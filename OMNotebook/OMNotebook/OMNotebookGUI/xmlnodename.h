/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*!
* \file xmlnodename.h
* \author Anders Fernström
* \date 2005-11-30
*
* \brief Define the xml node names for the xml format used to save the
* cell structure
*/

// notebook
#define XML_NOTEBOOK      "Notebook"

// cell element
#define XML_GROUPCELL      "GroupCell"
#define XML_TEXTCELL      "TextCell"
#define XML_INPUTCELL      "InputCell"
#define XML_GRAPHCELL      "GraphCell"
#define XML_LATEXCELL      "LatexCell"
// attribute
#define XML_CLOSED        "closed"
#define XML_STYLE        "style"
#define XML_NAME        "name"

// child
#define XML_TEXT        "Text"
#define XML_RULE        "Rule"
#define XML_IMAGE        "Image"
#define XML_INPUTPART      "Input"
#define XML_OUTPUTPART      "Output"

#define XML_FALSE        "false"
#define XML_TRUE        "true"

// Define different read mode
#define READMODE_NORMAL        1
#define READMODE_OLD        2
#define READMODE_CONVERTING_ONB    3

#define XML_GRAPHCELL_OMCPLOT "OMCPlot"
#define XML_GRAPHCELL_TITLE "Title"
#define XML_GRAPHCELL_GRID "Grid"
#define XML_GRAPHCELL_PLOTTYPE "PlotType"
#define XML_GRAPHCELL_LOGX "LogX"
#define XML_GRAPHCELL_LOGY "LogY"
#define XML_GRAPHCELL_XLABEL "XLabel"
#define XML_GRAPHCELL_YLABEL "YLabel"
#define XML_GRAPHCELL_XRANGE_MIN "XRangeMin"
#define XML_GRAPHCELL_XRANGE_MAX "XRangeMax"
#define XML_GRAPHCELL_YRANGE_MIN "YRangeMin"
#define XML_GRAPHCELL_YRANGE_MAX "YRangeMax"
#define XML_GRAPHCELL_CURVE_WIDTH "CurveWidth"
#define XML_GRAPHCELL_CURVE_STYLE "CurveStyle"
#define XML_GRAPHCELL_LEGENDPOSITION "LegendPosition"
#define XML_GRAPHCELL_FOOTER "Footer"
#define XML_GRAPHCELL_AUTOSCALE "AutoScale"

#define XML_GRAPHCELL_CURVE "Curve"
#define XML_GRAPHCELL_XDATA "XData"
#define XML_GRAPHCELL_YDATA "YData"
#define XML_GRAPHCELL_VISIBLE "Visible"
#define XML_GRAPHCELL_COLOR "Color"

#define XML_GRAPHCELL_DATA "Data"
#define XML_GRAPHCELL_AREA  "Area"

#define XML_GRAPHCELL_GRAPH  "Graph"
#define XML_GRAPHCELL_SHAPE "Shape"
