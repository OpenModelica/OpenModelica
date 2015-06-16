#ifndef MEASURE_TIME_HPP
#define MEASURE_TIME_HPP

#if defined(_MSC_VER)
#include <intrin.h>
#endif

#ifdef USE_SCOREP
  #define MEASURETIME_REGION_DEFINE(handlerName, regionName) SCOREP_USER_REGION_DEFINE( handlerName )
  #define MEASURETIME_START(valStart, handlerName, regionName) SCOREP_USER_REGION_BEGIN( handlerName, regionName, SCOREP_USER_REGION_TYPE_COMMON )
  #define MEASURETIME_END(valStart, valEnd, valRes, handlerName) SCOREP_USER_REGION_END( handlerName )
  #include <scorep/SCOREP_User.h>
#else
  #define MEASURETIME_REGION_DEFINE(handlerName, regionName)
  #define MEASURETIME_START(valStart, handlerName, regionName) MeasureTime::getTimeValuesStart(valStart)
  #define MEASURETIME_END(valStart, valEnd, valRes, handlerName) { MeasureTime::getTimeValuesEnd(valEnd); valEnd->sub(valStart); valEnd->sub(MeasureTime::getOverhead()); valRes.sumMeasuredValues->add(valEnd); ++(valRes.sumMeasuredValues->_numCalcs); }
#endif

#include <fstream>
#include <sstream>
#include <vector>
#include <map>
#include <ctime>
#include <iostream>
#include <Core/Modelica.h>

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValues
{
 public:


  unsigned int _numCalcs;

  MeasureTimeValues();
  virtual ~MeasureTimeValues();

  virtual std::string serializeToJson() = 0;

  virtual void add(MeasureTimeValues *values) = 0;
  virtual void sub(MeasureTimeValues *values) = 0;
  virtual void div(int counter) = 0;
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValuesSolver : public MeasureTimeValues
{
 public:
    MeasureTimeValuesSolver();
    MeasureTimeValuesSolver(unsigned long long functionEvaluations, unsigned long long errorTestFailures);
    virtual ~MeasureTimeValuesSolver();

    virtual std::string serializeToJson();

    virtual void add(MeasureTimeValues *values);
    virtual void sub(MeasureTimeValues *values);
    virtual void div(int counter);

    unsigned long long functionEvaluations;
    unsigned long long errorTestFailures;
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeData
{
 public:
  std::string id;
  MeasureTimeValues *sumMeasuredValues;

  MeasureTimeData();
  MeasureTimeData(std::string id);
  virtual ~MeasureTimeData();

  std::string serializeToJson();

  void addValuesToSum(MeasureTimeValues *values);
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTime
{
 public:
  typedef std::map<std::string, std::vector<MeasureTimeData> *> block_map;
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
    getInstance()->getTimeValuesStartP(res);
  }

  static inline void getTimeValuesEnd(MeasureTimeValues *res)
  {
    getInstance()->getTimeValuesEndP(res);
  }

  static MeasureTimeValues* getZeroValues();

  static void deinitialize();

  static void addResultContentBlock(std::string filename, std::string blockname, std::vector<MeasureTimeData> * in);

  static void writeToJson();

  virtual void benchOverhead();

  virtual void setOverheadToZero();

  virtual void initializeThread(unsigned long int threadNumber) = 0;
  virtual void deinitializeThread() = 0;

 protected:
  static MeasureTime * instance;
  static file_map toWrite;

  MeasureTimeValues * overhead;

  MeasureTime();

  virtual MeasureTimeValues* getZeroValuesP() = 0;

  virtual void getTimeValuesStartP(MeasureTimeValues *res) = 0;
  virtual void getTimeValuesEndP(MeasureTimeValues *res) = 0;
};

#endif // MEASURE_TIME_HPP
