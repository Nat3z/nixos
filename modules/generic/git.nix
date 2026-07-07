{
  username,
  config,
  lib,
  ...
}:
let
  credentials = import ../../credentials/git.nix;
  cfg = config.git-setup;
in
{
  options = {
    git-setup = {
      enable = lib.mkEnableOption "Enable git setup module";
      signing = {
        enable = lib.mkEnableOption "Enable git signing";
        key = lib.mkOption {
          default = null;
          type = lib.types.nullOr lib.types.str;
          description = "Key path for signing commits";
        };
        ssh = lib.mkEnableOption "Set SSH Signing";
      };
      config = {
        user = {
          name = lib.mkOption {
            type = lib.types.str;
            default = credentials.name;
            description = "Git user name";
          };
          email = lib.mkOption {
            type = lib.types.str;
            default = credentials.email;
            description = "Git user email";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.programs.git = {
      enable = true;
      settings = lib.mkMerge [
        cfg.config
        (lib.mkIf cfg.signing.ssh {
          gpg.format = "ssh"; 
        })
      ];
      signing = lib.mkIf cfg.signing.enable {
        signByDefault = true;
        key = cfg.signing.key;
      };
    };
  };
}
