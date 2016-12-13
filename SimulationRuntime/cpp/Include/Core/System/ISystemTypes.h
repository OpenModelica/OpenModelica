#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */

 /// store attributes of a variable
struct AlgloopVarAttributes
{
  AlgloopVarAttributes() {};
  AlgloopVarAttributes(const char *name,double nominal,double minValue,double maxValue)
  :name(name)
  ,nominal(nominal)
  ,minValue(minValue)
  ,maxValue(maxValue)
  {}

  const char *name;
  double nominal;
  double minValue;
  double maxValue;
};

 /** @} */ // end of coreSystem