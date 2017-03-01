/** @addtogroup core
 *
 *  @{
 */

typedef double modelica_real;
typedef int modelica_integer;
typedef bool modelica_boolean;
typedef bool  edge_rettype;
typedef bool sample_rettype;
typedef double cos_rettype;
typedef double cosh_rettype;
typedef double sin_rettype;
typedef double sinh_rettype;
typedef double log_rettype;
typedef double tan_rettype;
typedef double atan_rettype;
typedef double tanh_rettype;
typedef double exp_rettype;
typedef double sqrt_rettype;
typedef double abs_rettype;
typedef double max_rettype;
typedef double min_rettype;
typedef double arctan_rettype;
typedef double floorRetType;
typedef double asinRetType;
typedef double tan_rettype;
typedef double tanhRetType;
typedef double acosRetType;
typedef double logRetType;
typedef double coshRetType;

#ifndef FORCE_INLINE
  #if defined(_MSC_VER)
    #define FORCE_INLINE __forceinline
  #else
    #define FORCE_INLINE __attribute__((always_inline)) inline
  #endif
#endif

#ifndef PREFETCH
  #if defined(_MSC_VER)
    #define PREFETCH(add, rw, locality)
  #else
    #define PREFETCH(add, rw, locality) __builtin_prefetch(add, rw, locality)
  #endif
#endif

#ifndef VAR_ALIGN_PRE
  #ifdef __GNUC__
    #define VAR_ALIGN_PRE
    #define VAR_ALIGN_POST __attribute__((aligned(0x40)))
  #elif defined _MSC_VER
    #define VAR_ALIGN_PRE __declspec(align(64))
    #define VAR_ALIGN_POST
  #else
    #define VAR_ALIGN_PRE
    #define VAR_ALIGN_POST
  #endif
#endif


#ifndef BOOST_THREAD_USE_DLL
  #define BOOST_THREAD_USE_DLL
#endif
#ifndef BOOST_STATIC_LINKING
  #ifndef BOOST_ALL_DYN_LINK
    #define BOOST_ALL_DYN_LINK
  #endif
#endif

// Visual C++ 2015 by default does not link the CRT if the entry point is overriden. Force linking. Macros according to
    //  "MSDN — Predefined Macros"; library names according to "Visual C++ Team Blog — Introducing the Universal CRT".
    #if _MSC_VER >= 1900
    #       if _DEBUG
    #               if _DLL
    #                       pragma comment(lib, "vcruntimed")
    #                       pragma comment(lib, "ucrtd")
    #               else
    #                       pragma comment(lib, "libvcruntimed")
    #                       pragma comment(lib, "libucrtd")
    #               endif
    #       else
    #               if _DLL
    #                       pragma comment(lib, "vcruntime")
    #                       pragma comment(lib, "ucrt")
    #               else
    #                       pragma comment(lib, "libvcruntime")
    #                       pragma comment(lib, "libucrt")
    #               endif
    #       endif
    #endif


/** @} */ // end of core
