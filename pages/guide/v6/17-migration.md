---
layout: guide
group: guide
title: Migration From Elide 5
description: Migration From Elide 5
version: 6
---

Elide 5 documentation can be found [here]({{site.baseurl}}/pages/guide/v5/01-start.html).
Elide 4 documentation can be found [here]({{site.baseurl}}/pages/guide/v4/01-start.html).

## New Features in Elide 6.X

Elide 6 introduces several new features:
 - Elide 6 is built using Java 11 (as opposed to Java 8).
 - GraphQL subscription support is added along with a JMS data store that can read Elide models from JMS topics.
 - Coming Soon: Quarkus support including Elide native builds with GraalVM.

## API Changes

 - Prior to Elide 6, updates to complex, embedded attributes in Elide models required every field to be set in the attribute or they would be overwritten with nulls.  Elide 6 is now aware of individual fields in complex, embedded attributes and only changes what has been sent by the client.  See [#2277](https://github.com/yahoo/elide/issues/2277) for more details.
 - Elide 6 is stricter about legal JSON-API URLs.  Path segments that represent collections are limited to alphanumeric characters along with underscore and hyphen.  In addition, the path segment must start with a letter.
 - Elide 6 is more relaxed about ID fields in JSON-API URLS.  It now allows colon, ampersand, and space.

## Interface Changes

 - DataStoreTransaction has a number of breaking changes:
    - The `getRelation` method has been split into `getToOneRelation` and `getToManyRelation`.
    - Both `loadObjects` and `getToManyRelation` now return a new subclass of `Iterable`: `DataStoreIterable`
    - A new iterable class has been introduced (`DataStoreIterable`) which wraps an underlying iterable.  The `DataStoreIterable` has flags that control whether Elide filters, sorts, and paginates the iterable in memory.
    - The methods `supportsFiltering`, `supportsPagination`, and `supportsSorting` have been removed and replaced with the `DataStoreIterable` instead.
s
 - EntityDictionary is now entirely constructed with a Builder.  All prior constructors have been removed.
 - Security checks are now instantiated at boot and reused across requests.  This change requires security checks to be thread safe.

## Module & Package Changes

The following packages have been removed:

 - Legacy datastore packages elide-hibernate-3 and elide-hibernate-5 have been retired and can be replaced with the JPA data store.
 - The Elide bridgeable datastore has been removed.
 - The package elide-datastore-hibernate has been renamed to elide-datastore-jpql.   Internal package structure for the module was also changed.

