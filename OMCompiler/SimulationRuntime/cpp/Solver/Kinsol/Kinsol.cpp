#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
/** @addtogroup solverKinsol
*
*  @{
*/

#if defined(__vxworks)
#include<wvLib.h>
//#include <klu.h>
#else
//#include <Solver/KLU/klu.h>
#endif
//#include<wvLib.h>

#include<Core/Math/ILapack.h>
#include <Solver/Kinsol/FactoryExport.h>

#include <nvector/nvector_serial.h>
#include <kinsol/kinsol.h>

#include <kinsol/kinsol_spgmr.h>
#include <kinsol/kinsol_dense.h>

#include <kinsol/kinsol_spbcgs.h>
#include <kinsol/kinsol_sptfqmr.h>
/*will be used with new sundials version
#include <kinsol/kinsol_klu.h>
*/
#include <kinsol/kinsol_direct.h>
#include <sundials/sundials_dense.h>
#include <kinsol/kinsol_impl.h>


#include <Core/Utils/extension/logger.hpp>
#include <Solver/Kinsol/KinsolLapack.h>
#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>
#if defined(__TRICORE__)
#include <include/kinsol/kinsol.h>
#endif

//#include <Core/Utils/numeric/bindings/lapack/driver/gesv.hpp>
#include <Core/Utils/numeric/bindings/ublas.hpp>
#include <Core/Utils/numeric/utils.h>






/**
Forward declarations for used external C functions
*/
int kin_fCallback(N_Vector y, N_Vector fval, void *user_data);
/*will be used with new sundials version
int kin_SlsSparseJacFn(N_Vector u, N_Vector fu,SlsMat J, void *user_data,N_Vector tmp1, N_Vector tmp2);
int kin_DlsDenseJacFn(long int N, N_Vector u, N_Vector fu,DlsMat J, void *user_data,N_Vector tmp1, N_Vector tmp2);
*/


/**\Callback function for Kinsol to calculate right hand side, calls internal Kinsol member function
 *  \param [in] y variables vector
 *  \param [in] fval right hand side vecotre
 *  \param [in] user_data user data pointer is used to access Kinsol instance
 *  \return status value
 */
int kin_fCallback(N_Vector y,N_Vector fval, void *user_data)
{
	Kinsol* myKinsol =  (Kinsol*)(user_data);
	return  myKinsol->kin_f(y,fval,user_data);
}
 /**\Callback function for Kinsol to calculate sparse jacobian matrix, calls internal Kinsol member function
 *  \param [in] u Parameter_Description
 *  \param [in] fu Parameter_Description
 *  \param [out] J Parameter_Description
 *  \param [in] user_data Parameter_Description
 *  \param [in] tmp1 Parameter_Description
 *  \param [in] tmp2 Parameter_Description
 *  \return Return_Description
 *  \details Details
 */
/*will be used with new sundials version
int kin_SlsSparseJacFn(N_Vector u, N_Vector fu,SlsMat J, void *user_data,N_Vector tmp1, N_Vector tmp2)
{
	Kinsol* myKinsol =  (Kinsol*)(user_data);
	return  myKinsol->kin_JacSparse(u, fu,J,user_data,tmp1, tmp2);
}*/

/**\Callback function for Kinsol to calculate dense jacobian matrix, calls internal Kinsol member function
 *  \param [in] N Parameter_Description
 *  \param [in] u Parameter_Description
 *  \param [in] fu Parameter_Description
 *  \param [out] J Parameter_Description
 *  \param [in] user_data Parameter_Description
 *  \param [in] tmp1 Parameter_Description
 *  \param [in] tmp2 Parameter_Description
 *  \return Return_Description
 *  \details Details
 */
/*will be used with new sundials version
int kin_DlsDenseJacFn(long int N, N_Vector u, N_Vector fu,DlsMat J, void *user_data,N_Vector tmp1, N_Vector tmp2)
{
	Kinsol* myKinsol =  (Kinsol*)(user_data);
	return  myKinsol->kin_JacDense(N,u,fu,J,user_data,tmp1,tmp2);
}
*/

Kinsol::Kinsol(INonLinSolverSettings* settings,shared_ptr<INonLinearAlgLoop> algLoop)
    :AlgLoopSolverDefaultImplementation()
	,_algLoop            (algLoop)
	, _kinsolSettings     ((INonLinSolverSettings*)settings)
	, _y                  (NULL)
	, _y0                 (NULL)
	, _yScale             (NULL)
	, _fScale             (NULL)
	, _f                  (NULL)
	, _helpArray          (NULL)
	, _currentIterate     (NULL)
	, _jac                (NULL)
	, _fHelp              (NULL)
	, _yHelp              (NULL)

	, _fnorm              (10.0)
	, _currentIterateNorm (100.0)
	, _firstCall          (true)
	, _usedCompletePivoting (false)
	, _usedIterativeSolver (false)
	, _iterationStatus    (CONTINUE)
	, _Kin_y              (NULL)
	, _Kin_y0             (NULL)
	, _Kin_yScale         (NULL)
	, _Kin_fScale         (NULL)
	, _kinMem             (NULL)
	/*
	, _kluSymbolic 			(NULL)
    , _kluNumeric			(NULL)
    , _kluCommon			(NULL)
    , _Ai					(NULL)
    , _Ap					(NULL)
    , _Ax					(NULL)
*/
    , _fValid(false)
    , _y_old(NULL)
    , _y_new(NULL)
  , _solverErrorNotificationGiven(false)

{
	_max_dimSys = 100;
	_max_dimZeroFunc=50;
	_data = ((void*)this);
	if (_algLoop)
	{
		_single_instance = false;
		AlgLoopSolverDefaultImplementation::initialize(_algLoop->getDimZeroFunc(),_algLoop->getDimReal());
	}
	else
	{
		_single_instance = true;
		AlgLoopSolverDefaultImplementation::initialize(_max_dimZeroFunc,_max_dimSys);
	}
}

Kinsol::~Kinsol()
{
	if(_y)                delete []  _y;
	if(_y0)               delete []  _y0;
    if(_y_old)            delete [] _y_old;
    if(_y_new)            delete [] _y_new;
	if(_yScale)           delete []  _yScale;
	if(_fScale)           delete []  _fScale;
	if(_f)                delete []  _f;
	if(_helpArray)        delete []  _helpArray;
	if(_jac)              delete []  _jac;
	if(_fHelp)            delete []  _fHelp;
	if(_currentIterate)   delete []  _currentIterate;
	if(_yHelp)            delete []  _yHelp;
	if(_Kin_y)

		N_VDestroy_Serial(_Kin_y);
	if(_Kin_y0)
		N_VDestroy_Serial(_Kin_y0);
	if(_Kin_yScale)
		N_VDestroy_Serial(_Kin_yScale);
	if(_Kin_fScale)
		N_VDestroy_Serial(_Kin_fScale);
	if(_kinMem)
		KINFree(&_kinMem);


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

void Kinsol::initialize()
{
	int idid;
    if(!_algLoop)
        throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
	if(_firstCall)
	   _algLoop->initialize();

	_firstCall = false;
    _sparse = _algLoop->getUseSparseFormat();
    _dimSys =_algLoop->getDimReal();

			// Initialization of vector of unknowns
			if(_y)               delete []  _y;
			if(_y0)              delete []  _y0;
			if(_yScale)          delete []  _yScale;
			if(_fScale)          delete []  _fScale;
			if(_f)               delete []  _f;
			if(_helpArray)       delete []  _helpArray;
			if(_jac)             delete []  _jac;
			if(_yHelp)           delete []  _yHelp;
			if(_fHelp)           delete []  _fHelp;
			if(_currentIterate)  delete []  _currentIterate;
            if(_y_old)           delete [] _y_old;
            if(_y_new)           delete [] _y_new;
			_y                = new double[_dimSys];
			_y0               = new double[_dimSys];
			_yScale           = new double[_dimSys];
			_fScale           = new double[_dimSys];
			_f                = new double[_dimSys];
			_helpArray        = new double[_dimSys];
			_currentIterate   = new double[_dimSys];
            _y_old            = new double[_dimSys];
            _y_new            = new double[_dimSys];
			_jac              = new double[_dimSys*_dimSys];
			_yHelp            = new double[_dimSys];
			_fHelp            = new double[_dimSys];

			_algLoop->getReal(_y);
			_algLoop->getReal(_y0);
            _algLoop->getReal(_y_new);
            _algLoop->getReal(_y_old);
			memset(_f, 0, _dimSys*sizeof(double));
			memset(_helpArray, 0, _dimSys*sizeof(double));
			memset(_yHelp, 0, _dimSys*sizeof(double));
			memset(_fHelp, 0, _dimSys*sizeof(double));
			memset(_jac, 0, _dimSys*_dimSys*sizeof(double));
			memset(_currentIterate, 0, _dimSys*sizeof(double));

			_algLoop->getNominalReal(_yScale);

			for (int i=0; i<_dimSys; i++)
				if(_yScale[i] != 0)
					_yScale[i] = 1/_yScale[i];
				else
					_yScale[i] = 1;


			if (_Kin_y)

				N_VDestroy_Serial(_Kin_y);
			if (_Kin_y0)
				N_VDestroy_Serial(_Kin_y0);
			if (_Kin_yScale)
				N_VDestroy_Serial(_Kin_yScale);
			if (_Kin_fScale)
				N_VDestroy_Serial(_Kin_fScale);
			if (_kinMem)
				KINFree(&_kinMem);

			_Kin_y = N_VMake_Serial(_dimSys, _y);
			_Kin_y0 = N_VMake_Serial(_dimSys, _y0);
			_Kin_yScale = N_VMake_Serial(_dimSys, _yScale);
			_Kin_fScale = N_VMake_Serial(_dimSys, _fScale);
			_kinMem = KINCreate();

			/*
			//sparse
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


			//Set Options
			//idid = KINSetNumMaxIters(_kinMem, _kinsolSettings->getNewtMax());
			idid = KINInit(_kinMem, kin_fCallback, _Kin_y);
			if (check_flag(&idid, (char *)"KINInit", 1))
				throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol::initialize()");
			idid = KINSetUserData(_kinMem, _data);
			if (check_flag(&idid, (char *)"KINSetUserData", 1))
				throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol::initialize()");

			KINDense(_kinMem, _dimSys);

			/*will be used with new sundials version
			if(_algLoop->isLinearTearing())
			{
				//sparse matrix active
				const sparsematrix_t& A = _algLoop->getSystemSparseMatrix();
				unsigned int nonzeros= A.nnz();

				idid = KINKLU(_kinMem, _dimSys,nonzeros);
				if (check_flag(&idid, (char *)"KINKLU", 1))
				throw ModelicaSimulationError(ALGLOOP_SOLVER,"error init  linear klu solver ");
				idid = KINSlsSetSparseJacFn(_kinMem, kin_SlsSparseJacFn);
				if (check_flag(&idid, (char *)"KINSlsSetSparseJacFn", 1))
				throw ModelicaSimulationError(ALGLOOP_SOLVER,"error int  sparse callback function");

				//dense matrix active
				idid =KINDlsSetDenseJacFn(_kinMem, kin_DlsDenseJacFn);
				if (check_flag(&idid, (char *)"KINDlsSetDenseJacFn", 1))
				throw ModelicaSimulationError(ALGLOOP_SOLVER,"error in  dense jacobian callback function");


			}*/

			idid = KINSetErrFile(_kinMem, NULL);
			idid = KINSetNumMaxIters(_kinMem, 50);
			//idid = KINSetEtaForm(_kinMem, KIN_ETACHOICE2);

			_fnormtol  = 1.e-13;     /* function tolerance */
			_scsteptol = 1.e-13;     /* step tolerance */

			idid = KINSetFuncNormTol(_kinMem, _fnormtol);
			idid = KINSetScaledStepTol(_kinMem, _scsteptol);
			idid = KINSetRelErrFunc(_kinMem, 1e-14);

			_counter = 0;

	LOGGER_WRITE("Kinsol: initialized",LC_NLS,LL_DEBUG);
}

void Kinsol::solve(shared_ptr<INonLinearAlgLoop> algLoop, bool first_solve)
{
	if (first_solve)
	{
		_algLoop = algLoop;
		_firstCall = true;
	}
	if (_algLoop != algLoop)
		throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
	solve();
}
bool* Kinsol::getConditionsWorkArray()
{
	return AlgLoopSolverDefaultImplementation::getConditionsWorkArray();

}
bool* Kinsol::getConditions2WorkArray()
{

	return AlgLoopSolverDefaultImplementation::getConditions2WorkArray();
 }


 double* Kinsol::getVariableWorkArray()
 {

	return AlgLoopSolverDefaultImplementation::getVariableWorkArray();

 }


void Kinsol::solve()
{
	if (_firstCall)
	{
		initialize();
	}

	if(!_algLoop)
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
	_iterationStatus = CONTINUE;

	int idid;
	_counter++;
	_eventRetry = false;
	_iterationStatus = CONTINUE;
	//get variables vectors for last accepted step
	_algLoop->getReal(_y);
	_algLoop->getRealStartValues(_y0);

	// Try Dense first
	////////////////////////////
	if(_usedCompletePivoting || _usedIterativeSolver)
	{
		KINDense(_kinMem, _dimSys);
		_usedCompletePivoting = false;
		_usedIterativeSolver = false;
	}

	for(int i=0;i<_dimSys;i++) // Reset Scaling
		_fScale[i] = 1.0;

	solveNLS();
	if(_iterationStatus == DONE)
	{
		_algLoop->setReal(_y);
		_algLoop->evaluate();

		return;
	}
	else  // Try Scaling
	{
		_iterationStatus = CONTINUE;
		_algLoop->setReal(_y0);
		_algLoop->evaluate();
		_algLoop->getRHS(_fScale);
		for(int i=0;i<_dimSys;i++)
		{

			if(abs(_fScale[i]) >1.0)
			_fScale[i] = abs(1/_fScale[i]);
			else
			_fScale[i] = 1;

		}

		_iterationStatus = CONTINUE;

		solveNLS();
	}

	if(_iterationStatus == DONE)
	{
		_algLoop->setReal(_y);
		_algLoop->evaluate();

		return;
	}

	// Try complete pivoting
	///////////////////////////////////////
	//_usedCompletePivoting = true;
	//

	//KINLapackCompletePivoting(_kinMem, _dimSys);
	//
	//for(int i=0;i<_dimSys;i++) // Reset Scaling
	//	_fScale[i] = 1.0;

	//_iterationStatus = CONTINUE;
	//solveNLS();
	//if(_iterationStatus == DONE)
	//	return;
	//else  // Try Scaling
	//{
	//	_iterationStatus = CONTINUE;
	//	_algLoop->setReal(_y0);
	//	_algLoop->evaluate();
	//	_algLoop->getRHS(_fScale);
	//	for(int i=0;i<_dimSys;i++)
	//	{
	//
	//		if(abs(_fScale[i]) >1.0)
	//		_fScale[i] = abs(1/_fScale[i]);
	//		else
	//		_fScale[i] = 1;

	//
	//	}
	//	_iterationStatus = CONTINUE;
	//	solveNLS();
	//}
	//
	//if(_iterationStatus == DONE)
	//	return;

	//Try iterative Solvers
	/////////////////////////////////
	_usedIterativeSolver = true;

	for(int i=0;i<_dimSys;i++) // Reset Scaling
		_fScale[i] = 1.0;

	KINSpgmr(_kinMem,_dimSys);

	_iterationStatus = CONTINUE;
	solveNLS();

	if(_iterationStatus == DONE)
	{
		_algLoop->setReal(_y);
		_algLoop->evaluate();

		return;
	}
	else  // Try Scaling
	{
		_iterationStatus = CONTINUE;
		_algLoop->setReal(_y0);
		_algLoop->evaluate();
		_algLoop->getRHS(_fScale);
		for(int i=0;i<_dimSys;i++)
		{
			if(abs(_fScale[i]) >1.0)
			_fScale[i] = abs(1/_fScale[i]);
			else
			_fScale[i] = 1;
		}
		_iterationStatus = CONTINUE;
		solveNLS();

	}
	if(_iterationStatus == DONE)
	{
		_algLoop->setReal(_y);
		_algLoop->evaluate();
		return;
	}

	for(int i=0;i<_dimSys;i++) // Reset Scaling
		_fScale[i] = 1.0;

	KINSpbcg(_kinMem,_dimSys);
	_iterationStatus = CONTINUE;
	solveNLS();
	if(_iterationStatus == DONE)
	{
		_algLoop->setReal(_y);
		_algLoop->evaluate();
		return;
	}
	else  // Try Scaling
	{
		_iterationStatus = CONTINUE;
		_algLoop->setReal(_y0);
		_algLoop->evaluate();
		_algLoop->getRHS(_fScale);
		for(int i=0;i<_dimSys;i++)
		{
			if(abs(_fScale[i]) >1.0)
				_fScale[i] = abs(1/_fScale[i]);
			else
				_fScale[i] = 1;
		}
		solveNLS();
	}
	if(_iterationStatus == DONE)
	{
		_algLoop->setReal(_y);
		_algLoop->evaluate();
		return;
	}

	if(_eventRetry)
	{
		memcpy(_y, _helpArray ,_dimSys*sizeof(double));
		_iterationStatus = CONTINUE;
		return;
	}

	if(_iterationStatus == SOLVERERROR && !_eventRetry)
	{

	  if(_kinsolSettings->getContinueOnError())
	  {
		if(!_solverErrorNotificationGiven)
		{
		  LOGGER_WRITE("Kinsol: Solver error detected. The simulation will continue, but the results may be incorrect.",LC_NLS,LL_WARNING);
		  _solverErrorNotificationGiven = true;
		}
	  }
	  else

		throw ModelicaSimulationError(ALGLOOP_SOLVER,"Nonlinear solver failed!");
	}
}

INonLinearAlgLoopSolver::ITERATIONSTATUS Kinsol::getIterationStatus()
{
	return _iterationStatus;
}


void Kinsol::calcFunction(const double *y, double *residual)
{

	if(!_algLoop)
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
	_fValid = true;
	_algLoop->setReal(y);
	try
	{
		_algLoop->evaluate();
	} catch (std::exception & ex)
	{
		_fValid = false;
	}
	_algLoop->getRHS(residual);

	// Check for numerical overflow to avoid endless iterations
	for(int i=0;i<_dimSys;i++)
	{
		if(!isfinite(residual[i]) || !isfinite(y[i]))
			_fValid = false;
	}
}

int Kinsol::kin_f(N_Vector y,N_Vector fval, void *user_data)
{

	((Kinsol*) user_data)->calcFunction(NV_DATA_S(y),NV_DATA_S(fval));

	if(((Kinsol*) user_data)->_fValid)
		return(0);
	else
		return(1);
}
/**\brief internal function called by Kinsol callback function to calculate sparse jacobian
 *  \param [in] u  variables vector
 *  \param [in] fu right hand side vector
 *  \param [out] J sparse jacobian
 *  \param [in] user_data  is used to access instance of Kinsol
 *  \param [in] tmp1 Parameter_Description
 *  \param [in] tmp2 Parameter_Description
 *  \return status value
 *  \details Details
 */
/*will be used with new sundials version
int Kinsol::kin_JacSparse(N_Vector u, N_Vector fu,SlsMat J, void *user_data,N_Vector tmp1, N_Vector tmp2)
{


	const sparsematrix_t& A = _algLoop->getSystemSparseMatrix();
	unsigned int nonzeros= A.nnz();
	int const* Ti = bindings::begin_compressed_index_major (A);
	int const* Tj = bindings::begin_index_minor (A);
	double const* Ax = bindings::begin_value (A);

	memcpy(J->data,Ax,nonzeros*sizeof(double));
	memcpy(J->rowvals,Tj,nonzeros*sizeof(int));
	memcpy(J->colptrs,Ti,(_dimSys+1)*sizeof(int));

	return 0;

}
*/
/**\brief internal function called by Kinsol callback function to calculate dense jacobian
 *  \param [in] N system dimension
 *  \param [in] u variables vector
 *  \param [in] fu right hand side vector
 *  \param [out] J dense jacobian matirx
 *  \param [in] user_data  is used to access instance of Kinsol
 *  \param [in] tmp1 Parameter_Description
 *  \param [in] tmp2 Parameter_Description
 *  \return status value
 *  \details Details
 */
/*will be used with new sundials version
int Kinsol::kin_JacDense(long int N, N_Vector u, N_Vector fu,DlsMat J, void *user_data,N_Vector tmp1, N_Vector tmp2)
{
	const matrix_t& A = _algLoop->getSystemMatrix();

	for(size_t i = 0; i < A.size1(); ++i)
	{

		const ublas::matrix_column<const  matrix_t > col (A, i);
		std::copy(col.begin(), col.end(), J->cols[i]);

	}
	return 0;
}
*/
void Kinsol::stepCompleted(double time)
{
	memcpy(_y0,_y,_dimSys*sizeof(double));
    memcpy(_y_old,_y_new,_dimSys*sizeof(double));
    memcpy(_y_new,_y,_dimSys*sizeof(double));
}

int Kinsol::check_flag(void *flagvalue, char *funcname, int opt)
{
	int *errflag;

	/* Check if SUNDIALS function returned NULL pointer - no memory allocated */
	if (opt == 0 && flagvalue == NULL) {
		fprintf(stderr,
			"\nSUNDIALS_ERROR: %s() failed - returned NULL pointer\n\n",
			funcname);
		return(1);
	}

	/* Check if flag < 0 */
	else if (opt == 1) {
		errflag = (int *) flagvalue;
		if (*errflag < 0) {
			fprintf(stderr,
				"\nSUNDIALS_ERROR: %s() failed with flag = %d\n\n",
				funcname, *errflag);
			return(1);
		}
	}

	/* Check if function returned NULL pointer - no memory allocated */
	else if (opt == 2 && flagvalue == NULL) {
		fprintf(stderr,
			"\nMEMORY_ERROR: %s() failed - returned NULL pointer\n\n",
			funcname);
		return(1);
	}

	return(0);
}

void Kinsol::solveNLS()
{
	int
		method = KIN_NONE,//
		iter = 0,
		idid;
	double
		maxStepsStart = 0,
		maxSteps = maxStepsStart,
		maxStepsHigh =1e8,
		locTol =5e-7,
	    delta = 1e-14;

	_currentIterateNorm = 100.0;

	while(_iterationStatus == CONTINUE)
	{
		iter++;
		//Increase max. Newton Step size
		idid = KINSetMaxNewtonStep(_kinMem, maxSteps);

		// Reset initial guess
		memcpy(_y,_y0,_dimSys*sizeof(double));

		// Call Kinsol
		idid = KINSol(_kinMem, _Kin_y, method, _Kin_yScale, _Kin_fScale);

		KINGetFuncNorm(_kinMem, &_fnorm);
		if(!_fValid && (idid==KIN_FIRST_SYSFUNC_ERR)) throw ModelicaSimulationError(ALGLOOP_SOLVER,"Algloop could not be evaluated! Evaluation failed at the first call.");
		//if(_fnorm/euclidNorm(_dimSys,_yScale) < 1e-4)
		if(idid != KIN_SUCCESS &&  _fnorm < locTol && _fnorm < _currentIterateNorm)
		{
			_currentIterateNorm = _fnorm;
			memcpy(_currentIterate,_y,_dimSys*sizeof(double));
		}

		// Check the return status for possible restarts
		switch (idid){
			// Success
		case KIN_SUCCESS:
			_iterationStatus = DONE;
			break;

			// Fine initial guess
		case KIN_INITIAL_GUESS_OK:
			_iterationStatus = DONE;
			break;

			// Did we reach a saddle point
		case KIN_STEP_LT_STPTOL:
			KINGetFuncNorm(_kinMem, &_fnorm);
			if(_fnorm < _fnormtol)
			{
				_iterationStatus = DONE;
			}else
			{
				check4EventRetry(_y);
				if(method==KIN_NONE)
				{
					method = KIN_LINESEARCH;
					maxSteps = maxStepsStart;
				}
				else
					_iterationStatus = SOLVERERROR;
			}
			break;

			// MaxStep too low
		case KIN_MXNEWT_5X_EXCEEDED:
			KINGetFuncNorm(_kinMem, &_fnorm);
			if(_fnorm < _fnormtol)
			{
				_iterationStatus = DONE;
			}else
			{
				check4EventRetry(_y);
				if(method == KIN_NONE)
				{
					if (maxSteps == maxStepsHigh)
					{
						method = KIN_LINESEARCH;
						maxSteps = maxStepsStart;
					} else
						maxSteps = maxStepsHigh;
				}
				else // already trying Linesearch
						_iterationStatus = SOLVERERROR;
			  }

			break;

			// Max Iterations exceeded
		case KIN_MAXITER_REACHED:
			KINGetFuncNorm(_kinMem, &_fnorm);
			if(_fnorm < _fnormtol)
			{
				_iterationStatus = DONE;
			}else
			{
				check4EventRetry(_y);
				if(method == KIN_NONE)
				{
						method = KIN_LINESEARCH;
						maxSteps = maxStepsStart;

				}else // already trying Linesearch
				{
					if (maxSteps > 0 && maxSteps < 1)
					{
						_iterationStatus = SOLVERERROR;
					} else
						if (maxSteps==0)
							maxSteps = maxStepsHigh;
						else
							maxSteps /= 10;
				}
			}
			break;

			// Linesearch did not converge
		case KIN_LINESEARCH_NONCONV:
			KINGetFuncNorm(_kinMem, &_fnorm);
			if(_fnorm < _fnormtol)
			{
				_iterationStatus = DONE;
			}else
			{
				check4EventRetry(_y);

				if(delta < 1e-16)
					_iterationStatus = SOLVERERROR;
				else
				{
					delta /= 1e2;
					idid = KINSetRelErrFunc(_kinMem, delta);
				}

			}
			break;
			// Other failures (setup etc) -> directly break
		default:

			KINGetFuncNorm(_kinMem, &_fnorm);
			if(_fnorm < _fnormtol)        // Initial guess may be the solution
				_iterationStatus = DONE;
			else
				_iterationStatus = SOLVERERROR;
			break;
		}
	}
	// Check if the best found solution suffices
	if(_iterationStatus == SOLVERERROR && _currentIterateNorm < locTol)
	{
		_iterationStatus = DONE;
		for(int i=0;i<_dimSys;i++)
			_y[i] = _currentIterate[i];
	}



}
/**
 *  \brief Restores all algloop variables for a output step
 *  \return Return_Description
 *  \details Details
 */
void Kinsol::restoreOldValues()
{
     memcpy(_y,_y_old,_dimSys*sizeof(double));

}
    /**
 *  \brief Restores all algloop variables for last output step
 *  \return Return_Description
 *  \details Details
 */
void Kinsol::restoreNewValues()
{
    memcpy(_y,_y_new,_dimSys*sizeof(double));
}




void Kinsol::check4EventRetry(double* y)
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
/** @} */ // end of solverKinsol
