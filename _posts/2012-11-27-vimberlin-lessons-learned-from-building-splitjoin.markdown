---
layout: post
title: "Vimberlin: Lessons Learned from Building Splitjoin"
date: 2012-11-27 21:19
comments: true
categories: vim talks
---

At the November Vimberlin meetup, I talked about my exprience of building a
plugin, what decisions I made and what lessons I took away from it all. My hope
was that the attendees could use my ideas in their own code, and maybe become
motivated to get coding themselves. Here's a short summary of the basic ideas I
presented.

<!-- more -->

## Structure

Vimscript doesn't have a lot of conventions, so it's usually up to the plugin
author to decide on the structure of their project. In the case of splitjoin,
it looks a bit like this:

```
|~autoload/
| |~sj/
| | |-coffee.vim
| | |-css.vim
| | |-...
| `-sj.vim
|~ftplugin/
| |+coffee/
| |+css/
| |+...
|~plugin/
| `-splitjoin.vim
```

The `plugin/splitjoin.vim` file is the only entry point of the plugin, but most
of what it does is defining the necessary commands, mappings and default
setting values. The actual work of splitting or joining code is implemented in
autoloaded functions placed in the `autoload` directory. The files in the
`ftplugin` directory define lists of these functions that are active for
specific filetypes.

The autoloaded functions make up the public interface of the plugin. They're
callable from anywhere, which means that they can be used (at least in theory)
to extend the plugin or re-use some of its functionality. The utility functions
in `autoload/sj.vim` can be particularly useful in some cases and I continue to
rely on them every once in a while in my Vimfiles.

Implementation details can be hidden by using script-local functions (defined
as `s:FunctionName`). In a way, these are "private" functions, except not
private to a module or class, but to a file.

This separation lets users of different skill levels understand different
amounts of what's going on. The `plugin/splitjoin.vim` file contains a fair
amount of boilerplate that can usually be safely ignored if you want to add a
new splitting or joining function for a filetype. And, you can probably even
reuse some function directly by only editing the files in the `ftplugin`
directory. I can't say that's *very* useful for splitjoin in particular, but
I've had pull requests on other plugins that were extremely easy to make simply
because of this separation.

Of course, "separation of concerns is good" is probably not news to most
developers, but Vimscript gets a bad rap of being messy. It certainly has a lot
of deficiencies, compared to most general-purpose languages, but my point is
that it **is** possible to build a well-structured system in Vimscript.

## Using Vim

Imagine you want to split a CSS definition:

``` css
a { color: blue; text-decoration: underline; }
```

How do you do that? Well, you could start by getting the position of the `{`
and `}`, right? Something like this pseudo-vimscript:

``` vim
let [start_line, start_col] = searchpos('{')
let [end_line, end_col]     = searchpos('}')
```

And then what? You could probably fetch the contents of the buffer around these
line numbers and slice it up somehow. This would involve a lot of indexing,
off-by-one ambiguities, and problems with multibyte. Or, you could just do
something like this:

``` vim
normal! ya{
let text = @"
" ... actually process the text
let @" = text
normal! va{p
```

The `normal!` command simply performs a sequence of keys as if they were typed
in by a user. The special `@"` variable holds the contents of the unnamed
register, which is used for pasting. Chances are, if you know these details,
you can pretty much understand what's going on there. There's no explicit
coordinates to juggle around and the code itself is fairly simple.

This was a lesson I learned after I gave up trying to maintain some artificial
level of "purity" for my Vimscript. I used to think that executing a `normal!`
within a function call is a horrible hack, that a function that moves the
cursor or enters visual mode is unacceptable. After gaining some more
experience, I came to the conclusion that artificially excluding some features
in Vim does not make the code better, and has the potential to make it worse.
Of course, that doesn't mean that a text-retrieving function should perform a
rot13 on the entire file or something like that -- you should always try to
avoid side effects as much as possible and maintain some consistent state of
the buffer. But if you have the power of Vim at your disposal, there's little
sense to avoid using its functionality.

## Process, Debugging

Vim doesn't provide you with some kind of a workflow to write plugins. There's
no TDD loop, no browser to refresh. My usual process is:

- I open the code in one window
- I open an example file with Vim in a different window
- I make a change to the plugin code
- I close the second Vim, reopen it and try the functionality again

This might seem annoying, but I find it quite simple, especially if I take care
to set things up for minimal interaction. For instance, if your experiments
involve a test file with some code you want to split on line 3, you could do:

``` bash
vim +3 +SplitjoinSplit
```

And then just rely on history entries to perform your test in a few keystrokes.
With some effort, you could probably even do this automatically, but I haven't
gone in that direction.

As for debugging, the `echo` command is not very useful for more than one
message. The `echomsg` command can be used in its place. The difference is that
all output from `echomsg` is stored in the "messages" list that you can access
by executing the `messages` command.

But the most useful debugging tool for me is an upgrade to `echomsg`, called
`Decho`. It comes from the
[decho.vim](http://www.vim.org/scripts/script.php?script_id=120) plugin,
written by Dr. Chip, and simply opens up a temporary buffer to hold the output
of all `Decho` commands. You can find some other interesting tools in that
plugin, although I never really got into the habit of using them myself.

A few other useful debugging tools are the `PrettyPrint` command, installable
as [prettyprint.vim](http://www.vim.org/scripts/script.php?script_id=2860) and
my `Bufferize` command that you can see in
[this gist](https://gist.github.com/1102968).

## Testing

Splitjoin was the first plugin I attempted to test, for the simple reason that
I was getting fed up with manually checking all different scenarios every time
I made a change to the code. I used my
[vimrunner](https://github.com/AndrewRadev/vimrunner) gem to set up some rspec
tests for the plugin, which did a great job at finding a bunch of bugs I hadn't
noticed and at preventing regressions every once in a while. This is something
I can recommend to ruby programmers, since it should be familiar to them and
the rspec framework is very mature and makes it easy to write helpers, set up
temporary files and so on. Paul Mucur has a
[blog post](http://mudge.name/2012/04/18/testing-vim-plugins-on-travis-ci-with-rspec-and-vimrunner.html)
with a much more detailed explanation of the matter, including how to integrate
the tests with Travis CI, and my
[blog post on implementing Vimrunner](http://andrewradev.com/2011/11/15/driving-vim-with-ruby-and-cucumber/)
might be interesting to understand how it works under the hood.

That said, it does have some disadvantages. It can be fairly slow, and not very
helpful with error reporting. I don't use it as a TDD tool, only as a
regression-preventing one. And, obviously, it's probably not very suited to
non-rubyists. A different tool I can recommend is
[vspec](https://github.com/kana/vim-vspec) by Kana Natsuno. I haven't
used it myself, but Drew Neil reports good results with his recent
[markdown folding plugin](https://github.com/nelstrom/vim-markdown-folding).
It provides a nice BDD-like syntax, while being pure Vimscript.

## In closing

Writing Vimscript is awesome and you should do it. If you've found something in
Vim you don't quite like or want to implement a workflow that's not quite
"normal", you can -- just grab your Vim and start experimenting.
