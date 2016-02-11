/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
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
 * from Linkoping University, either from the above address,
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

#ifndef MODELICA_PARSER_COMMON_H
#define MODELICA_PARSER_COMMON_H

#ifdef __cplusplus
extern "C" {
#endif

#include "systemimpl.h"
#include <pthread.h>

#define UNBOX_OFFSET 1

DLLDirection extern pthread_key_t modelicaParserKey;

#define omc_first_comment ((parser_members*)pthread_getspecific(modelicaParserKey))->first_comment
#define ModelicaParser_filename_OMC ((parser_members*)pthread_getspecific(modelicaParserKey))->filename_OMC
#define ModelicaParser_timeStamp ((parser_members*)pthread_getspecific(modelicaParserKey))->timestamp
#define ModelicaParser_filename_C ((parser_members*)pthread_getspecific(modelicaParserKey))->filename_C
#define ModelicaParser_filename_C_testsuiteFriendly ((parser_members*)pthread_getspecific(modelicaParserKey))->filename_C_testsuiteFriendly
#define ModelicaParser_readonly ((parser_members*)pthread_getspecific(modelicaParserKey))->readonly
#define ModelicaParser_flags ((parser_members*)pthread_getspecific(modelicaParserKey))->flags
#define ModelicaParser_langStd ((parser_members*)pthread_getspecific(modelicaParserKey))->langStd
#define ModelicaParser_lexerError ((parser_members*)pthread_getspecific(modelicaParserKey))->lexerError
#define ModelicaParser_encoding ((parser_members*)pthread_getspecific(modelicaParserKey))->encoding
#define ModelicaParser_threadData ((parser_members*)pthread_getspecific(mmc_thread_data_key))

typedef struct antlr_members_struct {
  int lexerError;
  const char *encoding;
  long first_comment;
  void* filename_OMC;
  void* timestamp;
  const char* filename_C;
  const char* filename_C_testsuiteFriendly;
  int readonly;
  int flags;
  int langStd;
  threadData_t *threadData;
} parser_members;

#define PARSE_MODELICA        0
#define PARSE_FLAT            1<<0
#define PARSE_META_MODELICA   1<<1
#define PARSE_EXPRESSION      1<<2
#define PARSE_CODE_EXPRESSION 1<<3
#define PARSE_PARMODELICA     1<<4
#define PARSE_OPTIMICA        1<<5
#define PARSE_PATH            1<<6
#define PARSE_CREF            1<<7
#define PARSE_PDEMODELICA     1<<8
#define metamodelica_enabled() (ModelicaParser_flags&PARSE_META_MODELICA)
#define parmodelica_enabled() (ModelicaParser_flags&PARSE_PARMODELICA)
#define optimica_enabled() (ModelicaParser_flags&PARSE_OPTIMICA)
#define pdemodelica_enabled() (ModelicaParser_flags&PARSE_PDEMODELICA)
#define code_expressions_enabled() (ModelicaParser_flags&PARSE_CODE_EXPRESSION)
#define flat_modelica_enabled() (ModelicaParser_flags&PARSE_FLAT)
#define parse_expression_enabled() (ModelicaParser_flags&PARSE_EXPRESSION)

#ifdef __cplusplus
}
#endif

#endif
