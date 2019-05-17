#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Utils/extension/measure_time_papi.hpp>

MeasureTimeValuesPAPI::MeasureTimeValuesPAPI(unsigned long long time, long long l2CacheMisses, long long instructions) : MeasureTimeValues(), _time(time), _l2CacheMisses(l2CacheMisses), _instructions(instructions), _maxTime(time) {}

MeasureTimeValuesPAPI::MeasureTimeValuesPAPI(const MeasureTimeValuesPAPI &timeValues) : MeasureTimeValues(), _time(timeValues._time), _l2CacheMisses(timeValues._l2CacheMisses), _instructions(timeValues._instructions), _maxTime(timeValues._maxTime) {}

MeasureTimeValuesPAPI::~MeasureTimeValuesPAPI() {}

std::string MeasureTimeValuesPAPI::serializeToJson() const
{
  std::stringstream ss;
  ss << "\"ncall\":" << _numCalcs << ",\"time\":" << _time << ",\"maxTime\":" << _maxTime << ",\"l2cacheMisses\":" << _l2CacheMisses
          << ",\"instructions\":" << _instructions
          << ",\"meanTime\":" << (_numCalcs == 0 ? 0 : _time/_numCalcs)
          << ",\"meanInstructions\":" << (_numCalcs == 0 ? 0 : _instructions/_numCalcs)
          << ",\"meanL2CacheMisses\":" << (_numCalcs == 0 ? 0 : _l2CacheMisses/_numCalcs);
  return ss.str();
}

MeasureTimePAPI::MeasureTimePAPI(unsigned long int (*threadHandle)()) : MeasureTime(), threadHandle(threadHandle)
{
  _events = new int[NUM_PAPI_EVENTS];

#ifdef USE_PAPI
  _events[0] = PAPI_TOT_CYC;
  _events[1] = PAPI_L2_TCM;
  _events[2] = PAPI_TOT_INS;

  _eventSet = PAPI_NULL;
  int initRetVal = PAPI_library_init(PAPI_VER_CURRENT);

  if (initRetVal != PAPI_VER_CURRENT && initRetVal > 0)
  {
    std::cerr << "PAPI library init failed!" << std::endl;
    exit(1);
  }

  if (PAPI_thread_init(threadHandle) != PAPI_OK)
  {
    std::cerr << "PAPI thread init failed!" << std::endl;
    exit(1);
  }

  if (PAPI_create_eventset(&_eventSet) != PAPI_OK)
  {
    std::cerr << "PAPI create eventset failed!" << " Error: " << PAPI_create_eventset(&_eventSet) << std::endl;
    exit(1);
  }

  if (PAPI_add_events(_eventSet, _events, NUM_PAPI_EVENTS) != PAPI_OK)
  {
    std::cerr << "PAPI add events failed!" << std::endl;
    exit(1);
  }

  if (PAPI_start(_eventSet) != PAPI_OK)
  {
    std::cerr << "PAPI_start_counters - FAILED" << std::endl;
    throw ModelicaSimulationError(UTILITY,"PAPI_start_counters - FAILED");
  }
#else
  _eventSet = 0;
  throw ModelicaSimulationError(UTILITY,"Papi not supported!");
#endif
}

MeasureTimePAPI::~MeasureTimePAPI()
{

}

void MeasureTimePAPI::initializeThread(unsigned long int threadNumber)
{
#ifdef USE_PAPI
  //unsigned long int threadNumber = threadHandle();

  if (PAPI_attach(_eventSet, threadNumber) != PAPI_OK)
      std::cerr << "PAPI attach failed! Thread: " << threadNumber << std::endl;
#endif
}

void MeasureTimePAPI::deinitializeThread()
{

}

void MeasureTimePAPI::getTimeValuesStartP(MeasureTimeValues *res) const
{
#ifdef USE_PAPI
  MeasureTimeValuesPAPI *val = static_cast<MeasureTimeValuesPAPI*>(res);

//  if (PAPI_reset(eventSet) != PAPI_OK)
//  {
//    std::cerr << "PAPI_reset - FAILED" << std::endl;
//    throw ModelicaSimulationError(UTILITY,"PAPI_reset_counters - FAILED");
//  }
  long long values[NUM_PAPI_EVENTS];
  if (PAPI_read(_eventSet, values) != PAPI_OK)
  {
          std::cerr << "PAPI_read_counters - FAILED" << std::endl;
          throw ModelicaSimulationError(UTILITY,"PAPI_read_counters - FAILED");
  }

//  val->time = 0;
//  val->l2CacheMisses = 0;
//  val->instructions = 0;
  val->_time = values[0];
  val->_l2CacheMisses = values[1];
  val->_instructions = values[2];
#endif
}

void MeasureTimePAPI::getTimeValuesEndP(MeasureTimeValues *res) const
{
#ifdef USE_PAPI
  long long values[NUM_PAPI_EVENTS];
  if (PAPI_read(_eventSet, values) != PAPI_OK)
  {
          std::cerr << "PAPI_read_counters - FAILED" << std::endl;
          throw ModelicaSimulationError(UTILITY,"PAPI_read_counters - FAILED");
  }

  MeasureTimeValuesPAPI *val = static_cast<MeasureTimeValuesPAPI*>(res);
  val->_time = values[0];
  val->_l2CacheMisses = values[1];
  val->_instructions = values[2];
#endif
}

MeasureTimeValues* MeasureTimePAPI::getZeroValuesP() const
{
  return new MeasureTimeValuesPAPI(0, 0, 0);
}

void MeasureTimeValuesPAPI::add(MeasureTimeValues *values)
{
  MeasureTimeValuesPAPI *val = static_cast<MeasureTimeValuesPAPI*>(values);
  _time += val->_time;
  _l2CacheMisses += val->_l2CacheMisses;
  _instructions += val->_instructions;

  if( val->_time > _maxTime )
    _maxTime = val->_time;
}

void MeasureTimeValuesPAPI::sub(MeasureTimeValues *values)
{
  MeasureTimeValuesPAPI *val = static_cast<MeasureTimeValuesPAPI*>(values);
  if(_time > val->_time)
    _time -= val->_time;
  else
    _time = 0;

  if(_l2CacheMisses > val->_l2CacheMisses)
    _l2CacheMisses -= val->_l2CacheMisses;
  else
    _l2CacheMisses = 0;

  if(_instructions > val->_instructions)
    _instructions -= val->_instructions;
  else
    _instructions = 0;
}

void MeasureTimeValuesPAPI::div(int counter)
{
  _time = _time / counter;
  _l2CacheMisses = _l2CacheMisses / counter;
  _instructions = _instructions / counter;
}

MeasureTimeValuesPAPI* MeasureTimeValuesPAPI::clone() const
{
  return new MeasureTimeValuesPAPI(*this);
}

void MeasureTimeValuesPAPI::reset()
{
  MeasureTimeValues::reset();
  _time = 0;
  _l2CacheMisses = 0;
  _instructions = 0;
  _maxTime = 0;
}
