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
  import Expression = NFExpression;
  import InstNode = NFInstNode.InstNode;
  import Variable = NFVariable;

  // New Backend imports

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
      list<ComponentRef> inputs       "list of all (external) inputs, dependencies";
      list<ComponentRef> outputs      "list of all outputs";
      DAE.ElementSource source        "origin of algorithm";
      DAE.Expand expand               "this algorithm was translated from an equation. we should not expand array crefs!";
      EquationAttributes attr         "Additional Attributes";
    end ALGORITHM;

    record IF_EQUATION
      list<Expression> conditions     "Condition";
      list<list<Equation>> eqnstrue   "Equations of true branch";
      list<Equation> eqnsfalse        "Equations of false branch";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr         "Additional Attributes";
    end IF_EQUATION;

    record FOR_EQUATION
      InstNode iter                   "the iterator variable"; // Should this be a cref?
      Expression range                "Start - (Step) - Stop";
      Equation body                   "iterated equation";
      DAE.ElementSource source        "origin of equation";
      EquationAttributes attr;
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
      Option<Equation> body           "Optional body equation";
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
        case qualEq as SCALAR_EQUATION() then "[SCAL] " + Expression.toString(qualEq.lhs) + " = " + Expression.toString(qualEq.rhs);
        case qualEq as ARRAY_EQUATION() then  "[ARRY] " + Expression.toString(qualEq.lhs) + " = " + Expression.toString(qualEq.rhs);
        case qualEq as SIMPLE_EQUATION() then "[SIMP] " + ComponentRef.toString(qualEq.lhs) + " = " + ComponentRef.toString(qualEq.rhs);
        case qualEq as RECORD_EQUATION() then "[RECD] " + Expression.toString(qualEq.lhs) + " = " + Expression.toString(qualEq.rhs);
        case qualEq as ALGORITHM() then       "[ALGO] \n" + Algorithm.toString(qualEq.alg);
        case qualEq as IF_EQUATION() then     "[-IF-] ";
        case qualEq as FOR_EQUATION() then    "[FOR-] ";
        case qualEq as WHEN_EQUATION() then   WhenEquationBody.toString(qualEq.body, "", str + "[----] ", "[WHEN] ");
        case qualEq as AUX_EQUATION() then    "[AUX-] ";
        case qualEq as DUMMY_EQUATION() then  "[DUMY] Dummy equation.";
        else                                  "[FAIL] Equation.toString failed!";
      end match;
    end toString;

    function getAttributes
      input Equation eq;
      output EquationAttributes attr;
    algorithm
      attr := match eq
        local
          EquationAttributes tmp;
          Equation body;
        case SCALAR_EQUATION(attr = tmp) then tmp;
        case ARRAY_EQUATION(attr = tmp) then tmp;
        case SIMPLE_EQUATION(attr = tmp) then tmp;
        case RECORD_EQUATION(attr = tmp) then tmp;
        case ALGORITHM(attr = tmp) then tmp;
        case IF_EQUATION(attr = tmp) then tmp;
        case FOR_EQUATION(attr = tmp) then tmp;
        case WHEN_EQUATION(attr = tmp) then tmp;
        case AUX_EQUATION(body = SOME(body)) then getAttributes(body);
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
          list<list<Equation>> eqnstrue = {};

        case qualEq as SCALAR_EQUATION()
          algorithm
            qualEq.lhs := funcExp(qualEq.lhs);
            qualEq.rhs := funcExp(qualEq.rhs);
        then qualEq;

        case qualEq as ARRAY_EQUATION()
          algorithm
            qualEq.lhs := funcExp(qualEq.lhs);
            qualEq.rhs := funcExp(qualEq.rhs);
        then qualEq;

        case qualEq as SIMPLE_EQUATION() guard(isSome(funcCrefOpt))
          algorithm
            SOME(funcCref) := funcCrefOpt;
            qualEq.lhs := funcCref(qualEq.lhs);
            qualEq.rhs := funcCref(qualEq.rhs);
        then qualEq;

        case qualEq as RECORD_EQUATION()
          algorithm
            qualEq.lhs := funcExp(qualEq.lhs);
            qualEq.rhs := funcExp(qualEq.rhs);
        then qualEq;

        case qualEq as ALGORITHM()
          algorithm
            qualEq.alg := Algorithm.mapExp(qualEq.alg, funcExp);
            if isSome(funcCrefOpt) then
              SOME(funcCref) := funcCrefOpt;
              qualEq.inputs := List.map(qualEq.inputs, funcCref);
              qualEq.outputs := List.map(qualEq.outputs, funcCref);
            end if;
        then qualEq;

        case qualEq as IF_EQUATION()
          algorithm
            qualEq.conditions := List.map(qualEq.conditions, funcExp);
            for eqn_lst in qualEq.eqnstrue loop
              eqnstrue := List.map2(eqn_lst, map, funcExp, funcCrefOpt) :: eqnstrue;
            end for;
            qualEq.eqnstrue := listReverse(eqnstrue);
            qualEq.eqnsfalse := List.map2(qualEq.eqnsfalse, map, funcExp, funcCrefOpt);
        then qualEq;

        case qualEq as FOR_EQUATION()
          algorithm
            qualEq.range := funcExp(qualEq.range);
            qualEq.body := map(qualEq.body, funcExp, funcCrefOpt);
            qualEq.range := funcExp(qualEq.range);
        then qualEq;

        case qualEq as WHEN_EQUATION()
          algorithm
            qualEq.body := WhenEquationBody.map(qualEq.body, funcExp, funcCrefOpt);
        then qualEq;

        case qualEq as AUX_EQUATION(body = SOME(body))
          algorithm
            qualEq.body := SOME(map(body, funcExp, funcCrefOpt));
        then qualEq;
      end match;
    end map;

  end Equation;

  uniontype WhenEquationBody
    record WHEN_EQUATION_BODY "equation when condition then cr = exp, reinit(...), terminate(...) or assert(...)"
      Expression condition                "the when-condition" ;
      list<WhenStatement> when_stmts;
      Option<WhenEquationBody> else_when "elsewhen equation with the same cref on the left hand side.";
    end WHEN_EQUATION_BODY;

    function toString
      input WhenEquationBody body;
      input output String str = "";
      input String indent = "";
      input String elseStr = "";
    protected
      WhenEquationBody elseWhen;
    algorithm
      str := str + elseStr + "when " + Expression.toString(body.condition) + " then \n";
      for stmt in body.when_stmts loop
        str := str + WhenStatement.toString(stmt, indent + "  ") + "\n";
      end for;
      if isSome(body.else_when) then
        SOME(elseWhen) := body.else_when;
        str := str + WhenEquationBody.toString(elseWhen, indent, indent +"else ");
      end if;
      str := str + indent + "end when;";
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
    algorithm
      whenBody.condition := funcExp(whenBody.condition);
      whenBody.when_stmts := List.map2(whenBody.when_stmts, WhenStatement.map, funcExp, funcCrefOpt);
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
                                                                              else str + "NBEquation.WhenStatement.toString failed.";
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

        case qual as ASSIGN()
          algorithm
            qual.lhs := funcExp(qual.lhs);
            qual.rhs := funcExp(qual.rhs);
        then qual;

        case qual as REINIT()
          algorithm
            if isSome(funcCrefOpt) then
              SOME(funcCref) := funcCrefOpt;
              qual.stateVar := funcCref(qual.stateVar);
            end if;
            qual.value := funcExp(qual.value);
        then qual;

        case qual as ASSERT()
          algorithm
            qual.condition := funcExp(qual.condition);
            // These might not be neccessary
            qual.message := funcExp(qual.message);
            qual.level := funcExp(qual.level);
        then qual;

        case qual as TERMINATE()
          algorithm
            // This might not be neccessary
            qual.message := funcExp(qual.message);
        then qual;

        case qual as NORETCALL()
          algorithm
            qual.exp := funcExp(qual.exp);
        then qual;

        else stmt;
      end match;
    end map;
  end WhenStatement;

  uniontype EquationAttributes
    record EQUATION_ATTRIBUTES
      Boolean differentiated "true if the equation was differentiated, and should not be differentiated again to avoid equal equations";
      EquationKind kind;
      EvaluationStages evalStages;
    end EQUATION_ATTRIBUTES;
  end EquationAttributes;

  constant EquationAttributes EQ_ATTR_DEFAULT_DYNAMIC = EQUATION_ATTRIBUTES(false, DYNAMIC_EQUATION(), DEFAULT_EVALUATION_STAGES);
  constant EquationAttributes EQ_ATTR_DEFAULT_BINDING = EQUATION_ATTRIBUTES(false, BINDING_EQUATION(), DEFAULT_EVALUATION_STAGES);
  constant EquationAttributes EQ_ATTR_DEFAULT_INITIAL = EQUATION_ATTRIBUTES(false, INITIAL_EQUATION(), DEFAULT_EVALUATION_STAGES);
  constant EquationAttributes EQ_ATTR_DEFAULT_DISCRETE = EQUATION_ATTRIBUTES(false, DISCRETE_EQUATION(), DEFAULT_EVALUATION_STAGES);
  constant EquationAttributes EQ_ATTR_DEFAULT_AUX = EQUATION_ATTRIBUTES(false, AUX_EQUATION(), DEFAULT_EVALUATION_STAGES);
  constant EquationAttributes EQ_ATTR_DEFAULT_UNKNOWN = EQUATION_ATTRIBUTES(false, UNKNOWN_EQUATION_KIND(), DEFAULT_EVALUATION_STAGES);

  uniontype EquationKind

    record BINDING_EQUATION
    end BINDING_EQUATION;
    record DYNAMIC_EQUATION
    end DYNAMIC_EQUATION;
    record INITIAL_EQUATION
    end INITIAL_EQUATION;
    record CLOCKED_EQUATION
      Integer clk;
    end CLOCKED_EQUATION;
    record DISCRETE_EQUATION
    end DISCRETE_EQUATION;
    record AUX_EQUATION
      "ToDo! Do we still need this?"
    end AUX_EQUATION;
    record UNKNOWN_EQUATION_KIND
    end UNKNOWN_EQUATION_KIND;
  end EquationKind;

  uniontype EvaluationStages
    record EVALUATION_STAGES
      Boolean dynamicEval;
      Boolean algebraicEval;
      Boolean zerocrossEval;
      Boolean discreteEval;
    end EVALUATION_STAGES;
  end EvaluationStages;

  constant EvaluationStages DEFAULT_EVALUATION_STAGES = EVALUATION_STAGES(false,false,false,false);


  uniontype Equations
    record EQUATIONS
      ExpandableArray<Equation> eqArr;
    end EQUATIONS;

    function toString
      input Equations equations;
      input output String str = "";
    protected
      Integer numberOfElements = ExpandableArray.getNumberOfElements(equations.eqArr);
    algorithm
      str := StringUtil.headline_3(str + " Equations (" + intString(numberOfElements) + ")") + "\n";
      for i in 1:numberOfElements loop
        str := str + "(" + intString(i) + ")\t" + Equation.toString(ExpandableArray.get(i, equations.eqArr), "\t") + "\n";
      end for;
    end toString;

    function fromList
      input list<Equation> eq_lst;
      output Equations equations;
    algorithm
    equations := EQUATIONS(ExpandableArray.new(listLength(eq_lst), DUMMY_EQUATION()));
      for eq in eq_lst loop
        equations.eqArr := ExpandableArray.add(eq, equations.eqArr);
      end for;
    end fromList;

    function map
      "Traverses all equations and applies a function to them."
      input output Equations equations;
      input MapFunc func;
      partial function MapFunc
        input output Equation e;
      end MapFunc;
    protected
      Equation eq, new_eq;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq := ExpandableArray.get(i, equations.eqArr);
          new_eq := func(eq);
          if not referenceEq(eq, new_eq) then
            ExpandableArray.update(i, new_eq, equations.eqArr);
          end if;
        end if;
      end for;
    end map;

    function mapExp
      "Traverses all expressions of all equations and applies a function to it.
      Optional second input to also traverse crefs, only needed for simple
      eqns, when eqns and algorithms."
      input output Equations equations;
      input MapFuncExp funcExp;
      input Option<MapFuncCref> funcCrefOpt = NONE();
      partial function MapFuncExp
        input output Expression e;
      end MapFuncExp;
      partial function MapFuncCref
        input output ComponentRef c;
      end MapFuncCref;
    protected
      Equation eq, new_eq;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq := ExpandableArray.get(i, equations.eqArr);
          new_eq := Equation.map(eq, funcExp, funcCrefOpt);
          if not referenceEq(eq, new_eq) then
            ExpandableArray.update(i, new_eq, equations.eqArr);
          end if;
        end if;
      end for;
    end mapExp;
  end Equations;

  uniontype EquationPointers
    record EQUATION_POINTERS
      ExpandableArray<Pointer<Equation>> eqArr;
    end EQUATION_POINTERS;

    function toString
      input EquationPointers equations;
      input output String str = "";
    protected
      Integer numberOfElements = ExpandableArray.getNumberOfElements(equations.eqArr);
    algorithm
      str := StringUtil.headline_4(str + " EquationPointers (" + intString(numberOfElements) + ")") + "\n";
      for i in 1:numberOfElements loop
        str := str + "(" + intString(i) + ")\t" + Equation.toString(Pointer.access(ExpandableArray.get(i, equations.eqArr)), "\t") + "\n";
      end for;
    end toString;

    function fromList
      input list<Pointer<Equation>> eq_lst;
      output EquationPointers equationPointers;
    algorithm
    equationPointers := EQUATION_POINTERS(ExpandableArray.new(listLength(eq_lst), Pointer.create(DUMMY_EQUATION())));
      for eq in eq_lst loop
        equationPointers.eqArr := ExpandableArray.add(eq, equationPointers.eqArr);
      end for;
    end fromList;

    function map
      "Traverses all equations and applies a function to them."
      input output EquationPointers equations;
      input MapFunc func;
      partial function MapFunc
        input output Equation e;
      end MapFunc;
    protected
      Equation eq, new_eq;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq := Pointer.access(ExpandableArray.get(i, equations.eqArr));
          new_eq := func(eq);
          if not referenceEq(eq, new_eq) then
            ExpandableArray.update(i, Pointer.create(new_eq), equations.eqArr);
          end if;
        end if;
      end for;
    end map;

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
      Equation eq, new_eq;
    algorithm
      for i in 1:ExpandableArray.getLastUsedIndex(equations.eqArr) loop
        if ExpandableArray.occupied(i, equations.eqArr) then
          eq := Pointer.access(ExpandableArray.get(i, equations.eqArr));
          new_eq := Equation.map(eq, funcExp, funcCrefOpt);
          if not referenceEq(eq, new_eq) then
            ExpandableArray.update(i, Pointer.create(new_eq), equations.eqArr);
          end if;
        end if;
      end for;
    end mapExp;
  end EquationPointers;

  uniontype EqData
    record EQ_DATA_SIM
      Equations equations           "All equations";
      EquationPointers continuous   "Continuous equations";
      EquationPointers discretes    "Discrete equations";
      EquationPointers initials     "(Exclusively) Initial equations";
      EquationPointers auxiliaries  "Auxiliary equations";
    end EQ_DATA_SIM;

    record EQ_DATA_JAC
      Equations equations           "All equations";
      EquationPointers results      "Result equations";
      EquationPointers temporary    "Temporary inner equations";
      EquationPointers auxiliaries  "Auxiliary equations";
    end EQ_DATA_JAC;

    record EQ_DATA_HESS
      Equations equations           "All equations";
      Pointer<Equation> result      "Result equation";
      EquationPointers temporary    "Temporary inner equations";
      EquationPointers auxiliaries  "Auxiliary equations";
    end EQ_DATA_HESS;

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
              tmp :=  Equations.toString(qualEqData.equations, "Simulation");
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
              tmp :=  Equations.toString(qualEqData.equations, "Jacobian");
            else
              tmp :=  EquationPointers.toString(qualEqData.results, "Result") + "\n" +
                      EquationPointers.toString(qualEqData.temporary, "Temporary Inner") + "\n" +
                      EquationPointers.toString(qualEqData.auxiliaries, "Auxiliary");
            end if;
        then tmp;
        case qualEqData as EQ_DATA_HESS()
          algorithm
            if level == 0 then
              tmp :=  Equations.toString(qualEqData.equations, "Hessian");
            else
              tmp :=  StringUtil.headline_4("Result Equation Pointer") + "\n" +
                      Equation.toString(Pointer.access(qualEqData.result)) + "\n" +
                      EquationPointers.toString(qualEqData.temporary, "Temporary Inner") + "\n" +
                      EquationPointers.toString(qualEqData.auxiliaries, "Auxiliary");
            end if;
        then tmp;

      else "NBEquation.EqData.toString failed!\n";
      end match;
    end toString;

  end EqData;

  annotation(__OpenModelica_Interface="backend");
end NBEquation;
