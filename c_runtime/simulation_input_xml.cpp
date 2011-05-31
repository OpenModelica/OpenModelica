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
/* reads string value from a string */
void read_value(string s, string *str);
/* reads a string value from a string */
void read_value(string s, const char **str);
/* reads boolean value from a string */
void read_value(string s, signed char *str);

static void XMLCALL
startElement(void *userData, const char *name, const char **attr)
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
    cerr << "simulation_input_xml.cpp: Error: can not read file " << *filename << " as indata to simulation." << endl;
    delete filename;
    fclose(file);
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
  if (sim_verbose >= LOG_SOLVER) { cout << "read start = " << *start << " from init file." << endl; }
  read_value(mi.de["stopTime"],stop);
  if (sim_verbose >= LOG_SOLVER) { cout << "read stop = " << *stop << " from init file." << endl; }
  read_value(mi.de["stepSize"],stepSize);
  if (sim_verbose >= LOG_SOLVER) { cout << "read stepSize = " << *stepSize << " from init file." << endl; }
  read_value(mi.de["tolerance"],tolerance);
  if (sim_verbose >= LOG_SOLVER) { cout << "read tolerance = " << *tolerance << " from init file." << endl; }

  if (methodc == NULL)
  {
    read_value(mi.de["solver"],method);
    if (sim_verbose >= LOG_SOLVER) { cout << "read method = " << *method << " from init file." << endl; }
  }
  else
  {
    string tmp;
    read_value(mi.de["solver"],&tmp);
    if (sim_verbose >= LOG_SOLVER) { cout << "read method  = " << *methodc << " from commandline." << endl; }
  }
  read_value(mi.de["outputFormat"],outputFormat);
  if (sim_verbose >= LOG_SOLVER) { cout << "read outputFormat = " << *outputFormat << " from init file." << endl; }
  read_value(mi.de["variableFilter"],variableFilter);
  if (sim_verbose >= LOG_SOLVER) { cout << "read variableFilter = " << *variableFilter << " from init file." << endl; }

  // set the step size
  globalData->current_stepsize = *stepSize;
  if (stepSize < 0) { // stepSize < 0 => Automatic number of outputs
    *outputSteps = -1;
  } else {
    // Calculate outputSteps from stepSize, start and stop
    *outputSteps = (long)(int(*stop-*start) /(*stepSize));
  }

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
    if (sim_verbose >= LOG_INIT) {
      cout << "read " << simData->statesNames[i].name << " = " << simData->states[i] << " from init file." << endl;
    }
  }

  for(int i = 0; i < simData->nStates; i++) { // Read der(x) initial values
    read_value(mi.rDer[i]["start"],&simData->statesDerivatives[i]);
    if (sim_verbose >= LOG_INIT) {
      cout << "read " << simData->stateDerivativesNames[i].name << " = " << simData->statesDerivatives[i] << " from init file." << endl;
    }
  }

  for(int i = 0; i < simData->nAlgebraic; i++) { // Read y initial values
    read_value(mi.rAlg[i]["start"],&simData->algebraics[i]);
    if (sim_verbose >= LOG_INIT) {
      cout << "read " << simData->algebraicsNames[i].name << " = " << simData->algebraics[i] << " from init file." << endl;
    }
  }

  for(int i = 0; i < simData->nParameters; i++) { // Read parameter values
    read_value(mi.rPar[i]["start"],&simData->parameters[i]);
    if (sim_verbose >= LOG_INIT) {
      cout << "read " << simData->parametersNames[i].name << " = " << simData->parameters[i] << " from init file." << endl;
    }
  }

  for(int i = 0; i < simData->intVariables.nParameters; i++) { // Read parameter values
    read_value(mi.iPar[i]["start"],&simData->intVariables.parameters[i]);
    if (sim_verbose >= LOG_INIT) {
      cout << "read " << simData->int_param_names[i].name << " = " << simData->intVariables.parameters[i] << " from init file." << endl;
    }
  }

  for(int i = 0; i < simData->intVariables.nAlgebraic; i++) { // Read parameter values
    read_value(mi.iAlg[i]["start"],&simData->intVariables.algebraics[i]);
    if (sim_verbose >= LOG_INIT) {
      cout << "read " << simData->int_alg_names[i].name << " = " << simData->intVariables.algebraics[i] << " from init file." << endl;
    }
  }

  for(int i = 0; i < simData->boolVariables.nParameters; i++) { // Read parameter values
    read_value(mi.bPar[i]["start"],&simData->boolVariables.parameters[i]);
    if (sim_verbose >= LOG_INIT) {
      cout << "read " << simData->bool_param_names[i].name << " = " << (bool)simData->boolVariables.parameters[i] << " from init file." << endl;
    }
  }

  for(int i = 0; i < simData->boolVariables.nAlgebraic; i++) { // Read parameter values
    read_value(mi.bAlg[i]["start"],&simData->boolVariables.algebraics[i]);
    if (sim_verbose >= LOG_INIT) {
      cout << "read " << simData->bool_alg_names[i].name << " = " << (bool)simData->boolVariables.algebraics[i] << " from init file." << endl;
    }
  }

  for(int i=0; i < simData->stringVariables.nParameters; i++) { // Read string parameter values
    read_value(mi.sPar[i]["start"],&(simData->stringVariables.parameters[i]));
    if (sim_verbose >= LOG_INIT) {
      cout << "read " << simData->string_param_names[i].name << " = \"" << simData->stringVariables.parameters[i] << "\" from init file." << endl;
    }
  }

  for(int i=0; i < simData->stringVariables.nAlgebraic; i++) { // Read string algebraic values
    read_value(mi.sAlg[i]["start"],&simData->stringVariables.algebraics[i]);
    if (sim_verbose >= LOG_INIT) {
      cout << "read " << simData->string_alg_names[i].name << " from init file." << endl;
    }
  }

  if (sim_verbose >= LOG_SOLVER)
  {
    cout << "Read parameter data from file " << *filename << endl;
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
    *res = atoi(s.c_str());
  }
}


