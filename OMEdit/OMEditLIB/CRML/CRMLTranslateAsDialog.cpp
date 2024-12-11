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

#include "CRML/CRMLTranslateAsDialog.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Util/StringHandler.h"
#include "Modeling/ModelicaClassDialog.h"
#include "MainWindow.h"
#include "Options/OptionsDialog.h"

#include <QGridLayout>
#include <QMessageBox>
#include <QDir>

/*!
 * \class CRMLTranslateAsDialog
 * \brief Creates a dialog for CRML translateAs.
 */
/*!
 * \brief CRMLTranslateAsDialog::CRMLTranslateAsDialog
 * \param pCRMLTranslatorOptions
 * \param pParent
 */
CRMLTranslateAsDialog::CRMLTranslateAsDialog(CRMLTranslatorOptions *pCRMLTranslatorOptions, QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::translateAsCRML));
  setMinimumWidth(600);
  mpCRMLTranslatorOptions = pCRMLTranslatorOptions;
  // Create the output directory label
  mpOutputDirectoryLabel = new Label(tr("Select the output directory:"));
  mpOutputDirectoryTextBox = new QLineEdit;
  mpOutputDirectoryTextBox->setText(StringHandler::getLastOpenDirectory());
  mpOutputDirectoryBrowseButton = new QPushButton(Helper::browse);
  mpOutputDirectoryBrowseButton->setAutoDefault(false);
  connect(mpOutputDirectoryBrowseButton, SIGNAL(clicked()), SLOT(browseOutputDirectory()));
  // Create the parent package label, text box, browse button
  mpParentClassLabel = new Label(tr("Insert in class - within (optional):"));
  mpParentClassTextBox = new QLineEdit;
  mpParentClassBrowseButton = new QPushButton(Helper::browse);
  mpParentClassBrowseButton->setAutoDefault(false);
  connect(mpParentClassBrowseButton, SIGNAL(clicked()), SLOT(browseParentClass()));
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(translateAsCRML()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpOutputDirectoryLabel, 1, 0);
  pMainLayout->addWidget(mpOutputDirectoryTextBox, 1, 1);
  pMainLayout->addWidget(mpOutputDirectoryBrowseButton, 1, 2);
  pMainLayout->addWidget(mpParentClassLabel, 2, 0);
  pMainLayout->addWidget(mpParentClassTextBox, 2, 1);
  pMainLayout->addWidget(mpParentClassBrowseButton, 2, 2);
  pMainLayout->addWidget(mpButtonBox, 3, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief CRMLTranslateAsDialog::browseOutputDirectory
 * Sets the output directory.
 */
void CRMLTranslateAsDialog::browseOutputDirectory()
{
  mpOutputDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName, "Choose output directory"), NULL));
}

/*!
 * \brief CRMLTranslateAsDialog::browseParentClass
 * Sets the parent class name.
 */
void CRMLTranslateAsDialog::browseParentClass()
{
  LibraryBrowseDialog *pLibraryBrowseDialog = new LibraryBrowseDialog(Helper::selectParentClassName, mpParentClassTextBox, MainWindow::instance()->getLibraryWidget());
  pLibraryBrowseDialog->exec();
}

/*!
 * \brief CRMLTranslateAsDialog::translateAsCRML
 * Calls the translate CRML model functionality.
 */
void CRMLTranslateAsDialog::translateAsCRML()
{
  // check output directory
  if (!mpOutputDirectoryTextBox->text().isEmpty()) {
    // check if output directory exists
    if (!QDir().exists(mpOutputDirectoryTextBox->text())) {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Output directory does not exist."), QMessageBox::Ok);
      return;
    }
  }
  // crml translator options
  mpCRMLTranslatorOptions->setOutputDirectory(mpOutputDirectoryTextBox->text());
  mpCRMLTranslatorOptions->setModelicaWithin(mpParentClassTextBox->text());
  accept();
}
