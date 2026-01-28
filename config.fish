set -g fish_color_autosuggestion 555 brblack
set -g fish_color_cancel -r
set -g fish_color_command --bold
set -g fish_color_comment red
set -g fish_color_cwd green
set -g fish_color_cwd_root red
set -g fish_color_end brmagenta
set -g fish_color_error brred
set -g fish_color_escape bryellow --bold
set -g fish_color_history_current --bold
set -g fish_color_host normal
set -g fish_color_match --background=brblue
set -g fish_color_normal normal
set -g fish_color_operator bryellow
set -g fish_color_param cyan
set -g fish_color_quote yellow
set -g fish_color_redirection brblue
set -g fish_color_search_match bryellow '--background=brblack'
set -g fish_color_selection white --bold '--background=brblack'
set -g fish_color_user brgreen
set -g fish_color_valid_path --underline
set fish_greeting

starship init fish | source
alias ls='eza --icons=always'

if status --is-interactive
    fastfetch --config examples/13
    if not set -q __WAL_RAN_ONCE
        set -g __WAL_RAN_ONCE 1

        set wall (cat ~/.cache/ml4w/hyprland-dotfiles/current_wallpaper | string collect)
        wal -q -i $wall
        cat ~/.cache/wal/sequences &
    end
end

function far
    if test (count $argv) -ne 2
        echo "Usage: far <find> <replace>"
        return 1
    end

    set find_pattern $argv[1]
    set replace_pattern $argv[2]

    if test (uname) = "Darwin"
        for file in (find . -type f)
            if grep -Iq . "$file"
                env LC_CTYPE=C sed -i '' "s/$find_pattern/$replace_pattern/g" "$file"
            end
        end
    else
        for file in (find . -type f)
            if grep -Iq . "$file"
                sed -i "s/$find_pattern/$replace_pattern/g" "$file"
            end
        end
    end
end
fish_vi_key_bindings
