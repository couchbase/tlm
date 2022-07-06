#!/usr/bin/env python3

"""
Copyright 2015-Present Couchbase, Inc.

Use of this software is governed by the Business Source License included in
the file licenses/BSL-Couchbase.txt.  As of the Change Date specified in that
file, in accordance with the Business Source License, use of this software will
be governed by the Apache License, Version 2.0, included in the file
licenses/APL2.txt.
"""

"""Script to tag projects with the release from the manifest.

Requires: Permission to push tags to Gerrit

Usage: Run from the top of a repo checkout:
    tag_release.py <release> <projects..>

e.g.

    tag_release.py 4.0.0 memcached platform

This will print the commands needed to tag the release.
Review, then copy/paste.
"""

import os
import sys
import xml.etree.ElementTree

if len(sys.argv) < 3:
    print("Usage: {} <release> <projects...>".format(
        sys.argv[0]), file=sys.stderr)
    exit(1)

release = sys.argv[1]
manifest_path = None
manifest_subdirs = ["released/", "released/couchbase-server/"]
for subdir in manifest_subdirs:
    path = ".repo/manifests/" + subdir + release + ".xml"
    if os.path.exists(path):
        manifest_path = path
        break

if not manifest_path:
    print("Unable to locate manifest '" + release + ".xml' - searched in:", file=sys.stderr)
    for subdir in manifest_subdirs:
        print("\t" + subdir, file=sys.stderr)
    print("Check specified release and current working " \
        "directory (should be run from top-level of repo checkout).", file=sys.stderr)
    exit(2)

projects_to_tag = sys.argv[2:]

e = xml.etree.ElementTree.parse(manifest_path).getroot()
for p in e.findall('project'):
    if p.attrib['name'] in projects_to_tag:
        name = p.attrib['name']
        sha = p.attrib['revision']
        print("pushd " + name)
        print("""git tag -a -m "{0} release ({1})" v{0} {2}""".format(
            release, name, sha))
        print("git push review v{0}".format(release))
        print("popd")
