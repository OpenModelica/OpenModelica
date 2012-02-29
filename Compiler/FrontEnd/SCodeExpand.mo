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
public import SCodeInst;

protected import Absyn;
protected import DAEDump;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import List;
protected import SCode;
  
replaceable type ElementType subtypeof Any;

partial function ExpandScalarFunc
  input ElementType inElement;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
end ExpandScalarFunc;

public function expand
  input String inName;
  input SCodeInst.Class inClass;
  output DAE.DAElist outDAE;
protected
  list<DAE.Element> el;
  DAE.FunctionTree tree;
algorithm
  outDAE := matchcontinue(inName, inClass)
    local
      list<DAE.Element> el;
      DAE.DAElist dae;
      DAE.FunctionTree tree;
      Integer vars, params;
    
    case (_, _)
      equation
        el = expandClass(inClass, {}, {});
        dae = DAE.DAE({DAE.COMP(inName, el, DAE.emptyElementSource, NONE())});

        tree = DAE.AVLTREENODE(NONE(), 0, NONE(), NONE());
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
  input SCodeInst.Class inClass;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
algorithm
  outElements := match(inClass, inSubscripts, inAccumEl)
    local
      list<SCodeInst.Element> comps;
      list<DAE.Element> el;

    case (SCodeInst.BASIC_TYPE(), _, _) then inAccumEl;
    
    case (SCodeInst.COMPLEX_CLASS(components = comps), _, _)
      equation
        el = List.fold1(comps, expandElement, inSubscripts, inAccumEl);
      then
        el;

  end match;
end expandClass;

protected function expandElement
  input SCodeInst.Element inElement;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
algorithm
  outElements := match(inElement, inSubscripts, inAccumEl)
    local
      SCodeInst.Component comp;
      list<DAE.Element> el;
      SCodeInst.Class cls;
      Absyn.Path path;
      String err_msg;
      DAE.Type ty;
      DAE.Dimensions dims;

    case (SCodeInst.ELEMENT(component = comp, cls = SCodeInst.BASIC_TYPE()), _, _)
      equation
        el = expandComponent(comp, inSubscripts, inAccumEl);
      then
        el;

    case (SCodeInst.ELEMENT(component = SCodeInst.TYPED_COMPONENT(ty =
        DAE.T_ARRAY(ty = ty, dims = dims)), cls = cls), _, _)
      equation
        el = expandArray(cls, dims, {} :: inSubscripts, inAccumEl, expandClass);
      then
        el;

    case (SCodeInst.ELEMENT(component = comp, cls = cls), _, _)
      equation
        el = expandClass(cls, {} :: inSubscripts, inAccumEl);
      then
        el;

    case (SCodeInst.EXTENDED_ELEMENTS(cls = cls), _, _)
      equation
        el = expandClass(cls, inSubscripts, inAccumEl);
      then
        el;

    case (SCodeInst.CONDITIONAL_ELEMENT(component = comp), _, _)
      equation
        path = SCodeInst.getComponentName(comp);
        err_msg = "SCodeExpand.expandElement got unresolved conditional component " +& 
          Absyn.pathString(path) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
        inAccumEl;

  end match;
end expandElement;

protected function expandComponent
  input SCodeInst.Component inComponent;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  output list<DAE.Element> outElements;
algorithm
  outElements := match(inComponent, inSubscripts, inAccumEl)
    local
      Absyn.Path name;
      DAE.Dimensions dims;
      list<DAE.Element> el;
      SCodeInst.Component comp;
      String err_msg;

    case (SCodeInst.TYPED_COMPONENT(ty = DAE.T_ARRAY(dims = dims)), _, _)
      equation
        comp = unliftComponentType(inComponent);
        el = expandArray(comp, dims, {} :: inSubscripts, inAccumEl, expandScalar);
      then
        el;

    case (SCodeInst.TYPED_COMPONENT(ty = _), _, _)
      equation
        el = expandScalar(inComponent, {} :: inSubscripts, inAccumEl);
      then
        el;
        
    case (SCodeInst.UNTYPED_COMPONENT(name = name), _, _)
      equation
        err_msg = "SCodeExpand.expandComponent got untyped component " +&
          Absyn.pathString(name) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
        fail();

    case (SCodeInst.CONDITIONAL_COMPONENT(name = name), _, _)
      equation
        err_msg = "SCodeExpand.expandComponent got unresolved conditional component " +&
          Absyn.pathString(name) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
        inAccumEl;

    case (SCodeInst.OUTER_COMPONENT(name = _), _, _)
      then inAccumEl;

  end match;
end expandComponent;

protected function expandArray
  input ElementType inElement;
  input list<DAE.Dimension> inDimensions;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  input ExpandScalarFunc inScalarFunc;
  output list<DAE.Element> outElements;
algorithm
  outElements := 
  match(inElement, inDimensions, inSubscripts, inAccumEl, inScalarFunc)
    local
      Integer dim;
      list<DAE.Dimension> rest_dims;
      list<DAE.Element> el;
      list<DAE.Subscript> subs;
      list<list<DAE.Subscript>> rest_subs;

    case (_, {}, subs :: rest_subs, _, _)
      equation
        subs = listReverse(subs);
        el = inScalarFunc(inElement, subs :: rest_subs, inAccumEl);
      then
        el;
        
    case (_, DAE.DIM_INTEGER(integer = dim) :: rest_dims, _, _, _)
      equation
        el = expandArrayIntDim(inElement, dim, rest_dims, inSubscripts,
            inAccumEl, inScalarFunc);
      then
        el;

    case (_, DAE.DIM_ENUM(enumTypeName = _) :: _, _, _, _)
      equation
        print("SCodeExpand.expandArray TODO: implement support for enum dims.\n");
      then
        fail();

    else
      equation
        print("Unknown dimension in SCodeExpand.expandArray\n");
      then
        fail();

  end match;
end expandArray;

protected function expandArrayIntDim
  input ElementType inElement;
  input Integer inIndex;
  input list<DAE.Dimension> inDimensions;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Element> inAccumEl;
  input ExpandScalarFunc inScalarFunc;
  output list<DAE.Element> outElements;
algorithm
  outElements := 
  match(inElement, inIndex, inDimensions, inSubscripts, inAccumEl, inScalarFunc)
    local
      list<DAE.Subscript> subs;
      list<list<DAE.Subscript>> rest_subs;
      list<DAE.Element> el;
      String err_msg;

    case (_, 0, _, _, _, _)
      then inAccumEl;

    case (_, _, _, subs :: rest_subs, _, _)
      equation
        subs = DAE.INDEX(DAE.ICONST(inIndex)) :: subs;
        el = expandArray(inElement, inDimensions, subs :: rest_subs,
            inAccumEl, inScalarFunc);
      then
        expandArrayIntDim(inElement, inIndex - 1, inDimensions, inSubscripts,
            el, inScalarFunc);

    else
      equation
        true = (inIndex < 0);
        err_msg = "SCodeExpand.expandArrayIntDim got negative dimension " +&
          intString(inIndex) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
        fail();
          
  end match;
end expandArrayIntDim;      

protected function expandScalar
  input SCodeInst.Component inComponent;
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
      SCodeInst.Binding binding;
      Option<DAE.Exp> bind_exp;
      SCodeInst.Prefixes prefs;

    case (SCodeInst.TYPED_COMPONENT(prefixes = 
        SCodeInst.PREFIXES(variability = DAE.CONST())), _, _)
      then inAccumEl;

    case (SCodeInst.TYPED_COMPONENT(prefixes = 
        SCodeInst.PREFIXES(variability = DAE.PARAM())), _, _)
      then inAccumEl;
      
    case (SCodeInst.TYPED_COMPONENT(name, ty, prefs, binding, _), subs, _)
      equation
        bind_exp = expandBinding(binding, subs);
        subs = listReverse(subs);
        cref = subscriptPath(name, subs);
        (var_kind, dir, vis, fp, sp) = getPrefixes(prefs);
        elem = DAE.VAR(cref, var_kind, dir, DAE.NON_PARALLEL(), vis, ty,
          bind_exp, {}, fp, sp, DAE.emptyElementSource, NONE(), NONE(),
          Absyn.NOT_INNER_OUTER());
      then
        elem :: inAccumEl;

    case (SCodeInst.UNTYPED_COMPONENT(name = name), _, _)
      equation
        print("Got untyped component " +& Absyn.pathString(name) +& "\n");
      then
        fail();

    case (SCodeInst.CONDITIONAL_COMPONENT(name = name), _, _)
      equation
        print("Got conditional component " +& Absyn.pathString(name) +& "\n");
      then
        fail();

    case (SCodeInst.OUTER_COMPONENT(name = _), _, _)
      then inAccumEl;

  end match;
end expandScalar;

protected function expandBinding
  input SCodeInst.Binding inBinding;
  input list<list<DAE.Subscript>> inSubscripts;
  output Option<DAE.Exp> outBinding;
algorithm
  outBinding := match(inBinding, inSubscripts)
    local
      DAE.Exp exp;
      Integer pl;
      list<list<DAE.Subscript>> subs;
      list<DAE.Subscript> flat_subs;
      list<DAE.Exp> sub_exps;

    case (SCodeInst.UNBOUND(), _) then NONE();

    case (SCodeInst.TYPED_BINDING(bindingExp = exp, propagatedLevels = -1), _)
      then SOME(exp);

    case (SCodeInst.TYPED_BINDING(bindingExp = exp, propagatedLevels = pl), _)
      equation
        subs = List.firstN(inSubscripts, pl);
        flat_subs = List.flatten(subs);
        flat_subs = listReverse(flat_subs);
        sub_exps = List.map(flat_subs, Expression.subscriptExp);
        exp = subscriptBindingExp(exp, sub_exps);
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

protected function subscriptBindingExp
  input DAE.Exp inExp;
  input list<DAE.Exp> inSubscripts;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp, inSubscripts)
    local
      DAE.Exp exp, sub;
      list<DAE.Exp> rest_subs;

    case (_, {}) then inExp;

    case (exp, sub :: rest_subs)
      equation
        exp = DAE.ASUB(exp, {sub});
      then
        subscriptBindingExp(exp, rest_subs);

  end match;
end subscriptBindingExp;

protected function subscriptPath
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
        cref = subscriptPath(path, rest_subs);
      then
        DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, subs, cref);

    case (Absyn.FULLYQUALIFIED(path = path), _)
      then subscriptPath(path, inSubscripts);

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
end subscriptPath;

protected function unliftComponentType
  input SCodeInst.Component inComponent;
  output SCodeInst.Component outComponent;
protected
  Absyn.Path name;
  DAE.Type ty;
  SCodeInst.Prefixes prefs;
  SCodeInst.Binding binding;
  Absyn.Info info;
algorithm
  SCodeInst.TYPED_COMPONENT(name, DAE.T_ARRAY(ty = ty), prefs, binding, info) := inComponent;
  outComponent := SCodeInst.TYPED_COMPONENT(name, ty, prefs, binding, info);
end unliftComponentType;

protected function getPrefixes
  input SCodeInst.Prefixes inPrefixes;
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

    case SCodeInst.PREFIXES(vis, kind, _, _, (dir, _), (fp, _), (sp, _))
      then (kind, dir, vis, fp, sp);
    
    case SCodeInst.NO_PREFIXES()
      then (DAE.VARIABLE(), DAE.BIDIR(), DAE.PUBLIC(), DAE.NON_CONNECTOR(),
          DAE.NON_STREAM_CONNECTOR());

  end match;
end getPrefixes;

end SCodeExpand;
