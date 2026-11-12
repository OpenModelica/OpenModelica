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

#ifndef FMIGUIDETEST_H
#define FMIGUIDETEST_H

#include <QObject>

/*!
 * \brief The FMIGuideTest class
 * Tests the dialog that recommends the settings of an FMU export.
 */
class FMIGuideTest: public QObject
{
  Q_OBJECT
private slots:
  /*!
   * \brief recommendsWhatTheHostOffers
   * The recommendation follows the answers and stays inside what the host can export.
   */
  void recommendsWhatTheHostOffers();
  /*!
   * \brief refusesWhenNothingFits
   * Apply is off when no FMU of the host fits the answers.
   */
  void refusesWhenNothingFits();
  /*!
   * \brief recommendsPackaging
   * The platforms, the source code and the filter follow where the FMU runs and what must stay hidden.
   */
  void recommendsPackaging();
  void cleanupTestCase();
};

#endif // FMIGUIDETEST_H
