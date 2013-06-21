#include "openmodelica.h"
#include "meta_modelica.h"
#include "rml_compatibility.h"
#include "OpenModelicaBootstrappingHeader.h"
#include "HpcOmBenchmarkExt.cpp"

extern "C" {
extern int HpcOmBenchmarkExt_requiredTimeForMult()
{
  return HpcOmBenchmarkExtImpl__requiredTimeForMult();
}

extern int HpcOmBenchmarkExt_requiredTimeForAdd()
{
  return HpcOmBenchmarkExtImpl__requiredTimeForAdd();
}

extern int HpcOmBenchmarkExt_requiredTimeForCom()
{
  return HpcOmBenchmarkExtImpl__requiredTimeForCom();
}

}
