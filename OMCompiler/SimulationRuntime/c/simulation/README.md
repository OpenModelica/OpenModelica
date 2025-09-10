# C Simulation Runtime - Developer Documentation

The main simulation runtime for simulation executables.

Containing:
  - Integration or implementation of ODE/DAE solvers
  - Integration or implementation of linear and non-linear solvers
  - Analysis tools
  - Implementaitons of Modelica builtin functions
  - Utility functions for evaluation of equations

## Directory Structure

### ODE/DAE Solver

  - Perfom Simulation:
    [solver/perform_simulation.c.inc](./solver/perform_simulation.c.inc),
    [solver/solver_main.c](./solver/solver_main.c)<br/>
    Main solver routine to integrate ODE/DAE system using one of the following
    solvers:

    - CVODE: [solver/cvode_solver.c](./solver/cvode_solver.c)<br/>
      Integration of SUNDIALS CVODES ODE solver.

    - DASSL: [solver/dassl.c](./solver/dassl.c)<br/>
      Integration of DASSL ODE/DAE solver.

    - GBODE: [solver/gbode_main.c](./solver/gbode_main.c)<br/>
      Implementation of a generic (implicit and explicit) Runge Kutta ODE
      solver.

    - IDA: [solver/ida_solver.c](./solver/ida_solver.c)<br/>
      Integration of SUNDIALS IDA ODE/DAE solver.

   - QSS:
     [solver/perform_qss_simulation.c.inc](./solver/perform_qss_simulation.c.inc)<br/>
     Quantized State System (QSS) solver for sparse ODE systems.

### Linear Solver

  - Linear System: [solver/linearSystem.c](./solver/linearSystem.c)<br/>
    Solve linear systems with one of the following solver methods:

    - KLU: [solver/linearSolverKlu.c](./solver/linearSolverKlu.c)<br/>
      Integration of Suite Sparse's KLU linear solver.

    - LAPACK: [solver/linearSolverLapack.c](./solver/linearSolverLapack.c)<br/>
      Integration of LAPACK.

    - LIS: [solver/linearSolverLis.c](./solver/linearSolverLis.c)<br/>
      Integration of Lis from Scalable Software Infrastructure Project.

    - Total Pivot:
      [solver/linearSolverTotalPivot.c](./solver/linearSolverTotalPivot.c)<br/>
      Implementation of Gaussian elimination based on LU decomposition with
      total pivot.

    - UMFPACK:
      [solver/linearSolverUmfpack.c](./solver/linearSolverUmfpack.c)<br/>
      Integration of Suite Sparse's UMFPACK linear solver.

### Non-Linear Solver

  - Non-Linear System:
    [solver/nonlinearSystem.c](./solver/nonlinearSystem.c)<br/>
    Solve non-linear systems with one of the following solver methods:

    - KINSOL: [solver/kinsolSolver.c](./solver/kinsolSolver.c)<br/>
      Integration of SUNDIALS KINSOL non-linear solver.

    - Homotopy:
      [solver/nonlinearSolverHomotopy.c](./solver/nonlinearSolverHomotopy.c)<br/>
      Implementation of a damped Newton solver / fixed-point iteration.

    - Hybrid:
      [solver/nonlinearSolverHybrd.c](./solver/nonlinearSolverHybrd.c)<br/>
      Implementaton of modified version of Powell hybrid method from MINPACK.

    - Mixed Strategy: [solver/mixedSystem.c](./solver/mixedSystem.c)<br/>
      Implementation of mixed strategy.
      First the homotopy solver is tried and then as fallback the hybrid solver.

    - Newton-Raphson:
      [solver/nonlinearSolverNewton.c](./solver/nonlinearSolverNewton.c)<br/>
      Implementaton of Newton-Raphson method.

  - Initial Guess DB:
    [solver/nonlinearValuesList.c](./solver/nonlinearValuesList.c)<br/>
    Store guesses for initial values for non-linear systems.

### Analysis Tools

  - Jacobian Analysis:
    [solver/jacobian_analysis.c](./solver/jacobian_analysis.c)<br/>
    Singular Value Decomposition (SVD) to analyze Jacobians.

  - Newton Diagnostics:
    [solver/newton_diagnostics.c](./solver/newton_diagnostics.c)<br/>
    Analyse initial guesses for the Newton-Raphson algorithm.

### Modelica Builtin

  - `delay`: [solver/delay.c](./solver/delay.c)<br/>
    Implementation of Modelica built-in operator `delay`.

  - `spatialDistribution`:
    [solver/spatialDistribution.c](./solver/spatialDistribution.c)<br/>
    Implementation of Modelica built-in operator `spatialDistribution`.

  - Synchronous Features: [solver/synchronous.c](./solver/synchronous.c)<br/>
    Implementaton of Modelica synchronous features.

### Basic Math

  - Vector/Matrix Operations: [solver/omc_math.c](./solver/omc_math.c)<br/>
    Basic vector and matrix operations.

### Util

  - Initialization: [solver/initialization/](./solver/initialization/)<br/>
    Solve initial ODE/DAE system at time `start_time`.
    Can use Homotopy and symbolic initialization.

  - Result files: [results/](./results/)<br/>
    Write simulation results (CSV/MAT).

  - Events: [solver/events.c](./solver/events.c)<br/>
    Handling of state and time events during simulation.

  - Symbolic Jacobians:
    [solver/jacobianSymbolical.c](./solver/jacobianSymbolical.c)<br/>
    Symbolic evaluation of Jacobians.

  - State Selection: [solver/stateset.c](./solver/stateset.c)<br/>
    State selection for ODE solvers.
