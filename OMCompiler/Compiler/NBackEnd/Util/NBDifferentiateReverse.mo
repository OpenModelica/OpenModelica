encapsulated package NBDifferentiateReverse
"file:        NBDifferentiateReverse.mo
 package:     NBDifferentiateReverse
 description: This file contains the functions to differentiate equations and
              expressions symbolically in a tape based reverse mode e.g. to generate adjoint jacobians.
 only support REAL, BINARY, UNARY expressions and the five basic BINARY arithmetic ops ADD, SUB, MUL, DIV, (POW) for the type REAL
"

public  
  function getCref
    "Extract cref from expression if it is a cref expression, otherwise return empty cref."
    input Expression expr;
    output ComponentRef cref;
  algorithm
    cref := match expr
      case Expression.CREF(cref = cref) then cref;
      else ComponentRef.EMPTY();
    end match;
  end getCref;

  type PartialMap = UnorderedMap<Expression, Expression>;
  uniontype PartialsForComponent
    record PARTIALS_FOR_COMPONENT
      Expression outputExpr; // lhs of the equation (variable or expression)
      PartialMap partials;   // d(outputExpr)/d(inputExpr) (inputExprs come from RHS)
    end PARTIALS_FOR_COMPONENT;
  end PartialsForComponent;

  function partialMapToString
    input PartialMap m;
    output String str;
  protected
    list<tuple<Expression, Expression>> kvs;
    Boolean first = true;
    Expression k, v;
  algorithm
    kvs := UnorderedMap.toList(m);
    str := "{";
    for kv in kvs loop
      (k, v) := kv;
      if first then first := false; else str := str + ", "; end if;
      str := str + "d/d(" + expressionToString(k) + ") = " + expressionToString(v);
    end for;
    str := str + "}";
  end partialMapToString;

  function collectPartialsForComponents
    "Batch for a list of strong components, result shape: list< per-component list<PartialsForComponent> >."
    input list<NBStrongComponent.StrongComponent> comps;
    input list<Expression> seeds = {}; // optional seeds for each component, default is Expression.REAL(1.0)
    // each inner list<PartialsForComponent> contains the partials for all strong components in one partition
    // one backend dae can have multiple partitions, so the outer list is needed
    output list<list<PartialsForComponent>> results = {};
  protected
    NBStrongComponent.StrongComponent c;
  algorithm
    for c in comps loop
      results := collectPartialsForStrongComponent(c) :: results;
    end for;
    results := listReverse(results);
  end collectPartialsForComponents;

protected
  import Expression = NFExpression;
  import Operator = NFOperator;
  import Op = NFOperator.Op;
  import Type = NFType;
  import SimplifyExp = NFSimplifyExp;
  import ComponentRef = NFComponentRef;
  import Origin = NFComponentRef.Origin;
  import NFBuiltinFuncs;
  import Call = NFCall;
  import AbsynUtil;
  import NFFunction.{Function};
  import NBDifferentiate;
  import StrongComponent = NBStrongComponent;
  import NBEquation;
  import BVariable = NBVariable;
  import Variable = NFVariable;
  //import InstNode = NFInstNode;

  // record Node
  //   Expression expr; // the expression this node represents
  //   // list<Expression> childGradients; // local gradients d_expr/d_child for each child (weights)
  //   list<Integer> childIndices; // indices of the children nodes on the tape these weights correspond to (deps)
  // end Node;

  // function createSimpleRealVar
  //   input String name;
  //   output Expression expr;
  //   output Pointer<NBVariable.Variable> var_ptr;
  //   output ComponentRef cref;
  // protected
  //   InstNode.InstNode node;
  //   NBVariable.Variable var;
  //   Type ty = Type.REAL();
  // algorithm
  //   node := InstNode.VAR_NODE(name, Pointer.create(NBVariable.DUMMY_VARIABLE));
  //   cref := ComponentRef.CREF(node, {}, ty, Origin.CREF, ComponentRef.EMPTY());
  //   var  := NBVariable.fromCref(cref);
  //   (var_ptr, cref) := NBVariable.makeVarPtrCyclic(var, cref);
  //   expr := Expression.CREF(ty, cref);
  // end createSimpleRealVar;

  // Constructors and helpers for PartialMap
  function partialMapNew
    output PartialMap m;
  algorithm
    m := UnorderedMap.new<Expression>(Expression.hash, Expression.isEqual);
  end partialMapNew;

  function partialMapGet
    input PartialMap m;
    input Expression key;
    output Expression val;
  algorithm
    if UnorderedMap.contains(key, m) then
      val := UnorderedMap.getOrFail(key, m);
    else
      val := Expression.REAL(0.0);
    end if;
  end partialMapGet;

  function partialMapAdd
    input output PartialMap m;
    input Expression key;
    input Expression addVal;
  protected
    Expression cur;
  algorithm
    if UnorderedMap.contains(key, m) then
      cur := UnorderedMap.getOrFail(key, m);
      UnorderedMap.add(key, simplify(Expression.BINARY(cur, Operator.makeAdd(Type.REAL()), addVal)), m);
    else
      UnorderedMap.add(key, addVal, m);
    end if;
  end partialMapAdd;

  function collectPartialsForStrongComponent
    input NBStrongComponent.StrongComponent compIn;
    output list<PartialsForComponent> results;
  protected
    NBStrongComponent.StrongComponent comp = NBStrongComponent.removeAlias(compIn);
    Pointer<NBEquation.Equation> eqp;
    NBEquation.Equation eq;
  algorithm
    results := {};
    () := match comp
      case NBStrongComponent.SINGLE_COMPONENT(eqn = eqp) algorithm
        eq := Pointer.access(eqp);
        results := { symbolicReverseModeStrongComponent(comp) };
      then ();
      else ();
    end match;
  end collectPartialsForStrongComponent;

  function localPartialFor1ArgCall
    "Return local partial df/darg for a builtin single-argument call expression.
    Reuses differentiateBuiltinCall1Arg so rules are not duplicated."
    input Expression exp;
    output Expression localPartial;
  protected
    Call callv;
    String name;
    Expression arg;
    Function fn;
    list<Expression> args;
  algorithm
    localPartial := match exp
      case Expression.CALL(call = callv) then
        match callv
          case Call.TYPED_CALL(fn = fn, arguments = args) guard (Function.isBuiltin(fn) and listLength(args) == 1) then
            // differentiateBuiltinCall1Arg returns df/darg (does NOT multiply by inner derivative)
            NBDifferentiate.differentiateBuiltinCall1Arg(AbsynUtil.pathString(Function.nameConsiderBuiltin(fn)), listHead(args));
          else
            Expression.makeZero(Expression.typeOf(exp));
        end match;
      else
        Expression.makeZero(Expression.typeOf(exp));
    end match;
  end localPartialFor1ArgCall;


  function localPartialFor2ArgCall
    "Return local partial df/darg for a builtin two-argument call expression.
    Reuses NBDifferentiate.differentiateBuiltinCall2Arg so rules are not duplicated."
    input Expression exp;
    input Integer childIndex;
    output Expression localPartial;
  protected
    Call callv;
    Function fn;
    list<Expression> args;
    Expression arg1;
    Expression arg2;
    Expression p1;
    Expression p2;
    String name;
  algorithm
    localPartial := match exp
      case Expression.CALL(call = callv) then
        match callv
          case Call.TYPED_CALL(fn = fn, arguments = args) guard (Function.isBuiltin(fn) and listLength(args) == 2) then
            // extract the two arguments
            match args
              case {arg1, arg2} algorithm
                name := AbsynUtil.pathString(Function.nameConsiderBuiltin(fn));
                // get local derivatives df/darg1 and df/darg2
                (p1, p2) := NBDifferentiate.differentiateBuiltinCall2Arg(name, arg1, arg2);
                then (if childIndex == 1 then p1 else p2);
              else
                Expression.makeZero(Expression.typeOf(exp));
            end match;
          else
            Expression.makeZero(Expression.typeOf(exp));
        end match;
      else
        Expression.makeZero(Expression.typeOf(exp));
    end match;
  end localPartialFor2ArgCall;


  function prodExp
    input list<Expression> xs;
    input Type ty;
    output Expression p;
  algorithm
    p := Expression.REAL(1.0);
    for e in xs loop
      p := Expression.MULTARY({p, e}, {}, Operator.makeMul(ty));
    end for;
  end prodExp;

  function divExp
    input Expression num;
    input Expression den;
    input Type ty;
    output Expression q;
  algorithm
    if Expression.isOne(den) then
      q := num;
    else
      q := Expression.MULTARY({num}, {den}, Operator.makeMul(ty));
    end if;
  end divExp;

  function localGradient
    input Expression expr;
    input Integer childIndex;
    output Expression grad;
  protected
    Expression left_child, right_child;
    Operator op;
    list<Expression> args, inv_args;
    Expression localGradient;
    Integer nArgs;
    Expression P, Q, base, child;
    Type ty = Type.REAL();

  algorithm
    grad := match expr
      case Expression.REAL() then 
        Expression.REAL(0.0); 

      case Expression.CREF() then 
        Expression.REAL(1.0);

      case Expression.UNARY(operator = op, exp = child) then
        match op.op
          case Op.UMINUS then 
            Expression.REAL(-1.0); // ∂(-a)/∂a = -1

          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + "Failed! Given Unary Operator is not supported: " + Operator.toDebugString(op)});
          then fail();
        end match;

      case Expression.BINARY(exp1 = left_child, operator = op, exp2 = right_child) then
        // Differentiate based on the operator
        match op.op
          case Op.ADD then 
            Expression.REAL(1.0);  // ∂(a + b)/∂a = 1, ∂(a + b)/∂b = 1

          case Op.SUB then 
            if childIndex == 1 then 
              Expression.REAL(1.0)  // ∂(a - b)/∂a = 1
            else Expression.REAL(-1.0); // ∂(a - b)/∂b = -1

          case Op.MUL then
            if childIndex == 1 then 
              right_child // ∂(a * b)/∂a = b
            else left_child; // ∂(a * b)/∂b = a

          // case Op.MUL_EW then
          //   if childIndex == 1 then 
          //     right_child // ∂(A .* B)/∂A = B
          //   else left_child; // ∂(A .* B)/∂B = A

          case Op.DIV then
            if childIndex == 1 then
              simplify(Expression.BINARY(Expression.REAL(1.0), Operator.makeDiv(Type.REAL()), right_child)) // ∂(a / b)/∂a = 1/b
            else
              simplify(Expression.negate(Expression.BINARY(left_child, Operator.makeDiv(Type.REAL()), 
                                Expression.BINARY(right_child, Operator.makePow(Type.REAL()), Expression.REAL(2.0))))); //∂(a / b)/∂b = -a/(b^2) 

          case Op.MUL_MATRIX_VECTOR then
            if childIndex == 1 then 
              right_child // ∂(A * x)/∂A = x
            else left_child; // ∂(A * x)/∂x = A

          case Op.MUL_VECTOR_MATRIX then
            if childIndex == 1 then 
              right_child // ∂(x * A)/∂x = A
            else left_child; // ∂(x * A)/∂A = x

          case Op.SCALAR_PRODUCT then
            if childIndex == 1 then 
              right_child // ∂(x * y)/∂x = y
            else left_child; // ∂(x * y)/∂y = x
          
          case Op.MATRIX_PRODUCT then
            if childIndex == 1 then 
              right_child // ∂(A * B)/∂A = B
            else left_child; // ∂(A * B)/∂B = A
    
          else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + "Failed! Given Operator is not supported: " + Operator.toDebugString(op)});
          then fail();
        end match;

      case Expression.MULTARY(arguments = args, inv_arguments = inv_args, operator = op) algorithm
        nArgs := listLength(args);
        if op.op == Op.ADD then
          grad := if childIndex <= nArgs then Expression.REAL(1.0) else Expression.REAL(-1.0);
        elseif op.op == Op.MUL then
          P := if listEmpty(args) then Expression.REAL(1.0) else simplify(prodExp(args, ty));
          Q := if listEmpty(inv_args) then Expression.REAL(1.0) else simplify(prodExp(inv_args, ty));
          base := simplify(divExp(P, Q, ty));
          if childIndex <= nArgs then
            child := listGet(args, childIndex);
            grad := simplify(divExp(base, child, ty));
          else
            child := listGet(inv_args, childIndex - nArgs);
            grad := simplify(Expression.negate(divExp(base, child, ty)));
          end if;
        else
          Error.addMessage(Error.INTERNAL_ERROR,
            {getInstanceName() + " MULTARY op can only be + or * but is: " + Operator.symbol(op)});
          fail();
        end if;
      then grad;

      case Expression.CALL() guard List.hasOneElement(Call.arguments(expr.call)) then 
        localPartialFor1ArgCall(expr);

      case Expression.CALL() guard (listLength(Call.arguments(expr.call)) == 2) then 
        localPartialFor2ArgCall(expr, childIndex);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + "Failed! Given Expression is not supported." + Expression.toString(expr)});
      then fail();
    end match;
  end localGradient;

  function getChildren
    input Expression expr;
    output list<Expression> children;
  protected
    Expression left_child, right_child, child;
    Operator op;
    list<Expression> multary_args, multary_inv_args;
  algorithm
    children := match expr
        case Expression.REAL() then {};
        case Expression.CREF() then {};
        case Expression.UNARY(operator = op, exp = child) then {child};
        case Expression.BINARY(exp1 = left_child, operator = op, exp2 = right_child) then {left_child, right_child};
        case Expression.MULTARY(arguments = multary_args, inv_arguments = multary_inv_args) then listAppend(multary_args, multary_inv_args);
        case Expression.CALL() then 
          match expr
            local 
              list<Expression> args;
            case Expression.CALL(call = Call.TYPED_CALL(arguments = args)) then args;
          end match;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + "Failed! Given Expression is not supported: " + Expression.toString(expr)});
        then fail();
    end match;
  end getChildren;

  // Check if two expressions are structurally equal
  function expressionEqual
    input Expression expr1;
    input Expression expr2;
    output Boolean equal;
  algorithm
    equal := Expression.isEqual(expr1, expr2);
  end expressionEqual;

  // Convert expression to string representation
  function expressionToString
    input Expression expr;
    output String str;
  algorithm
    str := Expression.toString(expr);
  end expressionToString;

  // Build computation tape in post-order traversal
  function buildTape
    input Expression expr;
    output list<Expression> tape;
  protected
    UnorderedSet<Expression> visited;
  algorithm
    // Hash set for fast membership: Expression.hash / Expression.isEqual
    visited := UnorderedSet.new<Expression>(Expression.hash, Expression.isEqual);
    tape := buildTapeHelper(expr, {}, visited);
  end buildTape;

  // Helper function for building tape with visited tracking
  function buildTapeHelper
    input Expression expr;
    input list<Expression> currentTape;
    input UnorderedSet<Expression> visited;
    output list<Expression> tape;
  protected
    list<Expression> children;
  algorithm
    // Check if already visited
    if UnorderedSet.contains(expr, visited) then
      tape := currentTape;
      return;
    end if;
    // if not visited mark as visited now
    UnorderedSet.add(expr, visited);
    
    // process children first (post-order)
    // so that for expression a * b, a and b appear before a * b in the tape
    tape := currentTape;
    children := getChildren(expr);
    
    // recursively build tape for each child
    for child in children loop
      tape := buildTapeHelper(child, tape, visited);
    end for;
    
    // after the children add current expression to tape
    tape := expr :: tape;
  end buildTapeHelper;

  // Simplification rules for algebraic expressions
  function simplify
    input Expression expr;
    output Expression simplified;
  algorithm
    simplified := SimplifyExp.simplify(expr);
  end simplify;

  function symbolicReverseModeStrongComponent
    "Differentiate a SINGLE_COMPONENT strong component in reverse mode.
     Uses RHS for differentiation and returns PartialsForComponent with LHS as outputExpr."
    input StrongComponent comp;
    input Expression seed = Expression.REAL(1.0);
    output PartialsForComponent result;
  protected
    Pointer<NBEquation.Equation> eq_ptr;
    NBEquation.Equation eq;
    Expression lhs, rhs;
    StrongComponent c = comp;
    PartialMap pm;
  algorithm
    c := StrongComponent.removeAlias(c);
    eq_ptr := match c
      case StrongComponent.SINGLE_COMPONENT() then c.eqn;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,
          {getInstanceName() + ": symbolicReverseModeStrongComponent currently only supports SINGLE_COMPONENT."});
      then fail();
    end match;

    eq := Pointer.access(eq_ptr);

    // Get LHS and RHS; differentiate RHS, but report LHS as outputExpr
    lhs := NBEquation.Equation.getLHS(eq);
    rhs := NBEquation.Equation.getRHS(eq);

    pm := symbolicReverseMode(rhs, seed);
    result := PartialsForComponent.PARTIALS_FOR_COMPONENT(lhs, pm);
  end symbolicReverseModeStrongComponent;

  // Main function: Symbolic reverse-mode differentiation over an expression
  function symbolicReverseMode
    input Expression expr;
    input Expression seed = Expression.REAL(1.0);
    output PartialMap partials;
  protected
    list<Expression> tape, children;
    Expression currentGrad, localGrad, childGrad;
    Integer i;
  algorithm
    // Build computation tape
    tape := buildTape(expr);

    print("Computation tape:\n");
    for i in 1:listLength(tape) loop
      print(intString(i) + ": " + expressionToString(listGet(tape, i)) + "\n");
    end for;

    // Initialize gradient map
    partials := partialMapNew();
    // add seed gradient d(expr)/d(expr) = seed
    // this is simply the seed expression e.g. $SEED_ODE_JAC.DER(x)
    partialMapAdd(partials, expr, seed);

    // Process tape in reverse order 
    // we built tape by prepending so no need to reverse it here
    // for a * b the tape looks like [a * b, a, b]
    for operation in tape loop
      currentGrad := partialMapGet(partials, operation);
      if Expression.isZero(currentGrad) then
        continue;
      end if;

      children := getChildren(operation);
      i := 1;
      for child in children loop
        localGrad := localGradient(operation, i);
        // chain rule: d(output)/d(child) = d(output)/d(operation) * d(operation)/d(child)
        // this multiplication could be more complicated though for matrices/vectors
        // currently this is handled in makeAdjointContribution but should probably be done here
        childGrad := simplify(Expression.BINARY(currentGrad, Operator.makeMul(Type.REAL()), localGrad));
        partialMapAdd(partials, child, childGrad);
        i := i + 1;
      end for;
    end for;
  end symbolicReverseMode;

  annotation(__OpenModelica_Interface="backend");
end NBDifferentiateReverse;