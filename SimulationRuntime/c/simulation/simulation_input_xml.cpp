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
#include "error.h"

#include <fstream>
#include <iomanip>
#include <map>
#include <list>
#include <string.h>
#include <expat.h>

using namespace std;

typedef map < string, string >             omc_ModelDescription;
typedef map < string, string >             omc_DefaultExperiment;
typedef map < string, string >             omc_ScalarVariable;
typedef map < int, omc_ScalarVariable >    omc_ModelVariables;

/* maybe use a map below {"rSta" -> omc_ModelVariables} */
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

/* reads double value from a string */
void read_value(string s, double *res);
/* reads integer value from a string */
void read_value(string s, modelica_integer *res);
/* reads integer value from a string */
void read_value(string s, int *res);
/* reads string value from a string */
void read_value(string s, string *str);
/* reads a string value from a string */
void read_value(string s, const char **str);
/* reads boolean value from a string */
void read_value(string s, signed char *str);

static void XMLCALL startElement(void *userData, const char *name, const char **attr)
{
  omc_ModelInput* mi = (omc_ModelInput*)userData;
  int i = 0;

  /* handle fmiModelDescription */
  if (!strcmp(name, "fmiModelDescription"))
  {
    for (i = 0; attr[i]; i += 2)
    {
      mi->md[attr[i]] = attr[i + 1];
    }
    return;
  }
  /* handle DefaultExperiment */
  if (!strcmp(name, "DefaultExperiment"))
  {
    for (i = 0; attr[i]; i += 2)
    {
      mi->de[attr[i]] = attr[i + 1];
    }
    return;
  }

  /* handle ScalarVariable */
  if (!strcmp(name, "ScalarVariable"))
  {
    omc_ScalarVariable v;
    string ci, ct;
    mi->lastCI = -1;
    mi->lastCT = NULL;
    for (i = 0; attr[i]; i += 2)
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

    if (mi->lastCT == NULL)
    {
      THROW2("simulation_input_xml.cpp: error reading the xml file, found unknown class: %s  for variable: %s",ct.c_str(),(v["name"]).c_str());
    }

    /* add the ScalarVariable map to the correct map! */
    (*mi->lastCT)[mi->lastCI] = v;
    return;
  }
  /* handle Real/Integer/Boolean/String */
  if (!strcmp(name, "Real") || !strcmp(name, "Integer") || !strcmp(name, "Boolean") || !strcmp(name, "String"))
  {
    /* add keys/value to the last variable */
    for (i = 0; attr[i]; i += 2)
    {
      /* add more key/value pairs to the last variable */
      ((*mi->lastCT)[mi->lastCI])[attr[i]] = attr[i + 1];
    }
    ((*mi->lastCT)[mi->lastCI])["variableType"] = name;
    return;
  }
  /* anything else, we don't handle! */
}

static void XMLCALL
endElement(void *userData, const char *name)
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
  string *filename = NULL;
  FILE* file = NULL;
  XML_Parser parser = NULL;
  int done = 0;
  map< string, modelica_integer> mapAlias,mapAliasParam;
  map< string, modelica_integer>::iterator it, itParam;

  /* read the filename from the command line (if any) */
  filename=(string*)getFlagValue("f",argc,argv);
  /* no file given on the command line? use the default */
  if (filename == NULL) {
    filename = new string(string(modelData->modelFilePrefix)+"_init.xml");  /* model_name defined in generated code for model.*/
  }
  /* open the file and fail on error. we open it read-write to be sure other processes can overwrite it */
  file = fopen(filename->c_str(), "r");
  if (!file) {
    THROW1("simulation_input_xml.cpp: Error: can not read file %s as indata to simulation.",filename->c_str());
    /* if (filename) delete filename; */
  }
  /* create the XML parser */
  parser = XML_ParserCreate(NULL);
  if (!parser) {
    if (filename) delete filename;
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
    if (XML_Parse(parser, buf, len, done) == XML_STATUS_ERROR)
    {
      fclose(file);
      THROW3("simulation_input_xml.cpp: Error: failed to read the XML file %s: %s at line %lu\n",
          filename->c_str(),
          XML_ErrorString(XML_GetErrorCode(parser)),
          XML_GetCurrentLineNumber(parser));
      delete filename;
      XML_ParserFree(parser);
      EXIT(1);
    }
  } while (!done);

  /* now we should have all the data inside omc_ModelInput mi. */

  /* first, check the modelGUID!
     TODO! FIXME! THIS SEEMS TO FAIL!
     ARE WE READING THE OLD XML FILE?? */

  if (strcmp(modelData->modelGUID, mi.md["guid"].c_str()))
  {
    XML_ParserFree(parser);
    fclose(file);
    THROW3("Error, the GUID: %s from input data file: %s does not match the GUID compiled in the model: %s",mi.md["guid"].c_str(),filename->c_str(),modelData->modelGUID);
    delete filename;
    EXIT(1);
  }


  string *methodc = (string*)getFlagValue("m",argc,argv);

  /* read all the DefaultExperiment values */
  read_value(mi.de["startTime"],start);
  simulationInfo->startTime = *start;
  DEBUG_INFO1(LOG_SOLVER,"read start = %f from init file",*start);
  read_value(mi.de["stopTime"],stop);
  simulationInfo->stopTime = *stop;
  DEBUG_INFO1(LOG_SOLVER," read stop = %f from init file",*stop);
  read_value(mi.de["stepSize"],stepSize);
  simulationInfo->stepSize = *stepSize;
  DEBUG_INFO1(LOG_SOLVER," read step = %f from init file",*stepSize);
  read_value(mi.de["tolerance"],tolerance);
  simulationInfo->tolerance = *tolerance;
  DEBUG_INFO1(LOG_SOLVER," read tolerance = %f from init file",*tolerance);

  if (methodc == NULL)
  {
    read_value(mi.de["solver"], method);
    simulationInfo->solverMethod = method->c_str();
    DEBUG_INFO1(LOG_SOLVER," read solver method = %s from init file",method->c_str());
  }
  else
  {
    string tmp;
    read_value(mi.de["solver"],&tmp);
    simulationInfo->solverMethod = methodc->c_str();
    DEBUG_INFO1(LOG_SOLVER," read solver method = %s from command line",methodc->c_str());
  }
  read_value(mi.de["outputFormat"],outputFormat);
  simulationInfo->outputFormat = outputFormat->c_str();
  DEBUG_INFO1(LOG_SOLVER," read outputFormat = %s from init file",outputFormat->c_str());
  read_value(mi.de["variableFilter"],variableFilter);
  simulationInfo->variableFilter = variableFilter->c_str();
  DEBUG_INFO1(LOG_SOLVER," read outputFormat = %s from init file",variableFilter->c_str());

  //
  modelica_integer nxchk,nychk,npchk;
  modelica_integer nyintchk,npintchk;
  modelica_integer nyboolchk,npboolchk;
  modelica_integer nystrchk,npstrchk;

  read_value(mi.md["numberOfContinuousStates"],          &nxchk);
  read_value(mi.md["numberOfRealAlgebraicVariables"],    &nychk);
  read_value(mi.md["numberOfRealParameters"],            &npchk);

  read_value(mi.md["numberOfIntegerParameters"],         &npintchk);
  read_value(mi.md["numberOfIntegerAlgebraicVariables"], &nyintchk);

  read_value(mi.md["numberOfBooleanParameters"],         &npboolchk);
  read_value(mi.md["numberOfBooleanAlgebraicVariables"], &nyboolchk);

  read_value(mi.md["numberOfStringParameters"],          &npstrchk);
  read_value(mi.md["numberOfStringAlgebraicVariables"],  &nystrchk);

  if (nxchk != modelData->nStates || nychk != modelData->nVariablesReal - 2*modelData->nStates || npchk != modelData->nParametersReal
      || npintchk != modelData->nParametersInteger || nyintchk != modelData->nVariablesInteger
      || npboolchk != modelData->nParametersBoolean || nyboolchk != modelData->nVariablesBoolean
      || npstrchk != modelData->nParametersString || nystrchk != modelData->nVariablesString) {
    cerr << "Error, input data file does not match model." << endl;
    cerr << "nx in initfile: " << nxchk << " from model code :" << modelData->nStates << endl;
    cerr << "ny in initfile: " << nychk << " from model code :" << modelData->nVariablesReal - 2*modelData->nStates << endl;
    cerr << "np in initfile: " << npchk << " from model code :" << modelData->nParametersReal << endl;
    cerr << "npint in initfile: " << npintchk << " from model code: " << modelData->nParametersInteger << endl;
    cerr << "nyint in initfile: " << nyintchk << " from model code: " << modelData->nVariablesInteger <<  endl;
    cerr << "npbool in initfile: " << npboolchk << " from model code: " << modelData->nParametersBoolean << endl;
    cerr << "nybool in initfile: " << nyboolchk << " from model code: " << modelData->nVariablesBoolean <<  endl;
    cerr << "npstr in initfile: " << npstrchk << " from model code: " << modelData->nParametersString << endl;
    cerr << "nystr in initfile: " << nystrchk << " from model code: " << modelData->nVariablesString <<  endl;
    delete filename;
    XML_ParserFree(parser);
    fclose(file);
    EXIT(-1);
  }

  /* Read all static data from File for every variable */
  /* Read states static data */
  for(int i = 0; i < modelData->nStates; i++) {

    DEBUG_INFO(LOG_DEBUG, "Read xml file for states");
    /* read var info */
    read_value(mi.rSta[i]["name"],&(modelData->realVarsData[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->realVarsData[i].info.name);
    read_value(mi.rSta[i]["valueReference"],&(modelData->realVarsData[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->realVarsData[i].info.name,modelData->realVarsData[i].info.id);
    read_value(mi.rSta[i]["description"],&(modelData->realVarsData[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s description \"%s\" from init file",modelData->realVarsData[i].info.name,modelData->realVarsData[i].info.comment);
    read_value(mi.rSta[i]["fileName"], (const char**) (void*)&(modelData->realVarsData[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->realVarsData[i].info.name, modelData->realVarsData[i].info.info.filename);
    read_value(mi.rSta[i]["startLine"],(modelica_integer*)&(modelData->realVarsData[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->realVarsData[i].info.name,modelData->realVarsData[i].info.info.lineStart);
    read_value(mi.rSta[i]["startColumn"],(modelica_integer*)&(modelData->realVarsData[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->realVarsData[i].info.name,modelData->realVarsData[i].info.info.colStart);
    read_value(mi.rSta[i]["endLine"],(modelica_integer*)&(modelData->realVarsData[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->realVarsData[i].info.name,modelData->realVarsData[i].info.info.lineEnd);
    read_value(mi.rSta[i]["endColumn"],(modelica_integer*)&(modelData->realVarsData[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->realVarsData[i].info.name,modelData->realVarsData[i].info.info.colEnd);
    read_value(mi.rSta[i]["fileWritable"],(modelica_integer*)&(modelData->realVarsData[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->realVarsData[i].info.name,modelData->realVarsData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.rSta[i]["start"], &(modelData->realVarsData[i].attribute.start));
    DEBUG_INFO2(LOG_SOLVER, "read start-value for %s =  %f from init file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].attribute.start);
    read_value(mi.rSta[i]["fixed"], (signed char*)&(modelData->realVarsData[i].attribute.fixed));
    DEBUG_INFO2(LOG_SOLVER, "read fixed-value for %s = %s from init file", modelData->realVarsData[i].info.name, (modelData->realVarsData[i].attribute.fixed)?"true":"false");
    read_value(mi.rSta[i]["nominal"], &(modelData->realVarsData[i].attribute.nominal));
    DEBUG_INFO2(LOG_SOLVER, "read nominal-value for %s =  %f from init file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].attribute.nominal);
    read_value(mi.rSta[i]["min"], &(modelData->realVarsData[i].attribute.min));
    DEBUG_INFO2(LOG_SOLVER," read min-value for %s =  %g from init file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].attribute.min);
    read_value(mi.rSta[i]["max"], &(modelData->realVarsData[i].attribute.max));
    DEBUG_INFO2(LOG_SOLVER," read max-value for %s =  %g from init file", modelData->realVarsData[i].info.name, modelData->realVarsData[i].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->realVarsData[i].info.name)]=i;
  }

  /* Read stateDerivatives static data */
  for(int i = 0; i < modelData->nStates; i++)
  {
    DEBUG_INFO(LOG_DEBUG, "Read xml file for stateDerivatives");
    /* read var info */
    read_value(mi.rDer[i]["name"], &(modelData->realVarsData[modelData->nStates + i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->realVarsData[modelData->nStates+i].info.name);
    read_value(mi.rDer[i]["valueReference"], &(modelData->realVarsData[modelData->nStates+i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.id);
    read_value(mi.rDer[i]["description"], &(modelData->realVarsData[modelData->nStates+i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.comment);
    read_value(mi.rDer[i]["fileName"], (const char**)(void*)&(modelData->realVarsData[modelData->nStates+i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.filename);
    read_value(mi.rDer[i]["startLine"], (modelica_integer*) &(modelData->realVarsData[modelData->nStates+i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.lineStart);
    read_value(mi.rDer[i]["startColumn"], (modelica_integer*) &(modelData->realVarsData[modelData->nStates+i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.colStart);
    read_value(mi.rDer[i]["endLine"], (modelica_integer*) &(modelData->realVarsData[modelData->nStates+i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.lineEnd);
    read_value(mi.rDer[i]["endColumn"], (modelica_integer*) &(modelData->realVarsData[modelData->nStates+i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.colEnd);
    read_value(mi.rDer[i]["fileWritable"], (modelica_integer*) &(modelData->realVarsData[modelData->nStates+i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->realVarsData[modelData->nStates+i].info.name,modelData->realVarsData[modelData->nStates+i].info.info.readonly);

    /* read var attribute */
    read_value(mi.rDer[i]["start"], &(modelData->realVarsData[modelData->nStates+i].attribute.start));
    DEBUG_INFO2(LOG_SOLVER, "read start-value for %s =  %f from init file", modelData->realVarsData[modelData->nStates+i].info.name, modelData->realVarsData[modelData->nStates+i].attribute.start);
    read_value(mi.rDer[i]["fixed"], (signed char*)&(modelData->realVarsData[modelData->nStates+i].attribute.fixed));
    DEBUG_INFO2(LOG_SOLVER, "read fixed for %s = %s from init file", modelData->realVarsData[modelData->nStates+i].info.name, (modelData->realVarsData[modelData->nStates+i].attribute.fixed)?"true":"false");
    read_value(mi.rDer[i]["nominal"], &(modelData->realVarsData[modelData->nStates+i].attribute.nominal));
    DEBUG_INFO2(LOG_SOLVER, "read nominal-value for %s =  %f from init file", modelData->realVarsData[modelData->nStates+i].info.name, modelData->realVarsData[modelData->nStates+i].attribute.nominal);
    read_value(mi.rDer[i]["min"], &(modelData->realVarsData[modelData->nStates+i].attribute.min));
    DEBUG_INFO2(LOG_SOLVER, "read min-value for %s =  %g from init file", modelData->realVarsData[modelData->nStates+i].info.name, modelData->realVarsData[modelData->nStates+i].attribute.min);
    read_value(mi.rDer[i]["max"], &(modelData->realVarsData[modelData->nStates+i].attribute.max));
    DEBUG_INFO2(LOG_SOLVER, "read max-value for %s =  %g from init file", modelData->realVarsData[modelData->nStates+i].info.name, modelData->realVarsData[modelData->nStates+i].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->realVarsData[modelData->nStates+i].info.name)]= modelData->nStates+i;
  }

  /* Read real algebraics static data */
  for(int i = 0; i < (modelData->nVariablesReal - 2*modelData->nStates); i++)
  {
    int j = 2*modelData->nStates + i;
    DEBUG_INFO(LOG_DEBUG, "Read xml file for real algebracis");
    /* read var info */
    read_value(mi.rAlg[i]["name"], &(modelData->realVarsData[j].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->realVarsData[j].info.name);
    read_value(mi.rAlg[i]["valueReference"], &(modelData->realVarsData[j].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.id);
    read_value(mi.rAlg[i]["description"], &(modelData->realVarsData[j].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.comment);
    read_value(mi.rAlg[i]["fileName"], (const char**)(void*)&(modelData->realVarsData[j].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.filename);
    read_value(mi.rAlg[i]["startLine"], (modelica_integer*) &(modelData->realVarsData[j].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.lineStart);
    read_value(mi.rAlg[i]["startColumn"], (modelica_integer*) &(modelData->realVarsData[j].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.colStart);
    read_value(mi.rAlg[i]["endLine"], (modelica_integer*) &(modelData->realVarsData[j].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.lineEnd);
    read_value(mi.rAlg[i]["endColumn"], (modelica_integer*) &(modelData->realVarsData[j].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.colEnd);
    read_value(mi.rAlg[i]["fileWritable"], (modelica_integer*) &(modelData->realVarsData[j].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->realVarsData[j].info.name,modelData->realVarsData[j].info.info.readonly);

    /* read var attribute */
    read_value(mi.rAlg[i]["start"], &(modelData->realVarsData[j].attribute.start));
    DEBUG_INFO2(LOG_SOLVER, "read start-value for %s =  %f from init file", modelData->realVarsData[j].info.name, modelData->realVarsData[j].attribute.start);
    read_value(mi.rAlg[i]["fixed"], (signed char*)&(modelData->realVarsData[j].attribute.fixed));
    DEBUG_INFO2(LOG_SOLVER, "read fixed-value for %s = %s from init file", modelData->realVarsData[j].info.name, modelData->realVarsData[j].attribute.fixed?"true":"false");
    read_value(mi.rAlg[i]["nominal"], &(modelData->realVarsData[j].attribute.nominal));
    DEBUG_INFO2(LOG_SOLVER, "read nominal-value for %s = %f from init file", modelData->realVarsData[j].info.name, modelData->realVarsData[j].attribute.nominal);
    read_value(mi.rAlg[i]["min"], &(modelData->realVarsData[j].attribute.min));
    DEBUG_INFO2(LOG_SOLVER, "read min-value for %s = %g from init file", modelData->realVarsData[j].info.name, modelData->realVarsData[j].attribute.min);
    read_value(mi.rAlg[i]["max"], &(modelData->realVarsData[j].attribute.max));
    DEBUG_INFO2(LOG_SOLVER, "read max-value for %s = %g from init file", modelData->realVarsData[j].info.name, modelData->realVarsData[j].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->realVarsData[j].info.name)]= j;
  }

  /* Read integer variables static data */
  for(int i = 0; i < modelData->nVariablesInteger; i++)
  {
    DEBUG_INFO(LOG_DEBUG, "Read xml file for integer algebracis");
    /* read var info */
    read_value(mi.iAlg[i]["name"], &(modelData->integerVarsData[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->integerVarsData[i].info.name);
    read_value(mi.iAlg[i]["valueReference"], &(modelData->integerVarsData[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.id);
    read_value(mi.iAlg[i]["description"], &(modelData->integerVarsData[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.comment);
    read_value(mi.iAlg[i]["fileName"], (const char**)(void*)&(modelData->integerVarsData[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.filename);
    read_value(mi.iAlg[i]["startLine"], (modelica_integer*) &(modelData->integerVarsData[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.lineStart);
    read_value(mi.iAlg[i]["startColumn"], (modelica_integer*) &(modelData->integerVarsData[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.colStart);
    read_value(mi.iAlg[i]["endLine"], (modelica_integer*) &(modelData->integerVarsData[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.lineEnd);
    read_value(mi.iAlg[i]["endColumn"], (modelica_integer*) &(modelData->integerVarsData[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.colEnd);
    read_value(mi.iAlg[i]["fileWritable"], (modelica_integer*) &(modelData->integerVarsData[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->integerVarsData[i].info.name,modelData->integerVarsData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.iAlg[i]["start"], &(modelData->integerVarsData[i].attribute.start));
    DEBUG_INFO2(LOG_SOLVER, "read start-value for %s =  %ld from init file", modelData->integerVarsData[i].info.name, modelData->integerVarsData[i].attribute.start);
    read_value(mi.iAlg[i]["fixed"], (signed char*)&(modelData->integerVarsData[i].attribute.fixed));
    DEBUG_INFO2(LOG_SOLVER, "read fixed-value for %s = %s from init file", modelData->integerVarsData[i].info.name, modelData->integerVarsData[i].attribute.fixed?"true":"false");
    read_value(mi.iAlg[i]["min"], &(modelData->integerVarsData[i].attribute.min));
    DEBUG_INFO2(LOG_SOLVER, "read min-value for %s =  %ld from init file", modelData->integerVarsData[i].info.name, modelData->integerVarsData[i].attribute.min);
    read_value(mi.iAlg[i]["max"], &(modelData->integerVarsData[i].attribute.max));
    DEBUG_INFO2(LOG_SOLVER, "read max-value for %s =  %ld from init file", modelData->integerVarsData[i].info.name, modelData->integerVarsData[i].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->integerVarsData[i].info.name)]= i;
  }

  /* Read boolean variables static data */
  for(int i = 0; i < modelData->nVariablesBoolean; i++)
  {
    DEBUG_INFO(LOG_DEBUG, "Read xml file for boolean algebracis");
    /* read var info */
    read_value(mi.bAlg[i]["name"], &(modelData->booleanVarsData[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->booleanVarsData[i].info.name);
    read_value(mi.bAlg[i]["valueReference"], &(modelData->booleanVarsData[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.id);
    read_value(mi.bAlg[i]["description"], &(modelData->booleanVarsData[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.comment);
    read_value(mi.bAlg[i]["fileName"], (const char**)(void*)&(modelData->booleanVarsData[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.filename);
    read_value(mi.bAlg[i]["startLine"], (modelica_integer*) &(modelData->booleanVarsData[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.lineStart);
    read_value(mi.bAlg[i]["startColumn"], (modelica_integer*) &(modelData->booleanVarsData[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.colStart);
    read_value(mi.bAlg[i]["endLine"], (modelica_integer*) &(modelData->booleanVarsData[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.lineEnd);
    read_value(mi.bAlg[i]["endColumn"], (modelica_integer*) &(modelData->booleanVarsData[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.colEnd);
    read_value(mi.bAlg[i]["fileWritable"], (modelica_integer*) &(modelData->booleanVarsData[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->booleanVarsData[i].info.name,modelData->booleanVarsData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.bAlg[i]["start"], (signed char*)&(modelData->booleanVarsData[i].attribute.start));
    DEBUG_INFO2(LOG_SOLVER, "read start-value for %s = %s from init file", modelData->booleanVarsData[i].info.name, modelData->booleanVarsData[i].attribute.start?"true":"false");
    read_value(mi.bAlg[i]["fixed"],(signed char*)&(modelData->booleanVarsData[i].attribute.fixed));
    DEBUG_INFO2(LOG_SOLVER, "read fixed-value for %s = %s from init file", modelData->booleanVarsData[i].info.name, modelData->booleanVarsData[i].attribute.fixed?"true":"false");

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->booleanVarsData[i].info.name)]= i;
  }

  /* Read string variables static data */
  for(int i = 0; i < modelData->nVariablesString; i++) {

    DEBUG_INFO(LOG_DEBUG, "Read xml file for string algebracis");
    /* read var info */
    read_value(mi.sAlg[i]["name"], &(modelData->stringVarsData[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->stringVarsData[i].info.name);
    read_value(mi.sAlg[i]["valueReference"], &(modelData->stringVarsData[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.id);
    read_value(mi.sAlg[i]["description"], &(modelData->stringVarsData[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.comment);
    read_value(mi.sAlg[i]["fileName"], (const char**)(void*)&(modelData->stringVarsData[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.filename);
    read_value(mi.sAlg[i]["startLine"], (modelica_integer*) &(modelData->stringVarsData[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.lineStart);
    read_value(mi.sAlg[i]["startColumn"], (modelica_integer*) &(modelData->stringVarsData[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.colStart);
    read_value(mi.sAlg[i]["endLine"], (modelica_integer*) &(modelData->stringVarsData[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.lineEnd);
    read_value(mi.sAlg[i]["endColumn"], (modelica_integer*) &(modelData->stringVarsData[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.colEnd);
    read_value(mi.sAlg[i]["fileWritable"], (modelica_integer*) &(modelData->stringVarsData[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->stringVarsData[i].info.name,modelData->stringVarsData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.sAlg[i]["start"], &(modelData->stringVarsData[i].attribute.start));
    DEBUG_INFO2(LOG_SOLVER, "read for %s start-value %s from init file", modelData->stringVarsData[i].info.name, modelData->stringVarsData[i].attribute.start);

    /* create a mapping for Alias variable to get the correct index */
    mapAlias[(modelData->stringVarsData[i].info.name)]=i;
  }

  /*
   *  Real all parameter
   */
  /* Read Parameters static data */
  for(int i = 0; i < modelData->nParametersReal; i++)
  {
    DEBUG_INFO(LOG_DEBUG, "Read xml file for real parameters");
    /* read var info */
    read_value(mi.rPar[i]["name"], &(modelData->realParameterData[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->realParameterData[i].info.name);
    read_value(mi.rPar[i]["valueReference"], &(modelData->realParameterData[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.id);
    read_value(mi.rPar[i]["description"], &(modelData->realParameterData[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.comment);
    read_value(mi.rPar[i]["fileName"], (const char**)(void*)&(modelData->realParameterData[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.filename);
    read_value(mi.rPar[i]["startLine"], (modelica_integer*) &(modelData->realParameterData[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.lineStart);
    read_value(mi.rPar[i]["startColumn"], (modelica_integer*) &(modelData->realParameterData[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.colStart);
    read_value(mi.rPar[i]["endLine"], (modelica_integer*) &(modelData->realParameterData[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.lineEnd);
    read_value(mi.rPar[i]["endColumn"], (modelica_integer*) &(modelData->realParameterData[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.colEnd);
    read_value(mi.rPar[i]["fileWritable"], (modelica_integer*) &(modelData->realParameterData[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->realParameterData[i].info.name,modelData->realParameterData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.rPar[i]["start"], &(modelData->realParameterData[i].attribute.start));
    DEBUG_INFO2(LOG_SOLVER, "read start-value for %s =  %f from init file", modelData->realParameterData[i].info.name, modelData->realParameterData[i].attribute.start);
    read_value(mi.rPar[i]["fixed"],(signed char*)&(modelData->realParameterData[i].attribute.fixed));
    DEBUG_INFO2(LOG_SOLVER, "read fixed for %s = %s from init file", modelData->realParameterData[i].info.name, modelData->realParameterData[i].attribute.fixed?"true":"false");
    read_value(mi.rPar[i]["nominal"], &(modelData->realParameterData[i].attribute.nominal));
    DEBUG_INFO2(LOG_SOLVER, "read nominal for %s = %f from init file", modelData->realParameterData[i].info.name, modelData->realParameterData[i].attribute.nominal);
    read_value(mi.rPar[i]["min"], &(modelData->realParameterData[i].attribute.min));
    DEBUG_INFO2(LOG_SOLVER," read min-value for %s =  %g from init file", modelData->realParameterData[i].info.name, modelData->realParameterData[i].attribute.min);
    read_value(mi.rPar[i]["max"], &(modelData->realParameterData[i].attribute.max));
    DEBUG_INFO2(LOG_SOLVER," read max-value for %s =  %g from init file", modelData->realParameterData[i].info.name, modelData->realParameterData[i].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAliasParam[(modelData->realParameterData[i].info.name)]=i;
  }

  /* Read integer parameters static data */
  for(int i = 0; i < modelData->nParametersInteger; i++) {

    DEBUG_INFO(LOG_DEBUG, "Read xml file for integer parameters");
    /* read var info */
    read_value(mi.iPar[i]["name"], &(modelData->integerParameterData[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->integerParameterData[i].info.name);
    read_value(mi.iPar[i]["valueReference"], &(modelData->integerParameterData[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.id);
    read_value(mi.iPar[i]["description"], &(modelData->integerParameterData[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.comment);
    read_value(mi.iPar[i]["fileName"], (const char**)(void*)&(modelData->integerParameterData[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.filename);
    read_value(mi.iPar[i]["startLine"], (modelica_integer*) &(modelData->integerParameterData[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.lineStart);
    read_value(mi.iPar[i]["startColumn"], (modelica_integer*) &(modelData->integerParameterData[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.colStart);
    read_value(mi.iPar[i]["endLine"], (modelica_integer*) &(modelData->integerParameterData[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.lineEnd);
    read_value(mi.iPar[i]["endColumn"], (modelica_integer*) &(modelData->integerParameterData[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.colEnd);
    read_value(mi.iPar[i]["fileWritable"], (modelica_integer*) &(modelData->integerParameterData[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->integerParameterData[i].info.name,modelData->integerParameterData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.iPar[i]["start"], &(modelData->integerParameterData[i].attribute.start));
    DEBUG_INFO2(LOG_SOLVER, "read start-value for %s =  %ld from init file", modelData->integerParameterData[i].info.name, modelData->integerParameterData[i].attribute.start);
    read_value(mi.iPar[i]["fixed"], (signed char*)&(modelData->integerParameterData[i].attribute.fixed));
    DEBUG_INFO2(LOG_SOLVER, "read fixed-value for %s = %s from init file", modelData->integerParameterData[i].info.name, modelData->integerParameterData[i].attribute.fixed?"true":"false");
    read_value(mi.iPar[i]["min"], &(modelData->integerParameterData[i].attribute.min));
    DEBUG_INFO2(LOG_SOLVER, "read min-value for %s =  %ld from init file", modelData->integerParameterData[i].info.name, modelData->integerParameterData[i].attribute.min);
    read_value(mi.iPar[i]["max"], &(modelData->integerParameterData[i].attribute.max));
    DEBUG_INFO2(LOG_SOLVER, "read max-value for %s =  %ld from init file", modelData->integerParameterData[i].info.name, modelData->integerParameterData[i].attribute.max);

    /* create a mapping for Alias variable to get the correct index */
    mapAliasParam[(modelData->integerParameterData[i].info.name)]=i;
  }

  for(int i = 0; i < modelData->nParametersBoolean; i++) { /* Read boolean parameters static data */

    DEBUG_INFO(LOG_DEBUG, "Read xml file for boolean parameters");
    /* read var info */
    read_value(mi.bPar[i]["name"], &(modelData->booleanParameterData[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->booleanParameterData[i].info.name);
    read_value(mi.bPar[i]["valueReference"], &(modelData->booleanParameterData[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->booleanParameterData[i].info.name,modelData->booleanParameterData[i].info.id);
    read_value(mi.bPar[i]["description"], &(modelData->booleanParameterData[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->booleanParameterData[i].info.name,modelData->booleanParameterData[i].info.comment);
    read_value(mi.bPar[i]["fileName"], (const char**)(void*)&(modelData->booleanParameterData[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->booleanParameterData[i].info.name,modelData->booleanParameterData[i].info.info.filename);
    read_value(mi.bPar[i]["startLine"], (modelica_integer*) &(modelData->booleanParameterData[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->booleanParameterData[i].info.name,modelData->booleanParameterData[i].info.info.lineStart);
    read_value(mi.bPar[i]["startColumn"], (modelica_integer*) &(modelData->booleanParameterData[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->booleanParameterData[i].info.name,modelData->booleanParameterData[i].info.info.colStart);
    read_value(mi.bPar[i]["endLine"], (modelica_integer*) &(modelData->booleanParameterData[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->booleanParameterData[i].info.name,modelData->booleanParameterData[i].info.info.lineEnd);
    read_value(mi.bPar[i]["endColumn"], (modelica_integer*) &(modelData->booleanParameterData[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->booleanParameterData[i].info.name,modelData->booleanParameterData[i].info.info.colEnd);
    read_value(mi.bPar[i]["fileWritable"], (modelica_integer*) &(modelData->booleanParameterData[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->booleanParameterData[i].info.name,modelData->booleanParameterData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.bPar[i]["start"], (signed char*)&(modelData->booleanParameterData[i].attribute.start));
    DEBUG_INFO2(LOG_SOLVER, "read start-value for %s =  %s from init file", modelData->booleanParameterData[i].info.name, modelData->booleanParameterData[i].attribute.start?"true":"false");
    read_value(mi.bPar[i]["fixed"], (signed char*)&(modelData->booleanParameterData[i].attribute.fixed));
    DEBUG_INFO2(LOG_SOLVER, "read fixed for %s = %s from init file", modelData->booleanParameterData[i].info.name, modelData->booleanParameterData[i].attribute.fixed?"true":"false");

    /* create a mapping for Alias variable to get the correct index */
    mapAliasParam[(modelData->booleanParameterData[i].info.name)]=i;
  }

  for(int i = 0; i < modelData->nParametersString; i++) { /* Read string parameters static data */

    DEBUG_INFO(LOG_DEBUG, "Read xml file for string parameters");
    /* read var info */
    read_value(mi.sPar[i]["name"], &(modelData->stringParameterData[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->stringParameterData[i].info.name);
    read_value(mi.sPar[i]["valueReference"], &(modelData->stringParameterData[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.id);
    read_value(mi.sPar[i]["description"], &(modelData->stringParameterData[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.comment);
    read_value(mi.sPar[i]["fileName"], (const char**)(void*)&(modelData->stringParameterData[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.filename);
    read_value(mi.sPar[i]["startLine"], (modelica_integer*) &(modelData->stringParameterData[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.lineStart);
    read_value(mi.sPar[i]["startColumn"], (modelica_integer*) &(modelData->stringParameterData[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.colStart);
    read_value(mi.sPar[i]["endLine"], (modelica_integer*) &(modelData->stringParameterData[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.lineEnd);
    read_value(mi.sPar[i]["endColumn"], (modelica_integer*) &(modelData->stringParameterData[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.colEnd);
    read_value(mi.sPar[i]["fileWritable"], (modelica_integer*) &(modelData->stringParameterData[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->stringParameterData[i].info.name,modelData->stringParameterData[i].info.info.readonly);

    /* read var attribute */
    read_value(mi.sPar[i]["start"], &(modelData->stringParameterData[i].attribute.start));
    DEBUG_INFO2(LOG_SOLVER, "read for %s start-value %s from init file", modelData->stringParameterData[i].info.name, modelData->stringParameterData[i].attribute.start);

    /* create a mapping for Alias variable to get the correct index */
    mapAliasParam[(modelData->stringParameterData[i].info.name)]=i;
  }

  /*
   *  Real all alias vars
   */

  for(int i = 0; i < modelData->nAliasReal; i++) { /* Read string variables static data */

    DEBUG_INFO(LOG_DEBUG, "Read xml file for real alias vars");
    /* read var info */
    read_value(mi.rAli[i]["name"], &(modelData->realAlias[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->realAlias[i].info.name);
    read_value(mi.rAli[i]["valueReference"], &(modelData->realAlias[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",(modelData->realAlias[i].info.name),modelData->realAlias[i].info.id);
    read_value(mi.rAli[i]["description"], &(modelData->realAlias[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.comment);
    read_value(mi.rAli[i]["fileName"], (const char**)(void*)&(modelData->realAlias[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.filename);
    read_value(mi.rAli[i]["startLine"], (modelica_integer*) &(modelData->realAlias[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.lineStart);
    read_value(mi.rAli[i]["startColumn"], (modelica_integer*) &(modelData->realAlias[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.colStart);
    read_value(mi.rAli[i]["endLine"], (modelica_integer*) &(modelData->realAlias[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.lineEnd);
    read_value(mi.rAli[i]["endColumn"], (modelica_integer*) &(modelData->realAlias[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.colEnd);
    read_value(mi.rAli[i]["fileWritable"], (modelica_integer*) &(modelData->realAlias[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->realAlias[i].info.name,modelData->realAlias[i].info.info.readonly);

    string aliasTmp;
    read_value(mi.rAli[i]["alias"], &aliasTmp);
    if (aliasTmp.compare("negatedAlias") == 0){
      modelData->realAlias[i].negate = 1;
    }else{
      modelData->realAlias[i].negate = 0;
    }
    DEBUG_INFO2(LOG_DEBUG," read for %s negated %d from init file", modelData->realAlias[i].info.name, modelData->realAlias[i].negate);

    read_value(mi.rAli[i]["aliasVariable"], &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if (it != mapAlias.end()){
      modelData->realAlias[i].nameID  = (*it).second;
      modelData->realAlias[i].aliasType = 0;
    }else if (itParam != mapAliasParam.end()){
      modelData->realAlias[i].nameID  = (*itParam).second;
      modelData->realAlias[i].aliasType = 1;
    }else if (aliasTmp.compare("time")){
      modelData->realAlias[i].aliasType = 2;
    }else{
        THROW("Alias variable not found.");
    }
    DEBUG_INFO3(LOG_DEBUG," read for %s aliasID %d from %s from init file",
                modelData->realAlias[i].info.name,
                modelData->realAlias[i].nameID,
                modelData->realAlias[i].aliasType?((modelData->realAlias[i].aliasType==2)?"time":"real parameters"):"real variables");

  }

  /*
   *  integer all alias vars
   */
  for(int i = 0; i < modelData->nAliasInteger; i++) { /* Read string variables static data */

    DEBUG_INFO(LOG_DEBUG, "Read xml file for integer alias vars");
    /* read var info */
    read_value(mi.iAli[i]["name"], &(modelData->integerAlias[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->integerAlias[i].info.name);
    read_value(mi.iAli[i]["valueReference"], &(modelData->integerAlias[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.id);
    read_value(mi.iAli[i]["description"], &(modelData->integerAlias[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.comment);
    read_value(mi.iAli[i]["fileName"], (const char**)(void*)&(modelData->integerAlias[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.filename);
    read_value(mi.iAli[i]["startLine"], (modelica_integer*) &(modelData->integerAlias[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.lineStart);
    read_value(mi.iAli[i]["startColumn"], (modelica_integer*) &(modelData->integerAlias[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.colStart);
    read_value(mi.iAli[i]["endLine"], (modelica_integer*) &(modelData->integerAlias[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.lineEnd);
    read_value(mi.iAli[i]["endColumn"], (modelica_integer*) &(modelData->integerAlias[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.colEnd);
    read_value(mi.iAli[i]["fileWritable"], (modelica_integer*) &(modelData->integerAlias[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].info.info.readonly);

    string aliasTmp;
    read_value(mi.iAli[i]["alias"], &aliasTmp);
    if (aliasTmp.compare("negatedAlias") == 0){
      modelData->integerAlias[i].negate = 1;
    }else{
      modelData->integerAlias[i].negate = 0;
    }
    DEBUG_INFO2(LOG_DEBUG," read for %s negated %d from init file",modelData->integerAlias[i].info.name,modelData->integerAlias[i].negate);

    read_value(mi.iAli[i]["aliasVariable"], &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if (it != mapAlias.end()){
      modelData->integerAlias[i].nameID  = (*it).second;
      modelData->integerAlias[i].aliasType = 0;
    }else if (itParam != mapAliasParam.end()){
      modelData->integerAlias[i].nameID  = (*itParam).second;
      modelData->integerAlias[i].aliasType = 1;
    }else{
        THROW("Alias variable not found.");
    }
    DEBUG_INFO3(LOG_DEBUG," read for %s aliasID %d from %s from init file",
                modelData->integerAlias[i].info.name,
                modelData->integerAlias[i].nameID,
                modelData->integerAlias[i].aliasType?"integer parameters":"integer variables");

  }

  /*
   *  boolean all alias vars
   */
  for(int i = 0; i < modelData->nAliasBoolean; i++) { /* Read string variables static data */

    DEBUG_INFO(LOG_DEBUG, "Read xml file for boolean alias vars");
    /* read var info */
    read_value(mi.bAli[i]["name"], &(modelData->booleanAlias[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->booleanAlias[i].info.name);
    read_value(mi.bAli[i]["valueReference"], &(modelData->booleanAlias[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.id);
    read_value(mi.bAli[i]["description"], &(modelData->booleanAlias[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.comment);
    read_value(mi.bAli[i]["fileName"], (const char**)(void*)&(modelData->booleanAlias[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.filename);
    read_value(mi.bAli[i]["startLine"], (modelica_boolean*) &(modelData->booleanAlias[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.lineStart);
    read_value(mi.bAli[i]["startColumn"], (modelica_boolean*) &(modelData->booleanAlias[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.colStart);
    read_value(mi.bAli[i]["endLine"], (modelica_boolean*) &(modelData->booleanAlias[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.lineEnd);
    read_value(mi.bAli[i]["endColumn"], (modelica_boolean*) &(modelData->booleanAlias[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.colEnd);
    read_value(mi.bAli[i]["fileWritable"], (modelica_boolean*) &(modelData->booleanAlias[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->booleanAlias[i].info.name,modelData->booleanAlias[i].info.info.readonly);

    string aliasTmp;
    read_value(mi.bAli[i]["alias"], &aliasTmp);
    if (aliasTmp.compare("negatedAlias") == 0){
      modelData->booleanAlias[i].negate = 1;
    }else{
      modelData->booleanAlias[i].negate = 0;
    }
    DEBUG_INFO2(LOG_DEBUG," read for %s negated %d from init file", modelData->booleanAlias[i].info.name, modelData->booleanAlias[i].negate);

    read_value(mi.bAli[i]["aliasVariable"], &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if (it != mapAlias.end()){
      modelData->booleanAlias[i].nameID  = (*it).second;
      modelData->booleanAlias[i].aliasType = 0;
    }else if (itParam != mapAliasParam.end()){
      modelData->booleanAlias[i].nameID  = (*itParam).second;
      modelData->booleanAlias[i].aliasType = 1;
    }else{
        THROW("Alias variable not found.");
    }
    DEBUG_INFO3(LOG_DEBUG, " read for %s aliasID %d from %s from init file",
                modelData->booleanAlias[i].info.name,
                modelData->booleanAlias[i].nameID,
                modelData->booleanAlias[i].aliasType?"boolean parameters":"boolean variables");

  }


  /*
   *  string all alias vars
   */
  for(int i = 0; i < modelData->nAliasString; i++) { /* Read string variables static data */

    DEBUG_INFO(LOG_DEBUG, "Read xml file for string alias vars");
    /* read var info */
    read_value(mi.sAli[i]["name"], &(modelData->stringAlias[i].info.name));
    DEBUG_INFO1(LOG_DEBUG," read var %s from init file",modelData->stringAlias[i].info.name);
    read_value(mi.sAli[i]["valueReference"], &(modelData->stringAlias[i].info.id));
    DEBUG_INFO2(LOG_DEBUG," read for %s id %d from init file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.id);
    read_value(mi.sAli[i]["description"], &(modelData->stringAlias[i].info.comment));
    DEBUG_INFO2(LOG_DEBUG," read for %s comment %s from init file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.comment);
    read_value(mi.sAli[i]["fileName"], (const char**)(void*)&(modelData->stringAlias[i].info.info.filename));
    DEBUG_INFO2(LOG_DEBUG," read for %s filename %s from init file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.filename);
    read_value(mi.sAli[i]["startLine"], (modelica_string*) &(modelData->stringAlias[i].info.info.lineStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineStart %d from init file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.lineStart);
    read_value(mi.sAli[i]["startColumn"], (modelica_string*) &(modelData->stringAlias[i].info.info.colStart));
    DEBUG_INFO2(LOG_DEBUG," read for %s colStart %d from init file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.colStart);
    read_value(mi.sAli[i]["endLine"], (modelica_string*) &(modelData->stringAlias[i].info.info.lineEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s lineEnd %d from init file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.lineEnd);
    read_value(mi.sAli[i]["endColumn"], (modelica_string*) &(modelData->stringAlias[i].info.info.colEnd));
    DEBUG_INFO2(LOG_DEBUG," read for %s colEnd %d from init file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.colEnd);
    read_value(mi.sAli[i]["fileWritable"], (modelica_string*) &(modelData->stringAlias[i].info.info.readonly));
    DEBUG_INFO2(LOG_DEBUG," read for %s readonly %d from init file",modelData->stringAlias[i].info.name,modelData->stringAlias[i].info.info.readonly);

    string aliasTmp;
    read_value(mi.sAli[i]["alias"], &aliasTmp);
    if (aliasTmp.compare("negatedAlias") == 0){
      modelData->stringAlias[i].negate = 1;
    }else{
      modelData->stringAlias[i].negate = 0;
    }
    DEBUG_INFO2(LOG_DEBUG, " read for %s negated %d from init file", modelData->stringAlias[i].info.name, modelData->stringAlias[i].negate);

    read_value(mi.sAli[i]["aliasVariable"], &aliasTmp);

    it = mapAlias.find(aliasTmp);
    itParam = mapAliasParam.find(aliasTmp);

    if (it != mapAlias.end()){
      modelData->stringAlias[i].nameID  = (*it).second;
      modelData->stringAlias[i].aliasType = 0;
    }else if (itParam != mapAliasParam.end()){
      modelData->stringAlias[i].nameID  = (*itParam).second;
      modelData->stringAlias[i].aliasType = 1;
    }else{
        THROW("Alias variable not found.");
    }
    DEBUG_INFO3(LOG_DEBUG," read for %s aliasID %d from %s from init file",
                modelData->stringAlias[i].info.name,
                modelData->stringAlias[i].nameID,
                modelData->stringAlias[i].aliasType?"string parameters":"string variables");

  }



  delete filename;
  XML_ParserFree(parser);
  fclose(file);
}

inline void read_value(string s, string *str)
{
  *str = s;
}


inline void read_value(string s, const char **str)
{
  if (str == NULL) {
    WARNING("error read_value, no data allocated for storing string");
    return;
  }
  *str = strdup(s.c_str());
}

inline void read_value(string s, double *res)
{
  if (s.compare("true") == 0) {
    *res = 1.0;
  }
  else if (s.compare("false") == 0) {
    *res = 0.0;
  }
  else {
    *res = atof(s.c_str());
  }
}

inline void read_value(string s, signed char *res)
{
  if (s.compare("true") == 0) {
    *res = 1;
  }
  else if (s.compare("false") == 0) {
    *res = 0;
  }
  else {
    *res = 0;
  }
}

inline void read_value(string s, modelica_integer *res)
{
  if (s.compare("true") == 0) {
    *res = 1;
  }
  else if (s.compare("false") == 0) {
    *res = 0;
  }
  else {
    *res = atol(s.c_str());
  }
}

inline void read_value(string s, int *res)
{
  if (s.compare("true") == 0) {
    *res = 1;
  }
  else if (s.compare("false") == 0) {
    *res = 0;
  }
  else {
    *res = atoi(s.c_str());
  }
}

