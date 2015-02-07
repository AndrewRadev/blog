---
layout: post
title: 'Thoughts on "Half a Model"'
date: 2013-04-28 11:37
comments: true
categories: ruby rails
published: true
---

In ActiveRecord, you can use the `select` method to run the underlying database
query with a `SELECT` for particular fields. As a result, the object simply
doesn't have the rest of its attributes. Depending on the particular table and
the use case, this could speed things up. Even without the performance
argument, the idea to "get only the things you need" seems perfectly
reasonable. This has never quite clicked with me, and I recently realized why.
I've never encountered the problem viewed from this angle, so I figure it might
be worth sharing.

<!-- more -->

Imagine you have a `Product` model. It has a name, a description, a price,
translations. It is connected to a shop, a user, shipping information. In time,
as you work with it, you create a mental model of it, what its API is, what you
can do with it. You know what a "product" is, but the issue is, you don't know
what "half a product" is. If you only select half of its attributes, you can no
longer recognize this object, you can't work with it unless you go back to the
place you've built it and figure it out. This makes it much more difficult to
build up a mental model of the code. If you often do `select`s, you have to get
into the mindset that every method call in the view requires a double-check
with the fetching code in the controller. A simple performance improvement
turns out to have a very disproportionate mental penalty.

For a practical example, imagine a helper method invocation, like
`product_summary(product)`, which gives you a short, formatted summary of the
product information, suitable for reuse. If you only `select` particular fields
in different controllers, this helper may or may not work depending on what
subset of data the `product` object currently has available.

Now, I'm not suggesting you never do this. Web development existed before ORMs
and there are still people who prefer tighter database integration that an ORM
could provide. It's simply a tradeoff. An object that represents the dataset
gives you a solid mental model to rely on, but it comes at the price that you
now need the full data row for it to be relevant. One possible compromise I see
is to create a new type of object. For instance, `ProductDescription` and
`ProductImage` that work on well-defined subsets of the data. That way, you
might be able to maintain a good mental model of the data layer at the cost of
many more one-shot classes. I can't really say how good this would work in
practice. Naming could easily turn out to be an issue, and boilerplate code may
be needed to fit the pieces together. Still, I'd say it's worth a try if
`select`-ing is a viable performance improvement.
