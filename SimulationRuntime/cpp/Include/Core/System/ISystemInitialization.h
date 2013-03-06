#pragma once

/*****************************************************************************/
/**

Abstract interface class for system properties in open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class ISystemInitialization
{
public:

    virtual ~ISystemInitialization()    {};


    virtual unsigned int getDimInitEquations() /*const*/ = 0;


    virtual unsigned int getDimUnfixedStates() /*const*/ = 0;


    virtual unsigned int getDimUnfixedParameters() /*const*/ = 0;


    virtual unsigned int getDimIntialResiduals() /*const*/ = 0;

    /// (Re-) initialize the system of equations and bounded parameters
    virtual void init(double ts,double te) = 0;
    //sets the initial status
    virtual void setInitial(bool) = 0;
    //returns the intial status
    virtual bool initial() = 0;


};
