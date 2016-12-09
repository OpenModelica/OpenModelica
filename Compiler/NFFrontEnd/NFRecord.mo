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

encapsulated package NFRecord
" file:        NFRecord.mo
  package:     NFRecord
  description: package for handling records.


  Functions used by NFInst for handling records.
"

import NFBinding.Binding;
import NFClass.Class;
import NFComponent.Component;
import NFDimension.Dimension;
import NFEquation.Equation;
import NFInstNode.InstNode;
import NFMod.Modifier;
import NFPrefix.Prefix;
import NFStatement.Statement;

protected
import ClassInf;
import ComponentReference;
import Error;
import Expression;
import Inst = NFInst;
import InstUtil;
import List;
import Lookup = NFLookup;
import Static;
import TypeCheck = NFTypeCheck;
import Types;
import Typing = NFTyping;

public
function typeRecordCall
  input Absyn.ComponentRef functionName;
  input Absyn.FunctionArgs functionArgs;
  input Prefix prefix;
  input InstNode classNode;
  input DAE.Type classType;
  input SCode.Element cls;
  input InstNode component;
  input SourceInfo info;
  output DAE.Exp typedExp;
  output DAE.Type ty;
  output DAE.Const variability;
protected
  String fn_name;
  Absyn.Path fn, fn_1;
  InstNode fakeComponent;
  DAE.CallAttributes ca;
  DAE.Type resultType;
  list<DAE.FuncArg> funcArg;
  DAE.FunctionAttributes functionAttributes;
  DAE.TypeSource source;
  list<DAE.Var> vars;
  list<Absyn.Exp> args;
  list<DAE.Exp> dargs;
  list<DAE.Type> dargsType;
  list<DAE.Const> dargsVariability;
  DAE.FunctionBuiltin isBuiltin;
  Boolean builtin;
  DAE.InlineType inlineType;
algorithm

  fn := Absyn.crefToPath(functionName);

  DAE.T_COMPLEX(varLst = vars) := classType;
  functionAttributes := InstUtil.getFunctionAttributes(cls, vars);
  ty := Types.makeFunctionType(fn, vars, functionAttributes);

  DAE.T_FUNCTION(funcResultType = resultType) := ty;

  Absyn.FUNCTIONARGS(args = args) := functionArgs;
  (dargs, dargsType, dargsVariability) := Typing.typeExps(args, component, info);
  variability := List.fold(dargsVariability, Types.constAnd, DAE.C_CONST());

  (isBuiltin,builtin,fn_1) := Static.isBuiltinFunc(fn, ty);
  inlineType := Static.inlineBuiltin(isBuiltin,functionAttributes.inline);

  ca := DAE.CALL_ATTR(
          resultType,
          Types.isTuple(resultType),
          builtin,
          functionAttributes.isImpure or (not functionAttributes.isOpenModelicaPure),
          functionAttributes.isFunctionPointer,
          inlineType,DAE.NO_TAIL());

  typedExp := DAE.CALL(fn_1, dargs, ca);

end typeRecordCall;

annotation(__OpenModelica_Interface="frontend");
end NFRecord;
