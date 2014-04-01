#ifndef fmiFunctions_h
#define fmiFunctions_h

/* This header file must be utilized when compiling a FMU.
   It defines all functions of the
         FMI 2.0 Model Exchange and Co-Simulation Interface.

   In order to have unique function names even if several FMUs
   are compiled together (e.g. for embedded systems), every "real" function name
   is constructed by prepending the function name by "FMI_FUNCTION_PREFIX".
   Therefore, the typical usage is:

      #define FMI_FUNCTION_PREFIX MyModel_
      #include "fmiFunctions.h"

   As a result, a function that is defined as "fmiGetDerivatives" in this header file,
   is actually getting the name "MyModel_fmiGetDerivatives".

   This only holds if the FMU is shipped in C source code, or is compiled in a
   static link library. For FMUs compiled in a DLL/sharedObject, the "actual" function
   names are used and "FMI_FUNCTION_PREFIX" must not be defined.

   Revisions:
   - Oct. 11, 2013: Functions of ModelExchange and CoSimulation merged:
                      fmiInstantiateModel , fmiInstantiateSlave  -> fmiInstantiate
                      fmiFreeModelInstance, fmiFreeSlaveInstance -> fmiFreeInstance
                      fmiEnterModelInitializationMode, fmiEnterSlaveInitializationMode -> fmiEnterInitializationMode
                      fmiExitModelInitializationMode , fmiExitSlaveInitializationMode  -> fmiExitInitializationMode
                      fmiTerminateModel, fmiTerminateSlave  -> fmiTerminate
                      fmiResetSlave -> fmiReset (now also for ModelExchange and not only for CoSimulation)
                    Functions renamed:
                      fmiUpdateDiscreteStates -> fmiNewDiscreteStates
   - June 13, 2013: Functions removed:
                       fmiInitializeModel
                       fmiEventUpdate
                       fmiCompletedEventIteration
                       fmiInitializeSlave
                    Functions added:
                       fmiEnterModelInitializationMode
                       fmiExitModelInitializationMode
                       fmiEnterEventMode
                       fmiUpdateDiscreteStates
                       fmiEnterContinuousTimeMode
                       fmiEnterSlaveInitializationMode;
                       fmiExitSlaveInitializationMode;
   - Feb. 17, 2013: Portability improvements:
                       o DllExport changed to FMI_Export
                       o FUNCTION_PREFIX changed to FMI_FUNCTION_PREFIX
                       o Allow undefined FMI_FUNCTION_PREFIX (meaning no prefix is used)
                    Changed function name "fmiTerminate" to "fmiTerminateModel" (due to #113)
                    Changed function name "fmiGetNominalContinuousState" to
                                          "fmiGetNominalsOfContinuousStates"
                    Removed fmiGetStateValueReferences.
   - Nov. 14, 2011: Adapted to FMI 2.0:
                       o Split into two files (fmiFunctions.h, fmiTypes.h) in order
                         that code that dynamically loads an FMU can directly
                         utilize the header files).
                       o Added C++ encapsulation of C-part, in order that the header
                         file can be directly utilized in C++ code.
                       o fmiCallbackFunctions is passed as pointer to fmiInstantiateXXX
                       o stepFinished within fmiCallbackFunctions has as first
                         argument "fmiComponentEnvironment" and not "fmiComponent".
                       o New functions to get and set the complete FMU state
                         and to compute partial derivatives.
   - Nov.  4, 2010: Adapted to specification text:
                       o fmiGetModelTypesPlatform renamed to fmiGetTypesPlatform
                       o fmiInstantiateSlave: Argument GUID     replaced by fmuGUID
                                              Argument mimetype replaced by mimeType
                       o tabs replaced by spaces
   - Oct. 16, 2010: Functions for FMI for Co-simulation added
   - Jan. 20, 2010: stateValueReferencesChanged added to struct fmiEventInfo (ticket #27)
                    (by M. Otter, DLR)
                    Added WIN32 pragma to define the struct layout (ticket #34)
                    (by J. Mauss, QTronic)
   - Jan.  4, 2010: Removed argument intermediateResults from fmiInitialize
                    Renamed macro fmiGetModelFunctionsVersion to fmiGetVersion
                    Renamed macro fmiModelFunctionsVersion to fmiVersion
                    Replaced fmiModel by fmiComponent in decl of fmiInstantiateModel
                    (by J. Mauss, QTronic)
   - Dec. 17, 2009: Changed extension "me" to "fmi" (by Martin Otter, DLR).
   - Dez. 14, 2009: Added eventInfo to meInitialize and added
                    meGetNominalContinuousStates (by Martin Otter, DLR)
   - Sept. 9, 2009: Added DllExport (according to Peter Nilsson's suggestion)
                    (by A. Junghanns, QTronic)
   - Sept. 9, 2009: Changes according to FMI-meeting on July 21:
                    meInquireModelTypesVersion     -> meGetModelTypesPlatform
                    meInquireModelFunctionsVersion -> meGetModelFunctionsVersion
                    meSetStates                    -> meSetContinuousStates
                    meGetStates                    -> meGetContinuousStates
                    removal of meInitializeModelClass
                    removal of meGetTime
                    change of arguments of meInstantiateModel
                    change of arguments of meCompletedIntegratorStep
                    (by Martin Otter, DLR):
   - July 19, 2009: Added "me" as prefix to file names (by Martin Otter, DLR).
   - March 2, 2009: Changed function definitions according to the last design
                    meeting with additional improvements (by Martin Otter, DLR).
   - Dec. 3 , 2008: First version by Martin Otter (DLR) and Hans Olsson (Dynasim).

   Copyright © 2008-2011 MODELISAR consortium,
               2012-2013 Modelica Association Project "FMI"
               All rights reserved.
   This file is licensed by the copyright holders under the BSD 2-Clause License
   (http://www.opensource.org/licenses/bsd-license.html):

   ----------------------------------------------------------------------------
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   - Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.
   - Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.
   - Neither the name of the copyright holders nor the names of its
     contributors may be used to endorse or promote products derived
     from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
   OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
   ----------------------------------------------------------------------------

   with the extension:

   You may distribute or publicly perform any modification only under the
   terms of this license.
   (Note, this means that if you distribute a modified file,
    the modified file must also be provided under this license).
*/

#ifdef __cplusplus
extern "C" {
#endif

#include "fmiTypesPlatform.h"
#include "fmiFunctionTypes.h"
#include <stdlib.h>


/*
  Export FMI API functions on Windows and under GCC.
  If custom linking is desired then the FMI_Export must be
  defined before including this file. For instance,
  it may be set to __declspec(dllimport).
*/
#if !defined(FMI_Export) && !defined(FMI_FUNCTION_PREFIX)
 #if defined _WIN32 || defined __CYGWIN__
  /* Note: both gcc & MSVC on Windows support this syntax. */
      #define FMI_Export __declspec(dllexport)
 #else
  #if __GNUC__ >= 4
    #define FMI_Export __attribute__ ((visibility ("default")))
  #else
    #define FMI_Export
  #endif
 #endif
#endif

/* Macros to construct the real function name
   (prepend function name by FMI_FUNCTION_PREFIX) */
#if defined(FMI_FUNCTION_PREFIX)
  #define fmiPaste(a,b)     a ## b
  #define fmiPasteB(a,b)    fmiPaste(a,b)
  #define fmiFullName(name) fmiPasteB(FMI_FUNCTION_PREFIX, name)
#else
  #define fmiFullName(name) name
#endif

/***************************************************
Common Functions
****************************************************/
#define fmiGetTypesPlatform         fmiFullName(fmiGetTypesPlatform)
#define fmiGetVersion               fmiFullName(fmiGetVersion)
#define fmiSetDebugLogging          fmiFullName(fmiSetDebugLogging)
#define fmiInstantiate              fmiFullName(fmiInstantiate)
#define fmiFreeInstance             fmiFullName(fmiFreeInstance)
#define fmiSetupExperiment          fmiFullName(fmiSetupExperiment)
#define fmiEnterInitializationMode  fmiFullName(fmiEnterInitializationMode)
#define fmiExitInitializationMode   fmiFullName(fmiExitInitializationMode)
#define fmiTerminate                fmiFullName(fmiTerminate)
#define fmiReset                    fmiFullName(fmiReset)
#define fmiGetReal                  fmiFullName(fmiGetReal)
#define fmiGetInteger               fmiFullName(fmiGetInteger)
#define fmiGetBoolean               fmiFullName(fmiGetBoolean)
#define fmiGetString                fmiFullName(fmiGetString)
#define fmiSetReal                  fmiFullName(fmiSetReal)
#define fmiSetInteger               fmiFullName(fmiSetInteger)
#define fmiSetBoolean               fmiFullName(fmiSetBoolean)
#define fmiSetString                fmiFullName(fmiSetString)
#define fmiGetFMUstate              fmiFullName(fmiGetFMUstate)
#define fmiSetFMUstate              fmiFullName(fmiSetFMUstate)
#define fmiFreeFMUstate             fmiFullName(fmiFreeFMUstate)
#define fmiSerializedFMUstateSize   fmiFullName(fmiSerializedFMUstateSize)
#define fmiSerializeFMUstate        fmiFullName(fmiSerializeFMUstate)
#define fmiDeSerializeFMUstate      fmiFullName(fmiDeSerializeFMUstate)
#define fmiGetDirectionalDerivative fmiFullName(fmiGetDirectionalDerivative)


/***************************************************
Functions for FMI for Model Exchange
****************************************************/
#define fmiEnterEventMode                fmiFullName(fmiEnterEventMode)
#define fmiNewDiscreteStates             fmiFullName(fmiNewDiscreteStates)
#define fmiEnterContinuousTimeMode       fmiFullName(fmiEnterContinuousTimeMode)
#define fmiCompletedIntegratorStep       fmiFullName(fmiCompletedIntegratorStep)
#define fmiSetTime                       fmiFullName(fmiSetTime)
#define fmiSetContinuousStates           fmiFullName(fmiSetContinuousStates)
#define fmiGetDerivatives                fmiFullName(fmiGetDerivatives)
#define fmiGetEventIndicators            fmiFullName(fmiGetEventIndicators)
#define fmiGetContinuousStates           fmiFullName(fmiGetContinuousStates)
#define fmiGetNominalsOfContinuousStates fmiFullName(fmiGetNominalsOfContinuousStates)


/***************************************************
Functions for FMI for Co-Simulation
****************************************************/
#define fmiSetRealInputDerivatives      fmiFullName(fmiSetRealInputDerivatives)
#define fmiGetRealOutputDerivatives     fmiFullName(fmiGetRealOutputDerivatives)
#define fmiDoStep                       fmiFullName(fmiDoStep)
#define fmiCancelStep                   fmiFullName(fmiCancelStep)
#define fmiGetStatus                    fmiFullName(fmiGetStatus)
#define fmiGetRealStatus                fmiFullName(fmiGetRealStatus)
#define fmiGetIntegerStatus             fmiFullName(fmiGetIntegerStatus)
#define fmiGetBooleanStatus             fmiFullName(fmiGetBooleanStatus)
#define fmiGetStringStatus              fmiFullName(fmiGetStringStatus)

/* Version number */
#define fmiVersion "2.0"


/***************************************************
Common Functions
****************************************************/

/* Inquire version numbers of header files */
   FMI_Export fmiGetTypesPlatformTYPE fmiGetTypesPlatform;
   FMI_Export fmiGetVersionTYPE       fmiGetVersion;
   FMI_Export fmiSetDebugLoggingTYPE  fmiSetDebugLogging;

/* Creation and destruction of FMU instances */
   FMI_Export fmiInstantiateTYPE  fmiInstantiate;
   FMI_Export fmiFreeInstanceTYPE fmiFreeInstance;

/* Enter and exit initialization mode, terminate and reset */
   FMI_Export fmiSetupExperimentTYPE         fmiSetupExperiment;
   FMI_Export fmiEnterInitializationModeTYPE fmiEnterInitializationMode;
   FMI_Export fmiExitInitializationModeTYPE  fmiExitInitializationMode;
   FMI_Export fmiTerminateTYPE               fmiTerminate;
   FMI_Export fmiResetTYPE                   fmiReset;

/* Getting and setting variables values */
   FMI_Export fmiGetRealTYPE    fmiGetReal;
   FMI_Export fmiGetIntegerTYPE fmiGetInteger;
   FMI_Export fmiGetBooleanTYPE fmiGetBoolean;
   FMI_Export fmiGetStringTYPE  fmiGetString;

   FMI_Export fmiSetRealTYPE    fmiSetReal;
   FMI_Export fmiSetIntegerTYPE fmiSetInteger;
   FMI_Export fmiSetBooleanTYPE fmiSetBoolean;
   FMI_Export fmiSetStringTYPE  fmiSetString;

/* Getting and setting the internal FMU state */
   FMI_Export fmiGetFMUstateTYPE            fmiGetFMUstate;
   FMI_Export fmiSetFMUstateTYPE            fmiSetFMUstate;
   FMI_Export fmiFreeFMUstateTYPE           fmiFreeFMUstate;
   FMI_Export fmiSerializedFMUstateSizeTYPE fmiSerializedFMUstateSize;
   FMI_Export fmiSerializeFMUstateTYPE      fmiSerializeFMUstate;
   FMI_Export fmiDeSerializeFMUstateTYPE    fmiDeSerializeFMUstate;

/* Getting partial derivatives */
   FMI_Export fmiGetDirectionalDerivativeTYPE fmiGetDirectionalDerivative;


/***************************************************
Functions for FMI for Model Exchange
****************************************************/

/* Enter and exit the different modes */
   FMI_Export fmiEnterEventModeTYPE               fmiEnterEventMode;
   FMI_Export fmiNewDiscreteStatesTYPE            fmiNewDiscreteStates;
   FMI_Export fmiEnterContinuousTimeModeTYPE      fmiEnterContinuousTimeMode;
   FMI_Export fmiCompletedIntegratorStepTYPE      fmiCompletedIntegratorStep;

/* Providing independent variables and re-initialization of caching */
   FMI_Export fmiSetTimeTYPE             fmiSetTime;
   FMI_Export fmiSetContinuousStatesTYPE fmiSetContinuousStates;

/* Evaluation of the model equations */
   FMI_Export fmiGetDerivativesTYPE                fmiGetDerivatives;
   FMI_Export fmiGetEventIndicatorsTYPE            fmiGetEventIndicators;
   FMI_Export fmiGetContinuousStatesTYPE           fmiGetContinuousStates;
   FMI_Export fmiGetNominalsOfContinuousStatesTYPE fmiGetNominalsOfContinuousStates;


/***************************************************
Functions for FMI for Co-Simulation
****************************************************/

/* Simulating the slave */
   FMI_Export fmiSetRealInputDerivativesTYPE  fmiSetRealInputDerivatives;
   FMI_Export fmiGetRealOutputDerivativesTYPE fmiGetRealOutputDerivatives;

   FMI_Export fmiDoStepTYPE     fmiDoStep;
   FMI_Export fmiCancelStepTYPE fmiCancelStep;

/* Inquire slave status */
   FMI_Export fmiGetStatusTYPE        fmiGetStatus;
   FMI_Export fmiGetRealStatusTYPE    fmiGetRealStatus;
   FMI_Export fmiGetIntegerStatusTYPE fmiGetIntegerStatus;
   FMI_Export fmiGetBooleanStatusTYPE fmiGetBooleanStatus;
   FMI_Export fmiGetStringStatusTYPE  fmiGetStringStatus;

#ifdef __cplusplus
}  /* end of extern "C" { */
#endif

#endif /* fmiFunctions_h */