#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */
/*includes removed for static linking not needed any more
#ifdef RUNTIME_STATIC_LINKING
#include <boost/multi_array.hpp>
#endif
*/
class IStateSelection
{
public:
  virtual ~IStateSelection()  {};
  virtual int getDimStateSets() const = 0;
  virtual int getDimStates(unsigned int index) const = 0;
  virtual int getDimCanditates(unsigned int index) const = 0;
  virtual int getDimDummyStates(unsigned int index) const = 0;
  virtual void getStates(unsigned int index, double* z) = 0;
  virtual void setStates(unsigned int index, const double* z) = 0;
  virtual void getStateCanditates(unsigned int index, double* z) = 0;
  virtual bool getAMatrix(unsigned int index, DynArrayDim2<int> & A) = 0 ;
  virtual void setAMatrix(unsigned int index, DynArrayDim2<int>& A) = 0;
  virtual bool getAMatrix(unsigned int index, DynArrayDim1<int> & A) = 0 ;
  virtual void setAMatrix(unsigned int index, DynArrayDim1<int>& A) = 0;
};
/** @} */ // end of coreSystem
