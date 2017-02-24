#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/Nox/FactoryExport.h>


#include <Solver/Nox/NoxLapackInterface.h>
#include "Teuchos_StandardCatchMacros.hpp"

#include <Core/Utils/extension/logger.hpp>
#include <Solver/Nox/Nox.h>
#include <Solver/Nox/NoxSettings.h>

#include <Core/Utils/numeric/bindings/ublas.hpp>
#include <Core/Utils/numeric/utils.h>


#include <iostream>


Nox::Nox(INonLinearAlgLoop* algLoop, INonLinSolverSettings* settings)
	: _algLoop            (algLoop)
	, _noxSettings        ((INonLinSolverSettings*)settings)
	, _iterationStatus    (CONTINUE)
	, _y                  (NULL)
	, _y0                 (NULL)
	, _y_old              (NULL)
	, _y_new              (NULL)
	, _yScale             (NULL)
	, _firstCall		  (true)
	, _generateoutput     (false)
	, _useDomainScaling         (false)
{
	_dimSys=_algLoop->getDimReal();
}

Nox::~Nox()
{
	if(_y)                  delete []  _y;
	if(_y0)                 delete []  _y0;
    if(_y_old)              delete [] _y_old;
    if(_y_new)              delete [] _y_new;
    if(_yScale)              delete [] _yScale;
    //if(_noxLapackInterface) delete _noxLapackInterface;

}

void Nox::initialize()
{
	if (_generateoutput) std::cout << "starting init" << std::endl;
	_firstCall = false;
	_algLoop->initialize();
	if(_y) delete [] _y;
	if(_y0) delete [] _y0;
	if(_y_old) delete [] _y_old;
	if(_y_new) delete [] _y_new;
    if(_yScale) delete [] _yScale;


	_y                = new double[_dimSys];
	_y0               = new double[_dimSys];
	_y_old            = new double[_dimSys];
	_y_new            = new double[_dimSys];
	_yScale            = new double[_dimSys];

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

	if (_generateoutput) std::cout << "ending init" << std::endl;
}


void Nox::solve()
{
	if (_generateoutput) std::cout << "starting solving algloop " << _algLoop->getEquationIndex() << std::endl;

	int iter=-1; //Iterationcount
	NOX::StatusTest::StatusType status;
	NOX::LAPACK::Vector Lapacksolution;//temporary variable used to convert the solution from NOX::LAPACK::Vector to a double array.
	double * rhs = new double[_dimSys];
	double sum;



    if (_firstCall) initialize();

	// Set up the status tests
    _statusTestNormF = Teuchos::rcp(new NOX::StatusTest::NormF(1.0e-13));
    _statusTestMaxIters = Teuchos::rcp(new NOX::StatusTest::MaxIters(100));
    _statusTestStagnation = Teuchos::rcp(new NOX::StatusTest::Stagnation(15,0.99));
    _statusTestDivergence = Teuchos::rcp(new NOX::StatusTest::Divergence(1.0e13));

	_statusTestsCombo = Teuchos::rcp(new NOX::StatusTest::Combo(NOX::StatusTest::Combo::OR, _statusTestNormF, _statusTestMaxIters));
	_statusTestsCombo->addStatusTest(_statusTestStagnation);
	_statusTestsCombo->addStatusTest(_statusTestDivergence);

	// Create the list of solver parameters
    _solverParametersPtr = Teuchos::rcp(new Teuchos::ParameterList);
	//resetting method to default (Line Search). For detailed calibration, check https://trilinos.org/docs/dev/packages/nox/doc/html/parameters.html
    _solverParametersPtr->set("Nonlinear Solver", "Line Search Based");

	_solverParametersPtr->sublist("Printing").set("Output Precision", 15);

	//_solverParametersPtr->sublist("Direction").set("Method", "Steepest Descent");

	//resetting Line search method to default (Full Step, ie. Standard Newton with lambda=1)
	_solverParametersPtr->sublist("Line Search").set("Method", "Backtrack");
	// Set the level of output
    if (_generateoutput){
		_solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error + NOX::Utils::Warning + NOX::Utils::OuterIteration + NOX::Utils::Details + NOX::Utils::Debug); //(there are also more options, but error and outer iteration are the ones that I commonly use.
	}else{
		_solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error);
	}
	_solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error + NOX::Utils::Warning + NOX::Utils::OuterIteration + NOX::Utils::InnerIteration + NOX::Utils::Details + NOX::Utils::Debug); //(there are also more options, but error and outer iteration are the ones that I commonly use.


	if (_generateoutput) std::cout << "creating noxLapackInterface" << std::endl;

	_noxLapackInterface = Teuchos::rcp(new NoxLapackInterface (_algLoop,-1));//this also gets the nominal values



	_iterationStatus=CONTINUE;

	if (_generateoutput) std::cout << "starting while loop" << std::endl;

	while(_iterationStatus==CONTINUE){
		iter++;

		if ((false && (iter != 1))){
			std::cout << "Entering next iteration of while loop" << std::endl;
			_solverParametersPtr->print();
			std::cout << std::endl;
		}

		// Reset initial guess
		memcpy(_y,_y0,_dimSys*sizeof(double));
		_algLoop->setReal(_y);

		if ((false && (iter != 1))){
			std::cout << "building grp" << std::endl;
			_solverParametersPtr->print();
			std::cout << std::endl;
		}

		try{
			_grp = Teuchos::rcp(new NOX::LAPACK::Group(*_noxLapackInterface));//this also calls the getInitialGuess-function in the NoxLapackInterface and sets the initial guess in the NOX::LAPACK::Group
		}
		catch(const std::exception &ex)
		{
			std::string divbyzero = "Division by zero";
			std::string errorstring(ex.what());
			//we only do the error handling by variation of initial guess in case of division by zero at evaluation of initial guess
			if(errorstring.find(divbyzero)!=std::string::npos){
				//some magic

				//alle Richtungen durchzuprobieren ist doof, denn das kann ich nur durch 2^_dimSys Aufrufe von der Lösungsroutine beschränken. Allerdings besteht Grund zur Hoffnung, dass es relativ schnell gelöst wird.
				//Dann sollte ich allerdings nicht mehr allzu viele Methoden durchprobieren, ie. einfach Linesearch und das wars.
				//Oder ich versuche herauszufinden, welche Koordinaten die Division durch Null hervorrufen. Heuristisch sind das die Koordinaten, die sowieso schon Null sind.
				//anstatt vectors von arrays kann ich auch einfach mehrere vectors erstellen. Oder halt gleich eine Matrix mit Zweifachzeigern.

				//iterate through all possibilities.
				//bool triednew_yindirection p = true;
				//algLoop->setReal(new_y);
				//try{_algLoop->evaluate}
				//_grp = ...
				//simplelinesearchsolve(_grp);

				NOX::StatusTest::StatusType stat = NOX::StatusTest::Unevaluated;
				int initialguessdividebyzerofailurecounter = 0;

				while((stat!=NOX::StatusTest::Converged)){
					bool detecteddivisionbyzero=true;
					double* startvaluemodifier=new double[_dimSys];

					memcpy(_y,_y0,_dimSys*sizeof(double));
					_algLoop->setReal(_y);

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

					std::cout << "initialguessdividebyzerofailurecounter =" << initialguessdividebyzerofailurecounter << std::endl;
					std::cout << "startvaluemodifier =" << std::endl;
					for (int i=0;i<_dimSys;i++){
						std::cout << " " << startvaluemodifier[i];
					}
					std::cout << std::endl;


					initialguessdividebyzerofailurecounter++;

					std::cout << "Varying initial guess by 10%:" << std::endl;
					for (int i=0;i<_dimSys;i++){
						if(_y[i]!=0.0){
							_y[i]+=0.1*_y[i]*startvaluemodifier[i];
						}else{
							_y[i]=0.1*startvaluemodifier[i];
						}
					}
					delete [] startvaluemodifier;

					_algLoop->setReal(_y);
					while(detecteddivisionbyzero){
						try{
							_algLoop->evaluate();
							detecteddivisionbyzero=false;
							stat = BasicNLSsolve();
						}
						catch(const std::exception &e){
							std::string error(e.what());
							if(errorstring.find(divbyzero)!=std::string::npos){
								std::cout << "still dividing by zero, trying new initial guess." << std::endl;
							}else{
								throw;
							}
						}
					}
				}
				break;
			}else{
				throw;
			}
		}

		if ((false && (iter != 1))){
			std::cout << "grp built" << std::endl;
			_solverParametersPtr->print();
			std::cout << std::endl;
		}

		if (_generateoutput) std::cout << "building solver" << std::endl;



		try{
			//std::cout << "building solver..." << std::endl;
		// Create the solver
		_solver = NOX::Solver::buildSolver(_grp, _statusTestsCombo, _solverParametersPtr);
			//std::cout << "done!" << std::endl;
		}
		catch(const std::exception &ex)
		{
			std::cout << std::endl << "sth went wrong during solver building, with error message" << ex.what() << std::endl;
			std::cout << "the group is given by" << std::endl;
			_grp->print();
			std::cout << "the status test is given by" << std::endl;
			_statusTestsCombo->print(std::cout);
			std::cout << "the solver parameters are given by" << std::endl;
			_solverParametersPtr->print();
			//std::cout << add_error_info("building solver with grp, status tests and solverparameters", ex.what(), ex.getErrorID(), time) << std::endl << std::endl;
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"solver building error");
		}


		if (_generateoutput) {
			double* rhsssss = new double[_dimSys];//stores f(x)
			double* xp = new double[_dimSys];//stores x temporarily
			_algLoop->getReal(xp);
			_algLoop->getRHS(rhsssss);
			std::cout << "we are at position x=(";
			for (int i=0;i<_dimSys;i++){
				std::cout << xp[i] << " ";
			}
			std::cout << ")" << std::endl;
			std::cout << "the right hand side is given by (";
			for (int i=0;i<_dimSys;i++){
				std::cout << rhsssss[i] << " ";
			}
			std::cout << ")" << std::endl;
			std::cout << std::endl;
			delete [] rhsssss;
			delete [] xp;

			std::cout << "solving..." << std::endl;
		}

		if (false && (iter != 1)){
			std::cout << "we are solving with the following options:" <<std::endl;
			_solverParametersPtr->print();
			std::cout << std::endl;
		}


		try{
			//std::cout << "solving..." << std::endl;
			status = _solver->solve();
			//std::cout << "done!" << std::endl;
		}
		catch(const std::exception &ex)
		{
			std::cout << std::endl << "sth went wrong during solving, with error message" << ex.what() << std::endl;
			//std::cout << add_error_info("building solver with grp, status tests and solverparameters", ex.what(), ex.getErrorID(), time) << std::endl << std::endl;
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"solving error");
		}

		if (_generateoutput) std::cout << "finishing solve!" << std::endl;

		// Get the answer
		NOX::LAPACK::Group solnGrp = dynamic_cast<const NOX::LAPACK::Group&>(_solver->getSolutionGroup());
		Lapacksolution=dynamic_cast<const NOX::LAPACK::Vector&>(solnGrp.getX());

		for (int i=0;i<_dimSys;i++){
			if (_useDomainScaling){
				_y[i]=Lapacksolution(i)/_yScale[i];
			}else{
				_y[i]=Lapacksolution(i);
			}
		}

		int numberofdifferentnormtests=5;//this variable is used twice.

		_algLoop->setReal(_y);
		_algLoop->evaluate();

		if (_generateoutput) {
			std::cout << "solutionvector=(";
			for (int i=0;i<_dimSys;i++) std::cout << _y[i] << " ";
			std::cout << ")" << std::endl;
		}

		sum=0.0;
		_algLoop->getRHS(rhs);
		for (int i=0;i<_dimSys;i++) sum+=rhs[i]*rhs[i];


		if (status==NOX::StatusTest::Converged){
			//this safeguard check fails since function value scaling was implemented.
			//if (sum>1.0e-6) std::cout << "something is not right with the solver. sum=" << sum << std::endl;
			if (_generateoutput) std::cout << "simtime=" << _algLoop->getSimTime() << std::endl;
			_iterationStatus=DONE;
		}else{
			//skip iter=1,2,4,6,7,9,11,12,13

			if (iter==11){
				iter = 14;
			}
			if (iter==9){
				iter = 10;
			}
			if (iter==6){
				iter = 8;
			}
			if (iter==4){
				iter = 5;
			}
			if (iter==0){
				iter = 3;
			}
			if ((iter == 1) || (iter == 2) || (iter == 4) || (iter == 6) || (iter == 7) || (iter == 9)){
				std::cout << "You failed heavily at iter = " << iter << " and simtime " << _algLoop->getSimTime() << std::endl;
			}

			switch(iter%(numberofdifferentnormtests)){
				case 0:
				*_statusTestNormF=NOX::StatusTest::NormF(1.0e-13);
				break;
				case 1:
				*_statusTestNormF=NOX::StatusTest::NormF(1.0e-11);
				break;
				case 2:
				*_statusTestNormF=NOX::StatusTest::NormF(1.0e-9);
				break;
				case 3:
				*_statusTestNormF=NOX::StatusTest::NormF(1.0e-7);
				break;
				default:
				*_statusTestNormF=NOX::StatusTest::NormF(1.0e-5);
				break;
			}
			_statusTestsCombo = Teuchos::rcp(new NOX::StatusTest::Combo(NOX::StatusTest::Combo::OR, _statusTestNormF, _statusTestMaxIters));
			_statusTestsCombo->addStatusTest(_statusTestStagnation);
			_statusTestsCombo->addStatusTest(_statusTestDivergence);

			switch (iter/numberofdifferentnormtests){
			case 0:
				break;
				//default Nox Line Search failed -> Try damped Newton instead
			case 1:
				_solverParametersPtr->sublist("Line Search").sublist("Full Step").set("Full Step", 0.5);

				//default Nox Line Search failed -> Try Backtracking instead
			case 2:
				_solverParametersPtr->sublist("Line Search").set("Method", "Backtrack");
				_solverParametersPtr->sublist("Line Search").sublist("Backtrack").set("Default Step", 1024.0*1024.0);
				_solverParametersPtr->sublist("Line Search").sublist("Backtrack").set("Minimum Step", 1.0e-30);
				_solverParametersPtr->sublist("Line Search").sublist("Backtrack").set("Recovery Step", 0.0);
				//std::cout << "we just set the solver parameters to use backtrack. the currently used options are:" << std::endl;
				//_solverParametersPtr->print();
				//std::cout << std::endl;
				break;

				//Backtracking failed -> Try Polynomial with various parameters instead
			case 3:
				_solverParametersPtr->sublist("Line Search").set("Method", "Polynomial");
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Minimum Step", 1.0e-30);
				//_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Alpha Factor", 1.0e-2);
				break;

			case 4:
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic");
				break;

			case 5:
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic3");
				break;

			case 6:
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Sufficient Decrease Condition", "Ared/Pred");
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Cubic");
				break;

			case 7:
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic");
				break;

			case 8:
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic3");
				break;

				//Polynomial failed -> Try More'-Thuente instead
			case 9:
				_solverParametersPtr->sublist("Line Search").set("Method", "More'-Thuente");
				//_solverParametersPtr->sublist("Line Search").sublist("More'-Thuente").set("Sufficient Decrease", 1.0e-2);
				break;

				//More'-Thuente failed -> Try Trust Region instead
			case 10:
				//_solverParametersPtr->sublist("Line Search").remove("Method", true);
				_solverParametersPtr->set("Nonlinear Solver", "Trust Region Based");
				_solverParametersPtr->sublist("Trust Region").set("Minimum Improvement Ratio", 1.0e-4);
				_solverParametersPtr->sublist("Trust Region").set("Minimum Trust Region Radius", 1.0e-6);
				break;

				//Trust Region failed -> Try Inexact Trust Region instead
			case 11:
				//_solverParametersPtr->sublist("Trust Region").set("Use Dogleg Segment Minimization", true);
				_solverParametersPtr->set("Nonlinear Solver", "Inexact Trust Region Based");
				break;

				//Inexact Trust Region failed -> Try Tensor instead
			//case 11:
				//_solverParametersPtr->set("Nonlinear Solver", "Tensor Based");
				//break;

				//Tensor failed or other failure
			default:
				int numberofhomotopytries = 0;
				while((_iterationStatus!=DONE)){
					//todo: This is implemented in the worst way possible. Please fix this.
					//try homotopy
					try{
						if (_generateoutput) std::cout << "solving with numberofhomotopytries = " << numberofhomotopytries << std::endl;
						LocaHomotopySolve(numberofhomotopytries);
					}
					catch(const std::exception &e){
						std::string errorstring(e.what());
						_iterationStatus=SOLVERERROR;
						throw ModelicaSimulationError(ALGLOOP_SOLVER,"Nonlinear solver nox failed with error message " +errorstring);
					}
					numberofhomotopytries++;
				}
				break;
			}
			//comment in for debugging
			if (_generateoutput){
				std::cout << "solutionvector=(";
				for (int i=0;i<_dimSys;i++) std::cout << std::setprecision (std::numeric_limits<double>::digits10 + 8) << _y[i] << " ";
				std::cout << ")" << std::setprecision (6) << std::endl;
				std::cout << "rhs =(";
				for (int i=0;i<_dimSys;i++) std::cout << rhs[i] << " ";
				std::cout << ")" << std::endl;
				std::cout << "squared norm of f = " << sum << std::endl;

				std::cout << "simtime=" << std::setprecision (std::numeric_limits<double>::digits10 + 1) << _algLoop->getSimTime() << std::endl;
				std::cout << "Some error occured when solving algloop " << _algLoop->getEquationIndex() << ". Trying to solve with different method. iter=" << iter << std::endl;
				//_solverParametersPtr->print();
				//_solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error + NOX::Utils::Warning + NOX::Utils::OuterIteration + NOX::Utils::InnerIteration);
				//_solverParametersPtr->print();
			}

			if(_generateoutput){
				std::cout << "Solverparameters and StatusTest at iter " << iter << ", with simtime " << _algLoop->getSimTime() << std::endl;
				_solverParametersPtr->print();
				_statusTestsCombo->print(std::cout);
			}
		}
		if (false && (iter==1)&&(_iterationStatus==CONTINUE)){
			std::cout << "deleting _noxLapackInterface..." << std::endl;
			_solverParametersPtr->print();
			std::cout << std::endl;
		}


		if (false && (iter==1)&&(_iterationStatus==CONTINUE)){
			std::cout << "finishing an iteration of the while loop" << std::endl;
			_solverParametersPtr->print();
			std::cout << std::endl;
		}
	}
	//if (_noxLapackInterface) delete _noxLapackInterface;
	if (_generateoutput) std::cout << "ending solve" << std::endl;
	if (rhs) delete rhs;
}

IAlgLoopSolver::ITERATIONSTATUS Nox::getIterationStatus()
{
	return _iterationStatus;
}

void Nox::stepCompleted(double time)
{
	memcpy(_y0,_y,_dimSys*sizeof(double));
    memcpy(_y_old,_y_new,_dimSys*sizeof(double));
    memcpy(_y_new,_y,_dimSys*sizeof(double));
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

void Nox::LocaHomotopySolve(int numberofhomotopytries)
{
    if (_firstCall) initialize();

	if(_generateoutput) std::cout << "We are going to solve algloop " << _algLoop->getEquationIndex() << std::endl;

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
	stepperList.set("Max Nonlinear Iterations", 100); // Should set
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
	stepSizeList.set("Initial Step Size", 0.1);   // Should set
	stepSizeList.set("Min Step Size", 1.0e-3);    // Should set
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

	if (_generateoutput) std::cout << "creating noxLapackInterface" << std::endl;

	// Set up the problem interface
	Teuchos::RCP<NoxLapackInterface> LocaLapackInterface = Teuchos::rcp(new NoxLapackInterface (_algLoop, numberofhomotopytries));//this also gets the nominal values
	LOCA::ParameterVector p;
	p.addParameter("lambda",0.0);

	// Create a group which uses that problem interface. The group will
	// be initialized to contain the default initial guess for the
	// specified problem.
	Teuchos::RCP<LOCA::MultiContinuation::AbstractGroup> grp = Teuchos::rcp(new LOCA::LAPACK::Group(globalData, *LocaLapackInterface));
	grp->setParams(p);

	// Set up the status tests
    Teuchos::RCP<NOX::StatusTest::NormF> normF = Teuchos::rcp(new NOX::StatusTest::NormF(1.0e-4));
    Teuchos::RCP<NOX::StatusTest::MaxIters> maxIters = Teuchos::rcp(new NOX::StatusTest::MaxIters(100));
    Teuchos::RCP<NOX::StatusTest::Generic> comboOR = Teuchos::rcp(new NOX::StatusTest::Combo(NOX::StatusTest::Combo::OR, normF, maxIters));

	// Create the stepper
	LOCA::Stepper stepper(globalData, grp, comboOR, paramList);

	_iterationStatus=CONTINUE;

	try{
		// Perform continuation run
		LOCA::Abstract::Iterator::IteratorStatus status = stepper.run();
		// Check for convergence
		if (status != LOCA::Abstract::Iterator::Finished){
			std::cout << "Stepper failed to converge!" << std::endl;
		}else{
			_iterationStatus=DONE;
		}
	}
	catch(const std::exception &ex)
	{
		std::cout << std::endl << "sth went wrong during stepper running, with error message" << ex.what() << std::endl;
		//std::cout << add_error_info("building solver with grp, status tests and solverparameters", ex.what(), ex.getErrorID(), time) << std::endl << std::endl;
		throw ModelicaSimulationError(ALGLOOP_SOLVER,"solving error");
	}

	if (_generateoutput) std::cout << "finishing solve!" << std::endl;

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
	_algLoop->evaluate();

	if (_generateoutput) {
		std::cout << "solutionvector=(";
		for (int i=0;i<_dimSys;i++) std::cout << _y[i] << " ";
		std::cout << ")" << std::endl;

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

		std::cout << "Solverparamters and StatusTest at simtime " << _algLoop->getSimTime() << std::endl;
		paramList->print();
		_statusTestsCombo->print(std::cout);
		std::cout << "ending solve" << std::endl;
	}
}

NOX::StatusTest::StatusType Nox::BasicNLSsolve(){
	NOX::StatusTest::StatusType status = NOX::StatusTest::Unevaluated;
	try{
		Teuchos::RCP<NoxLapackInterface> noxlapackinterface=Teuchos::rcp(new NoxLapackInterface(_algLoop,-1));
		Teuchos::RCP<NOX::LAPACK::Group> grp=Teuchos::rcp(new NOX::LAPACK::Group(*noxlapackinterface));
		Teuchos::RCP<NOX::StatusTest::NormF> normf = Teuchos::rcp(new NOX::StatusTest::NormF(1.0e-13));
		Teuchos::RCP<NOX::StatusTest::MaxIters> maxiters = Teuchos::rcp(new NOX::StatusTest::MaxIters(50));
		Teuchos::RCP<NOX::StatusTest::Stagnation> stagnation = Teuchos::rcp(new NOX::StatusTest::Stagnation(15,0.99));
		Teuchos::RCP<NOX::StatusTest::Divergence> divergence = Teuchos::rcp(new NOX::StatusTest::Divergence(1.0e13));
		Teuchos::RCP<NOX::StatusTest::Combo> statusTestsCombo = Teuchos::rcp(new NOX::StatusTest::Combo(NOX::StatusTest::Combo::OR, normf, maxiters));
		statusTestsCombo->addStatusTest(_statusTestStagnation);
		statusTestsCombo->addStatusTest(_statusTestDivergence);
		Teuchos::RCP<Teuchos::ParameterList> solverParametersPtr = Teuchos::rcp(new Teuchos::ParameterList);
		solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error + NOX::Utils::OuterIteration);
		solverParametersPtr->sublist("Line Search").set("Method","Backtrack");
		solverParametersPtr->sublist("Line Search").sublist("Backtrack").set("Recovery Step", 0.0);
		Teuchos::RCP<NOX::Solver::Generic> solver = NOX::Solver::buildSolver(grp, statusTestsCombo, solverParametersPtr);
		status = solver->solve();/*
		if (status == NOX::StatusTest::Converged){
			_iterationStatus=DONE;
			NOX::LAPACK::Group solnGrp = dynamic_cast<const NOX::LAPACK::Group&>(solver->getSolutionGroup());
			//Teuchos::RCP<const LOCA::LAPACK::Group> finalGroup = Teuchos::rcp_dynamic_cast<const LOCA::LAPACK::Group>(stepper.getSolutionGroup());
			const NOX::LAPACK::Vector& finalSolution = dynamic_cast<const NOX::LAPACK::Vector&>(solnGrp.getX());
			for (int i=0;i<_dimSys;i++){
				if (_useDomainScaling){
					_y[i]=finalSolution(i)/_yScale[i];
				}else{
					_y[i]=finalSolution(i);
				}
			}
			_algLoop->setReal(_y);
			_algLoop->evaluate();
		}else{
			_iterationStatus=SOLVERERROR;
		}*/
		_iterationStatus=DONE;
		NOX::LAPACK::Group solnGrp = dynamic_cast<const NOX::LAPACK::Group&>(solver->getSolutionGroup());
		const NOX::LAPACK::Vector& finalSolution = dynamic_cast<const NOX::LAPACK::Vector&>(solnGrp.getX());

		std::cout << "final solution: " << std::endl;
		finalSolution.print(std::cout);

		if(status == NOX::StatusTest::Converged){
			for (int i=0;i<_dimSys;i++){
				if (_useDomainScaling){
					_y[i]=finalSolution(i)/_yScale[i];
				}else{
					_y[i]=finalSolution(i);
				}
			}
			_algLoop->setReal(_y);
			_algLoop->evaluate();
		}else{
			_iterationStatus=SOLVERERROR;
		}
	}
	catch(const std::exception &ex)
	{
		std::cout << "sth went wrong when solving AlgLoop " << _algLoop->getEquationIndex() << " at simtime " << _algLoop->getSimTime() << ", with error message:" << std::endl << ex.what() << std::endl;
		throw ModelicaSimulationError(ALGLOOP_SOLVER,"solving error");
	}
    return status;
}

NOX::StatusTest::StatusType Nox::secondBasicNLSsolve(){
	NOX::StatusTest::StatusType status;
	int iter = 0;
	if (_generateoutput) std::cout << "starting solving algloop " << _algLoop->getEquationIndex() << std::endl;

	if (_firstCall) initialize();

	_statusTestNormF = Teuchos::rcp(new NOX::StatusTest::NormF(1.0e-13));
    _statusTestMaxIters = Teuchos::rcp(new NOX::StatusTest::MaxIters(100));
    _statusTestStagnation = Teuchos::rcp(new NOX::StatusTest::Stagnation(15,0.99));
    _statusTestDivergence = Teuchos::rcp(new NOX::StatusTest::Divergence(1.0e13));

	_statusTestsCombo = Teuchos::rcp(new NOX::StatusTest::Combo(NOX::StatusTest::Combo::OR, _statusTestNormF, _statusTestMaxIters));
	_statusTestsCombo->addStatusTest(_statusTestStagnation);
	_statusTestsCombo->addStatusTest(_statusTestDivergence);

	_solverParametersPtr = Teuchos::rcp(new Teuchos::ParameterList);
	_solverParametersPtr->sublist("Line Search").set("Method", "Backtrack");

	if (_generateoutput){
		_solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error + NOX::Utils::Warning + NOX::Utils::OuterIteration + NOX::Utils::Details + NOX::Utils::Debug); //(there are also more options, but error and outer iteration are the ones that I commonly use.
	}else{
		_solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error);
	}

	_noxLapackInterface = Teuchos::rcp(new NoxLapackInterface (_algLoop,-1));//this also gets the nominal values

	_iterationStatus=CONTINUE;

	while(_iterationStatus==CONTINUE){
		iter++;

		// Reset initial guess
		memcpy(_y,_y0,_dimSys*sizeof(double));
		_algLoop->setReal(_y);

		_grp = Teuchos::rcp(new NOX::LAPACK::Group(*_noxLapackInterface));//this also calls the getInitialGuess-function in the NoxLapackInterface and sets the initial guess in the NOX::LAPACK::Group

		try{
			_solver = NOX::Solver::buildSolver(_grp, _statusTestsCombo, _solverParametersPtr);
		}
		catch(const std::exception &ex)
		{
			std::cout << std::endl << "sth went wrong during solver building, with error message" << ex.what() << std::endl;
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"solver building error");
		}


		if (_generateoutput) {
			double* rhsssss = new double[_dimSys];//stores f(x)
			double* xp = new double[_dimSys];//stores x temporarily
			_algLoop->getReal(xp);
			_algLoop->getRHS(rhsssss);
			std::cout << "we are at position x=(";
			for (int i=0;i<_dimSys;i++){
				std::cout << xp[i] << " ";
			}
			std::cout << ")" << std::endl;
			std::cout << "the right hand side is given by (";
			for (int i=0;i<_dimSys;i++){
				std::cout << rhsssss[i] << " ";
			}
			std::cout << ")" << std::endl;
			std::cout << std::endl;
			delete [] rhsssss;
			delete [] xp;

			std::cout << "we are solving with the following options:" <<std::endl;
			_solverParametersPtr->print();
			std::cout << std::endl;
		}

		try{
			status = _solver->solve();
		}
		catch(const std::exception &ex)
		{
			std::cout << std::endl << "sth went wrong during solving, with error message" << ex.what() << std::endl;
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"solving error");
		}

		// Get the answer
		NOX::LAPACK::Group solnGrp = dynamic_cast<const NOX::LAPACK::Group&>(_solver->getSolutionGroup());
		NOX::LAPACK::Vector Lapacksolution=dynamic_cast<const NOX::LAPACK::Vector&>(solnGrp.getX());

		for (int i=0;i<_dimSys;i++){
			if (_useDomainScaling){
				_y[i]=Lapacksolution(i)/_yScale[i];
			}else{
				_y[i]=Lapacksolution(i);
			}
		}

		_algLoop->setReal(_y);
		_algLoop->evaluate();

		if (_generateoutput) {
			std::cout << "solutionvector=(";
			for (int i=0;i<_dimSys;i++) std::cout << _y[i] << " ";
			std::cout << ")" << std::endl;
		}

		if (status==NOX::StatusTest::Converged){
			if (_generateoutput) std::cout << "simtime=" << _algLoop->getSimTime() << std::endl;
			_iterationStatus=DONE;
		}
	}
	if (_generateoutput) std::cout << "ending solve" << std::endl;

	return status;
}

/** @} */ // end of solverNox
