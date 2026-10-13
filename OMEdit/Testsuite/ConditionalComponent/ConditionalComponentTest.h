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

#ifndef CONDITIONALCOMPONENTTEST_H
#define CONDITIONALCOMPONENTTEST_H

#include <QObject>

/*!
 * \brief The ConditionalComponentTest class
 * Tests the conditional component support in the element attributes dialog.
 */
class ConditionalComponentTest : public QObject
{
  Q_OBJECT
private slots:
  void initTestCase();
  /*!
   * \brief componentConditionFromSource
   * Checks that OMCProxy::getComponentCondition returns the condition of a
   * component declared conditional in the source and an empty string for a
   * component without a condition.
   */
  void componentConditionFromSource();
  /*!
   * \brief setAndRemoveComponentCondition
   * Checks that OMCProxy::setComponentCondition can add a condition and that
   * passing an empty string removes it again.
   */
  void setAndRemoveComponentCondition();
  /*!
   * \brief attributesDialogShowsCondition
   * Checks that the element attributes dialog reads the condition of a
   * component into the checkable "Conditional Component" group box.
   */
  void attributesDialogShowsCondition();
  /*!
   * \brief attributesDialogSetsAndRemovesCondition
   * Checks that setting/removing the condition in the element attributes
   * dialog and accepting it updates the component in the model.
   */
  void attributesDialogSetsAndRemovesCondition();
  void cleanupTestCase();
};

#endif // CONDITIONALCOMPONENTTEST_H
