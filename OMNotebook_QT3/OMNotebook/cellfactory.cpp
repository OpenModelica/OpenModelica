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

#include <qobject.h>
#include <qmessagebox.h>

#include "cellfactory.h"
#include "textcell.h"
#include "inputcell.h"
#include "imagecell.h"
#include "cellgroup.h"
#include "cellcursor.h"
#include "stylesheet.h"

//MODEQ Headersm
//#ifdef MODEQ
#include "omcinteractiveenvironment.h"
#include "modelicahighlighter.h"
//#else
//#include "smlinteractiveenvironment.h"
//#include "smlhighlighter.h"
//#endif

namespace IAEX
{
   
   CellFactory::CellFactory(Document *doc) : doc_(doc){}

   CellFactory::~CellFactory()
   {}
   
    /*!
     *
     * \todo Remove document dependency from Cellstructure. It is only
     * used to point to a commandcenter (in this case the current
     * document) and for the click event to get the current
     * cursor. This can be done in some better way. Maybe by sending a
     * signal to the document instead.
     *
     * \todo Refactor the creation of image cells. Where should the
     * filename come from? As it is now it is hardcoded. A possible
     * solution is to add a new createCell method that adds a parameter
     * for the filename. Check for the correct style. If it is not a
     * correct style that uses the filename parameter then send the
     * style to the original createCell method. There is a lot of
     * problems with this method.
     *
     */
	Cell *CellFactory::createCell(const QString &style, Cell *parent)
	{
		if(style == "input" || style == "Input" || style == "ModelicaInput")
		{
			InputCell *text = new InputCell(parent);
			text->setStyle("Input");

			text->setDelegate(new OmcInteractiveEnvironment());

			// 2005-10-03 AF, added this try-catch check
			try
			{
				text->setSyntaxHighlighter(new ModelicaHighlighter());
			}
			catch( exception &e )
			{
				QString msg = e.what();
				msg += "\nNo syntax highlighting will be avalible.";
				QMessageBox::warning( 0, "Warning", msg, "OK" );
			}

			QObject::connect(text, SIGNAL(cellselected(Cell *,Qt::ButtonState)),
				doc_, SLOT(selectedACell(Cell*,Qt::ButtonState)));
			QObject::connect(text, SIGNAL(clicked(Cell *)),
				doc_, SLOT(mouseClickedOnCell(Cell*)));
			//QObject::connect(text, SIGNAL(openLink(QUrl*)),
			//		  doc_, SLOT(linkClicked(QUrl*)));

			return text;
		}
		else if( style == "cursor")
		{
			return new CellCursor(parent);
		}
		else if(style == "cellgroup")
		{
			Cell *text = new CellGroup(parent);
			QObject::connect(text, SIGNAL(cellOpened(Cell *, const bool)),
				doc_, SLOT(cursorMoveAfter(Cell*, const bool)));
			QObject::connect(text, SIGNAL(cellselected(Cell *, Qt::ButtonState)),
				doc_, SLOT(selectedACell(Cell*, Qt::ButtonState)));
			QObject::connect(text, SIGNAL(clicked(Cell *)),
				doc_, SLOT(mouseClickedOnCell(Cell*)));
			QObject::connect(text, SIGNAL(openLink(QUrl*)),
				doc_, SLOT(linkClicked(QUrl*)));
			return text;
		}
		else //All other styles will be implemented with a TextCell.
		{
			TextCell *text = new TextCell(parent);
			QObject::connect(text, SIGNAL(cellselected(Cell *, Qt::ButtonState)),
				doc_, SLOT(selectedACell(Cell*, Qt::ButtonState)));
			QObject::connect(text, SIGNAL(clicked(Cell *)),
				doc_, SLOT(mouseClickedOnCell(Cell*)));
			QObject::connect(text, SIGNAL(openLink(QUrl*)),
				doc_, SLOT(linkClicked(QUrl*)));
			// 	 QObject::connect(doc_, SIGNAL(viewExpression(const bool)),
			// 			  text, SLOT(viewExpression(const bool)));

			QString style_ = style;

			if(style_ == QString::null)
				style_ = QString("Text");

			//Stylesheet *stylesheet = Stylesheet::instance("stylesheet.xml");
			//stylesheet->getStyle(text, style_);
			text->setStyle(style_);

			return text; 
		}
	}

   Cell *CellFactory::createCell(const QString &filename, 
	   const QString &style, Cell *parent)
   {
	   if( style == "Image")
	   {	 
		   return new ImageCell(filename, parent);
	   }
	   else
		   return createCell(style, parent);
   }
}
