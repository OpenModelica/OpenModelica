/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/** @addtogroup solverKinsol
*
*  @{
*/

#include <Core/ModelicaDefine.h>  // This has to be first to include
#include <Core/Modelica.h>        // But... why?

#if defined(__vxworks)
#include<wvLib.h>
#endif

#include <kinsol/kinsol.h>                  // Main header file for KINSOL
#include <nvector/nvector_serial.h>         // Default serial vectors
#include <sunlinsol/sunlinsol_dense.h>      // Default dense linear solver
#include <sunlinsol/sunlinsol_spgmr.h>      // Scaled, Preconditioned, Generalized Minimum Residual iterative linear solver
#include <sunlinsol/sunlinsol_spbcgs.h>     // Scaled, Preconditioned, Bi-Conjugate Gradient, Stabilized iterative linear solver

#include <Solver/Kinsol/FactoryExport.h>
#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>

#include <Core/Math/ILapack.h>
#include <Core/Utils/extension/logger.hpp>
#include <Core/Utils/numeric/bindings/ublas.hpp>
#include <Core/Utils/numeric/utils.h>

/**\Callback function for Kinsol to calculate right hand side, calls internal Kinsol member function
 *  \param [in] y variables vector
 *  \param [in] fval right hand side vecotre
 *  \param [in] user_data user data pointer is used to access Kinsol instance
 *  \return status value
 */
int kin_fCallback(N_Vector y,N_Vector fval, void *user_data) {
  Kinsol* myKinsol =  (Kinsol*)(user_data);
  return  myKinsol->kin_f(y,fval,user_data);
}

/**
 * @brief Construct a new Kinsol:: Kinsol object
 *
 * @param settings    General parameters for a non-linear solver object
 * @param algLoop     Algebraic loop
 */
Kinsol::Kinsol(INonLinSolverSettings* settings, shared_ptr<INonLinearAlgLoop> algLoop)
  :AlgLoopSolverDefaultImplementation()
  ,_algLoop               (algLoop)
  , _kinsolSettings       ((INonLinSolverSettings*)settings)
  , _y                    (NULL)
  , _y0                   (NULL)
  , _yScale               (NULL)
  , _fScale               (NULL)
  , _f                    (NULL)
  , _helpArray            (NULL)
  , _currentIterate       (NULL)
  , _jac                  (NULL)
  , _fHelp                (NULL)
  , _yHelp                (NULL)
  , _fnorm                (10.0)
  , _currentIterateNorm   (100.0)
  , _firstCall            (true)
  , _usedCompletePivoting (false)
  , _usedIterativeSolver  (false)
  , _iterationStatus      (CONTINUE)
  , _Kin_y                (NULL)
  , _Kin_y0               (NULL)
  , _Kin_yScale           (NULL)
  , _Kin_fScale           (NULL)
  , _Kin_ySolver          (NULL)
  , _Kin_linSol           (NULL)
  , _Kin_J                (NULL)
  , _kinMem               (NULL)
  , _fValid               (false)
  , _y_old                (NULL)
  , _y_new                (NULL)
  , _solverErrorNotificationGiven(false)
{
  _max_dimSys = 100;
  _max_dimZeroFunc=50;
  _data = ((void*)this);
  if (_algLoop) {
    _single_instance = false;
    AlgLoopSolverDefaultImplementation::initialize(_algLoop->getDimZeroFunc(),_algLoop->getDimReal());
  } else {
    _single_instance = true;
    AlgLoopSolverDefaultImplementation::initialize(_max_dimZeroFunc,_max_dimSys);
  }
}

/**
 * @brief Destroy the Kinsol:: Kinsol object
 *
 */
Kinsol::~Kinsol() {
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

  N_VDestroy_Serial(_Kin_y);
  N_VDestroy_Serial(_Kin_y0);
  N_VDestroy_Serial(_Kin_yScale);
  N_VDestroy_Serial(_Kin_fScale);
  N_VDestroy_Serial(_Kin_ySolver);
  SUNMatDestroy(_Kin_J);
  SUNLinSolFree(_Kin_linSol);
  KINFree(&_kinMem);
}

/**
 * @brief Initialize Kinsol solver
 *
 * If the solver was already initialized reinitialize the solver.
 *
 */
void Kinsol::initialize() {
  int idid;
  if(!_algLoop) {
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
  }
  if(_firstCall) {
    _algLoop->initialize();
  }

  _firstCall = false;
  _sparse = _algLoop->getUseSparseFormat();
  _dimSys =_algLoop->getDimReal();

  // Free data, if it's not NULL allready
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
  N_VDestroy_Serial(_Kin_y);
  N_VDestroy_Serial(_Kin_y0);
  N_VDestroy_Serial(_Kin_yScale);
  N_VDestroy_Serial(_Kin_fScale);
  N_VDestroy(_Kin_ySolver);
  SUNMatDestroy(_Kin_J);
  SUNLinSolFree(_Kin_linSol);
  KINFree(&_kinMem);

  // Initialize vectors
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

  // Scale y
  _algLoop->getNominalReal(_yScale);
  for (int i=0; i<_dimSys; i++) {
    if(_yScale[i] != 0) {
      _yScale[i] = 1/_yScale[i];
    } else {
      _yScale[i] = 1;
    }
  }


  // Create Kinsol memory
  _Kin_y = N_VMake_Serial(_dimSys, _y);
  _Kin_y0 = N_VMake_Serial(_dimSys, _y0);
  _Kin_yScale = N_VMake_Serial(_dimSys, _yScale);
  _Kin_fScale = N_VMake_Serial(_dimSys, _fScale);
  _Kin_ySolver = N_VNew_Serial(_dimSys);
  _kinMem = KINCreate();

  // Set internal memory
  idid = KINInit(_kinMem, kin_fCallback, _Kin_y);
  if (check_flag(&idid, (char *)"KINInit", 1)) {
    throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol::initialize()");
  }

  // Initialize dense linear solver
  _Kin_J = SUNDenseMatrix(_dimSys, _dimSys);
  _Kin_linSol = SUNLinSol_Dense(_Kin_ySolver, _Kin_J);
  if (_Kin_linSol == NULL) {
    fprintf(stderr,"\nSUNDIALS_ERROR: SUNLinSol_Dense() failed - returned NULL pointer\n\n");
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "Kinsol::solve()");
  }
  idid = KINSetLinearSolver(_kinMem, _Kin_linSol, _Kin_J);
  if (check_flag(&idid, (char *)"KINSetLinearSolver", 1)) {
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "Kinsol::initialize()");
  }

  // Set optional inputs
  idid = KINSetUserData(_kinMem, _data);
  if (check_flag(&idid, (char *)"KINSetUserData", 1)) {
    throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol::initialize()");
  }

  idid = KINSetErrFile(_kinMem, NULL);
  idid = KINSetNumMaxIters(_kinMem, 50);

  _fnormtol  = 1.e-13;     /* function tolerance */
  _scsteptol = 1.e-13;     /* step tolerance */

  idid = KINSetFuncNormTol(_kinMem, _fnormtol);
  idid = KINSetScaledStepTol(_kinMem, _scsteptol);
  idid = KINSetRelErrFunc(_kinMem, 1e-14);

  _counter = 0;

  LOGGER_WRITE("Kinsol: initialized",LC_NLS,LL_DEBUG);
}


/**
 * @brief Wrapper for Kinsol::solve()
 *
 * Sets algLoop and first_solve
 *
 * @param algLoop
 * @param first_solve
 */
void Kinsol::solve(shared_ptr<INonLinearAlgLoop> algLoop, bool first_solve)
{
  if (first_solve) {
    _algLoop = algLoop;
    _firstCall = true;
  }
  if (_algLoop != algLoop) {
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
  }
  solve();
}


/**
 * @brief  Solve algebraic loop with former initialzed Kinsol solver
 *
 * _algLoop and _firstCall has to be set outside this function.
 */
void Kinsol::solve() {
  // Initialize at first call
  if (_firstCall) {
    initialize();
  }

  if(!_algLoop) {
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
  }

  int idid;
  _counter++;
  _eventRetry = false;
  _iterationStatus = CONTINUE;

  //get variables vectors for last accepted step
  _algLoop->getReal(_y);
  _algLoop->getRealStartValues(_y0);

  // Reinitialize dense linear solver if last call was with comlpete pivoting or iterative solver
  if(_usedCompletePivoting || _usedIterativeSolver)
  {
    idid = SUNLinSolFree(_Kin_linSol);
    if (check_flag(&idid, (char *)"SUNLinSolFree", 1)) {
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "Kinol::solve()");
    }
    _Kin_linSol = SUNLinSol_Dense(_Kin_ySolver, _Kin_J);
    if (_Kin_linSol == NULL) {
      fprintf(stderr,"\nSUNDIALS_ERROR: SUNLinSol_Dense() failed - returned NULL pointer\n\n");
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "Kinsol::solve()");
    }
    idid = KINSetLinearSolver(_kinMem, _Kin_linSol, _Kin_J);
    if (check_flag(&idid, (char *)"KINSetUserData", 1)) {
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "Kinsol::initialize()");
    }

    _usedCompletePivoting = false;
    _usedIterativeSolver = false;
  }

  // Reset Scaling
  for(int i=0;i<_dimSys;i++) {
    _fScale[i] = 1.0;
  }

  // Try Dense first
  ////////////////////////////
  solveNLS();
  if(_iterationStatus == DONE)
  {
    _algLoop->setReal(_y);
    _algLoop->evaluate();
    return;
  }

  // Try Dense with scaling
  ////////////////////////////
  _iterationStatus = CONTINUE;
  _algLoop->setReal(_y0);
  _algLoop->evaluate();
  _algLoop->getRHS(_fScale);
  for(int i=0;i<_dimSys;i++) {
    if(abs(_fScale[i]) >1.0) {
      _fScale[i] = abs(1/_fScale[i]);
    } else {
      _fScale[i] = 1;
    }
  }
  solveNLS();
  if(_iterationStatus == DONE) {
    _algLoop->setReal(_y);
    _algLoop->evaluate();
    return;
  }

  // Try SPGMR solver
  // Scaled, Preconditioned, Generalized Minimum Residual iterative linear solver
  /////////////////////////////////
  _iterationStatus = CONTINUE;
  _usedIterativeSolver = true;

  // Reset Scaling
  for(int i=0;i<_dimSys;i++) {
    _fScale[i] = 1.0;
  }

  // Free linear solver and initialize linear solver
  idid = SUNLinSolFree(_Kin_linSol);
  if (check_flag(&idid, (char *)"SUNLinSolFree", 1)) {
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "Kinsol::solve()");
  }
  _Kin_linSol = SUNLinSol_SPGMR(_Kin_ySolver, PREC_NONE, _dimSys /* Krylov subspaces */);
  if (_Kin_linSol == NULL) {
    fprintf(stderr,"\nSUNDIALS_ERROR: SUNLinSol_SPGMR() failed - returned NULL pointer\n\n");
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "Kinsol::solve()");
  }
  idid = KINSetLinearSolver(_kinMem, _Kin_linSol, NULL);
  if (check_flag(&idid, (char *)"KINSetLinearSolver", 1)) {
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "Kinsol::solve()");
  }

  // Solve
  solveNLS();
  if(_iterationStatus == DONE) {
    _algLoop->setReal(_y);
    _algLoop->evaluate();
    return;
  }

  // Try SPGMR solver with scaling
  /////////////////////////////////
  _iterationStatus = CONTINUE;
  _algLoop->setReal(_y0);
  _algLoop->evaluate();
  _algLoop->getRHS(_fScale);
  for(int i=0;i<_dimSys;i++) {
    if(abs(_fScale[i]) >1.0) {
      _fScale[i] = abs(1/_fScale[i]);
    } else {
    _fScale[i] = 1;
    }
  }
  solveNLS();
  if(_iterationStatus == DONE) {
    _algLoop->setReal(_y);
    _algLoop->evaluate();
    return;
  }

  // Try SPBCG solver
  // Scaled, Preconditioned, Generalized Minimum Residual iterative linear solver
  /////////////////////////////////
  _iterationStatus = CONTINUE;

  // Reset Scaling
  for(int i=0;i<_dimSys;i++) {
    _fScale[i] = 1.0;
  }

  // Free linear solver and initialize linear solver
  idid = SUNLinSolFree(_Kin_linSol);
  if (check_flag(&idid, (char *)"SUNLinSolFree", 1)) {
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "Kinsol::solve()");
  }
  _Kin_linSol = SUNLinSol_SPBCGS(_Kin_ySolver, PREC_NONE, _dimSys /* Krylov subspaces */);
  if (_Kin_linSol == NULL) {
    fprintf(stderr,"\nSUNDIALS_ERROR: SUNLinSol_SPGMR() failed - returned NULL pointer\n\n");
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "Kinsol::solve()");
  }
  idid = KINSetLinearSolver(_kinMem, _Kin_linSol, _Kin_J);
  if (check_flag(&idid, (char *)"KINSetLinearSolver", 1)) {
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "Kinsol::solve()");
  }

  // Solve
  solveNLS();
  if(_iterationStatus == DONE) {
    _algLoop->setReal(_y);
    _algLoop->evaluate();
    return;
  }

  // Try SPBCG solver with scaling
  /////////////////////////////////
  _iterationStatus = CONTINUE;
  _algLoop->setReal(_y0);
  _algLoop->evaluate();
  _algLoop->getRHS(_fScale);
  for(int i=0;i<_dimSys;i++) {
    if(abs(_fScale[i]) >1.0) {
      _fScale[i] = abs(1/_fScale[i]);
    } else {
      _fScale[i] = 1;
    }
  }
  solveNLS();
  if(_iterationStatus == DONE) {
    _algLoop->setReal(_y);
    _algLoop->evaluate();
    return;
  }

  // TODO: Whats this event stuff doing????
  if(_eventRetry) {
    memcpy(_y, _helpArray ,_dimSys*sizeof(double));
    _iterationStatus = CONTINUE;
    return;
  }

  // Give up
  /////////////////////////////////
  if(_iterationStatus == SOLVERERROR && !_eventRetry) {
    if(_kinsolSettings->getContinueOnError()) {
      if(!_solverErrorNotificationGiven) {
        LOGGER_WRITE("Kinsol: Solver error detected. The simulation will continue, but the results may be incorrect.",LC_NLS,LL_WARNING);
        _solverErrorNotificationGiven = true;
      }
    } else {
      throw ModelicaSimulationError(ALGLOOP_SOLVER,"Nonlinear solver failed!");
    }
  }
}

bool* Kinsol::getConditionsWorkArray() {
  return AlgLoopSolverDefaultImplementation::getConditionsWorkArray();
}


bool* Kinsol::getConditions2WorkArray() {
  return AlgLoopSolverDefaultImplementation::getConditions2WorkArray();
}


double* Kinsol::getVariableWorkArray() {
  return AlgLoopSolverDefaultImplementation::getVariableWorkArray();
}

INonLinearAlgLoopSolver::ITERATIONSTATUS Kinsol::getIterationStatus() {
  return _iterationStatus;
}


void Kinsol::calcFunction(const double *y, double *residual) {
  if(!_algLoop) {
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
  }
  _fValid = true;
  _algLoop->setReal(y);
  try {
    _algLoop->evaluate();
  } catch (std::exception & ex) {
    _fValid = false;
  }
  _algLoop->getRHS(residual);

  // Check for numerical overflow to avoid endless iterations
  for(int i=0;i<_dimSys;i++) {
    if(!isfinite(residual[i]) || !isfinite(y[i])) {
      _fValid = false;
    }
  }
}

int Kinsol::kin_f(N_Vector y,N_Vector fval, void *user_data) {
  ((Kinsol*) user_data)->calcFunction(NV_DATA_S(y),NV_DATA_S(fval));

  if(((Kinsol*) user_data)->_fValid) {
    return(0);
  } else {
    return(1);
  }
}

void Kinsol::stepCompleted(double time) {
  memcpy(_y0,_y,_dimSys*sizeof(double));
  memcpy(_y_old,_y_new,_dimSys*sizeof(double));
  memcpy(_y_new,_y,_dimSys*sizeof(double));
}

int Kinsol::check_flag(void *flagvalue, char *funcname, int opt) {
  int *errflag;

  // Check if SUNDIALS function returned NULL pointer - no memory allocated
  if (opt == 0 && flagvalue == NULL) {
    fprintf(stderr, "\nSUNDIALS_ERROR: %s() failed - returned NULL pointer\n\n", funcname);
    return(1);
  }

  // Check if flag < 0
  else if (opt == 1) {
    errflag = (int *) flagvalue;
    if (*errflag < 0) {
      fprintf(stderr, "\nSUNDIALS_ERROR: %s() failed with flag = %d\n\n", funcname, *errflag);
      return(1);
    }
  }

  // Check if function returned NULL pointer - no memory allocated
  else if (opt == 2 && flagvalue == NULL) {
    fprintf(stderr, "\nMEMORY_ERROR: %s() failed - returned NULL pointer\n\n", funcname);
    return(1);
  }

  return(0);
}

void Kinsol::solveNLS() {
  int
    method = KIN_NONE,
    iter = 0,
    idid;
  double
    maxStepsStart = 0,
    maxSteps = maxStepsStart,
    maxStepsHigh =1e8,
    locTol =5e-7,
      delta = 1e-14;

  _currentIterateNorm = 100.0;

  while(_iterationStatus == CONTINUE) {
    iter++;
    //Increase max. Newton Step size
    idid = KINSetMaxNewtonStep(_kinMem, maxSteps);

    // Reset initial guess
    memcpy(_y,_y0,_dimSys*sizeof(double));

    // Call Kinsol
    idid = KINSol(_kinMem, _Kin_y, method, _Kin_yScale, _Kin_fScale);

    KINGetFuncNorm(_kinMem, &_fnorm);
    if(!_fValid && (idid==KIN_FIRST_SYSFUNC_ERR)) {
      throw ModelicaSimulationError(ALGLOOP_SOLVER,"Algloop could not be evaluated! Evaluation failed at the first call.");
    }
    if(idid != KIN_SUCCESS &&  _fnorm < locTol && _fnorm < _currentIterateNorm) {
      _currentIterateNorm = _fnorm;
      memcpy(_currentIterate,_y,_dimSys*sizeof(double));
    }

    // Check the return status for possible restarts
    switch (idid) {
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
        if(_fnorm < _fnormtol) {
          _iterationStatus = DONE;
        } else {
          check4EventRetry(_y);
          if(method==KIN_NONE) {
            method = KIN_LINESEARCH;
            maxSteps = maxStepsStart;
          } else {
            _iterationStatus = SOLVERERROR;
          }
        }
        break;

      // MaxStep too low
      case KIN_MXNEWT_5X_EXCEEDED:
        KINGetFuncNorm(_kinMem, &_fnorm);
        if(_fnorm < _fnormtol) {
          _iterationStatus = DONE;
        } else {
          check4EventRetry(_y);
          if(method == KIN_NONE) {
            if (maxSteps == maxStepsHigh) {
              method = KIN_LINESEARCH;
              maxSteps = maxStepsStart;
            } else {
              maxSteps = maxStepsHigh;
            }
          } else { // already trying Linesearch
              _iterationStatus = SOLVERERROR;
          }
        }
        break;

      // Max Iterations exceeded
      case KIN_MAXITER_REACHED:
        KINGetFuncNorm(_kinMem, &_fnorm);
        if(_fnorm < _fnormtol) {
          _iterationStatus = DONE;
        } else {
          check4EventRetry(_y);
          if(method == KIN_NONE) {
            method = KIN_LINESEARCH;
            maxSteps = maxStepsStart;
          } else {  // already trying Linesearch
            if (maxSteps > 0 && maxSteps < 1) {
              _iterationStatus = SOLVERERROR;
            } else {
              if (maxSteps==0) {
                maxSteps = maxStepsHigh;
              } else {
                maxSteps /= 10;
              }
            }
          }
        }
        break;

      // Linesearch did not converge
      case KIN_LINESEARCH_NONCONV:
        KINGetFuncNorm(_kinMem, &_fnorm);
        if(_fnorm < _fnormtol) {
          _iterationStatus = DONE;
        } else {
          check4EventRetry(_y);
          if(delta < 1e-16) {
            _iterationStatus = SOLVERERROR;
          } else {
            delta /= 1e2;
            idid = KINSetRelErrFunc(_kinMem, delta);
          }
        }
        break;

      // Other failures (setup etc) -> directly break
      default:
        KINGetFuncNorm(_kinMem, &_fnorm);
        if(_fnorm < _fnormtol) {        // Initial guess may be the solution
          _iterationStatus = DONE;
        } else {
          _iterationStatus = SOLVERERROR;
        }
        break;
    }
  }

  // Check if the best found solution suffices
  if(_iterationStatus == SOLVERERROR && _currentIterateNorm < locTol) {
    _iterationStatus = DONE;
    for(int i=0;i<_dimSys;i++) {
      _y[i] = _currentIterate[i];
    }
  }
}


/**
 *  \brief Restores all algloop variables for a output step
 *  \return Return_Description
 *  \details Details
 */
void Kinsol::restoreOldValues() {
  memcpy(_y,_y_old,_dimSys*sizeof(double));
}


/**
 *  \brief Restores all algloop variables for last output step
 *  \return Return_Description
 *  \details Details
 */
void Kinsol::restoreNewValues() {
  memcpy(_y,_y_new,_dimSys*sizeof(double));
}


void Kinsol::check4EventRetry(double* y) {
  if(!_algLoop) {
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
  }
  _algLoop->setReal(y);
  if(!(_algLoop->isConsistent()) && !_eventRetry) {
    memcpy(_helpArray, y,_dimSys*sizeof(double));
    _eventRetry = true;
  }
}
/** @} */ // end of solverKinsol
