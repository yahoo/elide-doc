---
layout: guide
group: guide
title: Extension
---
There are four common patterns to extend Elide with custom business logic:

1. Simple translations and computations
1. Wiring in a non-standard persistence backend
1. Adding logic around persistence life cycle events (create, delete, update attribute, etc)
1. Validation that write operations left the data model in a consistent state

#Simple Translations
It is sometimes required to perform simple computations or translations when a model attribute is read or written.
For example, a user model might require a cryptographic hash applied to a password field before it is persisted. 

It is generally not a good idea to put logic inside getter and setter functions that are used by JPA providers to 
hydrate and read attributes.  JPA does provide a `Transient` annotation that allows attributes and functions to exist
in a data model that are not persisted.  By default, Elide will not expose any attributes marked as `Transient`.  
However, this behavior can be overridden by also annotating the attribute with the `ComputedAttribute` Elide annotation.

To perform simple computations and translations, put them inside attribute getter and setter functions that are marked
both as `Transient` and a `ComputedAttribute`.

```java
@Entity
public class Person {
    private String givenName;
    private String familyName;

    @Transient
    @ComputedAttribute
    public String getFullName() {
        return givenName + " " + familyName;
    }
}
```

#Wiring in a Persistence Layer

While it is generally easier to use a JPA provider, sometimes this isn't possible or practical.  The backend may be a set
of web services whose responses must be coalesced into a single data model.  Wiring in a new backend involves creating a `DataStore`
and corresponding `DataStoreTransaction`.

A `DataStore` primarily creates `DataStoreTransaction` instances - one for each request.
A `DataStoreTransaction` is responsible for persistence of entities:

1. Loading objects & optionally applying filters during the load
1. Creating objects
1. Deleting objects
1. Saving objects
1. Committing the transaction

#Extending Life Cycle Events

TBD

Sometimes, business logic however requires access to other objects and resources outside of the model.  Since all model objects in Elide are ultimately constructed by the `DataStore`, and because elide does not directly depend on any specific dependency injection framework, elide provides an alternate way to initialize a model.

Elide can be configured with an `Initializer` implementation for a particular model class.  An `Initializer` is any class which implements the following interface:

```java
public interface Initializer<T> {
    /**
     * Initialize an entity bean
     *
     * @param entity Entity bean to initialize
     */
    public void initialize(T entity);
}
```

TODO - add example code for how to configure elide with initializers.

#Validation

Data models can be validated using [bean validation](http://beanvalidation.org/1.0/spec/).  This requires
*JSR303* data model annotations and wiring in a bean validator in the `DataStore`.
