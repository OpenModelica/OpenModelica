#pragma once
/*****************************************************************************
*
* Simulation code
*
*****************************************************************************/
class CoupledInductorsExtension: public ISystemInitialization, public IMixedSystem,public IWriteOutput, public IStateSelection, public CoupledInductorsWriteOutput, public CoupledInductorsInitialize, public CoupledInductorsJacobian,public CoupledInductorsStateSelection
{
public:
  CoupledInductorsExtension(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
  virtual ~CoupledInductorsExtension();
  
  ///Intialization methods from ISystemInitialization
  virtual bool initial();
  virtual void setInitial(bool);
  virtual void initialize();
  virtual void initEquations();
  
  ///Write simulation results methods from IWriteOutput
  /// Output routine (to be called by the solver after every successful integration step)
  virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT);
  virtual IHistory* getHistory();
  /// Provide Jacobian
  virtual void getJacobian(SparseMatrix& matrix);
  virtual void getStateSetJacobian(unsigned int index,SparseMatrix& matrix);
  /// Called to handle all events occured at same time
  virtual bool handleSystemEvents(bool* events);
  //Saves all variables before an event is handled, is needed for the pre, edge and change operator
  virtual void saveAll();
  
  //StateSelction methods
  virtual int getDimStateSets() const;
  virtual int getDimStates(unsigned int index) const;
  virtual int getDimCanditates(unsigned int index) const ;
  virtual int getDimDummyStates(unsigned int index) const ;
  virtual void getStates(unsigned int index,double* z);
  virtual void setStates(unsigned int index,const double* z);
  virtual void getStateCanditates(unsigned int index,double* z);
  virtual bool getAMatrix(unsigned int index,DynArrayDim2<int>& A);
  virtual void setAMatrix(unsigned int index, DynArrayDim2<int>& A);
  virtual bool getAMatrix(unsigned int index,DynArrayDim1<int>& A);
  virtual void setAMatrix(unsigned int index,DynArrayDim1<int>& A);
  
  
  /*colored jacobians*/
  virtual void getAColorOfColumn(int* aSparsePatternColorCols, int size);
  virtual int  getAMaxColors();
  
  virtual string getModelName();
};