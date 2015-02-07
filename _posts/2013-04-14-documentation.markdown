---
layout: post
title: "Documentation"
date: 2013-04-14 17:31
comments: true
categories: talks documentation
published: true
---

I recently participated in RogueConf, a small Bulgarian conference. I talked
about documentation, how and when to write it, how to write tools to help you
out. The video is [on youtube](http://youtu.be/0aZ0LRxuq_I), and the slides are
[on speakerdeck](https://speakerdeck.com/andrewradev/dokumientatsiia-rogueconf-2013),
though it's all in Bulgarian. This post is the TL;DR of the talk. I'm going to
run through my main points, skipping over the demos and most of the examples.
Eventually, I'll extract some simple documentation tools from work in the
[dawanda/doctools](https://github.com/dawanda/doctools) repository, but there
is still some effort needed to make them generally usable, I'm afraid.

<!-- more -->

Documentation is a great thing. I doubt you'll find a Linux power user who
doesn't appreciate manpages, for instance. Github READMEs, wikis, Vim's
`:help`, it's all examples of great documentation that we couldn't do without.
And yet we also run into stuff like this:

``` ruby
# returns true
def public?
  return true
end
```

Or, even worse, like this:

``` ruby
# returns true
def public?
  return false
end
```

The problems I see here are that the documentation:

- repeats the code without providing any benefit
- is not maintained when code changes

One simple way to solve these issues is to do away with docs altogether, but
put in extra effort to maintain a high level of code readability. The idea is
that **readable code** is better than **unreadable code with documentation**.
This is an excellent rule that could save the day in a lot of cases. Two
instances I see that this breaks down in are legacy code and highly
domain-specific code.

With legacy code, you may have a complicated, 700-line method that interacts
with all kinds of shared state. If you've spent 3 hours figuring out how it
works, you might not have the time and energy to refactor it. It might even
take days of planned, step-by-step refactoring. In this case, I'd argue that a
couple of comments that explain what you've understood would be immensely
helpful to the next poor soul that turns up there. In other words, **unreadable
code with documentation** is still better than **unreadable code without
documentation**.

As for the second case, consider code that implements a mathematical algorithm.
If such code follows equations closely, variable naming will probably consist
of one-letter variables, breaking a bunch of readability rules. However, if you
know the algorithm, you'll be able to understand the code easily, and if you
don't, it's highly unlikely that variable naming will explain it. A short
description of the algorithm and a link to a longer article would probably do
much more towards that goal.

Domain knowledge is important. A mathematical algorithm is hard to understand
when we don't grok the domain, but that's the case for pretty much all
programming problems. The goal of documentation is not so much to explain how
the code works, but to describe how it reifies the domain. A couple of short
paragraphs in a README that provide a high-level overview of the problem domain
would be an excellent start to that. Even better, they could provide pointers
to code entities that implement the various pieces of functionality.

One thing I see as a consequence is that there's more value in documenting
classes and modules than methods and functions. A programming module's purpose
is part of the domain logic, and it's not very likely to quickly and radically
change during the project. On the other hand, method calls are much more likely
to be in flux, changing to accomodate the interactions between objects better.
This likelihood of change raises the probability of the documentation going out
of date. And wrong documentation is worse than no documentation.

In that line of thoughts, it's also important to make writing documentation as
easy as possible so it's more likely that developers would maintain it. For
instance, a lot of API-doc tools generate links to other symbols in the code if
they're annotated in a special way. Cross-referencing makes it easy for code
writers to structure the documentation in a readable fashion. Another example
would be automatically generating graphs of the code that explain entities and
their relationships -- they're easy to write, and have the potential to provide
a lot of value.

A word on automatic generation. To me, it's important not to go overboard.
Generating a full graph of all entities in the project and how they interact
can be overwhelming. Too much information can impair the readability of the
graph a lot. I would rather have developers provide a manual list of entities
and relations that are relevant for the feature they're describing. This would
require some manual effort, but would also provide much more control over the
communicated information.

It's important to make documentation easy to write, but it's just as important
to make it easy to read. A webpage with nice links to sections is a given. One
other potentially good idea would be to provide a command-line tool that gives
the information in a CLI-friendly form. Webpages are great for extended reads,
but sometimes you just need a quick reference, and using a command-line tool to
dump it in your terminal (or in your Vim) can be much more comfortable.

Is it worth it though? If you're three people on a monolithic rails app in the
beginnings of a startup, it probably isn't. You'll know all the code that other
people have written, you can afford to have full visibility on the changes, you
understand all of the domain logic involved. In fact, it will likely slow you
down and change too much for it to have any value whatsoever. With a larger
project, lack of documentation can hurt a lot. This is of particular importance
for a service-oriented architecture, where the individual components need
well-defined and well-understood endpoints.

And if there is value in documenting the project, there is a lot of value in
writing tools and building workflows to make that process as easy as possible.
It should never consume a huge part of developers' time, but in my experience,
a couple of hours per week are enough to build simple tools to help you out. A
slow morning is all that it takes to start tinkering with Graphviz and some
regexes and come up with a tool that generates relationship graphs out of
simple descriptions.

In the end, I believe it's a matter of habit, both documentation and tooling.
If we decide they are important to our work, it's only a matter of exercising
some willpower to build these habits, the same way we craft good commit
messages, write unit tests and refactor our code.
