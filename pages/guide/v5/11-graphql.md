---
layout: guide
group: guide
subtopic: true
title: GraphQL
version: 5
---

--------------------------

[GraphQL](http://graphql.org/) is a language specification published by Facebook for constructing graph APIs.  The specification provides great flexibility
in API expression, but also little direction for best practices for common mutation operations.  For example, it is silent on how to:

* Create a new object and add it to an existing collection in the same operation.
* Create a set of related, composite objects (a subgraph) and connect it to an existing, persisted graph.
* Differentiate between deleting an object vs disassociating an object from a relationship (but not deleting it).
* Change the composition of a relationship to something different.
* Reference a newly created object inside other mutation operations.
* Perform any combination of the above edits together so they can happen atomically in a single request.

Elide offers an opinionated GraphQL API that addresses exactly how to do these things in a uniform way across your entire data model graph.

## JSON Envelope
--------------------------
Elide accepts GraphQL queries embedded in HTTP POST requests.  It follows the [convention defined by GraphQL](https://graphql.org/learn/serving-over-http/) for serving over HTTP.  Namely, ever GraphQL query is wrapped in a JSON envelope object with one required attribute and two optional attributes:
1. *query* - _Required_.  Contains the actual graphQL query.
2. *operationName* - Used if multiple operations are present in the same query.
3. *variables* - Contains a json object of key/value pairs where the keys map to variable names in the query and the values map to the variable values.

```json
{
    "query": "mutation myMutation($bookName: String $authorName: String) {book(op: UPSERT data: {id:2,title:$bookName}) {edges {node {id title authors(op: UPSERT data: {id:2,name:$authorName}) {edges {node {id name}}}}}}}",
    "variables": {
        "authorName": "John Setinbeck",
        "bookName": "Grapes of Wrath"
    }
}
```

The response is also a JSON payload:

```json
{
  "data": { ... },
  "errors": [ ... ]
}
```

The 'data' field contains the graphQL response object, and the 'errors' field (only present when they exist) contains one or more errors encountered when executing the query.  Note that it is possible to receive a 200 HTTP OK from Elide but also have errors in the query.

## API Structure
--------------------------

GraphQL splits its schema into two kinds of objects:
1.  **Query objects** which are used to compose queries and mutations
2.  **Input Objects** which are used to supply input data to mutations

The schema for both kinds of objects are derived from the entity relationship graph (defined by the JPA data model).
Both contain a set of attributes and relationships.  Attributes are properties of the entity.
Relationships are links to other entities in the graph.

### Input Objects

Input objects just contain attributes and relationship with names directly matching
the property names in the JPA annotated model:

![GraphQL Input Object UML](/assets/images/graphql_input_object_uml.png){:class="img-responsive"}

### Query Objects

Query Objects are more complex than Input Objects since they do more than simply describe data; they must
support filtering, sorting, and pagination.  Elide's GraphQL structure for queries and mutations is depicted below:

![GraphQL Query Object UML](/assets/images/graphql_query_object_uml.png){:class="img-responsive"}

Every GraphQL schema must define a root document which represents the root of the graph.
In Elide, entities can be marked if they are directly navigable from the root of the
graph. Elide’s GraphQL root documents consist of _relationships_ to these rootable entities.
Each root relationship is named by its pluralized type name in the GraphQL root document.

All other non-rootable entities in our schema must be referenced through traversal of the
relationships in the entity relationship graph.

Elide models relationships following [Relay's Connection pattern](http://graphql.org/learn/pagination/).
Relationships are a collection of graph _edges_.  Each edge contains a graph _node_.  The _node_ is an instance of a
data model which in turn contains its own attributes and set of relationships.

#### Relationship Arguments

In GraphQL, any property in the schema can take arguments.  Relationships in Elide have a standard
set of arguments that either constrain the edges fetched from a relationship or supply data to a mutation:

1. The **ids** parameter is a collection of node identifiers.  It is used to select one or more nodes from a relationship.
2. The **filter** parameter is used to build [RSQL](https://github.com/jirutka/rsql-parser) filter predicates that select zero or more nodes from a relationship.
3. The **sort** parameter is used to order a relationship's edges by one or more node attributes.
4. The parameters **offset** and **first** are used to paginate a relationship across multiple API requests.
5. The **op** argument describes the operation to perform on the relationship. When not provided, this argument
defaults to a FETCH operation which simply reads the collection of edges.
6. The **data** parameter is provided for operations that mutate the collection (UPSERT, UPDATE, and REPLACE), It contains
a list of input objects that match the data type of the relationship.  Each _data_ object can be a complex subgraph which contains
other objects through nested relationships.

Entity attributes generally do not take arguments.  

#### Relationship Operations

Elide GraphQL relationships support six operations which can be broken into two groups: data operations and id operations.
The operations are separated into those that accept a _data_ argument and those that accept an _ids_ argument:


| Operation | Data | Ids |
| --------- |------|-----|
| Upsert    | ✓    | X   |
| Update    | ✓    | X   |
| Fetch     | X    | ✓   |
| Replace   | ✓    | X   |
| Remove    | X    | ✓   |
| Delete    | X    | ✓   |
{:.table}

--------------------------

1. The **FETCH** operation retrieves a set of objects. When a list of ids is specified, it will only extract the set of objects within the
relationship with matching ids.  If no ids are specified, then the entire collection of objects will be returned to the caller.
2. The **DELETE** operation fully deletes an object from the system.
3. The **REMOVE** operation removes a specified set (qualified by the _ids_ argument) of objects from a relationship. This allows the caller to remove
relationships between objects without being forced to fully delete the referenced objects.
4. The **UPSERT** operation behaves much like SQL’s MERGE.  Namely, if the object already exists (based on the provided
id) then it will be updated.  Otherwise, it will be created. In the case of updates, attributes that are not specified are left unmodified.  If the _data_ argument contains a complex subgraph of nested objects, nested objects will also invoke **UPSERT**.
5. The **UPDATE** operation behaves much like SQL’s UPDATE.  Namely, if the object already exists (based on the provided
id) then it will be updated.  Attributes that are not specified are left unmodified.  If the _data_ argument contains a complex subgraph of nested objects, nested objects will also invoke **UPDATE**.
6. The **REPLACE** operation is intended to replace an entire relationship with the set of objects provided in the _data_ argument.
**REPLACE** can be thought of as an **UPSERT** followed by an implicit **REMOVE** of everything else that was previously in the collection that the client
has authorization to see & manipulate.

#### Map Data Types

GraphQL has no native support for a map data type.  If a JPA data model includes a map, Elide translates this to a list of key/value pairs in the GraphQL schema.

## Making Calls
--------------------------

All calls must be HTTP `POST` requests made to the root endpoint. This specific endpoint will depend on where you mount the provided servlet.
For example, if the servlet is mounted at `/graphql`, all requests should be sent as:

```
POST https://yourdomain.com/graphql
```

## Example Data Model

All subsequent query examples are based on the following data model including `Book`, `Author`, and `Publisher`:

{% include code_example example='graphql-data-model' offset=0 %}

## Filtering
--------------------------

Elide supports filtering relationships for any _FETCH_ operation by passing a [RSQL](https://github.com/jirutka/rsql-parser) expression in 
the _filter_ parameter for the relationship.  RSQL is a query language that allows conjunction (and), disjunction (or), and parenthetic grouping
of boolean expressions.  It is a superset of the [FIQL language](https://tools.ietf.org/html/draft-nottingham-atompub-fiql-00).
FIQL defines all String comparison operators to be case insensitive. Elide overrides this behavior making all operators case sensitive by default. For case insensitive queries, Elide introduces new operators.
RSQL predicates can filter attributes in:
* The relationship model
* Another model joined to the relationship model through to-one relationships

To join across relationships, the attribute name is prefixed by one or more relationship names separated by period ('.')

### Operators

The following RSQL operators are supported:

* `=in=` : Evaluates to true if the attribute exactly matches any of the values in the list. (Case Sensitive)
* `=ini=`: Evaluates to true if the attribute exactly matches any of the values in the list. (Case Insensitive)
* `=out=` : Evaluates to true if the attribute does not match any of the values in the list. (Case Sensitive)
* `=outi=` : Evaluates to true if the attribute does not match any of the values in the list. (Case Insensitive)
* `==ABC*` : Similar to SQL `like 'ABC%`. (Case Sensitive)
* `==*ABC` : Similar to SQL `like '%ABC`. (Case Sensitive)
* `==*ABC*` : Similar to SQL `like '%ABC%`. (Case Sensitive)
* `=ini=ABC*` : Similar to SQL `like 'ABC%`. (Case Insensitive)
* `=ini=*ABC` : Similar to SQL `like '%ABC`. (Case Insensitive)
* `=ini=*ABC*` : Similar to SQL `like '%ABC%`. (Case Insensitive)
* `=isnull=true` : Evaluates to true if the attribute is null
* `=isnull=false` : Evaluates to true if the attribute is not null
* `=lt=` : Evaluates to true if the attribute is less than the value.
* `=gt=` : Evaluates to true if the attribute is greater than the value.
* `=le=` : Evaluates to true if the attribute is less than or equal to the value.
* `=ge=` : Evaluates to true if the attribute is greater than or equal to the value.

### Examples
* Filter books by title equal to 'abc' _and_ genre starting with 'Science':
  `"title=='abc';genre=='Science*'` 
* Filter books with a publication date greater than a certain time _or_ the genre is _not_ 'Literary Fiction'
or 'Science Fiction':
  `publishDate>1454638927411,genre=out=('Literary Fiction','Science Fiction')`
* Filter books by the publisher name contains XYZ:
  `publisher.name==*XYZ*`

###### FIQL Default Behaviour
Not that from the above listed RSQL operators, the behavior of FIQL operators `=in=,=out=,==` are changed to Case Sensitive.  
To change it back to Case Insensitive Behavior, initialize RSQLFilterDialect with FIQL Case sensitive strategy.
```java
    @Bean
    @ConditionalOnMissingBean
    public Elide initializeElide(EntityDictionary dictionary,
            DataStore dataStore, ElideConfigProperties settings) {

        ElideSettingsBuilder builder = new ElideSettingsBuilder(dataStore)
                .withEntityDictionary(dictionary)
                .withDefaultMaxPageSize(settings.getMaxPageSize())
                .withDefaultPageSize(settings.getPageSize())
                .withJoinFilterDialect(new RSQLFilterDialect(dictionary), new CaseSensitivityStrategy.FIQLCompliant())
                .withSubqueryFilterDialect(new RSQLFilterDialect(dictionary), new CaseSensitivityStrategy.FIQLCompliant())
                .withAuditLogger(new Slf4jLogger())
                .withISO8601Dates("yyyy-MM-dd'T'HH:mm'Z'", TimeZone.getTimeZone("UTC"));

        return new Elide(builder.build());
    }
```

## Pagination
--------------------------

Any relationship can be paginated by providing one or both of the following parameters:
1. **first** - The number of items to return per page.
2. **offset** - The number of items to skip.

### Relationship Metadata

Every relationship includes information about the collection (in addition to a list of edges) 
that can be requested on demand:

1. **endCursor** - The last record offset in the current page (exclusive).
2. **startCursor** - The first record offset in the current page (inclusive).
3. **hasNextPage** - Whether or not more pages of data exist.
4. **totalRecords** - The total number of records in this relationship across all pages.

These properties are contained within the _pageInfo_ structure:

```
{
  pageInfo {
    endCursor
    startCursor
    hasNextPage
    totalRecords
  }
}
```

## Sorting
--------------------------

Any relationship can be sorted by attributes in:
* The relationship model
* Another model joined to the relationship model through to-one relationships

To join across relationships, the attribute name is prefixed by one or more relationship names separated by period ('.')

It is also possible to sort in either ascending or descending order by prepending
the attribute expression with a '+' or '-' character.  If no order character is provided, sort order defaults to ascending.

A relationship can be sorted by multiple attributes by separating the attribute expressions by commas: ','.

## Model Identifiers
--------------------------

Elide supports three mechanisms by which a newly created entity is assigned an ID:

1. The ID is assigned by the client and saved in the data store.
1. The client doesn't provide an ID and the data store generates one.
1. The client provides an ID which is replaced by one generated by the data store.  When using _UPSERT_, the client
must provide an ID to identify objects which are both created and added to collections in other objects.  However, in some instances
the server should have ultimate control over the ID that is assigned.  

Elide looks for the JPA `GeneratedValue` annotation to disambiguate whether or not
the data store generates an ID for a given data model.   If the client also generated 
an ID during the object creation request, the data store ID overrides the client value.

### Matching newly created objects to IDs

When using _UPSERT_, Elide returns object entity bodies (containing newly assigned IDs) in 
the order in which they were created - assuming all the entities were newly created (and not mixed
with entity updates in the request).  The client can use this order to map the object created to its server
assigned ID.

## FETCH Examples
--------------------------

### Fetch All Books

Include the id, title, genre, & language in the result.

{% include code_example example='fetch-all-books' offset=2 %}

### Fetch Single Book

Fetches book 1.  The response includes the id, title, and authors.  
For each author, the response includes its id & name.

{% include code_example example='fetch-one-book' offset=4 %}

### Filter All Books

Fetches the set of books that start with 'Libro U'.

{% include code_example example='filter-all-books' offset=6 %}

### Paginate All Books

Fetches a single page of books (1 book per page), starting at the 2nd page.  
Also requests the relationship metadata.

{% include code_example example='fetch-books-paginated' offset=8 %}

### Sort All Books

Sorts the collection of books first by their publisher id (descending) and then by the book id (ascending).

{% include code_example example='sort-all-books' offset=10 %}

### Schema Introspection 

Fetches the entire list of data types in the GraphQL schema.

{% include code_example example='schema-introspection' offset=12 %}

## UPSERT Examples
--------------------------

### Create and add new book to an author

Creates a new book and adds it to Author 1.
The author's id and list of newly created books is returned in the response. 
For each newly created book, only the title is returned.

{% include code_example example='upsert-and-add' offset=14 %}

### Update the title of an existing book

Updates the title of book 1 belonging to author 1.
The author's id and list of updated books is returned in the response. 
For each updated book, only the title is returned.

{% include code_example example='upsert-to-modify' offset=16 %}

## UPDATE Examples
--------------------------

Updates author 1's name and simultaneously updates the titles of books 2 and 3.

{% include code_example example='update-graph' offset=18 %}

## DELETE Examples
--------------------------

Deletes books 1 and 2.  The id and title of the remaining books are returned in the response.

{% include code_example example='delete-multiple' offset=20 %}

## REMOVE Example
--------------------------

Removes books 1 and 2 from author 1.  Author 1 is returned with the remaining books.

{% include code_example example='remove-multiple' offset=22 %}

## REPLACE Example
--------------------------

Replaces the set of authors for _every_ book with the set consisting of:
* An existing author (author 1)
* A new author

The response includes the complete set of books (id & title) and their new authors (id & name).

{% include code_example example='replace-multiple' offset=24 %}

## Type Serialization/Deserialization
-------------------------------------

Type coercion between the API and underlying data model has common support across JSON-API and GraphQL and is covered [here](https://elide.io/pages/guide/v{{ page.version }}/09-clientapis.html#type-coercion).

