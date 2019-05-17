#include <Solver/Nox/NOX_StatusTest_SgnChange.H>
#include "NOX_Common.H"
#include "NOX_LAPACK_Group.H"
#include "NOX_Abstract_Vector.H"
#include "NOX_Abstract_Group.H"

NOX::StatusTest::SgnChange::SgnChange(double tol) :
  _tol(tol),
  _status(NOX::StatusTest::Unevaluated),
  _numSignChanges(0),
  _firstCall(true),
  _dimSys(0)
{

}

NOX::StatusTest::SgnChange::~SgnChange()
{

}

void NOX::StatusTest::SgnChange::initialize(const NOX::Solver::Generic& problem)
{
  _dimSys = problem.getSolutionGroup().getX().length();
  _x0=Teuchos::rcp(new NOX::LAPACK::Vector(_dimSys));
  _x1=Teuchos::rcp(new NOX::LAPACK::Vector(_dimSys));
  _f0=Teuchos::rcp(new NOX::LAPACK::Vector(_dimSys));
  _f1=Teuchos::rcp(new NOX::LAPACK::Vector(_dimSys));
  _firstCall=false;
}

NOX::StatusTest::StatusType NOX::StatusTest::SgnChange::checkStatus(const NOX::Solver::Generic& problem, NOX::StatusTest::CheckType checkType)
{
  if(_firstCall) initialize(problem);
  std::vector<bool> fSignChange(_dimSys, false);
  Teuchos::RCP<NOX::LAPACK::Group> grp=Teuchos::rcp(new NOX::LAPACK::Group(dynamic_cast<const NOX::LAPACK::Group&>(problem.getSolutionGroup())));//(problem.getSolutionGroup());//solutiongroup is constant, thus we need to assign it to be able to modify it.//throws an error if used in conjunction with lapack
  *_x1=*_x0=grp->getX();
  grp->computeF();
  *_f0=grp->getF();

	for (int i=0;i<_dimSys;i++){
		// compute F at x1=x0+2*eps*e_i and save in f1
		(*_x1)(i)=std::nextafter(std::nextafter((*_x1)(i),std::numeric_limits<double>::max()),std::numeric_limits<double>::max());
    grp->setX(*_x1);
    grp->computeF();
    *_f1=grp->getF();
		// compare
		for(int j=0;j<_dimSys;j++){
			if ((*_f0)(j)*(*_f1)(j)<=0.0){
				fSignChange[j]= true;
			}
		}
    (*_x1)(i)=(*_x0)(i);

		// do the same for x0-2*eps*e_i
		(*_x1)(i)=std::nextafter(std::nextafter((*_x1)(i),-std::numeric_limits<double>::max()),-std::numeric_limits<double>::max());
    grp->setX(*_x1);
    grp->computeF();
    *_f1=grp->getF();
		// compare
		for(int j=0;j<_dimSys;j++){
			if ((*_f0)(j)*(*_f1)(j)<=0.0){
				fSignChange[j]= true;
			}
		}
    (*_x1)(i)=(*_x0)(i);
	}
  _numSignChanges=std::count(fSignChange.begin(), fSignChange.end(), true);

  grp->setX(*_x0);
  grp->computeF();

  //return converged, if all entries of fSignChange are true, unconverged otherwise.//only available in C++-11//alternative: use _numSignChanges==_dimSys as criteria instead.
	_status = (std::all_of(fSignChange.begin(),fSignChange.end(),[](bool a){return a;})) ? NOX::StatusTest::Converged : NOX::StatusTest::Unconverged;
  return _status;
}

NOX::StatusTest::StatusType NOX::StatusTest::SgnChange::getStatus() const
{
  return _status;
}

std::ostream& NOX::StatusTest::SgnChange::print(std::ostream& stream, int indent) const
{
  for (int j = 0; j < indent; j ++)
    stream << ' ';
  stream << _status;
  stream << "Found sign changes in " << _numSignChanges;
  stream << " out of " << _dimSys;
  stream << " components.";
  stream << std::endl;
  return stream;
}
