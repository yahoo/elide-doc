---
layout: guide
group: guide
title: Data Stores
version: 5
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
7. [Aggregation Store](https://github.com/yahoo/elide/tree/master/elide-datastore/elide-datastore-aggregation) - A store which provides computation of groupable measures (similar to SQL group by).  The aggregation store has custom annotations that map an Elide model to native SQL queries against a JDBC database.

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

    return new JpaDataStore(
            () -> { return entityManagerFactory.createEntityManager(); },
                (em -> { return new NonJtaTransaction(em); }));
}
```

## Overriding in Elide Standalone

[Elide Standalone][elide-standalone] is configured by default with the JPA data store.

To change the store, the `ElideStandaloneSettings` interface can be overridden to change the function 
which builds the `ElideSettings` object:

```java
/**
 * Elide settings to be used for bootstrapping the Elide service. By default, this method constructs an
 * ElideSettings object using the application overrides provided in this class. If this method is overridden,
 * the returned settings object is used over any additional Elide setting overrides.
 *
 * That is to say, if you intend to override this method, expect to fully configure the ElideSettings object to
 * your needs.
 *
 * @param injector Service locator for web service for dependency injection.
 * @return Configured ElideSettings object.
 */
default ElideSettings getElideSettings(ServiceLocator injector) {
    EntityManagerFactory entityManagerFactory = Util.getEntityManagerFactory(getModelPackageName(), new Properties());
    DataStore dataStore = new JpaDataStore(
            () -> { return entityManagerFactory.createEntityManager(); },
            (em -> { return new NonJtaTransaction(em); }));

    EntityDictionary dictionary = new EntityDictionary(getCheckMappings(), injector::inject);

    ElideSettingsBuilder builder = new ElideSettingsBuilder(dataStore)
            .withEntityDictionary(dictionary)
            .withJoinFilterDialect(new RSQLFilterDialect(dictionary))
            .withSubqueryFilterDialect(new RSQLFilterDialect(dictionary));

    if (enableIS06081Dates()) {
        builder = builder.withISO8601Dates("yyyy-MM-dd'T'HH:mm'Z'", TimeZone.getTimeZone("UTC"));
    }

    return builder.build();
}  
```

# Custom Stores

Custom stores can be written by implementing the `DataStore` and `DataStoreTransaction` interfaces.

## Enabling In-Memory Filtering, Sorting, or Pagination

If a Data Store is unable to fully or partially implement sorting, filtering, or pagination, the Elide framework can perform
this function in-memory instead.

The Data Store Transaction can inform Elide of its capabilities by overriding the following methods:

```java
/**
 * Whether or not the transaction can filter the provided class with the provided expression.
 * @param entityClass The class to filter
 * @param expression The filter expression
 * @return FULL, PARTIAL, or NONE
 */
default FeatureSupport supportsFiltering(Class<?> entityClass, FilterExpression expression) {
    return FeatureSupport.FULL;
}

/**
 * Whether or not the transaction can sort the provided class.
 * @param entityClass
 * @return true if sorting is possible
 */
default boolean supportsSorting(Class<?> entityClass, Sorting sorting) {
    return true;
}

/**
 * Whether or not the transaction can paginate the provided class.
 * @param entityClass
 * @return true if pagination is possible
 */
default boolean supportsPagination(Class<?> entityClass) {
    return true;
}
```

# Multiple Stores

A common pattern in Elide is the need to support multiple data stores.  Typically, one data store manages most models, but some models may require a different persistence backend or have other needs to specialize the behavior of the store.  The multiplex store (`MultiplexManager`) in Elide manages multiple stores - delegating calls to the appropriate store which is responsible for a particular model.

## Spring Boot

To setup the multiplex store in spring boot, create a `DataStore` bean:


```java
@Bean
public DataStore buildDataStore(EntityManagerFactory entityManagerFactory) {

    //Store 1 manages Book, Author, and Publisher
    DataStore store1 = new JpaDataStore(
            () -> { return entityManagerFactory.createEntityManager(); },
            (em -> { return new NonJtaTransaction(em); }),
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
ElideSettings getElideSettings(ServiceLocator injector) {
    EntityManagerFactory entityManagerFactory = Util.getEntityManagerFactory(getModelPackageName(),
            getDatabaseProperties());
    //Store 1 manages Book, Author, and Publisher
    DataStore store1 = new JpaDataStore(
            () -> { return entityManagerFactory.createEntityManager(); },
            (em -> { return new NonJtaTransaction(em); }),
            Book.class, Author.class, Publisher.class
    );

    //Store 2 is a custom store that manages Manufacturer
    DataStore store2 = new MyCustomDataStore(...);

    //Create the new multiplex store...
    DataStore multiplexStore = new MultiplexManager(store1, store2);

    EntityDictionary dictionary = new EntityDictionary(getCheckMappings(), injector::inject);

    //Construct the ElideSettings with the new multiplex store...
    ElideSettingsBuilder builder = new ElideSettingsBuilder(multiplexStore)
            .withEntityDictionary(dictionary)
            .withJoinFilterDialect(new RSQLFilterDialect(dictionary))
            .withSubqueryFilterDialect(new RSQLFilterDialect(dictionary))
            .withISO8601Dates("yyyy-MM-dd'T'HH:mm'Z'", TimeZone.getTimeZone("UTC"));
            .withAuditLogger(getAuditLogger());

    return builder.build();
}
```

[elide-standalone]: https://github.com/yahoo/elide/tree/master/elide-standalone
[elide-spring]: https://github.com/yahoo/elide/tree/master/elide-spring/elide-spring-boot-autoconfigure
