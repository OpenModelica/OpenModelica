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
  import Type = NFType;

  // NB imports
  import Module = NBModule;
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointers, EqData, EquationAttributes, Iterator};
  import Replacements = NBReplacements;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointer, VariablePointers, VarData};

  // Util
  import Slice = NBSlice;
  import StringUtil;

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
      local
        EqData eqData;
        VarData varData;
      case BackendDAE.MAIN()
        algorithm
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then
            print(StringUtil.headline_4("[dumpBackendInline] Inlining operatations for: "
              + List.toString(inline_types, DAEDump.dumpInlineTypeBackendStr)));
          end if;
          (eqData, varData) := inline(bdae.eqData, bdae.varData, bdae.funcTree, inline_types);
          bdae.eqData := eqData;
          bdae.varData := varData;
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then
            print("\n");
          end if;
        then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
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
    "also inlines simple record equalities"
    input output EqData eqData;
    input VariablePointers variables;
  protected
    Pointer<Integer> index = EqData.getUniqueIndex(eqData);
    Pointer<list<Pointer<Equation>>> new_eqns = Pointer.create({});
  algorithm
    eqData := EqData.map(eqData, function inlineRecordEquation(iter = Iterator.EMPTY(), variables = variables, record_eqns = new_eqns, index = index, inlineSimple = true));
    eqData := EqData.addUntypedList(eqData, Pointer.access(new_eqns), false);
    eqData := EqData.compress(eqData);
  end inlineRecords;

  function inlineRecordSliceEquation
    input Slice<Pointer<Equation>> slice;
    input VariablePointers variables;
    input Pointer<Integer> index;
    input Boolean inlineSimple;
    output list<Slice<Pointer<Equation>>> slices;
  protected
    Pointer<list<Pointer<Equation>>> record_eqns = Pointer.create({});
  algorithm
    inlineRecordEquation(Pointer.access(Slice.getT(slice)), Iterator.EMPTY(), variables, record_eqns, index, inlineSimple);
    // somehow split slice.indices
    slices := list(Slice.SLICE(eqn, {}) for eqn in Pointer.access(record_eqns));
  end inlineRecordSliceEquation;

protected
  function inline extends Module.inlineInterface;
  protected
    UnorderedMap<Absyn.Path, Function> replacements "rules for replacements are stored inside here";
    UnorderedSet<VariablePointer> set "new iterators from function bodies";
    VariablePointers variables = VarData.getVariables(varData);
  algorithm
    // collect functions
    replacements := UnorderedMap.new<Function>(AbsynUtil.pathHash, AbsynUtil.pathEqual);
    replacements := FunctionTree.fold(funcTree, function collectInlineFunctions(inline_types = inline_types), replacements);

    // apply replacements
    eqData  := Replacements.replaceFunctions(eqData, variables, replacements);

    // replace record constucters after functions because record operator
    // functions will produce record constructors once inlined
    eqData  := inlineRecordsTuples(eqData, variables);

    // collect new iterators from replaced function bodies
    set     := UnorderedSet.new(BVariable.hash, BVariable.equalName);
    eqData  := EqData.map(eqData, function BackendDAE.lowerEquationIterators(variables = variables, set = set));
    varData := VarData.addTypedList(varData, UnorderedSet.toList(set), NBVariable.VarData.VarType.ITERATOR);
    eqData  := EqData.mapExp(eqData, function BackendDAE.lowerComponentReferenceExp(variables = variables));
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

  function inlineRecordsTuples
    "does not inline simple record equalities"
    input output EqData eqData;
    input VariablePointers variables;
  protected
    Pointer<Integer> index = EqData.getUniqueIndex(eqData);
    Pointer<list<Pointer<Equation>>> new_eqns = Pointer.create({});
  algorithm
    eqData := EqData.map(eqData, function inlineRecordEquation(iter = Iterator.EMPTY(), variables = variables, record_eqns = new_eqns, index = index, inlineSimple = false));
    eqData := EqData.map(eqData, function inlineTupleEquation(index = index, iter = Iterator.EMPTY(), tuple_eqns = new_eqns));
    eqData := EqData.addUntypedList(eqData, Pointer.access(new_eqns), false);
    eqData := EqData.compress(eqData);
  end inlineRecordsTuples;

  function inlineRecordEquation
    "tries to inline a record equation. Removes the old equation by making it a dummy
    and appends new equations to the mutable list.
    EquationPointers.compress() should be used afterwards to remove the dummy equations."
    input output Equation eqn;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> record_eqns;
    input Pointer<Integer> index;
    input Boolean inlineSimple;
  algorithm
    eqn := match eqn
      local
        Equation new_eqn;
        Integer size;
        String str;

      // don't inline simple cref equalities
      case Equation.RECORD_EQUATION(lhs = Expression.CREF(), rhs = Expression.CREF()) guard(not inlineSimple) then eqn;
      case Equation.ARRAY_EQUATION(lhs = Expression.CREF(), rhs = Expression.CREF())  guard(not inlineSimple) then eqn;

      // try to inline other record equations. try catch to be sure to not discard
      case Equation.RECORD_EQUATION(ty = Type.COMPLEX()) algorithm
        try
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then
            str := "[" + getInstanceName() + "] Inlining: ";
            if Iterator.isEmpty(iter) then
              str := str + Equation.toString(eqn);
            else
              str := str + "\n" + Equation.forEquationToString(iter, {eqn}, "", "[----] ", "[FOR-] " + "(" + intString(Equation.size(Pointer.create(eqn)) * Iterator.size(iter)) + ")" + EquationAttributes.toString(eqn.attr, " "));
            end if;
            print(str + "\n");
          end if;
          new_eqn := inlineRecordEquationWork(eqn.lhs, eqn.rhs, iter, eqn.attr, eqn.recordSize, variables, record_eqns, index, inlineSimple);
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then print("\n"); end if;
        else
          // inlining failed, keep old equation
          new_eqn := eqn;
        end try;
      then new_eqn;

      // only if record size is not NONE()
      case Equation.ARRAY_EQUATION(recordSize = SOME(size)) algorithm
        try
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then print("[" + getInstanceName() + "] Inlining: " + Equation.toString(eqn) + "\n"); end if;
          new_eqn := inlineRecordEquationWork(eqn.lhs, eqn.rhs, iter, eqn.attr, size, variables, record_eqns, index, inlineSimple);
        else
          // inlining failed, keep old equation
          new_eqn := eqn;
        end try;
      then new_eqn;

      // iterate over body equations of for-loop
      case Equation.FOR_EQUATION() algorithm
        new_eqn := inlineRecordEquation(List.first(eqn.body), eqn.iter, variables, record_eqns, index, inlineSimple);
        new_eqn := if Equation.isDummy(new_eqn) then new_eqn else eqn;
      then new_eqn;

      else eqn;
    end match;
  end inlineRecordEquation;

  function inlineRecordEquationWork
    input Expression lhs;
    input Expression rhs;
    input Iterator iter;
    input EquationAttributes attr;
    input Integer recordSize;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> record_eqns;
    input Pointer<Integer> index;
    input Boolean inlineSimple;
    output Equation new_eqn;
  protected
    list<Pointer<Equation>> tmp_eqns;
    Pointer<Equation> tmp_eqn;
    Pointer<list<Pointer<Equation>>> tmp_eqns_ptr;
    Expression new_lhs, new_rhs;
  algorithm
    tmp_eqns := Pointer.access(record_eqns);
    for i in 1:recordSize loop
      new_lhs := inlineRecordExp(lhs, i, variables);
      new_rhs := inlineRecordExp(rhs, i, variables);

      // create new equation
      tmp_eqn := Equation.makeAssignment(new_lhs, new_rhs, index, NBEquation.SIMULATION_STR, iter, attr);

      // if the equation still has a record type, inline it further
      if Equation.isRecordEquation(tmp_eqn) then
        tmp_eqns_ptr := Pointer.create(tmp_eqns);
        _ := inlineRecordEquation(Pointer.access(tmp_eqn), iter, variables, tmp_eqns_ptr, index, inlineSimple);
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

public
  function inlineRecordExp
    "inlines record constructors in a single expression"
    input output Expression exp;
    input Integer index;
    input VariablePointers variables;
  algorithm
    exp := Expression.nthRecordElement(index, exp);
    // lower indexed record constructor elements
    exp := Expression.map(exp, inlineRecordConstructorElements);
    // lower the new component references of record attributes
    exp := Expression.map(exp, function BackendDAE.lowerComponentReferenceExp(variables = variables));
  end inlineRecordExp;

protected
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

  function inlineTupleEquation
    "inlines equations of the form TPL1 = TPL2 which is not modelica standard but can be created
    by the function alias module and need to be removed afterwards"
    input output Equation eqn;
    input Pointer<Integer> index;
    input Iterator iter;
    input Pointer<list<Pointer<Equation>>> tuple_eqns;
  algorithm
    eqn := match eqn
      local
        list<Pointer<Equation>> eqns;
        list<Expression> lhs_elems, rhs_elems;
        Expression lhs, rhs;
        Pointer<Equation> tmp_eqn;
        Equation new_eqn, body_eqn;

      case Equation.RECORD_EQUATION() algorithm
        lhs_elems := getElementList(eqn.lhs);
        rhs_elems := getElementList(eqn.rhs);
        if not listEmpty(lhs_elems) and listLength(lhs_elems) == listLength(rhs_elems) then
          if Flags.isSet(Flags.DUMPBACKENDINLINE) then
            print("[" + getInstanceName() + "] Inlining: " + Equation.toString(eqn) + "\n");
          end if;
          eqns := Pointer.access(tuple_eqns);
          for tpl in List.zip(lhs_elems, rhs_elems) loop
            (lhs, rhs) := tpl;
            if not (Expression.isWildCref(lhs) or Expression.isWildCref(rhs)) then
              tmp_eqn := Equation.makeAssignment(lhs, rhs, index, NBVariable.AUXILIARY_STR, iter, eqn.attr);
              if Flags.isSet(Flags.DUMPBACKENDINLINE) then
                print("-- Result: " + Equation.toString(Pointer.access(tmp_eqn)) + "\n");
              end if;
              eqns := tmp_eqn :: eqns;
            end if;
          end for;
          Pointer.update(tuple_eqns, eqns);
          new_eqn := Equation.DUMMY_EQUATION();
        else
          new_eqn := eqn;
        end if;
      then new_eqn;

      // inline tuple equations in for loops
      case Equation.FOR_EQUATION(body = {body_eqn}) algorithm
        body_eqn := inlineTupleEquation(body_eqn, index, eqn.iter, tuple_eqns);
        if Equation.isDummy(body_eqn) then
          new_eqn := Equation.DUMMY_EQUATION();
        else
          new_eqn := eqn;
        end if;
      then new_eqn;

      // ToDo: inline tuple in if and when

      else eqn;
    end match;
  end inlineTupleEquation;

  function getElementList
    input Expression exp;
    output list<Expression> elements;
  algorithm
    elements := match exp
      local
        Expression sub_exp, elem;

      case Expression.TUPLE() then exp.elements;

      case Expression.TUPLE_ELEMENT(tupleExp = sub_exp as Expression.TUPLE()) algorithm
        if exp.index > listLength(sub_exp.elements) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to get subscripted tuple element: " + Expression.toString(exp)});
          fail();
        else
          elem := listGet(sub_exp.elements, exp.index);
        end if;
      then {elem};

      else {};
    end match;
  end getElementList;


  annotation(__OpenModelica_Interface="backend");
end NBInline;
