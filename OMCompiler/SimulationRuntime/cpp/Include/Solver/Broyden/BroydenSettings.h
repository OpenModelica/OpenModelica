#pragma once
/** @addtogroup solverBroyden
 *
 *  @{
 */

#include <Core/Solver/INonLinSolverSettings.h>
class BroydenSettings :public INonLinSolverSettings
{
public:
    BroydenSettings();

    virtual ~BroydenSettings();
        /*max. Anzahl an Broydenititerationen pro Schritt (default: 25)*/
    virtual long int    getNewtMax();
    virtual void        setNewtMax(long int);
    /* Relative Toleranz für die Broydeniteration (default: 1e-6)*/
    virtual double        getRtol();
    virtual void        setRtol(double);
    /*Absolute Toleranz für die Broydeniteration (default: 1e-6)*/
    virtual double        getAtol();
    virtual void        setAtol(double);
    /*Dämpfungsfaktor (default: 0.9)*/
    virtual double        getDelta();
    virtual void        setDelta(double);
    virtual void load(string);

    virtual void setContinueOnError(bool);
    virtual bool getContinueOnError();
private:
    long int    _iNewt_max;                    ///< max. Anzahl an Broydenititerationen pro Schritt (default: 25)

    double        _dRtol;                        ///< Relative Toleranz für die Broydeniteration (default: 1e-6)
    double        _dAtol;                        ///< Absolute Toleranz für die Broydeniteration (default: 1e-6)
    double        _dDelta;                        ///< Dämpfungsfaktor (default: 0.9)
    bool _continueOnError;
};
/** @} */ // end of solverBroyden
