#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
/** @addtogroup solverKinsol
 *
 *  @{
 */

#include <Solver/Dgesv/DgesvSolverSettings.h>

DgesvSolverSettings::DgesvSolverSettings()
: _UseSparseFormat         (false)
{
};

bool DgesvSolverSettings::getUseSparseFormat(){
	return _UseSparseFormat;
}

void DgesvSolverSettings::setUseSparseFormat(bool value){
	_UseSparseFormat=value;
}

void DgesvSolverSettings::load(std::string){
	//keine ahnung ob das so stimmt, aber die load funktion macht auch in kinsol nix.
}
/** @} */ // end of solverKinsol
