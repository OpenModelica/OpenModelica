#include "rml.h"
#include <stdio.h>
#include <assert.h>

#define GROWTH_FACTOR 1.4  /* According to some roumours of buffer growth */
#define INITIAL_BUFSIZE 4000 /* Seems reasonable */
char *buf = NULL;
char *errorBuf = NULL;

int nfilled=0;
int cursize=0;

int errorNfilled=0;
int errorCursize=0;

void increase_buffer(void);
void error_increase_buffer(void);
void Print_5finit(void)
{

}

RML_BEGIN_LABEL(Print__print_5ferror_5fbuf)
{
  char* str = RML_STRINGDATA(rmlA0);
  /*  printf("cursize: %d, nfilled %d, strlen: %d\n",cursize,nfilled,strlen(str));*/
  
  assert(str != NULL);
  while (errorNfilled + strlen(str)+1 > errorCursize) {
    error_increase_buffer();
    /* printf("increased -- cursize: %d, nfilled %d\n",cursize,nfilled);*/
  }

  sprintf((char*)(errorBuf+strlen(errorBuf)),"%s",str);
  errorNfilled=strlen(errorBuf);

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
    error_increase_buffer();
  }

  rmlA0=(void*)mk_scon(errorBuf);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Print__print_5fbuf)
{
  char* str = RML_STRINGDATA(rmlA0);
  /*  printf("cursize: %d, nfilled %d, strlen: %d\n",cursize,nfilled,strlen(str));*/
  
  assert(str != NULL);
  while (nfilled + strlen(str)+1 > cursize) {
    increase_buffer();
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
    increase_buffer();
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
  }

  fprintf(file,"%s",buf);
  
  if (fclose(file) != 0) {
    /* RMLFAIL */
  }
  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


void increase_buffer(void) 
{
  char * new_buf;
  int new_size;

  if (cursize == 0) {
    new_buf = (char*)malloc(INITIAL_BUFSIZE);
    assert(new_buf != NULL);
    new_buf[0]='\0';
    cursize = INITIAL_BUFSIZE;
  } else {
    new_buf = (char*)malloc(new_size =(int) (cursize * GROWTH_FACTOR));
    assert(new_buf != NULL);
    memcpy(new_buf,buf,cursize);
    cursize = new_size;
  }
  if (buf) {
    free(buf);
  }
  buf = new_buf;
}

void error_increase_buffer(void) 
{
  char * new_buf;
  int new_size;

  if (errorCursize == 0) {
    new_buf = (char*)malloc(INITIAL_BUFSIZE);
    assert(new_buf != NULL);
    new_buf[0]='\0';
    errorCursize = INITIAL_BUFSIZE;
  } else {
    new_buf = (char*)malloc(new_size =(int) (errorCursize * GROWTH_FACTOR));
    assert(new_buf != NULL);
    memcpy(new_buf,errorBuf,errorCursize);
    errorCursize = new_size;
  }
  if (errorBuf) {
    free(errorBuf);
  }
  errorBuf = new_buf;
}
