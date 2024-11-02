format = '$all$character'

[custom.current_time]
command = "printf 'at ' && date +'%H:%M %p'"
when = "true"
format = "[$output]($style) "
style = "bold green"

[character]
success_symbol = "[>](bold green)"
error_symbol = "[x](bold red)"
vimcmd_symbol = "[<](bold green)"

[git_commit]
tag_symbol = " tag "

[git_status]
ahead = ">"
behind = "<"
diverged = "<>"
renamed = "r"
deleted = "x"

[buf]
format = "[$symbol]($style)"

[c]
symbol = "C "

[cobol]
symbol = "cobol "
format = "[$symbol]($style)"

[cmake]
symbol = "cmake "
format = "[$symbol]($style)"

[daml]
symbol = "daml "
format = "[$symbol]($style)"

[dart]
symbol = "dart "
format = "[$symbol]($style)"

[deno]
symbol = "deno "
format = "[$symbol]($style)"

[dotnet]
symbol = ".NET "
format = "[$symbol(🎯 $tfm )]($style)"

[directory]
read_only = " ro"

[docker_context]
symbol = "docker "
format = '[$symbol]($style)'

[elixir]
symbol = "exs "
format = '[$symbol]($style)'

[elm]
symbol = "elm "
format = '[$symbol]($style)'

[erlang]
format = '[$symbol]($style)'

[fennel]
symbol = "fnl "
format = '[$symbol]($style)'

[fossil_branch]
symbol = "fossil "

[gcloud]
symbol = "gcp "

[git_branch]
symbol = ""

[golang]
symbol = "go "
format = '[$symbol]($style)'

[gradle]
symbol = "gradle "
format = '[$symbol]($style)'

[guix_shell]
symbol = "guix "

[haxe]
format = '[$symbol]($style)'

[helm]
format = '[$symbol]($style)'

[hg_branch]
symbol = "hg "

[java]
symbol = "java "
format = '[$symbol]($style)'

[julia]
symbol = "jl "
format = '[$symbol]($style)'

[kotlin]
symbol = "kt "
format = '[$symbol]($style)'

[lua]
symbol = "lua "
format = '[$symbol]($style)'

[nodejs]
symbol = "nodejs "
format = '[$symbol]($style)'

[memory_usage]
symbol = "memory "

[meson]
symbol = "meson "
format = '[$symbol]($style)'

[nim]
symbol = "nim "
format = '[$symbol]($style)'

[nix_shell]
symbol = "nix "

[ocaml]
symbol = "ml "
format = '[$symbol(\($switch_indicator$switch_name\) )]($style)'

[opa]
symbol = "opa "
format = '[$symbol]($style)'

[package]
symbol = "pkg "
format = '[$version]($style) '
[perl]
symbol = "pl "
format = '[$symbol]($style)'

[php]
symbol = "php "
format = '[$symbol]($style)'

[pijul_channel]
symbol = "pijul "

[pulumi]
symbol = "pulumi "
format = '[$symbol$stack]($style)'

[purescript]
symbol = "purs "
format = '[$symbol]($style)'

[python]
symbol = "py "
format = '[$symbol]($style)'

[raku]
symbol = "raku "
format = '[$symbol]($style)'

[red]
format = '[$symbol]($style)'

[ruby]
symbol = "rb "
format = '[$symbol]($style)'

[rust]
symbol = "rs "
format = '[$symbol]($style)'

[scala]
symbol = "scala "

[spack]
symbol = "spack "

[solidity]
symbol = "solidity "
format = '[$symbol]($style)'

[status]
symbol = "[x](bold red) "

[sudo]
symbol = "sudo "

[swift]
symbol = "swift "
format = '[$symbol]($style)'

[typst]
symbol = "typst "
format = '[$symbol]($style)'

[vlang]
format = '[$symbol]($style)'

[terraform]
symbol = "terraform "

[zig]
symbol = "zig "
format = '[$symbol]($style)'

[vagrant]
format = '[$symbol]($style)'
