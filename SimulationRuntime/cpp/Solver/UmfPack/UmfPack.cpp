#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include <Solver/UmfPack/UmfPack.h>
#include <Core/Math/ILapack.h>

#ifdef USE_UMFPACK
#include "umfpack.h"
#endif

UmfPack::UmfPack(IAlgLoop* algLoop, ILinSolverSettings* settings) : _iterationStatus(CONTINUE), _umfpackSettings(settings), _algLoop(algLoop), _rhs(NULL), _x(NULL), _firstuse(true), _jacd(NULL)
{
}

UmfPack::~UmfPack()
{
    if(_jacd)   delete [] _jacd;
    if(_rhs)     delete []  _rhs;
    if(_x)      delete [] _x;
}

void UmfPack::initialize()
{
#ifdef USE_UMFPACK
    _firstuse=false;
    _algLoop->initialize();
    if(_algLoop->queryDensity()<1. &&_umfpackSettings->getUseSparseFormat() )
    {
        _algLoop->setUseSparseFormat(true);
        _jacs = boost::shared_ptr<SparseMatrix> (new SparseMatrix);
    }
    else
    {
        _jacd= new double[_algLoop->getDimReal()*_algLoop->getDimReal()];
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
    if(!_algLoop->getUseSparseFormat())
    {
        long int dimRHS  = 1;          // Dimension of right hand side of linear system (=b)
        long int dimSys = _algLoop->getDimReal();
        long int irtrn  = 0;          // Retrun-flag of Fortran code        _algLoop->getReal(_y);
        long int * _helpArray = new long int[_algLoop->getDimReal()];
        _algLoop->evaluate();
        _algLoop->getRHS(_rhs);
        _algLoop->getSystemMatrix(_jacd);
        dgesv_(&dimSys,&dimRHS,_jacd,&dimSys,_helpArray,_rhs,&dimSys,&irtrn);
        std::memcpy(_x,_rhs,dimSys*sizeof(double));
        _algLoop->setReal(_x);
        delete [] _helpArray;
    }
    else
    {
        _algLoop->evaluate();
        _algLoop->getRHS(_rhs);
        _algLoop->getSystemMatrix(_jacs);

        int status, sys=0;
        double Control [UMFPACK_CONTROL], Info [UMFPACK_INFO] ;
        void *Symbolic, *Numeric ;
        umfpack_di_defaults (Control) ;
        status = umfpack_di_symbolic (_jacs->size1(), _jacs->size2(), &_jacs->index1_data()[0], &_jacs->index2_data()[0], &_jacs->value_data()[0], &Symbolic, Control, Info) ;
        status = umfpack_di_numeric (&_jacs->index1_data()[0], &_jacs->index2_data()[0], &_jacs->value_data()[0], Symbolic, &Numeric, Control, Info);
        status = umfpack_di_solve (sys, &_jacs->index1_data()[0], &_jacs->index2_data()[0], &_jacs->value_data()[0], _x, _rhs, Numeric, Control, Info);
        umfpack_di_free_symbolic (&Symbolic);
        umfpack_di_free_numeric (&Numeric);
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
