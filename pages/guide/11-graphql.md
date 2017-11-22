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
The operations are separated into those that accept a _data_ argument and those that accept an _ids_ argument:


| Operation | Data | Ids |
| --------- |------|-----|
| Upsert    | ✓    | X   |
| Fetch     | X    | ✓   |
| Replace   | ✓    | X   |
| Remove    | X    | ✓   |
| Delete    | X    | ✓   |


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

#### Map Data Types

GraphQL has no native support for a map data type.  If a JPA data model includes a map, Elide translates this to a list of key/value pairs in the GraphQL schema.

### Making Calls

All calls must be `POST` requests made to the root endpoint. This specific endpoint will depend on where you mount the provided servlet.
For example, if the servlet is mounted at `/graphql`, all requests should be sent as:

```
POST https://yourdomain.com/graphql
```

### Example Data Model

All subsequent query examples are based on the following data model including `Book`, `Author`, and `Publisher`:

```java
@Entity
@Table(name = "book")
@Include(rootLevel = true)
public class Book {
    @Id public long id;
    public String title;
    @ManyToMany
    public Set<Author> authors;
    @ManyToOne
    Publisher publisher;
}
```
```java
@Entity
@Table(name = "author")
@Include(rootLevel = false)
public class Author {
    @Id public long id;
    public String name;
    @ManyToMany
    public Set<Book> books;
}
```
```java
@Entity
@Table(name = "publisher")
@Include(rootLevel = false)
public class Publisher {
    @Id public long id;
    public String name;
    @OneToMany
    public Set<Book> books;
}
```

### FETCH Examples

#### Fetch entire collection of Books with ID, Title, and Authors
```
book {
  id,
  title,
  authors
}
```

#### Fetch single book with Title and Authors
```
book(ids: [1]) {
  title,
  authors
} 
```

### UPSERT Examples

#### Create and Add a New Author to a Book
```
mutation book(op: UPSERT, data: {authors: [{name: "The added author"}]}) {
  id,
  authors
}
```

### DELETE Examples

#### Delete a Book
```
mutation book(op: DELETE, ids: [1]) {
  id
}
```
Deletes the book with `id = 1` and removes disassociates all relationships other entities might have with this object.

### REMOVE Examples

#### Remove an author from a book.

```
book(ids: [1]) {
    authors(op: REMOVE, ids: [3])
}
```
Removes the _association_ between book with `id = 1` and author with `id = 3`, however, the author is still present in the persistence store.

### REPLACE Examples
  
#### Replace All Book Authors
```
mutation book(op: REPLACE, data: {authors:[{ name: "The New Author" }]}) {
  id,
  authors
}
```

### Complex Queries

#### Replacing a particular nested field
Let's assume that in a complex scenario, we want to update the name of the 18th author of the 9th book. The corresponding query would be,
```
book(ids: [9]) {
    id,
    authors(op: REPLACE, data: {name: "New author"}) {
        title
    }
}
```
The above payload structure helps us manipulate a specific entity amongst several different entities linked with to same parent as under.
```
book(id = 9)
| \ \
.. .. authors(id = 18)
      |
      name
```
#### Replacing two seperate fields linked to the same parent
Let's say we want to replace the title of two seperate books associated with the same author. The corresponding query would look like,
```
author(ids: [1]) {
    id,
    books(op: REPLACE, data: [{id: 1, title: "New title"}, {id: 2, title: "New title"}]) {
        id
    }
}
```
The above payload structure helps us manipulate attributes associated with two different entities having the same parent entity as under.
```
author
|     \
|      \
books   books
|  \    |  \
|   \  ...  title
...  title
```
#### Replacing fields of two seperate entities associated to the same parent
Now lets say we want to modify a ``Book`` and a `Publisher` name. This can be accomplished in a single query as under.
```
books(ids: [1]) {
    id,
    authors(op: REPLACE, data: [{id: 1, name: "New author"}]) {
        id
    },
    publisher(op: REPLACE, data: [{id: 1, name: "New name"}]) {
        id
    }
}
```
The above payload structure helps us manipulate attributes of two seperate entities associated with the same parent in a single transaction as under.
```
books
|      \
authors  publisher
|      |
name  name
```

#### Allowing multiple operations in a single transaction
We can get fancy and allow for multiple operations, like replacing title of a book and deleting a publisher, all in a single transaction.
```
books(ids: [1]) {
    id,
    authors(op: REPLACE, data: [{id: 1, name: "New author"}]) {
        id
    },
    publisher(op: REMOVE, ids: [1]) {
        id
    }
}
```
