#ifndef MEASURE_TIME_HPP
#define MEASURE_TIME_HPP

#if defined(_MSC_VER)
#include <intrin.h>
#endif

#include <fstream>
#include <string>
#include <sstream>
#include <vector>
#include <map>
#include <ctime>
#include <iostream>
#include <Core/Modelica.h>

class MeasureTimeValues
{
 public:
  MeasureTimeValues();
  virtual ~MeasureTimeValues();

  virtual std::string serializeToJson() const = 0;

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

  MeasureTimeData();
  virtual ~MeasureTimeData();

  std::string serializeToJson() const;

  void addValuesToSum(MeasureTimeValues *values);
};

class MeasureTime
{
 public:
  typedef void (*getTimeValuesFctType)(MeasureTimeValues*);

  typedef std::map<std::string, const std::vector<MeasureTimeData> *> block_map;
  typedef std::map<std::string, block_map> file_map;

  virtual ~MeasureTime();

  static MeasureTime* getInstance();

  static MeasureTimeValues* getOverhead();

  /**
   * Applied overhead minimization:
   *  - stick thread to core 1 -> no effect
   *  - always inline -> effect
   *  - measure overhead and sub the values -> effect
   */
  static inline void getTimeValuesStart(MeasureTimeValues *res) //__attribute__((always_inline))
  {
    getTimeValuesStartFct(res);
  }

  static inline void getTimeValuesEnd(MeasureTimeValues *res)
  {
    getTimeValuesEndFct(res);
  }

  static MeasureTimeValues* getZeroValues();

  static void deinitialize();

  static void addJsonContentBlock(const std::string filename, const std::string blockname, const std::vector<MeasureTimeData> * in);

  static void writeToJson();

  virtual void benchOverhead();

 protected:

  static MeasureTime * instance;
  static getTimeValuesFctType getTimeValuesStartFct, getTimeValuesEndFct;
  static file_map toWrite;

  MeasureTimeValues * overhead;

  MeasureTime();

  virtual MeasureTimeValues* getZeroValuesP() = 0;
};
#endif // MEASURE_TIME_HPP
