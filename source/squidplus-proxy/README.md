# _squidplus-proxy_ Content Pack

## Summary

The _squidplus-proxy_ Content Pack provides both client artefacts that acquire then post Squid access logs to a Stroom instance and Stroom content
artefacts that will normalise the Squid access logs into the Stroom [`event-logging-schema`](https://github.com/gchq/event-logging-schema) format.

This package does not use the standard Squid access log format, but a bespoke format called _squidplus_. This format records additional information such
as port numbers, complete request and response headers, additional status information, data transfer sizes and next hop host information.

Client deployment information can be found in the supplied [README](clientArtefacts/README.md) file.


## Stroom Contents

The following represents the folder structure and content that will be imported in to Stroom with this content pack.

* _Event Sources/Proxy/Squid-Plus-XML_
    * **Squid-Plus-XML-V1.0-EVENTS** `Feed`

        The feed used to store and process Squid Proxy events using the enriched SquidPlus Proxy XML format

    * **Squid-Plus-XML-V1.0-EVENTS** `Xslt`

        The xslt translation to convert the SquidPlus Proxy XML format into <Event> type XML.

    * **Squid-Plus-XML-V1.0-EVENTS** `Pipeline`

        The pipeline to process SquidPlus Proxy XML format into <Event> type XML.

### Dependancies

| Content pack | Version | Notes |
|:------------ |:------- |:----- |
| [`template-pipelines` Content Pack](../template-pipelines/README.md) | [v1.0](https://github.com/gchq/stroom-content/releases/tag/template-pipelines-v1.0) | Content pack elment is the Event Data (XML) Pipeline |

## Client Contents

The client artefacts are

* **README.md** `Document`

    Basic documentation to configure and deploy the SquidPlus logging capability on a Linux Squid server.

* **squidplusXML.pl** `Script - Perl`

    Perl script that ingests squidplus format Squid logs, correcting for possible errant log lines (due to large reqest/response header values), resolves and adds fully qualified domain names from IP addresses and converts to a simple XML format.

* **squid_stroom_feeder.sh** `Script - Bash`

    Bash script that orchestrates the rolling over of the Squid logs, runs the **squidplusXML.pl** script then posts the resultant output to the appropriate feed within Stroom.

## Documentation Contents

There are no separate documentation artfacts.
