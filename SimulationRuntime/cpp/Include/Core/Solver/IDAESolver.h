#pragma once



/*****************************************************************************/
/**

Abstract interface class for numerical time integration methods
in open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class IDAESolver
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
        TIMEEVENTCALL   =   0x00002000,            ///< Aufruf nach einem Time-Event
        RECORDCALL        =   0x00004000,            ///< Erster Aufruf zum recorden von y0
    };

    /// Enum to define the current status of the solver
    enum SOLVERSTATUS
    {
        UNDEF_STATUS    =    0x00000,
        CONTINUE        =    0x00001,        ///< Continoue integration
        USER_STOP        =    0x00002,            ///< Integratin stopped by user
        SOLVERERROR            =    0x00004,        ///< An error occured. Integration was stopped
        DONE            =    0x00008,            ///< Integration successfully done
    };

    /// Enumeration to denote the event status
    enum ZEROSTATUS
    {
        EQUAL_ZERO,            ///< Value of zero function smaller than given tolerance (_zeroTol)
        ZERO_CROSSING,        ///< zero crossing = change in sign of zero function
        NO_ZERO,            ///< Even though zero crossing occured, no value of zero function did not become zero in given intervall
        UNCHANGED_SIGN        ///< no zero crossing = continoue time integration
    };

    virtual ~IDAESolver()    {};


    /// Set start time
    virtual void setStartTime(const double& time) = 0;

    /// Set end time
    virtual void setEndTime(const double& time) = 0;

    /// Set the initial step size (needed for reinitialization after external zero search)
    virtual void setInitStepSize(const double& stepSize) = 0;

    /// (Re-) initialize the solver
    virtual void init() = 0;

    /// Approximation of the numerical solution in a given time interval
    virtual void solve(const SOLVERCALL command = UNDEF_CALL) = 0;

    /// Provides the status of the solver after returning
    virtual const SOLVERSTATUS getSolverStatus() = 0;

    /// Write out statistical information (statistical information of last simulation, e.g. time, number of steps, etc.)
    virtual void writeSimulationInfo() = 0;

    /// Indicates whether a solver error occurred during integration, returns type of error and provides error message
    virtual const int reportErrorMessage(ostream& messageStream) = 0;

};
