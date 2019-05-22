/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2018, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef _LLVM_GEN_WRAPPERS_H
#define _LLVM_GEN_WRAPPERS_H

/*Things depending on the bootstrapping header. Order is important*/
#include "ModelicaUtilities.h"
#include "openmodelica.h"
#include "meta_modelica.h"
#define ADD_METARECORD_DEFINITIONS static
#define UNBOX_OFFSET 1
#include "OpenModelicaBootstrappingHeader.h"

#include "errorext.h"
#include "integer_array_jit.h"
#include "llvm_gen_modelica_constants.h"
#include "meta_modelica_builtin.h"
#include "real_array_jit.h"
#include "systemimpl.h"
#include "util/read_write.h"
#include "util/modelica_string_lit.h"
#include "util/boolean_array.h"
#include "util/string_array.h"

#ifdef __cplusplus
extern "C" {
#endif

#if !defined(OMC_GENERATE_RELOCATABLE_CODE)
extern void* omc_AbsynUtil_pathString(threadData_t*,void*,void*,int,int);
#else
extern void* (*omc_AbsynUtil_pathString)(threadData_t*,void*,void*,int,int);
#endif

modelica_metatype mmc_icon_to_value_wrapper(modelica_metatype mmc);
modelica_metatype mmc_rcon_to_value_wrapper(modelica_metatype mmc);
modelica_metatype mmc_bcon_to_value_wrapper(modelica_metatype mmc);
modelica_metatype mmc_scon_to_value_wrapper(modelica_metatype mmc);
modelica_metatype mmc_mk_cons_last_elem(modelica_metatype car);
modelica_metatype mmc_mk_cons_wrapper(modelica_metatype car, modelica_metatype cdr);
modelica_metatype mmc_lcon_to_value(modelica_metatype varLst);
modelica_metatype mmc_mtcon_to_value(modelica_metatype varlst);
modelica_metatype mmc_tcon_to_value(modelica_metatype vl);
modelica_metatype mmc_mk_icon_wrapper(const modelica_integer i);
modelica_metatype mmc_mk_bcon_wrapper(const modelica_boolean b);
modelica_metatype mmc_lcon_to_value_wrapper(modelica_metatype varLst);
modelica_metatype mmc_mk_icon_wrapper(const modelica_integer i);
modelica_metatype mmc_mk_bcon_wrapper(const modelica_boolean b);
modelica_metatype mmc_mk_scon_wrapper(const char *s);
modelica_metatype mmc_mk_box_no_inline(mmc_sint_t _slots, mmc_uint_t ctor, ...);
static modelica_metatype mmc_to_value(modelica_metatype mmc);
static modelica_metatype name_to_path(const char *name);
static char* path_to_name(void* path, char del);
static int get_array_type_and_dims(type_description *desc, modelica_metatype arrdata);
static int get_array_data(int curdim, int dims, const _index_t *dim_size,
						  modelica_metatype arrdata, enum type_desc_e type, modelica_metatype *data);
static int get_array_sizes(int dims, _index_t *dim_size, modelica_metatype dimLst);
static int value_to_type_desc(modelica_metatype value, type_description *desc);
static modelica_metatype generate_array(enum type_desc_e type, int curdim, int ndims,
							_index_t *dim_size, modelica_metatype *data);
static modelica_metatype type_desc_to_value(type_description *desc);
modelica_integer mmc_unbox_integer_no_inline(modelica_metatype v);
double mmc_unbox_Real_no_inline(modelica_metatype v);
#ifdef __cplusplus
}
#endif

#endif
