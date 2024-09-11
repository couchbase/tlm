#!/usr/bin/env python

"""
Copyright 2017-Present Couchbase, Inc.

Use of this software is governed by the Business Source License included in
the file licenses/BSL-Couchbase.txt.  As of the Change Date specified in that
file, in accordance with the Business Source License, use of this software will
be governed by the Apache License, Version 2.0, included in the file
licenses/APL2.txt.
"""

# This script should work with python2 or python3. It also tries to
# never throw an error depsite what manifest nonsense it might come
# across. If it can't find the annotation for whatever reason, it
# outputs nothing.

import os
import subprocess
import sys
import xml.etree.ElementTree as ET

# Annotation name
if len(sys.argv) < 2:
    sys.exit(0)

# Find appropriate manifest - either in .repo directory, or in file named
# 'manifest.xml' in cwd. If neither available, exit without complaint.
manifest = ''
if os.path.isdir(".repo"):
    with open(os.devnull, "w") as devnull:
        try:
            proc = subprocess.Popen(
                ['repo', 'manifest'],
                stdout=subprocess.PIPE,
                stderr=devnull,
                shell=True
            )
            manifest_bytes, _ = proc.communicate()
            manifest = manifest_bytes.decode('utf-8')
        except:
            # Ignore it
            pass
elif os.path.exists("manifest.xml"):
    with open("manifest.xml") as m:
        manifest = m.read()

if manifest == '':
    # Failed to get manifest for some reason
    sys.exit(0)

root = ET.fromstring(manifest)

# Return the first requested annotation that's found
for annot in sys.argv[1:]:
    attr = root.find(f'project[@name="build"]/annotation[@name="{annot}"]')
    if attr is not None:
        value = attr.get('value')
        if value is not None:
           print (value)
           sys.exit(0)
