/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated uniontype NBInline<T>
" file:         NBInline.mo
  package:      NBInline
  description:  This file contains functions for inlining operations.
"

protected
  import Inline = NBInline;

  // OF imports
  import Absyn;
  import AbsynUtil;
  import DAE;
  import DAEDump;
  import DAEUtil;

  // NF imports
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFunction.Function;
  import NFFlatten.FunctionTree;
  import Statement = NFStatement;

  // NB imports
  import Module = NBModule;
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointers, EqData, EquationAttributes, Iterator};
  import Replacements = NBReplacements;
  import NBVariable.{VariablePointers, VarData};

// =========================================================================
//                      MAIN ROUTINE, PLEASE DO NOT CHANGE
// =========================================================================
public
  function main
    "Wrapper function for any inlining function. This will be
     called during simulation and gets the corresponding subfunction from
     the given input."
    extends Module.wrapper;
    input list<DAE.InlineType> inline_types;
  algorithm
    bdae := match bdae
      case BackendDAE.MAIN()
        algorithm
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then
            print(StringUtil.headline_4("[dumpBackendInline] Inlining operatations for: " + List.toString(inline_types, DAEDump.dumpInlineTypeBackendStr)));
          end if;
          bdae.eqData := inline(bdae.eqData, bdae.varData, bdae.funcTree, inline_types);
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then
            print("\n");
          end if;
        then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end main;

// =========================================================================
//                    TYPES, UNIONTYPES AND MEMBER FUNCTIONS
// =========================================================================
  function inlineForEquation
    "inlines for-equations of size 1 to its body equation by replacing
    the iterators by the only values they are ever going to be."
    input output Equation eqn;
  algorithm
    eqn := match eqn
      local
        Equation new_eqn;
        UnorderedMap<ComponentRef, Expression> replacements     "replacement map for iterator crefs";
        list<ComponentRef> names;
        list<Expression> ranges;
        ComponentRef name;
        Expression range;
        Integer start;

      case Equation.FOR_EQUATION(body = {new_eqn}) guard(Equation.size(Pointer.create(eqn)) == 1) algorithm
        replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
        (names, ranges) := Iterator.getFrames(eqn.iter);
        for tpl in List.zip(names, ranges) loop
          (name, range) := tpl;
          (start, _, _) := Expression.getIntegerRange(range);
          UnorderedMap.add(name, Expression.INTEGER(start), replacements);
        end for;
        new_eqn := Equation.map(new_eqn, function Replacements.applySimpleExp(replacements = replacements));
        if Flags.isSet(Flags.DUMPBACKENDINLINE) then
          print("[" + getInstanceName() + "] Inlining: " + Equation.toString(eqn) + "\n");
          print("-- Result: " + Equation.toString(new_eqn) + "\n");
        end if;
      then new_eqn;

      else eqn;
    end match;
  end inlineForEquation;

protected
  function inline extends Module.inlineInterface;
  protected
    UnorderedMap<Absyn.Path, Function> replacements "rules for replacements are stored inside here";
  algorithm
    // collect functions
    replacements := UnorderedMap.new<Function>(AbsynUtil.pathHash, AbsynUtil.pathEqual);
    replacements := FunctionTree.fold(funcTree, function collectInlineFunctions(inline_types = inline_types), replacements);

    // apply replacements
    eqData := Replacements.replaceFunctions(eqData, replacements);
    eqData := inlineRecords(eqData, VarData.getVariables(varData));
  end inline;

  function collectInlineFunctions
    "collects all functions that have one of the inline types,
    use with FunctionTree.fold()"
    input Absyn.Path key;
    input Function value;
    input output UnorderedMap<Absyn.Path, Function> replacements;
    input list<DAE.InlineType> inline_types;
  algorithm
    // only add to the map if the function has one of the inline types and is inlineable
    if List.contains(inline_types, Function.inlineBuiltin(value), DAEUtil.inlineTypeEqual) and functionInlineable(value) then
      UnorderedMap.add(key, value, replacements);
    end if;
  end collectInlineFunctions;

  function functionInlineable
    "returns true if the function can be inlined"
    input Function fn;
    output Boolean b = false;
  algorithm
    // currently we only inline single assignments
    // also check for single output?
    if Function.hasSingleOrEmptyBody(fn) then
      b := match Function.getBody(fn)
        case {Statement.ASSIGNMENT()} then true;
        else false;
      end match;
    end if;
  end functionInlineable;

  function inlineRecords
    input output EqData eqData;
    input VariablePointers variables;
  protected
    Pointer<list<Pointer<Equation>>> record_eqns = Pointer.create({});
  algorithm
    eqData := EqData.map(eqData, function inlineRecordEquation(variables = variables, record_eqns = record_eqns, index = EqData.getUniqueIndex(eqData)));
    eqData := EqData.addUntypedList(eqData, Pointer.access(record_eqns), false);
    eqData := EqData.compress(eqData);
  end inlineRecords;

  function inlineRecordEquation
    "tries to inline a record equation. Removes the old equation by making it a dummy
    and appends new equations to the mutable list.
    EquationPointers.compress() should be used afterwards to remove the dummy equations."
    input output Equation eqn;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> record_eqns;
    input Pointer<Integer> index;
  algorithm
    eqn := match eqn
      local
        Equation new_eqn;
        Integer size;

      // don't inline simple cref equalities
      case Equation.RECORD_EQUATION(lhs = Expression.CREF(), rhs = Expression.CREF()) then eqn;
      case Equation.ARRAY_EQUATION(lhs = Expression.CREF(), rhs = Expression.CREF()) then eqn;

      // try to inline other record equations. try catch to be sure to not discard
      case Equation.RECORD_EQUATION() algorithm
        try
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then print("[" + getInstanceName() + "] Inlining: " + Equation.toString(eqn) + "\n"); end if;
          new_eqn := inlineRecordEquationWork(eqn.lhs, eqn.rhs, eqn.attr, eqn.source, eqn.recordSize, variables, record_eqns, index);
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then print("\n"); end if;
        else
          // inlining failed, keep old equation
          new_eqn := eqn;
        end try;
      then new_eqn;

      // only if record size is not NONE()
      case Equation.ARRAY_EQUATION(recordSize = SOME(size)) algorithm
        try
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then
            print("[" + getInstanceName() + "] Inlining: " + Equation.toString(eqn) + "\n");
          end if;
          new_eqn := inlineRecordEquationWork(eqn.lhs, eqn.rhs, eqn.attr, eqn.source, size, variables, record_eqns, index);
        else
          // inlining failed, keep old equation
          new_eqn := eqn;
        end try;
      then new_eqn;

      // iterate over body equations of for-loop
      case Equation.FOR_EQUATION() algorithm
        eqn.body := list(inlineRecordEquation(body_eqn, variables, record_eqns, index) for body_eqn in eqn.body);
      then eqn;

      else eqn;
    end match;
  end inlineRecordEquation;

  function inlineRecordEquationWork
    input Expression lhs;
    input Expression rhs;
    input EquationAttributes attr;
    input DAE.ElementSource src;
    input Integer recordSize;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> record_eqns;
    input Pointer<Integer> index;
    output Equation new_eqn;
  protected
    list<Pointer<Equation>> tmp_eqns;
    Pointer<Equation> tmp_eqn;
    Pointer<list<Pointer<Equation>>> tmp_eqns_ptr;
    Expression new_lhs, new_rhs;
  algorithm
    tmp_eqns := Pointer.access(record_eqns);
    for i in 1:recordSize loop
      new_lhs := Expression.nthRecordElement(i, lhs);
      new_rhs := Expression.nthRecordElement(i, rhs);

      // lower indexed record constructor elements
      new_lhs := Expression.map(new_lhs, inlineRecordConstructorElements);
      new_rhs := Expression.map(new_rhs, inlineRecordConstructorElements);

      // lower the new component references of record attributes
      new_lhs := Expression.map(new_lhs, function BackendDAE.lowerComponentReferenceExp(variables = variables));
      new_rhs := Expression.map(new_rhs, function BackendDAE.lowerComponentReferenceExp(variables = variables));

      // create new equation
      tmp_eqn := Equation.fromLHSandRHS(new_lhs, new_rhs, index, NBEquation.SIMULATION_STR, attr, src);

      // if the equation still has a record type, inline it further
      if Equation.isRecordEquation(tmp_eqn) then
        tmp_eqns_ptr := Pointer.create(tmp_eqns);
        _ := inlineRecordEquation(Pointer.access(tmp_eqn), variables, tmp_eqns_ptr, index);
        tmp_eqns := Pointer.access(tmp_eqns_ptr);
      else
        tmp_eqns := tmp_eqn :: tmp_eqns;
        if Flags.isSet(Flags.DUMPBACKENDINLINE) then
          print("-- Result: " + Equation.toString(Pointer.access(tmp_eqn)) + "\n");
        end if;
      end if;
    end for;
    Pointer.update(record_eqns, tmp_eqns);
    new_eqn := Equation.DUMMY_EQUATION();
  end inlineRecordEquationWork;

  function inlineRecordConstructorElements
    "removes indexed constructor element calls
    Constructor(a,b,c)[2] --> b"
    input output Expression exp;
  algorithm
    exp := match exp
      local
        Expression new_exp;
        Call call;
        Function fn;

      case Expression.RECORD_ELEMENT(recordExp = Expression.CALL(call = call as Call.TYPED_CALL(fn = fn))) algorithm
        if Function.isDefaultRecordConstructor(fn) then
          new_exp := listGet(call.arguments, exp.index);
        elseif Function.isNonDefaultRecordConstructor(fn) then
          // ToDo: this has to be mapped correctly with the body.
          //   for non default record constructors its not always the
          //   case that inputs map 1:1 to attributes
          new_exp := listGet(call.arguments, exp.index);
        else
          new_exp := exp;
        end if;
      then new_exp;
      else exp;
    end match;
  end inlineRecordConstructorElements;


  annotation(__OpenModelica_Interface="backend");
end NBInline;
