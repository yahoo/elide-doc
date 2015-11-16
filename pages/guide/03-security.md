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
Permissions include `ReadPermission`, `WritePermission`, `CreatePermission`, `DeletePermission`, and `SharePermission`.

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
all models must enumerate all security checks.  The declarations become highly redundant and error prone.

Elide allows hierarchical URL navigation.  Security checks are evaluated in the order in which the 
relationship graph is traversed.  

Consider a simple data model consisting of articles - each having zero or more comments.
A PATCH on `/article/1/comments/4` changing the comment _title_ field would be evaluated in the following order:

1. Read permission check on the article model.
1. Read field permission check on the article's `comments` relationship.
1. Read permission check on the comment model.
1. Write permission check on the comment model.
1. Read field permission check on the comment's `title` attribute.
1. Write field permission check on the comment's `title` attribute.

## Check

Checks are simply functions that return whether or not access should be granted to the requesting user. 
There are three kinds of checks:

### Model Checks
A model check grants or denies access based on the instance of the model being accessed.  It has the following interface:

```Java
public interface Check<T> {
    public boolean ok(PersistentResource<T> model);
}
```
It is evaluated for each model instance accessed.

### User Checks

In many cases, a security check is unrelated to a model instance and only depends on the user performing the action.
A user check extends a model check and adds the following additional function prototype:

```Java
public interface UserCheck<T> extends Check<T> {
    final static UserPermission ALLOW = UserPermission.ALLOW;
    final static UserPermission DENY = UserPermission.DENY;
    final static UserPermission FILTER = UserPermission.FILTER;

    UserPermission userPermission(User user);
}
```
User checks occur before model checks.  The model check may or may not be invoked depending on the return 
value of the `userPermission` function:

`DENY` rejects the user request and `ok` is not called. 
`ALLOW` accepts the user request and `ok` is not called. 
`FILTER` requires `ok` to be called.  This is useful when both the user and model checks
should be invoked, but the user check short circuits the more expensive model check.

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
