/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCStateSelection.h" */
CauerLowPassSCStateSelection::CauerLowPassSCStateSelection(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : CauerLowPassSC(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
{
}

CauerLowPassSCStateSelection::~CauerLowPassSCStateSelection()
{
}

int CauerLowPassSCStateSelection::getDimStateSets() const
{
  return 0;
}

int CauerLowPassSCStateSelection::getDimStates(unsigned int index) const
{
  return 0;
}

int CauerLowPassSCStateSelection::getDimCanditates(unsigned int index) const
{
  return 0;
}

int CauerLowPassSCStateSelection::getDimDummyStates(unsigned int index) const
{
  return 0;
}
void CauerLowPassSCStateSelection::getStates(unsigned int index, double* z)
{
}

void CauerLowPassSCStateSelection::setStates(unsigned int index, const double* z)
{
}

void CauerLowPassSCStateSelection::getStateCanditates(unsigned int index, double* z)
{

}

bool CauerLowPassSCStateSelection::getAMatrix(unsigned int index, DynArrayDim2<int> & A)
{
  return false;
}

bool CauerLowPassSCStateSelection::getAMatrix(unsigned int index, DynArrayDim1<int> & A)
{
  return false;
}

void CauerLowPassSCStateSelection::setAMatrix(unsigned int index, DynArrayDim2<int>& A)
{
}

void CauerLowPassSCStateSelection::setAMatrix(unsigned int index, DynArrayDim1<int>& A)
{
}

void CauerLowPassSCStateSelection::initialize()
{
}