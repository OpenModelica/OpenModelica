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
#ifdef SCOREP_USER_ENABLE
  SCOREP_USER_REGION_DEFINE(kinsol_initialization_handle)
  SCOREP_USER_REGION_BEGIN(kinsol_initialization_handle, "Kinsol_initialization", SCOREP_USER_REGION_TYPE_FUNCTION )
#endif
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
#ifdef SCOREP_USER_ENABLE
  SCOREP_USER_REGION_END(kinsol_initialization_handle)
#endif
}

void Kinsol::solve()
{
#ifdef SCOREP_USER_ENABLE
  SCOREP_USER_REGION_DEFINE(kinsol_solve_handle)
  SCOREP_USER_REGION_BEGIN(kinsol_solve_handle, "Kinsol_solve", SCOREP_USER_REGION_TYPE_FUNCTION )
#endif
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

    // Try Dense first

      KINDense(_kinMem, _dimSys);
    solveNLS();
    if(_iterationStatus == DONE)
      return;

    if(_eventRetry)
    {
      memcpy(_y, _helpArray ,_dimSys*sizeof(double));
      _iterationStatus = CONTINUE;
      return;
    }

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

    // Try Sptfqmr
    /*
    KINSptfqmr(_kinMem, 5);
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
    */
    //


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


    if(_iterationStatus == SOLVERERROR && !_eventRetry)
      throw std::runtime_error("Nonlinear solver failed!");

    if(_eventRetry)
    {
      memcpy(_y, _helpArray ,_dimSys*sizeof(double));
      _iterationStatus = CONTINUE;
      return;
    }
  }
#ifdef SCOREP_USER_ENABLE
  SCOREP_USER_REGION_END(kinsol_solve_handle)
#endif
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
   double maxSteps = 1e-3;
  realtype fnorm;

  while(_iterationStatus == CONTINUE)
    {
      iter++;
      //Increase max. Newton Step size
      idid = KINSetMaxNewtonStep(_kinMem, maxSteps);

      // Reset initial guess
      memcpy(_y,_y0,_dimSys*sizeof(double));

      // Call Kinsol
      idid = KINSol(_kinMem, _Kin_y, method, _Kin_yScale, _Kin_yScale);

      //Is the solution finite
      if(!isfinite(_y,_dimSys))
      {
         memcpy(_y,_y0,_dimSys*sizeof(double));
         _iterationStatus = SOLVERERROR;
         break;
      }

      // Did we reach a saddle point
      /*
      if(idid == 2)
      {
        KINGetFuncNorm(_kinMem, &fnorm);
        if(fnorm > 2.0)
        {
          idid = -99;
        }
      }
      */
      //Check of return flag
      if (idid < 0)
      {
        //did we ran into a solution that is inconsistent?
        _algLoop->setReal(_y); 
        if(!(_algLoop->isConsistent()) && !_eventRetry)
        {
          memcpy(_helpArray, _y,_dimSys*sizeof(double));
          _eventRetry = true;
        }
        // If maxstep is exceeded, increase the limit, otherwise try linesearch or exit the loop
        if(idid != KIN_MXNEWT_5X_EXCEEDED)
        {
          if(method == KIN_NONE)
          // Directly try linesearch
            iter = 14;
          else
          {
            _iterationStatus = SOLVERERROR;
            break;
          }
        }
      }
      else
      {
        _iterationStatus = DONE;
        break;
      }

      // try Linesearch after increasing the maximal stepsize
      if(iter > 13)
      {
        method = KIN_LINESEARCH;
        if(iter==14)
          maxSteps = 1e-3;
        else
          maxSteps*=10;
        // Linesearch did not help -> break
        if(iter > 20)
        {
          _iterationStatus = SOLVERERROR;
          break;
        }
      }
      else
        maxSteps *= 10;
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
