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

encapsulated package BackendCevalInterface
" file:        BackendCevalInterface.mo
  package:     BackendCevalInterface
  description: Interface functions used to separate frontend and backend."

public import Absyn;
public import DAE;
public import FCore;
public import Values;

protected
import BackendInterface;
import Global;

public

uniontype BackendInterfaceFunctions
  record BACKEND_INTERFACE_FUNCTIONS
    partialCevalInteractiveFunctions cevalInteractiveFunctions;
    partialCevalCallFunction cevalCallFunction;
    partialElabCallInteractive elabCallInteractive;
  end BACKEND_INTERFACE_FUNCTIONS;
end BackendInterfaceFunctions;

public function initializeBackendInterface
  input BackendInterfaceFunctions inFunctions;
algorithm
  setGlobalRoot(Global.backendCevalInterface, inFunctions);
end initializeBackendInterface;

function cevalInteractiveFunctions
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input Absyn.Msg inMsg;
  input Integer inNumIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
protected
  BackendInterfaceFunctions functions;
  partialCevalInteractiveFunctions func;
algorithm
  functions := getGlobalRoot(Global.backendInterface);
  func := functions.cevalInteractiveFunctions;
  (outCache,outValue) := func(inCache, inEnv, inExp, inMsg, inNumIter);
end cevalInteractiveFunctions;

function cevalCallFunction
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input list<Values.Value> inValues;
  input Boolean inImplInst;
  input Absyn.Msg inMsg;
  input Integer inNumIter = 1;
  output FCore.Cache outCache;
  output Values.Value outValue;
protected
  BackendInterfaceFunctions functions;
  partialCevalCallFunction func;
algorithm
  functions := getGlobalRoot(Global.backendInterface);
  func := functions.cevalCallFunction;
  (outCache,outValue) := func(inCache, inEnv, inExp, inValues, inImplInst, inMsg, inNumIter);
end cevalCallFunction;

function elabCallInteractive "Note: elabCall_InteractiveFunction is set in the error buffer; the called function should pop it"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input list<Absyn.Exp> inExps;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplInst;
  input DAE.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  BackendInterfaceFunctions functions;
  partialElabCallInteractive func;
algorithm
  functions := getGlobalRoot(Global.backendInterface);
  func := functions.elabCallInteractive;
  (outCache, outExp, outProperties) := func(inCache, inEnv, inCref, inExps, inNamedArgs, inImplInst, inPrefix, inInfo);
end elabCallInteractive;

partial function partialCevalInteractiveFunctions
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input Absyn.Msg inMsg;
  input Integer inNumIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
end partialCevalInteractiveFunctions;

partial function partialCevalCallFunction
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input list<Values.Value> inValues;
  input Boolean inImplInst;
  input Absyn.Msg inMsg;
  input Integer inNumIter = 1;
  output FCore.Cache outCache;
  output Values.Value outValue;
end partialCevalCallFunction;

partial function partialElabCallInteractive "Note: elabCall_InteractiveFunction is set in the error buffer; the called function should pop it"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input list<Absyn.Exp> inExps;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplInst;
  input DAE.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
end partialElabCallInteractive;

annotation(__OpenModelica_Interface="frontend");
end BackendCevalInterface;
