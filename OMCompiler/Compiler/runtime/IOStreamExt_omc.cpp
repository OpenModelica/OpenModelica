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
 *
 *  This file is the external C implementation of TOP/Compiler/IOStreamExt.mo
 *
 *  TODO! FIXME! implement stream buffers (unify with Print.mo,
 *               but more general, as we need several buffers),
 *               handle buffer files, etc.
 *
 */

#include "IOStreamExt.c"
#include "openmodelica.h"
#include "meta/meta_modelica.h"

extern "C" {

extern int IOStreamExt_createFile(const char* filename)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern void IOStreamExt_closeFile(int id)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern void IOStreamExt_deleteFile(int id)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern void IOStreamExt_clearFile(int id)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern void IOStreamExt_printFile(int id, int whereToPrint)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern const char* IOStreamExt_readFile(int id)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern void IOStreamExt_appendFile(int id, const char* str)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern int IOStreamExt_createBuffer()
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern void IOStreamExt_deleteBuffer(int id)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern void IOStreamExt_clearBuffer(int id)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern const char* IOStreamExt_readBuffer(int id)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern void IOStreamExt_appendBuffer(int id, const char* str)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern void IOStreamExt_printBuffer(int id, int whereToPrint)
{
  fprintf(stderr, "NYI: %s:%d\n", __FILE__, __LINE__);
  MMC_THROW();
}

extern const char* IOStreamExt_appendReversedList(modelica_metatype lst)
{
  int lstLen, i, acc, len;
  char *res, *tmp, *res_head;
  modelica_metatype car, lstHead;
  lstLen = listLength(lst);
  acc = 0;
  lstHead = lst;
  // fprintf(stderr, "****** IOStreamExt_appendReversedList:");printAny(lst);fprintf(stderr, " to ");

  for (i=0; i<lstLen /* MMC_NILTEST not required */ ; i++, lst = MMC_CDR(lst)) {
    tmp = MMC_STRINGDATA(MMC_CAR(lst));
    acc += strlen(tmp);
  }
  res = (char*) omc_alloc_interface.malloc(acc+1);
  res_head = res;
  res += acc;
  res[0] = '\0';
  lst = lstHead;
  for (i=0; i<lstLen /* MMC_NILTEST not required */ ; i++, lst = MMC_CDR(lst)) {
    car = MMC_CAR(lst);
    tmp = MMC_STRINGDATA(car);
    len = strlen(tmp);
    res -= len;
    memcpy(res,tmp,len);
  }
  // fprintf(stderr, "'%s' ****\n", res_head);
  return res_head;
}

extern void IOStreamExt_printReversedList(modelica_metatype lst, int whereToPrint)
{
  int lstLen, i;
  const char** strs;
  FILE* f;
  lstLen = listLength(lst);
  switch (whereToPrint) {
  case 1: f = stdout; break;
  case 2: f = stderr; break;
  default: MMC_THROW();
  }
  strs = (const char**) omc_alloc_interface.malloc(sizeof(const char*)*lstLen);

  for (i=0; i<lstLen ; i++, lst = MMC_CDR(lst)) {
    strs[i] = MMC_STRINGDATA(MMC_CAR(lst));
  }
  for (i=0; i<lstLen ; i++) {
    fprintf(f, "%s", strs[lstLen-1-i]);
  }
  fflush(f);
  GC_free(strs);
}

}
