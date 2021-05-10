# _stroom-logs_ Content Pack

This content pack contains feeds for receiving the logs from within the Stroom family of applications.

## _Feeds_ 
* [STROOM-ACCESS-EVENTS](#STROOM-ACCESS-EVENTS) `Feed`
* [STROOM-APP-EVENTS](#STROOM-APP-EVENTS) `Feed`
* [STROOM-USER-EVENTS](#STROOM-USER-EVENTS) `Feed`
* [STROOM_NGINX-ACCESS-EVENTS](#STROOM_NGINX-ACCESS-EVENTS) `Feed`
* [STROOM_NGINX-APP-EVENTS](#STROOM_NGINX-APP-EVENTS) `Feed`
* [STROOM_PROXY-ACCESS-EVENTS](#STROOM_PROXY-ACCESS-EVENTS) `Feed`
* [STROOM_PROXY-APP-EVENTS](#STROOM_PROXY-APP-EVENTS) `Feed`
* [STROOM_PROXY-SEND-EVENTS](#STROOM_PROXY-SEND-EVENTS) `Feed`
* [STROOM_PROXY-RECEIVE-EVENTS](#STROOM_PROXY-RECEIVE-EVENTS) `Feed`

 ## _Pipelines_  
Pipelines with associated processor filters and translations are provided, in order to normalise the data that is
received on the provided feeds.

* System events are normalised into Stroom Family `<records>` XML.
* User events are normalised into `<Events>`, that conform to the `event-logging` XML schema.

## System Monitoring Dashboard
The `Stroom Family App Events Dashboard` is designed to provide a view of system events, that may be useful for
system monitoring of the Stroom environment.

The datasources `Stroom Family Apps Index` and `Stroom Family Apps SQL Statistic` are used by this dashboard.
These datasources and associated pipelines and procesor filters are included within this content pack.

## Further Information

#### STROOM_ACCESS-EVENTS

Web server access logs from stroom.

#### STROOM_APP-EVENTS

Application logs from stroom.

#### STROOM_USER-EVENTS

Accounting and audit events from stroom.

#### STROOM_NGINX-ACCESS-EVENTS

Web server access logs from stroom-nginx.

#### STROOM_NGINX-APP-EVENTS

Application (error) logs from stroom-nginx.

#### STROOM_PROXY-ACCESS-EVENTS

Web server access logs from stroom-proxy.

#### STROOM_PROXY-APP-EVENTS

Application logs from stroom-proxy.

#### STROOM_PROXY-SEND-EVENTS

Events generated when data is sent from stroom-proxy.

#### STROOM_PROXY-RECEIVE-EVENTS

Events generated when data is received by stroom-proxy.
