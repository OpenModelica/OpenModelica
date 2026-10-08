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

#include "ChoicesEnumerationTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Element/Element.h"
#include "Element/ElementProperties.h"

#include <QComboBox>

OMEDITTEST_MAIN(ChoicesEnumerationTest)

void ChoicesEnumerationTest::initTestCase()
{
  const QString fileName = QFINDTESTDATA("ChoicesEnumerationTest.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(fileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("EnumWithChoices")) {
    QFAIL(QString("Failed to load file %1").arg(fileName).toStdString().c_str());
  }
}

void ChoicesEnumerationTest::enumParameterWithChoices()
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem("EnumWithChoices.ClassWithInstance");
  if (!pLibraryTreeItem) {
    QFAIL("Failed to find the library tree item for EnumWithChoices.ClassWithInstance.");
  }
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  if (!pModelWidget) {
    QFAIL("Failed to create the model widget for EnumWithChoices.ClassWithInstance.");
  }
  GraphicsView *pDiagramGraphicsView = pModelWidget->getDiagramGraphicsView();
  if (!pDiagramGraphicsView) {
    QFAIL("The model widget of EnumWithChoices.ClassWithInstance has no diagram graphics view.");
  }
  Element *pClassWithEnum = pDiagramGraphicsView->getElementObject("classWithEnum");
  if (!pClassWithEnum) {
    QFAIL("Failed to find the classWithEnum diagram element.");
  }
  ModelInstance::Component *pClassWithEnumModel = pClassWithEnum->getModelComponent();
  if (!pClassWithEnumModel) {
    QFAIL("The classWithEnum diagram element has no model component.");
  }
  /* Create the ElementParameters dialog without exec() so that no dialog is shown.
   * The constructor builds the parameters list of the component type and delegates it.
   */
  ElementParameters *pElementParameters = new ElementParameters(pClassWithEnumModel, pDiagramGraphicsView, false, false, false, 0, 0, 0, MainWindow::instance());
  /* Issue #16620: choices take precedence over enumeration.
   * The enumeration parameter with a choices annotation must use its choices.
   */
  Parameter *pEnumParamWithChoices = pElementParameters->findParameter("enumParamWithChoices");
  QVERIFY(pEnumParamWithChoices);
  if (pEnumParamWithChoices) {
    QVERIFY(pEnumParamWithChoices->isChoices());
    QVERIFY(!pEnumParamWithChoices->isEnumeration());
    QComboBox *pChoicesComboBox = qobject_cast<QComboBox*>(pEnumParamWithChoices->getValueWidget());
    QVERIFY(pChoicesComboBox);
    if (pChoicesComboBox) {
      // 1 empty item + 2 choices from the annotation. The third enumeration literal must not be offered.
      QCOMPARE(pChoicesComboBox->count(), 3);
      QCOMPARE(pChoicesComboBox->itemData(1).toString(), QString("EnumWithChoices.SomeType.Choice1"));
      QCOMPARE(pChoicesComboBox->itemData(2).toString(), QString("EnumWithChoices.SomeType.Choice2"));
    }
  }
  /* The enumeration parameter without a choices annotation must use the enumeration literals. */
  Parameter *pEnumParam = pElementParameters->findParameter("enumParam");
  QVERIFY(pEnumParam);
  if (pEnumParam) {
    QVERIFY(pEnumParam->isEnumeration());
    QVERIFY(!pEnumParam->isChoices());
    QComboBox *pEnumerationComboBox = qobject_cast<QComboBox*>(pEnumParam->getValueWidget());
    QVERIFY(pEnumerationComboBox);
    if (pEnumerationComboBox) {
      // 1 empty item + 3 enumeration literals.
      QCOMPARE(pEnumerationComboBox->count(), 4);
      QCOMPARE(pEnumerationComboBox->itemData(1).toString(), QString("EnumWithChoices.SomeType.Choice1"));
      QCOMPARE(pEnumerationComboBox->itemData(3).toString(), QString("EnumWithChoices.SomeType.Choice3"));
    }
  }
  delete pElementParameters;
}

void ChoicesEnumerationTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
