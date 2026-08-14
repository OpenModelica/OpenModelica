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

#include "TabbedViewTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include <QApplication>
#include <QMouseEvent>

OMEDITTEST_MAIN(TabbedViewTest)

void TabbedViewTest::initTestCase()
{
  // load TabbedViewTest.mo
  const QString tabbedViewTestFileName = QFINDTESTDATA("TabbedViewTest.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(tabbedViewTestFileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("TabbedViewTest")) {
    QFAIL(QString("Failed to load file %1").arg(tabbedViewTestFileName).toStdString().c_str());
  }
  // Make sure the modeling view is in tabbed mode.
  MainWindow::switchToTabbedMode(MainWindow::instance()->getModelWidgetContainer());
  QApplication::processEvents();
}

void TabbedViewTest::middleClickClosesOnlyClickedTab()
{
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pLibraryTreeItem1 = pLibraryTreeModel->findLibraryTreeItem("TabbedViewTest.Model1");
  LibraryTreeItem *pLibraryTreeItem2 = pLibraryTreeModel->findLibraryTreeItem("TabbedViewTest.Model2");
  if (!pLibraryTreeItem1 || !pLibraryTreeItem2) {
    QFAIL("Failed to find the test models.");
  }
  pLibraryTreeModel->showModelWidget(pLibraryTreeItem1);
  pLibraryTreeModel->showModelWidget(pLibraryTreeItem2);
  QApplication::processEvents();

  ModelWidgetContainer *pModelWidgetContainer = MainWindow::instance()->getModelWidgetContainer();
  if (pModelWidgetContainer->subWindowList().size() != 2) {
    QFAIL("Expected two open model widgets.");
  }

  QTabBar *pTabBar = pModelWidgetContainer->findChild<QTabBar*>(QString(), Qt::FindDirectChildrenOnly);
  if (!pTabBar) {
    QFAIL("Failed to find the tab bar.");
  }
  if (pTabBar->count() != 2) {
    QFAIL("Expected two tabs.");
  }
  QRect firstTabRect = pTabBar->tabRect(0);
  if (firstTabRect.isEmpty()) {
    QFAIL("The tab bar is not laid out.");
  }

  // Simulate a middle click (press and release) on the first tab.
  QPoint clickPos = firstTabRect.center();
  QMouseEvent pressEvent(QEvent::MouseButtonPress, QPointF(clickPos), QPointF(clickPos), QPointF(pTabBar->mapToGlobal(clickPos)), Qt::MiddleButton, Qt::MiddleButton, Qt::NoModifier);
  QApplication::sendEvent(pTabBar, &pressEvent);
  QApplication::processEvents();
  QMouseEvent releaseEvent(QEvent::MouseButtonRelease, QPointF(clickPos), QPointF(clickPos), QPointF(pTabBar->mapToGlobal(clickPos)), Qt::MiddleButton, Qt::NoButton, Qt::NoModifier);
  QApplication::sendEvent(pTabBar, &releaseEvent);
  QApplication::processEvents();

  // Only the clicked tab should have been closed (issue #16264).
  if (pModelWidgetContainer->subWindowList().size() != 1) {
    QFAIL("Middle click should have closed only the clicked tab.");
  }
  QMdiSubWindow *pMdiSubWindow = pModelWidgetContainer->subWindowList().at(0);
  if (!pMdiSubWindow || pMdiSubWindow->widget() != pLibraryTreeItem2->getModelWidget()) {
    QFAIL("The remaining tab should be the second model.");
  }
}

void TabbedViewTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
