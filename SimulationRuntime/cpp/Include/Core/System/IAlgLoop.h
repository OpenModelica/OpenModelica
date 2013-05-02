#pragma once

#include "IMixedSystem.h"
#include "IContinuous.h"
#include "Object/IObject.h"
/*****************************************************************************/
/**

Abstract interface class for algebraic loop in equations in open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class IAlgLoop
{
public:
    /// Enumeration with modelica data types
    enum CONSTRTYPE
    {
  UNDEF    =    0x00000000,
  REAL    =    0x00000001,
  INTEGER    =    0x00000002,
  BOOLEAN    =    0x00000004,
  ALL        =    0x00000007,
    };



    virtual ~IAlgLoop()    {};

    /// Provide number (dimension) of variables according to the data type
    virtual int getDimVars() const = 0;

    /// Provide number (dimension) of right hand sides (residuals) according to the data type
    virtual int getDimRHS() const = 0;

    /// (Re-) initialize the system of equations
    virtual void init() = 0;

    /// Provide variables of given data type
    virtual void giveVars(double* lambda) = 0;
    /*
    virtual void giveVars(int* lambda) = 0;
    virtual void giveVars(bool* lambda) = 0;
    */
    /// Set variables with given data type
    virtual void setVars(const double* lambda) = 0;
    /*
    virtual void setVars(const int* lambda ) = 0;
    virtual void setVars(const bool* lambd ) = 0;
    */
    /// Update transfer behavior of the system of equations according to command given by solver
    virtual void update(const IContinuous::UPDATE command = IContinuous::UNDEF_UPDATE) = 0;

    /// Provide the right hand side (according to the index)
    virtual void giveRHS(double* res) = 0;
    /*
    virtual void giveRHS(int* res) = 0;
    virtual void giveRHS(bool* res) = 0;
    */
    virtual void giveAMatrix(double* A_matrix) = 0;
    virtual bool isLinear() = 0;

    /// Fügt das übergebene Objekt als Across-Kante hinzu
    void addAcrossEdge(IObject& new_obj);

    /// Fübt das übergebene Objekt als Through-Kante hinzu
    void addThroughEdge(IObject& new_obj);

    /// Definiert die übergebene Größe als Schnittgröße
    void addConstraint(double& constr_value);
    /*
    void addConstraint(int& constr_value);
    void addConstraint(bool& constr_value);
    */
};
