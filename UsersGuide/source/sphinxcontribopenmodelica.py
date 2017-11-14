#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import os
import shutil
import traceback
from os.path import basename
try:
    from StringIO import StringIO
except ImportError:
    from io import StringIO
import subprocess

from sphinx.util.compat import Directive
from docutils import nodes
from docutils.parsers.rst.directives.misc import Include as BaseInclude
from sphinx import directives
from docutils.parsers.rst import directives as rstdirectives
import docutils.parsers.rst.directives.images
from docutils.statemachine import ViewList

from OMPython import OMCSession

omc = OMCSession()
omhome = omc.sendExpression("getInstallationDirectoryPath()")
omc.sendExpression("setModelicaPath(\""+omhome+"/lib/omlibrary\")")
omc.sendExpression('mkdir("tmp/source")')
dochome = omc.sendExpression('cd("tmp")')

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
  (nm,ne,nw) = omc.sendExpression("countMessages()")
  return ne+nw == 0

def getErrorString(state):
  (nm,ne,nw) = omc.sendExpression("countMessages()")
  s = fixPaths(omc.sendExpression("OpenModelica.Scripting.getErrorString()"))
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

class ExecMosDirective(directives.CodeBlock):
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
        assert(omc.ask('clear()'))
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
          assert("" == omc.ask(str(s), parsed=False).strip())
        elif 'parsed' in self.options:
          res.append(fixPaths(omc.sendExpression(str(s))))
        else:
          res.append(fixPaths(omc.ask(str(s), parsed=False)))
        if not ('noerror' in self.options or erroratend):
          errs = fixPaths(omc.ask('getErrorString()', parsed=False))
          if errs!='""':
            res.append(errs)
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
    vl = ViewList()
    vl.append(".. code-block :: modelica", "<OMC loadString>")
    for opt in ['caption', 'name']:
      if opt in self.options:
        vl.append("  :%s: %s" % (opt,self.options[opt]), "<OMC loadString>")
    vl.append("", "<OMC loadString>")
    for n in self.content:
      vl.append("  " + str(n), "<OMC loadString>")
    node = docutils.nodes.paragraph()
    omc.sendExpression("loadString(%s)" % escapeString('\n'.join([str(n) for n in self.content])))
    self.state.nested_parse(vl, 0, node)
    return node.children + getErrorString(self.state)

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
      filename = os.path.abspath(self.options.get('filename') or omc.sendExpression("currentSimulationResult"))
      filename = filename.replace("\\", "/")
      caption = self.options.get('caption') or "Plot generated by OpenModelica+gnuplot"
      if 'plotall' in self.options:
        variables = list(omc.sendExpression('readSimulationResultVars(%s)' % escapeString(filename)))
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
        vl.append(">>> plotall()", "<OMC gnuplot>")
      node = docutils.nodes.paragraph()
      self.state.nested_parse(vl, 0, node)
      cb = node.children
      csvfile = os.path.abspath("tmp/" + self.arguments[0]) + ".csv"
      csvfile = csvfile.replace("\\", "/")
      if filename.endswith(".csv"):
        shutil.copyfile(filename, csvfile)
      else:
        assert(omc.sendExpression('filterSimulationResults("%s", "%s", %s)' % (filename,csvfile,varstrquoted)))
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
    omc = OMCSession()
    omc.sendExpression("setModelicaPath(\""+omhome+"/lib/omlibrary\")")
    omc.sendExpression('cd("tmp")')
    return []

def setup(app):
    app.add_directive('omc-mos', ExecMosDirective)
    app.add_directive('omc-gnuplot', OMCGnuplotDirective)
    app.add_directive('omc-loadstring', OMCLoadStringDirective)
    app.add_directive('omc-reset', OMCResetDirective)
