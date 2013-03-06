#pragma once





/*****************************************************************************/
/**

Algeimeine Klasse zur Kapselung der Parameter (Einstellungen) für einen nicht linearen Solver
Hier werden default-Einstellungen entsprechend der allgemeinen Simulations-
einstellugnen gemacht, diese können überprüft und ev. Fehleinstellungen korrigiert
werden.
*****************************************************************************/
class INonLinSolverSettings
{
public:
    ~INonLinSolverSettings(){};

    virtual long int    getNewtMax() = 0;
    virtual void        setNewtMax(long int)= 0;
    virtual double        getRtol() = 0;
    virtual void        setRtol(double) = 0;
    virtual double        getAtol() = 0;
    virtual void        setAtol(double) = 0;
    virtual double        getDelta()= 0;
    virtual void        setDelta(double)= 0;
    virtual void load(string)=0;
};




