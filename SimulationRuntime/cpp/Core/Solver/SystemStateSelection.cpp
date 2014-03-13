
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
}
SystemStateSelection::~SystemStateSelection()
{
	_rowPivot.clear();
	_colPivot.clear();
}

bool SystemStateSelection::stateSelection(int switchStates)
{
	if(!_initialized)
		initialize();
	int res=0;
	int changed = false;
	for(int i=0; i<_dimStateSets; i++)
	{
		boost::shared_array<int> oldColPivot(new int[_dimStateCanditates[i]]);
		boost::shared_array<int> oldRowPivot(new int[_dimDummyStates[i]]);
		SparseMatrix stateset_matrix;
		_system->getStateSetJacobian(i,stateset_matrix);

		/* call pivoting function to select the states */


		memcpy(oldColPivot.get(), _colPivot[i].get(), _dimStateCanditates[i]*sizeof(int));
		memcpy(oldRowPivot.get(), _rowPivot[i].get(), _dimDummyStates[i]*sizeof(int));




		/*workarround for c array*/
		double* jac = new double[_dimDummyStates[i]*_dimStateCanditates[i]];
		for(int k=0;k<_dimStateCanditates[i];k++)
			for(int j= 0;j<_dimDummyStates[i];j++)
				jac[k*_dimDummyStates[i]+j]=stateset_matrix(k,j);


		if((pivot(jac, _dimDummyStates[i], _dimStateCanditates[i], _rowPivot[i].get(), _colPivot[i].get()) != 0))
		{
			throw std::invalid_argument("Error, singular Jacobian for dynamic state selection at time");
		}

		/* if we have a new set throw event for reinitialization
		and set the A matrix for set.x=A*(states) */
		res = comparePivot(oldColPivot.get(), _colPivot[i].get(), switchStates,i);
		if(!switchStates)
		{
			memcpy(_colPivot[i].get(), oldColPivot.get(), _dimStateCanditates[i]*sizeof(int));
			memcpy(_rowPivot[i].get(), oldRowPivot.get(), _dimDummyStates[i]*sizeof(int));


		}
		delete [] jac;
		if(res)
		   changed = true;
	   else
		  changed = false;
	}  
	return changed;
	
}

void SystemStateSelection::setAMatrix(int* newEnable,unsigned int index)
{
	int col;
	int row=0;
	boost::multi_array<int,2> A;
	_state_selection->getAMatrix(index,A);
	fill_array<int,2 >(A,0);
	double* states;//states
	double* states2;//state candidates
	states = new double[_dimStates[index]];
	states2 = new double[_dimStateCanditates[index]];
	_state_selection->getStates(index,states);
	_state_selection->getStateCanditates(index,states2);
	for(col=0; col<_dimStateCanditates[index]; col++)
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
	_state_selection->setStates(index,states);
	_state_selection->setAMatrix(index,A);
	delete [] states ;
	delete [] states2 ; 
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