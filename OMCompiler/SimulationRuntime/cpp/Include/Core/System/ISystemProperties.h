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

class ISystemProperties
{
public:
  virtual ~ISystemProperties()  {};

  /// M is regular
  virtual bool isODE() /*const*/ = 0;

  /// M is singular
  virtual bool isAlgebraic() /*const*/ = 0;

  /// System is able to provide the Jacobian symbolically
  virtual bool provideSymbolicJacobian() /*const*/ = 0;
};
/** @} */ // end of coreSystem