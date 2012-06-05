#pragma once
#include "stdafx.h"
#include "IdaSettings.h"

IdaSettings::IdaSettings(IGlobalSettings* globalSettings)
  : SolverSettings    (globalSettings)
  ,_denseOutput(false)
  ,_eventOutput(false)

{
};

bool IdaSettings::getDenseOutput()
{
  return _denseOutput;
}
void IdaSettings::setDenseOutput(bool dense)
{
  _denseOutput = dense;
}  


bool IdaSettings::getEventOutput()
{
  return _eventOutput;
}

void IdaSettings::setEventOutput(bool eventOutput)
{
  _eventOutput = eventOutput;
}
