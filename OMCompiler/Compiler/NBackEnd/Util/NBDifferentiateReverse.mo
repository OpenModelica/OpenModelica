encapsulated package NBDifferentiateReverse
"file:        NBDifferentiateReverse.mo
 package:     NBDifferentiateReverse
 description: This file contains the functions to differentiate equations and
              expressions symbolically in reverse mode e.g. to generate adjoint jacobians.
 only support REAL, BINARY, UNARY expressions and the five basic BINARY arithmetic ops ADD, SUB, MUL, DIV, (POW) for the type REAL
 How to handle the UNARY ops NEG, SIN, COS as they are no Expressions or Operators?
"

  protected function getCref
    "Extract cref from expression if it is a cref expression, otherwise return empty cref."
    input Expression expr;
    output ComponentRef cref;
  algorithm
    cref := match expr
      case Expression.CREF(cref = cref) then cref;
      else ComponentRef.EMPTY();
    end match;
  end getCref;

  public function testBasicDifferentiation
      input Real dummy;
      output Boolean success;
    protected
      Expression x, y, expr, diff_expr, mulXY, mul2, mul3;
      GradientMap grads;
      Expression gradX, gradY;
      NBDifferentiate.DifferentiationArguments diff_args, diff_args_diff;
    algorithm
      // Create test expression: f(x, y) = x * sin(y)
      x := Expression.CREF(Type.REAL(), 
                          ComponentRef.CREF(InstNode.NAME_NODE("x"), {}, Type.REAL(), Origin.CREF, ComponentRef.EMPTY()));
      y := Expression.CREF(Type.REAL(),
                          ComponentRef.CREF(InstNode.NAME_NODE("y"), {}, Type.REAL(), Origin.CREF, ComponentRef.EMPTY()));

      // sinY := Expression.CALL(Call.makeTypedCall(
      //     fn          = NFBuiltinFuncs.SIN_REAL,
      //     args        = {y},
      //     variability = Expression.variability(y),
      //     purity      = NFPrefixes.Purity.PURE));
          
      mulXY := Expression.BINARY(exp1 = x, operator = Operator.makeMul(Type.REAL()), exp2 = y);
      mul2 := Expression.BINARY(exp1 = Expression.REAL(2.0), operator = Operator.makeMul(Type.REAL()), exp2 = y);
      mul3 := Expression.BINARY(exp1 = Expression.REAL(3.0), operator = Operator.makeMul(Type.REAL()), exp2 = mulXY);
      expr := Expression.BINARY(exp1 = mul2, operator = Operator.makeAdd(Type.REAL()), exp2 = mul3);


      // diff_args := NBDifferentiate.DifferentiationArguments.simpleCref(getCref(x));
      // (diff_expr, diff_args_diff) := NBDifferentiate.differentiateBinary(expr, diff_args);
      // print("\n");

      // print("Expression: " + expressionToString(expr) + "\n");
      // print("Differentiated Expression w.r.t. x: " + expressionToString(diff_expr) + "\n");
      
      // Compute gradients reverse mode
      grads := symbolicReverseMode(expr);
      gradX := findGradient(x, grads); // y
      gradY := findGradient(y, grads); // x + cos(y)
      print("Expression: " + expressionToString(expr) + "\n");
      print("Gradient w.r.t. x: " + expressionToString(gradX) + "\n");
      print("Gradient w.r.t. y: " + expressionToString(gradY) + "\n");

      success := true;
  end testBasicDifferentiation;




protected
  import DAE;
  import Expression = NFExpression;
  import Operator = NFOperator;
  import Op = NFOperator.Op;
  import Type = NFType;
  import SimplifyExp = NFSimplifyExp;
  import InstNode = NFInstNode;
  import ComponentRef = NFComponentRef;
  import Origin = NFComponentRef.Origin;
  import NFBuiltinFuncs;
  import Call = NFCall;
  import AbsynUtil;
  import NFFunction.{Function, Slot};
  import NBDifferentiate;
  import StrongComponent = NBStrongComponent;
  import NBEquation;
  import NBSolve;
  import BVariable = NBVariable;
  import NBackendDAE;
  import NFFlatten.FunctionTree;
  import Partition = NBPartition;
  import Variable = NFVariable;

  // record Node
  //   Expression expr; // the expression this node represents
  //   // list<Expression> childGradients; // local gradients d_expr/d_child for each child (weights)
  //   list<Integer> childIndices; // indices of the children nodes on the tape these weights correspond to (deps)
  // end Node;

  function createSimpleRealVar
    input String name;
    output Expression expr;
    output Pointer<NBVariable.Variable> var_ptr;
    output ComponentRef cref;
  protected
    InstNode.InstNode node;
    NBVariable.Variable var;
    Type ty = Type.REAL();
  algorithm
    node := InstNode.VAR_NODE(name, Pointer.create(NBVariable.DUMMY_VARIABLE));
    cref := ComponentRef.CREF(node, {}, ty, Origin.CREF, ComponentRef.EMPTY());
    var  := NBVariable.fromCref(cref);
    (var_ptr, cref) := NBVariable.makeVarPtrCyclic(var, cref);
    expr := Expression.CREF(ty, cref);
  end createSimpleRealVar;


  function exprListToString
    input list<Expression> es;
    output String str;
  protected
    Boolean first = true;
  algorithm
    str := "{";
    for e in es loop
      if first then
        first := false;
      else
        str := str + ", ";
      end if;
      str := str + expressionToString(e);
    end for;
    str := str + "}";
  end exprListToString;

  // Pretty-print list<tuple<Expression, list<Expression>>>
  function seedPartialsListToString
    input list<tuple<Expression, list<Expression>>> seedToPartials;
    output String str;
  protected
    Boolean first = true;
    Expression seed;
    list<Expression> parts;
  algorithm
    str := "[";
    for it in seedToPartials loop
      (seed, parts) := it;
      if first then
        first := false;
      else
        str := str + ", ";
      end if;
      str := str + "(" + expressionToString(seed) + " -> " + exprListToString(parts) + ")";
    end for;
    str := str + "]";
  end seedPartialsListToString;

  type JacobianType = enumeration(ODE, DAE, LS, NLS);
  public function testReverseStrongComponent
    input NBackendDAE dae;
    input Partition.Kind kind;
  protected
    // Expression x, y, term1, term2, lhs_expr, rhs;
    // ComponentRef x_cref;
    // ComponentRef lhs_cref;
    // Pointer<NBVariable.Variable> x_var_ptr;
    // Pointer<NBVariable.Variable> der_x_var_ptr;
    GradientMap grads;
    // Expression grad_x, grad_y;
    // Pointer<NBEquation.Equation> eq_ptr;
    // NBEquation.Equation eq;
    // NBEquation.EquationAttributes attrs;

    FunctionTree funcTree;
    // UnorderedMap<ComponentRef,ComponentRef> diff_map = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    // NBDifferentiate.DifferentiationArguments diffArguments;
    // Pointer<Integer> idx = Pointer.create(0);
    list<Partition.Partition> oldPartitions;
    list<StrongComponent> comps, diffed_comps;
    // JacobianType jacType;
    // BVariable.VariablePointers unknowns;
    // list<Pointer<Variable>> derivative_vars, state_vars;
    // BVariable.VariablePointers seedCandidates, partialCandidates;
    // Pointer<list<Pointer<Variable>>> seed_vars_ptr = Pointer.create({});
    // Pointer<list<Pointer<Variable>>> pDer_vars_ptr = Pointer.create({});
    // list<Pointer<Variable>> res_vars, tmp_vars, seed_vars;
    // String name;
    // BVariable.checkVar func = BVariable.isStateDerivative;
    // NBEquation.EquationPointer eq_ptr;
    // Expression rdiff, expr;
    // ComponentRef ref;
    // UnorderedMap<ComponentRef, Expression> partials;
    //list<tuple<Expression, list<Expression>>> allPartials = {};
  algorithm
    // // Proper backend variables (VAR_NODE) for x and y
    // (x, x_var_ptr, x_cref) := createSimpleRealVar("x");
    // (y, _,          _)     := createSimpleRealVar("y");

    // // Build RHS: x*y + 2*y
    // term1 := Expression.BINARY(x, Operator.makeMul(Type.REAL()), y);
    // term2 := Expression.BINARY(Expression.REAL(2.0), Operator.makeMul(Type.REAL()), y);
    // rhs   := Expression.BINARY(term1, Operator.makeAdd(Type.REAL()), term2);

    // // Create derivative variable der(x)
    // (lhs_cref, der_x_var_ptr) := NBVariable.makeDerVar(x_cref);
    // lhs_expr := Expression.CREF(Type.REAL(), lhs_cref);

    // // Equation der(x) = x*y + 2*y
    // attrs := NBEquation.default(NBEquation.EquationKind.CONTINUOUS, false);
    // eq := NBEquation.Equation.SCALAR_EQUATION(Type.REAL(), lhs_expr, rhs, DAE.emptyElementSource, attrs);
    // eq_ptr := Pointer.create(eq);

    // // Construct SINGLE_COMPONENT (adjust if your real signature differs)
    // comp := StrongComponent.SINGLE_COMPONENT(x_var_ptr, eq_ptr, NBSolve.Status.EXPLICIT);


    // allPartials := gatherPartialsForAllSeeds(dae, kind);


    // // Print the collected partials
    // print("allPartials = " + seedPartialsListToString(allPartials) + "\n");



    _ := match dae
      case NBackendDAE.MAIN(funcTree = funcTree)
        algorithm
          oldPartitions := match kind
            case NBPartition.Kind.ODE then dae.ode;
          end match;


          for part in oldPartitions loop
            comps := list(comp for comp guard(not StrongComponent.isDiscrete(comp)) in Util.getOption(part.strongComponents));


            // Differentiate residual (lhs - rhs)
            for comp in comps loop
              print("Original strong component:\n");
              print("  " + StrongComponent.toString(comp) + "\n");
              
              grads := symbolicReverseModeStrongComponent(comp);

              print("Computed gradients:\n");
              print(" " + gradientMapToString(grads) + "\n");
              print("###############################################\n");

              // grad_x := findGradient(x, grads);
              // grad_y := findGradient(y, grads);

              // print("Residual equation: " + NBEquation.Equation.toString(eq) + "\n");
              // print("df/dx = " + Expression.toString(grad_x) + "\n");
              // print("df/dy = " + Expression.toString(grad_y) + "\n");
            end for;

            //gatherPartialsWrtInput({grads}, x);
          end for;
      then dae;
    end match;

  // () := match dae
  //   case NBackendDAE.MAIN(funcTree = funcTree)
  //     algorithm
  //       oldPartitions := match kind
  //         case NBPartition.Kind.ODE then dae.ode;
  //       end match;
  //       jacType := JacobianType.ODE;
  //       name := "TEST";
  //       print(intString(listLength(oldPartitions)) + " partitions found.\n");
  //       // differentiate all strong components
  //       for part in oldPartitions loop
  //         partialCandidates := part.unknowns;
  //         unknowns  := part.unknowns;
  //         derivative_vars := list(var for var guard(NBVariable.isStateDerivative(var)) in BVariable.VariablePointers.toList(unknowns));
  //         state_vars := list(Util.getOption(NBVariable.getVarState(var)) for var in derivative_vars);
  //         seedCandidates := BVariable.VariablePointers.fromList(state_vars, partialCandidates.scalarized);
  //         comps := list(comp for comp guard(not StrongComponent.isDiscrete(comp)) in Util.getOption(part.strongComponents));

  //         BVariable.VariablePointers.mapPtr(seedCandidates, function makeVarTraverse(name = name, vars_ptr = seed_vars_ptr, map = diff_map, makeVar = NBVariable.makeSeedVar, init = true));

  //         // create pDer vars (also filters out discrete vars)
  //         (res_vars, tmp_vars) := List.splitOnTrue(BVariable.VariablePointers.toList(partialCandidates), func);
  //         (tmp_vars, _) := List.splitOnTrue(tmp_vars, function NBVariable.isContinuous(init = false));

  //         for v in res_vars loop makeVarTraverse(v, name, pDer_vars_ptr, diff_map, function NBVariable.makePDerVar(isTmp = false), init = true); end for;
  //         res_vars := Pointer.access(pDer_vars_ptr);

  //         pDer_vars_ptr := Pointer.create({});
  //         for v in tmp_vars loop makeVarTraverse(v, name, pDer_vars_ptr, diff_map, function NBVariable.makePDerVar(isTmp = true), init = true); end for;
  //         tmp_vars := Pointer.access(pDer_vars_ptr);

  //         // Build differentiation argument structure
  //         diffArguments := NBDifferentiate.DIFFERENTIATION_ARGUMENTS(
  //           diffCref        = ComponentRef.EMPTY(),   // no explicit cref necessary, rules are set by diff map
  //           new_vars        = {},
  //           diff_map        = SOME(diff_map),         // seed and temporary cref map
  //           diffType        = NBDifferentiate.DifferentiationType.JACOBIAN,
  //           funcTree        = funcTree,
  //           scalarized      = seedCandidates.scalarized
  //         );

  //         (diffed_comps, diffArguments) := NBDifferentiate.differentiateStrongComponentList(comps, diffArguments, idx, "TEST", getInstanceName());

  //         print("Original strong components:\n");
  //         for c in comps loop
  //           print("  " + StrongComponent.toString(c) + "\n");
  //         end for;
  //         print("Differentiated strong components:\n");
  //         for c in diffed_comps loop
  //           print("  " + StrongComponent.toString(c) + "\n");
  //           eq_ptr := NBStrongComponent.getEquationPointers(c);
  //           rdiff := diffedResidualExpr(Pointer.access(eq_ptr));
  //           partials := collectPartialsWrtSeeds(rdiff, diff_map, diffArguments.scalarized);
  //           print("    Collected partials: ");
  //           for tpl in UnorderedMap.toList(partials) loop
  //             (ref, expr) := tpl;
  //             print("      " + ComponentRef.toString(ref) + " -> " + Expression.toString(expr) + "\n");
  //           end for;
  //         end for;
  //       end for;
  //     then ();
  // end match;
  end testReverseStrongComponent;

  // public function gatherPartialsForAllSeeds
  //   "For a BackendDAE.JACOBIAN, compute reverse-mode gradients for each strong component
  //    and gather ∂output_i/∂seed for all seed variables in VarData.seedVars.
  //    Returns a list of tuples (seedExpr, partialsPerOutput)."
  //   input NBackendDAE bdae;
  //   input Partition.Kind kind;
  //   output list<tuple<Expression, list<Expression>>> seedToPartials = {};
  // protected
  //   array<StrongComponent> compsArr;
  //   NBVariable.VarData varData;
  //   NBVariable.VariablePointers knowns;
  //   NBVariable.VariablePointers seedVars;
  //   NBVariable.VariablePointers unknowns;
  //   list<Pointer<NBVariable.Variable>> derivative_vars, state_vars;
  //   NBVariable.VariablePointers seedCandidates, partialCandidates;
  //   list<Pointer<NBVariable.Variable>> seedPtrs;
  //   list<GradientMap> outputsGradients = {};
  //   GradientMap gm;
  //   StrongComponent comp;
  //   Expression seedExpr;
  //   list<Expression> partials;
  //   Integer i, n;
  //   list<Partition.Partition> partitions;
  // algorithm
  //   _ := match bdae
  //     case NBackendDAE.MAIN(varData = NBVariable.VAR_DATA_SIM(knowns = knowns)) //NBackendDAE.JACOBIAN(varData = varData as NBVariable.VarData.VAR_DATA_JAC(seedVars = seedVars), comps = compsArr)
  //       algorithm
  //         partitions := match kind
  //           case NBPartition.Kind.ODE then bdae.ode;
  //         end match;

  //         for part in partitions loop
  //           partialCandidates := part.unknowns;
  //           unknowns  := part.unknowns;
  //           derivative_vars := list(var for var guard(NBVariable.isStateDerivative(var)) in NBVariable.VariablePointers.toList(unknowns));
  //           state_vars := list(Util.getOption(NBVariable.getVarState(var)) for var in derivative_vars);
  //           seedCandidates := NBVariable.VariablePointers.fromList(state_vars, partialCandidates.scalarized);
  //           //allSeedCandidates := seedCandidates :: allSeedCandidates;

  //           compsArr := listArray(list(StrongComponent.removeAlias(c) for c guard(not StrongComponent.isDiscrete(c)) in Util.getOption(part.strongComponents)));
  //           // print("Partition with " + intString(arrayLength(compsArr)) + " strong components.\n");
  //           // Build GradientMap list, one per output (strong component)
  //           n := arrayLength(compsArr);
  //           for i in 1:n loop
  //             comp := compsArr[i];
  //             // Try reverse-mode for supported SINGLE_COMPONENTs; skip unsupported
  //             try
  //               gm := symbolicReverseModeStrongComponent(comp);
  //               outputsGradients := gm :: outputsGradients;
  //             else
  //               // skip component if not supported
  //             end try;
  //           end for;
  //         end for;
  //         outputsGradients := listReverse(outputsGradients);

  //         // Gather ∂output_i/∂seed for each seed variable
  //         seedPtrs := NBVariable.VariablePointers.toList(seedCandidates);
  //         for sptr in seedPtrs loop
  //           seedExpr := NBVariable.toExpression(sptr);
  //           partials := gatherPartialsWrtInput(outputsGradients, seedExpr);
  //           seedToPartials := (seedExpr, partials) :: seedToPartials;
  //         end for;
  //         seedToPartials := listReverse(seedToPartials);
  //     then ();

  //     else algorithm
  //       Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + ": gatherPartialsForAllSeeds only supports BackendDAE.JACOBIAN."});
  //     then fail();
  //   end match;
  // end gatherPartialsForAllSeeds;


  // public function partialDerivativeWrtInput
  //   "Returns ∂output/∂input from a single GradientMap."
  //   input GradientMap grads;
  //   input Expression inputExpr;
  //   output Expression dfdInput;
  // algorithm
  //   dfdInput := simplify(findGradient(inputExpr, grads));
  // end partialDerivativeWrtInput;

  // public function gatherPartialsWrtInput
  //   "Returns ∂output_i/∂input for each output i (one GradientMap per output)."
  //   input list<GradientMap> outputsGradients;
  //   input Expression inputExpr;
  //   output list<Expression> partials;
  // algorithm
  //   partials := list(partialDerivativeWrtInput(gm, inputExpr) for gm in outputsGradients);
  // end gatherPartialsWrtInput;

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
        Expression.REAL(value = 0.0); 

      case Expression.CREF() then 
        Expression.REAL(value = 1.0);

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
              Expression.BINARY(Expression.REAL(1.0), Operator.makeDiv(Type.REAL()), right_child) // ∂(a / b)/∂a = 1/b
            else
              Expression.negate(Expression.BINARY(left_child, Operator.makeDiv(Type.REAL()), 
                                Expression.BINARY(right_child, Operator.makePow(Type.REAL()), Expression.REAL(2.0)))); //∂(a / b)/∂b = -a/(b^2) 

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
          P := if listEmpty(args) then Expression.REAL(1.0) else prodExp(args, ty);
          Q := if listEmpty(inv_args) then Expression.REAL(1.0) else prodExp(inv_args, ty);
          base := divExp(P, Q, ty);
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
    Expression left_child, right_child;
    Operator op;
    list<Expression> multary_args, multary_inv_args;
  algorithm
    children := match expr
        case Expression.REAL() then {};
        case Expression.CREF() then {};
        case Expression.BINARY(exp1 = left_child, operator = op, exp2 = right_child) then {left_child, right_child};
        case Expression.MULTARY(arguments = multary_args, inv_arguments = multary_inv_args) then listAppend(multary_args, multary_inv_args);
        case Expression.CALL() then 
          match expr
            local 
              list<Expression> args;
            case Expression.CALL(call = Call.TYPED_CALL(arguments = args)) then args;
          end match;
        // case UNARY(operator = op, exp = child) then {child};
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + "Failed! Given Expression is not supported: " + Expression.toString(expr)});
        then fail();
    end match;
  end getChildren;

  function isLeaf
    input Expression expr;
    output Boolean result;
  algorithm
    result := match expr
      case Expression.REAL() then true;
      case Expression.CREF() then true;
      else then false;
    end match;
  end isLeaf;

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

  function gradientEntryToString
    input GradientEntry entry;
    output String str;
  protected
    Expression key, value;
  algorithm
    (key, value) := entry;
    str := "d/d(" + expressionToString(key) + ") = " + expressionToString(value);
  end gradientEntryToString;

  // To-string for GradientMap
  function gradientMapToString
    input GradientMap grads;
    output String str;
  protected
    Boolean first = true;
  algorithm
    str := "{";
    for entry in grads loop
      if first then
        first := false;
      else
        str := str + ", ";
      end if;
      str := str + gradientEntryToString(entry);
    end for;
    str := str + "}";
  end gradientMapToString;

  // Check if expression is in visited list
  function isVisited
    input Expression expr;
    input list<Expression> visited;
    output Boolean result;
  algorithm
    result := false;
    for v in visited loop
      if expressionEqual(expr, v) then
        result := true;
        return;
      end if;
    end for;
  end isVisited;

  // Build computation tape in post-order traversal
  function buildTape
    input Expression expr;
    output list<Expression> tape;
  algorithm
    tape := buildTapeHelper(expr, {}, {});
  end buildTape;

  // Helper function for building tape with visited tracking
  function buildTapeHelper
    input Expression expr;
    input list<Expression> currentTape;
    input list<Expression> visited;
    output list<Expression> tape;
  protected
    list<Expression> children;
  algorithm
    // Check if already processed
    if isVisited(expr, visited) then
      tape := currentTape;
      return;
    end if;
    
    // Process children first (post-order)
    tape := currentTape;
    children := getChildren(expr);
    
    for child in children loop
      tape := buildTapeHelper(child, tape, expr :: visited);
    end for;
    
    // Add current expression to tape
    tape := expr :: tape;
  end buildTapeHelper;

  // Helper function to check if expression is zero constant
  function isZeroConstant
    input Expression expr;
    output Boolean result;
  algorithm
    result := Expression.isZero(expr);
  end isZeroConstant;

  // Simplification rules for algebraic expressions
  function simplify
    input Expression expr;
    output Expression simplified;
  algorithm
    simplified := SimplifyExp.simplify(expr);
  end simplify;

  // Gradient map as list of tuples
  type GradientEntry = tuple<Expression, Expression>;
  type GradientMap = list<GradientEntry>;

  // Find gradient for a specific expression in gradient map
  function findGradient
    input Expression expr;
    input GradientMap grads;
    output Expression grad;
  protected
    Expression key, value;
  algorithm
    grad := Expression.REAL(0.0);  // Default to zero
    for entry in grads loop
      (key, value) := entry;
      if expressionEqual(key, expr) then
        grad := value;
        return;
      end if;
    end for;
  end findGradient;

  // Update gradient map with new gradient for expression
  function updateGradient
    input Expression expr;
    input Expression newGrad;
    input GradientMap grads;
    output GradientMap updatedGrads;
  protected
    Expression existingGrad, combinedGrad;
    Boolean found;
    Expression key, value;
  algorithm
    updatedGrads := {};
    found := false;
    
    for entry in grads loop
      (key, value) := entry;
      if expressionEqual(key, expr) then
        existingGrad := value;
        combinedGrad := simplify(Expression.BINARY(existingGrad, Operator.makeAdd(Type.REAL()), newGrad));
        updatedGrads := (expr, combinedGrad) :: updatedGrads;
        found := true;
      else
        updatedGrads := entry :: updatedGrads;
      end if;
    end for;
    
    if not found then
      updatedGrads := (expr, newGrad) :: updatedGrads;
    end if;
  end updateGradient;


  function symbolicReverseModeStrongComponent
    "Differentiate a SINGLE_COMPONENT strong component in reverse mode.
     Builds residual expression (lhs - rhs) and reuses symbolicReverseMode.
     Currently only supports StrongComponent.SINGLE_COMPONENT with SCALAR_EQUATION."
    input StrongComponent comp;
    input Expression cotangent = Expression.REAL(1.0);
    output GradientMap gradients;
  protected
    Pointer<NBEquation.Equation> eq_ptr;
    NBEquation.Equation eq;
    Expression lhs, rhs, residual;
    Type ty;
    Operator subOp;
    StrongComponent c = comp;
  algorithm
    c := StrongComponent.removeAlias(c);
    // Use equation pointer directly; do not require EXPLICIT status
    eq_ptr := match c
      case StrongComponent.SINGLE_COMPONENT() then c.eqn;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,
          {getInstanceName() + ": symbolicReverseModeStrongComponent currently only supports SINGLE_COMPONENT."});
      then fail();
    end match;

    eq := Pointer.access(eq_ptr);

    // Only scalar equations supported for now; extract RHS
    rhs := match eq
      case NBEquation.Equation.SCALAR_EQUATION() then NBEquation.Equation.getRHS(eq);
      case NBEquation.Equation.ARRAY_EQUATION() then NBEquation.Equation.getRHS(eq);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,
          {getInstanceName() + ": symbolicReverseModeStrongComponent currently only supports SCALAR_EQUATION."});
      then fail();
    end match;

    gradients := symbolicReverseMode(rhs, cotangent);
  end symbolicReverseModeStrongComponent;

  // Main function: Symbolic reverse-mode differentiation
  function symbolicReverseMode
    input Expression expr;
    input Expression cotangent = Expression.REAL(1.0);
    output GradientMap gradients;
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

    // Initialize gradients with output gradient
    gradients := {(expr, cotangent)};
    
    // Process tape in reverse order
    for operation in tape loop // no need to reverse as tape is built by prepending to it
      currentGrad := findGradient(operation, gradients);
      
      // Skip if no gradient for this operation
      if isZeroConstant(currentGrad) then
        continue;
      end if;
      
      children := getChildren(operation);
      
      // Propagate gradients to children using chain rule
      i := 1;
      for child in children loop
        localGrad := localGradient(operation, i);
        childGrad := simplify(Expression.BINARY(currentGrad, Operator.makeMul(Type.REAL()), localGrad));
        gradients := updateGradient(child, childGrad, gradients);
        i := i + 1;
      end for;
    end for;
  end symbolicReverseMode;

  annotation(__OpenModelica_Interface="backend");
end NBDifferentiateReverse;