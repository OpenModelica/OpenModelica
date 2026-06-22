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

encapsulated package MidToLLVMUtil
" file:        MidToLLVMUtil.mo
  package:     MidToLLVMUtil
  description: Various utility procedures. Mainly used for the LLVM tests.
  author: John Tinnerholm
"
protected
import CodegenUtil.{underscorePath,dotPath};
import EXT_LLVM;
import List;
import MidCode;
import System;
import Tpl.{Text,textString};
import Values;
import ValuesUtil;

public
function functionsAreJitted
  "Given A set of function determine if they are jit compiled or not"
  input list<Absyn.Path> funcNames;
  output Boolean b;
algorithm
  // Util.boolAndList was removed from master. Replace with an
  // open-coded short-circuiting AND so the semantics match.
  b := true;
  for fName in funcNames loop
    if not funcIsJitCompiled(fName) then
      b := false;
      return;
    end if;
  end for;
end functionsAreJitted;

function funcIsJitCompiled
  "Checks if there exists a handler to a function with the given Absyn.path."
  input Absyn.Path fName;
  output Boolean b;
protected
  String fString;
algorithm
  fString := textString(underscorePath(Tpl.MEM_TEXT({},{}),fName));
  b := EXT_LLVM.funcIsJitCompiled(fString);
end funcIsJitCompiled;

//Note that this function maybe should be in there own file, ValueToMid or something like that.
function valLstToMidVarLst
  input list<Values.Value> valLst;
  output list<MidCode.Var> midVarLst;
algorithm
  midVarLst := List.map(valLst,valueToMidVar);
end valLstToMidVarLst;

public function valueToMidVar
  input Values.Value val;
  output MidCode.Var midVar;
algorithm
  midVar := MidCode.VAR("_tmp_" + intString(System.tmpTickIndex(46)), ValuesUtil.valueExpType(val), false);
end valueToMidVar;

annotation(__OpenModelica_Interface="backend");
end MidToLLVMUtil;
