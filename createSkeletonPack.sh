#!/bin/bash
if [ "$#" -eq 0 ] || ! [ -f "$1" ]; then
    echo "Usage: $0 new-content-pack-name" >&2
    echo "E.g: $0 my-new-content-pack" >&2
    echo "Existing content packs" >&2
    ls -1 -d ./compose/*.yml
    exit 1
fi
