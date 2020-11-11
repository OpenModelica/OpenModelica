#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/PackageManagement.c"
#endif
#include "omc_simulation_settings.h"
#include "PackageManagement.h"
#include "util/modelica.h"
#include "PackageManagement_includes.h"
DLLExport
modelica_boolean omc_PackageManagement_upgradeInstalledPackages(threadData_t *threadData, modelica_boolean _b)
{
modelica_boolean _res;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = 0;
_return: OMC_LABEL_UNUSED
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
DLLExport
modelica_boolean omc_PackageManagement_updateIndex(threadData_t *threadData)
{
modelica_boolean _res;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = 0;
_return: OMC_LABEL_UNUSED
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
DLLExport
modelica_boolean omc_PackageManagement_installPackage(threadData_t *threadData, modelica_string _str1, modelica_string _str2, modelica_boolean _b)
{
modelica_boolean _res;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = 0;
_return: OMC_LABEL_UNUSED
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
DLLExport
modelica_metatype omc_PackageManagement_getInstalledLibraries(threadData_t *threadData)
{
modelica_metatype _lst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_return: OMC_LABEL_UNUSED
return _lst;
}
DLLExport
modelica_metatype omc_PackageManagement_versionsThatProvideTheWanted(threadData_t *threadData, modelica_string _id, modelica_string _version, modelica_boolean _printError)
{
modelica_metatype _result = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_result = tmpMeta[0];
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
DLLExport
modelica_metatype omc_PackageManagement_AvailableLibraries_listKeys(threadData_t *threadData, modelica_metatype __omcQ_24in_5Flst)
{
modelica_metatype _lst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_lst = __omcQ_24in_5Flst;
_return: OMC_LABEL_UNUSED
return _lst;
}
