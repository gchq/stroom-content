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
# e.g.:  validateContentPacks.py stroom-101 core-xml-schemas
#        validateContentPacks.py --all
#
# Script to validate one or more content packs
#
# packName is the name of the sub-folder in stroom-content-source.
# Anything inside this folder is considered stroom content relative to 
# stroom's root folder
# --all indicates to build all pack folders found in stroom-content-source
#
#**********************************************************************

import configparser
import fnmatch
import logging
import os
import re
import shutil
import sys
import time
import xml.etree.ElementTree as ET
import zipfile

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

# Class for ascii colour codes for use in print statements
class Col:
    RED = '\033[0;31m'
    BRED = '\033[1;31m'
    GREEN = '\033[0;32m'
    BOLD_GREEN = '\033[1;32m'
    YELLOW = '\033[0;33m'
    BOLD_YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    BOLD_BLUE = '\033[1;34m'
    LIGHT_GREY = '\033[37m'
    DARK_GREY = '\033[90m'
    MAGENTA = '\033[0;35m'
    BOLD_MAGENTA = '\033[1;35m'
    CYAN = '\033[0;36m'
    BOLD_CYAN = '\033[1;36m'
    NC = '\033[0m' # No Color

    @staticmethod
    def _colourise(string, colour_code):
        return ''.join([colour_code, string, Col.NC])

    @staticmethod
    def red(string):
        return Col._colourise(string, Col.RED)
    
    @staticmethod
    def bold_red(string):
        return Col._colourise(string, Col.BRED)
    
    @staticmethod
    def green(string):
        return Col._colourise(string, Col.GREEN)
    
    @staticmethod
    def bold_green(string):
        return Col._colourise(string, Col.BOLD_GREEN)
    
    @staticmethod
    def yellow(string):
        return Col._colourise(string, Col.YELLOW)
    
    @staticmethod
    def bold_yellow(string):
        return Col._colourise(string, Col.BOLD_YELLOW)
    
    @staticmethod
    def blue(string):
        return Col._colourise(string, Col.BLUE)
    
    @staticmethod
    def bold_blue(string):
        return Col._colourise(string, Col.BOLD_BLUE)
    
    @staticmethod
    def light_grey(string):
        return Col._colourise(string, Col.LIGHT_GREY)
    
    @staticmethod
    def dark_grey(string):
        return Col._colourise(string, Col.DARK_GREY)
    
    @staticmethod
    def magenta(string):
        return Col._colourise(string, Col.MAGENTA)
    
    @staticmethod
    def bold_magenta(string):
        return Col._colourise(string, Col.BOLD_MAGENTA)
    
    @staticmethod
    def cyan(string):
        return Col._colourise(string, Col.CYAN)
    
    @staticmethod
    def bold_cyan(string):
        return Col._colourise(string, Col.BOLD_CYAN)




# Class to represent a folder in the heirarchy of folders/entities.
# A folder can contain many child folders and many child entities
class Folder:
    def __init__(self, full_path, name, parent):
        self.full_path = full_path
        self.name = name
        self.parent = parent
        # (entity_type, name) => DocRef dict
        self.entities = dict()
        # name => Folder dict
        self.child_folders = dict()

    def __str__(self):
        return "full_path: {}, name: {}".format(self.full_path, self.name)

    # Adds an entity to this folder
    def _add_entity(self, doc_ref):
        key = (doc_ref.entity_type, doc_ref.name)
        if not key in self.entities:
            self.entities[key] = doc_ref
        else:
            existing_doc_ref = self.entities[key]
            if not (existing_doc_ref.entity_type == "Folder"
                    and existing_doc_ref.uuid == doc_ref.uuid):
                print_error(("Multiple entities with the same name and type in "
                             + "folder {}, name: {}, type: {}, UUIDs: {}, {}")
                    .format(
                        Col.blue(self.full_path), 
                        Col.green(doc_ref.name), 
                        Col.cyan(doc_ref.entity_type), 
                        Col.yellow(existing_doc_ref.uuid), 
                        Col.yellow(doc_ref.uuid)))
                print("\nDisplaying tree so far")
                self.print_tree()
                exit(1)

    # Adds a child folder with passed name to the dict of child folders
    # Returns the created folder instance
    def _add_child_folder(self, name):
        if not name in self.child_folders:
            logging.debug("Creating child folder {} in folder [{}]".format(
                name, self))

            if (self.full_path == ""):
                child_full_path = name
            else:
                child_full_path = "/".join([self.full_path, name])

            child_full_path = child_full_path.replace("//", "/")

            child_folder = Folder(child_full_path, name, self)
            self.child_folders[name] = child_folder
        else:
            logging.debug("Folder {} already exists in folder [{}]".format(
                name, self))

        return self.child_folders[name]

    # Adds node to this folder, creating intermediate folders as required
    def add_node(self, node):
        logging.debug("add_node called, self [{}] to folder [{}]"
            .format(self, self))
        # time.sleep(0.5)
        if node.path == self.full_path:
            # entity belongs in this folder so just add it
            logging.debug("Adding entity [{}] to folder [{}]"
                .format(node.doc_ref, self))
            self._add_entity(node.doc_ref)
        else:
            # entity belongs further down so create the folder at this
            # level and try again

            logging.debug("node.path [{}], self.full_path [{}]"
                .format(node.path, self.full_path))
            # ensure we have no trailing slash
            relative_folder = node.path.rstrip("/")

            # if self is /A/B and node is /A/B/C/D
            # the relative path is /C/D
            relative_folder = relative_folder.replace(self.full_path, "")
            relative_folder = relative_folder.lstrip("/")

            child_folder_name = relative_folder.split("/")[0]

            logging.debug("relative_folder [{}], child_folder_name [{}]"
                    .format(relative_folder, child_folder_name))

            child_folder = self._add_child_folder(child_folder_name)

            # recursive call to continue trying to add the node
            child_folder.add_node(node)

    # Print this folder and all folders/entities below it
    def print_tree(self, level=-1):
        logging.debug("print_tree called with self [{}], level {}"
            .format(self, level))
        single_indent = "    "
        indent_str = single_indent * level

        if (self.name != None):
            print("{}+ {}".format(
                indent_str, 
                Col.bold_blue(self.name)))

        # Output all the folders (and their contents) first
        for child_folder_name, child_folder in sorted(self.child_folders.items()):
            child_folder.print_tree(level + 1)

        # Now output all the entities, sorted by name then entity type
        for type_name_tuple, doc_ref in sorted(
                self.entities.items(),
                key=lambda item: (item[0][1], item[0][0])):
            if doc_ref.entity_type != "Folder":
                preV6Str = "(pre-v6)" if doc_ref.isPreV6 else ""
                print("{}{}- {} [{}] {} {}"
                    .format(
                        indent_str, 
                        single_indent, 
                        Col.green(doc_ref.name),
                        Col.cyan(doc_ref.entity_type),
                        Col.dark_grey(doc_ref.uuid),
                        Col.red(preV6Str)))

    @staticmethod
    def create_root_folder():
        return Folder("", None, None)


# Class to represent a stroom DocRef object that uniquely defines an entity
class DocRef:
    def __init__(self, entity_type, uuid, name, isPreV6=False):
        self.entity_type = entity_type
        self.uuid = uuid
        self.name = name
        self.isPreV6 = isPreV6

    def __str__(self):
        return "entity_type: {}, uuid: {}, name: {}, isPreV6 {}".format(
            self.entity_type, self.uuid, self.name, self.isPreV6)


# Class to represent a .node file, i.e. a DocRef with a path to provide a
# location in the folder tree
class Node:
    # def __init__(self, path, entity_type, uuid, name):
    def __init__(self, path, doc_ref):
        self.path = path
        self.doc_ref = doc_ref

    def __str__(self):
        return "path: {}, doc_ref: {}".format(self.path, self.doc_ref)


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


def print_error(msg):
    print(''.join([Col.red("ERROR"), " - ", msg]))


def error_exit(msg):
    print_error(msg)
    exit(1)


def extract_doc_ref_from_xml(entity_file):
    if not os.path.isfile(entity_file):
        error_exit("Entity file {} does not exist".format(entity_file))

    # logging.debug("Extracting uuid for {}".format(entity_file))
    xml_root = ET.parse(entity_file).getroot()
    entity_type = xml_root.tag
    uuidElm = xml_root.find('uuid')
    nameElm = xml_root.find('name')

    uuid = uuidElm.text if uuidElm != None else None
    name = nameElm.text if nameElm != None else None

    return DocRef(entity_type, uuid, name, True)


def parse_node_file(node_file):
    if not os.path.isfile(node_file):
        error_exit("Node file {} does not exist".format(node_file))

    dummy_section_name = 'dummy_section'

    # ConfigParser is meant to deal with .ini files so adding dummy_section
    # is a bit of a hack to work with section-less config files that look
    # like .ini files.
    with open(node_file, 'r') as f:
        config_string = '[' + dummy_section_name + ']\n' + f.read()

    config = configparser.ConfigParser()
    config.read_string(config_string)
    return config[dummy_section_name]


# Turn the doc_ref name into a safe form for use in a filename
def get_safe_file_name(doc_ref):
    # Logic duplicated from 
    # stroom.importexport.server.ImportExportFileNameUtil

    safe_name = re.sub("[^A-Za-z0-9]", "_", doc_ref.name)
    # Limit to 100 chars
    safe_name = safe_name[0:100]
    return safe_name


def validate_node_against_node_file(node, node_file):
    # This validation matches the code in
    # stroom.importexport.server.ImportExportFileNameUtil
    filename = os.path.basename(node_file)
    doc_ref = node.doc_ref

    safe_name = get_safe_file_name(doc_ref)
    pattern = "{}\\.{}\\.{}\\.node".format(
            safe_name, doc_ref.entity_type, doc_ref.uuid)

    if re.match(pattern, filename) == None:
        error_exit("The name of node file {} does not match expected pattern {}"
                .format(
                    Col.blue(node_file),
                    Col.green(pattern)))


def extract_node_from_node_file(node_file):
    node_config = parse_node_file(node_file)
    uuid = node_config.get('uuid')
    entity_type = node_config.get('type')
    name = node_config.get('name')
    path = node_config.get('path')

    doc_ref = DocRef(entity_type, uuid, name)
    node = Node(path, doc_ref)

    validate_node_against_node_file(node, node_file)

    return node


def validate_pre_stroom_six_folder_uuids(stroom_content_path, path_to_uuid_dict):
    logging.debug("validate_pre_stroom_six_folder_uuids([{}]) called"
            .format(stroom_content_path))
    # make sure we don't have multiple folder entities with
    # different uuids else this may cause odd behaviour on import
    for root, dirnames, filenames in os.walk(stroom_content_path):
        for dirname in dirnames:
            logging.debug("dirname: {}".format(dirname))
            full_filename = os.path.join(
                root, dirname, '..', dirname + FOLDER_ENTITY_SUFFIX)
            logging.debug("full_filename: {}".format(full_filename))
            entity_path = os.path.relpath(
                os.path.join(root, dirname), stroom_content_path)
            logging.debug("entity_path: {}".format(entity_path))
            doc_ref = extract_doc_ref_from_xml(full_filename)
            uuid = doc_ref.uuid
            if uuid == None:
                error_exit("Entity file {} does not have a UUID"
                    .format(Col.blue(full_filename)))
            logging.debug("uuid = {}".format(uuid))

            if not entity_path in path_to_uuid_dict:
                path_to_uuid_dict[entity_path] = uuid
            elif path_to_uuid_dict[entity_path] != uuid:
                error_exit("Multiple uuids exist for path {}"
                    .format(Col.blue(entity_path)))


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
        if existing_doc_ref.entity_type == "Folder":
            if existing_doc_ref.name != doc_ref.name:
                error_exit(("Folder {} has a duplicate UUID {}. " 
                    + "Duplicate of entity {}").format(
                    Col.blue(full_filename), 
                    Col.yellow(doc_ref.uuid), 
                    Col.green(existing_doc_ref.name)))
        else:
            error_exit(("Entity {} with type {} has a duplicate UUID {}. " 
                + "Duplicate of entity {} with type {}").format(
                Col.blue(full_filename), 
                Col.cyan(doc_ref.entity_type), 
                Col.yellow(doc_ref.uuid), 
                Col.green(existing_doc_ref.name), 
                Col.cyan(existing_doc_ref.entity_type)))
    else:
        # Add our unique uuid/doc_ref to the dict
        uuid_to_doc_ref_dict[doc_ref.uuid] = doc_ref


def extract_entity_uuids_from_xml(pack_dir, uuid_to_doc_ref_dict, node_tree):
    for root, dirnames, filenames in os.walk(pack_dir):
        for xml_file in fnmatch.filter(filenames, '*.xml'):
            if not xml_file.endswith(".data.xml"):
                logging.debug("root: {}".format(root))
                logging.debug("xml_file: {}".format(xml_file))

                full_filename = os.path.join(root, xml_file)

                doc_ref = extract_doc_ref_from_xml(full_filename)
                logging.debug("doc_ref: {}".format(doc_ref))

                if doc_ref.entity_type != "folder":
                    # this is a stroom entity, not a folder
                    entity_path = os.path.relpath(
                        root, pack_dir)
                    logging.debug("entity_path: {}".format(entity_path))
                    node = Node(entity_path, doc_ref)

                    # Add the found node to our tree, which will ensure the
                    # entity name is unique within its path
                    node_tree.add_node(node)

                    if doc_ref.entity_type != FOLDER_ENTITY_TYPE:
                        check_if_uuid_already_used(
                            doc_ref, 
                            uuid_to_doc_ref_dict, 
                            full_filename)


def extract_entity_uuids_from_node_files(
        pack_dir, uuid_to_doc_ref_dict, node_tree):
    for root, dirnames, filenames in os.walk(pack_dir):
        for node_file in fnmatch.filter(filenames, '*.node'):
            logging.debug("node_file: {}".format(node_file))
            full_filename = os.path.join(root, node_file)
            logging.debug("full_filename: {}".format(full_filename))
            node = extract_node_from_node_file(full_filename)

            # Add the found node to our tree, which will ensure the
            # entity name is unique within its path
            node_tree.add_node(node)

            check_if_uuid_already_used(
                node.doc_ref, 
                uuid_to_doc_ref_dict, 
                full_filename)


def validate_pack(
        pack, root_path, path_to_uuid_dict, uuid_to_doc_ref_dict, node_tree):

    # validation rules:
    # All folder entities (pre-v6 only) must have a uniqe UUID
    # All entities must have a unique UUID
    # All entities must have a unique (name, type) within a folder
    # All node files must have a filename that matches a specific format

    pack_path = os.path.join(root_path, pack)

    #check the folder exists for the pack name
    if not os.path.isdir(pack_path):
        error_exit("Pack {} does not exist in {}".format(pack, root_path))

    stroom_content_path = os.path.join(pack_path, STROOM_CONTENT_DIR_NAME)

    # Determine if this pack is in v6+ format or not by the presence
    # of any .node files
    is_stroom_six_or_above = is_pack_stroom_six_or_greater(stroom_content_path)
            
    preV6Str = "" if is_stroom_six_or_above else "(pre-v6)"
    print("Validating pack {} {}".format(
        Col.green(pack),
        Col.red(preV6Str)))

    if not is_stroom_six_or_above:
        validate_pre_stroom_six_folder_uuids(
                stroom_content_path, 
                path_to_uuid_dict)

    #Loop through all the xml files finding those that have a uuid element
    #for each one that isn't a folder entity make sure the uuid
    #is not already used by another entity
    if is_stroom_six_or_above:
        extract_entity_uuids_from_node_files(
                stroom_content_path,
                uuid_to_doc_ref_dict,
                node_tree)
    else:
        extract_entity_uuids_from_xml(
                stroom_content_path, 
                uuid_to_doc_ref_dict,
                node_tree)


def validate_packs(pack_list, root_path):

    # logging.debug("Validating packs: {}".format(pack_list))
    
    # A dict of path=>uuid mappings to establish if we have multiple folder
    # paths with the same uuid (pre stroom6 only)
    path_to_uuid_dict = dict()
    # A dict of uuid=>docref
    uuid_to_doc_ref_dict = dict()

    # Create the root node of the folder/entity tree
    node_tree = Folder.create_root_folder()

    print("\nValidating content packs")
    for pack in pack_list:
        validate_pack(
            pack, 
            root_path, 
            path_to_uuid_dict, 
            uuid_to_doc_ref_dict, 
            node_tree)

    print("\nUUIDs for pre-v6 paths:")
    for key in sorted(path_to_uuid_dict):
        print("{} - {}".format(
            Col.bold_blue(key),
            Col.dark_grey(path_to_uuid_dict[key])))

    print("\nDisplaying the complete explorer tree for the chosen packs\n")
    node_tree.print_tree()

    print("\nValidation completed with no errors")




# Script proper starts here
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if len(sys.argv) == 1:
    print_error("No arguments supplied")
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
    print_error("Cannot specify --all and named packs")
    print_usage()
    exit(1)

if len(packs_to_build) == 0 and not isAllPacks:
    print_error("Must specify --all or provide a list of named packs")
    print_usage()
    exit(1)

if isAllPacks:
    print("Processing all content packs")
    for list_entry in os.listdir(source_path):
        if os.path.isdir(os.path.join(source_path, list_entry)):
            packs_to_build.append(list_entry)
else:
    print("Processing packs: {}".format(packs_to_build))

print("Using root path: {}".format(Col.blue(root_path)))
print("Using source path: {}".format(Col.blue(source_path)))

validate_packs(packs_to_build, source_path)

print("Done!")
exit(0)
