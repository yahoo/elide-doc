---
layout: guide
group: guide
title: Getting Started
---
###Prerequisites

  * Java 8

###Overview

<p align="center">
  <img alt="Elide High-Level Overview" src="/assets/images/elide-high-level.png" />
</p>

The Elide library is integrated directly into your serving layer. It is independent of any additional custom logic and can be used alongside custom application code. It consumes and produces valid [JSON API](http://jsonapi.org/) documents as its interchange format between clients to make it easy to adapt and create clients.

###Technical Overview

<p align="center">
  <img alt="Elide High-Level Overview" src="/assets/images/elide-service-desc.png" />
</p>

Elide is middleware for your web service layer. It typically sits between your datastore (and any caching/scaling technologies you may have there) and your server technology (i.e. Jetty, Tomcat, etc.).

The elide-core component is the basis of Elide's functionality. It interacts with a specified database manager to lookup and store data effectively. Moreover, JPA-annotated Java beans are consumed by elide-core and then properly validated hierarchically per request to ensure security.

###Code
The first step is to create a JPA data model and mark which beans to expose via Elide.  The following directive exposes **everything** in a package:  

```java
@Include(rootLevel=true)
package example;
```

The second step is to create a `DatabaseManager`.   It is an interface that binds to a JPA provider.  Elide ships with a default implementation for
Hibernate.  The default `HibernateManager` will discover all of the JPA beans in your deployment and expose those that have been annotated to do so.

```java
/* Takes a hibernate session factory */
DatabaseManager db = new HibernateManager(sessionFactory);
```

The third step is to create an `AuditLogger`.   It is an interface that does something with Audit messages.  Elide ships with a default that
dumps them to slf4j:

```java
AuditLogger logger = new Slf4jLogger();
```

Create an `Elide class`.  It is the entry point for handling requests from your web server/container.  

```java
Elide elide = new Elide(logger, db);
```

`Elide` has methods for `get`, `patch`, `post`, and `delete`.  These methods generally take:

1. An opaque user `Object`
1. An HTTP path as a `String`
1. A JSON API document as a `String` representing the request entity body (if one is required).

It returns a `ElideResponse` which contains the HTTP response status code and a `String` which contains the response entity body.

```
ElideResponse response = elide.post(path, requestBody, user)
```

Wire up the four HTTP verbs to your container and you will have a functioning JSON API server.
