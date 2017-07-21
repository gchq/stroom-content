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
# removeAuditElements.py
# 
# Usage: buildContentPacks.py 
#
# Script to remove any of the audit elements from the XML files. When Stroom
# exports content, it includes the various audit elements such as createdBy. 
# These elements are not desired in the content pakc source so make merging 
# developed content from Stroom back into source control more difficult.  This 
# script will just strip them out.
#
#**********************************************************************

import sys
import os
import re
import zipfile
import shutil
import fnmatch
import xml.etree.ElementTree as ET

SOURCE_DIR_NAME = "source"
STROOM_CONTENT_DIR_NAME = "stroomContent"
XML_DECLARATION = '<?xml version="1.1" encoding="UTF-8"?>\n'

root_path = os.path.dirname(os.path.realpath(__file__))
source_path = os.path.join(root_path, SOURCE_DIR_NAME)


def remove_element(parent_elm, element_name):
    # print("  parent_elm is {}".format(parent_elm))
    elm = parent_elm.find(element_name)
    if elm is not None:
        # print("  Removing element {}".format(element_name))
        parent_elm.remove(elm)
        return True
    else:
        # print("  Element {} not found".format(element_name))
        return False

def remove_audit_elements(xml_file):
    # print("Processing file {}".format(xml_file))
    try:
        tree = ET.parse(xml_file)
        xml_root = tree.getroot()

        has_changed = False
        has_changed = remove_element(xml_root, 'createTime') or has_changed 
        has_changed = remove_element(xml_root, 'createUser') or has_changed 
        has_changed = remove_element(xml_root, 'updateTime') or has_changed 
        has_changed = remove_element(xml_root, 'updateUser') or has_changed 

        if (has_changed):
            print("Writing changes to file {}".format(xml_file))

            #elementTree uses a slightly different xml declaration to ours so write our own
            # with open(xml_file, 'wb', encoding='utf-8') as f:
            with open(xml_file, 'wb') as f:
                f.write(XML_DECLARATION.encode(encoding='UTF-8'))
                tree.write(f, encoding='UTF-8', xml_declaration=False)
                f.write('\n'.encode(encoding='UTF-8'))

    except ET.ParseError as e:
        print("ERROR file is not valid xml {}".format(xml_file))
        exit(1)

        



# Script proper starts here
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

print("Looking for xml files to clean...")

for the_file in os.listdir(source_path):
    content_dir = os.path.join(source_path, the_file, STROOM_CONTENT_DIR_NAME)
    if os.path.isdir(content_dir): 
        for root, dirnames, filenames in os.walk(content_dir):
            for xml_file in fnmatch.filter(filenames, '*.xml'):
                if (not fnmatch.fnmatch(xml_file, '*.data.xml')):
                    full_filename = os.path.join(root, xml_file)
                    remove_audit_elements(full_filename)

print("Done!")
exit(0)
