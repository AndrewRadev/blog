---
layout: post
title: "Manipulating Coffeescript With Vim, Part 2: Wrapping and Unwrapping"
date: 2012-07-21 12:40
comments: true
categories: vim coffeescript
---

In coffeescript, particularly when you're dealing with nodejs, code is often
wrapped with lots and lots of callbacks. Since the indentation of the wrapping
function calls varies, it's not very easy to move them around, delete them, or
add new ones, because you need to adjust the indentation of the blocks of code
they contain.

In [my previous post](/2012/04/03/manipulating-coffeescript-with-vim-part-1-text-objects), I
defined two mappings to operate on blocks of code. In this one, I'll define two
that deal with the wrapping callbacks.

<!-- more -->

## Basic tools

[Before](/2012/04/03/manipulating-coffeescript-with-vim-part-1-text-objects), I
introduced a few helper functions. These will be useful here as well, and I'll
add a bit more to the toolbox. For convenience, here's a quick reference here:

``` vim
" Find the number of the lowest line having an indentation the same or larger
" than the current line.
function! s:LowerIndentLimit(lineno)
  " ...
endfunction

" Find the number of the highest line having an indentation the same or larger
" than the current line.
function! s:UpperIndentLimit(lineno)
  " ...
endfunction
```

And here's some more functions that will abstract away some of the more mundane
actions:

``` vim
function! s:SetIndent(from, to, indent)
  let saved_cursor = getpos('.')
  exe a:from . ',' . a:to . 's/^\s*/' . repeat(' ', a:indent)
  call setpos('.', saved_cursor)
endfunction

function! s:IncreaseIndent(from, to, amount)
  let saved_cursor = getpos('.')
  exe a:from . ',' . a:to . repeat('>', a:amount)
  call setpos('.', saved_cursor)
endfunction

function! s:DecreaseIndent(from, to, amount)
  let saved_cursor = getpos('.')
  exe a:from . ',' . a:to . repeat('<', a:amount)
  call setpos('.', saved_cursor)
endfunction
```

All three of these use a very popular pattern for saving the cursor. The
`getpos` call is used to fetch a data structure that describes a position in
the buffer. In particular, with `'.'`, we get the location of the cursor. When
we're done executing commands that move around the buffer, we can call `setpos`
to restore the position. It's not as elegant as using ruby blocks would be, but
it does the job.

The actual content of each of the functions is a single line, but it's a
slightly hard-to-read and often-used one, so it makes sense to hide it behind a
function call. Instead of explaining them in detail, I'll just give a few
examples of usage:

  - `s:SetIndent(42, 45, 2)` would execute the command `42,45s/^\s*/  /`, which
    replaces all whitespace at the start of the given lines with `a:indent`
    spaces.
  - `s:IncreaseIndent(42, 45, 1)` translates into `42,45>`, which moves the
    range rightwards a single shiftwidth.
  - `s:DecreaseIndent(42, 45, 3)` translates into `42,45<<<` -- similar to the
    above, except moving leftwards three shiftwidths.

It shouldn't be too difficult to decipher the logic behind the implementation,
having these results. In any case, armed with the three helpers and a way to
find the end of a block of code, let's see what we can do.

## "Wrapping" a block of code

The first interesting point is adding "surroundings" -- wrapping blocks. Let's
take this code, for example:

``` coffeescript
db.query "select * from users", (err, users) ->
  db.query "select * from posts", (err, posts) ->
    console.log [users, posts]
```

If we wanted to add another query before the "posts" one, we'd probably have to
do it in two steps, something like this:

``` coffeescript
# First, indent the block below the cursor
db.query "select * from users", (err, users) ->
    db.query "select * from posts", (err, posts) ->
      console.log [users, posts]

# Then, add the new line above
db.query "select * from users", (err, users) ->
  db.query "select * from posts", (err, posts) ->
    db.query "select * from comments", (err, comments) ->
      console.log [users, posts]
```

Right now, there's only two lines after the first select, but there could just
as easily be a lot more. An
[indent text object](http://www.vim.org/scripts/script.php?script_id=3037)
could help with this, but it would be even easier if we could just get the
indent as we hit the `O` key. Of course, overriding the built-in would be a
pretty bad idea in this case, since we'd lose the ability to *just* open a
single line. I'll use the `,` key as a leader and map `,O` to this action:

``` vim
nnoremap ,O :call <SID>OpenWrappingLineAbove()<cr>

function! s:OpenWrappingLineAbove()
  let start  = line('.')
  let end    = s:LowerIndentLimit(lineno)
  let indent = indent(lineno)

  call s:IncreaseIndent(start, end, 1)
  normal! O
  call s:SetIndent(line('.'), line('.'), indent)
  call feedkeys('A')

  undojoin
endfunction
```

It's just a few lines, which makes sense, since what we're trying to do is not
that complicated anyway. Let's break it down:

``` vim
let start  = line('.')
let end    = s:LowerIndentLimit(lineno)
let indent = indent(lineno)
```

The first part is initializing the data we'll need. The `start` variable holds
the current line, `indent` is its indentation level as a number of shiftwidths,
and `end` is set to the end of the block of contiguous indentation. Note that
`indent` would be a multiple of shiftwidths in coffeescript if you're following
conventions. If this were indented using tabs, things would be slightly
different.

So, now that we have those, let's indent the range. Remember the
`IncreaseIndent` helper?

``` vim
call s:IncreaseIndent(start, end, 1)
```

All that's left is to open up a new line above and set its indent
appropriately:

``` vim
normal! O
call s:SetIndent(line('.'), line('.'), indent)
call feedkeys('A')
```

Remember that we've moved the current line a shiftwidth deeper, so now `indent`
points to the original indentation -- exactly what we need for the new line
we're opening above, hence the `s:SetIndent`.

The `feedkeys` call is used instead of a `normal!`, because we want to leave
the user in insert mode afterwards, and that's the simplest way to do that.

The last line is the command `undojoin`, which is a useful trick. We're
actually performing two user actions, an `O` and then a `:substitute` to set
the indent. If the user tries to undo this, they'll have to do it in two steps.
The `undojoin` makes it a single action as you'd expect from a mapping.

## "Unwrapping"

The other way around is deleting a surrounding. Let's take the example from earlier:

``` coffeescript
db.query "select * from users", (err, users) ->
  db.query "select * from posts", (err, posts) ->
    db.query "select * from comments", (err, comments) ->
      console.log [users, posts]
```

We'd like to be able to delete the middle query, the "posts" one, and not
disturb the flow. Doing it by hand might look a bit like this:

``` coffeescript
# First, delete the line
db.query "select * from users", (err, users) ->
    db.query "select * from comments", (err, comments) ->
      console.log [users, posts]

# Then, adjust indenting
db.query "select * from users", (err, users) ->
  db.query "select * from comments", (err, comments) ->
    console.log [users, posts]
```

So that's the process we'll perform to solve the problem with vimscript:

``` vim
nnoremap ,dh :call <SID>DeleteWrappingLine()<cr>

function! s:DeleteWrappingLine()
  normal! dd

  let start = line('.')
  let end   = s:LowerIndentLimit(lineno)

  call s:DecreaseIndent(lineno, limit, 1)
endfunction
```

The translation is short and simple. Delete the current line, get the new
"current line" and the last line of the code block, then just decrease the
indent of the area defined by those two. The mapping I've chosen is `,dh`, to
remain consistent with `,O` ("h", because the motion is moving the text
to the left).

## Going visual

There are a few minor problems with both mappings that we can fix by making
them work with visual selections. First of all, the `,O` mapping is useful when
we want to add "wrappings" to an already-wrapped block, but what if we want to
wrap only a particular area of sequential code? For example:

``` coffeescript
db.query "select * from users", (err, users) ->
  console.log comments
  console.log users
```

Now, we'd like to get this:

``` coffeescript
db.query "select * from users", (err, users) ->
  db.query "select * from comments", (err, users) ->
    console.log comments
  console.log users
```

Using the `,O` mapping directly on `console.log comments` would indent the
`users` line as well:

``` coffeescript
db.query "select * from users", (err, users) ->
  # cursor
    console.log comments
    console.log users
```

Again, this is a simplified example. It's easy to imagine a sequential chunk of
code in which we'd want to wrap only a particular area. So, a simple solution
is to make the `,O` mapping work with a visual mode selection by indenting that
alone. It turns out that it's not very difficult to accomplish.

``` vim
nnoremap ,O :call <SID>OpenWrappingLineAbove('n')<cr>
xnoremap ,O :<c-u>call <SID>OpenWrappingLineAbove('v')<cr>

function! s:OpenWrappingLineAbove(mode)
  if a:mode ==# 'v'
    let start  = line("'<")
    let end    = line("'>")
  else
    let start  = line('.')
    let end    = s:LowerIndentLimit(start)
  endif

  let indent = indent(start)

  call s:IncreaseIndent(start, end, 1)
  normal! O
  call s:SetIndent(line('.'), line('.'), indent)
  call feedkeys('A')

  undojoin
endfunction
```

So, what is the difference? There is a single `mode` argument to the function
now -- either "n" or "v" depending on which mapping we're executing. The visual
mode mapping also removes the range that's automatically inserted for all
visual mappings with a `<c-u>`
([:help c_CTRL-U](http://vimdoc.sourceforge.net/htmldoc/cmdline.html#c_CTRL-U)).
As for the implementation, the only difference between modes is how we get the
`start` and `end` lines. In visual mode, we can simply fetch them from the `'<`
and `'>` marks that point to the area defined by the last visual mode
selection.

We'll do something similar for the second mapping. In that case, the problem is
a bit different -- we can currently delete a single line, but not multiple ones
in a single go. So, in a case like this:

``` coffeescript
db.query "select * from users", (err, users) ->
  db.query "select * from posts", (err, posts) ->
    db.query "select * from comments", (err, comments) ->
      console.log [users, comments]
      console.log [users, posts]
```

We'd like to be able to mark the second and third lines and just delete them
both to get to this:

``` coffeescript
db.query "select * from users", (err, users) ->
  console.log [users, comments]
  console.log [users, posts]
```

Just as with the previous mapping, we'll introduce a `mode` argument and
separate the logic:

``` coffeescript
nnoremap ,dh :call <SID>DeleteWrappingLine('n')<cr>
xnoremap ,dh :<c-u>call <SID>DeleteWrappingLine('v')<cr>

function! s:DeleteWrappingLine(mode)
  if a:mode ==# 'v'
    let start_line       = line("'<")
    let end_line         = line("'>")
    let new_current_line = nextnonblank(end_line + 1)

    if end_line == line('$')
      let indent = 0
    else
      let indent = indent(new_current_line) - indent(start_line)
    endif

    let amount = indent / &sw
    exe "'<,'>delete"
  else
    let amount = 1
    normal! dd
  endif

  let start = line('.')
  let end   = s:LowerIndentLimit(start)

  call s:DecreaseIndent(start, end, amount)
endfunction
```

The bottom part of the function hasn't changed significantly. And if we're not
in visual mode, we just assume that the amount to de-indent is 1 and carry on
as before. In the case of several selected lines, it's a different matter.
There are three cases for the deleted text that we should consider:

  1. The marked code is at the end of the file (`end_line == line('$')`). This
     is the simplest case, because it just means we don't have to care about
     indenting at all.
  2. The marked code is at the top of the file (`start_line` == 1). In this
     case, we just want to take the new "current line" and place it at
     indentation zero. It turns out that's actually expressed with the same
     code as the next case.
  3. The selection is somewhere in the midst of other code. The new "current
     line" basically needs to take the place of the first line, so the
     adjustment can be calculated with
     `indent(new_current_line) - indent(start_line)`.

I've included the second case as a part of the thought process, but it turns
out not to be necessary. Note that we're dividing the lines by `&shiftwidth`.
This assumes the code is following the coffeescript convention of indenting
with spaces.

What if the indentation amount is zero or negative? This could happen, for
example, in this case:

``` coffeescript
db.query "select * from users", (err, users) ->
  db.query "select * from comments", (err, users) ->
    console.log [users, comments]
console.log "something"
console.log "something else"
```

If we were to mark the third and fourth line and execute the mapping, the
`amount` variable would be -1. However, the implementation of
`s:DecreaseIndent` uses the `repeat` function, which returns an empty string
when given a non-positive number, so the action is still correct -- nothing is
reindented at all.

## Summary

  - Given a few basic helper functions, moving indented blocks around is not
    very difficult. The tricky part is figuring out the logic of what we want
    to do.
  - It pays off to start with a simple case and think about how to expand it
    later. For example, you could start writing something that works on a
    single line and then figure out how to generalize it with visual mode.
  - A simple way to re-use a function for the implementation of a mapping in
    both visual and normal mode is to make it receive the mode as an argument
    and slightly change its behaviour depending on that.
  - The `feedkeys()` function could be more convenient than `normal!` depending
    on what you're trying to do.
  - `undojoin` can be used to turn several actions into a single one in terms
    of undo.

As in the previous post, the code is available as a
[gist](https://gist.github.com/3155336). It's also a part of the
[coffee_tools](https://github.com/AndrewRadev/coffee_tools.vim) almost-plugin.
