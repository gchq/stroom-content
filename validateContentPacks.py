#!/usr/bin/env python3
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
import configparser
import logging

logging.basicConfig(level=logging.INFO)
# logging.basicConfig(level=logging.DEBUG)

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

class DocRef:
    def __init__(self, entity_type, uuid, name):
        self.entity_type = entity_type
        self.uuid = uuid
        self.name = name


class Node:
    def __init__(self, path, entity_type, uuid, name):
        self.path = path
        self.doc_ref = DocRef(entity_type, uuid, name)


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

# def extract_doc_ref_from_xml(entity_file):
    # if not os.path.isfile(entity_file):
        # print("ERROR - Entity file {} does not exist".format(entity_file))
        # exit(1)

    # xml_root = ET.parse(entity_file).getroot()
    # uuidElm = xml_root.find('uuid')

    # if uuidElm == None:
        # uuid = None
    # else:
        # uuid = uuidElm.text
    # return uuid
    
def extract_doc_ref_from_xml(entity_file):
    if not os.path.isfile(entity_file):
        print("ERROR - Entity file {} does not exist".format(entity_file))
        exit(1)

    # print("Extracting uuid for {}".format(entity_file))
    xml_root = ET.parse(entity_file).getroot()
    entity_type = xml_root.tag
    uuidElm = xml_root.find('uuid')
    nameElm = xml_root.find('name')

    uuid = uuidElm.text if uuidElm != None else None
    name = nameElm.text if nameElm != None else None

    return DocRef(entity_type, uuid, name)

# def extract_entity_type_from_xml(entity_file):
    # if not os.path.isfile(entity_file):
        # print("ERROR - Entity file {} does not exist".format(entity_file))
        # exit(1)

    # # print("Extracting uuid for {}".format(entity_file))
    # xml_root = ET.parse(entity_file).getroot()
    # entity_type = xml_root.tag

    # return entity_type

def parse_node_file(node_file):
    if not os.path.isfile(node_file):
        print("ERROR - Node file {} does not exist".format(node_file))
        exit(1)

    dummy_section_name = 'dummy_section'

    # ConfigParser is meant to deal with .ini files so adding dummy_section
    # is a bit of a hack to work with section-less config files that look
    # like .ini files.
    with open(node_file, 'r') as f:
        config_string = '[' + dummy_section_name + ']\n' + f.read()

    config = configparser.ConfigParser()
    config.read_string(config_string)
    return config[dummy_section_name]

def extract_doc_ref_from_node_file(node_file):
    node_config = parse_node_file(node_file)
    uuid = node_config.get('uuid')
    entity_type = node_config.get('type')
    name = node_config.get('name')

    doc_ref = DocRef(entity_type, uuid, name)

    return doc_ref

def extract_uuid_from_node_config(node_config):
    uuid = node_config.get('uuid')
    if uuid == None:
        print("ERROR - Node file {} does not contain a 'uuid' tag".format(entity_file))
        exit(1)

    return uuid

def extract_entity_type_from_node_config(node_config):
    entity_type = node_config.get('type')
    if entity_type == None:
        print("ERROR - Node file {} does not contain a 'type' tag".format(entity_file))
        exit(1)

    return entity_type

def validate_pre_stroom_six_folder_uuids(pack, stroom_content_path, path_to_uuid_dict):
    #make sure we don't have multiple folder entities with
    #different uuids else this may cause odd behaviour on import
    for root, dirnames, filenames in os.walk(stroom_content_path):
        # folder_entities = fnmatch.filter(filenames, '*' + FOLDER_ENTITY_SUFFIX) 
        # logging.debug("folder entities: {}".format(folder_entities))
        # for filename in folder_entities:
        for dirname in dirnames:
            # logging.debug("dirname: {}".format(dirname))
            full_filename = os.path.join(root, dirname, '..', dirname + FOLDER_ENTITY_SUFFIX)
            # logging.debug("full_filename: {}".format(full_filename))
            entity_path = os.path.relpath(os.path.join(root, dirname), stroom_content_path)
            # logging.debug("entity_path: {}".format(entity_path))
            doc_ref = extract_doc_ref_from_xml(full_filename)
            uuid = doc_ref.uuid
            if uuid == None:
                print("ERROR - Entity file {} does not have a UUID".format(full_filename))
                exit(1)
            # logging.debug("uuid = {}".format(uuid))

            if not entity_path in path_to_uuid_dict:
                path_to_uuid_dict[entity_path] = uuid
            elif path_to_uuid_dict[entity_path] != uuid:
                print("ERROR - Multiple uuids exist for path {}".format(entity_path))
                exit(1)

def is_pack_stroom_six_or_greater(pack_dir):
    # Determine if this pack is in v6+ format or not by the presence
    # of any .node files
    is_stroom_six_or_above = False
    for root, dirnames, filenames in os.walk(pack_dir):
        if not is_stroom_six_or_above:
            for filename in filenames:
                if not is_stroom_six_or_above and filename.endswith('.node'):
                    is_stroom_six_or_above = True
                    break

    return is_stroom_six_or_above

def check_if_uuid_already_used(doc_ref, uuid_to_doc_ref_dict, full_filename):
    if doc_ref.uuid in uuid_to_doc_ref_dict:
        existing_doc_ref = uuid_to_doc_ref_dict.get(doc_ref.uuid)
        print("ERROR - Entity {} with type {} has a duplicate UUID {}. Duplicate of entity {} with type {}".format(
            full_filename, 
            doc_ref.entity_type, 
            doc_ref.uuid, 
            existing_doc_ref.name, 
            existing_doc_ref.entity_type))
        exit(1)
    else:
        # Add our unique uuid/doc_ref to the dict
        uuid_to_doc_ref_dict[doc_ref.uuid] = doc_ref
        # uuids.append(uuid)


def extract_entity_uuids_from_xml(pack_dir, uuid_to_doc_ref_dict):
    for root, dirnames, filenames in os.walk(pack_dir):
        for xml_file in fnmatch.filter(filenames, '*.xml'):
            if not xml_file.endswith(".data.xml"):
                full_filename = os.path.join(root, xml_file)
                doc_ref = extract_doc_ref_from_xml(full_filename)
                # uuid = doc_ref.uuid
                if doc_ref.uuid != None:
                    # this is a stroom entity
                    if doc_ref.entity_type != FOLDER_ENTITY_TYPE:
                        check_if_uuid_already_used(
                                doc_ref, 
                                uuid_to_doc_ref_dict, 
                                full_filename)
                        # if uuid in uuid_to_doc_ref_dict:
                            # existing_doc_ref = uuid_to_doc_ref_dict.get(uuid)
                            # print("ERROR - Entity {} with type {} has a duplicate UUID {}. Duplicate of entity {} with type {}".format(
                                # full_filename, 
                                # doc_ref.entity_type, 
                                # doc_ref.uuid, 
                                # existing_doc_ref.name, 
                                # existing_doc_ref.entity_type))
                            # exit(1)
                        # else:
                            # # Add our unique uuid/doc_ref to the dict
                            # uuid_to_doc_ref_dict[uuid] = doc_ref
                            # # uuids.append(uuid)

def extract_entity_uuids_from_node_files(pack_dir, uuid_to_doc_ref_dict):
    for root, dirnames, filenames in os.walk(pack_dir):
        for node_file in fnmatch.filter(filenames, '*.node'):
            logging.debug("node_file: {}".format(node_file))
            full_filename = os.path.join(root, node_file)
            logging.debug("full_filename: {}".format(full_filename))
            # node_config = parse_node_file(full_filename)
            # entity_type = extract_entity_type_from_node_config(node_config)
            # uuid = extract_uuid_from_node_config
            doc_ref = extract_doc_ref_from_node_file(full_filename)
            # uuid = doc_ref.uuid
            check_if_uuid_already_used(
                    doc_ref, 
                    uuid_to_doc_ref_dict, 
                    full_filename)
            # if uuid in uuid_to_doc_ref_dict:
                # existing_doc_ref = uuid_to_doc_ref_dict.get(uuid)
                # print("ERROR - Entity {} with type {} has a duplicate UUID {}. Duplicate of entity {} with type {}".format(
                    # full_filename, 
                    # doc_ref.entity_type, 
                    # doc_ref.uuid, 
                    # existing_doc_ref.name, 
                    # existing_doc_ref.entity_type))
                # exit(1)
            # else:
                # # Add our unique uuid/doc_ref to the dict
                # uuid_to_doc_ref_dict[uuid] = doc_ref
                # # uuids.append(uuid)


def validate_packs(pack_list, root_path):

    # logging.debug("Validating packs: {}".format(pack_list))
    
    # A dict of path=>uuid mappings to establish if we have multiple folder
    # paths with the same uuid (pre stroom6 only)
    path_to_uuid_dict = dict()
    # A dict of uuid=>docref
    uuid_to_doc_ref_dict = dict()
    # An array of all entity uuids to be used for ensuring all entity
    # uuids are unique
    for pack in pack_list:
        pack_path = os.path.join(root_path, pack)

        #check the folder exists for the pack name
        if not os.path.isdir(pack_path):
            print("ERROR - Pack {} does not exist in {}".format(pack, root_path))
            exit(1)

        stroom_content_path = os.path.join(pack_path, STROOM_CONTENT_DIR_NAME)

        # Determine if this pack is in v6+ format or not by the presence
        # of any .node files
        is_stroom_six_or_above = is_pack_stroom_six_or_greater(stroom_content_path)
                
        if is_stroom_six_or_above:
            print("Pack {} looks like a post-v6 project".format(pack))
        else:
            print("Pack {} looks like a pre-v6 project, so we will try and validate folder uuids".format(pack))
            validate_pre_stroom_six_folder_uuids(
                    pack, 
                    stroom_content_path, 
                    path_to_uuid_dict)

        #Loop through all the xml files finding those that have a uuid element
        #for each one that isn't a folder entity make sure the uuid
        #is not already used by another entity
        if is_stroom_six_or_above:
            extract_entity_uuids_from_node_files(
                    stroom_content_path,
                    uuid_to_doc_ref_dict)
        else:
            extract_entity_uuids_from_xml(
                    stroom_content_path, 
                    uuid_to_doc_ref_dict)

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
