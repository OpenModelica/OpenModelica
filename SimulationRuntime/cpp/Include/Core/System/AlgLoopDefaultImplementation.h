#pragma once


/*****************************************************************************/
/**

Services for the implementation of an algebraic loop in open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/

/// Enumeration to control the output
enum OUTPUT
{
    UNDEF_OUTPUT    =    0x00000000,

    WRITEOUT      =  0x00000001,      ///< vxworks! Store current position of curser and write out current results
    RESET      =  0x00000002,      ///< Reset curser position
    OVERWRITE    =  0x00000003,      ///< RESET|WRITE


    HEAD_LINE    =  0x00000010,      ///< Write out head line
    RESULTS      =  0x00000020,      ///< Write out results
    SIMINFO      =  0x00000040      ///< Write out simulation info (e.g. number of steps)
  };
/*
#ifdef RUNTIME_STATIC_LINKING
class AlgLoopDefaultImplementation
#else*/
class BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL AlgLoopDefaultImplementation
/*#endif*/
{
public:
    AlgLoopDefaultImplementation();

    ~AlgLoopDefaultImplementation();


    /// Provide number (dimension) of variables according to data type
    int getDimReal() const;
   /// Provide number (dimension) of residuals according to data type
    int getDimRHS() const;

    /// (Re-) initialize the system of equations
    void initialize();

    /// Provide variables with given index to the system

    void getReal(double* lambda) ;

    /// Set variables with given index to the system

    void setReal(const double* lambda);

    /// Provide the right hand side (according to the index)
    void getRHS(double* res);


    /// Output routine (to be called by the solver after every successful integration step)
    void writeOutput(const OUTPUT command = UNDEF_OUTPUT);


    /// Set stream for output
    /*void setOutput(std::ostream* outputStream) ;*/


    // Member variables
    //---------------------------------------------------------------
protected:
    int
       _dimAEq;                        ///< Number (dimension) of unknown/equations (the index denotes the data type; 0: double, 1: int, 2: bool)


  std::vector<double>
   _xd_init,    ///< Double values before update of loop
    __xd;     ///< Double values after update of loop


    std::vector<int>
       _xi_init,            ///< Integer values before update of loop
    __xi;       ///< Integer values after update of loop


    std::vector<bool>
        _xb_init,            ///< Boolean values before update of loop
   __xb;       ///< Boolean values after update of loop

    IAlgLoop::CONSTRTYPE
        _constraintType;                ///< Typ der Bindungsgleichungen (analog, digital, binär)

};
