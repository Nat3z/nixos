{ pkgs, ... }: {
    home.packages = [
       pkgs.fd
       (pkgs.writeShellScriptBin "v" ''
            if [[ $# -eq 1 ]]; then
                selected=$1
            else
                selected=$(cd ~ && fd -d 4 --base-directory ~ --type directory --exclude .git --exclude Downloads --exclude Music --exclude node_modules --exclude target --exclude Music --exclude Pictures --exclude Public --exclude Templates --exclude Videos --exclude Desktop --exclude Applications --exclude go --exclude Movies --exclude Music --exclude Pictures --exclude Public --exclude Library | fzf-tmux)
            fi

            if [[ -z $selected ]]; then
                exit 0
            fi

            # fd --base-directory returns paths relative to ~.  tmux new-session -c
            # resolves relative paths from the tmux server/current pane, so make it
            # absolute or new sessions may start in the wrong directory.
            if [[ "$selected" != /* ]]; then
                selected="$HOME/$selected"
            fi

            selected_name=$(basename "$selected" | tr . _)

            if [[ -z $TMUX ]]; then
                if tmux has-session -t="$selected_name" 2> /dev/null; then
                    tmux attach-session -t "$selected_name"
                else
                    tmux new-session -s "$selected_name" -c "$selected"
                fi
                exit 0
            fi

            if ! tmux has-session -t="$selected_name" 2> /dev/null; then
                tmux new-session -ds "$selected_name" -c "$selected"
            fi

            tmux switch-client -t "$selected_name"
        '')
    ];
}
