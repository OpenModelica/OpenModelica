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
 * RCS: $Id$
 *
 */

#include "FindReplaceDialog.h"
#include "Helper.h"

FindReplaceDialog::FindReplaceDialog(QWidget *pParent)
  : QDialog(pParent, Qt::WindowTitleHint)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Find/Replace")));
  // Find Label and text box
  mpFindLabel = new Label(tr("Find:"));
  mpFindComboBox = new QComboBox;
  mpFindComboBox->setEditable(true);
  connect(mpFindComboBox, SIGNAL(editTextChanged(QString)), this, SLOT(textToFindChanged()));
  connect(mpFindComboBox, SIGNAL(editTextChanged(QString)), this, SLOT(validateRegularExpression(QString)));
  /* Since the default QCompleter for QComboBox is case insenstive. */
  QCompleter *pFindComboBoxCompleter = mpFindComboBox->completer();
  pFindComboBoxCompleter->setCaseSensitivity(Qt::CaseSensitive);
  mpFindComboBox->setCompleter(pFindComboBoxCompleter);
  // Find replace and text box
  mpReplaceWithLabel = new Label(tr("Replace With:"));
  mpReplaceWithTextBox = new QLineEdit;
  // Find Direction
  mpDirectionGroupBox = new QGroupBox(tr("Direction"));
  mpForwardRadioButton = new QRadioButton(tr("Forward"));
  mpForwardRadioButton->setChecked(true);
  mpBackwardRadioButton = new QRadioButton(tr("Backward"));
  // Find Options
  mpOptionsBox = new QGroupBox(tr("Options"));
  mpCaseSensitiveCheckBox = new QCheckBox(tr("Case Sensitive"));
  mpWholeWordCheckBox = new QCheckBox(tr("Whole Words"));
  mpRegularExpressionCheckBox = new QCheckBox(tr("Regular Expressions"));
  // Buttons
  mpFindButton = new QPushButton(tr("Find"));
  connect(mpFindButton, SIGNAL(clicked()), this, SLOT(find()));
  mpReplaceButton = new QPushButton(tr("Replace"));
  connect(mpReplaceButton, SIGNAL(clicked()), this, SLOT(replace()));
  mpReplaceAllButton = new QPushButton(tr("Replace All"));
  connect(mpReplaceAllButton, SIGNAL(clicked()), this, SLOT(replaceAll()));
  mpCloseButton = new QPushButton(Helper::close);
  connect(mpCloseButton, SIGNAL(clicked()), this, SLOT(close()));
  updateButtons();
  // set the layouts
  // set the directions layout
  QVBoxLayout *pDirectionVerticalLayout = new QVBoxLayout;
  pDirectionVerticalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pDirectionVerticalLayout->addWidget(mpForwardRadioButton);
  pDirectionVerticalLayout->addWidget(mpBackwardRadioButton);
  mpDirectionGroupBox->setLayout(pDirectionVerticalLayout);
  // set the options layput
  QVBoxLayout *pOptionsVerticalLayout = new QVBoxLayout;
  pOptionsVerticalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pOptionsVerticalLayout->addWidget(mpCaseSensitiveCheckBox);
  pOptionsVerticalLayout->addWidget(mpWholeWordCheckBox);
  pOptionsVerticalLayout->addWidget(mpRegularExpressionCheckBox);
  mpOptionsBox->setLayout(pOptionsVerticalLayout);
  // set horizontal layout for directions and options
  QHBoxLayout *pDirectionsOptionsHorizontalLayout = new QHBoxLayout;
  pDirectionsOptionsHorizontalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pDirectionsOptionsHorizontalLayout->addWidget(mpDirectionGroupBox);
  pDirectionsOptionsHorizontalLayout->addWidget(mpOptionsBox);
  // set buttons layout
  QGridLayout *pButtonsGridLayout = new QGridLayout;
  pButtonsGridLayout->addWidget(mpFindButton);
  pButtonsGridLayout->addWidget(mpReplaceButton);
  pButtonsGridLayout->addWidget(mpReplaceAllButton);
  pButtonsGridLayout->addWidget(mpCloseButton);
  // set main layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainGridLayout->addWidget(mpFindLabel, 0, 0);
  pMainGridLayout->addWidget(mpFindComboBox, 0, 1);
  pMainGridLayout->addWidget(mpReplaceWithLabel, 1, 0);
  pMainGridLayout->addWidget(mpReplaceWithTextBox, 1, 1);
  pMainGridLayout->addLayout(pDirectionsOptionsHorizontalLayout, 2, 0, 3, 2);
  pMainGridLayout->addLayout(pButtonsGridLayout, 0, 2, 4, 2, Qt::AlignRight);
  setLayout(pMainGridLayout);
}

void FindReplaceDialog::show()
{
  QTextCursor currentTextCursor = mpBaseEditor->textCursor();
  if (currentTextCursor.hasSelection())
  {
    QString selectedText = currentTextCursor.selectedText();
    saveFindTextToSettings(selectedText);
    readFindTextFromSettings();
  }
  else
  {
    readFindTextFromSettings();
  }
  mpFindComboBox->lineEdit()->selectAll();
  setVisible(true);
}

/*!
  Associates the text editor where to perform the search
  \param ModelicaTextEdit - pointer to ModelicaTextEdit
  */
void FindReplaceDialog::setTextEdit(BaseEditor *pBaseEditor)
{
  mpBaseEditor = pBaseEditor;
}

/*!
  Reads the list of find texts from the settings file.
  */
void FindReplaceDialog::readFindTextFromSettings()
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  settings.setIniCodec(Helper::utf8.toStdString().data());
  mpFindComboBox->clear();
  QList<QVariant> findTexts = settings.value("findReplaceDialog/textsToFind").toList();
  int numFindTexts = qMin(findTexts.size(), (int)MaxFindTexts);
  for (int i = 0; i < numFindTexts; ++i)
  {
    FindText findText = qvariant_cast<FindText>(findTexts[i]);
    mpFindComboBox->addItem(findText.text);
  }
}

/*!
  Saves the find text to the settings file.
  \param textToFind - the text to find
  */
void FindReplaceDialog::saveFindTextToSettings(QString textToFind)
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  settings.setIniCodec(Helper::utf8.toStdString().data());
  QList<QVariant> texts = settings.value("findReplaceDialog/textsToFind").toList();
  // remove the already present text from the list.
  foreach (QVariant text, texts)
  {
    FindText findText = qvariant_cast<FindText>(text);
    if (findText.text.compare(textToFind) == 0)
      texts.removeOne(text);
  }
  FindText findText;
  findText.text = textToFind;
  texts.prepend(QVariant::fromValue(findText));
  while (texts.size() > MaxFindTexts)
    texts.removeLast();

  settings.setValue("findReplaceDialog/textsToFind", texts);
}

/*!
  Performs the find task
  */
void FindReplaceDialog::find()
{
  findText(mpForwardRadioButton->isChecked());
}

void FindReplaceDialog::findText(bool forward)
{
  QTextCursor currentTextCursor = mpBaseEditor->textCursor();
  bool backward = !forward;

  if (currentTextCursor.hasSelection())
  {
    currentTextCursor.setPosition(forward ? currentTextCursor.position() : currentTextCursor.anchor(), QTextCursor::MoveAnchor);
  }
  const QString &textToFind = mpFindComboBox->currentText();
  // save the find text in settings
  saveFindTextToSettings(textToFind);
  bool result = true;
  QTextDocument::FindFlags flags;
  if (backward)
    flags |= QTextDocument::FindBackward;
  if (mpCaseSensitiveCheckBox->isChecked())
    flags |= QTextDocument::FindCaseSensitively;
  if (mpWholeWordCheckBox->isChecked())
    flags |= QTextDocument::FindWholeWords;

  if (mpRegularExpressionCheckBox->isChecked())
  {
    QRegExp reg(textToFind, (mpCaseSensitiveCheckBox->isChecked() ? Qt::CaseSensitive : Qt::CaseInsensitive));
    currentTextCursor = mpBaseEditor->document()->find(reg, currentTextCursor, flags);
    mpBaseEditor->setTextCursor(currentTextCursor);
    result = (!currentTextCursor.isNull());
  }

  QTextCursor newTextCursor = mpBaseEditor->document()->find(textToFind, currentTextCursor, flags);
  if (newTextCursor.isNull())
  {
    QTextCursor ac(mpBaseEditor->document());
    ac.movePosition(flags & QTextDocument::FindBackward ? QTextCursor::End : QTextCursor::Start);
    newTextCursor = mpBaseEditor->document()->find(textToFind, ac, flags);
    if (newTextCursor.isNull())
    {
      result = false;
      newTextCursor = currentTextCursor;
    }
  }
  mpBaseEditor->setTextCursor(newTextCursor);

  if(!result)
  {
    QString message = QString( tr("Can't find the text '") ) + textToFind + QString( "'." );
    QMessageBox::information( this, "Find", message );
  }
}

/*!
  Replaces the found occurrences and goes to the next occurrence
  */
void FindReplaceDialog::replace()
{
  int compareString(0);
  if(mpCaseSensitiveCheckBox->isChecked())
    compareString = Qt::CaseSensitive;
  else
    compareString = Qt::CaseInsensitive;
  int same = mpBaseEditor->textCursor().selectedText().compare(mpFindComboBox->currentText(),( Qt::CaseSensitivity)compareString );
  if (mpBaseEditor->textCursor().hasSelection()&& same == 0  )
  {
    mpBaseEditor->textCursor().insertText(mpReplaceWithTextBox->text());
    find();
  }
  else
    find();
}

/*!
  Replaces all the found occurrences
  */
void FindReplaceDialog::replaceAll()
{
  // move cursor to start of text
  QTextCursor cursor = mpBaseEditor->textCursor();
  cursor.movePosition(QTextCursor::Start);
  mpBaseEditor->setTextCursor(cursor);

  QTextDocument::FindFlags flags;
  if (mpCaseSensitiveCheckBox->isChecked())
    flags |= QTextDocument::FindCaseSensitively;
  if (mpWholeWordCheckBox->isChecked())
    flags |= QTextDocument::FindWholeWords;

  // save the find text in settings
  saveFindTextToSettings(mpFindComboBox->currentText());
  // replace all
  int i=0;
  mpBaseEditor->textCursor().beginEditBlock();
  while(mpBaseEditor->find(mpFindComboBox->currentText(), flags ))
  {
    mpBaseEditor->textCursor().insertText(mpReplaceWithTextBox->text());
    i++;
  }
  mpBaseEditor->textCursor().endEditBlock();

  // show message box with status information
  QString message;
  message.setNum(i);
  message += QString( " occurence(s) of the text '" ) + mpFindComboBox->currentText() +
      QString( "' was replaced with the text '" ) + mpReplaceWithTextBox->text() + QString( "'." );
  QMessageBox::information( this, "Replace All", message );
}

void FindReplaceDialog::updateButtons()
{
  const bool enable = !mpFindComboBox->currentText().isEmpty();
  mpFindButton->setEnabled(enable);
}

/*!
  Checks whether the passed text is a valid regular expression
  */
void FindReplaceDialog::validateRegularExpression(const QString &text)
{
  if (!mpRegularExpressionCheckBox->isChecked() || text.size() == 0)
  {
    return; // nothing to validate
  }
  QRegExp reg(text, (mpCaseSensitiveCheckBox->isChecked() ? Qt::CaseSensitive : Qt::CaseInsensitive));
  if (!reg.isValid())
  {
    QMessageBox::critical( this, "Find", reg.errorString());
  }
}

/*!
  The regular expression checkbox was selected
  */
void FindReplaceDialog::regularExpressionSelected(bool selected)
{
  if (selected)
    validateRegularExpression(mpFindComboBox->currentText());
  else
    validateRegularExpression("");
}

/*!
  When the text edit contents changed
  */
void FindReplaceDialog::textToFindChanged()
{
  mpFindButton->setEnabled(mpFindComboBox->currentText().size() > 0);
}
