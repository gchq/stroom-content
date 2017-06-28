#!/bin/bash

#Creates the skeleton directory structure for a new content pack including creating
#root README and CHANGELOG files

SOURCE_DIR=./source

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 new-content-pack-name" >&2
    echo "E.g: $0 my-new-content-pack" >&2
    echo "Existing content packs" >&2
    ls -1 -d ./source/* | sed 's#\./source/#  #'
    exit 1
fi

contentPackName=$1

if [ -e "${SOURCE_DIR}/${contentPackName}" ]; then

    echo "Content pack [${contentPackName}] already exists, exiting!" >&2
    exit 1
fi

contentPackDir="${SOURCE_DIR}/${contentPackName}"
docsDir="$contentPackDir/docs"
clientDir="$contentPackDir/clientArtefacts"
stroomContentDir="$contentPackDir/stroomContent"
changeLogFile="${contentPackDir}/CHANGELOG.md"
rootReadmeFile="${contentPackDir}/README.md"

makeDir() {
    [ "$#" -eq 0 ] && echo "Expecting dir as an arg" && exit 1
    dir=$1
    echo "Creating directory $dir"
    mkdir $dir
    touch $dir/.gitkeep
}

echo "Creating content pack $contentPackName..."
echo ""

makeDir "$contentPackDir"
makeDir "$docsDir"
makeDir "$clientDir"
makeDir "$stroomContentDir"

echo "Creating README file $rootReadmeFile"
cat >$rootReadmeFile <<EOL
# _${contentPackName}_ Content Pack
EOL

echo "Creating CHANGELOG file $changeLogFile"
cat >$changeLogFile <<EOL
# Change Log

All notable changes to this content pack will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

### Changed

### Removed
EOL

echo ""
echo "TIP: Use the linux binary 'uuidgen' to generatethe UUIDs required in the content pack's XML files."
echo ""
echo "TIP: Run the script createNewStroomFolder.sh from any directory to create a new Stroom Folder in that directory."
echo ""
echo "Done"
