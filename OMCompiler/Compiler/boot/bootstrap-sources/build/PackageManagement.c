#include "omc_simulation_settings.h"
#include "PackageManagement.h"
#include "util/modelica.h"
#include "PackageManagement_includes.h"
DLLDirection
void omc_PackageManagement_installCachedPackages(threadData_t *threadData)
{
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
DLLDirection
modelica_boolean omc_PackageManagement_upgradeInstalledPackages(threadData_t *threadData, modelica_boolean _b)
{
modelica_boolean _res;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = 0;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_PackageManagement_upgradeInstalledPackages(threadData_t *threadData, modelica_metatype _b)
{
modelica_integer tmp1;
modelica_boolean _res;
modelica_metatype out_res;
tmp1 = mmc_unbox_integer(_b);
_res = omc_PackageManagement_upgradeInstalledPackages(threadData, tmp1);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_boolean omc_PackageManagement_updateIndex(threadData_t *threadData)
{
modelica_boolean _res;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = 0;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_PackageManagement_updateIndex(threadData_t *threadData)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_PackageManagement_updateIndex(threadData);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_boolean omc_PackageManagement_installPackage(threadData_t *threadData, modelica_string _str1, modelica_string _str2, modelica_boolean _b)
{
modelica_boolean _res;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = 0;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_PackageManagement_installPackage(threadData_t *threadData, modelica_metatype _str1, modelica_metatype _str2, modelica_metatype _b)
{
modelica_integer tmp1;
modelica_boolean _res;
modelica_metatype out_res;
tmp1 = mmc_unbox_integer(_b);
_res = omc_PackageManagement_installPackage(threadData, _str1, _str2, tmp1);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_metatype omc_PackageManagement_getInstalledLibraries(threadData_t *threadData)
{
modelica_metatype _lst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_return: OMC_LABEL_UNUSED
return _lst;
}
DLLDirection
modelica_metatype omc_PackageManagement_versionsThatProvideTheWanted(threadData_t *threadData, modelica_string _id, modelica_string _version, modelica_boolean _printError)
{
modelica_metatype _result = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_result = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _result;
}
modelica_metatype boxptr_PackageManagement_versionsThatProvideTheWanted(threadData_t *threadData, modelica_metatype _id, modelica_metatype _version, modelica_metatype _printError)
{
modelica_integer tmp1;
modelica_metatype _result = NULL;
tmp1 = mmc_unbox_integer(_printError);
_result = omc_PackageManagement_versionsThatProvideTheWanted(threadData, _id, _version, tmp1);
return _result;
}
DLLDirection
modelica_metatype omc_PackageManagement_AvailableLibraries_listKeys(threadData_t *threadData, modelica_metatype __omcQ_24in_5Flst)
{
modelica_metatype _lst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_lst = __omcQ_24in_5Flst;
_return: OMC_LABEL_UNUSED
return _lst;
}
