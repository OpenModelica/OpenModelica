#pragma once
/** @defgroup solverHybrj Solver.Hybrj
 *  Hybrj class wrapper from Minpack package
 *  @{
 */
#if defined(__vxworks) || defined(RUNTIME_STATIC_LINKING)
  #define BOOST_EXTENSION_SOLVER_DECL
  #define BOOST_EXTENSION_SOLVERSETTINGS_DECL
#elif defined(OMC_BUILD) || defined(SIMSTER_BUILD)
  #define BOOST_EXTENSION_SOLVER_DECL BOOST_EXTENSION_IMPORT_DECL
  #define BOOST_EXTENSION_SOLVERSETTINGS_DECL BOOST_EXTENSION_IMPORT_DECL
#else
  error "operating system not supported"
#endif

/** @} */ // end of solverHybrj

