#include "openmodelica.h"
#include "meta_modelica.h"
#include "rml_compatibility.h"
#include "OpenModelicaBootstrappingHeader.h"
#include "HpcOmBenchmarkExt.cpp"

extern "C" {
extern void* HpcOmBenchmarkExt_requiredTimeForOp()
{
  return HpcOmBenchmarkExtImpl__requiredTimeForOp();
}

extern void* HpcOmBenchmarkExt_requiredTimeForComm()
{
  return HpcOmBenchmarkExtImpl__requiredTimeForComm();
}

extern void* HpcOmBenchmarkExt_readCalcTimesFromXml(const char *filename)
{
  return HpcOmBenchmarkExtImpl__readCalcTimesFromXml(filename);
}
}
