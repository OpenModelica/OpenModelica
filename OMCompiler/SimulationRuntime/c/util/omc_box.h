/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */


#ifndef OMC_BOX_H_
#define OMC_BOX_H_

#include "../openmodelica_types.h"
#include "../gc/omc_rc.h"
/* meta/meta_modelica.h defines the same box vocabulary for MetaModelica. */
#if !defined(OMC_METAMODELICA_RUNTIME)

#if defined(__cplusplus)
extern "C" {
#endif

/* A counted box, for the boxed (boxptr_*) wrappers and the modelica://
 * resource table:
 *
 *     [ rc : mmc_uint_t ][ w0 : ctor ][ w1 .. wN : fields ]
 *
 * The pointer is the w0 word, so field i is word i as MMC_OFFSET numbers them,
 * and OMC_BOX_FIELD reads the same index in either runtime. */
#define OMC_BOX_FIELD(X, I) (((void**)(X))[I])

/* A counted box has no slot count in its header, so an array box that is
   walked at run time carries it above the tag. */
#define OMC_ARRAY_TAG 255
#define OMC_BOX_ARRAY_TAG(N) ((mmc_uint_t)(((mmc_uint_t)(N)) << 8 | OMC_ARRAY_TAG))
#define OMC_BOX_ARRAY_LEN(X) (((mmc_uint_t*)(X))[0] >> 8)

/* A static, immortal box. Written as OMC_DEFBOXLIT(name, nfields, ctor)
   {f1, f2}}; -- the same shape as MMC_DEFSTRUCTLIT. */
#define OMC_DEFBOXLIT(NAME, LEN, CON) \
  struct { \
    mmc_uint_t rc; \
    mmc_uint_t ctor; \
    const void *data[LEN]; \
  } NAME = { OMC_RC_IMMORTAL, (CON),
#define OMC_REFBOXLIT(NAME) ((void*) &((NAME).ctor))

/* A boxed Real literal. The value sits where omc_unbox_real expects it. */
#define OMC_DEFREALLIT(NAME, VAL) \
  struct { \
    mmc_uint_t rc; \
    modelica_real v; \
  } NAME = { OMC_RC_IMMORTAL, (VAL) }
#define OMC_REFREALLIT(NAME) ((void*) &((NAME).v))

void* omc_box_new_n(int nfields, int ctor, ...);

/* What a partial application evaluates to, laid out like a box of two fields.
   Modelica only passes a function value down into a call, so it and its
   environment are locals of the frame that makes them. */
typedef struct {
  mmc_uint_t ctor;
  void *fn;
  void *env;
} omc_closure;

/* A boxed scalar for the boxptr_* wrappers: a counted cell, never an immediate,
   so the count is always where omc_rc expects it. */
void* omc_mk_rcon(modelica_real r);
void* omc_mk_icon(modelica_integer i);
#define omc_mk_bcon(b)            omc_mk_icon(b)
#define omc_mk_real(r)            omc_mk_rcon(r)
#define omc_mk_integer(i)         omc_mk_icon(i)
#define omc_mk_boolean(b)         omc_mk_icon(b)
#define omc_mk_enumeration(e)     omc_mk_icon(e)
#define omc_mk_string(s)          ((void*)(s))
#define omc_mk_modelica_array(a)  omc_box_array(&(a))
void* omc_box_array(void *arr);

#define omc_unbox_real(x)     (*(modelica_real*)(x))
#define omc_unbox_integer(x)  (*(modelica_integer*)(x))
#define omc_unbox_boolean(x)  ((modelica_boolean) omc_unbox_integer(x))
#define omc_unbox_string(x)   ((modelica_string)(x))
#define omc_unbox_array(x)    (*(base_array_t*)(x))

#define omc_mk_box(N, CTOR, ...)  omc_box_new_n((N), (CTOR), __VA_ARGS__)
#define omc_mk_box0(CTOR)              omc_box_new_n(0, (CTOR))
#define omc_mk_box1(CTOR,...)          omc_box_new_n(1, (CTOR), __VA_ARGS__)
#define omc_mk_box2(CTOR,...)          omc_box_new_n(2, (CTOR), __VA_ARGS__)
#define omc_mk_box3(CTOR,...)          omc_box_new_n(3, (CTOR), __VA_ARGS__)
#define omc_mk_box4(CTOR,...)          omc_box_new_n(4, (CTOR), __VA_ARGS__)
#define omc_mk_box5(CTOR,...)          omc_box_new_n(5, (CTOR), __VA_ARGS__)
#define omc_mk_box6(CTOR,...)          omc_box_new_n(6, (CTOR), __VA_ARGS__)
#define omc_mk_box7(CTOR,...)          omc_box_new_n(7, (CTOR), __VA_ARGS__)
#define omc_mk_box8(CTOR,...)          omc_box_new_n(8, (CTOR), __VA_ARGS__)
#define omc_mk_box9(CTOR,...)          omc_box_new_n(9, (CTOR), __VA_ARGS__)
#define omc_mk_box10(CTOR,...)         omc_box_new_n(10, (CTOR), __VA_ARGS__)
#define omc_mk_box11(CTOR,...)         omc_box_new_n(11, (CTOR), __VA_ARGS__)
#define omc_mk_box12(CTOR,...)         omc_box_new_n(12, (CTOR), __VA_ARGS__)
#define omc_mk_box13(CTOR,...)         omc_box_new_n(13, (CTOR), __VA_ARGS__)
#define omc_mk_box14(CTOR,...)         omc_box_new_n(14, (CTOR), __VA_ARGS__)
#define omc_mk_box15(CTOR,...)         omc_box_new_n(15, (CTOR), __VA_ARGS__)
#define omc_mk_box16(CTOR,...)         omc_box_new_n(16, (CTOR), __VA_ARGS__)
#define omc_mk_box17(CTOR,...)         omc_box_new_n(17, (CTOR), __VA_ARGS__)
#define omc_mk_box18(CTOR,...)         omc_box_new_n(18, (CTOR), __VA_ARGS__)
#define omc_mk_box19(CTOR,...)         omc_box_new_n(19, (CTOR), __VA_ARGS__)
#define omc_mk_box20(CTOR,...)         omc_box_new_n(20, (CTOR), __VA_ARGS__)

#if defined(__cplusplus)
} /* end extern "C" */
#endif

#endif /* !OMC_METAMODELICA_RUNTIME */
#endif /* OMC_BOX_H_ */
