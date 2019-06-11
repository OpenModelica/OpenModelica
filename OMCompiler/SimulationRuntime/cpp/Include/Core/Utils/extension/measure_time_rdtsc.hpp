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
