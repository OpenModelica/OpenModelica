/** @addtogroup solverCvode
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(OMC_BUILD)

#include <Solver/Hybrj/Hybrj.h>
#include <Solver/Hybrj/HybrjSettings.h>


using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<INonLinearAlgLoopSolver, INonLinSolverSettings*,shared_ptr<INonLinearAlgLoop> > > >()
    ["hybrj"].set<Hybrj>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["hybrjSettings"].set<HybrjSettings>();
 }


#else
error "operating system not supported"
#endif
/** @} */ // end of solverHybrj


