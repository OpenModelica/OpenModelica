/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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

encapsulated package BackendInterface
" file:        BackendInterface.mo
  package:     BackendInterface
  description: Interface functions used to separate frontend and backend."

public import Absyn;
public import DAE;
public import FCore;
public import Prefix;
public import Values;

protected
import CevalScript;
import RewriteRules;
import StaticScript;

public function cevalInteractiveFunctions
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input Absyn.Msg inMsg;
  input Integer inNumIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache, outValue) := CevalScript.cevalInteractiveFunctions( inCache, inEnv, inExp, inMsg, inNumIter);
end cevalInteractiveFunctions;

public function cevalCallFunction
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input list<Values.Value> inValues;
  input Boolean inImplInst;
  input Absyn.Msg inMsg;
  input Integer inNumIter = 1;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache, outValue) := CevalScript.cevalCallFunction(inCache, inEnv, inExp, inValues, inImplInst, inMsg, inNumIter);
end cevalCallFunction;

public function elabCallInteractive
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input list<Absyn.Exp> inExps;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImplInst;
  input Prefix.Prefix inPrefix;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) :=
    StaticScript.elabCallInteractive(inCache, inEnv, inCref, inExps, inNamedArgs, inImplInst, inPrefix, inInfo);
end elabCallInteractive;

function noRewriteRulesFrontEnd
  output Boolean noRules;
algorithm
  noRules := RewriteRules.noRewriteRulesFrontEnd();
end noRewriteRulesFrontEnd;

function rewriteFrontEnd
  input Absyn.Exp inExp;
  output Absyn.Exp outExp;
  output Boolean isChanged;
algorithm
  (outExp,isChanged) := RewriteRules.rewriteFrontEnd(inExp);
end rewriteFrontEnd;

annotation(__OpenModelica_Interface="backendInterface");
end BackendInterface;
