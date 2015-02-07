---
layout: post
title: "Manipulating Coffeescript With Vim, Part 1: Text Objects"
date: 2012-04-03 22:40
comments: true
categories: vim coffeescript
---

I recently started to write *a lot* of coffeescript at work, so I bumped into
an issue that I've been avoiding for some time: manipulating indent-based
languages. Theoretically, it should be easier (no "ends" or closing braces,
right?), but I have a lot of tools to move code around, wrap it in blocks, or
view it nicely, that just don't work with semantic indentation. So, I had to
experiment to come up with some vimscript to make it more comfortable. It's all
a [work in progress](https://github.com/AndrewRadev/coffee_tools.vim), but it's
been rather useful for me so far.

Originally, I intended to write a single post, but I started off rather
verbosely, so I decided to make it a series instead and explain the code in
more detail along the way. To begin with, I'll describe the process of writing
two simple text objects that might be useful in day-to-day coffeescript
development.

If you're unfamiliar with text objects in Vim, you could get a good explanation
from the help files with [:help text-objects](http://vimdoc.sourceforge.net/htmldoc/motion.html#object-select).
Another nice introduction is [Chapter 15](http://learnvimscriptthehardway.stevelosh.com/chapters/15.html)
from "Learn Vimscript the Hard Way" by Steve Losh. It's rather short, so I
recommend you skip through it in any case.

<!-- more -->

## Basic Tools

First, we'll define two functions that don't make much sense on their own, but
will be useful a bit later. The first one does the following:

  - Takes the indent of the current line as a "base".
  - Iterates through the buffer, line by line.
  - Returns the last line with a level of indent the same or larger than the base.

``` vim
function! s:LowerIndentLimit(lineno)
  let base_indent  = indent(a:lineno)
  let current_line = a:lineno
  let next_line    = nextnonblank(current_line + 1)

  while current_line < line('$') && indent(next_line) >= base_indent
    let current_line = next_line
    let next_line    = nextnonblank(current_line + 1)
  endwhile

  return current_line
endfunction
```

The second one does the same thing, except upwards in the buffer:

``` vim
function! s:UpperIndentLimit(lineno)
  let base_indent  = indent(a:lineno)
  let current_line = a:lineno
  let prev_line    = prevnonblank(current_line - 1)

  while current_line > 0 && indent(prev_line) >= base_indent
    let current_line = prev_line
    let prev_line    = prevnonblank(current_line - 1)
  endwhile

  return current_line
endfunction
```

We could have combined these in a single one, but it wouldn't really make much
of a difference code-wise. The repetition between them is, regrettably,
difficult to avoid, but given their small size, I wouldn't worry too much about
it.

## Indent Text Object

A popular method of working with indent-based languages is an "indent text
object", which basically selects any same-level indented code. You can find one
implementation [here](http://www.vim.org/scripts/script.php?script_id=3037).
It's originally meant for python and some considerations have been made to make
it more convenient there, but it might work nicely for coffee as well. A
different one by Kana Natsuno can be found
[here](http://www.vim.org/scripts/script.php?script_id=2484). That one's
interesting as being built on a generic text object framework,
[textobj-user](http://www.vim.org/scripts/script.php?script_id=2100)

That said, making our own simple indent text object is rather trivial given the
above helpers:

``` vim
onoremap ii :<c-u>call <SID>IndentTextObject()<cr>
onoremap аi :<c-u>call <SID>IndentTextObject()<cr>
xnoremap ii :<c-u>call <SID>IndentTextObject()<cr>
xnoremap ai :<c-u>call <SID>IndentTextObject()<cr>

function! s:IndentTextObject()
  let upper = s:UpperIndentLimit(line('.'))
  let lower = s:LowerIndentLimit(line('.'))

  if lower > upper
    exe upper
    exe 'normal! V'.(lower - upper).'j'
  else
    normal! V
  endif
endfunction
```

Put together, the `IndentLimit` helpers fetch the area around the current line
with the same level of indentation. Getting Vim to recognize it in the relevant
mappings is a matter of marking the area in visual mode. To do that correctly,
the first thing we need to check is that the lower limit is below the upper
one:

``` vim
if lower > upper
  exe upper
  exe 'normal! V'.(lower - upper).'j'
  " ...
```

That `exe upper` may look a bit weird. Remember that `upper` is a line number,
so let's say that number is, for example, 42. `exe 42` will translate to
executing the command `42`, which is equivalent to typing `:42` in the
command-line, which in turn makes Vim jump to line 42 in the current buffer.
So, fun fact -- any number is a completely valid Vim command.

The second case means that the lower limit is not below the upper one, so we
either have a mistake in the code, or `lower == upper` -- the text object is a
single line. This could easily happen in a situation like this with the cursor
on `bar`:

``` coffeescript
if foo?
  bar
else
  baz
```

In that case, we simply mark the line with `normal! V`.

So now, we can select a given block of sequential code by hitting `Vii`, delete
it with `dii`, and so on. You might notice that `ii` and `ai` are the same in
this implementation. It might make sense to have `ai` mark one line above as
well, or maybe change `ii` to look for the *next* level of indentation or
something. I never really got used to using an "indent" text object, though, so
I can't say which would be useful. Consider the implementation an exercise for
the reader :).

## Function Text Object

A very similar (coffee-specific) text object is the "function" one. "Change
inner function" is one action I tend to do rather often, for example. The
initial implementation is pretty simple as well:

- Find something that looks like the start of a function upwards in the buffer.
- Find the body of the function by grabbing the code that's indented one level
  deeper than the function start.
- Mark the area, including or excluding the function start depending on the
  type of text object ("a" or "i")

Or, translated into code:

``` vim
onoremap if :<c-u>call <SID>FunctionTextObject('i')<cr>
onoremap аf :<c-u>call <SID>FunctionTextObject('a')<cr>
xnoremap if :<c-u>call <SID>FunctionTextObject('i')<cr>
xnoremap af :<c-u>call <SID>FunctionTextObject('a')<cr>

function! s:FunctionTextObject(type)
  let function_start = search('\((.\{-})\)\=\s*[-=]>$', 'Wbnc')
  if function_start <= 0
    return
  endif

  let body_start = function_start + 1
  " TODO (2012-03-31) if indent(body_start) == indent(function_start)
  let indent_limit   = s:LowerIndentLimit(body_start)

  if a:type == 'i'
    let start = body_start
  else
    let start = function_start
  endif

  if indent_limit > start
    exe start
    exe 'normal! V'.(indent_limit - start).'j'
  else
    exe 'normal! V'
  endif
endfunction
```

Notice that, this time, the `s:FunctionTextObject` function is invoked with a
parameter that depends on the specific mapping. An "inner" text object (`if`)
would operate on the body of the function, while an "around" one (`af`) would
manipulate the entire function definition. So, we could change the body of a
function with `cif`, and we could move a function around with `daf` and
pasting.

There's a fair amount of Vim magic here that may not be immediately apparent,
so let's break it down a little.

``` vim
let function_start = search('\((.\{-})\)\=\s*[-=]>$', 'Wbnc')
if function_start < 0
  return
endif
```

The first thing we need to do is find the start of the function. The `search`
call will do that and return the relevant line, or 0 if nothing is found. In
the latter case, we just return early, since there's no function to find.

The invocation of `search` is a pretty terse bundle of logic. The first
argument is the pattern we're looking for, and the second consists of control
flags for the behaviour of `search`. All available flags are listed
[here](http://vimdoc.sourceforge.net/htmldoc/eval.html#search\(\)), but if you
don't feel like reading through that:

- `b` stands for "backwards", which makes sense for a text object that marks
  the function we're currently in.
- `W` indicates we don't want to wrap around the ends of the buffer. No point
  in finding the function at the other end of the file, after all.
- `n` tells the call not to move the cursor. While it may be useful to put the
  cursor at the spot we're working on, it won't be necessary in this case.
- `c` accepts a match for the regex at the cursor position.

As for the regex:

- `\(...\)` is the grouping operator, and a `\=` at the end makes the group
  optional.
- `(.\{-})` would be the parameter list. The `\{-}` modifier is equivalent to
  Perl's `.*?` -- a nongreedy match for 0 or many of anything.
- `\s*` is something you should already be familiar with, matches any
  whitespace.
- `[-=]>$` is either a `->` or `=>` at the end of the line.

Putting it all together, it should start with an optional `()` group with
anything in it, then maybe some whitespace, and an `->` or `=>` arrow at the
end of the line, which mostly describes a coffeescript function. If you'd like
to learn a bit more about Vim regexes, you could jump to
[one of my older blog posts](http://andrewradev.com/2011/05/08/vim-regexes/).

Moving on along:

``` vim
let body_start = function_start + 1
if body_start > line('$') || indent(body_start) <= indent(function_start)
  if a:type == 'a'
    normal! V
  endif

  return
endif

let indent_limit = s:LowerIndentLimit(body_start)
```

The start of the actual function body would be the line after the function
definition. Of course, we need to check if one is present at all. If
`body_start` is greater than the last line number, then there's definitely no
body. If its indentation isn't larger than the one of the function definition,
it's the same case. In this situation, we need to bail early, so we `return`,
but if the type of the text object is an "around" one, we should mark the
function definition at least.

If there *is* a body, its last line will be found by the `s:LowerIndentLimit`
helper we defined earlier.

``` vim
if a:type == 'i'
  let start = body_start
else
  let start = function_start
endif
```

Nothing complicated here: If we type the object with `if` ("inner function"),
we start from the contents, otherwise, with an `af`, we start from the function
definition.

And as for the last part, it's exactly the same as in the indent text object:

``` vim
if indent_limit > start
  exe start
  exe 'normal! V'.(indent_limit - start).'j'
else
  exe 'normal! V'
endif
```

This simply marks the content in visual mode, careful to do the right thing if
there's only one line selected.

## Some minor tweaks

An obvious helper function to extract would be the one piece of code that's
exactly the same in both text objects:

``` vim
function s:MarkVisual(start_line, end_line)
  if a:end_line > a:start_line
    exe a:start_line
    exe 'normal! V'.(a:end_line - a:start_line).'j'
  else
    normal! V
  endif
endfunction
```

Not only does it help in this case, it's also a fairly often-used helper
function, so you might want to make it global (or autoloaded) and use it in
other situations as well. For our purposes here, though, let's rewrite it a
tiny bit into this:

``` vim
function! s:MarkVisual(command, start_line, end_line)
  if a:start_line != line('.')
    exe a:start_line
  endif

  if a:end_line > a:start_line
    exe 'normal! '.a:command.(a:end_line - a:start_line).'jg_'
  else
    exe 'normal! '.a:command.'g_'
  endif
endfunction
```

We've added one more argument, `command`, that could be either 'V' or 'v' and
determines the type of visual mode to enter. To have the function work well
with characterwise visual mode, there's two more changes:

- We don't jump to the given start line if it's the same as the current one.
- We execute an additional `g_` after each command in order to mark the complete line.

These tweaks don't change the previous behaviour (in a way we care for), so we
can safely replace it in the indent text object, leaving it a lean three lines:

``` vim
function! s:IndentTextObject()
  let upper = s:UpperIndentLimit(line('.'))
  let lower = s:LowerIndentLimit(line('.'))
  call s:MarkVisual('V', upper, lower)
endfunction
```

As for the function text object, we can improve it a bit by using characterwise
visual mode:

``` vim
function! s:FunctionTextObject(type)
  let function_start = search('\((.\{-})\)\=\s*[-=]>$', 'Wbc')
  if function_start < 0
    return
  endif

  let body_start = function_start + 1
  if body_start > line('$') || indent(nextnonblank(body_start)) <= indent(function_start)
    if a:type == 'a'
      normal! vg_
    endif

    return
  endif

  let indent_limit = s:LowerIndentLimit(body_start)

  if a:type == 'i'
    let start = body_start
  else
    let start = function_start
  endif

  call s:MarkVisual('v', start, indent_limit)
endfunction
```

We've replaced a `normal! V` with `normal! vg_` and we're using `s:MarkVisual`
with a `v` argument. Also note that the `n` in the `search` function's modifier
list is missing. This means that the `search` will move the cursor to the
beginning of the found text. So now, we'd get much better results on code like
this:

``` coffeescript
db.query "show tables", (err, result) ->
  console.log err, result
```

Instead of `caf` removing the entire first line, it'll stop just after the
first comma, allowing you to work only on the function even in this case.

## Summary

- Fetching "blocks of code" is fairly simple with indent-based languages. The
  `IndentLimit` helpers will be useful in future blog posts as well.
- Writing text objects is tricky and usually requires a certain amount of
  experimenting, but it could be worth it. It definitely makes sense to use a
  ready-made plugin for text objects, but it could be a good idea to work on
  creating your own to match your preferences and specific use cases.
- The `search` function is a very often-used one, along with its cousin,
  `searchpairpos`. Learning its control flags (and Vim regexes) can help a lot
  for building various tools.

The entire code is available as a [gist](https://gist.github.com/2294916). You
can also use the function text object from my
[coffee_tools](https://github.com/AndrewRadev/coffee_tools.vim) almost-plugin.
