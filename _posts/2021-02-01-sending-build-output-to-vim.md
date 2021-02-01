---
layout: post
title: "Sending Build Output to Vim"
date: 2021-02-01 16:40
comments: true
categories: vim rust
published: true
---

Vim is actually quite easy to build from source. You can edit `src/Makefile` and enable features and custom language extensions. Turns out, I hadn't scrolled through that file in a while, since version [8.0.1295](https://github.com/vim/vim/commit/e42a6d250907e278707753d7d1ba91ffc2471db0) comes with an interesting addition -- the compilation flag `--enable-autoservername`.

Running the editor with a `--servername` parameter allows remote connections from a different instance using command-line flags or function calls. I've been using this functionality to build a [custom testing framework](https://github.com/AndrewRadev/vimrunner) in Ruby, but you have to knowingly launch it with that flag. Now, each instance can be available to connect with by default.

It's not *necessary*, exactly -- you could always make yourself a shell alias like `alias vim="vim --servername VIM-$RANDOM"`. But the discovery gave me an idea of how to remove a tiny bit of friction from my Rust workflow, and I might end up using the same technique in the future. Read on to learn how to send your build output to a Vim instance for easier processing.

<!-- more -->

## But why?

When using a large IDE, or even something smaller like VSCode, I think there's a tendency to keep one instance running and open things in it. In fact, on my machine, running `code <some-file>` in the terminal opens the code in an existing instance, even though you *can* launch multiple ones.

Vim is a lot more decoupled than that. You *can* have one big Vim open holding tabs, terminal windows, git commands and a lot more. But it's just one possible workflow and somewhat counter to what you get from the defaults. Personally, I tend to have one Vim focused on the code I'm currently working on, but I might also open other ones with notes or other projects to ~~copy-paste from~~ use as inspiration.

I also use separate terminals for running commands -- tests, git, etc. I respect the flexibility of `:terminal`, but I guess I'm just too used to jumping between workspaces and I like keeping things separate. But this does make it slightly harder to debug builds. Usually, when Rust shows me compile errors or test failures, I'd double-click their locations and paste them into Vim. A plugin like [vim-fetch](https://github.com/wsdjeg/vim-fetch) helps a lot with this kind of thing.

It works, it's fine, I'm used to it. But if I *could* directly send the errors over to my editor...

## Finding the right instance

First, let's decide where to send the output. There might be multiple instances, but I'm looking for the one in the same directory I'm running the command in:

``` ruby
# Let's get a list of all available instances:
vim_instances = %x[vim --serverlist].lines.map(&:strip)
cwd           = FileUtils.pwd

servername = vim_instances.find do |candidate|
  # Use --remote-expr to get the results of `getcwd()` from each of the Vims:
  candidate_wd = %x[vim --servername #{candidate} --remote-expr 'getcwd()'].strip

  # The one we're looking for should have a  current working directory that's
  # somewhere under the command's working directory:
  if candidate_wd.start_with?(cwd)
    candidate
  else
    nil
  end
end
```

The invocation to send commands is extractable, although I don't usually need the output. Here's what it might look like if we pulled it out to a function without capturing the output:

``` ruby
def send_to_vim(servername, command)
  system 'vim', '--servername', servername, '--remote-expr', command, out: '/dev/null'
end
```

This one is easier to manage in terms of escaping and quotes, too, since the `system` call takes care of quoting the individual arguments properly.

## Running the cargo command

The `cargo` tool is extensible in the same way `git` is: If you create a command in `$PATH` named `cargo-something`, it becomes available as `cargo something`. This means it's a good idea to handle both invocations at the start of the program:

``` ruby
if ARGV.first == 'vim'
  # then it was called as `cargo vim <command>` and not `cargo-vim <command>`,
  # so remove the "vim" part:
  ARGV.shift
end

if ARGV.count < 1
  STDERR.puts "USAGE: cargo vim <build|run|test> [args...]"
  exit 1
end
```

But once we have that, `ARGV` contains everything we need to run the *real* cargo command and get its output. It would be nice if I could just get the output of the previous command. I imagine myself running `cargo build` once, having it fail, and then just go "oh, let's just take this elsewhere", but I couldn't find a good way of doing this. Instead, re-running should be fast enough the second time around, this time into a file:

``` ruby
Tempfile.open('cargo-vim') do |f|
  print "Running cargo #{ARGV.join(' ')} ... "

  # The output from `cargo` goes in the standard error stream, so we want to
  # redirect that one to the temporary file. Stdout we don't care about much.
  result = system 'cargo', *ARGV, err: f, out: '/dev/null'

  puts "DONE"

  # ...
end
```

In the [real code](https://github.com/AndrewRadev/scripts/blob/c352c9e5bb42adb4435282e851ae4e98e319bfd0/bin/cargo-vim) I've also added some measurements and visual cues to get something slightly fancier:

```
% cargo vim build
Running cargo build ... DONE 123.23ms 🗸
% cargo vim build
Running cargo build ... DONE 348.68ms ❌
```

But the core of the code is rerunning the same command into a tempfile. That file's path can then be used to populate the quickfix list if the result is falsey:

``` ruby
Tempfile.open('cargo-vim') do |f|
  # ...

  if result
    # No errors, clear and close the quickfix list
    send_to_vim(servername, "setqflist([])")
    send_to_vim(servername, "execute('cclose')")
  else
    # There's errors, populate the quickfix list
    send_to_vim(servername, "execute('silent compiler cargo')")
    send_to_vim(servername, "execute('silent cfile #{f.path}')")
    send_to_vim(servername, "execute('silent copen')")
    exit 1
  end
end
```

Vim can handle cargo build output, because the [basic Rust configuration](https://github.com/rust-lang/rust.vim) has a "compiler" definition for it. Running `compiler cargo` is enough to tell Vim how to parse the output of the build process in a useful way. The built-in `cfile` command loads up the given file path into the quickfix window as an "error report".

The end result is a `cargo vim build` that produces something like this:

![Build output in the quickfix window](/images/cargo-quickfix.png)

## Was this really necessary?

You don't need any of this if you're fine with change your mental patterns a little bit. You can easily have the "compiler" setup in `~/.vim/ftplugin/rust.vim`:

``` vim
compiler cargo
set makeprg=cargo\ test
```

That way, if you get a build error, you could just switch to Vim and run the built-in `:make` command. It'll pretty much do the same thing.

It could be argued my `cargo vim` command is slightly more convenient in case you build up a more complicated command line, like if you invoke `cargo test --test test_markdown`, you can just tweak that invocation rather than running `:make` in Vim with arguments. Or there might be ENV vars that change the build process. Honestly, though, I just don't like having the "running" part in Vim due to some form of mental compartmentalization. You do you.

What this kind of separate script *would* be nice for for is pre-processing of the error output before sending it over to Vim's `compiler` setup. I might end up doing the same thing for RSpec, where importing test failures is trickier due to some tests being printed as `spec/test_name_spec.rb[1:2:3:4]`. That part at the end is an identifier for the test, based on where it is in the example hierarchy, and it's not possible to translate it *directly* into a file:line location. I've got a [proof-of-concept script](https://github.com/AndrewRadev/scripts/blob/c352c9e5bb42adb4435282e851ae4e98e319bfd0/bin/rspec-translate) that might give me that info to plug into a similar "send to Vim" tool. Plus, RSpec can record the last set of test failures in a file, so it might not even be necessary to re-run the suite.

Either way, no, none of this is "necessary", but it was a fun little exploration for me. And maybe you've learned a thing or two about Vim's quickfix list and its client-server interface.
