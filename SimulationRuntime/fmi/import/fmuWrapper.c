#ifndef FMUWRAPPER_C
#define FMUWRAPPER_C

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>


/* Define for Debuging */
/*#define _PRINT_OUT__ */
/*#define _DEBUG_ */


#define BUFSIZE 4096

#include "fmuWrapper.h"

#ifdef __cplusplus
extern "C"{
#endif
/* get model type platform */
const char* fmiGetModelTypesPF(void* in_fmi){
  FMI* fmi = (FMI*) in_fmi;
  if(fmi->getModelTypesPlatform){
    return(fmi->getModelTypesPlatform());
  }
  else{
    printf("#### fmiGetModelTypesPF(...) failed...\n");
    exit(EXIT_FAILURE);
  }
}

/* get applied FMI version */
const char* fmiGetVer(void* in_fmi){
  FMI* fmi = (FMI*) in_fmi;
  if(fmi->getVersion){
    return(fmi->getVersion());
  }
  else{
    printf("#### fmiGetModelTypesPF(...) failed...\n");
    exit(EXIT_FAILURE);
  }
}

/* get process address from the dll */
void* getProAdr(FMI* fmi, const char* mid, const char* funName){
  char name[BUFSIZE];
  void* funPointer;
  sprintf(name, "%s_%s", mid, funName);
  funPointer = (void*) getFunctionPointerFromDLL(fmi->dllHandle, name);
  if (!funPointer) {
    printf("#### Error! Loading function %s_%s in dll failed!!!\n",mid,funName);
    exit(EXIT_FAILURE);
  }
  else  return funPointer;
}

/* Load the given dll and set function pointers in fmi */
void* loadFMUDll(void* in_fmi, const char* pathFMUDll,const char* mid){
  FMI* fmi = (FMI*) in_fmi;
  char* pathFMUSO;
  char* err_dlopen;
  int pathLen;
  pathLen = strlen(pathFMUDll);
  pathFMUSO = (char*)calloc(pathLen+2, sizeof(char));
  //strcat(pathFMUSO,"./");
  strncat(pathFMUSO,pathFMUDll,pathLen-3);
  strcat(pathFMUSO,".so");
  pathFMUSO[pathLen+1] = '\0';
#if defined(__MINGW32__) || defined(_MSC_VER)
  fmi->dllHandle = LoadLibrary(pathFMUDll);
#else
  fmi->dllHandle = dlopen(pathFMUSO, RTLD_LOCAL | RTLD_NOW);
#endif
  if(!fmi->dllHandle){
#ifdef _DEBUG_
#if defined(__MINGW32__) || defined(_MSC_VER)
    printf("#### Loading dll library \"%s\" in fmiInstantiate failed!!!\n",pathFMUDll);
#else
    err_dlopen = dlerror();
    printf("#### Error message: \"%s\"!!!\n",err_dlopen);
    printf("#### Loading dll library \"%s\" in fmiInstantiate failed!!!\n",pathFMUSO);
#endif
#endif
    exit(EXIT_FAILURE);
  }
  fmi->getModelTypesPlatform   = (fGetModelTypesPlatform)   getProAdr(fmi, mid, "fmiGetModelTypesPlatform");
  fmi->getVersion              = (fGetVersion)              getProAdr(fmi, mid, "fmiGetVersion");
  fmi->instantiateModel        = (fInstantiateModel)        getProAdr(fmi, mid, "fmiInstantiateModel");
  fmi->freeModelInstance       = (fFreeModelInstance)       getProAdr(fmi, mid, "fmiFreeModelInstance");
  fmi->setDebugLogging         = (fSetDebugLogging)         getProAdr(fmi, mid, "fmiSetDebugLogging");
  fmi->setTime                 = (fSetTime)                 getProAdr(fmi, mid, "fmiSetTime");
  fmi->setContinuousStates     = (fSetContinuousStates)     getProAdr(fmi, mid, "fmiSetContinuousStates");
  fmi->completedIntegratorStep = (fCompletedIntegratorStep) getProAdr(fmi, mid, "fmiCompletedIntegratorStep");
  fmi->setReal                 = (fSetReal)                 getProAdr(fmi, mid, "fmiSetReal");
  fmi->setInteger              = (fSetInteger)              getProAdr(fmi, mid, "fmiSetInteger");
  fmi->setBoolean              = (fSetBoolean)              getProAdr(fmi, mid, "fmiSetBoolean");
  fmi->setString               = (fSetString)               getProAdr(fmi, mid, "fmiSetString");
  fmi->initialize              = (fInitialize)              getProAdr(fmi, mid, "fmiInitialize");
  fmi->getDerivatives          = (fGetDerivatives)          getProAdr(fmi, mid, "fmiGetDerivatives");
  fmi->getEventIndicators      = (fGetEventIndicators)      getProAdr(fmi, mid, "fmiGetEventIndicators");
  fmi->getReal                 = (fGetReal)                 getProAdr(fmi, mid, "fmiGetReal");
  fmi->getInteger              = (fGetInteger)              getProAdr(fmi, mid, "fmiGetInteger");
  fmi->getBoolean              = (fGetBoolean)              getProAdr(fmi, mid, "fmiGetBoolean");
  fmi->getString               = (fGetString)               getProAdr(fmi, mid, "fmiGetString");
  fmi->eventUpdate             = (fEventUpdate)             getProAdr(fmi, mid, "fmiEventUpdate");
  fmi->getContinuousStates     = (fGetContinuousStates)     getProAdr(fmi, mid, "fmiGetContinuousStates");
  fmi->getNominalContinuousStates = (fGetNominalContinuousStates) getProAdr(fmi, mid, "fmiGetNominalContinuousStates");
  fmi->getStateValueReferences = (fGetStateValueReferences) getProAdr(fmi, mid, "fmiGetStateValueReferences");
  fmi->terminate               = (fTerminate)               getProAdr(fmi, mid, "fmiTerminate");
#ifdef _DEBUG_
  printf("\n\n#### Loading dll library in instantiateFMIFun succeeded!!!\n");
#endif
  /* void *dummy = NULL; // only for return void pointer required in OpenModelica */
  return NULL; /* dummy; */
}
void freeFMUDll(void* dummy){
  return;
} /* dummy for Modelica */

/* --------------------------------------------------------------
 * setters of specified FMI functions
 * --------------------------------------------------------------
 * set flag for debugging
 * FMI stardard interface */
void fmiSetDebugLog(void* in_fmi, void* in_fmu, char log){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  if(fmi->setDebugLogging){
    status = fmi->setDebugLogging(in_fmu,log);
    if(status>fmiWarning){
      printf("#### fmiSetDebugLog(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return;
}

/* set simulation time
 * FMI standard interface
 */
double fmiSetT(void* in_fmi, void* in_fmu, double in_t, double in_flowControl){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  if(fmi->setTime){
    status = fmi->setTime(in_fmu,in_t);
#ifdef _PRINT_OUT__
    printf("\n#### fmiSetTime time: = %f\n",in_t);
#endif
    if(status>fmiWarning){
      printf("#### fmiSetTime(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return in_flowControl;
}

/* set new continuous states of the model
 * FMI standard interface
 */
double fmiSetContStates(void* in_fmi, void* in_fmu, const double* in_x, int nx, double in_flowControl){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  if(fmi->setContinuousStates){
    status = fmi->setContinuousStates(in_fmu,in_x,nx);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<nx;i++){
      printf("\n#### fmiSetContStates[%d] = %f\n",i,in_x[i]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiSetContStates(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return in_flowControl;
}

/* set real variable values via an array of value references
 * FMI standard interface
 */
double fmiSetRealVR(void* in_fmi, void* in_fmu, const int* in_vr, const double* rv, int nvr, double in_flowControl){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  const unsigned int* vr = (const unsigned int*) in_vr;
  if(fmi->setReal){
    status = fmi->setReal(in_fmu,vr,nvr,rv);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<nvr;i++){
      printf("\n#### fmiSetReal[%d] = %f\n",i,rv[i]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiSetReal(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return in_flowControl;
}

/* set integer variable values via an array of value references
 * FMI standard interface
 */
double fmiSetIntegerVR(void* in_fmi, void* in_fmu, const int* in_vr, const int* iv, int nvr, double in_flowControl){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  const unsigned int* vr = (const unsigned int*) in_vr;
  if(fmi->setInteger){
    status = fmi->setInteger(in_fmu,vr,nvr,iv);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<nvr;i++){
      printf("\n#### fmiSetInteger[%d] = %d\n",i,((ModelInstance*)in_fmu)->i[in_vr[i]]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiSetInteger(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return in_flowControl;
}


/* set string variable values via an array of the the value refercences
 * FMI standard interface
 */
double fmiSetStringVR(void* in_fmi, void* in_fmu, const int* in_vr, const char** sv, int nvr, double in_flowControl){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  const unsigned int* vr = (const unsigned int*) in_vr;
  if(fmi->setString){
    status = fmi->setString(in_fmu,vr,nvr,sv);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<nvr;i++){
      printf("\n#### fmiSetString[%d] = %s\n",i,((ModelInstance*)in_fmu)->s[in_vr[i]]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiSetString(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return in_flowControl;
}

/* set boolean variable values via an array of the the value refercences
 * FMI standard interface
 */
double fmiSetBooleanVR(void* in_fmi, void* in_fmu, const int* in_vr, const int* in_bv, int nvr, double in_flowControl){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  const unsigned int* vr = (const unsigned int*) in_vr;
  const fmiBoolean* bv = (const fmiBoolean*) in_bv;
  if(fmi->setBoolean){
    status = fmi->setBoolean(in_fmu,vr,nvr,bv);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<nvr;i++){
      printf("\n#### fmiSetString[%d] = %c\n",i,((ModelInstance*)in_fmu)->b[in_vr[i]]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiSetBoolean(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return in_flowControl;
}

/* fmiCompletedIntegratorStep(...) for step event
 * FMI standard interface
 */
double fmiCompIntStep(void* in_fmi, void* in_fmu, void* in_stepEvt, double in_flowControl){ /* in_events is an array of modelica boolean array */
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  fmiBoolean* stepEvt = (fmiBoolean*) in_stepEvt;
  if(fmi->completedIntegratorStep){
    status = fmi->completedIntegratorStep(in_fmu,stepEvt);
#ifdef _PRINT_OUT__
    printf("\n#### fmiCompletedIntegratorStep stepEvent: = %d\n",*stepEvt);
#endif
    if(status>fmiWarning){
      printf("#### fmiCompletedIntegratorStep(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return in_flowControl;
}

/* --------------------------------------------------------------
 * getters of specified FMI functions
 * --------------------------------------------------------------
 * get values of the continuous states
 * FMI standard interface
 */
void fmiGetContStates(void* in_fmi, void* in_fmu, double* out_x, int nx){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  if(fmi->getContinuousStates){
    status = fmi->getContinuousStates(in_fmu,out_x,nx);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<nx;i++){
      printf("\n#### fmiGetContStates[%d] = %f\n",i,out_x[i]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiGetContStates(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return;
}

/* get nonminal values of the continuous states
 * FMI standard interface
 */
void fmiGetNomContStates(void* in_fmi, void* in_fmu, double* x_nom, int nx){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  if(fmi->getNominalContinuousStates){
    status = fmi->getNominalContinuousStates(in_fmu,x_nom,nx);
    if(status>fmiWarning){
      printf("#### fmiGetNomContStates(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return;
}
/* get state value refercences
 * FMI standard interface
 */
void fmiGetStateVR(void* in_fmi, void* in_fmu, int* in_vrx, int nx){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  unsigned int* vrx = (unsigned int*) in_vrx;
  if(fmi->getStateValueReferences){
    status = fmi->getStateValueReferences(in_fmu,vrx,nx);
    if(status>fmiWarning){
      printf("#### fmiGetStateVR(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return;
}

/* get the value of the derivaties of all continous states
 * FMI standard interface
 */
void fmiGetDer(void* in_fmi, void* in_fmu, double* der_x, int nx, const double* x, double in_flowControl){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  if(fmi->getDerivatives)
  {
    status = fmi->getDerivatives(in_fmu,der_x,nx);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<nx;i++){
      printf("\n#### fmiGetDerivatives[%d] = %f\n",i,der_x[i]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiGetDerivatives(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return;
}

/* get real variable values via an array of the the value refercences
 * FMI standard interface
 */
void fmiGetRealVR(void* in_fmi, void* in_fmu, const int* in_vr, double* rv, int nvr, double in_flowControl){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  const unsigned int* vr = (const unsigned int*) in_vr;
  if(fmi->getReal){
    status = fmi->getReal(in_fmu,vr,nvr,rv);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<nvr;i++){
      printf("\n#### fmiGetReal[%d] = %f\n",i,rv[i]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiGetReal(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return;
}

/* get integer variable values via an array of the the value refercences
 * FMI standard interface
 */
void fmiGetIntegerVR(void* in_fmi, void* in_fmu, const int* in_vr, int* iv, int nvr, double in_flowControl){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  const unsigned int* vr = (const unsigned int*) in_vr;
  if(fmi->getInteger){
    status = fmi->getInteger(in_fmu,vr,nvr,iv);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<nvr;i++){
      printf("\n#### fmiGetInteger[%d] = %d\n",i,((ModelInstance*)in_fmu)->i[in_vr[i]]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiGetInteger(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return;
}

/* get integer variable values via an array of the the value refercences
 * FMI standard interface
 */
void fmiGetStringVR(void* in_fmi, void* in_fmu, const int* in_vr, const char** sv, int nvr, double in_flowControl){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  const unsigned int* vr = (const unsigned int*) in_vr;
  if(fmi->getString){
    status = fmi->getString(in_fmu,vr,nvr,sv);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<nvr;i++){
      printf("\n#### fmiGetString[%d] = %s\n",i,((ModelInstance*)in_fmu)->s[in_vr[i]]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiGetString(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return;
}

/* get boolean variable values via an array of the the value refercences
 * FMI standard interface
 */
void fmiGetBooleanVR(void* in_fmi, void* in_fmu, const int* in_vr, int* bv, int nvr, double in_flowControl){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  const unsigned int* vr = (const unsigned int*) in_vr;
  char* cbv = (char*) malloc(sizeof(char)*nvr);
  if(fmi->getBoolean){
    status = fmi->getBoolean(in_fmu,vr,nvr,cbv);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<nvr;i++){
      printf("\n#### fmiGetBoolean[%d] = %c\n",i,((ModelInstance*)in_fmu)->b[in_vr[i]]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiGetBoolean(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  /*
   * convert fmuBoolean (char)
   * to Modelica Boolean (int)
   */
  int i;
  for(i=0;i<nvr;i++)
    bv[i] = cbv[i] ? 1 : 0;
  return;
}

/* get time event during the simulation */
void fmiGetTimeEvent(void * in_evtInfo, double in_time, double in_pretime, void * in_timeEvt, double* out_nextTime){
  fmiEventInfo * evtInfo = (fmiEventInfo*) in_evtInfo;
  fmiBoolean * timeEvt = (fmiBoolean*) in_timeEvt;
  double dt = in_time - in_pretime;
  double nextTime = in_time + dt;
  /* printf("#### dt = %f, in_time = %f, in_pretime = %f, nextTime = %f\n",dt,in_time,in_pretime, nextTime); */
  *timeEvt = (evtInfo->upcomingTimeEvent)&&(evtInfo->nextEventTime < nextTime);
  if(*timeEvt) *out_nextTime = 2.5; /* evtInfo->nextEventTime; */
  return;
}

/* get event indicators of the model
 * FMI standard interface
 */
void fmiGetEventInd(void* in_fmi, void* in_fmu, double* z, int ni){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  if(fmi->getEventIndicators)  {
    status = fmi->getEventIndicators(in_fmu,z,ni);
#ifdef _PRINT_OUT__
    int i;
    for(i=0;i<ni;i++){
      printf("\n#### fmiGetEventIndicators[%d] = %f\n",i,z[i]);
    }
#endif
    if(status>fmiWarning){
      printf("#### fmiGetEventIndicators(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return;
}

/* check state event
 * helper function to check the occurance of a state event
 */
void fmuStateEventCheck(void* stateEvt, int ni, const double* z, const double* prez){
  int i;
  /* signed char retv; */
  *((fmiBoolean*) stateEvt) = fmiFalse;
  for(i = 0; i < ni; i++) *((fmiBoolean*) stateEvt) = *((fmiBoolean*) stateEvt)||(prez[i]*z[i] < 0);
#ifdef _PRINT_OUT__
  for(i=0;i<ni;i++){
    printf("\n#### fmuStateEventCheck[%d] = %f, prez[%d] = %f, stateEvt = %d \n",i,z[i], i, prez[i], *((fmiBoolean*) stateEvt));
  }
#endif
  if(*((fmiBoolean*) stateEvt)==fmiTrue){
    /* *flag = -0.5;
     * printf("#### flag = %f\n",*flag); */
  }
  else{
    /* *flag = 0.5;
     * printf("#### flag = %f\n",*flag); */
  }
  return;/* retv; */
}

/* --------------------------------------------------------------
 * other specified FMI functions
 * --------------------------------------------------------------
 * event update at time, step or state event
 * FMI standard interface
 */
void fmiEvtUpdate(void* in_fmi, void* in_fmu,fmiBoolean inter_res, fmiEventInfo* in_evtInfo){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  if(fmi->eventUpdate){
    status = fmi->eventUpdate(in_fmu,inter_res,in_evtInfo);
    if(status>fmiWarning){
      printf("#### fmiEventUpdate(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return;
}

/* wrapper for fmiEventUpdate, update the event if any */
void fmuEventUpdate(void * in_fmufun, void * in_inst, void * in_evtInfo, void * timeEvt, void * stepEvt, void * stateEvt, void * interMediateRes){
  /* printf("#### ----- timeEvt %d, stepEvt %d, stateEvt %d\n",*((fmiBoolean*)timeEvt),*((fmiBoolean*)stepEvt),*((fmiBoolean*)stateEvt)); */
#ifdef _PRINT_OUT__
  printf("#### eventInfo->stateValuesChanged = %d\n",((fmiEventInfo*) in_evtInfo)->stateValuesChanged);
#endif
  /*if(*((fmiBoolean*)timeEvt)||*((fmiBoolean*)stepEvt)||*((fmiBoolean*)stateEvt)){*/
  fmiEvtUpdate(in_fmufun,in_inst,*((fmiBoolean*)interMediateRes),(fmiEventInfo*) in_evtInfo);
#ifdef _PRINT_OUT__
    printf("#### fmiEvtUpdate(...) has been called ...\n\n");
#endif
  /*}*/
  return;
}

/* logger function for printing screen message
 * logger(c, comp->instanceName, fmiOK, "log", "fmiSetTime: time=%.16g", time); */
void fmuLogger(void* in_fmu, const char* instanceName, fmiStatus status,
    const char* category, const char* message, ...){
  va_list message_args;
  va_start(message_args, message);
  printf("[ '%s', %d, '%s'",instanceName,status,category);
  vprintf(message, message_args);
  printf("]\n");
  va_end(message_args);
}

/* instantiation of an fmiComponent instance, i.e. an FMU
 * FMI standard interface */
void* fmiInstantiate(void* in_fmi, const char* instanceName,  const char* GUID, void* in_functions, int logFlag){
  FMI* fmi = (FMI*) in_fmi;
  fmiComponent fmu = NULL;
  fmiCallbackFunctions* functions = (fmiCallbackFunctions*) in_functions;
  fmiBoolean loggingon = fmiFalse;
  if(logFlag) loggingon = fmiTrue;
#ifdef _DEBUG_
  printf("#### loggingon is %d\n",loggingon);
#endif
  if(fmi->instantiateModel)
  {
#ifdef _DEBUG_
    printf("#### the address of fmi->instantiateModel is %x ...\n",fmi->instantiateModel);
#endif
    fmu = fmi->instantiateModel(instanceName,GUID,*functions,loggingon);
#ifdef _DEBUG_
    printf("#### the address of fmu(%s) is %x ...\n",instanceName,fmu);
#endif
    if(!fmu){
      printf("#### fmiInstantiateModel(...) failed...\n");
      exit(EXIT_FAILURE);
    }

  }
  return (fmu);
}

/* initialization of the instantiated FMU
 * FMI standard interface
 */
void fmiInit(void* in_fmi, void* in_fmu, int tolCont, double rTol, void* in_evtInfo){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
#ifdef _DEBUG_
  printf("\n#### fmiInit has been called here ... \n\n");
#endif
  if (fmi->flagInit ==0){
    fmiEventInfo* eventInfo = (fmiEventInfo*) in_evtInfo;
    fmiBoolean tolControl = fmiFalse;
    if(tolCont) tolControl = fmiTrue;
    if(fmi->initialize){
      status = fmi->initialize(in_fmu,tolControl,rTol,eventInfo);
      fmi->flagInit = 1;
      if(status>fmiWarning){
        printf("#### fmiInitialize(...) failed...\n");
        exit(EXIT_FAILURE);
      }
    }
  }
#ifdef _DEBUG_
  printf("\n#### fmiInit has been called ... \n\n");
#endif
  return;
}

/* terminate a FMU and release all resources
 * FMI stardard interface
 */
void fmiTerminator(void* in_fmi, void* in_fmu){
  FMI* fmi = (FMI*) in_fmi;
  fmiStatus status;
  if(fmi->terminate){
    status = fmi->terminate(in_fmu);
    if(status>fmiWarning){
      printf("#### fmiTerminator(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
  return;
}

/* constructor and destructor of FMI structure containing loaded interface functions */
void* instantiateFMIFun(const char* mid, const char* pathFMUDll){
  void* fmi = malloc(sizeof(FMI));
  ((FMI*) fmi)->flagInit = 0;
  loadFMUDll(fmi, pathFMUDll,mid);
#ifdef _DEBUG_
  printf("\n#### instantiateFMIFun has been called here ... \n\n");
#endif
  return fmi;
}

void freeFMUFun(void* in_fmufun){
  FMI* fmi = (FMI*) in_fmufun;
  FreeLibraryFromHandle(fmi->dllHandle);
#ifdef _DEBUG_
  printf("\n#### freeFMIFun has been called here ... \n\n");
#endif
  free(fmi);
}

/* constructor and destructor of helper structure fmuBoolean containing event information */
void* fmuBooleanInst(int def_bool){
  void* fmubool = malloc(sizeof(fmiBoolean));
  if(def_bool) *((fmiBoolean*) fmubool) = fmiTrue;
  else *((fmiBoolean*) fmubool) = fmiFalse;
#ifdef _DEBUG_
  printf("\n#### fmuBooleanInst has been called here ... \n\n");
#endif
  return fmubool;
}

void freefmuBooleanInst(void* in_bool){
  free(in_bool);
#ifdef _DEBUG_
  printf("\n#### freefmuBooleanInst has been called here ... \n\n");
#endif
  return;
}

void* fmuFreeAll(void* in_fmufun, void* in_inst, void* functions){
  fmiFreeModelInst(in_fmufun, in_inst);
  freeFMUFun(in_fmufun);
  fmiFreeCallbackFuns(functions);
  return NULL;
}

// free the allocated memory for FMU
// FMI standard interface
void fmiFreeModelInst(void* in_fmufun, void* in_fmu){
  FMI* fmi = (FMI*) in_fmufun;
  if(fmi->freeModelInstance){
    fmi->freeModelInstance(in_fmu);
    if(!in_fmu){
      printf("#### fmiFreeModelInstance(...) failed...\n");
      exit(EXIT_FAILURE);
    }
  }
#ifdef _DEBUG_
  printf("\n#### fmiFreeModelInst has been called here ... \n\n");
#endif
  return;
}

// void fmiFreeModelInst(void* in_fmu){
//    void* dllHandle = LoadLibraryFromDLL(FMU_BINARIES_Win32_DLL);
//  fFreeModelInstance freeModelInstance  = (fFreeModelInstance)   getFunctionPointerFromDLL(dllHandle, "bouncingBall_fmiFreeModelInstance");
//    if(freeModelInstance){
//          freeModelInstance(in_fmu);
//          if(!in_fmu){
//            printf("#### fmiFreeModelInstance(...) failed...\n");
//            exit(EXIT_FAILURE);
//          }
//    }
//  #ifdef _DEBUG_
//  printf("\n#### fmiFreeModelInst has been called here ... \n\n");
//  #endif
//    return;
//}

/* constructor and destructor of structure for fmiCallbackFunctions */
void* fmiCallbackFuns(){
  void* functions = malloc(sizeof(fmiCallbackFunctions));
  ((fmiCallbackFunctions*) functions)->logger = fmuLogger;
  ((fmiCallbackFunctions*) functions)->allocateMemory = calloc;
  ((fmiCallbackFunctions*) functions)->freeMemory = free;
#ifdef _DEBUG_
  printf("\n#### fmiCallbackFuns has been called here ... \n\n");
#endif
  return functions;
}
void fmiFreeCallbackFuns(void * functions){
  free(functions);
}

/* constructor and destructor of structure for fmiCallbackFunctions */
void* fmiEvtInfo(){
  void* evtInfo = malloc(sizeof(fmiEventInfo));
#ifdef _DEBUG_
  printf("\n#### fmiEvtInfo has been called here ... \n\n");
#endif
  return evtInfo;
}

void freefmiEvtInfo(void* in_evtInfo){
  free(in_evtInfo);
#ifdef _DEBUG_
  printf("\n#### freefmiEvtInfo has been called here ... \n\n");
#endif
  return;
}

void fmiFreeDummy(void * dummy){
  return;
}

/* print variables from simulation environment */
void printVariables(const double * var, int n, const char* varName){
  int i;
  printf("\n\n#### ------------------------------------- (%s)\n",varName);
  printf("#### number of variables is: %d\n",n);

  for(i = 0; i < n; i++) printf("var[%d]: %f\n",i,var[i]);
  printf("#### -------------------------------------\n\n");
  return;
}

void printIntVariables(const int * var, int n, const char* varName){
  int i;
  printf("\n\n#### ------------------------------------- (%s)\n",varName);
  printf("#### number of variables is: %d\n",n);
  for(i = 0; i < n; i++) printf("var[%d]: %d\n",i,var[i]);
  printf("#### -------------------------------------\n\n");
  return;
}
#ifdef __cplusplus
} /* extern "C" */
#endif
/* ------------------------------------------------------------------------
 * main test block
 * ------------------------------------------------------------------------
 */
#ifdef _TEST_FMI
int main(int argc, char *argv[])
{
  void* fmi = instantiateFMIFun(FMU_BINARIES_Win32_DLL);
  double dt = 0.02;
  double preTimer, endTime = 0.08;
  /* test block of fmiGetDer(...) */
  double * x = (double*)malloc(sizeof(double)*NUMBER_OF_STATES);
  x[0] = 1;
  x[1] = 0;
  double * der_x = (double*)malloc(sizeof(double)*NUMBER_OF_STATES);
  int nx = NUMBER_OF_STATES;
  double timer;
  timer = 0;
  /* test block of fmiGetEventInd(...) */
  double * z = (double*)malloc(sizeof(double)*NUMBER_OF_EVENT_INDICATORS);
  double * prez = (double*)malloc(sizeof(double)*NUMBER_OF_EVENT_INDICATORS);
  int ni = NUMBER_OF_EVENT_INDICATORS;
  /* variables for event handling */
  fmiBoolean timeEvent, stepEvent, stateEvent;
  /* -------------------------------------------------------------- */
  loadFMUDll(fmi,FMU_BINARIES_Win32_DLL);
#ifdef _DEBUG_
  printf("#### the address of fmi->dllHandle is %d ...\n",((FMI*)fmi)->dllHandle);
  printf("#### fmi->getModelTypesPlatform is: %s\n",((FMI*)fmi)->getModelTypesPlatform());
  printf("#### fmi->getVersion is: %s\n",((FMI*)fmi)->getVersion());
  printf("-----------------------------------------------------------\n\n");
#endif

  /* -------------------------------------------------------------- */
  /* Instantiation of FMU */
  fmiString instanceName="bouncingBall";
  fmiString GUID="{8c4e810f-3df3-4a00-8276-176fa3c9f003}"; /* fmusdk */
  /* fmiString GUID = "{9d95f943-e636-4f71-8d7d-6f54c4128f13}"; // dymola 7.4 */
  /* fmiString GUID = "{4e78de7b-7813-41d4-a68b-110ca1e861d0}"; // openmodelica 1.7.0 */
  void* functions = fmiCallbackFuns();
  fmiBoolean loggingon;
  loggingon=fmiFalse;
  fmiComponent c1 = fmiInstantiate(fmi,instanceName, GUID, functions, loggingon);
  fmiComponent c2 = fmiInstantiate(fmi,instanceName, GUID, functions, loggingon);
  if((c1)&&(c2)){
    printf("#### fmiInstantiate succedded....\n");
    printf("#### the address of fmiComponent c1: %x, c2: %x...\n",c1,c2);
    printf("#### c1->instanceName: %s\n",((ModelInstance*)c1)->instanceName);
    printf("#### c1->GUID: %s\n",((ModelInstance*)c1)->GUID);
    printf("#### c1->time: %f\n",((ModelInstance*)c1)->time);
    printf("-----------------------------------------------------------\n\n");
  }
  else {
    printf("#### fmiInstantiate failed....\n");
    exit(EXIT_FAILURE);
  }
  /* --------------------------------------------------------------
   * test block of void fmiSetT(void* in_fmi, void* in_fmu, double in_t)
   */
  fmiSetT(fmi,c1,timer);
#ifdef _DEBUG_
  printf("#### c1->time: %f\n",((ModelInstance*)c1)->time);
  printf("-----------------------------------------------------------\n\n");
#endif
  /* --------------------------------------------------------------
   * Initialization of FMU
   */
  fmiEventInfo* eventInfo = (fmiEventInfo*)fmiEvtInfo();
  fmiInit(fmi,c1,fmiTrue,0.0001,eventInfo);
  if(eventInfo->terminateSimulation){
    printf("#### Simulation of model(%s) terminated at time t = .16g\n",((ModelInstance*)c1)->instanceName,((ModelInstance*)c1)->time);
    endTime = timer;
  }

  /* -------------------------------------------------------------- */

  int i;
  while(timer<endTime){
#ifdef _DEBUG_
    printf("-----------------------------------------------------------\n\n");
    printf("#### Simulation results at time t = %f\n",((ModelInstance*)c1)->time);
#endif
    /* test block of void fmiGetContStates(void* in_fmi, void* in_fmu, double* in_x, int nx) */
    fmiGetContStates(fmi,c1,x,NUMBER_OF_STATES);
#ifdef _DEBUG_
    for(i = 0; i < NUMBER_OF_STATES; i++){
      printf("#### valude of der_x[%d]: %f\n",i,der_x[i]);
      printf("#### valude of x[%d]: %f\n\n",i,x[i]);
    }
#endif

    /* test block of fmiGetDer(...) */
    fmiGetDer(fmi,c1,der_x,nx,x);

    preTimer = timer; /* record of previous time */
    timer = min(timer+dt,endTime); /* calculate next time */
    timeEvent = (eventInfo->upcomingTimeEvent)&&(eventInfo->nextEventTime<timer); /* check for time event */
    if(timeEvent) timer = eventInfo->nextEventTime; /* set the timer to next event time if time event triggered */
    dt = timer-preTimer; /* calculate the new time step */
    fmiSetT(fmi,c1,timer); /* set new time */

    /* perform the time integration */
    for(i = 0; i < NUMBER_OF_STATES; i++){
      /* printf("#### valude of der_x[%d]: %f\n",i,der_x[i]); */
      x[i] += der_x[i]*dt;
#ifdef _DEBUG_
      printf("#### valude of x[%d]: %f\n",i,x[i]);
#endif
    }

    /* test block of fmiSetContStates */
    fmiSetContStates(fmi,c1,x,NUMBER_OF_STATES);

    /* test block of fmiCompletedIntegratorStep(...) */
    fmiCompIntStep(fmi,c1, &stepEvent);

    /* test block of fmiGetEventInd(...)   */
    for(i = 0; i < NUMBER_OF_EVENT_INDICATORS; i++){
      prez[i] = z[i];
#ifdef _DEBUG_
      printf("#### valude of z[%d]: %f\n",i,z[i]);
#endif
    }
#ifdef _DEBUG_
    printf("-----------------------------------------------------------\n\n");
#endif
    fmiGetEventInd(fmi,c1,z,ni);
    stateEvent = fmiFalse;
    for(i = 0; i < NUMBER_OF_EVENT_INDICATORS; i++) stateEvent = stateEvent||(prez[i]*z[i]<0);

    /* event handling */
    if(timeEvent||stepEvent||stateEvent){
      /* test block of fmiEventUpdate(...) */

      fmiEvtUpdate(fmi,c1,fmiFalse, eventInfo);

      if(eventInfo->terminateSimulation){
        printf("#### Simulation of model(%s) terminated at time t = .16g\n",((ModelInstance*)c1)->instanceName,((ModelInstance*)c1)->time);
        break;
      }

      if(eventInfo->stateValuesChanged && loggingon){
        printf("#### State values of model(%s) changed at time t = .16g\n",((ModelInstance*)c1)->instanceName,((ModelInstance*)c1)->time);
      }

      if(eventInfo->stateValuesChanged && loggingon){
        printf("#### State value references of model(%s) changed at time t = .16g\n",((ModelInstance*)c1)->instanceName,((ModelInstance*)c1)->time);
      }

    }/* if(timeEvent||stepEvent||stateEvent) */

    /* test of voiod
     * fmiGetRealVR(void* in_fmi, void* in_fmu, const int* in_vr, double* rv, int nvr)
     * fmiSetRealVr(void* in_fmi, void* in_fmu, const int* in_vr, const double* rv, int nvr) */
    int nv = 5;
    const int vr[5] = {0,1,2,3,4};
    double* rv = (double*)malloc(sizeof(double)*nv);
    fmiGetRealVR(fmi,c1,vr,rv,5);
    double* in_rv = (double*)malloc(sizeof(double)*nv);

    for(i = 0; i < nv; i++){
      printf("#### fmiGetRealVR rv[%d] : %f\n",i,rv[i]);
      in_rv[i] = rv[i]+0.001;
    }
    fmiSetRealVR(fmi,c1,vr,(const double*)in_rv,5);
    fmiGetRealVR(fmi,c1,vr,rv,5);
    for(i = 0; i < nv; i++){
      printf("#### fmiSetRealVR rv[%d] : %f\n",i,rv[i]);
    }

  } /* while(...) */


  /* free pre-allocated memory */
  free(x);
  free(der_x);
  free(z);
  free(prez);
  fmiFreeModelInst(c1);
  freeFMIFun(fmi);
  freefmiEvtInfo(eventInfo);
  fmiFreeCallbackFuns(functions);
  printf("#### Simulation done...\n\n");
  system("PAUSE");
  return EXIT_SUCCESS;
}
#endif /* _TEST_FMI */
#endif
