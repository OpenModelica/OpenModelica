#include "rml.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <sys/unistd.h>
#include <sys/stat.h>
#include "read_write.h"
#include "../values.h"
#include <dirent.h>
#include <time.h>
#include <sys/param.h> /* MAXPATHLEN */


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

char * cc=NULL;
char * cflags=NULL;

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
  set_cc("gcc");
  set_cflags("-I$MOSHHOME/../c_runtime -L$MOSHHOME/../c_runtime -lc_runtime -lm $MODELICAUSERCFLAGS");
}

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


RML_BEGIN_LABEL(System__strcmp)
{
  char *str = RML_STRINGDATA(rmlA0);
  char *str2 = RML_STRINGDATA(rmlA1);
  int res= strcmp(str,str2);

  rmlA0 = (void*) mk_icon(res);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__compile_5fc_5ffile)
{
  char* str = RML_STRINGDATA(rmlA0);
  char command[255];
  char exename[255];
  if(strlen(str) >= 255) {
    RML_TAILCALLK(rmlFC);
  }
  if (cc == NULL||cflags == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(exename,str,strlen(str)-2);
  exename[strlen(str)-2]='\0';

  sprintf(command,"%s %s -o %s %s",cc,str,exename,cflags);
  printf("compile using: %s\n",command);
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
  sprintf(command,"./%s %s_in.txt %s_out.txt",str,str,str);
  ret_val = system(command);  
  if (ret_val != 0) {
    RML_TAILCALLK(rmlFC);
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__system_5fcall)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
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


RML_BEGIN_LABEL(System__write_5ffile)
{
  char* data = RML_STRINGDATA(rmlA1);
  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"w");
  /*   assert(file != NULL); */
  if (file == NULL) {
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
  if (envvalue == NULL) 
  {
    RML_TAILCALLK(rmlFC);
  }
  rmlA0 = (void*) mk_scon(envvalue);

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


RML_BEGIN_LABEL(System__sub_5fdirectories)
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

RML_BEGIN_LABEL(System__mo_5ffiles)
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


RML_BEGIN_LABEL(System__read_5fvalues_5ffrom_5ffile)
{
  type_description desc;
  void * res, *res2;
  int ival;
  float rval;
  float *rval_arr;
  int *ival_arr;
  int size;

  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"r");
  if (file == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  
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
      int currdim,el,i;
      if (desc.type == 'r') {
	/* Create array to hold inserted values, max dimension as size */
	size = 1;
	for (currdim=0;currdim < desc.ndims; currdim++) {
	  size *= desc.dim_size[currdim];
	}
	rval_arr = (float*)malloc(sizeof(float)*size);
	if(rval_arr == NULL) {
	  RML_TAILCALLK(rmlFC);
	}
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%e",&rval_arr[i]);
	}

	next_realelt(NULL);
	/* 1 is current dimension (start value) */
	res =(void*) Values__ARRAY(generate_array('r',1,&desc,(void*)rval_arr)); 
      }
	
      if (desc.type == 'i') {
	int currdim,el,i;
	/* Create array to hold inserted values, mult of dimensions as size */
	size = 1;
	for (currdim=0;currdim < desc.ndims; currdim++) {
	  size *= desc.dim_size[currdim];
	}
	ival_arr = (int*)malloc(sizeof(int)*size);
	if(rval_arr==NULL) {
	  RML_TAILCALLK(rmlFC);
	}
	/* Fill the array in reversed order */
	for(i=size-1;i>=0;i--) {
	  fscanf(file,"%f",&ival_arr[i]);
	}
	next_intelt(NULL);
	res = (void*) Values__ARRAY(generate_array('i',1,&desc,(void*)ival_arr));
	
      }      
    }
  rmlA0 = (void*)res;
  RML_TAILCALLK(rmlSC);
}   
RML_END_LABEL

RML_BEGIN_LABEL(System__read_5fptolemyplot_5fdataset)
{
  int i,size;
  char **vars;
  char* filename = RML_STRINGDATA(rmlA0);
  void *lst = rmlA1;
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
  float time;
  clock_t cl;
  
  cl=clock();
  
  time = (float)cl / (float)CLOCKS_PER_SEC;
  /*  printf("clock : %d\n",cl); */
  /* printf("returning time: %f\n",time);  */
  rmlA0 = (void*) mk_rcon(time);
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

RML_BEGIN_LABEL(System__path_5fdelimiter)
{
  rmlA0 = (void*) mk_scon("/");

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__group_5fdelimiter)
{
  rmlA0 = (void*) mk_scon(":");

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(System__directory_5fexist)
{
  char* str = RML_STRINGDATA(rmlA0);
  int ret_val;
  struct stat buf;
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

RML_BEGIN_LABEL(System__regular_5ffile_5fexist)
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
    return 0.0;
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
