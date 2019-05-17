//#pragma once
#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include <Solver/ARKode/ARKodeSettings.h>

ARKodeSettings::ARKodeSettings(IGlobalSettings* globalSettings)
  : SolverSettings    (globalSettings)
  ,_denseOutput(true)
{
};
 ARKodeSettings::~ARKodeSettings()
 {

 }
bool ARKodeSettings::getDenseOutput()
{
  return _denseOutput;
}
void ARKodeSettings::setDenseOutput(bool dense)
{
  _denseOutput = dense;
}
