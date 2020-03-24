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

#include "OMSimulatorEditor.h"
#include "Options/OptionsDialog.h"
#include "Options/NotificationsDialog.h"
#include "Modeling/ModelWidgetContainer.h"

#include <QMessageBox>
#include <QMenu>

OMSimulatorEditor::OMSimulatorEditor(QWidget *pParent)
  : BaseEditor(pParent), mLastValidText(""), mTextChanged(false)
{

}

/*!
 * \brief OMSimulatorEditor::validateText
 * When user make some changes in the OMSimulatorEditor text then this method validates the text.
 * \return
 */
bool OMSimulatorEditor::validateText()
{
  if (mTextChanged) {
    // if the user makes few mistakes in the text then dont let him change the perspective
    if (!mpModelWidget->omsimulatorEditorTextChanged()) {
      QSettings *pSettings = Utilities::getApplicationSettings();
      int answer = -1;
      if (pSettings->contains("textEditor/revertPreviousOrFixErrorsManually")) {
        answer = pSettings->value("textEditor/revertPreviousOrFixErrorsManually").toInt();
      }
      if (answer < 0 || OptionsDialog::instance()->getNotificationsPage()->getAlwaysAskForTextEditorErrorCheckBox()->isChecked()) {
        NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::RevertPreviousOrFixErrorsManually,
                                                                            NotificationsDialog::CriticalIcon,
                                                                            MainWindow::instance());
        pNotificationsDialog->setNotificationLabelString(GUIMessages::getMessage(GUIMessages::ERROR_IN_TEXT).arg("OMSimulator Model")
                                                         .append(GUIMessages::getMessage(GUIMessages::CHECK_MESSAGES_BROWSER))
                                                         .append(GUIMessages::getMessage(GUIMessages::REVERT_PREVIOUS_OR_FIX_ERRORS_MANUALLY)));
        pNotificationsDialog->getOkButton()->setText(Helper::revertToLastCorrectVersion);
        pNotificationsDialog->getOkButton()->setAutoDefault(false);
        pNotificationsDialog->getCancelButton()->setText(Helper::fixErrorsManually);
        pNotificationsDialog->getCancelButton()->setAutoDefault(true);
        pNotificationsDialog->getButtonBox()->removeButton(pNotificationsDialog->getOkButton());
        pNotificationsDialog->getButtonBox()->removeButton(pNotificationsDialog->getCancelButton());
        pNotificationsDialog->getButtonBox()->addButton(pNotificationsDialog->getCancelButton(), QDialogButtonBox::ActionRole);
        pNotificationsDialog->getButtonBox()->addButton(pNotificationsDialog->getOkButton(), QDialogButtonBox::ActionRole);
        // we set focus to this widget here so when the error dialog is closed Qt gives back the focus to this widget.
        mpPlainTextEdit->setFocus(Qt::ActiveWindowFocusReason);
        answer = pNotificationsDialog->exec();
      }
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
 * \brief OMSCompositeModelEditor::popUpCompleter()
 * \we do not have completer for this
 */
void OMSimulatorEditor::popUpCompleter()
{

}

/*!
 * \brief OMSimulatorEditor::showContextMenu
 * Create a context menu.
 * \param point
 */
void OMSimulatorEditor::showContextMenu(QPoint point)
{
  QMenu *pMenu = createStandardContextMenu();
  pMenu->exec(mapToGlobal(point));
  delete pMenu;
}

/*!
 * \brief OMSimulatorEditor::contentsHasChanged
 * Slot activated when OMSimulatorEditor's QTextDocument contentsChanged SIGNAL is raised.\n
 * Sets the model as modified so that user knows that his current model is not saved.
 * \param position
 * \param charsRemoved
 * \param charsAdded
 */
void OMSimulatorEditor::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  if (mpModelWidget->isVisible()) {
    if (charsRemoved == 0 && charsAdded == 0) {
      return;
    }
    /* if user is changing the read only file. */
    if (mpModelWidget->getLibraryTreeItem()->isReadOnly() && !mForceSetPlainText) {
      /* if user is changing the read-only class. */
      mpInfoBar->showMessage(tr("<b>Warning: </b>You are changing a read-only class."));
    } else {
      /* if user is changing, the normal file. */
      if (!mForceSetPlainText) {
        mpModelWidget->setWindowTitle(QString(mpModelWidget->getLibraryTreeItem()->getName()).append("*"));
        mpModelWidget->getLibraryTreeItem()->setIsSaved(false);
        MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->updateLibraryTreeItem(mpModelWidget->getLibraryTreeItem());
        mTextChanged = true;
      }
    }
  }
}

/*!
 * \brief OMSimulatorEditor::setPlainText
 * Reimplementation of QPlainTextEdit::setPlainText method.
 * Makes sure we dont update if the passed text is same.
 * \param text the string to set.
 * \param useInserText
 */
void OMSimulatorEditor::setPlainText(const QString &text, bool useInserText)
{
  if (text != mpPlainTextEdit->toPlainText()) {
    mForceSetPlainText = true;
    if (!useInserText) {
      mpPlainTextEdit->setPlainText(text);
    } else {
      QTextCursor textCursor (mpPlainTextEdit->document());
      textCursor.beginEditBlock();
      textCursor.select(QTextCursor::Document);
      textCursor.insertText(text);
      textCursor.endEditBlock();
      mpPlainTextEdit->setTextCursor(textCursor);
    }
    mForceSetPlainText = false;
    mLastValidText = text;
  }
}

/*!
 * \class OMSimulatorHighlighter
 * \brief A syntax highlighter for OMSimulatorEditor.
 */
/*!
 * \brief OMSimulatorHighlighter::OMSimulatorHighlighter
 * \param pOMSimulatorEditorPage
 * \param pPlainTextEdit
 */
OMSimulatorHighlighter::OMSimulatorHighlighter(OMSimulatorEditorPage *pOMSimulatorEditorPage, QPlainTextEdit *pPlainTextEdit)
  : QSyntaxHighlighter(pPlainTextEdit->document())
{
  mpOMSimulatorEditorPage = pOMSimulatorEditorPage;
  mpPlainTextEdit = pPlainTextEdit;
  initializeSettings();
}

/*!
 * \brief OMSimulatorHighlighter::initializeSettings
 * Initialized the syntax highlighter with default values.
 */
void OMSimulatorHighlighter::initializeSettings()
{
  QFont font;
  font.setFamily(mpOMSimulatorEditorPage->getOptionsDialog()->getTextEditorPage()->getFontFamilyComboBox()->currentFont().family());
  font.setPointSizeF(mpOMSimulatorEditorPage->getOptionsDialog()->getTextEditorPage()->getFontSizeSpinBox()->value());
  mpPlainTextEdit->document()->setDefaultFont(font);
  mpPlainTextEdit->setTabStopWidth(mpOMSimulatorEditorPage->getOptionsDialog()->getTextEditorPage()->getTabSizeSpinBox()->value() * QFontMetrics(font).width(QLatin1Char(' ')));
  // set color highlighting
  mHighlightingRules.clear();
  HighlightingRule rule;
  mTextFormat.setForeground(mpOMSimulatorEditorPage->getColor("Text"));
  mTagFormat.setForeground(mpOMSimulatorEditorPage->getColor("Tag"));
  mElementFormat.setForeground(mpOMSimulatorEditorPage->getColor("Element"));
  mCommentFormat.setForeground(mpOMSimulatorEditorPage->getColor("Comment"));
  mQuotationFormat.setForeground(QColor(mpOMSimulatorEditorPage->getColor("Quotes")));

  rule.mPattern = QRegExp("\\b[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTextFormat;
  mHighlightingRules.append(rule);

  // CompositeModel Tags
  QStringList compositeModelTags;
  compositeModelTags << "<\\?"
                << "<"
                << "</"
                << "\\?>"
                << ">"
                << "/>";
  foreach (const QString &compositeModelTag, compositeModelTags) {
    rule.mPattern = QRegExp(compositeModelTag);
    rule.mFormat = mTagFormat;
    mHighlightingRules.append(rule);
  }

  // CompositeModel Elements
  QStringList elementPatterns;
  elementPatterns << "\\bxml\\b"
                  << "\\bssd:SystemStructureDescription\\b"
                  << "\\bssd:System\\b"
                  << "\\bssd:SimulationInformation\\b"
                  << "\\bssd:Annotations\\b"
                  << "\\bssd:Annotation\\b"
                  << "\\boms:TlmMaster\\b"
                  << "\\bssd:Elements\\b"
                  << "\\boms:Bus\\b"
                  << "\\boms:Signals\\b"
                  << "\\boms:Signal\\b"
                  << "\\bssd:Component\\b"
                  << "\\bssd:ElementGeometry\\b"
                  << "\\bssd:Connectors\\b"
                  << "\\bssd:Connector\\b"
                  << "\\bssd:ConnectorGeometry\\b"
                  << "\\bParameter\\b"
                  << "\\bssd:Connections\\b"
                  << "\\boms:Connections\\b"
                  << "\\bssd:Connection\\b"
                  << "\\boms:Connection\\b"
                  << "\\bssd:ConnectionGeometry\\b"
                  << "\\bssd:DefaultExperiment\\b";
  foreach (const QString &elementPattern, elementPatterns)
  {
    rule.mPattern = QRegExp(elementPattern);
    rule.mFormat = mElementFormat;
    mHighlightingRules.append(rule);
  }

  // CompositeModel Comments
  mCommentStartExpression = QRegExp("<!--");
  mCommentEndExpression = QRegExp("-->");
}

/*!
 * \brief OMSimulatorHighlighter::highlightMultiLine
 * Highlights the multilines text.\n
 * Quoted text.
 * \param text
 */
void OMSimulatorHighlighter::highlightMultiLine(const QString &text)
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
 * \brief OMSimulatorHighlighter::highlightBlock
 * Reimplementation of QSyntaxHighlighter::highlightBlock
 * \param text
 */
void OMSimulatorHighlighter::highlightBlock(const QString &text)
{
  /* Only highlight the text if user has enabled the syntax highlighting */
  if (!mpOMSimulatorEditorPage->getOptionsDialog()->getTextEditorPage()->getSyntaxHighlightingGroupBox()->isChecked()) {
    return;
  }
  // set text block state
  setCurrentBlockState(0);
  setFormat(0, text.length(), mpOMSimulatorEditorPage->getColor("Text"));
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
 * \brief OMSimulatorHighlighter::settingsChanged
 * Slot activated whenever editor settings changes.
 */
void OMSimulatorHighlighter::settingsChanged()
{
  initializeSettings();
  rehighlight();
}
