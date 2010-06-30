/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 *
 *  RCS: $Id: IOStreamExt.c 5482 2010-05-10 05:56:23Z adrpo $
 *
 *  This file is the external C implementation of TOP/Compiler/IOStreamExt.mo
 *
 *  TODO! FIXME! implement stream buffers (unify with Print.mo,
 *               but more general, as we need several buffers),
 *               handle buffer files, etc.
 *
 */

#include <stdio.h>
#include <string.h>
#include "rml.h"

void IOStreamExt_5finit(void)
{
   /* nothing to do for now */
}

RML_BEGIN_LABEL(IOStreamExt__createFile)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__closeFile)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__deleteFile)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__clearFile)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__printFile)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__readFile)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__appendFile)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__createBuffer)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__deleteBuffer)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__clearBuffer)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__readBuffer)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__appendBuffer)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__printBuffer)
{
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__appendReversedList)
{
  /* count the length of elements in the list */
  rml_uint_t len_car = 0;
  rml_uint_t len_cur = 0;
  rml_uint_t len = 0;
  struct rml_string *str = 0;
  void *lst = rmlA0;

  while( RML_GETHDR(lst) == RML_CONSHDR ) {
    len += RML_HDRSTRLEN(RML_GETHDR(RML_CAR(lst)));
    lst = RML_CDR(lst);
  }

  /* allocate the string */
  str = rml_prim_mkstring(len, 1);
  if (len == 0) /* if the list is empty, return empty string! */
  {
    str->data[0] = '\0';     /* set the end to 0 */
    rmlA0 = RML_TAGPTR(str); /* set the result to the tagged pointer */
    RML_TAILCALLK(rmlSC);    /* return from the function */
  }

  /* re-read the rmlA0 as it might have been moved by the GC */
  lst = rmlA0;
  len_cur = len;
  while( RML_GETHDR(lst) == RML_CONSHDR )
  {
    void* car = RML_CAR(lst);
    len_car = RML_HDRSTRLEN(RML_GETHDR(car));
    (void)memcpy(&str->data[len_cur-len_car], RML_STRINGDATA(car), len_car);
    len_cur -= len_car;
    lst = RML_CDR(lst);
  }
  str->data[len] = '\0';
  rmlA0 = RML_TAGPTR(str);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(IOStreamExt__printReversedList)
{
  /* count the length of elements in the list */
  rml_uint_t len_car = 0;
  rml_uint_t len_cur = 0;
  rml_uint_t len = 0;
  char *str = 0;
  void *lst = rmlA0; /* the list buffer, reversed */
  int whereToPrint = RML_UNTAGFIXNUM(rmlA1); /* where to print */

  while( RML_GETHDR(lst) == RML_CONSHDR ) {
    len += RML_HDRSTRLEN(RML_GETHDR(RML_CAR(lst)));
    lst = RML_CDR(lst);
  }

  if (len == 0) /* if the list is empty we have nothing to print */
  {
    RML_TAILCALLK(rmlSC);    /* return from the function */
  }

  /* allocate the string in the C heap */
  str = (char*)malloc(len+1);

  if (str == NULL) /* we couldn't allocate the string */
  {
    fprintf(stderr, "\nIOStreamExt.printReversedList failed! Error: Could not allocate string of length %d! Not enough memory.", len+1);
    fflush(stderr);
    RML_TAILCALLK(rmlFC);
  }

  len_cur = len;

  // re-initialize the lst
  lst = rmlA0; /* the list buffer, reversed */

  while( RML_GETHDR(lst) == RML_CONSHDR )
  {
    void* car = RML_CAR(lst);
    len_car = RML_HDRSTRLEN(RML_GETHDR(car));
    (void)memcpy(&str[len_cur - len_car], RML_STRINGDATA(car), len_car);
    len_cur = len_cur - len_car;
    lst = RML_CDR(lst);
  }
  str[len] = '\0';

  if (whereToPrint == 1) /* standard output */
  {
    fwrite(str, len, 1, stdout);
    fflush(stdout);
  }
  else if (whereToPrint == 2) /* standard error */
  {
    fwrite(str, len, 1, stderr);
    fflush(stderr);
  }
  /* free the memory */
  free(str);
  /* return from the function */
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

