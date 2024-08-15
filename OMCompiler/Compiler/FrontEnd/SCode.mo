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

encapsulated package SCode
" file:        SCodeUtil.mo
  package:     SCode
  description: SCode intermediate form


  This module contains data structures to describe a Modelica
  model in a more convenient (canonical) way than the Absyn module does.
  Local functions for query of SCode are defined.

  Printing and translating to string functions are now moved to SCodeDump! (2011-05-21)

  See also AbsynToSCode.mo for translation functions from Absyn representation to SCode representation.

  The SCode representation is used as input to the Inst module"

public import Absyn;

// Some definitions are aliased from Absyn
public type Ident = Absyn.Ident;
public type Path = Absyn.Path;
public type Subscript = Absyn.Subscript;

public
uniontype Restriction
  record R_CLASS end R_CLASS;
  record R_OPTIMIZATION end R_OPTIMIZATION;
  record R_MODEL end R_MODEL;
  record R_RECORD
    Boolean isOperator;
  end R_RECORD;
  record R_BLOCK end R_BLOCK;
  record R_CONNECTOR "a connector"
    Boolean isExpandable "is expandable?";
  end R_CONNECTOR;
  record R_OPERATOR end R_OPERATOR;
  record R_TYPE end R_TYPE;
  record R_PACKAGE end R_PACKAGE;
  record R_FUNCTION
    FunctionRestriction functionRestriction;
  end R_FUNCTION;

  record R_ENUMERATION end R_ENUMERATION;

  // predefined internal types
  record R_PREDEFINED_INTEGER     "predefined IntegerType" end R_PREDEFINED_INTEGER;
  record R_PREDEFINED_REAL        "predefined RealType"    end R_PREDEFINED_REAL;
  record R_PREDEFINED_STRING      "predefined StringType"  end R_PREDEFINED_STRING;
  record R_PREDEFINED_BOOLEAN     "predefined BooleanType" end R_PREDEFINED_BOOLEAN;
  record R_PREDEFINED_ENUMERATION "predefined EnumType"    end R_PREDEFINED_ENUMERATION;
  // BTH
  record R_PREDEFINED_CLOCK       "predefined ClockType"   end R_PREDEFINED_CLOCK;

  // MetaModelica extensions
  record R_METARECORD "Metamodelica extension"
    Absyn.Path name; //Name of the uniontype
    Integer index; //Index in the uniontype
    Boolean singleton;
    Boolean moved; // true if moved outside uniontype, otherwise false.
    list<String> typeVars;
  end R_METARECORD; /* added by x07simbj */

  record R_UNIONTYPE "Metamodelica extension"
    list<String> typeVars;
  end R_UNIONTYPE; /* added by simbj */
end Restriction;

// Same as Absyn.FunctionRestriction except this contains
// FR_EXTERNAL_FUNCTION and FR_RECORD_CONSTRUCTOR.
public
uniontype FunctionRestriction
  record FR_NORMAL_FUNCTION "a normal function"
    Absyn.FunctionPurity purity;
  end FR_NORMAL_FUNCTION;
  record FR_EXTERNAL_FUNCTION "an external function"
    Absyn.FunctionPurity purity;
  end FR_EXTERNAL_FUNCTION;

  record FR_OPERATOR_FUNCTION "an operator function" end FR_OPERATOR_FUNCTION;
  record FR_RECORD_CONSTRUCTOR "record constructor"  end FR_RECORD_CONSTRUCTOR;
  record FR_PARALLEL_FUNCTION "an OpenCL/CUDA parallel/device function" end FR_PARALLEL_FUNCTION;
  record FR_KERNEL_FUNCTION "an OpenCL/CUDA kernel function" end FR_KERNEL_FUNCTION;
end FunctionRestriction;

public
uniontype Mod "- Modifications"

  record MOD
    Final finalPrefix "final prefix";
    Each  eachPrefix "each prefix";
    list<SubMod> subModLst;
    Option<Absyn.Exp> binding;
    Option<String> comment;
    SourceInfo info;
  end MOD;

  record REDECL
    Final         finalPrefix "final prefix";
    Each          eachPrefix  "each prefix";
    Element       element     "The new element declaration.";
  end REDECL;

  record NOMOD end NOMOD;

end Mod;

public
uniontype SubMod "Modifications are represented in an more structured way than in
    the `Absyn\' module.  Modifications using qualified names
    (such as in `x.y =  z\') are normalized (to `x(y = z)\')."
  record NAMEMOD
    Ident ident;
    Mod mod "A named component" ;
  end NAMEMOD;
end SubMod;

public
type Program = list<Element> "- Programs
As in the AST, a program is simply a list of class definitions.";

public
uniontype Enum "Enum, which is a name in an enumeration and an optional Comment."
  record ENUM
    Ident   literal;
    Comment comment;
  end ENUM;
end Enum;

public
uniontype ClassDef
"The major difference between these types and their Absyn
 counterparts is that the PARTS constructor contains separate
 lists for elements, equations and algorithms.

 SCode.PARTS contains elements of a class definition. For instance,
    model A
      extends B;
      C c;
    end A;
 Here PARTS contains two elements ('extends B' and 'C c')
 SCode.DERIVED is used for short class definitions, i.e:
  class A = B[ArrayDims](modifiers);
 SCode.CLASS_EXTENDS is used for extended class definition, i.e:
  class extends A (modifier)
    new elements;
  end A;"

  record PARTS "a class made of parts"
    list<Element>              elementLst          "the list of elements";
    list<Equation>             normalEquationLst   "the list of equations";
    list<Equation>             initialEquationLst  "the list of initial equations";
    list<AlgorithmSection>     normalAlgorithmLst  "the list of algorithms";
    list<AlgorithmSection>     initialAlgorithmLst "the list of initial algorithms";
    list<ConstraintSection>    constraintLst       "the list of constraints";
    list<Absyn.NamedArg>       clsattrs            "the list of class attributes. Currently for Optimica extensions";
    Option<ExternalDecl>       externalDecl        "used by external functions";
  end PARTS;

  record CLASS_EXTENDS "an extended class definition plus the additional parts"
    Mod                        modifications       "the modifications that need to be applied to the base class";
    ClassDef                   composition         "the new composition";
  end CLASS_EXTENDS;

  record DERIVED "a derived class"
    Absyn.TypeSpec typeSpec "typeSpec: type specification" ;
    Mod modifications       "the modifications";
    Attributes attributes   "the element attributes";
  end DERIVED;

  record ENUMERATION "an enumeration"
    list<Enum> enumLst      "if the list is empty it means :, the supertype of all enumerations";
  end ENUMERATION;

  record OVERLOAD "an overloaded function"
    list<Absyn.Path> pathLst "the path lists";
  end OVERLOAD;

  record PDER "the partial derivative"
    Absyn.Path  functionPath     "function name" ;
    list<Ident> derivedVariables "derived variables" ;
  end PDER;

end ClassDef;


public
uniontype Comment

  record COMMENT
    Option<Annotation> annotation_;
    Option<String> comment;
  end COMMENT;

end Comment;

public constant Comment noComment = COMMENT(NONE(),NONE());

// stefan
public
uniontype Annotation

  record ANNOTATION
    Mod modification;
  end ANNOTATION;

end Annotation;

public
uniontype ExternalDecl "Declaration of an external function call - ExternalDecl"
  record EXTERNALDECL
    Option<Ident>        funcName "The name of the external function" ;
    Option<String>       lang     "Language of the external function" ;
    Option<Absyn.ComponentRef> output_  "output parameter as return value" ;
    list<Absyn.Exp>      args     "only positional arguments, i.e. expression list" ;
    Option<Annotation>   annotation_ ;
  end EXTERNALDECL;

end ExternalDecl;

public
uniontype Equation
"These represent equations and are almost identical to their Absyn versions.
 In EQ_IF the elseif branches are represented as normal else branches with
 a single if statement in them."
  record EQ_IF
    list<Absyn.Exp> condition "conditional" ;
    list<list<Equation>> thenBranch "the true (then) branch" ;
    list<Equation>       elseBranch "the false (else) branch" ;
    Comment comment;
    SourceInfo info;
  end EQ_IF;

  record EQ_EQUALS "the equality equation"
    Absyn.Exp expLeft  "the expression on the left side of the operator";
    Absyn.Exp expRight "the expression on the right side of the operator";
    Comment comment;
    SourceInfo info;
  end EQ_EQUALS;

  record EQ_PDE "partial differential equation or boundary condition"
    Absyn.Exp expLeft  "the expression on the left side of the operator";
    Absyn.Exp expRight "the expression on the right side of the operator";
    Absyn.ComponentRef domain "domain for PDEs" ;
    Comment comment;
    SourceInfo info;
  end EQ_PDE;

  record EQ_CONNECT "the connect equation"
    Absyn.ComponentRef crefLeft  "the connector/component reference on the left side";
    Absyn.ComponentRef crefRight "the connector/component reference on the right side";
    Comment comment;
    SourceInfo info;
  end EQ_CONNECT;

  record EQ_FOR "the for equation"
    Ident index "the index name";
    Option<Absyn.Exp> range "the range of the index";
    list<Equation> eEquationLst "the equation list";
    Comment comment;
    SourceInfo info;
  end EQ_FOR;

  record EQ_WHEN "the when equation"
    Absyn.Exp        condition "the when condition";
    list<Equation>  eEquationLst "the equation list";
    list<tuple<Absyn.Exp, list<Equation>>> elseBranches "the elsewhen expression and equation list";
    Comment comment;
    SourceInfo info;
  end EQ_WHEN;

  record EQ_ASSERT "the assert equation"
    Absyn.Exp condition "the assert condition";
    Absyn.Exp message   "the assert message";
    Absyn.Exp level;
    Comment comment;
    SourceInfo info;
  end EQ_ASSERT;

  record EQ_TERMINATE "the terminate equation"
    Absyn.Exp message "the terminate message";
    Comment comment;
    SourceInfo info;
  end EQ_TERMINATE;

  record EQ_REINIT "a reinit equation"
    Absyn.Exp cref      "the variable to initialize";
    Absyn.Exp expReinit "the new value" ;
    Comment comment;
    SourceInfo info;
  end EQ_REINIT;

  record EQ_NORETCALL "function calls without return value"
    Absyn.Exp exp;
    Comment comment;
    SourceInfo info;
  end EQ_NORETCALL;

end Equation;

public uniontype AlgorithmSection "- Algorithms
  The Absyn module uses the terminology from the
  grammar, where algorithm means an algorithmic
  statement. But here, an Algorithm means a whole
  algorithm section."
  record ALGORITHM "the algorithm section"
    list<Statement> statements "the algorithm statements" ;
  end ALGORITHM;

end AlgorithmSection;

public uniontype ConstraintSection
  record CONSTRAINTS
    list<Absyn.Exp> constraints;
  end CONSTRAINTS;
end ConstraintSection;

public uniontype Statement "The Statement type describes one algorithm statement in an algorithm section."
  record ALG_ASSIGN
    Absyn.Exp assignComponent "assignComponent" ;
    Absyn.Exp value "value" ;
    Comment comment;
    SourceInfo info;
  end ALG_ASSIGN;

  record ALG_IF
    Absyn.Exp boolExpr;
    list<Statement> trueBranch;
    list<tuple<Absyn.Exp, list<Statement>>> elseIfBranch;
    list<Statement> elseBranch;
    Comment comment;
    SourceInfo info;
  end ALG_IF;

  record ALG_FOR
    Ident index "the index name";
    Option<Absyn.Exp> range "the range of the index";
    list<Statement> forBody "forBody";
    Comment comment;
    SourceInfo info;
  end ALG_FOR;

  record ALG_PARFOR
    Ident index "the index name";
    Option<Absyn.Exp> range "the range of the index";
    list<Statement> parforBody "parallel for loop body";
    Comment comment;
    SourceInfo info;
  end ALG_PARFOR;

  record ALG_WHILE
    Absyn.Exp boolExpr "boolExpr" ;
    list<Statement> whileBody "whileBody" ;
    Comment comment;
    SourceInfo info;
  end ALG_WHILE;

  record ALG_WHEN_A
    list<tuple<Absyn.Exp, list<Statement>>> branches;
    Comment comment;
    SourceInfo info;
  end ALG_WHEN_A;

  record ALG_ASSERT
    Absyn.Exp condition;
    Absyn.Exp message;
    Absyn.Exp level;
    Comment comment;
    SourceInfo info;
  end ALG_ASSERT;

  record ALG_TERMINATE
    Absyn.Exp message;
    Comment comment;
    SourceInfo info;
  end ALG_TERMINATE;

  record ALG_REINIT
    Absyn.Exp cref;
    Absyn.Exp newValue;
    Comment comment;
    SourceInfo info;
  end ALG_REINIT;

  record ALG_NORETCALL
    Absyn.Exp exp;
    Comment comment;
    SourceInfo info;
  end ALG_NORETCALL;

  record ALG_RETURN
    Comment comment;
    SourceInfo info;
  end ALG_RETURN;

  record ALG_BREAK
    Comment comment;
    SourceInfo info;
  end ALG_BREAK;

  // MetaModelica extensions
  record ALG_FAILURE
    list<Statement> stmts;
    Comment comment;
    SourceInfo info;
  end ALG_FAILURE;

  record ALG_TRY
    list<Statement> body;
    list<Statement> elseBody;
    Comment comment;
    SourceInfo info;
  end ALG_TRY;

  record ALG_CONTINUE
    Comment comment;
    SourceInfo info;
  end ALG_CONTINUE;

end Statement;

// common prefixes to elements
public
uniontype Visibility "the visibility prefix"
  record PUBLIC    "a public element"    end PUBLIC;
  record PROTECTED "a protected element" end PROTECTED;
end Visibility;

public
uniontype Redeclare "the redeclare prefix"
  record REDECLARE     "a redeclare prefix"     end REDECLARE;
  record NOT_REDECLARE "a non redeclare prefix" end NOT_REDECLARE;
end Redeclare;

public uniontype ConstrainClass
  record CONSTRAINCLASS
    Absyn.Path constrainingClass;
    Mod modifier;
    Comment comment;
  end CONSTRAINCLASS;
end ConstrainClass;

public
uniontype Replaceable "the replaceable prefix"
  record REPLACEABLE "a replaceable prefix containing an optional constraint"
    Option<ConstrainClass> cc  "the constraint class";
  end REPLACEABLE;
  record NOT_REPLACEABLE "a non replaceable prefix" end NOT_REPLACEABLE;
end Replaceable;

public
uniontype Final "the final prefix"
  record FINAL    "a final prefix"      end FINAL;
  record NOT_FINAL "a non final prefix" end NOT_FINAL;
end Final;

public
uniontype Each "the each prefix"
  record EACH     "a each prefix"     end EACH;
  record NOT_EACH "a non each prefix" end NOT_EACH;
end Each;

public
uniontype Encapsulated "the encapsulated prefix"
  record ENCAPSULATED     "a encapsulated prefix"     end ENCAPSULATED;
  record NOT_ENCAPSULATED "a non encapsulated prefix" end NOT_ENCAPSULATED;
end Encapsulated;

public
uniontype Partial "the partial prefix"
  record PARTIAL     "a partial prefix"     end PARTIAL;
  record NOT_PARTIAL "a non partial prefix" end NOT_PARTIAL;
end Partial;

public
uniontype ConnectorType
  record POTENTIAL "No connector type prefix." end POTENTIAL;
  record FLOW "A flow prefix." end FLOW;
  record STREAM "A stream prefix." end STREAM;
end ConnectorType;

public
uniontype Prefixes "the common class or component prefixes"
  record PREFIXES "the common class or component prefixes"
    Visibility       visibility           "the protected/public prefix";
    Redeclare        redeclarePrefix      "redeclare prefix";
    Final            finalPrefix          "final prefix, be it at the element or top level";
    Absyn.InnerOuter innerOuter           "the inner/outer/innerouter prefix";
    Replaceable      replaceablePrefix    "replaceable prefix";
  end PREFIXES;
end Prefixes;

public
uniontype Element "- Elements
  There are four types of elements in a declaration, represented by the constructors:
  IMPORT     (for import clauses)
  EXTENDS    (for extends clauses),
  CLASS      (for top/local class definitions)
  COMPONENT  (for local variables)
  DEFINEUNIT (for units)"

  record IMPORT "an import element"
    Absyn.Import imp                 "the import definition";
    Visibility   visibility          "the protected/public prefix";
    SourceInfo   info                "the import information";
  end IMPORT;

  record EXTENDS "the extends element"
    Path baseClassPath               "the extends path";
    Visibility visibility            "the protected/public prefix";
    Mod modifications                "the modifications applied to the base class";
    Option<Annotation> ann           "the extends annotation";
    SourceInfo info                  "the extends info";
  end EXTENDS;

  record CLASS "a class definition"
    Ident   name                     "the name of the class";
    Prefixes prefixes                "the common class or component prefixes";
    Encapsulated encapsulatedPrefix  "the encapsulated prefix";
    Partial partialPrefix            "the partial prefix";
    Restriction restriction          "the restriction of the class";
    ClassDef classDef                "the class specification";
    Comment cmt                      "the class annotation and string-comment";
    SourceInfo info                  "the class information";
  end CLASS;

  record COMPONENT "a component"
    Ident name                      "the component name";
    Prefixes prefixes               "the common class or component prefixes";
    Attributes attributes           "the component attributes";
    Absyn.TypeSpec typeSpec         "the type specification";
    Mod modifications               "the modifications to be applied to the component";
    Comment comment                 "this if for extraction of comments and annotations from Absyn";
    Option<Absyn.Exp> condition     "the conditional declaration of a component";
    SourceInfo info                 "this is for line and column numbers, also file name.";
  end COMPONENT;

  record DEFINEUNIT "a unit defintion has a name and the two optional parameters exp, and weight"
    Ident name;
    Visibility visibility            "the protected/public prefix";
    Option<String> exp               "the unit expression";
    Option<Real> weight              "the weight";
    SourceInfo info                  "The source information";
  end DEFINEUNIT;

end Element;

public
uniontype Attributes "- Attributes"
  record ATTR "the attributes of the component"
    Absyn.ArrayDim arrayDims "the array dimensions of the component";
    ConnectorType connectorType "The connector type: flow, stream or nothing.";
    Parallelism parallelism "parallelism prefix: parglobal, parlocal, parprivate";
    Variability variability " the variability: parameter, discrete, variable, constant" ;
    Absyn.Direction direction "the direction: input, output or bidirectional" ;
    Absyn.IsField isField "non-fiel / field";
  end ATTR;
end Attributes;

public
uniontype Parallelism "Parallelism"
  record PARGLOBAL  "Global variables for CUDA and OpenCL"            end PARGLOBAL;
  record PARLOCAL "Shared for CUDA and local for OpenCL"              end PARLOCAL;
  record NON_PARALLEL  "Non parallel/Normal variables"                 end NON_PARALLEL;
end Parallelism;

public
uniontype Variability "the variability of a component"
  record VAR      "a variable"          end VAR;
  record DISCRETE "a discrete variable" end DISCRETE;
  record PARAM    "a parameter"         end PARAM;
  record CONST    "a constant"          end CONST;
end Variability;

public /* adrpo: previously present in Inst.mo */
uniontype Initial "the initial attribute of an algorithm or equation
 Intial is used as argument to instantiation-function for
 specifying if equations or algorithms are initial or not."
  record INITIAL     "an initial equation or algorithm" end INITIAL;
  record NON_INITIAL "a normal equation or algorithm"   end NON_INITIAL;
end Initial;


public constant Prefixes defaultPrefixes =
  PREFIXES(
    PUBLIC(),
    NOT_REDECLARE(),
    NOT_FINAL(),
    Absyn.NOT_INNER_OUTER(),
    NOT_REPLACEABLE());

public constant Prefixes defaultProtectedPrefixes =
  PREFIXES(
    PROTECTED(),
    NOT_REDECLARE(),
    NOT_FINAL(),
    Absyn.NOT_INNER_OUTER(),
    NOT_REPLACEABLE());

public constant Attributes defaultVarAttr =
  ATTR({}, POTENTIAL(), NON_PARALLEL(), VAR(), Absyn.BIDIR(), Absyn.NONFIELD());
public constant Attributes defaultParamAttr =
  ATTR({}, POTENTIAL(), NON_PARALLEL(), PARAM(), Absyn.BIDIR(), Absyn.NONFIELD());
public constant Attributes defaultConstAttr =
  ATTR({}, POTENTIAL(), NON_PARALLEL(), CONST(), Absyn.BIDIR(), Absyn.NONFIELD());
public constant Attributes defaultInputAttr =
  ATTR({}, POTENTIAL(), NON_PARALLEL(), VAR(), Absyn.INPUT(), Absyn.NONFIELD());
public constant Attributes defaultOutputAttr =
  ATTR({}, POTENTIAL(), NON_PARALLEL(), VAR(), Absyn.OUTPUT(), Absyn.NONFIELD());

annotation(__OpenModelica_Interface="frontend");
end SCode;
