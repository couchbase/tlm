#!/usr/bin/env python

import xml.etree.ElementTree as ET

tree = ET.parse('.repo/manifest.xml')
root = tree.getroot()

version = None
buildnum = None

for project in root.findall('project'):
    if project.get('name') == 'build':
        for annotation in project.findall('annotation'):
            if annotation.get('name') == 'VERSION':
                print '%s-0000' % (annotation.get('value'),)
                break
        else:
            print '0.0.0-9999'

        break
else:
    print '0.0.0-9999'
