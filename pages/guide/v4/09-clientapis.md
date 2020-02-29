---
layout: guide
group: guide
title: Client APIs
version: 4
---

## Supported APIs

Graph APIs are an evolution of web service APIs that serve and manipulate data for mobile & web applications.
They have a number of characteristics that make them well suited to this task:
1.  Most notably, they present a **data model** as an entity relationship graph and an **accompanying schema**.
    * A well defined model allows for a consistent view of the data and a centralized way to manipulate an instance of the model or to cache it.
    * The schema provides powerful introspection capabilities that can be used to build tools to help developers understand and navigate the model.
2.  The API allows the client to **fetch or mutate as much or as little information in single roundtrip** between client and server.  This also
    shrinks payload sizes and simplifies the process of schema evolution.
3.  There is a **well defined standard** for the API that fosters a community approach to development of supporting tools & best practices.

Elide supports the two most widely adopted standards for graph APIs: 

* [JSON-API]({{site.baseurl}}/pages/guide/v{{ page.version }}/10-jsonapi.html)
* [GraphQL]({{site.baseurl}}/pages/guide/v{{ page.version }}/11-graphql.html)

## Common Concepts

All Elide APIs share a common set of concepts:
1.  The API exposes a set of related data models as an entity relationship graph.
2.  All models have a unique identifier.
3.  Models have attributes and relationships.
   1. Relationships are links to other models.  They can be traversed in the API.  If the relationship represents a collection, it can be sorted, filtered, and paginated.
   2. Attributes are properties of the model.  They can be simple or complex (objects or collections).
4.  Filtering, sorting, and pagination share common languages and expressions.
5.  Text and numeric representation of complex attributes is common.

### Type Coercion

Elide attempts to deserialize and coerce fields in the client payload into the underlying type defined in the data model.  Similarly, Elide 
will serialize the data model fields into the text format defined by the schema of the client payload.

Beyond primitive, numeric, and String types, Elide can serialize and deserialize complex and user defined types.

#### User Type Registration

To register a new type for serialization and deserialization, define a `Serde` (short for Serializer/Deserializer):

```java
/**
 * Bidirectional conversion from one type to another.
 * @param <S> The serialized type
 * @param <T> The deserialized type
 */
public interface Serde<S, T> {
    /**
     * Deserialize an instance of type S to type T.
     * @param val The thing to deserialize
     * @return The deserialized value
     */
    T deserialize(S val);

    /**
     * Serializes an instance of type T as type S.
     * @param val The thing to serialize
     * @return The serialized value
     */
    S serialize(T val);
}
```

At startup, Elide will automatically discover any `Serde` classes annotated with `ElideTypeConverter`:

```java
@ElideTypeConverter(type = OffsetDateTime.class, name = "OffsetDateTime")
public class OffsetDateTimeSerde implements Serde<String, OffsetDateTime> {
    @Override
    public OffsetDateTime deserialize(String val) {
        return OffsetDateTime.parse(val, DateTimeFormatter.ISO_OFFSET_DATE_TIME);
    }

    @Override
    public String serialize(OffsetDateTime val) {
        return val.format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
    }
}
```

#### Date Coercion

Elide has built-in support for either:
 - Epoch based dates (serialized as a long)
 - [ISO8601](https://www.iso.org/iso-8601-date-and-time-format.html) based dates (serialized as a String `yyyy-MM-dd'T'HH:mm'Z')

##### Spring Boot Configuration

[Elide Spring Boot][elide-spring] is configured by default to use IS08601 dates.

This can be toggled by overriding the `Elide` autoconfigure bean:

```java
    @Bean
    public Elide initializeElide(EntityDictionary dictionary, DataStore dataStore, ElideConfigProperties settings) {

        ElideSettingsBuilder builder = new ElideSettingsBuilder(dataStore)
                ...
                .withEpochDates();

        return new Elide(builder.build());
```

##### Elide Standalone Configuration

[Elide standalone][elide-standalone] defaults to ISO8601 dates.  This can be toggled by overriding the following setting in `ElideStandaloneSettings`:

```java
    /**
     * Whether Dates should be ISO8601 strings (true) or epochs (false).
     * @return
     */
    default boolean enableIS06081Dates() {
        return true;
    }
```

##### Elide Library Configuration

If using Elide as a library, the following date serdes can be registered:
1. [IS8601 Serde](https://github.com/yahoo/elide/blob/master/elide-core/src/main/java/com/yahoo/elide/utils/coerce/converters/ISO8601DateSerde.java)
2. [Epoch Serde](https://github.com/yahoo/elide/blob/master/elide-core/src/main/java/com/yahoo/elide/utils/coerce/converters/EpochToDateConverter.java)

#### UUID Coercion

Elide has built in support for converting between String and UUIDs.  The conversion leverages `UUID.fromString`. 

#### Enum Coercion

Elide has built in support for converting between Strings or Integers to enumeration types (by name or value respectively).

[elide-standalone]: https://github.com/yahoo/elide/tree/master/elide-standalone
[elide-spring]: https://github.com/yahoo/elide/tree/master/elide-spring/elide-spring-boot-autoconfigure
