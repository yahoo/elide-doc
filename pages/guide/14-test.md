---
layout: guide
group: guide
title: Test
---

The [elide-test-helpers](https://github.com/yahoo/elide/tree/master/elide-contrib/elide-test-helpers) package provides a JSON-API and GraphQL
type safe DSL that simplifies adding integration tests to your service.  The DSLs are designed to work with [Rest Assured](http://rest-assured.io/).

## Dependencies

The tests described here are based on a [simple blog example](https://github.com/yahoo/elide/tree/master/elide-example/elide-blog-example).

The example leverages: 
1. [Elide Standalone](https://github.com/yahoo/elide/tree/master/elide-standalone) for running the test service.
2. [JUnit 5](https://junit.org/junit5/) for adding tests.
3. [elide-test-helpers](https://github.com/yahoo/elide/tree/master/elide-contrib/elide-test-helpers) for the JSON-API and GraphQL DSLs.
4. [Rest Assured](http://rest-assured.io/) for issuing HTTP requests against the test service.

### Maven 
```xml
        <dependency>
            <groupId>com.yahoo.elide</groupId>
            <artifactId>elide-standalone</artifactId>
            <version>${elide.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>com.yahoo.elide</groupId>
            <artifactId>elide-test-helpers</artifactId>
            <version>${elide.version}</version>
            <exclusions>
                <exclusion>
                    <groupId>org.antlr</groupId>
                    <artifactId>antlr4-runtime</artifactId>
                </exclusion>
            </exclusions>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>com.jayway.restassured</groupId>
            <artifactId>rest-assured</artifactId>
            <version>${rest-assured.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <version>${junit5.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <version>${junit5.version}</version>
            <scope>test</scope>
        </dependency>
```

## Setup

Using elide standalone, you can setup a test service for integration tests
by having your test classes extend a common test base class like this one:

```java
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public class IntegrationTest {
    private ElideStandalone elide;

    protected static final String JDBC_URL = "jdbc:h2:mem:db1;DB_CLOSE_DELAY=-1;MVCC=TRUE";
    protected static final String JDBC_USER = "sa";
    protected static final String JDBC_PASSWORD = "";

    @BeforeAll
    public void init() throws Exception {

        //Instantiate elide standalone with common setting overrides:
        elide = new ElideStandalone(new ElideStandaloneSettings() {

            //Set the service port
            @Override
            public int getPort() {
                return 8080;
            }

            //Tell elide standalone where the models live
            @Override
            public String getModelPackageName() {
                return "com.foo.bar.models";
            }

            //Configure JPA properties
            public Properties getDatabaseProperties() {
                Properties options = new Properties();

                options.put("hibernate.show_sql", "true");
                options.put("hibernate.dialect", "org.hibernate.dialect.H2Dialect");
                options.put("hibernate.current_session_context_class", "thread");
                options.put("hibernate.jdbc.use_scrollable_resultset", "true");

                options.put("javax.persistence.jdbc.driver", "org.h2.Driver");
                options.put("javax.persistence.jdbc.url", JDBC_URL);
                options.put("javax.persistence.jdbc.user", JDBC_USER);
                options.put("javax.persistence.jdbc.password", JDBC_PASSWORD);

                return options;
            }
        });

        //Start elide in non-blocking mode.
        elide.start(false);
    }


    @AfterAll
    public void shutdown() throws Exception {
        elide.stop();
    }
}

```
## JSON-API DSL

Using Rest Assured and the JSON-API DSL, you can issue JSON-API requests and verify responses against your test service like this:

```java

    @Test
    void jsonApiTest() {
        when()
                .get("/api/v1/user")
                .then()
                .body(equalTo(
                        data(
                                resource(
                                        type( "user"),
                                        id("1"),
                                        attributes(
                                                attr("name", "Jon Doe"),
                                                attr("role", "Registered")
                                        )
                                ),
                                resource(
                                        type( "user"),
                                        id("2"),
                                        attributes(
                                                attr("name", "Jane Doe"),
                                                attr("role", "Registered")


                                        )
                                )
                        ).toJSON())
                )
                .statusCode(HttpStatus.SC_OK);
    }

```

The complete set of static DSL operators for JSON-API can be found [here](https://github.com/yahoo/elide/blob/master/elide-contrib/elide-test-helpers/src/main/java/com/yahoo/elide/contrib/testhelpers/jsonapi/JsonApiDSL.java).

## GraphQL DSL

Using Rest Assured and the GraphQL DSL, you can issue GraphQL requests and verify responses against your test service like this:

```java
    @Test
    void graphqlTest() {
        given()
            .contentType(MediaType.APPLICATION_JSON)
            .accept(MediaType.APPLICATION_JSON)
            .body("{ \"query\" : \"" + GraphQLDSL.document(
                query(
                    selection(
                        field("user",
                            selections(
                                field("id"),
                                field("name"),
                                field("role")
                            )
                        )
                    )
                )
            ).toQuery() + "\" }"
        )
        .when()
            .post("/graphql/api/v1")
            .then()
            .body(equalTo(GraphQLDSL.document(
                selection(
                    field(
                        "user",
                        selections(
                            field("id", "1"),
                            field( "name", "Jon Doe"),
                            field("role", "Registered")
                        ),
                        selections(
                            field("id", "2"),
                            field( "name", "Jane Doe"),
                            field("role", "Registered")
                        )
                    )
                )
            ).toResponse()))
            .statusCode(HttpStatus.SC_OK);
    }
```


The complete set of static DSL operators for GraphQL can be found [here](https://github.com/yahoo/elide/blob/master/elide-contrib/elide-test-helpers/src/main/java/com/yahoo/elide/contrib/testhelpers/graphql/GraphQLDSL.java).
