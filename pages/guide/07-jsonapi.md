---
layout: guide
group: guide
title: Json API
---

In some scenarios, JSON-API does not define how an implementation should behave.  Elide also may not implement all optional features of the
JSON-API specification.  The following sections clarify Elide's behavior with respect to undefined or optional aspects of JSON-API.

## Hierarchical URLs

Elide generally follows the [JSON-API recommendations](http://jsonapi.org/recommendations/) for URL design.

There are a few caveats given that Elide allows developers control over how entities are exposed:

1. Some entities may only be reached through a relationship to another entity.  Not every entity is _rootable_
1. The root path segment of URLs are by default the name of the class (lowercase).  This can be overridden
1. Elide allows relationships to be nested arbitrarily deep in URLs
1. Elide currently requires all individual entities to be addressed by ID within a URL.  For example, consider a model with an article with a singular author which has a singular address.   While unambiguous, the following is *not* allowed: `/articles/1/author/address`.  Instead, the author must be full qualified by ID: `/articles/1/author/34/address`

## Filters

## Entity Identifiers
