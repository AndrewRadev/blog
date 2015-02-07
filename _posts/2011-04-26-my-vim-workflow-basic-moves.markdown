---
layout: post
title: "My Vim Workflow: Basic Moves"
date: 2011-04-26 22:15
comments: true
categories: vim
---

To start off, I'll write about something I've actually seen interest in from
people I know -- my Vim configuration. I'll try to explain my personal workflow
and maybe share some useful tricks along the way. For now, I'll limit myself to
the basic stuff and exclude plugin-related wizardry, maybe I can devote another
blog post to some of the plugins I can't live without.

<!-- more -->

## Moving within a buffer

The most fundamental of all movements is the holy `hjkl`. As any permanently
vim-damaged person will tell you, this is what you use to move around, not the
arrow keys. Unfortunately, I've had two annoyances with the default behavior of
`j` and `k` in particular.

The first one is not going through visual lines. I strongly prefer
[line wrapping](http://vimdoc.sourceforge.net/htmldoc/options.html#%27wrap%27)
and I always end up trying to go to the next/previous visual line, only to be
sent to the next/previous real line and start thinking about how to get back.
Since I believe that having to exert conscious thought while moving around is
not a very good idea in Vim, overriding this default is one of the more
important things in my configuration:

``` vim
nnoremap j gj
nnoremap k gk
xnoremap j gj
xnoremap k gk
```

The other one is that they're really, really slow. I don't mean response time,
it's just difficult to use them for navigating up and down bodies of code,
especially when scrolling is involved, since they only go one line at a time.
Some people use the built-in mappings to move up and down by pages, but the
rapid jumps tend to confuse me. I'd much rather like to be able to move through
lines with a bigger step. An obvious mapping to that end (or at least obvious
in hindsight) is:

``` vim
nmap J 5j
nmap K 5k
xmap J 5j
xmap K 5k
```

This way, whenever I want to jump around more quickly, I just hold down the
shift key and when I want to slow down and be more precise, I let go of it.
Note that I'm using `nmap`, not `nnoremap`, since I want to keep the mappings
for the visual lines that I explained above.

This one is a lot more intrusive, though. `J` is used reasonably often for
joining lines together, but instead of that, I just use `:join`. As for `K`,
it's mapped to showing the manual for the word under the buffer, but it really
doesn't seem like something that's used often enough to warrant a single key on
the home row (and I usually prefer googling anyway).

## Moving around buffers

To move efficiently between splits, I use these simple mappings:

``` vim
nmap gh <C-w>h
nmap gj <C-w>j
nmap gk <C-w>k
nmap gl <C-w>l
```

Nothing fancy, but much easier on the fingers than the
[original ones](http://vimdoc.sourceforge.net/htmldoc/windows.html#CTRL-W_j).
`g` might seem like an odd key to use for the combination, but I find it's been
a very good decision. I move through splits _a lot_, and that key is on the
home row on the left hand -- the perfect spot in combination with `hjkl`, since
I'm a bit of a touch-typist.

On the other hand, `gt` and `gT`
([click](http://vimdoc.sourceforge.net/htmldoc/tabpage.html#gt)) are a horrible
finger combo to me, since they need to be pressed with the same hand. Adding
this mapping was essential for me to be able to whiz through tabs just as
easily as with splits:

``` vim
nmap <C-l> gt
nmap <C-h> gT
```

Again, nothing fancy, but I did say I'm sticking to my basic moves in this
post.

## Opening and closing buffers

One thing I find annoying in "normal" editors is opening buffers. Usually, when
you open a file in, say, notepad++, it appears in a new tab and all others
remain where they are. At some point, I have tons of tabs around for all kinds
of files I don't care about anymore and I can't locate anything I need. In Vim,
I usually maintain a few tabs, each of which has several (usually less than
three) horizontal splits, and I know what I have on each one. Whenever I want
to open a new buffer, I can replace the current one if I don't need it, I can
pop it up in a split if it's related to the current file (a test file, for
example), or I can open it in a new tab if it's related to a different context.

My actual interface to doing this is the awesome
[NERDTree plugin](http://www.vim.org/scripts/script.php?script_id=1658).
It's not without its little flaws, but it's definitely a life-changer. It has
mappings for opening up files in all the ways I described above, and more.

By the way, an interesting (and somewhat amusing) fact is that you can actually
write plugins for the NERDTree plugin, so you can add custom menu items and
mappings. I have a few experimental ones
[here](https://github.com/AndrewRadev/Vimfiles/tree/master/nerdtree_plugin)
-- nothing too complicated, but my point is that it's a fairly extensible tool.

As for closing buffers, something I've found particularly useful is this:

``` vim
nnoremap QQ :QuitTab<cr>
command! QuitTab call s:QuitTab()
function! s:QuitTab()
  try
    tabclose
  catch /E784/ " Can't close last tab
    qall
  endtry
endfunction
```

A bit more involved, but actually not that difficult to understand. I use
`:tabclose` to attempt to close the current tab page. If it's the last one, an
error is raised, so I just catch it and quit instead. The particular problem I
was trying to solve was having a NERDTree opened on each tab. That meant that
even if I have a single buffer in the tab, a simple `:q` would not be enough.
And since `:tabc` is way too long and doesn't work for a single page, I just
came up with a slightly more elaborate combination that does what I need and
mapped it to QQ.

## Probably enough for the moment...

I have a ton of small tricks in my vimfiles, but this post's taken me more than
a week of twiddling (did I mention I'm new at this?), so I figure that's good
enough to publish for now. It's not like I'm in a rush or anything. I'll
(obviously) ask in my vicinity for opinions, but if you're somebody I haven't
talked to and you happen to have one, feel free to drop a comment.
