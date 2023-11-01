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

## API Changes

### API Versioning Strategies

Elide 7 includes implementations for the following API Versioning Strategies
- Path
- Header
- Parameters
- Media Type Profile

This can be customized by implementing and registering a `com.yahoo.elide.core.request.route.RouteResolver`.

The default in Elide Spring Boot is now using the Path strategy instead of using the `ApiVersion` header. The Path strategy is the only one that is supported when integrating with Springdoc as the other strategies are difficult to document with OpenAPI.

This can be configured back to the previous defaults using `application.yaml`.

```yaml
elide:
  api-versioning-strategy:
    path:
      enabled: false
    header:
      enabled: true
      header-name:
      - ApiVersion
```

The default in Elide Standalone now accepts all the strategies.

This can be configured back to the previous defaults using the following.

```java
public abstract class Settings implements ElideStandaloneSettings {
    @Override
    public RouteResolver getRouteResolver() {
        new HeaderRouteResolver("ApiVersion");
    }
}
```

### Elide Settings

The `ElideSettingsBuilder` has been changed to be more consistent with the other Lombok builders and to allow easier customization over the defaults instead of replacing it.

For Elide Spring Boot the default settings can be customized using a `ElideSettingsBuilderCustomizer`, `JsonApiSettingsBuilderCustomizer`, `GraphQLSettingsBuilderCustomizer` or `AsyncSettingsBuilderCustomizer`.

The following code only modifies the `defaultMaxPageSize`.

```java
@Configuration
public class ElideConfiguration {
    @Bean
    ElideSettingsBuilderCustomizer elideSettingsBuilderCustomizer() {
        return builder -> builder.defaultMaxPageSize(1000);
    }
}
```

For Elide Standalone the default settings can be customized by overriding the `getElideSettingsBuilder()`, `getJsonApiSettingsBuilder()`, `getGraphQLSettingsBuilder()` or `getAsyncSettingsBuilder()` methods in `ElideStandaloneSettings`.

The following code only modifies the `defaultMaxPageSize`.

```java
public abstract class Settings implements ElideStandaloneSettings {
    @Override
    public ElideSettingsBuilder getElideSettingsBuilder(
            EntityDictionary dictionary,
            DataStore dataStore,
            JsonApiMapper mapper) {
        return ElideStandaloneSettings.super.getElideSettingsBuilder(
                dictionary,
                dataStore,
                mapper)
            defaultMaxPageSize(1000);
    }
}
```

### Request Scope

The `com.yahoo.elide.core.security.RequestScope` interface has changed to be able to return a `Route`. This replaces the `getApiVersion()`, `getRequestHeaderByName()`, `getBaseUrlEndPoint()` and `getQueryParams()` methods.

The JSON-API relevant fields in `com.yahoo.elide.core.RequestScope` have been moved to `com.yahoo.elide.jsonapi.JsonApiRequestScope`.

### Exception Handling

The `ErrorMapper` which mapped an exception to a `CustomErrorException` has been replaced by an `ExceptionMapper` that maps an exception to an `ElideErrorResponse` which contains `ElideErrors` as a body. 

The `ElideErrors` will be mapped to the corresponding `JsonApiErrors` and `GraphQLErrors`. The [`JsonApiError`](https://github.com/yahoo/elide/blob/master/elide-core/src/main/java/com/yahoo/elide/jsonapi/serialization/JsonApiErrorSerializer.java) and [`GraphQLError`](https://github.com/yahoo/elide/blob/master/elide-graphql/src/main/java/com/yahoo/elide/graphql/serialization/GraphQLErrorSerializer.java) are what is serialized as a response.

This mapping of `ElideErrors` happens in the [`DefaultJsonApiExceptionHandler`](https://github.com/yahoo/elide/blob/master/elide-core/src/main/java/com/yahoo/elide/jsonapi/DefaultJsonApiExceptionHandler.java) and [`DefaultGraphQLExceptionHandler`](https://github.com/yahoo/elide/blob/master/elide-graphql/src/main/java/com/yahoo/elide/graphql/DefaultGraphQLExceptionHandler.java) using the `JsonApiErrorMapper` and `GraphQLErrorMapper`.

The following is an example of a custom implementation of an `ExceptionMapper`.

```java
public class InvalidEntityBodyExceptionMapper implements ExceptionMapper<InvalidEntityBodyException, ElideErrors> {
    public ElideErrorResponse<ElideErrors> toErrorResponse(InvalidEntityBodyException exception, ErrorContext errorContext) {
        return ElideErrorResponse.badRequest()
                .errors(errors -> errors
                        // Add the first error
                        .error(error -> error
                                .message(errorContext.isVerbose() ? exception.getMessage() : "Invalid entity body")
                                .attribute("code", "InvalidEntityBody")
                                .attribute("body", ""))
                        // Add the second error
                        .error(error -> error
                                .message("Item 1 cannot be empty")
                                .attribute("code", "NotEmpty")
                                .attribute("item", "1"))
                        // Add the third error
                        .error(error -> error
                                .message("Item 2 cannot be null")
                                .attribute("code", "NotNull")
                                .attribute("item", "2")));
    }
}
```

The following is the relationship between `ElideError` and `JsonApiError` and `GraphQLError`.

|Elide Error            |JsonApi Error          |GraphQL Error          |
|-----------------------|-----------------------|-----------------------|
|`message`              |`details`              |`message`              |
|`attributes`           |`meta`                 |`extensions`           |
|`attributes.id`        |`id`                   |`extensions.id`        |
|`attributes.status`    |`status`               |`extensions.status`    |
|`attributes.code`      |`code`                 |`extensions.code`      |
|`attributes.title`     |`title`                |`extensions.title`     |
|`attributes.source`    |`source`               |`extensions.source`    |
|`attributes.links`     |`links`                |`extensions.links`     |
|`attributes.path`      |`meta.path`            |`path`                 |
|`attributes.locations` |`meta.locations`       |`locations`            |
{:.table}

#### Constraint Violation

Previously the property path that caused the constraint violation can be found on `source.property`. For JSON-API errors this is now at `meta.property`. For GraphQL errors this is now at `extensions.property`.

### Elide

The JSON-API processing logic in `com.yahoo.elide.Elide` have been moved to `com.yahoo.elide.jsonapi.JsonApi`.

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

