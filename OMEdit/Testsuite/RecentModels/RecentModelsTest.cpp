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

#include "RecentModelsTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"

OMEDITTEST_MAIN(RecentModelsTest)

static QString testFile()
{
  return QFINDTESTDATA("RecentModelsTest.mo");
}

void RecentModelsTest::initTestCase()
{
  QSettings *pSettings = Utilities::getApplicationSettings();
  // remember the lists of the user running the test, they are restored in cleanupTestCase().
  mRecentFiles = pSettings->value("recentFilesList/files").toList();
  mRecentModels = pSettings->value("recentModelsList/models").toList();
  pSettings->remove("recentFilesList/files");
  pSettings->remove("recentModelsList/models");
  MainWindow::instance()->updateRecentFileActionsAndList();
  MainWindow::instance()->updateRecentModelActionsAndList();
}

/*!
 * \brief RecentModelsTest::openFileAddsRecentFileOnly
 * Opening a file adds it to the recent files list and leaves the recent models list alone.
 */
void RecentModelsTest::openFileAddsRecentFileOnly()
{
  MainWindow::instance()->getLibraryWidget()->openFile(testFile(), Helper::utf8, false, true);
  QVERIFY(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem("RecentModelsTest.M"));
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> files = pSettings->value("recentFilesList/files").toList();
  QCOMPARE(files.size(), 1);
  QCOMPARE(qvariant_cast<RecentFile>(files[0]).fileName, testFile());
  QCOMPARE(pSettings->value("recentModelsList/models").toList().size(), 0);
}

/*!
 * \brief RecentModelsTest::addRecentModelKeepsListsSeparate
 * A recent model stores the class name and the file of its top level class and does not
 * end up in the recent files list.
 */
void RecentModelsTest::addRecentModelKeepsListsSeparate()
{
  MainWindow::instance()->addRecentModel("RecentModelsTest.M");
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> models = pSettings->value("recentModelsList/models").toList();
  QCOMPARE(models.size(), 1);
  RecentFile recentModel = qvariant_cast<RecentFile>(models[0]);
  QCOMPARE(recentModel.fileName, QString("RecentModelsTest.M"));
  QCOMPARE(recentModel.path, testFile());
  QCOMPARE(pSettings->value("recentFilesList/files").toList().size(), 1);
}

/*!
 * \brief RecentModelsTest::showRecentModelLoadsTheLibrary
 * Opening a recent model of a class that is not loaded, loads the stored file first and
 * does not add that file to the recent files list.
 */
void RecentModelsTest::showRecentModelLoadsTheLibrary()
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem("RecentModelsTest");
  QVERIFY(pLibraryTreeItem);
  QVERIFY(pLibraryTreeModel->unloadLibraryTreeItem(pLibraryTreeItem, true));
  QVERIFY(!pLibraryTreeModel->findLibraryTreeItem("RecentModelsTest.M"));
  MainWindow::instance()->showRecentModel("RecentModelsTest.M", Helper::utf8, testFile());
  QVERIFY(pLibraryTreeModel->findLibraryTreeItem("RecentModelsTest.M"));
  QCOMPARE(Utilities::getApplicationSettings()->value("recentFilesList/files").toList().size(), 1);
}

/*!
 * \brief RecentModelsTest::closingAddsOpenModels
 * The models open in the model view are added to the recent models list when OMEdit is closed.
 */
void RecentModelsTest::closingAddsOpenModels()
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem("RecentModelsTest.M");
  QVERIFY(pLibraryTreeItem);
  pLibraryTreeModel->showModelWidget(pLibraryTreeItem);
  // start from an empty recent models list so that the entry can only come from closing
  QSettings *pSettings = Utilities::getApplicationSettings();
  pSettings->remove("recentModelsList/models");
  MainWindow::instance()->updateRecentModelActionsAndList();
  // beforeClosingMainWindow() deletes the application settings object, read the settings again afterwards.
  MainWindow::instance()->beforeClosingMainWindow();
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  QList<QVariant> models = settings.value("recentModelsList/models").toList();
  QCOMPARE(models.size(), 1);
  QCOMPARE(qvariant_cast<RecentFile>(models[0]).fileName, QString("RecentModelsTest.M"));
  QCOMPARE(qvariant_cast<RecentFile>(models[0]).path, testFile());
  QCOMPARE(settings.value("recentFilesList/files").toList().size(), 1);
}

void RecentModelsTest::cleanupTestCase()
{
  // the application settings object is gone at this point, write the lists back with a new one.
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  if (mRecentFiles.isEmpty()) {
    settings.remove("recentFilesList/files");
  } else {
    settings.setValue("recentFilesList/files", mRecentFiles);
  }
  if (mRecentModels.isEmpty()) {
    settings.remove("recentModelsList/models");
  } else {
    settings.setValue("recentModelsList/models", mRecentModels);
  }
}
