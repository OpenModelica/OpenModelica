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
#include <QPrinter>
#include <QMessageBox>

//IAEX Headers
#include "printervisitor.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellcursor.h"
#include "graphcell.h"

#include <QImage>
#include <QPainter>
#include <QTemporaryFile>
#include <QGraphicsRectItem>
#include "../Pltpkg2/legendLabel.h"
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
	PrinterVisitor::PrinterVisitor( QTextDocument* doc, QPrinter* printer )
		: ignore_(false), firstChild_(true), closedCell_(0), currentTableRow_(0), printer_(printer)
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
//					tableFormatExpression.setBackground( QColor(235, 235, 220) ); // 180, 180, 180
					tableFormatExpression.setBackground( QColor(235, 0, 0) ); // 180, 180, 180

					QVector<QTextLength> constraints;
					constraints << QTextLength(QTextLength::PercentageLength, 100);
					tableFormatExpression.setColumnWidthConstraints(constraints);

					cursor.insertTable( 1, 1, tableFormatExpression );
	QMessageBox::information(0,"uu2", node->text());

					QString html = node->textHtml();
					html += "<br><br>";
					cursor.insertFragment( QTextDocumentFragment::fromHtml( html ));
				}
				else
				{
					QString html = node->textHtml();
					html += "<br><br>";
					html.remove( "file:///" );
					QTextDocumentFragment frgmnt;
					printEditor_->document()->setTextWidth(700);
					cursor.insertFragment(QTextDocumentFragment::fromHtml( html ));
					QMessageBox::information(0, "uu3", node->text());
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
	QMessageBox::information(0, "uu1", node->text());
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

	//GRAPHCELL

	void PrinterVisitor::visitGraphCellNodeBefore(GraphCell *node)
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


					QRect r2 = node->compoundwidget->gwMain->rect();
					r2.setWidth(r2.width()-1);
					r2.setHeight(r2.height()-2);

/*
					QImage qi(r2.size(), QImage::Format_RGB32);

					QPainter qp;
					qp.begin(&qi);


					//For some reason render() uses another background color for negative coordinates. A workaround is to add a white QGraphicsRectItem behind the other objects..
					QRectF rect = node->compoundwidget->gwMain->mapToScene(node->compoundwidget->gwMain->rect()).boundingRect();
					rect.setWidth( rect.width() *2);
					rect.setLeft(rect.left() - rect.width()/2);
					rect.setTop(rect.top() - rect.height()/2);
					rect.setHeight(rect.height() * 2);
					QGraphicsRectItem* r = new QGraphicsRectItem(rect);
					QBrush b(Qt::white);
					r->setBrush(b);
					r->setZValue(-100);
					node->compoundwidget->gwMain->graphicsScene->addItem(r);


					r2 = node->compoundwidget->gwMain->rect();
					node->compoundwidget->gwMain->render(&qp, r2);
					delete r;

					qp.end();


					qi.save(QString("u77.bmp"),"BMP");
*/

//
//					QMessageBox::information(0, "uu", QVariant(node->compoundwidget->rect().width()).toString());
//					QMessageBox::information(0, "uu2", QVariant(printer_->pageRect().width()).toString());
//					QMessageBox::information(0, "uu2", QVariant(printer_->pageRect().height()).toString());

					QImage i3(node->compoundwidget->rect().size(),  QImage::Format_RGB32);
					i3.fill(QColor(Qt::white).rgb());
					QPainter p(&i3);
					QRectF target = QRectF(node->compoundwidget->gwMain->rect());
					target.moveTo(node->compoundwidget->gwMain->pos());
					node->compoundwidget->gwMain->render(&p, target);

					p.drawRect(target);

					target = QRectF(node->compoundwidget->gvLeft->rect());
					target.moveTo(node->compoundwidget->gvLeft->pos());
					node->compoundwidget->gvLeft->render(&p, target);

					target = QRectF(node->compoundwidget->gvBottom->rect());
					target.moveTo(node->compoundwidget->gvBottom->pos());
					node->compoundwidget->gvBottom->render(&p, target);

					node->compoundwidget->yLabel->render(&p, node->compoundwidget->yLabel->pos());
					node->compoundwidget->xLabel->render(&p, node->compoundwidget->xLabel->pos());
					node->compoundwidget->plotTitle->render(&p, node->compoundwidget->plotTitle->pos());


					QList<LegendLabel*> l = node->compoundwidget->legendFrame->findChildren<LegendLabel*>();
					for(int i = 0; i < l.size(); ++i)
						l[i]->render(&p, l[i]->pos()+node->compoundwidget->legendFrame->pos());

					if(node->imageFile)
						delete node->imageFile;

					node->imageFile = new QTemporaryFile("tmpImage_XXXXXX.bmp");
					node->imageFile->open();
					if(i3.width() < printer_->pageRect().width()/8)
						i3.save(node->imageFile, "BMP");
					else
						i3.scaledToWidth(printer_->pageRect().width()/8, Qt::SmoothTransformation).save(node->imageFile, "BMP");

					cursor.insertImage(node->imageFile->fileName());
					node->imageFile->close();

				}
			}

			if( firstChild_ )
				firstChild_ = false;
		}
	}

	void PrinterVisitor::visitGraphCellNodeAfter(GraphCell *)
	{}

	//CELLCURSOR
	void PrinterVisitor::visitCellCursorNodeBefore(CellCursor *)
	{}

	void PrinterVisitor::visitCellCursorNodeAfter(CellCursor *)
	{}
}
