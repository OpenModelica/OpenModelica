#pragma once
/** @addtogroup solverNox
 *
 *  @{
 */


#include <Solver/Nox/NOX_StatusTest_SgnChange.H>


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
  void LocaHomotopySolve(const int numberofhomotopytries);
  NOX::StatusTest::StatusType BasicNLSsolve();
  void addPrintingList(const Teuchos::RCP<Teuchos::ParameterList> solverParametersPtr);
  void copySolution(const Teuchos::RCP<const NOX::Solver::Generic> solver,double* const algLoopSolution);
  void printLogger();
  void divisionbyzerohandling(double const * const y0);
  bool checkwhethersolutionisnearby(double const * const y);
  bool isdivisionbyzeroerror(const std::exception &ex);
  void modifySolverParameters(const Teuchos::RCP<Teuchos::ParameterList> solverParametersPtr,const int iter);

  bool modify_y(const int counter);
  void BinRep(std::vector<double> &result, const int number);

  //void check4EventRetry(double* y)

// Member variables
  //---------------------------------------------------------------
  INonLinSolverSettings
    *_noxSettings;     ///< Settings for the solver

  INonLinearAlgLoop
    *_algLoop;            ///< Algebraic loop to be solved

  ITERATIONSTATUS
    _iterationStatus;     ///< Output   - Denotes the status of iteration

  const long int _dimSys;

  double
	  *_y,
	  *_y0,
      *_y_old,
      *_y_new,
      *_yScale,
	  _locTol,
	  _currentIterateNorm,
	  *_currentIterate;

  Teuchos::RCP<NoxLapackInterface> _noxLapackInterface;

  Teuchos::RCP<NOX::LAPACK::Group> _grp;

  //used for status tests
  Teuchos::RCP<NOX::StatusTest::NormF> _statusTestNormF;
  Teuchos::RCP<NOX::StatusTest::MaxIters> _statusTestMaxIters;
  Teuchos::RCP<NOX::StatusTest::Stagnation> _statusTestStagnation;
  Teuchos::RCP<NOX::StatusTest::Divergence> _statusTestDivergence;
  Teuchos::RCP<NOX::StatusTest::SgnChange> _statusTestSgnChange;

  Teuchos::RCP<NOX::StatusTest::Combo> _statusTestsCombo;

  //list of solver parameters
  Teuchos::RCP<Teuchos::ParameterList> _solverParametersPtr;

  //solver
  Teuchos::RCP<NOX::Solver::Generic> _solver;

  Teuchos::RCP<std::ostream> _output;

  bool _firstCall;
  bool _generateoutput;
  bool _useDomainScaling;
};
/** @} */ // end of solverNox
