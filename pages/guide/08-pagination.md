---
layout: guide
group: guide
title: Pagination
---
# Features

Elide supports:
1. Paginating a collection by row offset and limit.
2. Paginating a collection by page size and number of pages.
3. Returning the total size of a collection visible to the given user.
4. Returning a _meta_ block in the JSON-API response body containing metadata about the collection.
5. A simple way to control: 
  * the availability of metadata 
  * the number of records that can be paginated

# Syntax
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

# Examples

Return page 3 of size 100 of the book collection:

`/book?page[number]=3&page[size]=100`

Return 100 records from the book collection starting at record 1200:

`/book?page[offset]=1200&page[limit]=100`

Return the size of the book collection:

`/book?page[totals]`

Return page 3 of size 100 of the book collection **and** return the size of the book collection:

`/book?page[number]=3&page[size]=100&page[totals]`

# Meta Block
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

# Paginate Annotation
Any entity can be annotated with the _Paginate_ annotation which can control:
1. Whether or not page totals can be requested for collections of the entity's type.
2. The maximum number of records that can ever be returned in a single response.
3. The default number of records that should be returned when no page _limit_ or _size_ is provided.

```
    @Paginate(countable = true, maxLimit = 100000, defaultLimit = 10)
    class Book { ... }
```
## Default Limits
When no _Paginate_ annotation is provided, Elide by default sets the maximum number of allowed
records to **10000** and the default number of records to **500**.

# When Collections Cannot Be Paginated
Some security _checks_ are evaluated in memory on the server - checks which cannot be pushed
to the data store and that depend on the value of data being returned.

Whenever Elide must prune a collection based on such checks, it rejects requests to paginate
the collection by returning a **400** error to the client.
