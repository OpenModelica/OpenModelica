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

#include "ModelInstanceTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/Model.h"

OMEDITTEST_MAIN(ModelInstanceTest)

void ModelInstanceTest::initTestCase()
{
  // load ModelInstanceTest.mo
  const QString modelInstanceTestFileName = QFINDTESTDATA("ModelInstanceTest.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(modelInstanceTestFileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("P")) {
    QFAIL(QString("Failed to load file %1").arg(modelInstanceTestFileName).toStdString().c_str());
  }

  // load RestrictedVariabilityParamDialog.mo
  const QString restrictedVariabilityParamDialogFileName = QFINDTESTDATA("RestrictedVariabilityParamDialog.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(restrictedVariabilityParamDialogFileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("RestrictedVariabilityParamDialog")) {
    QFAIL(QString("Failed to load file %1").arg(restrictedVariabilityParamDialogFileName).toStdString().c_str());
  }
}

void ModelInstanceTest::classAnnotations()
{
  ModelInstance::Model *pModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance("P.M"));
  if (!pModelInstance) {
    QFAIL("Model instance is null.");
  }

  if (pModelInstance->getAnnotation()->getIconAnnotation()->getGraphics().isEmpty()) {
    QFAIL("Failed to read the class icon annotation.");
  }

  if (pModelInstance->getAnnotation()->getDiagramAnnotation()->getGraphics().isEmpty()) {
    QFAIL("Failed to read the class diagram annotation.");
  }

  delete pModelInstance;
}

void ModelInstanceTest::classElements()
{
  ModelInstance::Model *pModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance("P.M"));
  if (!pModelInstance) {
    QFAIL("Model instance is null.");
  }

  if (pModelInstance->getElements().isEmpty()) {
    QFAIL("Failed to read the class elements.");
  }

  delete pModelInstance;
}

void ModelInstanceTest::classConnections()
{
  ModelInstance::Model *pModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance("P.M"));
  if (!pModelInstance) {
    QFAIL("Model instance is null.");
  }

  if (pModelInstance->getConnections().isEmpty()) {
    QFAIL("Failed to read the class connections.");
  }

  delete pModelInstance;
}

void ModelInstanceTest::isParameter()
{
  QFETCH(QString, model);
  QFETCH(QString, element);
  QFETCH(bool, result);

  ModelInstance::Model *pModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance(model));
  if (!pModelInstance) {
    QFAIL("Model instance is null.");
  }

  auto pElement = pModelInstance->lookupElement(element);

  if (!pElement) {
    QFAIL(QString("Failed to find element %1.").arg(element).toStdString().c_str());
  }

  QCOMPARE(pElement->isParameter(), result);

  delete pModelInstance;
}

void ModelInstanceTest::isParameter_data()
{
  QTest::addColumn<QString>("model");
  QTest::addColumn<QString>("element");
  QTest::addColumn<bool>("result");

  QTest::newRow("Parameter in prefix")
      << "RestrictedVariabilityParamDialog.Volume"
      << "V"
      << false;

  QTest::newRow("Parameter in extends modifiers")
      << "RestrictedVariabilityParamDialog.RestrictByRedeclare"
      << "V"
      << true;
}

void ModelInstanceTest::isInput()
{
  QFETCH(QString, model);
  QFETCH(QString, element);
  QFETCH(bool, result);

  ModelInstance::Model *pModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance(model));
  if (!pModelInstance) {
    QFAIL("Model instance is null.");
  }

  auto pElement = pModelInstance->lookupElement(element);

  if (!pElement) {
    QFAIL(QString("Failed to find element %1.").arg(element).toStdString().c_str());
  }

  QCOMPARE(pElement->isInput(), result);

  delete pModelInstance;
}

void ModelInstanceTest::isInput_data()
{
  QTest::addColumn<QString>("model");
  QTest::addColumn<QString>("element");
  QTest::addColumn<bool>("result");

  QTest::newRow("Input in prefix")
      << "RestrictedVariabilityParamDialog.Volume"
      << "X"
      << false;

  QTest::newRow("Input in extends modifiers")
      << "RestrictedVariabilityParamDialog.InputByRedeclare"
      << "X"
      << true;
}

void ModelInstanceTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
