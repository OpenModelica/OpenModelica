#!/usr/bin/env python3
# To test this, use for example:
# rsync -a --progress test.openmodelica.org:/var/www/libraries/ --include=*/ --include="*.uses" --include="*.classes" --exclude='*' --delete .
# python3 CountClassUses.py MSL_3.2.1 ModelicaTest_3.2.1
# Or use the BuildModelRecursive.mos script to generate the required files

import glob
from sys import argv

classes = glob.glob('*/files/*.classes')

library = argv[1]
for f in argv[1:]:
  assert -1 == f.find('/')

all_classes = dict((c.strip(),[]) for c in open(glob.glob('%s/files/*.classes' % library)[0], 'r').readlines())
unused_classes = set(all_classes.keys()) # Mainly for debugging since we print out the count of classes...

for cls in [glob.glob('%s/files/*.uses' % cl) for cl in argv[1:]]:
  for cl in cls:
    name = cl[:-5].split('files/')[1]
    used_classes = set(c.strip() for c in open(cl,'r').readlines())
    unused_classes = unused_classes - used_classes
    for c in used_classes:
      if c in all_classes:
        all_classes[c].append(name)

print(argv[1],'coverage using example models in',', '.join(argv[1:]))
for cl in sorted(all_classes, key = lambda cl: (len(all_classes[cl]),cl)):
  print(len(all_classes[cl]),cl)
