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
MATCH_SINGLE_INFALLIBLE = Literal("Notification: This match expression has a single case with an infallible pattern; it could be rewritten as a destructuring assignment of the input(s).").set_parse_action(
  lambda s,s2: {'match_single_infallible': True})
UNKNOWN = Suppress("Notification:")

NOTIFICATION = (Suppress("[") + FILEINFO + Suppress("]") + (UNUSED_LOCAL|UNUSED_AS|UNUSED_ASSIGN|DEAD_STATEMENT|USE_MATCH|EMPTY_CALL_NAMED_ARG|ALL_EMPTY|MATCH_UNUSED_INPUT|INFALLIBLE_PATTERN|AS_ONLY|MC_TO_TRY|MATCH_SINGLE_INFALLIBLE|UNKNOWN))

AGENT_KEYS = ('match_unused_input', 'infallible_pattern', 'as_only', 'mc_to_try', 'match_single_infallible')

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

def gitInitialCheckpoint():
  """Capture the initial state of TRACKED, modified files into the index. We do
  NOT use `git add -A` because that would also stage every untracked file in the
  tree (debug scripts, generated dumps, etc.), which the user did not ask to
  commit. Untracked files are left alone; subsequent agent fixes are only
  responsible for files they actually modify."""
  subprocess.check_call(['git', 'add', '-u'], cwd=COMPILER_DIR)

def gitStage(paths):
  """Stage the specific paths that the agent just produced and that compiled.
  Only these `deemed working' files are added to the index; everything else
  stays in whatever state the user left it in."""
  if not paths:
    return
  subprocess.check_call(['git', 'add', '--'] + list(paths), cwd=COMPILER_DIR)

def gitRevert(paths):
  """Restore the given paths from the index (= the last verified state)."""
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

META_MODELICA_PRIMER = """\
Quick MetaModelica primer (the dialect used in this file):

* `match` and `matchcontinue` are EXPRESSIONS that pattern-match a value (or
  a tuple of values) against one or more `case` clauses.
  - `match` requires that the first case whose patterns syntactically match
    must also succeed at runtime; if its body fails (e.g. a `fail()` call,
    a failed nested pattern match, or a failed `:=` assignment), the whole
    match fails — it does NOT try the next case.
  - `matchcontinue` does try the next case on runtime failure. This is
    strictly slower because it captures and restores state, so it should
    only be used when later cases are intended to be tried after an earlier
    case's body fails.
* A case looks like:
      case <pattern> [guard <expr>] [equation ...] [algorithm ...] then <expr>;
  The `then <expr>;` part is the value the match expression evaluates to
  when this case is selected. The optional `equation`/`algorithm` sections
  are local bindings/statements used only inside this case.
* Multiple inputs are matched as a tuple: `match (a, b, c) case (1, _, 3) ...`.
* `_` is a wildcard pattern; `id as <pattern>` binds the matched value to
  `id` in addition to recursing into `<pattern>`; the shorthand `id` is
  equivalent to `id as _` only when the type is unambiguous.
* `try ... else ... end try;` is a STATEMENT (not an expression) that runs
  the `try` block and falls through to the `else` block on runtime failure.
  Unlike `matchcontinue`, it does not destructure a value; you write any
  failable statements (typically a destructuring `:=` assignment) inside it.
* `end match;` / `end matchcontinue;` / `end try;` are required closing
  tokens — do not forget them.
"""

def agentPrompt(notif, moFileRel):
  info = notif[0]
  data = notif[1] if len(notif) >= 2 else {}
  loc = "lines %d-%d (columns %d-%d)" % (info['startLine'], info['endLine'], info['startCol'], info['endCol'])
  header = ("You are editing the MetaModelica file `%s`.\n"
            "The compiler emitted a refactoring notification at %s.\n\n"
            "%s\n" % (moFileRel, loc, META_MODELICA_PRIMER))
  footer = ("\n\nProcedure:\n"
            "1. Read the relevant region of `%s` (use the line numbers above plus a few\n"
            "   lines of context above and below) to see the full match expression.\n"
            "2. Make ONE focused edit that performs the refactor described below.\n"
            "3. Do not touch any other function, file, or unrelated piece of code.\n"
            "4. Do not commit. Do not run the compiler or tests.\n"
            "5. Preserve the surrounding indentation, comments, and blank lines.\n"
            "6. If, after reading the actual code, the described refactor is not\n"
            "   applicable (e.g. the pattern variable IS used in a way the notification\n"
            "   missed, the input has side effects, or the structure is different from\n"
            "   what the notification implies), leave the file unchanged and stop.\n"
            % moFileRel)
  if 'match_unused_input' in data:
    ident = data['match_unused_input'].strip('`')
    body = (
      "Refactor: drop an unused input from a match expression.\n\n"
      "Notification: input `%s` of this match expression is wildcard (`_`) in every\n"
      "case, so the expression `%s` is computed but its value is never inspected.\n\n"
      "What to change:\n"
      "  - In the input tuple of the match expression (between `match` and the first\n"
      "    `case`), delete the occurrence of `%s` and the comma that separates it from\n"
      "    its neighbour. If `%s` is the only remaining input, the surrounding\n"
      "    parentheses around the input tuple should also go (so it becomes\n"
      "    `match <singleInput>` rather than `match (<singleInput>)`).\n"
      "  - In every case (including any `else` case if it uses tuple patterns), delete\n"
      "    the `_` at the SAME positional index from the case's pattern tuple, plus the\n"
      "    adjacent comma. Keep all other pattern positions in place.\n"
      "  - The number of pattern positions per case after the edit must equal the\n"
      "    number of inputs after the edit.\n\n"
      "Worked example. Before:\n"
      "    y := match (a, b, c)\n"
      "      case (1, _, 3) then 10;\n"
      "      case (4, _, 6) then 20;\n"
      "      else 0;\n"
      "    end match;\n"
      "After (dropping input `b`):\n"
      "    y := match (a, c)\n"
      "      case (1, 3) then 10;\n"
      "      case (4, 6) then 20;\n"
      "      else 0;\n"
      "    end match;\n\n"
      "Edge cases to handle:\n"
      "  - An `else` case has no pattern tuple in source, so leave it alone.\n"
      "  - Cases may have a `guard <expr>`, `equation`, or `algorithm` section between\n"
      "    the pattern and `then` — only modify the pattern tuple, not those parts.\n"
      "  - If `%s` appears as a free expression inside any case body, it is still in\n"
      "    scope (it is a parameter/local of the enclosing function), so the body does\n"
      "    NOT need to change.\n" %
      (ident, ident, ident, ident, ident))
  elif 'infallible_pattern' in data:
    pat = data['infallible_pattern']
    body = (
      "Refactor: replace an infallible no-binding pattern with a wildcard.\n\n"
      "Notification: the pattern `%s` is guaranteed to match at runtime (no test can\n"
      "fail) and binds no variable. It is equivalent to plain `_`, but more verbose\n"
      "and harder to read.\n\n"
      "What to change:\n"
      "  - Locate the pattern `%s` inside the case at the indicated line range. It\n"
      "    is either a tuple pattern containing only `_` (like `(_, _, _)`), a record\n"
      "    constructor pattern of a uniontype with a single record (`SOMENAME(_, _)`),\n"
      "    or a named-args pattern with no arguments (`SOMENAME()`).\n"
      "  - Replace just that pattern with `_`. Do not change anything else in the case.\n\n"
      "Worked example. Before:\n"
      "    case SINGLE(_, _) then 1;\n"
      "After:\n"
      "    case _ then 1;\n\n"
      "If the pattern appears nested inside a larger pattern (e.g. as one element of a\n"
      "tuple or as an argument to another constructor), still replace just that\n"
      "occurrence with `_`, e.g. `(1, SINGLE(_, _))` -> `(1, _)`.\n" %
      (pat, pat))
  elif 'as_only' in data:
    ident = data['as_only'].strip('`')
    body = (
      "Refactor: drop an input that is only renamed by the cases.\n\n"
      "Notification: input `%s` of this match expression is, in every case, either a\n"
      "plain wildcard `_` or only used to rename the value (e.g. `name as _`, or the\n"
      "shorthand `name` when the type is unambiguous). No case actually inspects the\n"
      "value, so the input is being dragged through the match for no reason.\n\n"
      "What to change:\n"
      "  - In the input tuple of the match expression (between `match`/`matchcontinue`\n"
      "    and the first `case`), delete `%s` and its surrounding comma. If it was the\n"
      "    only remaining input, drop the parentheses too.\n"
      "  - In every case, find the pattern at the SAME positional index as `%s` was.\n"
      "    It will be `_`, `someName`, or `someName as _`. Remove that whole pattern\n"
      "    position (and its adjacent comma) from the case's pattern tuple.\n"
      "  - For each case where the pattern was a binding (e.g. `someName as _` or just\n"
      "    `someName`), find every reference to that bound name in the case's body /\n"
      "    `then` expression / `guard` / `equation` / `algorithm` section and replace\n"
      "    it with `%s`. Be careful to do textual identifier-boundary matching (do not\n"
      "    replace inside other identifiers like `someName2` or `xsomeName`).\n"
      "  - The number of pattern positions per case after the edit must equal the\n"
      "    number of inputs after the edit.\n\n"
      "Worked example. Before:\n"
      "    y := match (a, b, c)\n"
      "      case (1, x, 3) then x + 1;\n"
      "      case (4, y, 6) then y * 2;\n"
      "      else 0;\n"
      "    end match;\n"
      "After (dropping input `b`, body uses `b` directly):\n"
      "    y := match (a, c)\n"
      "      case (1, 3) then b + 1;\n"
      "      case (4, 6) then b * 2;\n"
      "      else 0;\n"
      "    end match;\n\n"
      "If any case binds a name that is ALSO declared as a local in the enclosing\n"
      "function with a different meaning, leave the file unchanged and stop — the\n"
      "rewrite would be unsafe.\n" %
      (ident, ident, ident, ident))
  elif 'match_single_infallible' in data:
    body = (
      "Refactor: a `match` expression with exactly one case and an infallible\n"
      "pattern is being used purely to destructure (or just to wrap) a value.\n"
      "Rewrite it without the match — that is clearer and avoids the runtime\n"
      "cost of building a match expression.\n\n"
      "What to change. Pick the simpler form that preserves semantics:\n\n"
      "(A) The pattern binds nothing (it is `_`, a tuple of `_`s, or an\n"
      "    infallible record pattern with no bound variables).\n"
      "    - If the surrounding context is `<lhs> := match <inputExpr> case <pat>\n"
      "      then <expr>; end match;`, replace the whole thing with\n"
      "      `<lhs> := <expr>;`.\n"
      "    - If <inputExpr> may have side effects (a function call, etc.), keep\n"
      "      its evaluation by prepending `_ := <inputExpr>;` before the\n"
      "      assignment. If <inputExpr> is a plain variable reference, no such\n"
      "      prefix is needed.\n"
      "    - For multiple inputs `match (a, b) case (_, _) then ...`, treat\n"
      "      each input the same way.\n\n"
      "    Worked example. Before:\n"
      "        y := match x case _ then 5; end match;\n"
      "    After (x is a plain variable):\n"
      "        y := 5;\n\n"
      "(B) The pattern binds one or more variables (it is `id as <subpat>`, a\n"
      "    tuple containing as-bindings, a record pattern with named-field\n"
      "    bindings, etc.).\n"
      "    - Rewrite the match as a destructuring assignment whose LHS is the\n"
      "      pattern and whose RHS is the input expression, followed by the\n"
      "      original case body assignment.\n"
      "    - If the case's `then <expr>` is exactly one of the bound names and\n"
      "      no other work is done in the case, you can collapse the two\n"
      "      assignments into one — e.g. bind the destructured value directly\n"
      "      to <lhs>.\n\n"
      "    Worked example 1 (collapsible). Before:\n"
      "        classes := match inProgram\n"
      "          case p as Absyn.PROGRAM() then p.classes;\n"
      "        end match;\n"
      "    After:\n"
      "        Absyn.PROGRAM(classes=classes) := inProgram;\n\n"
      "    Worked example 2 (not collapsible). Before:\n"
      "        n := match lst\n"
      "          case a::rest then a + List.length(rest);\n"
      "        end match;\n"
      "    After:\n"
      "        a::rest := lst;\n"
      "        n := a + List.length(rest);\n"
      "    (If `a` and `rest` are not already declared as locals of the\n"
      "    enclosing function, add them to the `protected`/`local` section.)\n\n"
      "Edge cases to handle:\n"
      "  - The case may have a `guard` — if so, leave the file unchanged; a\n"
      "    guard means the match CAN fail at runtime even when the pattern is\n"
      "    structurally infallible, so this rewrite would change semantics.\n"
      "  - The case may have an `equation` or `algorithm` section before\n"
      "    `then`. Those statements must move out as well, in the same order,\n"
      "    after the destructuring assignment and before the final result\n"
      "    assignment.\n"
      "  - If the function has no `protected`/`local` declarations for the\n"
      "    pattern's bound names, add them. Use the types visible from the\n"
      "    uniontype/record fields.\n"
      "  - If the rewrite turns out to require restructuring that you are not\n"
      "    confident is semantics-preserving, leave the file unchanged.\n")
  elif 'mc_to_try' in data:
    body = (
      "Refactor: rewrite a one-case-plus-else `matchcontinue` as `try ... else ... end try;`.\n\n"
      "Notification: this `matchcontinue` has exactly one real case and an `else`.\n"
      "It is therefore being used as an exception handler, not as multi-way dispatch.\n"
      "`try ... else ... end try;` expresses that intent directly and avoids the\n"
      "overhead of `matchcontinue`.\n\n"
      "Important — `try`/`else` is a STATEMENT, not an expression:\n"
      "  - `matchcontinue` returns a value; the surrounding code looks like\n"
      "      <lhs> := matchcontinue <inputExpr> case <pat> then <expr>; else <expr2>; end matchcontinue;\n"
      "  - `try` does not return a value; you must assign to <lhs> inside both branches.\n"
      "    So the rewrite turns one assignment of a match expression into a `try`\n"
      "    statement that contains two assignments (one in `try`, one in `else`).\n\n"
      "What to change:\n"
      "  - Identify <lhs> (everything to the left of `:=`), <inputExpr> (the value\n"
      "    after `matchcontinue`), <pat> (the case's pattern), <expr> (the case's\n"
      "    `then` value), and <expr2> (the else's `then` value).\n"
      "  - Replace the whole `<lhs> := matchcontinue ... end matchcontinue;` with:\n"
      "        try\n"
      "          <pat> := <inputExpr>;\n"
      "          <lhs> := <expr>;\n"
      "        else\n"
      "          <lhs> := <expr2>;\n"
      "        end try;\n"
      "    If <expr> is exactly the pattern variable bound in <pat> (e.g. the case is\n"
      "    `case a::_ then a;`), you can collapse the two `try` assignments by binding\n"
      "    <lhs> directly in the pattern, e.g. `<lhs>::_ := <inputExpr>;` — but only do\n"
      "    this when it preserves the original semantics exactly.\n"
      "  - If the case has a `guard`, an `equation` section, or an `algorithm` section,\n"
      "    those statements must move into the `try` block too, BEFORE the assignment\n"
      "    that produces <lhs>. If the structure is complicated enough that you are not\n"
      "    sure the rewrite is semantically equivalent, leave the file unchanged.\n"
      "  - Any `local` declarations attached to the case stay where they are (they are\n"
      "    declared in the enclosing function/match block, not in the case itself in\n"
      "    typical OMC style); do not duplicate or move them.\n\n"
      "Worked example. Before:\n"
      "    n := matchcontinue x\n"
      "      case a::_ then a;\n"
      "      else 3;\n"
      "    end matchcontinue;\n"
      "After (collapsed form):\n"
      "    try\n"
      "      n::_ := x;\n"
      "    else\n"
      "      n := 3;\n"
      "    end try;\n"
      "After (non-collapsed form, also valid):\n"
      "    try\n"
      "      a::_ := x;\n"
      "      n := a;\n"
      "    else\n"
      "      n := 3;\n"
      "    end try;\n")
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
  if not notifs:
    return
  # Process bottom-up so earlier line numbers stay valid across edits within one batch.
  notifs.sort(key=lambda n: (n[0]['startLine'], n[0]['startCol']), reverse=True)
  moFileRel = relativeToCompiler(moFile)
  # Establish a baseline ONCE per file: stage currently-modified tracked files so
  # that any later agent edit shows up as `git diff --name-only`. We do NOT stage
  # untracked files here (the user's debug scripts, generated dumps, etc.).
  try:
    gitInitialCheckpoint()
  except (subprocess.CalledProcessError, FileNotFoundError) as e:
    print("git checkpoint failed (%s); aborting agent fixes." % e)
    return
  for n in notifs:
    prompt = agentPrompt(n, moFileRel)
    if prompt is None:
      continue
    info = n[0]
    print("%s Running agent for: %s" % (infoStr(info), list(n[1].keys())[0]))
    try:
      runAgent(prompt)
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
      print("Agent invocation failed (%s); skipping." % e)
      continue
    dirty = gitDirtyFiles()
    if not dirty:
      print("%s Agent made no changes." % infoStr(info))
      continue
    unexpected = [p for p in dirty if p != moFileRel]
    if unexpected:
      # The prompt is scoped to a single .mo file; touching anything else is
      # almost always a hallucination (e.g. editing a similarly-named function
      # in a different module). Skip verification and revert immediately —
      # running the build only to reject it would just waste time.
      print("%s Agent touched unexpected files %s; reverting all %s without verifying." %
            (infoStr(info), unexpected, dirty))
      gitRevert(dirty)
      continue
    try:
      runOMC(stamp)
    except Exception:
      print("%s Agent fix broke the build; reverting %s" % (infoStr(info), dirty))
      gitRevert(dirty)
      continue
    # Compile succeeded: promote ONLY these verified files to the new baseline.
    # Untracked files the agent may have created are deliberately left untracked
    # so the user can decide whether to keep them.
    try:
      gitStage(dirty)
      print("%s Agent fix verified. Staged: %s" % (infoStr(info), dirty))
    except subprocess.CalledProcessError as e:
      print("%s Agent fix verified but `git add` failed (%s)." % (infoStr(info), e))

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
