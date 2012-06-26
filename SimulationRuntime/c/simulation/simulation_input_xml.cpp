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
 * RCS: $Id: SimCode.mo 9167 2011-05-29 12:58:33Z Frenkel TUD $
 *
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
#include "omc_error.h"

#include <fstream>
#include <iomanip>
#include <map>
#include <list>
#include <string.h>
#include <expat.h>

typedef std::map<std::string, std::string> omc_ModelDescription;
typedef std::map<std::string, std::string> omc_DefaultExperiment;
typedef std::map<std::string, std::string> omc_ScalarVariable;
typedef std::map<int, omc_ScalarVariable>  omc_ModelVariables;

/* maybe use a map below {"rSta"  -> omc_ModelVariables} */
/* typedef map < string, omc_ModelVariables > omc_ModelVariablesClassified; */

/* structure used to collect data from the xml input file */
typedef struct omc_ModelInput
{
  omc_ModelDescription  md; /* model description */
  omc_DefaultExperiment de; /* default experiment */

  omc_ModelVariables    rSta; /* states */
  omc_ModelVariables    rDer; /* derivatives */
  omc_ModelVariables    rAlg; /* algebraic */
  omc_ModelVariables    rPar; /* parameters */
  omc_ModelVariables    rAli; /* aliases */

  omc_ModelVariables    iAlg; /* int algebraic */
  omc_ModelVariables    iPar; /* int parameters */
  omc_ModelVariables    iAli; /* int aliases */

  omc_ModelVariables    bAlg; /* bool algebraic */
  omc_ModelVariables    bPar; /* bool parameters */
  omc_ModelVariables    bAli; /* bool aliases */

  omc_ModelVariables    sAlg; /* string algebraic */
  omc_ModelVariables    sPar; /* string parameters */
  omc_ModelVariables    sAli; /* string aliases */

  /* these two we need to know to be able to add
     the stuff in <Real ... />, <String ... /> to
     the correct variable in the correct map */
  int                   lastCI; /* index */ 
  omc_ModelVariables*   lastCT; /* type (classification) */
} omc_ModelInput;

// a map for overrides
typedef std::map<std::string, std::string> omc_CommandLineOverrides;
// function to handle command line settings override
omc_ModelInput doOverride(omc_ModelInput mi, MODEL_DATA* modelData, std::string* override);

/* reads double value from a string */
void read_value(std::string s, modelica_real* res);
/* reads integer value from a string */
void read_value(std::string s, modelica_integer* res);
/* reads integer value from a string */
void read_value(std::string s, int* res);
/* reads std::string value from a string */
void read_value(std::string s, std::string* str);
/* reads modelica_string value from a string */
void read_value(std::string s, modelica_string* str);
/* reads boolean value from a string */
void read_value(std::string s, modelica_boolean* str);

static void XMLCALL startElement(void *userData, const char *name, const char **attr)
{
  omc_ModelInput* mi = (omc_ModelInput*)userData;
  int i = 0;

  /* handle fmiModelDescription */
  if(!strcmp(name, "fmiModelDescription"))
  {
    for(i = 0; attr[i]; i += 2)
    {
      mi->md[attr[i]] = attr[i + 1];
    }
    return;
  }
  /* handle DefaultExperiment */
  if(!strcmp(name, "DefaultExperiment"))
  {
    for (i = 0; attr[i]; i += 2)
    {
      mi->de[attr[i]] = attr[i + 1];
    }
    return;
  }

  /* handle ScalarVariable */
  if(!strcmp(name, "ScalarVariable"))
  {
    omc_ScalarVariable v;
    string ci, ct;
    mi->lastCI = -1;
    mi->lastCT = NULL;
    for(i = 0; attr[i]; i += 2)
    {
      v[attr[i]] = attr[i + 1];
    }
    /* fetch the class index/type  */
    ci = v["classIndex"];
    ct = v["classType"];
    /* transform to int  */
    mi->lastCI = atoi(ci.c_str());

    /* which one of the classifications?  */
    mi->lastCT = ct.compare("rSta") ? mi->lastCT : &mi->rSta;
    mi->lastCT = ct.compare("rDer") ? mi->lastCT : &mi->rDer;
    mi->lastCT = ct.compare("rAlg") ? mi->lastCT : &mi->rAlg;
    mi->lastCT = ct.compare("rPar") ? mi->lastCT : &mi->rPar;
    mi->lastCT = ct.compare("rAli") ? mi->lastCT : &mi->rAli;

    mi->lastCT = ct.compare("iAlg") ? mi->lastCT : &mi->iAlg;
    mi->lastCT = ct.compare("iPar") ? mi->lastCT : &mi->iPar;
    mi->lastCT = ct.compare("iAli") ? mi->lastCT : &mi->iAli;

    mi->lastCT = ct.compare("bAlg") ? mi->lastCT : &mi->bAlg;
    mi->lastCT = ct.compare("bPar") ? mi->lastCT : &mi->bPar;
    mi->lastCT = ct.compare("bAli") ? mi->lastCT : &mi->bAli;

    mi->lastCT = ct.compare("sAlg") ? mi->lastCT : &mi->sAlg;
    mi->lastCT = ct.compare("sPar") ? mi->lastCT : &mi->sPar;
    mi->lastCT = ct.compare("sAli") ? mi->lastCT : &mi->sAli;

    if(mi->lastCT == NULL)
    {
      THROW2("simulation_input_xml.cpp: error reading the xml file, found unknown class: %s  for variable: %s",ct.c_str(),(v["name"]).c_str());
    }

    /* add the ScalarVariable map to the correct map! */
    (*mi->lastCT)[mi->lastCI] = v;
    return;
  }
  /* handle Real/Integer/Boolean/String */
  if(!strcmp(name, "Real") || !strcmp(name, "Integer") || !strcmp(name, "Boolean") || !strcmp(name, "String"))
  {
    /* add keys/value to the last variable */
    for(i = 0; attr[i]; i += 2)
    {
      /* add more key/value pairs to the last variable */
      ((*mi->lastCT)[mi->lastCI])[attr[i]] = attr[i + 1];
    }
    ((*mi->lastCT)[mi->lastCI])["variableType"] = name;
    return;
  }
  /* anything else, we don't handle! */
}

static void XMLCALL endElement(void *userData, const char *name)
{
  /* do nothing! */
}

/* \brief
 *  Reads initial values from a text file.
 *
 *  The textfile should be given as argument to the main function using
 *  the -f file flag.
 */
void read_input_xml(int argc, char **argv,
    MODEL_DATA* modelData,
    SIMULATION_INFO* simulationInfo,
    double *start, double *stop,
    double *stepSize, long *outputSteps,
    double *tolerance, string* method,
    string* outputFormat, string* variableFilter)
{
  omc_ModelInput mi;
  char buf[BUFSIZ] = {0};
  std::string *filename = NULL;
  FILE* file = NULL;
  XML_Parser parser = NULL;
  int done = 0;
  std::map<std::string, modelica_integer> mapAlias, mapAliasParam;
  std::map<std::string, modelica_integer>::iterator it, itParam;

  /* read the filename from the command line (if any) */
  filename = (std::string*)getFlagValue("f",argc,argv);
  /* no file given on the command line? use the default */
  if(filename == NULL)
    filename = new string(string(modelData->modelFilePrefix)+"_init.xml");  /* model_name defined in generated code for model.*/

  /* open the file and fail on error. we open it read-write to be sure other processes can overwrite it */
  file = fopen(filename->c_str(), "r");
  if(!file)
  {
    THROW1("simulation_input_xml.cpp: Error: can not read file %s as setup file to the generated simulation code.",filename->c_str());
    /* if(filename) delete filename; */
  }
  /* create the XML parser */
  parser = XML_ParserCreate(NULL);
  if(!parser)
  {
    if(filename) delete filename;
    fclose(file);
    THROW("simulation_input_xml.cpp: Error: couldn't allocate memory for the XML parser!");
  }
  /* set our user data */
  XML_SetUserData(parser, &mi);
  /* set the handlers for start/end of element. */
  XML_SetElementHandler(parser, startElement, endElement);
  do
  {
    size_t len = fread(buf, 1, sizeof(buf), file);
    done = len < sizeof(buf);
    if(XML_Parse(parser, buf, len, done) == XML_STATUS_ERROR)
    {
      fclose(file);
      WARNING3("simulation_input_xml.cpp: Error: failed to read the XML file %s: %s at line %lu\n",
          filename->c_str(),
          XML_ErrorString(XML_GetErrorCode(parser)),
          XML_GetCurrentLineNumber(parser));
      delete filename;
      XML_ParserFree(parser);
      THROW("see last warning");
    }
  }while(!done);

  /* now we should have all the data inside omc_ModelInput mi. */

  /* first, check the modelGUID!
     TODO! FIXME! THIS SEEMS TO FAIL!
     ARE WE READING THE OLD XML FILE?? */
  if(strcmp(modelData->modelGUID, mi.md["guid"].c_str()))
  {
    XML_ParserFree(parser);
    fclose(file);
    WARNING3("Error, the GUID: %s from input data file: %s does not match the GUID compiled in the model: %s",
        mi.md["guid"].c_str(),
        filename->c_str(),
        modelData->modelGUID);
    delete filename;
    THROW("see last warning");
  }

  std::string* methodc = (string*)getFlagValue("m", argc, argv);
  if (!methodc)
  {
    methodc = (string*)getFlagValue("s", argc, argv);
  }

  // deal with override
  std::string* override = (string*)getFlagValue("override", argc, argv);
  mi = doOverride(mi, modelData, override);

  /* read all the DefaultExperiment values */
  DEBUG_INFO(LOG_SOLVER, "read all the DefaultExperiment values:");
  read_value(mi.de["startTime"],start);
  simulationInfo->startTime = *start;
  DEBUG_INFO_AL1(LOG_SOLVER, "| startTime = %g", *start);
  read_value(mi.de["stopTime"],stop);
  simulationInfo->stopTime = *stop;
  DEBUG_INFO_AL1(LOG_SOLVER, "| stopTime = %g", *stop);
  read_value(mi.de["stepSize"],stepSize);
  simulationInfo->stepSize = *stepSize;
  DEBUG_INFO_AL1(LOG_SOLVER, "| stepSize = %g", *stepSize);
  read_value(mi.de["tolerance"],tolerance);
  simulationInfo->tolerance = *tolerance;
  DEBUG_INFO_AL1(LOG_SOLVER, "| tolerance = %g", *tolerance);

  if(methodc == NULL)
  {
    read_value(mi.de["solver"], method);
    simulationInfo->solverMethod = method->c_str();
    DEBUG_INFO_AL1(LOG_SOLVER, "| solver method: %s", method->c_str());
  }
  else
  {
    string tmp;
    read_value(mi.de["solver"],&tmp);
    simulationInfo->solverMethod = methodc->c_str();
    DEBUG_INFO_AL1(LOG_SOLVER, "| solver method: %s [from command line]", methodc->c_str());
  }

  read_value(mi.de["outputFormat"],outputFormat);
  simulationInfo->outputFormat = outputFormat->c_str();
  DEBUG_INFO_AL1(LOG_SOLVER, "| output format: %s", outputFormat->c_str());

  read_value(mi.de["variableFilter"], variableFilter);
  simulationInfo->variableFilter = variableFilter->c_str();
  DEBUG_INFO_AL1(LOG_SOLVER, "| variable filter: %s", variableFilter->c_str());

  modelica_integer nxchk, nychk, npchk;
  modelica_integer nyintchk, npintchk;
  modelica_integer nyboolchk, npboolchk;
  modelica_integer nystrchk, npstrchk;

  read_value(mi.md["numberOfContinuousStates"],          &nxchk);
  read_value(mi.md["numberOfRealAlgebraicVariables"],    &nychk);
  read_value(mi.md["numberOfRealParameters"],            &npchk);

  read_value(mi.md["numberOfIntegerParameters"],         &npintchk);
  read_value(mi.md["numberOfIntegerAlgebraicVariables"], &nyintchk);

  read_value(mi.md["numberOfBooleanParameters"],         &npboolchk);
  read_value(mi.md["numberOfBooleanAlgebraicVariables"], &nyboolchk);

  read_value(mi.md["numberOfStringParameters"],          &npstrchk);
  read_value(mi.md["numberOfStringAlgebraicVariables"],  &nystrchk);

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
    WARNING("Error, input data file does not match model.");
    WARNING_AL2("| nx in setup file: %ld from model code: %ld", nxchk, modelData->nStates);
    WARNING_AL2("| ny in setup file: %ld from model code: %ld", nychk, modelData->nVariablesReal - 2*modelData->nStates);
    WARNING_AL2("| np in setup file: %ld from model code: %ld", npchk, modelData->nParametersReal);
    WARNING_AL2("| npint in setup file: %ld from model code: %ld", npintchk, modelData->nParametersInteger);
    WARNING_AL2("| nyint in setup file: %ld from model code: %ld", nyintchk, modelData->nVariablesInteger);
    WARNING_AL2("| npbool in setup file: %ld from model code: %ld", npboolchk, modelData->nParametersBoolean);
    WARNING_AL2("| nybool in setup file: %ld from model code: %ld", nyboolchk, modelData->nVariablesBoolean);
    WARNING_AL2("| npstr in setup file: %ld from model code: %ld", npstrchk, modelData->nParametersString);
    WARNING_AL2("| nystr in setup file: %ld from model code: %ld", nystrchk, modelData->nVariablesString);
    delete filename;
    XML_ParserFree(parser);
    fclose(file);
    EXIT(-1);
  }

  /* Read all static data from File for every variable */
  /* Read states static data */
  DEBUG_INFO((LOG_SOLVER|LOG_DEBUG), "read xml file for states:");
  for(int i=0; i<modelData->nStates; i++)
  {
    /* read var info */
    read_value(mi.rSta[i]["name"], &(modelData->realVarsData[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file", modelData->realVarsData[i].info.name);
    read_value(mi.rSta[i]["valueReference"], &(modelData->realVarsData[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].info.id);
    read_value(mi.rSta[i]["description"], &(modelData->realVarsData[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s description \"%s\" from setup file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].info.comment);
    read_value(mi.rSta[i]["fileName"], (modelica_string*)&(modelData->realVarsData[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].info.info.filename);
    read_value(mi.rSta[i]["startLine"], (modelica_integer*)&(modelData->realVarsData[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].info.info.lineStart);
    read_value(mi.rSta[i]["startColumn"], (modelica_integer*)&(modelData->realVarsData[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].info.info.colStart);
    read_value(mi.rSta[i]["endLine"], (modelica_integer*)&(modelData->realVarsData[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].info.info.lineEnd);
    read_value(mi.rSta[i]["endColumn"], (modelica_integer*)&(modelData->realVarsData[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].info.info.colEnd);
    read_value(mi.rSta[i]["fileWritable"], (modelica_integer*)&(modelData->realVarsData[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.rSta[i]["useStart"], (modelica_boolean*)&(modelData->realVarsData[i].attribute.useStart));
    read_value(mi.rSta[i]["start"], &(modelData->realVarsData[i].attribute.start));
    read_value(mi.rSta[i]["fixed"], (modelica_boolean*)&(modelData->realVarsData[i].attribute.fixed));
    read_value(mi.rSta[i]["useNominal"], (modelica_boolean*)&(modelData->realVarsData[i].attribute.useNominal));
    read_value(mi.rSta[i]["nominal"], &(modelData->realVarsData[i].attribute.nominal));
    read_value(mi.rSta[i]["min"], &(modelData->realVarsData[i].attribute.min));
    read_value(mi.rSta[i]["max"], &(modelData->realVarsData[i].attribute.max));

    DEBUG_INFO_AL10(LOG_SOLVER, "| Real %s(%sstart=%g%s, fixed=%s, %snominal=%g%s, min=%g, max=%g)", modelData->realVarsData[i].info.name, (modelData->realVarsData[i].attribute.useStart)?"":"{", modelData->realVarsData[i].attribute.start, (modelData->realVarsData[i].attribute.useStart)?"":"}", (modelData->realVarsData[i].attribute.fixed)?"true":"false", (modelData->realVarsData[i].attribute.useNominal)?"":"{", modelData->realVarsData[i].attribute.nominal, (modelData->realVarsData[i].attribute.useNominal)?"":"}", modelData->realVarsData[i].attribute.min, modelData->realVarsData[i].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->realVarsData[i].info.name)] = i;
  }

  /* Read stateDerivatives static data */
  DEBUG_INFO((LOG_SOLVER|LOG_DEBUG), "read xml file for stateDerivatives:");
  for(int i=0; i<modelData->nStates; i++)
  {
    /* read var info */
    read_value(mi.rDer[i]["name"], &(modelData->realVarsData[modelData->nStates + i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->realVarsData[modelData->nStates+i].info.name);
    read_value(mi.rDer[i]["valueReference"], &(modelData->realVarsData[modelData->nStates+i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.id);
    read_value(mi.rDer[i]["description"], &(modelData->realVarsData[modelData->nStates+i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.comment);
    read_value(mi.rDer[i]["fileName"], (modelica_string*)&(modelData->realVarsData[modelData->nStates+i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.filename);
    read_value(mi.rDer[i]["startLine"], (modelica_integer*) &(modelData->realVarsData[modelData->nStates+i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.lineStart);
    read_value(mi.rDer[i]["startColumn"], (modelica_integer*) &(modelData->realVarsData[modelData->nStates+i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.colStart);
    read_value(mi.rDer[i]["endLine"], (modelica_integer*) &(modelData->realVarsData[modelData->nStates+i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.lineEnd);
    read_value(mi.rDer[i]["endColumn"], (modelica_integer*) &(modelData->realVarsData[modelData->nStates+i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.colEnd);
    read_value(mi.rDer[i]["fileWritable"], (modelica_integer*) &(modelData->realVarsData[modelData->nStates+i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.readonly);

    /* read var attribute */
    read_value(mi.rDer[i]["useStart"], (modelica_boolean*)&(modelData->realVarsData[modelData->nStates+i].attribute.useStart));
    read_value(mi.rDer[i]["start"], &(modelData->realVarsData[modelData->nStates+i].attribute.start));
    read_value(mi.rDer[i]["fixed"], (modelica_boolean*)&(modelData->realVarsData[modelData->nStates+i].attribute.fixed));
    read_value(mi.rDer[i]["useNominal"], (modelica_boolean*)&(modelData->realVarsData[modelData->nStates+i].attribute.useNominal));
    read_value(mi.rDer[i]["nominal"], &(modelData->realVarsData[modelData->nStates+i].attribute.nominal));
    read_value(mi.rDer[i]["min"], &(modelData->realVarsData[modelData->nStates+i].attribute.min));
    read_value(mi.rDer[i]["max"], &(modelData->realVarsData[modelData->nStates+i].attribute.max));

    DEBUG_INFO_AL10(LOG_SOLVER, "| Real %s(%sstart=%g%s, fixed=%s, %snominal=%g%s, min=%g, max=%g)", modelData->realVarsData[modelData->nStates+i].info.name, (modelData->realVarsData[modelData->nStates+i].attribute.useStart)?"":"{", modelData->realVarsData[modelData->nStates+i].attribute.start, (modelData->realVarsData[modelData->nStates+i].attribute.useStart)?"":"}", (modelData->realVarsData[modelData->nStates+i].attribute.fixed)?"true":"false", (modelData->realVarsData[modelData->nStates+i].attribute.useNominal)?"":"{", modelData->realVarsData[modelData->nStates+i].attribute.nominal, (modelData->realVarsData[modelData->nStates+i].attribute.useNominal)?"":"}", modelData->realVarsData[modelData->nStates+i].attribute.min, modelData->realVarsData[modelData->nStates+i].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->realVarsData[modelData->nStates+i].info.name)]= modelData->nStates+i;
  }

  /* Read real algebraics static data */
  DEBUG_INFO((LOG_SOLVER|LOG_DEBUG), "read xml file for real algebraic:");
  for(int i=0; i<(modelData->nVariablesReal - 2*modelData->nStates); i++)
  {
    int j = 2*modelData->nStates + i;

    /* read var info */
    read_value(mi.rAlg[i]["name"], &(modelData->realVarsData[j].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->realVarsData[j].info.name);
    read_value(mi.rAlg[i]["valueReference"], &(modelData->realVarsData[j].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.id);
    read_value(mi.rAlg[i]["description"], &(modelData->realVarsData[j].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.comment);
    read_value(mi.rAlg[i]["fileName"], (modelica_string*)&(modelData->realVarsData[j].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.filename);
    read_value(mi.rAlg[i]["startLine"], (modelica_integer*) &(modelData->realVarsData[j].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.lineStart);
    read_value(mi.rAlg[i]["startColumn"], (modelica_integer*) &(modelData->realVarsData[j].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.colStart);
    read_value(mi.rAlg[i]["endLine"], (modelica_integer*) &(modelData->realVarsData[j].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.lineEnd);
    read_value(mi.rAlg[i]["endColumn"], (modelica_integer*) &(modelData->realVarsData[j].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.colEnd);
    read_value(mi.rAlg[i]["fileWritable"], (modelica_integer*) &(modelData->realVarsData[j].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.readonly);

    /* read var attribute */
    read_value(mi.rAlg[i]["useStart"], (modelica_boolean*)&(modelData->realVarsData[j].attribute.useStart));
    read_value(mi.rAlg[i]["start"], &(modelData->realVarsData[j].attribute.start));
    read_value(mi.rAlg[i]["fixed"], (modelica_boolean*)&(modelData->realVarsData[j].attribute.fixed));
    read_value(mi.rAlg[i]["useNominal"], (modelica_boolean*)&(modelData->realVarsData[j].attribute.useNominal));
    read_value(mi.rAlg[i]["nominal"], &(modelData->realVarsData[j].attribute.nominal));
    read_value(mi.rAlg[i]["min"], &(modelData->realVarsData[j].attribute.min));
    read_value(mi.rAlg[i]["max"], &(modelData->realVarsData[j].attribute.max));

    DEBUG_INFO_AL10(LOG_SOLVER, "| Real %s(%sstart=%g%s, fixed=%s, %snominal=%g%s, min=%g, max=%g)", modelData->realVarsData[j].info.name, (modelData->realVarsData[j].attribute.useStart)?"":"{", modelData->realVarsData[j].attribute.start, (modelData->realVarsData[j].attribute.useStart)?"":"}", (modelData->realVarsData[j].attribute.fixed)?"true":"false", (modelData->realVarsData[j].attribute.useNominal)?"":"{", modelData->realVarsData[j].attribute.nominal, (modelData->realVarsData[j].attribute.useNominal)?"":"}", modelData->realVarsData[j].attribute.min, modelData->realVarsData[j].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->realVarsData[j].info.name)]= j;
  }

  /* Read integer variables static data */
  DEBUG_INFO((LOG_SOLVER|LOG_DEBUG), "read xml file for integer algebraic:");
  for(int i=0; i<modelData->nVariablesInteger; i++)
  {
    /* read var info */
    read_value(mi.iAlg[i]["name"], &(modelData->integerVarsData[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->integerVarsData[i].info.name);
    read_value(mi.iAlg[i]["valueReference"], &(modelData->integerVarsData[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.id);
    read_value(mi.iAlg[i]["description"], &(modelData->integerVarsData[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.comment);
    read_value(mi.iAlg[i]["fileName"], (modelica_string*)&(modelData->integerVarsData[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.filename);
    read_value(mi.iAlg[i]["startLine"], (modelica_integer*) &(modelData->integerVarsData[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.lineStart);
    read_value(mi.iAlg[i]["startColumn"], (modelica_integer*) &(modelData->integerVarsData[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.colStart);
    read_value(mi.iAlg[i]["endLine"], (modelica_integer*) &(modelData->integerVarsData[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.lineEnd);
    read_value(mi.iAlg[i]["endColumn"], (modelica_integer*) &(modelData->integerVarsData[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.colEnd);
    read_value(mi.iAlg[i]["fileWritable"], (modelica_integer*) &(modelData->integerVarsData[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.iAlg[i]["useStart"], &(modelData->integerVarsData[i].attribute.useStart));
    read_value(mi.iAlg[i]["start"], &(modelData->integerVarsData[i].attribute.start));
    read_value(mi.iAlg[i]["fixed"], &(modelData->integerVarsData[i].attribute.fixed));
    read_value(mi.iAlg[i]["min"], &(modelData->integerVarsData[i].attribute.min));
    read_value(mi.iAlg[i]["max"], &(modelData->integerVarsData[i].attribute.max));

    DEBUG_INFO_AL7(LOG_SOLVER, "| Integer %s(%sstart=%ld%s, fixed=%s, min=%ld, max=%ld)", modelData->integerVarsData[i].info.name, (modelData->integerVarsData[i].attribute.useStart)?"":"{", modelData->integerVarsData[i].attribute.start, (modelData->integerVarsData[i].attribute.useStart)?"":"}", (modelData->integerVarsData[i].attribute.fixed)?"true":"false", modelData->integerVarsData[i].attribute.min, modelData->integerVarsData[i].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->integerVarsData[i].info.name)]= i;
  }

  DEBUG_INFO((LOG_SOLVER|LOG_DEBUG), "read xml file for boolean algebraic:");
  /* Read boolean variables static data */
  for(int i=0; i<modelData->nVariablesBoolean; i++)
  {
    /* read var info */
    read_value(mi.bAlg[i]["name"], &(modelData->booleanVarsData[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->booleanVarsData[i].info.name);
    read_value(mi.bAlg[i]["valueReference"], &(modelData->booleanVarsData[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.id);
    read_value(mi.bAlg[i]["description"], &(modelData->booleanVarsData[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.comment);
    read_value(mi.bAlg[i]["fileName"], (modelica_string*)&(modelData->booleanVarsData[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.filename);
    read_value(mi.bAlg[i]["startLine"], (modelica_integer*) &(modelData->booleanVarsData[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.lineStart);
    read_value(mi.bAlg[i]["startColumn"], (modelica_integer*) &(modelData->booleanVarsData[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.colStart);
    read_value(mi.bAlg[i]["endLine"], (modelica_integer*) &(modelData->booleanVarsData[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.lineEnd);
    read_value(mi.bAlg[i]["endColumn"], (modelica_integer*) &(modelData->booleanVarsData[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.colEnd);
    read_value(mi.bAlg[i]["fileWritable"], (modelica_integer*) &(modelData->booleanVarsData[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.bAlg[i]["useStart"], &(modelData->booleanVarsData[i].attribute.useStart));
    read_value(mi.bAlg[i]["start"], &(modelData->booleanVarsData[i].attribute.start));
    read_value(mi.bAlg[i]["fixed"], &(modelData->booleanVarsData[i].attribute.fixed));

    DEBUG_INFO_AL5(LOG_SOLVER, "| Boolean %s(%sstart=%s%s, fixed=%s)", modelData->booleanVarsData[i].info.name, modelData->booleanVarsData[i].attribute.useStart?"":"{", modelData->booleanVarsData[i].attribute.start?"true":"false", modelData->booleanVarsData[i].attribute.useStart?"":"}", modelData->booleanVarsData[i].attribute.fixed?"true":"false");

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->booleanVarsData[i].info.name)]= i;
  }

  /* read string variables static data */
  DEBUG_INFO((LOG_SOLVER|LOG_DEBUG), "read xml file for string algebraic:");
  for(int i=0; i<modelData->nVariablesString; i++)
  {
    /* read var info */
    read_value(mi.sAlg[i]["name"], &(modelData->stringVarsData[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->stringVarsData[i].info.name);
    read_value(mi.sAlg[i]["valueReference"], &(modelData->stringVarsData[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.id);
    read_value(mi.sAlg[i]["description"], &(modelData->stringVarsData[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.comment);
    read_value(mi.sAlg[i]["fileName"], (modelica_string*)&(modelData->stringVarsData[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.filename);
    read_value(mi.sAlg[i]["startLine"], (modelica_integer*) &(modelData->stringVarsData[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.lineStart);
    read_value(mi.sAlg[i]["startColumn"], (modelica_integer*) &(modelData->stringVarsData[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.colStart);
    read_value(mi.sAlg[i]["endLine"], (modelica_integer*) &(modelData->stringVarsData[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.lineEnd);
    read_value(mi.sAlg[i]["endColumn"], (modelica_integer*) &(modelData->stringVarsData[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.colEnd);
    read_value(mi.sAlg[i]["fileWritable"], (modelica_integer*) &(modelData->stringVarsData[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.sAlg[i]["useStart"], &(modelData->stringVarsData[i].attribute.useStart));
    read_value(mi.sAlg[i]["start"], &(modelData->stringVarsData[i].attribute.start));

    DEBUG_INFO_AL4(LOG_SOLVER, "| String %s(%sstart=%s%s)", modelData->stringVarsData[i].info.name, (modelData->stringVarsData[i].attribute.useStart)?"":"{", modelData->stringVarsData[i].attribute.start, (modelData->stringVarsData[i].attribute.useStart)?"":"}");

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->stringVarsData[i].info.name)]=i;
  }

  /*
   * real all parameters
   */
  /* read Parameters static data */
  DEBUG_INFO((LOG_SOLVER|LOG_DEBUG), "read xml file for real parameters:");
  for(int i=0; i<modelData->nParametersReal; i++)
  {
    /* read var info */
    read_value(mi.rPar[i]["name"], &(modelData->realParameterData[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->realParameterData[i].info.name);
    read_value(mi.rPar[i]["valueReference"], &(modelData->realParameterData[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.id);
    read_value(mi.rPar[i]["description"], &(modelData->realParameterData[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.comment);
    read_value(mi.rPar[i]["fileName"], (modelica_string*)&(modelData->realParameterData[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.filename);
    read_value(mi.rPar[i]["startLine"], (modelica_integer*) &(modelData->realParameterData[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.lineStart);
    read_value(mi.rPar[i]["startColumn"], (modelica_integer*) &(modelData->realParameterData[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.colStart);
    read_value(mi.rPar[i]["endLine"], (modelica_integer*) &(modelData->realParameterData[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.lineEnd);
    read_value(mi.rPar[i]["endColumn"], (modelica_integer*) &(modelData->realParameterData[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.colEnd);
    read_value(mi.rPar[i]["fileWritable"], (modelica_integer*) &(modelData->realParameterData[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.rPar[i]["useStart"], &(modelData->realParameterData[i].attribute.useStart));
    read_value(mi.rPar[i]["start"], &(modelData->realParameterData[i].attribute.start));
    read_value(mi.rPar[i]["fixed"], &(modelData->realParameterData[i].attribute.fixed));
    read_value(mi.rPar[i]["useNominal"], &(modelData->realParameterData[i].attribute.useNominal));
    read_value(mi.rPar[i]["nominal"], &(modelData->realParameterData[i].attribute.nominal));
    read_value(mi.rPar[i]["min"], &(modelData->realParameterData[i].attribute.min));
    read_value(mi.rPar[i]["max"], &(modelData->realParameterData[i].attribute.max));

    DEBUG_INFO_AL10(LOG_SOLVER, "| parameter Real %s(%sstart=%g%s, fixed=%s, %snominal=%g%s, min=%g, max=%g)", modelData->realParameterData[i].info.name, modelData->realParameterData[i].attribute.useStart?"":"{", modelData->realParameterData[i].attribute.start, modelData->realParameterData[i].attribute.useStart?"":"}", modelData->realParameterData[i].attribute.fixed?"true":"false", modelData->realParameterData[i].attribute.useNominal?"":"{", modelData->realParameterData[i].attribute.nominal, modelData->realParameterData[i].attribute.useNominal?"":"}", modelData->realParameterData[i].attribute.min, modelData->realParameterData[i].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAliasParam[(modelData->realParameterData[i].info.name)]=i;
  }

  /* Read integer parameters static data */
  DEBUG_INFO((LOG_SOLVER|LOG_DEBUG), "read xml file for integer parameters:");
  for(int i=0; i<modelData->nParametersInteger; i++)
  {
    /* read var info */
    read_value(mi.iPar[i]["name"], &(modelData->integerParameterData[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->integerParameterData[i].info.name);
    read_value(mi.iPar[i]["valueReference"], &(modelData->integerParameterData[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.id);
    read_value(mi.iPar[i]["description"], &(modelData->integerParameterData[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.comment);
    read_value(mi.iPar[i]["fileName"], (modelica_string*)&(modelData->integerParameterData[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.filename);
    read_value(mi.iPar[i]["startLine"], (modelica_integer*) &(modelData->integerParameterData[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.lineStart);
    read_value(mi.iPar[i]["startColumn"], (modelica_integer*) &(modelData->integerParameterData[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.colStart);
    read_value(mi.iPar[i]["endLine"], (modelica_integer*) &(modelData->integerParameterData[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.lineEnd);
    read_value(mi.iPar[i]["endColumn"], (modelica_integer*) &(modelData->integerParameterData[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.colEnd);
    read_value(mi.iPar[i]["fileWritable"], (modelica_integer*) &(modelData->integerParameterData[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.iPar[i]["useStart"], (modelica_boolean*)&(modelData->integerParameterData[i].attribute.useStart));
    read_value(mi.iPar[i]["start"], &(modelData->integerParameterData[i].attribute.start));
    read_value(mi.iPar[i]["fixed"], (modelica_boolean*)&(modelData->integerParameterData[i].attribute.fixed));
    read_value(mi.iPar[i]["min"], &(modelData->integerParameterData[i].attribute.min));
    read_value(mi.iPar[i]["max"], &(modelData->integerParameterData[i].attribute.max));

    DEBUG_INFO_AL7(LOG_SOLVER, "| parameter Integer %s(%sstart=%ld%s, fixed=%s, min=%ld, max=%ld)", modelData->integerParameterData[i].info.name, modelData->integerParameterData[i].attribute.useStart?"":"{", modelData->integerParameterData[i].attribute.start, modelData->integerParameterData[i].attribute.useStart?"":"}", modelData->integerParameterData[i].attribute.fixed?"true":"false", modelData->integerParameterData[i].attribute.min, modelData->integerParameterData[i].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAliasParam[(modelData->integerParameterData[i].info.name)]=i;
  }

  /* Read boolean parameters static data */
  DEBUG_INFO((LOG_SOLVER|LOG_DEBUG), "read xml file for boolean parameters:");
  for(int i=0; i<modelData->nParametersBoolean; i++)
  {
    /* read var info */
    read_value(mi.bPar[i]["name"], &(modelData->booleanParameterData[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file", modelData->booleanParameterData[i].info.name);
    read_value(mi.bPar[i]["valueReference"], &(modelData->booleanParameterData[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file", modelData->booleanParameterData[i].info.name, modelData->booleanParameterData[i].info.id);
    read_value(mi.bPar[i]["description"], &(modelData->booleanParameterData[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file", modelData->booleanParameterData[i].info.name, modelData->booleanParameterData[i].info.comment);
    read_value(mi.bPar[i]["fileName"], (modelica_string*)&(modelData->booleanParameterData[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file", modelData->booleanParameterData[i].info.name, modelData->booleanParameterData[i].info.info.filename);
    read_value(mi.bPar[i]["startLine"], (modelica_integer*)&(modelData->booleanParameterData[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file", modelData->booleanParameterData[i].info.name, modelData->booleanParameterData[i].info.info.lineStart);
    read_value(mi.bPar[i]["startColumn"], (modelica_integer*)&(modelData->booleanParameterData[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file", modelData->booleanParameterData[i].info.name, modelData->booleanParameterData[i].info.info.colStart);
    read_value(mi.bPar[i]["endLine"], (modelica_integer*)&(modelData->booleanParameterData[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file", modelData->booleanParameterData[i].info.name, modelData->booleanParameterData[i].info.info.lineEnd);
    read_value(mi.bPar[i]["endColumn"], (modelica_integer*)&(modelData->booleanParameterData[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file", modelData->booleanParameterData[i].info.name, modelData->booleanParameterData[i].info.info.colEnd);
    read_value(mi.bPar[i]["fileWritable"], (modelica_integer*)&(modelData->booleanParameterData[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file", modelData->booleanParameterData[i].info.name, modelData->booleanParameterData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.bPar[i]["useStart"], &(modelData->booleanParameterData[i].attribute.useStart));
    read_value(mi.bPar[i]["start"], &(modelData->booleanParameterData[i].attribute.start));
    read_value(mi.bPar[i]["fixed"], &(modelData->booleanParameterData[i].attribute.fixed));

    DEBUG_INFO_AL5(LOG_SOLVER, "| parameter Boolean %s(%sstart=%s%s, fixed=%s)", modelData->booleanParameterData[i].info.name, modelData->booleanParameterData[i].attribute.useStart?"":"{", modelData->booleanParameterData[i].attribute.start?"true":"false", modelData->booleanParameterData[i].attribute.useStart?"":"}", modelData->booleanParameterData[i].attribute.fixed?"true":"false");

    /* create a mapping for Alias variable to get the correct index */
    mapAliasParam[(modelData->booleanParameterData[i].info.name)]=i;
  }

  /* Read string parameters static data */
  DEBUG_INFO((LOG_SOLVER|LOG_DEBUG), "read xml file for string parameters:");
  for(int i=0; i<modelData->nParametersString; i++)
  {
    /* read var info */
    read_value(mi.sPar[i]["name"], &(modelData->stringParameterData[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->stringParameterData[i].info.name);
    read_value(mi.sPar[i]["valueReference"], &(modelData->stringParameterData[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.id);
    read_value(mi.sPar[i]["description"], &(modelData->stringParameterData[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.comment);
    read_value(mi.sPar[i]["fileName"], (modelica_string*)&(modelData->stringParameterData[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.filename);
    read_value(mi.sPar[i]["startLine"], (modelica_integer*) &(modelData->stringParameterData[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.lineStart);
    read_value(mi.sPar[i]["startColumn"], (modelica_integer*) &(modelData->stringParameterData[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.colStart);
    read_value(mi.sPar[i]["endLine"], (modelica_integer*) &(modelData->stringParameterData[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.lineEnd);
    read_value(mi.sPar[i]["endColumn"], (modelica_integer*) &(modelData->stringParameterData[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.colEnd);
    read_value(mi.sPar[i]["fileWritable"], (modelica_integer*) &(modelData->stringParameterData[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.sPar[i]["useStart"], &(modelData->stringParameterData[i].attribute.useStart));
    read_value(mi.sPar[i]["start"], &(modelData->stringParameterData[i].attribute.start));

    DEBUG_INFO_AL4(LOG_SOLVER, "| parameter String %s(%sstart=%s%s)", modelData->stringParameterData[i].info.name, modelData->stringParameterData[i].attribute.useStart?"":"{", modelData->stringParameterData[i].attribute.start, modelData->stringParameterData[i].attribute.useStart?"":"}");

    /* create a mapping for Alias variable to get the correct index */
    mapAliasParam[(modelData->stringParameterData[i].info.name)]=i;
  }

  /*
   * real all alias vars
   */
  DEBUG_INFO(LOG_DEBUG, "read xml file for real alias vars:");
  for(int i=0; i<modelData->nAliasReal; i++)
  {
    /* read var info */
    read_value(mi.rAli[i]["name"], &(modelData->realAlias[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->realAlias[i].info.name);
    read_value(mi.rAli[i]["valueReference"], &(modelData->realAlias[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",(modelData->realAlias[i].info.name),modelData->realAlias[i].info.id);
    read_value(mi.rAli[i]["description"], &(modelData->realAlias[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.comment);
    read_value(mi.rAli[i]["fileName"], (modelica_string*)&(modelData->realAlias[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.filename);
    read_value(mi.rAli[i]["startLine"], (modelica_integer*) &(modelData->realAlias[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.lineStart);
    read_value(mi.rAli[i]["startColumn"], (modelica_integer*) &(modelData->realAlias[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.colStart);
    read_value(mi.rAli[i]["endLine"], (modelica_integer*) &(modelData->realAlias[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.lineEnd);
    read_value(mi.rAli[i]["endColumn"], (modelica_integer*) &(modelData->realAlias[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.colEnd);
    read_value(mi.rAli[i]["fileWritable"], (modelica_integer*) &(modelData->realAlias[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.readonly);

    string aliasTmp;
    read_value(mi.rAli[i]["alias"], &aliasTmp);
    if(aliasTmp.compare("negatedAlias") == 0)
      modelData->realAlias[i].negate = 1;
    else
      modelData->realAlias[i].negate = 0;

    DEBUG_INFO_AL2(LOG_DEBUG, "| read for %s negated %d from setup file", modelData->realAlias[i].info.name, modelData->realAlias[i].negate);

    read_value(mi.rAli[i]["aliasVariable"], &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if(it != mapAlias.end())
    {
      modelData->realAlias[i].nameID  = (*it).second;
      modelData->realAlias[i].aliasType = 0;
    }
    else if(itParam != mapAliasParam.end())
    {
      modelData->realAlias[i].nameID  = (*itParam).second;
      modelData->realAlias[i].aliasType = 1;
    }
    else if(aliasTmp.compare("time"))
      modelData->realAlias[i].aliasType = 2;
    else
      THROW("Alias variable not found.");

    DEBUG_INFO_AL3(LOG_DEBUG, "| read for %s aliasID %d from %s from setup file",
                modelData->realAlias[i].info.name,
                modelData->realAlias[i].nameID,
                modelData->realAlias[i].aliasType ? ((modelData->realAlias[i].aliasType==2) ? "time" : "real parameters") : "real variables");
  }

  /*
   * integer all alias vars
   */
  DEBUG_INFO(LOG_DEBUG, "read xml file for integer alias vars:");
  for(int i=0; i<modelData->nAliasInteger; i++)
  {
    /* read var info */
    read_value(mi.iAli[i]["name"], &(modelData->integerAlias[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->integerAlias[i].info.name);
    read_value(mi.iAli[i]["valueReference"], &(modelData->integerAlias[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.id);
    read_value(mi.iAli[i]["description"], &(modelData->integerAlias[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.comment);
    read_value(mi.iAli[i]["fileName"], (modelica_string*)&(modelData->integerAlias[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.filename);
    read_value(mi.iAli[i]["startLine"], (modelica_integer*) &(modelData->integerAlias[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.lineStart);
    read_value(mi.iAli[i]["startColumn"], (modelica_integer*) &(modelData->integerAlias[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.colStart);
    read_value(mi.iAli[i]["endLine"], (modelica_integer*) &(modelData->integerAlias[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.lineEnd);
    read_value(mi.iAli[i]["endColumn"], (modelica_integer*) &(modelData->integerAlias[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.colEnd);
    read_value(mi.iAli[i]["fileWritable"], (modelica_integer*) &(modelData->integerAlias[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.readonly);

    string aliasTmp;
    read_value(mi.iAli[i]["alias"], &aliasTmp);
    if(aliasTmp.compare("negatedAlias") == 0)
      modelData->integerAlias[i].negate = 1;
    else
      modelData->integerAlias[i].negate = 0;

    DEBUG_INFO_AL2(LOG_DEBUG, "| read for %s negated %d from setup file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].negate);

    read_value(mi.iAli[i]["aliasVariable"], &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if(it != mapAlias.end())
    {
      modelData->integerAlias[i].nameID  = (*it).second;
      modelData->integerAlias[i].aliasType = 0;
    }
    else if(itParam != mapAliasParam.end())
    {
      modelData->integerAlias[i].nameID  = (*itParam).second;
      modelData->integerAlias[i].aliasType = 1;
    }
    else
      THROW("Alias variable not found.");

    DEBUG_INFO_AL3(LOG_DEBUG, "| read for %s aliasID %d from %s from setup file",
                modelData->integerAlias[i].info.name,
                modelData->integerAlias[i].nameID,
                modelData->integerAlias[i].aliasType?"integer parameters":"integer variables");
  }

  /*
   * boolean all alias vars
   */
  DEBUG_INFO(LOG_DEBUG, "read xml file for boolean alias vars:");
  for(int i=0; i<modelData->nAliasBoolean; i++)
  {
    /* read var info */
    read_value(mi.bAli[i]["name"], &(modelData->booleanAlias[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->booleanAlias[i].info.name);
    read_value(mi.bAli[i]["valueReference"], &(modelData->booleanAlias[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.id);
    read_value(mi.bAli[i]["description"], &(modelData->booleanAlias[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.comment);
    read_value(mi.bAli[i]["fileName"], (modelica_string*)&(modelData->booleanAlias[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.filename);
    read_value(mi.bAli[i]["startLine"], (modelica_boolean*) &(modelData->booleanAlias[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.lineStart);
    read_value(mi.bAli[i]["startColumn"], (modelica_boolean*) &(modelData->booleanAlias[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.colStart);
    read_value(mi.bAli[i]["endLine"], (modelica_boolean*) &(modelData->booleanAlias[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.lineEnd);
    read_value(mi.bAli[i]["endColumn"], (modelica_boolean*) &(modelData->booleanAlias[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.colEnd);
    read_value(mi.bAli[i]["fileWritable"], (modelica_boolean*) &(modelData->booleanAlias[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.readonly);

    std::string aliasTmp;
    read_value(mi.bAli[i]["alias"], &aliasTmp);
    if(aliasTmp.compare("negatedAlias") == 0)
      modelData->booleanAlias[i].negate = 1;
    else
      modelData->booleanAlias[i].negate = 0;

    DEBUG_INFO_AL2(LOG_DEBUG, "| read for %s negated %d from setup file", modelData->booleanAlias[i].info.name, modelData->booleanAlias[i].negate);

    read_value(mi.bAli[i]["aliasVariable"], &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if(it != mapAlias.end())
    {
      modelData->booleanAlias[i].nameID  = (*it).second;
      modelData->booleanAlias[i].aliasType = 0;
    }
    else if(itParam != mapAliasParam.end())
    {
      modelData->booleanAlias[i].nameID  = (*itParam).second;
      modelData->booleanAlias[i].aliasType = 1;
    }
    else
      THROW("Alias variable not found.");

    DEBUG_INFO_AL3(LOG_DEBUG, "| read for %s aliasID %d from %s from setup file",
                modelData->booleanAlias[i].info.name,
                modelData->booleanAlias[i].nameID,
                modelData->booleanAlias[i].aliasType ? "boolean parameters" : "boolean variables");
  }

  /*
   * string all alias vars
   */
  DEBUG_INFO(LOG_DEBUG, "read xml file for string alias vars:");
  for(int i=0; i<modelData->nAliasString; i++)
  {
    /* read var info */
    read_value(mi.sAli[i]["name"], &(modelData->stringAlias[i].info.name));
    DEBUG_INFO_AL1(LOG_DEBUG, "| read var %s from setup file",modelData->stringAlias[i].info.name);
    read_value(mi.sAli[i]["valueReference"], &(modelData->stringAlias[i].info.id));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s id %d from setup file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.id);
    read_value(mi.sAli[i]["description"], &(modelData->stringAlias[i].info.comment));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s comment %s from setup file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.comment);
    read_value(mi.sAli[i]["fileName"], (modelica_string*)&(modelData->stringAlias[i].info.info.filename));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s filename %s from setup file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.filename);
    read_value(mi.sAli[i]["startLine"], (modelica_string*) &(modelData->stringAlias[i].info.info.lineStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineStart %d from setup file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.lineStart);
    read_value(mi.sAli[i]["startColumn"], (modelica_string*) &(modelData->stringAlias[i].info.info.colStart));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colStart %d from setup file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.colStart);
    read_value(mi.sAli[i]["endLine"], (modelica_string*) &(modelData->stringAlias[i].info.info.lineEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s lineEnd %d from setup file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.lineEnd);
    read_value(mi.sAli[i]["endColumn"], (modelica_string*) &(modelData->stringAlias[i].info.info.colEnd));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s colEnd %d from setup file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.colEnd);
    read_value(mi.sAli[i]["fileWritable"], (modelica_string*) &(modelData->stringAlias[i].info.info.readonly));
    DEBUG_INFO_AL2(LOG_DEBUG, "| | read for %s readonly %d from setup file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.readonly);

    std::string aliasTmp;
    read_value(mi.sAli[i]["alias"], &aliasTmp);
    if(aliasTmp.compare("negatedAlias") == 0)
      modelData->stringAlias[i].negate = 1;
    else
      modelData->stringAlias[i].negate = 0;

    DEBUG_INFO_AL2(LOG_DEBUG, "| read for %s negated %d from setup file", modelData->stringAlias[i].info.name, modelData->stringAlias[i].negate);

    read_value(mi.sAli[i]["aliasVariable"], &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if(it != mapAlias.end())
    {
      modelData->stringAlias[i].nameID  = (*it).second;
      modelData->stringAlias[i].aliasType = 0;
    }
    else if(itParam != mapAliasParam.end())
    {
      modelData->stringAlias[i].nameID  = (*itParam).second;
      modelData->stringAlias[i].aliasType = 1;
    }
    else
      THROW("Alias variable not found.");

    DEBUG_INFO_AL3(LOG_DEBUG, "| read for %s aliasID %d from %s from setup file",
                modelData->stringAlias[i].info.name,
                modelData->stringAlias[i].nameID,
                modelData->stringAlias[i].aliasType ? "string parameters" : "string variables");
  }

  delete filename;
  XML_ParserFree(parser);

  fclose(file);
}

/* reads std::string value from a string */
inline void read_value(std::string s, std::string* str)
{
  *str = s;
}

/* reads modelica_string value from a string */
inline void read_value(std::string s, modelica_string* str)
{
  if(str == NULL)
  {
    WARNING("error read_value, no data allocated for storing string");
    return;
  }
  *str = strdup(s.c_str());
}

/* reads double value from a string */
inline void read_value(std::string s, modelica_real* res)
{
  if(s.compare("true") == 0)
    *res = 1.0;
  else if(s.compare("false") == 0)
    *res = 0.0;
  else
    *res = atof(s.c_str());
}

/* reads boolean value from a string */
inline void read_value(std::string s, modelica_boolean* res)
{
  if(s.compare("true") == 0)
    *res = 1;
  else if(s.compare("false") == 0)
    *res = 0;
  else
    *res = 0;
}

/* reads integer value from a string */
inline void read_value(std::string s, modelica_integer* res)
{
  if(s.compare("true") == 0)
    *res = 1;
  else if(s.compare("false") == 0)
    *res = 0;
  else
    *res = atol(s.c_str());
}

/* reads integer value from a string */
inline void read_value(std::string s, int* res)
{
  if(s.compare("true") == 0)
    *res = 1;
  else if(s.compare("false") == 0)
    *res = 0;
  else
    *res = atoi(s.c_str());
}


omc_ModelInput doOverride(omc_ModelInput mi, MODEL_DATA* modelData, std::string* override)
{
  omc_CommandLineOverrides mOverrides;
  if (override)
  {
    /* read override values */
    DEBUG_INFO_AL1(LOG_SOLVER, "read override values: %s", override->c_str());
    std::string key, value;
    char *str = strdup(override->c_str());
    char *p = strtok(str, ",");
    while (p)
    {
        std::string *key_val = new string(p);
        // split it key = value => map[key]=value
        size_t pos = key_val->find("=");
        key = key_val->substr(0,pos);
        value = key_val->substr(pos + 1,key_val->length() - pos - 1);

        /* un-quote key and value
        if (key[0] == '"')
         key = key.substr(1,key.length() - 1);
        if (key[key.length()] == '"')
         key = key.substr(0,key.length() - 1);
        if (value[0] == '"')
         value = value.substr(1,value.length() - 1);
        if (value[value.length()] == '"')
         value = value.substr(0,value.length() - 1);
        */

        // map[key]=value
        mOverrides[key] = value;

        DEBUG_INFO_AL2(LOG_SOLVER, "override %s = %s", key.c_str(), value.c_str());

        // move to next
        p = strtok(NULL, ",");
    }

    // now we have all overrides in mOverrides, override mi now
    mi.de["solver"]         = mOverrides.count("solver")         ? mOverrides["solver"]         : mi.de["solver"];
    mi.de["startTime"]      = mOverrides.count("startTime")      ? mOverrides["startTime"]      : mi.de["startTime"];
    mi.de["stopTime"]       = mOverrides.count("stopTime")       ? mOverrides["stopTime"]       : mi.de["stopTime"];
    mi.de["stepSize"]       = mOverrides.count("stepSize")       ? mOverrides["stepSize"]       : mi.de["stepSize"];
    mi.de["tolerance"]      = mOverrides.count("tolerance")      ? mOverrides["tolerance"]      : mi.de["tolerance"];
    mi.de["outputFormat"]   = mOverrides.count("outputFormat")   ? mOverrides["outputFormat"]   : mi.de["outputFormat"];
    mi.de["variableFilter"] = mOverrides.count("variableFilter") ? mOverrides["variableFilter"] : mi.de["variableFilter"];

    // override all found!
    for(int i=0; i<modelData->nStates; i++)
    {
      mi.rSta[i]["start"] = mOverrides.count(mi.rSta[i]["name"]) ? mOverrides[mi.rSta[i]["name"]] : mi.rSta[i]["start"];
      mi.rDer[i]["start"] = mOverrides.count(mi.rDer[i]["name"]) ? mOverrides[mi.rDer[i]["name"]] : mi.rDer[i]["start"];
    }
    for(int i=0; i<(modelData->nVariablesReal - 2*modelData->nStates); i++)
    {
      mi.rAlg[i]["start"] = mOverrides.count(mi.rAlg[i]["name"]) ? mOverrides[mi.rAlg[i]["name"]] : mi.rAlg[i]["start"];
    }
    for(int i=0; i<modelData->nVariablesInteger; i++)
    {
      mi.iAlg[i]["start"] = mOverrides.count(mi.iAlg[i]["name"]) ? mOverrides[mi.iAlg[i]["name"]] : mi.iAlg[i]["start"];
    }
    for(int i=0; i<modelData->nVariablesBoolean; i++)
    {
      mi.bAlg[i]["start"] = mOverrides.count(mi.bAlg[i]["name"]) ? mOverrides[mi.bAlg[i]["name"]] : mi.bAlg[i]["start"];
    }
    for(int i=0; i<modelData->nVariablesString; i++)
    {
      mi.sAlg[i]["start"] = mOverrides.count(mi.sAlg[i]["name"]) ? mOverrides[mi.sAlg[i]["name"]] : mi.sAlg[i]["start"];
    }
    for(int i=0; i<modelData->nParametersReal; i++)
    {
      mi.rPar[i]["start"] = mOverrides.count(mi.rPar[i]["name"]) ? mOverrides[mi.rPar[i]["name"]] : mi.rPar[i]["start"];
    }
    for(int i=0; i<modelData->nParametersInteger; i++)
    {
      mi.iPar[i]["start"] = mOverrides.count(mi.iPar[i]["name"]) ? mOverrides[mi.iPar[i]["name"]] : mi.iPar[i]["start"];
    }
    for(int i=0; i<modelData->nParametersBoolean; i++)
    {
      mi.bPar[i]["start"] = mOverrides.count(mi.bPar[i]["name"]) ? mOverrides[mi.bPar[i]["name"]] : mi.bPar[i]["start"];
    }
    for(int i=0; i<modelData->nParametersString; i++)
    {
      mi.sPar[i]["start"] = mOverrides.count(mi.sPar[i]["name"]) ? mOverrides[mi.sPar[i]["name"]] : mi.sPar[i]["start"];
    }
    for(int i=0; i<modelData->nAliasReal; i++)
    {
      mi.rAli[i]["start"] = mOverrides.count(mi.rAli[i]["name"]) ? mOverrides[mi.rAli[i]["name"]] : mi.rAli[i]["start"];
    }
    for(int i=0; i<modelData->nAliasInteger; i++)
    {
      mi.iAli[i]["start"] = mOverrides.count(mi.iAli[i]["name"]) ? mOverrides[mi.iAli[i]["name"]] : mi.iAli[i]["start"];
    }
    for(int i=0; i<modelData->nAliasBoolean; i++)
    {
      mi.bAli[i]["start"] = mOverrides.count(mi.bAli[i]["name"]) ? mOverrides[mi.bAli[i]["name"]] : mi.bAli[i]["start"];
    }
    for(int i=0; i<modelData->nAliasString; i++)
    {
      mi.sAli[i]["start"] = mOverrides.count(mi.sAli[i]["name"]) ? mOverrides[mi.sAli[i]["name"]] : mi.sAli[i]["start"];
    }
    DEBUG_INFO_AL1(LOG_SOLVER, "override done!: %s", override->c_str());
  }
  else
  {
    DEBUG_INFO(LOG_SOLVER, "NO override given on the command line.");
  }
  return mi;
}
