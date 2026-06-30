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

#ifndef EBDDRUNTIMETEST_H
#define EBDDRUNTIMETEST_H

#include <QObject>

/*!
 * \brief The EbddRuntimeTest class
 * Tests parsing of the Equation-Based Declarative Debugger runtime info file
 * (<model>_dbg.json) into the transformational debugger's equation model.
 */
class EbddRuntimeTest : public QObject
{
  Q_OBJECT

private slots:
  /*!
   * \brief parsesRuntimeInfo
   * Tests TransformationsWidget::parseRuntimeInfoFile: records keyed by eqIndex
   * are attached to the matching equations, the meta header line is ignored and
   * each iteration variable's value/residual is read.
   */
  void parsesRuntimeInfo();
  /*!
   * \brief parsesNewtonIterations
   * Tests that "newtonIteration" records are parsed, carrying the 1-based
   * iteration index and each variable's scaled residual.
   */
  void parsesNewtonIterations();
  /*!
   * \brief parsesJacobian
   * Tests that "jacobian" records are parsed into the column labels and the
   * dense matrix rows.
   */
  void parsesJacobian();
  /*!
   * \brief parsesHomotopy
   * Tests that "homotopy" records are parsed, carrying the step index, the
   * continuation parameter lambda and the path point per variable.
   */
  void parsesHomotopy();
  /*!
   * \brief parsesEventIterations
   * Tests that model-level "eventIteration" records (eqIndex < 0) are routed to
   * the model-level list, not attached to an equation, carrying the discrete
   * variable values.
   */
  void parsesEventIterations();
  /*!
   * \brief parsesChattering
   * Tests that "chattering" records attach to the implicated equation, carrying
   * the time window, the state-event count and the zero-crossing description.
   */
  void parsesChattering();
  /*!
   * \brief parsesNullSpace
   * Tests that "nullSpace" records attach to the equation system, carrying the
   * linearly-dependent variables involved in the singularity.
   */
  void parsesNullSpace();
  /*!
   * \brief parsesConvergenceDiagnostics
   * Tests that "convergenceDiagnostics" records attach to the equation system,
   * carrying the non-linear equation count and the non-linear variables.
   */
  void parsesConvergenceDiagnostics();
  void cleanupTestCase();
};

#endif // EBDDRUNTIMETEST_H
