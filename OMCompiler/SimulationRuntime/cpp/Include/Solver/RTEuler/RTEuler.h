#pragma once
/** @addtogroup solverCvode
 *
 *  @{
 */
#include "FactoryExport.h"
#include <Core/Solver/SolverDefaultImplementation.h>

class IEulerSettings;

/*****************************************************************************/
/**

Euler method for the solution of a non-stiff initial value problem of a system
of ordinary differantial equations of the form

z' = f(t,z).

Dense output may be used. Zero crossing are detected by bisection or linear
interpolation.

\date     01.09.2008
\author


*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class  RTEuler : public ISolver, public SolverDefaultImplementation
{
public:
   RTEuler(IMixedSystem* system, ISolverSettings* settings);
     virtual ~RTEuler();

    /// Set start time for numerical solution
    virtual void setStartTime(const double& t);

    /// Set end time for numerical solution
    virtual void setEndTime(const double& t);

    /// Set the initial step size (needed for reinitialization after external zero search)
     virtual void setInitStepSize(const double& h);

    /// (Re-) initialize the solver
    virtual void initialize();

    /// Approximation of the numerical solution in a given time interval
    virtual void solve(const SOLVERCALL command = UNDEF_CALL);

    /// Provides the status of the solver after returning
    virtual ISolver::SOLVERSTATUS getSolverStatus();

    /// Write out statistical information (statistical information of last simulation, e.g. time, number of steps, etc.)
     virtual void writeSimulationInfo();

    /// Indicates whether a solver error occurred during integration, returns type of error and provides error message
    virtual const int reportErrorMessage(ostream& messageStream);
  virtual bool stateSelection();
  virtual void setTimeOut(unsigned int time_out);


  virtual void stop();

private:

    /// Encapsulation of determination of right hand side
    void calcFunction(const double& t, const double* z, double* zDot);

    void doRK1();

    // Member variables
    //---------------------------------------------------------------
    ISolverSettings
        *_eulerSettings;              ///< Settings for the solver

    long int
        _dimSys;                  ///< Temp       - (total) Dimension of systems (=number of ODE)


    double _tHelp;
    double
        *_z,                    ///< Temp      - State vector
        *_zInit,                        ///< Temp           - Initial state vector
        *_f;                    ///< Temp      - function evaluation                  ///< Temp      - yhelp and fhelp only provided in order to avoid multiple generation of save

    ISystemProperties* _properties;
    IContinuous* _continuous_system;
    IEvent* _event_system;
    IMixedSystem* _mixed_system;
    ITime* _time_system;
};
/** @} */ // end of solverRteuler
