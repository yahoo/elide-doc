---
layout: guide
group: guide
title: Performance 
---

## N+1 Problem

### Overview
The N+1 problem is a performance issue where an ORM issues a large number of database queries to fetch a parent/child relationship.
The ORM issues a single query to hydrate the parent and then _N_ queries to hydrate the children.

Most ORMs solve this problem by providing a number of different fetching strategies that are enabled when a proxy object or collection
is hydrated.  These strategies fall into one of two categories:

1. A join is used to fetch both the parent and the children in a single query.  The ORM populates its session cache with all entities
fetched in the join.  Joining works well for fetching singular relationships.  It is important to note that a singular join that fetches 
an entire subgraph (spanning multiple relationships) is impractical and would break row based pagination (offset & limit).  Furthermore,
large joins put considerable memory stress on the ORM server.
2. Instead of a single query per element of a collection, the number of queries is reduced by fetching multiple children in fewer
queries.

These strategies may or not be available to the developer depending on how the ORM is leveraged.  If the developer interacts with
a proxy object directly, all fetch strategies are available.  However, the SQL queries generated from proxy objects cannot be customized
with additional filters, sorting, or pagination.

Alternatively, the developer can have complete control over the query by writing JPQL or Criteria queries.  However, only join fetching
is available through these APIs.

### Solution
Because Elide has to work well under a wide variety of circumstances, it has adopted a hybrid solution for ORM based data stores.

Whenever Elide traverses a to-one relationship, it returns the ORM proxy object directly.  In most cases, these relationships should already exist inside the session and result in no extra database queries.

Whenever Elide traverses a to-many relationship, it returns the ORM proxy if there is no client supplied filter expression, sorting
clause, or pagination.  Otherwise, it constructs a custom JPQL query that will join with all to-one relationships to prefetch them.

In general, it is recommended to configure the ORM with batch fetching so the ORM will efficiently hydrate proxy collections.
 
## Security Checks
## Hibernate-isms 
## Database-isms 
## Text Search
## Bespoke Fieldsets
