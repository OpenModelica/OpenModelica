/** @addtogroup solverKinsol
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#if defined(__vxworks) || defined(__TRICORE__)

#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>

extern "C" IAlgLoopSolver* createKinsol(IAlgLoop* algLoop, INonLinSolverSettings* settings)
{
    return new Kinsol(algLoop, settings);
}

extern "C" INonLinSolverSettings* createKinsolSettings()
{
    return new KinsolSettings();
}

#elif defined(SIMSTER_BUILD)

#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>

/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_kinsol(boost::extensions::factory_map & fm)
{
    fm.get<IAlgLoopSolver,int,IAlgLoop*, INonLinSolverSettings*>()[1].set<Kinsol>();
    fm.get<INonLinSolverSettings,int >()[2].set<KinsolSettings>();
}

#elif defined(OMC_BUILD)
#include <nvector/nvector_serial.h>
#include <kinsol/kinsol.h>
#ifdef USE_SUNDIALS_LAPACK
  #include <kinsol/kinsol_lapack.h>
#else
  #include <kinsol/kinsol_spgmr.h>
  #include <kinsol/kinsol_dense.h>
#endif //USE_SUNDIALS_LAPACK
#include <kinsol/kinsol_spbcgs.h>
#include <kinsol/kinsol_sptfqmr.h>
//#include <kinsol/kinsol_klu.h>
#include <kinsol/kinsol_direct.h>
#include <sundials/sundials_dense.h>
#include <kinsol/kinsol_impl.h>
#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>

using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IAlgLoopSolver,IAlgLoop*, INonLinSolverSettings*> > >()
    ["kinsol"].set<Kinsol>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["kinsolSettings"].set<KinsolSettings>();
}

#else
error "operating system not supported"
#endif
/** @} */ // end of solverKinsol
