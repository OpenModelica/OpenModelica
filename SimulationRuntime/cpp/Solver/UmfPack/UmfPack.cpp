#include "UmfPack.h"
#include <iostream>
#include <fstream>

UmfPack::UmfPack(IAlgLoop* algLoop, ILinSolverSettings* settings) : _iterationStatus(CONTINUE), _umfpackSettings(settings), _algLoop(algLoop), _jac(NULL), _rhs(NULL)
{
  ofstream file;
  file.open("umfpack.out",ios::app);
  file<<"constructor"<<std::endl;
  file.close();
}

UmfPack::~UmfPack() {
  if(_jac)      delete  _jac;
  if(_rhs)     delete []  _rhs;
  if(_x)      delete [] _x;
}

void UmfPack::initialize()
{

  _algLoop->setUseSparseFormat(_umfpackSettings->getUseSparseFormat());
  _algLoop->initialize();
  _jac = new sparse_matrix;
  _rhs = new double[_algLoop->getDimReal()];
  _x = new double[_algLoop->getDimReal()];
 ofstream file;
  file.open("umfpack.out",ios::app);
  file<<"init"<<std::endl;
  file.close();
}

void UmfPack::solve()
{
      ofstream file;
  file.open("umfpack.out",ios::app);
  _algLoop->evaluate();
  file<<"evaluate"<<std::endl;
  _algLoop->getRHS(_rhs);
  file<<"getrhs"<<std::endl;
  _algLoop->getSystemMatrix(_jac);
file<<"_jac"<<std::endl;
      for(std::vector<int>::iterator it=_jac->Ap.begin(); it!=_jac->Ap.end(); it++) {
        file<<*it<<" ";
    }
    file<<std::endl;
    for(std::vector<int>::iterator it=_jac->Ai.begin(); it!=_jac->Ai.end(); it++) {
        file<<*it<<" ";
    }
    file<<std::endl;
    for(std::vector<double>::iterator it=_jac->Ax.begin(); it!=_jac->Ax.end(); it++) {
        file<<*it<<" ";
    }
    file<<std::endl;
    file.close();
  int status=_jac->solve(_rhs,_x);
  if(status==0) {
      _iterationStatus=DONE;
  } else {
    _iterationStatus=SOLVERERROR;
  }
  _algLoop->setReal(_x);
}

IAlgLoopSolver::ITERATIONSTATUS UmfPack::getIterationStatus()
{
  return _iterationStatus;
}

void UmfPack::stepCompleted(double time)
{
}
