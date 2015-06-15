#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
/** @addtogroup solverKinsol
 *
 *  @{
 */
#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>


extern "C" void dgesv_(long int *n, long int *nrhs, double *J, long int *ldj, long int *pivot,double *b, long int *ldb, long int *idid);

#if defined(__TRICORE__)
  #include <include/kinsol/kinsol.h>
#endif


int kin_fCallback(N_Vector y,N_Vector fval, void *user_data)
{
    Kinsol* myKinsol =  (Kinsol*)(user_data);
    return  myKinsol->kin_f(y,fval,user_data);
}


Kinsol::Kinsol(IAlgLoop* algLoop, INonLinSolverSettings* settings)
    : _algLoop            (algLoop)
    , _kinsolSettings     ((INonLinSolverSettings*)settings)
    , _y                  (NULL)
    , _y0                 (NULL)
    , _yScale             (NULL)
    , _fScale             (NULL)
    , _f                  (NULL)
    , _helpArray          (NULL)
    , _ihelpArray         (NULL)
    , _zeroVec            (NULL)
    , _currentIterate     (NULL)
    , _jac                (NULL)
    , _fHelp              (NULL)
    , _yHelp              (NULL)
    , _dimSys             (0)
    , _fnorm              (10.0)
    , _currentIterateNorm (100.0)
    , _firstCall          (true)
    , _iterationStatus    (CONTINUE)
    , _Kin_y              (NULL)
    , _Kin_y0             (NULL)
    , _Kin_yScale         (NULL)
    , _Kin_fScale         (NULL)
    , _kinMem             (NULL)
{
    _data = ((void*)this);
}

Kinsol::~Kinsol()
{
    if(_y)                delete []  _y;
    if(_y0)               delete []  _y0;
    if(_yScale)           delete []  _yScale;
    if(_fScale)           delete []  _fScale;
    if(_f)                delete []  _f;
    if(_helpArray)        delete []  _helpArray;
    if(_ihelpArray)       delete []  _ihelpArray;
    if(_jac)              delete []  _jac;
    if(_fHelp)            delete []  _fHelp;
    if(_zeroVec)          delete []  _zeroVec;
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
            if(_y)               delete []  _y;
            if(_y0)              delete []  _y0;
            if(_yScale)          delete []  _yScale;
            if(_fScale)          delete []  _fScale;
            if(_f)               delete []  _f;
            if(_helpArray)       delete []  _helpArray;
            if(_ihelpArray)      delete []  _ihelpArray;
            if(_jac)             delete []  _jac;
            if(_yHelp)           delete []  _yHelp;
            if(_fHelp)           delete []  _fHelp;
            if(_zeroVec)         delete []  _zeroVec;
            if(_currentIterate)  delete []  _currentIterate;

            _y                = new double[_dimSys];
            _y0               = new double[_dimSys];
            _yScale           = new double[_dimSys];
            _fScale           = new double[_dimSys];
            _f                = new double[_dimSys];
            _helpArray        = new double[_dimSys];
            _ihelpArray       = new long int[_dimSys];
            _zeroVec          = new double[_dimSys];
            _currentIterate   = new double[_dimSys];

            _jac              = new double[_dimSys*_dimSys];
            _yHelp            = new double[_dimSys];
            _fHelp            = new double[_dimSys];

            _algLoop->getReal(_y);
            _algLoop->getReal(_y0);

            memset(_f, 0, _dimSys*sizeof(double));
            memset(_helpArray, 0, _dimSys*sizeof(double));
            memset(_ihelpArray, 0, _dimSys*sizeof(long int));
            memset(_yHelp, 0, _dimSys*sizeof(double));
            memset(_fHelp, 0, _dimSys*sizeof(double));
            memset(_jac, 0, _dimSys*_dimSys*sizeof(double));
            memset(_zeroVec, 0, _dimSys*sizeof(double));
            memset(_currentIterate, 0, _dimSys*sizeof(double));

            _algLoop->getNominalReal(_yScale);

            for (int i=0; i<_dimSys; i++)
              _yScale[i] = 1/_yScale[i];

            _Kin_y = N_VMake_Serial(_dimSys, _y);
            _Kin_y0 = N_VMake_Serial(_dimSys, _y0);
            _Kin_yScale = N_VMake_Serial(_dimSys, _yScale);
            _Kin_fScale = N_VMake_Serial(_dimSys, _fScale);
            _kinMem = KINCreate();

            //Set Options
            //idid = KINSetNumMaxIters(_kinMem, _kinsolSettings->getNewtMax());
            idid = KINInit(_kinMem, kin_fCallback, _Kin_y);
            if (check_flag(&idid, (char *)"KINInit", 1))
                throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol::initialize()");
            idid = KINSetUserData(_kinMem, _data);
            if (check_flag(&idid, (char *)"KINSetUserData", 1))
                throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol::initialize()");

            #ifdef USE_SUNDIALS_LAPACK
              KINLapackDense(_kinMem, _dimSys);
            #else
              KINDense(_kinMem, _dimSys);
            #endif //USE_SUNDIALS_LAPACK

            idid = KINSetErrFile(_kinMem, NULL);
            idid = KINSetNumMaxIters(_kinMem, 1000);
            //idid = KINSetEtaForm(_kinMem, KIN_ETACHOICE2);

            _fnormtol  = 1.e-12;     /* function tolerance */
            _scsteptol = 1.e-12;     /* step tolerance */

            idid = KINSetFuncNormTol(_kinMem, _fnormtol);
            idid = KINSetScaledStepTol(_kinMem, _scsteptol);
            idid = KINSetRelErrFunc(_kinMem, 1e-14);

            _counter = 0;
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

        _algLoop->evaluate();
        _algLoop->getRHS(_f);
        _algLoop->getSystemMatrix(_jac);
        dgesv_(&dimSys,&dimRHS,_jac,&dimSys,_ihelpArray,_f,&dimSys,&irtrn);
        memcpy(_y,_f,_dimSys*sizeof(double));
        _algLoop->setReal(_y);
    }
    else if(_algLoop->isLinearTearing())
    {
        long int dimRHS  = 1;          // Dimension of right hand side of linear system (=b)
        long int dimSys = _dimSys;
        long int irtrn  = 0;          // Retrun-flag of Fortran code

        _algLoop->setReal(_zeroVec);
        _algLoop->evaluate();
        _algLoop->getRHS(_f);
        _algLoop->getReal(_y);
        calcJacobian(_f,_y);
        dgesv_(&dimSys, &dimRHS, _jac, &dimSys, _ihelpArray, _f,&dimSys,&irtrn);
        for(int i=0; i<_dimSys; i++)
          _f[i]*=-1.0;
        memcpy(_y, _f, _dimSys*sizeof(double));
        _algLoop->setReal(_y);
        //_algLoop->evaluate();
        if(irtrn != 0)
            throw ModelicaSimulationError(ALGLOOP_SOLVER,"error solving linear tearing system");
        else
          _iterationStatus = DONE;
    }
    else
    {
        _counter++;
        _eventRetry = false;

        // Try Dense first
        ////////////////////////////
        for(int i=0;i<_dimSys;i++) // Reset Scaling
          _fScale[i] = 1.0;


        solveNLS();
        if(_iterationStatus == DONE)
          return;
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

/*
    if(_iterationStatus == DONE)
      return;

    //Try iterative Solvers
    /////////////////////////////////////
    for(int i=0;i<_dimSys;i++) // Reset Scaling
      _fScale[i] = 1.0;

    KINSpgmr(_kinMem,_dimSys);
    _iterationStatus = CONTINUE;
    solveNLS();

    if(_iterationStatus == DONE)
      return;
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
      return;

    for(int i=0;i<_dimSys;i++) // Reset Scaling
      _fScale[i] = 1.0;

    KINSpbcg(_kinMem,_dimSys);
    _iterationStatus = CONTINUE;
    solveNLS();
    if(_iterationStatus == DONE)
      return;
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
      return;

    if(_eventRetry)
    {
      memcpy(_y, _helpArray ,_dimSys*sizeof(double));
      _iterationStatus = CONTINUE;
      return;
    }

    if(_iterationStatus == SOLVERERROR && !_eventRetry)
      throw ModelicaSimulationError(ALGLOOP_SOLVER,"Nonlinear solver failed!");
*/
    }
}

IAlgLoopSolver::ITERATIONSTATUS Kinsol::getIterationStatus()
{
    return _iterationStatus;
}


void Kinsol::calcFunction(const double *y, double *residual)
{
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

   for(int i=0;i<_dimSys;i++)
     {
        if(!(boost::math::isfinite(residual[i])) || !(boost::math::isfinite(y[i])))
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
        maxStepsStart = 1e4,
        maxSteps = maxStepsStart,
        maxStepsHigh =1e8,
        maxStepsLow = 1,
        limit = maxStepsHigh,
        locTol = 1e-6;

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
        //if(_fnorm/euclidNorm(_dimSys,_yScale) < 1e-4)
        if(idid != KIN_SUCCESS &&  _fnorm < locTol && _fnorm < _currentIterateNorm)
        {
           _currentIterateNorm = _fnorm;
       for(int i=0;i<_dimSys;i++)
        _currentIterate[i] = _y[i];
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
          limit = maxStepsHigh;
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
                    if (maxSteps > limit)
                    {
                        // The starting maxSteps is reached again -> Try Linesearch
                        if (limit == maxStepsStart)
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
                            limit = maxStepsStart;
                        }
                    }else
                        maxSteps *= 10;
                }
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
                // Try diffent maxStsps
                /*
        if (maxSteps > limit)
                {
                    // The starting maxSteps is reached again -> Solvererror
                    if (maxSteps > maxStepsStart)
                    {
            */
            _iterationStatus = SOLVERERROR;
            /*
                    } else // Try lower maxStep values
                    {
                        maxSteps = maxStepsLow;
                        limit = maxStepsStart;
                    }
                }else
                    maxSteps *= 10;
          */
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

bool Kinsol::isfinite(double* u, int dim)
{
    for(int i=0;i<dim;i++)
    {
        if(!(boost::math::isfinite(u[i])))
            return false;
    }
    return true;
}
void Kinsol::calcJacobian(double* f,double* y)
{
    double y_old;
    memcpy(_yHelp,y,_dimSys*sizeof(double));
    for(int j=0; j<_dimSys; ++j)
    {
        // Reset variables for every column
        double stepsize=1;//+(1.e-6*_yHelp[j]);

        y_old=_yHelp[j];
        // Finitializee difference
        _yHelp[j] += stepsize;

        calcFunction(_yHelp,_fHelp);

        // Build Jacobian in Fortran format
        for(int i=0; i<_dimSys; ++i)
            _jac[i+j*_dimSys] = (_fHelp[i] - f[i]) / stepsize;

        _yHelp[j] = y_old;
    }
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
/** @} */ // end of solverKinsol