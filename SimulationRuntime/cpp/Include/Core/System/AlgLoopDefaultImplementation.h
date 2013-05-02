#pragma once

#include <System/IAlgLoop.h>          // Interface for algebraic loop

#include <Math/Functions.h>  // Include for use of abs



#include <ostream>                              // Use stream for output
using std::ostream;

/*****************************************************************************/
/**

Services for the implementation of an algebraic loop in open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL AlgLoopDefaultImplementation
{
public:
    AlgLoopDefaultImplementation();

    ~AlgLoopDefaultImplementation();


    /// Provide number (dimension) of variables according to data type
    int getDimVars() const;
   /// Provide number (dimension) of residuals according to data type
    int getDimRHS() const;

    /// (Re-) initialize the system of equations
    void init()    ;

    /// Provide variables with given index to the system

    void giveVars(double* lambda) ;
    void giveVars(int* lambda) ;
    void giveVars(bool* lambda);

    /// Set variables with given index to the system

    void setVars(const double* lambda);
    void setVars(const int* lambda );
    void setVars(const bool* lambd );

    /// Provide the right hand side (according to the index)
    void giveRHS(double* res);
    void giveRHS(int* res);
    void giveRHS(bool* res);


    /// Output routine (to be called by the solver after every successful integration step)
    void writeOutput(const IMixedSystem::OUTPUT command = IMixedSystem::UNDEF_OUTPUT);


    /// Set stream for output
    void setOutput(ostream* outputStream) ;


    // Member variables
    //---------------------------------------------------------------
protected:
    int
       _dimAEq;                  ///< Number (dimension) of unknown/equations (the index denotes the data type; 0: double, 1: int, 2: bool)


  std::vector<double>
   _xd_init,    ///< Double values before update of loop
    __xd;     ///< Double values after update of loop


    std::vector<int>
       _xi_init,      ///< Integer values before update of loop
    __xi;       ///< Integer values after update of loop


    std::vector<bool>
  _xb_init,            ///< Boolean values before update of loop
   __xb;       ///< Boolean values after update of loop

    IAlgLoop::CONSTRTYPE
  _constraintType;                ///< Typ der Bindungsgleichungen (analog, digital, binär)
    ostream
  *_outputStream;                ///< Output stream for results
};
