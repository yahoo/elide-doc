---
layout: guide
group: guide
title: Migration From Elide 4
version: 5
---

Elide 4 documentation can be found [here](/pages/guide/v4/01-start.html).

## New Features in Elide 5.X

Elide 5 introduces three primary new features:
 - A new [semantic modeling layer and analytic query API](/pages/guide/v{{ page.version }}/04-analytics.html) for OLAP style queries against your database.
 - An [asynchronous API]((/pages/guide/v{{ page.version }}/11.5-asyncapi.html)) for API read requests with long durations.
 - [A mechanism](/pages/guide/v{{ page.version}}/02-data-model.html#api-versions) to version elide models and the corresponding API.

<!-- The analytics capabilities and asynchronous API were developed in conjunction with a powerful Analytics UI called [Yavin](https://yavin.dev/). -->

## API Changes

The only notable API change are:
- [Improved error responses](https://github.com/yahoo/elide/pull/1200) that are more compatible with the JSON-API specification.
- [FIQL operators are now case sensitive by default](https://github.com/yahoo/elide/pull/1519).  New case insensitive operators have been introduced allowing greater flexibility.  It is possible to revert to elide 4 semantics through configuration.

## Interface Changes

In addition to new features, Elide 5 streamlines a number of public interfaces to simplify concepts.  This includes:
 - A simpler `Check` class hierarchy.
 - A new `NonTransferable` permission (which replaces `SharePermission`).
 - Changes to Elide's `User` abstraction for authentication.
 - Lifecycle hooks have been restructured to better decouple their logic from Elide models.
 - Initializers have been removed.  Dependency Injection is available for models, checks, lifecycle hooks, and serdes.
 - A simpler and more powerful `DataStoreTransaction` interface.
 - GraphQL has its own `FilterDialect` interface.
 - The `Include` annotation now defaults to marking models as root level.
 - Elide settings has been stripped of unnecessary configuration options.

## Module & Package Changes

Because Elide 5 is a major release, we took time to reorganize the module & package structure including:
 - elide-example has been removed.  The only Elide examples we plan to maintain are the [spring boot](https://github.com/yahoo/elide-spring-boot-example) and [standalone](https://github.com/yahoo/elide-standalone-example) examples.
 - elide-contrib submodules have been promoted to mainline modules elide-swagger and elide-test.
 - elide-annotations has been absorbed into elide-core.
 - New modules were created for elide-async (async API), elide-model-config (the semantic layer), and elide-datastore/elide-datastore-aggregation (the analytics module).
 - Some classes in elide-core were reorganized into new packages.

### Security

#### Security Checks

Elide no longer has separate classes (`InlineCheck` & `CommitCheck`) that determine when a check runs (immediately before a field is read/written or immediately before transaction commit).  Instead, all checks (regardless of type) run immediately before a field is read/written except for checks on newly created objects (which run at transaction commit).  The new class hierarchy looks like this:

<div id="check-tree" style="height: 250px"></div>

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
          text: {name: 'UserCheck'}
        },
        {
          text: {name: 'OperationCheck'},
          children: [
            {text: {name: 'FilterExpressionCheck'}}
          ]
        }
      ]
    }
  })
</script>

See Elide's [security documentation](/pages/guide/v{{ page.version }}/03-security.html) for details on how to define checks.

#### NonTransferable & SharePermission

Prior to Elide 5, models were unshareable by default and had to be annotated with `SharePermission` to share them with other collections after creation.  In Elide 5, the default state is inverted.  All models are shareable by default and must be explicitly marked `NonTransferable` to limit collection assignment after creation.  

Similar to Elide 4:
1. All models, when initially created, can be added to any collection regardless of the `NonTransferable` annotation.
2. A user agent must have read permission on a model to change which collections it belongs to after creation.

#### User Object

Elide's `User` abstraction has four new changes:
1. `User` explicitly wraps a `java.security.Principal` object rather than a `java.lang.Object`.
2. `User` includes methods to get the identity/name of the underlying principal as well as any role memberships the principal has.
3. Elide JAXRS endpoints no longer require a function (named 'elideUserExtractionFunction') to map the `SecurityContext` to an underlying principal object.
4. Elide environments (spring & standalone) have their own predefined User subclasses:
    1. Elide Spring creates a subclass of User (`AuthenticationUser`) which wraps a Spring `org.springframework.security.core.Authentication` object.   
    2. Elide standalone creates a subclass of User (`SecurityContextUser`) which wraps a `javax.ws.rs.core.SecurityContext` object.

Security checks which dereference the `User` object will require changes to access the underlying principal object depending on the framework they use.

#### User Checks for newly created objects

When a new model instance is created, only user checks are evaluated.

### DataStoreTransaction Changes

#### Object Loading Changes

All methods which load objects from persistence now are passed an `EntityProjection` rather than a `Class`.  The projection has more information to help the `DataStore` optimize its loads including:
1. The data type to load.
2. The explicit list of attributes to fetch.
3. The explicit list of relationships to fetch (modeled as EntityProjections).
4. Any filter predicates to apply.
5. Any sorting to apply.
6. Any pagination to apply.

#### Relationship Fetching

The transaction `getRelation` method now takes a `Relationship` object instead of a `Class`.  The relationship is essentially a named `EntityProjection`.

#### Attribute Reads & Writes

The transaction `getAttribute` and `setAttribute` functions now take `Attribute` objects - a shared concept with the new `EntityProjection`.

#### Removal of accessUser function

The `DataStoreTransaction` no longer requires a method to access the User object during transaction initialization.

#### RequestScope in every contract

Nearly every method now takes a RequestScope object.

#### Contract changes for support methods

The methods `supportsFiltering`, `supportPagination`, and `supportSorting` include additional information to help data stores make more informed decisions.

### Lifecycle Hook Refactor

The life cycle hook function now includes extra parameters to indicate what operation is being performed on the model and when in the transaction lifecycle it occurred:
```java
public abstract void execute(LifeCycleHookBinding.Operation operation,
                             LifeCycleHookBinding.TransactionPhase phase,
                             T elideEntity,
                             RequestScope requestScope,
                             Optional<ChangeSpec> changes);
```

To register life cycle hooks, all the prior annotations have been replaced with [a single annotation](/pages/guide/v{{ page.version }}/02-data-model.html#annotation-based-hooks).  The hook logic now should reside outside the Elide model classes.

### New Public Interfaces

The following classes/interfaces have been refactored to limit exposure to only the public contract:
 - Pagination
 - Sorting
 - AuditLogger
 - LogMessage

To accomplish this, elide-core and elide-annotations had to be consolidated into a single artifact.

### Error Reporting

Elide 5 fixes a number of problems with error reporting:
1. All error responses are HTML encoded.
2. Exception names are no longer returned to clients in the error response.
3. Better, human readable descriptions were added for many errors.
4. The error status for JSON-API is now correctly encoded as a String (was a number before).
5. The JSON-API patch extension response now correctly returns an array of error objects.
