#pragma once
#include "stdafx.h"
#include "IdasSettings.h"

IdasSettings::IdasSettings(IGlobalSettings* globalSettings)
  : SolverSettings    (globalSettings)
  ,_denseOutput(false)
  ,_eventOutput(false)

{
};

bool IdasSettings::getDenseOutput()
{
  return _denseOutput;
}
void IdasSettings::setDenseOutput(bool dense)
{
  _denseOutput = dense;
}  


bool IdasSettings::getEventOutput()
{
  return _eventOutput;
}

void IdasSettings::setEventOutput(bool eventOutput)
{
  _eventOutput = eventOutput;
}