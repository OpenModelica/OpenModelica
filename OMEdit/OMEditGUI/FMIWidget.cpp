/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Author 2011: Adeel Asghar
 *
 */

/*
 * RCS: $Id$
 */

#include "FMIWidget.h"

//! @class ImportFMIWidget
//! @brief Creates an interface for importing FMU package.

//! Constructor
//! @param pParent is the pointer to MainWindow.
ImportFMIWidget::ImportFMIWidget(MainWindow *pParent)
  : QDialog(pParent, Qt::WindowTitleHint)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::importFMI));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(550);
  // set parent widget
  mpParentMainWindow = pParent;
  // set import heading
  mpImportFMIHeading = new QLabel(Helper::importFMI);
  mpImportFMIHeading->setFont(QFont("", Helper::headingFontSize));
  // set seperator line
  mpHorizontalLine = new QFrame();
  mpHorizontalLine->setFrameShape(QFrame::HLine);
  mpHorizontalLine->setFrameShadow(QFrame::Sunken);
  // create FMU File selection controls
  mpFmuFileLabel = new QLabel(tr("FMU File:"));
  mpFmuFileTextBox = new QLineEdit;
  mpBrowseFileButton = new QPushButton(Helper::browse);
  connect(mpBrowseFileButton, SIGNAL(clicked()), SLOT(setSelectedFile()));
  // create Output Directory selection controls
  mpOutputDirectoryLabel = new QLabel(tr("Output Directory (Optional):"));
  mpOutputDirectoryTextBox = new QLineEdit;
  mpBrowseDirectoryButton = new QPushButton(Helper::browse);
  connect(mpBrowseDirectoryButton, SIGNAL(clicked()), SLOT(setSelectedDirectory()));
  // import FMI note
  mpOutputDirectoryNoteLabel = new QLabel(tr("* If no Output Directory specified then the FMU files are generated in the current working directory."));
  // create OK button
  mpImportButton = new QPushButton(Helper::ok);
  connect(mpImportButton, SIGNAL(clicked()), SLOT(importFMU()));
  // set grid layout
  QLabel *pNoteLabel = new QLabel(tr("* This feature is experimental. Most models are not yet handled by it."));
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  mainLayout->addWidget(mpImportFMIHeading, 0, 0, 1, 3);
  mainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 3);
  mainLayout->addWidget(mpFmuFileLabel, 2, 0);
  mainLayout->addWidget(mpFmuFileTextBox, 2, 1);
  mainLayout->addWidget(mpBrowseFileButton, 2, 2);
  mainLayout->addWidget(mpOutputDirectoryLabel, 3, 0);
  mainLayout->addWidget(mpOutputDirectoryTextBox, 3, 1);
  mainLayout->addWidget(mpBrowseDirectoryButton, 3, 2);
  mainLayout->addWidget(mpOutputDirectoryNoteLabel, 4, 0, 1, 3, Qt::AlignLeft);
  mainLayout->addWidget(mpImportButton, 5, 0, 1, 3, Qt::AlignRight);
  mainLayout->addWidget(pNoteLabel, 6, 0, 1, 3, Qt::AlignLeft);
  setLayout(mainLayout);
}

//! Slot activated when mpBrowseFileButton clicked signal is raised.
//! Allows the user to select the FMU file.
void ImportFMIWidget::setSelectedFile()
{
  mpFmuFileTextBox->setText(StringHandler::getOpenFileName(this, Helper::chooseFile, NULL, Helper::fmuFileTypes, NULL));
}

//! Slot activated when mpBrowseDirectoryButton clicked signal is raised.
//! Allows the user to select the output directory for FMU files.
void ImportFMIWidget::setSelectedDirectory()
{
  mpOutputDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, Helper::chooseDirectory, NULL));
}

//! Slot activated when mpImportButton clicked signal is raised.
//! Sends the importFMU command to OMC.
//! Reads the generated model by fmigenerator and loads it.
void ImportFMIWidget::importFMU()
{
  if (mpFmuFileTextBox->text().isEmpty())
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("FMU File")), Helper::ok);
    return;
  }

  if (mpParentMainWindow->mpOMCProxy->importFMU(mpFmuFileTextBox->text(), mpOutputDirectoryTextBox->text()))
  {
    QFile fmuImportLogfile;
    fmuImportLogfile.setFileName(mpParentMainWindow->mpOMCProxy->changeDirectory().append(QDir::separator()).append("fmuImport.log"));
    // Open the FMU Import log file
    if (!fmuImportLogfile.open(QIODevice::ReadOnly))
    {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(tr("Could not open file "))
                            .append(fmuImportLogfile.fileName()), Helper::ok);
      return;
    }
    // Read the FMU Import log file
    QTextStream inStream(&fmuImportLogfile);
    QString importedFileName;
    while (!inStream.atEnd())
    {
      QString line = inStream.readLine();
      // Check for the path
      if (line.contains("FMU decompression path:"))
      {
        importedFileName.append(line.mid(line.indexOf("FMU decompression path:")+24));
      }
      // Check for the model name
      if (line.contains("Modelica model name:"))
      {
        importedFileName.append(QDir::separator()).append(line.mid(line.indexOf("Modelica model name:")+21));
      }
    }
    mpParentMainWindow->mpProjectTabs->openFile(importedFileName);
    accept();
  }
  else
  {
    QFile fmuImportErrorLogfile;
    fmuImportErrorLogfile.setFileName(mpParentMainWindow->mpOMCProxy->changeDirectory().append(QDir::separator()).append("fmuImportError.log"));
    // Open the FMU Import Error log file
    if (fmuImportErrorLogfile.open(QIODevice::ReadOnly))
    {
      QTextStream inStream(&fmuImportErrorLogfile);
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(inStream.readAll()).append("\n")
                            .append(tr("while importing ")).append(mpFmuFileTextBox->text()), Helper::ok);
    }
    else
    {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(tr("unknown error ")).append("\n")
                            .append(tr("while importing ")).append(mpFmuFileTextBox->text()), Helper::ok);
    }
  }
}
