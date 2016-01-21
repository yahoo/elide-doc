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

Lifecycle event triggers embed business logic with the entity bean. As entity bean attributes are updated by Elide, any defined triggers will be called.  `@On...` annotations define which method to call for these triggers:

```Java
@Entity
class Book {
   @Column
   public String title;

   @OnUpdate("title")
   public void onUpdateTitle() {
      // title attribute updated
   }

   @OnCommit("title")
   public void onCommitTitle() {
      // title attribute update committed
   }

   @OnCommit
   public void onCommitBook() {
      // book entity committed
   }

   @OnDelete
   public void onDeleteBook() {
      // book entity deleted
   }
}
```

Specifying an annotation without a value executes the denoted method on every instance of that action (i.e. every update, commit, etc.). However, if a value is specified in the annotation, then that particular method is only executed when the specific operation occurs to the particular field. Below is a description of each of these annotations and their function:

1. `@OnCreate` This annotation executes immediately when the object is created on the server-side and before it is committed/persisted in the backend.
1. `@OnDelete` This annotation executes immediately when the object has been deleted on the server-side.
1. `@OnUpdate(value)` If `value` is **not** specified, then this annotation executes on every update action to the object. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` is updated.
1. `@OnCommit(value)` If `value` is **not** specified, then this annotation executes every time the object is committed to the datastore. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` has changed.

## Initializers

Sometimes, lifecycle event triggers require access to other objects and resources outside of the model.  Since all model objects in Elide are ultimately constructed by the `DataStore`, and because elide does not directly depend on any specific dependency injection framework, elide provides an alternate way to initialize a model.

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

Initializers can be configured in a custom `DataStore` when the method `populateEntityDictionary` is invoked:

```java
    public void populateEntityDictionary(EntityDictionary dictionary) {

        /* Assuming this DataStore extends another... */
        super.populateEntityDictionary(dictionary);

        /*
         * Create an initializer for model Foobar, passing any runtime configuration to
         * the constructor of the initializer.
         */
        ...

        /* Bind the initializer to Foobar.class */
        dictionary.bindInitializer(foobarInitializer, Foobar.class);
    }
```

#Validation

Data models can be validated using [bean validation](http://beanvalidation.org/1.0/spec/).  This requires
*JSR303* data model annotations and wiring in a bean validator in the `DataStore`.
