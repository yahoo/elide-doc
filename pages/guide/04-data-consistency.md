---
layout: guide
group: guide
title: Data Consistency
---
## Transactions
Accessing a hierarchy of objects requires a consistent view of related models.  Reading from and writing to individual resources without some form of transactions can result in inconsistent client state where some models reflect one state and others reflect a different state.  This can lead to subtle bugs.

Elide wraps every request (either via JSON API or the patch extension) in a transaction.  Transactions are handled by `DataStore` implementations.

## Cascading Deletes
Many JPA ORM providers include a mechanism to cascade deletes so that model entities or even sub-hierarchies of model entities are removed 
whenever they become orphaned by a delete operation.  Elide relies on the functionality of the ORM to perform cascading deletes.  
Furthermore, Elide does not evaluate permission checks for model entities removed by the JPA provider through a cascade operation.
