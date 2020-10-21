---
layout: guide
group: guide
title: Getting Started
version: 4
---
## So You Want An API?
{:.no-toc}

The easiest way to get started with Elide is to use the [Spring Boot starter dependency](https://github.com/yahoo/elide/tree/master/elide-spring/elide-spring-boot-starter). The starter bundles all of the dependencies you will need to stand up a web service. This tutorial uses the starter, and all of the code is [available here][elide-demo].

You can deploy and play with this example on Heroku or locally.  The landing page will let you toggle between the [swagger UI][swagger-ui] and [Graphiql](https://github.com/graphql/graphiql) for the example service.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/yahoo/elide-spring-boot-example)

Don't like Spring/Spring Boot? - check out the same getting starting guide using Jetty/Jersey and [Elide standalone](https://github.com/yahoo/elide/tree/master/elide-standalone).

Don't like Java?  [Here][navi-example] is an example project using Elide with Kotlin.

## Contents
1. Contents
{:toc}

## Add Elide as a Dependency

To include elide into your spring project, add the single starter dependency:
```xml
<dependency>
  <groupId>com.yahoo.elide</groupId>
  <artifactId>elide-spring-boot-starter</artifactId>
  <version>${elide.version}</version>
</dependency>
```

## Create Models

Elide models are some of the most important code in any Elide project. Your models are the view of your data that you wish to expose. In this example we will be modeling a software artifact repository since most developers have a high-level familiarity with artifact repositories such as Maven, Artifactory, npm, and the like.

The first models we’ll need are `ArtifactGroup`, `ArtifactProduct`, and `ArtifactVersion`.  For brevity we will omit package names and import statements.

{% include code_example example="01-more-beans" %}

## Spin up the API

So now we have some models, but without an API it is not very useful. Before we add the API component, we need to create the schema in the database that our models will use.   Our example uses liquibase to manage the schema.  When Heroku releases the application, our example will execute the [database migrations][demo-schema] to configure the database with some test data automatically.  This demo uses Postgres.  Feel free to modify the migration script if you are using a different database provider.

There may be more tables in your database than models in your project or vice versa.  Similarly, there may be more columns in a table than in a particular model or vice versa.  Not only will our models work just fine, but we expect that models will normally expose only a subset of the fields present in the database. Elide is an ideal tool for building micro-services - each service in your system can expose only the slice of the database that it requires.

### Classes

Bringing life to our API is trivially easy.  We need a single Application class:

```java
/**
 * Example app using elide-spring.
 */
@SpringBootApplication
public class App {
    public static void main(String[] args) throws Exception {
        SpringApplication.run(App.class, args);
    }
}
```

### Supporting Files

The application is configured with a Spring application yaml file (broken into sections below).  

The Elide Spring starter uses a JPA data store (the thing that talks to the database).  This can be configured like any other Spring data source and JPA provider.  The one below uses an H2 in-memory database:

```yaml
spring:
  jpa:
    hibernate:
      show_sql: true
      naming:
        physical-strategy: 'org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl'
      dialect: 'org.hibernate.dialect.H2Dialect'
      ddl-auto: 'validate'
      jdbc:
        use_scrollable_resultset: true
  datasource:
    url: 'jdbc:h2:mem:db1;DB_CLOSE_DELAY=-1'
    username: 'sa'
    password: ''
    driver-class-name: 'org.h2.Driver'
```

Elide has its own configuration to turn on APIs and setup their URL paths:

```yaml
elide:
  json-api:
    path: /api/v1
    enabled: true
  graphql:
    path: /graphql/api/v1
    enabled: true
  swagger:
    path: /doc
    enabled: true
    version: "1.0"
```

### Running

With these new classes, you have two options for running your project.  You can either run the `App` class using your
favorite IDE, or you can run the service from the command line:

```java -jar target/elide-spring-boot-1.0.jar```

Our example requires the following environment variables to be set to work correctly with Heroku and Postgres.  

1. JDBC_DATABASE_URL
2. JDBC_DATABASE_USERNAME
3. JDBC_DATABASE_PASSWORD

If running inside a Heroku dyno, Heroku sets these variables for us.  If you don't set them, the example will use the H2 in memory database.

With the `App` class and application yaml file, we can now run our API.

You can now run the following curl commands to see some of the sample data that the liquibase migrations added for us.  Don't forget to replace localhost:8080 with your Heroku URL if running from Heroku!

{% include code_example example="01-data-fetch" %}

Here are the respective repsonses:

{% include code_example example="01-data-fetch-rsp" %}

## Looking at more data

You can navigate through the entity relationship graph defined in the models and explore relationships:

```
List groups:                 group/
Show a group:                group/<group id>
List a group's products:     group/<group id>/products/
Show a product:              group/<group id>/products/<product id>
List a product's versions:   group/<group id>/products/<product id>/versions/
Show a version:              group/<group id>/products/<product id>/versions/<version id>
```

## Writing Data

So far we have defined our views on the database and exposed those views over HTTP. This is great progress, but so far
we have only read data from the database.

### Inserting Data

Fortunately for us adding data is just as easy as reading data. For now let’s use cURL to put data in the database.

{% include code_example example="01-data-insert" %}

When you run that cURL call you should see a bunch of json returned, that is our newly inserted object!

{% include code_example example="01-data-insert-rsp" %}

### Modifying Data

Notice that, when we created it, we did not set any of the attributes of our new product record.  Updating our
data to help our users is just as easy as it is to add new data. Let’s update our model with the following cURL call.

{% include code_example example="01-data-update" %}

It’s just that easy to create and update data using Elide.

[elide-demo]: https://github.com/yahoo/elide-spring-boot-example
[navi-example]: https://github.com/yahoo/navi/tree/master/packages/webservice
[demo-schema]: https://github.com/yahoo/elide-spring-boot-example/blob/master/src/main/resources/db/changelog/changelog.xml
[swagger-ui]: https://swagger.io/tools/swagger-ui/
