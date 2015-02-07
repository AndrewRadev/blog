---
layout: post
title: "Vim and Ctags: Finding Tag Definitions"
date: 2011-10-15 00:14
comments: true
categories: vim
published: true
---

A while back, I posted
[an article](http://andrewradev.com/2011/06/08/vim-and-ctags/)
on setting up Vim with ctags. In this post, I'll go through the code of a small
vim plugin I've recently published,
[tagfinder.vim](http://www.vim.org/scripts/script.php?script_id=3771),
which is a generalization of the last example from that article. Basically, it
lets you define custom commands to look for tags by their name, filtering them
by a specific type -- class, method, module, and so on. This doesn't add a
whole lot of value over the built-in `:tag` command, but I find it's still
pretty useful. The idea was originally taken from Tom Link's
[tlib](http://www.vim.org/scripts/script.php?script_id=1863) library.

My goal is to show an example of moving from an idea of useful functionality to
working vimscript. I *am* cheating quite a lot, since it's something I've had
in my vimfiles for a while now. I've only isolated it into a plugin, removing
the dependencies and adding hooks for custom commands. This means that I have a
good idea of what I want to do, so I'll skip lots of steps in the process of
describing it. Still, I think it might be useful to see the components of a
simple vim plugin and how they work together. I'll make a summary after the
post with what I consider some of the more important lessons.

<!-- more -->

## Problem definition

First of all, what's the problem I'm trying to solve?

I'd like to be able to look up classes and methods by their names. Since I
don't want to have to type in the whole name, some completion is necessary. The
plugin also needs to be customizable, because ctags uses different kind names
for different languages. For instance, a method is denoted by `f` in ruby, but
by `m` in java, so a `:FindMethod` command wouldn't work the same way in both
languages.

## Basic framework

Where to start? I could try doing things top-down -- start with an interface
using commands -- but for something like this, I'd prefer to work bottom-up, at
least in the beginning. The plugin is simple enough in theory, but vimscript
can be a complicated beast. It'd be nice to have the functions doing the hard
work nailed down, so I'm confident enough to deal with the user interface.

So, to start off, let's write a few functions that retrieve tags, filtered the
way I like. The first one will be used when I have a full tag.

``` vim plugin/taglist.vim
function! FindTags(name, kinds)
  let tag_list = []

  for entry in taglist(a:name)
    if index(a:kinds, entry.kind) > -1
      call add(tag_list, entry)
    endif
  endfor

  return tag_list
endfunction
```

Basically, I retrieve the tag data using `taglist()` and then iterate through
the returned list. Each entry is a dict with several fields. For now, the
`kind` one will be enough. The check is performed by looking for `entry.kind`
within the given list of kinds to look for. If one is found, the result will be
a non-negative number, in which case the entry is kept for later.

From the found tags, I can retrieve the filename and pattern to locate the tag
definitions. I could send the user to one of these directly, or use some kind
of a menu to have them choose one. I'll deal with that later on.

For now, I'll write another function to use for the completion process. For
this one, I need to look for any tags starting with a certain string. Also,
there's no point in keeping all the data from the found tags, a name would be
enough for the purposes of completion.

``` vim plugin/taglist.vim
function! FindTagNamesByPrefix(prefix, kinds)
  let tag_set = {}

  for entry in taglist('^'.a:prefix)
    if index(a:kinds, entry.kind) > -1
      let tag_set[entry.name] = 1
    endif
  endfor

  return keys(tag_set)
endfunction
```

The invocation would be something like `FindTagNamesByPrefix('ActiveR', ['c', 'class'])`.
The result, a list of all classes that start with "ActiveR" within the tag
file.

This time, I'm not using a list to store the tags. I need to remove any
duplicates, because there could easily be a dozen definitions of the same
function within the project. Interestingly enough, vim doesn't seem to have a
built-in function to filter a list by uniqueness, so I use a dict instead.

The function iterates through the results of `taglist()`, just like before.
Notice that I'm using `^` to anchor the match to the beginning of the tag.
Next, the tags are filtered by the given kinds, nothing new here. Instead of
using `add()` to stick the tag in a list, I just save it as the key of a dict.
When it's all done, the function simply returns all of the dict's keys and I
get a unique list of tag names, starting with the given prefix.

This is a good start. You can experiment with these functions to check that
they work more or less correctly. For example, you could tag the rails source
and play with that. Retrieving the tags for "ActiveRecord", for instance, will
vary depending on whether you look for a class with `['c']` or module with
`['m']`. A nice plugin you could use to view the returned structures in the
command line is
[prettyprint.vim](http://www.vim.org/scripts/script.php?script_id=2860).

Now, let's build on these functions to actually implement the interface.

## Straightforward solution

Let's start with writing a command that opens up the quickfix window with all
found tags. To simplify things, I'll look only for classes first, and see how I
can generalize things later.

``` vim plugin/taglist.vim
command! -nargs=1 FindClass call s:FindClass(<f-args>)
function! s:FindClass(name)
  let qflist = []
  for entry in FindTags(a:name, ['c', 'class'])
    let filename = entry.filename
    let pattern  = substitute(entry.cmd, '^/\(.*\)/$', '\1', '')

    call add(qflist, {
          \ 'filename': filename,
          \ 'pattern':  pattern,
          \ })
  endfor

  call setqflist(qflist)
  copen
endfunction
```

There are a few interesting things going on here. Let's go through them
step-by-step:

  - Since I want to put a fair amount of logic into the command, I use a
    script-local function, `s:FindClass()` to do the heavy lifting. I could
    make this a global function or put it in autoload, but at the moment, this
    is going to be too specific to be useful elsewhere, so better keep it close
    to the command as its implementation. I limit the argument count to one,
    because I'll be looking for only one tag at a time.
  - The `qflist` variable holds a list I'm filling with entries for the
    quickfix window. The tag entries are structured a bit differently, so
    there's a need to do some conversion. Once all of the entries are converted
    into the `qflist` array, `setqflist(qflist)` loads them up in the quickfix
    window. All that's left is executing `copen` to actually open it.
  - The conversion of the pattern is required, because the tag entry contains a
    `cmd` field that might look like `/^    class ActiveRecord::Base$/`. The
    first and last `/` symbols need to be removed for the quickfix entry to do
    the right thing. A simple regular expression does the trick.

Let's handle some edge cases now by adding some checks to the final lines of
the function.

``` vim plugin/taglist.vim
function! s:FindClass(name)
  " ...

  if len(qflist) == 0
    echohl Error | echo "No tags found" | echohl NONE
  elseif len(qflist) == 1
    call setqflist(qflist)
    silent cfirst
  else
    call setqflist(qflist)
    copen
  endif
endfunction
```

Now, if no tags have been found, an error message is displayed. If only one tag
is present, there's no need to open the quickfix window, so the user is sent to
the first (and only) entry. Otherwise, the window is opened and the user can
choose the tag to jump to.

Now that I have a `:FindClass` command, I can build a `:FindFunction` one to
look for functions. It seems like the only difference between them is in the
parameter given to `FindTags`. Let's just rewrite the `s:FindClass` function to
take an additional argument and rename it to something more generic.

``` vim plugin/taglist.vim
command! -nargs=1 FindClass    call s:JumpToTag(<f-args>, ['c', 'class'])
command! -nargs=1 FindFunction call s:JumpToTag(<f-args>, ['f', 'method', 'F', 'singleton method'])
function! s:JumpToTag(name, kinds)
  " ...

  for entry in FindTags(a:name, a:kinds)
    " ...
  endfor

  " ...
endfunction
```

These changes should be enough. I can now add all kinds of commands to look for
specific language constructs, but there's an annoying problem -- different
languages use different kind names. In that case, I can buffer-localize the
commands and make the `s:JumpToTag()` function global, so it's accessible in
the filetype plugins.

``` vim ftplugin/ruby.vim
command! -buffer -nargs=1 FindClass    call JumpToTag(<f-args>, ['c', 'class'])
command! -buffer -nargs=1 FindFunction call JumpToTag(<f-args>, ['f', 'method', 'F', 'singleton method'])
```

``` vim ftplugin/vim.vim
command! -buffer -nargs=1 FindCommand  call JumpToTag(<f-args>, ['c', 'command'])
command! -buffer -nargs=1 FindFunction call JumpToTag(<f-args>, ['f', 'function'])
```

Simple enough. One drawback is that there's no longer any access to these
commands unless a buffer is opened. A simple solution is to define global
commands with the same names and let the buffer-local ones override them for
specific filetypes. We'll see how that can be implemented a bit later on, after
I create a better interface for defining them.

## Completion

A big issue is the lack of command-line completion. Thankfully, this is easy
enough to implement (for now).

``` vim plugin/tagfinder.vim
command! -buffer -nargs=1 -complete=customlist,s:CompleteFindClass FindClass call JumpToTag(<f-args>, ['c', 'class'])
function! s:CompleteFindClass(lead, command_line, cursor_pos)
  if len(a:lead) > 0
    let tag_prefix = a:lead
  else
    let tag_prefix = '.'
  endif

  return sort(FindTagNamesByPrefix(tag_prefix, kinds))
endfunction
```

The `-complete=customlist,s:CompleteFindClass` part is new. It attaches the
`s:CompleteFindClass` function to the `FindClass` command. Vim invokes it when
`<tab>` is pressed while typing and provides the three parameters:

  - `a:lead` holds the current word that's being completed
  - `a:command_line` is the entire command line
  - `a:cursor_pos` is the position of the cursor in the command line, in bytes

If the `a:lead` argument is not empty, then the user has started typing
something and I can use that as a prefix. If not, I just start a search for all
tags. Generally, that would be *very* inefficient, but might be okay for a
small codebase. We can always stop it with a `Ctrl+C`, so it shouldn't be a
problem.

Note the `-buffer` part of the command, by the way. If we want to use this as
completion for a global command, that one needs to be removed.

## A sensible user interface

Unfortunately, the above code is a bit too much to copy for every single tag
finder a user would want to write. Most of the code can be extracted in a
helper, but the completion function needs to have these specific arguments in
order to fit with vim's interface. To work around this, I'll just use the first
argument, `a:lead`, to determine what kind of completion to perform.

It has to be said that the above code would actually be enough for most cases.
From this point on, things might get a bit more difficult to follow, involving
commands that define other commands. You have been warned.

For starters, let's define a simpler user interface, disregarding completion
for the moment. This time, I'll start from the end result. My goal is being
able to do this:

``` vim
DefineLocalTagFinder FindFunction f,method,F,singleton\ method
```

This invocation should be enough to define a `:FindFunction` command for the
current buffer. I've placed a "Local" in the name to make its scope obvious and
because I'll be writing a global version of it later. Its definition would be
pretty much the same as the above buffer-local commands, except it needs to be
made generic.

``` vim
command! -nargs=+ DefineLocalTagFinder call s:DefineLocalTagFinder(<f-args>)
function s:DefineLocalTagFinder(name, kinds)
  exe 'command! -buffer -nargs=1 '.a:name.' call JumpToTag(<f-args>, "'.a:kinds.'")'
endfunction
```

The new command needs two arguments -- a command name and a specification of
the kinds of tags it will be looking for. While we can't constrain the command
to exactly two parameters, `-nargs=+` is good enough. As for the kinds, we
don't need to use a comma (or any special delimiter) to separate them, but it
makes things a bit simpler in this case.

The `exe` might look a bit odd if you're not used to writing vimscript, but on
close inspection, there's nothing difficult about it. The string is executed as
a regular vim command would, with `a:name` and `a:kinds` replaced with their
actual values. It's very similar to the `send` method in ruby. If we invoke the
command with `DefineLocalTagFinder FindFunction f,function`, the string would
expand to:

``` vim
command! -buffer -nargs=1 FindFunction call JumpToTag(<f-args>, "f,function")
```

As you may have noticed, this doesn't quite fit with our previous definition of
`JumpToTag`. We'll just rewrite it, like so:

``` vim
function! JumpToTag(name, kinds)
  let kinds = split(a:kinds, ',')
  " ...
endfunction
```

Why the change? Well, serializing an array by hand is a bit difficult to read.
Since `JumpToTag` is my own helper function, better adapt it a bit to fit my
needs and have it use a comma-separated string instead of an array.

The last part of the puzzle is, again, completion. I'll make it dynamic by
tracking all tag-finding commands defined in the buffer and determining the
completion depending on the `a:command_line` argument.

``` vim plugin/tagfinder.vim
command! -nargs=+ DefineLocalTagFinder call s:DefineLocalTagFinder(<f-args>)
function s:DefineLocalTagFinder(name, kinds)
  if !exists('b:tagfinder_commands')
    let b:tagfinder_commands = {}
  endif

  let b:tagfinder_commands[a:name] = split(kinds, ',')

  exe 'command! -buffer -nargs=1 -complete=customlist,CompleteTagFinder '.a:name.' call JumpToTag(<f-args>, "'.a:kinds.'")'
endfunction

function! CompleteTagFinder(lead, command_line, cursor_pos)
  let command_name = s:ExtractCommandName(a:command_line)
  let kinds        = b:tagfinder_commands[command_name]

  if len(a:lead) > 0
    let tag_prefix = a:lead
  else
    let tag_prefix = '.'
  endif

  return sort(FindTagNamesByPrefix(tag_prefix, kinds))
endfunction

function! s:ExtractCommandName(command_line)
  let command_line = substitute(a:command_line, '^.*|', '', '')
  let parts        = split(command_line, '\s\+')
  return parts[0]
endfunction
```

Now, every time a tag-finding command is defined, its name is saved in a
buffer-local variable, along with the tag kinds it's linked to. Whenever
completion is needed for one of these commands, its name is retrieved from the
entire command line.

Getting the command name from the entire line is a bit annoying. It'd be simple
to just split it by whitespace and grab the first part, but there might be
something in front of it, ending in "|", like:

``` vim
echo | split | Function save_page_
```

That's why the `s:ExtractCommandName` starts by removing anything up to the
last "|" character, and then proceeds to extract the first part as the command
name.

## Cleanup

There are a few more things that need to be done to make this a proper plugin.
For starters, the global functions need to be autoloaded to avoid polluting the
global namespace.

``` vim autoload/tagfinder.vim
function! tagfinder#CompleteTagFinder(lead, command_line, cursor_pos)
  " ...
endfunction

function! tagfinder#FindTagNamesByPrefix(prefix, kinds)
  " ...
endfunction

function! tagfinder#FindTags(name, kinds)
  " ...
endfunction

function! tagfinder#JumpToTag(name, kinds)
  " ...
endfunction
```

A global `DefineTagFinder` command would be nice to set up some default
commands. If you code almost exclusively in ruby, you could do that with the
above `FindFunction` and `FindClass` to avoid being unable to search when
you're in a buffer with a different filetype.

``` vim plugin/tagfinder.vim
if !exists('b:tagfinder_commands')
  let g:tagfinder_commands = {}
endif

command! -nargs=+ DefineTagFinder call s:DefineTagFinder(<f-args>)
function s:DefineTagFinder(name, kinds)
  let g:tagfinder_commands[a:name] = split(a:kinds, ',')

  exe 'command! -nargs=1 -complete=customlist,tagfinder#CompleteTagFinder '.a:name.' call JumpToTag(<f-args>, "'.a:kinds.'")'
endfunction
```

``` vim autoload/tagfinder.vim
function! tagfinder#CompleteTagFinder(lead, command_line, cursor_pos)
  if !exists('b:tagfinder_commands')
    let b:tagfinder_commands = {}
  endif

  let command_name       = s:ExtractCommandName(a:command_line)
  let tagfinder_commands = extend(g:tagfinder_commands, b:tagfinder_commands)
  let kinds              = tagfinder_commands[command_name]

  " ...
endfunction
```

I've added a `g:tagfinder_commands` variable and I use that to store the global
command names. The completion function merges the global and the buffer-local
variables and queries the result to figure out the kinds to look for.

And, of course, there's the important matter of writing documentation, but this
is one process I won't be describing here.

The full source code of the plugin is on
[github](https://github.com/AndrewRadev/tagfinder.vim).

## Summary

  - Vimscript is a bit difficult to get into. At its core lies a very simple
    language, but with lots of extensions for various edge cases that may
    confuse newcomers. Once you get the hang of it, though, it's not that big
    of a deal (excluding the occasional hiccup).
  - Tags are a powerful resource. Vim allows you to retrieve tags very quickly
    and filter them on anything you want. Depending on the command-line flags
    and the language, you might get a lot more information that I've needed in
    this example, like the containing class, inheritance chain, type (for
    variables).
  - The quickfix list is easy to manipulate and provides a nice interface for a
    lot of needs. It can be used for navigating compilation errors,
    [investigating backtraces](https://github.com/AndrewRadev/Vimfiles/blob/1c2eea9bdb3c9d8c05624ff7dcd08c463152fdd4/startup/commands.vim#L148-L171),
    and, in this case, jumping around tag definitions.
  - Commands can define other commands. And, they can do it dynamically if they
    have to, by using `exe`. This may look ugly if overused, but it's a pretty
    powerful tool.
  - Adding completion to vim commands can help a lot in the long run. Whenever
    you write a command to help you out with something, consider if it would
    benefit from a completion function.
