encapsulated package NBDifferentiateReverse_new
"file:        NBDifferentiateReverse_new.mo
 package:     NBDifferentiateReverse_new
 description: Tape-based symbolic reverse mode AD using Node records that
              reference children by tape index and store local partials.
 notes:       Currently supports REAL literals, CREFs, BINARY ops (ADD, SUB, MUL, DIV, POW (in quotient rule part)),
              and builtin unary/binary calls already handled by NBDifferentiate.* helpers.
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
    Expression x, y, expr, mulXY, mul2, mul3;
    GradientMap grads;
    Expression gradX, gradY;
  algorithm
    // Create test expression: f(x, y) = 2*y + 3*(x*y)
    x := Expression.CREF(Type.REAL(),
                         ComponentRef.CREF(InstNode.NAME_NODE("x"), {}, Type.REAL(), Origin.CREF, ComponentRef.EMPTY()));
    y := Expression.CREF(Type.REAL(),
                         ComponentRef.CREF(InstNode.NAME_NODE("y"), {}, Type.REAL(), Origin.CREF, ComponentRef.EMPTY()));

    mulXY := Expression.BINARY(exp1 = x, operator = Operator.makeMul(Type.REAL()), exp2 = y);
    mul2  := Expression.BINARY(exp1 = Expression.REAL(2.0), operator = Operator.makeMul(Type.REAL()), exp2 = y);
    mul3  := Expression.BINARY(exp1 = Expression.REAL(3.0), operator = Operator.makeMul(Type.REAL()), exp2 = mulXY);
    expr  := Expression.BINARY(exp1 = mul2, operator = Operator.makeAdd(Type.REAL()), exp2 = mul3);

    grads := symbolicReverseMode(expr);

    gradX := findGradient(x, grads); // expected: 3*y
    gradY := findGradient(y, grads); // expected: 2 + 3*x

    print("Expression: " + expressionToString(expr) + "\n");
    print("Gradient w.r.t. x: " + expressionToString(gradX) + "\n");
    print("Gradient w.r.t. y: " + expressionToString(gradY) + "\n");

    success := true;
  end testBasicDifferentiation;

protected
  import Expression = NFExpression;
  import Operator   = NFOperator;
  import Op         = NFOperator.Op;
  import Type       = NFType;
  import SimplifyExp = NFSimplifyExp;
  import InstNode   = NFInstNode;
  import ComponentRef = NFComponentRef;
  import Origin     = NFComponentRef.Origin;
  import NFBuiltinFuncs;
  import Call       = NFCall;
  import AbsynUtil;
  import NFFunction.{Function, Slot};
  import NBDifferentiate;

  // Node for tape: local partials to each child + indices to children
  record Node
    list<Expression> childGradients; // df/dchild_i
    list<Integer> childIndices;      // indices into tape (1-based)
  end Node;

  // Gradient map type (keep public-style)
  type GradientEntry = tuple<Expression, Expression>;
  type GradientMap   = list<GradientEntry>;

  //------------------------------------------------------------------
  // Utility / equality / string
  //------------------------------------------------------------------

  function expressionEqual
    input Expression expr1;
    input Expression expr2;
    output Boolean equal;
  algorithm
    equal := Expression.isEqual(expr1, expr2);
  end expressionEqual;

  function expressionToString
    input Expression expr;
    output String str;
  algorithm
    str := Expression.toString(expr);
  end expressionToString;

  function simplify
    input Expression expr;
    output Expression simplified;
  algorithm
    simplified := SimplifyExp.simplify(expr);
  end simplify;

  function addExpr
    input Expression a;
    input Expression b;
    output Expression c;
  algorithm
    c := simplify(Expression.BINARY(a, Operator.makeAdd(Type.REAL()), b));
  end addExpr;

  function mulExpr
    input Expression a;
    input Expression b;
    output Expression c;
  algorithm
    c := simplify(Expression.BINARY(a, Operator.makeMul(Type.REAL()), b));
  end mulExpr;

  function isZeroConstant
    input Expression expr;
    output Boolean result;
  algorithm
    result := Expression.isZero(expr);
  end isZeroConstant;

  //------------------------------------------------------------------
  // Child extraction
  //------------------------------------------------------------------

  function getChildren
    input Expression expr;
    output list<Expression> children;
  protected
    Expression left_child, right_child;
    Operator op;
  algorithm
    children := match expr
      case Expression.REAL() then {};
      case Expression.CREF() then {};
      case Expression.BINARY(exp1 = left_child, operator = op, exp2 = right_child) then {left_child, right_child};
      case Expression.CALL() then
        match expr
          local 
            list<Expression> args;
          case Expression.CALL(call = Call.TYPED_CALL(arguments = args)) then args;
        end match;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,
          {getInstanceName() + " Unsupported expression for getChildren: " + Expression.toString(expr)});
      then fail();
    end match;
  end getChildren;

  //------------------------------------------------------------------
  // Local partial derivatives (df/dchild_i)
  //------------------------------------------------------------------

  function localPartialFor1ArgCall
    input Expression exp;
    output Expression localPartial;
  protected
    Call callv;
    Function fn;
    list<Expression> args;
  algorithm
    localPartial := match exp
      case Expression.CALL(call = callv) then
        match callv
          case Call.TYPED_CALL(fn = fn, arguments = args) guard (Function.isBuiltin(fn) and listLength(args) == 1) then
            NBDifferentiate.differentiateBuiltinCall1Arg(
              AbsynUtil.pathString(Function.nameConsiderBuiltin(fn)),
              listHead(args));
          else Expression.makeZero(Expression.typeOf(exp));
        end match;
      else Expression.makeZero(Expression.typeOf(exp));
    end match;
  end localPartialFor1ArgCall;

  function localPartialFor2ArgCall
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
            match args
              case {arg1, arg2} algorithm
                name := AbsynUtil.pathString(Function.nameConsiderBuiltin(fn));
                (p1, p2) := NBDifferentiate.differentiateBuiltinCall2Arg(name, arg1, arg2);
              then (if childIndex == 1 then p1 else p2);
              else Expression.makeZero(Expression.typeOf(exp));
            end match;
          else Expression.makeZero(Expression.typeOf(exp));
        end match;
      else Expression.makeZero(Expression.typeOf(exp));
    end match;
  end localPartialFor2ArgCall;

  function localGradientOne
    "Local derivative df/d(childIndex) for supported kinds."
    input Expression expr;
    input Integer childIndex;
    output Expression grad;
  protected
    Expression left_child, right_child;
    Operator op;
  algorithm
    grad := match expr
      case Expression.REAL() then Expression.REAL(0.0);
      case Expression.CREF() then Expression.REAL(1.0);
      case Expression.BINARY(exp1 = left_child, operator = op, exp2 = right_child) then
        match op.op
          case Op.ADD then Expression.REAL(1.0);
          case Op.SUB then if childIndex == 1 then Expression.REAL(1.0) else Expression.REAL(-1.0);
          case Op.MUL then if childIndex == 1 then right_child else left_child;
          case Op.DIV then
            if childIndex == 1 then
              Expression.BINARY(Expression.REAL(1.0), Operator.makeDiv(Type.REAL()), right_child)
            else
              Expression.negate(
                Expression.BINARY(
                  left_child, Operator.makeDiv(Type.REAL()),
                  Expression.BINARY(right_child, Operator.makePow(Type.REAL()), Expression.REAL(2.0))
                )
              );
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,
              {getInstanceName() + " Unsupported binary operator in localGradientOne: " + Operator.symbol(op)});
          then fail();
        end match;
      case Expression.CALL() guard List.hasOneElement(Call.arguments(expr.call)) then
        localPartialFor1ArgCall(expr);

      case Expression.CALL() guard (listLength(Call.arguments(expr.call)) == 2) then
        localPartialFor2ArgCall(expr, childIndex);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,
          {getInstanceName() + " Unsupported expression in localGradientOne: " + Expression.toString(expr)});
      then fail();
    end match;
  end localGradientOne;

  function localGradientsAll
    "Return list of local partials df/dchild_i in the same order as getChildren(expr)."
    input Expression expr;
    output list<Expression> partials;
  protected
    list<Expression> children;
    list<Expression> acc = {};
    Integer i;
  algorithm
    children := getChildren(expr);
    i := 1;
    for c in children loop
      acc := localGradientOne(expr, i) :: acc;
      i := i + 1;
    end for;
    partials := listReverse(acc);
  end localGradientsAll;

  //------------------------------------------------------------------
  // Tape construction with memoization
  //------------------------------------------------------------------

  // Mapping expression -> index
  type ExprIndexEntry = tuple<Expression, Integer>;

  function lookupExprIndex
    input Expression expr;
    input list<ExprIndexEntry> mapping;
    output Integer idx; // 0 if not found
  protected
    Expression key;
    Integer val;
  algorithm
    idx := 0;
    for e in mapping loop
      (key, val) := e;
      if expressionEqual(expr, key) then
        idx := val;
        return;
      end if;
    end for;
  end lookupExprIndex;

  function buildTape
    "Builds a tape (topological order) of unique subexpressions.
     Returns tape nodes, list of expressions (parallel to tape), and index of root expression."
    input Expression root;
    output list<Node> tape;
    output list<Expression> exprs;
    output Integer rootIndex;
  algorithm
    (tape, exprs, {}, rootIndex) := buildTapeRec(root, {}, {}, {}, 0);
  end buildTape;

  function buildTapeRec
    input Expression expr;
    input list<Node> tapeIn;
    input list<Expression> exprsIn;
    input list<ExprIndexEntry> mapIn;
    input Integer countIn;
    output list<Node> tapeOut;
    output list<Expression> exprsOut;
    output list<ExprIndexEntry> mapOut;
    output Integer index;
  protected
    Integer existing;
    list<Expression> children;
    list<Integer> childIdxs = {};
    list<Expression> childPars;
    list<Node> tapeAcc;
    list<Expression> exprsAcc;
    list<ExprIndexEntry> mapAcc;
    Integer countAcc;
    Integer childIndex;
  algorithm
    // Check if already on tape
    existing := lookupExprIndex(expr, mapIn);
    if existing <> 0 then
      tapeOut := tapeIn;
      exprsOut := exprsIn;
      mapOut := mapIn;
      index := existing;
      return;
    end if;

    // Process children first
    tapeAcc := tapeIn;
    exprsAcc := exprsIn;
    mapAcc := mapIn;
    countAcc := countIn;

    children := getChildren(expr);
    for c in children loop
      (tapeAcc, exprsAcc, mapAcc, childIndex) := buildTapeRec(c, tapeAcc, exprsAcc, mapAcc, countAcc);
      countAcc := childIndex; // last assigned index
      childIdxs := childIndex :: childIdxs;
    end for;
    childIdxs := listReverse(childIdxs);

    // Compute local partials for this expr
    childPars := localGradientsAll(expr);

    // Create node
    index := countAcc + 1;
    tapeOut := tapeAcc;
    exprsOut := exprsAcc;
    mapOut := mapAcc;

    tapeOut := listAppend(tapeOut, {Node(childPars, childIdxs)});
    exprsOut := listAppend(exprsOut, {expr});
    mapOut := (expr, index) :: mapOut;
  end buildTapeRec;

  //------------------------------------------------------------------
  // Gradient accumulation
  //------------------------------------------------------------------

  function symbolicReverseMode
    input Expression expr;
    input Expression cotangent = Expression.REAL(1.0);
    output GradientMap gradients;
  protected
    list<Node> tapeList;
    list<Expression> exprList;
    Integer rootIdx;
    Integer n;
    Integer i;
    array<Node> tapeArr;
    array<Expression> exprArr;
    array<Expression> gradArr;
    Node node;
    list<Integer> childIdxs;
    list<Expression> childLocals;
    Expression gCurrent;
    Expression localPart;
    Integer cIdx;
    list<Expression> remainingLocals;
    list<Integer> remainingIdxs;
    Expression childContribution;
  algorithm
    (tapeList, exprList, rootIdx) := buildTape(expr);

    n := listLength(tapeList);
    tapeArr := listArray(tapeList);
    exprArr := listArray(exprList);
    gradArr := listArray(list(Expression.REAL(0.0) for i in 1:n));

    // root should be last node if topological append order was preserved
    if rootIdx <> n then
      // Just a sanity message, not fatal
      print("Warning: root index " + intString(rootIdx) + " != tape size " + intString(n) + "\n");
    end if;

    gradArr[rootIdx] := cotangent;

    print("Computation tape (topological order):\n");
    for i in 1:n loop
      print(intString(i) + ": " + expressionToString(exprArr[i]) + "\n");
    end for;

    // Reverse pass
    for i in n:-1:1 loop
      gCurrent := gradArr[i];
      if isZeroConstant(gCurrent) then
        continue;
      end if;

      node := tapeArr[i];
      childLocals := node.childGradients;
      childIdxs   := node.childIndices;

      // Iterate zipped lists
      remainingLocals := childLocals;
      remainingIdxs   := childIdxs;

      while not listEmpty(remainingIdxs) loop
        cIdx := listHead(remainingIdxs);
        remainingIdxs := listRest(remainingIdxs);

        localPart := listHead(remainingLocals);
        remainingLocals := listRest(remainingLocals);

        childContribution := mulExpr(gCurrent, localPart);
        // Accumulate: gradArr[cIdx] += childContribution
        gradArr[cIdx] := addExpr(gradArr[cIdx], childContribution);
      end while;
    end for;

    // Build gradient map (all tape entries)
    gradients := {};
    for i in 1:n loop
      gradients := (exprArr[i], gradArr[i]) :: gradients;
    end for;
  end symbolicReverseMode;

  //------------------------------------------------------------------
  // Public gradient lookup (unchanged interface)
  //------------------------------------------------------------------
  function findGradient
    input Expression expr;
    input GradientMap grads;
    output Expression grad;
  protected
    Expression key, value;
  algorithm
    grad := Expression.REAL(0.0);
    for entry in grads loop
      (key, value) := entry;
      if expressionEqual(key, expr) then
        grad := value;
        return;
      end if;
    end for;
  end findGradient;

  annotation(__OpenModelica_Interface="backend");
end NBDifferentiateReverse_new;