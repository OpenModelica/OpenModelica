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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "rml.h"


#define GROWTH_FACTOR 1.4  /* According to some roumours of buffer growth */
#define INITIAL_BUFSIZE 4000 /* Seems reasonable */
char *buf = NULL;
char *errorBuf = NULL;

int nfilled=0;
int cursize=0;

int errorNfilled=0;
int errorCursize=0;
int increase_buffer(void);
int increase_buffer_fixed(int);
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
  return 0;
}

RML_BEGIN_LABEL(Print__setBufSize)
{
  int newSize = (int)RML_IMMEDIATE(RML_UNTAGFIXNUM(rmlA0));
  if (newSize > 0) {
  	printf(" setting init_size to: %d\n",newSize);
    increase_buffer_fixed(newSize);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__unSetBufSize)
{
  int newSize = (int)RML_IMMEDIATE(RML_UNTAGFIXNUM(rmlA0));
      increase_buffer_fixed(INITIAL_BUFSIZE);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

extern int showErrorMessages;

RML_BEGIN_LABEL(Print__printErrorBuf)
{
  char* str = RML_STRINGDATA(rmlA0);

  if (showErrorMessages) /* adrpo: should we show error messages while they happen? */
  {
    fprintf(stderr, "%s", str);
    fflush(stderr);
  }

  if (print_error_buf_impl(str) != 0) {
    RML_TAILCALLK(rmlFC);
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__clearErrorBuf)
{
  errorNfilled=0;
  if (errorBuf != 0) {
    /* adrpo 2008-12-15 free the error buffer as it might have got quite big meantime */
    free(errorBuf);
    errorBuf = NULL;
    errorCursize=0;
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__getErrorString)
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


RML_BEGIN_LABEL(Print__printBuf)
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

RML_BEGIN_LABEL(Print__clearBuf)
{
  nfilled=0;
  if (buf != 0) {
    /* adrpo 2008-12-15 free the print buffer as it might have got quite big meantime */
    free(buf);
    buf = NULL;
    cursize = 0;
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__getString)
{
  if(buf == NULL || buf[0]=='\0' || cursize==0){
	  rmlA0=(void*)mk_scon("");
	  RML_TAILCALLK(rmlSC);
  }
  if (buf == 0) {	
    if (increase_buffer() != 0) {
      RML_TAILCALLK(rmlFC);
    }
  }
  rmlA0=(void*)mk_scon(buf);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__writeBuf)
{
  char * filename = RML_STRINGDATA(rmlA0);
  FILE * file;

  file = fopen(filename,"w");

  if (file == NULL || buf == NULL || buf[0]=='\0') {
    /* HOWTO: RML fail */
    /* RML_TAILCALLK(rmlFC); */
  }

  fprintf(file,"%s",buf);
  fflush(file);

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
    new_buf = (char*)malloc(INITIAL_BUFSIZE*sizeof(char));
    if (new_buf == NULL) { return -1; }
    new_buf[0]='\0';
    cursize = INITIAL_BUFSIZE;
  } else {
  	//fprintf(stderr,"increasing buffer from %d to %d \n",cursize,((int)(cursize * GROWTH_FACTOR)));
    new_buf = (char*)malloc((new_size =(int) (cursize * GROWTH_FACTOR))*sizeof(char));
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

int increase_buffer_fixed(int increase)
{
  char * new_buf;
  int new_size;

  if (cursize == 0) {
    new_buf = (char*)malloc(increase*sizeof(char));
    if (new_buf == NULL) { return -1; }
    new_buf[0]='\0';
    cursize = increase;
  } else {
	new_size = (int)(cursize+increase);
  	//fprintf(stderr,"increasing buffer_FIXED_ from %d to %d \n",cursize,new_size);
    new_buf = (char*)malloc(new_size*sizeof(char));
    if (new_buf == NULL) { return -1; }
    //memcpy(new_buf,buf,cursize);
    cursize = new_size;
  }
  //printf("new buff size set to: %d\n",cursize);
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
    new_buf = (char*)malloc(INITIAL_BUFSIZE*sizeof(char));
    if (new_buf == NULL) { return -1; }
    new_buf[0]='\0';
    errorCursize = INITIAL_BUFSIZE;
  } else {
    new_buf = (char*)malloc((new_size =(int) (errorCursize * GROWTH_FACTOR))*sizeof(char));
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
