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

#if defined(RUNTIME_STATIC_LINKING)
#undef BOOST_EXTENSION_STATESELECT_DECL
#define BOOST_EXTENSION_STATESELECT_DECL
#endif

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
  std::vector<boost::shared_array<int> > _rowPivot;
  std::vector<boost::shared_array<int> > _colPivot;
  unsigned int _dimStateSets;
  std::vector<unsigned int> _dimStates;
  std::vector<unsigned int> _dimDummyStates;
  std::vector<unsigned int> _dimStateCanditates;
  bool _initialized;
};
 /** @} */ // end of coreSolver