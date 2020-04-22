#pragma once

/** @addtogroup coreSystem
 *
 *  @{
 */

/*****************************************************************************/
/**

Services for the implementation of an algebraic loop in open modelica.

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
  int _dimAEq
;                        ///< Number (dimension) of unknown/equations (the index denotes the data type; 0: double, 1: int, 2: bool)
  int _dimZeroFunc;
  double* _res;
  double* _x0;

  double * _AData;
  double* _Ax;
  bool _useSparseFormat;
  bool _firstcall;


};
/** @} */ // end of coreSystem
