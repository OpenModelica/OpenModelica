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

#include "DynamicAnnotationTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/Model.h"

OMEDITTEST_MAIN(DynamicAnnotationTest)

void DynamicAnnotationTest::initTestCase()
{
  // load MWE.mo
  const QString fileName = QFINDTESTDATA("MWE.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(fileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("MWE")) {
    QFAIL(QString("Failed to load file %1").arg(fileName).toStdString().c_str());
  }

  // load EnableInReplaceable.mo
  const QString enableInReplaceableFileName = QFINDTESTDATA("EnableInReplaceable.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(enableInReplaceableFileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("EnableInReplaceable")) {
    QFAIL(QString("Failed to load file %1").arg(enableInReplaceableFileName).toStdString().c_str());
  }

  // load EnableInReplaceable1.mo
  const QString enableInReplaceable1FileName = QFINDTESTDATA("EnableInReplaceable1.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(enableInReplaceable1FileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("EnableInReplaceable1")) {
    QFAIL(QString("Failed to load file %1").arg(enableInReplaceable1FileName).toStdString().c_str());
  }
}

void DynamicAnnotationTest::evaluate()
{
  QFETCH(QString, model);
  QFETCH(QString, element);
  QFETCH(QString, subElement);
  QFETCH(bool, result);

  // check model instance
  ModelInstance::Model *pModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance(model));
  if (!pModelInstance) {
    QFAIL(QString("Model instance of %1 is NULL.").arg(model).toStdString().c_str());
  }

  auto pElement = pModelInstance->lookupElement(element);
  if (!pElement) {
    QFAIL(QString("Failed to find element %1.").arg(element).toStdString().c_str());
  }

  auto pSubElement = pElement->getModel()->lookupElement(subElement);
  if (!pSubElement) {
    QFAIL(QString("Failed to find sub element %1.").arg(subElement).toStdString().c_str());
  }

  auto &dialogAnnotation = pSubElement->getAnnotation()->getDialogAnnotation();
  BooleanAnnotation enable = dialogAnnotation.isEnabled();
  enable.evaluate(pModelInstance);
  QCOMPARE(enable, result);

  delete pModelInstance;
}

void DynamicAnnotationTest::evaluate_data()
{
  QTest::addColumn<QString>("model");
  QTest::addColumn<QString>("element");
  QTest::addColumn<QString>("subElement");
  QTest::addColumn<bool>("result");

  QTest::newRow("Evaluate Dialog(enable=world.animateWorld)")
      << "MWE.Unnamed"
      << "test"
      << "a"
      << false;

  QTest::newRow("Evaluate Dialog(enable = booleanParam) in model")
      << "EnableInReplaceable.ClassWithInstances"
      << "mainClass"
      << "realParam"
      << true;

  QTest::newRow("Evaluate Dialog(enable = booleanParam) in record")
      << "EnableInReplaceable.ClassWithInstances"
      << "mainRecord"
      << "realParam"
      << true;
}

void DynamicAnnotationTest::evaluate_nested()
{
  QFETCH(QString, model);
  QFETCH(QString, element);
  QFETCH(QString, subElement);
  QFETCH(QString, nestedModel);
  QFETCH(QString, modifier);
  QFETCH(QString, nestedElement);
  QFETCH(bool, result);

  ModelInstance::Model *pModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance(model));
  if (!pModelInstance) {
    QFAIL(QString("Model instance of %1 is NULL.").arg(model).toStdString().c_str());
  }

  auto pElement = pModelInstance->lookupElement(element);
  if (!pElement) {
    QFAIL(QString("Failed to find element %1.").arg(element).toStdString().c_str());
  }

  auto pSubElement = pElement->getModel()->lookupElement(subElement);
  if (!pSubElement) {
    QFAIL(QString("Failed to find sub element %1.").arg(subElement).toStdString().c_str());
  }

  ModelInstance::Model *pNestedModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance(nestedModel, pSubElement->getQualifiedName(), modifier));
  if (!pNestedModelInstance) {
    QFAIL(QString("Model instance of %1 is NULL.").arg(nestedModel).toStdString().c_str());
  }
  ModelInstance::Model *pCurrentNestedModelInstance = pSubElement->getModel();
  pSubElement->setModel(pNestedModelInstance);

  auto pNestedElement = pNestedModelInstance->lookupElement(nestedElement);
  if (!pNestedElement) {
    QFAIL(QString("Failed to find nested element %1.").arg(nestedElement).toStdString().c_str());
  }

  auto &dialogAnnotation = pNestedElement->getAnnotation()->getDialogAnnotation();
  BooleanAnnotation enable = dialogAnnotation.isEnabled();
  enable.evaluate(pModelInstance);
  QCOMPARE(enable, result);

  pSubElement->setModel(pCurrentNestedModelInstance);
  delete pNestedModelInstance;
  delete pModelInstance;
}

void DynamicAnnotationTest::evaluate_nested_data()
{
  QTest::addColumn<QString>("model");
  QTest::addColumn<QString>("element");
  QTest::addColumn<QString>("subElement");
  QTest::addColumn<QString>("nestedModel");
  QTest::addColumn<QString>("modifier");
  QTest::addColumn<QString>("nestedElement");
  QTest::addColumn<bool>("result");

  QTest::newRow("Evaluate Dialog(enable = booleanParam) in record")
      << "EnableInReplaceable.ClassWithInstances"
      << "classWithReplaceable"
      << "replParamRecord"
      << "EnableInReplaceable.MainRecord"
      << ""
      << "realParam"
      << true;

  QTest::newRow("Evaluate Dialog(enable = booleanParam) in model")
      << "EnableInReplaceable.ClassWithInstances"
      << "classWithReplaceable"
      << "replInstance"
      << "EnableInReplaceable.MainClass"
      << ""
      << "realParam"
      << true;

  QTest::newRow("Evaluate Dialog(enable = booleanParam) in short class")
      << "EnableInReplaceable.ClassWithInstances"
      << "classWithReplaceable"
      << "replModel"
      << "EnableInReplaceable.MainClass"
      << ""
      << "realParam"
      << true;

  QTest::newRow("Evaluate Dialog(enable=typeParam == EnableInReplaceable1.SomeType.Type1)")
      << "EnableInReplaceable1.ClassWithInstance"
      << "classWithRecords"
      << "replRecord1"
      << "EnableInReplaceable1.BaseRecord"
      << ""
      << "realParam1"
      << true;

  QTest::newRow("Evaluate Dialog(enable=typeParam == EnableInReplaceable1.SomeType.Type2)")
      << "EnableInReplaceable1.ClassWithInstance"
      << "classWithRecords"
      << "replRecord1"
      << "EnableInReplaceable1.BaseRecord"
      << ""
      << "realParam2"
      << false;

  QTest::newRow("Evaluate Dialog(enable=typeParam == EnableInReplaceable1.SomeType.Type1) with modifier")
      << "EnableInReplaceable1.ClassWithInstance"
      << "classWithRecords"
      << "replRecord1"
      << "EnableInReplaceable1.BaseRecord"
      << "(typeParam=EnableInReplaceable1.SomeType.Type2)"
      << "realParam1"
      << false;

  QTest::newRow("Evaluate Dialog(enable=typeParam == EnableInReplaceable1.SomeType.Type2) with modifier")
      << "EnableInReplaceable1.ClassWithInstance"
      << "classWithRecords"
      << "replRecord1"
      << "EnableInReplaceable1.BaseRecord"
      << "(typeParam=EnableInReplaceable1.SomeType.Type2)"
      << "realParam2"
      << true;
}

void DynamicAnnotationTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
