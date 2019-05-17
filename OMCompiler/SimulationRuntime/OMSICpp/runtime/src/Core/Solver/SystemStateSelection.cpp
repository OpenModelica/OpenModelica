/** @addtogroup coreSolver
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Solver/FactoryExport.h>
#include <Core/Solver/SystemStateSelection.h>
#include <Core/Math/ArrayOperations.h>
#include <Core/Math/Functions.h>


SystemStateSelection::SystemStateSelection(IMixedSystem* system)
  :_system(system)
  ,_colPivot()
  ,_rowPivot()
  ,_initialized(false)

{

  _state_selection = dynamic_cast<IStateSelection*>(system);
  if ( !_state_selection)
    throw ModelicaSimulationError(MATH_FUNCTION,"No state selection system");

}

void SystemStateSelection::initialize()
{
#if defined(__vxworks)
#else
  _dimStateSets = _state_selection->getDimStateSets();

  _dimStates.clear();
  _dimStateCanditates.clear();
  _dimDummyStates.clear();
  _rowPivot.clear();
  _colPivot.clear();
  for(int i=0; i<_dimStateSets; i++)
  {
    _dimStates.push_back(_state_selection->getDimStates(i));
    _dimStateCanditates.push_back(_state_selection->getDimCanditates(i));
    _dimDummyStates.push_back(_dimStateCanditates[i]-_dimStates[i]);

    _rowPivot.push_back(boost::shared_array<int>(new int[_dimDummyStates[i]]));
    _colPivot.push_back(boost::shared_array<int>(new int[_dimStateCanditates[i]]));
    for(int n=0; n<_dimDummyStates[i]; n++)
      _rowPivot[i][n] = n;

    for(int n=0; n<_dimStateCanditates[i]; n++)
      _colPivot[i][n] = _dimStateCanditates[i]-n-1;
  }


  _initialized = true;
#endif
}

SystemStateSelection::~SystemStateSelection()
{
#if defined(__vxworks)
#else
  _rowPivot.clear();
  _colPivot.clear();
#endif
}

bool SystemStateSelection::stateSelection(int switchStates)
{
#if defined(__vxworks)
return true;

#else
  if(!_initialized)
    initialize();
  int res=0;
  int changed = false;
  for(int i=0; i<_dimStateSets; i++)
  {
    boost::shared_array<int> oldColPivot(new int[_dimStateCanditates[i]]);
    boost::shared_array<int> oldRowPivot(new int[_dimDummyStates[i]]);
    const matrix_t& stateset_matrix =  _system->getStateSetJacobian(i);

    /* call pivoting function to select the states */



    memcpy(oldColPivot.get(), _colPivot[i].get(), _dimStateCanditates[i]*sizeof(int));
    memcpy(oldRowPivot.get(), _rowPivot[i].get(), _dimDummyStates[i]*sizeof(int));

    const double* jac =    stateset_matrix.data().begin();
    int* piv=_colPivot[i].get();

   double* jac_ = new double[_dimDummyStates[i]*_dimStateCanditates[i]];
   memcpy(jac_, jac, _dimDummyStates[i]*_dimStateCanditates[i]*sizeof(double));



    if((pivot(jac_, _dimDummyStates[i], _dimStateCanditates[i], _rowPivot[i].get(), _colPivot[i].get()) != 0))
    {
      throw ModelicaSimulationError(MATH_FUNCTION,"Error, singular Jacobian for dynamic state selection at time");
    }
    /* if we have a new set throw event for reinitialization
    and set the A matrix for set.x=A*(states) */
    res = comparePivot(oldColPivot.get(), _colPivot[i].get(), switchStates,i);
    if(!switchStates)
    {
      memcpy(_colPivot[i].get(), oldColPivot.get(), _dimStateCanditates[i]*sizeof(int));
      memcpy(_rowPivot[i].get(), oldRowPivot.get(), _dimDummyStates[i]*sizeof(int));


    }
    delete [] jac_;
    if(res)
      changed = true;
    else
      changed = false;
  }
  return changed;
#endif
}

void SystemStateSelection::setAMatrix(int* newEnable, unsigned int index)
{
#if defined(__vxworks)
#else
  int col;
  int row=0;
  DynArrayDim2<int> A2;
  DynArrayDim1<int> A1;
  double* states;//states
  double* states2;//state candidates
  states = new double[_dimStates[index]];
  states2 = new double[_dimStateCanditates[index]];
  _state_selection->getStates(index,states);
  _state_selection->getStateCanditates(index,states2);

  if( _state_selection->getAMatrix(index,A2))
  {
    fill_array<int>(A2,0);

    for(col=0; col<_dimStateCanditates[index]; col++)
    {
      if(newEnable[col]==2)
      {
        /* set A[row, col] */
        A2(row+1,col+1) = 1;
        ///* reinit state */
        states[row] =states2[col];
        row++;
      }
    }
    _state_selection->setAMatrix(index,A2);

  }
  else if( _state_selection->getAMatrix(index,A1))
  {
    fill_array<int>(A1,0);

    for(col=0; col<_dimStateCanditates[index]; col++)
    {
      if(newEnable[col]==2)
      {
        /* set A[row, col] */
        A1(row+col+1) = 1;
        ///* reinit state */
        states[row] =states2[col];
        row++;
      }
    }
    _state_selection->setAMatrix(index,A1);
  }
  else
    throw ModelicaSimulationError(MATH_FUNCTION,"No A matrix availibale for state selection");
  _state_selection->setStates(index,states);
  delete [] states ;
  delete [] states2 ;
#endif
}


int SystemStateSelection::comparePivot(int *oldPivot, int *newPivot,int switchStates,unsigned int index)
{

  int ret = 0;
  int* oldEnable = new int[_dimStateCanditates[index] ];
  int* newEnable = new int[_dimStateCanditates[index] ];

  for(int i=0; i<_dimStateCanditates[index]; i++)
  {
    int entry = (i < _dimDummyStates[index]) ? 1: 2;
    newEnable[ newPivot[i] ] = entry;
    oldEnable[ oldPivot[i] ] = entry;
  }

  for(int i=0; i<_dimStateCanditates[index]; i++)
  {
    if(newEnable[i] != oldEnable[i])
    {
      if(switchStates)
      {

        setAMatrix(newEnable,index);

      }
      ret = -1;
      break;
    }
  }

  delete [] oldEnable;
  delete [] newEnable;

  return ret;
}
 /** @} */ // end of coreSolver
