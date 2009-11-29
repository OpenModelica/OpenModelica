#ifdef __cplusplus
extern "C" {
#endif
/* header part */
#define SimpleFun_tryFunction_rettype_1 targ1
typedef struct SimpleFun_tryFunction_rettype_s
{
    modelica_real targ1; /* [] */
} SimpleFun_tryFunction_rettype;

DLLExport 
SimpleFun_tryFunction_rettype _SimpleFun_tryFunction(modelica_real a);

DLLExport 
int in_SimpleFun_tryFunction(type_description * inArgs, type_description * outVar);
#define SimpleFun_otherFun_rettype_1 targ1
#define SimpleFun_otherFun_rettype_2 targ2
typedef struct SimpleFun_otherFun_rettype_s
{
    modelica_real targ1; /* [] */
    modelica_real targ2; /* [] */
} SimpleFun_otherFun_rettype;

DLLExport 
SimpleFun_otherFun_rettype _SimpleFun_otherFun(modelica_real ia, modelica_real ib);

DLLExport 
int in_SimpleFun_otherFun(type_description * inArgs, type_description * outVar);
struct Try_Rec {
  modelica_real r1;
  modelica_real r2;
};
const char* SimpleFun_Try__Rec__desc__fields[] = {"r1","r2"};
struct record_description SimpleFun_Try__Rec__desc = {
    "SimpleFun_Try__Rec", /* package_record__X */
    "SimpleFun.Try_Rec", /* package.record_X */
    SimpleFun_Try__Rec__desc__fields
};
#define SimpleFun_mk__rec_rettype_1 targ1
typedef struct SimpleFun_mk__rec_rettype_s
{
    struct Try_Rec targ1; /* [] */
} SimpleFun_mk__rec_rettype;

DLLExport 
SimpleFun_mk__rec_rettype _SimpleFun_mk__rec(modelica_real a, modelica_real b);

DLLExport 
int in_SimpleFun_mk__rec(type_description * inArgs, type_description * outVar);
#define SimpleFun_recFun_rettype_1 targ1
typedef struct SimpleFun_recFun_rettype_s
{
    modelica_real targ1; /* [] */
} SimpleFun_recFun_rettype;

DLLExport 
SimpleFun_recFun_rettype _SimpleFun_recFun(struct Try_Rec tr);

DLLExport 
int in_SimpleFun_recFun(type_description * inArgs, type_description * outVar);
/* End of header part */

/* Body */
SimpleFun_tryFunction_rettype _SimpleFun_tryFunction(modelica_real a)
{
  SimpleFun_tryFunction_rettype tmp1;
  state tmp2;
  modelica_real tmp1;
  tmp2 = get_memory_state();
  tmp1 = (10.0 * a);
  
  _return:
  tmp1.targ1 = tmp1;
  restore_memory_state(tmp2);
  return tmp1;
}

int in_SimpleFun_tryFunction(type_description * inArgs, type_description * outVar)
{
  modelica_real a;
  SimpleFun_tryFunction_rettype out;
  if(read_modelica_real(&inArgs, &a)) return 1;
  out = _SimpleFun_tryFunction(a);
  write_modelica_real(outVar, &out.targ1);
  return 0;
}

SimpleFun_otherFun_rettype _SimpleFun_otherFun(modelica_real ia, modelica_real ib)
{
  SimpleFun_otherFun_rettype tmp1;
  state tmp2;
  modelica_real yy;
  modelica_real xx;
  modelica_real s;
  state tmp3;
  modelica_integer tmp5;
  modelica_integer tmp6;
  modelica_integer tmp7;
  state tmp8;
  modelica_integer tmp10;
  modelica_integer tmp11;
  modelica_integer tmp12;
  modelica_boolean tmp13;
  tmp2 = get_memory_state();
  s = ((modelica_real)0);
  tmp5 = 1; tmp6 = (1); tmp7 = 10;
  {
  modelica_integer i;

    for (i = tmp5; in_range_integer(i, tmp5, tmp7); i += tmp6) {
      tmp3 = get_memory_state();
      s = (s + (ia * ((modelica_real)(modelica_integer)i)));
      restore_memory_state(tmp3);
    }
  } /* end for*/

  yy = ((10.0 * ia) + (ib + s));
  tmp10 = 1; tmp11 = (1); tmp12 = 10;
  {
  modelica_integer i;

    for (i = tmp10; in_range_integer(i, tmp10, tmp12); i += tmp11) {
      tmp8 = get_memory_state();
      s = (s + (ia * ((modelica_real)(modelica_integer)i)));
      restore_memory_state(tmp8);
    }
  } /* end for*/

  tmp13 = (yy > 10.0);
  if (tmp13) {
  }
  else {
  }
  s = ((tmp13)?(4.0 + s):(s - 2.0));
  xx = (yy / s);
  
  _return:
  tmp1.targ1 = yy;
  tmp1.targ2 = xx;
  restore_memory_state(tmp2);
  return tmp1;
}

int in_SimpleFun_otherFun(type_description * inArgs, type_description * outVar)
{
  modelica_real ia;
  modelica_real ib;
  SimpleFun_otherFun_rettype out;
  if(read_modelica_real(&inArgs, &ia)) return 1;
  if(read_modelica_real(&inArgs, &ib)) return 1;
  out = _SimpleFun_otherFun(ia, ib);
  write_modelica_real(outVar, &out.targ1);
  write_modelica_real(outVar, &out.targ2);
  return 0;
}

SimpleFun_mk__rec_rettype _SimpleFun_mk__rec(modelica_real a, modelica_real b)
{
  SimpleFun_mk__rec_rettype tmp1;
  state tmp2;
  struct Try_Rec out;
  tmp2 = get_memory_state();
  out.r1 = (a + b);
  out.r2 = b;
  
  _return:
  tmp1.targ1 = out;
  restore_memory_state(tmp2);
  return tmp1;
}

int in_SimpleFun_mk__rec(type_description * inArgs, type_description * outVar)
{
  modelica_real a;
  modelica_real b;
  SimpleFun_mk__rec_rettype out;
  if(read_modelica_real(&inArgs, &a)) return 1;
  if(read_modelica_real(&inArgs, &b)) return 1;
  out = _SimpleFun_mk__rec(a, b);
  write_modelica_record(outVar, &SimpleFun_Try__Rec__desc, TYPE_DESC_REAL,&(out.targ1.r1),TYPE_DESC_REAL,&(out.targ1.r2),TYPE_DESC_NONE);
  return 0;
}

SimpleFun_recFun_rettype _SimpleFun_recFun(struct Try_Rec tr)
{
  SimpleFun_recFun_rettype tmp1;
  state tmp2;
  modelica_real rr;
  tmp2 = get_memory_state();
  rr = tr.r1;
  
  _return:
  tmp1.targ1 = rr;
  restore_memory_state(tmp2);
  return tmp1;
}

int in_SimpleFun_recFun(type_description * inArgs, type_description * outVar)
{
  struct Try_Rec tr;
  SimpleFun_recFun_rettype out;
  if(read_modelica_record(&inArgs,&(tr.r1),&(tr.r2))) return 1;
  out = _SimpleFun_recFun(tr);
  write_modelica_real(outVar, &out.targ1);
  return 0;
}

/* End Body */

#ifdef __cplusplus
}
#endif
