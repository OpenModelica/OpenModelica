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

#include "HomotopyTest.h"
#include "Util.h"
#include "OMEditApplication.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Simulation/SimulationOutputWidget.h"

#ifndef GC_THREADS
#define GC_THREADS
#endif
extern "C" {
#include "meta/meta_modelica.h"
}

OMEDITTEST_MAIN(HomotopyTest)

void HomotopyTest::initTestCase()
{
  MainWindow::instance()->getLibraryWidget()->openFile(QFINDTESTDATA("HomotopyTest.mo"));
}

void HomotopyTest::simulateHomotopyTestM1()
{
  simulate(QStringLiteral("HomotopyTest.M1"));
}

void HomotopyTest::simulateHomotopyTestM2()
{
  simulate(QStringLiteral("HomotopyTest.M2"));
}

void HomotopyTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}

void HomotopyTest::simulate(const QString &className)
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
  if (!Util::expandLibraryTreeItemParentHierarchy(pLibraryTreeItem)) {
    QFAIL(QString("Expanding to %1 failed.").arg(className).toStdString().c_str());
  }

  MainWindow::instance()->simulate(pLibraryTreeItem);
  SimulationOutputWidget *pSimulationOutputWidget = MessagesWidget::instance()->getSimulationOutputWidget(className);
  if (pSimulationOutputWidget) {
    if (pSimulationOutputWidget->getSimulationOptions().getClassName().compare(className) == 0) {
      QString simulationLogFileName = QString("%1/%2.log").arg(pSimulationOutputWidget->getSimulationOptions().getWorkingDirectory())
                                      .arg(pSimulationOutputWidget->getSimulationOptions().getOutputFileName());
      /* Use QSignalSpy to check if simulation is finished or not.
       * if its finished then we read the simulation file.
       * otherwise the timeout of 5 mins has occurred.
       */
      QSignalSpy simulationSignalSpy(pSimulationOutputWidget, SIGNAL(simulationFinished()));
      if (simulationSignalSpy.wait(300000)) {
        readSimulationLogFile(simulationLogFileName);
      } else {
        QFAIL("Simulation not finished in time.");
      }
    } else {
      QFAIL(QString("Wrong class name. Expected %1 got %2.").arg(className, pSimulationOutputWidget->getSimulationOptions().getClassName()).toStdString().c_str());
    }
  } else {
    QFAIL(QString("Translation of %1 failed.").arg(className).toStdString().c_str());
  }
}

void HomotopyTest::readSimulationLogFile(const QString &simulationLogFilePath)
{
  // read the simulation log file for error message.
  QFile simulationLogFile(simulationLogFilePath);
  if (!simulationLogFile.open(QIODevice::ReadOnly)) {
    QFAIL(QString("Unable to open the simulation log file %1.").arg(simulationLogFilePath).toStdString().c_str());
  } else {
    QString contents = QString(simulationLogFile.readAll());
    simulationLogFile.close();
    if (!contents.contains(QStringLiteral("simulation terminated by an assertion at initialization"))) {
      qDebug() << contents;
      QFAIL("Failed to find the expected output in the simulation log file i.e., simulation terminated by an assertion at initialization");
    }
  }
}
