{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    shellAliases = {
      cd = "z";
      vim = "nvim";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
  };
  
  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;
}
