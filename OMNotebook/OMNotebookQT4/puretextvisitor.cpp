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

		(*ts_) << tmp.toPlainText();
		(*ts_) << "\r\n\r\n\r\n";
	}

	void PureTextVisitor::visitTextCellNodeAfter(TextCell *)
	{}

	//INPUTCELL
	void PureTextVisitor::visitInputCellNodeBefore(InputCell *node)
	{
		(*ts_) << node->text();
		(*ts_) << QString( "\r\n\r\n\r\n" );
	}

	void PureTextVisitor::visitInputCellNodeAfter(InputCell *)
	{}

	//CELLCURSOR
	void PureTextVisitor::visitCellCursorNodeBefore(CellCursor *)
	{}      

	void PureTextVisitor::visitCellCursorNodeAfter(CellCursor *)
	{}
} 
