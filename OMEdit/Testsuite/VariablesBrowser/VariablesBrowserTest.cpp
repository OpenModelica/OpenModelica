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
#include "OMPlot.h"
#include "PlotWindow.h"
#include "PlotCurve.h"

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

void VariablesBrowserTest::valueLabels()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QTemporaryDir workingDirectory;
  QVERIFY(workingDirectory.isValid());
  pOMCProxy->changeDirectory(workingDirectory.path());

  const QString model = "model ValueLabelsTest\n"
                        "  type Mode = enumeration(Off, Heat, Cool);\n"
                        "  Mode m;\n"
                        "  Boolean b;\n"
                        "  Integer i;\n"
                        "  Real x;\n"
                        "equation\n"
                        "  m = if time < 0.5 then Mode.Off else Mode.Cool;\n"
                        "  b = time > 0.5;\n"
                        "  i = if b then 2 else 1;\n"
                        "  x = time;\n"
                        "end ValueLabelsTest;\n";
  QVERIFY(pOMCProxy->loadString(model, "ValueLabelsTest.mo"));
  const QStringList modeLabels = QStringList() << "Off" << "Heat" << "Cool";
  const QStringList booleanLabels = QStringList() << "false" << "true";

  // a .mat or .arrow result file names the values itself
  foreach (const QString &format, QStringList() << "arrow" << "mat") {
    const QString resultFile = workingDirectory.filePath("ValueLabelsTest_res." + format);
    pOMCProxy->sendCommand("simulate(ValueLabelsTest, stopTime=1, outputFormat=\"" + format + "\")");
    const QString simulationResult = pOMCProxy->getResult();
    QVERIFY2(QFile::exists(resultFile), qPrintable(simulationResult + pOMCProxy->getErrorString()));
    OMPlot::PlotWindow plotWindow;
    plotWindow.setPlotType(OMPlot::PlotWindow::PLOT);
    plotWindow.initializeFile(resultFile);
    plotWindow.setVariablesList(QStringList() << "m" << "b" << "x");
    plotWindow.plot();
    QHash<QString, OMPlot::PlotCurve*> curves;
    foreach (OMPlot::PlotCurve *pPlotCurve, plotWindow.getPlot()->getPlotCurvesList()) {
      curves.insert(pPlotCurve->getYVariable(), pPlotCurve);
    }
    QVERIFY2(curves.contains("m") && curves.contains("b") && curves.contains("x"), qPrintable(format));
    QCOMPARE(curves.value("m")->getValueLabels(), modeLabels);
    QCOMPARE(curves.value("m")->getValueLabelBase(), 1);
    QCOMPARE(curves.value("b")->getValueLabels(), booleanLabels);
    QCOMPARE(curves.value("b")->getValueLabelBase(), 0);
    QVERIFY(!curves.value("x")->hasValueLabels());
    QCOMPARE(curves.value("m")->valueText(3), QString("Cool"));
    QVERIFY(!plotWindow.getStackCurves());
  }

  // only Booleans, Integers and enumerations go in lanes, unless the toolbar says otherwise
  OMPlot::PlotWindow discretePlotWindow;
  discretePlotWindow.setPlotType(OMPlot::PlotWindow::PLOT);
  discretePlotWindow.initializeFile(workingDirectory.filePath("ValueLabelsTest_res.mat"));
  discretePlotWindow.setVariablesList(QStringList() << "m" << "b" << "i");
  discretePlotWindow.plot();
  QVERIFY(discretePlotWindow.getStackCurves());
  discretePlotWindow.updatePlot();
  foreach (OMPlot::PlotCurve *pPlotCurve, discretePlotWindow.getPlot()->getPlotCurvesList()) {
    QVERIFY(pPlotCurve->isDiscrete());
    QVERIFY(pPlotCurve->isStacked());
  }
  discretePlotWindow.setStackCurves(false);
  QVERIFY(!discretePlotWindow.getStackCurves());
  foreach (OMPlot::PlotCurve *pPlotCurve, discretePlotWindow.getPlot()->getPlotCurvesList()) {
    QVERIFY(!pPlotCurve->isStacked());
  }
}

void VariablesBrowserTest::resultFileUnits()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QTemporaryDir workingDirectory;
  QVERIFY(workingDirectory.isValid());
  pOMCProxy->changeDirectory(workingDirectory.path());

  const QString model = "model ResultFileUnitsTest\n"
                        "  parameter Real w(unit = \"rad/s\", displayUnit = \"rpm\") = 10;\n"
                        "  Real T(unit = \"K\", displayUnit = \"degC\", start = 300, fixed = true);\n"
                        "  Real v(unit = \"m/s\");\n"
                        "equation\n"
                        "  der(T) = 1;\n"
                        "  v = w*time;\n"
                        "end ResultFileUnitsTest;\n";
  QVERIFY(pOMCProxy->loadString(model, "ResultFileUnitsTest.mo"));
  pOMCProxy->sendCommand("simulate(ResultFileUnitsTest, stopTime=1)");
  const QString simulationResult = pOMCProxy->getResult();
  QVERIFY2(QFile::exists(workingDirectory.filePath("ResultFileUnitsTest_res.mat")), qPrintable(simulationResult + pOMCProxy->getErrorString()));
  QVERIFY(QFile::remove(workingDirectory.filePath("ResultFileUnitsTest_init.xml")));

  // as MainWindow::openResultFile does
  const QStringList variables = pOMCProxy->readSimulationResultVars(workingDirectory.filePath("ResultFileUnitsTest_res.mat"));
  VariablesWidget *pVariablesWidget = MainWindow::instance()->getVariablesWidget();
  pVariablesWidget->insertVariablesItemsToTree("ResultFileUnitsTest_res.mat", workingDirectory.path(), variables, SimulationOptions());
  VariablesTreeModel *pVariablesTreeModel = pVariablesWidget->getVariablesTreeModel();
  const QList<QStringList> units = {{"w", "rad/s", "rpm"}, {"T", "K", "degC"}, {"v", "m/s", "m/s"}};
  foreach (const QStringList &unit, units) {
    VariablesTreeItem *pVariablesTreeItem = pVariablesTreeModel->findVariablesTreeItem("ResultFileUnitsTest_res.mat." + unit.at(0), pVariablesTreeModel->getRootVariablesTreeItem());
    QVERIFY2(pVariablesTreeItem, qPrintable("Variable " + unit.at(0) + " is not in the Variables Browser."));
    QCOMPARE(pVariablesTreeItem->getUnit(), unit.at(1));
    QCOMPARE(pVariablesTreeItem->getDisplayUnit(), unit.at(2));
  }
}

void VariablesBrowserTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
