#ifndef MEASURE_TIME_RDTSC_HPP_
#define MEASURE_TIME_RDTSC_HPP_

#include <Core/Utils/extension/measure_time.hpp>

class MeasureTimeValuesRDTSC : public MeasureTimeValues
{
public:
  unsigned long long time;

	unsigned long long max_time;

  MeasureTimeValuesRDTSC(unsigned long long time);
  virtual ~MeasureTimeValuesRDTSC();

  virtual std::string serializeToJson() const;

  virtual void add(MeasureTimeValues *values);
  virtual void sub(MeasureTimeValues *values);
  virtual void div(int counter);
};

class MeasureTimeRDTSC : public MeasureTime
{
 protected:
  MeasureTimeRDTSC();

  MeasureTimeValues* getZeroValuesP();
  void getTimeValuesStartP(MeasureTimeValues *res);
  void getTimeValuesEndP(MeasureTimeValues *res);

 public:
  virtual ~MeasureTimeRDTSC();

  static void initialize()
  {
    instance = new MeasureTimeRDTSC();
    instance->setOverheadToZero();
  }

  virtual void initializeThread(unsigned long int (*threadHandle)());
  virtual void deinitializeThread(unsigned long int (*threadHandle)());

 private:
  static inline unsigned long long RDTSC(); //__attribute__((always_inline));
};

#endif /* MEASURE_TIME_RDTSC_HPP_ */
