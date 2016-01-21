---
layout: guide
group: guide
title: Security
---
## Core Concepts
Elide authorization involves a few core concepts:

* **Permissions** - a set of annotations that describe how a model (read, update, delete, create, & share) or model field (read & update) can be accessed.
* **Checks** - custom code that verifies whether a user can perform an action.  Checks are assigned to permissions.
* **User** - an opaque object which represents the user identity and is passed to checks.
* **Persistent Resource** - all JPA annotated models are wrapped in `PersistentResource` objects.  Each `PersistentResource` includes a lineage or directed path of prior resources that were accessed to reach this particular resource.  A lineage can only traverse the JPA annotated relationships between models.  The current resource and any resource in its lineage can be referenced by a check.

## Permission Annotations
Permissions include `ReadPermission`, `UpdatePermission`, `CreatePermission`, `DeletePermission`, and `SharePermission`. Permissions are annotations (i.e. `@ReadPermission(any = {...})`) which can be applied to a model at the `package`, `entity`, or `field`-level. Evaluation precedence is: `package < entity < field`.

All permissions are configured in 1 of 2 ways:

1. *Any* - A list of `Check` classes.  If any of the checks evaluate to true, permission is granted.
1. *All* - A list of `Check` classes.  If all of the checks evaluate to true, permission is granted.

More complex check expressions can be implemented by composing and evaluating checks inside another check class.

### Share Permissions

`SharePermissions` govern whether an existing (not newly created) model instance can be shared with another collection or relationship.
When a relationship is updated by PATCH or POST, existing model instances are loaded by ID and assigned to the selected relationship.  These loads
bypass the normal relationship graph traversal and corresponding security check evaluation to reference a given model instance.

To prevent [unauthorized access](#shareable), Elide disallows this behavior by default.  It can be explicitly enabled by
making an object _shareable_.  Shareable models are models with an associated `SharePermission`.  Attempts to share objects without this
permission or without satisfying the associated permission check(s) are denied access.  

## Application  
Security is applied in three ways:

1. **Granting or denying access.**  If a specific model or model field is accessed and the requesting user does not belong to a role that has the associated permission, the request will be rejected with a 403 error code.  Otherwise the request is granted.
1. **Filtering Collections.** If a model has any associated read permission checks, these checks are evaluated against each model that is a member of the collection.  Only the models the user has access to are returned in the response.
1. **Filtering a model.**  If a user has read access to a model but only for a subset of a model’s fields, the disallowed fields are simply excluded from the output (rather than denying the request).  This filtering does not apply for explicit requests for sparse fieldsets.

### Hierarchical Security

JSON API does not qualify (outside of recommendations) whether a URL can traverse the model relationship graph.   
Without a hierarchy, all models must be accessible at the URL root.  When everything is exposed at the root,
all models must enumerate security checks.  The declarations become highly redundant and error prone.

Elide allows hierarchical URL navigation.  Security checks are evaluated in the order in which the
relationship graph is traversed.  

Consider a simple data model consisting of articles - each having zero or more comments.
A PATCH on `/article/1/comments/4` changing the comment _title_ field would be evaluated in the following order:

1. Read permission check on the article model.
1. Read field permission check on the article's `comments` relationship.
1. Read permission check on the comment model.
1. Update permission check on the comment model.
1. Read field permission check on the comment's `title` attribute.
1. Update field permission check on the comment's `title` attribute.

### Bidirectional Relationships

When one side of a bidirectional relationship is modified by a client, Elide will automatically update the opposite side
of the relationship.  This implies that the client must have permission to both read and write both sides of the relationship (both
at the model level and at the relationship level).

## Check

Checks are simply functions that return whether or not access should be granted to the requesting user.

There are two classes of checks: `CommitCheck` and `InlineCheck`. This distinction enforces check and permission compatibility at compile-time. Specifically, `CreatePermission` and `UpdatePermission` can take any class of check while `ReadPermission` and `DeletePermission` can only accept `InlineCheck`s.

### Check Hierarchy

`Check` is the primitive interface describing all checks in the system. However, this is expanded into a specific hierarchy of supported checks:

```
Hierarchy:
                Check
                 / \
                /   \
               /     \
      CommitCheck   InlineCheck
                        / \
                       /   \
                      /     \
                UserCheck  OperationCheck
```

In particular, checks should only be implemented by extending one of the abstract classes at the leaf nodes. That is, there is a clear and logical distinction between `CommitCheck`, `UserCheck`, and `OperationCheck`.

### Commit Checks

The commit check is the first leaf in the tree above. What the word "commit" describes is the execution time at which this particular check is executed. That is, this check executes after all changes have been made within a request but **before** those changes are ever committed to the database. This type of check allows you to verify the final state of an object as it will be committed. The effective implementation of `CommitCheck` is specified below:

```
public abstract class CommitCheck<T> implements Check<T> {
    public abstract boolean ok(T object, RequestScope requestScope, Optional<ChangeSpec> changeSpec);
}
```

The arguments are briefly described:

  1. `object`. The first argument is the object in its fully modified state.
  1. `requestScope`. This is the request scope object for the request.
  1. `changeSpec`. The `ChangeSpec` object provides an overview of the changes to this object. This is only present in the case of an `UpdatePermission` check since it is not valid for other operations.

### Operation Checks

Operation checks are really the analog to `CommitCheck`. However, rather than waiting until commit time, `OperationCheck`s run before an action is ever taken (i.e. **inline**). These checks are preferred over commit checks whenever possible since they provide the ability for a request to fail sooner. The effective implementation is as follows:

```
public abstract class OperationCheck<T> implements InlineCheck<T> {
    public abstract boolean ok(T object, RequestScope requestScope, Optional<ChangeSpec> changeSpec);
}
```

The arguments to the function are the same as `CommitCheck`.

### User Checks

User checks depend strictly on the user. These are inline checks (i.e. they run as operations occur rather than deferring until commit time) which only take a `User` object as input. Effectively, the `UserCheck` class has the following definition:

```
public abstract class UserCheck implements InlineCheck {
    public abstract boolean ok(User user);
}
```

### Data Store Checks

In some cases, the check logic can be pushed down to the data store itself.  For example, a filter can be added to a
database query to remove elements from a collection where access is disallowed.

The definition of these checks is outside of the scope of Elide, but an example is provided for Hibernate in the repository.  

## Security of Shareable Models<a name="shareable">&nbsp;</a>

The following scenario illustrates what could happen _without_ Elide's concept of shareable models.

Imagine a scenario where Elide is used to model and expose a bank account.  In this example, there are 3 models:

1. A user
1. An account
1. An account transaction

A user has one or more accounts which each have one or more transactions.  In this example, the developer has implemented
simple security checks for the user model such that a user's model is only readable and writable by himself.  All other models
have no implemented checks.

Now let's say Sally is `/user/1` in our system.  An evil hacker wants to read Sally's transactions.  The hacker
creates a new account `/user/2`.  The hacker creates an empty account with no transactions: `/user/2/account/342`.

The hacker can then issue POST requests against `/user/2/account/342/relationships/transaction`.  These requests
attempt to add an existing (randomly selected) transaction belonging to another user to the hacker's account:

```
POST /user/2/account/342/relationships/transaction HTTP/1.1
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json

{
    "data": [
        { "type": "transaction", "id": "123" }
    ]
}
```

Once successfully assigned to the hacker's account, the hacker can now read and manipulate Sally's (or any other user's) transactions.

What makes this possible is that there is no lineage for objects which are loaded in this fashion.  A transaction is simply
referenced by its ID (123) bypassing any security checks that would have evaluated if the same object had been loaded starting from
the user model.

This behavior is disallowed by default and can only be enabled by explicitly making a model shareable with an associated security check.  
