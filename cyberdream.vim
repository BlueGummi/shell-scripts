" Put in ~/.local/share/nvim/plugged/vim-airline-themes/autoload/airline/themes/cyberdream.vim
" Cyberdream airline theme
" Ported from https://github.com/scottmckendry/cyberdream.nvim

let g:airline#themes#cyberdream#palette = {}

" Colors from cyberdream palette
let s:bg        = '#16181a'
let s:bg_alt    = '#1e2124'
let s:bg_hl     = '#3c4048'
let s:fg        = '#ffffff'
let s:grey      = '#7b8496'
let s:blue      = '#5ea1ff'
let s:green     = '#5eff6c'
let s:cyan      = '#5ef1ff'
let s:red       = '#ff6e5e'
let s:yellow    = '#f1ff5e'
let s:magenta   = '#ff5ef1'
let s:orange    = '#ffbd5e'
let s:purple    = '#bd5eff'

" [ guifg, guibg, ctermfg, ctermbg ]

" Normal mode
" section a: mode indicator (blue bg)
" section b: middle info (bg_alt)
" section c: filename area (bg)
let s:N1 = [ s:bg,     s:blue,   17,  75  ]
let s:N2 = [ s:fg,     s:bg_alt, 255, 236 ]
let s:N3 = [ s:fg,     s:bg,     255, 234 ]
let g:airline#themes#cyberdream#palette.normal = airline#themes#generate_color_map(s:N1, s:N2, s:N3)
let g:airline#themes#cyberdream#palette.normal_modified = {
      \ 'airline_c': [ s:yellow, s:bg, 227, 234, '' ] }

" Insert mode (green)
let s:I1 = [ s:bg,  s:green,   17,  83  ]
let s:I2 = [ s:fg,  s:bg_alt,  255, 236 ]
let s:I3 = [ s:fg,  s:bg,      255, 234 ]
let g:airline#themes#cyberdream#palette.insert = airline#themes#generate_color_map(s:I1, s:I2, s:I3)
let g:airline#themes#cyberdream#palette.insert_modified = {
      \ 'airline_c': [ s:yellow, s:bg, 227, 234, '' ] }

" Visual mode (magenta)
let s:V1 = [ s:bg,  s:magenta, 17,  207 ]
let s:V2 = [ s:fg,  s:bg_alt,  255, 236 ]
let s:V3 = [ s:fg,  s:bg,      255, 234 ]
let g:airline#themes#cyberdream#palette.visual = airline#themes#generate_color_map(s:V1, s:V2, s:V3)
let g:airline#themes#cyberdream#palette.visual_modified = {
      \ 'airline_c': [ s:yellow, s:bg, 227, 234, '' ] }

" Replace mode (red)
let s:R1 = [ s:bg,  s:red,    17,  203 ]
let s:R2 = [ s:fg,  s:bg_alt, 255, 236 ]
let s:R3 = [ s:fg,  s:bg,     255, 234 ]
let g:airline#themes#cyberdream#palette.replace = airline#themes#generate_color_map(s:R1, s:R2, s:R3)
let g:airline#themes#cyberdream#palette.replace_modified = {
      \ 'airline_c': [ s:yellow, s:bg, 227, 234, '' ] }

" Command mode (orange)
let s:C1 = [ s:bg,  s:orange, 17,  215 ]
let s:C2 = [ s:fg,  s:bg_alt, 255, 236 ]
let s:C3 = [ s:fg,  s:bg,     255, 234 ]
let g:airline#themes#cyberdream#palette.commandline = airline#themes#generate_color_map(s:C1, s:C2, s:C3)

" Terminal mode (cyan)
let s:T1 = [ s:bg,  s:cyan,   17,  87  ]
let s:T2 = [ s:fg,  s:bg_alt, 255, 236 ]
let s:T3 = [ s:fg,  s:bg,     255, 234 ]
let g:airline#themes#cyberdream#palette.terminal = airline#themes#generate_color_map(s:T1, s:T2, s:T3)

" Inactive windows
let s:IA1 = [ s:grey, s:bg_alt, 102, 236 ]
let s:IA2 = [ s:grey, s:bg_alt, 102, 236 ]
let s:IA3 = [ s:grey, s:bg,     102, 234 ]
let g:airline#themes#cyberdream#palette.inactive = airline#themes#generate_color_map(s:IA1, s:IA2, s:IA3)
let g:airline#themes#cyberdream#palette.inactive_modified = {
      \ 'airline_c': [ s:orange, s:bg, 215, 234, '' ] }

" Accents
let g:airline#themes#cyberdream#palette.accents = {
      \ 'red':    [ s:red,    '', 203, '' ],
      \ 'green':  [ s:green,  '', 83,  '' ],
      \ 'blue':   [ s:blue,   '', 75,  '' ],
      \ 'yellow': [ s:yellow, '', 227, '' ],
      \ 'orange': [ s:orange, '', 215, '' ],
      \ 'purple': [ s:purple, '', 141, '' ],
      \ }
