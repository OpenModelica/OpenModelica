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

#ifndef HOMOTOPYTEST_H
#define HOMOTOPYTEST_H

#include <QObject>
#include <QProcess>

/*!
 * \brief The HomotopyTest class
 * This test check the simulation of model containing the logging annotation.
 * `HomotopyTest.M1` contains `annotation(__OpenModelica_simulationFlags(lv="LOG_NLS_V"));`
 * `HomotopyTest.M2` contains `annotation(__OpenModelica_simulationFlags(lv="LOG_NLS_V,LOG_INIT_HOMOTOPY"));`
 */
class HomotopyTest: public QObject
{
  Q_OBJECT
private slots:
  /*!
   * \brief initTestCase
   * Loads the HomotopyTest.mo file.
   */
  void initTestCase();
  /*!
   * \brief simulateHomotopyTestM1
   * Simulates the HomotopyTest.M1 model.
   */
  void simulateHomotopyTestM1();
  /*!
   * \brief simulateHomotopyTestM2
   * Simulates the HomotopyTest.M2 model.
   */
  void simulateHomotopyTestM2();
  void cleanupTestCase();
public:
  /*!
   * \brief simulate
   * Simulates the class.
   * \param className
   */
  void simulate(const QString &className);
  void readSimulationLogFile(const QString &simulationLogFilePath);
};

#endif // HOMOTOPYTEST_H
