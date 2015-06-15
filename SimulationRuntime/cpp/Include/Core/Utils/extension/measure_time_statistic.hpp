#ifndef MEASURE_TIME_STATISTIC_HPP_
#define MEASURE_TIME_STATISTIC_HPP_

#include <Core/Utils/extension/measure_time_rdtsc.hpp>

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValuesStatistic : public MeasureTimeValuesRDTSC
{
public:
  unsigned long long _min_time;
  unsigned long long _kill_time;

  MeasureTimeValuesStatistic(unsigned long long time);

  virtual ~MeasureTimeValuesStatistic();

  virtual std::string serializeToJson();

  virtual void add(MeasureTimeValues *values);
  virtual void sub(MeasureTimeValues *values);

private:
  long double _quad_sum; // used to calculate standard variation sqrt(sum_i(xi-xaverage))
  unsigned _count;

  void filter(unsigned long long val);

};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeStatistic : public MeasureTimeRDTSC
{
protected:
  MeasureTimeStatistic();

  MeasureTimeValues* getZeroValuesP();

public:
  virtual ~MeasureTimeStatistic();

  static void initialize()
  {
    instance = new MeasureTimeStatistic();
    instance->setOverheadToZero();
  }
};

#endif /* MEASURE_TIME_STATISTIC_HPP_ */
