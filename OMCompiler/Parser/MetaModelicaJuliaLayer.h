#if !defined(__METAMODELICA_JULIA_LAYER__H)
#define __METAMODELICA_JULIA_LAYER__H

#include <julia.h>

#define jl_debug_println(X) jl_call1(jl_get_function(jl_base_module, "show"), (X));

/* Note: These values may be garbage collected away? Call this before each file is parsed? */
void OpenModelica_initMetaModelicaJuliaLayer();

extern jl_function_t* omc_jl_some;
extern jl_function_t* omc_jl_cons;
extern jl_function_t* omc_jl_cons_typed;
extern jl_function_t* omc_jl_sourceinfo;
extern jl_function_t* omc_jl_listReverse;
extern jl_function_t* omc_jl_listEmpty;
extern jl_function_t* omc_jl_tuple2;
extern jl_function_t* omc_jl_isDerCref;
extern jl_value_t* omc_jl_nil;

static inline jl_value_t* mmc_mk_some_or_none(jl_value_t *value) {
  return value ? jl_call1(omc_jl_some, value) : jl_nothing;
}

static inline jl_value_t* mmc_mk_scon(const char *str) {
  return jl_cstr_to_string(str);
}

static inline jl_value_t* __mmc_mk_cons(jl_value_t* head, jl_value_t* tail) {
  jl_value_t *res = jl_call2(omc_jl_cons, head, tail);
  assert(res);
  return res;
}

static inline jl_value_t* mmc_mk_cons_typed(jl_value_t* T, jl_value_t* head, jl_value_t* tail) {
  jl_value_t *res = jl_call3(omc_jl_cons_typed, T, head, tail);
  assert(res);
  return res;
}

static inline jl_value_t* SourceInfo__SOURCEINFO(jl_value_t* fileName, jl_value_t* isReadOnly, jl_value_t* lineNumberStart, jl_value_t* columnNumberStart, jl_value_t* lineNumberEnd, jl_value_t* columnNumberEnd, jl_value_t* lastModification)
{
  jl_value_t *vals[7] = {fileName,isReadOnly,lineNumberStart,columnNumberStart,lineNumberEnd,columnNumberEnd,lastModification};
  return jl_call(omc_jl_sourceinfo, vals, 7);
}

#define omc_AbsynUtil_isDerCref(IGNORE, X) (X ? jl_call1(omc_jl_isDerCref, X) : jl_nothing)
#define mmc_mk_tuple2(x1,x2) (jl_call2(omc_jl_tuple2, x1, x2))

#define MMC_TRUE jl_true
#define MMC_FALSE jl_false
#define mmc_mk_bcon(X) X ? jl_true : jl_false
#define mmc_mk_icon(X) jl_box_int64(X)
#define mmc_mk_rcon(X) jl_box_float64(X)
#define mmc_mk_nil() omc_jl_nil
#define mmc_mk_none() jl_nothing
#define mmc_mk_some(X) jl_call1(omc_jl_some, X)
#define listReverseInPlace(X) jl_call1(omc_jl_listReverse, X)
#define listEmpty(X) (jl_true == jl_call1(omc_jl_listEmpty, (X)))
#define optionNone(X) jl_is_nothing(X)

enum enumErrorType {ErrorType_syntax=0,ErrorType_grammar,ErrorType_translation,ErrorType_symbolic,ErrorType_runtime,ErrorType_scripting};
enum enumErrorLevel {ErrorLevel_internal=0,ErrorLevel_error,ErrorLevel_warning,ErrorLevel_notification};
typedef enum enumErrorType ErrorType;
typedef enum enumErrorLevel ErrorLevel;

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
       jl_value_t* filename);

/* TODO: These should probably be some calls to Julia iconv functions? Or real iconv, who knows... */
#define SystemImpl__iconv(STR,FROM,TO,ERR) STR
#define SystemImpl__iconv__ascii(STR) STR

static inline jl_value_t* or_nil(jl_value_t *value) {
  return value ? value : mmc_mk_nil();
}

#endif
