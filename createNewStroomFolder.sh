#!/bin/bash

if [ ! "$#" -eq 1 ]; then
    echo "Usage: $0 folderName" >&2
    echo "E.g: $0 \"My new folder\"" >&2
    exit 1
fi

folderName="$1"

echo "Creating folder ${folderName} and its associated XML file in this directory..."

mkdir "${folderName}"
cat >"${folderName}.Folder.xml" <<EOL
<?xml version="1.1" encoding="UTF-8"?>
<folder>
   <name>${folderName}</name>
   <uuid>$(uuidgen)</uuid>
</folder>
EOL
