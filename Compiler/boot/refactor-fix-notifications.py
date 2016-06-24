#!/usr/bin/env python
# Fix warnings in MetaModelica code by refactoring

import copy
import re
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

IDENT = Word(alphanums + "_")
FILENAME = Regex("[^:]*")
FILEINFO = (FILENAME + Suppress(":") + Word(nums) + Suppress(":") + Word(nums) + Suppress("-") + Word(nums) + Suppress(":") + Word(nums) + Suppress(Regex("[^]]*"))).setParseAction(
  lambda s,s2: {'fileName':s2[0],'startLine':int(s2[1]),'startCol':int(s2[2]),'endLine':int(s2[3]),'endCol':int(s2[4])})
UNUSED_LOCAL = (Suppress("Notification: Unused local variable: ") + IDENT + "." + StringEnd()).setParseAction(
  lambda s,s2: {'unused_local':s2[0]})
DEAD_STATEMENT = Literal("Notification: Dead code elimination: Statement optimised away.").setParseAction(
  lambda s,s2: {'dead_statement':True})
UNUSED_ASSIGN = (Suppress("Notification: Removing unused assignment to: ") + IDENT + "." + StringEnd()).setParseAction(
  lambda s,s2: {'unused_assign':s2[0]})
USE_MATCH = Literal("Notification: This matchcontinue expression has no overlapping patterns and should be using match instead of matchcontinue.").setParseAction(
  lambda s,s2: {'mc_to_match':True})
UNUSED_AS = (Literal("Notification: Removing unused as-binding: ") + IDENT + "." + StringEnd() ).setParseAction(
  lambda s,s2: {'unused_as':s2[1]})
EMPTY_CALL_NAMED_ARG = (Literal("Notification: Removing empty call named pattern argument: ") + IDENT + "." + StringEnd() ).setParseAction(
  lambda s,s2: {'empty_call_named_arg':s2[1]})
ALL_EMPTY = (Literal("Notification: All patterns in call were empty: ") + IDENT + "." + StringEnd() ).setParseAction(
  lambda s,s2: {'all_empty':s2[1]})
UNKNOWN = Suppress("Notification:")

NOTIFICATION = (Suppress("[") + FILEINFO + Suppress("]") + (UNUSED_LOCAL|UNUSED_AS|UNUSED_ASSIGN|DEAD_STATEMENT|USE_MATCH|EMPTY_CALL_NAMED_ARG|ALL_EMPTY|UNKNOWN))

def runOMC(arg):
  try:
    res = subprocess.check_output(['../../../build/bin/omc','-d=patternmAllInfo,-listAppendWrongOrder',arg],stderr=subprocess.STDOUT)
  except subprocess.CalledProcessError as e:
    print e.output,e
    raise

def infoStr(info):
  start = info['startLine']
  end = info['endLine']
  return "%s:%s" % (info['fileName'].split("/")[-1],("%d-%d" % (start,end) if start<>end else "%d" % start))

def printWarning(info,s):
  print infoStr(info) + " " + bcolors.FAIL + s + bcolors.ENDC
def printInfo(info,s):
  print infoStr(info) + " " + s

def getContents(moContents,startLine,endLine,startCol,endCol):
  if startLine == endLine:
    return moContents[startLine-1][startCol-1:endCol-1]
  first = moContents[startLine-1][startCol-1:]
  last = moContents[endLine-1][:endCol-1]
  return first + "".join(moContents[startLine:endLine-1]) + last

def getIdents(s):
  return re.split(r'[^0-9A-Za-z_]+',s)

def updateContents(moContents,startLine,endLine,startCol,endCol,s):
  if startLine == endLine:
    orig = moContents[startLine-1]
    moContents[startLine-1] = orig[:startCol-1] + s + orig[endCol-1:]
    return moContents
  begin = moContents[startLine-1][:startCol-1]
  end = moContents[endLine-1][endCol-1:]
  line = begin + s + end
  del moContents[startLine:endLine] # Does not delete startLine-1, which is the one we will abuse
  moContents[startLine-1] = line

def fixFileIter(stamp,moFile,logFile):
  mo = open(moFile, 'r')
  moContents = mo.readlines()
  mo.close()
  moOriginalContents = copy.deepcopy(moContents)
  iterate = False
  try:
    log = open(logFile, 'r')
  except:
    return # It's ok; there were no messages
  allLines = log.readlines()
  for l in allLines:
    try:
      NOTIFICATION.parseString(l.strip())
    except:
      print("Notification failed for",l)
  lst = [NOTIFICATION.parseString(line.strip()) for line in allLines]
  len1 = len(lst)
  lst = [n for n in lst if n[0]['fileName'] == moFile]
  len2 = len(lst)
  lst.sort(key=lambda n: "%s%07d" % (n[0]['fileName'],n[0]['endLine']),reverse=True)
  maxLine = sys.maxsize

  for n in lst:
    info = n[0]
    startLine = info['startLine']
    endLine = info['endLine']
    startCol = info['startCol']
    endCol = info['endCol']
    lineContentsOfInfo = getContents(moContents,startLine,endLine,startCol,endCol)
    if startLine >= maxLine:
      iterate = True
      continue
    msg = None
    if len(n)==2 and n[1].has_key('unused_local'):
      # Skip these. Some optimizations make declarations seem unused but the source code still uses them
      continue
      ident = n[1]['unused_local']
      endCol += 2
      s = getContents(moContents,startLine,endLine,startCol,endCol)
      if not s.endswith(";\n"):
        printWarning(info,'%s does not look like an element declaration' % (ident,lineContentsOfInfo.strip()))
        continue
      c = getIdents(s).count(ident)
      if c<>1:
        printWarning(info,'Tried to remove unused local element %s from %s, but the element occurs %d times rather than 1' % (ident,lineContentsOfInfo.strip(),c))
        continue
      if re.search(',%s' % ident, s):
        updated = re.sub(',%s' % ident,'',s)
        updateContents(moContents,startLine,endLine,startCol,endCol,updated)
        printInfo(info, 'Removed unused local element %s in %s' % (ident,s.strip()))
        maxLine = startLine
        continue
      print s
    elif len(n)==2 and n[1].has_key('all_empty'):
      ident = n[1]['all_empty']
      split = re.split("%s[(][ _,]*[)]" % ident, lineContentsOfInfo, maxsplit=1)
      if len(split) <> 2:
        printWarning(info,'Failed to find pattern call to %s with only wild patterns in %s' % (ident,lineContentsOfInfo.strip()))
        continue
      updated = split[0] + ident + "()" + split[1]
      updateContents(moContents,startLine,endLine,startCol,endCol,updated)
      printInfo(info, 'Removed pattern call to %s with only wild argument in %s with replacement %s' % (ident,lineContentsOfInfo.strip(),updated))
      maxLine = startLine
    elif len(n)==2 and n[1].has_key('empty_call_named_arg'):
      ident = n[1]['empty_call_named_arg']
      split = re.split(", *%s *= *_" % ident, lineContentsOfInfo, maxsplit=1)
      if len(split) <> 2:
        split = re.split("%s *= *_ *, *" % ident, lineContentsOfInfo, maxsplit=1)
      if len(split) <> 2:
        split = re.split("[(] *%s *= *_ *[)]" % ident, lineContentsOfInfo, maxsplit=1)
        if len(split) == 2:
          split[0] += "("
          split[1] = ")" + split[1]
      if len(split) <> 2:
        printWarning(info,'Failed to find empty named arg %s in %s' % (ident,lineContentsOfInfo.strip()))
        continue
      updated = "".join(split)
      updateContents(moContents,startLine,endLine,startCol,endCol,updated)
      printInfo(info, 'Removed empty named arg %s in %s with %s' % (ident,lineContentsOfInfo.strip(),updated))
      maxLine = startLine
    elif len(n)==2 and n[1].has_key('unused_assign'):
      ident = n[1]['unused_assign']
      split = re.split("(^|[(,]) *%s *([,)=]|:=)" % ident, lineContentsOfInfo, maxsplit=1)
      if len(split) <> 4:
        printWarning(info,'Failed to find assignment to %s in %s' % (ident,lineContentsOfInfo.strip()))
        continue
      updated = split[0]+split[1]+('_ ' if re.match('[:]?=',split[2]) else '_')+split[2]+split[3]
      updateContents(moContents,startLine,endLine,startCol,endCol,updated)
      printInfo(info, 'Replaced dead assign %s in %s with %s' % (ident,lineContentsOfInfo.strip(),updated))
      maxLine = startLine
    elif len(n)==2 and n[1].has_key('unused_as'):
      ident = n[1]['unused_as']
      s = lineContentsOfInfo
      c = getIdents(s).count(ident)
      reSameEqComma = "%s *= *%s *," % (ident,ident)
      reSameEqParens = ", *%s *= *%s *[)]" % (ident,ident)
      reSameEqBothParens = "[(] *%s *= *%s *[)]" % (ident,ident)
      reSameEqAs = "%s *= *%s *as *" % (ident,ident)
      done = False
      for (regex,replace) in [(reSameEqComma,""),(reSameEqParens,")"),(reSameEqBothParens,"(%s=_)" % ident),(reSameEqAs,"%s=" % ident)]:
        if c == 2 and re.search(regex,s):
          updated = re.sub(regex,replace,s)
          printInfo(info,"Removed dead as-binding %s=%s in %s" % (ident,ident,updated.strip()))
          updateContents(moContents,startLine,endLine,startCol,endCol,updated)
          maxLine = startLine
          done = True
          break
      if done:
        continue
      if c <> 1:
        if not iterate: printWarning(info,"Trying to remove identifier %s as-pattern from %s, but the identifier has count %d" % (ident,s.strip(),c))
        continue
      # First replace the (only) identifier possible with _
      # Then if we get "_ as ", remove that too
      # Take care if another identifier ends with _, e.g. "model_ as ..."
      updated = re.sub("([^a-zA-Z0-9_]|^)_ +as( +|\n|$)","\\1",re.sub("([^a-zA-Z0-9_]|^)%s([^a-zA-Z0-9_]|$)" % ident,"\\1_\\2",s))
      updateContents(moContents,startLine,endLine,startCol,endCol,updated)
      maxLine = startLine
      printInfo(info,"Removed dead as-binding %s in %s" % (ident,updated))
    elif len(n)==2 and n[1].has_key('dead_statement'):
      if startLine <> endLine:
        printWarning(info,'Dead statement spanning multiple rows')
        continue
      sOrig = moContents[startLine-1]
      s = (sOrig[:startCol-1] + sOrig[endCol:]).strip()
      if s <> "":
        if not iterate: printWarning(info,"After removing statement '%s' remains" % s)
        continue
      del moContents[startLine-1]
      maxLine = startLine
      printInfo(info,"Removed dead statement %s" % sOrig.strip())
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
          msg = bcolors.FAIL + "Found 2 matchcontinue on the same line (%d): %s" (startLine,moContents[startLine-1].strip()) + bcolors.ENDC
          break
      while success1 and endLine > startLine:
        if moContents[endLine-1].count("matchcontinue") == 1:
          success2 = True
          msg = "Success"
          break
        elif moContents[endLine-1].count("matchcontinue") == 0:
          startLine += 1
        else:
          msg = bcolors.FAIL + "Found 2 matchcontinue on the same line (%d): %s" (endLine,moContents[endLine-1].strip()) + bcolors.ENDC
          break
      if success2:
        moContents[startLine-1] = moContents[startLine-1].replace("matchcontinue","match")
        moContents[endLine-1] = moContents[endLine-1].replace("matchcontinue","match")
        maxLine = startLine
      else:
        startLine = info['startLine']
        endLine = info['endLine']
        if msg is None:
          msg = bcolors.FAIL + "Failed" + bcolors.ENDC
      print "%s Matchcontinue to match: %s\n%6d:  %s\n%6d:  %s" % (infoStr(info),msg,startLine,moContents[startLine-1].strip(),endLine,moContents[endLine-1].strip())
  mo = open(moFile, 'w')
  mo.writelines(moContents)
  mo.close()
  try:
    runOMC(stamp)
  except:
    badFile = moFile + ".err"
    print 'Reverting all operations after failing to compile after performing operations on %s. The bad file is stored as: %s' % (stamp,badFile)
    os.rename(moFile, badFile)
    mo = open(moFile, 'w')
    mo.writelines(moOriginalContents)
    mo.close()
    sys.exit(1)
  return iterate

def fixFile(stamp,logFile,moFile):
  runOMC(arg)
  iterate = fixFileIter(stamp,moFile,logFile)
  while iterate:
    print "Iterating %s" % stamp
    iterate = fixFileIter(stamp,moFile,logFile)
  return iterate

def runStamp(arg):
  if not arg.endswith('.stamp.mos'):
    print('Expected all arguments to have suffix .stamp.mos')
    sys.exit(1)
  f = open(arg)
  moFile = os.path.realpath(f.readline().split('"')[1])
  logFile = arg.replace('.stamp.mos','.log')
  if os.path.exists(moFile.replace('.mo','.tpl')):
    print 'Skipping Susan-generated file %s' % arg
    return
  fixFile(arg,logFile,moFile)

for arg in args:
  try:
    runStamp(arg)
  except:
    print("Failed for",arg)
    raise
