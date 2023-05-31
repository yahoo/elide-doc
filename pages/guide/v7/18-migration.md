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

Spring Boot 3 introduces a number of changes in both classes and configuration, now builds with Java 17, and migrates to Hibernate 6.  [This guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide) provides details about how to migrate.  

## Hibernate 

Hibernate 6 moves away from javax.persistence to jakarta.persistence among other changes.  [This guide](https://github.com/hibernate/hibernate-orm/blob/6.0/migration-guide.adoc) provides details about how to migrate.

## Hibernate Search

Hiberate Search 6 introduces an entirely new API including model annotations.  [This guide](https://docs.jboss.org/hibernate/search/6.0/migration/html_single/) provides details about how to migrate.

## Swagger 2 / OpenAPI 3

The migration to Swagger 2 to support OpenAPI 3 completely replaces the older annotations that were used for Swagger 1. For instance the `@ApiModel` and `@ApiModelProperty` annotations have both been replaced by `@Schema`. An overview of the changes in OpenAPI 3 can be found [here](https://swagger.io/blog/news/whats-new-in-openapi-3-0/).

## Configuration Properties

With Elide 7 a few configuration properties were renamed.

| Old                                                        | New                                                                  |
|------------------------------------------------------------|----------------------------------------------------------------------|
|`elide.aggregation-store.enable-meta-data-store`            |`elide.aggregation-store.metadata-store.enabled`                      |
|`elide.aggregation-store.default-cache-expiration-minutes`  |`elide.aggregation-store.query-cache.expiration`                      |
|`elide.aggregation-store.query-cache-maximum-entries`       |`elide.aggregation-store.query-cache.max-size`                        |
|`elide.async.max-async-after-seconds`                       |`elide.async.max-async-after`                                         |
|`elide.async.cleanup-enabled`                               |`elide.async.cleanup.enabled`                                         |
|`elide.async.max-run-time-seconds`                          |`elide.async.cleanup.query-max-run-time`                              |
|`elide.async.query-cleanup-days`                            |`elide.async.cleanup.query-retention-duration`                        |
|`elide.async.query-cancellation-interval-seconds`           |`elide.async.cleanup.query-cancellation-check-interval`               |
|`elide.dynamic-config`                                      |`elide.aggregation-store.dynamic-config`                              |
|`elide.dynamic-config.config-api-enabled`                   |`elide.aggregation-store.dynamic-config.config-api.enabled`           |
|`elide.export.extension-enabled`                            |`elide.export.append-file-extension`                                  |
|`elide.export.skipCSVHeader`                                |`elide.export.format.csv.write-header`                                |
|`elide.graphql.enable-federation`                           |`elide.graphql.federation.enabled`                                    |
|`elide.jsonapi.enable-links`                                |`elide.jsonapi.links.enabled`                                         |
|`elide.subscription`                                        |`elide.graphql.subscription`                                          |
|`elide.subscription.connection-timeout-ms`                  |`elide.graphql.subscription.connection-timeout`                       |
|`elide.subscription.idle-timeout-ms`                        |`elide.graphql.subscription.idle-timeout`                             |
|`elide.subscription.publish-enabled`                        |`elide.graphql.subscription.publishing.enabled`                       |
|`elide.strip-authorizaton-headers`                          |`elide.strip-authorization-headers`                                   |
{:.table}

### Converting Durations

The properties indicating a duration are now specified using `java.time.Duration`. For instance a configuration value of `7d` indicates 7 days and `300s` indicates 300 seconds.

The following are the supported units
- `ns` for nanoseconds
- `us` for microseconds
- `ms` for milliseconds
- `s` for seconds
- `m` for minutes
- `h` for hours
- `d` for days

