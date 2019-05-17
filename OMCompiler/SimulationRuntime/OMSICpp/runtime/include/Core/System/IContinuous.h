#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */

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
    enum UPDATETYPE
    {
        UNDEF_UPDATE    = 0x00000000,
        ACROSS        = 0x00000001,
        THROUGH        = 0x00000002,
        ALL            = 0x00000003,
        DISCRETE       = 0x00000004,
        CONTINUOUS    = 0x00000008,
        RANKING        = 0x00000016      ///< Ranking Method
    };

    virtual ~IContinuous()  {};

    /// Provide number (dimension) of boolean variables
    virtual int getDimBoolean() const = 0;

    /// Provide number (dimension) of states
    virtual int getDimContinuousStates() const = 0;
    /// Provide number (dimension) of states
    virtual int getDimAE() const = 0;

    /// Provide number (dimension) of integer variables
    virtual int getDimInteger() const = 0;

    /// Provide number (dimension) of real variables
    virtual int getDimReal() const = 0;

    /// Provide number (dimension) of string variables
    virtual int getDimString() const = 0;

    /// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
    virtual int getDimRHS() const = 0;

    /// Provide boolean variables
    virtual void getBoolean(bool* z) = 0;

    /// Provide boolean variables
    virtual void getContinuousStates(double* z) = 0;
    virtual void getNominalStates(double* z) = 0 ;
    /// Provide integer variables
    virtual void getInteger(int* z) = 0;

    /// Provide real variables
    virtual void getReal(double* z) = 0;

    /// Provide real variables
    virtual void getString(std::string* z) = 0;

    /// Provide the right hand side
    virtual void getRHS(double* f) = 0;

    /// Provide boolean variables
    virtual void setBoolean(const bool* z) = 0;

    /// Provide boolean variables
    virtual void setContinuousStates(const double* z) = 0;

    /// Provide integer variables
    virtual void setInteger(const int* z) = 0;

    /// Provide real variables
    virtual void setReal(const double* z) = 0;

    /// Provide real variables
    virtual void setString(const std::string* z) = 0;

    /// Provide the right hand side
    virtual void setStateDerivatives(const double* f) = 0;
    ///Restores all algloop variables for a output step
     virtual void restoreOldValues() = 0;
     ///Restores all algloop variables for last output step
     virtual void restoreNewValues() = 0;
    /// Update transfer behavior of the system of equations according to command given by solver

    virtual bool evaluateAll(const UPDATETYPE command = UNDEF_UPDATE) = 0;  // vxworks
    virtual void evaluateODE(const UPDATETYPE command = UNDEF_UPDATE) = 0;  // vxworks
    virtual void evaluateZeroFuncs(const UPDATETYPE command = UNDEF_UPDATE) = 0;
    virtual bool evaluateConditions(const UPDATETYPE command = UNDEF_UPDATE) = 0;
    virtual void evaluateDAE(const UPDATETYPE command = UNDEF_UPDATE) =0;



    virtual double& getRealStartValue(double& var) = 0;
    virtual bool& getBoolStartValue(bool& var) = 0;
    virtual int& getIntStartValue(int& var) = 0;
    virtual string& getStringStartValue(string& var) = 0;
    virtual void setRealStartValue(double& var,double val) = 0;
    virtual void setBoolStartValue(bool& var,bool val) = 0;
    virtual void setIntStartValue(int& var,int val) = 0;
    virtual void setStringStartValue(string& var,string val) = 0;

    //in case of solver-based activation of system equations
    virtual void setNumPartitions(int numPartitions) = 0;
    virtual int getNumPartitions() = 0;
    virtual void setPartitionActivation(bool* partitions) = 0;
    virtual void getPartitionActivation(bool* partitions) = 0;
    virtual int getActivator(int state) = 0;


};
/** @} */ // end of coreSystem
/*
/// Enumeration with variable- and differentiation-index to sort state vector and vector of right hand side
    /// (see: Simeon, B.: "Numerische Integration mechanischer Mehrkörpersysteme", PhD-Thesis, Düsseldorf, 1994)
    enum INDEX
    {
        UNDEF_INDEX     =    0x00000,
        VAR_INDEX0      =    0x00001,    ///< Variable Index 0 (States of systems of 1st order)
        VAR_INDEX1      =    0x00002,    ///< Variable Index 1 (1st order States of systems of 2nd order, e.g. positions)
        VAR_INDEX2      =    0x00004,    ///< Variable Index 2 (2nd order States of systems of 2nd order, e.g. velocities)
        VAR_INDEX3      =    0x00038,    ///< Variable Index 3 (all constraints)
        DIFF_INDEX3     =    0x00008,    ///< Differentiation Index 3 (constraints on position level only)
        DIFF_INDEX2     =    0x00010,    ///< Differentiation Index 2 (constraints on velocity level only)
        DIFF_INDEX1     =    0x00020,    ///< Differentiation Index 1 (constraints on acceleration level only)
        ALL_RESIDUES    =    0x00040,    ///< All residues
        ALL_STATES      =    0x00007,    ///< All states (no order)
        ALL_VARS        =    0x0003f,    ///< All variables (no order)
    };
    */
