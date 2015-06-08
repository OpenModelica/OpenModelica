
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

TLMEditor::TLMEditor(ModelWidget *pModelWidget)
  : BaseEditor(pModelWidget), mTextChanged(false)
{
  connect(this, SIGNAL(focusOut()), mpModelWidget, SLOT(TLMEditorTextChanged()));
}

/*!
 * \brief TLMEditor::showContextMenu
 * Create a context menu.
 * \param point
 */
void TLMEditor::showContextMenu(QPoint point)
{
  QMenu *pMenu = createStandardContextMenu();
  pMenu->exec(mapToGlobal(point));
  delete pMenu;
}

//! Slot activated when TLMEdit's QTextDocument contentsChanged SIGNAL is raised.
//! Sets the model as modified so that user knows that his current TLM is not saved.
void TLMEditor::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  if (mpModelWidget->isVisible()) {
    if (charsRemoved == 0 && charsAdded == 0) {
      return;
    }
    /* if user is changing the text. */
    if (!mForceSetPlainText) {
      mpModelWidget->setModelModified();
      mTextChanged = true;
    }
  }
}

bool TLMEditor::validateMetaModelText()
{
   if (mTextChanged) {
      emit focusOut();
   }
  return true;
}

/*!
 * \brief TLMEditor::setPlainText
 * Reimplementation of QPlainTextEdit::setPlainText method.
 * Makes sure we dont update if the passed text is same.
 * \param text the string to set.
 */
void TLMEditor::setPlainText(const QString &text)
{
  if (text != mpPlainTextEdit->toPlainText()) {
    mForceSetPlainText = true;
    mpPlainTextEdit->setPlainText(text);
    mForceSetPlainText = false;
  }
}

//! @class TLMHighlighter
//! @brief A syntax highlighter for TLMEditor.

//! Constructor
TLMHighlighter::TLMHighlighter(TLMEditorPage *pTLMEditorPage, QPlainTextEdit *pPlainTextEdit)
    : QSyntaxHighlighter(pPlainTextEdit->document())
{
  mpTLMEditorPage = pTLMEditorPage;
  mpPlainTextEdit = pPlainTextEdit;
  initializeSettings();
}

//! Initialized the syntax highlighter with default values.
void TLMHighlighter::initializeSettings()
{
  QFont font;
  font.setFamily(mpTLMEditorPage->getFontFamilyComboBox()->currentFont().family());
  font.setPointSizeF(mpTLMEditorPage->getFontSizeSpinBox()->value());
  mpPlainTextEdit->document()->setDefaultFont(font);
  mpPlainTextEdit->setTabStopWidth(mpTLMEditorPage->getTabSizeSpinBox()->value() * QFontMetrics(font).width(QLatin1Char(' ')));
  // set color highlighting
  mHighlightingRules.clear();
  HighlightingRule rule;
  mTextFormat.setForeground(mpTLMEditorPage->getTextRuleColor());
  mTagFormat.setForeground(mpTLMEditorPage->getTagRuleColor());
  mElementFormat.setForeground(mpTLMEditorPage->getElementRuleColor());
  mCommentFormat.setForeground(mpTLMEditorPage->getCommentRuleColor());
  mQuotationFormat.setForeground(QColor(mpTLMEditorPage->getQuotesRuleColor()));

  rule.mPattern = QRegExp("\\b[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTextFormat;
  mHighlightingRules.append(rule);

 // TLM Tags
  QStringList TLMTags;
  TLMTags << "<\\?"
          << "<"
          << "</"
          << "\\?>"
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
  elementPatterns << "\\bxml\\b"
                  << "\\bModel\\b"
                  << "\\bAnnotations\\b"
                  << "\\bAnnotation\\b"
                  << "\\bSubModels\\b"
                  << "\\bSubModel\\b"
                  << "\\bInterfacePoint\\b"
                  << "\\bConnections\\b"
                  << "\\bConnection\\b"
                  << "\\bLines\\b"
                  << "\\bLine\\b"
                  << "\\bSimulationParams\\b";
  foreach (const QString &elementPattern, elementPatterns)
  {
    rule.mPattern = QRegExp(elementPattern);
    rule.mFormat = mElementFormat;
    mHighlightingRules.append(rule);
  }

  // TLM Comments
  mCommentStartExpression = QRegExp("<!--");
  mCommentEndExpression = QRegExp("-->");
}

/*!
  Highlights the multilines text.\n
  Quoted text.
  */
void TLMHighlighter::highlightMultiLine(const QString &text)
{
  int index = 0, startIndex = 0;
  int blockState = previousBlockState();
  // fprintf(stderr, "%s with blockState %d\n", text.toStdString().c_str(), blockState);

  while (index < text.length())
  {
    switch (blockState) {
      case 2:
        if (text[index] == '-' &&
            index+1<text.length() && text[index+1] == '-' &&
            index+2<text.length() && text[index+2] == '>') {
          index = index+2;
          setFormat(startIndex, index-startIndex+1, mCommentFormat);
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
        if (text[index] == '<' &&
            index+1<text.length() && text[index+1] == '!' &&
            index+2<text.length() && text[index+2] == '-' &&
            index+3<text.length() && text[index+3] == '-') {
          startIndex = index;
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
      setFormat(startIndex, text.length()-startIndex, mCommentFormat);
      setCurrentBlockState(2);
      break;
    case 3:
      setFormat(startIndex, text.length()-startIndex, mQuotationFormat);
      setCurrentBlockState(3);
      break;
  }
}

//! Reimplementation of QSyntaxHighlighter::highlightBlock
void TLMHighlighter::highlightBlock(const QString &text)
{
  /* Only highlight the text if user has enabled the syntax highlighting */
  if (!mpTLMEditorPage->getSyntaxHighlightingCheckbox()->isChecked()) {
    return;
  }
  setCurrentBlockState(0);
  setFormat(0, text.length(), mpTLMEditorPage->getTextRuleColor());
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
void TLMHighlighter::settingsChanged()
{
  initializeSettings();
  rehighlight();
}

