interface package DAEDumpTV

// Susan can't handle cyclic includes of templates, so this is a bit of a hack
// to allow DAEDumpTpl to dump expressions without actually including
// ExpressionDumpTpl.
package ExpressionDumpTpl
  function dumpExp
    input Tpl.Text in_txt;
    input DAE.Exp in_a_exp;
    input String in_a_stringDelimiter;
    output Tpl.Text out_txt;
  end dumpExp;
end ExpressionDumpTpl;

package ClassInf
  function getStateName
    input State inState;
    output Absyn.Path outPath;
  end getStateName;

  uniontype State "- Machine states, the string contains the classname."
    record UNKNOWN
      Absyn.Path path;
    end UNKNOWN;

     record OPTIMIZATION
      Absyn.Path path;
     end OPTIMIZATION;

    record MODEL
      Absyn.Path path;
    end MODEL;

    record RECORD
      Absyn.Path path;
    end RECORD;

    record BLOCK
      Absyn.Path path;
    end BLOCK;

    record CONNECTOR
      Absyn.Path path;
      Boolean isExpandable;
    end CONNECTOR;

    record TYPE
      Absyn.Path path;
    end TYPE;

    record PACKAGE
      Absyn.Path path;
    end PACKAGE;

    record FUNCTION
      Absyn.Path path;
      Boolean isImpure;
    end FUNCTION;

    record ENUMERATION
      Absyn.Path path;
    end ENUMERATION;

    record HAS_RESTRICTIONS
      Absyn.Path path;
      Boolean hasEquations;
      Boolean hasAlgorithms;
      Boolean hasConstraints;
    end HAS_RESTRICTIONS;

    record TYPE_INTEGER
      Absyn.Path path;
    end TYPE_INTEGER;

    record TYPE_REAL
      Absyn.Path path;
    end TYPE_REAL;

    record TYPE_STRING
      Absyn.Path path;
    end TYPE_STRING;

    record TYPE_BOOL
      Absyn.Path path;
    end TYPE_BOOL;

    record TYPE_ENUM
      Absyn.Path path;
    end TYPE_ENUM;

    record EXTERNAL_OBJ
      Absyn.Path path;
    end EXTERNAL_OBJ;

    /* MetaModelica extension */
    record META_TUPLE
      Absyn.Path path;
    end META_TUPLE;

    record META_LIST
      Absyn.Path path;
    end META_LIST;

    record META_OPTION
      Absyn.Path path;
    end META_OPTION;

    record META_RECORD
      Absyn.Path path;
    end META_RECORD;

    record META_UNIONTYPE
      Absyn.Path path;
    end META_UNIONTYPE;

    record META_ARRAY
      Absyn.Path path;
    end META_ARRAY;

    record META_POLYMORPHIC
      Absyn.Path path;
    end META_POLYMORPHIC;
    /*---------------------*/
  end State;

end ClassInf;

package Config
  function showAnnotations
    output Boolean outShowAnnotations;
  end showAnnotations;

  function showStructuralAnnotations
    output Boolean outShowAnnotations;
  end showStructuralAnnotations;

  function showStartOrigin
    output Boolean show;
  end showStartOrigin;
end Config;

package Absyn

  type Ident = String;

  uniontype Path
      record QUALIFIED
        Ident name;
        Path path;
      end QUALIFIED;

      record IDENT
        Ident name;
      end IDENT;

      record FULLYQUALIFIED
        Path path;
      end FULLYQUALIFIED;
    end Path;

end Absyn;

package SCode

   uniontype Visibility
     record PUBLIC end PUBLIC;
     record PROTECTED end PROTECTED;
  end Visibility;

   uniontype Variability
     record VAR      end VAR;
     record DISCRETE end DISCRETE;
     record PARAM    end PARAM;
     record CONST    end CONST;
  end Variability;

  uniontype Comment
    record COMMENT
      Option<Annotation> annotation_;
      Option<String> comment;
    end COMMENT;
  end Comment;

  uniontype Annotation
    record ANNOTATION
      Mod modification;
    end ANNOTATION;
  end Annotation;

end SCode;


package DAEDump

uniontype compWithSplitElements
  record COMP_WITH_SPLIT
    String name;
    splitElements spltElems;
    Option<SCode.Comment> comment;
  end COMP_WITH_SPLIT;
end compWithSplitElements;

uniontype splitElements
  record SPLIT_ELEMENTS
    list<DAE.Element> v;
    list<DAE.Element> ie;
    list<DAE.Element> ia;
    list<DAE.Element> e;
    list<DAE.Element> a;
    list<DAE.Element> co;
    list<DAE.Element> o;
    list<DAE.Element> ca;
    list<compWithSplitElements> sm;
  end SPLIT_ELEMENTS;
end splitElements;

uniontype functionList
  record FUNCTION_LIST
    list<DAE.Function> funcs;
  end FUNCTION_LIST;
end functionList;

function filterStructuralMods
  input SCode.Mod mod;
  output SCode.Mod outMod;
end filterStructuralMods;

end DAEDump;



package DAE

    type Ident = String;

    type InstDims = list<Dimension>;
    type Dimensions = list<Dimension>;

  uniontype DAElist
    record DAE
      list<Element> elementLst;
    end DAE;
  end DAElist;

  /* AVLTree for functions */
  type AvlKey = Absyn.Path;

  type AvlValue = Option<Function>;

  type FunctionTree = AvlTree;

  uniontype AvlTree "The binary tree data structure"
    record AVLTREENODE
      Option<AvlTreeValue> value "Value" ;
      Integer height "heigth of tree, used for balancing";
      Option<AvlTree> left "left subtree" ;
      Option<AvlTree> right "right subtree" ;
    end AVLTREENODE;

  end AvlTree;

  uniontype AvlTreeValue "Each node in the binary tree can have a value associated with it."
    record AVLTREEVALUE
      AvlKey key "Key" ;
      AvlValue value "Value" ;
    end AVLTREEVALUE;

  end AvlTreeValue;

  uniontype ElementSource "gives information about the origin of the element"
    record SOURCE
      SourceInfo info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Within> partOfLst "the model(s) this element came from";
      list<Option<ComponentRef>> instanceOptLst "the instance(s) this element is part of";
      list<Option<tuple<ComponentRef, ComponentRef>>> connectEquationOptLst "this element came from this connect(s)";
      list<Absyn.Path> typeLst "the classes where the type(s) of the element is defined";
      list<SymbolicOperation> operations "the symbolic operations used to end up with the final state of the element";
      list<SCode.Comment> comment;
    end SOURCE;
  end ElementSource;

  uniontype Element
    record VAR
      ComponentRef componentRef " The variable name";
      VarKind kind "varible kind: variable, constant, parameter, discrete etc." ;
      VarDirection direction "input, output or bidir" ;
      VarParallelism parallelism "parglobal, parlocal, or non_parallel";
      VarVisibility protection "if protected or public";
      Type ty "Full type information required";
      Option<Exp> binding "Binding expression e.g. for parameters ; value of start attribute";
      InstDims  dims "dimensions";
      Flow flowPrefix "Flow of connector variable. Needed for unconnected flow variables" ;
      Stream streamPrefix "Stream variables in connectors" ;
      ElementSource source "the origins of the component/equation/algorithm";
      Option<VariableAttributes> variableAttributesOption;
      Option<SCode.Comment> comment;
      Absyn.InnerOuter innerOuter "inner/outer required to 'change' outer references";
    end VAR;

    record DEFINE "A solved equation"
      ComponentRef componentRef;
      Exp exp;
      ElementSource source "the origin of the component/equation/algorithm";
    end DEFINE;

    record INITIALDEFINE " A solved initial equation"
      ComponentRef componentRef;
      Exp exp;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIALDEFINE;

    record EQUATION "Scalar equation"
      Exp exp;
      Exp scalar;
      ElementSource source "the origin of the component/equation/algorithm";
    end EQUATION;

    record EQUEQUATION "effort variable equality"
      ComponentRef cr1;
      ComponentRef cr2;
      ElementSource source "the origin of the component/equation/algorithm";
    end EQUEQUATION;

    record ARRAY_EQUATION " an array equation"
      Dimensions dimension "dimension sizes" ;
      Exp exp;
      Exp array;
      ElementSource source "the origin of the component/equation/algorithm";
    end ARRAY_EQUATION;

    record INITIAL_ARRAY_EQUATION "An initial array equation"
      Dimensions dimension "dimension sizes";
      Exp exp;
      Exp array;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIAL_ARRAY_EQUATION;

    record CONNECT_EQUATION "a connect equation"
      Element lhsElement;
      Connect.Face lhsFace;
      Element rhsElement;
      Connect.Face rhsFace;
      ElementSource source "the origin of the component/equation/algorithm";
    end CONNECT_EQUATION;

    record COMPLEX_EQUATION "an equation of complex type, e.g. record = func(..)"
      Exp lhs;
      Exp rhs;
      ElementSource source "the origin of the component/equation/algorithm";
    end COMPLEX_EQUATION;

    record INITIAL_COMPLEX_EQUATION "an initial equation of complex type, e.g. record = func(..)"
      Exp lhs;
      Exp rhs;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIAL_COMPLEX_EQUATION;

    record WHEN_EQUATION " a when equation"
      Exp condition "Condition" ;
      list<Element> equations "Equations" ;
      Option<Element> elsewhen_ "Elsewhen should be of type WHEN_EQUATION" ;
      ElementSource source "the origin of the component/equation/algorithm";
    end WHEN_EQUATION;

    record FOR_EQUATION " a for-equation"
      Type type_ "this is the type of the iterator";
      Boolean iterIsArray "True if the iterator has an array type, otherwise false.";
      Ident iter "the iterator variable";
      Integer index "the index of the iterator variable, to make it unique; used by the new inst";
      Exp range "range for the loop";
      list<Element> equations "Equations" ;
      ElementSource source "the origin of the component/equation/algorithm" ;
    end FOR_EQUATION;

    record IF_EQUATION " an if-equation"
      list<Exp> condition1 "Condition" ;
      list<list<Element>> equations2 "Equations of true branch" ;
      list<Element> equations3 "Equations of false branch" ;
      ElementSource source "the origin of the component/equation/algorithm";
    end IF_EQUATION;

    record INITIAL_IF_EQUATION "An initial if-equation"
      list<Exp> condition1 "Condition" ;
      list<list<Element>> equations2 "Equations of true branch" ;
      list<Element> equations3 "Equations of false branch" ;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIAL_IF_EQUATION;

    record INITIALEQUATION " An initial equaton"
      Exp exp1;
      Exp exp2;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIALEQUATION;

    record ALGORITHM " An algorithm section"
      Algorithm algorithm_;
      ElementSource source "the origin of the component/equation/algorithm";
    end ALGORITHM;

    record INITIALALGORITHM " An initial algorithm section"
      Algorithm algorithm_;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIALALGORITHM;

    record COMP
      Ident ident;
      list<Element> dAElist "a component with subelements, normally only used at top level.";
      ElementSource source "the origin of the component/equation/algorithm"; // we might not this here.
      Option<SCode.Comment> comment;
    end COMP;

    record EXTOBJECTCLASS "The 'class' of an external object"
      Absyn.Path path "className of external object";
      ElementSource source "the origin of the component/equation/algorithm";
    end EXTOBJECTCLASS;

    record ASSERT " The Modelica builtin assert"
      Exp condition;
      Exp message;
      Exp level;
      ElementSource source "the origin of the component/equation/algorithm";
    end ASSERT;

    record INITIAL_ASSERT " The Modelica builtin assert"
      Exp condition;
      Exp message;
      Exp level;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIAL_ASSERT;

    record TERMINATE " The Modelica builtin terminate(msg)"
      Exp message;
      ElementSource source "the origin of the component/equation/algorithm";
    end TERMINATE;

    record INITIAL_TERMINATE " The Modelica builtin terminate(msg)"
      Exp message;
      ElementSource source "the origin of the component/equation/algorithm";
    end INITIAL_TERMINATE;

    record REINIT " reinit operator for reinitialization of states"
      ComponentRef componentRef;
      Exp exp;
      ElementSource source "the origin of the component/equation/algorithm";
    end REINIT;

    record NORETCALL "call with no return value, i.e. no equation.
      Typically sideeffect call of external function but also
      Connections.* i.e. Connections.root(...) functions."
      Exp exp;
      ElementSource source "the origin of the component/equation/algorithm";
    end NORETCALL;

    record INITIAL_NORETCALL "call with no return value, i.e. no equation.
      Typically sideeffect call of external function but also
      Connections.* i.e. Connections.root(...) functions."
      Exp exp;
      ElementSource source "the origin of the component/equation/algorithm" ;
    end INITIAL_NORETCALL;

    record CONSTRAINT " constraint section"
      Constraint constraints;
      ElementSource source "the origin of the component/equation/algorithm";
    end CONSTRAINT;

    record COMMENT
      SCode.Comment cmt;
    end COMMENT;

  end Element;

  uniontype Algorithm "The `Algorithm\' type corresponds to a whole algorithm section.
    It is simple a list of algorithm statements."
    record ALGORITHM_STMTS
      list<Statement> statementLst;
    end ALGORITHM_STMTS;

  end Algorithm;

  uniontype Statement
    record STMT_ASSIGN
      Exp exp1;
      Exp exp;
      ElementSource source;
    end STMT_ASSIGN;

    record STMT_TUPLE_ASSIGN
      list<Exp> expExpLst;
      Exp exp;
      ElementSource source;
    end STMT_TUPLE_ASSIGN;

    record STMT_ASSIGN_ARR
      Exp lhs;
      Exp exp;
      ElementSource source;
    end STMT_ASSIGN_ARR;

    record STMT_IF
      Exp exp;
      list<Statement> statementLst;
      Else else_;
      ElementSource source;
    end STMT_IF;

    record STMT_FOR
      Boolean iterIsArray;
      Ident iter;
      Exp range;
      list<Statement> statementLst;
      ElementSource source;
    end STMT_FOR;

    record STMT_WHILE
      Exp exp;
      list<Statement> statementLst;
      ElementSource source;
    end STMT_WHILE;

    record STMT_WHEN
      Exp exp;
      list<Statement> statementLst;
      Option<Statement> elseWhen;
      list<Integer> helpVarIndices;
      ElementSource source;
    end STMT_WHEN;

    record STMT_ASSERT
      Exp cond;
      Exp msg;
      Exp level;
      ElementSource source;
    end STMT_ASSERT;

    record STMT_TERMINATE
      Exp msg;
      ElementSource source;
    end STMT_TERMINATE;

    record STMT_REINIT
      Exp var;
      Exp value;
      ElementSource source;
    end STMT_REINIT;

    record STMT_NORETCALL
      Exp exp;
      ElementSource source;
    end STMT_NORETCALL;

    record STMT_RETURN
      ElementSource source;
    end STMT_RETURN;

    record STMT_CONTINUE
      ElementSource source;
    end STMT_CONTINUE;

    record STMT_BREAK
      ElementSource source;
    end STMT_BREAK;

    record STMT_FAILURE
      list<Statement> body;
      ElementSource source;
    end STMT_FAILURE;
  end Statement;

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

    record MUL_ARR
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

  uniontype ExternalDecl
    record EXTERNALDECL
      String name;
      list<ExtArg> args;
      ExtArg returnArg;
      String language;
      Option<SCode.Annotation> ann;
    end EXTERNALDECL;
  end ExternalDecl;

  uniontype ExtArg
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

  uniontype Var "- Variables"
    record TYPES_VAR
      Ident name "name";
      Attributes attributes "attributes";
      Type ty "type" ;
      Binding binding "equation modification";
      Option<Const> constOfForIteratorRange "the constant-ness of the range if this is a for iterator, NONE() if is NOT a for iterator";
    end TYPES_VAR;
  end Var;

  uniontype Attributes "- Attributes"
    record ATTR
      ConnectorType       connectorType "flow, stream or unspecified";
      SCode.Parallelism   parallelism "parallelism";
      SCode.Variability   variability "variability" ;
      Absyn.Direction     direction "direction" ;
      Absyn.InnerOuter    innerOuter "inner, outer,  inner outer or unspecified";
      SCode.Visibility    visibility "public, protected";
    end ATTR;
  end Attributes;

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

    record WILD end WILD;

  end ComponentRef;

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

  uniontype VarKind
    record VARIABLE "variable" end VARIABLE;
    record DISCRETE "discrete" end DISCRETE;
    record PARAM "parameter"   end PARAM;
    record CONST "constant"    end CONST;
  end VarKind;

  uniontype ConnectorType "The type of a connector element."
    record POTENTIAL end POTENTIAL;
    record FLOW end FLOW;
    record STREAM
      Option<ComponentRef> associatedFlow;
    end STREAM;
    record NON_CONNECTOR end NON_CONNECTOR;
  end ConnectorType;

  uniontype VarDirection
    record INPUT  "input"                   end INPUT;
    record OUTPUT "output"                  end OUTPUT;
    record BIDIR  "neither input or output" end BIDIR;
  end VarDirection;

  uniontype VarParallelism
    record PARGLOBAL     "Global variables for CUDA and OpenCL"     end PARGLOBAL;
    record PARLOCAL      "Shared for CUDA and local for OpenCL"     end PARLOCAL;
    record NON_PARALLEL  "Non parallel/Normal variables"            end NON_PARALLEL;
  end VarParallelism;

  uniontype StateSelect
    record NEVER end NEVER;
    record AVOID end AVOID;
    record DEFAULT end DEFAULT;
    record PREFER end PREFER;
    record ALWAYS end ALWAYS;
  end StateSelect;

  uniontype Uncertainty
    record GIVEN end GIVEN;
    record SOUGHT end SOUGHT;
    record REFINE end REFINE;
  end Uncertainty;

  uniontype Distribution
    record DISTRIBUTION
      Exp name;
      Exp params;
      Exp paramNames;
    end DISTRIBUTION;
  end Distribution;

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

  uniontype VarVisibility
    record PUBLIC "public variables"       end PUBLIC;
    record PROTECTED "protected variables" end PROTECTED;
  end VarVisibility;

  uniontype Function
    record FUNCTION " A Modelica function"
      Absyn.Path path;
      list<FunctionDefinition> functions "contains the body and an optional function derivative mapping";
      Type type_;
      Boolean partialPrefix "MetaModelica extension";
      Boolean isImpure;
      InlineType inlineType;
      ElementSource source "the origin of the component/equation/algorithm";
      Option<SCode.Comment> comment;
    end FUNCTION;

    record RECORD_CONSTRUCTOR "A Modelica record constructor. The function can be generated from the Path and Type alone."
      Absyn.Path path;
      Type type_;
      ElementSource source "the origin of the component/equation/algorithm";
    end RECORD_CONSTRUCTOR;
  end Function;

  uniontype FunctionDefinition

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

  uniontype derivativeCond "Different conditions on derivatives"
    record ZERO_DERIVATIVE end ZERO_DERIVATIVE;
    record NO_DERIVATIVE
      Exp binding;
    end NO_DERIVATIVE;
  end derivativeCond;

  type TypeSource = list<Absyn.Path>;

  uniontype Type "models the different front-end and back-end types"

    record T_INTEGER
      list<Var> varLst;
    end T_INTEGER;

    record T_REAL
      list<Var> varLst;
    end T_REAL;

    record T_STRING
      list<Var> varLst;
    end T_STRING;

    record T_BOOL
      list<Var> varLst;
    end T_BOOL;

    record T_CLOCK
      list<Var> varLst;
    end T_CLOCK;

    record T_ENUMERATION "If the list of names is empty, this is the super-enumeration that is the super-class of all enumerations"
      Option<Integer> index "the enumeration value index, SOME for element, NONE() for type" ;
      Absyn.Path path "enumeration path" ;
      list<String> names "names" ;
      list<Var> literalVarLst;
      list<Var> attributeLst;
    end T_ENUMERATION;

    record T_ARRAY
      "an array can be represented in two equivalent ways:
         1. T_ARRAY(non_array_type, {dim1, dim2, dim3}) =
         2. T_ARRAY(T_ARRAY(T_ARRAY(non_array_type, {dim1}), {dim2}), {dim3})
         In general Inst generates 1 and all the others generates 2"
      Type ty "Type";
      Dimensions dims "dims";
    end T_ARRAY;

    record T_NORETCALL "For functions not returning any values."
    end T_NORETCALL;

    record T_UNKNOWN "Used when type is not yet determined"
    end T_UNKNOWN;

    record T_COMPLEX
      ClassInf.State complexClassType "The type of a class" ;
      list<Var> varLst "The variables of a complex type" ;
      EqualityConstraint equalityConstraint;
    end T_COMPLEX;

    record T_SUBTYPE_BASIC
      ClassInf.State complexClassType "The type of a class" ;
      list<Var> varLst "complexVarLst; The variables of a complex type! Should be empty, kept here to verify!";
      Type complexType "complexType; A complex type can be a subtype of another (primitive) type (through extends)";
      EqualityConstraint equalityConstraint;
    end T_SUBTYPE_BASIC;

    record T_FUNCTION
      list<FuncArg> funcArg;
      Type funcResultType "Only single-result" ;
      FunctionAttributes functionAttributes;
      Absyn.Path path;
    end T_FUNCTION;

    record T_FUNCTION_REFERENCE_VAR "MetaModelica Function Reference that is a variable"
      Type functionType "the type of the function";
    end T_FUNCTION_REFERENCE_VAR;

    record T_FUNCTION_REFERENCE_FUNC "MetaModelica Function Reference that is a direct reference to a function"
      Boolean builtin;
      Type functionType "type of the non-boxptr function";
      TypeSource source;
    end T_FUNCTION_REFERENCE_FUNC;

    record T_TUPLE
      list<Type> types "For functions returning multiple values.";
    end T_TUPLE;

    record T_CODE
      CodeType ty;
      TypeSource source;
    end T_CODE;

    record T_ANYTYPE
      Option<ClassInf.State> anyClassType "anyClassType - used for generic types. When class state present the type is assumed to be a complex type which has that restriction.";
    end T_ANYTYPE;

    // MetaModelica extensions
    record T_METALIST "MetaModelica list type"
      Type ty "listType";
    end T_METALIST;

    record T_METATUPLE "MetaModelica tuple type"
      list<Type> types;
    end T_METATUPLE;

    record T_METAOPTION "MetaModelica option type"
      Type ty;
    end T_METAOPTION;

    record T_METAUNIONTYPE "MetaModelica Uniontype"
      list<Absyn.Path> paths;
      Boolean knownSingleton "The runtime system (dynload), does not know if the value is a singleton. But optimizations are safe if this is true.";
      Absyn.Path path;
    end T_METAUNIONTYPE;

    record T_METARECORD "MetaModelica Record, used by Uniontypes. added by simbj"
      Absyn.Path path;
      Absyn.Path utPath "the path to its uniontype; this is what we match the type against";
      // If the metarecord constructor was added to the FunctionTree, this would
      // not be needed. They are used to create the datatype in the runtime...
      Integer index; //The index in the uniontype
      list<Var> fields;
      Boolean knownSingleton "The runtime system (dynload), does not know if the value is a singleton. But optimizations are safe if this is true.";
    end T_METARECORD;

    record T_METAARRAY
      Type ty;
    end T_METAARRAY;

    record T_METABOXED "Used for MetaModelica generic types"
      Type ty;
    end T_METABOXED;

    record T_METAPOLYMORPHIC
      String name;
    end T_METAPOLYMORPHIC;

    record T_METATYPE "this type contains all the meta types"
      Type ty;
    end T_METATYPE;

  end Type;

  uniontype InlineType
    record NORM_INLINE "Normal inline, inline as soon as possible"
    end NORM_INLINE;

    record EARLY_INLINE "Inline even earlier than NORM_INLINE. This will display the inlined code in the flattened model and also works for functions calling other functions that should be inlined."
    end EARLY_INLINE;

    record NO_INLINE "Avoid inline, this is default behaviour but is also possible to set with Inline=false"
    end NO_INLINE;

    record AFTER_INDEX_RED_INLINE "Try to inline after index reduction"
    end AFTER_INDEX_RED_INLINE;
  end InlineType;

  uniontype Binding "- Binding"
    record UNBOUND end UNBOUND;

    record EQBOUND
      Exp exp "exp";
      Option<Values.Value> evaluatedExp "evaluatedExp; evaluated exp";
      Const constant_ "constant";
      BindingSource source "Used for error reporting: this boolean tells us that the parameter did not had a binding but had a start value that was used instead.";
    end EQBOUND;

    record VALBOUND
      Values.Value valBound "valBound";
      BindingSource source "Used for error reporting: this boolean tells us that the parameter did not had a binding but had a start value that was used instead";
    end VALBOUND;

  end Binding;

  uniontype Flow "The Flow of a variable indicates if it is a Flow variable or not, or if
     it is not a connector variable at all."
    record FLOW end FLOW;
    record NON_FLOW end NON_FLOW;
    record NON_CONNECTOR end NON_CONNECTOR;
  end Flow;


  uniontype Dimension
    record DIM_INTEGER "Dimension given by an integer."
      Integer integer;
    end DIM_INTEGER;

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

  uniontype FuncArg
    record FUNCARG
      String name;
      Type ty;
      Const const;
      VarParallelism par;
      Option<Exp> defaultBinding;
    end FUNCARG;
  end FuncArg;

  uniontype Const
    record C_CONST end C_CONST;
    record C_PARAM end C_PARAM;
    record C_VAR end C_VAR;
    record C_UNKNOWN end C_UNKNOWN;
  end Const;

  uniontype Exp "Expressions
      The `Exp\' datatype closely corresponds to the `Absyn.Exp\'
      datatype, but is used for statically analyzed expressions.  It
      includes explicit type promotions and typed (non-overloaded)
      operators. It also contains expression indexing with the `ASUB\'
      constructor.  Indexing arbitrary array expressions is currently
      not supported in Modelica, but it is needed here.

      When making additions, update at least the following functions:
      * Expression.traverseExp
      * Expression.traverseExpTopDown
      * Expression.traverseExpBiDir
      * ExpressionDump.printExpStr
      "
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

    record PARTEVALFUNCTION
      Absyn.Path path;
      list<Exp> expList;
      Type ty;
    end PARTEVALFUNCTION;

    record ARRAY
      Type ty;
      Boolean scalar "scalar for codegen" ;
      list<Exp> array "Array constructor, e.g. {1,3,4}" ;
    end ARRAY;

    record MATRIX
      Type ty;
      Integer integer;
      list<list<Exp>> matrix;
    end MATRIX;

    record RANGE
      Type ty;
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
    end METARECORDCALL;

    record MATCHEXPRESSION
      MatchType matchType;
      list<Exp> inputs;
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
      Integer index;
      Type ty "The type is required for code generation to work properly";
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

  end Exp;

  uniontype CallAttributes
    record CALL_ATTR
      TailCall tailCall "Input variables of the function if the call is tail-recursive";
    end CALL_ATTR;
  end CallAttributes;

  uniontype TailCall
    record NO_TAIL
    end NO_TAIL;
    record TAIL
    end TAIL;
  end TailCall;

end DAE;

package SCodeDump
  constant SCodeDumpOptions defaultOptions;
end SCodeDump;

package Tpl
  function addTemplateError
    input String inErrMsg;
  end addTemplateError;
end Tpl;

package System
  function escapedString
    input String unescapedString;
    input Boolean unescapeNewline;
    output String escapedString;
  end escapedString;

  function stringReplace
    input String str;
    input String source;
    input String target;
    output String res;
  end stringReplace;

end System;

package Flags
  uniontype ConfigFlag end ConfigFlag;
  constant ConfigFlag MODELICA_OUTPUT;
  function getConfigBool
    input ConfigFlag inFlag;
    output Boolean outValue;
  end getConfigBool;
end Flags;

end DAEDumpTV;
