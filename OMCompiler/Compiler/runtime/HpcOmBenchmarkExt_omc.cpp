#include "openmodelica.h"
#include "meta/meta_modelica.h"
#define ADD_METARECORD_DEFINITIONS static
#include "OpenModelicaBootstrappingHeader.h"

#if !defined(_MSC_VER)
#include "HpcOmBenchmarkExt.cpp"
#else
#include "errorext.h"
#define HPC_OM_VS() c_add_message(NULL, -1, ErrorType_scripting, ErrorLevel_error, "HpcOmBenchmark not supported on Visual Studio.", NULL, 0);MMC_THROW();
#endif

extern "C" {
extern void* HpcOmBenchmarkExt_requiredTimeForOp()
{
#if defined(_MSC_VER)
  HPC_OM_VS();
#else
  return HpcOmBenchmarkExtImpl__requiredTimeForOp();
#endif
}

extern void* HpcOmBenchmarkExt_requiredTimeForComm()
{
#if defined(_MSC_VER)
  HPC_OM_VS();
#else
  return HpcOmBenchmarkExtImpl__requiredTimeForComm();
#endif
}

extern void* HpcOmBenchmarkExt_readCalcTimesFromXml(const char *filename)
{
#if defined(_MSC_VER)
  HPC_OM_VS();
#else
  return HpcOmBenchmarkExtImpl__readCalcTimesFromXml(filename);
#endif
}

extern void* HpcOmBenchmarkExt_readCalcTimesFromJson(const char *filename)
{
#if defined(_MSC_VER)
  HPC_OM_VS();
#else
  return HpcOmBenchmarkExtImpl__readCalcTimesFromJson(filename);
#endif
}
}
