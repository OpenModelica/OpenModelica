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

#include "MetaModelicaEditor.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Options/OptionsDialog.h"
#include <QCompleter>
#include <QMenu>

MetaModelicaEditor::MetaModelicaEditor(QWidget *pParent)
  : BaseEditor(pParent)
{
  mpPlainTextEdit->setCanHaveBreakpoints(true);
  /* set the document marker */
  mpDocumentMarker = new DocumentMarker(mpPlainTextEdit->document());
  QStringList keywords = MetaModelicaHighlighter::getKeywords();
  mpPlainTextEdit->insertCompleterKeywords(keywords);
  QStringList types = MetaModelicaHighlighter::getTypes();
  mpPlainTextEdit->insertCompleterTypes(types);
  QList<CompleterItem> codesnippets = getCodeSnippets();
  mpPlainTextEdit->insertCompleterCodeSnippets(codesnippets);
}

/*!
 * \brief MetaModelicaEditor::setPlainText
 * Reimplementation of QPlainTextEdit::setPlainText method.
 * Makes sure we dont update if the passed text is same.
 * \param text the string to set.
 */
void MetaModelicaEditor::setPlainText(const QString &text)
{
  if (text != mpPlainTextEdit->toPlainText()) {
    mForceSetPlainText = true;
    mpPlainTextEdit->setPlainText(text);
    mForceSetPlainText = false;
    mpPlainTextEdit->foldAll();
  }
}

/*!
 * \brief MetaModelicaEditor::popUpCompleter()
 * show the popup for keywords and type for autocompletion
 */
void MetaModelicaEditor::popUpCompleter()
{
  QCompleter *completer = mpPlainTextEdit->completer();
  QRect cr = mpPlainTextEdit->cursorRect();
  cr.setWidth(completer->popup()->sizeHintForColumn(0)+ completer->popup()->verticalScrollBar()->sizeHint().width());
  completer->complete(cr);
}

/*!
 * \brief MetaModelicaEditor::getCodeSnippets()
 * returns the list of CompleterItem to the autocompleter
 */

QList<CompleterItem> MetaModelicaEditor::getCodeSnippets()
{
  QList<CompleterItem> codesnippetslist;
  codesnippetslist << CompleterItem("match" ,"match (control)\n  case (condition) then (value);\n  case (condition) then (value);\nend match;", "control")
                   << CompleterItem("matchcontinue" ,"matchcontinue (control)\n  case (condition) then (value);\n  case (condition) then (value);\nend matchcontinue;", "control")
                   << CompleterItem("function" ,"function name\n  \nend name;", "name")
                   << CompleterItem("block" ,"block name\n  \nend name;", "name")
                   << CompleterItem("model" ,"model name\n  \nend name;", "name")
                   << CompleterItem("class" ,"class name\n  \nend name;", "name")
                   << CompleterItem("connector" ,"connector name\n  \nend name;", "name")
                   << CompleterItem("package" ,"package name\n  \nend name;", "name")
                   << CompleterItem("record" ,"record name\n  \nend name;", "name")
                   << CompleterItem("while" ,"while condition loop\n  \nend while;", "condition")
                   << CompleterItem("if" ,"if condition then\n  \nend if;", "condition")
                   << CompleterItem("if" ,"if condition then\n  \nelseif condition then\n  \nelse\n  \nend if;", "condition")
                   << CompleterItem("for" ,"for condition loop\n  \nend for;", "condition")
                   << CompleterItem("when", "when condition then\n  \nend when;", "condition")
                   << CompleterItem("when", "when condition then\n  \nelsewhen condition then\n  \nend when;", "condition");
  return codesnippetslist;
}

/*!
 * \brief MetaModelicaEditor::showContextMenu
 * Create a context menu.
 * \param point
 */
void MetaModelicaEditor::showContextMenu(QPoint point)
{
  QMenu *pMenu = BaseEditor::createStandardContextMenu();
  pMenu->addSeparator();
  pMenu->addAction(mpToggleCommentSelectionAction);
  pMenu->addSeparator();
  pMenu->addAction(mpFoldAllAction);
  pMenu->addAction(mpUnFoldAllAction);
  pMenu->exec(mapToGlobal(point));
  delete pMenu;
}

void MetaModelicaEditor::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  if (mpModelWidget && mpModelWidget->isVisible()) {
    if (charsRemoved == 0 && charsAdded == 0) {
      return;
    }
    /* if user is changing the text. */
    if (!mForceSetPlainText) {
      mpModelWidget->updateModelText();
    }
  }
}

/*!
 * \brief MetaModelicaEditor::toggleCommentSelection
 */
void MetaModelicaEditor::toggleCommentSelection()
{
  BaseEditor::toggleCommentSelection();
}

/*!
  * \class MetaModelicaHighlighter
  * \brief A syntax highlighter for MetaModelicaEditor.
 */
/*!
 * \brief MetaModelicaHighlighter::MetaModelicaHighlighter
 * \param pMetaModelicaEditorPage
 * \param pPlainTextEdit
 */
MetaModelicaHighlighter::MetaModelicaHighlighter(MetaModelicaEditorPage *pMetaModelicaEditorPage, QPlainTextEdit *pPlainTextEdit)
  : QSyntaxHighlighter(pPlainTextEdit->document())
{
  mpMetaModelicaEditorPage = pMetaModelicaEditorPage;
  mpPlainTextEdit = pPlainTextEdit;
  initializeSettings();
}

//! Initialized the syntax highlighter with default values.
void MetaModelicaHighlighter::initializeSettings()
{
  QFont font;
  font.setFamily(mpMetaModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getFontFamilyComboBox()->currentFont().family());
  font.setPointSizeF(mpMetaModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getFontSizeSpinBox()->value());
  mpPlainTextEdit->document()->setDefaultFont(font);
  mpPlainTextEdit->setTabStopWidth(mpMetaModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getTabSizeSpinBox()->value() * QFontMetrics(font).width(QLatin1Char(' ')));
  // set color highlighting
  mHighlightingRules.clear();
  HighlightingRule rule;
  mTextFormat.setForeground(mpMetaModelicaEditorPage->getColor("Text"));
  mKeywordFormat.setForeground(mpMetaModelicaEditorPage->getColor("Keyword"));
  mTypeFormat.setForeground(mpMetaModelicaEditorPage->getColor("Type"));
  mSingleLineCommentFormat.setForeground(mpMetaModelicaEditorPage->getColor("Comment"));
  mMultiLineCommentFormat.setForeground(mpMetaModelicaEditorPage->getColor("Comment"));
  mQuotationFormat.setForeground(mpMetaModelicaEditorPage->getColor("Quotes"));
  // Priority: keyword > func() > ident > number. Yes, the order matters :)
  mNumberFormat.setForeground(mpMetaModelicaEditorPage->getColor("Number"));
  rule.mPattern = QRegExp("[0-9][0-9]*([.][0-9]*)?([eE][+-]?[0-9]*)?");
  rule.mFormat = mNumberFormat;
  mHighlightingRules.append(rule);
  rule.mPattern = QRegExp("\\b[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTextFormat;
  mHighlightingRules.append(rule);
  // keywords
  QStringList keywordPatterns = getKeywords();
  foreach (const QString &pattern, keywordPatterns) {
    QString newPattern = QString("\\b%1\\b").arg(pattern);
    rule.mPattern = QRegExp(newPattern);
    rule.mFormat = mKeywordFormat;
    mHighlightingRules.append(rule);
  }
  // Modelica types
  QStringList typePatterns = getTypes();
  foreach (const QString &pattern, typePatterns) {
    QString newPattern = QString("\\b%1\\b").arg(pattern);
    rule.mPattern = QRegExp(newPattern);
    rule.mFormat = mTypeFormat;
    mHighlightingRules.append(rule);
  }
}
// Function which returns list of keywords for the highlighter
QStringList MetaModelicaHighlighter::getKeywords()
{
  QStringList keywordsList;
  keywordsList << "algorithm"
               << "and"
               << "annotation"
               << "assert"
               << "block"
               << "break"
               << "class"
               << "connect"
               << "connector"
               << "constant"
               << "constrainedby"
               << "der"
               << "discrete"
               << "each"
               << "else"
               << "elseif"
               << "elsewhen"
               << "encapsulated"
               << "end"
               << "enumeration"
               << "equation"
               << "expandable"
               << "extends"
               << "external"
               << "false"
               << "final"
               << "flow"
               << "for"
               << "function"
               << "if"
               << "import"
               << "impure"
               << "in"
               << "initial"
               << "inner"
               << "input"
               << "loop"
               << "model"
               << "not"
               << "operator"
               << "or"
               << "outer"
               << "output"
               << "optimization"
               << "package"
               << "parameter"
               << "partial"
               << "protected"
               << "public"
               << "pure"
               << "record"
               << "redeclare"
               << "replaceable"
               << "return"
               << "stream"
               << "then"
               << "true"
               << "type"
               << "when"
               << "while"
               << "within"
               /* MetaModelica specific keywords */
               << "as"
               << "case"
               << "continue"
               << "equality"
               << "failure"
               << "guard"
               << "local"
               << "match"
               << "matchcontinue"
               << "uniontype"
               << "subtypeof"
               << "try"
               << "parfor"
               << "parallel"
               << "parlocal"
               << "parglobal"
               << "parkernel"
               << "threaded";
  return keywordsList;
}

// Function which returns list of types for the highlighter
QStringList MetaModelicaHighlighter::getTypes()
{
  QStringList typesList;
  typesList  << "String"
             << "Integer"
             << "Boolean"
             << "Real"
             << "Option"
             << "SOME"
             << "NONE"
             << "list"
             << "array";
  return typesList;
}

/*!
 * \brief MetaModelicaHighlighter::highlightMultiLine
 * Highlights the multilines text.
 * Quoted text or multiline comments.
 * \param text
 */
void MetaModelicaHighlighter::highlightMultiLine(const QString &text)
{
  /* Hand-written recognizer beats the crap known as QRegEx ;) */
  int index = 0, startIndex = 0;
  int blockState = previousBlockState();
  int foldingIndent = 0;
  bool foldingEndState = false;
  bool foldingEnd = false;
  bool previousFoldingEnd = false;
  int foldingStartIndex = -1;
  int previousFoldingStartIndex = -1;
  QTextBlock previousTextBlck = currentBlock().previous();
  TextBlockUserData *pPreviousTextBlockUserData = BaseEditorDocumentLayout::userData(previousTextBlck);
  if (pPreviousTextBlockUserData) {
    foldingIndent = pPreviousTextBlockUserData->foldingIndent();
    foldingEndState = pPreviousTextBlockUserData->foldingEndState();
    previousFoldingEnd = pPreviousTextBlockUserData->foldingEnd();
    previousFoldingStartIndex = pPreviousTextBlockUserData->foldingStartIndex();
  }
  // store parentheses info
  Parentheses parentheses;
  TextBlockUserData *pTextBlockUserData = BaseEditorDocumentLayout::userData(currentBlock());
  if (pTextBlockUserData) {
    pTextBlockUserData->clearParentheses();
    pTextBlockUserData->setFoldingIndent(0);
    pTextBlockUserData->setFoldingEndIncluded(false);
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
    if (pTextBlockUserData && (blockState < 1 || blockState > 3 || mpMetaModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox()->isChecked())) {
      if (text[index] == '(' || text[index] == '{' || text[index] == '[') {
        parentheses.append(Parenthesis(Parenthesis::Opened, text[index], index));
      } else if (text[index] == ')' || text[index] == '}' || text[index] == ']') {
        parentheses.append(Parenthesis(Parenthesis::Closed, text[index], index));
      }
    }
    if (pTextBlockUserData) {
      // if no single line comment, no multi line comment and no quotes then check for block start and end
      if (blockState < 1 || blockState > 3) {
        if (!foldingEndState) {
          if (Utilities::containsWord(text, index, "function")) {
            foldingStartIndex = index;
            index = index + QString("function").length();
          } else if (Utilities::containsWord(text, index, "package")) {
            foldingStartIndex = index;
            index = index + QString("package").length();
          } else if (Utilities::containsWord(text, index, "record")) {
            foldingStartIndex = index;
            index = index + QString("record").length();
          } else if (Utilities::containsWord(text, index, "uniontype")) {
            foldingStartIndex = index;
            index = index + QString("uniontype").length();
          } else if (Utilities::containsWord(text, index, "match", true)) {
            foldingStartIndex = index;
            index = index + QString("match").length();
          } else if (Utilities::containsWord(text, index, "matchcontinue", true)) {
            foldingStartIndex = index;
            index = index + QString("matchcontinue").length();
          } else if (Utilities::containsWord(text, index, "for")) {
            foldingStartIndex = index;
            index = index + QString("for").length();
          } else if (Utilities::containsWord(text, index, "while")) {
            foldingStartIndex = index;
            index = index + QString("while").length();
          } else if (Utilities::containsWord(text, index, "if")) {
            foldingStartIndex = index;
            index = index + QString("if").length();
          } else if (Utilities::containsWord(text, index, "try")) {
            foldingStartIndex = index;
            index = index + QString("try").length();
          }
        }
        if (Utilities::containsWord(text, index, "end")) {
          index = index + QString("end").length();
          foldingEndState = true;
        }
        if ((foldingEndState || foldingStartIndex > -1) && (index<text.length() && text[index] == ';')) {
          foldingEndState = false;
          foldingEnd = true;
        }
      }
    }
    index++;
  }
  if (pTextBlockUserData) {
    pTextBlockUserData->setParentheses(parentheses);
    pTextBlockUserData->setFoldingEndState(foldingEndState);
    pTextBlockUserData->setFoldingEnd(foldingEnd);
    pTextBlockUserData->setFoldingStartIndex(foldingStartIndex);
    if (previousFoldingStartIndex < 0) {
      pTextBlockUserData->setFoldingIndent(previousFoldingEnd ? foldingIndent - 1 : foldingIndent);
    } else {
      pTextBlockUserData->setFoldingIndent(previousFoldingEnd ? foldingIndent : foldingIndent + 1);
    }
    // set text block user data
    setCurrentBlockUserData(pTextBlockUserData);
//    qDebug() << text << pTextBlockUserData->foldingIndent() << pTextBlockUserData->foldingEnd() << pTextBlockUserData->foldingStartIndex();
  }

//  int currentState = currentBlockState();
//  if (currentState != -1) {
//    QTextBlock block = currentBlock();
//    QTextBlock nextBlock = block.next();
//    while (nextBlock.isValid()) {
//      TextBlockUserData *pCurrentTextBlockUserData = BaseEditorDocumentLayout::userData(block);
//      TextBlockUserData *pNextTextBlockUserData = BaseEditorDocumentLayout::userData(nextBlock);

//      if (pCurrentTextBlockUserData->foldingStartIndex() < 0) {
//        pNextTextBlockUserData->setFoldingIndent(foldingIndent);
//      } else {
//        pNextTextBlockUserData->setFoldingIndent(foldingIndent + 1);
//      }
//      qDebug() << pCurrentTextBlockUserData->foldingStartIndex() << pNextTextBlockUserData->foldingIndent();
//      block = nextBlock;
//      nextBlock = block.next();
//    }
//  }

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
void MetaModelicaHighlighter::highlightBlock(const QString &text)
{
  setCurrentBlockState(0);
  setFormat(0, text.length(), mTextFormat.foreground().color());
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

/*!
 * \brief MetaModelicaHighlighter::settingsChanged
 * Slot activated whenever ModelicaEditor text settings changes.
 */
void MetaModelicaHighlighter::settingsChanged()
{
  initializeSettings();
  rehighlight();
}
