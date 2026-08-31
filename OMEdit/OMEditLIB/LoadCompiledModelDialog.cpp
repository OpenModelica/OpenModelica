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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "LoadCompiledModelDialog.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Util/StringHandler.h"
#include "MainWindow.h"

#include <QDialogButtonBox>
#include <QDir>
#include <QGridLayout>

/*!
 * \class LoadCompiledModelDialog
 * \brief This class is used to load the compiled model.
 */
/*!
 * \brief LoadCompiledModelDialog::LoadCompiledModelDialog
 * \param pParent
 */
LoadCompiledModelDialog::LoadCompiledModelDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::loadCompiledModel));
  setMinimumWidth(400);
  // create executable label, textbox and browse button
  Label *pExecutableLabel = new Label(tr("Executable"));
  mpExecutableTextBox = new QLineEdit;
  QPushButton *pExecutableBrowseButton = new QPushButton(Helper::browse);
  connect(pExecutableBrowseButton, &QPushButton::clicked, this, &LoadCompiledModelDialog::browseExecutable);
  // create model init file label, combobox and browse button
  Label *pModelInitFileLabel = new Label(tr("Model init file"));
  mpModelInitFileComboBox = new QComboBox;
  mpModelInitFileComboBox->setEditable(true);
  QPushButton *pModelInitFileBrowseButton = new QPushButton(Helper::browse);
  connect(pModelInitFileBrowseButton, &QPushButton::clicked, this, &LoadCompiledModelDialog::browseModelInitFile);
  // create result file label, combobox and browse button
  Label *pResultFileLabel = new Label(tr("Result file"));
  mpResultFileComboBox = new QComboBox;
  mpResultFileComboBox->setEditable(true);
  QPushButton *pResultFileBrowseButton = new QPushButton(Helper::browse);
  connect(pResultFileBrowseButton, &QPushButton::clicked, this, &LoadCompiledModelDialog::browseResultFile);
  // Create the buttons
  QPushButton *pOkButton = new QPushButton(Helper::ok);
  pOkButton->setAutoDefault(true);
  connect(pOkButton, SIGNAL(clicked()), SLOT(loadCompiledModel()));
  QPushButton *pCancelButton = new QPushButton(Helper::cancel);
  pCancelButton->setAutoDefault(false);
  connect(pCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  QDialogButtonBox *pButtonBox = new QDialogButtonBox(Qt::Horizontal);
  pButtonBox->addButton(pOkButton, QDialogButtonBox::ActionRole);
  pButtonBox->addButton(pCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(pExecutableLabel, 0, 0);
  pMainLayout->addWidget(mpExecutableTextBox, 0, 1);
  pMainLayout->addWidget(pExecutableBrowseButton, 0, 2);
  pMainLayout->addWidget(pModelInitFileLabel, 1, 0);
  pMainLayout->addWidget(mpModelInitFileComboBox, 1, 1);
  pMainLayout->addWidget(pModelInitFileBrowseButton, 1, 2);
  pMainLayout->addWidget(pResultFileLabel, 2, 0);
  pMainLayout->addWidget(mpResultFileComboBox, 2, 1);
  pMainLayout->addWidget(pResultFileBrowseButton, 2, 2);
  pMainLayout->addWidget(pButtonBox, 3, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief LoadCompiledModelDialog::fetchModelInitFiles
 * Fetches the model init files from the executable path and populates the model init file combobox.
 */
void LoadCompiledModelDialog::fetchModelInitFiles()
{
  mpModelInitFileComboBox->clear();
  QString executablePath = mpExecutableTextBox->text();
  if (executablePath.isEmpty()) {
    return;
  }
  QDir dir(QFileInfo(executablePath).absolutePath());
  QStringList filters;
  filters << "*_init.xml";
  QStringList initFiles = dir.entryList(filters, QDir::Files, QDir::Name);
  for (const QString &initFile : initFiles) {
    mpModelInitFileComboBox->addItem(dir.absoluteFilePath(initFile));
  }
}

/*!
 * \brief LoadCompiledModelDialog::fetchResultFiles
 * Fetches the result files from the executable path and populates the result file combobox.
 */
void LoadCompiledModelDialog::fetchResultFiles()
{
  mpResultFileComboBox->clear();
  QString executablePath = mpExecutableTextBox->text();
  if (executablePath.isEmpty()) {
    return;
  }
  QDir dir(QFileInfo(executablePath).absolutePath());
  QStringList filters;
  QStringList extList = Helper::ModelicaSimulationOutputFormats.split(",", Qt::SkipEmptyParts);
  for (const QString &ext : extList) {
    filters << QString("*.%1").arg(ext.trimmed());
  }
  QStringList resultFiles = dir.entryList(filters, QDir::Files, QDir::Name);
  for (const QString &resultFile : resultFiles) {
    mpResultFileComboBox->addItem(dir.absoluteFilePath(resultFile));
  }
}

/*!
 * \brief LoadCompiledModelDialog::browseExecutable
 * Browses for the executable file and sets the path in the executable textbox.
 */
void LoadCompiledModelDialog::browseExecutable()
{
  QString executableFilePath = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseFile), NULL, "", NULL);
  if (executableFilePath.isEmpty()) {
    return;
  }
  mpExecutableTextBox->setText(executableFilePath);
  fetchModelInitFiles();
  fetchResultFiles();
}

/*!
 * \brief LoadCompiledModelDialog::browseModelInitFile
 * Browses for the model init file and sets the path in the model init file combobox.
 */
void LoadCompiledModelDialog::browseModelInitFile()
{
  QString modelInitFilePath = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseFile), NULL, Helper::xmlFileTypes, NULL);
  if (modelInitFilePath.isEmpty()) {
    return;
  }
  mpModelInitFileComboBox->lineEdit()->setText(modelInitFilePath);
}

/*!
 * \brief LoadCompiledModelDialog::browseResultFile
 * Browses for the result file and sets the path in the result file combobox.
 */
void LoadCompiledModelDialog::browseResultFile()
{
  QString resultFilePath = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseFile), NULL, Helper::omResultFileTypes, NULL);
  if (resultFilePath.isEmpty()) {
    return;
  }
  mpResultFileComboBox->lineEdit()->setText(resultFilePath);
}

/*!
 * \brief LoadCompiledModelDialog::loadCompiledModel
 * Loads the compiled model using the provided executable file path, model init file path, and result file path.
 */
void LoadCompiledModelDialog::loadCompiledModel()
{
  const QString executableFilePath = mpExecutableTextBox->text();
  const QString modelInitFilePath = mpModelInitFileComboBox->currentText();
  const QString resultFilePath = mpResultFileComboBox->currentText();

  MainWindow::instance()->loadCompiledModel(executableFilePath, modelInitFilePath, resultFilePath);
  accept();
}
