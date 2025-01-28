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
encapsulated package NBDifferentiate
"file:        NBDifferentiate.mo
 package:     NBDifferentiate
 description: This file contains the functions to differentiate equations and
              expressions symbolically.
"
public
  // OF imports
  import Absyn;
  import AbsynUtil;
  import BaseAvlTree;
  import AvlSetPath;
  import DAE;

  // NF imports
  import Algorithm = NFAlgorithm;
  import Binding = NFBinding;
  import BuiltinFuncs = NFBuiltinFuncs;
  import Call = NFCall;
  import Class = NFClass;
  import Component = NFComponent;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFInstNode.{InstNode, CachedData};
  import NFFlatten.{FunctionTree, FunctionTreeImpl};
  import NFFunction.Function;
  import FunctionDerivative = NFFunctionDerivative;
  import Operator = NFOperator;
  import Prefixes = NFPrefixes;
  import Sections = NFSections;
  import SimplifyExp = NFSimplifyExp;
  import Statement = NFStatement;
  import Type = NFType;
  import NFPrefixes.Variability;
  import Variable = NFVariable;

  // Backend imports
  import NBEquation.{Equation, EquationAttributes, EquationPointer, EquationPointers, IfEquationBody, WhenEquationBody, WhenStatement};
  import NBVariable.{VariablePointer};
  import BVariable = NBVariable;
  import Replacements = NBReplacements;
  import StrongComponent = NBStrongComponent;

  // Util imports
  import Array;
  import BackendUtil = NBBackendUtil;
  import Error;
  import UnorderedMap;
  import Slice = NBSlice;

  // ================================
  //        TYPES AND UNIONTYPES
  // ================================
  type DifferentiationType = enumeration(TIME, SIMPLE, FUNCTION, JACOBIAN);

  uniontype DifferentiationArguments
    record DIFFERENTIATION_ARGUMENTS
      ComponentRef diffCref                                       "The input will be differentiated w.r.t. this cref (only SIMPLE).";
      list<Pointer<Variable>> new_vars                            "contains all new variables that need to be added to the system";
      Option<UnorderedMap<ComponentRef,ComponentRef>> jacobianHT  "seed and temporary cref hashtable x --> $SEED.MATRIX.x, y --> $pDer.MATRIX.y";
      DifferentiationType diffType                                "Differentiation use case (time, simple, function, jacobian)";
      FunctionTree funcTree                                       "Function tree containing all functions and their known derivatives";
      Boolean scalarized                                          "true if the variables are scalarized";
    end DIFFERENTIATION_ARGUMENTS;

    function default
      input DifferentiationType ty = DifferentiationType.TIME;
      input FunctionTree funcTree = FunctionTreeImpl.EMPTY();
      output DifferentiationArguments diffArgs = DIFFERENTIATION_ARGUMENTS(
        diffCref        = ComponentRef.EMPTY(),
        new_vars        = {},
        jacobianHT      = NONE(),
        diffType        = ty,
        funcTree        = funcTree,
        scalarized      = false
      );
    end default;

    function simpleCref "Differentiate w.r.t. cref"
      input ComponentRef cref;
      input FunctionTree funcTree = FunctionTreeImpl.EMPTY();
      output DifferentiationArguments diffArgs = DIFFERENTIATION_ARGUMENTS(
        diffCref        = cref,
        new_vars        = {},
        jacobianHT      = NONE(),
        diffType        = DifferentiationType.SIMPLE,
        funcTree        = funcTree,
        scalarized      = false
      );
    end simpleCref;

    function toString
      input DifferentiationArguments diffArgs;
      output String str = "[" + diffTypeStr(diffArgs.diffType) + "]";
    algorithm
      if diffArgs.diffType == DifferentiationType.SIMPLE then
        str := str + " " + ComponentRef.toString(diffArgs.diffCref);
      end if;
    end toString;

    function diffTypeStr
      input DifferentiationType diffType;
      output String str;
    algorithm
      str := match diffType
        case DifferentiationType.TIME       then "TIME";
        case DifferentiationType.SIMPLE     then "SIMPLE";
        case DifferentiationType.FUNCTION   then "FUNCTION";
        case DifferentiationType.JACOBIAN   then "JACOBIAN";
        else "FAIL";
      end match;
    end diffTypeStr;
  end DifferentiationArguments;

  // ================================
  //             FUNCTIONS
  // ================================

  function differentiateStrongComponentList
    "author: kabdelhak
    Differentiates a list of strong components."
    input output list<StrongComponent> comps;
    input output DifferentiationArguments diffArguments;
    input Pointer<Integer> idx;
    input String context;
    input String name;
  protected
    Pointer<DifferentiationArguments> diffArguments_ptr = Pointer.create(diffArguments);
  algorithm
    comps := List.map(comps, function differentiateStrongComponent(diffArguments_ptr = diffArguments_ptr, idx = idx, context = context, name = name));
    diffArguments := Pointer.access(diffArguments_ptr);
  end differentiateStrongComponentList;

  function differentiateStrongComponent
    input output StrongComponent comp;
    input Pointer<DifferentiationArguments> diffArguments_ptr;
    input Pointer<Integer> idx;
    input String context;
    input String name;
  algorithm
    comp := match comp
      local
        Pointer<Variable> new_var;
        Pointer<Equation> new_eqn;
        list<Slice<VariablePointer>> new_var_slices;
        list<Pointer<Equation>> new_eqns;
        ComponentRef new_cref;
        Slice<VariablePointer> new_var_slice;
        Slice<EquationPointer> new_eqn_slice;
        DifferentiationArguments diffArguments;

      case StrongComponent.SINGLE_COMPONENT() algorithm
        new_var := differentiateVariablePointer(comp.var, diffArguments_ptr);
        new_eqn := differentiateEquationPointer(comp.eqn, diffArguments_ptr, name);
        Equation.createName(new_eqn, idx, context);
      then StrongComponent.SINGLE_COMPONENT(new_var, new_eqn, comp.status);

      case StrongComponent.MULTI_COMPONENT() algorithm
        new_var_slices := list(Slice.apply(var, function differentiateVariablePointer(diffArguments_ptr = diffArguments_ptr)) for var in comp.vars);
        new_eqn_slice := Slice.apply(comp.eqn, function differentiateEquationPointer(diffArguments_ptr = diffArguments_ptr, name = name));
        Equation.createName(Slice.getT(new_eqn_slice), idx = idx, context = context);
      then StrongComponent.MULTI_COMPONENT(new_var_slices, new_eqn_slice, comp.status);

      case StrongComponent.SLICED_COMPONENT() algorithm
        (Expression.CREF(cref = new_cref), diffArguments) := differentiateComponentRef(Expression.fromCref(comp.var_cref), Pointer.access(diffArguments_ptr));
        Pointer.update(diffArguments_ptr, diffArguments);
        new_var_slice := Slice.apply(comp.var, function differentiateVariablePointer(diffArguments_ptr = diffArguments_ptr));
        new_eqn_slice := Slice.apply(comp.eqn, function differentiateEquationPointer(diffArguments_ptr = diffArguments_ptr, name = name));
        Slice.applyMutable(new_eqn_slice, function Equation.createName(idx = idx, context = context));
      then StrongComponent.SLICED_COMPONENT(new_cref, new_var_slice, new_eqn_slice, comp.status);

      case StrongComponent.RESIZABLE_COMPONENT() algorithm
        (Expression.CREF(cref = new_cref), diffArguments) := differentiateComponentRef(Expression.fromCref(comp.var_cref), Pointer.access(diffArguments_ptr));
        Pointer.update(diffArguments_ptr, diffArguments);
        new_var_slice := Slice.apply(comp.var, function differentiateVariablePointer(diffArguments_ptr = diffArguments_ptr));
        new_eqn_slice := Slice.apply(comp.eqn, function differentiateEquationPointer(diffArguments_ptr = diffArguments_ptr, name = name));
        Slice.applyMutable(new_eqn_slice, function Equation.createName(idx = idx, context = context));
      then StrongComponent.RESIZABLE_COMPONENT(new_cref, new_var_slice, new_eqn_slice, comp.order, comp.status);

      case StrongComponent.GENERIC_COMPONENT() algorithm
        (Expression.CREF(cref = new_cref), diffArguments) := differentiateComponentRef(Expression.fromCref(comp.var_cref), Pointer.access(diffArguments_ptr));
        Pointer.update(diffArguments_ptr, diffArguments);
        new_eqn := differentiateEquationPointer(Slice.getT(comp.eqn), diffArguments_ptr, name);
        Equation.createName(new_eqn, idx, context);
      then StrongComponent.GENERIC_COMPONENT(new_cref, Slice.SLICE(new_eqn, comp.eqn.indices));

      case StrongComponent.ENTWINED_COMPONENT() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " not implemented for entwined equation:\n" + StrongComponent.toString(comp)});
      then fail();

      case StrongComponent.ALGEBRAIC_LOOP() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " not implemented for algebraic loop:\n" + StrongComponent.toString(comp)});
      then fail();

      case StrongComponent.ALIAS() then differentiateStrongComponent(comp.original, diffArguments_ptr, idx, context, name);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " not implemented for unknown strong component:\n" + StrongComponent.toString(comp)});
      then fail();
    end match;
  end differentiateStrongComponent;

  function differentiateEquationPointerList
    "author: kabdelhak
    Differentiates a list of equations wrapped in pointers."
    input output list<Pointer<Equation>> equations;
    input output DifferentiationArguments diffArguments;
    input Pointer<Integer> idx;
    input String context;
    input String name;
  protected
    Pointer<DifferentiationArguments> diffArguments_ptr = Pointer.create(diffArguments);
  algorithm
    equations := List.map(equations, function differentiateEquationPointer(diffArguments_ptr = diffArguments_ptr, name = name));
    for eqn in equations loop
      Equation.createName(eqn, idx, context);
    end for;
    diffArguments := Pointer.access(diffArguments_ptr);
  end differentiateEquationPointerList;

  function differentiateEquationPointer
    input Pointer<Equation> eq_ptr;
    input Pointer<DifferentiationArguments> diffArguments_ptr;
    input String name = "";
    output Pointer<Equation> derivative_ptr;
  protected
    Equation eq, diffedEq;
    DifferentiationArguments old_diffArguments, new_diffArguments;
  algorithm
    eq := Pointer.access(eq_ptr);
    old_diffArguments := Pointer.access(diffArguments_ptr);

    derivative_ptr := match Equation.getAttributes(eq)

      // we differentiate w.r.t time and there already is a derivative saved
      case EquationAttributes.EQUATION_ATTRIBUTES(derivative = SOME(derivative_ptr))
        guard(old_diffArguments.diffType == DifferentiationType.TIME)
      then derivative_ptr;

      // else differentiate the equation
      else algorithm
        (diffedEq, new_diffArguments) := differentiateEquation(eq, old_diffArguments, name);
        derivative_ptr := Pointer.create(diffedEq);
        // save the derivative if we derive w.r.t. time
        if new_diffArguments.diffType == DifferentiationType.TIME then
          Pointer.update(eq_ptr, Equation.setDerivative(eq, derivative_ptr));
        end if;
        if not referenceEq(new_diffArguments, old_diffArguments) then
          Pointer.update(diffArguments_ptr, new_diffArguments);
        end if;
      then derivative_ptr;
    end match;
  end differentiateEquationPointer;

  function differentiateEquation
    input output Equation eq;
    input output DifferentiationArguments diffArguments;
    input String name = "";
  algorithm
    if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) and not stringEqual(name, "") then
      print("### debugDifferentiation | " + name + " ###\n");
      print("[BEFORE] " + Equation.toString(eq) + "\n");
    end if;
    (eq, diffArguments) := match eq
      local
        Equation res;
        Expression lhs, rhs;
        ComponentRef lhs_cref, rhs_cref;
        list<Equation> forBody = {};
        IfEquationBody ifBody;
        WhenEquationBody whenBody;
        Pointer<DifferentiationArguments> diffArguments_ptr;
        EquationAttributes attr;
        Algorithm alg;

      // ToDo: Element source stuff (see old backend)
      case Equation.SCALAR_EQUATION() algorithm
        (lhs, diffArguments) := differentiateExpression(eq.lhs, diffArguments);
        (rhs, diffArguments) := differentiateExpression(eq.rhs, diffArguments);
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.SCALAR_EQUATION(eq.ty, lhs, rhs, eq.source, attr), diffArguments);

      case Equation.ARRAY_EQUATION() algorithm
        (lhs, diffArguments) := differentiateExpression(eq.lhs, diffArguments);
        (rhs, diffArguments) := differentiateExpression(eq.rhs, diffArguments);
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.ARRAY_EQUATION(eq.ty, lhs, rhs, eq.source, attr, eq.recordSize), diffArguments);

      case Equation.RECORD_EQUATION() algorithm
        (lhs, diffArguments) := differentiateExpression(eq.lhs, diffArguments);
        (rhs, diffArguments) := differentiateExpression(eq.rhs, diffArguments);
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.RECORD_EQUATION(eq.ty, lhs, rhs, eq.source, attr, eq.recordSize), diffArguments);

      case Equation.IF_EQUATION() algorithm
        (ifBody, diffArguments_ptr) := differentiateIfEquationBody(eq.body, Pointer.create(diffArguments));
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.IF_EQUATION(eq.size, ifBody, eq.source, attr), Pointer.access(diffArguments_ptr));

      case Equation.FOR_EQUATION() algorithm
        for body_eqn in eq.body loop
          (body_eqn, diffArguments) := differentiateEquation(body_eqn, diffArguments);
          forBody := body_eqn :: forBody;
        end for;
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.FOR_EQUATION(eq.size, eq.iter, listReverse(forBody), eq.source, attr), diffArguments);

      case Equation.WHEN_EQUATION() algorithm
        (whenBody, diffArguments) := differentiateWhenEquationBody(eq.body, diffArguments);
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.WHEN_EQUATION(eq.size, whenBody, eq.source, attr), diffArguments);

      case Equation.ALGORITHM() algorithm
        (alg, diffArguments) := differentiateAlgorithm(eq.alg, diffArguments);
      then (Equation.ALGORITHM(eq.size, alg, eq.source, eq.expand, eq.attr), diffArguments);

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Equation.toString(eq)});
      then fail();

    end match;

/* ToDo
    record AUX_EQUATION
      "Auxiliary equations are generated when auxiliary variables are generated
      that are known to always be solved in this specific equation. E.G. $CSE
      The variable binding contains the equation, but this equation is also
      allowed to have a body for special cases."
      Pointer<Variable> auxiliary     "Corresponding auxiliary variable";
      Option<Equation> body           "Optional body equation"; // -> Expression
    end AUX_EQUATION;

    record DUMMY_EQUATION
    end DUMMY_EQUATION;

  */
    if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) and not stringEqual(name, "") then
      eq := Equation.simplify(eq, name, "\t");
      print("[AFTER ] " + Equation.toString(eq) + "\n\n");
    else
      eq := Equation.simplify(eq, name);
    end if;
  end differentiateEquation;

  function differentiateIfEquationBody
    input output IfEquationBody body;
    input output Pointer<DifferentiationArguments> diffArguments_ptr;
  protected
    list<Pointer<Equation>> then_eqns;
    IfEquationBody else_if;
  algorithm
    // ToDo: this is a little ugly
    // 1. why are the then_eqns Pointers? no need for that
    // 2. we could just traverse it regularly without creating a pointer for diffArguments
    then_eqns := List.map(body.then_eqns, function differentiateEquationPointer(diffArguments_ptr = diffArguments_ptr, name = ""));
    if isSome(body.else_if) then
      (else_if, diffArguments_ptr) := differentiateIfEquationBody(Util.getOption(body.else_if), diffArguments_ptr);
      body := IfEquationBody.IF_EQUATION_BODY(body.condition, then_eqns, SOME(else_if));
    else
      body := IfEquationBody.IF_EQUATION_BODY(body.condition, then_eqns, NONE());
    end if;
  end differentiateIfEquationBody;

  function differentiateWhenEquationBody
    input output WhenEquationBody body;
    input output DifferentiationArguments diffArguments;
  protected
    list<WhenStatement> when_stmts;
    WhenEquationBody else_when;
  algorithm
    (when_stmts, diffArguments) := List.mapFold(body.when_stmts, function differentiateWhenStatement(), diffArguments);
    if isSome(body.else_when) then
      (else_when, diffArguments) := differentiateWhenEquationBody(Util.getOption(body.else_when), diffArguments);
      body := WhenEquationBody.WHEN_EQUATION_BODY(body.condition, when_stmts, SOME(else_when));
    else
      body := WhenEquationBody.WHEN_EQUATION_BODY(body.condition, when_stmts, NONE());
    end if;
  end differentiateWhenEquationBody;

  function differentiateWhenStatement
    input output WhenStatement stmt;
    input output DifferentiationArguments diffArguments;
  algorithm
    (stmt, diffArguments) := match stmt
      local
        Expression lhs, rhs;
      // Only differentiate assignments
      case WhenStatement.ASSIGN() algorithm
        (lhs, diffArguments) := differentiateExpression(stmt.lhs, diffArguments);
        (rhs, diffArguments) := differentiateExpression(stmt.rhs, diffArguments);
      then (WhenStatement.ASSIGN(lhs, rhs, stmt.source), diffArguments);
      else (stmt, diffArguments);
    end match;
  end differentiateWhenStatement;

  function differentiateExpressionDump
    "wrapper function for differentiation to allow dumping before and afterwards"
    input output Expression exp;
    input output DifferentiationArguments diffArguments;
    input String name = "";
    input String indent = "";
  algorithm
    if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
      print(indent + "### debugDifferentiation | " + name + " ###\n");
      print(indent + "[BEFORE] " + Expression.toString(exp) + "\n");
      (exp, diffArguments) := differentiateExpression(exp, diffArguments);
      print(indent + "[AFTER ] " + Expression.toString(exp) + "\n\n");
    else
      (exp, diffArguments) := differentiateExpression(exp, diffArguments);
    end if;
  end differentiateExpressionDump;

  function differentiateExpression
    input output Expression exp;
    input output DifferentiationArguments diffArguments;
  algorithm
  (exp, diffArguments) := match exp
    local
      Expression elem1, elem2;
      list<Expression> new_elements = {};
      list<list<Expression>> new_matrix_elements = {};
      array<Expression> arr;

    // differentiation of constant expressions results in zero
    case Expression.INTEGER()   then (Expression.INTEGER(0), diffArguments);
    case Expression.REAL()      then (Expression.REAL(0.0), diffArguments);
    // leave boolean and string expressions as is
    case Expression.STRING()    then (exp, diffArguments);
    case Expression.BOOLEAN()   then (exp, diffArguments);

    // differentiate cref
    case Expression.CREF() then differentiateComponentRef(exp, diffArguments);

    // [a, b, c, ...]' = [a', b', c', ...]
    case Expression.ARRAY() algorithm
      (arr, diffArguments) := Array.mapFold(exp.elements, differentiateExpression, diffArguments);
      exp.elements := arr;
    then (exp, diffArguments);

    // |a, b, c|'   |a', b', c'|
    // |d, e, f|  = |d', e', f'|
    // |g, h, i|    |g', h', i'|
    case Expression.MATRIX() algorithm
      for element_lst in exp.elements loop
        new_elements := {};
        for element in element_lst loop
          (element, diffArguments) := differentiateExpression(element, diffArguments);
          new_elements := element :: new_elements;
        end for;
        new_matrix_elements := listReverse(new_elements) :: new_matrix_elements;
      end for;
    then (Expression.MATRIX(listReverse(new_matrix_elements)), diffArguments);

    // (a, b, c, ...)' = (a', b', c', ...)
    case Expression.TUPLE() algorithm
      for element in exp.elements loop
        (element, diffArguments) := differentiateExpression(element, diffArguments);
        new_elements := element :: new_elements;
      end for;
    then (Expression.TUPLE(exp.ty, listReverse(new_elements)), diffArguments);

    // REC(a, b, c, ...)' = REC(a', b', c', ...)
    case Expression.RECORD() algorithm
      for element in exp.elements loop
        (element, diffArguments) := differentiateExpression(element, diffArguments);
        new_elements := element :: new_elements;
      end for;
    then (Expression.RECORD(exp.path, exp.ty, listReverse(new_elements)), diffArguments);

    case Expression.CALL() then differentiateCall(exp, diffArguments);

    // (if c then a else b)' = if c then a' else b'
    case Expression.IF() algorithm
      (elem1, diffArguments) := differentiateExpression(exp.trueBranch, diffArguments);
      (elem2, diffArguments) := differentiateExpression(exp.falseBranch, diffArguments);
    then (Expression.IF(exp.ty, exp.condition, elem1, elem2), diffArguments);

    // e.g. (fg)' = fg' + f'g (more rules in differentiateBinary)
    case Expression.BINARY() then differentiateBinary(exp, diffArguments);

    // e.g. (fgh)' = f'gh + fg'h + fgh' (more rules in differentiateMultary)
    case Expression.MULTARY() then differentiateMultary(exp, diffArguments);

    // (-x)' = -(x')
    case Expression.UNARY() algorithm
      (elem1, diffArguments) := differentiateExpression(exp.exp, diffArguments);
    then (Expression.UNARY(exp.operator, elem1), diffArguments);

    // ((Real) x)' = (Real) x'
    case Expression.CAST() algorithm
      (elem1, diffArguments) := differentiateExpression(exp.exp, diffArguments);
    then (Expression.CAST(exp.ty, elem1), diffArguments);

    // BOX(x)' = BOX(x')
    case Expression.BOX() algorithm
      (elem1, diffArguments) := differentiateExpression(exp.exp, diffArguments);
    then (Expression.BOX(elem1), diffArguments);

    // UNBOX(x)' = UNBOX(x')
    case Expression.UNBOX() algorithm
      (elem1, diffArguments) := differentiateExpression(exp.exp, diffArguments);
    then (Expression.UNBOX(elem1, exp.ty), diffArguments);

    // (x(1))' = x'(1)
    case Expression.SUBSCRIPTED_EXP() algorithm
      (elem1, diffArguments) := differentiateExpression(exp.exp, diffArguments);
    then (Expression.SUBSCRIPTED_EXP(elem1, exp.subscripts, exp.ty, exp.split), diffArguments);

    // (..., a_i,...)' = (..., a'_i, ...)
    case Expression.TUPLE_ELEMENT() algorithm
      (elem1, diffArguments) := differentiateExpression(exp.tupleExp, diffArguments);
    then (Expression.TUPLE_ELEMENT(elem1, exp.index, exp.ty), diffArguments);

    // REC(i, ...)' = REC(i', ...)
    // ToDo: does this suffice? Check with old backend RSUB()!
    case Expression.RECORD_ELEMENT() algorithm
      (elem1, diffArguments) := differentiateExpression(exp.recordExp, diffArguments);
    then (Expression.RECORD_ELEMENT(elem1, exp.index, exp.fieldName, exp.ty), diffArguments);

    // Binary expressions, conditions and placeholders are not differentiated and left as they are
    case Expression.LBINARY()       then (exp, diffArguments);
    case Expression.LUNARY()        then (exp, diffArguments);
    case Expression.RELATION()      then (exp, diffArguments);
    case Expression.SIZE()          then (exp, diffArguments);
    case Expression.RANGE()         then (exp, diffArguments);
    case Expression.END()           then (exp, diffArguments);
    case Expression.EMPTY()         then (exp, diffArguments);
    case Expression.ENUM_LITERAL()  then (exp, diffArguments);
    case Expression.TYPENAME()      then (exp, diffArguments);

    else algorithm
      // maybe add failtrace here and allow failing
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp)});
    then fail();
  end match;

/* ToDo:

  record PARTIAL_FUNCTION_APPLICATION
    ComponentRef fn;
    list<Expression> args;
    list<String> argNames;
    Type ty;
  end PARTIAL_FUNCTION_APPLICATION;

  */
  end differentiateExpression;

  function differentiateComponentRef
    input output Expression exp "Has to be Expression.CREF()";
    input output DifferentiationArguments diffArguments;
  protected
    Pointer<Variable> var_ptr, der_ptr;
    ComponentRef derCref, strippedCref;
  algorithm
    // extract var pointer first to have following code more readable
    var_ptr := match exp
      // function body expressions, empty and wild crefs are not lowered (maybe do it?)
      case _ guard(diffArguments.diffType == DifferentiationType.FUNCTION) then Pointer.create(NBVariable.DUMMY_VARIABLE);
      case Expression.CREF(cref = ComponentRef.EMPTY()) then Pointer.create(NBVariable.DUMMY_VARIABLE);
      case Expression.CREF(cref = ComponentRef.WILD())  then Pointer.create(NBVariable.DUMMY_VARIABLE);
      case Expression.CREF() then BVariable.getVarPointer(exp.cref);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp)});
      then fail();
    end match;

    (exp, diffArguments) := match (exp, diffArguments.diffType, diffArguments.jacobianHT)
      local
        Expression res;
        UnorderedMap<ComponentRef,ComponentRef> jacobianHT;

      // -------------------------------------
      //    EMPTY and WILD crefs do nothing
      // -------------------------------------
      case (Expression.CREF(cref = ComponentRef.EMPTY()), _, _) then (exp, diffArguments);
      case (Expression.CREF(cref = ComponentRef.WILD()), _, _)  then (exp, diffArguments);

      // -------------------------------------
      //    Special rules for Type: FUNCTION
      //    (needs to be first because var_ptr is DUMMY)
      // -------------------------------------

      // Types: (FUNCTION)
      // Any variable that is in the HT will be differentiated accordingly. 0 otherwise
      case (Expression.CREF(), DifferentiationType.FUNCTION, SOME(jacobianHT)) algorithm
        strippedCref := ComponentRef.stripSubscriptsAll(exp.cref);
        if UnorderedMap.contains(strippedCref, jacobianHT) then
          // get the derivative and reapply subscripts
          derCref := UnorderedMap.getOrFail(strippedCref, jacobianHT);
          derCref := ComponentRef.mergeSubscripts(ComponentRef.subscriptsAllFlat(exp.cref), derCref);
          res     := Expression.fromCref(derCref);
        else
          res     := Expression.makeZero(exp.ty);
        end if;
      then (res, diffArguments);

      // -------------------------------------
      //    Generic Rules
      // -------------------------------------

      // Types: (TIME)
      // differentiate time cref => 1
      case (Expression.CREF(), DifferentiationType.TIME, _)
        guard(ComponentRef.isTime(exp.cref))
      then (Expression.makeOne(exp.ty), diffArguments);

      // Types: not (TIME)
      // differentiate time cref => 0
      case (Expression.CREF(), _, _)
        guard(ComponentRef.isTime(exp.cref))
      then (Expression.makeZero(exp.ty), diffArguments);

      // Types: (ALL)
      // differentiate start cref => 0
      case (Expression.CREF(), _, _)
        guard(BVariable.isStart(var_ptr))
      then (Expression.makeZero(exp.ty), diffArguments);

      // ToDo: Records, Arrays, WILD (?)

      // Types: (SIMPLE)
      //  D(x)/dx => 1
      case (Expression.CREF(), DifferentiationType.SIMPLE, _)
        guard(ComponentRef.isEqual(exp.cref, diffArguments.diffCref))
      then (Expression.makeOne(exp.ty), diffArguments);

      // Types: (SIMPLE)
      // D(y)/dx => 0
      case (Expression.CREF(), DifferentiationType.SIMPLE, _)
      then (Expression.makeZero(exp.ty), diffArguments);

      // Types: (ALL)
      // Known variables, except for top level inputs have a 0-derivative
      case (Expression.CREF(), _, _)
        guard(BVariable.isParamOrConst(var_ptr) and
              not (ComponentRef.isTopLevel(exp.cref) and BVariable.isInput(var_ptr)))
      then (Expression.makeZero(exp.ty), diffArguments);

      // -------------------------------------
      //    Special rules for Type: TIME
      // -------------------------------------

      // Types: (TIME)
      // D(discrete)/d(x) = 0
      case (Expression.CREF(), DifferentiationType.TIME, _)
        guard(BVariable.isDiscrete(var_ptr) or BVariable.isDiscreteState(var_ptr))
      then (Expression.makeZero(exp.ty), diffArguments);

      // Types: (TIME)
      // DUMMY_STATES => DUMMY_DER
      case (Expression.CREF(), DifferentiationType.TIME, _)
        guard(BVariable.isDummyState(var_ptr))
      then (Expression.fromCref(BVariable.getPartnerCref(exp.cref, BVariable.getVarDummyDer)), diffArguments);

      // Types: (TIME)
      // D(x)/dtime --> der(x) --> $DER.x
      // STATE => STATE_DER
      case (Expression.CREF(), DifferentiationType.TIME, _)
        guard(BVariable.isState(var_ptr))
      then (Expression.fromCref(BVariable.getPartnerCref(exp.cref, BVariable.getVarDer)), diffArguments);

      // Types: (TIME)
      // D(y)/dtime --> der(y) --> $DER.y
      // ALGEBRAIC => STATE_DER
      // make y a state and add new STATE_DER
      case (Expression.CREF(), DifferentiationType.TIME, _)
        guard(BVariable.isContinuous(var_ptr, false))
        algorithm
          // create derivative
          (derCref, der_ptr) := BVariable.makeDerVar(exp.cref);
          // add derivative to new_vars
          diffArguments.new_vars := der_ptr :: diffArguments.new_vars;
          // update algebraic variable to be a state
          BVariable.setStateDerivativeVar(var_ptr, der_ptr);
      then (Expression.fromCref(derCref), diffArguments);

      // -------------------------------------
      //    Special rules for Type: JACOBIAN
      // -------------------------------------

      // Types: (JACOBIAN)
      // cref in jacobianHT => get $SEED or $pDER variable from hash table
      case (Expression.CREF(), DifferentiationType.JACOBIAN, SOME(jacobianHT))
        guard(diffArguments.scalarized)
      algorithm
        if UnorderedMap.contains(exp.cref, jacobianHT) then
          res := Expression.fromCref(UnorderedMap.getOrFail(exp.cref, jacobianHT));
        else
          // Everything that is not in jacobianHT gets differentiated to zero
          res := Expression.makeZero(exp.ty);
        end if;
      then (res, diffArguments);

      // Types: (JACOBIAN)
      // cref in jacobianHT => get $SEED or $pDER variable from hash table
      case (Expression.CREF(), DifferentiationType.JACOBIAN, SOME(jacobianHT))
        guard(not diffArguments.scalarized)
      algorithm
        strippedCref := ComponentRef.stripSubscriptsAll(exp.cref);
        if UnorderedMap.contains(strippedCref, jacobianHT) then
          // get the derivative an reapply subscripts
          derCref := UnorderedMap.getOrFail(strippedCref, jacobianHT);
          derCref := ComponentRef.mergeSubscripts(ComponentRef.subscriptsAllFlat(exp.cref), derCref);
          res     := Expression.fromCref(derCref);
        else
          res     := Expression.makeZero(exp.ty);
        end if;
      then (res, diffArguments);

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp)});
      then fail();

    end match;
  end differentiateComponentRef;

  function differentiateVariablePointer
    input Pointer<Variable> var_ptr;
    input Pointer<DifferentiationArguments> diffArguments_ptr;
    output Pointer<Variable> diff_ptr;
  protected
    DifferentiationArguments diffArguments = Pointer.access(diffArguments_ptr);
    Variable var = Pointer.access(var_ptr);
    Expression crefExp;
  algorithm
    (crefExp, diffArguments) := differentiateComponentRef(Expression.fromCref(var.name), diffArguments);
    diff_ptr := match crefExp
      case Expression.CREF(cref = ComponentRef.EMPTY()) then Pointer.create(NBVariable.DUMMY_VARIABLE);
      case Expression.CREF(cref = ComponentRef.WILD())  then Pointer.create(NBVariable.DUMMY_VARIABLE);
      case Expression.CREF() then BVariable.getVarPointer(crefExp.cref);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + Variable.toString(var)
          + " because the result is expected to be a variable but turned out to be " + Expression.toString(crefExp) + "."});
      then fail();
    end match;
    Pointer.update(diffArguments_ptr, diffArguments);
  end differentiateVariablePointer;

  function differentiateCall
  "Differentiate builtin function calls
  1. if the function is builtin -> use hardcoded logic
  2. if the function is not builtin -> check if there is a 'fitting' derivative defined.
    - 'fitting' means that all the zeroDerivative annotations have to hold
    2.1 fitting function found -> use it
    2.2 fitting function not found -> differentiate the body of the function
  ToDo: respect the 'order' of the derivative when differentiating!"
    input output Expression exp "Has to be Expression.CALL()";
    input output DifferentiationArguments diffArguments;
  protected
    constant Boolean debug = false;
  algorithm
    if debug then
      print("\nDifferentiate Exp-Call: "+ Expression.toString(exp) + "\n");
    end if;

    (exp, diffArguments) := match exp
      local
        Expression ret;
        Call call, der_call;
        Option<Function> func_opt, der_func_opt;
        list<Function> derivatives;
        Function func, der_func;
        list<Expression> arguments = {};
        Operator addOp, mulOp;
        list<tuple<Expression, InstNode>> arguments_inputs;
        Expression arg;
        InstNode inp;
        Boolean isCont, isReal;
        // interface map. If the map contains a variable it has a zero derivative
        // if the value is "true" it has to be stripped from the interface
        // (it is possible that a variable has a zero derivative, but still appears in the interface)
        UnorderedMap<String, Boolean> interface_map = UnorderedMap.new<Boolean>(stringHashDjb2, stringEqual);

      // for reductions only differentiate the argument
      case Expression.CALL(call = call as Call.TYPED_REDUCTION()) algorithm
        (ret, diffArguments) := differentiateReduction(AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn)), exp, diffArguments);
      then (ret, diffArguments);

      // builtin functions
      case Expression.CALL(call = call as Call.TYPED_CALL()) guard(Function.isBuiltin(call.fn)) algorithm
        (ret, diffArguments) := differentiateBuiltinCall(AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn)), exp, diffArguments);
      then (ret, diffArguments);

      // user defined functions
      case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        func_opt := FunctionTreeImpl.getOpt(diffArguments.funcTree, call.fn.path);
        if Util.isSome(func_opt) then
          // The function is in the function tree
          SOME(func) := func_opt;

          // build interface map to check if a function fits
          // save all inputs that would end up in a zero derivative in a map
          arguments_inputs := List.zip(call.arguments, func.inputs);
          for tpl in arguments_inputs loop
            (arg, inp) := tpl;
            // do not check for continuous if it is for functions (differentiating a function inside a function)
            // crefs are not lowered there! assume it is continuous
            isCont := (diffArguments.diffType == DifferentiationType.FUNCTION) or BackendUtil.isContinuous(arg, false);
            isReal := Type.isReal(Type.arrayElementType(Expression.typeOf(arg))); // ToDo also records
            if not (isCont and isReal) then
              // add to map; if it is not Real also already set to true (always removed from interface)
              UnorderedMap.add(InstNode.name(inp), not isReal, interface_map);
            end if;
          end for;

          // try to get a fitting function from derivatives -> if none is found, differentiate
          der_func_opt := Function.getDerivative(func, interface_map);
          if Util.isSome(der_func_opt) then
            SOME(der_func) := der_func_opt;
          else
            (der_func, diffArguments) := differentiateFunction(func, interface_map, diffArguments);
          end if;

          for tpl in listReverse(arguments_inputs) loop
            (arg, inp) := tpl;
            // only keep the arguments which are not in the map or have value false
            if not UnorderedMap.getOrDefault(InstNode.name(inp), interface_map, false) then
              arguments := arg :: arguments;
            end if;
          end for;

          // differentiate type arguments and append to original ones
          (arguments, diffArguments) := List.mapFold(arguments, differentiateExpression, diffArguments);
          arguments := listAppend(call.arguments, arguments);

          ret := Expression.CALL(Call.makeTypedCall(der_func, arguments, call.var, call.purity));
        else
          // The function is not in the function tree and not builtin -> error
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
            + " failed because the function is not a builtin function and could not be found in the function tree: "
            + Expression.toString(exp)});
          fail();
        end if;
      then (ret, diffArguments);

      // If the call was not typed correctly by the frontend
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp)});
      then fail();
    end match;

    if debug then
      print("Differentiate-ExpCall-result: " + Expression.toString(exp) + "\n");
    end if;
  end differentiateCall;

  function differentiateReduction
    "This function differentiates reduction expressions with respect to a given variable.
    Also creates and multiplies inner derivatives."
    input String name;
    input output Expression exp;
    input output DifferentiationArguments diffArguments;
  algorithm
    exp := match exp
      local
        Call call;
        Expression arg;

      case Expression.CALL(call = call as Call.TYPED_REDUCTION()) guard(name == "sum") algorithm
        (arg, diffArguments) := differentiateExpression(call.exp, diffArguments);
        call.exp := arg;
        exp.call := call;
      then exp;

      // ToDo: product, min, max

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of non-call expression: " + Expression.toString(exp)});
      then fail();
    end match;
  end differentiateReduction;

  function differentiateBuiltinCall
    "This function differentiates built-in call expressions with respect to a given variable.
    Also creates and multiplies inner derivatives."
    input String name;
    input output Expression exp;
    input output DifferentiationArguments diffArguments;
  protected
    // these need to be adapted to size and type of exp
    Operator.SizeClassification sizeClass = NFOperator.SizeClassification.SCALAR;
    Operator addOp = Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), Type.REAL());
    Operator mulOp = Operator.fromClassification((NFOperator.MathClassification.MULTIPLICATION, sizeClass), Type.REAL());
  algorithm
    exp := match (exp)
      local
        Integer i;
        Expression ret, ret1, ret2, arg1, arg2, arg3, diffArg1, diffArg2, diffArg3;
        list<Expression> rest;
        Type ty;
        DifferentiationType diffType;

      // d/dz delay(x, delta) = (dt/dz - d delta/dz) * delay(der(x), delta)
      case (Expression.CALL()) guard(name == "delay")
      algorithm
        (arg1, arg2, arg3) := match Call.arguments(exp.call)
          case {arg1, arg2, arg3} then (arg1, arg2, arg3);
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
          then fail();
        end match;
        // if z = t then dt/dz = 1 else dt/dz = 0
        ret1 := Expression.REAL(if diffArguments.diffType == DifferentiationType.TIME then 1.0 else 0.0);
        // d delta/dz
        (ret2, diffArguments) := differentiateExpression(arg2, diffArguments);
        // dt/dz - d delta/dz
        ret2 := SimplifyExp.simplifyDump(Expression.MULTARY({ret1}, {ret2}, addOp), true, getInstanceName());
        if Expression.isZero(ret2) then
          ret := Expression.makeZero(Expression.typeOf(arg1));
        else
          diffType := diffArguments.diffType;
          diffArguments.diffType := DifferentiationType.TIME;
          (ret1, diffArguments) := differentiateExpression(arg1, diffArguments);
          diffArguments.diffType := diffType;
          exp.call := Call.setArguments(exp.call, {ret1, arg2, arg3});
          ret := Expression.MULTARY({ret2, exp}, {}, mulOp);
        end if;
      then ret;

      // SMOOTH
      case (Expression.CALL()) guard(name == "smooth")
      algorithm
        ret := match Call.arguments(exp.call)
          case {arg1 as Expression.INTEGER(i), arg2} guard(i > 0) algorithm
            (ret2, diffArguments) := differentiateExpression(arg2, diffArguments);
            exp.call := Call.setArguments(exp.call, {Expression.INTEGER(i-1), ret2});
          then exp;
          case {arg1 as Expression.INTEGER(i), arg2} algorithm
            (ret2, diffArguments) := differentiateExpression(arg2, diffArguments);
            exp := Expression.CALL(Call.makeTypedCall(
              fn          = NFBuiltinFuncs.NO_EVENT,
              args        = {ret2},
              variability = Expression.variability(ret2),
              purity      = NFPrefixes.Purity.PURE
            ));
          then exp;
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
          then fail();
        end match;
      then ret;

      // Functions with one argument that differentiate "through"
      // d/dz f(x) -> f(dx/dz)
      case (Expression.CALL()) guard(List.contains({"sum", "pre", "noEvent"}, name, stringEqual))
      algorithm
        arg1 := match Call.arguments(exp.call)
          case {arg1} then arg1;
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
          then fail();
        end match;
        (ret1, diffArguments) := differentiateExpression(arg1, diffArguments);
        exp.call := Call.setArguments(exp.call, {ret1});
      then exp;

      // Functions with two arguments that differentiate "through"
      // df(x,y)/dz = f(dx/dz, dy/dz)
      case (Expression.CALL()) guard(List.contains({"homotopy", "$OMC$inStreamDiv"}, name, stringEqual))
      algorithm
        (arg1, arg2) := match Call.arguments(exp.call)
          case {arg1, arg2} then (arg1, arg2);
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
          then fail();
        end match;
        (ret1, diffArguments) := differentiateExpression(arg1, diffArguments);
        (ret2, diffArguments) := differentiateExpression(arg2, diffArguments);
        exp.call := Call.setArguments(exp.call, {ret1, ret2});
      then exp;

      // FILL
      case (Expression.CALL()) guard(name == "fill")
      algorithm
        // only differentiate 1st input
        arg1 :: rest := Call.arguments(exp.call);
        (ret1, diffArguments) := differentiateExpression(arg1, diffArguments);
        exp.call := Call.setArguments(exp.call, ret1 :: rest);
      then exp;

      // SEMI LINEAR
      // d sL(x, m1, m2)/dz = sL(x, dm1/dz, dm2/dz) + dx/dz * (if x >= 0 then m1 else m2)
      case (Expression.CALL()) guard(name == "semiLinear")
      algorithm
        (arg1, arg2, arg3) := match Call.arguments(exp.call)
          case {arg1, arg2, arg3} then (arg1, arg2, arg3);
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
          then fail();
        end match;

        // dx/dz, dm1/dz, dm2/dz
        (diffArg1, diffArguments) := differentiateExpression(arg1, diffArguments);
        (diffArg2, diffArguments) := differentiateExpression(arg2, diffArguments);
        (diffArg3, diffArguments) := differentiateExpression(arg3, diffArguments);

        // sL(x, dm1/dz, dm2/dz)
        exp.call := Call.setArguments(exp.call, {arg1, diffArg2, diffArg3});
        ret := exp;

        // only add second part if dx/dz is nonzero
        if not Expression.isZero(diffArg1) then
          ty    := Expression.typeOf(diffArg1);
          // x >= 0
          ret1  := Expression.RELATION(arg1, Operator.makeGreaterEq(ty), Expression.makeZero(ty), -1);
          // if x >= 0 then m1 else m2
          ret1  := Expression.IF(ty, ret1, arg2, arg3);
          // dx/dz * (if x >= 0 then m1 else m2)
          ret2  := Expression.MULTARY({diffArg1, ret1}, {}, mulOp);
          // sL(x, dm1/dz, dm2/dz) + dx/dz * (if x >= 0 then m1 else m2)
          ret   := Expression.MULTARY({ret, ret2}, {}, addOp);
        end if;
      then ret;

      // d/dz min(x,y) = if x < y then dx/dz else dy/dz
      // d/dz max(x,y) = if x > y then dx/dz else dy/dz
      // FIXME at x = y the derivative may not be well-defined
      case (Expression.CALL()) guard(name == "min" or name == "max")
      algorithm
        (arg1, arg2) := match Call.arguments(exp.call)
          case {arg1, arg2} then (arg1, arg2);
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
          then fail();
        end match;

        // dx/dz, dy/dz
        (diffArg1, diffArguments) := differentiateExpression(arg1, diffArguments);
        (diffArg2, diffArguments) := differentiateExpression(arg2, diffArguments);

        ty := Expression.typeOf(diffArg1);
        if Expression.isZero(diffArg1) and Expression.isZero(diffArg2) then
          ret := Expression.makeZero(ty);
        else
          // condition x < y or x > y
          ret1 := Expression.RELATION(
            arg1,
            if name == "min" then Operator.makeLess(ty) else Operator.makeGreater(ty),
            arg2,
            -1);
          // if condition then dx/dz else dy/dz
          ret := Expression.IF(ty, ret1, diffArg1, diffArg2);
        end if;
      then ret;

      // Builtin function call with one argument
      // df(x)/dz = df/dx * dx/dz
      case (Expression.CALL()) guard List.hasOneElement(Call.arguments(exp.call))
      algorithm
        arg1 := match Call.arguments(exp.call)
          case {arg1} then arg1;
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
          then fail();
        end match;
        // differentiate the call df/dx
        ret := differentiateBuiltinCall1Arg(name, arg1);
        if not Expression.isZero(ret) then
          // differentiate the argument (inner derivative) dx/dz
          (diffArg1, diffArguments) := differentiateExpression(arg1, diffArguments);
          ret := Expression.MULTARY({ret, diffArg1}, {}, mulOp);
        end if;
      then ret;

      // Builtin function call with two arguments
      // df(x,y)/dz = df/dx * dx/dz + df/dy * dy/dz
      case (Expression.CALL()) guard(listLength(Call.arguments(exp.call)) == 2)
      algorithm
        (arg1, arg2) := match Call.arguments(exp.call)
          case {arg1, arg2} then (arg1, arg2);
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp) + "."});
          then fail();
        end match;
        // differentiate the call
        (ret1, ret2) := differentiateBuiltinCall2Arg(name, arg1, arg2);             // df/dx and df/dy
        (diffArg1, diffArguments) := differentiateExpression(arg1, diffArguments);  // dx/dz
        (diffArg2, diffArguments) := differentiateExpression(arg2, diffArguments);  // dy/dz
        ret1 := Expression.MULTARY({ret1, diffArg1}, {}, mulOp);                    // df/dx * dx/dz
        ret2 := Expression.MULTARY({ret2, diffArg2}, {}, mulOp);                    // df/dy * dy/dz
        ret := Expression.MULTARY({ret1,ret2}, {}, addOp);                          // df/dx * dx/dz + df/dy * dy/dz
      then ret;

      // try some simple known cases
      case (Expression.CALL()) algorithm
        ret := match Call.functionNameLast(exp.call)
          case "sample" then Expression.BOOLEAN(false);
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp)});
          then fail();
        end match;
      then ret;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of non-call expression: " + Expression.toString(exp)});
        then fail();
    end match;
  end differentiateBuiltinCall;

  function differentiateBuiltinCall1Arg
    "differentiate a builtin call with one argument."
    input String name;
    input Expression arg;
    output Expression derFuncCall;
  protected
    // these probably need to be adapted to the size and type of arg
    Operator.SizeClassification sizeClass = NFOperator.SizeClassification.SCALAR;
    Operator powOp = Operator.fromClassification((NFOperator.MathClassification.POWER, sizeClass), Type.REAL());
    Operator addOp = Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), Type.REAL());
    Operator mulOp = Operator.fromClassification((NFOperator.MathClassification.MULTIPLICATION, sizeClass), Type.REAL());
  algorithm
    derFuncCall := match (name)
      local
        Expression ret;

      // all these have integer values and therefore zero derivative
      case ("sign")     then Expression.INTEGER(0);
      case ("ceil")     then Expression.REAL(0.0);
      case ("floor")    then Expression.REAL(0.0);
      case ("integer")  then Expression.INTEGER(0);

      // abs(arg) -> sign(arg)
      case ("abs") then Expression.CAST(
        Expression.typeOf(arg),
        Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.SIGN,
          args        = {arg},
          variability = Expression.variability(arg),
          purity      = NFPrefixes.Purity.PURE
        )));

      // sqrt(arg) -> 0.5/arg^(0.5)
      case ("sqrt") algorithm
        ret := Expression.BINARY(arg, powOp, Expression.REAL(0.5));       // arg^0.5
        ret := Expression.MULTARY({Expression.REAL(0.5)}, {ret}, mulOp);  // 1/(2*arg^0.5)
      then ret;

      // sin(arg) -> cos(arg)
      case ("sin") then Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.COS_REAL,
          args        = {arg},
          variability = Expression.variability(arg),
          purity      = NFPrefixes.Purity.PURE
        ));

      // cos(arg) -> -sin(arg)
      case ("cos") then Expression.negate(Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.SIN_REAL,
          args        = {arg},
          variability = Expression.variability(arg),
          purity      = NFPrefixes.Purity.PURE
        )));

      // tan(arg) -> 1/cos(arg)^2
      // kabdelhak: ToDo - investigate numerical properties: 1+tan(arg)^2 maybe better?
      case ("tan") algorithm
        ret := Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.COS_REAL,
          args        = {arg},
          variability = Expression.variability(arg),
          purity      = NFPrefixes.Purity.PURE));                         // cos(arg)
        ret := Expression.BINARY(ret, powOp, Expression.REAL(2.0));       // cos(arg)^2
        ret := Expression.MULTARY({Expression.REAL(1.0)}, {ret}, mulOp);  // 1/cos(arg)^2
      then ret;

      // asin(arg) -> 1/sqrt(1-arg^2)
      case ("asin") algorithm
        ret := Expression.BINARY(arg, powOp, Expression.REAL(2.0));       // arg^2
        ret := Expression.MULTARY({Expression.REAL(1.0)}, {ret}, addOp);  // 1-arg^2
        ret := Expression.BINARY(ret, powOp, Expression.REAL(0.5));       // sqrt(1-arg^2)
        ret := Expression.MULTARY({Expression.REAL(1.0)}, {ret}, mulOp);  // 1/sqrt(1-arg^2)
      then ret;

      // acos(arg) -> -1/sqrt(1-arg^2)
      case ("acos") algorithm
        ret := Expression.BINARY(arg, powOp, Expression.REAL(2.0));       // arg^2
        ret := Expression.MULTARY({Expression.REAL(1.0)}, {ret}, addOp);  // 1-arg^2
        ret := Expression.BINARY(ret, powOp, Expression.REAL(0.5));       // sqrt(1-arg^2)
        ret := Expression.MULTARY({Expression.REAL(-1.0)}, {ret}, mulOp); // -1/sqrt(1-arg^2)
      then ret;

      // atan(arg) -> 1/(1+arg^2)
      case ("atan") algorithm
        ret := Expression.BINARY(arg, powOp, Expression.REAL(2.0));       // arg^2
        ret := Expression.MULTARY({Expression.REAL(1.0), ret}, {}, addOp);// 1+arg^2
        ret := Expression.MULTARY({Expression.REAL(1.0)}, {ret}, mulOp);  // 1/(1+arg^2)
      then ret;

      // sinh(arg) -> cosh(arg)
      case ("sinh") then Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.COSH_REAL,
          args        = {arg},
          variability = Expression.variability(arg),
          purity      = NFPrefixes.Purity.PURE
        ));

      // cosh(arg) -> sinh(arg)
      case ("cosh") then Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.SINH_REAL,
          args        = {arg},
          variability = Expression.variability(arg),
          purity      = NFPrefixes.Purity.PURE
        ));

      // tanh(arg) -> 1-tanh(arg)^2
      case ("tanh") algorithm
        ret := Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.TANH_REAL,
          args        = {arg},
          variability = Expression.variability(arg),
          purity      = NFPrefixes.Purity.PURE));                         // tanh(arg)
        ret := Expression.BINARY(ret, powOp, Expression.REAL(2.0));       // tanh(arg)^2
        ret := Expression.MULTARY({Expression.REAL(1.0)}, {ret}, addOp);  // 1-tanh(arg)^2
      then ret;

      // acosh(arg) -> 1/sqrt(arg^2-1)
      case ("acosh") algorithm
        ret := Expression.BINARY(arg, powOp, Expression.REAL(2.0));       // arg^2
        ret := Expression.MULTARY({ret}, {Expression.REAL(1.0)}, addOp);  // arg^2-1
        ret := Expression.BINARY(ret, powOp, Expression.REAL(0.5));       // sqrt(arg^2-1)
        ret := Expression.MULTARY({Expression.REAL(1.0)}, {ret}, mulOp);  // 1/sqrt(arg^2-1)
      then ret;

      // asinh(arg) -> 1/sqrt(arg^2+1)
      case ("asinh") algorithm
        ret := Expression.BINARY(arg, powOp, Expression.REAL(2.0));         // arg^2
        ret := Expression.MULTARY({ret, Expression.REAL(1.0)}, {}, addOp);  // arg^2+1
        ret := Expression.BINARY(ret, powOp, Expression.REAL(0.5));         // sqrt(arg^2+1)
        ret := Expression.MULTARY({Expression.REAL(1.0)}, {ret}, mulOp);    // 1/sqrt(arg^2+1)
      then ret;

      // atanh(arg) -> 1/(1-arg^2)
      case ("atanh") algorithm
        ret := Expression.BINARY(arg, powOp, Expression.REAL(2.0));       // arg^2
        ret := Expression.MULTARY({Expression.REAL(1.0)}, {ret}, addOp);  // 1-arg^2
        ret := Expression.MULTARY({Expression.REAL(1.0)}, {ret}, mulOp);  // 1/(1-arg^2)
      then ret;

      // exp(arg) -> exp(arg)
      case ("exp") then Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.EXP_REAL,
          args        = {arg},
          variability = Expression.variability(arg),
          purity      = NFPrefixes.Purity.PURE
        ));

      // log(arg) -> 1/arg
      case ("log") then Expression.MULTARY({Expression.REAL(1.0)}, {arg}, mulOp);

      // log10(arg) -> 1/(arg*log(10))
      case ("log10") algorithm
        ret := Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.LOG_REAL,
          args        = {Expression.REAL(10.0)},
          variability = Variability.CONSTANT,
          purity      = NFPrefixes.Purity.PURE));                             // log(10)
        ret := Expression.MULTARY({Expression.REAL(1.0)}, {arg, ret}, mulOp); // 1/(arg*log(10))
      then ret;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + name});
      then fail();
    end match;
  end differentiateBuiltinCall1Arg;

  function differentiateBuiltinCall2Arg
    "differentiate a builtin call with two arguments."
    input String name;
    input Expression arg1;
    input Expression arg2;
    output Expression derFuncCall1;
    output Expression derFuncCall2;
  protected
    // these probably need to be adapted to the size and type of arg
    Operator.SizeClassification sizeClass = NFOperator.SizeClassification.SCALAR;
    Operator powOp = Operator.fromClassification((NFOperator.MathClassification.POWER, sizeClass), Type.REAL());
    Operator addOp = Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), Type.REAL());
    Operator mulOp = Operator.fromClassification((NFOperator.MathClassification.MULTIPLICATION, sizeClass), Type.REAL());
  algorithm
    (derFuncCall1, derFuncCall2) := match (name)
      local
        Expression exp1, exp2, ret1, ret2;

      // div(arg1, arg2) truncates the fractional part of arg1/arg2 so it has discrete values
      // therefore it has zero derivative where it's defined
      case ("div") then (Expression.INTEGER(0), Expression.INTEGER(0));

      // d/darg1 mod(arg1, arg2) -> 1
      // d/darg2 mod(arg1, arg2) -> -floor(arg1/arg2)
      case ("mod") algorithm
        exp2 := Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.FLOOR,
          args        = {Expression.MULTARY({arg1}, {arg2}, mulOp)},          // arg1/arg2
          variability = Prefixes.variabilityMax(Expression.variability(arg1), Expression.variability(arg2)),
          purity      = NFPrefixes.Purity.PURE
        ));                                                                   // floor(arg1/arg2)
        ret2 := Expression.negate(exp2);                                      // -floor(arg1/arg2)
      then (Expression.REAL(1), ret2);

      // d/darg1 rem(arg1, arg2) -> 1
      // d/darg2 rem(arg1, arg2) -> -div(arg1, arg2)
      case ("rem") algorithm
        exp2 := Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.DIV_REAL,
          args        = {arg1, arg2},
          variability = Prefixes.variabilityMax(Expression.variability(arg1), Expression.variability(arg2)),
          purity      = NFPrefixes.Purity.PURE
        ));                                                                   // div(arg1, arg2)
        ret2 := Expression.negate(exp2);                                      // -div(arg1, arg2)
      then (Expression.REAL(1), ret2);

      // d/darg1 atan2(arg1, arg2) -> -arg2/(arg1^2+arg2^2)
      // d/darg2 atan2(arg1, arg2) ->  arg1/(arg1^2+arg2^2)
      case ("atan2") algorithm
        exp1 := Expression.BINARY(arg1, powOp, Expression.REAL(2.0));         // arg1^2
        exp2 := Expression.BINARY(arg2, powOp, Expression.REAL(2.0));         // arg2^2
        exp1 := Expression.MULTARY({exp1, exp2}, {}, addOp);                  // arg1^2+arg2^2
        ret1 := Expression.MULTARY({Expression.negate(arg2)}, {exp1}, mulOp); // -arg2/(arg1^2+arg2^2)
        ret2 := Expression.MULTARY({arg1}, {exp1}, mulOp);                    //  arg1/(arg1^2+arg2^2)
      then (ret1, ret2);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + name});
      then fail();
    end match;
  end differentiateBuiltinCall2Arg;

  function differentiateFunction
    input Function func;
    output Function der_func;
    input UnorderedMap<String, Boolean> interface_map;
    input output DifferentiationArguments diffArguments;
  algorithm
    der_func := match func
      local
        InstNode node;
        Pointer<Class> cls;
        Class new_cls;
        DifferentiationArguments funcDiffArgs;
        UnorderedMap<ComponentRef, ComponentRef> diff_map = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
        Sections sections;
        list<Algorithm> algorithms;
        Absyn.Path new_path;
        FunctionDerivative funcDer;
        Function dummy_func;
        CachedData cachedData;
        String der_func_name;
        list<InstNode> local_outputs;

      case der_func as Function.FUNCTION(node = node as InstNode.CLASS_NODE(cls = cls)) algorithm
        new_cls := match Pointer.access(cls)
          case new_cls as Class.INSTANCED_CLASS(sections = sections as Sections.SECTIONS()) algorithm
            // prepare outputs that become locals
            local_outputs     := list(InstNode.setComponentDirection(NFPrefixes.Direction.NONE, node) for node in der_func.outputs);
            local_outputs     := list(InstNode.protect(node) for node in local_outputs);

            // prepare differentiation arguments
            funcDiffArgs              := DifferentiationArguments.default();
            funcDiffArgs.diffType     := DifferentiationType.FUNCTION;
            funcDiffArgs.funcTree     := diffArguments.funcTree;
            createInterfaceDerivatives(der_func.inputs, interface_map, diff_map);
            createInterfaceDerivatives(der_func.locals, interface_map, diff_map);
            createInterfaceDerivatives(der_func.outputs, interface_map, diff_map);
            funcDiffArgs.jacobianHT   := SOME(diff_map);

            // differentiate interface arguments
            der_func.inputs   := differentiateFunctionInterfaceNodes(der_func.inputs, interface_map, diff_map, funcDiffArgs, true);
            der_func.locals   := differentiateFunctionInterfaceNodes(der_func.locals, interface_map, diff_map, funcDiffArgs, true);
            der_func.outputs  := differentiateFunctionInterfaceNodes(der_func.outputs, interface_map, diff_map, funcDiffArgs, false);

            der_func.locals   := listAppend(der_func.locals, local_outputs);

            // create "fake" function with correct interface to have the interface
            // in the case of recursive differentiation (e.g. function calls itself)
            dummy_func    := func;
            node.cls      := Pointer.create(new_cls);
            der_func_name := NBVariable.FUNCTION_DERIVATIVE_STR + intString(listLength(func.derivatives));
            node.name     := der_func_name + "." + node.name;
            // create "fake" function from new node (update cache to get correct derivative name)
            der_func.path := AbsynUtil.prefixPath(der_func_name, der_func.path);
            cachedData    := CachedData.FUNCTION({der_func}, true, false);
            der_func.node := InstNode.setFuncCache(node, cachedData);

            // create fake derivative
            funcDer := FunctionDerivative.FUNCTION_DER(
              derivativeFn          = der_func.node,
              derivedFn             = dummy_func.node,
              order                 = Expression.INTEGER(1),
              conditions            = {}, // possibly needs updating
              lowerOrderDerivatives = {}  // possibly needs updating
            );

            // add fake derivative to function tree
            dummy_func.derivatives  := funcDer :: dummy_func.derivatives;
            funcDiffArgs.funcTree   := FunctionTreeImpl.add(funcDiffArgs.funcTree, dummy_func.path, dummy_func, FunctionTreeImpl.addConflictReplace);

            // differentiate function statements
            (algorithms, funcDiffArgs) := List.mapFold(sections.algorithms, differentiateAlgorithm, funcDiffArgs);

            // add them to new node
            sections.algorithms   := algorithms;
            new_cls.sections      := sections;
            node.cls              := Pointer.create(new_cls);
            cachedData            := CachedData.FUNCTION({der_func}, true, false);
            der_func.node         := InstNode.setFuncCache(node, cachedData);
            der_func.derivatives  := {};
          then new_cls;

          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for class " + Class.toFlatString(Pointer.access(cls), func.node) + "."});
          then fail();
        end match;

        // add function to function tree
        diffArguments.funcTree := FunctionTreeImpl.add(diffArguments.funcTree, der_func.path, der_func);
        // add new function as derivative to original function
        funcDer := FunctionDerivative.FUNCTION_DER(
          derivativeFn          = der_func.node,
          derivedFn             = func.node,
          order                 = Expression.INTEGER(1),
          conditions            = {}, // possibly needs updating
          lowerOrderDerivatives = {}  // possibly needs updating
        );
        func.derivatives := List.appendElt(funcDer, func.derivatives);
        diffArguments.funcTree := FunctionTreeImpl.add(diffArguments.funcTree, func.path, func, FunctionTreeImpl.addConflictReplace);
      then der_func;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for uninstanced function " + Function.signatureString(func) + "."});
      then fail();
    end match;
    if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
      print("\n[BEFORE] " + Function.toFlatString(func) + "\n");
      print("\n[AFTER ] " + Function.toFlatString(der_func) + "\n\n");
    end if;
  end differentiateFunction;

  function differentiateFunctionInterfaceNodes
    "differentiates function interface nodes (inputs, outputs, locals) and
    adds them to the diff_map used for differentiation. Also returns the new
    interface node lists for the differentiated function.
    (outputs only have the differentiated and not the original interface nodes)"
    input output list<InstNode> interface_nodes;
    input UnorderedMap<String, Boolean> interface_map;
    input UnorderedMap<ComponentRef, ComponentRef> diff_map;
    input output DifferentiationArguments diffArgs;
    input Boolean keepOld;
  protected
    list<InstNode> new_nodes;
    ComponentRef cref, diff_cref;
    InstNode comp_node;
    Component comp;
    Binding binding;
  algorithm
    new_nodes := if keepOld then listReverse(interface_nodes) else {};
    interface_nodes := list(node for node guard(not UnorderedMap.contains(InstNode.name(node), interface_map)) in interface_nodes);
    for node in interface_nodes loop
      cref := ComponentRef.fromNode(node, InstNode.getType(node));
      diff_cref := UnorderedMap.getSafe(cref, diff_map, sourceInfo());
      diff_cref := match diff_cref
        case ComponentRef.CREF(node = comp_node as InstNode.COMPONENT_NODE()) algorithm
          // differentiate bindings
          comp := Pointer.access(comp_node.component);
          comp := match comp
            case comp as Component.COMPONENT() algorithm
              (binding, diffArgs) := differentiateBinding(comp.binding, diffArgs);
              comp.binding := binding;
            then comp;
            else comp;
          end match;
          comp_node.component := Pointer.create(comp);
          diff_cref.node := comp_node;
        then diff_cref;
        else diff_cref;
      end match;
      new_nodes := ComponentRef.node(diff_cref) :: new_nodes;
    end for;
    interface_nodes := listReverse(new_nodes);
  end differentiateFunctionInterfaceNodes;

  function createInterfaceDerivatives
    input list<InstNode> interface_nodes;
    input UnorderedMap<String, Boolean> interface_map;
    input UnorderedMap<ComponentRef, ComponentRef> diff_map;
  protected
    ComponentRef cref, diff_cref;
    list<InstNode> n;
  algorithm
    n := list(node for node guard(not UnorderedMap.contains(InstNode.name(node), interface_map)) in interface_nodes);
    for node in n loop
      cref := ComponentRef.fromNode(node, InstNode.getType(node));
      diff_cref := BVariable.makeFDerVar(cref);
      UnorderedMap.add(cref, diff_cref, diff_map);
    end for;
  end createInterfaceDerivatives;

  function resolvePartialDerivatives
    input output Function func;
    input output FunctionTree funcTree;
  protected
    Function der_func;
    InstNode node;
    Pointer<Class> cls, tmp_cls;
    Class new_cls, wrap_cls;
    Sections sections;
    UnorderedMap<ComponentRef, ComponentRef> diff_map = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedMap<String, Boolean> interface_map;
    DifferentiationArguments diffArgs = DifferentiationArguments.default();
    list<Algorithm> algorithms;
    CachedData cachedData;
    InstNode diffVar;
    ComponentRef diffCref;
    list<InstNode> local_outputs;
    Boolean changed = false;
  algorithm
    func := match func
      case der_func as Function.FUNCTION(node = InstNode.CLASS_NODE(cls = cls)) algorithm
        wrap_cls := Pointer.access(cls);
        new_cls := match wrap_cls
          case wrap_cls as Class.TYPED_DERIVED(baseClass = node as InstNode.CLASS_NODE(cls = tmp_cls)) algorithm
            new_cls :=  match Pointer.access(tmp_cls)
              case new_cls as Class.INSTANCED_CLASS(sections = sections as Sections.SECTIONS(algorithms = algorithms)) algorithm
                // prepare differentiation arguments
                diffArgs.diffType     := DifferentiationType.FUNCTION;
                diffArgs.funcTree     := funcTree;

                interface_map := UnorderedMap.fromLists(list(InstNode.name(var) for var in der_func.inputs), List.fill(false, listLength(der_func.inputs)), stringHashDjb2, stringEqual);

                // add all differentiated inputs to the interface map
                for var in List.getAtIndexLst(der_func.inputs, der_func.derivedInputs) loop
                  UnorderedMap.remove(InstNode.name(var), interface_map);

                  // prepare outputs that become locals
                  local_outputs     := list(InstNode.setComponentDirection(NFPrefixes.Direction.NONE, node) for node in der_func.outputs);
                  local_outputs     := list(InstNode.protect(node) for node in local_outputs);

                  // differentiate interface arguments
                  createInterfaceDerivatives({var}, interface_map, diff_map);
                  createInterfaceDerivatives(der_func.locals, interface_map, diff_map);
                  createInterfaceDerivatives(der_func.outputs, interface_map, diff_map);
                  diffArgs.jacobianHT   := SOME(diff_map);

                  der_func.locals   := differentiateFunctionInterfaceNodes(der_func.locals, interface_map, diff_map, diffArgs, true);
                  der_func.outputs  := differentiateFunctionInterfaceNodes(der_func.outputs, interface_map, diff_map, diffArgs, false);

                  diffCref          := UnorderedMap.getSafe(ComponentRef.fromNode(var, InstNode.getType(var)), diff_map, sourceInfo());
                  der_func.locals   := listAppend(der_func.locals, local_outputs);

                  // differentiate function statements
                  (algorithms, diffArgs) := List.mapFold(algorithms, differentiateAlgorithm, diffArgs);
                  algorithms := Algorithm.mapExpList(algorithms, function Replacements.single(old = Expression.fromCref(diffCref), new = Expression.makeOne(ComponentRef.getSubscriptedType(diffCref))));

                  UnorderedMap.add(InstNode.name(var), false, interface_map);
                end for;

                // add them to new node
                sections.algorithms     := algorithms;
                new_cls.sections        := sections;
                new_cls.ty              := wrap_cls.ty;
                new_cls.restriction     := wrap_cls.restriction;
                node.cls                := Pointer.create(new_cls);
                cachedData              := CachedData.FUNCTION({der_func}, true, false);
                der_func.node           := InstNode.setFuncCache(node, cachedData);
                der_func.derivatives    := {};
                der_func.derivedInputs  := {};

                changed := true;
              then new_cls;

              else wrap_cls;
            end match;
          then new_cls;
          else wrap_cls;
        end match;

        if changed then
          if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
            print("\n[BEFORE] " + Function.toFlatString(func) + "\n");
            print("\n[AFTER ] " + Function.toFlatString(der_func) + "\n\n");
          end if;
          funcTree := FunctionTreeImpl.add(funcTree, der_func.path, der_func, FunctionTreeImpl.addConflictReplace);
        end if;
      then der_func;

      else func;
    end match;
  end resolvePartialDerivatives;

  function differentiateAlgorithm
    input output Algorithm alg;
    input output DifferentiationArguments diffArguments;
  protected
    list<list<Statement>> statements;
    list<Statement> statements_flat;
    list<ComponentRef> inputs, outputs;
  algorithm
    (statements, diffArguments) := List.mapFold(alg.statements, differentiateStatement, diffArguments);
    statements_flat := List.flatten(statements);
    (inputs, outputs) := Algorithm.getInputsOutputs(statements_flat);
    alg := Algorithm.ALGORITHM(statements_flat, inputs, outputs, alg.scope, alg.source);
  end differentiateAlgorithm;

  function differentiateStatement
    input Statement stmt;
    output list<Statement> diff_stmts "two statements for 'Real' assignments (diff; original) and else one";
    input output DifferentiationArguments diffArguments;
  algorithm
    diff_stmts := match stmt
      local
        Statement diff_stmt;
        Expression exp, lhs, rhs;
        list<Statement> branch_stmts_flat;
        list<list<Statement>> branch_stmts;
        list<tuple<Expression, list<Statement>>> branches = {};

      // I. differentiate 'Real' assignment and return differentiated and original statement
      case diff_stmt as Statement.ASSIGNMENT() guard(Type.isReal(Type.arrayElementType(Expression.typeOf(diff_stmt.lhs)))) algorithm
        (lhs, diffArguments) := differentiateExpression(diff_stmt.lhs, diffArguments);
        (rhs, diffArguments) := differentiateExpression(diff_stmt.rhs, diffArguments);
        diff_stmt.lhs := lhs;
        diff_stmt.rhs := SimplifyExp.simplifyDump(rhs, true, getInstanceName());
      then {diff_stmt, stmt};

      // II. delegate differentiation to body and only return differentiated statement
      case diff_stmt as Statement.FOR() algorithm
        (branch_stmts, diffArguments) := List.mapFold(diff_stmt.body, differentiateStatement, diffArguments);
        diff_stmt.body := List.flatten(branch_stmts);
      then {diff_stmt};

      case diff_stmt as Statement.WHILE() algorithm
        (branch_stmts, diffArguments) := List.mapFold(diff_stmt.body, differentiateStatement, diffArguments);
        diff_stmt.body := List.flatten(branch_stmts);
      then {diff_stmt};

      case diff_stmt as Statement.FAILURE() algorithm
        (branch_stmts, diffArguments) := List.mapFold(diff_stmt.body, differentiateStatement, diffArguments);
        diff_stmt.body := List.flatten(branch_stmts);
      then {diff_stmt};

      case diff_stmt as Statement.IF() algorithm
        for branch in diff_stmt.branches loop
          (exp, branch_stmts_flat) := branch;
          (branch_stmts, diffArguments) := List.mapFold(branch_stmts_flat, differentiateStatement, diffArguments);
          branches := (exp, List.flatten(branch_stmts)) :: branches;
        end for;
        diff_stmt.branches := listReverse(branches);
      then {diff_stmt};

      case diff_stmt as Statement.WHEN() algorithm
        for branch in diff_stmt.branches loop
          (exp, branch_stmts_flat) := branch;
          (branch_stmts, diffArguments) := List.mapFold(branch_stmts_flat, differentiateStatement, diffArguments);
          branches := (exp, List.flatten(branch_stmts)) :: branches;
        end for;
        diff_stmt.branches := listReverse(branches);
      then {diff_stmt};

      // III. assignments of non-Real are not differentiated, as well as empty statements
      case Statement.ASSIGNMENT()           then {stmt};
      case Statement.FUNCTION_ARRAY_INIT()  then {stmt};
      case Statement.ASSERT()               then {stmt};
      case Statement.TERMINATE()            then {stmt};
      case Statement.NORETCALL()            then {stmt};
      case Statement.RETURN()               then {stmt};
      case Statement.BREAK()                then {stmt};

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:" + Statement.toString(stmt)});
      then fail();
    end match;
  end differentiateStatement;

  function differentiateBinary
    "Some of this is depcreated because of Expression.MULTARY().
    Will always try to convert to MULTARY whenever possible. (commutativity)"
    input output Expression exp "Has to be Expression.BINARY()";
    input output DifferentiationArguments diffArguments;
  algorithm
    (exp, diffArguments) := match exp
      local
        Expression exp1, exp2, diffExp1, diffExp2, e1, e2, e3, res;
        Operator operator, addOp, mulOp, powOp;
        Operator.SizeClassification sizeClass;

      // Addition calculations (ADD, ADD_EW, ...)
      // (f + g)' = f' + g'
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard(Operator.getMathClassification(operator) == NFOperator.MathClassification.ADDITION)
        algorithm
          (diffExp1, diffArguments) := differentiateExpression(exp1, diffArguments);
          (diffExp2, diffArguments) := differentiateExpression(exp2, diffArguments);
      then (Expression.MULTARY({diffExp1, diffExp2}, {}, operator), diffArguments);

      // Subtraction calculations (SUB, SUB_EW, ...)
      // (f - g)' = f' - g'
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard(Operator.getMathClassification(operator) == NFOperator.MathClassification.SUBTRACTION)
        algorithm
          (diffExp1, diffArguments) := differentiateExpression(exp1, diffArguments);
          (diffExp2, diffArguments) := differentiateExpression(exp2, diffArguments);
          // create addition operator from the size classification of original multiplication operator
          (_, sizeClass) := Operator.classify(operator);
          addOp := Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), operator.ty);
      then (Expression.MULTARY({diffExp1}, {diffExp2}, addOp), diffArguments);

      // Multiplication (MUL, MUL_EW, ...)
      // (f * g)' =  fg' + f'g
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard(Operator.getMathClassification(operator) == NFOperator.MathClassification.MULTIPLICATION)
        algorithm
          (diffExp1, diffArguments) := differentiateExpression(exp1, diffArguments);
          (diffExp2, diffArguments) := differentiateExpression(exp2, diffArguments);
          // create addition operator from the size classification of original multiplication operator
          (_, sizeClass) := Operator.classify(operator);
          addOp := Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), operator.ty);
      then (Expression.MULTARY(
              {Expression.BINARY(exp1, operator, diffExp2),
               Expression.BINARY(diffExp1, operator, exp2)},
              {},
              addOp
            ),
            diffArguments);

      // Division (DIV, DIV_EW, ...)
      // (f / g)' = (f'g - fg') / g^2
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard(Operator.getMathClassification(operator) == NFOperator.MathClassification.DIVISION)
        algorithm
          (diffExp1, diffArguments) := differentiateExpression(exp1, diffArguments);
          (diffExp2, diffArguments) := differentiateExpression(exp2, diffArguments);
          // create subtraction and multiplication operator from the size classification of original division operator
          (_, sizeClass) := Operator.classify(operator);
          addOp := Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), operator.ty);
          mulOp := Operator.fromClassification((NFOperator.MathClassification.MULTIPLICATION, sizeClass), operator.ty);
          powOp := Operator.fromClassification((NFOperator.MathClassification.POWER, sizeClass), operator.ty);
      then (Expression.MULTARY(
              {Expression.MULTARY(
                {Expression.BINARY(exp1, mulOp, diffExp2)},              // fg'
                {Expression.BINARY(diffExp1, mulOp, exp2)},              // - f'g
                addOp
              )},
              {Expression.BINARY(exp2, powOp, Expression.REAL(2.0))},           // / g^2
              mulOp
            ),
            diffArguments);

      // Power (POW, POW_EW, ...) with base zero
      // (0^r)' = 0
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard((Operator.getMathClassification(operator) == NFOperator.MathClassification.POWER) and
              Expression.isZero(exp1))
      then (Expression.makeZero(operator.ty), diffArguments);

      // Power (POW, POW_EW, ...) general case
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard((Operator.getMathClassification(operator) == NFOperator.MathClassification.POWER))
        algorithm
          (diffExp1, diffArguments) := differentiateExpression(exp1, diffArguments);
          (diffExp2, diffArguments) := differentiateExpression(exp2, diffArguments);
          diffExp1 := SimplifyExp.simplifyDump(diffExp1, true, getInstanceName());
          diffExp2 := SimplifyExp.simplifyDump(diffExp2, true, getInstanceName());
          (_, sizeClass) := Operator.classify(operator);
          mulOp := Operator.fromClassification((NFOperator.MathClassification.MULTIPLICATION, sizeClass), operator.ty);
          addOp := Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), operator.ty);

          res := match (Expression.isZero(diffExp1), Expression.isZero(diffExp2))
            // Power (POW, POW_EW, ...) with constant exponent and constant base
            // (r1^r2)' = 0
            case (true, true) then Expression.makeZero(operator.ty);
            // Power (POW, POW_EW, ...) with constant exponent
            // (x^r)' = r*(x^(r-1))*x'
            case (false, true) then Expression.MULTARY({exp2, Expression.BINARY(exp1, operator, minusOne(exp2, addOp)), diffExp1}, {}, mulOp);
            // Power (POW, POW_EW, ...) with constant base
            // (r^x)'  = r^x*ln(r)*x'
            case (true, false) then Expression.MULTARY({exp, expLog(exp1), diffExp2}, {}, mulOp);
            // Power (POW, POW_EW, ...) regular case
            // (x^y)' = x^(y-1) * (x*ln(x)*y'+(y*x'))
            else algorithm
              // x^(y-1)
              e1 := Expression.BINARY(exp1, operator, minusOne(exp2, addOp));
              // x * ln(x) * y'
              e2 := Expression.MULTARY({exp1, expLog(exp1), diffExp2}, {}, mulOp);
              // y * x'
              e3 := Expression.MULTARY({exp2, diffExp1}, {}, mulOp);
            then Expression.MULTARY({e1, Expression.MULTARY({e2, e3}, {}, addOp)}, {}, mulOp);
          end match;
      then (res, diffArguments);

      // Logical and Comparing operators => just return as is
      case Expression.BINARY(operator = operator)
        guard((Operator.getMathClassification(operator) == NFOperator.MathClassification.LOGICAL) or
              (Operator.getMathClassification(operator) == NFOperator.MathClassification.RELATION))
      then (exp, diffArguments);

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp)});
      then fail();

    end match;
    // simplify?
  end differentiateBinary;

  function differentiateMultary
    "Differentiates a multary expression. Expression.MULTARY()
    Note: these can only contain commutative operators"
    input output Expression exp "Has to be Expression.MULTARY()";
    input output DifferentiationArguments diffArguments;
  algorithm
    exp := match exp
      local
        Expression diff_arg, divisor, diff_enumerator, diff_divisor;
        list<Expression> arguments, new_arguments = {};
        list<Expression> inv_arguments, new_inv_arguments = {};
        list<Expression> diff_arguments, diff_inv_arguments;
        Operator operator, addOp, powOp;
        Operator.SizeClassification sizeClass;

      // Dash calculations (ADD, SUB, ADD_EW, SUB_EW, ...)
      // NOTE: Multary always contains ADDITION
      // (sum(f_i))' = sum(f_i')
      // e.g. (f + g + h - p - q)' = f' + g' + h' - p' - q'
      case Expression.MULTARY(arguments = arguments, inv_arguments = inv_arguments, operator = operator)
        guard(Operator.getMathClassification(operator) == NFOperator.MathClassification.ADDITION)
        algorithm
          for arg in listReverse(arguments) loop
            (diff_arg, diffArguments) := differentiateExpression(arg, diffArguments);
            new_arguments := diff_arg :: new_arguments;
          end for;
          for arg in listReverse(inv_arguments) loop
            (diff_arg, diffArguments) := differentiateExpression(arg, diffArguments);
            new_inv_arguments := diff_arg :: new_inv_arguments;
          end for;
      then Expression.MULTARY(new_arguments, new_inv_arguments, operator);

      // Dot calculations (MUL, DIV, MUL_EW, DIV_EW, ...)
      // NOTE: Multary always contains MULTIPLICATION
      // no inverse arguments so single product rule:
      // prod(f_i)) = sum((f_i)' * prod(f_k | k <> i))
      // e.g. (fgh)' = f'gh + fg'h + fgh'
      case Expression.MULTARY(arguments = arguments, inv_arguments = {}, operator = operator)
        guard(Operator.getMathClassification(operator) == NFOperator.MathClassification.MULTIPLICATION)
        algorithm
          // create addition operator
          (_, sizeClass) := Operator.classify(operator);
          addOp := Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), operator.ty);
          (new_arguments, diffArguments) := differentiateMultaryMultiplicationArgs(arguments, diffArguments, operator);
      then Expression.MULTARY(new_arguments, {}, addOp);

      // Dot calculations (MUL, DIV, MUL_EW, DIV_EW, ...)
      // NOTE: Multary always contains MULTIPLICATION
      // (prod(f_i)) / prod(g_j))'
      // makes use if single product rule:
      // prod(f_i)) = sum((f_i)' * prod(f_k | k <> i))
      // e.g. (abc)' = a'bc + ab'c + abc'
      // and binary division rule
      // (f / g)' = (f'g - g'f) / g^2
      case Expression.MULTARY(arguments = arguments, inv_arguments = inv_arguments, operator = operator)
        guard(Operator.getMathClassification(operator) == NFOperator.MathClassification.MULTIPLICATION)
        algorithm
          // create addition and power operator
          (_, sizeClass) := Operator.classify(operator);
          addOp := Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), operator.ty);
          powOp := Operator.fromClassification((NFOperator.MathClassification.POWER, sizeClass), operator.ty);
          // f'
          (diff_arguments, diffArguments) := differentiateMultaryMultiplicationArgs(arguments, diffArguments, operator);
          diff_enumerator := Expression.MULTARY(diff_arguments, {}, addOp);
          // g'
          (diff_inv_arguments, diffArguments) := differentiateMultaryMultiplicationArgs(inv_arguments, diffArguments, operator);
          diff_divisor := Expression.MULTARY(diff_inv_arguments, {}, addOp);
          // g
          divisor := Expression.MULTARY(inv_arguments, {}, operator);
      then Expression.MULTARY(
              {Expression.MULTARY(
                {Expression.MULTARY(diff_enumerator :: inv_arguments, {}, operator)},   // f'g
                {Expression.MULTARY(diff_divisor :: arguments, {}, operator)},          // -g'f
                addOp
              )},
              {Expression.BINARY(divisor, powOp, Expression.REAL(2.0))},
              operator
           );

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp)});
      then fail();
    end match;
  end differentiateMultary;

  function differentiateMultaryMultiplicationArgs
    "prod(f_i)) = sum((f_i)' * prod(f_k | k <> i))
    e.g. (fgh)' = f'gh + fg'h + fgh'"
    input list<Expression> arguments;
    output list<Expression> new_arguments = {};
    input output DifferentiationArguments diffArguments;
    input Operator operator;
  protected
    Expression diff_arg;
    Array<List<Expression>> diff_lists;
    Integer idx = 1;
  algorithm
    diff_lists := arrayCreate(listLength(arguments), {});
    for arg in arguments loop
      (diff_arg, diffArguments) := differentiateExpression(arg, diffArguments);
      for i in 1:arrayLength(diff_lists) loop
        diff_lists[i] := if i == idx then diff_arg :: diff_lists[i] else arg :: diff_lists[i];
      end for;
      idx := idx + 1;
    end for;
    for i in arrayLength(diff_lists):-1:1 loop
      new_arguments := Expression.MULTARY(listReverse(diff_lists[i]), {}, operator) :: new_arguments;
    end for;
  end differentiateMultaryMultiplicationArgs;

  function differentiateEquationAttributes
    "Differentiates the residual variable for diffType JACOBIAN, if it exists.
    The cref has to be saved in the jacobianHT for this to work.
    ToDo: needs to be adapted for torn/inner equations"
    input output EquationAttributes attr;
    input DifferentiationArguments diffArguments;
  algorithm
    attr := match (attr, diffArguments)
      local
        Pointer<Variable> residualVar, diffedResidualVar;
        UnorderedMap<ComponentRef,ComponentRef> jacobianHT;

      case (EquationAttributes.EQUATION_ATTRIBUTES(residualVar = SOME(residualVar)),
         DIFFERENTIATION_ARGUMENTS(jacobianHT = SOME(jacobianHT), diffType = DifferentiationType.JACOBIAN))
        guard(UnorderedMap.contains(BVariable.getVarName(residualVar), jacobianHT))
        algorithm
          diffedResidualVar := BVariable.getVarPointer(UnorderedMap.getOrFail(BVariable.getVarName(residualVar), jacobianHT));
          attr.residualVar := SOME(diffedResidualVar);
      then attr;

      else attr;

    end match;
  end differentiateEquationAttributes;

  function differentiateBinding
    input output Binding binding;
    input output DifferentiationArguments diffArgs;
  protected
    Option<Expression> opt_exp;
    Expression exp;
  algorithm
    opt_exp := Binding.getExpOpt(binding);
    if Util.isSome(opt_exp) then
      (exp, diffArgs) := differentiateExpression(Util.getOption(opt_exp), diffArgs);
      binding := Binding.setExp(exp, binding);
    end if;
  end differentiateBinding;

  protected
    function minusOne
      input output Expression exp;
      input Operator op;
    algorithm
      exp := match exp
        local
          Real r;
          Integer i;
        case Expression.REAL(value = r)         then Expression.REAL(r - 1.0);
        case Expression.INTEGER(value = i)      then Expression.INTEGER(i - 1);
        else Expression.MULTARY({exp}, {Expression.makeOne(op.ty)}, op);
      end match;
    end minusOne;

    function expLog
      input output Expression exp;
    algorithm
      exp := match exp
        local
          Real r;
          Integer i;
        case Expression.REAL(value = r)     then Expression.REAL(log(r));
        case Expression.INTEGER(value = i)  then Expression.REAL(log(i));
        else Expression.CALL(Call.makeTypedCall(
          fn          = NFBuiltinFuncs.LOG_REAL,
          args        = {exp},
          variability = Expression.variability(exp),
          purity      = NFPrefixes.Purity.PURE
        ));
      end match;
    end expLog;

  annotation(__OpenModelica_Interface="backend");
end NBDifferentiate;
