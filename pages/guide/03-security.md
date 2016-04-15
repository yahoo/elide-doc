---
layout: guide
group: guide
title: Security
---
## Core Concepts
Elide authorization involves a few core concepts:

* **User** - an object you define that is passed to checks, and which represents the user in your domain.
* **Checks** - a function that grants or denies a user can perform a particular action.
* **Permissions** - a set of annotations (read, update, delete, create, and share) that describe which checks are
  evaluated when a user attempts to preform an action.

## User
Each request is associated with a user. The user is computed by a function that you provide conforming to the
interface:

```java
Function<SecurityContext, Object>
```

## Security Evaluation
Security is applied hierarchically with three goals:

1. **Granting or denying access.**  When a model or field is accessed, a set of checks are evaluated to
    determine if the access will be denied (i.e. 403 status code) or permitted. Simply, if a user does not have access
    to a particular collection (anywhere along the request) then the request will be rejected.
1. **Filtering Collections.** If a model has read permissions defined, these checks are evaluated against each model
    that is a member of the collection.  Only the models the user has access to are returned in the response.
1. **Filtering a model.**  If a user has read access to a model, but only for a subset of a model’s fields, the
    disallowed fields are simply excluded from the output (rather than denying the request). When the user explicitly
    requests a field-set that contains a restricted field the request is rejected rather than filtered.

### Hierarchical Security
JSON API does not specify how to map a particular dataset into corresponding URL representations. Elide accepts all
URLs that can be constructed by traversing the data's relationship graph. This is beneficial because it alleviates the
need for all models to be accessible at the URL root. When everything is exposed at the root you need to enumerate all
of the valid access patterns for all of your models–which quickly becomes unwieldy. By allowing traversal of the
object graph you can eliminate invalid access patterns by applying security rules to the relationships to prune
the graph.

Consider a simple data model consisting of articles - each having zero or more comments. The request `PATCH
/article/1/comments/4` changing the comment _title_ field would cause permissions to evaluated in the following order:

1. Read permission check on the `Article<1>#comments`. If there is no permission defined on the collection directly
   then the Read permission defined on the entity will be used. If there is no Read permission defined on the entity
   then the Read permission defined at a package level will be used. If there is no permission at the package level
   then, by default, access is granted.
1. Update permission check on `Comment<4>#title`.

### Bidirectional Relationships
When one side of a bidirectional relationship is modified by a client, Elide will automatically update the
opposite side of the relationship.  This implies that the client must have permission to write both sides of the
relationship (either through permissions at the model level or through permissions at the relationship level).

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
within a request but *before* those changes are ever committed to the database. This type of check allows
you to verify the final state of an object as it will be committed.

### Operation Checks
Operation checks behave similarly to commit checks however, rather than waiting until commit time,
`OperationCheck`s run before an action is ever taken, *inline* with the user's access as it were. These checks
are preferred over commit checks whenever possible since they allow requests to fail fast.

### User Checks
User checks depend strictly on the user. These are inline checks (i.e. they run as operations occur rather than
deferring until commit time) and only take a `User` object as input. These checks are cached at a user level
instead of an object level. User checks allow for quickly filtering of large collections because the check only
needs to be evaluated once per request.

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
`field`-level. The most specific annotation always take precedence (`package < entity < field`).

The permission annotations wrap an expression that defines the logic to be evaluated. The expression is composition of
checks (described above). Each check should implement the [Check][javadoc-annotations] interface and
their representation in the expression is determined by the string used to register them in the `EntityDictionary`.
The expressions are constructed with a [simple grammar][source-grammar]. The grammar allows for clauses that describe
what the check guards against that are combined using `AND`, `OR`, and `NOT`, and can be grouped using parenthesis.
To better understand how permissions work consider the following sample code. (Only the relevant portions are included.)

{% include code_example example='check-expressions' %}

You will notice that `IsOwner` actually defines two check classes; it does so because we might want to evaluate the
same logic at distinct points in processing the request. For example, we could not apply `IsOwner.Inline` when creating
a new post because `new Post().author == null` but just before we are ready to store the new `Post` it should have an
author (and that author should be the user trying to create the post).

Contrast `IsOwner` to `IsSuperuser` which only defines one check. `isSuperuser` only defines one check because it
is unlikely that would want to distinguish situations when the user is not a superuser before processing their request
and is a superuser after processing their request. However, the check in `IsSuperuser` is still defined as an inner
class because we might want to add related checks in the future.

#### Read
`ReadPermission` governs whether a model or field can be accessed by a particular user. If the expression evaluates
to `true` then access is granted. Notably, `ReadPermission` is evaluated as the user navigates through the data
represented by the URL. Elide's security model is focused on field-level access, with permission annotations applied
at on an entity or package being shorthand for applying that same security to every field in that scope. For example,
if a request is made to `GET /users/1/posts/3/comments/99` the permission execution will be as follows:

1. `ReadPermission` on `User<1>#posts`
1. `ReadPermission` on `Post<3>#comments`
1. `ReadPermission` on any field on `Comment<99>`

If all of these checks succeed, then the response will succeed. The contents of the response are then determined by
evaluating the `ReadPermission` on each field–if a field does not have an annotation, then access defaults to whatever
is specified at the entity level. For example, if `ReadPermission` on `Comment` is true, then an unannotated field
will be returned in the response; but if `ReadPermission` on `Comment` is false, then only annotated fields that
return true from their `ReadPermission` will be returned in the response.

#### Update
`UpdatePermission` governs whether a model can be updated by a particular user. Update is invoked when an attribute's
value is changed or values are added to or removed from a relationship. Examples of operations that will evaluate
`UpdatePermission` given objects `Post` and `User` from the code snippets above:

* Changing the value of `Post.published` will evaluate `UpdatePermission` on `published`. Because more specific
  checks override less specific checks, the `UpdatePermission` on `Post` will not be evaluated (which is why we
  duplicate `User.ownsPost.inline` in our field-level annotation).
* Setting `Post.author = User` will evaluate `UpdatePermission` on `Post` since `author` does not have a more specific
  annotation. Because `author` is reciprocal, `UpdatePermission` will also be evaluated on the `User.posts` field.
* Removing `Post` from `User.posts` will trigger `UpdatePermission` on `Post` and on `User`.
* Creating `Post` will trigger `UpdatePermission` checks on the fields it contains (as well as any reciprocal fields on
  referenced objects).

#### Create
`CreatePermission` governs whether a model can be created. It is evaluated in conjunction with `UpdatePermission` to
determine if the user's request to create a resource will succeed.

#### Delete
`DeletePermission` governs whether a model can be deleted.

#### Share
`SharePermission` governs whether an existing (not newly created) object can be added to a relationship on
another object. When a relationship is updated by either a `PATCH` or a `POST`, data is loaded by ID and assigned to
the selected relationship. However, because these loads bypass the normal relationship graph traversal, they also bypass
the corresponding security checks. Consider the following request:

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

This request creates a new comment that is associated with `Post<25>`; however, we don't know anything about that
`Post` either from the request itself (since we're not creating it) or from the path by which we have arrived
(`/user/2/comments`).

`SharePermission` is how we determine if the reference here to `Post<25>` is valid. By default, Elide
disallows creating relationships like this to prevent [unauthorized access](#security-of-shareable-models).
Creating unbounded relationships in this manner can be explicitly enabled by adding `SharePermission` to a model,
making the model *shareable*.  Attempts to share objects without this permission or without satisfying the associated
permission check(s) are denied access.

In this request `SharePermission` is not needed for the owning side of the `Comment.author` relationship because
in order to reach the appropriate collection (`User.comments` in this example) to create the `Comment` you first need
to be able to see `User` and then the particular `User` who owns the comment. If, however, you were going to create
the same comment from the path `/posts/25/comments/` then you *would* need `SharePermission` on `User` and you would
not need it on `Post` because we can see by the URL that you have valid access to `Post<25>` but cannot determine if
you can access `User<2>`.

## Security of Shareable Models
The following scenario illustrates what could happen _without_ Elide's concept of shareable models.

Imagine a scenario where Elide is used to model and expose a bank account.  In this example, there are 3 models:

1. A user
1. An account
1. A transaction

A user has accounts which each have a set of transactions.  In this example, the developer has implemented
simple security checks for the user model such that a user's model is only readable and writable by himself.
Accounts and transactions have no implemented checks because they can only be reached by navigating through `User`
and so no user can read the data belonging to any other user.

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
For this request the following security checks are evaluated, all of which pass because they are legitimate accesses.

1. `ReadPermission` on `User<2>`
1. `ReadPermission` on `Account<342>`
1. `UpdatePermission` on `Account<342>#transactions`

Noteably absent from the evaluated checks are any that involve `Transaction<123>`, this is because `Transaction<123>`
is not being directly accessed by the hacker. It could be that the hacker has another account (say `Account<345>`) to
which `Transaction<123>` belongs, which would make the hacker's modification of `Transaction<123>` totally legitimate.

Without `SharePermission` there is no way to validate the hacker's access to the transactions they are attempting to
modify, so if a transaction with the specified id exists it will be added to the hacker's account. While the hacker
has no way to know the contents of the transaction in advance (and consequently might end up owning the bank a great
deal of money) there is no good way to prevent abusive behavior like this since security checks are evaluated while
navigating the object hierarchy.

To prevent circumventing security in this manner Elide will not allow the loading of arbitrary objects (i.e. objects
not directly in the request's lineage or created by the request) unless the object that is being loaded has a
`SharePermission` annotation and the checks specified by that annotation evaluate to true.

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
