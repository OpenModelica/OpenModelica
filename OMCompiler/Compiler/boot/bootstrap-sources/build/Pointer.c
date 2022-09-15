#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "Pointer.c"
#endif
#include "omc_simulation_settings.h"
#include "Pointer.h"
#include "util/modelica.h"
#include "Pointer_includes.h"
DLLExport
modelica_metatype omc_Pointer_applyMapFold(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmutable, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _mutable = NULL;
modelica_metatype _arg = NULL;
modelica_metatype _new = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_mutable = __omcQ_24in_5Fmutable;
_arg = __omcQ_24in_5Farg;
_new = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), omc_Pointer_access(threadData, _mutable), _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, omc_Pointer_access(threadData, _mutable), _arg ,&_arg);
if((!referenceEq(_new, omc_Pointer_access(threadData, _mutable))))
{
omc_Pointer_update(threadData, _mutable, _new);
}
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _mutable;
}
DLLExport
modelica_metatype omc_Pointer_applyFold(threadData_t *threadData, modelica_metatype _mutable, modelica_fnptr _func)
{
modelica_metatype _arg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), omc_Pointer_access(threadData, _mutable)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, omc_Pointer_access(threadData, _mutable));
_return: OMC_LABEL_UNUSED
return _arg;
}
DLLExport
modelica_metatype omc_Pointer_apply(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmutable, modelica_fnptr _func)
{
modelica_metatype _mutable = NULL;
modelica_metatype _new = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_mutable = __omcQ_24in_5Fmutable;
_new = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), omc_Pointer_access(threadData, _mutable)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, omc_Pointer_access(threadData, _mutable));
if((!referenceEq(_new, omc_Pointer_access(threadData, _mutable))))
{
omc_Pointer_update(threadData, _mutable, _new);
}
_return: OMC_LABEL_UNUSED
return _mutable;
}
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
