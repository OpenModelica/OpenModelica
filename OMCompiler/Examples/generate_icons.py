#!/usr/bin/env python

__author__ = 'Zsolt Lattmann'
__copyright__ = 'Copyright (C) 2013 Vanderbilt University'
__license__ = """
Copyright (C) 2013 Vanderbilt University

Permission is hereby granted, free of charge, to any person obtaining a
copy of this data, including any software or models in source or binary
form, as well as any drawings, specifications, and documentation
(collectively "the Data"), to deal in the Data without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Data, and to
permit persons to whom the Data is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Data.

THE DATA IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS, SPONSORS, DEVELOPERS, CONTRIBUTORS, OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE DATA OR THE USE OR OTHER DEALINGS IN THE DATA.
"""
__status__ = "Prototype"
__maintainer__ = "https://openmodelica.org"

import os
import re
import math
import json
import logging
import sys
import time
import hashlib
import base64
import datetime
from optparse import OptionParser

import svgwrite
from OMPython import OMCSessionZMQ
omc = OMCSessionZMQ()

# OpenModelica setup commands (use old front-end, see #6301)
OMC_SETUP_COMMANDS = ['setCommandLineOptions("-d=nogen,noevalfunc,-newInst")']
# use new front-end and nfAPI
# OMC_SETUP_COMMANDS = ['setCommandLineOptions("-d=nogen,noevalfunc,newInst,nfAPI")']

def classToFileName(cl):
  """
  The file-system dislikes directory separators, and scripts dislike tokens that expand to other names.
  This function uses the same replacement rules as the OpenModelica documentation-generating script.
  """
  return cl.replace("/","Division").replace("*","Multiplication").replace("<","x3C").replace(">","x3E")

exp_float = '[+-]?\d+(?:.\d+)?(?:e[+-]?\d+)?'

element_id = 0
regex_equal_key_value = re.compile("([^ =]+) *= *(\"[^\"]*\"|[^ ]*)")

regex_type_value = re.compile("(\w+.\w+)*")

# Compile regular expressions ONLY once!
# example: {-100.0,-100.0,100.0,100.0,true,0.16,2.0,2.0, {...
regex_coordSys = re.compile('('+exp_float+'),('+exp_float+'),('+exp_float+'),('+exp_float+'),(\w+),('+exp_float+'),('+exp_float+'),('+exp_float+'),')

# example: Rectangle(true, {35.0, 10.0}, 0, {0, 0, 0}, {255, 255, 255}, LinePattern.Solid, FillPattern.Solid, 0.25, BorderPattern.None, {{-15.0, -4.0}, {15.0, 4.0}}, 0
regex_rectangle = re.compile('Rectangle\(([\w ]+), {('+exp_float+'), ('+exp_float+')}, ('+exp_float+'), {(\d+), (\d+), (\d+)}, {(\d+), (\d+), (\d+)}, (\w+.\w+), (\w+.\w+), ('+exp_float+'), (\w+.\w+), {{('+exp_float+'), ('+exp_float+')}, {('+exp_float+'), ('+exp_float+')}}, ('+exp_float+')')

# example: Line(true, {0.0, 0.0}, 0, {{-30, -120}, {-10, -100}}, {0, 0, 0}, LinePattern.Solid, 0.25, {Arrow.None, Arrow.None}, 3, Smooth.None
regex_line = re.compile('Line\(([\w ]+), {('+exp_float+'), ('+exp_float+')}, ('+exp_float+'), ({{'+exp_float+', '+exp_float+'}(?:, {'+exp_float+', '+exp_float+'})*}), {(\d+), (\d+), (\d+)}, (\w+.\w+), ('+exp_float+'), {(\w+.\w+), (\w+.\w+)}, ('+exp_float+'), (\w+.\w+)')

# example: Ellipse(true, {0.0, 0.0}, 0, {0, 0, 0}, {95, 95, 95}, LinePattern.Solid, FillPattern.Solid, 0.25, {{-100, 100}, {100, -100}}, 0, 360)}}
regex_ellipse = re.compile('Ellipse\(([\w ]+), {('+exp_float+'), ('+exp_float+')}, ('+exp_float+'), {(\d+), (\d+), (\d+)}, {(\d+), (\d+), (\d+)}, (\w+.\w+), (\w+.\w+), ('+exp_float+'), {{('+exp_float+'), ('+exp_float+')}, {('+exp_float+'), ('+exp_float+')}}, ('+exp_float+'), ('+exp_float+')')

# example: Text(true, {0.0, 0.0}, 0, {0, 0, 255}, {0, 0, 0}, LinePattern.Solid, FillPattern.None, 0.25, {{-150, 110}, {150, 70}}, "%name", 0, {-1, -1, -1}, "fontName", {TextStyle.Bold, TextStyle.Italic, TextStyle.UnderLine}, TextAlignment.Center
regex_text = re.compile('Text\(([\w ]+), {('+exp_float+'), ('+exp_float+')}, ('+exp_float+'), {(\d+), (\d+), (\d+)}, {(\d+), (\d+), (\d+)}, (\w+.\w+), (\w+.\w+), ('+exp_float+'), {{('+exp_float+'), ('+exp_float+')}, {('+exp_float+'), ('+exp_float+')}}, ("[^"]*"), ('+exp_float+'), {([+-]?\d+), ([+-]?\d+), ([+-]?\d+)}, ("[^"]*"), {([^}]*)}, (\w+.\w+)')

# example: Text(true, {0.0, 0.0}, 0, {0, 0, 255}, {0, 0, 0}, LinePattern.Solid, FillPattern.None, 0.25, {{-150, 110}, {150, 70}}, {"%name", y, 0}, 0, {-1, -1, -1}, "fontName", {TextStyle.Bold, TextStyle.Italic, TextStyle.UnderLine}, TextAlignment.Center
regex_text2 = re.compile('Text\(([\w ]+), {('+exp_float+'), ('+exp_float+')}, ('+exp_float+'), {(\d+), (\d+), (\d+)}, {(\d+), (\d+), (\d+)}, (\w+.\w+), (\w+.\w+), ('+exp_float+'), {{('+exp_float+'), ('+exp_float+')}, {('+exp_float+'), ('+exp_float+')}}, {("[^"]*"), [+-, \w\d]*}, ('+exp_float+'), {([+-]?\d+), ([+-]?\d+), ([+-]?\d+)}, ("[^"]*"), {([^}]*)}, (\w+.\w+)')

# example: Polygon(true, {0.0, 0.0}, 0, {0, 127, 255}, {0, 127, 255}, LinePattern.Solid, FillPattern.Solid, 0.25, {{-24, -34}, {-82, 40}, {-72, 46}, {-14, -26}, {-24, -34}}, Smooth.None
#   Polygon(true, {-60, -40},90, {0, 0, 0}, {255, 128, 0}, LinePattern.Solid, FillPattern.VerticalCylinder, 0.25, {{-20.0, 10.0}, {0.0, -10.0}, {1.22465e-16, -50.0}, {-10.0, -60.0}, {-20.0, -60.0}, {-20.0, 10.0}}, Smooth.None
regex_polygon = re.compile('Polygon\(([\w ]+), {('+exp_float+'), ('+exp_float+')}, ('+exp_float+'), {(\d+), (\d+), (\d+)}, {(\d+), (\d+), (\d+)}, (\w+.\w+), (\w+.\w+), ('+exp_float+'), ({{'+exp_float+'(?:e[+-]?\d+)?, '+exp_float+'(?:e[+-]?\d+)?}(?:, {'+exp_float+', '+exp_float+'})*}), (\w+.\w+)')

# example: {{-100.0, -100.0}, {-100.0, -30.0}, {0.0, -30.0}, {0.0, 0.0}}
regex_points = re.compile('{('+exp_float+'), ('+exp_float+')}')

# example: Bitmap(true, {0.0, 0.0}, 0, {{-98, 98}, {98, -98}}, "modelica://Modelica/Resources/Images/Mechanics/MultiBody/Visualizers/TorusIcon.png"
# TODO: where is the imageSource?
regex_bitmap = re.compile('Bitmap\(([\w ]+), {('+exp_float+'), ('+exp_float+')}, ('+exp_float+'), {{('+exp_float+'), ('+exp_float+')}, {('+exp_float+'), ('+exp_float+')}}, ("[^"]*")(?:, ("[^"]*"))?')

# anything unknown that produces output should look like this: Trash(...
regex_any = re.compile('(\w+)\(')

omc_cache = {}


def ask_omc(question, opt=None, parsed=True):
    p = (question, opt, parsed)
    if p in omc_cache:
        return omc_cache[p]

    if opt:
        expression = question + '(' + opt + ')'
    else:
        expression = question

    logger.debug('ask_omc: {0}  - parsed: {1}'.format(expression, parsed))

    try:
        if parsed:
            res = omc.sendExpression(expression)
            omc.clearOMParserResult()
        else:
            res = omc.sendExpression(expression, parsed=False)
    except Exception as e:
        logger.error("OMC failed: {0}, {1}, parsed={2}".format(question, opt, parsed))
        raise

    omc_cache[p] = res

    return res

def removeFirstLastCurlBrackets(value):
    value = value.strip()
    if (len(value) > 1 and value[0] == '{' and value[len(value) - 1] == '}'):
        value = value[1: len(value) - 1]
    return value

def removeFirstLastParentheses(value):
    value = value.strip()
    if (len(value) > 1 and value[0] == '(' and value[len(value) - 1] == ')'):
      value = value[1: len(value) - 1]
    return value

def unparseArrays(value):
    lst = []
    braceopen = 0
    mainbraceopen = 0
    i = 0
    value = removeFirstLastCurlBrackets(value)
    subbraceopen = 0

    while i < len(value):
      if value[i] == ' ' or value[i] == ',':
        i+=1
        continue # ignore any kind of space
      if value[i] == '{' and braceopen == 0:
        braceopen = 1
        mainbraceopen = i
        i+=1
        continue
      if value[i] == '{':
        subbraceopen = 1

      if value[i] == '}' and braceopen == 1 and subbraceopen == 0:
        # closing of a group
        braceopen = 0
        lst.append(value[mainbraceopen:i+1])
        i+=1
        continue
      if value[i] == '}':
        subbraceopen = 0

      # skip the whole quotes section
      if value[i] == '"':
        i+=1
        while value[i] != '"':
          i+=1
          if value[i-1] == '\\' and value[i] == '"':
            i+=1

      i+=1

    return lst

def getStrings(value, start='{', end='}'):
    lst = []
    mask = False
    inString = False
    stringEnd = '\0'
    begin = 0
    ele = 0

    for i in range(len(value)):
      if inString:
        if mask:
          mask = False
        else:
          if value[i] == '\\':
            mask = True
          elif value[i] == stringEnd:
            inString = False
      else:
        if value[i] == '"':
          stringEnd = '"'
          inString = True
        elif value[i] == '\'':
          stringEnd = '\''
          inString = True
        elif value[i] == ',':
          if ele == 0:
            lst.append(value[begin:i].strip())
            begin = i+1
        elif value[i] == start:
          ele+=1
        elif value[i] == end:
          ele-=1

    lst.append(value[begin:len(value) + 1].strip())
    return lst

def consumeChar(value, res, i):
    if value[i] == '\\':
      i+=1
      if (value[i] == '\''):
        res.append('\'')
      elif (value[i] == '"'):
        res.append('\"')
      elif (value[i] == '?'):
        res.append('\?')
      elif (value[i] == '\\'):
        res.append('\\')
      elif (value[i] == 'a'):
        res.append('\a')
      elif (value[i] == 'b'):
        res.append('\b')
      elif (value[i] == 'f'):
        res.append('\f')
      elif (value[i] == 'n'):
        res.append('\n')
      elif (value[i] == 'r'):
        res.append('\r')
      elif (value[i] == 't'):
        res.append('\t')
      elif (value[i] == 'v'):
        res.append('\v')
    else:
      res.append(value[i])

    return res

def unparseStrings(value):
    lst = []
    value = value.strip()
    if value[0] != '{':
      return lst #ERROR?
    i = 1
    res = []
    while value[i] == '"':
      i+=1
      while value[i] != '"':
        res = consumeChar(value, res, i)
        i+=1
        # if we have unexpected double quotes then, however omc should return \"
        # remove this block once fixed in omc
        if value[i] == '"' and value[i+1] != ',':
          if value[i+1] != '}':
            res = consumeChar(value, res, i)
            i+=1
        # remove this block once fixed in omc
      i+=1
      if value[i] == '}':
        lst.append(''.join(res))
        return lst
      if value[i] == ',':
        lst.append(''.join(res))
        i+=1
        res = []
        while value[i] == ' ': # if we have space before next value e.g {"x", "y", "z"}
          i+=1
        continue
      while value[i] != '"' and value[i] is not None:
        i+=1
        print("error? malformed string-list. skipping: %c" % value[i])

    return lst

def componentPlacement(componentAnnotations):
    componentAnnotations = removeFirstLastCurlBrackets(componentAnnotations)
    annotations = getStrings(componentAnnotations, '(', ')')
    for annotation in annotations:
        if annotation.startswith('Placement'):
            annotation = annotation[len('Placement'):]
            placementAnnotation = removeFirstLastParentheses(annotation)
            if placementAnnotation.lower() == 'error':
                return []
            else:
                return getStrings(placementAnnotation)

def toInt(value, defaultValue = 0):
    try:
        return int(value)
    except:
        return defaultValue

def toFloat(value, defaultValue = 0):
    try:
        return float(value)
    except:
        return defaultValue

def toBool(value, defaultValue = False):
    try:
        return bool(value)
    except:
        return defaultValue

graphics_cache = {}

# get graphics objects from annotation Icon
def getGraphicsForClass(modelicaClass):

    # TODO: does not work if a port (same class) is being used multiple times...
    # if modelicaClass in graphics_cache:
    #     return graphics_cache[modelicaClass]

    result = dict()
    result['graphics'] = []

    answer2 = ask_omc('getIconAnnotation', modelicaClass, parsed=False)

    result['coordinateSystem'] = {}
    result['coordinateSystem']['extent'] = [[-100, -100], [100, 100]]

    r = regex_coordSys.search(answer2)
    if r:
        g = r.groups()
        result['coordinateSystem']['extent'] = [[toFloat(g[0]), toFloat(g[1])], [toFloat(g[2]), toFloat(g[3])]]
        result['coordinateSystem']['preserveAspectRatio'] = toBool(g[4])
        result['coordinateSystem']['initialScale'] = toFloat(g[5])
        result['coordinateSystem']['grid'] = [toFloat(g[6]), toFloat(g[7])]

        withOutCoordSys = answer2[answer2.find(',{'):]
    else:
        # logger.warning('Coordinate system was skipped')
        # logger.warning(answer2)
        withOutCoordSys = answer2

    for icon_line in withOutCoordSys.split('),'):

        # default values
        graphicsObj = {}

        r = regex_line.search(icon_line)
        if r:
            graphicsObj['type'] = 'Line'
            g = r.groups()
            graphicsObj['visible'] = g[0]
            graphicsObj['origin'] = [toFloat(g[1]), toFloat(g[2])]
            graphicsObj['rotation'] = toFloat(g[3])

            points = []
            gg = re.findall(regex_points, g[4])
            for i in range(0, len(gg)):
                points.append([toFloat(gg[i][0]), toFloat(gg[i][1])])
            graphicsObj['points'] = points

            graphicsObj['color'] = [toInt(g[5]), toInt(g[6]), toInt(g[7])]
            graphicsObj['pattern'] = g[8]
            graphicsObj['thickness'] = toFloat(g[9])
            graphicsObj['arrow'] = [g[10], g[11]]
            graphicsObj['arrowSize'] = toFloat(g[12])
            graphicsObj['smooth'] = g[13]

        r = regex_rectangle.search(icon_line)
        if r:
            graphicsObj['type'] = 'Rectangle'
            g = r.groups()
            graphicsObj['visible'] = g[0]
            graphicsObj['origin'] = [toFloat(g[1]), toFloat(g[2])]
            graphicsObj['rotation'] = toFloat(g[3])
            graphicsObj['lineColor'] = [toInt(g[4]), toInt(g[5]), toInt(g[6])]
            graphicsObj['fillColor'] = [toInt(g[7]), toInt(g[8]), toInt(g[9])]
            graphicsObj['linePattern'] = g[10]
            graphicsObj['fillPattern'] = g[11]
            graphicsObj['lineThickness'] = toFloat(g[12])
            graphicsObj['borderPattern'] = g[13]
            graphicsObj['extent'] = [[toFloat(g[14]), toFloat(g[15])], [toFloat(g[16]), toFloat(g[17])]]
            graphicsObj['radius'] = toFloat(g[18])

        r = regex_polygon.search(icon_line)
        if r:
            graphicsObj['icon_line'] = icon_line
            graphicsObj['type'] = 'Polygon'
            g = r.groups()
            graphicsObj['visible'] = g[0]
            graphicsObj['origin'] = [toFloat(g[1]), toFloat(g[2])]
            graphicsObj['rotation'] = toFloat(g[3])
            graphicsObj['lineColor'] = [toInt(g[4]), toInt(g[5]), toInt(g[6])]
            graphicsObj['fillColor'] = [toInt(g[7]), toInt(g[8]), toInt(g[9])]
            graphicsObj['linePattern'] = g[10]
            graphicsObj['fillPattern'] = g[11]
            graphicsObj['lineThickness'] = toFloat(g[12])

            points = []
            gg = re.findall(regex_points, g[13])
            for i in range(0, len(gg)):
                points.append([toFloat(gg[i][0]), toFloat(gg[i][1])])
            graphicsObj['points'] = points

            minX = 100
            minY = 100
            maxX = -100
            maxY = -100

            for point in graphicsObj['points']:
                if minX > point[0]:
                    minX = point[0]
                if maxX < point[0]:
                    maxX = point[0]
                if minY > point[1]:
                    minY = point[1]
                if maxY < point[1]:
                    maxY = point[1]

            graphicsObj['extent'] = [[minX, minY], [maxX, maxY]]

            graphicsObj['smooth'] = g[14]

        r = regex_text.search(icon_line)
        if not r:
            r = regex_text2.search(icon_line)
        if r:
            graphicsObj['type'] = 'Text'
            g = r.groups()
            graphicsObj['visible'] = g[0]
            graphicsObj['origin'] = [toFloat(g[1]), toFloat(g[2])]
            graphicsObj['rotation'] = toFloat(g[3])
            graphicsObj['lineColor'] = [toInt(g[4]), toInt(g[5]), toInt(g[6])]
            graphicsObj['fillColor'] = [toInt(g[7]), toInt(g[8]), toInt(g[9])]
            graphicsObj['linePattern'] = g[10]
            graphicsObj['fillPattern'] = g[11]
            graphicsObj['lineThickness'] = toFloat(g[12])
            graphicsObj['extent'] = [[toFloat(g[13]), toFloat(g[14])], [toFloat(g[15]), toFloat(g[16])]]
            graphicsObj['textString'] = g[17].strip('"')
            graphicsObj['fontSize'] = toFloat(g[18])
            graphicsObj['textColor'] = [toInt(g[19]), toInt(g[20]), toInt(g[21])]
            graphicsObj['fontName'] = g[22]
            if graphicsObj['fontName']:
                graphicsObj['fontName'] = graphicsObj['fontName'].strip('"')

            graphicsObj['textStyle'] = []
            if g[23]:
                graphicsObj['textStyle'] = regex_type_value.findall(g[23])  # text Style can have different number of styles

            graphicsObj['horizontalAlignment'] = g[24]

        r = regex_ellipse.search(icon_line)
        if r:
            g = r.groups()
            graphicsObj['type'] = 'Ellipse'
            graphicsObj['visible'] = g[0]
            graphicsObj['origin'] = [toFloat(g[1]), toFloat(g[2])]
            graphicsObj['rotation'] = toFloat(g[3])
            graphicsObj['lineColor'] = [toInt(g[4]), toInt(g[5]), toInt(g[6])]
            graphicsObj['fillColor'] = [toInt(g[7]), toInt(g[8]), toInt(g[9])]
            graphicsObj['linePattern'] = g[10]
            graphicsObj['fillPattern'] = g[11]
            graphicsObj['lineThickness'] = toFloat(g[12])
            graphicsObj['extent'] = [[toFloat(g[13]), toFloat(g[14])], [toFloat(g[15]), toFloat(g[16])]]
            graphicsObj['startAngle'] = toFloat(g[17])
            graphicsObj['endAngle'] = toFloat(g[18])

        r = regex_bitmap.search(icon_line)
        if r:
            g = r.groups()
            graphicsObj['type'] = 'Bitmap'
            graphicsObj['visible'] = g[0]
            graphicsObj['origin'] = [toFloat(g[1]), toFloat(g[2])]
            graphicsObj['rotation'] = toFloat(g[3])
            graphicsObj['extent'] = [[toFloat(g[4]), toFloat(g[5])], [toFloat(g[6]), toFloat(g[7])]]

            if g[9] != '""':
                graphicsObj['href'] = "data:image;base64,"+g[9].strip('"')
            else:
                fname = ask_omc('uriToFilename', g[8], parsed=False).strip().strip('"')
                if not os.path.exists(fname):
                    fname = os.path.join(baseDir, g[8].strip('"'))
                if not os.path.isdir(fname) and os.path.exists(fname):
                    with open(fname, "rb") as f_p:
                        graphicsObj['href'] = "data:image;base64,"+base64.b64encode(f_p.read()).decode()
                else:
                    logger.error("Could not find bitmap file {0}".format(g[8]))
                    graphicsObj['href'] = g[8].strip('"')

        if not 'type' in graphicsObj:
            r = regex_any.search(icon_line)
            if r:
                g = r.groups()
                graphicsObj['type'] = 'Unknown'
                logger.error('Unknown graphicsObj: {0}'.format(g[0]))
            elif icon_line.strip() == '{}': # ignore empty icons
                graphicsObj['type'] = 'Empty'
            else: # assume others to be empty as well
                graphicsObj['type'] = 'Empty'
                logger.info('Treating graphicsObj as empty icon: {0}'.format(icon_line))

        result['graphics'].append(graphicsObj)

    graphics_cache[modelicaClass] = result

    return result

def getGraphicsWithPortsForClass(modelicaClass):
    graphics = getGraphicsForClass(modelicaClass)
    graphics['className'] = modelicaClass
    graphics['ports'] = []
    if (modelicaClass):
        componentsList = unparseArrays(ask_omc('getComponents', modelicaClass + ', useQuotes = true', parsed=False))
        if componentsList:
            componentAnnotations = ask_omc('getComponentAnnotations', modelicaClass, parsed=False)
            componentAnnotationsList = getStrings(removeFirstLastCurlBrackets(componentAnnotations))

            for i in range(len(componentsList)):
                componentInfo = unparseStrings(componentsList[i])
                class_name = componentInfo[0]
                component_name = componentInfo[1]

                if ask_omc('isConnector', class_name):
                    if (i < len(componentAnnotationsList)):
                        comp_annotation = componentPlacement(componentAnnotationsList[i])
                        if (comp_annotation):
                            # base class graphics for ports
                            g_base = []
                            base_classes = []
                            getBaseClasses(class_name, base_classes)

                            for base_class in base_classes:
                                graphics_base = getGraphicsForClass(base_class)
                                g_base.append(graphics_base)

                            g = getGraphicsForClass(class_name)

                            g_this = g['graphics']

                            g['graphics'] = []
                            for g_b in g_base:
                                for g_i in g_b['graphics']:
                                    g['graphics'].append(g_i)
                            for g_b in g_this:
                                g['graphics'].append(g_b)

                            g['id'] = component_name
                            g['className'] = class_name

                            g['desc'] = componentInfo[2]

                            g['classDesc'] = ask_omc('getClassComment', class_name).strip().strip('"')

                            minX = g['coordinateSystem']['extent'][0][0]
                            minY = g['coordinateSystem']['extent'][0][1]
                            maxX = g['coordinateSystem']['extent'][1][0]
                            maxY = g['coordinateSystem']['extent'][1][1]

                            for gs in g['graphics']:
                                # use default values if it is not there
                                if not 'extent' in gs:
                                    gs['extent'] = [[-100, -100], [100, 100]]

                                if not 'origin' in gs:
                                    gs['origin'] = [0, 0]

                                if minX > gs['extent'][0][0] + gs['origin'][0]:
                                    minX = gs['extent'][0][0] + gs['origin'][0]
                                if minX > gs['extent'][1][0] + gs['origin'][0]:
                                    minX = gs['extent'][1][0] + gs['origin'][0]
                                if minY > gs['extent'][0][1] + gs['origin'][1]:
                                    minY = gs['extent'][0][1] + gs['origin'][1]
                                if minY > gs['extent'][1][1] + gs['origin'][1]:
                                    minY = gs['extent'][1][1] + gs['origin'][1]
                                if maxX < gs['extent'][1][0] + gs['origin'][0]:
                                    maxX = gs['extent'][1][0] + gs['origin'][0]
                                if maxX < gs['extent'][0][0] + gs['origin'][0]:
                                    maxX = gs['extent'][0][0] + gs['origin'][0]
                                if maxY < gs['extent'][1][1] + gs['origin'][1]:
                                    maxY = gs['extent'][1][1] + gs['origin'][1]
                                if maxY < gs['extent'][0][1] + gs['origin'][1]:
                                    maxY = gs['extent'][0][1] + gs['origin'][1]

                            g['coordinateSystem']['extent'] = [[minX, minY], [maxX, maxY]]

                            #print(comp_annotation)
                            if comp_annotation[0] == "true":
                                index_delta = 7
                                if comp_annotation[10] == "-":
                                    # fallback to diagram annotations
                                    index_delta = 0

                                for i in [1,2,7]:
                                    if comp_annotation[i + index_delta] == "-":
                                        comp_annotation[i + index_delta] = 0
                                origin_x = toFloat(comp_annotation[1 + index_delta])
                                origin_y = toFloat(comp_annotation[2 + index_delta])
                                x0 = toFloat(comp_annotation[3 + index_delta])
                                y0 = toFloat(comp_annotation[4 + index_delta])
                                x1 = toFloat(comp_annotation[5 + index_delta])
                                y1 = toFloat(comp_annotation[6 + index_delta])

                                if comp_annotation[7 + index_delta] == "":
                                    rotation = 0.0
                                else:
                                    rotation = toFloat(comp_annotation[7 + index_delta])

                                g['transformation'] = {}
                                g['transformation']['origin'] = [origin_x, origin_y]
                                g['transformation']['extent'] = [[x0, y0], [x1, y1]]
                                if isinstance(rotation,dict):
                                    g['transformation']['rotation'] = 0.0
                                else:
                                    g['transformation']['rotation'] = rotation

                                graphics['ports'].append(g)

    return graphics


def getGradientColors(startColor, stopColor, mid_points):
    result = []

    startRed = toInt(startColor[0])
    startGreen = toInt(startColor[1])
    startBlue = toInt(startColor[2])

    stopRed = toInt(stopColor[0])
    stopGreen = toInt(stopColor[1])
    stopBlue = toInt(stopColor[2])

    r_delta = (stopRed - startRed) / (mid_points + 1)
    g_delta = (stopGreen - startGreen) / (mid_points + 1)
    b_delta = (stopBlue - startBlue) / (mid_points + 1)

    result.append((startRed, startGreen, startBlue))

    for i in range(1, mid_points + 1):
        result.append((startRed + i * r_delta, startGreen + i * g_delta, startBlue + i * b_delta))

    result.append((stopRed, stopGreen, stopBlue))

    return result


def getCoordinates(xy, graphics, minX, maxY, transformation, coordinateSystem):

    x = xy[0] + graphics['origin'][0]
    y = xy[1] + graphics['origin'][1]

    # rotation for the icon
    s = math.sin(graphics['rotation'] / 180 * 3.1415)
    c = math.cos(graphics['rotation'] / 180 * 3.1415)

    x -= graphics['origin'][0]
    y -= graphics['origin'][1]

    xnew = x * c - y * s
    ynew = x * s + y * c

    x = xnew + graphics['origin'][0]
    y = ynew + graphics['origin'][1]

    if transformation and coordinateSystem:
        try:
            t_width = abs(max(transformation['extent'][1][0], transformation['extent'][0][0]) - min(transformation['extent'][1][0], transformation['extent'][0][0]))
            t_height = abs(max(transformation['extent'][1][1], transformation['extent'][0][1]) - min(transformation['extent'][1][1], transformation['extent'][0][1]))
            o_width = abs(max(coordinateSystem['extent'][1][0], coordinateSystem['extent'][0][0]) - min(coordinateSystem['extent'][1][1], coordinateSystem['extent'][0][1]))
            o_height = abs(max(coordinateSystem['extent'][1][1], coordinateSystem['extent'][0][1]) - min(coordinateSystem['extent'][1][1], coordinateSystem['extent'][0][1]))

            if 'extent' in transformation and transformation['extent'][1][0] < transformation['extent'][0][0]:
                # horizontal flip
                x = (-xy[0] + graphics['origin'][0]) / o_width * t_width + transformation['origin'][0] + transformation['extent'][1][0] + t_width / 2
            else:
                x = (xy[0] + graphics['origin'][0]) / o_width * t_width + transformation['origin'][0] + transformation['extent'][0][0] + t_width / 2

            if 'extent' in transformation and transformation['extent'][1][1] < transformation['extent'][0][1]:
                # vertical flip
                y = (-xy[1] + graphics['origin'][1]) / o_height * t_height + transformation['origin'][1] + min(transformation['extent'][1][1], transformation['extent'][0][1]) + t_height / 2
            else:
                y = (xy[1] + graphics['origin'][1]) / o_height * t_height + transformation['origin'][1] + min(transformation['extent'][0][1], transformation['extent'][0][1]) + t_height / 2

            s = math.sin(transformation['rotation'] / 180 * 3.1415)
            c = math.cos(transformation['rotation'] / 180 * 3.1415)

            x -= transformation['origin'][0]
            y -= transformation['origin'][1]

            xnew = x * c - y * s
            ynew = x * s + y * c

            x = xnew + transformation['origin'][0]
            y = ynew + transformation['origin'][1]

        except KeyError as ex:
            logger.error('Component position transformation failed: {0}', ex.message)
            logger.error(graphics)

    x -= minX
    y = maxY - y

    return x, y


# get svg object from modelica graphics object
def getSvgFromGraphics(dwg, graphics, minX, maxY, includeInvisibleText, transformation=None, coordinateSystem=None):
    global element_id
    shape = None
    definitions = svgwrite.container.Defs()
    origin = None

    if not 'origin' in graphics:
        graphics['origin'] = (0, 0)

    origin = graphics['origin']

    if graphics['type'] == 'Rectangle' or graphics['type'] == 'Ellipse' or graphics['type'] == 'Text' or graphics['type'] == "Bitmap":
        (x0, y0) = getCoordinates(graphics['extent'][0], graphics, minX, maxY, transformation, coordinateSystem)
        (x1, y1) = getCoordinates(graphics['extent'][1], graphics, minX, maxY, transformation, coordinateSystem)

    if graphics['type'] == 'Rectangle' or graphics['type'] == 'Ellipse' or graphics['type'] == 'Polygon':
        if not 'fillPattern' in graphics:
            graphics['fillPattern'] = 'FillPattern.None'

    if graphics['type'] == 'Rectangle':
        shape = dwg.rect((min(x0, x1), min(y0, y1)), (abs(x1 - x0), abs(y1 - y0)), graphics['radius'], graphics['radius'])

    elif graphics['type'] == 'Line':
        if 'points' in graphics:
            if graphics['smooth'] == 'Smooth.Bezier' and len(graphics['points']) > 2:
                # TODO: Optimize this part!!!
                shape = svgwrite.path.Path()
                x_0, y_0 = getCoordinates([graphics['points'][0][0], graphics['points'][0][1]], graphics, minX, maxY, transformation, coordinateSystem)
                shape.push('M', x_0, y_0, 'C')

                for i in range(1, len(graphics['points']) - 1):
                    x_0, y_0 = getCoordinates([graphics['points'][i-1][0], graphics['points'][i-1][1]], graphics, minX, maxY, transformation, coordinateSystem)
                    x_1, y_1 = getCoordinates([graphics['points'][i][0], graphics['points'][i][1]], graphics, minX, maxY, transformation, coordinateSystem)
                    x_2, y_2 = getCoordinates([graphics['points'][i+1][0], graphics['points'][i+1][1]], graphics, minX, maxY, transformation, coordinateSystem)
                    x_01 = (x_1 + x_0) / 2
                    y_01 = (y_1 + y_0) / 2
                    x_12 = (x_2 + x_1) / 2
                    y_12 = (y_2 + y_1) / 2
                    shape.push(x_01, y_01, x_1, y_1, x_12, y_12)
                x_n, y_n = getCoordinates([graphics['points'][len(graphics['points']) - 1][0], graphics['points'][len(graphics['points']) - 1][1]], graphics, minX, maxY, transformation, coordinateSystem)
                shape.push(x_12, y_12, x_n, y_n, x_n, y_n)
            else:
                shape = dwg.polyline([getCoordinates([x, y], graphics, minX, maxY, transformation, coordinateSystem) for (x, y) in graphics['points']])
            shape.fill('none', opacity=0)

            # markers
            if graphics['arrow'][0] != 'Arrow.None':
                url_id_start = graphics['arrow'][0] + '_start' + str(element_id)
                element_id += 1
                marker = svgwrite.container.Marker(insert=(10, 5), size=(4, 3), orient='auto', id=url_id_start, viewBox="0 0 10 10")
                p = svgwrite.path.Path(d="M 10 0 L 0 5 L 10 10 z")
                p.fill("rgb(" + ','.join([str(v) for v in graphics['color']]) + ")")
                marker.add(p)
                definitions.add(marker)
                shape['marker-start'] = marker.get_funciri()

            if graphics['arrow'][1] != 'Arrow.None':
                url_id_end = graphics['arrow'][1] + '_end' + str(element_id)
                element_id += 1
                marker = svgwrite.container.Marker(insert=(0, 5), size=(4, 3), orient='auto', id=url_id_end, viewBox="0 0 10 10")
                p = svgwrite.path.Path(d="M 0 0 L 10 5 L 0 10 z")
                p.fill("rgb(" + ','.join([str(v) for v in graphics['color']]) + ")")
                marker.add(p)
                definitions.add(marker)
                shape['marker-end'] = marker.get_funciri()

        else:
            logger.error('Not handled: {0}'.format(graphics))
            return None

    elif graphics['type'] == 'Polygon':
        if 'points' in graphics:
            if graphics['smooth'] == 'Smooth.Bezier' and len(graphics['points']) > 2:
                # TODO: Optimize this part!!!
                shape = svgwrite.path.Path()
                x_0, y_0 = getCoordinates([graphics['points'][0][0], graphics['points'][0][1]], graphics, minX, maxY, transformation, coordinateSystem)
                shape.push('M', x_0, y_0, 'C')

                for i in range(1, len(graphics['points']) - 1):
                    x_0, y_0 = getCoordinates([graphics['points'][i-1][0], graphics['points'][i-1][1]], graphics, minX, maxY, transformation, coordinateSystem)
                    x_1, y_1 = getCoordinates([graphics['points'][i][0], graphics['points'][i][1]], graphics, minX, maxY, transformation, coordinateSystem)
                    x_2, y_2 = getCoordinates([graphics['points'][i+1][0], graphics['points'][i+1][1]], graphics, minX, maxY, transformation, coordinateSystem)
                    x_01 = (x_1 + x_0) / 2
                    y_01 = (y_1 + y_0) / 2
                    x_12 = (x_2 + x_1) / 2
                    y_12 = (y_2 + y_1) / 2
                    shape.push(x_01, y_01, x_1, y_1, x_12, y_12)
                x_n, y_n = getCoordinates([graphics['points'][len(graphics['points']) - 1][0], graphics['points'][len(graphics['points']) - 1][1]], graphics, minX, maxY, transformation, coordinateSystem)
                shape.push(x_12, y_12, x_n, y_n, x_n, y_n)
            else:
                shape = dwg.polygon([getCoordinates([x, y], graphics, minX, maxY, transformation, coordinateSystem) for (x, y) in graphics['points']])
        else:
            logger.error('Not handled: {0}'.format(graphics))
            return None

    elif graphics['type'] == 'Ellipse':
        shape = dwg.ellipse(((x0 + x1) / 2, (y0 + y1) / 2), (abs((x1 - x0) / 2), abs((y1 - y0) / 2)))

    elif graphics['type'] == 'Text':

        extra = {}
        x = (x0 + x1) / 2
        y = (y0 + y1) / 2

        extra['font_family'] = graphics['fontName'] or "Verdana"

        if graphics['fontSize'] == 0:
            extra['font_size'] = str(abs(y1-y0)) # fit text into extent according to 18.6.5.5
        else:
            extra['font_size'] = graphics['fontSize']

        for style in graphics['textStyle']:
            if style == "TextStyle.Bold":
                extra['font-weight'] = 'bold'
            elif style == "TextStyle.Italic":
                extra['font-style'] = 'italic'
            elif style == "TextStyle.UnderLine":
                extra['text-decoration'] = 'underline'

        extra['dominant_baseline'] = "middle"

        if graphics['horizontalAlignment'] == "TextAlignment.Left":
            extra['text_anchor'] = "start"
            if x0 < x1:
                x = x0
            else:
                x = x1
        elif graphics['horizontalAlignment'] == "TextAlignment.Center":
            extra['text_anchor'] = "middle"
        elif graphics['horizontalAlignment'] == "TextAlignment.Right":
            extra['text_anchor'] = "end"
            if x0 < x1:
                x = x1
            else:
                x = x0

        shape = dwg.text(graphics['textString'].replace('%', ''), None, [x], [y], **extra)

        if includeInvisibleText and graphics['textString'].find('%') != -1:
            extra = {'class': "bbox", 'display': "none"}
            xmin = x0
            ymin = y0
            xmax = x1
            ymax = y1

            if x0 > x1:
                xmin = x1
                xmax = x0
            if y0 > y1:
                ymin = y1
                ymax = y0

            shape.add(svgwrite.text.TSpan(("{0} {1} {2} {3}".format(xmin, ymin, xmax, ymax)), **extra))
            extra = {'class': "data-bind", 'display': "none"}
            shape.add(svgwrite.text.TSpan(graphics['textString'], **extra))

    elif graphics['type'] == 'Bitmap':
        xmin = x0
        ymin = y0
        xmax = x1
        ymax = y1

        if x0 > x1:
            xmin = x1
            xmax = x0
        if y0 > y1:
            ymin = y1
            ymax = y0

        if (graphics['href'] == ''):
            return None
        shape = dwg.image(graphics['href'], x=xmin,y=ymin,width=xmax-xmin,height=ymax-ymin) # put in correct URL or base64 data "data:image;base64,"

    elif graphics['type'] == 'Empty':
        return None

    else:
        logger.warning('Not handled: {0}'.format(graphics))
        return None

    dot_size = 4
    dash_size = 16
    space_size = 8

    if 'linePattern' in graphics:
        dot_size *= graphics['lineThickness']
        dash_size *= graphics['lineThickness']
        space_size *= graphics['lineThickness']

        if graphics['linePattern'] == 'LinePattern.None' or graphics['type'] == 'Text':
            pass
        elif graphics['linePattern'] == 'LinePattern.Solid':
            shape.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width='{0}mm'.format(graphics['lineThickness']))
        elif graphics['linePattern'] == 'LinePattern.Dash':
            shape.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width='{0}mm'.format(graphics['lineThickness']))
            shape.dasharray([dash_size, space_size])
        elif graphics['linePattern'] == 'LinePattern.Dot':
            shape.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width='{0}mm'.format(graphics['lineThickness']))
            shape.dasharray([dot_size, space_size])
        elif graphics['linePattern'] == 'LinePattern.DashDot':
            shape.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width='{0}mm'.format(graphics['lineThickness']))
            shape.dasharray([dash_size, space_size, dot_size, space_size])
        elif graphics['linePattern'] == 'LinePattern.DashDotDot':
            shape.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width='{0}mm'.format(graphics['lineThickness']))
            shape.dasharray([dash_size, space_size, dot_size, space_size, dot_size, space_size])

        if graphics['type'] == 'Rectangle':
            if graphics['borderPattern'] == 'BorderPattern.None':
                pass
            elif graphics['borderPattern'] == 'BorderPattern.Raised':
                url_id = graphics['borderPattern'] + '_' + str(element_id)
                element_id += 1
                shape['filter'] = 'url(#' + url_id + ')'

                filter = svgwrite.filters.Filter(id=url_id, filterUnits="objectBoundingBox", x="-0.1", y="-0.1", width="1.2", height="1.2")
                filter.feGaussianBlur("SourceAlpha", stdDeviation="5", result="alpha_blur")
                feSL = filter.feSpecularLighting("alpha_blur", surfaceScale="5", specularConstant="1", specularExponent="20", lighting_color="#FFFFFF", result="spec_light")
                feSL.fePointLight((-5000, -10000, 10000))
                filter.feComposite("spec_light", in2="SourceAlpha", operator="in", result="spec_light")
                filter.feComposite("SourceGraphic", in2="spec_light", operator="out", result="spec_light_fill")

                definitions.add(filter)
            elif graphics['borderPattern'] == 'BorderPattern.Sunken':
                logger.warning('Not supported: {0}'.format(graphics['borderPattern']))
            elif graphics['borderPattern'] == 'BorderPattern.Engraved':
                logger.warning('Not supported: {0}'.format(graphics['borderPattern']))

    if 'color' in graphics:
        try:
            shape.stroke("rgb(" + ','.join([str(v) for v in graphics['color']]) + ")", width='{0}mm'.format(graphics['thickness']))
        except TypeError as ex:
            logger.error('{0} {1}'.format(graphics['color'], ex.message))

    if 'pattern' in graphics:
        dot_size *= graphics['thickness']
        dash_size *= graphics['thickness']
        space_size *= graphics['thickness']

        if graphics['pattern'] == 'LinePattern.None' or graphics['type'] == 'Text':
            pass
        elif graphics['pattern'] == 'LinePattern.Solid':
            shape.stroke("rgb(" + ','.join([str(v) for v in graphics['color']]) + ")", width='{0}mm'.format(graphics['thickness']))
        elif graphics['pattern'] == 'LinePattern.Dash':
            shape.stroke("rgb(" + ','.join([str(v) for v in graphics['color']]) + ")", width='{0}mm'.format(graphics['thickness']))
            shape.dasharray([dash_size, space_size])
        elif graphics['pattern'] == 'LinePattern.Dot':
            shape.stroke("rgb(" + ','.join([str(v) for v in graphics['color']]) + ")", width='{0}mm'.format(graphics['thickness']))
            shape.dasharray([dot_size, space_size])
        elif graphics['pattern'] == 'LinePattern.DashDot':
            shape.stroke("rgb(" + ','.join([str(v) for v in graphics['color']]) + ")", width='{0}mm'.format(graphics['thickness']))
            shape.dasharray([dash_size, space_size, dot_size, space_size])
        elif graphics['pattern'] == 'LinePattern.DashDotDot':
            shape.stroke("rgb(" + ','.join([str(v) for v in graphics['color']]) + ")", width='{0}mm'.format(graphics['thickness']))
            shape.dasharray([dash_size, space_size, dot_size, space_size, dot_size, space_size])

    if 'fillPattern' in graphics:
        if graphics['fillPattern'] == 'FillPattern.None':
            if graphics['type'] == 'Text':
                shape.fill("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", opacity=1)
            else:
                shape.fill('none', opacity=0)
        elif graphics['fillPattern'] == 'FillPattern.Solid':
            shape.fill("rgb(" + ','.join([str(v) for v in graphics['fillColor']]) + ")", opacity=1)
        elif graphics['fillPattern'] == 'FillPattern.Horizontal':
            url_id = str(element_id)
            element_id += 1
            shape.fill('url(#' + url_id + ')')

            pattern = svgwrite.pattern.Pattern(id=url_id, insert=(0, 0), size=(5, 5), patternUnits='userSpaceOnUse')

            rect = svgwrite.shapes.Rect(insert=(0, 0), size=(5, 5))
            rect.fill("rgb(" + ','.join([str(v) for v in graphics['fillColor']]) + ")")
            pattern.add(rect)

            svg_path = svgwrite.path.Path(d="M0,0 L5,0")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=2)
            pattern.add(svg_path)

            definitions.add(pattern)

        elif graphics['fillPattern'] == 'FillPattern.Vertical':
            url_id = str(element_id)
            element_id += 1
            shape.fill('url(#' + url_id + ')')

            pattern = svgwrite.pattern.Pattern(id=url_id, insert=(0, 0), size=(5, 5), patternUnits='userSpaceOnUse')

            rect = svgwrite.shapes.Rect(insert=(0, 0), size=(5, 5))
            rect.fill("rgb(" + ','.join([str(v) for v in graphics['fillColor']]) + ")")
            pattern.add(rect)

            svg_path = svgwrite.path.Path(d="M0,0 L0,5")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=2)
            pattern.add(svg_path)

            definitions.add(pattern)

        elif graphics['fillPattern'] == 'FillPattern.Cross':
            url_id = str(element_id)
            element_id += 1
            shape.fill('url(#' + url_id + ')')

            pattern = svgwrite.pattern.Pattern(id=url_id, insert=(0, 0), size=(5, 5), patternUnits='userSpaceOnUse')

            rect = svgwrite.shapes.Rect(insert=(0, 0), size=(5, 5))
            rect.fill("rgb(" + ','.join([str(v) for v in graphics['fillColor']]) + ")")
            pattern.add(rect)

            svg_path = svgwrite.path.Path(d="M0,0 L5,0")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=2)
            pattern.add(svg_path)

            svg_path = svgwrite.path.Path(d="M0,0 L0,5")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=2)
            pattern.add(svg_path)

            definitions.add(pattern)

        elif graphics['fillPattern'] == 'FillPattern.Forward':
            url_id = str(element_id)
            element_id += 1
            shape.fill('url(#' + url_id + ')')

            pattern = svgwrite.pattern.Pattern(id=url_id, insert=(0, 0), size=(7, 7), patternUnits='userSpaceOnUse')

            rect = svgwrite.shapes.Rect(insert=(0, 0), size=(7, 7))
            rect.fill("rgb(" + ','.join([str(v) for v in graphics['fillColor']]) + ")")
            pattern.add(rect)

            svg_path = svgwrite.path.Path(d="M0,0 l7,7")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=1)
            pattern.add(svg_path)

            svg_path = svgwrite.path.Path(d="M6,-1 l3,3")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=1)
            pattern.add(svg_path)

            svg_path = svgwrite.path.Path(d="M-1,6 l3,3")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=1)
            pattern.add(svg_path)

            definitions.add(pattern)

        elif graphics['fillPattern'] == 'FillPattern.Backward':
            url_id = str(element_id)
            element_id += 1
            shape.fill('url(#' + url_id + ')')

            pattern = svgwrite.pattern.Pattern(id=url_id, insert=(0, 0), size=(7, 7), patternUnits='userSpaceOnUse')

            rect = svgwrite.shapes.Rect(insert=(0, 0), size=(7, 7))
            rect.fill("rgb(" + ','.join([str(v) for v in graphics['fillColor']]) + ")")
            pattern.add(rect)

            svg_path = svgwrite.path.Path(d="M7,0 l-7,7")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=1)
            pattern.add(svg_path)

            svg_path = svgwrite.path.Path(d="M1,-1 l-7,7")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=1)
            pattern.add(svg_path)

            svg_path = svgwrite.path.Path(d="M8,6 l-7,7")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=1)
            pattern.add(svg_path)

            definitions.add(pattern)

        elif graphics['fillPattern'] == 'FillPattern.CrossDiag':

            url_id = str(element_id)
            element_id += 1
            shape.fill('url(#' + url_id + ')')

            pattern = svgwrite.pattern.Pattern(id=url_id, insert=(0, 0), size=(8, 8), patternUnits='userSpaceOnUse')

            rect = svgwrite.shapes.Rect(insert=(0, 0), size=(8, 8))
            rect.fill("rgb(" + ','.join([str(v) for v in graphics['fillColor']]) + ")")
            pattern.add(rect)

            svg_path = svgwrite.path.Path(d="M0,0 l8,8")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=1)
            pattern.add(svg_path)

            svg_path = svgwrite.path.Path(d="M8,0 l-8,8")
            svg_path.stroke("rgb(" + ','.join([str(v) for v in graphics['lineColor']]) + ")", width=1)
            pattern.add(svg_path)

            definitions.add(pattern)

        elif graphics['fillPattern'] == 'FillPattern.HorizontalCylinder':

            url_id = str(element_id)
            element_id += 1
            shape.fill('url(#' + url_id + ')')

            lineColor = graphics['lineColor']
            fillColor = graphics['fillColor']

            if not lineColor:
                lineColor = 'black'
            if not fillColor:
                fillColor = 'white'

            gradient = svgwrite.gradients.LinearGradient(id=url_id, x1="0%", y1="0%", x2="0%", y2="100%")

            colors = getGradientColors(lineColor, fillColor, 0)

            stopValues = [
                (0, 0),
                (0.3, 1),
                (0.7, 1),
                (1, 0)
            ]

            for (stopValue, idx) in stopValues:
                gradient.add_stop_color(offset=stopValue, color='rgb({0}, {1}, {2})'.format(colors[idx][0], colors[idx][1], colors[idx][2]), opacity=1)

            definitions.add(gradient)

        elif graphics['fillPattern'] == 'FillPattern.VerticalCylinder':
            url_id = str(element_id)
            element_id += 1
            shape.fill('url(#' + url_id + ')')

            lineColor = graphics['lineColor']
            fillColor = graphics['fillColor']

            if not lineColor:
                lineColor = 'black'
            if not fillColor:
                fillColor = 'white'

            gradient = svgwrite.gradients.LinearGradient(id=url_id, x1="0%", y1="0%", x2="100%", y2="0%")

            colors = getGradientColors(lineColor, fillColor, 0)

            stopValues = [
                (0, 0),
                (0.3, 1),
                (0.7, 1),
                (1, 0)
            ]

            for (stopValue, idx) in stopValues:
                gradient.add_stop_color(offset=stopValue, color='rgb({0}, {1}, {2})'.format(colors[idx][0], colors[idx][1], colors[idx][2]), opacity=1)

            definitions.add(gradient)
        elif graphics['fillPattern'] == 'FillPattern.Sphere':
            if graphics['type'] == 'Ellipse':
                url_id = str(element_id)
                element_id += 1

                shape.fill('url(#' + url_id + ')')

                lineColor = graphics['lineColor']
                fillColor = graphics['fillColor']

                if not lineColor:
                    lineColor = 'black'
                if not fillColor:
                    fillColor = 'white'

                gradient = svgwrite.gradients.RadialGradient(id=url_id, cx="50%", cy="50%", r="55%", fx="50%", fy="50%")
                colors = getGradientColors(lineColor, fillColor, 9)

                stopValues = [
                    (0, 10),
                    (0.45, 8),
                    (0.7, 6),
                    (1, 0)
                ]

                for (stopValue, idx) in stopValues:
                    gradient.add_stop_color(offset=stopValue, color='rgb({0}, {1}, {2})'.format(toInt(colors[idx][0]), toInt(colors[idx][1]), toInt(colors[idx][2])), opacity=1)

                definitions.add(gradient)
            elif graphics['type'] == 'Rectangle':
                url_id = str(element_id)
                element_id += 1

                shape.fill('url(#' + url_id + ')')

                lineColor = graphics['lineColor']
                fillColor = graphics['fillColor']

                if not lineColor:
                    lineColor = 'black'
                if not fillColor:
                    fillColor = 'white'

                gradient = svgwrite.gradients.RadialGradient(id=url_id, cx="50%", cy="50%", r="0.9", fx="50%", fy="50%")

                colors = getGradientColors(lineColor, fillColor, 0)

                stopValues = [
                    (0, 1),
                    (1, 0)
                ]

                for (stopValue, idx) in stopValues:
                    gradient.add_stop_color(offset=stopValue, color='rgb({0}, {1}, {2})'.format(colors[idx][0], colors[idx][1], colors[idx][2]), opacity=1)

                definitions.add(gradient)
    else:
        if graphics['type'] != 'Bitmap':
            shape.fill('none', opacity=0)

    return shape, definitions


# generate svgs from graphics objects
def generateSvg(filename, iconGraphics, includeInvisibleText, warn_duplicates):
    global element_id, use_subdirs
    element_id = 0

    width = 100
    height = 100

    minX = 0
    minY = 0
    maxX = 100
    maxY = 100

    for iconGraphic in iconGraphics:
        for graphics in iconGraphic['graphics']:
            if not 'origin' in graphics:
                graphics['origin'] = (0, 0)

            if not 'extent' in graphics:
                graphics['extent'] = [[-100, -100], [100, 100]]

            if 'extent' in graphics:
                if minX > graphics['extent'][0][0] + graphics['origin'][0]:
                    minX = graphics['extent'][0][0] + graphics['origin'][0]
                if minX > graphics['extent'][1][0] + graphics['origin'][0]:
                    minX = graphics['extent'][1][0] + graphics['origin'][0]
                if minY > graphics['extent'][0][1] + graphics['origin'][1]:
                    minY = graphics['extent'][0][1] + graphics['origin'][1]
                if minY > graphics['extent'][1][1] + graphics['origin'][1]:
                    minY = graphics['extent'][1][1] + graphics['origin'][1]
                if maxX < graphics['extent'][1][0] + graphics['origin'][0]:
                    maxX = graphics['extent'][1][0] + graphics['origin'][0]
                if maxX < graphics['extent'][0][0] + graphics['origin'][0]:
                    maxX = graphics['extent'][0][0] + graphics['origin'][0]
                if maxY < graphics['extent'][1][1] + graphics['origin'][1]:
                    maxY = graphics['extent'][1][1] + graphics['origin'][1]
                if maxY < graphics['extent'][0][1] + graphics['origin'][1]:
                    maxY = graphics['extent'][0][1] + graphics['origin'][1]

            if 'points' in graphics:
                for point in graphics['points']:
                    if minX > point[0] + graphics['origin'][0]:
                        minX = point[0] + graphics['origin'][0]
                    if minY > point[1] + graphics['origin'][1]:
                        minY = point[1] + graphics['origin'][1]
                    if maxX < point[0] + graphics['origin'][0]:
                        maxX = point[0] + graphics['origin'][0]
                    if maxY < point[1] + graphics['origin'][1]:
                        maxY = point[1] + graphics['origin'][1]

            for port in iconGraphic['ports']:
                if minX > port['transformation']['extent'][0][0] + port['transformation']['origin'][0]:
                    minX = port['transformation']['extent'][0][0] + port['transformation']['origin'][0]
                if minX > port['transformation']['extent'][1][0] + port['transformation']['origin'][0]:
                    minX = port['transformation']['extent'][1][0] + port['transformation']['origin'][0]
                if minY > port['transformation']['extent'][0][1] + port['transformation']['origin'][1]:
                    minY = port['transformation']['extent'][0][1] + port['transformation']['origin'][1]
                if minY > port['transformation']['extent'][1][1] + port['transformation']['origin'][1]:
                    minY = port['transformation']['extent'][1][1] + port['transformation']['origin'][1]
                if maxX < port['transformation']['extent'][1][0] + port['transformation']['origin'][0]:
                    maxX = port['transformation']['extent'][1][0] + port['transformation']['origin'][0]
                if maxX < port['transformation']['extent'][0][0] + port['transformation']['origin'][0]:
                    maxX = port['transformation']['extent'][0][0] + port['transformation']['origin'][0]
                if maxY < port['transformation']['extent'][1][1] + port['transformation']['origin'][1]:
                    maxY = port['transformation']['extent'][1][1] + port['transformation']['origin'][1]
                if maxY < port['transformation']['extent'][0][1] + port['transformation']['origin'][1]:
                    maxY = port['transformation']['extent'][0][1] + port['transformation']['origin'][1]

    # ports can have borders
    minX -= 5
    maxX += 5
    minY -= 5
    maxY += 5

    width = maxX - minX
    height = maxY - minY

    dwg = svgwrite.Drawing(filename, size=(width, height), viewBox="0 0 " + str(width) + " " + str(height))
    # Makes hashing not work
    # dwg.add(svgwrite.base.Desc(iconGraphics[-1]['className']))

    for iconGraphic in iconGraphics:
        for graphics in iconGraphic['graphics']:
            svgShape = getSvgFromGraphics(dwg, graphics, minX, maxY, includeInvisibleText)
            if svgShape:
                dwg.add(svgShape[0])
                dwg.add(svgShape[1])

    for iconGraphic in iconGraphics:
        for port in iconGraphic['ports']:
            group = dwg.g(id=port['id'])
            for graphics in port['graphics']:
                svgShape = getSvgFromGraphics(dwg, graphics, minX, maxY, includeInvisibleText, port['transformation'], port['coordinateSystem'])
                if svgShape:
                    group.add(svgShape[0])
                    group.add(svgShape[1])

            port_info = dwg.g(id='info', display='none')
            port_info.add(svgwrite.text.Text(port['id'], id='name'))
            port_info.add(svgwrite.text.Text(port['className'], id='type'))
            port_info.add(svgwrite.text.Text(port['classDesc'], id='classDesc'))
            port_info.add(svgwrite.text.Text(port['desc'], id='desc'))

            group.add(port_info)

            dwg.add(group)
    hashName = hashlib.sha1(dwg.tostring().encode("utf-8")).hexdigest() + ".svg"
    if use_subdirs:
        hashName = os.path.join(hashName[:1],hashName)
    hashPath = os.path.join(os.path.dirname(filename),hashName)
    if not os.path.exists(hashPath):
        if os.name == 'nt':
            dwg.saveas(filename)
        else:
            dwg.saveas(hashPath)
    if os.name != 'nt': # no symlink on windows, do nothing as we saved it above
        if not os.path.islink(filename):
            try:
                os.symlink(hashName, filename)
            except OSError as e:
                logger.error('Target file {0} already exists'.format(filename))
        else:
            if warn_duplicates:
                logger.warning('Target file {0} already exists'.format(filename))
            else:
                logger.error('Target file {0} already exists'.format(filename))

    return dwg


def exportIcon(modelicaClass, base_classes, includeInvisbleText, warn_duplicates, with_json):
    # get all icons
    iconGraphics = []

    for base_class in base_classes:
        graphics = getGraphicsWithPortsForClass(base_class)
        iconGraphics.insert(0,graphics)
    graphics = getGraphicsWithPortsForClass(modelicaClass)
    iconGraphics.append(graphics)

    if with_json:
        with open(os.path.join(output_dir, classToFileName(modelicaClass) + '.json'), 'w') as f_p:
            json.dump(iconGraphics, f_p)

    # export svgs
    dwg = generateSvg(os.path.join(output_dir, classToFileName(modelicaClass) + ".svg"), iconGraphics, includeInvisbleText, warn_duplicates)
    return dwg

# Note: The order of the base classes matters
def getBaseClasses(modelica_class, base_classes):
    inheritance_cnt = ask_omc('getInheritanceCount', modelica_class)

    if inheritance_cnt:
        for i in range(1, inheritance_cnt + 1):
            base_class = ask_omc('getNthInheritedClass', modelica_class + ', ' + str(i))
            if base_class not in base_classes:
                base_classes.append(base_class)
                getBaseClasses(base_class, base_classes)


def main():
    global baseDir, use_subdirs
    t = time.time()
    parser = OptionParser()
    parser.add_option("--with-html", help="Generate an HTML report with all SVG-files", action="store_true", dest="with_html", default=False)
    parser.add_option("--with-invisible-text", action="store_true", help="Includes invisible text containing the original text and bounding box, for debugging purposes", dest="includeInvisibleText", default=False)
    parser.add_option("--output-dir", help="Directory to generate SVG-files in", type="string", dest="output_dir", default=os.path.abspath('ModelicaIcons'))
    parser.add_option("--warn-dup", help="Warn about duplicate files instead of generating an error", action="store_true", dest="warn_duplicates", default=False)
    parser.add_option("--with-json", help="Output icon annotation as json", action="store_true", dest="with_json", default=False)
    parser.add_option("--with-subdirs", help="Output hashed icon files in subdirs", action="store_true", dest="use_subdirs", default=False)
    parser.add_option("--quiet", help="Do not output to the console", action="store_true", dest="quiet", default=False)
    (options, args) = parser.parse_args()
    if len(args) == 0:
      parser.print_help()
      return
    global output_dir
    output_dir = options.output_dir
    with_html = options.with_html
    includeInvisibleText = options.includeInvisibleText
    warn_duplicates = options.warn_duplicates
    with_json = options.with_json
    use_subdirs = options.use_subdirs

    # create logger with 'spam_application'
    global logger
    logger = logging.getLogger(os.path.basename(__file__))
    logger.setLevel(logging.DEBUG)

    # create console handler with a higher log level
    ch = logging.StreamHandler()
    if not options.quiet:
      ch.setLevel(logging.INFO)
    else:
      ch.setLevel(logging.CRITICAL)

    # create formatter and add it to the handlers
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)

    # add the handlers to the logger
    logger.addHandler(ch)

    # Inputs
    PACKAGES_TO_LOAD = args
    PACKAGES_TO_LOAD_FROM_FILE = []
    PACKAGES_TO_GENERATE = PACKAGES_TO_LOAD


    logger.info('Application started')
    logger.info('Output directory: ' + output_dir)
    print("%s Generating SVGs for package(s) %s" % (datetime.datetime.now(),PACKAGES_TO_GENERATE))

    if use_subdirs:
        for f in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']:
            output_dirx = os.path.join(output_dir, f)
            if not os.path.exists(output_dirx):
                try:
                    os.makedirs(output_dirx)
                except:
                    pass
    else:
        if not os.path.exists(output_dir):
            try:
                os.makedirs(output_dir)
            except:
                pass

    success = True

    for command in OMC_SETUP_COMMANDS:
        omc.sendExpression(command, parsed=False)
    for package in PACKAGES_TO_LOAD:
        logger.info('Loading package: {0}'.format(package))
        package_load = omc.sendExpression('loadModel(' + package + ')')
        if not package_load:
          success = False
          break
    for package in PACKAGES_TO_LOAD_FROM_FILE:
        logger.info('Loading package from file: {0}'.format(package))
        package_load = omc.sendExpression('loadFile("' + package + '")')
        logger.info('Load success: {0}'.format(package_load))
        if not package_load:
          success = False
          break
    if not success:
      logger.critical('Failed to load packages in %.1f seconds: %s' % (time.time()-t,omc.sendExpression('getErrorString()')))
      return 1
    dwgs = []

    for package in PACKAGES_TO_GENERATE:
      try:
        # create file handler which logs even debug messages
        fh = logging.FileHandler(package + '.log')
        fh.setLevel(logging.DEBUG)
        fh.setFormatter(formatter)
        logger.addHandler(fh)

        classInfo  = omc.sendExpression('getClassInformation({0})'.format(package))
        baseDir = os.path.dirname(classInfo[5])
        modelica_classes = omc.sendExpression('getClassNames(' + package + ', recursive=true, qualified=true, sort=true)')
        for modelica_class in modelica_classes:
            logger.info('Exporting: ' + modelica_class)

            # try:
            base_classes = []
            getBaseClasses(modelica_class, base_classes)
            dwg = exportIcon(modelica_class, base_classes, includeInvisibleText, warn_duplicates, with_json)
            dwgs.append(dwg)

            logger.info('Done: ' + modelica_class)
            # except:
            #     print 'FAILED: ' + modelica_class
        logger.removeHandler(fh)
      except Exception as e:
        logger.critical('Failed to generate icons for %s after %.1f seconds: %s' % (package,time.time()-t,sys.exc_info()[1]))
        raise
    if with_html:
      logger.info('Generating HTML file ...')
      with open(os.path.join(output_dir, 'index.html'), 'w') as f_p:
          f_p.write('<html>\n')
          f_p.write('<head>\n')
          f_p.write('</head>\n')

          f_p.write('<body>\n')

          for dwg in dwgs:
              try:
                dwg.write(f_p)
              except UnicodeEncodeError:
                f_p.write(dwg.tostring().encode("utf-8"))

          f_p.write('</body>\n')
          f_p.write('</html>\n')

      logger.info('HTML file is ready.')
    print("%s Generated SVGs for %d models in package(s) %s in %.1f seconds" % (datetime.datetime.now(),len(dwgs),PACKAGES_TO_GENERATE,time.time()-t))

    logger.info('End of application')
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())
