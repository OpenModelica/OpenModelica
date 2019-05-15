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

#ifndef OMSU_INPUT_XML_H
#define OMSU_INPUT_XML_H


#include <expat.h>          /* use expat XML parser */
#include <uthash.h>         /* use uthash as hash table for C*/

#include <stdio.h>
#include <float.h>

#include <omsi.h>
#include <omsi_callbacks.h>

#include <omsi_utils.h>

/* typedefs for structures */
typedef struct hash_string_string {
  omsi_string id;       /* key */
  omsi_string val;      /* value */
  UT_hash_handle hh;    /* makes this structure hashable */
} hash_string_string;

typedef hash_string_string omc_ModelDescription;
typedef hash_string_string omc_DefaultExperiment;
typedef hash_string_string omc_ScalarVariable;

typedef struct hash_long_var {
  omsi_long id;             /* key */
  omc_ScalarVariable *val;  /* value */
  UT_hash_handle hh;        /* makes this structure hashable */
} hash_long_var;

typedef hash_long_var omc_ModelVariables;

typedef struct hash_string_long {
  omsi_string id;           /* key */
  omsi_long val;            /* value */
  UT_hash_handle hh;        /* makes this structure hashable */
} hash_string_long;

/* structure used to collect data from the xml input file */
typedef struct omc_ModelInput {
  omc_ModelDescription  *md; /* model description */
  omc_DefaultExperiment *de; /* default experiment */

  omc_ModelVariables    *rSta; /* states */
  omc_ModelVariables    *rDer; /* derivatives */
  omc_ModelVariables    *rAlg; /* algebraic */
  omc_ModelVariables    *rPar; /* parameters */
  omc_ModelVariables    *rAli; /* aliases */
  omc_ModelVariables    *rSen; /* sensitivities */

  omc_ModelVariables    *iAlg; /* int algebraic */
  omc_ModelVariables    *iPar; /* int parameters */
  omc_ModelVariables    *iAli; /* int aliases */

  omc_ModelVariables    *bAlg; /* bool algebraic */
  omc_ModelVariables    *bPar; /* bool parameters */
  omc_ModelVariables    *bAli; /* bool aliases */

  omc_ModelVariables    *sAlg; /* string algebraic */
  omc_ModelVariables    *sPar; /* string parameters */
  omc_ModelVariables    *sAli; /* string aliases */

  /* these two we need to know to be able to add
     the stuff in <Real ... />, <String ... /> to
     the correct variable in the correct map */
  omsi_long             lastCI; /* index */
  omc_ModelVariables**  lastCT; /* type (classification) */
} omc_ModelInput;


#ifdef __cplusplus
extern "C" {
#endif

/* public function prototypes */
omsi_status omsu_process_input_xml(omsi_t*                         osu_data,
                                   omsi_string                     filename,
                                   omsi_string                     fmuGUID,
                                   omsi_string                     instanceName,
                                   const omsi_callback_functions*  functions);



/*private function prototypes */
omsi_int omsu_find_alias_index(omsi_int alias_valueReference,
                               omsi_int n_variables);

void omsu_read_var_info (omc_ScalarVariable*    v,
                         model_variable_info_t* model_var_info,
                         omsi_data_type         type,
                         omsi_unsigned_int*     variable_index,
                         omsi_int               number_of_prev_variables);

void omsu_read_var_infos(model_data_t*      model_data,
                         omc_ModelInput*    mi);

omsi_string omsu_findHashStringStringNull(hash_string_string*   ht,
                                          omsi_string           key);

omsi_string omsu_findHashStringStringEmpty(hash_string_string*  ht,
                                           omsi_string          key);

omsi_string omsu_findHashStringString(hash_string_string*   ht,
                                      omsi_string           key);

void omsu_addHashLongVar(hash_long_var**        ht,
                         omsi_long              key,
                         omc_ScalarVariable*    val);

void omsu_addHashStringString(hash_string_string**  ht,
                              omsi_string           key,
                              omsi_string           val);

void omsu_read_value_int(omsi_string    s,
                         omsi_int*      res,
                         omsi_int       default_value);

void omsu_read_value_uint(omsi_string           s,
                          omsi_unsigned_int*    res);

omc_ScalarVariable** omsu_findHashLongVar(hash_long_var *ht,
                                          omsi_long     key);

void omsu_read_value_real(omsi_string   s,
                          omsi_real*    res,
                          omsi_real     default_value);

void omsu_read_value_bool(omsi_string   s,
                          omsi_bool*    res);

void omsu_read_value_bool_default (omsi_string  s,
                                   omsi_bool*   res,
                                   omsi_bool    default_bool);

void omsu_read_value_string(omsi_string s,
                            omsi_char** str);

void XMLCALL startElement(void*         userData,
                          omsi_string   name,
                          omsi_string*  attr);

void XMLCALL endElement(void*       userData,
                        omsi_string name);

void omsu_free_ModelInput(omc_ModelInput* mi);

void free_hash_string_string (hash_string_string* data);

void free_hash_long_var (hash_long_var* data);


#ifdef __cplusplus
}  /* end of extern "C" { */
#endif

#endif
