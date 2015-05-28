
BouncingBallExtension::BouncingBallExtension(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : BouncingBall(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , BouncingBallWriteOutput(globalSettings,nonlinsolverfactory, sim_data,sim_vars)
    , BouncingBallInitialize(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , BouncingBallJacobian(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    , BouncingBallStateSelection(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
    
{
}

BouncingBallExtension::~BouncingBallExtension()
{
}

bool BouncingBallExtension::initial()
{
   return BouncingBallInitialize::initial();
}
void BouncingBallExtension::setInitial(bool value)
{
   BouncingBallInitialize::setInitial(value);
}

void BouncingBallExtension::initialize()
{
  BouncingBallWriteOutput::initialize();
  BouncingBallInitialize::initialize();
  BouncingBallJacobian::initialize();
  
  BouncingBallJacobian::initializeColoredJacobianA();
}

void BouncingBallExtension::getJacobian(SparseMatrix& matrix)
{
  getAJacobian(matrix);

}

void BouncingBallExtension::getStateSetJacobian(unsigned int index,SparseMatrix& matrix)
{
  switch (index)
  {
    default:
       throw ModelicaSimulationError(MATH_FUNCTION,"Not supported statset index");
   }
}

bool BouncingBallExtension::handleSystemEvents(bool* events)
{
  return BouncingBall::handleSystemEvents(events);
}

void BouncingBallExtension::saveAll()
{
  return BouncingBall::saveAll();
}

void BouncingBallExtension::initEquations()
{
  BouncingBallInitialize::initEquations();
}

void BouncingBallExtension::writeOutput(const IWriteOutput::OUTPUT command)
{
  BouncingBallWriteOutput::writeOutput(command);
}

IHistory* BouncingBallExtension::getHistory()
{
  return BouncingBallWriteOutput::getHistory();
}

int BouncingBallExtension::getDimStateSets() const
{
  return BouncingBallStateSelection::getDimStateSets();
}

int BouncingBallExtension::getDimStates(unsigned int index) const
{
  return BouncingBallStateSelection::getDimStates(index);
}

int BouncingBallExtension::getDimCanditates(unsigned int index) const
{
  return BouncingBallStateSelection::getDimCanditates(index);
}

int BouncingBallExtension::getDimDummyStates(unsigned int index) const
{
  return BouncingBallStateSelection::getDimDummyStates(index);
}

void BouncingBallExtension::getStates(unsigned int index,double* z)
{
  BouncingBallStateSelection::getStates(index,z);
}

void BouncingBallExtension::setStates(unsigned int index,const double* z)
{
  BouncingBallStateSelection::setStates(index,z);
}

void BouncingBallExtension::getStateCanditates(unsigned int index,double* z)
{
  BouncingBallStateSelection::getStateCanditates(index,z);
}

bool BouncingBallExtension::getAMatrix(unsigned int index,DynArrayDim2<int> & A)
{
  return BouncingBallStateSelection::getAMatrix(index,A);
}

void BouncingBallExtension::setAMatrix(unsigned int index,DynArrayDim2<int> & A)
{
  BouncingBallStateSelection::setAMatrix(index,A);
}

bool BouncingBallExtension::getAMatrix(unsigned int index,DynArrayDim1<int> & A)
{
  return BouncingBallStateSelection::getAMatrix(index,A);
}

void BouncingBallExtension::setAMatrix(unsigned int index,DynArrayDim1<int> & A)
{
  BouncingBallStateSelection::setAMatrix(index,A);
}

/*needed for colored jacobians*/

void BouncingBallExtension::getAColorOfColumn(int* aSparsePatternColorCols, int size)
{
 memcpy(aSparsePatternColorCols, _AColorOfColumn, size * sizeof(int));
}

int BouncingBallExtension::getAMaxColors()
{
 return _AMaxColors;
}

/*********************************************************************************************/

string BouncingBallExtension::getModelName()
{
 return "BouncingBall";
}