/**
 *  \file Nox.cpp
 *  \brief Brief
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

/**
 *  \brief Brief
 *
 *  \param [in] algLoop Parameter_Description
 *  \param [in] settings Parameter_Description
 *  \return Return_Description
 *
 *  \details Details
 */
Nox::Nox(INonLinearAlgLoop* algLoop, INonLinSolverSettings* settings)
	: _algLoop            (algLoop)
	, _noxSettings        ((INonLinSolverSettings*)settings)
	, _iterationStatus    (CONTINUE)
	, _y                  (NULL)
	, _y0                 (NULL)
	, _y_old              (NULL)
	, _y_new              (NULL)
	, _yScale             (NULL)
  , _helpArray          (NULL)
	, _firstCall		  (true)
	, _generateoutput     (false)
	, _useDomainScaling         (false)
	, _currentIterate             (NULL)
	, _dimSys (_algLoop->getDimReal())
  , _lc(LC_NLS)
  , _SimTimeOld  (0.0)
  , _SimTimeNew  (0.0)
{

}
/**
 *  \brief Brief
 *
 *  \return Return_Description
 *
 *  \details Details
 */
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
 *  \brief Brief
 *
 *  \return Return_Description
 *
 *  \details Details
 */
void Nox::initialize()
{
	if (_generateoutput) std::cout << "starting init" << std::endl;
	_firstCall = false;
	_algLoop->initialize();//this sets values in the real variable


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
	if (_useDomainScaling){
		_algLoop->getNominalReal(_yScale);
		for (int i=0; i<_dimSys; i++){
			if(_yScale[i] != 0)
				_yScale[i] = 1/_yScale[i];
			else
				_yScale[i] = 1;
		}
	}


	// Set up the status tests
  _statusTestNormF = Teuchos::rcp(new NOX::StatusTest::NormF(1.0e-13));
  _statusTestMaxIters = Teuchos::rcp(new NOX::StatusTest::MaxIters(100));
  _statusTestStagnation = Teuchos::rcp(new NOX::StatusTest::Stagnation(15,0.99));
  _statusTestDivergence = Teuchos::rcp(new NOX::StatusTest::Divergence(1.0e13));
  //_statusTestSgnChange = Teuchos::rcp(new NOX::StatusTest::SgnChange(5.0e-7));

	_statusTestsCombo = Teuchos::rcp(new NOX::StatusTest::Combo(NOX::StatusTest::Combo::OR, _statusTestNormF, _statusTestMaxIters));
	_statusTestsCombo->addStatusTest(_statusTestStagnation);
	_statusTestsCombo->addStatusTest(_statusTestDivergence);

	if (_generateoutput) std::cout << "ending init" << std::endl;
}
/**
 *  \brief Brief
 *
 *  \return Return_Description
 *
 *  \details Details
 */
void Nox::solve()
{
  if (_generateoutput) std::cout << "start solving" << std::endl;
	int iter=-1; //Iterationcount of proper methods
	NOX::StatusTest::StatusType status;
	bool handleddivisionbyzeroerror=false;
  _OutOfProperMethods=false;
  _eventRetry=false;

  LOGGER_WRITE_BEGIN("Nox: start solving " + to_string(_algLoop->getEquationIndex()) + " at Simulation time " + to_string(_algLoop->getSimTime()), _lc, LL_DEBUG);

  //setup solver
  if (_firstCall)
    initialize();

	// Create the list of solver parameters. For detailed calibration, check https://trilinos.org/docs/dev/packages/nox/doc/html/parameters.html
  _solverParametersPtr = Teuchos::rcp(new Teuchos::ParameterList);
  _solverParametersPtr->set("Nonlinear Solver", "Line Search Based");
	//_solverParametersPtr->sublist("Line Search").set("Method", "Full Step");
	addPrintingList(_solverParametersPtr);

  if (_generateoutput) std::cout << "Does NoxLapackInterface induce this error?" << std::endl;
	_noxLapackInterface = Teuchos::rcp(new NoxLapackInterface (_algLoop));//this also gets the nominal values

	_iterationStatus=CONTINUE;

  if (_generateoutput) std::cout << "solver init done" << std::endl;

  //try extrapolating initial guess. Up to now, y0=y_new. Now we want that (y0,_algLoop->getSimTime()),(y_new,_SimTimeNew),(y_old,_SimTimeOld) form a line.
  //This is equivalent to the formula y0=y_new+(y_new-y_old)*(_algLoop->getSimTime()-_SimTimeNew)/(_SimTimeNew-_SimTimeOld)
  //Do this only iff _algLoop->getSimTime(),_SimTimeNew are not equal to _SimTimeOld

  //set y0. Maybe this should be rather done in the step completed function.

  if((_SimTimeOld!=_SimTimeNew)){
    //store times temporarily for lambda expression
    double SimTimeCurrent = _algLoop->getSimTime();
    double SimTimeNew = _SimTimeNew;
    double SimTimeOld = _SimTimeOld;
    std::transform(_y_old,_y_old+_dimSys,_y_new,_y0,[&SimTimeNew,&SimTimeOld,&SimTimeCurrent](const double &a,const double &b)->double{return b+(b-a)*(SimTimeCurrent-SimTimeNew)/(SimTimeNew-SimTimeOld);});
    if(_generateoutput){
      std::cout << "Using extrapolated values for y0:" << std::endl;
      std::cout << "SimTime =" << _algLoop->getSimTime() << "=" << SimTimeCurrent << std::endl;
      std::cout << "y0=";
      std::for_each(_y0,_y0+_dimSys,[](const double a){std::cout << a << " ";});
      std::cout << std::endl;
      std::cout << "SimTimeNew =" << _SimTimeNew << "=" << SimTimeNew << std::endl;
      std::cout << "yNew=";
      std::for_each(_y_new,_y_new+_dimSys,[](const double a){std::cout << a << " ";});
      std::cout << std::endl;
      std::cout << "SimTimeOld =" << _SimTimeOld << "=" << SimTimeOld << std::endl;
      std::cout << "yOld=";
      std::for_each(_y_old,_y_old+_dimSys,[](const double a){std::cout << a << " ";});
      std::cout << std::endl;
    }
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
      std::cout << "failed when evaluating algloop for the first time with error message: " << ex.what() << std::endl;
			throw;
		}
	}

  if (_generateoutput) std::cout << "handleddivisionbyzeroerror" << std::endl;

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

    if (_generateoutput) std::cout << "solving..." << std::endl;

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

    if (_generateoutput) std::cout << "solving done" << std::endl;

		if (status==NOX::StatusTest::Converged){
      _algLoop->setReal(_y);
      _algLoop->evaluate();
			_iterationStatus=DONE;
		}else{

      bool EvalAfterSolveFailed=false;

      _algLoop->setReal(_y);
      try{
        _algLoop->evaluate();
			}catch(const std::exception & ex){
        EvalAfterSolveFailed=true;
        if (_generateoutput) std::cout << "EvalAfterSolveFailed" << std::endl;
      }
      //&& is important here, since CheckWhetherSolutionIsNearby(_y) throws an error if EvalAfterSolveFailed=true.
      if((!EvalAfterSolveFailed) && (CheckWhetherSolutionIsNearby(_y))){
          _algLoop->setReal(_y);
          _algLoop->evaluate();
          _iterationStatus=DONE;
      }else{
        check4EventRetry(_y);
        if ((iter==0) || (iter==1)) iter = 2;
        modifySolverParameters(_solverParametersPtr,iter);
      }
		}
	}

  //try homotopy
  int numberofhomotopytries = 0;
  while((_iterationStatus==CONTINUE) && (numberofhomotopytries<_noxLapackInterface->getMaxNumberOfHomotopyTries()) && !_eventRetry){
    if (_generateoutput) std::cout << "Solving with Homotopy at numberofhomotopytries = " << numberofhomotopytries << std::endl;
    try{
      LocaHomotopySolve(numberofhomotopytries);
    }
    catch(const std::exception &e){
      std::string errorstring(e.what());
      if ((_generateoutput)) std::cout << "Solving with Homotopy failed with error message " + errorstring << " at numberofhomotopytries = " << numberofhomotopytries << std::endl;
    }
    numberofhomotopytries++;
  }

  //try varying initial guess

  //try setting initial guess to nominal values
  if((_iterationStatus==CONTINUE) && (!_eventRetry)){
    _algLoop->getNominalReal(_y);
    std::cout << "Trying to solve with nominal values given by ";
    for (int i=0;i<_dimSys;i++){
      std::cout << _y[i] << " ";
    }
    std::cout << std::endl;

    _algLoop->setReal(_y);
    if(BasicNLSsolve()==NOX::StatusTest::Converged){
      _iterationStatus=DONE;
    }else{
      bool EvalAfterSolveFailed2=false;
      _algLoop->setReal(_y);
      try{
        _algLoop->evaluate();
			}catch(const std::exception & ex){
        EvalAfterSolveFailed2=true;
        std::cout << "EvalAfterSolveFailed2" << std::endl;
      }
      //&& is important here, since CheckWhetherSolutionIsNearby(_y) throws an error if EvalAfterSolveFailed=true.
      if((!EvalAfterSolveFailed2) && (CheckWhetherSolutionIsNearby(_y))){
        _algLoop->setReal(_y);
        _algLoop->evaluate();
        _iterationStatus=DONE;
      }
    }
  }

  //no extrapolation of the initial guess

  if((_iterationStatus==CONTINUE) && (!_eventRetry)){
    memcpy(_y,_y_new,_dimSys*sizeof(double));
    std::cout << "Trying to solve without extrapolated values:";
    for (int i=0;i<_dimSys;i++){
      std::cout << _y[i] << " ";
    }
    std::cout << std::endl;

    _algLoop->setReal(_y);
    if(BasicNLSsolve()==NOX::StatusTest::Converged){
      _iterationStatus=DONE;
    }else{
      bool EvalAfterSolveFailed2=false;
      _algLoop->setReal(_y);
      try{
        _algLoop->evaluate();
			}catch(const std::exception & ex){
        EvalAfterSolveFailed2=true;
        std::cout << "EvalAfterSolveFailed2" << std::endl;
      }
      //&& is important here, since CheckWhetherSolutionIsNearby(_y) throws an error if EvalAfterSolveFailed=true.
      if((!EvalAfterSolveFailed2) && (CheckWhetherSolutionIsNearby(_y))){
        _algLoop->setReal(_y);
        _algLoop->evaluate();
        _iterationStatus=DONE;
      }
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
      bool EvalAfterSolveFailed3=false;
      _algLoop->setReal(_y);
      try{
        _algLoop->evaluate();
			}catch(const std::exception & ex){
        EvalAfterSolveFailed3=true;
        std::cout << "EvalAfterSolveFailed3" << std::endl;
      }
      //&& is important here, since CheckWhetherSolutionIsNearby(_y) throws an error if EvalAfterSolveFailed=true.
      if((!EvalAfterSolveFailed3) && (CheckWhetherSolutionIsNearby(_y))){
          _algLoop->setReal(_y);
          _algLoop->evaluate();
          _iterationStatus=DONE;
      }
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
IAlgLoopSolver::ITERATIONSTATUS Nox::getIterationStatus()
{
	return _iterationStatus;
}

void Nox::stepCompleted(double time)
{
	memcpy(_y0,_y,_dimSys*sizeof(double));
  memcpy(_y_old,_y_new,_dimSys*sizeof(double));
  memcpy(_y_new,_y,_dimSys*sizeof(double));
  if (time == _algLoop->getSimTime()){
    _SimTimeOld = _SimTimeNew;
    _SimTimeNew = _algLoop->getSimTime();
  }else{
    if(_generateoutput) std::cout << "time=" << time << ", algLoop->getSimTime()=" << _algLoop->getSimTime() << std::endl;
  }
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

void Nox::check4EventRetry(double* y)
{
	_algLoop->setReal(y);
	if(!(_algLoop->isConsistent()) && !_eventRetry)
	{
		memcpy(_helpArray, y,_dimSys*sizeof(double));
		_eventRetry = true;
	}
}
/**
 *  \brief Brief
 *
 *  \param [in] numberofhomotopytries Parameter_Description
 *  \return Return_Description
 *
 *  \details Details
 */
void Nox::LocaHomotopySolve(const int numberofhomotopytries)
{
	if((_generateoutput)) std::cout << "We are going to solve algloop " << _algLoop->getEquationIndex() << "using homotopy with numberofhomotopytries=" << numberofhomotopytries << std::endl;

	// Reset initial guess
	memcpy(_y,_y0,_dimSys*sizeof(double));
	_algLoop->setReal(_y);

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
  if (_generateoutput){
		nlPrintParams.set("Output Information", NOX::Utils::Details + NOX::Utils::OuterIteration + NOX::Utils::Warning + NOX::Utils::StepperIteration + NOX::Utils::StepperDetails + NOX::Utils::StepperParameters);  // Should set
	}else{
		nlPrintParams.set("Output Information", NOX::Utils::Error); // Should set
	}

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

	// Create the stepper
	LOCA::Stepper stepper(globalData, grp, _statusTestsCombo, paramList);

	try{
		// Perform continuation run
		LOCA::Abstract::Iterator::IteratorStatus status = stepper.run();
		printLogger();
		// Check for convergence
		if (status != LOCA::Abstract::Iterator::Finished){
			if((_generateoutput)) std::cout << "Stepper failed to converge!" << std::endl;
		}else{
       if((_generateoutput)) std::cout << "Stepper was successful!" << std::endl;
			_iterationStatus=DONE;
		}
	}
	catch(const std::exception &ex)
	{
		if(_generateoutput) std::cout << std::endl << "sth went wrong during stepper running, with error message" << ex.what() << std::endl;
		//std::cout << add_error_info("building solver with grp, status tests and solverparameters", ex.what(), ex.getErrorID(), time) << std::endl << std::endl;
		throw ModelicaSimulationError(ALGLOOP_SOLVER,"solving error");
	}

	if (_generateoutput) std::cout << "finishing solve!" << std::endl;

  if(_iterationStatus==DONE){
    // Get the final solution from the stepper
    Teuchos::RCP<const LOCA::LAPACK::Group> finalGroup = Teuchos::rcp_dynamic_cast<const LOCA::LAPACK::Group>(stepper.getSolutionGroup());
    const NOX::LAPACK::Vector& finalSolution = dynamic_cast<const NOX::LAPACK::Vector&>(finalGroup->getX());

    if(_generateoutput){
      // Print final solution
      std::cout << std::endl << "Final solution is " << std::endl;
      finalGroup->printSolution(finalSolution, finalGroup->getParam("lambda"));//does not work
    }

      LOCA::destroyGlobalData(globalData);

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
      if (_generateoutput) std::cout << "algloop evaluation after solve failed with error message:" << std::endl << ex.what() << std::endl << "Trying to continue without. This should hopefully lead to statusTest::Failed." << std::endl;
    }

    if (_generateoutput) {
      double * rhs = new double[_dimSys];
      double sum;
      sum=0.0;
      _algLoop->getRHS(rhs);
      for (int i=0;i<_dimSys;i++) sum+=rhs[i]*rhs[i];

      std::cout << "solutionvector=(";
      for (int i=0;i<_dimSys;i++) std::cout << std::setprecision (std::numeric_limits<double>::digits10 + 8) << _y[i] << " ";
      std::cout << ")" << std::setprecision (6) << std::endl;
      std::cout << "rhs =(";
      for (int i=0;i<_dimSys;i++) std::cout << rhs[i] << " ";
      std::cout << ")" << std::endl;
      std::cout << "squared norm of f = " << sum << std::endl;

      std::cout << "simtime=" << std::setprecision (std::numeric_limits<double>::digits10 + 1) << _algLoop->getSimTime() << std::endl;
      if (rhs) delete rhs;

      std::cout << "ending solve" << std::endl;
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
		throw ModelicaSimulationError(ALGLOOP_SOLVER,"solving error in Algloop " + std::to_string(_algLoop->getEquationIndex()) + " at simtime " + std::to_string(_algLoop->getSimTime()) + ", with error message: " + ex.what());
	}
  return status;
}
/**
 *  \brief Brief
 *
 *  \param [in] solverParametersPtr Parameter_Description
 *  \param [in] iter Parameter_Description
 *  \return Return_Description
 *
 *  \details Details
 */
void Nox::modifySolverParameters(const Teuchos::RCP<Teuchos::ParameterList> solverParametersPtr,const int iter){

	switch (iter){
	case 0:
		break;
		//default Nox Line Search failed -> Try damped Newton instead
	case 1://should delete this. It typically does not help (verify this))
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
 *  \brief Brief
 *
 *  \param [in] y Parameter_Description
 *  \return Return_Description
 *
 *  \details Details
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
/**
 *  \brief Brief
 *
 *  \param [in] ex Parameter_Description
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
 *  \brief Brief
 *
 *  \param [in] y0 Parameter_Description
 *  \return Return_Description
 *
 *  \details Details
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
			std::cout << "Could not find a good initial guess with a root nearby:(" << std::endl;
			throw;
		}

		//converts initialguessdividebyzerofailurecounter into its binary representation and store it in startvaluemodifier
		for(int i=0;i<_dimSys;i++)
		{
			startvaluemodifier[i]=static_cast<int>(initialguessdividebyzerofailurecounter/std::floor(std::pow(2.0,static_cast<double>(i))))%2;
			if (startvaluemodifier[i]==0) startvaluemodifier[i]=-1;
		}

		if(_generateoutput){
			std::cout << "initialguessdividebyzerofailurecounter =" << initialguessdividebyzerofailurecounter << std::endl;
			std::cout << "startvaluemodifier =" << std::endl;
			for (int i=0;i<_dimSys;i++){
				std::cout << " " << startvaluemodifier[i];
			}
			std::cout << std::endl;
		}

		initialguessdividebyzerofailurecounter++;

    if(_generateoutput)
      std::cout << "Varying initial guess by 10%:" << std::endl;
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
					std::cout << "still dividing by zero, trying new initial guess." << std::endl;
				}else{
          std::cout << "eval after solve failed when trying to fix division by zero error." << std::endl;
					throw;
				}
			}
		}
	}
}
/**
 *  \brief Brief
 *
 *  \param [in] result Parameter_Description
 *  \param [in] number Parameter_Description
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
 *  \brief Brief
 *
 *  \param [in] counter Parameter_Description
 *  \return Return_Description
 *
 *  \details Details
 */
bool Nox::modify_y(const int counter){
	std::vector<double> startvaluemodifier(_dimSys);

	memcpy(_y,_y0,_dimSys*sizeof(double));

  BinRep(startvaluemodifier,counter);

  //replace 0 by -1.
  std::for_each(startvaluemodifier.begin(),startvaluemodifier.end(), [](double d){return (d==0.0) ? -1.0 : d;});

  std::cout << "Varying initial guess by 10%:" << std::endl;
	for (int i=0;i<_dimSys;i++){
    _y[i] += (_y[i]!=0.0) ? 0.1*_y[i]*startvaluemodifier[i] : 0.1*startvaluemodifier[i];
	}

	_algLoop->setReal(_y);
	try{
		_algLoop->evaluate();
    return true;
	}
	catch(const std::exception &ex){
		std::cout << ex.what() << " Error occured when varying initial guess." << std::endl;
	}
  return false;
}

//writes output
/**
 *  \brief Brief
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


//sets printing list in solverParametersPtr
/**
 *  \brief Brief
 *
 *  \param [in] solverParametersPtr Parameter_Description
 *  \return Return_Description
 *
 *  \details Details
 */
void Nox::addPrintingList(const Teuchos::RCP<Teuchos::ParameterList> solverParametersPtr){
  solverParametersPtr->sublist("Printing").set("Output Precision", 15);
  solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error + NOX::Utils::Warning + NOX::Utils::OuterIteration + NOX::Utils::InnerIteration);
  if(!_generateoutput){
    solverParametersPtr->sublist("Printing").set("Output Stream", _output);
    solverParametersPtr->sublist("Printing").set("Error Stream", _output);
  }
}
/**
 *  \brief Brief
 *
 *  \param [in] solver Parameter_Description
 *  \param [in] algLoopSolution Parameter_Description
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
