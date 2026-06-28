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
          description = "GPG key path for signing commits";
        };
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
      settings = cfg.config;
      signing = lib.mkIf cfg.signing.enable {
        signByDefault = true;
        key = cfg.signing.key;
      };
    };
  };
}
