---
layout: guide
group: guide
subtopic: true
title: JSON API
description: JSON API
version: 7
---

--------------------------

[JSON-API](https://jsonapi.org) is a specification for building REST APIs for CRUD (create, read, update, and delete) operations.  
Similar to GraphQL: 
*  It allows the client to control what is returned in the response payload.  
*  It provides a mechanism in the form of extensions (the [_Atomic Operations Extension and JSON Patch Extension_](#bulk-writes-and-complex-mutations)) that allows multiple mutations to the graph to occur in a single request.

Unlike GraphQL, the JSON-API specification spells out exactly how to perform common CRUD operations including complex graph mutations.  
JSON-API has no standardized schema introspection.  However, Elide adds this capability to any service by exporting 
an [OpenAPI](https://www.openapis.org) document (formerly known as [Swagger](https://swagger.io)).

The [JSON-API specification](https://jsonapi.org/format/) is the best reference for understanding JSON-API.  The following sections describe 
commonly used JSON-API features as well as Elide additions for filtering, pagination, sorting, and generation of OpenAPI documents.

## Hierarchical URLs
--------------------------

Elide generally follows the [JSON-API recommendations](http://jsonapi.org/recommendations/) for URL design.

There are a few caveats given that Elide allows developers control over how entities are exposed:

1. Some entities may only be reached through a relationship to another entity.  Not every entity is _rootable_.
1. The root path segment of URLs are by default the name of the class (lowercase).  This can be overridden.
1. Elide allows relationships to be nested arbitrarily deep in URLs.
1. Elide currently requires all individual entities to be addressed by ID within a URL.  For example, consider a model with an 
article and a singular author which has a singular address.   While unambiguous, the following is *not* allowed: `/articles/1/author/address`.  
Instead, the author must be fully qualified by ID: `/articles/1/author/34/address`

## Model Identifiers
--------------------------

Elide supports three mechanisms by which a newly created entity is assigned an ID:

1. The ID is assigned by the client and saved in the data store.
1. The client doesn't provide an ID and the data store generates one.
1. The client provides an ID which is replaced by one generated by the data store.  When using the Atomic Operations Extension or JSON Patch Extension, the client
must provide an ID or Local ID to identify objects which are both created and added to collections in other objects. However, in some instances
the server should have ultimate control over the ID that is assigned.  

Elide looks for the JPA `GeneratedValue` annotation to disambiguate whether or not
the data store generates an ID for a given data model. If the client also generated 
an ID during the object creation request, the data store ID overrides the client value.

### Matching newly created objects to IDs

When using the Atomic Operations Extension or JSON Patch Extension, Elide returns object entity bodies (containing newly assigned IDs) in 
the order in which they were created. The client can use this order to map the object created to its server assigned ID.

## Sparse Fields
--------------------------
JSON-API allows the client to limit the attributes and relationships that should be included in the response payload
for any given entity.  The _fields_ query parameter specifies the type (data model) and list of fields that should be included.

For example, to fetch the book collection but only include the book titles:

{% include code_example example='jsonapi-sparse' offset=2 %}

More information about sparse fields can be found [here](http://jsonapi.org/format/#fetching-sparse-fieldsets).

## Compound Documents 
--------------------------
JSON-API allows the client to fetch a primary collection of elements but also include their relationships or their 
relationship's relationships (arbitrarily nested) through compound documents.  The _include_ query parameter specifies
what relationships should be expanded in the document.

The following example fetches the book collection but also includes all of the book authors.  Sparse fields are used
to limit the book and author fields in the response:

{% include code_example example='jsonapi-include' offset=4 %}

More information about compound documents can be found [here](http://jsonapi.org/format/#document-compound-documents).

## Filtering
--------------------------

JSON-API is agnostic to filtering strategies.  The only recommendation is that servers and clients _should_
prefix filtering query parameters with the word 'filter'.

Elide supports multiple filter dialects and the ability to add new ones to meet the needs of developers or to evolve
the platform should JSON-API standardize them.  Elide's primary dialect is [RSQL](https://github.com/jirutka/rsql-parser).

### RSQL

[RSQL](https://github.com/jirutka/rsql-parser) is a query language that allows conjunction (and), disjunction (or), and parenthetic grouping
of Boolean expressions.  It is a superset of the [FIQL language](https://tools.ietf.org/html/draft-nottingham-atompub-fiql-00).

Because RSQL is a superset of FIQL, FIQL queries should be properly parsed.
RSQL primarily adds more friendly lexer tokens to FIQL for conjunction and disjunction: 'and' instead of ';' and 'or' instead of ','.
RSQL also adds a richer set of operators.
FIQL defines all String comparison operators to be case insensitive. Elide overrides this behavior making all operators case sensitive by default. For case insensitive queries, Elide introduces new operators.
#### Filter Syntax

Filter query parameters either look like: 
1. `filter[TYPE]` where 'TYPE' is the name of the data model/entity.   These are type specific filters and only apply to filtering collections of the given type.
1. `filter` with no type specified.   This is a global filter and can be used to filter across relationships (by performing joins in the persistence layer).

Any number of typed filter parameters can be specified provided the 'TYPE' is different for each parameter.  There can only be a single global filter for the entire
query.  Typed filters can be used for any collection returned by Elide.  Global filters can only be used to filter root level collections.

The value of any query parameter is a RSQL expression composed of predicates.  Each predicate contains an attribute of the data model or a related data model,
an operator, and zero or more comparison values.

Filter attributes can be:
* In the data model itself
* In another related model traversed through to-one or to-many relationships
* Inside an object or nested object hierarchy

To join across relationships or drill into nested objects, the attribute name is prefixed by one or more relationship or field names separated by period ('.').  For example, 'author.books.price.total' references all of the author's books with a price having a particular total value.

#### Typed Filter Examples

Return all the books written by author '1' with the genre exactly equal to 'Science Fiction':

`/author/1/book?filter[book]=genre=='Science Fiction'`

Return all the books written by author '1' with the genre exactly equal to 'Science Fiction' _and_ the title starts with 'The' _and_ whose total price is greater than 100.00:

`/author/1/book?filter[book]=genre=='Science Fiction';title==The*;price.total>100.00`

Return all the books written by author '1' with the publication date greater than a certain time _or_ the genre _not_ 'Literary Fiction'
or 'Science Fiction':

`/author/1/book?filter[book]=publishDate>1454638927411,genre=out=('Literary Fiction','Science Fiction')`

Return all the books whose title contains 'Foo'.  Include all the authors of those books whose name does not equal 'Orson Scott Card':

`/book?include=authors&filter[book]=title==*Foo*&filter[author]=name!='Orson Scott Card'`

#### Global Filter Examples

Return all the books with an author whose name is 'Null Ned' and whose title is 'Life with Null Ned':

`/book?filter=authors.name=='Null Ned';title=='Life with Null Ned'`

#### Operators

The following RSQL operators are supported:

|Operator          |Description                                                                                                                                                                                        |
|------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|`=in=`            | Evaluates to true if the attribute exactly matches any of the values in the list. (Case Sensitive)                                                                                                |
|`=ini=`           | Evaluates to true if the attribute exactly matches any of the values in the list. (Case Insensitive)                                                                                              |
|`=out=`           | Evaluates to true if the attribute does not match any of the values in the list. (Case Sensitive)                                                                                                 |
|`=outi=`          | Evaluates to true if the attribute does not match any of the values in the list. (Case Insensitive)                                                                                               |
|`==ABC*`          | Similar to SQL `like 'ABC%'`. (Case Sensitive)                                                                                                                                                    |
|`==*ABC`          | Similar to SQL `like '%ABC'`. (Case Sensitive)                                                                                                                                                    |
|`==*ABC*`         | Similar to SQL `like '%ABC%'`. (Case Sensitive)                                                                                                                                                   |
|`=ini=ABC*`       | Similar to SQL `like 'ABC%'`. (Case Insensitive)                                                                                                                                                  |
|`=ini=*ABC`       | Similar to SQL `like '%ABC'`. (Case Insensitive)                                                                                                                                                  |
|`=ini=*ABC*`      | Similar to SQL `like '%ABC%'`. (Case Insensitive)                                                                                                                                                 |
|`=isnull=true`    | Evaluates to true if the attribute is `null`.                                                                                                                                                     |
|`=isnull=false`   | Evaluates to true if the attribute is not `null`.                                                                                                                                                 |
|`=lt=`            | Evaluates to true if the attribute is less than the value.                                                                                                                                        |
|`=gt=`            | Evaluates to true if the attribute is greater than the value.                                                                                                                                     |
|`=le=`            | Evaluates to true if the attribute is less than or equal to the value.                                                                                                                            |
|`=ge=`            | Evaluates to true if the attribute is greater than or equal to the value.                                                                                                                         |
|`=isempty=`       | Determines if a collection is empty or not.                                                                                                                                                       |
|`=between=`       | Determines if a model attribute is >= and <= the two provided arguments.                                                                                                                          |
|`=notbetween=`    | Negates the between operator.                                                                                                                                                                     |
|`=hasmember=`     | Determines if a collection contains a particular element. This can be used to evaluate that an attribute across a to-many association has a `null` value present by using `=hasmember=null`.      |
|`=hasnomember=`   | Determines if a collection does not contain a particular element.                                                                                                                                 |
|`=subsetof=`      | Determines if a collection is a subset of the values in the list. Meaning all the elements of the collection are in the provided values. Note that an empty set is a subset of every set.         |
|`=notsubsetof=`   | Determines if a collection is not a subset of the values in the list.                                                                                                                             |
|`=supersetof=`    | Determines if a collection is a superset of the values in the list. Meaning all the elements in the provided values are in the collection.                                                        |
|`=notsupersetof=` | Determines if a collection is not a superset of the values in the list.                                                                                                                               |
{:.table}

The operators `hasmember`, `hasnomember`, `subsetof`, `notsubsetof`, `supersetof`, `notsupersetof` can be applied to collections (book.awards) or across to-many relationships (book.authors.name).

##### FIQL Default Behaviour
By default, the FIQL operators =in=,=out=,== are case sensitive. This can be reverted to case insensitive by changing the case sensitive strategy:
```java
@Configuration
public class ElideConfiguration {
    @Bean
    public JsonApiSettingsBuilderCustomizer jsonApiSettingsBuilderCustomizer() {
        return builder -> builder
            .joinFilterDialect(new RSQLFilterDialect(dictionary), new CaseSensitivityStrategy.FIQLCompliant())
            .subqueryFilterDialect(new RSQLFilterDialect(dictionary), new CaseSensitivityStrategy.FIQLCompliant());
    }
}
```


#### Values & Type Coercion
Values are specified as URL encoded strings.  Elide will type coerce them into the appropriate primitive 
data type for the attribute filter.

#### Attribute arguments.

Some data stores like the Aggregation Store support parameterized model attributes.  Parameters can be included in a filter predicate with the following syntax:

`field[arg1:value1][arg2:value2]`

Argument values must be URL encoded.  There is no limit to the number of arguments provided in this manner.

## Pagination
--------------------------

Elide supports:
1. Paginating a collection by row offset and limit.
2. Paginating a collection by page size and number of pages.
3. Returning the total size of a collection visible to the given user.
4. Returning a _meta_ block in the JSON-API response body containing metadata about the collection or individual resources.
5. A simple way to control: 
  * the availability of metadata 
  * the number of records that can be paginated

### Syntax
Elide allows pagination of the primary collection being returned in the response via the _page_ query parameter.

The _rough_ BNF syntax for the _page_ query parameter is:
```
<QUERY> ::= 
     "page" "[" "size" "]" "=" <INTEGER>
   | "page" "[" "number" "]" "=" <INTEGER>
   | "page" "[" "limit" "]" "=" <INTEGER>
   | "page" "[" "offset" "]" "=" <INTEGER>
   | "page" "[" "totals" "]"
```

Legal combinations of the _page_ query params include:
1. size
1. number
1. size & number
1. size & number & totals
1. offset
1. limit
1. offset & limit
1. offset & limit & totals

### Meta Block
Whenever a _page_ query parameter is specified, Elide will return a _meta_ block in the
JSON-API response that contains:
1. The page _number_
2. The page size or _limit_
3. The total number of pages (_totalPages_) in the collection
4. The total number of records (_totalRecords_) in the collection.

The values for _totalPages_ and _totalRecords_ are only returned if the _page[totals]_ 
parameter was specified in the query.

### Example

Paginate the book collection starting at the 4th record.  Include no more than 2 books per page.
Include the total size of the collection in the _meta block_:

{% include code_example example='jsonapi-paginate' offset=6 %}

## Sorting
--------------------------

Elide supports:
1.  Sorting a collection by any model attribute.
2.  Sorting a collection by multiple attributes at the same time in either ascending or descending order.
3.  Sorting a collection by an attribute of another model connected via one or more to-one relationships.

### Syntax
Elide allows sorting of the primary collection being returned in the response via the _sort_ query parameter.

The _rough_ BNF syntax for the _sort_ query parameter is:
```
<QUERY> ::= "sort" "=" <LIST_OF_SORT_SPECS>

<LIST_OF_SORT_SPECS> = <SORT_SPEC> | <SORT_SPEC> "," <LIST_OF_SORT_SPECS>

<SORT_SPEC> ::= "+|-"? <PATH_TO_ATTRIBUTE>

<PATH_TO_ATTRIBUTE> ::= <RELATIONSHIP> <PATH_TO_ATTRIBUTE> | <ATTRIBUTE>

<RELATIONSHIP> ::= <TERM> "."

<ATTRIBUTE> ::= <TERM>
```

### Sort By ID

The keyword _id_ can be used to sort by whatever field a given entity uses as its identifier.

### Example

Sort the collection of author 1's books in descending order by the book's publisher's name:

{% include code_example example='jsonapi-sort' offset=8 %}


## Bulk Writes And Complex Mutations
--------------------------

JSON-API supports a mechanism for [extensions](http://jsonapi.org/extensions/).

Elide supports the [Atomic Operations Extension](https://jsonapi.org/ext/atomic/) which allows multiple mutation operations (create, delete, update) to be bundled together in as single request. Elide also supports the older deprecated [JSON Patch Extension](https://github.com/json-api/json-api/blob/9c7a03dbc37f80f6ca81b16d444c960e96dd7a57/extensions/jsonpatch/index.md) which offers similar functionality.

Elide supports these extensions because it allows complex & bulk edits to the data model in the context of a single transaction.

The extensions require a different Media Type to be specified for the `Content-Type` and `Accept` headers when making the request.

|Extension         |Media Type                                                       |
|------------------|-----------------------------------------------------------------|
|Atomic Operations | `application/vnd.api+json;ext="https://jsonapi.org/ext/atomic"` |
|JSON Patch        | `application/vnd.api+json;ext=jsonpatch`                        |
{:.table}

Elide's Atomic Operations and JSON Patch extension support requires that all resources have assigned IDs specified using the `id` member when fixing up relationships. For newly created objects, if the IDs are generated by the server, a client generated Local ID can be specified using the `lid` member. Client generated IDs should be a UUID as described in [RFC 4122](https://datatracker.ietf.org/doc/html/rfc4122.html).

### Atomic Operations

The following Atomic Operations request creates an author (Ernest Hemingway), some of his books, and his book publisher in a single request:

{% include code_example example='jsonapi-atomic-operations-extension' offset=10 %}

### JSON Patch

The following JSON Patch request creates an author (Ernest Hemingway), some of his books, and his book publisher in a single request:

{% include code_example example='jsonapi-patch-extension' offset=10 %}

## Links
------------

JSON-API links are disabled by default. They can be enabled in `application.yaml`:

```yaml
elide:
  base-url: 'https://elide.io'
  json-api:
    enabled: true
    path: /json
    links:
      enabled: true
```

The `elide.json-api.links.enabled` property switches the feature on.  The `base-url` property provides the URL schema, host, and port your clients use to connect to your service.  The `path` property provides the route where the JSON-API controller is rooted.  All link URLs using the above configuration would be prefixed with 'https://elide.io/json'.

If `base-url` is not provided, Elide will generate the link URL prefix using the client HTTP request.

For Elide standalone, you can enable links by overriding `ElideStandaloneSettings` and configure the settings:

```java
public abstract class Settings implements ElideStandaloneSettings {
    @Override
    public String getBaseUrl() {
        return "https://elide.io";
    }

    @Override
    public JsonApiSettingsBuilder getJsonApiSettingsBuilder(EntityDictionary dictionary, JsonApiMapper mapper) {
        String jsonApiBaseUrl = getBaseUrl()
                + getJsonApiPathSpec().replace("/*", "")
                + "/";

        return ElideStandaloneSettings.super.getJsonApiSettingsBuilder(dictionary, mapper)
                .links(links -> links.enabled(true).jsonApiLinks(new DefaultJsonApiLinks(jsonApiBaseUrl)));
    }
}
```

Enabling JSON-API links will result in payload responses that look like:

```json
{
    "data": [
        {
            "type": "group",
            "id": "com.example.repository",
            "attributes": {
                "commonName": "Example Repository",
                "description": "The code for this project"
            },
            "relationships": {
                "products": {
                    "links": {
                        "self": "https://elide.io/api/v1/group/com.example.repository/relationships/products",
                        "related": "https://elide.io/api/v1/group/com.example.repository/products"
                    },
                    "data": [
                        
                    ]
                }
            },
            "links": {
                "self": "https://elide.io/api/v1/group/com.example.repository"
            }
        }
    ]
}
```

You can customize the links that are returned by registering your own implementation of `JsonApiLinks` with ElideSettings:

```java
public interface JsonApiLinks {
    Map<String, String> getResourceLevelLinks(PersistentResource var1);

    Map<String, String> getRelationshipLinks(PersistentResource var1, String var2);
}
```

## Meta Blocks
-------------------------------------

JSON-API supports returning non standard information in responses inside a [meta block](https://jsonapi.org/format/#document-meta).
Elide supports meta blocks in three scenarios:
1.  Document meta blocks are returned for any [pagination](#pagination) request.  
2.  The developer can customize the Document meta block for any collection query.
3.  The developer can customize a Resource meta block for any resource returned by Elide.

### Customizing the Document Meta Block

To customize the document meta block, add fields to the `RequestScope` object inside a [custom data store]({{site.baseurl}}/pages/guide/v{{ page.version }}/06-datastores.html#custom-stores):

```java
    @Override
    public <T> DataStoreIterable<T> loadObjects(EntityProjection projection, RequestScope scope) { 

        //Populates the JSON-API meta block with a new field, 'key':
        scope.setMetadataField("key", 123);

```

This would produce a JSON response like:

```json
{
    "data": [
        {
            "type": "widget",
            "id": "1"
        }
    ],
    "meta": {
        "key": 123
    }
}

```

### Customizing the Resource Meta Block

To customize the resource meta block, the resource model class must implement the `WithMetadata` interface:

```java
public interface WithMetadata {

    /**
     * Sets a metadata property for this request.
     * @param property
     * @param value
     */
    default void setMetadataField(String property, Object value) { //NOOP }

    /**
     * Retrieves a metadata property from this request.
     * @param property
     * @return An optional metadata property.
     */
    Optional<Object> getMetadataField(String property);

    /**
     * Return the set of metadata fields that have been set.
     * @return metadata fields that have been set.
     */
    Set<String> getMetadataFields();
}
```

For example, the following example model implements `WithMetadata`:

```java
@Include
public class Widget implements WithMetadata {
    static Map metadata = Map.of("key", 123);

    @Id
    private String id;

    @Override
    public Optional<Object> getMetadataField(String property) {
        return Optional.ofNullable(Widget.metadata.get(property));
    }

    @Override
    public Set<String> getMetadataFields() {
        return Widget.metadata.keySet();
    }
}
```

The models must be populated with at least one field for the meta block to be returned in the response.  These fields can also be populated in a [custom data store]({{site.baseurl}}/pages/guide/v{{ page.version }}/06-datastores.html#custom-stores) or [lifecycle hook]({{site.baseurl}}/pages/guide/v{{ page.version }}/02-data-model.html#lifecycle-hooks).  This would produce a JSON response like:


```json
{
    "data": [
        {
            "type": "widget",
            "id": "1",
            "meta": {
                "key": 123
            }
        }
    ]
}

```

## Type Serialization/Deserialization
-------------------------------------

Type coercion between the API and underlying data model has common support across JSON-API and GraphQL and is covered [here]({{site.baseurl}}/pages/guide/v{{ page.version }}/09-clientapis.html#type-coercion).

## OpenAPI
--------------------------

OpenAPI documents can be highly customized. The steps to customize this are documented [here]({{site.baseurl}}/pages/guide/v{{ page.version }}/13-openapi.html).

## Custom Error Responses
--------------------------

Configuring custom error responses is documented [here]({{site.baseurl}}/pages/guide/v{{ page.version }}/09-clientapis.html#custom-error-responses).
