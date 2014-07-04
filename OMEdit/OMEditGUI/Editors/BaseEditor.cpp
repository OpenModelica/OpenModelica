/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "BaseEditor.h"
#include "Helper.h"

BaseEditor::BaseEditor(QWidget *pParent)
  : QPlainTextEdit(pParent)
{
  setTabStopWidth(Helper::tabWidth);
  setObjectName("BaseEditor");
  document()->setDocumentMargin(2);
  // line numbers widget
  mpLineNumberArea = new LineNumberArea(this);
  connect(this, SIGNAL(blockCountChanged(int)), this, SLOT(updateLineNumberAreaWidth(int)));
  connect(this, SIGNAL(updateRequest(QRect,int)), this, SLOT(updateLineNumberArea(QRect,int)));
  connect(this, SIGNAL(cursorPositionChanged()), this, SLOT(highlightCurrentLine()));
  updateLineNumberAreaWidth(0);
  highlightCurrentLine();
}

//! Calculate appropriate width for LineNumberArea.
//! @return int width of LineNumberArea.
int BaseEditor::lineNumberAreaWidth()
{
  int digits = 1;
  int max = qMax(1, document()->blockCount());
  while (max >= 10)
  {
    max /= 10;
    ++digits;
  }
  int space = 20 + fontMetrics().width(QLatin1Char('9')) * digits;
  return space;
}

//! Activated whenever LineNumberArea Widget paint event is raised.
//! Writes the line numbers for the visible blocks.
void BaseEditor::lineNumberAreaPaintEvent(QPaintEvent *event)
{
  QPainter painter(mpLineNumberArea);
  painter.fillRect(event->rect(), QColor(240, 240, 240));

  QTextBlock block = firstVisibleBlock();
  int blockNumber = block.blockNumber();
  int top = (int) blockBoundingGeometry(block).translated(contentOffset()).top();
  int bottom = top + (int) blockBoundingRect(block).height();

  while (block.isValid() && top <= event->rect().bottom())
  {
    if (block.isVisible() && bottom >= event->rect().top())
    {
      QString number = QString::number(blockNumber + 1);
      // make the current highlighted line number darker
      if (blockNumber == textCursor().blockNumber())
        painter.setPen(QColor(64, 64, 64));
      else
        painter.setPen(Qt::gray);
      painter.setFont(document()->defaultFont());
      QFontMetrics fontMetrics (document()->defaultFont());
      painter.drawText(0, top, mpLineNumberArea->width() - 5, fontMetrics.height(), Qt::AlignRight, number);
    }
    block = block.next();
    top = bottom;
    bottom = top + (int) blockBoundingRect(block).height();
    ++blockNumber;
  }
}

/*!
  Takes the cursor to the specific line.
  \param lineNumber - the line number to go.
  */
void BaseEditor::goToLineNumber(int lineNumber)
{
  const QTextBlock &block = document()->findBlockByNumber(lineNumber - 1); // -1 since text index start from 0
  if (block.isValid())
  {
    QTextCursor cursor(block);
    cursor.movePosition(QTextCursor::Right, QTextCursor::MoveAnchor, 0);
    setTextCursor(cursor);
    centerCursor();
  }
}

//! Reimplementation of resize event.
//! Resets the size of LineNumberArea.
void BaseEditor::resizeEvent(QResizeEvent *pEvent)
{
  QPlainTextEdit::resizeEvent(pEvent);

  QRect cr = contentsRect();
  mpLineNumberArea->setGeometry(QRect(cr.left(), cr.top(), lineNumberAreaWidth(), cr.height()));
}

//! Updates the width of LineNumberArea.
void BaseEditor::updateLineNumberAreaWidth(int newBlockCount)
{
  Q_UNUSED(newBlockCount);
  setViewportMargins(lineNumberAreaWidth(), 0, 0, 0);
}

//! Slot activated when ModelicaEditor updateRequest signal is raised.
//! Scrolls the LineNumberArea Widget and also updates its width if required.
void BaseEditor::updateLineNumberArea(const QRect &rect, int dy)
{
  if (dy)
    mpLineNumberArea->scroll(0, dy);
  else
    mpLineNumberArea->update(0, rect.y(), mpLineNumberArea->width(), rect.height());

  if (rect.contains(viewport()->rect()))
    updateLineNumberAreaWidth(0);
}

//! Slot activated when editor's cursorPositionChanged signal is raised.
//! Hightlights the current line.
void BaseEditor::highlightCurrentLine()
{
  QList<QTextEdit::ExtraSelection> extraSelections;
  QTextEdit::ExtraSelection selection;
  QColor lineColor = QColor(232, 242, 254);
  selection.format.setBackground(lineColor);
  selection.format.setProperty(QTextFormat::FullWidthSelection, true);
  selection.cursor = textCursor();
  selection.cursor.clearSelection();
  extraSelections.append(selection);
  setExtraSelections(extraSelections);
}

//! @class GotoLineWidget
//! @brief An interface to goto a specific line in ModelicaEditor.

//! Constructor
GotoLineDialog::GotoLineDialog(BaseEditor *pBaseEditor, QWidget *pParent)
  : QDialog(pParent, Qt::WindowTitleHint)
{
  setWindowTitle(QString(Helper::applicationName).append(" - Go to Line"));
  setAttribute(Qt::WA_DeleteOnClose);
  setModal(true);
  mpBaseEditor = pBaseEditor;
  mpLineNumberLabel = new Label;
  mpLineNumberTextBox = new QLineEdit;
  mpOkButton = new QPushButton(Helper::ok);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(goToLineNumber()));
  // set layout
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->addWidget(mpLineNumberLabel, 0, 0);
  mainLayout->addWidget(mpLineNumberTextBox, 1, 0);
  mainLayout->addWidget(mpOkButton, 2, 0, 1, 0, Qt::AlignRight);
  setLayout(mainLayout);
}

//! Reimplementation of QDialog::show
void GotoLineDialog::show()
{
  mpLineNumberLabel->setText(QString("Enter line number (1 to ").append(QString::number(mpBaseEditor->blockCount())).append("):"));
  QIntValidator *intValidator = new QIntValidator(this);
  intValidator->setRange(1, mpBaseEditor->blockCount());
  mpLineNumberTextBox->setValidator(intValidator);
  setVisible(true);
}

//! Slot activated when mpOkButton clicked signal raised.
void GotoLineDialog::goToLineNumber()
{
  mpBaseEditor->goToLineNumber(mpLineNumberTextBox->text().toInt());
  accept();
}
