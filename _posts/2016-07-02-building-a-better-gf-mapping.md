---
layout: post
title: "Building a better gf mapping"
date: 2016-03-09 11:44
comments: true
categories: vim ember
published: false
---

I recently started working with ember.js. It's a nice framework, but, like most newish technologies, Vim support is minimal. So, as I usually do in such cases, I started working on some tools to help me out with navigation. Tim Pope's [projectionist](https://github.com/tpope/vim-projectionist) helped a lot, but I wanted more, so I started building it up in what would later be published as [ember_tools](https://github.com/AndrewRadev/ember_tools.vim).

The biggest feature was the `gf` mapping ("go to file"), which was inspired by the one in vim-rails. Using `gf` in a rails project almost always does "the right thing" for whatever you can think of. So, I poked around in that one, tried to figure out how it was implemented. In the process, I learned a few things and had a bunch of pretty good ideas, which I'll talk about in this blog post.

<!-- more -->

## Some basics

Before I start with the interesting stuff, let me explain a few basics you might need to know in order to understand it. Feel free to skip this section if you're feeling confident in your Vimscript skills.

First, the way you ordinarily customize the `gf` mapping is not by directly remapping it, but by modifying the "include expression", or `includeexpr`. It's an expression that gets evaluated every time you press `gf` or `<c-w>f` or anything in that family of mappings. In this particular scenario, things are implemented a bit differently, but it's useful to know the concept.

A different setting that modifies some core Vim behaviour is `iskeyword`. It contains a comma-separated list of all (groups of) keys that are considered part of a "word". This affects what pressing `w` does, it affects `expand('<cword>')`, syntax highlighting, all sorts of things. It's generally pretty risky to try changing it from its default. Recent versions of Vim allow some finer-grained control over some of this behaviour, but this one setting remains a powerful and dangerous tool that we're going to use in a very careful way later.

On a completely unrelated note, *autocommands* are sort of like Vim events. You can listen to an autocommand like `BufWrite` (when Vim writes the buffer to a file), or `InsertLeave` (when Vim exits insert mode) to run any old Vim command at the right time.

And the last concept that you'll need to know about, is the `execute` command, often shortened to `exe`. It's sort of like eval in most languages, but it doesn't allow you to evaluate a random expression, only a command. For instance, if you have some sequence of keypresses that you've been building up, like

``` vim
let keypress_sequence = number_of_steps_to_the_right . "l"
```

You can't just run the sequence with `normal! keypress_sequence`. That would run the literal key sequence "keypress_sequence". Instead, you can run `exe "normal! ".keypress_sequence` to evaluate the variable `keypress_sequence` to its string value and execute the `normal!` command with the right thing.

And, if you didn't figure it out from the last paragraph, in Vimscript, the dot is used for string concatenation, so:

``` vim
let a_hundred = "100"
let a_hundred_plus_one = a_hundred . " + 1"

echo a_hundred_plus_one
" -> 100 + 1
```

I can't guarantee you won't have to reach for `:help` in the following paragraphs, but hopefully this should be enough. And with that out of the way...

## How it works in vim-rails

If you poke around enough in vim-rails' source code, looking for how `gf` works, you'll likely end up in a place that has the following line:

``` vim
cmap <buffer><script><expr> <Plug><cfile> rails#cfile('delegate')
```

It maps the (fake) key sequence `<Plug><cfile>` to the expression `rails#cfile('delegate')` function. Yes, `<Plug>` is a "key" of sorts. If you look at `:help <Plug>`, you'll discover that it "can be used for an internal mapping, which is not to be matched with any key sequence". If you follow some links, you'll also find it's "a special code that a typed key will never produce".

In general, `<cfile>` is something that expands on the command line to the filename under the cursor, based on Vim's built-in rules for recognizing a filename. What Tim Pope does here is create a *new* expression, `<Plug><cfile>`, which expands to whatever `rails#cfile('delegate')` returns.

That last function is the one that actually does the heavy lifting of figuring out how the stuff under the cursor maps to an actual file. So that, in vim-rails, calling `:echo rails#cfile('delegate')` with the cursor on the word "user", would output "app/models/user.rb".

The expression `<Plug><cfile>` is mapped to that value on the command-line with a `cmap`. The following two lines hook this up to the `gf` mapping:

``` vim
nmap <buffer><silent> <Plug>RailsFind <SID>:find <Plug><cfile><CR>
" ... snip ...
nmap <buffer> gf <Plug>RailsFind
```

This creates a normal-mode mapping for `<Plug>RailsFind`, just in case somebody wants to use a different mapping for it. What it actually does is call the `:find` command with the right filename. Interestingly enough, the `:find` command can find all kinds of files in the `path` setting, so there might be some value in playing around with that one... But that's not something I've experimented with yet.

The actual `gf` mapping just delegates to the plug-mapping. There's a few other mappings around that area that set things up for `<c-w>f` and similar other mappings, but they work roughly the same way.

So why is this interesting for ember tools? Well, a tiny problem I happened to have is that my ember app was in a subdirectory of a rails app. This would activate vim-rails for my ember files, and that means activating rails' gf. In order to avoid something like this happening, I added this little workaround to `ember_tools`:

``` vim
" Override gf if rails sets it after us
autocmd User Rails cmap <buffer><expr> <Plug><cfile> ember_tools#Includeexpr()
```

Which I find pretty clever! See, thanks to Tim Pope's `<Plug><cfile>` setup, I only need to override that one mapping to return the results of calling my own function. That function can, at any point, `return rails#cfile('delegate')` to fall back to the default vim-rails behaviour. All the other related mappings work just fine. It's an interesting way to achieve this without a complicated combination of settings.

This also opens up some possibilities to extend vim-rails' `gf` mapping! As powerful as it is, there's a few improvements I wanted to do there as well... I started work on this in a script I called [rails_extra](https://github.com/AndrewRadev/Vimfiles/blob/9b17ea1be4ad1c12882aae5068699e43ea4f9310/personal/plugin/rails_extra.vim). Currently, it's a mess of functions from various of my plugins, and it's not organized particularly well. It works wonders, though. I've made `gf` follow custom rspec matchers, look for factories, go to `require`d assets in the asset pipeline. My favorite extension, though, is `gf` on translation keys, which I'll talk about next.

## Finding translations

Internationalization has always been a pain for me to keep track of. It's a necessity, but it does complicate things a lot and I often wish I had better tooling for it. For ember, I use the [ember-i18n](https://github.com/jamesarosen/ember-i18n) project, and I hook up a helper to be able to do something like:

``` handlebars
{{"{{i18n 'some.nested.translation_key'"}}}}
```

So how do I set things up so I can `gf` on the key and end up on the translation? The tricky bit here is not the actual file. If I can detect I'm on a translation key, I can easily say that the file to be returned is, in my case, `../config/en.yml`. (In this particular project, the translations are the same ones defined for the rails project, which happens to contain my ember one.)

Detecting the key might look like this:

``` vim
function! EmberGfTranslations()
  " ... snip ...
  if !ember_tools#search#UnderCursor('i18n [''"]\zs\k\+[''"]')
    return ''
  endif

  let translation_key = expand('<cword>')
  " ... snip ...
endfunction
```

I'm not going to explain `ember_tools#search#UnderCursor`, because it would take me another full blog post to go over all the weird logic in there. Suffice it to say, it works reasonably well for checking whether the cursor is somewhere on text that matches this pattern and moving said cursor to the beginning of it. In our case, due to the `\zs`, the beginning happens to be right on top of the translation key.

Note, by the way, that the pattern matches `\k\+` (in quotes). The `\k` pattern matches "keyword" arguments, and, ordinarily, the `.` character is not one of them (it causes way more trouble than it's worth). But in most ember identifiers I care for, `.`, `-`, and `/` are perfectly valid. Think of components, for instance -- `{{"{{user/profile-picture"}}}}`. So I decided I can just do something like this:

``` vim
let saved_iskeyword  = &iskeyword

let callbacks = [
      \ ...
      \ 'EmberGfImports',
      \ 'EmberGfTranslations',
      \ 'EmberGfRoutes',
      \ ...
      \ ]

for callback in callbacks
  try
    set iskeyword+=.,-,/
    " look for the right callback to invoke
  finally
    " whatever happens, just restore the old value of `iskeyword`
    let &iskeyword = saved_iskeyword
  endtry
endfor
```

Basically, I just add everything I need to `iskeyword`, and restore it afterwards. No harm, no foul.

Anyway, after storing the `translation_key` I found under ther cursor, I can split it by dots to get the list of sections in the rails yaml file. In the example, I'd have a list like `['some', 'nested', 'translation_key']`. So what now?

The way the `gf` mapping works, we can only have our custom include expression return a file path. In our case, the file is easy -- the big yaml file with translations, `config/locales/en.yml`. But how do we make Vim jump to the right place where the translation is found?

Well, the solution I came up with... I'm honestly kind of surprised that it works. Let me start a new section for that.

## When you have a problem, just put :exe until it's fixed

Imagine you want to set things up so that the next time a particular file is opened, a particular command is run, only once. It might look something like this:

``` vim
autocmd BufEnter /some/file/path :echo "foo"
autocmd BufEnter /some/file/path :call ClearFileOpenCallback() " how to do this?
```

The first autocommand executes the thing we need, the second one clears that callback. How can we clear the callbacks? A simple way is to group them with a specific name. Here's how that might look:

``` vim
function SetCallbacks()
  augroup file_open_callback
    autocmd!

    " set up a bunch of callbacks
  augroup END
endfunction

function ClearCallbacks()
  augroup file_open_callback
    autocmd!
  augroup END
endfunction
```

By naming a group called `file_open_callback`, we can refer to this temporary autocommand group. The initial `autocmd!` in the beginning of the group clears everything that's ever been defined in it. That's why our "clear" function is just the group and the clearing command.

So the setup makes sense -- one function sets a callback, which, after it's done with its work, triggers the other function. Said function clears the callback -- and that's how you get a one-shot autocommand.

Now, the question is, how do we set up the autocommand so that it searches for the pattern we give it? Just put `:exe` until it works:

``` vim
function! ember_tools#SetFileOpenCallback(filename, ...)
  " all the words to search for, provided as variable arguments:
  let searches = a:000

  " use absolute paths:
  let filename = fnamemodify(a:filename, ':p')

  augroup ember_tools_file_open_callback
    autocmd!

    " start by going to the top of the file:
    exe 'autocmd BufEnter '.filename.' normal! gg'

    " search for every pattern, one after the other:
    for pattern in searches
      exe 'autocmd BufEnter '.filename.' call search("'.escape(pattern, '"\').'")'
    endfor

    " clear all callbacks, so we leave it a one-shot thing:
    exe 'autocmd BufEnter '.filename.' call ember_tools#ClearFileOpenCallback()'
  augroup END
endfunction

function! ember_tools#ClearFileOpenCallback()
  augroup ember_tools_file_open_callback
    autocmd!
  augroup END
endfunction
```

The exe calls just evaluate down to autocommands keyed to that particular file. Each of the steps is triggered only on `BufEnter` of this one particular file, and they run in a sequence. Once they're all called, we can clear the callbacks.

After getting the translation keys in an array, we can split up the keys and search for them in sequence with (something similar to):

``` vim
:call ember_tools#SetFileOpenCallback('config/locales/en.yml', 'some', 'nested', 'translation_key')
```

This ends up creating a list of autocommands that looks like this:

``` vim
autocmd BufEnter /path/to/config/locales/en.yml normal! gg
autocmd BufEnter /path/to/config/locales/en.yml call search("some")
autocmd BufEnter /path/to/config/locales/en.yml call search("nested")
autocmd BufEnter /path/to/config/locales/en.yml call search("translation_key")
autocmd BufEnter /path/to/config/locales/en.yml call ember_tools#ClearFileOpenCallback()
```

After that, we return `config/locales/en.yml` and the autocommands kick in, position the cursor in the right place, and then unset themselves. Not that complicated, even if it is kind of hacky. So the function that takes care of going to the translations ends up looking like this:

``` vim
function! EmberGfTranslations()
  " ... snip ...
  if !ember_tools#search#UnderCursor('i18n [''"]\zs\k\+[''"]')
    return ''
  endif

  let translation_key = expand('<cword>')
  let translations_file = fnamemodify('config/locales/en.yml', ':p')

  " Prepare the arguments to the file open callback function:
  "   - The filename to fire on
  "   - The pieces of the key, searched one by one
  "
  let callback_args = [translations_file]
  call extend(callback_args, split(translation_key, '\.'))

  " The "call" function calls a function. Vimscript can be an odd language
  " sometimes.
  call call('ember_tools#SetFileOpenCallback', callback_args)

  " After we've set up the autocommands to fire when the file is opened, we
  " return the file path and let Vim take care of the actually opening it (in
  " a split, or tab, or whatever, depending on the mapping that was invoked)
  return translations_file
endfunction
```

There's a few Vimscript-y weirdnesses in there, but hopefully, it should be readable enough as it is.

## To Sum Up

The `gf` mapping is a useful abstraction to navigate your code, and extending it yourself is not super difficult to do. You take the text under the cursor, pick it apart with regexes and figure out what the path you're looking for is. You do need some background knowledge, but the `:help` files are always nearby to help you out. If you're working on a particular framework that doesn't have special support for it, consider writing your own.

If you've never written Vimscript so far, it could be a nice introduction that'll give you a good productivity boost. Hope this blog post has given you some basic tools to get you started, and some clever ideas to inspire you to keep going.
