# Stroom Content

_Stroom Content_ is a repository of the content definition files used to import entities into _Stroom_. Entities are such things as XML Schemas, XSLT translations, data splitter definitions, pipelines, dashboards, visualisations, etc. This repository provides a means to share common _Stroom_ content in a form that can be imported into multiple instances of _Stroom_.

The content is grouped into a number of _content packs_ which can each be built into a zip file that is ready for import directly into _Stroom_.

## Building the content packs

Each content pack is defined as a directory within _stroom-content-source_ with the name of content pack being the name of the directory.

The content packs can be built into the zip files by running the python script _buildContentPacks.py_. You can either build all packs or a list of named packs and you can choose to have them packaged as single combined zip or one per pack.

For example:

```bash
#build all packs into a single zip
./buildContentPacks.py --combine --all 

#build all packs, one zip per pack
./buildContentPacks.py  --all 

#build a named list of packs
./buildContentPacks.py  stroom-101 core-xml-schemas
```


## Importing the content packs

The content pack zip files can be imported into _Stroom_ by selecting _Import_ from the _Tools_ menu.
