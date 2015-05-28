
BouncingBallStateSelection::BouncingBallStateSelection(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : BouncingBall(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
{
}

BouncingBallStateSelection::~BouncingBallStateSelection()
{
}

int BouncingBallStateSelection::getDimStateSets() const
{
  return 0;
}

int BouncingBallStateSelection::getDimStates(unsigned int index) const
{
  return 0;
}

int BouncingBallStateSelection::getDimCanditates(unsigned int index) const
{
  return 0;
}

int BouncingBallStateSelection::getDimDummyStates(unsigned int index) const
{
  return 0;
}
void BouncingBallStateSelection::getStates(unsigned int index, double* z)
{
}

void BouncingBallStateSelection::setStates(unsigned int index, const double* z)
{
}

void BouncingBallStateSelection::getStateCanditates(unsigned int index, double* z)
{

}

bool BouncingBallStateSelection::getAMatrix(unsigned int index, DynArrayDim2<int> & A)
{
  return false;
}

bool BouncingBallStateSelection::getAMatrix(unsigned int index, DynArrayDim1<int> & A)
{
  return false;
}

void BouncingBallStateSelection::setAMatrix(unsigned int index, DynArrayDim2<int>& A)
{
}

void BouncingBallStateSelection::setAMatrix(unsigned int index, DynArrayDim1<int>& A)
{
}

void BouncingBallStateSelection::initialize()
{
}