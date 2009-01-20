/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
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
 * \file updatelinkvisitor.cpp
 * \author Anders Fernström
 */

//STD Headers
#include <exception>
#include <stdexcept>

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
			throw runtime_error( msg.c_str() );
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
                    throw runtime_error( msg.c_str() );
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

	//GRAPHCELL
	void UpdateLinkVisitor::visitGraphCellNodeBefore(GraphCell *node)
	{}

	void UpdateLinkVisitor::visitGraphCellNodeAfter(GraphCell *)
	{}


	//CELLCURSOR
	void UpdateLinkVisitor::visitCellCursorNodeBefore(CellCursor *)
	{}

	void UpdateLinkVisitor::visitCellCursorNodeAfter(CellCursor *)
	{}
}
