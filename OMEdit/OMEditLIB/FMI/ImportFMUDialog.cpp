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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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

#include "ImportFMUDialog.h"
#include "MainWindow.h"
#include "OMC/OMCProxy.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Util/StringHandler.h"
#include "Options/OptionsDialog.h"
#include "Git/CommitChangesDialog.h"

#include <QMessageBox>
#include <QGridLayout>

/*!
 * \class ImportFMUDialog
 * \brief Creates an interface for importing FMU package.
 */
/*!
 * \brief ImportFMUDialog::ImportFMUDialog
 * \param pParent
 */
ImportFMUDialog::ImportFMUDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::importFMU));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(550);
  // set import heading
  mpImportFMUHeading = Utilities::getHeadingLabel(Helper::importFMU);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // create FMU File selection controls
  mpFmuFileLabel = new Label(tr("FMU File:"));
  mpFmuFileTextBox = new QLineEdit;
  mpBrowseFileButton = new QPushButton(Helper::browse);
  mpBrowseFileButton->setAutoDefault(false);
  connect(mpBrowseFileButton, SIGNAL(clicked()), SLOT(setSelectedFile()));
  // create Output Directory selection controls
  mpOutputDirectoryLabel = new Label(tr("Output Directory (Optional):"));
  mpOutputDirectoryTextBox = new QLineEdit;
  mpBrowseDirectoryButton = new QPushButton(Helper::browse);
  mpBrowseDirectoryButton->setAutoDefault(false);
  connect(mpBrowseDirectoryButton, SIGNAL(clicked()), SLOT(setSelectedDirectory()));
  // create Log Level Drop Down
  mpLogLevelLabel = new Label(tr("Log Level:"));
  mpLogLevelComboBox = new QComboBox;
  mpLogLevelComboBox->addItem(tr("Nothing"), QVariant(0));
  mpLogLevelComboBox->addItem(tr("Fatal"), QVariant(1));
  mpLogLevelComboBox->addItem(tr("Error"), QVariant(2));
  mpLogLevelComboBox->addItem(tr("Warning"), QVariant(3));
  mpLogLevelComboBox->addItem(Helper::information, QVariant(4));
  mpLogLevelComboBox->addItem(tr("Verbose"), QVariant(5));
  mpLogLevelComboBox->addItem(tr("Debug"), QVariant(6));
  mpLogLevelComboBox->setCurrentIndex(3);
  // create debug logging checkbox
  mpDebugLoggingCheckBox = new QCheckBox(tr("Debug Logging"));
  // create generate input connectors pins checkbox
  mpGenerateIntputConnectors = new QCheckBox(tr("Generate input connector pins"));
  mpGenerateIntputConnectors->setChecked(true);
  // create generate output connectors pins checkbox
  mpGenerateOutputConnectors = new QCheckBox(tr("Generate output connector pins"));
  mpGenerateOutputConnectors->setChecked(true);
  // import FMU note
  mpOutputDirectoryNoteLabel = new Label(tr("* If no Output Directory specified then the FMU files are generated in the current working directory."));
  // create OK button
  mpImportButton = new QPushButton(Helper::ok);
  mpImportButton->setAutoDefault(true);
  connect(mpImportButton, SIGNAL(clicked()), SLOT(importFMU()));
  // set grid layout
  Label *pNoteLabel = new Label(tr("* This feature is experimental. Most models are not yet handled by it."));
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpImportFMUHeading, 0, 0, 1, 3);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 3);
  pMainLayout->addWidget(mpFmuFileLabel, 2, 0);
  pMainLayout->addWidget(mpFmuFileTextBox, 2, 1);
  pMainLayout->addWidget(mpBrowseFileButton, 2, 2);
  pMainLayout->addWidget(mpOutputDirectoryLabel, 3, 0);
  pMainLayout->addWidget(mpOutputDirectoryTextBox, 3, 1);
  pMainLayout->addWidget(mpBrowseDirectoryButton, 3, 2);
  pMainLayout->addWidget(mpOutputDirectoryNoteLabel, 4, 0, 1, 3, Qt::AlignLeft);
  pMainLayout->addWidget(mpLogLevelLabel, 5, 0);
  pMainLayout->addWidget(mpLogLevelComboBox, 5, 1, 1, 2);
  pMainLayout->addWidget(mpDebugLoggingCheckBox, 6, 0, 1, 3);
  pMainLayout->addWidget(mpGenerateIntputConnectors, 7, 0, 1, 3);
  pMainLayout->addWidget(mpGenerateOutputConnectors, 8, 0, 1, 3);
  pMainLayout->addWidget(pNoteLabel, 9, 0, 1, 3, Qt::AlignLeft);
  pMainLayout->addWidget(mpImportButton, 10, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
  Slot activated when mpBrowseFileButton clicked signal is raised.\n
  Allows the user to select the FMU file.
  */
void ImportFMUDialog::setSelectedFile()
{
  mpFmuFileTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                           NULL, Helper::fmuFileTypes, NULL));
}

/*!
  Slot activated when mpBrowseDirectoryButton clicked signal is raised.\n
  Allows the user to select the output directory for FMU files.
  */
void ImportFMUDialog::setSelectedDirectory()
{
  mpOutputDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseDirectory), NULL));
}

/*!
  Slot activated when mpImportButton clicked signal is raised.\n
  Sends the importFMU command to OMC.
  */
void ImportFMUDialog::importFMU()
{
  if (mpFmuFileTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("FMU File")), Helper::ok);
    return;
  }
  /* ticket:4959 Create a unique folder for each FMU
   * Otherwise we have issues during simulation since the files are mixed.
   */
  QString outputDirectory;
  if (mpOutputDirectoryTextBox->text().isEmpty()) {
    // Create an output directory for FMU binaries and files
    outputDirectory = QString("%1/temp%2").arg(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory())
                      .arg(QDateTime::currentDateTime().toString("yyyyMMddhhmmsszzz"));
    if (!QDir().exists(outputDirectory)) {
      QDir().mkpath(outputDirectory);
    }
    MainWindow::instance()->mFMUDirectoriesList.append(outputDirectory);
  } else {
    outputDirectory = mpOutputDirectoryTextBox->text();
  }
  QString fmuFileName = MainWindow::instance()->getOMCProxy()->importFMU(mpFmuFileTextBox->text(), outputDirectory,
                                                                         mpLogLevelComboBox->itemData(mpLogLevelComboBox->currentIndex()).toInt(),
                                                                         mpDebugLoggingCheckBox->isChecked(),
                                                                         mpGenerateIntputConnectors->isChecked(),
                                                                         mpGenerateOutputConnectors->isChecked());
  if (!fmuFileName.isEmpty()) {
    MainWindow::instance()->getLibraryWidget()->openFile(fmuFileName);
  }
  // trace import modeldescription
  if (OptionsDialog::instance()->getTraceabilityPage()->getTraceabilityGroupBox()->isChecked() && !fmuFileName.isEmpty()) {
    QFileInfo file(fmuFileName);
    // Get the name of the file without the extension
    QString base_name = file.baseName();
    // Push traceability information automaticaly to Daemon
    MainWindow::instance()->getCommitChangesDialog()->generateTraceabilityURI("fmuImport", fmuFileName, base_name, mpFmuFileTextBox->text());
  }
  accept();
}
