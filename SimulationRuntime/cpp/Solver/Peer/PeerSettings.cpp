//#pragma once
#include <Core/Modelica.h>
#include <Solver/Peer/PeerSettings.h>

PeerSettings::PeerSettings(IGlobalSettings* globalSettings)
  : SolverSettings    (globalSettings)
  ,_denseOutput(true)
{
};
 PeerSettings::~PeerSettings()
 {

 }
bool PeerSettings::getDenseOutput()
{
  return _denseOutput;
}
void PeerSettings::setDenseOutput(bool dense)
{
  _denseOutput = dense;
}
