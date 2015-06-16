#ifndef MEASURE_TIME_RDTSC_HPP_
#define MEASURE_TIME_RDTSC_HPP_

#include <Core/Utils/extension/measure_time.hpp>

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValuesRDTSC : public MeasureTimeValues
{
public:
  unsigned long long _time;
  unsigned long long _max_time;

  MeasureTimeValuesRDTSC(unsigned long long time);
  virtual ~MeasureTimeValuesRDTSC();

  virtual std::string serializeToJson();

  virtual void add(MeasureTimeValues *values);
  virtual void sub(MeasureTimeValues *values);
  virtual void div(int counter);



};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeRDTSC : public MeasureTime
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

  virtual void initializeThread(unsigned long int threadNumber);
  virtual void deinitializeThread();


  static inline unsigned long long RDTSC(); //__attribute__((always_inline));

};

#endif /* MEASURE_TIME_RDTSC_HPP_ */
