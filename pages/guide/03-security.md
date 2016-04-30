---
layout: guide
group: guide
title: Security
---
## Core Concepts
Elide authorization involves a few core concepts:

* **User** - an object you define that is passed to **checks**, and which represents the user in your domain.
* **Checks** - a function that grants or denies a user **permission** to perform a particular action.
* **Permissions** - a set of annotations (read, update, delete, create, and share) that correspond to actions on the data model.
Each **permission** is decorated with one or more checks that are evaluated when a user attempts to perform that action.

## User
Each request is associated with a user. The user is computed by a function that you provide conforming to the
interface:

```java
Function<SecurityContext, Object>
```

## Security Evaluation
Security is applied hierarchically with three goals:

1. **Granting or denying access.**  When a model or field is accessed, a set of checks are evaluated to
    determine if the access will be denied (i.e. 403 status code) or permitted. Simply, if a user has explicitly requested 
    access to part of data model they should not see, the request will be rejected.
1. **Filtering Collections.** If a model has read permissions defined, these checks are evaluated against each model
    that is a member of the collection.  Only the models the user has access to (by virtue of being of being able 
    to read at least one of the model's fields) are returned in the response.
1. **Filtering a model.**  If a user has read access to a model, but only for a subset of a model’s fields, the
    disallowed fields are simply excluded from the output (rather than denying the request). However, when the user explicitly
    requests a field-set that contains a restricted field, the request is rejected rather than filtered.

### Hierarchical Security
JSON API does not specify how to map a particular dataset into corresponding URL representations. Elide accepts all
URLs that can be constructed by traversing the data's relationship graph. This is beneficial because it alleviates the
need for all models to be accessible at the URL root. When everything is exposed at the root, you need to enumerate all
of the valid access patterns for all of your models–which quickly becomes unwieldy.  Typically, security rules only need 
to be defined for a subset of models and relationships.

By allowing traversal of the object graph, you can eliminate invalid access patterns by applying security rules to the 
relationships to prune the graph.  Consider a simple data model consisting of articles - each having zero or more comments. The request `PATCH
/article/1/comments/4` changing the comment _title_ field would cause permissions to evaluated in the following order:

1. Read permission check on the `Article<1>#comments`. 
1. Update permission check on `Comment<4>#title`.

### Bidirectional Relationships
When one side of a bidirectional relationship is modified by a client, Elide will automatically update the
opposite side of the relationship.  This implies that the client must have permission to write both sides of the
relationship.

## Checks
Checks are simply functions that return whether or not access should be granted to the requesting user. There
are three types of checks: `InlineCheck`, `CommitCheck`, and `CriterionCheck`. Checks must be implemented by
extending one of these abstract classes. The class you choose to extend has an impact on how Elide will evaluate
your the check. There are specific types of check described by the following hierarchy:

<div id="check-tree" style="height: 250px"></div>
<!-- tree is rendered below -->
Checks are expected to implement only one of the `ok` functions from the check interface.

```java
public interface Check<T> {
  /**
   * Determines whether the user can access the resource. The result is cached on a
   * per-object basis, i.e. this check will only be run once on each T. The exception
   * to this rule is that when evaluating checks for an UpdatePermission the results
   * are not cached.
   *
   * @param object — the fully modified object
   * @param requestScope —  The request scope allows for access to the current user
   *                        and the set of resources that have been created during
   *                        the current request.
   * @param changeSpec — The `ChangeSpec` is only present for `UpdatePermission` checks
   *                     and only when the checks are specified at the field level. It
   *                     provides a 'diff' of the field.
   * @return true if security check passed
   */
  boolean ok(T object, RequestScope requestScope, Optional<ChangeSpec> changeSpec);

  /**
   * Determines whether the user can access the resource.
   *
   * @param user — the user making the request
   * @return true if security check passed
   */
  boolean ok(User user);
}
```

### Commit Checks
Commit checks are, as you might expect, checks which are executed just before Elide calls `commit` on your datastore.
That means that checks which extend `CommitCheck` defer their execution until all changes have been made
within a request but *before* those changes are ever committed to the datastore. This type of check allows
you to verify the final state of an object as it will be committed.

### Operation Checks
Operation checks behave similarly to commit checks however, rather than waiting until commit time,
`OperationCheck`s run before an action is ever taken, *inline* with the user's access as it were. These checks
are preferred over commit checks whenever possible since they allow requests to fail fast.

### User Checks
User checks depend strictly on the user. These are inline checks (i.e. they run as operations occur rather than
deferring until commit time) and only take a `User` object as input.   Because these checks only depend on who
is performaing the operation and not on what has changed, these checks are only evaluated once per request - an optimization
that accelerates the filtering of large collections.

### Criterion Checks
In some cases, the check logic can be pushed down to the data store itself. For example, a filter can be added to a
database query to remove elements from a collection where access is disallowed. These checks return a filtering object
that your database library can use to limit the queries that it uses to marshal the data. Checks which extend the
`CriterionCheck` must conform to the interface:

```java
/**
 * Extends Check to support Hibernate Criteria to limit SQL query responses.
 * @param <R> Type of the criterion to return
 * @param <T> Type of the record for the Check
 */
public interface CriterionCheck<R, T> extends Check<T> {
    /**
     * Get criterion for request scope.
     *
     * @param requestScope the requestScope
     * @return the criterion
     */
    R getCriterion(RequestScope requestScope);
}
```

## Permission Annotations
The permission annotations include `ReadPermission`, `UpdatePermission`, `CreatePermission`, `DeletePermission`,
and `SharePermission`. Permissions are annotations which can be applied to a model at the `package`, `entity`, or
`field`-level. The most specific annotation always take precedence (`package < entity < field`).  More specifically, a field annotation
overrides the behavior of an entity annotation.  An entity annotation overrides the behavior of a package annotation.  Entity annotations
can be inherited from superclasses.  When no annotation is provided at any level, access is implicitly granted for 
`ReadPermission`, `UpdatePermission`, `CreatePermission`, and `DeletePermission` and implicitly
denied for `SharePermission`.

The permission annotations wrap a boolean expression composed of the check(s) to be evaluated combined with `AND`, `OR`, 
and `NOT` operators and grouped using parenthesis.  The checks are uniquely identified within the expression 
by a string - typically a human readable phrase that describes the intent of the check.  These strings are mapped to the explicit
`Check` classes at runtime by registering them in the `EntityDictionary`.  When no registration is made, the checks can be identified by
their fully qualified class names.  The complete expression grammar can be found [here][source-grammar].

To better understand how permissions work consider the following sample code. (Only the relevant portions are included.)

{% include code_example example='check-expressions' %}

You will notice that `IsOwner` actually defines two check classes; it does so because we might want to evaluate the
same logic at distinct points in processing the request (inline when reading a post and at commit when creating a post). 
For example, we could not apply `IsOwner.Inline` when creating a new post because the post's author has not yet been assigned.
Once the post has been created and all fields assigned by Elide, the security check can be evaluated.

Contrast `IsOwner` to `IsSuperuser` which only defines one check. `IsSuperuser` only defines one check because it only depends
on who is performing the action and not on the data model being manipulated.  

#### Read
`ReadPermission` governs whether a model or field can be read by a particular user. If the expression evaluates
to `true` then access is granted. Notably, `ReadPermission` is evaluated as the user navigates through the data
represented by the URL. Elide's security model is focused on field-level access, with permission annotations applied
at on an entity or package being shorthand for applying that same security to every field in that scope. For example,
if a request is made to `GET /users/1/posts/3/comments/99` the permission execution will be as follows:

1. `ReadPermission` on `User<1>#posts`
1. `ReadPermission` on `Post<3>#comments`
1. `ReadPermission` on any field on `Comment<99>`

If all of these checks succeed, then the response will succeed. The contents of the response are then determined by
evaluating the `ReadPermission` on each field.   The response will contain the subset of fields where `ReadPermission`
is granted.  If a field does not have an annotation, then access defaults to whatever is specified at the entity level.   
If the entity does not have an annotation, access defaults to whatever is specified at the package.  If the package does not have an 
annotation, access defaults to granted.

#### Update
`UpdatePermission` governs whether a model can be updated by a particular user. Update is invoked when an attribute's
value is changed or values are added to or removed from a relationship. Examples of operations that will evaluate
`UpdatePermission` given objects `Post` and `User` from the code snippets above:

* Changing the value of `Post.published` will evaluate `UpdatePermission` on `published`. Because more specific
  checks override less specific checks, the `UpdatePermission` on the entity `Post` will not be evaluated.
* Setting `Post.author = User` will evaluate `UpdatePermission` on `Post` since `author` does not have a more specific
  annotation. Because `author` is a bidirectional relationship, `UpdatePermission` will also be evaluated on the `User.posts` field.
* Removing `Post` from `User.posts` will trigger `UpdatePermission` on both the `Post` and `User` entities.
* Creating `Post` will trigger `UpdatePermission` checks on any fields that are initialized in the request (as well as any bidirectional fields on
  referenced objects).

#### Create
`CreatePermission` governs whether a model can be created. It is evaluated in conjunction with `UpdatePermission` on any initialized field to
determine if the user's request to create a resource will succeed.

#### Delete
`DeletePermission` governs whether a model can be deleted.

#### Share

`SharePermission` governs whether an existing model instance (one created in a prior transaction) can be assigned to 
another collection other than the one in which it was initially created.  Basically, does a collection 'own' the  model instance 
in a private sense or can it be moved or referenced by other collections.

When a relationship is updated by either a `PATCH` or a `POST`, data is loaded by ID and assigned to the selected relationship.
For example, consider `Post<25>` added to the `Comment<123>#post` relationship:


```http
POST /user/2/comments HTTP/1.1
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json

{
  "data": {
    "id": "123",
    "type": "comment",
    "attributes": { "text": "..." },
    "relationships": {
      "post": { "data": {"type": "post", "id": 25} },
      "author": { "data": {"type": "user", "id": 2} }
    }
  }
}
```

This is the single instance in JSON-API where an object can be referenced directly by ID without first traversing
through the normal relationship graph of the URL.  This access bypasses the hierarchical security of the data model relationship graph.
Specifically, while `ReaderPermission` will be evaluated on the loaded object, other checks (on parent collections and objects) will not be.

By default, Elide disallows manipulating relationships like this to prevent [unauthorized access](#security-of-shareable-models).
Creating unbounded relationships in this manner can be explicitly enabled by adding `SharePermission` to a model,
making the model *shareable*.  Attempts to share objects without this permission or without satisfying the associated
permission check(s) are denied access.

## Security of Shareable Models
The following scenario illustrates what could happen _without_ Elide's concept of shareable models.

Imagine a scenario where Elide is used to model and expose a bank account.  In this example, there are 3 models:

1. A user
1. An account
1. A transaction

A user has accounts which each have a set of transactions.  In this example, the developer has implemented
simple security checks for the user model such that a user's model is only readable and writable by herself.
Accounts and transactions have no implemented checks because the developer _mistakenly assumed_ these models can only be 
reached by navigating through `User`.

Now let's say Sally is `/user/1` in our system.  An evil hacker wants to read Sally's transactions.  The hacker
creates a new account `/user/2`.  The hacker creates an empty account with no transactions: `/user/2/account/342`.
The hacker can then `POST /user/2/account/342/relationships/transaction` with random transaction IDs, for example:

```http
POST /user/2/account/342/relationships/transaction HTTP/1.1
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json

{
    "data": [
        { "type": "transaction", "id": "123" }
    ]
}

```
For this request the following security checks are evaluated, all of which pass. 

1. `ReadPermission` on `User<2>#account`
1. `ReadPermission` on `Account<342>#transactions`
1. `UpdatePermission` on `Account<342>#transactions`
1. `ReadPermission` on Transaction<123> fields

The final check passes because the developer assumed the checks on the user entity were sufficient to also limit access 
to everything inside user (accounts and transactions).  The developer failed to account for the case where JSON-API can 
reference an object directly by ID when manipulating relationships.

To prevent circumventing security in this manner Elide by default will not allow an entity to be assigned to another collection other
than the one in which it was initially created.  This behavior can be changed by explicitly annotating the entity with `SharePermission`
and an associated check expression.

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
            {text: {name: 'OperationCheck'}}
          ]
        },
        {
          text: {name: 'CriterionCheck'}
        }
      ]
    }
  })
</script>

[javadoc-annotations]: http://www.javadoc.io/doc/com.yahoo.elide/elide-annotations/ "Elide-Annotations documentation"
[source-grammar]: https://github.com/yahoo/elide/blob/master/elide-core/src/main/antlr4/com/yahoo/elide/generated/parsers/Expression.g4#L25
