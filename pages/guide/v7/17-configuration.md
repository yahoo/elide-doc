---
layout: guide
group: guide
title: Configuration
description: Configuration
version: 7
---

## Core Properties

| Name                                                       | Description                                                                                            | Default Value
|------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|---------------
|`elide.base-url`                                            | The base service URL that clients use in queries.                                                      | 
|`elide.page-size`                                           | Default pagination size for collections if the client doesn't paginate.                                | `500`
|`elide.max-page-size`                                       | The maximum pagination size a client can request.                                                      | `10000`
|`elide.verbose-errors`                                      | Turns on/off verbose error responses.                                                                  | `false`
|`elide.strip-authorization-headers`                         | Remove Authorization headers from RequestScope to prevent accidental logging of security credentials.  | `true`
{:.table}

## JSON-API Properties

| Name                                                       | Description                                                                                            | Default Value
|------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|---------------
|`elide.json-api.enabled`                                    | Whether or not the controller is enabled.                                                              | `false`
|`elide.json-api.path`                                       | The URL path prefix for the controller.                                                                | `/`
|`elide.json-api.links.enabled`                              | Turns on/off JSON-API links in the API.                                                                | `false`
{:.table}

## GraphQL Properties

| Name                                                       | Description                                                                                            | Default Value
|------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|---------------
|`elide.graphql.enabled`                                     | Whether or not the controller is enabled.                                                              | `false`
|`elide.graphql.path`                                        | The URL path prefix for the controller.                                                                | `/`
|`elide.graphql.federation.enabled`                          | Turns on/off Apollo federation schema.                                                                 | `false`
|`elide.graphql.subscription.enabled`                        | Whether or not the controller is enabled.                                                              | `false`
|`elide.graphql.subscription.path`                           | The URL path prefix for the controller.                                                                | `/`
|`elide.graphql.subscription.send-ping-on-subscribe`         | Websocket sends a PING immediate after receiving a SUBSCRIBE.                                          | `false`
|`elide.graphql.subscription.connection-timeout`             | Time allowed from web socket creation to successfully receiving a CONNECTION_INIT message.             | `5000ms`
|`elide.graphql.subscription.idle-timeout`                   | Maximum idle timeout in milliseconds with no websocket activity.                                       | `300000ms`
|`elide.graphql.subscription.max-subscriptions`              | Maximum number of outstanding GraphQL queries per websocket.                                           | `30`
|`elide.graphql.subscription.max-message-size`               | Maximum message size that can be sent to the websocket.                                                | `10000`
|`elide.graphql.subscription.publishing.enabled`             | Whether Elide should publish subscription notifications to JMS on lifecycle events.                    | `false`
{:.table}

## API Docs Properties

| Name                                                       | Description                                                                                            | Default Value
|------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|---------------
|`elide.api-docs.enabled`                                    | Whether or not the controller is enabled.                                                              | `false`
|`elide.api-docs.path`                                       | The URL path prefix for the controller.                                                                | `/`
|`elide.api-docs.version`                                    | The OpenAPI Specification Version to generate.                                                         | `openapi_3_0`
{:.table}

## Async Properties

| Name                                                       | Description                                                                                            | Default Value
|------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|---------------
|`elide.async.enabled`                                       | Whether or not the async feature is enabled.                                                           | `false`
|`elide.async.thread-pool-size`                              | Default thread pool size.                                                                              | `5`
|`elide.async.max-async-after`                               | Default maximum permissible time to wait synchronously for the query to complete before switching to asynchronous mode. | `10s`
|`elide.async.cleanup.enabled`                               | Whether or not the cleanup is enabled.                                                                 | `false`
|`elide.async.cleanup.query-max-run-time`                    | Maximum query run time.                                                                                | `3600s`
|`elide.async.cleanup.query-retention-duration`              | Retention period of async query and results before being cleaned up.                                   | `7d`
|`elide.async.cleanup.query-cancellation-check-interval`     | Polling interval to identify async queries that should be canceled.                                    | `300s`
|`elide.async.export.enabled`                                | Whether or not the controller is enabled.                                                              | `false`
|`elide.async.export.path`                                   | The URL path prefix for the controller.                                                                | `/export`
|`elide.async.export.append-file-extension`                  | Enable Adding Extension to table export attachments.                                                   | `false`
|`elide.async.export.storage-destination`                    | Storage engine destination.                                                                            | `/tmp`
|`elide.async.export.format.csv.write-header`                | Generates the header in a CSV formatted export.                                                        | `true`
{:.table}

## Aggregation Store Properties

| Name                                                       | Description                                                                                            | Default Value
|------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|---------------
|`elide.aggregation-store.enabled`                           | Whether or not aggregation data store is enabled.                                                      | `false`
|`elide.aggregation-store.default-dialect`                   | SQLDialect type for default DataSource Object.                                                         | `Hive`
|`elide.aggregation-store.query-cache.enabled`               | Whether or not to enable the query cache.                                                              | `true`
|`elide.aggregation-store.query-cache.expiration`            | Query cache expiration after write.                                                                    | `10m`
|`elide.aggregation-store.query-cache.max-size`              | Limit on number of query cache entries.                                                                | `1024`
|`elide.aggregation-store.metadata-store.enabled`            | Whether or not meta data store is enabled.                                                             | `false`
|`elide.aggregation-store.dynamic-config.enabled`            | Whether or not dynamic model config is enabled.                                                        | `false`
|`elide.aggregation-store.dynamic-config.path`               | The path where the config hjsons are stored.                                                           | `/`
|`elide.aggregation-store.dynamic-config.config-api.enabled` | Enable support for reading and manipulating HJSON configuration through Elide models.                  | `false`
{:.table}

## JPA Store Properties

| Name                                                       | Description                                                                                            | Default Value
|------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|---------------
|`elide.jpa-store.delegate-to-in-memory-store`               | When fetching a subcollection from another multi-element collection, whether or not to do sorting, filtering and pagination in memory. | `true`
{:.table}

### Converting Durations

The properties indicating a duration are specified using `java.time.Duration`. For instance a configuration value of `7d` indicates 7 days and `300s` indicates 300 seconds.

The following are the supported units
- `ns` for nanoseconds
- `us` for microseconds
- `ms` for milliseconds
- `s` for seconds
- `m` for minutes
- `h` for hours
- `d` for days

