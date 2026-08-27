#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Mutable.c"
#endif
#include "omc_simulation_settings.h"
#include "Mutable.h"
#include "util/modelica.h"
#include "Mutable_includes.h"
modelica_metatype omc_Mutable_access(threadData_t *threadData, modelica_metatype _mutable)
{
modelica_metatype _mutable_ext;
modelica_metatype _data_ext;
modelica_metatype _data = NULL;
_mutable_ext = (modelica_metatype)_mutable;
_data_ext = mutableAccess(_mutable_ext);
_data = (modelica_metatype)_data_ext;
return _data;
}
void omc_Mutable_update(threadData_t *threadData, modelica_metatype _mutable, modelica_metatype _data)
{
modelica_metatype _mutable_ext;
modelica_metatype _data_ext;
_mutable_ext = (modelica_metatype)_mutable;
_data_ext = (modelica_metatype)_data;
mutableUpdate(_mutable_ext, _data_ext);
return;
}
modelica_metatype omc_Mutable_create(threadData_t *threadData, modelica_metatype _data)
{
modelica_metatype _data_ext;
modelica_metatype _mutable_ext;
modelica_metatype _mutable = NULL;
_data_ext = (modelica_metatype)_data;
_mutable_ext = mutableCreate(_data_ext);
_mutable = (modelica_metatype)_mutable_ext;
return _mutable;
}
