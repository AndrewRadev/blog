---
layout: post
title: "Code Alignment"
date: 2016-11-13 14:30
comments: true
categories: rules
published: true
---

Okay, this is going to be a bit bikesheddy. It's about a code style rule that some people love and some people hate, and I have an *&#10024;opinion&#10024;* about. It's not a particularly strong opinion, as in, if the team I'm working with disagrees with me, I have no issue following the popular vote. It's a small enough thing that it might not matter in the long term.

Let's start by examining some code:

<!-- more -->

``` ruby
describe Registration do
  it "disallows duplicates" do
    create(:registration, uid: '123', provider: 'twitter')

    first  = build(:registration, provider: 'twitter',  uid: '123')
    second = build(:registration, provider: 'twitter',  uid: '234')
    third  = build(:registration, provider: 'facebook', uid: '123')

    expect(first).not_to be_valid

    expect(second).to be_valid
    expect(third).to be_valid
  end
end
```

The three variables, `first`, `second`, and `third`, are aligned by the `=` sign, and the method invocations on the right are aligned by commas. Here are the benefits I see with this:

- On the left side, you can easily scan variable names. If the body of the code that uses these variables is complicated, you can index it visually -- you look at the variable on the left side, you check what you have on the right. It's *very* rare that I read variable names like normal text -- left-to-right, top-to-bottom. I just scan them quickly and then consult the "index" as I'm reading the body of the code.

- On the right side, we have some very homogeneous invocations of the `build` method. The thing we're interested in the most are the *differences* between them (what is the `provider`, what is the `uid`?) and when they're ordered like this, it's easy to see them at a glance.

This might not be too obvious in a short piece of code, but with larger chunks of text, it gets more and more useful. Arguably, you don't want to end up with large chunks of code, but it depends. For instance:

``` scss
$icon-arrow-thick-right: "\e600";
$icon-arrow-thick-left: "\e601";
$icon-arrow-thick-up: "\e602";
$icon-arrow-thick-down: "\e603";
$icon-arrow-thick-b-right: "\e604";
$icon-arrow-thick-b-up: "\e605";
$icon-arrow-thick-b-left: "\e606";
$icon-arrow-thick-b-down: "\e607";
$icon-arrow-thin-right: "\e608";
$icon-arrow-thin-up: "\e609";
$icon-arrow-thin-left: "\e60a";
```

... and another 400 lines of the same. Compare to:

``` scss
$icon-arrow-thick-right:   "\e600";
$icon-arrow-thick-left:    "\e601";
$icon-arrow-thick-up:      "\e602";
$icon-arrow-thick-down:    "\e603";
$icon-arrow-thick-b-right: "\e604";
$icon-arrow-thick-b-up:    "\e605";
$icon-arrow-thick-b-left:  "\e606";
$icon-arrow-thick-b-down:  "\e607";
$icon-arrow-thin-right:    "\e608";
$icon-arrow-thin-up:       "\e609";
$icon-arrow-thin-left:     "\e60a";
```

This isn't exactly "code" -- it's a table of contents of sorts. As such, it's super useful to have it aligned. Just imagine a book where the index is described without alignment and how annoying it would be to orient yourself by pages/chapters. Again, on the left side you have an easily-scannable list, on the right, you have some very homogeneous content where you can easily notice the differences between lines (so you can filter the similarities out).

CSS declarations are an interesting counter-example. You rarely want to scan "labels" on the left side. The fact that one CSS selector uses `margin` and `padding` isn't as important as the values of those fields. And on the right side, you can have some very heterogenous content -- pixels, pairs of numbers, quadruplets of numbers, text:

``` css
.something {
  margin-top: 20px;
  padding: 0 20px;
  text-align: right;
}
```

Probably not much value in aligning it. There are some exceptions, like:

``` css
dl {
  -webkit-margin-before: 4px;
  -webkit-margin-after:  4px;
          margin-before: 4px;
          margin-after:  4px;
}
```

But this one can be hard to maintain automatically. I might do it if it's isolated in a mixin, simply because it would be read far more often that it would be updated.

## Drawbacks

Code like this can be more difficult to edit. You need to have an editor tool to help you (like [this](https://github.com/vim-scripts/Align), or [this](https://github.com/godlygeek/tabular), or [this](https://github.com/junegunn/vim-easy-align)), and I think many people don't, and align the code manually. Which doesn't seem like a great idea. I don't feel it's worth enough to waste energy on it if your editor doesn't have the tooling to do it easily.

Then there's the issue with VCS logs. Every alignment change due to a new item means touching a lot of other items. Mind you, with `git diff`, there's the `-b`/`--ignore-space-change` flag, so it might not be a huge problem in practice.

Another potential problem is large differences in lengths. For instance:

``` ruby
one                          = 1
two                          = 2
three                        = 3
forty_two_hundred_and_twenty = 4220
```

It's now significantly harder to make the connection between `one` and `1`, because they're quite far away from each other. My solution in situations like this is simple:

``` ruby
one   = 1
two   = 2
three = 3

forty_two_hundred_and_twenty = 4220
thirty_five_thousand         = 35_000
```

You might want to ask yourself why some variables are a single word, and others are an entire phrase. I find this kind of inconsistency to the amount of detail can hurt comprehension quite a lot. Maybe there's a name you could introduce for a new concept? It's not a "solution" to the alignment problem, all I'm saying is, it might be a minor smell to think about.

I've also heard the argument that search-and-replace might end up being harder. I'm not convinced it's a big issue, to be honest. Instead of looking for `foobar =`, you'd have to look for `foobar\s\+=`. It's rare that only this one pattern will be enough to get things done anyway, and it's very likely you'll need manual intervention whatever set of patterns and replacements you come up with.

## Is it worth it?

Depends. When you have a bunch of data with entries that have a very similar structure, I'd certainly want it to be aligned. Think the SCSS example above, or a database schema, or something like this:

``` javascript
payment_plans_for_select_box = [
  {label: 'Free',           value: 'free'},
  {label: 'Business',       value: 'business'},
  {label: 'Premium',        value: 'premium'},
  {label: 'SuperMega Plan', value: 'super_mega'},
]
```

I'd also go for it in the testing case, where you often have a setup phase with several invocations of the same functions with different parameters. For anything else, it depends, and it seems like mostly personal preference. The "similar enough structure" idea is my key guiding point, in all cases.

It's tricky to apply, because it's very contextual. How much is "similar enough"? Difficult to say. And it's definitely not something that an automated tool can determine (at this time). It's one of the reasons I dislike `gofmt`, it removes any alignment even when there would be a very noticeable benefit from it.

Either way, whether you decide to apply this rule or not, it's a good idea to know *why*, in more concrete terms than "it feels right/wrong". I hope I've given you a possible answer to this question.
