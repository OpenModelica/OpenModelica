#ifndef fmiFunctionTypes_h
#define fmiFunctionTypes_h

/* This header file must be utilized when compiling an FMU or an FMI master.
   It declares data and function types for FMI 2.0

   Revisions:
   - Oct. 11, 2013: Functions of ModelExchange and CoSimulation merged:
                      fmiInstantiateModelTYPE , fmiInstantiateSlaveTYPE  -> fmiInstantiateTYPE
                      fmiFreeModelInstanceTYPE, fmiFreeSlaveInstanceTYPE -> fmiFreeInstanceTYPE
                      fmiEnterModelInitializationModeTYPE, fmiEnterSlaveInitializationModeTYPE -> fmiEnterInitializationModeTYPE
                      fmiExitModelInitializationModeTYPE , fmiExitSlaveInitializationModeTYPE  -> fmiExitInitializationModeTYPE
                      fmiTerminateModelTYPE , fmiTerminateSlaveTYPE  -> fmiTerminate
                      fmiResetSlave -> fmiReset (now also for ModelExchange and not only for CoSimulation)
                    Functions renamed
                      fmiUpdateDiscreteStatesTYPE -> fmiNewDiscreteStatesTYPE
                    Renamed elements of the enumeration fmiEventInfo
                      upcomingTimeEvent             -> nextEventTimeDefined // due to generic naming scheme: varDefined + var
                      newUpdateDiscreteStatesNeeded -> newDiscreteStatesNeeded;
   - June 13, 2013: Changed type fmiEventInfo
                    Functions removed:
                       fmiInitializeModelTYPE
                       fmiEventUpdateTYPE
                       fmiCompletedEventIterationTYPE
                       fmiInitializeSlaveTYPE
                    Functions added:
                       fmiEnterModelInitializationModeTYPE
                       fmiExitModelInitializationModeTYPE
                       fmiEnterEventModeTYPE
                       fmiUpdateDiscreteStatesTYPE
                       fmiEnterContinuousTimeModeTYPE
                       fmiEnterSlaveInitializationModeTYPE;
                       fmiExitSlaveInitializationModeTYPE;
   - Feb. 17, 2013: Added third argument to fmiCompletedIntegratorStepTYPE
                    Changed function name "fmiTerminateType" to "fmiTerminateModelType" (due to #113)
                    Changed function name "fmiGetNominalContinuousStateTYPE" to
                                          "fmiGetNominalsOfContinuousStatesTYPE"
                    Removed fmiGetStateValueReferencesTYPE.
   - Nov. 14, 2011: First public Version


   Copyright © 2011 MODELISAR consortium,
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

/* make sure all compiler use the same alignment policies for structures */
#if defined _MSC_VER || defined __GNUC__
#pragma pack(push,8)
#endif


/* Type definitions */
typedef enum {
    fmiOK,
    fmiWarning,
    fmiDiscard,
    fmiError,
    fmiFatal,
    fmiPending
} fmiStatus;

typedef enum {
    fmiModelExchange,
    fmiCoSimulation
} fmiType;

typedef enum {
    fmiDoStepStatus,
    fmiPendingStatus,
    fmiLastSuccessfulTime,
    fmiTerminated
} fmiStatusKind;

typedef void      (*fmiCallbackLogger)        (fmiComponentEnvironment, fmiString, fmiStatus, fmiString, fmiString, ...);
typedef void*     (*fmiCallbackAllocateMemory)(size_t, size_t);
typedef void      (*fmiCallbackFreeMemory)    (void*);
typedef void      (*fmiStepFinished)          (fmiComponentEnvironment, fmiStatus);

typedef struct {
   fmiCallbackLogger         logger;
   fmiCallbackAllocateMemory allocateMemory;
   fmiCallbackFreeMemory     freeMemory;
   fmiStepFinished           stepFinished;
   fmiComponentEnvironment   componentEnvironment;
} fmiCallbackFunctions;

typedef struct {
	 fmiBoolean newDiscreteStatesNeeded;
   fmiBoolean terminateSimulation;
   fmiBoolean nominalsOfContinuousStatesChanged;
   fmiBoolean valuesOfContinuousStatesChanged;
   fmiBoolean nextEventTimeDefined;
   fmiReal    nextEventTime;
} fmiEventInfo;


/* reset alignment policy to the one set before reading this file */
#if defined _MSC_VER || defined __GNUC__
#pragma pack(pop)
#endif


/* Define fmi function pointer types to simplify dynamic loading */

/***************************************************
Types for Common Functions
****************************************************/

/* Inquire version numbers of header files and setting logging status */
   typedef const char* fmiGetTypesPlatformTYPE();
   typedef const char* fmiGetVersionTYPE();
   typedef fmiStatus   fmiSetDebugLoggingTYPE(fmiComponent, fmiBoolean, size_t, const fmiString[]);

/* Creation and destruction of FMU instances and setting debug status */
   typedef fmiComponent fmiInstantiateTYPE (fmiString, fmiType, fmiString, fmiString, const fmiCallbackFunctions*, fmiBoolean, fmiBoolean);
   typedef void         fmiFreeInstanceTYPE(fmiComponent);

/* Enter and exit initialization mode, terminate and reset */
   typedef fmiStatus fmiSetupExperimentTYPE        (fmiComponent, fmiBoolean, fmiReal, fmiReal, fmiBoolean, fmiReal);
   typedef fmiStatus fmiEnterInitializationModeTYPE(fmiComponent);
   typedef fmiStatus fmiExitInitializationModeTYPE (fmiComponent);
   typedef fmiStatus fmiTerminateTYPE              (fmiComponent);
   typedef fmiStatus fmiResetTYPE                  (fmiComponent);

/* Getting and setting variable values */
   typedef fmiStatus fmiGetRealTYPE   (fmiComponent, const fmiValueReference[], size_t, fmiReal   []);
   typedef fmiStatus fmiGetIntegerTYPE(fmiComponent, const fmiValueReference[], size_t, fmiInteger[]);
   typedef fmiStatus fmiGetBooleanTYPE(fmiComponent, const fmiValueReference[], size_t, fmiBoolean[]);
   typedef fmiStatus fmiGetStringTYPE (fmiComponent, const fmiValueReference[], size_t, fmiString []);

   typedef fmiStatus fmiSetRealTYPE   (fmiComponent, const fmiValueReference[], size_t, const fmiReal   []);
   typedef fmiStatus fmiSetIntegerTYPE(fmiComponent, const fmiValueReference[], size_t, const fmiInteger[]);
   typedef fmiStatus fmiSetBooleanTYPE(fmiComponent, const fmiValueReference[], size_t, const fmiBoolean[]);
   typedef fmiStatus fmiSetStringTYPE (fmiComponent, const fmiValueReference[], size_t, const fmiString []);

/* Getting and setting the internal FMU state */
   typedef fmiStatus fmiGetFMUstateTYPE           (fmiComponent, fmiFMUstate*);
   typedef fmiStatus fmiSetFMUstateTYPE           (fmiComponent, fmiFMUstate);
   typedef fmiStatus fmiFreeFMUstateTYPE          (fmiComponent, fmiFMUstate*);
   typedef fmiStatus fmiSerializedFMUstateSizeTYPE(fmiComponent, fmiFMUstate, size_t*);
   typedef fmiStatus fmiSerializeFMUstateTYPE     (fmiComponent, fmiFMUstate, fmiByte[], size_t);
   typedef fmiStatus fmiDeSerializeFMUstateTYPE   (fmiComponent, const fmiByte[], size_t, fmiFMUstate*);

/* Getting partial derivatives */
   typedef fmiStatus fmiGetDirectionalDerivativeTYPE(fmiComponent, const fmiValueReference[], size_t,
                                                                   const fmiValueReference[], size_t,
                                                                   const fmiReal[], fmiReal[]);

/***************************************************
Types for Functions for FMI for Model Exchange
****************************************************/

/* Enter and exit the different modes */
   typedef fmiStatus fmiEnterEventModeTYPE         (fmiComponent);
   typedef fmiStatus fmiNewDiscreteStatesTYPE      (fmiComponent, fmiEventInfo*);
   typedef fmiStatus fmiEnterContinuousTimeModeTYPE(fmiComponent);
   typedef fmiStatus fmiCompletedIntegratorStepTYPE(fmiComponent, fmiBoolean, fmiBoolean*, fmiBoolean*);

/* Providing independent variables and re-initialization of caching */
   typedef fmiStatus fmiSetTimeTYPE            (fmiComponent, fmiReal);
   typedef fmiStatus fmiSetContinuousStatesTYPE(fmiComponent, const fmiReal[], size_t);

/* Evaluation of the model equations */
   typedef fmiStatus fmiGetDerivativesTYPE               (fmiComponent, fmiReal[], size_t);
   typedef fmiStatus fmiGetEventIndicatorsTYPE           (fmiComponent, fmiReal[], size_t);
   typedef fmiStatus fmiGetContinuousStatesTYPE          (fmiComponent, fmiReal[], size_t);
   typedef fmiStatus fmiGetNominalsOfContinuousStatesTYPE(fmiComponent, fmiReal[], size_t);


/***************************************************
Types for Functions for FMI for Co-Simulation
****************************************************/

/* Simulating the slave */
   typedef fmiStatus fmiSetRealInputDerivativesTYPE (fmiComponent, const fmiValueReference [], size_t, const fmiInteger [], const fmiReal []);
   typedef fmiStatus fmiGetRealOutputDerivativesTYPE(fmiComponent, const fmiValueReference [], size_t, const fmiInteger [], fmiReal []);

   typedef fmiStatus fmiDoStepTYPE     (fmiComponent, fmiReal, fmiReal, fmiBoolean);
   typedef fmiStatus fmiCancelStepTYPE (fmiComponent);

/* Inquire slave status */
   typedef fmiStatus fmiGetStatusTYPE       (fmiComponent, const fmiStatusKind, fmiStatus* );
   typedef fmiStatus fmiGetRealStatusTYPE   (fmiComponent, const fmiStatusKind, fmiReal*   );
   typedef fmiStatus fmiGetIntegerStatusTYPE(fmiComponent, const fmiStatusKind, fmiInteger*);
   typedef fmiStatus fmiGetBooleanStatusTYPE(fmiComponent, const fmiStatusKind, fmiBoolean*);
   typedef fmiStatus fmiGetStringStatusTYPE (fmiComponent, const fmiStatusKind, fmiString* );


#ifdef __cplusplus
}  /* end of extern "C" { */
#endif

#endif /* fmiFunctionTypes_h */
