#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
from os.path import basename
from StringIO import StringIO

from sphinx.util.compat import Directive
from docutils import nodes
from docutils.parsers.rst.directives.misc import Include as BaseInclude
from sphinx import directives
from docutils.parsers.rst import directives as rstdirectives

from OMPython import OMCSession

omc = OMCSession()
omhome = omc.sendExpression("getInstallationDirectoryPath()")
dochome = omc.sendExpression("cd()")

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

class ExecMosDirective(directives.CodeBlock):
  """Execute the specified python code and insert the output into the document"""
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
    'parsed': rstdirectives.flag
  }

  def run(self):
    #oldStdout, sys.stdout = sys.stdout, StringIO()
    try:
      if 'clear' in self.options:
        assert(omc.ask('clear()'))
      res = []
      for s in self.content:
        res.append(">>> %s" % s)
        if 'parsed' in self.options:
          res.append(fixPaths(omc.sendExpression(str(s))))
        else:
          res.append(fixPaths(omc.ask(str(s), parsed=False)))
        if not ('noerror' in self.options):
          errs = fixPaths(omc.sendExpression('getErrorString()'))
          if len(errs):
            res.append(errs)
      # res += sys.stdout.readlines()
      self.content = res
      self.arguments.append('modelica')
      return super(ExecMosDirective, self).run()
    except Exception, e:
      return [nodes.error(None, nodes.paragraph(text = "Unable to execute Modelica code"), nodes.paragraph(text = str(e)))]
    finally:
      pass # sys.stdout = oldStdout

def setup(app):
    app.add_directive('exec-mos', ExecMosDirective)
