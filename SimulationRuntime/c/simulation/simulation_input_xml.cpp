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
 * file simulation_input_xml.cpp
 * this file reads the model input from Model_init.xml
 * file using the Expat XML parser.
 * basically a structure with maps is created (see omc_ModelInput)
 * and populated during the XML parser. after, the values from it
 * are used to populate the outputs of the read_input_xml function.
 */


#include "simulation_input_xml.h"
#include "simulation_runtime.h"
#include "options.h"
#include "util/omc_error.h"
#include "meta/meta_modelica.h"
#include "util/modelica_string.h"

#include <limits.h>
#include <map>
#include "util/uthash.h"
#include <string>
#include <string.h>
#include <expat.h>

typedef struct hash_string_string
{
  const char *id;
  const char *val;
  UT_hash_handle hh;
} hash_string_string;

typedef hash_string_string omc_ModelDescription;
typedef hash_string_string omc_DefaultExperiment;
typedef hash_string_string omc_ScalarVariable;

typedef struct hash_long_var
{
  long id;
  omc_ScalarVariable *val;
  UT_hash_handle hh;
} hash_long_var;

typedef hash_long_var omc_ModelVariables;

extern "C" {

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
  hash_string_string *v = (hash_string_string*) malloc(sizeof(hash_string_string));
  v->id=strdup(key);
  v->val=strdup(val);
  HASH_ADD_KEYPTR( hh, *ht, key, strlen(key), v );
}

static inline omc_ScalarVariable** findHashLongVar(hash_long_var *ht, long key)
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

static inline void addHashLongVar(hash_long_var **ht, long key, omc_ScalarVariable *val)
{
  hash_long_var *v = (hash_long_var*) malloc(sizeof(hash_long_var));
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
typedef std::map<std::string, std::string> omc_CommandLineOverrides;
// a map to find out which names were used
#define OMC_OVERRIDE_UNUSED 0
#define OMC_OVERRIDE_USED   1
typedef std::map<std::string, mmc_sint_t> omc_CommandLineOverridesUses;

// function to handle command line settings override
void doOverride(omc_ModelInput& mi, MODEL_DATA* modelData, const char* override, const char* overrideFile);

static const double REAL_MIN = -DBL_MAX;
static const double REAL_MAX = DBL_MAX;
static const double INTEGER_MIN = (((modelica_integer)-1)<<(8*sizeof(modelica_integer)-1));
/* Avoid integer overflow */
static const double INTEGER_MAX = -((((modelica_integer)-1)<<(8*sizeof(modelica_integer)-1))+1);

/* reads double value from a string */
static void read_value_real(std::string s, modelica_real* res, modelica_real default_value);
/* reads integer value from a string */
static void read_value_long(std::string s, modelica_integer* res, modelica_integer default_value = 0);
/* reads integer value from a string */
static void read_value_int(std::string s, int* res);
/* reads modelica_string value from a string */
static void read_value_string(std::string s, const char** str);
static void read_value_mm(std::string s, modelica_metatype *str);
/* reads boolean value from a string */
static void read_value_bool(std::string s, modelica_boolean* str);

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

  /* handle ScalarVariable */
  if(!strcmp(name, "ScalarVariable"))
  {
    omc_ScalarVariable *v = NULL, *vfind;
    const char *ci, *ct;
    int fail=0;
    mi->lastCI = -1;
    mi->lastCT = NULL;
    for(i = 0; attr[i]; i += 2) {
      addHashStringString(&v, attr[i], attr[i+1]);
    }
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
      throwStreamPrint(NULL, "simulation_input_xml.cpp: error reading the xml file, found unknown class: %s  for variable: %s",ct,findHashStringString(v,"name"));
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
  /* anything else, we don't handle! */
}

static void XMLCALL endElement(void *userData, const char *name)
{
  /* do nothing! */
}

static void read_var_info(omc_ScalarVariable *v, VAR_INFO &info)
{
  read_value_string(findHashStringString(v,"name"), &info.name);
  debugStreamPrint(LOG_DEBUG, 1, "read var %s from setup file", info.name);

  read_value_int(findHashStringString(v,"valueReference"), &info.id);
  debugStreamPrint(LOG_DEBUG, 0, "read for %s id %d from setup file", info.name, info.id);
  read_value_string(findHashStringStringEmpty(v,"description"), &info.comment);
  debugStreamPrint(LOG_DEBUG, 0, "read for %s description \"%s\" from setup file", info.name, info.comment);
  read_value_string(findHashStringString(v,"fileName"), &info.info.filename);
  debugStreamPrint(LOG_DEBUG, 0, "read for %s filename %s from setup file", info.name, info.info.filename);
  read_value_long(findHashStringString(v,"startLine"), (modelica_integer*)&(info.info.lineStart));
  debugStreamPrint(LOG_DEBUG, 0, "read for %s lineStart %d from setup file", info.name, info.info.lineStart);
  read_value_long(findHashStringString(v,"startColumn"), (modelica_integer*)&(info.info.colStart));
  debugStreamPrint(LOG_DEBUG, 0, "read for %s colStart %d from setup file", info.name, info.info.colStart);
  read_value_long(findHashStringString(v,"endLine"), (modelica_integer*)&(info.info.lineEnd));
  debugStreamPrint(LOG_DEBUG, 0, "read for %s lineEnd %d from setup file", info.name, info.info.lineEnd);
  read_value_long(findHashStringString(v,"endColumn"), (modelica_integer*)&(info.info.colEnd));
  debugStreamPrint(LOG_DEBUG, 0, "read for %s colEnd %d from setup file", info.name, info.info.colEnd);
  read_value_long(findHashStringString(v,"fileWritable"), (modelica_integer*)&(info.info.readonly));
  debugStreamPrint(LOG_DEBUG, 0, "read for %s readonly %d from setup file", info.name, info.info.readonly);
  if (DEBUG_STREAM(LOG_DEBUG)) messageClose(LOG_DEBUG);
}

static void read_var_attribute_real(omc_ScalarVariable *v, REAL_ATTRIBUTE &attribute)
{
  read_value_bool(findHashStringString(v,"useStart"), (modelica_boolean*)&(attribute.useStart));
  read_value_real(findHashStringStringEmpty(v,"start"), &(attribute.start), 0.0);
  read_value_bool(findHashStringString(v,"fixed"), (modelica_boolean*)&(attribute.fixed));
  read_value_bool(findHashStringString(v,"useNominal"), (modelica_boolean*)&(attribute.useNominal));
  read_value_real(findHashStringStringEmpty(v,"nominal"), &(attribute.nominal), 1.0);
  read_value_real(findHashStringStringEmpty(v,"min"), &(attribute.min), REAL_MIN);
  read_value_real(findHashStringStringEmpty(v,"max"), &(attribute.max), REAL_MAX);

  infoStreamPrint(LOG_DEBUG, 0, "Real %s(%sstart=%g%s, fixed=%s, %snominal=%g%s, min=%g, max=%g)", findHashStringString(v,"name"), (attribute.useStart)?"":"{", attribute.start, (attribute.useStart)?"":"}", (attribute.fixed)?"true":"false", (attribute.useNominal)?"":"{", attribute.nominal, attribute.useNominal?"":"}", attribute.min, attribute.max);
}

static void read_var_attribute_int(omc_ScalarVariable *v, INTEGER_ATTRIBUTE &attribute)
{
  read_value_bool(findHashStringString(v,"useStart"), &attribute.useStart);
  read_value_long(findHashStringStringEmpty(v,"start"), &attribute.start, 0);
  read_value_bool(findHashStringString(v,"fixed"), &attribute.fixed);
  read_value_long(findHashStringStringEmpty(v,"min"), &attribute.min, INTEGER_MIN);
  read_value_long(findHashStringStringEmpty(v,"max"), &attribute.max, INTEGER_MAX);

  infoStreamPrint(LOG_DEBUG, 0, "Integer %s(%sstart=%ld%s, fixed=%s, min=%ld, max=%ld)", findHashStringString(v,"name"), attribute.useStart?"":"{", attribute.start, attribute.useStart?"":"}", attribute.fixed?"true":"false", attribute.min, attribute.max);
}

static void read_var_attribute_bool(omc_ScalarVariable *v, BOOLEAN_ATTRIBUTE &attribute)
{
  read_value_bool(findHashStringString(v,"useStart"), &attribute.useStart);
  read_value_bool(findHashStringStringEmpty(v,"start"), &attribute.start);
  read_value_bool(findHashStringString(v,"fixed"), &attribute.fixed);

  infoStreamPrint(LOG_DEBUG, 0, "Boolean %s(%sstart=%s%s, fixed=%s)", findHashStringString(v,"name"), attribute.useStart?"":"{", attribute.start?"true":"false", attribute.useStart?"":"}", attribute.fixed?"true":"false");
}

static void read_var_attribute_string(omc_ScalarVariable *v, STRING_ATTRIBUTE &attribute)
{
  read_value_bool(findHashStringString(v,"useStart"), &attribute.useStart);
  read_value_mm(findHashStringStringEmpty(v,"start"), &attribute.start);

  infoStreamPrint(LOG_DEBUG, 0, "String %s(%sstart=%s%s)", findHashStringString(v,"name"), attribute.useStart?"":"{", MMC_STRINGDATA(attribute.start), attribute.useStart?"":"}");
}

/* \brief
 *  Reads initial values from a text file.
 *
 *  The textfile should be given as argument to the main function using
 *  the -f file flag.
 */
void read_input_xml(MODEL_DATA* modelData,
    SIMULATION_INFO* simulationInfo)
{
  omc_ModelInput mi = {0};
  const char *filename;
  FILE* file = NULL;
  XML_Parser parser = NULL;
  std::map<std::string, mmc_sint_t> mapAlias, mapAliasParam;
  std::map<std::string, mmc_sint_t>::iterator it, itParam;

  if(NULL == modelData->initXMLData)
  {
    /* read the filename from the command line (if any) */
    if(omc_flag[FLAG_F]) {
      filename = omc_flagValue[FLAG_F];
    } else {
      /* no file given on the command line? use the default
       * model_name defined in generated code for model.*/
      if (0 > GC_asprintf((char**)&filename, "%s_init.xml", modelData->modelFilePrefix)) {
        throwStreamPrint(NULL, "simulation_input_xml.cpp: Error: can not allocate memory.");
      }
    }

    /* open the file and fail on error. we open it read-write to be sure other processes can overwrite it */
    file = fopen(filename, "r");
    if(!file) {
      throwStreamPrint(NULL, "simulation_input_xml.cpp: Error: can not read file %s as setup file to the generated simulation code.",filename);
    }
  }
  /* create the XML parser */
  parser = XML_ParserCreate(NULL);
  if(!parser)
  {
    fclose(file);
    throwStreamPrint(NULL, "simulation_input_xml.cpp: Error: couldn't allocate memory for the XML parser!");
  }
  /* set our user data */
  XML_SetUserData(parser, &mi);
  /* set the handlers for start/end of element. */
  XML_SetElementHandler(parser, startElement, endElement);
  if(NULL == modelData->initXMLData)
  {
    int done;
    char buf[BUFSIZ] = {0};
    do
    {
      size_t len = fread(buf, 1, sizeof(buf), file);
      done = len < sizeof(buf);
      if(XML_STATUS_ERROR == XML_Parse(parser, buf, len, done))
      {
        fclose(file);
        warningStreamPrint(LOG_STDOUT, 0, "simulation_input_xml.cpp: Error: failed to read the XML file %s: %s at line %lu\n",
            filename,
            XML_ErrorString(XML_GetErrorCode(parser)),
            XML_GetCurrentLineNumber(parser));
        XML_ParserFree(parser);
        throwStreamPrint(NULL, "see last warning");
      }
    }while(!done);
    fclose(file);
  }
  else if(XML_STATUS_ERROR == XML_Parse(parser, modelData->initXMLData, strlen(modelData->initXMLData), 1))
  { /* Got the full string already */
    fprintf(stderr, "%s, %s %lu\n", modelData->initXMLData, XML_ErrorString(XML_GetErrorCode(parser)), XML_GetCurrentLineNumber(parser));
    warningStreamPrint(LOG_STDOUT, 0, "simulation_input_xml.cpp: Error: failed to read the XML data %s: %s at line %lu\n",
             modelData->initXMLData,
             XML_ErrorString(XML_GetErrorCode(parser)),
             XML_GetCurrentLineNumber(parser));
    XML_ParserFree(parser);
    throwStreamPrint(NULL, "see last warning");
  }

  /* now we should have all the data inside omc_ModelInput mi. */

  /* first, check the modelGUID!
     TODO! FIXME! THIS SEEMS TO FAIL!
     ARE WE READING THE OLD XML FILE?? */
  const char *guid = findHashStringStringNull(mi.md,"guid");
  if (NULL==guid) {
     warningStreamPrint(LOG_STDOUT, 0, "The Model GUID: %s is not set in file: %s",
        modelData->modelGUID,
        filename);
  } else if (strcmp(modelData->modelGUID, guid)) {
    XML_ParserFree(parser);
    warningStreamPrint(LOG_STDOUT, 0, "Error, the GUID: %s from input data file: %s does not match the GUID compiled in the model: %s",
        guid,
        filename,
        modelData->modelGUID);
    throwStreamPrint(NULL, "see last warning");
  }

  // deal with override
  const char* override = omc_flagValue[FLAG_OVERRIDE];
  const char* overrideFile = omc_flagValue[FLAG_OVERRIDE_FILE];
  doOverride(mi, modelData, override, overrideFile);

  /* read all the DefaultExperiment values */
  infoStreamPrint(LOG_SIMULATION, 1, "read all the DefaultExperiment values:");

  read_value_real(findHashStringString(mi.de,"startTime"), &(simulationInfo->startTime), 0);
  infoStreamPrint(LOG_SIMULATION, 0, "startTime = %g", simulationInfo->startTime);

  read_value_real(findHashStringString(mi.de,"stopTime"), &(simulationInfo->stopTime), 1.0);
  infoStreamPrint(LOG_SIMULATION, 0, "stopTime = %g", simulationInfo->stopTime);

  read_value_real(findHashStringString(mi.de,"stepSize"), &(simulationInfo->stepSize), (simulationInfo->stopTime - simulationInfo->startTime) / 500);
  infoStreamPrint(LOG_SIMULATION, 0, "stepSize = %g", simulationInfo->stepSize);

  read_value_real(findHashStringString(mi.de,"tolerance"), &(simulationInfo->tolerance), 1e-5);
  infoStreamPrint(LOG_SIMULATION, 0, "tolerance = %g", simulationInfo->tolerance);

  read_value_mm(findHashStringString(mi.de,"solver"), &simulationInfo->solverMethod);
  infoStreamPrint(LOG_SIMULATION, 0, "solver method: %s", MMC_STRINGDATA(simulationInfo->solverMethod));

  read_value_mm(findHashStringString(mi.de,"outputFormat"), &(simulationInfo->outputFormat));
  infoStreamPrint(LOG_SIMULATION, 0, "output format: %s", MMC_STRINGDATA(simulationInfo->outputFormat));

  read_value_mm(findHashStringString(mi.de,"variableFilter"), &(simulationInfo->variableFilter));
  infoStreamPrint(LOG_SIMULATION, 0, "variable filter: %s", MMC_STRINGDATA(simulationInfo->variableFilter));

  read_value_string(findHashStringString(mi.md,"OPENMODELICAHOME"), &simulationInfo->OPENMODELICAHOME);
  infoStreamPrint(LOG_SIMULATION, 0, "OPENMODELICAHOME: %s", simulationInfo->OPENMODELICAHOME);
  messageClose(LOG_SIMULATION);

  modelica_integer nxchk, nychk, npchk;
  modelica_integer nyintchk, npintchk;
  modelica_integer nyboolchk, npboolchk;
  modelica_integer nystrchk, npstrchk;

  read_value_long(findHashStringString(mi.md,"numberOfContinuousStates"),          &nxchk);
  read_value_long(findHashStringString(mi.md,"numberOfRealAlgebraicVariables"),    &nychk);
  read_value_long(findHashStringString(mi.md,"numberOfRealParameters"),            &npchk);

  read_value_long(findHashStringString(mi.md,"numberOfIntegerParameters"),         &npintchk);
  read_value_long(findHashStringString(mi.md,"numberOfIntegerAlgebraicVariables"), &nyintchk);

  read_value_long(findHashStringString(mi.md,"numberOfBooleanParameters"),         &npboolchk);
  read_value_long(findHashStringString(mi.md,"numberOfBooleanAlgebraicVariables"), &nyboolchk);

  read_value_long(findHashStringString(mi.md,"numberOfStringParameters"),          &npstrchk);
  read_value_long(findHashStringString(mi.md,"numberOfStringAlgebraicVariables"),  &nystrchk);

  if(nxchk != modelData->nStates
    || nychk != modelData->nVariablesReal - 2*modelData->nStates
    || npchk != modelData->nParametersReal
    || npintchk != modelData->nParametersInteger
    || nyintchk != modelData->nVariablesInteger
    || npboolchk != modelData->nParametersBoolean
    || nyboolchk != modelData->nVariablesBoolean
    || npstrchk != modelData->nParametersString
    || nystrchk != modelData->nVariablesString)
  {
    if (ACTIVE_WARNING_STREAM(LOG_SIMULATION))
    {
      warningStreamPrint(LOG_SIMULATION, 1, "Error, input data file does not match model.");
      warningStreamPrint(LOG_SIMULATION, 0, "nx in setup file: %ld from model code: %d", nxchk, (int)modelData->nStates);
      warningStreamPrint(LOG_SIMULATION, 0, "ny in setup file: %ld from model code: %ld", nychk, modelData->nVariablesReal - 2*modelData->nStates);
      warningStreamPrint(LOG_SIMULATION, 0, "np in setup file: %ld from model code: %ld", npchk, modelData->nParametersReal);
      warningStreamPrint(LOG_SIMULATION, 0, "npint in setup file: %ld from model code: %ld", npintchk, modelData->nParametersInteger);
      warningStreamPrint(LOG_SIMULATION, 0, "nyint in setup file: %ld from model code: %ld", nyintchk, modelData->nVariablesInteger);
      warningStreamPrint(LOG_SIMULATION, 0, "npbool in setup file: %ld from model code: %ld", npboolchk, modelData->nParametersBoolean);
      warningStreamPrint(LOG_SIMULATION, 0, "nybool in setup file: %ld from model code: %ld", nyboolchk, modelData->nVariablesBoolean);
      warningStreamPrint(LOG_SIMULATION, 0, "npstr in setup file: %ld from model code: %ld", npstrchk, modelData->nParametersString);
      warningStreamPrint(LOG_SIMULATION, 0, "nystr in setup file: %ld from model code: %ld", nystrchk, modelData->nVariablesString);
      messageClose(LOG_SIMULATION);
    }
    XML_ParserFree(parser);
    EXIT(-1);
  }

  /* read all static data from File for every variable */

#define READ_VARIABLES(out,in,attributeKind,read_var_attribute,debugName,start,nStates,mapAlias) \
  infoStreamPrint(LOG_DEBUG, 1, "read xml file for %s", debugName); \
  for(mmc_sint_t i = 0; i < nStates; i++) \
  { \
    mmc_sint_t j = start+i; \
    VAR_INFO &info = out[j].info; \
    attributeKind &attribute = out[j].attribute; \
    omc_ScalarVariable *v = *findHashLongVar(in, i); \
    read_var_info(v, info); \
    read_var_attribute(v, attribute); \
    if (info.name[0] == '$') { \
      out[j].filterOutput = 1; \
    } else if (!omc_flag[FLAG_EMIT_PROTECTED] && 0 == strcmp(findHashStringString(v,"isProtected"),"true")) { \
      infoStreamPrint(LOG_DEBUG, 0, "filtering protected variable %s", info.name); \
      out[j].filterOutput = 1; \
    } \
    mapAlias[info.name] = j; /* create a mapping for Alias variable to get the correct index */ \
    debugStreamPrint(LOG_DEBUG, 0, "real %s: mapAlias[%s] = %ld", debugName, info.name, j); \
  } \
  messageClose(LOG_DEBUG);

  READ_VARIABLES(modelData->realVarsData,mi.rSta,REAL_ATTRIBUTE,read_var_attribute_real,"real states",0,modelData->nStates,mapAlias);
  READ_VARIABLES(modelData->realVarsData,mi.rDer,REAL_ATTRIBUTE,read_var_attribute_real,"real state derivatives",modelData->nStates,modelData->nStates,mapAlias);
  READ_VARIABLES(modelData->realVarsData,mi.rAlg,REAL_ATTRIBUTE,read_var_attribute_real,"real algebraics",2*modelData->nStates,modelData->nVariablesReal - 2*modelData->nStates,mapAlias);

  READ_VARIABLES(modelData->integerVarsData,mi.iAlg,INTEGER_ATTRIBUTE,read_var_attribute_int,"integer variables",0,modelData->nVariablesInteger,mapAlias);
  READ_VARIABLES(modelData->booleanVarsData,mi.bAlg,BOOLEAN_ATTRIBUTE,read_var_attribute_bool,"boolean variables",0,modelData->nVariablesBoolean,mapAlias);
  READ_VARIABLES(modelData->stringVarsData,mi.sAlg,STRING_ATTRIBUTE,read_var_attribute_string,"string variables",0,modelData->nVariablesString,mapAlias);

  READ_VARIABLES(modelData->realParameterData,mi.rPar,REAL_ATTRIBUTE,read_var_attribute_real,"real parameters",0,modelData->nParametersReal,mapAliasParam);
  READ_VARIABLES(modelData->integerParameterData,mi.iPar,INTEGER_ATTRIBUTE,read_var_attribute_int,"integer parameters",0,modelData->nParametersInteger,mapAliasParam);
  READ_VARIABLES(modelData->booleanParameterData,mi.bPar,BOOLEAN_ATTRIBUTE,read_var_attribute_bool,"boolean parameters",0,modelData->nParametersBoolean,mapAliasParam);
  READ_VARIABLES(modelData->stringParameterData,mi.sPar,STRING_ATTRIBUTE,read_var_attribute_string,"string parameters",0,modelData->nParametersString,mapAliasParam);

  /*
   * real all alias vars
   */
  infoStreamPrint(LOG_DEBUG, 1, "read xml file for real alias vars");
  for(mmc_sint_t i=0; i<modelData->nAliasReal; i++)
  {
    read_var_info(*findHashLongVar(mi.rAli,i), modelData->realAlias[i].info);

    const char *aliasTmp;
    read_value_string(findHashStringStringNull(*findHashLongVar(mi.rAli,i),"alias"), &aliasTmp);
    if (0 == strcmp(aliasTmp,"negatedAlias")) {
      modelData->realAlias[i].negate = 1;
    } else {
      modelData->realAlias[i].negate = 0;
    }
    infoStreamPrint(LOG_DEBUG, 0, "read for %s negated %d from setup file", modelData->realAlias[i].info.name, modelData->realAlias[i].negate);

    /* filter internal variables */
    if(modelData->realAlias[i].info.name[0] == '$') {
      modelData->realAlias[i].filterOutput = 1;
    }

    read_value_string(findHashStringStringNull(*findHashLongVar(mi.rAli,i),"aliasVariable"), &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if(it != mapAlias.end()) {
      modelData->realAlias[i].nameID  = (*it).second;
      modelData->realAlias[i].aliasType = 0;
    } else if (itParam != mapAliasParam.end()) {
      modelData->realAlias[i].nameID  = (*itParam).second;
      modelData->realAlias[i].aliasType = 1;
    } else if (0==strcmp(aliasTmp,"time")) {
      modelData->realAlias[i].aliasType = 2;
    } else {
      throwStreamPrint(NULL, "Real Alias variable %s not found.", aliasTmp);
    }
    debugStreamPrint(LOG_DEBUG, 0, "read for %s aliasID %d from %s from setup file",
                modelData->realAlias[i].info.name,
                modelData->realAlias[i].nameID,
                modelData->realAlias[i].aliasType ? ((modelData->realAlias[i].aliasType==2) ? "time" : "real parameters") : "real variables");
  }
  messageClose(LOG_DEBUG);

  /*
   * integer all alias vars
   */
  infoStreamPrint(LOG_DEBUG, 1, "read xml file for integer alias vars");
  for(mmc_sint_t i=0; i<modelData->nAliasInteger; i++)
  {
    read_var_info(*findHashLongVar(mi.iAli,i), modelData->integerAlias[i].info);

    const char *aliasTmp;
    read_value_string(findHashStringStringNull(*findHashLongVar(mi.iAli,i),"alias"), &aliasTmp);
    if (0 == strcmp(aliasTmp,"negatedAlias")) {
      modelData->integerAlias[i].negate = 1;
    } else {
      modelData->integerAlias[i].negate = 0;
    }

    infoStreamPrint(LOG_DEBUG, 0, "read for %s negated %d from setup file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].negate);

    /* filter internal variables */
    if(modelData->integerAlias[i].info.name[0] == '$') {
      modelData->integerAlias[i].filterOutput = 1;
    }
    read_value_string(findHashStringString(*findHashLongVar(mi.iAli,i),"aliasVariable"), &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if(it != mapAlias.end()) {
      modelData->integerAlias[i].nameID  = (*it).second;
      modelData->integerAlias[i].aliasType = 0;
    } else if(itParam != mapAliasParam.end()) {
      modelData->integerAlias[i].nameID  = (*itParam).second;
      modelData->integerAlias[i].aliasType = 1;
    } else {
      throwStreamPrint(NULL, "Integer Alias variable %s not found.", aliasTmp);
    }
    debugStreamPrint(LOG_DEBUG, 0, "read for %s aliasID %d from %s from setup file",
                modelData->integerAlias[i].info.name,
                modelData->integerAlias[i].nameID,
                modelData->integerAlias[i].aliasType?"integer parameters":"integer variables");
  }
  messageClose(LOG_DEBUG);

  /*
   * boolean all alias vars
   */
  infoStreamPrint(LOG_DEBUG, 1, "read xml file for boolean alias vars");
  for(mmc_sint_t i=0; i<modelData->nAliasBoolean; i++)
  {
    read_var_info(*findHashLongVar(mi.bAli,i), modelData->booleanAlias[i].info);

    const char *aliasTmp;
    read_value_string(findHashStringString(*findHashLongVar(mi.bAli,i),"alias"), &aliasTmp);
    if  (0 == strcmp(aliasTmp,"negatedAlias")) {
      modelData->booleanAlias[i].negate = 1;
    } else {
      modelData->booleanAlias[i].negate = 0;
    }

    infoStreamPrint(LOG_DEBUG, 0, "read for %s negated %d from setup file", modelData->booleanAlias[i].info.name, modelData->booleanAlias[i].negate);

    /* filter internal variables */
    if(modelData->booleanAlias[i].info.name[0] == '$') {
      modelData->booleanAlias[i].filterOutput = 1;
    }
    read_value_string(findHashStringString(*findHashLongVar(mi.bAli,i),"aliasVariable"), &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if (it != mapAlias.end()) {
      modelData->booleanAlias[i].nameID  = (*it).second;
      modelData->booleanAlias[i].aliasType = 0;
    } else if(itParam != mapAliasParam.end()) {
      modelData->booleanAlias[i].nameID  = (*itParam).second;
      modelData->booleanAlias[i].aliasType = 1;
    } else {
      throwStreamPrint(NULL, "Boolean Alias variable %s not found.", aliasTmp);
    }
    debugStreamPrint(LOG_DEBUG, 0, "read for %s aliasID %d from %s from setup file",
                modelData->booleanAlias[i].info.name,
                modelData->booleanAlias[i].nameID,
                modelData->booleanAlias[i].aliasType ? "boolean parameters" : "boolean variables");
  }
  messageClose(LOG_DEBUG);

  /*
   * string all alias vars
   */
  infoStreamPrint(LOG_DEBUG, 1, "read xml file for string alias vars");
  for(mmc_sint_t i=0; i<modelData->nAliasString; i++)
  {
    read_var_info(*findHashLongVar(mi.sAli,i), modelData->stringAlias[i].info);

    const char *aliasTmp;
    read_value_string(findHashStringString(*findHashLongVar(mi.sAli,i),"alias"), &aliasTmp);
    if (0 == strcmp(aliasTmp,"negatedAlias")) {
      modelData->stringAlias[i].negate = 1;
    } else {
      modelData->stringAlias[i].negate = 0;
    }
    infoStreamPrint(LOG_DEBUG, 0, "read for %s negated %d from setup file", modelData->stringAlias[i].info.name, modelData->stringAlias[i].negate);

    /* filter internal variables */
    if(modelData->stringAlias[i].info.name[0] == '$') {
      modelData->stringAlias[i].filterOutput = 1;
    }

    read_value_string(findHashStringString(*findHashLongVar(mi.sAli,i),"aliasVariable"), &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if(it != mapAlias.end()) {
      modelData->stringAlias[i].nameID  = (*it).second;
      modelData->stringAlias[i].aliasType = 0;
    } else if(itParam != mapAliasParam.end()) {
      modelData->stringAlias[i].nameID  = (*itParam).second;
      modelData->stringAlias[i].aliasType = 1;
    } else {
      throwStreamPrint(NULL, "String Alias variable %s not found.", aliasTmp);
    }
    debugStreamPrint(LOG_DEBUG, 0, "read for %s aliasID %d from %s from setup file",
                modelData->stringAlias[i].info.name,
                modelData->stringAlias[i].nameID,
                modelData->stringAlias[i].aliasType ? "string parameters" : "string variables");
  }
  messageClose(LOG_DEBUG);

  XML_ParserFree(parser);
}

/* reads modelica_string value from a string */
static inline void read_value_string(std::string s, const char **str)
{
  if(str == NULL)
  {
    warningStreamPrint(LOG_SIMULATION, 0, "error read_value, no data allocated for storing string");
    return;
  }
  *str = strdup(s.c_str());
}

static inline void read_value_mm(std::string s, modelica_string *str)
{
  if(str == NULL) {
    warningStreamPrint(LOG_SIMULATION, 0, "error read_value, no data allocated for storing string");
    return;
  }
  *str = mmc_mk_scon(s.c_str());
}

/* reads double value from a string */
static inline void read_value_real(std::string s, modelica_real* res, modelica_real default_value)
{
  if(s.compare("") == 0) {
    *res = default_value;
  } else if(s.compare("true") == 0) {
    *res = 1.0;
  } else if(s.compare("false") == 0) {
    *res = 0.0;
  } else {
    *res = atof(s.c_str());
  }
}

/* reads boolean value from a string */
static inline void read_value_bool(std::string s, modelica_boolean* res)
{
  if(s.compare("true") == 0)
    *res = 1;
#if 0
// no need to call compare when result is same as in else
  else if(s.compare("false") == 0)
    *res = 0;
#endif
  else
    *res = 0;
}

/* reads integer value from a string */
static inline void read_value_long(std::string s, modelica_integer* res, modelica_integer default_value)
{
  if(s.compare("") == 0) {
    *res = default_value;
  } if(s.compare("true") == 0) {
    *res = 1;
  } else if(s.compare("false") == 0) {
    *res = 0;
  } else {
    *res = atol(s.c_str());
  }
}

/* reads int value from a string */
static inline void read_value_int(std::string s, int* res)
{
  if(s.compare("true") == 0)
    *res = 1;
  else if(s.compare("false") == 0)
    *res = 0;
  else
    *res = atoi(s.c_str());
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

static const char* getOverrideValue(omc_CommandLineOverrides& mOverrides, omc_CommandLineOverridesUses& mOverridesUses, const char *name)
{
    mOverridesUses[name] = OMC_OVERRIDE_USED;
    return mOverrides[name].c_str();
}

void doOverride(omc_ModelInput& mi, MODEL_DATA* modelData, const char* override, const char* overrideFile)
{
  omc_CommandLineOverrides mOverrides;
  omc_CommandLineOverridesUses mOverridesUses;
  char* overrideStr = NULL;
  if((override != NULL) && (overrideFile != NULL))
  {
    throwStreamPrint(NULL, "simulation_input_xml.cpp: usage error you cannot have both -override and -overrideFile active at the same time. see Model -? for more info!");
  }

  if(override != NULL) {
    overrideStr = strdup(override);
  }

  if(overrideFile != NULL) {
    /* read override values from file */
    infoStreamPrint(LOG_SOLVER, 0, "read override values from file: %s", overrideFile);
    FILE *infile = fopen(overrideFile, "r");
    char *line=NULL, *tline=NULL, *tline2=NULL;
    char *overrideLine;
    size_t n=0;

    if (0==infile) {
      throwStreamPrint(NULL, "simulation_input_xml.cpp: could not open the file given to -overrideFile=%s", overrideFile);
    }

    free(overrideStr);
    fseek(infile, 0L, SEEK_END);
    n = ftell(infile);
    line = (char*) malloc(n+1);
    line[0] = '\0';
    fseek(infile, 0L, SEEK_SET);
    errno = 0;
    if (1 != fread(line, n, 1, infile)) {
      free(line);
      throwStreamPrint(NULL, "simulation_input_xml.cpp: could not read overrideFile %s: %s", overrideFile, strerror(errno));
    }
    line[n] = '\0';
    overrideLine = (char*) malloc(n+1);
    overrideLine[0] = '\0';
    overrideStr = overrideLine;
    tline = line;

    /* get the lines */
    while (0 != (tline2=strchr(tline,'\n'))) {
      *tline2 = '\0';

      tline = trim(tline);
      // if is comment //, ignore line
      if (tline[0] && tline[0] != '/' && tline[1] != '/') {
        if (overrideLine != overrideStr) {
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

  if (overrideStr != NULL) {
    std::string key, value;
    /* read override values */
    infoStreamPrint(LOG_SOLVER, 0, "read override values: %s", overrideStr);
    /* fix overrideStr to contain | instead of , for splitting */
    parseVariableStr(overrideStr);
    char *p = strtok(overrideStr, "!");

    while(p) {
      std::string key_val(p);

      // split it key = value => map[key]=value
      size_t pos = key_val.find("=");
      key = key_val.substr(0,pos);
      value = key_val.substr(pos + 1,key_val.length() - pos - 1);

      /* un-quote key and value
      if(key[0] == '"')
       key = key.substr(1,key.length() - 1);
      if(key[key.length()] == '"')
       key = key.substr(0,key.length() - 1);
      if(value[0] == '"')
       value = value.substr(1,value.length() - 1);
      if(value[value.length()] == '"')
       value = value.substr(0,value.length() - 1);
      */

      // map[key]=value
      mOverrides[key] = value;
      mOverridesUses[key] = OMC_OVERRIDE_UNUSED;

      infoStreamPrint(LOG_SOLVER, 0, "override %s = %s", key.c_str(), value.c_str());

      // move to next
      p = strtok(NULL, "!");
    }

    free(overrideStr);


    // now we have all overrides in mOverrides, override mi now
    const char *strs[] = {"solver","startTime","stopTime","stepSize","tolerance","outputFormat","variableFilter"};
    for (int i=0; i<sizeof(strs)/sizeof(char*); i++) {
      if (mOverrides.count(strs[i])) {
        addHashStringString(&mi.de, strs[i], getOverrideValue(mOverrides, mOverridesUses, strs[i]));
      }
    }

    #define CHECK_OVERRIDE(v) \
      if (mOverrides.count(findHashStringString(*findHashLongVar(mi.v,i),"name"))) { \
        addHashStringString(findHashLongVar(mi.v,i), "start", getOverrideValue(mOverrides, mOverridesUses, findHashStringString(*findHashLongVar(mi.v,i),"name"))); \
      }

    // override all found!
    for(mmc_sint_t i=0; i<modelData->nStates; i++) {
      CHECK_OVERRIDE(rSta);
      CHECK_OVERRIDE(rDer);
    }
    for(mmc_sint_t i=0; i<(modelData->nVariablesReal - 2*modelData->nStates); i++) {
      CHECK_OVERRIDE(rAlg);
    }
    for(mmc_sint_t i=0; i<modelData->nVariablesInteger; i++) {
      CHECK_OVERRIDE(iAlg);
    }
    for(mmc_sint_t i=0; i<modelData->nVariablesBoolean; i++) {
      CHECK_OVERRIDE(bAlg);
    }
    for(mmc_sint_t i=0; i<modelData->nVariablesString; i++) {
      CHECK_OVERRIDE(sAlg);
    }
    for(mmc_sint_t i=0; i<modelData->nParametersReal; i++) {
      // TODO: only allow to override primary parameters
      CHECK_OVERRIDE(rPar);
    }
    for(mmc_sint_t i=0; i<modelData->nParametersInteger; i++) {
      // TODO: only allow to override primary parameters
      CHECK_OVERRIDE(iPar);
    }
    for(mmc_sint_t i=0; i<modelData->nParametersBoolean; i++) {
      // TODO: only allow to override primary parameters
      CHECK_OVERRIDE(bPar);
    }
    for(mmc_sint_t i=0; i<modelData->nParametersString; i++) {
      // TODO: only allow to override primary parameters
      CHECK_OVERRIDE(sPar);
    }
    for(mmc_sint_t i=0; i<modelData->nAliasReal; i++) {
      CHECK_OVERRIDE(rAli);
    }
    for(mmc_sint_t i=0; i<modelData->nAliasInteger; i++) {
      CHECK_OVERRIDE(iAli);
    }
    for(mmc_sint_t i=0; i<modelData->nAliasBoolean; i++) {
      CHECK_OVERRIDE(bAli);
    }
    for(mmc_sint_t i=0; i<modelData->nAliasString; i++) {
      CHECK_OVERRIDE(sAli);
    }

    // give a warning if an override is not used #3204
    for (std::map<std::string, mmc_sint_t>::iterator it = mOverridesUses.begin(); it != mOverridesUses.end(); ++it) {
      if (it->second == OMC_OVERRIDE_UNUSED) {
         warningStreamPrint(LOG_STDOUT, 0, "simulation_input_xml.cpp: override variable name not found in model: %s\n", it->first.c_str());
      }
    }

    infoStreamPrint(LOG_SOLVER, 0, "override done!");
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "NO override given on the command line.");
  }
}

}
