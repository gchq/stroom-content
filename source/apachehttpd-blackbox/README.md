# _apachehttpd-blackbox_ Content Pack

## Summary

The _apachehttpd-blackbox_ Content Pack provides both client artefacts that acquire then post Apache Httpd access logs to a Stroom instance and Stroom
content artefacts that will normalise the Apache Httpd access logs into the Stroom [`event-logging-schema`](https://github.com/gchq/event-logging-schema) format.

This package does not use the standard Apache Httpd access log format (_combined_), but a bespoke format called _blackbox_. This format records
additional information such as port numbers, additional status information, data transfer sizes, queries and server names.

Client deployment information can be found in the supplied [README](clientArtefacts/README.md) file.

## Stroom Contents

The following represents the folder structure and content that will be imported in to Stroom with this content pack.

* _Event Sources/WebServer/ApacheHttpd_
    * **ApacheHttpd-BlackBox-V1.0-EVENTS** `Feed`

        The feed used to store and process Apache Httpd events using the enriched BlackBox format

    * **ApacheHttpd-BlackBox-V1.0-EVENTS** `Text Converter`

        The Stroom Text Converter to convert the BlackBox format into simple Stroom Name Value pair _Records_ XML format

    * **ApacheHttpd-BlackBox-V1.0-EVENTS** `Xslt`

        The xslt translation to convert the BlackBox simple Stroom Name Value pair _Records_ XML format into <Event> type XML.

    * **ApacheHttpd-BlackBox-V1.0-EVENTS** `Pipeline`

        The pipeline to process Apache Httpd events using the enriched BlackBox format into <Event> type XML.

### Dependencies

| Content pack | Version | Notes |
|:------------ |:------- |:----- |
| [`template-pipelines` Content Pack](../template-pipelines/README.md) | [v1.0](https://github.com/gchq/stroom-content/releases/tag/template-pipelines-v1.0) | Content pack element is the Event Data (XML) Pipeline |

## Client Contents

The client artefacts are

* **README.md** `Document`

    Basic documentation to configure and deploy the Apache Httpd logging capability on a Linux Apache Httpd server.

* **httpd_stroom_feeder.sh** `Script - Bash`

    Bash script that orchestrates the collection of the Apache Httpd logs, enriching then posting them to the appropriate feed within Stroom.

## Documentation Contents

There are no separate documentation artefacts.
