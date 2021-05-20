---
layout: guide
group: guide
title: Analytic Query Support
version: 5
---

* TOC
{:toc}

# Overview

Elide includes a semantic modeling layer and analytic query API for OLAP style queries against your database.

A **semantic model** is the view of the data you want your users to understand. It is typically non-relational (for simplicity) and consists of concepts like tables, measures, and dimensions. End users refer to these concepts by name only (they are not expected to derive formulas or know about the physical storage or serialization of data).

A **virtual semantic layer** maps a semantic model to columns and tables in a physical database. Elide’s virtual semantic layer accomplishes this mapping through a [Hjson](https://hjson.github.io/) configuration language. Hjson is a human friendly adaptation of JSON that allows comments and a relaxed syntax among other features. Elide’s virtual semantic layer includes the following information:

 * The defintions of tables, measures, and dimensions you want to expose to the end user.
 * Metadata like descriptions, categories, and tags that better describe and label the semantic model.
 * For every table, measure, and dimension, a SQL fragment that maps it to the physical data. These fragements are used by elide to generate native SQL queries against the target database.

Elide leverages the `AggregationDataStore` store to expose the read-only models defined in the semantic model.  Model attributes represent either metrics (for aggregating, filtering, and sorting) and dimensions (for grouping, filtering, and sorting).  Models exposed through the aggregation store are flat and do not contain relationships to other models.

The Aggregation store includes a companion store, the `MetaDataStore`, which exposes metadata about the Aggregation store models including their metrics and dimensions.  The metadata store models are predefined, read-only, and served from server memory.

There are two mechanisms to create models in the Aggregation store's semantic layer:
1. Through [Hjson](https://hjson.github.io/) configuration files that can be maintained without writing code or rebuilding the application.
2. Through JVM language classes annotated with Elide annotations.

The former is preferred for most use cases because of better ergonomics for non-developers.  The latter is useful to add custom Elide security rules or life cycle hooks.

With the introduction of the Aggregation store, Elide now integrates with [Yavin](https://yavin.dev/) - a companion UI framework that provides data visualization and analytics.

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

A full list of available table and column metadata is covered in the [configuration section](#tables). Metadata can be queried through the _table_ model and its associated relationships. To enable the metadata query APIs, we have to turn on the `MetaDataStore`. The `enableMetaDataStore` flag is described [here](#feature-flags).

{% include code_example example="04-metadata-query" %}

Here are the respective responses:

{% include code_example example="04-metadata-response" %}

# Configuration

## Feature Flags

There are feature flags that enable Hjson configuration, analytic queries, and [Metadata queries](#metadata-queries) respectively:

| Configuration                         | Description                                                       | Default  |
| --------------------------------------| ----------------------------------------------------------------- | -------  |
| dynamic-config.enabled                | Enable model creation through the Hjson configuration files.      | false    |
| aggregation-store.enabled             | Enable support for data analytic queries.                         | false    |
| aggregation-store.enableMetaDataStore | Enable the metadata query APIs exposing the metadata about the Aggregation store models including their metrics and dimensions. | false    |
{:.table}

{% include code_example example="04-analytic-feature-flags" %}

## File Layout

Analtyic model configuration can either be specified through JVM classes decorated with Elide annotations _or_ Hjson configuration files.  Hjson configuration files can be sourced either from the local filesystem or the classpath.  If Hjson configuration is found in the classpath, the filesystem is ignored.  All Hjson configuration must conform to the following directory structure:

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

1. Analytic model files are stored in `/models/tables`.  Multiple models can be grouped together into a single file.
2. Security rules are stored in `/models/security.hjson`.
3. Model and security Hjson files support variable substitution with variables defined in `/models/variables.hjson`.
4. Data source configurations are stored in `/db/sql`.  Multiple configurations can be grouped together into a single file.
5. Data source Hjson files support variable substitution with variables defined in `/db/variables.hjson`.

CONFIG_ROOT can be any directory in the filesystem or classpath.  The root configuration location can be set as follows:

{% include code_example example="04-dynamic-config-path" %}

## Data Source Configuration

The Aggregation Data Store does not leverage JPA, but rather uses JDBC directly.  By default, Elide will leverage the default JPA configuration for establishing connections through the Aggregation Data Store.  However, more complex configurations are possible including:

1.  Using a different JDBC data source other than what is configured for JPA.
2.  Leveraging multiple JDBC data sources for different Elide models.

For these complex configurations, you must configure Elide using the Aggregation Store's Hjson configuration language.  The following configuration file illustrates two data sources.  Each data source configuration includes:
1. A name that will be referenced in your Analytic models (effectively binding them to a data source).
2. A JDBC URL
3. A JDBC driver
4. A user name
5. An [Elide SQL Dialect](#dialects).  This can either be the name of an Elide supported dialect _or_ it can be the fully qualified class name of an implementation of an Elide dialect.
6. A map of driver specific properties.

```
{
  dbconfigs:
  [
    {
      name: Presto Data Source
      url: jdbc:presto://localhost:4443/testdb
      driver: com.facebook.presto.jdbc.PrestoDriver
      user: guestdb2
      dialect: PrestoDB
    }
    {
      name: Hive Data Source
      url: jdbc:hive2://localhost:4444/dbName
      driver: org.apache.hive.jdbc.HiveDriver
      user: guestmysql
      dialect: com.yahoo.elide.datastores.aggregation.queryengines.sql.dialects.impl.HiveDialect
      propertyMap:
      {
        sslEnabled : true
      }
    }
  ]
}
```

By default, Elide uses HikariCP's DataSource for JDBC connection pool. A custom `DataSourceConfiguration` can be configured by the following override:

{% include code_example example="04-datasource-configuration" %}

### Data Source Passwords

Data source passwords are provided out of band by implementing a `DBPasswordExtractor`:

```java
public interface DBPasswordExtractor {
    String getDBPassword(DBConfig config);
}
```

A custom `DBPasswordExtractor` can be configured by the following override:

{% include code_example example="04-db-password" %}

### Dialects

A dialect must be configured for Elide to correctly generate analytic SQL queries.  Elide supports the following dialects out of the box:

| Friendly Name | Class                                                                                 |
| ------------- | ------------------------------------------------------------------------------------- |
| H2            | com.yahoo.elide.datastores.aggregation.queryengines.sql.dialects.impl.H2Dialect       |
| Hive          | com.yahoo.elide.datastores.aggregation.queryengines.sql.dialects.impl.HiveDialect     |
| PrestoDB      | com.yahoo.elide.datastores.aggregation.queryengines.sql.dialects.impl.PrestoDBDialect |
| Postgres      | com.yahoo.elide.datastores.aggregation.queryengines.sql.dialects.impl.PostgresDialect |
| MySQL         | com.yahoo.elide.datastores.aggregation.queryengines.sql.dialects.impl.MySQLDialect    |
| Druid         | com.yahoo.elide.datastores.aggregation.queryengines.sql.dialects.impl.DruidDialect    |
{:.table}

If not leveraging Hjson configuration, a default dialect can be configured for analytic queries:

{% include code_example example="04-default-dialect" %}

## Model Configuration

### Concepts

Elide exposes a virtual semantic model of tables and columns that represents a data warehouse.   The virtual semantic model can be mapped to one or more physical databases, tables, and columns through configuration by a data analyst.   The analyst maps virtual tables and columns to fragments of native SQL queries that are later assembled into complete SQL statements at query time.

Analytic models are called **Tables** in Elide.  They are made up of:
1. **Metrics** - Numeric columns that can be aggregated, filtered on, and sorted on.
2. **Dimensions** - Columns that can be grouped on, filtered on, and sorted on.
3. **TimeDimension** - A type of **Dimension** that represents time.  Time dimensions are tied to grain (a period) and a timezone.
4. **Columns** - The supertype of **Metrics**, **Dimensions**, and **TimeDimensions**.  All columns share a set of common metadata.
5. **Joins** - Even though Elide analytic models are flat (there are no relationships to other models), individual model columns can be sourced from multiple physical tables.  **Joins** provide Elide the information it needs to join other database tables at query time to compute a given column.

Some metrics have **FunctionArguments**.  They represent parameters that are supplied by the client to change how the metric is computed.

### Example Configuration

{% include code_example example="04-analytic-config" %}

### Tables

Tables must source their columns from somewhere.  There are three, mutually exclusive options:
1.  Tables can source their columns from a physical table.  
2.  Tables can source their columns from a SQL subquery.
3.  Tables can extend (override or add columns to) an existing Table. More details can be found [here](#inheritance).

These options are configured via the 'table', 'sql', and 'extend' [properties](#table-properties).

#### Table Properties

Tables include the following properties:

| Hjson Property        | Explanation                                                      |  Example Hjson Value | Annotation/Java Equivalent |
| --------------------- | ---------------------------------------------------------------- | -------------------- | -------------------------- |
| name                  | The name of the elide model.  It will be exposed through the API with this name. | tableName | `@Include(type="tableName")` |
| version               | If leveraging Elide API versions, the API version associated with this model.  | 1.0 | `@ApiVersion(version="1.0")` |
| friendlyName          | The friendly name for this table.  Unicode characters are supported.  | 'Player Stats' | `@TableMeta(friendlyName="Player Stats")` |
| description           | A description of the table. | 'A description for tableName' | `@TableMeta(description="A description for tableName")` |
| category              | A free-form text category for the table. | 'Some Category' | `@TableMeta(category="Some Category")` |
| tags                  | A list of free-form text labels for the table. | ['label1', 'label2'] | `@TableMeta(tags={"label1","label2"})` |
| cardinality           | tiny, small, medium, large, huge - A hint about the number of records in the table. | small | `@TableMeta(size=CardinalitySize.SMALL)` |
| dbConnectionName      | The name of the physical data source where this table can be queried.  This name must match a data source configuration name. | MysqlDB | `@FromTable(dbConnectionName="MysqlDB")` |
| schema                | The database schema where the physical data resides | schemaName | `@FromTable(name=schemaName.tableName)` |
| table                 | Exactly one of _table_, _sql_, and _extend_ must be provided.  Provides the name of the physical base table where data will be sourced from. | tableName | `@FromTable(name=tableName)` |
| sql                   | Exactly one of _table_, _sql_, and _extend_ must be provided.  Provides a SQL subquery where the data will be sourced from. | 'SELECT foo, bar FROM blah;' | `@FromSubquery(sql="SELECT foo, bar FROM blah;")` |
| extend                | Exactly one of _table_, _sql_, and _extend_ must be provided.  This model extends or inherits from another analytic model. | tableName | class Foo extends Bar |
| readAccess            | An elide permission rule that governs read access to the table. | 'member and admin.user' | `@ReadPermission(expression="member and admin.user")` |
| filterTemplate        | An RSQL filter expression template that must directly match or be included in the client provided filter. | countryIsoCode==\{\{code\}\} | @TableMeta(filterTemplate="countryIsoCode==\{\{code\}\}") |
| hidden                | The table is not exposed through the API. | true | `@Exclude` |
| isFact                | Is the table a fact table. Models annotated using FromTable or FromSubquery or TableMeta or configured through Hjson default to true unless marked otherwise.  Yavin will use this flag to determine which tables can be used to build reports. | true | `@TableMeta(isFact=false)` |
{:.table}

### Columns

Columns are either measures, dimensions, or time dimensions.   They all share a number of [common properties](#column-properties).  The most important properties are:
1. The name of the column.
2. The data type of the column.
3. The definition of the column.

Column definitions are templated, native SQL fragments.  Columns definitions can include references to other column definitions or physical column names that are expanded at query time.  Any part of the column definition enclosed in double curly braces (\{\{foo\}\}) is interpreted either as:
- Another column in the current table (assuming the parameter matches another column name in the table).  
- A column in the underlying physical table (assuming either the parameter does not match any columns in the current table _or_ it matches the current column name).
- Another column in a different table.  The parameter is a dot ('.') separated path where each segment of the path represents a join to another table (denoted by the join name) ending with the destination column name (\{\{player.team.name\}\}).  

Column expressions can be defined in Hjson or Java:

{% include code_example example="04-columns" %}

#### Column Properties

Columns include the following properties:

| Hjson Property        | Explanation                                                      |  Example Hjson Value | Annotation/Java Equivalent |
| --------------------- | ---------------------------------------------------------------- | -------------------- | -------------------------- |
| name                  | The name of the column.  It will be exposed through the API with this name. | columnName | String columnName; |
| friendlyName          | The friendly name for this column to be displayed in the UI. | 'Country Code' | `@ColumnMeta(friendlyName = "Country Code")` |
| description           | A description of the column. | 'A description for columnA' | `@ColumnMeta(description="A description for columnA")` |
| category              | A free-form text category for the column. | 'Some Category' | `@ColumnMeta(category="Some Category")` |
| tags                  | A list of free-form text labels for the column. | ['label1', 'label2'] | `@ColumnMeta(tags={"label1","label2"})` |
| cardinality           | tiny, small, medium, large, huge - A hint about the dimension's cardinality. | small | `@ColumnMeta(size=CardinalitySize.SMALL)` |
| readAccess            | An elide permission rule that governs read access to the column. | 'admin.user' | `@ReadPermission(expression="admin.user")` |
| definition            | A SQL fragment that describes how to generate the column. | MAX(\{\{sessions\}\}) | @DimensionFormula("CASE WHEN \{\{name\}\} = 'United States' THEN true ELSE false END") |
| type                  | The data type of the column.  One of 'INTEGER', 'DECIMAL', 'MONEY', 'TEXT', 'COORDINATE', 'BOOLEAN' | 'BOOLEAN' | String columnName; |
| hidden                | The column is not exposed through the API. | true | `@Exclude` |
{:.table}

Non-time dimensions include the following properties that describe where a discrete list of values can be sourced from (for type-ahead search or other uses) :

| Hjson Property        | Explanation                                                      |  Example Hjson Value | Annotation/Java Equivalent |
| --------------------- | ---------------------------------------------------------------- | -------------------- | -------------------------- |
| values                | An optional enumerated list of dimension values for small cardinality dimensions | ['Africa', 'Asia', 'North America'] | `@ColumnMeta(values = {"Africa", "Asia", "North America")` |
| tableSource           | The semantic table and column names where to find the values (tableName.columnName). | continent.name | `@ColumnMeta(tableSource = "continent.name")` |
{:.table}

#### Time Dimensions & Time Grains

Time dimensions represent time and include one or more time grains.  The time grain determines how time is represented as text in query filters and query results.  Supported time grains include:

| Grain        | Text Format           |
| ------------ | --------------------- |
| SECOND       | "yyyy-MM-dd HH:mm:ss" |
| MINUTE       | "yyyy-MM-dd HH:mm"    |
| HOUR         | "yyyy-MM-dd HH"       |
| DAY          | "yyyy-MM-dd"          |
| WEEK         | "yyyy-MM-dd"          |
| ISOWEEK      | "yyyy-MM-dd"          |
| MONTH        | "yyyy-MM"             |
| QUARTER      | "yyyy-MM"             |
| YEAR         | "yyyy"                |
{:.table}

When defining a time dimension, a native SQL expression may be provided with the grain to convert the underlying column (represented as \{\{\}\}) to its expanded SQL definition:

{% include code_example example="04-time-dimensions" %}

Elide would expand the above example to this SQL fragment: `PARSEDATETIME(FORMATDATETIME(createdOn, 'yyyy-MM'), 'yyyy-MM')`.

Time grain definitions are optional and default to type 'DAY' and an empty SQL expression.

### Joins

Table joins allow column expressions to reference fields from other tables.  At query time, if a column requires a join, the join will be added to the generated SQL query.  Each table configuration can include zero or more join definitions:

{% include code_example example="04-joins" %}

#### Join Properties

Each join definition includes the following properties:

| Hjson Property        | Explanation                                                      |
| --------------------- | ---------------------------------------------------------------- |
| name                  | A unique name for the join.  The name can be referenced in column definitions. |
| to                    | The name of the Elide model being joined against.  This can be a semantic model or a CRUD model. |
| kind                  | 'toMany' or 'toOne' (Default: toOne)                  |
| type                  | 'left', 'inner', 'full' or 'cross' (Default: left)                           |
| definition            | A templated SQL join expression.  See below. |
{:.table}

#### Join Definition

Join definitions are templated SQL expressions that represent the _ON_ clause of a SQL statement:

{% raw %}
```
definition: "{{ orderId}} = {{delivery.orderId}} AND {{ delivery.delivered_on }} > '1970-01-01'"
```
{% endraw %}

Column references must be wrapped in curly braces and are replaced at query time with the correctly qualified SQL names.  A column reference can either refer to:
1. A logical column in the current model that should be expanded by its corresponding SQL definition.
2. A physical column in the current table.
3. A reference to logical or physical column in the join table.  The reference consists of the join name, a period, and finally the column name in the join table.

### Inheritance

Tables can extend another existing Table. The following actions can be performed:
* New columns can be added.
* Existing columns can be modified.
* [Table properties](#table-properties) can be modified.

The Table properties listed below can be inherited without re-declaration. Any [Table property](#table-properties) not listed below, has to be re-declared.

* `dbConnectionName`
* `schema`
* `table`
* `sql`

Unlike [Table properties](#table-properties), [Column properties](#column-properties) are not inherited. When overriding a Column in an extended Table, the column properties have to be redefined.

#### Hjson inheritance vs Java inheritance

Hjson inheritance and Java inheritance differ in one key way. Hjson inheritance allows the type of a measure or dimension to be changed in the subclassed model. Changing the type of an inherited measure or dimension in Java might generate a compilation error.

#### Example Extend Configuration

The sample below uses the [Example Configuration](#example-configuration) as its parent model. Let's assume we are a club that exposes the Player Stats from the intra-squad practice games and the tournament games to coaches using the PlayerStats model. We want to expose the data from the same persistent store to the general public with below differences:
* Exclude the intra-squad games from `highScore` calculation.
* Modify the Grain of `game_on` column from `DAY` to `YEAR`.
* Accessible by Admins and Guest users.

To avoid the compilation error highlighted [above](#hjson-inheritance-vs-Java-inheritance), we will have to write the new JVM class with all the columns and properties instead of inheriting unchanged ones from the Parent model. With the Hjson `extend`, it will be a few lines of simple changes to inherit from the Parent model without duplication as highlighted in the example below.

{% include code_example example="04-analytic-extend-config" %}

We can use Java's inheritance, if the goal does not involve changing the type of columns. Hjson `extend` will still require a few lines of simple changes.

{% include code_example example="04-analytic-extend-config-simple" %}

## Security Configuration

The list of available security roles can be defined in the security.hjson file:

```
{
    roles : [
        admin.user
        guest user
        member
        user
    ]
}
```

Each role defined generates an Elide [user check](/pages/guide/v{{ page.version }}/03-security.html#user-checks) that extends [RoleMemberCheck](https://github.com/yahoo/elide/blob/master/elide-core/src/main/java/com/yahoo/elide/core/security/checks/prefab/Role.java#L38-L48).  

These roles can then be referenced in security rules applied to entire tables or individual columns in their respective Hjson configuration:

`readAccess = 'member OR guest user'`

The `readAccess` table and column attribute can also reference Elide checks that are compiled with your application to implement row level security or other more complex security rules.

## Variable Substitution

To avoid repeated configuration blocks, all Hjson files (table, security, and data source) support variable substitution.  Variables are defined in the variables.hjson file:

```
{
   foo: [1, 2, 3]
   bar: blah
   hour: hour_replace
   measure_type: MAX
   name: PlayerStats
   table: player_stats
}
```

The file format is a simple mapping from the variable name to a JSON structure.  At server startup, Elide will replace any variable name surrounded by '<%' and '%>' tags with the corresponding JSON structure.

## Caching

The Aggregation data store supports a configurable caching strategy to cache query results.  More details can be found in the [performance section](/pages/guide/v{{ page.version }}/16-performance.html#aggregationdatastore-cache).

### Bypassing Cache

Elide JAX-RS endpoints (elide-standalone) and Spring conrollers (Spring) support a Bypass Cache header ('bypasscache') that can be set to `true` for caching to be disabled on a per query basis. If no bypasscache header is specified by the client or a value other than `true` is used, caching is enabled by default.

## Configuration Validation

All Hjson configuration files are validated by a JSON schema.  The schemas for each file type can be found here:
1. [Table Config](https://github.com/yahoo/elide/blob/master/elide-model-config/src/main/resources/elideTableSchema.json)
1. [Data Source Config](https://github.com/yahoo/elide/blob/master/elide-model-config/src/main/resources/elideDBConfigSchema.json)
1. [Security Config](https://github.com/yahoo/elide/blob/master/elide-model-config/src/main/resources/elideSecuritySchema.json)
1. [Variable File](https://github.com/yahoo/elide/blob/master/elide-model-config/src/main/resources/elideVariableSchema.json)

Hjson configuration files can be validated against schemas using a command-line utility following these steps:

1. Build your Elide project to generate a Fat JAR. Make sure to include a Fat JAR build configuration in your POM file.

   `mvn clean install`

1. Using the generated JAR for validation:

   `java -cp elide-*-example.jar com.yahoo.elide.modelconfig.validator.DynamicConfigValidator --help`
   `java -cp elide-*-example.jar com.yahoo.elide.modelconfig.validator.DynamicConfigValidator --configDir <Path for Config Directory>`

1. The config directory needs to adhere to this [file layout](#file-layout).

## Signature Verification

Elide supports RSA signature verification of Hjson configuration files

1. Generate a TAR file of the models directory. Refer [file layout](#file-layout) for model directory structure.

   `bash tar -czvf models.tar.gz models/`
   
1. Generate an RSA Public and Private Key Pair.

1. Create an RSA signature using the content of the TAR file and the RSA Private key.

1. Add the public key to the Java Keystore.

1. Use the DynamicConfigVerifier to validate the RSA signature using the Public Key.

```
a) java -cp elide-*-example.jar com.yahoo.elide.contrib.dynamicconfighelpers.verify.DynamicConfigVerifier --tarFile <Path of model config tar file> --signatureFile <Path of Signature file> --publicKeyName <Name of the public key in keystore>

b) java -cp elide-*-example.jar com.yahoo.elide.contrib.dynamicconfighelpers.verify.DynamicConfigVerifier --help
```
