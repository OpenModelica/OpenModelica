//#pragma once
#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include <Solver/IDA/IDASettings.h>

IDASettings::IDASettings(IGlobalSettings* globalSettings)
  : SolverSettings    (globalSettings)
  ,_denseOutput(true)
{
};
 IDASettings::~IDASettings()
 {

 }
bool IDASettings::getDenseOutput()
{
  return _denseOutput;
}
void IDASettings::setDenseOutput(bool dense)
{
  _denseOutput = dense;
}
