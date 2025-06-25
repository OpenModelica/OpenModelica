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

#include "VariableValueTest.h"
#include "Util.h"
#include "OMEditApplication.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"

#define GC_THREADS
extern "C" {
#include "meta/meta_modelica.h"
}

OMEDITTEST_MAIN(VariableValueTest)

void VariableValueTest::initTestCase()
{
  // load TestIconExtend.mo
  QString testIconExtendFileName = QFINDTESTDATA("TestIconExtend.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(testIconExtendFileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("TestIconExtend")) {
    QFAIL(QString("Failed to load file %1").arg(testIconExtendFileName).toStdString().c_str());
  }

  // load IconsWithValues.mo
  QString iconsWithValuesFileName = QFINDTESTDATA("IconsWithValues.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(iconsWithValuesFileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("IconsWithValues")) {
    QFAIL(QString("Failed to load file %1").arg(iconsWithValuesFileName).toStdString().c_str());
  }

  // load TestParameterSubLevelinIcon.mo
  QString testParameterSubLevelinIconFileName = QFINDTESTDATA("TestParameterSubLevelinIcon.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(testParameterSubLevelinIconFileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("TestParameterSubLevelinIcon")) {
    QFAIL(QString("Failed to load file %1").arg(testParameterSubLevelinIconFileName).toStdString().c_str());
  }
}

void VariableValueTest::variableValue()
{
  QFETCH(QString, model);
  QFETCH(QString, component);
  QFETCH(bool, inherited);
  QFETCH(QString, variable);
  QFETCH(QString, result);

  ModelInstance::Model *pModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance(model));
  if (!pModelInstance) {
    QFAIL("Model instance is null.");
  }

  auto pElement = pModelInstance->lookupElement(component);

  if (!pElement) {
    QFAIL(QString("Failed to find element %1.").arg(component).toStdString().c_str());
  }

  QPair<QString, bool> displayString("", false);

  QStringList nameList;
  nameList = StringHandler::makeVariableParts(pElement->getQualifiedName());
  // the first item is element name
  if (!inherited && !nameList.isEmpty()) {
    nameList.removeFirst();
  }

  if (!pElement->getModel()) {
    QFAIL(QString("Element %1 has not model.").arg(component).toStdString().c_str());
  }

  pElement = pElement->getModel()->getRootParentElement();

  displayString = pElement->getVariableValue(QStringList() << nameList << StringHandler::makeVariableParts(variable));
  QCOMPARE(displayString.first, result);

  delete pModelInstance;
}

void VariableValueTest::variableValue_data()
{
  QTest::addColumn<QString>("model");
  QTest::addColumn<QString>("component");
  QTest::addColumn<bool>("inherited");
  QTest::addColumn<QString>("variable");
  QTest::addColumn<QString>("result");

  // Test component modifier values
  QTest::newRow("ComponentModifier1")
      << "IconsWithValues.Test1"
      << "component1"
      << false
      << "p"
      << "4";

  // Test extends modifier values
  QTest::newRow("ExtendsModifier1")
      << "IconsWithValues.Test2"
      << "component1"
      << true
      << "p"
      << "44";

  // Test instance name values
  QTest::newRow("InstanceName1")
      << "TestIconExtend.View"
      << "myClass3"
      << false
      << "myClass.MyCostumString"
      << "TestStringmanuel";

  QTest::newRow("InstanceName2")
      << "TestIconExtend.View"
      << "myClass3"
      << false
      << "myClass.nonString"
      << "10";

  QTest::newRow("ExtendsModifierLocalVariable1")
      << "TestIconExtend.View"
      << "myClass2"
      << false
      << "MyCostumString"
      << "MyStringParameter";

  QTest::newRow("ExtendsModifierLocalVariable2")
      << "TestIconExtend.View"
      << "myClass2"
      << false
      << "nonString"
      << "relParam";

  QTest::newRow("ComponentSubLevelExtendsModifier1")
      << "TestIconExtend.View"
      << "myClass"
      << false
      << "MyCostumString"
      << "TestStringmanuel";

  QTest::newRow("ComponentSubLevelExtendsModifier2")
      << "TestIconExtend.View"
      << "myClass"
      << false
      << "nonString"
      << "10";

  QTest::newRow("ComponentSubLevelModifier1")
      << "TestParameterSubLevelinIcon.ClassWhereTestModelisUsed"
      << "testmodel1"
      << false
      << "a"
      << "1";

  QTest::newRow("ComponentSubLevelExtendsModifier3")
      << "TestParameterSubLevelinIcon.ClassWhereTestModelisUsed"
      << "testmodel1"
      << false
      << "b"
      << "2";

  QTest::newRow("ComponentSubLevelRecordModifier1")
      << "TestParameterSubLevelinIcon.ClassWhereTestModelisUsed"
      << "testmodel1"
      << false
      << "testrecord1.c"
      << "3";
}

void VariableValueTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
