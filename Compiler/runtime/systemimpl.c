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
 * TODO! unify the functions in this file for all platforms as is really hard to follow!
 *       if we have 2 definition for each function!
 */

/*
 * adrpo 2007-05-09
 * UNCOMMENT THIS ONLY IF YOU COMPILE OMC IN DEBUG MODE!!!!!
 * #define RML_DEBUG
 */

/*
 * adrpo 2008-12-02
 * http://www.cse.yorku.ca/~oz/hash.html
 * hash functions which could be useful to replace System__hash:
 * djb2 hash
 * unsigned long hash(unsigned char *str)
 * {
 *   unsigned long hash = 5381;
 *   int c;
 *   while (c = *str++)  hash = ((hash << 5) + hash) + c; // hash * 33 + c
 *   return hash;
 * }
 *******
 * sdbm hash
 * static unsigned long sdbm(unsigned char* str)
 * {
 *   unsigned long hash = 0;
 *   int c;
 *   while (c = *str++) hash = c + (hash << 6) + (hash << 16) - hash;
 *   return hash;
 * }
 *
 */

/*
 * x08joekl 2008-01-24
 * functions and globals common to both win32 and *nix
 */

#if defined(_MSC_VER)
 #define WIN32_LEAN_AND_MEAN
 #include <Windows.h>
#endif
#include <stdlib.h>
#include <string.h>
#include "systemimpl.h"
#include "rml.h"

/* use this one to output messages depending on flags! */
int check_debug_flag(char const* strdata);

static char * cc=NULL;
static char * cxx=NULL;
static char * linker=NULL;
static char * cflags=NULL;
static char * ldflags=NULL;

#define MAX_PTR_INDEX 10000

/*
#if defined(_MSC_VER)
#define inline __inline
#else // Linux & MinGW
#define inline inline
#endif
*/

static inline modelica_integer alloc_ptr();
static inline void free_ptr(modelica_integer index);
static void free_library(modelica_ptr_t lib);
static void free_function(modelica_ptr_t func);

static int set_cc(char *str)
{
  size_t len = strlen(str);
  if (cc != NULL) {
    free(cc);
  }
  cc = (char*)malloc(len+1);
  if (cc == NULL) return -1;
  memcpy(cc,str,len+1);
  return 0;
}

static int set_cxx(char *str)
{
  size_t len = strlen(str);
  if (cxx != NULL) {
    free(cxx);
  }
  cxx = (char*)malloc(len+1);
  if (cxx == NULL) return -1;
  memcpy(cxx,str,len+1);
  return 0;
}

static int set_linker(char *str)
{
  size_t len = strlen(str);
  if (linker != NULL) {
    free(linker);
  }
  linker = (char*)malloc(len+1);
  if (linker == NULL) return -1;
  memcpy(linker,str,len+1);
  return 0;
}

static int set_cflags(char *str)
{
  size_t len = strlen(str);
  if (cflags != NULL) {
    free(cflags);
  }
  cflags = (char*)malloc(len+1);
  if (cflags == NULL) return -1;
  memcpy(cflags,str,len+1);
  return 0;
}

static int set_ldflags(char *str)
{
  size_t len = strlen(str);
  if (ldflags != NULL) {
    free(ldflags);
  }
  ldflags = (char*)malloc(len+1);
  if (ldflags == NULL) return -1;
  memcpy(ldflags,str,len+1);
  return 0;
}

RML_BEGIN_LABEL(System__trimChar)
{
  char* str = RML_STRINGDATA(rmlA0);
  char  char_to_be_trimmed = (char)RML_STRINGDATA(rmlA1)[0];
  int length=strlen(str);
  int start_pos = 0;
  int end_pos = length - 1;
  char* res;
  while(start_pos < end_pos){
    if(str[start_pos] == char_to_be_trimmed)
      start_pos++;
    if(str[end_pos] == char_to_be_trimmed)
      end_pos--;
    if(str[start_pos] != char_to_be_trimmed && str[end_pos] != char_to_be_trimmed)
      break;
  }
  if(end_pos > start_pos){
    res= (char*)malloc(end_pos - start_pos +2);
    strncpy(res,&str[start_pos],end_pos - start_pos+1);
    res[end_pos - start_pos+1] = '\0';
    rmlA0 = (void*) mk_scon(res);
    free(res);
    RML_TAILCALLK(rmlSC);

  }else{
    rmlA0 = (void*) mk_scon("");
    RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL

// windows and mingw32
#if defined(__MINGW32__) || defined(_MSC_VER)

#include <stdlib.h>
#include <direct.h>
#include <assert.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlwapi.h>

#define MAXPATHLEN MAX_PATH
#define S_IFLNK  0120000  /* symbolic link */

static struct modelica_ptr_s ptr_vector[MAX_PTR_INDEX];
static modelica_integer last_ptr_index = -1;


void System_5finit(void)
{
  char* path;
  char* newPath;

  last_ptr_index = -1;
  memset(ptr_vector, 0, sizeof(ptr_vector));

  set_cc("g++");
  set_cxx("g++");
#if defined(__x86_64__)
  /* -fPIC needed on x86_64! */
  set_linker("g++ -shared -export-dynamic -fPIC");
#else
  set_linker("g++ -shared -export-dynamic");
#endif

#if defined(__i386__) || defined(__x86_64__) || defined(_MSC_VER)
  /*
   * if we are on i386 or x86_64 or compiling with
   * Visual Studio then use the SSE instructions,
   * not the normal i387 FPU
   */
  set_cflags("-msse2 -mfpmath=sse ${MODELICAUSERCFLAGS}");
#else
  set_cflags("${MODELICAUSERCFLAGS}");
#endif
  set_ldflags("-lc_runtime");
  path = getenv("PATH");

  _putenv("SENDDATALIBS=-lsendData -lQtNetwork-mingw -lQtCore-mingw -lQtGui-mingw -luuid -lole32 -lws2_32");
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

RML_BEGIN_LABEL(System__strtok)
{
  char *s;
  char *delimit = RML_STRINGDATA(rmlA1);
  char *str = strdup(RML_STRINGDATA(rmlA0));

  void * res = (void*)mk_nil();
  s=strtok(str,delimit);
  if (s == NULL)
  {
    /* adrpo added 2004-10-27 */
    free(str);
    rmlA0=res; RML_TAILCALLK(rmlFC);
  }
  res = (void*)mk_cons(mk_scon(s),res);
  while (s=strtok(NULL,delimit))
  {
    res = (void*)mk_cons(mk_scon(s),res);
  }
  rmlA0=res;

  /* adrpo added 2004-10-27 */
  free(str);

  /* adrpo changed 2004-10-29
  * rml_prim_once(RML__list_5freverse);
  * RML_TAILCALLK(rmlSC);
  */
  RML_TAILCALLQ(RML__list_5freverse,1);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__toupper)
{
  char *str = strdup(RML_STRINGDATA(rmlA0));
  char *res=str;
  while (*str!= '\0')
  {
    *str=toupper(*str++);
  }
  rmlA0 = (void*) mk_scon(res);

  /* adrpo added 2004-10-29 */
  free(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__removeFirstAndLastChar)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *res = "";
  int length=strlen(str);
  int i;
  if(length > 1)
    {
      res=malloc(length-1);
      strncpy(res,str + 1,length-2);

      res[length-1] = '\0';
    }

  rmlA0 = (void*) mk_scon(res);
  /* adrpo added 2004-10-29 */
  free(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__isIdenticalFile)
{
  char *fileName1 = RML_STRINGDATA(rmlA0);
  char *fileName2 = RML_STRINGDATA(rmlA1);
  char emptyString[5] = "empty";
  int res=1,i;
  FILE *fp1,*fp2,*d1,*d2;
  long fileSize1,fileSize2;
  fp1 = fopen(fileName1, "r");

  if(!fp1){
    //printf("Error opening the file: %s, creating it\n",fileName1);
    d1 = fopen(fileName1,"w+");
    for(i=0;i<5;++i)
      fputc(emptyString[i],d1);
    fclose(d1);
  }
  fp1 = fopen(fileName1, "r");
  fp2 = fopen(fileName2, "r");
  if(!fp2){
      //printf("Error opening the file(#2): %s\n",fileName2);
     rmlA0 = RML_FALSE;
      RML_TAILCALLK(rmlSC);
    }

  fseek(fp1 , 0 , SEEK_END);
  fileSize1 = ftell(fp1);
  rewind(fp1);
  fseek(fp2 , 0 , SEEK_END);
  fileSize2 = ftell(fp2);
  rewind(fp2);
  if(fileSize1 != fileSize2)
    res=-1;
  else
    for(i=0;i<fileSize1;++i)
      if(fgetc(fp1) != fgetc(fp2))
        res=-1;
  fclose(fp1);fclose(fp2);
  rmlA0 = res?RML_TRUE:RML_FALSE; //mk_bcon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

int str_contain_char( const char* chars, const char chr)
{
  int length_of_chars = strlen(chars);
  int i;
  for(i = 0; i < length_of_chars; i++)
    {
      if(chr == chars[i])
        return 1;
    }
  return 0;
}

RML_BEGIN_LABEL(System__os)
{
  char *envvalue;
  envvalue = getenv("OS");
  if (envvalue == NULL) {
     rmlA0 = (void*) mk_scon("Windows_NT");
  } else {
      rmlA0 = (void*) mk_scon(envvalue);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*  this removes chars in second from the beginning and end of the first
    string and returns it */
RML_BEGIN_LABEL(System__trim)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *chars_to_be_removed = RML_STRINGDATA(rmlA1);
  int length=strlen(str);
  char *res = malloc(length+1);
  int i;
  int start_pos = 0;
  int end_pos = length - 1;
  if(length > 1)
    {
      strncpy(res,str,length);
      for(i=0; i < length; i++ )
        {

          if(str_contain_char(chars_to_be_removed,res[start_pos]))
            start_pos++;
          if(str_contain_char(chars_to_be_removed,res[end_pos]))
            end_pos--;
          if (start_pos == end_pos) break;
        }


      res[length] = '\0';
    }
  if(start_pos <= end_pos)
    {
      res[end_pos+1] = '\0';
      rmlA0 = (void*) mk_scon(&res[start_pos]);
    } else {
      rmlA0 = (void*) mk_scon("");
    }

  free(res);


  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__strcmp)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *str2 = RML_STRINGDATA(rmlA1);
  int res= strcmp(str,str2);

  rmlA0 = (void*) mk_icon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringFind)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *searchStr = RML_STRINGDATA(rmlA1);
  int strLen = strlen(str);
  int strSearchLen = strlen(searchStr);
  int i,retVal=-1;

  for (i=0; i< strLen - strSearchLen+1; i++) {
    if (strncmp(&str[i],searchStr,strSearchLen) == 0) {
      retVal = i;
      break;
    }
  }
  rmlA0 = (void*) mk_icon(retVal);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringFindString)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *searchStr = RML_STRINGDATA(rmlA1);
  int strLen = strlen(str);
  int strSearchLen = strlen(searchStr);
  int i,retVal=-1;

  for (i=0; i< strLen - strSearchLen+1; i++) {
    if (strncmp(&str[i],searchStr,strSearchLen) == 0) {
      retVal = i;
      break;
    }
  }
  if (retVal == -1)
    RML_TAILCALLK(rmlFC);
  rmlA0 = (void*) mk_scon(str+retVal);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__strncmp)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *str2 = RML_STRINGDATA(rmlA1);
  rml_sint_t len = RML_UNTAGFIXNUM(rmlA2);
  int res= strncmp(str,str2,len);

  rmlA0 = (void*) mk_icon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringReplace)
{
  char *str = /* strdup( */RML_STRINGDATA(rmlA0)/* ) */;
  char *source = /* strdup( */RML_STRINGDATA(rmlA1)/* ) */;
  char *target =/*  strdup( */RML_STRINGDATA(rmlA2)/* ) */;
  char * res=0;
/*   printf("in '%s' replace '%s' with '%s'\n",str,source,target); */

  /* adrpo 2006-05-15
   * if source and target are the same this function
   * cycles, get rid of that here
   * x08joekl 2008-02-5
   * fixed so that _replace handles target having source as a substring.
   */
  /*
   if (!strcmp(source, target))
     RML_TAILCALLK(rmlSC);
  */
  /* end adrpo */

  res = _replace(str,source,target);
  if (res == NULL)
  {
/*      printf("res == NULL\n");  */
    RML_TAILCALLK(rmlFC);
  }
  rmlA0 = (void*) mk_scon(res);
/*   printf("Replace result: '%s'\n",res); */
  free(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setCCompiler)
{
  char* str = RML_STRINGDATA(rmlA0);
  if (set_cc(str)) {
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
  char* str = RML_STRINGDATA(rmlA0);
  if (set_cxx(str)) {
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

RML_BEGIN_LABEL(System__setLinker)
{
  char* str = RML_STRINGDATA(rmlA0);
  if (set_linker(str)) {
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
  char* str = RML_STRINGDATA(rmlA0);
  if (set_cflags(str)) {
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
  char* str = RML_STRINGDATA(rmlA0);
  if (set_ldflags(str)) {
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

RML_BEGIN_LABEL(System__getExeExt)
{
  rmlA0 = (void*) mk_scon(".exe");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getDllExt)
{
  rmlA0 = (void*) mk_scon(".dll");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__loadLibrary)
{
  const char *str = RML_STRINGDATA(rmlA0);
  char libname[MAXPATHLEN];
  char currentDirectory[MAXPATHLEN];
  DWORD bufLen = MAXPATHLEN;
  modelica_ptr_t lib = NULL;
  modelica_integer libIndex;
  HMODULE h;
  /* adrpo: use BACKSLASH here as specified here: http://msdn.microsoft.com/en-us/library/ms684175(VS.85).aspx */
  GetCurrentDirectory(bufLen,currentDirectory);
#if defined(_MSC_VER)
  _snprintf(libname, MAXPATHLEN, "%s\\%s.dll", currentDirectory, str);
#else
  snprintf(libname, MAXPATHLEN, "%s\\%s.dll", currentDirectory, str);
#endif

  h = LoadLibrary(libname);
  if (h == NULL) {
    //fprintf(stderr, "Unable to load '%s': %lu.\n", libname, GetLastError());
    fflush(stderr);
    RML_TAILCALLK(rmlFC);
  }
  libIndex = alloc_ptr();
  if (libIndex < 0) {
    //fprintf(stderr, "Error loading library %s!\n", libname); fflush(stderr);
    FreeLibrary(h);
    h = NULL;
    RML_TAILCALLK(rmlFC);
  }
  lib = lookup_ptr(libIndex); // lib->cnt = 1
  lib->data.lib = h;
  rmlA0 = (void*) mk_icon(libIndex);
  if (check_debug_flag("dynload")) { fprintf(stderr, "LIB LOAD name[%s] index[%d] handle[%lu].\n", libname, libIndex, h); fflush(stderr); }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

void free_library(modelica_ptr_t lib)
{
  if (check_debug_flag("dynload")) { fprintf(stderr, "LIB UNLOAD handle[%lu].\n", lib->data.lib); fflush(stderr); }
  if (!FreeLibrary(lib->data.lib))
  {
    fprintf(stderr,"System.freeLibrary error code: %lu while unloading dll.\n", GetLastError());
    fflush(stderr);
  }
  lib->data.lib = NULL;
}

RML_BEGIN_LABEL(System__lookupFunction)
{
  modelica_integer libIndex = RML_UNTAGFIXNUM(rmlA0), funcIndex;
  const char *str = RML_STRINGDATA(rmlA1);
  modelica_ptr_t lib = NULL, func = NULL;
  function_t funcptr;

  lib = lookup_ptr(libIndex);

  if (lib == NULL)
    RML_TAILCALLK(rmlFC);

  funcptr = (void*)GetProcAddress(lib->data.lib, str);

  if (funcptr == NULL) {
    /*fprintf(stderr, "Unable to find `%s': %lu.\n", str, GetLastError());*/
    RML_TAILCALLK(rmlFC);
  }

  funcIndex = alloc_ptr();
  func = lookup_ptr(funcIndex);
  func->data.func.handle = funcptr;
  func->data.func.lib = libIndex;
  ++(lib->cnt); // lib->cnt = 2
  /* fprintf(stderr, "LOOKUP LIB index[%d]/count[%d]/handle[%lu] function %s[%d].\n", libIndex, lib->cnt, lib->data.lib, str, funcIndex); fflush(stderr); */
  rmlA0 = (void*) mk_icon(funcIndex);
  RML_TAILCALLK(rmlSC);
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

RML_BEGIN_LABEL(System__pathDelimiter)
{
  rmlA0 = (void*) mk_scon("/");

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__groupDelimiter)
{
  rmlA0 = (void*) mk_scon(";");

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

RML_BEGIN_LABEL(System__pwd)
{
  char buf[MAXPATHLEN];
  char* buf2;
  LPTSTR bufPtr=buf;
  DWORD bufLen = MAXPATHLEN;
  GetCurrentDirectory(bufLen,bufPtr);

  /* Make sure windows paths use fronslash and not backslash */
  buf2=_replace(buf,"\\","/");

  rmlA0 = (void*) mk_scon(buf2);
  free(buf2);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__writeFile)
{
  char* data = RML_STRINGDATA(rmlA1);
  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"w");
  if (file == NULL) {
    char *c_tokens[1]={filename};
    c_add_message(21, /* WRITING_FILE_ERROR */
      "SCRIPTING",
      "ERROR",
      "Error writing to file %s.",
      c_tokens,
      1);
    RML_TAILCALLK(rmlFC);
  }
  /* adrpo changed 2006-10-06
   * fprintf(file,"%s",data);
   */
  fwrite(RML_STRINGDATA(rmlA1), RML_HDRSTRLEN(RML_GETHDR(rmlA1)), 1, file);
  fflush(file);
  fclose(file);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__readFile)
{
  char* filename = RML_STRINGDATA(rmlA0);
  char* buf;
  int res;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0)
  {
    char *c_tokens[1]={filename};
    c_add_message(85, /* ERROR_OPENING_FILE */
      "SCRIPTING",
      "ERROR",
      "Error opening file %s.",
      c_tokens,
      1);
    rmlA0 = (void*) mk_scon("No such file");
    RML_TAILCALLK(rmlSC);
  }

  file = fopen(filename,"rb");
  buf = malloc(statstr.st_size+1);

  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size)
  {
  /* adrpo added 2004-10-26 */
  free(buf);
    rmlA0 = (void*) mk_scon("Failed while reading file");
    RML_TAILCALLK(rmlSC);
  }
  buf[statstr.st_size] = '\0';
  fclose(file);
  rmlA0 = (void*) mk_scon(buf);

  /* adrpo added 2004-10-26 */
  free(buf);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

int stringContains(char *str,char c){
  int i;
  for(i=0;i<strlen(str);++i)
    if(str[i]==c){
      //printf(" (#%d / %d)contained '%c' ('%c', __%s__)\t",i,strlen(str),str[i],c,str);
      return 1;
    }
  return 0;
}
int filterString(char* buf,char* bufRes){
    int res,i,bufPointer = 0,slen,isNumeric=0,numericEncounter=0;
    char preChar,cc;
    char filterChars[12] = "0123456789.\0";
    char numeric[11] = "0123456789\0";
    slen = strlen(buf);
    preChar = '\0';
    for(i=0;i<slen;++i){
      cc = buf[i];
      if((stringContains(filterChars,buf[i])))
      {
        if(buf[i]=='.'){
        if(stringContains(numeric,preChar) || (( i < slen+1) && stringContains(numeric,buf[i+1])) ){
          if(isNumeric == 0){isNumeric=1;numericEncounter++;}
          //printf("skipping_1: '%c'\n",buf[i]);
        }
        else{
          bufRes[bufPointer++] = buf[i];
          isNumeric=0;
        }
        }
        else
        {
          if(isNumeric == 0){isNumeric=1;numericEncounter++;}
          //printf("skipping_2: '%c'\n",buf[i]);
        }
      }
      else
      {
        bufRes[bufPointer++] = buf[i];
        isNumeric=0;
      }
      preChar = buf[i];
      //isNumeric=0;
    }
    bufRes[bufPointer++] = '\0';
    return numericEncounter;
}

RML_BEGIN_LABEL(System__readFileNoNumeric)
{
  char* filename = RML_STRINGDATA(rmlA0);
  char* buf, *bufRes;
  int res,i,bufPointer = 0,numCount;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0)
  {
    char *c_tokens[1]={filename};
    c_add_message(85, /* ERROR_OPENING_FILE */
      "SCRIPTING",
      "ERROR",
      "Error opening file %s.",
      c_tokens,
      1);
    rmlA0 = (void*) mk_scon("No such file");
    RML_TAILCALLK(rmlSC);
  }

  file = fopen(filename,"rb");
  buf = malloc(statstr.st_size+1);
  bufRes = malloc((statstr.st_size+70)*sizeof(char));
  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size)
  {
  /* adrpo added 2004-10-26 */
  free(buf);
    rmlA0 = (void*) mk_scon("Failed while reading file");
    RML_TAILCALLK(rmlSC);
  }
  buf[statstr.st_size] = '\0';
  numCount = filterString(buf,bufRes);
  fclose(file);
  sprintf(bufRes,"%s\nFilter count from numberic domain: %d",bufRes,numCount);

  rmlA0 = (void*) mk_scon(bufRes);

  /* adrpo added 2004-10-26 */
  free(buf);
  free(bufRes);

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

/* adrpo@ida added 2005-11-24 */
RML_BEGIN_LABEL(System__setEnv)
{
  char* envname = RML_STRINGDATA(rmlA0);
  char* envvalue = RML_STRINGDATA(rmlA1);
  rml_sint_t overwrite = RML_UNTAGFIXNUM(rmlA2);
  int setenv_result = 0;
  char *temp = (char*)malloc(strlen(envname)+strlen(envvalue)+2);
  sprintf(temp,"%s=%s", envname, envvalue);
  setenv_result = _putenv(temp);
  rmlA0 = (void*) mk_icon(setenv_result);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL



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

RML_BEGIN_LABEL(System__getVariableNames)
{
  char* model = RML_STRINGDATA(rmlA0);
  int size = getVariableListSize(model);
  char* lst = 0;

  if(!size)
    RML_TAILCALLK(rmlFC);

  lst = (char*)malloc(sizeof(char)*size +1);

  getVariableList(model, lst);
  rmlA0 = (void*)mk_scon(lst);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__time)
{
  double _time;
  clock_t cl;

  cl=clock();

  _time = (double)cl / (double)CLOCKS_PER_SEC;
  /*  printf("clock : %d\n",cl); */
  /* printf("returning time: %f\n",time);  */
  rmlA0 = (void*) mk_rcon(_time);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

#if !defined(_MSC_VER)
inline
#endif
RML_BEGIN_LABEL(System__hash)
{
  char *str = RML_STRINGDATA(rmlA0);
  int hash=0, c=0;
  while( c = *str++ ) hash +=c;
  rmlA0 = RML_IMMEDIATE(RML_TAGFIXNUM(hash));
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

RML_BEGIN_LABEL(System__getPackageFileNames)
{
  char* dir = RML_STRINGDATA(rmlA0);
  char* fileName = RML_STRINGDATA(rmlA1);
    char * strSearch = (char*)malloc(sizeof(char*)*(strlen(dir)+strlen(fileName)+10));
    char * tmpSearchString = (char*)malloc(sizeof(char*)*MAX_PATH);
    int mallocSize = MAX_PATH,current=0;
    char * retString = (char*)malloc(mallocSize*sizeof(char*));
    int ret_val;
    void *res;
    WIN32_FIND_DATA FileData;
    HANDLE sh;

    sprintf(strSearch,"%s\\*\0",dir);
  sh = FindFirstFile(strSearch, &FileData);

  if (sh == INVALID_HANDLE_VALUE) {
    printf(" invalid\n");
  }
  else {
    if ((FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
      sprintf(tmpSearchString,"%s\\%s\\%s",dir,FileData.cFileName,fileName);
      if(fileExistsLocal(tmpSearchString)==0){
        if(strlen(FileData.cFileName)+current>mallocSize){
          mallocSize *= 2;
          retString = (char *)realloc(retString,mallocSize);
        }
        if(current==0){
          sprintf(retString,"%s",FileData.cFileName);
        }
        else{
          sprintf(retString,",%s",FileData.cFileName);
        }
        current +=strlen(FileData.cFileName)+1;
      }
    }
  }
  while(FindNextFile(sh, &FileData) != 0){
    if ((FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
      sprintf(tmpSearchString,"%s\\%s\\%s",dir,FileData.cFileName,fileName);
      if(fileExistsLocal(tmpSearchString)==0){
        if(strlen(FileData.cFileName)+current>mallocSize){
          mallocSize *= 2;
          retString = (char *)realloc(retString,mallocSize);
        }
        if(current==0){
          sprintf(retString,"%s",FileData.cFileName);
        }
        else{
          sprintf(retString,"%s,%s",retString,FileData.cFileName);
        }
        current +=strlen(FileData.cFileName)+1;
      }
    }
  }
  FindClose(sh);
  //printf(" to return: %s\n",retString);
  rmlA0 = (void*) mk_scon(retString);
  free(strSearch);
  free(tmpSearchString);
  free(retString);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__directoryExists)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  void *res;
  WIN32_FIND_DATA FileData;
  HANDLE sh;
  if (str == NULL)
    RML_TAILCALLK(rmlFC);
  sh = FindFirstFile(str, &FileData);
  if (sh == INVALID_HANDLE_VALUE) {
    ret_val = 1;
  }
  else {
    if ((FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0) {
      ret_val = 1;
    }
    else {
      ret_val = 0;
    }
    FindClose(sh);
  }
  rmlA0 = (void*) mk_icon(ret_val);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__regularFileExists)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  void *res;
  WIN32_FIND_DATA FileData;
  HANDLE sh;

  if (str == NULL)
    RML_TAILCALLK(rmlFC);

  sh = FindFirstFile(str, &FileData);
  if (sh == INVALID_HANDLE_VALUE) {
    ret_val = 1;
  }
  else {
    if ((FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
      ret_val = 1;
    }
    else {
      ret_val = 0;
    }
    FindClose(sh);
  }

  rmlA0 = (void*) mk_icon(ret_val);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__removeFile)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  ret_val = remove(str);

  rmlA0 = (void*) mk_icon(ret_val);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


#ifdef WIN32
RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("WIN32");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
#elif CYGWIN
RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("CYGWIN");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
#else

RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("");
  RML_TAILCALLK(rmlSC);
}
#endif

RML_BEGIN_LABEL(System__realCeil)
{
  rmlA0 = rml_prim_mkreal(ceil(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__asin)
{
  rmlA0 = rml_prim_mkreal(asin(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__acos)
{
  rmlA0 = rml_prim_mkreal(acos(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__atan)
{
  rmlA0 = rml_prim_mkreal(atan(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__atan2)
{
  rmlA0 = rml_prim_mkreal(atan2(rml_prim_get_real(rmlA0),
        rml_prim_get_real(rmlA1)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__cosh)
{
  rmlA0 = rml_prim_mkreal(cosh(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__log)
{
  rmlA0 = rml_prim_mkreal(log(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__log10)
{
  rmlA0 = rml_prim_mkreal(log10(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__sinh)
{
  rmlA0 = rml_prim_mkreal(sinh(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tanh)
{
  rmlA0 = rml_prim_mkreal(tanh(rml_prim_get_real(rmlA0)));
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

//void* generate_array(char type, int curdim, type_description *desc, void *data)
//
//{
//  void *lst;
//  double rval;
//  int ival;
//  int i;
//  lst = (void*)mk_nil();
//  if (curdim == desc->ndims)
//  {
//    for (i=0; i< desc->dim_size[curdim-1]; i++)
//    {
//      if (type == 'r')
//      {
//      rval = next_realelt((double*)data);
//      lst = (void*)mk_cons(Values__REAL(mk_rcon(rval)),lst);
//      }
//      else if (type == 'i')
//      {
//      ival = next_intelt((int*)data);
//      lst = (void*)mk_cons(Values__INTEGER(mk_icon(ival)),lst);
//      }
//      else if (type == 'b')
//      {
//      rval = next_realelt((double*)data);
//      lst = (void*)mk_cons(Values__BOOL(rval?RML_TRUE:RML_FALSE/*mk_bcon(rval)*/),lst);
//      }
//    }
//  }
//  else
//  {
//    for (i=0; i< desc->dim_size[curdim-1]; i++) {
//    lst = (void*)mk_cons(Values__ARRAY(generate_array(type,curdim+1,desc,data)),lst);
//  }
//  }
//  return lst;
//}

char* class_names_for_simulation = NULL;
RML_BEGIN_LABEL(System__getClassnamesForSimulation)
{
  if(class_names_for_simulation)
    rmlA0 = (void*) mk_scon(strdup(class_names_for_simulation));
  else
    rmlA0 = (void*) mk_scon("{}");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setClassnamesForSimulation)
{
  char* class_names = RML_STRINGDATA(rmlA0);
  if(class_names_for_simulation)
    free(class_names_for_simulation);

  class_names_for_simulation = strdup(class_names);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__getVariableValue)
{
  double timeStamp   = rml_prim_get_real(rmlA0);
  void *timeValues   = rmlA1;
  void *varValues   = rmlA2;

  // values to find the correct range
  double preValue   = 0.0;
  double preTime   = 0.0;
  double nowValue   = 0.0;
  double nowTime   = 0.0;

  // linjear interpolation data
  double timedif       = 0.0;
  double valuedif      = 0.0;
  double valueSlope      = 0.0;
  double timeDifTimeStamp  = 0.0;

  // break loop and return value
  int valueFound = 0;
  double returnValue = 0.0;

for(; RML_GETHDR(timeValues) == RML_CONSHDR && valueFound == 0; timeValues = RML_CDR(timeValues), varValues = RML_CDR(varValues)) {


    nowValue   = rml_prim_get_real(RML_CAR(varValues));
    nowTime   =  rml_prim_get_real(RML_CAR(timeValues));


  if(timeStamp == nowTime){
      valueFound   = 1;
      returnValue = nowValue;

    } else if (timeStamp >= preTime && timeStamp <= nowTime) { // need to do interpolation
      valueFound       = 1;
      timedif       = nowTime - preTime;
      valuedif      = nowValue - preValue;
      valueSlope       = valuedif / timedif;
      timeDifTimeStamp   = timeStamp - preTime;
      returnValue     = preValue + (valueSlope*timeDifTimeStamp);
      /*
      printf("\t ### Interpolation ###");
      printf("nowTime: %f", nowTime);
      printf("\n");
      printf("preTime: %f", preTime);
      printf("\n");
      printf("nowValue: %f", nowValue);
      printf("\n");
      printf("preValue: %f", preValue);
      printf("\n");

    printf("timedif: %f", timedif);
      printf("\n");
      printf("valuedif: %f", valuedif);
      printf("\n");
      printf("valueSlope: %f", valueSlope);
      printf("\n");
      printf("timeDifTimeStamp: %f", timeDifTimeStamp);
      printf("\n");
      printf("returnValue: %f", returnValue);
      printf("\n");
    */
  } else {
    preValue   = nowValue;
      preTime   = nowTime;

  }

  }
  if(valueFound == 0){
    // value could not be found in the dataset, what do we do?
      printf("\n WARNING: timestamp(%f) outside simulation timeline \n",timeStamp);
    RML_TAILCALLK(rmlFC);
  } else {

      rmlA0 = (void*)mk_rcon(returnValue);
      RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL

RML_BEGIN_LABEL(System__sendData)
{





  char* data = RML_STRINGDATA(rmlA0);
  char* interpolation = RML_STRINGDATA(rmlA1);
 char* title = RML_STRINGDATA(rmlA2);
 int legend = RML_UNTAGFIXNUM(rmlA3); //RML_STRINGDATA(rmlA3);
 int grid = RML_UNTAGFIXNUM(rmlA4); //RML_STRINGDATA(rmlA4);
 int logX = RML_UNTAGFIXNUM(rmlA5); //RML_STRINGDATA(rmlA5);
 int logY = RML_UNTAGFIXNUM(rmlA6); //RML_STRINGDATA(rmlA6);
 char* xLabel = RML_STRINGDATA(rmlA7);
 char* yLabel = RML_STRINGDATA(rmlA8);
 int points = RML_UNTAGFIXNUM(rmlA9);
  char* range = RML_STRINGDATA(rmlA10);
 //char* yRange = RML_STRINGDATA(rmlA11);
//  emulateStreamData(data, 7778);


//  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, "linear", 1);
///  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, interpolation, 1);

//  emulateStreamData(data, 7778, title, "time", "", legend, grid, 0, 0, 0, 0, logX, logY, interpolation, 1);
  emulateStreamData(data, title, xLabel, yLabel , interpolation, legend, grid, logX, logY, points, range);

//  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, "linear");

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__enableSendData)
{
  int enable = RML_UNTAGFIXNUM(rmlA0);
  if(enable)
    _putenv("enableSendData=1");
  else
    _putenv("enableSendData=0");


//  enableSendData(enable);
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setDataPort)
{
  int port = RML_UNTAGFIXNUM(rmlA0);

    char* dataport = malloc(25);
    sprintf(dataport,"sendDataPort=%s", port);
    _putenv(dataport);
    free(dataport);
//  setDataPort(port);
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
RML_BEGIN_LABEL(System__setVariableFilter)
{
  char * variables = RML_STRINGDATA(rmlA0);
  char* filter=malloc(strlen(variables)+20);
  sprintf(filter, "sendDataFilter=%s",variables);
  _putenv(filter);
  free(filter);
//  setVariableFilter(variables);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__sendData2)
{
  char* info = RML_STRINGDATA(rmlA0);
  char* data = RML_STRINGDATA(rmlA1);
  emulateStreamData2(info, data, 7778);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

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

RML_BEGIN_LABEL(System__getCurrentTime)
{
  time_t t;
  double elapsedTime;             // the time elapsed as double
  time( &t );
  rmlA0 = mk_rcon(difftime(t, 0)); // the current time
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


#else /********************************* LINUX PART!!! *************************************/

#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <sys/param.h> /* MAXPATHLEN */
#include <ctype.h>

/* MacOS malloc.h is in sys */
#ifndef __APPLE_CC__
#include <malloc.h>
#else
#define HAVE_SCANDIR
#include <sys/malloc.h>
#endif

#ifndef _IFDIR
# ifdef S_IFDIR
#  define _IFDIR S_IFDIR
# else
#  error "Neither _IFDIR nor S_IFDIR is defined."
# endif
#endif

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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

static struct modelica_ptr_s ptr_vector[MAX_PTR_INDEX];
static modelica_integer last_ptr_index = -1;

void System_5finit(void)
{
  char* qthome;
  char sendDataLibs[3000] = {0};

  last_ptr_index = -1;
  memset(ptr_vector, 0, sizeof(ptr_vector));

  set_cc("g++");
  set_cxx("g++");
#if defined(__sparc__)
  set_linker("g++ -G");
#elif defined(__APPLE_CC__)
  set_linker("g++ -single_module -dynamiclib -flat_namespace");
#elif defined(__x86_64__)
  /* -fPIC needed on x86_64! */
  set_linker("g++ -shared -export-dynamic -fPIC");
#else
  set_linker("g++ -shared -export-dynamic");
#endif

#if defined(__i386__) || defined(__x86_64__)
  /*
   * if we are on i386 or x86_64 then use the
   * SSE instructions, not the normal i387 FPU
   */
  set_cflags("-msse2 -mfpmath=sse ${MODELICAUSERCFLAGS}");
#else
  set_cflags("${MODELICAUSERCFLAGS}");
#endif
  set_ldflags("-lc_runtime");

  putenv(LDFLAGS_SENDDATA /* Defined in the Makefile; from the configure script */);
   /* set the SENDDATALIBS environment variable */
  putenv(strdup(sendDataLibs));
}

/**
 * Author BZ
 * helper function for getSymbolicLinkPath
 **/
char *mergePathWithLink(char *path,char *linkPath)
{
    char *lastSlash;
    char *newPath = (char *) malloc(sizeof(char)*MAXPATHLEN);
    //printf(" entered mergePathWithLink, path: %s, link: %s\n",path,linkPath);
    if(linkPath[0] =='/') // if link is non relative
  return linkPath;
    // else; replace ......./link with ..../link_result
    lastSlash = strrchr(path,'/')+1;
    *lastSlash = '\0';
    strncpy(newPath,path,lastSlash-path+1);
    strcat(newPath,linkPath);
    free(linkPath);
return newPath;
}

/**
 * Author BZ, 2008-09
 * helper function for findSymbolicLinks
 * This function evaluates each directory/file and if it is a symbolic link, call mergePathWithLink
 * to produce resulting path ( if a link is refering to a relative dir or not).
 *
 * */
char *getSymbolicLinkPath(char* path)
{
    int err,readChars;
    char *buffer;
    struct stat ss;

    err = lstat(path,&ss);
    //printf(" check existence %s\n",path);
    if(err==0){ // file exists
      //printf("okay succ %s, %d\n",path,ss.st_mode);
      if(S_ISLNK(ss.st_mode))
      {
          //printf("*** is link *** %s\n",path);
          buffer = (char *) malloc(sizeof(char)*MAXPATHLEN);
          readChars = readlink (path, buffer, MAXPATHLEN);
          if(readChars >0){
            buffer[readChars]='\0';
            buffer = mergePathWithLink(path,buffer);
            free(path);
            path = buffer;
            //printf(" have %s from symolic link\n",path);
            path = getSymbolicLinkPath(path);
            //printf(" after recursive call, terminating; %s\n\n",path);
          }
          else if(readChars==-1){
            free(buffer);
          }
      }
      return path;
    }
    else{
        //printf(" no existing: %s\n",path);
      return path;
    }
}
/**
 * Author BZ, 2008-09
 * This function traverses all directories searching for symbolic links like;
 * home/bjozac/linkToNewDir/a.mo
 * 1) isLink(/home) "then get link path"
 * 2) isLink(/home/bjozac/) same as above, do nothing
 * 3) isLink(/home/bjozac/linkToNewDir) => true, new path: /home/bjozac/NewDir/
 * 4) isLink(/home/bjozac/newDir/a.mo)
 **/
char* findSymbolicLinks(char* path)
{
    int readChars=0,pointer=0,i;
    char *curRes = (char *) malloc(sizeof(char)*MAXPATHLEN);
    char *destPos;
    char *curPos;
    char *endPos;
    curRes[0]='\0';
    curPos = path;
    if(path[0]=='/'){
  curRes = strcat(curRes,"/");
        curPos = &path[1]; // skip first slash, will add when finished.
    }

    for(i=0;i<100;++i){
        endPos = strchr(curPos,'/');
        if(endPos==NULL){ // End OF String
      endPos = strrchr(curPos,'\0');
      strncat(curRes,curPos,endPos-curPos); // add filename
      //printf(" check: %s ==> " ,curRes);
      curRes = getSymbolicLinkPath(curRes);
      //printf("\tbecame: %s\n",curRes);
      free(path);
          return curRes;
  }
  strncat(curRes,curPos,endPos-curPos);
  curRes = getSymbolicLinkPath(curRes);
  if(curRes[strlen(curRes)-1] != '/')
          strcat(curRes,"/");
  //printf("path: %s\n",curRes);
  curPos = endPos+1;
    }
    if(strchr(path,'/')!=NULL)
  fprintf(stderr,"possible error in save-function\n");
    free(path);
    return curRes;
}


/* Normalize a path i.e. transforms /usr/local/..//lib to /usr/lib
   returns NULL on failure.

*/
char* normalizePath(const char* src)
{
  const char* srcEnd = src + strlen(src);
  const char* srcPos = src;
  char* dest;
  char* targetPos = dest;
  char* newSrcPos = NULL;
  char* p = NULL;
  char* tmp;
  int appendSlash = 0;

  if (strlen(src) == 0) {
    return NULL;
  }

  if (src[0] != '/') {
    /* it is a relative path, so prepend cwd */
    tmp = malloc(1024);
    p = getcwd(tmp, 1024);
    if (p == NULL) {
      free(tmp);
      return NULL;
    }
    dest = malloc(strlen(src) + strlen(p) + 2);
    strcpy(dest, p);
    free(p);
    targetPos = dest + strlen(dest);
    if (dest[strlen(dest) - 1] != '/') {
      appendSlash = 1;
    }
  }
  else {
    /* absolute path */
    dest = malloc(strlen(src) + 2);
    dest[0] = '\0';
    targetPos = dest;
    appendSlash = 1;
  }

  while (srcPos < srcEnd) {
    if (strstr(srcPos, "..") == (srcPos)) {
      /* found .. remove last part of the path in dest */
      p = strrchr(dest, '/');
      if (p == NULL) {
        p = dest;
        appendSlash = 0;
      }
      p[0] = '\0';
      targetPos = p;
      /* seek next / in src */
      srcPos = strchr(srcPos, '/');
      if (srcPos == NULL) {
        break;
      }
      srcPos = srcPos + 1; /* skip the found / */
      continue;
    }
    if (appendSlash) {
      targetPos[0] = '/';
      targetPos++;
      targetPos[0] = '\0'; /* always null terminate so that dest is a valid string */
    }
    newSrcPos = strchr(srcPos, '/');
    /* printf("dest = %s\n", dest); */
    /* printf("srcPos = %s\n", srcPos); */
    /* printf("newSrcPos = %s\n", newSrcPos); */
    if (newSrcPos == NULL) {
      /* did not find any more / copy rest of string and end */
      strcpy(targetPos, srcPos);
      break;
    }
    if (newSrcPos == srcPos) {
      /* skip multiple / */
      srcPos = srcPos + 1;
      appendSlash = 0;
      continue;
    }
    strncpy(targetPos, srcPos, newSrcPos - srcPos);
    targetPos = targetPos + (newSrcPos - srcPos);
    srcPos = newSrcPos + 1; /* + 1 to skip the found / */
    appendSlash = 1;
  }
  //printf("calling: -->%s<--\n" ,dest);
  dest = findSymbolicLinks(dest);
  //printf(" RES:  %s\n",dest);
  return dest;
}
/*
*/

RML_BEGIN_LABEL(System__isSameFile)
{
  char* fileName1 = RML_STRINGDATA(rmlA0);
  char* fileName2 = RML_STRINGDATA(rmlA1);
  char* normPath1 = normalizePath(fileName1);
  char* normPath2 = normalizePath(fileName2);
  int same = 0;
  if (normPath1 == NULL || normPath2 == NULL) {
    if (normPath1) free(normPath1);
    if (normPath2) free(normPath2);
    RML_TAILCALLK(rmlFC);
  }

  same = strcmp(normPath1, normPath2) == 0;
  free(normPath1);
  free(normPath2);
  if (same) {
    RML_TAILCALLK(rmlSC);
  }
  else {
    RML_TAILCALLK(rmlFC);
  }
}
RML_END_LABEL

RML_BEGIN_LABEL(System__strtok)
{
  char *s;
  char *delimit = RML_STRINGDATA(rmlA1);
  char *str = strdup(RML_STRINGDATA(rmlA0));

  void * res = (void*)mk_nil();
  s=strtok(str,delimit);
  if (s == NULL)
  {
    /* adrpo added 2004-10-27 */
    free(str);
    rmlA0=res; RML_TAILCALLK(rmlFC);
  }
  res = (void*)mk_cons(mk_scon(s),res);
  while (s=strtok(NULL,delimit))
  {
    res = (void*)mk_cons(mk_scon(s),res);
  }
  rmlA0=res;

  /* adrpo added 2004-10-27 */
  free(str);

  /* adrpo changed 2004-10-29
  rml_prim_once(RML__list_5freverse);
  RML_TAILCALLK(rmlSC);
  */
  RML_TAILCALLQ(RML__list_5freverse,1);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__toupper)
{
  char *str = strdup(RML_STRINGDATA(rmlA0));
  char *res=str;
  while (*str!= '\0')
  {
    *str=toupper(*str++);
  }
  rmlA0 = (void*) mk_scon(res);

  /* adrpo added 2004-10-29 */
  free(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__removeFirstAndLastChar)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *res = "";
  int length=strlen(str);
  if(length > 1)
    {
      res=malloc(length-1);
      strncpy(res,str + 1,length-2);

      res[length-1] = '\0';
    }
  rmlA0 = (void*) mk_scon(res);
  /* adrpo added 2004-10-29 */
  free(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

int str_contain_char( const char* chars, const char chr)
{
  int length_of_chars = strlen(chars);
  int i;
  for(i = 0; i < length_of_chars; i++)
    {
      if(chr == chars[i])
        return 1;
    }
  return 0;
}

RML_BEGIN_LABEL(System__os)
{
  rmlA0 = (void*) mk_scon("linux");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*  this removes chars in second from the beginning and end of the first
    string and returns it */
RML_BEGIN_LABEL(System__trim)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *chars_to_be_removed = RML_STRINGDATA(rmlA1);
  int length=strlen(str);
  char *res = malloc(length+1);
  int i;
  int start_pos = 0;
  int end_pos = length - 1;
  if(length > 1)
    {
      strncpy(res,str,length);
      for(i=0; i < length; i++ )
        {

          if(str_contain_char(chars_to_be_removed,res[start_pos]))
            start_pos++;
          if(str_contain_char(chars_to_be_removed,res[end_pos]))
            end_pos--;
          if (start_pos == end_pos) break;
        }


      res[length] = '\0';
    }
  if(start_pos <= end_pos)
    {
      res[end_pos+1] = '\0';
      rmlA0 = (void*) mk_scon(&res[start_pos]);
    } else {
      rmlA0 = (void*) mk_scon("");
    }

  free(res);


  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__strcmp)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *str2 = RML_STRINGDATA(rmlA1);
  int res= strcmp(str,str2);

  rmlA0 = (void*) mk_icon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringFind)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *searchStr = RML_STRINGDATA(rmlA1);
  int strLen = strlen(str);
  int strSearchLen = strlen(searchStr);
  int i,retVal=-1;

  for (i=0; i< strLen - strSearchLen+1; i++) {
    if (strncmp(&str[i],searchStr,strSearchLen) == 0) {
        retVal = i;
        break;
    }
  }
  rmlA0 = (void*) mk_icon(retVal);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__stringFindString)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *searchStr = RML_STRINGDATA(rmlA1);
  int strLen = strlen(str);
  int strSearchLen = strlen(searchStr);
  int i,retVal=-1;

  for (i=0; i< strLen - strSearchLen+1; i++) {
    if (strncmp(&str[i],searchStr,strSearchLen) == 0) {
      retVal = i;
      break;
    }
  }
  if (retVal == -1)
    RML_TAILCALLK(rmlFC);
  rmlA0 = (void*) mk_scon(str+retVal);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__strncmp)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *str2 = RML_STRINGDATA(rmlA1);
  rml_sint_t len = RML_UNTAGFIXNUM(rmlA2);
  int res= strncmp(str,str2,len);

  rmlA0 = (void*) mk_icon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__isIdenticalFile)
{
  char *fileName1 = RML_STRINGDATA(rmlA0);
  char *fileName2 = RML_STRINGDATA(rmlA1);
  char emptyString[5] = "empty";
  int res=1,i;
  FILE *fp1,*fp2,*d1,*d2;
  long fileSize1,fileSize2;
  fp1 = fopen(fileName1, "r");

  if(!fp1){
    //printf("Error opening the file: %s, creating it\n",fileName1);
    d1 = fopen(fileName1,"w+");
    for(i=0;i<5;++i)
      fputc(emptyString[i],d1);
    fclose(d1);
  }
  fp1 = fopen(fileName1, "r");
  fp2 = fopen(fileName2, "r");
  if(!fp2){
      //printf("Error opening the file(#2): %s\n",fileName2);
     rmlA0 = RML_FALSE/*mk_bcon(-1)*/;
      RML_TAILCALLK(rmlSC);
    }
  fseek(fp1 , 0 , SEEK_END);
  fileSize1 = ftell(fp1);
  rewind(fp1);
  fseek(fp2 , 0 , SEEK_END);
  fileSize2 = ftell(fp2);
  rewind(fp2);
  if(fileSize1 != fileSize2)
    res=-1;
  else
    for(i=0;i<fileSize1;++i)
      if(fgetc(fp1) != fgetc(fp2))
        res=-1;
  fclose(fp1);fclose(fp2);
  rmlA0 = res?RML_FALSE:RML_TRUE/*mk_bcon(res)*/;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__stringReplace)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *source = RML_STRINGDATA(rmlA1);
  char *target = RML_STRINGDATA(rmlA2);
  char * res=0;

  /* adrpo 2006-05-15
   * if source and target are the same this function
   * cycles, get rid of that here
   * x08joekl 2008-02-5
   * fixed so that _replace handles target having source as a substring.
   */
  /*
   if (!strcmp(source, target))
     RML_TAILCALLK(rmlSC);
  */
  /* end adrpo */

  res = _replace(str,source,target);

  if (res == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  rmlA0 = (void*) mk_scon(res);
  free(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setCCompiler)
{
  char* str = RML_STRINGDATA(rmlA0);
  if(set_cc(str))  {
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
  char* str = RML_STRINGDATA(rmlA0);
  if (set_cxx(str)) {
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

RML_BEGIN_LABEL(System__setLinker)
{
  char* str = RML_STRINGDATA(rmlA0);
  if (set_linker(str)) {
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
  char* str = RML_STRINGDATA(rmlA0);
  if (set_cflags(str)) {
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
  char* str = RML_STRINGDATA(rmlA0);
  if (set_ldflags(str)) {
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

RML_BEGIN_LABEL(System__getExeExt)
{
  rmlA0 = (void*) mk_scon("");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getDllExt)
{
  rmlA0 = (void*) mk_scon(".so");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* errorext.h is a C++ header... */
void c_add_message(int errorID, char* type, char* severity,
    char* message, char** ctokens, int nTokens);

RML_BEGIN_LABEL(System__loadLibrary)
{
  const char *str = RML_STRINGDATA(rmlA0);
  char libname[MAXPATHLEN];
  modelica_ptr_t lib = NULL;
  modelica_integer libIndex;
  void *h;
  char* ctokens[2];
  snprintf(libname, MAXPATHLEN, "./%s.so", str);
  h = dlopen(libname, RTLD_LOCAL | RTLD_NOW);
  if (h == NULL) {
    ctokens[0] = dlerror();
    ctokens[1] = libname;
    c_add_message(-1, "RUNTIME", "ERROR", "OMC unable to load `%s': %s.\n", ctokens, 2);
    RML_TAILCALLK(rmlFC);
  }
  libIndex = alloc_ptr();
  if (libIndex < 0) {
    fprintf(stderr, "Error loading library %s!\n", libname); fflush(stderr);
    dlclose(h);
    RML_TAILCALLK(rmlFC);
  }
  lib = lookup_ptr(libIndex);
  lib->data.lib = h;
  rmlA0 = (void*) mk_icon(libIndex);
  if (check_debug_flag("dynload"))
  {
    fprintf(stderr, "LIB LOAD [%s].\n", libname, lib->cnt, libIndex, h); fflush(stderr);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

void free_library(modelica_ptr_t lib)
{
  if (check_debug_flag("dynload")) { fprintf(stderr, "LIB UNLOAD handle[%lu].\n", (unsigned long) lib->data.lib); fflush(stderr); }
  if (dlclose(lib->data.lib))
  {
    /* report an error here!
    fprintf(stderr,"System.freeLibrary error code: %lu while unloading dll.\n", );
    fflush(stderr);
    */
  }
  lib->data.lib = NULL;
}

RML_BEGIN_LABEL(System__lookupFunction)
{
  modelica_integer libIndex = RML_UNTAGFIXNUM(rmlA0), funcIndex;
  const char *str = RML_STRINGDATA(rmlA1);
  modelica_ptr_t lib = NULL, func = NULL;
  function_t funcptr;

  lib = lookup_ptr(libIndex);

  if (lib == NULL)
    RML_TAILCALLK(rmlFC);

  funcptr = dlsym(lib->data.lib, str);

  if (funcptr == NULL) {
    fprintf(stderr, "Unable to find `%s': %s.\n", str, dlerror());
    RML_TAILCALLK(rmlFC);
  }

  funcIndex = alloc_ptr();
  func = lookup_ptr(funcIndex);
  func->data.func.handle = funcptr;
  func->data.func.lib = libIndex;
  ++(lib->cnt);
  rmlA0 = (void*) mk_icon(funcIndex);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__compileCFile)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  char exename[255];
  char *tmp;

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

#ifndef __APPLE_CC__  /* seems that we need to disable this on MacOS */
  putenv("GCC_EXEC_PREFIX=");
#endif
  tmp = getenv("MODELICAUSERCFLAGS");
  if (tmp == NULL || tmp[0] == '\0'  ) {
    putenv("MODELICAUSERCFLAGS=  ");
  }
  if (system(command) != 0) {
    RML_TAILCALLK(rmlFC);
  }

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

RML_BEGIN_LABEL(System__pwd)
{
  char buf[MAXPATHLEN];
  if (NULL == getcwd(buf,MAXPATHLEN)) {
    fprintf(stderr, "System.pwd failed\n");
    rmlA0 = (void*) mk_scon("$invalid_path$");
  } else {
    rmlA0 = (void*) mk_scon(buf);
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__writeFile)
{
  char* data = RML_STRINGDATA(rmlA1);
  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"w");
  if (file == NULL) {
    char *c_tokens[1]={filename};
    c_add_message(21, /* WRITING_FIvalue_to_type_descLE_ERROR */
      "SCRIPTING",
      "ERROR",
      "Error writing to file %s.",
      c_tokens,
      1);
    RML_TAILCALLK(rmlFC);
  }
  /* adrpo changed 2006-10-06
   * fprintf(file,"%s",data);
   */
  fwrite(RML_STRINGDATA(rmlA1), RML_HDRSTRLEN(RML_GETHDR(rmlA1)), 1, file);
  fflush(file);
  fclose(file);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__readFile)
{
  char* filename = RML_STRINGDATA(rmlA0);
  char* buf;
  int res;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0)
  {
    char *c_tokens[1]={filename};
    c_add_message(85, /* ERROR_OPENING_FILE */
      "SCRIPTING",
      "ERROR",
      "Error opening file %s.",
      c_tokens,
      1);
    rmlA0 = (void*) mk_scon("No such file");
    RML_TAILCALLK(rmlSC);
  }

  file = fopen(filename,"rb");
  buf = malloc(statstr.st_size+1);

  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size)
  {
  /* adrpo added 2004-10-26 */
  free(buf);
    rmlA0 = (void*) mk_scon("Failed while reading file");
    RML_TAILCALLK(rmlSC);
  }
  buf[statstr.st_size] = '\0';
  fclose(file);
  rmlA0 = (void*) mk_scon(buf);

  /* adrpo added 2004-10-26 */
  free(buf);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

int stringContains(char *str,char c){
  int i;
  for(i=0;i<strlen(str);++i)
    if(str[i]==c){
      //printf(" (#%d / %d)contained '%c' ('%c', __%s__)\t",i,strlen(str),str[i],c,str);
      return 1;
    }
  return 0;
}
int filterString(char* buf,char* bufRes){
    int res,i,bufPointer = 0,slen,isNumeric=0,numericEncounter=0;
    char preChar,cc;
    char filterChars[12] = "0123456789.\0";
    char numeric[11] = "0123456789\0";
    slen = strlen(buf);
    preChar = '\0';
    for(i=0;i<slen;++i){
      cc = buf[i];
      if((stringContains(filterChars,buf[i])))
      {
        if(buf[i]=='.'){
        if(stringContains(numeric,preChar) || (( i < slen+1) && stringContains(numeric,buf[i+1])) ){
          if(isNumeric == 0){isNumeric=1;numericEncounter++;}
          //printf("skipping_1: '%c'\n",buf[i]);
        }
        else{
          bufRes[bufPointer++] = buf[i];
          isNumeric=0;
        }
        }
        else
        {
          if(isNumeric == 0){isNumeric=1;numericEncounter++;}
          //printf("skipping_2: '%c'\n",buf[i]);
        }
      }
      else
      {
        bufRes[bufPointer++] = buf[i];
        isNumeric=0;
      }
      preChar = buf[i];
      //isNumeric=0;
    }
    bufRes[bufPointer++] = '\0';
    return numericEncounter;
}

RML_BEGIN_LABEL(System__readFileNoNumeric)
{
  char* filename = RML_STRINGDATA(rmlA0);
  char* buf, *bufRes;
  int res,i,bufPointer = 0,numCount;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0)
  {
    char *c_tokens[1]={filename};
    c_add_message(85, /* ERROR_OPENING_FILE */
      "SCRIPTING",
      "ERROR",
      "Error opening file %s.",
      c_tokens,
      1);
    rmlA0 = (void*) mk_scon("No such file");
    RML_TAILCALLK(rmlSC);
  }

  file = fopen(filename,"rb");
  buf = malloc(statstr.st_size+1);
  bufRes = malloc((statstr.st_size+70)*sizeof(char));
  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size)
  {
  /* adrpo added 2004-10-26 */
  free(buf);
    rmlA0 = (void*) mk_scon("Failed while reading file");
    RML_TAILCALLK(rmlSC);
  }
  buf[statstr.st_size] = '\0';
  numCount = filterString(buf,bufRes);
  fclose(file);
  sprintf(bufRes,"%s\nFilter count from numberic domain: %d",bufRes,numCount);

  rmlA0 = (void*) mk_scon(bufRes);

  /* adrpo added 2004-10-26 */
  free(buf);
  free(bufRes);

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

RML_BEGIN_LABEL(System__readEnv)
{
  char* envname = RML_STRINGDATA(rmlA0);
  char *envvalue = getenv(envname);
  if (envvalue == NULL)
  {
    RML_TAILCALLK(rmlFC);
  }
  rmlA0 = (void*) mk_scon(envvalue);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* adrpo@ida added 2005-11-24 */
RML_BEGIN_LABEL(System__setEnv)
{
  char* envname = RML_STRINGDATA(rmlA0);
  char* envvalue = RML_STRINGDATA(rmlA1);
  rml_sint_t overwrite = RML_UNTAGFIXNUM(rmlA2);
  int setenv_result = 0;
  setenv_result = setenv(envname, envvalue, (int)overwrite);
  rmlA0 = (void*) mk_icon(setenv_result);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


char *select_from_dir;

int file_select_directories(const struct dirent *entry)
{
  char fileName[MAXPATHLEN];
  int res;
  struct stat fileStatus;
  if ((strcmp(entry->d_name, ".") == 0) ||
      (strcmp(entry->d_name, "..") == 0)) {
    return (0);
  } else {
    sprintf(fileName,"%s/%s",select_from_dir,entry->d_name);
    res = stat(fileName,&fileStatus);
    if (res!=0) return 0;
    if ((fileStatus.st_mode & _IFDIR))
      return (1);
    else
      return (0);
  }
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

int file_select_mo(const struct dirent *entry)
{
  char fileName[MAXPATHLEN];
  int res; char* ptr;
  struct stat fileStatus;
  if ((strcmp(entry->d_name, ".") == 0) ||
      (strcmp(entry->d_name, "..") == 0) ||
      (strcmp(entry->d_name, "package.mo") == 0)) {
    return (0);
  } else {
    ptr = (char*)rindex(entry->d_name, '.');
    if ((ptr != NULL) &&
  ((strcmp(ptr, ".mo") == 0))) {
      return (1);
    } else {
      return (0);
    }
  }
}

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

RML_BEGIN_LABEL(System__getVariableNames)
{
  char* model = RML_STRINGDATA(rmlA0);
  int size = getVariableListSize(model);

  if(!size)
    RML_TAILCALLK(rmlFC);

  char* lst = (char*)malloc(sizeof(char)*size +1);

  getVariableList(model, lst);
  rmlA0 = (void*)mk_scon(lst);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__time)
{
  double time;
  clock_t cl;

  cl=clock();

  time = (double)cl / (double)CLOCKS_PER_SEC;
  /*  printf("clock : %d\n",cl); */
  /* printf("returning time: %f\n",time);  */
  rmlA0 = (void*) mk_rcon(time);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

inline RML_BEGIN_LABEL(System__hash)
{
  char *str = RML_STRINGDATA(rmlA0);
  long hash=0, c=0;
  while( c = *str++ ) hash +=c;
  rmlA0 = RML_IMMEDIATE(RML_TAGFIXNUM(hash));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__pathDelimiter)
{
  rmlA0 = (void*) mk_scon("/");

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__groupDelimiter)
{
  rmlA0 = (void*) mk_scon(":");

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

char *path_cat (const char *str1, char *str2,char *fileString) {
    size_t str1_len = strlen(str1),str2_len = strlen(str2);
    struct stat buf;
    char *result;
    int ret_val;

    result = (char *)malloc(PATH_MAX*sizeof( *result));
    if(strcmp(str2,"..") ==0 || strcmp(str2,".")==0){ result[0]= '\0'; return result;}
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

RML_BEGIN_LABEL(System__directoryExists)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  struct stat buf;

  if (str == NULL)
    RML_TAILCALLK(rmlFC);

  ret_val = stat(str, &buf);
  if (ret_val != 0 ) {
    rmlA0 = (void*) mk_icon(1);
  }
  else {
    if (buf.st_mode & S_IFDIR) {
      rmlA0 = (void*) mk_icon(0);
    }
    else {
      rmlA0 = (void*) mk_icon(1);
    }
  }
  RML_TAILCALLK(rmlSC);

}
RML_END_LABEL

RML_BEGIN_LABEL(System__regularFileExists)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  struct stat buf;
  ret_val = stat(str, &buf);
  if (ret_val != 0 ) {
    rmlA0 = (void*) mk_icon(1);
  }
  else {
    if (buf.st_mode & S_IFREG ) {
      rmlA0 = (void*) mk_icon(0);
    }
    else {
      rmlA0 = (void*) mk_icon(1);
    }
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__removeFile)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  ret_val = remove(str);

  rmlA0 = (void*) mk_icon(ret_val);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


#ifdef WIN32
RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("WIN32");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
#elif defined CYGWIN
RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("CYGWIN");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
#else
RML_BEGIN_LABEL(System__platform)
{
  rmlA0 = (void*) mk_scon("");
  RML_TAILCALLK(rmlSC);
}
#endif

RML_BEGIN_LABEL(System__realCeil)
{
  rmlA0 = rml_prim_mkreal(ceil(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__asin)
{
  rmlA0 = rml_prim_mkreal(asin(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__acos)
{
  rmlA0 = rml_prim_mkreal(acos(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__atan)
{
  rmlA0 = rml_prim_mkreal(atan(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__atan2)
{
  rmlA0 = rml_prim_mkreal(atan2(rml_prim_get_real(rmlA0),
        rml_prim_get_real(rmlA1)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__cosh)
{
  rmlA0 = rml_prim_mkreal(cosh(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__log)
{
  rmlA0 = rml_prim_mkreal(log(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__log10)
{
  rmlA0 = rml_prim_mkreal(log10(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__sinh)
{
  rmlA0 = rml_prim_mkreal(sinh(rml_prim_get_real(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tanh)
{
  rmlA0 = rml_prim_mkreal(tanh(rml_prim_get_real(rmlA0)));
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

char* class_names_for_simulation = NULL;
RML_BEGIN_LABEL(System__getClassnamesForSimulation)
{
  if(class_names_for_simulation)
    rmlA0 = (void*) mk_scon(strdup(class_names_for_simulation));
  else
    rmlA0 = (void*) mk_scon("{}");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setClassnamesForSimulation)
{
  char* class_names = RML_STRINGDATA(rmlA0);
  if(class_names_for_simulation)
    free(class_names_for_simulation);

  class_names_for_simulation = strdup(class_names);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

char* compile_command = NULL;

RML_BEGIN_LABEL(System__getVariableValue)
{
  double timeStamp   = rml_prim_get_real(rmlA0);
  void *timeValues   = rmlA1;
  void *varValues   = rmlA2;

  // values to find the correct range
  double preValue   = 0.0;
  double preTime   = 0.0;
  double nowValue   = 0.0;
  double nowTime   = 0.0;

  // linjear interpolation data
  double timedif       = 0.0;
  double valuedif      = 0.0;
  double valueSlope      = 0.0;
  double timeDifTimeStamp  = 0.0;

  // break loop and return value
  int valueFound = 0;
  double returnValue = 0.0;

for(; RML_GETHDR(timeValues) == RML_CONSHDR && valueFound == 0; timeValues = RML_CDR(timeValues), varValues = RML_CDR(varValues)) {


    nowValue   = rml_prim_get_real(RML_CAR(varValues));
    nowTime   =  rml_prim_get_real(RML_CAR(timeValues));


  if(timeStamp == nowTime){
      valueFound   = 1;
      returnValue = nowValue;

    } else if (timeStamp >= preTime && timeStamp <= nowTime) { // need to do interpolation
      valueFound       = 1;
      timedif       = nowTime - preTime;
      valuedif      = nowValue - preValue;
      valueSlope       = valuedif / timedif;
      timeDifTimeStamp   = timeStamp - preTime;
      returnValue     = preValue + (valueSlope*timeDifTimeStamp);
      /*
      printf("\t ### Interpolation ###");
      printf("nowTime: %f", nowTime);
      printf("\n");
      printf("preTime: %f", preTime);
      printf("\n");
      printf("nowValue: %f", nowValue);
      printf("\n");
      printf("preValue: %f", preValue);
      printf("\n");

    printf("timedif: %f", timedif);
      printf("\n");
      printf("valuedif: %f", valuedif);
      printf("\n");
      printf("valueSlope: %f", valueSlope);
      printf("\n");
      printf("timeDifTimeStamp: %f", timeDifTimeStamp);
      printf("\n");
      printf("returnValue: %f", returnValue);
      printf("\n");
    */
  } else {
    preValue   = nowValue;
      preTime   = nowTime;

  }

  }
  if(valueFound == 0){
    // value could not be found in the dataset, what do we do?
    printf("\n WARNING: timestamp outside simulation timeline \n");
    RML_TAILCALLK(rmlFC);
  } else {

      rmlA0 = (void*)mk_rcon(returnValue);
      RML_TAILCALLK(rmlSC);
  }
}
RML_END_LABEL

RML_BEGIN_LABEL(System__sendData)
{

  char* data = RML_STRINGDATA(rmlA0);
  char* interpolation = RML_STRINGDATA(rmlA1);
 char* title = RML_STRINGDATA(rmlA2);
 int legend = RML_UNTAGFIXNUM(rmlA3); //RML_STRINGDATA(rmlA3);
 int grid = RML_UNTAGFIXNUM(rmlA4); //RML_STRINGDATA(rmlA4);
 int logX = RML_UNTAGFIXNUM(rmlA5); //RML_STRINGDATA(rmlA5);
 int logY = RML_UNTAGFIXNUM(rmlA6); //RML_STRINGDATA(rmlA6);
 char* xLabel = RML_STRINGDATA(rmlA7);
 char* yLabel = RML_STRINGDATA(rmlA8);
 int points = RML_UNTAGFIXNUM(rmlA9);
 char* range = RML_STRINGDATA(rmlA10);
// char* yRange = RML_STRINGDATA(rmlA11);
//  emulateStreamData(data, 7778);

//  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, "linear", 1);
///  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, interpolation, 1);

//  emulateStreamData(data, 7778, title, "time", "", legend, grid, 0, 0, 0, 0, logX, logY, interpolation, 1);
// emulateStreamData(data, title, xLabel, yLabel , interpolation, legend, grid, logX, logY, points, range);
 // emulateStreamData(data, 7778, title, xLabel, yLabel , interpolation, legend, grid, 0, 0, 0, 0, logX, logY, points, range);

  emulateStreamData(data, title, xLabel, yLabel , interpolation, legend, grid, logX, logY, points, range);

//  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, "linear");

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__enableSendData)
{
  int enable = RML_UNTAGFIXNUM(rmlA0);
  if(enable)
    setenv("enableSendData", "1", 1 /* overwrite */);
  else
    setenv("enableSendData", "0", 1 /* overwrite */);
//  enableSendData(enable);
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setDataPort)
{
  long port = RML_UNTAGFIXNUM(rmlA0);
  char* p = malloc(10);
  sprintf(p, "%s", (char*) port);
  setenv("sendDataPort", p, 1 /* overwrite */);
  free(p);
  setDataPort(port);
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
RML_BEGIN_LABEL(System__setVariableFilter)
{
  char * variables = RML_STRINGDATA(rmlA0);
  setenv("sendDataFilter", variables, 1 /* overwrite */);
//  setVariableFilter(variables);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__sendData2)
{
  char* info = RML_STRINGDATA(rmlA0);
  char* data = RML_STRINGDATA(rmlA1);
  emulateStreamData2(info, data, 7778);

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

RML_BEGIN_LABEL(System__getCurrentTime)
{
  time_t t;
  double elapsedTime;             // the time elapsed as double
  time( &t );
  rmlA0 = mk_rcon(difftime(t, 0)); // the file modification time
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

#endif /* MINGW32 and Linux */

/************************************************************************************************
 * from here on down the functions are THE SAME for all platforms (mingw/msvc, linux, macos, etc)
 ************************************************************************************************/

inline modelica_integer alloc_ptr()
{
  const modelica_integer start = last_ptr_index;
  modelica_integer index;
  index = start;
  for (;;) {
    ++index;
    if (index >= MAX_PTR_INDEX)
      index = 0;
    if (index == start)
      return -1;
    if (ptr_vector[index].cnt == 0)
      break;
  }
  ptr_vector[index].cnt = 1;
  return index;
}

modelica_ptr_t lookup_ptr(modelica_integer index)
{
  assert(index < MAX_PTR_INDEX);
  return ptr_vector + index;
}

inline void free_ptr(modelica_integer index)
{
  assert(index < MAX_PTR_INDEX);
  ptr_vector[index].cnt = 0;
  memset(&(ptr_vector[index].data), 0, sizeof(ptr_vector[index].data));
}

RML_BEGIN_LABEL(System__freeFunction)
{
  modelica_integer funcIndex = RML_UNTAGFIXNUM(rmlA0);
  modelica_ptr_t func = NULL, lib = NULL;

  func = lookup_ptr(funcIndex);

  if (func == NULL)
    RML_TAILCALLK(rmlFC);

  lib = lookup_ptr(func->data.func.lib);

  if (lib == NULL) {
    free_function(func);
    free_ptr(funcIndex);
    RML_TAILCALLK(rmlFC);
  }


  if (lib->cnt <= 1) {
    free_library(lib);
    free_ptr(func->data.func.lib);
    // fprintf(stderr, "library count %u, after unloading!\n", lib->cnt); fflush(stderr);
  } else {
    --(lib->cnt);
    // fprintf(stderr, "library count %u, no unloading!\n", lib->cnt); fflush(stderr);
  }

  free_function(func);
  free_ptr(funcIndex);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__freeLibrary)
{
  modelica_integer libIndex = RML_UNTAGFIXNUM(rmlA0);
  modelica_ptr_t lib = NULL;

  lib = lookup_ptr(libIndex);

  if (lib == NULL)
    RML_TAILCALLK(rmlFC);

  if (lib->cnt <= 1) {
    free_library(lib);
    free_ptr(libIndex);
    /* fprintf(stderr, "LIB UNLOAD index[%d]/count[%d]/handle[%ul].\n", libIndex, lib->cnt, lib->data.lib); fflush(stderr); */
  } else {
    --(lib->cnt);
    /* fprintf(stderr, "LIB *NO* UNLOAD index[%d]/count[%d]/handle[%ul].\n", libIndex, lib->cnt, lib->data.lib); fflush(stderr); */
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

void free_function(modelica_ptr_t func)
{
  /* noop */
  modelica_ptr_t lib = NULL;
  lib = lookup_ptr(func->data.func.lib);
  /* fprintf(stderr, "FUNCTION FREE LIB index[%d]/count[%d]/handle[%ul].\n", (lib-ptr_vector),((modelica_ptr_t)(lib-ptr_vector))->cnt, lib->data.lib); fflush(stderr); */
}

/*
 * @author: adrpo
 * side effect to detect if we have expandable conenctors in a program
 */
int hasExpandableConnector = 0;
/*
 * @author: adrpo
 * side effect to set if we have expandable conenctors in a program
 */
RML_BEGIN_LABEL(System__getHasExpandableConnectors)
{
  rmlA0 = hasExpandableConnector ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
/*
 * @author: adrpo
 * side effect to get if we have expandable conenctors in a program
 */
RML_BEGIN_LABEL(System__setHasExpandableConnectors)
{
  hasExpandableConnector = (RML_UNTAGFIXNUM(rmlA0)) ? 1 : 0;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*
 * @author: adrpo
 * side effect to detect if we have expandable conenctors in a program
 */
int hasInnerOuterDefinitions = 0;
/*
 * @author: adrpo
 * side effect to set if we have expandable conenctors in a program
 */
RML_BEGIN_LABEL(System__getHasInnerOuterDefinitions)
{
  rmlA0 = hasInnerOuterDefinitions ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
/*
 * @author: adrpo
 * side effect to get if we have expandable conenctors in a program
 */
RML_BEGIN_LABEL(System__setHasInnerOuterDefinitions)
{
  hasInnerOuterDefinitions = (RML_UNTAGFIXNUM(rmlA0)) ? 1 : 0;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*
 * @author ppriv
 */
static modelica_integer tmp_tick_no = 0;

RML_BEGIN_LABEL(System__tmpTick)
{
  rmlA0 = (void*) mk_icon(tmp_tick_no++);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__tmpTickReset)
{
  tmp_tick_no = RML_UNTAGFIXNUM(rmlA0);
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL



RML_BEGIN_LABEL(System__listAppendUnsafe)
{
  // call RML__listAppend
  RML_TAILCALLQ(RML__listAppend,2);
  // this is an alternative
#if 0
    void *lst, *tmp;
    rml_uint_t idx = 0;
    lst = rmlA0;

    if (rml_trace_enabled)
    {
      fprintf(stderr, "System.listAppendUnsafe\n"); fflush(stderr);
    }

    /* the first list is empty */
    if (RML_GETHDR(rmlA0) != RML_CONSHDR)
    {
      rmlA0 = rmlA1; /* the first list was empty, return the second list. */
      RML_TAILCALLK(rmlSC);
    }
    /* the second list is empty */
    if (RML_GETHDR(rmlA1) != RML_CONSHDR)
    {
      rmlA0 = rmlA0; /* the second list was empty, return the first list. */
      RML_TAILCALLK(rmlSC);
    }

    /* find the end of the first list! */
    while( RML_GETHDR(lst) == RML_CONSHDR )
    {
      if (RML_GETHDR(tmp = RML_CDR(lst)) != RML_CONSHDR)
        break;
      else
        lst = tmp; /* move to next element */
    }

    struct rml_struct *p = RML_UNTAGPTR(lst);
    /* set the cdr of the last element in the first list to the first element in the second list */
    p->data[1] = rmlA1;
    for (idx = rml_array_trail_size; &rml_array_trail[idx] >= rmlATP; idx--)
      if (rml_array_trail[idx] == lst) /* if found, do not add again */
      {
        rmlA0 = rmlA0; /* return the pointer to the first list */
        /* return resulting list */
        RML_TAILCALLK(rmlSC);
      }
    /* add the address of the list element into the roots to be
     *  taken into consideration at the garbage collection time
     */
    if( rmlATP == &rml_array_trail[0] )
    {
      (void)fprintf(stderr, "Array Trail Overflow!\n");
      rml_exit(1);
    }
    *--rmlATP = lst;

    rmlA0 = rmlA0; /* return the pointer to the first list */
    /* return resulting list */
    RML_TAILCALLK(rmlSC);
#endif

}
RML_END_LABEL

char          rml_external_roots_trail_names[1024][200];
void         *rml_external_roots_trail[1024] = {0};
rml_uint_t    rml_external_roots_trail_size = 1024;

/* forward my external roots */
void rml_user_gc(struct rml_xgcstate *state)
{
  rml_user_gc_callback(state, rml_external_roots_trail, sizeof(void*));
}

RML_BEGIN_LABEL(System__addToRoots)
{
    rml_uint_t i = RML_UNTAGFIXNUM(rmlA0);

    if (rml_trace_enabled)
    {
      fprintf(stderr, "System__addToRoots\n"); fflush(stderr);
    }

    if (i >= rml_external_roots_trail_size)
      RML_TAILCALLK(rmlFC);

    rml_external_roots_trail[i] = rmlA1;

    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__getFromRoots)
{
    rml_uint_t i = RML_UNTAGFIXNUM(rmlA0);

    if (rml_trace_enabled)
    {
      fprintf(stderr, "System__getFromRoots\n"); fflush(stderr);
    }

    if (i >= rml_external_roots_trail_size)
      RML_TAILCALLK(rmlFC);

    rmlA0 = rml_external_roots_trail[i];

    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__enableTrace)
{
  rml_trace_enabled = 1;
  if (rml_trace_enabled)
  {
    fprintf(stderr, "System__enableTrace\n"); fflush(stderr);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__disableTrace)
{
  if (rml_trace_enabled)
  {
    fprintf(stderr, "System__disableTrace\n"); fflush(stderr);
  }
  rml_trace_enabled = 0;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* is the same for both Windows/Linux */
RML_BEGIN_LABEL(System__systemCall)
{
  int ret_val;
  char* str = RML_STRINGDATA(rmlA0);

  if (rml_trace_enabled)
  {
    fprintf(stderr, "System.systemCall: %s\n", str); fflush(stderr);
  }

  ret_val = system(str);

  if (rml_trace_enabled)
  {
    fprintf(stderr, "System.systemCall: returned value: %d\n", ret_val); fflush(stderr);
  }

  rmlA0 = (void*) mk_icon(ret_val);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

