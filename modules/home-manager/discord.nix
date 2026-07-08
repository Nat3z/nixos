{ pkgs, config, lib, ... }:
{
    home.activation.discordNoSelfUpdate = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        rm -rf "$HOME/Library/Application Support/discord/app-"*
        /usr/bin/python3 - <<'PY'
import json, os
p = os.path.expanduser("~/Library/Application Support/discord/settings.json")
os.makedirs(os.path.dirname(p), exist_ok=True)
try:
    with open(p) as f:
        settings = json.load(f)
except Exception:
    settings = {}
settings.update({
    "SKIP_HOST_UPDATE": True,
    "SKIP_MODULE_UPDATE": True,
    "USE_NEW_UPDATER": False,
})
settings.pop("openasar", None)
with open(p, "w") as f:
    json.dump(settings, f, indent=2)
PY
    '';

    home.packages = with pkgs; [
        ((discord.override {
            withOpenASAR = false;
            withVencord = true;
        }).overrideAttrs (old: {
            # Discord's darwin package currently ships absurdly large badge-*.ico
            # files (~8.4G total) in discord_desktop_core. They are Windows badge
            # assets and are not needed on macOS.
            postInstall = (old.postInstall or "") + ''
                rm -f $out/Applications/Discord.app/Contents/Resources/modules/discord_desktop_core/app/images/badges/badge-*.ico

                # Discord may try to restart into a self-updated copy under
                # ~/Library/Application Support/discord/app-*, which conflicts with
                # the immutable Nix-managed app/modules. Remove those stale updater
                # payloads before launching so the Nix store app is always used.
                substituteInPlace $out/bin/Discord \
                    --replace-fail '/bin/disable-breaking-updates.py' '/bin/disable-breaking-updates.py
rm -rf "$HOME/Library/Application Support/discord/app-"*
/usr/bin/python3 -c "import json, os; p=os.path.expanduser(\"~/Library/Application Support/discord/settings.json\"); os.makedirs(os.path.dirname(p), exist_ok=True); s=json.load(open(p)) if os.path.exists(p) else {}; s.update({\"SKIP_HOST_UPDATE\": True, \"SKIP_MODULE_UPDATE\": True, \"USE_NEW_UPDATER\": False}); s.pop(\"openasar\", None); json.dump(s, open(p, \"w\"), indent=2)"'
            '';
        }))
    ];
}
