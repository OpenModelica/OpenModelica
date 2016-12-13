#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
/** @addtogroup solverLinearSolver
*
*  @{
*/


#include<Core/Math/ILapack.h>
#include <Solver/LinearSolver/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <Solver/LinearSolver/LinearSolver.h>

#if defined(klu)
	#include <klu.h>
#endif

#include <iostream>

#include <Core/Utils/numeric/bindings/ublas.hpp>
#include <Core/Utils/numeric/utils.h>

LinearSolver::LinearSolver(ILinearAlgLoop* algLoop, ILinSolverSettings* settings)
	: _algLoop            (algLoop)
	, _dimSys             (0)

	, _y                  (NULL)
	, _y0                  (NULL)
	, _y_old(NULL)
    , _y_new(NULL)
	, _b                  (NULL)
	, _A                (NULL)
	, _ihelpArray         (NULL)
	, _jhelpArray		  (NULL)
	, _zeroVec            (NULL)

	#if defined(klu)
		, _kluSymbolic 			(NULL)
		, _kluNumeric			(NULL)
		, _kluCommon			(NULL)
		, _Ai					(NULL)
		, _Ap					(NULL)
		, _Ax					(NULL)
	#endif

	, _iterationStatus    (CONTINUE)
	, _firstCall          (true)
	, _scale			  (NULL)
{
	_sparse = _algLoop->getUseSparseFormat();
}

LinearSolver::~LinearSolver()
{
	if(_y)                delete []  _y;
	if(_y0)               delete []  _y0;
    if(_y_old)            delete [] _y_old;
    if(_y_new)            delete [] _y_new;
	if(_b)                delete []  _b;
	if(_A)              delete []  _A;
	if(_ihelpArray)       delete []  _ihelpArray;
	if (_jhelpArray)       delete[]  _jhelpArray;
	if(_zeroVec)          delete []  _zeroVec;
	if (_scale)            delete[]  _scale;

	#if defined(klu)
		if(_sparse == true)
		{
			if(_kluCommon)
			{
				if(_kluSymbolic)
					klu_free_symbolic(&_kluSymbolic, _kluCommon);
				if(_kluNumeric)
					klu_free_numeric(&_kluNumeric, _kluCommon);
				delete _kluCommon;
			}
			if(_Ap)
				delete [] _Ap;
			if(_Ai)
				delete [] _Ai;
		}
	#endif
}

void LinearSolver::initialize()
{
	_firstCall = false;
	//(Re-) Initialization of algebraic loop
	_algLoop->initialize();

	int dimDouble=_algLoop->getDimReal();
	int ok=0;

	if (dimDouble!=_dimSys)
	{
		_dimSys=dimDouble;

		if (_dimSys>0)
		{
			// Initialization of vector of unknowns
			if(_y)               delete []  _y;
			if(_y0)              delete []  _y0;
			if(_y_old)           delete [] _y_old;
			if(_y_new)           delete [] _y_new;
			if(_b)               delete []  _b;
			if(_A)             delete []  _A;
			if(_ihelpArray)      delete []  _ihelpArray;
			if (_jhelpArray)       delete[]  _jhelpArray;
			if(_zeroVec)         delete []  _zeroVec;
			if (_scale)			 delete[]  _scale;

			_y                = new double[_dimSys];
			_y0               = new double[_dimSys];
			_y_old            = new double[_dimSys];
			_y_new            = new double[_dimSys];
			_b                = new double[_dimSys];
			_A              = new double[_dimSys*_dimSys];
			_ihelpArray       = new long int[_dimSys];
			_jhelpArray		  = new long int[_dimSys];
			_zeroVec          = new double[_dimSys];
			_scale			  = new double[_dimSys];

			_algLoop->getReal(_y);
			_algLoop->getReal(_y0);
			_algLoop->getReal(_y_new);
			_algLoop->getReal(_y_old);
			memset(_b, 0, _dimSys*sizeof(double));
			memset(_ihelpArray, 0, _dimSys*sizeof(long int));
			memset(_jhelpArray, 0, _dimSys*sizeof(long int));
			memset(_A, 0, _dimSys*_dimSys*sizeof(double));
			memset(_zeroVec, 0, _dimSys*sizeof(double));
			memset(_scale, 0, _dimSys*sizeof(double));

			#if defined(klu)
				if(_sparse == true)
				{
					_kluCommon = new klu_common;
					ok=klu_defaults (_kluCommon);
					if (ok!=1) throw ModelicaSimulationError(ALGLOOP_SOLVER,"error initializing Sparse Solver KLU");

					sparsematrix_t& A = _algLoop->getSystemSparseMatrix();

					 _nonzeros = A.nnz();

					_Ap = new int[(_dimSys + 1)];
					_Ai = new int[_nonzeros];
					_Ax = new double[_nonzeros];

					int const* Ti= boost::numeric::bindings::begin_compressed_index_major (A);
					int const* Tj= boost::numeric::bindings::begin_index_minor (A);

					_Ax= boost::numeric::bindings::begin_value (A);

					//testing, whether Ax is modified
					double *Ax=0;
					Ax = new double[_nonzeros];
					for(int i=0;i<_nonzeros;i++) Ax[i]=_Ax[i];

					memcpy(_Ap,Ti,sizeof(int)* (_dimSys + 1) );
					memcpy(_Ai,Tj,sizeof(int)* (_nonzeros) );

					_kluSymbolic = klu_analyze (_dimSys, _Ap, _Ai, _kluCommon);
					_kluNumeric = klu_factor (_Ap, _Ai, _Ax, _kluSymbolic, _kluCommon);
					if (_kluNumeric==NULL) throw ModelicaSimulationError(ALGLOOP_SOLVER,"error during numerical factorization with Sparse Solver KLU");

					//testing, whether Ax is modified
					for(int i=0;i<_nonzeros;i++) if(Ax[i]!=_Ax[i]) std::cout << "Ax was modified" << std::endl;
					if(Ax)
					delete [] Ax;
				}
			#endif
		}
		else
		{
			_iterationStatus = SOLVERERROR;
		}
	}
	LOGGER_WRITE("LinearSolver: initialized",LC_NLS,LL_DEBUG);
}

void LinearSolver::solve()
{
	if (_firstCall){
		initialize();
	}

	_iterationStatus = CONTINUE;

	//use lapack
	long int dimRHS  = 1;          // Dimension of right hand side of linear system (=_b)
	long int irtrn  = 0;          // Return-flag of Fortran code

	if(_algLoop->isLinearTearing())
		_algLoop->setReal(_zeroVec);	//if the system is linear Tearing it means that the system is of the form Ax-b=0, so plugging in x=0 yields -b for the left hand side

	_algLoop->evaluate();
	_algLoop->getRHS(_b);

	if (_sparse == false){
		const matrix_t& A = _algLoop->getSystemMatrix();
		const double* Atemp = A.data().begin();

		memcpy(_A, Atemp, _dimSys*_dimSys*sizeof(double));

		/*
		//output routine
		std::cout << std::endl;
		std::cout << "We solve a linear system with coefficient matrix" << std::endl;
		for (int i=0;i<_dimSys;i++){
			for (int j=0;j<_dimSys;j++){
				std::cout << Atemp[i+j*_dimSys] << " ";
			}
			std::cout << std::endl;
		}
		std::cout << "and right hand side" << std::endl;
		for (int i=0;i<_dimSys;i++){
			std::cout << _b[i] << " ";
		}
		std::cout << std::endl;
		*/


		dgesv_(&_dimSys,&dimRHS,_A,&_dimSys,_ihelpArray,_b,&_dimSys,&irtrn);

		if  (irtrn != 0)
		{
			dgetc2_(&_dimSys, _A, &_dimSys, _ihelpArray, _jhelpArray, &irtrn);
			dgesc2_(&_dimSys, _A, &_dimSys, _b, _ihelpArray, _jhelpArray, _scale);
			LOGGER_WRITE("LinearSolver: Linear system singular, using perturbed system matrix.", LC_NLS, LL_DEBUG);
			_iterationStatus = DONE;
		}
		else
			_iterationStatus = DONE;
	}else{

		#if defined(klu)


			//testing sparse with dense
			/*this version is a test. it extracts the dense format out of the sparse format and uses the dense lapack solver to sove the dense problem.

			//writing entries of A
			sparsematrix_t& A = _algLoop->getSystemSparseMatrix();
			_Ax= boost::numeric::bindings::begin_value (A);


			double** a = new double*[_dimSys];
			double* asdf = new double[_dimSys*_dimSys];
			for(int i=0;i<_dimSys;i++){
				a[i]=new double[_dimSys];
			}

			for(int i=0;i<_dimSys;i++){
				for(int j=0;j<_dimSys;j++){
					a[i][j]=0;
					for(int k=_Ap[j];k<_Ap[j+1];k++)
						if(i==_Ai[k])
							a[i][j]=_Ax[k];
				}
			}

			for(int i=0;i<_dimSys;i++){
				for(int j=0;j<_dimSys;j++){
					asdf[i+j*_dimSys]=a[i][j];
				}
			}

			//output routine
			std::cout << std::endl;
			std::cout << "We solve a linear system with coefficient matrix" << std::endl;
			for (int i=0;i<_dimSys;i++){
				for (int j=0;j<_dimSys;j++){
					std::cout << asdf[i+j*_dimSys] << " ";
				}
				std::cout << std::endl;
			}
			std::cout << "and right hand side" << std::endl;
			for (int i=0;i<_dimSys;i++){
				std::cout << _b[i] << " ";
			}
			std::cout << std::endl;





			dgesv_(&_dimSys,&dimRHS,asdf,&_dimSys,_ihelpArray,_b,&_dimSys,&irtrn);
			_iterationStatus = DONE;
			for(int i=0;i<_dimSys;i++){
				delete [] a[i];
			}
			delete [] a;
			delete [] asdf;

			/*test for ccs-dense-conversion
			// testSparse2.cpp : Defines the entry point for the console application.
			//

			#include "stdafx.h"


			int _tmain(int argc, _TCHAR* argv[])
			{
				int _dimSys = 3;
				int _Ap[4] = {0,3,5,6};
				int _Ai[6] = { 0, 1, 2, 1, 2, 2 };
				int _Ax[6] = { 5, 4, 3, 2, 1, 8 };

				double** a = new double*[_dimSys];
				for (int i = 0; i<_dimSys; i++){
					a[i] = new double[_dimSys];
				}

				for (int i = 0; i<_dimSys; i++){
					for (int j = 0; j<_dimSys; j++){
						a[i][j] = 0;
						for (int k = _Ap[j]; k<_Ap[j + 1]; k++)
							if (i == _Ai[k])
								a[i][j] += _Ax[k];
					}
				}

				for (int i = 0; i < _dimSys; i++){
					for (int j = 0; j < _dimSys; j++){
						printf("a(%i,%i)=%e\n", i, j, a[i][j]);
					}
				}

				for (int i = 0; i<_dimSys; i++){
					delete[] a[i];
				}
				delete[] a;
				return 0;
			}
			*/


			//version with klu

			/*
			//testing, whether Ax is modified
			double *Ax=NULL;
			Ax = new double[_nonzeros];
			for(int i=0;i<_nonzeros;i++) Ax[i]=_Ax[i];
			*/


			//writing entries of A
			sparsematrix_t& A = _algLoop->getSystemSparseMatrix();
			_Ax= boost::numeric::bindings::begin_value (A);

			int ok = klu_refactor (_Ap, _Ai, _Ax, _kluSymbolic, _kluNumeric, _kluCommon) ;

			//checking for accuracy of refactorization
			ok = klu_rgrowth(_Ap, _Ai, _Ax, _kluSymbolic, _kluNumeric, _kluCommon);
			if (ok!=1) throw ModelicaSimulationError(ALGLOOP_SOLVER,"Sparse Solver KLU: error checking accuracy of refactorization by computing reciprocal pivot growth");
			if (_kluCommon->rgrowth < 1e-3){
				klu_free_numeric(&_kluNumeric, _kluCommon);
				_kluNumeric = klu_factor (_Ap, _Ai, _Ax, _kluSymbolic, _kluCommon);
				if (_kluNumeric==NULL) throw ModelicaSimulationError(ALGLOOP_SOLVER,"error during numerical factorization with Sparse Solver KLU");
			}

			ok=klu_solve (_kluSymbolic, _kluNumeric, _dimSys, 1, _b, _kluCommon) ;
			if (ok!=1) throw ModelicaSimulationError(ALGLOOP_SOLVER,"error solving Sparse Solver KLU");

			/*
			//testing, whether Ax is modified
			for(int i=0;i<_nonzeros;i++) if(Ax[i]!=_Ax[i]) std::cout << "Ax was modified" << std::endl;
			if(Ax)
			delete [] Ax;
			*/

		#else
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"error solving linear system with klu not implemented");
		#endif
	}

	if(_algLoop->isLinearTearing()){
		for(int i=0; i<_dimSys; i++)
			_y[i]=-_b[i];
	}else{
		memcpy(_y,_b,_dimSys*sizeof(double));
	}


	/*
	//output routine
	std::cout << "The solution of the linear system is given by" << std::endl;
	for (int i=0;i<_dimSys;i++){
		std::cout << _y[i] << " ";
	}
	std::cout << std::endl;
	*/


	_algLoop->setReal(_y);
	if(_algLoop->isLinearTearing())		_algLoop->evaluate();//warum nur in diesem Fall??
}

IAlgLoopSolver::ITERATIONSTATUS LinearSolver::getIterationStatus()
{
	return _iterationStatus;
}

void LinearSolver::stepCompleted(double time)
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
void LinearSolver::restoreOldValues()
{
	memcpy(_y,_y_old,_dimSys*sizeof(double));
}


/**
 *  \brief Restores all algloop variables for last output step
 *  \return Return_Description
 *  \details Details
 */
void LinearSolver::restoreNewValues()
{
   memcpy(_y,_y_new,_dimSys*sizeof(double));
}


/** @} */ // end of solverLinearSolver
