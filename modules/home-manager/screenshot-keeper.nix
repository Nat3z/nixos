{ config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  scriptPath = "${homeDir}/Library/Scripts/screenshot_keeper.py";
in
{
  home.file."Library/Scripts/screenshot_keeper.py" = {
    force = true;
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import json
      import subprocess
      import time
      from pathlib import Path

      SCREENSHOT_DIR = Path.home() / "Screenshots"
      STATE_FILE = Path.home() / "Library" / "Application Support" / "screenshot-keeper" / "state.json"
      POLL_SECONDS = 1.0
      KEEP_COUNT = 5
      EXTS = {".png", ".jpg", ".jpeg", ".tif", ".tiff", ".gif", ".heic"}


      def screenshot_files():
          if not SCREENSHOT_DIR.exists():
              SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
          files = []
          for p in SCREENSHOT_DIR.iterdir():
              if p.is_file() and p.suffix.lower() in EXTS and not p.name.startswith('.'):
                  try:
                      st = p.stat()
                  except FileNotFoundError:
                      continue
                  files.append((p, st.st_mtime, st.st_size))
          return files


      def wait_until_stable(path: Path, timeout=10):
          last = None
          deadline = time.time() + timeout
          while time.time() < deadline:
              try:
                  st = path.stat()
                  cur = (st.st_size, st.st_mtime_ns)
              except FileNotFoundError:
                  return False
              if cur == last and st.st_size > 0:
                  return True
              last = cur
              time.sleep(0.25)
          return path.exists()


      def copy_image_to_clipboard(path: Path):
          ext = path.suffix.lower()
          if ext == ".png":
              cls = "«class PNGf»"
          elif ext in {".jpg", ".jpeg"}:
              cls = "JPEG picture"
          elif ext in {".tif", ".tiff"}:
              cls = "TIFF picture"
          else:
              # For formats AppleScript cannot coerce reliably, copy the file reference.
              script = 'on run argv\nset the clipboard to (POSIX file (item 1 of argv))\nend run'
              subprocess.run(["/usr/bin/osascript", "-e", script, str(path)], check=False,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
              return

          script = f'on run argv\nset the clipboard to (read (POSIX file (item 1 of argv)) as {cls})\nend run'
          subprocess.run(["/usr/bin/osascript", "-e", script, str(path)], check=False,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


      def prune_old(files):
          # Keep newest by modification time; delete oldest first.
          current = []
          for p, _, _ in files:
              try:
                  current.append((p, p.stat().st_mtime))
              except FileNotFoundError:
                  pass
          current.sort(key=lambda item: item[1], reverse=True)
          for p, _ in current[KEEP_COUNT:]:
              try:
                  p.unlink()
              except FileNotFoundError:
                  pass
              except OSError:
                  pass


      def load_seen():
          try:
              return set(json.loads(STATE_FILE.read_text()).get("seen", []))
          except Exception:
              return set()


      def save_seen(seen):
          STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
          tmp = STATE_FILE.with_suffix(".tmp")
          tmp.write_text(json.dumps({"seen": sorted(seen)}, indent=2))
          tmp.replace(STATE_FILE)


      def file_id(path: Path):
          try:
              st = path.stat()
              return f"{path}|{st.st_mtime_ns}|{st.st_size}"
          except FileNotFoundError:
              return None


      def main():
          SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
          seen = load_seen()
          # First run: mark existing screenshots seen so only new arrivals are copied.
          if not STATE_FILE.exists():
              for p, _, _ in screenshot_files():
                  fid = file_id(p)
                  if fid:
                      seen.add(fid)
              save_seen(seen)

          while True:
              files = screenshot_files()
              files.sort(key=lambda item: item[1])
              for p, _, _ in files:
                  fid = file_id(p)
                  if not fid or fid in seen:
                      continue
                  if wait_until_stable(p):
                      fid = file_id(p)
                      if fid and fid not in seen:
                          copy_image_to_clipboard(p)
                          seen.add(fid)
              prune_old(screenshot_files())
              # Keep state bounded and only for files still present.
              live_prefixes = {str(p) for p, _, _ in screenshot_files()}
              seen = {x for x in seen if x.split('|', 1)[0] in live_prefixes}
              save_seen(seen)
              time.sleep(POLL_SECONDS)


      if __name__ == "__main__":
          main()
    '';
  };

  home.file."Library/LaunchAgents/com.user.screenshot-keeper.plist" = {
    force = true;
    text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>com.user.screenshot-keeper</string>
      <key>ProgramArguments</key>
      <array>
        <string>${pkgs.python3}/bin/python3</string>
        <string>${scriptPath}</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <true/>
      <key>StandardOutPath</key>
      <string>${homeDir}/Library/Logs/screenshot-keeper.log</string>
      <key>StandardErrorPath</key>
      <string>${homeDir}/Library/Logs/screenshot-keeper.err</string>
    </dict>
    </plist>
  '';
  };
}
