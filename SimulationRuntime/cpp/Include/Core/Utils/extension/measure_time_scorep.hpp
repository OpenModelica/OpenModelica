/*
 * measure_time_scorep.hpp
 *
 *  Created on: 17.10.2014
 *      Author: marcus
 */

#ifndef MEASURE_TIME_SCOREP_HPP_
#define MEASURE_TIME_SCOREP_HPP_

#include <Core/Utils/extension/measure_time.hpp>

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValuesScoreP : public MeasureTimeValues
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

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeScoreP : public MeasureTime
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
