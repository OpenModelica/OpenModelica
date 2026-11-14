/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * @author John Tinnerholm
 */

#include "ImportXMILEDialog.h"
#include "XMILETranslator.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Options/OptionsDialog.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Util/StringHandler.h"

#include <QApplication>
#include <QDir>
#include <QFileInfo>
#include <QGridLayout>
#include <QMessageBox>
#include <QRegularExpression>

namespace {
const char *formKey = "xmileImport/form";
}

/*!
 * \class ImportXMILEDialog
 * \brief Imports a System Dynamics model (XMILE: Stella .stmx/.itmx, .xmile, Vensim through xmutil) as a Modelica model.
 */
/*!
 * \brief ImportXMILEDialog::ImportXMILEDialog
 * \param pParent
 */
ImportXMILEDialog::ImportXMILEDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Import XMILE")));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(600);
  mpHeading = Utilities::getHeadingLabel(tr("Import XMILE"));
  mpHorizontalLine = Utilities::getHeadingLine();
  // the XMILE file
  mpXMILEFileLabel = new Label(tr("XMILE File:"));
  mpXMILEFileTextBox = new QLineEdit;
  mpBrowseXMILEFileButton = new QPushButton(Helper::browse);
  mpBrowseXMILEFileButton->setAutoDefault(false);
  connect(mpBrowseXMILEFileButton, SIGNAL(clicked()), SLOT(browseXMILEFile()));
  // the model name
  mpModelNameLabel = new Label(tr("Model Name:"));
  mpModelNameTextBox = new QLineEdit;
  mpModelNameTextBox->setPlaceholderText(tr("If empty then the name of the XMILE file."));
  // blocks with the diagram (in sectors) or the flat model
  mpOutputLabel = new Label(tr("Output:"));
  mpOutputComboBox = new QComboBox;
  mpOutputComboBox->addItem(tr("Blocks with the stock and flow diagram (in sectors when large)"), QVariant(XMILETranslator::Blocks));
  mpOutputComboBox->addItem(tr("Blocks in sectors"), QVariant(XMILETranslator::BlocksInSectors));
  mpOutputComboBox->addItem(tr("Blocks without sectors"), QVariant(XMILETranslator::BlocksWithoutSectors));
  mpOutputComboBox->addItem(tr("Flat model (equations only)"), QVariant(XMILETranslator::Flat));
  mpOutputComboBox->setToolTip(tr("Sectors: groups of closely connected variables, each a model with its own diagram."));
  int index = mpOutputComboBox->findData(Utilities::getApplicationSettings()->value(formKey, XMILETranslator::Blocks).toInt());
  mpOutputComboBox->setCurrentIndex(index < 0 ? 0 : index);
  // Excel data
  mpExcelFilesLabel = new Label(tr("Excel Data (Optional):"));
  mpExcelFilesTextBox = new QLineEdit;
  mpExcelFilesTextBox->setPlaceholderText(tr("Workbooks (.xlsx) with time series the model uses, separated by ;"));
  mpBrowseExcelFilesButton = new QPushButton(Helper::browse);
  mpBrowseExcelFilesButton->setAutoDefault(false);
  connect(mpBrowseExcelFilesButton, SIGNAL(clicked()), SLOT(browseExcelFiles()));
  // the output directory
  mpOutputDirectoryLabel = new Label(tr("Output Directory (Optional):"));
  mpOutputDirectoryTextBox = new QLineEdit;
  mpOutputDirectoryTextBox->setPlaceholderText(tr("If empty then the working directory."));
  mpBrowseDirectoryButton = new QPushButton(Helper::browse);
  mpBrowseDirectoryButton->setAutoDefault(false);
  connect(mpBrowseDirectoryButton, SIGNAL(clicked()), SLOT(browseOutputDirectory()));
  // the translator
  mpTranslatorLabel = new Label(tr("Translator:"));
  mpTranslatorTextBox = new QLineEdit(XMILETranslator::savedTranslator());
  QString found = XMILETranslator::findTranslator();
  mpTranslatorTextBox->setPlaceholderText(found.isEmpty() ? tr("libxmile2mo or xmile2mo (XMILEToModelica.jl)") : found);
  mpBrowseTranslatorButton = new QPushButton(Helper::browse);
  mpBrowseTranslatorButton->setAutoDefault(false);
  connect(mpBrowseTranslatorButton, SIGNAL(clicked()), SLOT(browseTranslator()));
  // import button
  mpImportButton = new QPushButton(Helper::ok);
  mpImportButton->setAutoDefault(true);
  connect(mpImportButton, SIGNAL(clicked()), SLOT(importXMILE()));
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpHeading, 0, 0, 1, 3);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 3);
  pMainLayout->addWidget(mpXMILEFileLabel, 2, 0);
  pMainLayout->addWidget(mpXMILEFileTextBox, 2, 1);
  pMainLayout->addWidget(mpBrowseXMILEFileButton, 2, 2);
  pMainLayout->addWidget(mpModelNameLabel, 3, 0);
  pMainLayout->addWidget(mpModelNameTextBox, 3, 1, 1, 2);
  pMainLayout->addWidget(mpOutputLabel, 4, 0);
  pMainLayout->addWidget(mpOutputComboBox, 4, 1, 1, 2);
  pMainLayout->addWidget(mpExcelFilesLabel, 5, 0);
  pMainLayout->addWidget(mpExcelFilesTextBox, 5, 1);
  pMainLayout->addWidget(mpBrowseExcelFilesButton, 5, 2);
  pMainLayout->addWidget(mpOutputDirectoryLabel, 6, 0);
  pMainLayout->addWidget(mpOutputDirectoryTextBox, 6, 1);
  pMainLayout->addWidget(mpBrowseDirectoryButton, 6, 2);
  pMainLayout->addWidget(mpTranslatorLabel, 7, 0);
  pMainLayout->addWidget(mpTranslatorTextBox, 7, 1);
  pMainLayout->addWidget(mpBrowseTranslatorButton, 7, 2);
  pMainLayout->addWidget(mpImportButton, 8, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

void ImportXMILEDialog::browseXMILEFile()
{
  QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL,
                                                    tr("XMILE Files (*.xmile *.stmx *.itmx *.xml)"), NULL);
  if (!fileName.isEmpty()) {
    mpXMILEFileTextBox->setText(fileName);
  }
}

void ImportXMILEDialog::browseExcelFiles()
{
  QStringList fileNames = StringHandler::getOpenFileNames(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFiles), NULL,
                                                          tr("Excel Files (*.xlsx)"), NULL);
  if (!fileNames.isEmpty()) {
    mpExcelFilesTextBox->setText(fileNames.join(";"));
  }
}

void ImportXMILEDialog::browseOutputDirectory()
{
  QString directory = StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseDirectory), NULL);
  if (!directory.isEmpty()) {
    mpOutputDirectoryTextBox->setText(directory);
  }
}

void ImportXMILEDialog::browseTranslator()
{
  QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, "", NULL);
  if (!fileName.isEmpty()) {
    mpTranslatorTextBox->setText(fileName);
  }
}

/*!
 * \brief ImportXMILEDialog::importXMILE
 * Translates the XMILE file to <output directory>/<model name>.mo and opens it.
 */
void ImportXMILEDialog::importXMILE()
{
  const QString title = QString("%1 - %2").arg(Helper::applicationName, Helper::error);
  XMILETranslator::Options options;
  options.input = mpXMILEFileTextBox->text().trimmed();
  if (!QFileInfo(options.input).isFile()) {
    QMessageBox::critical(this, title, options.input.isEmpty() ? GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("XMILE File"))
                                                               : tr("The file %1 does not exist.").arg(options.input), QMessageBox::Ok);
    return;
  }
  options.name = mpModelNameTextBox->text().trimmed();
  if (options.name.isEmpty()) {
    options.name = XMILETranslator::modelName(options.input);
  }
  if (!QRegularExpression("^[A-Za-z_][A-Za-z0-9_]*$").match(options.name).hasMatch()) {
    QMessageBox::critical(this, title, tr("%1 is not a Modelica name.").arg(options.name), QMessageBox::Ok);
    return;
  }
  if (MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItemOneLevel(options.name)) {
    QMessageBox::critical(this, title, tr("A class %1 is loaded. Unload it or choose another model name.").arg(options.name), QMessageBox::Ok);
    return;
  }
  QString directory = mpOutputDirectoryTextBox->text().trimmed();
  if (directory.isEmpty()) {
    directory = OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory();
  }
  if (!QDir().mkpath(directory)) {
    QMessageBox::critical(this, title, tr("Unable to create the directory %1.").arg(directory), QMessageBox::Ok);
    return;
  }
  options.output = QDir(directory).absoluteFilePath(options.name + ".mo");
  if (QFileInfo(options.output).exists()
      && QMessageBox::question(this, QString("%1 - %2").arg(Helper::applicationName, Helper::question),
                               tr("%1 exists. Overwrite it?").arg(options.output), QMessageBox::Yes | QMessageBox::No) != QMessageBox::Yes) {
    return;
  }
  options.form = (XMILETranslator::Form)mpOutputComboBox->currentData().toInt();
  const QStringList excelFiles = mpExcelFilesTextBox->text().split(";");
  for (const QString &file : excelFiles) {
    if (!file.trimmed().isEmpty()) {
      options.excel << file.trimmed();
    }
  }
  XMILETranslator::setTranslator(mpTranslatorTextBox->text().trimmed());
  Utilities::getApplicationSettings()->setValue(formKey, (int)options.form);
  QString error;
  QApplication::setOverrideCursor(Qt::WaitCursor);
  bool ok = XMILETranslator::translate(options, &error);
  QApplication::restoreOverrideCursor();
  if (!ok) {
    QMessageBox::critical(this, title, tr("Unable to translate %1:\n%2").arg(options.input, error), QMessageBox::Ok);
    return;
  }
  MainWindow::instance()->getLibraryWidget()->openFile(options.output);
  accept();
}
