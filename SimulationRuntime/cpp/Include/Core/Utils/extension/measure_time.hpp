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

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValues
{
 public:
  MeasureTimeValues();
  virtual ~MeasureTimeValues();

  virtual std::string serializeToJson() const = 0;

  virtual void add(MeasureTimeValues *values) = 0;
  virtual void sub(MeasureTimeValues *values) = 0;
  virtual void div(int counter) = 0;
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeData
{
 public:
  std::string id;
  MeasureTimeValues *sumMeasuredValues;
  //MeasureTimeValues *maxMeasuredValues;
  unsigned int numCalcs;

  MeasureTimeData();
  MeasureTimeData(std::string id);
  virtual ~MeasureTimeData();

  std::string serializeToJson() const;

  void addValuesToSum(MeasureTimeValues *values);
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTime
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
    instance->getTimeValuesStartP(res);
  }

  static inline void getTimeValuesEnd(MeasureTimeValues *res)
  {
    instance->getTimeValuesEndP(res);
  }

  static MeasureTimeValues* getZeroValues();

  static void deinitialize();

  static void addResultContentBlock(const std::string filename, const std::string blockname, const std::vector<MeasureTimeData> * in);

  static void writeToJson();

  virtual void benchOverhead();

  virtual void setOverheadToZero();

  virtual void initializeThread(unsigned long int (*threadHandle)()) = 0;
  virtual void deinitializeThread(unsigned long int (*threadHandle)()) = 0;

 protected:
  static MeasureTime * instance;
  static getTimeValuesFctType getTimeValuesStartFct;
  static getTimeValuesFctType getTimeValuesEndFct;
  static file_map toWrite;

  MeasureTimeValues * overhead;

  MeasureTime();

  virtual MeasureTimeValues* getZeroValuesP() = 0;

  virtual void getTimeValuesStartP(MeasureTimeValues *res) = 0;
  virtual void getTimeValuesEndP(MeasureTimeValues *res) = 0;
};
#endif // MEASURE_TIME_HPP
