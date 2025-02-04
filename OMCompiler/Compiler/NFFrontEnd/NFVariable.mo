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

encapsulated uniontype NFVariable
  import Attributes = NFAttributes;
  import Binding = NFBinding;
  import Class = NFClass;
  import Component = NFComponent;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Equation = NFEquation;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import NFPrefixes.Visibility;
  import NFPrefixes.Variability;
  import NFPrefixes.ConnectorType;
  import NFPrefixes.Direction;
  import NFPrefixes.AccessLevel;
  import Type = NFType;
  import NFBackendExtension.{BackendInfo, VariableKind, VariableAttributes};

protected
  import Ceval = NFCeval;
  import ExpandExp = NFExpandExp;
  import FlatModelicaUtil = NFFlatModelicaUtil;
  import Inst = NFInst;
  import IOStream;
  import MetaModelica.Dangerous.listReverseInPlace;
  import StringUtil;
  import Typing = NFTyping;
  import Util;
  import Variable = NFVariable;

public
  record VARIABLE
    ComponentRef name;
    Type ty;
    Binding binding;
    Visibility visibility;
    Attributes attributes;
    list<tuple<String, Binding>> typeAttributes;
    list<Variable> children;
    Option<SCode.Comment> comment;
    SourceInfo info;
    BackendInfo backendinfo "NFBackendExtension.DUMMY_BACKEND_INFO for all of frontend. Only used in Backend.";
  end VARIABLE;

  function fromCref
    "creates a variable from a component reference.
    Note: does not flatten, do not use for instantiated elements!"
    input ComponentRef cref;
    output Variable variable;
  protected
    list<ComponentRef> crefs;
    InstNode node, class_node;
    Component comp;
    Type ty;
    Binding binding;
    Visibility vis;
    Attributes attr;
    Option<SCode.Comment> cmt;
    SourceInfo info;
    BackendInfo binfo = NFBackendExtension.DUMMY_BACKEND_INFO;
    array<InstNode> child_nodes;
    list<Variable> children = {};
  algorithm
    node := ComponentRef.node(cref);
    comp := InstNode.component(node);
    ty := ComponentRef.getSubscriptedType(cref);
    vis := InstNode.visibility(node);
    attr := Component.getAttributes(comp);
    cmt := Component.comment(comp);
    info := InstNode.info(node);

    // kabdelhak: add dummy backend info, will be changed to actual value in
    // conversion to backend process (except for iterators). NBackendDAE.lower
    if ComponentRef.isIterator(cref) then
      binding := NFBinding.EMPTY_BINDING;
      binfo.varKind := VariableKind.ITERATOR();
    else
      binding := Component.getImplicitBinding(comp, InstNode.instanceParent(node));
    end if;

    // get the record children if the variable is a record
    if not Type.isExternalObject(ty) then
      children := match Type.arrayElementType(ty)
        case Type.COMPLEX(cls = class_node) algorithm
          child_nodes := Class.getComponents(InstNode.getClass(class_node));
          children := list(fromCref(ComponentRef.prefixCref(c, InstNode.getType(c), {}, cref)) for c in child_nodes);
        then children;
        else {};
      end match;
    end if;

    variable := VARIABLE(cref, ty, binding, vis, attr, {}, children, cmt, info, binfo);
  end fromCref;

  function size
    input Variable var;
    input Boolean resize = false;
    output Integer s = Type.sizeOf(var.ty, resize);
  end size;

  function hash
    input Variable var;
    output Integer i = ComponentRef.hash(var.name);
  end hash;

  function equalName
    input Variable var1;
    input Variable var2;
    output Boolean b = ComponentRef.isEqual(var1.name, var2.name);
  end equalName;

  function expand
    "Expands an array variable into its scalar elements."
    input Variable var;
    input Boolean backend = false;
    output list<Variable> vars;
  protected
    list<ComponentRef> crefs;
    Variable v;
    Binding binding;
    Variability bind_var;
    Binding.Source bind_src;
    Expression bind_exp, exp;
    list<Expression> expl;
    Integer crefs_len, expl_len;
  algorithm
    if Type.isArray(var.ty) then
      // Expand the name.
      exp := Expression.fromCref(var.name);
      exp := ExpandExp.expandCref(exp, backend);
      expl := Expression.arrayScalarElements(exp);
      crefs := list(Expression.toCref(e) for e in expl);

      v := var;
      v.ty := Type.arrayElementType(v.ty);
      vars := {};
      binding := var.binding;

      // If the variable has a binding we need to expand it too.
      if Binding.isBound(binding) then
        bind_exp := Binding.getTypedExp(binding);
        expl := Expression.arrayScalarElements(ExpandExp.expand(bind_exp));

        crefs_len := listLength(crefs);
        expl_len := listLength(expl);

        // If the binding has fewer dimensions than the variable, 'multiply' the
        // list of binding expression until they match.
        if expl_len < crefs_len then
          if intMod(crefs_len, expl_len) <> 0 then
            Error.assertion(false, getInstanceName() + " failed to expand " +
              ComponentRef.toString(var.name), sourceInfo());
          end if;

          expl := List.flatten(List.fill(expl, intDiv(crefs_len, expl_len)));
        end if;

        bind_var := Binding.variability(binding);
        bind_src := Binding.source(binding);

        for cr in crefs loop
          v.name := cr;
          exp :: expl := expl;
          v.binding := Binding.makeFlat(exp, bind_var, bind_src);
          vars := v :: vars;
        end for;
      else
        for cr in crefs loop
          v.name := cr;
          vars := v :: vars;
        end for;
      end if;
      vars := listReverseInPlace(vars);
    else
      vars := {var};
    end if;
  end expand;

  function expandChildren
    "Expands a variable into itself and its children if its complex."
    input Variable var;
    input list<Dimension> arrayDims = {};
    input Boolean addDimensions = true;
    output list<Variable> children;
  protected
    list<Dimension> newArrayDims;
  algorithm
    // add dimensions of surrounding record
    if addDimensions and not listEmpty(arrayDims) then
      var.ty := Type.liftArrayLeftList(var.ty, arrayDims);
    end if;
    newArrayDims := Type.arrayDims(var.ty);

    // return all children and the variable itself
    children := var :: List.flatten(list(expandChildren(v, newArrayDims, addDimensions) for v in var.children));
  end expandChildren;

  function typeOf
    input Variable var;
    output Type ty = var.ty;
  end typeOf;

  function attributes
    input Variable variable;
    output Attributes attributes = variable.attributes;
  end attributes;

  function variability
    input Variable variable;
    output Variability variability = variable.attributes.variability;
  end variability;

  function visibility
    input Variable variable;
    output Visibility visibility = variable.visibility;
  end visibility;

  function isComplex
    input Variable var;
    output Boolean b = Type.isComplex(var.ty);
  end isComplex;

  function isComplexArray
    input Variable var;
    output Boolean b = Type.isComplexArray(var.ty);
  end isComplexArray;

  function isStructural
    input Variable variable;
    output Boolean structural =
      variable.attributes.variability <= Variability.STRUCTURAL_PARAMETER;
  end isStructural;

  function isEmptyArray
    input Variable variable;
    output Boolean isEmpty = Type.isEmptyArray(variable.ty);
  end isEmptyArray;

  function isDeleted
    input Variable variable;
    output Boolean deleted;
  protected
    InstNode node;
  algorithm
    node := ComponentRef.node(variable.name);
    deleted := InstNode.isComponent(node) and Component.isDeleted(InstNode.component(node));
  end isDeleted;

  function isPresent
    input Variable variable;
    output Boolean present = not ConnectorType.isPotentiallyPresent(variable.attributes.connectorType);
  end isPresent;

  function isPotential
    input Variable variable;
    output Boolean potential = ConnectorType.isPotential(variable.attributes.connectorType);
  end isPotential;

  function isFlow
    input Variable variable;
    output Boolean potential = ConnectorType.isFlow(variable.attributes.connectorType);
  end isFlow;

  function isStream
    input Variable variable;
    output Boolean potential = ConnectorType.isStream(variable.attributes.connectorType);
  end isStream;

  function isInput
    input Variable variable;
    output Boolean b = variable.attributes.direction == Direction.INPUT;
  end isInput;

  function isTopLevelInput
    input Variable variable;
    output Boolean topInput = ComponentRef.isTopLevel(variable.name) and
                              variable.attributes.direction == Direction.INPUT;
  end isTopLevelInput;

  function isPublic
    input Variable variable;
    output Boolean isPublic = variable.visibility == Visibility.PUBLIC;
  end isPublic;

  function isProtected
    input Variable variable;
    output Boolean isProtected = variable.visibility == Visibility.PROTECTED;
  end isProtected;

  function isEncrypted
    input Variable variable;
    output Boolean isEncrypted;
  protected
    ComponentRef name;
    SourceInfo info;
  algorithm
    name := variable.name;

    while ComponentRef.isCref(name) loop
      info := InstNode.info(ComponentRef.node(name));

      if StringUtil.endsWith(info.fileName, ".moc") then
        isEncrypted := true;
        return;
      end if;

      name := ComponentRef.rest(name);
    end while;

    isEncrypted := false;
  end isEncrypted;

  function isAccessible
    input Variable variable;
    output Boolean isAccessible;
  protected
    Option<AccessLevel> oaccess;
    AccessLevel access;
  algorithm
    oaccess := InstNode.getAccessLevel(ComponentRef.node(variable.name));

    if isSome(oaccess) then
      SOME(access) := oaccess;
    else
      access := if isEncrypted(variable) then AccessLevel.DOCUMENTATION else AccessLevel.PACKAGE_DUPLICATE;
    end if;

    if access < AccessLevel.ICON then
      isAccessible := false;
    elseif access < AccessLevel.NON_PACKAGE_TEXT then
      isAccessible := not isProtected(variable);
    else
      isAccessible := true;
    end if;
  end isAccessible;

  function lookupTypeAttribute
    input String name;
    input Variable var;
    output Binding binding;
  algorithm
    for attr in var.typeAttributes loop
      if Util.tuple21(attr) == name then
        binding := Util.tuple22(attr);
        return;
      end if;
    end for;

    binding := NFBinding.EMPTY_BINDING;
  end lookupTypeAttribute;

  function applyToType
    input output Variable var;
    input typeFunc func;
    partial function typeFunc
      input output Type ty;
    end typeFunc;
  algorithm
    var.ty := func(var.ty);
    var.name := ComponentRef.applyToType(var.name, func);
  end applyToType;

  function propagateAnnotation
    input String name;
    input Boolean overwrite;
    input Boolean evaluate = false;
    input output Variable var;
  protected
    InstNode node;
    SCode.Mod mod;
    Absyn.Exp aexp;
    Expression exp;
  protected
    SCode.Annotation anno;
    InstNode scope;
  algorithm
    if ComponentRef.isCref(var.name) then
      node := ComponentRef.node(var.name);
      // InstNode.getAnnotation is recursive and returns the first annotation found.
      // if the original is supposed to be overwritten, skip the node itself and look at the parent
      if overwrite and InstNode.isComponent(node) then
        node := InstNode.parent(node);
      end if;

      (mod, scope) := InstNode.getAnnotation(name, node);

      if not SCodeUtil.isEmptyMod(mod) then
        if evaluate then
          () := matchcontinue mod
            case SCode.Mod.MOD(binding = SOME(aexp))
              algorithm
                exp := Inst.instExp(aexp, scope, NFInstContext.ANNOTATION, mod.info);
                exp := Typing.typeExp(exp, NFInstContext.ANNOTATION, mod.info);
                exp := Ceval.evalExp(exp);
                mod.binding := SOME(Expression.toAbsyn(exp));
              then
                ();

            else ();
          end matchcontinue;
        end if;

        anno := SCode.ANNOTATION(modification = SCode.MOD(
          finalPrefix = SCode.NOT_FINAL(),
          eachPrefix  = SCode.NOT_EACH(),
          subModLst   = {SCode.SubMod.NAMEMOD(name, mod)},
          binding     = NONE(),
          comment     = NONE(),
          info        = sourceInfo()));
        var.comment := SCodeUtil.appendAnnotationToCommentOption(anno, var.comment, true);
      end if;
    end if;
  end propagateAnnotation;

  function removeNonTopLevelDirection
    "Removes input/output prefixes from a variable that's not a top-level
     component, a component in a top-level connector, or a component in a
     top-level input component."
    input output Variable var;
  protected
    ComponentRef rest_name;
    InstNode node;
    Attributes attr;
  algorithm
    if var.attributes.direction == Direction.NONE then
      return;
    end if;

    rest_name := ComponentRef.rest(var.name);
    while not ComponentRef.isEmpty(rest_name) loop
      node := ComponentRef.node(rest_name);

      if not (InstNode.isConnector(node) or InstNode.isInput(node)) then
        attr := var.attributes;
        attr.direction := Direction.NONE;
        var.attributes := attr;
        return;
      end if;

      rest_name := ComponentRef.rest(rest_name);
    end while;
  end removeNonTopLevelDirection;

  partial function MapFn
    input output Expression exp;
  end MapFn;

  function mapExp
    input output Variable var;
    input MapFn fn;
  algorithm
    var.binding := Binding.mapExp(var.binding, fn);
    var.typeAttributes := list(
      (Util.tuple21(a), Binding.mapExp(Util.tuple22(a), fn)) for a in var.typeAttributes);
    var.children := list(mapExp(v, fn) for v in var.children);
    var.backendinfo := BackendInfo.map(var.backendinfo, fn);
    var.ty := Type.applyToDims(var.ty, func = function Dimension.mapExp(func = fn));
    var.name := ComponentRef.mapTypes(var.name, function Type.applyToDims(func = function Dimension.mapExp(func = fn)));
  end mapExp;

  function mapExpShallow
    input output Variable var;
    input MapFn fn;
  algorithm
    var.binding := Binding.mapExpShallow(var.binding, fn);
    var.typeAttributes := list(
      (Util.tuple21(a), Binding.mapExpShallow(Util.tuple22(a), fn)) for a in var.typeAttributes);
    var.children := list(mapExpShallow(v, fn) for v in var.children);
  end mapExpShallow;

  function toString
    input Variable var;
    input String indent = "";
    input Boolean printBindingType = false;
    output String str;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
    s := toStream(var, indent, printBindingType, s);
    str := IOStream.string(s);
    IOStream.delete(s);
  end toString;

  function toStream
    input Variable var;
    input String indent = "";
    input Boolean printBindingType = false;
    input output IOStream.IOStream s;
  protected
    Boolean first;
    Binding b;
  algorithm
    s := IOStream.append(s, indent);

    if var.visibility == Visibility.PROTECTED then
      s := IOStream.append(s, "protected ");
    end if;

    s := IOStream.append(s, Attributes.toString(var.attributes, var.ty));
    s := IOStream.append(s, Type.toString(var.ty));
    s := IOStream.append(s, " ");
    s := IOStream.append(s, ComponentRef.toString(var.name));

    if not listEmpty(var.typeAttributes) then
      s := IOStream.append(s, "(");

      first := true;
      for a in var.typeAttributes loop
        if first then
          first := false;
        else
          s := IOStream.append(s, ", ");
        end if;

        b := Util.tuple22(a);

        if Binding.isEach(b) then
          s := IOStream.append(s, "each ");
        end if;

        s := IOStream.append(s, Util.tuple21(a));
        s := IOStream.append(s, " = ");
        s := IOStream.append(s, Binding.toString(b));
      end for;

      s := IOStream.append(s, ")");
    end if;

    if Binding.isBound(var.binding) then
      s := IOStream.append(s, " = ");

      if printBindingType then
        s := IOStream.append(s, "(");
        s := IOStream.append(s, Type.toString(Binding.getType(var.binding)));
        s := IOStream.append(s, ") ");
      end if;

      s := IOStream.append(s, Binding.toString(var.binding));
    end if;
  end toStream;

  function toFlatStream
    input Variable var;
    input BaseModelica.OutputFormat format;
    input String indent = "";
    input Boolean printBindingType = false;
    input output IOStream.IOStream s;
  protected
    Boolean first;
    Binding b;
    Integer var_dims, binding_dims;
  algorithm
    s := IOStream.append(s, indent);

    s := Attributes.toFlatStream(var.attributes, var.ty, s, ComponentRef.isSimple(var.name));
    s := IOStream.append(s, Type.toFlatString(var.ty, format));
    s := IOStream.append(s, " ");
    s := IOStream.append(s, ComponentRef.toFlatString(var.name, format));

    if not listEmpty(var.typeAttributes) then
      s := Component.typeAttrsToFlatStream(var.typeAttributes, var.ty, format, s);
    elseif not listEmpty(var.children) then
      s := toFlatStreamModifier(var.children, format.moveBindings or Binding.isBound(var.binding), printBindingType, format, s);
    end if;

    s := toFlatStreamBinding(var.binding, printBindingType, format, s);
    s := FlatModelicaUtil.appendComment(var.comment, NFFlatModelicaUtil.ElementType.COMPONENT, s);
  end toFlatStream;

  function toFlatStreamBinding
    input Binding binding;
    input Boolean printBindingType;
    input BaseModelica.OutputFormat format;
    input output IOStream.IOStream s;
  algorithm
    if Binding.isBound(binding) then
      s := IOStream.append(s, " = ");

      if printBindingType then
        s := IOStream.append(s, "(");
        s := IOStream.append(s, Type.toFlatString(Binding.getType(binding), format));
        s := IOStream.append(s, ") ");
      end if;

      s := IOStream.append(s, Binding.toFlatString(binding, format));
    end if;
  end toFlatStreamBinding;

  function toFlatStreamModifier
    input list<Variable> children;
    input Boolean overwrittenBinding;
    input Boolean printBindingType;
    input BaseModelica.OutputFormat format;
    input output IOStream.IOStream s;
  protected
    Boolean empty = true;
    Boolean overwritten_binding;
    IOStream.IOStream ss;
    Binding.Source src;
  algorithm
    for child in children loop
      ss := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());

      if not listEmpty(child.typeAttributes) then
        ss := Component.typeAttrsToFlatStream(child.typeAttributes, child.ty, format, ss);
      elseif not listEmpty(child.children) then
        overwritten_binding := overwrittenBinding or Binding.isBound(child.binding);
        ss := toFlatStreamModifier(child.children, overwritten_binding, printBindingType, format, ss);
      end if;

      if not overwrittenBinding then
        src := Binding.source(child.binding);
        if src == NFBinding.Source.MODIFIER or src == NFBinding.Source.GENERATED then
          ss := toFlatStreamBinding(child.binding, printBindingType, format, ss);
        end if;
      end if;

      if not IOStream.empty(ss) then
        if empty then
          s := IOStream.append(s, "(");
          empty := false;
        else
          s := IOStream.append(s, ", ");
        end if;

        s := IOStream.append(s, Util.makeQuotedIdentifier(ComponentRef.firstName(child.name)));
        s := IOStream.appendListStream(ss, s);
      end if;
    end for;

    if not empty then
      s := IOStream.append(s, ")");
    end if;
  end toFlatStreamModifier;

  function moveBinding
    "Removes the binding of the variable, if it has one and it has at least
     discrete variability, and creates an equation from it."
    input output Variable var;
    input output list<Equation> equations;
  algorithm
    if variability(var) >= Variability.DISCRETE and Binding.isBound(var.binding) then
      equations := Equation.makeEquality(Expression.fromCref(var.name),
        Binding.getExp(var.binding), var.ty, InstNode.EMPTY_NODE(),
        ElementSource.createElementSource(var.info)) :: equations;
      var.binding := NFBinding.EMPTY_BINDING;
    end if;
  end moveBinding;

  function getVariableAttributes
    input Variable var;
    output VariableAttributes variableAttributes = var.backendinfo.attributes;
  end getVariableAttributes;

  function getNominal
    input Variable var;
    output Option<Expression> nominal = VariableAttributes.getNominal(getVariableAttributes(var));
  end getNominal;


  annotation(__OpenModelica_Interface="frontend");
end NFVariable;
