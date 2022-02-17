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
  // support levels
  mpFullSupportCheckBox = new QCheckBox(tr("Full"));
  mpFullSupportCheckBox->setChecked(true);
  connect(mpFullSupportCheckBox, SIGNAL(toggled(bool)), SLOT(filterChanged(bool)));
  mpSupportCheckBox = new QCheckBox(tr("Partial"));
  mpSupportCheckBox->setChecked(true);
  connect(mpSupportCheckBox, SIGNAL(toggled(bool)), SLOT(filterChanged(bool)));
  mpExperimentalCheckBox = new QCheckBox(tr("Experimental"));
  connect(mpExperimentalCheckBox, SIGNAL(toggled(bool)), SLOT(filterChanged(bool)));
  mpObsoleteCheckBox = new QCheckBox(tr("Obsolete"));
  connect(mpObsoleteCheckBox, SIGNAL(toggled(bool)), SLOT(filterChanged(bool)));
  mpNoSupportCheckBox = new QCheckBox(tr("None"));
  connect(mpNoSupportCheckBox, SIGNAL(toggled(bool)), SLOT(filterChanged(bool)));
  QGroupBox *pSupportLevelsGroupBox = new QGroupBox(tr("Support Levels"));
  QGridLayout *pSupportLevelsGridLayout = new QGridLayout;
  pSupportLevelsGridLayout->addWidget(mpFullSupportCheckBox, 0, 0);
  pSupportLevelsGridLayout->addWidget(mpSupportCheckBox, 0, 1);
  pSupportLevelsGridLayout->addWidget(mpExperimentalCheckBox, 1, 0);
  pSupportLevelsGridLayout->addWidget(mpObsoleteCheckBox, 1, 1);
  pSupportLevelsGridLayout->addWidget(mpNoSupportCheckBox, 2, 0, 1, 2);
  pSupportLevelsGroupBox->setLayout(pSupportLevelsGridLayout);
  // name combobox
  mpNameComboBox = new QComboBox;
  connect(mpNameComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(libraryIndexChanged(QString)));
  // source label
  mpSourceLabel = new Label;
  mpSourceLabel->setOpenExternalLinks(true);
  mpSourceLabel->setTextInteractionFlags(Qt::TextBrowserInteraction);
  // version combobox
  mpVersionComboBox = new QComboBox;
  // fetch libraries
  QString indexFilePath = QString("%1/.openmodelica/libraries/index.json").arg(Helper::userHomeDirectory);
  // update the package index
  MainWindow::instance()->getOMCProxy()->updatePackageIndex();
  if (QFile::exists(indexFilePath)) {
    if (mIndexJsonDocument.parse(indexFilePath)) {
      QVariantMap result = mIndexJsonDocument.result.toMap();
      mLibrariesMap = result["libs"].toMap();
      for (QVariantMap::const_iterator librariesIterator = mLibrariesMap.begin(); librariesIterator != mLibrariesMap.end(); ++librariesIterator) {
        const QString library = librariesIterator.key();
        QStringList versions = MainWindow::instance()->getOMCProxy()->getAvailablePackageVersions(library, "");
        mLibrariesAndVersionsMap.insert(library, versions);
      }
    }
  } else {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Package index file <b>%1</b> doesn't exist.").arg(indexFilePath), Helper::ok);
  }
  // exact match checkbox
  mpExactMatchCheckBox = new QCheckBox(tr("Exact Match (Install only the specified version of dependencies)"));
  mpExactMatchCheckBox->setChecked(true);
  // Progress label & bar
  mpProgressLabel = new Label(tr("<b>Installing library. Please wait.</b>"));
  mpProgressLabel->hide();
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

  filterChanged(true);
  // layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  int row = 0;
  pMainGridLayout->setAlignment(Qt::AlignTop);
  pMainGridLayout->addWidget(pHeadingLabel, row++, 0, 1, 2);
  pMainGridLayout->addWidget(Utilities::getHeadingLine(), row++, 0, 1, 2);
  pMainGridLayout->addWidget(pSupportLevelsGroupBox, row++, 0, 1, 2);
  pMainGridLayout->addWidget(new Label(Helper::name), row, 0);
  pMainGridLayout->addWidget(mpNameComboBox, row++, 1);
  pMainGridLayout->addWidget(new Label(Helper::versionLabel), row, 0);
  pMainGridLayout->addWidget(mpVersionComboBox, row++, 1);
  pMainGridLayout->addWidget(mpSourceLabel, row++, 0, 1, 2);
  pMainGridLayout->addWidget(mpExactMatchCheckBox, row++, 0, 1, 2);
  pMainGridLayout->addWidget(mpProgressLabel, row, 0);
  pMainGridLayout->addWidget(mpButtonBox, row++, 1, Qt::AlignRight);
  setLayout(pMainGridLayout);
}

/*!
 * \brief InstallLibraryDialog::filterChanged
 * Updates the version combobox when any filter changes.
 * \param checked
 */
void InstallLibraryDialog::filterChanged(bool checked)
{
  Q_UNUSED(checked);

  mpNameComboBox->clear();
  mFilteredLibrariesMap.clear();

  for (QVariantMap::const_iterator librariesIterator = mLibrariesMap.begin(); librariesIterator != mLibrariesMap.end(); ++librariesIterator) {
    const QString library = librariesIterator.key();

    QVariantMap libraryMap = mLibrariesMap[library].toMap();
    QVariantMap libraryVersionsMap = libraryMap["versions"].toMap();
    QStringList versions = mLibrariesAndVersionsMap[library];
    QStringList filteredVersions = versions;
    QStringList supportList;
    QStringList providesList;

    if (mpFullSupportCheckBox->isChecked()) {
      supportList.append("fullSupport");
    }
    if (mpSupportCheckBox->isChecked()) {
      supportList.append("support");
    }
    if (mpExperimentalCheckBox->isChecked()) {
      supportList.append("experimental");
    }
    if (mpObsoleteCheckBox->isChecked()) {
      supportList.append("obsolete");
    }
    if (mpNoSupportCheckBox->isChecked()) {
      supportList.append("noSupport");
    }

    foreach (QString version, versions) {
      QVariantMap libraryVersionMap = libraryVersionsMap[version].toMap();
      QList<QVariant> provides = libraryVersionMap["provides"].toList();
      foreach (QVariant provide, provides) {
        providesList.append(provide.toString());
      }
      // support filter
      QString support = libraryVersionMap["support"].toString();
      if (!supportList.isEmpty() && !supportList.contains(support)) {
        filteredVersions.removeOne(version);
      }
    }

    filteredVersions.removeDuplicates();

    if (!filteredVersions.isEmpty()) {
      mpNameComboBox->addItem(library);
      FilteredLibrary filteredLibrary;
      filteredLibrary.source = libraryMap["git"].toString();
      filteredLibrary.versions = filteredVersions;
      mFilteredLibrariesMap.insert(library, filteredLibrary);
    }
  }

  libraryIndexChanged(mpNameComboBox->currentText());
}

/*!
 * \brief InstallLibraryDialog::libraryIndexChanged
 * Fills the version combobox when the library is changed.
 * \param text
 */
void InstallLibraryDialog::libraryIndexChanged(const QString &text)
{
  mpSourceLabel->clear();
  mpVersionComboBox->clear();

  if (text.isEmpty()) {
    mpOkButton->setEnabled(false);
  } else {
    FilteredLibrary filteredLibrary = mFilteredLibrariesMap[text];
    mpSourceLabel->setText(QString("<a href=\"%1\">%1</a>").arg(filteredLibrary.source));
    mpVersionComboBox->addItems(filteredLibrary.versions);
    mpOkButton->setEnabled(true);
  }
}

/*!
 * \brief InstallLibraryDialog::installLibrary
 * Installs the library.
 */
void InstallLibraryDialog::installLibrary()
{
  mpProgressLabel->show();
  mpOkButton->setEnabled(false);
  repaint(); // repaint the dialog so progresslabel is updated.
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
    mpProgressLabel->hide();
    mpOkButton->setEnabled(true);
  }
}
