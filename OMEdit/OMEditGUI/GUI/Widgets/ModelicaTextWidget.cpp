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

#include "ModelicaTextWidget.h"
#include "Helper.h"
#include <QtGui>
#include <QSettings>

/*!
  \class CommentDefinition
  \brief Defines the single and multi line comments styles. The class implementation and logic is inspired from Qt Creator sources.
  */
CommentDefinition::CommentDefinition() :
    m_afterWhiteSpaces(false),
    m_singleLine(QLatin1String("//")),
    m_multiLineStart(QLatin1String("/*")),
    m_multiLineEnd(QLatin1String("*/"))
{}

CommentDefinition &CommentDefinition::setAfterWhiteSpaces(const bool afterWhiteSpaces)
{
    m_afterWhiteSpaces = afterWhiteSpaces;
    return *this;
}

CommentDefinition &CommentDefinition::setSingleLine(const QString &singleLine)
{
    m_singleLine = singleLine;
    return *this;
}

CommentDefinition &CommentDefinition::setMultiLineStart(const QString &multiLineStart)
{
    m_multiLineStart = multiLineStart;
    return *this;
}

CommentDefinition &CommentDefinition::setMultiLineEnd(const QString &multiLineEnd)
{
    m_multiLineEnd = multiLineEnd;
    return *this;
}

bool CommentDefinition::isAfterWhiteSpaces() const
{ return m_afterWhiteSpaces; }

const QString &CommentDefinition::singleLine() const
{ return m_singleLine; }

const QString &CommentDefinition::multiLineStart() const
{ return m_multiLineStart; }

const QString &CommentDefinition::multiLineEnd() const
{ return m_multiLineEnd; }

bool CommentDefinition::hasSingleLineStyle() const
{ return !m_singleLine.isEmpty(); }

bool CommentDefinition::hasMultiLineStyle() const
{ return !m_multiLineStart.isEmpty() && !m_multiLineEnd.isEmpty(); }

void CommentDefinition::clearCommentStyles()
{
    m_singleLine.clear();
    m_multiLineStart.clear();
    m_multiLineEnd.clear();
}

namespace {

bool isComment(const QString &text,
               int index,
               const CommentDefinition &definition,
               const QString & (CommentDefinition::* comment) () const)
{
    const QString &commentType = ((definition).*(comment))();
    const int length = commentType.length();

    Q_ASSERT(text.length() - index >= length);

    int i = 0;
    while (i < length) {
        if (text.at(index + i) != commentType.at(i))
            return false;
        ++i;
    }
    return true;
}

}

//! @class ModelicaEditor
//! @brief An editor for Modelica Text. Subclass QPlainTextEdit

//! Constructor
ModelicaTextEdit::ModelicaTextEdit(ModelicaTextWidget *pParent)
  : QPlainTextEdit(pParent), mLastValidText(""), mTextChanged(false)
{
  mpModelicaTextWidget = pParent;
  setTabStopWidth(Helper::tabWidth);
  setObjectName("ModelicaTextEdit");
  setContextMenuPolicy(Qt::CustomContextMenu);
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  document()->setDocumentMargin(2);
  createActions();
  setLineWrapping();
  OptionsDialog *pOptionsDialog = mpModelicaTextWidget->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getOptionsDialog();
  connect(pOptionsDialog, SIGNAL(updateLineWrapping()), SLOT(setLineWrapping()));
  connect(this, SIGNAL(focusOut()), mpModelicaTextWidget->getModelWidget(), SLOT(modelicaEditorTextChanged()));
  connect(this->document(), SIGNAL(contentsChange(int,int,int)), SLOT(contentsHasChanged(int,int,int)));
  // line numbers widget
  mpLineNumberArea = new LineNumberArea(this);
  connect(this, SIGNAL(blockCountChanged(int)), this, SLOT(updateLineNumberAreaWidth(int)));
  connect(this, SIGNAL(updateRequest(QRect,int)), this, SLOT(updateLineNumberArea(QRect,int)));
  connect(this, SIGNAL(cursorPositionChanged()), this, SLOT(highlightCurrentLine()));
  connect(this, SIGNAL(cursorPositionChanged()), this, SLOT(updateCursorPosition()));
  updateLineNumberAreaWidth(0);
  highlightCurrentLine();
  updateCursorPosition();
}

void ModelicaTextEdit::createActions()
{
  mpToggleCommentSelectionAction = new QAction(tr("Toggle Comment Selection"), this);
  mpToggleCommentSelectionAction->setShortcut(QKeySequence("Ctrl+k"));
  connect(mpToggleCommentSelectionAction, SIGNAL(triggered()), SLOT(toggleCommentSelection()));
}

void ModelicaTextEdit::setLastValidText(QString validText)
{
  mLastValidText = validText;
}

//! Uses the OMC parseString API to check the class names inside the Modelica Text
//! @return QStringList a list of class names
QStringList ModelicaTextEdit::getClassNames(QString *errorString)
{
  OMCProxy *pOMCProxy = mpModelicaTextWidget->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
  QStringList classNames;
  LibraryTreeNode *pLibraryTreeNode = mpModelicaTextWidget->getModelWidget()->getLibraryTreeNode();
  if (toPlainText().isEmpty())
  {
    *errorString = tr("Start and End modifiers are different");
    return QStringList();
  }
  else
  {
    if (pLibraryTreeNode->getParentName().isEmpty())
    {
      classNames = pOMCProxy->parseString(StringHandler::escapeString(toPlainText()));
    }
    else
    {
      classNames = pOMCProxy->parseString("within " + pLibraryTreeNode->getParentName() + ";" + StringHandler::escapeString(toPlainText()));
    }
  }
  bool existModel = false;
  QStringList existingmodelsList;
  // check if the class already exists
  foreach(QString className, classNames)
  {
    if (pLibraryTreeNode->getNameStructure().compare(className) != 0)
    {
      if (pOMCProxy->existClass(className))
      {
        existingmodelsList.append(className);
        existModel = true;
      }
    }
  }
  // check if existModel is true
  if (existModel)
  {
    *errorString = QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES)).arg(existingmodelsList.join(",")).append("\n")
        .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(""));
    return QStringList();
  }
  return classNames;
}

//! When user make some changes in the ModelicaEditor text then this method validates the text and show text correct options.
bool ModelicaTextEdit::validateModelicaText()
{
  if (mTextChanged)
  {
    // if the user makes few mistakes in the text then dont let him change the perspective
    if (!emit focusOut())
    {
      MainWindow *pMainWindow = mpModelicaTextWidget->getModelWidget()->getModelWidgetContainer()->getMainWindow();
      QMessageBox *pMessageBox = new QMessageBox(pMainWindow);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - Error"));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setText(GUIMessages::getMessage(GUIMessages::ERROR_IN_MODELICA_TEXT)
                      .append(GUIMessages::getMessage(GUIMessages::CHECK_MESSAGES_BROWSER))
                      .append(GUIMessages::getMessage(GUIMessages::REVERT_PREVIOUS_OR_FIX_ERRORS_MANUALLY)));
      pMessageBox->addButton(tr("Revert from previous"), QMessageBox::AcceptRole);
      pMessageBox->addButton(tr("Fix errors manually"), QMessageBox::RejectRole);
      int answer = pMessageBox->exec();
      switch (answer)
      {
        case QMessageBox::AcceptRole:
          mTextChanged = false;
          // revert back to last valid block
          setPlainText(mLastValidText);
          return true;
        case QMessageBox::RejectRole:
          mTextChanged = true;
          return false;
        default:
          // should never be reached
          mTextChanged = true;
          return false;
      }
    }
    else
    {
      mTextChanged = false;
    }
  }
  return true;
}

//! Reimplementation of resize event.
//! Resets the size of LineNumberArea.
void ModelicaTextEdit::resizeEvent(QResizeEvent *pEvent)
{
  QPlainTextEdit::resizeEvent(pEvent);

  QRect cr = contentsRect();
  mpLineNumberArea->setGeometry(QRect(cr.left(), cr.top(), lineNumberAreaWidth(), cr.height()));
}

void ModelicaTextEdit::keyPressEvent(QKeyEvent *pEvent)
{
  if (pEvent->modifiers().testFlag(Qt::ControlModifier) && pEvent->key() == Qt::Key_K)
  {
    toggleCommentSelection();
    return;
  }
  /* Ticket #2273. Change shift+enter to enter. */
  else if (pEvent->modifiers().testFlag(Qt::ShiftModifier) && (pEvent->key() == Qt::Key_Enter || pEvent->key() == Qt::Key_Return))
  {
    pEvent->setModifiers(Qt::NoModifier);
  }
  QPlainTextEdit::keyPressEvent(pEvent);
}

//! Calculate appropriate width for LineNumberArea.
//! @return int width of LineNumberArea.
int ModelicaTextEdit::lineNumberAreaWidth()
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

//! Updates the width of LineNumberArea.
void ModelicaTextEdit::updateLineNumberAreaWidth(int newBlockCount)
{
  Q_UNUSED(newBlockCount);
  setViewportMargins(lineNumberAreaWidth(), 0, 0, 0);
}

//! Slot activated when ModelicaEditor cursorPositionChanged signal is raised.
//! Hightlights the current line.
void ModelicaTextEdit::highlightCurrentLine()
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

//! Slot activated when ModelicaEditor cursorPositionChanged signal is raised.
//! Updates the cursorPostionLabel i.e Line: 12, Col:123.
void ModelicaTextEdit::updateCursorPosition()
{
  const QTextBlock block = textCursor().block();
  const int line = block.blockNumber() + 1;
  const int column = textCursor().columnNumber();
  Label *pCursorPositionLabel = mpModelicaTextWidget->getModelWidget()->getCursorPositionLabel();
  pCursorPositionLabel->setText(QString("Line: %1, Col: %2").arg(line).arg(column));
}

//! Slot activated when ModelicaEditor updateRequest signal is raised.
//! Scrolls the LineNumberArea Widget and also updates its width if required.
void ModelicaTextEdit::updateLineNumberArea(const QRect &rect, int dy)
{
  if (dy)
    mpLineNumberArea->scroll(0, dy);
  else
    mpLineNumberArea->update(0, rect.y(), mpLineNumberArea->width(), rect.height());

  if (rect.contains(viewport()->rect()))
    updateLineNumberAreaWidth(0);
}

void ModelicaTextEdit::showContextMenu(QPoint point)
{
  MainWindow *pMainWindow = mpModelicaTextWidget->getModelWidget()->getModelWidgetContainer()->getMainWindow();
  QMenu *pMenu = createStandardContextMenu();
  /* Add custom actions here */
  pMenu->addSeparator();
  pMenu->addAction(pMainWindow->getFindReplaceAction());
  pMenu->addAction(pMainWindow->getClearFindReplaceTextsAction());
  pMenu->addAction(pMainWindow->getGotoLineNumberAction());
  pMenu->addSeparator();
  pMenu->addAction(mpToggleCommentSelectionAction);
  pMenu->exec(mapToGlobal(point));
  delete pMenu;
}

/*!
  Slot activated when toggle comment selection is seleteted from context menu or ctrl+k is pressed.
  The implementation and logic is inspired from Qt Creator sources.
  */
void ModelicaTextEdit::toggleCommentSelection()
{
  CommentDefinition definition;
  if (!definition.hasSingleLineStyle() && !definition.hasMultiLineStyle())
    return;

  QTextCursor cursor = textCursor();
  QTextDocument *doc = cursor.document();
  cursor.beginEditBlock();

  int pos = cursor.position();
  int anchor = cursor.anchor();
  int start = qMin(anchor, pos);
  int end = qMax(anchor, pos);
  bool anchorIsStart = (anchor == start);

  QTextBlock startBlock = doc->findBlock(start);
  QTextBlock endBlock = doc->findBlock(end);

  if (end > start && endBlock.position() == end) {
    --end;
    endBlock = endBlock.previous();
  }

  bool doMultiLineStyleUncomment = false;
  bool doMultiLineStyleComment = false;
  bool doSingleLineStyleUncomment = false;

  bool hasSelection = cursor.hasSelection();

  if (hasSelection && definition.hasMultiLineStyle()) {

    QString startText = startBlock.text();
    int startPos = start - startBlock.position();
    const int multiLineStartLength = definition.multiLineStart().length();
    bool hasLeadingCharacters = !startText.left(startPos).trimmed().isEmpty();

    if (startPos >= multiLineStartLength
        && isComment(startText,
                     startPos - multiLineStartLength,
                     definition,
                     &CommentDefinition::multiLineStart)) {
      startPos -= multiLineStartLength;
      start -= multiLineStartLength;
    }

    bool hasSelStart = (startPos <= startText.length() - multiLineStartLength
                        && isComment(startText,
                                     startPos,
                                     definition,
                                     &CommentDefinition::multiLineStart));

    QString endText = endBlock.text();
    int endPos = end - endBlock.position();
    const int multiLineEndLength = definition.multiLineEnd().length();
    bool hasTrailingCharacters =
        !endText.left(endPos).remove(definition.singleLine()).trimmed().isEmpty()
        && !endText.mid(endPos).trimmed().isEmpty();

    if (endPos <= endText.length() - multiLineEndLength
        && isComment(endText, endPos, definition, &CommentDefinition::multiLineEnd)) {
      endPos += multiLineEndLength;
      end += multiLineEndLength;
    }

    bool hasSelEnd = (endPos >= multiLineEndLength
                      && isComment(endText,
                                   endPos - multiLineEndLength,
                                   definition,
                                   &CommentDefinition::multiLineEnd));

    doMultiLineStyleUncomment = hasSelStart && hasSelEnd;
    doMultiLineStyleComment = !doMultiLineStyleUncomment
        && (hasLeadingCharacters
            || hasTrailingCharacters
            || !definition.hasSingleLineStyle());
  } else if (!hasSelection && !definition.hasSingleLineStyle()) {

    QString text = startBlock.text().trimmed();
    doMultiLineStyleUncomment = text.startsWith(definition.multiLineStart())
        && text.endsWith(definition.multiLineEnd());
    doMultiLineStyleComment = !doMultiLineStyleUncomment && !text.isEmpty();

    start = startBlock.position();
    end = endBlock.position() + endBlock.length() - 1;

    if (doMultiLineStyleUncomment) {
      int offset = 0;
      text = startBlock.text();
      const int length = text.length();
      while (offset < length && text.at(offset).isSpace())
        ++offset;
      start += offset;
    }
  }

  if (doMultiLineStyleUncomment) {
    cursor.setPosition(end);
    cursor.movePosition(QTextCursor::PreviousCharacter,
                        QTextCursor::KeepAnchor,
                        definition.multiLineEnd().length());
    cursor.removeSelectedText();
    cursor.setPosition(start);
    cursor.movePosition(QTextCursor::NextCharacter,
                        QTextCursor::KeepAnchor,
                        definition.multiLineStart().length());
    cursor.removeSelectedText();
  } else if (doMultiLineStyleComment) {
    cursor.setPosition(end);
    cursor.insertText(definition.multiLineEnd());
    cursor.setPosition(start);
    cursor.insertText(definition.multiLineStart());
  } else {
    endBlock = endBlock.next();
    doSingleLineStyleUncomment = true;
    for (QTextBlock block = startBlock; block != endBlock; block = block.next()) {
      QString text = block.text().trimmed();
      if (!text.isEmpty() && !text.startsWith(definition.singleLine())) {
        doSingleLineStyleUncomment = false;
        break;
      }
    }

    const int singleLineLength = definition.singleLine().length();
    for (QTextBlock block = startBlock; block != endBlock; block = block.next()) {
      if (doSingleLineStyleUncomment) {
        QString text = block.text();
        int i = 0;
        while (i <= text.size() - singleLineLength) {
          if (isComment(text, i, definition, &CommentDefinition::singleLine)) {
            cursor.setPosition(block.position() + i);
            cursor.movePosition(QTextCursor::NextCharacter,
                                QTextCursor::KeepAnchor,
                                singleLineLength);
            cursor.removeSelectedText();
            break;
          }
          if (!text.at(i).isSpace())
            break;
          ++i;
        }
      } else {
        QString text = block.text();
        foreach(QChar c, text) {
          if (!c.isSpace()) {
            if (definition.isAfterWhiteSpaces())
              cursor.setPosition(block.position() + text.indexOf(c));
            else
              cursor.setPosition(block.position());
            cursor.insertText(definition.singleLine());
            break;
          }
        }
      }
    }
  }
  // adjust selection when commenting out
  if (hasSelection && !doMultiLineStyleUncomment && !doSingleLineStyleUncomment) {
    cursor = textCursor();
    if (!doMultiLineStyleComment)
      start = startBlock.position(); // move the comment into the selection
    int lastSelPos = anchorIsStart ? cursor.position() : cursor.anchor();
    if (anchorIsStart) {
      cursor.setPosition(start);
      cursor.setPosition(lastSelPos, QTextCursor::KeepAnchor);
    } else {
      cursor.setPosition(lastSelPos);
      cursor.setPosition(start, QTextCursor::KeepAnchor);
    }
    setTextCursor(cursor);
  }
  cursor.endEditBlock();
}

//! Activated whenever LineNumberArea Widget paint event is raised.
//! Writes the line numbers for the visible blocks.
void ModelicaTextEdit::lineNumberAreaPaintEvent(QPaintEvent *event)
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

//! Reimplementation of QPlainTextEdit::setPlainText method.
//! Makes sure we dont update if the passed text is same.
//! @param text the string to set.
void ModelicaTextEdit::setPlainText(const QString &text)
{
  if (text != toPlainText())
  {
    QPlainTextEdit::setPlainText(text);
    updateLineNumberAreaWidth(0);
  }
}

//! Slot activated when ModelicaTextEdit's QTextDocument contentsChanged SIGNAL is raised.
//! Sets the model as modified so that user knows that his current model is not saved.
void ModelicaTextEdit::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  if (mpModelicaTextWidget->isVisible())
  {
    if (charsRemoved == 0 && charsAdded == 0)
      return;
    /* if user is changing the system library class. */
    if (mpModelicaTextWidget->getModelWidget()->getLibraryTreeNode()->isSystemLibrary())
    {
      InfoBar *pInfoBar = mpModelicaTextWidget->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getInfoBar();
      pInfoBar->showMessage(tr("<b>Warning: </b>You are changing a system library class. System libraries are always read-only. Your changes will not be saved."));
    }
    /* if user is changing the read-only class. */
    else if (mpModelicaTextWidget->getModelWidget()->getLibraryTreeNode()->isReadOnly())
    {
      InfoBar *pInfoBar = mpModelicaTextWidget->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getInfoBar();
      pInfoBar->showMessage(tr("<b>Warning: </b>You are changing a read-only class."));
    }
    /* if user is changing the normal class. */
    else
    {
      mpModelicaTextWidget->getModelWidget()->setModelModified();
      mTextChanged = true;
    }
  }
}

void ModelicaTextEdit::setLineWrapping()
{
  OptionsDialog *pOptionsDialog = mpModelicaTextWidget->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getOptionsDialog();
  if (pOptionsDialog->getModelicaTextEditorPage()->getLineWrappingCheckbox()->isChecked())
    setLineWrapMode(QPlainTextEdit::WidgetWidth);
  else
    setLineWrapMode(QPlainTextEdit::NoWrap);
}

//! @class ModelicaTextHighlighter
//! @brief A syntax highlighter for ModelicaEditor.

//! Constructor
ModelicaTextHighlighter::ModelicaTextHighlighter(ModelicaTextSettings *pSettings, MainWindow *pMainWindow, QTextDocument *pParent)
  : QSyntaxHighlighter(pParent)
{
  mpModelicaTextSettings = pSettings;
  mpMainWindow = pMainWindow;
  initializeSettings();
}

//! Initialized the syntax highlighter with default values.
void ModelicaTextHighlighter::initializeSettings()
{
  QTextDocument *pTextDocument = qobject_cast<QTextDocument*>(parent());
  QFont font;
  font.setFamily(mpModelicaTextSettings->getFontFamily());
  font.setPointSizeF(mpModelicaTextSettings->getFontSize());
  pTextDocument->setDefaultFont(font);
  // set color highlighting
  mHighlightingRules.clear();
  HighlightingRule rule;
  mTextFormat.setForeground(mpModelicaTextSettings->getTextRuleColor());
  mKeywordFormat.setForeground(mpModelicaTextSettings->getKeywordRuleColor());
  mTypeFormat.setForeground(mpModelicaTextSettings->getTypeRuleColor());
  mSingleLineCommentFormat.setForeground(mpModelicaTextSettings->getCommentRuleColor());
  mMultiLineCommentFormat.setForeground(mpModelicaTextSettings->getCommentRuleColor());
  mFunctionFormat.setForeground(mpModelicaTextSettings->getFunctionRuleColor());
  mQuotationFormat.setForeground(QColor(mpModelicaTextSettings->getQuotesRuleColor()));
  // Priority: keyword > func() > ident > number. Yes, the order matters :)
  mNumberFormat.setForeground(mpModelicaTextSettings->getNumberRuleColor());
  rule.mPattern = QRegExp("[0-9][0-9]*([.][0-9]*)?([eE][+-]?[0-9]*)?");
  rule.mFormat = mNumberFormat;
  mHighlightingRules.append(rule);
  rule.mPattern = QRegExp("\\b[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTextFormat;
  mHighlightingRules.append(rule);
  // keywords
  QStringList keywordPatterns;
  keywordPatterns << "\\balgorithm\\b"
                  << "\\band\\b"
                  << "\\bannotation\\b"
                  << "\\bassert\\b"
                  << "\\bblock\\b"
                  << "\\bbreak\\b"
                  << "\\bBoolean\\b"
                  << "\\bclass\\b"
                  << "\\bconnect\\b"
                  << "\\bconnector\\b"
                  << "\\bconstant\\b"
                  << "\\bconstrainedby\\b"
                  << "\\bder\\b"
                  << "\\bdiscrete\\b"
                  << "\\beach\\b"
                  << "\\belse\\b"
                  << "\\belseif\\b"
                  << "\\belsewhen\\b"
                  << "\\bencapsulated\\b"
                  << "\\bend\\b"
                  << "\\benumeration\\b"
                  << "\\bequation\\b"
                  << "\\bexpandable\\b"
                  << "\\bextends\\b"
                  << "\\bexternal\\b"
                  << "\\bfalse\\b"
                  << "\\bfinal\\b"
                  << "\\bflow\\b"
                  << "\\bfor\\b"
                  << "\\bfunction\\b"
                  << "\\bif\\b"
                  << "\\bimport\\b"
                  << "\\bin\\b"
                  << "\\binitial\\b"
                  << "\\binner\\b"
                  << "\\binput\\b"
                  << "\\bloop\\b"
                  << "\\bmodel\\b"
                  << "\\bnot\\b"
                  << "\\boperator\\b"
                  << "\\bor\\b"
                  << "\\bouter\\b"
                  << "\\boutput\\b"
                  << "\\boptimization\\b"
                  << "\\bpackage\\b"
                  << "\\bparameter\\b"
                  << "\\bpartial\\b"
                  << "\\bprotected\\b"
                  << "\\bpublic\\b"
                  << "\\brecord\\b"
                  << "\\bredeclare\\b"
                  << "\\breplaceable\\b"
                  << "\\breturn\\b"
                  << "\\bstream\\b"
                  << "\\bthen\\b"
                  << "\\btrue\\b"
                  << "\\btype\\b"
                  << "\\bwhen\\b"
                  << "\\bwhile\\b"
                  << "\\bwithin\\b";
  foreach (const QString &pattern, keywordPatterns)
  {
    rule.mPattern = QRegExp(pattern);
    rule.mFormat = mKeywordFormat;
    mHighlightingRules.append(rule);
  }
  // Modelica types
  QStringList typePatterns;
  typePatterns << "\\bString\\b"
               << "\\bInteger\\b"
               << "\\bBoolean\\b"
               << "\\bReal\\b";
  foreach (const QString &pattern, typePatterns)
  {
    rule.mPattern = QRegExp(pattern);
    rule.mFormat = mTypeFormat;
    mHighlightingRules.append(rule);
  }

  rule.mPattern = QRegExp("\\b[A-Za-z0-9_]+(?=\\()");
  rule.mFormat = mFunctionFormat;
  mHighlightingRules.append(rule);

  rule.mPattern = QRegExp("//[^\n]*");
  rule.mFormat = mSingleLineCommentFormat;
  mHighlightingRules.append(rule);

  mCommentStartExpression = QRegExp("/\\*");
  mCommentEndExpression = QRegExp("\\*/");
}

//! Highlights the multilines text.
//! Quoted text or multiline comments.
void ModelicaTextHighlighter::highlightMultiLine(const QString &text)
{
  /* Hand-written recognizer beats the crap known as QRegEx ;) */
  int index = 0, startIndex = 0;
  int blockState = previousBlockState();
  // fprintf(stderr, "%s with blockState %d\n", text.toStdString().c_str(), blockState);

  while (index < text.length())
  {
    switch (blockState) {
      /* if the block already has single line comment then don't check for multi line comment and quotes. */
      case 1:
        if (text[index] == '/' && index+1<text.length() && text[index+1] == '/') {
          index++;
          setFormat(startIndex, index-startIndex+1, mSingleLineCommentFormat);
          blockState = 1; /* don't change the blockstate. */
        }
        break;
      case 2:
        if (text[index] == '*' && index+1<text.length() && text[index+1] == '/') {
          index++;
          setFormat(startIndex, index-startIndex+1, mMultiLineCommentFormat);
          blockState = 0;
        }
        break;
      case 3:
        if (text[index] == '\\') {
          index++;
        } else if (text[index] == '"') {
          setFormat(startIndex, index-startIndex+1, mQuotationFormat);
          blockState = 0;
        }
        break;
      default:
        /* check if single line comment then set the blockstate to 1. */
        if (text[index] == '/' && index+1<text.length() && text[index+1] == '/') {
          startIndex = index++;
          blockState = 1;
        } else if (text[index] == '/' && index+1<text.length() && text[index+1] == '*') {
          startIndex = index++;
          blockState = 2;
        } else if (text[index] == '"') {
          startIndex = index;
          blockState = 3;
        }
    }
    index++;
  }
  switch (blockState) {
    case 2:
      setFormat(startIndex, text.length()-startIndex, mMultiLineCommentFormat);
      setCurrentBlockState(2);
      break;
    case 3:
      setFormat(startIndex, text.length()-startIndex, mQuotationFormat);
      setCurrentBlockState(3);
      break;
  }
}

//! Reimplementation of QSyntaxHighlighter::highlightBlock
void ModelicaTextHighlighter::highlightBlock(const QString &text)
{
  /* Only highlight the text if user has enabled the syntax highlighting */
  if (mpMainWindow) /* mpMainWindow is 0 for the ModelicaTextHighlighter used by ModelicaTextEditorPage in OptionsDialog */
    if (!mpMainWindow->getOptionsDialog()->getModelicaTextEditorPage()->getSyntaxHighlightingCheckbox()->isChecked())
      return;
  setCurrentBlockState(0);
  setFormat(0, text.length(), mpModelicaTextSettings->getTextRuleColor());
  foreach (const HighlightingRule &rule, mHighlightingRules)
  {
    QRegExp expression(rule.mPattern);
    int index = expression.indexIn(text);
    while (index >= 0)
    {
      int length = expression.matchedLength();
      setFormat(index, length, rule.mFormat);
      index = expression.indexIn(text, index + length);
    }
  }
  highlightMultiLine(text);
}

//! Slot activated whenever ModelicaEditor text settings changes.
void ModelicaTextHighlighter::settingsChanged()
{
  initializeSettings();
  rehighlight();
}

//! @class GotoLineWidget
//! @brief An interface to goto a specific line in ModelicaEditor.

//! Constructor
GotoLineDialog::GotoLineDialog(ModelicaTextEdit *pModelicaEditor, MainWindow *pMainWindow)
  : QDialog(pMainWindow, Qt::WindowTitleHint)
{
  setWindowTitle(QString(Helper::applicationName).append(" - Go to Line"));
  setAttribute(Qt::WA_DeleteOnClose);
  setModal(true);
  mpModelicaEditor = pModelicaEditor;
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
  mpLineNumberLabel->setText(QString("Enter line number (1 to ").append(QString::number(mpModelicaEditor->blockCount())).append("):"));
  QIntValidator *intValidator = new QIntValidator(this);
  intValidator->setRange(1, mpModelicaEditor->blockCount());
  mpLineNumberTextBox->setValidator(intValidator);
  setVisible(true);
}

//! Slot activated when mpOkButton clicked signal raised.
void GotoLineDialog::goToLineNumber()
{
  const QTextBlock &block = mpModelicaEditor->document()->findBlockByNumber(mpLineNumberTextBox->text().toInt() - 1); // -1 since text index start from 0
  if (block.isValid())
  {
    QTextCursor cursor(block);
    cursor.movePosition(QTextCursor::Right, QTextCursor::MoveAnchor, 0);
    mpModelicaEditor->setTextCursor(cursor);
    mpModelicaEditor->centerCursor();
  }
  accept();
}

ModelicaTextWidget::ModelicaTextWidget(ModelWidget *pParent)
  : QWidget(pParent)
{
  mpModelWidget = pParent;
  // Create Modelica Text Editor
  mpModelicaTextEdit = new ModelicaTextEdit(this);
  // set layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpModelicaTextEdit, 0, 0);
  setLayout(pMainLayout);
}

ModelWidget* ModelicaTextWidget::getModelWidget()
{
  return mpModelWidget;
}

ModelicaTextEdit* ModelicaTextWidget::getModelicaTextEdit()
{
  return mpModelicaTextEdit;
}

FindReplaceDialog::FindReplaceDialog (QWidget *pParent)
  : QDialog(pParent, Qt::WindowTitleHint)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Find/Replace")));
  // Find Label and text box
  mpFindLabel = new Label(tr("Find:"));
  mpFindComboBox = new QComboBox;
  mpFindComboBox->setEditable(true);
  connect(mpFindComboBox, SIGNAL(editTextChanged(QString)), this, SLOT(textToFindChanged()));
  connect(mpFindComboBox, SIGNAL(editTextChanged(QString)), this, SLOT(validateRegularExpression(QString)));
  /* Since the default QCompleter for QComboBox is case insenstive. */
  QCompleter *pFindComboBoxCompleter = mpFindComboBox->completer();
  pFindComboBoxCompleter->setCaseSensitivity(Qt::CaseSensitive);
  mpFindComboBox->setCompleter(pFindComboBoxCompleter);
  // Find replace and text box
  mpReplaceWithLabel = new Label(tr("Replace With:"));
  mpReplaceWithTextBox = new QLineEdit;
  // Find Direction
  mpDirectionGroupBox = new QGroupBox(tr("Direction"));
  mpForwardRadioButton = new QRadioButton(tr("Forward"));
  mpForwardRadioButton->setChecked(true);
  mpBackwardRadioButton = new QRadioButton(tr("Backward"));
  // Find Options
  mpOptionsBox = new QGroupBox(tr("Options"));
  mpCaseSensitiveCheckBox = new QCheckBox(tr("Case Sensitive"));
  mpWholeWordCheckBox = new QCheckBox(tr("Whole Words"));
  mpRegularExpressionCheckBox = new QCheckBox(tr("Regular Expressions"));
  // Buttons
  mpFindButton = new QPushButton(tr("Find"));
  connect(mpFindButton, SIGNAL(clicked()), this, SLOT(find()));
  mpReplaceButton = new QPushButton(tr("Replace"));
  connect(mpReplaceButton, SIGNAL(clicked()), this, SLOT(replace()));
  mpReplaceAllButton = new QPushButton(tr("Replace All"));
  connect(mpReplaceAllButton, SIGNAL(clicked()), this, SLOT(replaceAll()));
  mpCloseButton = new QPushButton(Helper::close);
  connect(mpCloseButton, SIGNAL(clicked()), this, SLOT(close()));
  updateButtons();
  // set the layouts
  // set the directions layout
  QVBoxLayout *pDirectionVerticalLayout = new QVBoxLayout;
  pDirectionVerticalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pDirectionVerticalLayout->addWidget(mpForwardRadioButton);
  pDirectionVerticalLayout->addWidget(mpBackwardRadioButton);
  mpDirectionGroupBox->setLayout(pDirectionVerticalLayout);
  // set the options layput
  QVBoxLayout *pOptionsVerticalLayout = new QVBoxLayout;
  pOptionsVerticalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pOptionsVerticalLayout->addWidget(mpCaseSensitiveCheckBox);
  pOptionsVerticalLayout->addWidget(mpWholeWordCheckBox);
  pOptionsVerticalLayout->addWidget(mpRegularExpressionCheckBox);
  mpOptionsBox->setLayout(pOptionsVerticalLayout);
  // set horizontal layout for directions and options
  QHBoxLayout *pDirectionsOptionsHorizontalLayout = new QHBoxLayout;
  pDirectionsOptionsHorizontalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pDirectionsOptionsHorizontalLayout->addWidget(mpDirectionGroupBox);
  pDirectionsOptionsHorizontalLayout->addWidget(mpOptionsBox);
  // set buttons layout
  QGridLayout *pButtonsGridLayout = new QGridLayout;
  pButtonsGridLayout->addWidget(mpFindButton);
  pButtonsGridLayout->addWidget(mpReplaceButton);
  pButtonsGridLayout->addWidget(mpReplaceAllButton);
  pButtonsGridLayout->addWidget(mpCloseButton);
  // set main layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainGridLayout->addWidget(mpFindLabel, 0, 0);
  pMainGridLayout->addWidget(mpFindComboBox, 0, 1);
  pMainGridLayout->addWidget(mpReplaceWithLabel, 1, 0);
  pMainGridLayout->addWidget(mpReplaceWithTextBox, 1, 1);
  pMainGridLayout->addLayout(pDirectionsOptionsHorizontalLayout, 2, 0, 3, 2);
  pMainGridLayout->addLayout(pButtonsGridLayout, 0, 2, 4, 2, Qt::AlignRight);
  setLayout(pMainGridLayout);
}

void FindReplaceDialog::show()
{
  QTextCursor currentTextCursor = mpModelicaTextEdit->textCursor();
  if (currentTextCursor.hasSelection())
  {
    QString selectedText = currentTextCursor.selectedText();
    saveFindTextToSettings(selectedText);
    readFindTextFromSettings();
  }
  else
  {
    readFindTextFromSettings();
  }
  mpFindComboBox->lineEdit()->selectAll();
  setVisible(true);
}

/*!
  Associates the text editor where to perform the search
  \param ModelicaTextEdit - pointer to ModelicaTextEdit
  */
void FindReplaceDialog::setTextEdit(ModelicaTextEdit *pModelicaTextEdit)
{
  mpModelicaTextEdit = pModelicaTextEdit;
}

/*!
  Reads the list of find texts from the settings file.
  */
void FindReplaceDialog::readFindTextFromSettings()
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  mpFindComboBox->clear();
  QList<QVariant> findTexts = settings.value("findReplaceDialog/textsToFind").toList();
  int numFindTexts = qMin(findTexts.size(), (int)MaxFindTexts);
  for (int i = 0; i < numFindTexts; ++i)
  {
    FindText findText = qvariant_cast<FindText>(findTexts[i]);
    mpFindComboBox->addItem(findText.text);
  }
}

/*!
  Saves the find text to the settings file.
  \param textToFind - the text to find
  */
void FindReplaceDialog::saveFindTextToSettings(QString textToFind)
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  QList<QVariant> texts = settings.value("findReplaceDialog/textsToFind").toList();
  // remove the already present text from the list.
  foreach (QVariant text, texts)
  {
    FindText findText = qvariant_cast<FindText>(text);
    if (findText.text.compare(textToFind) == 0)
       texts.removeOne(text);
  }
  FindText findText;
  findText.text = textToFind;
  texts.prepend(QVariant::fromValue(findText));
  while (texts.size() > MaxFindTexts)
     texts.removeLast();

  settings.setValue("findReplaceDialog/textsToFind", texts);
}

/*!
  Performs the find task
  */
void FindReplaceDialog::find()
{
  findText(mpForwardRadioButton->isChecked());
}

void FindReplaceDialog::findText(bool forward)
{
  QTextCursor currentTextCursor = mpModelicaTextEdit->textCursor();
  bool backward = !forward;

  if (currentTextCursor.hasSelection())
  {
    currentTextCursor.setPosition(forward ? currentTextCursor.position() : currentTextCursor.anchor(), QTextCursor::MoveAnchor);
  }
  const QString &textToFind = mpFindComboBox->currentText();
  // save the find text in settings
  saveFindTextToSettings(textToFind);
  bool result = true;
  QTextDocument::FindFlags flags;
  if (backward)
    flags |= QTextDocument::FindBackward;
  if (mpCaseSensitiveCheckBox->isChecked())
    flags |= QTextDocument::FindCaseSensitively;
  if (mpWholeWordCheckBox->isChecked())
    flags |= QTextDocument::FindWholeWords;

  if (mpRegularExpressionCheckBox->isChecked())
  {
    QRegExp reg(textToFind, (mpCaseSensitiveCheckBox->isChecked() ? Qt::CaseSensitive : Qt::CaseInsensitive));
    currentTextCursor = mpModelicaTextEdit->document()->find(reg, currentTextCursor, flags);
    mpModelicaTextEdit->setTextCursor(currentTextCursor);
    result = (!currentTextCursor.isNull());
  }

  QTextCursor newTextCursor = mpModelicaTextEdit->document()->find(textToFind, currentTextCursor, flags);
  if (newTextCursor.isNull())
  {
    QTextCursor ac(mpModelicaTextEdit->document());
    ac.movePosition(flags & QTextDocument::FindBackward ? QTextCursor::End : QTextCursor::Start);
    newTextCursor = mpModelicaTextEdit->document()->find(textToFind, ac, flags);
    if (newTextCursor.isNull())
    {
      result = false;
      newTextCursor = currentTextCursor;
    }
  }
  mpModelicaTextEdit->setTextCursor(newTextCursor);

  if(!result)
  {
    QString message = QString( "Can't find the text '" ) + textToFind + QString( " '." );
    QMessageBox::information( this, "Find", message );
  }
}

/*!
  Replaces the found occurrences and goes to the next occurrence
  */
void FindReplaceDialog::replace()
{
  int compareString(0);
  if(mpCaseSensitiveCheckBox->isChecked())
    compareString = Qt::CaseSensitive;
  else
    compareString = Qt::CaseInsensitive;
  int same = mpModelicaTextEdit->textCursor().selectedText().compare(mpFindComboBox->currentText(),( Qt::CaseSensitivity)compareString );
  if (mpModelicaTextEdit->textCursor().hasSelection()&& same == 0  )
  {
    mpModelicaTextEdit->textCursor().insertText(mpReplaceWithTextBox->text());
    find();
  }
  else
    find();
}

/*!
  Replaces all the found occurrences
  */
void FindReplaceDialog::replaceAll()
{
  // move cursor to start of text
  QTextCursor cursor = mpModelicaTextEdit->textCursor();
  cursor.movePosition(QTextCursor::Start);
  mpModelicaTextEdit->setTextCursor(cursor);

  QTextDocument::FindFlags flags;
  if (mpCaseSensitiveCheckBox->isChecked())
    flags |= QTextDocument::FindCaseSensitively;
  if (mpWholeWordCheckBox->isChecked())
    flags |= QTextDocument::FindWholeWords;

  // save the find text in settings
  saveFindTextToSettings(mpFindComboBox->currentText());
  // replace all
  int i=0;
  mpModelicaTextEdit->textCursor().beginEditBlock();
  while(mpModelicaTextEdit->find(mpFindComboBox->currentText(), flags ))
  {
    mpModelicaTextEdit->textCursor().insertText(mpReplaceWithTextBox->text());
    i++;
  }
  mpModelicaTextEdit->textCursor().endEditBlock();

  // show message box with status information
  QString message;
  message.setNum(i);
  message += QString( " occurence(s) of the text '" ) + mpFindComboBox->currentText() +
    QString( "' was replaced with the text '" ) + mpReplaceWithTextBox->text() + QString( "'." );
    QMessageBox::information( this, "Replace All", message );
}

void FindReplaceDialog::updateButtons()
{
  const bool enable = !mpFindComboBox->currentText().isEmpty();
  mpFindButton->setEnabled(enable);
}

/*!
  Checks whether the passed text is a valid regular expression
  */
void FindReplaceDialog::validateRegularExpression(const QString &text)
{
  if (!mpRegularExpressionCheckBox->isChecked() || text.size() == 0)
  {
    return; // nothing to validate
  }
  QRegExp reg(text, (mpCaseSensitiveCheckBox->isChecked() ? Qt::CaseSensitive : Qt::CaseInsensitive));
  if (!reg.isValid())
  {
    QMessageBox::critical( this, "Find", reg.errorString());
  }
}

/*!
  The regular expression checkbox was selected
  */
void FindReplaceDialog::regularExpressionSelected(bool selected)
{
  if (selected)
    validateRegularExpression(mpFindComboBox->currentText());
  else
    validateRegularExpression("");
}

/*!
  When the text edit contents changed
  */
void FindReplaceDialog::textToFindChanged()
{
  mpFindButton->setEnabled(mpFindComboBox->currentText().size() > 0);
}

