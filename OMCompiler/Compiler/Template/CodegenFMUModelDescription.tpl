/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

// The modelDescription.xml of an FMU, dispatched on the FMI version.

package CodegenFMUModelDescription

import interface SimCodeTV;
import interface SimCodeBackendTV;
import CodegenFMU1;
import CodegenFMU2;
import CodegenFMU3;

template fmuModelDescriptionFile(SimCode simCode, String guid, String FMUVersion, String FMUType, list<String> sourceFiles)
 "Generates code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <?xml version="1.0" encoding="UTF-8"?>
  <%
  if isFMIVersion30(FMUVersion) then CodegenFMU3.fmiModelDescription(simCode, guid, FMUType, sourceFiles)
  else if isFMIVersion20(FMUVersion) then CodegenFMU2.fmiModelDescription(simCode, guid, FMUType, sourceFiles)
  else CodegenFMU1.fmiModelDescription(simCode,guid,FMUType)
  %>
  >>
end fmuModelDescriptionFile;

annotation(__OpenModelica_Interface="codegen_fmu");
end CodegenFMUModelDescription;

// vim: filetype=susan sw=2 sts=2
