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

class mytuple
{
public:
	 mytuple(int a, int b)
	 {
		ele1 = a;
		ele2 = b;
	 };
	~mytuple(){};
	int ele1;
	int ele2;
};



bool BOOST_EXTENSION_EXPORT_DECL mycompare ( mytuple lhs, mytuple rhs);

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

/// store attributes of a variable
struct AlgloopVarAttributes
{
  AlgloopVarAttributes() {};
  AlgloopVarAttributes(const char *name,double nominal,double min,double max)
  :name(name)
  ,nominal(nominal)
  ,min(min)
  ,max(max)
  {}

  const char *name;
  double nominal;
  double min;
  double max;
};

class BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL AlgLoopDefaultImplementation
{
public:
  AlgLoopDefaultImplementation();

  ~AlgLoopDefaultImplementation();

  /// Provide number (dimension) of variables according to data type
  int getDimReal() const;

  // Provide number (dimension) of residuals according to data type
  int getDimRHS() const;

  /// (Re-) initialize the system of equations
  void initialize();

  /// Provide variables of the system
  void getReal(double* lambda) const;

  /// Set variables of the system
  void setReal(const double* lambda);

  /// Provide the right hand side (residuals)
  void getRHS(double* res) const;

  //void getSparseAdata(double* data, int nonzeros);

  /// Output routine (to be called by the solver after every successful integration step)
  void writeOutput(const OUTPUT command = UNDEF_OUTPUT);

  //void setDim(const int dim);

  /// Set stream for output
  /*void setOutput(std::ostream* outputStream) ;*/


  // Member variables
  //---------------------------------------------------------------
protected:
  int _dimAEq;                        ///< Number (dimension) of unknown/equations (the index denotes the data type; 0: double, 1: int, 2: bool)
  double* _xd_init;
  double* __xd;

  IAlgLoop::CONSTRTYPE
  _constraintType;                ///< Typ der Bindungsgleichungen (analog, digital, binär)
  double * _AData;
  double* _Ax;
  bool _bInitialized;

};
/** @} */ // end of coreSystem
