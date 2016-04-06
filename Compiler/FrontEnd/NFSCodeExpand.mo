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

encapsulated package NFSCodeExpand
" file:        NFSCodeExpand.mo
  package:     NFSCodeExpand
  description: Expands the output from SCodeInst into DAE form.


"

public import DAE;
public import HashTablePathToFunction;
public import NFInstTypes;

protected import Absyn;
protected import Algorithm;
protected import BaseHashTable;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import NFInstDump;
protected import NFInstUtil;
protected import List;
protected import SCode;
protected import Types;
protected import Util;

protected type Equation = NFInstTypes.Equation;
public type FunctionHashTable = HashTablePathToFunction.HashTable;
protected type Statement = NFInstTypes.Statement;

replaceable type ElementType subtypeof Any;
replaceable type AccumType subtypeof Any;

protected uniontype ExpandKind
  record EXPAND_MODEL end EXPAND_MODEL;
  record EXPAND_FUNCTION "Does not expand/scalarize arrays" end EXPAND_FUNCTION;
end ExpandKind;

partial function ExpandScalarFunc
  input ElementType inElement;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<AccumType> inAccumEl;
  output list<AccumType> outElements;
end ExpandScalarFunc;

public function expand
  input String inName;
  input NFInstTypes.Class inClass;
  input FunctionHashTable inFunctions;
  output DAE.DAElist outDAE;
  output DAE.FunctionTree outFunctions;
algorithm
  (outDAE, outFunctions) := matchcontinue(inName, inClass, inFunctions)
    local
      list<DAE.Element> el;
      DAE.DAElist dae;
      DAE.FunctionTree tree;
      Integer vars, params;
      list<DAE.Function> funcs;

    case (_, _, _)
      equation
        el = expandClass(inClass, {}, {});
        el = listReverse(el);
        dae = DAE.DAE({DAE.COMP(inName, el, DAE.emptyElementSource, NONE())});

        funcs = List.map(BaseHashTable.hashTableValueList(inFunctions), expandFunction);

        tree = DAE.AvlTreePathFunction.Tree.EMPTY();
        tree = DAEUtil.addDaeFunction(funcs, tree);

        (_,_) = countElements(el, 0, 0);
        //print("\nFound " + intString(vars) + " components and " +
        //  intString(params) + " parameters.\n");
      then
        (dae, tree);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("NFSCodeExpand.expand failed.\n");
      then
        fail();

  end matchcontinue;
end expand;

protected function countElements
  input list<DAE.Element> inElements;
  input Integer inVarCount;
  input Integer inParamCount;
  output Integer outVarCount;
  output Integer outParamCount;
algorithm
  (outVarCount, outParamCount) := match(inElements, inVarCount, inParamCount)
    local
      list<DAE.Element> rest_el;
      Integer vars, params;

    case ({}, _, _) then (inVarCount, inParamCount);

    case (DAE.VAR(kind = DAE.VARIABLE()) :: rest_el, _, _)
      equation
        (vars, params) = countElements(rest_el, inVarCount + 1, inParamCount);
      then
        (vars, params);

    case (DAE.VAR(kind = DAE.DISCRETE()) :: rest_el, _, _)
      equation
        (vars, params) = countElements(rest_el, inVarCount + 1, inParamCount);
      then
        (vars, params);

    case (DAE.VAR(kind = DAE.PARAM()) :: rest_el, _, _)
      equation
        (vars, params) = countElements(rest_el, inVarCount, inParamCount + 1);
      then
        (vars, params);

    case (_ :: rest_el, _, _)
      equation
        (vars, params) = countElements(rest_el, inVarCount, inParamCount);
      then
        (vars, params);

  end match;
end countElements;

protected function expandClass
  input NFInstTypes.Class inClass;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
algorithm
  outElements := match(inClass, inSubscripts, inAccumEl)
    local
      list<NFInstTypes.Element> comps;
      list<DAE.Element> el;
      list<Equation> eq;
      list<list<Statement>> al;

    case (NFInstTypes.BASIC_TYPE(_), _, _) then inAccumEl;

    case (NFInstTypes.COMPLEX_CLASS(components = comps, equations = eq, algorithms = al), _, _)
      equation
        el = List.fold2(comps, expandElement, EXPAND_MODEL(), inSubscripts, inAccumEl);
        el = List.fold1(eq, expandEquation, inSubscripts, el);
        el = expandArray((al,EXPAND_MODEL(),false /* not initial */), EXPAND_MODEL(), {}, {}::inSubscripts, el, expandStatementsList);
      then
        el;

  end match;
end expandClass;

protected function expandElement
  input NFInstTypes.Element inElement;
  input ExpandKind inKind;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
algorithm
  outElements := match(inElement, inKind, inSubscripts, inAccumEl)
    local
      NFInstTypes.Component comp;
      list<DAE.Element> el;
      NFInstTypes.Class cls;
      Absyn.Path path;
      String err_msg;
      DAE.Type ty;
      DAE.Dimensions dims;

    case (NFInstTypes.ELEMENT(component = comp, cls = NFInstTypes.BASIC_TYPE(_)), _, _, _)
      equation
        el = expandComponent(comp, inKind, inSubscripts, inAccumEl);
      then
        el;

    case (NFInstTypes.ELEMENT(component = NFInstTypes.TYPED_COMPONENT(ty = DAE.T_ARRAY(dims = dims)), cls = cls), _, _, _)
      equation
        el = expandArray(cls, inKind, dims, {} :: inSubscripts, inAccumEl, expandClass);
      then
        el;

    case (NFInstTypes.ELEMENT(cls = cls), _, _, _)
      equation
        el = expandClass(cls, {} :: inSubscripts, inAccumEl);
      then
        el;

    case (NFInstTypes.CONDITIONAL_ELEMENT(component = comp), _, _, _)
      equation
        path = NFInstUtil.getComponentName(comp);
        err_msg = "NFSCodeExpand.expandElement got unresolved conditional component " +
          Absyn.pathString(path) + "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
        inAccumEl;

  end match;
end expandElement;

protected function expandComponent
  input NFInstTypes.Component inComponent;
  input ExpandKind inKind;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
algorithm
  outElements := match(inComponent, inKind, inSubscripts, inAccumEl)
    local
      Absyn.Path name;
      DAE.Dimensions dims;
      list<DAE.Element> el;
      NFInstTypes.Component comp;
      String err_msg;
      SourceInfo info;

    case (NFInstTypes.TYPED_COMPONENT(ty = DAE.T_ARRAY(dims = dims)), _, _, _)
      equation
        comp = unliftComponentType(inComponent);
        el = expandArray(comp, inKind, dims, {} :: inSubscripts, inAccumEl, expandScalar);
      then
        el;

    case (NFInstTypes.TYPED_COMPONENT(), _, _, _)
      equation
        el = expandScalar(inComponent, {} :: inSubscripts, inAccumEl);
      then
        el;

    case (NFInstTypes.UNTYPED_COMPONENT(name = name, info = info), _, _, _)
      equation
        err_msg = "NFSCodeExpand.expandComponent got untyped component " +
          Absyn.pathString(name) + " at position: " + Error.infoStr(info) + "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
        fail();

    case (NFInstTypes.CONDITIONAL_COMPONENT(name = name, info = info), _, _, _)
      equation
        err_msg = "NFSCodeExpand.expandComponent got unresolved conditional component " +
          Absyn.pathString(name) + " at position: " + Error.infoStr(info) + "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
        inAccumEl;

    case (NFInstTypes.OUTER_COMPONENT(), _, _, _)
      then inAccumEl;

  end match;
end expandComponent;

protected function expandArray
  input ElementType inElement;
  input ExpandKind inKind;
  input list<DAE.Dimension> inDimensions;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<AccumType> inAccumEl;
  input ExpandScalarFunc inScalarFunc;
  output list<AccumType> outElements;
algorithm
  outElements :=
  match(inElement, inKind, inDimensions, inSubscripts, inAccumEl, inScalarFunc)
    local
      Integer dim,start;
      list<DAE.Dimension> rest_dims;
      list<AccumType> el;
      list<DAE.Subscript> subs;
      list<list<DAE.Subscript>> rest_subs;
      String dim_str;
      DAE.Exp exp;
      Absyn.Path enum_path;
      list<String> enum_lits;
      list<DAE.Exp> enum_expl;

    case (_, _, {}, subs :: rest_subs, _, _)
      equation
        subs = listReverse(subs);
        el = inScalarFunc(inElement, subs :: rest_subs, inAccumEl);
      then
        el;

    case (_, _, DAE.DIM_INTEGER(integer = dim) :: rest_dims, _, _, _)
      equation
        start = if isExpandFunction(inKind) then dim else 1;
        el = expandArrayIntDim(inElement, inKind, start, dim, rest_dims, inSubscripts,
            inAccumEl, inScalarFunc);
      then
        el;

    case (_, _, DAE.DIM_ENUM(enumTypeName = enum_path, literals = enum_lits) ::
        rest_dims, _, _, _)
      equation
        enum_expl = Expression.makeEnumLiterals(enum_path, enum_lits);
        el = expandArrayEnumDim(inElement, inKind, enum_expl, rest_dims,
          inSubscripts, inAccumEl, inScalarFunc);
      then
        el;

    case (_, EXPAND_FUNCTION(), DAE.DIM_EXP(exp) :: rest_dims, _ :: _, _, _)
      then expandArrayExpDim(inElement, DAE.INDEX(exp), rest_dims, inSubscripts, inAccumEl, inScalarFunc);

    case (_, EXPAND_FUNCTION(), DAE.DIM_UNKNOWN() :: rest_dims, _ :: _, _, _)
      then expandArrayExpDim(inElement, DAE.WHOLEDIM(), rest_dims, inSubscripts, inAccumEl, inScalarFunc);

    else
      equation
        dim_str = ExpressionDump.dimensionString(listHead(inDimensions));
        print("Unknown dimension " + dim_str + " in NFSCodeExpand.expandArray\n");
      then
        fail();

  end match;
end expandArray;

protected function expandArrayIntDim
  input ElementType inElement;
  input ExpandKind inKind;
  input Integer inIndex;
  input Integer inDimSize;
  input list<DAE.Dimension> inDimensions;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<AccumType> inAccumEl;
  input ExpandScalarFunc inScalarFunc;
  output list<AccumType> outElements;
algorithm
  outElements :=
  matchcontinue(inElement, inKind, inIndex, inDimSize, inDimensions, inSubscripts, inAccumEl, inScalarFunc)
    local
      list<DAE.Subscript> subs;
      list<list<DAE.Subscript>> rest_subs;
      list<AccumType> el;

    case (_, _, _, _, _, _, _, _)
      equation
        true = (inIndex > inDimSize);
      then
        inAccumEl;

    case (_, _, _, _, _, subs :: rest_subs, _, _)
      equation
        subs = DAE.INDEX(DAE.ICONST(inIndex)) :: subs;
        el = expandArray(inElement, inKind, inDimensions, subs :: rest_subs,
            inAccumEl, inScalarFunc);
      then
        expandArrayIntDim(inElement, inKind, inIndex + 1, inDimSize, inDimensions,
          inSubscripts, el, inScalarFunc);

  end matchcontinue;
end expandArrayIntDim;

protected function expandArrayEnumDim
  input ElementType inElement;
  input ExpandKind inKind;
  input list<DAE.Exp> inEnumLiterals;
  input list<DAE.Dimension> inDimensions;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<AccumType> inAccumEl;
  input ExpandScalarFunc inScalarFunc;
  output list<AccumType> outElements;
algorithm
  outElements := match(inElement, inKind, inEnumLiterals, inDimensions,
      inSubscripts, inAccumEl, inScalarFunc)
    local
      list<DAE.Subscript> subs;
      list<list<DAE.Subscript>> rest_subs;
      list<AccumType> el;
      DAE.Exp lit;
      list<DAE.Exp> rest_lits;

    case (_, _, lit :: rest_lits, _, subs :: rest_subs, _, _)
      equation
        subs = DAE.INDEX(lit) :: subs;
        el = expandArray(inElement, inKind, inDimensions, subs :: rest_subs,
          inAccumEl, inScalarFunc);
      then
        expandArrayEnumDim(inElement, inKind, rest_lits, inDimensions,
          inSubscripts, el, inScalarFunc);

    case (_, _, {}, _, _, _, _) then inAccumEl;

  end match;
end expandArrayEnumDim;

protected function expandArrayExpDim
  input ElementType inElement;
  input DAE.Subscript inSub;
  input list<DAE.Dimension> inDimensions;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<AccumType> inAccumEl;
  input ExpandScalarFunc inScalarFunc;
  output list<AccumType> outElements;
algorithm
  outElements :=  match (inElement, inSub, inDimensions, inSubscripts, inAccumEl, inScalarFunc)
    local
      list<DAE.Subscript> subs;
      list<list<DAE.Subscript>> rest_subs;

    case (_, _, _, subs :: rest_subs, _, _)
      equation
        subs = inSub :: subs;
      then expandArray(inElement, EXPAND_FUNCTION(), inDimensions, subs :: rest_subs, inAccumEl, inScalarFunc);

  end match;
end expandArrayExpDim;

protected function expandScalar
  input NFInstTypes.Component inComponent;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
algorithm
  outElements := match(inComponent, inSubscripts, inAccumEl)
    local
      Absyn.Path name;
      DAE.Type ty;
      DAE.ComponentRef cref;
      list<list<DAE.Subscript>> subs;
      DAE.Element elem;
      DAE.VarKind var_kind;
      DAE.VarDirection dir;
      DAE.VarVisibility vis;
      DAE.ConnectorType ct;
      NFInstTypes.Binding binding;
      Option<DAE.Exp> bind_exp;
      NFInstTypes.DaePrefixes prefs;

    case (NFInstTypes.TYPED_COMPONENT(prefixes =
        NFInstTypes.DAE_PREFIXES(variability = DAE.CONST())), _, _)
      then inAccumEl;

    case (NFInstTypes.TYPED_COMPONENT(name = name, ty = ty, prefixes = prefs,
        binding = binding), subs, _)
      equation
        subs = listReverse(subs);
        bind_exp = expandBinding(binding, subs);
        cref = subscriptPath(name, subs);
        (var_kind, dir, vis, ct) = getPrefixes(prefs);
        elem = DAE.VAR(cref, var_kind, dir, DAE.NON_PARALLEL(), vis, ty,
          bind_exp, {}, ct, DAE.emptyElementSource, NONE(), NONE(),
          Absyn.NOT_INNER_OUTER());
      then
        elem :: inAccumEl;

    case (NFInstTypes.UNTYPED_COMPONENT(name = name), _, _)
      equation
        print("Got untyped component " + Absyn.pathString(name) + "\n");
      then
        fail();

    case (NFInstTypes.CONDITIONAL_COMPONENT(name = name), _, _)
      equation
        print("Got conditional component " + Absyn.pathString(name) + "\n");
      then
        fail();

    case (NFInstTypes.OUTER_COMPONENT(), _, _)
      then inAccumEl;

  end match;
end expandScalar;

protected function expandBinding
  input NFInstTypes.Binding inBinding;
  input list<list<DAE.Subscript>> inSubscripts;
  output Option<DAE.Exp> outBinding;
algorithm
  outBinding := match(inBinding, inSubscripts)
    local
      DAE.Exp exp;
      Integer pd;
      list<DAE.Subscript> flat_subs;
      list<DAE.Exp> sub_exps;

    case (NFInstTypes.UNBOUND(), _) then NONE();

    case (NFInstTypes.TYPED_BINDING(bindingExp = exp, propagatedDims = -1), _)
      then SOME(exp);

    case (NFInstTypes.TYPED_BINDING(bindingExp = exp, propagatedDims = pd), _)
      equation
        flat_subs = List.flatten(inSubscripts);
        flat_subs = List.lastN(flat_subs, pd);
        sub_exps = List.map(flat_subs, Expression.getSubscriptExp);
        exp = DAE.ASUB(exp, sub_exps);
        (exp, _) = ExpressionSimplify.simplify(exp);
      then
        SOME(exp);

    else
      equation
        print("NFSCodeExpand.expandBinding got unknown binding\n");
      then
        fail();

  end match;
end expandBinding;

protected function subscriptPath
  input Absyn.Path inPath;
  input list<list<DAE.Subscript>> inSubscripts;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inPath, inSubscripts)
    case (_, {{}}) then ComponentReference.pathToCref(inPath);
    else subscriptPath2(inPath, inSubscripts);
  end match;
end subscriptPath;

protected function subscriptPath2
  input Absyn.Path inPath;
  input list<list<DAE.Subscript>> inSubscripts;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inPath, inSubscripts)
    local
      String name;
      Absyn.Path path;
      list<DAE.Subscript> subs;
      list<list<DAE.Subscript>> rest_subs;
      DAE.ComponentRef cref;

    case (Absyn.IDENT(name = name), {subs})
      then DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, subs);

    case (Absyn.QUALIFIED(name = name, path = path), subs :: rest_subs)
      equation
        cref = subscriptPath2(path, rest_subs);
      then
        DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, subs, cref);

    case (Absyn.FULLYQUALIFIED(path = path), _)
      then subscriptPath2(path, inSubscripts);

    case (_, {})
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"NFSCodeExpand.subscriptPath ran out of subscripts!\n"});
      then
        fail();

    case (Absyn.IDENT(), _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"NFSCodeExpand.subscriptPath got too many subscripts!\n"});
      then
        fail();

  end match;
end subscriptPath2;

protected function subscriptCref
  input DAE.ComponentRef inCref;
  input list<list<DAE.Subscript>> inSubscripts;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inSubscripts)
    case (_, {{}}) then inCref;
    else subscriptCref2(inCref, inSubscripts, inCref, inSubscripts);
  end match;
end subscriptCref;

protected function subscriptCref2
  input DAE.ComponentRef inCref;
  input list<list<DAE.Subscript>> inSubscripts;
  input DAE.ComponentRef inCrefFull;
  input list<list<DAE.Subscript>> inSubscriptsFull;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inSubscripts, inCrefFull, inSubscriptsFull)
    local
      String id, str;
      DAE.Type ty;
      DAE.ComponentRef cref;
      list<DAE.Subscript> subs;
      list<list<DAE.Subscript>> rest_subs;
      Integer ix;

    case (DAE.CREF_IDENT(id, ty, {}), {subs}, _, _)
      then DAE.CREF_IDENT(id, ty, subs);

    case (DAE.CREF_IDENT(id, ty, subs), {_}, _, _)
      then DAE.CREF_IDENT(id, ty, subs);

    case (DAE.CREF_ITER(id, ix, ty, {}), {subs}, _, _)
      then DAE.CREF_ITER(id, ix, ty, subs);

    case (DAE.CREF_ITER(id, ix, ty, subs), {_}, _, _)
      then DAE.CREF_ITER(id, ix, ty, subs);

    case (DAE.CREF_QUAL(id, ty, {}, cref), subs :: rest_subs, _, _)
      equation
        cref = subscriptCref2(cref, rest_subs, inCrefFull, inSubscriptsFull);
      then
        DAE.CREF_QUAL(id, ty, subs, cref);

    case (DAE.CREF_QUAL(id, ty, subs, cref), _ :: rest_subs, _, _)
      equation
        cref = subscriptCref2(cref, rest_subs, inCrefFull, inSubscriptsFull);
      then
        DAE.CREF_QUAL(id, ty, subs, cref);

    case (DAE.WILD(), _, _, _) then inCref;

    case (_, {}, _, _)
      equation
        str = "NFSCodeExpand.subscriptCref ran out of subscripts on cref: " +
          ComponentReference.printComponentRefStr(inCrefFull) + " reached: " +
          ComponentReference.printComponentRefStr(inCref) + "!\n";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        inCref;

    case (DAE.CREF_IDENT(), _, _, _)
      equation
        str = "NFSCodeExpand.subscriptCref got too many subscripts on cref: " +
          ComponentReference.printComponentRefStr(inCrefFull) + " reached: " +
          ComponentReference.printComponentRefStr(inCref) + "!\n";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        inCref;

  end match;
end subscriptCref2;

protected function unliftComponentType
  input NFInstTypes.Component inComponent;
  output NFInstTypes.Component outComponent;
protected
  Absyn.Path name;
  DAE.Type ty;
  NFInstTypes.DaePrefixes prefs;
  NFInstTypes.Binding binding;
  SourceInfo info;
  Option<NFInstTypes.Component> p;
algorithm
  NFInstTypes.TYPED_COMPONENT(name, DAE.T_ARRAY(ty = ty), p, prefs, binding, info) := inComponent;
  outComponent := NFInstTypes.TYPED_COMPONENT(name, ty, p, prefs, binding, info);
end unliftComponentType;

protected function getPrefixes
  input NFInstTypes.DaePrefixes inPrefixes;
  output DAE.VarKind outVarKind;
  output DAE.VarDirection outDirection;
  output DAE.VarVisibility outVisibility;
  output DAE.ConnectorType outConnectorType;
algorithm
  (outVarKind, outDirection, outVisibility, outConnectorType) :=
  match(inPrefixes)
    local
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarVisibility vis;
      DAE.ConnectorType ct;

    case NFInstTypes.DAE_PREFIXES(vis, kind, _, _, dir, ct)
      then (kind, dir, vis, ct);

    case NFInstTypes.NO_DAE_PREFIXES()
      then (DAE.VARIABLE(), DAE.BIDIR(), DAE.PUBLIC(), DAE.NON_CONNECTOR());

  end match;
end getPrefixes;

protected function expandEquation
  input Equation inEquation;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
algorithm
  outElements := matchcontinue(inEquation, inSubscripts, inAccumEl)
    local
      DAE.Exp rhs, lhs, exp, msg, level;
      DAE.ComponentRef cref1;
      DAE.Type ty1;
      list<DAE.Element> accum_el;
      list<DAE.Dimension> dims;
      Absyn.Path path;
      SourceInfo info;
      list<DAE.Exp> expLst;
      String name           "The name of the index/iterator variable.";
      Integer index;
      DAE.Type indexType    "The type of the index/iterator variable.";
      Option<DAE.Exp> range "The range expression to loop over.";
      list<Equation> body   "The body of the for loop.";
      list<tuple<DAE.Exp, list<Equation>>> branches;


    case (NFInstTypes.EQUALITY_EQUATION(lhs = lhs, rhs = rhs), _, _)
      equation
        ty1 = Expression.typeof(lhs);
        dims = Types.getDimensions(ty1);
        accum_el = expandArray((lhs, rhs), EXPAND_MODEL(), dims, {} :: inSubscripts, inAccumEl,
          expandEqEquation);
      then
        accum_el;

    case (NFInstTypes.CONNECT_EQUATION(), _, _)
      equation
        print("Skipping expansion of connect\n");
      then
        inAccumEl;

    case (NFInstTypes.FOR_EQUATION(_, _, _, _, body, _), _, _)
      equation
        accum_el = List.flatten(List.map2(body, expandEquation, inSubscripts, inAccumEl));
        accum_el = listAppend(accum_el, inAccumEl);
      then
        accum_el;

    case (NFInstTypes.IF_EQUATION(_, _), _, _)
      equation
         //accum_el = DAE.IF_EQUATION();
         print("Skipping if equation\n");
         accum_el = inAccumEl;
      then
        accum_el;

    case (NFInstTypes.WHEN_EQUATION(_, _), _, _)
      equation
         //accum_el = DAE.IF_EQUATION();
         print("Skipping when equation\n");
         accum_el = inAccumEl;
      then
        accum_el;

    case (NFInstTypes.ASSERT_EQUATION(condition = exp, message = msg, level = level), _, _)
      equation
        ty1 = Expression.typeof(exp);
        _ = Types.getDimensions(ty1);
        accum_el = DAE.ASSERT(exp, msg, level, DAE.emptyElementSource)::inAccumEl;
      then
        accum_el;

    case (NFInstTypes.TERMINATE_EQUATION(message = msg), _, _)
      equation
        ty1 = Expression.typeof(msg);
        _ = Types.getDimensions(ty1);
        accum_el = DAE.TERMINATE(msg, DAE.emptyElementSource)::inAccumEl;
      then
        accum_el;

    case (NFInstTypes.REINIT_EQUATION(cref = cref1, reinitExp = exp), _, _)
      equation
        ty1 = Expression.typeof(exp);
        _ = Types.getDimensions(ty1);
        accum_el = DAE.REINIT(cref1, exp, DAE.emptyElementSource)::inAccumEl;
      then
        accum_el;

    case (NFInstTypes.NORETCALL_EQUATION(exp = exp), _, _)
      equation
        ty1 = Expression.typeof(exp);
        _ = Types.getDimensions(ty1);
        accum_el = DAE.NORETCALL(exp, DAE.emptyElementSource)::inAccumEl;
      then
        accum_el;

    else
      equation
        print("NFSCodeExpand.expandEquation failed on equation:\n" +
            NFInstDump.equationStr(inEquation) + "\n");
      then
        inAccumEl;

  end matchcontinue;
end expandEquation;

protected function expandEqEquation
  input tuple<DAE.Exp, DAE.Exp> inTuple;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outAccumEl;
algorithm
  outAccumEl := match(inTuple, inSubscripts, inAccumEl)
    local
      DAE.Exp lhs, rhs;
      list<list<DAE.Subscript>> subs;
      list<DAE.Subscript> comp_subs;
      DAE.Element eq;
      list<DAE.Exp> sub_expl;

    case ((lhs, rhs), subs as comp_subs :: _, _)
      equation
        subs = listReverse(subs);
        sub_expl = List.map(comp_subs, Expression.getSubscriptExp);
        lhs = subscriptExp(lhs, sub_expl, subs);
        (lhs, _) = ExpressionSimplify.simplify(lhs);
        rhs = subscriptExp(rhs, sub_expl, subs);
        (rhs, _) = ExpressionSimplify.simplify(rhs);
        eq = DAE.EQUATION(lhs, rhs, DAE.emptyElementSource);
      then
        eq :: inAccumEl;

  end match;
end expandEqEquation;

protected function subscriptExp
  input DAE.Exp inExp;
  input list<DAE.Exp> inEqSubscripts;
  input list<list<DAE.Subscript>> inAllSubscripts;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp, inEqSubscripts, inAllSubscripts)
    local
      DAE.ComponentRef cref;
      DAE.Type ty;
      DAE.Exp e1, e2;
      DAE.Operator op;

    case (DAE.ICONST(_), _, _) then inExp;
    case (DAE.RCONST(_), _, _) then inExp;
    case (DAE.SCONST(_), _, _) then inExp;
    case (DAE.BCONST(_), _, _) then inExp;
    case (DAE.ENUM_LITERAL(), _, _) then inExp;

    case (DAE.CREF(cref, ty), _, _)
      equation
        cref = subscriptCref(cref, inAllSubscripts);
      then
        DAE.CREF(cref, ty);

    case (DAE.BINARY(e1, op, e2), _, _)
      equation
        e1 = subscriptExp(e1, inEqSubscripts, inAllSubscripts);
        e2 = subscriptExp(e2, inEqSubscripts, inAllSubscripts);
        op = Expression.unliftOperatorX(op, listLength(inEqSubscripts));
      then
        DAE.BINARY(e1, op, e2);

    case (DAE.ARRAY(), _, _)
      equation
        e1 = subscriptArrayElements(inExp, inAllSubscripts);
        e2 = DAE.ASUB(e1, inEqSubscripts);
      then
        e2;
    case (DAE.CAST(ty,e1), _, _)
      equation
        e1 = subscriptExp(e1, inEqSubscripts, inAllSubscripts);
        ty = Types.arrayElementType(ty);
        e1 = DAE.CAST(ty,e1);
      then
        e1;

    else inExp;
  end match;
end subscriptExp;

protected function subscriptArrayElements
  input DAE.Exp inArray;
  input list<list<DAE.Subscript>> inAllSubscripts;
  output DAE.Exp outArray;
algorithm
  outArray := match(inArray, inAllSubscripts)
    local
      DAE.Type ty;
      Boolean scalar;
      list<DAE.Exp> expl;

    case (DAE.ARRAY(ty as DAE.T_ARRAY(ty = DAE.T_ARRAY()), scalar, expl), _)
      equation
        expl = List.map1(expl, subscriptArrayElements, inAllSubscripts);
      then
        DAE.ARRAY(ty, scalar, expl);

    case (DAE.ARRAY(ty, scalar, expl), _)
      equation
        expl = List.map2(expl, subscriptExp, {}, inAllSubscripts);
      then
        DAE.ARRAY(ty, scalar, expl);

  end match;
end subscriptArrayElements;

protected function expandStatements
  input tuple<list<Statement>,ExpandKind,Boolean> inTpl;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outAccumEl;
protected
  ExpandKind kind;
  list<Statement> stmt;
  Boolean isInitial;
  list<DAE.Statement> dstmt;
  DAE.Algorithm alg;
  DAE.Element el;
algorithm
  (stmt,kind,isInitial) := inTpl;
  dstmt := listReverse(List.fold2(stmt, expandStatement, kind, inSubscripts, {}));
  alg := DAE.ALGORITHM_STMTS(dstmt);
  el := if isInitial then DAE.INITIALALGORITHM(alg,DAE.emptyElementSource) else DAE.ALGORITHM(alg,DAE.emptyElementSource);
  outAccumEl := if listEmpty(dstmt) then inAccumEl else el::inAccumEl;
end expandStatements;

protected function expandStatementsList
  input tuple<list<list<Statement>>,ExpandKind,Boolean> inTpl;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outAccumEl;
protected
  ExpandKind kind;
  list<list<Statement>> stmt;
  Boolean isInitial;
  list<DAE.Statement> dstmt;
  DAE.Algorithm alg;
  DAE.Element el;
  list<tuple<list<Statement>,ExpandKind,Boolean>> tpls;
algorithm
  (stmt,kind,isInitial) := inTpl;
  tpls := List.map2(stmt,Util.make3Tuple,kind,isInitial);
  outAccumEl := List.fold1(tpls, expandStatements, inSubscripts, inAccumEl);
end expandStatementsList;

protected function expandStatement
  input Statement inStmt;
  input ExpandKind inKind;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Statement> inAccumEl;
  output list<DAE.Statement> outElements;
algorithm
  outElements := matchcontinue(inStmt, inKind, inSubscripts, inAccumEl)
    local
      DAE.Exp rhs, lhs, exp;
      list<DAE.Exp> sub_expl;
      DAE.Type   ty;
      list<Statement> body;
      list<DAE.Subscript> comp_subs;
      list<list<DAE.Subscript>> subs;
      list<DAE.Statement> dbody,accum_el;
      list<DAE.Dimension> dims;
      list<tuple<DAE.Exp,list<Statement>>> branches;
      list<tuple<DAE.Exp,list<DAE.Statement>>> dbranches;
      String name;
      Integer index;

    case (NFInstTypes.ASSIGN_STMT(lhs = lhs, rhs = rhs), _, subs as comp_subs :: _, _)
      equation
        subs = listReverse(subs);
        sub_expl = List.map(comp_subs, Expression.getSubscriptExp);
        lhs = subscriptExp(lhs, sub_expl, subs);
        /* (lhs, _) = ExpressionSimplify.simplify(lhs); ??? */
        rhs = subscriptExp(rhs, sub_expl, subs);
        (rhs, _) = ExpressionSimplify.simplify(rhs);
      then
        DAE.STMT_ASSIGN(DAE.T_ANYTYPE_DEFAULT, lhs, rhs, DAE.emptyElementSource)::inAccumEl;

    case (NFInstTypes.FUNCTION_ARRAY_INIT(name = name, ty = ty as DAE.T_ARRAY(dims=dims)), _, _, _)
      equation
        accum_el = if not Expression.arrayContainWholeDimension(dims)
          then DAE.STMT_ARRAY_INIT(name,ty,DAE.emptyElementSource) :: inAccumEl
          else inAccumEl;
      then
        accum_el;

    case (NFInstTypes.NORETCALL_STMT(exp = exp), _, subs as comp_subs :: _, _)
      equation
        subs = listReverse(subs);
        sub_expl = List.map(comp_subs, Expression.getSubscriptExp);
        exp = subscriptExp(exp, sub_expl, subs);
        (exp, _) = ExpressionSimplify.simplify(exp);
      then DAE.STMT_NORETCALL(exp, DAE.emptyElementSource)::inAccumEl;

    case (NFInstTypes.IF_STMT(branches = branches), _, subs as comp_subs :: _, _)
      equation
        subs = listReverse(subs);
        sub_expl = List.map(comp_subs, Expression.getSubscriptExp);
        dbranches = List.map3(branches,expandBranch,inKind,subs,sub_expl);
        dbody = Algorithm.makeIfFromBranches(dbranches,DAE.emptyElementSource);
      then listAppend(dbody,inAccumEl);

    case (NFInstTypes.FOR_STMT(name=name,index=index,indexType=ty,range=SOME(exp),body=body), _, subs as comp_subs :: _, _)
      equation
        subs = listReverse(subs);
        sub_expl = List.map(comp_subs, Expression.getSubscriptExp);
        exp = subscriptExp(exp, sub_expl, subs);
        (exp, _) = ExpressionSimplify.simplify(exp);
        dbody = List.fold2(body,expandStatement,inKind,subs,{});
      then DAE.STMT_FOR(ty,false /*???*/,name,index,exp,dbody,DAE.emptyElementSource)::inAccumEl;

    else
      equation
        print("NFSCodeExpand.expandStatement failed\n");
      then
        fail();

  end matchcontinue;
end expandStatement;

protected function expandBranch
  input tuple<DAE.Exp,list<Statement>> branch;
  input ExpandKind inKind;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Exp> sub_expl;
  output tuple<DAE.Exp,list<DAE.Statement>> dbranch;
protected
  DAE.Exp exp;
  list<Statement> stmt;
  list<DAE.Statement> dstmt;
algorithm
  (exp,stmt) := branch;
  exp := subscriptExp(exp, sub_expl, inSubscripts);
  dstmt := List.fold2(stmt,expandStatement,inKind,inSubscripts,{});
  dbranch := (exp,dstmt);
end expandBranch;

protected function expandFunction
  input NFInstTypes.Function inFunction;
  output DAE.Function outFunction;
algorithm
  outFunction := match (inFunction)
    local
      Absyn.Path path;
      list<DAE.Element> el;
      list<NFInstTypes.Element> inputs,outputs,locals;
      list<NFInstTypes.Statement> al;
      DAE.Type recType;
      DAE.Element outRec;

    case NFInstTypes.FUNCTION(path=path,inputs=inputs,outputs=outputs,locals=locals,algorithms=al)
      equation
        el = {};
        el = List.fold2(inputs, expandElement, EXPAND_FUNCTION(), {}, el);
        el = List.fold2(outputs, expandElement, EXPAND_FUNCTION(), {}, el);
        el = List.fold2(locals, expandElement, EXPAND_FUNCTION(), {}, el);
        el = expandArray((al,EXPAND_FUNCTION(),false /* not initial */), EXPAND_FUNCTION(), {}, {}::{}, el, expandStatements);
        el = listReverse(el);
      then DAE.FUNCTION(path,{DAE.FUNCTION_DEF(el)},DAE.T_FUNCTION_DEFAULT,SCode.PUBLIC() /*TODO: Improve this...*/,false,false,DAE.NO_INLINE(),DAE.emptyElementSource,NONE());


    case NFInstTypes.RECORD_CONSTRUCTOR(path, recType , inputs, locals, _)
      equation
        el = List.fold2(inputs, expandElement, EXPAND_FUNCTION(), {}, {});
        el = List.fold2(locals, expandElement, EXPAND_FUNCTION(), {}, el);

        // Create the return variable for the record constructor which will have the type of the
        // record itself.
        outRec = DAE.VAR(DAE.CREF_IDENT("$res", DAE.T_UNKNOWN_DEFAULT, {}), DAE.VARIABLE(),
          DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.PUBLIC(), recType,
          NONE(), {}, DAE.NON_CONNECTOR(), DAE.emptyElementSource, NONE(), NONE(),
          Absyn.NOT_INNER_OUTER());
        el = outRec::el;
        el = listReverse(el);
      then DAE.FUNCTION(path,{DAE.FUNCTION_DEF(el)},DAE.T_FUNCTION_DEFAULT,SCode.PUBLIC() /*TODO: Improve this...*/,false,false,DAE.NO_INLINE(),DAE.emptyElementSource,NONE());

  end match;
end expandFunction;

protected function isExpandFunction
  input ExpandKind inKind;
  output Boolean b;
algorithm
  b := match inKind case EXPAND_FUNCTION() then true; else false; end match;
end isExpandFunction;

annotation(__OpenModelica_Interface="frontend");
end NFSCodeExpand;
