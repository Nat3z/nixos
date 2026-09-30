// aerospace-peek: Mission-Control-style overview of AeroSpace workspaces.
// Runs as a background agent; SIGUSR1 toggles the overlay. Hidden workspaces are
// rendered live by capturing each window and placing it where it was last tiled.

import AppKit
import ScreenCaptureKit

// MARK: - Options

struct Options {
    var aerospace: String = "/run/current-system/sw/bin/aerospace"
    var switchScript: String? = nil
    // workspace name -> key that selects it in the overlay
    var keys: [String: String] = [:]

    static func parse() -> Options {
        var options: Options = Options()
        var args: IndexingIterator<ArraySlice<String>> = CommandLine.arguments.dropFirst().makeIterator()
        while let arg: String = args.next() {
            switch arg {
            case "--aerospace": options.aerospace = args.next() ?? options.aerospace
            case "--switch": options.switchScript = args.next()
            case "--key":
                // --key <workspace>=<key>
                guard let pair: String = args.next(), let eq: String.Index = pair.firstIndex(of: "=") else { continue }
                options.keys[String(pair[..<eq])] = String(pair[pair.index(after: eq)...]).lowercased()
            default:
                FileHandle.standardError.write("aerospace-peek: unknown argument \(arg)\n".data(using: .utf8)!)
            }
        }
        return options
    }

    func key(for workspace: String) -> String? {
        keys[workspace] ?? (workspace.count == 1 ? workspace.lowercased() : nil)
    }

    // Mapped keys win; typing a single-character workspace name also works.
    func workspace(for key: String, among names: [String]) -> String? {
        names.first(where: { self.key(for: $0) == key }) ?? names.first(where: { $0.lowercased() == key })
    }
}

// MARK: - AeroSpace CLI

struct Workspace: Decodable {
    let name: String
    let focused: Bool

    enum CodingKeys: String, CodingKey {
        case name = "workspace"
        case focused = "workspace-is-focused"
    }
}

struct Window: Decodable {
    let id: CGWindowID
    let workspace: String
    let pid: pid_t

    enum CodingKeys: String, CodingKey {
        case id = "window-id"
        case workspace
        case pid = "app-pid"
    }
}

private struct WorkspaceEvent: Decodable {
    let workspace: String
    let prevWorkspace: String?
}

// Splits a byte stream into lines; readabilityHandler callbacks are serialized.
private final class LineBuffer: @unchecked Sendable {
    private var data: Data = Data()

    func append(_ chunk: Data, _ onLine: (Data) -> Void) {
        data.append(chunk)
        while let newline: Data.Index = data.firstIndex(of: 0x0A) {
            onLine(Data(data[data.startIndex..<newline]))
            data.removeSubrange(data.startIndex...newline)
        }
    }
}

final class AeroSpace: @unchecked Sendable {
    let bin: String

    init(bin: String) { self.bin = bin }

    func workspaces() -> [Workspace] {
        decode(run(["list-workspaces", "--all", "--json", "--format",
                    "%{workspace} %{workspace-is-focused}"]))
    }

    func windows() -> [Window] {
        decode(run(["list-windows", "--all", "--json", "--format", "%{window-id} %{workspace} %{app-pid}"]))
    }

    // Prefer the SKHD switch script so follow windows (FaceTime, Cap, Discord) come along.
    func focus(_ workspace: String, script: String?) {
        DispatchQueue.global(qos: .userInteractive).async {
            if let script: String = script {
                _ = self.run([workspace], executable: script)
            } else {
                _ = self.run(["workspace", workspace])
            }
        }
    }

    // Streams focused-workspace changes as (previous, current). Reconnects if AeroSpace restarts.
    func subscribe(_ handler: @escaping (String?, String) -> Void) {
        let process: Process = Process()
        process.executableURL = URL(fileURLWithPath: bin)
        process.arguments = ["subscribe", "focused-workspace-changed"]
        let out: Pipe = Pipe()
        process.standardOutput = out
        process.standardError = FileHandle.nullDevice

        let buffer: LineBuffer = LineBuffer()
        out.fileHandleForReading.readabilityHandler = { handle in
            let chunk: Data = handle.availableData
            guard !chunk.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            buffer.append(chunk) { line in
                guard let event: WorkspaceEvent = try? JSONDecoder().decode(WorkspaceEvent.self, from: line) else { return }
                DispatchQueue.main.async { handler(event.prevWorkspace, event.workspace) }
            }
        }
        process.terminationHandler = { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.subscribe(handler) }
        }
        do {
            try process.run()
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.subscribe(handler) }
        }
    }

    private func run(_ args: [String], executable: String? = nil) -> Data? {
        let process: Process = Process()
        process.executableURL = URL(fileURLWithPath: executable ?? bin)
        process.arguments = args
        // Launchd's PATH lacks aerospace, which the switch script calls by name.
        var env: [String: String] = ProcessInfo.processInfo.environment
        env["PATH"] = [(bin as NSString).deletingLastPathComponent, "/run/current-system/sw/bin", env["PATH"] ?? "/usr/bin:/bin"].joined(separator: ":")
        process.environment = env
        let out: Pipe = Pipe()
        process.standardOutput = out
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return nil }
        let data: Data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return process.terminationStatus == 0 ? data : nil
    }

    private func decode<T: Decodable>(_ data: Data?) -> [T] {
        guard let data: Data = data else { return [] }
        return (try? JSONDecoder().decode([T].self, from: data)) ?? []
    }
}

// MARK: - Capture

@MainActor
final class Capturer {
    // Last capture per window, so reopening paints instantly before the refresh lands.
    private(set) var images: [CGWindowID: CGImage] = [:]
    // Window frames normalized to their display, remembered from when they were last on screen.
    private(set) var frames: [CGWindowID: CGRect] = [:]

    func content() async -> SCShareableContent? {
        try? await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
    }

    // AeroSpace parks hidden windows in a screen corner, so only windows mostly inside a
    // display are laid out; those frames are what hidden workspaces get drawn with.
    func remember(_ content: SCShareableContent) {
        for window: SCWindow in content.windows where window.windowLayer == 0 {
            let area: CGFloat = window.frame.width * window.frame.height
            guard area > 0 else { continue }
            for display: SCDisplay in content.displays {
                let visible: CGRect = window.frame.intersection(display.frame)
                guard !visible.isNull, visible.width * visible.height > area * 0.5 else { continue }
                frames[window.windowID] = CGRect(
                    x: (window.frame.minX - display.frame.minX) / display.frame.width,
                    y: (window.frame.minY - display.frame.minY) / display.frame.height,
                    width: window.frame.width / display.frame.width,
                    height: window.frame.height / display.frame.height)
                break
            }
        }
    }

    func capture(_ windows: [(SCWindow, CGSize)], onImage: @escaping @MainActor (CGWindowID, CGImage) -> Void) async {
        await withTaskGroup(of: (CGWindowID, CGImage?).self) { group in
            for (window, size) in windows {
                group.addTask {
                    let config: SCStreamConfiguration = SCStreamConfiguration()
                    config.width = max(1, Int(size.width))
                    config.height = max(1, Int(size.height))
                    config.showsCursor = false
                    config.ignoreShadowsSingleWindow = true
                    let filter: SCContentFilter = SCContentFilter(desktopIndependentWindow: window)
                    let image: CGImage? = try? await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                    return (window.windowID, image)
                }
            }
            for await (id, image) in group {
                guard let image: CGImage = image else { continue }
                await MainActor.run {
                    self.images[id] = image
                    onImage(id, image)
                }
            }
        }
    }
}

// MARK: - Views

private let accent: NSColor = NSColor.controlAccentColor

final class TileView: NSView {
    static let labelHeight: CGFloat = 36
    static let screenRadius: CGFloat = 10

    let workspace: String
    var onHover: (() -> Void)?
    var onClick: (() -> Void)?

    private let screenLayer: CALayer = CALayer()
    private let wallpaperLayer: CALayer = CALayer()
    private let ring: CALayer = CALayer()
    private var windowLayers: [CGWindowID: CALayer] = [:]
    private var windowFrames: [CGWindowID: CGRect] = [:]
    private var iconViews: [NSImageView] = []
    private let keycap: NSView = NSView()
    private let keyLabel: NSTextField
    private let nameLabel: NSTextField

    var selected: Bool = false {
        didSet { ring.opacity = selected ? 1 : 0 }
    }

    // `windows` are back-to-front with frames normalized to the screen (top-left origin).
    init(workspace: String, key: String?, current: Bool, wallpaper: CGImage?, windows: [(CGWindowID, pid_t, CGRect)], images: [CGWindowID: CGImage]) {
        self.workspace = workspace
        keyLabel = NSTextField(labelWithString: key?.uppercased() ?? "")
        nameLabel = NSTextField(labelWithString: key?.uppercased() == workspace ? "" : workspace)
        super.init(frame: .zero)
        wantsLayer = true

        ring.borderColor = accent.cgColor
        ring.borderWidth = 3
        ring.cornerRadius = Self.screenRadius + 5
        ring.opacity = 0
        layer?.addSublayer(ring)

        screenLayer.cornerRadius = Self.screenRadius
        screenLayer.masksToBounds = true
        screenLayer.backgroundColor = NSColor(white: 0.12, alpha: 1).cgColor
        screenLayer.borderWidth = current ? 1.5 : 0.5
        screenLayer.borderColor = NSColor(white: 1, alpha: current ? 0.55 : 0.12).cgColor
        layer?.addSublayer(screenLayer)

        wallpaperLayer.contents = wallpaper
        wallpaperLayer.contentsGravity = .resizeAspectFill
        screenLayer.addSublayer(wallpaperLayer)

        for (id, pid, frame) in windows {
            let windowLayer: CALayer = CALayer()
            windowLayer.masksToBounds = true
            windowLayer.backgroundColor = NSColor(white: 0.2, alpha: 0.9).cgColor
            windowLayer.contentsGravity = .resizeAspectFill
            if let image: CGImage = images[id] {
                windowLayer.contents = image
            } else if let icon: NSImage = NSRunningApplication(processIdentifier: pid)?.icon {
                // Placeholder until the first capture lands.
                let iconLayer: CALayer = CALayer()
                iconLayer.contents = icon
                iconLayer.contentsGravity = .resizeAspect
                iconLayer.name = "icon"
                windowLayer.addSublayer(iconLayer)
            }
            screenLayer.addSublayer(windowLayer)
            windowLayers[id] = windowLayer
            windowFrames[id] = frame
        }

        var seen: Set<pid_t> = []
        for (_, pid, _) in windows.reversed() where seen.insert(pid).inserted && iconViews.count < 5 {
            guard let icon: NSImage = NSRunningApplication(processIdentifier: pid)?.icon else { continue }
            let view: NSImageView = NSImageView(image: icon)
            view.imageScaling = .scaleProportionallyUpOrDown
            addSubview(view)
            iconViews.append(view)
        }

        keycap.wantsLayer = true
        keycap.layer?.backgroundColor = NSColor(white: 1, alpha: 0.14).cgColor
        keycap.layer?.cornerRadius = 5
        keycap.layer?.borderWidth = 0.5
        keycap.layer?.borderColor = NSColor(white: 1, alpha: 0.18).cgColor
        keycap.isHidden = key == nil
        keyLabel.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
        keyLabel.textColor = NSColor(white: 1, alpha: 0.92)
        keyLabel.alignment = .center
        keycap.addSubview(keyLabel)
        addSubview(keycap)

        nameLabel.font = .systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = NSColor(white: 1, alpha: 0.5)
        addSubview(nameLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setImage(_ image: CGImage, for id: CGWindowID) {
        guard let windowLayer: CALayer = windowLayers[id] else { return }
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.12)
        windowLayer.contents = image
        windowLayer.sublayers?.first(where: { $0.name == "icon" })?.removeFromSuperlayer()
        CATransaction.commit()
    }

    func setFrame(_ frame: CGRect, for id: CGWindowID) {
        guard windowFrames[id] != nil else { return }
        windowFrames[id] = frame
        needsLayout = true
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let screen: CGRect = CGRect(x: 0, y: Self.labelHeight, width: bounds.width, height: bounds.height - Self.labelHeight)
        screenLayer.frame = screen
        ring.frame = screen.insetBy(dx: -5, dy: -5)
        wallpaperLayer.frame = CGRect(origin: .zero, size: screen.size)

        let scale: CGFloat = screen.width / (window?.screen?.frame.width ?? screen.width)
        for (id, windowLayer) in windowLayers {
            guard let frame: CGRect = windowFrames[id] else { continue }
            // Normalized frames are top-left origin; layers are bottom-left.
            windowLayer.frame = CGRect(
                x: frame.minX * screen.width,
                y: (1 - frame.maxY) * screen.height,
                width: frame.width * screen.width,
                height: frame.height * screen.height)
            windowLayer.cornerRadius = max(2, 16 * scale)
            let side: CGFloat = min(40, windowLayer.bounds.width * 0.3, windowLayer.bounds.height * 0.3)
            windowLayer.sublayers?.first?.frame = CGRect(x: (windowLayer.bounds.width - side) / 2, y: (windowLayer.bounds.height - side) / 2, width: side, height: side)
        }
        CATransaction.commit()

        let midY: CGFloat = Self.labelHeight / 2 - 2
        keycap.frame = CGRect(x: 2, y: midY - 11, width: max(24, keyLabel.intrinsicContentSize.width + 12), height: 22)
        keyLabel.frame = CGRect(x: 0, y: 3, width: keycap.frame.width, height: 16)
        let nameX: CGFloat = keycap.isHidden ? 2 : keycap.frame.maxX + 8
        nameLabel.frame = CGRect(x: nameX, y: midY - 8, width: nameLabel.intrinsicContentSize.width + 4, height: 16)

        var x: CGFloat = bounds.width - 2
        for view: NSImageView in iconViews {
            x -= 18
            view.frame = CGRect(x: x, y: midY - 9, width: 18, height: 18)
            x -= 4
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways], owner: self))
    }

    override func mouseMoved(with event: NSEvent) { if !selected { onHover?() } }
    override func mouseEntered(with event: NSEvent) { onHover?() }
    override func mouseDown(with event: NSEvent) { onClick?() }
    // Clicks land even if the panel never became key.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class OverlayPanel: NSPanel {
    var onKey: ((NSEvent) -> Void)?

    override var canBecomeKey: Bool { true }
    override func keyDown(with event: NSEvent) { onKey?(event) }
}

// MARK: - Overlay

@MainActor
final class Overlay {
    private let options: Options
    private let aerospace: AeroSpace
    private let capturer: Capturer = Capturer()
    private var panel: OverlayPanel?
    private var tiles: [TileView] = []
    private var columns: Int = 1
    private var selection: Int = 0
    private var previous: String?
    // App to hand focus back to when the overlay is dismissed without switching.
    private var frontmost: NSRunningApplication?
    private var wallpapers: [URL: CGImage] = [:]
    private var generation: Int = 0

    var isShown: Bool { panel?.isVisible == true }

    init(options: Options) {
        self.options = options
        aerospace = AeroSpace(bin: options.aerospace)
        aerospace.subscribe { [weak self] prev, current in
            guard let self = self else { return }
            if let prev = prev, prev != current { self.previous = prev }
            if self.isShown { self.hide() }
            // Let AeroSpace finish laying out before remembering frames.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { self.refreshFrames() }
        }
    }

    func toggle() {
        isShown ? hide() : show()
    }

    func hide() {
        generation += 1
        guard let panel: OverlayPanel = panel else { return }
        self.panel = nil
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = reduceMotion ? 0 : 0.1
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }

    private var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    private func refreshFrames() {
        Task { @MainActor in
            if let content: SCShareableContent = await capturer.content() { capturer.remember(content) }
        }
    }

    private func show() {
        generation += 1
        let token: Int = generation
        let aerospace: AeroSpace = self.aerospace
        DispatchQueue.global(qos: .userInteractive).async {
            let workspaces: [Workspace] = aerospace.workspaces()
            let windows: [Window] = aerospace.windows()
            DispatchQueue.main.async {
                guard token == self.generation, !workspaces.isEmpty else { return }
                self.present(workspaces, windows, token: token)
            }
        }
    }

    private func present(_ workspaces: [Workspace], _ windows: [Window], token: Int) {
        let screen: NSScreen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens[0]
        let panel: OverlayPanel = OverlayPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.onKey = { [weak self] event in self?.handle(event) }

        let backdrop: NSVisualEffectView = NSVisualEffectView(frame: CGRect(origin: .zero, size: screen.frame.size))
        backdrop.material = .fullScreenUI
        backdrop.blendingMode = .behindWindow
        backdrop.state = .active
        backdrop.autoresizingMask = [.width, .height]
        let tint: NSView = NSView(frame: backdrop.bounds)
        tint.wantsLayer = true
        tint.layer?.backgroundColor = NSColor(white: 0.04, alpha: 0.45).cgColor
        tint.autoresizingMask = [.width, .height]
        backdrop.addSubview(tint)
        panel.contentView = backdrop

        let wallpaper: CGImage? = wallpaper(for: screen)
        let order: [CGWindowID: Int] = zOrder()
        let byWorkspace: [String: [Window]] = Dictionary(grouping: windows, by: { $0.workspace })
        let focused: String? = workspaces.first(where: { $0.focused })?.name

        tiles = workspaces.map { workspace in
            // Back-to-front so floating windows stay on top of tiles.
            let members: [Window] = (byWorkspace[workspace.name] ?? []).sorted { (order[$0.id] ?? .max) > (order[$1.id] ?? .max) }
            let tile: TileView = TileView(
                workspace: workspace.name,
                key: options.key(for: workspace.name),
                current: workspace.focused,
                wallpaper: wallpaper,
                windows: layout(members),
                images: capturer.images)
            backdrop.addSubview(tile)
            return tile
        }
        for (index, tile) in tiles.enumerated() {
            tile.onHover = { [weak self] in self?.select(index) }
            tile.onClick = { [weak self] in self?.activate(index) }
        }
        arrange(in: CGRect(origin: .zero, size: screen.frame.size), aspect: screen.frame.width / screen.frame.height)

        let names: [String] = workspaces.map(\.name)
        let initial: String? = previous.flatMap { names.contains($0) && $0 != focused ? $0 : nil } ?? focused
        select(names.firstIndex(where: { $0 == initial }) ?? 0)

        panel.alphaValue = 0
        // Launchd agents start in the background, so explicitly take focus for key presses.
        frontmost = NSWorkspace.shared.frontmostApplication
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = reduceMotion ? 0 : 0.12
            panel.animator().alphaValue = 1
        }
        self.panel = panel

        Task { @MainActor in await self.refresh(windows, token: token, screen: screen) }
    }

    // Re-read frames for visible workspaces, then capture every window at tile resolution.
    private func refresh(_ windows: [Window], token: Int, screen: NSScreen) async {
        guard let content: SCShareableContent = await capturer.content(), token == generation else { return }
        capturer.remember(content)

        let byWorkspace: [String: [Window]] = Dictionary(grouping: windows, by: { $0.workspace })
        let tileWidth: CGFloat = tiles.first?.bounds.width ?? 400
        let pixels: CGFloat = tileWidth / screen.frame.width * screen.backingScaleFactor
        let scWindows: [CGWindowID: SCWindow] = Dictionary(content.windows.map { ($0.windowID, $0) }, uniquingKeysWith: { a, _ in a })

        var jobs: [(SCWindow, CGSize)] = []
        var tileFor: [CGWindowID: TileView] = [:]
        for tile: TileView in tiles {
            for (id, _, frame) in layout(byWorkspace[tile.workspace] ?? []) {
                tile.setFrame(frame, for: id)
                guard let scWindow: SCWindow = scWindows[id] else { continue }
                tileFor[id] = tile
                jobs.append((scWindow, CGSize(width: scWindow.frame.width * pixels, height: scWindow.frame.height * pixels)))
            }
        }
        await capturer.capture(jobs) { [weak self] id, image in
            guard let self = self, token == self.generation else { return }
            tileFor[id]?.setImage(image, for: id)
        }
    }

    // Remembered frames when known; otherwise an even split, like a fresh tiles layout.
    private func layout(_ windows: [Window]) -> [(CGWindowID, pid_t, CGRect)] {
        let known: Bool = windows.allSatisfy { capturer.frames[$0.id] != nil }
        return windows.enumerated().map { index, window in
            let width: CGFloat = 1 / CGFloat(windows.count)
            let frame: CGRect = known ? capturer.frames[window.id]! : CGRect(x: CGFloat(index) * width, y: 0, width: width, height: 1)
            return (window.id, window.pid, frame)
        }
    }

    // Picks the column count that gives the largest tiles, then centers each row.
    private func arrange(in bounds: CGRect, aspect: CGFloat) {
        let area: CGRect = bounds.insetBy(dx: 72, dy: 72)
        let gap: CGFloat = 36
        let count: Int = tiles.count
        var best: (columns: Int, width: CGFloat) = (1, 0)
        for columns: Int in 1...max(1, count) {
            let rows: Int = Int(ceil(Double(count) / Double(columns)))
            var width: CGFloat = min((area.width - gap * CGFloat(columns - 1)) / CGFloat(columns), bounds.width * 0.3)
            let fitHeight: CGFloat = (area.height - gap * CGFloat(rows - 1)) / CGFloat(rows) - TileView.labelHeight
            width = min(width, fitHeight * aspect)
            if width > best.width { best = (columns, width) }
        }
        columns = best.columns
        let size: CGSize = CGSize(width: best.width, height: best.width / aspect + TileView.labelHeight)
        let rows: Int = Int(ceil(Double(count) / Double(columns)))
        let gridHeight: CGFloat = CGFloat(rows) * size.height + CGFloat(rows - 1) * gap
        var y: CGFloat = bounds.midY + gridHeight / 2

        for row: Int in 0..<rows {
            let rowTiles: ArraySlice<TileView> = tiles[(row * columns)..<min(count, (row + 1) * columns)]
            let rowWidth: CGFloat = CGFloat(rowTiles.count) * size.width + CGFloat(rowTiles.count - 1) * gap
            var x: CGFloat = bounds.midX - rowWidth / 2
            y -= size.height
            for tile: TileView in rowTiles {
                tile.frame = CGRect(origin: CGPoint(x: x.rounded(), y: y.rounded()), size: size)
                x += size.width + gap
            }
            y -= gap
        }
    }

    private func select(_ index: Int) {
        guard tiles.indices.contains(index) else { return }
        selection = index
        for (i, tile) in tiles.enumerated() { tile.selected = i == index }
    }

    private func activate(_ index: Int) {
        guard tiles.indices.contains(index) else { return }
        go(to: tiles[index].workspace)
    }

    private func go(to workspace: String) {
        hide()
        aerospace.focus(workspace, script: options.switchScript)
    }

    private func handle(_ event: NSEvent) {
        let key: String = event.charactersIgnoringModifiers?.lowercased() ?? ""
        switch event.keyCode {
        case 53: // escape
            hide()
            frontmost?.activate()
        case 36, 76, 49: activate(selection) // return, enter, space
        case 48: select((selection + (event.modifierFlags.contains(.shift) ? tiles.count - 1 : 1)) % max(1, tiles.count)) // tab
        case 123: select(selection - 1)
        case 124: select(selection + 1)
        case 125: select(min(tiles.count - 1, selection + columns))
        case 126: select(selection - columns)
        default:
            if let workspace: String = options.workspace(for: key, among: tiles.map(\.workspace)) {
                go(to: workspace)
                return
            }
            switch key {
            case "h": select(selection - 1)
            case "l": select(selection + 1)
            case "j": select(min(tiles.count - 1, selection + columns))
            case "k": select(selection - columns)
            default: NSSound.beep()
            }
        }
    }

    private func wallpaper(for screen: NSScreen) -> CGImage? {
        guard let url: URL = NSWorkspace.shared.desktopImageURL(for: screen) else { return nil }
        if let cached: CGImage = wallpapers[url] { return cached }
        guard let image: NSImage = NSImage(contentsOf: url) else { return nil }
        // Downscale once; tiles are small and full-size wallpapers are huge.
        let width: CGFloat = 1280
        let height: CGFloat = width * image.size.height / max(1, image.size.width)
        let rep: NSBitmapImageRep? = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width), pixelsHigh: Int(height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        guard let rep: NSBitmapImageRep = rep else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()
        wallpapers[url] = rep.cgImage
        return rep.cgImage
    }

    // Front-to-back index of every on-screen window (no capture permission needed).
    private func zOrder() -> [CGWindowID: Int] {
        guard let list: [[String: Any]] = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else { return [:] }
        var order: [CGWindowID: Int] = [:]
        for (index, info) in list.enumerated() {
            if let id: CGWindowID = info[kCGWindowNumber as String] as? CGWindowID { order[id] = index }
        }
        return order
    }
}

// MARK: - Main

let app: NSApplication = NSApplication.shared
app.setActivationPolicy(.accessory)

// Hidden workspaces fall back to app icons until screen recording is granted.
if !CGPreflightScreenCaptureAccess() { CGRequestScreenCaptureAccess() }

let overlay: Overlay = MainActor.assumeIsolated { Overlay(options: Options.parse()) }

signal(SIGUSR1, SIG_IGN)
let toggleSource: DispatchSourceSignal = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
toggleSource.setEventHandler { MainActor.assumeIsolated { overlay.toggle() } }
toggleSource.resume()

app.run()
