#include "rml.h"
#include <stdio.h>

#define GROWTH_FACTOR 1.4  /* According to some roumours of buffer growth */
#define INITIAL_BUFSIZE 4000 /* Seems reasonable */
char *buf = NULL;
char *errorBuf = NULL;

int nfilled=0;
int cursize=0;

int errorNfilled=0;
int errorCursize=0;

int increase_buffer(void);
int error_increase_buffer(void);
void Print_5finit(void)
{

}

int print_error_buf_impl(char *str)
{
  /*  printf("cursize: %d, nfilled %d, strlen: %d\n",cursize,nfilled,strlen(str));*/
  
  if (str == NULL) {
    return -1;
  }
  while (errorNfilled + strlen(str)+1 > errorCursize) {
    if (error_increase_buffer() != 0) {
      return -1;
    }
    /* printf("increased -- cursize: %d, nfilled %d\n",cursize,nfilled);*/
  }

  sprintf((char*)(errorBuf+strlen(errorBuf)),"%s",str);
  errorNfilled=strlen(errorBuf);
}

RML_BEGIN_LABEL(Print__print_5ferror_5fbuf)
{
  char* str = RML_STRINGDATA(rmlA0);
  if (print_error_buf_impl(str) != 0) {
    RML_TAILCALLK(rmlFC);
  }
  
  /*  printf("%s",str);*/
  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__clear_5ferror_5fbuf)
{
  errorNfilled=0;
  if (errorBuf != 0) {
    errorBuf[0]='\0';
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__get_5ferror_5fstring)
{
  if (errorBuf == 0) {
    if(error_increase_buffer() != 0) {
      RML_TAILCALLK(rmlFC);
    }
  }

  rmlA0=(void*)mk_scon(errorBuf);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Print__print_5fbuf)
{
  char* str = RML_STRINGDATA(rmlA0);
  /*  printf("cursize: %d, nfilled %d, strlen: %d\n",cursize,nfilled,strlen(str));*/
    
  while (nfilled + strlen(str)+1 > cursize) {
    if(increase_buffer()!= 0) {
        RML_TAILCALLK(rmlFC);
    }
    /* printf("increased -- cursize: %d, nfilled %d\n",cursize,nfilled);*/
  }

  sprintf((char*)(buf+strlen(buf)),"%s",str);
  nfilled=strlen(buf);

  /*  printf("%s",str);*/

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__clear_5fbuf)
{
  nfilled=0;
  if (buf != 0) {
    buf[0]='\0';
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__get_5fstring)
{
  if (buf == 0) {
    if (increase_buffer() != 0) {
      RML_TAILCALLK(rmlFC);
    }
  }

  rmlA0=(void*)mk_scon(buf);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__write_5fbuf)
{
  char * filename = RML_STRINGDATA(rmlA0);
  FILE * file;

  file = fopen(filename,"w");
  
  if (file == NULL||buf == NULL || buf[0]=='\0') {
    /* HOWTO: RML fail */    
    /* RML_TAILCALLK(rmlFC); */
  }

  fprintf(file,"%s",buf);
  
  if (fclose(file) != 0) {
    /* RMLFAIL */
    /* RML_TAILCALLK(rmlFC); */
  }
  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


int increase_buffer(void) 
{
  char * new_buf;
  int new_size;

  if (cursize == 0) {
    new_buf = (char*)malloc(INITIAL_BUFSIZE);
    if (new_buf == NULL) { return -1; }
    new_buf[0]='\0';
    cursize = INITIAL_BUFSIZE;
  } else {
    new_buf = (char*)malloc(new_size =(int) (cursize * GROWTH_FACTOR));
    if (new_buf == NULL) { return -1; }
    memcpy(new_buf,buf,cursize);
    cursize = new_size;
  }
  if (buf) {
    free(buf);
  }
  buf = new_buf;
  return 0;
}

int error_increase_buffer(void) 
{
  char * new_buf;
  int new_size;

  if (errorCursize == 0) {
    new_buf = (char*)malloc(INITIAL_BUFSIZE);
    if (new_buf == NULL) { return -1; }
    new_buf[0]='\0';
    errorCursize = INITIAL_BUFSIZE;
  } else {
    new_buf = (char*)malloc(new_size =(int) (errorCursize * GROWTH_FACTOR));
    if (new_buf == NULL) { return -1; }
    memcpy(new_buf,errorBuf,errorCursize);
    errorCursize = new_size;
  }
  if (errorBuf) {
    free(errorBuf);
  }
  errorBuf = new_buf;
  return 0;
}
