"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Settings {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:name = 'vim-matchtag'
let s:match_id = 99

let s:tagname_regexp = '[0-9A-Za-z_.-]'
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Configs {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetConfig(name, default)
  let name = 'g:vim_matchtag_'.a:name
  return exists(name) ? eval(name) : a:default
endfunction

let s:both = s:GetConfig('both', 0)
let s:debug = s:GetConfig('debug', 0)
let s:timeout = s:GetConfig('timeout', 300)
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Functions {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" The function that is invoked (very often) to definie a ":match"
" highlighting for any matching tag.
function! matchtag#HighlightMatchingTag()
  " Remove any previous match.
  if exists('w:match_tag_hl_on') && w:match_tag_hl_on
    silent! call s:DeleteMatch()
    let w:match_tag_hl_on = 0
  endif

  " Avoid removing the popup menu.
  " Or return when there are no colors
  if pumvisible() || (&t_Co < 8 && !has('gui_running'))
    return 
  endif

  call s:HighlightTag()
endfunction

function! s:HighlightTag()
  let save_cursor = getcurpos()
  let cursor_col = save_cursor[2]
  let bracket_col = match(getline('.'), '^\s*\zs<') + 1
  if cursor_col < bracket_col
    call cursor(0, bracket_col)
  endif

  let [row, col] = s:GetTagPos()
  if row
    " Current tag
    let tagname = s:GetTagName(row, col)
    if s:both
      let pos = [[row, col+1, len(tagname)]]
      call matchaddpos('MatchTag', pos, 10, s:match_id)
    endif

    " Set cursor to tag start to search backward correctly
    call cursor(row, col)

    " Matching tag
    let [match_row, match_col, offset] = s:SearchMatchTag(tagname)
    let match_tagname = s:GetTagName(match_row, match_col)
    let match_pos = [[match_row, match_col+offset, len(match_tagname)+1-offset]]
    call matchaddpos('MatchTag', match_pos, 10, s:match_id+1)

    let w:match_tag_hl_on = 1
    call matchtag#Log('In tag '.tagname)
    call matchtag#Log('Match tag '.match_tagname)
  else
    call matchtag#Log('Not in tag pair')
  endif

  call setpos('.', save_cursor)
endfunction

function! s:GetTagPos()
  let timeout = s:timeout
  let has_left = 0
  let has_right = 0
  let [left_row, left_col] = searchpos('<', 'bcnW', line('w0'), timeout)
  let [left_not_row, left_not_col] = searchpos('>', 'bnW', line('w0'), timeout)
  if (left_row == left_not_row && left_col > left_not_col) 
        \ || (left_row > left_not_row)
    let has_left = 1
  endif

  let [right_row, right_col] = searchpos('\(/\)\@<!>', 'cnW', line('w$'), timeout)
  let [right_not_row, right_not_col] = searchpos('<', 'nW', line('w$'), timeout)
  if (right_row == right_not_row && right_col < right_not_col)
        \ || (right_row < right_not_row)
        \ || right_not_row == 0
    let has_right = 1
  endif
  if has_left && has_right
    return [left_row, left_col]
  else
    return [0, 0]
  endif
endfunction

function! s:GetTagName(row, col)
  let row = a:row
  let col = a:col
  let line = getline(row)

  let end = col + 1
  while line[end] =~ s:tagname_regexp
    let end += 1
  endwhile
  let tagname = line[col: end-1]
  return tagname
endfunction

function! s:SearchMatchTag(tagname)
  let tagname = a:tagname
  let flags = 'nW'
  if tagname[0] == '/'
    let start = '<'.tagname[1:]
    let end = tagname
    let flags = flags.'b'

    " Don't include '<' if search backward
    let offset = 1
  else
    let start = '<'.tagname
    let end = '/'.tagname
    let offset = 0
  endif
  let [row, col] = searchpairpos(start, '', end, flags)

  return [row, col, offset]
endfunction

function! s:DeleteMatch()
  silent! call matchdelete(s:match_id)
  silent! call matchdelete(s:match_id+1)
endfunction

function! matchtag#DisableMatchTag()
  let g:loaded_matchtag = 0
  autocmd! matchtag
  call s:DeleteMatch()
endfunction

function! matchtag#EnableMatchTag()
  let g:loaded_matchtag = 1

  let files = s:GetConfig('files', g:vim_matchtag_files_default)
  augroup matchtag
    execute 'autocmd! CursorMoved,CursorMovedI,WinEnter '.files
          \.' call matchtag#HighlightMatchingTag()'
    execute 'autocmd! Bufleave '.files
          \.' silent! call s:DeleteMatch()'
    if exists('##TextChanged')
      execute 'autocmd! TextChanged,TextChangedI '.files
            \.' call matchtag#HighlightMatchingTag()'
    endif
  augroup END

  silent! doautocmd CursorMoved
endfunction

function! matchtag#Toggle()
  if exists('g:loaded_matchtag') && g:loaded_matchtag
    call matchtag#Log('Disable')
    call matchtag#DisableMatchTag()
  else
    call matchtag#Log('Enable')
    call matchtag#EnableMatchTag()
  endif
endfunction

function! matchtag#ToggleBoth()
  let s:both = 1 - s:both
  silent! doautocmd CursorMoved
endfunction

function! matchtag#Log(msg)
  if s:debug
    echom '['.s:name.']['.v:lnum.'] '.a:msg
  endif
endfunction
"}}}
