---
layout: guide
group: guide
title: Analytic Query Support
version: 5
---

# Overview

Elide's `AggregationDataStore` exposes read-only models that support data analytic queries.  Model attributes represent either metrics (for aggregating, filtering, and sorting) and dimensions (for grouping, filtering, and sorting).  Models exposed through the Aggregation store are flat and do not contain relationships to other models.

The Aggregation store includes a companion store, the `MetaDataStore`, which exposes metadata about the Aggregation store models including their metrics and dimensions.  The metadata store models are predefined, read-only, and served from server memory.

There are two mechanisms for how to create models in the Aggregation store:
1. Through a [HJSON](https://hjson.github.io/) configuration file that can be maintained without writing code or rebuilding the application.
2. Through JVM language classes annotated with Elide annotations.

The former is preferred for most use cases because of better ergonomics for non-developers.  The latter is useful to add custom Elide security rules or life cycle hooks.

With the introduction of the Aggregation store, Elide now integrates with [Navi](https://github.com/yahoo/navi) - a companion UI framework that provides data visualization and analytics.

# Querying

Models managed by the `AggregationDataStore` can be queried via JSON-API or GraphQL similar to other Elide models.  There are a few important distinctions:
1. If one or more metrics are included in the query, every dimension will be used to aggregate the selected metrics.
2. If only dimensions (no metrics) are included in the query, Elide will return a distinct list of the requested dimension value combinations.
3. Every elide model includes an ID field.  The ID field returned from aggregation store models is not a true identifier.  It represents the row number from a returned result.  Attempts to load the model by its identifier will result in an error.

## Analytic Queries

Similar to other Elide models, analytic models can be sorted, filtered, and paginated.  A typical analytic query might look like:

{% include code_example example="04-analytic-query" %}

Conceptually, these queries might generate SQL similar to:

```SQL
SELECT MAX(highScore), overallRating, countryIsoCode FROM playerStats GROUP BY overallRating, countryIsoCode ORDER BY MAX(highScore) ASC;
```

Here are the respective responses:

{% include code_example example="04-analytic-response" %}

## Metadata Queries

A full list of available table and column metadata is covered in the configuration section.  Metadata can be queried through the _table_ model and its associated relationships:

{% include code_example example="04-metadata-query" %}

Here are the respective responses:

{% include code_example example="04-metadata-response" %}

# Configuration

Analtyic model configuration can either be specified through JVM classes decorated with Elide annotations _or_ HJSON configuration files.  HJSON configuration files can either sit locally in the filesystem or be sourced from the classpath.  Either way, they must conform to the following directory structure:

```
	CONFIG_ROOT/
	  ├── models/
	  |  ├── tables/
	  |  |  ├── model1.hjson
	  |  |  ├── model2.hjson
	  |  ├── security.hjson
	  |  └── variables.hjson
	  ├── db/
	  |  ├── sql/
	  |  |  ├── db1.hjson
	  |  ├── variables.hjson
	
```

## Root Directory

CONFIG_ROOT can be any directory in the filesystem or classpath.  It can be configured in spring by setting elide.dynamic-config.path:

```yaml
elide:
  dynamic-config:
    path: src/resources/configs
    enabled: true

```

Alternatively, in elide standalone, it can be configured by overriding the following setting in `ElideStandaloneSettings`:

```java
    default String getDynamicConfigPath() {
        return File.separator + "models" + File.separator;
    }
```

## Data Source Configuration

The Aggregation Data Store does not leverage JPA, but rather uses JDBC directly.  With zero additional configuration, Elide will leverage the default JPA configuration for establishing connections through the Aggregation Data Store.  However, more complex configurations are possible including:

1.  Using a different JDBC data source other than what is configured for JPA.
2.  Leveraging multiple JDBC data sources for different Elide models.

For these complex configurations, you must configure Elide using the Aggregation Store's HJSON configuration language.  The following configuration file illustrates two configurations.  Each configuration includes:
1. A name that will be referenced in your Analytic models (effectively binding them to a data source).
2. A JDBC URL
3. A JDBC driver
4. A user name
5. An Elide SQL Dialect.  This can either be the name of an Elide support dialect _or_ it can be the fully qualified class name of an implementation of an Elide dialect.
6. A map of driver specific properties.

```json
{
  dbconfigs:
  [
    {
      name: Presto Data Source
      url: jdbc:db2:localhost:50000/testdb
      driver: COM.ibm.db2.jdbc.net.DB2Driver
      user: guestdb2
      dialect: PrestoDB
      propertyMap:
      {
        hibernate.show_sql: true
        hibernate.default_batch_fetch_size: 100.1
      }
    }
    {
      name: MySQLConnection
      url: jdbc:mysql://localhost/testdb?serverTimezone=UTC
      driver: com.mysql.jdbc.Driver
      user: guestmysql
      dialect: com.yahoo.elide.datastores.aggregation.queryengines.sql.dialects.impl.HiveDialect
    }
  ]
}
```

```java
public interface DBPasswordExtractor {
    String getDBPassword(DBConfig config);
}
```
