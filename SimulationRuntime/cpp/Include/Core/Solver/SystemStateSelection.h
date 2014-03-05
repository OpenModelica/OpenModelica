#pragma once


class BOOST_EXTENSION_STATESELECT_DECL SystemStateSelection
{
public:
    SystemStateSelection(IMixedSystem* system);

    ~SystemStateSelection();
    
    bool stateSelection(int switchStates);
	void initialize();
  private:
   
   void setAMatrix(int* newEnable);
   int comparePivot(int *oldPivot, int *newPivot,int switchStates);
   
   
   IMixedSystem* _system;
   IStateSelection* _state_selection;
   int* _rowPivot;
   int* _colPivot;
    unsigned int  _dimStates;
	unsigned int  _dimDummyStates;
	unsigned int  _dimStateCanditates;
	bool _initialized;
};

