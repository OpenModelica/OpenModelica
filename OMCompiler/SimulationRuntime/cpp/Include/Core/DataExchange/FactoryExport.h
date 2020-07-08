#pragma once
/** @addtogroup dataexchange
*
*  @{
*/
#if defined(__vxworks)

#define BOOST_EXTENSION_SOLVER_DECL
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL
#define BOOST_EXTENSION_XML_READER_DECL
#define BOOST_EXTENSION_LOGGER_DECL

#elif defined(RUNTIME_STATIC_LINKING) && (defined(OMC_BUILD) || defined(SIMSTER_BUILD))
#define BOOST_EXTENSION_LOGGER_DECL
#define BOOST_EXTENSION_XML_READER_DECL
#elif defined(OMC_BUILD) || defined(SIMSTER_BUILD)
#define BOOST_EXTENSION_LOGGER_DECL BOOST_EXTENSION_IMPORT_DECL
#define BOOST_EXTENSION_XML_READER_DECL BOOST_EXTENSION_EXPORT_DECL
#else
    error "operating system not supported"
#endif
/** @} */
