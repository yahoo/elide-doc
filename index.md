---
layout: home
group: home
title: Home
---
##What Is Elide?

Elide is a Java library that lets you stand up a [JSON API](http://jsonapi.org) web service with minimal effort starting from a JPA annotated data model.
Elide is designed to quickly build and deploy **production quality** web services that expose databases as services.  Beyond the basics, elide provides:

1. **Access** to JPA entities via JSON API CRUD operations.  Entities can be explicitly included or excluded via annotations.
1. **Patch Extension** Elide supports the [JSON API Patch extension](http://jsonapi.org/extensions/jsonpatch/) allowing multiple create, edit, and delete operations in a single request.
1. **Atomic Requests** All requests to the library (including the patch extension) can be embedded in transactions to ensure operational integrity.
1. **Authorization** All operations on entities and their fields can be assigned custom permission checks limiting who has access to your data.
1. **Audit** Logging can be customized for any operation on any entity.
1. **Extension** Elide allows the ability to add custom business logic and to changeout the default JPA provider (Hibernate)
1. **Client API** Elide is developed in conjunction with a Javascript client library that insulates developers from changes to the specification.

Elide is a library intended to ease the process of standing up production web service layers. It dramatically reduces the number of lines of code required to standup fast and secure web services by handling the "plumbing" automatically. Building a backend web service with Elide only requires the following steps:

  1. Define your data model (this is likely already done if you're using an ORM such as [Hibernate](http://hibernate.org/))
  1. Annotate your model with appropriate security controls
  1. Redirect the appropriate URI root from your web server (i.e. Jetty, Tomcat, etc.) to be handled via the Elide endpoints

After having completed these steps, your web service is ready to go. In short, all of the boilerplate involved in writing each individual endpoint is gone; this allows you to focus on the interesting parts of your problem without the worry of extraneous detail. Consequently, Elide makes for a great **rapid prototyping** tool which allows you to quickly evolve your prototype into a production quality service. Often, the largest distinction will be a rigorous definition of the security model.

##License

The use and distribution terms for this software are covered by the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.html).
