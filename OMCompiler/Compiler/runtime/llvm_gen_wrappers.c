#include "llvm_gen_wrappers.h"
#ifdef __cplusplus
gextern "C" {
#endif

/**/
modelica_metatype VALUES_FAIL() {
  return Values__META_5fFAIL;
}

/* This functions run the JIT within the C environment of omc */
 modelica_metatype run_jit_internal(modelica_metatype (*top_level_func)(modelica_metatype), modelica_metatype args) {
  modelica_metatype res;
  MMC_TRY()
  res = top_level_func(args);
  return res;
  MMC_CATCH()
  return VALUES_FAIL();
}

/* Calls MMC_THROW_INTERNAL, macro cannot be used in the JIT context */
void mmc_throw_internal()
{
  threadData_t *threadData = (threadData_t *) pthread_getspecific(mmc_thread_data_key);
  MMC_THROW();
}

/* Calls MMC_THROW, macro cannot be used in the JIT context */
void mmc_throw()
{
  threadData_t *threadData = (threadData_t *) pthread_getspecific(mmc_thread_data_key);
  MMC_THROW();
}

double mmc_unbox_real_no_inline(modelica_metatype v)
{
  return mmc_prim_get_real(v);
}

modelica_integer mmc_unbox_integer_no_inline(modelica_metatype v)
{
  return MMC_UNTAGFIXNUM(v);
}

modelica_metatype mmc_icon_to_value_wrapper(modelica_metatype mmc)
{
    if (MMC_IS_INTEGER(mmc)) {
      return Values__INTEGER(mmc_mk_icon(MMC_UNTAGFIXNUM(mmc)));
    }
    return NULL;
}

modelica_metatype mmc_rcon_to_value_wrapper(modelica_metatype mmc)
{
  mmc_uint_t hdr = MMC_GETHDR(mmc);

  if (hdr == MMC_REALHDR) {
	return Values__REAL(mmc_mk_rcon(mmc_unbox_real(mmc)));
  }
  return NULL;
}


modelica_metatype mmc_mk_scon_to_value_wrapper(modelica_metatype mmc)
{
  modelica_metatype v;
  mmc_uint_t hdr = MMC_GETHDR(mmc);

  if (MMC_HDRISSTRING(hdr)) {
    MMC_CHECK_STRING(mmc);
    v = Values__STRING(mmc_mk_scon(MMC_STRINGDATA(mmc)));
	return v;
  }
  return NULL;
}

modelica_metatype mmc_bcon_to_value_wrapper(modelica_metatype mmc)
{
  //Seems like MMC_IS_INTEGER check for booleans aswell..
  if (MMC_IS_INTEGER(mmc)) {
	modelica_metatype v = Values__BOOL(mmc_mk_icon(MMC_UNTAGFIXNUM(mmc)));
	return v;
  }
  return NULL;
}

modelica_metatype mmc_scon_to_value_wrapper(modelica_metatype mmc)
{
  mmc_uint_t hdr = MMC_GETHDR(mmc);

  if (MMC_HDRISSTRING(hdr)) {
	MMC_CHECK_STRING(mmc);
	return Values__STRING(mmc_mk_scon(MMC_STRINGDATA(mmc)));
  }

  return NULL;
}
/*Special function, creates the last element i a list.*/
modelica_metatype mmc_mk_cons_last_elem(modelica_metatype car)
{
  modelica_metatype v = (void*)mmc_mk_cons(car,mmc_mk_nil());
  return v;
}

modelica_metatype mmc_mk_cons_wrapper(modelica_metatype car,modelica_metatype cdr)
{
  modelica_metatype v = (void**)mmc_mk_cons(car,cdr);
  return v;
}

modelica_metatype mmc_lcon_to_value_wrapper(modelica_metatype lst)
{
  modelica_metatype res;
  res = mmc_to_value(lst);
  return res;
}

//For regular arrays.
modelica_metatype mmc_arrcon_to_value_wrapper(modelica_metatype arr, const int type)
{
  base_array_t *bArr = (base_array_t*)arr;
  switch (type) {
  case MODELICA_REAL: {
	modelica_metatype data = (modelica_real*) bArr->data + base_array_nr_of_elements(*bArr) - 1;
	return generate_array(TYPE_DESC_REAL,1,bArr->ndims,bArr->dim_size,&data);
  }
  default:
	return NULL;
  }
}

  //  generate_array(enum type_desc_e type, int curdim, int ndims,_index_t *dim_size, void **data)
  //EX call: generate_array(TYPE_DESC_REAL, 1, desc->data.real_array.ndims, desc->data.real_array.dim_size, &ptr);
//The varlst will be constructed in memory before it is passed to this function.
modelica_metatype mmc_mtcon_to_value(modelica_metatype varlst)
{
  modelica_metatype tpl = (void*) Values__META_5fTUPLE(varlst);
  return tpl;
}

modelica_metatype mmc_tcon_to_value(modelica_metatype vl)
{
  modelica_metatype tp = mmc_to_value(vl);
  return tp;
}

modelica_metatype mmc_utcon_to_value(modelica_metatype vl)
{
  modelica_metatype tp = mmc_to_value(vl);
  return tp;
}

/* Wrapper functions */
modelica_metatype mmc_mk_icon_wrapper(const modelica_integer i)
{
  void* v = mmc_mk_icon(i);
  return v;
}

modelica_metatype mmc_mk_bcon_wrapper(const modelica_boolean b)
{
  return mmc_mk_bcon(b);
}

modelica_metatype mmc_mk_scon_wrapper(const char *s)
{
  return mmc_mk_scon(s);
}


modelica_metatype mmc_mk_box_jit(mmc_sint_t _slots, mmc_uint_t ctor, ...)
{
  mmc_sint_t i;
  va_list argp;
  struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(_slots+1);
  p->header = MMC_STRUCTHDR(_slots, ctor);
  va_start(argp, ctor);
  for (i = 0; i < _slots; i++) {
    p->data[i] = va_arg(argp, void*);
  }
  va_end(argp);
#ifdef MMC_MK_DEBUG
  fprintf(stderr, "BOXNN slots:%ld ctor: %lu\n", _slots, ctor); fflush(NULL);
#endif
  return MMC_TAGPTR(p);
}

/* From DynLoad.cpp, TODO Booleans? */
static modelica_metatype mmc_to_value(void* mmc)
{
  mmc_uint_t hdr;
  int numslots;
  unsigned ctor;
  int i;
  void* t;

  //TODO: make some kind of hack to detect booleans.
  if (MMC_IS_INTEGER(mmc)) {
     return Values__INTEGER(mmc_mk_icon(MMC_UNTAGFIXNUM(mmc)));
  }
  hdr = MMC_GETHDR(mmc);
  if (hdr == MMC_REALHDR) {
    return Values__REAL(mmc_mk_rcon(mmc_unbox_real(mmc)));
  }
  if (MMC_HDRISSTRING(hdr)) {
    MMC_CHECK_STRING(mmc);
    // We need to duplicate the string because literals may not be accessible anymore... Bleh
    return Values__STRING(mmc_mk_scon(MMC_STRINGDATA(mmc)));
  }
  if (hdr == MMC_NILHDR) {
    return Values__LIST(mmc_mk_nil());
  }

  numslots = MMC_HDRSLOTS(hdr);
  ctor = 255 & (hdr >> 2);

  if (numslots>0 && ctor == MMC_ARRAY_TAG) {
    modelica_metatype varlst = (modelica_metatype ) mmc_mk_nil();
    for (i=numslots; i>0; i--) {
      t = mmc_to_value(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),i)));
      varlst = mmc_mk_cons(t, varlst);
    }
    return (modelica_metatype ) Values__META_5fARRAY(varlst);
  }

  if (numslots>0 && ctor > 1) { /* RECORD */
    modelica_metatype namelst = (modelica_metatype ) mmc_mk_nil();
    modelica_metatype varlst = (modelica_metatype ) mmc_mk_nil();
    struct record_description* desc = (struct record_description*) MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),1));

    assert(desc != NULL);

	for (i=numslots; i>1; i--) {
      t = mmc_to_value(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),i)));
      varlst = mmc_mk_cons(t, varlst);
      t = (void*) desc->fieldNames[i-2];
      namelst = mmc_mk_cons(mmc_mk_scon(t != NULL ? (const char*) t : "(null)"), namelst);
    }

    return (modelica_metatype ) Values__RECORD(name_to_path(desc->path),
                                   varlst, namelst, mmc_mk_icon(((mmc_sint_t)ctor)-3));
  }

  if (numslots>0 && ctor == 0) { /* TUPLE */
    modelica_metatype varlst = (modelica_metatype ) mmc_mk_nil();
    for (i=numslots; i>0; i--) {
      t = mmc_to_value(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),i)));
      varlst = mmc_mk_cons(t, varlst);
    }
    return (modelica_metatype ) Values__META_5fTUPLE(varlst);
  }

  if (numslots==0 && ctor==1) /* NONE() */ {
    return Values__OPTION(mmc_mk_none());
  }

  if (numslots==1 && ctor==1) /* SOME(x) */ {
    t = mmc_to_value(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),1)));
	return Values__OPTION(mmc_mk_some(t));
  }

  if (numslots==2 && ctor==1) { /* CONS-PAIR */
    /* Transform list by first reversing it to preserve the order */
    modelica_metatype varlst;
    mmc = listReverse(mmc);
    varlst = (modelica_metatype ) mmc_mk_nil();
    while (!MMC_NILTEST(mmc)) {
      t = mmc_to_value(MMC_CAR(mmc));
      varlst = mmc_mk_cons(t, varlst);
      mmc = MMC_CDR(mmc);
    }
    return (modelica_metatype ) Values__LIST(varlst);
  }

  fprintf(stderr, "mmc_to_value: %d slots; ctor %d - FAILED to detect the type\n", numslots, ctor);
  return NULL;
}

//Function copied from Dynload.cpp (strul vid inkludering...)
static modelica_metatype name_to_path(const char *name)
{
  const char *last = name, *pos = NULL;
  char *tmp;
  modelica_metatype ident = NULL;
  int need_replace = 0;
  while ((pos = strchr(last, '_')) != NULL) {
    if (pos[1] == '_') {
      last = pos + 2;
      need_replace = 1;
      continue;
    } else
      break;
  }
  if (pos == NULL) {
    if (need_replace) {
      tmp = _replace(name, "__", "_");
      ident = mmc_mk_scon(tmp);
      GC_free(tmp);
    } else {
      /* memcpy(&tmp, &name, sizeof(char *)); */ /* don't try this at home */
      ident = mmc_mk_scon((char*)name);
    }
    return Absyn__IDENT(ident);
  } else {
    size_t len = pos - name;
    tmp = (char*)GC_malloc_atomic(len + 1);
    memcpy(tmp, name, len);
    tmp[len] = '\0';
    if (need_replace) {
      char *tmp2 = _replace(tmp, "__", "_");
      ident = mmc_mk_scon(tmp2);
      GC_free(tmp2);
    } else {
      ident = mmc_mk_scon(tmp);
    }
    GC_free(tmp);
    return Absyn__QUALIFIED(ident, name_to_path(pos + 1));
  }
}

void print_jit (void* s) {
  print(s);
}

modelica_metatype listHead_jit (modelica_metatype X)
{
  //TODO ask Martin how to fetch threadData from this context (I think this is correct?)
  return boxptr_listHead((threadData_t *)pthread_getspecific(mmc_thread_data_key),X);
}

modelica_metatype listRest_jit (modelica_metatype X)
{
  return boxptr_listRest((threadData_t *)pthread_getspecific(mmc_thread_data_key),X);
}

int listEmpty_jit (modelica_metatype X) {
  return MMC_NILTEST(X);
}

modelica_metatype listDelete_jit (modelica_metatype X,const modelica_integer Y)
{
  return boxptr_listDelete((threadData_t *)pthread_getspecific(mmc_thread_data_key),
						   X,mmc_mk_icon(Y));
}

modelica_boolean isCons_jit(modelica_metatype obj)
{
  return (MMC_GETHDR(obj) == MMC_CONSHDR);
}

modelica_boolean isSome_jit(modelica_metatype obj)
{
  modelica_boolean retVal = (0 ==  MMC_HDRSLOTS(MMC_GETHDR(obj)));
  return retVal;
}
modelica_integer get_uniontypevariant(modelica_metatype obj)
{
  mmc_sint_t hdr = MMC_GETHDR(obj);
  hdr = MMC_HDRCTOR(hdr) - 3;
  return hdr;
}

modelica_metatype get_metafield(modelica_metatype obj, modelica_integer index)
{
  //DBG("INDEX: %d\n",index);
  modelica_metatype tmp = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(obj),index));
  return tmp;
}

modelica_integer in_range_integer_jit (modelica_integer i,modelica_integer start,modelica_integer stop)
{
  return in_range_integer(i,start,stop);
}

modelica_integer in_range_boolean_jit(modelica_integer b, modelica_integer start,modelica_integer stop)
{
  return in_range_boolean(b,start,stop);
}

modelica_real in_range_real_jit (modelica_real r, modelica_real start,modelica_real stop)
{
  return in_range_real(r,start,stop);
}

modelica_boolean stringCompare_jit(modelica_string x, modelica_string y)
{
  return stringCompare(x,y);
}

modelica_boolean stringEqual_jit(modelica_string x, modelica_string y)
{
  return stringEqual(x,y);
}

//Returns the ammounts of elements in a standard modelica array.
modelica_integer modelicaArrayLength(modelica_metatype arr)
{
  const base_array_t *tmp = (base_array_t*) arr;
  DBG("SO MANY ELEMENTS%zu \n", base_array_nr_of_elements(*tmp));
  return base_array_nr_of_elements(*tmp);
}

/*Related to Setjmp/longjmp */
jmp_buf *get_mmc_jumper()
{
  DBG("FETCHING MMC_JUMPER\n");
  threadData_t *threadData =
	(threadData_t *)pthread_getspecific(mmc_thread_data_key);
  jmp_buf *tmp = threadData->mmc_jumper;
  DBG("Adress of threadData->mmc_jumper:%p in get_mmc_jumper\n",tmp);
  return tmp;
}

jmp_buf *alloc_get_jmp_buf()
{
  DBG("Allocating JMP_BUF\n");
  jmp_buf *jb = GC_MALLOC(sizeof(jmp_buf));
  DBG("Returning jmp_buf:%p\n",jb);
  return jb;
}

void set_mmc_jumper(jmp_buf *jmpBuf)
{
  DBG("Calling set mmc_jumper\n");
  DBG("Adress of jmpBufPtrPtre:%p\n",jmpBuf);
  threadData_t *threadData = pthread_getspecific(mmc_thread_data_key);
  threadData->mmc_jumper = jmpBuf;
}
#include <setjmp.h>
/* Same as longjump but passes the jmp_buf as a pointer */
void longjump_jumpbufAsPtr(jmp_buf *envP, int val)
{
  longjmp(*envP, val);
}

modelica_metatype value_to_mmc(modelica_metatype value)
{
  switch (MMC_HDRCTOR(MMC_GETHDR(value))) {
  case Values__INTEGER_3dBOX1:
  case Values__BOOL_3dBOX1: {
    return mmc_mk_icon(MMC_UNTAGFIXNUM(MMC_STRUCTDATA(value)[UNBOX_OFFSET+0]));
  };
  case Values__STRING_3dBOX1: {
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
    return mmc_mk_scon(MMC_STRINGDATA(data));
  };
  case Values__REAL_3dBOX1: {
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
    return mmc_mk_rcon(mmc_prim_get_real(data));
  }
  case Values__ARRAY_3dBOX2:
    printf("[dynload]: Parsing of array inside uniontype failed\n");
    return 0;
  case Values__RECORD_3dBOX4: {
    modelica_metatype path = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+1];
    modelica_metatype names = MMC_STRUCTDATA(value)[UNBOX_OFFSET+2];
    modelica_metatype index = MMC_STRUCTDATA(value)[UNBOX_OFFSET+3];
    int index_int = ((mmc_sint_t)index >> 1);
    int i=0;
    modelica_metatype tmp = names;
    modelica_metatype *data_mmc;
    struct record_description* desc = (struct record_description*) malloc(sizeof(struct record_description));
    if (desc == NULL) {
      fprintf(stderr, "[dynload]: value_to_mmc: malloc failed\n");
      return 0;
    }
    while (MMC_GETHDR(tmp) != MMC_NILHDR) {
      i++; tmp = MMC_CDR(tmp);
    }
    /* duplicate string? will this give problems with GC? */
    desc->path = path_to_name(path, '_');
    desc->name = path_to_name(path, '.');
    desc->fieldNames = (const char**) malloc(i*sizeof(char*));
    data_mmc = (void**) malloc((i+1)*sizeof(void*));
    i=0;
    data_mmc[0] = desc;
    while (MMC_GETHDR(names) != MMC_NILHDR) {
      desc->fieldNames[i] = MMC_STRINGDATA(MMC_CAR(names));
      names = MMC_CDR(names);
      data_mmc[i+1] = value_to_mmc(MMC_CAR(data));
      i++;
      data = MMC_CDR(data);
    }
    return mmc_mk_box_arr(i+1, index_int+3, (void**) data_mmc);
  }; break;
  case Values__OPTION_3dBOX1: {
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
    int numslots = MMC_HDRSLOTS(MMC_GETHDR(data));
    if (numslots == 0) return mmc_mk_none();
    return mmc_mk_some(value_to_mmc(MMC_STRUCTDATA(data)[0]));
  }; break;
  case Values__LIST_3dBOX1: {
    void* data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
    void* tmp = mmc_mk_nil();
    while (MMC_GETHDR(data) != MMC_NILHDR) {
      tmp = mmc_mk_cons(value_to_mmc(MMC_CAR(data)), tmp);
      data = MMC_CDR(data);
    }
    /* Transform list by first reversing it to preserve the order */
    return listReverse(tmp);
  };
  case Values__META_5fARRAY_3dBOX1: {
    void* data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
    void* tmp = mmc_mk_nil();
    while (MMC_GETHDR(data) != MMC_NILHDR) {
      tmp = mmc_mk_cons(value_to_mmc(MMC_CAR(data)), tmp);
      data = MMC_CDR(data);
    }
    return listArray(listReverse(tmp));
  };
  case Values__META_5fTUPLE_3dBOX1: {
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
    int len=0;
    modelica_metatype tmp = data;
    modelica_metatype *data_mmc;
    modelica_metatype res;

    while (MMC_GETHDR(tmp) != MMC_NILHDR) {
      len++; tmp = MMC_CDR(tmp);
    }
    res = mmc_mk_box_no_assign(len, 0, 0);
    len = 0;
    tmp = data;
    while (MMC_GETHDR(tmp) != MMC_NILHDR) {
      threadData_t *threadData = NULL;
      arrayUpdate(res, ++len, value_to_mmc(MMC_CAR(tmp)));
      tmp = MMC_CDR(tmp);
    }
    return res;
  };
  case Values__ENUM_5fLITERAL_3dBOX2:
  case Values__CODE_3dBOX1:
    /* unsupported */
    fprintf(stderr, "%s:%d: enum,code unsupported in MetaModelica data\n", __FILE__, __LINE__);
    return 0;
  default:
    /* unsupported */
    fprintf(stderr, "%s:%d: Error, unknown type", __FILE__, __LINE__);
    printAny(value);
    fprintf(stderr, "\n");
    return 0;
  }
}


static char* path_to_name(void* path, char del)
{
  threadData_t *threadData = (threadData_t *) pthread_getspecific(mmc_thread_data_key);
  char delStr[2] = {del,'\0'};
  return MMC_STRINGDATA(omc_AbsynUtil_pathString(threadData, path, mmc_mk_scon(delStr), 0, 0));
}

static int parse_array(type_description *desc, modelica_metatype arrdata, modelica_metatype dimLst)
{
  _index_t dims, *dim_size;
  modelica_metatype data;
  assert(desc->type == TYPE_DESC_NONE);
  dims = get_array_type_and_dims(desc, arrdata);
  if (dims < 1) {
    printf("dims: %d\n", (int) dims);
    return -1;
  }
  dim_size = (_index_t*) malloc(sizeof(_index_t) * dims);
  switch (desc->type) {
  case TYPE_DESC_REAL_ARRAY:
    desc->data.real_array.ndims = dims;
    desc->data.real_array.dim_size = dim_size;
    break;
  case TYPE_DESC_INT_ARRAY:
    desc->data.int_array.ndims = dims;
    desc->data.int_array.dim_size = dim_size;
    break;
  case TYPE_DESC_BOOL_ARRAY:
    desc->data.bool_array.ndims = dims;
    desc->data.bool_array.dim_size = dim_size;
    break;
  case TYPE_DESC_STRING_ARRAY:
    desc->data.string_array.ndims = dims;
    desc->data.string_array.dim_size = dim_size;
    break;
  default:
    assert(0);
    return -1;
  }
  if (get_array_sizes(dims, dim_size, dimLst))
    return -1;
  switch (desc->type) {
  case TYPE_DESC_REAL_ARRAY:
    alloc_real_array_data(&(desc->data.real_array));
    data = desc->data.real_array.data;
    return get_array_data(1, dims, dim_size, arrdata, TYPE_DESC_REAL, &data);
  case TYPE_DESC_INT_ARRAY:
    alloc_integer_array_data(&(desc->data.int_array));
    data = desc->data.int_array.data;
    return get_array_data(1, dims, dim_size, arrdata, TYPE_DESC_INT, &data);
  case TYPE_DESC_BOOL_ARRAY:
    alloc_boolean_array_data(&(desc->data.bool_array));
    data = desc->data.bool_array.data;
    return get_array_data(1, dims, dim_size, arrdata, TYPE_DESC_BOOL, &data);
  case TYPE_DESC_STRING_ARRAY:
    alloc_string_array_data(&(desc->data.string_array));
    data = desc->data.string_array.data;
    return get_array_data(1, dims, dim_size, arrdata, TYPE_DESC_STRING, &data);
  default:
    break;
  }

  assert(0);
  return -1;
}

static modelica_metatype generate_array(enum type_desc_e type, int curdim, int ndims,
                     _index_t *dim_size, modelica_metatype *data)
{
  modelica_metatype lst = (modelica_metatype ) mmc_mk_nil();
  modelica_metatype dimLst = (void*) mmc_mk_nil();
  int i, cur_dim_size = dim_size[curdim - 1];
  if (curdim == ndims) {
    type_description tmp;
    tmp.type = type;
    switch (type) {
    case TYPE_DESC_REAL: {
      modelica_real *ptr = *((modelica_real**)data);
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.real = *ptr;
        lst = (modelica_metatype ) mmc_mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    case TYPE_DESC_INT: {
      modelica_integer *ptr = *((modelica_integer**)data);
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.integer = *ptr;
        lst = (modelica_metatype ) mmc_mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    case TYPE_DESC_BOOL: {
      modelica_boolean *ptr = *((modelica_boolean**)data);
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.boolean = *ptr;
        lst = (modelica_metatype ) mmc_mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    case TYPE_DESC_STRING: {
      modelica_string *ptr = *((modelica_string**)data);
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.string = *ptr;
        lst = (modelica_metatype ) mmc_mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    default:
      assert(0);
      return NULL;
    }
  } else {
    for (i = 0; i < cur_dim_size; ++i) {
      lst = (modelica_metatype ) mmc_mk_cons(generate_array(type, curdim + 1, ndims, dim_size,
                                            data), lst);
    }
  }
  for (i = ndims; i >= curdim; i--) {
    dimLst = (modelica_metatype ) mmc_mk_cons(mmc_mk_icon(dim_size[i-1]), dimLst);
  }

  return Values__ARRAY(lst, dimLst);
}

modelica_metatype type_desc_to_value(type_description *desc)
{
  switch (desc->type) {
  case TYPE_DESC_NONE:
    return NULL;
  case TYPE_DESC_NORETCALL:
    return (modelica_metatype ) Values__NORETCALL;
  case TYPE_DESC_REAL:
    return (modelica_metatype ) Values__REAL(mmc_mk_rcon(desc->data.real));
  case TYPE_DESC_INT:
    return (modelica_metatype ) Values__INTEGER(mmc_mk_icon(desc->data.integer));
  case TYPE_DESC_BOOL:
    if(getMyBool(desc))
      return (modelica_metatype ) Values__BOOL(MMC_TRUE);
    return (modelica_metatype ) Values__BOOL(MMC_FALSE);
  case TYPE_DESC_STRING:
    /* Duplicate since we unload the object */
    return (modelica_metatype ) Values__STRING(mmc_mk_scon(MMC_STRINGDATA(desc->data.string)));
  case TYPE_DESC_TUPLE: {
    type_description *e = desc->data.tuple.element + desc->data.tuple.elements;
    modelica_metatype lst = (modelica_metatype ) mmc_mk_nil();
    while (e > desc->data.tuple.element) {
      modelica_metatype t = type_desc_to_value(--e);
      if (t == NULL)
        return NULL;
      lst = mmc_mk_cons(t, lst);
    }
    return (modelica_metatype ) Values__TUPLE(lst);
  };
  case TYPE_DESC_RECORD: {
    char **name = desc->data.record.name + desc->data.record.elements;
    type_description *e = desc->data.record.element + desc->data.record.elements;
    modelica_metatype namelst = (modelica_metatype ) mmc_mk_nil();
    modelica_metatype varlst = (modelica_metatype ) mmc_mk_nil();
    while (e > desc->data.record.element) {
      modelica_metatype n, *t;
      --name;
      --e;
      n = mmc_mk_scon(*name);
      t = type_desc_to_value(e);
      if (n == NULL || t == NULL)
        return NULL;
      namelst = mmc_mk_cons(n, namelst);
      varlst = mmc_mk_cons(t, varlst);
    }
    return (modelica_metatype ) Values__RECORD(name_to_path(desc->data.record.record_name),
                                   varlst, namelst, mmc_mk_icon(-1));
  };
  case TYPE_DESC_REAL_ARRAY: {
    modelica_metatype ptr = (modelica_real *) desc->data.real_array.data
      + base_array_nr_of_elements(desc->data.real_array) - 1;
    return generate_array(TYPE_DESC_REAL, 1, desc->data.real_array.ndims,
                          desc->data.real_array.dim_size, &ptr);
  };
  case TYPE_DESC_INT_ARRAY: {
    modelica_metatype ptr = (modelica_integer *) desc->data.int_array.data
      + base_array_nr_of_elements(desc->data.int_array) - 1;
    return generate_array(TYPE_DESC_INT, 1, desc->data.int_array.ndims,
                          desc->data.int_array.dim_size, &ptr);
  };
  case TYPE_DESC_BOOL_ARRAY: {
    modelica_metatype ptr = (modelica_boolean *) desc->data.bool_array.data
      + base_array_nr_of_elements(desc->data.bool_array) - 1;
    return generate_array(TYPE_DESC_BOOL, 1, desc->data.bool_array.ndims,
                          desc->data.bool_array.dim_size, &ptr);
  };
  case TYPE_DESC_STRING_ARRAY: {
    modelica_metatype ptr = (modelica_string *) desc->data.string_array.data
      + base_array_nr_of_elements(desc->data.string_array) - 1;
    return generate_array(TYPE_DESC_STRING, 1, desc->data.string_array.ndims,
                          desc->data.string_array.dim_size, &ptr);
  };
  case TYPE_DESC_MMC: {
    void* t = 0;//TODO!:
	//    assert(0 == mmc_to_value(desc->data.mmc, &t));
    return t;
  };
  case TYPE_DESC_COMPLEX: {
    return NULL;
  };
  default: break;
  }

  assert(0);
  return NULL;
}

modelica_metatype valueLst_to_type_descs(modelica_metatype value)
{
  const int MMC_NUM_ARGS = 32;
  type_description *descs = GC_malloc(sizeof(type_description)*(MMC_NUM_ARGS+1));
  type_description *arg = descs;
  while (!listEmpty(value)) {
    modelica_metatype val = MMC_CAR(value);
    if (value_to_type_desc(val,arg)) {
	  return NULL;
    }
    ++arg;
    value = MMC_CDR(value);
  }
  /* For Compatability with the existing read and write functions. */
  init_type_description(arg);
  return descs;
}

static int value_to_type_desc(modelica_metatype value, type_description *desc)
{
  init_type_description(desc);
  switch (MMC_HDRCTOR(MMC_GETHDR(value))) {
  case Values__INTEGER_3dBOX1: {

    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    desc->type = TYPE_DESC_INT;
    desc->data.integer = MMC_UNTAGFIXNUM(data);
  }; break;
  case Values__ENUM_5fLITERAL_3dBOX2: {
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+1];
    desc->type = TYPE_DESC_INT;
    desc->data.integer = MMC_UNTAGFIXNUM(data);
  }; break;
  case Values__REAL_3dBOX1: {
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    desc->type = TYPE_DESC_REAL;
    desc->data.real = mmc_prim_get_real(data);
  }; break;
  case Values__BOOL_3dBOX1: {
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    desc->type = TYPE_DESC_BOOL;
    desc->data.boolean = (data == MMC_TRUE);
  }; break;
  case Values__STRING_3dBOX1: {
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    desc->type = TYPE_DESC_STRING;
    desc->data.string = data;
  }; break;
  case Values__ARRAY_3dBOX2: {
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    modelica_metatype dimLst = MMC_STRUCTDATA(value)[UNBOX_OFFSET+1];
    if (parse_array(desc, data, dimLst)) {
      printf("Parsing of array failed\n");
      return -1;
    }
  }; break;
  case Values__RECORD_3dBOX4: {
    modelica_metatype path = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+1];
    modelica_metatype names = MMC_STRUCTDATA(value)[UNBOX_OFFSET+2];
    modelica_metatype index = MMC_STRUCTDATA(value)[UNBOX_OFFSET+3];
    if (-1 != ((mmc_sint_t)index >> 1)) {
      desc->type = TYPE_DESC_MMC;
      desc->data.mmc = value_to_mmc(value);
      break;
    }
    desc->type = TYPE_DESC_RECORD;
    //fprintf(stderr, "makepath: %s\n", path_to_name(path));
    desc->data.record.record_name = path_to_name(path, '.');
    while ((MMC_GETHDR(names) != MMC_NILHDR) &&
           (MMC_GETHDR(data) != MMC_NILHDR)) {
      type_description *elem;
      modelica_metatype nptr;

      nptr = MMC_CAR(names);
      elem = add_modelica_record_member(desc, MMC_STRINGDATA(nptr),
                                        MMC_HDRSTRLEN(MMC_GETHDR(nptr)));

      if (value_to_type_desc(MMC_CAR(data), elem)) {
        return -1;
      }
      data = MMC_CDR(data);
      names = MMC_CDR(names);
    }
  }; break;

  case Values__TUPLE_3dBOX1: {
    modelica_metatype data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    desc->type = TYPE_DESC_TUPLE;
    while (MMC_GETHDR(data) != MMC_NILHDR) {
      type_description *elem;

      elem = add_tuple_member(desc);

      if (value_to_type_desc(MMC_CAR(data), elem)) {
        return -1;
      }
      data = MMC_CDR(data);
    }
  }; break;
  case Values__META_5fTUPLE_3dBOX1:
  case Values__LIST_3dBOX1:
  case Values__OPTION_3dBOX1:
    desc->type = TYPE_DESC_MMC;
    desc->data.mmc = value_to_mmc(value);
    if (desc->data.mmc == 0) {
      c_add_message(NULL,-1, ErrorType_runtime, ErrorLevel_error, "systemimpl.c:value_to_type_desc failed\n", NULL, 0);
      return -1;
    }
    break;
    /* unsupported */
  case Values__META_5fARRAY_3dBOX1:
    c_add_message(NULL,-1, ErrorType_runtime, ErrorLevel_error, "systemimpl.c:value_to_type_desc failed: Values.META_ARRAY\n", NULL, 0);
    return -1;
  case Values__CODE_3dBOX1:
    c_add_message(NULL,-1, ErrorType_runtime, ErrorLevel_error, "systemimpl.c:value_to_type_desc failed: Values.CODE\n", NULL, 0);
    return -1;
  default:
    c_add_message(NULL,-1, ErrorType_runtime, ErrorLevel_error, "systemimpl.c:value_to_type_desc failed\n", NULL, 0);
    return -1;
  }

  return 0;
}


static int get_array_type_and_dims(type_description *desc, modelica_metatype arrdata)
{
  modelica_metatype item = NULL;

  if (MMC_GETHDR(arrdata) == MMC_NILHDR) {
    /* Empty arrays automaticly get to be real arrays */
    desc->type = TYPE_DESC_REAL_ARRAY;
    return 1;
  }

  item = MMC_CAR(arrdata);
  switch (MMC_HDRCTOR(MMC_GETHDR(item))) {
  case Values__INTEGER_3dBOX1:
    desc->type = TYPE_DESC_INT_ARRAY;
    return 1;
  case Values__REAL_3dBOX1:
    desc->type = TYPE_DESC_REAL_ARRAY;
    return 1;
  case Values__BOOL_3dBOX1:
    desc->type = TYPE_DESC_BOOL_ARRAY;
    return 1;
  case Values__STRING_3dBOX1:
    desc->type = TYPE_DESC_STRING_ARRAY;
    return 1;
  case Values__ARRAY_3dBOX2:
    return (1 + get_array_type_and_dims(desc, MMC_STRUCTDATA(item)[UNBOX_OFFSET+0]));
  case Values__ENUM_5fLITERAL_3dBOX2:
  case Values__LIST_3dBOX1:
  case Values__TUPLE_3dBOX1:
  case Values__RECORD_3dBOX4:
  case Values__CODE_3dBOX1:
    return -1;
  default:
    return -1;
  }
}


static int get_array_data(int curdim, int dims, const _index_t *dim_size,
                          modelica_metatype arrdata, enum type_desc_e type, modelica_metatype *data)
{
  modelica_metatype ptr = arrdata;
  assert(curdim > 0 && curdim <= dims);
  if (curdim == dims) {
    while (MMC_GETHDR(ptr) != MMC_NILHDR) {
      modelica_metatype item = MMC_CAR(ptr);

      switch (type) {
      case TYPE_DESC_REAL: {
        modelica_real *ptr = *((modelica_real**)data);
        if (MMC_HDRCTOR(MMC_GETHDR(item)) != Values__REAL_3dBOX1)
          return -1;
        *ptr = mmc_prim_get_real(MMC_STRUCTDATA(item)[UNBOX_OFFSET+0]);
        *data = ++ptr;
      }; break;
      case TYPE_DESC_INT: {
        modelica_integer *ptr = *((modelica_integer**)data);
        if (MMC_HDRCTOR(MMC_GETHDR(item)) != Values__INTEGER_3dBOX1)
          return -1;
        *ptr = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(item)[UNBOX_OFFSET+0]);
        *data = ++ptr;
      }; break;
      case TYPE_DESC_BOOL: {
        modelica_boolean *ptr = *((modelica_boolean**)data);
        if (MMC_HDRCTOR(MMC_GETHDR(item)) != Values__BOOL_3dBOX1)
          return -1;
        *ptr = (MMC_STRUCTDATA(item)[UNBOX_OFFSET+0] == MMC_TRUE);
        *data = ++ptr;
      }; break;
      case TYPE_DESC_STRING: {
        modelica_string *ptr = *((modelica_string**)data);
        modelica_metatype str;
        if (MMC_HDRCTOR(MMC_GETHDR(item)) != Values__STRING_3dBOX1)
          return -1;
        str = MMC_STRUCTDATA(item)[UNBOX_OFFSET+0];
        *ptr = str;
        *data = ++ptr;
      }; break;
      default:
        assert(0);
        return -1;
      }

      ptr = MMC_CDR(ptr);
    }
  } else {
    while (MMC_GETHDR(ptr) != MMC_NILHDR) {
      modelica_metatype item = MMC_CAR(ptr);
      if (MMC_HDRCTOR(MMC_GETHDR(item)) != Values__ARRAY_3dBOX2)
        return -1;

      if (get_array_data(curdim + 1, dims, dim_size, MMC_STRUCTDATA(item)[UNBOX_OFFSET+0],
                         type, data))
        return -1;

      ptr = MMC_CDR(ptr);
    }
  }

  return 0;
}

static int get_array_sizes(int dims, _index_t *dim_size, modelica_metatype dimLst)
{
  int i;
  modelica_metatype ptr = dimLst;

  for (i = 0; i < dims; i++) {
    assert(MMC_GETHDR(ptr) != MMC_NILHDR);
    dim_size[i] = MMC_UNTAGFIXNUM(MMC_CAR(ptr));
    ptr = MMC_CDR(ptr);
  }

  return 0;
}

/*
  TODO: Custom implementation of div,
  https://build.openmodelica.org/Documentation/ModelicaReference.Operators.%27div()%27.html
  (Custom implementation, otherwise we need a dedicated part of MidCode to detect calls to it)
*/
modelica_integer div_jit(modelica_integer a, modelica_integer b)
{
  return ldiv(a,b).quot;
}

modelica_integer stringInt_jit(modelica_string s)
{
  return nobox_stringInt(pthread_getspecific(mmc_thread_data_key),s);
}

modelica_integer integer_jit(modelica_real r)
{
  return floor(r);
}

modelica_metatype arrayCreate_jit(modelica_integer nelts,modelica_metatype val)
{
  return arrayCreate(nelts,val);
}

modelica_metatype arrayUpdate_jit(modelica_metatype arr, modelica_integer ix, modelica_metatype val)
{
  //TODO: Should not be like this... Seems like MidCode does not detect arrayUpdate correctly......
  modelica_metatype bIx = mmc_mk_icon(ix);
  threadData_t *threadData = pthread_getspecific(mmc_thread_data_key);
  return boxptr_arrayUpdate(threadData,arr,bIx,val);
}

modelica_metatype arrayGet_jit(modelica_metatype arr,modelica_integer ix)
{
    threadData_t *threadData = pthread_getspecific(mmc_thread_data_key);
	return nobox_arrayGet(threadData,arr,ix);
}

modelica_integer arrayLength_jit(modelica_metatype arr)
{
  return arrayLength(arr);
}

/*For base_array_t, so that we do not have to generate LLVM IR corresponding to the signature*/
modelica_metatype alloc_base_array_t_jit()
{
  base_array_t *arr;
  arr = GC_MALLOC(sizeof(arr));
  return arr;
}

/*We have to write a wrapper. passed as a pointer since we hack to avoid C-signatures*/
int size_of_dimension_base_array_jit(const base_array_t *a, int i)
{
  if ((i > 0) && (i <= a->ndims)) {
    return a->dim_size[i-1];
  }
  /* This is a weird work-around to return 0 if the dimension is out of bounds and a dimension is 0
   * The reason is that we lose the dimensions in the DAE.ARRAY after a 0-dimension
   * Note: We return size(arr,2)=0 if arr has dimensions [0,2], and not the expected 2
   */
  for (i=0; i<a->ndims; i++) {
    if (a->dim_size[i] == 0) {
      return 0;
    }
  }
  fprintf(stderr, "size_of_dimension_base_array failed for i=%d, ndims=%d (ndims out of bounds)\n", i, a->ndims);
  abort();
}

/*Builtin string operations */

modelica_integer stringLength_jit(modelica_metatype str)
{
  return MMC_STRLEN(str);
}

modelica_metatype stringGetStringChar_jit(threadData_t *threadData, metamodelica_string str, modelica_integer ix) {
  MMC_CHECK_STRING(str);
  if (ix < 1 || ix > (long) MMC_STRLEN(str))
    MMC_THROW_INTERNAL();
  return mmc_strings_len1[(size_t)MMC_STRINGDATA(str)[ix-1]];
}

modelica_metatype stringUpdateStringChar_jit(threadData_t *threadData,metamodelica_string str, metamodelica_string c, modelica_integer ix)
{
  int length = 0;
  unsigned header = MMC_GETHDR(str);
  unsigned nwords = MMC_HDRSLOTS(header) + 1;
  struct mmc_string *p = NULL;
  void *res = NULL;
  MMC_CHECK_STRING(str);
  MMC_CHECK_STRING(c);
  if (ix < 1 || MMC_STRLEN(c) != 1)
    MMC_THROW_INTERNAL();
  length = MMC_STRLEN(str);
  if (ix > length)
    MMC_THROW_INTERNAL();
  p = (struct mmc_string *) mmc_alloc_words_atomic(nwords);
  p->header = header;
  memcpy(p->data, MMC_STRINGDATA(str), length+1 /* include NULL */);
  p->data[ix-1] = MMC_STRINGDATA(c)[0];
  res = MMC_TAGPTR(p);
  MMC_CHECK_STRING(res);
  return res;
}

/*Builtin Integer operations*/
modelica_integer iMin(modelica_integer x, modelica_integer y)
{
  return x <  y ? x : y;
}

modelica_integer iMax(modelica_integer x, modelica_integer y)
{
  return x > y ? x : y;
}

modelica_integer iMod(modelica_integer x, modelica_integer y)
{
  return (x % y + y) % y;
}

#ifdef __cplusplus
}
#endif
