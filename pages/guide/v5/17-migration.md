---
layout: guide
group: guide
title: Migration From Elide 4
version: 5
---

Elide 6 documentation can be found [here]({{site.baseurl}}/pages/guide/v6/01-start.html).
Elide 4 documentation can be found [here]({{site.baseurl}}/pages/guide/v4/01-start.html).

## New Features in Elide 5.X

Elide 5 introduces several new features:
 - A new [semantic modeling layer and analytic query API]({{site.baseurl}}/pages/guide/v{{ page.version }}/04-analytics.html) for OLAP style queries against your database.
 - An [asynchronous API]({{site.baseurl}}/pages/guide/v{{ page.version }}/11.5-asyncapi.html) for API read requests with long durations.
 - An [data export API]({{site.baseurl}}/pages/guide/v{{ page.version }}/11.5-asyncapi.html) for exporting flat models as CSV or JSON.
 - [A mechanism]({{site.baseurl}}/pages/guide/v{{ page.version}}/02-data-model.html#api-versions) to version elide models and the corresponding API.
 - The 'hasmember' and 'hasnomember' filter operator supports predicates that traverse to-many relationships (book.authors.name=hasmember='Foo').
 - New 'between' and 'notbetween' filter operators.
 - [Eliminates N+1 database query scenarios]({{site.baseurl}}/pages/guide/v{{ page.version}}/16-performance.html).

The analytics capabilities, asynchronous API, and table export API were developed in conjunction with a powerful Analytics UI called [Yavin](https://yavin.dev/). 

## API Changes

The only notable API change are:
- [Improved error responses](https://github.com/yahoo/elide/pull/1200) that are more compatible with the JSON-API specification.
- [FIQL operators are now case sensitive by default](https://github.com/yahoo/elide/pull/1519).  New case insensitive operators have been introduced allowing greater flexibility.  It is possible to revert to elide 4 semantics through configuration.
- JSON-API now validates requests for invalid sparse fields and throws a 400 error if present.
- To enable parameterized attributes in analytic queries, RSQL filter grammar was augmented to include support for field arguments.

## Interface Changes

In addition to new features, Elide 5 streamlines a number of public interfaces to simplify concepts.  This includes:
 - A simpler `Check` class hierarchy.
 - A new `NonTransferable` permission (which replaces `SharePermission`).
 - Changes to Elide's `User` abstraction for authentication.
 - Lifecycle hooks have been restructured to better decouple their logic from Elide models.
 - Initializers have been removed.  Dependency Injection is available for models, checks, lifecycle hooks, and serdes.
 - A simpler and more powerful `DataStoreTransaction` interface.
 - GraphQL has its own `FilterDialect` interface.
 - The `Include` annotation now defaults to marking models as root level.  The 'type' attribute was renamed to 'name'.
 - The `Include` annotation at the package level now denotes a namespace.  The 'name' attribute will be prepended to all elide models contained therein.
 - Elide settings has been stripped of unnecessary configuration options.
 - Elide 5 introduces a new type system for models allowing dynamic models that are not bound to JVM classes.
 - The interface for overriding JPQL predicate generation for filter operators includes more information about the filter.

## Module & Package Changes

Because Elide 5 is a major release, we took time to reorganize the module & package structure including:
 - elide-example has been removed.  The only Elide examples we plan to maintain are the [spring boot](https://github.com/yahoo/elide-spring-boot-example) and [standalone](https://github.com/yahoo/elide-standalone-example) examples.
 - elide-contrib submodules have been promoted to mainline modules elide-swagger and elide-test.
 - elide-annotations has been absorbed into elide-core.
 - New modules were created for elide-async (async API), elide-model-config (the semantic layer), and elide-datastore/elide-datastore-aggregation (the analytics module).
 - Some classes in elide-core were reorganized into new packages.

## Security

### Security Checks

Elide no longer has separate classes (`InlineCheck` & `CommitCheck`) that determine when a check runs (immediately before a field is read/written or immediately before transaction commit).  Instead, all checks (regardless of type) run immediately before a field is read/written except for checks on newly created objects (which run at transaction commit).  However, there is a method in Check that can force Elide to run the check at transaction commit preserving the legacy behavior.  The new class hierarchy looks like this:

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

Filter expression checks now take a `Type` instead of a `Class` when referring to the Elide model:

```java
public abstract FilterExpression getFilterExpression(Type<?> entityClass, RequestScope requestScope);
```

See Elide's [security documentation]({{site.baseurl}}/pages/guide/v{{ page.version }}/03-security.html) for details on how to define checks.

### NonTransferable & SharePermission

Prior to Elide 5, models were unshareable by default and had to be annotated with `SharePermission` to share them with other collections after creation.  In Elide 5, the default state is inverted.  All models are shareable by default and must be explicitly marked `NonTransferable` to limit collection assignment after creation.  

Similar to Elide 4:
1. All models, when initially created, can be added to any collection regardless of the `NonTransferable` annotation.
2. A user agent must have read permission on a model to change which collections it belongs to after creation.

### User Object

Elide's `User` abstraction has four new changes:
1. `User` explicitly wraps a `java.security.Principal` object rather than a `java.lang.Object`.
2. `User` includes methods to get the identity/name of the underlying principal as well as any role memberships the principal has.
3. Elide JAXRS endpoints no longer require a function (named 'elideUserExtractionFunction') to map the `SecurityContext` to an underlying principal object.
4. Elide environments (spring & standalone) have their own predefined User subclasses:
    1. Elide Spring creates a subclass of User (`AuthenticationUser`) which wraps a Spring `org.springframework.security.core.Authentication` object.   
    2. Elide standalone creates a subclass of User (`SecurityContextUser`) which wraps a `javax.ws.rs.core.SecurityContext` object.

Security checks which dereference the `User` object will require changes to access the underlying principal object depending on the framework they use.

## DataStoreTransaction Changes

### Object Loading Changes

All methods which load objects from persistence now are passed an `EntityProjection` rather than a `Class`.  The projection has more information to help the `DataStore` optimize its loads including:
1. The data type to load.
2. The explicit list of attributes to fetch.
3. The explicit list of relationships to fetch (modeled as EntityProjections).
4. Any filter predicates to apply.
5. Any sorting to apply.
6. Any pagination to apply.

### Relationship Fetching

The transaction `getRelation` method now takes a `Relationship` object instead of a `Class`.  The relationship is essentially a named `EntityProjection`.

### Attribute Reads & Writes

The transaction `getAttribute` and `setAttribute` functions now take `Attribute` objects - a shared concept with the new `EntityProjection`.

### Removal of accessUser function

The `DataStoreTransaction` no longer requires a method to access the User object during transaction initialization.

### RequestScope in every contract

Nearly every method now takes a RequestScope object.

### Contract changes for support methods

The methods `supportsFiltering`, `supportPagination`, and `supportSorting` include additional information to help data stores make more informed decisions.

### Replaced Object with Java Generics

All methods that referred to models as Objects now leverage Java generics instead. 

## Lifecycle Hook Refactor

The life cycle hook function now includes extra parameters to indicate what operation is being performed on the model and when in the transaction lifecycle it occurred:
```java
public abstract void execute(LifeCycleHookBinding.Operation operation,
                             LifeCycleHookBinding.TransactionPhase phase,
                             T elideEntity,
                             RequestScope requestScope,
                             Optional<ChangeSpec> changes);
```

To register life cycle hooks, all the prior annotations can be replaced with [a single annotation]({{site.baseurl}}/pages/guide/v{{ page.version }}/02-data-model.html#annotation-based-hooks).  The hook logic now should reside outside the Elide model classes.
However, legacy life cycle hook annotations remain supported.

## New Public Interfaces

The following classes/interfaces have been refactored to limit exposure to only the public contract:
 - Pagination
 - Sorting
 - AuditLogger
 - LogMessage

To accomplish this, elide-core and elide-annotations had to be consolidated into a single artifact.

## Error Reporting

Elide 5 fixes a number of problems with error reporting:
1. All error responses are HTML encoded.
2. Exception names are no longer returned to clients in the error response.
3. Better, human readable descriptions were added for many errors.
4. The error status for JSON-API is now correctly encoded as a String (was a number before).
5. The JSON-API patch extension response now correctly returns an array of error objects.

## JPQL Predicate Generation

The interface to override a JPQL predicate for a filter operator has new, richer contract:

```java
@FunctionalInterface
public interface JPQLPredicateGenerator {
    String generate(FilterPredicate predicate, Function<Path, String> aliasGenerator);
}
```

## Types instead of Classes

Elide models are no longer static JVM classes but instead leverage Elide's new `Type` system.  This change allows data stores to register models that are not static classes.
It is possible to convert between a Class and Type and vice versa.  An Elide model class can be converted to a Type by wrapping it in a `ClassType`:

```java
new ClassType(Book.class)
```

A Type can be converted to a model class by calling the following method:

```java
Optional<Class<T>> getUnderlyingClass();
```

The type of any model instance can be returned by calling the following static method on the `EntityDictionary`:

```java
public static <T> Type<T> getType(T object);
```
