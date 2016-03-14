---
layout: guide
group: guide
title: Test
---

The surface of an Elide web service can become quite large given the numerous ways of navigating a complex data model.  This can make testing daunting.
Elide has a [sibling project](github link) for testing the authorization logic of your service.  

## Overview

The test framework allows the developer to redefine the authorization rules for different classes of users in a domain specific language.

Provided some test data for a `DataStore`, the framework builds a graph (cycles removed) of every possible 
way to navigate the test data originating from the rootable entities.

For every collection and entity in the graph, it tests all combinations of CRUD operations - comparing the result returned from Elide with the expected result
defined in the domain specific language.  Any mismatches are reported as test failures.

## Domain Specific Language

The DSL is structured as a [gherkin](gherkin link) feature file with the following elements:

### Exposed Entities

Exposed entities is a table describing which JPA entities are exposed through Elide and which of those entities are rootable.  

```
    Given exposed entities
      | EntityName    | Rootable |
      | parent        | true     |
      | child         | false    |
```

### Users

There will be different classes of users who have access to the system.  A class of users are the set of users who share the same authorization
permissions.  Ideally, the developer should define a `user` for each permutation of authorization permissions they want to test.  
```
    And users
      # Amalberti father
      | Emmanuel |
      # Bonham parents
      | Mo       |
      | Margery  |
```

The concept of users is opaque to the security test framework.  It has no concept of authentication or user identity.  Instead the developer provides
a concrete implementation of a `UserFactory` which constructs the user objects your authorization code expects:

```
public interface UserFactory {
        User makeUser(String alias);
}
```

### Associated Permissions

Associated permissions is a table that defines which entities a given user class has access to which CRUD operations are allowed.

```
    And associated permissions
      | UserName  | EntityName | ValidIdsList            | EntityPermissions         | RestrictedReadFields  | RestrictedWriteFields |
       ########### ############ ##############            ########################### ####################### #######################
      | Mo        | parent     | Mo                      | Create,Read,Update        |                       | deceased              |
      | Mo        | parent     | Mo's Spouse             | Create,Read,Update        | otherSpouses          | deceased              |
      | Mo        | parent     | Emmanuel,Goran,Hina     | Read,Update               | otherSpouses          | [EXCLUDING] friends |
```

#### UserName
This column identifies the user class.

#### EntityName
This column identifies the JPA entity.  The name must match the name exposed via Elide.

#### ValidIdsList
There is a [grammar](...) which defines the syntax for this column.  In short, it can be one of the following:
1. A list of comma separated entity IDs.  The IDs much match the test data in the `DataStore`.
2. The keyword `[ALL]` which signifies all the IDs found in the test data for the given entity.
3. An expression `[type.collection]` where `type` is another entity and `collection` is a relationship inside of `type` that contains elements of type `EntityName`.  This expression semantically means: 'If the user has any access to an entity of type `type`, they should have access to everything inside that entity's collection `collection`.'  More concretly, this expression will get expanded to a comma separated list of IDs by first expanding type to the set of entities of type `type` the user class has access to.  For each of these entities, it will then expand to the list of IDs contained within `collection`.  Expressions of this type can be combined within lists of comma separated IDs.  

Aliases can also be defined to represent one or more comma separated IDs,  These aliases are expanded in the grammar expression prior to parsing.  Aliases are defined in the gherkin file:

```
    And aliases
      | Mo                  | 1 |
      | Margery             | 2 |
      | Mo's Spouse         | Margery |
      | Margery's Spouse    | Mo |
      | Margery's Ex        | Emmanuel |
      | Emmanuel            | 3 |
      | Emmanuel's Ex       | Margery |
      | Goran               | 4 |
      | Bonham Children     | 1,2,3 |
      | Amalberti Children  | 4,5,6 |
      | Tang Children       | 7 |
```

Aliases can reference other aliases.

#### EntityPermissions

Entity Permissions are the list of CRUD permissions that are allowed for the given list of entities for the given user.  They should be defined
as a comma separated list of the keywords 'Create', 'Read', 'Update', and 'Delete'.

#### RestrictedReadFields & RestrictedWriteFields

The list of entity fields the given user class should not be able to read or write respectively.
There is a [grammar](...) which defines the syntax for this column.  In short, it can be one of the following:
1. A comma separated list of fieldnames.
2. The keyword `[ALL]` which signifies all fields.
3. The keyword `[EXCLUDING]` followed by a list of fields.  This inverts the column to a white list of allowed fields instead of a blacklist of excluded fields.

### Disabled Test Ids

```
    And disabled test ids
      | CreateRelation:child#5/relationships/playmates:Denied=[1,2,3] |
      | CreateRelation:child#6/relationships/playmates:Denied=[3]     |

```

If you want to disable a test from running, you can do so by adding 'name' of the test to this list.  The 'name' of the tests are displayed
in the output of test framework executions.

## Complete Example

A full example of the configuration DSL can be found [here](...)

## Using The Framework

Using the framework can be broken down into the following steps:
1. Create a feature file using the described DSL.
2. Write a java program that does the following:
   1. Initializes the entity dictionary.
   2. Create test data.
   3. Create a user factory.
   4. Initialize a `ValidationDriver` 

'''
        setupEntityDictionary();
        setupDB();

        String featureFile = "SampleConfig.feature";

        UserFactory customUserFactory = new TestUserFactory();

        AuditLogger AuditLogger = new AuditLogger() {
            @Override
            public void commit() throws IOException {

            }
        };

        driver = new ValidationDriver(featureFile, customUserFactory, dataStore, AuditLogger);
'''

Given that the goal of the test framework is limited to testing authorization code (security check logic), the `DataStore` used to furnish test data
should ideally be orthogonal to the correctness of the tests.   We recommend using the provided Hibernate test data store which uses [flyway](...)
to create an in-memory mysql database with test data.

This database can be initialized
