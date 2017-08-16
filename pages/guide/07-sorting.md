---
layout: guide
group: guide
title: Sorting
---
# Features

Elide supports:
1.  Sorting a collection by any attribute of the collection's type.
2.  Sorting a collection by multiple attributes at the same time in either ascending or descending order.
3.  Sorting a collection by any attribute of a to-one relationship of the collection's type.  Multiple relationships can be traversed provided the path 
from the collection to the sorting attribute is entirely through to-one relationships.

# Syntax
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

# Examples

Sort books ascending by title:

`/book?sort=title`

Sort books descending by title:

`/book?sort=-title`

Sort books ascending by their publisher's name:

`/book?sort=+publisher.name`

Sort books ascending by their publisher's name and descending by their ID:

`/book?sort=+publisher.name,-id`

# Sort By ID

The keyword _id_ can be used to sort by whatever field a given entity uses as its identifier.

# Caveats

Sorting across relationships performs an inner join between the primary collection type and its relationship type.  
This may exclude results from the collection where a relationship is not present.
