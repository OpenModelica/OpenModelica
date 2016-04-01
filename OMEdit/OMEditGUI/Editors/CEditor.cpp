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

#include "CEditor.h"

CEditor::CEditor(MainWindow *pMainWindow)
  : BaseEditor(pMainWindow)
{
  QFont font;
  font.setFamily(pMainWindow->getOptionsDialog()->getTextEditorPage()->getFontFamilyComboBox()->currentFont().family());
  font.setPointSizeF(pMainWindow->getOptionsDialog()->getTextEditorPage()->getFontSizeSpinBox()->value());
  mpPlainTextEdit->document()->setDefaultFont(font);
  mpPlainTextEdit->setTabStopWidth(pMainWindow->getOptionsDialog()->getTextEditorPage()->getTabSizeSpinBox()->value() * QFontMetrics(font).width(QLatin1Char(' ')));
}

/*!
 * \brief CEditor::showContextMenu
 * Create a context menu.
 * \param point
 */
void CEditor::showContextMenu(QPoint point)
{
  QMenu *pMenu = BaseEditor::createStandardContextMenu();
  pMenu->exec(mapToGlobal(point));
  delete pMenu;
}

/*!
  * \class CHighlighter
  *  \brief A syntax highlighter for CEditor.
 */
/*!
 * \brief CHighlighter::CHighlighter
 * \param pTextDocument
 */
CHighlighter::CHighlighter(QPlainTextEdit *pPlainTextEdit)
  : QSyntaxHighlighter(pPlainTextEdit->document())
{
  mpPlainTextEdit = pPlainTextEdit;
  initializeSettings();
}

//! Initialized the syntax highlighter with default values.
void CHighlighter::initializeSettings()
{
  QFont font;
  font.setFamily(Helper::monospacedFontInfo.family());
  mpPlainTextEdit->document()->setDefaultFont(font);
  mpPlainTextEdit->setTabStopWidth(4 * QFontMetrics(font).width(QLatin1Char(' ')));
  // set color highlighting
  mHighlightingRules.clear();
  HighlightingRule rule;
  mTextFormat.setForeground(QColor(0, 0, 0));
  mKeywordFormat.setForeground(QColor(139, 0, 0));
  mTypeFormat.setForeground(QColor(255, 10, 10));
  mSingleLineCommentFormat.setForeground(QColor(0, 150, 0));
  mMultiLineCommentFormat.setForeground(QColor(0, 150, 0));
  mFunctionFormat.setForeground(QColor(0, 0, 255));
  mQuotationFormat.setForeground(QColor(0, 139, 0));
  // Priority: keyword > func() > ident > number. Yes, the order matters :)
  mNumberFormat.setForeground(QColor(139, 0, 139));
  rule.mPattern = QRegExp("[0-9][0-9]*([.][0-9]*)?([eE][+-]?[0-9]*)?");
  rule.mFormat = mNumberFormat;
  mHighlightingRules.append(rule);
  rule.mPattern = QRegExp("\\b[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTextFormat;
  mHighlightingRules.append(rule);
  // keywords
  QStringList keywordPatterns;
  keywordPatterns << "\\bauto\\b"
                  << "\\bbreak\\b"
                  << "\\bcase\\b"
                  << "\\bconst\\b"
                  << "\\bcontinue\\b"
                  << "\\bdefault\\b"
                  << "\\bdo\\b"
                  << "\\belse\\b"
                  << "\\benum\\b"
                  << "\\bextern\\b"
                  << "\\bfor\\b"
                  << "\\bgoto\\b"
                  << "\\bif\\b"
                  << "\\blong\\b"
                  << "\\bregister\\b"
                  << "\\breturn\\b"
                  << "\\bshort\\b"
                  << "\\bsigned\\b"
                  << "\\bsizeof\\b"
                  << "\\bstatic\\b"
                  << "\\bclass\\b"
                  << "\\bstruct\\b"
                  << "\\bswitch\\b"
                  << "\\btypedef\\b"
                  << "\\bunion\\b"
                  << "\\bunsigned\\b"
                  << "\\bvoid\\b"
                  << "\\bvolatile\\b"
                  << "\\bwhile\\b";
  foreach (const QString &pattern, keywordPatterns)
  {
    rule.mPattern = QRegExp(pattern);
    rule.mFormat = mKeywordFormat;
    mHighlightingRules.append(rule);
  }
  // Modelica types
  QStringList typePatterns;
  typePatterns << "\\bchar\\b"
               << "\\bdouble\\b"
               << "\\bint\\b"
               << "\\bdouble\\b"
               << "\\bfloat\\b";
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

//! Highlights the multilines text.
//! Quoted text or multiline comments.
void CHighlighter::highlightMultiLine(const QString &text)
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
void CHighlighter::highlightBlock(const QString &text)
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
