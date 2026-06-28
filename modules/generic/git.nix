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
      config = lib.mkOption {
        default = {
          user.name = credentials.name;
          user.email = credentials.email;
        };
        type = lib.types.attrsOf lib.types.str;
        description = "Global git configuration values";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.programs.git = {
      enable = true;
      userName = cfg.config.user.name;
      userEmail = cfg.config.user.email;
      signing = lib.mkIf cfg.signing.enable {
        signByDefault = true;
        key = cfg.signing.key;
      };
    };
  };
}
