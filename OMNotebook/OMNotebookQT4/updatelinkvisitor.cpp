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

/*! 
 * \file updatelinkvisitor.cpp
 * \author Anders Fernström
 */

//STD Headers
#include <exception>

//QT Headers
#include <QtCore/QDir>

//IAEX Headers
#include "updatelinkvisitor.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellcursor.h"


namespace IAEX
{
	/*! 
	 * \class UpdateLinkVisitor
	 * \date 2005-12-05
	 *
	 * \brief update any links in textcells to reflect any change in 
	 * folder when saving.
	 */

	/*! 
	 * \author Anders Fernström
	 *
	 * \brief The class constructor
	 */
	UpdateLinkVisitor::UpdateLinkVisitor(QString oldFilepath, QString newFilepath)
	{
		oldDir_.setPath( oldFilepath );
		newDir_.setPath( newFilepath );

		if( !oldDir_.exists() || !newDir_.exists() )
		{
			string msg = "UpdateLink, old or new dir don't exists.";
			throw exception( msg.c_str() );
		}
	}

	/*! 
	 * \author Anders Fernström
	 *
	 * \brief The class deconstructor
	 */
	UpdateLinkVisitor::~UpdateLinkVisitor()
	{}

	// CELL
	void UpdateLinkVisitor::visitCellNodeBefore(Cell *)
	{}

	void UpdateLinkVisitor::visitCellNodeAfter(Cell *)
	{}

	// GROUPCELL
	void UpdateLinkVisitor::visitCellGroupNodeBefore(CellGroup *node)
	{}

	void UpdateLinkVisitor::visitCellGroupNodeAfter(CellGroup *)
	{}

	// TEXTCELL
	void UpdateLinkVisitor::visitTextCellNodeBefore(TextCell *node)
	{
		QString html = node->textHtml();
		int pos(0);
		while( true )
		{
			int startPos = html.indexOf( "<a href=\"", pos, Qt::CaseInsensitive );
			if( 0 <= startPos )
			{
				// add lengt of '<a href="' to startpos
				startPos += 9;

				int endPos = html.indexOf( "\"", startPos, Qt::CaseInsensitive );
				if( 0 <= endPos )
				{
					//a link is found, replace it with new link
					QString oldLink = html.mid( startPos, endPos - startPos );
					QString newLink = newDir_.relativeFilePath( oldDir_.absoluteFilePath( oldLink ));
					html.replace( startPos, endPos - startPos, newLink );

					//cout << "OLD LINK: " << oldLink.toStdString() << endl;
					//cout << "NEW LINK: " << newLink.toStdString() << endl;

					// set pos to the end of the link
					pos = startPos + newLink.length();
				}
				else
				{
					// this should never happen!
					string msg = "Error, found no end of linkpath";
                    throw exception( msg.c_str() );
					break;
				}
			}
			else
				break;
		}

		// set the new html code to the textcell
		node->setTextHtml( html );
	}

	void UpdateLinkVisitor::visitTextCellNodeAfter(TextCell *)
	{}

	//INPUTCELL
	void UpdateLinkVisitor::visitInputCellNodeBefore(InputCell *node)
	{}

	void UpdateLinkVisitor::visitInputCellNodeAfter(InputCell *)
	{}

	//CELLCURSOR
	void UpdateLinkVisitor::visitCellCursorNodeBefore(CellCursor *)
	{}      

	void UpdateLinkVisitor::visitCellCursorNodeAfter(CellCursor *)
	{}
} 
