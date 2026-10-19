" Run with test/run.sh, or
"   vim -N -u NONE -i NONE -S test/run.vim
"   nvim --headless -u NONE -i NONE -S test/run.vim
" Results are written to $MATCHTAG_TEST_OUT (default: test/results.txt).
" Exit code is 1 if any test fails.

set nocompatible
let s:root = expand('<sfile>:p:h:h')
let s:fixtures = s:root . '/test/fixtures/'
let &runtimepath = s:root . ',' . &runtimepath
if &t_Co < 8
  set t_Co=256
endif
filetype on
syntax on
runtime plugin/matchtag.vim

let s:results = []
let s:failed = 0

" Highlights as 'group:row,col,len', ordered by match id
function! s:Highlights()
  let matches = sort(getmatches(), { a, b -> a.id - b.id })
  return join(map(matches,
        \ { _, m -> m.group . ':' . join(get(m, 'pos1', []), ',') }), ' ')
endfunction

function! s:Expect(desc, lnum, col, expected)
  call cursor(a:lnum, a:col)
  redraw
  call matchtag#HighlightMatchingTag()
  let actual = s:Highlights()
  if actual ==# a:expected
    call add(s:results, 'ok   ' . a:desc)
  else
    let s:failed += 1
    call add(s:results, 'FAIL ' . a:desc)
    call add(s:results, '       expected: ' . string(a:expected))
    call add(s:results, '       actual:   ' . string(actual))
  endif
endfunction

function! s:Open(file)
  execute 'silent edit! ' . fnameescape(a:file)
endfunction

" HTML {{{
call s:Open(s:fixtures . 'html.html')
call s:Expect('html: <header> skips "/header" in src path', 1, 2, 'matchTag:19,2,7')
call s:Expect('html: </header>', 19, 3, 'matchTag:1,2,6')
call s:Expect('html: <divider> is not <div>', 6, 4, 'matchTag:6,13,8')
call s:Expect('html: <div> containing self-closing divs', 7, 4, 'matchTag:17,4,4')
call s:Expect('html: </div> after self-closing divs', 17, 5, 'matchTag:7,4,3')
call s:Expect('html: self-closing <div /> as empty tag', 9, 6, 'matchTag:9,6,3')
call s:Expect('html: <resource> is not "/resources"', 18, 4, 'matchTag:18,32,9')
call s:Expect('html: <AppBar.Trail>', 20, 2, 'matchTag:20,17,13')

" Without syntax, e.g. treesitter
syntax off
call s:Expect('no syntax: <header> skips "/header" in src path', 1, 2, 'matchTag:19,2,7')
call s:Expect('no syntax: </header>', 19, 3, 'matchTag:1,2,6')
syntax on
" }}}

" Cursor in indent {{{
call s:Open(s:fixtures . 'indent.html')
setlocal shiftwidth=2
call s:Expect('indent: line 1, col 1 before <div>', 1, 1, 'matchTag:1,6,3 matchTag:3,6,4')
call s:Expect('indent: line 1, col 3 before <div>', 1, 3, 'matchTag:1,6,3 matchTag:3,6,4')
call s:Expect('indent: line 2, col 3 before <p>', 2, 3, 'matchTag:2,8,1 matchTag:2,12,2')
call s:Expect('indent: text inside <span>', 6, 1, 'matchTag:7,2,5 matchTag:4,2,4')
" }}}

" Script and errors {{{
call s:Open(s:fixtures . 'script.html')
call s:Expect('script: "<b" in JS is skipped', 3, 18, '')
call s:Expect('script: blank line in JS is skipped', 4, 1, '')
" Like the cursor at the end of line in Insert mode
set virtualedit=onemore
call s:Expect('script: end of line in JS is skipped', 3, col([3, '$']), '')
set virtualedit=
call s:Expect('error: unclosed <b>', 9, 4, 'matchTagError:9,4,1')
" }}}

" TSX / JSX {{{
call s:Open(s:fixtures . 'App.tsx')
call s:Expect('tsx: <div>', 8, 6, 'matchTag:15,6,4')
call s:Expect('tsx: <h1>', 9, 8, 'matchTag:9,24,3')
call s:Expect('tsx: <li> in expression', 12, 12, 'matchTag:12,27,3')
call s:Expect('tsx: </div>', 15, 7, 'matchTag:8,6,3')
call s:Expect('tsx: "<" in Array<string> is skipped', 6, 23, '')

call s:Open(s:fixtures . 'App.jsx')
call s:Expect('jsx: <div>', 7, 6, 'matchTag:14,6,4')
call s:Expect('jsx: </div>', 14, 7, 'matchTag:7,6,3')
" }}}

" Large file {{{
let s:big = tempname() . '.html'
let s:lines = ['<div class="root">']
for s:i in range(400)
  let s:lines += [
        \ '  <div class="row">',
        \ '    <div',
        \ '      class="cell"',
        \ '      onClick={() => go(' . s:i . ')}',
        \ '    />',
        \ '    <span>' . s:i . '</span>',
        \ '    <img src="./img/div.png" />',
        \ '  </div>']
endfor
call add(s:lines, '</div>')
call writefile(s:lines, s:big)
call s:Open(s:big)
call s:Expect('large: <div> with match out of window is not an error', 1, 2, '')
call s:Expect('large: </div> with match out of window is not an error', line('$'), 3, '')
call s:Expect('large: <div> near the end', 1602, 4, 'matchTag:1609,4,4')
call writefile(s:lines[:-2] + ['  <b>unclosed', '</div>'], s:big)
call s:Open(s:big)
call s:Expect('large: unclosed <b> with the file end in window', line('$') - 1, 4, 'matchTagError:3202,4,1')
call delete(s:big)
" }}}

" Reload {{{
let s:file = tempname() . '.html'
call writefile(['<div>', '  <p>x</p>', '</div>'], s:file)
call s:Open(s:file)
call s:Expect('reload: before', 2, 4, 'matchTag:2,8,2')
call writefile(['<div>', '  <span>long</span>', '</div>'], s:file)
edit!
call s:Expect('reload: lines are not cached after :edit!', 2, 4, 'matchTag:2,14,5')
call delete(s:file)
" }}}

" API {{{
try
  call matchtag#Log('test')
  call add(s:results, 'ok   api: matchtag#Log()')
catch
  let s:failed += 1
  call add(s:results, 'FAIL api: matchtag#Log(): ' . v:exception)
endtry
" }}}

call add(s:results, printf('%s: %d passed, %d failed',
      \ has('nvim') ? 'nvim' : 'vim',
      \ len(filter(copy(s:results), 'v:val =~# "^ok"')), s:failed))
call writefile(s:results, empty($MATCHTAG_TEST_OUT)
      \ ? s:root . '/test/results.txt' : $MATCHTAG_TEST_OUT)
if s:failed
  cquit
endif
qall!
" vim: fdm=marker
