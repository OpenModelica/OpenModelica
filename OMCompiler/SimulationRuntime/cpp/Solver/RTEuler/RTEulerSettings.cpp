/** @addtogroup solverCvode
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/RTEuler/RTEulerSettings.h>

RTEulerSettings::RTEulerSettings(IGlobalSettings* globalSettings)
: SolverSettings    (globalSettings)
{
}


/**
initializes settings object by an xml file
*/
void RTEulerSettings::load(std::string xml_file)
{
}


 /* std::fstream ofs;
    ofs.open("C:\\Temp\\EulerSettings.xml", ios::out);
    boost::archive::xml_oarchive xml(ofs);
    xml << boost::serialization::make_nvp("EulerSettings", *this);
    ofs.close();*/
/** @} */ // end of solverRteuler