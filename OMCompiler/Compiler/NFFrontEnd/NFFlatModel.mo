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

  import FlatModel = NFFlatModel;

  type TypeTree = TypeTreeImpl.Tree;

  encapsulated package TypeTreeImpl
    import BaseAvlTree;
    import Absyn.Path;
    import NFType.Type;

    extends BaseAvlTree;
    redeclare type Key = Absyn.Path;
    redeclare type Value = Type;

    redeclare function extends keyStr
    algorithm
      outString := AbsynUtil.pathString(inKey);
    end keyStr;

    redeclare function extends valueStr
    algorithm
      outString := Type.toString(inValue);
    end valueStr;

    redeclare function extends keyCompare
    algorithm
      outResult := AbsynUtil.pathCompareNoQual(inKey1, inKey2);
    end keyCompare;

    redeclare function addConflictDefault = addConflictKeep;
  end TypeTreeImpl;

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
    flatModel.variables := list(Variable.mapExp(v, fn) for v in flatModel.variables);
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
    s := IOStream.append(s, "class '" + flat_model.name + "'");
    s := FlatModelicaUtil.appendElementSourceCommentString(flat_model.source, s);
    s := IOStream.append(s, "\n");

    flat_model.variables := reconstructRecordInstances(flat_model.variables);

    for fn in functions loop
      if not (Function.isDefaultRecordConstructor(fn) or Function.isExternalObjectConstructorOrDestructor(fn)) then
        s := Function.toFlatStream(fn, s);
        s := IOStream.append(s, ";\n\n");
      end if;
    end for;

    for ty in TypeTree.listValues(collectFlatTypes(flat_model, functions)) loop
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
    output TypeTree types;
  algorithm
    types := TypeTree.new();
    types := List.fold(flatModel.variables, collectVariableFlatTypes, types);
    types := List.fold(flatModel.equations, collectEquationFlatTypes, types);
    types := List.fold(flatModel.initialEquations, collectEquationFlatTypes, types);
    types := List.fold(flatModel.algorithms, collectAlgorithmFlatTypes, types);
    types := List.fold(flatModel.initialAlgorithms, collectAlgorithmFlatTypes, types);
    types := List.fold(functions, collectFunctionFlatTypes, types);
  end collectFlatTypes;

  function collectVariableFlatTypes
    input Variable var;
    input output TypeTree types;
  algorithm
    types := collectFlatType(var.ty, types);
    types := collectBindingFlatTypes(var.binding, types);

    for attr in var.typeAttributes loop
      types := collectBindingFlatTypes(Util.tuple22(attr), types);
    end for;
  end collectVariableFlatTypes;

  function collectFlatType
    input Type ty;
    input output TypeTree types;
  algorithm
    () := match ty
      case Type.ENUMERATION()
        algorithm
          types := TypeTree.add(types, ty.typePath, ty);
        then
          ();

      case Type.ARRAY()
        algorithm
          types := Dimension.foldExpList(ty.dimensions, collectExpFlatTypes_traverse, types);
          types := collectFlatType(ty.elementType, types);
        then
          ();

      case Type.COMPLEX(complexTy = ComplexType.RECORD())
        algorithm
          types := TypeTree.add(types, InstNode.scopePath(ty.cls), ty);
        then
          ();

      case Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT())
        algorithm
          types := TypeTree.add(types, InstNode.scopePath(ty.cls), ty);
        then
          ();

      else ();
    end match;
  end collectFlatType;

  function collectBindingFlatTypes
    input Binding binding;
    input output TypeTree types;
  algorithm
    if Binding.isExplicitlyBound(binding) then
      types := collectExpFlatTypes(Binding.getTypedExp(binding), types);
    end if;
  end collectBindingFlatTypes;

  function collectEquationFlatTypes
    input Equation eq;
    input output TypeTree types;
  algorithm
    () := match eq
      case Equation.EQUALITY()
        algorithm
          types := collectExpFlatTypes(eq.lhs, types);
          types := collectExpFlatTypes(eq.rhs, types);
          types := collectFlatType(eq.ty, types);
        then
          ();

      case Equation.ARRAY_EQUALITY()
        algorithm
          types := collectExpFlatTypes(eq.lhs, types);
          types := collectExpFlatTypes(eq.rhs, types);
          types := collectFlatType(eq.ty, types);
        then
          ();

      case Equation.FOR()
        algorithm
          types := Util.applyOptionOrDefault(eq.range,
            function collectExpFlatTypes(types = types), types);
          types := List.fold(eq.body, collectEquationFlatTypes, types);
        then
          ();

      case Equation.IF()
        algorithm
          types := List.fold(eq.branches, collectEqBranchFlatTypes, types);
        then
          ();

      case Equation.WHEN()
        algorithm
          types := List.fold(eq.branches, collectEqBranchFlatTypes, types);
        then
          ();

      case Equation.ASSERT()
        algorithm
          types := collectExpFlatTypes(eq.condition, types);
          types := collectExpFlatTypes(eq.message, types);
          types := collectExpFlatTypes(eq.level, types);
        then
          ();

      case Equation.TERMINATE()
        algorithm
          types := collectExpFlatTypes(eq.message, types);
        then
          ();

      case Equation.REINIT()
        algorithm
          types := collectExpFlatTypes(eq.reinitExp, types);
        then
          ();

      case Equation.NORETCALL()
        algorithm
          types := collectExpFlatTypes(eq.exp, types);
        then
          ();

      else ();
    end match;
  end collectEquationFlatTypes;

  function collectEqBranchFlatTypes
    input Equation.Branch branch;
    input output TypeTree types;
  algorithm
    () := match branch
      case Equation.Branch.BRANCH()
        algorithm
          types := collectExpFlatTypes(branch.condition, types);
          types := List.fold(branch.body, collectEquationFlatTypes, types);
        then
          ();

      else ();
    end match;
  end collectEqBranchFlatTypes;

  function collectAlgorithmFlatTypes
    input Algorithm alg;
    input output TypeTree types;
  algorithm
    types := List.fold(alg.statements, collectStatementFlatTypes, types);
  end collectAlgorithmFlatTypes;

  function collectStatementFlatTypes
    input Statement stmt;
    input output TypeTree types;
  algorithm
    () := match stmt
      case Statement.ASSIGNMENT()
        algorithm
          types := collectExpFlatTypes(stmt.lhs, types);
          types := collectExpFlatTypes(stmt.rhs, types);
          types := collectFlatType(stmt.ty, types);
        then
          ();

      case Statement.FOR()
        algorithm
          types := List.fold(stmt.body, collectStatementFlatTypes, types);
          types := collectExpFlatTypes(Util.getOption(stmt.range), types);
        then
          ();

      case Statement.IF()
        algorithm
          types := List.fold(stmt.branches, collectStmtBranchFlatTypes, types);
        then
          ();

      case Statement.WHEN()
        algorithm
          types := List.fold(stmt.branches, collectStmtBranchFlatTypes, types);
        then
          ();

      case Statement.ASSERT()
        algorithm
          types := collectExpFlatTypes(stmt.condition, types);
          types := collectExpFlatTypes(stmt.message, types);
          types := collectExpFlatTypes(stmt.level, types);
        then
          ();

      case Statement.TERMINATE()
        algorithm
          types := collectExpFlatTypes(stmt.message, types);
        then
          ();

      case Statement.NORETCALL()
        algorithm
          types := collectExpFlatTypes(stmt.exp, types);
        then
          ();

      case Statement.WHILE()
        algorithm
          types := collectExpFlatTypes(stmt.condition, types);
          types := List.fold(stmt.body, collectStatementFlatTypes, types);
        then
          ();

      else ();
    end match;
  end collectStatementFlatTypes;

  function collectStmtBranchFlatTypes
    input tuple<Expression, list<Statement>> branch;
    input output TypeTree types;
  algorithm
    types := collectExpFlatTypes(Util.tuple21(branch), types);
    types := List.fold(Util.tuple22(branch), collectStatementFlatTypes, types);
  end collectStmtBranchFlatTypes;

  function collectExpFlatTypes
    input Expression exp;
    input output TypeTree types;
  algorithm
    types := Expression.fold(exp, collectExpFlatTypes_traverse, types);
  end collectExpFlatTypes;

  function collectExpFlatTypes_traverse
    input Expression exp;
    input output TypeTree types;
  algorithm
    types := match exp
      case Expression.SUBSCRIPTED_EXP()
        guard Flags.getConfigBool(Flags.MODELICA_OUTPUT)
        algorithm
          types := collectSubscriptedFlatType(exp.exp, exp.subscripts, exp.ty, types);
        then
          types;

      else collectFlatType(Expression.typeOf(exp), types);
    end match;
  end collectExpFlatTypes_traverse;

  function collectFunctionFlatTypes
    input Function fn;
    input output TypeTree types;
  protected
    list<Statement> body;
  algorithm
    types := ClassTree.foldComponents(Class.classTree(InstNode.getClass(fn.node)),
      collectComponentFlatTypes, types);
    if not Function.isExternal(fn) then
      body := Function.getBody(fn);
      types := List.fold(body, collectStatementFlatTypes, types);
    end if;
  end collectFunctionFlatTypes;

  function collectComponentFlatTypes
    input InstNode component;
    input output TypeTree types;
  protected
    Component comp;
  algorithm
    comp := InstNode.component(component);
    types := collectFlatType(Component.getType(comp), types);
    types := collectBindingFlatTypes(Component.getBinding(comp), types);
  end collectComponentFlatTypes;

  function collectSubscriptedFlatType
    input Expression exp;
    input list<Subscript> subs;
    input Type subscriptedTy;
    input output TypeTree types;
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
    types := TypeTree.add(types, Absyn.IDENT(name), Type.SUBSCRIPTED(name, exp_ty, sub_tyl, subscriptedTy));
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
      Component.getAttributes(record_comp), {}, {}, Component.comment(record_comp), InstNode.info(record_node));
  end reconstructRecordInstance;

  annotation(__OpenModelica_Interface="frontend");
end NFFlatModel;
