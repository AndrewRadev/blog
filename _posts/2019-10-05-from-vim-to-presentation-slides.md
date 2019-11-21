---
layout: post
title: "From Vim to Presentation Slides"
date: 2019-10-05 08:00
comments: true
categories: vim talks
published: true
---

There's a little-known Vim command called [`:TOhtml`](https://vimhelp.org/syntax.txt.html#convert-to-HTML) that does something quite surprising for a built-in -- it converts the current Vim window into raw HTML. This includes syntax highlighting for code, and even line numbers. It can convert the full buffer or a range of selected lines.

While I've always considered it a fun trick, it was somewhat recently that I realized it has a very practical use -- to paste syntax-highlighted code into presentation slides.

<!-- more -->

## The Process

First off, HTML is a good start, but it needs to be parsed as Rich Text Format:

``` vim
" Main entry point, the :Tortf command, translates the given range as (start,
" end) parameters for the function that does the real work. Defaults to the
" whole buffer.
command! -range=% Tortf call s:Tortf(<line1>, <line2>)

function! s:Tortf(start, end)
  " We need a temporary file to actually write the HTML to. The :TOhtml
  " command opens a buffer, but doesn't save it:
  "
  let filename = tempname().'.html'

  " We run the command with the given range and save it to the temporary file:
  "
  exe a:start.','.a:end.'TOhtml'
  exe 'write '.filename

  " The `libreoffice` command will figure out how to open an HTML file -- with
  " the "writer" tool:
  "
  call system('libreoffice '.filename.' &')

  " No need to stay in this buffer -- it's done its job, so we can safely get
  " rid of it:
  quit!
endfunction
```

This command-function pair can live in your `.vimrc` or in a file in the `~/.vim/plugin` directory. Once I've set an appropriate light scheme, ran the `:gui` command to ensure I've got the right colors, I can execute the `:Tortf` command and get something like this:

![Code in libreoffice](/images/to_rtf.png)

Now I can copy that code and try to paste it in a LibreOffice Impress presentation. Instead of just using `Ctrl+V`, though, it's better to "Paste special". On the current LibreOffice version, that's located under **Edit** > **Paste Special** > **Paste Special...**, or it can be triggered with `Shift+Ctrl+V`:

![Paste Special](/images/paste_special.png)

The normal paste tends to change fonts depending on what you're pasting over. Random things get bolded, or colors change. This way tends to produce less surprises.

And that's pretty much it.

## Some Sensible Questions to Ask

### Any problems with this method?

Oh, tons. When I copy a slide, its code ends up centered for some reason, so I need to select it and left-align. Sometimes, colors still get messed up. Editing the code works, but it requires some work to maintain the right syntax highlighting.

Some of this might be LibreOffice bugs, or it might be me not using it correctly. Let me know if you have any solutions I can try!

### Why use LibreOffice at all then?

Frameworks like impress.js are pretty good for code, but I find them less flexible in terms of just positioning graphics and such around. Even with code, I'd occasionally like to position it weirdly or appearify chunks of code one by one, and the PowerPoint model of making presentations gives me that flexibility.

Keynote might be much better, but I'm not a Mac user, so I couldn't say.

### Would this method work with Keynote?

Probably yes, but I can't be sure. You'd need to tweak some of the commands to launch Keynote and some other word processor instead of LibreOffice.

### What about using screenshots instead?

It's an option, but code-as-text means you can make small edits later. It also allows people to select the code from the slides afterwards, even if you export them to PDF.

Mind you, with the existence of tools like [vim-silicon](https://github.com/segeljakt/vim-silicon), screenshots are certainly a more interesting option nowadays.
