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
	, _useScale           (true)
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
    if(_noxLapackInterface) delete _noxLapackInterface;

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
	_algLoop->getNominalReal(_yScale);

	if (_generateoutput) std::cout << "ending init" << std::endl;
}


void Nox::solve()
{
	if (_generateoutput) std::cout << "starting solve" << std::endl;

	int iter=0; //Iterationcount
	NOX::StatusTest::StatusType status;
	NOX::LAPACK::Vector Lapacksolution;//temporary variable used to convert the solution from NOX::LAPACK::Vector to a double array.
	double * rhs = new double[_dimSys];
	double sum;



    if (_firstCall) initialize();

	// Set up the status tests
    _statusTestNormF = Teuchos::rcp(new NOX::StatusTest::NormF(3.0e-5));
    _statusTestMaxIters = Teuchos::rcp(new NOX::StatusTest::MaxIters(100));
    _statusTestsCombo = Teuchos::rcp(new NOX::StatusTest::Combo(NOX::StatusTest::Combo::OR, _statusTestNormF, _statusTestMaxIters));

	// Create the list of solver parameters
    _solverParametersPtr = Teuchos::rcp(new Teuchos::ParameterList);
	//resetting method to default (Line Search). For detailed calibration, check https://trilinos.org/docs/dev/packages/nox/doc/html/parameters.html
    _solverParametersPtr->set("Nonlinear Solver", "Line Search Based");
	//resetting Line search method to default (Full Step, ie. Standard Newton with lambda=1)
	_solverParametersPtr->sublist("Line Search").set("Method", "Full Step");
	// Set the level of output
    if (_generateoutput){
		_solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error + NOX::Utils::Warning + NOX::Utils::OuterIteration + NOX::Utils::InnerIteration + NOX::Utils::Debug); //(there are also more options, but error and outer iteration are the ones that I commonly use.
	}else{
		_solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error);
	}


	_iterationStatus=CONTINUE;

	if (_generateoutput) std::cout << "starting while loop" << std::endl;

	while(_iterationStatus==CONTINUE){
		iter++;

		// Reset initial guess
		memcpy(_y,_y0,_dimSys*sizeof(double));
		_algLoop->setReal(_y);

		if (_generateoutput) std::cout << "creating noxLapackInterface" << std::endl;

		_noxLapackInterface = new NoxLapackInterface (_algLoop);
		_grp = Teuchos::rcp(new NOX::LAPACK::Group(*_noxLapackInterface));

		if (_generateoutput) std::cout << "building solver" << std::endl;

		// Create the solver
		_solver = NOX::Solver::buildSolver(_grp, _statusTestsCombo, _solverParametersPtr);

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

		status = _solver->solve();

		if (_generateoutput) std::cout << "finishing solve!" << std::endl;

		// Get the answer
		NOX::LAPACK::Group solnGrp = dynamic_cast<const NOX::LAPACK::Group&>(_solver->getSolutionGroup());

		Lapacksolution=dynamic_cast<const NOX::LAPACK::Vector&>(solnGrp.getX());
		for (int i=0;i<_dimSys;i++){
			_y[i]=Lapacksolution(i);
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


		if (status==NOX::StatusTest::Converged){
			if (sum>1.0e-6) std::cout << "something is not right with the solver. sum=" << sum << std::endl;
			//std::cout << "simtime=" << _algLoop->getSimTime() << std::endl;
			_iterationStatus=DONE;
		}else{
			switch (iter){
				//default Nox Line Search failed -> Try Backtracking instead
			case 1:
				_solverParametersPtr->sublist("Line Search").set("Method", "Backtrack");
				break;

				//Backtracking failed -> Try Polynomial instead
			case 2:
				_solverParametersPtr->sublist("Line Search").set("Method", "Polynomial");
				//->sublist("Line Search").sublist("Polynomial").set("Alpha Factor", 1.0e-2);
				break;

				//Polynomial failed -> Try More'-Thuente instead
			case 3:
				//_solverParametersPtr->sublist("Line Search").sublist("Polynomial").remove("Alpha Factor", true);
				_solverParametersPtr->sublist("Line Search").set("Method", "More'-Thuente");
				//_solverParametersPtr->sublist("Line Search").sublist("More'-Thuente").set("Sufficient Decrease", 1.0e-2);
				break;

				//More'-Thuente failed -> Try Trust Region instead
			case 4:
				//_solverParametersPtr->sublist("Line Search").sublist("More'-Thuente").remove("Sufficient Decrease", true);
				_solverParametersPtr->sublist("Line Search").remove("Method", true);
				_solverParametersPtr->set("Nonlinear Solver", "Trust Region Based");
				_solverParametersPtr->sublist("Trust Region").set("Minimum Improvement Ratio", 1.0e-4);
				_solverParametersPtr->sublist("Trust Region").set("Minimum Trust Region Radius", 1.0e-6);
				break;

				//Trust Region failed -> Try Inexact Trust Region instead
			case 5:
				//_solverParametersPtr->sublist("Trust Region").set("Use Dogleg Segment Minimization", true);
				_solverParametersPtr->set("Nonlinear Solver", "Inexact Trust Region Based");
				break;

				//Inexact Trust Region failed -> Try Tensor instead
			case 6:
				_solverParametersPtr->set("Nonlinear Solver", "Tensor Based");
				break;

				//Tensor failed or other failure
			default:
				_iterationStatus=SOLVERERROR;
				throw ModelicaSimulationError(ALGLOOP_SOLVER,"Nonlinear solver nox failed!");
				break;
			}
			//comment in for debugging
			std::cout << "simtime=" << _algLoop->getSimTime() << std::endl;
			std::cout << "Some error occured. Trying to solve with different method. iter=" << iter << std::endl;
			_solverParametersPtr->sublist("Printing").set("Output Information", NOX::Utils::Error + NOX::Utils::Warning + NOX::Utils::OuterIteration + NOX::Utils::InnerIteration);
		}
		if (_noxLapackInterface) delete _noxLapackInterface;
	}
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
