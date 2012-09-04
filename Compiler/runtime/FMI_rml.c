/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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

#include "rml.h"
#include "FMIImpl.c"

void FMI_5finit(void)
{

}

RML_BEGIN_LABEL(FMI__initializeFMIImport)
{
  const char* filename = RML_STRINGDATA(rmlA0);
  const char* workingDirectory = RML_STRINGDATA(rmlA1);
  void* fmiContext;
  void* fmiInstance;
  const char* modelIdentifier;
  const char* description;
  double experimentStartTime;
  double experimentStopTime;
  double experimentTolerance;
  void* modelVariablesInstance;
  void* modelVariablesList;
  rmlA0 = FMIImpl__initializeFMIImport(filename, workingDirectory, RML_UNTAGFIXNUM(rmlA2), &fmiContext, &fmiInstance, &modelIdentifier, &description,
      &experimentStartTime, &experimentStopTime, &experimentTolerance, &modelVariablesInstance, &modelVariablesList) ? RML_TRUE : RML_FALSE;
  rmlA1 = (void*) mk_icon(fmiContext);
  rmlA2 = (void*) mk_icon(fmiInstance);
  rmlA3 = (void*) mk_scon(modelIdentifier);
  rmlA4 = (void*) mk_scon(description);
  rmlA5 = (void*) mk_rcon(experimentStartTime);
  rmlA6 = (void*) mk_rcon(experimentStopTime);
  rmlA7 = (void*) mk_rcon(experimentTolerance);
  rmlA8 = (void*) mk_icon(modelVariablesInstance);
  rmlA9 = modelVariablesList;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__releaseFMIImport)
{
  FMIImpl__releaseFMIImport(RML_UNTAGFIXNUM(rmlA0), RML_UNTAGFIXNUM(rmlA1), RML_UNTAGFIXNUM(rmlA2));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIModelVariableVariability)
{
  const char* res = FMIImpl__getFMIModelVariableVariability(RML_UNTAGFIXNUM(rmlA0));
  rmlA0 = (void*) mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIModelVariableCausality)
{
  const char* res = FMIImpl__getFMIModelVariableCausality(RML_UNTAGFIXNUM(rmlA0));
  rmlA0 = (void*) mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIModelVariableBaseType)
{
  const char* res = FMIImpl__getFMIModelVariableBaseType(RML_UNTAGFIXNUM(rmlA0));
  rmlA0 = (void*) mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIModelVariableName)
{
  char* res = FMIImpl__getFMIModelVariableName(RML_UNTAGFIXNUM(rmlA0));
  rmlA0 = (void*) mk_scon(res);
  free(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIModelVariableDescription)
{
  const char* res = FMIImpl__getFMIModelVariableDescription(RML_UNTAGFIXNUM(rmlA0));
  rmlA0 = (void*) mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMINumberOfContinuousStates)
{
  rmlA0 = (void*) mk_icon(FMIImpl__getFMINumberOfContinuousStates(RML_UNTAGFIXNUM(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMINumberOfEventIndicators)
{
  rmlA0 = (void*) mk_icon(FMIImpl__getFMINumberOfEventIndicators(RML_UNTAGFIXNUM(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIModelVariableHasStart)
{
  rmlA0 = FMIImpl__getFMIModelVariableHasStart(RML_UNTAGFIXNUM(rmlA0)) ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIModelVariableIsFixed)
{
  rmlA0 = FMIImpl__getFMIModelVariableIsFixed(RML_UNTAGFIXNUM(rmlA0)) ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIRealVariableStartValue)
{
  rmlA0 = (void*) mk_rcon(FMIImpl__getFMIRealVariableStartValue(RML_UNTAGFIXNUM(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIIntegerVariableStartValue)
{
  rmlA0 = (void*) mk_icon(FMIImpl__getFMIIntegerVariableStartValue(RML_UNTAGFIXNUM(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIBooleanVariableStartValue)
{
  rmlA0 = FMIImpl__getFMIBooleanVariableStartValue(RML_UNTAGFIXNUM(rmlA0)) ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIStringVariableStartValue)
{
  rmlA0 = (void*) mk_scon(FMIImpl__getFMIStringVariableStartValue(RML_UNTAGFIXNUM(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIEnumerationVariableStartValue)
{
  rmlA0 = (void*) mk_icon(FMIImpl__getFMIEnumerationVariableStartValue(RML_UNTAGFIXNUM(rmlA0)));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
