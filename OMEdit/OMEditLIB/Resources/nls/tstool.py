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

"""List, check and edit the messages of a Qt .ts translation file.

  tstool.py list FILE [--context C] [--limit N] [--guessed] [--skip KEYS.jsonl]
  tstool.py check FILE...
  tstool.py apply FILE EDITS.json

list prints the unfinished messages as JSON lines. apply reads a JSON list:

  {"context": C, "source": S, "comment": ..., "translation": T}   finished
  {"context": C, "source": S, "translation": [T1, T2]}             numerus forms
  {"context": C, "source": S, "clear": true}                       empty, unfinished

"comment" is only needed when it is set on the message. apply refuses
translations that fail the checks, then writes the file with lconvert, so the
format is the one lupdate writes. Set LCONVERT if lconvert is not on PATH.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from collections import Counter

PLACEHOLDER = re.compile(r"%(?:L?\d{1,2}|n)")
TAG = re.compile(r"(</?)(a|b|big|body|br|center|code|div|em|font|h[1-6]|head|hr|html|i|img|li|nobr|ol|p|pre|qt|s|"
                 r"small|span|strong|sub|sup|table|td|th|tr|tt|u|ul)\b", re.IGNORECASE)
ENTITY = re.compile(r"&(?:[A-Za-z]+|#\d+);")
MNEMONIC = re.compile(r"&(?!&)(?=\S)")


def lconvert():
    for c in (os.environ.get("LCONVERT"), shutil.which("lconvert"), "/usr/lib/qt6/bin/lconvert"):
        if c and os.access(c, os.X_OK):
            return c
    sys.exit("lconvert not found, set LCONVERT")


def messages(root):
    for ctx in root.iter("context"):
        name = ctx.findtext("name")
        for msg in ctx.iter("message"):
            yield name, msg


def key(name, msg):
    return {"context": name, "source": msg.findtext("source"), "comment": msg.findtext("comment")}


def forms(msg):
    tr = msg.find("translation")
    if msg.get("numerus") == "yes":
        return [f.text or "" for f in tr.findall("numerusform")]
    return [tr.text or ""]


def mnemonics(s):
    return len(MNEMONIC.findall(ENTITY.sub("", s.replace("&&", ""))))


def problems(source, translations):
    errors, warnings = [], []
    want = Counter(PLACEHOLDER.findall(source))
    for i, t in enumerate(translations):
        got = Counter(PLACEHOLDER.findall(t))
        if len(translations) > 1:
            want_n, got_n = want.copy(), got.copy()
            want_n.pop("%n", None)
            got_n.pop("%n", None)
            if set(want_n) != set(got_n):
                errors.append(f"form {i}: placeholders {sorted(got)} != {sorted(want)}")
            elif "%n" in want and "%n" not in got:
                warnings.append(f"form {i}: no %n")
        elif set(got) != set(want):
            errors.append(f"placeholders {sorted(got)} != {sorted(want)}")
        if mnemonics(source) != mnemonics(t):
            errors.append(f"{mnemonics(t)} & mnemonics, the source has {mnemonics(source)}")
        if Counter((a, b.lower()) for a, b in TAG.findall(t)) != Counter((a, b.lower()) for a, b in TAG.findall(source)):
            errors.append("HTML tags differ")
        if t.count("\n") != source.count("\n"):
            errors.append(f"{t.count(chr(10))} line breaks, the source has {source.count(chr(10))}")
        if source[:len(source) - len(source.lstrip())] != t[:len(t) - len(t.lstrip())] or \
           source[len(source.rstrip()):] != t[len(t.rstrip()):]:
            errors.append("leading or trailing whitespace differs")
        for end in ("...", "…", ":"):
            if source.rstrip().endswith(end) != t.rstrip().endswith(end):
                warnings.append(f"the source and the translation do not both end with {end!r}")
        if not t.strip():
            errors.append("empty translation")
    return errors, warnings


def cmd_list(a):
    root = ET.parse(a.file).getroot()
    skip = set()
    if a.skip and os.path.exists(a.skip):
        with open(a.skip, encoding="utf-8") as f:
            for line in f:
                if line.strip():
                    k = json.loads(line)
                    skip.add((k["context"], k["source"], k.get("comment")))
    n = 0
    for name, msg in messages(root):
        tr = msg.find("translation")
        if tr.get("type") != "unfinished" or (a.context and name != a.context):
            continue
        k = key(name, msg)
        if (k["context"], k["source"], k["comment"]) in skip:
            continue
        guess = forms(msg)
        if a.guessed and not any(g.strip() for g in guess):
            continue
        k["extracomment"] = msg.findtext("extracomment")
        k["numerus"] = msg.get("numerus") == "yes"
        k["guess"] = guess if k["numerus"] else guess[0]
        print(json.dumps({x: v for x, v in k.items() if v not in (None, False)}, ensure_ascii=False))
        n += 1
        if a.limit and n >= a.limit:
            break


def cmd_check(a):
    bad = 0
    for path in a.files:
        root = ET.parse(path).getroot()
        for name, msg in messages(root):
            tr = msg.find("translation")
            if tr.get("type") in ("vanished", "obsolete"):
                continue
            t = forms(msg)
            if not any(x.strip() for x in t):
                continue
            errors, _ = problems(msg.findtext("source"), t)
            for e in errors:
                state = tr.get("type") or "finished"
                print(f"{path}: {name}: {msg.findtext('source')!r} ({state}): {e}")
                bad += 1
    sys.exit(1 if bad else 0)


def cmd_apply(a):
    tree = ET.parse(a.file)
    index = {}
    for name, msg in messages(tree.getroot()):
        k = key(name, msg)
        index[(k["context"], k["source"], k["comment"])] = msg
    with open(a.edits, encoding="utf-8") as f:
        edits = json.load(f)
    failed = False
    for e in edits:
        msg = index.get((e["context"], e["source"], e.get("comment")))
        label = f"{e['context']}: {e['source']!r}"
        if msg is None:
            print(f"{label}: no such message")
            failed = True
            continue
        tr = msg.find("translation")
        numerus = msg.get("numerus") == "yes"
        if e.get("clear"):
            tr.set("type", "unfinished")
            for f in (tr.findall("numerusform") if numerus else [tr]):
                f.text = None
            continue
        t = e["translation"]
        t = t if isinstance(t, list) else [t]
        if numerus != (len(t) > 1 or isinstance(e["translation"], list)) or \
           (numerus and len(t) != len(tr.findall("numerusform"))):
            print(f"{label}: give {len(tr.findall('numerusform'))} numerus forms" if numerus
                  else f"{label}: not a numerus message")
            failed = True
            continue
        errors, warnings = problems(e["source"], t)
        for w in warnings:
            print(f"{label}: warning: {w}")
        if errors:
            for x in errors:
                print(f"{label}: {x}")
            failed = True
            continue
        if numerus:
            for f, x in zip(tr.findall("numerusform"), t):
                f.text = x
        else:
            tr.text = t[0]
        tr.attrib.pop("type", None)
    if failed:
        sys.exit("nothing written")
    # lupdate's same-text heuristic: an empty unfinished message gets the
    # translation of the finished ones with the same source if they all agree.
    finished = {}
    for name, msg in messages(tree.getroot()):
        if msg.find("translation").get("type") is None:
            finished.setdefault((msg.findtext("source"), msg.get("numerus")), set()).add(tuple(forms(msg)))
    for name, msg in messages(tree.getroot()):
        tr = msg.find("translation")
        guesses = finished.get((msg.findtext("source"), msg.get("numerus")), set())
        guess = next(iter(guesses)) if len(guesses) == 1 else None
        if tr.get("type") == "unfinished" and guess and not any(x.strip() for x in forms(msg)):
            for f, x in zip(tr.findall("numerusform") if msg.get("numerus") == "yes" else [tr], guess):
                f.text = x
            print(f"{name}: {msg.findtext('source')!r}: same-text guess, review it with list --guessed")
    with tempfile.TemporaryDirectory(dir=os.path.dirname(os.path.abspath(a.file))) as tmp:
        raw, out = os.path.join(tmp, "raw.ts"), os.path.join(tmp, "out.ts")
        tree.write(raw, encoding="utf-8", xml_declaration=True)
        r = subprocess.run([lconvert(), "-locations", "none", "-i", raw, "-o", out])
        if r.returncode != 0 or not os.path.isfile(out):
            sys.exit(f"lconvert failed with exit code {r.returncode}, {a.file} not changed")
        shutil.copymode(a.file, out)
        os.replace(out, a.file)
    print(f"{a.file}: {len(edits)} messages updated")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("list")
    s.add_argument("file")
    s.add_argument("--context")
    s.add_argument("--limit", type=int)
    s.add_argument("--guessed", action="store_true", help="only messages with a guessed translation")
    s.add_argument("--skip", help="JSON lines of messages to leave out")
    s.set_defaults(func=cmd_list)
    s = sub.add_parser("check")
    s.add_argument("files", nargs="+")
    s.set_defaults(func=cmd_check)
    s = sub.add_parser("apply")
    s.add_argument("file")
    s.add_argument("edits")
    s.set_defaults(func=cmd_apply)
    a = p.parse_args()
    a.func(a)


if __name__ == "__main__":
    main()
