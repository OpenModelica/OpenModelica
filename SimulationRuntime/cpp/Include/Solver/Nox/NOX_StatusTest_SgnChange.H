#ifndef NOX_STATUSTEST_SGNCHANGE_H
#define NOX_STATUSTEST_SGNCHANGE_H

#include "NOX_Solver_Generic.H"
#include "NOX_StatusTest_Generic.H"	// base class
#include "NOX_LAPACK_Vector.H"

namespace NOX{
namespace StatusTest{

class SgnChange : public Generic {

public:

  //! Constructor
  SgnChange() = delete;//avoid default constructor, only available in C++-11
  SgnChange(double tol);

  //! Destructor
  ~SgnChange();
  // derived
  virtual StatusType checkStatus(const NOX::Solver::Generic& problem, NOX::StatusTest::CheckType checkType);
  // derived
  virtual StatusType getStatus() const;
  // derived
  virtual std::ostream& print(std::ostream& stream, int indent = 0) const;

private:
  //! %do initialization in checkStatus only once
  void initialize(const NOX::Solver::Generic& problem);

  //! %Status
  StatusType _status;

  //! %Tolerance
  double _tol;

  //! %Number of sign changes
  int _numSignChanges;

  //! %Only initialize once
  bool _firstCall;

  //! %Dimension of solution and function
  unsigned int _dimSys;

  //! %solution/function vector pointers
  Teuchos::RCP<NOX::LAPACK::Vector> _x0,_x1,_f0,_f1;
};
}//namespace StatusTest
}//namespace NOX
#endif