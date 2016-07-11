---
layout: guide
group: guide
title: Filters
---

JSON-API 1.0 is agnostic to filtering strategies.  The only recommendation is that servers and clients _should_
prefix filtering query parameters with the word 'filter'.

Elide supports multiple filter dialects and the ability to add new ones to meet the needs of developers or to evolve
the platform should JSON-API standardize them.

# Supported Dialects

Elide supports two primary dialects - [RSQL](#rsql) and [basic](#basic).

# Filtering Multiple Types 

If multiple data models are referenced in a filter expression, there are two different approaches for how to handle them:

1. *Disjoint* - Filters for each model are disjoint and applied independently.  Whenever a collection of models is loaded from a `DataStore`, only 
the filters for that model are applied.
2. *Joined* - The `DataStore` attempts to join the referenced model tables into a single table and apply the filters globally on the joined table.

Each approach has advantages and disadvantages:
 
1. Disjoint filtering is fully compatible with pagination performed by the `DataStore`.   Joined filtering breaks pagination because the
cardinality of the resulting join is typically much larger than the requested collection.
2. Disjoint filtering allows all elements of compound documents (the primary collection _and_ the includes) to be filtered individually.
3. Joined filtering allows more precise control over what is returned from an individual collection of elements.
4. Joined filtering is not easy to support unless the underlying `DataStore` natively supports joins.  
5. Elide has full support for disjoint filtering.
6. Elide has limited support for joined filtering.  It is only supported today for filters applied to root 
collections - '/books' but not '/books/1/authors'. 

To better understand the differences, consider the following example.  Imagine a collection of two books with the titles 'Foo' and 'Foobar'.  Imagine 'Foo' was written by author 'A' and 'Foobar' was written by author 'B'. 

## Disjoint Filters 

The following RSQL query separates expression by type:

```
/book?include=authors&filter[book]=title==Foo*,filter[author]=name==A
```

It requests the collection of books and any related authors.  The collection
of books is filtered to only those whose title starts with 'Foo'.  The related
authors are filtered to only those whose name is 'A'.

It would return both books, but only a single author in the 'included' section:

```
{
  "data": [
  {
    "type": "book",
    "id": "1",
    "attributes": {
      "title": "Foo"
    },
    "relationships": {
      "authors": {
        "data": [{ "type": "author", "id": "1" }]
      },
    }
  }, {
    "type": "book",
    "id": "2",
    "attributes": {
      "title": "Foobar"
    },
    "relationships": {
      "authors": {
        "data": [{ "type": "author", "id": "2" }]
      },
    }
  }],
  "included": [
  {
    "type": "author",
    "id": "1",
    "attributes": {
      "name": "A",
    }
  }]
}
```

## Joined Filters 

The following RSQL query has a single expression for both types:
```
/book?include=authors&filter=title==Foo*;author.name==A
```

It requests the collection of books and any related authors where the book title
starts with 'Foo' __and__ the author's name is 'A'.

It would return a single book and a single author:

```
{
  "data": [
  {
    "type": "book",
    "id": "1",
    "attributes": {
      "title": "Foo"
    },
    "relationships": {
      "authors": {
        "data": [{ "type": "author", "id": "1" }]
      },
    }
  }],
  "included": [
  {
    "type": "author",
    "id": "1",
    "attributes": {
      "name": "A",
    }
  }]
}
```

## RSQL

[RSQL](https://github.com/jirutka/rsql-parser) is a query language that allows conjunction (and), disjunction (or), and parenthetic grouping
of boolean expressions.  It is a superset of the [FIQL language](https://tools.ietf.org/html/draft-nottingham-atompub-fiql-00).

Because RSQL is a superset of FIQL, FIQL queries should be properly parsed.
RSQL primarily adds more friendly lexer tokens to FIQL for conjunction and disjunction: 'and' instead of ';' and 'or' instead of ','.
RSQL also adds a richer set of operators.

### Disjoint Filter Syntax

To specify _disjoint filters_, the filter query parameters look like `filter[TYPE]` where 'TYPE' is the name of the data model/entity.  
Any number of filter parameters can be specified provided the 'TYPE' is different for each parameter.

The value of any query parameter is a RSQL expression composed of predicates.  Each predicate contains an attribute of the data model,
an operator, and zero or more comparison values.

### Disjoint Filter Examples

Return all the books written by author '1' with the genre exactly equal to 'Science Fiction':

`/author/1/book?filter[book]=genre=='Science Fiction'`

Return all the books written by author '1' with the genre exactly equal to 'Science Fiction' _and_ the title starts with 'The':

`/author/1/book?filter[book]=genre=='Science Fiction';title==The*`

Return all the books written by author '1' with the publication date greater than a certain time _or_ the genre _not_ 'Literary Fiction'
or 'Science Fiction':

`/author/1/book?filter[book]=publishDate>1454638927411,genre=out=('Literary Fiction','Science Fiction')`

Return all the books whose title contains 'Foo'.  Include all the authors of those books whose name does not equal 'Orson Scott Card':

`/book?include=authors&filter[book]=title==*Foo*,filter[author]=name!='Orson Scott Card'`

### Joined Filter Syntax

To specify _joined filters_, the query should have a _single_ query parameter 'filter'.  The value of the query parameter is a RSQL
expression composed of predicates.  Each predicate contains a '.' separated path to a data model attribute, an operator, and zero or more
comparison values.

The attributes referenced in the expression are relative to the collection requested in the URL.   If '/books' is the URL
path, then attributes can be:

1. From the 'book' data model: 'genre', 'title', etc.
2. From another data model that can be reached by an association of 'book': 'author.name', 'publisher.address.city', etc.

### Joined Filter Examples

Return all the books where the (genre is 'Science Fiction' _or_ the title starts with 'The') _and_ the books author is not 'Orson Scott Card':

`/book?filter=(genre=='Science Fiction',title==The*);author.name!='Orson Scott Card'`

### Operators

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

## Basic

Elide supports filters that are similar to the [JSON-API recommendations](http://jsonapi.org/recommendations/).
However, it extends them to support additional filter operator types and compound documents.
Filters are only supported on attributes with simple, primitive types.

### Disjoint Filter Syntax

Basic disjoint filtering has the following _rough_ BNF syntax for the query parameter and value:

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

#### Values
Values are simply a comma separated list of URL encoded strings.

#### Type Coercion
Values are type coerced into the appropriate primitive data type for the attribute filter.

#### Multiple Filters
When multiple filters are present for the same type, the filters are a logical ‘and’ for any collection with
that type.   Filters are type independent: any filters for type 'A' do *not* modify the results 
returned for a collection of type 'B'.

### Joined Filter Syntax

Joined filters have a nearly identical syntax to disjoint filters.  

The only difference is that the query parameter allows a '.' separated path to an attribute from a particular type.
If '/books' is the URL path, then attributes can be specified:

1. From the 'book' data model: 'genre', 'title', etc.
2. From another data model that can be reached by an association of 'book': 'author.name', 'publisher.address.city', etc.

### Operators
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

### Disjoint Filter Examples

Return all the books written by author '1' with the genre exactly equal to 'Science Fiction':

`/author/1/book?filter[book.genre]=Science%20Fiction`

Return all the books written by author '1' with the genre exactly equal to 'Science Fiction' _and_ the title starts with 'The':

`/author/1/book?filter[book.genre]=Science%20Fiction,filter[book.title][prefix]=The`

Return all the books written by author '1' with the publication date greater than a certain time _and_ the genre _not_ 'Literary Fiction'
or 'Science Fiction':

`/author/1/book?filter[book.publishDate][gt]=1454638927411,filter[book.genre][not]=Literary%20Fiction,Science%20Fiction`

Return all the books whose title contains 'Foo'.  Include all the authors of those books whose name does not equal 'Orson Scott Card':

`/book?include=authors&filter[book.title][infix]=Foo,filter[author.name][not]=Orson%20Scott%20Card`

### Joined Filter Examples

Return all the books where the title starts with 'The' _and_ the books author is not 'Orson Scott Card':

`/book?filter[book.title][prefix]=The,filter[book.author.name][not]=Orson%20Scott%20Card`

# Enabling/Disabling Dialects 

Elide supports multiple dialects enabled simultaneously.  They are applied in the order in which they were enabled until one dialect successfully parses
the entire set of filter query parameters.

If no dialects are explicitly enabled, Basic filtering is enabled by default.

Dialects are enabled when constructing the `Elide` object with an `ElideBuilder` as follows:

```
return new Elide.Builder(dataStore)
                        .withAuditLogger(auditLogger)
                        .withJoinFilterDialect(joinFilterDialect)
                        .withSubqueryFilterDialect(subqueryFilterDialect)
                        .withEntityDictionary(dictionary)
                        .build();
```

The method `withJoinFilterDialect` enables a filter dialect that supports [joined filter expressions](#joined-filters) by adding it to the
list of supported join filter dialects.

The method `withSubqueryFilterDialect` enables a filter dialect that supports [disjoint filter expressions](#disjoint-filters) by adding
it to the list of supported subquery filter dialects.

# Adding New Dialects

New dialects can be created by implementing one or both of the following interfaces.

For dialects that parse [joined filter expressions](#joined-filters):

```
public interface JoinFilterDialect {
    /**
     * @param path the URL path
     * @param filterParams the subset of query parameters that start with 'filter'
     * @return The root of an expression abstract syntax tree parsed from both the path and the query parameters.
     * @throws ParseException
     */
    public FilterExpression parseGlobalExpression(
            String path,
            MultivaluedMap<String, String> filterParams) throws ParseException;
}
```

For dialects that parse [disjoint filter expressions](#disjoint-filters):

```
public interface SubqueryFilterDialect {
    /**
     * @param path The URL path
     * @param filterParams The subset of queryParams that start with 'filter'
     * @return The root of an expression abstract syntax tree parsed from both the path and the query parameters.
     */
    public Map<String, FilterExpression> parseTypedExpression(String path, MultivaluedMap<String, String> filterParams)
            throws ParseException;
}
```
