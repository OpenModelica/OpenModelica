#pragma once
/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/Solver/INonLinSolverSettings.h>
class NewtonSettings :public INonLinSolverSettings
{
public:
    NewtonSettings();

    virtual ~NewtonSettings();
        /*max. Anzahl an Newtonititerationen pro Schritt (default: 25)*/
    virtual long int    getNewtMax();
    virtual void        setNewtMax(long int);
    /* Relative Toleranz für die Newtoniteration (default: 1e-6)*/
    virtual double        getRtol();
    virtual void        setRtol(double);
    /*Absolute Toleranz für die Newtoniteration (default: 1e-6)*/
    virtual double        getAtol();
    virtual void        setAtol(double);
    /*Dämpfungsfaktor (default: 0.9)*/
    virtual double        getDelta();
    virtual void        setDelta(double);
    virtual void load(string);
private:
    long int    iNewt_max;                    ///< max. Anzahl an Newtonititerationen pro Schritt (default: 25)

    double        dRtol;                        ///< Relative Toleranz für die Newtoniteration (default: 1e-6)
    double        dAtol;                        ///< Absolute Toleranz für die Newtoniteration (default: 1e-6)
    double        dDelta;                        ///< Dämpfungsfaktor (default: 0.9)
};
/** @} */ // end of solverNewton
