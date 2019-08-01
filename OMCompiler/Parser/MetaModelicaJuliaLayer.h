/* Note: These values may be garbage collected away? Call this before each file is parsed? */
void OpenModelica_initMetaModelicaJuliaLayer();

extern jl_function_t* omc_jl_some;
extern jl_function_t* omc_jl_cons;
extern jl_function_t* omc_jl_sourceinfo;
extern jl_function_t* omc_jl_listReverse;

static inline jl_value_t* mmc_mk_some_or_none(jl_value_t *value) {
  return value ? jl_call1(omc_jl_some, value) : jl_nothing;
}

static inline jl_value_t* or_nil(jl_value_t *value) {
  return value ? value : jl_nothing;
}

static inline jl_value_t* mmc_mk_scon(const char *str) {
  return jl_cstr_to_string(str);
}

static inline jl_value_t* mmc_mk_cons(jl_value_t* head, jl_value_t* tail) {
  return jl_call2(omc_jl_cons, head, tail);
}

static inline jl_value_t* SourceInfo__SOURCEINFO(jl_value_t* fileName, jl_value_t* isReadOnly, jl_value_t* lineNumberStart, jl_value_t* columnNumberStart, jl_value_t* lineNumberEnd, jl_value_t* columnNumberEnd, jl_value_t* lastModification)
{
  jl_value_t *vals[7] = {fileName,isReadOnly,lineNumberStart,columnNumberStart,lineNumberEnd,columnNumberEnd,lastModification};
  return jl_call(omc_jl_sourceinfo, vals, 7);
}

#define MMC_TRUE jl_true
#define MMC_FALSE jl_false
#define mmc_mk_bcon(X) X ? jl_true : jl_false
#define mmc_mk_icon(X) jl_box_int64(X)
#define mmc_mk_rcon(X) jl_box_float64(X)
#define mmc_mk_nil() jl_nothing
#define mmc_mk_none() jl_nothing
#define mmc_mk_some(X) jl_call1(omc_jl_some, X)
#define listReverseInPlace(X) jl_call1(omc_jl_listReverse, X)
#define optionNone(X) jl_is_nothing(X)

#define c_add_source_message(X, NUM, KIND, LEVEL, MSG, ...) assert(0)

