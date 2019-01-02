#!/usr/bin/env python

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
    print >> sys.stderr, "Usage: {} <release> <projects...>".format(
        sys.argv[0])
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
    print >> sys.stderr, "Unable to locate manifest '" + release + ".xml' - searched in:"
    for subdir in manifest_subdirs:
        print >> sys.stderr, "\t" + subdir
    print >> sys.stderr, "Check specified release and current working " \
        "directory (should be run from top-level of repo checkout)."
    exit(2)

projects_to_tag = sys.argv[2:]

e = xml.etree.ElementTree.parse(manifest_path).getroot()
for p in e.findall('project'):
    if p.attrib['name'] in projects_to_tag:
        name = p.attrib['name']
        sha = p.attrib['revision']
        print "pushd " + name
        print """git tag -a -m "{0} release ({1})" v{0} {2}""".format(
            release, name, sha)
        print "git push review v{0}".format(release)
        print "popd"
