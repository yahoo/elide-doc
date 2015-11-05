---
layout: home
group: home
title: Home
---
##What Is Elide?

Elide is a Java library that let's you stand up a [JSON API](http://jsonapi.org) web service with minimal effort starting from a JPA annotated data model.
Elide is designed to quickly build and deploy **production quality** web services that expose databases as services.  Beyond the basics, elide provides:

1. **Access** to JPA entities via JSON API CRUD operations.  Entities can be explicitly included or excluded via annotations.
1. **Patch Extension** Elide supports the [JSON API Patch extension](http://jsonapi.org/extensions/jsonpatch/) allowing multiple create, edit, and delete operations in a single request.
1. **Atomic Requests** All requests to the library (including the patch extension) can be embedded in transactions to ensure operational integrity.
1. **Authorization** All operations on entities and their fields can be assigned custom permission checks limiting who has access to your data.
1. **Audit** Logging can be customized for any operation on any entity.
1. **Extension** Elide allows the ability to add custom business logic and to changeout the default JPA provider (Hibernate)
1. **Client API** Elide is developed in conjunction with a Javascript client library that insulates developers from changes to the specification.

##License

The use and distribution terms for this software are covered by the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.html).
