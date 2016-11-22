# _template-pipelines_ Content Pack

## Contents

The following represents the folder structure and content that will be imported in to Stroom with this content pack.

* _Template Pipelines_ 
    * _Fragments_
        * [Event Data Base](#event-data-base) `Pipeline`
    * [Batch Search](#batch-search) `Pipeline`
    * [Context Data](#context-data) `Pipeline`
    * [Event Data (JSON)](#event-data-json) `Pipeline`
    * [Event Data (Text)](#event-data-text) `Pipeline`
    * [Event Data (XML)](#event-data-xml) `Pipeline`
    * [Indexing](#indexing) `Pipeline`
    * [Reference Data](#reference-data) `Pipeline`
    * [Search Extraction](#search-extraction) `Pipeline`
    * [Statistic](#statistic) `Pipeline`

## Event Data Base

This is a fragment of a pipeline that is inherited from by the Event Data (....) pipelines. This pipeline fragment expects XML data (of any structure) which will be translated into event-logging format, then validated against the event-logging XML Schema before being written to the stream store.

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

## Reference Data

<!--TODO-->

## Search Extraction

A _Search Extraction_ pipeline is used in a Dashboard query that uses an Index. If the fields used in the Dashboard Table are not present in the Index then the whole event XML record will need to be retrieved from the Stream Store.  To display the data in the XML event it must first be converted into a form suitable for use by the Table, given that XML can be highly hierarchical while the Table is a very flat structure.

Pipelines inheriting from this will require an XSLT to translate from the event-logging format into XML conforming to the [records XML Schema](./core-xml-schemas.md#records).

## Statistic

A template for pipelines that will generate statistic events for submission to a _Statistic Store_.  A pipeline inheriting from this will require an XSLT translation to covert from the event-logging format into XML conforming to the [statistics XML Schema](./core-xml-schemas.md#statistics). 

This translation controls the level of abstraction between the statistic(s) and the source event, e.g. only some events may generate a statistic, or a single event-logging event could spawn many statistic events.


