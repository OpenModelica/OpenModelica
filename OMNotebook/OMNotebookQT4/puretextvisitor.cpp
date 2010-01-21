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
 * \file puretextvisitor.cpp
 * \author Anders Fernström
 */

// QT Headers
#include <QtCore/QFile>
#include <QtCore/QTextStream>

//IAEX Headers
#include "puretextvisitor.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellcursor.h"
#include "celldocument.h"
#include "graphcell.h"


namespace IAEX
{
	/*!
	 * \class PureTextVisitor
	 * \date 2005-11-21
	 *
	 * \brief Export contents in a document to a file as pure text
	 *
	 * Traverses the cellstructure and export the text inside textcells
	 * and inputcells to a file, as pure/plain text.
	 */

	/*!
	 * \author Anders Fernström
	 *
	 * \brief The class constructor
	 */
	PureTextVisitor::PureTextVisitor(QFile *file)
	{
		ts_ = new QTextStream( file );
	}

	/*!
	 * \author Anders Fernström
	 *
	 * \brief The class deconstructor
	 */
	PureTextVisitor::~PureTextVisitor()
	{
		delete ts_;
	}

	// CELL
	void PureTextVisitor::visitCellNodeBefore(Cell *)
	{}

	void PureTextVisitor::visitCellNodeAfter(Cell *)
	{}

	// GROUPCELL
	void PureTextVisitor::visitCellGroupNodeBefore(CellGroup *node)
	{}

	void PureTextVisitor::visitCellGroupNodeAfter(CellGroup *)
	{}

	// TEXTCELL
	void PureTextVisitor::visitTextCellNodeBefore(TextCell *node)
	{
		node->viewExpression(false);

		// remove img tag before exporting
		int pos = 0;
		QString html = node->textHtml();
		while( true )
		{
			int start = html.indexOf( "<img src=", pos, Qt::CaseInsensitive );
			if( 0 <= start )
			{
				int end = html.indexOf( "/>", start, Qt::CaseInsensitive );
				if( 0 <= end )
				{
					html.remove( start, (end - start) + 2 );
					pos = start;
				}
				else
					break;
			}
			else
				break;
		}
		QTextEdit tmp;
		tmp.setHtml( html );

		// 2006-03-03 AF, export chapter counter
		if( !node->ChapterCounter().isNull() )
			(*ts_) << node->ChapterCounter() << QString(" ");

		(*ts_) << tmp.toPlainText();
		(*ts_) << "\r\n\r\n\r\n";
	}

	void PureTextVisitor::visitTextCellNodeAfter(TextCell *)
	{}

	//INPUTCELL
	void PureTextVisitor::visitInputCellNodeBefore(InputCell *node)
	{
		// 2006-03-03 AF, export chapter counter
		if( !node->ChapterCounter().isNull() )
			(*ts_) << node->ChapterCounter() << QString(" ");

		(*ts_) << node->text();
		(*ts_) << QString( "\r\n\r\n" );

		// 2006-03-03 AF, export output if not an image
		if( node->textOutputHtml().indexOf( "<img src=", 0, Qt::CaseInsensitive ) < 0 )
		{
			(*ts_) << node->textOutput();
			(*ts_) << QString( "\r\n\r\n\r\n" );
		}
	}

	void PureTextVisitor::visitInputCellNodeAfter(InputCell *)
	{}

	//GRAPHCELL

	void PureTextVisitor::visitGraphCellNodeBefore(GraphCell *node)
	{
		// 2006-03-03 AF, export chapter counter
		if( !node->ChapterCounter().isNull() )
			(*ts_) << node->ChapterCounter() << QString(" ");

		(*ts_) << node->text();
		(*ts_) << QString( "\r\n\r\n" );

		// 2006-03-03 AF, export output if not an image
		if( node->textOutputHtml().indexOf( "<img src=", 0, Qt::CaseInsensitive ) < 0 )
		{
			(*ts_) << node->textOutput();
			(*ts_) << QString( "\r\n\r\n\r\n" );
		}
	}

	void PureTextVisitor::visitGraphCellNodeAfter(GraphCell *)
	{}

	//CELLCURSOR
	void PureTextVisitor::visitCellCursorNodeBefore(CellCursor *)
	{}

	void PureTextVisitor::visitCellCursorNodeAfter(CellCursor *)
	{}
}
