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


#include <stdlib.h>
#include "printimpl.c"
#include "rml.h"

void Print_5finit(void)
{
  // set things to 0
  char *buf = NULL;
  char *errorBuf = NULL;

  int nfilled=0;
  int cursize=0;

  int errorNfilled=0;
  int errorCursize=0;
}

RML_BEGIN_LABEL(Print__saveAndClearBuf)
{
  long freeHandle,foundHandle=0;

  if (! savedBuffers) { 
    savedBuffers = (char**)malloc(MAXSAVEDBUFFERS*sizeof(char*));
    if (!savedBuffers) { 
     fprintf(stderr, "Internal error allocating savedBuffers in Print.saveAndClearBuf\n");
     RML_TAILCALLK(rmlFC);
    }
    memset(savedBuffers,0,MAXSAVEDBUFFERS);
  }
  if (! savedCurSize) { 
    savedCurSize = (long*)malloc(MAXSAVEDBUFFERS*sizeof(long*));
    if (!savedCurSize) { 
     fprintf(stderr, "Internal error allocating savedCurSize in Print.saveAndClearBuf\n");
     RML_TAILCALLK(rmlFC);
    }
    memset(savedCurSize,0,MAXSAVEDBUFFERS);
  }
  if (! savedNfilled) { 
    savedNfilled = (long*)malloc(MAXSAVEDBUFFERS*sizeof(long*));
    if (!savedNfilled) { 
     fprintf(stderr, "Internal error allocating savedNfilled in Print.saveAndClearBuf\n");
     RML_TAILCALLK(rmlFC);
     }
    memset(savedNfilled,0,MAXSAVEDBUFFERS);
  }
  for (freeHandle=0; freeHandle< MAXSAVEDBUFFERS; freeHandle++) {
    if (savedBuffers[freeHandle]==0)
    {
      foundHandle = 1;
      break;
    }
  }
  if (!foundHandle) {
      fprintf(stderr,"Internal error, can not save more than %d buffers, increase MAXSAVEDBUFFERS in printimpl.c\n",MAXSAVEDBUFFERS);
      RML_TAILCALLK(rmlFC);
  }
  savedBuffers[freeHandle] = buf;
  savedCurSize[freeHandle] = cursize;
  savedNfilled[freeHandle] = nfilled;
  buf = (char*)malloc(INITIAL_BUFSIZE*sizeof(char));  
  nfilled=0;
  cursize=0;
  rmlA0 = mk_icon(freeHandle);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__restoreBuf)
{
  long handle = (long)RML_UNTAGFIXNUM(rmlA0);

  if (handle < 0 || handle > MAXSAVEDBUFFERS-1) {
    fprintf(stderr,"Internal error, hanlde %d out of range. Should be in [%d,&d]\n",handle,0,MAXSAVEDBUFFERS-1);
    RML_TAILCALLK(rmlFC);
  } else {
    if (buf) { free(buf);}
    buf = savedBuffers[handle];
    cursize = savedCurSize[handle];
    nfilled = savedNfilled[handle];
    savedBuffers[handle] = 0;
    savedCurSize[handle] = 0;
    savedNfilled[handle] = 0;
    if (buf == 0) { 
      fprintf(stderr,"Internal error, handle %d does not contain a valid buffer pointer\n",handle);
      RML_TAILCALLK(rmlFC);
    }
    RML_TAILCALLK(rmlSC);
   }
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__setBufSize)
{
  long newSize = (long)RML_UNTAGFIXNUM(rmlA0); // adrpo: do not use RML_IMMEDIATE as is just a cast to void! IS NOT NEEDED!
  PrintImpl__setBufSize(newSize);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__unSetBufSize)
{
  PrintImpl__unSetBufSize();
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__printErrorBuf)
{
  if (PrintImpl__printErrorBuf(RML_STRINGDATA(rmlA0)))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__clearErrorBuf)
{
  PrintImpl__clearErrorBuf();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__getErrorString)
{
  const char* str = PrintImpl__getErrorString();
  rml_uint_t nbytes = strlen(str);
  struct rml_string *retval;
  if (str == NULL)
    RML_TAILCALLK(rmlFC);
  // use internal RML to allocate the string memory!
  retval = rml_prim_mkstring(nbytes,0);
  memcpy(retval->data, str, nbytes+1); /* including terminating '\0' */
  rmlA0 = RML_TAGPTR(retval);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Print__printBuf)
{
  if (PrintImpl__printBuf(RML_STRINGDATA(rmlA0)))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Print__clearBuf)
{
  PrintImpl__clearBuf();
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__getString)
{
  const char* str = PrintImpl__getString();
  rml_uint_t nbytes = strlen(str);
  struct rml_string *retval;
  if (str == NULL)
    RML_TAILCALLK(rmlFC);
  // use internal RML to allocate the string memory!
  retval = rml_prim_mkstring(nbytes,0);
  memcpy(retval->data, str, nbytes+1); /* including terminating '\0' */
  rmlA0 = RML_TAGPTR(retval);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__writeBuf)
{
  if (PrintImpl__writeBuf(RML_STRINGDATA(rmlA0)))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__getBufLength)
{
  rmlA0 = mk_icon(PrintImpl__getBufLength());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__printBufSpace)
{
  if (PrintImpl__printBufSpace((long)RML_UNTAGFIXNUM(rmlA0)))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Print__printBufNewLine)
{
  if (PrintImpl__printBufNewLine())
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Print__hasBufNewLineAtEnd)
{
  rmlA0 = PrintImpl__hasBufNewLineAtEnd() ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
