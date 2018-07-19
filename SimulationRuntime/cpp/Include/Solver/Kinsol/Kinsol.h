#pragma once
/** @addtogroup solverKinsol
 *
 *  @{
 */

#include "FactoryExport.h"
#include <Core/Solver/AlgLoopSolverDefaultImplementation.h>


class Kinsol : public INonLinearAlgLoopSolver,  public AlgLoopSolverDefaultImplementation
{
public:
  Kinsol(INonLinSolverSettings* settings,shared_ptr<INonLinearAlgLoop> algLoop=shared_ptr<INonLinearAlgLoop>());
  virtual ~Kinsol();

  /// (Re-) initialize the solver
  virtual void initialize();

  /// Solution of a (non-)linear system of equations
  virtual void solve();
  //solve for a single instance call
  virtual void solve(shared_ptr<INonLinearAlgLoop> algLoop,bool first_solve = false);
  /// Returns the status of iteration
  virtual ITERATIONSTATUS getIterationStatus();
  virtual void stepCompleted(double time);
  virtual void restoreOldValues();
  virtual void restoreNewValues();

  virtual bool* getConditionsWorkArray();
  virtual bool* getConditions2WorkArray();
  virtual double* getVariableWorkArray();

  int kin_f(N_Vector y, N_Vector fval, void *user_data);

 /*will be used with new sundials version
  int kin_JacSparse(N_Vector u, N_Vector fu,SlsMat J, void *user_data,N_Vector tmp1, N_Vector tmp2);
 int kin_JacDense(long int N, N_Vector u, N_Vector fu,DlsMat J, void *user_data,N_Vector tmp1, N_Vector tmp2);
 */
private:
  /// Encapsulation of determination of residuals to given unknowns
  void calcFunction(const double* y, double* residual);


  int check_flag(void *flagvalue, char *funcname, int opt);

  void solveNLS();
  void check4EventRetry(double* y);

  // Member variables
  //---------------------------------------------------------------
  INonLinSolverSettings
    *_kinsolSettings;     ///< Settings for the solver

  shared_ptr<INonLinearAlgLoop> _algLoop;            ///< Algebraic loop to be solved

  ITERATIONSTATUS
    _iterationStatus;     ///< Output   - Denotes the status of iteration


  int _dim;
  bool
    _firstCall;           ///< Temp   - Denotes the first call to the solver, init() is called

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
	  *_currentIterate,
      *_y_old,
      *_y_new;
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
    _fValid,

	_usedCompletePivoting,
	_usedIterativeSolver,

    _solverErrorNotificationGiven;


  realtype _fnorm,
    _currentIterateNorm;

   int _counter;
   //required for klu linear solver
   bool _sparse;
/*
   klu_symbolic* _kluSymbolic ;
   klu_numeric* _kluNumeric ;
   klu_common* _kluCommon ;
   int* _Ai;
   int* _Ap;
   double* _Ax;
   int _nonzeros;
*/
};
/** @} */ // end of solverKinsol
