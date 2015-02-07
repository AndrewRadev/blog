---
layout: post
title: "Grouped Select Helper Methods in Rails"
date: 2011-05-25 23:08
comments: true
categories: rails
---

I've always thought generating select tags was a bit odd in Rails. There are
various choices and it might be difficult to decide which to use in a specific
situation. A popular article on the topic is this one:
[Select helper methods in Ruby on Rails](http://shiningthrough.co.uk/Select-helper-methods-in-Ruby-on-Rails).
It's pretty old (2007), but still relevant. I'll go through the helpers in that
post quickly:

  - `collection_select`: Mostly used for model-backed data, invoked with all
    the method names it needs to build up the select box.
  - `select_tag`: A lot simpler, requires the option tags as a string, which
    usually needs to be delegated to another helper.
  - `select`: Used with a hash of names and values or with a list of pairs.
    This means that you can use it for any kind of data, including one from a
    model, but you need to prepare it first.

What the article doesn't cover, though, is the grouped select helpers. They're
used when you need to categorize the data with optgroup tags. There's info on
the Net here and there, but I'll try to give a quick run-down on how and when
to use them. I'll be using the `FormBuilder` variants of the helpers, but I'll
also give an example later on for non-resource forms.

<!-- more -->

## Grouping collections and their children

To create a selection box from a collection, you can use
`grouped_collection_select`. As you might have guessed, it's very similar to
`collection_select`, except it receives a few additional parameters. I'll
borrow an example straight from the
[rails docs](http://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html#method-i-grouped_collection_select):

``` ruby
class Continent < ActiveRecord::Base
  has_many :countries
  # attribs: id, name
end

class Country < ActiveRecord::Base
  belongs_to :continent
  # attribs: id, name, continent_id
end

class City < ActiveRecord::Base
  belongs_to :country
  # attribs: id, name, country_id
end
```

Now, if we want to display a form to set a city's country, and group the
options by continent, we could do this:

``` erb
<%= form_for @city do |f| %>
  <%= f.grouped_collection_select :country_id,
    @continents, :countries, :name,
    :id, :name
  %>
<% end %>
```

As you can see, it's a pretty long method call, but there's nothing really complicated going on:

  - `:country_id` is the field we're assigning to
  - `@continents` is the parent collection
  - `:countries` is the method we're calling on each continent to retrieve the records for the `<option>` tags
  - `:name` is the method that will be used for displaying each continent
  - `:id` and `:name` are the key and value methods for each country

I'm quite sure I'll never be able to use this method without looking it up, but
it does a good job for a simple case. A close relative,
`option_groups_from_collection_for_select` might be a bit more useful in
practice, but more on that a bit later.

## More generic select tags with select_tag

Drop-downs are pretty useful for displaying various choices on the user
interface. The `grouped_collection_select` helper is meant to be used
specifically with model properties, so it might not be immediately obvious how
to create generic selects. The helper in this case is `select_tag`:

``` erb
<% languages = ['English', 'Bulgarian'] %>
<%= select_tag :language, options_for_select(languages) %>
```

As noted at the start of the post, this one is the simplest one of the bunch.
Its second argument is just a string containing all option tags as HTML. If we
want to get a grouped select, we need to change the structure and the helper
we're using:

``` erb
<% cities = {
  'USA'      => ['Washington', 'New York'],
  'Bulgaria' => ['Sofia', 'Svishtov']
} %>
<%= select_tag :city, grouped_options_for_select(cities) %>
```

You can also use `options_from_collection_for_select` or
`option_groups_from_collection_for_select` to generate option tags in the same
way as the collection select helpers. It gets a bit long-winded, but I really
can't think of shorter names myself. The important thing is that this set of
helpers has the same feature set as the `FormBuilder` ones, albeit with a
slightly different API.

## Note: A small inconsistency

Ordinarily, when using a resource form with `form_for`, the helper methods have
the same names as standalone form helpers, except the suffix "_tag" is removed.
For example, these two forms are mostly equivalent:

``` erb
<%= form_for @post do |f| %>
  <%= f.text_field :title %>
  <%= f.text_area :body %>
  <%= f.submit %>
<% end %>

<%= form_tag :url => new_post_path do %>
  <%= text_field_tag 'post[title]' %>
  <%= text_area_tag 'post[body]' %>
  <%= submit_tag %>
<% end %>
```

So, the usual convention is that standalone helpers have similar `FormBuilder`
ones, whose names lack the "_tag" suffix. The select helpers break that
pattern: `select_tag` doesn't have a `FormBuilder` equivalent. Instead,
`FormBuilder#select` mimics the behavior of the `select` helper:

``` erb
<%= form_for @post do |f| %>
  <%= f.select      :category_id, Category.all %>
  <%= select :post, :category_id, Category.all %>
<% end %>
```

It's a bit surprising, but I think that's the only helper that doesn't follow
the convention, so it's just something to take note of.

## Grouping models by characteristics

While we can use `grouped_collection_select` for model relationships, this
doesn't help us if we want to group models by the value of some attribute.
Let's take this for an example:

``` ruby
class Category < ActiveRecord::Base
  has_many :posts
  # attribs: name, active
end

class Post < ActiveRecord::Base
  belongs_to :category
  # attribs: title, category_id
end
```

We want to display a selection box for a post's category and group the
available ones based on whether they're active or not. First of all, let's
generate the grouping as a data structure:

``` ruby
class Post < ActiveRecord::Base
  def self.for_select
    {
      'active'   => where(:active => true).map { |p| [p.id, p.name] },
      'inactive' => where(:active => false).map { |p| [p.id, p.name] }
    }
  end
end
```

It's not the most efficient way to do this, but it should be easy to
understand. Basically, the keys are the labels to display in the optgroups and
the values are collections of key/value pairs to use for the option tags.
Obviously, you could put this code anywhere you like. To me, it seems sensible
to keep it tucked in the model, since it's just a data structure, but you might
consider it specific enough to be put in a helper in the view layer, for
example.

Now, to get the actual select box, you could use `select_tag` with the
appropriate option helper:

``` erb
<%= form_for @post do |f| %>
  <%= select_tag 'post[category_id]', grouped_options_for_select(Post.for_select) %>
<% end %>
```

A very nice bonus with this approach is that the grouping can easily be changed
by modifying the behavior of `Post::for_select`. If you'd like the groups to be
called "enabled" and "disabled" instead, you just have to modify that method
instead of hunting it down in the view layer. You can even remove grouping
altogether and use `Post.all` instead, although that would require changing the
option helper.

Unfortunately, `select_tag` is great for the general case, but not very well
suited for model forms. You need to specify the `name` attribute yourself, as
`post[category_id]`, which might be a problem if you decide to rename your
model or use inheritance. It would be much nicer if we could use something like
the `select` helper. The problem is, you currently can't -- `select` only works
with flat collections and there's no such thing as a `grouped_select`. However,
interestingly enough, you <em>can</em> use `select` with a string:

``` erb
<%= form_for @post do |f| %>
  <%= f.select :category_id, grouped_options_for_select(Post.for_select) %>
<% end %>
```

The `grouped_options_for_select` helper generates the option tags in a string,
and `select` simply uses it as it is. This doesn't seem to be a documented
feature, possibly because it looks like a side effect of delegating to other
helpers -- the relevant source is
[here](https://github.com/rails/rails/blob/3-0-9/actionpack/lib/action_view/helpers/form_options_helper.rb#L298).
Still, it doesn't look like a feature that's likely to change anytime soon.

This method can also replace `grouped_collection_select`. Using the example
with the cities, countries and continents, we could define the data like so:

``` ruby
class Country < ActiveRecord::Base
  def self.for_select
    Continent.all.map do |continent|
      [continent, continent.countries.map { |c| [c.id, c.name] }]
    end
  end
end
```

Note that it works not only with hashes, but also with lists of pairs, where
the first item is the key and the second is the collection for the options.

The form is almost exactly the same as with the previous `select` example:

``` erb
<%= form_for @city do |f| %>
  <%= f.select :country_id, grouped_options_for_select(Country.for_select) %>
<% end %>
```

A drawback in this case is that it might get a bit complicated to add custom
logic to the `Country::for_select` method. While it's true that
`grouped_collection_select` requires a lot of arguments, that lets you isolate
the logic in scopes and might be a better choice sometimes.

## Summary

  - `collection_select` and `grouped_collection_select` are meant to be used
    when dealing with model data. The invocation gets long, but their many
    arguments make them pretty customizable.
  - When you need a select tag that is not linked to a model attribute, you can
    do it with `select_tag` and choose a helper method to generate your option
    tags.
  - Most `FormBuilder` helpers have standalone versions that end in "_tag", but
    `FormBuilder#select` is `not` equivalent to` select_tag`.
  - You can use `select` for arbitrary collections by relying on one of the
    option-generating helpers. It requires some more work to prepare the data
    structure, but this lets you customize it with only a few changes to the view
    layer.
