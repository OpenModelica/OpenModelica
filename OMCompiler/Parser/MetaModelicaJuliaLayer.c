#include <julia.h>

jl_function_t* omc_jl_some = NULL;
jl_function_t* omc_jl_cons = NULL;
jl_function_t* omc_jl_sourceinfo = NULL;
jl_function_t* omc_jl_listReverse = NULL;

void OpenModelica_initMetaModelicaJuliaLayer()
{
  jl_eval_string("import MetaModelica");
  omc_jl_some = jl_get_function(jl_base_module, "MetaModelica.SOME");
  omc_jl_cons = jl_get_function(jl_base_module, "MetaModelica.Cons");
  omc_jl_cons = jl_get_function(jl_base_module, "MetaModelica.SOURCEINFO");
  omc_jl_listReverse = jl_get_function(jl_base_module, "MetaModelica.listReverse");
}
