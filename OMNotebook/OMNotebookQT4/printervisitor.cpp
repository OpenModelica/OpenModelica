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
 * \file printervisitor.cpp
 * \author Anders Fernström
 */

//STD Headers
#include <exception>

//QT Headers
#include <QtGui/QTextDocument>

//IAEX Headers
#include "printervisitor.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellcursor.h"


namespace IAEX
{
	/*! 
	 * \class PrinterVisitor
	 * \date 2005-12-19
	 *
	 * \brief creates a new QTextDocument that contaions the documents
	 * enthier text
	 */

	/*! 
	 * \author Anders Fernström
	 *
	 * \brief The class constructor
	 */
	PrinterVisitor::PrinterVisitor( QTextDocument* doc )
		: doc_(doc), ignore_(false), firstChild_(true), closedCell_(0)
	{
	}

	/*! 
	 * \author Anders Fernström
	 *
	 * \brief The class deconstructor
	 */
	PrinterVisitor::~PrinterVisitor()
	{}

	// CELL
	void PrinterVisitor::visitCellNodeBefore(Cell *)
	{}

	void PrinterVisitor::visitCellNodeAfter(Cell *)
	{}

	// GROUPCELL
	void PrinterVisitor::visitCellGroupNodeBefore(CellGroup *node)
	{
		if( node->isClosed() )
		{
			ignore_ = true;
			firstChild_ = true;
			closedCell_ = node;
		}
	}

	void PrinterVisitor::visitCellGroupNodeAfter(CellGroup *node)
	{
		if( ignore_ && closedCell_ == node )
		{
			ignore_ = false;
			firstChild_ = false;
			closedCell_ = 0;
		}
	}

	// TEXTCELL
	void PrinterVisitor::visitTextCellNodeBefore(TextCell *node)
	{
		if( !ignore_ || firstChild_ )
		{
			QString html = doc_->toHtml();
			html += "<br><br>" + node->textHtml();
			html.remove( "file:///" );
			doc_->setHtml( html );

			if( firstChild_ )
				firstChild_ = false;
		}
	}

	void PrinterVisitor::visitTextCellNodeAfter(TextCell *)
	{}

	//INPUTCELL
	void PrinterVisitor::visitInputCellNodeBefore(InputCell *node)
	{
		if( !ignore_ || firstChild_ )
		{
			QString html = doc_->toHtml();
			html += "<br><br>" + node->textHtml() + "<br>" + node->textOutputHtml();
			html.remove( "file:///" );
			doc_->setHtml( html );

			if( firstChild_ )
				firstChild_ = false;
		}
	}

	void PrinterVisitor::visitInputCellNodeAfter(InputCell *)
	{}

	//CELLCURSOR
	void PrinterVisitor::visitCellCursorNodeBefore(CellCursor *)
	{}      

	void PrinterVisitor::visitCellCursorNodeAfter(CellCursor *)
	{}
} 
