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
#include "Simulation/SimulationDialog.h"
#include "Simulation/SimulationOutputWidget.h"
#include "Simulation/SimulationProcessThread.h"

#define GC_THREADS
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
  mCompilationFinished = false;
  mSimulationLogFileName = "";
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(QStringLiteral("HomotopyTest.M1"));
  if (!Util::expandLibraryTreeItemParentHierarchy(pLibraryTreeItem)) {
    QFAIL("Expanding to HomotopyTest.M1 failed.");
  }

  MainWindow::instance()->simulate(pLibraryTreeItem);
  if (MainWindow::instance()->getSimulationDialog()->getSimulationOutputWidgetsList().size() > 0) {
    SimulationOutputWidget *pSimulationOutputWidget = MainWindow::instance()->getSimulationDialog()->getSimulationOutputWidgetsList().last();
    if (pSimulationOutputWidget->getSimulationOptions().getClassName().compare(QStringLiteral("HomotopyTest.M1")) == 0) {
      mSimulationLogFileName = QString("%1/%2.log").arg(pSimulationOutputWidget->getSimulationOptions().getWorkingDirectory())
                               .arg(pSimulationOutputWidget->getSimulationOptions().getClassName());
      connect(pSimulationOutputWidget->getSimulationProcessThread(), SIGNAL(sendCompilationFinished(int,QProcess::ExitStatus)), SLOT(compilationFinished(int,QProcess::ExitStatus)));
      connect(pSimulationOutputWidget->getSimulationProcessThread(), SIGNAL(sendSimulationFinished(int,QProcess::ExitStatus)), SLOT(simulationFinished(int,QProcess::ExitStatus)));
      // wait for compilation
      QEventLoop compilationEventLoop;
      connect(pSimulationOutputWidget->getSimulationProcessThread(), SIGNAL(sendCompilationFinished(int,QProcess::ExitStatus)), &compilationEventLoop, SLOT(quit()));
      compilationEventLoop.exec();
      if (mCompilationFinished) {
        // wait for simulation
        QEventLoop simulationEventLoop;
        connect(pSimulationOutputWidget->getSimulationProcessThread(), SIGNAL(sendSimulationFinished(int,QProcess::ExitStatus)), &simulationEventLoop, SLOT(quit()));
        simulationEventLoop.exec();
      }
    } else {
      QFAIL(QString("Wrong class name. Expected HomotopyTest.M1 got %1.").arg(pSimulationOutputWidget->getSimulationOptions().getClassName()).toStdString().c_str());
    }
  } else {
    QFAIL("Translation of HomotopyTest.M1 failed.");
  }
}

void HomotopyTest::simulateHomotopyTestM2()
{
  mCompilationFinished = false;
  mSimulationLogFileName = "";
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(QStringLiteral("HomotopyTest.M2"));
  if (!Util::expandLibraryTreeItemParentHierarchy(pLibraryTreeItem)) {
    QFAIL("Expanding to HomotopyTest.M2 failed.");
  }

  MainWindow::instance()->simulate(pLibraryTreeItem);
  if (MainWindow::instance()->getSimulationDialog()->getSimulationOutputWidgetsList().size() > 1) {
    SimulationOutputWidget *pSimulationOutputWidget = MainWindow::instance()->getSimulationDialog()->getSimulationOutputWidgetsList().last();
    if (pSimulationOutputWidget->getSimulationOptions().getClassName().compare(QStringLiteral("HomotopyTest.M2")) == 0) {
      mSimulationLogFileName = QString("%1/%2.log").arg(pSimulationOutputWidget->getSimulationOptions().getWorkingDirectory())
                               .arg(pSimulationOutputWidget->getSimulationOptions().getClassName());
      connect(pSimulationOutputWidget->getSimulationProcessThread(), SIGNAL(sendCompilationFinished(int,QProcess::ExitStatus)), SLOT(compilationFinished(int,QProcess::ExitStatus)));
      connect(pSimulationOutputWidget->getSimulationProcessThread(), SIGNAL(sendSimulationFinished(int,QProcess::ExitStatus)), SLOT(simulationFinished(int,QProcess::ExitStatus)));
      // wait for compilation
      QEventLoop compilationEventLoop;
      connect(pSimulationOutputWidget->getSimulationProcessThread(), SIGNAL(sendCompilationFinished(int,QProcess::ExitStatus)), &compilationEventLoop, SLOT(quit()));
      compilationEventLoop.exec();
      if (mCompilationFinished) {
        // wait for simulation
        QEventLoop simulationEventLoop;
        connect(pSimulationOutputWidget->getSimulationProcessThread(), SIGNAL(sendSimulationFinished(int,QProcess::ExitStatus)), &simulationEventLoop, SLOT(quit()));
        simulationEventLoop.exec();
      }
    } else {
      QFAIL(QString("Wrong class name. Expected HomotopyTest.M2 got %1.").arg(pSimulationOutputWidget->getSimulationOptions().getClassName()).toStdString().c_str());
    }
  } else {
    QFAIL("Translation of HomotopyTest.M2 failed.");
  }
}

void HomotopyTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}

void HomotopyTest::compilationFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  if (!(exitStatus == QProcess::NormalExit && exitCode == 0)) {
    QString exitCodeStr = tr("Compilation process failed. Exited with code %1.").arg(QString::number(exitCode));
    QFAIL(exitCodeStr.toStdString().c_str());
  }
  mCompilationFinished = true;
}

void HomotopyTest::simulationFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    QString exitCodeStr = tr("Simulation process finished successfully. It should fail instead. Exited with code %1.").arg(QString::number(exitCode));
    QFAIL(exitCodeStr.toStdString().c_str());
  }

  // read the simulation log file for error message.
  QFile simulationLogFile(mSimulationLogFileName);
  if (!simulationLogFile.open(QIODevice::ReadOnly)) {
    QFAIL(QString("Unable to open the simulation log file %1.").arg(mSimulationLogFileName).toStdString().c_str());
  } else {
    QString contents = QString(simulationLogFile.readAll());
    simulationLogFile.close();
    if (!contents.contains(QStringLiteral("simulation terminated by an assertion at initialization"))) {
      QFAIL("Failed to find the expected output in the simulation log file i.e., simulation terminated by an assertion at initialization");
    }
  }
}
