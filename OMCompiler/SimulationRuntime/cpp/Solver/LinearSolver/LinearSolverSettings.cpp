#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
/** @addtogroup solverKinsol
 *
 *  @{
 */

#include <Solver/LinearSolver/LinearSolverSettings.h>

LinearSolverSettings::LinearSolverSettings()
  : _UseSparseFormat  (false)
{
}

bool LinearSolverSettings::getUseSparseFormat()
{
  return _UseSparseFormat;
}

void LinearSolverSettings::setUseSparseFormat(bool value)
{
  _UseSparseFormat = value;
}

void LinearSolverSettings::load(std::string)
{
  //keine ahnung ob das so stimmt, aber die load funktion macht auch in kinsol nix.
}
/** @} */ // end of solverKinsol
