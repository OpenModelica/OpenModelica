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

#include "MergeExtendsModifiersTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/Model.h"

OMEDITTEST_MAIN(MergeExtendsModifiersTest)

void MergeExtendsModifiersTest::initTestCase()
{
  // load CopyExtendModifier.mo
  const QString copyExtendModifierFileName = QFINDTESTDATA("CopyExtendModifier.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(copyExtendModifierFileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("CopyExtendModifier")) {
    QFAIL(QString("Failed to load file %1").arg(copyExtendModifierFileName).toStdString().c_str());
  }

  // load CopyExtendModifier2.mo
  const QString copyExtendModifier2FileName = QFINDTESTDATA("CopyExtendModifier2.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(copyExtendModifier2FileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("CopyExtendModifier2")) {
    QFAIL(QString("Failed to load file %1").arg(copyExtendModifier2FileName).toStdString().c_str());
  }
}

void MergeExtendsModifiersTest::mergeModifiers()
{
  QFETCH(QStringList, modifiers);
  QFETCH(QString, result);

  QVector<const ModelInstance::Modifier*> modifierList;

  foreach (auto modifier, modifiers) {
    const QJsonObject modifierJSON = MainWindow::instance()->getOMCProxy()->modifierToJSON(modifier);
    ModelInstance::Modifier *pModifier = new ModelInstance::Modifier("", QJsonValue(modifierJSON), nullptr);
    modifierList.append(pModifier);
  }

  ModelInstance::Modifier *pMergedModifier = ModelInstance::Modifier::mergeModifiersIntoOne(modifierList, nullptr);
  const QString mergedModifiers = pMergedModifier->toString();
  delete pMergedModifier;

  QCOMPARE(mergedModifiers, result);
}

void MergeExtendsModifiersTest::mergeModifiers_data()
{
  QTest::addColumn<QStringList>("modifiers");
  QTest::addColumn<QString>("result");

  QTest::newRow("Merge modifiers")
      << QStringList{"(realParam1 = 3)", "(realParam2 = 5)"}
      << "(realParam2 = 5, realParam1 = 3)";

  QTest::newRow("Merge modifiers update")
      << QStringList{"(realParam2 = 3)", "(realParam2 = 5)"}
      << "(realParam2 = 5)";

  QTest::newRow("Merge modifiers nested")
      << QStringList{"M(realParam1 = 3)", "M(realParam2 = 5, realParam3 = 10)"}
      << "(realParam2 = 5, realParam3 = 10, realParam1 = 3)";
}

void MergeExtendsModifiersTest::mergeExtendsModifiers()
{
  QFETCH(QString, model);
  QFETCH(QString, element);
  QFETCH(QString, result);

  ModelInstance::Model *pModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance(model));
  if (!pModelInstance) {
    QFAIL("Model instance is null.");
  }

  auto pElement = pModelInstance->lookupElement(element);

  if (!pElement) {
    QFAIL(QString("Failed to find element %1.").arg(element).toStdString().c_str());
  }

  const QString mergedModifiers = pElement->toString(false, true);
  QCOMPARE(mergedModifiers, result);

  delete pModelInstance;
}

void MergeExtendsModifiersTest::mergeExtendsModifiers_data()
{
  QTest::addColumn<QString>("model");
  QTest::addColumn<QString>("element");
  QTest::addColumn<QString>("result");

  QTest::newRow("Merge extends modifiers")
      << "CopyExtendModifier.ClassWithExtend"
      << "baseModel"
      << "CopyExtendModifier.BaseModel baseModel (a = 1, b = 2)";

  QTest::newRow("Merge extends modifiers with redeclare")
      << "CopyExtendModifier2.ClassWithExtend"
      << "baseModel"
      << "inner CopyExtendModifier2.BaseModel baseModel (a = 1, b = 2, redeclare CopyExtendModifier2.BaseRecord replRecord)";
}

void MergeExtendsModifiersTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
