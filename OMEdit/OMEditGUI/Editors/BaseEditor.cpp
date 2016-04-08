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
 *
 */

#include "BaseEditor.h"
#include "ModelWidgetContainer.h"
#include "Helper.h"

/*!
 * \class TabSettings
 * \brief Defines the tabs and indentation settings for the editor.
 */
TabSettings::TabSettings()
  : mTabPolicy(SpacesOnlyTabPolicy), mTabSize(4), mIndentSize(2)
{

}

/*!
 * \brief tabSettings::lineIndentPosition
 * Returns the lines indent position.
 * \param text
 * \return
 */
int TabSettings::lineIndentPosition(const QString &text) const
{
  int i = 0;
  while (i < text.size()) {
    if (!text.at(i).isSpace()) {
      break;
    }
    ++i;
  }
  int column = columnAt(text, i);
  return i - (column % mIndentSize);
}

/*!
 * \brief tabSettings::columnAt
 * \param text
 * \param position
 * \return
 */
int TabSettings::columnAt(const QString &text, int position) const
{
  int column = 0;
  for (int i = 0; i < position; ++i) {
    if (text.at(i) == QLatin1Char('\t')) {
      column = column - (column % mTabSize) + mTabSize;
    } else {
      ++column;
    }
  }
  return column;
}

/*!
 * \brief tabSettings::indentedColumn
 * \param column
 * \param doIndent
 * \return
 */
int TabSettings::indentedColumn(int column, bool doIndent) const
{
  int aligned = (column / mIndentSize) * mIndentSize;
  if (doIndent) {
    return aligned + mIndentSize;
  }
  if (aligned < column) {
    return aligned;
  }
  return qMax(0, aligned - mIndentSize);
}

/*!
 * \brief tabSettings::indentationString
 * \param startColumn
 * \param targetColumn
 * \param block
 * \return
 */
QString TabSettings::indentationString(int startColumn, int targetColumn) const
{
  targetColumn = qMax(startColumn, targetColumn);
  if (mTabPolicy == SpacesOnlyTabPolicy) {
    return QString(targetColumn - startColumn, QLatin1Char(' '));
  }

  QString s;
  int alignedStart = startColumn - (startColumn % mTabSize) + mTabSize;
  if (alignedStart > startColumn && alignedStart <= targetColumn) {
    s += QLatin1Char('\t');
    startColumn = alignedStart;
  }
  if (int columns = targetColumn - startColumn) {
    int tabs = columns / mTabSize;
    s += QString(tabs, QLatin1Char('\t'));
    s += QString(columns - tabs * mTabSize, QLatin1Char(' '));
  }
  return s;
}

/*!
 * \brief tabSettings::firstNonSpace
 * \param text
 * \return
 */
int TabSettings::firstNonSpace(const QString &text)
{
  int i = 0;
  while (i < text.size()) {
    if (!text.at(i).isSpace()) {
      return i;
    }
    ++i;
  }
  return i;
}

/*!
 * \brief tabSettings::spacesLeftFromPosition
 * \param text
 * \param position
 * \return
 */
int TabSettings::spacesLeftFromPosition(const QString &text, int position)
{
  int i = position;
  while (i > 0) {
    if (!text.at(i-1).isSpace()) {
      break;
    }
    --i;
  }
  return position - i;
}

/*!
 * \brief TabSettings::cursorIsAtBeginningOfLine
 * Returns true if cursor is at beginning of line.
 * \param cursor
 * \return
 */
bool TabSettings::cursorIsAtBeginningOfLine(const QTextCursor &cursor)
{
  QString text = cursor.block().text();
  int fns = firstNonSpace(text);
  return (cursor.position() - cursor.block().position() <= fns);
}

TextBlockUserData::~TextBlockUserData()
{
  TextMarks marks = _marks;
  _marks.clear();
  foreach (ITextMark *mk, marks) {
    mk->removeFromEditor();
  }
}

/*!
 * \brief TextBlockUserData::checkOpenParenthesis
 * Checks the open Parenthesis for any mismatch
 * \param cursor
 * \param c
 * \return
 */
TextBlockUserData::MatchType TextBlockUserData::checkOpenParenthesis(QTextCursor *cursor, QChar c)
{
  QTextBlock block = cursor->block();
  if (!BaseEditorDocumentLayout::hasParentheses(block)) {
    return NoMatch;
  }

  Parentheses parentheses = BaseEditorDocumentLayout::parentheses(block);
  Parenthesis openParenthesis, closedParenthesis;
  QTextBlock closedParenthesisBlock = block;
  const int cursorPos = cursor->position() - closedParenthesisBlock.position();
  int i = 0;
  int ignore = 0;
  bool foundOpen = false;
  for (;;) {
    if (!foundOpen) {
      if (i >= parentheses.count())
        return NoMatch;
      openParenthesis = parentheses.at(i);
      if (openParenthesis.pos != cursorPos) {
        ++i;
        continue;
      } else {
        foundOpen = true;
        ++i;
      }
    }

    if (i >= parentheses.count()) {
      for (;;) {
        closedParenthesisBlock = closedParenthesisBlock.next();
        if (!closedParenthesisBlock.isValid())
          return NoMatch;
        if (BaseEditorDocumentLayout::hasParentheses(closedParenthesisBlock)) {
          parentheses = BaseEditorDocumentLayout::parentheses(closedParenthesisBlock);
          break;
        }
      }
      i = 0;
    }

    closedParenthesis = parentheses.at(i);
    if (closedParenthesis.type == Parenthesis::Opened) {
      ignore++;
      ++i;
      continue;
    } else {
      if (ignore > 0) {
        ignore--;
        ++i;
        continue;
      }

      cursor->clearSelection();
      cursor->setPosition(closedParenthesisBlock.position() + closedParenthesis.pos + 1, QTextCursor::KeepAnchor);

      if ((c == QLatin1Char('{') && closedParenthesis.chr != QLatin1Char('}'))
          || (c == QLatin1Char('(') && closedParenthesis.chr != QLatin1Char(')'))
          || (c == QLatin1Char('[') && closedParenthesis.chr != QLatin1Char(']'))) {
        return Mismatch;
      }

      return Match;
    }
  }
}

/*!
 * \brief TextBlockUserData::checkClosedParenthesis
 * Checks the close Parenthesis for any mismatch
 * \param cursor
 * \param c
 * \return
 */
TextBlockUserData::MatchType TextBlockUserData::checkClosedParenthesis(QTextCursor *cursor, QChar c)
{
  QTextBlock block = cursor->block();
  if (!BaseEditorDocumentLayout::hasParentheses(block)) {
    return NoMatch;
  }

  Parentheses parentheses = BaseEditorDocumentLayout::parentheses(block);
  Parenthesis openParenthesis, closedParenthesis;
  QTextBlock openParenthesisBlock = block;
  const int cursorPos = cursor->position() - openParenthesisBlock.position();
  int i = parentheses.count() - 1;
  int ignore = 0;
  bool foundClosed = false;
  for (;;) {
    if (!foundClosed) {
      if (i < 0)
        return NoMatch;
      closedParenthesis = parentheses.at(i);
      if (closedParenthesis.pos != cursorPos - 1) {
        --i;
        continue;
      } else {
        foundClosed = true;
        --i;
      }
    }

    if (i < 0) {
      for (;;) {
        openParenthesisBlock = openParenthesisBlock.previous();
        if (!openParenthesisBlock.isValid())
          return NoMatch;

        if (BaseEditorDocumentLayout::hasParentheses(openParenthesisBlock)) {
          parentheses = BaseEditorDocumentLayout::parentheses(openParenthesisBlock);
          break;
        }
      }
      i = parentheses.count() - 1;
    }

    openParenthesis = parentheses.at(i);
    if (openParenthesis.type == Parenthesis::Closed) {
      ignore++;
      --i;
      continue;
    } else {
      if (ignore > 0) {
        ignore--;
        --i;
        continue;
      }

      cursor->clearSelection();
      cursor->setPosition(openParenthesisBlock.position() + openParenthesis.pos, QTextCursor::KeepAnchor);

      if ((c == QLatin1Char('}') && openParenthesis.chr != QLatin1Char('{'))
          || (c == QLatin1Char(')') && openParenthesis.chr != QLatin1Char('('))
          || (c == QLatin1Char(']') && openParenthesis.chr != QLatin1Char('['))) {
        return Mismatch;
      }
      return Match;
    }
  }
}

/*!
 * \brief TextBlockUserData::matchCursorBackward
 * Matches the parentheses in the backward direction.
 * \param cursor
 * \return
 */
TextBlockUserData::MatchType TextBlockUserData::matchCursorBackward(QTextCursor *cursor)
{
  cursor->clearSelection();
  const QTextBlock block = cursor->block();
  if (!BaseEditorDocumentLayout::hasParentheses(block)) {
    return NoMatch;
  }

  const int relPos = cursor->position() - block.position();
  Parentheses parentheses = BaseEditorDocumentLayout::parentheses(block);
  const Parentheses::const_iterator cend = parentheses.constEnd();
  for (Parentheses::const_iterator it = parentheses.constBegin();it != cend; ++it) {
    const Parenthesis &parenthesis = *it;
    if (parenthesis.pos == relPos - 1 && parenthesis.type == Parenthesis::Closed) {
      return checkClosedParenthesis(cursor, parenthesis.chr);
    }
  }
  return NoMatch;
}

/*!
 * \brief TextBlockUserData::matchCursorForward
 * Matches the parentheses in the forward direction.
 * \param cursor
 * \return
 */
TextBlockUserData::MatchType TextBlockUserData::matchCursorForward(QTextCursor *cursor)
{
  cursor->clearSelection();
  const QTextBlock block = cursor->block();
  if (!BaseEditorDocumentLayout::hasParentheses(block)) {
    return NoMatch;
  }

  const int relPos = cursor->position() - block.position();
  Parentheses parentheses = BaseEditorDocumentLayout::parentheses(block);
  const Parentheses::const_iterator cend = parentheses.constEnd();
  for (Parentheses::const_iterator it = parentheses.constBegin();it != cend; ++it) {
    const Parenthesis &parenthesis = *it;
    if (parenthesis.pos == relPos && parenthesis.type == Parenthesis::Opened) {
      return checkOpenParenthesis(cursor, parenthesis.chr);
    }
  }
  return NoMatch;
}

/*!
 * \class BaseEditorDocumentLayout
 * Implements a custom text layout for BaseEditor to be able to work with QTextDocument::setDocumentLayout().
 */
BaseEditorDocumentLayout::BaseEditorDocumentLayout(QTextDocument *document)
  : QPlainTextDocumentLayout(document), mHasBreakpoint(false)
{

}

Parentheses BaseEditorDocumentLayout::parentheses(const QTextBlock &block)
{
  if (TextBlockUserData *userData = testUserData(block))
    return userData->parentheses();
  return Parentheses();
}

bool BaseEditorDocumentLayout::hasParentheses(const QTextBlock &block)
{
  if (TextBlockUserData *userData = testUserData(block))
    return userData->hasParentheses();
  return false;
}

TextBlockUserData* BaseEditorDocumentLayout::testUserData(const QTextBlock &block)
{
  return static_cast<TextBlockUserData*>(block.userData());
}

TextBlockUserData* BaseEditorDocumentLayout::userData(const QTextBlock &block)
{
  TextBlockUserData *data = static_cast<TextBlockUserData*>(block.userData());
  if (!data && block.isValid()) {
    const_cast<QTextBlock&>(block).setUserData((data = new TextBlockUserData));
  }
  return data;
}

/*!
 * \class BaseEditor::PlainTextEdit
 * Internal QPlainTextEdit for Editor.
 */
BaseEditor::PlainTextEdit::PlainTextEdit(BaseEditor *pBaseEditor)
  : QPlainTextEdit(pBaseEditor), mpBaseEditor(pBaseEditor)
{
  setObjectName("BaseEditor");
  QTextDocument *pTextDocument = document();
  pTextDocument->setDocumentMargin(2);
  BaseEditorDocumentLayout *pModelicaTextDocumentLayout = new BaseEditorDocumentLayout(pTextDocument);
  pTextDocument->setDocumentLayout(pModelicaTextDocumentLayout);
  setDocument(pTextDocument);
  // line numbers widget
  mpLineNumberArea = new LineNumberArea(mpBaseEditor);
  // parentheses matcher
  mParenthesesMatchFormat = Utilities::getParenthesesMatchFormat();
  mParenthesesMisMatchFormat = Utilities::getParenthesesMisMatchFormat();

  updateLineNumberAreaWidth(0);
  updateHighlights();
  updateCursorPosition();
  setLineWrapping();
  connect(this, SIGNAL(blockCountChanged(int)), mpBaseEditor, SLOT(updateLineNumberAreaWidth(int)));
  connect(this, SIGNAL(updateRequest(QRect,int)), mpBaseEditor, SLOT(updateLineNumberArea(QRect,int)));
  connect(this, SIGNAL(cursorPositionChanged()), mpBaseEditor, SLOT(updateHighlights()));
  connect(this, SIGNAL(cursorPositionChanged()), mpBaseEditor, SLOT(updateCursorPosition()));
  connect(document(), SIGNAL(contentsChange(int,int,int)), mpBaseEditor, SLOT(contentsHasChanged(int,int,int)));
  OptionsDialog *pOptionsDialog = mpBaseEditor->getMainWindow()->getOptionsDialog();
  connect(pOptionsDialog, SIGNAL(updateLineWrapping()), mpBaseEditor, SLOT(setLineWrapping()));
  setContextMenuPolicy(Qt::CustomContextMenu);
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), mpBaseEditor, SLOT(showContextMenu(QPoint)));
}

/*!
 * \brief BaseEditor::PlainTextEdit::lineNumberAreaWidth
 * Calculate appropriate width for LineNumberArea.
 * \return int width of LineNumberArea.
 */
int BaseEditor::PlainTextEdit::lineNumberAreaWidth()
{
  int digits = 2;
  int max = qMax(1, document()->blockCount());
  while (max >= 10) {
    max /= 10;
    ++digits;
  }
  int space = 10 + fontMetrics().width(QLatin1Char('9')) * digits;
  if (mpBaseEditor->canHaveBreakpoints()) {
    space += 16;  /* the breakpoint enable/disable svg is 16*16. */
  }
  return space;
}

/*!
 * \brief BaseEditor::PlainTextEdit::lineNumberAreaPaintEvent
 * Activated whenever LineNumberArea Widget paint event is raised.
 * Writes the line numbers for the visible blocks and draws the breakpoint markers.
 * \param event
 */
void BaseEditor::PlainTextEdit::lineNumberAreaPaintEvent(QPaintEvent *event)
{
  QPainter painter(mpLineNumberArea);
  painter.fillRect(event->rect(), QColor(240, 240, 240));

  QTextBlock block = firstVisibleBlock();
  int blockNumber = block.blockNumber();
  int top = (int) blockBoundingGeometry(block).translated(contentOffset()).top();
  int bottom = top + (int) blockBoundingRect(block).height();
  const QFontMetrics fm(mpLineNumberArea->font());
  int fmLineSpacing = fm.lineSpacing();

  while (block.isValid() && top <= event->rect().bottom()) {
    /* paint line numbers */
    if (block.isVisible() && bottom >= event->rect().top()) {
      QString number;
      if (mpBaseEditor->getModelWidget() && mpBaseEditor->getModelWidget()->getLibraryTreeItem()->isInPackageOneFile() &&
          mpBaseEditor->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
        number = QString::number(blockNumber + mpBaseEditor->getModelWidget()->getLibraryTreeItem()->mClassInformation.lineNumberStart);
      } else {
        number = QString::number(blockNumber + 1);
      }
      // make the current highlighted line number darker
      if (blockNumber == textCursor().blockNumber()) {
        painter.setPen(QColor(64, 64, 64));
      } else {
        painter.setPen(Qt::gray);
      }
      painter.setFont(document()->defaultFont());
      QFontMetrics fontMetrics (document()->defaultFont());
      painter.drawText(0, top, mpLineNumberArea->width() - 5, fontMetrics.height(), Qt::AlignRight, number);
    }
    /* paint breakpoints */
    TextBlockUserData *pTextBlockUserData = static_cast<TextBlockUserData*>(block.userData());
    if (pTextBlockUserData && mpBaseEditor->canHaveBreakpoints()) {
      int xoffset = 0;
      foreach (ITextMark *mk, pTextBlockUserData->marks()) {
        int x = 0;
        int radius = fmLineSpacing + 2;
        QRect r(x + xoffset, top, radius, radius);
        mk->icon().paint(&painter, r, Qt::AlignCenter);
        xoffset += 2;
      }
    }
    block = block.next();
    top = bottom;
    bottom = top + (int) blockBoundingRect(block).height();
    ++blockNumber;
  }
}

/*!
 * \brief BaseEditor::PlainTextEdit::lineNumberAreaMouseEvent
 * Activated whenever LineNumberArea Widget mouse press event is raised.
 * \param event
 */
void BaseEditor::PlainTextEdit::lineNumberAreaMouseEvent(QMouseEvent *event)
{
  /* if breakpoints are not enabled for this editor then return. */
  if (!mpBaseEditor->canHaveBreakpoints()) {
    return;
  }

  QTextCursor cursor = cursorForPosition(QPoint(0, event->pos().y()));
  const QFontMetrics fm(mpLineNumberArea->font());
  int breakPointWidth = 0;
  breakPointWidth += fm.lineSpacing();

  // Set whether the mouse cursor is a hand or a normal arrow
  if (event->type() == QEvent::MouseMove) {
    bool handCursor = (event->pos().x() <= breakPointWidth);
    if (handCursor != (mpLineNumberArea->cursor().shape() == Qt::PointingHandCursor)) {
      mpLineNumberArea->setCursor(handCursor ? Qt::PointingHandCursor : Qt::ArrowCursor);
    }
  } else if (event->type() == QEvent::MouseButtonPress || event->type() == QEvent::MouseButtonDblClick) {
    /* Do not allow breakpoints if file is not saved. */
    if (!mpBaseEditor->getModelWidget()->getLibraryTreeItem()->isSaved()) {
      mpBaseEditor->getMainWindow()->getInfoBar()->showMessage(tr("<b>Information: </b>Breakpoints are only allowed on saved classes."));
      return;
    }
    QString fileName = mpBaseEditor->getModelWidget()->getLibraryTreeItem()->getFileName();
    int lineNumber = cursor.blockNumber() + 1;
    if (event->button() == Qt::LeftButton) {  //! left clicked: add/remove breakpoint
      toggleBreakpoint(fileName, lineNumber);
    } else if (event->button() == Qt::RightButton) {  //! right clicked: show context menu
      QMenu menu(this);
      mpBaseEditor->getToggleBreakpointAction()->setData(QStringList() << fileName << QString::number(lineNumber));
      menu.addAction(mpBaseEditor->getToggleBreakpointAction());
      menu.exec(event->globalPos());
    }
  }
}

/*!
 * \brief BaseEditor::PlainTextEdit::goToLineNumber
 * Takes the cursor to the specific line.
 * \param lineNumber - the line number to go.
 */
void BaseEditor::PlainTextEdit::goToLineNumber(int lineNumber)
{
  if (mpBaseEditor->getModelWidget() && mpBaseEditor->getModelWidget()->getLibraryTreeItem()->isInPackageOneFile() &&
      mpBaseEditor->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    int lineNumberStart = mpBaseEditor->getModelWidget()->getLibraryTreeItem()->mClassInformation.lineNumberStart;
    int lineNumberDifferenceFromStart = lineNumberStart - 1;
    lineNumber -= lineNumberDifferenceFromStart;
  }
  const QTextBlock &block = document()->findBlockByNumber(lineNumber - 1); // -1 since text index start from 0
  if (block.isValid()) {
    QTextCursor cursor(block);
    cursor.movePosition(QTextCursor::Right, QTextCursor::MoveAnchor, 0);
    setTextCursor(cursor);
    centerCursor();
  }
}

/*!
 * \brief BaseEditor::updateLineNumberAreaWidth
 * Updates the width of LineNumberArea.
 * \param newBlockCount
 */
void BaseEditor::PlainTextEdit::updateLineNumberAreaWidth(int newBlockCount)
{
  Q_UNUSED(newBlockCount);
  setViewportMargins(lineNumberAreaWidth(), 0, 0, 0);
}

/*!
 * \brief BaseEditor::updateLineNumberArea
 * Scrolls the LineNumberArea Widget and also updates its width if required.
 * \param rect
 * \param dy
 */
void BaseEditor::PlainTextEdit::updateLineNumberArea(const QRect &rect, int dy)
{
  if (dy) {
    mpLineNumberArea->scroll(0, dy);
  } else {
    mpLineNumberArea->update(0, rect.y(), mpLineNumberArea->width(), rect.height());
  }

  if (rect.contains(viewport()->rect())) {
    updateLineNumberAreaWidth(0);
  }
}

/*!
 * \brief BaseEditor::updateHighlights
 * Slot activated when editor's cursorPositionChanged signal is raised.\n
 * Updates all the highlights.
 */
void BaseEditor::PlainTextEdit::updateHighlights()
{
  QList<QTextEdit::ExtraSelection> selections;
  setExtraSelections(selections);
  highlightCurrentLine();
  highlightParentheses();
}

/*!
 * \brief BaseEditor::updateCursorPosition
 * Slot activated when editor's cursorPositionChanged signal is raised.
 * Updates the cursorPostionLabel i.e Line: 12, Col:123.
 */
void BaseEditor::PlainTextEdit::updateCursorPosition()
{
  if (mpBaseEditor->getModelWidget()) {
    const QTextBlock block = textCursor().block();
    const int line = block.blockNumber() + 1;
    const int column = textCursor().columnNumber();
    Label *pCursorPositionLabel = mpBaseEditor->getModelWidget()->getCursorPositionLabel();
    pCursorPositionLabel->setText(QString("Line: %1, Col: %2").arg(line).arg(column));
  }
}

/*!
 * \brief BaseEditor::setLineWrapping
 * Sets the Editor Line Wrapping mode.
 */
void BaseEditor::PlainTextEdit::setLineWrapping()
{
  OptionsDialog *pOptionsDialog = mpBaseEditor->getMainWindow()->getOptionsDialog();
  if (pOptionsDialog->getTextEditorPage()->getLineWrappingCheckbox()->isChecked()) {
    setLineWrapMode(QPlainTextEdit::WidgetWidth);
  } else {
    setLineWrapMode(QPlainTextEdit::NoWrap);
  }
}

/*!
 * \brief BaseEditor::PlainTextEdit::toggleBreakpoint
 * Toggles the breakpoint.
 * \param fileName
 * \param lineNumber
 */
void BaseEditor::PlainTextEdit::toggleBreakpoint(const QString fileName, int lineNumber)
{
  BreakpointsTreeModel *pBreakpointsTreeModel = mpBaseEditor->getMainWindow()->getDebuggerMainWindow()->getBreakpointsWidget()->getBreakpointsTreeModel();
  BreakpointMarker *pBreakpointMarker = pBreakpointsTreeModel->findBreakpointMarker(fileName, lineNumber);
  if (!pBreakpointMarker) {
    /* create a breakpoint marker */
    pBreakpointMarker = new BreakpointMarker(fileName, lineNumber, pBreakpointsTreeModel);
    pBreakpointMarker->setEnabled(true);
    /* Add the marker to document marker */
    mpBaseEditor->getDocumentMarker()->addMark(pBreakpointMarker, lineNumber);
    /* insert the breakpoint in BreakpointsWidget */
    pBreakpointsTreeModel->insertBreakpoint(pBreakpointMarker, mpBaseEditor->getModelWidget()->getLibraryTreeItem(), pBreakpointsTreeModel->getRootBreakpointTreeItem());
  } else {
    mpBaseEditor->getDocumentMarker()->removeMark(pBreakpointMarker);
    pBreakpointsTreeModel->removeBreakpoint(pBreakpointMarker);
  }
}

/*!
 * \brief BaseEditor::indentOrUnindent
 * Indents or unindents the code.
 * \param doIndent
 */
void BaseEditor::PlainTextEdit::indentOrUnindent(bool doIndent)
{
  TabSettings tabSettings = mpBaseEditor->getMainWindow()->getOptionsDialog()->getTabSettings();
  QTextCursor cursor = textCursor();
  cursor.beginEditBlock();
  // Indent or unindent the selected lines
  if (cursor.hasSelection()) {
    int pos = cursor.position();
    int anchor = cursor.anchor();
    int start = qMin(anchor, pos);
    int end = qMax(anchor, pos);
    QTextDocument *doc = document();
    QTextBlock startBlock = doc->findBlock(start);
    QTextBlock endBlock = doc->findBlock(end-1).next();
    // Only one line partially selected.
    if (startBlock.next() == endBlock && (start > startBlock.position() || end < endBlock.position() - 1)) {
      cursor.removeSelectedText();
    } else {
      for (QTextBlock block = startBlock; block != endBlock; block = block.next()) {
        QString text = block.text();
        int indentPosition = tabSettings.lineIndentPosition(text);
        if (!doIndent && !indentPosition) {
          indentPosition = tabSettings.firstNonSpace(text);
        }
        int targetColumn = tabSettings.indentedColumn(tabSettings.columnAt(text, indentPosition), doIndent);
        cursor.setPosition(block.position() + indentPosition);
        cursor.insertText(tabSettings.indentationString(0, targetColumn));
        cursor.setPosition(block.position());
        cursor.setPosition(block.position() + indentPosition, QTextCursor::KeepAnchor);
        cursor.removeSelectedText();
      }
      cursor.endEditBlock();
      return;
    }
  }
  // Indent or unindent at cursor position
  QTextBlock block = cursor.block();
  QString text = block.text();
  int indentPosition = cursor.positionInBlock();
  int spaces = tabSettings.spacesLeftFromPosition(text, indentPosition);
  int startColumn = tabSettings.columnAt(text, indentPosition - spaces);
  int targetColumn = tabSettings.indentedColumn(tabSettings.columnAt(text, indentPosition), doIndent);
  cursor.setPosition(block.position() + indentPosition);
  cursor.setPosition(block.position() + indentPosition - spaces, QTextCursor::KeepAnchor);
  cursor.removeSelectedText();
  cursor.insertText(tabSettings.indentationString(startColumn, targetColumn));
  cursor.endEditBlock();
  setTextCursor(cursor);
}

/*!
 * \brief BaseEditor::PlainTextEdit::highlightCurrentLine
 * Hightlights the current line.
 */
void BaseEditor::PlainTextEdit::highlightCurrentLine()
{
  Utilities::highlightCurrentLine(this);
}

/*!
 * \brief BaseEditor::PlainTextEdit::highlightParentheses
 * Highlights the matching parentheses.
 */
void BaseEditor::PlainTextEdit::highlightParentheses()
{
  Utilities::highlightParentheses(this, mParenthesesMatchFormat, mParenthesesMisMatchFormat);
}

/*!
 * \brief BaseEditor::PlainTextEdit::plainTextFromSelection
 * Returns the selected text in plain text format.
 * \param cursor
 * \return
 */
QString BaseEditor::PlainTextEdit::plainTextFromSelection(const QTextCursor &cursor) const
{
  // Copy the selected text as plain text
  QString text = cursor.selectedText();
  return convertToPlainText(text);
}

/*!
 * \brief BaseEditor::PlainTextEdit::convertToPlainText
 * Returns the text in plain text format.
 * \param txt
 * \return
 */
QString BaseEditor::PlainTextEdit::convertToPlainText(const QString &txt)
{
  QString ret = txt;
  QChar *uc = ret.data();
  QChar *e = uc + ret.size();

  for (; uc != e; ++uc) {
    switch (uc->unicode()) {
      case 0xfdd0: // QTextBeginningOfFrame
      case 0xfdd1: // QTextEndOfFrame
      case QChar::ParagraphSeparator:
      case QChar::LineSeparator:
        *uc = QLatin1Char('\n');
        break;
      case QChar::Nbsp:
        *uc = QLatin1Char(' ');
        break;
      default:
        ;
    }
  }
  return ret;
}

/*!
 * \brief BaseEditor::PlainTextEdit::resizeEvent
 * Reimplementation of resize event.
 * Resets the size of LineNumberArea.
 * \param pEvent
 */
void BaseEditor::PlainTextEdit::resizeEvent(QResizeEvent *pEvent)
{
  QPlainTextEdit::resizeEvent(pEvent);

  QRect cr = contentsRect();
  mpLineNumberArea->setGeometry(QRect(cr.left(), cr.top(), lineNumberAreaWidth(), cr.height()));
}

/*!
 * \brief BaseEditor::keyPressEvent
 * Reimplementation of keyPressEvent.
 * \param pEvent
 */
void BaseEditor::PlainTextEdit::keyPressEvent(QKeyEvent *pEvent)
{
  if (pEvent->key() == Qt::Key_Escape) {
    if (mpBaseEditor->getFindReplaceWidget()->isVisible()) {
      mpBaseEditor->getFindReplaceWidget()->close();
    }
    return;
  }
  if (pEvent->key() == Qt::Key_Tab || pEvent->key() == Qt::Key_Backtab) {
    // tab or backtab is pressed.
    indentOrUnindent(pEvent->key() == Qt::Key_Tab);
    return;
  } else if (pEvent->modifiers().testFlag(Qt::ControlModifier) && pEvent->key() == Qt::Key_F) {
    // ctrl+f is pressed.
    mpBaseEditor->showFindReplaceWidget();
    return;
  } else if (pEvent->modifiers().testFlag(Qt::ControlModifier) && pEvent->key() == Qt::Key_L) {
    // ctrl+l is pressed.
    mpBaseEditor->showGotoLineNumberDialog();
    return;
  } else if (pEvent->modifiers().testFlag(Qt::ControlModifier) && pEvent->key() == Qt::Key_K) {
    // ctrl+k is pressed.
    mpBaseEditor->toggleCommentSelection();
    return;
  } else if (pEvent->modifiers().testFlag(Qt::ShiftModifier) && (pEvent->key() == Qt::Key_Enter || pEvent->key() == Qt::Key_Return)) {
    /* Ticket #2273. Change shift+enter to enter. */
    pEvent->setModifiers(Qt::NoModifier);
  }
  QPlainTextEdit::keyPressEvent(pEvent);
  /* If user has pressed enter then a new line is inserted.
   * Indent the new line based on the indentation of previous line.
   */
  /*! @todo We should add formatter classes to handle this based on editor language i.e Modelica or C/C++. */
  if (pEvent->key() == Qt::Key_Enter || pEvent->key() == Qt::Key_Return) {
    TabSettings tabSettings = mpBaseEditor->getMainWindow()->getOptionsDialog()->getTabSettings();
    QTextCursor cursor = textCursor();
    const QTextBlock previousBlock = cursor.block().previous();
    QString indentText = previousBlock.text();
    cursor.beginEditBlock();
    cursor.insertText(indentText.left(tabSettings.firstNonSpace(indentText)));
    cursor.endEditBlock();
    setTextCursor(cursor);
  }
}

/*!
 * \brief BaseEditor::PlainTextEdit::createMimeDataFromSelection
 * Reimplementation of QPlainTextEdit::createMimeDataFromSelection() to allow copying text with formatting.
 * \return
 */
QMimeData* BaseEditor::PlainTextEdit::createMimeDataFromSelection() const
{
  if (textCursor().hasSelection()) {
    QTextCursor cursor = textCursor();
    QMimeData *mimeData = new QMimeData;
    QString text = plainTextFromSelection(cursor);
    mimeData->setText(text);
    // Create a new document from the selected text document fragment
    QTextDocument *tempDocument = new QTextDocument;
    QTextCursor tempCursor(tempDocument);
    tempCursor.insertFragment(cursor.selection());
    // Apply the additional formats set by the syntax highlighter
    QTextBlock start = document()->findBlock(cursor.selectionStart());
    QTextBlock last = document()->findBlock(cursor.selectionEnd());
    QTextBlock end = last.next();

    const int selectionStart = cursor.selectionStart();
    const int endOfDocument = tempDocument->characterCount() - 1;
    for (QTextBlock current = start; current.isValid() && current != end; current = current.next()) {
      foreach (const QTextLayout::FormatRange &range, current.layout()->additionalFormats()) {
        const int startPosition = current.position() + range.start - selectionStart;
        const int endPosition = startPosition + range.length;
        if (endPosition <= 0 || startPosition >= endOfDocument) {
          continue;
        }
        tempCursor.setPosition(qMax(startPosition, 0));
        tempCursor.setPosition(qMin(endPosition, endOfDocument), QTextCursor::KeepAnchor);
        QTextCharFormat format = range.format;
        format.setFont(range.format.font());
        tempCursor.setCharFormat(format);
      }
    }
    // Reset the user states since they are not interesting
    for (QTextBlock block = tempDocument->begin(); block.isValid(); block = block.next()) {
      block.setUserState(-1);
    }
    // Make sure the text appears pre-formatted
    tempCursor.setPosition(0);
    tempCursor.movePosition(QTextCursor::End, QTextCursor::KeepAnchor);
    QTextBlockFormat blockFormat = tempCursor.blockFormat();
    blockFormat.setNonBreakableLines(true);
    tempCursor.setBlockFormat(blockFormat);
    mimeData->setHtml(tempCursor.selection().toHtml());
    delete tempDocument;

    // Try to figure out whether we are copying an entire block, and store the complete block including indentation
    QTextCursor selectedStartCursor = cursor;
    selectedStartCursor.setPosition(cursor.selectionStart());
    QTextCursor selectedEndCursor = cursor;
    selectedEndCursor.setPosition(cursor.selectionEnd());

    bool startOk = TabSettings::cursorIsAtBeginningOfLine(selectedStartCursor);
    bool multipleBlocks = (selectedEndCursor.block() != selectedStartCursor.block());

    if (startOk && multipleBlocks) {
      selectedStartCursor.movePosition(QTextCursor::StartOfBlock);
      if (TabSettings::cursorIsAtBeginningOfLine(selectedEndCursor)) {
        selectedEndCursor.movePosition(QTextCursor::StartOfBlock);
      }
      cursor.setPosition(selectedStartCursor.position());
      cursor.setPosition(selectedEndCursor.position(), QTextCursor::KeepAnchor);
      text = plainTextFromSelection(cursor);
      mimeData->setData(QLatin1String("application/OMEdit.modelica-text"), text.toUtf8());
    }
    return mimeData;
  }
  return 0;
}

/*!
 * \brief BaseEditor::PlainTextEdit::focusInEvent
 * Reimplementation of QPlainTextEdit::focusInEvent(). Stops the auto save timer.
 * \param event
 */
void BaseEditor::PlainTextEdit::focusInEvent(QFocusEvent *event)
{
  mpBaseEditor->getMainWindow()->getAutoSaveTimer()->stop();
  QPlainTextEdit::focusInEvent(event);
}

/*!
 * \brief BaseEditor::PlainTextEdit::focusOutEvent
 * Reimplementation of QPlainTextEdit::focusOutEvent(). Restarts the auto save timer.
 * \param event
 */
void BaseEditor::PlainTextEdit::focusOutEvent(QFocusEvent *event)
{
  /* The user might start editing the document and then minimize the OMEdit window.
   * We should only start the autosavetimer when MainWindow is the active window and focusOutEvent is called.
   */
  if (mpBaseEditor->getMainWindow()->isActiveWindow()) {
    if (mpBaseEditor->getMainWindow()->getOptionsDialog()->getGeneralSettingsPage()->getEnableAutoSaveGroupBox()->isChecked()) {
      mpBaseEditor->getMainWindow()->getAutoSaveTimer()->start();
    }
  }
  QPlainTextEdit::focusOutEvent(event);
}

/*!
 * \class BaseEditor
 * Base class for all editors.
 */
/*!
 * \brief BaseEditor::BaseEditor
 * \param pMainWindow
 */
BaseEditor::BaseEditor(MainWindow *pMainWindow)
  : QWidget(pMainWindow), mpModelWidget(0), mpMainWindow(pMainWindow), mCanHaveBreakpoints(false)
{
  initialize();
}

BaseEditor::BaseEditor(ModelWidget *pModelWidget)
  : QWidget(pModelWidget), mpModelWidget(pModelWidget), mCanHaveBreakpoints(false)
{
  mpMainWindow = pModelWidget->getModelWidgetContainer()->getMainWindow();
  initialize();
}

/*!
 * \brief BaseEditor::setCanHaveBreakpoints
 * Sets whether editor supports breakpoints or not. Also sets/unsets the editor's LineNumberArea mouse tracking.
 * \param canHaveBreakpoints
 */
void BaseEditor::setCanHaveBreakpoints(bool canHaveBreakpoints)
{
  mCanHaveBreakpoints = canHaveBreakpoints;
  mpPlainTextEdit->getLineNumberArea()->setMouseTracking(canHaveBreakpoints);
}

/*!
 * \brief BaseEditor::goToLineNumber
 * Takes the cursor to the specific line.
 * \param lineNumber - the line number to go.
 */
void BaseEditor::goToLineNumber(int lineNumber)
{
  mpPlainTextEdit->goToLineNumber(lineNumber);
}

/*!
 * \brief BaseEditor::initialize
 * Initializes the editor with default values.
 */
void BaseEditor::initialize()
{
  mpPlainTextEdit = new PlainTextEdit(this);
  mpFindReplaceWidget = new FindReplaceWidget(this);
  mpFindReplaceWidget->hide();
  createActions();
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpPlainTextEdit, 1);
  pMainLayout->addWidget(mpFindReplaceWidget, 0, Qt::AlignBottom);
  setLayout(pMainLayout);
}

/*!
 * \brief BaseEditor::createActions
 * Creates the actions for editor's context menu.
 */
void BaseEditor::createActions()
{
  // find replace class action
  mpFindReplaceAction = new QAction(QString(Helper::findReplaceModelicaText), this);
  mpFindReplaceAction->setStatusTip(tr("Shows the Find/Replace window"));
  mpFindReplaceAction->setShortcut(QKeySequence("Ctrl+f"));
  connect(mpFindReplaceAction, SIGNAL(triggered()), SLOT(showFindReplaceWidget()));
  // clear find/replace texts action
  mpClearFindReplaceTextsAction = new QAction(tr("Clear Find/Replace Texts"), this);
  mpClearFindReplaceTextsAction->setStatusTip(tr("Clears the Find/Replace text items"));
  connect(mpClearFindReplaceTextsAction, SIGNAL(triggered()), SLOT(clearFindReplaceTexts()));
  // goto line action
  mpGotoLineNumberAction = new QAction(tr("Go to Line"), this);
  mpGotoLineNumberAction->setStatusTip(tr("Shows the Go to Line Number window"));
  mpGotoLineNumberAction->setShortcut(QKeySequence("Ctrl+l"));
  connect(mpGotoLineNumberAction, SIGNAL(triggered()), SLOT(showGotoLineNumberDialog()));
  // ShowTabsAndSpaces action
  mpShowTabsAndSpacesAction = new QAction(tr("Show Tabs and Spaces"), this);
  mpShowTabsAndSpacesAction->setStatusTip(tr("Shows the Tabs and Spaces"));
  mpShowTabsAndSpacesAction->setCheckable(true);
  connect(mpShowTabsAndSpacesAction, SIGNAL(triggered(bool)), SLOT(showTabsAndSpaces(bool)));
  /* Toggle breakpoint action */
  mpToggleBreakpointAction = new QAction(tr("Toggle Breakpoint"), this);
  connect(mpToggleBreakpointAction, SIGNAL(triggered()), SLOT(toggleBreakpoint()));
  // toggle comment action
  mpToggleCommentSelectionAction = new QAction(tr("Toggle Comment Selection"), this);
  mpToggleCommentSelectionAction->setShortcut(QKeySequence("Ctrl+k"));
  connect(mpToggleCommentSelectionAction, SIGNAL(triggered()), SLOT(toggleCommentSelection()));
}

/*!
 * \brief BaseEditor::createStandardContextMenu
 * Creates a standard context menu for ediotr.
 * \return
 */
QMenu* BaseEditor::createStandardContextMenu()
{
  QMenu *pMenu = mpPlainTextEdit->createStandardContextMenu();
  pMenu->addSeparator();
  pMenu->addAction(mpFindReplaceAction);
  pMenu->addAction(mpClearFindReplaceTextsAction);
  pMenu->addAction(mpGotoLineNumberAction);
  pMenu->addSeparator();
  pMenu->addAction(mpShowTabsAndSpacesAction);
  return pMenu;
}

/*!
 * \brief BaseEditor::updateLineNumberAreaWidth
 * Updates the width of LineNumberArea.
 * \param newBlockCount
 */
void BaseEditor::updateLineNumberAreaWidth(int newBlockCount)
{
  mpPlainTextEdit->updateLineNumberAreaWidth(newBlockCount);
}

/*!
 * \brief BaseEditor::updateLineNumberArea
 * Scrolls the LineNumberArea Widget and also updates its width if required.
 * \param rect
 * \param dy
 */
void BaseEditor::updateLineNumberArea(const QRect &rect, int dy)
{
  mpPlainTextEdit->updateLineNumberArea(rect, dy);
}

/*!
 * \brief BaseEditor::updateHighlights
 * Slot activated when editor's cursorPositionChanged signal is raised.
 * Updates all the highlights.
 */
void BaseEditor::updateHighlights()
{
  mpPlainTextEdit->updateHighlights();
}

/*!
 * \brief BaseEditor::updateCursorPosition
 * Slot activated when editor's cursorPositionChanged signal is raised.
 * Updates the cursorPostionLabel i.e Line: 12, Col:123.
 */
void BaseEditor::updateCursorPosition()
{
  mpPlainTextEdit->updateCursorPosition();
}

/*!
 * \brief BaseEditor::setLineWrapping
 */
void BaseEditor::setLineWrapping()
{
  mpPlainTextEdit->setLineWrapping();
}

/*!
 * \brief BaseEditor::showFindReplaceWidget
 * Shows the FindReplaceWidget
 */
void BaseEditor::showFindReplaceWidget()
{
  mpFindReplaceWidget->show();
}

/*!
 * \brief BaseEditor::clearFindReplaceTexts
 * Clears the FindReplaceWidget remembered text.
 */
void BaseEditor::clearFindReplaceTexts()
{
  QSettings *pSettings = OpenModelica::getApplicationSettings();
  pSettings->remove("FindReplaceDialog/textsToFind");
}

/*!
 * \brief BaseEditor::showGotoLineNumberDialog
 * Shows the GotoLineDialog
 */
void BaseEditor::showGotoLineNumberDialog()
{
  GotoLineDialog *pGotoLineWidget = new GotoLineDialog(this);
  pGotoLineWidget->exec();
}

/*!
 * \brief BaseEditor::showTabsAndSpaces
 * Shows/hide tabs and spaces for the editor.
 * \param On
 */
void BaseEditor::showTabsAndSpaces(bool On)
{
  QTextOption textOption = mpPlainTextEdit->document()->defaultTextOption();
  if (On) {
    textOption.setFlags(textOption.flags() | QTextOption::ShowTabsAndSpaces);
  } else {
    textOption.setFlags(textOption.flags() & ~QTextOption::ShowTabsAndSpaces);
  }
  mpPlainTextEdit->document()->setDefaultTextOption(textOption);
}

/*!
 * \brief BaseEditor::toggleBreakpoint
 * Slot activated when set breakpoint is seleteted from line number area context menu.
 */
void BaseEditor::toggleBreakpoint()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction) {
    QStringList list = pAction->data().toStringList();
    mpPlainTextEdit->toggleBreakpoint(list.at(0), list.at(1).toInt());
  }
}

/*!
 * \class FindReplaceWidget
 * Creates a widget within editor for find and replace.
 */
FindReplaceWidget::FindReplaceWidget(BaseEditor *pBaseEditor)
  : QWidget(pBaseEditor), mpBaseEditor(pBaseEditor)
{
  // Find Label and text box
  mpFindLabel = new Label(tr("Find:"));
  mpFindComboBox = new QComboBox;
  mpFindComboBox->setEditable(true);
  connect(mpFindComboBox, SIGNAL(editTextChanged(QString)), this, SLOT(textToFindChanged()));
  connect(mpFindComboBox, SIGNAL(editTextChanged(QString)), this, SLOT(validateRegularExpression(QString)));
  connect(mpFindComboBox->lineEdit(), SIGNAL(returnPressed()), SLOT(findNext()));
  /* Since the default QCompleter for QComboBox is case insenstive. */
  QCompleter *pFindComboBoxCompleter = mpFindComboBox->completer();
  pFindComboBoxCompleter->setCaseSensitivity(Qt::CaseSensitive);
  mpFindComboBox->setCompleter(pFindComboBoxCompleter);
  // previous, next & close buttons
  mpFindPreviousButton = new QPushButton(Helper::previous);
  connect(mpFindPreviousButton, SIGNAL(clicked()), this, SLOT(findPrevious()));
  mpFindNextButton = new QPushButton(Helper::next);
  connect(mpFindNextButton, SIGNAL(clicked()), this, SLOT(findNext()));
  mpCloseButton = new QPushButton(Helper::close);
  connect(mpCloseButton, SIGNAL(clicked()), this, SLOT(close()));
  // buttons layout
  QHBoxLayout *pFindButtonsHorizontalLayout = new QHBoxLayout;
  pFindButtonsHorizontalLayout->addWidget(mpFindPreviousButton);
  pFindButtonsHorizontalLayout->addWidget(mpFindNextButton);
  pFindButtonsHorizontalLayout->addWidget(mpCloseButton);
  // Find replace and text box
  mpReplaceWithLabel = new Label(tr("Replace With:"));
  mpReplaceWithTextBox = new QLineEdit;
  connect(mpReplaceWithTextBox, SIGNAL(returnPressed()), SLOT(replace()));
  // Find Options
  mpCaseSensitiveCheckBox = new QCheckBox(tr("Case Sensitive"));
  mpWholeWordCheckBox = new QCheckBox(tr("Whole Words"));
  mpRegularExpressionCheckBox = new QCheckBox(tr("Regular Expressions"));
  // Replace & replace all buttons
  mpReplaceButton = new QPushButton(tr("Replace"));
  connect(mpReplaceButton, SIGNAL(clicked()), this, SLOT(replace()));
  mpReplaceAllButton = new QPushButton(tr("Replace All"));
  connect(mpReplaceAllButton, SIGNAL(clicked()), this, SLOT(replaceAll()));
  // options layout
  QHBoxLayout *pOptionsHorizontalLayout = new QHBoxLayout;
  pOptionsHorizontalLayout->addWidget(mpCaseSensitiveCheckBox);
  pOptionsHorizontalLayout->addWidget(mpWholeWordCheckBox);
  pOptionsHorizontalLayout->addWidget(mpRegularExpressionCheckBox);
  pOptionsHorizontalLayout->addWidget(mpReplaceButton);
  pOptionsHorizontalLayout->addWidget(mpReplaceAllButton);
  // set main layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpFindLabel, 0, 0);
  pMainLayout->addWidget(mpFindComboBox, 0, 1);
  pMainLayout->addLayout(pFindButtonsHorizontalLayout, 0, 2);
  pMainLayout->addWidget(mpReplaceWithLabel, 1, 0);
  pMainLayout->addWidget(mpReplaceWithTextBox, 1, 1);
  pMainLayout->addLayout(pOptionsHorizontalLayout, 1, 2);
  setLayout(pMainLayout);
  // set tab order
  setTabOrder(mpFindComboBox, mpReplaceWithTextBox);
  setTabOrder(mpReplaceWithTextBox, mpFindPreviousButton);
}

/*!
 * \brief FindReplaceWidget::show
 * Shows the FindReplaceWidget.
 * Reads the settings to get the previously searched text.
 */
void FindReplaceWidget::show()
{
  QTextCursor currentTextCursor = mpBaseEditor->getPlainTextEdit()->textCursor();
  if (currentTextCursor.hasSelection()) {
    QString selectedText = currentTextCursor.selectedText();
    saveFindTextToSettings(selectedText);
    readFindTextFromSettings();
  } else {
    readFindTextFromSettings();
  }
  mpFindComboBox->setFocus();
  mpFindComboBox->lineEdit()->selectAll();
  setVisible(true);
}

/*!
 * \brief FindReplaceWidget::readFindTextFromSettings
 * Reads the list of find texts from the settings file.
 */
void FindReplaceWidget::readFindTextFromSettings()
{
  QSettings *pSettings = OpenModelica::getApplicationSettings();
  mpFindComboBox->clear();
  QList<QVariant> findTexts = pSettings->value("FindReplaceDialog/textsToFind").toList();
  int numFindTexts = qMin(findTexts.size(), (int)MaxFindTexts);
  for (int i = 0; i < numFindTexts; ++i) {
    FindTextOM findText = qvariant_cast<FindTextOM>(findTexts[i]);
    mpFindComboBox->addItem(findText.text);
  }
}

/*!
 * \brief FindReplaceWidget::saveFindTextToSettings
 * Saves the find text to the settings file.
 * \param textToFind - the text to find
 */
void FindReplaceWidget::saveFindTextToSettings(QString textToFind)
{
  QSettings *pSettings = OpenModelica::getApplicationSettings();
  QList<QVariant> texts = pSettings->value("FindReplaceDialog/textsToFind").toList();
  // remove the already present text from the list.
  foreach (QVariant text, texts) {
    FindTextOM findText = qvariant_cast<FindTextOM>(text);
    if (findText.text.compare(textToFind) == 0)
      texts.removeOne(text);
  }
  FindTextOM findText;
  findText.text = textToFind;
  texts.prepend(QVariant::fromValue(findText));
  while (texts.size() > MaxFindTexts) {
    texts.removeLast();
  }
  pSettings->setValue("FindReplaceDialog/textsToFind", texts);
}

/*!
 * \brief FindReplaceWidget::findText
 * Finds the text
 * \param forward - direction flag.
 */
void FindReplaceWidget::findText(bool forward)
{
  QTextCursor currentTextCursor = mpBaseEditor->getPlainTextEdit()->textCursor();
  bool backward = !forward;

  if (currentTextCursor.hasSelection()) {
    currentTextCursor.setPosition(forward ? currentTextCursor.position() : currentTextCursor.anchor(), QTextCursor::MoveAnchor);
  }
  const QString &textToFind = mpFindComboBox->currentText();
  // save the find text in settings
  saveFindTextToSettings(textToFind);
  QTextDocument::FindFlags flags;
  if (backward) {
    flags |= QTextDocument::FindBackward;
  }
  if (mpCaseSensitiveCheckBox->isChecked()) {
    flags |= QTextDocument::FindCaseSensitively;
  }
  if (mpWholeWordCheckBox->isChecked()) {
    flags |= QTextDocument::FindWholeWords;
  }

  if (mpRegularExpressionCheckBox->isChecked()) {
    QRegExp reg(textToFind, (mpCaseSensitiveCheckBox->isChecked() ? Qt::CaseSensitive : Qt::CaseInsensitive));
    currentTextCursor = mpBaseEditor->getPlainTextEdit()->document()->find(reg, currentTextCursor, flags);
    mpBaseEditor->getPlainTextEdit()->setTextCursor(currentTextCursor);
  }

  QTextCursor newTextCursor = mpBaseEditor->getPlainTextEdit()->document()->find(textToFind, currentTextCursor, flags);
  if (newTextCursor.isNull()) {
    QTextCursor ac(mpBaseEditor->getPlainTextEdit()->document());
    ac.movePosition(flags & QTextDocument::FindBackward ? QTextCursor::End : QTextCursor::Start);
    newTextCursor = mpBaseEditor->getPlainTextEdit()->document()->find(textToFind, ac, flags);
    if (newTextCursor.isNull()) {
      newTextCursor = currentTextCursor;
    }
  }
  mpBaseEditor->getPlainTextEdit()->setTextCursor(newTextCursor);
}

/*!
 * \brief FindReplaceWidget::findPrevious
 * Finds the text in backward direction.
 */
void FindReplaceWidget::findPrevious()
{
  findText(false);
}

/*!
 * \brief FindReplaceWidget::findNext
 * Finds the text in forward direction.
 */
void FindReplaceWidget::findNext()
{
  findText(true);
}

/*!
 * \brief FindReplaceWidget::close
 * Reimplementation of QWidget::close(). Sets the focus on BaseEditor::PlainTextEdit
 * \return
 */
bool FindReplaceWidget::close()
{
  bool closed = QWidget::close();
  mpBaseEditor->getPlainTextEdit()->setFocus(Qt::ActiveWindowFocusReason);
  return closed;
}

/*!
 * \brief FindReplaceWidget::replace
 * Replaces the found occurrences and goes to the next occurrence
 */
void FindReplaceWidget::replace()
{
  int compareString(0);
  if(mpCaseSensitiveCheckBox->isChecked()) {
    compareString = Qt::CaseSensitive;
  } else {
    compareString = Qt::CaseInsensitive;
  }
  int same = mpBaseEditor->getPlainTextEdit()->textCursor().selectedText().compare(mpFindComboBox->currentText(),( Qt::CaseSensitivity)compareString );
  if (mpBaseEditor->getPlainTextEdit()->textCursor().hasSelection() && same == 0) {
    mpBaseEditor->getPlainTextEdit()->textCursor().insertText(mpReplaceWithTextBox->text());
    findNext();
  } else {
    findNext();
  }
}

/*!
 * \brief FindReplaceWidget::replaceAll
 * Replaces all the found occurrences
 */
void FindReplaceWidget::replaceAll()
{
  // move cursor to start of text
  QTextCursor cursor = mpBaseEditor->getPlainTextEdit()->textCursor();
  cursor.movePosition(QTextCursor::Start);
  mpBaseEditor->getPlainTextEdit()->setTextCursor(cursor);

  QTextDocument::FindFlags flags;
  if (mpCaseSensitiveCheckBox->isChecked()) {
    flags |= QTextDocument::FindCaseSensitively;
  }
  if (mpWholeWordCheckBox->isChecked()) {
    flags |= QTextDocument::FindWholeWords;
  }
  // save the find text in settings
  saveFindTextToSettings(mpFindComboBox->currentText());
  // replace all
  int i=0;
  mpBaseEditor->getPlainTextEdit()->textCursor().beginEditBlock();
  while (mpBaseEditor->getPlainTextEdit()->find(mpFindComboBox->currentText(), flags)) {
    mpBaseEditor->getPlainTextEdit()->textCursor().insertText(mpReplaceWithTextBox->text());
    i++;
  }
  mpBaseEditor->getPlainTextEdit()->textCursor().endEditBlock();
}

/*!
 * \brief FindReplaceWidget::keyPressEvent
 * \param pEvent
 */
void FindReplaceWidget::keyPressEvent(QKeyEvent *pEvent)
{
  if (pEvent->key() == Qt::Key_Escape) {
    mpBaseEditor->getPlainTextEdit()->setFocus(Qt::ActiveWindowFocusReason);
    return;
  }
  QWidget::keyPressEvent(pEvent);
}

/*!
 * \brief FindReplaceWidget::validateRegularExpression
 * Checks whether the passed text is a valid regular expression
 * \param text
 */
void FindReplaceWidget::validateRegularExpression(const QString &text)
{
  if (!mpRegularExpressionCheckBox->isChecked() || text.size() == 0) {
    return; // nothing to validate
  }
  QRegExp reg(text, (mpCaseSensitiveCheckBox->isChecked() ? Qt::CaseSensitive : Qt::CaseInsensitive));
  if (!reg.isValid()) {
    QMessageBox::critical( this, "Find", reg.errorString());
  }
}

/*!
 * \brief FindReplaceWidget::regularExpressionSelected
 * The regular expression checkbox was selected
 * \param selected
 */
void FindReplaceWidget::regularExpressionSelected(bool selected)
{
  if (selected) {
    validateRegularExpression(mpFindComboBox->currentText());
  } else {
    validateRegularExpression("");
  }
}

/*!
 * \brief FindReplaceWidget::textToFindChanged
 * When the text edit contents changed
 */
void FindReplaceWidget::textToFindChanged()
{
  mpFindNextButton->setEnabled(mpFindComboBox->currentText().size() > 0);
}

/*!
 * \class GotoLineDialog
 * An interface to goto a specific line in editor.
 */
GotoLineDialog::GotoLineDialog(BaseEditor *pBaseEditor)
  : QDialog(pBaseEditor)
{
  setWindowTitle(QString(Helper::applicationName).append(" - Go to Line"));
  setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
  setAttribute(Qt::WA_DeleteOnClose);
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

/*!
 * \brief GotoLineDialog::exec
 * Reimplementation of QDialog::exec
 * \return
 */
int GotoLineDialog::exec()
{
  if (mpBaseEditor->getModelWidget() && mpBaseEditor->getModelWidget()->getLibraryTreeItem()->isInPackageOneFile() &&
      mpBaseEditor->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    int lineNumberStart = mpBaseEditor->getModelWidget()->getLibraryTreeItem()->mClassInformation.lineNumberStart;
    mpLineNumberLabel->setText(tr("Enter line number (%1 to %2):").arg(QString::number(lineNumberStart))
                               .arg(QString::number(mpBaseEditor->getPlainTextEdit()->blockCount() + lineNumberStart - 1)));
  } else {
    mpLineNumberLabel->setText(tr("Enter line number (1 to %1):").arg(QString::number(mpBaseEditor->getPlainTextEdit()->blockCount())));
  }
  QIntValidator *intValidator = new QIntValidator(this);
  intValidator->setRange(1, mpBaseEditor->getPlainTextEdit()->blockCount());
  mpLineNumberTextBox->setValidator(intValidator);
  return QDialog::exec();
}

/*!
 * \brief GotoLineDialog::goToLineNumber
 * Slot activated when mpOkButton clicked signal raised.
 */
void GotoLineDialog::goToLineNumber()
{
  mpBaseEditor->goToLineNumber(mpLineNumberTextBox->text().toInt());
  accept();
}
