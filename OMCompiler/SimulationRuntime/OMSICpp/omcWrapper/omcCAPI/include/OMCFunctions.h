
#ifndef OMC_H
#define OMC_H


#include "meta/meta_modelica.h"
#include "scripting-API/OpenModelicaScriptingAPI.h"

extern "C" {
int omc_Main_handleCommand(void* threadData, void* imsg, void** omsg);
void* omc_Main_init(void* threadData, void* args);
void omc_Main_readSettings(void* threadData, void* args);
#if defined(_WIN32)
void omc_Main_setWindowsPaths(threadData_t *threadData, void* _inOMHome);
#endif


}

#endif // OMC_H