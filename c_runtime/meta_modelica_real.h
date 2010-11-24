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

/* File: meta_modelica_real.h
 * Description: This is the C header file for the new builtin
 * functions existing in MetaModelica.
 */

#ifndef META_MODELICA_REAL_H_
#define META_MODELICA_REAL_H_

#include "modelica.h"

#if defined(__cplusplus)
extern "C" {
#endif

/* Real Operations */
typedef modelica_real realAdd_rettype;
typedef modelica_real realSub_rettype;
typedef modelica_real realMul_rettype;
typedef modelica_real realDiv_rettype;
typedef modelica_real realMod_rettype;
typedef modelica_real realPow_rettype;
typedef modelica_real realMax_rettype;
typedef modelica_real realMin_rettype;

realAdd_rettype realAdd(modelica_real,modelica_real);
realSub_rettype realSub(modelica_real,modelica_real);
realMul_rettype realMul(modelica_real,modelica_real);
realDiv_rettype realDiv(modelica_real,modelica_real);
realMod_rettype realMod(modelica_real,modelica_real);
realPow_rettype realPow(modelica_real,modelica_real);
realMax_rettype realMax(modelica_real,modelica_real);
realMin_rettype realMin(modelica_real,modelica_real);

modelica_metatype boxptr_realAdd(modelica_metatype,modelica_metatype);
modelica_metatype boxptr_realSub(modelica_metatype,modelica_metatype);
modelica_metatype boxptr_realMul(modelica_metatype,modelica_metatype);
modelica_metatype boxptr_realDiv(modelica_metatype,modelica_metatype);
modelica_metatype boxptr_realMod(modelica_metatype,modelica_metatype);
modelica_metatype boxptr_realPow(modelica_metatype,modelica_metatype);
modelica_metatype boxptr_realMax(modelica_metatype,modelica_metatype);
modelica_metatype boxptr_realMin(modelica_metatype,modelica_metatype);

typedef modelica_real realAbs_rettype;
typedef modelica_real realNeg_rettype;
typedef modelica_real realCos_rettype;
typedef modelica_real realCosh_rettype;
typedef modelica_real realAcos_rettype;
typedef modelica_real realSin_rettype;
typedef modelica_real realSinh_rettype;
typedef modelica_real realAsin_rettype;
typedef modelica_real realAtan_rettype;
typedef modelica_real realAtan2_rettype;
typedef modelica_real realTanh_rettype;
typedef modelica_real realExp_rettype;
typedef modelica_real realLn_rettype;
typedef modelica_real realLog10_rettype;
typedef modelica_real realCeil_rettype;
typedef modelica_real realFloor_rettype;
typedef modelica_real realSqrt_rettype;

#define realAbs(X) fabs(X)
#define realNeg(X) (-(X))
#define realCos(X) cos(X)
#define realCosh(X) cosh(X)
#define realAcos(X) acos(X)
#define realSin(X) sin(X)
#define realSinh(X) sinh(X)
#define realAsin(X) asin(X)
#define realAtan(X) atan(X)
#define realAtan2(X,Y) atan2(X,Y)
#define realTanh(X) tanh(X)
#define realExp(X) exp(X)
#define realLn(X) log(X)
#define realLog10(X) log10(X)
#define realCeil(X) ceil(X)
#define realFloor(X) floor(X)
#define realSqrt(X) sqrt(X)

modelica_metatype boxptr_realAbs(modelica_metatype);
modelica_metatype boxptr_realNeg(modelica_metatype);
modelica_metatype boxptr_realCos(modelica_metatype);
modelica_metatype boxptr_realSin(modelica_metatype);
modelica_metatype boxptr_realAtan(modelica_metatype);
modelica_metatype boxptr_realExp(modelica_metatype);
modelica_metatype boxptr_realLn(modelica_metatype);
modelica_metatype boxptr_realLog10(modelica_metatype);
modelica_metatype boxptr_realSqrt(modelica_metatype);

typedef modelica_boolean realLt_rettype;
typedef modelica_boolean realLe_rettype;
typedef modelica_boolean realEq_rettype;
typedef modelica_boolean realNe_rettype;
typedef modelica_boolean realGe_rettype;
typedef modelica_boolean realGt_rettype;

realLt_rettype realLt(modelica_real, modelica_real);
realLe_rettype realLe(modelica_real, modelica_real);
realEq_rettype realEq(modelica_real, modelica_real);
realNe_rettype realNe(modelica_real, modelica_real);
realGe_rettype realGe(modelica_real, modelica_real);
realGt_rettype realGt(modelica_real, modelica_real);

modelica_metatype boxptr_realLt(modelica_metatype,modelica_metatype);
modelica_metatype boxptr_realGt(modelica_metatype,modelica_metatype);

typedef modelica_integer realInt_rettype;
typedef modelica_string realString_rettype;

realInt_rettype realInt(modelica_real);
realString_rettype realString(modelica_real);

modelica_metatype boxptr_realString(modelica_metatype);

#if defined(__cplusplus)
}
#endif

#endif
