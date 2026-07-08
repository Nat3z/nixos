{ pkgs, config, ... }:
{
    home.packages = with pkgs; [
        ((discord.override {
            withOpenASAR = true;
            withVencord = true;
        }).overrideAttrs (old: {
            # Discord's darwin package currently ships absurdly large badge-*.ico
            # files (~8.4G total) in discord_desktop_core. They are Windows badge
            # assets and are not needed on macOS.
            postInstall = (old.postInstall or "") + ''
                rm -f $out/Applications/Discord.app/Contents/Resources/modules/discord_desktop_core/app/images/badges/badge-*.ico

                # Discord/OpenAsar may try to restart into a self-updated copy under
                # ~/Library/Application Support/discord/app-*, which conflicts with
                # the immutable Nix-managed app/modules. Remove those stale updater
                # payloads before launching so the Nix store app is always used.
                substituteInPlace $out/bin/Discord \
                    --replace-fail 'disable-breaking-updates.py' 'disable-breaking-updates.py
rm -rf "$HOME/Library/Application Support/discord/app-"*'
            '';
        }))
    ];
}
