#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import os
import traceback
from os.path import basename
from StringIO import StringIO
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
omc.sendExpression('mkdir("tmp/source")')
dochome = omc.sendExpression('cd("tmp")')

class ExecDirective(Directive):
  """Execute the specified python code and insert the output into the document"""
  has_content = True

  def run(self):
    oldStdout, sys.stdout = sys.stdout, StringIO()
    try:
      exec '\n'.join(self.content)
      return [nodes.paragraph(text = sys.stdout.getvalue())]
    except Exception, e:
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
  s = fixPaths(omc.sendExpression("getErrorString()"))
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
  }

  def run(self):
    #oldStdout, sys.stdout = sys.stdout, StringIO()
    erroratend = 'erroratend' in self.options or (not 'noerror' in self.options and len(self.content)==1)
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
        res.append(">>> %s" % s)
        if s.strip().endswith(";"):
          assert("" == omc.ask(str(s), parsed=False).strip())
        elif 'parsed' in self.options:
          res.append(fixPaths(omc.sendExpression(str(s))))
        else:
          res.append(fixPaths(omc.ask(str(s), parsed=False)))
        if not ('noerror' in self.options or erroratend):
          errs = fixPaths(omc.ask('getErrorString()', parsed=False))
          if errs<>'""':
            res.append(errs)
      # res += sys.stdout.readlines()
      self.content = res
      self.arguments.append('modelica')
      return super(ExecMosDirective, self).run() + (getErrorString(self.state) if erroratend else [])
    except Exception, e:
      return [nodes.error(None, nodes.paragraph(text = "Unable to execute Modelica code"), nodes.paragraph(text = str(e) + "\n" + traceback.format_exc()))]
    finally:
      pass # sys.stdout = oldStdout

def escapeString(s):
  return '"' + s.replace('"', '\\"') + '"'

class OMCLoadStringDirective(Directive):
  """Loads the code into OMC and returns the highlighted version of it"""
  has_content = True
  required_arguments = 0

  def run(self):
    vl = ViewList()
    for text in [".. code-block :: modelica", ""]:
      vl.append(text, "<OMC loadString>")
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
    'filename': str,
    'parametric': rstdirectives.flag
  }

  def run(self):
    try:
      filename = os.path.abspath(self.options.get('filename') or omc.sendExpression("currentSimulationResult"))
      if len(self.content)>1:
        varstr = "{%s}" % ", ".join(self.content)
        varstrquoted = "{%s}" % ", ".join(['"%s"'%s for s in self.content])
      else:
        varstr = self.content[0]
        varstrquoted = '{"%s"}'%self.content[0]
      vl = ViewList()
      if 'parametric' in self.options:
        vl.append('>>> plotParametric("%s","%s")' % (self.content[0],self.content[1]), "<OMC gnuplot>")
      else:
        vl.append(">>> plot(%s)" % varstrquoted, "<OMC gnuplot>")
      node = docutils.nodes.paragraph()
      self.state.nested_parse(vl, 0, node)
      cb = node.children
      assert(omc.sendExpression('filterSimulationResults("%s", "%s.csv", %s)' % (filename,os.path.abspath("tmp/" + self.arguments[0]),varstrquoted)))
      with open("tmp/%s.gnuplot" % self.arguments[0], "w") as gnuplot:
        gnuplot.write('set datafile separator ","\n')
        if 'parametric' in self.options:
          assert(2 == len(self.content))
          gnuplot.write('set parametric\n')
          gnuplot.write('set key off\n')
          gnuplot.write('set xlabel "%s"\n' % self.content[0])
          gnuplot.write('set ylabel "%s"\n' % self.content[1])
        for term in ["pdf", "svg", "png"]:
          gnuplot.write('set term %s\n' % term)
          gnuplot.write('set output "%s.%s"\n' % (os.path.abspath("source/" + self.arguments[0]), term))
          gnuplot.write('plot \\\n')
          if 'parametric' in self.options:
            vs = ['"%s.csv" using "%s":"%s" with lines' % (os.path.abspath("tmp/" + self.arguments[0]),self.content[0],self.content[1])]
          else:
            vs = ['"%s.csv" using 1:"%s"  title "%s" with lines, \\\n' % (os.path.abspath("tmp/" + self.arguments[0]),v,v) for v in self.content]
          gnuplot.writelines(vs)
          gnuplot.write('\n')
      subprocess.check_call(["gnuplot", "tmp/%s.gnuplot" % self.arguments[0]])
      try:
        vl = ViewList()
        for text in [".. figure :: %s.*" % self.arguments[0], "", "  Plot generated by OpenModelica+gnuplot"]:
          vl.append(text, "<OMC gnuplot>")
        node = docutils.nodes.paragraph()
        self.state.nested_parse(vl, 0, node)
        fig = node.children
      except Exception, e:
        fig = [nodes.error(None, nodes.paragraph(text = "Unable to execute gnuplot-figure directive"), nodes.paragraph(text = str(e) + "\n" + traceback.format_exc()))]
      return cb + fig
    except Exception, e:
      return [nodes.error(None, nodes.paragraph(text = "Unable to execute gnuplot directive"), nodes.paragraph(text = str(e) + "\n" + traceback.format_exc()))]

def setup(app):
    app.add_directive('omc-mos', ExecMosDirective)
    app.add_directive('omc-gnuplot', OMCGnuplotDirective)
    app.add_directive('omc-loadstring', OMCLoadStringDirective)
