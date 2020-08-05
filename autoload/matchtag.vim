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
  if exists('w:matchtag_hl_on') && w:matchtag_hl_on
    silent! call s:DeleteMatch()
    let w:matchtag_hl_on = 0
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
  let [cursor_row, cursor_col] = save_cursor[1:2]
  let bracket_col = match(getline('.'), '^\s*\zs<') + 1
  if cursor_col < bracket_col
    call cursor(0, bracket_col)
  endif

  let [row, col] = s:GetTagPos(1)
  if row
    " Find current tag
    let tagname = s:GetTagName(row, col)
    let pos = [[row, col+1, len(tagname)]]
    call matchtag#Log('On tag '.tagname)

    " Set cursor to tag start to search backward correctly
    call cursor(row, col)

    " Find matching tag
    let [match_row, match_col, offset] = s:SearchMatchTag(tagname)
    if match_row
      let match_tagname = s:GetTagName(match_row, match_col)

      " Highlight tags
      let cursor_on_tag = cursor_row == row
            \ && cursor_col >= col 
            \ && cursor_col <= (col+len(tagname)+1)
      if !cursor_on_tag || s:both
        call matchaddpos('MatchTag', pos, 10, s:match_id)
      endif
      let match_pos = [[
            \match_row, 
            \match_col+offset, 
            \len(match_tagname)+1-offset
            \]]
      call matchaddpos('MatchTag', match_pos, 10, s:match_id+1)
      let w:matchtag_hl_on = 1
      call matchtag#Log('Matching tag '.match_tagname)
    else
      let w:matchtag_hl_on = 1
      call matchaddpos('MatchTagError', pos, 10, s:match_id)
      call matchtag#Log('Matching tag Not found')
    endif
  endif

  call setpos('.', save_cursor)
endfunction

" Compare two positions
" 0: pos1 is after pos2
" 1: pos1 is ahead of pos2
function! s:IsAheadOf(pos1, pos2)
  let [row1, col1] = a:pos1
  let [row2, col2] = a:pos2
  if row1 == row2 && col1 > col2
        \ || row1 > row2
    return 0
  else
    return 1
  endif
endfunction

function! s:IsEmptyPos(pos)
  let [row, col] = a:pos
  return row == 0 && col == 0
endfunction

function! s:NotAfter(main, excludes)
  let regexp = '\('.join(split(a:excludes, ','), '\|').'\)'
  return a:main.regexp.'\@!'
endfunction

function! s:NotBefore(main, excludes)
  let regexp = '\('.join(split(a:excludes, ','), '\|').'\)'
  return regexp.'\@<!'.a:main
endfunction

" Regexps that are used to check whether the cursor is on a tag
" Ignore 
" - '/>' in empty tag 
" - '<?', '?>' in php tags
" - '<!--', '-->' in html comments
" - '=>' in JavaScript
function! s:GetTagPos(check_nearby_tag)
  call matchtag#Log('GetTagPos ---------')
  let timeout = s:timeout

  let open_bracket = searchpos(s:NotAfter('<', '?,!'), 'bcnW', line('w0'), timeout)
  if s:IsEmptyPos(open_bracket)
    call matchtag#Log('Not on/in tag, no open bracket')
    return [0,0]
  endif
  let close_bracket = searchpos(s:NotBefore('>', '?,='), 'bnW', line('w0'), timeout)
  let has_nearby_open = s:IsAheadOf(close_bracket, open_bracket)
  let has_nearby_close = !has_nearby_open

  let open_bracket_forward = searchpos(s:NotAfter('<', '?'), 'nW', line('w$'), timeout)
  let close_bracket_forward = searchpos(s:NotBefore('>', '/,?,-,='), 'cnW', line('w$'), timeout)
  if s:IsEmptyPos(close_bracket_forward)
    call matchtag#Log('Not on/in tag, no close bracket')
    return [0,0]
  endif
  let has_nearby_close_forward = s:IsAheadOf(close_bracket_forward, open_bracket_forward)
        \ || s:IsEmptyPos(open_bracket_forward)
  let has_nearby_open_forward = !has_nearby_close_forward

  if has_nearby_open && has_nearby_close_forward
    call matchtag#Log('On tag')
    return open_bracket
  endif

  if has_nearby_open_forward && a:check_nearby_tag
    let line = getline(open_bracket_forward[0])
    let is_close_tag = line[open_bracket_forward[1]] == '/'
    if is_close_tag
      call cursor(open_bracket_forward)
      call matchtag#Log('Move to close tag ->')
      return s:GetTagPos(0)
    endif
  endif
  if has_nearby_close && a:check_nearby_tag
    let line = getline(open_bracket[0])
    let is_open_tag = line[open_bracket[1]] != '/'
    if is_open_tag
      call cursor(close_bracket)
      call matchtag#Log('Move to open tag ->')
      return s:GetTagPos(0)
    endif
  endif

  call matchtag#Log('Not on/in tag '.has_nearby_open.', '.has_nearby_close_forward)
  return [0, 0]
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
    echom '['.s:name.'] '.a:msg
  endif
endfunction
"}}}
