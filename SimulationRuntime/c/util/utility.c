/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */


#include "utility.h"
#include "modelica_string.h"
#include "simulation_data.h"
#include "simulation/options.h"
#include <string.h>

modelica_real real_int_pow(threadData_t *threadData, modelica_real base, modelica_integer n)
{
  modelica_real result = 1.0;
  modelica_integer m = n < 0;
  FILE_INFO info = omc_dummyFileInfo;
  if(m)
  {
    if(base == 0.0)
      omc_assert(threadData, info, "Model error. 0^(%i) is not defined", n);
    n = -n;
  }
  while(n != 0)
  {
    if((n % 2) != 0)
    {
      result *= base;
      n--;
    }
    base *= base;
    n /= 2;
  }
  return m ? (1 / result) : result;
}

#if !defined(OMC_MINIMAL_RUNTIME)

#include <regex.h>
#include "meta/meta_modelica.h"

extern int OpenModelica_regexImpl(const char* str, const char* re, const int maxn, int extended, int ignoreCase, void*(*mystrdup)(const char*), void **outMatches)
{
  regex_t myregex;
  int nmatch=0,i,rc,res;
  int flags = (extended ? REG_EXTENDED : 0) | (ignoreCase ? REG_ICASE : 0) | (maxn ? 0 : REG_NOSUB);
#if !defined(_MSC_VER)
  regmatch_t matches[maxn < 1 ? 1 : maxn];
#else
  /* Stupid compiler */
  regmatch_t *matches;
  matches = (regmatch_t*)malloc(maxn*sizeof(regmatch_t));
  assert(matches != NULL);
#endif
  memset(&myregex, 1, sizeof(regex_t));
  rc = regcomp(&myregex, re, flags);
  if (rc && maxn == 0) {
#if defined(_MSC_VER)
    free(matches);
#endif
    return 0;
  }
  if (rc) {
    char err_buf[2048] = {0};
    int len = 0;
    len += snprintf(err_buf+len,2040-len,"Failed to compile regular expression: %s with error: ", re);
    regerror(rc, &myregex, err_buf+len, 2048-len);
    regfree(&myregex);
    if (maxn) {
      outMatches[0] = mystrdup(err_buf);
      for (i=1; i<maxn; i++)
        outMatches[i] = mystrdup("");
    }
#if defined(_MSC_VER)
    free(matches);
#endif
    return 0;
  }
  res = regexec(&myregex, str, maxn, matches, 0);
  if (!maxn)
    nmatch += res == 0 ? 1 : 0;
  else if (maxn) {
    char *dup = strdup(str);
    for (i=0; i<maxn; i++) {
      if (!res && matches[i].rm_so != -1) {
        memcpy(dup, str + matches[i].rm_so, matches[i].rm_eo - matches[i].rm_so);
        dup[matches[i].rm_eo - matches[i].rm_so] = '\0';
        outMatches[nmatch++] = mystrdup(dup);
      }
    }
    for (i=nmatch; i<maxn; i++) {
      outMatches[i] = mystrdup("");
    }
    free(dup);
  }

  regfree(&myregex);
#if defined(_MSC_VER)
  free(matches);
#endif
  return nmatch;
}

extern int OpenModelica_regex(const char* str, const char* re, int maxn, int extended, int sensitive, const char **outMatches)
{
  return OpenModelica_regexImpl(str,re,maxn,extended,sensitive,(void*(*)(const char*)) mmc_mk_scon,(void**)outMatches);
}

#endif /* OMC_MINIMAL_RUNTIME */
