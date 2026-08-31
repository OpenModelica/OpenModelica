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

#ifndef MEASURE_TIME_RDTSC_HPP_
#define MEASURE_TIME_RDTSC_HPP_

#include <Core/Utils/extension/measure_time.hpp>

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValuesRDTSC : public MeasureTimeValues
{
public:
  unsigned long long _time;
  unsigned long long _maxTime;

  MeasureTimeValuesRDTSC(unsigned long long time);
  MeasureTimeValuesRDTSC(const MeasureTimeValuesRDTSC &timeValues);
  virtual ~MeasureTimeValuesRDTSC();

  virtual std::string serializeToJson() const;

  virtual void add(MeasureTimeValues *values);
  virtual void sub(MeasureTimeValues *values);
  virtual void div(int counter);

  virtual MeasureTimeValuesRDTSC* clone() const;
  virtual void reset();
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeRDTSC : public MeasureTime
{
 protected:
  MeasureTimeRDTSC();

  MeasureTimeValues* getZeroValuesP() const;
  void getTimeValuesStartP(MeasureTimeValues *res) const;
  void getTimeValuesEndP(MeasureTimeValues *res) const;


 public:
  virtual ~MeasureTimeRDTSC();

  static void initialize()
  {
    _instance = new MeasureTimeRDTSC();
    _instance->setOverheadToZero();
  }

  virtual void initializeThread(unsigned long int threadNumber);
  virtual void deinitializeThread();


  static inline unsigned long long RDTSC(); //__attribute__((always_inline));

};

#endif /* MEASURE_TIME_RDTSC_HPP_ */
