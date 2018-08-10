#!/usr/bin/env python3

import argparse
from junit_xml import TestSuite, TestCase
import glob
import simplejson
import subprocess
import time
from natsort import natsorted

def readTest(f, expectedFailures):
  cl = ".".join(f.split(".")[:-1])
  name = f.split(".")[-2]
  with open(f) as fin:
    try:
      res = simplejson.load(fin)
    except simplejson.errors.JSONDecodeError:
      print("Error loading file %s" % f)
      raise

  expectFail = cl in expectedFailures

  if "killed" in res:
    tc1 = TestCase(name, cl, 0, '', '')
    tc2 = TestCase(name, cl, 0, '', '')
    if expectFail:
      tc1.add_skipped_info('Killed or crashed; expected failure')
    else:
      tc1.add_error_info('Killed or crashed')
    tc2.add_error_info('Killed or crashed')
    return (tc1, tc2, cl)

  tc1 = TestCase(name, cl, res["time"], res["messages"], '')
  tc2 = TestCase(name, cl, res["time"], res["messages"], '')
  success = res["success"]
  shouldPass = res["shouldPass"]
  if expectFail:
    if success:
      tc1.add_error_info('This testcase started working (failure was expected)')
    else:
      tc1.add_skipped_info('This testcase still fails (as expected)')
  elif not success:
    if shouldPass:
      tc1.add_error_info('failed')
    else:
      tc1.add_error_info('expected failure, but passed')
  if not success:
    if shouldPass:
      tc2.add_error_info('failed')
    else:
      tc2.add_error_info('expected failure, but passed')
  return (tc1, tc2, None if success else cl)

if __name__ == '__main__':
  parser = argparse.ArgumentParser(description='OpenModelica ModelicaCompliance testing tool')
  parser.add_argument('--expectedFailures', default=None)
  parser.add_argument('--outPrefix', default="openmodelica")
  parser.add_argument('--version', default="OpenModelica ???")
  args = parser.parse_args()
  expectedFailuresFile = args.expectedFailures
  outPrefix = args.outPrefix
  version = args.version

  expectedFailures = set()
  if expectedFailuresFile:
    with open(expectedFailuresFile) as fin:
      expectedFailures = set(l.strip() for l in fin.readlines())
  print("=== Expected Failures ===")
  print(expectedFailures)
  print("=== End Expected Failures ===")

  res = [readTest(f, expectedFailures) for f in natsorted(glob.glob("*.res"))]

  (tcs1,tcs2,failures) = zip(*res)
  ts1 = TestSuite(version, tcs1)
  ts2 = TestSuite(version, tcs2)
  if outPrefix:
    with open("%s.ignore.xml" % outPrefix, "w") as fout:
      TestSuite.to_file(fout, [ts1], prettyprint=False)
    with open("%s.xml" % outPrefix, "w") as fout:
      TestSuite.to_file(fout, [ts2], prettyprint=False)
    with open("%s.failures" % outPrefix, "w") as fout:
      for fail in failures:
        if fail:
          fout.write(fail + "\n")
