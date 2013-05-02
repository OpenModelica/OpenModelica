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

#include "meta_modelica.h"
#include "dtoa.c"

#define to_char(n) ((n) + '0')

#define MAXEXPDIG 6

static int
exponent(char *p0, int expo)
{
  char *p, *t;
  char expbuf[MAXEXPDIG];

  p = p0;
  *p++ = 'e';
  if (expo < 0) {
    expo = -expo;
    *p++ = '-';
  }
  else
    *p++ = '+';
  t = expbuf + MAXEXPDIG;
  if (expo > 9) {
    do {
      *--t = to_char(expo % 10);
    } while ((expo /= 10) > 9);
    *--t = to_char(expo);
    for (; t < expbuf + MAXEXPDIG; *p++ = *t++)
      ;
  }
  else {
    /*
     * Exponents for decimal floating point conversions
     * (%[eEgG]) must be at least two characters long,
     * whereas exponents for hexadecimal conversions can
     * be only one character long.
     */
    *p++ = '0';
    *p++ = to_char(expo);
  }
  return (p - p0);
}

/*
 * Generate reals like %.16g but platform-independent
 * Does not check for inf/NaN in the default mode since realString
 * handles them in a more efficient manner (static data, no allocation)
 */
static void* dtostr(double d)
{
  const int prec = 16 /* 1 more than mathematically relevant */;
  int signflag,i,totalsz;
  int expt,expsz=0,ndig;
  char *cp,*cporig,*dtoaend;
  char expbuf[MAXEXPDIG];
  void *retval;
  char *res;
  const int debug = 0;
#ifdef REAL_STRING_TEST_MAIN
  if (isinf(d) && d < 0)
    return "-inf";
  else if (isinf(d))
    return "inf";
  else if (isnan(d))
    return "NaN";
#endif
  *expbuf = 0;
  cporig = dtoa(d,1,prec,&expt,&signflag,&dtoaend);
  cp = cporig;
  ndig = dtoaend - cp;
  /*
   * Allocate the string on GC'ed heap directly
   * We just need to calculate the exact length of the string first :)
   */
  if (expt == 0) {
    totalsz = signflag+2+ndig;
    if (debug) fprintf(stderr, "totalsz: #1\n");
  } else if (expt == ndig || (expt > 0 && expt < prec && expt > ndig)) {
    totalsz = signflag+expt+2;
    if (debug) fprintf(stderr, "totalsz: #2\n");
  } else if (expt > 0 && expt < prec && expt > ndig) {
    totalsz = signflag+expt+2;
    if (debug) fprintf(stderr, "totalsz: #2.5\n");
  } else if (expt > 0 && expt < prec) {
    totalsz = signflag+ndig+1;
    if (debug) fprintf(stderr, "totalsz: #3\n");
  } else if (expt <= 0 && ndig+expt > -prec) {
    totalsz = signflag-expt+ndig+2;
    if (debug) fprintf(stderr, "totalsz: #4\n");
  } else {
    totalsz = signflag;
    if (expt && ndig == 1) totalsz += ndig;
    else if (expt == 1 || ndig == 1) totalsz += ndig+2;
    else totalsz += ndig+1;
    if (expt!=1) {
      /* Yup, this is then used later ;) */
      expsz = exponent(expbuf,expt == 0 ? expt : expt - 1);
      totalsz += expsz;
    }
    if (debug) fprintf(stderr, "totalsz: #5: %d %d %d %d\n", expt, ndig, expsz, totalsz);
  }
  retval = mmc_mk_scon_len(totalsz);
  res = MMC_STRINGDATA(retval);
  *res = '\0';

  if (signflag) *res++ = '-';
  if (expt == 0) {
    *res++ = '0';
    *res++ = '.';
    strcpy(res,cp);
    res += ndig;
  } else if (expt == ndig) {
    strcpy(res,cp);
    res += ndig;
    *res++ = '.';
    *res++ = '0';
  } else if (expt > 0 && expt < prec && expt > ndig) {
    strcpy(res,cp);
    res += ndig;
    for (i=ndig;i<expt;i++) {
      *res++ = '0';
    }
    *res++ = '.';
    *res++ = '0';
  } else if (expt > 0 && expt < prec) {
    for (i=0;i<expt;i++) {
      *res++ = *cp++;
    }
    *res++ = '.';
    strcpy(res,cp);
    res += ndig-expt;
  } else if (expt <= 0 && ndig+expt > -prec) {
    *res++ = '0';
    *res++ = '.';
    for (i=0;i<-expt;i++)
      *res++ = '0';
    strcpy(res,cp);
    res += ndig;
  } else {
    if (expt == 0) {
      *res++ = '0';
      *res++ = '.';
    } else {
      *res++ = *cp++;
      if (expt && ndig > 1) *res++ = '.';
      if (expt == 1 && ndig == 1) {
        *res++ = '.';
        *res++ = '0';
      }
    }
    strcpy(res,cp);
    res += ndig-1;
    if (expt) {
      strncpy(res,expbuf,expsz);
      res += expsz;
    }
  }
  *res = 0;
  freedtoa(cporig);
  if(debug) fprintf(stderr, "%.15g => %s\n", d, MMC_STRINGDATA(retval));
  if(debug) fprintf(stderr, "%lu => %lu\n", (unsigned long)strlen(MMC_STRINGDATA(retval)), (unsigned long)MMC_STRLEN(retval));
  MMC_CHECK_STRING(retval);
  return retval;
}

#undef MAXEXPDIG

static const MMC_DEFSTRINGLIT(_OMC_LIT_NEG_INF,4,"-inf");
static const MMC_DEFSTRINGLIT(_OMC_LIT_POS_INF,3,"inf");
static const MMC_DEFSTRINGLIT(_OMC_LIT_NAN,3,"NaN");

#if defined(_MSC_VER)
#include <float.h>
#define isnan _isnan
#define isinf !_finite
#endif

modelica_string _old_realString(modelica_real r)
{
  /* NOTE: The RML runtime uses the same code as this function.
   * If you update one, you must update the other or the testsuite might break
   *
   * 64-bit (1+11+52) double: -d.[15 digits]E-[4 digits] = ~24 digits max.
   * Add safety margin in case some C runtime is trigger happy. */
  static char buffer[32];
  modelica_string res;
  /* fprintf(stderr, "\nrealString(%g)\n", r);*/
  if (isinf(r) && r < 0)
    res = MMC_REFSTRINGLIT(_OMC_LIT_NEG_INF);
  else if (isinf(r))
    res = MMC_REFSTRINGLIT(_OMC_LIT_POS_INF);
  else if (isnan(r))
    res = MMC_REFSTRINGLIT(_OMC_LIT_NAN);
  else {
    char* endptr;
    int ix = snprintf(buffer, 32, "%.15g", r);
    long ignore;
    if (ix < 0)
      MMC_THROW();
    errno = 0;
    /* If it looks like an integer, we need to append .0 so it looks like real */
    ignore = strtol(buffer,&endptr,10);
    if (errno == 0 && *endptr == '\0') {
      if (ix > 30)
        MMC_THROW();
      buffer[ix++] = '.';
      buffer[ix++] = '0';
      buffer[ix] = '\0';
    }
    res = mmc_mk_scon(buffer);
  }
  return res;
}

modelica_string realString(modelica_real r)
{
  if (isinf(r) && r < 0)
    return MMC_REFSTRINGLIT(_OMC_LIT_NEG_INF);
  else if (isinf(r))
    return MMC_REFSTRINGLIT(_OMC_LIT_POS_INF);
  else if (isnan(r))
    return MMC_REFSTRINGLIT(_OMC_LIT_NAN);
#if defined(_MSC_VER)
  return _old_realString(r);
#else /* Linux and MinGW seems to know how to handle this */
  return dtostr(r);
#endif
}


#ifdef REAL_STRING_TEST_MAIN
#define c 15
int main()
{
  int i,j;
  double dds[c] = {-1.765,1.765,0,1,4,15e13,1.676e14,-15e-1,0.005,-0.03e13,1234567890,-1234567890,9.999999999999999e22,INFINITY,NAN};
  const char *res[c] = {
    "-1.765","1.765","0.0","1.0","4.0","150000000000000.0","167600000000000.0","-1.5","0.005","-300000000000.0","1234567890.0","-1234567890.0","9.999999999999999e+22","inf","NaN",
  };
  for (i=0;i<c;i++) {
    for (j=0;j<1;j++) {
    char *buf;
    buf = dtostr(dds[i]);
    fprintf(stderr, "%s%.15g to %s\n", strcmp(res[i],buf)==0 ? "" : "ERRROR: ",dds[i], buf);
    }
  }
}
#endif
