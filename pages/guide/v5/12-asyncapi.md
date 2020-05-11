---
layout: guide
group: guide
subtopic: true
title: Async API
version: 5
---

## Overview

API responses can be slowed down due to multiple reasons. The most common reasons for slowness but not limited to can be complex computational logic or heavy load on the backend database or the API trying to fetch data over a long date range, etc. This could result in a timeout error by the web server. Elide supports fetching the results from calls to JSON-API and GraphQL endpoints asynchronously. Some of the features available are:
* Each Elide instance runs a background process which is responsible for running the query in the background and posting the results in the database.
* Status for Queries which may have stopped executing due to an application reboot is also updated.
* Historical queries and result stored in the database longer than a configurable threshold are deleted.

## Security

The name of the submitter principal is associated with each query submission. The result and status of the query are only accessible to the principal that submitted the query request. If principal was not set in the context then the query and results are accessible to all null principals.

## Enable the Async API

By default the async API is disabled. The entity models needed to support the Async API are built-in. Before we enable the Async API, we need to create the schema in the database for the async models to use. You can refer [demo-schema](https://github.com/yahoo/elide-spring-boot-example/blob/master/src/main/resources/db/changelog/changelog.xml) for the schema details. Feel free to modify the query/result column size as per your needs. Do not update the types of these columns if you rely on hibernate to validate the schema as it could result in errors. Once the schema has been created, you can enable Async API easily.

{% include code_example example="async-api-enable" %}

#### Additional Configuration

There are additional overrides which can be added to update the default configurations related to number of threads, query timeouts and query cleanups.

{% include code_example example="async-api-additional-config" %}

## Running

Once you have configured the settings based on your preference, start the Elide service and run the following curl commands to submit calls to JSON-API/GraphQL endpoints be executed asynchronously. Don’t forget to replace localhost:8080 with your URL. The example below makes use of the models and sample data that the liquibase migrations added through our example [elide-demo](https://github.com/yahoo/elide-spring-boot-example) project.

### Submitting query

{% include code_example example="async-query-submit" %}

Here are the respective repsonses:

{% include code_example example="async-query-submit-rsp" %}

### Retrieving query status

{% include code_example example="async-query-status" %}

Here are the respective repsonses:

{% include code_example example="async-query-status-rsp" %}

### Retrieving query result

{% include code_example example="async-query-result" %}

Here are the respective repsonses:

{% include code_example example="async-query-result-rsp" %}

## Supported Query Types

Below are the supported values for query type in asynchronous calls:

* GRAPHQL_V1_0
* JSONAPI_V1_0

## Query Status

Below are the different possible statuses of asynchronous calls:

* QUEUED
* PROCESSING
* COMPLETE
* CANCELLED (Only status update to CANCELLED allowed, but query cancellation feature to be added later.)
* TIMEDOUT
* FAILURE

## Overriding the AsyncQueryDAO

Elide has a default implementation of [AsyncQueryDAO](https://github.com/yahoo/elide/blob/master/elide-async/src/main/java/com/yahoo/elide/async/service/AsyncQueryDAO.java) interface which is used by the background process for status updates, query cleanup, etc. You have an option to disable it and provide your own implementation.

{% include code_example example="async-api-dao-disabled" %}
