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

#include "EbddRuntimeTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "TransformationalDebugger/TransformationsWidget.h"
#include "TransformationalDebugger/OMDumpXML.h"

#include <QTemporaryFile>

OMEDITTEST_MAIN(EbddRuntimeTest)

void EbddRuntimeTest::parsesRuntimeInfo()
{
  // Equations are matched by their index; getOMEquation skips list position 0.
  QList<OMEquation*> equations;
  OMEquation *dummy = new OMEquation(); dummy->index = 0;
  OMEquation *eq6 = new OMEquation();   eq6->index = 6;
  OMEquation *eq12 = new OMEquation();  eq12->index = 12;
  equations << dummy << eq6 << eq12;

  // A <model>_dbg.json as produced by the runtime: a meta header line followed
  // by one JSON object per solved nonlinear system.
  QTemporaryFile file;
  QVERIFY(file.open());
  file.write("{\"format\":\"EBDD runtime info\",\"version\":1,\"model\":\"M\"}\n");
  file.write("{\"kind\":\"nonlinear\",\"eqIndex\":6,\"section\":\"initial\",\"time\":0,\"status\":\"solved\",\"iterations\":7,\"size\":1,\"vars\":[{\"name\":\"y\",\"value\":0.25,\"residual\":2,\"nominal\":1}]}\n");
  file.write("{\"kind\":\"nonlinear\",\"eqIndex\":12,\"section\":\"regular\",\"time\":0.5,\"status\":\"solved\",\"iterations\":5,\"size\":1,\"vars\":[{\"name\":\"y\",\"value\":0.75,\"residual\":0,\"nominal\":1}]}\n");
  const QString fileName = file.fileName();
  file.close();

  TransformationsWidget::parseRuntimeInfoFile(equations, fileName);

  // eq6 (initial system) got one solve carrying the iteration variable 'y'.
  QCOMPARE(eq6->runtimeSolves.size(), 1);
  QCOMPARE(eq6->runtimeSolves.at(0).section, QStringLiteral("initial"));
  QCOMPARE(eq6->runtimeSolves.at(0).status, QStringLiteral("solved"));
  QCOMPARE(eq6->runtimeSolves.at(0).iterations, 7);
  QCOMPARE(eq6->runtimeSolves.at(0).variables.size(), 1);
  QCOMPARE(eq6->runtimeSolves.at(0).variables.at(0).name, QStringLiteral("y"));
  QCOMPARE(eq6->runtimeSolves.at(0).variables.at(0).value, 0.25);
  QCOMPARE(eq6->runtimeSolves.at(0).variables.at(0).residual, 2.0);

  // eq12 (regular system) got its own solve.
  QCOMPARE(eq12->runtimeSolves.size(), 1);
  QCOMPARE(eq12->runtimeSolves.at(0).time, 0.5);
  QCOMPARE(eq12->runtimeSolves.at(0).variables.at(0).value, 0.75);

  // the meta header line carries no eqIndex and must not create a record.
  QCOMPARE(dummy->runtimeSolves.size(), 0);

  qDeleteAll(equations);
}

void EbddRuntimeTest::parsesNewtonIterations()
{
  QList<OMEquation*> equations;
  OMEquation *dummy = new OMEquation(); dummy->index = 0;
  OMEquation *eq6 = new OMEquation();   eq6->index = 6;
  equations << dummy << eq6;

  // Two Newton-iteration records for the same system (eqIndex 6).
  QTemporaryFile file;
  QVERIFY(file.open());
  file.write("{\"format\":\"EBDD runtime info\",\"version\":1,\"model\":\"M\"}\n");
  file.write("{\"kind\":\"newtonIteration\",\"eqIndex\":6,\"section\":\"initial\",\"time\":0,\"iteration\":1,\"size\":1,\"vars\":[{\"name\":\"y\",\"value\":1,\"residual\":2,\"residualScaled\":0.5,\"nominal\":4}]}\n");
  file.write("{\"kind\":\"newtonIteration\",\"eqIndex\":6,\"section\":\"initial\",\"time\":0,\"iteration\":2,\"size\":1,\"vars\":[{\"name\":\"y\",\"value\":0.25,\"residual\":0.1,\"residualScaled\":0.025,\"nominal\":4}]}\n");
  const QString fileName = file.fileName();
  file.close();

  TransformationsWidget::parseRuntimeInfoFile(equations, fileName);

  QCOMPARE(eq6->runtimeSolves.size(), 2);
  QCOMPARE(eq6->runtimeSolves.at(0).kind, QStringLiteral("newtonIteration"));
  QCOMPARE(eq6->runtimeSolves.at(0).iteration, 1);
  QCOMPARE(eq6->runtimeSolves.at(0).variables.at(0).residualScaled, 0.5);
  QCOMPARE(eq6->runtimeSolves.at(1).iteration, 2);
  QCOMPARE(eq6->runtimeSolves.at(1).variables.at(0).value, 0.25);
  QCOMPARE(eq6->runtimeSolves.at(1).variables.at(0).residualScaled, 0.025);

  qDeleteAll(equations);
}

void EbddRuntimeTest::parsesJacobian()
{
  QList<OMEquation*> equations;
  OMEquation *dummy = new OMEquation(); dummy->index = 0;
  OMEquation *eq6 = new OMEquation();   eq6->index = 6;
  equations << dummy << eq6;

  // A 2x2 Jacobian record for system eqIndex 6.
  QTemporaryFile file;
  QVERIFY(file.open());
  file.write("{\"format\":\"EBDD runtime info\",\"version\":1,\"model\":\"M\"}\n");
  file.write("{\"kind\":\"jacobian\",\"eqIndex\":6,\"section\":\"initial\",\"time\":0,\"iteration\":2,\"size\":2,\"vars\":[\"x\",\"y\"],\"rows\":[[1.5,2],[3,4.25]]}\n");
  const QString fileName = file.fileName();
  file.close();

  TransformationsWidget::parseRuntimeInfoFile(equations, fileName);

  QCOMPARE(eq6->runtimeSolves.size(), 1);
  const OMRuntimeSolve &solve = eq6->runtimeSolves.at(0);
  QCOMPARE(solve.kind, QStringLiteral("jacobian"));
  QCOMPARE(solve.iteration, 2);
  QCOMPARE(solve.jacobianVars.size(), 2);
  QCOMPARE(solve.jacobianVars.at(1), QStringLiteral("y"));
  QCOMPARE(solve.jacobianRows.size(), 2);
  QCOMPARE(solve.jacobianRows.at(0).at(1), 2.0);
  QCOMPARE(solve.jacobianRows.at(1).at(1), 4.25);

  qDeleteAll(equations);
}

void EbddRuntimeTest::parsesHomotopy()
{
  QList<OMEquation*> equations;
  OMEquation *dummy = new OMEquation(); dummy->index = 0;
  OMEquation *eq3 = new OMEquation();   eq3->index = 3;
  equations << dummy << eq3;

  QTemporaryFile file;
  QVERIFY(file.open());
  file.write("{\"format\":\"EBDD runtime info\",\"version\":1,\"model\":\"M\"}\n");
  file.write("{\"kind\":\"homotopy\",\"eqIndex\":3,\"section\":\"initial\",\"time\":0,\"step\":1,\"lambda\":0.2,\"size\":1,\"vars\":[{\"name\":\"x\",\"value\":1.15,\"residual\":7e-07}]}\n");
  file.write("{\"kind\":\"homotopy\",\"eqIndex\":3,\"section\":\"initial\",\"time\":0,\"step\":2,\"lambda\":1,\"size\":1,\"vars\":[{\"name\":\"x\",\"value\":1.3247,\"residual\":0}]}\n");
  const QString fileName = file.fileName();
  file.close();

  TransformationsWidget::parseRuntimeInfoFile(equations, fileName);

  QCOMPARE(eq3->runtimeSolves.size(), 2);
  QCOMPARE(eq3->runtimeSolves.at(0).kind, QStringLiteral("homotopy"));
  QCOMPARE(eq3->runtimeSolves.at(0).step, 1);
  QCOMPARE(eq3->runtimeSolves.at(0).lambda, 0.2);
  QCOMPARE(eq3->runtimeSolves.at(0).variables.at(0).name, QStringLiteral("x"));
  QCOMPARE(eq3->runtimeSolves.at(1).lambda, 1.0);
  QCOMPARE(eq3->runtimeSolves.at(1).variables.at(0).value, 1.3247);

  qDeleteAll(equations);
}

void EbddRuntimeTest::parsesEventIterations()
{
  QList<OMEquation*> equations;
  OMEquation *dummy = new OMEquation(); dummy->index = 0;
  OMEquation *eq6 = new OMEquation();   eq6->index = 6;
  equations << dummy << eq6;

  QTemporaryFile file;
  QVERIFY(file.open());
  file.write("{\"format\":\"EBDD runtime info\",\"version\":1,\"model\":\"M\"}\n");
  file.write("{\"kind\":\"eventIteration\",\"eqIndex\":-1,\"time\":0.5,\"iteration\":0,\"vars\":[{\"name\":\"b\",\"value\":1},{\"name\":\"c\",\"value\":2}]}\n");
  file.write("{\"kind\":\"eventIteration\",\"eqIndex\":-1,\"time\":0.5,\"iteration\":1,\"vars\":[{\"name\":\"b\",\"value\":1},{\"name\":\"c\",\"value\":2}]}\n");
  const QString fileName = file.fileName();
  file.close();

  QList<OMRuntimeSolve> modelSolves;
  TransformationsWidget::parseRuntimeInfoFile(equations, fileName, &modelSolves);

  // model-level records land in the model list, not on any equation.
  QCOMPARE(eq6->runtimeSolves.size(), 0);
  QCOMPARE(modelSolves.size(), 2);
  QCOMPARE(modelSolves.at(0).kind, QStringLiteral("eventIteration"));
  QCOMPARE(modelSolves.at(0).iteration, 0);
  QCOMPARE(modelSolves.at(0).variables.size(), 2);
  QCOMPARE(modelSolves.at(0).variables.at(0).name, QStringLiteral("b"));
  QCOMPARE(modelSolves.at(0).variables.at(1).value, 2.0);
  QCOMPARE(modelSolves.at(1).iteration, 1);

  qDeleteAll(equations);
}

void EbddRuntimeTest::parsesChattering()
{
  QList<OMEquation*> equations;
  OMEquation *dummy = new OMEquation(); dummy->index = 0;
  OMEquation *eq3 = new OMEquation();   eq3->index = 3;
  equations << dummy << eq3;

  QTemporaryFile file;
  QVERIFY(file.open());
  file.write("{\"format\":\"EBDD runtime info\",\"version\":1,\"model\":\"M\"}\n");
  file.write("{\"kind\":\"chattering\",\"eqIndex\":3,\"timeStart\":1.0,\"timeEnd\":1.02,\"stateEvents\":100,\"zeroCrossing\":\"x > 0.0\"}\n");
  const QString fileName = file.fileName();
  file.close();

  TransformationsWidget::parseRuntimeInfoFile(equations, fileName);

  QCOMPARE(eq3->runtimeSolves.size(), 1);
  const OMRuntimeSolve &solve = eq3->runtimeSolves.at(0);
  QCOMPARE(solve.kind, QStringLiteral("chattering"));
  QCOMPARE(solve.stateEvents, 100);
  QCOMPARE(solve.timeStart, 1.0);
  QCOMPARE(solve.timeEnd, 1.02);
  QCOMPARE(solve.zeroCrossing, QStringLiteral("x > 0.0"));

  qDeleteAll(equations);
}

void EbddRuntimeTest::parsesNullSpace()
{
  QList<OMEquation*> equations;
  OMEquation *dummy = new OMEquation(); dummy->index = 0;
  OMEquation *eq6 = new OMEquation();   eq6->index = 6;
  equations << dummy << eq6;

  QTemporaryFile file;
  QVERIFY(file.open());
  file.write("{\"format\":\"EBDD runtime info\",\"version\":1,\"model\":\"M\"}\n");
  file.write("{\"kind\":\"nullSpace\",\"eqIndex\":6,\"section\":\"initial\",\"time\":0,\"size\":2,\"linearlyDependentVars\":[\"w\",\"v\"]}\n");
  const QString fileName = file.fileName();
  file.close();

  TransformationsWidget::parseRuntimeInfoFile(equations, fileName);

  QCOMPARE(eq6->runtimeSolves.size(), 1);
  const OMRuntimeSolve &solve = eq6->runtimeSolves.at(0);
  QCOMPARE(solve.kind, QStringLiteral("nullSpace"));
  QCOMPARE(solve.linearlyDependentVars.size(), 2);
  QCOMPARE(solve.linearlyDependentVars.at(0), QStringLiteral("w"));
  QCOMPARE(solve.linearlyDependentVars.at(1), QStringLiteral("v"));

  qDeleteAll(equations);
}

void EbddRuntimeTest::parsesConvergenceDiagnostics()
{
  QList<OMEquation*> equations;
  OMEquation *dummy = new OMEquation(); dummy->index = 0;
  OMEquation *eq6 = new OMEquation();   eq6->index = 6;
  equations << dummy << eq6;

  QTemporaryFile file;
  QVERIFY(file.open());
  file.write("{\"format\":\"EBDD runtime info\",\"version\":1,\"model\":\"M\"}\n");
  file.write("{\"kind\":\"convergenceDiagnostics\",\"eqIndex\":6,\"section\":\"initial\",\"time\":0,\"size\":3,\"nonlinearEquations\":1,\"nonlinearVars\":[\"x\",\"y\"]}\n");
  const QString fileName = file.fileName();
  file.close();

  TransformationsWidget::parseRuntimeInfoFile(equations, fileName);

  QCOMPARE(eq6->runtimeSolves.size(), 1);
  const OMRuntimeSolve &solve = eq6->runtimeSolves.at(0);
  QCOMPARE(solve.kind, QStringLiteral("convergenceDiagnostics"));
  QCOMPARE(solve.nonlinearEquations, 1);
  QCOMPARE(solve.nonlinearVars.size(), 2);
  QCOMPARE(solve.nonlinearVars.at(0), QStringLiteral("x"));
  QCOMPARE(solve.nonlinearVars.at(1), QStringLiteral("y"));

  qDeleteAll(equations);
}

void EbddRuntimeTest::resolvesAliasEquations()
{
  // Mirrors the issue #10995 TestHomotopy case: a regular assign defines z, and
  // an initial-lambda0 alias equation aliases it.
  QList<OMEquation*> equations;
  QHash<QString, OMVariable> variables;
  OMVariable z; z.name = QStringLiteral("z"); variables.insert(QStringLiteral("z"), z);

  OMEquation *dummy = new OMEquation(); dummy->index = 0;
  OMEquation *orig = new OMEquation();
  orig->index = 12; orig->tag = QStringLiteral("assign"); orig->defines << QStringLiteral("z");
  orig->text << QStringLiteral("x - 3.0");
  OMEquation *alias = new OMEquation();
  alias->index = 9; alias->tag = QStringLiteral("alias"); alias->section = QStringLiteral("initial-lambda0");
  alias->aliasOf = 12;
  equations << dummy << orig << alias;

  // an alias resolves to its original; a non-alias resolves to itself.
  QCOMPARE(TransformationsWidget::resolveAliasEquation(equations, alias), orig);
  QCOMPARE(TransformationsWidget::resolveAliasEquation(equations, orig), orig);

  TransformationsWidget::enrichAliasEquations(equations, variables);

  // direction 1: the alias now carries the original's text/defines and toString
  // shows the full assignment next to the alias indicator.
  QCOMPARE(alias->text, orig->text);
  QCOMPARE(alias->defines, QStringList() << QStringLiteral("z"));
  QVERIFY(alias->toString().contains(QStringLiteral("alias of equation 12")));
  QVERIFY(alias->toString().contains(QStringLiteral("z := x - 3.0")));

  // direction 2 (#10995 comment): selecting z must list the alias equation among
  // the equations it is defined in, not just the regular one.
  QVERIFY(variables[QStringLiteral("z")].definedIn.contains(9));

  qDeleteAll(equations);
}

void EbddRuntimeTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
