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
#include "../FMI.h"
#include "FMIImpl.c"

void FMIExt_5finit(void)
{

}

RML_BEGIN_LABEL(FMIExt__initializeFMIImport)
{
  const char* filename = RML_STRINGDATA(rmlA0);
  const char* workingDirectory = RML_STRINGDATA(rmlA1);
  void* fmiContext;
  void* fmiInstance;
  void* fmiInfo;
  void* experimentAnnotation;
  void* modelVariablesInstance;
  void* modelVariablesList;
  rmlA0 = FMIImpl__initializeFMIImport(filename, workingDirectory, RML_UNTAGFIXNUM(rmlA2), &fmiContext, &fmiInstance, &fmiInfo, &experimentAnnotation,
      &modelVariablesInstance, &modelVariablesList) ? RML_TRUE : RML_FALSE;
  rmlA1 = (void*) mk_icon(fmiContext);
  rmlA2 = (void*) mk_icon(fmiInstance);
  rmlA3 = fmiInfo;
  rmlA4 = experimentAnnotation;
  rmlA5 = (void*) mk_icon(modelVariablesInstance);
  rmlA6 = modelVariablesList;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMIExt__releaseFMIImport)
{
  FMIImpl__releaseFMIImport(RML_UNTAGFIXNUM(rmlA0), RML_UNTAGFIXNUM(rmlA1), RML_UNTAGFIXNUM(rmlA2));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
