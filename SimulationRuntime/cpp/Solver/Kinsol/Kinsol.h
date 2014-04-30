
#pragma once

#include "FactoryExport.h"
#include<kinsol.h>
#include<nvector_serial.h>
#include<kinsol_dense.h>
#include<kinsol_spgmr.h>
#include <kinsol_spbcgs.h>
#include <kinsol_sptfqmr.h>
#include <boost/math/special_functions/fpclassify.hpp>
//#include<kinsol_lapack.h>


class Kinsol : public IAlgLoopSolver
{
public:

  Kinsol(IAlgLoop* algLoop,INonLinSolverSettings* settings);

  virtual ~Kinsol();

  /// (Re-) initialize the solver
  virtual void initialize();

  /// Solution of a (non-)linear system of equations
  virtual void solve();

  /// Returns the status of iteration
  virtual ITERATIONSTATUS getIterationStatus();
   virtual void stepCompleted(double time);

private:
  /// Encapsulation of determination of residuals to given unknowns
  void calcFunction(const double* y, double* residual);


  int check_flag(void *flagvalue, char *funcname, int opt);
  static int kin_fCallback(N_Vector y, N_Vector fval, void *user_data);
  void solveNLS();
  bool isfinite(double* u, int dim);
  void check4EventRetry(double* y);

  // Member variables
  //---------------------------------------------------------------
  INonLinSolverSettings
    *_kinsolSettings;     ///< Settings for the solver

  IAlgLoop
    *_algLoop;          ///< Algebraic loop to be solved

  ITERATIONSTATUS
    _iterationStatus;     ///< Output   - Denotes the status of iteration

  long int
    _dimSys;          ///< Temp   - Number of unknowns (=dimension of system of equations)

  bool
    _firstCall;         ///< Temp   - Denotes the first call to the solver, init() is called

  double
    *_y,             ///< Temp   - Unknowns
    *_f,             ///< Temp   - Residuals
  *_helpArray,
    *_y0,            ///< Temp   - Auxillary variables
  *_yScale,       ///< Temp   - Auxillary variables
  *_fScale,    ///< Temp   - Auxillary variables
  *_jac;

  double  _fnormtol,
      _scsteptol;


  N_Vector
    _Kin_y,      ///< Temp     - Initial values in the Sundials Format
  _Kin_y0,
    _Kin_yScale,
    _Kin_fScale;
  void
    *_kinMem,         ///< Temp     - Memory for the solver
    *_data;           ///< Temp     - User data. Contains pointer to Kinsol

  bool
    _eventRetry,
  _fValid;

   realtype _fnorm,
       _currentIterateNorm;
};
