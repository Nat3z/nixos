{ pkgs, ... }: {

  programs.tmux = {
    enable = true;
    # shortcut = "a";
    # aggressiveResize = true; -- Disabled to be iTerm-friendly
    baseIndex = 1;
    # Avoid putting `new-session` in tmux.conf; it makes reloads/source-file flaky
    # and can create an extra session before your real one starts.
    newSession = false;
    # These bindings below target copy-mode-vi, so make tmux use vi copy mode.
    keyMode = "vi";
    # Stop tmux+escape craziness.
    escapeTime = 0;
    # Force tmux to use /tmp for sockets (WSL2 compat)
    secureSocket = false;

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.sensible
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_window_status_style 'rounded'
          set -g @catppuccin_date_time_text ' %m-%d-%Y %I:%M %p'
        '';
      }
      tmuxPlugins.yank
    ];

    extraConfig = ''
      # https://old.reddit.com/r/tmux/comments/mesrci/tmux_2_doesnt_seem_to_use_256_colors/
      set -g default-shell $SHELL
      set -g default-command $SHELL
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      set-environment -g COLORTERM "truecolor"

      # Catppuccin v2 only defines status modules by default; opt into using them.
      # Keep the status bar visible as a full-width bar at the bottom.
      set -g status on
      set -g status-position bottom
      set -gF status-style "bg=#{@thm_mantle},fg=#{@thm_fg}"
      set -g status-right-length 100
      set -g status-left-length 100
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_application}"
      set -ag status-right "#{E:@catppuccin_status_session}"
      set -ag status-right "#{E:@catppuccin_status_date_time}"

      # Mouse works as expected
      set-option -g mouse on
      # easy-to-remember split pane commands
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind -n M-H previous-window
      bind -n M-L next-window
      bind c new-window -c "#{pane_current_path}"

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel

      # vim/tmux navigation.  Use pane_current_command instead of shell vars in
      # tmux.conf; the old is_vim/tmux_version assignments were not reliable tmux
      # commands, and the C-\\ binding was not getting installed.
      bind-key -n 'C-h' if -F '#{m/r:(^|/)(g?view|n?vim?x?)(diff)?$,#{pane_current_command}}' 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if -F '#{m/r:(^|/)(g?view|n?vim?x?)(diff)?$,#{pane_current_command}}' 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if -F '#{m/r:(^|/)(g?view|n?vim?x?)(diff)?$,#{pane_current_command}}' 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if -F '#{m/r:(^|/)(g?view|n?vim?x?)(diff)?$,#{pane_current_command}}' 'send-keys C-l'  'select-pane -R'
      bind-key -n 'C-\' if -F '#{m/r:(^|/)(g?view|n?vim?x?)(diff)?$,#{pane_current_command}}' 'send-keys C-\' 'select-pane -l'

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l
      bind-key -n 'C-g' if -F '#{m/r:(^|/)(g?view|n?vim?x?)(diff)?$,#{pane_current_command}}' 'display-message "is vim"' 'display-message "is NOT vim"'
    '';
  };
}
