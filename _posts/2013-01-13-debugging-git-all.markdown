---
layout: post
title: "Debugging git-all"
date: 2013-01-13 16:16
comments: true
categories: haskell git
---

An interesting tool I discovered recently is
[git-all](http://hackage.haskell.org/package/git-all). It shows you the status
of all git repositories in the current directory that have changes or require
pushing. This is pretty useful with my "projects" directory -- I could have
forgotten to push some recent commits, or I might have started working on
something and need a reminder to finish it.

The program is written in haskell and I decided that it's small enough to use
for haskell practice. My original intention was to add support for colors, but
I found an odd bug that I ended up fixing instead. In the process, I learned
one or two interesting things, so I'd like to explain them for someone else's
benefit. If you have some haskell knowledge, but you're still in the "beginner"
category, you might find the small nuggets of information useful.

I'll start by covering several things about haskell I learned during the
process. After that, I'll describe the actual problem and how I managed to
solve it. Note that I'm very inexperienced in this area, so take my thoughts
with a grain of salt.

<!-- more -->

## Typeable

The
[Typeable](http://www.haskell.org/ghc/docs/6.12.1/html/libraries/base/Data-Typeable.html)
class is an interesting one, because it attempts to add some form of duck
typing to a statically-typed language. The main use case seems to be the `cast`
function. Here's an example:

``` haskell
import Data.Typeable

typeableTest :: (Typeable a) => a -> String
typeableTest subject =
  case (cast subject :: Maybe String) of
    Just s    -> s
    otherwise -> "Not a string"

main = do
  print $ typeableTest (3 :: Int)
  print $ typeableTest "foo"
```

The `typeableTest` function can accept any type `a` that has a `Typeable`
instance. In this example, you can call it both with an int or with a string
and it compiles and runs without a hitch. Note that I had to specify that `3`
is an int -- it seems like for these kind of checks, `cast` requires its
argument to have an unambigious type, so you can't rely on type inference.

If you need one of your own types to be `Typeable`, you can simply `derive Typeable`,
but you'd need the GHC extension `DeriveDataTypeable`. It would look something
like this:

``` haskell
{-# LANGUAGE DeriveDataTypeable #-}

import Data.Typeable

data RPS = Rock | Paper | Scissors
  deriving Typeable
```

As mentioned, I'm very inexperienced in haskell, but on a first glance, this
seems awfully opposed to the language's philosophy. I suppose in the hands of
elder haskell wizards, this could be a very powerful tool, but on the beginner
level, I'd avoid it, because it seems like it could cause a lot of issues.
You'll see one of those a bit further below.

## Strings

Haskell strings are an excellent playground to learn standard recursion
techniques. Since they're implemented as linked lists, you can easily
pattern-match on them and do simple things such as:

``` haskell
import Data.Char

ucfirst :: String -> String
ucfirst ""     = ""
ucfirst (c:cs) = (toUpper c):cs

main = do
  print $ ucfirst "foo"
  print $ ucfirst "Foo"
```

Unfortunately, this is also a huge problem. Exposing the way strings are built
internally leaves no room for replacing their implementation. With time, it's
become apparent that the default `String` type can cause performance issues, so
haskell has been moving towards different types like
[Data.Text](http://hackage.haskell.org/packages/archive/text/0.11.2.0/doc/html/Data-Text.html).
This kind of string can't really be pattern-matched, so the above program would
probably look something like this:

``` haskell
import Data.Char as C
import Data.Text as T

ucfirst :: Text -> Text
ucfirst t =
  case uncons t of
    Just (c, t') -> cons (C.toUpper c) t'
    Nothing      -> t

main = do
  print $ ucfirst (T.pack "foo")
  print $ ucfirst (T.pack "Foo")
```

This time, we have to `uncons` it manually to separate the first letter and the
remainder, which might also fail with `Nothing`, so we need to pattern-match
for `Maybe`. I'm not really sure if this is the recommended solution,
performance-wise, but this is the simplest I can come up with. It's not that
much more complicated than the `String` variant, but it does force you to go
through some more work.

An annoying problem is that you now have to `T.pack` every string you ever work
with. The solution to this is `OverloadedStrings`. With that language
extension, the code can now look like this:

``` haskell
{-# LANGUAGE OverloadedStrings #-}

import Data.Char as C
import Data.Text as T

ucfirst :: Text -> Text
ucfirst t = "You saw the implementation above"

main = do
  print $ ucfirst "foo"
  print $ ucfirst "Foo"
```

As you can see, we can just use `"foo"` as a string literal and it'll get
translated to a `Text` from the compiler, probably by replacing instances of
the literal to `fromString "foo"`. This also means that we can replace all
instances of `Text` with, say, `ByteString` and the code should still work.

## The Bug

Now for the actual problem I discovered. When you call `git-all`, it expects to
get an additional command, either `status` or `fetch`. If no command is given,
it defaults to `status`. Here's the relevant code:

``` haskell
mainArgs <- getArgs
opts     <- withArgs (if L.null mainArgs then ["status"] else mainArgs)
                     (cmdArgs gitAll)
```

Simply put, if there are no `mainArgs`, then just use `["status"]` as the
argument list instead.

However, if you consider this code carefully, the `["status"]` serves as a
replacement to the *entire* set of options given on the command line. If the
binary is invoked as, say `git-all -v`, then `mainArgs` is not empty, so the
default command is not set. Sure enough, this invocation causes the following
error:

    git-all: Prelude.tail: empty list
    git-all: thread blocked indefinitely in an MVar operation

A better way to handle the case of a missing command is in the `cmdArgs`
invocation, by using the `opt` function. The command is fetched from the
`arguments` variable defined like so:

``` haskell
gitAll = GitAll
    -- omitted for brevity ...
    { arguments = def &= args &= typ "fetch | status" } &=
    -- omitted for brevity ...
```

So, it should be enough to change the `arguments` line to this:

``` haskell
{ arguments = def &= args &= typ "fetch | status" &= opt "status" } &=
```

Surprisingly, this fails with the following error message:

    Unknown command: "status"

The message is easily trackable to this case statement:

``` haskell
case L.head (arguments opts) of
  "fetch"  ->
    -- do something

  "status" -> do
    -- do something else

  unknown  -> putStrM $ T.concat [ "Unknown command: ", T.pack unknown, "\n" ]
```

What's going on here? It seems like the command is `status`, just like it
should be, but the case statement that handles it doesn't work. Well, the
problem should be obvious from the given code above, but I only realized it
after adding some logging. The error message is `Unknown command: "status"`, but
notice that the code displaying the message doesn't wrap `status` in quotes.
What the `opt` function stores in the arguments turns out to be `"status"`, not
`status`. Here's the code of `opt` in the `cmdArgs` package:

``` haskell
opt :: (Show a, Typeable a) => a -> Ann
opt x = FlagOptional $ case cast x of
    Just y -> y
    _ -> show x
```

As you can see, the given argument doesn't need to be a `String`, and if it's
not, it's turned into one by using `show`. In this case, due to
`OverloadedStrings`, the string literal is actually a `Text`. And applying
`show` to a `Text` wraps it in quotes. The fix was simply using `T.unpack
"status"` to provide an actual `String` to the `opt` function.

## In Conclusion

In the end, the bug was easy to solve, but not very straightforward to debug.
Haskell's type system is one of its strongest points, but it can be somewhat
circumvented by using `Typeable`. To me, this looks like a tool to be used very
sparingly, since it has the potential to turn useful compile-time errors into
runtime errors. The issue was also partly caused by the string that's not
*actually* a `String`. I can't really deny that `OverloadedStrings` is a useful
extension, so I'd just be on the lookout for any potential misalignments
between the string types.
