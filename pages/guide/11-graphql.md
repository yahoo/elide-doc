---
layout: guide
group: guide
title: GraphQL API
---

# API Usage (Client-side info)

Graph APIs are an evolution of web service APIs that serve and manipulate data for mobile & web applications.
They have a number of characteristics that make them well suited to this task:
1.  Most notably, they present a **data model** as an entity relationship graph and **accompanying schema**.
    * A well defined model allows for a consistent view of the data and a centralized way to manipulate an instance of the model or to cache it.
    * The schema provides powerful introspection capabilities that can be used to build tools to help developers understand and navigate the model.
2.  The API allows the client to **fetch or mutate as much or as little information in single roundtrip** between client and server.  This also
    shrinks payload sizes and simplifies the process of schema evolution.
3.  There is a **well defined standard** for the API that fosters a community approach to development of supporting tools & best practices.

Elide supports the two most widely adopted standards for graph APIs: [JSON-API](http://jsonapi.org/) and [GraphQL](http://graphql.org/).

# GraphQL 

GraphQL is a language specification published by Facebook for constructing graph APIs.  The specification provides great flexibility
in API expression, but also little direction for best practices for common mutation operations.  For example, it is silent on how to:

* Create a new object and add it to an existing collection in the same operation.
* Create a set of related, composite objects (a subgraph) and connect it to an existing, persisted graph.
* Differentiate between deleting an object vs disassociating an object from a relationship (but not deleting it).
* Change the composition of a relationship to something different.
* Reference a newly created object inside other mutation operations.
* Perform any combination of the above edits together so they can happen atomically in a single request.

Elide offers an opinionated GraphQL API that addresses exactly how to do these things in a uniform way across your entire data model graph.

## API Structure

GraphQL splits its schema into two kinds of objects:
1.  **Query objects** which are used to compose queries and mutations
2.  **Input Objects** which are used to supply input data to mutations

The schema for both kinds of objects are derived from the entity relationship graph (defined by the JPA data model).
Both contain a set of attributes and relationships.  Attributes are properties of the entity.
Relationships are links to other entities in the graph.

### Input Objects

Input objects just contain attributes and relationship with names that directly match 
the property names in the JPA annotated model:

![GraphQL Input Object UML](/assets/images/graphql_input_object_uml.png){:class="img-responsive"}

### Query Objects

Query Objects are more complex given that queries have to support filtering, sorting,
and pagination and not simply describe data.  Elide's GraphQL structure for queries and mutations is depicted below:

![GraphQL Query Object UML](/assets/images/graphql_query_object_uml.png){:class="img-responsive"}

Every GraphQL schema must define a root document which represents the root of the graph.
In Elide, entities can be marked if they are directly navigable from the root of the
graph. Elide’s GraphQL root documents consists of _relationships_ to these rootable entities.
Each relationship is named by its pluralized type name in the GraphQL root document.

All other non-rootable entities in our schema must be referenced through traversal of the
relationships in the entity relationship graph.

Every relationship is modeled the same way.  Elide adopts [Relay's pattern for pagination support](http://graphql.org/learn/pagination/).
Relationships are a collection of _edges_.  Each edge contains a _node_.  The _node_ is an instance of a
data model that is also a member of the relationship.   It contains attributes and its own set of relationships.

#### Relationship Arguments

In GraphQL, any property in the schema can take arguments.  Relationships in Elide have a standard
set of arguments that either constrain the edges fetched from a relationship or supply data to a mutation:

1. The **ids** parameter is a collection of node identifiers.  It is used to select one or more nodes from a relationship.
2. The **filter** parameter is used to build complex [RSQL](https://github.com/jirutka/rsql-parser) filter predicates that select zero or more nodes from a relationship.
3. The **sort** parameter is used to order a relationship's edges by one or more node attributes.
4. The parameters **offset** and **first** are used to paginate a relationship across multiple API requests.
5. The **op** argument describes the operation to perform on the relationship. When not provided, this argument
defaults to a FETCH operation—which simply reads the collection of edges.
6. The **data** parameter is provided for operations that mutate the collection (UPSERT and REPLACE), It contains
a list of input objects that match the data type of the relationship.

Entity attributes generally do not take arguments. However, attributes can be annotated as computed which allows
the data model to define any number of arguments that are passed to the resolver of that attribute.

#### Relationship Operations

Elide GraphQL relationships support five operations which can be broken into two groups: data operations and id operations.
The operations are separated into those that accept a _data_ argument and those that accept an _ids_ argument:


| Operation | Data | Ids |
| --------- |------|-----|
| Upsert    | ✓    | X   |
| Fetch     | X    | ✓   |
| Replace   | ✓    | X   |
| Remove    | X    | ✓   |
| Delete    | X    | ✓   |

--------------------------

1. The **FETCH** operation retrieves a set of objects. When a list of ids is specified, it will only extract the set of objects within the
relationship with matching ids.  If no ids are specified, then the entire collection of objects will be returned to the caller.
2. The **DELETE** operation fully deletes an object from the system.
3. The **REMOVE** operation removes a specified set (qualified by the _ids_ argument) of objects from a relationship. This allows the caller to remove
relationships between objects without being forced to fully delete the referenced objects.
4. The **UPSERT** operation behaves much like SQL’s MERGE.  Namely, if the object already exists (based on the provided
id) then it will be updated.  Otherwise, it will be created. In the case of updates, attributes that are not specified are left unmodified.
5. The **REPLACE** operation is intended to replace an entire relationship with the set of objects provided in the _data_ argument.
**REPLACE** can be though of an **UPSERT** followed by an implicit **REMOVE** of everything else that was previously in the collection that the client
has authorization to see & manipulate.

#### Map Data Types

GraphQL has no native support for a map data type.  If a JPA data model includes a map, Elide translates this to a list of key/value pairs in the GraphQL schema.

### Making Calls

All calls must be HTTP `POST` requests made to the root endpoint. This specific endpoint will depend on where you mount the provided servlet.
For example, if the servlet is mounted at `/graphql`, all requests should be sent as:

```
POST https://yourdomain.com/graphql
```

### Example Data Model

All subsequent query examples are based on the following data model including `Book`, `Author`, and `Publisher`:

{% include code_example example='graphql-data-model' offset=0 %}

### Filtering

Elide supports filtering relationships for any _FETCH_ operation by passing a [RSQL](https://github.com/jirutka/rsql-parser) expression in 
the _filter_ parameter for the relationship.  RSQL is a query language that allows conjunction (and), disjunction (or), and parenthetic grouping
of boolean expressions.  It is a superset of the [FIQL language](https://tools.ietf.org/html/draft-nottingham-atompub-fiql-00).

RSQL predicates can filter attributes in:
* The relationship model
* Another model joined to the relationship model through to-one relationships

To join across relationships, the attribute name is prefixed by one or more relationship names separated by period ('.')

#### Operators

The following RSQL operators are supported:

* `=in=` : Evaluates to true if the attribute exactly matches any of the values in the list.
* `=out=` : Evaluates to true if the attribute does not match any of the values in the list.
* `==ABC*` : Similar to SQL `like 'ABC%`.
* `==*ABC` : Similar to SQL `like '%ABC`.
* `==*ABC*` : Similar to SQL `like '%ABC%`.
* `=isnull=true` : Evaluates to true if the attribute is null
* `=isnull=false` : Evaluates to true if the attribute is not null
* `=lt=` : Evaluates to true if the attribute is less than the value.
* `=gt=` : Evaluates to true if the attribute is greater than the value.
* `=le=` : Evaluates to true if the attribute is less than or equal to the value.
* `=ge=` : Evaluates to true if the attribute is greater than or equal to the value.

#### Examples
* Filter books by title equal to 'abc' _and_ genre starting with 'Science':
  `"title=='abc';genre=='Science*'` 
* Filter books with a publication date greater than a certain time _or_ the genre is _not_ 'Literary Fiction'
or 'Sicence Fiction':
  `publishDate>1454638927411,genre=out=('Literary Fiction','Science Fiction')`
* Filter books by the publisher name contains XYZ:
  `publisher.name==*XYZ*`

### Pagination

Any relationship can be paginated by providing one or both of the following parameters:
1. **first** - The number of items to return per page.
2. **offset** - The number of items to skip.

#### Relationship Metadata

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

### Sorting

Any relationship can be sorted by attributes in:
* The relationship model
* Another model joined to the relationship model through to-one relationships

To join across relationships, the attribute name is prefixed by one or more relationship names separated by period ('.')

It is also possible to sort in either ascending or descending order by prepending
the attribute expression with a '+' or '-' character.  If no order character is provided, sort order defaults to ascending.

A relationship can be sorted by multiple attributes by seperating the attribute expressions by commas: ','.

### FETCH Examples

#### Fetch All Books

Include the id, title, genre, & language in the result.

{% include code_example example='fetch-all-books' offset=2 %}

#### Fetch Single Book

Fetches book 1.  The response includes the id, title, and authors.  
For each author, the response includes its id & name.

{% include code_example example='fetch-one-book' offset=4 %}

#### Filter All Books

Fetches the set of books that start with 'Libro U'.

{% include code_example example='filter-all-books' offset=6 %}

#### Paginate All Books

Fetches a single page of books (1 book per page), starting at the 2nd page.  
Also requests the relationship metadata.

{% include code_example example='fetch-books-paginated' offset=8 %}

#### Sort All Books

Sorts the collection of books first by their publisher id (descending) and then by the book id (ascending).

{% include code_example example='sort-all-books' offset=10 %}

### UPSERT Examples

#### Create and add new book to an author

Creates a new book and adds it to Author 1.
The author's id and list of newly created books is returned in the response. 
For each newly created book, only the title is returned.

{% include code_example example='upsert-and-add' offset=12 %}

#### Update the title of an existing book

Updates the title of book 1 belonging to author 1.
The author's id and list of updated books is returned in the response. 
For each updated book, only the title is returned.

{% include code_example example='upsert-to-modify' offset=14 %}

### DELETE Examples

#### Delete a Book

Deletes books 1 and 2.  The id and title of the deleted books is returned in the response.

{% include code_example example='delete-multiple' offset=16 %}

# JSON-API 

[JSON-API](jsonapi.org) is a specification for building REST APIs for CRUD (create, read, update, and delete) operations.  
Similar to graphQL: 
*  It allows the client to control what is returned in the response payload.  
*  It also offered an API extension (the _patch extension_) that allowed multiple mutations to the graph to occur in a single request.

Unlike graphQL, it is more structured - laying out how to perform common API operations.  

Also unlike graphQL, it has no standardized API introspection.  However, Elide adds this capability to any service by exporting 
an [Open API Initiative](www.openapis.org) document (formerly known as [Swagger](swagger.io)).

The [json-api specification](http://jsonapi.org/format/) is the best reference for understanding JSON-API.  The following sections describe Elide additions
for filtering, pagination, sorting, and swagger.

## Filtering

JSON-API 1.0 is agnostic to filtering strategies.  The only recommendation is that servers and clients _should_
prefix filtering query parameters with the word 'filter'.

Elide supports multiple filter dialects and the ability to add new ones to meet the needs of developers or to evolve
the platform should JSON-API standardize them.

### Supported Dialects

Elide supports two primary dialects - [RSQL](#rsql) and [basic](#basic).

### RSQL

[RSQL](https://github.com/jirutka/rsql-parser) is a query language that allows conjunction (and), disjunction (or), and parenthetic grouping
of boolean expressions.  It is a superset of the [FIQL language](https://tools.ietf.org/html/draft-nottingham-atompub-fiql-00).

Because RSQL is a superset of FIQL, FIQL queries should be properly parsed.
RSQL primarily adds more friendly lexer tokens to FIQL for conjunction and disjunction: 'and' instead of ';' and 'or' instead of ','.
RSQL also adds a richer set of operators.

#### RSQL Filter Syntax

To specify _disjoint filters_, the filter query parameters look like `filter[TYPE]` where 'TYPE' is the name of the data model/entity.  
Any number of filter parameters can be specified provided the 'TYPE' is different for each parameter.

The value of any query parameter is a RSQL expression composed of predicates.  Each predicate contains an attribute of the data model,
an operator, and zero or more comparison values.

#### RSQL Filter Examples

Return all the books written by author '1' with the genre exactly equal to 'Science Fiction':

`/author/1/book?filter[book]=genre=='Science Fiction'`

Return all the books written by author '1' with the genre exactly equal to 'Science Fiction' _and_ the title starts with 'The':

`/author/1/book?filter[book]=genre=='Science Fiction';title==The*`

Return all the books written by author '1' with the publication date greater than a certain time _or_ the genre _not_ 'Literary Fiction'
or 'Science Fiction':

`/author/1/book?filter[book]=publishDate>1454638927411,genre=out=('Literary Fiction','Science Fiction')`

Return all the books whose title contains 'Foo'.  Include all the authors of those books whose name does not equal 'Orson Scott Card':

`/book?include=authors&filter[book]=title==*Foo*&filter[author]=name!='Orson Scott Card'`

#### RSQL Operators

The following RSQL operators are supported:

* `=in=` : Evaluates to true if the attribute exactly matches any of the values in the list.
* `=out=` : Evaluates to true if the attribute does not match any of the values in the list.
* `==ABC*` : Similar to SQL `like 'ABC%`.
* `==*ABC` : Similar to SQL `like '%ABC`.
* `==*ABC*` : Similar to SQL `like '%ABC%`.
* `=isnull=true` : Evaluates to true if the attribute is null
* `=isnull=false` : Evaluates to true if the attribute is not null
* `=lt=` : Evaluates to true if the attribute is less than the value.
* `=gt=` : Evaluates to true if the attribute is greater than the value.
* `=le=` : Evaluates to true if the attribute is less than or equal to the value.
* `=ge=` : Evaluates to true if the attribute is greater than or equal to the value.

### Basic 

Elide supports filters that are similar to the [JSON-API recommendations](http://jsonapi.org/recommendations/).
However, it extends them to support additional filter operator types and compound documents.
Filters are only supported on attributes with simple, primitive types.

#### Basic Filter Syntax

Basic filtering has the following _rough_ BNF syntax for the query parameter and value:

```
<QUERY> ::= 
     "filter" "[" <TYPE> "." <ATTRIBUTE> "]" "=" <VALUES>
   | "filter" "[" <TYPE> "." <ATTRIBUTE> "]" "[in]" "=" <VALUES> 
   | "filter" "[" <TYPE> "." <ATTRIBUTE> "]" "[not]" "=" <VALUES> 
   | "filter" "[" <TYPE> "." <ATTRIBUTE> "]" "[prefix]" "=" <VALUE> 
   | "filter" "[" <TYPE> "." <ATTRIBUTE> "]" "[postfix]" "=" <VALUE> 
   | "filter" "[" <TYPE> "." <ATTRIBUTE> "]" "[infix]" "=" <VALUE> 
   | "filter" "[" <TYPE> "." <ATTRIBUTE> "]" "[isnull]"
   | "filter" "[" <TYPE> "." <ATTRIBUTE> "]" "[notnull]"

<ATTRIBUTE> ::= <TERM>
<TYPE> ::= <TERM>

<VALUE> ::= <URL_ENCODED_TERM> 
<VALUES> ::= <URL_ENCODED_TERM> | <URL_ENCODED_TERM> “,” <VALUES>
```

#### Basic Operators
Elide supports the following operators.  When an operator is not specified, Elide basic uses the `in` operator.

* `in` : Evaluates to true if the attribute exactly matches any of the values in the list.
* `not` : Evaluates to true if the attribute does not match any of the values in the list.
* `prefix` : Similar to SQL `like 'value%`.
* `postfix` : Similar to SQL `like '%value`.
* `infix` : Similar to SQL `like '%value%`.
* `isnull` : Evaluates to true if the attribute is null
* `notnull` : Evaluates to true if the attribute is not null
* `lt` : Evaluates to true if the attribute is less than the value.
* `gt` : Evaluates to true if the attribute is greater than the value.
* `le` : Evaluates to true if the attribute is less than or equal to the value.
* `ge` : Evaluates to true if the attribute is greater than or equal to the value.

#### Values
Values are simply a comma separated list of URL encoded strings.

#### Type Coercion
Values are type coerced into the appropriate primitive data type for the attribute filter.

#### Multiple Filters
When multiple filters are present for the same type, the filters are a logical ‘and’ for any collection with
that type.   Filters are type independent: any filters for type 'A' do *not* modify the results 
returned for a collection of type 'B'.

#### Basic Filter Examples

Return all the books written by author '1' with the genre exactly equal to 'Science Fiction':

`/author/1/book?filter[book.genre]=Science%20Fiction`

Return all the books written by author '1' with the genre exactly equal to 'Science Fiction' _and_ the title starts with 'The':

`/author/1/book?filter[book.genre]=Science%20Fiction&filter[book.title][prefix]=The`

Return all the books written by author '1' with the publication date greater than a certain time _and_ the genre _not_ 'Literary Fiction'
or 'Science Fiction':

`/author/1/book?filter[book.publishDate][gt]=1454638927411&filter[book.genre][not]=Literary%20Fiction,Science%20Fiction`

Return all the books whose title contains 'Foo'.  Include all the authors of those books whose name does not equal 'Orson Scott Card':

`/book?include=authors&filter[book.title][infix]=Foo&filter[author.name][not]=Orson%20Scott%20Card`

## Pagination

Elide supports:
1. Paginating a collection by row offset and limit.
2. Paginating a collection by page size and number of pages.
3. Returning the total size of a collection visible to the given user.
4. Returning a _meta_ block in the JSON-API response body containing metadata about the collection.
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

```
"meta": {
  "page": {
    "number":1,
    "totalRecords":20,
    "limit":2,"
    "totalPages":10
   }
}
```

## Sorting

Elide supports:
1.  Sorting a collection by any attribute of the collection's type.
2.  Sorting a collection by multiple attributes at the same time in either ascending or descending order.
3.  Sorting a collection by any attribute of a to-one relationship of the collection's type.  Multiple relationships can be traversed provided the path 
from the collection to the sorting attribute is entirely through to-one relationships.

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

## Swagger

Swagger documents can be highly customized.  As a result, they are not enabled by default and instead must be 
initialized through code.  The steps to do this are documented [here]({{site.baseurl}}/pages/guide/13-swagger.html).
