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
0. Checkout the Elide source code into a clean directory: `git clone git@github.com:yahoo/elide.git`
1. Run the following command to build a list of changelog entries since the prior release: `git log $CURRENT_VERSION... --pretty=format:'   * [view commit](https://github.com/yahoo/elide/commit/%H) %s ' --reverse`.  The environment variable $CURRENT_VERSION must be set to the current elide version.
2. After the command runs, edit `changelog.md` on the release branch.  The file must be hand edited to break the log into sections for **Features** and **Fixes** along with a new heading for the current release.  Commit the changes and pull them into your local github clone.
3. Either run:
   1. `mvn -B release:prepare` if the build is for a patch release.
   2. `mvn -B release:prepare -DautoVersionSubmodules=true -DreleaseVersion=$NEXT_VERSION` for all other releases.  The environment variable $NEXT_VERSION must be set to the next elide release version.
2. Monitor the build and make sure it succeeds in screwdriver.cd.
3. In a browser, navigate to https://bintray.com/yahoo/maven/elide
4. Navigate to the release tag and then to "Maven Central"
5. Navigate to oss.sonatype.org
6. Click on profile and then drop down to user token
7. Copy the user token key and password into bintray.  Click Sync (to publish to maven central).  Click Publish (to release on bintray).

### Integration Tests
### High Level Design
### Security Subsystem
### Analytic Query Subsystem
