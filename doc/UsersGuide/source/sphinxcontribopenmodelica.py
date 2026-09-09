#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import logging
import re
import shutil
import traceback
from os.path import basename
from io import StringIO
import subprocess

#from sphinx.util.compat import Directive
from docutils.parsers.rst import Directive
from docutils import nodes
from docutils.parsers.rst.directives.misc import Include as BaseInclude
from sphinx import directives
from docutils.parsers.rst import directives as rstdirectives
import docutils.parsers.rst.directives.images
from docutils.statemachine import ViewList

from OMPython import OMCSessionLocal, OMSessionException


class OMCMessages(logging.Handler):
  """Collect the omc messages OMPython logs.

  OMPython 4 asks omc for its messages after every sendExpression, which empties
  omc's buffer, so the getErrorString() and countMessages() these directives used
  to call afterwards come back empty and the errors an example is meant to
  demonstrate never reach the page. The messages are still logged, so pick them
  up from there and rebuild what getErrorString() would have returned.
  """

  # One entry of the summary OMPython logs when it saw an error:
  #   00: [kind:level:id] [file:readonly:lineStart:colStart:lineEnd:colEnd] message
  _long = re.compile(r"^\d+: \[[^\]:]*:([a-z]+):\d+\] "
                     r"\[([^:]*):(true|false):(\d+):(\d+):(\d+):(\d+)\] (.*)\Z",
                     re.DOTALL)
  # A single message:
  #   [OMC log for '...']: [kind:level:id] message
  _short = re.compile(r"^\[OMC log for '.*?'\]: \[[^\]:]*:([a-z]+):\d+\] (.*)\Z",
                      re.DOTALL)

  def __init__(self):
    super().__init__(level=logging.DEBUG)
    self.messages = []
    self._pending = []

  def emit(self, record):
    # OMPython's own output still belongs in the build log; propagate is off so
    # that notifications can be collected without also printing all of them.
    if record.levelno >= logging.WARNING:
      logging.getLogger().handle(record)

    text = record.getMessage()
    if text.startswith("OMC reported 'error'-level messages"):
      # Supersedes the individual messages of the same call: this one carries
      # the source positions as well.
      entries = []
      for line in text.split("\n"):
        m = self._long.match(line)
        if m:
          entries.append(self._entry(*m.groups()))
      if entries:
        self._pending = entries
      return
    m = self._short.match(text)
    if m:
      level, message = m.groups()
      self._pending.append((level, "%s: %s" % (level.capitalize(), message)))

  @staticmethod
  def _entry(level, filename, readonly, lstart, cstart, lend, cend, message):
    """Format one message the way omc's getErrorString() does."""
    where = ""
    if filename or lstart != "0":
      where = "[%s:%s:%s-%s:%s:%s] " % (filename, lstart, cstart, lend, cend,
                                        "readonly" if readonly == "true" else "writable")
    return (level, "%s%s: %s" % (where, level.capitalize(), message))

  def collect(self):
    """Move the messages of the last sendExpression into the running list."""
    self.messages.extend(self._pending)
    self._pending = []

  def clear(self):
    self.messages = []
    self._pending = []

  def counts(self):
    """(notifications+, errors, warnings), like omc's countMessages()."""
    ne = sum(1 for level, _ in self.messages if level == "error")
    nw = sum(1 for level, _ in self.messages if level == "warning")
    return (len(self.messages), ne, nw)

  def text(self):
    """What omc's getErrorString() would have returned."""
    return "\n".join(message for _, message in self.messages)


messages = OMCMessages()
_omlogger = logging.getLogger("OMPython")
_omlogger.setLevel(logging.INFO)
_omlogger.addHandler(messages)
_omlogger.propagate = False

omc = OMCSessionLocal()

def sendExpression(expr, parsed=True):
  """Send an expression to omc, keeping OMC errors out of the exception path.

  Since OMPython 4 sendExpression() raises on error-level messages by default,
  and raises regardless of raise_on_error when the expression does not parse.
  The directives here deliberately render whatever omc reports (see
  getErrorString()), and every line of an omc-mos block is sent on its own, so
  an error has to come back as a result. Otherwise one bad line takes out the
  rest of its block, or the whole Sphinx build.
  """
  try:
    return omc.sendExpression(expr, parsed=parsed, raise_on_error=False)
  except OMSessionException as e:
    return str(e)
  finally:
    messages.collect()

omhome = sendExpression("getInstallationDirectoryPath()")
# Pinning the path to the libraries shipped with this omc keeps the build
# reproducible, but a CMake install tree has no lib/omlibrary at all. Leave
# omc's default path alone there, so it can still find ~/.openmodelica.
omlibrary = os.path.join(omhome, "lib", "omlibrary")

def setModelicaPath():
  if os.path.isdir(omlibrary):
    sendExpression('setModelicaPath("%s")' % omlibrary.replace("\\", "/"))

setModelicaPath()
sendExpression('mkdir("tmp/source")')
dochome = sendExpression('cd("tmp")')

class ExecDirective(Directive):
  """Execute the specified python code and insert the output into the document"""
  has_content = True

  def run(self):
    oldStdout, sys.stdout = sys.stdout, StringIO()
    try:
      exec('\n'.join(self.content))
      return [nodes.paragraph(text = sys.stdout.getvalue())]
    except Exception as e:
      return [nodes.error(None, nodes.paragraph(text = "Unable to execute python code at %s:%d:" % (basename(self.src), self.srcline)), nodes.paragraph(text = str(e)))]
    finally:
      sys.stdout = oldStdout

def fixPaths(s):
  return str(s).replace(omhome, u"«OPENMODELICAHOME»").replace(dochome, u"«DOCHOME»").strip()

def onlyNotifications():
  (nm,ne,nw) = messages.counts()
  return ne+nw == 0

def getErrorString(state):
  (nm,ne,nw) = messages.counts()
  s = fixPaths(messages.text())
  messages.clear()
  if nm==0:
    return []
  node = nodes.paragraph()
  for x in s.split("\n"):
    node += nodes.paragraph(text = x)
  if ne>0:
    return [nodes.error(None, node)]
  elif nw>0:
    return [nodes.warning(None, node)]
  else:
    return [nodes.note(None, node)]

class ExecMosDirective(directives.code.CodeBlock):
  """Execute the specified Modelica code and insert the output into the document using syntax highlighting"""
  has_content = True
  required_arguments = 0
  option_spec = {
    'linenos': rstdirectives.flag,
    'dedent': int,
    'lineno-start': int,
    'emphasize-lines': rstdirectives.unchanged_required,
    'caption': rstdirectives.unchanged_required,
    'name': rstdirectives.unchanged,
    'noerror': rstdirectives.flag,
    'clear': rstdirectives.flag,
    'parsed': rstdirectives.flag,
    'combine-lines': rstdirectives.positive_int_list,
    'erroratend': rstdirectives.flag,
    'hidden': rstdirectives.flag,
    'ompython-output': rstdirectives.flag,
  }

  def run(self):
    #oldStdout, sys.stdout = sys.stdout, StringIO()
    erroratend = 'erroratend' in self.options or (not 'noerror' in self.options and len(self.content)==1) or 'hidden' in self.options
    try:
      if 'clear' in self.options:
        assert(sendExpression('clear()'))
      res = []
      if 'combine-lines' in self.options:
        old = 0
        content = []
        for i in self.options['combine-lines']:
          assert(i > old)
          content.append("\n".join([str(s) for s in self.content[old:i]]))
          old = i
      else:
        content = [str(s) for s in self.content]
      for s in content:
        if 'ompython-output' in self.options:
          res.append('>>> omc.sendExpression(%s)' % escapeString(s))
        else:
          res.append(">>> %s" % s)
        if s.strip().endswith(";"):
          assert("" == sendExpression(str(s), parsed=False).strip())
        elif 'parsed' in self.options:
          res.append(fixPaths(sendExpression(str(s))))
        else:
          res.append(fixPaths(sendExpression(str(s), parsed=False)))
        if not ('noerror' in self.options or erroratend):
          errs = fixPaths(messages.text())
          messages.clear()
          if errs:
            res.append('"%s"' % errs)
      # res += sys.stdout.readlines()
      self.content = res
      if 'ompython-output' in self.options:
        self.arguments.append('python')
      else:
        self.arguments.append('modelica')
      return ([] if 'hidden' in self.options else super(ExecMosDirective, self).run()) + (getErrorString(self.state) if erroratend else [])
    except Exception as e:
      s = str(e) + "\n" + traceback.format_exc()
      print(s)
      return [nodes.error(None, nodes.paragraph(text = "Unable to execute Modelica code"), nodes.paragraph(text = s))]
    finally:
      pass # sys.stdout = oldStdout

def escapeString(s):
  return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

class OMCLoadStringDirective(Directive):
  """Loads the code into OMC and returns the highlighted version of it"""
  has_content = True
  required_arguments = 0
  option_spec = {
    'caption': rstdirectives.unchanged,
    'name': rstdirectives.unchanged
  }

  def run(self):
    try:
      vl = ViewList()
      vl.append(".. code-block :: modelica", "<OMC loadString>")
      for opt in ['caption', 'name']:
        if opt in self.options:
          vl.append("  :%s: %s" % (opt,self.options[opt]), "<OMC loadString>")
      vl.append("", "<OMC loadString>")
      for n in self.content:
        vl.append("  " + str(n), "<OMC loadString>")
      node = docutils.nodes.paragraph()
      sendExpression("loadString(%s)" % escapeString('\n'.join([str(n) for n in self.content])))
      self.state.nested_parse(vl, 0, node)
      return node.children + getErrorString(self.state)
    except Exception as e:
      s = str(e) + "\n" + traceback.format_exc()
      print(s)
      return [nodes.error(None, nodes.paragraph(text = "Unable to load Modelica code"), nodes.paragraph(text = s))]

class OMCGnuplotDirective(Directive):
  """Execute the specified python code and insert the output into the document"""
  has_content = True
  required_arguments = 1
  option_spec = {
    'filename': rstdirectives.path,
    'caption': rstdirectives.unchanged,
    'name': rstdirectives.unchanged,
    'parametric': rstdirectives.flag,
    'plotall': rstdirectives.flag
  }

  def run(self):
    try:
      filename = os.path.abspath(self.options.get('filename') or sendExpression("currentSimulationResult"))
      filename = filename.replace("\\", "/")
      caption = self.options.get('caption') or "Plot generated by OpenModelica+gnuplot"
      if 'plotall' in self.options:
        variables = list(sendExpression('readSimulationResultVars(%s)' % escapeString(filename)))
        variables.remove('time')
      else:
        variables = self.content
      if len(variables)>1:
        varstr = "{%s}" % ", ".join(variables)
        varstrquoted = "{%s}" % ", ".join(['"%s"'%s for s in variables])
      else:
        varstr = variables[0]
        varstrquoted = '{"%s"}'%variables[0]
      vl = ViewList()
      if 'parametric' in self.options:
        vl.append('>>> plotParametric("%s","%s")' % (variables[0],variables[1]), "<OMC gnuplot>")
      elif 'plotall' in self.options:
        vl.append(">>> plotAll()", "<OMC gnuplot>")
      node = docutils.nodes.paragraph()
      self.state.nested_parse(vl, 0, node)
      cb = node.children
      csvfile = os.path.abspath("tmp/" + self.arguments[0]) + ".csv"
      csvfile = csvfile.replace("\\", "/")
      if filename.endswith(".csv"):
        shutil.copyfile(filename, csvfile)
      else:
        assert(sendExpression('filterSimulationResults("%s", "%s", %s)' % (filename,csvfile,varstrquoted)))
      with open("tmp/%s.gnuplot" % self.arguments[0], "w") as gnuplot:
        gnuplot.write('set datafile separator ","\n')
        if 'parametric' in self.options:
          assert(2 == len(variables))
          gnuplot.write('set parametric\n')
          gnuplot.write('set key off\n')
          gnuplot.write('set xlabel "%s"\n' % variables[0])
          gnuplot.write('set ylabel "%s"\n' % variables[1])
        for term in ["pdf", "svg", "png"]:
          gnuplot.write('set term %s\n' % term)
          outputpath = os.path.abspath("source/" + self.arguments[0])
          outputpath = outputpath.replace("\\", "/")
          gnuplot.write('set output "%s.%s"\n' % (outputpath, term))
          gnuplot.write('plot \\\n')
          if 'parametric' in self.options:
            vs = ['"%s" using "%s":"%s" with lines' % (csvfile,variables[0],variables[1])]
          else:
            vs = ['"%s" using 1:"%s"  title "%s" with lines, \\\n' % (csvfile,v,v) for v in variables]
          gnuplot.writelines(vs)
          gnuplot.write('\n')
      subprocess.check_call(["gnuplot", "tmp/%s.gnuplot" % self.arguments[0]])
      try:
        vl = ViewList()
        for text in [".. figure :: %s.*" % self.arguments[0]] + (["  :name: %s" % self.options["name"]] if "name" in self.options else []) + ["", "  %s" % caption]:
          vl.append(text, "<OMC gnuplot>")
        node = docutils.nodes.paragraph()
        self.state.nested_parse(vl, 0, node)
        fig = node.children
      except Exception as e:
        s = str(e) + "\n" + traceback.format_exc()
        print(s)
        fig = [nodes.error(None, nodes.paragraph(text = "Unable to execute gnuplot-figure directive"), nodes.paragraph(text = s))]
      return cb + fig
    except Exception as e:
      s = str(e) + "\n" + traceback.format_exc()
      print(s)
      return [nodes.error(None, nodes.paragraph(text = "Unable to execute gnuplot directive"), nodes.paragraph(text = s))]

class OMCResetDirective(Directive):
  """Restarts OMPython"""
  has_content = False
  required_arguments = 0

  def run(self):
    global omc
    del(omc)
    omc = OMCSessionLocal()
    setModelicaPath()
    sendExpression('cd("tmp")')
    return []

def setup(app):
    app.add_directive('omc-mos', ExecMosDirective)
    app.add_directive('omc-gnuplot', OMCGnuplotDirective)
    app.add_directive('omc-loadstring', OMCLoadStringDirective)
    app.add_directive('omc-reset', OMCResetDirective)
