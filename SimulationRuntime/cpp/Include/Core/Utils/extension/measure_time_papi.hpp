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
  unsigned long long time;
  long long l2CacheMisses;
  long long instructions;

  unsigned long long max_time;

  MeasureTimeValuesPAPI(unsigned long long time, long long l2CacheMisses, long long instructions);
  virtual ~MeasureTimeValuesPAPI();

  virtual std::string serializeToJson();

  virtual void add(MeasureTimeValues *values);
  virtual void sub(MeasureTimeValues *values);
  virtual void div(int counter);
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimePAPI : public MeasureTime
{
 protected:
  MeasureTimePAPI(unsigned long int (*threadHandle)());

  MeasureTimeValues* getZeroValuesP();
  void getTimeValuesStartP(MeasureTimeValues *res);
  void getTimeValuesEndP(MeasureTimeValues *res);

 public:
  virtual ~MeasureTimePAPI();

  static void initialize(unsigned long int (*threadHandle)())
  {
    instance = new MeasureTimePAPI(threadHandle);
    instance->benchOverhead();
  }

  void initializeDirty()
  {
    #ifdef USE_PAPI
    if (PAPI_create_eventset(&eventSet) != PAPI_OK)
    {
      std::cerr << "PAPI create eventset failed!" << " Error: " << PAPI_create_eventset(&eventSet) << std::endl;
      exit(1);
    }

    if (PAPI_add_events(eventSet, events, NUM_PAPI_EVENTS) != PAPI_OK)
    {
      std::cerr << "PAPI add events failed!" << std::endl;
      exit(1);
    }

    if (PAPI_start(eventSet) != PAPI_OK)
    {
      std::cerr << "PAPI_start_counters - FAILED" << std::endl;
      throw ModelicaSimulationError(UTILITY,"PAPI_start_counters - FAILED");
      
    }
    #endif
    instance->benchOverhead();
  }

  virtual void initializeThread(unsigned long int threadNumber);
  virtual void deinitializeThread();

 private:
  int* events;
  int eventSet;
  unsigned long int (*threadHandle)();
};

#endif /* MEASURE_TIME_PAPI_HPP_ */
