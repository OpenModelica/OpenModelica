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
 * RCS: $Id$
 *
 */
#include "BreakpointMarker.h"
#include "ModelicaTextEditor.h"
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
ModelicaTextEditor::ModelicaTextEditor(ModelWidget *pParent)
  : BaseEditor(pParent), mLastValidText(""), mTextChanged(false), mForceSetPlainText(false)
{
  setContextMenuPolicy(Qt::CustomContextMenu);
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  setCanHaveBreakpoints(true);
  createActions();
  setLineWrapping();
  /* set the document marker */
  mpDocumentMarker = new DocumentMarker(document());
  setModelicaTextDocument(document());
  /* set the options for the editor */
  OptionsDialog *pOptionsDialog = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getOptionsDialog();
  connect(pOptionsDialog, SIGNAL(updateLineWrapping()), SLOT(setLineWrapping()));
  connect(this, SIGNAL(focusOut()), mpModelWidget, SLOT(modelicaEditorTextChanged()));
  connect(this->document(), SIGNAL(contentsChange(int,int,int)), SLOT(contentsHasChanged(int,int,int)));
  connect(this, SIGNAL(cursorPositionChanged()), this, SLOT(updateCursorPosition()));
  updateCursorPosition();
}

void ModelicaTextEditor::createActions()
{
  mpToggleCommentSelectionAction = new QAction(tr("Toggle Comment Selection"), this);
  mpToggleCommentSelectionAction->setShortcut(QKeySequence("Ctrl+k"));
  connect(mpToggleCommentSelectionAction, SIGNAL(triggered()), SLOT(toggleCommentSelection()));
}

void ModelicaTextEditor::setLastValidText(QString validText)
{
  mLastValidText = validText;
}

//! Uses the OMC parseString API to check the class names inside the Modelica Text
//! @return QStringList a list of class names
QStringList ModelicaTextEditor::getClassNames(QString *errorString)
{
  OMCProxy *pOMCProxy = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
  QStringList classNames;
  LibraryTreeNode *pLibraryTreeNode = mpModelWidget->getLibraryTreeNode();
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
bool ModelicaTextEditor::validateModelicaText()
{
  if (mTextChanged)
  {
    // if the user makes few mistakes in the text then dont let him change the perspective
    if (!emit focusOut())
    {
      MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
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

void ModelicaTextEditor::keyPressEvent(QKeyEvent *pEvent)
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
  BaseEditor::keyPressEvent(pEvent);
}

void ModelicaTextEditor::showContextMenu(QPoint point)
{
  MainWindow *pMainWindow = mpModelWidget->getModelWidgetContainer()->getMainWindow();
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

void ModelicaTextEditor::setModelicaTextDocument(QTextDocument *doc)
{
  ModelicaTextDocumentLayout *docLayout = qobject_cast<ModelicaTextDocumentLayout*>(doc->documentLayout());
  if (!docLayout)
  {
    QTextOption opt = doc->defaultTextOption();
    opt.setTextDirection(Qt::LeftToRight);
    opt.setFlags(opt.flags() | QTextOption::IncludeTrailingSpaces | QTextOption::AddSpaceForLineAndParagraphSeparators);
    doc->setDefaultTextOption(opt);
    docLayout = new ModelicaTextDocumentLayout(doc);
    doc->setDocumentLayout(docLayout);
  }
  setDocument(doc);
}

/*!
  Slot activated when toggle comment selection is seleteted from context menu or ctrl+k is pressed.
  The implementation and logic is inspired from Qt Creator sources.
  */
void ModelicaTextEditor::toggleCommentSelection()
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

//! Reimplementation of QPlainTextEdit::setPlainText method.
//! Makes sure we dont update if the passed text is same.
//! @param text the string to set.
void ModelicaTextEditor::setPlainText(const QString &text)
{
  if (text != toPlainText())
  {
    mForceSetPlainText = true;
    QPlainTextEdit::setPlainText(text);
    mForceSetPlainText = false;
    updateLineNumberAreaWidth(0);
  }
}

//! Slot activated when ModelicaTextEdit's QTextDocument contentsChanged SIGNAL is raised.
//! Sets the model as modified so that user knows that his current model is not saved.
void ModelicaTextEditor::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  if (mpModelWidget->isVisible())
  {
    if (charsRemoved == 0 && charsAdded == 0)
      return;
    /* if user is changing the system library class. */
    if (mpModelWidget->getLibraryTreeNode()->isSystemLibrary() && !mForceSetPlainText)
    {
      InfoBar *pInfoBar = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getInfoBar();
      pInfoBar->showMessage(tr("<b>Warning: </b>You are changing a system library class. System libraries are always read-only. Your changes will not be saved."));
    }
    /* if user is changing the read-only class. */
    else if (mpModelWidget->getLibraryTreeNode()->isReadOnly() && !mForceSetPlainText)
    {
      InfoBar *pInfoBar = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getInfoBar();
      pInfoBar->showMessage(tr("<b>Warning: </b>You are changing a read-only class."));
    }
    /* if user is changing the normal class. */
    else
    {
      if (!mForceSetPlainText) {
        mpModelWidget->setModelModified();
        mTextChanged = true;
      }
      /* Keep the line numbers and the block information for the line breakpoints updated */
      if (charsRemoved != 0)
      {
        mpDocumentMarker->updateBreakpointsLineNumber();
        mpDocumentMarker->updateBreakpointsBlock(document()->findBlock(position));
      }
      else
      {
        const QTextBlock posBlock = document()->findBlock(position);
        const QTextBlock nextBlock = document()->findBlock(position + charsAdded);
        if (posBlock != nextBlock)
        {
          mpDocumentMarker->updateBreakpointsLineNumber();
          mpDocumentMarker->updateBreakpointsBlock(posBlock);
          mpDocumentMarker->updateBreakpointsBlock(nextBlock);
        }
        else
          mpDocumentMarker->updateBreakpointsBlock(posBlock);
      }
    }
  }
}

void ModelicaTextEditor::setLineWrapping()
{
  OptionsDialog *pOptionsDialog = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getOptionsDialog();
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
