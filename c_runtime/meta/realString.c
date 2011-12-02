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

#include "dtoa.c"

#include "meta_modelica.h"

#define	to_char(n)	((n) + '0')

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
  ndig = ndig > prec ? prec : ndig;
  /*
   * Allocate the string on GC'ed heap directly
   * We just need to calculate the exact length of the string first :)
   */
  if (expt == ndig || (expt > 0 && expt < prec && expt > ndig)) {
    totalsz = signflag+expt+2;
  } else if (expt < 0 && expt > -prec && -expt > ndig) {
    totalsz = signflag+expt+ndig+2;
  } else {
    totalsz = signflag;
    if (expt < 0) {
      totalsz += 2;
    } else {
      if (ndig>1)
        totalsz += 1;
      if (expt == 0 && ndig == 1) {
        totalsz += 2;
      }
    }
    totalsz += ndig-1;
    if (expt!=1) {
      /* Yup, this is then used later ;) */
      expsz = exponent(expbuf,expt < 0 ? expt + 1 : expt - 1);
      totalsz += expsz;
    }
  }
  retval = mmc_mk_scon_len(totalsz);
  res = MMC_STRINGDATA(retval);
  *res = '\0';

  if (signflag) *res++ = '-';
  if (expt == ndig) {
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
  } else if (expt < 0 && expt > -prec && -expt > ndig) {
    *res++ = '0';
    *res++ = '.';
    for (i=0;i<-expt;i++)
      *res++ = '0';
    strcpy(res,cp);
    res += ndig;
  } else {
    if (expt <= 0) {
      *res++ = '0';
      *res++ = '.';
    } else {
      *res++ = *cp++;
      if (ndig>1)
        *res++ = '.';
      expt--;
      if (expt == 0 && ndig == 1) {
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
  MMC_CHECK_STRING(retval);
  return retval;
}

#undef MAXEXPDIG

static const MMC_DEFSTRINGLIT(_OMC_LIT_NEG_INF,4,"-inf");
static const MMC_DEFSTRINGLIT(_OMC_LIT_POS_INF,3,"inf");
static const MMC_DEFSTRINGLIT(_OMC_LIT_NAN,3,"NaN");

modelica_string realString(modelica_real r)
{
  if (isinf(r) && r < 0)
    return MMC_REFSTRINGLIT(_OMC_LIT_NEG_INF);
  else if (isinf(r))
    return MMC_REFSTRINGLIT(_OMC_LIT_POS_INF);
  else if (isnan(r))
    return MMC_REFSTRINGLIT(_OMC_LIT_NAN);
  return dtostr(r);
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
