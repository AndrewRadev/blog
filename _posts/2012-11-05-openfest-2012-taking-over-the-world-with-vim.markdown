---
layout: post
title: "OpenFest 2012: Taking Over the World with Vim"
date: 2012-11-05 16:35
comments: true
categories: vim talks
---

This year, I did a talk at [OpenFest](http://openfest.org/) about Vim. I tried
to make a few interesting points about Vim and why it's awesome. In the end,
it turned out to have too much talk and not enough mind-blowing plugin demos,
which I should probably work on for next time.

For now, I'd like to quickly go over the three main points that I hope people
took away from the talk. The slides are uploaded to
[speakerdeck](https://speakerdeck.com/andrewradev/kak-da-prievziemiem-svieta-s-vim-openfest-2012),
though they're almost certainly useless without the demos and my explanations
(not to mention they're in Bulgarian).

<!-- more -->

## It's not about speed, it's about comfort

A similar point was made recently in
[this blog post](http://jh.chabran.fr/post/30305487513/vim-isnt-about-speed).
Honestly, I'm surprised more people don't think this way. Most arguments for
why you should use Vim is that it makes you fast. Which is true, but only by
corollary. More importantly, it's just so damn convenient. Its mappings are
excellent at helping you not think about the details of what you're doing as
opposed to the result you want to get. Once you're in "the zone", it's like the
keyboard is no longer there and you have a direct interface to the code. Most
of the plugins I write attempt to smooth over any remaining use cases that make
me lose my focus when coding --
[multiline vs single-line code](https://github.com/AndrewRadev/splitjoin.vim),
[often-made substitutions](https://github.com/AndrewRadev/switch.vim),
[whitespace adjustment](https://github.com/AndrewRadev/whitespaste.vim), and so on.
Once you feel so comfortable with your editor that you can use it easily 8
hours a day at work and then some more on the couch at home, it's no wonder
you'll be fast with it.

## Just a text editor

The phrase "just a text editor" is used very often to describe Vim, but I find
it a bit vague. To me, there are two main points to this.

First, Vim is built entirely **from** text. Sure, there are some GUI elements
in Gvim, but they can be safely ignored for what I'm trying to say. Everything
in Vim is built using text and text alone. File managers, archive editing, even
editing images. This is in opposition to "normal" editors which provide special
cases for showing you lists of files, for version control integration, for
project management. In Vim, this functionality is not built by the core
developers, but by plugin authors instead. Vim has a certain lisp-like elegance
in this regard. Just like everything in lisp is "just a list", everything in
Vim is "just text". And if you can create a useful textual representation of
something, it's completely possible that Vim can be used to help with
efficiently navigating or changing it.

Second, Vim doesn't implement many features that don't directly help with
editing text. Instead, in true Unix tradition, it relies on external programs
to do their job and report back. Sure, you can edit a PNG with Vim, but it's
not like you'll find a PNG parser in its source code -- it uses imagemagick
instead. You can rely on external tools to provide completion for programming
languages, make requests to websites, even read pdfs and word documents. Vim is
"just a text editor", so it focuses on doing what it does best.

## Extensibility

There's a lot of fun in taking a bare-bones Vim and turning it into a weapon of
mass destruction. You don't get lots of power by default, but as you learn new
technologies and change your way of thinking, you can shape it to fit you
perfectly. The extent to which it can be customized is staggering -- to this
day, I haven't seen two configurations that implement the same workflow.
There's no "right" way to use it -- just get comfortable with its basics and
start looking for your own way of editing text. There's no shortage of plugins,
tips and tricks for you to try out along the way.

## In short

Vim's awesome and you should use it. Even if you eventually switch to something
else, the lessons learned will probably be of help.
