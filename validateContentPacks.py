#!/usr/bin/env python
#**********************************************************************
# Copyright 2016 Crown Copyright
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#**********************************************************************

#**********************************************************************
# validateContentPacks.py
# 
# Usage: validateContentPacks.py [--all] [packName ...]
# e.g.:  buildContentPacks.py stroom-101 core-xml-schemas
#        buildContentPacks.py --all
#
# Script to validate one or more content packs
#
# packName is the name of the sub-folder in stroom-content-source.
# Anything inside this folder is considered stroom content relative to 
# stroom's root folder
# --all indicates to build all pack folders found in stroom-content-source
#
#**********************************************************************

import sys
import os
import re
import zipfile
import shutil
import fnmatch
import xml.etree.ElementTree as ET
import ConfigParser


USAGE_TXT = "\
Usage:\nvalidateContentPacks.py [--all] [packName ...]\n\
e.g.\n\
To validate all content packs - buildPacks.py --all\n\
To validate specific named content packs - validateContentPacks.py pack-1 pack-2 pack-n"
SOURCE_DIR_NAME = "source"
TARGET_DIR_NAME = "target"
STROOM_CONTENT_DIR_NAME = "stroomContent"
FOLDER_ENTITY_TYPE = "folder"
FOLDER_ENTITY_SUFFIX = ".Folder.xml"

root_path = os.path.dirname(os.path.realpath(__file__))
source_path = os.path.join(root_path, SOURCE_DIR_NAME)
target_path = os.path.join(root_path, TARGET_DIR_NAME)

def list_content_packs():
    for the_file in os.listdir(source_path):
        file_path = os.path.join(source_path, the_file)
        if os.path.isdir(file_path): 
            print("  " + the_file)

def print_usage():
    print(USAGE_TXT)
    print("\nAvailable content packs:")
    list_content_packs()
    print("\n")

def extract_uuid(entity_file):
    if not os.path.isfile(entity_file):
        print("ERROR - Entity file {} does not exist".format(entity_file))
        exit(1)

    # print("Extracting uuid for {}".format(entity_file))
    xml_root = ET.parse(entity_file).getroot()
    uuidElm = xml_root.find('uuid')

    if uuidElm == None:
        uuid = None
    else:
        uuid = uuidElm.text
    return uuid

def extract_entity_type(entity_file):
    if not os.path.isfile(entity_file):
        print("ERROR - Entity file {} does not exist".format(entity_file))
        exit(1)

    # print("Extracting uuid for {}".format(entity_file))
    xml_root = ET.parse(entity_file).getroot()
    entity_type = xml_root.tag

    return entity_type

def validate_pre_stroom_six_folder_uuids(pack, stroom_content_path, path_to_uuid_dict):
    #make sure we don't have multiple folder entities with
    #different uuids else this may cause odd behaviour on import
    for root, dirnames, filenames in os.walk(stroom_content_path):
        # folder_entities = fnmatch.filter(filenames, '*' + FOLDER_ENTITY_SUFFIX) 
        # print("folder entities: {}".format(folder_entities))
        # for filename in folder_entities:
        for dirname in dirnames:
            # print("dirname: {}".format(dirname))
            full_filename = os.path.join(root, dirname, '..', dirname + FOLDER_ENTITY_SUFFIX)
            # print("full_filename: {}".format(full_filename))
            entity_path = os.path.relpath(os.path.join(root, dirname), stroom_content_path)
            # print("entity_path: {}".format(entity_path))
            uuid = extract_uuid(full_filename)
            if uuid == None:
                print("ERROR - Entity file {} does not have a UUID".format(full_filename))
                exit(1)
            # print("uuid = {}".format(uuid))

            if not entity_path in path_to_uuid_dict:
                path_to_uuid_dict[entity_path] = uuid
            elif path_to_uuid_dict[entity_path] != uuid:
                print("ERROR - Multiple uuids exist for path {}".format(entity_path))
                exit(1)

def is_pack_stroom_six_or_greater(pack_dir):
    # Determine if this pack is in v6+ format or not by the presence
    # of any .node files
    isStroomSixOrAbove = False
    for root, dirnames, filenames in os.walk(pack_dir):
        if not isStroomSixOrAbove:
            for filename in filenames:
                if not isStroomSixOrAbove and filename.endswith('.node'):
                    isStroomSixOrAbove = True
                    break

    return isStroomSixOrAbove


def validate_packs(pack_list, root_path):

    # print("Validating packs: {}".format(pack_list))
    
    path_to_uuid_dict = dict()
    uuids = []
    for pack in pack_list:
        pack_path = os.path.join(root_path, pack)

        #check the folder exists for the pack name
        if not os.path.isdir(pack_path):
            print("ERROR - Pack {} does not exist in {}".format(pack, root_path))
            exit(1)

        stroom_content_path = os.path.join(pack_path, STROOM_CONTENT_DIR_NAME)

        # Determine if this pack is in v6+ format or not by the presence
        # of any .node files
        isStroomSixOrAbove = is_pack_stroom_six_or_greater(stroom_content_path)
                
        if isStroomSixOrAbove:
            print("Pack {} looks like a post-v6 project".format(pack))
        else:
            print("Pack {} looks like a pre-v6 project, so we will try and validate folder uuids".format(pack))
            validate_pre_stroom_six_folder_uuids(
                    pack, stroom_content_path, path_to_uuid_dict)

        #Loop through all the xml files finding those that have a uuid element
        #for each one that isn't a folder entity make sure the uuid
        #is not already used by another entity
        for root, dirnames, filenames in os.walk(stroom_content_path):
            for xml_file in fnmatch.filter(filenames, '*.xml'):
                full_filename = os.path.join(root, xml_file)
                uuid = extract_uuid(full_filename)

                if uuid != None:
                    #this is a stroom entity
                    entity_type = extract_entity_type(full_filename)
                    if entity_type != FOLDER_ENTITY_TYPE:
                        #this is not a folder entity
                        if uuid in uuids:
                            print("ERROR - Entity {} with type {} has a duplicate UUID {}".format(
                                full_filename, entity_type, uuid))
                            exit(1)
                        else:
                            uuids.append(uuid)

    print("")
    print("UUIDs for paths:")
    for key in sorted(path_to_uuid_dict):
        print("{} - {}".format(key, path_to_uuid_dict[key]))

    print("")
    print("Validation completed with no errors")




# Script proper starts here
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if len(sys.argv) == 1:
    print("ERROR - No arguments supplied")
    print_usage()
    exit(1)

isAllPacks = False
packs_to_build = []

for arg in sys.argv[1:]:
    if arg == "--all":
        isAllPacks = True
    else:
        packs_to_build.append(arg)

if len(packs_to_build) > 0 and isAllPacks:
    print("ERROR - Cannot specify --all and named packs")
    print_usage()
    exit(1)

if len(packs_to_build) == 0 and not isAllPacks:
    print("ERROR - Must specify --all or provide a list of named packs")
    print_usage()
    exit(1)

if isAllPacks:
    print("Processing all content packs")
    for list_entry in os.listdir(source_path):
        if os.path.isdir(os.path.join(source_path, list_entry)):
            packs_to_build.append(list_entry)
else:
    print("Processing packs: {}".format(packs_to_build))

print("Using root path: {}".format(root_path))
print("Using source path: {}".format(source_path))

validate_packs(packs_to_build, source_path)

print("Done!")
exit(0)
