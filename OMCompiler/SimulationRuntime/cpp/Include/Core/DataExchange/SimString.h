#pragma once
/** @addtogroup dataexchange
 *
 *  @{
 */
#include "ISimVar.h"

/**
SimVar Klasse zum verwalten einer String Variable
*/
class SimString : public ISimVar
{

public:

  virtual ~SimString()  {};
  SimString(string value) {_value = value;}
  virtual string getName() {return _name;}
  virtual void setName(string name) {_name = name;}
  string& getValue() { return _value;}
private:
  string _name;
  string _value;
};
/** @} */ // end of dataexchange