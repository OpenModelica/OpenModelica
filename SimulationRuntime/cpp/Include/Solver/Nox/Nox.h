#pragma once
/** @addtogroup solverNox
 *
 *  @{
 */



class Nox : public IAlgLoopSolver
{
public:
  Nox(INonLinearAlgLoop* algLoop, INonLinSolverSettings* settings);
  virtual ~Nox();

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

  void getsolutionandevaluate(NOX::LAPACK::Group grp);
  void solverinit();
  void createStatusTests();
  void createSolverParameters();

  //void check4EventRetry(double* y)

// Member variables
  //---------------------------------------------------------------
  INonLinSolverSettings
    *_noxSettings;     ///< Settings for the solver

  INonLinearAlgLoop
    *_algLoop;            ///< Algebraic loop to be solved

  ITERATIONSTATUS
    _iterationStatus;     ///< Output   - Denotes the status of iteration

  long int _dimSys;

  double
	  *_y,
	  *_y0,
      *_y_old,
      *_y_new,
      *_yScale;

  Teuchos::RCP<NoxLapackInterface> _noxLapackInterface;

  Teuchos::RCP<NOX::LAPACK::Group> _grp;

  //used for status tests
  Teuchos::RCP<NOX::StatusTest::NormF> _statusTestNormF;
  Teuchos::RCP<NOX::StatusTest::MaxIters> _statusTestMaxIters;
  Teuchos::RCP<NOX::StatusTest::Combo> _statusTestsCombo;

  //list of solver parameters
  Teuchos::RCP<Teuchos::ParameterList> _solverParametersPtr;

  //solver
  Teuchos::RCP<NOX::Solver::Generic> _solver;

  bool _firstCall;
  bool _generateoutput;
  bool _useDomainScaling;
};
/** @} */ // end of solverNox
