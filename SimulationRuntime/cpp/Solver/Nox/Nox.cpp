/** @addtogroup solverNox
 *  @{
 *  / brief Nox solver using Trilinos' NOX. Methods include line search, trust region and homotopy. Yields additional methods for varying the initial guess and convergence criteria
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/Nox/FactoryExport.h>


#include <Core/Utils/extension/logger.hpp>
#include <Solver/Nox/NoxLapackInterface.h>
#include "Teuchos_StandardCatchMacros.hpp"

#include <Solver/Nox/Nox.h>
#include <Solver/Nox/NoxSettings.h>

#include <Core/Utils/numeric/bindings/ublas.hpp>
#include <Core/Utils/numeric/utils.h>


#include <iostream>


//!Constructor
Nox::Nox(INonLinSolverSettings* settings,shared_ptr<INonLinearAlgLoop> algLoop)
	 :AlgLoopSolverDefaultImplementation()
	, _algLoop            (algLoop)
	, _noxSettings        ((INonLinSolverSettings*)settings)
	, _iterationStatus    (CONTINUE)
	, _y                  (NULL)
	, _y0                 (NULL)
	, _y_old              (NULL)
	, _y_new              (NULL)
	, _yScale             (NULL)
  , _helpArray          (NULL)
	, _firstCall		  (true)
	, _useDomainScaling         (false)
	, _currentIterate             (NULL)

  , _lc(LC_NLS)
  , _SimTimeOld  (0.0)
  , _SimTimeNew  (0.0)
{
	if (_algLoop)
	{
		AlgLoopSolverDefaultImplementation::initialize(_algLoop->getDimZeroFunc(),_algLoop->getDimReal());
	}
	else
	{
		throw ModelicaSimulationError(ALGLOOP_SOLVER, "solve for single instance is not supported");
	}

}

//!Destructor
Nox::~Nox()
{
	if(_y)                  delete []  _y;
	if(_y0)                 delete []  _y0;
    if(_y_old)              delete [] _y_old;
    if(_y_new)              delete [] _y_new;
    if(_yScale)              delete [] _yScale;
	if(_currentIterate) delete [] _currentIterate;
	if(_helpArray) delete [] _helpArray;
}
/**
 *  \brief initialize
 *
 *  \return allocates memory
 *
 *  \details Details
 */
void Nox::initialize()
{
	_firstCall = false;
	 if(_algLoop)
      _algLoop->initialize();
    else
	  throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
    _dimSys = _algLoop->getDimReal();
	AlgLoopSolverDefaultImplementation::initialize(_algLoop->getDimZeroFunc(),_dimSys);
	if(_y) delete [] _y;
	if(_y0) delete [] _y0;
	if(_y_old) delete [] _y_old;
	if(_y_new) delete [] _y_new;
    if(_yScale) delete [] _yScale;
    if(_helpArray) delete [] _helpArray;


	_output = Teuchos::rcp(new std::stringstream);
	_y                = new double[_dimSys];
	_y0               = new double[_dimSys];
	_y_old            = new double[_dimSys];
	_y_new            = new double[_dimSys];
	_yScale            = new double[_dimSys];
	_currentIterate            = new double[_dimSys];
	_helpArray            = new double[_dimSys];

  memset(_helpArray, 0, _dimSys*sizeof(double));

	_algLoop->getReal(_y);
	_algLoop->getReal(_y0);
	_algLoop->getReal(_y_new);
	_algLoop->getReal(_y_old);
  _algLoop->getNominalReal(_yScale);
  for (int i=0; i<_dimSys; i++){
    if(_yScale[i] != 0)
      _yScale[i] = 1/_yScale[i];
    else
      _yScale[i] = 1;
  }


	// Set up the status tests
  _statusTestNormF = Teuchos::rcp(new NOX::StatusTest::NormF(_noxSettings->getRtol()));
  _statusTestMaxIters = Teuchos::rcp(new NOX::StatusTest::MaxIters(_noxSettings->getNewtMax()));
  _statusTestStagnation = Teuchos::rcp(new NOX::StatusTest::Stagnation(15,0.99));
  _statusTestDivergence = Teuchos::rcp(new NOX::StatusTest::Divergence(1.0e13));
  //_statusTestSgnChange = Teuchos::rcp(new NOX::StatusTest::SgnChange(5.0e-7));

	_statusTestsCombo = Teuchos::rcp(new NOX::StatusTest::Combo(NOX::StatusTest::Combo::OR, _statusTestNormF, _statusTestMaxIters));
	_statusTestsCombo->addStatusTest(_statusTestStagnation);
	_statusTestsCombo->addStatusTest(_statusTestDivergence);
	//_statusTestsCombo->addStatusTest(_statusTestSgnChange);
}
/**
 *  \brief main solving routine
 *
 *  \return void
 *
 *  \details solves nonlinear algloop with linearly extrapolated start value.\n
 *  Abort if NOX' status tests yield convergence, CheckWhetherSolutionIsNearby() yields true (both lead to _iterationStatus=DONE) or !_algLoop->isConsistent() (_iterationStatus=CONTINUE)\n
 *  Methods are applied in the following order:\n
 *  If division by zero occurs, vary initial guess by adding +-10% to each entry.\n
 *  Try various methods set in modifySolverParameters() (is a private function, so EXTRACT_PRIVATE = YES has to be set in the doxygen configuration file, which can be found in OpenModelica/doc/SimulationRuntime/cpp/CppRuntimeDoc.in), starting with %Newton's method\n
 *  Try homotopy\n
 *  Try various initial guesses:\n
 *  nominal values\n
 *  without extrapolation (solution from previous timestep as initial guess)\n
 *  vary initial guess by adding +-10% to each entry.\n
 *  Abort if all methods fail (_iterationStatus=SOLVERERROR), throw error if this happens.\n\n
 *  The parameters for the NOX solver can be found here:
 *  For detailed calibration, check https://trilinos.org/docs/dev/packages/nox/doc/html/parameters.html
 *
 */

void Nox::solve(shared_ptr<INonLinearAlgLoop> algLoop,bool first_solve = false)
{
	throw ModelicaSimulationError(ALGLOOP_SOLVER, "solve for single instance is not supported");
}
void Nox::solve()
{
	int iter=-1; //Iterationcount of proper methods
	NOX::StatusTest::StatusType status;
	bool handleddivisionbyzeroerror=false;
  _OutOfProperMethods=false;
  _eventRetry=false;

  LOGGER_WRITE_BEGIN("Nox: start solving algebraic loop no. " + to_string(_algLoop->getEquationIndex()) + " at Simulation time " + to_string(_algLoop->getSimTime()), _lc, LL_DEBUG);

  //setup solver
  if (!restart)
  {

	LOGGER_WRITE("initialize...",_lc, LL_DEBUG);
    _algLoop = algLoop;
    initialize();
	LOGGER_WRITE("init done!",_lc, LL_DEBUG);
  }
  if(!_algLoop)
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");

	// Create the list of solver parameters. For detailed calibration, check https://trilinos.org/docs/dev/packages/nox/doc/html/parameters.html
  _solverParametersPtr = Teuchos::rcp(new Teuchos::ParameterList);
  _solverParametersPtr->set("Nonlinear Solver", "Line Search Based");
	_solverParametersPtr->sublist("Line Search").set("Method", "Full Step");
	addPrintingList(_solverParametersPtr);

	_noxLapackInterface = Teuchos::rcp(new NoxLapackInterface (_algLoop));//this also gets the nominal values

	_iterationStatus=CONTINUE;


  //try extrapolating initial guess. Up to now, y0=y_new. Now we want that (y0,_algLoop->getSimTime()),(y_new,_SimTimeNew),(y_old,_SimTimeOld) form a line.
  //This is equivalent to the formula y0=y_new+(y_new-y_old)*(_algLoop->getSimTime()-_SimTimeNew)/(_SimTimeNew-_SimTimeOld)
  if((_SimTimeOld!=_SimTimeNew)){
    //store times temporarily for lambda expression
    double SimTimeCurrent = _algLoop->getSimTime();
    double SimTimeNew = _SimTimeNew;
    double SimTimeOld = _SimTimeOld;
    std::transform(_y_old,_y_old+_dimSys,_y_new,_y0,[&SimTimeNew,&SimTimeOld,&SimTimeCurrent](const double &a,const double &b)->double{return b+(b-a)*(SimTimeCurrent-SimTimeNew)/(SimTimeNew-SimTimeOld);});
    LOGGER_WRITE("Using extrapolated values for y0:",_lc, LL_DEBUG);
    LOGGER_WRITE("SimTime =" + to_string(_algLoop->getSimTime()),_lc, LL_DEBUG);
    LOGGER_WRITE_VECTOR("y0",_y0,_dimSys,_lc, LL_DEBUG);
    LOGGER_WRITE("SimTime =" + to_string(_algLoop->getSimTime()),_lc, LL_DEBUG);
    LOGGER_WRITE_VECTOR("yOld",_y_old,_dimSys,_lc, LL_DEBUG);
    LOGGER_WRITE("SimTimeNew =" + to_string(_SimTimeNew),_lc, LL_DEBUG);
    LOGGER_WRITE_VECTOR("yNew",_y_new,_dimSys,_lc, LL_DEBUG);
  }

  //handle division by zero
	try{
		memcpy(_y,_y0,_dimSys*sizeof(double));
		_algLoop->setReal(_y);
		_algLoop->evaluate();
	}
	catch(const std::exception &ex)
	{
		if(isdivisionbyzeroerror(ex)){
			handleddivisionbyzeroerror=true;
			divisionbyzerohandling(_y0);
		}else{
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"failed when evaluating algloop for the first time with error message: " + std::string(ex.what()));//this could be extended to handle other forms of failure as well.
		}
	}

  //try various methods, excluding homotopy

  while((_iterationStatus==CONTINUE) && (!_OutOfProperMethods) && !_eventRetry){
		iter++;

		// Reset initial guess
		if(!handleddivisionbyzeroerror){
			memcpy(_y,_y0,_dimSys*sizeof(double));
		}
		_algLoop->setReal(_y);

		_grp = Teuchos::rcp(new NOX::LAPACK::Group(*_noxLapackInterface));//this also calls the getInitialGuess-function in the NoxLapackInterface and sets the initial guess in the NOX::LAPACK::Group

		_solver = NOX::Solver::buildSolver(_grp, _statusTestsCombo, _solverParametersPtr);

    LOGGER_WRITE("solving...",_lc, LL_DEBUG);

		try{
			status = _solver->solve();
			printLogger();
		}
		catch(const std::exception &ex)
		{
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"solving error");
		}

    // Get the answer
    copySolution(_solver,_y);

    LOGGER_WRITE("solving done!",_lc, LL_DEBUG);

		if (status==NOX::StatusTest::Converged){
      _algLoop->setReal(_y);
      _algLoop->evaluate();
			_iterationStatus=DONE;
		}else{
      CheckWhetherSolutionIsNearbyWrapper();
      if(_iterationStatus!=DONE){
        check4EventRetry(_y);
        if ((iter==0) || (iter==1)) iter = 2;
        modifySolverParameters(_solverParametersPtr,iter);
      }
		}
	}

  //try homotopy
  int numberofhomotopytries = 0;
  while((_iterationStatus==CONTINUE) && (numberofhomotopytries<_noxLapackInterface->getMaxNumberOfHomotopyTries()) && !_eventRetry){
    LOGGER_WRITE("Solving with Homotopy at numberofhomotopytries = " + to_string(numberofhomotopytries),_lc, LL_DEBUG);

    // Reset initial guess
    memcpy(_y,_y0,_dimSys*sizeof(double));
    _algLoop->setReal(_y);

    try{
      LocaHomotopySolve(numberofhomotopytries);
    }
    catch(const std::exception &e){
      std::string errorstring(e.what());
      LOGGER_WRITE("Solving with Homotopy failed with error message " + errorstring + " at numberofhomotopytries = " + to_string(numberofhomotopytries),_lc, LL_DEBUG);
    }
    numberofhomotopytries++;
  }

  //try varying initial guess

  //try setting initial guess to nominal values
  if((_iterationStatus==CONTINUE) && (!_eventRetry)){
    _algLoop->getNominalReal(_y);
    LOGGER_WRITE("Trying to solve with nominal values given by ",_lc, LL_DEBUG);
    LOGGER_WRITE_VECTOR("yNominal", _y, _dimSys, _lc, LL_DEBUG);

    _algLoop->setReal(_y);
    if(BasicNLSsolve()==NOX::StatusTest::Converged){
      _iterationStatus=DONE;
    }else{
      CheckWhetherSolutionIsNearbyWrapper();
    }
  }

  //try homotopy with nominal values as initial guess
  //this does not help in the test suite and could therefore be deleted.

  // numberofhomotopytries = 0;
  // while((_iterationStatus==CONTINUE) && (numberofhomotopytries<_noxLapackInterface->getMaxNumberOfHomotopyTries()) && !_eventRetry){
    // LOGGER_WRITE("Solving with Homotopy at numberofhomotopytries = " + to_string(numberofhomotopytries) + " with nominal values as start values.",_lc, LL_DEBUG);

    // Reset initial guess
    // _algLoop->getNominalReal(_y);
    // _algLoop->setReal(_y);

    // try{
      // LocaHomotopySolve(numberofhomotopytries);
    // }
    // catch(const std::exception &e){
      // std::string errorstring(e.what());
      // LOGGER_WRITE("Solving with Homotopy failed with error message " + errorstring + " at numberofhomotopytries = " + to_string(numberofhomotopytries),_lc, LL_DEBUG);
    // }
    // numberofhomotopytries++;
  // }

  //no extrapolation of the initial guess

  if((_iterationStatus==CONTINUE) && (!_eventRetry)){
    memcpy(_y,_y_new,_dimSys*sizeof(double));
    LOGGER_WRITE("Trying to solve without extrapolated values",_lc, LL_DEBUG);
    LOGGER_WRITE_VECTOR("y", _y, _dimSys, _lc, LL_DEBUG);

    _algLoop->setReal(_y);
    if(BasicNLSsolve()==NOX::StatusTest::Converged){
      _iterationStatus=DONE;
    }else{
      CheckWhetherSolutionIsNearbyWrapper();
    }
  }

  //try varying initial guess y0 by 10%.
  //this can be accelerated to varying zero and equal start values only.
  int VaryInitGuess=0;
  while((_iterationStatus==CONTINUE) && (VaryInitGuess<std::pow(2,_dimSys)) && !_eventRetry){
    modify_y(VaryInitGuess);
    if(BasicNLSsolve()==NOX::StatusTest::Converged){
      _iterationStatus=DONE;
    }else{
      CheckWhetherSolutionIsNearbyWrapper();
    }
    VaryInitGuess++;
  }

  //we could try and solve a linear system, since the corresponding ticket has not been fixed yet in OpenModelica (Ticket 4374)


  if (_iterationStatus==DONE){
    LOGGER_WRITE("Solution found!", _lc, LL_DEBUG);
    LOGGER_WRITE_VECTOR("Solution", _y, _dimSys, _lc, LL_DEBUG);
    LOGGER_WRITE_END(_lc, LL_DEBUG);
  }else{
    if(_eventRetry)
    {
      memcpy(_y, _helpArray ,_dimSys*sizeof(double));
      _iterationStatus = CONTINUE;
    }else{
      LOGGER_WRITE("Nox Failed!", _lc, LL_DEBUG);
      LOGGER_WRITE_END(_lc, LL_DEBUG);
      _iterationStatus=SOLVERERROR;
      throw ModelicaSimulationError(ALGLOOP_SOLVER,"Nonlinear solver failed!");
    }
  }
}
/**
 *  \brief Brief
 *
 *  \return Return_Description
 *
 *  \details Details
 */
INonLinearAlgLoopSolver::ITERATIONSTATUS Nox::getIterationStatus()
{
	return _iterationStatus;
}
/**
 *  \brief derived
 *
 *  \param [in] time Equal to _algLoop->getSimTime()
 *  \return void
 *
 *  \details updates previous solutions and the time when they have been computed.
 */
void Nox::stepCompleted(double time)
{
   if(!_algLoop)
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");

	memcpy(_y0,_y,_dimSys*sizeof(double));
  memcpy(_y_old,_y_new,_dimSys*sizeof(double));
  memcpy(_y_new,_y,_dimSys*sizeof(double));
  if (time == _algLoop->getSimTime()){
    _SimTimeOld = _SimTimeNew;
    _SimTimeNew = _algLoop->getSimTime();
  }
}
bool* Nox::getConditionsWorkArray()
{
	return AlgLoopSolverDefaultImplementation::getConditionsWorkArray();

}
bool* Nox::getConditions2WorkArray()
{

	return AlgLoopSolverDefaultImplementation::getConditions2WorkArray();
 }


 double* Nox::getVariableWorkArray()
 {

	return AlgLoopSolverDefaultImplementation::getVariableWorkArray();

 }
/**
 *  \brief Restores all algloop variables for a output step
 *  \return Return_Description
 *  \details Details
 */
void Nox::restoreOldValues()
{
    memcpy(_y,_y_old,_dimSys*sizeof(double));

}
    /**
 *  \brief Restores all algloop variables for last output step
 *  \return Return_Description
 *  \details Details
 */
void Nox::restoreNewValues()
{
    memcpy(_y,_y_new,_dimSys*sizeof(double));
}
/**
 *  \brief See Kinsol's implementation
 *
 *  \param [in] y Parameter_Description
 *  \return Return_Description
 *
 *  \details Details
 */
void Nox::check4EventRetry(double* y)
{
	 if(!_algLoop)
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
	_algLoop->setReal(y);
	if(!(_algLoop->isConsistent()) && !_eventRetry)
	{
		memcpy(_helpArray, y,_dimSys*sizeof(double));
		_eventRetry = true;
	}
}
/**
 *  \brief Solve with homotopy method
 *
 *  \param [in] numberofhomotopytries number of simple function. See also NoxLapackInterface::computeSimplifiedF()
 *  \return void
 *
 *  \details Numerical continuation in lambda with the equation system\n
 *  lambda*F(x)+(1-lambda)*G(x)\n
 *  F(x) is the nonlinear system that we want to solve\n
 *  see also NoxLapackInterface::computeSimplifiedF() for G(x)
 */
void Nox::LocaHomotopySolve(const int numberofhomotopytries)
{
  LOGGER_WRITE("We are going to solve algloop " + to_string(_algLoop->getEquationIndex()) + "using homotopy with numberofhomotopytries=" + to_string(numberofhomotopytries),_lc, LL_DEBUG);

	//We are setting up the problem to perform arc-length continuation in the parameter "lambda" from 0 to 1 with a maximum of 50 continuation steps and maxNewtonIters nonlinear iterations per step.
	//Since we are doing an equilibrium continuation, we set the bifurcation method to "None".
	//We use a secant predictor and adaptive step size control with an initial step size of 0.1, maximum of 1.0 and minimum of 0.001.

	// Create parameter list. For detailed calibration, check https://trilinos.org/docs/dev/packages/nox/doc/html/parameters.html
	Teuchos::RCP<Teuchos::ParameterList> paramList = Teuchos::rcp(new Teuchos::ParameterList);
	// Create LOCA sublist
	Teuchos::ParameterList& locaParamsList = paramList->sublist("LOCA");
	// Create the stepper sublist and set the stepper parameters
	Teuchos::ParameterList& stepperList = locaParamsList.sublist("Stepper");
	stepperList.set("Continuation Method", "Arc Length");// Default
	//stepperList.set("Continuation Method", "Natural");
	stepperList.set("Continuation Parameter", "lambda");  // Must set
	stepperList.set("Initial Value", 0.0);             // Must set
	stepperList.set("Max Value", 1.0);             // Must set
	stepperList.set("Min Value", 0.0);             // Must set
	//stepperList.set("Max Steps", 50);                    // Should set
	stepperList.set("Max Nonlinear Iterations", 200); // Should set
	//stepperList.set("Compute Eigenvalues",false);        // Default
	// Create bifurcation sublist
	//Teuchos::ParameterList& bifurcationList = locaParamsList.sublist("Bifurcation");
	//bifurcationList.set("Type", "None");                 // Default
	// Create predictor sublist
	//Teuchos::ParameterList& predictorList = locaParamsList.sublist("Predictor");
	//predictorList.set("Method", "Secant");               // Default
	//predictorList.set("Method", "Constant");
	//predictorList.set("Method", "Tangent");
	// Create step size sublist
	Teuchos::ParameterList& stepSizeList = locaParamsList.sublist("Step Size");
	stepSizeList.set("Method", "Adaptive");             // Default
	stepSizeList.set("Initial Step Size", 1.0e-8);   // Should set
	stepSizeList.set("Min Step Size", 1.0e-9);    // Should set
	stepSizeList.set("Max Step Size", 1.0);      // Should set

	// Create the "Solver" parameters sublist to be used with NOX Solvers
	Teuchos::ParameterList& nlParams = paramList->sublist("NOX");
	nlParams.set("Nonlinear Solver", "Line Search Based");
	nlParams.sublist("Line Search");
	nlParams.sublist("Line Search").set("Method", "Backtrack");
	nlParams.sublist("Line Search").sublist("Backtrack").set("Default Step", 1.0);
	nlParams.sublist("Line Search").sublist("Backtrack").set("Minimum Step", 1.0e-30);
	nlParams.sublist("Line Search").sublist("Backtrack").set("Recovery Step", 0.0);

	Teuchos::ParameterList& nlPrintParams = nlParams.sublist("Printing");
	nlPrintParams.set("Output Precision", 15);
	nlPrintParams.set("Output Stream", _output);
	nlPrintParams.set("Error Stream", _output);
	//Set the level of output
  nlPrintParams.set("Output Information", NOX::Utils::Details + NOX::Utils::OuterIteration + NOX::Utils::Warning + NOX::Utils::StepperIteration + NOX::Utils::StepperDetails + NOX::Utils::StepperParameters);  // Should set

	// Create LAPACK Factory
	Teuchos::RCP<LOCA::LAPACK::Factory> lapackFactory = Teuchos::rcp(new LOCA::LAPACK::Factory);
	// Create global data object
	Teuchos::RCP<LOCA::GlobalData> globalData = LOCA::createGlobalData(paramList, lapackFactory);

	// Set up the problem interface
	Teuchos::RCP<NoxLapackInterface> LocaLapackInterface = Teuchos::rcp(new NoxLapackInterface (_algLoop));//this also gets the nominal values
  LocaLapackInterface->setNumberOfHomotopyTries(numberofhomotopytries);
	LOCA::ParameterVector p;
	p.addParameter("lambda",0.0);

	// Create a group which uses that problem interface. The group will
	// be initialized to contain the default initial guess for the
	// specified problem.
	Teuchos::RCP<LOCA::MultiContinuation::AbstractGroup> grp = Teuchos::rcp(new LOCA::LAPACK::Group(globalData, *LocaLapackInterface));
	grp->setParams(p);

	// Set up the status tests
  Teuchos::RCP<NOX::StatusTest::NormF> statusTestNormF = Teuchos::rcp(new NOX::StatusTest::NormF(1.0e-7));
  Teuchos::RCP<NOX::StatusTest::MaxIters> statusTestMaxIters = Teuchos::rcp(new NOX::StatusTest::MaxIters(100));
  Teuchos::RCP<NOX::StatusTest::Stagnation> statusTestStagnation = Teuchos::rcp(new NOX::StatusTest::Stagnation(15,0.99));
  Teuchos::RCP<NOX::StatusTest::Divergence> statusTestDivergence = Teuchos::rcp(new NOX::StatusTest::Divergence(1.0e13));
  //statusTestSgnChange = Teuchos::rcp(new NOX::StatusTest::SgnChange(5.0e-7));
	Teuchos::RCP<NOX::StatusTest::Combo> statusTestsCombo = Teuchos::rcp(new NOX::StatusTest::Combo(NOX::StatusTest::Combo::OR, statusTestNormF, statusTestMaxIters));
	statusTestsCombo->addStatusTest(statusTestStagnation);
	statusTestsCombo->addStatusTest(statusTestDivergence);

	// Create the stepper
	LOCA::Stepper stepper(globalData, grp, statusTestsCombo, paramList);

	try{
		// Perform continuation run
		LOCA::Abstract::Iterator::IteratorStatus status = stepper.run();
		printLogger();
		// Check for convergence
		if (status != LOCA::Abstract::Iterator::Finished){
      LOGGER_WRITE("Stepper failed to converge!",_lc, LL_DEBUG);
		}else{
      LOGGER_WRITE("Stepper was successful!",_lc, LL_DEBUG);
			_iterationStatus=DONE;
		}
	}
	catch(const std::exception &ex)
	{
    LOGGER_WRITE("sth went wrong during stepper running, with error message" + std::string(ex.what()),_lc, LL_DEBUG);
		throw ModelicaSimulationError(ALGLOOP_SOLVER,"solving error");
	}

  if(_iterationStatus==DONE){
    // Get the final solution from the stepper
    Teuchos::RCP<const LOCA::LAPACK::Group> finalGroup = Teuchos::rcp_dynamic_cast<const LOCA::LAPACK::Group>(stepper.getSolutionGroup());
    const NOX::LAPACK::Vector& finalSolution = dynamic_cast<const NOX::LAPACK::Vector&>(finalGroup->getX());

    for (int i=0;i<_dimSys;i++){
      if (_useDomainScaling){
        _y[i]=finalSolution(i)/_yScale[i];
      }else{
        _y[i]=finalSolution(i);
      }
    }

    _algLoop->setReal(_y);
    try{
      _algLoop->evaluate();
    }catch(const std::exception &ex)
    {
      LOGGER_WRITE("algloop evaluation after solve failed with error message:" + std::string(ex.what()) + "\nThis should not be seen, since _iterationStatus=DONE",_lc, LL_DEBUG);
    }
  }
  LOCA::destroyGlobalData(globalData);
}
/**
 *  \brief simple NLS solver based on Backtracking
 *
 *  \return void
 *
 *  \details requires a previously set initial guess (in algebraic loop)
 */
NOX::StatusTest::StatusType Nox::BasicNLSsolve(){
	NOX::StatusTest::StatusType status = NOX::StatusTest::Unevaluated;
	try{
		Teuchos::RCP<NoxLapackInterface> noxLapackInterface=Teuchos::rcp(new NoxLapackInterface(_algLoop));
		Teuchos::RCP<NOX::LAPACK::Group> grp=Teuchos::rcp(new NOX::LAPACK::Group(*noxLapackInterface));
		Teuchos::RCP<Teuchos::ParameterList> solverParametersPtr = Teuchos::rcp(new Teuchos::ParameterList);
		addPrintingList(solverParametersPtr);
		solverParametersPtr->sublist("Line Search").set("Method","Backtrack");
		solverParametersPtr->sublist("Line Search").sublist("Backtrack").set("Recovery Step", 0.0);
		Teuchos::RCP<NOX::Solver::Generic> solver = NOX::Solver::buildSolver(grp, _statusTestsCombo, solverParametersPtr);
		status = solver->solve();
		printLogger();
    copySolution(solver,_y);

		if (status == NOX::StatusTest::Converged){
			_algLoop->setReal(_y);
			_algLoop->evaluate();
		}
	}
	catch(const std::exception &ex)
	{
		throw ModelicaSimulationError(ALGLOOP_SOLVER,"solving error in Algloop " + std::to_string(_algLoop->getEquationIndex()) + " at simtime " + std::to_string(_algLoop->getSimTime()) + ", with error message: " + std::string(ex.what()));
	}
  return status;
}
/**
 *  \brief changes solving method
 *
 *  \param [in] solverParametersPtr pointer to solver parameters
 *  \param [in] iter number
 *  \return void
 *
 *  \details Given iter the following method is used:\n
 *  iter = 0 nothing changes\n
 *  iter = 1 damped Newton with fixed damping factor 0.5\n
 *  iter = 2 backtracking\n
 *  iter = 3 polynomial\n
 *  iter = 4 More'-Thuente\n
 *  iter = 5 trust region\n
 *  iter = 6 inexact trust region
 */
void Nox::modifySolverParameters(const Teuchos::RCP<Teuchos::ParameterList> solverParametersPtr,const int iter){

	switch (iter){
	case 0:
		break;
		//default Nox Line Search failed -> Try damped Newton instead
	case 1://should delete this. It typically does not help
		solverParametersPtr->sublist("Line Search").sublist("Full Step").set("Full Step", 0.5);
		break;

		//default Nox Line Search failed -> Try Backtracking instead
	case 2:
		solverParametersPtr->sublist("Line Search").set("Method", "Backtrack");
		//solverParametersPtr->sublist("Line Search").sublist("Backtrack").set("Default Step", 1024.0*1024.0);
		solverParametersPtr->sublist("Line Search").sublist("Backtrack").set("Minimum Step", 1.0e-30);
		solverParametersPtr->sublist("Line Search").sublist("Backtrack").set("Recovery Step", 0.0);
		//std::cout << "we just set the solver parameters to use backtrack. the currently used options are:" << std::endl;
		//solverParametersPtr->print();
		//std::cout << std::endl;
		break;

		//Backtracking failed -> Try Polynomial with various parameters instead
	case 3:
		solverParametersPtr->sublist("Line Search").set("Method", "Polynomial");
		solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Minimum Step", 1.0e-30);
		//solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Alpha Factor", 1.0e-2);
		break;

	// case 4:
		// solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic");
		// break;

	// case 5:
		// solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic3");
		// break;

	// case 6:
		// solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Sufficient Decrease Condition", "Ared/Pred");
		// solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Cubic");
		// break;

	// case 7:
		// solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic");
		// break;

	// case 8:
		// solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic3");
		// break;

		//Polynomial failed -> Try More'-Thuente instead
	case 4:
		solverParametersPtr->sublist("Line Search").set("Method", "More'-Thuente");
		// solverParametersPtr->sublist("Line Search").sublist("More'-Thuente").set("Recovery Step", std::numeric_limits<double>::min());//I would set this to 0.0, but then More Thuente throws an error:/
		//solverParametersPtr->sublist("Line Search").sublist("More'-Thuente").set("Sufficient Decrease", 1.0e-2);
		break;

		//More'-Thuente failed -> Try Trust Region instead
	case 5:
		//solverParametersPtr->sublist("Line Search").remove("Method", true);
		solverParametersPtr->set("Nonlinear Solver", "Trust Region Based");
		solverParametersPtr->sublist("Trust Region").set("Minimum Improvement Ratio", 1.0e-4);
		solverParametersPtr->sublist("Trust Region").set("Minimum Trust Region Radius", 1.0e-6);
		break;

		//Trust Region failed -> Try Inexact Trust Region instead
	case 6:
		//solverParametersPtr->sublist("Trust Region").set("Use Dogleg Segment Minimization", true);
		solverParametersPtr->set("Nonlinear Solver", "Inexact Trust Region Based");
    solverParametersPtr->sublist("Trust Region").set("Recovery Step", 0.0);
		break;

		//Inexact Trust Region failed -> Try Tensor instead
	//case 11:
		//solverParametersPtr->set("Nonlinear Solver", "Tensor Based");
		//break;

		//Tensor failed or other failure
	default:
    _OutOfProperMethods=true;
	}
}
/**
 *  \brief checks for sign changes nearby
 *
 *  \param [in] y guess for solution
 *  \return true if solution is nearby, false if not
 *
 *  \details checks for sign changes in y+-eps*e_i, where eps is approximately 1.0e-16 and e_i is the i-th unit vector
 */
bool Nox::CheckWhetherSolutionIsNearby(double const * const y){
	double* rhs=new double [_dimSys];
	double* rhs2=new double [_dimSys];
	double* ypluseps=new double [_dimSys];
	std::vector<bool> rhssignchange(_dimSys, false);
	_algLoop->setReal(y);
	_algLoop->evaluate();
	_algLoop->getRHS(rhs);

  memcpy(ypluseps,y,_dimSys*sizeof(double));

	for (int i=0;i<_dimSys;i++){
		// evaluate algLoop at ypluseps=y+eps*e_i and save in rhs2
		ypluseps[i]=std::nextafter(std::nextafter(ypluseps[i],std::numeric_limits<double>::max()),std::numeric_limits<double>::max());
		_algLoop->setReal(ypluseps);
		_algLoop->evaluate();
		_algLoop->getRHS(rhs2);
		ypluseps[i]=y[i];
		// compare
		for(int j=0;j<_dimSys;j++){
			if (rhs[j]*rhs2[j]<=0.0){
				rhssignchange[j]= true;
			}
		}

		// do the same for y-eps*e_i
		ypluseps[i]=std::nextafter(std::nextafter(ypluseps[i],-std::numeric_limits<double>::max()),-std::numeric_limits<double>::max());
		_algLoop->setReal(ypluseps);
		_algLoop->evaluate();
		_algLoop->getRHS(rhs2);
		ypluseps[i]=y[i];

		for(int j=0;j<_dimSys;j++){
			if (rhs[j]*rhs2[j]<=0.0){
				rhssignchange[j]= true;
			}
		}
	}

  _algLoop->setReal(y);
  _algLoop->evaluate();
	delete [] ypluseps;
	delete [] rhs2;
	delete [] rhs;
	return std::all_of(rhssignchange.begin(),rhssignchange.end(),[](bool a){return a;});
}

void Nox::CheckWhetherSolutionIsNearbyWrapper(){
      bool EvalAfterSolveFailed=false;
      _algLoop->setReal(_y);
      try{
        _algLoop->evaluate();
			}catch(const std::exception & ex){
        EvalAfterSolveFailed=true;
        LOGGER_WRITE("EvalAfterSolveFailed",_lc, LL_DEBUG);//this may be interesting in future.
      }
      //&& is important here, since CheckWhetherSolutionIsNearby(_y) throws an error if EvalAfterSolveFailed=true.
      if((!EvalAfterSolveFailed) && (CheckWhetherSolutionIsNearby(_y))){
          _algLoop->setReal(_y);
          _algLoop->evaluate();
          _iterationStatus=DONE;
      }
}

/**
 *  \brief checks whether the exception contains a string "Division by zero."
 *
 *  \param [in] ex exception
 *  \return Return_Description
 *
 *  \details Details
 */
bool Nox::isdivisionbyzeroerror(const std::exception &ex){
	std::string divbyzero = "Division by zero";
	std::string errorstring(ex.what());
	//we only do the error handling by variation of initial guess in case of division by zero at evaluation of initial guess
	return (errorstring.find(divbyzero)!=std::string::npos);
}

//additionally modifies _y and the algLoop
/**
 *  \brief handles division by zero errors.
 *
 *  \param [in] y0 start value for modification
 *  \return set _y as y0 with entries varied by +-10%.
 *
 *  \details solves the nonlinear system with a basic nonlinear solver after the modification and tries other modifications if the current modification does not lead to a solution.
 */
void Nox::divisionbyzerohandling(double const * const y0){
	NOX::StatusTest::StatusType stat = NOX::StatusTest::Unevaluated;
	int initialguessdividebyzerofailurecounter = 0;
	bool detecteddivisionbyzero;
	std::vector<double> startvaluemodifier(_dimSys);

	while((stat!=NOX::StatusTest::Converged)){
		detecteddivisionbyzero=true;

		memcpy(_y,y0,_dimSys*sizeof(double));

		if (initialguessdividebyzerofailurecounter>std::pow(2.0,static_cast<double>(_dimSys-1))){
      LOGGER_WRITE("Could not find a good initial guess with a root nearby:(",_lc, LL_DEBUG);
			throw;
		}

		//converts initialguessdividebyzerofailurecounter into its binary representation and store it in startvaluemodifier
		for(int i=0;i<_dimSys;i++)
		{
			startvaluemodifier[i]=static_cast<int>(initialguessdividebyzerofailurecounter/std::floor(std::pow(2.0,static_cast<double>(i))))%2;
			if (startvaluemodifier[i]==0) startvaluemodifier[i]=-1;
		}

    LOGGER_WRITE("initialguessdividebyzerofailurecounter = " + to_string(initialguessdividebyzerofailurecounter),_lc, LL_DEBUG);
    LOGGER_WRITE_VECTOR("startvaluemodifier", startvaluemodifier.data(), _dimSys, _lc, LL_DEBUG);

		initialguessdividebyzerofailurecounter++;

    LOGGER_WRITE("Varying initial guess by 10%",_lc, LL_DEBUG);

		for (int i=0;i<_dimSys;i++){
			if(_y[i]!=0.0){
				_y[i]+=0.1*_y[i]*startvaluemodifier[i];
			}else{
				_y[i]=0.1*startvaluemodifier[i];
			}
		}

		_algLoop->setReal(_y);
		while(detecteddivisionbyzero){
			try{
				_algLoop->evaluate();
				detecteddivisionbyzero=false;
				stat = BasicNLSsolve();
			}
			catch(const std::exception &ex){
				if(isdivisionbyzeroerror(ex)){
          LOGGER_WRITE("still dividing by zero, trying new initial guess.",_lc, LL_DEBUG);//this never happens
				}else{
          LOGGER_WRITE("eval after solve failed when trying to fix division by zero error with error message " + std::string(ex.what()),_lc, LL_DEBUG);//this does
					throw;
				}
			}
		}
	}
}
/**
 *  \brief converts number to its binary representation and stores it in result.
 *
 *  \param [out] result binary representation
 *  \param [in] number input number
 *  \return Return_Description
 *
 *  \details Details
 */
void Nox::BinRep(std::vector<double> &result, const int number){
  if (number > std::pow(2.0,static_cast<double>(result.size()))-1.0) throw std::range_error("Binary representation out of range");
  for(unsigned int i=0;i<result.size();i++)
	{
		result[i]=static_cast<int>(number/std::floor(std::pow(2.0,static_cast<double>(i))))%2;
	}
}
/**
 *  \brief replaces 0 by -1 in binary representation of counter and perturbates _y according to this binary representation.
 *
 *  \param [in] counter counter
 *  \return true if algloop can be evaluated in modified _y, false else.
 *
 *  \details If the i-th entry of the binary representation of counter is 1, _y[i] is multiplied by 1.1, otherwise by 0.9. If _y[i] is zero, its value is set to 0.1 or -0.1 times the i-th entry of the nominal value.
 */
bool Nox::modify_y(const int counter){
	std::vector<double> startvaluemodifier(_dimSys);

	memcpy(_y,_y0,_dimSys*sizeof(double));

  BinRep(startvaluemodifier,counter);

  //replace 0 by -1.
  std::for_each(startvaluemodifier.begin(),startvaluemodifier.end(), [](double &d){d=(d==0.0) ? -1.0 : d;});

  LOGGER_WRITE("Varying initial guess by 10%:",_lc, LL_DEBUG);
	for (int i=0;i<_dimSys;i++){
    _y[i] += (_y[i]!=0.0) ? 0.1*_y[i]*startvaluemodifier[i] : 0.1*startvaluemodifier[i]*_yScale[i];
	}

	_algLoop->setReal(_y);
	try{
		_algLoop->evaluate();
    return true;
	}
	catch(const std::exception &ex){
    LOGGER_WRITE("Error occured when varying initial guess with error message " + std::string(ex.what()),_lc, LL_DEBUG);
	}
  return false;
}

//writes output
/**
 *  \brief prints output of NOX
 *
 *  \return Return_Description
 *
 *  \details Details
 */
void Nox::printLogger(){
	if(!((dynamic_cast<const std::stringstream &>(*_output)).str().empty())){
		LOGGER_WRITE_BEGIN("NOX: ",LC_NLS,LL_DEBUG);
		LOGGER_WRITE((dynamic_cast<const std::stringstream &>(*_output)).str(),LC_NLS,LL_DEBUG);
		LOGGER_WRITE_END(LC_NLS,LL_DEBUG);
    (dynamic_cast<std::stringstream &>(*_output)).str("");
	}
}

/**
 *  \brief sets printing list in solverParametersPtr
 *
 *  \param [in] solverParametersPtr Parameter_Description
 *  \return Return_Description
 *
 *  \details Details
 */
void Nox::addPrintingList(const Teuchos::RCP<Teuchos::ParameterList> solverParametersPtr){
  solverParametersPtr->sublist("Printing").set("Output Precision", 15);
  solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error + NOX::Utils::Warning + NOX::Utils::OuterIteration + NOX::Utils::InnerIteration);
  solverParametersPtr->sublist("Printing").set("Output Stream", _output);
  solverParametersPtr->sublist("Printing").set("Error Stream", _output);
}
/**
 *  \brief copy solution from solver to the algLoopSolution
 *
 *  \param [in] solver solver
 *  \param [out] algLoopSolution writes solution of solver into algebraic loop
 *  \return Return_Description
 *
 *  \details Details
 */
void Nox::copySolution(const Teuchos::RCP<const NOX::Solver::Generic> solver,double* const algLoopSolution){
	const NOX::LAPACK::Vector& NoxSolution = dynamic_cast<const NOX::LAPACK::Vector&>((dynamic_cast<const NOX::LAPACK::Group&>(solver->getSolutionGroup())).getX());
	for (int i=0;i<_dimSys;i++){
		if (_useDomainScaling){
			algLoopSolution[i]=NoxSolution(i)/_yScale[i];
		}else{
			algLoopSolution[i]=NoxSolution(i);
		}
	}
}

/** @} */ // end of solverNox
