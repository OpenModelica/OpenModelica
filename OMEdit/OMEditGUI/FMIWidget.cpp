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

#include "FMIWidget.h"

//! @class ImportFMIWidget
//! @brief Creates an interface for importing FMU package.

//! Constructor
ImportFMIWidget::ImportFMIWidget(MainWindow *pParent)
    : QDialog(pParent, Qt::WindowTitleHint)
{
    setWindowTitle(QString(Helper::applicationName).append(" - Import FMI"));
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
    mpFmuFileLabel = new QLabel(Helper::fmuFileName);
    mpFmuFileTextBox = new QLineEdit;
    mpBrowseFileButton = new QPushButton(Helper::browse);
    connect(mpBrowseFileButton, SIGNAL(clicked()), SLOT(setSelectedFile()));
    // create Output Directory selection controls
    mpOutputDirectoryLabel = new QLabel(Helper::outputDirectory);
    mpOutputDirectoryTextBox = new QLineEdit;
    mpBrowseDirectoryButton = new QPushButton(Helper::browse);
    connect(mpBrowseDirectoryButton, SIGNAL(clicked()), SLOT(setSelectedDirectory()));
    // import FMI note
    mpOutputDirectoryNoteLabel = new QLabel(Helper::outputDirectoryNote);
    // create OK button
    mpImportButton = new QPushButton(Helper::import);
    connect(mpImportButton, SIGNAL(clicked()), SLOT(importFMU()));
    // set grid layout
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

    setLayout(mainLayout);
}

//! Slot activated when mpBrowseFileButton clicked signal is raised.
//! Allows the user to select the FMU file.
void ImportFMIWidget::setSelectedFile()
{
    mpFmuFileTextBox->setText(StringHandler::getOpenFileName(this, tr("Choose File"), NULL, Helper::fmuFileTypes, NULL));
}

//! Slot activated when mpBrowseDirectoryButton clicked signal is raised.
//! Allows the user to select the output directory for FMU files.
void ImportFMIWidget::setSelectedDirectory()
{
    mpOutputDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, tr("Choose Directory"), NULL));
}

//! Slot activated when mpImportButton clicked signal is raised.
//! Sends the importFMU command to OMC.
//! Reads the generated model by fmigenerator and loads it.
void ImportFMIWidget::importFMU()
{
    if (mpFmuFileTextBox->text().isEmpty())
    {
        QMessageBox::critical(this, Helper::applicationName + " - Error", GUIMessages::getMessage(GUIMessages::ENTER_NAME).
                              arg("FMU File"), tr("OK"));
        return;
    }

    if (mpParentMainWindow->mpOMCProxy->importFMU(mpFmuFileTextBox->text(), mpOutputDirectoryTextBox->text()))
    {
        QFile fmuImportLogfile;
        if (mpOutputDirectoryTextBox->text().isEmpty())
        {
            fmuImportLogfile.setFileName(QString(mpOutputDirectoryTextBox->text()).append(QDir::separator()).append("fmuImport.log"));
        }
        else
        {
            fmuImportLogfile.setFileName(mpParentMainWindow->mpOMCProxy->changeDirectory().append(QDir::separator()).append("fmuImport.log"));
        }

        if (!fmuImportLogfile.open(QIODevice::ReadOnly))
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error", GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                                  .arg("Could not open file ").append(fmuImportLogfile.fileName()), tr("OK"));
            return;
        }
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
        if (mpOutputDirectoryTextBox->text().isEmpty())
        {
            fmuImportErrorLogfile.setFileName(mpParentMainWindow->mpOMCProxy->changeDirectory().append(QDir::separator()).append("fmuImportError.log"));
        }
        else
        {
            fmuImportErrorLogfile.setFileName(QString(mpOutputDirectoryTextBox->text()).append(QDir::separator()).append("fmuImportError.log"));
        }

        if (fmuImportErrorLogfile.open(QIODevice::ReadOnly))
        {
            QTextStream inStream(&fmuImportErrorLogfile);
            QMessageBox::critical(this, Helper::applicationName + " - Error", GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                                  .arg(inStream.readAll()).append("\nwhile importing " + mpFmuFileTextBox->text()), tr("OK"));
        }
        else
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error", GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                                  .arg("unknown error ").append("\nwhile importing " + mpFmuFileTextBox->text()), tr("OK"));
        }
    }
}
