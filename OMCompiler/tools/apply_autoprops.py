#!/usr/bin/env python

# To do:
# 1) Switch to using the Subversion Python bindings.
#
# $HeadURL$
# $LastChangedRevision$
# $LastChangedDate$
# $LastChangedBy$
#
# Copyright (C) 2005,2006 Blair Zajac <blair@orcaware.com>
#
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This script is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# A copy of the GNU General Public License can be obtained by writing
# to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA 02111-1307 USA.

import getopt
import fnmatch
import os
import re
import sys

# The default path to the Subversion configuration file.
SVN_CONFIG_FILENAME = os.path.expandvars('$HOME/.subversion/config')

# The name of Subversion's private directory in working copies.
SVN_WC_ADM_DIR_NAME = '.svn'

# The name this script was invoked as.
PROGNAME = os.path.basename(sys.argv[0])

def usage():
  print("""This script reads the auto-properties defined in the file
'%s'
and applies them recursively to all the files and directories in the
current working copy.  It may behave differently than the Subversion
command line; where the subversion command line may only apply a single
matching auto-property to a single pathname, this script will apply all
matching lines to a single pathname.

Usage:
  %s [options] [WC_PATH]
where WC_PATH is the path to a working copy.
If WC_PATH is not specified, '.' is assumed.

Valid options are:
  --help, -h         : Print this help text.
  --config ARG       : Read the Subversion config file at path ARG
                       instead of '%s'.
""" % (SVN_CONFIG_FILENAME, PROGNAME, SVN_CONFIG_FILENAME))

def get_autoprop_lines(fd):
  lines = []
  reading_autoprops = 0

  re_start_autoprops = re.compile('^\s*\[auto-props\]\s*')
  re_end_autoprops = re.compile('^\s*\[\w+\]\s*')

  for line in fd.xreadlines():
    if reading_autoprops:
      if re_end_autoprops.match(line):
        reading_autoprops = 0
        continue
    else:
      if re_start_autoprops.match(line):
        reading_autoprops = 1
        continue

    if reading_autoprops:
      lines += [line]

  return lines

def process_autoprop_lines(lines):
  result = []

  for line in lines:
    # Split the line on the = separating the fnmatch string from the
    # properties.
    try:
      (fnmatch, props) = line.split('=', 1)
    except ValueError:
      continue

    # Remove leading and trailing whitespace from the fnmatch and
    # properties.
    fnmatch = fnmatch.strip()
    props = props.strip()

    # Create a list of property name and property values.  Remove all
    # leading and trailing whitespce from the propery names and
    # values.
    props_list = []
    for prop in props.split(';'):
      prop = prop.strip()
      if not len(prop):
        continue
      try:
        (prop_name, prop_value) = prop.split('=', 1)
        prop_name = prop_name.strip()
        prop_value = prop_value.strip()
      except ValueError:
        prop_name = prop
        prop_value = '*'
      if len(prop_name):
        props_list += [(prop_name, prop_value)]

    result += [(fnmatch, props_list)]

  return result

def filter_walk(autoprop_lines, dirname, filenames):
  # Do not descend into a .svn directory.
  try:
    filenames.remove(SVN_WC_ADM_DIR_NAME)
  except ValueError:
    pass

  filenames.sort()

  # Find those filenames that match each fnmatch.
  for autoprops_line in autoprop_lines:
    fnmatch_str = autoprops_line[0]
    prop_list = autoprops_line[1]

    matching_filenames = fnmatch.filter(filenames, fnmatch_str)
    matching_filenames = [f for f in matching_filenames \
      if not os.path.islink(os.path.join(dirname, f))]
    if not matching_filenames:
      continue

    for prop in prop_list:
      command = ['svn', 'propset', prop[0], prop[1]]
      for f in matching_filenames:
        command += ["%s/%s" % (dirname, f)]

      status = os.spawnvp(os.P_WAIT, 'svn', command)
      if status:
        print('Command %s failed with exit status %s' \
              % (command, status))

def main():
  try:
    opts, args = getopt.getopt(sys.argv[1:], 'h', ['help', 'config='])
  except getopt.GetoptError, e:
    usage()
    return 1

  config_filename = None
  for (o, a) in opts:
    if o == '-h' or o == '--help':
      usage()
      return 0
    elif o == '--config':
      config_filename = os.path.abspath(a)

  if not config_filename:
    config_filename = SVN_CONFIG_FILENAME

  if len(args) == 0:
    wc_path = '.'
  elif len(args) == 1:
    wc_path = args[0]
  else:
    usage()
    print("Too many arguments: %s" % ' '.join(args))
    return 1

  try:
    fd = file(config_filename)
  except IOError:
    print("Cannot open svn configuration file '%s' for reading: %s" \
          % (config_filename, sys.exc_value.strerror))
    return 1

  autoprop_lines = get_autoprop_lines(fd)

  fd.close()

  autoprop_lines = process_autoprop_lines(autoprop_lines)

  os.path.walk(wc_path, filter_walk, autoprop_lines)

if __name__ == '__main__':
  sys.exit(main())
