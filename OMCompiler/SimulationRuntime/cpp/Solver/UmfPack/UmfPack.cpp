/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include <Solver/UmfPack/UmfPack.h>
#include <Core/Math/ILapack.h>

#ifdef USE_UMFPACK
#include "umfpack.h"
#include <Core/Utils/numeric/bindings/umfpack/umfpack.hpp>
#include <Core/Utils/numeric/bindings/ublas/vector.hpp>
#include <Core/Utils/numeric/bindings/ublas.hpp>
#include <boost/numeric/ublas/io.hpp>
namespace umf = boost::numeric::bindings::umfpack;
#endif
UmfPack::UmfPack(ILinSolverSettings* settings,shared_ptr<ILinearAlgLoop> algLoop)
  :AlgLoopSolverDefaultImplementation()
  ,_iterationStatus(CONTINUE),
 _umfpackSettings(settings),
 _algLoop(algLoop),
 _rhs(NULL),
 _x(NULL),
 _firstuse(true),
 _jacd(NULL)
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

UmfPack::~UmfPack()
{
    if(_jacd)   delete [] _jacd;
    if(_rhs)     delete []  _rhs;
    if(_x)      delete [] _x;
}

void UmfPack::initialize()
{
#ifdef USE_UMFPACK
    _firstuse=false;
     if(_algLoop)
      _algLoop->initialize();
    else
	  throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
     _dimSys = _algLoop->getDimReal();

	if(_algLoop->queryDensity()<1. &&_umfpackSettings->getUseSparseFormat() )
    {
        _algLoop->setUseSparseFormat(true);

    }
    else
    {
        _jacd= new double[_algLoop->getDimReal()*_algLoop->getDimReal()];
        _algLoop->setUseSparseFormat(false);
    }


    _rhs = new double[_algLoop->getDimReal()];
    _x = new double[_algLoop->getDimReal()];
#endif
}


bool* UmfPack::getConditionsWorkArray()
{
	return AlgLoopSolverDefaultImplementation::getConditionsWorkArray();

}
bool* UmfPack::getConditions2WorkArray()
{

	return AlgLoopSolverDefaultImplementation::getConditions2WorkArray();
 }


 double* UmfPack::getVariableWorkArray()
 {

	return AlgLoopSolverDefaultImplementation::getVariableWorkArray();

 }

void UmfPack::solve(shared_ptr<ILinearAlgLoop> algLoop,bool first_solve)
{
	throw ModelicaSimulationError(ALGLOOP_SOLVER, "solve for single instance is not supported");
}
void UmfPack::solve()
{
#ifdef USE_UMFPACK



	if(!_algLoop)
       throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");


	 if(_firstuse)
		 initialize();
    if(!_algLoop->getUseSparseFormat())
    {
        long int dimRHS  = 1;          // Dimension of right hand side of linear system (=b)
        long int dimSys = _algLoop->getDimReal();
        long int irtrn  = 0;          // Retrun-flag of Fortran code        _algLoop->getReal(_y);
        long int * _helpArray = new long int[_algLoop->getDimReal()];
        _algLoop->evaluate();
        _algLoop->getb(_rhs);

        const matrix_t& A = _algLoop->getAMatrix();
		const double* jacd = A.data().begin();
		memcpy(_jacd, jacd, dimSys*dimSys*sizeof(double));

        dgesv_(&dimSys,&dimRHS,_jacd,&dimSys,_helpArray,_rhs,&dimSys,&irtrn);
        std::memcpy(_x,_rhs,dimSys*sizeof(double));
        _algLoop->setReal(_x);
        delete [] _helpArray;
    }
    else
    {


         int status;
        // get the default control parameters
		umf::control_type<> Control;
		// change the default print level
		Control [UMFPACK_PRL] = 6;

		 _algLoop->evaluate();
        _algLoop->getb(_rhs);
         long int dimSys = _algLoop->getDimReal();
        const sparsematrix_t& A = _algLoop->getSparseAMatrix();

        adaptor_t rhs_adaptor(dimSys,_rhs);
		shared_vector_t b(dimSys,rhs_adaptor);

        adaptor_t x_adaptor(dimSys,_x);
		shared_vector_t x(dimSys,x_adaptor);


        umf::symbolic_type<double> Symbolic;
        umf::numeric_type<double> Numeric;
		status = umf::symbolic(A, Symbolic);
        if(status<0)
			//umf::report_status (Control, status)
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"Error in umfpack symbolic function");
		status = umf::numeric (A, Symbolic, Numeric);
		if(status<0)
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"Error in umfpack numeric function");
        status = umf::solve (A, x, b, Numeric);
		if(status<0)
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"Error in umfpack solve function");
        _algLoop->setReal(_x);


    }

#endif
}

ILinearAlgLoopSolver::ITERATIONSTATUS UmfPack::getIterationStatus()
{
    return _iterationStatus;
}

void UmfPack::stepCompleted(double time)
{
}
void UmfPack::restoreOldValues()
{

}

void UmfPack::restoreNewValues()
{

}
