#!/usr/bin/env python

import xml.etree.ElementTree as ET
from subprocess import check_output

manifest = check_output(['repo', 'manifest'])
root = ET.fromstring(manifest.decode('utf-8'))

verattr = root.find('project[@name="build"]/annotation[@name="VERSION"]')
if verattr is not None:
    print ('%s-0000' % (verattr.get('value'),))
else:
    print ('0.0.0-9999')
