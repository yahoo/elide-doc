Below is my proposed outline for our updated documentation:

1. Quick Start
  * Standard/Recommended (start directing users to use Elide standalone)
  * Terminology Overview
    * Models
    * Datastores
    * Attributes
    * Relationships
  * Advanced (show advanced configuration using Elide as a middleware)
1. Models
  * Philosophy (Models are a _view_ on top of DB schema)
  * JPA (Brief overview and example with link to JPA docs)
  * Elide Computed properties (both attrs and rels. Explanation of why the exist and how/when to use).
  * Lifecycle Hooks (how/when/why)
  * Pagination (Server-side explanation on configuring pagination for models)
1. Security
  * Overview/Philosophy
  * PermissionExecutor (_brief_ description that such a thing exists and that it can be extended. Link to Advanced doc)
  * UserChecks
  * OperationChecks
  * CommitChecks
  * FilterExpressionChecks (for each check, explain what/how/why/when)
1. Datastores
  * Overview
  * Supported Stores
    * Hibernate 3
    * Hibernate 5
    * In-Memory
    * No-op
    * Multiplex Store
  * Bridgeable Stores
  * Custom Datastores (Explanation of interface, how to implement, datastore responsibilities, etc.)
1. Audit (Explanation of audit support)
1. API Usage (Client-side info)
  * JSON-API
    * Overview (link with full docs included)
    * Querying
    * Pagination
    * Sorting
    * Filtering
    * Swagger
  * GraphQL
    * Overview
    * Querying
    * Pagination
    * Sorting
    * Filtering
1. Advanced
  * Architecture (overall architecture of Elide describing things such as PersistentResource and EntityDictionary)
