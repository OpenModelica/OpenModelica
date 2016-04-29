/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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
#include "BreakpointMarker.h"
#include "ModelicaEditor.h"
#include "Helper.h"

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
ModelicaEditor::ModelicaEditor(ModelWidget *pParent)
  : BaseEditor(pParent), mLastValidText(""), mTextChanged(false), mForceSetPlainText(false)
{
  setCanHaveBreakpoints(true);
  setCanHaveFoldings(true);
  /* set the document marker */
  mpDocumentMarker = new DocumentMarker(mpPlainTextEdit->document());
}

/*!
 * \brief ModelicaEditor::getClassNames
 * Uses the OMC parseString API to check the class names inside the Modelica Text
 * \param errorString
 * \return QStringList a list of class names
 * \sa ModelWidget::modelicaEditorTextChanged()
 */
QStringList ModelicaEditor::getClassNames(QString *errorString)
{
  OMCProxy *pOMCProxy = mpMainWindow->getOMCProxy();
  QStringList classNames;
  LibraryTreeItem *pLibraryTreeItem = mpModelWidget->getLibraryTreeItem();
  if (mpPlainTextEdit->toPlainText().isEmpty()) {
    *errorString = tr("Start and End modifiers are different");
    return QStringList();
  } else {
    QString modelicaText = mpPlainTextEdit->toPlainText();
    QString stringToParse = modelicaText;
    if (!modelicaText.startsWith("within")) {
      stringToParse = QString("within %1;%2").arg(pLibraryTreeItem->parent()->getNameStructure()).arg(modelicaText);
    }
    classNames = pOMCProxy->parseString(stringToParse, pLibraryTreeItem->getFileName());
  }
  // if user is defining multiple top level classes.
  if (classNames.size() > 1) {
    *errorString = QString(GUIMessages::getMessage(GUIMessages::MULTIPLE_TOP_LEVEL_CLASSES)).arg(pLibraryTreeItem->getNameStructure())
        .arg(classNames.join(","));
    return QStringList();
  }
  bool existModel = false;
  QStringList existingmodelsList;
  // check if the class already exists
  foreach(QString className, classNames) {
    if (pLibraryTreeItem->getNameStructure().compare(className) != 0) {
      if (mpMainWindow->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className)) {
        existingmodelsList.append(className);
        existModel = true;
      }
    }
  }
  // check if existModel is true
  if (existModel) {
    *errorString = QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES)).arg(existingmodelsList.join(",")).append("\n")
        .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(""));
    return QStringList();
  }
  return classNames;
}

/*!
 * \brief ModelicaEditor::validateText
 * When user make some changes in the ModelicaEditor text then this method validates the text and show text correct options.
 * \param pLibraryTreeItem
 * \return
 */
bool ModelicaEditor::validateText(LibraryTreeItem **pLibraryTreeItem)
{
  if (mTextChanged) {
    // if the user makes few mistakes in the text then dont let him change the perspective
    if (!mpModelWidget->modelicaEditorTextChanged(pLibraryTreeItem)) {
      QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(GUIMessages::getMessage(GUIMessages::ERROR_IN_TEXT).arg("Modelica")
                           .append(GUIMessages::getMessage(GUIMessages::CHECK_MESSAGES_BROWSER))
                           .append(GUIMessages::getMessage(GUIMessages::REVERT_PREVIOUS_OR_FIX_ERRORS_MANUALLY)));
      pMessageBox->addButton(Helper::fixErrorsManually, QMessageBox::AcceptRole);
      pMessageBox->addButton(Helper::revertToLastCorrectVersion, QMessageBox::RejectRole);
      // we set focus to this widget here so when the error dialog is closed Qt gives back the focus to this widget.
      mpPlainTextEdit->setFocus(Qt::ActiveWindowFocusReason);
      int answer = pMessageBox->exec();
      switch (answer) {
        case QMessageBox::RejectRole:
          mTextChanged = false;
          // revert back to last correct version
          setPlainText(mLastValidText);
          return true;
        case QMessageBox::AcceptRole:
        default:
          mTextChanged = true;
          return false;
      }
    } else {
      mTextChanged = false;
      mLastValidText = mpPlainTextEdit->toPlainText();
    }
  }
  return true;
}

/*!
 * \brief ModelicaEditor::removeLeadingSpaces
 * Removes the leading spaces from a nested class text to make it more readable.
 * \param contents
 * \return
 */
QString ModelicaEditor::removeLeadingSpaces(QString contents)
{
  QString text;
  int startLeadingSpaces = 0;
  int leadingSpaces = 0;
  QTextStream textStream(&contents);
  int lineNumber = 1;
  while (!textStream.atEnd()) {
    QString currentLine = textStream.readLine();
    if (lineNumber == 1) {  // the first line
      startLeadingSpaces = StringHandler::getLeadingSpacesSize(currentLine);
      leadingSpaces = startLeadingSpaces;
    } else {
      leadingSpaces = qMin(startLeadingSpaces, StringHandler::getLeadingSpacesSize(currentLine));
    }
    text += currentLine.mid(leadingSpaces) + "\n";
    lineNumber++;
  }
  return text;
}

/*!
 * \brief ModelicaEditor::storeLeadingSpaces
 * Stores the leading spaces information in the text block user data.
 * \param leadingSpacesMap
 */
void ModelicaEditor::storeLeadingSpaces(QMap<int, int> leadingSpacesMap)
{
  QTextBlock block = mpPlainTextEdit->document()->firstBlock();
  while (block.isValid()) {
    TextBlockUserData *pTextBlockUserData = BaseEditorDocumentLayout::userData(block);
    if (pTextBlockUserData) {
      pTextBlockUserData->setLeadingSpaces(leadingSpacesMap.value(block.blockNumber() + 1, 0));
    }
    block = block.next();
  }
}

/*!
 * \brief ModelicaEditor::getPlainText
 * Reads the leading spaces information from the text block user data and inserts them to the actual string.
 * \return
 */
QString ModelicaEditor::getPlainText()
{
  if (mpModelWidget->getLibraryTreeItem()->isInPackageOneFile()) {
    QString text;
    QTextBlock block = mpPlainTextEdit->document()->firstBlock();
    while (block.isValid()) {
      TextBlockUserData *pTextBlockUserData = BaseEditorDocumentLayout::userData(block);
      if (pTextBlockUserData) {
        if (pTextBlockUserData->getLeadingSpaces() == -1) {
          TextBlockUserData *pFirstBlockUserData = BaseEditorDocumentLayout::userData(mpPlainTextEdit->document()->firstBlock());
          if (pFirstBlockUserData) {
            pTextBlockUserData->setLeadingSpaces(pFirstBlockUserData->getLeadingSpaces());
          } else {
            pTextBlockUserData->setLeadingSpaces(0);
          }
        }
        text += QString(pTextBlockUserData->getLeadingSpaces(), ' ');
      }
      text += block.text();
      block = block.next();
      if (block.isValid()) { // not last block
        text += "\n";
      }
    }
    return text;
  } else {
    return mpPlainTextEdit->toPlainText();
  }
}

/*!
 * \brief ModelicaEditor::showContextMenu
 * Create a context menu.
 * \param point
 */
void ModelicaEditor::showContextMenu(QPoint point)
{
  QMenu *pMenu = BaseEditor::createStandardContextMenu();
  pMenu->addSeparator();
  pMenu->addAction(mpToggleCommentSelectionAction);
  pMenu->exec(mapToGlobal(point));
  delete pMenu;
}

/*!
 * \brief ModelicaEditor::setPlainText
 * Reimplementation of QPlainTextEdit::setPlainText method.
 * Makes sure we dont update if the passed text is same.
 * \param text the string to set.
 */
void ModelicaEditor::setPlainText(const QString &text)
{
  QMap<int, int> leadingSpacesMap;
  QString contents = text;
  // store and remove leading spaces
  if (mpModelWidget->getLibraryTreeItem()->isInPackageOneFile()) {
    leadingSpacesMap = StringHandler::getLeadingSpaces(contents);
    contents = removeLeadingSpaces(contents);
  }
  // Only set the text when it is really new
  if (contents != mpPlainTextEdit->toPlainText()) {
    mForceSetPlainText = true;
    if (mpModelWidget->getLibraryTreeItem()->isInPackageOneFile()) {
      mpPlainTextEdit->setPlainText(contents);
      storeLeadingSpaces(leadingSpacesMap);
    } else {
      mpPlainTextEdit->setPlainText(contents);
    }
    mForceSetPlainText = false;
    mLastValidText = contents;
  }
}

//! Slot activated when ModelicaTextEdit's QTextDocument contentsChanged SIGNAL is raised.
//! Sets the model as modified so that user knows that his current model is not saved.
void ModelicaEditor::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  if (mpModelWidget->isVisible()) {
    if (charsRemoved == 0 && charsAdded == 0) {
      return;
    }
    /* if user is changing the system library class. */
    if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() && !mForceSetPlainText) {
      mpMainWindow->getInfoBar()->showMessage(tr("<b>Warning: </b>You are changing a system library class. System libraries are always read-only. Your changes will not be saved."));
    } else if (mpModelWidget->getLibraryTreeItem()->isReadOnly() && !mForceSetPlainText) {
      /* if user is changing the read-only class. */
      mpMainWindow->getInfoBar()->showMessage(tr("<b>Warning: </b>You are changing a read-only class."));
    } else {
      /* if user is changing, the normal class. */
      if (!mForceSetPlainText) {
        mpModelWidget->setWindowTitle(QString(mpModelWidget->getLibraryTreeItem()->getName()).append("*"));
        mpModelWidget->getLibraryTreeItem()->setIsSaved(false);
        mpMainWindow->getLibraryWidget()->getLibraryTreeModel()->updateLibraryTreeItem(mpModelWidget->getLibraryTreeItem());
        mTextChanged = true;
      }
      /* Keep the line numbers and the block information for the line breakpoints updated */
      if (charsRemoved != 0) {
        mpDocumentMarker->updateBreakpointsLineNumber();
        mpDocumentMarker->updateBreakpointsBlock(mpPlainTextEdit->document()->findBlock(position));
      } else {
        const QTextBlock posBlock = mpPlainTextEdit->document()->findBlock(position);
        const QTextBlock nextBlock = mpPlainTextEdit->document()->findBlock(position + charsAdded);
        if (posBlock != nextBlock) {
          mpDocumentMarker->updateBreakpointsLineNumber();
          mpDocumentMarker->updateBreakpointsBlock(posBlock);
          mpDocumentMarker->updateBreakpointsBlock(nextBlock);
        } else {
          mpDocumentMarker->updateBreakpointsBlock(posBlock);
        }
      }
    }
  }
}

/*!
  Slot activated when toggle comment selection is seleteted from context menu or ctrl+k is pressed.
  The implementation and logic is inspired from Qt Creator sources.
  */
void ModelicaEditor::toggleCommentSelection()
{
  CommentDefinition definition;
  if (!definition.hasSingleLineStyle() && !definition.hasMultiLineStyle()) {
    return;
  }

  QTextCursor cursor = mpPlainTextEdit->textCursor();
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
    cursor = mpPlainTextEdit->textCursor();
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
    mpPlainTextEdit->setTextCursor(cursor);
  }
  cursor.endEditBlock();
}

//! @class ModelicaTextHighlighter
//! @brief A syntax highlighter for ModelicaEditor.

//! Constructor
ModelicaTextHighlighter::ModelicaTextHighlighter(ModelicaEditorPage *pModelicaEditorPage, QPlainTextEdit *pPlainTextEdit)
  : QSyntaxHighlighter(pPlainTextEdit->document())
{
  mpModelicaEditorPage = pModelicaEditorPage;
  mpPlainTextEdit = pPlainTextEdit;
  initializeSettings();
}

//! Initialized the syntax highlighter with default values.
void ModelicaTextHighlighter::initializeSettings()
{
  QFont font;
  font.setFamily(mpModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getFontFamilyComboBox()->currentFont().family());
  font.setPointSizeF(mpModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getFontSizeSpinBox()->value());
  mpPlainTextEdit->document()->setDefaultFont(font);
  mpPlainTextEdit->setTabStopWidth(mpModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getTabSizeSpinBox()->value() * QFontMetrics(font).width(QLatin1Char(' ')));
  // set color highlighting
  mHighlightingRules.clear();
  HighlightingRule rule;
  mTextFormat.setForeground(mpModelicaEditorPage->getTextRuleColor());
  mKeywordFormat.setForeground(mpModelicaEditorPage->getKeywordRuleColor());
  mTypeFormat.setForeground(mpModelicaEditorPage->getTypeRuleColor());
  mSingleLineCommentFormat.setForeground(mpModelicaEditorPage->getCommentRuleColor());
  mMultiLineCommentFormat.setForeground(mpModelicaEditorPage->getCommentRuleColor());
  mFunctionFormat.setForeground(mpModelicaEditorPage->getFunctionRuleColor());
  mQuotationFormat.setForeground(QColor(mpModelicaEditorPage->getQuotesRuleColor()));
  // Priority: keyword > func() > ident > number. Yes, the order matters :)
  mNumberFormat.setForeground(mpModelicaEditorPage->getNumberRuleColor());
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
                  << "\\bimpure\\b"
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
                  << "\\bpure\\b"
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
}

/*!
 * \brief ModelicaTextHighlighter::highlightMultiLine
 * Highlights the multilines text.
 * Quoted text or multiline comments.
 * \param text
 * \param text
 */
void ModelicaTextHighlighter::highlightMultiLine(const QString &text)
{
  /* Hand-written recognizer beats the crap known as QRegEx ;) */
  int index = 0, startIndex = 0;
  int blockState = previousBlockState();
  // store parentheses info
  Parentheses parentheses;
  TextBlockUserData *pTextBlockUserData = BaseEditorDocumentLayout::userData(currentBlock());
  if (pTextBlockUserData) {
    pTextBlockUserData->clearParentheses();
  }
  while (index < text.length()) {
    switch (blockState) {
      /* if the block already has single line comment then don't check for multi line comment and quotes. */
      case 1:
        if (text[index] == '/' && index+1<text.length() && text[index+1] == '/') {
          index++;
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
          setFormat(startIndex, text.length(), mSingleLineCommentFormat);
          blockState = 1;
        } else if (text[index] == '/' && index+1<text.length() && text[index+1] == '*') {
          startIndex = index++;
          blockState = 2;
        } else if (text[index] == '"') {
          startIndex = index;
          blockState = 3;
        }
    }
    // if no single line comment, no multi line comment and no quotes then store the parentheses
    if (pTextBlockUserData && (blockState < 1 || blockState > 3 || mpModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox()->isChecked())) {
      if (text[index] == '(' || text[index] == '{' || text[index] == '[') {
        parentheses.append(Parenthesis(Parenthesis::Opened, text[index], index));
      } else if (text[index] == ')' || text[index] == '}' || text[index] == ']') {
        parentheses.append(Parenthesis(Parenthesis::Closed, text[index], index));
      }
    }
    index++;
  }
  if (pTextBlockUserData) {
    pTextBlockUserData->setParentheses(parentheses);
    // set text block user data
    setCurrentBlockUserData(pTextBlockUserData);
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
  if (!mpModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getSyntaxHighlightingCheckbox()->isChecked()) {
    return;
  }
  // set text block state
  setCurrentBlockState(0);
  setFormat(0, text.length(), mpModelicaEditorPage->getTextRuleColor());
  foreach (const HighlightingRule &rule, mHighlightingRules) {
    QRegExp expression(rule.mPattern);
    int index = expression.indexIn(text);
    while (index >= 0) {
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
