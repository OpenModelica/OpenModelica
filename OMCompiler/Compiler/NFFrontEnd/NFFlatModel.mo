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

encapsulated uniontype NFFlatModel
  import Equation = NFEquation;
  import Algorithm = NFAlgorithm;
  import Variable = NFVariable;

protected
  import Statement = NFStatement;
  import NFFunction.Function;
  import Expression = NFExpression;
  import Type = NFType;
  import Binding = NFBinding;
  import Dimension = NFDimension;
  import ComplexType = NFComplexType;
  import NFInstNode.InstNode;
  import IOStream;
  import NFSubscript.Subscript;
  import Class = NFClass;
  import NFClassTree.ClassTree;
  import Component = NFComponent;
  import NFComponentRef.ComponentRef;
  import DAE.ElementSource;
  import MetaModelica.Dangerous.listReverseInPlace;
  import Util;
  import Prefixes = NFPrefixes;
  import NFPrefixes.Visibility;
  import FlatModelicaUtil = NFFlatModelicaUtil;
  import UnorderedMap;
  import Typing = NFTyping;
  import ErrorExt;
  import Lookup = NFLookup;
  import InstContext = NFInstContext;

  import FlatModel = NFFlatModel;

  type TypeMap = UnorderedMap<Absyn.Path, Type>;

public
  record FLAT_MODEL
    String name;
    list<Variable> variables;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<Algorithm> algorithms;
    list<Algorithm> initialAlgorithms;
    ElementSource source;
  end FLAT_MODEL;

  function mapExp
    input output FlatModel flatModel;
    input MapFn fn;

    partial function MapFn
      input output Expression exp;
    end MapFn;
  algorithm
    flatModel.variables := list(Variable.mapExpShallow(v, fn) for v in flatModel.variables);
    flatModel.equations := Equation.mapExpList(flatModel.equations, fn);
    flatModel.initialEquations := Equation.mapExpList(flatModel.initialEquations, fn);
    flatModel.algorithms := Algorithm.mapExpList(flatModel.algorithms, fn);
    flatModel.initialAlgorithms := Algorithm.mapExpList(flatModel.initialAlgorithms, fn);
  end mapExp;

  function mapEquations
    input output FlatModel flatModel;
    input MapFn fn;

    partial function MapFn
      input output Equation eq;
    end MapFn;
  algorithm
    flatModel.equations := list(Equation.map(eq, fn) for eq in flatModel.equations);
    flatModel.initialEquations := list(Equation.map(eq, fn) for eq in flatModel.initialEquations);
  end mapEquations;

  function mapAlgorithms
    input output FlatModel flatModel;
    input MapFn fn;

    partial function MapFn
      input output Algorithm alg;
    end MapFn;
  algorithm
    flatModel.algorithms := list(fn(alg) for alg in flatModel.algorithms);
    flatModel.initialAlgorithms := list(fn(alg) for alg in flatModel.initialAlgorithms);
  end mapAlgorithms;

  function toString
    input FlatModel flatModel;
    input Boolean printBindingTypes = false;
    output String str = IOStream.string(toStream(flatModel, printBindingTypes));
  end toString;

  function printString
    input FlatModel flatModel;
    input Boolean printBindingTypes = false;
  protected
    IOStream.IOStream s;
  algorithm
    s := toStream(flatModel, printBindingTypes);
    IOStream.print(s, IOStream.stdOutput);
  end printString;

  function toStream
    input FlatModel flatModel;
    input Boolean printBindingTypes = false;
    output IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
    s := appendStream(flatModel, printBindingTypes, s);
  end toStream;

  function appendStream
    input FlatModel flatModel;
    input Boolean printBindingTypes = false;
    input output IOStream.IOStream s;
  algorithm
    s := IOStream.append(s, "class " + flatModel.name + "\n");

    for v in flatModel.variables loop
      s := Variable.toStream(v, "  ", printBindingTypes, s);
      s := IOStream.append(s, ";\n");
    end for;

    if not listEmpty(flatModel.initialEquations) then
      s := IOStream.append(s, "initial equation\n");
      s := Equation.toStreamList(flatModel.initialEquations, "  ", s);
    end if;

    if not listEmpty(flatModel.equations) then
      s := IOStream.append(s, "equation\n");
      s := Equation.toStreamList(flatModel.equations, "  ", s);
    end if;

    for alg in flatModel.initialAlgorithms loop
      if not listEmpty(alg.statements) then
        s := IOStream.append(s, "initial algorithm\n");
        s := Statement.toStreamList(alg.statements, "  ", s);
      end if;
    end for;

    for alg in flatModel.algorithms loop
      if not listEmpty(alg.statements) then
        s := IOStream.append(s, "algorithm\n");
        s := Statement.toStreamList(alg.statements, "  ", s);
      end if;
    end for;

    s := IOStream.append(s, "end " + flatModel.name + ";\n");
  end appendStream;

  function toFlatString
    "Returns a string containing the flat Modelica representation of the given model."
    input FlatModel flatModel;
    input list<Function> functions;
    input Boolean printBindingTypes = false;
    output String str = IOStream.string(toFlatStream(flatModel, functions, printBindingTypes));
  end toFlatString;

  function printFlatString
    "Prints a flat Modelica representation of the given model to standard output."
    input FlatModel flatModel;
    input list<Function> functions;
    input Boolean printBindingTypes = false;
  protected
    IOStream.IOStream s;
  algorithm
    s := toFlatStream(flatModel, functions, printBindingTypes);
    IOStream.print(s, IOStream.stdOutput);
  end printFlatString;

  function toFlatStream
    "Returns a new IOStream containing the flat Modelica representation of the given model."
    input FlatModel flatModel;
    input list<Function> functions;
    input Boolean printBindingTypes = false;
    output IOStream.IOStream s;
  algorithm
    s := IOStream.create(flatModel.name, IOStream.IOStreamType.LIST());
    s := appendFlatStream(flatModel, functions, printBindingTypes, s);
  end toFlatStream;

  function appendFlatStream
    "Appends the flat Modelica representation of the given model to an existing IOStream."
    input FlatModel flatModel;
    input list<Function> functions;
    input Boolean printBindingTypes = false;
    input output IOStream.IOStream s;
  protected
    FlatModel flat_model = flatModel;
    Visibility visibility = Visibility.PUBLIC;
  algorithm
    s := IOStream.append(s, "model '" + flat_model.name + "'");
    s := FlatModelicaUtil.appendElementSourceCommentString(flat_model.source, s);
    s := IOStream.append(s, "\n");

    flat_model.variables := reconstructRecordInstances(flat_model.variables);

    for fn in functions loop
      if not (Function.isDefaultRecordConstructor(fn) or Function.isExternalObjectConstructorOrDestructor(fn)) then
        s := Function.toFlatStream(fn, s);
        s := IOStream.append(s, ";\n\n");
      end if;
    end for;

    for ty in collectFlatTypes(flat_model, functions) loop
      s := Type.toFlatDeclarationStream(ty, s);
      s := IOStream.append(s, ";\n\n");
    end for;

    for v in flat_model.variables loop
      if visibility <> Variable.visibility(v) then
        visibility := Variable.visibility(v);
        s := IOStream.append(s, Prefixes.visibilityString(visibility));
        s := IOStream.append(s, "\n");
      end if;

      s := Variable.toFlatStream(v, "  ", printBindingTypes, s);
      s := IOStream.append(s, ";\n");
    end for;

    if not listEmpty(flat_model.initialEquations) then
      s := IOStream.append(s, "initial equation\n");
      s := Equation.toFlatStreamList(flat_model.initialEquations, "  ", s);
    end if;

    if not listEmpty(flat_model.equations) then
      s := IOStream.append(s, "equation\n");
      s := Equation.toFlatStreamList(flat_model.equations, "  ", s);
    end if;

    for alg in flat_model.initialAlgorithms loop
      if not listEmpty(alg.statements) then
        s := IOStream.append(s, "initial algorithm\n");
        s := Statement.toFlatStreamList(alg.statements, "  ", s);
      end if;
    end for;

    for alg in flat_model.algorithms loop
      if not listEmpty(alg.statements) then
        s := IOStream.append(s, "algorithm\n");
        s := Statement.toFlatStreamList(alg.statements, "  ", s);
      end if;
    end for;

    s := FlatModelicaUtil.appendElementSourceCommentAnnotation(flat_model.source, "  ", ";\n", s);
    s := IOStream.append(s, "end '" + flat_model.name + "';\n");
  end appendFlatStream;

  function collectFlatTypes
    input FlatModel flatModel;
    input list<Function> functions;
    output list<Type> outTypes;
  protected
    TypeMap types;
  algorithm
    types := UnorderedMap.new<Type>(AbsynUtil.pathHash, AbsynUtil.pathEqual);
    List.map1_0(flatModel.variables, collectVariableFlatTypes, types);
    List.map1_0(flatModel.equations, collectEquationFlatTypes, types);
    List.map1_0(flatModel.initialEquations, collectEquationFlatTypes, types);
    List.map1_0(flatModel.algorithms, collectAlgorithmFlatTypes, types);
    List.map1_0(flatModel.initialAlgorithms, collectAlgorithmFlatTypes, types);
    List.map1_0(functions, collectFunctionFlatTypes, types);
    outTypes := UnorderedMap.valueList(types);
    outTypes := list(typeFlatType(ty) for ty in outTypes);
  end collectFlatTypes;

  function collectVariableFlatTypes
    input Variable var;
    input TypeMap types;
  algorithm
    collectFlatType(var.ty, types);
    collectBindingFlatTypes(var.binding, types);

    for attr in var.typeAttributes loop
      collectBindingFlatTypes(Util.tuple22(attr), types);
    end for;
  end collectVariableFlatTypes;

  function collectFlatType
    input Type ty;
    input TypeMap types;
  algorithm
    () := match ty
      case Type.ENUMERATION()
        algorithm
          UnorderedMap.tryAdd(ty.typePath, ty, types);
        then
          ();

      case Type.ARRAY()
        algorithm
          Dimension.foldExpList(ty.dimensions, collectExpFlatTypes_traverse, types);
          collectFlatType(ty.elementType, types);
        then
          ();

      case Type.COMPLEX(complexTy = ComplexType.RECORD())
        algorithm
          UnorderedMap.tryAdd(InstNode.scopePath(ty.cls), ty, types);
        then
          ();

      case Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT())
        algorithm
          UnorderedMap.tryAdd(InstNode.scopePath(ty.cls), ty, types);
        then
          ();

      else ();
    end match;
  end collectFlatType;

  function collectBindingFlatTypes
    input Binding binding;
    input TypeMap types;
  algorithm
    if Binding.isExplicitlyBound(binding) then
      collectExpFlatTypes(Binding.getTypedExp(binding), types);
    end if;
  end collectBindingFlatTypes;

  function collectEquationFlatTypes
    input Equation eq;
    input TypeMap types;
  algorithm
    () := match eq
      case Equation.EQUALITY()
        algorithm
          collectExpFlatTypes(eq.lhs, types);
          collectExpFlatTypes(eq.rhs, types);
          collectFlatType(eq.ty, types);
        then
          ();

      case Equation.ARRAY_EQUALITY()
        algorithm
          collectExpFlatTypes(eq.lhs, types);
          collectExpFlatTypes(eq.rhs, types);
          collectFlatType(eq.ty, types);
        then
          ();

      case Equation.FOR()
        algorithm
          if isSome(eq.range) then
            collectExpFlatTypes(Util.getOption(eq.range), types);
          end if;

          List.map1_0(eq.body, collectEquationFlatTypes, types);
        then
          ();

      case Equation.IF()
        algorithm
          List.map1_0(eq.branches, collectEqBranchFlatTypes, types);
        then
          ();

      case Equation.WHEN()
        algorithm
          List.map1_0(eq.branches, collectEqBranchFlatTypes, types);
        then
          ();

      case Equation.ASSERT()
        algorithm
          collectExpFlatTypes(eq.condition, types);
          collectExpFlatTypes(eq.message, types);
          collectExpFlatTypes(eq.level, types);
        then
          ();

      case Equation.TERMINATE()
        algorithm
          collectExpFlatTypes(eq.message, types);
        then
          ();

      case Equation.REINIT()
        algorithm
          collectExpFlatTypes(eq.reinitExp, types);
        then
          ();

      case Equation.NORETCALL()
        algorithm
          collectExpFlatTypes(eq.exp, types);
        then
          ();

      else ();
    end match;
  end collectEquationFlatTypes;

  function collectEqBranchFlatTypes
    input Equation.Branch branch;
    input TypeMap types;
  algorithm
    () := match branch
      case Equation.Branch.BRANCH()
        algorithm
          collectExpFlatTypes(branch.condition, types);
          List.map1_0(branch.body, collectEquationFlatTypes, types);
        then
          ();

      else ();
    end match;
  end collectEqBranchFlatTypes;

  function collectAlgorithmFlatTypes
    input Algorithm alg;
    input TypeMap types;
  algorithm
    collectStatementsFlatTypes(alg.statements, types);
  end collectAlgorithmFlatTypes;

  function collectStatementsFlatTypes
    input list<Statement> statements;
    input TypeMap types;
  algorithm
    for s in statements loop
      collectStatementFlatTypes(s, types);
    end for;
  end collectStatementsFlatTypes;

  function collectStatementFlatTypes
    input Statement stmt;
    input TypeMap types;
  algorithm
    () := match stmt
      case Statement.ASSIGNMENT()
        algorithm
          collectExpFlatTypes(stmt.lhs, types);
          collectExpFlatTypes(stmt.rhs, types);
          collectFlatType(stmt.ty, types);
        then
          ();

      case Statement.FOR()
        algorithm
          collectStatementsFlatTypes(stmt.body, types);
          collectExpFlatTypes(Util.getOption(stmt.range), types);
        then
          ();

      case Statement.IF()
        algorithm
          List.map1_0(stmt.branches, collectStmtBranchFlatTypes, types);
        then
          ();

      case Statement.WHEN()
        algorithm
          List.map1_0(stmt.branches, collectStmtBranchFlatTypes, types);
        then
          ();

      case Statement.ASSERT()
        algorithm
          collectExpFlatTypes(stmt.condition, types);
          collectExpFlatTypes(stmt.message, types);
          collectExpFlatTypes(stmt.level, types);
        then
          ();

      case Statement.TERMINATE()
        algorithm
          collectExpFlatTypes(stmt.message, types);
        then
          ();

      case Statement.REINIT()
        algorithm
          collectExpFlatTypes(stmt.cref, types);
          collectExpFlatTypes(stmt.reinitExp, types);
        then
          ();

      case Statement.NORETCALL()
        algorithm
          collectExpFlatTypes(stmt.exp, types);
        then
          ();

      case Statement.WHILE()
        algorithm
          collectExpFlatTypes(stmt.condition, types);
          collectStatementsFlatTypes(stmt.body, types);
        then
          ();

      else ();
    end match;
  end collectStatementFlatTypes;

  function collectStmtBranchFlatTypes
    input tuple<Expression, list<Statement>> branch;
    input TypeMap types;
  algorithm
    collectExpFlatTypes(Util.tuple21(branch), types);
    collectStatementsFlatTypes(Util.tuple22(branch), types);
  end collectStmtBranchFlatTypes;

  function collectExpFlatTypes
    input Expression exp;
    input TypeMap types;
  algorithm
    Expression.fold(exp, collectExpFlatTypes_traverse, types);
  end collectExpFlatTypes;

  function collectExpFlatTypes_traverse
    input Expression exp;
    input output TypeMap types;
  algorithm
    () := match exp
      case Expression.SUBSCRIPTED_EXP()
        guard Flags.getConfigBool(Flags.MODELICA_OUTPUT)
        algorithm
          collectSubscriptedFlatType(exp.exp, exp.subscripts, exp.ty, types);
        then
          ();

      else
        algorithm
          collectFlatType(Expression.typeOf(exp), types);
        then
          ();

    end match;
  end collectExpFlatTypes_traverse;

  function collectFunctionFlatTypes
    input Function fn;
    input TypeMap types;
  algorithm
    ClassTree.applyComponents(Class.classTree(InstNode.getClass(fn.node)),
      function collectComponentFlatTypes(types = types));

    if not Function.isExternal(fn) then
      collectStatementsFlatTypes(Function.getBody(fn), types);
    end if;
  end collectFunctionFlatTypes;

  function collectComponentFlatTypes
    input InstNode component;
    input TypeMap types;
  protected
    Component comp;
  algorithm
    comp := InstNode.component(component);
    collectFlatType(Component.getType(comp), types);
    collectBindingFlatTypes(Component.getBinding(comp), types);
  end collectComponentFlatTypes;

  function collectSubscriptedFlatType
    input Expression exp;
    input list<Subscript> subs;
    input Type subscriptedTy;
    input TypeMap types;
  protected
    Type exp_ty;
    list<Type> sub_tyl;
    list<Dimension> dims;
    list<String> strl;
    String name;
  algorithm
    exp_ty := Expression.typeOf(exp);
    dims := List.firstN(Type.arrayDims(exp_ty), listLength(subs));
    sub_tyl := list(Dimension.subscriptType(d) for d in dims);
    name := Type.subscriptedTypeName(exp_ty, sub_tyl);
    UnorderedMap.tryAdd(Absyn.IDENT(name), Type.SUBSCRIPTED(name, exp_ty, sub_tyl, subscriptedTy), types);
  end collectSubscriptedFlatType;

  function reconstructRecordInstances
    input list<Variable> variables;
    output list<Variable> outVariables = {};
  protected
    list<Variable> rest_vars = variables, record_vars;
    Variable var;
    ComponentRef parent_cr;
    Type parent_ty;
    Integer field_count;
  algorithm
    while not listEmpty(rest_vars) loop
      var :: rest_vars := rest_vars;
      parent_cr := ComponentRef.rest(var.name);

      if not ComponentRef.isEmpty(parent_cr) then
        parent_ty := ComponentRef.nodeType(parent_cr);

        if Type.isRecord(parent_ty) then
          field_count := listLength(Type.recordFields(parent_ty));
          (record_vars, rest_vars) := List.split(rest_vars, field_count - 1);
          record_vars := var :: record_vars;
          var := reconstructRecordInstance(parent_cr, record_vars);
        end if;
      end if;

      outVariables := var :: outVariables;
    end while;

    outVariables := listReverseInPlace(outVariables);
  end reconstructRecordInstances;

  function reconstructRecordInstance
    input ComponentRef recordName;
    input list<Variable> variables;
    output Variable recordVar;
  protected
    InstNode record_node;
    Component record_comp;
    Type record_ty;
    list<Expression> field_exps;
    Expression record_exp;
    Binding record_binding;
  algorithm
    record_node := ComponentRef.node(recordName);
    record_comp := InstNode.component(record_node);
    record_ty := ComponentRef.nodeType(recordName);

    // Reconstruct the record instance binding if possible. If any field is
    // missing a binding we assume that the record instance didn't have a
    // binding in the first place, or that the binding was moved to an equation
    // during flattening.
    field_exps := {};
    for v in variables loop
      if Binding.hasExp(v.binding) then
        field_exps := Binding.getExp(v.binding) :: field_exps;
      else
        field_exps := {};
        break;
      end if;
    end for;

    if listEmpty(field_exps) then
      record_binding := NFBinding.EMPTY_BINDING;
    else
      field_exps := listReverseInPlace(field_exps);
      record_exp := Expression.makeRecord(InstNode.scopePath(InstNode.classScope(record_node)), record_ty, field_exps);
      record_binding := Binding.makeFlat(record_exp, Component.variability(record_comp), NFBinding.Source.GENERATED);
    end if;

    recordVar := Variable.VARIABLE(recordName, record_ty, record_binding, InstNode.visibility(record_node),
      Component.getAttributes(record_comp), {}, {}, Component.comment(record_comp), InstNode.info(record_node), NFBackendExtension.DUMMY_BACKEND_INFO);
  end reconstructRecordInstance;

  function typeFlatType
    input output Type ty;
  algorithm
    () := match ty
      case Type.COMPLEX(complexTy = ComplexType.RECORD())
        algorithm
          Typing.typeBindings(ty.cls, NFInstContext.CLASS);
        then
          ();

      else ();
    end match;
  end typeFlatType;

protected
  type ObfuscationMap = UnorderedMap<InstNode, String>;

public
  function obfuscate
    input output FlatModel flatModel;
  protected
    ObfuscationMap obfuscation_map;
    Boolean only_encrypted;
  algorithm
    only_encrypted := Flags.getConfigString(Flags.OBFUSCATE) == "encrypted";
    obfuscation_map := UnorderedMap.new<String>(InstNode.hash, InstNode.refEqual);

    for v in flatModel.variables loop
      addObfuscatedVariable(v, only_encrypted, obfuscation_map);
    end for;

    if UnorderedMap.isEmpty(obfuscation_map) then
      return;
    end if;

    flatModel.variables := list(obfuscateVariable(v, obfuscation_map) for v in flatModel.variables);
    flatModel := mapEquations(flatModel, function obfuscateEquation(obfuscationMap = obfuscation_map));
    flatModel := mapAlgorithms(flatModel, function obfuscateAlgorithm(obfuscationMap = obfuscation_map));
  end obfuscate;

  function addObfuscatedVariable
    input Variable var;
    input Boolean onlyEncrypted;
    input ObfuscationMap obfuscationMap;
  protected
    SourceInfo info;
    String filename;
    list<InstNode> nodes;
  algorithm
    if Variable.isProtected(var) and (not onlyEncrypted or Variable.isEncrypted(var)) then
      nodes := ComponentRef.nodes(var.name);
      nodes := List.trim(nodes, InstNode.isPublic);

      for node in nodes loop
        UnorderedMap.tryAdd(node, "n" + String(UnorderedMap.size(obfuscationMap) + 1), obfuscationMap);
      end for;
    end if;
  end addObfuscatedVariable;

  function obfuscateVariable
    input output Variable var;
    input ObfuscationMap obfuscationMap;
  algorithm
    var.name := obfuscateCref(var.name, obfuscationMap);
    var.comment := obfuscateCommentOpt(var.comment, ComponentRef.node(var.name), obfuscationMap);
    var := Variable.mapExpShallow(var, function obfuscateExp(obfuscationMap = obfuscationMap));
  end obfuscateVariable;

  function obfuscateCref
    input output ComponentRef cref;
    input ObfuscationMap obfuscationMap;
  protected
    Option<String> name;
  algorithm
    () := match cref
      case ComponentRef.CREF()
        algorithm
          name := UnorderedMap.get(cref.node, obfuscationMap);

          if isSome(name) then
            cref.node := InstNode.rename(Util.getOption(name), cref.node);
          end if;

          cref.subscripts := list(Subscript.mapShallowExp(s,
            function obfuscateExp(obfuscationMap = obfuscationMap)) for s in cref.subscripts);
        then
          ();

      else ();
    end match;
  end obfuscateCref;

  function obfuscateExp
    input output Expression exp;
    input ObfuscationMap obfuscationMap;
  algorithm
    exp := Expression.map(exp, function obfuscateExp_impl(obfuscationMap = obfuscationMap));
  end obfuscateExp;

  function obfuscateExpOpt
    input output Option<Expression> exp;
    input ObfuscationMap obfuscationMap;
  algorithm
    if isSome(exp) then
      exp := SOME(obfuscateExp(Util.getOption(exp), obfuscationMap));
    end if;
  end obfuscateExpOpt;

  function obfuscateExp_impl
    input output Expression exp;
    input ObfuscationMap obfuscationMap;
  algorithm
    () := match exp
      case Expression.CREF()
        algorithm
          exp.cref := obfuscateCref(exp.cref, obfuscationMap);
        then
          ();

      else ();
    end match;
  end obfuscateExp_impl;

  function obfuscateEquation
    input output Equation eq;
    input ObfuscationMap obfuscationMap;
  algorithm
    eq := Equation.setSource(obfuscateSource(Equation.source(eq), Equation.scope(eq), obfuscationMap), eq);
    eq := Equation.mapExpShallow(eq, function obfuscateExp(obfuscationMap = obfuscationMap));
  end obfuscateEquation;

  function obfuscateAlgorithm
    input output Algorithm alg;
    input ObfuscationMap obfuscationMap;
  algorithm
    alg.source := obfuscateSource(alg.source, alg.scope, obfuscationMap);
    alg.inputs := list(obfuscateCref(e, obfuscationMap) for e in alg.inputs);
    alg.outputs := list(obfuscateCref(e, obfuscationMap) for e in alg.outputs);
    alg.statements := list(Statement.map(s,
      function obfuscateStatement(scope = alg.scope, obfuscationMap = obfuscationMap)) for s in alg.statements);
  end obfuscateAlgorithm;

  function obfuscateStatement
    input output Statement stmt;
    input InstNode scope;
    input ObfuscationMap obfuscationMap;
  algorithm
    stmt := Statement.setSource(obfuscateSource(Statement.source(stmt), scope, obfuscationMap), stmt);
    stmt := Statement.mapExpShallow(stmt, function obfuscateExp(obfuscationMap = obfuscationMap));
  end obfuscateStatement;

  function obfuscateSource
    input output DAE.ElementSource source;
    input InstNode scope;
    input ObfuscationMap obfuscationMap;
  algorithm
    source.comment := list(obfuscateComment(c, scope, obfuscationMap) for c in source.comment);
  end obfuscateSource;

  function obfuscateCommentOpt
    input output Option<SCode.Comment> comment;
    input InstNode scope;
    input ObfuscationMap obfuscationMap;
  algorithm
    comment := Util.applyOption(comment,
      function obfuscateComment(scope = scope, obfuscationMap = obfuscationMap));
  end obfuscateCommentOpt;

  function obfuscateComment
    input output SCode.Comment comment;
    input InstNode scope;
    input ObfuscationMap obfuscationMap;
  algorithm
    comment.annotation_ := obfuscateAnnotationOpt(comment.annotation_, scope, obfuscationMap);
    comment.comment := NONE();
  end obfuscateComment;

  function obfuscateAnnotationOpt
    input output Option<SCode.Annotation> ann;
    input InstNode scope;
    input ObfuscationMap obfuscationMap;
  algorithm
    ann := Util.applyOption(ann,
      function obfuscateAnnotation(scope = scope, obfuscationMap = obfuscationMap));
  end obfuscateAnnotationOpt;

  function obfuscateAnnotation
    input output SCode.Annotation ann;
    input InstNode scope;
    input ObfuscationMap obfuscationMap;
  algorithm
    ann.modification := obfuscateAnnotationMod(ann.modification, scope, obfuscationMap);
  end obfuscateAnnotation;

  function obfuscateAnnotationMod
    input output SCode.Mod mod;
    input InstNode scope;
    input ObfuscationMap obfuscationMap;
  algorithm
    () := match mod
      case SCode.Mod.MOD()
        algorithm
          mod.subModLst := list(obfuscateAnnotationSubMod(s, scope, obfuscationMap)
            for s guard isAllowedAnnotation(s) in mod.subModLst);
          mod.binding := obfuscateAbsynExpOpt(mod.binding, scope, obfuscationMap);
        then
          ();

      else ();
    end match;
  end obfuscateAnnotationMod;

  function isAllowedAnnotation
    input SCode.SubMod mod;
    output Boolean allowed;
  algorithm
    allowed := match mod.ident
      case "Icon" then false;
      case "Diagram" then false;
      case "Dialog" then false;
      case "IconMap" then false;
      case "DiagramMap" then false;
      case "Placement" then false;
      case "Text" then false;
      case "Line" then false;
      case "defaultComponentName" then false;
      case "defaultComponentPrefixes" then false;
      case "missingInnerMessage" then false;
      case "obsolete" then false;
      case "unassignedMessage" then false;
      case "Protection" then false;
      case "Authorization" then false;
      else not Util.stringStartsWith("__", mod.ident);
    end match;
  end isAllowedAnnotation;

  function obfuscateAnnotationSubMod
    input output SCode.SubMod mod;
    input InstNode scope;
    input ObfuscationMap obfuscationMap;
  algorithm
    mod.mod := obfuscateAnnotationMod(mod.mod, scope, obfuscationMap);
  end obfuscateAnnotationSubMod;

  function obfuscateAbsynExpOpt
    input output Option<Absyn.Exp> exp;
    input InstNode scope;
    input ObfuscationMap obfuscationMap;
  algorithm
    exp := Util.applyOption(exp,
      function obfuscateAbsynExp(scope = scope, obfuscationMap = obfuscationMap));
  end obfuscateAbsynExpOpt;

  function obfuscateAbsynExp
    input output Absyn.Exp exp;
    input InstNode scope;
    input ObfuscationMap obfuscationMap;
  algorithm
    exp := AbsynUtil.traverseExp(exp, function obfuscateAbsynExpTraverse(scope = scope), obfuscationMap);
  end obfuscateAbsynExp;

  function obfuscateAbsynExpTraverse
    input output Absyn.Exp exp;
    input InstNode scope;
    input output ObfuscationMap obfuscationMap;
  algorithm
    () := match exp
      case Absyn.Exp.CREF()
        algorithm
          exp.componentRef := obfuscateAbsynCref(exp.componentRef, scope, obfuscationMap);
        then
          ();

      else ();
    end match;
  end obfuscateAbsynExpTraverse;

  function obfuscateAbsynCref
    input output Absyn.ComponentRef cref;
    input InstNode scope;
    input ObfuscationMap obfuscationMap;
  protected
    ComponentRef inst_cref;
    list<InstNode> nodes;
  algorithm
    ErrorExt.setCheckpoint(getInstanceName());
    try
      inst_cref := Lookup.lookupCref(cref, scope, NFInstContext.RELAXED);
      nodes := list(ComponentRef.node(c) for c in ComponentRef.toListReverse(inst_cref, includeScope = false));
      cref := obfuscateAbsynCref2(cref, nodes, obfuscationMap);
    else
    end try;
    ErrorExt.rollBack(getInstanceName());
  end obfuscateAbsynCref;

  function obfuscateAbsynCref2
    input output Absyn.ComponentRef cref;
    input list<InstNode> nodes;
    input ObfuscationMap obfuscationMap;
  protected
    InstNode node;
    list<InstNode> rest_nodes;
  algorithm
    () := match (cref, nodes)
      case (Absyn.ComponentRef.CREF_FULLYQUALIFIED(), _)
        algorithm
          cref.componentRef := obfuscateAbsynCref2(cref.componentRef, nodes, obfuscationMap);
        then
          ();

      case (Absyn.ComponentRef.CREF_QUAL(), node :: rest_nodes)
        guard InstNode.name(node) == cref.name
        algorithm
          cref.name := UnorderedMap.getOrDefault(node, obfuscationMap, cref.name);
          cref.componentRef := obfuscateAbsynCref2(cref.componentRef, rest_nodes, obfuscationMap);
        then
          ();

      case (Absyn.ComponentRef.CREF_IDENT(), node :: _)
        guard InstNode.name(node) == cref.name
        algorithm
          cref.name := UnorderedMap.getOrDefault(node, obfuscationMap, cref.name);
        then
          ();

      else ();
    end match;
  end obfuscateAbsynCref2;

  function hasArrayConnections
    input FlatModel flatModel;
    input Integer minSize = 100;
    output Boolean hasArrays = false;
  protected
    Type ty;
  algorithm
    for eq in flatModel.equations loop
      if Equation.contains(eq, Equation.isConnect) and Equation.sizeOf(eq) >= minSize then
        hasArrays := true;
        return;
      end if;
    end for;
  end hasArrayConnections;

  annotation(__OpenModelica_Interface="frontend");
end NFFlatModel;
