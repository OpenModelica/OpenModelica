#include <Core/Utils/extension/measure_time_scorep.hpp>

MeasureTimeValuesScoreP::MeasureTimeValuesScoreP() : MeasureTimeValues() {}

MeasureTimeValuesScoreP::~MeasureTimeValuesScoreP() {}

std::string MeasureTimeValuesScoreP::serializeToJson(unsigned int numCalcs)
{
  return "";
}

MeasureTimeScoreP::MeasureTimeScoreP() : MeasureTime()
{
}

MeasureTimeScoreP::~MeasureTimeScoreP()
{

}

void MeasureTimeScoreP::initializeThread(unsigned long int (*threadHandle)())
{
}

void MeasureTimeScoreP::deinitializeThread(unsigned long int (*threadHandle)())
{

}

void MeasureTimeScoreP::getTimeValuesStartP(MeasureTimeValues *res)
{
}

void MeasureTimeScoreP::getTimeValuesEndP(MeasureTimeValues *res)
{
}

MeasureTimeValues* MeasureTimeScoreP::getZeroValuesP()
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
