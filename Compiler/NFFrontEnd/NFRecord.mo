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

import Binding = NFBinding;
import NFClass.Class;
import NFComponent.Component;
import Dimension = NFDimension;
import NFEquation.Equation;
import Expression = NFExpression;
import NFExpression.CallAttributes;
import NFInstNode.InstNode;
import NFMod.Modifier;
import NFStatement.Statement;
import Type = NFType;
import Subscript = NFSubscript;

protected
import Inst = NFInst;
import List;
import Lookup = NFLookup;
import TypeCheck = NFTypeCheck;
import Types;
import Typing = NFTyping;
import NFInstUtil;
import NFPrefixes.Variability;

public
function typeRecordCall
  input Absyn.ComponentRef recName;
  input Absyn.FunctionArgs callArgs;
  input InstNode classNode;
  input Type classType;
  input InstNode callScope;
  input SourceInfo info;
  output Expression typedExp;
  output Type ty;
  output Variability variability;
//protected
//  InstNode instClassNode;
//  list<InstNode> inputs;
//  Component comp;
//  DAE.VarKind vari;
//  list<Func.FunctionSlot> slots;
//  list<Dimension> vectDims;
//  NFExpression.CallAttributes ca;
//  list <Expression> recElems, recExps;
//  Absyn.Path recPath;
algorithm
  typedExp := Expression.INTEGER(0);
  ty := Type.UNKNOWN();
  variability := Variability.CONTINUOUS;
//
//  inputs := getRecordConstructorInputs(classNode);
//
//  slots := Func.createAndFillSlots(recName, prefix, inputs, callArgs, callScope, info);
//
//  (slots,vectDims) := Func.typeCheckFunctionSlots(slots, Absyn.crefToPath(recName), prefix, info);
//  (recElems, variability) := Func.argsFromSlots(slots);
//
//  ty := classType;
//  // Prefix?
//  recPath := Absyn.crefToPath(recName);
//
//  if listLength(vectDims) == 0 then
//    typedExp := Expression.RECORD(recPath, ty, recElems);
//  else
//    recExps := vectorizeRecordCall(recPath, ty, recElems, vectDims);
//    typedExp := Expression.arrayFromList(recExps, ty, vectDims);
//  end if;

end typeRecordCall;

//function createAndFillSlots
//  input Absyn.ComponentRef funcName;
//  input list<InstNode> funcInputs;
//  input Absyn.FunctionArgs callArgs;
//  input InstNode callScope;
//  input SourceInfo info;
//  output list<Func.FunctionSlot> filledSlots;
//protected
//  Component comp;
//  DAE.VarKind vari;
//  DAE.Const const;
//  list<Absyn.Exp> posargs;
//  list<Absyn.NamedArg> namedargs;
//  Func.FunctionSlot sl;
//  list<Func.FunctionSlot> slots, posfilled;
//  Expression argExp;
//  Type argTy;
//  DAE.Const argConst;
//algorithm
//
//  slots := {};
//  for compnode in funcInputs loop
//    // argName := InstNode.name(compnode);
//    comp := InstNode.component(compnode);
//    vari := Component.variability(comp);
//    const := Typing.variabilityToConst(NFInstUtil.daeToSCodeVariability(vari));
//    // bind := Component.getBinding(comp)
//    // ty := Component.getType(comp);
//    slots := Func.SLOT(InstNode.name(compnode),
//                  NONE(),
//                  Component.getBinding(comp),
//                  SOME((Component.getType(comp), const)),
//                  false)::slots;
//  end for;
//  slots := listReverse(slots);
//
//  Absyn.FUNCTIONARGS(args = posargs, argNames = namedargs) := callArgs;
//
//  posfilled := {};
//  // handle positional args
//  for arg in posargs loop
//    (argExp, argTy, argConst) := Typing.typeExp(arg, callScope, info);
//    sl::slots := slots;
//    sl := Func.fillPosSlotWithArg(sl,(argExp, argTy, argConst));
//    posfilled := sl::posfilled;
//  end for;
//  slots := listAppend(listReverse(posfilled), slots);
//
//  // handle named args
//  for narg in namedargs loop
//    Absyn.NAMEDARG() := narg;
//    (argExp, argTy, argConst) := Typing.typeExp(narg.argValue, callScope, info);
//    slots := Func.fillNamedSlot(slots, narg.argName, (argExp, argTy, argConst), Absyn.crefToPath(funcName), info);
//  end for;
//
//  filledSlots := slots;
//end createAndFillSlots;
//
//function getRecordConstructorInputs
//  input InstNode classNode;
//  output list<InstNode> inputs = {};
//protected
//  InstNode compnode;
//  Component.Attributes attr;
//  array<InstNode> components;
//  Component comp;
//algorithm
//  Class.INSTANCED_CLASS(components = components) := InstNode.getClass(classNode);
//
//  for i in arrayLength(components):-1:1 loop
//     comp := InstNode.component(components[i]);
//     if Component.isPublic(comp) then
//       if Component.isConst(comp) then
//         if not Component.hasBinding(comp) then
//           inputs := components[i]::inputs;
//         end if;
//       else
//         inputs := components[i]::inputs;
//       end if;
//     end if;
//  end for;
//end getRecordConstructorInputs;
//
//function vectorizeRecordCall
//  input Absyn.Path inRecName;
//  input Type recType;
//  input list<Expression> valExps;
//  input list<Dimension> vecDims;
//  output list<Expression> outRecs;
//protected
//  list<list<Subscript>> vectsubs;
//  list<list<Expression>> vecargslst;
//algorithm
//
//  // Create combinations of each dims subs, i.e., expand an array[dims]
//  vectsubs := Func.vectorizeDims(vecDims);
//
//  // Apply the set of subs to each argument, i.e., expand each arg.
//  vecargslst := {};
//  for currsubs in vectsubs loop
//    vecargslst := list(Expression.subscript(arg, currsubs) for arg in valExps)::vecargslst;
//  end for;
//
//
//  outRecs := {};
//  for vals in vecargslst loop
//    outRecs := Expression.RECORD(inRecName, recType, vals)::outRecs;
//  end for;
//
//end vectorizeRecordCall;
//
//function recVariabilityfromSlots
//  "Not sure about how to deal with record variability. But this should do for now."
//  input list<Func.FunctionSlot> slots;
//  output DAE.Const variability;
//protected
//  DAE.Const const;
//  Binding b;
//algorithm
//  variability := DAE.C_CONST();
//  for s in slots loop
//    Func.SLOT() := s;
//    if isSome(s.arg) then
//      SOME((_, _, const)) := s.arg;
//      variability := Types.constAnd(variability, const);
//    else
//      variability := match s.default
//      // TODO FIXME what do we do with the propagatedDims?
//        case b as Binding.TYPED_BINDING()
//          then Types.constAnd(variability, b.variability);
//        else
//          algorithm
//            Error.addMessage(Error.INTERNAL_ERROR, {"NFRecord.typeRecordCall failed."});
//          then fail();
//        end match;
//    end if;
//  end for;
//end recVariabilityfromSlots;


annotation(__OpenModelica_Interface="frontend");
end NFRecord;
