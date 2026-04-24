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

#include "StringHandlerTest.h"
#include "Util.h"
#include "MainWindow.h"

OMEDITTEST_MAIN(StringHandlerTest)

void StringHandlerTest::makeVariablePartsWithIndTest()
{
  QFETCH(QString, string);
  QFETCH(QStringList, result);

  QCOMPARE(StringHandler::makeVariablePartsWithInd(string), result);
}

void StringHandlerTest::makeVariablePartsWithIndTest_data()
{
  QTest::addColumn<QString>("string");
  QTest::addColumn<QStringList>("result");

  QTest::newRow("Simple")
    << "foo"
    << QStringList({"foo"});

  QTest::newRow("Qualified")
    << "emf.flange.phi"
    << QStringList({"emf", "flange", "phi"});

  QTest::newRow("Quoted1")
    << "'sub.y'"
    << QStringList({"'sub.y'"});

  QTest::newRow("Quoted2")
    << "sub.'y'"
    << QStringList({"sub", "'y'"});

  QTest::newRow("Array1D")
    << "paramTable[1]"
    << QStringList({"paramTable", "[1]"});

  QTest::newRow("Array2D")
    << "paramTable[1,1]"
    << QStringList({"paramTable", "[1,1]"});
}

void StringHandlerTest::removeTypePrefix()
{
  QFETCH(QString, string);
  QFETCH(QString, typeName);
  QFETCH(QString, result);

  StringHandler::removeTypePrefix(string, typeName);
  QCOMPARE(string, result);
}

void StringHandlerTest::removeTypePrefix_data()
{
  QTest::addColumn<QString>("string");
  QTest::addColumn<QString>("typeName");
  QTest::addColumn<QString>("result");

  QTest::newRow("removeTypePrefix 1")
      << "P.Dynamics.FixedInitial"
      << "P.Dynamics"
      << "FixedInitial";

  QTest::newRow("removeTypePrefix 2")
      << "Modelica.Blocks.Types.Enumeration.Periodic"
      << "Modelica.Blocks.Types.Enumeration"
      << "Periodic";
}

void StringHandlerTest::splitPath()
{
  QFETCH(QString, path);
  QFETCH(QStringList, result);

  QCOMPARE(StringHandler::splitPath(path), result);
}

void StringHandlerTest::splitPath_data()
{
  QTest::addColumn<QString>("path");
  QTest::addColumn<QStringList>("result");

  QTest::newRow("Empty path")
    << ""
    << QStringList({});

  QTest::newRow("Path 1")
    << "A.B"
    << QStringList({"A", "B"});

  QTest::newRow("Path 2")
    << "A.B.'C'"
    << QStringList({"A", "B", "'C'"});

  QTest::newRow("Path 3")
    << "A.B.'C.D'"
    << QStringList({"A", "B", "'C.D'"});

  QTest::newRow("Path 4")
    << "A.B.'C.D'.E"
    << QStringList({"A", "B", "'C.D'", "E"});
}

void StringHandlerTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
