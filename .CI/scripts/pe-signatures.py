#!/usr/bin/env python3
"""Move Windows binaries (PE images) to the signing machine and back.

  pe-signatures.py collect <tree> <out>
      Copy each .exe and .dll of <tree> that has no Authenticode signature to
      the same relative path below <out>.
  pe-signatures.py apply <signed> <tree>...
      Copy each signed file of <signed> over the file at the same relative path
      of each <tree> that has it. That file must be the signed one without its
      signature, and each <tree> must have at least one of them.
"""

import os
import shutil
import struct
import sys


def headers(data):
  """Offsets of the CheckSum field and of the certificate table entry, or None."""
  if len(data) < 0x40 or data[:2] != b'MZ':
    return None
  pe = struct.unpack_from('<I', data, 0x3c)[0]
  if data[pe:pe + 4] != b'PE\0\0':
    return None
  opt = pe + 24
  magic = struct.unpack_from('<H', data, opt)[0]
  return opt + 64, opt + (112 if magic == 0x20b else 96) + 4 * 8


def certificate_table(data):
  """(offset, size) of the certificate table; size 0 if there is none."""
  return struct.unpack_from('<II', data, headers(data)[1])


def without_signature(data):
  checksum, entry = headers(data)
  offset, size = certificate_table(data)
  image = bytearray(data[:offset] if size else data)
  image[checksum:checksum + 4] = bytes(4)
  image[entry:entry + 8] = bytes(8)
  # The certificate table starts on an 8-byte boundary.
  return bytes(image).rstrip(b'\0')


def read(path):
  with open(path, 'rb') as f:
    return f.read()


def pe_files(root):
  for dirpath, dirs, names in os.walk(root):
    dirs.sort()
    for name in sorted(names):
      path = os.path.join(dirpath, name)
      if name.lower().endswith(('.exe', '.dll')) and not os.path.islink(path):
        data = read(path)
        if headers(data):
          yield os.path.relpath(path, root), data


def collect(tree, out):
  n = 0
  for rel, data in pe_files(tree):
    if certificate_table(data)[1] == 0:
      os.makedirs(os.path.dirname(os.path.join(out, rel)), exist_ok=True)
      shutil.copy2(os.path.join(tree, rel), os.path.join(out, rel))
      print(rel)
      n += 1
  print('%d unsigned files in %s' % (n, tree))


def apply(signed, trees):
  files = list(pe_files(signed))
  for rel, data in files:
    if certificate_table(data)[1] == 0:
      sys.exit('%s is not signed' % os.path.join(signed, rel))
  for tree in trees:
    n = 0
    for rel, data in files:
      target = os.path.join(tree, rel)
      if not os.path.isfile(target):
        continue
      old = read(target)
      if old != data:
        if not headers(old) or without_signature(old) != without_signature(data):
          sys.exit('%s is not the file that was signed' % target)
        shutil.copyfile(os.path.join(signed, rel), target)
      n += 1
    if n == 0:
      sys.exit('none of the signed files in %s belongs to %s' % (signed, tree))
    print('%d signed files in %s' % (n, tree))


if __name__ == '__main__':
  if len(sys.argv) == 4 and sys.argv[1] == 'collect':
    collect(sys.argv[2], sys.argv[3])
  elif len(sys.argv) >= 4 and sys.argv[1] == 'apply':
    apply(sys.argv[2], sys.argv[3:])
  else:
    sys.exit(__doc__)
