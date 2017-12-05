---
layout: guide
group: guide
title: Data Models
---
<style>
.annotation-list {
    font-size: 14pt;
    margin: 0 auto;
    max-width: 800px;
}

.annotation-list .list-label {
    font-weight: bold;
}

.annotation-list .list-value {
    margin-left: 10px;
}

.annotation-list .code-font {
    font-family: "Courier New", Courier, monospace;
    margin-left: 10px;
}
</style>

Elide generates its API entirely based on the concept of **Data Models**. In summary, these are [JPA-annotated](http://www.oracle.com/technetwork/java/javaee/tech/persistence-jsp-140049.html) Java classes that describe the _schema_ for each exposed endpoint. While the JPA annotations provide a high-level description on how relationships and attributes are modeled, Elide provides a set of [security annotations](/pages/guide/03-security.html) to secure this model. Data models are intended to be a _view_ on top of the [datastore](TODO: Link datastores) or the set of datastores which support your Elide-based service.

**NOTE:** This page is a description on how to _create_ data models in the backend using Elide. For more information on _interacting_ with an Elide API, please see our [API usage documentation](/pages/guide/09-clientapis.html).

## JPA Annotations

The [JPA (Java Persistence API)](http://www.oracle.com/technetwork/java/javaee/tech/persistence-jsp-140049.html) library provides a set of annotations for describing relationships between entities. Elide makes use of the following JPA annotations: `@Entity`, `@OneToOne`, `@OneToMany`, `@ManyToOne`, and `@ManyToMany`. Any JPA property or field that is exposed via Elide and is not a _relationship_ is considered an _attribute_ of the entity.

If you need more information about JPA, please [review their documentation](http://www.oracle.com/technetwork/java/javaee/tech/persistence-jsp-140049.html) or see our examples below.

## Exposing a Model as an Elide Endpoint

After creating a proper data model, exposing it through Elide requires you configure _include_ it in Elide. Elide generates its API as a _graph_; this graph can only be traversed starting at a _root_ node. Rootable entities are denoted by applying `@Include(rootLevel=true)` to the top-level of the class. Non-rootable entities can be accessed only as relationships through the graph.

```java
@Include
@Entity
public class Author {
    private Long id;
    private String name;
    private Set<Book> books;

    @Id
    @GeneratedValue(strategy=GenerationType.AUTO)
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    @ManyToMany
    public Set<Book> getBooks() {
        return books;
    }

    public void setBooks(Set<Book> books) {
        this.books = books;
    }
}
```

```java
@Include(rootLevel=true)
@Entity
public class Book {
    private Long id;
    private String title;
    private Set<Author> authors;

    @Id
    @GeneratedValue(strategy=GenerationType.AUTO)
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    @ManyToMany
    public Set<Author> getAuthors() {
        return authors;
    }

    public void setAuthors(Set<Author> authors) {
        this.authors = authors;
    }
}
```

Considering the example above, we have a full data model that exposes a specific graph. Namely, a root node of the type `Author` and a bi-directional relationship from `Author` to `Book`. That is, one can access all `Author` objects directly, but must go _through_ an author to see information about any specific `Book` object.

All public getters and setters are exposed through the Elide API if they are not explicitly marked `@Transient` or `@Exclude`. `@Transient` allows a field to be ignored by both Elide and an underlying persistence store while `@Exclude` allows a field to exist in the underlying JPA persistence layer without exposing it through the Elide API.

Much of the Elide per-model configuration is done via annotations. For a description of all Elide-supported annotations, please check out the [annotation overview](/pages/guide/11-annotations.html).

## Computed Attributes

A computed attribute is an entity attribute whose value is computed in code rather than fetched from a data store.

Elide supports computed properties through use of the `@ComputedAttribute` and `@ComputedRelationship` annotations. These annotations will indicate to Elide it should override the `@Transient` annotation on a field. 

A computed attribute can perform arbitrary computation and is exposed through Elide as a typical attribute.

```java
@Include
@Entity
public class Book {
    ...
    @Transient
    @ComputedAttribute
    public String getMyComputedAttribute(RequestScope requestScope) {
        return "My special string stored only in the JVM!";
    }
    ...
}
```

The same principles are analogous to `@ComputedRelationship`s.

## Lifecycle Hooks

Life cycle hooks are functions that embed business logic inline with Read, Create, Update, and Delete operations on a given data model. There are separate annotations for each CRUD operation and also each life cycle phase of the current transaction.

1. *Pre Security* - Executed prior to Elide security check evaluation.
1. *Pre Commit* - Executed immediately prior to transaction commit but after all security checks have been evaluated.
1. *Post Commit* - Executed immediately after transaction commit.

```java
@Entity
class Book {
   @Column
   public String title;

   @OnReadPreSecurity("title")
   public void onReadTitle() {
      // title attribute about to be read but security checks not yet executed.
   }

   @OnUpdatePreSecurity("title")
   public void onUpdateTitle() {
      // title attribute updated but security checks not yet executed.
   }

   @OnUpdatePostCommit("title")
   public void onCommitTitle() {
      // title attribute updated & committed
   }

   @OnCreatePostCommit
   public void onCommitBook() {
      // book entity created & committed
   }

   /**
    * Trigger functions can optionally accept a RequestScope to access the user principal.
    */
   @OnDeletePreCommit
   public void onDeleteBook(RequestScope scope) {
      // book entity deleted but not yet committed
   }
}
```

Trigger functions can either take zero parameters or a single `RequestScope` parameter.  The `RequestScope` can be used to access the user prinicipal object that initiated the
request:

```
   @OnReadPostCommit("title")
   public void onReadTitle(RequestScope scope) {
      User principal = scope.getUser();
 
      //Do something with the principal object...
   }

```

Read & update lifecycle hook annotation take an optional value that represents the entity field (attribute or relationship) which triggers the hook. If no value is specified, the hook is triggered for reads or updates to any field within the entity. Below is a description of each of these annotations and their function:

1. `@OnCreatePreSecurity` This annotation executes immediately when the object is created on the server-side but before _commit_ security checks execute and before it is persisted in the backend.
1. `@OnCreatePreCommit` This annotation executes after the object is created and all security checks are evaluated on the server-side but before it is persisted in the backend.
1. `@OnCreatePostCommit` This annotation executes after the object is created and persisted on the backend.
1. `@OnDeletePreSecurity` This annotation executes immediately when the object is deleted on the server-side but before security checks execute and before it is committed/persisted in the backend.
1. `@OnDeletePreCommit` This annotation executes after the object is deleted and all security checks are evaluated on the server-side but before it is committed/persisted in the backend.
1. `@OnDeletePostCommit` This annotation executes after the object is deleted and committed/persisted on the backend.
1. `@OnUpdatePreSecurity(value)` If `value` is **not** specified, then this annotation executes on every update action to the object. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` is updated.  This annotation executes immediately when the field is updated on the server-side but before security checks execute and before it is committed/persisted in the backend.
1. `@OnUpdatePreCommit(value)` If `value` is **not** specified, then this annotation executes on every update action to the object. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` is updated. This annotation executes after the object is updated and all security checks are evaluated on the server-side but before it is committed/persisted in the backend.
1. `@OnUpdatePostCommit(value)` If `value` is **not** specified, then this annotation executes on every update action to the object. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` is updated.  This annotation executes after the object is updated and committed/persisted on the backend.
1. `@OnReadPreSecurity(value)` If `value` is **not** specified, then this annotation executes every time an object field is read from the datastore. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` is read.  This annotation executes immediately when the object is read on the server-side but before security checks execute and before the transaction commits.
1. `@OnReadPreCommit(value)` If `value` is **not** specified, then this annotation executes every time an object field is read from the datastore. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` is read.  This annotation executes after the object is read and all security checks are evaluated on the server-side but before the transaction commits.
1. `@OnReadPostCommit(value)` If `value` is **not** specified, then this annotation executes every time an object field is read from the datastore. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` is read.  This annotation executes after the object is read and the transaction commits.

## Initializers

Sometimes models require additional information from the surrounding system to be useful. Since all model objects in Elide are ultimately constructed by the `DataStore`, and because Elide does not directly depend on any specific dependency injection framework (though you can still use your own [dependency injection frameworks](#dependency-injection)), Elide provides an alternate way to initialize a model.

Elide can be configured with an `Initializer` implementation for a particular model class.  An `Initializer` is any class which implements the following interface:

```java
@FunctionalInterface
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

## Dependency Injection

Dependency injection in Elide can be achieved by using [initializers](#initializers). To do so, implement your own store (or extend an existing store) and implement something like the following:

```java
public class MyStore extends HibernateStore {
    private final Injector injector;

    public MyStore(Injector injector, ...) {
        super(...);
        this.injector = injector;
    }

    @Override
    public void populateEntityDictionary(EntityDictionary) {
        /* bind your entities */
        for (Class<?> entityClass : yourEntityList) {
            dictionary.bindInitializer(injector::inject, entityClass);
        }
    }
}
```

Ultimately, each time an object of `entityClass` type is instantiated by Elide, Elide will run an initializer that allows the injection framework to inject into the new object.

If you're using the `elide-standalone` artifact, then this is already done [by default](https://github.com/yahoo/elide/blob/master/elide-standalone/src/main/java/com/yahoo/elide/standalone/datastore/InjectionAwareHibernateStore.java#L39).

## Validation

Data models can be validated using [bean validation](http://beanvalidation.org/1.0/spec/).  This requires
*JSR303* data model annotations and wiring in a bean validator in the `DataStore`.

## Philosophy

Data models are intended to be a _view_ on top of the [datastore](TODO: Link datastores) or the set of datastores which support your Elide-based service. While other JPA-based workflows often encourage writing data models that exactly match the underlying schema of the datastore, we propose a strategy of isolation on per-service basis. Namely, we recommend creating a data model that only supports precisely the bits of data you need from your underlying schema. Often times there will be no distinction when first building your systems. However, as your systems scale and you develop multiple services with overlapping datastore requirements, isolation often serves as an effective tool to **reduce interdependency** among services and **maximize the separation of concern**. Overall, while models can correspond to your underlying datastore schema as a one-to-one representation, it's not always strictly necessary and sometimes even undesireable.

As an example, let's consider a situation where you have two Elide-based microservices: one for your application backend and another for authentication (suppose account creation is performed out-of-band for this example). Assuming both of these rely on a common datastore, they'll both likely want to recognize the same underlying _User_ table. However, it's quite likely that the authentication service will only ever require information about user **credentials** and the application service will likely only ever need user **metadata**. More concretely, you could have a system that looks like the following:

**Table schema:**
```
id
userName
password
firstName
lastName
```

**Authentication schema:**
```
id
userName
password
```

**Application schema:**
```
id
userName
firstName
lastName
```

While you could certainly just use the raw table schema directly (represented as a JPA-annotated data model) and reuse it across services, the point is that you may be over-exposing information in areas where you may not want to. In the case of the _User_ object, it's quite apparent that the application service should never be _capable_ of accidentally exposing a user's private credentials. By creating isolated views per-service on top of common datastores, you sacrifice a small bit of [DRY principles](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself) for much better isolation and a more targeted service. Likewise, if the underlying table schema is updated with a new field that neither one of these services needs, neither service requires a rebuild and redeploy since the change is irrelevant to their function. 

**A note about microservices:** Another common technique to building microservices is for each service to have its own set of datastores entirely independent from other services (i.e. no shared overlap); these datastores are then synced by other services as necessary through a messaging bus. If your system architecture calls for such a model, it's quite likely you will follow the same pattern we have outlined here with _one key difference_: the underlying table schema for your _individual service's datastore_ will likely be exactly the same as your service's model representing it. However, overall, the net effect is the same since only the relevant information delivered over the bus is stored in your service's schema. In fact, this model is arguably more robust in the sense that if one datastore fails not all services necessarily fail.

