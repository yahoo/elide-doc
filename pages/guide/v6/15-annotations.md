---
layout: guide
group: guide
title: Annotation Overview
description: Data Modeling Annotation Overview
version: 6
---
<style>
.annotation-list {
    font-size: 14pt;
    margin: 0 auto;
    max-width: 800px;
}

.annotation-list .list-label {
    font-weight: bold;
}

.annotation-list .list-value {
    margin-left: 10px;
}

.annotation-list .code-font {
    font-family: "Courier New", Courier, monospace;
    margin-left: 10px;
}
</style>

Elide exposes data models using a set of annotations. To describe relational modeling, we rely on the well-adopted [JPA annotations]({{site.baseurl}}/pages/guide/v{{ page.version }}/02-data-model#annotations). For exposition and security, we rely on custom Elide annotations. A comprehensive list of supported Elide annotations is below.

## Core Annotations

{% include annotation_link_list source='core_annotations' %}

## Subscription Annotations

{% include annotation_link_list source='sub_annotations' %}

## Aggregation Annotations

{% include annotation_link_list source='agg_annotations' %}

## Annotation Details

{% include annotation_description source='core_annotations' %}
{% include annotation_description source='sub_annotations' %}
{% include annotation_description source='agg_annotations' %}
