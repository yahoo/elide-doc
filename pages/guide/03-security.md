---
layout: guide
group: guide
title: Security
---
## Core Concepts
---------------------
API authentication is largely a solved problem and generally outside the scope of Elide.
Authorization - the act of verifying data and operation access for an _already authenticated user_ in the Elide framework involves a few core concepts:

* **User** - Each API request is associated with a user principal.  The user is opaque to the Elide framework but is passed to developer-defined _check_ functions that evaluate arbitrary logic or build filter expressions.
* **Checks** - a function _or_ filter expression that grants or denies a user **permission** to perform a particular action.
* **Permissions** - a set of annotations (read, update, delete, create, and share) that correspond to actions on the data model's entities and fields.  Each **permission** is decorated with one or more checks that are evaluated when a user attempts to perform that action.

## Security Evaluation
Security is applied hierarchically with three goals:

1. **Granting or denying access.**  When a model or field is accessed, a set of checks are evaluated to determine if the access will be denied (i.e. 403 HTTP status code (JSON-API) or GraphQL error object) or permitted.  If a user has explicitly requested access to part of the data model they should not see, the request will be rejected.
1. **Filtering Collections.** If a model has read permissions defined, these checks are evaluated against each model that is a member of the collection.  Only the models the user has access to (by virtue of being of being able to read at least one of the model's fields) are returned in the response.
1. **Filtering a model.**  If a user has read access to a model, but only for a subset of a model’s fields, the disallowed fields are excluded from the output (rather than denying the request). However, when the user explicitly requests a field-set that contains a restricted field, the request is rejected rather than filtered.

### Hierarchical Security
Both JSON-API and GraphQL define mechanisms to fetch and manipulate entities defined by the data model schema.  Some (rootable) entities can be reached directly by providing their data type and unique identifier in the query. Other entities can only be reached through relationships to other entities– by traversing the entity relationship graph.  The Elide framework supports both methods of access. This is beneficial because it alleviates the need for all models to be accessible at the root of the graph. When everything is exposed at the root, the developer needs to enumerate all of the valid access patterns for all of the data models which quickly becomes unmanageable. In addition to eliminating redundancy in security declaration, this form of security can have significant performance benefits for enforcing security on large collections stored in key-value stores that have limited ability for the underlying persistence layer to directly apply security filters. It is often possible to deny access to an entire collection (i.e. hierarchical relationship) before attempting to verify access to each individual member within that collection.  Typically, security rules only need to be defined for a subset of models and relationships– often near the roots of the graph. Applying security rules to the relationships to prune the graph can eliminate invalid access patterns.  To better understand the sequence of how security is applied, consider the data model depicted in Figure 1 consisting of articles where each contains zero or more comments. 

![Security Article Comment UML](/assets/images/security_article_comment_uml.png){:class="img-responsive"} 

The request to update a specific comment of a particular article involves the following permission checks:
1. Read permission check on the Article’s comments field.
2. Update permission check on the Comment’s title field.

When a client modifies one side of a bidirectional relationship, Elide will automatically update the opposite side of the relationship. This implies that the client must have permission to write both sides of the relationship.

## Checks
---------------------
Checks are simply functions that either return:
* whether or not access should be granted to the requesting user. 
* a filter expression that can be used to filter a collection to what is visible to a given user.

Checks can either be invoked:
* immediately prior to the (create, read, update, and delete) action being performed.
* immediately before committing the transaction that wraps the entire API request.

The former is useful for checks that depend on data that is already persisted. Read, delete, and most update checks fall into this category. The latter is useful for checks involving complex mutations to the object graph for newly created data. These checks cannot execute until the data model has been fully updated to reflect the entire set of modifications.  Corresponding to these categories, there are two types of checks in Elide: InlineCheck and CommitCheck. Checks must be implemented by extending one of these abstract classes. The class you choose to extend impacts how Elide will evaluate your the check. There are specific types of check described by the following hierarchy:

<div id="check-tree" style="height: 250px"></div>

`InlineCheck` is the abstract super class of the three specific variants:

### Operation Checks
Operation checks are inline checks whose evaluation requires the entity instance being read from or written to. They operate in memory of the process executing the Elide library.

Operation checks are expected to implement the following `Check` interface:
```java
    /**
     * Determines whether the user can access the resource.
     *
     * @param object Fully modified object
     * @param requestScope Request scope object
     * @param changeSpec Summary of modifications
     * @return true if security check passed
     */
    boolean ok(T object, RequestScope requestScope, Optional<ChangeSpec> changeSpec);
```

### User Checks
User checks depend strictly on the user principal. These are inline checks (i.e. they run as operations occur rather than deferring until commit time) and only take a User object as input. Because these checks only depend on who is performing the operation and not on what has changed, these checks are only evaluated once per request - an optimization that accelerates the filtering of large collections.

User checks are expected to implement the following `Check` interface:
```java
    /**
     * Method reserved for user checks.
     *
     * @param user User to check
     * @return True if user check passes, false otherwise
     */
    boolean ok(User user);
```

### Filter Expression Checks
In some cases, the check logic can be pushed down to the data store itself. For example, a filter can be added to a database query to remove elements from a collection where access is disallowed. These checks return a `FilterExpression` predicate that your data store can use to limit the queries that it uses to marshal the data. Checks which extend the `FilterExpessionCheck` must conform to the interface:

```java

/**
 * Check for FilterExpression. This is a super class for user defined FilterExpression check. The subclass should
 * override getFilterExpression function and return a FilterExpression which will be passed down to datastore.
 * @param <T> Type of class
 */
public abstract class FilterExpressionCheck<T> extends InlineCheck<T> {

    /**
     * Returns a FilterExpression from FilterExpressionCheck.
     * @param entityClass The entity collection to filter
     * @param requestScope Request scope object
     * @return FilterExpression for FilterExpressionCheck.
     */
    public abstract FilterExpression getFilterExpression(Class<?> entityClass, RequestScope requestScope);
}
```

Most `FilterExpressionCheck` functions construct a `FilterPredicate` which is a concrete implementation of the `FilterExpression` interface:

```java
/**
 * Constructs a filter predicate
 * @param path The path through the entity relationship graph to a particular attribute to filter on.
 * @param op The filter comparison operator to evaluate.
 * @param values The list of values to compare the attribute against.
 */
public FilterPredicate(Path path, Operator op, List<Object> values) {
 ...
}
```

Here is an example to filter the Author model by book titles:
```java
   //Construct a filter for the Author model for books.title == 'Harry Potter'
   Path.PathElement authorPath = new Path.PathElement(Author.class, Book.class, "books");
   Path.PathElement bookPath = new Path.PathElement(Book.class, String.class, "title");
   List<Path.PathElement> pathList = Arrays.asList(authorPath, bookPath);
   Path path = new Path(pathList);

   return new FilterPredicate(path, Operator.IN, Collections.singletonList("Harry Potter"));
``` 

Filter expression checks are most important when a security rule is tied in some way to the data itself. By pushing the security rule down to the datastore, the data can be more efficiently queried which vastly improves performance.  Moreover, this feature is critical for implementing a service that requires complex security rules (i.e. anything more than role-based access) on large collections.

## User
---------------------
Each request is associated with a user. The user is computed by a function that you provide conforming to the interface:

```java
Function<SecurityContext, Object>
```

## Permission Annotations
---------------------
The permission annotations include `ReadPermission`, `UpdatePermission`, `CreatePermission`, `DeletePermission`, and `SharePermission`. Permissions are annotations which can be applied to a model at the `package`, `entity`, or `field`-level. The most specific annotation always take precedence (`package < entity < field`).  More specifically, a field annotation overrides the behavior of an entity annotation.  An entity annotation overrides the behavior of a package annotation.  Entity annotations can be inherited from superclasses.  When no annotation is provided at any level, access is implicitly granted for `ReadPermission`, `UpdatePermission`, `CreatePermission`, and `DeletePermission` and implicitly denied for `SharePermission`.

The permission annotations wrap a boolean expression composed of the check(s) to be evaluated combined with `AND`, `OR`, and `NOT` operators and grouped using parenthesis.  The checks are uniquely identified within the expression by a string - typically a human readable phrase that describes the intent of the check (_"principal is admin at company OR principal is super user with write permissions"_).  These strings are mapped to the explicit `Check` classes at runtime by registering them with Elide.  When no registration is made, the checks can be identified by their fully qualified class names.  The complete expression grammar can be found [here][source-grammar].

To better understand how permissions work consider the following sample code. (Only the relevant portions are included.)

{% include code_example example='check-expressions' %}

You will notice that `IsOwner` actually defines two check classes; it does so because we might want to evaluate the same logic at distinct points in processing the request (inline when reading a post and at commit when creating a post).  For example, we could not apply `IsOwner.Inline` when creating a new post because the post's author has not yet been assigned.  Once the post has been created and all fields assigned by Elide, the security check can be evaluated.

Contrast `IsOwner` to `IsSuperuser` which only defines one check. `IsSuperuser` only defines one check because it only depends on who is performing the action and not on the data model being manipulated.  

### Read
`ReadPermission` governs whether a model or field can be read by a particular user. If the expression evaluates to `true` then access is granted. Notably, `ReadPermission` is evaluated as the user navigates through the entity relationship graph.  Elide's security model is focused on field-level access, with permission annotations applied on an entity or package being shorthand for applying that same security to every field in that scope. For example, if a request is made to `GET /users/1/posts/3/comments/99` the permission execution will be as follows: 

1. `ReadPermission` on `User<1>#posts`
1. `ReadPermission` on `Post<3>#comments`
1. `ReadPermission` on any field on `Comment<99>`

If all of these checks succeed, then the response will succeed. The contents of the response are determined by evaluating the `ReadPermission` on each field.   The response will contain the subset of fields where `ReadPermission` is granted.  If a field does not have an annotation, then access defaults to whatever is specified at the entity level.  If the entity does not have an annotation, access defaults to whatever is specified at the package.  If the package does not have an annotation, access defaults to granted.

### Update
`UpdatePermission` governs whether a model can be updated by a particular user. Update is invoked when an attribute's value is changed or values are added to or removed from a relationship. Examples of operations that will evaluate `UpdatePermission` given objects `Post` and `User` from the code snippets above: 

* Changing the value of `Post.published` will evaluate `UpdatePermission` on `published`. Because more specific checks override less specific checks, the `UpdatePermission` on the entity `Post` will not be evaluated.
* Setting `Post.author = User` will evaluate `UpdatePermission` on `Post` since `author` does not have a more specific annotation. Because `author` is a bidirectional relationship, `UpdatePermission` will also be evaluated on the `User.posts` field.
* Removing `Post` from `User.posts` will trigger `UpdatePermission` on both the `Post` and `User` entities.
* Creating `Post` will _not_ trigger `UpdatePermission` checks on any fields that are initialized in the request.  However, it will trigger `UpdatePermission` on any bidirectional relationship fields on preexisting objects.

### Create
`CreatePermission` governs whether a model can be created or a field can be initialized in a newly created model instance.
Whenever a model instance is newly created, initialized fields are evaluated against `CreatePermission` rather than `UpdatePermission`.

### Delete
`DeletePermission` governs whether a model can be deleted.

### Share
`SharePermission` governs whether an existing model instance (one created in a prior transaction) can be assigned to another collection other than the one in which it was initially created.  Basically, does a collection 'own' the  model instance in a private sense (composition) or can it be moved or referenced by other collections (aggregation).

Graph APIs generally have two ways to reference an entity for CRUD operations. In the first mechanism, an entity is navigable through the entity relationship graph. An entity can be reached only through other entities. The alternative is to provide a mechanism to directly reference any entity by its data type and an instance identifier. The former approach is especially useful for modeling object composition (as opposed to aggregation). It enables the definition of hierarchical security.  The latter approach is especially useful when directly manipulating relationships or links between edges. More specifically, to add an existing entity to a collection, it is simplest to reference this entity by its type and ID in the API request rather than defining a path to it through the entity relationship graph.  Elide distinguishes between these two scenarios by tracking an object's lineage or path through the entity relationship graph. By default, Elide explicitly denies adding an existing (not newly created) entity to a relationship with another entity if it has no lineage. For object composition, this is typically the desired behavior. For aggregation, this default can be overridden by adding an explicit SharePermission.  SharePermission is always either identical to ReadPermission for the entity _or_ it is explicitly disallowed.

<script>
  new Treant({
    chart: {
      container: '#check-tree',
      connectors: {
        type: 'step'
      }
    },
    nodeStructure: {
      text: {name: 'Check'},
      children: [
        {
          text: {name: 'CommitCheck'}
        },
        {
          text: {name: 'InlineCheck'},
          children: [
            {text: {name: 'UserCheck'}},
            {text: {name: 'OperationCheck'}},
            {text: {name: 'FilterExpressionCheck'}}
          ]
        }
      ]
    }
  })
</script>

[javadoc-annotations]: http://www.javadoc.io/doc/com.yahoo.elide/elide-annotations/ "Elide-Annotations documentation"
[source-grammar]: https://github.com/yahoo/elide/blob/master/elide-core/src/main/antlr4/com/yahoo/elide/generated/parsers/Expression.g4#L25
