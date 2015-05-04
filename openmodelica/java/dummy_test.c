#include "meta_modelica.h"
#include "java_interface.h"

/* Used to test MetaModelica types that the compiler won't create properly yet */

int main(int argc, char** argv)
{
  jobject obj;
  JNIEnv *env;
  jmethodID mid;
  jclass cls;
  void *mmc_rec, *mmc_tup, *mmc_opt, *mmc_lst;
  struct record_description rec_desc;
  const char* fieldNames[2];
  jdouble dbl;
  printf("This is a dummy test of the external Java interface\n");
  printf("We will test all possible input types and simply print the value\n");
  fflush(stdout);
  env = getJavaEnv();
  getJavaMethod("JavaExt/DummyTest", "(Lorg/openmodelica/ModelicaObject;)V", env, &cls, &mid);
  obj = NewJavaInteger(env, 157);
  (*env)->CallStaticVoidMethod(env, cls, mid, obj);
  dbl = 15.7;
  obj = NewJavaDouble(env, dbl);
  (*env)->CallStaticVoidMethod(env, cls, mid, obj);
  obj = NewJavaBoolean(env, JNI_FALSE);
  (*env)->CallStaticVoidMethod(env, cls, mid, obj);
  obj = NewJavaString(env, "OpenModelica");
  (*env)->CallStaticVoidMethod(env, cls, mid, obj);

  /* MMC Types Init */
  rec_desc.name = "dummy";
  rec_desc.path = "dummy";
  fieldNames[0] = "field1";
  fieldNames[1] = "field2";
  rec_desc.fieldNames = fieldNames;
  mmc_rec = mmc_mk_box3(4, &rec_desc, (void*) mmc_mk_rcon(2.5), (void*) mmc_mk_icon(12));
  mmc_lst = mmc_mk_cons(mmc_rec, mmc_mk_nil());
  mmc_opt = mmc_mk_some(mmc_lst);
  mmc_tup = mmc_mk_box2(0, (void*) mmc_mk_icon(4), (void*) mmc_mk_scon("3.X"));
  /* MMC Types */
  #define mmc_call(X) {obj = mmc_to_jobject(env, X);\
  (*env)->CallStaticVoidMethod(env, cls, mid, obj);}
  mmc_call(mmc_rec);
  mmc_call(mmc_opt);
  mmc_call(mmc_lst);
  mmc_call(mmc_tup);
  mmc_call(mmc_mk_none());
  mmc_call(mmc_mk_nil());
}
