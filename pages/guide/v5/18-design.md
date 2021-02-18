---
layout: guide
group: guide
title: Design
version: 5
---

## Overview
The following guide is intended for developers who want to make changes to the Elide framework.  It will cover the design of various subsystems as well as topics for building and testing Elide.

1. Contents
{:toc}

### Module Layout

Elide is a mono-repo consisting of the following published modules:

| Module Name                     | Description                                                                      |
|---------------------------------|----------------------------------------------------------------------------------|
| elide-core                      | Contains modeling annotations, JSON-API parser, and core functions.              |
| elide-graphql                   | Contains the GraphQL parser.                                                     |
| elide-async                     | Contains Elide's asynchronous and data export APIs.                               |
| elide-swagger                   | Contains swagger document generation for JSON-API.                               |
| elide-standalone                | Opinionated embedded Jetty application with JAX-RS endpoints for Elide           |      
| elide-spring                    | Parent module for spring boot support                                            |      
| elide-spring-boot-autoconfigure | Elide spring boot auto configuration module                                      |
| elide-spring-boot-starter       | Elide spring boot starter pom                                                    |
| elide-test                      | JSON-API and GraphQL test DSLs for [Rest Assured Testing Framework](https://rest-assured.io/) |
| elide-integration-tests         | Integration tests that are run for JPA, Hibernate, and In-Memory data stores.    |
| elide-model-config              | HJSON Configuration language for the Aggregation store semantic layer.           |
| elide-datastore                 | Parent module for all data stores.                                               |
| elide-datastore-aggregation     | Datastore and semantic layer for processing analytic API queries.                |
| elide-datastore-hibernate       | Parent package for all hibernate and JPA stores.                                 |
| elide-datastore-hibernate3      | Legacy data store for Hibernate 3 support.                                       |
| elide-datastore-hibernate5      | Legacy data store for Hibernate 5 support.                                       |
| elide-datastore-jpa             | Primary data store for elide CRUD API queries.  Replaces legacy hibernate stores. |
| elide-datastore-mulitplex       | Support for multiple data stores.                                                |
| elide-datastore-noop            | Zero persistence store.  This is used for implementing simple POST functions.    |
| elide-datastore-search          | Text search store.  It must be used in conjunction with the JPA store.           |
| elide-datastore-inmemorydb      | Hashmap implementation of a datastore.                                           |
{:.table}
           
### Building

Elide is built using maven.  Because elide is a mono-repo with interdependencies between modules, it is recommended to fully build and install the project at least once:  

`mvn clean install`

Thereafter, individual modules can be built whenever making changes to them.  For example, the following command would rebuild only elide-core:

`mvn clean install -f elide-core`

Pull requests and release builds leverage [screwdriver][screwdriver.cd].   PR builds simply run the complete build along with code coverage:
`mvn -B clean verify coveralls:report`.

#### Release Versions

Elide follows [semantic versioning](https://semver.org/) for its releases.  Minor and patch versions only have the following version components: 
`MAJOR.MINOR.PATCH`.

Major releases are often pre-released prior to the publication of the final version.  Pre-releases have the following format:
`MAJOR.MINOR.PATCH-prCANDIDATE`.  For example, 5.0.0-pr2 is release candidate 2 of the Elide 5.0.0 version.

#### Release Builds

The release build is triggered by a github tag or release event.  Screwdriver will build the project and publish to bintray with the following command:
`mvn -B -DskipTests deploy --settings ./settings.xml`

To initiate a release, perform the following steps:
0. Checkout the Elide source code into a clean directory: 
   - `git clone git@github.com:yahoo/elide.git`
1. Run the following command to build a list of changelog entries since the prior release: 
   - `git log $CURRENT_VERSION... --pretty=format:'   * [view commit](https://github.com/yahoo/elide/commit/%H) %s ' --reverse`
   - The environment variable `$CURRENT_VERSION` must be set to the current elide version.
2. After the command runs, edit `changelog.md` on the release branch.  The file must be hand edited to break the log into sections for **Features** and **Fixes** along with a new heading for the current release.  Commit the changes and pull them into your local github clone.
3. Either run:
   - `mvn -B release:prepare` if the build is for a patch release.
   - `mvn -B release:prepare -DautoVersionSubmodules=true -DreleaseVersion=$NEXT_VERSION` for all other releases.  The environment variable $NEXT_VERSION must be set to the next elide release version.
2. Monitor the build and make sure it succeeds in screwdriver.cd.
3. In a browser, navigate to https://bintray.com/yahoo/maven/elide
4. Navigate to the release tag and then to "Maven Central"
5. Navigate to oss.sonatype.org
6. Click on profile and then drop down to user token
7. Copy the user token key and password into bintray.  Click Sync (to publish to maven central).  Click Publish (to release on bintray).

### Integration Tests

The elide-integration-tests module runs API tests against an embedded Jetty application with an H2 database for persistence.  Integration tests are run for the JPA, hibernate, and inmemory stores.  The module produce a 'test-jar' artifact that is then referenced for each data store module (jpa, hibernate, etc) that runs the corresponding tests.

Not every tests works for every store, and JUnit tags are leveraged to isolate the tests appropriate for each target.  

When run in an IDE, the inmemory store is leveraged.  To tests against a different data store, the IDE must be configured to:
1. Set a property that selects the [DataStoreTestHarness](https://github.com/yahoo/elide/blob/master/elide-core/src/main/java/com/yahoo/elide/core/datastore/test/DataStoreTestHarness.java) which in turn initializes the data store to test. 
2. Sets the classpath appropriately to the data store submodule that is being tested.

The following screenshot demonstrates configuring these two settings for the 'FilterIT' tests in IntelliJ:

![Configuring IT Tests In Intellij](/assets/images/intellij_config.png){:class="img-fluid"}

### High Level Design

The following diagram represents a high level component breakout of Elide.  Names in italics represent class names whereas other names represent functional blocks (made up of many classes).  Gray arrows represent client request and response flow through the system.  

![High Level Design](/assets/images/high_level_design.png){:class="img-fluid"}

Elide can be broken down into the following layers:

#### Parsing Layer

The parsing layer consists of a JSON-API parser and GraphQL parser.  This layer is responsible for mapping a client request in JSON-API or GraphQL into [Elide's internal request model](#client-request-model).  The parsers load, create, and manipulate Elide models via the `PersistentResource`.  

#### Business Logic Layer

The business logic layer is responsible for performing:
 - Authorization checks
 - Lifecycle hooks
 - Audit & Logging

All elide models (once loaded or created) are wrapped in a `PersistentResource`.  All attribute and relationship access (read & write) occur through this abstraction allowing a central place to enforce business rules.

In addition to invoking security checks and lifecycle hooks, the `PersistentResource` is also responsible for reading and writing the model and its fields to the persistence layer.

#### Persistence Layer

The persistence layer consists of two abstractions and their concrete implementations:

 - A `DataStore` which is responsible for telling Elide which models it manages and creating `DataStoreTransaction` objects.
 - A `DataStoreTransaction` which is created per request and is responsible for saving, loading, and deleting Elide models.   Each request's interactions with the persistence layer should occur atomically. 

Elide comes bundled with a number of `DataStore` [implementations](/pages/guide/v{{ page.version }}/06-datatstores.html).  The most notable are the JPA, Search, and Aggregation stores.

#### Client Request Model

The primary object in the client request model is the `EntityProjection`.  It represents the entire object graph to return for a particular client request.  The entity projection consists of `Attribute` objects (model fields), `Relationship` objects (named entity projections), and also whether the projection should be filtered, sorted, or paginated.  `Attribute` objects can take `Argument` objects as parameters.

#### Metadata and Configuration

Elide is configured either with Spring Boot or the elide-standalone module.  Application settings for spring and standalone are mapped to an internal `ElideSettings` object that configures the Elide framework (denoted by the `Elide` object).   

All static metadata about Elide models is extracted at service boot and stored in the `EntityDictionary`.  This class is used throughout Elide whenever a model must be read from or written to by the `PersistentResource`.

While earlier versions of Elide represented models as JVM classes, Elide 5 introduces its own `Type` system.  This allows Elide to register and use dynamic models that are not JVM classes or even models that are created after the service starts.

#### Modeling

CRUD models in Elide are created from JVM classes whereas analytic models are created either from JVM classes or HJSON configuration files.  In either case, Elide annotations are used to add metadata Elide needs to perform persistence and business rules.  All Elide annotations are documented [here](/pages/guide/v{{ page.version }}/15-annotations.html).

### Security Subsystem

Coming Soon.

### Analytic Query Subsystem

Coming Soon.
