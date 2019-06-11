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

//using std::map;
//using std::pair;
//using std::make_pair;

//#include <string>
//#include <vector>

//#include <Core/Utils/numeric/bindings/ublas.hpp>
//#include <Core/Utils/numeric/utils.h>

//#include <algorithm>

//typedef tuple<int,int> mytuple;

/*not used anymore

/// Enumeration to control the output
enum OUTPUT
{
    UNDEF_OUTPUT    =    0x00000000,

    WRITEOUT      =  0x00000001,      ///< vxworks! Store current position of curser and write out current results
    RESET         =  0x00000002,      ///< Reset curser position
    OVERWRITE     =  0x00000003,      ///< RESET|WRITE


    HEAD_LINE     =  0x00000010,      ///< Write out head line
    RESULTS       =  0x00000020,      ///< Write out results
    SIMINFO       =  0x00000040      ///< Write out simulation info (e.g. number of steps)
  };
*/

class BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL NonLinearAlgLoopDefaultImplementation
{
public:
  NonLinearAlgLoopDefaultImplementation();

  ~NonLinearAlgLoopDefaultImplementation();

  /// Provide number (dimension) of variables according to data type
  int getDimReal() const;
  virtual int getDimZeroFunc() const;
  /// (Re-) initialize the system of equations
  void initialize();

  /// Provide the right hand side (residuals)
  void getRHS(double* res) const;

  bool getUseSparseFormat();

  void setUseSparseFormat(bool value);

  virtual void getRealStartValues(double* vars) const;
  //void getSparseAdata(double* data, int nonzeros);

  // Member variables
  //---------------------------------------------------------------
protected:
  int _dimAEq;                        ///< Number (dimension) of unknown/equations (the index denotes the data type; 0: double, 1: int, 2: bool)
  int _dimZeroFunc;
  double* _res;
  double* _x0;

  double * _AData;
  double* _Ax;
  bool _useSparseFormat;
  bool _firstcall;

};
/** @} */ // end of coreSystem
