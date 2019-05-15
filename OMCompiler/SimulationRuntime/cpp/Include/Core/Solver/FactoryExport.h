#pragma once
/** @defgroup coreSolver Core.Solver
 *  Base module for all solver
 *  @{
 */
#if defined(__vxworks) || defined(__TRICORE__) || defined(RUNTIME_STATIC_LINKING)

#define BOOST_EXTENSION_SOLVER_DECL
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL
#define BOOST_EXTENSION_STATESELECT_DECL
#define BOOST_EXTENSION_MONITOR_DECL

#elif defined(OMC_BUILD) || defined(SIMSTER_BUILD)

#define BOOST_EXTENSION_SOLVER_DECL BOOST_EXTENSION_EXPORT_DECL
#define BOOST_EXTENSION_STATESELECT_DECL BOOST_EXTENSION_EXPORT_DECL
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL BOOST_EXTENSION_EXPORT_DECL
#define BOOST_EXTENSION_MONITOR_DECL BOOST_EXTENSION_EXPORT_DECL
#else
    error "operating system not supported"
#endif

 /** @} */ // end of coreSolver

