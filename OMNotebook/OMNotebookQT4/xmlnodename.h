/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

* Neither the name of Linköpings universitet nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
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
