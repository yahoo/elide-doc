---
layout: default
group: default
title: JSON API
---

<a href="https://github.com/yahoo/elide">
  <img style="position: fixed; top: 0; right: 0; border: 0; z-index: 2000" class="hidden-xs" src="https://camo.githubusercontent.com/365986a132ccd6a44c23a9169022c0b5c890c387/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f7265645f6161303030302e706e67" alt="Fork me on GitHub" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_right_red_aa0000.png" />
</a>

<div class="jumbotron">
  <div class="container">
    <div style="text-align: center">
      <img src="/assets/images/elide.svg" alt="Elide" width="340px" style="padding: 40px 0" />
      <h2>
        <!-- <img src="/assets/images/jsonapi.png" style="float: left" /> -->
        Stand up <a href="http://jsonapi.org/"><span style="font-family: monospace">{json:api}</span></a>
        web services backed by <br/> JPA annotated models in less than <em>15 minutes</em>
      </h2>
    </div>
  </div>
</div>

<div class="container">
  <div class="row" style="text-align: center">
    <h1 style="margin-top: 0px; margin-bottom: 30px">
      <a href="/pages/guide/01-start.html"><i class="fa fa-fast-forward"></i> Get Started</a>
    </h1>
  </div>

  <div class="row">

    <div class="col-md-4">
      <div style="text-align: center">
        <i class="fa fa-server fa-3x"></i>
        <p>Quickly build and deploy <b>production quality</b> web services that expose your data as a service.</p>
      </div>
    </div>

    <div class="col-md-4">
      <div style="text-align: center">
        <i class="fa fa-question-circle fa-3x"></i>
        <p>Elide is a Java library that enables you to stand up a <a href="http://jsonapi.org">JSON API</a> web service with <b>minimal effort</b> starting from a JPA annotated data model.</p>
      </div>
    </div>

    <div class="col-md-4">
      <div style="text-align: center">
        <i class="fa fa-at fa-3x"></i>
        <p>JPA enables you to use an ORM or, if you prefer, any persistence technology that support JPA&mdash;<b>Elide is agnostic</b> to your particular persistence strategy.</p>
      </div>
    </div>
  </div>

  <div class="row">
    <div class="col-md-3">
      <div style="text-align: center">
        <i class="fa fa-lock fa-3x"></i>
        <p><b>Security comes standard.</b> Controlling access to your data is as simple as defining your rules and annotating your models.</p>
      </div>
    </div>

    <div class="col-md-3">
      <div style="text-align: center">
        <img src="/assets/images/atom.png" height="45px" style="padding: 4px">
        <p>Elide supports the <a href="http://jsonapi.org/extensions/jsonpatch/">JSON API Patch extension</a> which enables multiple create, edit, and delete operations in a <b>single atomic request</b>.</p>
      </div>
    </div>

    <div class="col-md-3">
      <div style="text-align: center">
        <i class="fa fa-github-alt fa-3x"></i>
        <p>Elide is 100% <b>open source</b> and available on <a href="https://github.com/yahoo/elide">github</a>. Released under the commercial-friendly <a href="http://www.apache.org/licenses/LICENSE-2.0.html">Apache License, Version 2.0</a>.</p>
      </div>
    </div>

    <div class="col-md-3">
      <div style="text-align: center">
        <i class="fa fa-mobile fa-3x"></i>
        <p><b>Mobile Friendly.</b> JSON API lets developers fetch entire object graphs in a single round trip. With sparse fields, only the requested elements of the data model are returned.</p>
      </div>
    </div>

    <div class="col-md-2"></div>
  </div>

  <hr />

  <div class="row">
    <div class="col-md-8">
      <div class="embed-responsive embed-responsive-16by9">
        <iframe class="embed-responsive-item" src="https://www.youtube.com/embed/dhb9ooXhOeg" frameborder="0" allowfullscreen></iframe>
      </div>
    </div>
    <div class="col-md-4">
      <div style="text-align: center">
        <i class="fa fa-youtube-square fa-3x"></i>
        <p>In this 13 minute tutorial, we demonstrate how to stand up Elide using <a href="http://www.dropwizard.io/">Dropwizard</a>.</p>
        <p>We build a JSON API web service that exposes two models: User and Post.</p>
        <p>We also demonstrate how to create, list and delete posts using <a href="http://www.getpostman.com/">Postman</a>.</p>
      </div>
    </div>
  </div>

  <hr />
</div>

<!-- <div class="row">
  <div class="col-md-6">
    <h2><img src="/assets/images/jsonapi.png" height="96px"></h2>
    <ul>
      <li>JSON API is a modern <a href="http://jsonapi.org/format/">specification</a> for building APIs in JSON</li>
      <li>Reduces round trips to the server</li>
      <li>Mobile friendly with a polyglot of <a href="http://jsonapi.org/implementations/#client-libraries">clients</a></li>
    </ul>
  </div>
</div>
 -->
