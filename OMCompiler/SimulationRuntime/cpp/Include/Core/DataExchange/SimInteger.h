#pragma once
/** @addtogroup dataexchange
 *
 *  @{
 */
#include "ISimVar.h"

/**
SimVar Klasse zum verwalten einer Integer Variable
*/
class SimInteger : public ISimVar
{

public:

  virtual ~SimInteger()  {};
  SimInteger(int value) {_value = value;}
  virtual string getName() {return _name;}
  virtual void setName(string name) {_name = name;}
  int& getValue() { return _value;}
private:
  string _name;
  int _value;
};
/** @} */ // end of dataexchange