---
layout: guide
group: guide
title: Access
---
To define which models are exposed through the Elide service the `@Include` and `@Exclude` annotations. These access
annotations can be used at the package and class levels, with annotations at an entity level taking precedence.

Resources are accessed by traversing the models in the URL path. Consider the following simple data model with three
POJOs:

{% include code_example example="access-example" offset=0 %}

In this example all of the exposed models are accessable at the base of the API. (i.e. `/user/:id` and `/post/:id`
are valid URLs and `/comment/:id` is invalid) When we say that resources are accessed by traversing the models in the
URL we mean that if you have a `User#1` who has written `Post#1`, `Post#2`, `Post#3` the you can access those posts with
the URLs `/user/1/posts/1`, `/user/1/posts/2`, and `/user/1/posts/3`–almost a 1:1 mapping of how those resources would
be accessed directly from java:

```java
User user1 = UserDAO.getUserWithId(1);  // /user/1
Post post1 = user1.posts.get(1);        // /user/1/posts/1
Post post2 = user1.posts.get(2);        // /user/1/posts/2
Post post3 = user1.posts.get(3);        // /user/1/posts/3
```
