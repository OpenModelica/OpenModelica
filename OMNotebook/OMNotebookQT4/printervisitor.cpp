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
#include <QtGui/QTextCursor>
#include <QtGui/QTextDocumentFragment>
#include <QtGui/QTextEdit>
#include <QtGui/QTextTable>
#include <QtGui/QTextTableCell>
#include <QtGui/QTextTableFormat>

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
	 * \date 2005-12-19
	 *
	 * \brief The class constructor
	 *
	 * 2006-03-03 AF, Updated function so cells are printed in tables,
	 * so chapter numbers can be added to the left of the text. This
	 * change remade large part of this function (and the rest of the
	 * class).
	 */
	PrinterVisitor::PrinterVisitor( QTextDocument* doc )
		: ignore_(false), firstChild_(true), closedCell_(0), currentTableRow_(0)
	{
		printEditor_ = new QTextEdit();
		printEditor_->setDocument( doc );

		// set table format
		QTextTableFormat tableFormat;
		tableFormat.setBorder( 0 );
		tableFormat.setColumns( 2 );
		tableFormat.setCellPadding( 5 );

		QVector<QTextLength> constraints;
        constraints << QTextLength(QTextLength::FixedLength, 50)
                    << QTextLength(QTextLength::VariableLength, 620);
        tableFormat.setColumnWidthConstraints(constraints);

		// insert the table
		QTextCursor cursor = printEditor_->textCursor();
		table_ = cursor.insertTable(1, 2, tableFormat);
		
	}

	/*! 
	 * \author Anders Fernström
	 *
	 * \brief The class deconstructor
	 */
	PrinterVisitor::~PrinterVisitor()
	{
		delete printEditor_;
	}

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
			++currentTableRow_;
			table_->insertRows( currentTableRow_, 1 );
			
			// first column
			QTextTableCell tableCell( table_->cellAt( currentTableRow_, 0 ) );
			if( tableCell.isValid() )
			{
				if( !node->ChapterCounterHtml().isNull() )
				{
					QTextCursor cursor( tableCell.firstCursorPosition() );
					cursor.insertFragment( QTextDocumentFragment::fromHtml(
						node->ChapterCounterHtml() ));
				}
			}

			// second column
			tableCell = table_->cellAt( currentTableRow_, 1 );
			if( tableCell.isValid() )
			{
				QTextCursor cursor( tableCell.firstCursorPosition() );

				if( node->isViewExpression() )
				{
					//view expression table
					QTextTableFormat tableFormatExpression;
					tableFormatExpression.setBorder( 0 );
					tableFormatExpression.setColumns( 1 );
					tableFormatExpression.setCellPadding( 5 );
					tableFormatExpression.setBackground( QColor(235, 235, 220) ); // 180, 180, 180
					QVector<QTextLength> constraints;
					constraints << QTextLength(QTextLength::PercentageLength, 100);
					tableFormatExpression.setColumnWidthConstraints(constraints);
					
					cursor.insertTable( 1, 1, tableFormatExpression );

					QString html = node->textHtml();
					html += "<br><br>";
					cursor.insertFragment( QTextDocumentFragment::fromHtml( html ));
				}
				else
				{
					QString html = node->textHtml();
					html += "<br><br>";
					html.remove( "file:///" );
					cursor.insertFragment( QTextDocumentFragment::fromHtml( html ));
				}
			}

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
			++currentTableRow_;
			table_->insertRows( currentTableRow_, 1 );
			
			// first column
			QTextTableCell tableCell( table_->cellAt( currentTableRow_, 0 ) );
			if( tableCell.isValid() )
			{
				if( !node->ChapterCounterHtml().isNull() )
				{
					QTextCursor cursor( tableCell.firstCursorPosition() );
					cursor.insertFragment( QTextDocumentFragment::fromHtml(
						node->ChapterCounterHtml() ));
				}
			}

			// second column
			tableCell = table_->cellAt( currentTableRow_, 1 );
			if( tableCell.isValid() )
			{
				QTextCursor cursor( tableCell.firstCursorPosition() );

				// input table
				QTextTableFormat tableFormatInput;
				tableFormatInput.setBorder( 0 );
				tableFormatInput.setMargin( 6 );
				tableFormatInput.setColumns( 1 );
				tableFormatInput.setCellPadding( 8 );
				tableFormatInput.setBackground( QColor(245, 245, 255) ); // 200, 200, 255
				QVector<QTextLength> constraints;
				constraints << QTextLength(QTextLength::PercentageLength, 100);
                tableFormatInput.setColumnWidthConstraints(constraints);
				cursor.insertTable( 1, 1, tableFormatInput );
			
				QString html = node->textHtml();
				html += "<br>";
				if( !node->isEvaluated() || node->isClosed() )
					html += "<br>";
				cursor.insertFragment( QTextDocumentFragment::fromHtml( html ));

				// output table
				if( node->isEvaluated() && !node->isClosed() )
				{
					QTextTableFormat tableFormatOutput;
					tableFormatOutput.setBorder( 0 );
					tableFormatOutput.setMargin( 6 );
					tableFormatOutput.setColumns( 1 );
					tableFormatOutput.setCellPadding( 8 );
					QVector<QTextLength> constraints;
					constraints << QTextLength(QTextLength::PercentageLength, 100);
					tableFormatOutput.setColumnWidthConstraints(constraints);

					cursor = tableCell.lastCursorPosition();
					cursor.insertTable( 1, 1, tableFormatOutput );
					
					QString outputHtml( node->textOutputHtml() );
					outputHtml += "<br><br>";
					outputHtml.remove( "file:///" );
                    cursor.insertFragment( QTextDocumentFragment::fromHtml( outputHtml ));
				}
			}

			/*
			QString html = doc_->toHtml();
			html += "<br><br>" + node->textHtml() + "<br>" + node->textOutputHtml();
			html.remove( "file:///" );
			doc_->setHtml( html );*/

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
