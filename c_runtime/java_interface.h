/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef JAVA_INTERFACE__H
#define JAVA_INTERFACE__H

#include "modelica.h"
#ifdef __cplusplus
/*
 *  JNI C++ and C interfaces are different, but we use the same code for
 * both C++ and C. So __cplusplus has to be undefined for jni.h.
 */
#undef __cplusplus
#include "jni.h"
#define __cplusplus
#else
#include "jni.h"
#endif

#define EXIT_CODE_JAVA_ERROR 17
JNIEnv* getJavaEnv();

/* ModelicaArray<T> -> set firstDim and dims so the Java application can
 * create a ModelicaArray<Mode...> nested array using the unflatten method.
 * This is not done automatically as it takes a lot of extra time if the Java
 * application actually wants a flat array like the external C programs get.
 * These functions destroy the old object and replace the pointer with a fresh one */
void MakeJavaMultiDimArray(JNIEnv* env, jobject jarr, int numDim, jint firstDim, ...);
void FlattenJavaMultiDimArray(JNIEnv* env, jobject jarr);
/* Functions to create a flat array to be accessed in Java */
jobject NewJavaArray(JNIEnv* env);
void    JavaArrayAdd(JNIEnv* env, jobject arr, jobject o);
jobject JavaArrayGet(JNIEnv* env, jobject arr, jint ix);
/* T[n] -> ModelicaArray<T> */
jobject NewFlatJavaIntegerArray(JNIEnv* env, modelica_integer* base, int num);
jobject NewFlatJavaDoubleArray(JNIEnv* env, modelica_real* base, int num);
jobject NewFlatJavaStringArray(JNIEnv* env, modelica_string* base, int num);
jobject NewFlatJavaBooleanArray(JNIEnv* env, modelica_boolean* base, int num);
/* ModelicaArray<T> -> T[n] */
void GetFlatJavaIntegerArray(JNIEnv* env, jobject arr, modelica_integer* base, int num);
void GetFlatJavaDoubleArray(JNIEnv* env, jobject arr, modelica_real* base, int num);
void GetFlatJavaBooleanArray(JNIEnv* env, jobject arr, modelica_boolean* base, int num);
void GetFlatJavaStringArray(JNIEnv* env, jobject arr, modelica_string* base, int num);

/* Pass-Record-by-Map */
jobject NewJavaRecord(JNIEnv* env, const char* recordName, int ctor_index /* -1 record, >= 0 uniontype */, jobject map);
jobject NewJavaMap(JNIEnv* env);
jobject NewJavaInteger(JNIEnv* env, jint value);
jobject NewJavaDouble(JNIEnv* env, jdouble value);
jobject NewJavaBoolean(JNIEnv* env, jboolean value);
jobject NewJavaString(JNIEnv* env, const char* value);
jobject NewJavaTuple(JNIEnv* env, jobject arr);
jobject NewJavaOption(JNIEnv* env, jobject value);
jobject mmc_to_jobject(JNIEnv* env, void* mmc);
void* jobject_to_mmc(JNIEnv* env, jobject o);
jint GetJavaInteger(JNIEnv* env, jobject o);
jdouble GetJavaDouble(JNIEnv* env, jobject o);
jboolean GetJavaBoolean(JNIEnv* env, jobject o);
char* GetJavaString(JNIEnv* env, jobject o);
char* copyJstring(JNIEnv* env, jobject o);
char* jobjectToString(JNIEnv* env, jobject o);
void AddObjectToJavaMap(JNIEnv* env, jobject map, const char* key, jobject value);
jobject GetObjectFromJavaMap(JNIEnv* env, jobject map, const char* key);

const char* __CheckForJavaException(JNIEnv* env);

/* We want to check if it's a simulation, but we can't check for __cplusplus
 * because matchcontinue requires try-catch constructs
*/
/* #ifdef __cplusplus */ #if 0
#define CHECK_FOR_JAVA_EXCEPTION(env) do { \
  const char* msg = __CheckForJavaException(env); \
  if (msg != NULL) { \
    modelTermination=1; \
    throw TerminateSimulationException(string(msg)); \
  } \
} while (0)
#else
/* ModelicaUtilities.h is not available in OpenModelica?
 * Assertions also can't be used in OMC stand-alone functions; only simulations
 * We simply print the exception and abort()
 */
#define CHECK_FOR_JAVA_EXCEPTION(env) do { \
  const char* msg = __CheckForJavaException(env); \
  if (msg != NULL) { \
    fprintf(stderr, "Error: External Java Exception Thrown but can't assert in C-mode\nLocation: %s (%s:%d)\nThe exception message was:\n%s\n", __FUNCTION__, __FILE__, __LINE__, msg); \
    EXIT(EXIT_CODE_JAVA_ERROR); \
  } \
} while (0)
#endif

#endif
