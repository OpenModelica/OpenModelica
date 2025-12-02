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

#include "UtilitiesTest.h"
#include "Util.h"
#include "OMEditApplication.h"
#include "MainWindow.h"
#include "Util/Utilities.h"

#ifndef GC_THREADS
#define GC_THREADS
#endif
extern "C" {
#include "meta/meta_modelica.h"
}

OMEDITTEST_MAIN(UtilitiesTest)

void UtilitiesTest::extractArrayParts()
{
  QFETCH(QString, input);
  QFETCH(QStringList, expected);

  QCOMPARE(Utilities::extractArrayParts(input), expected);
}

void UtilitiesTest::extractArrayParts_data()
{
  QTest::addColumn<QString>("input");
  QTest::addColumn<QStringList>("expected");

  QTest::newRow("Simple array") << "{1, 2, 3}" << (QStringList{"1", "2", "3"});
  QTest::newRow("Quoted strings") << "{\"one\", \"two, three\"}" << (QStringList{"one", "two, three"});
  QTest::newRow("Mixed values") << "{1.2, \"hello\", var}" << (QStringList{"1.2", "hello", "var"});
  QTest::newRow("Non-array string") << "hello" << (QStringList{"hello"});
  QTest::newRow("Exponential form") << "{1e-09 , 2e-3 , 0.456e7}" << (QStringList{"1e-09", "2e-3", "0.456e7"});
}

void UtilitiesTest::literalConstant()
{
  QFETCH(QString, string);

  if (!Utilities::isValueLiteralConstant(string)) {
    QFAIL(QString("The value %1 is not a literal constant.").arg(string).toStdString().c_str());
  }
}

void UtilitiesTest::literalConstant_data()
{
  QTest::addColumn<QString>("string");

  QTest::newRow("Integer") << "123";
  QTest::newRow("Negative integer value") << "-23";
  QTest::newRow("Integer array") << "{1,2,3}";
  QTest::newRow("Integer array with whitespace") << "{11, 981 ,34}";
  QTest::newRow("Decimal") << "56.7";
  QTest::newRow("Negative decimal value") << "-10.00";
  QTest::newRow("Decimal array") << "{3.11,5.289,3.4798}";
  QTest::newRow("Decimal array with whitespace") << "{7.89 , 2.2 , 567.8}";
  QTest::newRow("Exponential form") << "1e-09";
  QTest::newRow("Exponential form array with whitespace") << "{1e-09 , 2e-3 , 0.456e7}";
}

void UtilitiesTest::scalarLiteralConstant()
{
  QFETCH(QString, string);

  if (!Utilities::isValueScalarLiteralConstant(string)) {
    QFAIL(QString("The value %1 is not a scalar literal constant.").arg(string).toStdString().c_str());
  }
}

void UtilitiesTest::scalarLiteralConstant_data()
{
  QTest::addColumn<QString>("string");

  QTest::newRow("Integer") << "123";
  QTest::newRow("Negative integer value") << "-23";
  QTest::newRow("Decimal") << "56.7";
  QTest::newRow("Negative decimal value") << "-10.00";
  QTest::newRow("Exponential form") << "1e-09";
}

void UtilitiesTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
