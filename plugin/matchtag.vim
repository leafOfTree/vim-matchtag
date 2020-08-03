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

let s:mapping = s:GetConfig('mapping', '<c-t>')
let s:enable_by_default = s:GetConfig('enable_by_default', 1)
"}}}

" Highlight
highlight default link matchTag	IncSearch

" Command
command ToggleMatchTag call matchtag#ToggleMatchTag()

" Mapping
execute 'nnoremap '.s:mapping.' :ToggleMatchTag<cr>'

" Wil be enabled by default
if s:enable_by_default
  call matchtag#EnableMatchTag()
endif
