#pragma once

class IAlgLoop;

/*****************************************************************************/
/**

Abstract interface class for numerical methods for the (possibly iterative)
solution of algebraic loops in open modelica.

\date     September, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class IAlgLoopSolver
{

public:
    /// Enumeration to control the time integration
    enum SOLVERCALL
    {
        UNDEF_CALL        =    0x00000000,

        FIRST_CALL        =    0x00000100,            ///< First call to solver
        LAST_CALL        =    0x00000200,            ///< Last call to solver
        RECALL            =    0x00000400,            ///< Call to solver after restart (state vector of solver has to be reinitialized)
        REGULAR_CALL    =    0x00000800,            ///< Regular call to solver
        REPEATED_CALL    =    0x00001000,            ///< Call to solver after rejected step (e.g. in external zero search)
    };

        /// Enumeration to denote the status of iteration
    enum ITERATIONSTATUS
    {
        CONTINUE,
        SOLVERERROR,
        DONE,
    };

    virtual ~IAlgLoopSolver()    {};

    /// (Re-) initialize the solver
    virtual void init() = 0;

  /// Solution of a (non-)linear system of equations
  virtual void solve() = 0;



};
