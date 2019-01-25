---
layout: guide
group: guide
title: Data Stores
---

`DataStores` connect a data model to a persistence layer and provide transactions that make all persistence operations
atomic in a single request.  

# Included Stores

Elide comes bundled with a number of data stores:   
1. Hibernate - Hibernate is a JPA provider that can map operations on a data model to an underlying relational database (ORM) or nosql persistence layer (OGM).  Elide supports stores for Hibernate 3 and 5.
3. In Memory Store - Data is persisted in a hash table on the JVM heap.
4. Multiplex Store - A multiplex store delegates persistence to different underlying stores depending on the data model.
5. Noop Store - A store which does nothing allowing business logic in computed attributes and life cycle hooks to 
entirely implement CRUD operations on the model.

Stores can be included through the following artifact dependencies:

## Hibernate Store

```
<dependency>
    <groupId>com.yahoo.elide</groupId>
    <artifactId>elide-datastore-hibernate5</artifactId>
    <version>4.0</version>
</dependency>
```

## In Memory Store

```
<dependency>
    <groupId>com.yahoo.elide</groupId>
    <artifactId>elide-datastore-inmemorydb</artifactId>
    <version>4.0</version>
</dependency>
```

## Multiplex Store

```
<dependency>
    <groupId>com.yahoo.elide</groupId>
    <artifactId>elide-datastore-multiplex</artifactId>
    <version>4.0</version>
</dependency>
```

## Noop Store

```
<dependency>
    <groupId>com.yahoo.elide</groupId>
    <artifactId>elide-datastore-noop</artifactId>
    <version>4.0</version>
</dependency>
```

# Overriding the Store

The elide-standalone artifact is the simplest way to get started with Elide.  It runs an embedded Jetty container with
common default settings including the Hibernate 5 data store.

To change the store, the `ElideStandaloneSettings` interface can be overridden to change the function 
which builds the `ElideSettings` object:

```
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
        DataStore dataStore = new InjectionAwareHibernateStore(
                injector, Util.getSessionFactory(getHibernate5ConfigPath(), getModelPackageName()));
        EntityDictionary dictionary = new EntityDictionary(getCheckMappings());
        return new ElideSettingsBuilder(dataStore)
                .withUseFilterExpressions(true)
                .withEntityDictionary(dictionary)
                .withJoinFilterDialect(new RSQLFilterDialect(dictionary))
                .withSubqueryFilterDialect(new RSQLFilterDialect(dictionary))
                .build();

    }  
```

# Custom Stores

Custom stores can be written by implenting the `DataStore` and `DataStoreTransaction` interfaces.
