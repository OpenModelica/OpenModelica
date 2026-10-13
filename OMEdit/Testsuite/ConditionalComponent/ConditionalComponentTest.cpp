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

#include "ConditionalComponentTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Element/Element.h"
#include "Element/ElementProperties.h"

#include <QGroupBox>
#include <QCoreApplication>
#include <QEvent>
#include <QLineEdit>
#include <QPointer>

static const char* className = "ConditionalComponentTest.ConditionalComponents";

OMEDITTEST_MAIN(ConditionalComponentTest)

void ConditionalComponentTest::initTestCase()
{
  const QString fileName = QFINDTESTDATA("ConditionalComponentTest.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(fileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("ConditionalComponentTest")) {
    QFAIL(QString("Failed to load file %1").arg(fileName).toStdString().c_str());
  }
}

void ConditionalComponentTest::componentConditionFromSource()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  // The component declared with a condition returns its condition expression.
  QCOMPARE(pOMCProxy->getComponentCondition(className, "conditionalComponent"), QString("useSensor"));
  // A component without a condition returns an empty string.
  QCOMPARE(pOMCProxy->getComponentCondition(className, "normalComponent"), QString(""));
}

void ConditionalComponentTest::setAndRemoveComponentCondition()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  // Initially the component has no condition.
  QCOMPARE(pOMCProxy->getComponentCondition(className, "normalComponent"), QString(""));
  // Add a condition.
  QVERIFY(pOMCProxy->setComponentCondition(className, "normalComponent", "useSensor"));
  QCOMPARE(pOMCProxy->getComponentCondition(className, "normalComponent"), QString("useSensor"));
  // An empty string removes the condition again.
  QVERIFY(pOMCProxy->setComponentCondition(className, "normalComponent", ""));
  QCOMPARE(pOMCProxy->getComponentCondition(className, "normalComponent"), QString(""));
}

void ConditionalComponentTest::attributesDialogShowsCondition()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
  if (!pLibraryTreeItem) {
    QFAIL(QString("Failed to find the library tree item for %1.").arg(className).toStdString().c_str());
  }
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  if (!pModelWidget) {
    QFAIL(QString("Failed to create the model widget for %1.").arg(className).toStdString().c_str());
  }
  GraphicsView *pDiagramGraphicsView = pModelWidget->getDiagramGraphicsView();
  if (!pDiagramGraphicsView) {
    QFAIL(QString("The model widget of %1 has no diagram graphics view.").arg(className).toStdString().c_str());
  }
  Element *pNormalComponent = pDiagramGraphicsView->getElementObject("normalComponent");
  if (!pNormalComponent) {
    QFAIL("Failed to find the normalComponent diagram element.");
  }

  // Make sure the component starts without a condition.
  QVERIFY(pOMCProxy->setComponentCondition(className, "normalComponent", ""));

  // The dialog of a component without a condition is unchecked and the expression is disabled.
  ElementAttributes *pAttributes = new ElementAttributes(pNormalComponent, MainWindow::instance());
  QGroupBox *pConditionGroupBox = pAttributes->getConditionGroupBox();
  QLineEdit *pConditionTextBox = pAttributes->getConditionTextBox();
  QVERIFY(pConditionGroupBox);
  QVERIFY(pConditionTextBox);
  QVERIFY(pConditionGroupBox->isCheckable());
  QVERIFY(!pConditionGroupBox->isChecked());
  QCOMPARE(pConditionTextBox->text(), QString(""));
  QVERIFY(!pConditionTextBox->isEnabled());
  delete pAttributes;

  // Make the component conditional and check that the dialog shows the condition.
  QVERIFY(pOMCProxy->setComponentCondition(className, "normalComponent", "useSensor"));
  pAttributes = new ElementAttributes(pNormalComponent, MainWindow::instance());
  pConditionGroupBox = pAttributes->getConditionGroupBox();
  pConditionTextBox = pAttributes->getConditionTextBox();
  QVERIFY(pConditionGroupBox);
  QVERIFY(pConditionTextBox);
  QVERIFY(pConditionGroupBox->isChecked());
  QCOMPARE(pConditionTextBox->text(), QString("useSensor"));
  QVERIFY(pConditionTextBox->isEnabled());
  delete pAttributes;

  // Restore the original state.
  pOMCProxy->setComponentCondition(className, "normalComponent", "");
}

void ConditionalComponentTest::attributesDialogSetsAndRemovesCondition()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
  if (!pLibraryTreeItem) {
    QFAIL(QString("Failed to find the library tree item for %1.").arg(className).toStdString().c_str());
  }
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  if (!pModelWidget) {
    QFAIL(QString("Failed to create the model widget for %1.").arg(className).toStdString().c_str());
  }
  GraphicsView *pDiagramGraphicsView = pModelWidget->getDiagramGraphicsView();
  if (!pDiagramGraphicsView) {
    QFAIL(QString("The model widget of %1 has no diagram graphics view.").arg(className).toStdString().c_str());
  }

  // Make sure the component starts without a condition.
  QVERIFY(pOMCProxy->setComponentCondition(className, "normalComponent", ""));
  QCOMPARE(pOMCProxy->getComponentCondition(className, "normalComponent"), QString(""));

  // Add a condition through the attributes dialog.
  Element *pNormalComponent = pDiagramGraphicsView->getElementObject("normalComponent");
  if (!pNormalComponent) {
    QFAIL("Failed to find the normalComponent diagram element.");
  }
  QPointer<ElementAttributes> pAttributes = new ElementAttributes(pNormalComponent, MainWindow::instance());
  QGroupBox *pConditionGroupBox = pAttributes->getConditionGroupBox();
  QLineEdit *pConditionTextBox = pAttributes->getConditionTextBox();
  QVERIFY(pConditionGroupBox);
  QVERIFY(pConditionTextBox);
  pConditionGroupBox->setChecked(true);
  QVERIFY(pConditionTextBox->isEnabled());
  pConditionTextBox->setText("useSensor");
  pAttributes->updateElementAttributes();
  /* updateElementAttributes() accepts the dialog which is deleted later because
   * of Qt::WA_DeleteOnClose. Flush the deferred delete before continuing.
   */
  QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
  QVERIFY(pAttributes.isNull());
  QCOMPARE(pOMCProxy->getComponentCondition(className, "normalComponent"), QString("useSensor"));

  // Remove the condition again through the attributes dialog.
  pNormalComponent = pDiagramGraphicsView->getElementObject("normalComponent");
  if (!pNormalComponent) {
    QFAIL("Failed to find the normalComponent diagram element.");
  }
  pAttributes = new ElementAttributes(pNormalComponent, MainWindow::instance());
  QGroupBox *pConditionGroupBox2 = pAttributes->getConditionGroupBox();
  QLineEdit *pConditionTextBox2 = pAttributes->getConditionTextBox();
  QVERIFY(pConditionGroupBox2);
  QVERIFY(pConditionTextBox2);
  QVERIFY(pConditionGroupBox2->isChecked());
  QCOMPARE(pConditionTextBox2->text(), QString("useSensor"));
  pConditionGroupBox2->setChecked(false);
  QVERIFY(!pConditionTextBox2->isEnabled());
  pAttributes->updateElementAttributes();
  QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
  QVERIFY(pAttributes.isNull());
  QCOMPARE(pOMCProxy->getComponentCondition(className, "normalComponent"), QString(""));
}

void ConditionalComponentTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
