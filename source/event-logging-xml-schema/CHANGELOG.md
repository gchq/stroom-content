# Change Log

All notable changes to this content pack will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

### Changed

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


[Unreleased]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v3.1.0...HEAD
[event-logging-xml-schema-v3.1.0]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v1.0...event-logging-xml-schema-v3.1.0
[event-logging-xml-schema-v1.0]: https://github.com/gchq/stroom-content/compare/event-logging-xml-schema-v1.0...event-logging-xml-schema-v1.0

