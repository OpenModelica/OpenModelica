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
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#else
#include <QtGui/QTextCursor>
#include <QtGui/QTextDocumentFragment>
#include <QtGui/QTextEdit>
#include <QtGui/QTextTable>
#include <QtGui/QTextTableCell>
#include <QtGui/QTextTableFormat>
#include <QPrinter>
#endif
#include "qwt_plot_renderer.h"

//IAEX Headers
#include "printervisitor.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "latexcell.h"
#include "cellcursor.h"
#include "graphcell.h"

#include <QImage>
#include <QPainter>
#include <QTemporaryFile>
#include <QGraphicsRectItem>
namespace IAEX
{
  /*!
   * \class PrinterVisitor
   * \date 2005-12-19
   *
   * \brief creates a new QTextDocument that contains the documents
   * entire text
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
    tableFormat.setCellPadding( 2 );

    // do not put the constraints on the columns. If we don't have chapter numbers we want to use the full space.
//    QVector<QTextLength> constraints;
//        constraints << QTextLength(QTextLength::PercentageLength, 20)
//                    << QTextLength(QTextLength::PercentageLength, 80);
//        tableFormat.setColumnWidthConstraints(constraints);

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
          tableFormatExpression.setCellPadding( 2 );
//          tableFormatExpression.setBackground( QColor(235, 235, 220) ); // 180, 180, 180
          tableFormatExpression.setBackground( QColor(235, 0, 0) ); // 180, 180, 180

          QVector<QTextLength> constraints;
          constraints << QTextLength(QTextLength::PercentageLength, 100);
          tableFormatExpression.setColumnWidthConstraints(constraints);

          cursor.insertTable( 1, 1, tableFormatExpression );
          // QMessageBox::information(0,"uu2", node->text());

          QString html = node->textHtml();
          cursor.insertFragment( QTextDocumentFragment::fromHtml( html ));
        }
        else
        {
          QString html = node->textHtml();

          html.remove( "file:///" );
          // in printed version link to other printed document
          if (html.contains(".onb\">")) {
            html.replace(".onb\">",".pdf\">");
          }
          if (html.contains(".onb#")) {
            while (html.contains(".onb#")) {
              int pos1 = html.indexOf(".onb#");
              int pos2 = html.indexOf("\">", pos1);
              html.replace(pos1, pos2-pos1, ".pdf");
            }
          }
          printEditor_->document()->setTextWidth(700);
          cursor.insertFragment(QTextDocumentFragment::fromHtml( html ));
          // QMessageBox::information(0, "uu3", node->text());
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
        tableFormatInput.setColumns( 1 );
        tableFormatInput.setCellPadding( 2 );
        tableFormatInput.setBackground( QColor(245, 245, 255) ); // 200, 200, 255

        QVector<QTextLength> constraints;
        constraints << QTextLength(QTextLength::PercentageLength, 100);
                tableFormatInput.setColumnWidthConstraints(constraints);
        cursor.insertTable( 1, 1, tableFormatInput );

        QString html = node->textHtml();
        // QMessageBox::information(0, "uu1", node->text());
        if( !node->isEvaluated() || node->isClosed() )
          html += "<br />";
        cursor.insertFragment( QTextDocumentFragment::fromHtml( html ));

        // output table
        if( node->isEvaluated() && !node->isClosed() )
        {
          QTextTableFormat tableFormatOutput;
          tableFormatOutput.setBorder( 0 );
          tableFormatOutput.setColumns( 1 );
          tableFormatOutput.setCellPadding( 2 );
          QVector<QTextLength> constraints;
          constraints << QTextLength(QTextLength::PercentageLength, 100);
          tableFormatOutput.setColumnWidthConstraints(constraints);

          cursor = tableCell.lastCursorPosition();
          cursor.insertTable( 1, 1, tableFormatOutput );

          QString outputHtml( node->textOutputHtml() );

          outputHtml.remove( "file:///" );
                    cursor.insertFragment( QTextDocumentFragment::fromHtml( outputHtml ));
        }
      }

#if 0
      QString html = doc_->toHtml();
      html += "<br><br>" + node->textHtml() + "<br>" + node->textOutputHtml();
      html.remove( "file:///" );
      doc_->setHtml( html );
#endif

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
        tableFormatInput.setColumns( 1 );
        tableFormatInput.setCellPadding( 2 );
        tableFormatInput.setBackground( QColor(245, 245, 255) ); // 200, 200, 255
        QVector<QTextLength> constraints;
        constraints << QTextLength(QTextLength::PercentageLength, 100);
                tableFormatInput.setColumnWidthConstraints(constraints);
        cursor.insertTable( 1, 1, tableFormatInput );

        QString html = node->textHtml();
        if( !node->isEvaluated() || node->isClosed() )
          html += "<br />";
        cursor.insertFragment( QTextDocumentFragment::fromHtml( html ));

        if( node->isEvaluated() && !node->isClosed() )
        {
          QTextTableFormat tableFormatOutput;
          tableFormatOutput.setBorder( 0 );
          tableFormatOutput.setColumns( 1 );
          tableFormatOutput.setCellPadding( 2 );
          QVector<QTextLength> constraints;
          constraints << QTextLength(QTextLength::PercentageLength, 100);
          tableFormatOutput.setColumnWidthConstraints(constraints);

          cursor = tableCell.lastCursorPosition();
          cursor.insertTable( 1, 1, tableFormatOutput );

          QString outputHtml( node->textOutputHtml() );

          outputHtml.remove( "file:///" );
          cursor.insertFragment( QTextDocumentFragment::fromHtml( outputHtml ));
        }

      }
      // print the plot
      if (node->mpPlotWindow && node->mpPlotWindow->isVisible()) {
        ++currentTableRow_;
        table_->insertRows( currentTableRow_, 1 );

        // first column
        tableCell = table_->cellAt( currentTableRow_, 1 );
        if( tableCell.isValid() )
        {
          QTextCursor cursor( tableCell.firstCursorPosition() );

          // input table
          QTextTableFormat tableFormatInput;
          tableFormatInput.setBorder( 0 );
          tableFormatInput.setColumns( 1 );
          tableFormatInput.setCellPadding( 2 );
          QVector<QTextLength> constraints;
          constraints << QTextLength(QTextLength::PercentageLength, 100);
                  tableFormatInput.setColumnWidthConstraints(constraints);
          cursor.insertTable( 1, 1, tableFormatInput );

          OMPlot::Plot *pPlot = node->mpPlotWindow->getPlot();
          // calculate height for width while preserving aspect ratio.
          int width, height;
          if (pPlot->size().width() > 600) {
            width = 600;
            qreal ratio = (double)pPlot->size().height() / pPlot->size().width();
            height = width * qCeil(ratio);
          } else {
            width = pPlot->size().width();
            height = pPlot->size().height();
          }
          // create a pixmap and render the plot on it
          QPixmap plotPixmap(width, height);
          QwtPlotRenderer plotRenderer;
          plotRenderer.renderTo(pPlot, plotPixmap);
          // insert the pixmap to table
          cursor.insertImage(plotPixmap.toImage());
        }
      }

      if( firstChild_ )
        firstChild_ = false;
    }
  }


  void PrinterVisitor::visitGraphCellNodeAfter(GraphCell *)
  {}

  // LATEXCELL

  void PrinterVisitor::visitLatexCellNodeBefore(LatexCell *node)
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
        tableFormatInput.setColumns( 1 );
        tableFormatInput.setCellPadding( 2 );
        tableFormatInput.setBackground( QColor(245, 245, 255) ); // 200, 200, 255
        QVector<QTextLength> constraints;
        constraints << QTextLength(QTextLength::PercentageLength, 100);
                tableFormatInput.setColumnWidthConstraints(constraints);
        cursor.insertTable( 1, 1, tableFormatInput );

        QString html = node->textHtml();
        if( !node->isEvaluated() || node->isClosed() )
          html += "<br />";
        cursor.insertFragment( QTextDocumentFragment::fromHtml( html ));

        if( node->isEvaluated() && !node->isClosed() )
        {
          QTextTableFormat tableFormatOutput;
          tableFormatOutput.setBorder( 0 );
          tableFormatOutput.setColumns( 1 );
          tableFormatOutput.setCellPadding( 2 );
          QVector<QTextLength> constraints;
          constraints << QTextLength(QTextLength::PercentageLength, 100);
          tableFormatOutput.setColumnWidthConstraints(constraints);

          cursor = tableCell.lastCursorPosition();
          cursor.insertTable( 1, 1, tableFormatOutput );

          QString outputHtml( node->textOutputHtml() );

          outputHtml.remove( "file:///" );
          cursor.insertFragment( QTextDocumentFragment::fromHtml( outputHtml ));
        }

      }

      if( firstChild_ )
        firstChild_ = false;
    }
  }
  void PrinterVisitor::visitLatexCellNodeAfter(LatexCell *)
  {}


  //CELLCURSOR
  void PrinterVisitor::visitCellCursorNodeBefore(CellCursor *)
  {}

  void PrinterVisitor::visitCellCursorNodeAfter(CellCursor *)
  {}
}
