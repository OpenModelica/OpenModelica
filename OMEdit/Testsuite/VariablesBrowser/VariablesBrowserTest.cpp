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

#include "VariablesBrowserTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "OMC/OMCProxy.h"
#include "Plotting/VariablesWidget.h"

OMEDITTEST_MAIN(VariablesBrowserTest)

void VariablesBrowserTest::arrayVariables()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QTemporaryDir workingDirectory;
  QVERIFY(workingDirectory.isValid());
  pOMCProxy->changeDirectory(workingDirectory.path());

  const QString model = "model ArrayVariablesTest\n"
                        "  parameter Integer N = 3;\n"
                        "  Real x[N](each start = 1, each fixed = true) \"Array of states\";\n"
                        "  Real y \"Scalar\";\n"
                        "equation\n"
                        "  for i in 1:N loop\n"
                        "    der(x[i]) = -i*x[i];\n"
                        "  end for;\n"
                        "  y = sum(x);\n"
                        "end ArrayVariablesTest;\n";
  QVERIFY(pOMCProxy->loadString(model, "ArrayVariablesTest.mo"));
  QVERIFY(pOMCProxy->setCommandLineOptions("--newBackend --simCodeScalarize=false"));
  pOMCProxy->sendCommand("simulate(ArrayVariablesTest, stopTime=0.1)");
  const QString simulationResult = pOMCProxy->getResult();
  pOMCProxy->sendCommand("clearCommandLineOptions()");
  QVERIFY2(QFile::exists(workingDirectory.filePath("ArrayVariablesTest_res.mat")), qPrintable(simulationResult + pOMCProxy->getErrorString()));

  // make sure the test covers the ArrayVariable case
  QFile initFile(workingDirectory.filePath("ArrayVariablesTest_init.xml"));
  QVERIFY(initFile.open(QIODevice::ReadOnly));
  QVERIFY(initFile.readAll().contains("<ArrayVariable"));
  initFile.close();

  VariablesWidget *pVariablesWidget = MainWindow::instance()->getVariablesWidget();
  pVariablesWidget->insertVariablesItemsToTree("ArrayVariablesTest_res.mat", workingDirectory.path(), QStringList(), SimulationOptions());
  VariablesTreeModel *pVariablesTreeModel = pVariablesWidget->getVariablesTreeModel();

  foreach (QString variable, QStringList() << "y" << "x[1]" << "x[3]") {
    VariablesTreeItem *pVariablesTreeItem = pVariablesTreeModel->findVariablesTreeItem("ArrayVariablesTest_res.mat." + variable, pVariablesTreeModel->getRootVariablesTreeItem());
    QVERIFY2(pVariablesTreeItem, qPrintable("Variable " + variable + " is not in the Variables Browser."));
    QVERIFY(pVariablesTreeItem->getExistInResultFile());
  }
  VariablesTreeItem *pVariablesTreeItem = pVariablesTreeModel->findVariablesTreeItem("ArrayVariablesTest_res.mat.x[2]", pVariablesTreeModel->getRootVariablesTreeItem());
  QVERIFY(pVariablesTreeItem);
  QCOMPARE(pVariablesTreeItem->getDescription(), QString("Array of states"));
  QVERIFY(!pVariablesTreeItem->isEditable());
}

void VariablesBrowserTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
