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
  import AvlSetPath;
  import DAE;

  // NF imports
  import BuiltinFuncs = NFBuiltinFuncs;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Function = NFFunction.Function;
  import FunctionTree = NFFlatten.FunctionTree;
  import Operator = NFOperator;
  import Type = NFType;
  import NFPrefixes.Variability;
  import Variable = NFVariable;

  // Backend imports
  import BVariable = NBVariable;
  import NBEquation.Equation;
  import NBEquation.EquationPointers;
  import NBEquation.EquationAttributes;
  import NBEquation.IfEquationBody;
  import NBEquation.WhenEquationBody;
  import NBEquation.WhenStatement;
  import HashTableCrToCr = NBHashTableCrToCr;

  // Util imports
  import Error;

  // ================================
  //        TYPES AND UNIONTYPES
  // ================================
  type DifferentiationType = enumeration(TIME, SIMPLE, FUNCTION, JACOBIAN);

  /* ToDo: is this whole differentiation data necessary with new HT approach? */
  uniontype DifferentiationData
    record DIFFERENTIATION_DATA
      Option<BVariable.VariablePointers> independenentVars "Independent variables";
      Option<BVariable.VariablePointers> dependenentVars   "Dependent variables";
      Option<BVariable.VariablePointers> knownVars         "known variables (e.g. parameter, constants, ...)";
      Option<BVariable.VariablePointers> allVars           "all variables";
      list<Variable> controlVars                           "variables to save control vars of for algorithm";
      list<ComponentRef> diffCrefs                         "all crefs to differentiate, needed for generic gradient";
      Option<HashTableCrToCr.HashTable> jacobianHT         "seed and temporary cref hashtable x --> $SEED.MATRIX.x, y --> $pDer.MATRIX.y";
      AvlSetPath.Tree diffedFunctions                      "current functions, to prevent recursive differentiation";
    end DIFFERENTIATION_DATA;
  end DifferentiationData;

  constant DifferentiationData EMPTY_DIFFERENTIATION_DATA = DIFFERENTIATION_DATA(NONE(),NONE(),NONE(),NONE(),{},{},NONE(),AvlSetPath.EMPTY());

  uniontype DifferentiationArguments
    record DIFFERENTIATION_ARGUMENTS
      ComponentRef diffCref                         "The input will be differentiated w.r.t. this cref.";
      //DifferentiationData diffData                "Contains information eg. independent, dependent, known variables";
      Option<HashTableCrToCr.HashTable> jacobianHT  "seed and temporary cref hashtable x --> $SEED.MATRIX.x, y --> $pDer.MATRIX.y";
      DifferentiationType diffType                  "Differentiation use case (time, simple, function, jacobian)";
      FunctionTree funcTree                         "Function tree containing all functions and their known derivatives";
      AvlSetPath.Tree diffedFunctions               "current functions, to prevent recursive differentiation";
    end DIFFERENTIATION_ARGUMENTS;
  end DifferentiationArguments;

  // ================================
  //             FUNCTIONS
  // ================================

  function differentiateEquationPointers
    "author: kabdelhak
    Differentiates an array of equations wrapped in pointers."
    input output EquationPointers equations;
    input output DifferentiationArguments diffArguments;
  protected
    Pointer<DifferentiationArguments> diffArguments_ptr = Pointer.create(diffArguments);
    list<Pointer<Equation>> diffed_eqn_lst;
  algorithm
    // don't use EquationPointers.map because that would manipulate original eqn pointers
    diffed_eqn_lst := List.map(EquationPointers.toList(equations), function differentiateEquationPointer(diffArguments_ptr = diffArguments_ptr));
    equations := EquationPointers.fromList(diffed_eqn_lst);
    diffArguments := Pointer.access(diffArguments_ptr);
  end differentiateEquationPointers;

  function differentiateEquationPointer
    input output Pointer<Equation> eq_ptr;
    input Pointer<DifferentiationArguments> diffArguments_ptr;
  protected
    Equation diffedEq;
    DifferentiationArguments old_diffArguments, new_diffArguments;
  algorithm
    old_diffArguments := Pointer.access(diffArguments_ptr);
    (diffedEq, new_diffArguments) := differentiateEquation(Pointer.access(eq_ptr), old_diffArguments);
    eq_ptr := Pointer.create(diffedEq);
    if not referenceEq(new_diffArguments, old_diffArguments) then
      Pointer.update(diffArguments_ptr, new_diffArguments);
    end if;
  end differentiateEquationPointer;

  function differentiateEquation
    input output Equation eq;
    input output DifferentiationArguments diffArguments;
  algorithm
    (eq, diffArguments) := match eq
      local
        Equation res;
        Expression lhs, rhs;
        ComponentRef lhs_cref, rhs_cref;
        IfEquationBody ifBody;
        WhenEquationBody whenBody;
        Pointer<DifferentiationArguments> diffArguments_ptr;
        EquationAttributes attr;

      // ToDo: Element source stuff (see old backend)
      case Equation.SCALAR_EQUATION() algorithm
        (lhs, diffArguments) := differentiateExpression(eq.lhs, diffArguments);
        (rhs, diffArguments) := differentiateExpression(eq.rhs, diffArguments);
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.SCALAR_EQUATION(lhs, rhs, eq.source, attr), diffArguments);

      case Equation.ARRAY_EQUATION() algorithm
        (lhs, diffArguments) := differentiateExpression(eq.lhs, diffArguments);
        (rhs, diffArguments) := differentiateExpression(eq.rhs, diffArguments);
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.ARRAY_EQUATION(eq.dimSize, lhs, rhs, eq.source, attr, eq.recordSize), diffArguments);

      case Equation.SIMPLE_EQUATION() algorithm
        (lhs, diffArguments) := differentiateComponentRef(Expression.fromCref(eq.lhs), diffArguments);
        (rhs, diffArguments) := differentiateComponentRef(Expression.fromCref(eq.rhs), diffArguments);
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
        res := match (lhs, rhs)
          // If both are still a componentRef, create simple equation.
          case (Expression.CREF(cref = lhs_cref), Expression.CREF(cref = rhs_cref))
          then Equation.SIMPLE_EQUATION(lhs_cref, rhs_cref, eq.source, attr);
          // else create regular equation: ToDo check array?
          else Equation.SCALAR_EQUATION(lhs, rhs, eq.source, attr);
        end match;
      then (res, diffArguments);

      case Equation.RECORD_EQUATION() algorithm
        (lhs, diffArguments) := differentiateExpression(eq.lhs, diffArguments);
        (rhs, diffArguments) := differentiateExpression(eq.rhs, diffArguments);
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.RECORD_EQUATION(eq.size, lhs, rhs, eq.source, attr), diffArguments);

      case Equation.IF_EQUATION() algorithm
        (ifBody, diffArguments_ptr) := differentiateIfEquationBody(eq.body, Pointer.create(diffArguments));
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.IF_EQUATION(eq.size, ifBody, eq.source, attr), Pointer.access(diffArguments_ptr));

      case Equation.FOR_EQUATION() algorithm
        (res, diffArguments) := differentiateEquation(eq.body, diffArguments);
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.FOR_EQUATION(eq.iter, eq.range, res, eq.source, attr), diffArguments);

      case Equation.WHEN_EQUATION() algorithm
        (whenBody, diffArguments) := differentiateWhenEquationBody(eq.body, diffArguments);
        attr := differentiateEquationAttributes(eq.attr, diffArguments);
      then (Equation.WHEN_EQUATION(eq.size, whenBody, eq.source, attr), diffArguments);

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Equation.toString(eq)});
      then fail();

    end match;
    eq := Equation.simplify(eq);
  /* ToDo:
    record ALGORITHM
      Integer size                    "output size";
      Algorithm alg                   "Algorithm statements";
      DAE.ElementSource source        "origin of algorithm";
      DAE.Expand expand               "this algorithm was translated from an equation. we should not expand array crefs!";
      EquationAttributes attr         "Additional Attributes";
    end ALGORITHM;

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
    then_eqns := List.map(body.then_eqns, function differentiateEquationPointer(diffArguments_ptr = diffArguments_ptr));
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

  function differentiateExpression
    input output Expression exp;
    input output DifferentiationArguments diffArguments;
  algorithm
  (exp, diffArguments) := match exp
    local
      Expression elem1, elem2;
      list<Expression> new_elements = {};
      list<list<Expression>> new_matrix_elements = {};

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
      for element in exp.elements loop
        (element, diffArguments) := differentiateExpression(element, diffArguments);
        new_elements := element :: new_elements;
      end for;
    then (Expression.ARRAY(exp.ty, listReverse(new_elements), exp.literal), diffArguments);

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
    then (Expression.SUBSCRIPTED_EXP(elem1, exp.subscripts, exp.ty), diffArguments);

    // (..., a_i ,...)' = (..., a'_i, ...)
    case Expression.TUPLE_ELEMENT() algorithm
      (elem1, diffArguments) := differentiateExpression(exp.tupleExp, diffArguments);
    then (Expression.TUPLE_ELEMENT(elem1, exp.index, exp.ty), diffArguments);

    // REC(i, ...)' = REC(i', ...)
    // ToDo: does this suffice? Check with old backend RSUB()!
    case Expression.RECORD_ELEMENT() algorithm
      (elem1, diffArguments) := differentiateExpression(exp.recordExp, diffArguments);
    then (Expression.RECORD_ELEMENT(elem1, exp.index, exp.fieldName, exp.ty), diffArguments);

    // x(..., (y = z)', ...) = x(..., y = z', ...)
    case Expression.BINDING_EXP() algorithm
      (elem1, diffArguments) := differentiateExpression(exp.exp, diffArguments);
    then (Expression.BINDING_EXP(elem1, exp.expType, exp.bindingType, exp.parents, exp.isEach), diffArguments);

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
  algorithm
    (exp, diffArguments) := match (exp, diffArguments)
      local
        Expression res;
        HashTableCrToCr.HashTable jacobianHT;

      // Types: (TIME)
      // differentiate time cref => 1
      case (Expression.CREF(), _)
        guard((diffArguments.diffType == DifferentiationType.TIME) and
              ComponentRef.isTime(exp.cref))
      then (Expression.makeOne(exp.ty), diffArguments);

      // Types: not (TIME)
      // differentiate time cref => 0
      case (Expression.CREF(), _)
        guard(not (diffArguments.diffType == DifferentiationType.TIME) and
              ComponentRef.isTime(exp.cref))
      then (Expression.makeZero(exp.ty), diffArguments);

      // Types: (ALL)
      // differentiate start cref => 0
      case (Expression.CREF(), _)
        guard(BVariable.isStart(BVariable.getVarPointer(exp.cref)))
      then (Expression.makeZero(exp.ty), diffArguments);

      // ToDo: Records, Arrays, WILD (?)

      // Types: (SIMPLE)
      //  D(x)/dx => 1
      case (Expression.CREF(), _)
        guard((diffArguments.diffType == DifferentiationType.SIMPLE) and
              ComponentRef.isEqual(exp.cref, diffArguments.diffCref))
      then (Expression.makeOne(exp.ty), diffArguments);

      // Types: (SIMPLE)
      // D(y)/dx => 0
      case (Expression.CREF(), _)
        guard(diffArguments.diffType == DifferentiationType.SIMPLE)
      then (Expression.makeZero(exp.ty), diffArguments);

      // Types: (ALL)
      // Known variables, except top for level inputs have a 0-derivative
      case (Expression.CREF(), _)
        guard(BVariable.isParamOrConst(BVariable.getVarPointer(exp.cref)) and
              not (ComponentRef.isTopLevel(exp.cref) and BVariable.isInput(BVariable.getVarPointer(exp.cref))))
      then (Expression.makeZero(exp.ty), diffArguments);

      // -------------------------------------
      //    Special rules for Type: TIME
      // -------------------------------------

      // Types: (TIME)
      // D(discrete)/d(x) = 0
      case (Expression.CREF(), _)
        guard((diffArguments.diffType == DifferentiationType.TIME) and
              (BVariable.isDiscrete(BVariable.getVarPointer(exp.cref)) or BVariable.isDiscreteState(BVariable.getVarPointer(exp.cref))))
      then (Expression.makeZero(exp.ty), diffArguments);

      // Types: (TIME)
      // DUMMY_STATES => DUMMY_DER
      case (Expression.CREF(), _)
        guard((diffArguments.diffType == DifferentiationType.TIME) and
              (BVariable.isDummyState(BVariable.getVarPointer(exp.cref))))
      then (Expression.fromCref(BVariable.getDummyDerCref(exp.cref)), diffArguments);

      // ToDo: Types: (TIME) D(y)/dtime --> der(y) --> $DER.y (make y a state)

      // -------------------------------------
      //    Special rules for Type: FUNCTION
      // -------------------------------------

      // ToDo: Types (FUNCTION) all of this!

      // -------------------------------------
      //    Special rules for Type: JACOBIAN
      // -------------------------------------

      // Types: (JACOBIAN)
      // cref in jacobianHT => get $SEED or $pDER variable from HashTable
      case (Expression.CREF(), DIFFERENTIATION_ARGUMENTS(jacobianHT = SOME(jacobianHT)))
        guard((diffArguments.diffType == DifferentiationType.JACOBIAN) and
              BaseHashTable.hasKey(exp.cref, jacobianHT))
      then (Expression.fromCref(BaseHashTable.get(exp.cref, jacobianHT)), diffArguments);

      // Types: (JACOBIAN)
      // Everything that is not in jacobianHT gets differentiated to zero
      case (Expression.CREF(), _)
        guard(diffArguments.diffType == DifferentiationType.JACOBIAN)
      then (Expression.makeZero(exp.ty), diffArguments);

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp)});
      then fail();

    end match;
  end differentiateComponentRef;


  // TODO: Copy Differentiate.mo function differentiateCalls
  function differentiateCall
  "Differentiate builtin function calls"
    input output Expression exp "Has to be Expression.CALL()";
    input output DifferentiationArguments diffArguments;
  protected
    constant Boolean debug = true;
  algorithm
    if debug then
      print("\nDifferentiate Exp-Call: "+ Expression.toString(exp) + "\n");
    end if;

    (exp, diffArguments) := match exp
      local
        Call call;
      case Expression.CALL(call=call) algorithm
        _ := match call
          local
            String name;
            ComponentRef inDiffwrtCref;
          case Call.TYPED_CALL() algorithm
            name := AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn));
            inDiffwrtCref := diffArguments.diffCref;
            exp := differentiateCallExp(name, exp, diffArguments);
            then();
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Call.toString(call)});
            then fail();
        end match;

        then (exp, diffArguments);
      else algorithm
        // Add failtrace here
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp)});
        then fail();
    end match;

    if debug then
      print("Differentiate-ExpCall-result: " + Expression.toString(exp) + "\n");
    end if;

  end differentiateCall;

  protected function differentiateCallExp
    "This function differentiates built-in call expressions with 1 argument
    with respect to a given variable,given as third argument."
    input String name;
    input output Expression exp;
    input output DifferentiationArguments diffArguments;
  algorithm
    exp := match (exp)
      local
        Call call;
        Expression derFuncCall, exp1, diffExp1;
        list<Expression> arguments;
        Operator operator, addOp, mulOp;
        Operator.SizeClassification sizeClass;

      // Builtin function call with one argument
      case (Expression.CALL(call=call))
      guard (listLength(Call.arguments(call)) == 1)
      algorithm
        arguments := Call.arguments(call);
        exp1 := List.first(arguments);
        diffExp1 := differentiateExpression(exp1, diffArguments);
        // TODO: Check sizeClass for array-equations
        sizeClass := NFOperator.SizeClassification.SCALAR;
        mulOp := Operator.fromClassification((NFOperator.MathClassification.MULTIPLICATION, sizeClass), Type.REAL());
        derFuncCall := differentiateNamedCall1Arg(name, exp1);
        then(Expression.MULTARY({derFuncCall, diffExp1}, mulOp));

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp)});
        then fail();
    end match;
  end differentiateCallExp;

  function differentiateNamedCall1Arg
    input String name;
    input Expression innerExp;
    output Expression derFuncCall;
  algorithm
    derFuncCall := match (name)
      // sin -> cos
      case ("sin") algorithm
        then Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.COS_REAL, {innerExp}, Expression.variability(innerExp)));
      // TODO All all builtin functions with one argument here
    else algorithm
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + name});
      then fail();
    end match;
  end differentiateNamedCall1Arg;

  function differentiateBinary
    "Some of this is depcreated because of Expression.MULTARY().
    Will always try to convert to MULTARY whenever possible. (commutativity)"
    input output Expression exp "Has to be Expression.BINARY()";
    input output DifferentiationArguments diffArguments;
  algorithm
    (exp, diffArguments) := match exp
      local
        Expression exp1, exp2, diffExp1, diffExp2, call;
        Operator operator, addOp, mulOp;
        Operator.SizeClassification sizeClass;

      // Dash calculations (ADD, SUB, ADD_EW, SUB_EW, ...)
      // (f + g)' = f' + g'
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard((Operator.getMathClassification(operator) == NFOperator.MathClassification.ADDITION) or
              (Operator.getMathClassification(operator) == NFOperator.MathClassification.SUBTRACTION))
        algorithm
          (diffExp1, diffArguments) := differentiateExpression(exp1, diffArguments);
          (diffExp2, diffArguments) := differentiateExpression(exp2, diffArguments);
      then (Expression.MULTARY({diffExp1, diffExp2}, operator), diffArguments);

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
              {Expression.MULTARY({exp1, diffExp2}, operator),
               Expression.MULTARY({diffExp1, exp2}, operator)},
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
      then (Expression.BINARY(
              Expression.MULTARY(
                {Expression.MULTARY({exp1, diffExp2}, mulOp),             // fg'
                 Expression.UNARY(
                  NFOperator.OPERATOR(operator.ty, NFOperator.Op.UMINUS), // -
                  Expression.MULTARY({diffExp1, exp2}, mulOp))},          // f'g
                addOp                                                     //  +
              ),
              operator,                                                   //  :
              Expression.MULTARY({exp2, exp2}, mulOp)                     // g*g
            ),
            diffArguments);

      // Power (POW, POW_EW, ...) with base zero
      // (0^r)' = 0
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard((Operator.getMathClassification(operator) == NFOperator.MathClassification.POWER) and
              Expression.isZero(exp1))
      then (Expression.makeZero(operator.ty), diffArguments);

      // Power (POW, POW_EW, ...) with constant exponent and constant base
      // (r1^r2)' = 0
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard((Operator.getMathClassification(operator) == NFOperator.MathClassification.POWER) and
              Expression.isConstNumber(exp1) and Expression.isConstNumber(exp2))
      then (Expression.makeZero(operator.ty), diffArguments);

      // Power (POW, POW_EW, ...) with constant exponent
      // (x^r)' = r*(x^(r-1))
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard((Operator.getMathClassification(operator) == NFOperator.MathClassification.POWER) and
              (Expression.isConstNumber(exp2) or BVariable.checkExp(exp2, BVariable.isParamOrConst)))
        algorithm
          (_, sizeClass) := Operator.classify(operator);
          mulOp := Operator.fromClassification((NFOperator.MathClassification.MULTIPLICATION, sizeClass), operator.ty);
          addOp := Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), operator.ty);
      then (Expression.MULTARY(
              {exp2,                                                     // r
              Expression.BINARY(exp1, operator, minusOne(exp2, addOp))}, // x^(r-1)                                             // r
              mulOp                                                      // *
            ),
            diffArguments);

      // Power (POW, POW_EW, ...) with constant base
      // ToDo: what is the most optimal constellation for this?
      // (r^x)'  = r^x*ln(r)*x'
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard((Operator.getMathClassification(operator) == NFOperator.MathClassification.POWER) and
              (Expression.isConstNumber(exp1) or BVariable.checkExp(exp1, BVariable.isParamOrConst)))
        algorithm
          (diffExp2, diffArguments) := differentiateExpression(exp2, diffArguments);
          (_, sizeClass) := Operator.classify(operator);
          mulOp := Operator.fromClassification((NFOperator.MathClassification.MULTIPLICATION, sizeClass), operator.ty);
      then (Expression.MULTARY(
              {exp, expLog(exp1), diffExp2},    // r^x * ln(r) * x
              mulOp                             //  *
            ),
            diffArguments);

      // Power (POW, POW_EW, ...) regular case
      // ToDo: what is the most optimal constellation for this?
      // (x^y)' = x^(y-1) * ( x*ln(x)*y'+(y*x'))
      case Expression.BINARY(exp1 = exp1, operator = operator, exp2 = exp2)
        guard(Operator.getMathClassification(operator) == NFOperator.MathClassification.POWER)
        algorithm
          (diffExp1, diffArguments) := differentiateExpression(exp1, diffArguments);
          (diffExp2, diffArguments) := differentiateExpression(exp2, diffArguments);
          // create addition, subtraction and multiplication operator from the size classification of original power operator
          (_, sizeClass) := Operator.classify(operator);
          addOp := Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), operator.ty);
          mulOp := Operator.fromClassification((NFOperator.MathClassification.MULTIPLICATION, sizeClass), operator.ty);
          // create the ln(x) call
          call := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.LOG_REAL, {exp1}, Expression.variability(exp1)));
      then (Expression.MULTARY(
              {Expression.BINARY(
                exp1,                                                   // x
                operator,                                               // ^
                minusOne(exp2, addOp)                                   // (y-1)
              ),
              Expression.MULTARY(
                {Expression.MULTARY(
                  {exp1, call, diffExp2},                               // x * ln(x) * y'
                  mulOp                                                 // *
                ),
                Expression.MULTARY({exp2, diffExp1}, mulOp)},           // y * x'
                addOp                                                   // +
              )},
              mulOp                                                     // *
            ),
            diffArguments);

      // Logical operators => just return as is
      case Expression.BINARY(operator = operator)
        guard(Operator.getMathClassification(operator) == NFOperator.MathClassification.LOGICAL)
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
        Expression diff_arg;
        list<Expression> arguments, new_arguments = {};
        Operator operator, addOp;
        Operator.SizeClassification sizeClass;
        Array<List<Expression>> diff_lists;
        Integer idx = 1;

      // Dash calculations (ADD, SUB, ADD_EW, SUB_EW, ...)
      // (sum(f_i))' = sum(f_i')
      // e.g. (f + g + h)' = f' + g' + h'
      case Expression.MULTARY(arguments = arguments, operator = operator)
        guard((Operator.getMathClassification(operator) == NFOperator.MathClassification.ADDITION) or
              (Operator.getMathClassification(operator) == NFOperator.MathClassification.SUBTRACTION))
        algorithm
          for arg in listReverse(arguments) loop
            (diff_arg, diffArguments) := differentiateExpression(arg, diffArguments);
            new_arguments := diff_arg :: new_arguments;
          end for;
      then Expression.MULTARY(new_arguments, operator);

      // Multiplication (MUL, MUL_EW, ...)
      // (prod(f_i))' = sum((f_i)' * prod(f_k | k <> i))
      // e.g. (fgh)' = f'gh + fg'h + fgh'
      case Expression.MULTARY(arguments = arguments, operator = operator)
        guard(Operator.getMathClassification(operator) == NFOperator.MathClassification.MULTIPLICATION)
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
            new_arguments := Expression.MULTARY(listReverse(diff_lists[i]), operator) :: new_arguments;
          end for;
          (_, sizeClass) := Operator.classify(operator);
          addOp := Operator.fromClassification((NFOperator.MathClassification.ADDITION, sizeClass), operator.ty);
      then Expression.MULTARY(new_arguments, addOp);

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Expression.toString(exp)});
      then fail();
    end match;
  end differentiateMultary;

  function differentiateEquationAttributes
    "Differentiates the residual variable, if it exists.
    The cref has to be saved in the jacobianHT for this to work.
    Only apply if diffType is JACOBIAN
    ToDo: needs to be adapted for torn/inner equations"
    input output EquationAttributes attr;
    input DifferentiationArguments diffArguments;
  algorithm
    if diffArguments.diffType == DifferentiationType.JACOBIAN then
      attr := match (attr, diffArguments)
        local
          Pointer<Variable> residualVar, diffedResidualVar;
          HashTableCrToCr.HashTable jacobianHT;

        case (EquationAttributes.EQUATION_ATTRIBUTES(residualVar = SOME(residualVar)), DIFFERENTIATION_ARGUMENTS(jacobianHT = SOME(jacobianHT)))
          guard(BaseHashTable.hasKey(BVariable.getVarName(residualVar), jacobianHT))
          algorithm
            diffedResidualVar := BVariable.getVarPointer(BaseHashTable.get(BVariable.getVarName(residualVar), jacobianHT));
        then EquationAttributes.EQUATION_ATTRIBUTES(attr.differentiated, attr.kind, attr.evalStages, SOME(diffedResidualVar));

        else attr;

      end match;
    end if;
  end differentiateEquationAttributes;

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
        else Expression.MULTARY({exp, Expression.makeMinusOne(op.ty)}, op);
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
        else Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.LOG_REAL, {exp}, Expression.variability(exp)));
      end match;
    end expLog;

  annotation(__OpenModelica_Interface="backend");
end NBDifferentiate;
