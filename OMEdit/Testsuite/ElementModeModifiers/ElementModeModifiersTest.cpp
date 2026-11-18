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

#include "ElementModeModifiersTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/Model.h"
#include "Element/Element.h"
#include "Element/ElementProperties.h"

OMEDITTEST_MAIN(ElementModeModifiersTest)

void ElementModeModifiersTest::initTestCase()
{
  const QString fileName = QFINDTESTDATA("ElementModeModifiers.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(fileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("ElementModeModifiers")) {
    QFAIL(QString("Failed to load file %1").arg(fileName).toStdString().c_str());
  }
}

/*!
 * \brief ElementModeModifiersTest::showParameter
 * Shows the element m2 of className and reads the parameter p of m1 from its parameters dialog.
 */
void ElementModeModifiersTest::showParameter(const QString &className, QString *pValue, QString *pDefaultValue)
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
  if (!pLibraryTreeItem) {
    QFAIL(qPrintable(QString("Failed to find the library tree item for %1.").arg(className)));
  }
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  if (!pModelWidget) {
    QFAIL(qPrintable(QString("Failed to create the model widget for %1.").arg(className)));
  }
  GraphicsView *pDiagramGraphicsView = pModelWidget->getDiagramGraphicsView();
  Element *pM2 = pDiagramGraphicsView->getElementObject("m2");
  if (!pM2) {
    QFAIL(qPrintable(QString("Failed to find the m2 element in %1.").arg(className)));
  }
  pM2->showElement();
  QVERIFY2(pModelWidget->isElementMode(), qPrintable(QString("Show Element of m2 in %1 did not enter the element mode.").arg(className)));
  Element *pM1 = pDiagramGraphicsView->getElementObject("m1");
  if (!pM1 || !pM1->getModelComponent()) {
    QFAIL(qPrintable(QString("Failed to find the m1 element in m2 of %1.").arg(className)));
  }
  // Same as Element::showParameters.
  bool inherited = pM1->isInheritedElement();
  ModelInstance::Element *pRootParentElement = pModelWidget->getModelInstance()->getRootParentElement();
  if (pRootParentElement) {
    inherited = pRootParentElement->isExtend();
  }
  ElementParameters *pElementParameters = new ElementParameters(pM1->getModelComponent(), pDiagramGraphicsView, inherited, false, false, 0, 0, 0, MainWindow::instance());
  Parameter *pParameter = pElementParameters->findParameter("p");
  if (!pParameter) {
    delete pElementParameters;
    QFAIL(qPrintable(QString("The parameters dialog of m2.m1 in %1 has no parameter p.").arg(className)));
  }
  *pValue = pParameter->getValue();
  *pDefaultValue = pParameter->getDefaultValue();
  delete pElementParameters;
}

void ElementModeModifiersTest::modifierFromIntermediateParent()
{
  QString value, defaultValue;
  showParameter("ElementModeModifiers.S2", &value, &defaultValue);
  if (QTest::currentTestFailed()) {
    return;
  }
  QVERIFY(value.isEmpty());
  QCOMPARE(defaultValue, QString("1"));
}

void ElementModeModifiersTest::outerModifierOverridesInner()
{
  QString value, defaultValue;
  showParameter("ElementModeModifiers.S3", &value, &defaultValue);
  if (QTest::currentTestFailed()) {
    return;
  }
  QCOMPARE(value, QString("2"));
}

void ElementModeModifiersTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
