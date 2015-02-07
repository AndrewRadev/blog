---
layout: post
title: "Small Refactorings"
date: 2014-04-29 20:46
comments: true
categories: ruby rails
published: true
---

A common piece of advice for dealing with bad rails code is to avoid making huge rewrites all at once. Instead, make small fixes whenever you see a problem. An often-cited variant of this is the "boyscout rule" -- leave the code better than you found it.

This is solid advice. Putting hacks and workarounds would only make things worse. Rewriting swaths of code for even small features would take a long amount of time and introduce risk. The best approach is to make small refactorings and build new features with new, better, code.

As with most good advice, this can still backfire. Ever seen an app with five different caching mechanisms and seven different event tracking approaches, all slightly different? This may have been a result of multiple developers going "this is horrible, I'll fix it". In the end, they created an even larger mess, despite their good intentions. How did this happen?

<!-- more -->

Let's start with a different question.

## What is a "good" refactoring?

In the ruby community, we care a lot about good code. We have blog posts, conference talks, and many books on the topic. The community still gets a lot of newcomers and we try to educate them on the importance of structured, well-tested code.

Unfortunately, even if you took two experienced rails developers and put them in front of bad code, they'd probably disagree on the solution.

- Some would follow The Rails Way, trusting themselves to the framework and its well-structured conventions, others would insist on extracting the logic in service objects, separate engines, or microservices.
- Some would partition the code into many extremely small classes, others would call this "overcomplicating" and opt for a more coarse approach.
- Some would aggressively monitor and improve the performance of the app, others would scoff at the idea, claiming it's a problem to be solved at a later time.

If you've identified with one half of the statements, I'm willing to bet there are rails developers out there that take the exact opposite stances and still create well-working apps. As much as we wish there was only one good way of doing things, that doesn't seem to be the case. Much of our decisions stem not from reason, but from our backgrounds, previous languages, what worked for us and what didn't. This becomes a particular problem in larger teams working on separate parts of the application.

## Good developers doing bad things

Note that I'm still talking about "good" developers. By "good" in this case, I mean they genuinely believe in writing readable, maintainable code, they have good intentions and try to follow basic programming principles. Still, it's not surprising for them to end up with a mess, especially when working with legacy code.

### Unfinished business

Let's look at a more concrete use case. A developer needs to make a change to existing functionality in the big old legacy app. The logic ends up being in one 300-line method call that mutates global variables, accesses information from constants set in initializers and responds to three optional boolean flags that contain double negatives in their usage (`dont_add_extra_taxes: false`). The developer shudders in horror, and decides to get rid of this monstrosity, so they create a brand new class for the changed functionality, and use that one instead.

This is the best solution at this point in time. Adding even more hacks to this large method is a terrible option. And rewriting it would require finding all the ways it's being used and thinking of a good way to reimplement them. Which would take a long time and hold considerable risk of errors. It's much better to get the immediate work out of the way and then find some time to take care of the rest of the refactoring.

The problem is, there are now two implementations of logic that's only slightly different. The old method still exists. Even if the developer says they'll "fix it later", that "later" might never arrive. Depending on the development processes and company culture, it could be difficult to allocate time for this kind of refactoring. Especially since it doesn't seem to hold any value -- the functionality is there and it works, right? There's no immediate rush. As a result, that developer might even leave the company before the time they get around to it. I've seen quite a few cases of code that was clearly meant to be part of a larger refactoring... By people no longer working there. Heck, I'm guilty of being that person myself.

### So many people

Still, I said we're talking about a big team, right? There's lots of good developers in this imaginary company we're looking at. Wouldn't somebody else pick up the torch and finish the cleanup? They will, if they know about it and agree with it. If another developer has to make a change that ends up in that same terrible method, it's not clear whether they'll find the previous one's attempt to reimplement it. Even if they do, it's unlikely they'll adapt this solution to fit their different use case, since that may involve quite some work as well. Not to mention what I previously talked about: different developers have different ideas of "good code". They may even find the rewrite attempt and decide it's not really that good and they can do a better job.

In any case, it's easy to repeat the previous process: Just create a new class that handles this use case.

In the end, everybody that touches that code ends up reimplementing a small part of it, but without a coherent vision of where it should end up, we're left with a lot of subtle duplication and the original code keeps chugging along untouched.

### Limited scope

Consistency is key here. When we work on a particular feature, it's easy to get tunnel vision and see everything in light of this one particular use case. Looking at the original code and all of its quirks, it's really easy to dismiss them as irrelevant. And, for the limited scope we need it for, that may be true. But the `dont_add_extra_taxes` option was created because of some particular feature. Understanding all those features is the only way towards really rewriting the code.

This could, and should, happen gradually, since it would be practically impossible to figure it all out without trial and error. It often ends up, however, that "gradually" means "write this one use case and then drop it". Continuing to reimplement everything may require re-rewriting the new code, or even deleting it and starting over. This is difficult to do, especially when it doesn't feel like that work is needed at the time. When you repeat this process for multiple developers, all of them working on the code at different times and in different contexts, it's no surprise that the end result is an incoherent mess.

### Company culture

As a result of all of the above, some teams even end up being paranoid of "refactoring" (in quotes). When too many developers have tried to refactor the code and either broke production or made things worse in the long run, the atmosphere deteriorates. It gets more and more difficult to refactor and it often has to be done quickly and sloppily between tasks. This itself leads to more problems, which closes the downward spiral.

This is a difficult environment. A nice blog post that tackles the topic is ["Refactoring: The Human Factor"](http://andrzejonsoftware.blogspot.de/2014/01/refactoring-human-factor.html) by Andrzej Krzywda.

## Solutions

So if small, gradual refactorings end up causing all these problems, which path should we take instead? Keep hacking up the old method, making it larger and even more complex? Stop working on features and devote a week or two for a complete rewrite of this one method?

Both of these sound ridiculous, and for good reason. Small refactorings are still our best tool to deal with these situations. I'd say we only need to be aware of the limitations of the approach and figure out how to mitigate them.

### Planning

One of the simplest things you can do, before jumping into refactoring, is **think**. Our first instinct can often be wrong and inconsistent with the rest of the app. Once we've started down some particular path, it's difficult to turn around and make different choices, so we often push forward, making things somehow fit in a kludgy way.

It would be best to avoid this from the very beginning. Think about the effect of the refactoring and how it's going to fit with the system. Consider what new abstractions have to be created and how these will affect the architecture. Make drawings, random notes, mind maps, but get a good, clear picture of where you're going before heading out.

Even so, it's almost certain you'll make mistakes. Be prepared to adjust your vision and iterate on the refactoring multiple times. The fact that it's new code doesn't automatically make it good, especially if it's introducing new structure that may or may not work well with the existing one.

### Communication

Another somewhat obvious way to avoid all these issues is to have a good, clear line of communication between developers. If you're going deep into the bowels of bad code, it pays off to ask around for help. Maybe someone has already been there and started working on a replacement. If you can take that and extend it, or build something else with a consistent interface, you're on the right track towards finally getting rid of the big bad method.

This can be hard to do, but if your team has no shared understanding of features, you'll end up having trouble sooner or later. Share knowledge in standups, pair with people on tricky problems, ask for advice. Do your best to spread the knowledge around and it'll pay off pretty soon.

### Patience

Rash behaviour is especially common in newbie developers, possibly just out of university. They often attempt to apply their fresh knowledge to fix the codebase without taking the time to understand it well enough. Patience is key. It's important not to go overboard with cleanup while you're still unfamiliar with the code, unless it's a simple fix or you're pairing with another team member.

Of course, it's also important not to wait **too long**. When you stare into the heart of legacy code, the legacy code stares back. Even if the convoluted logic was written this way for a good reason, that doesn't make it good code. Understand what it does, then figure out how to replicate the functionality in a better way.

### Persistence

The final trick is to persist. With rails apps, it's usually not that difficult to understand any given piece of functionality. You can use a pen and paper to chart the interactions, you can put debug statements in strategic places, but eventually, if you persist, you'll figure out what the code does and how it does it (and feel very clever as a result). The trick is finding the time and energy to do so.

Only several times in my career have I had the opportunity to really sit down and devote some undisturbed time to understand a large piece of code and rewrite it. These moments are rare and usually happen for odd reasons, but when they do, be sure to make good use of them. Otherwise, you could timebox yourself to, say, half an hour every day of trying to understand this one method. Put comments in it, describing what you know of it so far, or just write them down on paper. Build hypotheses, validate or reject them. With patience, you'll eventually get to know every dark corner and you can then figure out an architecture that implements the same features in a better way.

It's not easy, but you have to pull the trigger at some point. You can skirt around on the edges of the method, you can wrap the old code in a new interface, but it will never really be gone until you dig deep into it and figure it out. By all means, finish your feature in a separate class first, get that out of the way and move the ticket to "Done". But be sure to create a "Delete bad code" ticket and genuinely make the act of deletion a goal, in your head. Only when you meet that goal can you really pat yourself on the back for doing an excellent refactoring job.

## Conclusion

One of the best ways to get rid of legacy code is to make small improvements. New features or changes should not be done in the old code, but should be created in new classes, with clean interfaces.

However, this process relies on the assumption that you will eventually **delete** or **fix** the old code. Failing to do that is going to leave you with an ever-expanding app with no prospects of real improvement. It also doesn't absolve you from thinking about the **architecture** of the new code and **communicating** with your teammates. Creating new components without a clear vision and without adapting them when needed only leads to more chaos.

For a nice parable that tackles a similar topic, take a look at [The Codeless Code](http://thecodelesscode.com/case/123).
