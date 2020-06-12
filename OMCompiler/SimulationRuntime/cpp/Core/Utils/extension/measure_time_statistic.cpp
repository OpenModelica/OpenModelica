#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Utils/extension/measure_time_statistic.hpp>
#include <limits>
#include <cmath>
#include <algorithm>

MeasureTimeValuesStatistic::MeasureTimeValuesStatistic(unsigned long long time) : MeasureTimeValuesRDTSC(time), _quadSum(time),
																				  _minTime(std::numeric_limits<unsigned long long>::max()), _count(10), _killTime(0) {}

MeasureTimeValuesStatistic::MeasureTimeValuesStatistic(const MeasureTimeValuesStatistic &timeValues) : MeasureTimeValuesRDTSC(timeValues), _quadSum(timeValues._quadSum), _minTime(timeValues._minTime), _count(timeValues._count), _killTime(timeValues._killTime) {}

MeasureTimeValuesStatistic::~MeasureTimeValuesStatistic() {}


std::string MeasureTimeValuesStatistic::serializeToJson() const
{
  unsigned long long act_time = (_count < _numCalcs ? _time - _killTime : _time);
  unsigned actNumCalcs = (_count < _numCalcs ? _numCalcs-_count : _numCalcs);
  long double average = (long double)act_time/actNumCalcs, stdDev = sqrt(((long double)_quadSum/actNumCalcs) -(average*average));// V(x) = E(x*x) - E(x)*E(x)
  std::stringstream ss;

  ss << "\"ncall\":" << _numCalcs << ","  << "\"time\":" << _time << ",\"maxTime\":" <<  _maxTime << ",\"minTime\":" <<  (_numCalcs == 0 ? 0 : _minTime) << ",\"meanTime\":" << (_numCalcs == 0 ? 0 : average)
	 << ",\"std.deviation\":" << (_numCalcs == 0 ? 0 : stdDev ) << ",\"std.rel.deviation\":" << (_numCalcs == 0 ? 0 : stdDev/average);
  return ss.str();
}

void MeasureTimeValuesStatistic::add(MeasureTimeValues *values)
{
  MeasureTimeValuesRDTSC::add(values);

  MeasureTimeValuesStatistic *val = static_cast<MeasureTimeValuesStatistic*>(values);
  if( val->_time < _minTime )
    _minTime = val->_time;

  if(_numCalcs<_count)
  {
    _killTime +=val->_time;
  }
  else
   _quadSum += val->_time*val->_time;
}

void MeasureTimeValuesStatistic::filter(unsigned long long val)
{

}

void MeasureTimeValuesStatistic::sub(MeasureTimeValues *values)
{
  MeasureTimeValuesRDTSC::sub(values);
  MeasureTimeValuesStatistic *val = static_cast<MeasureTimeValuesStatistic*>(values);
  if(_quadSum > val->_time*val->_time)
    _quadSum -= val->_time * val->_time;
  else
    _quadSum = 0ull;
}

MeasureTimeValuesStatistic* MeasureTimeValuesStatistic::clone() const
{
  return new MeasureTimeValuesStatistic(*this);
}

void MeasureTimeValuesStatistic::reset()
{
  MeasureTimeValues::reset();
  _quadSum = 0;
  _count = 0;
  _minTime = 0;
  _killTime = 0;
}

MeasureTimeStatistic::MeasureTimeStatistic() : MeasureTimeRDTSC()
{
}

MeasureTimeStatistic::~MeasureTimeStatistic()
{
}

MeasureTimeValues* MeasureTimeStatistic::getZeroValuesP() const
{
  return new MeasureTimeValuesStatistic(0ull);
}

