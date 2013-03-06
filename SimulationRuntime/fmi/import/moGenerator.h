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

#include "xmlparser.h"
#include "fmuWrapper.h"

typedef enum{flat, structured} fmiNamingConvention;
typedef enum{constant, parameter, discrete, continuous} fmiVariability;
typedef enum{input, output, internal, none} fmiCausality;
typedef enum{noalias, alias, negatedAlias} fmiAlias;
typedef enum{fmi_false, fmi_true} fmiBooleanXML;
typedef enum{sv_real, sv_integer, sv_boolean, sv_string, sv_enum} fmiScalarVariableType;

typedef struct {
  const char* name;
  fmiValueReference vr;
  int aliasInd;
  void* variable;
  void* next;
} fmuOutputVar;


typedef struct{
  const char* declType;
  const char* start;
  int defStart;
  fmiBooleanXML fixed;
} fmiSTRING;

typedef struct{
  fmiBooleanXML start;
  const char* declType;
  int defStart;
  fmiBooleanXML fixed;
} fmiBOOLEAN;

typedef struct{
  const char* declType;
  const char* quantity;
  int min;
  int defMin;
  int max;
  int defMax;
  int start;
  int defStart;
  fmiBooleanXML fixed;
} fmiINTEGER;

typedef struct{
  const char *declType;
  const char *quantity;
  int min;
  int defMin;
  int max;
  int defMax;
  int start;
  int defStart;
  fmiBooleanXML fixed;
} fmiENUM;

typedef struct{
  const char* declType;
  const char* quantity;
  const char* unit;
  const char* displayUnit;
  fmiBooleanXML relQuantity;
  double min;
  int defMin;
  double max;
  int defMax;
  double nominal;
  int defNorminal;
  double start;
  int defStart;
  fmiBooleanXML fixed;
} fmiREAL;

typedef struct{
  const char* name;
  char* flatName;
  fmiValueReference vr; // value reference;
  const char* description;
  fmiVariability var;
  fmiCausality causality;
  fmiAlias alias;
  fmiScalarVariableType type;
  void* variable;
} fmiScalarVariable;

typedef struct{
  void *vp;
} fmiArrayVariable;

typedef struct{
  int nsv; // number of scalar variables
  fmiScalarVariable* list_sv;
  int nav; // number of array variables
  fmiArrayVariable* list_av;
} fmiModelVariable;

typedef struct{
  double startTime;
  double stopTime;
  double tolerance;
} fmiDefaultExperiment;

typedef struct{
  const char* fmiver; // fmi version number;
  const char* mn; // fmi model name
  const char* mid; // model identifier;
  const char* guid; // fingerprint of xml-file content
  const char* description; // string describing the model
  const char* author;
  const char* mver; // model version
  const char* genTool;// generation tool;
  const char* genTime; // generation date and time;
  fmiNamingConvention nconv; // variable naming convention;
  unsigned int ncs; // number of continuous states;
  unsigned int nei; // number of event indicators;
  fmiDefaultExperiment *defaultExperiment;
  fmiModelVariable* modelVariable;
} fmuModelDescription;


fmiScalarVariableType getElementType(ScalarVariable* sv);
void* allocateElmSV(fmiScalarVariable sv);
void instElmSV(ScalarVariable* sv, fmiScalarVariable fmisv);
void instScalarVariable(ModelDescription* md,fmiScalarVariable* list);
fmiNamingConvention getNamingConvention(ModelDescription* md, Att att);
void instFmuModelDescription(ModelDescription* md, fmuModelDescription* fmuMD, fmiModelVariable* fmuMV);
void freeScalarVariableLst(fmiScalarVariable* list,int nsv);
void tmpcodegen(fmuModelDescription* /*fmuMD*/, const char* /*decompPath*/);
void addOutputVariable(fmiScalarVariable* /*sv*/, fmuOutputVar** /*root*/, fmuOutputVar** /*nextVar*/, unsigned int* /*counter*/);
void blockcodegen(fmuModelDescription* /*fmuMD*/, const char* /*decompPath*/, const char* /*fmudllpath*/);
void printUsage();
