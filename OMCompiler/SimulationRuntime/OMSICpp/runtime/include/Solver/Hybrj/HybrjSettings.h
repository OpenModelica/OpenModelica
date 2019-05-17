#pragma once
 /** @addtogroup solverCvode
 *
 *  @{
 */

#include <Core/Solver/INonLinSolverSettings.h>
class HybrjSettings :public INonLinSolverSettings
{
public:
    HybrjSettings();
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

    virtual void setContinueOnError(bool);
    virtual bool getContinueOnError();
private:
    long int    _iNewt_max;                    ///< max. Anzahl an Newtonititerationen pro Schritt (default: 25)

    double        _dRtol;                        ///< Relative Toleranz für die Newtoniteration (default: 1e-6)
    double        _dAtol;                        ///< Absolute Toleranz für die Newtoniteration (default: 1e-6)
    double        _dDelta;                        ///< Dämpfungsfaktor (default: 0.9)
    bool _continueOnError;
};
/** @} */ // end of solverHybrj
