#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Utils/extension/measure_time_scorep.hpp>

MeasureTimeValuesScoreP::MeasureTimeValuesScoreP() : MeasureTimeValues() {}

MeasureTimeValuesScoreP::MeasureTimeValuesScoreP(const MeasureTimeValuesScoreP &timeValues) : MeasureTimeValues() {}

MeasureTimeValuesScoreP::~MeasureTimeValuesScoreP() {}

std::string MeasureTimeValuesScoreP::serializeToJson() const
{
  return "";
}

MeasureTimeScoreP::MeasureTimeScoreP() : MeasureTime()
{
}

MeasureTimeScoreP::~MeasureTimeScoreP()
{

}

void MeasureTimeScoreP::initializeThread(unsigned long int threadNumber)
{
}

void MeasureTimeScoreP::deinitializeThread()
{

}

void MeasureTimeScoreP::getTimeValuesStartP(MeasureTimeValues *res) const
{
}

void MeasureTimeScoreP::getTimeValuesEndP(MeasureTimeValues *res) const
{
}

MeasureTimeValues* MeasureTimeScoreP::getZeroValuesP() const
{
  return new MeasureTimeValuesScoreP();
}

void MeasureTimeValuesScoreP::add(MeasureTimeValues *values)
{
}

void MeasureTimeValuesScoreP::sub(MeasureTimeValues *values)
{
}

void MeasureTimeValuesScoreP::div(int counter)
{
}

MeasureTimeValuesScoreP* MeasureTimeValuesScoreP::clone() const
{
  return new MeasureTimeValuesScoreP(*this);
}

void MeasureTimeValuesScoreP::reset()
{
  MeasureTimeValues::reset();
}
