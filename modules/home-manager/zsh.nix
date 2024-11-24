{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
  };
  
  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;

}
