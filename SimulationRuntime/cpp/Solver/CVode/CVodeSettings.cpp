//#pragma once
#include "Modelica.h"
#include "CVodeSettings.h"

CVodeSettings::CVodeSettings(IGlobalSettings* globalSettings)
  : SolverSettings    (globalSettings)
  ,_denseOutput(true)
  ,_eventOutput(true)
{
};

bool CVodeSettings::getDenseOutput()
{
  return _denseOutput;
}
void CVodeSettings::setDenseOutput(bool dense)
{
  _denseOutput = dense;
}


bool CVodeSettings::getEventOutput()
{
  return _eventOutput;
}

void CVodeSettings::setEventOutput(bool eventOutput)
{
  _eventOutput = eventOutput;
}
