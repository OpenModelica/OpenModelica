#ifndef MEASURE_TIME_HPP
#define MEASURE_TIME_HPP

#if defined(_MSC_VER)
#include <intrin.h>
#endif

#include <fstream>
#include <string>
#include <sstream>
#include <vector>
#include <ctime>
#include <iostream>
#include <Core/Modelica.h>

class MeasureTimeValues
{
public:
  MeasureTimeValues();
  virtual ~MeasureTimeValues();

  virtual std::string serializeToJson() = 0;

  virtual void add(MeasureTimeValues *values) = 0;
  virtual void sub(MeasureTimeValues *values) = 0;
  virtual void div(int counter) = 0;
};

class MeasureTimeData
{
 public:
  unsigned int id;
  MeasureTimeValues *sumMeasuredValues;
  //MeasureTimeValues *maxMeasuredValues;
  unsigned int numCalcs;
  std::string category;


  MeasureTimeData();
  virtual ~MeasureTimeData();

  void addValuesToSum(MeasureTimeValues *values);
};

class MeasureTime
{
 public:
  typedef void (*getTimeValuesFctType)(MeasureTimeValues*);

  MeasureTime();

  virtual ~MeasureTime();

  static MeasureTime* getInstance();

  static MeasureTimeValues* getOverhead();

  /**
   * Applied overhead minimization:
   *  - stick thread to core 1 -> no effect
   *  - always inline -> effect
   *  - measure overhead and sub the values -> effect
   */
  static inline void getTimeValues(MeasureTimeValues *res) //__attribute__((always_inline))
  {
    getTimeValuesFct(res);
  }

  static MeasureTimeValues* getZeroValues();

  static void deinitialize();

  void writeTimeToJason(std::string model_name, std::vector<MeasureTimeData> data);

  virtual void benchOverhead();

 protected:
  static MeasureTime *instance;
  static getTimeValuesFctType getTimeValuesFct;

  MeasureTimeValues *overhead;

  virtual MeasureTimeValues* getZeroValuesP() = 0;
};
#endif // MEASURE_TIME_HPP
