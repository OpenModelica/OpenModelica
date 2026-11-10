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

#ifndef REPLACEABLECONSTRAINEDBYTEST_H
#define REPLACEABLECONSTRAINEDBYTEST_H

#include <QObject>

/*!
 * \brief The ReplaceableConstrainedByTest class
 * Tests the modifier values handed down from a replaceable component to the
 * parameters dialog of the class replacing it.
 */
class ReplaceableConstrainedByTest : public QObject
{
  Q_OBJECT
private slots:
  void initTestCase();
  /*!
   * \brief subDialogUsesParameterDefaultValue
   * Opens the parameters dialog of the replRecord1 replaceable component. Its
   * constrainedby modifier gets the value of the enclosing typeParam parameter,
   * which is not set but has a default value. The sub dialog of replRecord1 must
   * evaluate its enable annotations with that default value.
   */
  void subDialogUsesParameterDefaultValue();
  void cleanupTestCase();
};

#endif // REPLACEABLECONSTRAINEDBYTEST_H
