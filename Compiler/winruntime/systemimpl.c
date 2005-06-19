/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with OpenModelica; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

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
      res=malloc(length-2);
      for(i = 1; i < length - 1; ++i)
        res[i-1] = str[i];
      res[length-2] = '\0';  
    }
  rmlA0 = (void*) mk_scon(res);
  /* adrpo added 2004-10-29 */
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
  printf("compile using: %s\n",command);
  _putenv("GCC_EXEC_PREFIX="); 
//  _putenv("MODELICAUSERCFLAGS=-Dfoo"); 
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
	if (0 && str[0] == '\"') {
		char longname[MAX_PATH];
		char shortname[MAX_PATH];
		char* endpos = strstr(&str[1],"\"");
		char* tmp;
		char* pathend;
		char* mark;

		for(pathend = endpos; pathend > str && *pathend != '\\'; pathend--);
		
		strncpy(longname,&str[1],pathend-str-1);
		GetShortPathName(longname,shortname,MAX_PATH);
		tmp = strdup(str);
		sprintf(tmp,"%s%s",shortname,pathend);
		mark = strstr(tmp, "\"");
		if (mark) *mark = ' ';
	}
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
  assert(file != NULL);
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
    RML_TAILCALLK(rmlFC);
  }

  while (stat == 0) { /* Loop for tuples. At the end of while, we try to read another description */
    res = read_one_value_from_file(file, &desc);
    if (res == NULL) {
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
  rml_prim_once(Values__reverse_5fmatrix);

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
  while( str[i])
    res+=(int)str[i++];
      
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
