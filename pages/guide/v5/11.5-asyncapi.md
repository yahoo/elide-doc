---
layout: guide
group: guide
subtopic: true
title: Async API
version: 5
---

## Overview

Elide APIs are designed for synchronous request and response behavior. The time allowed to service a synchronous response can be limited by proxy servers and gateways. Analytic queries can often take longer than these limits and result in a server timeout. Elide's asynchronous API decouples the submission of a request and the delivery the response into separate client calls. Some of the features available are:
* Queries are run in a background thread that posts the results into a persistence store.
* Results can be retrieved as an embedded response or URL for downloading later (to be available soon).
* Supported downloading formats - CSV and JSON.
* Queries can be configured to execute synchronously before switching to asynchronous mode if not finished by a configurable threshold.
* Status for Queries which may have stopped executing due to an application reboot is also updated.
* Historical queries and result stored in the database longer than a configurable threshold are deleted.

## Security

Elide async API models (AsyncQuery and TableExport) have a simple permission model: Only the principal which submitted a query and admins are allowed to retrieve its status or results.

## Enable the Async API

By default the async API is disabled. The entity models needed to support the Async API are JPA models that are mapped to a specific database schema. This schema must be created in your target database. You can refer to [demo-schema](https://github.com/yahoo/elide-spring-boot-example/blob/elide-5.x/src/main/resources/db/changelog/changelog.xml) for an example using liquibase. Feel free to modify the query/result column sizes per your needs.

{% include code_example example="async-api-enable" %}

#### Additional Configuration

There are additional overrides which can be added to update the default configurations related to number of threads, query timeouts and query cleanups.

{% include code_example example="async-api-additional-config" %}

## Running

Once you have configured the settings based on your preference, start the Elide service and run the following curl commands to submit calls to JSON-API/GraphQL endpoints be executed asynchronously. Don’t forget to replace localhost:8080 with your URL. The example below makes use of the models and sample data that the liquibase migrations added through our example [elide-demo](https://github.com/yahoo/elide-spring-boot-example/tree/elide-5.x) project.

### Submitting query

{% include code_example example="async-api-submit" %}

Here are the respective repsonses:

{% include code_example example="async-api-submit-rsp" %}

### Retrieving status and result

{% include code_example example="async-api-status" %}

Here are the respective repsonses:

{% include code_example example="async-api-status-rsp" %}

## Supported Query Types

Below are the supported values for query type in asynchronous calls:

* GRAPHQL_V1_0
* JSONAPI_V1_0

## Supported Result Types

Below are the supported values for result type in asynchronous calls (Table Export only):

* JSON
* CSV

## Query Status

Below are the different possible statuses of asynchronous calls:

* QUEUED
* PROCESSING
* COMPLETE
* CANCELLED (Only status update to CANCELLED allowed, query cancellation handled by a background process.)
* TIMEDOUT
* FAILURE
* CANCEL_COMPLETE (After the background process has completed canceling.)

## Overriding the AsyncQueryDAO

Elide has a default implementation of [AsyncQueryDAO](https://github.com/yahoo/elide/blob/elide-5.x/elide-async/src/main/java/com/yahoo/elide/async/service/AsyncQueryDAO.java) interface which is used by the background process for status updates, query cleanup, etc. You have an option to disable it and provide your own implementation.

{% include code_example example="async-api-dao-disabled" %}

## Overriding the ResultStorageEngine

Elide has a default implementation of [ResultStorageEngine](https://github.com/yahoo/elide/blob/elide-5.x/elide-async/src/main/java/com/yahoo/elide/async/service/FileResultStorageEngine.java) interface which is used by the background table export process for storing the results. You have an option to disable it and provide your own implementation.

{% include code_example example="async-api-storageengine-disabled" %}
