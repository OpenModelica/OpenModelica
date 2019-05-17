#pragma once
/** @addtogroup solverNox
 *
 *  @{
 */
#include "FactoryExport.h"
#include <Core/Solver/AlgLoopSolverDefaultImplementation.h>

#include <Solver/Nox/NOX_StatusTest_SgnChange.H>



class Nox : public INonLinearAlgLoopSolver,  public AlgLoopSolverDefaultImplementation
{
public:
  Nox(INonLinSolverSettings* settings,shared_ptr<INonLinearAlgLoop> algLoop=shared_ptr<INonLinearAlgLoop>());
  virtual ~Nox();

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
  bool CheckWhetherSolutionIsNearby(double const * const y);
  void CheckWhetherSolutionIsNearbyWrapper();
  bool isdivisionbyzeroerror(const std::exception &ex);
  void modifySolverParameters(const Teuchos::RCP<Teuchos::ParameterList> solverParametersPtr,const int iter);
  Teuchos::RCP<Teuchos::ParameterList> setLocaParams();
  bool modify_y(const int counter);
  void BinRep(std::vector<double> &result, const int number);

  void check4EventRetry(double* y);

  //void check4EventRetry(double* y)

// Member variables
  //---------------------------------------------------------------
  INonLinSolverSettings
    *_noxSettings;     ///< Settings for the solver

  INonLinearAlgLoop
    *_algLoop;            ///< Algebraic loop to be solved

  ITERATIONSTATUS
    _iterationStatus;     ///< Output   - Denotes the status of iteration



  double
	  *_y,
	  *_y0,
      *_y_old,
      *_y_new,
      *_yScale,
      *_helpArray,
	  _locTol,
	  _currentIterateNorm,
	  *_currentIterate,
    _SimTimeOld,
    _SimTimeNew;

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
  bool _useDomainScaling;

  bool _OutOfProperMethods;
  bool _eventRetry;
  LogCategory _lc;
};
/** @} */ // end of solverNox
