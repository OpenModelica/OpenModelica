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

#ifndef MEASURE_TIME_STATISTIC_HPP_
#define MEASURE_TIME_STATISTIC_HPP_

#include <Core/Utils/extension/measure_time_rdtsc.hpp>

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValuesStatistic :
public
MeasureTimeValuesRDTSC
{
public:
  unsigned long long _minTime;
  unsigned long long _killTime;

  MeasureTimeValuesStatistic(unsigned long long time);
  MeasureTimeValuesStatistic(const MeasureTimeValuesStatistic &timeValues);

  virtual ~MeasureTimeValuesStatistic();

  virtual std::string serializeToJson() const;

  virtual void add(MeasureTimeValues *values);
  virtual void sub(MeasureTimeValues *values);

  virtual MeasureTimeValuesStatistic* clone() const;
  virtual void reset();

private:
  long double _quadSum; // used to calculate standard variation sqrt(sum_i(xi-xaverage))
  unsigned _count;

  void filter(unsigned long long val);

};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeStatistic :
public
MeasureTimeRDTSC
{
protected:
  MeasureTimeStatistic();
  MeasureTimeValues* getZeroValuesP() const;

public:
  virtual ~MeasureTimeStatistic();

  static void initialize()
  {
    _instance = new MeasureTimeStatistic();
    _instance->setOverheadToZero();
  }
};

#endif /* MEASURE_TIME_STATISTIC_HPP_ */
