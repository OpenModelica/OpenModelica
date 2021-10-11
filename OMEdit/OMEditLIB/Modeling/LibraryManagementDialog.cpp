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

#include "LibraryManagementDialog.h"
#include "MainWindow.h"
#include "OMC/OMCProxy.h"
#include "Modeling/MessagesWidget.h"

#include <QVBoxLayout>
#include <QMessageBox>

LibraryManagementDialog::LibraryManagementDialog(QWidget *parent)
  : QDialog(parent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Library Management")));
  // installed libraries
  Label *pInstalledLibrariesHeading = Utilities::getHeadingLabel(tr("Installed Libraries"));
  pInstalledLibrariesHeading->setElideMode(Qt::ElideMiddle);
  Label *pInstalledLibrariesDescriptionLabel = new Label(tr("Double click to load the library."));
  mpInstalledLibrariesTreeWidget = new QTreeWidget;
  mpInstalledLibrariesTreeWidget->setIndentation(0);
  mpInstalledLibrariesTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpInstalledLibrariesTreeWidget->setHeaderLabels(QStringList() << Helper::name << Helper::version);
  connect(mpInstalledLibrariesTreeWidget, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(loadInstalledLibrary(QTreeWidgetItem*,int)));
  fetchInstalledLibraries();
  // not installed libraries.
  Label *pNotInstalledLibrariesHeading = Utilities::getHeadingLabel(tr("Not Installed Libraries"));
  pNotInstalledLibrariesHeading->setElideMode(Qt::ElideMiddle);
  Label *pNotInstalledLibrariesDescriptionLabel = new Label(tr("Double click to install the library."));
  mpNotInstalledLibrariesTreeWidget = new QTreeWidget;
  mpNotInstalledLibrariesTreeWidget->setIndentation(0);
  mpNotInstalledLibrariesTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpNotInstalledLibrariesTreeWidget->setHeaderLabels(QStringList() << Helper::name << Helper::version << tr("Exact Match"));
  connect(mpNotInstalledLibrariesTreeWidget, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(installLibrary(QTreeWidgetItem*,int)));
  fetchNotInstalledLibraries();
  // layout
  QVBoxLayout *pMainVBoxLayout = new QVBoxLayout;
  pMainVBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainVBoxLayout->addWidget(pInstalledLibrariesHeading);
  pMainVBoxLayout->addWidget(Utilities::getHeadingLine());
  pMainVBoxLayout->addWidget(pInstalledLibrariesDescriptionLabel);
  pMainVBoxLayout->addWidget(mpInstalledLibrariesTreeWidget);
  pMainVBoxLayout->addWidget(pNotInstalledLibrariesHeading);
  pMainVBoxLayout->addWidget(Utilities::getHeadingLine());
  pMainVBoxLayout->addWidget(pNotInstalledLibrariesDescriptionLabel);
  pMainVBoxLayout->addWidget(mpNotInstalledLibrariesTreeWidget);
  setLayout(pMainVBoxLayout);
}

void removeTreeWidgetItems(QTreeWidget *pTreeWidget)
{
  int i = 0;
  while(i < pTreeWidget->topLevelItemCount()) {
    qDeleteAll(pTreeWidget->topLevelItem(i)->takeChildren());
    delete pTreeWidget->topLevelItem(i);
    i = 0;   //Restart iteration
  }
}

/*!
 * \brief LibraryManagementDialog::fetchInstalledLibraries
 * Fetches the installed libraries.
 */
void LibraryManagementDialog::fetchInstalledLibraries()
{
  mpInstalledLibrariesTreeWidget->setSortingEnabled(false);
  removeTreeWidgetItems(mpInstalledLibrariesTreeWidget);

  QList<QList<QString> > availableLibrariesAndVersions = MainWindow::instance()->getOMCProxy()->getAvailableLibrariesAndVersions();
  foreach (QStringList availableLibraryAndVersions, availableLibrariesAndVersions) {
    if (availableLibraryAndVersions.size() > 1) {
      mpInstalledLibrariesTreeWidget->addTopLevelItem(new QTreeWidgetItem(QStringList() << availableLibraryAndVersions.at(0) << availableLibraryAndVersions.at(1)));
    }
    for (int i = 2 ; i < availableLibraryAndVersions.size() ; i++) {
      mpInstalledLibrariesTreeWidget->addTopLevelItem(new QTreeWidgetItem(QStringList() << availableLibraryAndVersions.at(0) << availableLibraryAndVersions.at(i)));
    }
  }

  mpInstalledLibrariesTreeWidget->setSortingEnabled(true);
  mpInstalledLibrariesTreeWidget->sortByColumn(0, Qt::AscendingOrder);
}

/*!
 * \brief LibraryManagementDialog::fetchNotInstalledLibraries
 * Fetches not installed libraries.
 */
void LibraryManagementDialog::fetchNotInstalledLibraries()
{
  mpNotInstalledLibrariesTreeWidget->setSortingEnabled(false);
  removeTreeWidgetItems(mpNotInstalledLibrariesTreeWidget);

  QString indexFilePath = QString("%1/.openmodelica/libraries/index.json").arg(Helper::userHomeDirectory);
  if (!QFile::exists(indexFilePath) && !MainWindow::instance()->getOMCProxy()->updatePackageIndex()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Package index file <b>%1</b> doesn't exist.").arg(indexFilePath),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }

  JsonDocument jsonDocument;
  if (jsonDocument.parse(indexFilePath)) {
    QVariantMap result = jsonDocument.result.toMap();
    QVariantMap libraries = result["libs"].toMap();
    for (QVariantMap::const_iterator librariesIterator = libraries.begin(); librariesIterator != libraries.end(); ++librariesIterator) {
      QVariantMap libraryMap = librariesIterator.value().toMap();
      QVariantMap libraryVersionsMap = libraryMap["versions"].toMap();
      for (QVariantMap::const_iterator versionsIterator = libraryVersionsMap.begin(); versionsIterator != libraryVersionsMap.end(); ++versionsIterator) {
        QTreeWidgetItem *pTreeWidgetItem = new QTreeWidgetItem;
        pTreeWidgetItem->setText(0, librariesIterator.key());
        pTreeWidgetItem->setText(1, versionsIterator.key());
        pTreeWidgetItem->setCheckState(2, Qt::Unchecked);
        mpNotInstalledLibrariesTreeWidget->addTopLevelItem(pTreeWidgetItem);
      }
    }
  }

  mpNotInstalledLibrariesTreeWidget->setSortingEnabled(true);
  mpNotInstalledLibrariesTreeWidget->sortByColumn(0, Qt::AscendingOrder);
}

/*!
 * \brief LibraryManagementDialog::loadInstalledLibrary
 * Loads the installed library.
 * \param pTreeWidgetItem
 * \param column
 */
void LibraryManagementDialog::loadInstalledLibrary(QTreeWidgetItem *pTreeWidgetItem, int column)
{
  Q_UNUSED(column);
  MainWindow::instance()->loadSystemLibrary(pTreeWidgetItem->text(0), pTreeWidgetItem->text(1));
  QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::information),
                           tr("The library <b>%1</b> should be loaded. See Messages Browser for any possible messages.").arg(pTreeWidgetItem->text(0)), Helper::ok);
}

/*!
 * \brief LibraryManagementDialog::installLibrary
 * Installs the library.
 * \param pTreeWidgetItem
 * \param column
 */
void LibraryManagementDialog::installLibrary(QTreeWidgetItem *pTreeWidgetItem, int column)
{
  Q_UNUSED(column);
  QString library = pTreeWidgetItem->text(0);
  QString version = pTreeWidgetItem->text(1);
  bool exactMatch = pTreeWidgetItem->checkState(2);

  if (MainWindow::instance()->getOMCProxy()->installPackage(library, version, exactMatch)) {
    MainWindow::instance()->getOMCProxy()->updatePackageIndex();
    fetchInstalledLibraries();
    fetchNotInstalledLibraries();
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::information),
                             tr("The library <b>%1</b> is installed. Load the library from the list of installed library.").arg(pTreeWidgetItem->text(0)), Helper::ok);
  } else {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          tr("The library <b>%1</b> is not installed. See Messages Browser for any possible messages.").arg(pTreeWidgetItem->text(0)), Helper::ok);
  }
}
