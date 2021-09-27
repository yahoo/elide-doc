---
layout: guide
group: guide
title: Migration From Elide 5
version: 6
---

Elide 5 documentation can be found [here](/pages/guide/v5/01-start.html).
Elide 4 documentation can be found [here](/pages/guide/v4/01-start.html).

## New Features in Elide 6.X

Elide 6 introduces several new features:
 - Elide 6 is built using Java 11 (as opposed to Java 8).
 - GraphQL subscription support is added along with a JMS data store that can read Elide models from JMS topics.
 - Coming Soon: Quarkus support including Elide native builds with GraalVM.

## API Changes

Prior to Elide 6, updates to complex, embedded attributes in Elide models required every field to be set in the attribute or they would be overwritten with nulls.  Elide 6 is now aware of individual fields in complex, embedded attributes and only changes what has been sent by the client.  See [#2277](https://github.com/yahoo/elide/issues/2277) for more details.

## Interface Changes

 - EntityDictionary is now entirely constructed with a Builder.  All prior constructors have been removed.
 - Security checks are now instantiated at boot and reused across requests.  This change requires security checks to be thread safe.

## Module & Package Changes

The following packages havea been removed:

 - Legacy datastore packages elide-hibernate-3 and elide-hibernate-5 have been retired and can be replaced with the JPA data store.
 - The Elide bridgeable datastore has been removed.
 - The package elide-datastore-hibernate has been renamed to elide-datastore-jpql.   Internal package structure for the module was also changed.

