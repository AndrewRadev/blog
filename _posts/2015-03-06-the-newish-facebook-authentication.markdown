---
layout: post
title: "The New(ish) Facebook Authentication"
date: 2015-03-06 15:18
comments: true
categories: ruby rails facebook
published: true
---

Facebook changed their authentication process [fairly recently](https://developers.facebook.com/docs/apps/upgrading#upgrading_v2_0_user_ids). Instead of using a global user id, users would now get an app-specific id instead. This took me by surprise, and I had to jump through some hoops to get stuff to work with our setup. This is a short post that outlines what we did to work around the problem.

<!-- more -->

## The Good Old Way

The way things worked in The Old Times, you had a facebook app, authenticated with it, got a user id and saved it to the database. Upon the next facebook authentication, you'd get the same id and find it in the database, logging the relevant user in. Usually, you'd maintain multiple different apps for production, development, staging, and whatever other domain you need, since apps were only limited to a single domain.

For rails developers, [Omniauth](https://github.com/mkdynamic/omniauth-facebook) helped a lot. With that, all you needed to do is hook up a link to the right url. Sending the user to it would redirect them to facebook, log them in there, and provide you the id in `request.env['omniauth.auth']` under the key `:uid`.

## The Changes

Of course, with app-local ids, this gets a bit more complicated. Having three different apps no longer works well, since you have different ids for the same users. Putting them in the database means users can only log in with the facebook app they used to sign up. If your development database is a clone of production, it's no longer easy to do tests on your local machine.

The solution in this case is using [test apps](https://developers.facebook.com/docs/apps/test-apps). A test app is created from a normal app, has different access credentials, but the same user ids as its original. It's not public, so you can't cheat the system by using it in production, but you *can* use it for testing purposes on a domain other than your main one.

## Facebook for Business

But what if you have a legitimate need for multiple domains in production? At Knowable, we had both "knowable.org" and "joinpolymer.com", since we had two separately branded products backed by the same database. "Polymer" was our new project, and we wanted to introduce social logins to it. That's when we noticed the app id changes. We couldn't use test apps for the purpose, because they're not public. We couldn't use the same facebook app for both domains, either. So what now?

The solution was "[facebook for business](https://www.facebook.com/business)". This was probably created for a completely different purpose, but it also happens to be the offical way to work around this issue. If you create a "facebook business" and you claim both apps as belonging to it (you just need to be an admin to do that), you can request an additional field from facebook called `token_for_business` ([documentation](https://developers.facebook.com/docs/apps/for-business)). This is a string that's the same across all apps of that business, unique per user. This means that storing that in the database lets you use it for authentication alongside the id they give you.

As far as I know, there's no way to pull this off easily in Omniauth. We needed to fetch it in a separate query to facebook using the [koala](https://github.com/arsduo/koala) gem:

``` ruby
def get_facebook_business_token(omniauth)
  graph = Koala::Facebook::API.new(omniauth['credentials']['token'])
  profile = graph.get_object('me', fields: 'token_for_business')
  profile.fetch('token_for_business')
end
```

Usually, it'd be enough to look for the user/authentication with the recommended Omniauth oneliner:

``` ruby
auth = find_by(provider: omniauth['provider'], uid: omniauth['uid'])
```

In case this didn't work and the provider is "facebook", you'd simply get the business token from facebook and try fetching the authentication with that as well:

``` ruby
business_token = get_facebook_business_token(omniauth)
auth = find_by(provider: 'facebook', facebook_business_token: business_token)
```

Not ideal, given that we need to put extra fields on the authentication record specifically for facebook, but it works fine for this one special case.

## Impact

I'm slightly surprised that `omniauth-facebook` doesn't provide something for this, but I'm assuming it's a bit of an edge case to need two separate apps on two separate domains. And there's no point attempting to fetch the business token for "normal" apps.

Another interesting thing that we discovered is that facebook no longer provides a username, either. And, a friend working in a different company told me they may even not provide an email, if the user happens to not have confirmed their email to facebook. It gets harder and harder to create a fully functional user out of facebook data, but I suppose their changes are mostly geared towards protecting users' privacy. Hard to say how to handle these cases, though.
