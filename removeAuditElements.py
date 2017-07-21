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

root_path = os.path.dirname(os.path.realpath(__file__))
source_path = os.path.join(root_path, SOURCE_DIR_NAME)


def remove_element(parent_elm, element_name):
    elm = xml_root.find('./' + element_name)
    if elm is not None:
        print("  Removing element {}".format(element_name))
        parent_elm.remove(elm)
        return True
    else:
        return False

def remove_audit_elements(xml_file):
    print("Processing file {}".format(xml_file))
    xml_root = ET.parse(entity_file).getroot()

    has_changed = False
    has_changed = has_changed or remove_element('createTime')
    has_changed = has_changed or remove_element('createUser')
    has_changed = has_changed or remove_element('updateTime')
    has_changed = has_changed or remove_element('createUser')

    if (has_changed):
        print("Writing changes to file {}".format(xml_file))
        ET.write(open(xml_file, 'w'))



# Script proper starts here
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

for root, dirnames, filenames in os.walk(stroom_content_path):
    for xml_file in fnmatch.filter(filenames, '*.xml'):
        full_filename = os.path.join(root, xml_file)
        remove_audit_elements(full_filename)

print("Done!")
exit(0)
