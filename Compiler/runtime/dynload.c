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

#if defined(_MSC_VER)
 #define WIN32_LEAN_AND_MEAN
 #include <Windows.h>
#endif

#include "systemimpl.h"
#include "meta_modelica.h"
#include "rml.h"
#include "Absyn.h"
#include "Values.h" 

void *type_desc_to_value(type_description *desc);
static int execute_function(void *in_arg, void **out_arg,
                            int (* func)(type_description *,
                                         type_description *));
int parse_array(type_description *desc, void *arrdata);

void DynLoad_5finit(void)
{
}

RML_BEGIN_LABEL(DynLoad__executeFunction)
{
  modelica_integer funcIndex = RML_UNTAGFIXNUM(rmlA0);
  modelica_ptr_t func = NULL;
  /* modelica_ptr_t lib = NULL; */
  int retval = -1;
  void *retarg = NULL;
  func = lookup_ptr(funcIndex);
  if (func == NULL)
    RML_TAILCALLK(rmlFC);

  /* lib = lookup_ptr(func->data.func.lib); */
  /* fprintf(stderr, "CALL FUNCTION LIB \n"); */
  /* index[%d]/count[%d]/handle[%ul].\n", (lib-ptr_vector),((modelica_ptr_t)(lib-ptr_vector))->cnt, lib->data.lib); fflush(stderr); */

  retval = execute_function(rmlA1, &retarg, func->data.func.handle);
  if (retval) {
    RML_TAILCALLK(rmlFC);
  } else {
    if (retarg)
      rmlA0 = retarg;
    RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL

void *generate_array(enum type_desc_e type, int curdim, int ndims,
                     int *dim_size, void **data)
{
  void *lst = (void *) mk_nil();
  void *dimLst = (void*) mk_nil();
  int i, cur_dim_size = dim_size[curdim - 1];

  if (curdim == ndims) {
    type_description tmp;
    tmp.type = type;

    switch (type) {
    case TYPE_DESC_REAL: {
      modelica_real *ptr = *data;
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.real = *ptr;
        lst = (void *) mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    case TYPE_DESC_INT: {
      modelica_integer *ptr = *data;
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.integer = *ptr;
        lst = (void *) mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    case TYPE_DESC_BOOL: {
      modelica_boolean *ptr = *data;
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.boolean = *ptr;
        lst = (void *) mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    case TYPE_DESC_STRING: {
      modelica_string_t *ptr = *data;
      for (i = 0; i < cur_dim_size; ++i, --ptr) {
        tmp.data.string = *ptr;
        lst = (void *) mk_cons(type_desc_to_value(&tmp), lst);
      }
      *data = ptr;
    }; break;
    default:
      assert(0);
      return NULL;
    }
  } else {
    for (i = 0; i < cur_dim_size; ++i) {
      lst = (void *) mk_cons(generate_array(type, curdim + 1, ndims, dim_size,
                                            data), lst);
    }
  }
  for (i = ndims; i >= curdim; i--) {
    dimLst = (void *) mk_cons(mk_icon(dim_size[i-1]), dimLst);
  }

  return Values__ARRAY(lst, dimLst);
}


char* path_to_name(void* path, char del)
{
  char* buf = 0;
  char* bufstart = 0;
  void* tmpPath;
  int length = 0;

  tmpPath = path;
  while (tmpPath != NULL) {
    switch (RML_HDRCTOR(RML_GETHDR(tmpPath))) {
    case Absyn__IDENT_3dBOX1: {
      length += RML_HDRSTRLEN(RML_GETHDR(RML_STRUCTDATA(tmpPath)[0]));
      tmpPath = NULL;
      break;
    };
    case Absyn__QUALIFIED_3dBOX2: {
      length += RML_HDRSTRLEN(RML_GETHDR(RML_STRUCTDATA(tmpPath)[0])) + 1;
      tmpPath = RML_STRUCTDATA(tmpPath)[1];
      break;
    };
    case Absyn__FULLYQUALIFIED_3dBOX1: {
      tmpPath = RML_STRUCTDATA(tmpPath)[0];
      break;
    };
    default:
      /* free(buf); */
      return "path_to_name: failed to parse";
    }
  }

  buf = bufstart = malloc((length+1)*sizeof(char));
  if (buf == NULL) {
    return "path_to_name: malloc failed";
  }

  tmpPath = path;
  while (tmpPath != NULL) {
    int sprintres;
    switch (RML_HDRCTOR(RML_GETHDR(tmpPath))) {
    case Absyn__IDENT_3dBOX1: {
      sprintres = sprintf(buf, "%s", RML_STRINGDATA(RML_STRUCTDATA(tmpPath)[0]));
      if (sprintres < 0) {
        free(buf);
        return "path_to_name: sprintf failed";
      }
      buf += sprintres;
      tmpPath = NULL;
      break;
    };
    case Absyn__QUALIFIED_3dBOX2: {
      sprintres = sprintf(buf, "%s%c", RML_STRINGDATA(RML_STRUCTDATA(tmpPath)[0]), del);
      if (sprintres < 0) {
        free(buf);
        return "path_to_name: sprintf failed";
      }
      buf += sprintres;
      tmpPath = RML_STRUCTDATA(tmpPath)[1];
      break;
    };
    case Absyn__FULLYQUALIFIED_3dBOX1: {
      tmpPath = RML_STRUCTDATA(tmpPath)[0];
      break;
    };
    default:
      free(buf);
      return "path_to_name: failed to parse";
    }
  }
  return bufstart;
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
      ident = mk_scon(tmp);
      free(tmp);
    } else {
      /* memcpy(&tmp, &name, sizeof(char *)); */ /* don't try this at home */
      ident = mk_scon((char*)name);
    }
    return Absyn__IDENT(ident);
  } else {
    size_t len = pos - name;
    tmp = malloc(len + 1);
    memcpy(tmp, name, len);
    tmp[len] = '\0';
    if (need_replace) {
      char *tmp2 = _replace(tmp, "__", "_");
      ident = mk_scon(tmp2);
      free(tmp2);
    } else {
      ident = mk_scon(tmp);
    }
    free(tmp);
    return Absyn__QUALIFIED(ident, name_to_path(pos + 1));
  }
}

void *mmc_list_reverse(void* data) {
  void* res = mmc_mk_nil();
  while (!MMC_NILTEST(data)) {
    res = mmc_mk_cons(MMC_CAR(data), res);
    data = MMC_CDR(data);
  }
  return res;
}

int mmc_to_value(void* mmc, void** res)
{
  mmc_uint_t hdr;
  int numslots;
  unsigned ctor;
  int i;
  void* t;
  if (0 == ((long)mmc & 1)) {
    *res = Values__INTEGER(mmc);
    return 0;
  }
  hdr = RML_GETHDR(mmc);
  if (hdr == RML_REALHDR) {
    *res = Values__REAL(mmc);
    return 0;
  }
  if (RML_HDRISSTRING(hdr)) {
    *res = Values__STRING(mmc);
    return 0;
  }
  if (hdr == RML_NILHDR) {
    *res = Values__LIST(mk_nil());
    return 0;
  }

  numslots = RML_HDRSLOTS(hdr);
  ctor = 255 & (hdr >> 2);


  if (numslots>0 && ctor == MMC_ARRAY_TAG) {
    void *varlst = (void *) mk_nil();
    for (i=numslots; i>0; i--) {
      assert(0 == mmc_to_value(RML_FETCH(RML_OFFSET(RML_UNTAGPTR(mmc),i)),&t));
      varlst = mk_cons(t, varlst);
    }
    *res = (void *) Values__META_5fARRAY(varlst);
    return 0;
  }
  
  if (numslots>0 && ctor > 1) { /* RECORD */
    void *namelst = (void *) mk_nil();
    void *varlst = (void *) mk_nil();
    struct record_description* desc = RML_FETCH(RML_OFFSET(RML_UNTAGPTR(mmc),1));
    assert(desc != NULL);
    for (i=numslots; i>1; i--) {
      assert(0 == mmc_to_value(RML_FETCH(RML_OFFSET(RML_UNTAGPTR(mmc),i)),&t));
      varlst = mk_cons(t, varlst);
      t = (void*) desc->fieldNames[i-2];
      namelst = mk_cons(mk_scon(t != NULL ? t : "(null)"), namelst);
    }
    *res = (void *) Values__RECORD(name_to_path(desc->path),
                                   varlst, namelst, mk_icon(ctor-3));
    return 0;
  }

  if (numslots>0 && ctor == 0) { /* TUPLE */
    void *varlst = (void *) mk_nil();
    for (i=numslots; i>0; i--) {
      assert(0 == mmc_to_value(RML_FETCH(RML_OFFSET(RML_UNTAGPTR(mmc),i)),&t));
      varlst = mk_cons(t, varlst);
    }
    *res = (void *) Values__META_5fTUPLE(varlst);
    return 0;
  }

  if (numslots==0 && ctor==1) /* NONE() */ {
    *res = Values__OPTION(mk_none());
    return 0;
  }

  if (numslots==1 && ctor==1) /* SOME(x) */ {
    assert(0 == mmc_to_value(RML_FETCH(RML_OFFSET(RML_UNTAGPTR(mmc),1)),&t));
    *res = Values__OPTION(mk_some(t));
    return 0;
  }

  if (numslots==2 && ctor==1) { /* CONS-PAIR */
    /* Transform list by first reversing it to preserve the order */
	void *varlst;
    mmc = mmc_list_reverse(mmc);
    varlst = (void *) mk_nil();
    while (!MMC_NILTEST(mmc)) {
      assert(0 == mmc_to_value(MMC_CAR(mmc),&t));
      varlst = mk_cons(t, varlst);
      mmc = MMC_CDR(mmc);
    }
    *res = (void *) Values__LIST(varlst);
    return 0;
  }

  fprintf(stderr, "mmc_to_value: %d slots; ctor %d - FAILED to detect the type\n", numslots, ctor);
  return 1;
}

void *value_to_mmc(void* value)
{
  switch (RML_HDRCTOR(RML_GETHDR(value))) {
  case Values__INTEGER_3dBOX1:
  case Values__REAL_3dBOX1:
  case Values__BOOL_3dBOX1:
  case Values__STRING_3dBOX1: {
    void *data = RML_STRUCTDATA(value)[0];
    return data;
  };
  case Values__ARRAY_3dBOX2:
    printf("Parsing of array inside uniontype failed\n");
    return 0;
  case Values__RECORD_3dBOX4: {
    void *path = RML_STRUCTDATA(value)[0];
    void *data = RML_STRUCTDATA(value)[1];
    void *names = RML_STRUCTDATA(value)[2];
    void *index = RML_STRUCTDATA(value)[3];
    int index_int = ((long)index >> 1);
    int i=0;
    void *tmp = names;
    void **data_mmc;
    struct record_description* desc = malloc(sizeof(struct record_description));
    if (desc == NULL) {
      fprintf(stderr, "value_to_mmc: malloc failed\n");
      return 0;
    }
    while (!MMC_NILTEST(tmp)) {
      i++; tmp = RML_CDR(tmp);
    }
    /* duplicate string? will this give problems with GC? */
    desc->path = path_to_name(path, '_');
    desc->name = path_to_name(path, '.');
    desc->fieldNames = malloc(i*sizeof(char*));
    data_mmc = malloc((i+1)*sizeof(void*));
    i=0;
    data_mmc[0] = desc;
    while (!MMC_NILTEST(names)) {
      desc->fieldNames[i] = RML_STRINGDATA(RML_CAR(names));
      names = MMC_CDR(names);
      data_mmc[i+1] = value_to_mmc(RML_CAR(data));
      i++;
      data = MMC_CDR(data);
    }
    return mmc_mk_box_arr(i+1, index_int+3, data_mmc);
  }; break;
  case Values__OPTION_3dBOX1: {
    void *data = RML_STRUCTDATA(value)[0];
    int numslots = RML_HDRSLOTS(RML_GETHDR(data));
    if (numslots == 0) return mmc_mk_none();
    return mmc_mk_some(value_to_mmc(RML_STRUCTDATA(data)[0]));
  }; break;
  case Values__LIST_3dBOX1: {
    void* data = RML_STRUCTDATA(value)[0];
    void* tmp = mmc_mk_nil();
    while (!MMC_NILTEST(data)) {
      tmp = mmc_mk_cons(value_to_mmc(MMC_CAR(data)), tmp);
      data = MMC_CDR(data);
    }
    /* Transform list by first reversing it to preserve the order */
    return mmc_list_reverse(tmp);;
  };
  case Values__META_5fTUPLE_3dBOX1: {
    void *data = RML_STRUCTDATA(value)[0];
    int len=0;
    void *tmp = data;
    void **data_mmc;

    while (!MMC_NILTEST(tmp)) {
      len++; tmp = RML_CDR(tmp);
    }
    data_mmc = malloc(len*sizeof(void*));
    len = 0;
    tmp = data;
    while (!MMC_NILTEST(tmp)) {
      data_mmc[len++] = value_to_mmc(RML_CAR(tmp));
      tmp = RML_CDR(tmp);
    }
    return mmc_mk_box_arr(len, 0, data_mmc);
  };
  case Values__ENUM_3dBOX3:
  case Values__CODE_3dBOX1:
    /* unsupported */
    fprintf(stderr, "%s:%d: enum,code unsupported in MetaModelica data\n", __FILE__, __LINE__);
    return 0;
  default:
    /* unsupported */
    fprintf(stderr, "%s:%d: Error, unknown type\n", __FILE__, __LINE__);
    return 0;
  }
}

static int value_to_type_desc(void *value, type_description *desc)
{
  init_type_description(desc);

  switch (RML_HDRCTOR(RML_GETHDR(value))) {
  case Values__INTEGER_3dBOX1: {
    void *data = RML_STRUCTDATA(value)[0];
    desc->type = TYPE_DESC_INT;
    desc->data.integer = RML_UNTAGFIXNUM(data);
  }; break;
  case Values__REAL_3dBOX1: {
    void *data = RML_STRUCTDATA(value)[0];
    desc->type = TYPE_DESC_REAL;
    desc->data.real = rml_prim_get_real(data);
  }; break;
  case Values__BOOL_3dBOX1: {
    void *data = RML_STRUCTDATA(value)[0];
    desc->type = TYPE_DESC_BOOL;
    desc->data.boolean = (data == RML_TRUE);
  }; break;
  case Values__STRING_3dBOX1: {
    void *data = RML_STRUCTDATA(value)[0];
    int len = RML_HDRSTRLEN(RML_GETHDR(data));
    desc->type = TYPE_DESC_STRING;
    alloc_modelica_string(&(desc->data.string), len);
    memcpy(desc->data.string, RML_STRINGDATA(data), len + 1);
  }; break;
  case Values__ARRAY_3dBOX2: {
    void *data = RML_STRUCTDATA(value)[0];
    if (parse_array(desc, data)) {
      printf("Parsing of array failed\n");
      return -1;
    }
  }; break;
  case Values__RECORD_3dBOX4: {
    void *path = RML_STRUCTDATA(value)[0];
    void *data = RML_STRUCTDATA(value)[1];
    void *names = RML_STRUCTDATA(value)[2];
    void *index = RML_STRUCTDATA(value)[3];
    if (-1 != ((long)index >> 1)) {
      desc->type = TYPE_DESC_MMC;
      desc->data.mmc = value_to_mmc(value);
      break;
    }
    desc->type = TYPE_DESC_RECORD;
    //fprintf(stderr, "makepath: %s\n", path_to_name(path));
    desc->data.record.record_name = path_to_name(path, '.');
    while ((RML_GETHDR(names) != RML_NILHDR) &&
           (RML_GETHDR(data) != RML_NILHDR)) {
      type_description *elem;
      void *nptr;

      nptr = RML_CAR(names);
      elem = add_modelica_record_member(desc, RML_STRINGDATA(nptr),
                                        RML_HDRSTRLEN(RML_GETHDR(nptr)));

      if (value_to_type_desc(RML_CAR(data), elem)) {
        return -1;
      }
      data = RML_CDR(data);
      names = RML_CDR(names);
    }
  }; break;

  case Values__TUPLE_3dBOX1: {  
    void *data = RML_STRUCTDATA(value)[0];
    desc->type = TYPE_DESC_TUPLE;
    while (RML_GETHDR(data) != RML_NILHDR) { 
      type_description *elem; 
 
      elem = add_tuple_member(desc);

      if (value_to_type_desc(RML_CAR(data), elem)) {
        return -1;
      }
      data = RML_CDR(data);
    }
  }; break;
  case Values__META_5fTUPLE_3dBOX1:
  case Values__LIST_3dBOX1:
  case Values__OPTION_3dBOX1:
    desc->type = TYPE_DESC_MMC;
    desc->data.mmc = value_to_mmc(value);
    break;
    /* unsupported */
  case Values__ENUM_3dBOX3:
    c_add_message(-1, "RUNTIME", "ERROR", "systemimpl.c:value_to_type_desc failed: Values.ENUM\n", NULL, 0);
    return -1;
  case Values__CODE_3dBOX1:
    c_add_message(-1, "RUNTIME", "ERROR", "systemimpl.c:value_to_type_desc failed: Values.CODE\n", NULL, 0);
    return -1;
  default:
    c_add_message(-1, "RUNTIME", "ERROR", "systemimpl.c:value_to_type_desc failed\n", NULL, 0);
    return -1;
  }

  return 0;
}

void *type_desc_to_value(type_description *desc)
{
  switch (desc->type) {
  case TYPE_DESC_NONE:
    return NULL;
  case TYPE_DESC_NORETCALL:
    return (void *) Values__NORETCALL;
  case TYPE_DESC_REAL:
    return (void *) Values__REAL(mk_rcon(desc->data.real));
  case TYPE_DESC_INT:
    return (void *) Values__INTEGER(mk_icon(desc->data.integer));
  case TYPE_DESC_BOOL:
	  if(getMyBool(desc)) 
		  return (void *) Values__BOOL(RML_TRUE);
	  return (void *) Values__BOOL(RML_FALSE); 
  case TYPE_DESC_STRING:
    return (void *) Values__STRING(mk_scon(desc->data.string));
  case TYPE_DESC_TUPLE: {
    type_description *e = desc->data.tuple.element + desc->data.tuple.elements;
    void *lst = (void *) mk_nil();
    while (e > desc->data.tuple.element) {
      void *t = type_desc_to_value(--e);
      if (t == NULL)
        return NULL;
      lst = mk_cons(t, lst);
    }
    return (void *) Values__TUPLE(lst);
  };
  case TYPE_DESC_RECORD: { 
    char **name = desc->data.record.name + desc->data.record.elements;
    type_description *e = desc->data.record.element + desc->data.record.elements;
    void *namelst = (void *) mk_nil();
    void *varlst = (void *) mk_nil();
    while (e > desc->data.record.element) { 
      void *n, *t;
      --name;
      --e;
      n = mk_scon(*name);
      t = type_desc_to_value(e);
      if (n == NULL || t == NULL)
        return NULL;
      namelst = mk_cons(n, namelst);
      varlst = mk_cons(t, varlst);
    }
    return (void *) Values__RECORD(name_to_path(desc->data.record.record_name),
                                   varlst, namelst, mk_icon(-1));
  };
  case TYPE_DESC_REAL_ARRAY: {
    void *ptr = (modelica_real *) desc->data.real_array.data
      + real_array_nr_of_elements(&(desc->data.real_array)) - 1;
    return generate_array(TYPE_DESC_REAL, 1, desc->data.real_array.ndims,
                          desc->data.real_array.dim_size, &ptr);
  };
  case TYPE_DESC_INT_ARRAY: {
    void *ptr = (modelica_integer *) desc->data.int_array.data
      + integer_array_nr_of_elements(&(desc->data.int_array)) - 1;
    return generate_array(TYPE_DESC_INT, 1, desc->data.int_array.ndims,
                          desc->data.int_array.dim_size, &ptr);
  };
  case TYPE_DESC_BOOL_ARRAY: {
    void *ptr = (modelica_boolean *) desc->data.bool_array.data
      + boolean_array_nr_of_elements(&(desc->data.bool_array)) - 1;
    return generate_array(TYPE_DESC_BOOL, 1, desc->data.bool_array.ndims,
                          desc->data.bool_array.dim_size, &ptr);
  };
  case TYPE_DESC_STRING_ARRAY: {
    void *ptr = (modelica_string_t *) desc->data.string_array.data
      + string_array_nr_of_elements(&(desc->data.string_array)) - 1;
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
  }

  assert(0);
  return NULL;
}

static int get_array_type_and_dims(type_description *desc, void *arrdata)
{
  void *item = NULL;

  if (RML_GETHDR(arrdata) == RML_NILHDR) {
    /* Empty arrays automaticly get to be real arrays */
    desc->type = TYPE_DESC_REAL_ARRAY;
    return 1;
  }

  item = RML_CAR(arrdata);
  switch (RML_HDRCTOR(RML_GETHDR(item))) {
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
    return (1 + get_array_type_and_dims(desc, RML_STRUCTDATA(item)[0]));
  case Values__ENUM_3dBOX3:
  case Values__LIST_3dBOX1:
  case Values__TUPLE_3dBOX1:
  case Values__RECORD_3dBOX4:
  case Values__CODE_3dBOX1:
    return -1;
  default:
    return -1;
  }
}

static int get_array_sizes(int curdim, int dims, int *dim_size, void *arrdata)
{
  int size = 0;
  void *ptr = arrdata;

  assert(curdim > 0 && curdim <= dims);

  while (RML_GETHDR(ptr) != RML_NILHDR) {
    ++size;
    ptr = RML_CDR(ptr);
  }

  dim_size[curdim - 1] = size;

  if (size > 0) {
    void *item = RML_CAR(arrdata);
    if (RML_HDRCTOR(RML_GETHDR(item)) == Values__ARRAY_3dBOX2) {
      return get_array_sizes(curdim + 1, dims, dim_size,
                             RML_STRUCTDATA(item)[0]);
    }
  }

  return 0;
}

static int get_array_data(int curdim, int dims, const int *dim_size,
                          void *arrdata, enum type_desc_e type, void **data)
{
  void *ptr = arrdata;
  assert(curdim > 0 && curdim <= dims);
  if (curdim == dims) {
    while (RML_GETHDR(ptr) != RML_NILHDR) {
      void *item = RML_CAR(ptr);

      switch (type) {
      case TYPE_DESC_REAL: {
        modelica_real *ptr = *data;
        if (RML_HDRCTOR(RML_GETHDR(item)) != Values__REAL_3dBOX1)
          return -1;
        *ptr = rml_prim_get_real(RML_STRUCTDATA(item)[0]);
        *data = ++ptr;
      }; break;
      case TYPE_DESC_INT: {
        modelica_integer *ptr = *data;
        if (RML_HDRCTOR(RML_GETHDR(item)) != Values__INTEGER_3dBOX1)
          return -1;
        *ptr = RML_UNTAGFIXNUM(RML_STRUCTDATA(item)[0]);
        *data = ++ptr;
      }; break;
      case TYPE_DESC_BOOL: {
        modelica_boolean *ptr = *data;
        if (RML_HDRCTOR(RML_GETHDR(item)) != Values__BOOL_3dBOX1)
          return -1;
        *ptr = (RML_STRUCTDATA(item)[0] == RML_TRUE);
        *data = ++ptr;
      }; break;
      case TYPE_DESC_STRING: {
        modelica_string_t *ptr = *data;
        int len;
        void *str;
        if (RML_HDRCTOR(RML_GETHDR(item)) != Values__STRING_3dBOX1)
          return -1;
        str = RML_STRUCTDATA(item)[0];
        len = RML_HDRSTRLEN(RML_GETHDR(str));
        alloc_modelica_string(ptr, len);
        memcpy(*ptr, RML_STRINGDATA(str), len + 1);
        *data = ++ptr;
      }; break;
      default:
        assert(0);
        return -1;
      }

      ptr = RML_CDR(ptr);
    }
  } else {
    while (RML_GETHDR(ptr) != RML_NILHDR) {
      void *item = RML_CAR(ptr);
      if (RML_HDRCTOR(RML_GETHDR(item)) != Values__ARRAY_3dBOX2)
        return -1;

      if (get_array_data(curdim + 1, dims, dim_size, RML_STRUCTDATA(item)[0],
                         type, data))
        return -1;

      ptr = RML_CDR(ptr);
    }
  }

  return 0;
}

int parse_array(type_description *desc, void *arrdata)
{
  int dims, *dim_size;
  void *data;
  assert(desc->type == TYPE_DESC_NONE);
  dims = get_array_type_and_dims(desc, arrdata);
  if (dims < 1) {
    printf("dims: %d\n", dims);
    return -1;
  }
  dim_size = malloc(sizeof(int) * dims);
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
  if (get_array_sizes(1, dims, dim_size, arrdata))
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

static int execute_function(void *in_arg, void **out_arg,
                            int (* func)(type_description *,
                                         type_description *))
{
  type_description arglst[RML_NUM_ARGS + 1], crashbuf[50], *arg = NULL;
  type_description crashbufretarg, retarg;
  void *v = NULL;
  int retval = 0;
  int debugFlag = check_debug_flag("dynload");
  state mem_state;

  mem_state = get_memory_state();

  if (debugFlag) { fprintf(stderr, "input parameters:\n"); fflush(stderr); }

  v = in_arg;
  arg = arglst;

  while (RML_GETHDR(v) != RML_NILHDR) {
    void *val = RML_CAR(v);
    if (value_to_type_desc(val, arg)) {
      restore_memory_state(mem_state);
      if (debugFlag)
      {
        puttype(arg);
        fprintf(stderr, "returning from execute function due to value_to_type_desc failure!\n"); fflush(stderr);
      }
       return -1;
    }
    if (debugFlag) puttype(arg);
    ++arg;
    v = RML_CDR(v);
  }

  init_type_description(arg);
  init_type_description(&crashbufretarg);
  init_type_description(&retarg);
  init_type_description(&crashbuf[5]);

  retarg.retval = 1;

  if (debugFlag) { fprintf(stderr, "calling the function\n"); fflush(stderr); }
  /* call our function pointer! */
  retval = func(arglst, &retarg);

  /* free the type description for the input parameters! */
  arg = arglst;
  while (arg->type != TYPE_DESC_NONE) {
    free_type_description(arg);
    ++arg;
  }

  restore_memory_state(mem_state);

  if (retval) {
    return 1;
  } else {
    if (debugFlag) { fprintf(stderr, "output results:\n"); fflush(stderr); puttype(&retarg); }

    (*out_arg) = type_desc_to_value(&retarg);
    /* out_arg doesn't seem to get freed, something we can do anything about?
     * adrpo: 2009-09. it shouldn't be freed!
     */

    free_type_description(&retarg);

    if ((*out_arg) == NULL) {
      printf("Unable to parse returned values.\n");
      return -1;
    }

    return 0;
  }
}
