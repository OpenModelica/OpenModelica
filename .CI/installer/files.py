#!/usr/bin/env python3
"""Write the NSIS commands that install an OpenModelica install tree.

  files.py <tree> <out.nsh>

The output defines OM_INSTALL_FILES, which installs every file of <tree> through
the logging macros of OpenModelica.nsi, OM_DOC_SHORTCUTS, OM_HAVE_<CLIENT> for
each GUI client in bin/ and OM_HAVE_DOCS if the tree has documentation. The
User's Guide is not in OM_INSTALL_FILES but in OM_INSTALL_USERSGUIDE_FILES
(and OM_HAVE_USERSGUIDE), for a component of its own.
"""

import os
import sys

CLIENTS = ['OMEdit', 'OMNotebook', 'OMShell']

USERSGUIDE = 'share/doc/OpenModelica/UsersGuide'

DOCS = [
  ('share/doc/OpenModelica/UsersGuide/html/index.html', "OpenModelica User's Guide"),
  ('share/doc/OpenModelica/UsersGuide/OpenModelicaUsersGuide.pdf', "OpenModelica User's Guide (PDF)"),
  ('share/doc/OpenModelica/ModelicaTutorialFritzson.pdf', 'Modelica Tutorial by Peter Fritzson'),
  ('share/doc/OpenModelica/OpenModelicaSystem.pdf', 'OpenModelica System Guide'),
  ('share/doc/OpenModelica/OpenModelicaMetaProgramming.pdf', 'OpenModelica MetaProgramming Guide'),
  ('share/doc/OpenModelica/OpenModelicaTemplateProgramming.pdf', 'OpenModelica Template Programming Guide'),
]


def quote(s):
  return s.replace('$', '$$').replace('"', '$\\"')


def windows(rel):
  return '' if rel == '.' else '\\' + rel.replace('/', '\\')


def write_files(f, tree, top, skip=None):
  for root, dirs, files in os.walk(top):
    dirs[:] = sorted(d for d in dirs if os.path.join(root, d) != skip)
    f.write('  ${SetOutPath} "\\\\?\\$INSTDIR%s"\n' % quote(windows(os.path.relpath(root, tree))))
    for name in sorted(files):
      f.write('  ${File} "%s" "%s"\n' % (quote(os.path.join(root, name)), quote(name)))


def main(tree, out):
  tree = os.path.abspath(tree)
  if not os.path.isfile(os.path.join(tree, 'bin', 'omc.exe')):
    sys.exit('%s has no bin/omc.exe' % tree)
  with open(out, 'w', encoding='utf-8') as f:
    for client in CLIENTS:
      if os.path.isfile(os.path.join(tree, 'bin', client + '.exe')):
        f.write('!define OM_HAVE_%s\n' % client.upper())

    usersguide = os.path.join(tree, USERSGUIDE)
    f.write('!macro OM_INSTALL_FILES\n')
    write_files(f, tree, tree, skip=usersguide)
    f.write('!macroend\n')
    if os.path.isdir(usersguide):
      f.write('!define OM_HAVE_USERSGUIDE\n')
      f.write('!macro OM_INSTALL_USERSGUIDE_FILES\n')
      write_files(f, tree, usersguide)
      f.write('!macroend\n')

    docs = [(rel, title) for rel, title in DOCS if os.path.isfile(os.path.join(tree, rel))]
    if docs:
      f.write('!define OM_HAVE_DOCS\n')
    f.write('!macro OM_DOC_SHORTCUTS\n')
    for rel, title in docs:
      f.write('  ${If} ${FileExists} "$INSTDIR%s"\n' % quote(windows(rel)))
      f.write('    ${CreateShortcut} "$SMPROGRAMS\\$StartMenuGroup\\Documentation\\%s.lnk" "$INSTDIR%s" "" "" ""\n'
              % (quote(title), quote(windows(rel))))
      f.write('  ${EndIf}\n')
    f.write('!macroend\n')


if __name__ == '__main__':
  if len(sys.argv) != 3:
    sys.exit('usage: files.py <tree> <out.nsh>')
  main(sys.argv[1], sys.argv[2])
