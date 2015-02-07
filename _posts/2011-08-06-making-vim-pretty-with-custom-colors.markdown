---
layout: post
title: "Making Vim Pretty With Custom Colors"
date: 2011-08-06 16:20
comments: true
categories: vim
published: true
---

Pretty much all editors have the option of changing themes and tweaking colors.
Vim's no different, but instead of menus and wizards, it's done by using
vimscript. While it could be argued that this is more difficult than in a
"conventional" editor, I really don't think that's the case. I've recently been
hacking on my own color scheme a bit, so I'll take this opportunity to do a
post on how to manage colors in vim and achieve some nice effects.

<!-- more -->

## The basics

Vim's syntax items are organized into named groups: `Normal`, `Constant`,
`Function`, and so on. Every language that vim supports has a syntax file that
defines how the language tokens are mapped to those groups. This can be a very
complicated task involving tons of regular expressions and it won't be
discussed here. This article tackles the much simpler problem of defining the
mapping from group to actual color.

A colorcheme is a file, containing such mappings. These need to be located in
vim's runtime, under a "colors" directory. Activating a scheme is done by
executing:

``` vim
colorscheme scheme_name " or, a bit shorter:
colo scheme_name
```

The actual mappings are created by using the `highlight` command, or `hi` for
short. As an example, this is how you'd set all `Normal` text to be white on a
black background in the GUI:

``` vim
hi Normal guifg=White guibg=Black
```

As you can see, the first argument is the syntax group and the rest are
`key=value` modifiers. Different ones are used for GUI and terminal colors. It
goes like this:

  - `ctermfg`, `ctermbg`: These have effect on color terminals. On 8-color
    ones, you have access to several names like "blue", "red", and so on. You
    can also use the numbers from 0-15, where the upper half are "bright"
    versions of the original eight. These days, it's normal to use a 256-color
    terminal emulator, so you could probably utilize the whole 0-255 range.
    I'll talk about a plugin that helps with that later on. If you frequently
    find yourself without a running X server, you might want to consider
    limiting your choice to the base eight colors. Take a look
    [here](http://vimdoc.sourceforge.net/htmldoc/syntax.html#highlight-ctermbg)
    for more details on those.

  - `guifg`, `guibg`: These values have an effect only in the gui (gvim or
    mvim), and you can set them with color names or with hex values (#rrggbb).
    Generally, I'd recommend sticking to the hex codes. You can express more
    colors with them, and there are some nice plugins that could highlight that
    format, but more on that later.

The modifiers ending in "fg" set the foreground, the ones with "bg" are for the
background. You can reset the color to its default value by setting it to
`NONE`. If you want to specify additional properties, like making the text bold
or italic, you can use `gui=` and `cterm=`. For instance, to make searches
yellow, bold and underlined in the terminal:

``` vim
hi Search ctermfg=Yellow ctermbg=NONE cterm=bold,underline
```

It looks a bit like this:

![search highlighting](/images/search_highlighting.png)

Another important variation of the `highlight` command is `highlight link`. It
sets a syntax group's colors to be the same as another one's. This is used for
almost all language-specific syntax items. For instance, the `rubyFunction`
syntax group links to the `Function` one.

``` vim
hi def link rubyFunction Function
```

The `def` part stands for "default" and it means that the link will only take
effect if this syntax group hasn't been specified before. That way, if you want
to override it, you can do that in one of your own vimscripts.

# The process

So, now that we know the basic commands, where do we begin?

While you _could_ start from scratch, there's a lot of syntax to work with, so
it's highly recommended to grab some other colorscheme and hack on that. Your
modified file needs to be located under a "colors" directory in the vim
runtime, for example, `~/.vim/colors`. Unless you have some specific
requirements, it needs to start with some boilerplate. First, we set the
background:

``` vim
set background=dark
```

This can also be "light" and it's useful as a baseline. It affects the default
colors that come with vim, so if you leave some of them as they are, they will
change depending on its value. Some colorschemes try to adapt to it, but it's
simplest to just set it to one value and code according to that.

``` vim
hi clear
if exists("syntax_on")
  syntax reset
endif
```

This cleans up the current highlighting and syntax changes. It ensures that
when you change to this colorscheme, you start with a clean slate.

``` vim
let g:colors_name = 'colorscheme_name'
```

This line sets the name of the colorscheme, and it's important for it to match
the filename. The above example should be in a file called
"colorscheme_name.vim".

After this, it's time to start defining the actual syntax groups. A full list
of all of them can be found with
[:help highlight-groups](http://vimdoc.sourceforge.net/htmldoc/syntax.html#highlight-groups).
You can also execute `highlight` without an argument to see a full dump of all
the colors set at the moment. Here are few of the more common ones:

  - `Normal`: _The_ most common group of all. You probably want to keep it
    simple with this one, using some variation of white and black.

  - `Comment`: Should be self-explanatory.

  - `Constant`: This one is actually _not_ for constants, defined within the
    language, but for things like strings and numbers. There are specific
    groups that usually link to it, `String`, `Number`, `Boolean`, and so on,
    so you can color those in something more specific, if you'd like for them
    to stand out.

  - `Operator`: Braces, mathematical operators, commas. Which ones have this
    highlighting actually depends on the filetype, some prefer to use `Special`
    for punctuation.

  - `Statement`: Usually control flow statements, but this depends on the
    filetype as well. In vim, the built-in commands are highlighted with this
    group.

After you've decided on colors on a few of these, the rest can be linked to
them with `highlight link`, so you don't have to copy-paste the definitions.

Remember that you can execute `highlight` commands directly in the command
line, which will let you experiment with the colors before you write them to
the file. If you change your mind, just set the colorcheme again, which will
clear your tweaks. You can also execute `:source` with the filename, which
might be more convenient if you have a mapping for it.

## Tools

When you're looking at code, it might not be immediately obvious which tokens
map to which groups. Fortunately, vim has a few functions that help you
discover the syntax properties of the text. Unfortunately, they're a bit
confusing. You can investigate them in detail
[here](http://vimdoc.sourceforge.net/htmldoc/eval.html#synID(\)),
but I suggest you try out the
[SyntaxAttr.vim](http://www.vim.org/scripts/script.php?script_id=383)
plugin instead. After placing it in `autoload`, you just need to execute `call
SyntaxAttr#SyntaxAttr()`. This will display information about the syntax
directly under the cursor. Once you know what group a token belongs to, it's
easy to modify it.

Another interesting plugin that helps in the console is
[xterm-color-table.vim](http://www.vim.org/scripts/script.php?script_id=3412).
It has a single command, `XtermColorTable`, that displays all of the current
terminal's colors in a split window. They're annotated with the terminal's
color codes, 0-255, and also with hexcode equivalents, which could be very
helpful if you're trying to be GUI-compatible.

And as for the hexcodes, the
[colorizer.vim](http://www.vim.org/scripts/script.php?script_id=3567)
plugin highlights them all in the colors they represent. Since that format is
only compatible with the GUI, it's probably best to use it there, but it works
fairly well in the terminal as a sort of a guideline.

## Other interesting highlight groups

The SyntaxAttr plugin is great for most syntax groups, but there are a lot of
areas that you can't put the cursor on. Here are a few you might be interested
in:

  - `CursorLine`: I don't usually use a
    [cursor line](http://vimdoc.sourceforge.net/htmldoc/options.html#%27cursorline%27),
    but it helps a bit in the NERDTree. I like it unobtrusive, so I just make
    it underlined with NONE for the background.

  - `DiffText`, `DiffAdd`, `DiffChange`, `DiffDelete`: These control the colors
    when using vim's diffing capabilities. The
    [solarized](https://github.com/altercation/vim-colors-solarized)
    colorscheme, for example, makes removed items red and added ones green.

  - `Pmenu`, `PmenuSbar`, `PmenuThumb`, `PmenuSel`: Coloring the popup menu
    might seem like a small tweak, but having a bright pink one with white text
    can be _highly_ annoying. It's actually the reason I started learning how
    to customize my colors.

  - `Visual`: This one is for highlighting the visual selection. I'd recommend
    aiming for good contrast with a bright background color.

  - `Search`: If the default look of search matches looks unsightly to you, you
    could tweak this as I showed above. Note that this also affects the
    currently active line in the quickfix window.

  - `StatusLine`, `StatusLineNC`, `VertSplit`: These groups handle the looks of
    the window separator lines. I've always disliked how "fat" the windows
    borders look in vim. That's why I set a white foreground on a `NONE`
    background and tweaked my
    [fillchars](http://vimdoc.sourceforge.net/htmldoc/options.html#%27fillchars%27)
    to `stl:-,stlnc:-,vert:│`

    ![separator lines](/images/separator_lines.png)

    I've been very happy with the result, although I would have liked it a lot
    more if I could set a horizontal line character to the statusline filler.
    Apparently, vim doesn't let you put multibyte characters there...

  - `Folded` and <strong>FoldColumn</strong>: The second one only matters if
    you set a
    [foldcolumn](http://vimdoc.sourceforge.net/htmldoc/options.html#%27foldcolumn%27),
    but the first one would be important if you use folding at all. You
    should be careful not to make folded text too similar to status lines, or
    you might get confused when you work with splits.

  - `WildMenu`: If you've turned on the
    ['wildmenu'](http://vimdoc.sourceforge.net/htmldoc/options.html#%27wildmenu%27)
    option, you might benefit from tweaking this one. It controls the color
    of the active item in the menu. Since I don't have a background for the
    statusline anyway, I just set the font to something bright and obvious.
    Looks like this:

    ![wildmenu](/images/wildmenu.png)

  - `MatchParen`: This is not one of vim's core defaults, but it ships with the
    matchit plugin that comes with vim. You can customize what the matching
    brace looks like by tweaking this group.

## So, why not do it all with XML or something?

Many other editors are designed with the assumption that these color mappings
are just data. That makes a lot of sense and is simple enough to implement. You
can set the colors in XML or YAML files and let the editor parse them and
provide a nice GUI with color pickers and preview panes. The benefit of Vim's
approach is that it gives you a lot of freedom, without sacrificing too much.
Sure, the syntax is a bit frightening at first, but if you look at it at a high
level, it's just another key-value store. Except it's actually a part of the
scripting language, so you can put variables, expressions, whatever you need.

A very nice example is [Solarized](https://github.com/altercation/solarized).
It's a well thought-out set of colors for many different applications. The vim
colorscheme is interesting, because it goes to great lengths to be
customizable. You can set a few variables that control the contrast and
sharpness levels and you can switch between a light and a dark variant.

## Summary

  - A vim "theme" is called a "colorscheme" and is just a bunch of vimscript.
    The `highlight` command is the main one you need to remember.
  - You can set colors for the GUI or for the terminal, vim can't automatically transform the values from one to the other.
  - All the syntax groups can be seen with a
    [help highlight-groups](http://vimdoc.sourceforge.net/htmldoc/syntax.html#highlight-groups).
  - A few plugins that help are
    [SyntaxAttr.vim](http://www.vim.org/scripts/script.php?script_id=383),
    [xterm-color-table.vim](http://www.vim.org/scripts/script.php?script_id=3412),
    and [colorizer.vim](http://www.vim.org/scripts/script.php?script_id=3567).
  - As is usually the case with Vim, the colorscheme system is a bit odd at
    first, but flexible and fairly comfortable to work with once you get used
    to it.
