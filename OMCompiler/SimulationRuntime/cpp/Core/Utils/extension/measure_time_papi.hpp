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
 * measure_time_papi.hpp
 *
 *  Created on: 08.09.2014
 *      Author: marcus
 */

#ifndef MEASURE_TIME_PAPI_HPP_
#define MEASURE_TIME_PAPI_HPP_

#define NUM_PAPI_EVENTS 3

#include <Core/Utils/extension/measure_time.hpp>

#ifdef USE_PAPI
#include <papi.h>
#endif

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValuesPAPI : public MeasureTimeValues
{
public:
  unsigned long long _time;
  long long _l2CacheMisses;
  long long _instructions;

  unsigned long long _maxTime;

  MeasureTimeValuesPAPI(unsigned long long time, long long l2CacheMisses, long long instructions);
  MeasureTimeValuesPAPI(const MeasureTimeValuesPAPI &timeValues);
  virtual ~MeasureTimeValuesPAPI();

  virtual std::string serializeToJson() const;

  virtual void add(MeasureTimeValues *values);
  virtual void sub(MeasureTimeValues *values);
  virtual void div(int counter);

  virtual MeasureTimeValuesPAPI* clone() const;
  virtual void reset();
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimePAPI : public MeasureTime
{
 protected:
  MeasureTimePAPI(unsigned long int (*threadHandle)());

  MeasureTimeValues* getZeroValuesP() const;
  void getTimeValuesStartP(MeasureTimeValues *res) const;
  void getTimeValuesEndP(MeasureTimeValues *res) const;

 public:
  virtual ~MeasureTimePAPI();

  static void initialize(unsigned long int (*threadHandle)())
  {
    _instance = new MeasureTimePAPI(threadHandle);
    _instance->benchOverhead();
  }

  void initializeDirty()
  {
    #ifdef USE_PAPI
    if (PAPI_create_eventset(&_eventSet) != PAPI_OK)
    {
      std::cerr << "PAPI create eventset failed!" << " Error: " << PAPI_create_eventset(&_eventSet) << std::endl;
      exit(1);
    }

    if (PAPI_add_events(_eventSet, _events, NUM_PAPI_EVENTS) != PAPI_OK)
    {
      std::cerr << "PAPI add events failed!" << std::endl;
      exit(1);
    }

    if (PAPI_start(_eventSet) != PAPI_OK)
    {
      std::cerr << "PAPI_start_counters - FAILED" << std::endl;
      throw ModelicaSimulationError(UTILITY,"PAPI_start_counters - FAILED");

    }
    #endif
    _instance->benchOverhead();
  }

  virtual void initializeThread(unsigned long int threadNumber);
  virtual void deinitializeThread();

 private:
  int* _events;
  int _eventSet;
  unsigned long int (*threadHandle)();
};

#endif /* MEASURE_TIME_PAPI_HPP_ */
