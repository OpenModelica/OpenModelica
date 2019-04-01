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
 * @author Alachew Mengist <alachew.mengist@liu.se>
 */

#include "ImportFMUModelDescriptionDialog.h"
#include "MainWindow.h"
#include "OMC/OMCProxy.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Options/OptionsDialog.h"
#include "Git/CommitChangesDialog.h"
#include "Util/Helper.h"
#include "Util/StringHandler.h"

#include <QMessageBox>
#include <QGridLayout>

/*!
 * \class ImportFMUModelDescriptionDialog
 * \brief Creates an interface for importing FMU model description.
 */
/*!
 * \brief ImportFMUModelDescriptionDialog::ImportFMUModelDescriptionDialog
 * \param pParent
 */
ImportFMUModelDescriptionDialog::ImportFMUModelDescriptionDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Import FMU Model Description")));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(550);
  // create FMU File selection controls
  mpFmuModelDescriptionLabel = new Label(tr("FMU Model Description:"));
  mpFmuModelDescriptionTextBox = new QLineEdit;
  mpBrowseFileButton = new QPushButton(Helper::browse);
  mpBrowseFileButton->setAutoDefault(false);
  connect(mpBrowseFileButton, SIGNAL(clicked()), SLOT(setSelectedFile()));
  // create Output Directory selection controls
  mpOutputDirectoryLabel = new Label(tr("Output Directory (Optional):"));
  mpOutputDirectoryTextBox = new QLineEdit;
  mpBrowseDirectoryButton = new QPushButton(Helper::browse);
  mpBrowseDirectoryButton->setAutoDefault(false);
  connect(mpBrowseDirectoryButton, SIGNAL(clicked()), SLOT(setSelectedDirectory()));
  // import FMU Model description note
  mpOutputDirectoryNoteLabel = new Label(tr("* If no Output Directory specified then the Modelica model will be generated in the current working directory."));
  // create OK button
  mpImportButton = new QPushButton(Helper::ok);
  mpImportButton->setAutoDefault(true);
  connect(mpImportButton, SIGNAL(clicked()), SLOT(importFMUModelDescription()));
  // set grid layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpFmuModelDescriptionLabel, 0, 0);
  pMainLayout->addWidget(mpFmuModelDescriptionTextBox, 0, 1);
  pMainLayout->addWidget(mpBrowseFileButton, 0, 2);
  pMainLayout->addWidget(mpOutputDirectoryLabel, 1, 0);
  pMainLayout->addWidget(mpOutputDirectoryTextBox, 1, 1);
  pMainLayout->addWidget(mpBrowseDirectoryButton, 1, 2);
  pMainLayout->addWidget(mpOutputDirectoryNoteLabel, 2, 0, 1, 3);
  pMainLayout->addWidget(mpImportButton, 3, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
  Slot activated when mpBrowseFileButton clicked signal is raised.\n
  Allows the user to select the FMU model description.
  */
void ImportFMUModelDescriptionDialog::setSelectedFile()
{
  mpFmuModelDescriptionTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                           NULL, Helper::xmlFileTypes, NULL));
}

/*!
  Slot activated when mpBrowseDirectoryButton clicked signal is raised.\n
  Allows the user to select the output directory for FMU models with input and output.
  */
void ImportFMUModelDescriptionDialog::setSelectedDirectory()
{
  mpOutputDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseDirectory), NULL));
}

/*!
  Slot activated when mpImportButton clicked signal is raised.\n
  Sends the importFMUModelDescription command to OMC.
  */
void ImportFMUModelDescriptionDialog::importFMUModelDescription()
{
  if (mpFmuModelDescriptionTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("FMU Model Description XML file")), Helper::ok);
    return;
  }
  QString fmuFileName = MainWindow::instance()->getOMCProxy()->importFMUModelDescription(mpFmuModelDescriptionTextBox->text(), mpOutputDirectoryTextBox->text(), 1, false, true, true);

  if (!fmuFileName.isEmpty()) {
    MainWindow::instance()->getLibraryWidget()->openFile(fmuFileName);
  }
  //trace import modeldescription
  if (OptionsDialog::instance()->getTraceabilityPage()->getTraceabilityGroupBox()->isChecked() && !fmuFileName.isEmpty()) {
    QFileInfo file(fmuFileName);
    // Get the name of the file without the extension
    QString base_name = file.baseName();
    //Push traceability information automaticaly to Daemon
    MainWindow::instance()->getCommitChangesDialog()->generateTraceabilityURI("modelDescriptionImport", fmuFileName, base_name, mpFmuModelDescriptionTextBox->text());
  }
  accept();
}
