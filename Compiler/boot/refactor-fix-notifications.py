#!/usr/bin/env python
# Fix warnings in MetaModelica code by refactoring

import sys
import os
import os.path
from pyparsing import *
from optparse import OptionParser
import subprocess

parser = OptionParser()
(options,args) = parser.parse_args()

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'

    def disable(self):
        self.HEADER = ''
        self.OKBLUE = ''
        self.OKGREEN = ''
        self.WARNING = ''
        self.FAIL = ''
        self.ENDC = ''

FILENAME = Regex("[^:]*")
FILEINFO = (FILENAME + Suppress(":") + Word(nums) + Suppress(":") + Word(nums) + Suppress("-") + Word(nums) + Suppress(":") + Word(nums) + Suppress(Regex("[^]]*"))).setParseAction(
  lambda s,s2: {'fileName':s2[0],'startLine':int(s2[1]),'startCol':int(s2[2]),'endLine':int(s2[3]),'endCol':int(s2[4])})
UNUSED_LOCAL = (Suppress("Notification: Unused local variable: ") + Word(alphanums + "_") + "." + StringEnd()).setParseAction(
  lambda s,s2: {'unused_local':s2[0]})
USE_MATCH = Literal("Notification: This matchcontinue expression has no overlapping patterns and should be using match instead of matchcontinue.").setParseAction(
  lambda s,s2: {'mc_to_match':True})
UNKNOWN = Suppress("Notification:")

NOTIFICATION = (Suppress("[") + FILEINFO + Suppress("]") + (UNUSED_LOCAL|USE_MATCH|UNKNOWN))

def runOMC(arg):
  try:
    res = subprocess.check_output(['../../build/bin/omc','+d=patternmAllInfo',arg],stderr=subprocess.STDOUT)
  except subprocess.CalledProcessError as e:
    print e.output,e
    raise

def infoStr(info):
  return "%s:%d:%d" % (info['fileName'],info['startLine'],info['endLine'])

def fixFile(stamp,logFile,moFile):
  runOMC(arg)
  try:
    log = open(logFile, 'r')
  except:
    return # It's ok; there were no messages
  mo = open(moFile, 'r')
  moContents = mo.readlines()
  moOriginalContents = moContents
  lst = [NOTIFICATION.parseString(line.strip()) for line in log.readlines()]
  len1 = len(lst)
  lst = [n for n in lst if n[0]['fileName'] == moFile]
  len2 = len(lst)
  lst.sort(key=lambda n: n[0]['fileName'] + str(n[0]['endLine']),reverse=True)

  for n in lst:
    startLine = n[0]['startLine']
    endLine = n[0]['endLine']
    msg = None
    if len(n)==2 and n[1].has_key('unused_local'):
      pass
      #print "Unused local %s" % n
      #print moContents[endLine-1]
    elif len(n)==2 and n[1].has_key('mc_to_match'):
      success1 = False
      success2 = False
      while startLine < endLine:
        if moContents[startLine-1].count("matchcontinue") == 1:
          success1 = True
          break
        elif moContents[startLine-1].count("matchcontinue") == 0:
          startLine += 1
        else:
          msg = bcolors.WARNING + "Found 2 matchcontinue on the same line (%d): %s" (startLine,moContents[startLine-1].strip()) + bcolors.ENDC
          break
      while success1 and endLine > startLine:
        if moContents[endLine-1].count("matchcontinue") == 1:
          success2 = True
          msg = "Success"
          break
        elif moContents[endLine-1].count("matchcontinue") == 0:
          startLine += 1
        else:
          msg = bcolors.WARNING + "Found 2 matchcontinue on the same line (%d): %s" (endLine,moContents[endLine-1].strip()) + bcolors.ENDC
          break
      if success2:
        moContents[startLine-1] = moContents[startLine-1].replace("matchcontinue","match")
        moContents[endLine-1] = moContents[endLine-1].replace("matchcontinue","match")
      else:
        startLine = n[0]['startLine']
        endLine = n[0]['endLine']
        if msg is None:
          msg = bcolors.WARNING + "Failed" + bcolors.ENDC
      print "%s Matchcontinue to match: %s\n%6d:  %s\n%6d:  %s" % (infoStr(n[0]),msg,startLine,moContents[startLine-1].strip(),endLine,moContents[endLine-1].strip())
  mo.close()
  mo = open(moFile, 'w')
  mo.writelines(moContents)
  mo.close()
  try:
    runOMC(stamp)
  except:
    print 'Reverting all operations after failing to compile after performing operations on %s' % stamp
    mo.writelines(moOriginalContents)
    sys.exit(1)

def runStamp(arg):
  if not arg.endswith('.stamp.mos'):
    print('Expected all arguments to have suffix .stamp.mos')
    sys.exit(1)
  f = open(arg)
  moFile = os.readlink(f.readline().split('"')[1])
  logFile = arg.replace('.stamp.mos','.log')
  fixFile(arg,logFile,moFile)

for arg in args:
  runStamp(arg)
