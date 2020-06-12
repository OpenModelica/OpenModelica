#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Utils/extension/measure_time_rdtsc.hpp>

MeasureTimeValuesRDTSC::MeasureTimeValuesRDTSC(unsigned long long time) : MeasureTimeValues(), _time(time), _maxTime(time) {}

MeasureTimeValuesRDTSC::MeasureTimeValuesRDTSC(const MeasureTimeValuesRDTSC &timeValues) : MeasureTimeValues(timeValues), _time(timeValues._time), _maxTime(timeValues._maxTime) {}

MeasureTimeValuesRDTSC::~MeasureTimeValuesRDTSC() {}

std::string MeasureTimeValuesRDTSC::serializeToJson() const
{
  std::stringstream ss;
  ss << "\"ncall\":" << _numCalcs << ",\"time\":" << _time << ",\"maxTime\":" <<  _maxTime << ",\"meanTime\":" << (_numCalcs == 0 ? 0 : _time/_numCalcs);
  return ss.str();
}

void MeasureTimeValuesRDTSC::add(MeasureTimeValues *values)
{
  MeasureTimeValuesRDTSC *val = static_cast<MeasureTimeValuesRDTSC*>(values);
  _time += val->_time;

  if( val->_time > _maxTime )
    _maxTime = val->_time;
}

void MeasureTimeValuesRDTSC::sub(MeasureTimeValues *values)
{
  MeasureTimeValuesRDTSC *val = static_cast<MeasureTimeValuesRDTSC*>(values);
  if(_time > val->_time)
    _time -= val->_time;
  else
    _time = 0ull;
}

void MeasureTimeValuesRDTSC::div(int counter)
{
  _time = _time / counter;
}

MeasureTimeValuesRDTSC* MeasureTimeValuesRDTSC::clone() const
{
  return new MeasureTimeValuesRDTSC(*this);
}

void MeasureTimeValuesRDTSC::reset()
{
  MeasureTimeValues::reset();
  _time = 0;
  _maxTime = 0;
}

MeasureTimeRDTSC::MeasureTimeRDTSC() : MeasureTime()
{
}

MeasureTimeRDTSC::~MeasureTimeRDTSC()
{
}

void MeasureTimeRDTSC::initializeThread(unsigned long int threadNumber)
{

}

void MeasureTimeRDTSC::deinitializeThread()
{

}

void MeasureTimeRDTSC::getTimeValuesStartP(MeasureTimeValues *res) const
{
  MeasureTimeValuesRDTSC *val = static_cast<MeasureTimeValuesRDTSC*>(res);
  unsigned long long time = RDTSC();
  val->_time = time;
}

void MeasureTimeRDTSC::getTimeValuesEndP(MeasureTimeValues *res) const
{
  unsigned long long time = RDTSC();
  MeasureTimeValuesRDTSC *val = static_cast<MeasureTimeValuesRDTSC*>(res);
  val->_time = time;
}

MeasureTimeValues* MeasureTimeRDTSC::getZeroValuesP() const
{
  return new MeasureTimeValuesRDTSC(0ull);
}

#if defined(_MSC_VER)

#if defined(__i386__) || defined(__x86_64__)
unsigned long long MeasureTimeRDTSC::RDTSC()
{
  return _rdtsc();
}
#else
unsigned long long MeasureTimeRDTSC::RDTSC()
{
  throw ModelicaSimulationError(UTILITY,"No time measurement for this processor arch.");
  return 0;
}
#endif // defined(__i386__) || defined(__x86_64__)
#else
#if defined(__x86_64__)
unsigned long long MeasureTimeRDTSC::RDTSC()
{
  unsigned hi, lo;
  __asm__ __volatile__ ("rdtsc" : "=a"(lo), "=d"(hi));
  return ((unsigned long long) lo) | (((unsigned long long) hi) << 32);
}
#elif defined(__i386__)
unsigned long long MeasureTimeRDTSC::RDTSC()
{
  unsigned long long res;
  asm volatile (".byte 0x0f, 0x31" : "=A" (res));
  return res;
}
#else
unsigned long long MeasureTimeRDTSC::RDTSC()
{
  throw ModelicaSimulationError(UTILITY,"No time measurement for this processor arch.");
  return 0;
}

#endif //defined(__i386__)

#endif //defined(_MSC_VER)
