---
layout: guide
group: guide
title: Performance 
---

## N+1 Problem

### Overview
The N+1 problem is a performance issue where an ORM issues a large number of database queries to fetch a parent/child relationship.  The ORM issues a single query to hydrate the parent and then _N_ queries to hydrate the children.

Most ORMs solve this problem by providing a number of different fetching strategies that are enabled when a proxy object or collection is hydrated.  These strategies fall into one of two categories:

1. A join is used to fetch both the parent and the children in a single query.  The ORM populates its session cache with all entities fetched in the join.  Joining works well for fetching singular relationships.  It is important to note that a singular join that fetches an entire subgraph (spanning multiple relationships) is impractical and would break row based pagination (offset & limit).  Furthermore, large joins put considerable memory stress on the ORM server.  
2. Instead of a single query per element of a collection, the number of queries is reduced by fetching multiple children in fewer queries.

These strategies may or not be available to the developer depending on how the ORM is leveraged.  If the developer interacts with a proxy object directly, all fetch strategies are available.  However, the SQL queries generated from proxy objects cannot be customized with additional filters, sorting, or pagination.

Alternatively, the developer can have complete control over the query by writing JPQL or Criteria queries.  However, only join fetching is available through these APIs.

### Solution
Because Elide has to work well under a wide variety of circumstances, it has adopted a hybrid solution for ORM based data stores.

Whenever Elide traverses a to-one relationship, it returns the ORM proxy object directly.  In most cases, these relationships should already exist inside the session and result in no extra database queries.

Whenever Elide traverses a to-many relationship, it returns the ORM collection proxy if there is no client supplied filter expression, sorting clause, or pagination.  Otherwise, it constructs a custom JPQL query that will fetch the collection - joining with with all subsequent to-one relationships to prefetch them.

In general, it is recommended to configure the ORM with batch fetching so the ORM will efficiently hydrate proxy collections.
 
## Security Checks

Elide provides different flavors of security checks for performance reasons.  In general, it is expensive to execute servers side functions for every entity row hydrated from the database.  Because Elide is handling the results of each query in a single thread, the CPU cost of these checks can add extra latency to your queries.

To work around this, Elide provides two different kinds of security checks:

1. *User Checks* -  User checks are evaluated once per request rather than per entity row.
2. *Filter Expression Checks* - Filter Expression Checks generate filter expressions that are pushed to the persistence layer and executed in the database.

For data reads from the database, it is recommended to use User Checks and Filter Expression Checks wherever possible.

## ORM-isms 

Beware to-one relationships where the entity doesn't own the relationship (`mappedBy` is specified) _and_ `optional` is set to true.  The ORM must **ALWAYS** fetch these relationships when hydrating a proxy (leading to N+1 queries depending on how the ORM is configured).  The ORM has no way of knowing if the relationship is null or non-null without issuing another database query.

## Database-isms 

It is highly recommended to collocate Elide servers and the database in the same data center or region to reduce the latency of database queries from Elide. 

It is also recommended to segregate Elide read only transactions (data fetches) to run against a read-only replica of the database for optimal read performance. 

## Text Search

By default, text search (INFIX operator) is accomplished in Elide through a JPQL query similar to:
```
SELECT id, field1, field2, ... FROM table WHERE field1 like CONCAT('%', searchTerm, '%')
```

For case insensitive searches, Elide will add a lower case function to both the search field and the search value.

There are a number of limitations to this approach:
1. If the database is using a b-tree index to index the search column, a preceding wildcard ('%') will disable the use of the index.  The query will result in a full table scan.
2. Databases have limited support for functional indices.  Use of lower or upper case functions may also disable the use of an index.

Elide provides two capabilities to work around these issues for large tables that require text search:
1. Elide supports the [ability to override the JPQL fragment](#jpql-fragment-override) that is generated for any operator on any field in any entity model.  This makes it possible to disable the use of lower/upper case functions on a database column if the database column is already case insensitive.  It is also possible to use custom SQL dialects to leverage full text index support (where available).
2. Elide supports a [Text Search Data Store](https://github.com/yahoo/elide/tree/master/elide-datastore/elide-datastore-search) that can wrap another ORM data store.  Whenever possible, the text search data store can delegate queries to a local Lucene index or a Elasticsearch cluster rather than the default data store.  

### JPQL Fragment Override

To override the JPQL fragment Elide generates for a filter operator, you must define a JPQL Predicate Generator:

```java
/**
 * Converts a JPQL column alias and list of arguments into a JPQL filter predicate fragment.
 */
@FunctionalInterface
public interface JPQLPredicateGenerator {

    /**
     * Generate a JPQL fragment for a particular filter operator.
     * @param columnAlias The entity attribute being filtered.
     * @param parameters A list of prepared statement parameters that will be populated.
     * @return A JPQL fragment.
     */
    String generate(String columnAlias, List<FilterPredicate.FilterParameter> parameters);
}
```

And then register it with Elide for the filter operator you want to modify.  This can either be done globally:

```java
FilterTranslator.registerJPQLGenerator(Operator.NOTNULL, 
    (columnAlias, params) -> {
        return String.format("%s IS NOT NULL", columnAlias);
    }
);
```

Or the override can be registered for a specific model attribute:

```java
FilterTranslator.registerJPQLGenerator(Operator.NOTNULL, Book.class, "title",
    (columnAlias, params) -> {
        return String.format("%s IS NOT NULL", columnAlias);
    }
);

```

## Bespoke Field Sets

By default JSON-API fetches every relationship in an entity unless a client restricts what it asks for through sparse fields.  These relationship fetches result in extra database queries.  It is recommended to either use GraphQL or educate clients to use sparse fields in JSON-API whenever possible.
