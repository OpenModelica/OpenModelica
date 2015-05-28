/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h" */
CauerLowPassSCExtension::CauerLowPassSCExtension(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : CauerLowPassSC(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , CauerLowPassSCWriteOutput(globalSettings,nonlinsolverfactory, sim_data,sim_vars)
    , CauerLowPassSCInitialize(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , CauerLowPassSCJacobian(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , CauerLowPassSCStateSelection(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    
{
}

CauerLowPassSCExtension::~CauerLowPassSCExtension()
{
}

bool CauerLowPassSCExtension::initial()
{
   return CauerLowPassSCInitialize::initial();
}
void CauerLowPassSCExtension::setInitial(bool value)
{
   CauerLowPassSCInitialize::setInitial(value);
}

void CauerLowPassSCExtension::initialize()
{
  CauerLowPassSCWriteOutput::initialize();
  CauerLowPassSCInitialize::initialize();
  CauerLowPassSCJacobian::initialize();
  
  CauerLowPassSCJacobian::initializeColoredJacobianA();
}

void CauerLowPassSCExtension::getJacobian(SparseMatrix& matrix)
{
  getAJacobian(matrix);

}

void CauerLowPassSCExtension::getStateSetJacobian(unsigned int index,SparseMatrix& matrix)
{
  switch (index)
  {
    default:
       throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
   }
}

bool CauerLowPassSCExtension::handleSystemEvents(bool* events)
{
  return CauerLowPassSC::handleSystemEvents(events);
}

void CauerLowPassSCExtension::saveAll()
{
  return CauerLowPassSC::saveAll();
}

void CauerLowPassSCExtension::initEquations()
{
  CauerLowPassSCInitialize::initEquations();
}

void CauerLowPassSCExtension::writeOutput(const IWriteOutput::OUTPUT command)
{
  CauerLowPassSCWriteOutput::writeOutput(command);
}

IHistory* CauerLowPassSCExtension::getHistory()
{
  return CauerLowPassSCWriteOutput::getHistory();
}

int CauerLowPassSCExtension::getDimStateSets() const
{
  return CauerLowPassSCStateSelection::getDimStateSets();
}

int CauerLowPassSCExtension::getDimStates(unsigned int index) const
{
  return CauerLowPassSCStateSelection::getDimStates(index);
}

int CauerLowPassSCExtension::getDimCanditates(unsigned int index) const
{
  return CauerLowPassSCStateSelection::getDimCanditates(index);
}

int CauerLowPassSCExtension::getDimDummyStates(unsigned int index) const
{
  return CauerLowPassSCStateSelection::getDimDummyStates(index);
}

void CauerLowPassSCExtension::getStates(unsigned int index,double* z)
{
  CauerLowPassSCStateSelection::getStates(index,z);
}

void CauerLowPassSCExtension::setStates(unsigned int index,const double* z)
{
  CauerLowPassSCStateSelection::setStates(index,z);
}

void CauerLowPassSCExtension::getStateCanditates(unsigned int index,double* z)
{
  CauerLowPassSCStateSelection::getStateCanditates(index,z);
}

bool CauerLowPassSCExtension::getAMatrix(unsigned int index,DynArrayDim2<int> & A)
{
  return CauerLowPassSCStateSelection::getAMatrix(index,A);
}

void CauerLowPassSCExtension::setAMatrix(unsigned int index,DynArrayDim2<int> & A)
{
  CauerLowPassSCStateSelection::setAMatrix(index,A);
}

bool CauerLowPassSCExtension::getAMatrix(unsigned int index,DynArrayDim1<int> & A)
{
  return CauerLowPassSCStateSelection::getAMatrix(index,A);
}

void CauerLowPassSCExtension::setAMatrix(unsigned int index,DynArrayDim1<int> & A)
{
  CauerLowPassSCStateSelection::setAMatrix(index,A);
}

/*needed for colored jacobians*/

void CauerLowPassSCExtension::getAColorOfColumn(int* aSparsePatternColorCols, int size)
{
 memcpy(aSparsePatternColorCols, _AColorOfColumn, size * sizeof(int));
}

int CauerLowPassSCExtension::getAMaxColors()
{
 return _AMaxColors;
}

/*********************************************************************************************/

string CauerLowPassSCExtension::getModelName()
{
 return "Modelica.Electrical.Analog.Examples.CauerLowPassSC";
}