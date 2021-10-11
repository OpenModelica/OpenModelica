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

#include "InstallLibraryDialog.h"
#include "MainWindow.h"
#include "OMC/OMCProxy.h"

#include <QFile>
#include <QMessageBox>
#include <QGridLayout>

/*!
 * \brief InstallLibraryDialog::InstallLibraryDialog
 * \param parent
 */
InstallLibraryDialog::InstallLibraryDialog(QDialog *parent)
  : QDialog(parent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::installLibrary));
  setMinimumWidth(400);
  Label *pHeadingLabel = Utilities::getHeadingLabel(Helper::installLibrary);
  pHeadingLabel->setElideMode(Qt::ElideMiddle);
  // name combobox
  mpNameComboBox = new QComboBox;
  // version combobox
  mpVersionComboBox = new QComboBox;
  // fetch libraries
  QString indexFilePath = QString("%1/.openmodelica/libraries/index.json").arg(Helper::userHomeDirectory);
  if (QFile::exists(indexFilePath) || MainWindow::instance()->getOMCProxy()->updatePackageIndex()) {
    if (mIndexJsonDocument.parse(indexFilePath)) {
      QVariantMap result = mIndexJsonDocument.result.toMap();
      mLibrariesMap = result["libs"].toMap();
      for (QVariantMap::const_iterator librariesIterator = mLibrariesMap.begin(); librariesIterator != mLibrariesMap.end(); ++librariesIterator) {
        mpNameComboBox->addItem(librariesIterator.key());
      }
    }
  } else {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error), tr("Package index file <b>%1</b> doesn't exist.").arg(indexFilePath), Helper::ok);
  }
  connect(mpNameComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(libraryIndexChanged(QString)));
  libraryIndexChanged(mpNameComboBox->currentText());
  // exact match checkbox
  mpExactMatchCheckBox = new QCheckBox(tr("Exact Match"));
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(installLibrary()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->setAlignment(Qt::AlignTop);
  pMainGridLayout->addWidget(pHeadingLabel, 0, 0, 1, 2);
  pMainGridLayout->addWidget(Utilities::getHeadingLine(), 1, 0, 1, 2);
  pMainGridLayout->addWidget(new Label(Helper::name), 2, 0);
  pMainGridLayout->addWidget(mpNameComboBox, 2, 1);
  pMainGridLayout->addWidget(new Label(Helper::version), 3, 0);
  pMainGridLayout->addWidget(mpVersionComboBox, 3, 1);
  pMainGridLayout->addWidget(mpExactMatchCheckBox, 4, 0, 1, 2);
  pMainGridLayout->addWidget(mpButtonBox, 5, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainGridLayout);
}

/*!
 * \brief InstallLibraryDialog::libraryIndexChanged
 * Fills the version combobox when the library is changed.
 * \param text
 */
void InstallLibraryDialog::libraryIndexChanged(const QString &text)
{
  mpVersionComboBox->clear();
  QVariantMap libraryMap = mLibrariesMap[text].toMap();
  QVariantMap libraryVersionsMap = libraryMap["versions"].toMap();
  for (QVariantMap::const_iterator versionsIterator = libraryVersionsMap.begin(); versionsIterator != libraryVersionsMap.end(); ++versionsIterator) {
    mpVersionComboBox->addItem(versionsIterator.key());
  }
}

/*!
 * \brief InstallLibraryDialog::installLibrary
 * Installs the library.
 */
void InstallLibraryDialog::installLibrary()
{
  QString library = mpNameComboBox->currentText();
  QString version = mpVersionComboBox->currentText();
  bool exactMatch = mpExactMatchCheckBox->isChecked();

  if (MainWindow::instance()->getOMCProxy()->installPackage(library, version, exactMatch)) {
    MainWindow::instance()->getOMCProxy()->updatePackageIndex();
    MainWindow::instance()->addSystemLibraries();
    accept();
  } else {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          tr("The library <b>%1</b> is not installed. See Messages Browser for any possible messages.").arg(library), Helper::ok);
  }
}
