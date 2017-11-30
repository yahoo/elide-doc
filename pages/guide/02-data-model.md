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

Elide generates its API entirely based on the concept of **Data Models**. In summary, these are [JPA-annotated](http://www.oracle.com/technetwork/java/javaee/tech/persistence-jsp-140049.html) Java classes that describe the _schema_ for each exposed endpoint. While the JPA annotations provide a high-level description on how relationships and attributes are modeled, Elide provides a set of [security annotations](/pages/guide/03-security.html) to secure this model.

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

## JPA Annotations

The [JPA (Java Persistence API)](http://www.oracle.com/technetwork/java/javaee/tech/persistence-jsp-140049.html) library provides a set of annotations that are useful for imposing relational concepts on Java objects. Elide makes use of the following JPA annotations: `@Entity`, `@OneToOne`, `@OneToMany`, `@ManyToOne`, and `@ManyToMany`. These annotations indicate to Elide how to treat any particular field in your Elide data models. Namely, if a relationship attribute is present on a field or getter then that field is treated as a relationship. If no JPA relation-signifying annotation is found, then the field is assumed to be an _attribute_.

If you need more information about JPA, please [review their documentation](http://www.oracle.com/technetwork/java/javaee/tech/persistence-jsp-140049.html) or see our [examples below](#examples).

## Exposing a Model as an Elide Endpoint

After creating a proper data model, exposing it through Elide requires you configure _security_ and _include_ it in Elide. Minimally, that implies you should add the appropriate permission annotations and configure your `@Include` permission appropriately. Elide generates its API as a _graph_; this graph can only be traversed starting at a _root_ node. Rootable entities are denoted by applying `@Include(rootLevel=true)` to the top-level of the class. Non-rootable entities can be accessed only as relationships through the graph.

Many of the Elide per-model configuration is done via annotations. For a description of all Elide-supported annotations, please check out the [annotation overview](/pages/guide/11-annotations.html).

## Computed Properties

Elide supports computed properties by way of the `@ComputedAttribute` and `@ComputedRelationship` annotations. These are useful if your datastore is also tied to your Elide view data model. For instance, if you mark a field `@Transient`, a datastore such as Hibernate will ignore it. In the absence of the `@Computed*` attributes, Elide will too. However, when applying a computed property attribute, Elide will expose this field anyway.

## Lifecycle Hooks

Life cycle event triggers embed business logic with the entity bean. As entity bean attributes are updated by Elide, any defined triggers will be called.  `@On...` annotations define which method to call for these triggers.
There are separate annotations for each CRUD operation (_read_, _update_, _create_, and _delete_) and also each life cycle phase of the current transaction:

1. *Pre Security* - Executed prior to Elide _commit_ security check evaluation.
1. *Pre Commit* - Executed immediately prior to transaction commit but after all security checks have been evaluated.
1. *Pre Post* - Executed immediately after transaction commit.

```java
@Entity
class Book {
   @Column
   public String title;

   @OnReadPreSecurity("title")
   public void onReadTitle() {
      // title attribute about to be read but 'commit' security checks not yet executed.
   }

   @OnUpdatePreSecurity("title")
   public void onUpdateTitle() {
      // title attribute updated but 'commit' security checks not yet executed.
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

Specifying an annotation without a value executes the denoted method on every instance of that action (i.e. every update, read, etc.). However, if a value is specified in the annotation, then that particular method is only executed when the specific operation occurs to the particular field. Below is a description of each of these annotations and their function:

1. `@OnCreatePreSecurity` This annotation executes immediately when the object is created on the server-side but before _commit_ security checks execute and before it is committed/persisted in the backend.
1. `@OnCreatePreCommit` This annotation executes after the object is created and all security checks are evaluated on the server-side but before it is committed/persisted in the backend.
1. `@OnCreatePostCommit` This annotation executes after the object is created and committed/persisted on the backend.
1. `@OnDeletePreSecurity` This annotation executes immediately when the object is deleted on the server-side but before _commit_ security checks execute and before it is committed/persisted in the backend.
1. `@OnDeletePreCommit` This annotation executes after the object is deleted and all security checks are evaluated on the server-side but before it is committed/persisted in the backend.
1. `@OnDeletePostCommit` This annotation executes after the object is deleted and committed/persisted on the backend.
1. `@OnUpdatePreSecurity(value)` If `value` is **not** specified, then this annotation executes on every update action to the object. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` is updated.  This annotation executes immediately when the field is updated on the server-side but before _commit_ security checks execute and before it is committed/persisted in the backend.
1. `@OnUpdatePreCommit(value)` If `value` is **not** specified, then this annotation executes on every update action to the object. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` is updated. This annotation executes after the object is updated and all security checks are evaluated on the server-side but before it is committed/persisted in the backend.
1. `@OnUpdatePostCommit(value)` If `value` is **not** specified, then this annotation executes on every update action to the object. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` is updated.  This annotation executes after the object is updated and committed/persisted on the backend.
1. `@OnReadPreSecurity(value)` If `value` is **not** specified, then this annotation executes every time an object field is read from the datastore. However, if `value` is set, then the annotated method only executes when the field corresponding to the name in `value` is read.  This annotation executes immediately when the object is read on the server-side but before _commit_ security checks execute and before the transaction commits.
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

## Validation

Data models can be validated using [bean validation](http://beanvalidation.org/1.0/spec/).  This requires
*JSR303* data model annotations and wiring in a bean validator in the `DataStore`.

## Examples

Consider the following example models:

**Post.java**
```java
@Entity
@Include(rootLevel=true)
public class Post {
    private Long id;
    private String content;
    private Set<Comment> comments;

    @Id
    @GeneratedValue(strategy=GenerationType.AUTO)
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
            this.content = content;
    }

    @OneToMany
    public Set<Comment> getComments() {
        return comments;
    }

    public void setComments(Set<Comment> comments) {
        this.comments = comments;
    }
} 
```

**Comment.java**
```java
@Entity
@Include
public class Comment {
    private Long id;
    private String content;
    private Post post;

    @Id
    @GeneratedValue(strategy=GenerationType.AUTO)
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    @ManyToOne
    public Post getPost() {
        return post;
    }

    public void setPost(Post post) {
        this.post = post;
    }
} 
```

This example demonstrates an exposed model for a set of `Posts` and `Comments`. All posts in the system can be queried from the top-level by accessing the API-object named `post` since it is marked as a rootable entity. The only way to navigate to comments is directly through a `post` object since `comments` are not exposed at the root level.

<!-- TODO: Eventually we should just make a full, multi-page tutorial -->
For more information on accessing the exposed API, please see our [API usage documentation](TODO: Link API usage).

**NOTE:** There is no security on this model. For more information about securing your models, please review the [security documentation](/pages/guide/03-security.html).

