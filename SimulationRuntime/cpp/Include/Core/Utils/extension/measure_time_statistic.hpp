#ifndef MEASURE_TIME_STATISTIC_HPP_
#define MEASURE_TIME_STATISTIC_HPP_

#include <Core/Utils/extension/measure_time_rdtsc.hpp>

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValuesStatistic : public MeasureTimeValuesRDTSC
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

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeStatistic : public MeasureTimeRDTSC
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
