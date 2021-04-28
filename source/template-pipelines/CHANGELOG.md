# Change Log

All notable changes to this content pack will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

### Changed

### Removed


## [template-pipelines-v0.4]

### Added

* `Alerts To Detections` XSLT - used by `Search Extraction` pipeline to create `Detections` XML from alerts.


### Changed

* `Search Extraction` pipeline now capable of generating alerts when deployed into a version of Stroom that supports
this feature. **Warning!** This version of the pipeline is incompatible with versions of 
Stroom up to and including `v7.0`.

### Removed


## [template-pipelines-v0.3]

### Added

* `stroom:JSON` XSLT that defines utility functions and templates for JSON serialisation.
* `Standard Raw Extraction` pipeline - A template search extraction pipeline that uses XPathExtractionOutputFilter

### Changed

### Removed


## [template-pipelines-v0.2]

* Issue **gchq/stroom#918** Remove _Event Data Base_ pipeline and copy its structure into its child pipelines

## [template-pipelines-v0.1]

* Initial version.


[Unreleased]: https://github.com/gchq/stroom-content/compare/template-pipelines-v0.4...HEAD
[template-pipelines-v0.4]: https://github.com/gchq/stroom-content/compare/template-pipelines-v0.3...template-pipelines-v0.4
[template-pipelines-v0.3]: https://github.com/gchq/stroom-content/compare/template-pipelines-v0.2...template-pipelines-v0.3
[template-pipelines-v0.2]: https://github.com/gchq/stroom-content/compare/template-pipelines-v0.1...template-pipelines-v0.2
[template-pipelines-v0.1]: https://github.com/gchq/stroom-content/compare/template-pipelines-v0.1...template-pipelines-v0.1
