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
class ISystemProperties
{
public:

    virtual ~ISystemProperties()    {};

    /// No input
    virtual bool isAutonomous() /*const*/ = 0;

    /// Time is not present
    virtual bool isTimeInvariant() /*const*/ = 0;

    /// M is regular
    virtual bool isODE() /*const*/ = 0;

    /// M is singular
    virtual bool isAlgebraic() /*const*/ = 0;

    /// M = identity
    virtual bool isExplicit() /*const*/ = 0;

    /// M does not depend on t, z
    virtual bool hasConstantMass() /*const*/ = 0;

    /// M depends on z
    virtual bool hasStateDependentMass() /*const*/ = 0;

    /// System is able to provide the Jacobian symbolically
    virtual bool provideSymbolicJacobian() /*const*/ = 0;
};
