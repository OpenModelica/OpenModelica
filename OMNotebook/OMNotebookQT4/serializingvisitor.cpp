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

// REMADE LARGE PART OF THIS CLASS 2005-11-30 /AF

/*! 
* \file serializingvisitor.cpp
* \author Anders Fernström (and Ingemar Axelsson)
* \date 2005-11-30
*
* \brief Remake this class to work with the specified xml format that
* document are to be saved in. The old file have been renamed to 
* 'serializingvisitor.cpp.old' /AF
*/


//STD Headers
#include <iostream>

// QT Headers
#include <QtCore/QBuffer>
#include <QtCore/QDataStream>
#include <QtXml/QDomDocument>
#include <QtXml/QDomElement>

//IAEX Headers
#include "serializingvisitor.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellcursor.h"
#include "celldocument.h"
#include "xmlnodename.h"
#include "graphcell.h"
#include <QDataStream>
#include <QGraphicsRectItem>


namespace IAEX
{
	/*! 
	 * \class SerializingVisitor
	 * \date 2005-11-30 (update)
	 *
	 * \brief Saves a celltree to an xml file, by converting cell
	 * structure to XML.
	 *
	 * Traverses the cellstructure and creates a serialized 
	 * stream of the internal representation of the document.
	 *
	 * 2005-11-30 AF, This class was remade when another xml format 
	 * was used to save the cell structure.
	 */

	/*! 
	 * \author Anders Fernström and Ingemar Axelsson
	 * \date 2005-11-30 (update)
	 *
	 * \brief The class constructor
	 */
	SerializingVisitor::SerializingVisitor( QDomDocument &domdoc, Document* doc)
		: domdoc_(domdoc), 
		doc_(doc)
	{
		currentElement_ = domdoc_.createElement( XML_NOTEBOOK );
		domdoc_.appendChild( currentElement_ );
	}

	/*! 
	 * \author Ingemar Axelsson
	 *
	 * \brief The class deconstructor
	 */
	SerializingVisitor::~SerializingVisitor()
	{}


	// CELL
	// ******************************************************************
	void SerializingVisitor::visitCellNodeBefore(Cell *)
	{}

	void SerializingVisitor::visitCellNodeAfter(Cell *)
	{}


	// GROUPCELL
	// ******************************************************************
	void SerializingVisitor::visitCellGroupNodeBefore(CellGroup *node)
	{
		parents_.push( currentElement_ );
		QDomElement groupcell = domdoc_.createElement( XML_GROUPCELL );
		currentElement_.appendChild( groupcell );

		if( node->isClosed() )
			groupcell.setAttribute( XML_CLOSED, XML_TRUE );
		else
			groupcell.setAttribute( XML_CLOSED, XML_FALSE );

		// set the new current element
		currentElement_ = groupcell;
	}

	void SerializingVisitor::visitCellGroupNodeAfter(CellGroup *)
	{
		currentElement_ = parents_.top();
		parents_.pop();
	}


	// TEXTCELL
	// ******************************************************************
	void SerializingVisitor::visitTextCellNodeBefore(TextCell *node)
	{
		QDomElement textcell = domdoc_.createElement( XML_TEXTCELL );

		// Make sure that the text is viewed correct
		node->viewExpression(false);

		// Add style setting to textcell element
		textcell.setAttribute( XML_STYLE, node->style()->name() );

		// Create an text element and append an text node to the element
		QDomElement textelement = domdoc_.createElement( XML_TEXT );
		QDomText textnode = domdoc_.createTextNode( node->textHtml() );
		textelement.appendChild( textnode );
		textcell.appendChild( textelement );

		// Creates ruleelemetns
		Cell::rules_t r = node->rules();
		Cell::rules_t::const_iterator r_iter = r.begin();
		for( ; r_iter != r.end(); ++r_iter )
		{
			QDomElement ruleelement = domdoc_.createElement( XML_RULE );
			ruleelement.setAttribute( XML_NAME, (*r_iter)->attribute() );

			QDomText rulenode = domdoc_.createTextNode( (*r_iter)->value() );
			ruleelement.appendChild( rulenode );

			textcell.appendChild( ruleelement );
		}

		// Check if any image have been include in the text and add them
		// to the the the textcell element
		QString xoyz = node->textHtml();
		saveImages( textcell, xoyz );

		// Add textcell element to current element
		currentElement_.appendChild( textcell );
	}

	void SerializingVisitor::visitTextCellNodeAfter(TextCell *)
	{}


	//INPUTCELL
	// ******************************************************************
	void SerializingVisitor::visitInputCellNodeBefore(InputCell *node)
	{
		QDomElement inputcell = domdoc_.createElement( XML_INPUTCELL );

		// Add style setting to inputcell element
		inputcell.setAttribute( XML_STYLE, node->style()->name() );

		// Add close setting to inputcell element
		if( node->isClosed() )
			inputcell.setAttribute( XML_CLOSED, XML_TRUE );
		else
			inputcell.setAttribute( XML_CLOSED, XML_FALSE );

		// Create an text element (for input) and append it to the element
		QDomElement inputelement = domdoc_.createElement( XML_INPUTPART );
		QDomText inputnode = domdoc_.createTextNode( node->text() );
		inputelement.appendChild( inputnode );
		inputcell.appendChild( inputelement );

		// Create an text element (for output) and append it to the element
		QDomElement outputelement = domdoc_.createElement( XML_OUTPUTPART );
		
		QDomText outputnode;
		if( node->isPlot() )
			outputnode = domdoc_.createTextNode( node->textOutputHtml() );
		else
			outputnode = domdoc_.createTextNode( node->textOutput() );

		outputelement.appendChild( outputnode );
		inputcell.appendChild( outputelement );

		// Creates ruleelemetns
		Cell::rules_t r = node->rules();
		Cell::rules_t::const_iterator r_iter = r.begin();
		for( ; r_iter != r.end(); ++r_iter )
		{
			QDomElement ruleelement = domdoc_.createElement( XML_RULE );
			ruleelement.setAttribute( XML_NAME, (*r_iter)->attribute() );

			QDomText rulenode = domdoc_.createTextNode( (*r_iter)->value() );
			ruleelement.appendChild( rulenode );

			inputcell.appendChild( ruleelement );
		}

		// Check if any image have been include in the text and add them
		// to the the the inputcell element
		QString xoyz = node->textOutputHtml();
		saveImages( inputcell, xoyz );
	
		// Add inputcell element to current element
		currentElement_.appendChild( inputcell );
	}

	void SerializingVisitor::visitInputCellNodeAfter(InputCell *)
	{}

	//GRAPHCELL
	// ******************************************************************
	void SerializingVisitor::visitGraphCellNodeBefore(GraphCell *node)
	{
		QDomElement graphcell = domdoc_.createElement( XML_GRAPHCELL );

		// Add style setting to inputcell element
		graphcell.setAttribute( XML_STYLE, node->style()->name() );

		// Add close setting to inputcell element
		if( node->isClosed() )
			graphcell.setAttribute( XML_CLOSED, XML_TRUE );
		else
			graphcell.setAttribute( XML_CLOSED, XML_FALSE );

		QBuffer b;
		b.open( QBuffer::WriteOnly );
		QDataStream ds( &b );

		ds << node->compoundwidget->gwMain->mapToScene(node->compoundwidget->gwMain->rect()).boundingRect();
		b.close();


		graphcell.setAttribute( XML_GRAPHCELL_AREA, QString(b.data().toBase64().data()));

		graphcell.setAttribute( XML_GRAPHCELL_LEGEND, node->compoundwidget->legendFrame->isVisible()?XML_TRUE:XML_FALSE);
		graphcell.setAttribute( XML_GRAPHCELL_AA, node->compoundwidget->gwMain->antiAliasing?XML_TRUE:XML_FALSE );
		graphcell.setAttribute( XML_GRAPHCELL_LOGX, node->compoundwidget->gwMain->xLog?XML_TRUE:XML_FALSE );
		graphcell.setAttribute( XML_GRAPHCELL_LOGY, node->compoundwidget->gwMain->yLog?XML_TRUE:XML_FALSE );
		graphcell.setAttribute( XML_GRAPHCELL_TITLE, node->compoundwidget->plotTitle->text());
		graphcell.setAttribute( XML_GRAPHCELL_XLABEL, node->compoundwidget->xLabel->text() );
		graphcell.setAttribute( XML_GRAPHCELL_YLABEL, node->compoundwidget->yLabel->text() );
		graphcell.setAttribute( XML_GRAPHCELL_GRID, node->compoundwidget->gwMain->graphicsScene->gridVisible?XML_TRUE:XML_FALSE );
		graphcell.setAttribute( XML_GRAPHCELL_GRIDAUTOX, node->compoundwidget->gwMain->fixedXSize?XML_FALSE:XML_TRUE );
		graphcell.setAttribute( XML_GRAPHCELL_GRIDAUTOY, node->compoundwidget->gwMain->fixedYSize?XML_FALSE:XML_TRUE );

		graphcell.setAttribute( XML_GRAPHCELL_GRIDMAJORX, QVariant(node->compoundwidget->gwMain->xMajorDist).toString());
		graphcell.setAttribute( XML_GRAPHCELL_GRIDMAJORY, QVariant(node->compoundwidget->gwMain->yMajorDist).toString() );
		graphcell.setAttribute( XML_GRAPHCELL_GRIDMINORX, QVariant(node->compoundwidget->gwMain->xMinorDist).toString());
		graphcell.setAttribute( XML_GRAPHCELL_GRIDMINORY, QVariant(node->compoundwidget->gwMain->yMinorDist).toString());



for(int i = 0; i < node->compoundwidget->gwMain->variableData.size(); ++i)
{

		QDomElement data = domdoc_.createElement(XML_GRAPHCELL_DATA);

		data.setAttribute(XML_GRAPHCELL_LABEL, node->compoundwidget->gwMain->variableData[i]->variableName());
		data.setAttribute(XML_GRAPHCELL_ID, "0");



		QBuffer b;
		b.open( QBuffer::WriteOnly );
		QDataStream ds( &b );

		ds << *(node->compoundwidget->gwMain->variableData[i]);
		b.close();

	
		QDomText dnode = domdoc_.createTextNode(b.buffer().toBase64());
		data.appendChild(dnode);
		graphcell.appendChild(data);
}

for(int i = 0; i < node->compoundwidget->gwMain->curves.size(); ++i)
{
		QDomElement graph = domdoc_.createElement(XML_GRAPHCELL_GRAPH);
		if(node->compoundwidget->gwMain->curves[i]->visible)
			graph.setAttribute(XML_GRAPHCELL_LINE, XML_TRUE);
		else
			graph.setAttribute(XML_GRAPHCELL_LINE, XML_FALSE);

		if(node->compoundwidget->gwMain->curves[i]->drawPoints)
			graph.setAttribute(XML_GRAPHCELL_POINTS, XML_TRUE);
		else
			graph.setAttribute(XML_GRAPHCELL_POINTS, XML_FALSE);

		graph.setAttribute(XML_GRAPHCELL_COLOR, QVariant(node->compoundwidget->gwMain->curves[i]->color_).toString());
		
		if(node->compoundwidget->gwMain->curves[i]->interpolation = INTERPOLATION_NONE)
			graph.setAttribute(XML_GRAPHCELL_INTERPOLATION, XML_GRAPHCELL_NONE);
		else if(node->compoundwidget->gwMain->curves[i]->interpolation = INTERPOLATION_LINEAR)
			graph.setAttribute(XML_GRAPHCELL_INTERPOLATION, XML_GRAPHCELL_LINEAR);
		else if(node->compoundwidget->gwMain->curves[i]->interpolation = INTERPOLATION_CONSTANT)
			graph.setAttribute(XML_GRAPHCELL_INTERPOLATION, XML_GRAPHCELL_CONSTANT);

		graph.setAttribute(XML_GRAPHCELL_X, node->compoundwidget->gwMain->curves[i]->x->variableName());
		graph.setAttribute(XML_GRAPHCELL_Y, node->compoundwidget->gwMain->curves[i]->y->variableName());

		graphcell.appendChild(graph);
}

QList<QGraphicsItem*> l = node->compoundwidget->gwMain->graphicsItems->children();

for(int i = 0; i < l.size(); ++i)
{
	QBuffer b;
	b.open( QBuffer::WriteOnly );
	QDataStream ds( &b );
	ds.setVersion(QDataStream::Qt_4_2);

	QDomElement shape = domdoc_.createElement(XML_GRAPHCELL_SHAPE);
	QString type;

	if(QGraphicsRectItem* r =dynamic_cast<QGraphicsRectItem*>(l[i]))
	{
		type = XML_GRAPHCELL_RECT;		
		ds << r->rect() << r->pen() << r->brush();
	}
	else if(QGraphicsEllipseItem* r =dynamic_cast<QGraphicsEllipseItem*>(l[i]))
	{
		type = XML_GRAPHCELL_ELLIPSE;		
		ds << r->rect() << r->pen() << r->brush();

	}
	else if(QGraphicsLineItem* r =dynamic_cast<QGraphicsLineItem*>(l[i]))
	{
		type = XML_GRAPHCELL_LINE;		
		ds << r->line() << r->pen();
	}

	shape.setAttribute(XML_GRAPHCELL_SHAPETYPE, type);		

	b.close();
	shape.setAttribute( XML_GRAPHCELL_SHAPEDATA, QString(b.data().toBase64().data()));

	graphcell.appendChild(shape);
}

		// Create an text element (for input) and append it to the element
		QDomElement textelement = domdoc_.createElement( XML_INPUTPART );
		QDomText textnode = domdoc_.createTextNode( node->text() );
		textelement.appendChild( textnode );
		graphcell.appendChild( textelement );


		// Create an text element (for output) and append it to the element
		QDomElement outputelement = domdoc_.createElement( XML_OUTPUTPART );
		
		QDomText outputnode;
		if( node->isPlot() )
			outputnode = domdoc_.createTextNode( node->textOutputHtml() );
		else
			outputnode = domdoc_.createTextNode( node->textOutput() );

		outputelement.appendChild( outputnode );
		graphcell.appendChild( outputelement );
/*
		// Create an text element (for output) and append it to the element
		QDomElement outputelement = domdoc_.createElement( XML_OUTPUTPART );
		
		QDomText outputnode;
		outputnode = domdoc_.createTextNode( node->textOutput() );

		outputelement.appendChild( outputnode );
		graphcell.appendChild( outputelement );
*/
		// Creates ruleelemetns
		Cell::rules_t r = node->rules();
		Cell::rules_t::const_iterator r_iter = r.begin();
		for( ; r_iter != r.end(); ++r_iter )
		{
			QDomElement ruleelement = domdoc_.createElement( XML_RULE );
			ruleelement.setAttribute( XML_NAME, (*r_iter)->attribute() );

			QDomText rulenode = domdoc_.createTextNode( (*r_iter)->value() );
			ruleelement.appendChild( rulenode );

			graphcell.appendChild( ruleelement );
		}

		// Check if any image have been include in the text and add them
		// to the the the inputcell element
		QString xoyz = node->textOutputHtml();
		saveImages( graphcell, xoyz );

		// Add inputcell element to current element
		currentElement_.appendChild( graphcell );
	}

	void SerializingVisitor::visitGraphCellNodeAfter(GraphCell *)
	{}

	//CELLCURSOR
	// ******************************************************************
	void SerializingVisitor::visitCellCursorNodeBefore(CellCursor *)
	{}     

	void SerializingVisitor::visitCellCursorNodeAfter(CellCursor *)
	{}


	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-30
	 * \date 2005-12-12 (update)
	 *
	 * \brief Look through a html text and find all the images included.
	 * When a image is found the images is saved to the xml file and
	 * included in the current element
	 *
	 * 2005-12-12 AF, Added support for pasting images from clipboard
	 */
	void SerializingVisitor::saveImages( QDomElement &current, QString &text )
	{
		int pos(0);
		while( true )
		{
			int start = text.indexOf( "<img src=", pos, Qt::CaseInsensitive );
			if( 0 <= start )
			{ 
				// found an image
				start += 10; // pos of first letter in imagename
				int end = text.indexOf( "\"", start );

				// get the image name
				QString imagename = text.mid( start, end - start );

				CellDocument *doc = dynamic_cast<CellDocument*>(doc_);
				QImage *image = doc->getImage( imagename );

				// 2005-12-12 AF, Added support of pasting images from clipboard
				if( image->isNull() )
				{
					// found image that isn't part of the document, 
					// probably images that have been pasted into the text or
					// from copied cell
					QString tmpImagename = imagename;
					tmpImagename.remove( "file:///" );
					image = new QImage( tmpImagename );
				}

				if( !image->isNull() )
				{
					// create element and save the image to file
					QDomElement imageelement = domdoc_.createElement( XML_IMAGE );
					imageelement.setAttribute( XML_NAME, imagename );

					QBuffer buffer;
					buffer.open( QBuffer::WriteOnly );
					QDataStream out( &buffer );
					out << *image;
					buffer.close();
					
					QDomText imagedata = domdoc_.createTextNode( buffer.buffer().toBase64() ); 
					imageelement.appendChild( imagedata );

					current.appendChild( imageelement );
				}

				pos = end + 1;
			}
			else
				break;
		}
	}
} 
