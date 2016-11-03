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
# buildContentPacks.py
# 
# Usage: buildContentPacks.py [--combine] [--all] [packName ...]
# e.g.:  buildContentPacks.py --combine stroom-101 core-xml-schemas
#        buildContentPacks.py stroom-101 core-xml-schemas
#        buildContentPacks.py --all
#
# Script to package up the content pack source into a zip file or zip files.
#
# packName is the name of the sub-folder in stroom-content-source.
# Anything inside this folder is considered stroom content relative to 
# stroom's root folder
# --all indicates to build all pack folders found in stroom-content-source
# --combine indicates to place all content in a single zip file as 
# opposed to one for each packName
#
#**********************************************************************

import sys
import os
import re
import zipfile
import shutil
import fnmatch
import xml.etree.ElementTree as ET

USAGE_TXT = "Usage:\nbuildContentPacks.py [--combine] [--all] [packName ...]\ne.g.\nTo build all content packs - buildPacks.py [--combine] --all\nTo build specific named content packs - buildPacks.py [--combine] pack-1 pack-2 pack-n\nWhere --combine indicates all packs should be combined into a single zip file, otherwise each pack will be placed in its own zip file."
SOURCE_DIR_NAME = "stroom-content-source"
TARGET_DIR_NAME = "stroom-content-target"
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
    print USAGE_TXT
    print "\nAvailable content packs:"
    list_content_packs()
    print "\n"


def clear_dir(dir_path):
    print "Clearing contents of %s" % (dir_path)
    for the_file in os.listdir(dir_path):
        file_path = os.path.join(dir_path, the_file)
        try:
            if os.path.isfile(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path): 
                shutil.rmtree(file_path)
        except Exception as e:
            print(e)


def zip_pack(root_path, pack_name, zip_handle, added_files):

    #Now add all the contents of the pack folder and any sub folders
    #Paths are relative to the pack folder
    zip_source_path = os.path.join(source_path, pack_name)
    for root, dirs, files in os.walk(zip_source_path):
        for file in files:
            abs_path = os.path.join(root, file)
            rel_path = os.path.relpath(abs_path, zip_source_path)
            if not rel_path in added_files:
                added_files.append(rel_path)
                print "  %s" % (rel_path)
                zip_handle.write(abs_path, rel_path)


def build_pack(pack_name):
    dest_zip_file_name = pack_name + ".zip"
    dest_zip_file_path = os.path.join(target_path, dest_zip_file_name)
    print "Building content pack: %s into zip file %s" % (pack_name, dest_zip_file_name)

    added_files = []

    with zipfile.ZipFile(dest_zip_file_path, 'w', zipfile.ZIP_DEFLATED) as dest_zip_file:
        zip_pack(source_path, pack_name, dest_zip_file, added_files)

def extract_uuid(entity_file):
    if not os.path.isfile(entity_file):
        print "Entity file %s does not exist" % entity_file
        exit(1)

    # print "Extracting uuid for %s" % entity_file
    xml_root = ET.parse(entity_file).getroot()
    uuidElm = xml_root.find('uuid')

    if uuidElm == None:
        uuid = None
    else:
        uuid = uuidElm.text
    return uuid

def extract_entity_type(entity_file):
    if not os.path.isfile(entity_file):
        print "Entity file %s does not exist" % entity_file
        exit(1)

    # print "Extracting uuid for %s" % entity_file
    xml_root = ET.parse(entity_file).getroot()
    entity_type = xml_root.tag

    return entity_type



def validate_packs(pack_list, root_path):
    
    path_to_uuid_dict = dict()
    uuids = []
    for pack in pack_list:
        pack_path = os.path.join(root_path, pack)
        #check the folder exists for the pack name
        if not os.path.isdir(pack_path):
            print "Pack %s does not exist in %s" % (pack, root_path)
            exit(1)

        #make sure we don't have multiple folder entities with
        #different uuids else this may cause odd behaviour on import
        for root, dirnames, filenames in os.walk(pack_path):
            # folder_entities = fnmatch.filter(filenames, '*' + FOLDER_ENTITY_SUFFIX) 
            # print "folder entities: %s" % folder_entities
            # for filename in folder_entities:
            for dirname in dirnames:
                # print "dirname: %s" % dirname
                full_filename = os.path.join(root, dirname, '..', dirname + FOLDER_ENTITY_SUFFIX)
                # print "full_filename: %s" % full_filename
                entity_path = os.path.relpath(os.path.join(root, dirname), pack_path)
                # print "entity_path: %s" % entity_path
                uuid = extract_uuid(full_filename)
                if uuid == None:
                    print "Entity file %s does not have a UUID" % full_filename
                    exit(1)
                # print "uuid = %s" % uuid

                if not entity_path in path_to_uuid_dict:
                    path_to_uuid_dict[entity_path] = uuid
                elif path_to_uuid_dict[entity_path] != uuid:
                    print "Multiple uuids exist for path %" % entity_path
                    exit(1)

        #Loop through all the xml files finding those that have a uuid element
        #for each one that isn't a folder entity make sure the uuid
        #is not already used by another entity
        for root, dirnames, filenames in os.walk(pack_path):
            for xml_file in fnmatch.filter(filenames, '*.xml'):
                full_filename = os.path.join(root, xml_file)
                uuid = extract_uuid(full_filename)

                if uuid != None:
                    #this is a stroom entity
                    entity_type = extract_entity_type(full_filename)
                    if entity_type != FOLDER_ENTITY_TYPE:
                        #this is not a folder entity
                        if uuid in uuids:
                            print "Entity %s with type %s has a duplicate UUID %s" % (full_filename, entity_type, uuid)
                            exit(1)
                        else:
                            uuids.append(uuid)




# Script proper starts here
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if len(sys.argv) == 1:
    print "ERROR - No arguments supplied"
    print_usage()
    exit(1)

isAllPacks = False
arePacksCombined = False
packs_to_build = []

for arg in sys.argv[1:]:
    if arg == "--all":
        isAllPacks = True
    elif arg == "--combine":
        arePacksCombined = True
    else:
        packs_to_build.append(arg)

if len(packs_to_build) > 0 and isAllPacks:
    print "Cannot specify --all and named packs"
    print_usage()
    exit(1)

# ensure we have a target dir to put the zips in 
if not os.path.exists(target_path):
    print "Creating target directory %s" % target_path
    os.mkdir(target_path)

if isAllPacks:
    print "Building all content packs"
    for list_entry in os.listdir(source_path):
        if os.path.isdir(os.path.join(source_path, list_entry)):
            packs_to_build.append(list_entry)
else:
    print "Building the following packs:"

validate_packs(packs_to_build, source_path)

print "Using root path: ", root_path
print "Using source path: ", source_path
print "Using target path: ", target_path

clear_dir(target_path)

if arePacksCombined:
    dest_zip_file_name = "ContentPacks.zip"
    dest_zip_file_path = os.path.join(target_path, dest_zip_file_name)
    with zipfile.ZipFile(dest_zip_file_path, 'w', zipfile.ZIP_DEFLATED) as zip_handle:
        added_files = []
        for pack in packs_to_build:
            zip_pack(source_path, pack, zip_handle, added_files)
else:
    for pack in packs_to_build:
        build_pack(pack)

print "Done!"
exit(0)
