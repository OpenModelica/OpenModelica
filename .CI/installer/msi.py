#!/usr/bin/env python3
"""Write the WiX source of an MSI of an OpenModelica install tree, for wixl.

  msi.py <tree> <out.wxs> <version>

<version> is the version without the leading v, as for OpenModelica.nsi. The MSI
registers the installation like the NSIS installer does (SOFTWARE\\OpenModelica
<version>, OPENMODELICAHOME_<version>) and has these features:

  Core     everything in <tree> but the User's Guide
  Docs     the User's Guide (files.USERSGUIDE)
  Default  OPENMODELICAHOME and the .mo and .onb file associations

A nightly build replaces the previous nightly build of the same release series.
Releases install side by side.
"""

import os
import re
import sys
import uuid
from xml.sax.saxutils import quoteattr

from files import CLIENTS, DOCS, USERSGUIDE

NAMESPACE = uuid.UUID('4c6d2a1e-9f0b-4f63-8a57-0d0b6b6c8f51')
COMPANY = 'Open Source Modelica Consortium (OSMC) and Linköping University (LiU)'
CLIENT_TITLES = {
  'OMEdit': 'OpenModelica Connection Editor',
  'OMNotebook': 'OpenModelica Notebook',
  'OMShell': 'OpenModelica Shell',
}


def guid(*parts):
  return str(uuid.uuid5(NAMESPACE, '\0'.join(parts))).upper()


def versions(version):
  """The MSI ProductVersion and UpgradeCode for an OpenModelica version."""
  m = re.match(r'(\d+)\.(\d+)\.(\d+)(?:-[^-]+)?(?:-(\d+)-g[0-9a-f]+)?$', version)
  if not m:
    sys.exit('cannot make an MSI version of %s' % version)
  major, minor, patch, count = m.groups()
  if count:
    return '%s.%s.%s' % (major, minor, count), guid('nightly', major, minor), True
  return '%s.%s.%s' % (major, minor, patch), guid('release', version), False


class Writer:
  def __init__(self, version):
    self.version = version
    self.lines = []
    self.n = 0
    self.features = {'Core': [], 'Docs': [], 'Default': []}

  def id(self, prefix):
    self.n += 1
    return '%s%d' % (prefix, self.n)

  def add(self, depth, text):
    self.lines.append('  ' * depth + text)

  def component(self, depth, feature, key, body):
    cid = self.id('c')
    self.features[feature].append(cid)
    self.add(depth, '<Component Id="%s" Guid="%s" Win64="yes">' % (cid, guid(self.version, key)))
    for line in body:
      self.add(depth + 1, line)
    self.add(depth, '</Component>')

  def directory(self, depth, node, rel):
    for name, path, feature in node['files']:
      self.component(depth, feature, rel + '/' + name,
                     ['<File Id="%s" Name=%s Source=%s KeyPath="yes"/>'
                      % (self.id('f'), quoteattr(name), quoteattr(path))])
    for name in sorted(node['dirs']):
      self.add(depth, '<Directory Id="%s" Name=%s>' % (self.id('d'), quoteattr(name)))
      self.directory(depth + 1, node['dirs'][name], rel + '/' + name)
      self.add(depth, '</Directory>')


def tree_of(tree):
  root = {'dirs': {}, 'files': []}

  def node(rel):
    n = root
    for part in [] if rel == '.' else rel.split('/'):
      n = n['dirs'].setdefault(part, {'dirs': {}, 'files': []})
    return n

  for dirpath, dirs, names in os.walk(tree):
    rel = os.path.relpath(dirpath, tree)
    n = node(rel)
    feature = 'Docs' if (rel + '/').startswith(USERSGUIDE + '/') else 'Core'
    for name in sorted(names):
      n['files'].append((name, os.path.join(dirpath, name), feature))
  return root


def main(tree, out, version):
  tree = os.path.abspath(tree)
  product_version, upgrade_code, nightly = versions(version)
  env_version = re.sub(r'[^A-Za-z0-9]', '_', version)
  regkey = 'SOFTWARE\\OpenModelica %s' % version
  clients = [c for c in CLIENTS if os.path.isfile(os.path.join(tree, 'bin', c + '.exe'))]
  docs = [(rel, title) for rel, title in DOCS if os.path.isfile(os.path.join(tree, rel))]

  w = Writer(version)
  w.add(0, '<?xml version="1.0" encoding="utf-8"?>')
  w.add(0, '<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">')
  w.add(1, '<Product Id="*" Name=%s Language="1033" Version="%s" Manufacturer=%s UpgradeCode="%s">'
        % (quoteattr('OpenModelica ' + version), product_version, quoteattr(COMPANY), upgrade_code))
  w.add(2, '<Package InstallerVersion="500" Compressed="yes" InstallScope="perMachine" Description=%s/>'
        % quoteattr('OpenModelica ' + version))
  w.add(2, '<MajorUpgrade DowngradeErrorMessage="A newer OpenModelica of this series is already installed."/>')
  w.add(2, '<Media Id="1" Cabinet="openmodelica.cab" EmbedCab="yes"/>')
  w.add(2, '<Property Id="ARPURLINFOABOUT" Value="https://openmodelica.org/"/>')
  # The installer does not keep INSTALLDIR; the uninstall and a repair read it back.
  w.add(2, '<Property Id="INSTALLDIR">')
  w.add(3, '<RegistrySearch Id="InstallDirSearch" Root="HKLM" Key=%s Name="Path" Type="raw" Win64="yes"/>' % quoteattr(regkey))
  w.add(2, '</Property>')
  w.add(2, '<Directory Id="TARGETDIR" Name="SourceDir">')
  w.add(3, '<Directory Id="ProgramFiles64Folder">')
  w.add(4, '<Directory Id="INSTALLDIR" Name=%s>' % quoteattr('OpenModelica' + version))
  w.directory(5, tree_of(tree), '')
  w.component(5, 'Core', 'registration', [
    '<RegistryValue Root="HKLM" Key=%s Name="Path" Type="string" Value="[INSTALLDIR]" KeyPath="yes"/>' % quoteattr(regkey),
    '<RegistryValue Root="HKLM" Key=%s Name="Version" Type="string" Value=%s/>' % (quoteattr(regkey), quoteattr(version)),
    '<RegistryValue Root="HKLM" Key=%s Name="Nightly" Type="string" Value="%d"/>' % (quoteattr(regkey), nightly),
    '<Environment Id="OMHOMEVERSION" Name="OPENMODELICAHOME_%s" Value="[INSTALLDIR]" Action="set" Part="all" System="yes" Permanent="no"/>' % env_version,
  ])
  default = ['<Environment Id="OMHOME" Name="OPENMODELICAHOME" Value="[INSTALLDIR]" Action="set" Part="all" System="yes" Permanent="no"/>',
             '<RegistryValue Root="HKLM" Key=%s Name="Default" Type="integer" Value="1" KeyPath="yes"/>' % quoteattr(regkey)]
  for client, ext in [('OMEdit', '.mo'), ('OMNotebook', '.onb')]:
    if client in clients:
      progid = 'Software\\Classes\\' + CLIENT_TITLES[client]
      exe = '[INSTALLDIR]bin\\%s.exe' % client
      default += [
        '<RegistryValue Root="HKLM" Key="Software\\Classes\\%s" Type="string" Value=%s/>' % (ext, quoteattr(CLIENT_TITLES[client])),
        '<RegistryValue Root="HKLM" Key=%s Type="string" Value=%s/>' % (quoteattr(progid + '\\DefaultIcon'), quoteattr(exe + ',0')),
        '<RegistryValue Root="HKLM" Key=%s Type="string" Value=%s/>' % (quoteattr(progid + '\\shell\\open\\command'), quoteattr('"%s" "%%1"' % exe)),
      ]
  w.component(5, 'Default', 'default', default)
  w.add(4, '</Directory>')
  w.add(3, '</Directory>')
  w.add(3, '<Directory Id="ProgramMenuFolder">')
  w.add(4, '<Directory Id="MENUDIR" Name=%s>' % quoteattr('OpenModelica ' + version))
  shortcuts = ['<Shortcut Id="%s" Name=%s Target="[INSTALLDIR]bin\\%s.exe" WorkingDirectory="TempFolder"/>'
               % (w.id('s'), quoteattr(CLIENT_TITLES[c]), c) for c in clients]
  doc_shortcuts = {'Core': [], 'Docs': []}
  for rel, title in docs:
    doc_shortcuts['Docs' if rel.startswith(USERSGUIDE + '/') else 'Core'].append(
      '<Shortcut Id="%s" Name=%s Target=%s/>'
      % (w.id('s'), quoteattr(title), quoteattr('[INSTALLDIR]' + rel.replace('/', '\\'))))
  shortcuts += doc_shortcuts['Core']
  shortcuts += ['<RemoveFolder Id="MENUDIR" On="uninstall"/>',
                '<RegistryValue Root="HKLM" Key=%s Name="StartMenu" Type="integer" Value="1" KeyPath="yes"/>' % quoteattr(regkey)]
  w.component(5, 'Core', 'shortcuts', shortcuts)
  if doc_shortcuts['Docs']:
    w.component(5, 'Docs', 'usersguide-shortcuts', doc_shortcuts['Docs'] + [
      '<RegistryValue Root="HKLM" Key=%s Name="UsersGuide" Type="integer" Value="1" KeyPath="yes"/>' % quoteattr(regkey)])
  w.add(4, '</Directory>')
  w.add(3, '</Directory>')
  w.add(3, '<Directory Id="TempFolder"/>')
  w.add(2, '</Directory>')
  titles = {'Core': ('OpenModelica', 1, ' Absent="disallow"'),
            'Docs': ("User's Guide", 1, ''),
            'Default': ('Default installation', 1, '')}
  for feature, components in w.features.items():
    if not components:
      continue
    title, level, extra = titles[feature]
    w.add(2, '<Feature Id="%s" Title=%s Level="%d"%s>' % (feature, quoteattr(title), level, extra))
    for cid in components:
      w.add(3, '<ComponentRef Id="%s"/>' % cid)
    w.add(2, '</Feature>')
  w.add(1, '</Product>')
  w.add(0, '</Wix>')
  with open(out, 'w', encoding='utf-8') as f:
    f.write('\n'.join(w.lines) + '\n')


if __name__ == '__main__':
  if len(sys.argv) != 4:
    sys.exit('usage: msi.py <tree> <out.wxs> <version>')
  main(*sys.argv[1:])
