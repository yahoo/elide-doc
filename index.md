---
layout: default
---

<div class="text-light background-dark">
  <div class="jumbotron">
    <div class="container text-center">
      <h2>Model driven <span class="text-primary">{json:api}</span> & <span class="text-primary">GraphQL</span> web services for CRUD and Analytics.</h2>
      <a href="pages/guide/v7/01-start.html">
        <button type="button" class="btn btn-primary text-light my-3">Get Started</button>
      </a>
      <div class="mb-3">
        <img src="assets/images/elide-illustration.svg" class="img-fluid elide-illustration" alt="Elide Illustration">
      </div>
    </div>
  </div>
</div>

<div class="container text-center my-5">
  <img src="assets/images/elide-logo.svg" class="img-fluid mb-3" alt="Elide Logo">
  <h4 class="mx-2">Elide is a Java library that enables you to stand up JSON API or GraphQL web services in 4 simple steps.</h4>
</div>

<hr class="mx-5">

<div class="usage container my-3">
  <div class="text-center display-4 mb-2">How to use it</div>
  <ul class="nav nav-pills justify-content-center" role="tablist">
    <li class="nav-item" role="presentation"><a role="tab" class="nav-link active" data-toggle="tab" aria-controls="tab-crud" href="#tab-crud">CRUD</a></li>
    <li class="nav-item" role="presentation"><a role="tab" class="nav-link" data-toggle="tab" aria-controls="tab-analytics" href="#tab-analytics">Analytics</a></li>
  </ul>
  <div class="tab-content">
    <div role="tabpanel" class="tab-pane active" id="tab-crud">
      <div class="feature row align-items-center my-4">
        <div class="col-sm">
          <div class="mr-3">
            <h4>1. Define a model</h4>
            <p>Define a JPA annotated model including relationships to other models using Java, Kotlin, Groovy, and other JVM languages.</p>
          </div>
        </div>
        <div class="col-sm">
          <img src="assets/images/editor/crud/model-editor.png" class="img-fluid" alt="Editor: Model">
        </div>
      </div>
      <div class="feature row align-items-center my-4">
        <div class="col-sm">
          <div class="mr-3">
            <h4>2. Secure It</h4>
            <p>Control access to fields and entities through a declarative, intuitive permission syntax.</p>
          </div>
        </div>
        <div class="col-sm">
          <img src="assets/images/editor/crud/secure-editor.png" class="img-fluid" alt="Editor: Security">
        </div>
      </div>
      <div class="feature row align-items-center my-4">
        <div class="col-sm">
          <div class="mr-3">
            <h4>3. Expose It</h4>
            <p>Make instances of your new model accessible through a top level collection or restrict access only through relationships to other models</p>
          </div>
        </div>
        <div class="col-sm">
          <img src="assets/images/editor/crud/expose-editor.png" class="img-fluid" alt="Editor: Expose">
        </div>
      </div>
      <div class="feature row align-items-center my-4">
        <div class="col-sm">
          <div class="mr-3">
            <h4>4. Deploy & Query</h4>
            <p>And thats it - you are ready to deploy and query your data with JSON or GraphQL requests.</p>
          </div>
        </div>
        <div class="col-sm">
          <img src="assets/images/editor/crud/query.png" class="img-fluid" alt="Query">
        </div>
      </div>
    </div>
    <div role="tabpanel" class="tab-pane" id="tab-analytics">
      <div class="feature row align-items-center my-4">
        <div class="col-sm">
          <div class="mr-3">
            <h4>1. Define a model</h4>
            <p>Define an analytic model including tables, measures, dimensions, and joins with a friendly HJSON configuration language.</p>
          </div>
        </div>
        <div class="col-sm">
          <img src="assets/images/editor/analytics/model-editor.png" class="img-fluid" alt="Editor: Model">
        </div>
      </div>
      <div class="feature row align-items-center my-4">
        <div class="col-sm">
          <div class="mr-3">
            <h4>2. Secure It</h4>
            <p>Control access to fields and entities through a declarative, intuitive permission syntax.</p>
          </div>
        </div>
        <div class="col-sm">
          <img src="assets/images/editor/analytics/secure-editor.png" class="img-fluid" alt="Editor: Security">
        </div>
      </div>
      <div class="feature row align-items-center my-4">
        <div class="col-sm">
          <div class="mr-3">
            <h4>3. Connect It</h4>
            <p>Connect your models to one or more data sources.</p>
          </div>
        </div>
        <div class="col-sm">
          <img src="assets/images/editor/analytics/persist-editor.png" class="img-fluid" alt="Editor: Expose">
        </div>
      </div>
      <div class="feature row align-items-center my-4">
        <div class="col-sm">
          <div class="mr-3">
            <h4>4. Deploy & Query</h4>
            <p>And thats it - you are ready to deploy and query your data with JSON or GraphQL requests.</p>
          </div>
        </div>
        <div class="col-sm">
          <img src="assets/images/editor/analytics/query.png" class="img-fluid" alt="Query">
        </div>
      </div>
    </div>
  </div>
  <div class="text-center mt-5">
    <h2>Want to learn more?</h2>
    <a href="/pages/guide/v7/01-start.html">
      <button type="button" class="btn btn-primary text-light mb-2">Documentation</button>
    </a>
    <p>Or see our features below</p>
  </div>
</div>

<div class="text-light background-dark">
  <div class="container py-5">
    <div class="text-center display-4 mb-5">Features</div>
    <div class="feature row align-items-center">
      <div class="col-sm text-center text-sm-right d-block d-sm-none text-sm-center">
        <img src="assets/images/features/code-icon.png" class="img-fluid" alt="Features: Production Quality">
      </div>
      <div class="col-sm my-3 my-sm-0">
        <h4>Production Quality</h4>
        <p>Quickly build and deploy production quality web services that expose your data as a service.  Elide APIs support complex filtering rules, sorting, pagination, subscriptions, and text search.</p>
      </div>
      <div class="col-sm text-right d-none d-sm-block">
        <img src="assets/images/features/code-icon.png" class="img-fluid" alt="Features: Production Quality">
      </div>
    </div>
    <div class="feature row align-items-center elbow">
      <div class="elbow-right"></div>
      <div class="elbow-center"></div>
      <div class="elbow-left"></div>
    </div>
    <div class="feature row align-items-center">
      <div class="col-sm">
        <img src="assets/images/features/secure-icon.png" class="img-fluid" alt="Features: Security Comes Standard">
      </div>
      <div class="col-sm my-3 my-sm-0">
        <h4>Security Comes Standard</h4>
        <p>Controlling access to your data is as simple as defining your rules and annotating your models.</p>
      </div>
    </div>
    <div class="feature row align-items-center elbow">
      <div class="elbow-left"></div>
      <div class="elbow-center"></div>
      <div class="elbow-right"></div>
    </div>
    <div class="feature row align-items-center">
      <div class="col-sm text-center text-sm-right d-block d-sm-none">
        <img src="assets/images/features/mobile-icon.png" class="img-fluid" alt="Features: Mobile Friendly">
      </div>
      <div class="col-sm my-3 my-sm-0">
        <h4>Mobile Friendly</h4>
        <p>Fetch entire object graphs in a single round trip.  Subscribe to changes in your data model in realtime.  Only requested elements of the data model are returned.</p>
      </div>
      <div class="col-sm text-right d-none d-sm-block">
        <img src="assets/images/features/mobile-icon.png" class="img-fluid" alt="Features: Mobile Friendly">
      </div>
    </div>
    <div class="feature row align-items-center elbow">
      <div class="elbow-right"></div>
      <div class="elbow-center"></div>
      <div class="elbow-left"></div>
    </div>
    <div class="feature row align-items-center">
      <div class="col-sm">
        <img src="assets/images/features/atom-icon.png" class="img-fluid" alt="Features: Single Atomic Request">
      </div>
      <div class="col-sm my-3 my-sm-0">
        <h4>Single Atomic Request</h4>
        <p>Elide supports multiple data model mutations in a single request in either JSON-API or GraphQL. Create objects, add them to relationships, modify or delete together in a single atomic request.</p>
      </div>
    </div>
    <div class="feature row align-items-center elbow">
      <div class="elbow-left"></div>
      <div class="elbow-center"></div>
      <div class="elbow-right"></div>
    </div>
    <div class="feature row align-items-center">
      <div class="col-sm text-center text-sm-right d-block d-sm-none">
        <img src="assets/images/features/analytics-icon.png" class="img-fluid" alt="Features: Analytic Queries">
      </div>
      <div class="col-sm my-3 my-sm-0">
        <h4>Analytic Queries</h4>
        <p>Elide supports analytic queries against models crafted with its powerful semantic layer.  Elide APIs work natively with <a href="https://yavin.dev">Yavin</a> to visualize, explore, and report on your data.</p>
      </div>
      <div class="col-sm text-right d-none d-sm-block">
        <img src="assets/images/features/analytics-icon.png" class="img-fluid" alt="Features: Analytic Queries">
      </div>
    </div>
    <div class="feature row align-items-center elbow">
      <div class="elbow-right"></div>
      <div class="elbow-center"></div>
      <div class="elbow-left"></div>
    </div>
    <div class="feature row align-items-center">
      <div class="col-sm">
        <img src="assets/images/features/globe-icon.png" class="img-fluid" alt="Features: Open API">
      </div>
      <div class="col-sm my-3 my-sm-0">
        <h4>Open API</h4>
        <p>Explore, understand, and compose queries against your Elide API through generated OpenAPI documentation or GraphQL schema.</p>
      </div>
    </div>
    <div class="feature row align-items-center elbow">
      <div class="elbow-left"></div>
      <div class="elbow-center"></div>
      <div class="elbow-right"></div>
    </div>
    <div class="feature row align-items-center">
      <div class="col-sm text-center text-sm-right d-block d-sm-none">
        <img src="assets/images/features/customize-icon.png" class="img-fluid" alt="Features: Customize">
      </div>
      <div class="col-sm my-3 my-sm-0">
        <h4>Customize</h4>
        <p>Customize the behavior of data model operations with computed attributes, data validation annotations, and request lifecycle hooks.</p>
      </div>
      <div class="col-sm text-right d-none d-sm-block">
        <img src="assets/images/features/customize-icon.png" class="img-fluid" alt="Features: Customize">
      </div>
    </div>
    <div class="feature row align-items-center elbow">
      <div class="elbow-right"></div>
      <div class="elbow-center"></div>
      <div class="elbow-left"></div>
    </div>
    <div class="feature row align-items-center">
      <div class="col-sm">
        <img src="assets/images/features/annotation-icon.png" class="img-fluid" alt="Features: Storage Agnostic">
      </div>
      <div class="col-sm my-3 my-sm-0">
        <h4>Storage Agnostic</h4>
        <p>Elide is agnostic to your particular persistence strategy. Use an ORM or provide your own implementation of a data store.</p>
      </div>
    </div>
    <div class="feature row align-items-center elbow">
      <div class="elbow-left"></div>
      <div class="elbow-center"></div>
      <div class="elbow-right"></div>
    </div>
    <div class="feature row align-items-center">
      <div class="col-sm text-center text-sm-right d-block d-sm-none">
        <img src="assets/images/features/open-source-icon.png" class="img-fluid" alt="Features: Open Source">
      </div>
      <div class="col-sm my-3 my-sm-0">
        <h4>Open Source</h4>
        <p>Elide is 100% open source and available on <a href="https://github.com/yahoo/elide">Github</a>. Released under the commercial-friendly <a href="/pages/license.html">Apache License, Version 2.0</a>.</p>
      </div>
      <div class="col-sm text-right d-none d-sm-block">
        <img src="assets/images/features/open-source-icon.png" class="img-fluid" alt="Features: Open Source">
      </div>
    </div>

  </div>
</div>

<div class="container text-center my-5">
  <h2>Opinionated APIs for web & mobile</h2>
  <p>Improve the velocity and quality of your team's work.</p>
  <a href="/pages/guide/v7/01-start.html">
    <button type="button" class="btn btn-primary text-light">Get Started</button>
  </a>
</div>

<div class="footer text-light background-dark">
  <div class="container py-3">
    <div class="row">
      <div class="col-sm">
        <img src="assets/images/elide-white-logo.png" class="img-fluid" alt="Elide Logo">
      </div>
      <div class="col-sm links">
        <a href="/pages/guide/v7/01-start.html">Documentation</a>
        <a href="/pages/license.html">Licensing</a>
      </div>
      <div class="col-sm links">
        <a href="https://discord.com/widget?id=869678398241398854&theme=dark">Community</a>
      </div>
      <div class="col-sm links">
        <a href="https://github.com/yahoo/elide/releases">Releases</a>
      </div>
      <div class="col-sm">
        <a href="https://github.com/yahoo/elide">
          <button type="button" class="btn btn-secondary github">
            <img src="assets/images/GitHub-Mark-Light-32px.png" class="img-fluid" alt="Github Logo">
            <span>Github</span>
          </button>
        </a>
      </div>
    </div>
  </div>
</div>
