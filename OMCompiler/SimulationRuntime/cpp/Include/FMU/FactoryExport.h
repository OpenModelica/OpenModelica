#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */

#if defined(__vxworks)

#define BOOST_EXTENSION_SOLVER_DECL
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL

#elif defined(RUNTIME_STATIC_LINKING) && (defined(OMC_BUILD) || defined(SIMSTER_BUILD))
#define BOOST_EXTENSION_LOGGER_DECL
#define BOOST_EXTENSION_XML_READER_DECL
#elif defined(OMC_BUILD) || defined(SIMSTER_BUILD)
#define BOOST_EXTENSION_LOGGER_DECL BOOST_EXTENSION_IMPORT_DECL
#define BOOST_EXTENSION_XML_READER_DECL BOOST_EXTENSION_EXPORT_DECL
#else
    error "operating system not supported"
#endif

#ifndef ENABLE_SUNDIALS_STATIC
 shared_ptr<INonLinSolverSettings> createKinsolSettings()
 {
   throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol was disabled during build");
 }
 shared_ptr<INonLinearAlgLoopSolver> createKinsolSolver(shared_ptr<INonLinSolverSettings> solver_settings,shared_ptr<INonLinearAlgLoop> algLoop)
 {
   throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol was disabled during build");
 }
#endif

 shared_ptr<ISolver> createCVode(IMixedSystem* system, shared_ptr<ISolverSettings> solver_settings)
 {
   throw ModelicaSimulationError(SOLVER,"CVode was disabled during build");
 }
 shared_ptr<ISolverSettings> createCVodeSettings(shared_ptr<IGlobalSettings> globalSettings)
 {
   throw ModelicaSimulationError(SOLVER,"CVode was disabled during build");
 }

 shared_ptr<ISolver> createIda(IMixedSystem* system, shared_ptr<ISolverSettings> solver_settings)
 {
   throw ModelicaSimulationError(SOLVER,"IDA was disabled during build");
 }
 shared_ptr<ISolverSettings> createIdaSettings(shared_ptr<IGlobalSettings> globalSettings)
 {
   throw ModelicaSimulationError(SOLVER,"IDA was disabled during build");
 }

/** @} */ // end of coreSystem
