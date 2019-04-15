---
layout: guide
group: guide
title: Getting Started
---
## So You Want An API?
{:.no-toc}

The easiest way to get started with Elide is to use the elide-standalone library. The standalone library bundles all of
the dependencies you will need to stand up a web service. This tutorial will use elide-standalone, all of the code is
[available here][elide-demo]–if you want to see a more fully fleshed out example of the standalone library checkout this
[Kotlin blog example][kotlin-blog].

1. Contents
{:toc}

## Create A Bean

JPA beans are some of the most important code in any Elide project. Your beans are the view of your data model that you
wish to expose. In this example we will be modeling a software artifact repository since most developers have a
high-level familiarity with artifact repositories such as Maven, Artifactory, npm, and the like. If you are interested,
[the code][elide-demo] is tagged for each step so you can follow along.

The first bean we’ll need is the `ArtifactGroup` bean.  For brevity we will omit package names and import statements. This
will represent the `<groupId>` in Maven’s dependency coordinates.

```java
@Include(rootLevel = true)
@Entity
public class ArtifactGroup {
    @Id
    public String name = "";
}
```

## Spin up the API

So now we have a bean, but without an API it is not do very useful. Before we add the API component, we need to
create the schema in the database that our beans will use. Download and run the [demo setup script][demo-schema]; this
demo uses MySQL, feel free to modify the setup script if you are using a different database provider.

You may notice that there are more tables that just `ArtifactGroup`, and that the `ArtifactGroup` table has more fields
that our bean. Not only will our bean work just fine, we expect that beans will normally expose only a subset of the
fields present in the database. Elide is an ideal tool for building micro-services, each service in your system can
expose only the slice of the database that it requires.

### Classes

Bringing life to our API is trivially easy. We need two new classes: Main and Settings.

{% include code_example example="01-running" %}

### Supporting Files

Elide standalone uses a JPA data store that is configured programmatically (no persistence.xml required).

However, if you want to see the logs from your shiny new API, you will also want a [logback config][logback-conf]. 
Your logback config should go in `src/main/resources` so logback can find it.

### Running

With these new classes, you have two options for running your project, you can either run the `Main` class using your
favorite IDE, or we can add the following snippet to our gradle build script and run our project with ./gradlew run

```gradle
plugins {
  ...
  id 'application'
}

mainClassName = 'com.example.repository.Main' // the actual path to your Main class should go here
```

With the `Main` and `Settings` classes we can now run our API. If you navigate to
`http://localhost:8080/api/v1/artifactGroup` in your browser you can see some of the sample data that the bootstrap
script added for us. Exciting!

```json
{
  "data": [{
    "type": "artifactGroup",
    "id": "com.example.repository"
  }, {
    "type": "artifactGroup",
    "id": "com.yahoo.elide"
  }]
}
```

## Adding More Data

Now that we have an API that returns data, let’s add some more interesting behavior. Let’s update `ArtifactGroup`, and
add the `ArtifactProduct` and `ArtifactVersion` classes–which will be the `<artifactId>` and `<version>` tags
respectively.

{% include code_example example="01-more-beans" %}

We add the missing fields to `ArtifactGroup` since we anticipate the user will want to add some informative metadata to help
users find the products and artifacts they are interested in. If we restart the API and request `/artifactGroup` we’ll
see the other metadata we just added.

```json
{
  "data": [{
    "type": "artifactGroup",
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
    "type": "artifactGroup",
    "id": "com.yahoo.elide",
    "attributes": {
      "commonName": "Elide",
      "description": "The magical library powering this project"
    },
    "relationships": {
      "products": {
        "data": [{
          "type": "artifactProduct",
          "id": "elide-core"
        }, {
          "type": "artifactProduct",
          "id": "elide-standalone"
        }, {
          "type": "artifactProduct",
          "id": "elide-datastore-hibernate5"
        }]
      }
    }
  }]
}
```

So now we have an API that can display information for a full `<group>:<product>:<version>` set. We can fetch data from
our API in the following ways:

```
List groups:                 /artifactGroup/
Show a group:                /artifactGroup/<group id>
List a group's products:     /artifactGroup/<group id>/products/
Show a product:              /artifactGroup/<group id>/products/<product id>
List a product's versions:   /artifactGroup/<group id>/products/<product id>/versions/
Show a version:              /artifactGroup/<group id>/products/<product id>/versions/<version id>
```

We can now fetch almost all of the data we would wish, but let’s clean it up a bit. Right now all of our data types are
prefixed with Artifact. This might make sense in Java so that we don’t have naming collisions with classes from other
libraries, however the consumers of our API do not care about naming collisions. We can control how Elide exposes our
classes by setting the type on our `@Include` annotations.

```java
@Include(type = "group")
@Entity
public class ArtifactGroup { ... }

@Include(type = "product")
@Entity
public class ArtifactProduct { ... }

@Include(type = "version")
@Entity
public class ArtifactVersion{ ... }
```

Now, instead of making a call to `http://localhost:8080/api/v1/artifactGroup` to fetch our data, we make a request to
`http://localhost:8080/api/v1/group`. Our API returns the same data as before, mostly. The types of our objects now
reflect our preferences from the `Include` annotations.

```json
{
    "data": [{
    "type": "group",
    "id": "com.example.repository",
    ...
  }, {
    "type": "group",
    "id": "com.yahoo.elide",
    ...
    "relationships": {
      "products": {
        "data": [{
          "type": "product",
          "id": "elide-core"
        }, ...]
      }
    }
  }]
}
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

[elide-demo]: https://github.com/clayreimann/elide-demo
[kotlin-blog]: https://github.com/DennisMcWherter/elide-example-blog-kotlin
[demo-schema]: /pages/resources/demo.sql
[logback-conf]: /pages/resources/logback.xml
