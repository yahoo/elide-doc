---
layout: guide
group: guide
title: Swagger 
version: 4
---

## Overview

Elide supports the generation of [Swagger](http://swagger.io/) documentation from Elide annotated beans.  Specifically, it generates a JSON document
conforming to the swagger specification that can be used by tools like Swagger UI (among others) to explore, understand, and compose queries against
your Elide API.

Only JSON-API endpoints are documented.  The GraphQL API schema can be explored directly with tools like [Graphiql](https://github.com/graphql/graphiql).

## Features Supported

* **JaxRS Endpoint** - Elide ships with a customizable JaxRS endpoint that can publish one or more swagger documents.
* **Path Discovery** - Given a set of entities to explore, Elide will generate the minimum, cycle-free, de-duplicated set of URL paths in the swagger document.
* **Filter by Primitive Attributes** - All _GET_ requests on entity collections include filter parameters for each primitive attribute.
* **Prune Fields** - All _GET_ requests support JSON-API sparse fields query parameter.
* **Include Top Level Relationships** - All _GET_ requests support the ability to include direct relationships.
* **Sort by Attribute** - All _GET_ requests support sort query parameters.
* **Pagination** - All _GET_ requests support pagination query parameters.
* **Permission Exposition** - Elide permissions are exported as documentation for entity schemas.
* **Attribute Properties** - The _required_, _readOnly_, _example_ and _value_ fields are extracted from `ApiModelProperty` annotations.  

## Getting Started

### Maven

If you are not using [Elide Spring Starter][elide-spring] or [Elide Standalone][elide-standalone] (which package swagger as a dependency), you will need to pull in the following elide dependencies :

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

### Spring Boot Configuration

If you are using [Elide Spring Autoconfigure](https://github.com/yahoo/elide/tree/master/elide-spring/elide-spring-boot-autoconfigure), you can override the `Swagger` bean:

```java
    @Bean
    public Swagger buildSwagger(EntityDictionary dictionary, ElideConfigProperties settings) {
        Info info = new Info()
                .title(settings.getSwagger().getName())
                .version(settings.getSwagger().getVersion());

        SwaggerBuilder builder = new SwaggerBuilder(dictionary, info);

        Swagger swagger = builder.build().basePath(settings.getJsonApi().getPath());

        return swagger;
    }
```

The application yaml file has settings: 
 - to enable the swagger document endpoint 
 - to set the URL path for the swagger document endpoint
 - to set the API version number

```yaml
elide:
  swagger:
    path: /doc
    enabled: true
    version: "1.0"

```

### Elide Standalone Configuration

If you are using [Elide Standalone](https://github.com/yahoo/elide/tree/master/elide-standalone), you can extend `ElideStandaloneSettings` to configure swagger.  The `enableSwagger` function returns a map of Swagger documents keyed by a name for each document that will be exposed in the swagger document URL.


```java
    @Override
    public Map<String, Swagger> enableSwagger() {

        //Create a dictionary of the entities that will be exposed in swagger
        EntityDictionary dictionary = new EntityDictionary(new HashMap());
        dictionary.bindEntity(ArtifactGroup.class);
        dictionary.bindEntity(ArtifactProduct.class);
        dictionary.bindEntity(ArtifactVersion.class);

        //Title and version your service
        Info info = new Info().title("Test Service").version("1.0");

        //Build the swagger document with the base API path
        SwaggerBuilder builder = new SwaggerBuilder(dictionary, info);
        Swagger swagger = builder.build().basePath("/api/v1");

        //Return the map of swagger documents
        Map<String, Swagger> docs = new HashMap<>();
        docs.put("test", swagger);
        return docs;
    }
```

The code above exposes a single swagger document at the URL `/swagger/doc/test`.  To change the path where swagger will be exposed, override this function in `ElideStandaloneSettings`:

```java
    @Override
    public String getSwaggerPathSepc() {
        return "/mySwaggerPath/*";
    }
```

### Elide Library Configuration
If you are using Elide directly as a library (and not using Elide Standalone), follow these instructions:

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
SecurityRequirement oauthReq = new SecurityRequirement().requirement("myOauth");

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

### Attribute Properties

Elide extracts properties from the `ApiModelProperty` annotation and adds them to the swagger documentation.

```java
class Book {

    @ApiModelProperty(required = true)
    public String title;
}
```

Only the _required_, _value_, _example_, and _readOnly_ properties are extracted.  This is currently only supported for attributes on Elide models.

[elide-standalone]: https://github.com/yahoo/elide/tree/master/elide-standalone
[elide-spring]: https://github.com/yahoo/elide/tree/master/elide-spring/elide-spring-boot-starter
