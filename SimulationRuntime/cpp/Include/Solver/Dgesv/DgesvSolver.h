#pragma once
/** @addtogroup solverDgesvSolver
 *
 *  @{
 */

class DgesvSolver : public IAlgLoopSolver
{
 public:
  DgesvSolver(ILinearAlgLoop* algLoop, ILinSolverSettings* settings);
  virtual ~DgesvSolver();

  /// (Re-) initialize the solver
  virtual void initialize();

  /// Solution of a (non-)linear system of equations
  virtual void solve();

  /// Returns the status of iteration
  virtual ITERATIONSTATUS getIterationStatus();
  virtual void stepCompleted(double time);
  virtual void restoreOldValues();
  virtual void restoreNewValues();

 private:
  // Member variables
  //---------------------------------------------------------------

  ILinearAlgLoop
    *_algLoop;            ///< Algebraic loop to be solved

  ITERATIONSTATUS
    _iterationStatus;     ///< Output   - Denotes the status of iteration

  long int
    _dimSys,              ///< Number of unknowns (=dimension of system of equations)
    *_iHelp,              ///< Pivot indices for LAPACK routines
    *_jHelp;              ///< Pivot indices for LAPACK routines

  bool
    _firstCall,           ///< Temp   - Denotes the first call to the solver, init() is called
    _hasDgesvFactors,    ///< =true if previous dgesv was called
    _hasDgetc2Factors;   ///< =true if previous dgetc2 was called

  const char*
    *_yNames;             ///< Names of variables
  double
    *_yNominal,           ///< Nominal values of variables
    *_y,                  ///< Temp   - Unknowns
    *_y0,                 ///< Temp   - Auxillary variables
    *_y_old,              ///< Temp   - Stores old solution
    *_y_new,              ///< Temp   - Stores new solution
    *_b,                  ///< Right hand side
    *_A,                  ///< Coefficients of linear system
    *_zeroVec,            ///< Zero vector
    *_fNominal;
};
/** @} */ // end of solverLinearSolver
