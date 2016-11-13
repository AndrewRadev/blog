---
layout: page
title: About me
permalink: /about/
---

<img class="about-image" src="http://gravatar.com/avatar/fc59401781a26b10f5d4fc5b758fb3b7.png?s=192" alt="Hello, there" />

Hi, my name's Andrew and I'm a programmer. You can find me as "AndrewRadev" on [github](http://github.com/AndrewRadev) and on [twitter](http://twitter.com/AndrewRadev).

Professionally, I code mostly in [Ruby](http://ruby-lang.org), [Rails](http://rubyonrails.org/), and a bit of [Ember.js](http://emberjs.com/). In my spare time (and very non-professionally), I try to play around with all sorts of other stuff: [Image processing](https://github.com/AndrewRadev/image-processing), gamedev with Unity, [opengl and webgl](https://github.com/AndrewRadev/green-cubes), [Android](https://github.com/AndrewRadev/android_notes), [electronics](http://andrewradev.com/2012/01/08/first-steps-with-arduino/), and any fun programming-related thing that crosses my path.

I'm a dedicated [Vim](http://vim.org) user and I've created a [bunch of Vim plugins](http://www.vim.org/account/profile.php?user_id=31799). I maintain the [VimLinks](https://twitter.com/vimlinks) twitter account, I'm one of the maintainers of the [official ruby bindings for vim](https://github.com/vim-ruby/vim-ruby) (but I'm pretty bad at keeping up with the work there), and I own the runtime files for Vim's [eco support](https://github.com/AndrewRadev/vim-eco).

Occasionally, I speak at conferences, and I've put most of the videos in one [youtube playlist](https://www.youtube.com/playlist?list=PL_pobXkumxw7yYW0_bmPY-uk0XkwoRgtK). Most of them are in Bulgarian, but I've noted the language of each one in the playlist. I've also got a [playlist of Vim-related screencasts](https://www.youtube.com/playlist?list=PL_pobXkumxw6uu-IVW2j5LfCmjNzoIjip), though it's annoyingly short. I should get back to that, one of these days.

In this blog, I write about my programming-related experiences. Most of the articles seem to be about Vim, but I do write about other stuff as well, I promise.

Here are a few of my projects that I find interesting:

- [vimrunner](https://github.com/AndrewRadev/Vimrunner) is a ruby library that lets you spawn a vim instance and control it. This could be useful for integration tests for vim plugins and it's actually being used for CI in [some of my own plugins](http://travis-ci.org/#!/AndrewRadev/splitjoin.vim) and Paul Mucur's [runspec.vim](http://travis-ci.org/#!/mudge/runspec.vim).
- [daily_sites](http://daily-sites.andrewradev.com) is a small website I use to manage my everyday reading list.
- [ctags_reader](https://github.com/AndrewRadev/ctags_reader) is a little library to read ctags "tags" files and give you an interface to query them in a similar way that a text editor would. It's useful for some super-simple static analysis of code. I've used it to generate documentation links in non-API docs.
- [image-processing](https://github.com/AndrewRadev/image-processing) is an implementation of a bunch of simple image processing algorithms in ruby, using the [chunky_png](https://github.com/wvanbergen/chunky_png) library. It's mostly an exercise, though I'd love to improve them and actually figure out a good use for them. And possibly rewrite them in, say, Rust.
- [waiting-on-rails](https://github.com/AndrewRadev/waiting-on-rails) runs the `rails` command, while also playing some relaxing elevator music until the server boots. Convenient for that legacy monolith you need to start up every morning.
- [digits](https://github.com/AndrewRadev/digits) is a university project in C that attempts to recognize a digit from a given image. It's very limited, but it was an interesting exercise in image recognition.
- [green-cubes](https://github.com/AndrewRadev/green-cubes) is just a tiny webgl experiment for my talk at [BurgasConf 2014](https://github.com/AndrewRadev/BurgasConf-2014).

And some Vim plugins, if you're into that:

- [splitjoin](https://github.com/AndrewRadev/splitjoin.vim) lets you switch between multiline and single-line versions of the same code.
- [linediff](https://github.com/AndrewRadev/linediff.vim) lets you diff blocks of code instead of files.
- [inline_edit](https://github.com/AndrewRadev/inline_edit.vim) makes it easier to edit code that's embedded in other code, like script tags within HTML.
- [switch](https://github.com/AndrewRadev/switch.vim) changes code in predetermined ways depending on what is currently under the cursor.
- [sideways](https://github.com/AndrewRadev/sideways.vim) moves items in lists (argument lists, arrays) to the left and to the right. It also provides a text object for "item in argument list", which is arguably the more useful part of the plugin.
- [whitespaste](https://github.com/AndrewRadev/whitespaste.vim) attempts to adjust blank lines automatically when pasting.
- [multichange](https://github.com/AndrewRadev/multichange.vim) provides an easy way to replace words in a buffer or a particular area. Think variable renaming.
- [writable_search](https://github.com/AndrewRadev/writable_search.vim) lets you grep for something, edit the results directly and have the changes update the original buffers.
- [undoquit](https://github.com/AndrewRadev/undoquit.vim) is like a "Restore Tab" button for Vim, except it also works for splits. A window that was closed with `:quit` can be reopened with a keymap.
- [ember_tools](https://github.com/AndrewRadev/ember_tools.vim) provides some useful tools to work with an ember.js project.
- [gnugo](https://github.com/AndrewRadev/gnugo.vim) is a UI around a [GnuGo](https://www.gnu.org/software/gnugo/) process -- it lets you play Go right in your Vim.

If you're a Vim user, you might also like to look around my [Vimfiles](https://github.com/AndrewRadev/Vimfiles).
