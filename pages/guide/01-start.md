---
layout: guide
group: guide
title: Getting Started
---
## So You Want An API?
{:.no-toc}

The easiest way to get started with Elide is to use the elide-standalone library. The standalone library bundles all of the dependencies you will need to stand up a web service. This tutorial will use elide-standalone, and all of the code is [available here][elide-demo].

You can deploy and play with this example on Heroku or locally.  The landing page will display the [swagger UI][swagger-ui] for the example service.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/aklish/elide-heroku-example)

If you'd rather look at Kotlin code (a different example), checkout this [Kotlin blog example][kotlin-blog].

1. Contents
{:toc}

## Create A Bean

JPA beans are some of the most important code in any Elide project. Your beans are the view of your data model that you wish to expose. In this example we will be modeling a software artifact repository since most developers have a high-level familiarity with artifact repositories such as Maven, Artifactory, npm, and the like.
 
The first beans we’ll need are the `ArtifactGroup`, `ArtifactProduct`, and `ArtifactVersion` beans.  For brevity we will omit package names and import statements. 

{% include code_example example="01-more-beans" %}

## Spin up the API

So now we have some beans, but without an API it is not very useful. Before we add the API component, we need to create the schema in the database that our beans will use.   Out example uses liquibase to manage the schema.  When Heroku releases the application, our example will execute the [database migrations][demo-schema] to configure the database with some test data automatically.  This demo uses Postgres.  Feel free to modify the migration script if you are using a different database provider.

There may be more tables in your database than beans in your project.  Similarly, there may be more columns in a table than in a particular bean.  Not only will our beans work just fine, but we expect that beans will normally expose only a subset of the fields present in the database. Elide is an ideal tool for building micro-services - each service in your system can expose only the slice of the database that it requires.

### Classes

Bringing life to our API is trivially easy. We need two new classes: Main and Settings.

{% include code_example example="01-running" %}

### Supporting Files

Elide standalone uses a JPA data store (the thing that talks to the database) that is [configured programmatically][settings-config] (no persistence.xml required).

If you want to see the logs from your shiny new API, you will also want a [log4j config][log4j-conf]. 
Your log4j config should go in `src/main/resources` so log4j can find it.

### Running

With these new classes, you have two options for running your project.  You can either run the `Main` class using your
favorite IDE, or you can run the service from the command line:

```mvn exec:java -Dexec.mainClass="example.Main"```

Our example requires the following environment variables to be set to work correctly with Heroku and Postgres.  

1. JDBC_DATABASE_URL
2. JDBC_DATABASE_USERNAME
3. JDBC_DATABASE_PASSWORD

If running inside a Heroku dyno, Heroku sets these variables for us.  If you don't set them, the example will use the H2 in memory database.

With the `Main` and `Settings` classes we can now run our API. If you navigate to `http://localhost:8080/api/v1/group` (or alternately http://your-heroku-dyno/api/v1/group) in your browser you can see some of the sample data that the liquibase migrations added for us. Exciting!

```json
{
  "data": [{
    "type": "group",
    "id": "com.example.repository",
    "attributes": {
      "commonName": "Example Repository",
      "description": "The code for this project"
    },
    "relationships": {
      "products": {
        "data": []
      }
    }
  }, {
    "type": "group",
    "id": "com.yahoo.elide",
    "attributes": {
      "commonName": "Elide",
      "description": "The magical library powering this project"
    },
    "relationships": {
      "products": {
        "data": [{
          "type": "product",
          "id": "elide-core"
        }, {
          "type": "product",
          "id": "elide-standalone"
        }, {
          "type": "product",
          "id": "elide-datastore-hibernate5"
        }]
      }
    }
  }]
}
```

## Looking at more data

You can navigate through the entity relationship graph defined in the beans and explore relationships:

```
List groups:                 ap1/v1/group/
Show a group:                ap1/v1/group/<group id>
List a group's products:     ap1/v1/group/<group id>/products/
Show a product:              ap1/v1/group/<group id>/products/<product id>
List a product's versions:   ap1/v1/group/<group id>/products/<product id>/versions/
Show a version:              ap1/v1/group/<group id>/products/<product id>/versions/<version id>
```

## Writing Data

So far we have defined our views on the database and exposed those views over HTTP. This is great progress, but so far
we have only read data from the database.

### Inserting Data

Fortunately for us adding data is just as easy as reading data. For now let’s use cURL to put data in the database.

```curl
curl -X POST http://localhost:8080/api/v1/group/com.example.repository/products \
  -H"Content-Type: application/vnd.api+json" -H"Accept: application/vnd.api+json" \
  -d '{"data": {"type": "product", "id": "elide-demo"}}'
```

When you run that cURL call you should see a bunch of json returned, that is our newly inserted object! If we query
`http://localhost:8080/api/v1/group/com.example.repository/products/`

```json
{
  "data": [{
    "type": "product",
    "id": "elide-demo",
    "attributes": {
      "commonName": "",
      "description": ""
    },
    "relationships": {
      "group": {
        "data": {
          "type": "group",
          "id": "com.example.repository"
        }
      },
      "versions": {
        "data": []
      }
    }
  }]
}
```

## Modifying Data

Notice that, when we created it, we did not set any of the attributes of our new product record. Unfortunately for our
users this leaves the meaning of our elide-demo product ambiguous. What does it do, why should they use it? Updating our
data to help our users is just as easy as it is to add new data. Let’s update our bean with the following cURL call.

```curl
curl -X PATCH http://localhost:8080/api/v1/group/com.example.repository/products/elide-demo \
  -H"Content-Type: application/vnd.api+json" -H"Accept: application/vnd.api+json" \
  -d '{
    "data": {
      "type": "product",
      "id": "elide-demo",
      "attributes": {
        "commonName": "demo application",
        "description": "An example implementation of an Elide web service that showcases many Elide features"
      }
    }
  }'
```

It’s just that easy to create and update data using Elide.

[elide-demo]: https://github.com/aklish/elide-heroku-example
[kotlin-blog]: https://github.com/DennisMcWherter/elide-example-blog-kotlin
[demo-schema]: https://github.com/aklish/elide-heroku-example/blob/master/src/main/resources/db/changelog/changelog.xml
[log4j-conf]: https://github.com/aklish/elide-heroku-example/blob/master/src/main/resources/log4j2.xml
[settings-config]: https://github.com/aklish/elide-heroku-example/blob/master/src/main/java/example/Settings.java#L95-L111
[swagger-ui]: https://swagger.io/tools/swagger-ui/
