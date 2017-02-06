#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/Nox/FactoryExport.h>


#include <NOX.H>
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
    _statusTestsCombo = Teuchos::rcp(new NOX::StatusTest::Combo(NOX::StatusTest::Combo::OR, _statusTestNormF, _statusTestMaxIters));

	// Create the list of solver parameters
    _solverParametersPtr = Teuchos::rcp(new Teuchos::ParameterList);
	//resetting method to default (Line Search). For detailed calibration, check https://trilinos.org/docs/dev/packages/nox/doc/html/parameters.html
    _solverParametersPtr->set("Nonlinear Solver", "Line Search Based");

	_solverParametersPtr->sublist("Printing").set("Output Precision", 15);

	//_solverParametersPtr->sublist("Direction").set("Method", "Steepest Descent");

	//resetting Line search method to default (Full Step, ie. Standard Newton with lambda=1)
	_solverParametersPtr->sublist("Line Search").set("Method", "Full Step");
	// Set the level of output
    if (_generateoutput){
		_solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error + NOX::Utils::Warning + NOX::Utils::OuterIteration + NOX::Utils::Details + NOX::Utils::Debug); //(there are also more options, but error and outer iteration are the ones that I commonly use.
	}else{
		_solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error);
	}


	if (_generateoutput) std::cout << "creating noxLapackInterface" << std::endl;

	_noxLapackInterface = Teuchos::rcp(new NoxLapackInterface (_algLoop));//this also gets the nominal values



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

		_grp = Teuchos::rcp(new NOX::LAPACK::Group(*_noxLapackInterface));//this also calls the getInitialGuess-function in the NoxLapackInterface and sets the initial guess in the NOX::LAPACK::Group

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
		catch(std::exception &ex)
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
		catch(std::exception &ex)
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

		int numberofdifferentnormtests=5;

		if (status==NOX::StatusTest::Converged){
			//this safeguard check fails since function value scaling was implemented.
			//if (sum>1.0e-6) std::cout << "something is not right with the solver. sum=" << sum << std::endl;
			if (_generateoutput) std::cout << "simtime=" << _algLoop->getSimTime() << std::endl;
			_iterationStatus=DONE;
		}else{
			//skip iter=1,2,4,6,7,8
			if (iter==6){
				iter = 9;
			}
			if (iter==4){
				iter = 5;
			}
			if (iter==0){
				iter = 3;
			}
			if ((iter == 1) || (iter == 2) || (iter == 4) || (iter == 6) || (iter == 7) || (iter == 8)){
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

			switch (iter/numberofdifferentnormtests){
			case 0:
				break;
				//default Nox Line Search failed -> Try Backtracking instead
			case 1:
				_solverParametersPtr->sublist("Line Search").set("Method", "Backtrack");
				_solverParametersPtr->sublist("Line Search").sublist("Backtrack").set("Default Step", 1024.0*1024.0);
				_solverParametersPtr->sublist("Line Search").sublist("Backtrack").set("Minimum Step", 1.0e-30);
				_solverParametersPtr->sublist("Line Search").sublist("Backtrack").set("Recovery Step", 0.0);
				//std::cout << "we just set the solver parameters to use backtrack. the currently used options are:" << std::endl;
				//_solverParametersPtr->print();
				//std::cout << std::endl;
				break;

				//Backtracking failed -> Try Polynomial with various parameters instead
			case 2:
				_solverParametersPtr->sublist("Line Search").set("Method", "Polynomial");
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Minimum Step", 1.0e-30);
				//_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Alpha Factor", 1.0e-2);
				break;

			case 3:
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic");
				break;

			case 4:
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic3");
				break;

			case 5:
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Sufficient Decrease Condition", "Ared/Pred");
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Cubic");
				break;

			case 6:
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic");
				break;

			case 7:
				_solverParametersPtr->sublist("Line Search").sublist("Polynomial").set("Interpolation Type", "Quadratic3");
				break;

				//Polynomial failed -> Try More'-Thuente instead
			case 8:
				_solverParametersPtr->sublist("Line Search").set("Method", "More'-Thuente");
				//_solverParametersPtr->sublist("Line Search").sublist("More'-Thuente").set("Sufficient Decrease", 1.0e-2);
				break;

				//More'-Thuente failed -> Try Trust Region instead
			case 9:
				//_solverParametersPtr->sublist("Line Search").sublist("More'-Thuente").remove("Sufficient Decrease", true);
				_solverParametersPtr->sublist("Line Search").remove("Method", true);
				_solverParametersPtr->set("Nonlinear Solver", "Trust Region Based");
				_solverParametersPtr->sublist("Trust Region").set("Minimum Improvement Ratio", 1.0e-4);
				_solverParametersPtr->sublist("Trust Region").set("Minimum Trust Region Radius", 1.0e-6);
				break;

				//Trust Region failed -> Try Inexact Trust Region instead
			case 10:
				//_solverParametersPtr->sublist("Trust Region").set("Use Dogleg Segment Minimization", true);
				_solverParametersPtr->set("Nonlinear Solver", "Inexact Trust Region Based");
				break;

				//Inexact Trust Region failed -> Try Tensor instead
			//case 11:
				//_solverParametersPtr->set("Nonlinear Solver", "Tensor Based");
				//break;

				//Tensor failed or other failure
			default:
				_iterationStatus=SOLVERERROR;
				throw ModelicaSimulationError(ALGLOOP_SOLVER,"Nonlinear solver nox failed!");
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
				std::cout << "Solverparamters and StatusTest at iter " << iter << ", with simtime " << _algLoop->getSimTime() << std::endl;
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


/** @} */ // end of solverNox
