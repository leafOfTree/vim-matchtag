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

let s:mapping_toggle = s:GetConfig('mapping_toggle', '')
let s:mapping_toggle_highlight_cursor_on = s:GetConfig('mapping_toggle_highlight_cursor_on',
      \s:GetConfig('mapping_both', ''))
let s:enable_by_default = s:GetConfig('enable_by_default', 1)

" Use global variable so it can also be used by scripts in autoload
let g:vim_matchtag_files_default = '*.html,*.xml,*.js,*.jsx,*.ts,*.tsx,*.vue,*.svelte,*.jsp,*.php,*.erb,*.astro'
let s:files = s:GetConfig('files', g:vim_matchtag_files_default)
"}}}

" Highlight
highlight default link matchTag	Visual
highlight default link matchTagError Error

" Command
command! MatchTagToggle call matchtag#Toggle()
command! MatchTagToggleHighlightCursorOn call matchtag#ToggleHighlightCursorOn()
command! MatchTagToggleBoth call matchtag#ToggleHighlightCursorOn()

" Mapping
augroup matchtag-maping
  autocmd! matchtag-maping
  if !empty(s:mapping_toggle)
    execute 'autocmd BufNewFile,BufRead '.s:files
          \.' nnoremap<buffer> '
          \.s:mapping_toggle.' :MatchTagToggle<cr>'
  endif
  if !empty(s:mapping_toggle_highlight_cursor_on)
    execute 'autocmd BufNewFile,BufRead '.s:files
          \.' nnoremap<buffer> '
          \.s:mapping_toggle_highlight_cursor_on.' :MatchTagToggleHighlightCursorOn<cr>'
  endif
augroup END

function! s:ShouldEnableFile()
  return stridx(s:files, '*.'.&filetype) != -1 || stridx(s:files, expand('%:t')) != -1
endfunction

" Enable by default for specific files
if s:enable_by_default
  if s:ShouldEnableFile()
    call matchtag#EnableMatchTag()
  else
    execute 'autocmd BufNewFile,BufRead '.s:files
          \.' ++once call matchtag#EnableMatchTag()'
  endif
endif
" vim: fdm=marker
