#pragma once
/** @addtogroup solverKinsol
 *  
 *  @{
 */
#include "FactoryExport.h"
#include <nvector/nvector_serial.h>
#include <kinsol/kinsol.h>
#ifdef USE_SUNDIALS_LAPACK
  #include <kinsol/kinsol_lapack.h>
#else
  #include <kinsol/kinsol_spgmr.h>
  #include <kinsol/kinsol_dense.h>
#endif //USE_SUNDIALS_LAPACK
#include <kinsol/kinsol_spbcgs.h>
#include <kinsol/kinsol_sptfqmr.h>
#include <boost/math/special_functions/fpclassify.hpp>
//#include<kinsol_lapack.h>
 int kin_fCallback(N_Vector y, N_Vector fval, void *user_data);
class Kinsol : public IAlgLoopSolver
{
public:
  Kinsol(IAlgLoop* algLoop, INonLinSolverSettings* settings);
  virtual ~Kinsol();

  /// (Re-) initialize the solver
  virtual void initialize();

  /// Solution of a (non-)linear system of equations
  virtual void solve();

  /// Returns the status of iteration
  virtual ITERATIONSTATUS getIterationStatus();
  virtual void stepCompleted(double time);
  int kin_f(N_Vector y, N_Vector fval, void *user_data);
private:
  /// Encapsulation of determination of residuals to given unknowns
  void calcFunction(const double* y, double* residual);
  /// Encapsulation of determination of Jacobian
  void calcJacobian(double* f, double* y);

  int check_flag(void *flagvalue, char *funcname, int opt);

  void solveNLS();
  bool isfinite(double* u, int dim);
  void check4EventRetry(double* y);

  // Member variables
  //---------------------------------------------------------------
  INonLinSolverSettings
    *_kinsolSettings;     ///< Settings for the solver

  IAlgLoop
    *_algLoop;            ///< Algebraic loop to be solved

  ITERATIONSTATUS
    _iterationStatus;     ///< Output   - Denotes the status of iteration

  long int
    _dimSys;              ///< Temp   - Number of unknowns (=dimension of system of equations)

  bool
    _firstCall;           ///< Temp   - Denotes the first call to the solver, init() is called
  long int * _ihelpArray;
  double
    *_y,                  ///< Temp   - Unknowns
    *_f,                  ///< Temp   - Residuals
    *_helpArray,
    *_y0,                 ///< Temp   - Auxillary variables
    *_yScale,             ///< Temp   - Auxillary variables
    *_fScale,             ///< Temp   - Auxillary variables
    *_jac,
    *_yHelp,              ///< Temp   - Auxillary variables
    *_fHelp,              ///< Temp   - Auxillary variables
    *_zeroVec,
    *_currentIterate;

  double
    _fnormtol,
    _scsteptol;

  N_Vector
    _Kin_y,              ///< Temp   - Initial values in the Sundials Format
    _Kin_y0,
    _Kin_yScale,
    _Kin_fScale;

  void
    *_kinMem,            ///< Temp   - Memory for the solver
    *_data;              ///< Temp   - User data. Contains pointer to Kinsol

  bool
    _eventRetry,
    _fValid;

  realtype _fnorm,
    _currentIterateNorm;

   int _counter;
};
/** @} */ // end of solverKinsol
