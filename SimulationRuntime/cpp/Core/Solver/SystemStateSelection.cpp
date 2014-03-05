
#include "stdafx.h"
#include "FactoryExport.h"
#include <Solver/SystemStateSelection.h>
#include <Math/ArrayOperations.h>
#include <Math/Functions.h>


SystemStateSelection::SystemStateSelection(IMixedSystem* system)
:_system(system)
,_colPivot(NULL)
,_rowPivot(NULL)
,_initialized(false)
{
  _state_selection = dynamic_cast<IStateSelection*>(system);
  if ( !_state_selection)
  throw std::invalid_argument("No state selection system");
}
void SystemStateSelection::initialize()
{
  if(_rowPivot)        delete [] _rowPivot;
  if(_colPivot)        delete [] _colPivot;
  _dimStates = _state_selection->getDimStateSets();
  _dimStateCanditates = _state_selection->getDimCanditates();
  _dimDummyStates = _dimStateCanditates-_dimStates;
    _rowPivot        = new int[_dimDummyStates];
   _colPivot      = new   int[_dimStateCanditates];
   for(int n=0; n<_dimDummyStates; n++)
      _rowPivot[n] = n;

    for(int n=0; n<_dimStateCanditates; n++)
      _colPivot[n] = _dimStateCanditates-n-1;
  _initialized = true;
}
SystemStateSelection::~SystemStateSelection()
{
 if(_rowPivot)        delete [] _rowPivot;
  if(_colPivot)        delete [] _colPivot;
}

bool SystemStateSelection::stateSelection(int switchStates)
{
  if(!_initialized)
    initialize();
  int res=0;
  
    int* oldColPivot =  new int[_dimStateCanditates];
    int* oldRowPivot =   new int[_dimDummyStates];
    SparseMatrix stateset_matrix;
  _system->getStateSetJacobian(stateset_matrix);
  
  /* call pivoting function to select the states */
    memcpy(oldColPivot,_colPivot, _dimStateCanditates*sizeof(int));
    memcpy(oldRowPivot, _rowPivot, _dimDummyStates*sizeof(int));
  
  
  /*workarround for c array*/
  double* jac = new double[_dimDummyStates*_dimStateCanditates];
  for(int i=0;i<_dimStateCanditates;i++)
    for(int j= 0;j<_dimDummyStates;j++)
      jac[i*_dimDummyStates+j]=stateset_matrix(i,j);
  
  
  if((pivot(jac, _dimDummyStates, _dimStateCanditates, _rowPivot, _colPivot) != 0))
    {
    throw std::invalid_argument("Error, singular Jacobian for dynamic state selection at time");
  }
  
  /* if we have a new set throw event for reinitialization
       and set the A matrix for set.x=A*(states) */
    res = comparePivot(oldColPivot, _colPivot, switchStates);
    if(!switchStates)
    {
      memcpy(_colPivot, oldColPivot, _dimStateCanditates*sizeof(int));
      memcpy(_rowPivot, oldRowPivot, _dimDummyStates*sizeof(int));
    }
   delete [] oldColPivot;
   delete [] oldRowPivot;
  
    if(res)
     return true;
  else
    return false;
}

void SystemStateSelection::setAMatrix(int* newEnable)
{
  int col;
  int row=0;
  boost::multi_array<int,2> A;
  _state_selection->getAMatrix(A);
  fill_array<int,2 >(A,0);
  double* states;//states
  double* states2;//state candidates
  states = new double[_dimStates];
  states2 = new double[_dimStateCanditates];
  _state_selection->getStates(states);
   _state_selection->getStateCanditates(states2);
  for(col=0; col<_dimStateCanditates; col++)
  {
    if(newEnable[col]==2)
    {
     /* set A[row, col] */
      A[row+1][col+1] = 1;
      ///* reinit state */
      states[row] =states2[col];
      row++;
    }
  }
  _state_selection->setStates(states);
  _state_selection->setAMatrix(A);
  delete [] states ;
  delete [] states2 ; 
}


int SystemStateSelection::comparePivot(int *oldPivot, int *newPivot,int switchStates)
{
  
  int ret = 0;
  int* oldEnable = new int[_dimStateCanditates];
  int* newEnable = new int[_dimStateCanditates];

  for(int i=0; i<_dimStateCanditates; i++)
  {
    int entry = (i < _dimDummyStates) ? 1: 2;
    newEnable[ newPivot[i] ] = entry;
    oldEnable[ oldPivot[i] ] = entry;
 }

  for(int i=0; i<_dimStateCanditates; i++)
  {
    if(newEnable[i] != oldEnable[i])
    {
      if(switchStates)
      {
       
        setAMatrix(newEnable);
       
      }
      ret = -1;
      break;
    }
  }

  delete [] oldEnable;
  delete [] newEnable;

  return ret;
}