#include "UmfPack.h"


UmfPack::UmfPack(IAlgLoop* algLoop, ILinSolverSettings* settings) : _iterationStatus(CONTINUE), _umfpackSettings(settings), _algLoop(algLoop), _jac(NULL), _rhs(NULL)
{
}

UmfPack::~UmfPack() {
  if(_jac)      delete  _jac;
  if(_rhs)     delete []  _rhs;
  if(_x)      delete [] _x;
}

void UmfPack::initialize()
{
#ifdef USE_UMFPACK
  _algLoop->setUseSparseFormat(_umfpackSettings->getUseSparseFormat());
  _algLoop->initialize();
  _jac = new sparse_matrix;
  _rhs = new double[_algLoop->getDimReal()];
  _x = new double[_algLoop->getDimReal()];
#endif
}

void UmfPack::solve()
{
#ifdef USE_UMFPACK
  _algLoop->evaluate();
  _algLoop->getRHS(_rhs);
  _algLoop->getSystemMatrix(_jac);

  int status=_jac->solve(_rhs,_x);
  if(status==0) {
      _iterationStatus=DONE;
  } else {
    _iterationStatus=SOLVERERROR;
  }
  _algLoop->setReal(_x);
#endif
}

IAlgLoopSolver::ITERATIONSTATUS UmfPack::getIterationStatus()
{
  return _iterationStatus;
}

void UmfPack::stepCompleted(double time)
{
}
