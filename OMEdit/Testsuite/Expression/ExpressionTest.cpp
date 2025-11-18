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
 * @author Per Östlund <per.ostlund@liu.se>
 */

#include "ExpressionTest.h"
#include "Util.h"
#include "OMEditApplication.h"
#include "MainWindow.h"
#include "FlatModelica/Expression.h"

#define GC_THREADS
extern "C" {
#include "meta/meta_modelica.h"
}

OMEDITTEST_MAIN(ExpressionTest)

QString evalString(const QString &str)
{
  return FlatModelica::Expression::parse(str).evaluate([] (const std::string &) {
    // Assume that all variables have the value 1.0 for testing purposes.
    return FlatModelica::Expression(1.0);
  }).toQString();
}

void ExpressionTest::dynamicSelect()
{
  QFETCH(QString, string);
  QFETCH(QString, result);

  try {
    QCOMPARE(evalString(string), result);
  } catch (const std::exception &e) {
    qDebug() << e.what();
    QFAIL(QString("Failed to evaluate: ").arg(string).toStdString().c_str());
  }
}

void ExpressionTest::dynamicSelect_data()
{
  QTest::addColumn<QString>("string");
  QTest::addColumn<QString>("result");

  QTest::newRow("DynamicSelect1")
    << "DynamicSelect(\"0.0\", String(showNumber, significantDigits, 0, true))"
    << "DynamicSelect(\"0.0\",\"1\")";

  QTest::newRow("DynamicSelect2")
    << "DynamicSelect({{-35, 35}, {35, -35}}, {{-0, port_1.m_flow * 0}, {0, -0}})"
    << "DynamicSelect({{-35,35},{35,-35}},{{0,0},{0,0}})";

  QTest::addRow("DynamicSelect3")
    << "DynamicSelect(\"\", String(T - 273.15, \".1f\"))"
    << "DynamicSelect(\"\",\"-272.1\")";

  QTest::addRow("DynamicSelect4")
    << "DynamicSelect(\"\", String((if use_T_in then T_in else T) - 273.15, \".1f\"))"
    << "DynamicSelect(\"\",\"-272.1\")";

  QTest::addRow("DynamicSelect5")
    << "DynamicSelect({{-100, 10}, {-100, 10}}, {{100.0, 10.0}, {100.0 + 200.0 * max(-1.0, min(0.0, m_flow / abs(m_flow_nominal))), -10.0}})"
    << "DynamicSelect({{-100,10},{-100,10}},{{100,10},{100,-10}})";

  QTest::addRow("DynamicSelect6")
    << "DynamicSelect({{-100, 10}, {-100, 10}}, {{-100.0, 10.0}, {(-100.0) + 200.0 * min(1.0, max(0.0, m_flow / abs(m_flow_nominal))), -10.0}})"
    << "DynamicSelect({{-100,10},{-100,10}},{{-100,10},{100,-10}})";

  QTest::addRow("DynamicSelect7")
    << "DynamicSelect({{-100, 10}, {-100, 10}}, {{-100.0, 10.0}, {(-100.0) + 100.0 * min(1.0, max(0.0, port_1.m_flow * 3.0 / (abs(m_flow_nominal[1]) + abs(m_flow_nominal[2]) + abs(m_flow_nominal[3])))), -10.0}})"
    << "DynamicSelect({{-100,10},{-100,10}},{{-100,10},{0,-10}})";

  QTest::addRow("DynamicSelect8")
    << "DynamicSelect({{-100, 10}, {-100, 10}}, {{0.0, 10.0}, {100.0 * max(-1.0, min(0.0, port_1.m_flow * 3.0 / (abs(m_flow_nominal[1]) + abs(m_flow_nominal[2]) + abs(m_flow_nominal[3])))), -10.0}})"
    << "DynamicSelect({{-100,10},{-100,10}},{{0,10},{0,-10}})";

  QTest::addRow("DynamicSelect9")
    << "DynamicSelect({{0, 10}, {0, 10}}, {{100.0, 10.0}, {(1.0 - min(1.0, max(0.0, port_2.m_flow * 3.0 / (abs(m_flow_nominal[1]) + abs(m_flow_nominal[2]) + abs(m_flow_nominal[3]))))) * 100.0, -10.0}})"
    << "DynamicSelect({{0,10},{0,10}},{{100,10},{0,-10}})";

  QTest::addRow("DynamicSelect10")
    << "DynamicSelect({{0, 10}, {0, 10}}, {{0.0, 10.0}, {-max(-1.0, min(0.0, port_2.m_flow * 3.0 / (abs(m_flow_nominal[1]) + abs(m_flow_nominal[2]) + abs(m_flow_nominal[3])))) * 100.0, -10.0}})"
    << "DynamicSelect({{0,10},{0,10}},{{0,10},{-0,-10}})";

  QTest::addRow("DynamicSelect11")
    << "DynamicSelect({{-10, 0}, {-10, 0}}, {{-10.0, (-100.0) + 100.0 * min(1.0, max(0.0, port_3.m_flow * 3.0 / (abs(m_flow_nominal[1]) + abs(m_flow_nominal[2]) + abs(m_flow_nominal[3]))))}, {10.0, -100.0}})"
    << "DynamicSelect({{-10,0},{-10,0}},{{-10,0},{10,-100}})";

  QTest::addRow("DynamicSelect12")
    << "DynamicSelect({{-10, 0}, {-10, 0}}, {{-10.0, 100.0 * max(-1.0, min(0.0, port_3.m_flow * 3.0 / (abs(m_flow_nominal[1]) + abs(m_flow_nominal[2]) + abs(m_flow_nominal[3]))))}, {10.0, 0.0}})"
    << "DynamicSelect({{-10,0},{-10,0}},{{-10,0},{10,0}})";

  QTest::addRow("DynamicSelect13")
    << "DynamicSelect({{-35, 35}, {35, -35}}, {{-0.0, 0.0}, {0.0, -0.0}})"
    << "DynamicSelect({{-35,35},{35,-35}},{{-0,0},{0,-0}})";

  QTest::addRow("DynamicSelect14")
    << "DynamicSelect({170, 213, 255}, {min(1.0, max(0.0, 1.0 - (T - 273.15) / 50.0)) * 28.0 + min(1.0, max(0.0, (T - 273.15) / 50.0)) * 255.0, min(1.0, max(0.0, 1.0 - (T - 273.15) / 50.0)) * 108.0, min(1.0, max(0.0, 1.0 - (T - 273.15) / 50.0)) * 200.0})"
    << "DynamicSelect({170,213,255},{28,108,200})";

  QTest::addRow("DynamicSelect15")
    << "DynamicSelect({0, 127, 255}, {min(1.0, max(0.0, 1.0 - ((if use_T_in then T_in else T) - 273.15) / 50.0)) * 28.0 + min(1.0, max(0.0, ((if use_T_in then T_in else T) - 273.15) / 50.0)) * 255.0, min(1.0, max(0.0, 1.0 - ((if use_T_in then T_in else T) - 273.15) / 50.0)) * 108.0, min(1.0, max(0.0, 1.0 - ((if use_T_in then T_in else T) - 273.15) / 50.0)) * 200.0})"
    << "DynamicSelect({0,127,255},{28,108,200})";
}

void ExpressionTest::operators()
{
  QFETCH(QString, string);
  QFETCH(QString, result);

  try {
    QCOMPARE(evalString(string), result);
  } catch (const std::exception &e) {
    qDebug() << e.what();
    QFAIL(QString("Failed to evaluate: ").arg(string).toStdString().c_str());
  }
}

void ExpressionTest::operators_data()
{
  QTest::addColumn<QString>("string");
  QTest::addColumn<QString>("result");

  QTest::newRow("unary1")
    << "-17"
    << "-17";

  QTest::newRow("unary2")
    << "-3 + x"
    << "-2";

  QTest::newRow("unary3")
    << "x + -5"
    << "-4";

  QTest::newRow("logic1")
    << "x and y or z"
    << "true";

  QTest::newRow("logic2")
    << "{true, true, false} and {true, false, true}"
    << "{true,false,false}";

  QTest::newRow("arithmetic1")
    << "1 + 4 * 5 / 2 + x"
    << "12";

  QTest::newRow("array + array")
    << "{1, 2, 3} + {4, 5, 6}"
    << "{5,7,9}";

  QTest::newRow("scalar .+ array")
    << "1 .+ {1, 2, 3}"
    << "{2,3,4}";

  QTest::newRow("array .- array")
    << "{1, 2, 3} .- {6, 5, 4}"
    << "{-5,-3,-1}";

  QTest::newRow("array .- scalar")
    << "{4, 3, 2} .- 2"
    << "{2,1,0}";

  QTest::newRow("array .^ scalar")
    << "{3, 4, 5} .^ 2"
    << "{9,16,25}";

  QTest::newRow("matrix * vector")
    << "{{1, 2}, {3, 4}} * {5, 6}"
    << "{17,39}";

  QTest::newRow("vector * matrix")
    << "{5, 6} * {{1, 2}, {3, 4}}"
    << "{23,34}";

  QTest::newRow("matrix * matrix")
    << "{{1, 2, 4}, {3, 4, 6}, {4, 6, 3}} * {{5, 6, 9}, {7, 8, 3}, {3, 4, 7}}"
    << "{{31,38,43},{61,74,81},{71,84,75}}";

  QTest::newRow("matrix ^ scalar")
    << "{{1, 2}, {3, 4}} ^ 3"
    << "{{37,54},{81,118}}";

  QTest::newRow("- array")
    << "-{1, 2, 3}"
    << "{-1,-2,-3}";

  QTest::newRow("relation 1")
    << "x == y"
    << "true";

  QTest::newRow("relation 2")
    << "x > y"
    << "false";

  QTest::newRow("relation 3")
    << "x >= y"
    << "true";

  QTest::newRow("relation 4")
    << "not x == y"
    << "false";
}

void ExpressionTest::functions()
{
  QFETCH(QString, string);
  QFETCH(QString, result);

  try {
    QCOMPARE(evalString(string), result);
  } catch (const std::exception &e) {
    qDebug() << e.what();
    QFAIL(QString("Failed to evaluate: ").arg(string).toStdString().c_str());
  }
}

void ExpressionTest::functions_data()
{
  QTest::addColumn<QString>("string");
  QTest::addColumn<QString>("result");

  QTest::newRow("integer")
    << "integer(-3.8)"
    << "-4";

  QTest::newRow("ones")
    << "ones(3, 4)"
    << "{{1,1,1,1},{1,1,1,1},{1,1,1,1}}";

  QTest::newRow("fill")
    << "fill(true, 2, 3)"
    << "{{true,true,true},{true,true,true}}";

  QTest::newRow("sum1")
    << "sum(ones(4, 5))"
    << "20";

  QTest::newRow("min1")
    << "min({{2, 3, 4}, {-8, 1, 9}})"
    << "-8";

  QTest::newRow("min2")
    << "min({{}, {1, 2}})"
    << "1";

  QTest::newRow("min3")
    << "min({})"
    << "1.79769e+308";

  QTest::newRow("transpose")
    << "transpose({{1, 2}, {3, 4}})"
    << "{{1,3},{2,4}}";

  QTest::newRow("symmetric")
    << "symmetric({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}})"
    << "{{1,2,3},{2,5,6},{3,6,9}}";

  QTest::newRow("size1")
    << "size({{1, 2, 3}, {4, 5, 6}})"
    << "{2,3}";

  QTest::newRow("size2")
    << "size({{1, 2, 3}, {4, 5, 6}}, 2)"
    << "3";

  QTest::newRow("identity")
    << "identity(3)"
    << "{{1,0,0},{0,1,0},{0,0,1}}";

  QTest::newRow("diagonal")
    << "diagonal({1, 2, 3})"
    << "{{1,0,0},{0,2,0},{0,0,3}}";
}

void ExpressionTest::parseJSON()
{
  QFETCH(QJsonValue, jsonValue);
  QFETCH(QString, string);

  try {
    FlatModelica::Expression e;
    e.deserialize(jsonValue);
    qDebug() << e.toQString();
    //qDebug() << jsonValue;
    //qDebug() << e.serialize();
    QCOMPARE(e.serialize(), jsonValue);
    QCOMPARE(e.toQString(), string);
  } catch (const std::exception &e) {
    QFAIL(e.what());
  }
}

void ExpressionTest::parseJSON_data()
{
  QTest::addColumn<QJsonValue>("jsonValue");
  QTest::addColumn<QString>("string");
  QJsonValue value;

  value = 3;
  QTest::newRow("json_integer1") << value << "3";

  value = -52;
  QTest::newRow("json_integer2") << value << "-52";

  value = 3.14;
  QTest::newRow("json_real1") << value << "3.14";

  value = true;
  QTest::newRow("json_boolean1") << value << "true";

  value = false;
  QTest::newRow("json_boolean2") << value << "false";

  value = "string";
  QTest::newRow("json_string1") << value << "\"string\"";

  value = QJsonArray{1, 2, 3, 4, 5};
  QTest::newRow("json_array1") << value << "{1,2,3,4,5}";

  //value = QJsonObject{
  //  {"$kind", "cref"},
  //  {"parts", QJsonArray{
  //    QJsonObject{
  //      {"name", "a"},
  //      {"subscripts", QJsonArray{1, 2, ":"}}
  //    },
  //    QJsonObject{
  //      {"name", "b"}
  //    },
  //    QJsonObject{
  //      {"name", "c"},
  //      {"subscripts", QJsonArray{3}}
  //    }
  //  }}
  //};
  //QTest::newRow("json_cref1") << value;

  value = QJsonObject{
    {"$kind", "record"},
    {"name", "TestRecord"},
    {"elements", QJsonArray{4, "test"}}
  };
  QTest::newRow("json_record1") << value << "TestRecord(4,\"test\")";

  value = QJsonObject{
    {"$kind", "call"},
    {"name", "fill"},
    {"arguments", QJsonArray{1, 2, 3}}
  };
  QTest::newRow("json_call1") << value << "fill(1,2,3)";

  value = QJsonObject{
    {"$kind", "binary_op"},
    {"lhs", QJsonArray{1, 2, 3}},
    {"op", ".+"},
    {"rhs", QJsonArray{4, 5, 6}}
  };
  QTest::newRow("json_binary1") << value << "{1,2,3} .+ {4,5,6}";

  value = QJsonObject{
    {"$kind", "unary_op"},
    {"op", "not"},
    {"exp", false}
  };
  QTest::newRow("json_unary1") << value << "not false";

  value = QJsonObject{
    {"$kind", "if"},
    {"condition", true},
    {"true", 1},
    {"false", 2}
  };
  QTest::newRow("json_if1") << value << "if true then 1 else 2";

  value = QJsonObject{
    {"$kind", "binary_op"},
    {"lhs", QJsonObject{
      {"$kind", "if"},
      {"condition", true},
      {"true", 1},
      {"false", 2}
    }},
    {"op", "<"},
    {"rhs", 0.7}
  };
  QTest::newRow("json_if2") << value << "(if true then 1 else 2) < 0.7";

  value = QJsonObject{
    {"$kind", "enum"},
    {"name", "FillPattern.Solid"},
    {"index", 1}
  };
  QTest::newRow("json_enum") << value << "FillPattern.Solid";

  value = QJsonObject{
    {"$kind", "range"},
    {"start", 1},
    {"stop", 4}
  };
  QTest::newRow("json_range1") << value << "1:4";

  value = QJsonObject{
    {"$kind", "range"},
    {"start", 3},
    {"step", 2},
    {"stop", 11}
  };
  QTest::newRow("json_range2") << value << "3:2:11";

  value = QJsonObject{
    {"$kind", "iterator_call"},
    {"name", "$array"},
    {"exp", 1},
    {"iterators", QJsonArray{
      QJsonObject{
          {"name", "i"},
          {"range", QJsonObject{{"$kind", "range"}, {"start", 1}, {"stop", 3}}}
        },
      QJsonObject{
          {"name", "j"},
          {"range", QJsonObject{{"$kind", "range"}, {"start", 2}, {"stop", 4}}}
        }
      }
    }
  };
  QTest::newRow("json_iterator_call1") << value << "{1 for i in 1:3, j in 2:4}";
}

void ExpressionTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
