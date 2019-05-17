#pragma once
/** @addtogroup dataexchange
 *
 *  @{
 */
#include "ISimVar.h"

/**
SimVar Klasse zum verwalten einer Boolean Variable
*/
class SimBoolean : public ISimVar
{

public:
  virtual ~SimBoolean()  {};
  SimBoolean(bool value) {_value = value;}
  virtual string getName() {return _name;}
  virtual void setName(string name) {_name = name;}
  bool& getValue() { return _value;}
private:
  string _name;
  bool _value;
};
/** @} */ // end of dataexchange