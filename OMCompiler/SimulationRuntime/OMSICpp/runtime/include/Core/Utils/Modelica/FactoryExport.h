#pragma once
/** @defgroup coreUtils Core.Utils
 *  Module for utility functions
 *  @{
 */
#if defined(__vxworks) || defined(__TRICORE__)
  #define BOOST_EXTENSION_EXPORT_DECL
#elif defined(OMC_BUILD) || defined(SIMSTER_BUILD)
#else
    error "operating system not supported"
#endif
/** @} */ // end of coreUtils