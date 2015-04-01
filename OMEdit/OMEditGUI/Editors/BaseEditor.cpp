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
#include "ModelWidgetContainer.h"
#include "Helper.h"

BaseEditor::BaseEditor(MainWindow *pMainWindow)
  : QPlainTextEdit(pMainWindow), mpModelWidget(0), mpMainWindow(pMainWindow), mCanHaveBreakpoints(false)
{
  initialize();
}

BaseEditor::BaseEditor(ModelWidget *pModelWidget)
  : QPlainTextEdit(pModelWidget), mpModelWidget(pModelWidget), mCanHaveBreakpoints(false)
{
  mpMainWindow = pModelWidget->getModelWidgetContainer()->getMainWindow();
  initialize();
}

void BaseEditor::initialize()
{
  setObjectName("BaseEditor");
  document()->setDocumentMargin(2);
  // line numbers widget
  mpLineNumberArea = new LineNumberArea(this);
  updateLineNumberAreaWidth(0);
  highlightCurrentLine();
  updateCursorPosition();
  createActions();
  setLineWrapping();
  connect(this, SIGNAL(blockCountChanged(int)), SLOT(updateLineNumberAreaWidth(int)));
  connect(this, SIGNAL(updateRequest(QRect,int)), SLOT(updateLineNumberArea(QRect,int)));
  connect(this, SIGNAL(cursorPositionChanged()), SLOT(highlightCurrentLine()));
  connect(this, SIGNAL(cursorPositionChanged()), SLOT(updateCursorPosition()));
  connect(this->document(), SIGNAL(contentsChange(int,int,int)), SLOT(contentsHasChanged(int,int,int)));
  OptionsDialog *pOptionsDialog = mpMainWindow->getOptionsDialog();
  connect(pOptionsDialog, SIGNAL(updateLineWrapping()), SLOT(setLineWrapping()));
  setContextMenuPolicy(Qt::CustomContextMenu);
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
}

void BaseEditor::createActions()
{
  // find replace class action
  mpFindReplaceAction = new QAction(QString(Helper::findReplaceModelicaText), this);
  mpFindReplaceAction->setStatusTip(tr("Shows the Find/Replace window"));
  mpFindReplaceAction->setShortcut(QKeySequence("Ctrl+f"));
  connect(mpFindReplaceAction, SIGNAL(triggered()), SLOT(showFindReplaceDialog()));
  // clear find/replace texts action
  mpClearFindReplaceTextsAction = new QAction(tr("Clear Find/Replace Texts"), this);
  mpClearFindReplaceTextsAction->setStatusTip(tr("Clears the Find/Replace text items"));
  connect(mpClearFindReplaceTextsAction, SIGNAL(triggered()), SLOT(clearFindReplaceTexts()));
  // goto line action
  mpGotoLineNumberAction = new QAction(tr("Go to Line"), this);
  mpGotoLineNumberAction->setStatusTip(tr("Shows the Go to Line Number window"));
  mpGotoLineNumberAction->setShortcut(QKeySequence("Ctrl+l"));
  connect(mpGotoLineNumberAction, SIGNAL(triggered()), SLOT(showGotoLineNumberDialog()));
  /* Toggle breakpoint action */
  mpToggleBreakpointAction = new QAction(tr("Toggle Breakpoint"), this);
  connect(mpToggleBreakpointAction, SIGNAL(triggered()), SLOT(toggleBreakpoint()));
  // toggle comment action
  mpToggleCommentSelectionAction = new QAction(tr("Toggle Comment Selection"), this);
  mpToggleCommentSelectionAction->setShortcut(QKeySequence("Ctrl+k"));
  connect(mpToggleCommentSelectionAction, SIGNAL(triggered()), SLOT(toggleCommentSelection()));
}

//! Calculate appropriate width for LineNumberArea.
//! @return int width of LineNumberArea.
int BaseEditor::lineNumberAreaWidth()
{
  int digits = 2;
  int max = qMax(1, document()->blockCount());
  while (max >= 10)
  {
    max /= 10;
    ++digits;
  }
  int space = 10 + fontMetrics().width(QLatin1Char('9')) * digits;
  if (canHaveBreakpoints())
    space += 16;  /* the breakpoint enable/disable svg is 16*16. */
  return space;
}

/*!
  Activated whenever LineNumberArea Widget paint event is raised.
  Writes the line numbers for the visible blocks and draws the breakpoint markers.
  */
void BaseEditor::lineNumberAreaPaintEvent(QPaintEvent *event)
{
  QPainter painter(mpLineNumberArea);
  painter.fillRect(event->rect(), QColor(240, 240, 240));

  QTextBlock block = firstVisibleBlock();
  int blockNumber = block.blockNumber();
  int top = (int) blockBoundingGeometry(block).translated(contentOffset()).top();
  int bottom = top + (int) blockBoundingRect(block).height();
  const QFontMetrics fm(mpLineNumberArea->font());
  int fmLineSpacing = fm.lineSpacing();

  while (block.isValid() && top <= event->rect().bottom())
  {
    /* paint line numbers */
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
    /* paint breakpoints */
    TextBlockUserData *pTextBlockUserData = static_cast<TextBlockUserData*>(block.userData());
    if (pTextBlockUserData && canHaveBreakpoints())
    {
      int xoffset = 0;
      foreach (ITextMark *mk, pTextBlockUserData->marks())
      {
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

/**
 * Activated whenever LineNumberArea Widget mouse press event is raised.
 */
void BaseEditor::lineNumberAreaMouseEvent(QMouseEvent *event)
{
  /* if breakpoints are not enabled for this editor then return. */
  if (!canHaveBreakpoints()) {
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
    if (!mpModelWidget->getLibraryTreeNode()->isSaved()) {
      mpMainWindow->getInfoBar()->showMessage(tr("<b>Information: </b>Breakpoints are only allowed on saved classes."));
      return;
    }
    QString fileName = mpModelWidget->getLibraryTreeNode()->getFileName();
    int lineNumber = cursor.blockNumber() + 1;
    if (event->button() == Qt::LeftButton) {  //! left clicked: add/remove breakpoint
      toggleBreakpoint(fileName, lineNumber);
    } else if (event->button() == Qt::RightButton) {  //! right clicked: show context menu
      QMenu menu(this);
      mpToggleBreakpointAction->setData(QStringList() << fileName << QString::number(lineNumber));
      menu.addAction(mpToggleBreakpointAction);
      menu.exec(event->globalPos());
    }
  }
}

/*!
  Takes the cursor to the specific line.
  \param lineNumber - the line number to go.
  */
void BaseEditor::goToLineNumber(int lineNumber)
{
  const QTextBlock &block = document()->findBlockByNumber(lineNumber - 1); // -1 since text index start from 0
  if (block.isValid()) {
    QTextCursor cursor(block);
    cursor.movePosition(QTextCursor::Right, QTextCursor::MoveAnchor, 0);
    setTextCursor(cursor);
    centerCursor();
  }
}

void BaseEditor::setCanHaveBreakpoints(bool canHaveBreakpoints)
{
  mCanHaveBreakpoints = canHaveBreakpoints;
  mpLineNumberArea->setMouseTracking(canHaveBreakpoints);
}

void BaseEditor::toggleBreakpoint(const QString fileName, int lineNumber)
{
  BreakpointsTreeModel *pBreakpointsTreeModel = mpMainWindow->getDebuggerMainWindow()->getBreakpointsWidget()->getBreakpointsTreeModel();
  BreakpointMarker *pBreakpointMarker = pBreakpointsTreeModel->findBreakpointMarker(fileName, lineNumber);
  if (!pBreakpointMarker) {
    /* create a breakpoint marker */
    pBreakpointMarker = new BreakpointMarker(fileName, lineNumber, pBreakpointsTreeModel);
    pBreakpointMarker->setEnabled(true);
    /* Add the marker to document marker */
    mpDocumentMarker->addMark(pBreakpointMarker, lineNumber);
    /* insert the breakpoint in BreakpointsWidget */
    pBreakpointsTreeModel->insertBreakpoint(pBreakpointMarker, mpModelWidget->getLibraryTreeNode(), pBreakpointsTreeModel->getRootBreakpointTreeItem());
  } else {
    mpDocumentMarker->removeMark(pBreakpointMarker);
    pBreakpointsTreeModel->removeBreakpoint(pBreakpointMarker);
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

/*!
 * \brief BaseEditor::keyPressEvent
 * Reimplementation of keyPressEvent.
 * \param pEvent
 */
void BaseEditor::keyPressEvent(QKeyEvent *pEvent)
{
  if (pEvent->key() == Qt::Key_Tab || pEvent->key() == Qt::Key_Backtab) {
    // tab or backtab is pressed.
    indentOrUnindent(pEvent->key() == Qt::Key_Tab);
    return;
  } else if (pEvent->modifiers().testFlag(Qt::ControlModifier) && pEvent->key() == Qt::Key_L) {
    // ctrl+l is pressed.
    showGotoLineNumberDialog();
    return;
  } else if (pEvent->modifiers().testFlag(Qt::ControlModifier) && pEvent->key() == Qt::Key_K) {
    // ctrl+k is pressed.
    toggleCommentSelection();
    return;
  } else if (pEvent->modifiers().testFlag(Qt::ShiftModifier) && (pEvent->key() == Qt::Key_Enter || pEvent->key() == Qt::Key_Return)) {
    /* Ticket #2273. Change shift+enter to enter. */
    pEvent->setModifiers(Qt::NoModifier);
  }
  QPlainTextEdit::keyPressEvent(pEvent);
}

/*!
 * \brief BaseEditor::addDefaultContextMenuActions
 * Adds the default contextmenu actions.
 * \param pMenu
 */
void BaseEditor::addDefaultContextMenuActions(QMenu *pMenu)
{
  pMenu->addSeparator();
  pMenu->addAction(mpFindReplaceAction);
  pMenu->addAction(mpClearFindReplaceTextsAction);
  pMenu->addAction(mpGotoLineNumberAction);
}

/*!
 * \brief BaseEditor::updateLineNumberAreaWidth
 * Updates the width of LineNumberArea.
 * \param newBlockCount
 */
void BaseEditor::updateLineNumberAreaWidth(int newBlockCount)
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
void BaseEditor::updateLineNumberArea(const QRect &rect, int dy)
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
 * \brief BaseEditor::highlightCurrentLine
 * Slot activated when editor's cursorPositionChanged signal is raised.
 * Hightlights the current line.
 */
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

/*!
 * \brief BaseEditor::updateCursorPosition
 * Slot activated when editor's cursorPositionChanged signal is raised.
 * Updates the cursorPostionLabel i.e Line: 12, Col:123.
 */
void BaseEditor::updateCursorPosition()
{
  if (mpModelWidget) {
    const QTextBlock block = textCursor().block();
    const int line = block.blockNumber() + 1;
    const int column = textCursor().columnNumber();
    Label *pCursorPositionLabel = mpModelWidget->getCursorPositionLabel();
    pCursorPositionLabel->setText(QString("Line: %1, Col: %2").arg(line).arg(column));
  }
}

/*!
 * \brief BaseEditor::setLineWrapping
 * \todo For now keep this function in BaseEditor. We should make it a pure virtual and should ask derived classes to implement it.
 */
void BaseEditor::setLineWrapping()
{
  OptionsDialog *pOptionsDialog = mpMainWindow->getOptionsDialog();
  if (pOptionsDialog->getModelicaTextEditorPage()->getLineWrappingCheckbox()->isChecked()) {
    setLineWrapMode(QPlainTextEdit::WidgetWidth);
  } else {
    setLineWrapMode(QPlainTextEdit::NoWrap);
  }
}

void BaseEditor::showFindReplaceDialog()
{
  FindReplaceDialog *pFindReplaceDialog = mpMainWindow->getFindReplaceDialog();
  pFindReplaceDialog->setTextEdit(this);
  pFindReplaceDialog->show();
  pFindReplaceDialog->raise();
  pFindReplaceDialog->activateWindow();
}

void BaseEditor::clearFindReplaceTexts()
{
  QSettings *pSettings = OpenModelica::getApplicationSettings();
  pSettings->remove("findReplaceDialog/textsToFind");
  mpMainWindow->getFindReplaceDialog()->readFindTextFromSettings();
}

void BaseEditor::showGotoLineNumberDialog()
{
  GotoLineDialog *pGotoLineWidget = new GotoLineDialog(this);
  pGotoLineWidget->exec();
}

/**
 * Slot activated when set breakpoint is seleteted from line number area context menu.
 */
void BaseEditor::toggleBreakpoint()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction) {
    QStringList list = pAction->data().toStringList();
    toggleBreakpoint(list.at(0), list.at(1).toInt());
  }
}

/*!
 * \brief BaseEditor::indentOrUnindent
 * Indents or unindents the code.
 * \param doIndent
 * \todo For now keep this function in BaseEditor. We should make it a pure virtual and should ask derived classes to implement it.
 */
void BaseEditor::indentOrUnindent(bool doIndent)
{
  const ModelicaTabSettings *pModelicaTabSettings;
  pModelicaTabSettings = mpMainWindow->getOptionsDialog()->getModelicaTabSettings();
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
        int indentPosition = pModelicaTabSettings->lineIndentPosition(text);
        if (!doIndent && !indentPosition) {
          indentPosition = pModelicaTabSettings->firstNonSpace(text);
        }
        int targetColumn = pModelicaTabSettings->indentedColumn(pModelicaTabSettings->columnAt(text, indentPosition), doIndent);
        cursor.setPosition(block.position() + indentPosition);
        cursor.insertText(pModelicaTabSettings->indentationString(0, targetColumn));
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
  int spaces = pModelicaTabSettings->spacesLeftFromPosition(text, indentPosition);
  int startColumn = pModelicaTabSettings->columnAt(text, indentPosition - spaces);
  int targetColumn = pModelicaTabSettings->indentedColumn(pModelicaTabSettings->columnAt(text, indentPosition), doIndent);
  cursor.setPosition(block.position() + indentPosition);
  cursor.setPosition(block.position() + indentPosition - spaces, QTextCursor::KeepAnchor);
  cursor.removeSelectedText();
  cursor.insertText(pModelicaTabSettings->indentationString(startColumn, targetColumn));
  cursor.endEditBlock();
  setTextCursor(cursor);
}

//! @class GotoLineWidget
//! @brief An interface to goto a specific line in BaseEditor.

//! Constructor
GotoLineDialog::GotoLineDialog(BaseEditor *pBaseEditor)
  : QDialog(pBaseEditor, Qt::WindowTitleHint)
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

//! Reimplementation of QDialog::exec
int GotoLineDialog::exec()
{
  mpLineNumberLabel->setText(QString("Enter line number (1 to ").append(QString::number(mpBaseEditor->blockCount())).append("):"));
  QIntValidator *intValidator = new QIntValidator(this);
  intValidator->setRange(1, mpBaseEditor->blockCount());
  mpLineNumberTextBox->setValidator(intValidator);
  return QDialog::exec();
}

//! Slot activated when mpOkButton clicked signal raised.
void GotoLineDialog::goToLineNumber()
{
  mpBaseEditor->goToLineNumber(mpLineNumberTextBox->text().toInt());
  accept();
}
