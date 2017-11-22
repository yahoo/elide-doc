---
layout: guide
group: guide
title: GraphQL API
---

# API Usage (Client-side info)

Graph APIs are an evolution of web service APIs that serve and manipulate data for mobile & web applications.
They have a number of characteristics that make them well suited to this task:
1.  Most notably, they present a **data model** as an entity relationship graph and **accompanying schema**.
   1.  A well defined model allows for a consistent view of the data and a centralized way to manipulate an instance of the model or to cache it.
   2.  The schema provides powerful introspection capabilities that can be used to build tools to help developers understand and navigate the model.
2.  The API allows the client to **fetch or mutate as much or as little information in single roundtrip** between client and server.  This also
    shrinks payload sizes and simplifies the process of schema evolution.
3.  There is a **well defined standard** for the API that fosters a community approach to development of supporting tools & best practices.

Elide supports the two most widely adopted standards for graph APIs: JSON-API and GraphQL.

# GraphQL Through Elide

GraphQL is a language specification published by Facebook for constructing graph APIs.  The specification provides great flexibility
in API expression, but also little direction in terms of best practices for common mutation operations.  For example, it is silent on how to:

* Create a new object and add it to an existing collection in the same operation.
* Create a set of related, composite objects (a subgraph) and connect it to an existing, persisted graph.
* Differentiate between deleting an object vs disassociating an object from a relationship (but not deleting it).
* Change the composition of a relationship to something different.
* Reference a newly created object inside other mutation operations.
* Perform any combination of the above edits together so they can happen atomically in a single request.

Elide offers an opinionated GraphQL API that addresses exactly how to do these things in a uniform way across your entire data model graph.

## API Structure

GraphQL splits its schema into two kinds of objects:
1.  **Query objects** which are used to compose queries and mutations
2.  **Input Objects** which are used to supply input data to mutations

### Query Objects

Query Objects are more complex given that queries have to support filtering, sorting,
and pagination and not simply describe data.  Elide's GraphQL structure for queries and mutations is depicted below:

![image-title-here](/assets/images/graphql_uml.png){:class="img-responsive"}

Every entity in the entity relationship graph (defined by the JPA data model)
is broken into a series of attributes and relationships. Attributes are properties of the entity.
Relationships are links to other entities in the graph.

Every GraphQL schema must define a root document which represents the root of the graph.
In Elide, entities can be marked if they are directly navigable from the root of the
graph. Elide’s GraphQL root documents consists of _relationships_ to these rootable entities.
Each relationship is named by its pluralized type name in the GraphQL root document.

All other non-rootable entities in our schema must be referenced through traversal of the
relationships in the entity relationship graph.

Every relationship is modeled the same way.  Elide adopts Relay's pattern for pagination support.
Relationships are a collection of _edges_.  Each edge contains a _node_.  The _node_ is an instance of a
data model that is also a member of the relationship.   It contains attributes and its own set of relationships.

#### Relationship Arguments

In GraphQL, any property in the schema can take arguments.  Relationships in Elide have a standard
set of arguments that either constrain the edges fetched from a relationship or supply data to a mutation:

1. The **ids** parameter is a collection of node identifiers.  It is used to select one or more nodes from a relationship.
2. The **filter** parameter is used to build complex RSQLfilter predicates that select zero or more nodes from a relationship.
3. The **sort** parameter is used to order a relationship's edges by one or more node attributes.
4. The parameters **offset** and **first** are used to paginate a relationship across multiple API requests.
5. The **op** argument describes the operation to perform on the relationship. When not provided, this argument
defaults to a FETCH operation—which simply reads the collection of edges.
6. The **data** parameter is provided for operations that mutate the collection (UPSERT and REPLACE), It contains
a list of input objects that match the data type of the relationship.

Entity attributes generally do not take arguments. However, attributes can be annotated as computed which allows
the data model to define any number of arguments that are passed to the resolver of that attribute.

#### Relationship Operations

Elide GraphQL relationships support five relationship operations which can be broken into two groups: data operations and id operations.
The operations are separated into those that accept a _data_ argument and those that accept an _ids_ argument.

1. The **FETCH** operation retrieves a set of objects. When a list of ids is specified, it will only extract the set of objects within the
relationship with matching ids.  If no ids are specified, then the entire collection of objects will be returned to the caller.
2. The **DELETE** operation fully deletes an object from the system.
3. The **REMOVE** operation removes a specified set (qualified by the _ids_ argument) of objects from a relationship. This allows the caller to remove
relationships between objects without being forced to fully delete the referenced objects.
4. The **UPSERT** operation behaves much like SQL’s MERGE.  Namely, if the object already exists (based on the provided
id) then it will be updated otherwise it will be created. In the case of updates, attributes that are not specified are left unmodified.
5. The **REPLACE** operation is intended to replace an entire relationship with the set of objects provided in the _data_ argument.
**REPLACE** can be though of an **UPSERT** followed by an implicit **REMOVE** of everything else that was previously in the collection that the client
has authorization to see & manipulate.
