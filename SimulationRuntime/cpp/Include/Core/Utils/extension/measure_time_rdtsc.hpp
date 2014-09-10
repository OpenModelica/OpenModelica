#ifndef MEASURE_TIME_RDTSC_HPP_
#define MEASURE_TIME_RDTSC_HPP_

#include <Core/Utils/extension/measure_time.hpp>

class MeasureTimeValuesRDTSC : public MeasureTimeValues
{
public:
  unsigned long long time;

  MeasureTimeValuesRDTSC(unsigned long long time);
  virtual ~MeasureTimeValuesRDTSC();

  virtual std::string serializeToJson();

  virtual void add(MeasureTimeValues *values);
  virtual void sub(MeasureTimeValues *values);
  virtual void div(int counter);
};

class MeasureTimeRDTSC : public MeasureTime
{
 protected:
  MeasureTimeRDTSC();

  MeasureTimeValues* getZeroValuesP();

 public:
  virtual ~MeasureTimeRDTSC();

  static void initialize()
  {
    instance = new MeasureTimeRDTSC();
    MeasureTime::getTimeValuesFct = &MeasureTimeRDTSC::getTimeValues;
    instance->benchOverhead();
  }
  static void getTimeValues(MeasureTimeValues *res);

 private:
  static inline unsigned long long RDTSC() __attribute__((always_inline));
};

#endif /* MEASURE_TIME_RDTSC_HPP_ */
