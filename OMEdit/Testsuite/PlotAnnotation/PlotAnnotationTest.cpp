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

#include "PlotAnnotationTest.h"
#include "Util.h"
#include "Util/Helper.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/MessagesWidget.h"
#include "Modeling/Model.h"
#include "Modeling/ModelWidgetContainer.h"
#include "OMC/OMCProxy.h"
#include "Plotting/PlotWindowContainer.h"
#include "Simulation/SimulationOutputWidget.h"
#include "OMPlot.h"
#include "PlotCurve.h"
#include "PlotWindow.h"

OMEDITTEST_MAIN(PlotAnnotationTest)

/*!
 * \class PlotAnnotationTest
 * \brief Tests preferred-figure plotting and saving through the OMEdit GUI.
 */

/*!
 * \brief PlotAnnotationTest::initTestCase
 * Loads the small simulation model with its preferred Documentation figure.
 */
void PlotAnnotationTest::initTestCase()
{
  const QString modelFileName = QFINDTESTDATA("PlotAnnotationTest.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(modelFileName);
  QVERIFY2(MainWindow::instance()->getOMCProxy()->existClass("PlotAnnotationTest"),
           qPrintable(QString("Failed to load test model from %1.").arg(modelFileName)));
}

/*!
 * \brief PlotAnnotationTest::plotAndSaveDocumentationFigure
 * Simulates the model, confirms its annotated curve is plotted, and saves the
 * active plot back to the model through the GUI action handler.
 *
 * The test uses one curve and one simulation so it focuses on the OMEdit
 * integration path: annotation-driven plotting, annotation save, and its
 * single undo-stack entry.
 */
void PlotAnnotationTest::plotAndSaveDocumentationFigure()
{
  const QString className = QStringLiteral("PlotAnnotationTest");
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(className);
  QVERIFY(pLibraryTreeItem);

  // The save action intentionally updates an already-open model's undo stack.
  pLibraryTreeModel->showModelWidget(pLibraryTreeItem);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  QVERIFY(pModelWidget);
  QVERIFY(pModelWidget->getModelInstance());

  MainWindow::instance()->simulate(pLibraryTreeItem);
  SimulationOutputWidget *pOutputWidget = MessagesWidget::instance()->getSimulationOutputWidget(className);
  QVERIFY(pOutputWidget);
  QSignalSpy simulationFinishedSpy(pOutputWidget, &SimulationOutputWidget::simulationFinished);
  QVERIFY2(simulationFinishedSpy.wait(300000), "The plot annotation test simulation did not finish.");
  QApplication::processEvents();

  PlotWindowContainer *pPlotWindowContainer = MainWindow::instance()->getPlotWindowContainer();
  OMPlot::PlotWindow *pAnnotatedPlotWindow = nullptr;
  QMdiSubWindow *pPlotSubWindow = nullptr;
  for (QMdiSubWindow *pSubWindow : pPlotWindowContainer->subWindowList()) {
    auto *pPlotWindow = qobject_cast<OMPlot::PlotWindow*>(pSubWindow->widget());
    if (pPlotWindow && pPlotWindow->property(Helper::modelicaFigureTitle.toStdString().c_str()).toString() == QStringLiteral("Annotated decay")) {
      pAnnotatedPlotWindow = pPlotWindow;
      pPlotSubWindow = pSubWindow;
      break;
    }
  }
  QVERIFY(pAnnotatedPlotWindow);
  QVERIFY(pPlotSubWindow);
  QCOMPARE(pAnnotatedPlotWindow->property(Helper::modelicaFigureTitle.toStdString().c_str()).toString(), QStringLiteral("Annotated decay"));
  QCOMPARE(pAnnotatedPlotWindow->getPlot()->getPlotCurvesList().size(), 1);
  QCOMPARE(pAnnotatedPlotWindow->getPlot()->getPlotCurvesList().first()->getYVariable(), QStringLiteral("x"));
  QCOMPARE(pAnnotatedPlotWindow->getPlot()->getPlotCurvesList().first()->getCustomTitle(), QStringLiteral("State"));

  // Activate the annotated plot because saveFigureInModel operates on the current MDI window.
  pPlotWindowContainer->setActiveSubWindow(pPlotSubWindow);
  const int previousUndoCount = pModelWidget->getUndoStack()->count();
  pPlotWindowContainer->saveFigureInModel();
  QCOMPARE(pModelWidget->getUndoStack()->count(), previousUndoCount + 1);
  QVERIFY(pModelWidget->getUndoStack()->undoText().contains(className));

  const ModelInstance::DocumentationAnnotation *pDocumentation = pModelWidget->getModelInstance()->getAnnotation()->getDocumentationAnnotation();
  QVERIFY(pDocumentation);
  const QString savedDocumentation = pDocumentation->toString();
  QVERIFY(savedDocumentation.contains(QStringLiteral("info=\"Figure test documentation\"")));
  QVERIFY(savedDocumentation.contains(QStringLiteral("Figure(title=\"Annotated decay\"")));
  QVERIFY(savedDocumentation.contains(QStringLiteral("Curve(y=x,legend=\"State\")")));
}

/*!
 * \brief PlotAnnotationTest::cleanupTestCase
 * Closes OMEdit after the plot annotation GUI test.
 */
void PlotAnnotationTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
