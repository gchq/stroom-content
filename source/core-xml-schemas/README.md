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
        * [statistics v4.0.0](#statistics) `XMLSchema`


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

Statistic events in _stroom_ are an abstraction of the rich event records in stroom. The idea is to condense part of an event down to a count or value with some qualifying attributes, e.g. the number of bytes in a file upload event, or reducing a rich logon event down to a count of 1 with qualifying attributes for the user and device. These statistic events can then be aggregated in a number of different time buckets for fast querying. 

Statistics data can be recorded in two ways in _stroomn_, either using the internal SQL based statistics store, or by sending the statistic events via _Kafka_ to _stroom-stats_. Each mechanism uses a different version of the Statistics XMLSchema. The appropriate schema version for each statistics store is as follows:

* SQL Statistics - v2.0.1

* _stroom-stats_ - v4.0.0

### SQL Statistics

This statistics store is built in to _stroom_.  The schema is used to describe a statistics event record. Statistics are used to record counts (or values) of events happening, e.g. the number of a particular kind of event within a time period, or the CPU% of a Stroom node.

Data fed to the _StatisticsFilter_ pipeline element must conform to this XMLSchema.

### _stroom-stats_ Statistics
_stroom-stats_ is external to _stroom_ and provides a more scalable and feature rich store for statistics data. The structure of a _stroom-stats_ statistic event is broadly similar to a SQL Statistics event, with the addition of some features to support recording references to the source event(s) that contributed to the Statistic event.

Data fed to the `statisticEvents-Count` and `statisticEvents-Value` Kafka topics using _stroom's_ _KafkaProducerFilter_ pipeline element must conform to this XMLSchema.
