encapsulated package NBDifferentiateReverse
"file:        NBDifferentiateReverse.mo
 package:     NBDifferentiateReverse
 description: This file contains the functions to differentiate equations and
              expressions symbolically in reverse mode e.g. to generate adjoint jacobians.
 only support REAL, BINARY, UNARY expressions and the five basic BINARY arithmetic ops ADD, SUB, MUL, DIV, (POW) for the type REAL
 How to handle the UNARY ops NEG, SIN, COS as they are no Expressions or Operators?
"

  public function testBasicDifferentiation
      input Real dummy;
      output Boolean success;
    protected
      Expression x, y, expr;
      GradientMap grads;
      Expression gradX, gradY;
    algorithm
      // Create test expression: f(x, y) = x * sin(y)
      x := Expression.CREF(Type.REAL(), 
                          ComponentRef.CREF(InstNode.NAME_NODE("x"), {}, Type.REAL(), Origin.CREF, ComponentRef.EMPTY()));
      y := Expression.CREF(Type.REAL(),
                          ComponentRef.CREF(InstNode.NAME_NODE("y"), {}, Type.REAL(), Origin.CREF, ComponentRef.EMPTY()));
      expr := Expression.BINARY(exp1 = x, operator = Operator.makeMul(Type.REAL()), exp2 = y);
      
      // Compute gradients
      grads := symbolicReverseMode(expr);
      
      gradX := findGradient(x, grads);
      gradY := findGradient(y, grads);

      print("Expression: " + expressionToString(expr) + "\n");
      print("Gradient w.r.t. x: " + expressionToString(gradX) + "\n");
      print("Gradient w.r.t. y: " + expressionToString(gradY) + "\n");

      success := true;
  end testBasicDifferentiation;

protected
  import Expression = NFExpression;
  import Operator = NFOperator;
  import Op = NFOperator.Op;
  import Type = NFType;
  import SimplifyExp = NFSimplifyExp;
  import InstNode = NFInstNode;
  import ComponentRef = NFComponentRef;
  import Origin = NFComponentRef.Origin;

  function localGradient
    input Expression expr;
    input Integer childIndex;
    output Expression grad;
  protected
    Expression left_child, right_child;
    Operator op;
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

          case Op.DIV then
            if childIndex == 1 then
              Expression.BINARY(Expression.REAL(1.0), Operator.makeDiv(Type.REAL()), right_child) // ∂(a / b)/∂a = 1/b
            else
              Expression.negate(Expression.BINARY(left_child, Operator.makeDiv(Type.REAL()), 
                                Expression.BINARY(right_child, Operator.makePow(Type.REAL()), Expression.REAL(2.0)))); //∂(a / b)/∂b = -a/(b^2)

          else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + "Failed! Given Operator is not supported." + Operator.symbol(op)});
          then fail();
        end match;
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
  algorithm
    children := match expr
        case Expression.REAL() then {};
        case Expression.CREF() then {};
        case Expression.BINARY(exp1 = left_child, operator = op, exp2 = right_child) then {left_child, right_child};
        // case UNARY(operator = op, exp = child) then {child};
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + "Failed! Given Expression is not supported." + Expression.toString(expr)});
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
      case Expression.BINARY() then false;
      else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + "Failed! Given Expression is not supported." + Expression.toString(expr)});
      then fail();
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
    
    // For leaf nodes, don't add to tape
    if isLeaf(expr) then
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
    
    // Initialize gradients with output gradient
    gradients := {(expr, cotangent)};
    
    // Process tape in reverse order
    for operation in listReverse(tape) loop // is the listReverse needed?
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