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
// maybe use a map below {"rSta" -> omc_ModelVariables}
// typedef map < string, omc_ModelVariables > omc_ModelVariablesClassified;

/* structure used to collect data from the xml input file */
typedef struct omc_ModelInput
{
  omc_ModelDescription  md; // model description
  omc_DefaultExperiment de; // default experiment

  omc_ModelVariables    rSta; // states
  omc_ModelVariables    rDer; // derivatives
  omc_ModelVariables    rAlg; // algebraic
  omc_ModelVariables    rPar; // parameters
  omc_ModelVariables    rAli; // aliases

  omc_ModelVariables    iAlg; // int algebraic
  omc_ModelVariables    iPar; // int parameters
  omc_ModelVariables    iAli; // int aliases

  omc_ModelVariables    bAlg; // bool algebraic
  omc_ModelVariables    bPar; // bool parameters
  omc_ModelVariables    bAli; // bool aliases

  omc_ModelVariables    sAlg; // string algebraic
  omc_ModelVariables    sPar; // string parameters
  omc_ModelVariables    sAli; // string aliases

  // these two we need to know to be able to add
  // the stuff in <Real ... />, <String ... /> to
  // the correct variable in the correct map
  int                   lastCI; // index
  omc_ModelVariables*   lastCT; // type (classification)
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

  // handle fmiModelDescription
  if (!strcmp(name, "fmiModelDescription"))
  {
    for (i = 0; attr[i]; i += 2)
    {
      mi->md[attr[i]] = attr[i + 1];
    }
    return;
  }
  // handle DefaultExperiment
  if (!strcmp(name, "DefaultExperiment"))
  {
    for (i = 0; attr[i]; i += 2)
    {
      mi->de[attr[i]] = attr[i + 1];
    }
    return;
  }

  // handle ScalarVariable
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
    // fetch the class index/type
    ci = v["classIndex"];
    ct = v["classType"];
    // transform to int
    mi->lastCI = atoi(ci.c_str());

    // which one of the classifications?
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
      cerr << "simulation_input_xml.cpp: error reading the xml file, found unknown class: "
           << ct << " for variable: " << v["name"] << endl;
      EXIT(1);
    }

    // add the ScalarVariable map to the correct map!
    (*mi->lastCT)[mi->lastCI] = v;
    return;
  }
  // handle Real/Integer/Boolean/String
  if (!strcmp(name, "Real") || !strcmp(name, "Integer") || !strcmp(name, "Boolean") || !strcmp(name, "String"))
  {
    // add keys/value to the last variable
    for (i = 0; attr[i]; i += 2)
    {
      // add more key/value pairs to the last variable
      ((*mi->lastCT)[mi->lastCI])[attr[i]] = attr[i + 1];
    }
    ((*mi->lastCT)[mi->lastCI])["variableType"] = name;
    return;
  }
  // anything else, we don't handle!
}

static void XMLCALL
endElement(void *userData, const char *name)
{
  // do nothing!
}

/* \brief
 *  Reads initial values from a text file.
 *
 *  The textfile should be given as argument to the main function using
 *  the -f file flag.
 */
 void read_input_xml(int argc, char **argv,
                     DATA *simData,
                     MODEL_DATA* modelData,
                     SIMULATION_INFO* simulationData,
                     SOLVER_INFO* solverInfo,
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

  // read the filename from the command line (if any)
  filename=(string*)getFlagValue("f",argc,argv);
  // no file given on the command line? use the default
  if (filename == NULL) {
    filename = new string(string(simData->modelFilePrefix)+"_init.xml");  // model_name defined in generated code for model.
  }
  // open the file and fail on error. we open it read-write to be sure other processes can overwrite it
  file = fopen(filename->c_str(), "r");
  if (!file) {
	  THROW("simulation_input_xml.cpp: Error: can not read file %s as indata to simulation.",filename->c_str());
    delete filename;
    EXIT(-1);
  }
  // create the XML parser
  parser = XML_ParserCreate(NULL);
  if (!parser) {
      cerr << "simulation_input_xml.cpp: Error: couldn't allocate memory for the XML parser!" << endl;
      delete filename;
      fclose(file);
      EXIT(-1);
  }
  // set our user data
  XML_SetUserData(parser, &mi);
  // set the handlers for start/end of element.
  XML_SetElementHandler(parser, startElement, endElement);
  do
  {
    size_t len = fread(buf, 1, sizeof(buf), file);
    done = len < sizeof(buf);
    if (XML_Parse(parser, buf, len, done) == XML_STATUS_ERROR)
    {
      fprintf(stderr,
              "simulation_input_xml.cpp: Error: failed to read the XML file %s: %s at line %lu\n",
              filename->c_str(),
              XML_ErrorString(XML_GetErrorCode(parser)),
              XML_GetCurrentLineNumber(parser));
      delete filename;
      XML_ParserFree(parser);
      fclose(file);
      EXIT(1);
    }
  } while (!done);

  // now we should have all the data inside omc_ModelInput mi.

  // first, check the modelGUID!
  // TODO! FIXME! THIS SEEMS TO FAIL!
  // ARE WE READING THE OLD XML FILE??

  if (strcmp(simData->modelGUID, mi.md["guid"].c_str()))
  {
    cerr << "Error, the GUID: " << mi.md["guid"].c_str() << " from input data file: " << filename->c_str()
         << " does not match the GUID compiled in the model: " << simData->modelGUID
         << endl;
    delete filename;
    XML_ParserFree(parser);
    fclose(file);
    EXIT(1);
  }


  string *methodc = (string*)getFlagValue("m",argc,argv);

  // read all the DefaultExperiment values
  read_value(mi.de["startTime"],start);
  simulationData->startTime = *start;
  DEBUG_INFO(LV_SOLVER,"read start = %f from init file",*start);
  read_value(mi.de["stopTime"],stop);
  simulationData->stopTime = *stop;
  DEBUG_INFO(LV_SOLVER," read stop = %f from init file",*stop);
  read_value(mi.de["stepSize"],stepSize);
  simulationData->stepSize = *stepSize;
  DEBUG_INFO(LV_SOLVER," read step = %f from init file",*stepSize);
  read_value(mi.de["tolerance"],tolerance);
  simulationData->tolerance = *tolerance;
  DEBUG_INFO(LV_SOLVER," read tolerance = %f from init file",*tolerance);

  if (methodc == NULL)
  {
    read_value(mi.de["solver"], method);
    simulationData->solverMethod = method->c_str();
    DEBUG_INFO(LV_SOLVER," read solver method = %s from init file",method->c_str());
  }
  else
  {
    string tmp;
    read_value(mi.de["solver"],&tmp);
    simulationData->solverMethod = methodc->c_str();
    DEBUG_INFO(LV_SOLVER," read solver method = %s from command line",methodc->c_str());
  }
  read_value(mi.de["outputFormat"],outputFormat);
  simulationData->outputFormat = outputFormat->c_str();
  DEBUG_INFO(LV_SOLVER," read outputFormat = %s from init file",outputFormat->c_str());
  read_value(mi.de["variableFilter"],variableFilter);
  simulationData->variableFilter = variableFilter->c_str();
  DEBUG_INFO(LV_SOLVER," read outputFormat = %s from init file",variableFilter->c_str());

  // set the step size
  globalData->current_stepsize = *stepSize;
  if (stepSize < 0) { // stepSize < 0 => Automatic number of outputs
    *outputSteps = -1;
  } else {
    // Calculate outputSteps from stepSize, start and stop
    *outputSteps = (long)(int(*stop-*start) /(*stepSize));
  }
  simulationData->numSteps = *outputSteps;

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

  if (nxchk != simData->nStates || nychk != simData->nAlgebraic || npchk != simData->nParameters
      || npintchk != simData->intVariables.nParameters || nyintchk != simData->intVariables.nAlgebraic
      || npboolchk != simData->boolVariables.nParameters || nyboolchk != simData->boolVariables.nAlgebraic
      || npstrchk != simData->stringVariables.nParameters || nystrchk != simData->stringVariables.nAlgebraic) {
    cerr << "Error, input data file does not match model." << endl;
    cerr << "nx in initfile: " << nxchk << " from model code :" << simData->nStates << endl;
    cerr << "ny in initfile: " << nychk << " from model code :" << simData->nAlgebraic << endl;
    cerr << "np in initfile: " << npchk << " from model code :" << simData->nParameters << endl;
    cerr << "npint in initfile: " << npintchk << " from model code: " << simData->intVariables.nParameters << endl;
    cerr << "nyint in initfile: " << nyintchk << " from model code: " << simData->intVariables.nAlgebraic <<  endl;
    cerr << "npbool in initfile: " << npboolchk << " from model code: " << simData->boolVariables.nParameters << endl;
    cerr << "nybool in initfile: " << nyboolchk << " from model code: " << simData->boolVariables.nAlgebraic <<  endl;
    cerr << "npstr in initfile: " << npstrchk << " from model code: " << simData->stringVariables.nParameters << endl;
    cerr << "nystr in initfile: " << nystrchk << " from model code: " << simData->stringVariables.nAlgebraic <<  endl;
    delete filename;
    XML_ParserFree(parser);
    fclose(file);
    EXIT(-1);
  }

  for(int i = 0; i < simData->nStates; i++) { // Read x initial values
    read_value(mi.rSta[i]["start"],&simData->states[i]);
    DEBUG_INFO(LV_SOLVER,"read %s  =  %f from init file",simData->statesNames[i].name, simData->states[i]);
  }

  for(int i = 0; i < simData->nStates; i++) { // Read der(x) initial values
    read_value(mi.rDer[i]["start"],&simData->statesDerivatives[i]);
    DEBUG_INFO(LV_SOLVER,"read %s  =  %f from init file",simData->stateDerivativesNames[i].name, simData->statesDerivatives[i]);
  }

  for(int i = 0; i < simData->nAlgebraic; i++) { // Read y initial values
    read_value(mi.rAlg[i]["start"],&simData->algebraics[i]);
    DEBUG_INFO(LV_SOLVER," read %s  =  %f from init file",simData->algebraicsNames[i].name, simData->algebraics[i]);
  }

  for(int i = 0; i < simData->nParameters; i++) { // Read parameter values
    read_value(mi.rPar[i]["start"],&simData->parameters[i]);
    DEBUG_INFO(LV_SOLVER," read %s  =  %f from init file",simData->parametersNames[i].name, simData->parameters[i]);
  }

  for(int i = 0; i < simData->intVariables.nParameters; i++) { // Read parameter values
    read_value(mi.iPar[i]["start"],&simData->intVariables.parameters[i]);
    DEBUG_INFO(LV_SOLVER," read %s  =  %ld from init file",simData->int_param_names[i].name, simData->intVariables.parameters[i]);
  }

  for(int i = 0; i < simData->intVariables.nAlgebraic; i++) { // Read parameter values
    read_value(mi.iAlg[i]["start"],&simData->intVariables.algebraics[i]);
    DEBUG_INFO(LV_SOLVER," read %s  =  %ld from init file",simData->int_alg_names[i].name, simData->intVariables.algebraics[i]);
  }

  for(int i = 0; i < simData->boolVariables.nParameters; i++) { // Read parameter values
    read_value(mi.bPar[i]["start"],&simData->boolVariables.parameters[i]);
    DEBUG_INFO(LV_SOLVER," read %s  =  %d from init file",simData->bool_param_names[i].name, simData->boolVariables.parameters[i]);
  }

  for(int i = 0; i < simData->boolVariables.nAlgebraic; i++) { // Read parameter values
    read_value(mi.bAlg[i]["start"],&simData->boolVariables.algebraics[i]);
    DEBUG_INFO(LV_SOLVER," read %s  =  %d from init file",simData->bool_alg_names[i].name, simData->boolVariables.algebraics[i]);
  }

  for(int i=0; i < simData->stringVariables.nParameters; i++) { // Read string parameter values
    read_value(mi.sPar[i]["start"],&(simData->stringVariables.parameters[i]));
    DEBUG_INFO(LV_SOLVER," read %s  =  %s from init file",simData->string_param_names[i].name, simData->stringVariables.parameters[i]);
  }

  for(int i=0; i < simData->stringVariables.nAlgebraic; i++) { // Read string algebraic values
    read_value(mi.sAlg[i]["start"],&simData->stringVariables.algebraics[i]);
    DEBUG_INFO(LV_SOLVER," read %s  =  %s from init file",simData->string_alg_names[i].name, simData->stringVariables.algebraics[i]);
  }
  DEBUG_INFO(LV_SOLVER,"Read parameter data from file %s",filename->c_str());


  /* Read all static data from File for every variable */
  for(int i = 0; i < modelData->nStates; i++) { // Read states static data

	  DEBUG_INFO(LV_DEBUG, "Read xml file for states");
	  /* read var info */
      read_value(mi.rSta[i]["name"],&(modelData->realData[i].info.name));
      DEBUG_INFO(LV_DEBUG," read var %s from init file",modelData->realData[i].info.name);
      read_value(mi.rSta[i]["valueReference"],&(modelData->realData[i].info.id));
      DEBUG_INFO(LV_DEBUG," read for %s id %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.id);
      read_value(mi.rSta[i]["description"],&(modelData->realData[i].info.comment));
      DEBUG_INFO(LV_DEBUG," read for %s description \"%s\" from init file",modelData->realData[i].info.name,modelData->realData[i].info.comment);
      read_value(mi.rSta[i]["fileName"], (const char**) (void*)&(modelData->realData[i].info.info.filename));
      DEBUG_INFO(LV_DEBUG," read for %s filename %s from init file",modelData->realData[i].info.name, modelData->realData[i].info.info.filename);
	  read_value(mi.rSta[i]["startLine"],(modelica_integer*)&(modelData->realData[i].info.info.lineStart));
      DEBUG_INFO(LV_DEBUG," read for %s lineStart %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.info.lineStart);
      read_value(mi.rSta[i]["startColumn"],(modelica_integer*)&(modelData->realData[i].info.info.colStart));
      DEBUG_INFO(LV_DEBUG," read for %s colStart %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.info.colStart);
      read_value(mi.rSta[i]["endLine"],(modelica_integer*)&(modelData->realData[i].info.info.lineEnd));
      DEBUG_INFO(LV_DEBUG," read for %s lineEnd %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.info.lineEnd);
      read_value(mi.rSta[i]["endColumn"],(modelica_integer*)&(modelData->realData[i].info.info.colEnd));
      DEBUG_INFO(LV_DEBUG," read for %s colEnd %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.info.colEnd);
      read_value(mi.rSta[i]["fileWritable"],(modelica_integer*)&(modelData->realData[i].info.info.readonly));
      DEBUG_INFO(LV_DEBUG," read for %s readonly %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.info.readonly);

      /* read var attribute */
	  read_value(mi.rSta[i]["start"],&(modelData->realData[i].attribute.start));
	  DEBUG_INFO(LV_SOLVER," read start-value for %s =  %f from init file",modelData->realData[i].info.name,modelData->realData[i].attribute.start);
	  read_value(mi.rSta[i]["fixed"],(signed char*)&(modelData->realData[i].attribute.fixed));
	  DEBUG_INFO(LV_SOLVER," read fixed for %s = %s from init file",modelData->realData[i].info.name,(modelData->realData[i].attribute.fixed)?"true":"false");
  }

  for(int i = 0; i < modelData->nStates; i++) { // Read stateDerivatives static data

	  DEBUG_INFO(LV_DEBUG, "Read xml file for stateDerivatives");
	  /* read var info */
      read_value(mi.rDer[i]["name"], &(modelData->realData[modelData->nStates+i].info.name));
      DEBUG_INFO(LV_DEBUG," read var %s from init file",modelData->realData[modelData->nStates+i].info.name);
      read_value(mi.rDer[i]["valueReference"], &(modelData->realData[modelData->nStates+i].info.id));
      DEBUG_INFO(LV_DEBUG," read for %s id %d from init file",modelData->realData[modelData->nStates+i].info.name,modelData->realData[modelData->nStates+i].info.id);
      read_value(mi.rDer[i]["description"], &(modelData->realData[modelData->nStates+i].info.comment));
      DEBUG_INFO(LV_DEBUG," read for %s comment %s from init file",modelData->realData[modelData->nStates+i].info.name,modelData->realData[modelData->nStates+i].info.comment);
      read_value(mi.rDer[i]["fileName"], (const char**)(void*)&(modelData->realData[modelData->nStates+i].info.info.filename));
      DEBUG_INFO(LV_DEBUG," read for %s filename %s from init file",modelData->realData[modelData->nStates+i].info.name,modelData->realData[modelData->nStates+i].info.info.filename);
      read_value(mi.rDer[i]["startLine"], (modelica_integer*) &(modelData->realData[modelData->nStates+i].info.info.lineStart));
      DEBUG_INFO(LV_DEBUG," read for %s lineStart %d from init file",modelData->realData[modelData->nStates+i].info.name,modelData->realData[modelData->nStates+i].info.info.lineStart);
      read_value(mi.rDer[i]["startColumn"], (modelica_integer*) &(modelData->realData[modelData->nStates+i].info.info.colStart));
      DEBUG_INFO(LV_DEBUG," read for %s colStart %d from init file",modelData->realData[modelData->nStates+i].info.name,modelData->realData[modelData->nStates+i].info.info.colStart);
      read_value(mi.rDer[i]["endLine"], (modelica_integer*) &(modelData->realData[modelData->nStates+i].info.info.lineEnd));
      DEBUG_INFO(LV_DEBUG," read for %s lineEnd %d from init file",modelData->realData[modelData->nStates+i].info.name,modelData->realData[modelData->nStates+i].info.info.lineEnd);
      read_value(mi.rDer[i]["endColumn"], (modelica_integer*) &(modelData->realData[modelData->nStates+i].info.info.colEnd));
      DEBUG_INFO(LV_DEBUG," read for %s colEnd %d from init file",modelData->realData[modelData->nStates+i].info.name,modelData->realData[modelData->nStates+i].info.info.colEnd);
      read_value(mi.rDer[i]["fileWritable"], (modelica_integer*) &(modelData->realData[modelData->nStates+i].info.info.readonly));
      DEBUG_INFO(LV_DEBUG," read for %s readonly %d from init file",modelData->realData[modelData->nStates+i].info.name,modelData->realData[modelData->nStates+i].info.info.readonly);

      /* read var attribute */
	  read_value(mi.rDer[i]["start"],&(modelData->realData[modelData->nStates+i].attribute.start));
	  DEBUG_INFO(LV_SOLVER," read start-value for %s =  %f from init file",modelData->realData[modelData->nStates+i].info.name,modelData->realData[modelData->nStates+i].attribute.start);
	  read_value(mi.rDer[i]["fixed"],(signed char*)&(modelData->realData[modelData->nStates+i].attribute.fixed));
	  DEBUG_INFO(LV_SOLVER," read fixed for %s = %s from init file",modelData->realData[modelData->nStates+i].info.name,(modelData->realData[modelData->nStates+i].attribute.fixed)?"true":"false");
  }


  for(int i = 0; i < (modelData->nVariablesReal - 2*modelData->nStates); i++) { // Read stateDerivatives static data

	  int j = 2*modelData->nStates + i;
	  DEBUG_INFO(LV_DEBUG, "Read xml file for real algebracis");
	  /* read var info */
      read_value(mi.rAlg[i]["name"], &(modelData->realData[j].info.name));
      DEBUG_INFO(LV_DEBUG," read var %s from init file",modelData->realData[j].info.name);
      read_value(mi.rAlg[i]["valueReference"], &(modelData->realData[j].info.id));
      DEBUG_INFO(LV_DEBUG," read for %s id %d from init file",modelData->realData[j].info.name,modelData->realData[j].info.id);
      read_value(mi.rAlg[i]["description"], &(modelData->realData[j].info.comment));
      DEBUG_INFO(LV_DEBUG," read for %s comment %s from init file",modelData->realData[j].info.name,modelData->realData[j].info.comment);
      read_value(mi.rAlg[i]["fileName"], (const char**)(void*)&(modelData->realData[j].info.info.filename));
      DEBUG_INFO(LV_DEBUG," read for %s filename %s from init file",modelData->realData[j].info.name,modelData->realData[j].info.info.filename);
      read_value(mi.rAlg[i]["startLine"], (modelica_integer*) &(modelData->realData[j].info.info.lineStart));
      DEBUG_INFO(LV_DEBUG," read for %s lineStart %d from init file",modelData->realData[j].info.name,modelData->realData[j].info.info.lineStart);
      read_value(mi.rAlg[i]["startColumn"], (modelica_integer*) &(modelData->realData[j].info.info.colStart));
      DEBUG_INFO(LV_DEBUG," read for %s colStart %d from init file",modelData->realData[j].info.name,modelData->realData[j].info.info.colStart);
      read_value(mi.rAlg[i]["endLine"], (modelica_integer*) &(modelData->realData[j].info.info.lineEnd));
      DEBUG_INFO(LV_DEBUG," read for %s lineEnd %d from init file",modelData->realData[j].info.name,modelData->realData[j].info.info.lineEnd);
      read_value(mi.rAlg[i]["endColumn"], (modelica_integer*) &(modelData->realData[j].info.info.colEnd));
      DEBUG_INFO(LV_DEBUG," read for %s colEnd %d from init file",modelData->realData[j].info.name,modelData->realData[j].info.info.colEnd);
      read_value(mi.rAlg[i]["fileWritable"], (modelica_integer*) &(modelData->realData[j].info.info.readonly));
      DEBUG_INFO(LV_DEBUG," read for %s readonly %d from init file",modelData->realData[j].info.name,modelData->realData[j].info.info.readonly);

      /* read var attribute */
	  read_value(mi.rAlg[i]["start"],&(modelData->realData[j].attribute.start));
	  DEBUG_INFO(LV_SOLVER," read start-value for %s =  %f from init file",modelData->realData[j].info.name,modelData->realData[j].attribute.start);
	  read_value(mi.rAlg[i]["fixed"],(signed char*)&(modelData->realData[j].attribute.fixed));
	  DEBUG_INFO(LV_SOLVER," read fixed for %s = %s from init file",modelData->realData[j].info.name,modelData->realData[j].attribute.fixed?"true":"false");
  }


  for(int i = 0; i < modelData->nVariablesInteger; i++) { // Read stateDerivatives static data

	  DEBUG_INFO(LV_DEBUG, "Read xml file for integer algebracis");
	  /* read var info */
      read_value(mi.iAlg[i]["name"], &(modelData->integerData[i].info.name));
      DEBUG_INFO(LV_DEBUG," read var %s from init file",modelData->integerData[i].info.name);
      read_value(mi.iAlg[i]["valueReference"], &(modelData->integerData[i].info.id));
      DEBUG_INFO(LV_DEBUG," read for %s id %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.id);
      read_value(mi.iAlg[i]["description"], &(modelData->integerData[i].info.comment));
      DEBUG_INFO(LV_DEBUG," read for %s comment %s from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.comment);
      read_value(mi.iAlg[i]["fileName"], (const char**)(void*)&(modelData->integerData[i].info.info.filename));
      DEBUG_INFO(LV_DEBUG," read for %s filename %s from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.filename);
      read_value(mi.iAlg[i]["startLine"], (modelica_integer*) &(modelData->integerData[i].info.info.lineStart));
      DEBUG_INFO(LV_DEBUG," read for %s lineStart %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.lineStart);
      read_value(mi.iAlg[i]["startColumn"], (modelica_integer*) &(modelData->integerData[i].info.info.colStart));
      DEBUG_INFO(LV_DEBUG," read for %s colStart %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.colStart);
      read_value(mi.iAlg[i]["endLine"], (modelica_integer*) &(modelData->integerData[i].info.info.lineEnd));
      DEBUG_INFO(LV_DEBUG," read for %s lineEnd %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.lineEnd);
      read_value(mi.iAlg[i]["endColumn"], (modelica_integer*) &(modelData->integerData[i].info.info.colEnd));
      DEBUG_INFO(LV_DEBUG," read for %s colEnd %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.colEnd);
      read_value(mi.iAlg[i]["fileWritable"], (modelica_integer*) &(modelData->integerData[i].info.info.readonly));
      DEBUG_INFO(LV_DEBUG," read for %s readonly %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.readonly);

      /* read var attribute */
	  read_value(mi.iAlg[i]["start"],&(modelData->integerData[i].attribute.start));
	  DEBUG_INFO(LV_SOLVER," read start-value for %s =  %ld from init file",modelData->integerData[i].info.name,modelData->integerData[i].attribute.start);
	  read_value(mi.iAlg[i]["fixed"],(signed char*)&(modelData->integerData[i].attribute.fixed));
	  DEBUG_INFO(LV_SOLVER," read fixed for %s = %s from init file",modelData->integerData[i].info.name,modelData->integerData[i].attribute.fixed?"true":"false");
  }

  for(int i = 0; i < modelData->nVariablesBoolean; i++) { // Read stateDerivatives static data

	  DEBUG_INFO(LV_DEBUG, "Read xml file for boolean algebracis");
	  /* read var info */
      read_value(mi.bAlg[i]["name"], &(modelData->booleanData[i].info.name));
      DEBUG_INFO(LV_DEBUG," read var %s from init file",modelData->booleanData[i].info.name);
      read_value(mi.bAlg[i]["valueReference"], &(modelData->booleanData[i].info.id));
      DEBUG_INFO(LV_DEBUG," read for %s id %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.id);
      read_value(mi.bAlg[i]["description"], &(modelData->booleanData[i].info.comment));
      DEBUG_INFO(LV_DEBUG," read for %s comment %s from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.comment);
      read_value(mi.bAlg[i]["fileName"], (const char**)(void*)&(modelData->booleanData[i].info.info.filename));
      DEBUG_INFO(LV_DEBUG," read for %s filename %s from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.filename);
      read_value(mi.bAlg[i]["startLine"], (modelica_integer*) &(modelData->booleanData[i].info.info.lineStart));
      DEBUG_INFO(LV_DEBUG," read for %s lineStart %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.lineStart);
      read_value(mi.bAlg[i]["startColumn"], (modelica_integer*) &(modelData->booleanData[i].info.info.colStart));
      DEBUG_INFO(LV_DEBUG," read for %s colStart %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.colStart);
      read_value(mi.bAlg[i]["endLine"], (modelica_integer*) &(modelData->booleanData[i].info.info.lineEnd));
      DEBUG_INFO(LV_DEBUG," read for %s lineEnd %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.lineEnd);
      read_value(mi.bAlg[i]["endColumn"], (modelica_integer*) &(modelData->booleanData[i].info.info.colEnd));
      DEBUG_INFO(LV_DEBUG," read for %s colEnd %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.colEnd);
      read_value(mi.bAlg[i]["fileWritable"], (modelica_integer*) &(modelData->booleanData[i].info.info.readonly));
      DEBUG_INFO(LV_DEBUG," read for %s readonly %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.readonly);

      /* read var attribute */
	  read_value(mi.bAlg[i]["start"],&(modelData->booleanData[i].attribute.start));
	  DEBUG_INFO(LV_SOLVER," read start-value for %s =  %c from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].attribute.start);
	  read_value(mi.bAlg[i]["fixed"],(signed char*)&(modelData->booleanData[i].attribute.fixed));
	  DEBUG_INFO(LV_SOLVER," read fixed for %s = %s from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].attribute.fixed?"true":"false");
  }

  for(int i = 0; i < modelData->nVariablesString; i++) { // Read stateDerivatives static data

	  DEBUG_INFO(LV_DEBUG, "Read xml file for string algebracis");
	  /* read var info */
      read_value(mi.sAlg[i]["name"], &(modelData->stringData[i].info.name));
      DEBUG_INFO(LV_DEBUG," read var %s from init file",modelData->stringData[i].info.name);
      read_value(mi.sAlg[i]["valueReference"], &(modelData->stringData[i].info.id));
      DEBUG_INFO(LV_DEBUG," read for %s id %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.id);
      read_value(mi.sAlg[i]["description"], &(modelData->stringData[i].info.comment));
      DEBUG_INFO(LV_DEBUG," read for %s comment %s from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.comment);
      read_value(mi.sAlg[i]["fileName"], (const char**)(void*)&(modelData->stringData[i].info.info.filename));
      DEBUG_INFO(LV_DEBUG," read for %s filename %s from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.filename);
      read_value(mi.sAlg[i]["startLine"], (modelica_integer*) &(modelData->stringData[i].info.info.lineStart));
      DEBUG_INFO(LV_DEBUG," read for %s lineStart %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.lineStart);
      read_value(mi.sAlg[i]["startColumn"], (modelica_integer*) &(modelData->stringData[i].info.info.colStart));
      DEBUG_INFO(LV_DEBUG," read for %s colStart %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.colStart);
      read_value(mi.sAlg[i]["endLine"], (modelica_integer*) &(modelData->stringData[i].info.info.lineEnd));
      DEBUG_INFO(LV_DEBUG," read for %s lineEnd %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.lineEnd);
      read_value(mi.sAlg[i]["endColumn"], (modelica_integer*) &(modelData->stringData[i].info.info.colEnd));
      DEBUG_INFO(LV_DEBUG," read for %s colEnd %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.colEnd);
      read_value(mi.sAlg[i]["fileWritable"], (modelica_integer*) &(modelData->stringData[i].info.info.readonly));
      DEBUG_INFO(LV_DEBUG," read for %s readonly %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.readonly);

      /* read var attribute */
	  read_value(mi.sAlg[i]["start"],&(modelData->stringData[i].attribute.start));
	  DEBUG_INFO(LV_SOLVER," read for %s start-value %s from init file",modelData->stringData[i].info.name,modelData->stringData[i].attribute.start);
  }

  /*
   *  Real all parameter
   */
  for(int i = 0; i < modelData->nParametersReal; i++) { // Read Parameters static data

	  DEBUG_INFO(LV_DEBUG, "Read xml file for real parameters");
	  /* read var info */
      read_value(mi.rPar[i]["name"], &(modelData->realData[i].info.name));
      DEBUG_INFO(LV_DEBUG," read var %s from init file",modelData->realData[i].info.name);
      read_value(mi.rPar[i]["valueReference"], &(modelData->realData[i].info.id));
      DEBUG_INFO(LV_DEBUG," read for %s id %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.id);
      read_value(mi.rPar[i]["description"], &(modelData->realData[i].info.comment));
      DEBUG_INFO(LV_DEBUG," read for %s comment %s from init file",modelData->realData[i].info.name,modelData->realData[i].info.comment);
      read_value(mi.rPar[i]["fileName"], (const char**)(void*)&(modelData->realData[i].info.info.filename));
      DEBUG_INFO(LV_DEBUG," read for %s filename %s from init file",modelData->realData[i].info.name,modelData->realData[i].info.info.filename);
      read_value(mi.rPar[i]["startLine"], (modelica_integer*) &(modelData->realData[i].info.info.lineStart));
      DEBUG_INFO(LV_DEBUG," read for %s lineStart %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.info.lineStart);
      read_value(mi.rPar[i]["startColumn"], (modelica_integer*) &(modelData->realData[i].info.info.colStart));
      DEBUG_INFO(LV_DEBUG," read for %s colStart %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.info.colStart);
      read_value(mi.rPar[i]["endLine"], (modelica_integer*) &(modelData->realData[i].info.info.lineEnd));
      DEBUG_INFO(LV_DEBUG," read for %s lineEnd %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.info.lineEnd);
      read_value(mi.rPar[i]["endColumn"], (modelica_integer*) &(modelData->realData[i].info.info.colEnd));
      DEBUG_INFO(LV_DEBUG," read for %s colEnd %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.info.colEnd);
      read_value(mi.rPar[i]["fileWritable"], (modelica_integer*) &(modelData->realData[i].info.info.readonly));
      DEBUG_INFO(LV_DEBUG," read for %s readonly %d from init file",modelData->realData[i].info.name,modelData->realData[i].info.info.readonly);

      /* read var attribute */
	  read_value(mi.rPar[i]["start"],&(modelData->realData[i].attribute.start));
	  DEBUG_INFO(LV_SOLVER," read start-value for %s =  %f from init file",modelData->realData[i].info.name,modelData->realData[i].attribute.start);
	  read_value(mi.rPar[i]["fixed"],(signed char*)&(modelData->realData[i].attribute.fixed));
	  DEBUG_INFO(LV_SOLVER," read fixed for %s = %s from init file",modelData->realData[i].info.name,modelData->realData[i].attribute.fixed?"true":"false");
  }


  for(int i = 0; i < modelData->nVariablesInteger; i++) { // Read stateDerivatives static data

	  DEBUG_INFO(LV_DEBUG, "Read xml file for integer parameters");
	  /* read var info */
      read_value(mi.iPar[i]["name"], &(modelData->integerData[i].info.name));
      DEBUG_INFO(LV_DEBUG," read var %s from init file",modelData->integerData[i].info.name);
      read_value(mi.iPar[i]["valueReference"], &(modelData->integerData[i].info.id));
      DEBUG_INFO(LV_DEBUG," read for %s id %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.id);
      read_value(mi.iPar[i]["description"], &(modelData->integerData[i].info.comment));
      DEBUG_INFO(LV_DEBUG," read for %s comment %s from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.comment);
      read_value(mi.iPar[i]["fileName"], (const char**)(void*)&(modelData->integerData[i].info.info.filename));
      DEBUG_INFO(LV_DEBUG," read for %s filename %s from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.filename);
      read_value(mi.iPar[i]["startLine"], (modelica_integer*) &(modelData->integerData[i].info.info.lineStart));
      DEBUG_INFO(LV_DEBUG," read for %s lineStart %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.lineStart);
      read_value(mi.iPar[i]["startColumn"], (modelica_integer*) &(modelData->integerData[i].info.info.colStart));
      DEBUG_INFO(LV_DEBUG," read for %s colStart %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.colStart);
      read_value(mi.iPar[i]["endLine"], (modelica_integer*) &(modelData->integerData[i].info.info.lineEnd));
      DEBUG_INFO(LV_DEBUG," read for %s lineEnd %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.lineEnd);
      read_value(mi.iPar[i]["endColumn"], (modelica_integer*) &(modelData->integerData[i].info.info.colEnd));
      DEBUG_INFO(LV_DEBUG," read for %s colEnd %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.colEnd);
      read_value(mi.iPar[i]["fileWritable"], (modelica_integer*) &(modelData->integerData[i].info.info.readonly));
      DEBUG_INFO(LV_DEBUG," read for %s readonly %d from init file",modelData->integerData[i].info.name,modelData->integerData[i].info.info.readonly);

      /* read var attribute */
	  read_value(mi.iPar[i]["start"],&(modelData->integerData[i].attribute.start));
	  DEBUG_INFO(LV_SOLVER," read start-value for %s =  %ld from init file",modelData->integerData[i].info.name,modelData->integerData[i].attribute.start);
	  read_value(mi.iPar[i]["fixed"],(signed char*)&(modelData->integerData[i].attribute.fixed));
	  DEBUG_INFO(LV_SOLVER," read fixed for %s = %s from init file",modelData->integerData[i].info.name,modelData->integerData[i].attribute.fixed?"true":"false");
  }

  for(int i = 0; i < modelData->nVariablesBoolean; i++) { // Read stateDerivatives static data

	  DEBUG_INFO(LV_DEBUG, "Read xml file for boolean parameters");
	  /* read var info */
      read_value(mi.bPar[i]["name"], &(modelData->booleanData[i].info.name));
      DEBUG_INFO(LV_DEBUG," read var %s from init file",modelData->booleanData[i].info.name);
      read_value(mi.bPar[i]["valueReference"], &(modelData->booleanData[i].info.id));
      DEBUG_INFO(LV_DEBUG," read for %s id %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.id);
      read_value(mi.bPar[i]["description"], &(modelData->booleanData[i].info.comment));
      DEBUG_INFO(LV_DEBUG," read for %s comment %s from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.comment);
      read_value(mi.bPar[i]["fileName"], (const char**)(void*)&(modelData->booleanData[i].info.info.filename));
      DEBUG_INFO(LV_DEBUG," read for %s filename %s from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.filename);
      read_value(mi.bPar[i]["startLine"], (modelica_integer*) &(modelData->booleanData[i].info.info.lineStart));
      DEBUG_INFO(LV_DEBUG," read for %s lineStart %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.lineStart);
      read_value(mi.bPar[i]["startColumn"], (modelica_integer*) &(modelData->booleanData[i].info.info.colStart));
      DEBUG_INFO(LV_DEBUG," read for %s colStart %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.colStart);
      read_value(mi.bPar[i]["endLine"], (modelica_integer*) &(modelData->booleanData[i].info.info.lineEnd));
      DEBUG_INFO(LV_DEBUG," read for %s lineEnd %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.lineEnd);
      read_value(mi.bPar[i]["endColumn"], (modelica_integer*) &(modelData->booleanData[i].info.info.colEnd));
      DEBUG_INFO(LV_DEBUG," read for %s colEnd %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.colEnd);
      read_value(mi.bPar[i]["fileWritable"], (modelica_integer*) &(modelData->booleanData[i].info.info.readonly));
      DEBUG_INFO(LV_DEBUG," read for %s readonly %d from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].info.info.readonly);

      /* read var attribute */
	  read_value(mi.bPar[i]["start"],&(modelData->booleanData[i].attribute.start));
	  DEBUG_INFO(LV_SOLVER," read start-value for %s =  %c from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].attribute.start);
	  read_value(mi.bPar[i]["fixed"],(signed char*)&(modelData->booleanData[i].attribute.fixed));
	  DEBUG_INFO(LV_SOLVER," read fixed for %s = %s from init file",modelData->booleanData[i].info.name,modelData->booleanData[i].attribute.fixed?"true":"false");
  }

  for(int i = 0; i < modelData->nVariablesString; i++) { // Read stateDerivatives static data

	  DEBUG_INFO(LV_DEBUG, "Read xml file for string parameters");
	  /* read var info */
      read_value(mi.sPar[i]["name"], &(modelData->stringData[i].info.name));
      DEBUG_INFO(LV_DEBUG," read var %s from init file",modelData->stringData[i].info.name);
      read_value(mi.sPar[i]["valueReference"], &(modelData->stringData[i].info.id));
      DEBUG_INFO(LV_DEBUG," read for %s id %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.id);
      read_value(mi.sPar[i]["description"], &(modelData->stringData[i].info.comment));
      DEBUG_INFO(LV_DEBUG," read for %s comment %s from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.comment);
      read_value(mi.sPar[i]["fileName"], (const char**)(void*)&(modelData->stringData[i].info.info.filename));
      DEBUG_INFO(LV_DEBUG," read for %s filename %s from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.filename);
      read_value(mi.sPar[i]["startLine"], (modelica_integer*) &(modelData->stringData[i].info.info.lineStart));
      DEBUG_INFO(LV_DEBUG," read for %s lineStart %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.lineStart);
      read_value(mi.sPar[i]["startColumn"], (modelica_integer*) &(modelData->stringData[i].info.info.colStart));
      DEBUG_INFO(LV_DEBUG," read for %s colStart %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.colStart);
      read_value(mi.sPar[i]["endLine"], (modelica_integer*) &(modelData->stringData[i].info.info.lineEnd));
      DEBUG_INFO(LV_DEBUG," read for %s lineEnd %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.lineEnd);
      read_value(mi.sPar[i]["endColumn"], (modelica_integer*) &(modelData->stringData[i].info.info.colEnd));
      DEBUG_INFO(LV_DEBUG," read for %s colEnd %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.colEnd);
      read_value(mi.sPar[i]["fileWritable"], (modelica_integer*) &(modelData->stringData[i].info.info.readonly));
      DEBUG_INFO(LV_DEBUG," read for %s readonly %d from init file",modelData->stringData[i].info.name,modelData->stringData[i].info.info.readonly);

      /* read var attribute */
	  read_value(mi.sPar[i]["start"],&(modelData->stringData[i].attribute.start));
	  DEBUG_INFO(LV_SOLVER," read for %s start-value %s from init file",modelData->stringData[i].info.name,modelData->stringData[i].attribute.start);
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
    cerr << "error read_value, no data allocated for storing string" << endl;
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
