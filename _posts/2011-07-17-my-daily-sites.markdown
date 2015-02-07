---
layout: post
title: "My Daily Sites"
date: 2011-07-17 13:48
comments: true
categories: projects
---

For a while now, I've been working on a little website to manage some sites I
visit regularly. I call it "Daily Sites" and it's at
[http://daily-sites.heroku.com](http://daily-sites.heroku.com/).
Since it works just fine for me and I got around to writing a small about page
for it, I thought it's finally time to show it to other people with the hope
that it might be useful for them as well.

<!-- more -->

The idea was taken from a firefox plugin, called
"[Morning Coffee](https://addons.mozilla.org/en-US/firefox/addon/morning-coffee/)".
It lets you mark a website for viewing on specific days of the week. After
that, you can simply click a button to open all sites for the day in tabs.

This website is exactly the same -- you can log in with twitter or facebook and
enter sites to view on a schedule. I built it because the plugin wasn't
compatible with Firefox 4 for a long while. These days, it works just fine, but
I still think my version is a bit more flexible -- for one thing, the site list
is inherently shared, so it's easy to use with several computers. It's quite a
bit slower, though (page load + login), and you need to log in every time, but
I'll see what I can do about that later on.

So why would you want to use this instead of a simple RSS feed? Well, there are
several use cases I can think of:

  - **Sites that update on a schedule.** Think webcomics. A lot of them update
    Mondays, Wednesdays, and Fridays, some have a different schedule. While
    it's probably still possible to view them through a feed, I've personally
    gotten pretty used to visiting them, so I prefer this option.

  - **Sites you visit every day.** Facebook, Twitter, LinkedIn, Github... An
    RSS feed is just not feasible for some of these due to the amount of
    content. There are various apps that collect the information, provide
    notifications, filter it by criteria and so on, but I happen to be OK with
    the web interfaces, so I just click through them every once in a while.

  - **Google searches.** Occasionally, I'd like to know when something is
    published, when there's a new episode, something like that (usually some
    anime). I might not have a subscription to a news source that could provide
    the information, but I can just google it once a week.

  - **Reminders.** There's a ton of todo lists out there, but I still haven't
    found one that does a good job for me. For the simple task of reminding
    yourself to visit a website every so often and do something there, this
    works just fine. I have [iKnow](http://iknow.jp) registered for checking
    every day, so I can remember to practice some Japanese. I put
    [Project Euler](http://projecteuler.net/index.php)
    on Sunday, so I can remember to try solving some of the problems. It's a
    nice way to keep track of such things.

There's no doubt that there are other ways you can achieve the same results.
Heck, you can even manage them as bookmarks yourself. Still, I think the site
turned out pretty useful, so if you think you might benefit from using it, go
ahead.

I'm aware that it's _very_ basic, especially the design. I've just used Ryan
Bates' excellent [scaffolding gems](https://github.com/ryanb/nifty-generators)
to get things going and I'm not a designer at all, so I think it works just
fine for now. I hope I'll get around to experimenting with that later on, but I
doubt it'll be soon. I'd be happy to hear opinions on how it can be improved.
The code is hosted on [github](https://github.com/AndrewRadev/daily-sites), so
you could also file issues on the bugtracker there.
