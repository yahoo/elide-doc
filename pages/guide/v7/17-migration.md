---
layout: guide
group: guide
title: Migration From Elide 6
description: Migration From Elide 6
version: 7
---

Elide 6 documentation can be found [here]({{site.baseurl}}/pages/guide/v6/01-start.html).
Elide 5 documentation can be found [here]({{site.baseurl}}/pages/guide/v5/01-start.html).
Elide 4 documentation can be found [here]({{site.baseurl}}/pages/guide/v4/01-start.html).

## New Features in Elide 7.X

Elide 7 is a major dependency upgrade including the following key updates:
- Elide now builds with Java 17
- Upgrade to Spring Boot 3.X
- Upgrade to Hibernate 6.X
- Upgrade to Hibernate Search 6.X
- Migrate from javax to jakarta
- Upgrade to Jetty 11.X
- Upgrade to Jersey 3.1.X
- Upgrade to Swagger 2.X

To keep the migration simpler, no interface changes were made to Elide.  

## Spring Boot 3

Spring boot 3 introduces a number of changes in both classes and configuration, now builds with Java 17, and migrates to Hibernate 6.  [This guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide) provides details about how to migrate.  

## Hibernate 

Hibernate 6 moves away from javax.persistence to jakarta.persistence among other changes.  [This guide](https://github.com/hibernate/hibernate-orm/blob/6.0/migration-guide.adoc) provides details about how to migrate.

## Hibernate Search

Hiberate Search 6.X introduces an entirely new API including model annotations.  [This guide](https://docs.jboss.org/hibernate/search/6.0/migration/html_single/) provides details about how to migrate.

## Swagger 2 / OpenAPI 3

The migration to Swagger 2 to support OpenAPI 3 completely replaces the older annotations that were used for Swagger 1. For instance the `@ApiModel` and `@ApiModelProperty` annotations have both been replaced by `@Schema`. An overview of the changes in OpenAPI 3 can be found [here](https://swagger.io/blog/news/whats-new-in-openapi-3-0/).
