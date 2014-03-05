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

/*
 * adrpo 2007-05-09
 * UNCOMMENT THIS ONLY IF YOU COMPILE OMC IN DEBUG MODE!!!!!
 * #define RML_DEBUG
 */

#if defined(__MINGW32__) || defined(_MSC_VER)
#define NOMINMAX
#define USE_WIN32_UUID
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlwapi.h>
#endif

#include "rml.h"
#include "config.h"
#include "systemimpl.c"
#include "getMemorySize.c"
#include <float.h>
#include <ctype.h>
#include <limits.h>
#include <stdlib.h>
#include "omc_msvc.h"

/* use this one to output messages depending on flags! */
int check_debug_flag(char const* strdata);

/*
#if defined(_MSC_VER)
#define inline __inline
#else // Linux & MinGW
#define inline inline
#endif
*/

RML_BEGIN_LABEL(System__regularFileExists)
{
  char* str = RML_STRINGDATA(rmlA0);
  rmlA0 = SystemImpl__regularFileExists(str) ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__trimChar)
{
  char* str = RML_STRINGDATA(rmlA0);
  char  char_to_be_trimmed = (char)RML_STRINGDATA(rmlA1)[0];
  rmlA0 = SystemImpl__trimChar(str,char_to_be_trimmed);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__strtok)
{
  char *s;
  char *delimit = RML_STRINGDATA(rmlA1);
  char *str = GC_strdup(RML_STRINGDATA(rmlA0));

  void * res = (void*)mk_nil();
  s=strtok(str,delimit);
  if (s == NULL) {
    /* Empty string becomes empty list: A success! */
    rmlA0=res; RML_TAILCALLK(rmlSC);
  }
  res = (void*)mk_cons(mk_scon(s),res);
  while ((s=strtok(NULL,delimit)))
  {
    res = (void*)mk_cons(mk_scon(s),res);
  }
  rmlA0=res;

  RML_TAILCALLQ(RML__list_5freverse,1);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__substring)
{
  char* substring = NULL;
  char* str = RML_STRINGDATA(rmlA0);
  int startIndex = RML_UNTAGFIXNUM(rmlA1);
  int stopIndex = RML_UNTAGFIXNUM(rmlA2);
  int len1 = strlen(str);
  int len2 = 0;

  /* Check arguments */
  if ( startIndex < 1 )
  {
    RML_TAILCALLK(rmlFC);
  }
  if ( stopIndex == -999 )
  {
    stopIndex = startIndex;
  } else if ( stopIndex< startIndex ) {
    RML_TAILCALLK(rmlFC);
  } else if ( stopIndex > len1 ) {
    RML_TAILCALLK(rmlFC);
  }

  /* Allocate memory and copy string */
  len2 = stopIndex - startIndex + 1;
  substring = (char*)GC_malloc(len2+1);
  strncpy(substring, &str[startIndex-1], len2);
  substring[len2] = '\0';

  rmlA0 = mk_scon(substring);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__toupper)
{
  char *base = RML_STRINGDATA(rmlA0);
  long len = strlen(base);
  char *res = (char*) GC_malloc_atomic(len+1);
  int i;
  for (i=0; i<len; i++)
    res[i] = toupper(base[i]);
  // fix the end!
  res[i] = '\0';
  rmlA0 = (void*) mk_scon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tolower)
{
  char *base = RML_STRINGDATA(rmlA0);
  long len = strlen(base);
  char *res = (char*) GC_malloc_atomic(len+1);
  int i;
  for (i=0; i<len; i++)
    res[i] = tolower(base[i]);
  res[i] = '\0';
  rmlA0 = (void*) mk_scon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__removeFirstAndLastChar)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *res = NULL;
  int length=strlen(str);
  int i;
  if(length > 1) {
      res=(char*)GC_malloc((length-1)*sizeof(char));
      strncpy(res,str + 1,length-2);
      res[length-1] = '\0';
      rmlA0 = (void*) mk_scon(res);
  } else {
      rmlA0 = (void*) mk_scon(str);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__configureCommandLine)
{
  rmlA0 = (void*) mk_scon(CONFIGURE_COMMANDLINE);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*  this removes chars in second from the beginning and end of the first
    string and returns it */
RML_BEGIN_LABEL(System__trim)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *chars_to_be_removed = RML_STRINGDATA(rmlA1);
  char *res = SystemImpl__trim(str,chars_to_be_removed);
  rmlA0 = (void*) mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__trimWhitespace)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *res = SystemImpl__trim(str," \f\n\r\t\v");
  rmlA0 = (void*) mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__strcmp)
{
  char *str0 = RML_STRINGDATA(rmlA0);
  char *str1 = RML_STRINGDATA(rmlA1);
  int res = strcmp(str0,str1);
  /* adrpo: 2010-10-07, return -1, 0, +1 so we can pattern match on it directly! */
  if      (res>0) res =  1;
  else if (res<0) res = -1;
  rmlA0 = (void*) mk_icon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__basename)
{
  const char *str = RML_STRINGDATA(rmlA0);
  rmlA0 = mk_scon(SystemImpl__basename(str));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__dirname)
{
  const char *str = RML_STRINGDATA(rmlA0);
  rmlA0 = mk_scon(dirname(GC_strdup(str)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringFind)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *searchStr = RML_STRINGDATA(rmlA1);
  const char *found = strstr(str, searchStr);
  if (found == NULL)
    rmlA0 = (void*) mk_icon(-1);
  else
    rmlA0 = (void*) mk_icon((long)found-(long)str);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringFindString)
{
  const char *str = RML_STRINGDATA(rmlA0);
  const char *searchStr = RML_STRINGDATA(rmlA1);
  const char *found = strstr(str, searchStr);
  if (found == NULL)
    RML_TAILCALLK(rmlFC);
  rmlA0 = mk_scon(found);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__strncmp)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *str2 = RML_STRINGDATA(rmlA1);
  rml_sint_t len = RML_UNTAGFIXNUM(rmlA2);
  int res= strncmp(str,str2,len);
  /* adrpo: 2010-10-07, return -1, 0, +1 so we can pattern match on it directly! */
  if      (res>0) res =  1;
  else if (res<0) res = -1;

  rmlA0 = (void*) mk_icon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__isIdenticalFile)
{
  char *fileName1 = RML_STRINGDATA(rmlA0);
  char *fileName2 = RML_STRINGDATA(rmlA1);
  int res=1, i;
  FILE *fp1, *fp2;
  long fileSize1, fileSize2;

  fp1 = fopen(fileName1, "r");
  fp2 = fopen(fileName2, "r");

  /* adrpo: fail the function if we cannot open one of the files */
  if((fp1 == NULL) || (fp2 == NULL))
  {
    fclose(fp1);
    fclose(fp2);
    RML_TAILCALLK(rmlFC);
  }

  fseek(fp1 , 0 , SEEK_END);
  fileSize1 = ftell(fp1);
  rewind(fp1);
  fseek(fp2 , 0 , SEEK_END);
  fileSize2 = ftell(fp2);
  rewind(fp2);

  if(fileSize1 != fileSize2)
  {
    res=-1;
  }
  else
  {
    for(i=0;i<fileSize1;++i)
    {
      if(fgetc(fp1) != fgetc(fp2))
      {
        res=-1;
        break;
      }
    }
  }
  fclose(fp1);fclose(fp2);

  rmlA0 = res != -1 ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringReplace)
{
  char *str = /* strdup( */RML_STRINGDATA(rmlA0)/* ) */;
  char *source = /* strdup( */RML_STRINGDATA(rmlA1)/* ) */;
  char *target =/*  strdup( */RML_STRINGDATA(rmlA2)/* ) */;
  char *res = _replace(str,source,target);
  if (res == NULL)
    RML_TAILCALLK(rmlFC);
  rmlA0 = (void*) mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setCCompiler)
{
  const char* str = RML_STRINGDATA(rmlA0);
  if (SystemImpl__setCCompiler(str)) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getCCompiler)
{
  if (cc == NULL)
    RML_TAILCALLK(rmlFC);
  rmlA0 = (void*) mk_scon(cc);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setCXXCompiler)
{
  const char* str = RML_STRINGDATA(rmlA0);
  if (SystemImpl__setCXXCompiler(str)) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getCXXCompiler)
{
  if (cxx == NULL)
    RML_TAILCALLK(rmlFC);
  rmlA0 = (void*) mk_scon(cxx);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getOMPCCompiler)
{
  if (omp_cc == NULL)
    RML_TAILCALLK(rmlFC);
  rmlA0 = (void*) mk_scon(omp_cc);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setLinker)
{
  const char* str = RML_STRINGDATA(rmlA0);
  if (SystemImpl__setLinker(str)) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getLinker)
{
  if (linker == NULL)
    RML_TAILCALLK(rmlFC);
  rmlA0 = (void*) mk_scon(linker);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setCFlags)
{
  const char* str = RML_STRINGDATA(rmlA0);
  if (SystemImpl__setCFlags(str)) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getCFlags)
{
  if (cflags == NULL)
    RML_TAILCALLK(rmlFC);
  rmlA0 = (void*) mk_scon(cflags);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setLDFlags)
{
  const char* str = RML_STRINGDATA(rmlA0);
  if (SystemImpl__setLDFlags(str)) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getLDFlags)
{
  if (ldflags == NULL)
    RML_TAILCALLK(rmlFC);
  rmlA0 = (void*) mk_scon(ldflags);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__cd)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  ret_val = chdir(str);

  rmlA0 = (void*) mk_icon(ret_val);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__writeFile)
{
  char* data = RML_STRINGDATA(rmlA1);
  char* filename = RML_STRINGDATA(rmlA0);
  if (SystemImpl__writeFile(filename,data))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__appendFile)
{
  const char* filename = RML_STRINGDATA(rmlA0);
  const char* data = RML_STRINGDATA(rmlA1);
  if (SystemImpl__appendFile(filename, data))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__readFile)
{
  char* filename = RML_STRINGDATA(rmlA0);
  char* res = SystemImpl__readFile(filename);
  rmlA0 = (void*) mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__readFileNoNumeric)
{
  const char* filename = RML_STRINGDATA(rmlA0);
  char *res = SystemImpl__readFileNoNumeric(filename);
  rmlA0 = (void*) mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__readEnv)
{
  char* envname = RML_STRINGDATA(rmlA0);
  char *envvalue;
  envvalue = getenv(envname);
  if (envvalue == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  rmlA0 = (void*) mk_scon(envvalue);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__time)
{
  rmlA0 = (void*) mk_rcon(SystemImpl__time());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__removeFile)
{
  rmlA0 = (void*) mk_icon(SystemImpl__removeFile(RML_STRINGDATA(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

double next_realelt(double *arr)
{
  static int curpos;

  if(arr == NULL) {
    curpos = 0;
    return 0.0;
  }
  else {
    return arr[curpos++];
  }
}

int next_intelt(int *arr)
{
  static int curpos;

  if(arr == NULL) {
    curpos = 0;
    return 0;
  }
  else return arr[curpos++];
}

RML_BEGIN_LABEL(System__getClassnamesForSimulation)
{
  if(class_names_for_simulation)
    rmlA0 = (void*) mk_scon(class_names_for_simulation);
  else
    rmlA0 = (void*) mk_scon("{}");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setClassnamesForSimulation)
{
  char* class_names = RML_STRINGDATA(rmlA0);
  class_names_for_simulation = GC_strdup(class_names);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__getVariableValue)
{
  double timeStamp   = rml_prim_get_real(rmlA0);
  void *timeValues   = rmlA1;
  void *varValues   = rmlA2;
  double res;
  if (SystemImpl__getVariableValue(timeStamp,timeValues,varValues,&res))
    RML_TAILCALLK(rmlFC);
  rmlA0 = mk_rcon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getCurrentTime)
{
  rmlA0 = mk_rcon(SystemImpl__getCurrentTime());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*
 * @author adrpo
 * this function sets the depth of variable showing in Eclipse.
 * it has no effect if is called within source not compiled in debug mode
 */
RML_BEGIN_LABEL(System__setDebugShowDepth)
{
#ifdef RML_DEBUG
  rmldb_depth_of_variable_print = RML_UNTAGFIXNUM(rmlA0);
#endif
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__freeFunction)
{
  modelica_integer funcIndex = RML_UNTAGFIXNUM(rmlA0);
  modelica_integer printDebug = RML_UNTAGFIXNUM(rmlA1);
  if (SystemImpl__freeFunction(funcIndex, printDebug))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__freeLibrary)
{
  modelica_integer libIndex = RML_UNTAGFIXNUM(rmlA0);
  modelica_integer printDebug = RML_UNTAGFIXNUM(rmlA1);
  if (SystemImpl__freeLibrary(libIndex, printDebug))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*
 * @author: adrpo
 * side effect to set if we have expandable connectors in a program
 */
RML_BEGIN_LABEL(System__getHasExpandableConnectors)
{
  rmlA0 = hasExpandableConnectors ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
/*
 * @author: adrpo
 * side effect to get if we have expandable connectors in a program
 */
RML_BEGIN_LABEL(System__setHasExpandableConnectors)
{
  hasExpandableConnectors = (RML_UNTAGFIXNUM(rmlA0)) ? 1 : 0;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*
 * @author: adrpo
 * side effect to set if we do partial instantiation
 */
RML_BEGIN_LABEL(System__getPartialInstantiation)
{
  rmlA0 = isPartialInstantiation ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
/*
 * @author: adrpo
 * side effect to get if we do partial instantiation
 */
RML_BEGIN_LABEL(System__setPartialInstantiation)
{
  isPartialInstantiation = (RML_UNTAGFIXNUM(rmlA0)) ? 1 : 0;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*
 * @author: adrpo
 * side effect to set if we have expandable connectors in a program
 */
RML_BEGIN_LABEL(System__getHasInnerOuterDefinitions)
{
  rmlA0 = hasInnerOuterDefinitions ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
/*
 * @author: adrpo
 * side effect to get if we have expandable connectors in a program
 */
RML_BEGIN_LABEL(System__setHasInnerOuterDefinitions)
{
  hasInnerOuterDefinitions = (RML_UNTAGFIXNUM(rmlA0)) ? 1 : 0;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*
 * @author: adrpo
 * side effect to set if we have stream connectors in a program
 */
RML_BEGIN_LABEL(System__getHasStreamConnectors)
{
  rmlA0 = hasStreamConnectors ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
/*
 * @author: adrpo
 * side effect to get if we have stream connectors in a program
 */
RML_BEGIN_LABEL(System__setHasStreamConnectors)
{
  hasStreamConnectors = (RML_UNTAGFIXNUM(rmlA0)) ? 1 : 0;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getUsesCardinality)
{
  rmlA0 = usesCardinality ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setUsesCardinality)
{
  usesCardinality = (RML_UNTAGFIXNUM(rmlA0)) ? 1 : 0;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tmpTick)
{
  rmlA0 = (void*) mk_icon(SystemImpl_tmpTick(NULL));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tmpTickReset)
{
  SystemImpl_tmpTickReset(NULL,RML_UNTAGFIXNUM(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tmpTickIndex)
{
  rmlA0 = (void*) mk_icon(SystemImpl_tmpTickIndex(NULL,RML_UNTAGFIXNUM(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tmpTickIndexReserve)
{
  rmlA0 = (void*) mk_icon(SystemImpl_tmpTickIndexReserve(NULL,RML_UNTAGFIXNUM(rmlA0),RML_UNTAGFIXNUM(rmlA1)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tmpTickResetIndex)
{
  SystemImpl_tmpTickResetIndex(NULL,RML_UNTAGFIXNUM(rmlA0),RML_UNTAGFIXNUM(rmlA1));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tmpTickSetIndex)
{
  SystemImpl_tmpTickSetIndex(NULL,RML_UNTAGFIXNUM(rmlA0),RML_UNTAGFIXNUM(rmlA1));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tmpTickMaximum)
{
  rmlA0 = (void*) mk_icon(SystemImpl_tmpTickMaximum(NULL,RML_UNTAGFIXNUM(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__systemCall)
{
  const char* str = RML_STRINGDATA(rmlA0);
  const char* outFile = RML_STRINGDATA(rmlA1);
  rmlA0 = (void*) mk_icon(SystemImpl__systemCall(str,outFile));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__systemCallParallel)
{
  rmlA0 = SystemImpl__systemCallParallel(rmlA0,RML_UNTAGFIXNUM(rmlA1));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__spawnCall)
{
  const char* path = RML_STRINGDATA(rmlA0);
  const char* str = RML_STRINGDATA(rmlA1);
  rmlA0 = (void*) mk_icon(SystemImpl__spawnCall(path, str));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__windowsNewline)
{
  rmlA0 = (void*) mk_scon("\r\n");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL



/*
 * Platform specific implementations
 */
// windows and mingw32
#if defined(__MINGW32__) || defined(_MSC_VER)

void System_5finit(void)
{
  char* path;
  char* newPath;

  last_ptr_index = -1;
  memset(ptr_vector, 0, sizeof(ptr_vector));

  path = getenv("PATH");
}

RML_BEGIN_LABEL(System__isSameFile)
{
  char *fileName1 = RML_STRINGDATA(rmlA0);
  char *fileName2 = RML_STRINGDATA(rmlA1);
  char *fn1_2,*fn2_2;
  int same = 0;
  HRESULT res1,res2;
  char canonName1[MAX_PATH],canonName2[MAX_PATH];
  DWORD size=MAX_PATH;
  DWORD size2=MAX_PATH;
  if (UrlCanonicalize(fileName1,canonName1,&size,0) != S_OK ||
    UrlCanonicalize(fileName2,canonName2,&size2,0) != S_OK) {
      printf("Error, fileName1 =%s, fileName2 = %s couldn't be canonicalized\n",fileName1,fileName2);
      RML_TAILCALLK(rmlFC);
    };
  //printf("Canonicalized f1:%s, \nf2:%s\n",canonName1,canonName2);
  fn1_2 = _replace(canonName1,"//","/");
  fn2_2 = _replace(canonName2,"//","/");
  //printf("Replaced form f1:%s, \nf2:%s\n",fn1_2,fn2_2);
  same = strcmp(fn1_2,fn2_2) == 0;
  free(fn1_2);
  free(fn2_2);
  if(same){
    RML_TAILCALLK(rmlSC);
  }
  else {
    RML_TAILCALLK(rmlFC);
  }
}
RML_END_LABEL

RML_BEGIN_LABEL(System__compileCFile)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  char exename[255];
  char *tmp;

  assert(strlen(str) < 255);
  if (strlen(str) >= 255) {
    RML_TAILCALLK(rmlFC);
  }
  if (cc == NULL||cflags == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(exename,str,strlen(str)-2);
  exename[strlen(str)-2]='\0';

  sprintf(command,"%s %s -o %s %s > compilelog.txt 2>&1",cc,str,exename,cflags);
  //printf("compile using: %s\n",command);

  _putenv("GCC_EXEC_PREFIX=");
  tmp = getenv("MODELICAUSERCFLAGS");
  if (tmp == NULL || tmp[0] == '\0'  ) {
    _putenv("MODELICAUSERCFLAGS=  ");
  }
  if (system(command) != 0) {
    RML_TAILCALLK(rmlFC);
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* RML_BEGIN_LABEL(System__modelicapath) */
/* { */
/*   char *path = getenv("OPENMODELICALIBRARY"); */
/*   if (path == NULL)  */
/*       RML_TAILCALLK(rmlFC); */

/*   rmlA0 = (void*) mk_scon(path); */
/*   RML_TAILCALLK(rmlSC); */
/* } */
/* RML_END_LABEL */

RML_BEGIN_LABEL(System__subDirectories)
{
  void *res;
  WIN32_FIND_DATA FileData;
  BOOL more = TRUE;
  char* directory = RML_STRINGDATA(rmlA0);
  char pattern[1024];
  HANDLE sh;
  if (directory == NULL)
    RML_TAILCALLK(rmlFC);

  sprintf(pattern, "%s\\*.*", directory);

  res = (void*)mk_nil();
  sh = FindFirstFile(pattern, &FileData);
  if (sh != INVALID_HANDLE_VALUE) {
    while(more) {
      if (strcmp(FileData.cFileName,"..") != 0 &&
        strcmp(FileData.cFileName,".") != 0 &&
        (FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0)
      {
          res = (void*)mk_cons(mk_scon(FileData.cFileName),res);
      }
      more = FindNextFile(sh, &FileData);
    }
    if (sh != INVALID_HANDLE_VALUE) FindClose(sh);
  }
  rmlA0 = (void*)res;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__moFiles)
{
  void *res;
  WIN32_FIND_DATA FileData;
  BOOL more = TRUE;
  char* directory = RML_STRINGDATA(rmlA0);
  char pattern[1024];
  HANDLE sh;
  if (directory == NULL)
    RML_TAILCALLK(rmlFC);

  sprintf(pattern, "%s\\*.mo", directory);

  res = (void*)mk_nil();
  sh = FindFirstFile(pattern, &FileData);
  if (sh != INVALID_HANDLE_VALUE) {
    while(more) {
      if (strcmp(FileData.cFileName,"package.mo") != 0)
      {
          res = (void*)mk_cons(mk_scon(FileData.cFileName),res);
      }
      more = FindNextFile(sh, &FileData);
    }
    if (sh != INVALID_HANDLE_VALUE) FindClose(sh);
  }
  rmlA0 = (void*)res;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

int fileExistsLocal(char * s){
  int ret=-1;
  WIN32_FIND_DATA FileData;
  HANDLE sh;
  sh = FindFirstFile(s, &FileData);
  if (sh == INVALID_HANDLE_VALUE) {
    ret = -1;
  }
  else {
    if ((FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
      ret = -1;
    }
    else {
      ret = 0;
    }
    FindClose(sh);
  }
return ret;
}

RML_BEGIN_LABEL(System__getFileModificationTime)
{
  char* fileName = RML_STRINGDATA(rmlA0);
  struct _stat attrib;        // create a file attribute structure
  double elapsedTime;             // the time elapsed as double
  int result;            // the result of the function call

  result = _stat( fileName, &attrib );

  if( result != 0 )
  {
    rmlA0 = mk_none();     // we couldn't get the time, return NONE
  }
  else
  {
    rmlA0 = mk_some(mk_rcon(difftime(attrib.st_mtime, 0))); // the file modification time
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getCurrentTimeStr)
{
  time_t t;
  struct tm* localTime;
  char * dateStr;
  time( &t );
  localTime = localtime(&t);
  dateStr = asctime(localTime);
  rmlA0 = mk_scon(dateStr);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getCurrentDateTime)
{
  time_t t;
  struct tm* localTime;
  int sec;
  int min;
  int hour;
  int mday;
  int mon;
  int year;
  time( &t );
  localTime = localtime(&t);
  sec = localTime->tm_sec;
  min = localTime->tm_min;
  hour = localTime->tm_hour;
  mday = localTime->tm_mday;
  mon = localTime->tm_mon + 1;
  year = localTime->tm_year + 1900;
  rmlA0 = (void*) mk_icon(sec);
  rmlA1 = (void*) mk_icon(min);
  rmlA2 = (void*) mk_icon(hour);
  rmlA3 = (void*) mk_icon(mday);
  rmlA4 = (void*) mk_icon(mon);
  rmlA5 = (void*) mk_icon(year);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

#else /********************************* LINUX PART!!! *************************************/

#ifndef HAVE_SCANDIR

typedef int _file_select_func_type(const struct dirent *);
typedef int _file_compar_func_type(const struct dirent **, const struct dirent **);

void reallocdirents(struct dirent ***entries,
        unsigned int oldsize,
        unsigned int newsize) {
  struct dirent **newentries;
  if (newsize<=oldsize)
    return;
  newentries = (struct dirent**)malloc(newsize * sizeof(struct dirent *));
  if (*entries != NULL) {
    int i;
    for (i=0; i<oldsize; i++)
      newentries[i] = (*entries)[i];
    for(; i<newsize; i++)
      newentries[i] = NULL;
    if (oldsize > 0)
      free(*entries);
  }
  *entries = newentries;
}

/*
 * compar function is ignored
 */
int scandir(const char* dirname,
      struct dirent ***entries,
      _file_select_func_type select,
      _file_compar_func_type compar)
{
  DIR *dir = opendir(dirname);
  struct dirent *entry;
  unsigned int count = 0;
  unsigned int maxents = 100;
  *entries = NULL;
  reallocdirents(entries,0,maxents);
  do {
    entry = readdir(dir);
    if (entry == NULL)
      break;
    if (select == NULL || select(entry)) {
      struct dirent *entcopy = (struct dirent*)malloc(sizeof(struct dirent));
      if (count >= maxents) {
        unsigned int oldmaxents = maxents;
        maxents = maxents * 2;
        reallocdirents(entries, oldmaxents, maxents);
      }
      (*entries)[count] = entcopy;
      count++;
    }
  } while (count < maxents); /* shouldn't be needed */
  /*
     write code for calling qsort using compar for sorting the
     entries.
  */
  closedir(dir);
  return count;
}

#endif /* 0 */

void System_5finit(void)
{
  last_ptr_index = -1;
  memset(ptr_vector, 0, sizeof(ptr_vector));
}

RML_BEGIN_LABEL(System__subDirectories)
{
  int i,count;
  void *res;
  char* directory = RML_STRINGDATA(rmlA0);
  struct dirent **files;
  if (directory == NULL)
    RML_TAILCALLK(rmlFC);
  select_from_dir = directory;
  count = scandir(directory, &files, file_select_directories, NULL);
  res = (void*)mk_nil();
  for (i=0; i<count; i++)
  {
    res = (void*)mk_cons(mk_scon(files[i]->d_name),res);
    /* adrpo added 2004-10-28 */
    //free(files[i]->d_name);
  free(files[i]);
  }
  rmlA0 = (void*) res;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__moFiles)
{
  int i,count;
  void *res;
  char* directory = RML_STRINGDATA(rmlA0);
  struct dirent **files;
  if (directory == NULL)
    RML_TAILCALLK(rmlFC);
  select_from_dir = directory;
  count = scandir(directory, &files, file_select_mo, NULL);
  res = (void*)mk_nil();
  for (i=0; i<count; i++)
  {
    res = (void*)mk_cons(mk_scon(files[i]->d_name),res);
    /* adrpo added 2004-10-28 */
    //free(files[i]->d_name);
    free(files[i]);
  }
  rmlA0 = (void*) res;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

static char *path_cat (const char *str1, char *str2,char *fileString)
{
  struct stat buf;
  char *result;
  int ret_val;

  result = (char *)malloc(PATH_MAX*sizeof( *result));
  if(strcmp(str2,"..") ==0 || strcmp(str2,".")==0) {
    result[0]= '\0'; return result;
  }
  sprintf(result,"%s%s/%s",str1,str2,fileString);
  ret_val = stat(result, &buf);

  if (ret_val == 0 && buf.st_mode & S_IFREG) {
    return result;
  }
  result[0]='\0';
  return result;
}

RML_BEGIN_LABEL(System__getPackageFileNames)
{
    char* dir_path = RML_STRINGDATA(rmlA0);
    char* fileName = RML_STRINGDATA(rmlA1);
    struct dirent *dp;
    int mallocSize = PATH_MAX,current=0;
    char * retString = (char*)malloc(mallocSize*sizeof(char*));
    // enter existing path to directory below
    DIR *dir = opendir(dir_path);
    while ((dp=readdir(dir)) != NULL) {
            char *tmp;
            tmp = path_cat(dir_path, dp->d_name, fileName);
            if(strlen(tmp)>0){
                if(strlen(dp->d_name)+current>mallocSize){
                    mallocSize *= 2;
                    retString = (char *)realloc(retString,mallocSize);
                }
                if(current==0){
                    sprintf(retString,"%s",dp->d_name);
                }
                else{
                    sprintf(retString,"%s,%s",retString,dp->d_name);
                }
                current +=strlen(dp->d_name)+1;
            }
            free(tmp);
            tmp=NULL;
    }
    closedir(dir);
    //printf(" res string linux: %s\n" , retString);
    rmlA0 = (void*) mk_scon(retString);
    free(retString);
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getFileModificationTime)
{
  char* fileName = RML_STRINGDATA(rmlA0);
  struct stat attrib;            // create a file attribute structure
  double elapsedTime;                 // the time elapsed as double
  int result;                // the result of the function call

  result =   stat(fileName, &attrib); // get the attributes of the file

  if( result != 0 )
  {
    rmlA0 = mk_none();     // we couldn't get the time, return NONE
  }
  else
  {
    rmlA0 = mk_some(mk_rcon(difftime(attrib.st_mtime, 0))); // the file modification time
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__getCurrentTimeStr)
{
  time_t t;
  struct tm* localTime;
  char * dateStr;
  time( &t );
  localTime = localtime(&t);
  dateStr = asctime(localTime);
  rmlA0 = mk_scon(dateStr);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getCurrentDateTime)
{
  time_t t;
  struct tm* localTime;
  int sec;
  int min;
  int hour;
  int mday;
  int mon;
  int year;
  time( &t );
  localTime = localtime(&t);
  sec = localTime->tm_sec;
  min = localTime->tm_min;
  hour = localTime->tm_hour;
  mday = localTime->tm_mday;
  mon = localTime->tm_mon + 1;
  year = localTime->tm_year + 1900;
  rmlA0 = (void*) mk_icon(sec);
  rmlA1 = (void*) mk_icon(min);
  rmlA2 = (void*) mk_icon(hour);
  rmlA3 = (void*) mk_icon(mday);
  rmlA4 = (void*) mk_icon(mon);
  rmlA5 = (void*) mk_icon(year);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

#endif /* MINGW32 and Linux */

RML_BEGIN_LABEL(System__realtimeTick)
{
  int ix = RML_UNTAGFIXNUM(rmlA0);
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) RML_TAILCALLK(rmlFC);
  rt_tick(ix);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__realtimeTock)
{
  int ix = RML_UNTAGFIXNUM(rmlA0);
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_rcon(rt_tock(ix));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__realtimeClear)
{
  int ix = RML_UNTAGFIXNUM(rmlA0);
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) RML_TAILCALLK(rmlFC);
  rt_clear(ix);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__realtimeNtick)
{
  int ix = RML_UNTAGFIXNUM(rmlA0);
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_icon(rt_ncall(ix));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__resetTimer)
{
  /* reset the timer */
  timerIntervalTime = 0;
  timerCummulatedTime = 0;
  timerTime = 0;
  timerStackIdx = 0;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__startTimer)
{
  /* start the timer if not already started */
  if (!timerStackIdx)
  {
    rt_tick(RT_CLOCK_SPECIAL_STOPWATCH);
  }
  pushTimerStack();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stopTimer)
{
  popTimerStack();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getTimerIntervalTime)
{
  /* get the cummulated timer time */
  rmlA0 = mk_rcon(timerIntervalTime);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getTimerCummulatedTime)
{
  /* get the cummulated timer time */
  rmlA0 = mk_rcon(timerCummulatedTime);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getTimerElapsedTime)
{
  /* get the cummulated timer time */
  rmlA0 = mk_rcon(rt_tock(RT_CLOCK_SPECIAL_STOPWATCH) - timerStack[0]);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getTimerStackIndex)
{
  /* get the cummulated timer time */
  rmlA0 = mk_icon(timerStackIdx);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getRTLibs)
{
  rmlA0 = (void*) mk_scon(LDFLAGS_RT);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getRTLibsSim)
{
  rmlA0 = (void*) mk_scon(LDFLAGS_RT_SIM);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getCorbaLibs)
{
  rmlA0 = (void*) mk_scon(CONFIG_CORBALIBS);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getRuntimeLibs)
{
  rmlA0 = CONFIG_SYSTEMLIBS;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getExeExt)
{
  rmlA0 = (void*) mk_scon(CONFIG_EXE_EXT);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getDllExt)
{
  rmlA0 = (void*) mk_scon(CONFIG_DLL_EXT);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__os)
{
  rmlA0 = (void*) mk_scon(CONFIG_OS);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon(CONFIG_PLATFORM);
  RML_TAILCALLK(rmlSC);
}

RML_BEGIN_LABEL(System__pathDelimiter)
{
  rmlA0 = (void*) mk_scon(CONFIG_PATH_DELIMITER);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__groupDelimiter)
{
  rmlA0 = (void*) mk_scon(CONFIG_GROUP_DELIMITER);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__pwd)
{
  char *buf = SystemImpl__pwd();
  if (buf == NULL) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_scon(buf);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__directoryExists)
{
  const char* str = RML_STRINGDATA(rmlA0);
  rmlA0 = (void*) mk_icon(SystemImpl__directoryExists(str));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__createDirectory)
{
  const char* str = RML_STRINGDATA(rmlA0);
  rmlA0 = (void*) mk_icon(SystemImpl__createDirectory(str));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__removeDirectory)
{
  const char* str = RML_STRINGDATA(rmlA0);
  rmlA0 = (void*) mk_icon(SystemImpl__removeDirectory(str));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__userIsRoot)
{
  rmlA0 = mk_icon(CONFIG_USER_IS_ROOT);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setEnv)
{
  char* envname = RML_STRINGDATA(rmlA0);
  char* envvalue = RML_STRINGDATA(rmlA1);
  rml_sint_t overwrite = RML_UNTAGFIXNUM(rmlA2);
  rmlA0 = mk_icon(setenv(envname, envvalue, overwrite));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getUUIDStr)
{
  rmlA0 = mk_scon(SystemImpl__getUUIDStr());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__loadLibrary)
{
  const char *str = RML_STRINGDATA(rmlA0);
  modelica_integer printDebug = RML_UNTAGFIXNUM(rmlA1);
  int res = SystemImpl__loadLibrary(str, printDebug);
  if (res == -1)
    RML_TAILCALLK(rmlFC);
  rmlA0 = mk_icon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__lookupFunction)
{
  modelica_integer libIndex = RML_UNTAGFIXNUM(rmlA0), funcIndex;
  const char *str = RML_STRINGDATA(rmlA1);
  funcIndex = SystemImpl__lookupFunction(libIndex,str);
  if (funcIndex == -1)
    RML_TAILCALLK(rmlFC);
  rmlA0 = (void*) mk_icon(funcIndex);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__unescapedStringLength)
{
  const char *str = RML_STRINGDATA(rmlA0);
  rmlA0 = mk_icon(SystemImpl__unescapedStringLength(str));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringHashDjb2Mod)
{
  rmlA0 = mk_icon(stringHashDjb2Mod(rmlA0,RML_UNTAGFIXNUM(rmlA1)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__regex)
{
  void *res;
  int nmatch, i = 0, maxn = RML_UNTAGFIXNUM(rmlA2);
  void *matches[maxn];
  nmatch = OpenModelica_regexImpl(RML_STRINGDATA(rmlA0),RML_STRINGDATA(rmlA1),maxn,RML_UNTAGFIXNUM(rmlA3),RML_UNTAGFIXNUM(rmlA4),mk_scon,(void**)&matches);
  res = mk_nil();
  for (i=maxn-1; i>=0; i--) {
    res = mk_cons(matches[i],res);
  }
  rmlA0 = mk_icon(nmatch);
  rmlA1 = res;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__unescapedString)
{
  char *str = SystemImpl__unescapedString(RML_STRINGDATA(rmlA0));
  if (str == NULL) {
    RML_TAILCALLK(rmlSC);
  } else {
    rmlA0 = mk_scon(str);
    RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL

RML_BEGIN_LABEL(System__escapedString)
{
  char *str = omc__escapedString(RML_STRINGDATA(rmlA0),RML_UNTAGFIXNUM(rmlA1));
  if (str == NULL) {
    RML_TAILCALLK(rmlSC);
  } else {
    rmlA0 = mk_scon(str);
    RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL

RML_BEGIN_LABEL(System__unquoteIdentifier)
{
  char *str = SystemImpl__unquoteIdentifier(RML_STRINGDATA(rmlA0));
  if (str == NULL) {
    RML_TAILCALLK(rmlSC);
  } else {
    rmlA0 = mk_scon(str);
    RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL

RML_BEGIN_LABEL(System__realMaxLit)
{
  rmlA0 = mk_rcon(DBL_MAX / 2048);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__intMaxLit)
{
  rmlA0 = mk_icon(LONG_MAX / 2);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__uriToClassAndPath)
{
  const char *scheme;
  char *name,*path;
  int res = SystemImpl__uriToClassAndPath(RML_STRINGDATA(rmlA0),&scheme,&name,&path);
  rmlA0 = scheme ? mk_scon((char*)scheme) : 0;
  rmlA1 = name ? mk_scon(name) : 0;
  rmlA2 = path ? mk_scon(path) : 0;
  if (res)
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__modelicaPlatform)
{
  rmlA0 = mk_scon(CONFIG_MODELICA_SPEC_PLATFORM);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__openModelicaPlatform)
{
  rmlA0 = mk_scon(CONFIG_OPENMODELICA_SPEC_PLATFORM);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getGCStatus)
{
  long used = RML_SIZE_INT*((unsigned long)(rml_state_young_next - rml_young_region)
             + (unsigned long)(rml_current_next - rml_current_region));
  long allocated = RML_SIZE_INT*(rml_older_size + rml_young_size);
  rmlA0 = mk_icon(used);
  rmlA1 = mk_icon(allocated);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__dgesv)
{
  void *res;
  rmlA1 = mk_icon(SystemImpl__dgesv(rmlA0,rmlA1,&res));
  rmlA0 = res;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__lpsolve55)
{
  void *res;
  rmlA1 = mk_icon(SystemImpl__lpsolve55(rmlA0,rmlA1,rmlA2,&res));
  rmlA0 = res;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getLoadModelPath)
{
  const char *outDir;
  char *outName = NULL;
  int isDir;
  if (SystemImpl__getLoadModelPath(RML_STRINGDATA(rmlA0),rmlA1,rmlA2,&outDir,&outName,&isDir))
    RML_TAILCALLK(rmlFC);
  rmlA0 = mk_scon(outDir);
  rmlA1 = mk_scon(outName);
  rmlA2 = mk_icon(isDir);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__reopenStandardStream)
{
  rmlA0 = mk_icon(SystemImpl__reopenStandardStream(RML_UNTAGFIXNUM(rmlA0),RML_STRINGDATA(rmlA1)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getMakeCommand)
{
  rmlA0 = mk_scon(DEFAULT_MAKE);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__iconv)
{
  rmlA0 = mk_scon(SystemImpl__iconv(RML_STRINGDATA(rmlA0),RML_STRINGDATA(rmlA1),RML_STRINGDATA(rmlA2),1));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__snprintff)
{
  const char *fmt = RML_STRINGDATA(rmlA0);
  long len = RML_UNTAGFIXNUM(rmlA1);
  double d = rml_prim_get_real(rmlA2);
  if (len > 0) {
    char buf[len];
    if (snprintf(buf,len,fmt,d) >= len) {
      RML_TAILCALLK(rmlFC);
    }
    buf[len-1] = 0;
    rmlA0 = mk_scon(buf);
  } else {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__intRand)
{
  rmlA0 = mk_icon(SystemImpl__intRand(RML_UNTAGFIXNUM(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__realRand)
{
  rmlA0 = mk_rcon(SystemImpl__realRand());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__gettextInit)
{
  SystemImpl__gettextInit(RML_STRINGDATA(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__gettext)
{
  rmlA0 = mk_scon(SystemImpl__gettext(RML_STRINGDATA(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__anyStringCode)
{
  rmlA0 = mk_scon("You need to run the bootstrapped compiler in order to use anyStringCode");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__numBits)
{
  rmlA0 = mk_icon(8*sizeof(void*));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__integerMax)
{
  rmlA0 = mk_icon((1L << ((8*sizeof(void*))-2))-1);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__realpath)
{
  char buf[PATH_MAX];
  if (realpath(RML_STRINGDATA(rmlA0), buf) == NULL)
    RML_TAILCALLK(rmlFC);
  rmlA0 = mk_scon(buf);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getSimulationHelpText)
{
  rmlA0 = mk_scon(System_getSimulationHelpText(RML_UNTAGFIXNUM(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getTerminalWidth)
{
  rmlA0 = mk_icon(System_getTerminalWidth());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__fileIsNewerThan)
{
  int res = SystemImpl__fileIsNewerThan(RML_STRINGDATA(rmlA0), RML_STRINGDATA(rmlA1));
  if (res == -1)
    RML_TAILCALLK(rmlFC);
  rmlA0 = mk_icon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__numProcessors)
{
  rmlA0 = mk_icon(System_numProcessors());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__launchParallelTasks)
{
  c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("Threads are not available when OpenModelica is compiled using RML"),NULL,0);
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__GC_5fgcollect_5fand_5funmap)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__GC_5fenable)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__GC_5fdisable)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__GC_5fset_5ffree_5fspace_5fdivisor)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__exit)
{
  exit(RML_UNTAGFIXNUM(rmlA0));
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getMemorySize)
{
  rmlA0 = mk_rcon(System_getMemorySize());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__initGarbageCollector)
{
  SystemImpl__initGarbageCollector();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__fileContentsEqual)
{
  rmlA0 = mk_icon(SystemImpl__fileContentsEqual(RML_STRINGDATA(rmlA0), RML_STRINGDATA(rmlA1)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__rename)
{
  rmlA0 = mk_icon(SystemImpl__rename(RML_STRINGDATA(rmlA0), RML_STRINGDATA(rmlA1)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__ctime)
{
  rmlA0 = mk_scon(SystemImpl__ctime(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stat)
{
  double size,mtime;
  rmlA0 = mk_icon(SystemImpl__stat(RML_STRINGDATA(rmlA0),&size,&mtime));
  rmlA1 = mk_rcon(size);
  rmlA2 = mk_rcon(mtime);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__alarm)
{
  rmlA0 = mk_icon(SystemImpl__alarm(RML_UNTAGFIXNUM(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__covertTextFileToCLiteral)
{
  rmlA0 = mk_icon(SystemImpl__covertTextFileToCLiteral(RML_STRINGDATA(rmlA0),RML_STRINGDATA(rmlA1)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__isRML)
{
  rmlA0 = mk_icon(1);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__strtokIncludingDelimiters)
{
  char* str = RML_STRINGDATA(rmlA0);
  rml_uint_t len = RML_HDRSTRLEN(RML_GETHDR(rmlA0));
  char* cp = NULL;
  char *d = RML_STRINGDATA(rmlA1);
  rml_uint_t dlen = RML_HDRSTRLEN(RML_GETHDR(rmlA1));
  void *lst = RML_TAGPTR(&rml_prim_nil);
  void *slst = RML_TAGPTR(&rml_prim_nil);
  char* s = str;
  char* stmp;
  rml_uint_t start = 0, end = 0;
  /* len + 3 in pos signifies that there is no delimiter in the string */
  rml_uint_t pos = len + 3;

  /* fail if delimiter is bigger than string */
  if (dlen > len)
  {
    RML_TAILCALLK(rmlFC);
  }

  /* add 0 to the list! */
  lst = mk_cons(mk_icon(0), lst);

  /* find the first delimiter */
  while ((cp = strstr(s, d)) != NULL)
  {
    s = cp + dlen;
    pos = (cp - str);
    /* check if the position is already in the list */
    /* in the list add only the end */
    if (pos == RML_UNTAGFIXNUM(RML_CAR(lst)))
    {
      lst = mk_cons(mk_icon(pos+dlen), lst);
    }
    else /* not in the list, add both */
    {
      lst = mk_cons(mk_icon(pos), lst);
      lst = mk_cons(mk_icon(pos+dlen), lst);
    }
  }
  /* this means it was not found in the entire string */
  if (pos == (len + 3))
  {
    /* return the empty list */
    rmlA0 = slst;
    RML_TAILCALLK(rmlSC);
  }

  /* add len to the list! */
  if ((len) != RML_UNTAGFIXNUM(RML_CAR(lst)))
  {
    lst = mk_cons(mk_icon(len), lst);
  }

  /*
   * BIG NOTE! the list of indexes is reversed, it starts closer to len!
   */
  /* now we walk the list and build the string list */
  while( RML_GETHDR(lst) == RML_CONSHDR )
  {
    end = RML_UNTAGFIXNUM(RML_CAR(lst));
    lst = RML_CDR(lst);
    /* break if we reached the last in the list */
    if (RML_GETHDR(lst) == RML_NILHDR)
    {
      break;
    }
    start = RML_UNTAGFIXNUM(RML_CAR(lst));
    /* create stmp */
    pos = end - start;
    stmp = (char*)malloc((pos+1) * sizeof(char));
    strncpy(stmp, str + start, pos);
    stmp[pos] = '\0';
    slst = mk_cons(mk_scon(stmp), slst);
    free(stmp);
  }
  rmlA0 = slst;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

