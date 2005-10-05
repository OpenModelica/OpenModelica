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
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include "../absyn_builder/yacclib.h"

#define GROWTH_FACTOR 1.4  /* According to some roumours of buffer growth */
#define INITIAL_BUFSIZE 4000000 /* Seems reasonable */
char *buf = NULL;
char *errorBuf = NULL;

int nfilled=0;
int cursize=0;

int errorNfilled=0;
int errorCursize=0;

int increase_buffer(void);
void error_increase_buffer(void);
void Print_5finit(void)
{

}


void print_error_buf_impl(char *str)
{
  /*  printf("cursize: %d, nfilled %d, strlen: %d\n",cursize,nfilled,strlen(str));*/
  
  assert(str != NULL);
  while (errorNfilled + strlen(str)+1 > errorCursize) {
    error_increase_buffer();
    /* printf("increased -- cursize: %d, nfilled %d\n",cursize,nfilled);*/
  }

  sprintf((char*)(errorBuf+strlen(errorBuf)),"%s",str);
  errorNfilled=strlen(errorBuf);
}

RML_BEGIN_LABEL(Print__print_5ferror_5fbuf)
{
 char* str = RML_STRINGDATA(rmlA0);
 print_error_buf_impl(str);

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
  long strl;	
  char* str = RML_STRINGDATA(rmlA0);

  if (str == NULL) {
	  	RML_TAILCALLK(rmlFC); 
  }
  strl = strlen(str);
  while (nfilled + strl+1 > cursize) {
	  if (!increase_buffer()) {
		  RML_TAILCALLK(rmlFC);
	  }
  }

  sprintf((char*)(buf+nfilled),"%s",str);
  nfilled=strlen(buf);

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
	if (new_buf == NULL) {
		return 0;
	}
	new_buf[0]='\0';
    cursize = INITIAL_BUFSIZE;
  } else {
    new_buf = (char*)malloc(new_size =(int) (cursize * GROWTH_FACTOR));
	if (new_buf == NULL) {
		return 0;
	}
    memcpy(new_buf,buf,cursize);
    cursize = new_size;
  }
  if (buf) {
    free(buf);
  }
  buf = new_buf;
  return 1;
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
