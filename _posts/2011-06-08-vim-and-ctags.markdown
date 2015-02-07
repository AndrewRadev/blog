---
layout: post
title: "Vim and Ctags"
date: 2011-06-08 19:38
comments: true
categories: vim
---

[Ctags](http://ctags.sourceforge.net/) is an old tool, just like vim, and it
works wonders for code navigation. Since I was recently told that TextMate
doesn't have ctags integration out of the box, I figured I'd make an article
explaining it. Even if you've used it before, I'll describe some of my own
workflow, so you might learn something interesting anyway. I'll start from the
basic usage, and then I'll discuss things like keeping the tags file up to date
and maintaining tags for any libraries you might be using.

<!-- more -->

## What is ctags?

Ctags is a tool that extracts important constructs from the code you're working
on. If you're coding in ruby, it'll find methods, classes and modules. With
vimscript, it pulls out functions, commands and mappings. The extracted data is
dumped in a file called "tags" by default, which has a single item per line --
a "tag". Depending on the command-line flags and the programming language, you
could get a lot of information out of these. For example, with C++ and Java,
ctags can save the inheritance chain for a class. A text editor can then easily
use that for code navigation and completion.

## Installation and simplest use case

Setting up the environment is pretty simple. The actual program is called
"Exuberant ctags", since it's a rewrite of the original one. Googling for it
should provide tons of information for your specific platform, but in short:

  - If you're on a Mac and using a package manager, you could do a `brew
    install ctags` or `port install ctags`.
  - On Linux, I've yet to see a package manager that doesn't provide ctags.
  - On Windows, just download the binary from
    [the homepage](http://ctags.sourceforge.net/) and install away.

Assuming the executable is in your `PATH` (it might not be if you're running
Windows), you can simply go to a directory with some code and run:

``` bash
$ ctags -R .
```

The program will walk through the directory recursively, tagging all source
files it encounters. For large projects this might take a while, but it's
generally pretty fast.

At this point, you can edit a file and type `<C-]>` in normal mode to "follow"
the token under the cursor. Let's take this ruby code for example:

``` ruby
class Foo
  def bar
    "baz"
  end
end

Foo.new.bar
```

If the cursor is on `Foo` at the `Foo.new.bar` line and you type `<C-]>`, vim
will jump on the `class Foo` line. This works across files as well. To get back
to where you followed something, just type `<C-t>` in normal mode. Using these
two mappings, you can navigate your entire project pretty easily. Note that
it's extremely fast, even if you have a large tag file. That's because the tags
are sorted and vim uses a binary search to quickly locate them. It's simple and
highly effective.

## Multiple matches

If you have multiple definitions for a tag, the default `<C-]>` behavior is to
drop you off at the first one it finds. By default, vim gives more priority to
tags in the current file, which is often what you want. While doing that,
you'll also be shown a message:

```
tag 1 of x or more
```

There are various ways to jump through the rest of the matches:

  - `:tnext` and `:tprev` will send you to the next and previous tag in the
    list, respectively.
  - `:tselect` will display the tag list and let you choose one with a number.
  - `:ltag` will load the tags into the location list window. You can then view
    that window by executing `:lopen`.

For an easier time, you could always create some shortcuts. For example, you
could follow the convention of the
[unimpaired.vim](http://www.vim.org/scripts/script.php?script_id=1590)
plugin and map `]t` for `:tnext` and `[t` for `:tprev.`

## Dynamic tags and autotag

I'm going to call the tags generated for your code "dynamic", since you're
probably constantly making changes there. So, what happens when the tags are no
longer correct? While you could regularly invoke ctags on the working
directory, that's going to get annoying pretty fast. Thankfully, the tool has
an `-a` flag that makes it append to a tag file instead of overwriting it. That
way, you can update the tags very quickly every time a file changes. With vim's
autocommands, this could work like this:

``` vim
autocmd BufWritePost *
      \ if filereadable('tags') |
      \   call system('ctags -a '.expand('%')) |
      \ endif
```

Unfortunately, there's an issue with this approach. Ctags will only add new
tags, it won't remove ones that are no longer present. If you delete a
function, it will still appear in the tag file.

That's where the
[autotag.vim](http://www.vim.org/scripts/script.php?script_id=1343)
plugin comes in. Whenever you save a file, it deletes all of its entries and
invokes ctags in append mode. I've been using it for a long time and I haven't
noticed any overhead at all, even on Windows boxes. Unfortunately, your vim
build needs to have python support to use it. Even if it doesn't, though, no
errors are raised, which is nice if you use the same vimfiles across different
vim builds like I do.

## Static tags

Another way you could use ctags is to index libraries that your project uses,
assuming you have their source locally. For example, until recently, I would
checkout the rails source code at `~/src/rails`, run ctags on it and save the
resulting file as `~/tags/rails.tags`. I use the nifty
[Proj plugin](http://www.vim.org/scripts/script.php?script_id=2719)
to
source project-specific vimfiles, so I just have to add it to the
['tags'](http://vimdoc.sourceforge.net/htmldoc/options.html#%27tags%27)
option:

``` vim
set tags+=~/tags/rails.tags
```

This allows me to easily jump to a definition of a method within the framework
itself. Since rails is pretty well commented, I don't have to google for method
signatures, at least.

A better approach I eventually discovered was generating tags for _all gems_ I
was using. Of course, I can't build an index of every single gem on my system.
There are different versions installed side-by-side and I'd get a whole lot of
duplication (if nothing else). But since bundler made its way into ruby, the
Gemfile always contains a nice snapshot of all gems your particular application
is using. Thankfully, we don't have to parse the actual file for that.
[This little ruby snippet](https://gist.github.com/893236)
taps into bundler's API to retrieve the gem locations and builds the tag file:

``` ruby
require 'bundler'

paths = Bundler.load.specs.map(&:full_gem_path)

system("ctags -R -f gems.tags #{paths.join(' ')}")
```

Even if this script is specific to ruby, the general approach could be used for
any kind of project. Just maintain a list of all libraries your application is
using, find them locally and run ctags on that.

## Code completion

Vim has quite a few completion types to deal with different situations, but
[omnicompletion](http://vimdoc.sourceforge.net/htmldoc/insert.html#compl-omni),
which is meant to intelligently decide what to do, is just not very good for some languages. That's why, whenever I want to complete a method call or class name that I know is defined somewhere, I just use
[tag completion](http://vimdoc.sourceforge.net/htmldoc/insert.html#compl-tag):

``` vim
inoremap <c-x><c-]> <c-]>
```

If you'd like to have it appear automatically as you type, you could try the
[Acp plugin](http://www.vim.org/scripts/script.php?script_id=1879).
It's fast and pretty customizable -- you can define the type of completion
you'd like to use per filetype and depending on some specific condition.

## Accessing tag data in vimscript

If you'd like to use the tags for your own custom needs, vim provides a
straightforward way to do that through the
[taglist](http://vimdoc.sourceforge.net/htmldoc/eval.html#taglist\(\))
function. It's called with a regular expression and it will return all the data
from the matching tags in the form of a list of dictionaries. An example of
what you could do with it is the following command, which finds function
definitions:

``` vim
command! -nargs=1 Function call s:Function(<f-args>)
function! s:Function(name)
  " Retrieve tags of the 'f' kind
  let tags = taglist('^'.a:name)
  let tags = filter(tags, 'v:val["kind"] == "f"')

  " Prepare them for inserting in the quickfix window
  let qf_taglist = []
  for entry in tags
    call add(qf_taglist, {
          \ 'pattern':  entry['cmd'],
          \ 'filename': entry['filename'],
          \ })
  endfor

  " Place the tags in the quickfix window, if possible
  if len(qf_taglist) > 0
    call setqflist(qf_taglist)
    copen
  else
    echo "No tags found for ".a:name
  endif
endfunction
```

Invoking `:Function foo` will look for functions in the tag file that start
with "foo" and load them all in the
[quickfix](http://vimdoc.sourceforge.net/htmldoc/quickfix.html#quickfix)
window. This could be even more useful with some tab-completion and it's also
not very portable across filetypes. It shouldn't be too difficult to generalize
it a bit, so I might devote a separate blog post for that when I get around to
doing it.

## Summary

  - You can use ctags to index the code you're working on. The autotag plugin
    can keep the tag file up to date, but you need a vim with python support
    for that.
  - Generating tags for any libraries you're using is even easier, since they
    won't be changing any time soon. A potential problem is figuring out a way
    to add the extra tag files just where you need them.
  - Tag completion can often be good enough when you can't remember an exact
    name for a function or class.
  - Accessing the tag data for your own hardcore customization needs is done
    through the `taglist` function.
