#pragma once


#ifdef _WIN32
  #ifdef BUILDING_OMC_DLL
    #define OMC_DLL __declspec(dllexport)
  #else
    #define OMC_DLL __declspec(dllimport)
  #endif
#else
  #define OMC_DLL
#endif

