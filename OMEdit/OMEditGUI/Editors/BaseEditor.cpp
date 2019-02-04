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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "MainWindow.h"
#include "Editors/BaseEditor.h"
#include "Options/OptionsDialog.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Util/Helper.h"
#include "Debugger/Breakpoints/BreakpointsWidget.h"

#include <QMenu>
#include <QCompleter>
#include <QMessageBox>
#include <QTextDocumentFragment>

#if (QT_VERSION < QT_VERSION_CHECK(5, 0, 0))
#define QStringLiteral QString::fromUtf8
#endif
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
 * Returns the index where first non space character is found.
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

/*!
 * \class BaseEditorDocumentLayout
 * Implements a custom text layout for BaseEditor to be able to work with QTextDocument::setDocumentLayout().
 */
BaseEditorDocumentLayout::BaseEditorDocumentLayout(QTextDocument *document)
  : QPlainTextDocumentLayout(document), mHasBreakpoint(false)
{

}

/*!
 * \brief BaseEditorDocumentLayout::parentheses
 * Sets the Parentheses for the block.
 * \param block
 * \return
 */
Parentheses BaseEditorDocumentLayout::parentheses(const QTextBlock &block)
{
  if (TextBlockUserData *userData = testUserData(block)) {
    return userData->parentheses();
  }
  return Parentheses();
}

/*!
 * \brief BaseEditorDocumentLayout::hasParentheses
 * Checks if the block has Parentheses.
 * \param block
 * \return
 */
bool BaseEditorDocumentLayout::hasParentheses(const QTextBlock &block)
{
  if (TextBlockUserData *userData = testUserData(block)) {
    return userData->hasParentheses();
  }
  return false;
}

/*!
 * \brief BaseEditorDocumentLayout::setFoldingIndent
 * Sets the folding indent for the block.
 * \param block
 * \param indent
 */
void BaseEditorDocumentLayout::setFoldingIndent(const QTextBlock &block, int indent)
{
  if (indent == 0) {
    if (TextBlockUserData *userData = testUserData(block)) {
      userData->setFoldingIndent(0);
    }
  } else {
    userData(block)->setFoldingIndent(indent);
  }
}

/*!
 * \brief BaseEditorDocumentLayout::foldingIndent
 * Returns the folding indent of the block.
 * \param block
 * \return
 */
int BaseEditorDocumentLayout::foldingIndent(const QTextBlock &block)
{
  if (TextBlockUserData *userData = testUserData(block)) {
    return userData->foldingIndent();
  }
  return 0;
}

/*!
 * \brief BaseEditorDocumentLayout::canFold
 * Checks if block is foldable.
 * \param block
 * \return
 */
bool BaseEditorDocumentLayout::canFold(const QTextBlock &block)
{
  return (block.next().isValid() && foldingIndent(block.next()) > foldingIndent(block));
}

/*!
 * \brief BaseEditorDocumentLayout::foldOrUnfold
 * Folds/unfolds the block.
 * \param block
 * \param unfold
 */
void BaseEditorDocumentLayout::foldOrUnfold(const QTextBlock& block, bool unfold)
{
  if (!canFold(block)) {
    return;
  }
  QTextBlock b = block.next();
  int indent = foldingIndent(block);
  while (b.isValid() && foldingIndent(b) > indent && (unfold || b.next().isValid())) {
    b.setVisible(unfold);
    b.setLineCount(unfold? qMax(1, b.layout()->lineCount()) : 0);
    if (unfold) { // do not unfold folded sub-blocks
      if (isFolded(b) && b.next().isValid()) {
        int jndent = foldingIndent(b);
        b = b.next();
        while (b.isValid() && foldingIndent(b) > jndent) {
          b = b.next();
        }
        continue;
      }
    }
    b = b.next();
  }
  setFolded(block, !unfold);
}

/*!
 * \brief BaseEditorDocumentLayout::isFolded
 * Sets the block state to folded/unfolded.
 * \param block
 * \return
 */
bool BaseEditorDocumentLayout::isFolded(const QTextBlock &block)
{
  if (TextBlockUserData *userData = testUserData(block)) {
    return userData->folded();
  }
  return false;
}

/*!
 * \brief BaseEditorDocumentLayout::setFolded
 * \param block
 * \param folded
 */
void BaseEditorDocumentLayout::setFolded(const QTextBlock &block, bool folded)
{
  if (folded) {
    userData(block)->setFolded(true);
  } else if (TextBlockUserData *userData = testUserData(block)) {
    return userData->setFolded(false);
  }
}

/*!
 * \brief BaseEditorDocumentLayout::testUserData
 * \param block
 * \return
 */
TextBlockUserData* BaseEditorDocumentLayout::testUserData(const QTextBlock &block)
{
  return static_cast<TextBlockUserData*>(block.userData());
}

/*!
 * \brief BaseEditorDocumentLayout::userData
 * \param block
 * \return
 */
TextBlockUserData* BaseEditorDocumentLayout::userData(const QTextBlock &block)
{
  TextBlockUserData *data = static_cast<TextBlockUserData*>(block.userData());
  if (!data && block.isValid()) {
    const_cast<QTextBlock&>(block).setUserData((data = new TextBlockUserData));
  }
  return data;
}

/*!
 * \brief foldBoxWidth
 * Returns the width for folding control.
 * \param fm
 * \return
 */
static int foldBoxWidth(const QFontMetrics &fm)
{
  const int lineSpacing = fm.lineSpacing();
  return lineSpacing + lineSpacing % 2 + 1;
}

/*!
 * \class PlainTextEdit
 * Internal QPlainTextEdit for Editor.
 */
PlainTextEdit::PlainTextEdit(BaseEditor *pBaseEditor)
  : QPlainTextEdit(pBaseEditor), mpBaseEditor(pBaseEditor)
{
  setObjectName("BaseEditor");
  QTextDocument *pTextDocument = document();
  pTextDocument->setDocumentMargin(2);
  BaseEditorDocumentLayout *pModelicaTextDocumentLayout = new BaseEditorDocumentLayout(pTextDocument);
  pTextDocument->setDocumentLayout(pModelicaTextDocumentLayout);
  setDocument(pTextDocument);
  // line numbers widget
  mpLineNumberArea = new LineNumberArea(mpBaseEditor, this);
  mCanHaveBreakpoints = false;
  // parentheses matcher
  mParenthesesMatchFormat = Utilities::getParenthesesMatchFormat();
  mParenthesesMisMatchFormat = Utilities::getParenthesesMisMatchFormat();
  // Completer Tooltip widget
  mpCompleterToolTipWidget = new QWidget(this, Qt::ToolTip);
  mpCompleterToolTipWidget->installEventFilter(this);
  mpCompleterToolTipLabel = new Label;
  QHBoxLayout *pCompleterToolTipLayout = new QHBoxLayout;
  pCompleterToolTipLayout->setSpacing(0);
  pCompleterToolTipLayout->setContentsMargins(5, 5, 5, 5);
  pCompleterToolTipLayout->addWidget(mpCompleterToolTipLabel);
  mpCompleterToolTipWidget->setLayout(pCompleterToolTipLayout);
  // intialize the completer with QStandardItemModel
  mpStandardItemModel = new QStandardItemModel();
  // sort the StandardItemModel using QSortFilterProxy
  QSortFilterProxyModel *pSortFilterProxyModel = new QSortFilterProxyModel(this);
  pSortFilterProxyModel->setSourceModel(mpStandardItemModel);
  pSortFilterProxyModel->setSortCaseSensitivity(Qt::CaseInsensitive);
  pSortFilterProxyModel->sort(0,Qt::AscendingOrder);
  mpCompleter = new QCompleter(this);
  mpCompleter->setModel(pSortFilterProxyModel);
  mpCompleter->setCaseSensitivity(Qt::CaseSensitive);
  mpCompleter->setWrapAround(false);
  mpCompleter->setWidget(this);
  mpCompleter->setCompletionMode(QCompleter::PopupCompletion);
  connect(mpCompleter, SIGNAL(highlighted(QModelIndex)), this, SLOT(showCompletionItemToolTip(QModelIndex)));
  connect(mpCompleter, SIGNAL(activated(QModelIndex)), this, SLOT(insertCompletionItem(QModelIndex)));
  updateLineNumberAreaWidth(0);
  updateHighlights();
  updateCursorPosition();
  setLineWrapping();
  connect(this, SIGNAL(blockCountChanged(int)), this, SLOT(updateLineNumberAreaWidth(int)));
  connect(this, SIGNAL(updateRequest(QRect,int)), this, SLOT(updateLineNumberArea(QRect,int)));
  connect(this, SIGNAL(cursorPositionChanged()), this, SLOT(updateHighlights()));
  connect(this, SIGNAL(cursorPositionChanged()), this, SLOT(updateCursorPosition()));
  connect(document(), SIGNAL(contentsChange(int,int,int)), mpBaseEditor, SLOT(contentsHasChanged(int,int,int)));
  OptionsDialog *pOptionsDialog = OptionsDialog::instance();
  connect(pOptionsDialog, SIGNAL(textSettingsChanged()), this, SLOT(textSettingsChanged()));
  setContextMenuPolicy(Qt::CustomContextMenu);
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), mpBaseEditor, SLOT(showContextMenu(QPoint)));
  setUndoAvailable(false);
  setRedoAvailable(false);
  connect(this, SIGNAL(undoAvailable(bool)), SLOT(setUndoAvailable(bool)));
  connect(this, SIGNAL(redoAvailable(bool)), SLOT(setRedoAvailable(bool)));
}

/*!
 * \brief PlainTextEdit::eventFilter
 * Adds the background color and border to completer tooltip.
 * \param pObject
 * \param pEvent
 * \return
 */
bool PlainTextEdit::eventFilter(QObject *pObject, QEvent *pEvent)
{
  if (pObject != mpCompleterToolTipWidget) {
    return QObject::eventFilter(pObject, pEvent);
  }

  QWidget *pCompleterToolTipWidget = qobject_cast<QWidget*>(pObject);
  if (pCompleterToolTipWidget && pEvent->type() == QEvent::Paint) {
    QPainter painter (pCompleterToolTipWidget);
    painter.setPen(Qt::black);
    painter.setBrush(Qt::white);
    QRect rectangle = pCompleterToolTipWidget->rect();
    rectangle.setWidth(pCompleterToolTipWidget->rect().width() - 1);
    rectangle.setHeight(pCompleterToolTipWidget->rect().height() - 1);
    painter.drawRect(rectangle);
    return true;
  }
  return QObject::eventFilter(pObject, pEvent);
}

/*!
 * \class CompleterItem
 * \brief CompleterItem::CompleterItem
 * \param key
 * \param value
 * \param select
 * The constructor is set from outside depending on which editor is used (eg.) MetaModelicaEditor,
 * ModelicaEditor,CEditor etc..
 */
CompleterItem::CompleterItem(const QString &key, const QString &value, const QString &select)
  : mKey(key), mValue(value), mSelect(select)
{
  int ind = value.indexOf(select, 0);
  if (ind < 0) {
    mDescription = value;
  } else {
    mDescription = QString("<b>%1</b><i>%2</i>%3").arg(
          value.left(ind),
          select,
          value.right(value.size() - select.size() - ind)
        ).replace("\n", "<br/>");
  }
}

CompleterItem::CompleterItem(const QString &value, const QString &description)
  : mKey(value), mValue(value), mSelect(value), mDescription(description)
{
}

void PlainTextEdit::clearCompleter()
{
  mpStandardItemModel->clear();
}

void PlainTextEdit::insertCompleterSymbols(QList<CompleterItem> symbols, const QString &iconResource)
{
  for (int i = 0; i < symbols.size(); ++i) {
    QStandardItem *pStandardItem = new QStandardItem(symbols[i].mKey);
    pStandardItem->setIcon(QIcon(iconResource));
    pStandardItem->setData(QVariant::fromValue(symbols[i]), Qt::UserRole);
    mpStandardItemModel->appendRow(pStandardItem);
  }
}

/*!
 * \brief PlainTextEdit::insertCompleterKeywords
 * \param keywords
 * add Keyword list to the QStandardItemModel which will be used by the Completer
 * This function is set from outside depending on which editor is used (eg.) MetaModelicaEditor,
 * ModelicaEditor,CEditor etc..
 */
void PlainTextEdit::insertCompleterKeywords(QStringList keywords)
{
  for (int i = 0; i < keywords.size(); ++i) {
    QStandardItem *pStandardItem = new QStandardItem(keywords[i]);
    pStandardItem->setIcon(QIcon(":/Resources/icons/completerkeyword.svg"));
    pStandardItem->setData(QVariant::fromValue(CompleterItem(keywords[i],keywords[i],"")),Qt::UserRole);
    mpStandardItemModel->appendRow(pStandardItem);
  }
}

/*!
 * \brief PlainTextEdit::insertCompleterTypes
 * \param types
 * add types list to the QStandardItemModel which will be used by the Completer
 * This function is set from outside depending on which editor is used (eg.) MetaModelicaEditor,
 * ModelicaEditor,CEditor etc..
 */
void PlainTextEdit::insertCompleterTypes(QStringList types)
{
  for (int k = 0; k < types.size(); ++k) {
    QStandardItem *pStandardItem = new QStandardItem(types[k]);
    pStandardItem->setIcon(QIcon(":/Resources/icons/completerType.svg"));
    pStandardItem->setData(QVariant::fromValue(CompleterItem(types[k],types[k],"")),Qt::UserRole);
    mpStandardItemModel->appendRow(pStandardItem);
  }
}

/*!
 * \brief PlainTextEdit::insertCompleterCodeSnippets
 * \param items
 * Add codesnippet list to the QStandardItemModel which will be used by the Completer
 * This function is set from outside depending on which editor is used (eg.) MetaModelicaEditor,
 * ModelicaEditor,CEditor etc..
 */
void PlainTextEdit::insertCompleterCodeSnippets(QList<CompleterItem> items)
{
  for (int var = 0; var < items.length(); ++var) {
    QStandardItem *pStandardItem = new QStandardItem(items[var].mKey);
    pStandardItem->setIcon(QIcon(":/Resources/icons/completerCodeSnippets.svg"));
    pStandardItem->setData(QVariant::fromValue(items[var]),Qt::UserRole);
    mpStandardItemModel->appendRow(pStandardItem);
  }
}

/*!
 * \brief PlainTextEdit::setCanHaveBreakpoints
 * Sets whether editor supports breakpoints or not. Also sets/unsets the editor's LineNumberArea mouse tracking.
 * \param canHaveBreakpoints
 */
void PlainTextEdit::setCanHaveBreakpoints(bool canHaveBreakpoints)
{
  mCanHaveBreakpoints = canHaveBreakpoints;
  mpLineNumberArea->setMouseTracking(canHaveBreakpoints);
}

/*!
 * \brief PlainTextEdit::lineNumberAreaWidth
 * Calculate appropriate width for LineNumberArea.
 * \return int width of LineNumberArea.
 */
int PlainTextEdit::lineNumberAreaWidth()
{
  int digits = 2;
  int max = qMax(1, document()->blockCount());
  while (max >= 100) {
    max /= 10;
    ++digits;
  }
  const QFontMetrics fm(document()->defaultFont());
  int space = fm.width(QLatin1Char('9')) * digits;
  if (canHaveBreakpoints()) {
    space += fm.lineSpacing();
  } else {
    space += 4;
  }
  TextEditorPage *pTextEditorPage = OptionsDialog::instance()->getTextEditorPage();
  if (pTextEditorPage->getSyntaxHighlightingGroupBox()->isChecked() && pTextEditorPage->getCodeFoldingCheckBox()->isChecked()) {
    space += foldBoxWidth(fm);
  } else {
    space += 4;
  }
  return space;
}

/*!
 * \brief PlainTextEdit::lineNumberAreaPaintEvent
 * Activated whenever LineNumberArea Widget paint event is raised.
 * Writes the line numbers for the visible blocks and draws the breakpoint markers.
 * \param event
 */
void PlainTextEdit::lineNumberAreaPaintEvent(QPaintEvent *event)
{
  QPainter painter(mpLineNumberArea);
  painter.fillRect(event->rect(), QColor(240, 240, 240));

  QTextBlock block = firstVisibleBlock();
  int blockNumber = block.blockNumber();
  qreal top = blockBoundingGeometry(block).translated(contentOffset()).top();
  qreal bottom = top;
  const QFontMetrics fm(document()->defaultFont());
  int fmLineSpacing = fm.lineSpacing();

  int collapseColumnWidth = 4;
  TextEditorPage *pTextEditorPage = OptionsDialog::instance()->getTextEditorPage();
  if (pTextEditorPage->getSyntaxHighlightingGroupBox()->isChecked() && pTextEditorPage->getCodeFoldingCheckBox()->isChecked()) {
    collapseColumnWidth = foldBoxWidth(fm);
  }
  const int lineNumbersWidth = mpLineNumberArea->width() - collapseColumnWidth;

  while (block.isValid() && top <= event->rect().bottom()) {
    QTextDocument *pTextDocument = document();
    top = bottom;
    const qreal height = blockBoundingRect(block).height();
    bottom = top + height;
    QTextBlock nextBlock = block.next();

    QTextBlock nextVisibleBlock = nextBlock;
    int nextVisibleBlockNumber = blockNumber + 1;

    if (!nextVisibleBlock.isVisible()) {
      // invisible blocks do have zero line count
      nextVisibleBlock = pTextDocument->findBlockByLineNumber(nextVisibleBlock.firstLineNumber());
      nextVisibleBlockNumber = nextVisibleBlock.blockNumber();
    }

    if (bottom < event->rect().top()) {
      block = nextVisibleBlock;
      blockNumber = nextVisibleBlockNumber;
      continue;
    }
    /* paint breakpoints */
    TextBlockUserData *pTextBlockUserData = static_cast<TextBlockUserData*>(block.userData());
    if (pTextBlockUserData && canHaveBreakpoints()) {
      int xoffset = 0;
      foreach (ITextMark *mk, pTextBlockUserData->marks()) {
        int x = 0;
        int radius = fmLineSpacing;
        QRect r(x + xoffset, top, radius, radius);
        mk->icon().paint(&painter, r, Qt::AlignCenter);
        xoffset += 2;
      }
    }
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
      painter.drawText(0, top, lineNumbersWidth, fm.height(), Qt::AlignRight, number);
    }
    // paint folding markers
    TextEditorPage *pTextEditorPage = OptionsDialog::instance()->getTextEditorPage();
    if (pTextEditorPage->getSyntaxHighlightingGroupBox()->isChecked() && pTextEditorPage->getCodeFoldingCheckBox()->isChecked()) {
      painter.save();
      painter.setRenderHint(QPainter::Antialiasing, false);
      painter.setPen(Qt::gray);

      TextBlockUserData *nextBlockUserData = BaseEditorDocumentLayout::testUserData(nextBlock);
      bool drawFoldingControl = nextBlockUserData && BaseEditorDocumentLayout::foldingIndent(block) < nextBlockUserData->foldingIndent();
      bool drawLine = BaseEditorDocumentLayout::foldingIndent(block) > 0;
      bool drawEnd = drawLine && (!nextBlockUserData || (nextBlockUserData && BaseEditorDocumentLayout::foldingIndent(block) > nextBlockUserData->foldingIndent()));
      int boxWidth = foldBoxWidth(fm);
      int size = boxWidth / 4;
      QRect foldingMarkerBox(lineNumbersWidth + size, top + size, 2 * (size) + 1, 2 * (size) + 1);
      QRect foldingLineBox(lineNumbersWidth + size, top, 2 * (size) + 1, height);

      if (drawEnd) {
        painter.drawLine(QPointF(foldingLineBox.center().x(), foldingLineBox.top()), foldingLineBox.center());
        painter.drawLine(foldingLineBox.center(), QPointF(foldingLineBox.right(), foldingLineBox.center().y()));
      }

      if (drawLine && !drawEnd) {
        painter.drawLine(QPointF(foldingLineBox.center().x(), foldingLineBox.top()),
                         QPointF(foldingLineBox.center().x(), foldingLineBox.bottom()));
      }

      if (drawFoldingControl) {
        bool expanded = nextBlock.isVisible();
        QStyle *pStyle = style();
        QStyleOptionViewItemV2 styleOptionViewItem;
        styleOptionViewItem.rect = foldingMarkerBox;
        styleOptionViewItem.state = QStyle::State_Active | QStyle::State_Item | QStyle::State_Children;
        /* For some reason QStyle::PE_IndicatorBranch is not showing up in MAC.
         * So I use QStyle::PE_IndicatorArrowDown and QStyle::PE_IndicatorArrowRight
         * Perhaps this is fixed in newer Qt versions. We will see when we use Qt 5 for MAC.
         */
#ifndef Q_OS_MAC
        if (expanded) {
          styleOptionViewItem.state |= QStyle::State_Open;
        }
        pStyle->drawPrimitive(QStyle::PE_IndicatorBranch, &styleOptionViewItem, &painter, mpLineNumberArea);
#else
        styleOptionViewItem.rect.translate(-1, 0);
        if (expanded) {
          pStyle->drawPrimitive(QStyle::PE_IndicatorArrowDown, &styleOptionViewItem, &painter, mpLineNumberArea);
        } else {
          pStyle->drawPrimitive(QStyle::PE_IndicatorArrowRight, &styleOptionViewItem, &painter, mpLineNumberArea);
        }
#endif
      }
      painter.restore();
    }
    block = nextVisibleBlock;
    blockNumber = nextVisibleBlockNumber;
  }
}

/*!
 * \brief PlainTextEdit::lineNumberAreaMouseEvent
 * Activated whenever LineNumberArea Widget mouse press event is raised.
 * \param event
 */
void PlainTextEdit::lineNumberAreaMouseEvent(QMouseEvent *event)
{
  QTextCursor cursor = cursorForPosition(QPoint(0, event->pos().y()));
  const QFontMetrics fm(document()->defaultFont());
  // check mouse click for breakpoints
  if (canHaveBreakpoints()) {
    int breakPointWidth = fm.lineSpacing();
    // Set whether the mouse cursor is a hand or a normal arrow
    if (event->type() == QEvent::MouseMove) {
      bool handCursor = (event->pos().x() <= breakPointWidth);
      if (handCursor != (mpLineNumberArea->cursor().shape() == Qt::PointingHandCursor)) {
        mpLineNumberArea->setCursor(handCursor ? Qt::PointingHandCursor : Qt::ArrowCursor);
      }
    } else if ((event->type() == QEvent::MouseButtonPress || event->type() == QEvent::MouseButtonDblClick) &&
               (event->pos().x() <= breakPointWidth)) {
      /* Do not allow breakpoints if file is not saved. */
      if (!mpBaseEditor->getModelWidget()->getLibraryTreeItem()->isSaved()) {
        mpBaseEditor->getInfoBar()->showMessage(tr("<b>Information: </b>Breakpoints are only allowed on saved classes."));
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
  // check mouse click for folding markers
  TextEditorPage *pTextEditorPage = OptionsDialog::instance()->getTextEditorPage();
  if (pTextEditorPage->getSyntaxHighlightingGroupBox()->isChecked() && pTextEditorPage->getCodeFoldingCheckBox()->isChecked()) {
    int boxWidth = foldBoxWidth(fm);
    if (event->button() == Qt::LeftButton && event->pos().x() > mpLineNumberArea->width() - boxWidth) {
      if (!cursor.block().next().isVisible()) {
        toggleBlockVisible(cursor.block());
        moveCursorVisible(false);
      } else if (BaseEditorDocumentLayout::canFold(cursor.block())) {
        toggleBlockVisible(cursor.block());
        moveCursorVisible(false);
      }
    }
  }
}

/*!
 * \brief PlainTextEdit::goToLineNumber
 * Takes the cursor to the specific line.
 * \param lineNumber - the line number to go.
 */
void PlainTextEdit::goToLineNumber(int lineNumber)
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
 * \brief PlainTextEdit::highlightCurrentLine
 * Hightlights the current line.
 */
void PlainTextEdit::highlightCurrentLine()
{
  Utilities::highlightCurrentLine(this);
}

/*!
 * \brief PlainTextEdit::highlightParentheses
 * Highlights the matching parentheses.
 */
void PlainTextEdit::highlightParentheses()
{
  Utilities::highlightParentheses(this, mParenthesesMatchFormat, mParenthesesMisMatchFormat);
}

/*!
 * \brief BaseEditor::setLineWrapping
 * Sets the Editor Line Wrapping mode.
 */
void PlainTextEdit::setLineWrapping()
{
  OptionsDialog *pOptionsDialog = OptionsDialog::instance();
  if (pOptionsDialog->getTextEditorPage()->getLineWrappingCheckbox()->isChecked()) {
    setLineWrapMode(QPlainTextEdit::WidgetWidth);
  } else {
    setLineWrapMode(QPlainTextEdit::NoWrap);
  }
}

/*!
 * \brief PlainTextEdit::plainTextFromSelection
 * Returns the selected text in plain text format.
 * \param cursor
 * \return
 */
QString PlainTextEdit::plainTextFromSelection(const QTextCursor &cursor) const
{
  // Copy the selected text as plain text
  QString text = cursor.selectedText();
  return convertToPlainText(text);
}

/*!
 * \brief PlainTextEdit::convertToPlainText
 * Returns the text in plain text format.
 * \param txt
 * \return
 */
QString PlainTextEdit::convertToPlainText(const QString &txt)
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
 * \brief PlainTextEdit::moveCursorVisible
 * \param ensureVisible
 */
void PlainTextEdit::moveCursorVisible(bool ensureVisible)
{
  QTextCursor cursor = textCursor();
  if (!cursor.block().isVisible()) {
    cursor.setVisualNavigation(true);
    cursor.movePosition(QTextCursor::Up);
    setTextCursor(cursor);
  }
  if (ensureVisible) {
    ensureCursorVisible();
  }
}

/*!
 * \brief PlainTextEdit::ensureCursorVisible
 * Makes sure cursor is visible when user moves it inside hidden block.
 */
void PlainTextEdit::ensureCursorVisible()
{
  QTextBlock block = textCursor().block();
  if (!block.isVisible()) {
    BaseEditorDocumentLayout *pDocumentLayout = qobject_cast<BaseEditorDocumentLayout*>(document()->documentLayout());
    // Open all folds of current line.
    int indent = BaseEditorDocumentLayout::foldingIndent(block);
    block = block.previous();
    while (block.isValid()) {
      const int indent2 = BaseEditorDocumentLayout::foldingIndent(block);
      if (BaseEditorDocumentLayout::canFold(block) && indent2 < indent) {
        BaseEditorDocumentLayout::foldOrUnfold(block, true);
        if (block.isVisible()) {
          break;
        }
        indent = indent2;
      }
      block = block.previous();
    }
    pDocumentLayout->requestUpdate();
    pDocumentLayout->emitDocumentSizeChanged();
  }
  QPlainTextEdit::ensureCursorVisible();
}

/*!
 * \brief PlainTextEdit::toggleBreakpoint
 * Toggles the breakpoint.
 * \param fileName
 * \param lineNumber
 */
void PlainTextEdit::toggleBreakpoint(const QString fileName, int lineNumber)
{
  BreakpointsTreeModel *pBreakpointsTreeModel = MainWindow::instance()->getBreakpointsWidget()->getBreakpointsTreeModel();
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
void PlainTextEdit::indentOrUnindent(bool doIndent)
{
  TabSettings tabSettings = OptionsDialog::instance()->getTabSettings();
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
 * \brief PlainTextEdit::foldOrUnfold
 * folds or unfolds the whole document foldings.
 * \param unFold
 */
void PlainTextEdit::foldOrUnfold(bool unFold)
{
  BaseEditorDocumentLayout *pBaseEditorDocumentLayout = qobject_cast<BaseEditorDocumentLayout*>(document()->documentLayout());

  QTextBlock block = document()->firstBlock();
  while (block.isValid()) {
    if (BaseEditorDocumentLayout::canFold(block)) {
      BaseEditorDocumentLayout::foldOrUnfold(block, unFold);
    }
    block = block.next();
  }

  moveCursorVisible();
  pBaseEditorDocumentLayout->requestUpdate();
  pBaseEditorDocumentLayout->emitDocumentSizeChanged();
  centerCursor();
}

/*!
 * \brief PlainTextEdit::handleHomeKey
 * Handles the home key.\n
 * Moves the cursor to the start of the line.\n
 * Skips the trailing spaces.
 * \param keepAnchor
 */
void PlainTextEdit::handleHomeKey(bool keepAnchor)
{
  QTextCursor cursor = textCursor();
  QTextCursor::MoveMode mode = keepAnchor ? QTextCursor::KeepAnchor : QTextCursor::MoveAnchor;
  const int initpos = cursor.position();
  int pos = cursor.block().position();
  QChar character = document()->characterAt(pos);
  const QLatin1Char tab = QLatin1Char('\t');
  // loop until we have some character
  while (character == tab || character.category() == QChar::Separator_Space) {
    ++pos;
    if (pos == initpos) {
      break;
    }
    character = document()->characterAt(pos);
  }
  // Go to the start of the block when we're already at the start of the text
  if (pos == initpos) {
    pos = cursor.block().position();
  }
  // set the cursor position
  cursor.setPosition(pos, mode);
  setTextCursor(cursor);
}

/*!
 * \brief PlainTextEdit::toggleBlockVisible
 * Toggles the folding of the block.
 * \param block
 */
void PlainTextEdit::toggleBlockVisible(const QTextBlock &block)
{
  BaseEditorDocumentLayout *pBaseEditorDocumentLayout;
  pBaseEditorDocumentLayout = qobject_cast<BaseEditorDocumentLayout*>(document()->documentLayout());
  BaseEditorDocumentLayout::foldOrUnfold(block, BaseEditorDocumentLayout::isFolded(block));
  pBaseEditorDocumentLayout->requestUpdate();
  pBaseEditorDocumentLayout->emitDocumentSizeChanged();
}


/*!
 * \brief BaseEditor::updateLineNumberAreaWidth
 * Updates the width of LineNumberArea.
 * \param newBlockCount
 */
void PlainTextEdit::updateLineNumberAreaWidth(int newBlockCount)
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
void PlainTextEdit::updateLineNumberArea(const QRect &rect, int dy)
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
void PlainTextEdit::updateHighlights()
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
void PlainTextEdit::updateCursorPosition()
{
  if (mpBaseEditor->getModelWidget() && isVisible()) {
    const QTextBlock block = textCursor().block();
    const int line = block.blockNumber() + 1;
    const int column = textCursor().columnNumber();
    Label *pPositionLabel = MainWindow::instance()->getPositionLabel();
    pPositionLabel->setText(QString("Ln: %1, Col: %2").arg(line).arg(column));
  }
  ensureCursorVisible();
}

/*!
 * \brief PlainTextEdit::textSettingsChanged
 * Triggered when text settings are changed in the OptionsDialog.
 */
void PlainTextEdit::textSettingsChanged()
{
  // update line wrapping
  setLineWrapping();
  // update code foldings
  bool enable = true;
  // if user disables the code folding then unfold all the text editors.
  TextEditorPage *pTextEditorPage = OptionsDialog::instance()->getTextEditorPage();
  if (!pTextEditorPage->getSyntaxHighlightingGroupBox()->isChecked() || !pTextEditorPage->getCodeFoldingCheckBox()->isChecked()) {
    foldOrUnfold(true);
    enable = false;
  }
  mpBaseEditor->getFoldAllAction()->setEnabled(enable);
  mpBaseEditor->getUnFoldAllAction()->setEnabled(enable);
}

/*!
 * \brief PlainTextEdit::showTabsAndSpaces
 * Shows/hide tabs and spaces for the editor.
 * \param On
 */
void PlainTextEdit::showTabsAndSpaces(bool On)
{
  QTextOption textOption = document()->defaultTextOption();
  if (On) {
    textOption.setFlags(textOption.flags() | QTextOption::ShowTabsAndSpaces);
  } else {
    textOption.setFlags(textOption.flags() & ~QTextOption::ShowTabsAndSpaces);
  }
  document()->setDefaultTextOption(textOption);
}

/*!
 * \brief PlainTextEdit::toggleBreakpoint
 * Slot activated when set breakpoint is seleteted from line number area context menu.
 */
void PlainTextEdit::toggleBreakpoint()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction) {
    QStringList list = pAction->data().toStringList();
    toggleBreakpoint(list.at(0), list.at(1).toInt());
  }
}

/*!
 * \brief PlainTextEdit::foldAll
 * Folds all the foldings in the document.
 */
void PlainTextEdit::foldAll()
{
  TextEditorPage *pTextEditorPage = OptionsDialog::instance()->getTextEditorPage();
  if (pTextEditorPage->getSyntaxHighlightingGroupBox()->isChecked() && pTextEditorPage->getCodeFoldingCheckBox()->isChecked()) {
    foldOrUnfold(false);
  }
}

/*!
 * \brief PlainTextEdit::unFoldAll
 * Unfolds all the foldings in the document.
 */
void PlainTextEdit::unFoldAll()
{
  TextEditorPage *pTextEditorPage = OptionsDialog::instance()->getTextEditorPage();
  if (pTextEditorPage->getSyntaxHighlightingGroupBox()->isChecked() && pTextEditorPage->getCodeFoldingCheckBox()->isChecked()) {
    foldOrUnfold(true);
  }
}

/*!
 * \brief PlainTextEdit::resetZoom
 * Resets the document font size.
 */
void PlainTextEdit::resetZoom()
{
  QFont font = document()->defaultFont();
  font.setPointSizeF(OptionsDialog::instance()->getTextEditorPage()->getFontSizeSpinBox()->value());
  document()->setDefaultFont(font);
}

/*!
 * \brief PlainTextEdit::zoomIn
 * Increases the document font size.
 */
void PlainTextEdit::zoomIn()
{
  QFont font = document()->defaultFont();
  qreal fontSize = font.pointSizeF();
  fontSize = fontSize  + 1;
  font.setPointSizeF(fontSize);
  document()->setDefaultFont(font);
}

/*!
 * \brief PlainTextEdit::zoomOut
 * Decreases the document font size.
 */
void PlainTextEdit::zoomOut()
{
  QFont font = document()->defaultFont();
  qreal fontSize = font.pointSizeF();
  fontSize = fontSize <= 6 ? fontSize : fontSize - 1;
  font.setPointSizeF(fontSize);
  document()->setDefaultFont(font);
}

/*!
 * \brief PlainTextEdit::resizeEvent
 * Reimplementation of resize event.
 * Resets the size of LineNumberArea.
 * \param pEvent
 */
void PlainTextEdit::resizeEvent(QResizeEvent *pEvent)
{
  QPlainTextEdit::resizeEvent(pEvent);

  QRect cr = contentsRect();
  mpLineNumberArea->setGeometry(QRect(cr.left(), cr.top(), lineNumberAreaWidth(), cr.height()));
}

QCompleter *PlainTextEdit::completer()
{
  return mpCompleter;
}

/*!
 * \brief PlainTextEdit::showCompletionItemToolTip
 * \param index
 * Shows the tooltip widget for the CompleterItem represented by QModelIndex.
 */
void PlainTextEdit::showCompletionItemToolTip(const QModelIndex &index)
{
  TextEditorPage *pTextEditorPage = OptionsDialog::instance()->getTextEditorPage();
  if (pTextEditorPage->getAutoCompleteCheckBox()->isChecked()) {
    QVariant value = index.data(Qt::UserRole);
    CompleterItem completerItem = qvariant_cast<CompleterItem>(value);
    mpCompleterToolTipLabel->setText(completerItem.mDescription);
    mpCompleterToolTipWidget->adjustSize();
    QRect rect = mpCompleter->popup()->visualRect(index);
    mpCompleterToolTipWidget->move(mpCompleter->popup()->mapToGlobal(QPoint(rect.x() + mpCompleter->popup()->width() + 2, rect.y() + 2)));
    mpCompleterToolTipWidget->show();
  }
}

/*!
 * PlainTextEdit::insertCompletionItem
 * insert the completerItems from the completer popup
 */
void PlainTextEdit::insertCompletionItem(const QModelIndex &index)
{
  QVariant value = index.data(Qt::UserRole);
  CompleterItem completerItem = qvariant_cast<CompleterItem>(value);
  QString selectiontext = completerItem.mSelect;
  QStringList completionlength = completerItem.mValue.split("\n");
  QTextCursor cursor = textCursor();
  cursor.beginEditBlock();
  int extra = completionlength[0].length() - mpCompleter->completionPrefix().length();
  cursor.movePosition(QTextCursor::EndOfWord);
  cursor.insertText(completionlength[0].right(extra));
  // store the cursor position to be used for selecting text when inserting code snippets
  int currentpos = cursor.position();
  int startpos = currentpos-completionlength[0].length();
  // To insert CodeSnippets
  if (completionlength.length() > 1) {
    // Calculate the indentation spaces for the inserted text
    TabSettings tabSettings = OptionsDialog::instance()->getTabSettings();
    cursor.insertText("\n");
    const QTextBlock previousBlock = cursor.block().previous();
    QString indentText = previousBlock.text();
    cursor.deletePreviousChar();
    for (int var = 1; var < completionlength.length(); ++var) {
      cursor.insertText("\n");
      cursor.insertText(indentText.left(tabSettings.firstNonSpace(indentText)));
      cursor.insertText(completionlength[var]);
    }
    // set the cursor to appropriate selection text
    int indexpos=completionlength[0].indexOf(selectiontext,0); //find the index position of the selection text from the word
    cursor.setPosition(startpos+indexpos,QTextCursor::MoveAnchor);
	cursor.setPosition(startpos+indexpos+selectiontext.length(), QTextCursor::KeepAnchor);
  }
  cursor.endEditBlock();
  setTextCursor(cursor);
}

QString PlainTextEdit::textUnderCursor() const
{
  QTextCursor cursor = textCursor();
  cursor.select(QTextCursor::WordUnderCursor);
  return cursor.selectedText();
}

/*!
 * \brief PlainTextEdit::keyPressEvent
 * Reimplementation of keyPressEvent.
 * \param pEvent
 */
void PlainTextEdit::keyPressEvent(QKeyEvent *pEvent)
{
  bool shiftModifier = pEvent->modifiers().testFlag(Qt::ShiftModifier);
  bool controlModifier = pEvent->modifiers().testFlag(Qt::ControlModifier);
  bool isCompleterShortcut = controlModifier && (pEvent->key() == Qt::Key_Space); // CTRL+space
  bool isCompleterChar = mCompletionCharacters.indexOf(pEvent->key()) != -1;
  /* Ticket #4404. hide the completer on Esc and enter text based on Tab */
  if (mpCompleter && mpCompleter->popup()->isVisible()) {
    // The following keys are forwarded by the completer to the widget
    switch (pEvent->key()) {
      case Qt::Key_Enter:
      case Qt::Key_Return:
      case Qt::Key_Escape:
      case Qt::Key_Tab:
      case Qt::Key_Backtab:
        pEvent->ignore();
        return; // let the completer do default behavior
      default:
        break;
    }
  }
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
  } else if (controlModifier && pEvent->key() == Qt::Key_F) {
    // ctrl+f is pressed.
    mpBaseEditor->showFindReplaceWidget();
    return;
  } else if (controlModifier && pEvent->key() == Qt::Key_L) {
    // ctrl+l is pressed.
    mpBaseEditor->showGotoLineNumberDialog();
    return;
  } else if (controlModifier && pEvent->key() == Qt::Key_K) {
    // ctrl+k is pressed.
    mpBaseEditor->toggleCommentSelection();
    return;
  } else if (pEvent->matches(QKeySequence::Cut) || pEvent->matches(QKeySequence::Copy)) {
    // ctrl+x/ctrl+c is pressed.
    if (mpBaseEditor->getModelWidget() && mpBaseEditor->getModelWidget()->getLibraryTreeItem()
        && ((mpBaseEditor->getModelWidget()->getLibraryTreeItem()->getAccess() <= LibraryTreeItem::nonPackageText)
            || (mpBaseEditor->getModelWidget()->getLibraryTreeItem()->getAccess() == LibraryTreeItem::packageText))) {
      return;
    }
  } else if (pEvent->matches(QKeySequence::Undo)) {
    // ctrl+z is pressed.
    if (mpBaseEditor->getModelWidget()) {
      MainWindow::instance()->undo();
    } else {
      undo();
    }
    return;
  } else if (pEvent->matches(QKeySequence::Redo)) {
    // ctrl+y is pressed.
    if (mpBaseEditor->getModelWidget()) {
      MainWindow::instance()->redo();
    } else {
      redo();
    }
    return;
  } else if (shiftModifier && pEvent->key() == Qt::Key_Home) {
    handleHomeKey(true);
    return;
  } else if (pEvent->key() == Qt::Key_Home) {
    handleHomeKey(false);
    return;
  } else if (shiftModifier && (pEvent->key() == Qt::Key_Enter || pEvent->key() == Qt::Key_Return)) {
    /* Ticket #2273. Change shift+enter to enter. */
    pEvent->setModifiers(Qt::NoModifier);
  }
  /* do not change the order of execution as the indentation event will fail when completer is on */
  if (!mpCompleter || !isCompleterShortcut) { // do not process the shortcut when we have a completer
    QPlainTextEdit::keyPressEvent(pEvent);
  }
  /* If user has pressed enter then a new line is inserted.
   * Indent the new line based on the indentation of previous line.
   */

  /*! @todo We should add formatter classes to handle this based on editor language i.e Modelica or C/C++. */
  if (pEvent->key() == Qt::Key_Enter || pEvent->key() == Qt::Key_Return) {
    TabSettings tabSettings = OptionsDialog::instance()->getTabSettings();
    QTextCursor cursor = textCursor();
    const QTextBlock previousBlock = cursor.block().previous();
    QString indentText = previousBlock.text();
    cursor.beginEditBlock();
    cursor.insertText(indentText.left(tabSettings.firstNonSpace(indentText)));
    cursor.endEditBlock();
    setTextCursor(cursor);
  }

  const bool ctrlOrShift = pEvent->modifiers() & (Qt::ControlModifier | Qt::ShiftModifier);
  if (!mpCompleter || (ctrlOrShift && pEvent->text().isEmpty())) {
    return;
  }

  static QString eow("~!@#$%^&*()_+{}|:\"<>?,./;'[]\\-="); // end of word
  bool hasModifier = (pEvent->modifiers() != Qt::NoModifier) && !ctrlOrShift;
  QString completionPrefix = textUnderCursor();
  if ((!isCompleterShortcut && !isCompleterChar) && (hasModifier || pEvent->text().isEmpty()|| completionPrefix.length() < 1 || eow.contains(pEvent->text().right(1)))) {
    mpCompleter->popup()->hide();
    return;
  }

  if (completionPrefix != mpCompleter->completionPrefix()) {
    mpCompleter->setCompletionPrefix(completionPrefix);
  }
  //pop up the completer according to editor instance
  TextEditorPage *pTextEditorPage = OptionsDialog::instance()->getTextEditorPage();
  if (pTextEditorPage->getAutoCompleteCheckBox()->isChecked()) {
    mpBaseEditor->popUpCompleter();
  }
  if (mpCompleter->popup()->selectionModel()->selection().empty()) {
    mpCompleter->popup()->setCurrentIndex(mpCompleter->completionModel()->index(0, 0));
  }
}

/*!
 * \brief PlainTextEdit::createMimeDataFromSelection
 * Reimplementation of QPlainTextEdit::createMimeDataFromSelection() to allow copying text with formatting.
 * \return
 */
QMimeData* PlainTextEdit::createMimeDataFromSelection() const
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
 * \brief PlainTextEdit::focusInEvent
 * Reimplementation of QPlainTextEdit::focusInEvent(). Stops the auto save timer.
 * \param event
 */
void PlainTextEdit::focusInEvent(QFocusEvent *event)
{
  MainWindow::instance()->getAutoSaveTimer()->stop();
  QPlainTextEdit::focusInEvent(event);
}

/*!
 * \brief PlainTextEdit::focusOutEvent
 * Reimplementation of QPlainTextEdit::focusOutEvent(). Restarts the auto save timer.
 * \param event
 */
void PlainTextEdit::focusOutEvent(QFocusEvent *event)
{
  /* The user might start editing the document and then minimize the OMEdit window.
   * We should only start the autosavetimer when MainWindow is the active window and focusOutEvent is called.
   */
  if (MainWindow::instance()->isActiveWindow()) {
    if (OptionsDialog::instance()->getGeneralSettingsPage()->getEnableAutoSaveGroupBox()->isChecked()) {
      MainWindow::instance()->getAutoSaveTimer()->start();
    }
  }
  QPlainTextEdit::focusOutEvent(event);
}

/*!
 * \brief PlainTextEdit::paintEvent
 * Reimplementation for QPlainTextEdit::paintEvent() to draw folding indication in the text.
 * \param e
 */
void PlainTextEdit::paintEvent(QPaintEvent *e)
{
  if (mpCompleterToolTipWidget->isVisible()) {
    mpCompleterToolTipWidget->setVisible(mpCompleter->popup()->isVisible());
    QModelIndexList modelIndexes = mpCompleter->popup()->selectionModel()->selectedIndexes();
    if (!modelIndexes.isEmpty()) {
      QRect rect = mpCompleter->popup()->visualRect(modelIndexes.at(0));
      mpCompleterToolTipWidget->move(mpCompleter->popup()->mapToGlobal(QPoint(rect.x() + mpCompleter->popup()->width() + 2, rect.y() + 2)));
    }
  }
  QPlainTextEdit::paintEvent(e);

  QPointF offset(contentOffset());
  QPainter painter(viewport());
  QTextBlock block = firstVisibleBlock();

  qreal top = blockBoundingGeometry(block).translated(offset).top();
  qreal bottom = top + blockBoundingRect(block).height();

  QTextCursor cursor = textCursor();
  bool hasSelection = cursor.hasSelection();
  int selectionStart = cursor.selectionStart();
  int selectionEnd = cursor.selectionEnd();

  QTextDocument *pTextDocument = document();

  while (block.isValid() && top <= e->rect().bottom()) {
    QTextBlock nextBlock = block.next();
    QTextBlock nextVisibleBlock = nextBlock;

    if (!nextVisibleBlock.isVisible()) {
      // invisible blocks do have zero line count
      nextVisibleBlock = pTextDocument->findBlockByLineNumber(nextVisibleBlock.firstLineNumber());
      // in case our code somewhere did not set the line count of the invisible block to 0
      while (nextVisibleBlock.isValid() && !nextVisibleBlock.isVisible()) {
        nextVisibleBlock = nextVisibleBlock.next();
      }
    }
    if (block.isVisible() && bottom >= e->rect().top()) {
      if (nextBlock.isValid() && !nextBlock.isVisible()) {
        bool selectThis = (hasSelection && nextBlock.position() >= selectionStart && nextBlock.position() < selectionEnd);
        painter.save();
        painter.setFont(document()->defaultFont());
        painter.setPen(QColor(Qt::darkGray));
        if (selectThis) {
          painter.setBrush(palette().highlight());
        }

        QTextLayout *pTextLayout = block.layout();
        QTextLine line = pTextLayout->lineAt(pTextLayout->lineCount()-1);
        QRectF lineRect = line.naturalTextRect().translated(offset.x(), top);
        lineRect.adjust(0, 0, -1, -1);

        QString replacement = QLatin1String("...");
        QString rectReplacement = QLatin1String(" ") + replacement + QLatin1String("); ");

        const QFontMetrics fm(document()->defaultFont());
        QRectF collapseRect(lineRect.right() + 12, lineRect.top(), fm.width(rectReplacement), lineRect.height());
        painter.setRenderHint(QPainter::Antialiasing, true);
        painter.translate(.5, .5);
        painter.drawRoundedRect(collapseRect.adjusted(0, 0, 0, -1), 3, 3);
        painter.setRenderHint(QPainter::Antialiasing, false);
        painter.translate(-.5, -.5);

        block = nextVisibleBlock.previous();
        if (!block.isValid())
          block = pTextDocument->lastBlock();

        if (TextBlockUserData *blockUserData = BaseEditorDocumentLayout::testUserData(block)) {
          if (blockUserData->foldingEndIncluded()) {
            QString right = block.text().trimmed();
            if (right.endsWith(QLatin1Char(';'))) {
              right.chop(1);
              right = right.trimmed();
              replacement.append(right.right(right.endsWith(QLatin1Char('/')) ? 2 : 1));
              replacement.append(QLatin1Char(';'));
            }
          }
        }

        if (selectThis) {
          painter.setPen(palette().highlightedText().color());
        }
        painter.drawText(collapseRect, Qt::AlignCenter, replacement);
        painter.restore();
      }
    }

    block = nextVisibleBlock;
    top = bottom;
    bottom = top + blockBoundingRect(block).height();
  }
}

/*!
 * \brief PlainTextEdit::wheelEvent
 * \param event
 */
void PlainTextEdit::wheelEvent(QWheelEvent *event)
{
  if (event->modifiers() & Qt::ControlModifier) {
    if (event->delta() > 0) {
      zoomIn();
    } else {
      zoomOut();
    }
  }
  QPlainTextEdit::wheelEvent(event);
}

/*!
 * \class BaseEditor
 * Base class for all editors.
 */
/*!
 * \brief BaseEditor::BaseEditor
 * \param pParent
 */
BaseEditor::BaseEditor(QWidget *pParent)
  : QWidget(pParent)
{
  if (qobject_cast<ModelWidget*>(pParent)) {
    mpModelWidget = qobject_cast<ModelWidget*>(pParent);
  } else {
    mpModelWidget = 0;
  }
  initialize();
}

/*!
 * \brief BaseEditor::initialize
 * Initializes the editor with default values.
 */
void BaseEditor::initialize()
{
  mpInfoBar = new InfoBar(this);
  mpInfoBar->hide();
  mpPlainTextEdit = new PlainTextEdit(this);
  mpFindReplaceWidget = new FindReplaceWidget(this);
  mpFindReplaceWidget->hide();
  createActions();
  mForceSetPlainText = false;
  // set the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpInfoBar, 0, Qt::AlignTop);
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
  connect(mpShowTabsAndSpacesAction, SIGNAL(triggered(bool)), mpPlainTextEdit, SLOT(showTabsAndSpaces(bool)));
  /* Toggle breakpoint action */
  mpToggleBreakpointAction = new QAction(tr("Toggle Breakpoint"), this);
  connect(mpToggleBreakpointAction, SIGNAL(triggered()), mpPlainTextEdit, SLOT(toggleBreakpoint()));
  // we only define the zooming actions if ModelWidget is NULL otherwise we use the zooming actions from toolbar.
  if (!mpModelWidget) {
    // reset zoom action
    mpResetZoomAction = new QAction(QIcon(":/Resources/icons/zoomReset.svg"), Helper::resetZoom, this);
    mpResetZoomAction->setStatusTip(Helper::resetZoom);
    mpResetZoomAction->setShortcut(QKeySequence("Ctrl+0"));
    connect(mpResetZoomAction, SIGNAL(triggered()), mpPlainTextEdit, SLOT(resetZoom()));
    mpPlainTextEdit->addAction(mpResetZoomAction);
    // zoom in action
    mpZoomInAction = new QAction(QIcon(":/Resources/icons/zoomIn.svg"), Helper::zoomIn, this);
    mpZoomInAction->setStatusTip(Helper::zoomIn);
    mpZoomInAction->setShortcut(QKeySequence("Ctrl++"));
    connect(mpZoomInAction, SIGNAL(triggered()), mpPlainTextEdit, SLOT(zoomIn()));
    mpPlainTextEdit->addAction(mpZoomInAction);
    // zoom out action
    mpZoomOutAction = new QAction(QIcon(":/Resources/icons/zoomOut.svg"), Helper::zoomOut, this);
    mpZoomOutAction->setStatusTip(Helper::zoomOut);
    mpZoomOutAction->setShortcut(QKeySequence("Ctrl+-"));
    connect(mpZoomOutAction, SIGNAL(triggered()), mpPlainTextEdit, SLOT(zoomOut()));
    mpPlainTextEdit->addAction(mpZoomOutAction);
  }
  // toggle comment action
  mpToggleCommentSelectionAction = new QAction(tr("Toggle Comment Selection"), this);
  mpToggleCommentSelectionAction->setShortcut(QKeySequence("Ctrl+k"));
  connect(mpToggleCommentSelectionAction, SIGNAL(triggered()), SLOT(toggleCommentSelection()));
  // folding actions
  bool enable = true;
  // if user disables the code folding then unfold all the text editors.
  TextEditorPage *pTextEditorPage = OptionsDialog::instance()->getTextEditorPage();
  if (!pTextEditorPage->getSyntaxHighlightingGroupBox()->isChecked() || !pTextEditorPage->getCodeFoldingCheckBox()->isChecked()) {
    enable = false;
  }
  // fold all action
  mpFoldAllAction = new QAction(tr("Fold All"), this);
  mpFoldAllAction->setEnabled(enable);
  connect(mpFoldAllAction, SIGNAL(triggered()), mpPlainTextEdit, SLOT(foldAll()));
  // unfold all action
  mpUnFoldAllAction = new QAction(tr("Unfold All"), this);
  mpUnFoldAllAction->setEnabled(enable);
  connect(mpUnFoldAllAction, SIGNAL(triggered()), mpPlainTextEdit, SLOT(unFoldAll()));
}

static inline void setActionIcon(QAction *pAction, const QString &name)
{
  const QIcon icon = QIcon::fromTheme(name);
  if (!icon.isNull()) {
    pAction->setIcon(icon);
  }
}

/*!
 * \brief BaseEditor::createStandardContextMenu
 * Creates a standard context menu for ediotr.
 * \return
 */
QMenu* BaseEditor::createStandardContextMenu()
{
  /* ticket:4334 & 4344
   * It's not possible to remove QPlainTextEdit undo/redo actions from standard context menu.
   * So don't use the standard context menu.
   * Added our custom undo/redo actions to the custom context menu.
   */
  //  QMenu *pMenu = mpPlainTextEdit->createStandardContextMenu();
  QMenu *pMenu = new QMenu;
  if (mpModelWidget) {
    pMenu->addAction(MainWindow::instance()->getUndoAction());
    pMenu->addAction(MainWindow::instance()->getRedoAction());
  } else {
    QAction *pUndoAction = pMenu->addAction(tr("Undo"), mpPlainTextEdit, SLOT(undo()));
    pUndoAction->setIcon(QIcon(":/Resources/icons/undo.svg"));
    pUndoAction->setShortcut(QKeySequence::Undo);
    pUndoAction->setEnabled(mpPlainTextEdit->isUndoAvailable());
    QAction *pRedoAction = pMenu->addAction(tr("Redo"), mpPlainTextEdit, SLOT(undo()));
    pRedoAction->setIcon(QIcon(":/Resources/icons/redo.svg"));
    pRedoAction->setShortcut(QKeySequence::Redo);
    pRedoAction->setEnabled(mpPlainTextEdit->isRedoAvailable());
  }
  pMenu->addSeparator();
  /* ticket:4585
   * Since we are not using QPlainTextEdit->createStandardContextMenu()
   * so we need to create cut, copy, paste and select all here
   */
  const bool showTextSelectionActions = mpPlainTextEdit->textInteractionFlags() & (Qt::TextEditable | Qt::TextSelectableByKeyboard | Qt::TextSelectableByMouse);
  QAction *pCutAction = 0;
  QAction *pCopyAction = 0;
  QAction *pPasteAction = 0;
  QAction *pSelectAllAction = 0;
  if (showTextSelectionActions) {
#ifndef QT_NO_CLIPBOARD
    // cut
    if (mpPlainTextEdit->textInteractionFlags() & Qt::TextEditable) {
      pCutAction = pMenu->addAction(tr("Cu&t"), mpPlainTextEdit, SLOT(cut()));
      pCutAction->setEnabled(mpPlainTextEdit->textCursor().hasSelection());
      pCutAction->setObjectName(QStringLiteral("edit-cut"));
      setActionIcon(pCutAction, QStringLiteral("edit-cut"));
      pCutAction->setShortcut(QKeySequence::Cut);
    }
    // copy
    pCopyAction = pMenu->addAction(tr("&Copy"), mpPlainTextEdit, SLOT(copy()));
    pCopyAction->setEnabled(mpPlainTextEdit->textCursor().hasSelection());
    pCopyAction->setObjectName(QStringLiteral("edit-copy"));
    setActionIcon(pCopyAction, QStringLiteral("edit-copy"));
    pCopyAction->setShortcut(QKeySequence::Copy);
    // paste
    if (mpPlainTextEdit->textInteractionFlags() & Qt::TextEditable) {
      pPasteAction = pMenu->addAction(tr("&Paste"), mpPlainTextEdit, SLOT(paste()));
      pPasteAction->setEnabled(mpPlainTextEdit->canPaste());
      pPasteAction->setObjectName(QStringLiteral("edit-paste"));
      setActionIcon(pPasteAction, QStringLiteral("edit-paste"));
      pPasteAction->setShortcut(QKeySequence::Paste);
    }
#endif // QT_NO_CLIPBOARD
    pMenu->addSeparator();
    // select all
    pSelectAllAction = pMenu->addAction(tr("Select All"), mpPlainTextEdit, SLOT(selectAll()));
    pSelectAllAction->setEnabled(!mpPlainTextEdit->document()->isEmpty());
    pSelectAllAction->setObjectName(QStringLiteral("select-all"));
    pSelectAllAction->setShortcut(QKeySequence::SelectAll);
    pMenu->addSeparator();
  }
  // disable the cut & copy buttons based on Access annotation.
  if (mpModelWidget && mpModelWidget->getLibraryTreeItem()
      && ((mpModelWidget->getLibraryTreeItem()->getAccess() <= LibraryTreeItem::nonPackageText)
          || (mpModelWidget->getLibraryTreeItem()->getAccess() == LibraryTreeItem::packageText))) {
    pCutAction->setEnabled(false);
    pCopyAction->setEnabled(false);
  }
  pMenu->addAction(mpFindReplaceAction);
  pMenu->addAction(mpClearFindReplaceTextsAction);
  pMenu->addAction(mpGotoLineNumberAction);
  pMenu->addSeparator();
  pMenu->addAction(mpShowTabsAndSpacesAction);
  pMenu->addSeparator();
  if (!mpModelWidget) {
    pMenu->addAction(mpResetZoomAction);
    pMenu->addAction(mpZoomInAction);
    pMenu->addAction(mpZoomOutAction);
  } else {
    pMenu->addAction(MainWindow::instance()->getResetZoomAction());
    pMenu->addAction(MainWindow::instance()->getZoomInAction());
    pMenu->addAction(MainWindow::instance()->getZoomOutAction());
  }
  return pMenu;
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
  QSettings *pSettings = Utilities::getApplicationSettings();
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
 * \brief BaseEditor::toggleCommentSelection
 * Slot activated when toggle comment selection is seleteted from context menu or ctrl+k is pressed.
 * The implementation and logic is inspired from Qt Creator sources.
 */
void BaseEditor::toggleCommentSelection()
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
  /* ticket:4322 Unfold the block if line is commented out.
   * We only do this for single line comments because the multi line comments are done using selection.
   */
  if (!doMultiLineStyleComment && !doMultiLineStyleUncomment && !doSingleLineStyleUncomment) {
    endBlock = doc->findBlock(end);
    if (BaseEditorDocumentLayout::canFold(endBlock)) {
      BaseEditorDocumentLayout::foldOrUnfold(endBlock, true);
    }
  }
  cursor.endEditBlock();
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
  pMainLayout->setMargin(2);
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
  QSettings *pSettings = Utilities::getApplicationSettings();
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
  QSettings *pSettings = Utilities::getApplicationSettings();
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
  mpBaseEditor->getPlainTextEdit()->goToLineNumber(mpLineNumberTextBox->text().toInt());
  accept();
}

/*!
 * \class InfoBar
 * \brief Used for displaying information messages above the BaseEditor.
 */
/*!
 * \brief InfoBar::InfoBar
 * \param pParent
 */
InfoBar::InfoBar(QWidget *pParent)
  : QFrame(pParent)
{
  QPalette pal = palette();
  pal.setColor(QPalette::Window, QColor(255, 255, 225));
  pal.setColor(QPalette::WindowText, Qt::black);
  setPalette(pal);
  setFrameStyle(QFrame::StyledPanel);
  setAutoFillBackground(true);
  mpInfoLabel = new Label;
  mpInfoLabel->setWordWrap(true);
  mpCloseButton = new QToolButton;
  mpCloseButton->setAutoRaise(true);
  mpCloseButton->setIcon(QIcon(":/Resources/icons/delete.svg"));
  mpCloseButton->setToolTip(Helper::close);
  connect(mpCloseButton, SIGNAL(clicked()), SLOT(hide()));
  // set the layout
  QHBoxLayout *pMainLayout = new QHBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setMargin(2);
  pMainLayout->addWidget(mpInfoLabel);
  pMainLayout->addWidget(mpCloseButton, 0, Qt::AlignTop);
  setLayout(pMainLayout);
}

/*!
 * \brief InfoBar::showMessage
 * Shows the message in the InfoBar.
 * \param message
 */
void InfoBar::showMessage(QString message)
{
  mpInfoLabel->setText(message);
  show();
}
