#if !defined(OMC_INTERFACE)
#define OMC_INTERFACE

#if (defined _MSC_VER) && _MSC_VER<1300
#pragma warning (disable : 4786)
#endif

#if defined( _WIN32 ) && defined( _MSC_VER )
# if defined OMC_EXPORTS
#  define OMC_API __declspec( dllexport )
#   else
#  define OMC_API __declspec( dllimport )
# pragma warning( disable : 4251 )// 'identifier' : class 'type' needs to have dll-interface to be used by clients of class 'type2'
# endif
#endif

#if !defined(OMC_API)
#define OMC_API
#endif

#endif

#ifndef __GNUC__
#pragma warning(  disable : 4297 )        // Issue warning 4297
#endif
