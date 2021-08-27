#pragma once
/** @addtogroup solverLinear
 *
 *  @{
 */
#include <Core/Solver/ILinSolverSettings.h>

class LinearSolverSettings :public ILinSolverSettings
{
public:
  LinearSolverSettings();
  virtual bool getUseSparseFormat();
  virtual void setUseSparseFormat(bool value);
  virtual void load(std::string);
private:
  bool _UseSparseFormat;		//(default: false)
};
/** @} */ // end of solverKinsol
