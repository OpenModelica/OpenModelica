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

#include "HTMLEditor.h"
#include "Options/OptionsDialog.h"

#include <QMenu>

/*!
 * \class HTMLEditor
 * \brief An editor for HTML Text.
 */
/*!
 * \brief HTMLEditor::HTMLEditor
 * \param pParent
 */
HTMLEditor::HTMLEditor(QWidget *pParent)
  : BaseEditor(pParent)
{

}

/*!
 * \brief HTMLEditor::popUpCompleter()
 * \we do not have completer for this
 */
void HTMLEditor::popUpCompleter()
{

}

/*!
 * \brief HTMLEditor::showContextMenu
 * Create a context menu.
 * \param point
 */
void HTMLEditor::showContextMenu(QPoint point)
{
  QMenu *pMenu = BaseEditor::createStandardContextMenu();
  pMenu->exec(mapToGlobal(point));
  delete pMenu;
}

void HTMLEditor::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  Q_UNUSED(charsRemoved);
  Q_UNUSED(charsAdded);
}

/*!
  * \class HTMLHighlighter
  * \brief A syntax highlighter for HTMLEditor.
 */
/*!
 * \brief HTMLHighlighter::HTMLHighlighter
 * \param pCompositeModelEditorPage
 * \param pPlainTextEdit
 */
HTMLHighlighter::HTMLHighlighter(HTMLEditorPage *pHTMLEditorPage, QPlainTextEdit *pPlainTextEdit)
    : QSyntaxHighlighter(pPlainTextEdit->document())
{
  mpHTMLEditorPage = pHTMLEditorPage;
  mpPlainTextEdit = pPlainTextEdit;
  initializeSettings();
}

/*!
 * \brief HTMLHighlighter::initializeSettings
 * Initialized the syntax highlighter with default values.
 */
void HTMLHighlighter::initializeSettings()
{
  QFont font;
  font.setFamily(mpHTMLEditorPage->getOptionsDialog()->getTextEditorPage()->getFontFamilyComboBox()->currentFont().family());
  font.setPointSizeF(mpHTMLEditorPage->getOptionsDialog()->getTextEditorPage()->getFontSizeSpinBox()->value());
  mpPlainTextEdit->document()->setDefaultFont(font);
  mpPlainTextEdit->setTabStopWidth(mpHTMLEditorPage->getOptionsDialog()->getTextEditorPage()->getTabSizeSpinBox()->value() * QFontMetrics(font).width(QLatin1Char(' ')));
  // set color highlighting
  mHighlightingRules.clear();
  HighlightingRule rule;
  mTextFormat.setForeground(mpHTMLEditorPage->getColor("Text"));
  mTagFormat.setForeground(mpHTMLEditorPage->getColor("Tag"));
  mCommentFormat.setForeground(mpHTMLEditorPage->getColor("Comment"));
  mQuotationFormat.setForeground(QColor(mpHTMLEditorPage->getColor("Quotes")));

  rule.mPattern = QRegExp("\\b[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTextFormat;
  mHighlightingRules.append(rule);
  // start tag
  rule.mPattern = QRegExp("<[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTagFormat;
  mHighlightingRules.append(rule);
  // end tag
  rule.mPattern = QRegExp("<\\/[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTagFormat;
  mHighlightingRules.append(rule);

  QStringList closingTags;
  closingTags << ">" << "/>";
  foreach (const QString &closingTag, closingTags) {
    rule.mPattern = QRegExp(closingTag);
    rule.mFormat = mTagFormat;
    mHighlightingRules.append(rule);
  }
  // Comments
  mCommentStartExpression = QRegExp("<!--");
  mCommentEndExpression = QRegExp("-->");
}

/*!
 * \brief HTMLHighlighter::highlightMultiLine
 * Highlights the multilines text.\n
 * Quoted text.
 * \param text
 */
void HTMLHighlighter::highlightMultiLine(const QString &text)
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

/*!
 * \brief HTMLHighlighter::highlightBlock
 * Reimplementation of QSyntaxHighlighter::highlightBlock
 * \param text
 */
void HTMLHighlighter::highlightBlock(const QString &text)
{
  /* Only highlight the text if user has enabled the syntax highlighting */
  if (!mpHTMLEditorPage->getOptionsDialog()->getTextEditorPage()->getSyntaxHighlightingGroupBox()->isChecked()) {
    return;
  }
  // set text block state
  setCurrentBlockState(0);
  setFormat(0, text.length(), mpHTMLEditorPage->getColor("Text"));
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
 * \brief HTMLHighlighter::settingsChanged
 * Slot activated whenever HTMLEditor text settings changes.
 */
void HTMLHighlighter::settingsChanged()
{
  initializeSettings();
  rehighlight();
}
