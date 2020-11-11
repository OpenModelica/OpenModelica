#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Pointer.c"
#endif
#include "omc_simulation_settings.h"
#include "Pointer.h"
#include "util/modelica.h"
#include "Pointer_includes.h"
modelica_metatype omc_Pointer_access(threadData_t *threadData, modelica_metatype _mutable)
{
modelica_metatype _mutable_ext;
modelica_metatype _data_ext;
modelica_metatype _data = NULL;
_mutable_ext = (modelica_metatype)_mutable;
_data_ext = pointerAccess(_mutable_ext);
_data = (modelica_metatype)_data_ext;
return _data;
}
void omc_Pointer_update(threadData_t *threadData, modelica_metatype _mutable, modelica_metatype _data)
{
modelica_metatype _mutable_ext;
modelica_metatype _data_ext;
_mutable_ext = (modelica_metatype)_mutable;
_data_ext = (modelica_metatype)_data;
pointerUpdate(threadData, _mutable_ext, _data_ext);
return;
}
modelica_metatype omc_Pointer_createImmutable(threadData_t *threadData, modelica_metatype _data)
{
modelica_metatype _data_ext;
modelica_metatype _ptr_ext;
modelica_metatype _ptr = NULL;
_data_ext = (modelica_metatype)_data;
_ptr_ext = mmc_mk_some(_data_ext);
_ptr = (modelica_metatype)_ptr_ext;
return _ptr;
}
modelica_metatype omc_Pointer_create(threadData_t *threadData, modelica_metatype _data)
{
modelica_metatype _data_ext;
modelica_metatype _ptr_ext;
modelica_metatype _ptr = NULL;
_data_ext = (modelica_metatype)_data;
_ptr_ext = pointerCreate(_data_ext);
_ptr = (modelica_metatype)_ptr_ext;
return _ptr;
}
