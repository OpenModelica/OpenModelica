
CoupledInductorsStateSelection::CoupledInductorsStateSelection(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : CoupledInductors(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
{
}

CoupledInductorsStateSelection::~CoupledInductorsStateSelection()
{
}

int CoupledInductorsStateSelection::getDimStateSets() const
{
  return 0;
}

int CoupledInductorsStateSelection::getDimStates(unsigned int index) const
{
  return 0;
}

int CoupledInductorsStateSelection::getDimCanditates(unsigned int index) const
{
  return 0;
}

int CoupledInductorsStateSelection::getDimDummyStates(unsigned int index) const
{
  return 0;
}
void CoupledInductorsStateSelection::getStates(unsigned int index, double* z)
{
}

void CoupledInductorsStateSelection::setStates(unsigned int index, const double* z)
{
}

void CoupledInductorsStateSelection::getStateCanditates(unsigned int index, double* z)
{

}

bool CoupledInductorsStateSelection::getAMatrix(unsigned int index, DynArrayDim2<int> & A)
{
  return false;
}

bool CoupledInductorsStateSelection::getAMatrix(unsigned int index, DynArrayDim1<int> & A)
{
  return false;
}

void CoupledInductorsStateSelection::setAMatrix(unsigned int index, DynArrayDim2<int>& A)
{
}

void CoupledInductorsStateSelection::setAMatrix(unsigned int index, DynArrayDim1<int>& A)
{
}

void CoupledInductorsStateSelection::initialize()
{
}