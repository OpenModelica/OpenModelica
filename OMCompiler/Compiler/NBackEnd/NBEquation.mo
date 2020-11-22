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
  import DAEDump;

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

  type Equations = ExpandableArray<Equation>;
  type EquationPointers = ExpandableArray<Pointer<Equation>>;

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

    function equationsToString
      input Equations equations;
      input output String str = "";
    protected
      Integer numberOfElements = ExpandableArray.getNumberOfElements(equations);
    algorithm
      str := StringUtil.headline_3(str + " Equations (" + intString(numberOfElements) + ")") + "\n";
      for i in 1:numberOfElements loop
        str := str + "(" + intString(i) + ")\t" + toString(ExpandableArray.get(i, equations), "\t") + "\n";
      end for;
    end equationsToString;

    function equationPointersToString
      input EquationPointers equations;
      input output String str = "";
    protected
      Integer numberOfElements = ExpandableArray.getNumberOfElements(equations);
    algorithm
      str := StringUtil.headline_4(str + " Equation Pointers (" + intString(numberOfElements) + ")") + "\n";
      for i in 1:numberOfElements loop
        str := str + "(" + intString(i) + ")\t" + toString(Pointer.access(ExpandableArray.get(i, equations)), "\t") + "\n";
      end for;
    end equationPointersToString;

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

  annotation(__OpenModelica_Interface="backend");
end NBEquation;
