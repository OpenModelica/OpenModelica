/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
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
#define XML_NOTEBOOK			"Notebook"

// cell element
#define XML_GROUPCELL			"GroupCell"
#define XML_TEXTCELL			"TextCell"
#define XML_INPUTCELL			"InputCell"
#define XML_GRAPHCELL			"GraphCell"

// attribute
#define XML_CLOSED				"closed"
#define XML_STYLE				"style"
#define XML_NAME				"name"

// child
#define XML_TEXT				"Text"
#define XML_RULE				"Rule"
#define XML_IMAGE				"Image"
#define XML_INPUTPART			"Input"
#define XML_OUTPUTPART			"Output"

#define XML_FALSE				"false"
#define XML_TRUE				"true"

// Define different read mode
#define READMODE_NORMAL				1
#define READMODE_OLD				2
#define READMODE_CONVERTING_ONB		3

#define XML_GRAPHCELL_AREA  "Area"
#define XML_GRAPHCELL_LEGEND  "Legend"
#define XML_GRAPHCELL_AA  "Antialiasing"
#define XML_GRAPHCELL_LOGX  "LogX"
#define XML_GRAPHCELL_LOGY  "LogY"
#define XML_GRAPHCELL_TITLE  "Title"
#define XML_GRAPHCELL_XLABEL  "XLabel"
#define XML_GRAPHCELL_YLABEL  "YLabel"
#define XML_GRAPHCELL_DATA  "Data"
#define XML_GRAPHCELL_LABEL  "Label"
#define XML_GRAPHCELL_ID  "Id"
#define XML_GRAPHCELL_GRAPH  "Graph"
#define XML_GRAPHCELL_LINE  "Line"
#define XML_GRAPHCELL_POINTS  "Points"
#define XML_GRAPHCELL_COLOR  "Color"
#define XML_GRAPHCELL_INTERPOLATION  "Interpolation"
#define XML_GRAPHCELL_LINEAR "Linear"
#define XML_GRAPHCELL_CONSTANT "Constant"
#define XML_GRAPHCELL_NONE "None"
#define XML_GRAPHCELL_X  "X"
#define XML_GRAPHCELL_Y  "Y"
#define XML_GRAPHCELL_SHAPE "Shape"
#define XML_GRAPHCELL_MATRIX "Matrix"
#define XML_GRAPHCELL_GRID "Grid"
#define XML_GRAPHCELL_GRIDAUTOX "AutoX"
#define	XML_GRAPHCELL_GRIDAUTOY "AutoY"
#define XML_GRAPHCELL_GRIDMAJORX "MajorX"
#define XML_GRAPHCELL_GRIDMAJORY "MajorY"
#define XML_GRAPHCELL_GRIDMINORX "MinorX"
#define XML_GRAPHCELL_GRIDMINORY "MinorY"
#define XML_GRAPHCELL_SHOWGRAPH "ShowGraph"
#define XML_GRAPHCELL_SHAPETYPE "Type"
#define XML_GRAPHCELL_SHAPEDATA "Shapedata"

#define XML_GRAPHCELL_RECT "Rect"
#define XML_GRAPHCELL_LINE "Line"
#define XML_GRAPHCELL_ELLIPSE "Ellipse"
