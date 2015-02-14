---
layout: page
title: About
permalink: /about/
---

<img class="about-image" src="http://gravatar.com/avatar/fc59401781a26b10f5d4fc5b758fb3b7.png?s=192" alt="Hello, there" />

Hi, my name's Andrew and I'm a programmer. I code mostly in [Ruby](http://ruby-lang.org) and [Rails](http://rubyonrails.org/), but I try to play around with other stuff every once in a while. My current language of interest is [Rust](http://www.rust-lang.org/). I'm also learning R and data science on [coursera](https://www.coursera.org/specialization/jhudatascience/1). You can find me as "AndrewRadev" on [github](http://github.com/AndrewRadev) and on [twitter](http://twitter.com/AndrewRadev).

I'm a dedicated [Vim](http://vim.org) user and I've created a [bunch of Vim plugins](http://www.vim.org/account/profile.php?user_id=31799). I maintain the [VimLinks](https://twitter.com/vimlinks) twitter account, I'm one of the maintainers of the [official ruby bindings for vim](https://github.com/vim-ruby/vim-ruby) (but I'm pretty bad at keeping up with the work there), and I own the runtime files for Vim's [eco support](https://github.com/AndrewRadev/vim-eco).

I have a few non-programming hobbies, mostly standard geeky stuff. I love watching anime and reading manga. I enjoy video games, mostly RPGs. I'm also a [Doctor Who](http://www.bbc.co.uk/doctorwho/dw) fan, but only of the 2005 series. I'm learning the guitar, even though the best I can do right now is practice chords.

In this blog, I write about my programming-related experiences. Most of the articles seem to be about Vim, but in general, I blog about a bunch of different stuff.

Here are a few of my more interesting projects:

- [vimrunner](https://github.com/AndrewRadev/Vimrunner) is a ruby library that lets you spawn a vim instance and control it. This could be useful for integration tests for vim plugins and it's actually being used for CI in [some of my own plugins](http://travis-ci.org/#!/AndrewRadev/splitjoin.vim) and Paul Mucur's [runspec.vim](http://travis-ci.org/#!/mudge/runspec.vim).

- [libmarks](https://github.com/AndrewRadev/libmarks) is sort of a personal Ruby Toolbox. You can save your favorite libraries in there and it will let you organize and search them. In theory. Right now, it's still very much incomplete.

- [daily_sites](http://daily-sites.andrewradev.com) is a small website I use to manage my everyday reading list.

- [ctags_reader](https://github.com/AndrewRadev/ctags_reader) is a little library to read ctags "tags" files and give you an interface to query them in a similar way that a text editor would. It's useful for some super-simple static analysis of code.

- [image-processing](https://github.com/AndrewRadev/image-processing) is an implementation of a bunch of simple image processing algorithms in ruby, using the [chunky_png](https://github.com/wvanbergen/chunky_png) library. It's mostly an exercise, though I'd love to improve them and actually figure out a good use for them.

- [waiting-on-rails](https://github.com/AndrewRadev/waiting-on-rails) runs the `rails` command, while also playing some relaxing elevator music.

- [randfiles](https://github.com/AndrewRadev/randfiles) is a small tool that takes a list of directories and generates a random selection of files, optionally limiting them by size or by count. Inspired by [this tweet](https://twitter.com/#!/climagic/status/161915102436659200).

- [digits](https://github.com/AndrewRadev/digits) is a university project in C that attempts to recognize a digit from a given image. It's very limited, but it was an interesting exercise in image recognition.

And some Vim plugins, if you're into that:

- [splitjoin](https://github.com/AndrewRadev/splitjoin.vim) lets you switch between multiline and single-line versions of the same code.
- [linediff](https://github.com/AndrewRadev/linediff.vim) lets you diff blocks of code instead of files.
- [inline_edit](https://github.com/AndrewRadev/inline_edit.vim) makes it easier to edit code that's embedded in other code, like script tags within HTML.
- [switch](https://github.com/AndrewRadev/switch.vim) changes code in predetermined ways depending on what is currently under the cursor.
- [sideways](https://github.com/AndrewRadev/sideways.vim) moves items in lists (argument lists, arrays) to the left and to the right.
- [whitespaste](https://github.com/AndrewRadev/whitespaste.vim) attempts to adjust blank lines automatically when pasting.
- [multichange](https://github.com/AndrewRadev/multichange.vim) provides an easy way to replace words in a buffer or a particular area. Think variable renaming.
- [writable_search](https://github.com/AndrewRadev/writable_search.vim) lets you grep for something, edit the results directly and have the changes update the original buffers.
- [undoquit](https://github.com/AndrewRadev/undoquit.vim) is like a "Restore Tab" button for Vim, except it also works for splits. A window that was closed with `:quit` can be reopened with a keymap.

If you're a Vim user, you might also like to look around my
[Vimfiles](https://github.com/AndrewRadev/Vimfiles).
