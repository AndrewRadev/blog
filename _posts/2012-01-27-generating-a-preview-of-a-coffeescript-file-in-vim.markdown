---
layout: post
title: "Generating a Preview of a Coffeescript File in Vim"
date: 2012-01-27 16:26
comments: true
categories: vim, coffeescript
---

I started writing a bit of coffeescript recently. One of its benefits is that
the javascript it generates is fairly readable, which really helps in the
learning process. To make it easier to see it, I whipped up some vimscript to
open up a split window with the generated javascript and update it every time
the file is saved. In this short post, I'll just show the code and explain a
bit about how it works.

<!-- more -->

*Update: turns out, the official
[coffee-script plugin for Vim](https://github.com/kchmck/vim-coffee-script)
already defines a command to do something like this: `CoffeeWatch`.
Guess I should have read the docs more carefully :).*

The first step is setting up some parameters:

``` vim
function! SetupPreview(extension, command)
  let b:preview_file    = tempname().'.'.a:extension
  let b:preview_command = printf(a:command, shellescape(expand('%')))
  let b:preview_command .= ' > ' . b:preview_file . ' 2>&1'

  autocmd BufWritePost <buffer>
        \ if bufwinnr(b:preview_file) >= 0 |
        \   call UpdatePreview()           |
        \ endif
endfunction
```

After calling it with `SetupPreview('js', 'coffee -p %s')`, this generates a
temporary name for the preview file and stores that and the command in
buffer-local variables. It also schedules an update to the buffer on every
save, provided the window is still open. Note that the generated command uses
shell redirection, so there's no chance of it running on Windows.

This should be called in an ftplugin vim file:

``` vim
" ftplugin/coffee.vim
call SetupPreview('js', 'coffee -p %s')
```

Next, how to actually start the functionality:

``` vim
command! Preview call s:InitPreview()

function! s:InitPreview()
  if !exists('b:preview_file')
    echoerr 'No preview command has been defined for this buffer.'
    return
  endif

  if bufwinnr(b:preview_file) < 0
    let original_buffer = bufnr('%')
    exe 'split '.b:preview_file
    call s:SwitchWindow(original_buffer)
  endif

  call UpdatePreview()
endfunction
```

Executing `:Preview` opens up the buffer with the temporary file, goes back to
the original one and triggers an update.

``` vim
function! UpdatePreview()
  if !exists('b:preview_file') || bufwinnr(b:preview_file) < 0
    return
  endif

  call system(b:preview_command)

  let original_buffer = bufnr('%')
  call s:SwitchWindow(b:preview_file)
  silent edit!
  syntax on " workaround for weird lack of syntax
  normal! zR
  call s:SwitchWindow(original_buffer)
endfunction

function! s:SwitchWindow(bufname)
  let window = bufwinnr(a:bufname)
  exe window.'wincmd w'
endfunction
```

`UpdatePreview()` is called once on `:Preview` and automatically on every save.
It executes the stored shell command and does an `:edit!` in the preview
buffer. The function `s:SwitchWindow` simply finds a window in the current tab,
corresponding to a buffer, and jumps to it.

The full source can be found [here](https://gist.github.com/1688979). If you're
wondering why it expects the extension and the external command as parameters,
it's because you can use the same code for other kinds of preprocessing. To get
it to work for markdown, this should be enough:

``` vim
" fplugin/markdown.vim
call SetupPreview('markdown', 'markdown %s')
```
