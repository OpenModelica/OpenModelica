/** @addtogroup solverNewton
*
*  @{
*/
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Solver/Newton/Newton.h>

#include <Core/Math/ILapack.h>        // needed for solution of linear system with Lapack
#include <Core/Math/IBlas.h>        // use BLAS routines
#include <Core/Math/Constants.h>        // definitializeion of constants like uround

#if defined(__vxworks)
//#include <klu.h>
#else
//#include <Solver/KLU/klu.h>
#endif

#include <Core/Utils/numeric/bindings/ublas.hpp>
#include <Core/Utils/numeric/utils.h>

Newton::Newton(IAlgLoop* algLoop, INonLinSolverSettings* settings)
	: _algLoop            (algLoop)
	, _newtonSettings    ((INonLinSolverSettings*)settings)
	, _y                  (NULL)
	, _yHelp              (NULL)
	, _fnew               (NULL)
	, _fold               (NULL)
	, _f                  (NULL)
	, _ihelpArray         (NULL)
	, _fHelp              (NULL)
	, _delta_s            (NULL)
	, _delta_b            (NULL)
	, _iHelp              (NULL)
	, _jac                (NULL)
	, _jacHelpVec1        (NULL)
	, _jacHelpVec2        (NULL)
	, _jacHelpMat1        (NULL)
	, _jacHelpMat2        (NULL)
	, _work               (NULL)
	,_zeroVec             (NULL)
	, _identity           (NULL)


/*
    , _kluSymbolic 			(NULL)
    , _kluNumeric			(NULL)
    , _kluCommon			(NULL)
    , _Ai					(NULL)
    , _Ap					(NULL)
    , _Ax					(NULL)
*/
	, _dimSys            (0)
	, _firstCall        (true)
	, _iterationStatus    (CONTINUE)
	, _broydenMethod	(2)
	, _dONE				(1.0)
	,_dZERO				(0.0)
	,_iONE				(1)
	, _dMINUSONE		(-1.0)
	, _N				('n')
	,_T					('t')

{
	_sparse = _algLoop->getUseSparseFormat();
}

Newton::~Newton()
{
	if(_y)         delete []    _y;
	if(_yHelp)    delete []    _yHelp;
	if(_fnew)        delete []    _fnew;
	if(_fold)        delete []    _fold;
	if(_fHelp)        delete []    _fHelp;
	if(_delta_s)    delete []    _delta_s;
	if(_delta_b)    delete []    _delta_b;
	if(_iHelp)    delete []    _iHelp;
	if(_jac)    delete []    _jac;
	if(_jacHelpVec1)    delete []    _jacHelpVec1;
	if(_jacHelpVec2)    delete []    _jacHelpVec2;
	if(_jacHelpMat1)    delete []    _jacHelpMat1;
	if(_jacHelpMat2)    delete []    _jacHelpMat2;
	if(_work)    delete []    _work;
	if(_identity) delete [] _identity;
	if(_zeroVec) delete [] _zeroVec;
	if(_f) delete [] _f;
	if(_ihelpArray) delete [] _ihelpArray;


	/*
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
		if(_Ax)
			delete [] _Ax;
	}
	*/

}

void Newton::initialize()
{
	_firstCall = false;

	//(Re-) initializeialization of algebraic loop
	_algLoop->initialize();

	// Dimension of the system (number of variables)
	int
		dimDouble    = _algLoop->getDimReal(),

		dimInt        = 0,
		dimBool        = 0;

	// Check system dimension
	if (dimDouble != _dimSys)
	{
		_dimSys = dimDouble;
		_lwork = 8*_dimSys;
		_fNormTol = 1e-6;
		_dim = _dimSys;

		if(_dimSys > 0)
		{
			if(_y)         delete []    _y;
			if(_yHelp)    delete []    _yHelp;
			if(_fnew)        delete []    _fnew;
			if(_fold)        delete []    _fold;
			if(_fHelp)        delete []    _fHelp;
			if(_delta_s)    delete []    _delta_s;
			if(_delta_b)    delete []    _delta_b;
			if(_iHelp)    delete []    _iHelp;
			if(_jac)    delete []    _jac;
			if(_jacHelpVec1)    delete []    _jacHelpVec1;
			if(_jacHelpVec2)    delete []    _jacHelpVec2;
			if(_jacHelpMat1)    delete []    _jacHelpMat1;
			if(_jacHelpMat2)    delete []    _jacHelpMat2;
			if(_work)    delete []    _work;
			if(_identity) delete [] _identity;
			if(_zeroVec) delete [] _zeroVec;
			if(_f) delete [] _f;
			if(_ihelpArray) delete [] _ihelpArray;

			_y            = new double[_dimSys];
			_yHelp        = new double[_dimSys];
			_fnew            = new double[_dimSys];
			_fold            = new double[_dimSys];
			_fHelp            = new double[_dimSys];
			_delta_s        = new double[_dimSys];
			_delta_b        = new double[_dimSys];
			_iHelp       = new long int[_dimSys];
			_jac        = new double[_dimSys*_dimSys];
			_jacHelpVec1        = new double[_dimSys];
			_jacHelpVec2        = new double[_dimSys];
			_jacHelpMat1        = new double[_dimSys*_dimSys];
			_jacHelpMat2        = new double[_dimSys*_dimSys];
			_work        = new double[8*_dimSys];


			_identity = new double[_dimSys * _dimSys];

			_zeroVec          = new double[_dimSys];
			 _f                  = new double[_dimSys];
			_ihelpArray       = new long int[_dimSys];


			_algLoop->getReal(_y);
			memset(_yHelp,0,_dimSys*sizeof(double));
			memset(_fnew,0,_dimSys*sizeof(double));
			memset(_fold,0,_dimSys*sizeof(double));
			memset(_fHelp,0,_dimSys*sizeof(double));
			memset(_delta_s,0,_dimSys*sizeof(double));
			memset(_delta_b,0,_dimSys*sizeof(double));
			memset(_jac,0,_dimSys*_dimSys*sizeof(double));
			memset(_jacHelpVec1,0,_dimSys*sizeof(double));
			memset(_jacHelpVec2,0,_dimSys*sizeof(double));
			memset(_jacHelpMat1,0,_dimSys*_dimSys*sizeof(double));
			memset(_jacHelpMat2,0,_dimSys*_dimSys*sizeof(double));

			memset(_work,0,_lwork*sizeof(double));

			memset(_identity, 0,_dimSys*_dimSys*sizeof(double));

			for (int i = 0; i < _dimSys; i++)
			{
				_identity[i + i * _dimSys] = 1.0;
			}

			/* sparse stuff
			if (_algLoop->isLinear() || _algLoop->isLinearTearing())
				{
					if(_sparse == true)
					{
						_kluCommon = new klu_common;
						klu_defaults (_kluCommon);
						const sparsematrix_t& A = _algLoop->getSystemSparseMatrix();


						 _nonzeros = A.nnz();
						_Ap = new int[(_dim + 1)];
						_Ai = new int[_nonzeros];//todo + 1 ?
						_Ax = new double[_nonzeros];//todo + 1 ?

						int const* Ti = bindings::begin_compressed_index_major (A);
						int const* Tj = bindings::begin_index_minor (A);

						double const* Ax = bindings::begin_value (A);

						memcpy(_Ax,Ax,sizeof(double)* _nonzeros );
						memcpy(_Ap,Ti,sizeof(int)* (_dim + 1) );
						memcpy(_Ai,Tj,sizeof(int)* (_nonzeros) );

						_kluSymbolic = klu_analyze (_dim, _Ap, _Ai, _kluCommon);
						_kluNumeric = klu_factor (_Ap, _Ai, _Ax, _kluSymbolic, _kluCommon) ;
					}
				}
		*/




		}
		else
		{
			_iterationStatus = SOLVERERROR;
		}
	}


	long int
		irtrn    = 0;

	calcFunction(_y,_fold);
	if(!_algLoop->isLinear())
	{
		calcJacobian();
		if(_broydenMethod==2)
		{
			dgesv_(&_dimSys,&_dimSys,_jac,&_dimSys,_ihelpArray,_identity,&_dimSys,&irtrn);
			memcpy(_jac,_identity,_dimSys*_dimSys*sizeof(double));
		}

	}

	Logger::write("Newton: initialized",LC_NLS,LL_DEBUG);

}

void Newton::solve()
{

	long int
		dimRHS    = 1,                    // Dimension of right hand side of linear system (=b)
		irtrn    = 0;                    // Retrun-flag of Fortran code

	int
		totStps    = 0;                    // Total number of steps

	double delta;

	// If initialize() was not called yet
	if (_firstCall)
	{
		initialize();
	}

	if(_algLoop->isLinear() && !_algLoop->isLinearTearing())
	{


		//use lapack
		long int dimRHS  = 1;          // Dimension of right hand side of linear system (=b)
		long int irtrn  = 0;          // Retrun-flag of Fortran code        _algLoop->getReal(_y);
		_algLoop->evaluate();
		_algLoop->getRHS(_f);
		if(_sparse == false)
		{

			const matrix_t& A = _algLoop->getSystemMatrix();

			const double* jac = A.data().begin();


			memcpy(_jac, jac, _dimSys*_dimSys*sizeof(double));


			dgesv_(&_dimSys,&dimRHS,_jac,&_dimSys,_ihelpArray,_f,&_dimSys,&irtrn);


		}
		//sparse
		else
		{
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"error solving linear  system with klu not implemented");
			/*

			//const sparsematrix_t& As = _algLoop->getSystemSparseMatrix();

			//double const* Ax = bindings::begin_value (As);
			//double * Ax = (NULL);
			_algLoop->getSparseAdata( _Ax, _nonzeros);

			//memcpy(_Ax,Ax,sizeof(double)* _nonzeros );

			int ok = klu_refactor (_Ap, _Ai, _Ax, _kluSymbolic, _kluNumeric, _kluCommon) ;
			if (ok < 0)//wvEvent(4,NULL,0);
			{
				throw ModelicaSimulationError(ALGLOOP_SOLVER,"error solving linear  system with klu");
			}
			klu_solve (_kluSymbolic, _kluNumeric, _dim, 1, _f, _kluCommon) ;

			*/
		}

		memcpy(_y,_f,_dimSys*sizeof(double));
		_algLoop->setReal(_y);
		if(irtrn != 0)
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"error solving linear  system");
		else
			_iterationStatus = DONE;


	}
	else if(_algLoop->isLinearTearing())
	{


		//int
		//	method = KIN_NONE,
		//	iter = 0,
		//	idid;
		//for(int i=0;i<_dimSys;i++) // Reset Scaling
		//	_fScale[i] = 1.0;
		////idid = KINSol(_kinMem, _Kin_y, KIN_NONE, _Kin_yScale, _Kin_fScale);
		//solveNLS();
		//_algLoop->setReal(_y);
		//_algLoop->evaluate();
		////if (check_flag(&idid, (char *)"KINSol", 1))
		//if (_iterationStatus == SOLVERERROR)
		//	throw ModelicaSimulationError(ALGLOOP_SOLVER,"error solving linear tearing system");
		//else
		//	_iterationStatus = DONE;



		long int dimRHS  = 1;          // Dimension of right hand side of linear system (=b)
		long int irtrn  = 0;          // Retrun-flag of Fortran code

		_algLoop->setReal(_zeroVec);
		_algLoop->evaluate();
		_algLoop->getRHS(_f);


		// adaptor_t f_adaptor(_dimSys,_f);
		//shared_matrix_t b(_dimSys,1,f_adaptor);


		//print_m (b, "b vector");
		if(_sparse == false)
		{


			const matrix_t& A = _algLoop->getSystemMatrix();

			//matrix_t  A_copy(A);


			const double* jac = A.data().begin();

			//double* jac = new  double[dimSys*dimSys];
			//for(int i=0;i<dimSys;i++)
			//for(int j=0;j<dimSys;j++)
			//jac[i*_dimSys+j] = A_sparse(i,j);


			memcpy(_jac, jac, _dimSys*_dimSys*sizeof(double));




			dgesv_(&_dimSys, &dimRHS, _jac, &_dimSys, _ihelpArray, _f,&_dimSys,&irtrn);

		}
		//std::vector< int > ipiv (_dimSys);  // pivot vector
		//lapack::gesv (A, ipiv,b);   // solving the system, b contains x
		else
		{
			throw ModelicaSimulationError(ALGLOOP_SOLVER,"error solving linear  system with klu");
			/*
			//Sparse Solve

			const sparsematrix_t& As = _algLoop->getSystemSparseMatrix();

			double const* Ax = bindings::begin_value (As);

			memcpy(_Ax,Ax,sizeof(double)* _nonzeros );

			int ok = klu_refactor (_Ap, _Ai, _Ax, _kluSymbolic, _kluNumeric, _kluCommon) ;

			klu_solve (_kluSymbolic, _kluNumeric, _dim, 1, _f, _kluCommon) ;

			*/
	    }



	   for(int i=0; i<_dimSys; i++)
		_y[i]=-_f[i];
		_algLoop->setReal(_y);
		_algLoop->evaluate();

	}

	else
	{
		// Reset status flag
		_iterationStatus = CONTINUE;
		calcFunction(_y,_fold);
		//calcJacobian();
		/*
		if(_broydenMethod==2)
		{
			dgetrf_(&_dimSys, &_dimSys, _jac, &_dimSys, _iHelp, &irtrn);
			dgetri_(&_dimSys, _jac, &_dimSys, _iHelp,_work, &_lwork, &irtrn);
		}
		*/
	while(_iterationStatus == CONTINUE)
	{

			if(totStps < _newtonSettings->getNewtMax())
			{
				// Determination of Jacobian (Fortran-format)

					if(_broydenMethod==2)
					{
						//-_jac*_fold = _delta_s
					dgemv_(&_N, &_dimSys, &_dimSys, &_dMINUSONE, _jac, &_dimSys, _fold, &_iONE, &_dZERO, _delta_s, &_iONE);


					// Calculate new _y
					daxpy_(&_dimSys, &_dONE, _delta_s, &_iONE, _y, &_iONE);

					// Calculate new f
					calcFunction(_y,_fnew);

					// _jac*_fnew
					dgemv_(&_N, &_dimSys, &_dimSys, &_dONE, _jac, &_dimSys, _fnew, &_iONE, &_dZERO, _jacHelpVec1, &_iONE);
					// _jac*_delta_s
					dgemv_(&_T, &_dimSys, &_dimSys, &_dMINUSONE, _jac, &_dimSys, _delta_s, &_iONE, &_dZERO, _jacHelpVec2, &_iONE);
					//_delta_f is in f_old
					daxpy_(&_dimSys, &_dMINUSONE, _fnew, &_iONE, _fold, &_iONE);

					//delta
					delta = ddot_(&_dimSys, _jacHelpVec2, &_iONE, _fold, &_iONE);
					if(delta > 0)
						delta = 1/delta;
					else
						delta = 1e-16;

					// jacobian update accordings to Broyden2
					dger_(&_dimSys, &_dimSys, &delta, _jacHelpVec1, &_iONE, _jacHelpVec2 ,&_iONE, _jac, &_dimSys);



					double fnorm = dnrm2_(&_dimSys, _fnew, &_iONE);

					// Reset
					memcpy(_fold,_fnew, _dimSys*sizeof(double));

					//Stopping Criterion
					if( fnorm < _fNormTol)
					{
						//std::cout << totStps << std::endl;
						_iterationStatus = DONE;
						break;
					}

					}
					else if (_broydenMethod==1)
					{
					/*
						memcpy(_jacHelpMat2,_jac,_dimSys*_dimSys*sizeof(double));
						dgesv_(&_dimSys,&dimRHS,_jac,&_dimSys,_iHelp,_fold,&_dimSys,&irtrn);

						for(int i=0;i<_dimSys;i++)
							_y[i] -= _fold[i];

						calcFunction(_y,_fnew);

						for(int i=0;i<_dimSys;i++)
							_fold[i] = -_fold[i];

						outerprod(_dimSys, _fnew,_fold,_jacHelpMat1);
						delta = 0;
						double delta=0.0;
						for (int i=0;i<_dimSys;i++)
							delta+=_fold[i]*_fold[i];

						for(int i=0;i<_dimSys*_dimSys;i++)
							if(delta!=0)
								_jac[i] = _jacHelpMat2[i] + _jacHelpMat1[i]/delta;

						double fnorm = vecMaxNorm(_dimSys,_fnew);

						// Reset
						memcpy(_fold,_fnew, _dimSys*sizeof(double));

						//Stopping Criterion
						if( fnorm < _fNormTol)
						{
							_iterationStatus = DONE;
							break;
						}
					*/
					}

					// Increase counter
					++ totStps;

				}
				else
				{
					throw ModelicaSimulationError(ALGLOOP_SOLVER,"error solving nonlinear system");
				}

		}
	}
}

IAlgLoopSolver::ITERATIONSTATUS Newton::getIterationStatus()
{
	return _iterationStatus;
}


void Newton::calcFunction(const double *y, double *residual)
{
	_algLoop->setReal(y);
	_algLoop->evaluate();
	_algLoop->getRHS(residual);
}

void Newton::stepCompleted(double time)
{

}



void Newton::calcJacobian()
{

	for(int j=0; j<_dimSys; ++j)
	{
		// Reset variables for every column
		memcpy(_jacHelpVec1,_y,_dimSys*sizeof(double));
		double stepsize=1.e-6;//+(1.e-6*_yHelp[j]);

		// Finitializee difference
		_jacHelpVec1[j] += stepsize;

		calcFunction(_jacHelpVec1,_fHelp);

		// Build Jacobian in Fortran format
		for(int i=0; i<_dimSys; ++i)
			_jac[i+j*_dimSys] = (_fHelp[i] - _fold[i]) / stepsize;

		_yHelp[j] -=stepsize;
	}

}
void Newton::restoreOldValues()
{

}

void Newton::restoreNewValues()
{

}


/** @} */ // end of solverNewton

