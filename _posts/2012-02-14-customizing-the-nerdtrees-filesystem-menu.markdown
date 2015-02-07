---
layout: post
title: "Customizing the NERDTree's Filesystem Menu"
date: 2012-02-14 22:17
comments: true
categories: vim
---

For quite a while, the NERDTree has had some simple scripting capabilities. At
some point, I decided to use these to override the basic filesystem menu it
provides to something a bit weirder. My problem with the default menu was its
lack of vim keybindings. Being in command mode is usually not an issue, since
it's fairly rare, but I got really used to moving and renaming files through
the tree, so it was time to improve the experience a bit.

<!-- more -->

To that end, I created a one-line buffer at the very bottom of the window and
made a few mappings to cancel the operation and to perform it. The end result
looks a bit like this:

![Move dialog](/images/move_dialog.png)

Pressing Enter in insert or normal mode performs the "Move" operation, and
pressing `<esc>` or `<C-c>` cancels it. The code is fairly simple. I've
annotated the details in comments:

``` vim
function! NERDTreeInputBufferSetup(node, content, cursor_position, callback_function_name)
  " Create a one-line buffer, below everything else
  botright 1new

  " Since I'm using the Acp plugin (http://www.vim.org/scripts/script.php?script_id=1879),
  " I'd rather disable it in the input buffer to avoid problems when pressing
  " the Enter key.
  if exists(':AcpLock')
    AcpLock
    autocmd BufLeave <buffer> AcpUnlock
  endif

  " If we leave the buffer, cancel the operation
  autocmd BufLeave <buffer> q!

  " Set the content, and store the callback and the NERDTree node in the
  " buffer, so they're available for later.
  call setline(1, a:content)
  setlocal nomodified
  let b:node     = a:node
  let b:callback = function(a:callback_function_name)

  " Disallow opening new lines
  nmap <buffer> o <nop>
  nmap <buffer> O <nop>

  " Mappings that cancel the action
  nmap <buffer> <esc> :q!<cr>
  nmap <buffer> <c-[> :q!<cr>
  map  <buffer> <c-c> :q!<cr>
  imap <buffer> <c-c> :q!<cr>

  " Decide on the position of the cursor.
  "
  " If it's "basename", the cursor is positioned on the basename of the node
  " (the final path segment). This is useful for moving and copying nodes.
  "
  " If it's "append", enter insert mode at the end of the buffer. Nice for
  " creating new files easily.
  "
  if a:cursor_position == 'basename'
    normal! $T/
  elseif a:cursor_position == 'append'
    call feedkeys('A')
  endif

  " On pressing the Enter key, invoke the given callback with the node and the
  " final content of the buffer. The actual execution of the callback is
  " delegated to another function, so that the buffer can be closed.
  nmap <buffer> <cr>      :call NERDTreeInputBufferExecute(b:callback, b:node, getline('.'))<cr>
  imap <buffer> <cr> <esc>:call NERDTreeInputBufferExecute(b:callback, b:node, getline('.'))<cr>
endfunction

function! NERDTreeInputBufferExecute(callback, node, result)
  " Close the input buffer
  q!

  " Invoke the callback
  call call(a:callback, [a:node, a:result])
endfunction
```

The action to perform has to be in a different function. The name is given to the input buffer setup function. A sample invocation that sets up a "Move" command could look like this:

``` vim
function! NERDTreeMoveNodeWithTemporaryBuffer()
  let current_node = g:NERDTreeFileNode.GetSelected()
  let path         = current_node.path.str()

  call NERDTreeInputBufferSetup(current_node, path, 'basename', 'NERDTreeExecuteMove')
  setlocal statusline=Move
endfunction

function! NERDTreeExecuteMove(current_node, new_path)
  " Actual move logic goes here...
endfunction
```

I took the actual moving logic from the standard filesystem menu, so there's
nothing interesting there. The full code for my overrides, which include adding
and copying nodes, can be found
[on github](https://github.com/AndrewRadev/Vimfiles/blob/07678f2daca3c001a0c09b32f7dbbded72b62dcc/nerdtree_plugin/fs_buffer_menu.vim).
Note that I put the following code at the top:

``` vim
if exists("g:loaded_nerdree_buffer_fs_menu")
  finish
endif
let g:loaded_nerdtree_fs_menu       = 1 " Don't load default menu
let g:loaded_nerdree_buffer_fs_menu = 1
```

Most of this is standard "load once" stuff, but I've also set
`g:loaded_nerdtree_fs_menu` to avoid conflicting with the default NERDTree
menu. This only makes sense if I'm sure my overrides will be loaded first,
though. In my case, since I have a folder `nerdtree_plugin` in the root of my
vimfiles, this is going to be loaded before any bundles. If you use a separate
bundle or a different method, you might have a problem. You could rename it
somehow, or you could just delete the original `fs_menu.vim` file. I can't
really think of a different workaround at the moment.

It's a bit more overhead to set up, unfortunately, so I may try to improve on
it in the future. For now, though, it's good enough to re-use. A different task
I used it for is setting up an "imagemagick" menu option for images:

``` vim
if exists('g:loaded_nerdree_imagemagick_menu')
  finish
endif
let g:loaded_nerdree_imagemagick_menu = 1

call NERDTreeAddMenuItem({
      \ 'text':     '(i)magemagick processing',
      \ 'shortcut': 'i',
      \ 'callback': 'NERDTreeImageMagickProcessing'
      \ })

function! NERDTreeImageMagickProcessing()
  let current_file = g:NERDTreeFileNode.GetSelected()

  if current_file == {}
    return
  else
    " The path is relative to make it a bit easier to manipulate
    let path = fnamemodify(current_file.path.str(), ':.')

    call lib#NERDTreeInputBufferSetup(current_file, path, 'basename', 'NERDTreeExecuteConvert')
    setlocal statusline=Convert
  endif
endfunction

function! NERDTreeExecuteConvert(node, command_line)
  " Examples:
  "
  "   convert /some/file/name.jpg /some/file/name.png
  "   convert /some/file/name.jpg -resize 100x100 /some/file/name.jpg
  "
  let external_command = 'convert '.a:node.path.str().' '.a:command_line

  echomsg external_command
  let output = system(external_command)

  if v:shell_error == 0
    redraw
    echomsg 'Image converted as '.a:command_line
    call b:NERDTreeRoot.refresh()
    call NERDTreeRender()
  else
    echohl WarningMsg
    echomsg 'Error in command line: '.output
    echohl None
  endif
endfunction
```

So, now, pressing `mi` on a file lets me quickly convert an image to a
different format or resize it.
