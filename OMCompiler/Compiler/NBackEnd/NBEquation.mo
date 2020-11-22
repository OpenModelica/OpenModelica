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
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import InstNode = NFInstNode.InstNode;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import Operator = NFOperator;
  import Variable = NFVariable;

  // Old Backend imports
  import OldBackendDAE = BackendDAE;

  // New Backend imports
  import BVariable = NBVariable;

  // Util imports
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
        local
          Equation qualEq;
        case qualEq as SCALAR_EQUATION() then str + "[SCAL] " + EquationAttributes.toString(qualEq.attr) + Expression.toString(qualEq.lhs) + " = " + Expression.toString(qualEq.rhs);
        case qualEq as ARRAY_EQUATION()  then str + "[ARRY] " + EquationAttributes.toString(qualEq.attr) + Expression.toString(qualEq.lhs) + " = " + Expression.toString(qualEq.rhs);
        case qualEq as SIMPLE_EQUATION() then str + "[SIMP] " + EquationAttributes.toString(qualEq.attr) + ComponentRef.toString(qualEq.lhs) + " = " + ComponentRef.toString(qualEq.rhs);
        case qualEq as RECORD_EQUATION() then str + "[RECD] " + EquationAttributes.toString(qualEq.attr) + Expression.toString(qualEq.lhs) + " = " + Expression.toString(qualEq.rhs);
        case qualEq as ALGORITHM()       then str + "[ALGO] size " + intString(qualEq.size) + " " + EquationAttributes.toString(qualEq.attr) + "\n" + Algorithm.toString(qualEq.alg, str + "[----] ");
        case qualEq as IF_EQUATION()     then str + IfEquationBody.toString(qualEq.body, str + "[----] ", "[-IF-] ");
        case qualEq as FOR_EQUATION()    then str + forEquationToString(qualEq.iter, qualEq.range, qualEq.body, "", str + "[----] ", "[FOR-] ");
        case qualEq as WHEN_EQUATION()   then str + WhenEquationBody.toString(qualEq.body, str + "[----] ", "[WHEN] ");
        case qualEq as AUX_EQUATION()    then str + "[AUX-] Auxiliary equation for " + Variable.toString(Pointer.access(qualEq.auxiliary));
        case qualEq as DUMMY_EQUATION()  then str + "[DUMY] Dummy equation.";
        else                                  str + "[FAIL] " + getInstanceName() +  " failed!";
      end match;
    end toString;

    function makeStartEq
      input ComponentRef lhs;
      input ComponentRef rhs;
      output Equation eq;
    algorithm
      eq := SIMPLE_EQUATION(lhs, rhs, DAE.emptyElementSource, EQ_ATTR_DEFAULT_INITIAL);
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

    // TODO! use referenceEq when updating stuff
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
          Equation qualEq, body;
          MapFuncCref funcCref;
          Expression lhs, rhs, range;
          ComponentRef lhs_cref, rhs_cref;
          Algorithm alg;
          IfEquationBody ifEqBody;
          WhenEquationBody whenEqBody;
          Equation body, new_body;

        case qualEq as SCALAR_EQUATION()
          algorithm
            lhs := Expression.map(qualEq.lhs, funcExp);
            rhs := Expression.map(qualEq.rhs, funcExp);
            if not referenceEq(lhs, qualEq.lhs) then
              qualEq.lhs := lhs;
            end if;
            if not referenceEq(rhs, qualEq.rhs) then
              qualEq.rhs := rhs;
            end if;
        then qualEq;

        case qualEq as ARRAY_EQUATION()
          algorithm
            lhs := Expression.map(qualEq.lhs, funcExp);
            rhs := Expression.map(qualEq.rhs, funcExp);
            if not referenceEq(lhs, qualEq.lhs) then
              qualEq.lhs := lhs;
            end if;
            if not referenceEq(rhs, qualEq.rhs) then
              qualEq.rhs := rhs;
            end if;
        then qualEq;

        case qualEq as SIMPLE_EQUATION()
          algorithm
            if isSome(funcCrefOpt) then
              SOME(funcCref) := funcCrefOpt;
              lhs_cref := funcCref(qualEq.lhs);
              rhs_cref := funcCref(qualEq.rhs);
              if not referenceEq(lhs_cref, qualEq.lhs) then
                qualEq.lhs := lhs_cref;
              end if;
              if not referenceEq(rhs_cref, qualEq.rhs) then
                qualEq.rhs := rhs_cref;
              end if;
            end if;
        then qualEq;

        case qualEq as RECORD_EQUATION()
          algorithm
            lhs := Expression.map(qualEq.lhs, funcExp);
            rhs := Expression.map(qualEq.rhs, funcExp);
            if not referenceEq(lhs, qualEq.lhs) then
              qualEq.lhs := lhs;
            end if;
            if not referenceEq(rhs, qualEq.rhs) then
              qualEq.rhs := rhs;
            end if;
        then qualEq;

        case qualEq as ALGORITHM()
          algorithm
            alg := Algorithm.mapExp(qualEq.alg, funcExp);
            if isSome(funcCrefOpt) then
              SOME(funcCref) := funcCrefOpt;
              // ToDo referenceEq for lists?
              //alg.inputs := List.map(alg.inputs, funcCref);
              alg.outputs := List.map(alg.outputs, funcCref);
            end if;
            qualEq.alg := alg;
        then qualEq;

        case qualEq as IF_EQUATION()
          algorithm
            ifEqBody := IfEquationBody.map(qualEq.body, funcExp, funcCrefOpt);
            if not referenceEq(ifEqBody, qualEq.body) then
              qualEq.body := ifEqBody;
            end if;
        then qualEq;

        case qualEq as FOR_EQUATION()
          algorithm
            range := Expression.map(qualEq.range, funcExp);
            body := map(qualEq.body, funcExp, funcCrefOpt);
            if not referenceEq(range, qualEq.range) then
              qualEq.range := range;
            end if;
            if not referenceEq(body, qualEq.body) then
              qualEq.body := body;
            end if;
        then qualEq;

        case qualEq as WHEN_EQUATION()
          algorithm
            whenEqBody := WhenEquationBody.map(qualEq.body, funcExp, funcCrefOpt);
            if not referenceEq(whenEqBody, qualEq.body) then
              qualEq.body := whenEqBody;
            end if;
        then qualEq;

        case qualEq as AUX_EQUATION(body = SOME(body))
          algorithm
            new_body := map(body, funcExp, funcCrefOpt);
            if not referenceEq(new_body, body) then
              qualEq.body := SOME(new_body);
            end if;
        then qualEq;
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

    function simplify
      input output Equation eq;
    algorithm
      eq := match eq
        local
          Equation qual;
        case qual as SCALAR_EQUATION() algorithm
          qual.lhs := SimplifyExp.simplify(qual.lhs);
          qual.rhs := SimplifyExp.simplify(qual.rhs);
        then qual;
        case qual as ARRAY_EQUATION() algorithm
          qual.lhs := SimplifyExp.simplify(qual.lhs);
          qual.rhs := SimplifyExp.simplify(qual.rhs);
        then qual;
        case SIMPLE_EQUATION() then eq;
        case qual as RECORD_EQUATION() algorithm
          qual.lhs := SimplifyExp.simplify(qual.lhs);
          qual.rhs := SimplifyExp.simplify(qual.rhs);
        then qual;
        // ToDo: implement the following correctly:
        case qual as ALGORITHM()        then qual;
        case qual as IF_EQUATION()      then qual;
        case qual as FOR_EQUATION()     then qual;
        case qual as WHEN_EQUATION()    then qual;
        case qual as AUX_EQUATION()     then qual;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Equation.toString(eq)});
        then fail();
      end match;
    end simplify;

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
        local
          Equation qual;

        case qual as SCALAR_EQUATION() algorithm
            qual.attr := EquationAttributes.setResidualVar(qual.attr, residualVar);
        then qual;

        case qual as ARRAY_EQUATION() algorithm
            qual.attr := EquationAttributes.setResidualVar(qual.attr, residualVar);
        then qual;

        case qual as SIMPLE_EQUATION() algorithm
            qual.attr := EquationAttributes.setResidualVar(qual.attr, residualVar);
        then qual;

        // ToDo: add all other cases!

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for \n" + toString(eqn)});
        then fail();

      end match;
    end createResidual;

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
          WhenStatement qual;
          MapFuncCref funcCref;
          Expression lhs, rhs, value, condition;
          ComponentRef stateVar;

        case qual as ASSIGN()
          algorithm
            lhs := Expression.map(qual.lhs, funcExp);
            rhs := Expression.map(qual.rhs, funcExp);
            if not referenceEq(lhs, qual.lhs) then
              qual.lhs := lhs;
            end if;
            if not referenceEq(rhs, qual.rhs) then
              qual.rhs := rhs;
            end if;
        then qual;

        case qual as REINIT()
          algorithm
            if isSome(funcCrefOpt) then
              SOME(funcCref) := funcCrefOpt;
              stateVar := funcCref(qual.stateVar);
              if not referenceEq(stateVar, qual.stateVar) then
                qual.stateVar := stateVar;
              end if;
            end if;
            value := Expression.map(qual.value, funcExp);
            if not referenceEq(value, qual.value) then
              qual.value := value;
            end if;
        then qual;

        case qual as ASSERT()
          algorithm
            condition := Expression.map(qual.condition, funcExp);
            if not referenceEq(condition, qual.condition) then
              qual.condition := condition;
            end if;
        then qual;

        case qual as TERMINATE() then qual;

        case qual as NORETCALL()
          algorithm
            value := Expression.map(qual.exp, funcExp);
            if not referenceEq(value, qual.exp) then
              qual.exp := value;
            end if;
        then qual;

        else stmt;
      end match;
    end map;
  end WhenStatement;

  uniontype EquationAttributes
    record EQUATION_ATTRIBUTES // ToDo: replace differentiated by optional equation pointer to diffed eq (only TIME!)
      Boolean differentiated "true if the equation was differentiated, and should not be differentiated again to avoid equal equations";
      EquationKind kind;
      EvaluationStages evalStages;
      Option<Pointer<Variable>> residualVar;
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
        differentiated  = attributes.differentiated,
        kind            = EquationKind.convert(attributes.kind),
        evalStages      = EvaluationStages.convert(attributes.evalStages));
    end convert;
  end EquationAttributes;

  constant EquationAttributes EQ_ATTR_DEFAULT_DYNAMIC = EQUATION_ATTRIBUTES(false, DYNAMIC_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_BINDING = EQUATION_ATTRIBUTES(false, BINDING_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_INITIAL = EQUATION_ATTRIBUTES(false, INITIAL_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_DISCRETE = EQUATION_ATTRIBUTES(false, DISCRETE_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_AUX = EQUATION_ATTRIBUTES(false, AUX_EQUATION(), DEFAULT_EVALUATION_STAGES, NONE());
  constant EquationAttributes EQ_ATTR_DEFAULT_UNKNOWN = EQUATION_ATTRIBUTES(false, UNKNOWN_EQUATION_KIND(), DEFAULT_EVALUATION_STAGES, NONE());

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

  constant EvaluationStages DEFAULT_EVALUATION_STAGES = EVALUATION_STAGES(false,false,false,false);

  uniontype EquationPointers
    record EQUATION_POINTERS
      "author: kabdelhak 2020
      This uniontype is not really necessary, since it only wraps an expandable
      array of pointers to equations, but it makes it easier maintanable
      since all utility functions are in the same place. Also it mirrors
      VariablePointers behavior."
      ExpandableArray<Pointer<Equation>> eqArr;
    end EQUATION_POINTERS;

    function toString
      input EquationPointers equations;
      input output String str = "";
    protected
      Integer numberOfElements = ExpandableArray.getNumberOfElements(equations.eqArr);
    algorithm
      str := StringUtil.headline_4(str + " EquationPointers (" + intString(numberOfElements) + ")");
      for i in 1:numberOfElements loop
        str := str + "(" + intString(i) + ")" + Equation.toString(Pointer.access(ExpandableArray.get(i, equations.eqArr)), "\t") + "\n";
      end for;
    end toString;

    function empty
      "Creates an empty EquationPointers using given size."
      input Integer size = BaseHashTable.bigBucketSize;
      output EquationPointers equationPointers;
    protected
      Integer arr_size;
    algorithm
      arr_size := max(size, BaseHashTable.lowBucketSize);
      equationPointers := EQUATION_POINTERS(ExpandableArray.new(arr_size, Pointer.create(DUMMY_EQUATION())));
    end empty;

    function toList
      "Creates a EquationPointer list from EquationPointers."
      input EquationPointers equations;
      output list<Pointer<Equation>> eqn_lst;
    algorithm
      eqn_lst := ExpandableArray.toList(equations.eqArr);
    end toList;

    function fromList
      input list<Pointer<Equation>> eq_lst;
      output EquationPointers equationPointers;
    algorithm
      equationPointers := empty(listLength(eq_lst));
      equationPointers := addList(eq_lst, equationPointers);
    end fromList;

    function addList
      input list<Pointer<Equation>> eq_lst;
      input output EquationPointers equationPointers;
    algorithm
      for eq in eq_lst loop
        equationPointers.eqArr := ExpandableArray.add(eq, equationPointers.eqArr);
      end for;
    end addList;

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
    protected
      Pointer<Equation> eq_ptr;
      Equation eq, new_eq;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq_ptr := ExpandableArray.get(i, equations.eqArr);
          func(eq_ptr);
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
  end EquationPointers;

  uniontype EqData
    record EQ_DATA_SIM
      EquationPointers equations    "All equations";
      EquationPointers simulation   "All equations for simulation (without initial)";
      EquationPointers continuous   "Continuous equations";
      EquationPointers discretes    "Discrete equations";
      EquationPointers initials     "(Exclusively) Initial equations";
      EquationPointers auxiliaries  "Auxiliary equations";
    end EQ_DATA_SIM;

    record EQ_DATA_JAC
      EquationPointers equations    "All equations";
      EquationPointers results      "Result equations";
      EquationPointers temporary    "Temporary inner equations";
      EquationPointers auxiliaries  "Auxiliary equations";
    end EQ_DATA_JAC;

    record EQ_DATA_HESS
      EquationPointers equations    "All equations";
      Pointer<Equation> result      "Result equation";
      EquationPointers temporary    "Temporary inner equations";
      EquationPointers auxiliaries  "Auxiliary equations";
    end EQ_DATA_HESS;

    record EQ_DATA_EMPTY end EQ_DATA_EMPTY;

    function toString
      input EqData eqData;
      input Integer level = 0;
      output String str;
    algorithm
      str := match eqData
        local
          EqData qualEqData;
          String tmp;

        case qualEqData as EQ_DATA_SIM()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(qualEqData.equations, "Simulation");
            else
              tmp :=  EquationPointers.toString(qualEqData.continuous, "Continuous") + "\n" +
                      EquationPointers.toString(qualEqData.discretes, "Discrete") + "\n" +
                      EquationPointers.toString(qualEqData.initials, "(Exclusively) Initial") + "\n" +
                      EquationPointers.toString(qualEqData.auxiliaries, "Auxiliary");
            end if;
        then tmp;

        case qualEqData as EQ_DATA_JAC()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(qualEqData.equations, "Jacobian");
            else
              tmp :=  EquationPointers.toString(qualEqData.results, "Result") + "\n" +
                      EquationPointers.toString(qualEqData.temporary, "Temporary Inner") + "\n" +
                      EquationPointers.toString(qualEqData.auxiliaries, "Auxiliary");
            end if;
        then tmp;

        case qualEqData as EQ_DATA_HESS()
          algorithm
            if level == 0 then
              tmp :=  EquationPointers.toString(qualEqData.equations, "Hessian");
            else
              tmp :=  StringUtil.headline_4("Result Equation Pointer") + "\n" +
                      Equation.toString(Pointer.access(qualEqData.result)) + "\n" +
                      EquationPointers.toString(qualEqData.temporary, "Temporary Inner") + "\n" +
                      EquationPointers.toString(qualEqData.auxiliaries, "Auxiliary");
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
        local
          EqData qual;
        case qual as EQ_DATA_SIM() algorithm qual.equations := equations; then qual;
        case qual as EQ_DATA_JAC() algorithm qual.equations := equations; then qual;
        case qual as EQ_DATA_HESS() algorithm qual.equations := equations; then qual;
      end match;
    end setEquations;
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
