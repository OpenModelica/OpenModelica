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

#include "SimulationIntervalTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/MessagesWidget.h"
#include "Options/OptionsDialog.h"
#include "Simulation/SimulationOutputWidget.h"

OMEDITTEST_MAIN(SimulationIntervalTest)

void SimulationIntervalTest::initTestCase()
{
  const QString fileName = QFINDTESTDATA("SimulationIntervalTest.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(fileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("SimulationIntervalTest")) {
    QFAIL(QString("Failed to load file %1").arg(fileName).toStdString().c_str());
  }
}

void SimulationIntervalTest::simulateWithChangedStopTime()
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem("SimulationIntervalTest");
  if (!pLibraryTreeItem) {
    QFAIL("Failed to find the library tree item for SimulationIntervalTest.");
  }
  // The simulation dialog selects Interval only if the class has a model widget.
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  OptionsDialog::instance()->getSimulationPage()->getCloseSimulationOutputWidgetsBeforeSimulationCheckBox()->setChecked(true);
  simulate(pLibraryTreeItem, "1.2");
  if (QTest::currentTestFailed()) {
    return;
  }
  // 0.3 does not divide the new stopTime - startTime.
  pLibraryTreeItem->mSimulationOptions.setStopTime("1");
  simulate(pLibraryTreeItem, "1");
}

void SimulationIntervalTest::simulate(LibraryTreeItem *pLibraryTreeItem, const QString &stopTime)
{
  MainWindow::instance()->simulate(pLibraryTreeItem);
  SimulationOutputWidget *pSimulationOutputWidget = MessagesWidget::instance()->getSimulationOutputWidget(pLibraryTreeItem->getNameStructure());
  QVERIFY2(pSimulationOutputWidget && pSimulationOutputWidget->getSimulationOptions().getStopTime() == stopTime,
           qPrintable(QString("Translation with stopTime %1 failed.").arg(stopTime)));
  QCOMPARE(pSimulationOutputWidget->getSimulationOptions().getStepSize(), 0.3);
  QSignalSpy simulationSignalSpy(pSimulationOutputWidget, &SimulationOutputWidget::simulationFinished);
  QVERIFY2(simulationSignalSpy.wait(300000), "Simulation not finished in time.");
  const SimulationOptions &simulationOptions = pSimulationOutputWidget->getSimulationOptions();
  const QString resultFile = QString("%1/%2").arg(simulationOptions.getWorkingDirectory(), simulationOptions.getFullResultFileName());
  QVERIFY2(QFile::exists(resultFile), qPrintable(QString("The result file %1 does not exist.").arg(resultFile)));
}

void SimulationIntervalTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
