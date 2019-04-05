---
layout: post
title: "Driving Vim With Ruby and Cucumber"
date: 2011-11-15 19:26
comments: true
categories: [vim, ruby, testing]
published: true
---

One of the more exotic features of Vim is its remote control functionality.
Basically, if you invoke Vim with `--servername SOME_NAME`, you'll be able to
send commands to it with another Vim instance. Using this, I've recently
attempted to fix a common annoyance with vimscript -- its limited testability.
By spawning a remote instance and controlling it through ruby code, we can use
cucumber to perform simple integration testing for Vim plugins.

This is _not_ something I'd do for all code I write, but in some cases, it could
be a life-saver. My
[splitjoin](http://www.vim.org/scripts/script.php?script_id=3613) plugin is one
example of a project that I wish I had a good test suite on, considering the
amount of regressions I've had when modifying functionality. In this blog post,
I'll describe some ruby code to drive a Vim instance remotely and a few sample
cucumber steps you could write to make use of it.

<!-- more -->

## Client/server functionality

The first step is clarifying Vim's `+clientserver` functionality. The idea is
that you can spawn a "server" instance of Vim that can be used by other
instances.

``` bash
$ vim --servername VIMSERVER
```

After this Vim is started, we can open up another terminal and perform one of
three actions:

  - `vim --servername VIMSERVER --remote some_file_name` starts editing
    `some_file_name` in the server (and changes focus to it if the GUI is
    started).
  - `vim --servername VIMSERVER --remote-send 'some_key_sequence'` sends the
    given keys to the server as if they were typed by a user.
  - `vim --servername VIMSERVER --remote-expr 'VimExpression()'` evaluates the
    given vim expression on the server and returns the result. Note that a
    command is not an expression, but a function call or a variable is.

There are a few variations of these, like opening up a list of files in tabs or
not complaining if no instance was spawned. You can find those in the output of
`vim --help`. In the end, these three are going to have to be enough to control
Vim and inspect its output. Some additional vimscript will be required, but
this is enough to build on.

Another important runtime flag is `--serverlist`. This does what you'd think it
will, echoes the newline-separated list of all running servers. This is
necessary to check if Vim started successfully, or rather, to wait for it to be
good and ready before it can respond to remote commands.

It's good to note that if two Vims are started with the servername "FOO", the
second one would actually be named "FOO1". This means it may be a good idea to
generate the servername manually, either by inspecting the serverlist and
adapting, or by setting a random string as a name. For the examples here, I'll
just ignore the issue entirely and assume there's no other instance running.

## Vimrunner

The first step is to create some kind of an object that will encapsulate the
Vim instance. The first versions of this were built on top of a helper class
from spork's features,
[BackgroundJob](https://github.com/sporkrb/spork/blob/58959e176e4a310f3210af1062ac9e687b934647/features/support/background_job.rb).
Later, I managed to clear up a lot of the stream duplication and closing logic
by using `Process#spawn` ([docs](http://www.ruby-doc.org/core-1.9.3/Process.html#method-c-spawn)):

``` ruby
class Runner
  def self.start
    command = 'gvim -f --servername VIMRUNNER'
    pid     = spawn(command, [:in, :out, :err] => :close)

    new(pid)
  end

  def initialize(pid)
    @pid = pid
  end
end
```

Instead of a headless vim, the runner uses Gvim. This has the benefit of
letting us see what's going on and debug any issues that arise more easily.
And, well, I still haven't managed to get a proper headless vim instance
running...

Gvim needs to be started with the `-f` flag so it doesn't fork and kill its
original process. The standard streams of the child process are closed, because
we don't want them to mess up the parent's output in the terminal. The PID is
kept in an instance variable, so the process can be killed later. The `kill`
method is fairly simple as well:

``` ruby
def kill
  Process.kill('TERM', @pid)
  true
rescue Errno::ESRCH
  false
end
```

If the `@pid` corresponds to a running process, `Process#kill` will run without
a hitch. Otherwise, the specific exception is captured and `false` is returned,
so `kill` is safe to call regardless of the state of the Vim instance.

At this point, the `Runner` can only start Vim and kill it. The next step is
actually doing something interesting in the instance.

``` ruby
def type(keys)
  system('vim', '--servername', 'VIMRUNNER', '--remote-send', keys)
end
```

This is not very convenient to use in practice, but it does provide the ability
to do almost anything in the remotely controlled Vim. Here's an example irb
session:

``` ruby
vim = Runner.start
vim.type ':edit some_file_name<cr>'
vim.type 'iHello, World'
vim.type '<esc>:w<cr>'
vim.kill
```

As you may have guessed, this will edit a file called `some_file_name`, type
"Hello, World", and save. Instead of using `kill`, I could have also done
`vim.type '<c-\><c-n>ZZ'` in this case. The combination `<c-\><c-n>` brings Vim
into normal mode from any other one, which is quite useful for sending remote
commands.

For convenience's sake, I could add a method that does that for me:

``` ruby
def quit
  vim.type '<c-\><c-n>ZZ'
end
```

This is exactly how a simple DSL can be built for controlling Vim. The `type`
method can be used as a basis for other, more complicated ones. Here's an
implementation of `edit` and `write` methods:

``` ruby
def edit(filename)
  type "<c-\\><c-n>:edit #{filename}<cr>"
end

def write
  type '<c-\><c-n>:w<cr>'
end
```

Now that we have that, the above irb session can be simplified a bit:

``` ruby
vim = Runner.start
vim.edit 'some_file_name'
vim.type 'iHello, World'
vim.write
vim.kill
```

This should work just fine in the interactive console, but if you try to run it
as a script, it's probably going to fail. The reason is another problem that
would show up only in scripted interaction -- timing. When `vim.edit` is
executed, the vim instance is probably not started yet, which causes a problem
when the script attempts to connect to it. Here's a possible solution:

``` ruby
def wait_until_started
  serverlist = Runner.serverlist
  while serverlist.empty? or not serverlist.include? 'VIMRUNNER'
    sleep 0.1
    serverlist = Runner.serverlist
  end
end

def self.serverlist
  %x[vim --serverlist].strip.split "\n"
end
```

It's pretty hacky, but it's the best I managed to come up with. It goes through
the output of `vim --serverlist` looking for the started vim instance. If it
doesn't find it, it sleeps for 0.1 seconds and tries again.

The code does have another problem, though. A file is not actually written at
all. The reason is that the current `write` method simply sends a sequence of
keys. Since the code has no knowledge that it's sending a command, it doesn't
really care to wait until the command is done. That's why the vim instance is
killed before it manages to write the file (unless you were lucky with your
timing, that is).

So what could we do? The hacky solution is to simply ping the server again.

``` ruby
def write
  type '<c-\><c-n>:w<cr>'
  type '<c-\><c-n>'
end
```

Since Vim can't do two things at the same time, it'll finish writing the file
and then respond to the remote request. A better solution appears if we try to
solve a different problem.

If you tried to spec the `Runner` class, you'd notice it's a bit difficult to
pull off, since you won't really get any output from the runner's methods. As
noted before, Vim doesn't know what kind of keys you're sending, so it can't
respond in any way. The good news is that `--remote-expr` can be used to
evaluate some vimscript and return the result.

``` bash
$ vim --servername VIMRUNNER --remote-expr '&shiftwidth'
```

However, commands, the most basic building block of vimscript, are not
expressions. So, let's write some vimscript to execute a command and return its
output.

``` vim
function! VimrunnerEvaluateCommandOutput(command)
  redir => output
    silent exe a:command
  redir END

  return output
endfunction
```

The [:redir](http://vimdoc.sourceforge.net/htmldoc/various.html#:redir) command
is quite a useful one for scripting. It lets you execute a bunch of code and
store the output in a variable. This invocation won't really provide much
feedback in the case of problems, but it would at least return the correct
result if fed correct commands.

Loading the script in the server instance will require modifying the `start`
method a bit.


``` ruby
def self.start
  command = "gvim -f -u #{vimrc_path} --noplugin --servername VIMRUNNER"
  # ...
end

def self.vimrc_path
  File.expand_path('vimrc', File.dirname(__FILE__))
end
```

The `vimrc_path` method should return the path to the newly created vimrc file.
The `--noplugin` flag might not be necessary, but is a good idea to avoid
plugin issues. Adding some minimal configuration would also be a good idea:

``` vim
set nocompatible

filetype plugin on
filetype indent on
syntax on
```

So now, it's completely possible to define a `command` method that returns a
command's output and implement `write` and `edit` in terms of that.

``` ruby
def command(vim_command)
  expression = "VimrunnerEvaluateCommandOutput('#{vim_command.to_s}')"
  system('vim', '--servername', 'VIMRUNNER', '--remote-expr', expression).strip
end

def edit(filename)
  command "edit #{filename}"
end

def write
  command :write
end
```

There's no need for sending additional keystrokes now, because vim has to wait
until the commands are finished in order to return the output. This takes care
of that synchronization issue.

## Testing splitjoin with cucumber

Now, I'll take a look at a part of my
[splitjoin](https://github.com/AndrewRadev/splitjoin.vim) plugin and see how it
can be specified with a cucumber feature. Here's the scenario I came up with:

``` cucumber
Feature: CSS support

  Scenario: Splitting single-line style definitions
    Given Vim is running
    And the splitjoin plugin is loaded
    And I'm editing a file named "example.css" with the following contents:
      """
      h2 { font-size: 18px; font-weight: bold }
      """
    And the cursor is positioned on "h2"
    And "expandtab" is set
    And "shiftwidth" is set to "2"
    When I split the line
    And I save
    Then the file "example.css" should contain the following text:
      """
      h2 {
        font-size: 18px;
        font-weight: bold;
      }
      """
```

A few steps are straightforward to implement with what's currently defined in
the `Runner` class.

``` ruby
require './runner'

Given /^Vim is running$/ do
  @vim = Runner.start
end

Given /^I'm editing a file named "([^"]*)" with the following contents:$/ do |filename, text|
  File.open(filename, 'w') { |f| f.write(text) }
  @vim.edit filename
end

Then /^the file "([^"]*)" should contain the following text:$/ do |filename, text|
  File.exists?(filename).should be_true
  File.read(filename).should include text
end

When /^I save$/ do
  @vim.write
end
```

Since the code is creating temporary files, it's important to move into a
temporary directory while running the suite. It would also be useful to kill
the vim instance after each scenario, provided one is started.

``` ruby
require 'tmpdir'

Before do
  @tmpdir = Dir.mktmpdir
  @original_dir = FileUtils.getwd
  FileUtils.cd @tmpdir
end

After do
  FileUtils.cd @original_dir
  @vim.kill if @vim
end
```

The remaining steps require some more tinkering with the runner. Loading a
plugin is one thing that might seem a bit daunting at first. Turns out, it's
not that difficult at all once we have the `command` method.

``` ruby
Given /^the splitjoin plugin is loaded$/ do
  plugin_dir = File.expand_path('../../..', __FILE__) # or whatever is necessary
  @vim.add_plugin plugin_dir, 'plugin/splitjoin.vim'
end
```

``` ruby
def add_plugin(dir, entry_script)
  command("set runtimepath+=#{dir}")
  command("runtime #{entry_script}")
end
```

The first parameter to `add_plugin` is the plugin directory, and the other is
the main entry point. The directory is simply added to the server's runtimepath
and its plugin file is `runtime`'d, which has the effect of loading it just as
if we'd placed it in the system's vimfiles.

Positioning the cursor at some specific text in the buffer is quite simple
through `type` and the standard vim search. We could also implement a method to
call functions, but for now, this will do just fine:

``` ruby
Given /^the cursor is positioned on "([^"]*)"$/ do |text|
  @vim.search text
end
```

``` ruby
def search(text)
  type "<c-\\><c-n>/#{text}<cr>"
end
```

The steps that deal with settings can easily go through `command`, but let's
implement another method to abstract this away.

``` ruby
Given /^"([^"]*)" is set$/ do |boolean_setting|
  @vim.set boolean_setting
end

Given /^"([^"]*)" is set to "([^"]*)"$/ do |setting, value|
  @vim.set setting, value
end
```

``` ruby
def set(setting, value = nil)
  if value
    command "set #{setting}=#{value}"
  else
    command "set #{setting}"
  end
end
```

The only thing left is the line splitting step. Since the plugin is already
loaded, there's not much to it:

``` ruby
When /^I split the line$/ do
  @vim.command 'SplitjoinSplit'
end
```

The whole thing is fairly verbose, although a few steps can certainly be
extracted to a `Background` clause. While this plugin has a very specific use
case, provided a reasonable DSL is built for accessing the Vim instance,
writing the actual steps shouldn't be terribly difficult.

## Summary

Writing huge feature files is probably not going to be very efficient for most
pieces of vimscript. Not to mention that there are a lot of plugins that I
can't begin to image how to test in this fashion (rails.vim is one thing that
comes to mind). Even so, having a simple ruby DSL to manage Vim can help in
some cases, and it's definitely a fun project to play around with.

The code is hosted on github under the name of
[vimrunner](https://github.com/AndrewRadev/vimrunner), and I still intend to
work on it in the future. I've also published it on rubygems, so a `gem install vimrunner`
would give you a `vimrunner` executable to play around with. Some cucumber
steps can be found on github as well as
[cucumber-vimscript](https://github.com/AndrewRadev/cucumber-vimscript). I'm
going to try to use it for some of the new code I write to experiment with how
much is possible and I'd appreciate any feedback on it from someone else
attempting to use it in the field.
