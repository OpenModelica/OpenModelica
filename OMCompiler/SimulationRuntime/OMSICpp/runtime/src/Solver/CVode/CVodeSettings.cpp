/** @addtogroup solverCvode
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include <Solver/CVode/CVodeSettings.h>

CVodeSettings::CVodeSettings(IGlobalSettings* globalSettings)
  : SolverSettings    (globalSettings)
  ,_denseOutput(true)
{
};
 CVodeSettings::~CVodeSettings()
 {

 }
bool CVodeSettings::getDenseOutput()
{
  return _denseOutput;
}
void CVodeSettings::setDenseOutput(bool dense)
{
  _denseOutput = dense;
}
/** @} */ // end of solverCvode