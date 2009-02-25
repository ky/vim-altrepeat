"-----------------------------------------------------------------------------
" altrepeat
" Author: ky
" Version: 0.1
" License: The MIT License {{{
" The MIT License
"
" Copyright (C) 2009 ky
"
" Permission is hereby granted, free of charge, to any person obtaining a
" copy of this software and associated documentation files (the "Software"),
" to deal in the Software without restriction, including without limitation
" the rights to use, copy, modify, merge, publish, distribute, sublicense,
" and/or sell copies of the Software, and to permit persons to whom
" the Software is furnished to do so, subject to the following conditions:
" 
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
" 
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
" ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
" OTHER DEALINGS IN THE SOFTWARE.
" }}}
"-----------------------------------------------------------------------------

let s:CHANGEDTICK_RESET = -2
let s:CHANGEDTICK_INVALID = -1

let s:MODE_KEY = 1
let s:MODE_FUNCTION = 2


let s:changedtick = s:CHANGEDTICK_INVALID
"let s:type = 0
let s:sync_changedtick = 0
let s:insert_enter = 0


function! altrepeat#dump()
  call confirm( string([
        \ 's:changedtick'      . ': ' . s:changedtick,
        \ 'b:changedtick'      . ': ' . b:changedtick,
        \ 's:action'           . ': ' . (exists('s:action') ? s:action : ''),
        \ 's:mode'             . ': ' . (exists('s:mode') ? s:mode : ''),
        \ 's:sync_changedtick' . ': ' . s:sync_changedtick,
        \ 's:insert_enter'     . ': ' . s:insert_enter,
        \ 's:count'            . ': ' . (exists('s:count') ? s:count : '')
        \]))
        "\ 's:type'             . ': ' . s:type,
endfunction


" repeat plugin (version 1.0) compatible.
function! altrepeat#set_repeat_key(key_seq, ...)
  let cnt = (a:0 ? a:1 : 0)
  call s:set(a:key_seq, s:MODE_KEY, 0, cnt, [])
endfunction


function! altrepeat#set_repeat_function(func_name, type, ...)
  let cnt = (a:0 ? a:1 : 0)
  let arglist = (a:0 > 1 ? a:2 : [])
  call s:set(a:func_name, s:MODE_FUNCTION, a:type, cnt, arglist)
endfunction


function! s:set(action, mode, type, count, arglist)
  let s:changedtick = b:changedtick
  let s:action = a:action
  let s:mode = a:mode
  "let s:type = a:type
  let s:sync_changedtick = a:type
  let s:insert_enter = 0
  let s:count = a:count
  let s:arglist = a:arglist
  if !a:type
    call s:sync()
  endif
endfunction


function! altrepeat#execute(key_seq, count)
  let keep_changedtick = s:changedtick == b:changedtick

  execute printf('normal! %s%s', a:count ? a:count : '', a:key_seq)

  if keep_changedtick
    let s:changedtick = b:changedtick
  endif
endfunction


function! altrepeat#repeat(count)
  "call altrepeat#dump()
  if s:changedtick == b:changedtick
    let cnt = (
          \ s:count == -1
          \ ? 0
          \ : (a:count ? a:count : (s:count ? s:count : 0))
          \)
    if s:mode == s:MODE_KEY
      execute 'normal ' . (cnt ? cnt : '') . s:action
    elseif s:mode == s:MODE_FUNCTION
      let arglist = copy(s:arglist)
      call insert(arglist, cnt, 0)
      call call(s:action, arglist)
    endif
    call s:sync()
  else
    "execute 'normal! ' . (a:count > 0 ? a:count : '') . '.'
    call feedkeys(
          \ printf('%s%s.', (a:count > 0 ? a:count : ''), s:register()),
          \ 'n'
          \)
  endif
endfunction


function! s:sync()
  "if !s:type
    call feedkeys(":\<C-u>call altrepeat#sync()\<CR>:\<C-c>", 'n')
  "endif
endfunction


function! s:register()
  if v:register ==# '' || v:register ==# '"'
    return ''
  endif
  return '"' . v:register
endfunction


function! altrepeat#sync()
  let s:changedtick = b:changedtick
endfunction


augroup AltRepeatAugroup
  autocmd!
  autocmd BufEnter,BufReadPre,BufWritePre *
        \ let s:changedtick = (
        \   s:changedtick == s:CHANGEDTICK_RESET
        \   ? b:changedtick
        \   : s:CHANGEDTICK_INVALID
        \ )
  autocmd BufLeave,BufReadPost,BufWritePost *
        \ let s:changedtick = (
        \   s:changedtick == b:changedtick
        \   ? s:CHANGEDTICK_RESET
        \   : s:CHANGEDTICK_INVALID
        \ )
  autocmd InsertEnter *
        \ if s:sync_changedtick |
        \   let s:insert_enter = 1 |
        \   let s:sync_changedtick = 0 |
        \ else |
        \   let s:changedtick = s:CHANGEDTICK_INVALID |
        \ endif
  autocmd InsertLeave *
        \ if s:insert_enter |
        \   let s:changedtick = b:changedtick |
        \ endif
  autocmd CursorMovedI *
        \ if s:insert_enter |
        \   let s:changedtick = b:changedtick |
        \ endif
  autocmd CursorMoved *
        \ if s:insert_enter |
        \   let s:insert_enter = 0 |
        \ endif
augroup END


" vim: expandtab shiftwidth=2 softtabstop=2 foldmethod=marker
