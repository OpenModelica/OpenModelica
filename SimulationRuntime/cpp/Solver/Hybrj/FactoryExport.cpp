/** @addtogroup solverCvode
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)


#elif defined(SIMSTER_BUILD)

#include <Solver/Hybrj/Hybrj.h>
#include <Solver/Hybrj/HybrjSettings.h>


/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_hybrj(boost::extensions::factory_map & fm)
{
    fm.get<IAlgLoopSolver,int,INonLinearAlgLoop*, INonLinSolverSettings*>()[1].set<Hybrj>();
    fm.get<INonLinSolverSettings,int >()[2].set<HybrjSettings>();
}

#elif defined(OMC_BUILD)

#include <Solver/Hybrj/Hybrj.h>
#include <Solver/Hybrj/HybrjSettings.h>


using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IAlgLoopSolver,INonLinearAlgLoop*, INonLinSolverSettings*> > >()
    ["hybrj"].set<Hybrj>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["hybrjSettings"].set<HybrjSettings>();
 }


#else
error "operating system not supported"
#endif
/** @} */ // end of solverHybrj


