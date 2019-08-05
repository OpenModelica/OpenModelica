#include <stdio.h>
#include <julia.h>
#include "MetaModelicaJuliaLayer.h"

jl_function_t* omc_jl_some = NULL;
jl_function_t* omc_jl_cons = NULL;
jl_function_t* omc_jl_cons_typed = NULL;
jl_function_t* omc_jl_sourceinfo = NULL;
jl_function_t* omc_jl_listEmpty = NULL;
jl_function_t* omc_jl_listReverse = NULL;
jl_function_t* omc_jl_tuple2 = NULL;
jl_function_t* omc_jl_isDerCref = NULL;
jl_value_t* omc_jl_nil = NULL;

void OpenModelica_initMetaModelicaJuliaLayer()
{
  jl_module_t *MetaModelicaModule = (jl_module_t*)jl_eval_string("MetaModelica");
  jl_module_t *ListDefModule = (jl_module_t*)jl_eval_string("MetaModelica.ListDef");
  jl_module_t *parserModule = (jl_module_t*)jl_eval_string("OpenModelicaParser");
  assert(jl_is_module(MetaModelicaModule));
  assert(jl_is_module(parserModule));
  assert((omc_jl_some = jl_get_function(MetaModelicaModule, "SOME")));
  assert((omc_jl_cons = jl_get_function(ListDefModule, "cons")));
  assert((omc_jl_cons_typed = jl_get_function(ListDefModule, "consExternalC")));
  assert((omc_jl_sourceinfo = jl_get_function(MetaModelicaModule, "SOURCEINFO")));
  assert((omc_jl_listReverse = jl_get_function(MetaModelicaModule, "listReverse")));
  assert((omc_jl_listEmpty = jl_get_function(MetaModelicaModule, "listEmpty")));
  assert((omc_jl_isDerCref = jl_get_function(parserModule, "isDerCref")));
  assert((omc_jl_tuple2 = jl_get_function(jl_base_module, "tuple")));
  assert((omc_jl_nil = jl_get_global(ListDefModule, jl_symbol("nil"))));
}

void c_add_source_message(
       void *dummy,
       int errorID,
       ErrorType type,
       ErrorLevel severity,
       const char* message,
       const char** ctokens,
       int nTokens,
       int startLine,
       int startCol,
       int endLine,
       int endCol,
       int isReadOnly,
       jl_value_t* filename)
{
  int i;
  fprintf(stderr, "%s:%d:%d-%d:%d: %s\n", jl_string_data(filename), startLine, startCol, endLine, endCol, message, nTokens);
  for (i=0; i<nTokens; i++) {
    fprintf(stderr, "    Error token %d: %s\n", i+1, ctokens[i]);
  }
}
