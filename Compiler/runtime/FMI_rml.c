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

#include "FMIImpl.c"
#include "rml.h"

void FMI_5finit(void)
{

}

/*RML_BEGIN_LABEL(FMI__importFMU)
{
  const char* filename = RML_STRINGDATA(rmlA0);
  const char* workingDirectory = RML_STRINGDATA(rmlA1);
  char* res = FMIImpl__importFMU(filename, workingDirectory);
  rmlA0 = (void*) mk_scon(res);
  free(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL*/

RML_BEGIN_LABEL(FMI__initializeFMIContext)
{
  const char* filename = RML_STRINGDATA(rmlA0);
  const char* workingDirectory = RML_STRINGDATA(rmlA1);
  rmlA0 = FMIImpl__initializeFMIContext(filename, workingDirectory);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__releaseFMIContext)
{
  FMIImpl__releaseFMIContext(rmlA0);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__initializeFMI)
{
  const char* workingDirectory = RML_STRINGDATA(rmlA1);
  rmlA0 = FMIImpl__initializeFMI(rmlA0, workingDirectory);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__releaseFMI)
{
  FMIImpl__releaseFMI(rmlA0);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIModelIdentifier)
{
  const char* res = FMIImpl__getFMIModelIdentifier(rmlA0);
  rmlA0 = (void*) mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIDescription)
{
  const char* res = FMIImpl__getFMIDescription(rmlA0);
  rmlA0 = (void*) mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIDefaultExperimentStart)
{
  rmlA0 = (void*) mk_rcon(FMIImpl__getFMIDefaultExperimentStart(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIDefaultExperimentStop)
{
  rmlA0 = (void*) mk_rcon(FMIImpl__getFMIDefaultExperimentStop(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(FMI__getFMIDefaultExperimentTolerance)
{
  rmlA0 = (void*) mk_rcon(FMIImpl__getFMIDefaultExperimentTolerance(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
