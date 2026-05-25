#!/usr/bin/env python3

# This file is part of OpenModelica.
#
# Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
# c/o Linköpings universitet, Department of Computer and Information Science,
# SE-58183 Linköping, Sweden.
#
# All rights reserved.
#
# THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
# THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
# ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
# RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
# VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
#
# The OpenModelica software and the OSMC (Open Source Modelica Consortium)
# Public License (OSMC-PL) are obtained from OSMC, either from the above
# address, from the URLs:
# http://www.openmodelica.org or
# https://github.com/OpenModelica/ or
# http://www.ida.liu.se/projects/OpenModelica,
# and in the OpenModelica distribution.
#
# GNU AGPL version 3 is obtained from:
# https://www.gnu.org/licenses/licenses.html#GPL
#
# This program is distributed WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
# IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
#
# See the full OSMC Public License conditions for more details.

# Fix warnings in MetaModelica code by refactoring

import argparse
import copy
import re
import sys
import os
import os.path
from pyparsing import Word, alphanums, nums, Suppress, Regex, Literal, StringEnd
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('files', nargs='*')
args = parser.parse_args().files

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
FILEINFO = (FILENAME + Suppress(":") + Word(nums) + Suppress(":") + Word(nums) + Suppress("-") + Word(nums) + Suppress(":") + Word(nums) + Suppress(Regex("[^]]*"))).set_parse_action(
  lambda s,s2: {'fileName':s2[0],'startLine':int(s2[1]),'startCol':int(s2[2]),'endLine':int(s2[3]),'endCol':int(s2[4])})
UNUSED_LOCAL = (Suppress("Notification: Unused local variable: ") + IDENT + "." + StringEnd()).set_parse_action(
  lambda s,s2: {'unused_local':s2[0]})
DEAD_STATEMENT = Literal("Notification: Dead code elimination: Statement optimised away.").set_parse_action(
  lambda s,s2: {'dead_statement':True})
UNUSED_ASSIGN = (Suppress("Notification: Removing unused assignment to: ") + IDENT + "." + StringEnd()).set_parse_action(
  lambda s,s2: {'unused_assign':s2[0]})
USE_MATCH = Literal("Notification: This matchcontinue expression has no overlapping patterns and should be using match instead of matchcontinue.").set_parse_action(
  lambda s,s2: {'mc_to_match':True})
UNUSED_AS = (Literal("Notification: Removing unused as-binding: ") + IDENT + "." + StringEnd() ).set_parse_action(
  lambda s,s2: {'unused_as':s2[1]})
EMPTY_CALL_NAMED_ARG = (Literal("Notification: Removing empty call named pattern argument: ") + IDENT + "." + StringEnd() ).set_parse_action(
  lambda s,s2: {'empty_call_named_arg':s2[1]})
ALL_EMPTY = (Literal("Notification: All patterns in call were empty: ") + IDENT + "." + StringEnd() ).set_parse_action(
  lambda s,s2: {'all_empty':s2[1]})
# Agent-fixable notifications (handled by claude-sandbox.sh, not by Python regex).
# Use Regex(as_match=True) so the parse action can pull a capture group out of the
# notification text without pyparsing having to backtrack across Suppress().
MATCH_UNUSED_INPUT = Regex(r"Notification: Match input (.+) is not used by any case and could be removed\.", as_match=True).set_parse_action(
  lambda s,t: {'match_unused_input': t[0].group(1)})
INFALLIBLE_PATTERN = Regex(r"Notification: Pattern (.+) is infallible and binds no variables; it could be replaced with a wildcard\.", as_match=True).set_parse_action(
  lambda s,t: {'infallible_pattern': t[0].group(1)})
AS_ONLY = Regex(r"Notification: Pattern only renames the match input (.+); the match expression could be rewritten without this input and the body could use \1 directly\.", as_match=True).set_parse_action(
  lambda s,t: {'as_only': t[0].group(1)})
MC_TO_TRY = Literal("Notification: This matchcontinue has a single case and an else and could be rewritten as a try/else.").set_parse_action(
  lambda s,s2: {'mc_to_try': True})
UNKNOWN = Suppress("Notification:")

NOTIFICATION = (Suppress("[") + FILEINFO + Suppress("]") + (UNUSED_LOCAL|UNUSED_AS|UNUSED_ASSIGN|DEAD_STATEMENT|USE_MATCH|EMPTY_CALL_NAMED_ARG|ALL_EMPTY|MATCH_UNUSED_INPUT|INFALLIBLE_PATTERN|AS_ONLY|MC_TO_TRY|UNKNOWN))

AGENT_KEYS = ('match_unused_input', 'infallible_pattern', 'as_only', 'mc_to_try')

COMPILER_DIR = os.path.realpath(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..'))

def runOMC(arg):
  try:
    subprocess.check_output(['../../../build/bin/omc','-d=patternmAllInfo,-listAppendWrongOrder',arg],stderr=subprocess.STDOUT)
  except subprocess.CalledProcessError as e:
    print(e.output.decode(errors='replace'), e)
    raise

def infoStr(info):
  start = info['startLine']
  end = info['endLine']
  return "%s:%s" % (info['fileName'].split("/")[-1],("%d-%d" % (start,end) if start != end else "%d" % start))

def printWarning(info,s):
  print(infoStr(info) + " " + bcolors.FAIL + s + bcolors.ENDC)
def printInfo(info,s):
  print(infoStr(info) + " " + s)

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

def gitCheckpoint():
  """Stage all current changes so that `git checkout -- <path>` restores this state."""
  subprocess.check_call(['git', 'add', '-A'], cwd=COMPILER_DIR)

def gitRevert(paths):
  """Restore the given paths from the index (= the last checkpoint)."""
  if not paths:
    return
  subprocess.call(['git', 'checkout', '--'] + list(paths), cwd=COMPILER_DIR)

def gitDirtyFiles():
  """Return the paths (relative to COMPILER_DIR) of files that differ from the index."""
  out = subprocess.check_output(['git', 'diff', '--name-only'], cwd=COMPILER_DIR).decode()
  return [p for p in out.splitlines() if p.strip()]

def relativeToCompiler(path):
  return os.path.relpath(os.path.realpath(path), COMPILER_DIR)

def runAgent(prompt):
  """Run claude-sandbox.sh in the Compiler directory with the given prompt."""
  subprocess.check_call(['claude-sandbox.sh', prompt], cwd=COMPILER_DIR)

def agentPrompt(notif, moFileRel):
  info = notif[0]
  data = notif[1] if len(notif) >= 2 else {}
  loc = "lines %d-%d (columns %d-%d)" % (info['startLine'], info['endLine'], info['startCol'], info['endCol'])
  header = "In `%s` at %s:\n\n" % (moFileRel, loc)
  footer = ("\n\nMake the change directly to the file. Do not commit. "
            "Only modify code at the indicated location, plus any directly required follow-up "
            "(e.g. updating all cases of the same match expression). "
            "Preserve formatting and indentation. Do not touch unrelated functions or files.")
  if 'match_unused_input' in data:
    ident = data['match_unused_input'].strip('`')
    body = (
      "The match expression that spans these lines has an input `%s` that is not used "
      "by any case (every case has a wildcard `_` at that position). Refactor the match "
      "expression so the input is removed from the input tuple, and the matching wildcard "
      "position is removed from every case's pattern. The result type and arity of the "
      "match must remain unchanged." % ident)
  elif 'infallible_pattern' in data:
    pat = data['infallible_pattern']
    body = (
      "The pattern `%s` at this location is infallible and binds no variables. "
      "Replace just that pattern with a wildcard `_`. Do not touch any other case." % pat)
  elif 'as_only' in data:
    ident = data['as_only'].strip('`')
    body = (
      "The match expression that spans these lines has an input `%s` whose every case "
      "either uses `_` or only renames the value via an as-binding (e.g. `name as _`). "
      "Refactor: remove `%s` from the input tuple, drop the corresponding pattern position "
      "in each case, and in each case body replace uses of the renamed local name with `%s`." %
      (ident, ident, ident))
  elif 'mc_to_try' in data:
    body = (
      "This matchcontinue has exactly one case and an else. Rewrite it as a try/else.\n\n"
      "Example:\n"
      "  n := matchcontinue x\n"
      "    case a::_ then a;\n"
      "    else 3;\n"
      "  end matchcontinue;\n"
      "becomes:\n"
      "  try\n"
      "    n::_ := x;\n"
      "  else\n"
      "    n := 3;\n"
      "  end try;\n\n"
      "Preserve any local declarations and the result variable. The pattern from the case "
      "becomes the LHS of a destructuring assignment; the case result becomes the RHS.")
  else:
    return None
  return header + body + footer

def processAgentFixes(stamp, moFile, logFile):
  """For each agent-fixable notification in logFile, invoke the agent, then verify.
  On failure, revert the touched files from the git index."""
  try:
    with open(logFile, 'r') as log:
      allLines = log.readlines()
  except OSError:
    return
  notifs = []
  for line in allLines:
    try:
      n = NOTIFICATION.parse_string(line.strip())
    except Exception:
      continue
    if len(n) >= 2 and any(k in n[1] for k in AGENT_KEYS):
      notifs.append(n)
  notifs = [n for n in notifs if n[0]['fileName'] == moFile]
  # Process bottom-up so earlier line numbers stay valid across edits within one batch.
  notifs.sort(key=lambda n: (n[0]['startLine'], n[0]['startCol']), reverse=True)
  moFileRel = relativeToCompiler(moFile)
  for n in notifs:
    prompt = agentPrompt(n, moFileRel)
    if prompt is None:
      continue
    info = n[0]
    print("%s Running agent for: %s" % (infoStr(info), list(n[1].keys())[0]))
    try:
      gitCheckpoint()
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
      print("git checkpoint failed (%s); aborting agent fixes." % e)
      return
    try:
      runAgent(prompt)
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
      print("Agent invocation failed (%s); skipping." % e)
      continue
    dirty = gitDirtyFiles()
    if not dirty:
      print("%s Agent made no changes." % infoStr(info))
      continue
    try:
      runOMC(stamp)
      print("%s Agent fix verified. Touched: %s" % (infoStr(info), dirty))
    except Exception:
      print("%s Agent fix broke the build; reverting %s" % (infoStr(info), dirty))
      gitRevert(dirty)

def fixFileIter(stamp,moFile,logFile):
  with open(moFile, 'r') as mo:
    moContents = mo.readlines()
  moOriginalContents = copy.deepcopy(moContents)
  iterate = False
  try:
    with open(logFile, 'r') as log:
      allLines = log.readlines()
  except OSError:
    return # It's ok; there were no messages
  for line in allLines:
    try:
      NOTIFICATION.parse_string(line.strip())
    except Exception:
      print("Notification failed for", line)
  lst = [NOTIFICATION.parse_string(line.strip()) for line in allLines]
  lst = [n for n in lst if n[0]['fileName'] == moFile]
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
    if len(n)==2 and 'unused_local' in n[1]:
      # Skip these. Some optimizations make declarations seem unused but the source code still uses them
      continue
      ident = n[1]['unused_local']
      endCol += 2
      s = getContents(moContents,startLine,endLine,startCol,endCol)
      if not s.endswith(";\n"):
        printWarning(info,'%s does not look like an element declaration' % (ident,lineContentsOfInfo.strip()))
        continue
      c = getIdents(s).count(ident)
      if c!=1:
        printWarning(info,'Tried to remove unused local element %s from %s, but the element occurs %d times rather than 1' % (ident,lineContentsOfInfo.strip(),c))
        continue
      if re.search(',%s' % ident, s):
        updated = re.sub(',%s' % ident,'',s)
        updateContents(moContents,startLine,endLine,startCol,endCol,updated)
        printInfo(info, 'Removed unused local element %s in %s' % (ident,s.strip()))
        maxLine = startLine
        continue
      print(s)
    elif len(n)==2 and 'all_empty' in n[1]:
      ident = n[1]['all_empty']
      split = re.split("%s[(][ _,]*[)]" % ident, lineContentsOfInfo, maxsplit=1)
      if len(split) != 2:
        printWarning(info,'Failed to find pattern call to %s with only wild patterns in %s' % (ident,lineContentsOfInfo.strip()))
        continue
      updated = split[0] + ident + "()" + split[1]
      updateContents(moContents,startLine,endLine,startCol,endCol,updated)
      printInfo(info, 'Removed pattern call to %s with only wild argument in %s with replacement %s' % (ident,lineContentsOfInfo.strip(),updated))
      maxLine = startLine
    elif len(n)==2 and 'empty_call_named_arg' in n[1]:
      ident = n[1]['empty_call_named_arg']
      split = re.split(", *%s *= *_" % ident, lineContentsOfInfo, maxsplit=1)
      if len(split) != 2:
        split = re.split("%s *= *_ *, *" % ident, lineContentsOfInfo, maxsplit=1)
      if len(split) != 2:
        split = re.split("[(] *%s *= *_ *[)]" % ident, lineContentsOfInfo, maxsplit=1)
        if len(split) == 2:
          split[0] += "("
          split[1] = ")" + split[1]
      if len(split) != 2:
        printWarning(info,'Failed to find empty named arg %s in %s' % (ident,lineContentsOfInfo.strip()))
        continue
      updated = "".join(split)
      updateContents(moContents,startLine,endLine,startCol,endCol,updated)
      printInfo(info, 'Removed empty named arg %s in %s with %s' % (ident,lineContentsOfInfo.strip(),updated))
      maxLine = startLine
    elif len(n)==2 and 'unused_assign' in n[1]:
      ident = n[1]['unused_assign']
      split = re.split("(^|[(,]) *%s *([,)=]|:=)" % ident, lineContentsOfInfo, maxsplit=1)
      if len(split) != 4:
        printWarning(info,'Failed to find assignment to %s in %s' % (ident,lineContentsOfInfo.strip()))
        continue
      updated = split[0]+split[1]+('_ ' if re.match('[:]?=',split[2]) else '_')+split[2]+split[3]
      updateContents(moContents,startLine,endLine,startCol,endCol,updated)
      printInfo(info, 'Replaced dead assign %s in %s with %s' % (ident,lineContentsOfInfo.strip(),updated))
      maxLine = startLine
    elif len(n)==2 and 'unused_as' in n[1]:
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
      if c != 1:
        if not iterate: printWarning(info,"Trying to remove identifier %s as-pattern from %s, but the identifier has count %d" % (ident,s.strip(),c))
        continue
      # First replace the (only) identifier possible with _
      # Then if we get "_ as ", remove that too
      # Take care if another identifier ends with _, e.g. "model_ as ..."
      updated = re.sub("([^a-zA-Z0-9_]|^)_ +as( +|\n|$)","\\1",re.sub("([^a-zA-Z0-9_]|^)%s([^a-zA-Z0-9_]|$)" % ident,"\\1_\\2",s))
      updateContents(moContents,startLine,endLine,startCol,endCol,updated)
      maxLine = startLine
      printInfo(info,"Removed dead as-binding %s in %s" % (ident,updated))
    elif len(n)==2 and 'dead_statement' in n[1]:
      if startLine != endLine:
        printWarning(info,'Dead statement spanning multiple rows')
        continue
      sOrig = moContents[startLine-1]
      s = (sOrig[:startCol-1] + sOrig[endCol:]).strip()
      if s != "":
        if not iterate: printWarning(info,"After removing statement '%s' remains" % s)
        continue
      del moContents[startLine-1]
      maxLine = startLine
      printInfo(info,"Removed dead statement %s" % sOrig.strip())
    elif len(n)==2 and 'mc_to_match' in n[1]:
      success1 = False
      success2 = False
      while startLine < endLine:
        if moContents[startLine-1].count("matchcontinue") == 1:
          success1 = True
          break
        elif moContents[startLine-1].count("matchcontinue") == 0:
          startLine += 1
        else:
          msg = bcolors.FAIL + "Found 2 matchcontinue on the same line (%d): %s" % (startLine,moContents[startLine-1].strip()) + bcolors.ENDC
          break
      while success1 and endLine > startLine:
        if moContents[endLine-1].count("matchcontinue") == 1:
          success2 = True
          msg = "Success"
          break
        elif moContents[endLine-1].count("matchcontinue") == 0:
          startLine += 1
        else:
          msg = bcolors.FAIL + "Found 2 matchcontinue on the same line (%d): %s" % (endLine,moContents[endLine-1].strip()) + bcolors.ENDC
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
      print("%s Matchcontinue to match: %s\n%6d:  %s\n%6d:  %s" % (infoStr(info),msg,startLine,moContents[startLine-1].strip(),endLine,moContents[endLine-1].strip()))
  with open(moFile, 'w') as mo:
    mo.writelines(moContents)
  try:
    runOMC(stamp)
  except Exception:
    badFile = moFile + ".err"
    print('Reverting all operations after failing to compile after performing operations on %s. The bad file is stored as: %s' % (stamp,badFile))
    os.rename(moFile, badFile)
    with open(moFile, 'w') as mo:
      mo.writelines(moOriginalContents)
    sys.exit(1)
  return iterate

def fixFile(stamp,logFile,moFile):
  runOMC(stamp)
  iterate = fixFileIter(stamp,moFile,logFile)
  while iterate:
    print("Iterating %s" % stamp)
    iterate = fixFileIter(stamp,moFile,logFile)
  # After all Python-driven fixes settle, hand the remaining notifications to the agent.
  # logFile reflects the latest runOMC inside fixFileIter, so it is current.
  processAgentFixes(stamp, moFile, logFile)
  return iterate

def runStamp(arg):
  if not arg.endswith('.stamp.mos'):
    print('Expected all arguments to have suffix .stamp.mos')
    sys.exit(1)
  with open(arg) as f:
    moFile = os.path.realpath(f.readline().split('"')[1])
  logFile = arg.replace('.stamp.mos','.log')
  if os.path.exists(moFile.replace('.mo','.tpl')):
    print('Skipping Susan-generated file %s' % arg)
    return
  fixFile(arg,logFile,moFile)

for arg in args:
  try:
    runStamp(arg)
  except Exception:
    print("Failed for", arg)
    raise
