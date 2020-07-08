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
  #define MEASURETIME_END(valStart, valEnd, valRes, handlerName) { MeasureTime::getTimeValuesEnd(valEnd); valEnd->sub(valStart); valEnd->sub(MeasureTime::getOverhead()); valRes->_sumMeasuredValues->add(valEnd); ++(valRes->_sumMeasuredValues->_numCalcs); }
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

  virtual std::string serializeToJson() const = 0;

  virtual void add(MeasureTimeValues *values) = 0;
  virtual void sub(MeasureTimeValues *values) = 0;
  virtual void div(int counter) = 0;
  virtual MeasureTimeValues* clone() const = 0;
  virtual void reset();
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeValuesSolver : public MeasureTimeValues
{
  public:
    MeasureTimeValuesSolver();
    MeasureTimeValuesSolver(unsigned long long functionEvaluations, unsigned long long errorTestFailures);
    MeasureTimeValuesSolver(const MeasureTimeValuesSolver &timeValues);
    virtual ~MeasureTimeValuesSolver();

    virtual std::string serializeToJson() const;

    virtual void add(MeasureTimeValues *values);
    virtual void sub(MeasureTimeValues *values);
    virtual void div(int counter);

    virtual MeasureTimeValues* clone() const;
    virtual void reset();

    unsigned long long _functionEvaluations;
    unsigned long long _errorTestFailures;
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTimeData
{
 public:
  std::string _id;
  MeasureTimeValues *_sumMeasuredValues;

  MeasureTimeData();
  MeasureTimeData(const MeasureTimeData &data);
  MeasureTimeData(std::string id);
  virtual ~MeasureTimeData();

  std::string serializeToJson() const;

  void addValuesToSum(MeasureTimeValues *values);
};

class BOOST_EXTENSION_EXPORT_DECL MeasureTime
{
 public:
  typedef std::map<std::string, std::vector<MeasureTimeData*> *> block_map;
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
  static inline void getTimeValuesStart(MeasureTimeValues *res)
  {
    getInstance()->getTimeValuesStartP(res);
  }

  static inline void getTimeValuesEnd(MeasureTimeValues *res)
  {
    getInstance()->getTimeValuesEndP(res);
  }

  static MeasureTimeValues* getZeroValues();

  static void deinitialize();

  static void addResultContentBlock(std::string modelName, std::string blockName, std::vector<MeasureTimeData*> *data);

  static void writeToJson();

  virtual void benchOverhead();

  virtual void setOverheadToZero();

  virtual void initializeThread(unsigned long int threadNumber) = 0;
  virtual void deinitializeThread() = 0;

 protected:
  static MeasureTime * _instance;
  static file_map _valuesToWrite;

  MeasureTimeValues * _measuredOverhead;

  MeasureTime();

  virtual MeasureTimeValues* getZeroValuesP() const = 0;

  virtual void getTimeValuesStartP(MeasureTimeValues *res) const = 0;
  virtual void getTimeValuesEndP(MeasureTimeValues *res) const = 0;
};

#endif // MEASURE_TIME_HPP
