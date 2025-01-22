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
  import InstNode = NFInstNode.InstNode;
  import Statement = NFStatement;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // NB imports
  import Module = NBModule;
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, IfEquationBody, EquationPointers, EqData, EquationAttributes, Iterator};
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
    input Boolean init;
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
          (eqData, varData) := inline(bdae.eqData, bdae.varData, bdae.funcTree, inline_types, init);
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

      case Equation.FOR_EQUATION(body = {new_eqn}) guard(Iterator.size(eqn.iter) == 1) algorithm
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

  function inlineRecordSliceEquation
    input Slice<Pointer<Equation>> slice;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Boolean inlineSimple;
    output list<Slice<Pointer<Equation>>> slices;
  protected
    Pointer<list<Pointer<Equation>>> record_eqns = Pointer.create({});
  algorithm
    inlineRecordTupleArrayEquation(Pointer.access(Slice.getT(slice)), Iterator.EMPTY(), variables, record_eqns, set, index, inlineSimple);
    // somehow split slice.indices
    slices := list(Slice.SLICE(eqn, {}) for eqn in Pointer.access(record_eqns));
    if listEmpty(slices) then
      slices := {slice};
    end if;
  end inlineRecordSliceEquation;

  function inlineArrayConstructorSingle
    input output Equation eqn;
    input Iterator iter;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Pointer<list<Pointer<Equation>>> new_eqns = Pointer.create({});
    output Boolean changed;
  algorithm
    try
      (eqn, changed) := match eqn
        local
          Equation new_eqn, body;
          Expression lhs, rhs;
          Call call;

        // CREF = {... for i in []} array constructor equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.CREF(), rhs = rhs as Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR())) algorithm
        then (inlineArrayConstructor(eqn, lhs.cref, call.exp, call.iters, eqn.attr, iter, variables, new_eqns, set, index), true);

        // {... for i in []} = CREF array constructor equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()), rhs = rhs as Expression.CREF()) algorithm
        then (inlineArrayConstructor(eqn, rhs.cref, call.exp, call.iters, eqn.attr, iter, variables, new_eqns, set, index), true);

        // apply on for-equation. assumed to be split up
        case Equation.FOR_EQUATION(body = {body}) algorithm
          (new_eqn, changed) := inlineArrayConstructorSingle(body, eqn.iter, variables, set, index, new_eqns);
          new_eqn := if changed then new_eqn else eqn;
        then (new_eqn, changed);

        // nothing happens
        else (eqn, false);
      end match;
      // unpack the equation
      eqn := if Equation.isDummy(eqn) then Pointer.access(List.first(Pointer.access(new_eqns))) else eqn;
    else
      changed := false;
      if Flags.isSet(Flags.FAILTRACE) then
        Error.addCompilerWarning("Failed to inline following equation:\n" + Equation.toString(eqn));
      end if;
    end try;
  end inlineArrayConstructorSingle;

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

    // do not inline records tuples and arrays after causalization
    // ToDo: do it properly on strong components, cannot remove equations here
    set     := UnorderedSet.new(BVariable.hash, BVariable.equalName);
    if not List.any(inline_types, function DAEUtil.inlineTypeEqual(it2 = DAE.AFTER_INDEX_RED_INLINE())) then
      // replace record constucters after functions because record operator
      // functions will produce record constructors once inlined
      eqData  := inlineRecordsTuplesArrays(eqData, variables, set, init);
    end if;

    // collect new iterators from replaced function bodies
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

  function inlineRecordsTuplesArrays
    "does not inline simple record equalities"
    input output EqData eqData;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Boolean init;
  protected
    Pointer<Integer> index = EqData.getUniqueIndex(eqData);
    Pointer<list<Pointer<Equation>>> new_eqns = Pointer.create({});
  algorithm
    if init then
      eqData := match eqData
        case EqData.EQ_DATA_SIM() algorithm
          eqData.initials := EquationPointers.map(eqData.initials, function inlineRecordTupleArrayEquation(iter = Iterator.EMPTY(), variables = variables, new_eqns = new_eqns, set = set, index = index, inlineSimple = false));
          eqData.initials := EquationPointers.addList(Pointer.access(new_eqns), eqData.initials);
          eqData.initials := EquationPointers.compress(eqData.initials);
        then eqData;

        else eqData;
      end match;
    else
      eqData := EqData.map(eqData, function inlineRecordTupleArrayEquation(iter = Iterator.EMPTY(), variables = variables, new_eqns = new_eqns, set = set, index = index, inlineSimple = false));
      eqData := EqData.addUntypedList(eqData, Pointer.access(new_eqns), false);
      eqData := EqData.compress(eqData);
    end if;
  end inlineRecordsTuplesArrays;

  function inlineRecordTupleArrayEquation
    input output Equation eqn;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Boolean inlineSimple;
  algorithm
    try
      eqn := match eqn
        local
          Equation new_eqn, body;
          Expression lhs, rhs;
          Call call;
          list<Expression> elements;
          Integer size;

        // don't inline simple cref equalities
        case Equation.RECORD_EQUATION(lhs = Expression.CREF(), rhs = Expression.CREF()) guard(not inlineSimple) then eqn;
        case Equation.ARRAY_EQUATION(lhs = Expression.CREF(), rhs = Expression.CREF())  guard(not inlineSimple) then eqn;

        // try to inline other record equations. try catch to be sure to not discard
        case Equation.RECORD_EQUATION(ty = Type.COMPLEX()) then inlineRecordEquation(eqn, eqn.lhs, eqn.rhs, iter, eqn.attr, eqn.recordSize, variables, new_eqns, set, index, inlineSimple);

        // only if record size is not NONE()
        case Equation.ARRAY_EQUATION(recordSize = SOME(size)) then inlineRecordEquation(eqn, eqn.lhs, eqn.rhs, iter, eqn.attr, size, variables, new_eqns, set, index, inlineSimple);

        // inlining potential tuple equations
        case Equation.RECORD_EQUATION() then inlineTupleEquation(eqn, eqn.lhs, eqn.rhs, eqn.attr, iter, variables, new_eqns, set, index);

        // {...} = {...} array equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.ARRAY(), rhs = rhs as Expression.ARRAY())
        then inlineArrayEquation(eqn, lhs.elements, rhs.elements, eqn.attr, iter, variables, new_eqns, set, index);

        // CREF = {...} array equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.CREF(), rhs = rhs as Expression.ARRAY()) algorithm
          elements := list(NFExpression.applySubscripts({Subscript.INDEX(Expression.INTEGER(i))}, lhs) for i in 1:arrayLength(rhs.elements));
        then inlineArrayEquation(eqn, listArray(elements), rhs.elements, eqn.attr, iter, variables, new_eqns, set, index);

        // {...} = CREF array equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.ARRAY(), rhs = rhs as Expression.CREF()) algorithm
          elements := list(NFExpression.applySubscripts({Subscript.INDEX(Expression.INTEGER(i))}, rhs) for i in 1:arrayLength(lhs.elements));
        then inlineArrayEquation(eqn, lhs.elements, listArray(elements), eqn.attr, iter, variables, new_eqns, set, index);

        // CREF = {... for i in []} array constructor equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.CREF(), rhs = rhs as Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()))
        then inlineArrayConstructor(eqn, lhs.cref, call.exp, call.iters, eqn.attr, iter, variables, new_eqns, set, index);

        // {... for i in []} = CREF array constructor equation
        case Equation.ARRAY_EQUATION(lhs = lhs as Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()), rhs = rhs as Expression.CREF())
        then inlineArrayConstructor(eqn, rhs.cref, call.exp, call.iters, eqn.attr, iter, variables, new_eqns, set, index);

        // apply on for-equation. assumed to be split up
        case Equation.FOR_EQUATION(body = {body}) algorithm
          new_eqn := inlineRecordTupleArrayEquation(body, eqn.iter, variables, new_eqns, set, index, true);
          new_eqn := if Equation.isDummy(new_eqn) then new_eqn else eqn;
        then new_eqn;

        // apply on if-equation body equations
        case Equation.IF_EQUATION() guard IfEquationBody.isRecordOrTupleEquation(eqn.body) algorithm
          new_eqn := inlineRecordTupleArrayIfEquation(eqn, eqn.body, iter, variables, new_eqns, set, index, inlineSimple);
          new_eqn := if Equation.isDummy(new_eqn) then new_eqn else eqn;
        then new_eqn;

        // nothing happens
        else eqn;
      end match;
    else
      if Flags.isSet(Flags.FAILTRACE) then
        Error.addCompilerWarning("Failed to inline following equation:\n" + Equation.toString(eqn));
      end if;
    end try;
  end inlineRecordTupleArrayEquation;

  function inlineRecordTupleArrayIfEquation
    "Documentation"
    input output Equation eqn;
    input IfEquationBody body;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Boolean inlineSimple;
  protected
    list<Pointer<Equation>> eqns;
    IfEquationBody new_body;
    Pointer<Equation> new_eqn;
  algorithm
    eqns := Pointer.access(new_eqns);
    new_body := inlineRecordTupleArrayIfBody(body, iter, variables, set, index, inlineSimple);
    for b in IfEquationBody.split(new_body) loop
      new_eqn := IfEquationBody.makeIfEquation(b, index, NBEquation.SIMULATION_STR, iter, Equation.getSource(eqn), Equation.getAttributes(eqn));
      eqns := new_eqn :: eqns;
    end for;
    Pointer.update(new_eqns, eqns);
    eqn := Equation.DUMMY_EQUATION();
  end inlineRecordTupleArrayIfEquation;

  function inlineRecordTupleArrayIfBody
    "Documentation"
    input output IfEquationBody body;
    input Iterator iter;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Boolean inlineSimple;
  protected
    Pointer<list<Pointer<Equation>>> new_eqns = Pointer.create({});
  algorithm
    body.then_eqns := List.flatten(list(
      match inlineRecordTupleArrayEquation(Pointer.access(e), iter, variables, new_eqns, set, index, inlineSimple)
        case Equation.DUMMY_EQUATION() then Pointer.access(new_eqns);
        else {e};
      end match for e in body.then_eqns));
    body.else_if := Util.applyOption(body.else_if, function inlineRecordTupleArrayIfBody(iter = iter, variables = variables, set = set, index = index, inlineSimple = inlineSimple));
  end inlineRecordTupleArrayIfBody;

  function inlineRecordEquation
    "tries to inline a record equation. Removes the old equation by making it a dummy
    and appends new equations to the mutable list.
    EquationPointers.compress() should be used afterwards to remove the dummy equations."
    input output Equation eqn;
    input Expression lhs;
    input Expression rhs;
    input Iterator iter;
    input EquationAttributes attr;
    input Integer recordSize;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
    input Boolean inlineSimple;
  protected
    Expression new_lhs, new_rhs;
    list<Pointer<Equation>> eqns;
  algorithm
    if Flags.isSet(Flags.DUMPBACKENDINLINE) then
      print("[" + getInstanceName() + "] Inlining: " + Equation.toString(eqn) + "\n");
    end if;
    eqns := Pointer.access(new_eqns);
    for i in 1:recordSize loop
      new_lhs := inlineRecordConstructorExp(lhs, i, variables);
      new_rhs := inlineRecordConstructorExp(rhs, i, variables);
      eqns    := createInlinedEquation(eqns, new_lhs, new_rhs, attr, iter, variables, set, index);
    end for;
    Pointer.update(new_eqns, eqns);
    eqn := Equation.DUMMY_EQUATION();
  end inlineRecordEquation;

  function inlineTupleEquation
    "online inlines of LHS and RHS are of type Tuple"
    input output Equation eqn;
    input Expression LHS;
    input Expression RHS;
    input EquationAttributes attr;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
  protected
    list<Pointer<Equation>> eqns;
    list<Expression> lhs_elems, rhs_elems;
    Expression lhs, rhs;
    Pointer<Equation> tmp_eqn;
  algorithm
    lhs_elems := getElementList(LHS);
    rhs_elems := getElementList(RHS);
    if not listEmpty(lhs_elems) and List.compareLength(lhs_elems, rhs_elems) == 0 then
      if Flags.isSet(Flags.DUMPBACKENDINLINE) then
        print("[" + getInstanceName() + "] Inlining: " + Equation.toString(eqn) + "\n");
      end if;
      eqns := Pointer.access(new_eqns);
      for tpl in List.zip(lhs_elems, rhs_elems) loop
        (lhs, rhs) := tpl;
        // skip wild cref assignments
        if not (Expression.isWildCref(lhs) or Expression.isWildCref(rhs)) then
          eqns := createInlinedEquation(eqns, lhs, rhs, attr, iter, variables, set, index);
        end if;
      end for;
      Pointer.update(new_eqns, eqns);
      eqn := Equation.DUMMY_EQUATION();
    end if;
  end inlineTupleEquation;

  function inlineArrayEquation
    "inlines array equations of the form {a, b, c, ...} = {d, e, f, ...}
    to a = d; and so on. Also inlines them if inside for-equation or nested arrays.
    ToDo: inside When/If"
    input output Equation eqn;
    input array<Expression> lhs_elements;
    input array<Expression> rhs_elements;
    input EquationAttributes attr;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
  protected
    Pointer<list<Pointer<Equation>>> tmp_eqns;
    Equation inlined;
    list<Pointer<Equation>> eqns;
    Pointer<Equation> new_eqn;
  algorithm
    if Flags.isSet(Flags.DUMPBACKENDINLINE) then
      print("[" + getInstanceName() + "] Inlining: " + Equation.toString(eqn) + "\n");
    end if;
    eqns := Pointer.access(new_eqns);
    for i in 1: arrayLength(lhs_elements) loop
      eqns := createInlinedEquation(eqns, lhs_elements[i], rhs_elements[i], attr, iter, variables, set, index);
    end for;
    Pointer.update(new_eqns, eqns);
    eqn := Equation.DUMMY_EQUATION();
  end inlineArrayEquation;

  function inlineArrayConstructor
    input output Equation eqn;
    input ComponentRef cref;
    input Expression rhs;
    input list<tuple<InstNode, Expression>> iters;
    input EquationAttributes attr;
    input Iterator iter;
    input VariablePointers variables;
    input Pointer<list<Pointer<Equation>>> new_eqns;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
  protected
    list<tuple<ComponentRef, Expression, Option<Iterator>>> frames;
    list<Subscript> subs;
    Expression cref_exp;
    list<Pointer<Equation>> eqns;
  algorithm
    if Flags.isSet(Flags.DUMPBACKENDINLINE) then
      print("[" + getInstanceName() + "] Inlining: " + Equation.toString(eqn) + "\n");
    end if;
    eqns := Pointer.access(new_eqns);

    // inline the iterators
    frames := list(inlineArrayIterator(iter, set) for iter in iters);

    // add the iterators to the cref
    subs      := Iterator.normalizedSubscripts(Iterator.fromFrames(frames));
    //subs      := list(Subscript.INDEX(Expression.CREF(Type.INTEGER(), Util.tuple31(tpl))) for tpl in frames);
    cref_exp  := Expression.fromCref(ComponentRef.mergeSubscripts(subs, cref, true));
    eqns      := createInlinedEquation(eqns, cref_exp, rhs, attr, Iterator.addFrames(iter, frames), variables, set, index);
    Pointer.update(new_eqns, eqns);
    eqn := Equation.DUMMY_EQUATION();
  end inlineArrayConstructor;

  function inlineArrayIterator
    input tuple<InstNode, Expression> iter;
    input UnorderedSet<VariablePointer> set "new iterators";
    output tuple<ComponentRef, Expression, Option<Iterator>> frame;
  algorithm
    frame := match iter
      local
        InstNode node, node2;
        Expression range, range2;
        Iterator map;
        ComponentRef iter_cref;
        Pointer<Variable> iter_var;

      // it already is a proper range, use it for the for loop
      case (node, range as Expression.RANGE()) then (ComponentRef.makeIterator(node, Type.INTEGER()), range, NONE());

      // it has an array as constructor, map it to a range
      // used to fix #13031
      case (node, range as Expression.ARRAY()) algorithm
        node2   := InstNode.newIterator("$" + InstNode.name(node), Type.INTEGER(), sourceInfo());
        range2  := Expression.makeRange(Expression.INTEGER(1), NONE(), Expression.INTEGER(Type.sizeOf(Expression.typeOf(range))));
        map     := Iterator.fromFrames({(ComponentRef.makeIterator(node, Type.INTEGER()), range, NONE())});

        // create the new iterator variable
        iter_cref := ComponentRef.makeIterator(node2, Type.INTEGER());
        iter_var  := BackendDAE.lowerIterator(iter_cref);
        iter_cref := BVariable.getVarName(iter_var);
        UnorderedSet.add(iter_var, set);
      then (iter_cref, range2, SOME(map));

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to inline iterator expression: " + InstNode.toString(Util.tuple21(iter)) + " in " + Expression.toString(Util.tuple22(iter)) + "."});
      then fail();
    end match;
  end inlineArrayIterator;

  function createInlinedEquation
    "used for inlining record, tuple and array equations.
    tries to create new equation from lhs and rhs and applying
    the inlining methods on the results"
    input output list<Pointer<Equation>> eqns;
    input Expression lhs;
    input Expression rhs;
    input EquationAttributes attr;
    input Iterator iter;
    input VariablePointers variables;
    input UnorderedSet<VariablePointer> set "new iterators";
    input Pointer<Integer> index;
  protected
    Pointer<list<Pointer<Equation>>> tmp_eqns = Pointer.create({});
    Equation inlined;
    Pointer<Equation> new_eqn;
  algorithm
    new_eqn := Equation.makeAssignment(lhs, rhs, index, NBEquation.SIMULATION_STR, iter, attr);
    inlined := inlineRecordTupleArrayEquation(Pointer.access(new_eqn), iter, variables, tmp_eqns, set, index, false);
    eqns := match inlined
      case Equation.DUMMY_EQUATION() then listAppend(eqns, Pointer.access(tmp_eqns));
      else algorithm
        if Flags.isSet(Flags.DUMPBACKENDINLINE) then
          print("-- Result: " + Equation.toString(inlined) + "\n");
        end if;
      then new_eqn :: eqns;
    end match;
  end createInlinedEquation;

  function inlineRecordConstructorExp
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
  end inlineRecordConstructorExp;

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

  function getElementList
    "used for inlining tuple equations
    returns the tuple elements of an expression"
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
