#ifdef __cplusplus
extern "C" {
#endif
/* header part */
struct #an odd record# {
};
const char* ?noname?__desc__fields[] = {};
struct record_description ?noname?__desc = {
  "?noname?", /* package_record__X */
  "?noname?", /* package.record_X */
  ?noname?__desc__fields
};
struct #an odd record# {
};
const char* ?noname?__desc__fields[] = {};
struct record_description ?noname?__desc = {
  "?noname?", /* package_record__X */
  "?noname?", /* package.record_X */
  ?noname?__desc__fields
};
#define SimpleFun_tryFunction_rettype_1 targ1
typedef struct SimpleFun_tryFunction_rettype_s
{
  modelica_real targ1; /* tmp1 */
} SimpleFun_tryFunction_rettype;

DLLExport
SimpleFun_tryFunction_rettype _SimpleFun_tryFunction(modelica_real a);

DLLExport
int in_SimpleFun_tryFunction(type_description * inArgs, type_description * outVar);
struct #an odd record# {
};
const char* ?noname?__desc__fields[] = {};
struct record_description ?noname?__desc = {
  "?noname?", /* package_record__X */
  "?noname?", /* package.record_X */
  ?noname?__desc__fields
};
struct #an odd record# {
};
const char* ?noname?__desc__fields[] = {};
struct record_description ?noname?__desc = {
  "?noname?", /* package_record__X */
  "?noname?", /* package.record_X */
  ?noname?__desc__fields
};
struct #an odd record# {
};
const char* ?noname?__desc__fields[] = {};
struct record_description ?noname?__desc = {
  "?noname?", /* package_record__X */
  "?noname?", /* package.record_X */
  ?noname?__desc__fields
};
struct #an odd record# {
};
const char* ?noname?__desc__fields[] = {};
struct record_description ?noname?__desc = {
  "?noname?", /* package_record__X */
  "?noname?", /* package.record_X */
  ?noname?__desc__fields
};
struct #an odd record# {
};
const char* ?noname?__desc__fields[] = {};
struct record_description ?noname?__desc = {
  "?noname?", /* package_record__X */
  "?noname?", /* package.record_X */
  ?noname?__desc__fields
};
#define SimpleFun_otherFun_rettype_1 targ1
#define SimpleFun_otherFun_rettype_2 targ2
typedef struct SimpleFun_otherFun_rettype_s
{
  modelica_real targ1; /* yy */
  modelica_real targ2; /* xx */
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
struct #an odd record# {
};
const char* ?noname?__desc__fields[] = {};
struct record_description ?noname?__desc = {
  "?noname?", /* package_record__X */
  "?noname?", /* package.record_X */
  ?noname?__desc__fields
};
struct #an odd record# {
};
const char* ?noname?__desc__fields[] = {};
struct record_description ?noname?__desc = {
  "?noname?", /* package_record__X */
  "?noname?", /* package.record_X */
  ?noname?__desc__fields
};
#define SimpleFun_mk__rec_rettype_1 targ1
typedef struct SimpleFun_mk__rec_rettype_s
{
   targ1; /* out */
} SimpleFun_mk__rec_rettype;

DLLExport
SimpleFun_mk__rec_rettype _SimpleFun_mk__rec(modelica_real a, modelica_real b);

DLLExport
int in_SimpleFun_mk__rec(type_description * inArgs, type_description * outVar);
struct #an odd record# {
};
const char* ?noname?__desc__fields[] = {};
struct record_description ?noname?__desc = {
  "?noname?", /* package_record__X */
  "?noname?", /* package.record_X */
  ?noname?__desc__fields
};
#define SimpleFun_recFun_rettype_1 targ1
typedef struct SimpleFun_recFun_rettype_s
{
  modelica_real targ1; /* rr */
} SimpleFun_recFun_rettype;

DLLExport
SimpleFun_recFun_rettype _SimpleFun_recFun( tr);

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
  tmp1 = (10.0 * (modelica_integer)a);
  
  _return:
  tmp1.targ1 = tmp1;
  restore_memory_state(tmp2);
  return tmp1;
}
SimpleFun_otherFun_rettype _SimpleFun_otherFun(modelica_real ia, modelica_real ib)
{
  SimpleFun_otherFun_rettype tmp1;
  state tmp2;
  modelica_real yy;
  modelica_real xx;
  modelica_real s;
  state tmp3;
   tmp5;
   tmp6;
   tmp7;
  modelica_string tmp8;
  modelica_string tmp9;
  modelica_string tmp10;
  state tmp11;
   tmp13;
   tmp14;
   tmp15;
  modelica_string tmp16;
  modelica_boolean tmp17;
  modelica_string tmp18;
  tmp2 = get_memory_state();
  s = ((modelica_int)0);
  tmp5 = 1; tmp6 = (1); tmp7 = 10;
  {
   i;
  
    for (i = tmp5; in_range_integer(i, tmp5, tmp7); i += tmp6) {
      tmp3 = get_memory_state();
      cat_modelica_string(&tmp8,&(modelica_integer)s,&((modelica_integer)ia * ((modelica_int)(modelica_integer)i)));
      s = tmp8;
      restore_memory_state(tmp3);
    }
  } /*end for*/
  cat_modelica_string(&tmp9,&(modelica_integer)ib,&(modelica_integer)s);
  cat_modelica_string(&tmp10,&(10.0 * (modelica_integer)ia),&tmp9);
  yy = tmp10;
  tmp13 = 1; tmp14 = (1); tmp15 = 10;
  {
   i;
  
    for (i = tmp13; in_range_integer(i, tmp13, tmp15); i += tmp14) {
      tmp11 = get_memory_state();
      cat_modelica_string(&tmp16,&(modelica_integer)s,&((modelica_integer)ia * ((modelica_int)(modelica_integer)i)));
      s = tmp16;
      restore_memory_state(tmp11);
    }
  } /*end for*/
  tmp17 = ((modelica_integer)yy && !10.0);
  if(tmp17) {
    cat_modelica_string(&tmp18,&4.0,&(modelica_integer)s);
  }
  else {
  }
  s = ((tmp17)?tmp18:((modelica_integer)s - 2.0));
  xx = ((modelica_integer)yy / (modelica_integer)s);
  
  _return:
  tmp1.targ1 = yy;
  tmp1.targ2 = xx;
  restore_memory_state(tmp2);
  return tmp1;
}
SimpleFun_mk__rec_rettype _SimpleFun_mk__rec(modelica_real a, modelica_real b)
{
  SimpleFun_mk__rec_rettype tmp1;
  state tmp2;
   out;
  modelica_string tmp3;
  tmp2 = get_memory_state();
  cat_modelica_string(&tmp3,&(modelica_integer)a,&(modelica_integer)b);
  out.r1 = tmp3;
  out.r2 = (modelica_integer)b;
  
  _return:
  tmp1.targ1 = out;
  restore_memory_state(tmp2);
  return tmp1;
}
SimpleFun_recFun_rettype _SimpleFun_recFun( tr)
{
  SimpleFun_recFun_rettype tmp1;
  state tmp2;
  modelica_real rr;
  tmp2 = get_memory_state();
  rr = (modelica_integer)tr.(modelica_integer)r1;
  
  _return:
  tmp1.targ1 = rr;
  restore_memory_state(tmp2);
  return tmp1;
}
/* End Body */

#ifdef __cplusplus
}
#endif

