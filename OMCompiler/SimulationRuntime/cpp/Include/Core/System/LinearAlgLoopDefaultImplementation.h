#pragma once

/** @addtogroup coreSystem
 *
 *  @{
 */

/*****************************************************************************/
/**

Services for the implementation of an algebraic loop in open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/

class BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL LinearAlgLoopDefaultImplementation
{
public:
  LinearAlgLoopDefaultImplementation();

  ~LinearAlgLoopDefaultImplementation();

  /// Provide number (dimension) of variables according to data type
  int getDimReal() const;
  virtual int getDimZeroFunc() const;
  /// (Re-) initialize the system of equations
  void initialize();

  /// Provide the right hand side (residuals)
  void getb(double* res) const;

  bool getUseSparseFormat();

  void setUseSparseFormat(bool value);
  virtual void getRealStartValues(double* vars) const;

  //void getSparseAdata(double* data, int nonzeros);

  // Member variables
  //---------------------------------------------------------------
protected:
  int _dimAEq;                        ///< Number (dimension) of unknown/equations (the index denotes the data type; 0: double, 1: int, 2: bool)
  int _dimZeroFunc;
  double* _b;
  double* _x0;

  double * _AData;
  double* _Ax;
  bool _useSparseFormat;
  bool _firstcall;

};
/** @} */ // end of coreSystem
