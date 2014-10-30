/*
 * measure_time_scorep.hpp
 *
 *  Created on: 17.10.2014
 *      Author: marcus
 */

#ifndef MEASURE_TIME_SCOREP_HPP_
#define MEASURE_TIME_SCOREP_HPP_

#include <Core/Utils/extension/measure_time.hpp>

class MeasureTimeValuesScoreP : public MeasureTimeValues
{
public:
  MeasureTimeValuesScoreP();
  virtual ~MeasureTimeValuesScoreP();

  virtual std::string serializeToJson(unsigned int numCalcs);

  virtual void add(MeasureTimeValues *values);
  virtual void sub(MeasureTimeValues *values);
  virtual void div(int counter);
};

class MeasureTimeScoreP : public MeasureTime
{
 protected:
  MeasureTimeScoreP();

  MeasureTimeValues* getZeroValuesP();
  void getTimeValuesStartP(MeasureTimeValues *res);
  void getTimeValuesEndP(MeasureTimeValues *res);

 public:
  virtual ~MeasureTimeScoreP();

  static void initialize()
  {
    instance = new MeasureTimeScoreP();
    instance->benchOverhead();
  }

  virtual void initializeThread(unsigned long int (*threadHandle)());
  virtual void deinitializeThread(unsigned long int (*threadHandle)());
};

#endif /* MEASURE_TIME_SCOREP_HPP_ */
