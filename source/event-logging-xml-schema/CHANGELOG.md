# Change Log

All notable changes to this content pack will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

This changelog largely mirrors the changes in [event-logging-schema CHANGELOG](https://github.com/gchq/event-logging-schema/blob/master/CHANGELOG.md)

## [Unreleased]

### Added

### Changed

## [event-logging-xml-schema-v3.4.2]

* Issue **#54** : Rename NetworkComplexType to NetworkOutcomeComplexType. Add new NetworkComplexType that just extends BaseNetworkComplexType.

* Add example XML for Network/Close and Alert/Network.


## [event-logging-xml-schema-v3.4.1] - 2019-04-05

* Change all `Base....` complex types to be `abstract="true"`


## [event-logging-xml-schema-v3.4.0] - 2019-04-05

* No changes to the schema.

* Add additional junit test for regex escaping.


## [event-logging-xml-schema-v3.4-beta.1] - 2019-02-04

* Move complete examples into individual files that are validated as part of the build.

* Issue **#10** : Add `SearchResults` to `BaseMultiObjectComplexType` to allow for use cases like `View/SearchResults`. 

* Issue **#10** : Add `Id`, `Name` and `Description` to `QueryComplexType` to allow the linking of query to results.

* Issue **#39** : Add `TimeZoneName` element to `LocationComplexType` to improve the recording of time zone information.

* Issue **#44** : Add `Approval` schema action.

* Issue **#47** : Add `CachedInteractive`, `CachedRemoteInteractive`, `Proxy` and `Other` logon types to `AuthenticateLogonTypeSimpleType`.

* Issue **40**: Add `State`, `City` and `Town` elements to provide more Location detail.

* Improve documentation

* Issue **#49** : Fix broken link to _Illustrative Examples_ in root README.

* Issue **#3** : Add `Type` attribute to `Hash` element in `BaseFileComplexType`.

* Issue **#35** : Add `Meta` element to `Event` and `BaseObjectGroup` to allow extension/decoration.

* Issue **#31** : Add `Tags` element to `BaseObjectGroup`.

* Issue **#37** : Add `Tags` element to `SystemComplexType`.


## [event-logging-xml-schema-v3.3.1] - 2019-01-23

* No changes to the schema.

### Changed

* Change the schema generator to appy the version of the generated schema to the id attribute and the filename.


## [event-logging-xml-schema-v3.3.0] - 2019-01-14

### Added

* Issue **#33** : Add content to ClassificationComplexType to support richer protective marking schemes

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

    * Issue **#23** : Added optional Coordinates element to LocationComplexType to capture lat/long

## [event-logging-xml-schema-v3.1.1]

### Changed

* Schema changes

    * Issue **#18** : Remove `pattern` from `VersionSimpleType` as this is trumped by the enumerations. Add past versions as enumerations.

### Removed

* Remove schema v3.1.0 as this is broken due to a missing version enumeration

## [event-logging-xml-schema-v3.1.0]

### Added

* Schema changes

    * Issue **#16** : Add _Data_ element to _PrintSettings_ element

    * Issue **#13** : Add _Group_ to the list of items an _Authenticate_ action can occur on

    * Issue **#12** : Add _ElevatePrivilege_ and _Other_ to list of _Authenticate_ Actions

    * Issue **#6** : Add _PauseJob_, _ResumeJob_, _FailedPrint_ and _Other_ to _PrintActionSimpleType_

    * Issue **#4** : Extend _ObjectOutcomeComplexType_ to have _Data_ sub elements

### Changed

* Schema changes

    * Issue **#5** : Change certain instances of _xs:positiveInteger_ to _xs:nonNegativeInteger_ to allow zero values

* Refactor content pack directory structure

### Removed

## [event-logging-xml-schema-v1.0]

* Inital version.


[Unreleased]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.4.2...HEAD
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

