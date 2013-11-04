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
}

RML_BEGIN_LABEL(Print__saveAndClearBuf)
{
  long handle = PrintImpl__saveAndClearBuf(NULL);
  if (handle < 0)
    RML_TAILCALLK(rmlFC);
  rmlA0 = mk_icon(handle);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__restoreBuf)
{
  if (PrintImpl__restoreBuf(NULL,(long)RML_UNTAGFIXNUM(rmlA0)))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__setBufSize)
{
  long newSize = (long)RML_UNTAGFIXNUM(rmlA0); // adrpo: do not use RML_IMMEDIATE as is just a cast to void! IS NOT NEEDED!
  PrintImpl__setBufSize(NULL,newSize);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__unSetBufSize)
{
  PrintImpl__unSetBufSize(NULL);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__printErrorBuf)
{
  if (PrintImpl__printErrorBuf(NULL,RML_STRINGDATA(rmlA0)))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__clearErrorBuf)
{
  PrintImpl__clearErrorBuf(NULL);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__getErrorString)
{
  const char* str = PrintImpl__getErrorString(NULL);
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
  if (PrintImpl__printBuf(NULL,RML_STRINGDATA(rmlA0)))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Print__clearBuf)
{
  PrintImpl__clearBuf(NULL);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__getString)
{
  const char* str = PrintImpl__getString(NULL);
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
  if (PrintImpl__writeBuf(NULL,RML_STRINGDATA(rmlA0)))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__writeBufConvertLines)
{
  if (PrintImpl__writeBufConvertLines(NULL,RML_STRINGDATA(rmlA0)))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__getBufLength)
{
  rmlA0 = mk_icon(PrintImpl__getBufLength(NULL));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Print__printBufSpace)
{
  if (PrintImpl__printBufSpace(NULL,(long)RML_UNTAGFIXNUM(rmlA0)))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Print__printBufNewLine)
{
  if (PrintImpl__printBufNewLine(NULL))
    RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Print__hasBufNewLineAtEnd)
{
  rmlA0 = PrintImpl__hasBufNewLineAtEnd(NULL) ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
