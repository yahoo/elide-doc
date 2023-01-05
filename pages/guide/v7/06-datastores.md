---
layout: guide
group: guide
title: Data Stores
description: Configuring Elide with Different Data Sources and Databases
version: 7
---

A data store is responsible for:

1. reading and writing entity models to/from a persistence layer.
2. providing transactions that make all persistence operations atomic in a single request. 
3. implementing filtering, sorting, and pagination.  
4. declaring the entities it manages persistence for.

If a data store is unable to fully implement filtering, sorting, or pagination, it can instead rely on the Elide
framework to perform these functions in memory.  By default however, Elide pushes these responsibilities to the store.  

# Included Stores

Elide comes bundled with a number of data stores:   
1. JPA Store - A data store that can map operations on a data model to an underlying relational database (ORM) or nosql persistence layer (OGM).  The JPA Store can work with any JPA provider.
1. Hibernate - Prior to the JPA Store, Elide had explicit support for Hibernate 3 and 5 data stores.
3. Hashmap Store - Data is persisted in a hash table on the JVM heap.
4. Multiplex Store - A multiplex store delegates persistence to different underlying stores depending on the data model.
5. Noop Store - A store which does nothing, allowing business logic in computed attributes and life cycle hooks to entirely implement CRUD operations on the model.
6. [Search Store](https://github.com/yahoo/elide/tree/master/elide-datastore/elide-datastore-search) - A store which provides full text search on text fields while delegating other requests to another provided store.
7. [Aggregation Store]({{site.baseurl}}/pages/guide/v{{ page.version }}/04-analytics.html) - A store which provides computation of groupable measures (similar to SQL group by).  The aggregation store has custom annotations that map an Elide model to native SQL queries against a JDBC database.

Stores can be included through the following artifact dependencies:

## JPA Store

```xml
<dependency>
    <groupId>com.yahoo.elide</groupId>
    <artifactId>elide-datastore-jpa</artifactId>
    <version>${elide.version}</version>
</dependency>
```

## Hibernate Store

```xml
<dependency>
    <groupId>com.yahoo.elide</groupId>
    <artifactId>elide-datastore-hibernate5</artifactId>
    <version>${elide.version}</version>
</dependency>
```

## In Memory Store

```xml
<dependency>
    <groupId>com.yahoo.elide</groupId>
    <artifactId>elide-datastore-inmemorydb</artifactId>
    <version>${elide.version}</version>
</dependency>
```

## Multiplex Store

```xml
<dependency>
    <groupId>com.yahoo.elide</groupId>
    <artifactId>elide-datastore-multiplex</artifactId>
    <version>${elide.version}</version>
</dependency>
```

## Noop Store

```xml
<dependency>
    <groupId>com.yahoo.elide</groupId>
    <artifactId>elide-datastore-noop</artifactId>
    <version>${elide.version}</version>
</dependency>
```

## Search Store

```xml
<dependency>
    <groupId>com.yahoo.elide</groupId>
    <artifactId>elide-datastore-search</artifactId>
    <version>${elide.version}</version>
</dependency>
```

## Aggregation Store

```xml
<dependency>
    <groupId>com.yahoo.elide</groupId>
    <artifactId>elide-datastore-aggregation</artifactId>
    <version>${elide.version}</version>
</dependency>
```

# Overriding the Store

## Overriding in Spring Boot

[Elide Spring Boot][elide-spring] is configured by default with the JPA data store.

To change the store, override the `DataStore` autoconfigure bean:

```java
@Bean
public DataStore buildDataStore(EntityManagerFactory entityManagerFactory) {
    final Consumer<EntityManager> TXCANCEL = (em) -> { em.unwrap(Session.class).cancelQuery(); };

    return new JpaDataStore(
            () -> { return entityManagerFactory.createEntityManager(); },
                (em -> { return new NonJtaTransaction(em, TXCANCEL); }));
}
```

## Overriding in Elide Standalone

[Elide Standalone][elide-standalone] is configured by default with the JPA data store.

To change the store, the `ElideStandaloneSettings` interface can be overridden to change the function which builds the `DataStore` object.  One of two possible functions should be overridden depending on whether the `AggregationDataStore` is enabled:

```java
    /**
     * Gets the DataStore for elide when aggregation store is disabled.
     * @param entityManagerFactory EntityManagerFactory object.
     * @return DataStore object initialized.
     */
    default DataStore getDataStore(EntityManagerFactory entityManagerFactory) {
        DataStore jpaDataStore = new JpaDataStore(
                () -> { return entityManagerFactory.createEntityManager(); },
                (em) -> { return new NonJtaTransaction(em, ElideStandaloneSettings.TXCANCEL); });

        return jpaDataStore;
    }

    /**
     * Gets the DataStore for elide.
     * @param metaDataStore MetaDataStore object.
     * @param aggregationDataStore AggregationDataStore object.
     * @param entityManagerFactory EntityManagerFactory object.
     * @return DataStore object initialized.
     */
    default DataStore getDataStore(MetaDataStore metaDataStore, AggregationDataStore aggregationDataStore,
            EntityManagerFactory entityManagerFactory) {
        DataStore jpaDataStore = new JpaDataStore(
                () -> { return entityManagerFactory.createEntityManager(); },
                (em) -> { return new NonJtaTransaction(em, ElideStandaloneSettings.TXCANCEL); });

        DataStore dataStore = new MultiplexManager(jpaDataStore, metaDataStore, aggregationDataStore);

        return dataStore;
    }
```

# Custom Stores

Custom stores can be written by implementing the `DataStore` and `DataStoreTransaction` interfaces.

## Enabling In-Memory Filtering, Sorting, or Pagination

If a Data Store is unable to fully implement sorting, filtering, or pagination, the Elide framework can perform
these functions in-memory instead.

The Data Store Transaction can inform Elide of its capabilities (or lack thereof) by returning a `DataStoreIterable` for any collection loaded:

```java
/**
 * Returns data loaded from a DataStore.   Wraps an iterable but also communicates to Elide
 * if the framework needs to filter, sort, or paginate the iterable in memory before returning to the client.
 * @param <T> The type being iterated over.
 */
public interface DataStoreIterable<T> extends Iterable<T> {

    /**
     * Returns the underlying iterable.
     * @return The underlying iterable.
     */
    Iterable<T> getWrappedIterable();


    /**
     * Whether the iterable should be filtered in memory.
     * @return true if the iterable needs sorting in memory.  false otherwise.
     */
    default boolean needsInMemoryFilter() {
        return false;
    }

    /**
     * Whether the iterable should be sorted in memory.
     * @return true if the iterable needs sorting in memory.  false otherwise.
     */
    default boolean needsInMemorySort() {
        return false;
    }

    /**
     * Whether the iterable should be paginated in memory.
     * @return true if the iterable needs pagination in memory.  false otherwise.
     */
    default boolean needsInMemoryPagination() {
        return false;
    }
}

```

# Multiple Stores

A common pattern in Elide is the need to support multiple data stores.  Typically, one data store manages most models, but some models may require a different persistence backend or have other needs to specialize the behavior of the store.  The multiplex store (`MultiplexManager`) in Elide manages multiple stores - delegating calls to the appropriate store which is responsible for a particular model.

## Spring Boot

To setup the multiplex store in spring boot, create a `DataStore` bean:


```java
@Bean
public DataStore buildDataStore(EntityManagerFactory entityManagerFactory) {

    final Consumer<EntityManager> TXCANCEL = (em) -> { em.unwrap(Session.class).cancelQuery(); };

    //Store 1 manages Book, Author, and Publisher
    DataStore store1 = new JpaDataStore(
            entityManagerFactory::createEntityManager,
            (em) -> { return new NonJtaTransaction(em, TXCANCEL); },
            Book.class, Author.class, Publisher.class
    );

    //Store 2 is a custom store that manages Manufacturer
    DataStore store2 = new MyCustomDataStore(...);

    //Return the new multiplex store...
    return new MultiplexManager(store1, store2);
}
```

## Elide Standalone

To setup the multiplex store in Elide standalone, override the getElideSettings function:

```java
    /**
     * Gets the DataStore for elide when aggregation store is disabled.
     * @param entityManagerFactory EntityManagerFactory object.
     * @return DataStore object initialized.
     */
    default DataStore getDataStore(EntityManagerFactory entityManagerFactory) {
        //Store 1 manages Book, Author, and Publisher
        DataStore store1 = new JpaDataStore(
                () -> { return entityManagerFactory.createEntityManager(); },
                (em) -> { return new NonJtaTransaction(em, ElideStandaloneSettings.TXCANCEL); },
                Book.class, Author.class, Publisher.class
        );

        //Store 2 is a custom store that manages Manufacturer
        DataStore store2 = new MyCustomDataStore(...);

        //Create the new multiplex store...
        return new MultiplexManager(store1, store2);
    }
}
```

[elide-standalone]: https://github.com/yahoo/elide/tree/master/elide-standalone
[elide-spring]: https://github.com/yahoo/elide/tree/master/elide-spring/elide-spring-boot-autoconfigure
