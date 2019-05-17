#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */
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
  virtual ~ISystemInitialization() {};
  /// (Re-) initialize the system of equations and bounded parameters
  virtual void initialize() = 0;
  virtual void initEquations() = 0;
  //sets the initial status
  virtual void setInitial(bool) = 0;
  //returns the intial status
  virtual bool initial() = 0;
  virtual void initializeMemory() =0;
  virtual void initializeFreeVariables() =0;
   virtual void  initializeBoundVariables() =0;
};
/** @} */ // end of coreSystem
