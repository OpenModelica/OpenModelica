
CoupledInductorsExtension::CoupledInductorsExtension(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : CoupledInductors(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , CoupledInductorsWriteOutput(globalSettings,nonlinsolverfactory, sim_data,sim_vars)
    , CoupledInductorsInitialize(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , CoupledInductorsJacobian(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , CoupledInductorsStateSelection(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    
{
}

CoupledInductorsExtension::~CoupledInductorsExtension()
{
}

bool CoupledInductorsExtension::initial()
{
   return CoupledInductorsInitialize::initial();
}
void CoupledInductorsExtension::setInitial(bool value)
{
   CoupledInductorsInitialize::setInitial(value);
}

void CoupledInductorsExtension::initialize()
{
  CoupledInductorsWriteOutput::initialize();
  CoupledInductorsInitialize::initialize();
  CoupledInductorsJacobian::initialize();
  
  CoupledInductorsJacobian::initializeColoredJacobianA();
}

void CoupledInductorsExtension::getJacobian(SparseMatrix& matrix)
{
  getAJacobian(matrix);

}

void CoupledInductorsExtension::getStateSetJacobian(unsigned int index,SparseMatrix& matrix)
{
  switch (index)
  {
    default:
       throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
   }
}

bool CoupledInductorsExtension::handleSystemEvents(bool* events)
{
  return CoupledInductors::handleSystemEvents(events);
}

void CoupledInductorsExtension::saveAll()
{
  return CoupledInductors::saveAll();
}

void CoupledInductorsExtension::initEquations()
{
  CoupledInductorsInitialize::initEquations();
}

void CoupledInductorsExtension::writeOutput(const IWriteOutput::OUTPUT command)
{
  CoupledInductorsWriteOutput::writeOutput(command);
}

IHistory* CoupledInductorsExtension::getHistory()
{
  return CoupledInductorsWriteOutput::getHistory();
}

int CoupledInductorsExtension::getDimStateSets() const
{
  return CoupledInductorsStateSelection::getDimStateSets();
}

int CoupledInductorsExtension::getDimStates(unsigned int index) const
{
  return CoupledInductorsStateSelection::getDimStates(index);
}

int CoupledInductorsExtension::getDimCanditates(unsigned int index) const
{
  return CoupledInductorsStateSelection::getDimCanditates(index);
}

int CoupledInductorsExtension::getDimDummyStates(unsigned int index) const
{
  return CoupledInductorsStateSelection::getDimDummyStates(index);
}

void CoupledInductorsExtension::getStates(unsigned int index,double* z)
{
  CoupledInductorsStateSelection::getStates(index,z);
}

void CoupledInductorsExtension::setStates(unsigned int index,const double* z)
{
  CoupledInductorsStateSelection::setStates(index,z);
}

void CoupledInductorsExtension::getStateCanditates(unsigned int index,double* z)
{
  CoupledInductorsStateSelection::getStateCanditates(index,z);
}

bool CoupledInductorsExtension::getAMatrix(unsigned int index,DynArrayDim2<int> & A)
{
  return CoupledInductorsStateSelection::getAMatrix(index,A);
}

void CoupledInductorsExtension::setAMatrix(unsigned int index,DynArrayDim2<int> & A)
{
  CoupledInductorsStateSelection::setAMatrix(index,A);
}

bool CoupledInductorsExtension::getAMatrix(unsigned int index,DynArrayDim1<int> & A)
{
  return CoupledInductorsStateSelection::getAMatrix(index,A);
}

void CoupledInductorsExtension::setAMatrix(unsigned int index,DynArrayDim1<int> & A)
{
  CoupledInductorsStateSelection::setAMatrix(index,A);
}

/*needed for colored jacobians*/

void CoupledInductorsExtension::getAColorOfColumn(int* aSparsePatternColorCols, int size)
{
 memcpy(aSparsePatternColorCols, _AColorOfColumn, size * sizeof(int));
}

int CoupledInductorsExtension::getAMaxColors()
{
 return _AMaxColors;
}

/*********************************************************************************************/

string CoupledInductorsExtension::getModelName()
{
 return "Modelica.Electrical.Spice3.Examples.CoupledInductors";
}