encapsulated package NBSeedGather
  "Utilities to gather seed coefficients from differentiated equations."
  protected
    import NBJacobian;
    import NBEquation;
    import Variable = NFVariable;
    import ComponentRef = NFComponentRef;
    import Expression = NFExpression;
    import Operator = NFOperator;
    import Type = NFType;
    import StringUtil;
    import NFOperator.Op;
    import NBEquation.{Equation, EquationPointers, EqData};

    import BackendDAE = NBackendDAE;
    import StrongComponent = NBStrongComponent;
    import BVariable = NBVariable;
    import VariablePointers = NBVariable.VariablePointers;
    import UnorderedSet;
    import UnorderedMap;

public
  public function testGatherInJacobian
    "Iterate jacobian strong components, gather seed coefficients per equation.
     Call after a jacobian is built (e.g. from NBJacobian.jacobianSymbolicAdjoint or jacobianSymbolic).
     Set maxEq to limit output volume."
    input BackendDAE jac;
    input Integer maxEq = 20;
  protected
    UnorderedSet<ComponentRef> validSeeds;
    array<StrongComponent> compsArr;
    VariablePointers seedVP;
    list<ComponentRef> seedCrefs;
    Integer printed = 0;
    UnorderedMap<ComponentRef, ExpressionList> map;
    String hdr;
  algorithm
    () := match jac
      case BackendDAE.JACOBIAN(varData = BVariable.VarData.VAR_DATA_JAC(seedVars = seedVP), comps = compsArr) algorithm
        seedCrefs := VariablePointers.getVarNames(seedVP);
        validSeeds := UnorderedSet.fromList(seedCrefs, ComponentRef.hash, ComponentRef.isEqual);

        print(StringUtil.headline_2("NBSeedGather.testGatherInJacobian") + "\n");
        print("Total strong components: " + intString(arrayLength(compsArr)) + "\n");
        print("Seed variables considered (" + intString(listLength(seedCrefs)) + "): "
              + ComponentRef.listToString(seedCrefs) + "\n\n");

        for i in 1:arrayLength(compsArr) loop
          if printed >= maxEq then
            print("\n[stopping after " + intString(maxEq) + " equations]\n");
            break;
          end if;
          () := match compsArr[i]
            local
              Pointer<Equation> eqPtr;
              Pointer<Variable> vptr;
            // Only handle explicit single-component equations
            case NBStrongComponent.SINGLE_COMPONENT(eqn = eqPtr) algorithm
              map := gatherFromEquation(eqPtr, validSeeds);
              if UnorderedMap.size(map) > 0 then
                printed := printed + 1;
                hdr := "Eq#" + intString(printed) + " (component index " + intString(i) + ")";
                printSeedFactorMap(map, hdr);
              end if;
            then ();
            else ();
          end match;
        end for;

        if printed == 0 then
          print("<No seed factors gathered>\n");
        end if;
      then ();
      else algorithm
        print("testGatherInJacobian: Not a JACOBIAN backend DAE.\n");
      then ();
    end match;
  end testGatherInJacobian;

  // Convenience wrapper for a pDER equation pointer (if you want to call from existing code)
  public function gatherFromEquation
    input Pointer<Equation> eqPtr;
    input UnorderedSet<ComponentRef> validSeeds;
    output UnorderedMap<ComponentRef, ExpressionList> map;
  protected
    Equation eqn = Pointer.access(eqPtr);
    Expression rhs;
  algorithm
    rhs := NBEquation.Equation.getRHS(eqn);
    map := gatherSeedFactorMap(rhs, validSeeds);
  end gatherFromEquation;

protected
type ExpressionList = list<Expression>;

function sizeClassificationFromType
    input Type ty;
    output NFOperator.SizeClassification sc;
protected
    Integer rnk = Type.dimensionCount(ty);
algorithm
    sc := if rnk == 0 then 
        NFOperator.SizeClassification.SCALAR
      else if rnk == 1 then 
        NFOperator.SizeClassification.ELEMENT_WISE
      else
        NFOperator.SizeClassification.MATRIX_VECTOR;
end sizeClassificationFromType;


/**********************************************************************
   * Seed Coefficient Gathering Algorithm
   * ------------------------------------
   * For a differentiated equation:
   *   $pDER_CTX.$DER.x = a * $SEED_CTX.x - (b * $SEED_CTX.y * x + b * y * $SEED_CTX.x)
   *
   * We build a map:
   *   $SEED_CTX.x -> [a, - b * y]
   *   $SEED_CTX.y -> [- b * x]
   *
   * Also supports:
   *   A * $SEED_CTX.x          (matrix/vector)
   *   $SEED_CTX.x              (coefficient 1)
   *   a * $pDER_CTX.q          (treat $pDER like seed to propagate temp dependencies)
   *   -b * y * $SEED_CTX.x     (negative factors)
   *   (d * $SEED_CTX.y * x + d * y * $SEED_CTX.x) + c * $SEED_CTX.y + $SEED_CTX.z
   * Array / element-wise products are preserved in coefficients exactly as found.
   **********************************************************************/

  // Detect if a cref is a seed ($SEED_*) or a pDer ($pDER_*) variable.
  function isSeedOrPDerCref
    input ComponentRef cref;
    output Boolean b;
  protected
    String s = ComponentRef.toString(cref);
  algorithm
    // Cheap textual test; refine via BVariable helpers if needed.
    b := StringUtil.startsWith(s, "$SEED_") or StringUtil.startsWith(s, "$pDER_");
  end isSeedOrPDerCref;

  // Return SOME(cref) if expression is a cref to a seed/pDer, else NONE()
  function getSeedOrPDerFromExpr
    input Expression exp;
    output Option<ComponentRef> seedOpt;
  algorithm
    seedOpt := match exp
      case Expression.CREF(cref = _) guard isSeedOrPDerCref(exp.cref)
        then SOME(exp.cref);
      else NONE();
    end match;
  end getSeedOrPDerFromExpr;

  // Build a Real(1.0) constant expression
  function makeOne
    output Expression one;
  algorithm
    one := Expression.REAL(1.0);
  end makeOne;

  // Flatten additive structure into a list of additive terms (all "summed").
  function decomposeAdd
    input Expression e;
    output list<Expression> terms;
  algorithm
    terms := match e
      case Expression.MULTARY(operator = _) guard Operator.isAdd(e.operator)
        then List.flatten(list(decomposeAdd(arg) for arg in e.arguments));
      case Expression.BINARY(operator = _) guard Operator.isAdd(e.operator)
        then listAppend(decomposeAdd(e.exp1), decomposeAdd(e.exp2));
      else {e};
    end match;
  end decomposeAdd;

  // Helper: multiply remaining factors back (if >1) preserving operator size classification if possible.
  function rebuildProduct
    input list<Expression> factors;
    input Operator origOp "Original multiplication operator (for classification); may be unused if <2 factors.";
    output Expression prod;
  protected
    Integer n = listLength(factors);
  algorithm
    prod := match n
      case 0 then makeOne();
      case 1 then listHead(factors);
      else Expression.MULTARY(factors, {}, origOp);
    end match;
  end rebuildProduct;

  // Extract (seedCref, coefficient) from a single additive term.
  // Returns NONE() if the term does not contain exactly one seed/pDer factor at top multiplicative level.
  function extractSeedCoefficient
    input Expression term;
    output Option<tuple<ComponentRef, Expression>> res;
  protected
    Option<ComponentRef> seedOpt;
    ComponentRef seedCref;
    list<Expression> factors;
    list<Expression> newFactors = {};
    Operator opMul;
    Expression workTerm;
    Expression sub;
    Boolean neg = false;
  algorithm
    // Work on a local copy; never assign to input 'term'.
    workTerm := term;

    // Detect unary minus: Expression.UNARY(UMINUS, inner)
    workTerm := match workTerm
      case Expression.UNARY(operator = Operator.OPERATOR(op = Op.UMINUS), exp = sub)
        algorithm
          neg := true;
        then sub;
      else workTerm;
    end match;

    // Direct cref (seed or pDer)
    seedOpt := getSeedOrPDerFromExpr(workTerm);
    if Util.isSome(seedOpt) then
      seedCref := Util.getOption(seedOpt);
      if neg then
        // coefficient = -1
        res := SOME((seedCref, Expression.REAL(-1.0)));
      else
        res := SOME((seedCref, makeOne()));
      end if;
      return;
    end if;

    // Multiplicative (MULTARY) structure
    res := match workTerm
      case Expression.MULTARY(arguments = factors, operator = opMul)
        algorithm
          seedCref := ComponentRef.EMPTY();
          for f in factors loop
            seedOpt := getSeedOrPDerFromExpr(f);
            if Util.isSome(seedOpt) then
              // More than one seed -> ambiguous, abort.
              if not ComponentRef.isEmpty(seedCref) then
                return;
              end if;
              seedCref := Util.getOption(seedOpt);
            else
              newFactors := f :: newFactors;
            end if;
          end for;

          if ComponentRef.isEmpty(seedCref) then
            return; // no seed in this product
          end if;

          newFactors := listReverse(newFactors);
          sub := rebuildProduct(newFactors, opMul); // coefficient (may be 1)
          if neg then
            // Multiply coefficient by -1: (-1.0) * sub
            sub := Expression.MULTARY({Expression.REAL(-1.0), sub}, {}, Operator.makeMul(Type.REAL()));
          end if;
          res := SOME((seedCref, sub));
        then res;
      else NONE();
    end match;
  end extractSeedCoefficient;

  // Public: Gather map seed -> list of coefficient expressions from a RHS.
  
  function gatherSeedFactorMap
    input Expression rhs;
    input UnorderedSet<ComponentRef> validSeeds "Optional filter; pass empty set to accept all seeds/pDers";
    output UnorderedMap<ComponentRef, ExpressionList> map;
  protected
    list<Expression> additiveTerms;
    Option<tuple<ComponentRef, Expression>> eo;
    ComponentRef sc;
    Expression coeff;
    list<Expression> oldlst;
  algorithm
    map := UnorderedMap.new<ExpressionList>(ComponentRef.hash, ComponentRef.isEqual, 128);

    additiveTerms := decomposeAdd(rhs);

    for t in additiveTerms loop
      eo := extractSeedCoefficient(t);
      if Util.isSome(eo) then
        (sc, coeff) := Util.getOption(eo);

        // Filter if validSeeds not empty
        if (UnorderedSet.size(validSeeds) > 0) and not UnorderedSet.contains(sc, validSeeds) then
          continue;
        end if;

        if UnorderedMap.contains(sc, map) then
          oldlst := UnorderedMap.getOrFail(sc, map);
        else
          oldlst := {};
        end if;

        UnorderedMap.add(sc, coeff :: oldlst, map);
      end if;
    end for;

    // Reverse lists for natural order
    for sc in UnorderedMap.keyList(map) loop
      UnorderedMap.add(sc, listReverse(UnorderedMap.getOrFail(sc, map)), map);
    end for;
  end gatherSeedFactorMap;

  // Pretty-print the gathered map
  function printSeedFactorMap
    input UnorderedMap<ComponentRef, ExpressionList> map;
    input String header = "Seed Coefficient Map";
  protected
    list<ComponentRef> keys;
    ComponentRef k;
  algorithm
    print(StringUtil.headline_2(header) + "\n");
    keys := UnorderedMap.keyList(map);
    for k in keys loop
      print(ComponentRef.toString(k) + " -> {");
      print(stringDelimitList(List.map(UnorderedMap.getOrFail(k, map),
        function Expression.toString()), ", "));
      print("}\n");
    end for;
  end printSeedFactorMap;

  annotation(__OpenModelica_Interface="backend");
end NBSeedGather;