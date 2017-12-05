---
layout: guide
group: guide
title: Client APIs
---

Graph APIs are an evolution of web service APIs that serve and manipulate data for mobile & web applications.
They have a number of characteristics that make them well suited to this task:
1.  Most notably, they present a **data model** as an entity relationship graph and an **accompanying schema**.
    * A well defined model allows for a consistent view of the data and a centralized way to manipulate an instance of the model or to cache it.
    * The schema provides powerful introspection capabilities that can be used to build tools to help developers understand and navigate the model.
2.  The API allows the client to **fetch or mutate as much or as little information in single roundtrip** between client and server.  This also
    shrinks payload sizes and simplifies the process of schema evolution.
3.  There is a **well defined standard** for the API that fosters a community approach to development of supporting tools & best practices.

Elide supports the two most widely adopted standards for graph APIs: 

* [JSON-API]({{site.baseurl}}/pages/guide/10-jsonapi.html)
* [GraphQL]({{site.baseurl}}/pages/guide/11-graphql.html)
