/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

/* Creates an implementation only if #define GEN_META_MODELICA_BUILTIN_BOXPTR is given.
 * Else, we only create a header.
 */
#include "utility.h"
#include "meta_modelica_real.h"
#include "modelica_string.h"

#if !defined(META_MODELICA_BUILTIN_BOXPTR__H) || defined(GEN_META_MODELICA_BUILTIN_BOXPTR)
#define META_MODELICA_BUILTIN_BOXPTR__H

#ifdef GEN_META_MODELICA_BUILTIN_BOXPTR
#define boxptr_unOp(name,box,unbox,op) void* name(void* a) {return (void*)box(op(unbox(a)));}
#define boxptr_binOp(name,box,unbox,op) void* name(void* a, void* b) {return (void*)box((unbox(a)) op (unbox(b)));}
#define boxptr_binFn(name,box,unbox,fn) void* name(void* a, void* b) {return (void*)box(fn((unbox(a)),(unbox(b))));}
#else
#define boxptr_unOp(name,box,unbox,op) void* name(void*);
#define boxptr_binOp(name,box,unbox,op) void* name(void*,void*);
#define boxptr_binFn(name,box,unbox,op) void* name(void*,void*);
#endif

/* Missing stuff: realMod,realPow,realMax,realMin,intMod,intMax,intMin */

boxptr_unOp(boxptr_boolNot,mmc_mk_bcon,mmc_unbox_boolean,!)
boxptr_binOp(boxptr_boolAnd,mmc_mk_bcon,mmc_unbox_boolean,&&)
boxptr_binOp(boxptr_boolOr,mmc_mk_bcon,mmc_unbox_boolean,||)
boxptr_binOp(boxptr_boolEq,mmc_mk_bcon,mmc_unbox_boolean,==)
boxptr_binOp(boxptr_intAdd,mmc_mk_icon,mmc_unbox_integer,+)
boxptr_binOp(boxptr_intSub,mmc_mk_icon,mmc_unbox_integer,-)
boxptr_binOp(boxptr_intMul,mmc_mk_icon,mmc_unbox_integer,*)
boxptr_binOp(boxptr_intDiv,mmc_mk_icon,mmc_unbox_integer,/)
boxptr_binFn(boxptr_intMod,mmc_mk_icon,mmc_unbox_integer,modelica_mod_integer)
boxptr_unOp(boxptr_intAbs,mmc_mk_icon,mmc_unbox_integer,labs)
boxptr_unOp(boxptr_intNeg,mmc_mk_icon,mmc_unbox_integer,-)
boxptr_binOp(boxptr_intLt,mmc_mk_bcon,mmc_unbox_integer,<)
boxptr_binOp(boxptr_intLe,mmc_mk_bcon,mmc_unbox_integer,<=)
boxptr_binOp(boxptr_intEq,mmc_mk_bcon,mmc_unbox_integer,==)
boxptr_binOp(boxptr_intNe,mmc_mk_bcon,mmc_unbox_integer,!=)
boxptr_binOp(boxptr_intGe,mmc_mk_bcon,mmc_unbox_integer,>=)
boxptr_binOp(boxptr_intGt,mmc_mk_bcon,mmc_unbox_integer,>)
boxptr_unOp(boxptr_intReal,mmc_mk_rcon,mmc_unbox_integer,(modelica_real))
boxptr_unOp(boxptr_intString,(void*),mmc_unbox_integer,intString)

boxptr_binOp(boxptr_realAdd,mmc_mk_rcon,mmc_unbox_real,+)
boxptr_binOp(boxptr_realSub,mmc_mk_rcon,mmc_unbox_real,-)
boxptr_binOp(boxptr_realMul,mmc_mk_rcon,mmc_unbox_real,*)
boxptr_binOp(boxptr_realDiv,mmc_mk_rcon,mmc_unbox_real,/)
boxptr_binFn(boxptr_realMod,mmc_mk_rcon,mmc_unbox_real,modelica_mod_real)
boxptr_binFn(boxptr_realPow,mmc_mk_rcon,mmc_unbox_real,pow)
boxptr_unOp(boxptr_realAbs,mmc_mk_rcon,mmc_unbox_real,fabs)
boxptr_unOp(boxptr_realNeg,mmc_mk_rcon,mmc_unbox_real,-)
boxptr_binOp(boxptr_realLt,mmc_mk_bcon,mmc_unbox_real,<)
boxptr_binOp(boxptr_realLe,mmc_mk_bcon,mmc_unbox_real,<=)
boxptr_binOp(boxptr_realEq,mmc_mk_bcon,mmc_unbox_real,==)
boxptr_binOp(boxptr_realNe,mmc_mk_bcon,mmc_unbox_real,!=)
boxptr_binOp(boxptr_realGe,mmc_mk_bcon,mmc_unbox_real,>=)
boxptr_binOp(boxptr_realGt,mmc_mk_bcon,mmc_unbox_real,>)
boxptr_unOp(boxptr_realInt,mmc_mk_icon,mmc_unbox_real,(modelica_integer))
boxptr_unOp(boxptr_realString,(void*),mmc_unbox_real,realString)

boxptr_unOp(boxptr_stringInt,mmc_mk_icon,(void*),stringInt)
boxptr_unOp(boxptr_stringCharInt,mmc_mk_icon,(void*),stringCharInt)
boxptr_unOp(boxptr_intStringChar,(void*),mmc_unbox_integer,intStringChar)
boxptr_binFn(boxptr_stringCompare,mmc_mk_icon,(void*),mmc_stringCompare)

boxptr_binFn(boxptr_valueEq,mmc_mk_bcon,(void*),valueEq)

boxptr_unOp(boxptr_listLength,mmc_mk_icon,(void*),listLength)

#undef boxptr_unOp
#undef boxptr_binOp
#undef boxptr_binFn

#endif
