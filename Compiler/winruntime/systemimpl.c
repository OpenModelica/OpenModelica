/*
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "rml.h"
#include <stdio.h>
#include <stdlib.h>
#include <direct.h>
#include <assert.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include "../values.h"
#include "../absyn_builder/yacclib.h"
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "read_write.h"

#define MAXPATHLEN MAX_PATH

char * cc=NULL;
char * cflags=NULL;

void * read_ptolemy_dataset(char*filename, int size,char**vars,int datasize);
void * read_ptolemy_dataset_size(char*filename);
void * generate_array(char,int,type_description *,void *data);
float next_realelt(float*);
int next_intelt(int*);

void set_cc(char *str)
{
  if (cc != NULL) {
    free(cc);
  }
  cc = (char*)malloc(strlen(str)+1);
  assert(cc != NULL);
  memcpy(cc,str,strlen(str)+1);
}

void set_cflags(char *str)
{
  if (cflags != NULL) {
    free(cflags);
  }
  cflags = (char*)malloc(strlen(str)+1);
  assert(cflags != NULL);
  memcpy(cflags,str,strlen(str)+1);
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

char* _replace(char* source_str,char* search_str,char* replace_str)
{
  char *ostr, *nstr = NULL, *pdest = "";
  int length, nlen;
  unsigned int nstr_allocated;
  unsigned int ostr_allocated;
  
  if(!source_str || !search_str || !replace_str){
    printf("Not enough arguments\n");
    return NULL;
  }
  ostr_allocated = sizeof(char) * (strlen(source_str)+1);
  ostr = malloc( sizeof(char) * (strlen(source_str)+1));
  if(!ostr){
    printf("Insufficient memory available\n");
    return NULL;
  }
  strcpy(ostr, source_str);

  while(pdest)
    {
      pdest = strstr( ostr, search_str );
      length = (int)(pdest - ostr);

      if ( pdest != NULL )
        {
          ostr[length]='\0';
          nlen = strlen(ostr)+strlen(replace_str)+strlen( strchr(ostr,0)+strlen(search_str) )+1;
          if( !nstr || /* _msize( nstr ) */ nstr_allocated < sizeof(char) * nlen){
            nstr_allocated = sizeof(char) * nlen;
            nstr = malloc( sizeof(char) * nlen );
          }
          if(!nstr){
            printf("Insufficient memory available\n");
            return NULL;
          }

          strcpy(nstr, ostr);
          strcat(nstr, replace_str);
          strcat(nstr, strchr(ostr,0)+strlen(search_str));

          if( /* _msize(ostr) */ ostr_allocated < sizeof(char)*strlen(nstr)+1 ){
            ostr_allocated = sizeof(char)*strlen(nstr)+1;
            ostr = malloc(sizeof(char)*strlen(nstr)+1 );
          }
          if(!ostr){
            printf("Insufficient memory available\n");
            return NULL;
          }
          strcpy(ostr, nstr);
        }
    }
  if(nstr)
    free(nstr);
  return ostr;
}

 

void System_5finit(void)
{
	char* path;
	char* newPath;
	char* omhome;
	char* mingwpath;
	set_cc("gcc");
	set_cflags("-I%OPENMODELICAHOME%\\c_runtime -L%OPENMODELICAHOME%\\c_runtime -lc_runtime %MODELICAUSERCFLAGS%");
	path = getenv("PATH");
	omhome = getenv("OPENMODELICAHOME");
	if (omhome) {
		mingwpath = malloc(strlen(omhome)+20);
		sprintf(mingwpath,"%s\\mingw\\bin", omhome); 
		if (strncmp(mingwpath,path,strlen(mingwpath))!=0) {
			newPath = malloc(strlen(path)+strlen(mingwpath)+10);
			sprintf(newPath,"PATH=%s;%s",mingwpath,path);
			putenv(newPath);
			free(newPath);
		}
		free(mingwpath);
	}
}

RML_BEGIN_LABEL(System__vector_5fsetnth)
{
  /* This will not work until the garbage collector in RML is rewritten
    such that is can handle side effects correctly. 
  */
    rml_uint_t nelts = 0;
    void *vec = rmlA0;
    rml_uint_t i = (rml_uint_t)RML_UNTAGFIXNUM(rmlA1);
    if( i >= RML_HDRSLOTS(RML_GETHDR(vec)) ) {
      RML_TAILCALLK(rmlFC);
    } else {
      RML_STRUCTDATA(vec)[i] = rmlA2;      
      RML_TAILCALLK(rmlSC);
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

RML_BEGIN_LABEL(System__remove_5ffirst_5fand_5flast_5fchar)
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
        }


      res[length] = '\0';  
    }
  if(start_pos < end_pos)
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

RML_BEGIN_LABEL(System__string_5freplace)
{
  char *str = /* strdup( */RML_STRINGDATA(rmlA0)/* ) */;
  char *source = /* strdup( */RML_STRINGDATA(rmlA1)/* ) */;
  char *target =/*  strdup( */RML_STRINGDATA(rmlA2)/* ) */;
  char * res=0;
/*   printf("in '%s' replace '%s' with '%s'\n",str,source,target); */
  res = _replace(str,source,target);
  if (res == NULL) {
/*      printf("res == NULL\n");  */
    RML_TAILCALLK(rmlFC);
  }
  rmlA0 = (void*) mk_scon(res);
/*   printf("Replace result: '%s'\n",res); */
  free(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__compile_5fc_5ffile)
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

  sprintf(command,"%s %s -o %s %s",cc,str,exename,cflags);
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

RML_BEGIN_LABEL(System__set_5fc_5fcompiler)
{
  char* str = RML_STRINGDATA(rmlA0);
  set_cc(str);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__set_5fc_5fflags)
{
  char* str = RML_STRINGDATA(rmlA0);
  set_cflags(str);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__execute_5ffunction)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  int ret_val;
  sprintf(command,".\\%s %s_in.txt %s_out.txt",str,str,str);
  ret_val = system(command);
  
  if (ret_val != 0) {
    RML_TAILCALLK(rmlFC);
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__system_5fcall)
{
	int ret_val;
	char* str = RML_STRINGDATA(rmlA0);
	ret_val	= system(str);
	rmlA0	= (void*) mk_icon(ret_val);

	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__path_5fdelimiter)
{
  rmlA0 = (void*) mk_scon("\\");

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__group_5fdelimiter)
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
  getcwd(buf,MAXPATHLEN);
  rmlA0 = (void*) mk_scon(buf);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__write_5ffile)
{
  char* data = RML_STRINGDATA(rmlA1);
  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"w");
  if (file == NULL) { 
    printf("error opening file: %s\n",filename); 
    RML_TAILCALLK(rmlFC);
  } 
  fprintf(file,"%s",data);
  fclose(file);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__read_5ffile)
{
  char* filename = RML_STRINGDATA(rmlA0);
  char* buf;
  int res;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0)
  {
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

RML_BEGIN_LABEL(System__modelicapath)
{
  char *path = getenv("MODELICAPATH");
  if (path == NULL) 
      RML_TAILCALLK(rmlFC);
  
  rmlA0 = (void*) mk_scon(path);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__read_5fenv)
{
  char* envname = RML_STRINGDATA(rmlA0);
  char *envvalue = getenv(envname);
  if (envvalue == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  rmlA0 = (void*) mk_scon(envvalue);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/* adrpo@ida added 2005-11-24 */
RML_BEGIN_LABEL(System__set_5fenv)
{
  char* envname = RML_STRINGDATA(rmlA0);
  char* envvalue = RML_STRINGDATA(rmlA1);
  int overwrite = (int)RML_IMMEDIATE(RML_UNTAGFIXNUM(rmlA2));
  int setenv_result = 0;
  char *temp = (char*)malloc(strlen(envname)+strlen(envvalue)+2);
  sprintf(temp,"%s=%s", envname, envvalue);
  setenv_result = _putenv(temp); 
  rmlA0 = (void*) mk_icon(setenv_result);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__sub_5fdirectories)
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
		CloseHandle(sh);
	}
	rmlA0 = (void*)res;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__mo_5ffiles)
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
		CloseHandle(sh);
	}
	rmlA0 = (void*)res;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

void* read_one_value_from_file(FILE* file, type_description* desc)
{
  void *res=NULL;
  int ival;
  float rval;
  float *rval_arr;
  int *ival_arr;
  int size;
  if (desc->ndims == 0) /* Scalar value */ 
  {
    if (desc->type == 'i') {
      fscanf(file,"%d",&ival);
      res =(void*) Values__INTEGER(mk_icon(ival));
    } else if (desc->type == 'r') {
      fscanf(file,"%e",&rval);
      res = (void*) Values__REAL(mk_rcon(rval));
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
      if (desc->type == 'r') {
	/* Create array to hold inserted values, max dimension as size */
	size = 1;
	for (currdim=0;currdim < desc->ndims; currdim++) {
	  size *= desc->dim_size[currdim];
	}
	rval_arr = (float*)malloc(sizeof(float)*size);
	if(rval_arr == NULL) {
	  return NULL;
	}
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%e",&rval_arr[i]);
	}
	
	next_realelt(NULL);
	/* 1 is current dimension (start value) */
	res =(void*) Values__ARRAY(generate_array('r',1,desc,(void*)rval_arr)); 
      }
      
      if (desc->type == 'i') {
	int currdim,el,i;
	/* Create array to hold inserted values, mult of dimensions as size */
	size = 1;
	for (currdim=0;currdim < desc->ndims; currdim++) {
	  size *= desc->dim_size[currdim];
	}
	ival_arr = (int*)malloc(sizeof(int)*size);
	if(rval_arr==NULL) {
	  return NULL;
	}
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%f",&ival_arr[i]);
	}
	next_intelt(NULL);
	res = (void*) Values__ARRAY(generate_array('i',1,desc,(void*)ival_arr));	
      }  
      if (desc->type == 's') {
	printf("Error, array of strings not impl. yet.\n");
      }
    }
  return res;
}

RML_BEGIN_LABEL(System__read_5fvalues_5ffrom_5ffile)
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
      printf("Error reading values from file2\n");
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

RML_BEGIN_LABEL(System__read_5fptolemyplot_5fdataset_5fsize)
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


RML_BEGIN_LABEL(System__read_5fptolemyplot_5fdataset)
{
  int i,size;
  char **vars;
  char* filename = RML_STRINGDATA(rmlA0);
  void * lst = rmlA1;
  int datasize = (int)RML_IMMEDIATE(RML_UNTAGFIXNUM(rmlA2));
  void* p;
  rmlA0 = lst;
  rml_prim_once(RML__list_5flength);
  size = (int)RML_IMMEDIATE(RML_UNTAGFIXNUM(rmlA0));
  
  vars = (char**)malloc(sizeof(char*)*size);
  for (i=0,p=lst;i<size;i++) {
    vars[i]=RML_STRINGDATA(RML_CAR(p));
    p=RML_CDR(p);
  }
  rmlA0 = (void*)read_ptolemy_dataset(filename,size,vars,datasize);
  if (rmlA0 == NULL) {
    RML_TAILCALLK(rmlFC);
  }
#ifdef FIX_JAVA_NAMES
  rml_prim_once(Values__reverseMatrix);
#else
  rml_prim_once(Values__reverse_5fmatrix);
#endif

  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL


RML_BEGIN_LABEL(System__write_5fptolemyplot_5fdataset)
{
  char *filename = RML_STRINGDATA(rmlA0);
  void *value = rmlA1;
  

  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL


RML_BEGIN_LABEL(System__time)
{
  float _time;
  clock_t cl;
  
  cl=clock();
  
  _time = (float)cl / (float)CLOCKS_PER_SEC;
  /*  printf("clock : %d\n",cl); */
  /* printf("returning time: %f\n",time);  */
  rmlA0 = (void*) mk_rcon(_time);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__hash)
{
  char *str = RML_STRINGDATA(rmlA0);
  int res=0,i=0;
  while( str[i]){
    res+=(int)str[i++];
  }

  rmlA0 = (void*) mk_icon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__regular_5ffile_5fexist)
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

RML_BEGIN_LABEL(System__directory_5fexist)
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

float next_realelt(float *arr)
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

void * generate_array(char type, int curdim, type_description *desc,void *data)

{
  void *lst;
  float rval;
  int ival;
  int i;
  lst = (void*)mk_nil();
  if (curdim == desc->ndims) {
    for (i=0; i< desc->dim_size[curdim-1]; i++) {
      if (type == 'r') {
	rval = next_realelt((float*)data);
	lst = (void*)mk_cons(Values__REAL(mk_rcon(rval)),lst);
	
      } else if (type == 'i') {
	ival = next_intelt((int*)data);
	lst = (void*)mk_cons(Values__INTEGER(mk_icon(ival)),lst);
      }
    }
  } else {
    for (i=0; i< desc->dim_size[curdim-1]; i++) {
      lst = (void*)mk_cons(Values__ARRAY(generate_array(type,curdim+1,desc,data)),lst);
    }
  }
  return lst;
}

char* class_names_for_simulation = NULL;
RML_BEGIN_LABEL(System__get_5fclassnames_5ffor_5fsimulation)
{
  if(class_names_for_simulation)
    rmlA0 = (void*) mk_scon(strdup(class_names_for_simulation));
  else
    rmlA0 = (void*) mk_scon("{}");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__set_5fclassnames_5ffor_5fsimulation)
{
  char* class_names = RML_STRINGDATA(rmlA0);
  if(class_names_for_simulation)
    free(class_names_for_simulation);

  class_names_for_simulation = (char*)malloc(strlen(class_names)+1);
  assert(class_names_for_simulation != NULL);
  memcpy(class_names_for_simulation,class_names,strlen(class_names)+1);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

char* compile_command = NULL;
RML_BEGIN_LABEL(System__set_5fcompile_5fcommand)
{
  char* command = RML_STRINGDATA(rmlA0);
  if(compile_command)
    free(compile_command);

  compile_command = (char*)malloc(strlen(command)+1);
  if (compile_command == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(compile_command,command,strlen(command)+1);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__get_5fcompile_5fcommand)
{
  if(compile_command)
    rmlA0 = (void*) mk_scon(strdup(compile_command));
  else
    rmlA0 = (void*) mk_scon("");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
