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

encapsulated package BackendInterface
" file:        BackendInterface.mo
  package:     BackendInterface
  description: Interface functions used to separate frontend and backend."

public import Absyn;

protected
import Global;

public

uniontype BackendInterfaceFunctions
  record BACKEND_INTERFACE_FUNCTIONS
    partialNoRewriteRulesFrontEnd noRewriteRulesFrontEnd;
    partialRewriteFrontEnd rewriteFrontEnd;
    partialAppendLibrary appendLibrary;
    partialInitInstHashTable initInstHashTable;
  end BACKEND_INTERFACE_FUNCTIONS;
end BackendInterfaceFunctions;

public function initializeBackendInterface
  input BackendInterfaceFunctions inFunctions;
algorithm
  setGlobalRoot(Global.backendInterface, inFunctions);
end initializeBackendInterface;

function noRewriteRulesFrontEnd
  output Boolean noRules;
protected
  BackendInterfaceFunctions functions;
  partialNoRewriteRulesFrontEnd func;
algorithm
  functions := getGlobalRoot(Global.backendInterface);
  func := functions.noRewriteRulesFrontEnd;
  noRules := func();
end noRewriteRulesFrontEnd;

function rewriteFrontEnd
  input Absyn.Exp inExp;
  output Absyn.Exp outExp;
  output Boolean isChanged;
protected
  BackendInterfaceFunctions functions;
  partialRewriteFrontEnd func;
algorithm
  functions := getGlobalRoot(Global.backendInterface);
  func := functions.rewriteFrontEnd;
  (outExp,isChanged) := func(inExp);
end rewriteFrontEnd;

function appendLibrary
  input Absyn.Path modelName;
  input String modelicaPath;
  output Absyn.Program program;
  output Boolean success;
protected
  BackendInterfaceFunctions functions;
  partialAppendLibrary func;
algorithm
  functions := getGlobalRoot(Global.backendInterface);
  func := functions.appendLibrary;
  (program, success) := func(modelName, modelicaPath);
end appendLibrary;

function initInstHashTable
protected
  BackendInterfaceFunctions functions;
  partialInitInstHashTable func;
algorithm
  functions := getGlobalRoot(Global.backendInterface);
  func := functions.initInstHashTable;
  func();
end initInstHashTable;

partial function partialNoRewriteRulesFrontEnd
  output Boolean noRules;
end partialNoRewriteRulesFrontEnd;

partial function partialRewriteFrontEnd
  input Absyn.Exp inExp;
  output Absyn.Exp outExp;
  output Boolean isChanged;
end partialRewriteFrontEnd;

partial function partialAppendLibrary
  input Absyn.Path modelName;
  input String modelicaPath;
  output Absyn.Program program;
  output Boolean success;
end partialAppendLibrary;

partial function partialInitInstHashTable
end partialInitInstHashTable;

annotation(__OpenModelica_Interface="frontend_dump");
end BackendInterface;
