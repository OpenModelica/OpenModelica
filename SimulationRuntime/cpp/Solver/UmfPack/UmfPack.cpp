#include <Solver/UmfPack/UmfPack.h>

UmfPack::UmfPack(IAlgLoop* algLoop, ILinSolverSettings* settings) : _iterationStatus(CONTINUE), _umfpackSettings(settings), _algLoop(algLoop), _jacs(NULL), _rhs(NULL), _firstuse(true), _jacd(NULL)
{
}

UmfPack::~UmfPack() {
  if(_jacd)   delete [] _jacd;
  if(_jacs)      delete  _jacs;
  if(_rhs)     delete []  _rhs;
  if(_x)      delete [] _x;
}

void UmfPack::initialize()
{
#ifdef USE_UMFPACK
  _firstuse=false;
  _algLoop->initialize();
  if(_algLoop->queryDensity()<1. &&_umfpackSettings->getUseSparseFormat() ) {
    _algLoop->setUseSparseFormat(true);
    _jacs = new sparse_matrix;
  } else {
    _jacd=new double[_algLoop->getDimReal()*_algLoop->getDimReal()];
    _algLoop->setUseSparseFormat(false);
  }


  _rhs = new double[_algLoop->getDimReal()];
  _x = new double[_algLoop->getDimReal()];
#endif
}

void UmfPack::solve()
{
#ifdef USE_UMFPACK
  if(_firstuse) initialize();
  if(!_algLoop->getUseSparseFormat()) {
        long int dimRHS  = 1;          // Dimension of right hand side of linear system (=b)
        long int dimSys = _algLoop->getDimReal();
        long int irtrn  = 0;          // Retrun-flag of Fortran code        _algLoop->getReal(_y);
        double * _helpArray = new double[_algLoop->getDimReal()];
        _algLoop->evaluate();
        _algLoop->getRHS(_rhs);
        _algLoop->getSystemMatrix(_jacd);
        dgesv_(&dimSys,&dimRHS,_jacd,&dimSys,_helpArray,_rhs,&dimSys,&irtrn);
        memcpy(_x,_rhs,dimSys*sizeof(double));
        _algLoop->setReal(_x);
  } else {
       _algLoop->evaluate();
      _algLoop->getRHS(_rhs);
      _algLoop->getSystemMatrix(_jacs);

      int status=_jacs->solve(_rhs,_x);
      if(status==0) {
          _iterationStatus=DONE;
      } else {
        _iterationStatus=SOLVERERROR;
      }
      _algLoop->setReal(_x);
  }

#endif
}

IAlgLoopSolver::ITERATIONSTATUS UmfPack::getIterationStatus()
{
  return _iterationStatus;
}

void UmfPack::stepCompleted(double time)
{
}
