#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */

#if defined(__vxworks) || defined(__TRICORE__) || defined(RUNTIME_STATIC_LINKING)
  #define BOOST_EXTENSION_LOGGER_DECL
#elif defined(OMC_BUILD) || defined(SIMSTER_BUILD)
  #define BOOST_EXTENSION_LOGGER_DECL BOOST_EXTENSION_EXPORT_DECL
#else
  error "operating system not supported"
#endif

/** @} */ // end of coreSystem
