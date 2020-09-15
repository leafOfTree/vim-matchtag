"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim plugin for highlighting matching tags
" Maintainer: leafOfTree
" CREDITS: Inspired by matchParen.
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Exit quickly when:
" - this plugin was already loaded (or disabled)
" - when "compatiable" is set
" - the "CursorMoved" autocmd event is not available.
if exists('g:loaded_matchtag') 
      \ || exists('*s:HighlightMatchingTag')
      \ || !exists('##CursorMoved')
      \ || &cp 
  finish
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Config {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetConfig(name, default)
  let name = 'g:vim_matchtag_'.a:name
  return exists(name) ? eval(name) : a:default
endfunction

let s:mapping_toggle = s:GetConfig('mapping_toggle', '<c-t>')
let s:mapping_both = s:GetConfig('mapping_both', '<c-b>')
let s:enable_by_default = s:GetConfig('enable_by_default', 1)

" Use global variable so it can also be used by scripts in autoload
let g:vim_matchtag_files_default = '*.html,*.xml,*.js,*.jsx,*.ts,*.tsx,*.vue,*.svelte,*.jsp,*.php,*.erb'
let s:files = s:GetConfig('files', g:vim_matchtag_files_default)
"}}}

" Highlight
highlight default link matchTag	IncSearch
highlight default link matchTagError Error

" Command
command MatchTagToggle call matchtag#Toggle()
command MatchTagToggleBoth call matchtag#ToggleBoth()

" Mapping
augroup matchtag-maping
  autocmd! matchtag-maping
  execute 'autocmd BufNewFile,BufRead '.s:files
        \.' nnoremap<buffer> '
        \.s:mapping_toggle.' :MatchTagToggle<cr>'

  execute 'autocmd BufNewFile,BufRead '.s:files
        \.' nnoremap<buffer> '
        \.s:mapping_both.' :MatchTagToggleBoth<cr>'
augroup END

" Wil be enabled by default
if s:enable_by_default
  call matchtag#EnableMatchTag()
endif
" vim: fdm=marker
