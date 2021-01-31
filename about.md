---
layout: page
title: About me
permalink: /about/
---

<img class="about-image" src="/images/avatar_castle.png" alt="Hello, there" />

Hi, my name's Andrew and I'm a programmer. You can find me as "AndrewRadev" on [github](http://github.com/AndrewRadev) and on [twitter](http://twitter.com/AndrewRadev).

Professionally, I code mostly in Ruby and Rails. In my spare time (and very non-professionally), I try to play around with all sorts of other stuff: [Image processing](https://github.com/AndrewRadev/image-processing), gamedev with Unity, [opengl and webgl](https://github.com/AndrewRadev/green-cubes), [Android](https://github.com/AndrewRadev/android_notes), [electronics](http://andrewradev.com/2012/01/08/first-steps-with-arduino/), and any fun programming-related thing that crosses my path.

<div style="clear: both; margin-top: 50px;"></div>

## Rust

Recently, I've been building most of my side-projects in Rust. I've grown fond enough of the language to start teaching it [at Sofia University](https://fmi.rust-lang.bg/). I've got a bunch of half-baked experiments, but a few usable ones as well:

- [id3-image](https://github.com/AndrewRadev/id3-image) allows easy manipulation of images embedded in mp3s. Think cover art and thumbnails.
- [cargo-local](https://github.com/AndrewRadev/cargo-local) lets you find the local source code of packages, useful for exploring them with an editor or generating tags.
- [quickmd](https://github.com/AndrewRadev/quickmd) is a fast, self-contained markdown previewer.

## Ruby

I don't have that many published Ruby gems, compared to how long I've been working on the language. I guess working professionally in it means I tend to focus my spare time on other things, for the sake of variety. Here's a few of my projects, though:

- [vimrunner](https://github.com/AndrewRadev/Vimrunner) is a ruby library that lets you spawn a Vim instance and control it. This could be useful for integration tests for Vim plugins and it's actually being used for CI in [some of my own plugins](http://travis-ci.org/#!/AndrewRadev/splitjoin.vim) and a few others (like [runspec.vim](http://travis-ci.org/#!/mudge/runspec.vim), [vim-elixir](https://github.com/elixir-editors/vim-elixir), [vim-ruby](https://github.com/vim-ruby/vim-ruby)).
- [progressor](https://github.com/AndrewRadev/progressor) is a ruby gem that lets you measure loops of a long-running task and show some estimation of the remaining time. Useful for long data migrations, for instance.
- [ctags_reader](https://github.com/AndrewRadev/ctags_reader) is a little library to read ctags "tags" files and give you an interface to query them in a similar way that a text editor would. It's useful for some super-simple static analysis of code. I've used it to generate documentation links in non-API docs.
- [waiting-on-rails](https://github.com/AndrewRadev/waiting-on-rails) runs the `rails` command, while also playing some relaxing elevator music until the server boots. Convenient for that legacy monolith you need to start up every morning.
- [image-processing](https://github.com/AndrewRadev/image-processing) is an implementation of a bunch of simple image processing algorithms in ruby, using the [chunky_png](https://github.com/wvanbergen/chunky_png) library. It's mostly an exercise, though I'd love to improve them and actually figure out a good use for them. And possibly rewrite them in, say, Rust.
- [daily_sites](http://daily-sites.andrewradev.com) is a small website I use to manage my everyday reading list.

## Vim

I'm a dedicated Vim user and I've created [quite a few Vim plugins](http://www.vim.org/account/profile.php?user_id=31799). I maintain the [VimLinks](https://twitter.com/vimlinks) twitter account, I'm one of the maintainers of the [official ruby bindings for Vim](https://github.com/vim-ruby/vim-ruby) (but I'm pretty bad at keeping up with the work there), and I own the runtime files for Vim's [eco support](https://github.com/AndrewRadev/vim-eco) (though they haven't needed refreshing in a long, long while).

A few of the more interesting ones:

- [splitjoin](https://github.com/AndrewRadev/splitjoin.vim) lets you switch between multiline and single-line versions of the same code.
- [linediff](https://github.com/AndrewRadev/linediff.vim) lets you diff blocks of code instead of files.
- [tagalong](https://github.com/AndrewRadev/tagalong.vim) automatically changes a closing HTML tags when you edit the opening one.
- [inline_edit](https://github.com/AndrewRadev/inline_edit.vim) makes it easier to edit code that's embedded in other code, like script tags within HTML.
- [switch](https://github.com/AndrewRadev/switch.vim) changes code in predetermined ways depending on what is currently under the cursor.
- [sideways](https://github.com/AndrewRadev/sideways.vim) moves items in lists (argument lists, arrays) to the left and to the right. It also provides a text object for "item in argument list", which is arguably the more useful part of the plugin.
- [whitespaste](https://github.com/AndrewRadev/whitespaste.vim) attempts to adjust blank lines automatically when pasting.
- [multichange](https://github.com/AndrewRadev/multichange.vim) provides an easy way to replace words in a buffer or a particular area. Think variable renaming.
- [writable_search](https://github.com/AndrewRadev/writable_search.vim) lets you grep for something, edit the results directly and have the changes update the original buffers.
- [undoquit](https://github.com/AndrewRadev/undoquit.vim) is like a "Restore Tab" button for Vim, except it also works for splits. A window that was closed with `:quit` can be reopened with a keymap.
- [ember_tools](https://github.com/AndrewRadev/ember_tools.vim) provides some useful tools to work with an ember.js project.
- [gnugo](https://github.com/AndrewRadev/gnugo.vim) is a UI around a [GnuGo](https://www.gnu.org/software/gnugo/) process -- it lets you play Go right in your Vim.
- [id3](https://github.com/AndrewRadev/id3.vim) lets you "edit" mp3 files by editing their ID3 tags. It also handles flac files, so I might just rename it to something more appropriate one of these days.
- [discotheque](https://github.com/AndrewRadev/discotheque.vim) is a bit of a joke, but it can be a fun party trick.

If you're a Vim user, you might also like to look around my [Vimfiles](https://github.com/AndrewRadev/Vimfiles). The README might point you in the right directions to explore.

## Videos

I've got a playlist of Vim-related screencasts, mostly of my own plugins or setup:

<iframe width="560" height="315" src="https://www.youtube.com/embed/videoseries?list=PL_pobXkumxw6uu-IVW2j5LfCmjNzoIjip" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>

Occasionally, I speak at conferences, and I've put most of the videos in one youtube playlist. Most of them happen to be in Bulgarian, but if it has an English title, it should be in English:

<iframe width="560" height="315" src="https://www.youtube.com/embed/videoseries?list=PL_pobXkumxw7yYW0_bmPY-uk0XkwoRgtK" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
