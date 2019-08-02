#include <julia.h>

jl_function_t* omc_jl_some = NULL;
jl_function_t* omc_jl_cons = NULL;
jl_function_t* omc_jl_sourceinfo = NULL;
jl_function_t* omc_jl_listReverse = NULL;
jl_function_t* omc_jl_tuple2 = NULL;
jl_function_t* omc_jl_AbsynUtil_isDerCref = NULL;

void OpenModelica_initMetaModelicaJuliaLayer()
{
  jl_eval_string("import MetaModelica");
  omc_jl_some = jl_get_function(jl_base_module, "MetaModelica.SOME");
  omc_jl_cons = jl_get_function(jl_base_module, "MetaModelica.Cons");
  omc_jl_cons = jl_get_function(jl_base_module, "MetaModelica.SOURCEINFO");
  omc_jl_listReverse = jl_get_function(jl_base_module, "MetaModelica.listReverse");
  omc_jl_AbsynUtil_isDerCref = jl_get_function(jl_base_module, "AbsynUtil.isDerCref");
  omc_jl_tuple2 = jl_get_function(jl_base_module, "Tuple");
}
