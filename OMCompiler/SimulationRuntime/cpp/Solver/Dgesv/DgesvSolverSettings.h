#pragma once
/** @addtogroup solverDgesv
 *
 *  @{
 */
#include <Core/Solver/ILinSolverSettings.h>

class DgesvSolverSettings :public ILinSolverSettings
{
public:
  DgesvSolverSettings();
  virtual bool getUseSparseFormat();
  virtual void setUseSparseFormat(bool value);
  virtual void load(std::string);
private:
  bool _UseSparseFormat;		//(default: false)
};
/** @} */ // end of solverKinsol
