/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet,
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
 * \file xmlparser.cpp
 * \author Anders Fernström (and Ingemar Axelsson)
 * \date 2005-11-30
 *
 * \brief Remake this class to work with the specified xml format that
 * document are to be saved in. The old file have been renamed to 
 * 'xmlparser.cpp.old' /AF
 */


//STD Headers
#include <iostream>
#include <exception>
#include <stdexcept>
#include <string>

//QT Headers
#include <QtCore/QBuffer>
#include <QtCore/QFile>
#include <QtGui/QApplication>
#include <QtXml/QDomNode>

//IAEX Headers
#include "xmlparser.h"
#include "factory.h"
#include "inputcell.h"
#include "textcell.h"
#include "celldocument.h"


using namespace std;

namespace IAEX
{
	/*!
	 * \class XMLParser
	 * \author Anders Fernström (and Ingemar Axelsson)
	 *
	 * \brief Open an XML file and read the content. The xmlparser support
	 * two different read modes:
	 * READMODE_NORMAL	: Read the xml file normaly
	 * READMODE_OLD		: Read the xml file accordantly to the old xml 
	 *					  format used by OMNotebook.
	 */


	/*! 
	 * \author Anders Fernström (and Ingemar Axelsson)
	 * \date 2005-11-30 (update)
	 *
	 * \brief The class constructor
	 *
	 * 2005-11-30 AF, This class was remade when another xml format 
	 * was used to save the cell structure.
	 */
	XMLParser::XMLParser( const QString filename, Factory *factory, 
		Document *document, int readmode )
		: filename_( filename ), 
		factory_( factory ), 
		doc_( document ),
		readmode_( readmode )
	{
	}
   
   	/*! 
	 * \author Ingemar Axelsson
	 *
	 * \brief The class destructor
	 */
	XMLParser::~XMLParser()
	{}

	/*! 
	 * \author Anders Fernström
	 *
	 * \brief Open the xml file and check what readmode to use
	 */
	Cell *XMLParser::parse()
	{
		QDomDocument domdoc( "OMNotebook" );
		
		// open file and set content to the dom document
		QFile file( filename_ );
		if( !file.open( QIODevice::ReadOnly ))
		{
			string msg = "Could not open " + filename_.toStdString();
			throw exception( msg.c_str() );
		}
		
		if( !domdoc.setContent( &file ))
		{
			file.close();
			string msg = "Could not understand content of " + filename_.toStdString();
			throw exception( msg.c_str() );
		}
		file.close();

		// go to correct parse function
		try
		{
			switch( readmode_ )
			{
			case READMODE_NORMAL:
				return parseNormal( domdoc );
			case READMODE_OLD:
				return parseOld( domdoc );
			default:
				break;
			}
		}
		catch( exception &e )
		{
			throw e;
		}
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-30
	 *
	 * \brief Parse the xml file using NORMAL readmode
	 *
	 * \param domdoc The QDomDocument that should be parsed.
	 */	
	Cell *XMLParser::parseNormal( QDomDocument &domdoc )
	{
		// Create a root element
		QDomElement root = domdoc.documentElement();

		// Check if correct root, otherwise throw exception
		if( root.toElement().tagName() != XML_NOTEBOOK )
		{
			string msg = "Wrong root node (" + root.toElement().tagName().toStdString() +
				") in file " + filename_.toStdString();
			throw exception( msg.c_str() );
		}

		// Remove first cellgroup.
		QDomNode node = root.firstChild();
		if( !node.isNull() )
		{
			QDomElement element = node.toElement();
			if( !element.isNull() )
				if( element.tagName() == XML_GROUPCELL )
					node = element.firstChild();
		}

		// Create the grouppcell that will be the root parent.
		Cell *rootcell = factory_->createCell( "cellgroup", 0 );
		
		try
		{
			if( !node.isNull() )
				traverseCells( rootcell, node );
		}
		catch( exception &e )
		{
			throw e;
		}
		
		// check if root cell is empty
		if( !rootcell->hasChilds() )
		{
			string msg = "File " + filename_.toStdString() + " is empty";
			throw exception( msg.c_str() );
		}

		return rootcell;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-30
	 *
	 * \brief Parse the xml file using OLD readmode
	 *
	 * \param domdoc The QDomDocument that should be parsed.
	 */	
	Cell *XMLParser::parseOld( QDomDocument &domdoc )
	{
		// Create a root element
		QDomElement root = domdoc.documentElement();

		// Check if correct root, otherwise throw exception
		if( root.toElement().tagName() != "Notebook" )
		{
			string msg = "Wrong root node (" + root.toElement().tagName().toStdString() +
				") in file " + filename_.toStdString() + " (Old File)";
			throw exception( msg.c_str() );
		}

		// Remove first cellgroup.
		QDomNode node = root.firstChild();
		if( !node.isNull() )
		{
			QDomElement element = node.toElement();
			if( !element.isNull() )
				if( element.tagName() == "CellGroupData" )
					node = element.firstChild();
		}

		// Create the grouppcell that will be the root parent.
		Cell *rootcell = factory_->createCell( "cellgroup", 0 );
		xmltraverse( rootcell, node );
		return rootcell;
	}


	// READMODE_NORMAL
	// ***************************************************************

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-30
	 * \date 2005-12-01 (update)
	 *
	 * \brief Parse the xml file, check which cell and then call the
	 * correct traverse function; traverseGroupCell(), traverseTextCell(),
	 * traverseInputCell().
	 *
	 * 2005-12-01 AF, Implement function
	 *
	 * \param parent The parent cell
	 * \param element The current QDomElement being parsed
	 */	
	void XMLParser::traverseCells( Cell *parent, QDomNode &node )
	{
		try
		{
			while( !node.isNull() )
			{
				QDomElement element = node.toElement();
				if( !element.isNull() )
				{
					if( element.tagName() == XML_GROUPCELL )
						traverseGroupCell( parent, element );
					else if( element.tagName() == XML_TEXTCELL )
						traverseTextCell( parent, element );
					else if( element.tagName() == XML_INPUTCELL )
						traverseInputCell( parent, element );
					else
					{
						string msg = "Unknow tag name: " + element.tagName().toStdString() + ", in file " + filename_.toStdString();
						throw exception( msg.c_str() );
					}
				}

				node = node.nextSibling();
			}
		}
		catch( exception &e )
		{
			throw e;
		}
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-30
	 * \date 2005-12-01 (update)
	 *
	 * \brief Parse a group cell in the xml file.
	 *
	 * 2005-12-01 AF, Implement function
	 *
	 * \param parent The parent cell to the group cell
	 * \param element The current QDomElement being parsed
	 */	
	void XMLParser::traverseGroupCell( Cell *parent, QDomElement &element )
	{
		Cell *groupcell = factory_->createCell( "cellgroup", parent );

		QDomNode node = element.firstChild();
		if( !node.isNull() )
			traverseCells( groupcell, node.toElement() );

		// check if the groupcell is open or closed
		QString closed = element.attribute( XML_CLOSED, XML_FALSE );
		if( closed == XML_TRUE )
			groupcell->setClosed( true );
		else if( closed == XML_FALSE )
			groupcell->setClosed( false );
		else
			throw exception( "Unknown closed value in group cell" );

		parent->addChild( groupcell );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-30
	 * \date 2005-12-01 (update)
	 *
	 * \brief Parse a text cell in the xml file.
	 *
	 * 2005-12-01 AF, Implement function
	 *
	 * \param parent The parent cell to the text cell
	 * \param element The current QDomElement being parsed
	 */	
	void XMLParser::traverseTextCell( Cell *parent, QDomElement &element )
	{
		// Get the style value
		QString style = element.attribute( XML_STYLE, "Text" );

		// create textcell with the saved style
		Cell *textcell = factory_->createCell( style, parent );

		// go through all children in text cell/element
		QDomNode node = element.firstChild();
		while( !node.isNull() )
		{
			QDomElement e = node.toElement();
			if( !e.isNull() )
			{
				if( e.tagName() == XML_TEXT )
				{
					textcell->setTextHtml( e.text() );
				}
				else if( e.tagName() == XML_RULE )
				{
					textcell->addRule( 
						new Rule( e.attribute( XML_NAME, "" ), e.text() ));
				}
				else if( e.tagName() == XML_IMAGE )
				{
					addImage( textcell, e );
				}
				else
				{
					string msg = "Unknown tagname " + e.tagName().toStdString() + ", in text cell";
					throw exception( msg.c_str() );
				}
			}

			node = node.nextSibling();
		}

		parent->addChild( textcell );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-30
	 * \date 2006-01-17 (update)
	 *
	 * \brief Parse an input cell in the xml file.
	 *
	 * 2005-12-01 AF, Implement function
	 * 2006-01-17 AF, Added support for closed value in the inputcell
	 *
	 * \param parent The parent cell to the input cell
	 * \param element The current QDomElement being parsed
	 */	
	void XMLParser::traverseInputCell( Cell *parent, QDomElement &element )
	{
		// Get the style value
		QString style = element.attribute( XML_STYLE, "Input" );

		// create inputcell with the saved style
		Cell *inputcell = factory_->createCell( style, parent );

		// go through all children in input cell/element
		QDomNode node = element.firstChild();
		while( !node.isNull() )
		{
			QDomElement e = node.toElement();
			if( !e.isNull() )
			{
				if( e.tagName() == XML_INPUTPART )
				{
					inputcell->setText( e.text() );
				}
				else if( e.tagName() == XML_OUTPUTPART )
				{
					InputCell *iCell = dynamic_cast<InputCell*>(inputcell);

					if( iCell->isPlot() )
						iCell->setTextOutputHtml( e.text() );
					else
						iCell->setTextOutput( e.text() );
				}
				else if( e.tagName() == XML_RULE )
				{
					inputcell->addRule( 
						new Rule( e.attribute( XML_NAME, "" ), e.text() ));
				}
				else if( e.tagName() == XML_IMAGE )
				{
					addImage( inputcell, e );
				}
				else
				{
					string msg = "Unknown tagname " + e.tagName().toStdString() + ", in input cell";
					throw exception( msg.c_str() );
				}
			}

			node = node.nextSibling();
		}

		// 2006-01-17 AF, check if the inputcell is open or closed
		QString closed = element.attribute( XML_CLOSED, XML_FALSE );
		if( closed == XML_TRUE )
			inputcell->setClosed( true );
		else if( closed == XML_FALSE )
			inputcell->setClosed( false );
		else
			throw exception( "Unknown closed value in inputcell" );

		parent->addChild( inputcell );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-30
	 * \date 2005-12-01 (update)
	 *
	 * \brief Parse an image element in the xml file.
	 *
	 * 2005-12-01 AF, Implement function
	 *
	 * \param parent The cell that the image should be added to
	 * \param element The current QDomElement containing the image
	 */	
	void XMLParser::addImage( Cell *parent, QDomElement &element )
	{
		// Create a new image
		QImage *image = new QImage();

		// Get saved image name
		QString imagename = element.attribute( XML_NAME, "" );
		if( imagename.isEmpty() || imagename.isNull() )
			throw exception( "No name in image tag" );

		// Get saved image data
		QByteArray imagedata = QByteArray::fromBase64( element.text().toLatin1() );

		// Create image of image data
		QBuffer imagebuffer( &imagedata );
		imagebuffer.open( QBuffer::ReadOnly );
		QDataStream imagestream( &imagebuffer );
		imagestream >> *image;
		imagebuffer.close();

		if( !image->isNull() )
		{
			QString newname = doc_->addImage( image );

			// replace old imagename with the new name
			if( typeid(TextCell) == typeid(*parent) )
			{
				QString html = parent->textHtml();
				html.replace( imagename, newname );
				parent->setTextHtml( html );
			}
			else if( typeid(InputCell) == typeid(*parent) )
			{
				InputCell *inputcell = dynamic_cast<InputCell*>(parent);

				QString html = inputcell->textOutputHtml();
				html.replace( imagename, newname );
				inputcell->setTextOutputHtml( html );
			}
			else
			{
				string msg = "Unknown typeid of parent cell";
				throw exception( msg.c_str() );
			}
		}
		else
		{	
			string msg = "Error creating image: <"+ imagename.toStdString() +">";
			throw exception( msg.c_str() );
		}
	}


	// READMODE_OLD
	// ***************************************************************

	/*! 
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-12-01 (update)
	 *
	 * \brief Method for tracersing through the xmlfile (old format)
	 *
	 * 2005-12-01 AF, Changed some small things to fit the new xmlparser,
	 * but most of the function is taken from the old xmlparser class
	 */
	void XMLParser::xmltraverse( Cell *parent, QDomNode &node )
	{
		while( !node.isNull())
		{
			QDomElement e = node.toElement();
			if(!e.isNull())
			{
				if(e.tagName() == "CellGroupData")
				{	       
					Cell *aGroup = factory_->createCell("cellgroup", parent);

					QDomNode p = e.firstChild();
					xmltraverse( aGroup, p );

					QString qbool = e.attribute("closed");
					if( qbool.toLower() == "0" )
						aGroup->setClosed( false );
					else
						aGroup->setClosed( true );
					
					parent->addChild(aGroup);
				}
				else if(e.tagName() == "Cell")
				{
					// ignore imagecells
					if( e.attribute("style") != "Image" )
					{
						Cell *aCell = factory_->createCell(e.attribute("style"), parent);
						aCell->setText(e.text());
						aCell->setStyle( e.attribute("style") );

						parent->addChild( aCell );
					}
				}
				else
				{
					string msg = "Unknown tag: <"+ e.tagName().toStdString() +">";
					throw exception( msg.c_str() );
				}
			}
			node = node.nextSibling();
		}


	}


};
