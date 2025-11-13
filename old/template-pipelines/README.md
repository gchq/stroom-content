# _template-pipelines_ Content Pack

## Contents

The following represents the folder structure and content that will be imported in to Stroom with this content pack.

* _Template Pipelines_ 
    * _Fragments_
        * [Event Data Base](#event-data-base) `Pipeline`
    * [Alert To Detection](#alert-to-detection) `XSLT`
    * [Batch Search](#batch-search) `Pipeline`
    * [Context Data](#context-data) `Pipeline`
    * [Event Data (JSON)](#event-data-json) `Pipeline`
    * [Event Data (Text)](#event-data-text) `Pipeline`
    * [Event Data (XML)](#event-data-xml) `Pipeline`
    * [Indexing](#indexing) `Pipeline`
    * [JSON](#json-xslt) `XSLT`
    * [Reference Data](#reference-data) `Pipeline`
    * [Search Extraction](#search-extraction) `Pipeline`
    * [Standard Raw Extraction](#raw-extraction) `Pipeline`
    * [Statistic](#statistic) `Pipeline`

## Event Data Base

This is a fragment of a pipeline that is inherited from by the Event Data (....) pipelines. This pipeline fragment expects XML data (of any structure) which will be translated into event-logging format, then validated against the event-logging XML Schema before being written to the stream store.

## Alert To Detection

This XSLT converts `<records>` format alerts as created by Stroom Rules from Dashboards feature into `<Detections>` format.

For further information please refer to the section on [Search Extraction](#search-extraction).

## Batch Search

<!--TODO-->

## Context Data

This template pipeline is used for pipelines that process _Context_ data that is received alongside raw events. A _Context Data_ type pipeline is used to inject context data into another pipeline.

## Event Data (JSON)

Inherits from Event Data Base, adding a JSON parser in front of it. This pipeline can be used as a template for pipelines processing JSON format data into event-logging format XML. Pipelines inheriting from this will need to supply as a minimum an XSLT translation to convert the XML form of the JSON into event-logging form and an XSLT translation to decorate the event-logging XML with any additional data (e.g. IP -> hostname lookups).

## Event Data (Text)

Inherits from Event Data Base, adding a Data Splitter parser in front of it. This pipeline can be used as a template for pipelines processing text format data (e.g. Apache logs) into event-logging format XML. Pipelines inheriting from this will need to supply as a minimum a Text Converter to convert the text into XML, an XSLT translation to convert this XML into event-logging form and an XSLT translation to decorate the event-logging XML with any additional data (e.g. IP -> hostname lookups).

## Event Data (XML)

Inherits from Event Data Base, adding a Data Splitter parser in front of it. This pipeline can be used as a template for pipelines processing text format data (e.g. Apache logs) into event-logging format XML. Pipelines inheriting from this will need to supply as a minimum a Text Converter to convert the text into XML, an XSLT translation to convert this XML into event-logging form and an XSLT translation to decorate the event-logging XML with any additional data (e.g. IP -> hostname lookups).

## Indexing

<!--TODO-->

## JSON

An XSLT that provides utility template and associated functions that can be used to turn arbitrary XML into JSON.

The xsl function `stroom:json` called with a single XML node will return an `xs:string` containing a JSON representation of that node.

This simple mode of operation creates JSON arrays when there is more than one XML element with a particuar tag, and JSON objects otherwise.
This can have the effect that different XML fragments, that conform to the same schema result in JSON strings with different structures, if the multiplicity of sub-elements varies.

The xsl function `stroom:json` can be called with an optional second argument of type `xs:string`. 
This is a space or comma delimited list identifying elements that should always be contained within a JSON array, even when the multiplicity is 1.  
Each item within the list should take the form `ParentTag/Tag` or `*/Tag` where `ParentTag` is the name of the parent of the tag that should be contained within an array, and `*` denotes that elements with this name should always be contained within an array.

It is possible to create a standard for each XML schema that may be converted by this function and `<xsl:include>` the XSLT that defines this variable in all XSLTs that call `stroom:json`.  This approach avoids duplicating the multiple value tag list and creating a maintenance issue.

Use of this more complex form of `stroom:json` can create more consistent JSON representations of XML, making downstream parsing easier.

This XSLT requires XSLT 3.0.

## Reference Data

<!--TODO-->

## Search Extraction

### Compatibility

This version of the pipeline is not compatible with any versions of Stroom up to and including `v7.0.x` as these do not support Rules From Dashboards
alerting functionality.  It is important that you do not import it into incompatible versions of Stroom.

### Description

A _Search Extraction_ pipeline is used in a Dashboard query that uses an Index. If the fields used in the Dashboard Table 
are not present in the Index then the whole event XML record will need to be retrieved from the Stream Store.  
To display the data in the XML event it must first be converted into a form suitable for use by the Table,
given that XML can be highly hierarchical while the Table is a very flat structure.

### Basic/Interactive Use

It is typical to inherit from this pipeline in order to form hierarchical XML event data into a form suitable for display within
a table on a dashboard.

Pipelines inheriting from this will require an XSLT to translate from the event-logging format into XML conforming to the [records XML Schema](./core-xml-schemas.md#records).

### Alerting Use

Stroom versions `7.1.x` and later provide Rules from Dashboard functionality.
Whilst evaluating and generating alerts, Stroom runs the Search Extraction pipeline associated with the 
dashboard.
 
Alerts are initially created as `<records>` XML format.  These are transformed into `<Detections>` XML by an XSLT filter
step within this pipeline.  The XSLT used is also provided within this content pack:  [`Alert To Detection`](#alert-to-detection)

## Standard Raw Extraction

A template for search extraction pipelines that utilise the `XPathOutputFilter` to allow extraction of arbitrary data from the XML input without using a specific XSLT for record/field creation.

This template is designed to support a forthcoming release of Stroom that includes `XPathOutputFilter`.  Currently released versions of Stroom lack this feature and will
produce an error if pipelines that are based on this template are used.  

## Statistic

A template for pipelines that will generate statistic events for submission to a _Statistic Store_.  A pipeline inheriting from this will require an XSLT translation to covert from the event-logging format into XML conforming to the [statistics XML Schema](./core-xml-schemas.md#statistics). 

This translation controls the level of abstraction between the statistic(s) and the source event, e.g. only some events may generate a statistic, or a single event-logging event could spawn many statistic events.


