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


#if defined(__MINGW32__) || defined(_MSC_VER) /* Windows/MinGW */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#define MAXPATHLEN 1024
#include <winreg.h>
#include <winerror.h>

#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "java_interface.h"

typedef __declspec(dllimport) jint (__stdcall * GetCreatedJavaVMsFunc)(JavaVM **, jsize, jsize *);
typedef __declspec(dllimport) jint (__stdcall * CreateJavaVMFunc)(JavaVM**,void**,void*);

#else /* UNIX */

#include <unistd.h>
#include <dlfcn.h>

#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "java_interface.h"

typedef jint (*GetCreatedJavaVMsFunc)(JavaVM **, jsize, jsize *);
typedef jint (*CreateJavaVMFunc)(JavaVM**,void**,void*);

#endif

const char* JAVA_MODELICA_ARRAY   = "org/openmodelica/ModelicaArray";
const char* JAVA_MODELICA_INTEGER = "org/openmodelica/ModelicaInteger";
const char* JAVA_MODELICA_REAL    = "org/openmodelica/ModelicaReal";
const char* JAVA_MODELICA_BOOLEAN = "org/openmodelica/ModelicaBoolean";
const char* JAVA_MODELICA_STRING  = "org/openmodelica/ModelicaString";
const char* JAVA_MODELICA_RECORD  = "org/openmodelica/ModelicaRecord";
const char* JAVA_MODELICA_OMCRECORD  = "org/openmodelica/OMCModelicaRecord";
const char* JAVA_MODELICA_TUPLE   = "org/openmodelica/ModelicaTuple";
const char* JAVA_MODELICA_OPTION  = "org/openmodelica/ModelicaOption";
char* classPath;

int inside_exception = 0;

GetCreatedJavaVMsFunc OMC_GetCreatedJavaVMs = NULL;
CreateJavaVMFunc OMC_CreateJavaVM = NULL;


#if defined(__MINGW32__) || defined(_MSC_VER) /* Windows/MinGW */
/* Windows Dynamic Loading - NOT TESTED IF IT EVEN COMPILES */

int GetStringFromWindowsRegistry(HKEY key, const char *name, char *buf, int buf_length)
{
  DWORD type, size;
  if (RegQueryValueEx(key, name, 0, &type, 0, &size) == ERROR_SUCCESS) {
    if (type == REG_SZ && (size < (unsigned int)buf_length)) {
      /* The key is a string with ok length */
      if (RegQueryValueEx(key, name, 0, 0, (unsigned char*)buf, &size) == 0) {
        return 0;
      }
    }
  }
  return 1;
}

int GetRegistryJavaHome(char *java_home, int java_home_length)
{
  HKEY key, curver_key;
  char version[MAXPATHLEN];

  if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, "Software\\JavaSoft\\Java Runtime Environment", 0, KEY_READ, &key) != 0) {
    return 1;
  }

  if (GetStringFromWindowsRegistry(key, "CurrentVersion", version, sizeof(version))) {
    RegCloseKey(key);
    return 1;
  }

  if (RegOpenKeyEx(key, version, 0, KEY_READ, &curver_key) != 0) {
    RegCloseKey(key);
    return 1;
  }

  if (GetStringFromWindowsRegistry(curver_key, "JavaHome", java_home, java_home_length)) {
    RegCloseKey(key);
    RegCloseKey(curver_key);
    return 1;
  }

  RegCloseKey(key);
  RegCloseKey(curver_key);
  return 0;
}

HINSTANCE
tryToLoadJavaHome(const char* java_home) {
  char* vmlibpath;
  int i, java_home_length;
  HINSTANCE libVM = NULL;
#define NUM_PATHS 2
  const char* possiblePaths[NUM_PATHS] = {
      "%s\\bin\\client\\jvm.dll",
      "%s\\bin\\server\\jvm.dll"
  };
  if (java_home == NULL)
    return NULL;
  java_home_length = strlen(java_home);
  vmlibpath = malloc(java_home_length+500);
  for (i=0; i<NUM_PATHS && libVM == NULL; i++) {
    sprintf(vmlibpath, possiblePaths[i], java_home);
    libVM = LoadLibrary(vmlibpath);
    /* fprintf(stderr, "Tried to load %s: %s\n", vmlibpath, libVM == NULL ? "fail" : "success"); */
  }
  free(vmlibpath);
  return libVM;
}

void loadJNI()
{
  HINSTANCE libVM = NULL;
  char java_home_registry[MAXPATHLEN];
  char* java_home_env;
  static int java_init = 0;
  java_home_registry[0] = '\0';

  if (java_init == 0) {
    java_init = 1;
    java_home_env = getenv("JAVA_HOME");

    libVM = tryToLoadJavaHome(java_home_env);
    if (libVM == NULL && 0 == GetRegistryJavaHome(java_home_registry, MAXPATHLEN)) {
      libVM = tryToLoadJavaHome(java_home_registry);
    }

    if (libVM == NULL) {
      fprintf(stderr, "Failed to dynamically load JVM\nEnvironment JAVA_HOME = '%s'\nWindows Registry JAVA_HOME = '%s'\n", java_home_env, java_home_registry);
      exit(EXIT_CODE_JAVA_ERROR);
    }

    OMC_GetCreatedJavaVMs = (GetCreatedJavaVMsFunc) GetProcAddress(libVM, "JNI_GetCreatedJavaVMs");
    if (OMC_GetCreatedJavaVMs == NULL) {
      fprintf(stderr, "GetProcAddress(JNI_GetCreatedJavaVMs) failed\n");
      exit(EXIT_CODE_JAVA_ERROR);
    }

    OMC_CreateJavaVM = (CreateJavaVMFunc) GetProcAddress(libVM, "JNI_CreateJavaVM");
    if (OMC_CreateJavaVM == NULL) {
      fprintf(stderr, "GetProcAddress(JNI_CreateJavaVM)  failed\n");
      exit(EXIT_CODE_JAVA_ERROR);
    }
  }
}

#else /* UNIX dynamic loading */

void*
tryToLoadJavaHome(const char* java_home) {
  char* vmlibpath;
  int i, java_home_length;
  void *libVM = NULL;
#define NUM_PATHS 6
  const char* possiblePaths[NUM_PATHS] = {
      "%s/jre/lib/i386/client/libjvm.so",
      "%s/jre/lib/i386/server/libjvm.so",
      "%s/jre/lib/amd64/client/libjvm.so",
      "%s/jre/lib/amd64/server/libjvm.so",
      "%s/jre/lib/ppc/client/libjvm.so",
      "%s/jre/lib/ppc/server/libjvm.so"
  };
  if (java_home == NULL)
    return NULL;
  java_home_length = strlen(java_home);
  vmlibpath = malloc(java_home_length+500);
  for (i=0; i<NUM_PATHS && libVM == NULL; i++) {
    sprintf(vmlibpath, possiblePaths[i], java_home);
    libVM = dlopen(vmlibpath, RTLD_LAZY);
  }
  free(vmlibpath);
  return libVM;
}

void loadJNI()
{
  void *libVM = NULL;
  static int java_init = 0;
  char* java_home;
  const char* default_java_home = "/usr/lib/jvm/default-java/";

  if (java_init == 0) {
    java_init = 1;
    java_home = getenv("JAVA_HOME");
    libVM = tryToLoadJavaHome(java_home);
    libVM = libVM != NULL ? libVM : tryToLoadJavaHome(default_java_home);

    if (libVM == NULL) {
      fprintf(stderr, "Failed to dynamically load JVM\nEnvironment JAVA_HOME = '%s'\nDefault JAVA_HOME '%s'\n", java_home, default_java_home);
      exit(EXIT_CODE_JAVA_ERROR);
    }

    /*
     * Will produce compiler warnings because data pointers are not function pointers:
     * http://www.opengroup.org/onlinepubs/009695399/functions/dlsym.html
     */
    if (libVM == NULL) {
      fprintf(stderr, "dlopen failed: %s\n", dlerror());
      exit(EXIT_CODE_JAVA_ERROR);
    }
    *(void **) (&OMC_CreateJavaVM) = dlsym(libVM, "JNI_CreateJavaVM");
    if (OMC_CreateJavaVM == NULL) {
      fprintf(stderr, "dlsym(JNI_CreateJavaVM) failed: %s\n", dlerror());
      exit(EXIT_CODE_JAVA_ERROR);
    }
    *(void **) (&OMC_GetCreatedJavaVMs) = dlsym(libVM, "JNI_GetCreatedJavaVMs");
    if (OMC_GetCreatedJavaVMs == NULL) {
      fprintf(stderr, "dlsym(JNI_GetCreatedJavaVMs) failed: %s\n", dlerror());
      exit(EXIT_CODE_JAVA_ERROR);
    }
  }
}
#endif



/* Should work for multi-threaded applications */
JNIEnv* getJavaEnv()
{
  jint res;
  JavaVM *jvm = NULL;
  JNIEnv *env = NULL;
  jsize nVMs = 0;
  #if defined(__MINGW32__) || defined(_MSC_VER) /* Windows/MinGW */
  const char* classpathFormatString = "-Djava.class.path=%s\\share\\java\\modelica_java.jar;%s\\share\\java\\antlr-3.1.3.jar;%s";
  #else
  const char* classpathFormatString = "-Djava.class.path=%s/share/java/modelica_java.jar:%s/share/java/antlr-3.1.3.jar:%s";
  #endif
  char* openmodelicahome;
  char* classpathEnv;
  JavaVMInitArgs vm_args;
  JavaVMOption options[3];
  long classPathIx = 0;
  long classPathLen;

  loadJNI();

  if (OMC_GetCreatedJavaVMs(&jvm, 1, &nVMs)) {
    fprintf(stderr, "JNI_GetCreatedJavaVMs returned error\n");
    exit(EXIT_CODE_JAVA_ERROR);
  }

  if (nVMs == 1) {
    if ((*jvm)->AttachCurrentThread(jvm, (void **)&env, NULL)) {
      fprintf(stderr, "jvm->AttachCurrentThread returned error\n");
      return NULL;
    }
    return env;
  }

  openmodelicahome = getenv("OPENMODELICAHOME");
  if (openmodelicahome == NULL) {
    fprintf(stderr, "getenv(OPENMODELICAHOME) failed - Java subsystem can't find the Java runtime...\n");
    exit(EXIT_CODE_JAVA_ERROR);
  }
  init_modelica_string(&openmodelicahome, openmodelicahome);

  classpathEnv = getenv("CLASSPATH");
  if (classpathEnv == NULL)
    classpathEnv = "";

  classPathLen = strlen(classpathFormatString) + 2*strlen(openmodelicahome) + strlen(classpathEnv) + 100;
  classPath = malloc(classPathLen);
  if (classPath == NULL) {
    fprintf(stderr, "%s:%d malloc failed\n", __FILE__, __LINE__);
    exit(EXIT_CODE_JAVA_ERROR);
  }

  classPathIx = sprintf(classPath, classpathFormatString, openmodelicahome, openmodelicahome, classpathEnv);
  classPath[classPathIx] = '\0';
  free_modelica_string(&openmodelicahome);

  #if 1
  options[0].optionString = classPath;
  vm_args.nOptions = 1;
  #else
  /* For debugging */
  options[0].optionString = classPath;
  options[1].optionString = "-verbose:jni";
  options[2].optionString = "-Xcheck:jni";
  vm_args.nOptions = 3;
  fprintf(stderr, "options[0] %s\noptions[1] %s\noptions[2] %s\n",
      options[0].optionString,
      options[1].optionString,
      options[2].optionString);
  #endif

  vm_args.version = JNI_VERSION_1_4;
  vm_args.options = options;
  vm_args.ignoreUnrecognized = JNI_TRUE;
  /* Create the Java VM */
  res = OMC_CreateJavaVM(&jvm, (void**)&env, &vm_args);

  if (res < 0) {
    jvm = NULL;
    env = NULL;

    fprintf(stderr, "%s:%d JNI_CreateJavaVM failed\n", __FILE__, __LINE__);
    exit(EXIT_CODE_JAVA_ERROR);
  }

  /* Check that the system works */
  (*env)->FindClass(env, "java/lang/String");
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->FindClass(env, JAVA_MODELICA_STRING);
  CHECK_FOR_JAVA_EXCEPTION(env);

  return env;
}

jobject NewJavaArray(JNIEnv* env) {
  jobject res;
  jmethodID cid;
  const char* className = JAVA_MODELICA_ARRAY;
  const char* sig = "()V";
  jclass cls = (*env)->FindClass(env, className);

  CHECK_FOR_JAVA_EXCEPTION(env);

  cid = (*env)->GetMethodID(env, cls, "<init>", sig);
  CHECK_FOR_JAVA_EXCEPTION(env);
  res = (*env)->NewObject(env, cls, cid);
  (*env)->DeleteLocalRef(env, cls);

  return res;
}

void JavaArrayAdd(JNIEnv* env, jobject arr, jobject obj) {
  const char* methodName = "add";
  const char* sig = "(Ljava/lang/Object;)Z";
  jclass cls = (*env)->GetObjectClass(env,arr);
  jmethodID mid = (*env)->GetMethodID(env, cls, methodName, sig);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->CallBooleanMethod(env, arr, mid, obj);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->DeleteLocalRef(env, cls);
}

jobject JavaArrayGet(JNIEnv* env, jobject arr, jint ix) {
  jobject res;
  const char* methodName = "get";
  const char* sig = "(I)Ljava/lang/Object;";
  jclass cls = (*env)->GetObjectClass(env,arr);
  jmethodID mid = (*env)->GetMethodID(env, cls, methodName, sig);
  CHECK_FOR_JAVA_EXCEPTION(env);
  res = (*env)->CallObjectMethod(env, arr, mid, ix);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->DeleteLocalRef(env, cls);
  return res;
}

void MakeJavaMultiDimArray(JNIEnv* env, jobject jarr, int numDim, jint firstDim, ...) {
  jint *dims = malloc(numDim*sizeof(jint));
  int i;
  va_list va;
  jobject jdims;
  jmethodID mid;
  const char* className = JAVA_MODELICA_ARRAY;
  const char* methodName = "setDims";
  const char* sig = "(I[I)V";

  jclass cls = (*env)->FindClass(env, className);

  CHECK_FOR_JAVA_EXCEPTION(env);

  mid = (*env)->GetMethodID(env, cls, methodName, sig);
  CHECK_FOR_JAVA_EXCEPTION(env);

  va_start(va, firstDim);
  for (i=0; i<numDim-1; i++) {
    dims[i] = va_arg(va, jint);
  }
  va_end(va);

  jdims = (*env)->NewIntArray(env, numDim-1);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->SetIntArrayRegion(env, jdims, 0, numDim-1, dims);
  CHECK_FOR_JAVA_EXCEPTION(env);

  (*env)->CallVoidMethod(env, jarr, mid, firstDim, jdims);

  (*env)->DeleteLocalRef(env, jdims);
  (*env)->DeleteLocalRef(env, cls);
  free(dims);
}

void FlattenJavaMultiDimArray(JNIEnv* env, jobject jarr) {
  const char* methodName = "flattenModelicaArray";
  const char* sig = "()V";
  jclass cls = (*env)->GetObjectClass(env,jarr);
  jmethodID mid = (*env)->GetMethodID(env, cls, methodName, sig);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->CallVoidMethod(env, jarr, mid);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->DeleteLocalRef(env, cls);
}

jobject NewFlatJavaIntegerArray(JNIEnv* env, modelica_integer* base, int num)
{
  jobject jarr = NewJavaArray(env);
  int i;
  for (i=0; i<num; i++) {
    jobject o = NewJavaInteger(env, base[i]);
    JavaArrayAdd(env, jarr, o);
    (*env)->DeleteLocalRef(env, o);
  }
  return jarr;
}

jobject NewFlatJavaDoubleArray(JNIEnv* env, modelica_real* base, int num)
{
  jobject jarr = NewJavaArray(env);
    int i;
    for (i=0; i<num; i++) {
      jobject o = NewJavaDouble(env, base[i]);
      JavaArrayAdd(env, jarr, o);
      (*env)->DeleteLocalRef(env, o);
    }
    return jarr;
}

jobject NewFlatJavaStringArray(JNIEnv* env, modelica_string* base, int num)
{
  jobject jarr = NewJavaArray(env);
  int i;
  for (i=0; i<num; i++) {
    jobject o = NewJavaString(env, base[i]);
    JavaArrayAdd(env, jarr, o);
    (*env)->DeleteLocalRef(env, o);
  }
  return jarr;
}

jobject NewFlatJavaBooleanArray(JNIEnv* env, modelica_boolean* base, int num)
{
  jobject jarr = NewJavaArray(env);
  int i;
  for (i=0; i<num; i++) {
    jobject o = NewJavaBoolean(env, base[i]);
    JavaArrayAdd(env, jarr, o);
    (*env)->DeleteLocalRef(env, o);
  }
  return jarr;
}

void GetFlatJavaIntegerArray(JNIEnv* env, jobject jarr, modelica_integer* base, int num)
{
  int i;
  for (i=0; i<num; i++) {
    base[i] = GetJavaInteger(env, JavaArrayGet(env,jarr,i));
  }
}

void GetFlatJavaDoubleArray(JNIEnv* env, jobject jarr, modelica_real* base, int num)
{
  int i;
  for (i=0; i<num; i++) {
    base[i] = GetJavaDouble(env, JavaArrayGet(env,jarr,i));
  }
}

void GetFlatJavaBooleanArray(JNIEnv* env, jobject jarr, modelica_boolean* base, int num)
{
  int i;
  for (i=0; i<num; i++) {
    base[i] = GetJavaBoolean(env, JavaArrayGet(env,jarr,i));
  }
}

void GetFlatJavaStringArray(JNIEnv* env, jobject jarr, modelica_string* base, int num)
{
  int i;
  for (i=0; i<num; i++) {
    base[i] = GetJavaString(env, JavaArrayGet(env,jarr,i));
  }
}

jobject NewJavaRecord(JNIEnv* env, const char* recordName, int ctor_index, jobject map)
{
  jobject res, tmp;
  jmethodID cid;
  const char* className = JAVA_MODELICA_OMCRECORD;
  const char* sig = "(ILjava/lang/String;Ljava/util/Map;)V";
  jclass cls = (*env)->FindClass(env, className);

  CHECK_FOR_JAVA_EXCEPTION(env);

  cid = (*env)->GetMethodID(env, cls, "<init>", sig);
  CHECK_FOR_JAVA_EXCEPTION(env);
  tmp = (*env)->NewStringUTF(env,recordName);
  CHECK_FOR_JAVA_EXCEPTION(env);
  res = (*env)->NewObject(env, cls, cid, ctor_index, tmp, map);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->DeleteLocalRef(env, cls);
  (*env)->DeleteLocalRef(env, tmp);

  return res;
}

jobject NewJavaTuple(JNIEnv* env, jobject arr)
{
  jobject res;
  jmethodID cid;
  const char* className = JAVA_MODELICA_TUPLE;
  const char* sig = "(Ljava/util/List;)V";
  jclass cls = (*env)->FindClass(env, className);

  CHECK_FOR_JAVA_EXCEPTION(env);

  cid = (*env)->GetMethodID(env, cls, "<init>", sig);
  CHECK_FOR_JAVA_EXCEPTION(env);
  res = (*env)->NewObject(env, cls, cid, arr);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->DeleteLocalRef(env, cls);

  return res;
}

jobject NewJavaMap(JNIEnv* env)
{
  jobject res;
  jmethodID cid;
  const char* className = "java/util/LinkedHashMap";

  jclass cls = (*env)->FindClass(env, className);
  CHECK_FOR_JAVA_EXCEPTION(env);

  cid = (*env)->GetMethodID(env, cls, "<init>", "()V");
  CHECK_FOR_JAVA_EXCEPTION(env);

  res = (*env)->NewObject(env, cls, cid);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->DeleteLocalRef(env, cls);

  return res;
}

jobject NewJavaInteger(JNIEnv* env, jint value)
{
  const char* className = JAVA_MODELICA_INTEGER;
  const char* sig = "(I)V";
  jobject res;
  jmethodID cid;

  jclass cls = (*env)->FindClass(env, className);
  CHECK_FOR_JAVA_EXCEPTION(env);

  cid = (*env)->GetMethodID(env, cls, "<init>", sig);
  CHECK_FOR_JAVA_EXCEPTION(env);

  res = (*env)->NewObject(env, cls, cid, value);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->DeleteLocalRef(env, cls);

  return res;
}

jobject NewJavaDouble(JNIEnv* env, jdouble value)
{
  const char* className = JAVA_MODELICA_REAL;
  const char* sig = "(D)V";
  jobject res;
  jmethodID cid;

  jclass cls = (*env)->FindClass(env, className);
  CHECK_FOR_JAVA_EXCEPTION(env);

  cid = (*env)->GetMethodID(env, cls, "<init>", sig);
  CHECK_FOR_JAVA_EXCEPTION(env);

  res = (*env)->NewObject(env, cls, cid, value);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->DeleteLocalRef(env, cls);

  return res;
}

jobject NewJavaBoolean(JNIEnv* env, jboolean value)
{
  const char* className = JAVA_MODELICA_BOOLEAN;
  const char* sig = "(Z)V";
  jobject res;
  jmethodID cid;

  jclass cls = (*env)->FindClass(env, className);
  CHECK_FOR_JAVA_EXCEPTION(env);

  cid = (*env)->GetMethodID(env, cls, "<init>", sig);
  CHECK_FOR_JAVA_EXCEPTION(env);

  res = (*env)->NewObject(env, cls, cid, value);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->DeleteLocalRef(env, cls);

  return res;
}

jobject NewJavaString(JNIEnv* env, const char* value)
{
  const char* className = JAVA_MODELICA_STRING;
  const char* sig = "(Ljava/lang/String;Z)V";
  jobject res, tmp;
  jmethodID cid;
  jclass cls = (*env)->FindClass(env, className);

  CHECK_FOR_JAVA_EXCEPTION(env);

  cid = (*env)->GetMethodID(env, cls, "<init>", sig);
  CHECK_FOR_JAVA_EXCEPTION(env);

  tmp = value == NULL ? NULL : (*env)->NewStringUTF(env,value);
  CHECK_FOR_JAVA_EXCEPTION(env);
  res = (*env)->NewObject(env, cls, cid, tmp, JNI_TRUE);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->DeleteLocalRef(env, cls);

  return res;
}

jobject NewJavaOption(JNIEnv* env, jobject value)
{
  const char* className = JAVA_MODELICA_OPTION;
  const char* sig = "(Lorg/openmodelica/ModelicaObject;)V";
  jobject res;
  jmethodID cid;

  jclass cls = (*env)->FindClass(env, className);
  CHECK_FOR_JAVA_EXCEPTION(env);
  
  cid = (*env)->GetMethodID(env, cls, "<init>", sig);
  CHECK_FOR_JAVA_EXCEPTION(env);
  
  res = (*env)->NewObject(env, cls, cid, value);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->DeleteLocalRef(env, cls);
  
  return res;
}

jobject mmc_to_jobject(JNIEnv* env, void* mmc)
{
  mmc_uint_t hdr;
  int numslots;
  unsigned ctor;
  int i;

  if (0 == ((long)mmc & 1)) /* INTEGER */
    return NewJavaInteger(env,MMC_UNTAGFIXNUM(mmc));
  hdr = MMC_GETHDR(mmc);
  if (hdr == MMC_REALHDR) /* REAL */
    return NewJavaDouble(env,*((jdouble*)MMC_REALDATA(mmc)));
  if (MMC_HDRISSTRING(hdr)) /* STRING */
    return NewJavaString(env,MMC_STRINGDATA(mmc));
  if (hdr == MMC_NILHDR) /* Empty list; Tested, but not in OMC. */ {
    return NewJavaArray(env);
  }
  
  numslots = MMC_HDRSLOTS(hdr);
  ctor = 255 & (hdr >> 2);

  if (numslots>0 && ctor > 1) { /* RECORD */
    jobject rec_map;
    struct record_description* desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),1));    
    rec_map = NewJavaMap(env);
    if (numslots == 1 && desc == NULL) {
      return NewJavaRecord(env, "***output record***", -2, rec_map);
    }

    for (i=1; i<numslots; i++) {
      jobject o = mmc_to_jobject(env, MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),i+1)));
      AddObjectToJavaMap(env, rec_map, desc->fieldNames[i-1], o);
    }
    
    return NewJavaRecord(env, desc->name, ctor-3, rec_map);
  }

  if (numslots>0 && ctor == 0) { /* TUPLE; Tested, but not in OMC. */
    jobject arr = NewJavaArray(env);
    for (i=1; i<=numslots; i++) {
      jobject o = mmc_to_jobject(env, MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),i)));
      JavaArrayAdd(env, arr, o);
    }
    return NewJavaTuple(env, arr);
  }

  if (numslots==0 && ctor==1) /* NONE(); Tested, but not in OMC. */ {
    return NewJavaOption(env, NULL);
  }

  if (numslots==1 && ctor==1) /* SOME(x); Tested, but not in OMC. */ {
    return NewJavaOption(env, mmc_to_jobject(env, MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmc),1))));
  }

  if (numslots==2 && ctor==1) { /* CONS-PAIR; Tested, but not in OMC. */
    jobject arr = NewJavaArray(env);    
    while (!MMC_NILTEST(mmc)) {
      JavaArrayAdd(env, arr, mmc_to_jobject(env, MMC_CAR(mmc)));
      mmc = MMC_CDR(mmc);
    }
    return arr;
  }
  
  fprintf(stderr, "%s:%s: %d slots; ctor %d - FAILED to detect the type\n",
          __FILE__, __FUNCTION__, numslots, ctor);
  exit(EXIT_CODE_JAVA_ERROR);
}

char* jobjectToString(JNIEnv* env, jobject obj)
{
  jmethodID mid;
  jobject jstr;
  jclass cls;
  cls = (*env)->GetObjectClass(env, obj);
  CHECK_FOR_JAVA_EXCEPTION(env);
  mid = (*env)->GetMethodID(env, cls, "toString", "()Ljava/lang/String;");
  CHECK_FOR_JAVA_EXCEPTION(env);
  jstr = (*env)->CallObjectMethod(env, obj, mid);
  CHECK_FOR_JAVA_EXCEPTION(env);
  return copyJstring(env, jstr);
}

char* copyJstring(JNIEnv* env, jobject jstr)
{
  const char* str_tmp;
  char* str;
  if (jstr == NULL) {
    fprintf(stderr, "%s: Java String was NULL\n", __FUNCTION__);
    exit(EXIT_CODE_JAVA_ERROR);
  }
  CHECK_FOR_JAVA_EXCEPTION(env);
  str_tmp = (*env)->GetStringUTFChars(env, jstr, NULL);
  CHECK_FOR_JAVA_EXCEPTION(env);
  if (str_tmp == NULL) {
    fprintf(stderr, "%s: GetStringUTFChars failed\n", __FUNCTION__);
    exit(EXIT_CODE_JAVA_ERROR);
  }

  init_modelica_string(&str, str_tmp);
  (*env)->ReleaseStringUTFChars(env, jstr, str_tmp);
  return str;
}


void* jobject_to_mmc_record(JNIEnv* env, jobject record)
{
  jmethodID midGetKeys,midToArray,midGetIndex,midRecPath;
  jfieldID fidRecName;
  jclass clsObj;
  jclass clsKeySet;
  jobject keySet, jarrKeys, recordName, recordPath;
  jsize length;
  jint i, ctor_index;
  void** values;
  void* res;
  static jint jobject_to_mmc_record_warning_shown = 0;
  
  struct record_description *rec_desc = malloc(sizeof(struct record_description));
  
  clsObj = (*env)->GetObjectClass(env, record);
  CHECK_FOR_JAVA_EXCEPTION(env);
  /* Copy record names to C strings */
  fidRecName = (*env)->GetFieldID(env, clsObj, "recordName", "Ljava/lang/String;");
  CHECK_FOR_JAVA_EXCEPTION(env);
  recordName = (*env)->GetObjectField(env, record, fidRecName);
  CHECK_FOR_JAVA_EXCEPTION(env);
  midRecPath = (*env)->GetMethodID(env, clsObj, "getRecordPath", "()Ljava/lang/String;");
  CHECK_FOR_JAVA_EXCEPTION(env);
  recordPath = (*env)->CallObjectMethod(env, record, midRecPath);
  CHECK_FOR_JAVA_EXCEPTION(env);
  rec_desc->path=copyJstring(env, recordPath);
  rec_desc->name=copyJstring(env, recordName);
  /* Get the ctor_index */
  midGetIndex = (*env)->GetMethodID(env, clsObj, "get_ctor_index", "()I");
  CHECK_FOR_JAVA_EXCEPTION(env);
  ctor_index = (*env)->CallIntMethod(env, record, midGetIndex);
  CHECK_FOR_JAVA_EXCEPTION(env);
  /* Get the key set */
  midGetKeys = (*env)->GetMethodID(env, clsObj, "keySet", "()Ljava/util/Set;");
  CHECK_FOR_JAVA_EXCEPTION(env);
  keySet = (*env)->CallObjectMethod(env, record, midGetKeys);
  CHECK_FOR_JAVA_EXCEPTION(env);
  clsKeySet = (*env)->GetObjectClass(env, keySet);
  CHECK_FOR_JAVA_EXCEPTION(env);
  midToArray = (*env)->GetMethodID(env, clsKeySet, "toArray", "()[Ljava/lang/Object;");
  CHECK_FOR_JAVA_EXCEPTION(env);
  jarrKeys = (*env)->CallObjectMethod(env, keySet, midToArray);
  CHECK_FOR_JAVA_EXCEPTION(env);
  length = (*env)->GetArrayLength(env, jarrKeys);
  CHECK_FOR_JAVA_EXCEPTION(env);
  /* Alloc and fill data/fieldnames */
  rec_desc->fieldNames = malloc(length*sizeof(char*));
  values = malloc((length+1)*sizeof(void*));
  values[0] = rec_desc;
  for (i=0; i<length; i++) {
    jobject jstr = (*env)->GetObjectArrayElement(env, jarrKeys, i);
    jobject fieldValue;
    CHECK_FOR_JAVA_EXCEPTION(env);
    rec_desc->fieldNames[i] = copyJstring(env, jstr);
    fieldValue = GetObjectFromJavaMap(env, record, rec_desc->fieldNames[i]);
    values[i+1] = jobject_to_mmc(env, fieldValue);
  }

  if (ctor_index == -2 && 0 == jobject_to_mmc_record_warning_shown) {
    char* recStr = jobjectToString(env, record);
    jobject_to_mmc_record_warning_shown = 1;
    printf("Warning: %s:%s:%d\n*** %s\n", __FILE__, __FUNCTION__, __LINE__, recStr);
    printf("*** The record sent from Java does not carry a valid ctor_index value\n");
    printf("*** The field names may not be valid in OMC, but you can still view the structure in the Interactive interface.\n");
    printf("*** The returned record was probably created using new ModelicaRecord(...)\n");
    printf("*** Using the automatically generated interface (org.openmodelica.corba.parser.DefinitionsParser) is preferred.\n");
    printf("*** If you want to remove this warning, inherit from ModelicaRecord and override int get_ctor_index().\n");
    printf("*** Make it return -1 for regular records or >=0 for uniontypes.\n");
    printf("*** The correct value to use for uniontypes can be seen if you run getDefinitions() in the Interactive interface.\n");
    printf("*** This message will only be shown once per object file.\n");
  }
  res = mmc_mk_box_arr(length+1, (ctor_index != -2 ? ctor_index+3 : 2), values);
  free(values);
  return res;
}

void* jobject_to_mmc_int(JNIEnv* env, jobject obj)
{
  return mmc_mk_icon(GetJavaInteger(env, obj));
}

void* jobject_to_mmc_real(JNIEnv* env, jobject obj)
{
  return mmc_mk_rcon(GetJavaDouble(env, obj));
}

void* jobject_to_mmc_bool(JNIEnv* env, jobject obj)
{
  return mmc_mk_icon(GetJavaBoolean(env, obj) != JNI_FALSE ? 1 : 0);
}

void* jobject_to_mmc_string(JNIEnv* env, jobject obj)
{
  return mmc_mk_scon(GetJavaString(env, obj));
}

void* jobject_to_mmc_tuple(JNIEnv* env, jobject obj)
{
  jobject jarr;
  jmethodID mid;
  jclass cls;
  int i, length;
  void** values;
  void* res;
  
  cls = (*env)->GetObjectClass(env, obj);
  CHECK_FOR_JAVA_EXCEPTION(env);
  mid = (*env)->GetMethodID(env, cls, "toArray", "()[Ljava/lang/Object;");
  CHECK_FOR_JAVA_EXCEPTION(env);
  jarr = (*env)->CallObjectMethod(env, obj, mid);
  CHECK_FOR_JAVA_EXCEPTION(env);
  length = (*env)->GetArrayLength(env, jarr);
  
  values = malloc((length)*sizeof(void*));
  for (i=0; i<length; i++) {
    jobject fieldValue = (*env)->GetObjectArrayElement(env, jarr, i);
    values[i] = jobject_to_mmc(env, fieldValue);
  }
  res = mmc_mk_box_arr(length, 0 /* tuple: ctor=0 */, values);
  free(values);
  return res;
}

void* jobject_to_mmc_list(JNIEnv* env, jobject obj)
{
  jobject jarr;
  jmethodID mid;
  jclass cls;
  int i, length;
  void* res;
  
  cls = (*env)->GetObjectClass(env, obj);
  CHECK_FOR_JAVA_EXCEPTION(env);
  mid = (*env)->GetMethodID(env, cls, "toArray", "()[Ljava/lang/Object;");
  CHECK_FOR_JAVA_EXCEPTION(env);
  jarr = (*env)->CallObjectMethod(env, obj, mid);
  CHECK_FOR_JAVA_EXCEPTION(env);
  length = (*env)->GetArrayLength(env, jarr);
  
  res = mmc_mk_nil();
  for (i=0; i<length; i++) {
    /* Copy in reverse order */
    jobject fieldValue = (*env)->GetObjectArrayElement(env, jarr, length-i-1);
    res = mmc_mk_cons(jobject_to_mmc(env, fieldValue), res);
  }
  return res;
}

void* jobject_to_mmc_option(JNIEnv* env, jobject obj)
{
  jobject option;
  jfieldID fid;
  jclass cls;
  
  cls = (*env)->GetObjectClass(env, obj);
  CHECK_FOR_JAVA_EXCEPTION(env);
  fid = (*env)->GetFieldID(env, cls, "o", "Lorg/openmodelica/ModelicaObject;");
  CHECK_FOR_JAVA_EXCEPTION(env);
  option = (*env)->GetObjectField(env, obj, fid);
  CHECK_FOR_JAVA_EXCEPTION(env);
  if (option == NULL)
    return mmc_mk_none();
  return mmc_mk_some(jobject_to_mmc(env, option));
}

#define CALL_IF_INSTANCEOF(env,fn,o,c) { \
  jobject cls = (*env)->FindClass(env, c); \
  CHECK_FOR_JAVA_EXCEPTION(env); \
  if ((*env)->IsInstanceOf(env,o,cls)) \
    return fn(env, o); \
  CHECK_FOR_JAVA_EXCEPTION(env);\
};

void* jobject_to_mmc(JNIEnv* env, jobject o)
{
  CALL_IF_INSTANCEOF(env,jobject_to_mmc_record, o, JAVA_MODELICA_RECORD);
  CALL_IF_INSTANCEOF(env,jobject_to_mmc_int, o, JAVA_MODELICA_INTEGER);
  CALL_IF_INSTANCEOF(env,jobject_to_mmc_real, o, JAVA_MODELICA_REAL);
  CALL_IF_INSTANCEOF(env,jobject_to_mmc_bool, o, JAVA_MODELICA_BOOLEAN);
  CALL_IF_INSTANCEOF(env,jobject_to_mmc_string, o, JAVA_MODELICA_STRING);
  CALL_IF_INSTANCEOF(env,jobject_to_mmc_tuple, o, JAVA_MODELICA_TUPLE);
  CALL_IF_INSTANCEOF(env,jobject_to_mmc_option, o, JAVA_MODELICA_OPTION);
  CALL_IF_INSTANCEOF(env,jobject_to_mmc_list, o, JAVA_MODELICA_ARRAY); /* LIST */
  
  fprintf(stderr, "%s:%s: Failed to parse object: %s\n",
          __FILE__, __FUNCTION__, jobjectToString(env, o));
  exit(EXIT_CODE_JAVA_ERROR);
}

jint GetJavaInteger(JNIEnv* env, jobject obj) {
  jfieldID fid;
  jclass cls = (*env)->GetObjectClass(env, obj);
  jint res;

  fid = (*env)->GetFieldID(env, cls, "i", "I");
  CHECK_FOR_JAVA_EXCEPTION(env);

  res = (*env)->GetIntField(env, obj, fid);
  CHECK_FOR_JAVA_EXCEPTION(env);
  return res;
}


jdouble GetJavaDouble(JNIEnv* env, jobject obj) {
  jfieldID fid;
  jclass cls = (*env)->GetObjectClass(env, obj);
  jdouble res;

  fid = (*env)->GetFieldID(env, cls, "r", "D");
  CHECK_FOR_JAVA_EXCEPTION(env);

  res = (*env)->GetDoubleField(env, obj, fid);
  CHECK_FOR_JAVA_EXCEPTION(env);
  return res;
}

jboolean GetJavaBoolean(JNIEnv* env, jobject obj) {
  jfieldID fid;
  jclass cls = (*env)->GetObjectClass(env, obj);
  jboolean res;

  fid = (*env)->GetFieldID(env, cls, "b", "Z");
  CHECK_FOR_JAVA_EXCEPTION(env);

  res = (*env)->GetBooleanField(env, obj, fid);
  CHECK_FOR_JAVA_EXCEPTION(env);
  return res;
}

char* GetJavaString(JNIEnv* env, jobject obj) {
  jobject jstr;
  jmethodID mid;

  jclass cls = (*env)->GetObjectClass(env, obj);

  mid = (*env)->GetMethodID(env, cls, "toEscapedString", "()Ljava/lang/String;");
  CHECK_FOR_JAVA_EXCEPTION(env);

  jstr = (*env)->CallObjectMethod(env, obj, mid);
  CHECK_FOR_JAVA_EXCEPTION(env);
  return copyJstring(env, jstr);
}

void AddObjectToJavaMap(JNIEnv* env, jobject map, const char* key, jobject value)
{
  const char* sig = "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;";
  const char* methodName = "put";
  jmethodID mid;
  jclass cls;
  jobject keyString;

  cls = (*env)->GetObjectClass(env, map);

  CHECK_FOR_JAVA_EXCEPTION(env);

  mid = (*env)->GetMethodID(env, cls, methodName, sig);
  CHECK_FOR_JAVA_EXCEPTION(env);

  keyString = (*env)->NewStringUTF(env,key);
  CHECK_FOR_JAVA_EXCEPTION(env);
  (*env)->CallObjectMethod(env, map, mid, keyString, value);
  CHECK_FOR_JAVA_EXCEPTION(env);

  (*env)->DeleteLocalRef(env, cls);
  (*env)->DeleteLocalRef(env, keyString);
  (*env)->DeleteLocalRef(env, value);
  return;
}

jobject GetObjectFromJavaMap(JNIEnv* env, jobject map, const char* key) {
  const char* sig = "(Ljava/lang/Object;)Ljava/lang/Object;";
  const char* methodName = "get";
  jmethodID mid;
  jclass cls;
  jobject keyString, res;

  cls = (*env)->GetObjectClass(env, map);
  CHECK_FOR_JAVA_EXCEPTION(env);
  mid = (*env)->GetMethodID(env, cls, methodName, sig);
  CHECK_FOR_JAVA_EXCEPTION(env);

  keyString = (*env)->NewStringUTF(env,key);
  CHECK_FOR_JAVA_EXCEPTION(env);
  res = (*env)->CallObjectMethod(env, map, mid, keyString);
  CHECK_FOR_JAVA_EXCEPTION(env);

  (*env)->DeleteLocalRef(env, cls);
  (*env)->DeleteLocalRef(env, keyString);
  return res;
}

modelica_string GetStackTrace(JNIEnv* env, jobject t)
{
  jmethodID mid;
  jclass cls;
  jstring msg;
  modelica_string res;

  cls = (*env)->FindClass(env, "org/openmodelica/ModelicaHelper");
  CHECK_FOR_JAVA_EXCEPTION(env);
  mid = (*env)->GetStaticMethodID(env, cls, "getStackTrace", "(Ljava/lang/Throwable;)Ljava/lang/String;");
  CHECK_FOR_JAVA_EXCEPTION(env);
  msg = (*env)->CallStaticObjectMethod(env, cls, mid, t);
  res = copyJstring(env, msg);
  
  (*env)->DeleteLocalRef(env, msg);
  (*env)->DeleteLocalRef(env, cls);
  return res;
}

const char* __CheckForJavaException(JNIEnv* env)
{
  jthrowable exc;
  char* res;
  static int inside_exception = 0;

  exc = (*env)->ExceptionOccurred(env);
  if (exc) {
    (*env)->ExceptionClear(env);

    if (inside_exception) {
      return "The exception handler triggered an exception.\nMake sure the java runtime is installed in $OPENMODELICAHOME/share/java/modelica_java.jar\n";
    }
    inside_exception = 1;
    res = GetStackTrace(env, exc);
    inside_exception = 0;

    (*env)->DeleteLocalRef(env, exc);
    return res;
  } else {
    return NULL;
  }
}
