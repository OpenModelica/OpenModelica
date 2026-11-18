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

#ifndef ELEMENTMODEMODIFIERSTEST_H
#define ELEMENTMODEMODIFIERSTEST_H

#include <QObject>

/*!
 * \brief The ElementModeModifiersTest class
 * Tests the parameters dialog of an element shown with Show Element when the
 * modifiers of the element are given in the parent elements.
 */
class ElementModeModifiersTest : public QObject
{
  Q_OBJECT
private:
  void showParameter(const QString &className, QString *pValue, QString *pDefaultValue);
private slots:
  void initTestCase();
  /*!
   * \brief modifierFromIntermediateParent
   * Issue #18148. S2 extends S1, which has m2(m1(p = 1)). The modifier of the
   * intermediate parent m2 must show as the default value of m1.p.
   */
  void modifierFromIntermediateParent();
  /*!
   * \brief outerModifierOverridesInner
   * S3 extends S1(m2(m1(p = 2))). The outer modifier in S3 overrides the one
   * in S1 and is the value of m1.p.
   */
  void outerModifierOverridesInner();
  void cleanupTestCase();
};

#endif // ELEMENTMODEMODIFIERSTEST_H
