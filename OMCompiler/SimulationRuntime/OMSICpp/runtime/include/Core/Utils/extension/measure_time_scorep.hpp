/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/*
 * measure_time_scorep.hpp
 *
 *  Created on: 17.10.2014
 *      Author: marcus
 */

#ifndef MEASURE_TIME_SCOREP_HPP_
#define MEASURE_TIME_SCOREP_HPP_

#include <Core/Utils/extension/measure_time.hpp>

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValuesScoreP :
public
MeasureTimeValues
{
public:
  MeasureTimeValuesScoreP();
  MeasureTimeValuesScoreP(const MeasureTimeValuesScoreP &timeValues);
  virtual ~MeasureTimeValuesScoreP();

  virtual std::string serializeToJson() const;

  virtual void add(MeasureTimeValues *values);
  virtual void sub(MeasureTimeValues *values);
  virtual void div(int counter);

  MeasureTimeValuesScoreP* clone() const;
  virtual void reset();
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeScoreP :
public
MeasureTime
{
 protected:
  MeasureTimeScoreP();

  MeasureTimeValues* getZeroValuesP() const;
  void getTimeValuesStartP(MeasureTimeValues *res) const;
  void getTimeValuesEndP(MeasureTimeValues *res) const;

 public:
  virtual ~MeasureTimeScoreP();

  static void initialize()
  {
    _instance = new MeasureTimeScoreP();
    _instance->benchOverhead();
  }

  virtual void initializeThread(unsigned long int threadNumber);
  virtual void deinitializeThread();
};

#endif /* MEASURE_TIME_SCOREP_HPP_ */
