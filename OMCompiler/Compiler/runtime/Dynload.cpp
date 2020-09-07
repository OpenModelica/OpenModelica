/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


extern "C" {

#include <stdio.h>
#include <stdlib.h>
#include "openmodelica.h"
#include "util/read_write.h"
#include "util/real_array.h"
#include "util/string_array.h"
#include "util/boolean_array.h"
#include "util/integer_array.h"
#include "systemimpl.h"
#include "errorext.h"
#include "meta/meta_modelica_builtin.h"

#define MMC_NUM_ARGS 32
#define UNBOX_OFFSET 1

static void *type_desc_to_value(type_description *desc);
static int value_to_type_desc(void *value, type_description *desc);
static int execute_function(threadData_t* threadData, void *in_arg, void **out_arg,
                            int (* func)(threadData_t*,
                                         type_description *,
                                         type_description *), int printDebug);
static int parse_array(type_description *desc, void *arrdata, void *dimLst);
static void *value_to_mmc(void* value);
static const char* path_to_name(void* path, char del);

static int value_to_type_desc(void *value, type_description *desc)
{
  init_type_description(desc);

  switch (MMC_HDRCTOR(MMC_GETHDR(value))) {
  case Values__INTEGER_3dBOX1: {
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    desc->type = TYPE_DESC_INT;
    desc->data.integer = MMC_UNTAGFIXNUM(data);
  }; break;
  case Values__ENUM_5fLITERAL_3dBOX2: {
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+1];
    desc->type = TYPE_DESC_INT;
    desc->data.integer = MMC_UNTAGFIXNUM(data);
  }; break;
  case Values__REAL_3dBOX1: {
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    desc->type = TYPE_DESC_REAL;
    desc->data.real = mmc_prim_get_real(data);
  }; break;
  case Values__BOOL_3dBOX1: {
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    desc->type = TYPE_DESC_BOOL;
    desc->data.boolean = (data == MMC_TRUE);
  }; break;
  case Values__STRING_3dBOX1: {
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    desc->type = TYPE_DESC_STRING;
    desc->data.string = data;
  }; break;
  case Values__ARRAY_3dBOX2: {
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    void *dimLst = MMC_STRUCTDATA(value)[UNBOX_OFFSET+1];
    if (parse_array(desc, data, dimLst)) {
      printf("Parsing of array failed\n");
      return -1;
    }
  }; break;
  case Values__RECORD_3dBOX4: {
    void *path = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+1];
    void *names = MMC_STRUCTDATA(value)[UNBOX_OFFSET+2];
    void *index = MMC_STRUCTDATA(value)[UNBOX_OFFSET+3];
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
      void *nptr;

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
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET];
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

static int execute_function(threadData_t* threadData,
                            void *in_arg, void **out_arg,
                            int (* func)(threadData_t*,
                                         type_description *,
                                         type_description *), int printDebug)
{
  type_description arglst[MMC_NUM_ARGS + 1], crashbuf[50], *arg = NULL;
  type_description crashbufretarg, retarg;
  void *v = NULL;
  int retval = 0;

  if (printDebug) { fprintf(stderr, "[dynload]: input parameters:\n"); fflush(stderr); }

  v = in_arg;
  arg = arglst;

  while (!listEmpty(v)) {
    void *val = MMC_CAR(v);
    if (value_to_type_desc(val, arg)) {
      if (printDebug)
      {
        puttype(arg);
        fprintf(stderr, "[dynload]: returning from execute function due to value_to_type_desc failure!\n"); fflush(stderr);
      }
      return -1;
    }
    if (printDebug) puttype(arg);
    ++arg;
    v = MMC_CDR(v);
  }

  init_type_description(arg);
  init_type_description(&crashbufretarg);
  init_type_description(&retarg);
  init_type_description(&crashbuf[5]);

  retarg.retval = 1;

  if (printDebug) { fprintf(stderr, "[dynload]: calling the function\n"); fflush(stderr); }

  fflush(stdout);
  /* call our function pointer! */
  try { /* Don't let external C functions throwing C++ exceptions kill OMC! */
    retval = func(threadData, arglst, &retarg);
  } catch (...) {
    retval = 1;
  }
  /* Flush all buffers for deterministic behaviour; in particular for the testsuite */
  fflush(NULL);

  /* free the type description for the input parameters! */
  arg = arglst;
  while (arg->type != TYPE_DESC_NONE) {
    free_type_description(arg);
    ++arg;
  }

  if (retval) {
    *out_arg = Values__META_5fFAIL;
    return 0;
  } else {
    if (printDebug) { fprintf(stderr, "[dynload]: output results:\n"); fflush(stderr); puttype(&retarg); }

    (*out_arg) = type_desc_to_value(&retarg);
    /* out_arg doesn't seem to get freed, something we can do anything about?
     * adrpo: 2009-09. it shouldn't be freed!
     */

    free_type_description(&retarg);

    if ((*out_arg) == NULL) {
      printf("[dynload]: Unable to parse returned values.\n");
      return -1;
    }

    return 0;
  }
}

static void *generate_array(enum type_desc_e type, int curdim, int ndims,
                     _index_t *dim_size, void **data)
{
  void *lst = (void *) mmc_mk_nil();
  void *dimLst = (void*) mmc_mk_nil();
  int i, cur_dim_size = dim_size[curdim - 1];

  if (curdim == ndims) {
    type_description tmp;
    tmp.type = type;

    switch (type) {
    case TYPE_DESC_REAL: {
      modelica_real *ptr = *((modelica_real**)data);
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.real = *ptr;
        lst = (void *) mmc_mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    case TYPE_DESC_INT: {
      modelica_integer *ptr = *((modelica_integer**)data);
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.integer = *ptr;
        lst = (void *) mmc_mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    case TYPE_DESC_BOOL: {
      modelica_boolean *ptr = *((modelica_boolean**)data);
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.boolean = *ptr;
        lst = (void *) mmc_mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    case TYPE_DESC_STRING: {
      modelica_string *ptr = *((modelica_string**)data);
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.string = *ptr;
        lst = (void *) mmc_mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    default:
      assert(0);
      return NULL;
    }
  } else {
    for (i = 0; i < cur_dim_size; ++i) {
      lst = (void *) mmc_mk_cons(generate_array(type, curdim + 1, ndims, dim_size,
                                            data), lst);
    }
  }
  for (i = ndims; i >= curdim; i--) {
    dimLst = (void *) mmc_mk_cons(mmc_mk_icon(dim_size[i-1]), dimLst);
  }

  return Values__ARRAY(lst, dimLst);
}


static void *name_to_path(const char *name)
{
  const char *last = name, *pos = NULL;
  char *tmp;
  void *ident = NULL;
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

static int mmc_to_value(void* mmc, void** res)
{
  mmc_uint_t hdr;
  int numslots;
  unsigned ctor;
  int i;
  void* t;
  if (MMC_IS_INTEGER(mmc)) {
    *res = Values__INTEGER(mmc_mk_icon(MMC_UNTAGFIXNUM(mmc)));
    return 0;
  }
  hdr = MMC_GETHDR(mmc);
  if (hdr == MMC_REALHDR) {
    *res = Values__REAL(mmc_mk_rcon(mmc_unbox_real(mmc)));
    return 0;
  }
  if (MMC_HDRISSTRING(hdr)) {
    MMC_CHECK_STRING(mmc);
    // We need to duplicate the string because literals may not be accessible anymore... Bleh
    *res = Values__STRING(mmc_mk_scon(MMC_STRINGDATA(mmc)));
    return 0;
  }
  if (hdr == MMC_NILHDR) {
    *res = Values__LIST(mmc_mk_nil());
    return 0;
  }

  numslots = MMC_HDRSLOTS(hdr);
  ctor = 255 & (hdr >> 2);


  if (numslots>0 && ctor == MMC_ARRAY_TAG) {
    void *varlst = (void *) mmc_mk_nil();
    for (i=numslots; i>0; i--) {
      assert(0 == mmc_to_value(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),i)),&t));
      varlst = mmc_mk_cons(t, varlst);
    }
    *res = (void *) Values__META_5fARRAY(varlst);
    return 0;
  }

  if (numslots>0 && ctor > 1) { /* RECORD */
    void *namelst = (void *) mmc_mk_nil();
    void *varlst = (void *) mmc_mk_nil();
    struct record_description* desc = (struct record_description*) MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),1));
    assert(desc != NULL);
    for (i=numslots; i>1; i--) {
      assert(0 == mmc_to_value(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),i)),&t));
      varlst = mmc_mk_cons(t, varlst);
      t = (void*) desc->fieldNames[i-2];
      namelst = mmc_mk_cons(mmc_mk_scon(t != NULL ? (const char*) t : "(null)"), namelst);
    }
    *res = (void *) Values__RECORD(name_to_path(desc->path),
                                   varlst, namelst, mmc_mk_icon(((mmc_sint_t)ctor)-3));
    return 0;
  }

  if (numslots>0 && ctor == 0) { /* TUPLE */
    void *varlst = (void *) mmc_mk_nil();
    for (i=numslots; i>0; i--) {
      assert(0 == mmc_to_value(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),i)),&t));
      varlst = mmc_mk_cons(t, varlst);
    }
    *res = (void *) Values__META_5fTUPLE(varlst);
    return 0;
  }

  if (numslots==0 && ctor==1) /* NONE() */ {
    *res = Values__OPTION(mmc_mk_none());
    return 0;
  }

  if (numslots==1 && ctor==1) /* SOME(x) */ {
    assert(0 == mmc_to_value(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),1)),&t));
    *res = Values__OPTION(mmc_mk_some(t));
    return 0;
  }

  if (numslots==2 && ctor==1) { /* CONS-PAIR */
    /* Transform list by first reversing it to preserve the order */
    void *varlst;
    mmc = listReverse(mmc);
    varlst = (void *) mmc_mk_nil();
    while (!MMC_NILTEST(mmc)) {
      assert(0 == mmc_to_value(MMC_CAR(mmc),&t));
      varlst = mmc_mk_cons(t, varlst);
      mmc = MMC_CDR(mmc);
    }
    *res = (void *) Values__LIST(varlst);
    return 0;
  }

  fprintf(stderr, "mmc_to_value: %d slots; ctor %d - FAILED to detect the type\n", numslots, ctor);
  return 1;
}

static void *value_to_mmc(void* value)
{
  switch (MMC_HDRCTOR(MMC_GETHDR(value))) {
  case Values__INTEGER_3dBOX1:
  case Values__BOOL_3dBOX1: {
    return mmc_mk_icon(MMC_UNTAGFIXNUM(MMC_STRUCTDATA(value)[UNBOX_OFFSET+0]));
  };
  case Values__STRING_3dBOX1: {
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
    return mmc_mk_scon(MMC_STRINGDATA(data));
  };
  case Values__REAL_3dBOX1: {
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
    return mmc_mk_rcon(mmc_prim_get_real(data));
  }
  case Values__ARRAY_3dBOX2:
    printf("[dynload]: Parsing of array inside uniontype failed\n");
    return 0;
  case Values__RECORD_3dBOX4: {
    void *path = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+1];
    void *names = MMC_STRUCTDATA(value)[UNBOX_OFFSET+2];
    void *index = MMC_STRUCTDATA(value)[UNBOX_OFFSET+3];
    int index_int = ((mmc_sint_t)index >> 1);
    int i=0;
    void *tmp = names;
    void **data_mmc;
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
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
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
    void *data = MMC_STRUCTDATA(value)[UNBOX_OFFSET+0];
    int len=0;
    void *tmp = data;
    void **data_mmc;
    void *res;

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

void *type_desc_to_value(type_description *desc)
{
  switch (desc->type) {
  case TYPE_DESC_NONE:
    return NULL;
  case TYPE_DESC_NORETCALL:
    return (void *) Values__NORETCALL;
  case TYPE_DESC_REAL:
    return (void *) Values__REAL(mmc_mk_rcon(desc->data.real));
  case TYPE_DESC_INT:
    return (void *) Values__INTEGER(mmc_mk_icon(desc->data.integer));
  case TYPE_DESC_BOOL:
    if(getMyBool(desc))
      return (void *) Values__BOOL(MMC_TRUE);
    return (void *) Values__BOOL(MMC_FALSE);
  case TYPE_DESC_STRING:
    /* Duplicate since we unload the object */
    return (void *) Values__STRING(mmc_mk_scon(MMC_STRINGDATA(desc->data.string)));
  case TYPE_DESC_TUPLE: {
    type_description *e = desc->data.tuple.element + desc->data.tuple.elements;
    void *lst = (void *) mmc_mk_nil();
    while (e > desc->data.tuple.element) {
      void *t = type_desc_to_value(--e);
      if (t == NULL)
        return NULL;
      lst = mmc_mk_cons(t, lst);
    }
    return (void *) Values__TUPLE(lst);
  };
  case TYPE_DESC_RECORD: {
    char **name = desc->data.record.name + desc->data.record.elements;
    type_description *e = desc->data.record.element + desc->data.record.elements;
    void *namelst = (void *) mmc_mk_nil();
    void *varlst = (void *) mmc_mk_nil();
    while (e > desc->data.record.element) {
      void *n, *t;
      --name;
      --e;
      n = mmc_mk_scon(*name);
      t = type_desc_to_value(e);
      if (n == NULL || t == NULL)
        return NULL;
      namelst = mmc_mk_cons(n, namelst);
      varlst = mmc_mk_cons(t, varlst);
    }
    return (void *) Values__RECORD(name_to_path(desc->data.record.record_name),
                                   varlst, namelst, mmc_mk_icon(-1));
  };
  case TYPE_DESC_REAL_ARRAY: {
    void *ptr = (modelica_real *) desc->data.real_array.data
      + base_array_nr_of_elements(desc->data.real_array) - 1;
    return generate_array(TYPE_DESC_REAL, 1, desc->data.real_array.ndims,
                          desc->data.real_array.dim_size, &ptr);
  };
  case TYPE_DESC_INT_ARRAY: {
    void *ptr = (modelica_integer *) desc->data.int_array.data
      + base_array_nr_of_elements(desc->data.int_array) - 1;
    return generate_array(TYPE_DESC_INT, 1, desc->data.int_array.ndims,
                          desc->data.int_array.dim_size, &ptr);
  };
  case TYPE_DESC_BOOL_ARRAY: {
    void *ptr = (modelica_boolean *) desc->data.bool_array.data
      + base_array_nr_of_elements(desc->data.bool_array) - 1;
    return generate_array(TYPE_DESC_BOOL, 1, desc->data.bool_array.ndims,
                          desc->data.bool_array.dim_size, &ptr);
  };
  case TYPE_DESC_STRING_ARRAY: {
    void *ptr = (modelica_string *) desc->data.string_array.data
      + base_array_nr_of_elements(desc->data.string_array) - 1;
    return generate_array(TYPE_DESC_STRING, 1, desc->data.string_array.ndims,
                          desc->data.string_array.dim_size, &ptr);
  };
  case TYPE_DESC_MMC: {
    void* t = 0;
    assert(0 == mmc_to_value(desc->data.mmc, &t));
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

static int get_array_type_and_dims(type_description *desc, void *arrdata)
{
  void *item = NULL;

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

static int get_array_sizes(int dims, _index_t *dim_size, void *dimLst)
{
  int i;
  void *ptr = dimLst;

  for (i = 0; i < dims; i++) {
    assert(MMC_GETHDR(ptr) != MMC_NILHDR);
    dim_size[i] = MMC_UNTAGFIXNUM(MMC_CAR(ptr));
    ptr = MMC_CDR(ptr);
  }

  return 0;
}

static int get_array_data(int curdim, int dims, const _index_t *dim_size,
                          void *arrdata, enum type_desc_e type, void **data)
{
  void *ptr = arrdata;
  assert(curdim > 0 && curdim <= dims);
  if (curdim == dims) {
    while (MMC_GETHDR(ptr) != MMC_NILHDR) {
      void *item = MMC_CAR(ptr);

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
        void *str;
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
      void *item = MMC_CAR(ptr);
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

static int parse_array(type_description *desc, void *arrdata, void *dimLst)
{
  _index_t dims, *dim_size;
  void *data;
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

}
