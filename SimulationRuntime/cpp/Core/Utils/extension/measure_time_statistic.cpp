#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Utils/extension/measure_time_statistic.hpp>
#include <limits>
#include <cmath>
#include <algorithm>

MeasureTimeValuesStatistic::MeasureTimeValuesStatistic(unsigned long long time) : MeasureTimeValuesRDTSC(time), _quad_sum(time),
																				  _min_time(std::numeric_limits<unsigned long long>::max()), _count(10), _kill_time(0) {}


MeasureTimeValuesStatistic::~MeasureTimeValuesStatistic() {}

std::string MeasureTimeValuesStatistic::serializeToJson()
{
  unsigned long long act_time = (_count < _numCalcs ? _time - _kill_time : _time);
  unsigned actNumCalcs = (_count < _numCalcs ? _numCalcs-_count : _numCalcs);
  long double average = (long double)act_time/actNumCalcs, stdDev = sqrt(((long double)_quad_sum/actNumCalcs) -(average*average));// V(x) = E(x*x) - E(x)*E(x)
  std::stringstream ss;

  ss << "\"ncall\":" << _numCalcs << ","  << "\"time\":" << _time << ",\"maxTime\":" <<  _max_time << ",\"minTime\":" <<  (_numCalcs == 0 ? 0 : _min_time) << ",\"meanTime\":" << (_numCalcs == 0 ? 0 : average)
	 << ",\"std.deviation\":" << (_numCalcs == 0 ? 0 : stdDev ) << ",\"std.rel.deviation\":" << (_numCalcs == 0 ? 0 : stdDev/average);
  return ss.str();
}

void MeasureTimeValuesStatistic::add(MeasureTimeValues *values)
{
  MeasureTimeValuesRDTSC::add(values);

  MeasureTimeValuesStatistic *val = static_cast<MeasureTimeValuesStatistic*>(values);
  if( val->_time < _min_time )
    _min_time = val->_time;

  if(_numCalcs<_count)
  {
    _kill_time +=val->_time;
  }
  else
   _quad_sum += val->_time*val->_time;
}

void MeasureTimeValuesStatistic::filter(unsigned long long val)
{

}

void MeasureTimeValuesStatistic::sub(MeasureTimeValues *values)
{
  MeasureTimeValuesRDTSC::sub(values);
  MeasureTimeValuesStatistic *val = static_cast<MeasureTimeValuesStatistic*>(values);
  if(_quad_sum > val->_time*val->_time)
    _quad_sum -= val->_time * val->_time;
  else
    _quad_sum = 0ull;
}

MeasureTimeStatistic::MeasureTimeStatistic() : MeasureTimeRDTSC()
{
}

MeasureTimeStatistic::~MeasureTimeStatistic()
{
}

MeasureTimeValues* MeasureTimeStatistic::getZeroValuesP()
{
  return new MeasureTimeValuesStatistic(0ull);
}

