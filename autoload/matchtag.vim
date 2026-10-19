"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Settings {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:name = 'vim-matchtag'
let s:match_id = 999
let s:tagname_regexp = '[0-9A-Za-z_.-]'
let s:empty_tagname = '\v<(area|base|br|col|embed|hr|input|img|keygen|link|meta|param|source|track|wbr)>'
let s:component_name = '\v\C^[A-Z]\w+'
let s:exists_text_changed = exists('##TextChanged')

"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Configs {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetConfig(name, default)
  return get(g:, 'vim_matchtag_'.a:name, a:default)
endfunction

let s:highlight_cursor_on = s:GetConfig('highlight_cursor_on', s:GetConfig('both', 0))
let s:debug = s:GetConfig('debug', 0)
let s:timeout = s:GetConfig('timeout', 50)
let s:disable_cache = s:GetConfig('disable_cache',
      \ !s:exists_text_changed)
let s:skip = s:GetConfig('skip', 
      \ 'javascript\|css\|script\|style')
let s:skip_except = s:GetConfig('skip_except', 
      \ 'html\|template\|tsx\|jsx')
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
    call s:DeleteMatch()
    let w:matchtag_hl_on = 0
  endif

  " Avoid removing the popup menu.
  " Or return when there are no colors
  if pumvisible() || (&t_Co < 8 && !has('gui_running'))
    return 
  endif

  " Skip if current position contains specific syntax
  if s:IsInSkipSyntax()
    call s:Log('Skip syntax')
    return 
  endif

  call s:HighlightTag()
endfunction

let s:cached_lines = {}
let s:cache_key = ''
function! s:ResetLineCache()
  let s:cached_lines = {}
endfunction

if !s:disable_cache
  " Cache lines until the buffer or its text changes, including reloading
  " by :edit!, which doesn't trigger TextChanged
  function! s:GetLine(number)
    let key = bufnr('%').':'.b:changedtick
    if key !=# s:cache_key
      let s:cached_lines = {}
      let s:cache_key = key
    endif
    let number = a:number
    if has_key(s:cached_lines, number)
      return s:cached_lines[number]
    else
      let line = getline(number)
      let s:cached_lines[number] = line
      return line
    endif
  endfunction
else
  function! s:GetLine(number)
    return getline(a:number)
  endfunction
endif

function! s:HighlightTag()
  let save_cursor = getcurpos()

  let [cursor_row, cursor_col] = save_cursor[1:2]
  " Cursor in indent before a tag
  if getline('.')[: cursor_col - 1] =~ '^\s*$'
    let bracket_col = searchpos('^\s*\zs<', 'n', cursor_row, s:timeout)[1]
    if cursor_col < bracket_col
      call cursor(0, bracket_col)
    endif
  endif

  let [row, col] = s:GetTagPos()
  if row
    " Find current tag
    let line = s:GetLine(row)
    let tagname = s:GetTagName(line, col)
    let pos = [[row, col+1, len(tagname)]]
    call s:Log('On tag '.tagname)

    " Set cursor to tag start to search backward correctly
    call cursor(row, col)

    let self_closing = s:IsSelfClosingTag()
    let [match_row, match_col, offset, searched_all] = self_closing
          \ ? [0, 0, 0, 1]
          \ : s:SearchMatchTag(tagname)
    if match_row " Find matching tag
      let match_line = match_row == row 
            \ ? line 
            \ : s:GetLine(match_row)
      let match_tagname = s:GetTagName(match_line, match_col)

      " Highlight tags
      " Current tag
      let cursor_on_tag = cursor_row == row
            \ && cursor_col >= col 
            \ && cursor_col <= (col+len(tagname)+1)
      if !cursor_on_tag || s:highlight_cursor_on
        call matchaddpos('MatchTag', pos, 10, s:match_id)
      endif
      " Matching tag
      let match_pos = [[
            \match_row, 
            \match_col+offset, 
            \len(match_tagname)+1-offset
            \]]
      call matchaddpos('MatchTag', match_pos, 10, s:match_id+1)
      call s:Log('Matching tag '.match_tagname)
    else " No matching tag found
      if self_closing || s:IsEmptyTag(tagname)
        " Current tag is emtpy
        call matchaddpos('MatchTag', pos, 10, s:match_id)
        call s:Log('Current tag is empty: '.tagname)
      elseif searched_all
        " Matching tag not found
        call matchaddpos('MatchTagError', pos, 10, s:match_id)
        call s:Log('Matching tag Not found')
      else
        " Matching tag may be out of window, or the search timed out
        call s:Log('Matching tag Not found in window')
      endif
    endif
    let w:matchtag_hl_on = 1
  endif

  call setpos('.', save_cursor)
endfunction

function! s:IsEmptyTag(tagname)
  return match(a:tagname, s:empty_tagname) != -1 
        \|| match(a:tagname, s:component_name) != -1
endfunction

" Compare two positions
" 0: pos1 is after pos2
" 1: pos1 is ahead of pos2
function! s:IsAheadOf(pos1, pos2)
  let [row1, col1] = a:pos1
  let [row2, col2] = a:pos2
  if row2 > row1 || (row2 == row1 && col2 > col1)
    return 1
  else
    return 0
  endif
endfunction

function! s:IsEmptyPos(pos)
  let [row, col] = a:pos
  return row == 0 && col == 0
endfunction

function! s:IsSamePos(pos1, pos2)
  let [row1, col1] = a:pos1
  let [row2, col2] = a:pos2
  return row1 == row2 && col1 == col2
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
let s:open_bracket_regexp = s:NotAfter('<', '?,!')
let s:close_bracket_regexp = s:NotBefore('>', '?,=')
let s:open_bracket_forward_regexp = s:NotAfter('</', '?')
let s:close_bracket_forward_regexp = s:NotBefore('>', '?,-,=')

function! s:GetTagPos()
  call s:Log('GetTagPos')

  if s:IsInComment()
    call s:Log('In coment, skip')
    return [0, 0]
  endif

  let timeout = s:timeout
  let firstline = line('w0')
  let lastline = line('w$')

  " Search for '<' backward
  let open_bracket = searchpos(s:open_bracket_regexp, 'cbnW', firstline, timeout)
  " Search for '>' backward
  let close_bracket = searchpos(s:close_bracket_regexp, 'bnW', firstline, timeout)

  let near_open = s:IsAheadOf(close_bracket, open_bracket)
  let near_close = !near_open

  " Search for '<' forward
  let open_bracket_forward = searchpos(s:open_bracket_forward_regexp, 'nW', lastline, timeout)
  " Search for '>' forward
  let close_bracket_forward = searchpos(s:close_bracket_forward_regexp, 'cnW', lastline, timeout)

  let near_close_forward = s:IsAheadOf(close_bracket_forward, open_bracket_forward)
        \ || s:IsEmptyPos(open_bracket_forward)
  let near_open_forward = !near_close_forward

  " On tag
  if near_open && near_close_forward
    call s:Log('On tag')
    return open_bracket
  endif

  " Check if in tag
  " Check forward
  if near_open_forward
    call s:Log('Find close tag forward ')
    return open_bracket_forward
  endif
  " Check backward
  if near_close
    let open_of_closetag
          \ = searchpos('</', 'bcnW', firstline, timeout)
    let close_of_closetag
          \ = searchpos('/\zs>', 'bcnW', firstline, timeout)

    if !s:IsSamePos(open_bracket, open_of_closetag)
          \ && !s:IsSamePos(close_bracket, close_of_closetag) 

      let line = s:GetLine(open_bracket[0])
      let tagname = s:GetTagName(line, open_bracket[1])
      if s:IsEmptyTag(tagname)
        call s:Log('After an empty tag')
        return [0, 0]
      endif

      call s:Log('Find open tag backward')
      return open_bracket
    endif
  endif

  " Not on/in tag
  if s:IsEmptyPos(open_bracket)
    call s:Log('Not on/in tag, no open bracket')
    return [0, 0]
  endif
  if s:IsEmptyPos(close_bracket_forward)
    call s:Log('Not on/in tag, no close bracket')
    return [0, 0]
  endif

  call s:Log('Not on/in tag, <: '.near_open.', >: '.near_close_forward)
  return [0, 0]
endfunction

function! s:GetTagName(line, col)
  let line = a:line
  let col = a:col

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
    let name = tagname[1:]
    let flags = flags.'b'

    " Don't include '<' if search backward
    let offset = 1
  else
    let name = tagname
    let offset = 0
  endif
  " Match the whole tag name only, e.g. not '<div' in '<divider'
  " or '/img' in 'src="./img/a.png"'
  let name = escape(name, '.').'\%('.s:tagname_regexp.'\)\@!'
  let start = '<'.name
  let end = '<\zs/'.name
  " Search in window only like matchparen. The matching tag out of window
  " can't be seen, and searching the whole file may be slow
  let stopline = flags =~ 'b'
        \ ? min([line('w0'), line('.')])
        \ : max([line('w$'), line('.')])
  let start_time = reltime()
  let [row, col] = searchpairpos(start, '', end, flags, function('s:SkipMatch'), stopline, s:timeout)

  " Whether the whole file was searched, so a missing match is an error
  let searched_all = stopline == (flags =~ 'b' ? 1 : line('$'))
        \ && (s:timeout <= 0
        \      || reltimefloat(reltime(start_time)) * 1000 < s:timeout)
  return [row, col, offset, searched_all]
endfunction

function! s:SkipMatch()
  return s:IsInCommentOrString() || s:IsSelfClosingTag()
endfunction

" Check if the tag starting at cursor ends with '/>', e.g. <div />
" '>' inside quotes or braces like {() => ...} is ignored
let s:self_closing_max_lines = 50
function! s:IsSelfClosingTag()
  let [lnum, col] = [line('.'), col('.') - 1]
  let line = s:GetLine(lnum)
  if line[col] != '<' || line[col + 1] == '/'
    return 0
  endif

  let last = min([line('$'), lnum + s:self_closing_max_lines])
  let quote = ''
  let depth = 0
  let prev = ''
  let col += 1
  while lnum <= last
    while col < len(line)
      let char = line[col]
      if !empty(quote)
        if char == quote
          let quote = ''
        endif
      elseif char =~ '["'']' || (char == '`' && depth > 0)
        let quote = char
      elseif char == '{'
        let depth += 1
      elseif char == '}'
        let depth -= 1
      elseif char == '>' && depth <= 0
        return prev == '/'
      endif
      if char !~ '\s'
        let prev = char
      endif
      let col += 1
    endwhile
    let lnum += 1
    let line = s:GetLine(lnum)
    let col = 0
  endwhile
  return 0
endfunction

function! s:IsInCommentOrString()
  let names = s:SynNames()
  return s:containSyntax(names, '\ccomment\|string$')
endfunction

function! s:IsInComment()
  let names = s:SynNames()
  return s:containSyntax(names, '\ccomment$')
endfunction

function! s:IsInSkipSyntax()
  let names = s:SynNames()
  if empty(names)
    " Don't skip empty syntax to support treesitter
    return 0
  else
    return s:containSyntax(names, s:skip)
          \&& !s:containSyntax(names, s:skip_except)
  endif
endfunction

function! s:SynNames()
  let ids = synstack(line('.'), col('.'))
  return map(ids, { _, id -> synIDattr(id, 'name') })
endfunction

" Ignore case, e.g. 'javascript' matches 'javaScript' in html syntax
function! s:containSyntax(names, pat)
  if empty(a:pat)
    return 0
  endif

  for syn in a:names
    if syn =~? a:pat
      return 1
    endif
  endfor
  return 0
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
    autocmd! matchtag
    execute 'autocmd! CursorMoved,CursorMovedI,WinEnter '.files
          \.' call matchtag#HighlightMatchingTag()'

    " Clear match for all buffers
    autocmd BufWinEnter * call s:DeleteMatch()

    if s:exists_text_changed
      execute 'autocmd! TextChanged,TextChangedI '.files
            \.' call s:ResetLineCache()'
            \.'|call matchtag#HighlightMatchingTag()'

      execute 'autocmd! BufLeave '.files
            \.' call s:ResetLineCache()'
    endif
  augroup END

  silent! doautocmd CursorMoved
endfunction

function! matchtag#Toggle()
  if exists('g:loaded_matchtag') && g:loaded_matchtag
    call s:Log('Disable')
    call matchtag#DisableMatchTag()
  else
    call s:Log('Enable')
    call matchtag#EnableMatchTag()
  endif
endfunction

function! matchtag#ToggleHighlightCursorOn()
  let s:highlight_cursor_on = 1 - s:highlight_cursor_on
  silent! doautocmd CursorMoved
endfunction

function! s:Log(msg)
  if s:debug
    echom '['.s:name.'] '.a:msg
  endif
endfunction

function! matchtag#Log(msg)
  call s:Log(a:msg)
endfunction

function! matchtag#ReportTime()
  let save_cursor = getcurpos()
  call s:ResetLineCache()

  let total = 0
  let max = 0
  let max_line = 0
  for i in range(1, line('$'))
    call cursor(i, 1)
    let start = reltime()
    call matchtag#HighlightMatchingTag()
    let end = reltime()
    let duration = reltime(start, end)
    echom 'line '.i.', time: '.reltimestr(duration)
    let value = reltimefloat(duration)
    let total += value
    if max < value
      let max = value
      let max_line = i
    endif
  endfor
  let ave = total / line('$')

  call setpos('.', save_cursor)
  echom 'report Ave: '.string(ave)
        \.' Max: '.string(max).' on line '.max_line
endfunction


"}}}
" vim: fdm=marker
