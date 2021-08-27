#pragma once
/** @defgroup solverNewton Solver.Broyden
 *  Nonlineaar solver class for Broyden methods
 *  @{
 */
#if defined(__vxworks) || defined(RUNTIME_STATIC_LINKING)
  #define BOOST_EXTENSION_LOGGER_DECL
  #define BOOST_EXTENSION_SOLVER_DECL
  #define BOOST_EXTENSION_SOLVERSETTINGS_DECL
#elif defined(OMC_BUILD) || defined(SIMSTER_BUILD)
  #define BOOST_EXTENSION_LOGGER_DECL BOOST_EXTENSION_IMPORT_DECL
  #define BOOST_EXTENSION_SOLVER_DECL BOOST_EXTENSION_IMPORT_DECL
  #define BOOST_EXTENSION_SOLVERSETTINGS_DECL BOOST_EXTENSION_IMPORT_DECL
#else
    error "operating system not supported"
#endif
/** @} */ // end of solverBroyden


