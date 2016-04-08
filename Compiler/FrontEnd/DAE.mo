/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated package DAE
" file:        DAE.mo
  package:     DAE
  description: DAE management and output


  This module defines data structures for DAE equations and declarations of
  variables and functions. The DAE data structure is the result of flattening,
  containing only flat modelica, i.e. equations, algorithms, variables and
  functions."

// public imports
public import Absyn;
public import ClassInf;
public import SCode;
public import Values;

public type Ident = String;

public type InstDims = list<Dimension>;

public type StartValue = Option<Exp>;

public constant String UNIQUEIO = "$unique$outer$";

public constant String derivativeNamePrefix = "$DER";
public constant String preNamePrefix = "$PRE";
public constant String previousNamePrefix = "$CLKPRE";
public constant String startNamePrefix = "$START";


public uniontype VarKind
  record VARIABLE "variable" end VARIABLE;
  record DISCRETE "discrete" end DISCRETE;
  record PARAM "parameter"   end PARAM;
  record CONST "constant"    end CONST;
end VarKind;

public uniontype ConnectorType
  record POTENTIAL end POTENTIAL;
  record FLOW end FLOW;
  record STREAM end STREAM;
  record NON_CONNECTOR end NON_CONNECTOR;
end ConnectorType;

public uniontype VarDirection
  record INPUT  "input"                   end INPUT;
  record OUTPUT "output"                  end OUTPUT;
  record BIDIR  "neither input or output" end BIDIR;
end VarDirection;

public uniontype VarParallelism
  record PARGLOBAL     "Global variables for CUDA and OpenCL"     end PARGLOBAL;
  record PARLOCAL      "Shared for CUDA and local for OpenCL"     end PARLOCAL;
  record NON_PARALLEL  "Non parallel/Normal variables"            end NON_PARALLEL;
end VarParallelism;

public uniontype VarVisibility
  record PUBLIC "public variables"       end PUBLIC;
  record PROTECTED "protected variables" end PROTECTED;
end VarVisibility;

public uniontype VarInnerOuter
  record INNER           "an inner prefix"       end INNER;
  record OUTER           "an outer prefix"       end OUTER;
  record INNER_OUTER     "an inner outer prefix" end INNER_OUTER;
  record NOT_INNER_OUTER "no inner outer prefix" end NOT_INNER_OUTER;
end VarInnerOuter;

uniontype ElementSource "gives information about the origin of the element"
  record SOURCE
    SourceInfo info "the line and column numbers of the equations and algorithms this element came from";
    list<Absyn.Within> partOfLst "the model(s) this element came from";
    Option<ComponentRef> instanceOpt "the instance(s) this element is part of";
    list<tuple<ComponentRef, ComponentRef>> connectEquationOptLst "this element came from this connect(s)";
    list<Absyn.Path> typeLst "the classes where the type(s) of the element is defined";
    list<SymbolicOperation> operations "the symbolic operations used to end up with the final state of the element";
    list<SCode.Comment> comment;
  end SOURCE;
end ElementSource;

public constant ElementSource emptyElementSource = SOURCE(Absyn.dummyInfo,{},NONE(),{},{},{},{});

public uniontype SymbolicOperation
  record FLATTEN "From one equation/statement to an element"
    SCode.EEquation scode;
    Option<Element> dae;
  end FLATTEN;
  record SIMPLIFY "Before and after expression is equivalent"
    EquationExp before;
    EquationExp after;
  end SIMPLIFY;
  record SUBSTITUTION "A chain of substitutions"
    list<Exp> substitutions;
    Exp source;
  end SUBSTITUTION;
  record OP_INLINE "Before and after inlining of function calls"
    EquationExp before;
    EquationExp after;
  end OP_INLINE;
  record OP_SCALARIZE "Convert array equation into scalar equations; x = {1,2}, [1] => x[1] = {1}"
    EquationExp before;
    Integer index;
    EquationExp after;
  end OP_SCALARIZE;
  record OP_DIFFERENTIATE "Differentiate w.r.t. cr"
    ComponentRef cr;
    Exp before;
    Exp after;
  end OP_DIFFERENTIATE;

  record SOLVE "Solve equation, exp1 = exp2 => cr = exp; note that assertions may have been generated for example in case of divisions"
    ComponentRef cr;
    Exp exp1;
    Exp exp2;
    Exp res;
    list<Exp> assertConds;
  end SOLVE;
  record SOLVED "Equation is solved"
    ComponentRef cr;
    Exp exp;
  end SOLVED;
  record LINEAR_SOLVED "Solved linear system of equations"
    list<ComponentRef> vars;
    list<list<Real>> jac;
    list<Real> rhs;
    list<Real> result;
  end LINEAR_SOLVED;
  record NEW_DUMMY_DER "Introduced a dummy derivative (from index reduction)"
    ComponentRef chosen;
    list<ComponentRef> candidates;
  end NEW_DUMMY_DER;
  record OP_RESIDUAL "Converted the equation into residual form, to use nonlinear equation solvers 0=e (0=e1-e2)"
    Exp e1;
    Exp e2;
    Exp e;
  end OP_RESIDUAL;
end SymbolicOperation;

public uniontype EquationExp "An equation on residual or equality form has 1 or 2 expressions. For use with symbolic operation tracing."
  record PARTIAL_EQUATION "An expression that is part of the whole equation"
    Exp exp;
  end PARTIAL_EQUATION;
  record RESIDUAL_EXP "0 = exp"
    Exp exp;
  end RESIDUAL_EXP;
  record EQUALITY_EXPS "lhs = rhs"
    Exp lhs, rhs;
  end EQUALITY_EXPS;
end EquationExp;

public uniontype Element
  record VAR
    ComponentRef componentRef " The variable name";
    VarKind kind "varible kind: variable, constant, parameter, discrete etc." ;
    VarDirection direction "input, output or bidir" ;
    VarParallelism parallelism "parglobal, parlocal, or non_parallel";
    VarVisibility protection "if protected or public";
    Type ty "Full type information required";
    Option<Exp> binding "Binding expression e.g. for parameters ; value of start attribute";
    InstDims  dims "dimensions";
    ConnectorType connectorType "The connector type: flow, stream, no prefix, or not a connector element.";
    ElementSource source "the origins of the component/equation/algorithm";
    Option<VariableAttributes> variableAttributesOption;
    Option<SCode.Comment> comment;
    Absyn.InnerOuter innerOuter "inner/outer required to 'change' outer references";
  end VAR;

  record DEFINE "A solved equation"
    ComponentRef componentRef;
    Exp exp;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end DEFINE;

  record INITIALDEFINE " A solved initial equation"
    ComponentRef componentRef;
    Exp exp;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end INITIALDEFINE;

  record EQUATION "Scalar equation"
    Exp exp;
    Exp scalar;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end EQUATION;

  record EQUEQUATION "effort variable equality"
    ComponentRef cr1;
    ComponentRef cr2;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end EQUEQUATION;

  record ARRAY_EQUATION " an array equation"
    Dimensions dimension "dimension sizes" ;
    Exp exp;
    Exp array;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end ARRAY_EQUATION;

  record INITIAL_ARRAY_EQUATION "An initial array equation"
    Dimensions dimension "dimension sizes";
    Exp exp;
    Exp array;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end INITIAL_ARRAY_EQUATION;

  record COMPLEX_EQUATION "an equation of complex type, e.g. record = func(..)"
    Exp lhs;
    Exp rhs;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end COMPLEX_EQUATION;

  record INITIAL_COMPLEX_EQUATION "an initial equation of complex type, e.g. record = func(..)"
    Exp lhs;
    Exp rhs;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end INITIAL_COMPLEX_EQUATION;

  record WHEN_EQUATION " a when equation"
    Exp condition "Condition" ;
    list<Element> equations "Equations" ;
    Option<Element> elsewhen_ "Elsewhen should be of type WHEN_EQUATION" ;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end WHEN_EQUATION;

  record IF_EQUATION " an if-equation"
    list<Exp> condition1 "Condition" ;
    list<list<Element>> equations2 "Equations of true branch" ;
    list<Element> equations3 "Equations of false branch" ;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end IF_EQUATION;

  record INITIAL_IF_EQUATION "An initial if-equation"
    list<Exp> condition1 "Condition" ;
    list<list<Element>> equations2 "Equations of true branch" ;
    list<Element> equations3 "Equations of false branch" ;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end INITIAL_IF_EQUATION;

  record INITIALEQUATION " An initial equaton"
    Exp exp1;
    Exp exp2;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end INITIALEQUATION;

  record ALGORITHM " An algorithm section"
    Algorithm algorithm_;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end ALGORITHM;

  record INITIALALGORITHM " An initial algorithm section"
    Algorithm algorithm_;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end INITIALALGORITHM;

  record COMP
    Ident ident;
    list<Element> dAElist "a component with subelements, normally only used at top level.";
    ElementSource source "the origin of the component/equation/algorithm" ; // we might not this here.
    Option<SCode.Comment> comment;
  end COMP;

  record EXTOBJECTCLASS "The 'class' of an external object"
    Absyn.Path path "className of external object";
    ElementSource source "the origin of the component/equation/algorithm" ;
  end EXTOBJECTCLASS;

  record ASSERT " The Modelica builtin assert"
    Exp condition;
    Exp message;
    Exp level;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end ASSERT;

  record TERMINATE " The Modelica builtin terminate(msg)"
    Exp message;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end TERMINATE;

  record REINIT " reinit operator for reinitialization of states"
    ComponentRef componentRef;
    Exp exp;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end REINIT;

  record NORETCALL "call with no return value, i.e. no equation.
    Typically sideeffect call of external function but also
    Connections.* i.e. Connections.root(...) functions."
    Exp exp;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end NORETCALL;

  record INITIAL_NORETCALL "call with no return value, i.e. no equation.
    Typically sideeffect call of external function but also
    Connections.* i.e. Connections.root(...) functions."
    Exp exp;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end INITIAL_NORETCALL;

  record CONSTRAINT " constraint section"
    Constraint constraints;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end CONSTRAINT;

  record CLASS_ATTRIBUTES
    ClassAttributes classAttrs;
  end CLASS_ATTRIBUTES;

  record FLAT_SM "Flat state machine section"
    Ident ident;
    list<Element> dAElist "The states/modes transitions and variable
                      merging equations within the the flat state machine";
  end FLAT_SM;

  record SM_COMP "A state/mode component in a state machine"
    ComponentRef componentRef;
    list<Element> dAElist "a component with subelements";
  end SM_COMP;


end Element;

public constant Type T_ASSERTIONLEVEL = T_ENUMERATION(NONE(), Absyn.FULLYQUALIFIED(Absyn.IDENT("AssertionLevel")), {"error","warning"}, {}, {}, emptyTypeSource);
public constant Exp ASSERTIONLEVEL_ERROR = ENUM_LITERAL(Absyn.QUALIFIED("AssertionLevel",Absyn.IDENT("error")),1);
public constant Exp ASSERTIONLEVEL_WARNING = ENUM_LITERAL(Absyn.QUALIFIED("AssertionLevel",Absyn.IDENT("warning")),2);

public uniontype Function
  record FUNCTION " A Modelica function"
    Absyn.Path path;
    list<FunctionDefinition> functions "contains the body and an optional function derivative mapping";
    Type type_;
    SCode.Visibility visibility;
    Boolean partialPrefix "MetaModelica extension";
    Boolean isImpure "Modelica 3.3 impure/pure, by default isImpure = false all the time only if prefix *impure* function is specified";
    InlineType inlineType;
    ElementSource source "the origin of the component/equation/algorithm" ;
    Option<SCode.Comment> comment;
  end FUNCTION;

  record RECORD_CONSTRUCTOR "A Modelica record constructor. The function can be generated from the Path and Type alone."
    Absyn.Path path;
    Type type_;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end RECORD_CONSTRUCTOR;
end Function;

public uniontype InlineType
  record NORM_INLINE "Normal inline, inline as soon as possible"
  end NORM_INLINE;

  record BUILTIN_EARLY_INLINE "Inline even if inlining is globally disabled by flags."
  end BUILTIN_EARLY_INLINE;

  record EARLY_INLINE "Inline even earlier than NORM_INLINE. This will display the inlined code in the flattened model and also works for functions calling other functions that should be inlined."
  end EARLY_INLINE;

  record DEFAULT_INLINE "no user option, tool can inline this functio if necessary"
  end DEFAULT_INLINE;

  record NO_INLINE "don't inline this function, set with Inline=false"
  end NO_INLINE;

  record AFTER_INDEX_RED_INLINE "Try to inline after index reduction"
  end AFTER_INDEX_RED_INLINE;
end InlineType;

public uniontype FunctionDefinition

   record FUNCTION_DEF "Normal function body"
     list<Element> body;
   end FUNCTION_DEF;

   record FUNCTION_EXT "Normal external function declaration"
    list<Element> body;
    ExternalDecl externalDecl;
   end FUNCTION_EXT;

  record FUNCTION_DER_MAPPER "Contains derivatives for function"
    Absyn.Path derivedFunction "Function that is derived";
    Absyn.Path derivativeFunction "Path to derivative function";
    Integer derivativeOrder "in case a function have multiple derivatives, include all";
    list<tuple<Integer,derivativeCond>> conditionRefs;
    Option<Absyn.Path> defaultDerivative "if conditions fails, use default derivative if exists";
    list<Absyn.Path> lowerOrderDerivatives;
  end FUNCTION_DER_MAPPER;
end FunctionDefinition;

public
uniontype derivativeCond "Different conditions on derivatives"
  record ZERO_DERIVATIVE end ZERO_DERIVATIVE;
  record NO_DERIVATIVE Exp binding; end NO_DERIVATIVE;
end derivativeCond;

public
uniontype VariableAttributes
  record VAR_ATTR_REAL
    Option<Exp> quantity "quantity";
    Option<Exp> unit "unit";
    Option<Exp> displayUnit "displayUnit";
    Option<Exp> min;
    Option<Exp> max;
    Option<Exp> start "start value";
    Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
    Option<Exp> nominal "nominal";
    Option<StateSelect> stateSelectOption;
    Option<Uncertainty> uncertainOption;
    Option<Distribution> distributionOption;
    Option<Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
    Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
  end VAR_ATTR_REAL;

  record VAR_ATTR_INT
    Option<Exp> quantity "quantity";
    Option<Exp> min;
    Option<Exp> max;
    Option<Exp> start "start value";
    Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
    Option<Uncertainty> uncertainOption;
    Option<Distribution> distributionOption;
    Option<Exp> equationBound;
    Option<Boolean> isProtected; // ,eb,ip
    Option<Boolean> finalPrefix;
    Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
  end VAR_ATTR_INT;

  record VAR_ATTR_BOOL
    Option<Exp> quantity "quantity";
    Option<Exp> start "start value";
    Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
    Option<Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
    Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
  end VAR_ATTR_BOOL;

  record VAR_ATTR_CLOCK
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
  end VAR_ATTR_CLOCK;

  record VAR_ATTR_STRING
    Option<Exp> quantity "quantity";
    Option<Exp> start "start value";
    Option<Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
    Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
  end VAR_ATTR_STRING;

  record VAR_ATTR_ENUMERATION
    Option<Exp> quantity "quantity";
    Option<Exp> min;
    Option<Exp> max;
    Option<Exp> start "start";
    Option<Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables";
    Option<Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
    Option<Exp> startOrigin "where did start=X came from? NONE()|SOME(DAE.SCONST binding|type|undefined)";
  end VAR_ATTR_ENUMERATION;
end VariableAttributes;

public uniontype StateSelect
  record NEVER end NEVER;
  record AVOID end AVOID;
  record DEFAULT end DEFAULT;
  record PREFER end PREFER;
  record ALWAYS end ALWAYS;
end StateSelect;

public uniontype Uncertainty
  record GIVEN end GIVEN;
  record SOUGHT end SOUGHT;
  record REFINE end REFINE;
end Uncertainty;

public uniontype Distribution
  record DISTRIBUTION "see Distribution record in Distribution"
    Exp name;
    Exp params;
    Exp paramNames;
  end DISTRIBUTION;
end Distribution;

public uniontype ExtArg
  record EXTARG
    ComponentRef componentRef;
    Attributes attributes;
    Type type_;
  end EXTARG;

  record EXTARGEXP
    Exp exp;
    Type type_;
  end EXTARGEXP;

  record EXTARGSIZE
    ComponentRef componentRef;
    Attributes attributes;
    Type type_;
    Exp exp;
  end EXTARGSIZE;

  record NOEXTARG end NOEXTARG;
end ExtArg;

public uniontype ExternalDecl
  record EXTERNALDECL
    String name;
    list<ExtArg> args;
    ExtArg returnArg;
    String language;
    Option<SCode.Annotation> ann;
  end EXTERNALDECL;
end ExternalDecl;

public uniontype DAElist "A DAElist is a list of Elements. Variables, equations, functions,
  algorithms, etc. are all found in this list.
"
  record DAE
    list<Element> elementLst;
  end DAE;
end DAElist;

/* AVLTree for functions */
public type AvlKey = Absyn.Path;

public type AvlValue = Option<Function>;

public type FunctionTree = AvlTree;

public
uniontype AvlTree "The binary tree data structure
 "
  record AVLTREENODE
    Option<AvlTreeValue> value "Value" ;
    Integer height "heigth of tree, used for balancing";
    Option<AvlTree> left "left subtree" ;
    Option<AvlTree> right "right subtree" ;
  end AVLTREENODE;

end AvlTree;

public
uniontype AvlTreeValue "Each node in the binary tree can have a value associated with it."
  record AVLTREEVALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end AVLTREEVALUE;

end AvlTreeValue;

/* -- Algorithm.mo -- */
public
uniontype Algorithm "The `Algorithm\' type corresponds to a whole algorithm section.
  It is simple a list of algorithm statements."
  record ALGORITHM_STMTS
    list<Statement> statementLst;
  end ALGORITHM_STMTS;

end Algorithm;

public
uniontype Constraint "Optimica extension: The `Constraints\' type corresponds to a whole Constraint section.
  It is simple a list of expressions."
  record CONSTRAINT_EXPS
    list<Exp> constraintLst;
  end CONSTRAINT_EXPS;

  record CONSTRAINT_DT "Constraints needed for proper Dynamic Tearing"
    Exp constraint;
    Boolean localCon "local or global constraint; local constraints depend on variables that are computed within the algebraic loop itself";
  end CONSTRAINT_DT;
end Constraint;

public
uniontype ClassAttributes "currently for Optimica extension: these are the objectives of optimization class"
  record OPTIMIZATION_ATTRS
    Option<Exp> objetiveE;
    Option<Exp> objectiveIntegrandE;
    Option<Exp> startTimeE;
    Option<Exp> finalTimeE;
  end OPTIMIZATION_ATTRS;
end ClassAttributes;

/* TODO: create a backend and a simcode uniontype */
public
uniontype Statement "There are four kinds of statements:
    1. assignments ('a := b;')
    2. if statements ('if A then B; elseif C; else D;')
    3. for loops ('for i in 1:10 loop ...; end for;')
    4. when statements ('when E do S; end when;')"
  record STMT_ASSIGN
    Type type_;
    Exp exp1;
    Exp exp;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_ASSIGN;

  record STMT_TUPLE_ASSIGN
    Type type_;
    list<Exp> expExpLst;
    Exp exp;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_TUPLE_ASSIGN;

  record STMT_ASSIGN_ARR
    Type type_;
    Exp lhs;
    Exp exp;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_ASSIGN_ARR;

  record STMT_IF
    Exp exp;
    list<Statement> statementLst;
    Else else_;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_IF;

  record STMT_FOR
    Type type_ "this is the type of the iterator";
    Boolean iterIsArray "True if the iterator has an array type, otherwise false.";
    Ident iter "the iterator variable";
    Integer index "the index of the iterator variable, to make it unique; used by the new inst";
    Exp range "range for the loop";
    list<Statement> statementLst;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_FOR;

  record STMT_PARFOR
    Type type_ "this is the type of the iterator";
    Boolean iterIsArray "True if the iterator has an array type, otherwise false.";
    Ident iter "the iterator variable";
    Integer index "the index of the iterator variable, to make it unique; used by the new inst";
    Exp range "range for the loop";
    list<Statement> statementLst;
    list<tuple<ComponentRef,SourceInfo>> loopPrlVars "list of parallel variables used/referenced in the parfor loop";
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_PARFOR;

  record STMT_WHILE
    Exp exp;
    list<Statement> statementLst;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_WHILE;

  record STMT_WHEN
    Exp exp;
    list<ComponentRef> conditions;        // list of boolean variables as conditions  (this is simcode stuff)
    Boolean initialCall;                  // true, if top-level branch with initial() (this is simcode stuff)
    list<Statement> statementLst;
    Option<Statement> elseWhen;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_WHEN;

  record STMT_ASSERT "assert(cond,msg)"
    Exp cond;
    Exp msg;
    Exp level;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_ASSERT;

  record STMT_TERMINATE "terminate(msg)"
    Exp msg;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_TERMINATE;

  record STMT_REINIT
    Exp var "Variable";
    Exp value "Value ";
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_REINIT;

  record STMT_NORETCALL "call with no return value, i.e. no equation.
       Typically sideeffect call of external function."
    Exp exp;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_NORETCALL;

  record STMT_RETURN
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_RETURN;

  record STMT_BREAK
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_BREAK;

  record STMT_CONTINUE
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_CONTINUE;

  record STMT_ARRAY_INIT "For function initialization"
    String name;
    Type ty;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_ARRAY_INIT;

  // MetaModelica extension. KS
  record STMT_FAILURE
    list<Statement> body;
    ElementSource source "the origin of the component/equation/algorithm" ;
  end STMT_FAILURE;
end Statement;

public
uniontype Else "An if statements can one or more `elseif\' branches and an
    optional `else\' branch."
  record NOELSE end NOELSE;

  record ELSEIF
    Exp exp;
    list<Statement> statementLst;
    Else else_;
  end ELSEIF;

  record ELSE
    list<Statement> statementLst;
  end ELSE;

end Else;
/* -- End Algorithm.mo -- */

/* -- Start Types.mo -- */
public
uniontype Var "- Variables"
  record TYPES_VAR
    Ident name "name";
    Attributes attributes "attributes";
    Type ty "type";
    Binding binding "equation modification";
    Option<Const> constOfForIteratorRange "the constant-ness of the range if this is a for iterator, NONE() if is NOT a for iterator";
  end TYPES_VAR;
end Var;

public
uniontype Attributes "- Attributes"
  record ATTR
    SCode.ConnectorType connectorType "flow, stream or unspecified";
    SCode.Parallelism   parallelism "parallelism";
    SCode.Variability   variability "variability" ;
    Absyn.Direction     direction "direction" ;
    Absyn.InnerOuter    innerOuter "inner, outer,  inner outer or unspecified";
    SCode.Visibility    visibility "public, protected";
  end ATTR;
end Attributes;

public
constant Attributes dummyAttrVar   = ATTR(SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(),   Absyn.BIDIR(), Absyn.NOT_INNER_OUTER(), SCode.PUBLIC());
constant Attributes dummyAttrParam = ATTR(SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.PARAM(), Absyn.BIDIR(), Absyn.NOT_INNER_OUTER(), SCode.PUBLIC());
constant Attributes dummyAttrConst = ATTR(SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR(), Absyn.NOT_INNER_OUTER(), SCode.PUBLIC());
constant Attributes dummyAttrInput = ATTR(SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(),   Absyn.INPUT(), Absyn.NOT_INNER_OUTER(), SCode.PUBLIC());

public uniontype BindingSource "where this binding came from: either default binding or start value"
  record BINDING_FROM_DEFAULT_VALUE "the binding came from the default value" end BINDING_FROM_DEFAULT_VALUE;
  record BINDING_FROM_START_VALUE "the binding came from the start value" end BINDING_FROM_START_VALUE;
end BindingSource;

public
uniontype Binding
  record UNBOUND end UNBOUND;

  record EQBOUND
    Exp exp;
    Option<Values.Value> evaluatedExp;
    Const constant_;
    BindingSource source;
  end EQBOUND;

  record VALBOUND
    Values.Value valBound;
    BindingSource source;
  end VALBOUND;
end Binding;

public
type EqualityConstraint = Option<tuple<Absyn.Path, Integer, InlineType>>
  "contains the path to the equalityConstraint function,
   the dimension of the output and the inline type of the function";

public type TypeSource = list<Absyn.Path> "the class(es) where the type originated";
public constant TypeSource emptyTypeSource = {} "an empty origin for the type";

// default constants that can be used
constant Type T_REAL_DEFAULT        = T_REAL({}, emptyTypeSource);
constant Type T_INTEGER_DEFAULT     = T_INTEGER({}, emptyTypeSource);
constant Type T_STRING_DEFAULT      = T_STRING({}, emptyTypeSource);
constant Type T_BOOL_DEFAULT        = T_BOOL({}, emptyTypeSource);
constant Type T_CLOCK_DEFAULT       = T_CLOCK({}, emptyTypeSource);
constant Type T_ENUMERATION_DEFAULT = T_ENUMERATION(NONE(), Absyn.IDENT(""), {}, {}, {}, emptyTypeSource);
constant Type T_REAL_BOXED          = T_METABOXED(T_REAL_DEFAULT, emptyTypeSource);
constant Type T_INTEGER_BOXED       = T_METABOXED(T_INTEGER_DEFAULT, emptyTypeSource);
constant Type T_STRING_BOXED        = T_METABOXED(T_STRING_DEFAULT, emptyTypeSource);
constant Type T_BOOL_BOXED          = T_METABOXED(T_BOOL_DEFAULT, emptyTypeSource);
constant Type T_METABOXED_DEFAULT   = T_METABOXED(T_UNKNOWN_DEFAULT, emptyTypeSource);
constant Type T_METALIST_DEFAULT    = T_METALIST(T_UNKNOWN_DEFAULT, emptyTypeSource);
constant Type T_NONE_DEFAULT        = T_METAOPTION(T_UNKNOWN_DEFAULT, emptyTypeSource);
constant Type T_ANYTYPE_DEFAULT     = T_ANYTYPE(NONE(), emptyTypeSource);
constant Type T_UNKNOWN_DEFAULT     = T_UNKNOWN(emptyTypeSource);
constant Type T_NORETCALL_DEFAULT   = T_NORETCALL(emptyTypeSource);
constant Type T_FUNCTION_DEFAULT    = T_FUNCTION({},T_ANYTYPE_DEFAULT,FUNCTION_ATTRIBUTES_DEFAULT,emptyTypeSource);
constant Type T_METATYPE_DEFAULT    = T_METATYPE(T_UNKNOWN_DEFAULT, emptyTypeSource);
constant Type T_COMPLEX_DEFAULT     = T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("")), {}, NONE(), emptyTypeSource) "default complex with unknown CiState";
constant Type T_COMPLEX_DEFAULT_RECORD = T_COMPLEX(ClassInf.RECORD(Absyn.IDENT("")), {}, NONE(), emptyTypeSource) "default complex with record CiState";

constant Type T_SOURCEINFO_DEFAULT_METARECORD = T_METARECORD(Absyn.QUALIFIED("SourceInfo",Absyn.IDENT("SOURCEINFO")), {}, 1, {
    TYPES_VAR("fileName", dummyAttrVar, T_STRING_DEFAULT, UNBOUND(), NONE()),
    TYPES_VAR("isReadOnly", dummyAttrVar, T_BOOL_DEFAULT, UNBOUND(), NONE()),
    TYPES_VAR("lineNumberStart", dummyAttrVar, T_INTEGER_DEFAULT, UNBOUND(), NONE()),
    TYPES_VAR("columnNumberStart", dummyAttrVar, T_INTEGER_DEFAULT, UNBOUND(), NONE()),
    TYPES_VAR("lineNumberEnd", dummyAttrVar, T_INTEGER_DEFAULT, UNBOUND(), NONE()),
    TYPES_VAR("columnNumberEnd", dummyAttrVar, T_INTEGER_DEFAULT, UNBOUND(), NONE()),
    TYPES_VAR("lastModification", dummyAttrVar, T_REAL_DEFAULT, UNBOUND(), NONE())
  }, true, emptyTypeSource);
constant Type T_SOURCEINFO_DEFAULT  = T_METAUNIONTYPE({Absyn.QUALIFIED("SourceInfo",Absyn.IDENT("SOURCEINFO"))},{},true,EVAL_SINGLETON_KNOWN_TYPE(T_SOURCEINFO_DEFAULT_METARECORD),Absyn.IDENT("SourceInfo")::{});

// Arrays of unknown dimension, eg. Real[:]
public constant Type T_ARRAY_REAL_NODIM    = T_ARRAY(T_REAL_DEFAULT,{DIM_UNKNOWN()}, emptyTypeSource);
public constant Type T_ARRAY_INT_NODIM     = T_ARRAY(T_INTEGER_DEFAULT,{DIM_UNKNOWN()}, emptyTypeSource);
public constant Type T_ARRAY_BOOL_NODIM    = T_ARRAY(T_BOOL_DEFAULT,{DIM_UNKNOWN()}, emptyTypeSource);
public constant Type T_ARRAY_STRING_NODIM  = T_ARRAY(T_STRING_DEFAULT,{DIM_UNKNOWN()}, emptyTypeSource);


public uniontype Type "models the different front-end and back-end types"

  record T_INTEGER
    list<Var> varLst;
    TypeSource source;
  end T_INTEGER;

  record T_REAL
    list<Var> varLst;
    TypeSource source;
  end T_REAL;

  record T_STRING
    list<Var> varLst;
    TypeSource source;
  end T_STRING;

  record T_BOOL
    list<Var> varLst;
    TypeSource source;
  end T_BOOL;

  record T_CLOCK
    list<Var> varLst; // BTH Since Clock type has no attributes, this is not really needed, but at the moment kept for unified treatment of fundamental types
    TypeSource source;
  end T_CLOCK;

  record T_ENUMERATION "If the list of names is empty, this is the super-enumeration that is the super-class of all enumerations"
    Option<Integer> index "the enumeration value index, SOME for element, NONE() for type" ;
    Absyn.Path path "enumeration path" ;
    list<String> names "names" ;
    list<Var> literalVarLst;
    list<Var> attributeLst;
    TypeSource source;
  end T_ENUMERATION;

  record T_ARRAY
    "an array can be represented in two equivalent ways:
       1. T_ARRAY(non_array_type, {dim1, dim2, dim3})
       2. T_ARRAY(T_ARRAY(T_ARRAY(non_array_type, {dim1}), {dim2}), {dim3})
       In general Inst generates 1 and all the others generates 2"
    Type ty "Type";
    Dimensions dims "dims";
    TypeSource source;
  end T_ARRAY;

  record T_NORETCALL "For functions not returning any values."
    TypeSource source;
  end T_NORETCALL;

  record T_UNKNOWN "Used when type is not yet determined"
    TypeSource source;
  end T_UNKNOWN;

  record T_COMPLEX
    ClassInf.State complexClassType "The type of a class";
    list<Var> varLst "The variables of a complex type";
    EqualityConstraint equalityConstraint;
    TypeSource source;
  end T_COMPLEX;

  record T_SUBTYPE_BASIC
    ClassInf.State complexClassType "The type of a class";
    list<Var> varLst "complexVarLst; The variables of a complex type! Should be empty, kept here to verify!";
    Type complexType "complexType; A complex type can be a subtype of another (primitive) type (through extends)";
    EqualityConstraint equalityConstraint;
    TypeSource source;
  end T_SUBTYPE_BASIC;

  record T_FUNCTION
    list<FuncArg> funcArg "funcArg" ;
    Type funcResultType "Only single-result" ;
    FunctionAttributes functionAttributes;
    TypeSource source;
  end T_FUNCTION;

  record T_FUNCTION_REFERENCE_VAR "MetaModelica Function Reference that is a variable"
    Type functionType "the type of the function";
    TypeSource source;
  end T_FUNCTION_REFERENCE_VAR;

  record T_FUNCTION_REFERENCE_FUNC "MetaModelica Function Reference that is a direct reference to a function"
    Boolean builtin;
    Type functionType "type of the non-boxptr function";
    TypeSource source;
  end T_FUNCTION_REFERENCE_FUNC;

  record T_TUPLE
    list<Type> types "For functions returning multiple values.";
    Option<list<String>> names "For tuples elements that have names (function outputs)";
    TypeSource source;
  end T_TUPLE;

  record T_CODE
    CodeType ty;
    TypeSource source;
  end T_CODE;

  record T_ANYTYPE
    Option<ClassInf.State> anyClassType "anyClassType - used for generic types. When class state present the type is assumed to be a complex type which has that restriction.";
    TypeSource source;
  end T_ANYTYPE;

  // MetaModelica extensions
  record T_METALIST "MetaModelica list type"
    Type ty "listType";
    TypeSource source;
  end T_METALIST;

  record T_METATUPLE "MetaModelica tuple type"
    list<Type> types;
    TypeSource source;
  end T_METATUPLE;

  record T_METAOPTION "MetaModelica option type"
    Type ty;
    TypeSource source;
  end T_METAOPTION;

  record T_METAUNIONTYPE "MetaModelica Uniontype, added by simbj"
    // TODO: You can't trust these fields as it seems MetaUtil.fixUniontype is sent empty elements when running dependency analysis
    list<Absyn.Path> paths;
    list<Type> typeVars;
    Boolean knownSingleton "The runtime system (dynload), does not know if the value is a singleton. But optimizations are safe if this is true.";
    EvaluateSingletonType singletonType;
    TypeSource source;
  end T_METAUNIONTYPE;

  record T_METARECORD "MetaModelica Record, used by Uniontypes. added by simbj"
    Absyn.Path utPath "the path to its uniontype; this is what we match the type against";
    // If the metarecord constructor was added to the FunctionTree, this would
    // not be needed. They are used to create the datatype in the runtime...
    list<Type> typeVars;
    Integer index; //The index in the uniontype
    list<Var> fields;
    Boolean knownSingleton "The runtime system (dynload), does not know if the value is a singleton. But optimizations are safe if this is true.";
    TypeSource source;
  end T_METARECORD;

  record T_METAARRAY
    Type ty;
    TypeSource source;
  end T_METAARRAY;

  record T_METABOXED "Used for MetaModelica generic types"
    Type ty;
    TypeSource source;
  end T_METABOXED;

  record T_METAPOLYMORPHIC
    String name;
    TypeSource source;
  end T_METAPOLYMORPHIC;

  record T_METATYPE "this type contains all the meta types"
    Type ty;
    TypeSource source;
  end T_METATYPE;

end Type;

public uniontype CodeType
  record C_EXPRESSION
  end C_EXPRESSION;

  record C_EXPRESSION_OR_MODIFICATION
  end C_EXPRESSION_OR_MODIFICATION;

  record C_MODIFICATION
  end C_MODIFICATION;

  record C_TYPENAME
  end C_TYPENAME;

  record C_VARIABLENAME
  end C_VARIABLENAME;

  record C_VARIABLENAMES "Array of VariableName"
  end C_VARIABLENAMES;
end CodeType;

uniontype EvaluateSingletonType "Is here because constants are not allowed to contain function pointers for some reason"
  record EVAL_SINGLETON_TYPE_FUNCTION
    EvaluateSingletonTypeFunction fun;
  end EVAL_SINGLETON_TYPE_FUNCTION;

  record EVAL_SINGLETON_KNOWN_TYPE
    Type ty;
  end EVAL_SINGLETON_KNOWN_TYPE;

  record NOT_SINGLETON
  end NOT_SINGLETON;
end EvaluateSingletonType;

partial function EvaluateSingletonTypeFunction
  output Type ty;
end EvaluateSingletonTypeFunction;

public constant FunctionAttributes FUNCTION_ATTRIBUTES_BUILTIN = FUNCTION_ATTRIBUTES(NO_INLINE(),true,false,false,FUNCTION_BUILTIN(NONE()),FP_NON_PARALLEL());
public constant FunctionAttributes FUNCTION_ATTRIBUTES_DEFAULT = FUNCTION_ATTRIBUTES(DEFAULT_INLINE(),true,false,false,FUNCTION_NOT_BUILTIN(),FP_NON_PARALLEL());
public constant FunctionAttributes FUNCTION_ATTRIBUTES_IMPURE = FUNCTION_ATTRIBUTES(NO_INLINE(),false,true,false,FUNCTION_NOT_BUILTIN(),FP_NON_PARALLEL());
public constant FunctionAttributes FUNCTION_ATTRIBUTES_BUILTIN_IMPURE = FUNCTION_ATTRIBUTES(NO_INLINE(),false,true,false,FUNCTION_BUILTIN(NONE()),FP_NON_PARALLEL());

public
uniontype FunctionAttributes
  record FUNCTION_ATTRIBUTES
    InlineType inline;
    Boolean isOpenModelicaPure "if the function has __OpenModelica_Impure";
    Boolean isImpure "if the function has prefix *impure* is true, else false";
    Boolean isFunctionPointer "if the function is a local variable";
    FunctionBuiltin isBuiltin;
    FunctionParallelism functionParallelism;
  end FUNCTION_ATTRIBUTES;
end FunctionAttributes;

public
uniontype FunctionBuiltin
  record FUNCTION_NOT_BUILTIN "Function is not builtin"
  end FUNCTION_NOT_BUILTIN;

  record FUNCTION_BUILTIN "Function is builtin"
    Option<String> name;
  end FUNCTION_BUILTIN;

  record FUNCTION_BUILTIN_PTR "The function has a body, but its function pointer is builtin. This means inline code+optimized pointer if need be."
  end FUNCTION_BUILTIN_PTR;

end FunctionBuiltin;

//This was a function restriction in SCode and Absyn
//Now it is part of function attributes.
public
uniontype FunctionParallelism
  record FP_NON_PARALLEL   "a normal function i.e non_parallel"    end FP_NON_PARALLEL;
  record FP_PARALLEL_FUNCTION "an OpenCL/CUDA parallel/device function" end FP_PARALLEL_FUNCTION;
  record FP_KERNEL_FUNCTION "an OpenCL/CUDA kernel function" end FP_KERNEL_FUNCTION;
end FunctionParallelism;

type Dimensions = list<Dimension> "a list of dimensions";

public
uniontype Dimension
  record DIM_INTEGER "Dimension given by an integer."
    Integer integer;
  end DIM_INTEGER;

  record DIM_BOOLEAN "Dimension given by Boolean"
  end DIM_BOOLEAN;

  record DIM_ENUM "Dimension given by an enumeration."
    Absyn.Path enumTypeName "The enumeration type name.";
    list<String> literals "A list of the literals in the enumeration.";
    Integer size "The size of the enumeration.";
  end DIM_ENUM;

  record DIM_EXP "Dimension given by an expression."
    Exp exp;
  end DIM_EXP;

  record DIM_UNKNOWN "Dimension with unknown size."
    //DimensionBinding dimensionBinding "unknown dimension can be bound or unbound";
  end DIM_UNKNOWN;
end Dimension;

// adrpo: this is used to bind unknown dimensions to an expression
//        and when we do subtyping we add constrains to this expression.
//        this should be used for typechecking with unknown dimensions
//        when running checkModel. the binding acts like a type variable.
public uniontype DimensionBinding
   record DIM_UNBOUND "dimension is not bound"
   end DIM_UNBOUND;
   record DIM_BOUND "dimension is bound to an expression with constrains"
      Exp binding "the dimension is bound to this expression";
      Dimensions constrains "the bound has these constrains (collected when doing subtyping)";
   end DIM_BOUND;
end DimensionBinding;

public
uniontype FuncArg
  record FUNCARG
    String name;
    Type ty;
    Const const;
    VarParallelism par;
    Option<Exp> defaultBinding;
  end FUNCARG;
end FuncArg;

public
uniontype Const "The degree of constantness of an expression is determined by the Const
    datatype. Variables declared as \'constant\' will get C_CONST constantness.
    Variables declared as \'parameter\' will get C_PARAM constantness and
    all other variables are not constant and will get C_VAR constantness.

  - Variable properties"
  record C_CONST "constant " end C_CONST;

  record C_PARAM "parameter" end C_PARAM;

  record C_VAR "continuous" end C_VAR;

  record C_UNKNOWN end C_UNKNOWN;
end Const;

public
uniontype TupleConst "A tuple is added to the Types. This is used by functions whom returns multiple arguments.
  Used by split_props
  - Tuple constants"
  record SINGLE_CONST
    Const const;
  end SINGLE_CONST;

  record TUPLE_CONST
    list<TupleConst> tupleConstLst;
  end TUPLE_CONST;

end TupleConst;

public
uniontype Properties "P.R 1.1 for multiple return arguments from functions,
    one constant flag for each return argument.

  The datatype `Properties\' contain information about an
    expression.  The properties are created by analyzing the
    expressions.
  - Expression properties"
  record PROP
    Type type_ "type" ;
    Const constFlag "constFlag; if the type is a tuple, each element
                  have a const flag." ;
  end PROP;

  record PROP_TUPLE
    Type type_;
    TupleConst tupleConst "tupleConst; The elements might be
                  tuple themselfs." ;
  end PROP_TUPLE;

end Properties;

public
uniontype EqMod "To generate the correct set of equations, the translator has to
  differentiate between the primitive types `Real\', `Integer\',
  `String\', `Boolean\' and types directly derived from then from
  other, complex types.  For arrays and matrices the type
  `T_ARRAY\' is used, with the first argument being the number of
  dimensions, and the second being the type of the objects in the
  array.  The `Type\' type is used to store
  information about whether a class is derived from a primitive
  type, and whether a variable is of one of these types.
  - Modification datatype, was originally in Mod"
  record TYPED
    Exp modifierAsExp "modifier as expression" ;
    Option<Values.Value> modifierAsValue "modifier as Value option" ;
    Properties properties "properties" ;
    Absyn.Exp modifierAsAbsynExp "keep the untyped modifier as an absyn expression for modification comparison";
  end TYPED;

  record UNTYPED
    Absyn.Exp exp;
  end UNTYPED;

end EqMod;

public
uniontype SubMod "-Sub Modification"
  record NAMEMOD "named modification, i.e. (a = 5)"
    Ident ident "component name";
    Mod mod "modification";
  end NAMEMOD;
end SubMod;

public
uniontype Mod "Modification"
  record MOD
    SCode.Final   finalPrefix "final prefix";
    SCode.Each    eachPrefix "each prefix";
    list<SubMod>  subModLst;
    Option<EqMod> binding;
    SourceInfo    info;
  end MOD;

  record REDECL
    SCode.Final finalPrefix "final prefix";
    SCode.Each  eachPrefix "each prefix";
    SCode.Element element;
    Mod mod;
  end REDECL;

  record NOMOD end NOMOD;
end Mod;

public
uniontype ClockKind
  record INFERRED_CLOCK
  end INFERRED_CLOCK;

  record INTEGER_CLOCK
    Exp intervalCounter;
    Exp resolution " integer type >= 1 ";
  end INTEGER_CLOCK;

  record REAL_CLOCK
    Exp interval;
  end REAL_CLOCK;

  record BOOLEAN_CLOCK
    Exp condition;
    Exp startInterval " real type >= 0.0 ";
  end BOOLEAN_CLOCK;

  record SOLVER_CLOCK
    Exp c;
    Exp solverMethod " string type ";
  end SOLVER_CLOCK;
end ClockKind;

/* -- End Types.mo -- */

public
uniontype Exp "Expressions
  The 'Exp' datatype closely corresponds to the 'Absyn.Exp' datatype, but
  is used for statically analyzed expressions. It includes explicit type
  promotions and typed (non-overloaded) operators. It also contains expression
  indexing with the 'ASUB' constructor. Indexing arbitrary array expressions
  is currently not supported in Modelica, but it is needed here.

  When making additions, update at least the following functions:
  * Expression.traverseExp
  * Expression.traverseExpTopDown
  * Expression.traverseExpBiDir
  * ExpressionDump.printExpStr"

  record ICONST
    Integer integer "Integer constants" ;
  end ICONST;

  record RCONST
    Real real "Real constants" ;
  end RCONST;

  record SCONST
    String string "String constants" ;
  end SCONST;

  record BCONST
    Boolean bool "Bool constants" ;
  end BCONST;

  record CLKCONST "Clock constructors"
    ClockKind clk "Clock kinds";
  end CLKCONST;

  record ENUM_LITERAL "Enumeration literal"
    Absyn.Path name;
    Integer index;
  end ENUM_LITERAL;

  record CREF "component references, e.g. a.b{2}.c{1}"
    ComponentRef componentRef;
    Type ty;
  end CREF;

  record BINARY "Binary operations, e.g. a+4"
    Exp exp1;
    Operator operator;
    Exp exp2;
  end BINARY;

  record UNARY "Unary operations, -(4x)"
    Operator operator;
    Exp exp;
  end UNARY;

  record LBINARY "Logical binary operations: and, or"
    Exp exp1;
    Operator operator;
    Exp exp2;
  end LBINARY;

  record LUNARY "Logical unary operations: not"
    Operator operator;
    Exp exp;
  end LUNARY;

  record RELATION "Relation, e.g. a <= 0
    Index contains normal an Integer for every ZeroCrossing
    but if Relation is in algorithm with for loop the iterator and the range
    of static iterator is needed for codegen"
    Exp exp1;
    Operator operator;
    Exp exp2;
    Integer index;
    Option<tuple<Exp,Integer,Integer>> optionExpisASUB;
  end RELATION;

  record IFEXP "If expressions"
    Exp expCond;
    Exp expThen;
    Exp expElse;
  end IFEXP;

  record CALL
    Absyn.Path path;
    list<Exp> expLst;
    CallAttributes attr;
  end CALL;

  record RECORD "A record value cannot be represented as a call to its constructor. This record also contains the protected components."
    Absyn.Path path;
    list<Exp> exps "component values";
    list<String> comp "component name";
    Type ty;
  end RECORD;

  record PARTEVALFUNCTION
    Absyn.Path path;
    list<Exp> expList;
    Type ty;
    Type origType;
  end PARTEVALFUNCTION;

  record ARRAY
    Type ty;
    Boolean scalar "scalar for codegen";
    list<Exp> array "Array constructor, e.g. {1,3,4}";
  end ARRAY;

  record MATRIX
    Type ty;
    Integer integer "Size of the first dimension";
    list<list<Exp>> matrix;
  end MATRIX;

  record RANGE
    Type ty "the (array) type of the expression";
    Exp start "start value";
    Option<Exp> step "step value";
    Exp stop "stop value" ;
  end RANGE;

  record TUPLE
    list<Exp> PR "PR. Tuples, used in func calls returning several
                  arguments" ;
  end TUPLE;

  record CAST "Cast operator"
    Type ty "This is the full type of this expression, i.e. ET_ARRAY(...) for arrays and matrices";
    Exp exp;
  end CAST;

  record ASUB "Array subscripts"
    Exp exp;
    list<Exp> sub;
  end ASUB;

  record TSUB "Tuple 'subscript' (accessing only single values in calls)"
    Exp exp;
    Integer ix;
    Type ty;
  end TSUB;

  record RSUB "Record field indexing"
    Exp exp;
    Integer ix; // Used when generating code for MetaModelica records
    String fieldName;
    Type ty;
  end RSUB;

  record SIZE "The size operator"
    Exp exp;
    Option<Exp> sz;
  end SIZE;

  record CODE "Modelica AST constructor"
    Absyn.CodeNode code;
    Type ty;
  end CODE;

  record EMPTY
    "an empty expression, meaning a constant without a binding. is used to be able to continue the evaluation of a model even if there are
     constants with no bindings. at the end, when we have the DAE we should have no EMPTY values or expressions in it when we need to simulate
     the model.
     From Modelica specification: a package may we look inside should not be partial in a simulation model!"
    String scope "the scope where we could not find the binding";
    ComponentRef name "the name of the variable";
    Type ty "the type of the variable";
    String tyStr;
  end EMPTY;

  record REDUCTION "e.g. sum(i*i+1 for i in 1:4)"
    ReductionInfo reductionInfo;
    Exp expr "expr, e.g i*i+1" ;
    ReductionIterators iterators;
  end REDUCTION;

  /* Part of MetaModelica extension. KS */
  record LIST "MetaModelica list"
    list<Exp> valList;
  end LIST;

  record CONS "MetaModelica list cons"
    Exp car;
    Exp cdr;
  end CONS;

  record META_TUPLE
    list<Exp> listExp;
  end META_TUPLE;

  record META_OPTION
    Option<Exp> exp;
  end META_OPTION;

  /*
    Holds a metarecord call
     <metarecord>(<args>)
  */
  record METARECORDCALL //Metamodelica extension, simbj
    Absyn.Path path;
    list<Exp> args;
    list<String> fieldNames;
    Integer index; //Index in the uniontype
    list<Type> typeVars;
  end METARECORDCALL;

  record MATCHEXPRESSION
    MatchType matchType;
    list<Exp> inputs;
    list<list<String>> aliases "input aliases (input as-bindings)";
    list<Element> localDecls;
    list<MatchCase> cases;
    Type et;
  end MATCHEXPRESSION;

  record BOX "MetaModelica boxed value"
    Exp exp;
  end BOX;

  record UNBOX "MetaModelica value unboxing (similar to a cast)"
    Exp exp;
    Type ty;
  end UNBOX;

  record SHARED_LITERAL
    "Before code generation, we make a pass that replaces constant literals
    with a SHARED_LITERAL expression. Any immutable type can be shared:
    basic MetaModelica types and Modelica strings are fine. There is no point
    to share Real, Integer, Boolean or Enum though."
    Integer index "A unique indexing that can be used to point to a single shared literal in generated code";
    Exp exp "For printing strings, code generators that do not support this kind of literal, or for getting the type in case the code generator needs that";
  end SHARED_LITERAL;

  record PATTERN "(x,1,ROOT(a as _,false,_)) := rhs; MetaModelica extension"
    Pattern pattern;
  end PATTERN;

  record SUM //i.e. accumulated sum over a range of array vars
    Type ty;
    Exp iterator;
    Exp startIt;
    Exp endIt;
    Exp body;
  end SUM;
  /* --- */

end Exp;

public uniontype TailCall
  record NO_TAIL "Not tail-recursive"
  end NO_TAIL;
  record TAIL
    list<String> vars;
  end TAIL;
end TailCall;

public constant CallAttributes callAttrBuiltinBool = CALL_ATTR(T_BOOL_DEFAULT,false,true,false,false,NO_INLINE(),NO_TAIL());
public constant CallAttributes callAttrBuiltinInteger = CALL_ATTR(T_INTEGER_DEFAULT,false,true,false,false,NO_INLINE(),NO_TAIL());
public constant CallAttributes callAttrBuiltinReal = CALL_ATTR(T_REAL_DEFAULT,false,true,false,false,NO_INLINE(),NO_TAIL());
public constant CallAttributes callAttrBuiltinString = CALL_ATTR(T_STRING_DEFAULT,false,true,false,false,NO_INLINE(),NO_TAIL());
public constant CallAttributes callAttrBuiltinOther = CALL_ATTR(T_UNKNOWN_DEFAULT,false,true,false,false,NO_INLINE(),NO_TAIL());
public constant CallAttributes callAttrBuiltinImpureBool = CALL_ATTR(T_BOOL_DEFAULT,false,true,true,false,NO_INLINE(),NO_TAIL());
public constant CallAttributes callAttrBuiltinImpureInteger = CALL_ATTR(T_INTEGER_DEFAULT,false,true,true,false,NO_INLINE(),NO_TAIL());
public constant CallAttributes callAttrBuiltinImpureReal = CALL_ATTR(T_REAL_DEFAULT,false,true,true,false,NO_INLINE(),NO_TAIL());

public
uniontype CallAttributes
  record CALL_ATTR
    Type ty "The type of the return value, if several return values this is undefined";
    Boolean tuple_ "tuple" ;
    Boolean builtin "builtin Function call" ;
    Boolean isImpure "if the function has prefix *impure* is true, else false";
    Boolean isFunctionPointerCall;
    InlineType inlineType;
    TailCall tailCall "Input variables of the function if the call is tail-recursive";
  end CALL_ATTR;
end CallAttributes;

public uniontype ReductionInfo
  record REDUCTIONINFO "A separate uniontype containing the information not required by traverseExp, etc"
    Absyn.Path path "array, sum,..";
    Absyn.ReductionIterType iterType;
    Type exprType;
    Option<Values.Value> defaultValue "if there is no default value, the reduction is not defined for 0-length arrays/lists";
    String foldName;
    String resultName "Unique identifier for the resulting expression";
    Option<Exp> foldExp "For example, max(ident,$res) or ident+$res; array() does not use this feature; DO NOT TRAVERSE THIS EXPRESSION!";
  end REDUCTIONINFO;
end ReductionInfo;

public uniontype ReductionIterator
  record REDUCTIONITER
    String id;
    Exp exp;
    Option<Exp> guardExp;
    Type ty;
  end REDUCTIONITER;
end ReductionIterator;

public type ReductionIterators = list<ReductionIterator> "NOTE: OMC only handles one iterator for now";

public uniontype MatchCase
  record CASE
    list<Pattern> patterns "ELSE is handled by not doing pattern-matching";
    Option<Exp> patternGuard "Guard-expression";
    list<Element> localDecls;
    list<Statement> body;
    Option<Exp> result;
    SourceInfo resultInfo "We need to keep the line info here so we can set a breakpoint at the last statement of a match-expression";
    Integer jump "the number of iterations we should skip if we succeed with pattern-matching, but don't succeed";
    SourceInfo info;
  end CASE;
end MatchCase;

public uniontype MatchType
  record MATCHCONTINUE end MATCHCONTINUE;
  record TRY_STACKOVERFLOW end TRY_STACKOVERFLOW;
  record MATCH
    Option<tuple<Integer,Type,Integer>> switch "The index of the pattern to switch over, its type and the value to divide string hashes with";
  end MATCH;
end MatchType;

public uniontype Pattern "Patterns deconstruct expressions"
  record PAT_WILD "_"
  end PAT_WILD;
  record PAT_CONSTANT "compare to this constant value using equality"
    Option<Type> ty "so we can unbox if needed";
    Exp exp;
  end PAT_CONSTANT;
  record PAT_AS "id as pat"
    String id;
    Option<Type> ty "so we can unbox if needed";
    Attributes attr "so we know if the ident is parameter or assignable";
    Pattern pat;
  end PAT_AS;
  record PAT_AS_FUNC_PTR "id as pat"
    String id;
    Pattern pat;
  end PAT_AS_FUNC_PTR;
  record PAT_META_TUPLE "(pat1,...,patn)"
    list<Pattern> patterns;
  end PAT_META_TUPLE;
  record PAT_CALL_TUPLE "(pat1,...,patn)"
    list<Pattern> patterns;
  end PAT_CALL_TUPLE;
  record PAT_CONS "head::tail"
    Pattern head;
    Pattern tail;
  end PAT_CONS;
  record PAT_CALL "RECORD(pat1,...,patn); all patterns are positional"
    Absyn.Path name;
    Integer index;
    list<Pattern> patterns;
    list<Var> fields; // Needed to be able to bind a variable to the fields
    list<Type> typeVars;
    Boolean knownSingleton "The runtime system (dynload), does not know if the value is a singleton. But optimizations are safe if this is true.";
  end PAT_CALL;
  record PAT_CALL_NAMED "RECORD(pat1,...,patn); all patterns are named"
    Absyn.Path name;
    list<tuple<Pattern,String,Type>> patterns;
  end PAT_CALL_NAMED;
  record PAT_SOME "SOME(pat)"
    Pattern pat;
  end PAT_SOME;
end Pattern;

public
uniontype Operator "Operators which are overloaded in the abstract syntax are here
    made type-specific.  The integer addition operator (`ADD(INT)\')
    and the real addition operator (`ADD(REAL)\') are two distinct
    operators."
  record ADD
    Type ty;
  end ADD;

  record SUB
    Type ty;
  end SUB;

  record MUL
    Type ty;
  end MUL;

  record DIV
    Type ty;
  end DIV;

  record POW
    Type ty;
  end POW;

  record UMINUS
    Type ty;
  end UMINUS;

  record UMINUS_ARR
    Type ty;
  end UMINUS_ARR;

  record ADD_ARR
    Type ty;
  end ADD_ARR;

  record SUB_ARR
    Type ty;
  end SUB_ARR;

  record MUL_ARR "Element-wise array multiplication"
    Type ty;
  end MUL_ARR;

  record DIV_ARR
    Type ty;
  end DIV_ARR;

  record MUL_ARRAY_SCALAR " {a,b,c} * s"
    Type ty "type of the array" ;
  end MUL_ARRAY_SCALAR;

  record ADD_ARRAY_SCALAR " {a,b,c} .+ s"
    Type ty "type of the array";
  end ADD_ARRAY_SCALAR;

  record SUB_SCALAR_ARRAY "s .- {a,b,c}"
    Type ty "type of the array" ;
  end SUB_SCALAR_ARRAY;

  record MUL_SCALAR_PRODUCT " {a,b,c} * {c,d,e} => a*c+b*d+c*e"
    Type ty "type of the array" ;
  end MUL_SCALAR_PRODUCT;

  record MUL_MATRIX_PRODUCT "M1 * M2, matrix dot product"
    Type ty "{{..},..}  {{..},{..}}" ;
  end MUL_MATRIX_PRODUCT;

  record DIV_ARRAY_SCALAR "{a, b} / c"
    Type ty  "type of the array";
  end DIV_ARRAY_SCALAR;

  record DIV_SCALAR_ARRAY "c / {a,b}"
    Type ty "type of the array" ;
  end DIV_SCALAR_ARRAY;

  record POW_ARRAY_SCALAR
    Type ty "type of the array" ;
  end POW_ARRAY_SCALAR;

  record POW_SCALAR_ARRAY
    Type ty "type of the array" ;
  end POW_SCALAR_ARRAY;

  record POW_ARR "Power of a matrix: {{1,2,3},{4,5.0,6},{7,8,9}}^2"
    Type ty "type of the array";
  end POW_ARR;

  record POW_ARR2 "elementwise power of arrays: {1,2,3}.^{3,2,1}"
    Type ty "type of the array";
  end POW_ARR2;

  record AND
    Type ty;
  end AND;

  record OR
    Type ty;
  end OR;

  record NOT
    Type ty;
  end NOT;

  record LESS
    Type ty;
  end LESS;

  record LESSEQ
    Type ty;
  end LESSEQ;

  record GREATER
    Type ty;
  end GREATER;

  record GREATEREQ
    Type ty;
  end GREATEREQ;

  record EQUAL
    Type ty;
  end EQUAL;

  record NEQUAL
    Type ty;
  end NEQUAL;

  record USERDEFINED
    Absyn.Path fqName "The FQ name of the overloaded operator function" ;
  end USERDEFINED;

end Operator;

public
uniontype ComponentRef "- Component references
    CREF_QUAL(...) is used for qualified component names, e.g. a.b.c
    CREF_IDENT(..) is used for non-qualifed component names, e.g. x"

  record CREF_QUAL
    Ident ident;
    Type identType "type of the identifier, without considering the subscripts";
    list<Subscript> subscriptLst;
    ComponentRef componentRef;
  end CREF_QUAL;

  record CREF_IDENT
    Ident ident;
    Type identType "type of the identifier, without considering the subscripts";
    list<Subscript> subscriptLst;
  end CREF_IDENT;

  record CREF_ITER "An iterator index; used in local scopes in for-loops and reductions"
    Ident ident;
    Integer index;
    Type identType "type of the identifier, without considering the subscripts";
    list<Subscript> subscriptLst;
  end CREF_ITER;

  record OPTIMICA_ATTR_INST_CREF "An Optimica component reference with the time instant in it. e.g x2(finalTime)"
    ComponentRef componentRef;
    String instant;
  end OPTIMICA_ATTR_INST_CREF;

  record WILD end WILD;

end ComponentRef;

public constant ComponentRef crefTime = CREF_IDENT("time", T_REAL_DEFAULT, {});
public constant ComponentRef crefTimeState = CREF_IDENT("$time", T_REAL_DEFAULT, {});
public constant ComponentRef emptyCref = CREF_IDENT("", T_UNKNOWN_DEFAULT, {});

public
uniontype Subscript "The `Subscript\' and `ComponentRef\' datatypes are simple
  translations of the corresponding types in the `Absyn\' module."
  record WHOLEDIM "a{:,1}" end WHOLEDIM;

  record SLICE
    Exp exp "a{1:3,1}, a{1:2:10,2}" ;
  end SLICE;

  record INDEX
    Exp exp "a[i+1]" ;
  end INDEX;

  record WHOLE_NONEXP "Used for non-expanded arrays. Should probably be combined with WHOLEDIM
    into one case with Option<Exp> argument."
    Exp exp;
  end WHOLE_NONEXP;

end Subscript;
/* -- End Expression.mo -- */

public
uniontype Expand "array cref expansion strategy"
  record EXPAND     "expand crefs"     end EXPAND;
  record NOT_EXPAND "not expand crefs" end NOT_EXPAND;
end Expand;

public constant AvlTree emptyFuncTree = AVLTREENODE(NONE(),0,NONE(),NONE());
public constant DAElist emptyDae = DAE({});

annotation(__OpenModelica_Interface="frontend");
end DAE;
