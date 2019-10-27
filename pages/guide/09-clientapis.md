---
layout: guide
group: guide
title: Client APIs
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

* [JSON-API]({{site.baseurl}}/pages/guide/10-jsonapi.html)
* [GraphQL]({{site.baseurl}}/pages/guide/11-graphql.html)

## Type Coercion

Elide attempts to deserialize and coerce data model fields in the client payload into the underlying type defined in the JPA model.  Similarily, Elide 
will serialize JPA model fields into the text format defined by the schema of the client payload.

Beyond primitive, numeric, and String types, Elide can serialize and deserialize complex and user defined types.

### User Type Registration

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

Then register the `Serde` with Elide:

```java
CoerceUtil.register(targetType, serde);
```

### Date Coercion

[Elide standalone](https://github.com/yahoo/elide/tree/master/elide-standalone) has built-in support for either:
 - Epoch based dates (serialized as a long)
 - [ISO8601](https://www.iso.org/iso-8601-date-and-time-format.html) based dates (serialized as a String `yyyy-MM-dd'T'HH:mm'Z')

Elide standalone defaults to ISO8601 dates.  This can be toggled by overriding the following setting in `ElideStandaloneSettings`:

```java
    /**
     * Whether Dates should be ISO8601 strings (true) or epochs (false).
     * @return
     */
    default boolean enableIS06081Dates() {
        return true;
    }
```

If using Elide as a library, the following date serdes can be registered:
1. [IS8601 Serde](https://github.com/yahoo/elide/blob/master/elide-core/src/main/java/com/yahoo/elide/utils/coerce/converters/ISO8601DateSerde.java)
2. [Epoch Serde](https://github.com/yahoo/elide/blob/master/elide-core/src/main/java/com/yahoo/elide/utils/coerce/converters/EpochToDateConverter.java)

### UUID Coercion

Elide has built in support for converting between String and UUIDs.  The conversion leverages `UUID.fromString`. 

### Enum Coercion

Elide has built in support for converting between Strings or Integers to enumeration types (by name or value respectively).
