#include "stdafx.h"
#include "Kinsol.h"
#include "KinsolSettings.h"



Kinsol::Kinsol(IAlgLoop* algLoop, INonLinSolverSettings* settings)
    : _algLoop      (algLoop)
    , _kinsolSettings  ((INonLinSolverSettings*)settings)
    , _y        (NULL)
    , _y0       (NULL)
    , _yScale   (NULL)
    , _fScale   (NULL)
    , _f        (NULL)
    , _helpArray    (NULL)
    , _jac    (NULL)
    , _dimSys      (0)
	, _fnorm(10.0)
	, _currentIterateNorm (100.0)
    , _firstCall    (true)
    , _iterationStatus  (CONTINUE)
{
    _data = ((void*)this);
}

Kinsol::~Kinsol()
{
    if(_y)      delete []  _y;
    if(_y0)      delete []  _y0;
    if(_yScale)     delete []  _yScale;
    if(_fScale)     delete []  _fScale;
    if(_f)      delete []  _f;
    if(_helpArray)      delete []  _helpArray;
    if(_jac)      delete []  _jac;

    N_VDestroy_Serial(_Kin_y);
    N_VDestroy_Serial(_Kin_y0);
    N_VDestroy_Serial(_Kin_yScale);
    N_VDestroy_Serial(_Kin_fScale);

    KINFree(&_kinMem);
}

void Kinsol::initialize()
{
    int idid;

    _firstCall = false;

    //(Re-) Initialization of algebraic loop
    _algLoop->initialize();

    // Dimension of the system (number of variables)
    int
        dimDouble  = _algLoop->getDimReal(),
        dimInt    = 0,
        dimBool    = 0;

    // Check system dimension
    if (dimDouble != _dimSys)
    {
        _dimSys = dimDouble;

        if(_dimSys > 0)
        {
            // Initialization of vector of unknowns
            if(_y)         delete []  _y;
            if(_y0)       delete []  _y0;
            if(_yScale)     delete []  _yScale;
            if(_fScale)     delete []  _fScale;
            if(_f)         delete []  _f;
            if(_helpArray)     delete []  _helpArray;
            if(_jac)     delete []  _jac;

            _y      = new double[_dimSys];
            _y0         = new double[_dimSys];
            _yScale     = new double[_dimSys];
            _fScale     = new double[_dimSys];
            _f      = new double[_dimSys];
            _helpArray    = new double[_dimSys];
            _jac      = new double[_dimSys*_dimSys];

            _algLoop->getReal(_y);
            _algLoop->getReal(_y0);

            memset(_f,0,_dimSys*sizeof(double));
            memset(_helpArray,0,_dimSys*sizeof(double));


            _algLoop->getNominalReal(_yScale);

            for (int i=0;i<_dimSys;i++)
            {
                _fScale[i] = 1;
            }

            _Kin_y = N_VMake_Serial(_dimSys, _y);
            _Kin_y0 = N_VMake_Serial(_dimSys, _y0);
            _Kin_yScale = N_VMake_Serial(_dimSys, _yScale);
            _Kin_fScale = N_VMake_Serial(_dimSys, _fScale);
            _kinMem = KINCreate();

            //Set Options
            //idid = KINSetNumMaxIters(_kinMem, _kinsolSettings->getNewtMax());
            idid = KINInit(_kinMem, kin_fCallback, _Kin_y);
            if (check_flag(&idid, "KINInit", 1))
                throw std::invalid_argument("Kinsol::initialize()");
            idid = KINSetUserData(_kinMem, _data);
            if (check_flag(&idid, "KINSetUserData", 1))
                throw std::invalid_argument("Kinsol::initialize()");

            idid = KINSetErrFile(_kinMem, NULL);

            idid = KINSetNumMaxIters(_kinMem, 1000);

            _fnormtol  = 1.e-12;     /* function tolerance */
            _scsteptol = 1.e-12;     /* step tolerance */

            idid = KINSetFuncNormTol(_kinMem, _fnormtol);
            idid = KINSetScaledStepTol(_kinMem, _scsteptol);

        }
        else
        {
            _iterationStatus = SOLVERERROR;
        }
    }


}

void Kinsol::solve()
{
    if (_firstCall)
        initialize();

    _iterationStatus = CONTINUE;

    if(_algLoop->isLinear())
    {
        long int dimRHS  = 1;          // Dimension of right hand side of linear system (=b)
        long int dimSys = _dimSys;
        long int irtrn  = 0;          // Retrun-flag of Fortran code        _algLoop->getReal(_y);

        _algLoop->getRHS(_f);
        _algLoop->getSystemMatrix(_jac);
        dgesv_(&dimSys,&dimRHS,_jac,&dimSys,_helpArray,_f,&dimSys,&irtrn);
        memcpy(_y,_f,_dimSys*sizeof(double));
        _algLoop->setReal(_y);
    }
    else
    {
        _eventRetry = false;
        // Try Dense first
        //std::cerr << "Try dense...";
		
		/*
		for(int i=0;i<_dimSys;i++) 
			_y0[i] += _y[i] * 0.1;
		memcpy(_y,_y0,_dimSys*sizeof(double));
		*/
		
		/*
		KINSetNoResMon(_kinMem,TRUE);
		KINSetMaxSetupCalls(_kinMem,1);
		KINSetMaxSubSetupCalls(_kinMem,1);
		KINSetEtaForm(_kinMem,KIN_ETACHOICE1);
		*/

        KINDense(_kinMem, _dimSys);
        solveNLS();
        if(_iterationStatus == DONE)
            return;

        if(_eventRetry)
        {
            //std::cerr << "Event Retry";
            memcpy(_y, _helpArray ,_dimSys*sizeof(double));
            _iterationStatus = CONTINUE;
            return;
        }

        //std::cerr << "Try Spgmr...";
        // Try Spgmr
        KINSpgmr(_kinMem,5);
        _iterationStatus = CONTINUE;
        solveNLS();
        if(_iterationStatus == DONE)
            return;

        if(_eventRetry)
        {
            memcpy(_y, _helpArray ,_dimSys*sizeof(double));
            _iterationStatus = CONTINUE;
            return;
        }


        // Try Spbcg
        KINSpbcg(_kinMem,4);
        _iterationStatus = CONTINUE;
        solveNLS();
        if(_iterationStatus == DONE)
            return;
        if(_eventRetry)
        {
            memcpy(_y, _helpArray ,_dimSys*sizeof(double));
            _iterationStatus = CONTINUE;
            return;
        }

        // Try Sptfqmr

		KINSptfqmr(_kinMem, _dimSys);
        _iterationStatus = CONTINUE;
        solveNLS();
        if(_iterationStatus == DONE)
            return;

        if(_eventRetry)
        {
            memcpy(_y, _helpArray ,_dimSys*sizeof(double));
            _iterationStatus = CONTINUE;
            return;
        }

		/*
        if(_iterationStatus == SOLVERERROR && !_eventRetry)
            throw std::runtime_error("Nonlinear solver failed!");
			*/

        if(_eventRetry)
        {
            memcpy(_y, _helpArray ,_dimSys*sizeof(double));
            _iterationStatus = CONTINUE;
            return;
        }
    }

}

IAlgLoopSolver::ITERATIONSTATUS Kinsol::getIterationStatus()
{
    return _iterationStatus;
}


void Kinsol::calcFunction(const double *y, double *residual)
{
    _algLoop->setReal(y);
    _algLoop->evaluate();
    _algLoop->getRHS(residual);
}

int Kinsol::kin_fCallback(N_Vector y,N_Vector fval, void *user_data)
{
    ((Kinsol*) user_data)->calcFunction(NV_DATA_S(y),NV_DATA_S(fval));

    return(0);
}



void Kinsol::stepCompleted(double time)
{
    memcpy(_y0,_y,_dimSys*sizeof(double));
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
        method = KIN_NONE,
        iter = 0,
        idid;
    double 
        maxStepsStart = 1e3*max(euclidNorm(_dimSys,_yScale),euclidNorm(_dimSys,_yScale)),
        maxSteps = maxStepsStart,
        maxStepsHigh = 1e15,
        maxStepsLow = 1e-3,
        limit = maxStepsHigh;

    while(_iterationStatus == CONTINUE)
    {
        iter++;
        //Increase max. Newton Step size
        idid = KINSetMaxNewtonStep(_kinMem, maxSteps);

        // Reset initial guess
        //memcpy(_y,_y0,_dimSys*sizeof(double));

        // Call Kinsol
        idid = KINSol(_kinMem, _Kin_y, method, _Kin_yScale, _Kin_yScale);

        // std::cerr << "Kinsol finished with idid = "<<  idid ;
        //Is the solution finite
        if(!isfinite(_y,_dimSys))
        {
            memcpy(_y,_y0,_dimSys*sizeof(double));
            _iterationStatus = SOLVERERROR;
            break;
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
            if(_fnorm/euclidNorm(_dimSys,_yScale) < 1e-1)
            {
                _iterationStatus = DONE;
            }else
            {
                check4EventRetry(_y);
                method = KIN_LINESEARCH;
                maxSteps = maxStepsStart;
                limit = maxStepsHigh;
            }
			if(_fnorm > _currentIterateNorm)
				memcpy(_y,_y0,_dimSys*sizeof(double));
			else
				_currentIterateNorm = _fnorm;
            break;

            // MaxStep too low
        case KIN_MXNEWT_5X_EXCEEDED:
                check4EventRetry(_y);
                if(method == KIN_NONE)
                {
                    if (maxSteps > limit)
                    {	
                        // The starting maxSteps is reached again -> Try Linesearch 
                        if (maxSteps > maxStepsStart)
                        {
                            method = KIN_LINESEARCH;
                            maxSteps = maxStepsStart;
                            limit = maxStepsHigh;
                        } else // Try lower maxStep values
                        {
                            maxSteps = maxStepsLow;
                            limit = maxStepsStart;
                        }
                    }
                    else
                        maxSteps *= 10;

                }else // already trying Linesearch
                {
                    if (maxSteps > limit)
                    {	
                        // The starting maxSteps is reached again -> Solvererror 
                        if (maxSteps > maxStepsStart)
                        {
                            _iterationStatus = SOLVERERROR;
                        } else // Try lower maxStep values
                        {
                            maxSteps = maxStepsLow;
                            limit = maxStepsLow;
                        }
                    }else
                        maxSteps *= 10;
                }
				KINGetFuncNorm(_kinMem, &_fnorm);
				if(_fnorm > _currentIterateNorm)
					memcpy(_y,_y0,_dimSys*sizeof(double));
				else
					_currentIterateNorm = _fnorm;
                break;

                // Max Iterations exceeded
            case KIN_MAXITER_REACHED:
                check4EventRetry(_y);
                // Try Linesearch
                if(method == KIN_NONE)
                {
                    // Check lower maxSteps then Linesearch
                    if (limit == maxStepsStart)
                    {
                        method = KIN_LINESEARCH;
                        maxSteps = maxStepsStart;
                        limit = maxStepsHigh;
                    } else
                    {
                        maxSteps = maxStepsLow;
                        limit = maxStepsStart;
                    }
                } else
                {
                    _iterationStatus = SOLVERERROR;
                }
				KINGetFuncNorm(_kinMem, &_fnorm);
				if(_fnorm > _currentIterateNorm)
					memcpy(_y,_y0,_dimSys*sizeof(double));
				else
					_currentIterateNorm = _fnorm;
                break;

                // Linesearch did not converge
            case KIN_LINESEARCH_NONCONV:
                check4EventRetry(_y);
                // Try diffent maxStsps
                if (maxSteps > limit)
                    {	
                        // The starting maxSteps is reached again -> Solvererror 
                        if (maxSteps > maxStepsStart)
                        {
                            _iterationStatus = SOLVERERROR;
                        } else // Try lower maxStep values
                        {
                            maxSteps = maxStepsLow;
                            limit = maxStepsLow;
                        }
                    }else
                        maxSteps *= 10;
                KINGetFuncNorm(_kinMem, &_fnorm);
				if(_fnorm > _currentIterateNorm)
					memcpy(_y,_y0,_dimSys*sizeof(double));
				else
					_currentIterateNorm = _fnorm;
				break;
			// Other failures (setup etc) -> directly break
            default:
                _iterationStatus = SOLVERERROR;
				KINGetFuncNorm(_kinMem, &_fnorm); 
				if(_fnorm > _currentIterateNorm)
					memcpy(_y,_y0,_dimSys*sizeof(double));
				 else
					_currentIterateNorm = _fnorm;
                break;
        }
    }
}

bool Kinsol::isfinite(double* u, int dim)
{
    for(int i=0;i<dim;i++)
    {
        if(!(boost::math::isfinite(u[i])))
            return false;
    }
    return true;
}

void Kinsol::check4EventRetry(double* y)
{
    _algLoop->setReal(y); 
    if(!(_algLoop->isConsistent()) && !_eventRetry)
    {
        memcpy(_helpArray, y,_dimSys*sizeof(double));
        _eventRetry = true;
    }
}