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

#ifndef READ_WRITE_H_
#define READ_WRITE_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "openmodelica.h"


#if defined(__cplusplus)
extern "C" {
#endif


extern void init_type_description(type_description * desc);
extern void free_type_description(type_description * desc);

extern int read_modelica_real(type_description ** descptr, modelica_real * data);
extern int read_real_array(type_description ** descptr, real_array_t *arr);
extern void write_modelica_real(type_description *desc, const modelica_real *data);
extern void write_real_array(type_description *desc, const real_array_t *arr);

extern int read_modelica_integer(type_description **descptr, modelica_integer *data);
extern int read_integer_array(type_description ** descptr, integer_array_t *arr);
extern void write_modelica_integer(type_description *desc, const modelica_integer *data);
extern void write_integer_array(type_description *desc, const integer_array_t *arr);

extern int read_modelica_boolean(type_description **descptr, modelica_boolean *data);
extern int read_boolean_array(type_description ** descptr, boolean_array_t *arr);
extern void write_modelica_boolean(type_description *desc, const modelica_boolean *data);
extern void write_boolean_array(type_description *desc, const boolean_array_t *arr);

extern int read_modelica_string(type_description **descptr, modelica_string_t *str);
extern int read_string_array(type_description ** descptr, string_array_t *arr);
extern void write_modelica_string(type_description *desc, modelica_string *str);
extern void write_string_array(type_description *desc, const string_array_t *arr);

extern int read_modelica_complex(type_description **descptr, modelica_complex *data);
extern void write_modelica_complex(type_description *desc, const modelica_complex *data);

/* function pointer functions - added by stefan */
extern int read_modelica_fnptr(type_description **descptr, modelica_fnptr *fn);
extern void write_modelica_fnptr(type_description *desc, const modelica_fnptr *fn);

extern int read_modelica_metatype(type_description **descptr, modelica_metatype*ut);
extern void write_modelica_metatype(type_description *desc, const modelica_metatype*ut);

extern int read_modelica_record(type_description **descptr, ...);
extern void write_modelica_record(type_description *desc, void *rec_desc_void, ...);

extern void write_noretcall(type_description *desc);

extern type_description *add_modelica_record_member(type_description *desc,
                                             const char *name, size_t nlen);

extern type_description *add_tuple_member(type_description *desc);

extern char *my_strdup(const char *s);

extern int getMyBool(const type_description *desc);

extern void puttype(const type_description *desc);

#if defined(__cplusplus)
}
#endif

#endif
