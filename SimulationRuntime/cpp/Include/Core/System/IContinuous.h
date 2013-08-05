#pragma once



/*****************************************************************************/
/**

Abstract interface class for continous systems in open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class IContinuous
{
public:


    /// Enumeration to control the evaluation of equations within the system
    enum UPDATE
    {
        UNDEF_UPDATE    =    0x00000000,

        DISCRETE        =    0x00000001,            ///< Sample discrete variables only
        CONTINOUS        =    0x00000002,            ///< Determine continous variables
        ACROSS            =    0x00000004,
        THROUGH            =    0x00000008,
        ALL                =    0x0000000F,            ///< [DISCRETE|CONTINOUS]
        RANKING            =    0x00000010            ///< Ranking Method

    };



    virtual ~IContinuous()    {};



    /// Provide number (dimension) of variables according to the index
    virtual int getDimVars() const = 0;

    /// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
    virtual int getDimRHS() const = 0;



    /// Set current integration time
    virtual void setTime(const double& time) = 0;

    /// Provide variables with given index to the system
    virtual void giveVars(double* z) = 0;

    /// Set variables with given index to the system
    virtual void setVars(const double* z) = 0;

    /// Update transfer behavior of the system of equations according to command given by solver
    virtual bool update(const UPDATE command = UNDEF_UPDATE) = 0;

    /// Provide the right hand side (according to the index)
    virtual void giveRHS(double* f) = 0;


};

/*
/// Enumeration with variable- and differentiation-index to sort state vector and vector of right hand side
    /// (see: Simeon, B.: "Numerische Integration mechanischer Mehrkörpersysteme", PhD-Thesis, Düsseldorf, 1994)
    enum INDEX
    {
        UNDEF_INDEX            =    0x00000,
        VAR_INDEX0            =    0x00001,    ///< Variable Index 0 (States of systems of 1st order)
        VAR_INDEX1            =    0x00002,    ///< Variable Index 1 (1st order States of systems of 2nd order, e.g. positions)
        VAR_INDEX2            =    0x00004,    ///< Variable Index 2 (2nd order States of systems of 2nd order, e.g. velocities)
        VAR_INDEX3            =    0x00038,    ///< Variable Index 3 (all constraints)
        DIFF_INDEX3            =    0x00008,    ///< Differentiation Index 3 (constraints on position level only)
        DIFF_INDEX2            =    0x00010,    ///< Differentiation Index 2 (constraints on velocity level only)
        DIFF_INDEX1            =    0x00020,    ///< Differentiation Index 1 (constraints on acceleration level only)
        ALL_RESIDUES        =    0x00040,    ///< All residues
        ALL_STATES            =    0x00007,    ///< All states (no order)
        ALL_VARS            =    0x0003f,    ///< All variables (no order)
    };
    */
