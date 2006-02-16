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
		textcell.setAttribute( XML_STYLE, node->style().name() );

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
		saveImages( textcell, node->textHtml() );

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
		inputcell.setAttribute( XML_STYLE, node->style().name() );

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
		saveImages( inputcell, node->textOutputHtml() );
	
		// Add inputcell element to current element
		currentElement_.appendChild( inputcell );
	}

	void SerializingVisitor::visitInputCellNodeAfter(InputCell *)
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
