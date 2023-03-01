#!/usr/bin/env python3

"""
Copyright 2021-Present Couchbase, Inc.

Use of this software is governed by the Business Source License included in
the file licenses/BSL-Couchbase.txt.  As of the Change Date specified in that
file, in accordance with the Business Source License, use of this software will
be governed by the Apache License, Version 2.0, included in the file
licenses/APL2.txt.
"""

# This script is responsible for reading the environment files from
# built cbpy cbdeps packages and verifying that
# couchbase-server-black-duck-manifest.yaml is correct.

import argparse
import pathlib
import pprint
import re
import sys
import tarfile
import yaml
from collections import defaultdict

platforms = ["linux-x86_64", "linux-aarch64", "macosx-x86_64", "macosx-arm64", "windows-amd64"]

def dd():
    return defaultdict(dd)

def comment(s):
    return f"#{' ' if len(s.strip()) > 0 else ''}{s}"

def raw_version_string(v):
    """
    returns a given string minus the leading v/V, to ease comparison
    """
    if str(v).lower()[0] == "v":
        return str(v[1:])
    return str(v)

def read_dependencies_file(f):
    """
    Retrieve a dict of product:versions from a requirements.txt
    style text file
    """
    d = {}
    with f.open() as reqs:
        for line in reqs.readlines():
            line = line.strip()
            if not line.startswith("#") and line != "":
                [dep, ver] = line.split("=")
                d[dep] = ver
    print (f"Read {f}: {pprint.pformat(d)}")
    return d

def load_environments():
    """
    Reads platform files from cbdeps package .tgz files, saving the
    results in environment_deps
    """
    for platform in platforms:
        environment_deps[platform] = {}
        tarball = directory / f"cbpy-{platform}-{cbpy_version}.tgz"
        print (f"Reading environment from {tarball}...")
        with tarfile.open(tarball, "r:*") as tar:
            envfile = tar.extractfile(f"./env/environment-{platform}.txt")
            for line in envfile.readlines():
                if line.startswith(b"#"):
                    continue
                [package, version] = re.split(r'\s+', line.decode('utf-8'))[0:2]
                environment_deps[platform][package] = version

def detect_blackduck_drift():
    blackduck = dd()
    # Figure out what packages have drifted or are missing from black duck manifest
    for target_platform in environment_deps:
        for dep in environment_deps[target_platform]:
            if dep in bd_ignored:
                continue
            if dep in blackduck_manifest['components']:
                bd_dep_name = dep
            else:
                blackduck['missing'][dep] = environment_deps[target_platform][dep]
                continue
            bd_vers = list(map(raw_version_string, blackduck_manifest['components'][bd_dep_name]['versions']))
            if environment_deps[target_platform][dep] in bd_vers:
                continue
            else:
                blackduck['drifted'][dep] = { "version": environment_deps[target_platform][dep],"manifest_version": bd_vers}

    # Figure out what packages have been removed from black duck manifest
    for bd_dep in blackduck_manifest['components']:
        found = False
        for target_platform in environment_deps:
            for dep in environment_deps[target_platform]:
                if dep == bd_dep:
                    found = True
        if not found:
            blackduck['removed'][bd_dep] = ""

    # If we've got missing/drifted/removed packages, just show the relevant
    # info and error out
    if any(problem in blackduck for problem in ['missing', 'drifted', 'removed']):
        print("ERROR: couchbase-server-black-duck-manifest.yaml is incorrect!")
        if blackduck['missing']:
            print()
            print("Deps in current environments but missing from BD manifest:")
            for dep in blackduck['missing']:
                print(f"   {dep} ({blackduck['missing'][dep]})")
        if blackduck['drifted']:
            print()
            print("Deps with incorrect versions in BD manifest:")
            for dep in blackduck['drifted']:
                print("  ", dep, blackduck['drifted'][dep])
        if blackduck['removed']:
            print()
            print("Deps in BD manifest but no longer in environments:")
            for dep in blackduck['removed']:
                print("  ", dep)
        sys.exit(1)

parser = argparse.ArgumentParser(
    description='Updates Black Duck manifest based on final cbdeps packages'
)
parser.add_argument(
    '-v', '--version', help="Full version of cbdeps package, eg. 7.5.0-cb1",
    type=str, required=True
)
parser.add_argument(
    '-d', '--directory', help="Directory containing final cbdeps package .tgz files",
    type=str, required=True
)
parser.add_argument(
    '-t', '--tlm_dir', help="Path to tlm directory to update (defaults to .)",
    type=str, default="."
)
args = parser.parse_args()

directory = pathlib.Path(args.directory)
tlm_dir = pathlib.Path(args.tlm_dir)
cbpy_version = args.version

# Load tlm files
with (tlm_dir / "couchbase-server-black-duck-manifest.yaml").open() as m:
    blackduck_manifest = yaml.safe_load(m)
with (tlm_dir / "blackduck-ignore.txt").open() as i:
    bd_ignored = [
        x.strip() for x in i.readlines()
        if not x.startswith("#") and x != ""
    ]
bd_ignored.extend(read_dependencies_file(tlm_dir / "cb-stubs.txt").keys())

# Load enviroment files from tarballs
environment_deps = {}
load_environments()

# Finally, verify the black-duck-manifest
detect_blackduck_drift()
print("\n\nBlack Duck Manifest is all correct!\n")