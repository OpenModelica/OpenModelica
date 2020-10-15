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
encapsulated package NBEquation
" file:         NBEquation.mo
  package:      NBEquation
  description:  This file contains all functions and structures regarding
                backend equations.
"

public
  // Old Frontend imports
  import DAE;

  // New Frontend imports
  import Algorithm = NFAlgorithm;
  import Binding = NFBinding;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import InstNode = NFInstNode.InstNode;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import Variable = NFVariable;

  // Old Backend imports
  import OldBackendDAE = BackendDAE;

  // New Backend imports
  import BVariable = NBVariable;
  import HashTableCrToInt = NBHashTableCrToInt;

  // Util imports
  import BackendUtil = NBBackendUtil;
  import ExpandableArray;
  import StringUtil;

  uniontype Equation
    record SCALAR_EQUATION
      Expression lhs                  "left hand side expression";
      Expression rhs                  "right hand side expression";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end SCALAR_EQUATION;

    record ARRAY_EQUATION
      list<Integer> dimSize           "dimension sizes";
      Expression lhs                  "left hand side expression";
      Expression rhs                  "right hand side expression";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
      Option<Integer> recordSize      "NONE() if not a record";
    end ARRAY_EQUATION;

    record SIMPLE_EQUATION
      ComponentRef lhs                "left hand side component reference";
      ComponentRef rhs                "right hand side component reference";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end SIMPLE_EQUATION;

    record RECORD_EQUATION
      Integer size                    "size of equation";
      Expression lhs                  "left hand side expression";
      Expression rhs                  "right hand side expression";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end RECORD_EQUATION;

    record ALGORITHM
      Integer size                    "output size";
      Algorithm alg                   "Algorithm statements";
      DAE.ElementSource source        "origin of algorithm";
      DAE.Expand expand               "this algorithm was translated from an equation. we should not expand array crefs!";
      EquationAttributes attr         "Additional Attributes";
    end ALGORITHM;

    record IF_EQUATION
      Integer size;
      IfEquationBody body;
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end IF_EQUATION;

    record FOR_EQUATION
      InstNode iter                   "the iterator variable"; // Should this be a cref?
      Expression range                "Start - (Step) - Stop";
      Equation body                   "iterated equation";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end FOR_EQUATION;

    record WHEN_EQUATION
      Integer size                    "size of equation";
      WhenEquationBody body           "Actual equation body";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end WHEN_EQUATION;

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

    function toString
      input Equation eq;
      input output String str = "";
    algorithm
      str := match eq
        case SCALAR_EQUATION() then str + "[SCAL] " + EquationAttributes.toString(eq.attr) + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs);
        case ARRAY_EQUATION()  then str + "[ARRY] " + EquationAttributes.toString(eq.attr) + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs);
        case SIMPLE_EQUATION() then str + "[SIMP] " + EquationAttributes.toString(eq.attr) + ComponentRef.toString(eq.lhs) + " = " + ComponentRef.toString(eq.rhs);
        case RECORD_EQUATION() then str + "[RECD] " + EquationAttributes.toString(eq.attr) + Expression.toString(eq.lhs) + " = " + Expression.toString(eq.rhs);
        case ALGORITHM()       then str + "[ALGO] size " + intString(eq.size) + " " + EquationAttributes.toString(eq.attr) + "\n" + Algorithm.toString(eq.alg, str + "[----] ");
        case IF_EQUATION()     then str + IfEquationBody.toString(eq.body, str + "[----] ", "[-IF-] ");
        case FOR_EQUATION()    then str + forEquationToString(eq.iter, eq.range, eq.body, "", str + "[----] ", "[FOR-] ");
        case WHEN_EQUATION()   then str + WhenEquationBody.toString(eq.body, str + "[----] ", "[WHEN] ");
        case AUX_EQUATION()    then str + "[AUX-] Auxiliary equation for " + Variable.toString(Pointer.access(eq.auxiliary));
        case DUMMY_EQUATION()  then str + "[DUMY] Dummy equation.";
        else                        str + "[FAIL] " + getInstanceName() + " failed!";
      end match;
    end toString;

    function getEqnName
      input Pointer<Equation> eqn;
      output ComponentRef name;
    protected
      Pointer<Variable> residualVar;
    algorithm
      residualVar := getResidualVar(eqn);
      name := BVariable.getVarName(residualVar);
    end getEqnName;

    function getResidualVar
      input Pointer<Equation> eqn;
      output Pointer<Variable> residualVar;
    algorithm
      try
        residualVar := EquationAttributes.getResidualVar(getAttributes(Pointer.access(eqn)));
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of missing residual variable."});
        fail();
      end try;
    end getResidualVar;

    function makeStartEq
      input ComponentRef lhs;
      input ComponentRef rhs;
      input Pointer<Integer> idx;
      output Pointer<Equation> eq;
    algorithm
      eq := Pointer.create(SIMPLE_EQUATION(lhs, rhs, DAE.emptyElementSource, EQ_ATTR_DEFAULT_INITIAL));
      Equation.createName(eq, idx, "SRT");
    end makeStartEq;

    function forEquationToString
      input InstNode iter                   "the iterator variable";
      input Expression range                "Start - (Step) - Stop";
      input Equation body                   "iterated equation";
      input output String str = "";
      input String indent = "";
      input String indicator = "";
    protected
      WhenEquationBody elseWhen;
    algorithm
      str := str + indicator + "for " + InstNode.name(iter) + " in " + Expression.toString(range) + "\n";
      str := str + toString(body, indent + "  ") + "\n";
      str := str + indent + "end for;\n";
    end forEquationToString;

    function getAttributes
      input Equation eq;
      output EquationAttributes attr;
    algorithm
      attr := match eq
        local
          EquationAttributes tmp;
          Equation body;
        case SCALAR_EQUATION(attr = tmp)      then tmp;
        case ARRAY_EQUATION(attr = tmp)       then tmp;
        case SIMPLE_EQUATION(attr = tmp)      then tmp;
        case RECORD_EQUATION(attr = tmp)      then tmp;
        case ALGORITHM(attr = tmp)            then tmp;
        case IF_EQUATION(attr = tmp)          then tmp;
        case FOR_EQUATION(attr = tmp)         then tmp;
        case WHEN_EQUATION(attr = tmp)        then tmp;
        case AUX_EQUATION(body = SOME(body))  then getAttributes(body);
                                              else EQ_ATTR_DEFAULT_UNKNOWN;
      end match;
    end getAttributes;

    function setAttributes
      input output Equation eq;
      input EquationAttributes attr;
    algorithm
      eq := match eq
        local
          EquationAttributes tmp;
          Equation body;
        case SCALAR_EQUATION()  algorithm eq.attr := attr; then eq;
        case ARRAY_EQUATION()   algorithm eq.attr := attr; then eq;
        case SIMPLE_EQUATION()  algorithm eq.attr := attr; then eq;
        case RECORD_EQUATION()  algorithm eq.attr := attr; then eq;
        case ALGORITHM()        algorithm eq.attr := attr; then eq;
        case IF_EQUATION()      algorithm eq.attr := attr; then eq;
        case FOR_EQUATION()     algorithm eq.attr := attr; then eq;
        case WHEN_EQUATION()    algorithm eq.attr := attr; then eq;
        case AUX_EQUATION(body = SOME(body)) algorithm eq.body := SOME(setAttributes(body, attr)); then eq;
        end match;
    end setAttributes;

    function setDerivative
      input output Equation eq;
      input Pointer<Equation> derivative;
    protected
      EquationAttributes attr;
    algorithm
      attr := getAttributes(eq);
      attr.derivative := SOME(derivative);
      eq := setAttributes(eq, attr);
    end setDerivative;

    function map
      "Traverses all expressions of the equations and applies a function to it.
      Optional second input to also traverse crefs, only needed for simple
      eqns, when eqns and algorithms."
      input output Equation eq;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt = NONE();
      partial function MapFuncExp
        input output Expression e;
      end MapFuncExp;
      partial function MapFuncCref
        input output ComponentRef c;
      end MapFuncCref;
    algorithm
      eq := match eq
        local
          Equation body;
          MapFuncCref funcCref;
          Expression lhs, rhs, range;
          ComponentRef lhs_cref, rhs_cref;
          Algorithm alg;
          IfEquationBody ifEqBody;
          WhenEquationBody whenEqBody;
          Equation body, new_body;

        case SCALAR_EQUATION()
          algorithm
            lhs := Expression.map(eq.lhs, funcExp);
            rhs := Expression.map(eq.rhs, funcExp);
            if not referenceEq(lhs, eq.lhs) then
              eq.lhs := lhs;
            end if;
            if not referenceEq(rhs, eq.rhs) then
              eq.rhs := rhs;
            end if;
        then eq;

        case ARRAY_EQUATION()
          algorithm
            lhs := Expression.map(eq.lhs, funcExp);
            rhs := Expression.map(eq.rhs, funcExp);
            if not referenceEq(lhs, eq.lhs) then
              eq.lhs := lhs;
            end if;
            if not referenceEq(rhs, eq.rhs) then
              eq.rhs := rhs;
            end if;
        then eq;

        case SIMPLE_EQUATION()
          algorithm
            if isSome(funcCrefOpt) then
              SOME(funcCref) := funcCrefOpt;
              lhs_cref := funcCref(eq.lhs);
              rhs_cref := funcCref(eq.rhs);
              if not referenceEq(lhs_cref, eq.lhs) then
                eq.lhs := lhs_cref;
              end if;
              if not referenceEq(rhs_cref, eq.rhs) then
                eq.rhs := rhs_cref;
              end if;
            end if;
        then eq;

        case RECORD_EQUATION()
          algorithm
            lhs := Expression.map(eq.lhs, funcExp);
            rhs := Expression.map(eq.rhs, funcExp);
            if not referenceEq(lhs, eq.lhs) then
              eq.lhs := lhs;
            end if;
            if not referenceEq(rhs, eq.rhs) then
              eq.rhs := rhs;
            end if;
        then eq;

        case ALGORITHM()
          algorithm
            alg := Algorithm.mapExp(eq.alg, funcExp);
            if isSome(funcCrefOpt) then
              SOME(funcCref) := funcCrefOpt;
              // ToDo referenceEq for lists?
              //alg.inputs := List.map(alg.inputs, funcCref);
              alg.outputs := List.map(alg.outputs, funcCref);
            end if;
            eq.alg := alg;
        then eq;

        case IF_EQUATION()
          algorithm
            ifEqBody := IfEquationBody.map(eq.body, funcExp, funcCrefOpt);
            if not referenceEq(ifEqBody, eq.body) then
              eq.body := ifEqBody;
            end if;
        then eq;

        case FOR_EQUATION()
          algorithm
            range := Expression.map(eq.range, funcExp);
            body := map(eq.body, funcExp, funcCrefOpt);
            if not referenceEq(range, eq.range) then
              eq.range := range;
            end if;
            if not referenceEq(body, eq.body) then
              eq.body := body;
            end if;
        then eq;

        case WHEN_EQUATION()
          algorithm
            whenEqBody := WhenEquationBody.map(eq.body, funcExp, funcCrefOpt);
            if not referenceEq(whenEqBody, eq.body) then
              eq.body := whenEqBody;
            end if;
        then eq;

        case AUX_EQUATION(body = SOME(body))
          algorithm
            new_body := map(body, funcExp, funcCrefOpt);
            if not referenceEq(new_body, body) then
              eq.body := SOME(new_body);
            end if;
        then eq;

        case DUMMY_EQUATION() then eq;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because there was no suitable case for: " + Equation.toString(eq)});
        then fail();

      end match;
    end map;

    function collectCrefs
      "filters all crefs of an equation and adds them
      to a list of crefs. needs cref filter function."
      input Equation eq;
      input filterCref filter;
      output list<ComponentRef> cref_lst;

      partial function filterCref
        "partial function that needs to be provided.
        decides if the the cref is added to the list pointer."
        input output ComponentRef cref;
        input Pointer<list<ComponentRef>> cref_lst_ptr;
      end filterCref;

      function filterExp
        "wrapper function that applies filter cref to
        a cref expression."
        input output Expression exp;
        input filterCref filter;
        input Pointer<list<ComponentRef>> cref_lst_ptr;
      algorithm
        _ := match exp
          local
            ComponentRef cref;
            filterCref func;
          case Expression.CREF(cref = cref) algorithm
            filter(cref, cref_lst_ptr);
          then ();
          else ();
        end match;
      end filterExp;

    protected
      Pointer<list<ComponentRef>> cref_lst_ptr = Pointer.create({});
    algorithm
      // map with the expression and cref filter functions
      _ := map(eq, function filterExp(filter = filter, cref_lst_ptr = cref_lst_ptr),
              SOME(function filter(cref_lst_ptr = cref_lst_ptr)));
      cref_lst := Pointer.access(cref_lst_ptr);
    end collectCrefs;

  public
    function getLHS
      "gets the left hand side expression of an equation."
      input Equation eq;
      output Expression lhs;
    algorithm
      lhs := match(eq)
        local
          ComponentRef cref;
        case SCALAR_EQUATION(lhs = lhs)   then lhs;
        case ARRAY_EQUATION(lhs = lhs)    then lhs;
        case RECORD_EQUATION(lhs = lhs)   then lhs;
        case SIMPLE_EQUATION(lhs = cref)  then Expression.fromCref(cref);
        else fail();
      end match;
    end getLHS;

    function getRHS
      "gets the right hand side expression of an equation."
      input Equation eq;
      output Expression rhs;
    algorithm
      rhs := match(eq)
        local
          ComponentRef cref;
        case SCALAR_EQUATION(rhs = rhs)   then rhs;
        case ARRAY_EQUATION(rhs = rhs)    then rhs;
        case RECORD_EQUATION(rhs = rhs)   then rhs;
        case SIMPLE_EQUATION(rhs = cref)  then Expression.fromCref(cref);
        else fail();
      end match;
    end getRHS;

    function setLHS
      "sets the left hand side expression of an equation."
      input output Equation eq;
      input Expression lhs;
    algorithm
      eq := match(eq)
        local
          ComponentRef cref;
          Equation new_eq;
        case SCALAR_EQUATION()
          algorithm
            eq.lhs := lhs;
        then eq;
        case ARRAY_EQUATION()
          algorithm
            eq.lhs := lhs;
        then eq;
        case RECORD_EQUATION()
          algorithm
            eq.lhs := lhs;
        then eq;
        case SIMPLE_EQUATION()
          algorithm
            new_eq := match lhs
              local ComponentRef cr;
              case Expression.CREF(cref = cr) algorithm
                eq.lhs := cr;
              then eq;
              case _ guard(Type.isScalar(Expression.typeOf(lhs)))
              then SCALAR_EQUATION(lhs, Expression.fromCref(eq.rhs), eq.source, eq.attr);
              else ARRAY_EQUATION({}, lhs, Expression.fromCref(eq.rhs), eq.source, eq.attr, NONE());
            end match;
        then new_eq;
        else fail();
      end match;
    end setLHS;

    function setRHS
      "sets the right hand side expression of an equation."
      input output Equation eq;
      input Expression rhs;
    algorithm
      eq := match(eq)
        local
          ComponentRef cref;
          Equation new_eq;
        case SCALAR_EQUATION()
          algorithm
            eq.rhs := rhs;
        then eq;
        case ARRAY_EQUATION()
          algorithm
            eq.rhs := rhs;
        then eq;
        case RECORD_EQUATION()
          algorithm
            eq.rhs := rhs;
        then eq;
        case SIMPLE_EQUATION()
          algorithm
            new_eq := match rhs
              local ComponentRef cr;
              case Expression.CREF(cref = cr) algorithm
                eq.rhs := cr;
              then eq;
              case _ guard(Type.isScalar(Expression.typeOf(rhs)))
              then SCALAR_EQUATION(Expression.fromCref(eq.lhs), rhs, eq.source, eq.attr);
              else ARRAY_EQUATION({}, Expression.fromCref(eq.lhs), rhs, eq.source, eq.attr, NONE());
            end match;
        then new_eq;
      end match;
    end setRHS;

    function fromLHSandRHS
      input Expression lhs;
      input Expression rhs;
      input EquationAttributes attr = EQ_ATTR_DEFAULT_UNKNOWN;
      input DAE.ElementSource source = DAE.emptyElementSource;
      output Equation eq;
    protected
      Type ty;
    algorithm
      ty := Expression.typeOf(lhs);
      eq := match ty
        case Type.ARRAY() then ARRAY_EQUATION(List.map(ty.dimensions, Dimension.size), lhs, rhs, source, attr, NONE());
        else SCALAR_EQUATION(lhs, rhs, source, attr);
      end match;
    end fromLHSandRHS;

    function simplify
      input output Equation eq;
      input String name = "";
      input String indent = "";
    algorithm
      if Flags.isSet(Flags.DUMP_SIMPLIFY) and not stringEqual(indent, "") then
        print("\n");
      end if;
      eq := match eq
        case SCALAR_EQUATION() algorithm
          eq.lhs := SimplifyExp.simplifyDump(eq.lhs, name, indent);
          eq.rhs := SimplifyExp.simplifyDump(eq.rhs, name, indent);
        then eq;
        case ARRAY_EQUATION() algorithm
          eq.lhs := SimplifyExp.simplifyDump(eq.lhs, name, indent);
          eq.rhs := SimplifyExp.simplifyDump(eq.rhs, name, indent);
        then eq;
        case SIMPLE_EQUATION() then eq;
        case RECORD_EQUATION() algorithm
          eq.lhs := SimplifyExp.simplifyDump(eq.lhs, name, indent);
          eq.rhs := SimplifyExp.simplifyDump(eq.rhs, name, indent);
        then eq;
        // ToDo: implement the following correctly:
        case ALGORITHM()       then eq;
        case IF_EQUATION()     then eq;
        case FOR_EQUATION()    then eq;
        case WHEN_EQUATION()   then eq;
        case AUX_EQUATION()    then eq;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Equation.toString(eq)});
        then fail();
      end match;
    end simplify;

    function createName
      input Pointer<Equation> eqn_ptr;
      input Pointer<Integer> idx;
      input String context;
    protected
      Equation eqn;
      Pointer<Variable> residualVar;
    algorithm
      // create residual var as name
      (residualVar, _) := BVariable.makeResidualVar(context, Pointer.access(idx));
      Pointer.update(idx, Pointer.access(idx) + 1);

      // update equation attributes
      eqn := Pointer.access(eqn_ptr);
      eqn := match eqn
        case SCALAR_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case ARRAY_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case SIMPLE_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case RECORD_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case ALGORITHM() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case IF_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case FOR_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case WHEN_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + toString(eqn)});
        then fail();

      end match;
      Pointer.update(eqn_ptr, eqn);
    end createName;

    function createResidual
      "Creates a residual equation from a regular equation.
      Expample (for DAEMode): $RES_DAE_idx := rhs.
      Does not solve the equation, only saves the residual term!"
      input output Equation eqn;
      input String context;
      input Pointer<list<Pointer<Variable>>> residual_vars;
      input Pointer<Integer> idx;
    protected
      Pointer<Variable> residualVar;
    algorithm
      // create residual var and update pointers
      (residualVar, _) := BVariable.makeResidualVar(context, Pointer.access(idx));
      Pointer.update(residual_vars, residualVar :: Pointer.access(residual_vars));
      Pointer.update(idx, Pointer.access(idx) + 1);

      // update equation attributes
      eqn := match eqn
        case SCALAR_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case ARRAY_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case SIMPLE_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case RECORD_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case ALGORITHM() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case IF_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case FOR_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        case WHEN_EQUATION() algorithm
          eqn.attr := EquationAttributes.setResidualVar(eqn.attr, residualVar);
        then eqn;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + toString(eqn)});
        then fail();

      end match;
    end createResidual;

    function getResidualExp
      input Equation eqn;
      output Expression exp;
    algorithm
      exp := match eqn
        local
          Operator operator;

        case Equation.SCALAR_EQUATION() algorithm
          operator := Operator.OPERATOR(Expression.typeOf(eqn.lhs), NFOperator.Op.ADD);
        then Expression.MULTARY({eqn.rhs}, {eqn.lhs}, operator);

        case Equation.ARRAY_EQUATION()  algorithm
          operator := Operator.OPERATOR(Expression.typeOf(eqn.lhs), NFOperator.Op.ADD);
        then Expression.MULTARY({eqn.rhs}, {eqn.lhs}, operator);

        case Equation.SIMPLE_EQUATION() algorithm
          operator := Operator.OPERATOR(ComponentRef.getComponentType(eqn.lhs), NFOperator.Op.ADD);
        then Expression.MULTARY({Expression.fromCref(eqn.rhs)},{Expression.fromCref(eqn.lhs)}, operator);

        case Equation.RECORD_EQUATION() algorithm
          operator := Operator.OPERATOR(Expression.typeOf(eqn.lhs), NFOperator.Op.ADD);
        then Expression.MULTARY({eqn.rhs}, {eqn.lhs}, operator);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
      exp := SimplifyExp.simplify(exp);
    end getResidualExp;

    function isParameterEquation
      input Equation eqn;
      output Boolean b = true;
    protected
      Pointer<Boolean> b_ptr = Pointer.create(b);
    algorithm
      Equation.map(eqn, function expIsParamOrConst(b_ptr = b_ptr), SOME(function crefIsParamOrConst(b_ptr = b_ptr)));
      b := Pointer.access(b_ptr);
    end isParameterEquation;

    function expIsParamOrConst
      input output Expression exp;
      input Pointer<Boolean> b_ptr;
    algorithm
      if Pointer.access(b_ptr) then
        _ := match exp
          // set b_ptr to false on impure functions
          case Expression.CREF() algorithm
            crefIsParamOrConst(exp.cref, b_ptr);
          then ();
          case Expression.CALL() algorithm
            Pointer.update(b_ptr, Call.isImpure(exp.call));
          then ();
          else ();
        end match;
      end if;
    end expIsParamOrConst;

    function crefIsParamOrConst
      input output ComponentRef cref;
      input Pointer<Boolean> b_ptr;
    algorithm
      if Pointer.access(b_ptr) then
        Pointer.update(b_ptr, BVariable.isParamOrConst(BVariable.getVarPointer(cref)));
      end if;
    end crefIsParamOrConst;

    function generateBindingEquation
      input Pointer<Variable> var_ptr;
      input Pointer<Integer> idx;
      output Pointer<Equation> eqn;
    protected
      Variable var;
      Expression lhs, rhs;
    algorithm
      var := Pointer.access(var_ptr);
      lhs := Expression.fromCref(var.name);
      rhs := match var.binding
        local
          Binding qual;
        case qual as Binding.TYPED_BINDING()  then Expression.getBindingExp(qual.bindingExp);
        case qual as Binding.UNBOUND()        then Expression.makeZero(Expression.typeOf(lhs));
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong binding type: " + Binding.toString(var.binding) + " for variable " + Variable.toString(Pointer.access(var_ptr))});
        then fail();
      end match;
      eqn := Pointer.create(Equation.fromLHSandRHS(lhs, rhs, EQ_ATTR_DEFAULT_INITIAL));
      Equation.createName(eqn, idx, "BND");
    end generateBindingEquation;

  end Equation;

  uniontype IfEquationBody
    record IF_EQUATION_BODY
      Expression condition                  "the if-condition";
      list<Pointer<Equation>> then_eqns     "body equations";
      Option<IfEquationBody> else_if        "optional elseif equation";
    end IF_EQUATION_BODY;

    function toString
      input IfEquationBody body;
      input String indent = "";
      input String elseStr = "";
      input Boolean selfCall = false;
      output String str;
    protected
      IfEquationBody elseIf;
    algorithm
      if not Expression.isEnd(body.condition) then
        str := elseStr + "if " + Expression.toString(body.condition) + " then \n";
      else
        str := elseStr + "\n";
      end if;
      for eqn in body.then_eqns loop
        str := str + Equation.toString(Pointer.access(eqn), indent + "  ") + "\n";
      end for;
      if isSome(body.else_if) then
        SOME(elseIf) := body.else_if;
        str := str + toString(elseIf, indent, indent +"else ", true);
      end if;
      if not selfCall then
        str := str + indent + "end if;\n";
      end if;
    end toString;

    function map
      input output IfEquationBody ifBody;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt;
      partial function MapFuncExp
        input output Expression e;
      end MapFuncExp;
      partial function MapFuncCref
        input output ComponentRef c;
      end MapFuncCref;
    protected
      Expression condition;
    algorithm
      condition := Expression.map(ifBody.condition, funcExp);
      if not referenceEq(condition, ifBody.condition) then
        ifBody.condition := condition;
      end if;

      // referenceEq for lists?
      ifBody.then_eqns := List.map(ifBody.then_eqns, function Pointer.apply(func = function Equation.map(funcExp = function funcExp(), funcCrefOpt = function funcCrefOpt())));
    end map;
  end IfEquationBody;

  uniontype WhenEquationBody
    record WHEN_EQUATION_BODY "equation when condition then cr = exp, reinit(...), terminate(...) or assert(...)"
      Expression condition                  "the when-condition" ;
      list<WhenStatement> when_stmts        "body statements";
      Option<WhenEquationBody> else_when    "optional elsewhen body";
    end WHEN_EQUATION_BODY;

    function toString
      input WhenEquationBody body;
      input String indent = "";
      input String elseStr = "";
      input Boolean selfCall = false;
      output String str;
    protected
      WhenEquationBody elseWhen;
    algorithm
      str := elseStr + "when " + Expression.toString(body.condition) + " then \n";
      for stmt in body.when_stmts loop
        str := str + WhenStatement.toString(stmt, indent + "  ") + "\n";
      end for;
      if isSome(body.else_when) then
        SOME(elseWhen) := body.else_when;
        str := str + toString(elseWhen, indent, indent +"else ", true);
      end if;
      if not selfCall then
        str := str + indent + "end when;";
      end if;
    end toString;

    function map
      input output WhenEquationBody whenBody;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt;
      partial function MapFuncExp
        input output Expression e;
      end MapFuncExp;
      partial function MapFuncCref
        input output ComponentRef c;
      end MapFuncCref;
    protected
      Expression condition;
    algorithm
      condition := Expression.map(whenBody.condition, funcExp);
      if not referenceEq(condition, whenBody.condition) then
        whenBody.condition := condition;
      end if;

      // ToDo reference eq for lists?
      whenBody.when_stmts := List.map(whenBody.when_stmts, function WhenStatement.map(funcExp = funcExp, funcCrefOpt = funcCrefOpt));
    end map;
  end WhenEquationBody;

  uniontype WhenStatement
    record ASSIGN " left_cr = right_exp"
      Expression lhs     "left hand side of assignment";
      Expression rhs             "right hand side of assignment";
      DAE.ElementSource source  "origin of assignment";
    end ASSIGN;

    record REINIT "Reinit Statement"
      ComponentRef stateVar   "State variable to reinit";
      Expression value             "Value after reinit";
      DAE.ElementSource source  "origin of statement";
    end REINIT;

    record ASSERT
      Expression condition;
      Expression message;
      Expression level;
      DAE.ElementSource source "origin of statement";
    end ASSERT;

    record TERMINATE
      "The Modelica built-in terminate(msg)"
      Expression message;
      DAE.ElementSource source "the origin of the component/equation/algorithm";
    end TERMINATE;

    record NORETCALL
      "call with no return value, i.e. no equation.
      Typically side effect call of external function but also
      Connections.* i.e. Connections.root(...) functions."
      Expression exp;
      DAE.ElementSource source "the origin of the component/equation/algorithm";
    end NORETCALL;

    function toString
      input WhenStatement stmt;
      input output String str = "";
    algorithm
      str := match stmt
        local
          Expression lhs, rhs, value, condition, message, level;
          ComponentRef stateVar;
        case ASSIGN(lhs = lhs, rhs = rhs)                                     then str + Expression.toString(lhs) + " := " + Expression.toString(rhs);
        case REINIT(stateVar = stateVar, value = value)                       then str + "reinit(" + ComponentRef.toString(stateVar) + ", " + Expression.toString(value) + ")";
        case ASSERT(condition = condition, message = message, level = level)  then str + "assert(" + Expression.toString(condition) + ", " + Expression.toString(message) + ", " + Expression.toString(level) + ")";
        case TERMINATE(message = message)                                     then str + "terminate(" + Expression.toString(message) + ")";
        case NORETCALL(exp = value)                                           then str + Expression.toString(value);
                                                                              else str + getInstanceName() + " failed.";
      end match;
    end toString;

    function map
      input output WhenStatement stmt;
      input MapFunc funcExp;
      input Option<MapFuncCref> funcCrefOpt;
      partial function MapFunc
        input output Expression e;
      end MapFunc;
      partial function MapFuncCref
        input output ComponentRef c;
      end MapFuncCref;
    algorithm
      stmt := match stmt
        local
          MapFuncCref funcCref;
          Expression lhs, rhs, value, condition;
          ComponentRef stateVar;

        case ASSIGN()
          algorithm
            lhs := Expression.map(stmt.lhs, funcExp);
            rhs := Expression.map(stmt.rhs, funcExp);
            if not referenceEq(lhs, stmt.lhs) then
              stmt.lhs := lhs;
            end if;
            if not referenceEq(rhs, stmt.rhs) then
              stmt.rhs := rhs;
            end if;
        then stmt;

        case REINIT()
          algorithm
            if isSome(funcCrefOpt) then
              SOME(funcCref) := funcCrefOpt;
              stateVar := funcCref(stmt.stateVar);
              if not referenceEq(stateVar, stmt.stateVar) then
                stmt.stateVar := stateVar;
              end if;
            end if;
            value := Expression.map(stmt.value, funcExp);
            if not referenceEq(value, stmt.value) then
              stmt.value := value;
            end if;
        then stmt;

        case ASSERT()
          algorithm
            condition := Expression.map(stmt.condition, funcExp);
            if not referenceEq(condition, stmt.condition) then
              stmt.condition := condition;
            end if;
        then stmt;

        case TERMINATE() then stmt;

        case NORETCALL()
          algorithm
            value := Expression.map(stmt.exp, funcExp);
            if not referenceEq(value, stmt.exp) then
              stmt.exp := value;
            end if;
        then stmt;

        else stmt;
      end match;
    end map;
  end WhenStatement;

  uniontype EquationAttributes
    record EQUATION_ATTRIBUTES
      Option<Pointer<Equation>> derivative;
      EquationKind kind;
      EvaluationStages evalStages;
      Option<Pointer<Variable>> residualVar "also used to represent the equation itself";
    end EQUATION_ATTRIBUTES;

    function toString
      input EquationAttributes attr;
      output String str;
    algorithm
      str := match attr
        local
          Pointer<Variable> residualVar;
        case EQUATION_ATTRIBUTES(residualVar = SOME(residualVar))
        then "(" + ComponentRef.toString(BVariable.getVarName(residualVar)) + ") ";
        else "";
      end match;
    end toString;

    function setResidualVar
      input output EquationAttributes attr;
      input Pointer<Variable> residualVar;
    algorithm
      attr.residualVar := SOME(residualVar);
    end setResidualVar;

    function getResidualVar
      input EquationAttributes attr;
      output Pointer<Variable> residualVar;
    algorithm
      try
        SOME(residualVar) := attr.residualVar;
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of missing residualVar!"});
      end try;
    end getResidualVar;

    function convert
      input EquationAttributes attributes;
      output OldBackendDAE.EquationAttributes oldAttributes;
    algorithm
      oldAttributes := OldBackendDAE.EQUATION_ATTRIBUTES(
        differentiated  = Util.isSome(attributes.derivative),
        kind            = EquationKind.convert(attributes.kind),
        evalStages      = EvaluationStages.convert(attributes.evalStages));
    end convert;
  end EquationAttributes;

  constant EquationAttributes EQ_ATTR_DEFAULT_DYNAMIC = EQUATION_ATTRIBUTES(NONE(), DYNAMIC_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_BINDING = EQUATION_ATTRIBUTES(NONE(), BINDING_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_INITIAL = EQUATION_ATTRIBUTES(NONE(), INITIAL_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_DISCRETE = EQUATION_ATTRIBUTES(NONE(), DISCRETE_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_AUX = EQUATION_ATTRIBUTES(NONE(), AUX_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_UNKNOWN = EQUATION_ATTRIBUTES(NONE(), UNKNOWN_EQUATION_KIND(), DEFAULT_EVALUATION_STAGES, NONE());

  uniontype EquationKind
    record BINDING_EQUATION end BINDING_EQUATION;
    record DYNAMIC_EQUATION end DYNAMIC_EQUATION;
    record INITIAL_EQUATION end INITIAL_EQUATION;
    record CLOCKED_EQUATION Integer clk; end CLOCKED_EQUATION;
    record DISCRETE_EQUATION end DISCRETE_EQUATION;
    record AUX_EQUATION "ToDo! Do we still need this?" end AUX_EQUATION;
    record UNKNOWN_EQUATION_KIND end UNKNOWN_EQUATION_KIND;

    function convert
      input EquationKind eqKind;
      output OldBackendDAE.EquationKind oldEqKind;
    algorithm
      oldEqKind := match eqKind
        local
          Integer clk;
        case BINDING_EQUATION()           then OldBackendDAE.BINDING_EQUATION();
        case DYNAMIC_EQUATION()           then OldBackendDAE.DYNAMIC_EQUATION();
        case INITIAL_EQUATION()           then OldBackendDAE.INITIAL_EQUATION();
        case CLOCKED_EQUATION(clk = clk)  then OldBackendDAE.CLOCKED_EQUATION(clk);
        case DISCRETE_EQUATION()          then OldBackendDAE.DISCRETE_EQUATION();
        case AUX_EQUATION()               then OldBackendDAE.AUX_EQUATION();
        case UNKNOWN_EQUATION_KIND()      then OldBackendDAE.UNKNOWN_EQUATION_KIND();
        else fail();
      end match;
    end convert;
  end EquationKind;

  uniontype EvaluationStages
    record EVALUATION_STAGES
      Boolean dynamicEval;
      Boolean algebraicEval;
      Boolean zerocrossEval;
      Boolean discreteEval;
    end EVALUATION_STAGES;

    function convert
      input EvaluationStages evalStages;
      output OldBackendDAE.EvaluationStages oldEvalStages;
    algorithm
      oldEvalStages := OldBackendDAE.EVALUATION_STAGES(
        dynamicEval   = evalStages.dynamicEval,
        algebraicEval = evalStages.algebraicEval,
        zerocrossEval = evalStages.zerocrossEval,
        discreteEval  = evalStages.discreteEval);
    end convert;
  end EvaluationStages;

  constant EvaluationStages DEFAULT_EVALUATION_STAGES = EVALUATION_STAGES(true,true,false,true);

  uniontype EquationPointers
    record EQUATION_POINTERS
      "author: kabdelhak 2020
      This uniontype is not really necessary, since it only wraps an expandable
      array of pointers to equations, but it makes it easier maintanable
      since all utility functions are in the same place. Also it mirrors
      VariablePointers behavior."
      HashTableCrToInt.HashTable ht               "Hash table for cref->index";
      ExpandableArray<Pointer<Equation>> eqArr;
    end EQUATION_POINTERS;

    function toString
      input EquationPointers equations;
      input output String str = "";
      input Boolean printEmpty = true;
    protected
      Integer numberOfElements = ExpandableArray.getNumberOfElements(equations.eqArr);
    algorithm
      if printEmpty or numberOfElements > 0 then
        str := StringUtil.headline_4(str + " EquationPointers (" + intString(numberOfElements) + ")");
        for i in 1:numberOfElements loop
          str := str + "(" + intString(i) + ")" + Equation.toString(Pointer.access(ExpandableArray.get(i, equations.eqArr)), "\t") + "\n";
        end for;
        str := str + "\n";
      else
        str := "";
      end if;
    end toString;

    function empty
      "Creates an empty EquationPointers using given size."
      input Integer size = BaseHashTable.bigBucketSize;
      output EquationPointers equationPointers;
    protected
      Integer arr_size, bucketSize;
    algorithm
      arr_size := max(size, BaseHashTable.lowBucketSize);
      bucketSize := realInt(intReal(arr_size) * 1.4);
      equationPointers := EQUATION_POINTERS(HashTableCrToInt.empty(bucketSize), ExpandableArray.new(arr_size, Pointer.create(DUMMY_EQUATION())));
    end empty;

    function clone
      input EquationPointers equations;
      output EquationPointers new = fromList(toList(equations));
    end clone;

    function toList
      "Creates a EquationPointer list from EquationPointers."
      input EquationPointers equations;
      output list<Pointer<Equation>> eqn_lst;
    algorithm
      eqn_lst := ExpandableArray.toList(equations.eqArr);
    end toList;

    function fromList
      input list<Pointer<Equation>> eq_lst;
      output EquationPointers equations;
    algorithm
      equations := empty(listLength(eq_lst));
      equations := addList(eq_lst, equations);
    end fromList;

    function addList
      input list<Pointer<Equation>> eq_lst;
      input output EquationPointers equations;
    algorithm
      equations := List.fold(eq_lst, function add(), equations);
    end addList;

    function removeList
      "Removes a list of equations from the EquationPointers structure."
      input list<Pointer<Equation>> eq_lst;
      input output EquationPointers equations;
    algorithm
      equations := List.fold(eq_lst, function remove(), equations);
      equations := compress(equations);
    end removeList;

    function add
      input Pointer<Equation> eqn;
      input output EquationPointers equations;
    protected
      ComponentRef name;
      Integer idx;
    algorithm
      name := Equation.getEqnName(eqn);
      if BaseHashTable.hasKey(name, equations.ht) then
        idx := BaseHashTable.get(name, equations.ht);
        ExpandableArray.update(idx, eqn, equations.eqArr);
      else
        (_, idx) := ExpandableArray.add(eqn, equations.eqArr);
        equations.ht := BaseHashTable.add((name, idx), equations.ht);
      end if;
    end add;

    function remove
      "Removes an equation pointer identified by its (residual var) name from the set."
      input Pointer<Equation> eqn;
      input output EquationPointers equations "only an output for mapping";
    protected
      ComponentRef name;
      Integer idx;
    algorithm
      name := Equation.getEqnName(eqn);
      if BaseHashTable.hasKey(name, equations.ht) then
        idx := BaseHashTable.get(name, equations.ht);
        ExpandableArray.delete(idx, equations.eqArr);
        BaseHashTable.delete(name, equations.ht);
      end if;
    end remove;

    function map
      "Traverses all equations and applies a function to them."
      input output EquationPointers equations;
      input MapFunc func;
      partial function MapFunc
        input output Equation e;
      end MapFunc;
    protected
      Pointer<Equation> eq_ptr;
      Equation eq, new_eq;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq_ptr := ExpandableArray.get(i, equations.eqArr);
          eq := Pointer.access(eq_ptr);
          new_eq := func(eq);
          if not referenceEq(eq, new_eq) then
            // Do not update the expandable array entry, but the pointer itself
            Pointer.update(eq_ptr, new_eq);
          end if;
        end if;
      end for;
    end map;

    function mapPtr
      "Traverses all equations wrapped in pointers and applies a function to them.
      Note: the equation can only be updated if the function itself updates it!"
      input output EquationPointers equations;
      input MapFunc func;
      partial function MapFunc
        input Pointer<Equation> e;
      end MapFunc;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          func(ExpandableArray.get(i, equations.eqArr));
         end if;
      end for;
    end mapPtr;

    function mapExp
      "Traverses all expressions of all equations and applies a function to it.
      Optional second input to also traverse crefs, only needed for simple
      eqns, when eqns and algorithms."
      input output EquationPointers equations;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt = NONE();
      partial function MapFuncExp
        input output Expression e;
      end MapFuncExp;
      partial function MapFuncCref
        input output ComponentRef c;
      end MapFuncCref;
    protected
      Pointer<Equation> eq_ptr;
      Equation eq, new_eq;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq_ptr := ExpandableArray.get(i, equations.eqArr);
          eq := Pointer.access(eq_ptr);
          new_eq := Equation.map(eq, funcExp, funcCrefOpt);
          if not referenceEq(eq, new_eq) then
            // Do not update the expandable array entry, but the pointer itself
            Pointer.update(eq_ptr, new_eq);
          end if;
        end if;
      end for;
    end mapExp;

    function fold<T>
      "Traverses all equations and applies a function to them to accumulate data.
      Cannot change equations."
      input EquationPointers equations;
      input MapFunc func;
      input output T extArg;
      partial function MapFunc
        input Equation e;
        input output T extArg;
      end MapFunc;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          extArg := func(Pointer.access(ExpandableArray.get(i, equations.eqArr)), extArg);
        end if;
      end for;
    end fold;

    function foldRemovePtr<T>
      "Traverses all equation pointers and applies a function to them to accumulate data.
      Can invoke to delete the equation pointer. (also deletes other instances of the equation.
      Take care to keep a copy if you want to add it back later)"
      input output EquationPointers equations;
      input MapFunc func;
      input output T extArg;
      partial function MapFunc
        input Pointer<Equation> e;
        input output T extArg;
        output Boolean delete;
      end MapFunc;
    protected
      Pointer<Equation> eq_ptr;
      Boolean delete;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq_ptr := ExpandableArray.get(i, equations.eqArr);
          (extArg, delete) := func(eq_ptr, extArg);
          if delete then
            // change the pointer to point to an empty equation
            Pointer.update(eq_ptr, DUMMY_EQUATION());
            // delete this pointer instance
            equations.eqArr := ExpandableArray.delete(i, equations.eqArr);
          end if;
        end if;
      end for;
    end foldRemovePtr;

    function getEqnAt
      "Returns the equation pointer at given index. If there is none it fails."
      input EquationPointers equations;
      input Integer index;
      output Pointer<Equation> eqn;
    algorithm
      eqn := ExpandableArray.get(index, equations.eqArr);
    end getEqnAt;

    function compress "O(n)
      Reorders the elements in order to remove all the gaps.
      Be careful: This changes the indices of the elements."
      input output EquationPointers equations;
    algorithm
      // delete all empty equations
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          _ := match Pointer.access(ExpandableArray.get(i, equations.eqArr))
            case Equation.DUMMY_EQUATION() algorithm
              equations.eqArr := ExpandableArray.delete(i, equations.eqArr);
            then ();
            else ();
          end match;
        end if;
      end for;
      // compress the array
      equations.eqArr := ExpandableArray.compress(equations.eqArr);
    end compress;

     function sort
      "author: kabdelhak
      Sorts the equations solely by cref and operator attributes and type hash.
      Does not use the name! Used for reproduceable heuristic behavior independent of names."
      input output EquationPointers equations;
    protected
      Integer size;
      list<tuple<Integer, Pointer<Equation>>> hash_lst;
      Pointer<list<tuple<Integer, Pointer<Equation>>>> hash_lst_ptr = Pointer.create({});
      Pointer<Equation> eqn_ptr;
    algorithm
      // use number of elements
      size := ExpandableArray.getNumberOfElements(equations.eqArr);
      // hash all equations and create hash - equation tpl list
      mapPtr(equations, function createSortHashTpl(mod = realInt(size * log(size)), hash_lst_ptr = hash_lst_ptr));
      hash_lst := List.sort(Pointer.access(hash_lst_ptr), BackendUtil.indexTplGt);
      // add the equations one by one in sorted order
      equations := empty(size);
      for tpl in hash_lst loop
        (_, eqn_ptr) := tpl;
        equations.eqArr := ExpandableArray.add(eqn_ptr, equations.eqArr);
      end for;
    end sort;

  protected
    function createSortHashTpl
      "Helper function for sort(). Creates the hash value without considering the names and
      adds it as a tuple to the list in pointer."
      input Pointer<Equation> eqn_ptr;
      input Integer mod;
      input Pointer<list<tuple<Integer, Pointer<Equation>>>> hash_lst_ptr;
    protected
      Equation eqn;
      Integer hash;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      // create hash only from attributes
      hash := BackendUtil.noNameHashEq(eqn, mod);
      Pointer.update(hash_lst_ptr, (hash, eqn_ptr) :: Pointer.access(hash_lst_ptr));
    end createSortHashTpl;
  end EquationPointers;

  uniontype EqData
    record EQ_DATA_SIM
      Pointer<Integer> uniqueIndex  "current index to be used for new identifier";
      EquationPointers equations    "All equations";
      EquationPointers simulation   "All equations for simulation (without initial)";
      EquationPointers continuous   "Continuous equations";
      EquationPointers discretes    "Discrete equations";
      EquationPointers initials     "(Exclusively) Initial equations";
      EquationPointers auxiliaries  "Auxiliary equations";
      EquationPointers removed      "Removed equations (alias and no return value)";
    end EQ_DATA_SIM;

    record EQ_DATA_JAC
      Pointer<Integer> uniqueIndex  "current index to be used for new identifier";
      EquationPointers equations    "All equations";
      EquationPointers results      "Result equations";
      EquationPointers temporary    "Temporary inner equations";
      EquationPointers auxiliaries  "Auxiliary equations";
      EquationPointers removed      "Removed equations (alias and no return value)";
    end EQ_DATA_JAC;

    record EQ_DATA_HES
      Pointer<Integer> uniqueIndex  "current index to be used for new identifier";
      EquationPointers equations    "All equations";
      Pointer<Equation> result      "Result equation";
      EquationPointers temporary    "Temporary inner equations";
      EquationPointers auxiliaries  "Auxiliary equations";
      EquationPointers removed      "Removed equations (alias and no return value)";
    end EQ_DATA_HES;

    record EQ_DATA_EMPTY end EQ_DATA_EMPTY;

    function toString
      input EqData eqData;
      input Integer level = 0;
      output String str;
    algorithm
      str := match eqData
        local
          String tmp;

        case EQ_DATA_SIM()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(eqData.equations, "Simulation", false);
            else
              tmp :=  EquationPointers.toString(eqData.continuous, "Continuous", false) +
                      EquationPointers.toString(eqData.discretes, "Discrete", false) +
                      EquationPointers.toString(eqData.initials, "(Exclusively) Initial", false) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", false);
            end if;
        then tmp;

        case EQ_DATA_JAC()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(eqData.equations, "Jacobian", false);
            else
              tmp :=  EquationPointers.toString(eqData.results, "Result", false) +
                      EquationPointers.toString(eqData.temporary, "Temporary Inner", false) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", false);
            end if;
        then tmp;

        case EQ_DATA_HES()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(eqData.equations, "Hessian", false);
            else
              tmp :=  StringUtil.headline_4("Result Equation") + "\n" +
                      Equation.toString(Pointer.access(eqData.result)) + "\n" +
                      EquationPointers.toString(eqData.temporary, "Temporary Inner", false) +
                      EquationPointers.toString(eqData.auxiliaries, "Auxiliary", false);
            end if;
        then tmp;

        case EQ_DATA_EMPTY() then "Empty equation Data!\n";

      else getInstanceName() + " failed!\n";
      end match;
    end toString;

    function setEquations
      input output EqData eqData;
      input EquationPointers equations;
    algorithm
      eqData := match eqData
        case EQ_DATA_SIM() algorithm eqData.equations := equations; then eqData;
        case EQ_DATA_JAC() algorithm eqData.equations := equations; then eqData;
        case EQ_DATA_HES() algorithm eqData.equations := equations; then eqData;
      end match;
    end setEquations;

  type EqType = enumeration(CONTINUOUS, DISCRETE, INITIAL);

  function addTypedList
    input output EqData eqData;
    input list<Pointer<Equation>> eq_lst;
    input EqType eqType;
  algorithm
    eqData := match (eqData, eqType)

      case (EQ_DATA_SIM(), EqType.CONTINUOUS) algorithm
        for eqn_ptr in eq_lst loop
          Equation.createName(eqn_ptr, eqData.uniqueIndex, "SIM");
        end for;
        eqData.equations := EquationPointers.addList(eq_lst, eqData.equations);
        eqData.simulation := EquationPointers.addList(eq_lst, eqData.simulation);
        eqData.continuous := EquationPointers.addList(eq_lst, eqData.continuous);
      then eqData;

      case (EQ_DATA_SIM(), EqType.DISCRETE) algorithm
        for eqn_ptr in eq_lst loop
          Equation.createName(eqn_ptr, eqData.uniqueIndex, "SIM");
        end for;
        eqData.equations := EquationPointers.addList(eq_lst, eqData.equations);
        eqData.simulation := EquationPointers.addList(eq_lst, eqData.simulation);
        eqData.discretes := EquationPointers.addList(eq_lst, eqData.discretes);
      then eqData;

      case (EQ_DATA_SIM(), EqType.INITIAL) algorithm
        for eqn_ptr in eq_lst loop
          Equation.createName(eqn_ptr, eqData.uniqueIndex, "SIM");
        end for;
        eqData.equations := EquationPointers.addList(eq_lst, eqData.equations);
        eqData.initials := EquationPointers.addList(eq_lst, eqData.initials);
      then eqData;

      // ToDo: other cases

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end addTypedList;

  end EqData;

  uniontype InnerEquation
    record INNER_EQUATION
      "Inner equation for torn systems."
      Pointer<Equation> eqn;
      list<Pointer<Variable>> vars;
      //Option<Constraints> cons;
    end INNER_EQUATION;
  end InnerEquation;

  annotation(__OpenModelica_Interface="backend");
end NBEquation;
