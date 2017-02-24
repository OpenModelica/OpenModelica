#pragma once
/** @addtogroup solverLinearSolver
 *
 *  @{
 */

#if defined(klu)
  #include <../../../../build/include/omc/c/suitesparse/Include/klu.h>
#endif

class LinearSolver : public IAlgLoopSolver
{
public:
  LinearSolver(ILinearAlgLoop* algLoop, ILinSolverSettings* settings);
  virtual ~LinearSolver();

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
    _dimSys;              ///< Temp   - Number of unknowns (=dimension of system of equations)

  bool
    _firstCall;           ///< Temp   - Denotes the first call to the solver, init() is called

  long int *_ihelpArray,  //pivot indices for lapackroutine
    *_jhelpArray;       //pivot indices for lapackroutine

  const char*
    *_yNames;           ///< Names of variables
  double
    *_yNominal,         ///< Nominal values of variables
    *_y,                ///< Temp   - Unknowns
    *_y0,               ///< Temp   - Auxillary variables
    *_y_old,            //stores old solution
    *_y_new,            //stores new solution
    *_b,                ///< right hand side
    *_A,                ///coefficients of linear system
    *_zeroVec,          ///zero vector
    *_fNominal,         // klu scales the matrix entries already
    *_scale;            //scaling parameter to prevent overflow in singular systems
  bool _sparse;
  bool _generateoutput;   //prints nothing, if set to false. Prints Matrix, right hand side, and solution of the linear system, if set to true.
#if defined(klu)
  klu_symbolic* _kluSymbolic;
  klu_numeric* _kluNumeric;
  klu_common* _kluCommon;
  int* _Ai;
  int* _Ap;
  double* _Ax;
  int _nonzeros;
#endif

};
/** @} */ // end of solverLinearSolver
