#pragma once
/** @defgroup solverEuler Solver.Euler
 *  Module for Euler integration methods
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
class  Euler : public ISolver, public SolverDefaultImplementation
{
public:
     Euler(IMixedSystem* system, ISolverSettings* settings);
     virtual ~Euler();

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
    /// (Explizites) Euler-Verfahren 1. Ordnung
    /*
    Euler:
    y_n+1 = y_n + h * f(t_n, y_n)
    */
    void doEulerForward();


    /// Explizite Verfahren 1. und 2. Ordnung
    /*
    Euler-Cauchy (wie impliziter Euler, aber explizit durch Präd. Korr., 1. Ordnung):
    y_n+1^P = y_n + h * f(t_n, y_n)
    y_n+1 = y_n + h * f((t_n+1, y_n+1^P)

    Heun (wie Trapezregel, aber explizit durch Präd. Korr., 2. Ordnung):
    y_n+1^P = y_n + h * f(t_n, y_n)
    y_n+1 = y_n + h * 1/2(f(t_n, y_n) + f(t_n+1, y_n+1^P))

    Mod. Heun (siehe Heun):
    y_n+1^P = y_n + 2/3 * h * f(t_n, y_n)
    y_n+1 = y_n + h * (1/4*f(t_n, y_n) + 3/4*f((t_n+2/3h), y_n+1^P))

    */
    /*void doHeun(); */


    /// Implizites Euler-Verfahren 1. Ordnung (A-stabil, teilw. auch für instab. Systeme)
    /*
    Euler Rückwärts (wie Euler-Cauchy, ohne Prädiktor Schritt):
    y_n+1 = y_n + h * f(t_n+1, y_n+1)

    */
    void doEulerBackward();


    /// Implizite Mittelpunkts- oder Trapezregel 2. Ordnung (A-stabil)
    /*
    Trapezregel (wie Heun, ohne Prädiktor Schritt):
    y_n+1 = y_n + h * 1/2(f(t_n, y_n) + f(t_n+1, y_n+1))

    */
    void doMidpoint();


    /// Encapsulation of determination of right hand side
    void calcFunction(const double& t, const double* z, double* zDot);

    /// Output routine called after every sucessfull solver step (calls setZeroState() and writeToFile() in SolverDefaultImpl.)
    void solverOutput(const int& stp, const double& t, double* z, const double& h);

    // Hilfsfunktionen
    //------------------------------------------
    // Interpolation der Lösung für Euler-Verfahren
    void interp1(double time, double* value);

    /// Kapselung der Nullstellensuche
    void doMyZeroSearch();
    void doZeroSearch();

    // gibt den Wert der Nullstellenfunktion für die Zeit t und den Zustand y wieder
    void giveZeroVal(const double &t,const double *y,double *zeroValue);

    // gibt die Indizes der Nullstellenfunktion mit Vorzeichenwechsel zurück
    void giveZeroIdx(double *vL,double *vR,int *zeroIdx, int &zeroExist);




    ///// Output routine for dense output (Encapsulates interpolation, calls solverOutput() for output)
    //void denseout(double* pK1);

    ///// Ausgaberoutine zur dichten Ausgabe für alle Verfahren mit Ordnung > 1
    ///// (Kapselt die Interpolation, ruft solverOut zur Ausgabe, ruft numberOfRootsBySturm() zur Bestimmung der Anzahl der Nullstellen
    ///// im aktuellen Ausgabeintervall)
    //void denseout(double* pK1, double* pK2, double b, double* w1, double* w2, double* w3);


    /// Berechnung der Jacobimatrix
    void calcJac(double* yHelp, double* _fHelp, const double* _f, double* jac, const bool& flag);


    // Member variables
    //---------------------------------------------------------------
    IEulerSettings
        *_eulerSettings;                            ///< Settings for the solver

    long int
        _dimSys,                                    ///< Temp             - (total) Dimension of systems (=number of ODE)
        _idid;                                        ///< Input, Output    - Status Flag

    int
         _outputStp,
        _outputStps;                                ///< Output            - Number of output steps

    double
        *_z,                                        ///< Temp            - State vector
        *_z0,                                        ///< Temp            - (Old) state vector at left border of intervall (last step)
        *_z1,                                        ///< Temp            - (New) state vector at right border of intervall (last step)
        *_zInit,                                    ///< Temp            - Initial state vector
        *_zWrite,                                    ///< Temp            - Zustand den das System rausschreibt
        *_f0,
        *_f1;

     double
         _hOut,                                        ///< Temp            - Ouput step size for dense output
         _hZero,                                        ///< Temp            - Downscale of step size to approach the zero crossing
         _hUpLim,                                    ///< Temp             - Maximal step size
         _h00,
         _h01,
         _h10,
         _h11;


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

    ISystemProperties* _properties;
    IContinuous* _continuous_system;
    IEvent* _event_system;
    IMixedSystem* _mixed_system;
    ITime* _time_system;
};
/** @} */ // end of solverEuler