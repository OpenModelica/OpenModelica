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

#include "ModelInstanceTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/Model.h"
#include "OMC/OMCProxy.h"

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

  // load ModifierDisplayUnit.mo
  const QString modifierDisplayUnitFileName = QFINDTESTDATA("ModifierDisplayUnit.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(modifierDisplayUnitFileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("ModifierDisplayUnit")) {
    QFAIL(QString("Failed to load file %1").arg(modifierDisplayUnitFileName).toStdString().c_str());
  }

  // load Modifiers.mo
  const QString modifiersFileName = QFINDTESTDATA("Modifiers.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(modifiersFileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("Modifiers")) {
    QFAIL(QString("Failed to load file %1").arg(modifiersFileName).toStdString().c_str());
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

void ModelInstanceTest::documentationFigures()
{
  const auto makeRecord = [](const QString &name, const QJsonArray &elements) {
    return QJsonObject{{"$kind", "record"}, {"name", name}, {"elements", elements}};
  };
  const QJsonObject curve = makeRecord("Curve", QJsonArray{
                                         "time",
                                         QJsonObject{
                                           {"$kind", "cref"},
                                           {"parts", QJsonArray{QJsonObject{{"name", "h"}}}}
                                         },
                                         "Height of ball",
                                         0
                                       });
  const QJsonObject axisScale = makeRecord("AxisScale", QJsonArray{"Log", 2});
  const QJsonObject xAxis = makeRecord("Axis", QJsonArray{QJsonArray{}, QJsonArray{}, "", "time (s)", axisScale});
  const QJsonObject yAxis = makeRecord("Axis", QJsonArray{QJsonArray{}, QJsonArray{}, "", "", QJsonObject{}});
  const QJsonObject plot = makeRecord("Plot", QJsonArray{"height", "", QJsonArray{curve}, xAxis, yAxis});
  const QJsonObject figure = makeRecord("Figure", QJsonArray{"Bouncing ball", "", "", true, QJsonArray{plot}, ""});
  const QJsonObject secondFigure = makeRecord("Figure", QJsonArray{"Other", "", "", false, QJsonArray{}, ""});

  ModelInstance::DocumentationAnnotation documentation;
  documentation.deserialize(QJsonObject{
                              {"info", "Model information"},
                              {"revisions", "Model revisions"},
                              {"__OpenModelica_infoHeader", "Header"},
                              {"styleSheets", QJsonArray{"plot.css"}},
                              {"figures", QJsonArray{figure, secondFigure}}
                            });

  QCOMPARE(documentation.getInfo(), QString("Model information"));
  QCOMPARE(documentation.getRevisions(), QString("Model revisions"));
  QCOMPARE(documentation.getInfoHeader(), QString("Header"));
  QCOMPARE(documentation.getStyleSheets(), QStringList{"plot.css"});
  QCOMPARE(documentation.getFigures().size(), size_t(2));

  const ModelInstance::Figure *pFigure = documentation.getFigures().at(0).get();
  QCOMPARE(pFigure->getTitle(), QString("Bouncing ball"));
  QVERIFY(pFigure->isPreferred());
  QCOMPARE(pFigure->getPlots().size(), size_t(1));

  const ModelInstance::Plot *pPlot = pFigure->getPlots().at(0).get();
  QCOMPARE(pPlot->getTitle(), QString("height"));
  QCOMPARE(pPlot->getCurves().size(), size_t(1));
  QVERIFY(pPlot->getXAxis());
  QVERIFY(pPlot->getYAxis());
  QCOMPARE(pPlot->getXAxis()->getLabel(), QString("time (s)"));
  QVERIFY(pPlot->getXAxis()->getScale());
  QCOMPARE(pPlot->getXAxis()->getScale()->getScaleType(), QString("Log"));
  QCOMPARE(pPlot->getXAxis()->getScale()->getBase(), 2);
  QCOMPARE(pPlot->getCurves().at(0)->getY().toQString(), QString("h"));
  QCOMPARE(pPlot->getCurves().at(0)->getLegend(), QString("Height of ball"));

  const QString serialized =
      "Documentation(info=\"Model information\",revisions=\"Model revisions\",__OpenModelica_infoHeader=\"Header\","
      "styleSheets={\"plot.css\"},figures={Figure(title=\"Bouncing ball\",preferred=true,"
      "plots={Plot(title=\"height\",curves={Curve(y=h,legend=\"Height of ball\")},"
      "x=Axis(label=\"time (s)\",scale=AxisScale(scaleType=\"Log\",base=2)))}),Figure(title=\"Other\",plots={})})";
  QCOMPARE(documentation.toString(), serialized);

  const QString replacement = "Figure(title=\"Bouncing ball\",preferred=true,plots={Plot(curves={Curve(y=v)})})";
  const QString replacementSerialization =
      "Documentation(info=\"Model information\",revisions=\"Model revisions\",__OpenModelica_infoHeader=\"Header\","
      "styleSheets={\"plot.css\"},figures={Figure(title=\"Bouncing ball\",preferred=true,plots={Plot(curves={Curve(y=v)})}),"
      "Figure(title=\"Other\",plots={})})";
  QCOMPARE(documentation.toString("Bouncing ball", replacement), replacementSerialization);

  documentation.setDocumentation("Updated information", "Updated revisions", "Updated header");
  const QString updatedDocumentation =
      "Documentation(info=\"Updated information\",revisions=\"Updated revisions\",__OpenModelica_infoHeader=\"Updated header\","
      "styleSheets={\"plot.css\"},figures={Figure(title=\"Bouncing ball\",preferred=true,"
      "plots={Plot(title=\"height\",curves={Curve(y=h,legend=\"Height of ball\")},"
      "x=Axis(label=\"time (s)\",scale=AxisScale(scaleType=\"Log\",base=2)))}),Figure(title=\"Other\",plots={})})";
  QCOMPARE(documentation.toString(), updatedDocumentation);

  documentation.setFigureAnnotation("Bouncing ball", replacement);
  const QString updatedFigureSerialization =
      "Documentation(info=\"Updated information\",revisions=\"Updated revisions\",__OpenModelica_infoHeader=\"Updated header\","
      "styleSheets={\"plot.css\"},figures={Figure(title=\"Bouncing ball\",preferred=true,plots={Plot(curves={Curve(y=v)})}),"
      "Figure(title=\"Other\",plots={})})";
  QCOMPARE(documentation.toString(), updatedFigureSerialization);

  documentation.setFigureAnnotation("New figure", "Figure(title=\"New figure\",plots={})");
  QVERIFY(documentation.toString().contains("figures={Figure(title=\"Bouncing ball\""));
  QVERIFY(documentation.toString().contains("Figure(title=\"New figure\",plots={})"));
  QCOMPARE(documentation.getFigures().size(), size_t(2));
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

void ModelInstanceTest::referencePathEquivalence()
{
  MainWindow *pMainWindow = MainWindow::instance();
  OMCProxy *pOMCProxy = pMainWindow->getOMCProxy();
  const bool savedFlag = pMainWindow->isNewApiNoJson();

  QStringList classes;
  classes << "P.M"
          << "RestrictedVariabilityParamDialog.Volume"
          << "RestrictedVariabilityParamDialog.RestrictByRedeclare";

  for (const QString &className : classes) {
    // Diagram/model path (icon = false).
    pMainWindow->setNewApiNoJson(false);
    const QJsonObject jsonObject = pOMCProxy->getModelInstance(className, "", "", false, false);
    pMainWindow->setNewApiNoJson(true);
    const QJsonObject referenceObject = pOMCProxy->getModelInstance(className, "", "", false, false);
    if (jsonObject != referenceObject) {
      QFAIL(QString("Model instance for %1 differs between the JSON path and the reference path.").arg(className).toStdString().c_str());
    }

    // Annotation/icon path (icon = true).
    pMainWindow->setNewApiNoJson(false);
    const QJsonObject jsonIcon = pOMCProxy->getModelInstance(className, "", "", false, true);
    pMainWindow->setNewApiNoJson(true);
    const QJsonObject referenceIcon = pOMCProxy->getModelInstance(className, "", "", false, true);
    if (jsonIcon != referenceIcon) {
      QFAIL(QString("Annotation instance for %1 differs between the JSON path and the reference path.").arg(className).toStdString().c_str());
    }
  }

  pMainWindow->setNewApiNoJson(savedFlag);
}

void ModelInstanceTest::modifiertoString()
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

  auto *pModifier = pElement->getModifier();
  if (!pModifier) {
    QFAIL(QString("Failed to find element %1 modifier.").arg(element).toStdString().c_str());
  }

  QCOMPARE(pModifier->toString(true, true), result);

  delete pModelInstance;
}

void ModelInstanceTest::modifiertoString_data()
{
  QTest::addColumn<QString>("model");
  QTest::addColumn<QString>("element");
  QTest::addColumn<QString>("result");

  QTest::newRow("Element modifier toString 1")
      << "ModifierDisplayUnit"
      << "spring"
      << "(c = 35, f(displayUnit = \"kN\"), s_rel(displayUnit = \"cm\"))";

  QTest::newRow("Element modifier toString 2")
      << "Modifiers.M"
      << "a"
      << "(R = 1, V(start = 2), X = sin(time), Y(min = 2) = if time < 1 then 0 else 1)";
}

void ModelInstanceTest::subModifiertoString()
{
  QFETCH(QString, model);
  QFETCH(QString, element);
  QFETCH(QString, modifier);
  QFETCH(QString, result);

  ModelInstance::Model *pModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance(model));
  if (!pModelInstance) {
    QFAIL("Model instance is null.");
  }

  auto pElement = pModelInstance->lookupElement(element);
  if (!pElement) {
    QFAIL(QString("Failed to find element %1.").arg(element).toStdString().c_str());
  }

  auto *pModifier = pElement->getModifier();
  if (!pModifier) {
    QFAIL(QString("Failed to find element %1 modifier.").arg(element).toStdString().c_str());
  }

  bool found = false;
  foreach (auto *pSubModifier, pModifier->getModifiers()) {
    if (pSubModifier->getName() == modifier) {
      found = true;
      QCOMPARE(pSubModifier->toString(true, true), result);
      break;
    }
  }

  if (!found) {
    QFAIL(QString("Failed to find sub-modifier %1.").arg(modifier).toStdString().c_str());
  }

  delete pModelInstance;
}

void ModelInstanceTest::subModifiertoString_data()
{
  QTest::addColumn<QString>("model");
  QTest::addColumn<QString>("element");
  QTest::addColumn<QString>("modifier");
  QTest::addColumn<QString>("result");

  QTest::newRow("Sub modifier toString 1")
      << "ModifierDisplayUnit"
      << "spring"
      << "c"
      << "35";

  QTest::newRow("Sub modifier toString 2")
      << "ModifierDisplayUnit"
      << "spring"
      << "f"
      << "(displayUnit = \"kN\")";

  QTest::newRow("Sub modifier toString 3")
      << "ModifierDisplayUnit"
      << "spring"
      << "s_rel"
      << "(displayUnit = \"cm\")";

  QTest::newRow("Sub modifier toString 4")
      << "Modifiers.M"
      << "a"
      << "R"
      << "1";

  QTest::newRow("Sub modifier toString 5")
      << "Modifiers.M"
      << "a"
      << "V"
      << "(start = 2)";

  QTest::newRow("Sub modifier toString 6")
      << "Modifiers.M"
      << "a"
      << "X"
      << "sin(time)";

  QTest::newRow("Sub modifier toString 7")
      << "Modifiers.M"
      << "a"
      << "Y"
      << "(min = 2) = if time < 1 then 0 else 1";
}

void ModelInstanceTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
