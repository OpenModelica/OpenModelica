/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package SCodeExpand
" file:        SCodeExpand.mo
  package:     SCodeExpand
  description: Expands the output from SCodeInst into DAE form.

  RCS: $Id$

"

public import DAE;
public import HashTablePathToFunction;
public import InstTypes;

protected import Absyn;
protected import BaseHashTable;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import InstDump;
protected import InstUtil;
protected import List;
protected import SCode;
protected import Types;
protected import Util;
  
protected type Equation = InstTypes.Equation;
public type FunctionHashTable = HashTablePathToFunction.HashTable;
protected type Statement = InstTypes.Statement;

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
  input InstTypes.Class inClass;
  input FunctionHashTable inFunctions;
  output DAE.DAElist outDAE;
protected
  list<DAE.Element> el;
  DAE.FunctionTree tree;
algorithm
  outDAE := matchcontinue(inName, inClass, inFunctions)
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

        tree = DAEUtil.emptyFuncTree;
        tree = DAEUtil.addDaeFunction(funcs, tree);
        print("\nEXPANDED FORM:\n\n");
        print(DAEDump.dumpStr(dae, tree) +& "\n");
        (vars, params) = countElements(el, 0, 0);
        print("\nFound " +& intString(vars) +& " components and " +&
          intString(params) +& " parameters.\n");
      then
        dae;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("SCodeExpand.expand failed.\n");
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
  input InstTypes.Class inClass;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
algorithm
  outElements := match(inClass, inSubscripts, inAccumEl)
    local
      list<InstTypes.Element> comps;
      list<DAE.Element> el;
      list<Equation> eq;
      list<list<Statement>> al;

    case (InstTypes.BASIC_TYPE(), _, _) then inAccumEl;
    
    case (InstTypes.COMPLEX_CLASS(components = comps, equations = eq, algorithms = al), _, _)
      equation
        el = List.fold2(comps, expandElement, EXPAND_MODEL(), inSubscripts, inAccumEl);
        el = List.fold1(eq, expandEquation, inSubscripts, el);
        el = List.fold3(al, expandStatements, EXPAND_MODEL(), inSubscripts, false /* not initial */, el);
      then
        el;

  end match;
end expandClass;

protected function expandElement
  input InstTypes.Element inElement;
  input ExpandKind inKind;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
algorithm
  outElements := match(inElement, inKind, inSubscripts, inAccumEl)
    local
      InstTypes.Component comp;
      list<DAE.Element> el;
      InstTypes.Class cls;
      Absyn.Path path;
      String err_msg;
      DAE.Type ty;
      DAE.Dimensions dims;

    case (InstTypes.ELEMENT(component = comp, cls = InstTypes.BASIC_TYPE()), _, _, _)
      equation
        el = expandComponent(comp, inKind, inSubscripts, inAccumEl);
      then
        el;

    case (InstTypes.ELEMENT(component = InstTypes.TYPED_COMPONENT(ty =
        DAE.T_ARRAY(ty = ty, dims = dims)), cls = cls), _, _, _)
      equation
        el = expandArray(cls, inKind, dims, {} :: inSubscripts, inAccumEl, expandClass);
      then
        el;

    case (InstTypes.ELEMENT(component = comp, cls = cls), _, _, _)
      equation
        el = expandClass(cls, {} :: inSubscripts, inAccumEl);
      then
        el;

    case (InstTypes.EXTENDED_ELEMENTS(cls = cls), _, _, _)
      equation
        el = expandClass(cls, inSubscripts, inAccumEl);
      then
        el;

    case (InstTypes.CONDITIONAL_ELEMENT(component = comp), _, _, _)
      equation
        path = InstUtil.getComponentName(comp);
        err_msg = "SCodeExpand.expandElement got unresolved conditional component " +& 
          Absyn.pathString(path) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
        inAccumEl;

  end match;
end expandElement;

protected function expandComponent
  input InstTypes.Component inComponent;
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
      InstTypes.Component comp;
      String err_msg;
      Absyn.Info info;

    case (InstTypes.TYPED_COMPONENT(ty = DAE.T_ARRAY(dims = dims)), _, _, _)
      equation
        comp = unliftComponentType(inComponent);
        el = expandArray(comp, inKind, dims, {} :: inSubscripts, inAccumEl, expandScalar);
      then
        el;

    case (InstTypes.TYPED_COMPONENT(ty = _), _, _, _)
      equation
        el = expandScalar(inComponent, {} :: inSubscripts, inAccumEl);
      then
        el;
        
    case (InstTypes.UNTYPED_COMPONENT(name = name, info = info), _, _, _)
      equation
        err_msg = "SCodeExpand.expandComponent got untyped component " +&
          Absyn.pathString(name) +& " at position: " +& Error.infoStr(info) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
        fail();

    case (InstTypes.CONDITIONAL_COMPONENT(name = name, info = info), _, _, _)
      equation
        err_msg = "SCodeExpand.expandComponent got unresolved conditional component " +&
          Absyn.pathString(name) +& " at position: " +& Error.infoStr(info) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
        inAccumEl;

    case (InstTypes.OUTER_COMPONENT(name = _), _, _, _)
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
      DAE.Dimension first_dim;
      list<DAE.Dimension> rest_dims;
      list<AccumType> el;
      DAE.Subscript sub;
      list<DAE.Subscript> subs;
      list<list<DAE.Subscript>> rest_subs;
      String dim_str;
      DAE.Exp exp;

    case (_, _, {}, subs :: rest_subs, _, _)
      equation
        subs = listReverse(subs);
        el = inScalarFunc(inElement, subs :: rest_subs, inAccumEl);
      then
        el;
        
    case (_, _, DAE.DIM_INTEGER(integer = dim) :: rest_dims, _, _, _)
      equation
        start = Util.if_(isExpandFunction(inKind),dim,1);
        el = expandArrayIntDim(inElement, inKind, start, dim, rest_dims, inSubscripts,
            inAccumEl, inScalarFunc);
      then
        el;

    case (_, _, DAE.DIM_ENUM(enumTypeName = _) :: _, _, _, _)
      equation
        print("SCodeExpand.expandArray TODO: implement support for enum dims.\n");
      then
        fail();

    case (_, EXPAND_FUNCTION(), DAE.DIM_EXP(exp) :: rest_dims, subs :: rest_subs, _, _)
      then expandArrayExpDim(inElement, DAE.INDEX(exp), rest_dims, inSubscripts, inAccumEl, inScalarFunc);

    case (_, EXPAND_FUNCTION(), DAE.DIM_UNKNOWN() :: rest_dims, subs :: rest_subs, _, _)
      then expandArrayExpDim(inElement, DAE.WHOLEDIM(), rest_dims, inSubscripts, inAccumEl, inScalarFunc);

    else
      equation
        dim_str = ExpressionDump.dimensionString(List.first(inDimensions));
        print("Unknown dimension " +& dim_str +& " in SCodeExpand.expandArray\n");
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
      String err_msg;

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
      list<AccumType> el;
      String err_msg;

    case (_, _, _, subs :: rest_subs, _, _)
      equation
        subs = inSub :: subs;
      then expandArray(inElement, EXPAND_FUNCTION(), inDimensions, subs :: rest_subs, inAccumEl, inScalarFunc);

  end match;
end expandArrayExpDim;

protected function expandScalar
  input InstTypes.Component inComponent;
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
      SCode.Variability var;
      DAE.VarKind var_kind;
      DAE.VarDirection dir;
      DAE.VarVisibility vis;
      DAE.Flow fp;
      DAE.Stream sp;
      InstTypes.Binding binding;
      Option<DAE.Exp> bind_exp;
      InstTypes.DaePrefixes prefs;

    case (InstTypes.TYPED_COMPONENT(prefixes = 
        InstTypes.DAE_PREFIXES(variability = DAE.CONST())), _, _)
      then inAccumEl;

    case (InstTypes.TYPED_COMPONENT(name, ty, prefs, binding, _), subs, _)
      equation
        subs = listReverse(subs);
        bind_exp = expandBinding(binding, subs);
        cref = subscriptPath(name, subs);
        (var_kind, dir, vis, fp, sp) = getPrefixes(prefs);
        elem = DAE.VAR(cref, var_kind, dir, DAE.NON_PARALLEL(), vis, ty,
          bind_exp, {}, fp, sp, DAE.emptyElementSource, NONE(), NONE(),
          Absyn.NOT_INNER_OUTER());
      then
        elem :: inAccumEl;

    case (InstTypes.UNTYPED_COMPONENT(name = name), _, _)
      equation
        print("Got untyped component " +& Absyn.pathString(name) +& "\n");
      then
        fail();

    case (InstTypes.CONDITIONAL_COMPONENT(name = name), _, _)
      equation
        print("Got conditional component " +& Absyn.pathString(name) +& "\n");
      then
        fail();

    case (InstTypes.OUTER_COMPONENT(name = _), _, _)
      then inAccumEl;

  end match;
end expandScalar;

protected function expandBinding
  input InstTypes.Binding inBinding;
  input list<list<DAE.Subscript>> inSubscripts;
  output Option<DAE.Exp> outBinding;
algorithm
  outBinding := match(inBinding, inSubscripts)
    local
      DAE.Exp exp;
      Integer pd;
      list<list<DAE.Subscript>> subs;
      list<DAE.Subscript> flat_subs;
      list<DAE.Exp> sub_exps;

    case (InstTypes.UNBOUND(), _) then NONE();

    case (InstTypes.TYPED_BINDING(bindingExp = exp, propagatedDims = -1), _)
      then SOME(exp);

    case (InstTypes.TYPED_BINDING(bindingExp = exp, propagatedDims = pd), _)
      equation
        flat_subs = List.flatten(inSubscripts);
        flat_subs = List.lastN(flat_subs, pd);
        sub_exps = List.map(flat_subs, Expression.subscriptExp);
        exp = DAE.ASUB(exp, sub_exps);
        (exp, _) = ExpressionSimplify.simplify(exp);
      then 
        SOME(exp);

    else
      equation
        print("SCodeExpand.expandBinding got unknown binding\n");
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
          {"SCodeExpand.subscriptPath ran out of subscripts!\n"});
      then
        fail();

    case (Absyn.IDENT(name = _), _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"SCodeExpand.subscriptPath got too many subscripts!\n"});
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

    case (DAE.CREF_IDENT(id, ty, {}), {subs}, _, _)
      then DAE.CREF_IDENT(id, ty, subs);

    case (DAE.CREF_IDENT(id, ty, subs), {_}, _, _)
      then DAE.CREF_IDENT(id, ty, subs);

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
        str = "SCodeExpand.subscriptCref ran out of subscripts on cref: " +&  
          ComponentReference.printComponentRefStr(inCrefFull) +& " reached: " +&
          ComponentReference.printComponentRefStr(inCref) +& "!\n";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        inCref;

    case (DAE.CREF_IDENT(ident = _), _, _, _)
      equation
        str = "SCodeExpand.subscriptCref got too many subscripts on cref: " +&  
          ComponentReference.printComponentRefStr(inCrefFull) +& " reached: " +&
          ComponentReference.printComponentRefStr(inCref) +& "!\n";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        inCref;

  end match;
end subscriptCref2;

protected function unliftComponentType
  input InstTypes.Component inComponent;
  output InstTypes.Component outComponent;
protected
  Absyn.Path name;
  DAE.Type ty;
  InstTypes.DaePrefixes prefs;
  InstTypes.Binding binding;
  Absyn.Info info;
algorithm
  InstTypes.TYPED_COMPONENT(name, DAE.T_ARRAY(ty = ty), prefs, binding, info) := inComponent;
  outComponent := InstTypes.TYPED_COMPONENT(name, ty, prefs, binding, info);
end unliftComponentType;

protected function getPrefixes
  input InstTypes.DaePrefixes inPrefixes;
  output DAE.VarKind outVarKind;
  output DAE.VarDirection outDirection;
  output DAE.VarVisibility outVisibility;
  output DAE.Flow outFlow;
  output DAE.Stream outStream;
algorithm
  (outVarKind, outDirection, outVisibility, outFlow, outStream) :=
  match(inPrefixes)
    local
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarVisibility vis;
      DAE.Flow fp;
      DAE.Stream sp;

    case InstTypes.DAE_PREFIXES(vis, kind, _, _, dir, fp, sp)
      then (kind, dir, vis, fp, sp);
    
    case InstTypes.NO_DAE_PREFIXES()
      then (DAE.VARIABLE(), DAE.BIDIR(), DAE.PUBLIC(), DAE.NON_CONNECTOR(),
          DAE.NON_STREAM_CONNECTOR());

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
      DAE.Exp rhs, lhs, exp, msg;
      DAE.Element eq;
      DAE.ComponentRef cref1, cref2;
      DAE.Type ty1, ty2;
      list<list<DAE.Subscript>> subs;
      list<DAE.Element> accum_el;
      list<DAE.Dimension> dims;
      Absyn.Path path;
      Absyn.Info info;
      list<DAE.Exp> expLst;
      String index          "The name of the index/iterator variable.";
      DAE.Type indexType    "The type of the index/iterator variable.";
      Option<DAE.Exp> range "The range expression to loop over.";
      list<Equation> body   "The body of the for loop.";
      list<tuple<DAE.Exp, list<Equation>>> branches;
      

    case (InstTypes.EQUALITY_EQUATION(lhs = lhs, rhs = rhs), _, _)
      equation
        ty1 = Expression.typeof(lhs);
        dims = Types.getDimensions(ty1);
        accum_el = expandArray((lhs, rhs), EXPAND_MODEL(), dims, {} :: inSubscripts, inAccumEl,
          expandEqEquation);
      then
        accum_el;
        
    case (InstTypes.CONNECT_EQUATION(lhs = _), _, _)
      equation
        print("Skipping expansion of connect\n");
      then
        inAccumEl;
        
    case (InstTypes.FOR_EQUATION(index, indexType, range, body, info), _, _)
      equation
        accum_el = List.flatten(List.map2(body, expandEquation, inSubscripts, inAccumEl));
        accum_el = listAppend(accum_el, inAccumEl);
      then
        accum_el;
        
    case (InstTypes.IF_EQUATION(branches, info), _, _)
      equation
         //accum_el = DAE.IF_EQUATION();
         print("Skipping if equation\n");
         accum_el = inAccumEl;
      then
        accum_el;
        
    case (InstTypes.WHEN_EQUATION(branches, info), _, _)
      equation
         //accum_el = DAE.IF_EQUATION();
         print("Skipping when equation\n");
         accum_el = inAccumEl;
      then
        accum_el;
        
    case (InstTypes.ASSERT_EQUATION(condition = exp, message = msg, info = info), _, _)
      equation
        ty1 = Expression.typeof(exp);
        dims = Types.getDimensions(ty1);
        accum_el = DAE.ASSERT(exp, msg, DAE.emptyElementSource)::inAccumEl;
      then
        accum_el;
        
    case (InstTypes.TERMINATE_EQUATION(message = msg, info = info), _, _)
      equation
        ty1 = Expression.typeof(msg);
        dims = Types.getDimensions(ty1);
        accum_el = DAE.TERMINATE(msg, DAE.emptyElementSource)::inAccumEl;
      then
        accum_el;
        
    case (InstTypes.REINIT_EQUATION(cref = cref1, reinitExp = exp, info = info), _, _)
      equation
        ty1 = Expression.typeof(exp);
        dims = Types.getDimensions(ty1);
        accum_el = DAE.REINIT(cref1, exp, DAE.emptyElementSource)::inAccumEl;
      then
        accum_el;
        
    case (InstTypes.NORETCALL_EQUATION(exp = exp as DAE.CALL(path, expLst, _)), _, _)
      equation
        ty1 = Expression.typeof(exp);
        dims = Types.getDimensions(ty1);
        accum_el = DAE.NORETCALL(path, expLst, DAE.emptyElementSource)::inAccumEl;
      then
        accum_el;
        
    else
      equation
        print("SCodeExpand.expandEquation failed on equation:\n" +&
            InstDump.equationStr(inEquation) +& "\n");
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
        sub_expl = List.map(comp_subs, Expression.subscriptExp);
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
      Boolean scalar;
      list<DAE.Exp> expl;

    case (DAE.ICONST(_), _, _) then inExp;
    case (DAE.RCONST(_), _, _) then inExp;
    case (DAE.SCONST(_), _, _) then inExp;
    case (DAE.BCONST(_), _, _) then inExp;
    case (DAE.ENUM_LITERAL(name = _), _, _) then inExp;

    case (DAE.CREF(cref, ty), _, _)
      equation
        cref = subscriptCref(cref, inAllSubscripts);
      then
        DAE.CREF(cref, ty);

    case (DAE.BINARY(e1, op, e2), _, _)
      equation
        e1 = subscriptExp(e1, inEqSubscripts, inAllSubscripts);
        e2 = subscriptExp(e2, inEqSubscripts, inAllSubscripts);
      then
        DAE.BINARY(e1, op, e2);

    case (DAE.ARRAY(ty = _), _, _)
      equation
        e1 = subscriptArrayElements(inExp, inAllSubscripts);
        e2 = DAE.ASUB(e1, inEqSubscripts);
      then
        e2;

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

    case (DAE.ARRAY(ty as DAE.T_ARRAY(ty = DAE.T_ARRAY(ty = _)), scalar, expl), _)
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
  input list<Statement> inStmts;
  input ExpandKind inKind;
  input list<list<DAE.Subscript>> inSubscripts;
  input Boolean isInitial;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
protected
  list<DAE.Statement> dstmt;
  DAE.Algorithm alg;
  DAE.Element el;
algorithm
  dstmt := listReverse(List.fold2(inStmts, expandStatement, inKind, inSubscripts, {}));
  alg := DAE.ALGORITHM_STMTS(dstmt);
  el := Util.if_(isInitial,DAE.INITIALALGORITHM(alg,DAE.emptyElementSource),DAE.ALGORITHM(alg,DAE.emptyElementSource));
  outElements := Util.if_(List.isEmpty(dstmt),inAccumEl,el::inAccumEl);
end expandStatements;

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
      DAE.Statement eq;
      DAE.ComponentRef cref1, cref2;
      DAE.Type ty1, ty2, ty;
      list<list<DAE.Subscript>> subs;
      list<DAE.Statement> accum_el;
      list<DAE.Dimension> dims;
      list<tuple<DAE.Exp,list<Statement>>> branches;
      String name;

    case (InstTypes.ASSIGN_STMT(lhs = lhs, rhs = rhs), _, _, _)
      equation
        /* ty1 = Expression.typeof(lhs);
        dims = Types.getDimensions(ty1); */
        accum_el = expandArray((lhs, rhs), inKind, {}, {} :: inSubscripts, inAccumEl,
          expandAssignment);
      then
        accum_el;

    case (InstTypes.FUNCTION_ARRAY_INIT(name = name, ty = ty as DAE.T_ARRAY(dims=dims)), _, _, _)
      equation
        accum_el = Util.if_(not Expression.arrayContainWholeDimension(dims),
          DAE.STMT_ARRAY_INIT(name,ty,DAE.emptyElementSource) :: inAccumEl,
          inAccumEl);
      then
        accum_el;
        
    case (InstTypes.NORETCALL_STMT(exp = exp), _, _, _)
      equation
        ty = Expression.typeof(exp);
        dims = Types.getDimensions(ty);
        accum_el = expandArray(exp, inKind, dims, {} :: inSubscripts, inAccumEl, expandNoretcall);
      then accum_el;

    case (InstTypes.IF_STMT(branches = branches), _, _, _)
      equation
        accum_el = expandArray(branches, inKind, {}, {} :: inSubscripts, inAccumEl, expandIfStmt);
      then accum_el;

    else
      equation
        print("SCodeExpand.expandStatement failed\n");
      then
        fail();

  end matchcontinue;
end expandStatement;

protected function expandAssignment
  input tuple<DAE.Exp, DAE.Exp> inTuple;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Statement> inAccumEl;
  output list<DAE.Statement> outAccumEl;
algorithm
  outAccumEl := match(inTuple, inSubscripts, inAccumEl)
    local
      DAE.Exp lhs, rhs;
      list<list<DAE.Subscript>> subs;
      list<DAE.Subscript> comp_subs;
      DAE.Statement eq;
      list<DAE.Exp> sub_expl;

    case ((lhs, rhs), subs as comp_subs :: _, _)
      equation
        subs = listReverse(subs);
        sub_expl = List.map(comp_subs, Expression.subscriptExp);
        lhs = subscriptExp(lhs, sub_expl, subs);
        /* (lhs, _) = ExpressionSimplify.simplify(lhs); ??? */
        rhs = subscriptExp(rhs, sub_expl, subs);
        (rhs, _) = ExpressionSimplify.simplify(rhs);
        eq = DAE.STMT_ASSIGN(DAE.T_ANYTYPE_DEFAULT, lhs, rhs, DAE.emptyElementSource);
      then
        eq :: inAccumEl;
        
  end match;
end expandAssignment;

protected function expandNoretcall
  input DAE.Exp inExp;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Statement> inAccumEl;
  output list<DAE.Statement> outAccumEl;
algorithm
  outAccumEl := match(inExp, inSubscripts, inAccumEl)
    local
      list<list<DAE.Subscript>> subs;
      list<DAE.Subscript> comp_subs;
      DAE.Statement eq;
      list<DAE.Exp> sub_expl;
      DAE.Exp exp;

    case (exp, subs as comp_subs :: _, _)
      equation
        subs = listReverse(subs);
        sub_expl = List.map(comp_subs, Expression.subscriptExp);
        exp = subscriptExp(exp, sub_expl, subs);
        (exp, _) = ExpressionSimplify.simplify(exp);
        eq = DAE.STMT_NORETCALL(exp, DAE.emptyElementSource);
      then
        eq :: inAccumEl;
        
  end match;
end expandNoretcall;

protected function expandIfStmt
  input list<tuple<DAE.Exp,list<Statement>>> branches;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Statement> inAccumEl;
  output list<DAE.Statement> outAccumEl;
algorithm
  outAccumEl := match(branches, inSubscripts, inAccumEl)
    local
      list<list<DAE.Subscript>> subs;
      list<DAE.Subscript> comp_subs;
      DAE.Statement eq;
      list<DAE.Exp> sub_expl;

    case (branches, subs as comp_subs :: _, _)
      equation
        print("TODO: Expand if-stmt\n");
      then
        inAccumEl;
        
  end match;
end expandIfStmt;

protected function expandFunction
  input InstTypes.Function inFunction;
  output DAE.Function outFunction;
algorithm
  outFunction := match (inFunction)
    local
      Absyn.Path path;
      list<DAE.Element> el;
      list<InstTypes.Element> inputs,outputs,locals;
      list<InstTypes.Statement> al;
    case InstTypes.FUNCTION(path=path,inputs=inputs,outputs=outputs,locals=locals,algorithms=al)
      equation
        el = {};
        el = List.fold2(inputs, expandElement, EXPAND_FUNCTION(), {}, el);
        el = List.fold2(outputs, expandElement, EXPAND_FUNCTION(), {}, el);
        el = List.fold2(locals, expandElement, EXPAND_FUNCTION(), {}, el);
        el = expandStatements(al, EXPAND_FUNCTION(), {}, false /* not initial */, el);
        el = listReverse(el);
      then DAE.FUNCTION(path,{DAE.FUNCTION_DEF(el)},DAE.T_FUNCTION_DEFAULT,false,DAE.NO_INLINE(),DAE.emptyElementSource,NONE());
  end match;
end expandFunction;

protected function isExpandFunction
  input ExpandKind inKind;
  output Boolean b;
algorithm
  b := match inKind case EXPAND_FUNCTION() then true; else false; end match;
end isExpandFunction;

end SCodeExpand;
