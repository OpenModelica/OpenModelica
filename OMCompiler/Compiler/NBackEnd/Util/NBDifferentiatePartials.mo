/*
 * Utility for collecting partial derivatives (gradient) of a component or equation
 * by reusing NBDifferentiate in SIMPLE mode per input cref.
 *
 * Example:
 *   z = a * x + b * x * y
 * Produces:
 *   a -> x
 *   x -> a + b * y
 *   y -> b * x
 *   b -> x * y
 */

encapsulated package NBDifferentiatePartials
  import Absyn;
  import AbsynUtil;
  import UnorderedMap;
  import Util;

  // NF
  import Expression = NFExpression;
  import ComponentRef = NFComponentRef;
  import Type = NFType;
  import Operator = NFOperator;

  // Functions
  import NFFunction.{Function, Slot};
  import NFFlatten.{FunctionTree, FunctionTreeImpl};

  // Backend
  import NBEquation.{Equation, EquationPointer};
  import NBStrongComponent;
  import NBVariable;
  import NBDifferentiate;
  import NBSlice;

  // Util
  import NFSimplifyExp;

public
  // Map: input variable cref -> partial derivative of outputCref wrt. that input cref
  type PartialMap = UnorderedMap<ComponentRef, Expression>;
  // Map output cref -> its PartialMap (used for chaining via chain rule)
  type PartialsEnv = UnorderedMap<ComponentRef, PartialMap>;

  function partialMapToString
    input PartialMap partials;
    output String str;
  protected
    list<ComponentRef> keys;
    ComponentRef k;
    Expression v;
    Boolean first = true;
  algorithm
    keys := UnorderedMap.keyList(partials);

    str := "{";
    for k in keys loop
      v := UnorderedMap.getSafe(k, partials, sourceInfo());
      if first then
        first := false;
      else
        str := str + ", ";
      end if;
      str := str + ComponentRef.toString(k) + " -> " + Expression.toString(v);
    end for;
    str := str + "}";
  end partialMapToString;

  uniontype PartialsForComponent
    record PARTIALS_FOR_COMPONENT
      ComponentRef outputCref; // lhs of the equation, may be EMPTY() if not a simple assignment
      PartialMap partials;     // d(outputCref)/d(inputCref) for all inputCrefs in the rhs
    end PARTIALS_FOR_COMPONENT;

    function toString
      input PartialsForComponent p;
      output String str;
    algorithm
      str := match p
        local
          String lhsStr;
        case PARTIALS_FOR_COMPONENT() algorithm
         lhsStr := if ComponentRef.isEmpty(p.outputCref) then "<residual>" else ComponentRef.toString(p.outputCref);
          str := lhsStr + ": " + partialMapToString(p.partials);
          then str;
      end match;
    end toString;
  end PartialsForComponent;

  // Entry points

  function computePartialsForStrongComponent
    "Compute partial derivatives of the output(s) w.r.t. all input crefs used in the component's equation(s).
     Currently supports SINGLE_COMPONENT and GENERIC_COMPONENT with scalar equations."
    input NBStrongComponent.StrongComponent comp;
    input FunctionTree funcTree = FunctionTreeImpl.EMPTY();
    output list<PartialsForComponent> results;
  protected
    NBStrongComponent.StrongComponent compNoAlias;
  algorithm
    compNoAlias := NBStrongComponent.StrongComponent.removeAlias(comp); // better aliased handling later
    results := match compNoAlias
      local
        Equation eq;
        Expression lhs, rhs;
        ComponentRef outputCref;
        PartialsForComponent res;
        list<PartialsForComponent> acc = {};
      // Single scalar equation component: [var, eqn]
      case NBStrongComponent.StrongComponent.SINGLE_COMPONENT()
      algorithm
        eq := Pointer.access(compNoAlias.eqn);
        (outputCref, rhs) := getOutputAndRhs(eq);
        res := PARTIALS_FOR_COMPONENT(outputCref, computePartialsForExpression(rhs, funcTree));
      then {res};

    //   // Generic with single eqn slice pointing to a scalar equation
    //   case NBStrongComponent.StrongComponent.GENERIC_COMPONENT()
    //   algorithm
    //     eq := NBEquation.EquationPointer.access(NBSlice.Slice.getT(comp.eqn));
    //     (outputCref, rhs) := getOutputAndRhs(eq);
    //     res := PARTIALS_FOR_COMPONENT(outputCref, computePartialsForExpression(rhs, funcTree));
    //   then {res};

    //   // For sliced/multi/resizable components, collect per sliced equation.
    //   // You can extend this to handle arrays/records by iterating the slices and elements.
    //   case NBStrongComponent.StrongComponent.MULTI_COMPONENT()
    //   algorithm
    //     for eqs in list(comp.eqn) loop
    //       eq := NBEquation.EquationPointer.access(NBSlice.Slice.getT(eqs));
    //       (outputCref, rhs) := getOutputAndRhs(eq);
    //       res := PARTIALS_FOR_COMPONENT(outputCref, computePartialsForExpression(rhs, funcTree));
    //       acc := res :: acc;
    //     end for;
    //   then listReverse(acc);

    //   case NBStrongComponent.StrongComponent.SLICED_COMPONENT()
    //   algorithm
    //     eq := NBEquation.EquationPointer.access(NBSlice.Slice.getT(comp.eqn));
    //     (outputCref, rhs) := getOutputAndRhs(eq);
    //     res := PARTIALS_FOR_COMPONENT(outputCref, computePartialsForExpression(rhs, funcTree));
    //   then {res};

    //   case NBStrongComponent.StrongComponent.RESIZABLE_COMPONENT()
    //   algorithm
    //     eq := NBEquation.EquationPointer.access(NBSlice.Slice.getT(comp.eqn));
    //     (outputCref, rhs) := getOutputAndRhs(eq);
    //     res := PARTIALS_FOR_COMPONENT(outputCref, computePartialsForExpression(rhs, funcTree));
    //   then {res};

      // Algebraic loops and entwined components can be expanded similarly by iterating inner/residual eqns.
      else {};
    end match;
  end computePartialsForStrongComponent;

  function computePartialsForComponentsChained
    "Fold a list of components, chaining partials across them (in order)."
    input list<NBStrongComponent.StrongComponent> comps;
    input FunctionTree funcTree = FunctionTreeImpl.EMPTY();
    output list<list<PartialsForComponent>> allResults = {};
  protected
    PartialsEnv env = UnorderedMap.new<PartialMap>(ComponentRef.hash, ComponentRef.isEqual);
    list<PartialsForComponent> res;
    NBStrongComponent.StrongComponent c;
  algorithm
    for c in comps loop
      res := computePartialsForStrongComponent(c, funcTree);
      allResults := res :: allResults;
    end for;
  end computePartialsForComponentsChained;

  function computePartialsForEquationPointer
    "Compute partials for a scalar equation pointer (lhs=scalar cref) using the RHS."
    input EquationPointer eq_ptr;
    input FunctionTree funcTree = FunctionTreeImpl.EMPTY();
    output ComponentRef outputCref;
    output PartialMap partials;
  protected
    Equation eq;
    Expression rhs;
  algorithm
    eq := Pointer.access(eq_ptr);
    (outputCref, rhs) := getOutputAndRhs(eq);
    partials := computePartialsForExpression(rhs, funcTree);
  end computePartialsForEquationPointer;

  function computePartialsForExpression
    "Compute map var -> ∂(exp)/∂var by reusing NBDifferentiate in SIMPLE mode per input cref."
    input Expression exp;
    input FunctionTree funcTree = FunctionTreeImpl.EMPTY();
    output PartialMap partials;
  protected
    list<ComponentRef> inputs;
    NBDifferentiate.DifferentiationArguments diffArgs;
    Expression dExp;
  algorithm
    // 1) Collect all candidate input crefs occurring in the expression
    inputs := uniqueCrefs(exp);

    // 2) Build map input -> partial derivative
    partials := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);

    for v in inputs loop
      // Skip special crefs like time
      if ComponentRef.isTime(v) then
        // do not treat 'time' as an input parameter
      else
        diffArgs := NBDifferentiate.DifferentiationArguments.simpleCref(v, funcTree);
        (dExp, diffArgs) := NBDifferentiate.differentiateExpression(exp, diffArgs);
        // Optional simplification
        dExp := NFSimplifyExp.simplifyDump(dExp, true, "NBDifferentiatePartials");
        UnorderedMap.add(v, dExp, partials);
      end if;
    end for;
  end computePartialsForExpression;

protected
  function addExpr
    input Expression a;
    input Expression b;
    output Expression s;
  protected
    Operator addOp = Operator.fromClassification(
      (NFOperator.MathClassification.ADDITION, NFOperator.SizeClassification.SCALAR),
      Type.REAL()
    );
  algorithm
    if Expression.isZero(a) then
      s := b;
    elseif Expression.isZero(b) then
      s := a;
    else
      s := NFSimplifyExp.simplifyDump(Expression.MULTARY({a, b}, {}, addOp), true, "NBDifferentiatePartials");
    end if;
  end addExpr;

  function mulExpr
    input Expression a;
    input Expression b;
    output Expression p;
  protected
    Operator mulOp = Operator.fromClassification(
      (NFOperator.MathClassification.MULTIPLICATION, NFOperator.SizeClassification.SCALAR),
      Type.REAL()
    );
  algorithm
    if Expression.isZero(a) or Expression.isZero(b) then
      p := Expression.makeZero(Type.REAL());
    else
      p := NFSimplifyExp.simplifyDump(Expression.MULTARY({a, b}, {}, mulOp), true, "NBDifferentiatePartials");
    end if;
  end mulExpr;

  function getOutputAndRhs
    "Extract output cref (lhs) and rhs expression from a scalar equation.
     If lhs isn't a cref, output cref is set to ComponentRef.EMPTY()."
    input Equation eq;
    output ComponentRef outputCref;
    output Expression rhs;
  algorithm
    (outputCref, rhs) := match eq
      local
        Expression lhsE, rhsE;
      case NBEquation.Equation.SCALAR_EQUATION(lhs = lhsE, rhs = rhsE)
      algorithm
        outputCref := match lhsE
          case Expression.CREF() then lhsE.cref;
          else ComponentRef.EMPTY();
        end match;
      then (outputCref, rhsE);

      // Extend here for RECORD_EQUATION/ARRAY_EQUATION if you want element-wise gradients.
      else algorithm
        // Fallback: treat entire equation as residual lhs - rhs and use rhs
        // but mark output as empty if not a simple scalar assignment
        outputCref := ComponentRef.EMPTY();
        rhs := getRhsFromAny(eq);
      then (outputCref, rhs);
    end match;
  end getOutputAndRhs;

  function getRhsFromAny
    "Best-effort to get an RHS-like expression; for unsupported equations just return zero."
    input Equation eq;
    output Expression rhs;
  algorithm
    rhs := match eq
      case NBEquation.Equation.SCALAR_EQUATION(rhs = rhs) then rhs;
      else Expression.REAL(0.0);
    end match;
  end getRhsFromAny;

  function uniqueCrefs
    "Collect all crefs occurring in exp (deduplicated)."
    input Expression exp;
    output list<ComponentRef> crefs;
  protected
    UnorderedMap<ComponentRef, Boolean> map = UnorderedMap.new<Boolean>(ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    collectCrefs(exp, map);
    crefs := UnorderedMap.keyList(map);
  end uniqueCrefs;

  function collectCrefs
    "Recursive walker that adds crefs to set for later dedup."
    input Expression exp;
    input output UnorderedMap<ComponentRef, Boolean> set;
  algorithm
    () := match exp
      local
        Expression e1, e2;
        array<Expression> lst;
        list<list<Expression>> mat;
      case Expression.CREF() algorithm
        UnorderedMap.add(exp.cref, true, set);
      then ();

      case Expression.ARRAY(elements = lst) algorithm
        for e1 in lst loop collectCrefs(e1, set); end for;
      then ();

      case Expression.MATRIX(elements = mat) algorithm
        for row in mat loop for e1 in row loop collectCrefs(e1, set); end for; end for;
      then ();

    //   case Expression.TUPLE(elements = lst) algorithm
    //     for e1 in lst loop collectCrefs(e1, set); end for;
    //   then ();

    //   case Expression.RECORD(elements = lst) algorithm
    //     for e1 in lst loop collectCrefs(e1, set); end for;
    //   then ();

    //   case Expression.CALL() algorithm
    //     for e1 in NFBuiltinFuncs.getCallArguments(exp.call) loop
    //       collectCrefs(e1, set);
    //     end for;
    //   then ();

    //   case Expression.IF(trueBranch = e1, falseBranch = e2) algorithm
    //     collectCrefs(e1, set);
    //     collectCrefs(e2, set);
    //   then ();

      case Expression.BINARY(exp1 = e1, exp2 = e2) algorithm
        collectCrefs(e1, set);
        collectCrefs(e2, set);
      then ();

      case Expression.MULTARY() algorithm
        for e1 in exp.arguments loop collectCrefs(e1, set); end for;
        for e1 in exp.inv_arguments loop collectCrefs(e1, set); end for;
      then ();

      case Expression.UNARY(exp = e1) algorithm
        collectCrefs(e1, set);
      then ();

      case Expression.CAST(exp = e1) algorithm
        collectCrefs(e1, set);
      then ();

      case Expression.BOX(exp = e1) algorithm
        collectCrefs(e1, set);
      then ();

      case Expression.UNBOX(exp = e1) algorithm
        collectCrefs(e1, set);
      then ();

    //   case Expression.SUBSCRIPTED_EXP(exp = e1) algorithm
    //     collectCrefs(e1, set);
    //     // subscripts may also contain expressions; collect those too
    //     for s in exp.subscripts loop
    //       () := match s
    //         local Expression sExp;
    //         case NFSubscript.Subscript.INDEX(exp = sExp) algorithm
    //           collectCrefs(sExp, set);
    //         then ();
    //         else ();
    //       end match;
    //     end for;
    //   then ();

    //   case Expression.TUPLE_ELEMENT(tupleExp = e1) algorithm
    //     collectCrefs(e1, set);
    //   then ();

    //   case Expression.RECORD_ELEMENT(recordExp = e1) algorithm
    //     collectCrefs(e1, set);
    //   then ();

      else ();
    end match;
  end collectCrefs;

  annotation(__OpenModelica_Interface="backend");
end NBDifferentiatePartials;