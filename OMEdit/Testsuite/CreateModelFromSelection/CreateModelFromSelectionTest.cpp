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

#include "CreateModelFromSelectionTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Element/Element.h"
#include "Annotations/LineAnnotation.h"

#include <QFile>

static const char* packageName = "CreateModelFromSelectionTest";
static const char* className = "CreateModelFromSelectionTest.M";
static const char* topLevelClassName = "CreateModelFromSelectionTopLevel";

OMEDITTEST_MAIN(CreateModelFromSelectionTest)

static GraphicsView* openDiagram()
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
  if (!pLibraryTreeItem) {
    return nullptr;
  }
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  if (!pLibraryTreeItem->getModelWidget()) {
    return nullptr;
  }
  return pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView();
}

static void selectElements(GraphicsView *pGraphicsView, const QStringList &names)
{
  pGraphicsView->clearSelection();
  foreach (const QString &name, names) {
    Element *pElement = pGraphicsView->getElementObject(name);
    QVERIFY2(pElement, QString("Failed to find the element %1.").arg(name).toStdString().c_str());
    pElement->setSelected(true);
  }
}

void CreateModelFromSelectionTest::initTestCase()
{
  QVector<QPair<QString, QString> > libraries;
  libraries.append(qMakePair(QString("Modelica"), QString("default")));
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->addModelicaLibraries(libraries);
  // Open a copy since OMEdit saves the changed package on close.
  QVERIFY(mTemporaryDir.isValid());
  const QString fileName = mTemporaryDir.filePath("CreateModelFromSelectionTest.mo");
  QVERIFY(QFile::copy(QFINDTESTDATA("CreateModelFromSelectionTest.mo"), fileName));
  MainWindow::instance()->getLibraryWidget()->openFile(fileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass(packageName)) {
    QFAIL(QString("Failed to load file %1").arg(fileName).toStdString().c_str());
  }
}

void CreateModelFromSelectionTest::createAndReplace()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  GraphicsView *pGraphicsView = openDiagram();
  QVERIFY(pGraphicsView);
  selectElements(pGraphicsView, QStringList() << "gain" << "integrator");
  QVERIFY(pGraphicsView->createModelFromSelection("Sub", "Gain and integrator", packageName, "sub", true));

  // The new model has the moved components, their connection and one port for each connector connected to the outside.
  const QString newClassName = QString("%1.Sub").arg(packageName);
  QVERIFY(pOMCProxy->existClass(newClassName));
  QVERIFY(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(newClassName));
  QCOMPARE(pOMCProxy->getConnectionCount(newClassName), 3);
  const QString newClassText = pOMCProxy->list(newClassName);
  QVERIFY(newClassText.contains("Modelica.Blocks.Math.Gain gain(k = 2)"));
  QVERIFY(newClassText.contains("Modelica.Blocks.Continuous.Integrator integrator"));
  QVERIFY(newClassText.contains("Modelica.Blocks.Interfaces.RealInput u"));
  QVERIFY(newClassText.contains("Modelica.Blocks.Interfaces.RealOutput y"));
  QVERIFY(newClassText.contains("connect(u, gain.u)"));
  QVERIFY(newClassText.contains("connect(y, integrator.y)"));

  // The selection is replaced by a component that is connected as the selection was.
  QVERIFY(!pGraphicsView->getElementObject("gain"));
  QVERIFY(!pGraphicsView->getElementObject("integrator"));
  QVERIFY(pGraphicsView->getElementObject("sub"));
  QCOMPARE(pOMCProxy->getConnectionCount(className), 3);
  QCOMPARE(pGraphicsView->getConnectionsList().size(), 3);
  foreach (LineAnnotation *pConnection, pGraphicsView->getConnectionsList()) {
    QVERIFY2(pConnection->getStartElement() && pConnection->getEndElement(),
             QString("The connection %1 - %2 is not drawn.").arg(pConnection->getStartElementName(), pConnection->getEndElementName()).toStdString().c_str());
  }

  // Undo restores the selected components.
  pGraphicsView->getModelWidget()->getUndoStack()->undo();
  QVERIFY(pGraphicsView->getElementObject("gain"));
  QVERIFY(pGraphicsView->getElementObject("integrator"));
  QVERIFY(!pGraphicsView->getElementObject("sub"));
  QCOMPARE(pOMCProxy->getConnectionCount(className), 4);
}

void CreateModelFromSelectionTest::componentNameSameAsModelName()
{
  GraphicsView *pGraphicsView = openDiagram();
  QVERIFY(pGraphicsView);
  selectElements(pGraphicsView, QStringList() << "gain");
  QVERIFY(!pGraphicsView->createModelFromSelection("gainModel", "", packageName, "gainModel", true));
  QVERIFY(!MainWindow::instance()->getOMCProxy()->existClass(QString("%1.gainModel").arg(packageName)));
  QVERIFY(pGraphicsView->getElementObject("gain"));
}

void CreateModelFromSelectionTest::topLevelModelUses()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  GraphicsView *pGraphicsView = openDiagram();
  QVERIFY(pGraphicsView);
  selectElements(pGraphicsView, QStringList() << "gain");
  QVERIFY(pGraphicsView->createModelFromSelection(topLevelClassName, "", "", "", false));
  QVERIFY(pOMCProxy->existClass(topLevelClassName));
  const QList<QList<QString> > uses = pOMCProxy->getUses(topLevelClassName);
  QCOMPARE(uses.size(), 1);
  QCOMPARE(uses.at(0).at(0), QString("Modelica"));
  QCOMPARE(uses.at(0).at(1), QString("4.1.0"));
}

void CreateModelFromSelectionTest::cleanupTestCase()
{
  // Unload the changed classes without asking to save them.
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  foreach (const QString &name, QStringList() << packageName << topLevelClassName) {
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(name);
    if (pLibraryTreeItem) {
      pLibraryTreeModel->unloadClass(pLibraryTreeItem, false);
    }
  }
  MainWindow::instance()->close();
}
