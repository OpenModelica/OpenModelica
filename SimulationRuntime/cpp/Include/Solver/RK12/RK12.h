#pragma once
/** @defgroup solverRK12 Solver.RK12
 *  Module for RK12 integration methods
 *  @{
 */
#include "FactoryExport.h"
#include <Core/Solver/SolverDefaultImplementation.h>

class IRK12Settings;

/*****************************************************************************/
/**

RK12 method for the solution of a non-stiff initial value problem of a system
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
class  RK12 : public ISolver, public SolverDefaultImplementation
{
public:
     RK12(IMixedSystem* system, ISolverSettings* settings);
     virtual ~RK12();

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
    ISolver::SOLVERSTATUS getSolverStatus();

    /// Write out statistical information (statistical information of last simulation, e.g. time, number of steps, etc.)
     virtual void writeSimulationInfo();
      virtual void setTimeOut(unsigned int time_out);

    virtual void stop();
    /// Indicates whether a solver error occurred during integration, returns type of error and provides error message
    virtual int reportErrorMessage(ostream& messageStream);
    virtual bool stateSelection();
private:
    /*
    embedded RK12, i.e. explicit euler as predictor and heuns method as corrector
    */
    void doRK12();
    void doRK12_stepControl();

    void outputStepSize(bool *_activeStates, double time ,double hLatent, double hActive);

    void RK12Integration(bool *activeStates, double time, double *z0, double *z1, double h, double *error, double relTol, double absTol, int *numErrors);

    void RK12InterpolateStates(bool *activeStates, double *leftIntervalStates,double *rightIntervalStates,double leftTime,double rightTime, double *interpolStates, double interpolTime);

    /// Encapsulation of determination of right hand side
    void calcFunction(const double& t, const double* z, double* zDot);

    /// Output routine called after every sucessfull solver step (calls setZeroState() and writeToFile() in SolverDefaultImpl.)
    void solverOutput(const int& stp, const double& t, double* z, const double& h);

    // Hilfsfunktionen
    //------------------------------------------
    // Interpolation der Lösung für RK12-Verfahren
    void interp1(double time, double* value);

    double toleranceOK(double z1, double z2, double relTol, double absTol);

    double relError(double z1, double z2);

    /// Kapselung der Nullstellensuche
    void doMyZeroSearch();
    void doZeroSearch();

    // gibt den Wert der Nullstellenfunktion für die Zeit t und den Zustand y wieder
    void giveZeroVal(const double &t,const double *y,double *zeroValue);

    // gibt die Indizes der Nullstellenfunktion mit Vorzeichenwechsel zurück
    void giveZeroIdx(double *vL,double *vR,int *zeroIdx, int &zeroExist);

    /// Berechnung der Jacobimatrix
    void calcJac(double* yHelp, double* _fHelp, const double* _f, double* jac, const bool& flag);

    // Member variables
    //---------------------------------------------------------------
    IRK12Settings
        *_RK12Settings;                            ///< Settings for the solver

    long int
        _dimSys,                                    ///< Temp             - (total) Dimension of systems (=number of ODE)
        _idid,										///< Input, Output    - Status Flag
		_dimParts;                                  ///      				- number of partitions

    int
		_latentSteps,
		_activeSteps,
        _outputStp,
        _outputStps;                                ///< Output            - Number of output steps

    double
        *_z,                                        // State vector in latent step
        *_z0,                                       // (Old) state vector at left border of latent interval
        *_z1,                                       // (New) state vector at right border of latent interval
		*_z_a,										// State vector in active step
		*_z_a_0,									// (Old) state vector at left border of active interval
		*_z_a_1,									// (New) state vector at right border of active interval
        *_zPred,									// Predictor state after first step in RK12

        *_zInit,                                    // Temp            - Initial state vector
        *_zWrite,                                   // Temp            - write to res

        *_f0,
        *_f1,

		*_zDot0,									// state derivative for state
		*_zDotPred;									// state derivative for predictor state

     double
         _hOut,                                     // Ouput step size for dense output
         _hZero,                                    // Downscale of step size to approach the zero crossing
         _hUpLim,                                   // Maximal step size
         _h00,
         _h01,
         _h10,
         _h11,
		 _h_a;										// step size for the active step


    double
        _tOut,                                        ///< Output            - Time for dense output
        _tLastZero,                                 ///< Temp            - Stores the time of the last zero (not last zero crossing!)
        _tRealInitZero,                                ///< Temp            - Time of the very first zero in all zero functions
        _doubleZeroDistance,                        ///< Temp            - In case of two zeros in one intervall (doubleZero): distance between zeros
        _tZero,                                        ///< Temp            - Nullstelle
        _tLastWrite,                                ///< Temp            - Letzter Ausgabezeitpunkt
        _zeroTol;


    int
        *_zeroSignIter;                                ///< Temp            - Temporary zeroSign Vector


    bool
		*_activePartitions,							// boolean vector which partition has to be activated
		*_activeStates;								// boolean vector which state has to be calculated in an active step

    ISystemProperties* _properties;
    IContinuous* _continuous_system;
    IEvent* _event_system;
    IMixedSystem* _mixed_system;
    ITime* _time_system;
};
/** @} */ // end of solverRK12
