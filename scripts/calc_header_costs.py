#!/usr/bin/env python

"""Calculate the costs of compiling headers; by considering how many
times each header is included compared to the time to compile it.

Requires two files:

1. Dependancy information for each target, so we can determine how
   many times each header is included. For example if using Ninja:

       $ ninja -t deps > deps.txt

2. List of costs of compiling each target. For example if using Ninja:

       show_ninja_build_stats < .ninja_log > costs.txt

Output:

Prints a list of all headers which have both cost and dependancy
information, of the form:

   total_time, header, count, cost_to_compile

total_time: 'count' * 'cost'. This attempts to measure the overall
            cost of this header across the whole build.
header: Path to header
count: Number of targets which depend on this header (i.e. how many
       times it is included)
cost_to_compile: time in seconds to compile this header.


By sorting by the first column one can identify potential build
hotspots. Either reduce the number of times they are included; or the
cost to compile to minimise the overall impact.
"""

from __future__ import print_function
import collections
import os
import re
import sys

if len(sys.argv) != 3:
    print("Usage: <deps_file> <header costs>", file=sys.stderr)
    sys.exit(1)

headers = collections.defaultdict(dict)

with open(sys.argv[1]) as deps:
    for line in deps:
        # File consists of a paragraph for each target. Each paragraph
        # is of the form:
        #
        # relative/path/to/target.cc.o: #deps ... extra details
        #     ../path/to/dependancy1.cc
        #     /path/to/dependancy2.h
        # <blank line>
        if '#deps' in line:
            # Target name
            (target, _x) = line.split(':', 1)
            # Ignore targets which we don't want to count dependancies
            # for - such as the '.h.cc' fake targets.
            if target.endswith('.h.cc.o'):
                target = None
        elif line[0] != '\n':
            # Dependancy name
            dep = line.strip()
            # Remove any '../XXX/' prefix (due to source -> build path
            # conversion).
            # Assumes that the build directory is located inside the source.
            if dep.startswith('../'):
                dep = dep[3:]
            if 'count' not in headers[dep]:
                headers[dep]['count'] = 0
            headers[dep]['count'] += 1
            if (dep.startswith('/usr/include/') or
                dep.startswith('/Applications/Xcode.app')):
                headers[dep]['system'] = True
        else:
            # Paragraph (target) separator.
            target = None

with open(sys.argv[2]) as costs:
    for line in costs:
        (cost, target) = line.split()
        # Ignore the building of the .h.cc - that's just the cost to
        # create a symlink.
        if target.endswith('.h.cc'):
            continue
        # Fixup name of the .h.cc.o fake targets -> .h
        if target.endswith('.h.cc.o'):
            target = target[:-5]
            target = re.sub('CMakeFiles/.*_obj.dir/', '', target)
        headers[target]['cost'] = float(cost)

for k,v in headers.items():
    if 'count' in v:
        if 'cost' in v:
            total_cost = v['count'] * v['cost']
            print(total_cost, k, v['count'], v['cost'])
        else:
            # No cost value - print warming if this is a high count
            # header (and not system)
            if v['count'] > 100 and 'system' not in v:
                print("Warning: No cost value for '{}' but has " + "#include count of {}".format(k, v['count']),
                      file=sys.stderr)
