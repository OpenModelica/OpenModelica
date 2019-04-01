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

//QT Headers
#include <QtCore/QFile>
#include <QtGui/QTextBlock>
#include <QtGui/QTextDocument>
#include <QtGui/QTextLayout>
#include <QtXml/QDomDocument>
#include <QMessageBox>

// IAEX Headers
#include "ModelicaTextHighlighter.h"

namespace IAEX
{
  ModelicaTextHighlighter::ModelicaTextHighlighter(QTextDocument *pTextDocument)
    : QSyntaxHighlighter(pTextDocument)
  {
    initializeSettings();
  }

  //! Initialized the syntax highlighter with default values.
  void ModelicaTextHighlighter::initializeSettings()
  {
    mHighlightingRules.clear();
    // set color highlighting
    mTextFormat.setForeground(QColor(0, 0, 0)); // black
    mKeywordFormat.setForeground(QColor(180, 0, 0)); // dark red
    mTypeFormat.setForeground(QColor(255, 10, 10)); // red
    mSingleLineCommentFormat.setForeground(QColor(0, 120, 0)); // green
    mMultiLineCommentFormat.setForeground(QColor(0, 120, 0)); // green
    mFunctionFormat.setForeground(QColor(180, 0, 0)); // dark red
    mQuotationFormat.setForeground(QColor(120, 120, 120)); // gray
    mNumberFormat.setForeground(QColor(139, 0, 139)); // purple

    HighlightingRule rule;
    rule.mPattern = QRegExp("[0-9][0-9]*([.][0-9]*)?([eE][+-]?[0-9]*)?");
    rule.mFormat = mNumberFormat;
    mHighlightingRules.append(rule);
    rule.mPattern = QRegExp("\\b[A-Za-z_][A-Za-z0-9_]*");
    rule.mFormat = mTextFormat;
    mHighlightingRules.append(rule);
    // functions
    rule.mPattern = QRegExp("\\b[A-Za-z0-9_]+(?=\\()");
    rule.mFormat = mFunctionFormat;
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
    foreach (const QString &pattern, keywordPatterns) {
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
    foreach (const QString &pattern, typePatterns) {
      rule.mPattern = QRegExp(pattern);
      rule.mFormat = mTypeFormat;
      mHighlightingRules.append(rule);
    }
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
    // set text block state
    setCurrentBlockState(0);
    setFormat(0, text.length(), mTextFormat);
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
}
