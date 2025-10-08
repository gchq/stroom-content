# Change Log

All notable changes to this content pack will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

This changelog largely mirrors the changes in [event-logging-schema CHANGELOG](https://github.com/gchq/event-logging-schema/blob/master/CHANGELOG.md)

## [Unreleased]


## [event-logging-xml-schemas-v5.0]

* Upgrade to v7.0.x content pack format.

* Rename the pack from `event-logging-schema` to  `event-logging-schemas`.


## [event-logging-xml-schema-v4.1.0]

* Issue **gchq/event-logging-schema#86** : Change PermittedOrganisation to be unbounded within PermittedOrganisations.

* Issue **gchq/event-logging-schema#85** : Add In enumeration to TermConditionSimpleType to support the SQL IN condition.

* Issue **gchq/event-logging-schema#84** : Change Hash in BaseFileComplexType to be unbounded to allow multiple hashes for a file to be recorded.

* Issue **gchq/event-logging-schema#80** : Change Location.Floor from xs:integer to xs:string to allow for floors with names, e.g. Ground.

* Issue **gchq/event-logging-schema#75** : Add Changes element to Update to allow recording of a change where the before/after state is not known or is too large to record, e.g. adding a user to an long allow-list.

* Issue **gchq/event-logging-schema#62** : Add the Id attribute to AnyContentComplextType, e.g. Meta/@Id. This is to distinguish between multiple sibling Meta elements.

* Issue **gchq/event-logging-schema#67** : Add optional Outcome to EventDetail/Unknown to allow the outcome of the event to be recorded.

* Issue **gchq/event-logging-schema#74** : Add Date to EmailComnplexType.

* Issue **gchq/event-logging-schema#69** : Add optional unbounded Data element to the following elements or complex types: AntiMalwareThreatComplexType, Door, EventTimeComplexType, LocationComplexType, NetworkOutcomeComplexType and SystemComplexType.

* Refactor element EventDetail.Unknown into UnknownComplexType. Doesn't impact validity of XML documents.

* Issue **gchq/event-logging-schema#76** : Add Data element to Permission to allow for non-enumerated permission types. Add Create, Delete and Use to PermissionAttributeSimpleType.


## [event-logging-xml-schema-v4.0.0]

* Issue #68 : Add <SecutiryDomain> to <System>.

* Add <SharingData> element to <Events> and <Event>.

* Issue **gchq/event-logging-schema#58** : Remove `Event/Id`, add `EventSource/EventId` and `EventSource/SessionId`. Improve annotations for `EventChain` and `Activity`.

* Issue **gchq/event-logging-schema#57** : Refactor the schema to improve the xjc generated java code. Remove deprecated elements.

    * Extract new complex type `AuthenticateComplexType` from `Authenticate` element.

    * Extract new complex type `AuthoriseComplexType` from `Authorise` element.

    * Extract new complex type `CopyComplexType` from `CopyMoveComplexType`.

    * Extract new complex type `MoveComplexType` from `CopyMoveComplexType`.

    * Remove complex type `CopyMoveComplexType`.

    * Extract new complex type `CreateComplexType` from `Create` element.

    * Extract new complex type `ViewComplexType` from `View` element.

    * Extract new complex type `DeleteComplexType` from `Delete` element.

    * Extract new complex type `ProcessComplexType` from `Process` element.

    * Extract new complex type `PrintComplexType` from `Print` element.

    * Extract `InstallationGroup` from `InstallComplexType`.

    * Refactor `InstallComplexType` to use `InstallationGroup`.

    * Extract `UninstallComplexType` from `Uninstall` element.

    * Extract new complex type `NetworkEventActionComplexType` from `Network` element.

    * Remove deprecated `AntiMalware` element.

    * Extract new complex type `AlertComplexType` from `Alert` element.

    * Extract `SendReceiveGroup` from `SendReceiveComplexType`.

    * Extract `SendComplexType` from `Send` element.

    * Extract `ReceiveComplexType` from `Receive` element.

    * Extract `MetaDataTagsComplexType` from `Tags` element.

    * Remove `AntiMalwareComplexType`.

    * Merge `BaseAntiMalwareComplexType` into `AntiMalwareThreatComplexType`.

    * Remove `BaseAdvancedQueryItemComplexType`.

    * Extract `BaseMultiObjectGroup` from `BaseMultiObjectComplexType`.

    * Rename `NetworkSrcDstComplexType` to `NetworkLocationComplexType`.

    * Rename `NetworkSrcDstTransportProtocolSimpleType` to `NetworkProtocolSimpleType`.

    * Remove deprecated `SearchResult` and `SearchResultComplexType`.

    * Remove deprecated `EventDetail/Classification`.

    * Add additional `annotation/documentation` elements.

    * Remove unused `FromComplexType`.

    * Add `Keyboard`,`Mouse` and `Webcam` to `HardwareTypeSimpleType`.

    * Add `MemoryCard` to `MediaTypeSimpleType`.

    * Remove deprecated `LocationComplexType/TimeZone`.


## [event-logging-xml-schema-v3.4.2]

* Issue **gchq/event-logging-schema#54** : Rename NetworkComplexType to NetworkOutcomeComplexType. Add new NetworkComplexType that just extends BaseNetworkComplexType.

* Add example XML for Network/Close and Alert/Network.


## [event-logging-xml-schema-v3.4.1] - 2019-04-05

* Change all `Base....` complex types to be `abstract="true"`


## [event-logging-xml-schema-v3.4.0] - 2019-04-05

* No changes to the schema.

* Add additional junit test for regex escaping.


## [event-logging-xml-schema-v3.4-beta.1] - 2019-02-04

* Move complete examples into individual files that are validated as part of the build.

* Issue **gchq/event-logging-schema#10** : Add `SearchResults` to `BaseMultiObjectComplexType` to allow for use cases like `View/SearchResults`. 

* Issue **gchq/event-logging-schema#10** : Add `Id`, `Name` and `Description` to `QueryComplexType` to allow the linking of query to results.

* Issue **gchq/event-logging-schema#39** : Add `TimeZoneName` element to `LocationComplexType` to improve the recording of time zone information.

* Issue **gchq/event-logging-schema#44** : Add `Approval` schema action.

* Issue **gchq/event-logging-schema#47** : Add `CachedInteractive`, `CachedRemoteInteractive`, `Proxy` and `Other` logon types to `AuthenticateLogonTypeSimpleType`.

* Issue **40**: Add `State`, `City` and `Town` elements to provide more Location detail.

* Improve documentation

* Issue **gchq/event-logging-schema#49** : Fix broken link to _Illustrative Examples_ in root README.

* Issue **gchq/event-logging-schema#3** : Add `Type` attribute to `Hash` element in `BaseFileComplexType`.

* Issue **gchq/event-logging-schema#35** : Add `Meta` element to `Event` and `BaseObjectGroup` to allow extension/decoration.

* Issue **gchq/event-logging-schema#31** : Add `Tags` element to `BaseObjectGroup`.

* Issue **gchq/event-logging-schema#37** : Add `Tags` element to `SystemComplexType`.


## [event-logging-xml-schema-v3.3.1] - 2019-01-23

* No changes to the schema.

### Changed

* Change the schema generator to appy the version of the generated schema to the id attribute and the filename.


## [event-logging-xml-schema-v3.3.0] - 2019-01-14

### Added

* Issue **gchq/event-logging-schema#33** : Add content to ClassificationComplexType to support richer protective marking schemes

### Changed

* Change `name` to `pipelineName` in Schema Generator `configuration.yml`.

* Change `suffix` to `outputSuffix` in Schema Generator `configuration.yml`.

* Add `outputBaseName` to Schema Generator `configuration.yml` to allow the filename and if of the output schema to be changed.


## [event-logging-xml-schema-v3.2.4] - 2018-02-13

### Changed

* Add the pipeline suffix to the end of `id` attribute value on the `schema` element. This provides a means of differentiating the different forms of the schema.



## [event-logging-xml-schema-v3.2.3]

### Added

* Schema changes

    * Issue **gchq/event-logging-schema#23** : Added optional Coordinates element to LocationComplexType to capture lat/long

## [event-logging-xml-schema-v3.1.1]

### Changed

* Schema changes

    * Issue **gchq/event-logging-schema#18** : Remove `pattern` from `VersionSimpleType` as this is trumped by the enumerations. Add past versions as enumerations.

### Removed

* Remove schema v3.1.0 as this is broken due to a missing version enumeration

## [event-logging-xml-schema-v3.1.0]

### Added

* Schema changes

    * Issue **gchq/event-logging-schema#16** : Add _Data_ element to _PrintSettings_ element

    * Issue **gchq/event-logging-schema#13** : Add _Group_ to the list of items an _Authenticate_ action can occur on

    * Issue **gchq/event-logging-schema#12** : Add _ElevatePrivilege_ and _Other_ to list of _Authenticate_ Actions

    * Issue **gchq/event-logging-schema#6** : Add _PauseJob_, _ResumeJob_, _FailedPrint_ and _Other_ to _PrintActionSimpleType_

    * Issue **gchq/event-logging-schema#4** : Extend _ObjectOutcomeComplexType_ to have _Data_ sub elements

### Changed

* Schema changes

    * Issue **gchq/event-logging-schema#5** : Change certain instances of _xs:positiveInteger_ to _xs:nonNegativeInteger_ to allow zero values

* Refactor content pack directory structure

### Removed

## [event-logging-xml-schema-v1.0]

* Inital version.


[Unreleased]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v5.0...HEAD
[event-logging-xml-schema-v3.0]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v4.1.0...event-logging-xml-schema-v3.0
[event-logging-xml-schema-v4.1.0]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v4.0.0...event-logging-xml-schema-v4.1.0
[event-logging-xml-schema-v4.0.0]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.4.2...event-logging-xml-schema-v4.0.0
[event-logging-xml-schema-v3.4.2]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.4.1...event-logging-xml-schema-v3.4.2
[event-logging-xml-schema-v3.4.1]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.4.0...event-logging-xml-schema-v3.4.1
[event-logging-xml-schema-v3.4.0]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.4-beta.1...event-logging-xml-schema-v3.4.0
[event-logging-xml-schema-v3.4-beta.1]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.3.1...event-logging-xml-schema-v3.4-beta.1
[event-logging-xml-schema-v3.3.1]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.3.0...event-logging-xml-schema-v3.3.1
[event-logging-xml-schema-v3.3.0]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.2.4...event-logging-xml-schema-v3.3.0
[event-logging-xml-schema-v3.2.4]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.2.3...event-logging-xml-schema-v3.2.4
[event-logging-xml-schema-v3.2.3]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.1.1...event-logging-xml-schema-v3.2.3
[event-logging-xml-schema-v3.1.1]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.1.0...event-logging-xml-schema-v3.1.1
[event-logging-xml-schema-v3.1.0]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v1.0...event-logging-xml-schema-v3.1.0
[event-logging-xml-schema-v1.0]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v1.0...event-logging-xml-schema-v1.0

