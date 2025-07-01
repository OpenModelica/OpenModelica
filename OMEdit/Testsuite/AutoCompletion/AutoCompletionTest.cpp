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

#include "AutoCompletionTest.h"
#include "Util.h"
#include "OMEditApplication.h"
#include "MainWindow.h"
#include "Editors/ModelicaEditor.h"
#include "Modeling/LibraryTreeWidget.h"

#define GC_THREADS
extern "C" {
#include "meta/meta_modelica.h"
}

OMEDITTEST_MAIN(AutoCompletionTest)

void AutoCompletionTest::initTestCase()
{
  // Load OpenModelica for auto completion
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->addModelicaLibraries();

  MainWindow::instance()->getLibraryWidget()->openFile(QFINDTESTDATA(mFileName));
  if (!MainWindow::instance()->getOMCProxy()->existClass(mModelName)) {
    QFAIL(QString("Failed to load file %1").arg(mFileName).toStdString().c_str());
  }
}

void AutoCompletionTest::inOutAnnotationTest()
{
  QFETCH(QString, word);
  QFETCH(bool, result);

  QList<CompleterItem> annotations;
  QCOMPARE(ModelicaEditor::getCompletionAnnotations(word, annotations), result);
}

void AutoCompletionTest::inOutAnnotationTest_data()
{
  QTest::addColumn<QString>("word");
  QTest::addColumn<bool>("result");

  QTest::newRow("InAnnotation")
      << "annotation(Dialog(tab = \"General\")"
      << true;

  QTest::newRow("InDialogAnnotation")
      << "annotation(Dialog(tab = \"General\""
      << true;

  QTest::newRow("OutDialogAnnotationButInAnnotation")
      << "annotation(Dialog(tab = \"General\")"
      << true;

  QTest::newRow("OutAnnotation1")
      << "annotation(Dialog(tab = \"General\"))"
      << false;

  QTest::newRow("OutAnnotation2")
      << "annotation(Dialog(tab = \"General\"));"
      << false;
}

void AutoCompletionTest::getCompletionAnnotationsTest()
{
  QFETCH(QString, word);
  QFETCH(QStringList, result);

  QList<CompleterItem> annotations;
  ModelicaEditor::getCompletionAnnotations(word, annotations);
  QCOMPARE(BaseEditor::completerItemsToStringList(annotations), result);
}

void AutoCompletionTest::getCompletionAnnotationsTest_data()
{
  QTest::addColumn<QString>("word");
  QTest::addColumn<QStringList>("result");

  QTest::newRow("DocumentationAnnotation")
      << "annotation(Documentation("
      << QStringList({"info = ", "revisions = "});

  QTest::newRow("ExperimentAnnotation")
      << "annotation(experiment("
      << QStringList({"StartTime = 0", "StopTime = 1", "Interval = 0.002", "Tolerance = 1e-6"});
}

void AutoCompletionTest::getCompletionSymbolsTest()
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(mModelName);
  if (!pLibraryTreeItem) {
    QFAIL(QString("Failed to find library tree item for %1").arg(mModelName).toStdString().c_str());
  }

  QFETCH(QString, word);
  QFETCH(QStringList, expectedClasses);
  QFETCH(QStringList, expectedComponents);

  QList<CompleterItem> classes, components;
  ModelicaEditor::getCompletionSymbols(pLibraryTreeItem, word, classes, components);
  QCOMPARE(BaseEditor::completerItemsToStringList(classes), expectedClasses);
  QCOMPARE(BaseEditor::completerItemsToStringList(components), expectedComponents);
}

void AutoCompletionTest::getCompletionSymbolsTest_data()
{
  QTest::addColumn<QString>("word");
  QTest::addColumn<QStringList>("expectedClasses");
  QTest::addColumn<QStringList>("expectedComponents");

  // Test the auto completion for classes and components in the model
  QTest::newRow("EmptyWord")
      << ""
      << QStringList({"KindOfController", "test_annotation"})
      << QStringList({"Bonjour", "Hej", "Hello", "Hola", "isActive"});

  QTest::newRow("ClassName")
      << "test_annotation."
      << QStringList({"KindOfController"})
      << QStringList({"Bonjour", "Hej", "Hello", "Hola", "isActive"});
}

void AutoCompletionTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
