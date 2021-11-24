#!/usr/bin/env python

"""
Copyright 2017-Present Couchbase, Inc.

Use of this software is governed by the Business Source License included in
the file licenses/BSL-Couchbase.txt.  As of the Change Date specified in that
file, in accordance with the Business Source License, use of this software will
be governed by the Apache License, Version 2.0, included in the file
licenses/APL2.txt.
"""

# See primary explanation for what this script does in CMakeLists.txt.

# This script needs to work with python2 or python3. It also tries
# to never throw an error depsite what manifest nonsense it might come across.
# If it can't find the version for whatever reason, it outputs nothing.

import os
import subprocess
import sys
import xml.etree.ElementTree as ET

manifest = ''
with open(os.devnull, "w") as devnull:
    try:
        proc = subprocess.Popen(
            ['repo', 'manifest'],
            stdout=subprocess.PIPE,
            stderr=devnull
        )
        manifest, _ = proc.communicate()
    except:
        # Ignore it
        pass

if manifest == '':
    # Failed to get manifest for some reason
    sys.exit(0)

root = ET.fromstring(manifest.decode('utf-8'))

verattr = root.find('project[@name="build"]/annotation[@name="VERSION"]')
if verattr is not None:
    version = verattr.get('value')
    if version is not None:
        print (version + "-0000")
