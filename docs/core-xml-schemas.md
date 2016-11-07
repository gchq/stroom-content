# _core-xml-schemas_ Content Pack

## Contents

The following represents the folder structure and content that will be imported in to Stroom with this content pack.

* _XMLSchemas_ 
    * _analytic-ouput_ 
        * [analytic-output v1.0](#analytic-output) `XMLSchema`
    * _data-splitter_ 
        * [data-splitter v3.0](#data-splitter) `XMLSchema`
    * _json_ 
        * [json](#json) `XMLSchema`
    * _records_ 
        * [records v2.0](#records) `XMLSchema`
    * _reference-data_ 
        * [reference-data v2.0.1](#reference-data) `XMLSchema`
    * _statistics_ 
        * [statistics v2.0.1](#statistics) `XMLSchema`


## analytic-output 

This XMLSchema is a data structure for data produced by an analytic of some kind. The functionality for making use of this schema is currently not included in Stroom and will be added at a later date.

## data-splitter 

This XMLSchema defines the data used to describe a _Data Splitter_ configuration, i.e the regexes and splits to convert a plain text file format into structured XML.

## json 

This schema comes from w3.org and defines the structure used to represent json data as XML.

Data output by the _JSON_ type _Parser_ pipeline element will conform to this XMLSchema. Data input to the _JsonWriter_ pipeline element must conform to this XMLSchema.

## records

Defines the structure of the data output by a _Data Splitter_ type _Parser_ pipeline element.

## reference-data

XMLSchema to provide a common structure for describing reference data. For example a reference data feed may be supplied to Stroom to map IP addresses to fully qualified domain names. This data feed would either be ingested as data conforming to this XMLSchema or converted into it.

Data input to the _ReferenceDataFilter_ pipeline element must conform to this XMLSchema.

## statistics

This structure is used to describe a statistics event record. Statistics are used to record counts (or values) of events happening, e.g. the number of a particular kind of event witin a time period, or the CPU% of a Stroom node.

Data fed to the _NewStatisticsFilter_ pipeline element must conform to this XMLSchema.
