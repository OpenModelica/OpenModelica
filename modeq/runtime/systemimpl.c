#include "rml.h"
#include <stdio.h>
#include <assert.h>
#include "read_write.h"
#include "../values.h"

char * cc="/usr/bin/gcc";
char * cflags="-I$MOSHHOME/../c_runtime -L$MOSHHOME/../c_runtime -lc_runtime";

void System_5finit(void)
{

}

RML_BEGIN_LABEL(System__compile_5fc_5ffile)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  char exename[255];
  assert(strlen(str) < 255);
  if (cc == NULL||cflags == NULL) {
    /* RMLFAIL */
  }
  memcpy(exename,str,strlen(str)-1);
  sprintf(command,"%s %s -o %s %s",cc,str,exename,cflags);
  printf("compile using: %s\n",command);
 if (system(command) != 0) {
    /* RMLFAIL */
  }
       
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__set_5fc_5fcompiler)
{
  char* str = RML_STRINGDATA(rmlA0);
  if (cc != NULL) {
    free(cc);
  }
  cc = (char*)malloc(strlen(str)+1);
  assert(cc != NULL);
  memcpy(cc,str,strlen(str)+1);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(System__set_5fc_5fflags)
{
  char* str = RML_STRINGDATA(rmlA0);
  if (cflags != NULL) {
    free(cflags);
  }
  cflags = (char*)malloc(strlen(str)+1);
  assert(cflags != NULL);
  memcpy(cflags,str,strlen(str)+1);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__execute_5ffunction)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  int ret_val;
  sprintf(command,"%s %s_in.txt %s_out.txt",str,str,str);
  ret_val = system(command);
  
  assert(ret_val == 0);

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
  char* str = RML_STRINGDATA(rmlA0);
  printf("read_file, data:%s\n",str);
 RML_TAILCALLK(rmlSC);
}
RML_END_LABEL



RML_BEGIN_LABEL(System__read_5fvalues_5ffrom_5ffile)
{
  type_description desc;
  void * res, *res2;
  int ival;
  double rval;

  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"r");
  assert(file != NULL);
  
  read_type_description(file,&desc);
  
  if (desc.ndims == 0) /* Scalar value */ 
    {
      if (desc.type == 'i') {
	fscanf(file,"%d",&ival);
	res =(void*) Values__INTEGER(mk_icon(ival));
      } else if (desc.type == 'r') {
	fscanf(file,"%e",&rval);
	res = (void*) Values__REAL(mk_rcon(rval));
      } 
    } 
  else  /* Array value */
    {
      int currdim,el;
      if (desc.type == 'r') {
	res = (void*) mk_nil();
	for (currdim=0;currdim < desc.ndims; currdim++) {
	  res2 = (void*)mk_nil();
	  for (el=0; el < desc.dim_size[currdim]; el++) {
	    fscanf(file,"%e",&rval);
	    res2 =(void*) mk_cons(Values__REAL(mk_rcon(rval)),res2);
	  }
	  res = (void*) mk_cons(res,Values__ARRAY(res2));
	}
	res = (void*) Values__ARRAY(res2);
      }
  
      if (desc.type == 'r') {
	res = (void*) mk_nil();
	for (currdim=0;currdim < desc.ndims; currdim++) {
	  res2 = (void*) mk_nil();
	  for (el=0; el < desc.dim_size[currdim]; el++) {
	    fscanf(file,"%e",&rval);
	    res2 = (void*) mk_cons(Values__REAL(mk_rcon(rval)),res2);
	  }
	  res = (void*) mk_cons(res,Values__ARRAY(res2));
	}
	res = (void*) Values__ARRAY(res2);
      }      
    }
  rmlA0 = (void*)res;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
