
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

#include "TLMEditor.h"


TLMEditor::TLMEditor(ModelWidget *pParent)
  : BaseEditor(pParent)
{
  OptionsDialog *pOptionsDialog = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getOptionsDialog();
  connect(pOptionsDialog, SIGNAL(updateLineWrapping()), SLOT(setLineWrapping()));
  connect(this, SIGNAL(cursorPositionChanged()), this, SLOT(updateCursorPosition()));
  updateCursorPosition();
}

void TLMEditor::setLineWrapping()
{
  OptionsDialog *pOptionsDialog = mpModelWidget->getModelWidgetContainer()->getMainWindow()->getOptionsDialog();
  if (pOptionsDialog->getModelicaTextEditorPage()->getLineWrappingCheckbox()->isChecked())
    setLineWrapMode(QPlainTextEdit::WidgetWidth);
  else
    setLineWrapMode(QPlainTextEdit::NoWrap);
}

//! @class TLMHighlighter
//! @brief A syntax highlighter for TLMEditor.

//! Constructor
TLMHighlighter::TLMHighlighter(ModelicaTextSettings *pSettings, MainWindow *pMainWindow, QTextDocument *pParent)
  : QSyntaxHighlighter(pParent)
{
  mpModelicaTextSettings = pSettings;
  mpMainWindow = pMainWindow;
  initializeSettings();
}

//! Initialized the syntax highlighter with default values.
void TLMHighlighter::initializeSettings()
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
  mTagFormat.setForeground(mpModelicaTextSettings->getTLMTagRuleColor());
  mElementFormat.setForeground(mpModelicaTextSettings->getTLMElementRuleColor());
  mSingleLineCommentFormat.setForeground(mpModelicaTextSettings->getCommentRuleColor());
  mMultiLineCommentFormat.setForeground(mpModelicaTextSettings->getCommentRuleColor());
  mQuotationFormat.setForeground(QColor(mpModelicaTextSettings->getTLMQuotesRuleColor()));

 // TLM Tags
  QStringList TLMTags;
  TLMTags << "<"
          << "</"
          << ">"
          << "/>";
  foreach (const QString &TLMTag, TLMTags)
  {
    rule.mPattern = QRegExp(TLMTag);
    rule.mFormat = mTagFormat;
    mHighlightingRules.append(rule);
  }

 // TLM Elements
  QStringList elementPatterns;
  elementPatterns << "\\bModel\\b"
                  << "\\bSubModels\\b"
                  << "\\bSubModel\\b"
                  << "\\bConnections\\b"
                  << "\\bConnection\\b"
                  << "\\bInterfacePoint\\b"
                  << "\\bSimulationParams\\b";
  foreach (const QString &elementPattern, elementPatterns)
  {
    rule.mPattern = QRegExp(elementPattern);
    rule.mFormat = mElementFormat;
    mHighlightingRules.append(rule);
  }

  // Quoted Text
  rule.mPattern = QRegExp("(\".*\"|\'.*\')");
  rule.mFormat = mQuotationFormat;
  mHighlightingRules.append(rule);

  // TLM Comments
  mCommentStartExpression = QRegExp("<!--");
  mCommentEndExpression = QRegExp("-->");
}

//! Reimplementation of QSyntaxHighlighter::highlightBlock
void TLMHighlighter::highlightBlock(const QString &text)
{
  // singleline matches
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

  /* multiline matches
  * block-state:
  * 0 = comment-block-start-or-end, 1 = comment-block-not-end
  */
  setCurrentBlockState(0);

  int startIndex = 0;
  if (previousBlockState() != 1)
    startIndex = mCommentStartExpression.indexIn(text);

  while (startIndex >= 0)
  {
    int endIndex = mCommentEndExpression.indexIn(text, startIndex);
    int commentLength;
    if (endIndex == -1)
    {
      setCurrentBlockState(1);
      commentLength = text.length() - startIndex;
    }
    else
    {
      commentLength = endIndex - startIndex + mCommentEndExpression.matchedLength();
    }
    setFormat(startIndex, commentLength, mMultiLineCommentFormat);
    startIndex = mCommentStartExpression.indexIn(text, startIndex + commentLength);
  }
}

//! Slot activated whenever ModelicaEditor text settings changes.
void TLMHighlighter::settingsChanged()
{
  initializeSettings();
  rehighlight();
}

