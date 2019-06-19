---
layout: guide
group: guide
title: Swagger 
---

## Overview

Elide supports the generation of [Swagger](http://swagger.io/) documentation from Elide annotated beans.  Specifically, it generates a JSON document
conforming to the swagger specification that can be used by tools like Swagger UI (among others) to explore, understand, and compose queries against
your Elide API.

## Features Supported

* **JaxRS Endpoint** - Elide ships with a customizable JaxRS endpoint that can publish one or more swagger documents.
* **Path Discovery** - Given a set of entities to explore, Elide will generate the minimum, cycle-free, de-duplicated set of URL paths in the swagger document.
* **Filter by Primitive Attributes** - All _GET_ requests on entity collections include filter parameters for each primitive attribute.
* **Prune Fields** - All _GET_ requests support JSON-API sparse fields query parameter.
* **Include Top Level Relationships** - All _GET_ requests support the ability to include direct relationships.
* **Sort by Attribute** - All _GET_ requests support sort query parameters.
* **Pagination** - All _GET_ requests support pagination query parameters.
* **Permission Exposition** - Elide permissions are exported as documentation for entity schemas.

## Getting Started

### Maven

Pull in the following elide dependencies :

```
<dependency>
  <groupId>com.yahoo.elide</groupId>
  <artifactId>elide-swagger</artifactId>
</dependency>

<dependency>
  <groupId>com.yahoo.elide</groupId>
  <artifactId>elide-core</artifactId>
</dependency>

```

Pull in swagger core :

```
<dependency>
  <groupId>io.swagger</groupId>
  <artifactId>swagger-core</artifactId>
</dependency>
```

### Basic Setup

Create and initialize an entity dictionary.

```java
EntityDictionary dictionary = new EntityDictionary(Maps.newHashMap());

dictionary.bindEntity(Book.class);
dictionary.bindEntity(Author.class);
dictionary.bindEntity(Publisher.class);
```

Create a swagger info object.

```java
Info info = new Info().title("My Service").version("1.0");
```

Initialize a swagger builder.

```java
SwaggerBuilder builder = new SwaggerBuilder(dictionary, info);
```

Build the swagger document

```java
Swagger document = builder.build();
```

#### Convert Swagger to JSON

You can directly convert to JSON:

```java
String jsonOutput = SwaggerBuilder.getDocument(document);
```

#### Configure JAX-RS Endpoint

Or you can use the Swagger document directly to configure the [provided JAX-RS Endpoint](https://github.com/yahoo/elide/blob/master/elide-contrib/elide-swagger/src/main/java/com/yahoo/elide/contrib/swagger/resources/DocEndpoint.java):

```java
Map<String, Swagger> swaggerDocs = new HashMap<>();
docs.put("publishingModels", document)

//Dependency Inject the DocEndpoint JAX-RS resource
bind(docs).named("swagger").to(new TypeLiteral<Map<String, Swagger>>() { });
```

### Supporting OAuth

If you want swagger UI to acquire & use a bearer token from an OAuth identity provider, you can configure
the swagger document similar to:

```java
SecuritySchemeDefinition oauthDef = new OAuth2Definition().implicit(CONFIG_DATA.zuulAuthorizeUri());
SecurityRequirement oauthReq = new SecurityRequirement().requirement("myOuath");

SwaggerBuilder builder = new SwaggerBuilder(entityDictionary, info);
Swagger document = builder.build();
    .basePath("/my/url/path")
    .securityDefinition("myOauth", oauthDef)
    .security(oauthReq)
    .scheme(Scheme.HTTPS));
```

### Adding a global parameter

A query or header parameter can be added globally to all Elide API endpoints:

```java
HeaderParameter oauthParam = new HeaderParameter()
    .name("Authorization")
    .type("string")
    .description("OAuth bearer token")
    .required(false);

SwaggerBuilder crashBuilder = new SwaggerBuilder(dictionary, info)
    .withGlobalParameter(oauthParam);
```

### Adding a global response code

An HTTP response can be added globally to all Elide API endpoints:

```java
Response rateLimitedResponse = new Response().description("Too Many Requests");

SwaggerBuilder crashBuilder = new SwaggerBuilder(dictionary, info)
    .withGlobalResponse(429, rateLimitedResponse);
```

## Performance

### Path Generation

The Swagger UI is very slow when the number of generated URL paths exceeds a few dozen.  For large, complex data models, it is recommended to 
generate separate swagger documents for subgraphs of the model.  

```java
Set<Class<?>> entities = Sets.newHashSet(
    Book.class,
    Author.class,
    Publisher.class
);
 
SwaggerBuilder coreBuilder = new SwaggerBuilder(dictionary, info)
    .withExplicitClassList(entities);
```

In the above example, swagger will only generate paths that exclusively traverse the provided set of entities.  

### Document Size 

The size of the swagger document can be reduced significantly by limiting the number of filter operators that are used to generate query parameter
documentation.

```java
SwaggerBuilder crashBuilder = new SwaggerBuilder(dictionary, info)
   .withFilterOps(Sets.newHashSet(Operator.IN));
```

In the above example, filter query parameters are only generated for the _IN_ operator.
