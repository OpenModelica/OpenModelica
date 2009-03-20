/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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
#include "read_write.h"

static char * cc=NULL;
static char * cxx=NULL;
static char * linker=NULL;
static char * cflags=NULL;
static char * ldflags=NULL;

void * read_ptolemy_dataset(char*filename, int size,char**vars,
                            int datasize);
int read_ptolemy_dataset_size(char*filename);
static void *generate_array(enum type_desc_e type, int curdim, int ndims,
                            int *dim_size, void **data);
static int parse_array(type_description *desc, void *arrdata);
static void *type_desc_to_value(type_description *desc);
static int execute_function(void *in_arg, void **out_arg,
                            int (* func)(type_description *,
                                         type_description *));

typedef struct modelica_ptr_s *modelica_ptr_t;

#define MAX_PTR_INDEX 10000

/*
#if defined(_MSC_VER)
#define inline __inline
#else // Linux & MinGW
#define inline inline
#endif
*/

static inline modelica_integer alloc_ptr();
static inline modelica_ptr_t lookup_ptr(modelica_integer index);
static inline void free_ptr(modelica_integer index);
static void free_library(modelica_ptr_t lib);
static void free_function(modelica_ptr_t func);

typedef int (* function_t)(type_description *, type_description *);

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

/*
* Description:
*   Find and replace text within a string.
*
* Parameters:
*   source_src  (in) - pointer to source string
*   search_str (in) - pointer to search text
*   replace_str   (in) - pointer to replacement text
*
* Returns:
*   Returns a pointer to dynamically-allocated memory containing string
*   with occurences of the text pointed to by 'search_str' replaced by with the
*   text pointed to by 'replace_str'.
*/

static char *_strcat(char *buf, size_t *buf_size, char **ptr,
                     const char *addon, size_t addon_len)
{
  size_t pos = (*ptr) - buf;
  char *ret = buf;
  if ((pos + addon_len) > (*buf_size)) {
    (*buf_size) = (pos + addon_len);
    ret = realloc(buf, (*buf_size) + 1);
    if (ret == NULL) {
      free(buf);
      return NULL;
    }
    *ptr = ret + pos;
  }
  memcpy(*ptr, addon, addon_len);
  (*ptr) += addon_len;
  return ret;
}

char* _replace(const char* source_str,
               const char* search_str,
               const char* replace_str)
{
  char *ostr, *out = NULL;
  const char *pos = NULL, *last = NULL;
  const size_t nreplace = strlen(replace_str);
  const size_t nsearch = strlen(search_str);
  size_t ostr_allocated;

  if (!source_str || !search_str || !replace_str) {
    printf("Not enough arguments\n");
    return NULL;
  }

  ostr_allocated = strlen(source_str);
  ostr = malloc(ostr_allocated + 1);
  if (!ostr) {
    printf("Insufficient memory available\n");
    return NULL;
  }

  last = source_str;
  out = ostr;
  while((pos = strstr(last, search_str)) != NULL) {
    if (last < pos) {
      ostr = _strcat(ostr, &ostr_allocated, &out, last, pos - last);
      if (ostr == NULL) {
        printf("Insufficient memory available\n");
        return NULL;
      }
    }

    ostr = _strcat(ostr, &ostr_allocated, &out, replace_str, nreplace);
    if (ostr == NULL) {
      printf("Insufficient memory available\n");
      return NULL;
    }

    last = pos + nsearch;
  }

  if (*last != '\0') {
    ostr = _strcat(ostr, &ostr_allocated, &out, last, strlen(last));
    if (ostr == NULL) {
      printf("Insufficient memory available\n");
      return NULL;
    }
  }

  *out = '\0';

  return ostr;
}

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

#include "rml.h"
#include "Values.h"
#include "Absyn.h"

#define MAXPATHLEN MAX_PATH
#define S_IFLNK  0120000  /* symbolic link */

struct modelica_ptr_s {
  union {
    struct {
      function_t handle;
      modelica_integer lib;
    } func;
    HMODULE lib;
  } data;
  unsigned int cnt;
};

static struct modelica_ptr_s ptr_vector[MAX_PTR_INDEX];
static modelica_integer last_ptr_index = -1;


void System_5finit(void)
{
	char* path;
	char* newPath;
	char* omhome;
	char* mingwpath;
	char* qthome;

    last_ptr_index = -1;
    memset(ptr_vector, 0, sizeof(ptr_vector));

	set_cc("gcc");
  set_cxx("g++");
#if defined(__x86_64__)
  /* -fPIC needed on x86_64! */
  set_linker("gcc -shared -export-dynamic -fPIC");
#else
  set_linker("gcc -shared -export-dynamic");
#endif

#if defined(__i386__) || defined(__x86_64__) || defined(_MSC_VER)
  /*
   * if we are on i386 or x86_64 or compiling with
   * Visual Studio then use the SSE instructions,
   * not the normal i387 FPU
   */
  set_cflags("-Wall -msse2 -mfpmath=sse ${MODELICAUSERCFLAGS}");
#else
  set_cflags("${MODELICAUSERCFLAGS}");
#endif
  set_ldflags("-lc_runtime");
	path = getenv("PATH");
	omhome = getenv("OPENMODELICAHOME");
	if (omhome) {
		mingwpath = malloc(2*strlen(omhome)+25);
		sprintf(mingwpath,"%s\\mingw\\bin;%s\\lib", omhome, omhome);
		if (strncmp(mingwpath,path,strlen(mingwpath))!=0) {
			newPath = malloc(strlen(path)+strlen(mingwpath)+10);
			sprintf(newPath,"PATH=%s;%s",mingwpath,path);
			_putenv(newPath);
			free(newPath);
		}
		free(mingwpath);
	}

//	qthome = getenv("QTHOME");
//	if(qthome && strlen(qthome))
    if (1) {
//		char senddatalibs[] = "SENDDATALIBS= -lsendData -lQtNetwork -lQtCore -lQtGui -luuid -lole32 -lws2_32";
		_putenv("SENDDATALIBS=-lsendData -lQtNetwork-mingw -lQtCore-mingw -lQtGui-mingw -luuid -lole32 -lws2_32");
//		_putenv(senddatalibs);
    }
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
  same = strcmp(fn1_2,fn2_2);
   
  free(fn1_2);
  free(fn2_2);
  if(same ==0)
    RML_TAILCALLK(rmlSC);
  else 
    RML_TAILCALLK(rmlFC);
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

RML_BEGIN_LABEL(System__trimChar)
{
  char* str = RML_STRINGDATA(rmlA0);
  char  char_to_be_trimmed = RML_STRINGDATA(rmlA1)[0];
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
    res= (char*)malloc(end_pos - start_pos +1);
    strncpy(res,&str[start_pos],end_pos - start_pos + 1);
    res[end_pos - start_pos + 1] = '\0';
    rmlA0 = (void*) mk_scon(res);
    free(res);
    RML_TAILCALLK(rmlSC);

  }else{
    rmlA0 = (void*) mk_scon("");
    RML_TAILCALLK(rmlSC);
  }
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
  modelica_ptr_t lib = NULL;
  modelica_integer libIndex;
  HMODULE h;
#if defined(_MSC_VER)
  _snprintf(libname, MAXPATHLEN, "./%s.dll", str);
#else
  snprintf(libname, MAXPATHLEN, "./%s.dll", str);
#endif

  h = LoadLibrary(libname);
  if (h == NULL) {
    //fprintf(stderr, "Unable to load `%s': %lu.\n", libname, GetLastError());
    RML_TAILCALLK(rmlFC);
  }
  libIndex = alloc_ptr();
  if (libIndex < 0) {
    FreeLibrary(h);
    RML_TAILCALLK(rmlFC);
  }
  lib = lookup_ptr(libIndex);
  lib->data.lib = h;
  rmlA0 = (void*) mk_icon(libIndex);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

void free_library(modelica_ptr_t lib)
{
  FreeLibrary(lib->data.lib);
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
    fprintf(stderr, "Unable to find `%s': %lu.\n", str, GetLastError());
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

void free_function(modelica_ptr_t func)
{
  /* noop */
}


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

RML_BEGIN_LABEL(System__systemCall)
{
	int ret_val;
	char* str = RML_STRINGDATA(rmlA0);
	ret_val	= system(str);
	rmlA0 = (void*) mk_icon(ret_val);

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


//void* read_one_value_from_file(FILE* file, type_description* desc)
//{
//  void *res=NULL;
//  int ival;
//  double rval;
//  double *rval_arr;
//  int *ival_arr;
//  int size;
//  if (desc->ndims == 0) /* Scalar value */
//  {
//    if (desc->type == 'i') {
//      fscanf(file,"%d",&ival);
//      res =(void*) Values__INTEGER(mk_icon(ival));
//    } else if (desc->type == 'r') {
//      fscanf(file,"%le",&rval);
//      res = (void*) Values__REAL(mk_rcon(rval));
//    } else if (desc->type == 'b') {
//      fscanf(file,"%le",&rval);
//      res = (void*) Values__BOOL(rval?RML_TRUE:RML_FALSE/*mk_bcon(rval)*/);
//    }
//  } else if (desc->ndims == 1 && desc->type == 's') { /* Scalar String */
//    int i;
//    char* tmp;
//    tmp = malloc(sizeof(char)*(desc->dim_size[0]+1));
//    if (!tmp) return NULL;
//    for(i=0;i<desc->dim_size[0];i++) {
//      tmp[i] = fgetc(file);
//      if (tmp[i] == EOF) {
//	return NULL;
//      }
//    }
//    tmp[i]='\0';
//    res = (void*) Values__STRING(mk_scon(tmp));
//  }
//  else  /* Array value */
//  {
//    int currdim,el,i;
//    /* REAL ARRAYS */
//    if (desc->type == 'r') {
//	/* Create array to hold inserted values, max dimension as size */
//	size = 1;
//	for (currdim=0;currdim < desc->ndims; currdim++) {
//	  size *= desc->dim_size[currdim];
//	}
//	rval_arr = (double*)malloc(sizeof(double)*size);
//	if(rval_arr == NULL) {
//	  return NULL;
//	}
//	/* Fill the array in reversed order */
//	for(i=size-1;i>=0;i--) {
//	  fscanf(file,"%le",&rval_arr[i]);
//	}
//
//	next_realelt(NULL);
//	/* 1 is current dimension (start value) */
//	res =(void*) Values__ARRAY(generate_array('r',1,desc,(void*)rval_arr));
//      }
//      /* REAL ARRAY END, INTEGER ARRAY START*/
//
//      if (desc->type == 'i') {
//	int currdim,el,i;
//	/* Create array to hold inserted values, mult of dimensions as size */
//	size = 1;
//	for (currdim=0;currdim < desc->ndims; currdim++) {
//	  size *= desc->dim_size[currdim];
//	}
//	ival_arr = (int*)malloc(sizeof(int)*size);
//	if(ival_arr==NULL) {
//	  return NULL;
//	}
//	/* Fill the array in reversed order */
//	for(i=size-1;i>=0;i--) {
//	  fscanf(file,"%f",&ival_arr[i]);
//	}
//	next_intelt(NULL);
//	res = (void*) Values__ARRAY(generate_array('i',1,desc,(void*)ival_arr));
//      }
//      /*INTEGER ARRAY ENDS BOOLEAN ARRAY START*/
//
//	if (desc->type == 'b')
//	{
//		int currdim,el,i;
//		/* Create array to hold inserted values, mult of dimensions as size */
//		size = 1;
//		for (currdim=0;currdim < desc->ndims; currdim++) {
//	  		size *= desc->dim_size[currdim];
//		}
//		rval_arr = (double*)malloc(sizeof(double)*size);
//		if(rval_arr==NULL) {
//	  		return NULL;
//		}
//		/* Fill the array in reversed order */
//		for(i=size-1;i>=0;i--) {
//	  		fscanf(file,"%le",&rval_arr[i]);
//		}
//			next_intelt(NULL);
//			res = (void*) Values__ARRAY(generate_array('b',1,desc,(void*)rval_arr));
//	}
//	if (desc->type == 's') {
//		printf("Error, array of strings not impl. yet.\n");
//	}
//  }
//  return res;
//}

//RML_BEGIN_LABEL(System__readValuesFromFile)
//{
//  int stat=0;
//  int varcount=0;
//  type_description desc;
//  void *lst = (void*)mk_nil();
//  void *res = NULL;
//  char* filename = RML_STRINGDATA(rmlA0);
//  FILE * file=NULL;
//  file = fopen(filename,"r");
//  if (file == NULL) {
//    RML_TAILCALLK(rmlFC);
//  }
//
//  /* Read the first value */
//  stat = read_type_description(file,&desc);
//  if (stat != 0) {
//    printf("Error reading values from file\n");
//    RML_TAILCALLK(rmlFC);
//  }
//
//  while (stat == 0) { /* Loop for tuples. At the end of while, we try to read another description */
//    res = read_one_value_from_file(file, &desc);
//    if (res == NULL) {
//      printf("Error reading values from file2 %s ..\n", filename);
//      RML_TAILCALLK(rmlFC);
//    }
//    lst = (void*)mk_cons(res, lst);
//    varcount++;
//    read_to_eol(file);
//    stat = read_type_description(file,&desc);
//    /*
//    printf("varcount is : %d\n", varcount);
//    printf("stat is : %d\n", stat);
//    */
//  }
//  if (varcount > 1) { /* if tuple */
//    rmlA0 = lst;
//    rml_prim_once(RML__list_5freverse);
//    rmlA0 = (void*) Values__TUPLE(rmlA0);
//  }
//  else {
//    rmlA0 = (void*)res;
//  }
//  RML_TAILCALLK(rmlSC);
//}
//RML_END_LABEL

RML_BEGIN_LABEL(System__readPtolemyplotDataset)
{
  rml_sint_t i,size;
  char **vars;
  char* filename = RML_STRINGDATA(rmlA0);
  void *lst = rmlA1;
  rml_sint_t datasize = RML_UNTAGFIXNUM(rmlA2);
  void* p;
  rmlA0 = lst;
  rml_prim_once(RML__list_5flength);
  size = RML_UNTAGFIXNUM(rmlA0);

  vars = (char**)malloc(sizeof(char*)*size);
  for (i=0,p=lst;i<size;i++) {
    vars[i]=RML_STRINGDATA(RML_CAR(p));
    p=RML_CDR(p);
  }
  rmlA0 = (void*)read_ptolemy_dataset(filename,size,vars,datasize);
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }

  rml_prim_once(Values__reverseMatrix);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__readPtolemyplotVariables)
{
  rml_sint_t i,size;
  char* filename = RML_STRINGDATA(rmlA0);
  char* visvars = RML_STRINGDATA(rmlA1);
  void* p;

  rmlA0 = (void*)read_ptolemy_variables(filename, visvars);
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }

//  rml_prim_once(Values__reverseMatrix);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__readPtolemyplotDatasetSize)
{
  int size;
  char* filename = RML_STRINGDATA(rmlA0);
  void* p;

  size=read_ptolemy_dataset_size(filename);

  rmlA0 = (void*)Values__INTEGER(mk_icon(size));
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__writePtolemyplotDataset)
{
  char *filename = RML_STRINGDATA(rmlA0);
  void *value = rmlA1;


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
//	    rval = next_realelt((double*)data);
//	    lst = (void*)mk_cons(Values__REAL(mk_rcon(rval)),lst);
//      }
//      else if (type == 'i')
//      {
//	    ival = next_intelt((int*)data);
//	    lst = (void*)mk_cons(Values__INTEGER(mk_icon(ival)),lst);
//      }
//      else if (type == 'b')
//      {
//	    rval = next_realelt((double*)data);
//	    lst = (void*)mk_cons(Values__BOOL(rval?RML_TRUE:RML_FALSE/*mk_bcon(rval)*/),lst);
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
  double timeStamp 	= rml_prim_get_real(rmlA0);
  void *timeValues 	= rmlA1;
  void *varValues 	= rmlA2;

  // values to find the correct range
  double preValue 	= 0.0;
  double preTime 	= 0.0;
  double nowValue 	= 0.0;
  double nowTime 	= 0.0;

  // linjear interpolation data
  double timedif 			= 0.0;
  double valuedif			= 0.0;
  double valueSlope			= 0.0;
  double timeDifTimeStamp	= 0.0;

  // break loop and return value
  int valueFound = 0;
  double returnValue = 0.0;

for(; RML_GETHDR(timeValues) == RML_CONSHDR && valueFound == 0; timeValues = RML_CDR(timeValues), varValues = RML_CDR(varValues)) {


    nowValue 	= rml_prim_get_real(RML_CAR(varValues));
  	nowTime 	=  rml_prim_get_real(RML_CAR(timeValues));


	if(timeStamp == nowTime){
    	valueFound 	= 1;
    	returnValue = nowValue;

    } else if (timeStamp >= preTime && timeStamp <= nowTime) { // need to do interpolation
    	valueFound 			= 1;
    	timedif 			= nowTime - preTime;
    	valuedif			= nowValue - preValue;
    	valueSlope 			= valuedif / timedif;
    	timeDifTimeStamp 	= timeStamp - preTime;
    	returnValue 		= preValue + (valueSlope*timeDifTimeStamp);
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
		preValue 	= nowValue;
  		preTime 	= nowTime;

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
 //char* yRange = RML_STRINGDATA(rmlA11);
//  emulateStreamData(data, 7778);


//  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, "linear", 1);
///  emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, interpolation, 1);

//  emulateStreamData(data, 7778, title, "time", "", legend, grid, 0, 0, 0, 0, logX, logY, interpolation, 1);
  emulateStreamData(data, title, xLabel, yLabel , interpolation, legend, grid, logX, logY, points, range);

//	emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, "linear");

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


//	enableSendData(enable);
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
//	setDataPort(port);
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
//	setVariableFilter(variables);
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
  struct _stat attrib;			  // create a file attribute structure
  double elapsedTime;             // the time elapsed as double
  int result;					  // the result of the function call

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


#else /********************************* LINUX PART!!! *************************************/

#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

#include "rml.h"
#include "../Absyn.h"
#include "../Values.h"

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

struct modelica_ptr_s {
  union {
    struct {
      function_t handle;
      modelica_integer lib;
    } func;
    void *lib;
  } data;
  unsigned int cnt;
};
static struct modelica_ptr_s ptr_vector[MAX_PTR_INDEX];
static modelica_integer last_ptr_index = -1;

void System_5finit(void)
{
	char* qthome;

    last_ptr_index = -1;
    memset(ptr_vector, 0, sizeof(ptr_vector));

	set_cc("gcc");
  set_cxx("g++");
#if defined(__sparc__)
  set_linker("gcc -G");
#elif defined(__x86_64__)
  /* -fPIC needed on x86_64! */
  set_linker("gcc -shared -export-dynamic -fPIC");
#else
#ifdef __APPLE_CC__
  set_linker("gcc -single_module -dynamiclib -flat_namespace");
#else
  set_linker("gcc -shared -export-dynamic");
#endif
#endif /* __sparc__ */

#if defined(__i386__) || defined(__x86_64__)
  /*
   * if we are on i386 or x86_64 then use the
   * SSE instructions, not the normal i387 FPU
   */
  set_cflags("-Wall -msse2 -mfpmath=sse ${MODELICAUSERCFLAGS}");
#else
	set_cflags("${MODELICAUSERCFLAGS}");
#endif
  set_ldflags("-lc_runtime");

	qthome = getenv("QTHOME");
	if (qthome && strlen(qthome)) {
#ifdef __APPLE_CC__
		putenv("SENDDATALIBS=-lsendData -lQtNetwork -lQtCore -lQtGui -lz -framework Carbon");
#else
		putenv("SENDDATALIBS=-lsendData -lQtNetwork -lQtCore -lQtGui");
#endif
	} else {
		putenv("SENDDATALIBS=-lsendData");
    }
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
    res= (char*)malloc(end_pos - start_pos +1);
    strncpy(res,&str[start_pos],end_pos - start_pos + 1);
    res[end_pos - start_pos + 1] = '\0';
    rmlA0 = (void*) mk_scon(res);
    free(res);
    RML_TAILCALLK(rmlSC);

  }else{
    rmlA0 = (void*) mk_scon("");
    RML_TAILCALLK(rmlSC);
  }
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

RML_BEGIN_LABEL(System__loadLibrary)
{
  const char *str = RML_STRINGDATA(rmlA0);
  char libname[MAXPATHLEN];
  modelica_ptr_t lib = NULL;
  modelica_integer libIndex;
  void *h;
  snprintf(libname, MAXPATHLEN, "./%s.so", str);
  h = dlopen(libname, RTLD_LOCAL | RTLD_NOW);
  if (h == NULL) {
    //fprintf(stderr, "Unable to load `%s': %s.\n", libname, dlerror());
    RML_TAILCALLK(rmlFC);
  }
  libIndex = alloc_ptr();
  if (libIndex < 0) {
    dlclose(h);
    RML_TAILCALLK(rmlFC);
  }
  lib = lookup_ptr(libIndex);
  lib->data.lib = h;
  rmlA0 = (void*) mk_icon(libIndex);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

void free_library(modelica_ptr_t lib)
{
  dlclose(lib->data.lib);
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

void free_function(modelica_ptr_t func)
{
  /* noop */
}

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


RML_BEGIN_LABEL(System__systemCall)
{
  int ret_val;
  char* str = RML_STRINGDATA(rmlA0);
  ret_val = system(str);
  rmlA0 = (void*) mk_icon(ret_val);

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
  getcwd(buf,MAXPATHLEN);
  rmlA0 = (void*) mk_scon(buf);

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

#if 0 
void* read_one_value_from_file(FILE* file, type_description* desc)
{
  void *res=NULL;
  int ival;
  double rval;
  double *rval_arr;
  int *ival_arr;
  int size;
  if (desc->ndims == 0) /* Scalar value */
  {
    if (desc->type == 'i') {
      fscanf(file,"%d",&ival);
      res =(void*) Values__INTEGER(mk_icon(ival));
    } else if (desc->type == 'r') {
      fscanf(file,"%le",&rval);
      res = (void*) Values__REAL(mk_rcon(rval));
    } else if (desc->type == 'b') {
      fscanf(file,"%le",&rval);
      res = (void*) Values__BOOL(rval?RML_TRUE:RML_FALSE/*mk_bcon(rval)*/);
    }
  } else if (desc->ndims == 1 && desc->type == 's') { /* Scalar String */
    int i;
    char* tmp;
    tmp = malloc(sizeof(char)*(desc->dim_size[0]+1));
    if (!tmp) return NULL;
    for(i=0;i<desc->dim_size[0];i++) {
      tmp[i] = fgetc(file);
      if (tmp[i] == EOF) {
	return NULL;
      }
    }
    tmp[i]='\0';
    res = (void*) Values__STRING(mk_scon(tmp));
  }
  else  /* Array value */
  {
    int currdim,el,i;
    /* REAL ARRAYS */
    if (desc->type == 'r') {
	/* Create array to hold inserted values, max dimension as size */
	size = 1;
	for (currdim=0;currdim < desc->ndims; currdim++) {
	  size *= desc->dim_size[currdim];
	}
	rval_arr = (double*)malloc(sizeof(double)*size);
	if(rval_arr == NULL) {
	  return NULL;
	}
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%le",&rval_arr[i]);
	}

	next_realelt(NULL);
	/* 1 is current dimension (start value) */
	res =(void*) Values__ARRAY(generate_array('r',1,desc,(void*)rval_arr));
      }
      /* REAL ARRAY END, INTEGER ARRAY START*/

      if (desc->type == 'i') {
	int currdim,el,i;
	/* Create array to hold inserted values, mult of dimensions as size */
	size = 1;
	for (currdim=0;currdim < desc->ndims; currdim++) {
	  size *= desc->dim_size[currdim];
	}
	ival_arr = (int*)malloc(sizeof(int)*size);
	if(ival_arr==NULL) {
	  return NULL;
	}
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%f",&ival_arr[i]);
	}
	next_intelt(NULL);
	res = (void*) Values__ARRAY(generate_array('i',1,desc,(void*)ival_arr));
      }
      /*INTEGER ARRAY ENDS BOOLEAN ARRAY START*/

	if (desc->type == 'b')
	{
		int currdim,el,i;
		/* Create array to hold inserted values, mult of dimensions as size */
		size = 1;
		for (currdim=0;currdim < desc->ndims; currdim++) {
	  		size *= desc->dim_size[currdim];
		}
		rval_arr = (double*)malloc(sizeof(double)*size);
		if(rval_arr==NULL) {
	  		return NULL;
		}
		/* Fill the array in reversed order */
		for(i=size-1;i>=0;i--) {
	  		fscanf(file,"%le",&rval_arr[i]);
		}
			next_intelt(NULL);
			res = (void*) Values__ARRAY(generate_array('b',1,desc,(void*)rval_arr));
	}
	if (desc->type == 's') {
		printf("Error, array of strings not impl. yet.\n");
	}
  }
  return res;
}

RML_BEGIN_LABEL(System__readValuesFromFile)
{
  int stat=0;
  int varcount=0;
  type_description desc;
  void *lst = (void*)mk_nil();
  void *res = NULL;
  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"r");
  if (file == NULL) {
    RML_TAILCALLK(rmlFC);
  }

  /* Read the first value */
  stat = read_type_description(file,&desc);
  if (stat != 0) {
    printf("Error reading values from file\n");
    RML_TAILCALLK(rmlFC);
  }

  while (stat == 0) { /* Loop for tuples. At the end of while, we try to read another description */
    res = read_one_value_from_file(file, &desc);
    if (res == NULL) {
      printf("Error reading values from file2 %s .\n", filename);
      RML_TAILCALLK(rmlFC);
    }
    lst = (void*)mk_cons(res, lst);
    varcount++;
    read_to_eol(file);
    stat = read_type_description(file,&desc);
    /*
    printf("varcount is : %d\n", varcount);
    printf("stat is : %d\n", stat);
    */
  }
  if (varcount > 1) { /* if tuple */
    rmlA0 = lst;
    rml_prim_once(RML__list_5freverse);
    rmlA0 = (void*) Values__TUPLE(rmlA0);
  }
  else {
    rmlA0 = (void*)res;
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
#endif

RML_BEGIN_LABEL(System__readPtolemyplotDataset)
{
  rml_sint_t i,size;
  char **vars;
  char* filename = RML_STRINGDATA(rmlA0);
  void *lst = rmlA1;
  rml_sint_t datasize = RML_UNTAGFIXNUM(rmlA2);
  void* p = NULL;
  rmlA0 = lst;
  rml_prim_once(RML__list_5flength);
  size = RML_UNTAGFIXNUM(rmlA0);

  vars = (char**)malloc(sizeof(char*)*size);
  for (i=0,p=lst;i<size;i++) {
    vars[i]=RML_STRINGDATA(RML_CAR(p));
    p=RML_CDR(p);
  }
  rmlA0 = (void*)read_ptolemy_dataset(filename,size,vars,datasize);
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }

  rml_prim_once(Values__reverseMatrix);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__readPtolemyplotVariables)
{
  rml_sint_t i,size;
  char* filename = RML_STRINGDATA(rmlA0);
  char* visvars = RML_STRINGDATA(rmlA1);
  void* p;

  rmlA0 = (void*)read_ptolemy_variables(filename, visvars);
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }

//  rml_prim_once(Values__reverseMatrix);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__readPtolemyplotDatasetSize)
{
  int size;
  char* filename = RML_STRINGDATA(rmlA0);
  void* p;

  size=read_ptolemy_dataset_size(filename);

  rmlA0 = (void*)Values__INTEGER(mk_icon(size));
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__writePtolemyplotDataset)
{
  char *filename = RML_STRINGDATA(rmlA0);
  void *value = rmlA1;


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
  int hash=0, c=0;
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

#if 0
void* generate_array(char type, int curdim, type_description *desc, void *data)

{
  void *lst;
  double rval;
  int ival;
  int i;
  lst = (void*)mk_nil();
  if (curdim == desc->ndims)
  {
    for (i=0; i< desc->dim_size[curdim-1]; i++)
    {
      if (type == 'r')
      {
	    rval = next_realelt((double*)data);
	    lst = (void*)mk_cons(Values__REAL(mk_rcon(rval)),lst);
      }
      else if (type == 'i')
      {
	    ival = next_intelt((int*)data);
	    lst = (void*)mk_cons(Values__INTEGER(mk_icon(ival)),lst);
      }
      else if (type == 'b')
      {
	    rval = next_realelt((double*)data);
	    lst = (void*)mk_cons(Values__BOOL(rval?RML_TRUE:RML_FALSE/*mk_bcon(rval)*/),lst);
      }
    }
  }
  else
  {
    for (i=0; i< desc->dim_size[curdim-1]; i++) {
    lst = (void*)mk_cons(Values__ARRAY(generate_array(type,curdim+1,desc,data)),lst);
  }
  }
  return lst;
}
#endif

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
  double timeStamp 	= rml_prim_get_real(rmlA0);
  void *timeValues 	= rmlA1;
  void *varValues 	= rmlA2;

  // values to find the correct range
  double preValue 	= 0.0;
  double preTime 	= 0.0;
  double nowValue 	= 0.0;
  double nowTime 	= 0.0;

  // linjear interpolation data
  double timedif 			= 0.0;
  double valuedif			= 0.0;
  double valueSlope			= 0.0;
  double timeDifTimeStamp	= 0.0;

  // break loop and return value
  int valueFound = 0;
  double returnValue = 0.0;

for(; RML_GETHDR(timeValues) == RML_CONSHDR && valueFound == 0; timeValues = RML_CDR(timeValues), varValues = RML_CDR(varValues)) {


    nowValue 	= rml_prim_get_real(RML_CAR(varValues));
  	nowTime 	=  rml_prim_get_real(RML_CAR(timeValues));


	if(timeStamp == nowTime){
    	valueFound 	= 1;
    	returnValue = nowValue;

    } else if (timeStamp >= preTime && timeStamp <= nowTime) { // need to do interpolation
    	valueFound 			= 1;
    	timedif 			= nowTime - preTime;
    	valuedif			= nowValue - preValue;
    	valueSlope 			= valuedif / timedif;
    	timeDifTimeStamp 	= timeStamp - preTime;
    	returnValue 		= preValue + (valueSlope*timeDifTimeStamp);
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
		preValue 	= nowValue;
  		preTime 	= nowTime;

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

//	emulateStreamData(data, 7778, "Plot by OpenModelica", "time", "", 1, 1, 0, 0, 0, 0, 0, 0, "linear");

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
//	enableSendData(enable);
	  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__setDataPort)
{
	int port = RML_UNTAGFIXNUM(rmlA0);
	char* p = malloc(10);
	sprintf(p, "%s", port);
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
//	setVariableFilter(variables);
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
  struct stat attrib;			      // create a file attribute structure
  double elapsedTime;                 // the time elapsed as double
  int result;					      // the result of the function call

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

#endif /* MINGW32 */

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

inline modelica_ptr_t lookup_ptr(modelica_integer index)
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
  } else {
    --(lib->cnt);
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
  } else {
    --(lib->cnt);
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__executeFunction)
{
  modelica_integer funcIndex = RML_UNTAGFIXNUM(rmlA0);
  modelica_ptr_t func = NULL;
  int retval = -1;
  void *retarg = NULL;
  func = lookup_ptr(funcIndex);
  if (func == NULL)
    RML_TAILCALLK(rmlFC);
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

  return Values__ARRAY(lst);
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
  case Values__ARRAY_3dBOX1: {
    void *data = RML_STRUCTDATA(value)[0];
    if (parse_array(desc, data)) {
      printf("Parsing of array failed\n");
      return -1;
    }
  }; break;
  case Values__RECORD_3dBOX3: {
    void *data = RML_STRUCTDATA(value)[1];
    void *names = RML_STRUCTDATA(value)[2];
    desc->type = TYPE_DESC_RECORD;
    while ((RML_GETHDR(names) != RML_NILHDR)
           &&
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
  case Values__ENUM_3dBOX1:
  case Values__LIST_3dBOX1:
  case Values__CODE_3dBOX1:
    /* unsupported */
    return -1;
  default:
    return -1;
  }

  return 0;
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

void *type_desc_to_value(type_description *desc)
{
  switch (desc->type) {
  case TYPE_DESC_NONE:
    return NULL;
  case TYPE_DESC_REAL:
    return (void *) Values__REAL(mk_rcon(desc->data.real));
  case TYPE_DESC_INT:
    return (void *) Values__INTEGER(mk_icon(desc->data.integer));
  case TYPE_DESC_BOOL:
    return (void *) Values__BOOL(RML_PRIM_MKBOOL(desc->data.boolean));
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
                                   varlst, namelst);
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
  case TYPE_DESC_COMPLEX:
    return NULL;
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
  case Values__ARRAY_3dBOX1:
    return (1 + get_array_type_and_dims(desc, RML_STRUCTDATA(item)[0]));
  case Values__ENUM_3dBOX1:
  case Values__LIST_3dBOX1:
  case Values__TUPLE_3dBOX1:
  case Values__RECORD_3dBOX3:
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
    if (RML_HDRCTOR(RML_GETHDR(item)) == Values__ARRAY_3dBOX1) {
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
      if (RML_HDRCTOR(RML_GETHDR(item)) != Values__ARRAY_3dBOX1)
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
#if 0 /* only used for debug */
static void puttype(const type_description *desc)
{
  switch (desc->type) {
  case TYPE_DESC_REAL:
    fprintf(stderr, "REAL: %g\n", desc->data.real);
    break;
  case TYPE_DESC_INT:
    fprintf(stderr, "INT: %d\n", desc->data.integer);
    break;
  case TYPE_DESC_BOOL:
    fprintf(stderr, "BOOL: %c\n", desc->data.boolean ? 't' : 'f');
    break;
  case TYPE_DESC_STRING:
    fprintf(stderr, "STR: '%s'\n", desc->data.string);
    break;
  case TYPE_DESC_TUPLE: {
    size_t e;
    fprintf(stderr, "TUPLE (%u):\n", desc->data.tuple.elements);
    for (e = 0; e < desc->data.tuple.elements; ++e) {
      fprintf(stderr, "\t");
      puttype(desc->data.tuple.element + e);
    }
  }; break;
  case TYPE_DESC_REAL_ARRAY: {
    int d;
    fprintf(stderr, "REAL ARRAY [%d] (", desc->data.real_array.ndims);
    for (d = 0; d < desc->data.real_array.ndims; ++d)
      fprintf(stderr, "%d, ", desc->data.real_array.dim_size[d]);
    fprintf(stderr, ")\n");
    if (desc->data.real_array.ndims == 1) {
      int e;
      fprintf(stderr, "\t[");
      for (e = 0; e < desc->data.real_array.dim_size[0]; ++e)
        fprintf(stderr, "%g, ",
                ((modelica_real *) desc->data.real_array.data)[e]);
      fprintf(stderr, "]\n");
    }
  }; break;
  case TYPE_DESC_INT_ARRAY: {
    int d;
    fprintf(stderr, "INT ARRAY [%d] (", desc->data.int_array.ndims);
    for (d = 0; d < desc->data.int_array.ndims; ++d)
      fprintf(stderr, "%d, ", desc->data.int_array.dim_size[d]);
    fprintf(stderr, ")\n");
    if (desc->data.int_array.ndims == 1) {
      int e;
      fprintf(stderr, "\t[");
      for (e = 0; e < desc->data.int_array.dim_size[0]; ++e)
        fprintf(stderr, "%d, ",
                ((modelica_integer *) desc->data.int_array.data)[e]);
      fprintf(stderr, "]\n");
    }
  }; break;
  case TYPE_DESC_BOOL_ARRAY: {
    int d;
    fprintf(stderr, "BOOL ARRAY [%d] (", desc->data.bool_array.ndims);
    for (d = 0; d < desc->data.bool_array.ndims; ++d)
      fprintf(stderr, "%d, ", desc->data.bool_array.dim_size[d]);
    fprintf(stderr, ")\n");
    if (desc->data.bool_array.ndims == 1) {
      int e;
      fprintf(stderr, "\t[");
      for (e = 0; e < desc->data.bool_array.dim_size[0]; ++e)
        fprintf(stderr, "%c, ",
                ((modelica_boolean *) desc->data.bool_array.data)[e] ? 'T':'F');
      fprintf(stderr, "]\n");
    }
  }; break;
  case TYPE_DESC_STRING_ARRAY: {
    int d;
    fprintf(stderr, "STRING ARRAY [%d] (", desc->data.string_array.ndims);
    for (d = 0; d < desc->data.string_array.ndims; ++d)
      fprintf(stderr, "%d, ", desc->data.string_array.dim_size[d]);
    fprintf(stderr, ")\n");
    if (desc->data.string_array.ndims == 1) {
      int e;
      fprintf(stderr, "\t[");
      for (e = 0; e < desc->data.string_array.dim_size[0]; ++e)
        fprintf(stderr, "%s, ",
                ((modelica_string_t *) desc->data.string_array.data)[e]);
      fprintf(stderr, "]\n");
    }
  }; break;
  case TYPE_DESC_COMPLEX:
    fprintf(stderr, "COMPLEX\n");
    break;
  case TYPE_DESC_NONE:
    fprintf(stderr, "NONE\n");
    break;
  case TYPE_DESC_RECORD:
	  {
		  int i;
		  fprintf(stderr, "RECORD: %s\n", desc->data.record.record_name);
          for (i = 0; i < desc->data.record.elements; i++)
		  {
			  fprintf(stderr, "NAME: %s\n", desc->data.record.name[i]);
              puttype(&(desc->data.record.element[i]));
		  }
	  }
    break;
  }
  fflush(stderr);
}
#endif
static int execute_function(void *in_arg, void **out_arg,
                            int (* func)(type_description *,
                                         type_description *))
{
  type_description arglst[RML_NUM_ARGS + 1], *arg = NULL;
  type_description retarg;
  void *v = NULL;
  int retval;
  state mem_state;

  mem_state = get_memory_state();

  v = in_arg;
  arg = arglst;

  while (RML_GETHDR(v) != RML_NILHDR) {
    void *val = RML_CAR(v);
    if (value_to_type_desc(val, arg)) {
      restore_memory_state(mem_state);
      return -1;
    }

    /* puttype(arg); */

    ++arg;
    v = RML_CDR(v);
  }
  init_type_description(arg);
  init_type_description(&retarg);
  retarg.retval = 1;
  retval = func(arglst, &retarg);
  arg = arglst;
  while (arg->type != TYPE_DESC_NONE) {
	/* puttype(arg); */
    free_type_description(arg);
    ++arg;
  }

  restore_memory_state(mem_state);

  if (retval) {
    return 1;
  } else {
    /*
      fprintf(stderr, "X - Retarg:\n");
      puttype(&retarg);
    */

    (*out_arg) = type_desc_to_value(&retarg);
    /* out_arg doesn't seem to get freed, something we can do anything about?*/
	/* puttype(&retarg); */
    free_type_description(&retarg);

    if ((*out_arg) == NULL) {
      printf("Unable to parse returned values.\n");
      return -1;
    }

    return 0;
  }
}
