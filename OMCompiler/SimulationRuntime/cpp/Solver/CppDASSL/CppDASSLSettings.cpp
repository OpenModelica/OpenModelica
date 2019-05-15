//#pragma once
#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include <Solver/CppDASSL/CppDASSLSettings.h>

CppDASSLSettings::CppDASSLSettings(IGlobalSettings* globalSettings)
  : SolverSettings    (globalSettings)
  ,_denseOutput(true)
{
};
 CppDASSLSettings::~CppDASSLSettings()
 {

 }
bool CppDASSLSettings::getDenseOutput()
{
  return _denseOutput;
}
void CppDASSLSettings::setDenseOutput(bool dense)
{
  _denseOutput = dense;
}
