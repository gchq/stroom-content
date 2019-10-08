# _standard-pipelines_ Content Pack

## Contents

The following represents the folder structure and content that will be imported in to Stroom with this content pack.

* _Standard Pipelines_ 
    * [Reference Loader](#reference-loader) `Pipeline`
* _Standard Pipelines/Json_ 
    * [JSON_EXTRACTION](#JSON_EXTRACTION) `Pipeline`
    * [JSON_SEARCH_EXTRACTION](#JSON_SEARCH_EXTRACTION) `XSLT`
    * [EVENTS_TO_JSON-PIPELINE](#EVENTS_TO_JSON-PIPELINE) `Pipeline`
    * [EVENTS_TO_JSON](#EVENTS_TO_JSON) `XSLT`
    * [EVENTS_MULTIPLE-TAG-PAIRS](#EVENTS_MULTIPLE-TAG-PAIRS) `XSLT`

## Reference Loader 

This pipeline is used for injecting reference data conforming to the [reference-data XML Schema](./core-xml-schemas.md#reference-data) into another pipeline.

## JSON_EXTRACTION

A search extraction pipeline that writes a JSON representation of the entire event into `data[@name='Json']/@value`

This pipeline is useful for API access to JSON representations of events.

## JSON_SEARCH_EXTRACTION

The XSLT used by the `Json Extraction` Pipeline.

Requires `Json` XSLT from `Template Pipelines` content pack, and uses [EVENTS_MULTIPLE-TAG-PAIRS](#EVENTS_MULTIPLE-TAG-PAIRS) 

## EVENTS_TO_JSON-PIPELINE

A pipeline that converts `Event` streams into JSON text.

This might be useful as the basis for a pipeline used within some kind of export process.

## EVENTS_TO_JSON

The XSLT used by the `Events To Json` Pipeline.

Requires `Json` XSLT from `Template Pipelines` content pack and uses [EVENTS_MULTIPLE-TAG-PAIRS](#EVENTS_MULTIPLE-TAG-PAIRS)

## EVENTS_MULTIPLE-TAG-PAIRS

XSLT that defines a single variable `$multipleValueTagPairs` that is in the correct form to be used with the `json` 
function defined within the `Json` XSLT from `Template Pipelines` content pack.

The value of this XSLT variable is set to a value that is likely to be appropriate for many purposese where Events
in `event-logging` schema format are to be serialised as JSON.  However, the main purpose of this XSLT as with all the
content within this content pack, is to demonstrate a standard approach.   
