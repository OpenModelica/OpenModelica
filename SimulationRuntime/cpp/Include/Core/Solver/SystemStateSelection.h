#pragma once
/** @addtogroup coreSolver
 *
 *  @{
 */
#if defined(__TRICORE__) || defined(__vxworks)
#define BOOST_EXTENSION_STATESELECT_DECL
#endif

#include <Core/System/IStateSelection.h>
#include <boost/shared_array.hpp>

class BOOST_EXTENSION_STATESELECT_DECL SystemStateSelection
{
public:
  SystemStateSelection(IMixedSystem* system);
  ~SystemStateSelection();

  bool stateSelection(int switchStates);
  void initialize();

private:
  void setAMatrix(int* newEnable, unsigned int index);
  int comparePivot(int* oldPivot, int* newPivot, int switchStates, unsigned int index);

  IMixedSystem* _system;
  IStateSelection* _state_selection;
  vector<boost::shared_array<int> > _rowPivot;
  vector<boost::shared_array<int> > _colPivot;
  unsigned int _dimStateSets;
  vector<unsigned int> _dimStates;
  vector<unsigned int> _dimDummyStates;
  vector<unsigned int> _dimStateCanditates;
  bool _initialized;

};
 /** @} */ // end of coreSolver
