/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * file simulation_input_xml.c
 * this file reads the model input from Model_init.xml
 * file using the Expat XML parser.
 * basically a structure with maps is created (see omc_ModelInput)
 * and populated during the XML parser. after, the values from it
 * are used to populate the outputs of the read_input_xml function.
 */


#include "arrayIndex.h"
#include "simulation_input_xml.h"
#include "simulation_runtime.h"
#include "options.h"
#include "../util/omc_error.h"
#include "../util/omc_file.h"
#include "../meta/meta_modelica.h"
#include "../util/modelica_string.h"
#include "solver/model_help.h"

#include <limits.h>
#include "../util/uthash.h"
#include <string.h>
#include <ctype.h>
#include <expat.h>

typedef struct hash_string_string
{
  const char *id;
  const char *val;
  UT_hash_handle hh;
} hash_string_string;

typedef hash_string_string omc_ModelDescription;
typedef hash_string_string omc_DefaultExperiment;
typedef hash_string_string omc_ModelVariable; // ScalarVariable or ArrayVariable

typedef struct hash_long_var
{
  long id;
  omc_ModelVariable *val;
  UT_hash_handle hh;
} hash_long_var;

typedef hash_long_var omc_ModelVariables;

typedef struct hash_string_long
{
  const char *id;
  long val;
  UT_hash_handle hh;
} hash_string_long;

static inline const char* findHashStringStringNull(hash_string_string *ht, const char *key)
{
  hash_string_string *res;
  HASH_FIND_STR( ht, key, res );
  return res ? res->val : NULL;
}

static inline const char* findHashStringStringEmpty(hash_string_string *ht, const char *key)
{
  const char *res = findHashStringStringNull(ht,key);
  return res ? res : "";
}

static inline const char* findHashStringString(hash_string_string *ht, const char *key)
{
  const char *res = findHashStringStringNull(ht,key);
  if (0==res) {
    hash_string_string *c, *tmp;
    HASH_ITER(hh, ht, c, tmp) {
      fprintf(stderr, "HashMap contained: %s->%s\n", c->id, c->val);
    }
    throwStreamPrint(NULL, "Failed to lookup %s in hashmap %p", key, ht);
  }
  return res;
}

static inline void addHashStringString(hash_string_string **ht, const char *key, const char *val)
{
  hash_string_string *v = (hash_string_string*) calloc(1, sizeof(hash_string_string)); /* FIXME this isn't always freed correctly */
  v->id=strdup(key);
  v->val=strdup(val);
  HASH_ADD_KEYPTR( hh, *ht, v->id, strlen(v->id), v );
}

static inline long findHashStringLongOrZero(hash_string_long *ht, const char *key)
{
  hash_string_long *res;
  HASH_FIND_STR( ht, key, res );
  return res ? res->val : 0;
}

static inline long* findHashStringLongPtr(hash_string_long *ht, const char *key)
{
  hash_string_long *res;
  HASH_FIND_STR( ht, key, res );
  return res ? &res->val : 0;
}

static inline void addHashStringLong(hash_string_long **ht, const char *key, long val)
{
  hash_string_long *v2;
  HASH_FIND_STR( *ht, key, v2 );
  if (v2) {
    v2->val = val;
  } else {
    hash_string_long *v = (hash_string_long*) calloc(1, sizeof(hash_string_long));
    v->id=strdup(key);
    v->val=val;
    HASH_ADD_KEYPTR( hh, *ht, v->id, strlen(v->id), v );
  }
}

static inline omc_ModelVariable** findHashLongVar(hash_long_var *ht, long key)
{
  hash_long_var *res;
  HASH_FIND_INT( ht, &key, res );
  if (0==res) {
    hash_long_var *c, *tmp;
    HASH_ITER(hh, ht, c, tmp) {
      fprintf(stderr, "HashMap contained: %ld->*map*\n", c->id);
    }
    throwStreamPrint(NULL, "Failed to lookup %ld in hashmap %p", key, ht);
  }
  return &res->val;
}

static inline void addHashLongVar(hash_long_var **ht, long key, omc_ModelVariable *val)
{
  hash_long_var *v = (hash_long_var*) calloc(1, sizeof(hash_long_var));
  v->id=key;
  v->val=val;
  HASH_ADD_INT( *ht, id, v );
}

/* maybe use a map below {"rSta"  -> omc_ModelVariables} */
/* typedef map < string, omc_ModelVariables > omc_ModelVariablesClassified; */

/* structure used to collect data from the xml input file */
typedef struct omc_ModelInput
{
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
  mmc_sint_t            lastCI; /* index */
  omc_ModelVariables**  lastCT; /* type (classification) */
} omc_ModelInput;

// a map for overrides
typedef hash_string_string omc_CommandLineOverrides;
// a map to find out which names were used
#define OMC_OVERRIDE_UNUSED 0
#define OMC_OVERRIDE_USED   1
typedef hash_string_long omc_CommandLineOverridesUses;

// function to handle command line settings override
modelica_boolean doOverride(omc_ModelInput *mi, MODEL_DATA *modelData, const char *override, const char *overrideFile);

static const double REAL_MIN = -DBL_MAX;
static const double REAL_MAX = DBL_MAX;
static const double INTEGER_MIN = (double)MODELICA_INT_MIN;
/* Avoid integer overflow */
static const double INTEGER_MAX = (double)MODELICA_INT_MAX;

/* reads double value from a string */
static void read_value_real(const char *s, modelica_real* res, modelica_real default_value);
/* reads integer value from a string */
static void read_value_long(const char *s, modelica_integer* res, modelica_integer default_value);
/* reads integer value from a string */
static void read_value_int(const char *s, int* res);
/* reads modelica_string value from a string */
static void read_value_string(const char *s, const char** str);
/* reads boolean value from a string */
static void read_value_bool(const char *s, modelica_boolean* str);

static void XMLCALL startElement(void *userData, const char *name, const char **attr)
{
  omc_ModelInput* mi = (omc_ModelInput*)userData;
  mmc_sint_t i = 0;

  /* handle fmiModelDescription */
  if(!strcmp(name, "fmiModelDescription")) {
    for(i = 0; attr[i]; i += 2) {
      addHashStringString(&mi->md, attr[i], attr[i+1]);
    }
    return;
  }
  /* handle DefaultExperiment */
  if(!strcmp(name, "DefaultExperiment")) {
    for(i = 0; attr[i]; i += 2) {
      addHashStringString(&mi->de, attr[i], attr[i+1]);
    }
    return;
  }

  /* handle ScalarVariable and ArrayVariable */
  if(!strcmp(name, "ScalarVariable") || !strcmp(name, "ArrayVariable"))
  {
    omc_ModelVariable *v = NULL, *vfind;
    const char *ci, *ct;
    int fail=0;
    mi->lastCI = -1;
    mi->lastCT = NULL;
    for(i = 0; attr[i]; i += 2) {
      addHashStringString(&v, attr[i], attr[i+1]);
    }
    addHashStringString(&v, "num_dimensions", "0");

    /* fetch the class index/type  */
    ci = findHashStringString(v, "classIndex");
    ct = findHashStringString(v, "classType");
    /* transform to mmc_sint_t  */
    mi->lastCI = atoi(ci);

    /* which one of the classifications?  */
    if (strlen(ct) == 4) {
      if (ct[0]=='r') {
        if (0 == strcmp(ct+1,"Sta")) {
          mi->lastCT = &mi->rSta;
        } else if (0 == strcmp(ct+1,"Der")) {
          mi->lastCT = &mi->rDer;
        } else if (0 == strcmp(ct+1,"Alg")) {
          mi->lastCT = &mi->rAlg;
        } else if (0 == strcmp(ct+1,"Par")) {
          mi->lastCT = &mi->rPar;
        } else if (0 == strcmp(ct+1,"Ali")) {
          mi->lastCT = &mi->rAli;
        } else if (0 == strcmp(ct+1,"Sen")) {
          mi->lastCT = &mi->rSen;
        } else {
          fail = 1;
        }
      } else if (ct[0]=='i') {
        if (0 == strcmp(ct+1,"Alg")) {
          mi->lastCT = &mi->iAlg;
        } else if (0 == strcmp(ct+1,"Par")) {
          mi->lastCT = &mi->iPar;
        } else if (0 == strcmp(ct+1,"Ali")) {
          mi->lastCT = &mi->iAli;
        } else {
          fail = 1;
        }
      } else if (ct[0]=='b') {
        if (0 == strcmp(ct+1,"Alg")) {
          mi->lastCT = &mi->bAlg;
        } else if (0 == strcmp(ct+1,"Par")) {
          mi->lastCT = &mi->bPar;
        } else if (0 == strcmp(ct+1,"Ali")) {
          mi->lastCT = &mi->bAli;
        } else {
          fail = 1;
        }
      } else if (ct[0]=='s') {
        if (0 == strcmp(ct+1,"Alg")) {
          mi->lastCT = &mi->sAlg;
        } else if (0 == strcmp(ct+1,"Par")) {
          mi->lastCT = &mi->sPar;
        } else if (0 == strcmp(ct+1,"Ali")) {
          mi->lastCT = &mi->sAli;
        } else {
          fail = 1;
        }
      } else {
        fail = 1;
      }
    } else {
      fail = 1;
    }

    if (fail) {
      throwStreamPrint(NULL, "simulation_input_xml.c: error reading the xml file, found unknown class: %s  for variable: %s",ct,findHashStringString(v,"name"));
    }

    /* add the ScalarVariable map to the correct map! */
    addHashLongVar(mi->lastCT, mi->lastCI, v);

    return;
  }

  /* handle Real/Integer/Boolean/String */
  if(!strcmp(name, "Real") || !strcmp(name, "Integer") || !strcmp(name, "Boolean") || !strcmp(name, "String")) {
    /* add keys/value to the last variable */
    for(i = 0; attr[i]; i += 2) {
      /* add more key/value pairs to the last variable */
      addHashStringString(findHashLongVar(*mi->lastCT, mi->lastCI), attr[i], attr[i+1]);
    }
    addHashStringString(findHashLongVar(*mi->lastCT, mi->lastCI), "variableType", name);
    return;
  }

  /* Handle Dimensions of ArrayVariable */
  if(!strcmp(name, "Dimension")) {
    char* key;
    omc_ModelVariable** v;
    const char* num_dimensions;
    char* next_num_dimensions;
    unsigned int dim_plus_1;
    unsigned int size;
    unsigned int len;

    v = findHashLongVar(*mi->lastCT, mi->lastCI);
    num_dimensions = findHashStringString(*v, "num_dimensions");
    dim_plus_1 = atoi(num_dimensions) + 1;
    size = strlen(num_dimensions) + 2; // add additional +1 for possible increase number of digits and one +1 '\0'
    next_num_dimensions = calloc(sizeof(char), size);
    sprintf(next_num_dimensions, "%u", dim_plus_1);
    addHashStringString(v, "num_dimensions", next_num_dimensions);

    len = snprintf(NULL, 0, "dim-%u-valueReference", dim_plus_1); // longest string we ever write into key
    key = calloc(sizeof(char), len + 1);

    /* add more key/value pairs to the last variable */
    for(i = 0; attr[i]; i += 2) {
      if(!strcmp(attr[i], "start")) {
        sprintf(key, "dim-%u-start", dim_plus_1);
        addHashStringString(v, key, attr[i+1]);

      } else if(!strcmp(attr[i], "valueReference")) {
        sprintf(key, "dim-%u-valueReference", dim_plus_1);
        addHashStringString(v, key, attr[i+1]);
      }
    }

    free(key);
    free(next_num_dimensions);
    return;
  }

  /* anything else, we don't handle! */
}

static void XMLCALL endElement(void *userData, const char *name)
{
  /* do nothing! */
}

/**
 * @brief Fill variable info.
 *
 * Allocates memory for strings `name`, `comment`, `filename`.
 * Needs to be freed with `freeVarInfo`.
 *
 * @param var   Model variable hash map containing variable info.
 * @param info  Variable info to fill.
 */
static void read_var_info(omc_ModelVariable *var, VAR_INFO *info)
{
  modelica_integer inputIndex;
  read_value_string(findHashStringString(var,"name"), &info->name);
  debugStreamPrint(OMC_LOG_DEBUG, 1, "read var %s from setup file", info->name);

  read_value_long(findHashStringStringNull(var,"inputIndex"), &inputIndex, -1);
  info->inputIndex = inputIndex;
  debugStreamPrint(OMC_LOG_DEBUG, 0, "read input index %d from setup file", info->inputIndex);

  read_value_int(findHashStringString(var,"valueReference"), &info->id);
  debugStreamPrint(OMC_LOG_DEBUG, 0, "read for %s id %d from setup file", info->name, info->id);
  read_value_string(findHashStringStringEmpty(var,"description"), &info->comment);
  debugStreamPrint(OMC_LOG_DEBUG, 0, "read for %s description \"%s\" from setup file", info->name, info->comment);
  read_value_string(findHashStringString(var,"fileName"), &info->info.filename);
  debugStreamPrint(OMC_LOG_DEBUG, 0, "read for %s filename %s from setup file", info->name, info->info.filename);
  read_value_long(findHashStringString(var,"startLine"), (modelica_integer*)&(info->info.lineStart), 0);
  debugStreamPrint(OMC_LOG_DEBUG, 0, "read for %s lineStart %d from setup file", info->name, info->info.lineStart);
  read_value_long(findHashStringString(var,"startColumn"), (modelica_integer*)&(info->info.colStart), 0);
  debugStreamPrint(OMC_LOG_DEBUG, 0, "read for %s colStart %d from setup file", info->name, info->info.colStart);
  read_value_long(findHashStringString(var,"endLine"), (modelica_integer*)&(info->info.lineEnd), 0);
  debugStreamPrint(OMC_LOG_DEBUG, 0, "read for %s lineEnd %d from setup file", info->name, info->info.lineEnd);
  read_value_long(findHashStringString(var,"endColumn"), (modelica_integer*)&(info->info.colEnd), 0);
  debugStreamPrint(OMC_LOG_DEBUG, 0, "read for %s colEnd %d from setup file", info->name, info->info.colEnd);
  read_value_long(findHashStringString(var,"fileWritable"), (modelica_integer*)&(info->info.readonly), 0);
  debugStreamPrint(OMC_LOG_DEBUG, 0, "read for %s readonly %d from setup file", info->name, info->info.readonly);
  if (OMC_DEBUG_STREAM(OMC_LOG_DEBUG)) messageClose(OMC_LOG_DEBUG);
}


/**
 * @brief Read variable dimension information
 *
 * <ArrayVariable>
 *   <Dimension start="3"/>
 *   <Dimension valueReference="1001"/>
 * </ArrayVariable>
 *
 * @param v               Pointer to model variable hash map.
 * @param dimension_info  Pointer to dimension info structure to populate.
 */
static void read_var_dimension(omc_ModelVariable *v, DIMENSION_INFO *dimension_info) {
  char* key;
  int len;
  DIMENSION_ATTRIBUTE* dim;
  modelica_integer i;

  read_value_long(findHashStringStringEmpty(v, "num_dimensions"), &(dimension_info->numberOfDimensions), -1);
  if (dimension_info->numberOfDimensions <= 0) {
    // No <dimension> tags
    return;
  }

  dimension_info->dimensions = (DIMENSION_ATTRIBUTE*) calloc(dimension_info->numberOfDimensions, sizeof(DIMENSION_ATTRIBUTE));

  len = snprintf(NULL, 0, "dim-%lu-valueReference", dimension_info->numberOfDimensions); // longest string we ever write into key
  key = calloc(sizeof(char), len + 1);

  for (i = 0; i < dimension_info->numberOfDimensions; i++) {
    dim = &dimension_info->dimensions[i];

    sprintf(key, "dim-%lu-start", i + 1);
    read_value_long(findHashStringStringEmpty(v, key), &(dim->start), -1);

    sprintf(key, "dim-%lu-valueReference", i + 1);
    read_value_long(findHashStringStringEmpty(v, key), &(dim->valueReference), -1);

    if (dim->start > 0 && dim->valueReference == -1) {
      dim->type = DIMENSION_BY_START;
    } else if (dim->start == -1 && dim->valueReference >= 0) {
      dim->type = DIMENSION_BY_VALUE_REFERENCE;
    } else if (dim->start == -1 && dim->valueReference == -1) {
      throwStreamPrint(NULL, "simulation_input_xml.c: Error reading the xml file! " \
                             "Found neither 'start' or 'valueReference' element in <dimension> tag.");
    } else {
      throwStreamPrint(NULL, "simulation_input_xml.c: Error reading the xml file! " \
                             "Found 'start' and 'valueReference' element in <dimension> tag, " \
                             "but only one is allowed");
    }
  }

  dimension_info->scalar_length = -1; // We might not know the values of structural parameters yet.

  free(key);
}

static void read_var_attribute_real(omc_ModelVariable *v, REAL_ATTRIBUTE *attribute)
{
  const char *unit = NULL;
  const char *displayUnit = NULL;
  read_value_real(findHashStringStringEmpty(v,"start"), &(attribute->start), 0.0);
  read_value_bool(findHashStringString(v,"fixed"), (modelica_boolean*)&(attribute->fixed));
  read_value_bool(findHashStringString(v,"useNominal"), (modelica_boolean*)&(attribute->useNominal));
  read_value_real(findHashStringStringEmpty(v,"nominal"), &(attribute->nominal), 1.0);
  read_value_real(findHashStringStringEmpty(v,"min"), &(attribute->min), REAL_MIN);
  read_value_real(findHashStringStringEmpty(v,"max"), &(attribute->max), REAL_MAX);
  read_value_string(findHashStringStringEmpty(v,"unit"), &unit);
  attribute->unit = mmc_mk_scon_persist(unit); /* this function returns a copy, so unit can be freed */
  free((char*)unit);
  // read displayUnit
  read_value_string(findHashStringStringEmpty(v,"displayUnit"), &displayUnit);
  attribute->displayUnit = mmc_mk_scon_persist(displayUnit); /* this function returns a copy, so unit can be freed */
  free((char*)displayUnit);

  infoStreamPrint(OMC_LOG_DEBUG, 0, "Real %s(start=%g, fixed=%s, %snominal=%g%s, min=%g, max=%g)", findHashStringString(v,"name"), attribute->start, (attribute->fixed)?"true":"false", (attribute->useNominal)?"":"{", attribute->nominal, attribute->useNominal?"":"}", attribute->min, attribute->max);
}

static void read_var_attribute_int(omc_ModelVariable *v, INTEGER_ATTRIBUTE *attribute)
{
  read_value_long(findHashStringStringEmpty(v,"start"), &attribute->start, 0);
  read_value_bool(findHashStringString(v,"fixed"), &attribute->fixed);
  read_value_long(findHashStringStringEmpty(v,"min"), &attribute->min, INTEGER_MIN);
  read_value_long(findHashStringStringEmpty(v,"max"), &attribute->max, INTEGER_MAX);

  infoStreamPrint(OMC_LOG_DEBUG, 0, "Integer %s(start=%ld, fixed=%s, min=%ld, max=%ld)", findHashStringString(v,"name"), attribute->start, attribute->fixed?"true":"false", attribute->min, attribute->max);
}

static void read_var_attribute_bool(omc_ModelVariable *v, BOOLEAN_ATTRIBUTE *attribute)
{
  read_value_bool(findHashStringStringEmpty(v,"start"), &attribute->start);
  read_value_bool(findHashStringString(v,"fixed"), &attribute->fixed);

  infoStreamPrint(OMC_LOG_DEBUG, 0, "Boolean %s(start=%s, fixed=%s)", findHashStringString(v,"name"), attribute->start?"true":"false", attribute->fixed?"true":"false");
}

static void read_var_attribute_string(omc_ModelVariable *v, STRING_ATTRIBUTE *attribute)
{
  const char *start = NULL;
  read_value_string(findHashStringStringEmpty(v,"start"), &start);
  attribute->start = mmc_mk_scon_persist(start); /* this function returns a copy, so start can be freed */
  free((char*)start);

  infoStreamPrint(OMC_LOG_DEBUG, 0, "String %s(start=%s)", findHashStringString(v,"name"), MMC_STRINGDATA(attribute->start));
}

/**
 * @brief Check if a variable should be filtered from the output
 *
 * the check is like this:
 * - we filter if isProtected (protected variables)
 * - we filter if annotation(HideResult=true)
 * - we emit (remove filtering) if !encrypted && emitProtected && isProtected
 * - we emit (remove filtering) if ignoreHideResult && annotation(HideResult=true)
 *
 * @param variable  Variable to check
 * @param name      Variable name
 *
 * @return TRUE if the variable should be filtered (not appear in the output)
 */
int shouldFilterOutput(omc_ModelVariable *variable, const char *name)
{
  int ep = omc_flag[FLAG_EMIT_PROTECTED];
  int ihr = omc_flag[FLAG_IGNORE_HIDERESULT];
  const char *ipstr = findHashStringString(variable, "isProtected");
  const char *hrstr = findHashStringString(variable, "hideResult");
  const char *iestr = findHashStringString(variable, "isEncrypted");
  int ipcmptrue = (0 == strcmp(ipstr, "true"));
  int hrcmptrue = (0 == strcmp(hrstr, "true"));
  int iecmptrue = (0 == strcmp(iestr, "true"));

  int shouldFilter = FALSE;

  if (ipcmptrue) {
    infoStreamPrint(OMC_LOG_DEBUG, 0, "filtering protected variable %s", name);
    shouldFilter = TRUE;
  }
  if (hrcmptrue) {
    infoStreamPrint(OMC_LOG_DEBUG, 0, "filtering variable %s due to HideResult annotation", name);
    shouldFilter = TRUE;
  }
  if (!iecmptrue && ep && ipcmptrue) {
    infoStreamPrint(OMC_LOG_DEBUG, 0, "emitting protected variable %s due to flag %s", name, omc_flagValue[FLAG_EMIT_PROTECTED]);
    shouldFilter = FALSE;
  }
  if (ihr && hrcmptrue) {
    infoStreamPrint(OMC_LOG_DEBUG, 0, "emitting variable %s with HideResult=true annotation due to flag %s", name, omc_flagValue[FLAG_IGNORE_HIDERESULT]);
    shouldFilter = FALSE;
  }

  return shouldFilter;
}

/**
 * @brief Read all static data from File for every variable
 *
 * @param simulationInfo
 * @param type                T_REAL, T_INTEGER, T_BOOLEAN, T_STRING
 * @param out                 Write variable infos into.
 *                            Must be of type STATIC_<type>_DATA
 * @param in                  Model variable map
 * @param debugName           Name used in debug output
 * @param start               Start index in out
 * @param numVariables        Number of variables to read
 * @param mapAlias            Map of variable names to indices in out
 * @param mapAliasParam       Map of parameter names to indices in out
 * @param sensitivityParIndex Index in sensitivityParList, will be incremented
 *                            for each sensitivity parameter found
 */
static void read_variables(SIMULATION_INFO* simulationInfo,
                           enum var_type type,
                           void *out,
                           omc_ModelVariables *in,
                           const char *debugName,
                           mmc_sint_t start,
                           mmc_sint_t numVariables,
                           hash_string_long **mapAlias,
                           hash_string_long **mapAliasParam,
                           int *sensitivityParIndex)
{
  char type_name[8];
  VAR_INFO *info;
  DIMENSION_INFO* dimension;
  modelica_boolean *filterOutput;
  mmc_sint_t i, j;
  omc_ModelVariable *v;

  infoStreamPrint(OMC_LOG_DEBUG, 1, "read xml file for %s", debugName);
  for (i = 0; i < numVariables; i++) {
    j = start + i;
    v = *findHashLongVar(in, i);

    // Access real/int/bool/string attribute data
    // Set info, dimension and filterOutput pointers
    switch (type) {
      case T_REAL:
        {
          strncpy(type_name, "real", 8);
          STATIC_REAL_DATA* realVarsData = (STATIC_REAL_DATA*) out;
          REAL_ATTRIBUTE* attribute = &realVarsData[j].attribute;
          read_var_attribute_real(v, attribute);
          info = &realVarsData[j].info;
          dimension = &realVarsData[j].dimension;
          filterOutput = &realVarsData[j].filterOutput;
        }
        break;
      case T_INTEGER:
        {
          strncpy(type_name, "integer", 8);
          STATIC_INTEGER_DATA* intVarsData = (STATIC_INTEGER_DATA*) out;
          INTEGER_ATTRIBUTE* attribute = &intVarsData[j].attribute;
          read_var_attribute_int(v, attribute);
          info = &intVarsData[j].info;
          dimension = &intVarsData[j].dimension;
          filterOutput = &intVarsData[j].filterOutput;
        }
        break;
      case T_BOOLEAN:
        {
          strncpy(type_name, "boolean", 8);
          STATIC_BOOLEAN_DATA* boolVarsData = (STATIC_BOOLEAN_DATA*) out;
          BOOLEAN_ATTRIBUTE* attribute = &boolVarsData[j].attribute;
          read_var_attribute_bool(v, attribute);
          info = &boolVarsData[j].info;
          dimension = &boolVarsData[j].dimension;
          filterOutput = &boolVarsData[j].filterOutput;
        }
        break;
      case T_STRING:
        {
          strncpy(type_name, "string", 8);
          STATIC_STRING_DATA* stringVarsData = (STATIC_STRING_DATA*) out;
          STRING_ATTRIBUTE* attribute = &stringVarsData[j].attribute;
          read_var_attribute_string(v, attribute);
          info = &stringVarsData[j].info;
          dimension = &stringVarsData[j].dimension;
          filterOutput = &stringVarsData[j].filterOutput;
        }
        break;
      default:
        throwStreamPrint(NULL, "simulation_input_xml.c: Error: Unsupported type in read_variables.");
        break;
    }

    read_var_dimension(v, dimension);
    read_var_info(v, info);
    *filterOutput = shouldFilterOutput(v, info->name);

    /* create a mapping for Alias variable to get the correct index */
    addHashStringLong(mapAlias, info->name, j);
    debugStreamPrint(OMC_LOG_DEBUG, 0, "%s %s: mapAlias[%s] = %ld", type_name, debugName, info->name, (long)(j));
    if (omc_flag[FLAG_IDAS] && 0 == strcmp(debugName, "real sensitivities")) {
      if (0 == strcmp(findHashStringString(v, "isValueChangeable"), "true")) {
        long *it = findHashStringLongPtr(*mapAliasParam, info->name);
        // TODO: This should not be filled here. It's part of simulation info, not model data.
        simulationInfo->sensitivityParList[*sensitivityParIndex] = *it;
        infoStreamPrint(OMC_LOG_SOLVER, 0, "%d. sensitivity parameter %s at index %d", *sensitivityParIndex, info->name, simulationInfo->sensitivityParList[*sensitivityParIndex]);
        (*sensitivityParIndex)++;
      }
    }
  }
  messageClose(OMC_LOG_DEBUG);
}

/**
 * @brief Read XML file name from user supplied flags
 *
 * @return const char* Filename, needs to be freed.
 */
char* getXMLfileName(const char* modelFilePrefix, threadData_t* threadData) {
  char *filename;

  if (omc_flag[FLAG_F]) { // Read the filename from the command line
    filename = strdup(omc_flagValue[FLAG_F]);
    if(filename == NULL) {
      throwStreamPrint(threadData, "simulation_input_xml.c: Out of memory");
    }
  } else if (omc_flag[FLAG_INPUT_PATH]) { //  Read the input path from the command line
    filename = (char*) calloc(strlen(omc_flagValue[FLAG_INPUT_PATH]) + strlen(modelFilePrefix) + 10 + 1, sizeof(char));
    if(filename == NULL) {
      throwStreamPrint(threadData, "simulation_input_xml.c: Out of memory");
    }
    sprintf(filename, "%s/%s_init.xml", omc_flagValue[FLAG_INPUT_PATH], modelFilePrefix);
  } else { // Use default model_name
    filename = (char*) calloc(strlen(modelFilePrefix) + 9 + 1, sizeof(char));
    if(filename == NULL) {
      throwStreamPrint(threadData, "simulation_input_xml.c: Out of memory");
    }
    sprintf(filename, "%s_init.xml", modelFilePrefix);
  }

  return filename;
}

/**
 * @brief Parse input XML content.
 *
 * @param filename          Name to init XML file. If no file is available set `initXMLData` with the content of the file instead.
 * @param initXMLData       [Optional] Content of input XML file.
 * @param threadData        For error handling, can be NULL.
 * @return omc_ModelInput*  Hash map with all data read from XML. Needs to be freed by caller with `free`.
 */
omc_ModelInput* parse_input_xml(const char *filename, const char* initXMLData, threadData_t* threadData) {
  XML_Parser parser = NULL;
  enum XML_Status status;
  FILE* file = NULL;
  omc_ModelInput* mi = (omc_ModelInput*) calloc(1, sizeof(omc_ModelInput));

  /* create the XML parser */
  parser = XML_ParserCreate(NULL);
  if(!parser)
  {
    fclose(file);
    throwStreamPrint(threadData, "simulation_input_xml.c: Error: couldn't allocate memory for the XML parser!");
  }

  /* set our user data */
  XML_SetUserData(parser, mi);

  /* set the handlers for start/end of element. */
  XML_SetElementHandler(parser, startElement, endElement);

  if(initXMLData == NULL) {
    file = omc_fopen(filename, "r");
    if(!file) {
      throwStreamPrint(threadData, "simulation_input_xml.c: Error: can not read file %s as setup file to the generated simulation code.", filename);
    }

    int done;
    char buf[BUFSIZ+1] = {0};
    do
    {
      size_t len = omc_fread(buf, 1, BUFSIZ, file, 1);
      done = len < BUFSIZ;
      status = XML_Parse(parser, buf, len, done);
      if(status == XML_STATUS_ERROR)
      {
        fclose(file);
        warningStreamPrint(OMC_LOG_STDOUT, 0, "simulation_input_xml.c: Error: failed to read the XML file %s: %s at line %lu\n",
            filename,
            XML_ErrorString(XML_GetErrorCode(parser)),
            XML_GetCurrentLineNumber(parser));
        XML_ParserFree(parser);
        throwStreamPrint(threadData, "see last warning");
      }
    } while(!done);
    fclose(file);
  } else {
    status = XML_Parse(parser, initXMLData, strlen(initXMLData), 1);
    if(status == XML_STATUS_ERROR) {
      fprintf(stderr, "%s, %s %lu\n", initXMLData, XML_ErrorString(XML_GetErrorCode(parser)), XML_GetCurrentLineNumber(parser));
      warningStreamPrint(OMC_LOG_STDOUT, 0, "simulation_input_xml.c: Error: failed to read the XML data %s: %s at line %lu\n",
              initXMLData,
              XML_ErrorString(XML_GetErrorCode(parser)),
              XML_GetCurrentLineNumber(parser));
      XML_ParserFree(parser);
      throwStreamPrint(threadData, "see last warning");
    }
  }

  return mi;
}

/**
 * @brief Read default experiment information.
 *
 * @param simulationInfo    Contains read values after return.
 * @param de                Default experiment hash map.
 * @param reCalcStepSize    If true step size is recalculated instead of read from hash map.
 */
void read_default_experiment(SIMULATION_INFO* simulationInfo, omc_DefaultExperiment *de, modelica_boolean reCalcStepSize) {
  infoStreamPrint(OMC_LOG_SIMULATION, 1, "read all the DefaultExperiment values:");

  read_value_real(findHashStringString(de,"startTime"), &(simulationInfo->startTime), 0);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "startTime = %g", simulationInfo->startTime);

  read_value_real(findHashStringString(de,"stopTime"), &(simulationInfo->stopTime), 1.0);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "stopTime = %g", simulationInfo->stopTime);

  if (reCalcStepSize) {
    simulationInfo->stepSize = (simulationInfo->stopTime - simulationInfo->startTime) / 500;
    warningStreamPrint(OMC_LOG_STDOUT, 1, "Start or stop time was overwritten, but no new integrator step size was provided.");
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Re-calculating step size for 500 intervals.");
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Add `stepSize=<value>` to `-override=` or override file to silence this warning.");
    messageClose(OMC_LOG_STDOUT);
  } else {
    read_value_real(findHashStringString(de,"stepSize"), &(simulationInfo->stepSize), (simulationInfo->stopTime - simulationInfo->startTime) / 500);
  }
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "stepSize = %g", simulationInfo->stepSize);

  read_value_real(findHashStringString(de,"tolerance"), &(simulationInfo->tolerance), 1e-5);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "tolerance = %g", simulationInfo->tolerance);

  read_value_string(findHashStringString(de,"solver"), &simulationInfo->solverMethod);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "solver method: %s", simulationInfo->solverMethod);

  read_value_string(findHashStringString(de,"outputFormat"), &(simulationInfo->outputFormat));
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "output format: %s", simulationInfo->outputFormat);

  read_value_string(findHashStringString(de,"variableFilter"), &(simulationInfo->variableFilter));
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "variable filter: %s", simulationInfo->variableFilter);

  messageClose(OMC_LOG_SIMULATION);
}

/**
 * @brief Read number of scalar and array variables / parameters.
 *
 * Read number of scalar and array variables or parameters from model
 * description into `modelData`. Here one array variable of arbitrary size
 * counts as one variable.
 *
 * @param md          Model description hash map.
 * @param modelData   Model data to contain number of variables / parameters on
 * return.
 */
void read_model_description_sizes(omc_ModelDescription *md, MODEL_DATA *modelData) {
  modelica_integer numRealAlgVars;

  read_value_long(findHashStringString(md, "numberOfContinuousStates"), &modelData->nStatesArray, 0);
  read_value_long(findHashStringString(md, "numberOfRealAlgebraicVariables"), &numRealAlgVars, 0);
  modelData->nVariablesRealArray = 2*modelData->nStatesArray + numRealAlgVars;
  read_value_long(findHashStringString(md, "numberOfRealAlgebraicAliasVariables"), &modelData->nAliasRealArray, 0);
  // TODO: How to get data->modelData->nDiscreteReal or its array version?
  read_value_long(findHashStringString(md, "numberOfRealParameters"), &modelData->nParametersRealArray, 0);

  read_value_long(findHashStringString(md, "numberOfIntegerParameters"), &modelData->nParametersIntegerArray, 0);
  read_value_long(findHashStringString(md, "numberOfIntegerAlgebraicVariables"), &modelData->nVariablesIntegerArray, 0);
  read_value_long(findHashStringString(md, "numberOfIntegerAliasVariables"), &modelData->nAliasIntegerArray, 0);

  read_value_long(findHashStringString(md, "numberOfBooleanParameters"), &modelData->nParametersBooleanArray, 0);
  read_value_long(findHashStringString(md, "numberOfBooleanAlgebraicVariables"), &modelData->nVariablesBooleanArray, 0);
  read_value_long(findHashStringString(md, "numberOfBooleanAliasVariables"), &modelData->nAliasBooleanArray, 0);

  read_value_long(findHashStringString(md, "numberOfStringParameters"), &modelData->nParametersStringArray, 0);
  read_value_long(findHashStringString(md, "numberOfStringAlgebraicVariables"),  &modelData->nVariablesStringArray, 0);
  read_value_long(findHashStringString(md, "numberOfStringAliasVariables"),  &modelData->nAliasStringArray, 0);
}

/**
 * @brief Read all alias variables from hash map.
 *
 * Fill if parameter is negated, its ID, and alias type (variable, parameter, time).
 *
 * @param alias           Alias variable to fill with values from hash map.
 * @param aliasHashMap    Alias hash map.
 * @param nAliasVariables Number of alias variables in hash map.
 * @param mapAlias        Hash map for alias variables.
 * @param mapAliasParam   Hash map for alias parameters.
 */
void read_alias_var(DATA_ALIAS* alias,
                    omc_ModelVariables *aliasHashMap,
                    unsigned long nAliasVariables,
                    hash_string_long *mapAlias,
                    hash_string_long *mapAliasParam)
{
  // Assert nAliasVariables has correct size
  size_t num_alias_vars_xml = HASH_COUNT(aliasHashMap);
  assertStreamPrint(NULL, nAliasVariables == num_alias_vars_xml, "Number of alias variables doesn't match up. Expected %zu but found %zu in XML!", nAliasVariables, num_alias_vars_xml);

  long *it, *itParam;
  const char *aliasTmp = NULL;

  for(unsigned long i=0; i < nAliasVariables; i++)
  {
    read_var_info(*findHashLongVar(aliasHashMap, i), &alias[i].info);

    read_value_string(findHashStringStringNull(*findHashLongVar(aliasHashMap, i),"alias"), &aliasTmp);
    if (0 == strcmp(aliasTmp, "negatedAlias")) {
      alias[i].negate = 1;
    } else {
      alias[i].negate = 0;
    }
    infoStreamPrint(OMC_LOG_DEBUG, 0, "read for %s negated %d from setup file", alias[i].info.name, alias[i].negate);

    alias[i].filterOutput = shouldFilterOutput(*findHashLongVar(aliasHashMap, i), alias[i].info.name);

    free((char*)aliasTmp);
    aliasTmp = NULL;

    read_value_string(findHashStringStringNull(*findHashLongVar(aliasHashMap, i),"aliasVariable"), &aliasTmp);

    it = findHashStringLongPtr(mapAlias, aliasTmp);
    itParam = findHashStringLongPtr(mapAliasParam, aliasTmp);

    if (NULL != it) {
      alias[i].nameID  = *it;
      alias[i].aliasType = ALIAS_TYPE_VARIABLE;
    } else if (NULL != itParam) {
      alias[i].nameID  = *itParam;
      alias[i].aliasType = ALIAS_TYPE_PARAMETER;
    } else if (0 == strcmp(aliasTmp, "time")) {
      alias[i].aliasType = ALIAS_TYPE_TIME;
    } else {
      throwStreamPrint(NULL, "Alias variable %s not found.", aliasTmp);
    }
    free((char*)aliasTmp);
    aliasTmp = NULL;
  }
}

/**
 * @brief Reads initial values from init XML file.
 *
 * Can be FMI 1.0 modelDescription.xml or in a similar style.
 *
 *   - Parse init XML file or content written in C with Expat.
 *   - Checks GUID.
 *   - Read number of variables / parameters from XML.
 *   - Update initial values with overrides.
 *   - Read default experiment.
 *   - Allocates model data variables --> free with `freeModelDataVars`.
 *   - Read all initial values into `modelData`.
 *
 * @param modelData       Model data to update.
 * @param simulationInfo  Simulation info to update.
 * @param threadData      Thread data for error handling.
 */
void read_input_xml(MODEL_DATA* modelData,
                    SIMULATION_INFO* simulationInfo,
                    threadData_t* threadData)
{
  omc_ModelInput* mi;

  const char *filename, *guid, *override, *overrideFile;
  hash_string_long *mapAlias = NULL, *mapAliasParam = NULL, *mapAliasSen = NULL;
  int sensitivityParIndex = 0;

  filename = getXMLfileName(modelData->modelFilePrefix, threadData);
  mi = parse_input_xml(filename, modelData->initXMLData, threadData);

  /* Check modelGUID */
  guid = findHashStringStringNull(mi->md, "guid");
  if (NULL == guid) {
    warningStreamPrint(OMC_LOG_STDOUT, 0, "The Model GUID: %s is not set in file: %s",
        modelData->modelGUID,
        filename);
  } else if (strcmp(modelData->modelGUID, guid)) {
    throwStreamPrint(threadData, "GUID: %s from input data file: %s does not match the GUID compiled in the model: %s",
        guid,
        filename,
        modelData->modelGUID);
  }

  // Read sizes before using them
  read_model_description_sizes(mi->md, modelData);

  /* Update inital values from override flag */
  override = omc_flagValue[FLAG_OVERRIDE];
  overrideFile = omc_flagValue[FLAG_OVERRIDE_FILE];
  modelica_boolean reCalcStepSize = doOverride(mi, modelData, override, overrideFile);

  /* Read initial values from hash map */
  read_default_experiment(simulationInfo, mi->de, reCalcStepSize);

  read_value_string(findHashStringString(mi->md,"OPENMODELICAHOME"), &simulationInfo->OPENMODELICAHOME);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "OPENMODELICAHOME: %s", simulationInfo->OPENMODELICAHOME);

  allocModelDataVars(modelData, threadData);

  read_variables(simulationInfo, T_REAL,    modelData->realVarsData,         mi->rSta, "real states",            0,                    modelData->nStatesArray,                               &mapAlias,      &mapAliasParam, &sensitivityParIndex);
  read_variables(simulationInfo, T_REAL,    modelData->realVarsData,         mi->rDer, "real state derivatives", modelData->nStatesArray,   modelData->nStatesArray,                               &mapAlias,      &mapAliasParam, &sensitivityParIndex);
  read_variables(simulationInfo, T_REAL,    modelData->realVarsData,         mi->rAlg, "real algebraics",        2*modelData->nStatesArray, modelData->nVariablesRealArray - 2*modelData->nStatesArray, &mapAlias,      &mapAliasParam, &sensitivityParIndex);

  read_variables(simulationInfo, T_INTEGER, modelData->integerVarsData,      mi->iAlg, "integer variables",      0,                    modelData->nVariablesIntegerArray,                     &mapAlias,      &mapAliasParam, &sensitivityParIndex);
  read_variables(simulationInfo, T_BOOLEAN, modelData->booleanVarsData,      mi->bAlg, "boolean variables",      0,                    modelData->nVariablesBooleanArray,                     &mapAlias,      &mapAliasParam, &sensitivityParIndex);
  read_variables(simulationInfo, T_STRING,  modelData->stringVarsData,       mi->sAlg, "string variables",       0,                    modelData->nVariablesStringArray,                      &mapAlias,      &mapAliasParam, &sensitivityParIndex);

  read_variables(simulationInfo, T_REAL,    modelData->realParameterData,    mi->rPar, "real parameters",        0,                    modelData->nParametersRealArray,                       &mapAliasParam, &mapAliasParam, &sensitivityParIndex);
  read_variables(simulationInfo, T_INTEGER, modelData->integerParameterData, mi->iPar, "integer parameters",     0,                    modelData->nParametersIntegerArray,                    &mapAliasParam, &mapAliasParam, &sensitivityParIndex);
  read_variables(simulationInfo, T_BOOLEAN, modelData->booleanParameterData, mi->bPar, "boolean parameters",     0,                    modelData->nParametersBooleanArray,                    &mapAliasParam, &mapAliasParam, &sensitivityParIndex);
  read_variables(simulationInfo, T_STRING,  modelData->stringParameterData,  mi->sPar, "string parameters",      0,                    modelData->nParametersStringArray,                     &mapAliasParam, &mapAliasParam, &sensitivityParIndex);

  if (omc_flag[FLAG_IDAS]) {
    /* allocate memory for sensitivity analysis */
    simulationInfo->sensitivityParList = (int*) calloc(modelData->nSensitivityParamVars, sizeof(int));
    simulationInfo->sensitivityMatrix = (modelica_real*) calloc(modelData->nSensitivityVars - modelData->nSensitivityParamVars, sizeof(modelica_real));

    // TODO: We also need nSensitivityVarsArray
    read_variables(simulationInfo, T_REAL, modelData->realSensitivityData, mi->rSen, "real sensitivities", 0, modelData->nSensitivityVars, &mapAliasSen, &mapAliasParam, &sensitivityParIndex);
  }

  /* Read all alias variables */
  infoStreamPrint(OMC_LOG_DEBUG, 0, "Read XML file for real alias vars");
  read_alias_var(modelData->realAlias, mi->rAli, modelData->nAliasRealArray, mapAlias, mapAliasParam);
  infoStreamPrint(OMC_LOG_DEBUG, 0, "Read XML file for integer alias vars");
  read_alias_var(modelData->integerAlias, mi->iAli, modelData->nAliasIntegerArray, mapAlias, mapAliasParam);
  infoStreamPrint(OMC_LOG_DEBUG, 0, "Read XML file for boolean alias vars");
  read_alias_var(modelData->booleanAlias, mi->bAli, modelData->nAliasBooleanArray, mapAlias, mapAliasParam);
  infoStreamPrint(OMC_LOG_DEBUG, 0, "Read XML file for string alias vars");
  read_alias_var(modelData->stringAlias, mi->sAli, modelData->nAliasStringArray, mapAlias, mapAliasParam);

  calculateAllScalarLength(modelData);

  free((char*)filename);
  free(mi);
}

/* reads modelica_string value from a string */
static inline void read_value_string(const char *s, const char **str)
{
  if(str == NULL)
  {
    warningStreamPrint(OMC_LOG_SIMULATION, 0, "error read_value, no data allocated for storing string");
    return;
  }
  *str = strdup(s); /* memory is allocated here, must be freed by the caller */
}

/* reads double value from a string */
static inline void read_value_real(const char *s, modelica_real* res, modelica_real default_value)
{
  if (*s == '\0') {
    *res = default_value;
  } else if (0 == strcmp(s, "true")) {
    *res = 1.0;
  } else if (0 == strcmp(s, "false")) {
    *res = 0.0;
  } else {
    *res = atof(s);
  }
}

/* reads boolean value from a string */
static inline void read_value_bool(const char *s, modelica_boolean* res)
{
  *res = 0 == strcmp(s, "true");
}

/* reads integer value from a string */
static inline void read_value_long(const char *s, modelica_integer* res, modelica_integer default_value)
{
  if (s == NULL || *s == '\0') {
    *res = default_value;
  } else if (0 == strcmp(s, "true")) {
    *res = 1;
  } else if (0 == strcmp(s, "false")) {
    *res = 0;
  } else {
    *res = atol(s);
  }
}

/* reads int value from a string */
static inline void read_value_int(const char *s, int* res)
{
  if (0 == strcmp(s, "true")) {
    *res = 1;
  } else if (0 == strcmp(s, "false")) {
    *res = 0;
  } else {
    *res = atoi(s);
  }
}

static char* trim(char *str) {
  char *res=str,*end=str+strlen(str)-1;
  while (isspace(*res)) {
    res++;
  }
  while (isspace(*end)) {
    *end='\0';
    end--;
  }
  return res;
}

static const char* getOverrideValue(omc_CommandLineOverrides *mOverrides, omc_CommandLineOverridesUses **mOverridesUses, const char *name)
{
  addHashStringLong(mOverridesUses, name, OMC_OVERRIDE_USED);
  return findHashStringString(mOverrides, name);
}

/**
 * @brief Check override and do override.
 *
 * Overwrite start value if variable is changeable. Otherwise add it to
 * `mOverridesUses`.
 *
 * @param mOverrides            Command line overrides.
 * @param mOverridesUses
 * @param variables             Hash map with variables to check override for.
 * @param index                 Index of variable in map `variables`.
 * @param warn_small_override   Issue warning if overriding small value or zero if set to `1`.
 */
static void singleOverride(omc_CommandLineOverrides *mOverrides,
                           omc_CommandLineOverridesUses **mOverridesUses,
                           omc_ModelVariables *variables,
                           size_t index,
                           int warn_small_override)
{
  if (findHashStringStringNull(mOverrides, findHashStringString(*findHashLongVar(variables, index), "name")))
  {
    if (0 == strcmp(findHashStringString(*findHashLongVar(variables, index), "isValueChangeable"), "true"))
    {
      infoStreamPrint(OMC_LOG_SOLVER, 0,
                      "override %s = %s",
                      findHashStringString(*findHashLongVar(variables, index), "name"),
                      getOverrideValue(mOverrides, mOverridesUses, findHashStringString(*findHashLongVar(variables, index), "name")));
      if (warn_small_override && fabs(atof(getOverrideValue(mOverrides, mOverridesUses, findHashStringString(*findHashLongVar(variables, index), "name")))) < 1e-6) {
        warningStreamPrint(OMC_LOG_STDOUT, 0,
                           "You are overriding %s with a small value or zero.\n"\
                           "This could lead to numerically dirty solutions or divisions by zero if not tearingStrictness=veryStrict.",
                           findHashStringString(*findHashLongVar(variables, index), "name"));
      }
      addHashStringString(
        findHashLongVar(variables, index),
        "start",
        getOverrideValue(mOverrides, mOverridesUses, findHashStringString(*findHashLongVar(variables, index), "name")));
    }
    else
    {
      addHashStringLong(
        mOverridesUses,
        findHashStringString(*findHashLongVar(variables, index), "name"), OMC_OVERRIDE_USED);
      warningStreamPrint(OMC_LOG_STDOUT, 0,
                         "It is not possible to override the following quantity: %s\n"\
                         "It seems to be structural, final, protected or evaluated or has a non-constant binding.",
                         findHashStringString(*findHashLongVar(variables, index), "name"));
    }
  }
}

/**
 * @brief Read override values from simulation flags `-override` and `-overrideFile` and update variables.
 *
 * Return if step sizes needs to be re-calculated because start or stop time was changed, but step size wasn't changed.
 *
 * @param mi                    Model input from info XML file.
 * @param modelData             Pointer to model data containing variable values to override.
 * @param overrideFile          Path to override file given by `-overrideFile`.
 * @return modelica_boolean     True if integrator step size should be re-caclualted.
 */
modelica_boolean doOverride(omc_ModelInput *mi, MODEL_DATA *modelData, const char *override, const char *overrideFile)
{
  omc_CommandLineOverrides *mOverrides = NULL;
  omc_CommandLineOverridesUses *mOverridesUses = NULL, *it = NULL, *ittmp = NULL;
  mmc_sint_t i;
  modelica_boolean changedStartStop = 0 /* false */;
  modelica_boolean changedStepSize = 0 /* false */;
  modelica_boolean reCalcStepSize = 0 /* false */;
  char* overrideStr1 = NULL, *overrideStr2 = NULL, *overrideStr = NULL;
  if((override != NULL) && (overrideFile != NULL)) {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "using -override=%s and -overrideFile=%s", override, overrideFile);
  }

  if(override != NULL) {
    overrideStr1 = strdup(override);
  }

  if(overrideFile != NULL) {
    FILE *infile = NULL;
    char *line=NULL, *tline=NULL, *tline2=NULL;
    char *overrideLine;
    size_t n=0;

    /* read override values from file */
    infoStreamPrint(OMC_LOG_SOLVER, 0, "read override values from file: %s", overrideFile);

    infile = omc_fopen(overrideFile, "rb");
    if (0==infile) {
      throwStreamPrint(NULL, "simulation_input_xml.c: could not open the file given to -overrideFile=%s", overrideFile);
    }

    fseek(infile, 0L, SEEK_END);
    n = ftell(infile);
    line = (char*) malloc(n+1);
    line[0] = '\0';
    fseek(infile, 0L, SEEK_SET);
    errno = 0;
    if (1 != omc_fread(line, n, 1, infile, 0)) {
      free(line);
      throwStreamPrint(NULL, "simulation_input_xml.c: could not read overrideFile %s: %s", overrideFile, strerror(errno));
    }
    line[n] = '\0';
    overrideLine = (char*) malloc(n+1);
    overrideLine[0] = '\0';
    overrideStr2 = overrideLine;
    tline = line;

    /* get the lines */
    while (0 != (tline2=strchr(tline,'\n'))) {
      *tline2 = '\0';

      tline = trim(tline);
      // if is comment //, ignore line
      if (tline[0] && tline[0] != '/' && tline[1] != '/') {
        if (overrideLine != overrideStr2) {
          overrideLine[0] = ',';
          ++overrideLine;
        }
        overrideLine = strcpy(overrideLine,tline)+strlen(tline);
      }
      tline = tline2+1;
    }
    fclose(infile);
    free(line);
  }

  if (overrideStr1 != NULL || overrideStr2 != NULL) {
    char *value, *p, *ov;
    const char *strs[] = {"solver","startTime","stopTime","stepSize","tolerance","outputFormat","variableFilter"};
    /* read override values */
    infoStreamPrint(OMC_LOG_SOLVER, 0, "-override=%s", overrideStr1 ? overrideStr1 : "[not given]");
    infoStreamPrint(OMC_LOG_SOLVER, 0, "-overrideFile=%s", overrideStr2 ? overrideStr2 : "[not given]");
    /* fix overrideStr to contain | instead of , for splitting */
    if (overrideStr1)
    {
      parseVariableStr(overrideStr1);
      p = strtok(overrideStr1, "!");

      while (p) {
        // split it key = value => map[key]=value
        value = strchr(p, '=');

        if (!value) {
          throwStreamPrint(NULL, "Invalid format for value of override flag: %s", override);
        }

        if (*value == '\0') {
          warningStreamPrint(OMC_LOG_SOLVER, 0, "failed to parse override string %s", p);
          p = strtok(NULL, "!");
        }
        *value = '\0';
        value++;
        // map[key]=value
        // check if we already overrided this variable
        ov = (char*)findHashStringStringNull(mOverrides, p);
        if (ov)
        {
          warningStreamPrint(OMC_LOG_STDOUT, 0, "You are overriding variable: %s=%s again with %s=%s.", p, ov, p, value);
        }
        addHashStringString(&mOverrides, p, value);
        addHashStringLong(&mOverridesUses, p, OMC_OVERRIDE_UNUSED);

        // move to next
        p = strtok(NULL, "!");
      }
      free(overrideStr1);
    }

    if (overrideStr2)
    {
      parseVariableStr(overrideStr2);
      p = strtok(overrideStr2, "!");

      while (p) {
        // split it key = value => map[key]=value
        value = strchr(p, '=');

        if (!value) {
          throwStreamPrint(NULL, "Invalid format for value of override flag: %s", override);
        }

        if (*value == '\0') {
          warningStreamPrint(OMC_LOG_SOLVER, 0, "failed to parse override string %s", p);
          p = strtok(NULL, "!");
        }
        *value = '\0';
        value++;
        // map[key]=value
        ov = (char*)findHashStringStringNull(mOverrides, p);
        if (ov)
        {
          warningStreamPrint(OMC_LOG_STDOUT, 0, "You are overriding variable: %s=%s again with %s=%s.", p, ov, p, value);
        }
        addHashStringString(&mOverrides, p, value);
        addHashStringLong(&mOverridesUses, p, OMC_OVERRIDE_UNUSED);

        // move to next
        p = strtok(NULL, "!");
      }
      free(overrideStr2);
    }

    // Now we have all overrides in mOverrides, override mi now
    // Also check if we need to re-calculate stepSize (start / stop time changed, but stepSize not)
    for (i=0; i<sizeof(strs)/sizeof(char*); i++) {
      if (findHashStringStringNull(mOverrides, strs[i])) {
        addHashStringString(&mi->de, strs[i], getOverrideValue(mOverrides, &mOverridesUses, strs[i]));
        if (i==1 /* startTime */ || i ==2 /* stopTime */ ) {
          changedStartStop = 1 /* true */;
        }
        if (i==3 /* stepSize */) {
          changedStepSize = 1 /* true */;
        }
      }
    }
    reCalcStepSize = changedStartStop && !changedStepSize;

    // override all found!
    for(i=0; i<modelData->nStatesArray; i++) {
      singleOverride(mOverrides, &mOverridesUses, mi->rSta, i, 0);
      singleOverride(mOverrides, &mOverridesUses, mi->rDer, i, 0);
    }
    for(i=0; i<(modelData->nVariablesRealArray - 2*modelData->nStatesArray); i++) {
      singleOverride(mOverrides, &mOverridesUses, mi->rAlg, i, 0);
    }
    for(i=0; i<modelData->nVariablesIntegerArray; i++) {
      singleOverride(mOverrides, &mOverridesUses, mi->iAlg, i, 0);
    }
    for(i=0; i<modelData->nVariablesBooleanArray; i++) {
      singleOverride(mOverrides, &mOverridesUses, mi->bAlg, i, 0);
    }
    for(i=0; i<modelData->nVariablesStringArray; i++) {
      singleOverride(mOverrides, &mOverridesUses, mi->sAlg, i, 0);
    }
    for(i=0; i<modelData->nParametersRealArray; i++) {
      // TODO: only allow to override primary parameters
      singleOverride(mOverrides, &mOverridesUses, mi->rPar, i, 1);
    }
    for(i=0; i<modelData->nParametersIntegerArray; i++) {
      // TODO: only allow to override primary parameters
      singleOverride(mOverrides, &mOverridesUses, mi->iPar, i, 1);
    }
    for(i=0; i<modelData->nParametersBooleanArray; i++) {
      // TODO: only allow to override primary parameters
      singleOverride(mOverrides, &mOverridesUses, mi->bPar, i, 0);
    }
    for(i=0; i<modelData->nParametersStringArray; i++) {
      // TODO: only allow to override primary parameters
      singleOverride(mOverrides, &mOverridesUses, mi->sPar, i, 0);
    }
    for(i=0; i<modelData->nAliasRealArray; i++) {
      singleOverride(mOverrides, &mOverridesUses, mi->rAli, i, 0);
    }
    for(i=0; i<modelData->nAliasIntegerArray; i++) {
      singleOverride(mOverrides, &mOverridesUses, mi->iAli, i, 0);
    }
    for(i=0; i<modelData->nAliasBooleanArray; i++) {
      singleOverride(mOverrides, &mOverridesUses, mi->bAli, i, 0);
    }
    for(i=0; i<modelData->nAliasStringArray; i++) {
      singleOverride(mOverrides, &mOverridesUses, mi->sAli, i, 0);
    }

    // give a warning if an override is not used #3204
    HASH_ITER(hh, mOverridesUses, it, ittmp) {
      if (it->val == OMC_OVERRIDE_UNUSED) {
        warningStreamPrint(OMC_LOG_STDOUT, 0, "simulation_input_xml.c: override variable name not found in model: %s\n", it->id);
      }
    }

    infoStreamPrint(OMC_LOG_SOLVER, 0, "override done!");
  } else {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "NO override given on the command line.");
  }

  return reCalcStepSize;
}

void parseVariableStr(char* variableStr)
{
  /* TODO! FIXME!: support also quoted identifiers containing comma: , */
  unsigned int i = 0, insideArray = 0;
  for (i = 0; i < strlen(variableStr); i++)
  {
    if (variableStr[i] == '[') { insideArray = 1; }
    if (variableStr[i] == ']') { insideArray = 0; }
    if ((insideArray == 0) && (variableStr[i] == ',')) { variableStr[i] = '!'; }
  }
}
