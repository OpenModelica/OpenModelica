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

/*! \file openmodelica.h
 * Description: This is the C header file for the C code generated from
 * Modelica. It includes e.g. the C object representation of the builtin types
 * and arrays, etc.
 */

#ifndef OPENMODELICA_H_
#define OPENMODELICA_H_

#if defined(__cplusplus)
extern "C" {
#endif

#include "omc_simulation_settings.h"

#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <assert.h>
#include <float.h>

/* adrpo: extreme windows crap! */
#if defined(__MINGW32__) || defined(_MSC_VER)
#define DLLImport   __declspec( dllimport )
#define DLLExport   __declspec( dllexport )
#else
#define DLLImport /* extern */
#define DLLExport /* nothing */
#endif

#if defined(IMPORT_INTO)
#define DLLDirection DLLImport
#else /* we export from the dll */
#define DLLDirection DLLExport
#endif

#if __STDC_VERSION__ >= 199901L || __cplusplus >= 201103L
#define HAVE_VA_MACROS 1
#endif

#include "openmodelica_types.h"
#if defined(__MINGW32__) || defined(_MSC_VER)
#if !defined(WIN32_LEAN_AND_MEAN)
 #define WIN32_LEAN_AND_MEAN
#endif
#if !defined(NOMINMAX)
 #define NOMINMAX
#endif
#endif

/* BEFORE: compat.h */
#if defined(__MINGW32__) || defined(_MSC_VER) || defined(__AVR__)
#define EXIT(code) exit(code)
#else
/* We need to patch exit() on Unix systems
 * It does not change the exit code of simulations for some reason! */
#include <unistd.h>
#define EXIT(code) {fflush(NULL); _exit(code);}
#endif

#include "omc_inline.h"

/* BEFORE: fortran_types */
#if defined(__alpha__) || defined(__sparc64__) || defined(__x86_64__) || defined(__ia64__)
typedef int fortran_integer;
typedef unsigned int fortran_uinteger;
#else
typedef long int fortran_integer;
typedef unsigned long int fortran_uinteger;
#endif


/* BEFORE: read_write */
typedef struct type_desc_s type_description;

enum type_desc_e {
  TYPE_DESC_NONE,
  TYPE_DESC_REAL,
  TYPE_DESC_REAL_ARRAY,
  TYPE_DESC_INT,
  TYPE_DESC_INT_ARRAY,
  TYPE_DESC_BOOL,
  TYPE_DESC_BOOL_ARRAY,
  TYPE_DESC_STRING,
  TYPE_DESC_STRING_ARRAY,
  TYPE_DESC_TUPLE,
  TYPE_DESC_COMPLEX,
  TYPE_DESC_RECORD,
  /* function pointer - added by stefan */
  TYPE_DESC_FUNCTION,
  TYPE_DESC_MMC,
  TYPE_DESC_NORETCALL
};

struct type_desc_s {
  enum type_desc_e type;
  int retval : 1;
  union _data {
    modelica_real real;
    real_array r_array;
    modelica_integer integer;
    integer_array int_array;
    modelica_boolean boolean;
    boolean_array bool_array;
    modelica_string string;
    string_array string_array;
    struct _tuple {
      size_t elements;
      struct type_desc_s *element;
    } tuple;
    modelica_complex om_complex;
    struct _record {
      const char *record_name;
      size_t elements;
      char **name;
      struct type_desc_s *element;
    } record;
    /* function pointer - stefan */
    modelica_fnptr function;
    void* mmc;
  } data;
};

/* math functions (-lm)*/

/* Special Modelica builtin functions*/
#define smooth(P,EXP)    (EXP)
static inline modelica_real semiLinear(const modelica_real x,const modelica_real positiveSlope, const modelica_real negativeSlope){return x*((x>=0)? positiveSlope : negativeSlope);}
/* sign function */
static inline int sign(double v)
{
  return v > 0 ? 1 : v < 0 ? -1 : 0;
}

#include "util/omc_msvc.h"

/* initial and terminal function calls */
#define initial() data->simulationInfo->initial
#define terminal() data->simulationInfo->terminal

#define homotopy(actual, simplified) ((simplified) * (1.0-data->simulationInfo->lambda) + (actual) * data->simulationInfo->lambda)
#define homotopyParameter() data->simulationInfo->lambda

#include "gc/omc_gc.h"

/* g++ does not allow putting attributes next to labels
 * clang++ does allow it however...
 */
#if defined(__cplusplus) && defined(__GNUC__)
#define OMC_LABEL_UNUSED
#else
#define OMC_LABEL_UNUSED __attribute__((unused))
#endif

#if !defined(OMC_DISABLE_OPT)
#if defined(__clang__)
#define OMC_DISABLE_OPT __attribute__((optnone))
#elif defined(__GNUC__)
#define OMC_DISABLE_OPT __attribute__((optimize(0)))
#elif defined(_MSC_VER)
#define OMC_DISABLE_OPT /* nothing */
#endif
#endif

#if defined(__cplusplus)
} /* end extern "C" */
#endif

#endif
