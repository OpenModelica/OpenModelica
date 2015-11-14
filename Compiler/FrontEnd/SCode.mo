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
" file:        SCode.mo
  package:     SCode
  description: SCode intermediate form

  RCS: $Id$

  This module contains data structures to describe a Modelica
  model in a more convenient (canonical) way than the Absyn module does.
  Local functions for query of SCode are defined.

  Printing and translating to string functions are now moved to SCodeDump! (2011-05-21)

  See also SCodeUtil.mo for translation functions from Absyn representation to SCode representation.

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
  end R_METARECORD; /* added by x07simbj */

  record R_UNIONTYPE "Metamodelica extension"
  end R_UNIONTYPE; /* added by simbj */
end Restriction;

// Same as Absyn.FunctionRestriction except this contains
// FR_EXTERNAL_FUNCTION and FR_RECORD_CONSTRUCTOR.
public
uniontype FunctionRestriction
  record FR_NORMAL_FUNCTION "a normal function"
    Boolean isImpure "true for impure functions, false otherwise";
  end FR_NORMAL_FUNCTION;
  record FR_EXTERNAL_FUNCTION "an external function"
    Boolean isImpure "true for impure functions, false otherwise";
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
    Ident                      baseClassName       "the name of the base class we have to extend";
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

public constant Comment noComment = COMMENT(NONE(),NONE());

public
uniontype Comment

  record COMMENT
    Option<Annotation> annotation_;
    Option<String> comment;
  end COMMENT;

end Comment;

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
uniontype Equation "- Equations"
  record EQUATION "an equation"
    EEquation eEquation "an equation";
  end EQUATION;

end Equation;

public
uniontype EEquation
"These represent equations and are almost identical to their Absyn versions.
 In EQ_IF the elseif branches are represented as normal else branches with
 a single if statement in them."
  record EQ_IF
    list<Absyn.Exp> condition "conditional" ;
    list<list<EEquation>> thenBranch "the true (then) branch" ;
    list<EEquation>       elseBranch "the false (else) branch" ;
    Comment comment;
    SourceInfo info;
  end EQ_IF;

  record EQ_EQUALS "the equality equation"
    Absyn.Exp expLeft  "the expression on the left side of the operator";
    Absyn.Exp expRight "the expression on the right side of the operator";
    Comment comment;
    SourceInfo info;
  end EQ_EQUALS;

  record EQ_CONNECT "the connect equation"
    Absyn.ComponentRef crefLeft  "the connector/component reference on the left side";
    Absyn.ComponentRef crefRight "the connector/component reference on the right side";
    Comment comment;
    SourceInfo info;
  end EQ_CONNECT;

  record EQ_FOR "the for equation"
    Ident index "the index name";
    Option<Absyn.Exp> range "the range of the index";
    list<EEquation> eEquationLst "the equation list";
    Comment comment;
    SourceInfo info;
  end EQ_FOR;

  record EQ_WHEN "the when equation"
    Absyn.Exp        condition "the when condition";
    list<EEquation>  eEquationLst "the equation list";
    list<tuple<Absyn.Exp, list<EEquation>>> elseBranches "the elsewhen expression and equation list";
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
    Absyn.ComponentRef cref      "the variable to initialize";
    Absyn.Exp          expReinit "the new value" ;
    Comment comment;
    SourceInfo info;
  end EQ_REINIT;

  record EQ_NORETCALL "function calls without return value"
    Absyn.Exp exp;
    Comment comment;
    SourceInfo info;
  end EQ_NORETCALL;

end EEquation;

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
    Absyn.ComponentRef cref;
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

public constant Attributes defaultVarAttr =
  ATTR({}, POTENTIAL(), NON_PARALLEL(), VAR(), Absyn.BIDIR());
public constant Attributes defaultParamAttr =
  ATTR({}, POTENTIAL(), NON_PARALLEL(), PARAM(), Absyn.BIDIR());
public constant Attributes defaultConstAttr =
  ATTR({}, POTENTIAL(), NON_PARALLEL(), CONST(), Absyn.BIDIR());

// .......... functionality .........
protected import Error;
protected import Util;
protected import List;
protected import NFSCodeCheck;
protected import SCodeUtil;

public function stripSubmod
  "Removes all submodifiers from the Mod."
  input Mod inMod;
  output Mod outMod;
algorithm
  outMod := match(inMod)
    local
      Final fp;
      Each ep;
      Option<Absyn.Exp> binding;
      SourceInfo info;

    case MOD(fp, ep, _, binding, info)
      then MOD(fp, ep, {}, binding, info);
    else inMod;
  end match;
end stripSubmod;

public function getElementNamed
"Return the Element with the name given as first argument from the Class."
  input Ident inIdent;
  input Element inClass;
  output Element outElement;
algorithm
  outElement := match (inIdent,inClass)
    local
      Element elt;
      String id;
      list<Element> elts;

    case (id,CLASS(classDef = PARTS(elementLst = elts)))
      equation
        elt = getElementNamedFromElts(id, elts);
      then
        elt;

    /* adrpo: handle also the case model extends X then X; */
    case (id,CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = elts))))
      equation
        elt = getElementNamedFromElts(id, elts);
      then
        elt;
  end match;
end getElementNamed;

public function getElementNamedFromElts
"Helper function to getElementNamed."
  input Ident inIdent;
  input list<Element> inElementLst;
  output Element outElement;
algorithm
  outElement := matchcontinue (inIdent,inElementLst)
    local
      Element elt,comp,cdef;
      String id2,id1;
      list<Element> xs;

    case (id2,((comp as COMPONENT(name = id1)) :: _))
      equation
        true = stringEq(id1, id2);
      then
        comp;

    case (id2,(COMPONENT(name = id1) :: xs))
      equation
        false = stringEq(id1, id2);
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;

    case (id2,(CLASS(name = id1) :: xs))
      equation
        false = stringEq(id1, id2);
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;

    case (id2,(EXTENDS() :: xs))
      equation
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;

    case (id2,((cdef as CLASS(name = id1)) :: _))
      equation
        true = stringEq(id1, id2);
      then
        cdef;

    // Try next.
    case (id2, _:: xs)
      equation
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;
  end matchcontinue;
end getElementNamedFromElts;

public function isElementExtends "
Author BZ, 2009-01
check if an element is of type EXTENDS or not."
  input Element ele;
  output Boolean isExtend;
algorithm
  isExtend := match(ele)
    case EXTENDS() then true;
    else false;
  end match;
end isElementExtends;

public function isNotElementClassExtends "
check if an element is not of type CLASS_EXTENDS."
  input Element ele;
  output Boolean isExtend;
algorithm
  isExtend := match(ele)
    case CLASS(classDef = CLASS_EXTENDS()) then false;
    else true;
  end match;
end isNotElementClassExtends;

public function isParameterOrConst
"Returns true if Variability indicates a parameter or constant."
  input Variability inVariability;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVariability)
    case PARAM() then true;
    case CONST() then true;
    else false;
  end match;
end isParameterOrConst;

public function isConstant
"Returns true if Variability is constant, otherwise false"
  input Variability inVariability;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVariability)
    case CONST() then true;
    else false;
  end match;
end isConstant;

public function countParts
"Counts the number of ClassParts of a Class."
  input Element inClass;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inClass)
    local
      Integer res;
      list<Element> elts;

    case CLASS(classDef = PARTS(elementLst = elts))
      equation
        res = listLength(elts);
      then
        res;

    /* adrpo: handle also model extends X ... parts ... end X; */
    case CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = elts)))
      equation
        res = listLength(elts);
      then
        res;

    else 0;

  end matchcontinue;
end countParts;

public function componentNames
  "Return a string list of all component names of a class."
  input Element inClass;
  output list<String> outStringLst;
algorithm
  outStringLst := match (inClass)
    local list<String> res; list<Element> elts;

    case (CLASS(classDef = PARTS(elementLst = elts)))
      equation
        res = componentNamesFromElts(elts);
      then
        res;

    /* adrpo: handle also the case model extends X end X;*/
    case (CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = elts))))
      equation
        res = componentNamesFromElts(elts);
      then
        res;

    else {};

  end match;
end componentNames;

public function componentNamesFromElts
  "Helper function to componentNames."
  input list<Element> inElements;
  output list<String> outComponentNames;
algorithm
  outComponentNames := List.filterMap(inElements, componentName);
end componentNamesFromElts;

public function componentName
  input Element inComponent;
  output String outName;
algorithm
  COMPONENT(name = outName) := inComponent;
end componentName;

public function elementInfo "retrieves the element info"
  input Element e;
  output SourceInfo info;
algorithm
  info := match(e)
    local
      SourceInfo i;

    case(COMPONENT(info = i)) then i;
    case(CLASS(info = i)) then i;
    case(EXTENDS(info = i)) then i;
    case(IMPORT(info = i)) then i;
    else Absyn.dummyInfo;

  end match;
end elementInfo;

public function elementName ""
  input Element e;
  output String s;
algorithm
  s := match(e)
    case (COMPONENT(name = s)) then s;
    case (CLASS(name = s)) then s;
  end match;
end elementName;

public function elementNameInfo
  input Element inElement;
  output String outName;
  output SourceInfo outInfo;
algorithm
  (outName, outInfo) := match(inElement)
    local
      String name;
      SourceInfo info;

    case COMPONENT(name = name, info = info) then (name, info);
    case CLASS(name = name, info = info) then (name, info);

  end match;
end elementNameInfo;

public function elementNames "Gets all elements that have an element name from the list"
  input list<Element> elts;
  output list<String> names;
algorithm
  names := List.fold(elts,elementNamesWork,{});
end elementNames;

protected function elementNamesWork "Gets all elements that have an element name from the list"
  input Element e;
  input list<String> acc;
  output list<String> out;
algorithm
  out := match(e,acc)
    local
      String s;
    case (COMPONENT(name = s),_) then s::acc;
    case (CLASS(name = s),_) then s::acc;
    else acc;
  end match;
end elementNamesWork;

public function renameElement
  input Element inElement;
  input String inName;
  output Element outElement;
algorithm
  outElement := match(inElement, inName)
    local
      Prefixes pf;
      Encapsulated ep;
      Partial pp;
      Restriction res;
      ClassDef cdef;
      SourceInfo i;
      Attributes attr;
      Absyn.TypeSpec ty;
      Mod mod;
      Comment cmt;
      Option<Absyn.Exp> cond;

    case (CLASS(_, pf, ep, pp, res, cdef, cmt, i), _)
      then CLASS(inName, pf, ep, pp, res, cdef, cmt, i);

    case (COMPONENT(_, pf, attr, ty, mod, cmt, cond, i), _)
      then COMPONENT(inName, pf, attr, ty, mod, cmt, cond, i);

  end match;
end renameElement;

public function elementNameEqual
  input Element inElement1;
  input Element inElement2;
  output Boolean outEqual;
algorithm
  outEqual := match (inElement1, inElement2)
    case (CLASS(), CLASS()) then inElement1.name == inElement2.name;
    case (COMPONENT(), COMPONENT()) then inElement1.name == inElement2.name;
    case (DEFINEUNIT(), DEFINEUNIT()) then inElement1.name == inElement2.name;
    case (EXTENDS(), EXTENDS())
      then Absyn.pathEqual(inElement1.baseClassPath, inElement2.baseClassPath);
    case (IMPORT(), IMPORT())
      then Absyn.importEqual(inElement1.imp, inElement2.imp);
    else false;
  end match;
end elementNameEqual;

public function enumName ""
input Enum e;
output String s;
algorithm
  s := match(e)
    case(ENUM(literal = s)) then s;
  end match;
end enumName;

public function isRecord
"Return true if Class is a record."
  input Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case CLASS(restriction = R_RECORD()) then true;
    else false;
  end match;
end isRecord;

public function isOperatorRecord
"Return true if Class is a operator record."
  input Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case CLASS(restriction = R_RECORD(true)) then true;
    else false;
  end match;
end isOperatorRecord;

public function isFunction
"Return true if Class is a function."
  input Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case CLASS(restriction = R_FUNCTION()) then true;
    else false;
  end match;
end isFunction;

public function isFunctionRestriction
"Return true if restriction is a function."
  input Restriction inRestriction;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inRestriction)
    case R_FUNCTION() then true;
    else false;
  end match;
end isFunctionRestriction;

public function isFunctionOrExtFunctionRestriction
"restriction is function or external function.
  Otherwise false is returned."
  input Restriction r;
  output Boolean res;
algorithm
  res := match(r)
    case (R_FUNCTION(FR_NORMAL_FUNCTION())) then true;
    case (R_FUNCTION(FR_EXTERNAL_FUNCTION())) then true;
    else false;
  end match;
end isFunctionOrExtFunctionRestriction;

public function isOperator
"restriction is operator or operator function.
  Otherwise false is returned."
  input Element el;
  output Boolean res;
algorithm
  res := match(el)
    case (CLASS(restriction=R_OPERATOR())) then true;
    case (CLASS(restriction=R_FUNCTION(FR_OPERATOR_FUNCTION()))) then true;
    else false;
  end match;
end isOperator;

public function className
  "Returns the class name of a Class."
  input Element inClass;
  output String outName;
algorithm
  CLASS(name = outName) := inClass;
end className;

public function classSetPartial
"author: PA
  Sets the partial attribute of a Class"
  input Element inClass;
  input Partial inPartial;
  output Element outClass;
algorithm
  outClass := match (inClass,inPartial)
    local
      String id;
      Encapsulated enc;
      Partial partialPrefix;
      Restriction restr;
      ClassDef def;
      SourceInfo info;
      Prefixes prefixes;
      Comment cmt;

    case (CLASS(name = id,
                prefixes = prefixes,
                encapsulatedPrefix = enc,
                restriction = restr,
                classDef = def,
                cmt = cmt,
                info = info),partialPrefix)
      then CLASS(id,prefixes,enc,partialPrefix,restr,def,cmt,info);
  end match;
end classSetPartial;

public function elementEqual
"returns true if two elements are equal,
  i.e. for a component have the same type,
  name, and attributes, etc."
   input Element element1;
   input Element element2;
   output Boolean equal;
 algorithm
   equal := matchcontinue(element1,element2)
     local
      Ident name1,name2;
      Prefixes prefixes1, prefixes2;
      Encapsulated en1, en2;
      Partial p1,p2;
      Restriction restr1, restr2;
      Attributes attr1,attr2;
      Mod mod1,mod2;
      Absyn.TypeSpec tp1,tp2;
      Absyn.Import im1,im2;
      Absyn.Path path1,path2;
      Option<String> os1,os2;
      Option<Real> or1,or2;
      Option<Absyn.Exp> cond1, cond2;
      ClassDef cd1,cd2;

    case (CLASS(name1,prefixes1,en1,p1,restr1,cd1,_,_),CLASS(name2,prefixes2,en2,p2,restr2,cd2,_,_))
       equation
         true = stringEq(name1,name2);
         true = prefixesEqual(prefixes1,prefixes2);
         true = valueEq(en1,en2);
         true = valueEq(p1,p2);
         true = restrictionEqual(restr1,restr2);
         true = classDefEqual(cd1,cd2);
       then
         true;

    case (COMPONENT(name1,prefixes1,attr1,tp1,mod1,_,cond1,_),
          COMPONENT(name2,prefixes2,attr2,tp2,mod2,_,cond2,_))
       equation
         equality(cond1 = cond2);
         true = stringEq(name1,name2);
         true = prefixesEqual(prefixes1,prefixes2);
         true = attributesEqual(attr1,attr2);
         true = modEqual(mod1,mod2);
         true = Absyn.typeSpecEqual(tp1,tp2);
       then
         true;

     case (EXTENDS(path1,_,mod1,_,_), EXTENDS(path2,_,mod2,_,_))
       equation
         true = Absyn.pathEqual(path1,path2);
         true = modEqual(mod1,mod2);
       then
         true;

    case (IMPORT(imp = im1), IMPORT(imp = im2))
       equation
         true = Absyn.importEqual(im1,im2);
       then
         true;

     case (DEFINEUNIT(name1,_,os1,or1), DEFINEUNIT(name2,_,os2,or2))
       equation
         true = stringEq(name1,name2);
         equality(os1 = os2);
         equality(or1 = or2);
       then
         true;

     // otherwise false
     else false;
   end matchcontinue;
 end elementEqual;

// stefan
public function annotationEqual
"returns true if 2 annotations are equal"
  input Annotation annotation1;
  input Annotation annotation2;
  output Boolean equal;
protected
  Mod mod1, mod2;
algorithm
  ANNOTATION(modification = mod1) := annotation1;
  ANNOTATION(modification = mod2) := annotation2;
  equal := modEqual(mod1, mod2);
end annotationEqual;

public function restrictionEqual "Returns true if two Restriction's are equal."
  input Restriction restr1;
  input Restriction restr2;
  output Boolean equal;
algorithm
  equal := match(restr1,restr2)
    local
      FunctionRestriction funcRest1,funcRest2;

    case (R_CLASS(),R_CLASS()) then true;
    case (R_OPTIMIZATION(),R_OPTIMIZATION()) then true;
    case (R_MODEL(),R_MODEL()) then true;
    case (R_RECORD(true),R_RECORD(true)) then true; // operator record
    case (R_RECORD(false),R_RECORD(false)) then true;
    case (R_BLOCK(),R_BLOCK()) then true;
    case (R_CONNECTOR(true),R_CONNECTOR(true)) then true; // expandable connectors
    case (R_CONNECTOR(false),R_CONNECTOR(false)) then true; // non expandable connectors
    case (R_OPERATOR(),R_OPERATOR()) then true; // operator
    case (R_TYPE(),R_TYPE()) then true;
    case (R_PACKAGE(),R_PACKAGE()) then true;
    case (R_FUNCTION(funcRest1),R_FUNCTION(funcRest2)) then funcRestrictionEqual(funcRest1,funcRest2);
    case (R_ENUMERATION(),R_ENUMERATION()) then true;
    case (R_PREDEFINED_INTEGER(),R_PREDEFINED_INTEGER()) then true;
    case (R_PREDEFINED_REAL(),R_PREDEFINED_REAL()) then true;
    case (R_PREDEFINED_STRING(),R_PREDEFINED_STRING()) then true;
    case (R_PREDEFINED_BOOLEAN(),R_PREDEFINED_BOOLEAN()) then true;
    // BTH
    case (R_PREDEFINED_CLOCK(),R_PREDEFINED_CLOCK()) then true;
    case (R_PREDEFINED_ENUMERATION(),R_PREDEFINED_ENUMERATION()) then true;
    else false;
   end match;
end restrictionEqual;

public function funcRestrictionEqual
  input FunctionRestriction funcRestr1;
  input FunctionRestriction funcRestr2;
  output Boolean equal;
algorithm
  equal := match(funcRestr1,funcRestr2)
    local Boolean b1, b2;
    case (FR_NORMAL_FUNCTION(b1),FR_NORMAL_FUNCTION(b2)) then boolEq(b1, b2);
    case (FR_EXTERNAL_FUNCTION(b1),FR_EXTERNAL_FUNCTION(b2)) then boolEq(b1, b2);
    case (FR_OPERATOR_FUNCTION(),FR_OPERATOR_FUNCTION()) then true;
    case (FR_RECORD_CONSTRUCTOR(),FR_RECORD_CONSTRUCTOR()) then true;
    case (FR_PARALLEL_FUNCTION(),FR_PARALLEL_FUNCTION()) then true;
    case (FR_KERNEL_FUNCTION(),FR_KERNEL_FUNCTION()) then true;
    else false;
  end match;
end funcRestrictionEqual;

function enumEqual
  input Enum e1;
  input Enum e2;
  output Boolean isEqual;
algorithm
  isEqual := match(e1, e2)
    local
      String s1, s2;
      Boolean b1;

    case (ENUM(s1,_), ENUM(s2,_))
      equation
        b1 = stringEq(s1, s2);
        // ignore comments here.
      then b1;
  end match;
end enumEqual;

protected function classDefEqual
"Returns true if Two ClassDef's are equal"
 input ClassDef cdef1;
 input ClassDef cdef2;
 output Boolean equal;
 algorithm
   equal := match(cdef1,cdef2)
     local
       list<Element> elts1,elts2;
       list<Equation> eqns1,eqns2;
       list<Equation> ieqns1,ieqns2;
       list<AlgorithmSection> algs1,algs2;
       list<AlgorithmSection> ialgs1,ialgs2;
       list<ConstraintSection> cons1,cons2;
       Attributes attr1,attr2;
       Absyn.TypeSpec tySpec1, tySpec2;
       Absyn.Path p1, p2;
       Mod mod1,mod2;
       list<Enum> elst1,elst2;
       list<Ident> ilst1,ilst2;
       String bcName1, bcName2;
       list<Absyn.NamedArg> clsttrs1,clsttrs2;

     case(PARTS(elts1,eqns1,ieqns1,algs1,ialgs1,_,_,_),
          PARTS(elts2,eqns2,ieqns2,algs2,ialgs2,_,_,_))
       equation
         List.threadMapAllValue(elts1,elts2,elementEqual,true);
         List.threadMapAllValue(eqns1,eqns2,equationEqual,true);
         List.threadMapAllValue(ieqns1,ieqns2,equationEqual,true);
         List.threadMapAllValue(algs1,algs2,algorithmEqual,true);
         List.threadMapAllValue(ialgs1,ialgs2,algorithmEqual,true);
       then true;

     case (DERIVED(tySpec1,mod1,attr1),
           DERIVED(tySpec2,mod2,attr2))
       equation
         true = Absyn.typeSpecEqual(tySpec1, tySpec2);
         true = modEqual(mod1,mod2);
         true = attributesEqual(attr1, attr2);
       then
         true;

     case (ENUMERATION(elst1),ENUMERATION(elst2))
       equation
         List.threadMapAllValue(elst1,elst2,enumEqual,true);
       then
         true;

     case (CLASS_EXTENDS(bcName1,mod1,PARTS(elts1,eqns1,ieqns1,algs1,ialgs1,_,_,_)),
           CLASS_EXTENDS(bcName2,mod2,PARTS(elts2,eqns2,ieqns2,algs2,ialgs2,_,_,_)))
       equation
         List.threadMapAllValue(elts1,elts2,elementEqual,true);
         List.threadMapAllValue(eqns1,eqns2,equationEqual,true);
         List.threadMapAllValue(ieqns1,ieqns2,equationEqual,true);
         List.threadMapAllValue(algs1,algs2,algorithmEqual,true);
         List.threadMapAllValue(ialgs1,ialgs2,algorithmEqual,true);
         true = stringEq(bcName1,bcName2);
         true = modEqual(mod1,mod2);
       then
         true;

     case (PDER(_,ilst1),PDER(_,ilst2))
       equation
         List.threadMapAllValue(ilst1,ilst2,stringEq,true);
       then
         true;

    /* adrpo: TODO! FIXME! are these below really needed??!!
    // as far as I can tell we handle all the cases.
    case(cdef1, cdef2)
      equation
        equality(cdef1=cdef2);
      then true;

    case(cdef1, cdef2)
      equation
        failure(equality(cdef1=cdef2));
      then false;*/

    else fail();
  end match;
end classDefEqual;

protected function arraydimOptEqual
"Returns true if two Option<ArrayDim> are equal"
   input Option<Absyn.ArrayDim> adopt1;
   input Option<Absyn.ArrayDim> adopt2;
   output Boolean equal;
 algorithm
  equal := matchcontinue(adopt1,adopt2)
    local
      list<Absyn.Subscript> lst1,lst2;
      list<Boolean> blst;
    case(NONE(),NONE()) then true;
    case(SOME(lst1),SOME(lst2))
      equation
        List.threadMapAllValue(lst1,lst2,subscriptEqual,true);
      then
        true;
    // oth. false
    case(SOME(_),SOME(_)) then false;
  end matchcontinue;
end arraydimOptEqual;

protected function subscriptEqual
  "Returns true if two Absyn.Subscript are equal"
  input Absyn.Subscript sub1;
  input Absyn.Subscript sub2;
  output Boolean equal;
algorithm
  equal := match(sub1,sub2)
    local
      Absyn.Exp e1,e2;

    case(Absyn.NOSUB(),Absyn.NOSUB()) then true;
    case(Absyn.SUBSCRIPT(e1),Absyn.SUBSCRIPT(e2))
      then Absyn.expEqual(e1,e2);

  end match;
end subscriptEqual;

protected function algorithmEqual
"Returns true if two Algorithm's are equal."
  input AlgorithmSection alg1;
  input AlgorithmSection alg2;
  output Boolean equal;
algorithm
  equal := matchcontinue(alg1,alg2)
    local
      list<Statement> a1,a2;

    case(ALGORITHM(a1),ALGORITHM(a2))
      equation
        List.threadMapAllValue(a1,a2,algorithmEqual2,true);
      then
        true;

    // false otherwise!
    else false;
  end matchcontinue;
end algorithmEqual;

protected function algorithmEqual2
"Returns true if two Absyn.Algorithm are equal."
  input Statement ai1;
  input Statement ai2;
  output Boolean equal;
algorithm
  equal := matchcontinue(ai1,ai2)
    local
      Absyn.Algorithm alg1,alg2;
      Statement a1,a2;
      Absyn.ComponentRef cr1,cr2;
      Absyn.Exp e1,e2,e11,e12,e21,e22;
      Boolean b1,b2;

    case(ALG_ASSIGN(assignComponent = Absyn.CREF(cr1), value = e1),
        ALG_ASSIGN(assignComponent = Absyn.CREF(cr2), value = e2))
      equation
        b1 = Absyn.crefEqual(cr1,cr2);
        b2 = Absyn.expEqual(e1,e2);
        equal = boolAnd(b1,b2);
      then equal;
    case(ALG_ASSIGN(assignComponent = e11 as Absyn.TUPLE(_), value = e12),ALG_ASSIGN(assignComponent = e21 as Absyn.TUPLE(_), value = e22))
      equation
        b1 = Absyn.expEqual(e11,e21);
        b2 = Absyn.expEqual(e12,e22);
        equal = boolAnd(b1,b2);
      then equal;
    // base it on equality for now as the ones below are not implemented!
    case(a1, a2)
      equation
        Absyn.ALGORITHMITEM(algorithm_ = alg1) = statementToAlgorithmItem(a1);
        Absyn.ALGORITHMITEM(algorithm_ = alg2) = statementToAlgorithmItem(a2);
        // Don't compare comments and line numbers
        equality(alg1 = alg2);
      then
        true;
    // maybe replace failure/equality with these:
    //case(Absyn.ALG_IF(_,_,_,_),Absyn.ALG_IF(_,_,_,_)) then false; // TODO: ALG_IF
    //case (Absyn.ALG_FOR(_,_),Absyn.ALG_FOR(_,_)) then false; // TODO: ALG_FOR
    //case (Absyn.ALG_WHILE(_,_),Absyn.ALG_WHILE(_,_)) then false; // TODO: ALG_WHILE
    //case(Absyn.ALG_WHEN_A(_,_,_),Absyn.ALG_WHEN_A(_,_,_)) then false; //TODO: ALG_WHILE
    //case (Absyn.ALG_NORETCALL(_,_),Absyn.ALG_NORETCALL(_,_)) then false; //TODO: ALG_NORETCALL
    else false;
  end matchcontinue;
end algorithmEqual2;

public function equationEqual
"Returns true if two equations are equal."
  input Equation eqn1;
  input Equation eqn2;
  output Boolean equal;
protected
  EEquation eq1, eq2;
algorithm
  EQUATION(eEquation = eq1) := eqn1;
  EQUATION(eEquation = eq2) := eqn2;
  equal := equationEqual2(eq1, eq2);
end equationEqual;

protected function equationEqual2
"Helper function to equationEqual"
  input EEquation eq1;
  input EEquation eq2;
  output Boolean equal;
algorithm
  equal := matchcontinue(eq1,eq2)
    local
      list<list<EEquation>> tb1,tb2;
      Absyn.Exp cond1,cond2;
      list<Absyn.Exp> ifcond1,ifcond2;
      Absyn.Exp e11,e12,e21,e22,exp1,exp2,c1,c2,m1,m2,e1,e2;
      Absyn.ComponentRef cr11,cr12,cr21,cr22,cr1,cr2;
      Absyn.Ident id1,id2;
      list<EEquation> fb1,fb2,eql1,eql2,elst1,elst2;

    case (EQ_IF(condition = ifcond1, thenBranch = tb1, elseBranch = fb1),EQ_IF(condition = ifcond2, thenBranch = tb2, elseBranch = fb2))
      equation
        true = equationEqual22(tb1,tb2);
        List.threadMapAllValue(fb1,fb2,equationEqual2,true);
        List.threadMapAllValue(ifcond1,ifcond2,Absyn.expEqual,true);
      then
        true;

    case(EQ_EQUALS(expLeft = e11, expRight = e12),EQ_EQUALS(expLeft = e21, expRight = e22))
      equation
        true = Absyn.expEqual(e11,e21);
        true = Absyn.expEqual(e12,e22);
      then
        true;

    case(EQ_CONNECT(crefLeft = cr11, crefRight = cr12),EQ_CONNECT(crefLeft = cr21, crefRight = cr22))
      equation
        true = Absyn.crefEqual(cr11,cr21);
        true = Absyn.crefEqual(cr12,cr22);
      then
        true;

    case (EQ_FOR(index = id1, range = SOME(exp1), eEquationLst = eql1),EQ_FOR(index = id2, range = SOME(exp2), eEquationLst = eql2))
      equation
        List.threadMapAllValue(eql1,eql2,equationEqual2,true);
        true = Absyn.expEqual(exp1,exp2);
        true = stringEq(id1,id2);
      then
        true;

    case (EQ_FOR(index = id1, range = NONE(), eEquationLst = eql1),EQ_FOR(index = id2, range = NONE(), eEquationLst = eql2))
      equation
        List.threadMapAllValue(eql1,eql2,equationEqual2,true);
        true = stringEq(id1,id2);
      then
        true;

    case (EQ_WHEN(condition = cond1, eEquationLst = elst1),EQ_WHEN(condition = cond2, eEquationLst = elst2)) // TODO: elsewhen not checked yet.
      equation
        List.threadMapAllValue(elst1,elst2,equationEqual2,true);
        true = Absyn.expEqual(cond1,cond2);
      then
        true;

    case (EQ_ASSERT(condition = c1, message = m1),EQ_ASSERT(condition = c2, message = m2))
      equation
        true = Absyn.expEqual(c1,c2);
        true = Absyn.expEqual(m1,m2);
      then
        true;

    case (EQ_REINIT(cref = cr1, expReinit = e1),EQ_REINIT(cref = cr2, expReinit = e2))
      equation
        true = Absyn.expEqual(e1,e2);
        true = Absyn.crefEqual(cr1,cr2);
      then
        true;

    case (EQ_NORETCALL(exp = e1), EQ_NORETCALL(exp = e2))
      equation
        true = Absyn.expEqual(e1,e2);
      then
        true;

    // otherwise false
    else false;
  end matchcontinue;
end equationEqual2;

protected function equationEqual22
"Author BZ
 Helper function for equationEqual2, does compare list<list<equation>> (else ifs in ifequations.)"
  input list<list<EEquation>> inTb1;
  input list<list<EEquation>> inTb2;
  output Boolean bOut;
algorithm
  bOut := matchcontinue(inTb1,inTb2)
    local
      list<EEquation> tb_1,tb_2;
      list<list<EEquation>> tb1,tb2;

    case({},{}) then true;
    case(_,{}) then false;
    case({},_) then false;
    case(tb_1::tb1,tb_2::tb2)
      equation
        List.threadMapAllValue(tb_1,tb_2,equationEqual2,true);
        true = equationEqual22(tb1,tb2);
      then
        true;
    case(_::_,_::_) then false;

  end matchcontinue;
end equationEqual22;

public function modEqual
"Return true if two Mod:s are equal"
  input Mod mod1;
  input Mod mod2;
  output Boolean equal;
algorithm
  equal := matchcontinue(mod1,mod2)
    local
      Final f1,f2;
      Each each1,each2;
      list<SubMod> submodlst1,submodlst2;
      Absyn.Exp e1,e2;
      Element elt1,elt2;

    case (MOD(f1,each1,submodlst1,SOME(e1),_),MOD(f2,each2,submodlst2,SOME(e2),_))
      equation
        true = valueEq(f1,f2);
        true = eachEqual(each1,each2);
        true = subModsEqual(submodlst1,submodlst2);
        true = Absyn.expEqual(e1,e2);
      then
        true;

    case (MOD(f1,each1,submodlst1,NONE(),_),MOD(f2,each2,submodlst2,NONE(),_))
      equation
        true = valueEq(f1,f2);
        true = eachEqual(each1,each2);
        true = subModsEqual(submodlst1,submodlst2);
      then
        true;

    case (NOMOD(),NOMOD()) then true;

    case (REDECL(f1,each1,elt1),REDECL(f2,each2,elt2))
      equation
        true = valueEq(f1,f2);
        true = eachEqual(each1,each2);
        true = elementEqual(elt1, elt2);
      then
        true;

    else false;

  end matchcontinue;
end modEqual;

protected function subModsEqual
"Return true if two subModifier lists are equal"
  input list<SubMod>  inSubModLst1;
  input list<SubMod>  inSubModLst2;
  output Boolean equal;
algorithm
  equal := matchcontinue(inSubModLst1,inSubModLst2)
    local
      Ident id1,id2;
      Mod mod1,mod2;
      list<Subscript> ss1,ss2;
      list<SubMod>  subModLst1,subModLst2;

    case ({},{}) then true;

    case (NAMEMOD(id1,mod1)::subModLst1,NAMEMOD(id2,mod2)::subModLst2)
        equation
          true = stringEq(id1,id2);
          true = modEqual(mod1,mod2);
          true = subModsEqual(subModLst1,subModLst2);
        then
          true;

    else false;
  end matchcontinue;
end subModsEqual;

protected function subscriptsEqual
"Returns true if two subscript lists are equal"
  input list<Subscript> inSs1;
  input list<Subscript> inSs2;
  output Boolean equal;
algorithm
  equal := matchcontinue(inSs1,inSs2)
    local
      Absyn.Exp e1,e2;
      list<Subscript> ss1,ss2;

    case({},{}) then true;

    case(Absyn.NOSUB()::ss1,Absyn.NOSUB()::ss2)
      then subscriptsEqual(ss1,ss2);

    case(Absyn.SUBSCRIPT(e1)::ss1,Absyn.SUBSCRIPT(e2)::ss2)
      equation
        true = Absyn.expEqual(e1,e2);
        true = subscriptsEqual(ss1,ss2);
      then
        true;

    else false;
  end matchcontinue;
end subscriptsEqual;

public function attributesEqual
"Returns true if two Atributes are equal"
   input Attributes attr1;
   input Attributes attr2;
   output Boolean equal;
algorithm
  equal:= matchcontinue(attr1,attr2)
    local
      Parallelism prl1,prl2;
      Variability var1,var2;
      ConnectorType ct1, ct2;
      Absyn.ArrayDim ad1,ad2;
      Absyn.Direction dir1,dir2;

    case(ATTR(ad1,ct1,prl1,var1,dir1),ATTR(ad2,ct2,prl2,var2,dir2))
      equation
        true = arrayDimEqual(ad1,ad2);
        true = valueEq(ct1, ct2);
        true = parallelismEqual(prl1,prl2);
        true = variabilityEqual(var1,var2);
        true = Absyn.directionEqual(dir1,dir2);
      then
        true;

    else false;
  end matchcontinue;
end attributesEqual;

public function parallelismEqual
"Returns true if two Parallelism prefixes are equal"
  input Parallelism prl1;
  input Parallelism prl2;
  output Boolean equal;
algorithm
  equal := match(prl1,prl2)
    case(PARGLOBAL(),PARGLOBAL()) then true;
    case(PARLOCAL(),PARLOCAL()) then true;
    case(NON_PARALLEL(),NON_PARALLEL()) then true;
    else false;
  end match;
end parallelismEqual;

public function variabilityEqual
"Returns true if two Variablity prefixes are equal"
  input Variability var1;
  input Variability var2;
  output Boolean equal;
algorithm
  equal := match(var1,var2)
    case(VAR(),VAR()) then true;
    case(DISCRETE(),DISCRETE()) then true;
    case(PARAM(),PARAM()) then true;
    case(CONST(),CONST()) then true;
    else false;
  end match;
end variabilityEqual;

protected function arrayDimEqual
"Return true if two arraydims are equal"
 input Absyn.ArrayDim iad1;
 input Absyn.ArrayDim iad2;
 output Boolean equal;
 algorithm
   equal := matchcontinue(iad1,iad2)
     local
       Absyn.Exp e1,e2;
       Absyn.ArrayDim ad1,ad2;

     case({},{}) then true;

     case (Absyn.NOSUB()::ad1, Absyn.NOSUB()::ad2)
       equation
         true = arrayDimEqual(ad1,ad2);
       then
         true;

     case (Absyn.SUBSCRIPT(e1)::ad1,Absyn.SUBSCRIPT(e2)::ad2)
       equation
         true = Absyn.expEqual(e1,e2);
         true =  arrayDimEqual(ad1,ad2);
       then
         true;

     else false;
   end matchcontinue;
end arrayDimEqual;

public function setClassRestriction "Sets the restriction of a SCode Class"
  input Restriction r;
  input Element cl;
  output Element outCl;
algorithm
  outCl := matchcontinue(r, cl)
    local
      ClassDef parts;
      Partial p;
      Encapsulated e;
      Ident id;
      SourceInfo info;
      Prefixes prefixes;
      Restriction oldR;
      Comment cmt;

    // check if restrictions are equal, so you can return the same thing!
    case(_, CLASS(restriction = oldR))
      equation
        true = restrictionEqual(r, oldR);
      then cl;

    // not equal, change
    case(_, CLASS(id,prefixes,e,p,_,parts,cmt,info))
      then CLASS(id,prefixes,e,p,r,parts,cmt,info);
  end matchcontinue;
end setClassRestriction;

public function setClassName "Sets the name of a SCode Class"
  input Ident name;
  input Element cl;
  output Element outCl;
algorithm
  outCl := matchcontinue(name, cl)
    local
      ClassDef parts;
      Partial p;
      Encapsulated e;
      SourceInfo info;
      Prefixes prefixes;
      Restriction r;
      Ident id;
      Comment cmt;

    // check if restrictions are equal, so you can return the same thing!
    case(_, CLASS(name = id))
      equation
        true = stringEqual(name, id);
      then
        cl;

    // not equal, change
    case(_, CLASS(_,prefixes,e,p,r,parts,cmt,info))
      then CLASS(name,prefixes,e,p,r,parts,cmt,info);
  end matchcontinue;
end setClassName;

public function makeClassPartial
  input Element inClass;
  output Element outClass = inClass;
algorithm
  outClass := match outClass
    case CLASS(partialPrefix = NOT_PARTIAL())
      algorithm
        outClass.partialPrefix := PARTIAL();
      then
        outClass;

    else outClass;
  end match;
end makeClassPartial;

public function setClassPartialPrefix "Sets the partial prefix of a SCode Class"
  input Partial partialPrefix;
  input Element cl;
  output Element outCl;
algorithm
  outCl := matchcontinue(partialPrefix, cl)
    local
      ClassDef parts;
      Encapsulated e;
      Ident id;
      SourceInfo info;
      Restriction restriction;
      Prefixes prefixes;
      Partial oldPartialPrefix;
      Comment cmt;

    // check if partial prefix are equal, so you can return the same thing!
    case(_,CLASS(partialPrefix = oldPartialPrefix))
      equation
        true = valueEq(partialPrefix, oldPartialPrefix);
      then
        cl;

    // not the same, change
    case(_,CLASS(id,prefixes,e,_,restriction,parts,cmt,info))
      then CLASS(id,prefixes,e,partialPrefix,restriction,parts,cmt,info);
  end matchcontinue;
end setClassPartialPrefix;

public function findIteratorIndexedCrefsInEEquations
  input list<EEquation> inEqs;
  input String inIterator;
  input list<Absyn.IteratorIndexedCref> inCrefs = {};
  output list<Absyn.IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := List.fold1(inEqs, findIteratorIndexedCrefsInEEquation, inIterator,
    inCrefs);
end findIteratorIndexedCrefsInEEquations;

public function findIteratorIndexedCrefsInEEquation
  input EEquation inEq;
  input String inIterator;
  input list<Absyn.IteratorIndexedCref> inCrefs = {};
  output list<Absyn.IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := SCode.foldEEquationsExps(inEq,
    function Absyn.findIteratorIndexedCrefs(inIterator = inIterator), inCrefs);
end findIteratorIndexedCrefsInEEquation;

public function findIteratorIndexedCrefsInStatements
  input list<Statement> inStatements;
  input String inIterator;
  input list<Absyn.IteratorIndexedCref> inCrefs = {};
  output list<Absyn.IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := List.fold1(inStatements, findIteratorIndexedCrefsInStatement,
      inIterator, inCrefs);
end findIteratorIndexedCrefsInStatements;

public function findIteratorIndexedCrefsInStatement
  input Statement inStatement;
  input String inIterator;
  input list<Absyn.IteratorIndexedCref> inCrefs = {};
  output list<Absyn.IteratorIndexedCref> outCrefs;
algorithm
  outCrefs := SCode.foldStatementsExps(inStatement,
    function Absyn.findIteratorIndexedCrefs(inIterator = inIterator), inCrefs);
end findIteratorIndexedCrefsInStatement;

protected function filterComponents
  "Filters out the components from the given list of elements, as well as their names."
  input list<Element> inElements;
  output list<Element> outComponents;
  output list<String> outComponentNames;
algorithm
  (outComponents, outComponentNames) := List.map_2(inElements, filterComponents2);
end filterComponents;

protected function filterComponents2
  input Element inElement;
  output Element outComponent;
  output String outName;
algorithm
  COMPONENT(name = outName) := inElement;
  outComponent := inElement;
end filterComponents2;

public function getClassComponents
"This function returns the components from a class"
  input Element cl;
  output list<Element> compElts;
  output list<String> compNames;
algorithm
  (compElts,compNames) := match (cl)
    local
      list<Element> elts, comps;
      list<String> names;

    case (CLASS(classDef = PARTS(elementLst = elts)))
      equation
        (comps, names) = filterComponents(elts);
      then (comps,names);
    case (CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = elts))))
      equation
        (comps, names) = filterComponents(elts);
      then (comps,names);
  end match;
end getClassComponents;

public function getClassElements
"This function returns the components from a class"
  input Element cl;
  output list<Element> elts;
algorithm
  elts := match (cl)
    case (CLASS(classDef = PARTS(elementLst = elts)))
      then elts;
    case (CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = elts))))
      then elts;
    else {};
  end match;
end getClassElements;

public function makeEnumType
  "Creates an EnumType element from an enumeration literal and an optional
  comment."
  input Enum inEnum;
  input SourceInfo inInfo;
  output Element outEnumType;
protected
  String literal;
  Comment comment;
algorithm
  ENUM(literal = literal, comment = comment) := inEnum;
  NFSCodeCheck.checkValidEnumLiteral(literal, inInfo);
  outEnumType := COMPONENT(literal, defaultPrefixes, defaultConstAttr,
    Absyn.TPATH(Absyn.IDENT("EnumType"), NONE()),
    NOMOD(), comment, NONE(), inInfo);
end makeEnumType;

public function variabilityOr
  "Returns the more constant of two Variabilities
   (considers VAR() < DISCRETE() < PARAM() < CONST()),
   similarly to Types.constOr."
  input Variability inConst1;
  input Variability inConst2;
  output Variability outConst;
algorithm
  outConst := match(inConst1, inConst2)
    case (CONST(),_) then CONST();
    case (_,CONST()) then CONST();
    case (PARAM(),_) then PARAM();
    case (_,PARAM()) then PARAM();
    case (DISCRETE(),_) then DISCRETE();
    case (_,DISCRETE()) then DISCRETE();
    else VAR();
  end match;
end variabilityOr;

public function statementToAlgorithmItem
"Transforms SCode.Statement back to Absyn.AlgorithmItem. Discards the comment.
Only to be used to unparse statements again."
  input Statement stmt;
  output Absyn.AlgorithmItem algi;
algorithm
  algi := match stmt
    local
      Absyn.ComponentRef functionCall;
      Absyn.Exp assignComponent;
      Absyn.Exp boolExpr;
      Absyn.Exp value;
      String iterator;
      Option<Absyn.Exp> range;
      Absyn.FunctionArgs functionArgs;
      SourceInfo info;
      list<Absyn.Exp> conditions;
      list<list<Statement>> stmtsList;
      list<Statement> body,trueBranch,elseBranch;
      list<tuple<Absyn.Exp, list<Statement>>> branches;
      Option<Comment> comment;
      list<Absyn.AlgorithmItem> algs1,algs2;
      list<list<Absyn.AlgorithmItem>> algsLst;
      list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> abranches;

    case ALG_ASSIGN(assignComponent,value,_,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(assignComponent,value),NONE(),info);

    case ALG_IF(boolExpr,trueBranch,branches,elseBranch,_,info)
      equation
        algs1 = List.map(trueBranch,statementToAlgorithmItem);

        conditions = List.map(branches, Util.tuple21);
        stmtsList = List.map(branches, Util.tuple22);
        algsLst = List.mapList(stmtsList, statementToAlgorithmItem);
        abranches = List.threadTuple(conditions,algsLst);

        algs2 = List.map(elseBranch,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_IF(boolExpr,algs1,abranches,algs2),NONE(),info);

    case ALG_FOR(iterator,range,body,_,info)
      equation
        algs1 = List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_FOR({Absyn.ITERATOR(iterator,NONE(),range)},algs1),NONE(),info);

    case ALG_PARFOR(iterator,range,body,_,info)
      equation
        algs1 = List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_PARFOR({Absyn.ITERATOR(iterator,NONE(),range)},algs1),NONE(),info);

    case ALG_WHILE(boolExpr,body,_,info)
      equation
        algs1 = List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_WHILE(boolExpr,algs1),NONE(),info);

    case ALG_WHEN_A(branches,_,info)
      equation
        (boolExpr::conditions) = List.map(branches, Util.tuple21);
        stmtsList = List.map(branches, Util.tuple22);
        (algs1::algsLst) = List.mapList(stmtsList, statementToAlgorithmItem);
        abranches = List.threadTuple(conditions,algsLst);
      then Absyn.ALGORITHMITEM(Absyn.ALG_WHEN_A(boolExpr,algs1,abranches),NONE(),info);

    case ALG_ASSERT()
      then Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("assert", {}),
        Absyn.FUNCTIONARGS({stmt.condition, stmt.message, stmt.level}, {})), NONE(), stmt.info);

    case ALG_TERMINATE()
      then Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("terminate", {}),
        Absyn.FUNCTIONARGS({stmt.message}, {})), NONE(), stmt.info);

    case ALG_REINIT()
      then Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("reinit", {}),
        Absyn.FUNCTIONARGS({Absyn.CREF(stmt.cref), stmt.newValue}, {})), NONE(), stmt.info);

    case ALG_NORETCALL(Absyn.CALL(function_=functionCall,functionArgs=functionArgs),_,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(functionCall,functionArgs),NONE(),info);

    case ALG_RETURN(_,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_RETURN(),NONE(),info);

    case ALG_BREAK(_,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_BREAK(),NONE(),info);

    case ALG_CONTINUE(_,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_CONTINUE(),NONE(),info);

    case ALG_FAILURE(body,_,info)
      equation
        algs1 = List.map(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_FAILURE(algs1),NONE(),info);
  end match;
end statementToAlgorithmItem;

public function equationFileInfo
  input EEquation eq;
  output SourceInfo info;
algorithm
  info := match eq
    case EQ_IF(info=info) then info;
    case EQ_EQUALS(info=info) then info;
    case EQ_CONNECT(info=info) then info;
    case EQ_FOR(info=info) then info;
    case EQ_WHEN(info=info) then info;
    case EQ_ASSERT(info=info) then info;
    case EQ_TERMINATE(info=info) then info;
    case EQ_REINIT(info=info) then info;
    case EQ_NORETCALL(info=info) then info;
  end match;
end equationFileInfo;

public function emptyModOrEquality
"Checks if a Mod is empty (or only an equality binding is present)"
  input Mod mod;
  output Boolean b;
algorithm
  b := match(mod)
    case NOMOD() then true;
    case MOD(subModLst={}) then true;
    else false;
  end match;
end emptyModOrEquality;

public function isComponentWithDirection
  input Element elt;
  input Absyn.Direction dir1;
  output Boolean b;
algorithm
  b := match(elt,dir1)
    local
      Absyn.Direction dir2;

    case (COMPONENT(attributes = ATTR(direction = dir2)),_)
      then Absyn.directionEqual(dir1,dir2);

    else false;
  end match;
end isComponentWithDirection;

public function isComponent
  input Element elt;
  output Boolean b;
algorithm
  b := match(elt)
    case COMPONENT() then true;
    else false;
  end match;
end isComponent;

public function isNotComponent
  input Element elt;
  output Boolean b;
algorithm
  b := match(elt)
    case COMPONENT() then false;
    else true;
  end match;
end isNotComponent;

public function isClassOrComponent
  input Element inElement;
  output Boolean outIsClassOrComponent;
algorithm
  outIsClassOrComponent := match(inElement)
    case CLASS() then true;
    case COMPONENT() then true;
  end match;
end isClassOrComponent;

public function isClass
  input Element inElement;
  output Boolean outIsClass;
algorithm
  outIsClass := match inElement
    case CLASS() then true;
    else false;
  end match;
end isClass;

public function foldEEquations<ArgT>
  "Calls the given function on the equation and all its subequations, and
   updates the argument for each call."
  input EEquation inEquation;
  input FoldFunc inFunc;
  input ArgT inArg;
  output ArgT outArg;

  partial function FoldFunc
    input EEquation inEquation;
    input ArgT inArg;
    output ArgT outArg;
  end FoldFunc;
algorithm
  outArg := inFunc(inEquation, inArg);

  outArg := match inEquation
    local
      list<EEquation> eql;

    case EQ_IF()
      algorithm
        outArg := List.foldList1(inEquation.thenBranch, foldEEquations, inFunc, outArg);
      then
        List.fold1(inEquation.elseBranch, foldEEquations, inFunc, outArg);

    case EQ_FOR()
      then List.fold1(inEquation.eEquationLst, foldEEquations, inFunc, outArg);

    case EQ_WHEN()
      algorithm
        outArg := List.fold1(inEquation.eEquationLst, foldEEquations, inFunc, outArg);

        for branch in inEquation.elseBranches loop
          (_, eql) := branch;
          outArg := List.fold1(eql, foldEEquations, inFunc, outArg);
        end for;
      then
        outArg;

  end match;
end foldEEquations;

public function foldEEquationsExps<ArgT>
  "Calls the given function on all expressions inside the equation, and updates
   the argument for each call."
  input EEquation inEquation;
  input FoldFunc inFunc;
  input ArgT inArg;
  output ArgT outArg = inArg;

  partial function FoldFunc
    input Absyn.Exp inExp;
    input ArgT inArg;
    output ArgT outArg;
  end FoldFunc;
algorithm
  outArg := match inEquation
    local
      Absyn.Exp exp;
      list<EEquation> eql;

    case EQ_IF()
      algorithm
        outArg := List.fold(inEquation.condition, inFunc, outArg);
        outArg := List.foldList1(inEquation.thenBranch, foldEEquationsExps, inFunc, outArg);
      then
        List.fold1(inEquation.elseBranch, foldEEquationsExps, inFunc, outArg);

    case EQ_EQUALS()
      algorithm
        outArg := inFunc(inEquation.expLeft, outArg);
        outArg := inFunc(inEquation.expRight, outArg);
      then
        outArg;

    case EQ_CONNECT()
      algorithm
        outArg := inFunc(Absyn.CREF(inEquation.crefLeft), outArg);
        outArg := inFunc(Absyn.CREF(inEquation.crefRight), outArg);
      then
        outArg;

    case EQ_FOR()
      algorithm
        if isSome(inEquation.range) then
          SOME(exp) := inEquation.range;
          outArg := inFunc(exp, outArg);
        end if;
      then
        List.fold1(inEquation.eEquationLst, foldEEquationsExps, inFunc, outArg);

    case EQ_WHEN()
      algorithm
        outArg := List.fold1(inEquation.eEquationLst, foldEEquationsExps, inFunc, outArg);

        for branch in inEquation.elseBranches loop
          (exp, eql) := branch;
          outArg := inFunc(exp, outArg);
          outArg := List.fold1(eql, foldEEquationsExps, inFunc, outArg);
        end for;
      then
        outArg;

    case EQ_ASSERT()
      algorithm
        outArg := inFunc(inEquation.condition, outArg);
        outArg := inFunc(inEquation.message, outArg);
        outArg := inFunc(inEquation.level, outArg);
      then
        outArg;

    case EQ_TERMINATE()
      then inFunc(inEquation.message, outArg);

    case EQ_REINIT()
      algorithm
        outArg := inFunc(Absyn.CREF(inEquation.cref), outArg);
        outArg := inFunc(inEquation.expReinit, outArg);
      then
        outArg;

    case EQ_NORETCALL()
      then inFunc(inEquation.exp, outArg);

  end match;
end foldEEquationsExps;

public function foldStatementsExps<ArgT>
  "Calls the given function on all expressions inside the statement, and updates
   the argument for each call."
  input Statement inStatement;
  input FoldFunc inFunc;
  input ArgT inArg;
  output ArgT outArg = inArg;

  partial function FoldFunc
    input Absyn.Exp inExp;
    input ArgT inArg;
    output ArgT outArg;
  end FoldFunc;
algorithm
  outArg := match inStatement
    local
      Absyn.Exp exp;
      list<Statement> stmts;

    case ALG_ASSIGN()
      algorithm
        outArg := inFunc(inStatement.assignComponent, outArg);
        outArg := inFunc(inStatement.value, outArg);
      then
        outArg;

    case ALG_IF()
      algorithm
        outArg := inFunc(inStatement.boolExpr, outArg);
        outArg := List.fold1(inStatement.trueBranch, foldStatementsExps, inFunc, outArg);

        for branch in inStatement.elseIfBranch loop
          (exp, stmts) := branch;
          outArg := inFunc(exp, outArg);
          outArg := List.fold1(stmts, foldStatementsExps, inFunc, outArg);
        end for;
      then
        outArg;

    case ALG_FOR()
      algorithm
        if isSome(inStatement.range) then
          SOME(exp) := inStatement.range;
          outArg := inFunc(exp, outArg);
        end if;
      then
        List.fold1(inStatement.forBody, foldStatementsExps, inFunc, outArg);

    case ALG_PARFOR()
      algorithm
        if isSome(inStatement.range) then
          SOME(exp) := inStatement.range;
          outArg := inFunc(exp, outArg);
        end if;
      then
        List.fold1(inStatement.parforBody, foldStatementsExps, inFunc, outArg);

    case ALG_WHILE()
      algorithm
        outArg := inFunc(inStatement.boolExpr, outArg);
      then
        List.fold1(inStatement.whileBody, foldStatementsExps, inFunc, outArg);

    case ALG_WHEN_A()
      algorithm
        for branch in inStatement.branches loop
          (exp, stmts) := branch;
          outArg := inFunc(exp, outArg);
          outArg := List.fold1(stmts, foldStatementsExps, inFunc, outArg);
        end for;
      then
        outArg;

    case ALG_ASSERT()
      algorithm
        outArg := inFunc(inStatement.condition, outArg);
        outArg := inFunc(inStatement.message, outArg);
        outArg := inFunc(inStatement.level, outArg);
      then
        outArg;

    case ALG_TERMINATE()
      then inFunc(inStatement.message, outArg);

    case ALG_REINIT()
      algorithm
        outArg := inFunc(Absyn.CREF(inStatement.cref), outArg);
      then
        inFunc(inStatement.newValue, outArg);

    case ALG_NORETCALL()
      then inFunc(inStatement.exp, outArg);

    case ALG_FAILURE()
      then List.fold1(inStatement.stmts, foldStatementsExps, inFunc, outArg);

    case ALG_TRY()
      algorithm
        outArg := List.fold1(inStatement.body, foldStatementsExps, inFunc, outArg);
      then
        List.fold1(inStatement.elseBody, foldStatementsExps, inFunc, outArg);

    // No else case, to make this function break if a new statement is added to SCode.
    case ALG_RETURN() then outArg;
    case ALG_BREAK() then outArg;
    case ALG_CONTINUE() then outArg;
  end match;
end foldStatementsExps;

public function traverseEEquationsList
  "Traverses a list of EEquations, calling traverseEEquations on each EEquation
  in the list."
  input list<EEquation> inEEquations;
  input tuple<TraverseFunc, Argument> inTuple;
  output list<EEquation> outEEquations;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<EEquation, Argument> inTuple;
    output tuple<EEquation, Argument> outTuple;
  end TraverseFunc;
algorithm
  (outEEquations, outTuple) :=
    List.mapFold(inEEquations, traverseEEquations, inTuple);
end traverseEEquationsList;

public function traverseEEquations
  "Traverses an EEquation. For each EEquation it finds it calls the given
  function with the EEquation and an extra argument which is passed along."
  input EEquation inEEquation;
  input tuple<TraverseFunc, Argument> inTuple;
  output EEquation outEEquation;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<EEquation, Argument> inTuple;
    output tuple<EEquation, Argument> outTuple;
  end TraverseFunc;

protected
  TraverseFunc traverser;
  Argument arg;
  EEquation eq;
algorithm
  (traverser, arg) := inTuple;
  ((eq, arg)) := traverser((inEEquation, arg));
  (outEEquation, outTuple) := traverseEEquations2(eq, (traverser, arg));
end traverseEEquations;

public function traverseEEquations2
  "Helper function to traverseEEquations, does the actual traversing."
  input EEquation inEEquation;
  input tuple<TraverseFunc, Argument> inTuple;
  output EEquation outEEquation;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<EEquation, Argument> inTuple;
    output tuple<EEquation, Argument> outTuple;
  end TraverseFunc;
algorithm
  (outEEquation, outTuple) := match(inEEquation, inTuple)
    local
      tuple<TraverseFunc, Argument> tup;
      Absyn.Exp e1;
      Option<Absyn.Exp> oe1;
      list<Absyn.Exp> expl1;
      list<list<EEquation>> then_branch;
      list<EEquation> else_branch, eql;
      list<tuple<Absyn.Exp, list<EEquation>>> else_when;
      Comment comment;
      SourceInfo info;
      Ident index;

    case (EQ_IF(expl1, then_branch, else_branch, comment, info), tup)
      equation
        (then_branch, tup) = List.mapFold(then_branch,
          traverseEEquationsList, tup);
        (else_branch, tup) = traverseEEquationsList(else_branch, tup);
      then
        (EQ_IF(expl1, then_branch, else_branch, comment, info), tup);

    case (EQ_FOR(index, oe1, eql, comment, info), tup)
      equation
        (eql, tup) = traverseEEquationsList(eql, tup);
      then
        (EQ_FOR(index, oe1, eql, comment, info), tup);

    case (EQ_WHEN(e1, eql, else_when, comment, info), tup)
      equation
        (eql, tup) = traverseEEquationsList(eql, tup);
        (else_when, tup) = List.mapFold(else_when,
          traverseElseWhenEEquations, tup);
      then
        (EQ_WHEN(e1, eql, else_when, comment, info), tup);

    else (inEEquation, inTuple);
  end match;
end traverseEEquations2;

protected function traverseElseWhenEEquations
  "Traverses all EEquations in an else when branch, calling the given function
  on each EEquation."
  input tuple<Absyn.Exp, list<EEquation>> inElseWhen;
  input tuple<TraverseFunc, Argument> inTuple;
  output tuple<Absyn.Exp, list<EEquation>> outElseWhen;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<EEquation, Argument> inTuple;
    output tuple<EEquation, Argument> outTuple;
  end TraverseFunc;

protected
  Absyn.Exp exp;
  list<EEquation> eql;
algorithm
  (exp, eql) := inElseWhen;
  (eql, outTuple) := traverseEEquationsList(eql, inTuple);
  outElseWhen := (exp, eql);
end traverseElseWhenEEquations;

public function traverseEEquationListExps
  "Traverses a list of EEquations, calling the given function on each Absyn.Exp
  it encounters."
  input list<EEquation> inEEquations;
  input TraverseFunc traverser;
  input Argument inArg;
  output list<EEquation> outEEquations;
  output Argument outArg;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input Absyn.Exp inExp;
    input Argument inArg;
    output Absyn.Exp outExp;
    output Argument outArg;
  end TraverseFunc;algorithm
  (outEEquations, outArg) := List.map1Fold(inEEquations, traverseEEquationExps, traverser, inArg);
end traverseEEquationListExps;

public function traverseEEquationExps
  "Traverses an EEquation, calling the given function on each Absyn.Exp it
  encounters. This funcion is intended to be used together with
  traverseEEquations, and does NOT descend into sub-EEquations."
  input EEquation inEEquation;
  input TraverseFunc inFunc;
  input Argument inArg;
  output EEquation outEEquation;
  output Argument outArg;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input Absyn.Exp inExp;
    input Argument inArg;
    output Absyn.Exp outExp;
    output Argument outArg;
  end TraverseFunc;
algorithm
  (outEEquation, outArg) := match(inEEquation, inFunc, inArg)
    local
      TraverseFunc traverser;
      Argument arg;
      tuple<TraverseFunc, Argument> tup;
      Absyn.Exp e1, e2, e3;
      list<Absyn.Exp> expl1;
      list<list<EEquation>> then_branch;
      list<EEquation> else_branch, eql;
      list<tuple<Absyn.Exp, list<EEquation>>> else_when;
      Comment comment;
      SourceInfo info;
      Absyn.ComponentRef cr1, cr2;
      Ident index;

    case (EQ_IF(expl1, then_branch, else_branch, comment, info), traverser, arg)
      equation
        (expl1, arg) = Absyn.traverseExpList(expl1, traverser, arg);
      then
        (EQ_IF(expl1, then_branch, else_branch, comment, info), arg);

    case (EQ_EQUALS(e1, e2, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
        (e2, arg) = traverser(e2, arg);
      then
        (EQ_EQUALS(e1, e2, comment, info), arg);

    case (EQ_CONNECT(cr1, cr2, comment, info), _, _)
      equation
        (cr1, arg) = traverseComponentRefExps(cr1, inFunc, inArg);
        (cr2, arg) = traverseComponentRefExps(cr2, inFunc, arg);
      then
        (EQ_CONNECT(cr1, cr2, comment, info), arg);

    case (EQ_FOR(index, SOME(e1), eql, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (EQ_FOR(index, SOME(e1), eql, comment, info), arg);

    case (EQ_WHEN(e1, eql, else_when, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
        (else_when, arg) = List.map1Fold(else_when, traverseElseWhenExps, traverser, arg);
      then
        (EQ_WHEN(e1, eql, else_when, comment, info), arg);

    case (EQ_ASSERT(e1, e2, e3, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
        (e2, arg) = traverser(e2, arg);
        (e3, arg) = traverser(e3, arg);
      then
        (EQ_ASSERT(e1, e2, e3, comment, info), arg);

    case (EQ_TERMINATE(e1, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (EQ_TERMINATE(e1, comment, info), arg);

    case (EQ_REINIT(cr1, e1, comment, info), traverser, _)
      equation
        (cr1, arg) = traverseComponentRefExps(cr1, traverser, inArg);
        (e1, arg) = traverser(e1, arg);
      then
        (EQ_REINIT(cr1, e1, comment, info), arg);

    case (EQ_NORETCALL(e1, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (EQ_NORETCALL(e1, comment, info), arg);

    else (inEEquation, inArg);
  end match;
end traverseEEquationExps;

protected function traverseComponentRefExps
  "Traverses the subscripts of a component reference and calls the given
  function on the subscript expressions."
  input Absyn.ComponentRef inCref;
  input TraverseFunc inFunc;
  input Argument inArg;
  output Absyn.ComponentRef outCref;
  output Argument outArg;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input Absyn.Exp inExp;
    input Argument inArg;
    output Absyn.Exp outExp;
    output Argument outArg;
  end TraverseFunc;
algorithm
  (outCref, outArg) := match(inCref, inFunc, inArg)
    local
      Absyn.Ident name;
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef cr;
      Argument arg;

    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cr), _, _)
      equation
        (cr, arg) = traverseComponentRefExps(cr, inFunc, inArg);
      then
        (Absyn.crefMakeFullyQualified(cr), arg);

    case (Absyn.CREF_QUAL(name = name, subscripts = subs, componentRef = cr), _, _)
      equation
        (cr, arg) = traverseComponentRefExps(cr, inFunc, inArg);
        (subs, arg) = List.map1Fold(subs, traverseSubscriptExps, inFunc, arg);
      then
        (Absyn.CREF_QUAL(name, subs, cr), arg);

    case (Absyn.CREF_IDENT(name = name, subscripts = subs), _, _)
      equation
        (subs, arg) = List.map1Fold(subs, traverseSubscriptExps, inFunc, inArg);
      then
        (Absyn.CREF_IDENT(name, subs), arg);

    case (Absyn.WILD(), _, _) then (inCref, inArg);
  end match;
end traverseComponentRefExps;

protected function traverseSubscriptExps
  "Calls the given function on the subscript expression."
  input Absyn.Subscript inSubscript;
  input TraverseFunc inFunc;
  input Argument inArg;
  output Absyn.Subscript outSubscript;
  output Argument outArg;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input Absyn.Exp inExp;
    input Argument inArg;
    output Absyn.Exp outExp;
    output Argument outArg;
  end TraverseFunc;
algorithm
  (outSubscript, outArg) := match(inSubscript, inFunc, inArg)
    local
      Absyn.Exp sub_exp;
      TraverseFunc traverser;
      Argument arg;

    case (Absyn.SUBSCRIPT(subscript = sub_exp), traverser, arg)
      equation
        (sub_exp, arg) = traverser(sub_exp, arg);
      then
        (Absyn.SUBSCRIPT(sub_exp), arg);

    case (Absyn.NOSUB(), _, _) then (inSubscript, inArg);
  end match;
end traverseSubscriptExps;

protected function traverseElseWhenExps
  "Traverses the expressions in an else when branch, and calls the given
  function on the expressions."
  input tuple<Absyn.Exp, list<EEquation>> inElseWhen;
  input TraverseFunc traverser;
  input Argument inArg;
  output tuple<Absyn.Exp, list<EEquation>> outElseWhen;
  output Argument outArg;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input Absyn.Exp inExp;
    input Argument inArg;
    output Absyn.Exp outExp;
    output Argument outArg;
  end TraverseFunc;


protected
  Absyn.Exp exp;
  list<EEquation> eql;
algorithm
  (exp, eql) := inElseWhen;
  (exp, outArg) := traverser(exp, inArg);
  outElseWhen := (exp, eql);
end traverseElseWhenExps;

protected function traverseNamedArgExps
  "Calls the given function on the value expression associated with a named
  function argument."
  input Absyn.NamedArg inArg;
  input tuple<TraverseFunc, Argument> inTuple;
  output Absyn.NamedArg outArg;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input Absyn.Exp inExp;
    input Argument inArg;
    output Absyn.Exp outExp;
    output Argument outArg;
  end TraverseFunc;


protected
  TraverseFunc traverser;
  Argument arg;
  Absyn.Ident name;
  Absyn.Exp value;
algorithm
  (traverser, arg) := inTuple;
  Absyn.NAMEDARG(argName = name, argValue = value) := inArg;
  (value, arg) := traverser(value, arg);
  outArg := Absyn.NAMEDARG(name, value);
  outTuple := (traverser, arg);
end traverseNamedArgExps;

protected function traverseForIteratorExps
  "Calls the given function on the expression associated with a for iterator."
  input Absyn.ForIterator inIterator;
  input TraverseFunc inFunc;
  input Argument inArg;
  output Absyn.ForIterator outIterator;
  output Argument outArg;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input Absyn.Exp inExp;
    input Argument inArg;
    output Absyn.Exp outExp;
    output Argument outArg;
  end TraverseFunc;

algorithm
  (outIterator, outArg) := match(inIterator, inFunc, inArg)
    local
      TraverseFunc traverser;
      Argument arg;
      Absyn.Ident ident;
      Absyn.Exp guardExp,range;

    case (Absyn.ITERATOR(ident, NONE(), NONE()), _, arg)
      then
        (Absyn.ITERATOR(ident, NONE(), NONE()), arg);

    case (Absyn.ITERATOR(ident, NONE(), SOME(range)), traverser, arg)
      equation
        (range, arg) = traverser(range, arg);
      then
        (Absyn.ITERATOR(ident, NONE(), SOME(range)), arg);

    case (Absyn.ITERATOR(ident, SOME(guardExp), SOME(range)), traverser, arg)
      equation
        (guardExp, arg) = traverser(guardExp, arg);
        (range, arg) = traverser(range, arg);
      then
        (Absyn.ITERATOR(ident, SOME(guardExp), SOME(range)), arg);

    case (Absyn.ITERATOR(ident, SOME(guardExp), NONE()), traverser, arg)
      equation
        (guardExp, arg) = traverser(guardExp, arg);
      then
        (Absyn.ITERATOR(ident, SOME(guardExp), NONE()), arg);

  end match;
end traverseForIteratorExps;

public function traverseStatementsList
  "Calls traverseStatement on each statement in the given list."
  input list<Statement> inStatements;
  input tuple<TraverseFunc, Argument> inTuple;
  output list<Statement> outStatements;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Statement, Argument> inTuple;
    output tuple<Statement, Argument> outTuple;
  end TraverseFunc;
algorithm
  (outStatements, outTuple) :=
    List.mapFold(inStatements, traverseStatements, inTuple);
end traverseStatementsList;

public function traverseStatements
  "Traverses all statements in the given statement in a top-down approach where
  the given function is applied to each statement found, beginning with the given
  statement."
  input Statement inStatement;
  input tuple<TraverseFunc, Argument> inTuple;
  output Statement outStatement;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Statement, Argument> inTuple;
    output tuple<Statement, Argument> outTuple;
  end TraverseFunc;

protected
  TraverseFunc traverser;
  Argument arg;
  Statement stmt;
algorithm
  (traverser, arg) := inTuple;
  ((stmt, arg)) := traverser((inStatement, arg));
  (outStatement, outTuple) := traverseStatements2(stmt, (traverser, arg));
end traverseStatements;

public function traverseStatements2
  "Helper function to traverseStatements. Goes through each statement contained
  in the given statement and calls traverseStatements on them."
  input Statement inStatement;
  input tuple<TraverseFunc, Argument> inTuple;
  output Statement outStatement;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Statement, Argument> inTuple;
    output tuple<Statement, Argument> outTuple;
  end TraverseFunc;
algorithm
  (outStatement, outTuple) := match(inStatement, inTuple)
    local
      TraverseFunc traverser;
      Argument arg;
      tuple<TraverseFunc, Argument> tup;
      Absyn.Exp e;
      list<Statement> stmts1, stmts2;
      list<tuple<Absyn.Exp, list<Statement>>> branches;
      Comment comment;
      SourceInfo info;
      String iter;
      Option<Absyn.Exp> range;

    case (ALG_IF(e, stmts1, branches, stmts2, comment, info), tup)
      equation
        (stmts1, tup) = traverseStatementsList(stmts1, tup);
        (branches, tup) = List.mapFold(branches, traverseBranchStatements, tup);
        (stmts2, tup) = traverseStatementsList(stmts2, tup);
      then
        (ALG_IF(e, stmts1, branches, stmts2, comment, info), tup);

    case (ALG_FOR(iter, range, stmts1, comment, info), tup)
      equation
        (stmts1, tup) = traverseStatementsList(stmts1, tup);
      then
        (ALG_FOR(iter, range, stmts1, comment, info), tup);

    case (ALG_PARFOR(iter, range, stmts1, comment, info), tup)
      equation
        (stmts1, tup) = traverseStatementsList(stmts1, tup);
      then
        (ALG_PARFOR(iter, range, stmts1, comment, info), tup);

    case (ALG_WHILE(e, stmts1, comment, info), tup)
      equation
        (stmts1, tup) = traverseStatementsList(stmts1, tup);
      then
        (ALG_WHILE(e, stmts1, comment, info), tup);

    case (ALG_WHEN_A(branches, comment, info), tup)
      equation
        (branches, tup) = List.mapFold(branches, traverseBranchStatements, tup);
      then
        (ALG_WHEN_A(branches, comment, info), tup);

    case (ALG_FAILURE(stmts1, comment, info), tup)
      equation
        (stmts1, tup) = traverseStatementsList(stmts1, tup);
      then
        (ALG_FAILURE(stmts1, comment, info), tup);

    else (inStatement, inTuple);
  end match;
end traverseStatements2;

protected function traverseBranchStatements
  "Helper function to traverseStatements2. Calls traverseStatement each
  statement in a given branch."
  input tuple<Absyn.Exp, list<Statement>> inBranch;
  input tuple<TraverseFunc, Argument> inTuple;
  output tuple<Absyn.Exp, list<Statement>> outBranch;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Statement, Argument> inTuple;
    output tuple<Statement, Argument> outTuple;
  end TraverseFunc;

protected
  Absyn.Exp exp;
  list<Statement> stmts;
algorithm
  (exp, stmts) := inBranch;
  (stmts, outTuple) := traverseStatementsList(stmts, inTuple);
  outBranch := (exp, stmts);
end traverseBranchStatements;

public function traverseStatementListExps
  "Traverses a list of statements and calls the given function on each
  expression found."
  input list<Statement> inStatements;
  input TraverseFunc inFunc;
  input Argument inArg;
  output list<Statement> outStatements;
  output Argument outArg;


  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input Absyn.Exp inExp;
    input Argument inArgument;
    output Absyn.Exp outExp;
    output Argument outArgument;
  end TraverseFunc;
algorithm
  (outStatements, outArg) := List.map1Fold(inStatements, traverseStatementExps, inFunc, inArg);
end traverseStatementListExps;

public function traverseStatementExps
  "Applies the given function to each expression in the given statement. This
  function is intended to be used together with traverseStatements, and does NOT
  descend into sub-statements."
  input Statement inStatement;
  input TraverseFunc inFunc;
  input Argument inArg;
  output Statement outStatement;
  output Argument outArg;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input Absyn.Exp inExp;
    input Argument inArgument;
    output Absyn.Exp outExp;
    output Argument outArgument;
  end TraverseFunc;
algorithm
  (outStatement, outArg) := match(inStatement, inFunc, inArg)
    local
      TraverseFunc traverser;
      Argument arg;
      tuple<TraverseFunc, Argument> tup;
      String iterator;
      Absyn.Exp e1, e2, e3;
      list<Statement> stmts1, stmts2;
      list<tuple<Absyn.Exp, list<Statement>>> branches;
      Comment comment;
      SourceInfo info;
      Absyn.ComponentRef cref;

    case (ALG_ASSIGN(e1, e2, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
        (e2, arg) = traverser(e2, arg);
      then
        (ALG_ASSIGN(e1, e2, comment, info), arg);

    case (ALG_IF(e1, stmts1, branches, stmts2, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
        (branches, arg) = List.map1Fold(branches, traverseBranchExps, traverser, arg);
      then
        (ALG_IF(e1, stmts1, branches, stmts2, comment, info), arg);

    case (ALG_FOR(iterator, SOME(e1), stmts1, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (ALG_FOR(iterator, SOME(e1), stmts1, comment, info), arg);


    case (ALG_PARFOR(iterator, SOME(e1), stmts1, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (ALG_PARFOR(iterator, SOME(e1), stmts1, comment, info), arg);

    case (ALG_WHILE(e1, stmts1, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1, arg);
      then
        (ALG_WHILE(e1, stmts1, comment, info), arg);

    case (ALG_WHEN_A(branches, comment, info), traverser, arg)
      equation
        (branches, arg) = List.map1Fold(branches, traverseBranchExps, traverser, arg);
      then
        (ALG_WHEN_A(branches, comment, info), arg);

    case (ALG_ASSERT(), traverser, arg)
      algorithm
        (e1, arg) := traverser(inStatement.condition, arg);
        (e2, arg) := traverser(inStatement.message, arg);
        (e3, arg) := traverser(inStatement.level, arg);
      then
        (ALG_ASSERT(e1, e2, e3, inStatement.comment, inStatement.info), arg);

    case (ALG_TERMINATE(), traverser, arg)
      algorithm
        (e1, arg) := traverser(inStatement.message, arg);
      then
        (ALG_TERMINATE(e1, inStatement.comment, inStatement.info), arg);

    case (ALG_REINIT(), traverser, arg)
      algorithm
        (Absyn.CREF(cref), arg) := traverser(Absyn.CREF(inStatement.cref), arg);
        (e2, arg) := traverser(inStatement.newValue, arg);
      then
        (ALG_REINIT(cref, e2, inStatement.comment, inStatement.info), arg);

    case (ALG_NORETCALL(e1, comment, info), traverser, arg)
      equation
        (e1, arg) = traverser(e1,  arg);
      then
        (ALG_NORETCALL(e1, comment, info), arg);

    else (inStatement, inArg);
  end match;
end traverseStatementExps;

protected function traverseBranchExps
  "Calls the given function on each expression found in an if or when branch."
  input tuple<Absyn.Exp, list<Statement>> inBranch;
  input TraverseFunc traverser;
  input Argument inArg;
  output tuple<Absyn.Exp, list<Statement>> outBranch;
  output Argument outArg;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input Absyn.Exp inExp;
    input Argument inArgument;
    output Absyn.Exp outExp;
    output Argument outArgument;
  end TraverseFunc;

protected
  Argument arg;
  Absyn.Exp exp;
  list<Statement> stmts;
algorithm
  (exp, stmts) := inBranch;
  (exp, outArg) := traverser(exp, inArg);
  outBranch := (exp, stmts);
end traverseBranchExps;

public function elementIsClass
  input Element el;
  output Boolean b;
algorithm
  b := match el
    case CLASS() then true;
    else false;
  end match;
end elementIsClass;

public function elementIsPublicImport
  input Element el;
  output Boolean b;
algorithm
  b := match el
    case IMPORT(visibility=PUBLIC()) then true;
    else false;
  end match;
end elementIsPublicImport;

public function elementIsProtectedImport
  input Element el;
  output Boolean b;
algorithm
  b := match el
    case IMPORT(visibility=PROTECTED()) then true;
    else false;
  end match;
end elementIsProtectedImport;

public function getElementClass
  input Element el;
  output Element cl;
algorithm
  cl := match(el)
    case CLASS() then el;
    else fail();
  end match;
end getElementClass;

public constant list<String> knownExternalCFunctions = {"sin","cos","tan","asin","acos","atan","atan2","sinh","cosh","tanh","exp","log","log10","sqrt"};

public function isBuiltinFunction
  input Element cl;
  input list<String> inVars;
  input list<String> outVars;
  output String name;
algorithm
  name := match (cl,inVars,outVars)
    local
      String outVar1,outVar2;
      list<String> argsStr;
      list<Absyn.Exp> args;
    case (CLASS(name=name,restriction=R_FUNCTION(FR_EXTERNAL_FUNCTION()),classDef=PARTS(externalDecl=SOME(EXTERNALDECL(funcName=NONE(),lang=SOME("builtin"))))),_,_)
      then name;
    case (CLASS(restriction=R_FUNCTION(FR_EXTERNAL_FUNCTION()),classDef=PARTS(externalDecl=SOME(EXTERNALDECL(funcName=SOME(name),lang=SOME("builtin"))))),_,_)
      then name;
    case (CLASS(name=name,restriction=R_FUNCTION(FR_PARALLEL_FUNCTION()),classDef=PARTS(externalDecl=SOME(EXTERNALDECL(funcName=NONE(),lang=SOME("builtin"))))),_,_)
      then name;
    case (CLASS(restriction=R_FUNCTION(FR_PARALLEL_FUNCTION()),classDef=PARTS(externalDecl=SOME(EXTERNALDECL(funcName=SOME(name),lang=SOME("builtin"))))),_,_)
      then name;
    case (CLASS(restriction=R_FUNCTION(FR_EXTERNAL_FUNCTION()), classDef=PARTS(externalDecl=SOME(EXTERNALDECL(funcName=SOME(name),lang=SOME("C"),output_=SOME(Absyn.CREF_IDENT(outVar2,{})),args=args)))),_,{outVar1})
      equation
        true = listMember(name,knownExternalCFunctions);
        true = outVar2 == outVar1;
        argsStr = List.mapMap(args, Absyn.expCref, Absyn.crefIdent);
        equality(argsStr = inVars);
      then name;
    case (CLASS(name=name,
      restriction=R_FUNCTION(FR_EXTERNAL_FUNCTION()),
      classDef=PARTS(externalDecl=SOME(EXTERNALDECL(funcName=NONE(),lang=SOME("C"))))),_,_)
      equation
        true = listMember(name,knownExternalCFunctions);
      then name;
  end match;
end isBuiltinFunction;

public function getEEquationInfo
  "Extracts the SourceInfo from an EEquation."
  input EEquation inEEquation;
  output SourceInfo outInfo;
algorithm
  outInfo := match(inEEquation)
    local
      SourceInfo info;

    case EQ_IF(info = info) then info;
    case EQ_EQUALS(info = info) then info;
    case EQ_CONNECT(info = info) then info;
    case EQ_FOR(info = info) then info;
    case EQ_WHEN(info = info) then info;
    case EQ_ASSERT(info = info) then info;
    case EQ_TERMINATE(info = info) then info;
    case EQ_REINIT(info = info) then info;
    case EQ_NORETCALL(info = info) then info;
  end match;
end getEEquationInfo;

public function getStatementInfo
  "Extracts the SourceInfo from a Statement."
  input Statement inStatement;
  output SourceInfo outInfo;
algorithm
  outInfo := match inStatement
    case ALG_ASSIGN() then inStatement.info;
    case ALG_IF() then inStatement.info;
    case ALG_FOR() then inStatement.info;
    case ALG_PARFOR() then inStatement.info;
    case ALG_WHILE() then inStatement.info;
    case ALG_WHEN_A() then inStatement.info;
    case ALG_ASSERT() then inStatement.info;
    case ALG_TERMINATE() then inStatement.info;
    case ALG_REINIT() then inStatement.info;
    case ALG_NORETCALL() then inStatement.info;
    case ALG_RETURN() then inStatement.info;
    case ALG_BREAK() then inStatement.info;
    case ALG_FAILURE() then inStatement.info;
    case ALG_TRY() then inStatement.info;
    case ALG_CONTINUE() then inStatement.info;
    else
      equation
        Error.addInternalError("SCode.getStatementInfo failed", sourceInfo());
      then Absyn.dummyInfo;
  end match;
end getStatementInfo;

public function addElementToClass
  "Adds a given element to a class definition. Only implemented for PARTS."
  input Element inElement;
  input Element inClassDef;
  output Element outClassDef;
protected
  ClassDef cdef;
algorithm
  CLASS(classDef = cdef) := inClassDef;
  cdef := addElementToCompositeClassDef(inElement, cdef);
  outClassDef := setElementClassDefinition(cdef, inClassDef);
end addElementToClass;

public function addElementToCompositeClassDef
  "Adds a given element to a PARTS class definition."
  input Element inElement;
  input ClassDef inClassDef;
  output ClassDef outClassDef;
protected
  list<Element> el;
  list<Equation> nel, iel;
  list<AlgorithmSection> nal, ial;
  list<ConstraintSection> nco;
  Option<ExternalDecl> ed;
  list<Absyn.NamedArg> clsattrs;
algorithm
  PARTS(el, nel, iel, nal, ial, nco, clsattrs, ed) := inClassDef;
  outClassDef := PARTS(inElement :: el, nel, iel, nal, ial, nco, clsattrs, ed);
end addElementToCompositeClassDef;

public function setElementClassDefinition
  input ClassDef inClassDef;
  input Element inElement;
  output Element outElement;
protected
  Ident n;
  Prefixes pf;
  Partial pp;
  Encapsulated ep;
  Restriction r;
  SourceInfo i;
  Comment cmt;
algorithm
  CLASS(n, pf, ep, pp, r, _, cmt, i) := inElement;
  outElement := CLASS(n, pf, ep, pp, r, inClassDef, cmt, i);
end setElementClassDefinition;

public function visibilityBool
  "returns true for PUBLIC and false for PROTECTED"
  input Visibility inVisibility;
  output Boolean bVisibility;
algorithm
  bVisibility := match(inVisibility)
    case (PUBLIC()) then true;
    case (PROTECTED()) then false;
  end match;
end visibilityBool;

public function boolVisibility
  "returns for PUBLIC true and for PROTECTED false"
  input Boolean inBoolVisibility;
  output Visibility outVisibility;
algorithm
  outVisibility := match(inBoolVisibility)
    case (true) then PUBLIC();
    case (false) then PROTECTED();
  end match;
end boolVisibility;

public function visibilityEqual
  input Visibility inVisibility1;
  input Visibility inVisibility2;
  output Boolean outEqual;
algorithm
  outEqual := match(inVisibility1, inVisibility2)
    case (PUBLIC(), PUBLIC()) then true;
    case (PROTECTED(), PROTECTED()) then true;
    else false;
  end match;
end visibilityEqual;

public function eachBool
  input Each inEach;
  output Boolean bEach;
algorithm
  bEach := match(inEach)
    case (EACH()) then true;
    case (NOT_EACH()) then false;
  end match;
end eachBool;

public function boolEach
  input Boolean inBoolEach;
  output Each outEach;
algorithm
  outEach := match(inBoolEach)
    case (true) then EACH();
    case (false) then NOT_EACH();
  end match;
end boolEach;

public function prefixesRedeclare
  input Prefixes inPrefixes;
  output Redeclare outRedeclare;
algorithm
  PREFIXES(redeclarePrefix = outRedeclare) := inPrefixes;
end prefixesRedeclare;

public function prefixesSetRedeclare
  input Prefixes inPrefixes;
  input Redeclare inRedeclare;
  output Prefixes outPrefixes;
protected
  Visibility v;
  Final f;
  Absyn.InnerOuter io;
  Replaceable rp;
algorithm
  PREFIXES(v, _, f, io, rp) := inPrefixes;
  outPrefixes := PREFIXES(v, inRedeclare, f, io, rp);
end prefixesSetRedeclare;

public function prefixesSetReplaceable
  input Prefixes inPrefixes;
  input Replaceable inReplaceable;
  output Prefixes outPrefixes;
protected
  Visibility v;
  Final f;
  Absyn.InnerOuter io;
  Redeclare rd;
algorithm
  PREFIXES(v, rd, f, io, _) := inPrefixes;
  outPrefixes := PREFIXES(v, rd, f, io, inReplaceable);
end prefixesSetReplaceable;

public function redeclareBool
  input Redeclare inRedeclare;
  output Boolean bRedeclare;
algorithm
  bRedeclare := match(inRedeclare)
    case (REDECLARE()) then true;
    case (NOT_REDECLARE()) then false;
  end match;
end redeclareBool;

public function boolRedeclare
  input Boolean inBoolRedeclare;
  output Redeclare outRedeclare;
algorithm
  outRedeclare := match(inBoolRedeclare)
    case (true) then REDECLARE();
    case (false) then NOT_REDECLARE();
  end match;
end boolRedeclare;

public function replaceableBool
  input Replaceable inReplaceable;
  output Boolean bReplaceable;
algorithm
  bReplaceable := match(inReplaceable)
    case (REPLACEABLE()) then true;
    case (NOT_REPLACEABLE()) then false;
  end match;
end replaceableBool;

public function replaceableOptConstraint
  input Replaceable inReplaceable;
  output Option<ConstrainClass> outOptConstrainClass;
algorithm
  outOptConstrainClass := match(inReplaceable)
    local Option<ConstrainClass> cc;
    case (REPLACEABLE(cc)) then cc;
    case (NOT_REPLACEABLE()) then NONE();
  end match;
end replaceableOptConstraint;

public function boolReplaceable
  input Boolean inBoolReplaceable;
  input Option<ConstrainClass> inOptConstrainClass;
  output Replaceable outReplaceable;
algorithm
  outReplaceable := match(inBoolReplaceable, inOptConstrainClass)
    case (true, _) then REPLACEABLE(inOptConstrainClass);
    case (false, SOME(_))
      equation
        print("Ignoring constraint class because replaceable prefix is not present!\n");
      then NOT_REPLACEABLE();
    case (false, _) then NOT_REPLACEABLE();
  end match;
end boolReplaceable;

public function encapsulatedBool
  input Encapsulated inEncapsulated;
  output Boolean bEncapsulated;
algorithm
  bEncapsulated := match(inEncapsulated)
    case (ENCAPSULATED()) then true;
    case (NOT_ENCAPSULATED()) then false;
  end match;
end encapsulatedBool;

public function boolEncapsulated
  input Boolean inBoolEncapsulated;
  output Encapsulated outEncapsulated;
algorithm
  outEncapsulated := match(inBoolEncapsulated)
    case (true) then ENCAPSULATED();
    case (false) then NOT_ENCAPSULATED();
  end match;
end boolEncapsulated;

public function partialBool
  input Partial inPartial;
  output Boolean bPartial;
algorithm
  bPartial := match(inPartial)
    case (PARTIAL()) then true;
    case (NOT_PARTIAL()) then false;
  end match;
end partialBool;

public function boolPartial
  input Boolean inBoolPartial;
  output Partial outPartial;
algorithm
  outPartial := match(inBoolPartial)
    case (true) then PARTIAL();
    case (false) then NOT_PARTIAL();
  end match;
end boolPartial;

public function prefixesFinal
  input Prefixes inPrefixes;
  output Final outFinal;
algorithm
  PREFIXES(finalPrefix = outFinal) := inPrefixes;
end prefixesFinal;

public function finalBool
  input Final inFinal;
  output Boolean bFinal;
algorithm
  bFinal := match(inFinal)
    case (FINAL()) then true;
    case (NOT_FINAL()) then false;
  end match;
end finalBool;

public function finalEqual
  input Final inFinal1;
  input Final inFinal2;
  output Boolean bFinal;
algorithm
  bFinal := match(inFinal1,inFinal2)
    case (FINAL(),FINAL()) then true;
    case (NOT_FINAL(),NOT_FINAL()) then true;
    else false;
  end match;
end finalEqual;

public function boolFinal
  input Boolean inBoolFinal;
  output Final outFinal;
algorithm
  outFinal := match(inBoolFinal)
    case (true) then FINAL();
    case (false) then NOT_FINAL();
  end match;
end boolFinal;

public function connectorTypeEqual
  input ConnectorType inConnectorType1;
  input ConnectorType inConnectorType2;
  output Boolean outEqual;
algorithm
  outEqual := match(inConnectorType1, inConnectorType2)
    case (POTENTIAL(), POTENTIAL()) then true;
    case (FLOW(), FLOW()) then true;
    case (STREAM(), STREAM()) then true;
  end match;
end connectorTypeEqual;

public function potentialBool
  input ConnectorType inConnectorType;
  output Boolean outPotential;
algorithm
  outPotential := match(inConnectorType)
    case POTENTIAL() then true;
    else false;
  end match;
end potentialBool;

public function flowBool
  input ConnectorType inConnectorType;
  output Boolean outFlow;
algorithm
  outFlow := match(inConnectorType)
    case FLOW() then true;
    else false;
  end match;
end flowBool;

public function boolFlow
  input Boolean inBoolFlow;
  output ConnectorType outFlow;
algorithm
  outFlow := match(inBoolFlow)
    case true then FLOW();
    else POTENTIAL();
  end match;
end boolFlow;

public function streamBool
  input ConnectorType inStream;
  output Boolean bStream;
algorithm
  bStream := match(inStream)
    case STREAM() then true;
    else false;
  end match;
end streamBool;

public function boolStream
  input Boolean inBoolStream;
  output ConnectorType outStream;
algorithm
  outStream := match(inBoolStream)
    case true then STREAM();
    else POTENTIAL();
  end match;
end boolStream;

public function mergeAttributesFromClass
  input Attributes inAttributes;
  input Element inClass;
  output Attributes outAttributes;
algorithm
  outAttributes := match(inAttributes, inClass)
    local
      Attributes cls_attr, attr;

    case (_, CLASS(classDef = DERIVED(attributes = cls_attr)))
      equation
        SOME(attr) = mergeAttributes(inAttributes, SOME(cls_attr));
      then
        attr;

    else inAttributes;
  end match;
end mergeAttributesFromClass;

public function mergeAttributes
"@author: adrpo
 Function that is used with Derived classes,
 merge the derived Attributes with the optional Attributes returned from ~instClass~."
  input Attributes ele;
  input Option<Attributes> oEle;
  output Option<Attributes> outoEle;
algorithm
  outoEle := match(ele, oEle)
    local
      Parallelism p1,p2,p;
      Variability v1,v2,v;
      Absyn.Direction d1,d2,d;
      Absyn.ArrayDim ad1,ad2,ad;
      ConnectorType ct1, ct2, ct;

    case (_,NONE()) then SOME(ele);
    case(ATTR(ad1,ct1,p1,v1,d1), SOME(ATTR(_,ct2,p2,v2,d2)))
      equation
        ct = propagateConnectorType(ct1, ct2);
        p = propagateParallelism(p1,p2);
        v = propagateVariability(v1,v2);
        d = propagateDirection(d1,d2);
        ad = ad1; // TODO! CHECK if ad1 == ad2!
      then
        SOME(ATTR(ad,ct,p,v,d));
  end match;
end mergeAttributes;

public function prefixesVisibility
  input Prefixes inPrefixes;
  output Visibility outVisibility;
algorithm
  PREFIXES(visibility = outVisibility) := inPrefixes;
end prefixesVisibility;

public function prefixesSetVisibility
  input Prefixes inPrefixes;
  input Visibility inVisibility;
  output Prefixes outPrefixes;
protected
  Redeclare rd;
  Final f;
  Absyn.InnerOuter io;
  Replaceable rp;
algorithm
  PREFIXES(_, rd, f, io, rp) := inPrefixes;
  outPrefixes := PREFIXES(inVisibility, rd, f, io, rp);
end prefixesSetVisibility;

public function eachEqual "Returns true if two each attributes are equal"
  input Each each1;
  input Each each2;
  output Boolean equal;
algorithm
  equal := match(each1,each2)
    case (NOT_EACH(), NOT_EACH()) then true;
    case (EACH(), EACH()) then true;
    else false;
  end match;
end eachEqual;

public function replaceableEqual "Returns true if two replaceable attributes are equal"
  input Replaceable r1;
  input Replaceable r2;
  output Boolean equal;
algorithm
  equal := matchcontinue(r1,r2)
    local
      Absyn.Path p1, p2;
      Mod m1, m2;

    case(NOT_REPLACEABLE(),NOT_REPLACEABLE()) then true;

    case(REPLACEABLE(SOME(CONSTRAINCLASS(constrainingClass = p1, modifier = m1))),
         REPLACEABLE(SOME(CONSTRAINCLASS(constrainingClass = p2, modifier = m2))))
      equation
        true = Absyn.pathEqual(p1, p2);
        true = modEqual(m1, m2);
      then
        true;

    case(REPLACEABLE(NONE()),REPLACEABLE(NONE())) then true;

    else false;

  end matchcontinue;
end replaceableEqual;

public function prefixesEqual "Returns true if two prefixes are equal"
  input Prefixes prefixes1;
  input Prefixes prefixes2;
  output Boolean equal;
algorithm
  equal := matchcontinue(prefixes1,prefixes2)
    local
      Visibility v1,v2;
      Redeclare rd1,rd2;
      Final f1,f2;
      Absyn.InnerOuter io1,io2;
      Replaceable rpl1,rpl2;

    case(PREFIXES(v1,rd1,f1,io1,rpl1),PREFIXES(v2,rd2,f2,io2,rpl2))
      equation
        true = valueEq(v1, v2);
        true = valueEq(rd1, rd2);
        true = valueEq(f1, f2);
        true = Absyn.innerOuterEqual(io1, io2);
        true = replaceableEqual(rpl1, rpl2);
      then
        true;

    else false;

  end matchcontinue;
end prefixesEqual;

public function prefixesReplaceable "Returns the replaceable part"
  input Prefixes prefixes;
  output Replaceable repl;
algorithm
  PREFIXES(replaceablePrefix = repl) := prefixes;
end prefixesReplaceable;

public function elementPrefixes
  input Element inElement;
  output Prefixes outPrefixes;
algorithm
  outPrefixes := match(inElement)
    local
      Prefixes pf;

    case CLASS(prefixes = pf) then pf;
    case COMPONENT(prefixes = pf) then pf;
  end match;
end elementPrefixes;

public function isElementReplaceable
  input Element inElement;
  output Boolean isReplaceable;
protected
  Prefixes pf;
algorithm
  pf := elementPrefixes(inElement);
  isReplaceable := replaceableBool(prefixesReplaceable(pf));
end isElementReplaceable;

public function isElementRedeclare
  input Element inElement;
  output Boolean isRedeclare;
protected
  Prefixes pf;
algorithm
  pf := elementPrefixes(inElement);
  isRedeclare := redeclareBool(prefixesRedeclare(pf));
end isElementRedeclare;

public function prefixesInnerOuter
  input Prefixes inPrefixes;
  output Absyn.InnerOuter outInnerOuter;
algorithm
  PREFIXES(innerOuter = outInnerOuter) := inPrefixes;
end prefixesInnerOuter;

public function prefixesSetInnerOuter
  input Prefixes inPrefixes;
  input Absyn.InnerOuter inInnerOuter;
  output Prefixes outPrefixes;
protected
  Visibility v;
  Redeclare rd;
  Final f;
  Replaceable rp;
algorithm
  PREFIXES(v, rd, f, _, rp) := inPrefixes;
  outPrefixes := PREFIXES(v, rd, f, inInnerOuter, rp);
end prefixesSetInnerOuter;

public function removeAttributeDimensions
  input Attributes inAttributes;
  output Attributes outAttributes;
protected
  ConnectorType ct;
  Variability v;
  Parallelism p;
  Absyn.Direction d;
algorithm
  ATTR(_, ct, p, v, d) := inAttributes;
  outAttributes := ATTR({}, ct, p, v, d);
end removeAttributeDimensions;

public function setAttributesDirection
  input Attributes inAttributes;
  input Absyn.Direction inDirection;
  output Attributes outAttributes;
protected
  Absyn.ArrayDim ad;
  ConnectorType ct;
  Parallelism p;
  Variability v;
algorithm
  ATTR(ad, ct, p, v, _) := inAttributes;
  outAttributes := ATTR(ad, ct, p, v, inDirection);
end setAttributesDirection;

public function attrVariability
"Return the variability attribute from Attributes"
  input Attributes attr;
  output Variability var;
algorithm
  var := match (attr)
    local Variability v;
    case  ATTR(variability = v) then v;
  end match;
end attrVariability;

public function isDerivedClassDef
  input ClassDef inClassDef;
  output Boolean isDerived;
algorithm
  isDerived := match(inClassDef)
    case DERIVED() then true;
    else false;
  end match;
end isDerivedClassDef;

public function isConnector
  input Restriction inRestriction;
  output Boolean isConnector;
algorithm
  isConnector := match(inRestriction)
    case (R_CONNECTOR()) then true;
    else false;
  end match;
end isConnector;

public function removeBuiltinsFromTopScope
  input Program inProgram;
  output Program outProgram;
algorithm
  outProgram := List.filter(inProgram, isNotBuiltinClass);
end removeBuiltinsFromTopScope;

protected function isNotBuiltinClass
  input Element inClass;
algorithm
  _ := match(inClass)
    case CLASS(classDef = PARTS(externalDecl =
      SOME(EXTERNALDECL(lang = SOME("builtin"))))) then fail();
    else ();
  end match;
end isNotBuiltinClass;

public function getNamedAnnotation
  "Checks if the given annotation contains an entry with the given name with the
   value true."
  input Annotation inAnnotation;
  input String inName;
  output Absyn.Exp exp;
  output SourceInfo info;
protected
  list<SubMod> submods;
algorithm
  ANNOTATION(modification = MOD(subModLst = submods)) := inAnnotation;
  NAMEMOD(mod = MOD(info = info, binding = SOME(exp))) := List.find1(submods, hasNamedAnnotation, inName);
end getNamedAnnotation;

protected function hasNamedAnnotation
  "Checks if a submod has the same name as the given name, and if its binding
   in that case is true."
  input SubMod inSubMod;
  input String inName;
  output Boolean outIsMatch;
algorithm
  outIsMatch := match(inSubMod, inName)
    local
      String id;

    case (NAMEMOD(ident = id, mod = MOD(binding = SOME(_))), _)
      then stringEq(id, inName);

    else false;
  end match;
end hasNamedAnnotation;

public function hasBooleanNamedAnnotationInClass
  input Element inClass;
  input String namedAnnotation;
  output Boolean hasAnn;
algorithm
  hasAnn := match(inClass,namedAnnotation)
    local
      Annotation ann;
    case(CLASS(cmt=COMMENT(annotation_=SOME(ann))),_)
      then hasBooleanNamedAnnotation(ann,namedAnnotation);
    else false;
  end match;
end hasBooleanNamedAnnotationInClass;

public function optCommentHasBooleanNamedAnnotation
"check if the named annotation is present and has value true"
  input Option<Comment> comm;
  input String annotationName;
  output Boolean outB;
algorithm
  outB := match (comm,annotationName)
    local
      Annotation ann;
    case (SOME(COMMENT(annotation_=SOME(ann))),_)
      then hasBooleanNamedAnnotation(ann,annotationName);
    else false;
  end match;
end optCommentHasBooleanNamedAnnotation;

public function commentHasBooleanNamedAnnotation
"check if the named annotation is present and has value true"
  input Comment comm;
  input String annotationName;
  output Boolean outB;
algorithm
  outB := match (comm,annotationName)
    local
      Annotation ann;
    case (COMMENT(annotation_=SOME(ann)),_)
      then hasBooleanNamedAnnotation(ann,annotationName);
    else false;
  end match;
end commentHasBooleanNamedAnnotation;

public function hasBooleanNamedAnnotation
  "Checks if the given annotation contains an entry with the given name with the
   value true."
  input Annotation inAnnotation;
  input String inName;
  output Boolean outHasEntry;
protected
  list<SubMod> submods;
algorithm
  ANNOTATION(modification = MOD(subModLst = submods)) := inAnnotation;
  outHasEntry := List.exist1(submods, hasBooleanNamedAnnotation2, inName);
end hasBooleanNamedAnnotation;

protected function hasBooleanNamedAnnotation2
  "Checks if a submod has the same name as the given name, and if its binding
   in that case is true."
  input SubMod inSubMod;
  input String inName;
  output Boolean outIsMatch;
algorithm
  outIsMatch := match inSubMod
    local
      String id;

    case NAMEMOD(ident = id, mod = MOD(binding = SOME(Absyn.BOOL(value = true))))
      then stringEq(id, inName);

    else false;
  end match;
end hasBooleanNamedAnnotation2;

public function getEvaluateAnnotation
"@author: adrpo
 returns true if annotation(Evaluate = true) is present,
 otherwise false"
  input Option<Comment> inCommentOpt;
  output Boolean evalIsTrue;
algorithm
  evalIsTrue := match (inCommentOpt)
    local
      Annotation ann;
    case (SOME(COMMENT(annotation_ = SOME(ann))))
      then hasBooleanNamedAnnotation(ann, "Evaluate");
    else false;
  end match;
end getEvaluateAnnotation;

public function getInlineTypeAnnotationFromCmt
  input Comment inComment;
  output Option<Annotation> outAnnotation;
algorithm
  outAnnotation := match(inComment)
    local
      Annotation ann;

    case COMMENT(annotation_ = SOME(ann)) then getInlineTypeAnnotation(ann);
    else NONE();
  end match;
end getInlineTypeAnnotationFromCmt;

protected function getInlineTypeAnnotation
  input Annotation inAnnotation;
  output Option<Annotation> outAnnotation;
algorithm
  outAnnotation := matchcontinue(inAnnotation)
    local
      list<SubMod> submods;
      SubMod inline_mod;
      Final fp;
      Each ep;
      SourceInfo info;

    case ANNOTATION(MOD(fp, ep, submods, _, info))
      equation
        inline_mod = List.find(submods, isInlineTypeSubMod);
      then
        SOME(ANNOTATION(MOD(fp, ep, {inline_mod}, NONE(), info)));

    else NONE();
  end matchcontinue;
end getInlineTypeAnnotation;

protected function isInlineTypeSubMod
  input SubMod inSubMod;
  output Boolean outIsInlineType;
algorithm
  outIsInlineType := match(inSubMod)
    case NAMEMOD(ident = "Inline") then true;
    case NAMEMOD(ident = "LateInline") then true;
    case NAMEMOD(ident = "InlineAfterIndexReduction") then true;
  end match;
end isInlineTypeSubMod;

public function appendAnnotationToComment
  input Annotation inAnnotation;
  input Comment inComment;
  output Comment outComment;
algorithm
  outComment := match(inAnnotation, inComment)
    local
      Option<String> cmt;
      Final fp;
      Each ep;
      list<SubMod> mods1, mods2;
      Option<Absyn.Exp> b;
      SourceInfo info;

    case (_, COMMENT(NONE(), cmt))
      then COMMENT(SOME(inAnnotation), cmt);

    case (ANNOTATION(modification = MOD(subModLst = mods1)),
          COMMENT(SOME(ANNOTATION(MOD(fp, ep, mods2, b, info))), cmt))
      equation
        mods2 = listAppend(mods1, mods2);
      then
        COMMENT(SOME(ANNOTATION(MOD(fp, ep, mods2, b, info))), cmt);

  end match;
end appendAnnotationToComment;

public function getModifierInfo
  input Mod inMod;
  output SourceInfo outInfo;
algorithm
  outInfo := match(inMod)
    local
      SourceInfo info;
      Element el;

    case MOD(info = info) then info;
    case REDECL(element = el) then elementInfo(el);
    else Absyn.dummyInfo;
  end match;
end getModifierInfo;

public function getModifierBinding
  input Mod inMod;
  output Option<Absyn.Exp> outBinding;
algorithm
  outBinding := match(inMod)
    local
      Absyn.Exp binding;

    case MOD(binding = SOME(binding)) then SOME(binding);
    else NONE();
  end match;
end getModifierBinding;

public function removeComponentCondition
  input Element inElement;
  output Element outElement;
protected
  Ident name;
  Prefixes pf;
  Attributes attr;
  Absyn.TypeSpec ty;
  Mod mod;
  Comment cmt;
  SourceInfo info;
algorithm
  COMPONENT(name, pf, attr, ty, mod, cmt, _, info) := inElement;
  outElement := COMPONENT(name, pf, attr, ty, mod, cmt, NONE(), info);
end removeComponentCondition;

public function isInnerComponent
  "Returns true if the given element is an element with the inner prefix,
   otherwise false."
  input Element inElement;
  output Boolean outIsInner;
algorithm
  outIsInner := match(inElement)
    local
      Absyn.InnerOuter io;

    case COMPONENT(prefixes = PREFIXES(innerOuter = io))
      then Absyn.isInner(io);

    else false;

  end match;
end isInnerComponent;

public function makeElementProtected
  input Element inElement;
  output Element outElement;
algorithm
  outElement := match(inElement)
    local
      Ident name;
      Attributes attr;
      Absyn.TypeSpec ty;
      Mod mod;
      Comment cmt;
      Option<Absyn.Exp> cnd;
      SourceInfo info;
      Redeclare rdp;
      Final fp;
      Absyn.InnerOuter io;
      Replaceable rpp;
      Path bc;
      Option<Annotation> ann;

    case COMPONENT(prefixes = PREFIXES(visibility = PROTECTED()))
      then inElement;

    case COMPONENT(name, PREFIXES(_, rdp, fp, io, rpp), attr, ty, mod, cmt, cnd, info)
      then COMPONENT(name, PREFIXES(PROTECTED(), rdp, fp, io, rpp),
        attr, ty, mod, cmt, cnd, info);

    case EXTENDS(visibility = PROTECTED())
      then inElement;

    case EXTENDS(bc, _, mod, ann, info)
      then EXTENDS(bc, PROTECTED(), mod, ann, info);

    else inElement;

  end match;
end makeElementProtected;

public function isElementPublic
  input Element inElement;
  output Boolean outIsPublic;
algorithm
  outIsPublic := visibilityBool(prefixesVisibility(elementPrefixes(inElement)));
end isElementPublic;

public function isElementProtected
  input Element inElement;
  output Boolean outIsProtected;
algorithm
  outIsProtected := not visibilityBool(prefixesVisibility(elementPrefixes(inElement)));
end isElementProtected;

public function isElementEncapsulated
  input Element inElement;
  output Boolean outIsEncapsulated;
algorithm
  outIsEncapsulated := match(inElement)
    case CLASS(encapsulatedPrefix = ENCAPSULATED()) then true;
    else false;
  end match;
end isElementEncapsulated;

public function replaceOrAddElementInProgram
"replace the element in program at the specified path (includes the element name).
 if the element does not exist at that location then it fails.
 this function will fail if any of the path prefixes
 to the element are not found in the given program"
  input Program inProgram;
  input Element inElement;
  input Absyn.Path inClassPath;
  output Program outProgram;
algorithm
  outProgram := match(inProgram, inElement, inClassPath)
    local
      Program sp;
      Element c, e;
      Absyn.Path p;
      Absyn.Ident i;

    case (_, _, Absyn.QUALIFIED(i, p))
      equation
        e = getElementWithId(inProgram, i);
        sp = getElementsFromElement(inProgram, e);
        sp = replaceOrAddElementInProgram(sp, inElement, p);
        e = replaceElementsInElement(inProgram, e, sp);
        sp = replaceOrAddElementWithId(inProgram, e, i);
      then
        sp;

    case (_, _, Absyn.IDENT(i))
      equation
        sp = replaceOrAddElementWithId(inProgram, inElement, i);
      then
        sp;

    case (_, _, Absyn.FULLYQUALIFIED(p))
      equation
        sp = replaceOrAddElementInProgram(inProgram, inElement, p);
      then
        sp;
  end match;
end replaceOrAddElementInProgram;

public function replaceOrAddElementWithId
"replace the class in program at the specified id.
 if the class does not exist at that location then is is added"
  input Program inProgram;
  input Element inElement;
  input Ident inId;
  output Program outProgram;
algorithm
  outProgram := matchcontinue(inProgram, inElement, inId)
    local
      Program sp, rest;
      Element c, e;
      Absyn.Path p;
      Absyn.Ident i, n;

    case (CLASS(name = n)::rest, _, i)
      equation
        true = stringEq(n, i);
      then
        inElement::rest;

    case (COMPONENT(name = n)::rest, _, i)
      equation
        true = stringEq(n, i);
      then
        inElement::rest;

    case (EXTENDS(baseClassPath = p)::rest, _, i)
      equation
        true = stringEq(Absyn.pathString(p), i);
      then
        inElement::rest;

    case (e::rest, _, i)
      equation
        sp = replaceOrAddElementWithId(rest, inElement, i);
      then
        e::sp;

    // not found, add it
    case ({}, _, _)
      equation
        sp = {inElement};
      then
        sp;
  end matchcontinue;
end replaceOrAddElementWithId;

public function getElementsFromElement
  input Program inProgram;
  input Element inElement;
  output Program outProgram;
algorithm
  outProgram := match(inProgram, inElement)
    local
      Program els;
      Element e;
      Absyn.Path p;
      Absyn.Ident i;

    // a class with parts
    case (_, CLASS(classDef = PARTS(elementLst = els))) then els;
    // a class extends
    case (_, CLASS(classDef = CLASS_EXTENDS(composition = PARTS(elementLst = els)))) then els;
    // a derived class
    case (_, CLASS(classDef = DERIVED(typeSpec = Absyn.TPATH(path = p))))
      equation
        e = getElementWithPath(inProgram, p);
        els = getElementsFromElement(inProgram, e);
      then
        els;
  end match;
end getElementsFromElement;

public function replaceElementsInElement
"replaces elements in element, it will search for elements pointed by derived"
  input Program inProgram;
  input Element inElement;
  input Program inElements;
  output Element outElement;
algorithm
  outElement := matchcontinue(inProgram, inElement, inElements)
    local
      Program els;
      Element e;
      Absyn.Path p;
      Absyn.Ident i;
      Ident name "the name of the class";
      Prefixes prefixes "the common class or component prefixes";
      Encapsulated encapsulatedPrefix "the encapsulated prefix";
      Partial partialPrefix "the partial prefix";
      Restriction restriction "the restriction of the class";
      ClassDef classDef "the class specification";
      SourceInfo info "the class information";
      Comment cmt;

    // a class with parts, non derived
    case (_, CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction, classDef, cmt, info), _)
      equation
        (classDef, NONE()) = replaceElementsInClassDef(inProgram, classDef, inElements);
      then
        CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction, classDef, cmt, info);

    // a class derived
    case (_, CLASS(classDef = classDef), _)
      equation
        (classDef, SOME(e)) = replaceElementsInClassDef(inProgram, classDef, inElements);
      then
        e;

  end matchcontinue;
end replaceElementsInElement;

public function replaceElementsInClassDef
"replaces the elements in class definition.
 if derived a SOME(element) is returned,
 otherwise the modified class def and NONE()"
  input Program inProgram;
  input ClassDef inClassDef;
  input Program inElements;
  output ClassDef outClassDef;
  output Option<Element> outElementOpt;
algorithm
  (outClassDef, outElementOpt) := matchcontinue(inProgram, inClassDef, inElements)
    local
      Program els;
      Element e;
      Absyn.Path p;
      Absyn.Ident i;
      list<Element> elementLst "the list of elements";
      list<Equation> normalEquationLst "the list of equations";
      list<Equation> initialEquationLst "the list of initial equations";
      list<AlgorithmSection> normalAlgorithmLst "the list of algorithms";
      list<AlgorithmSection> initialAlgorithmLst "the list of initial algorithms";
      list<ConstraintSection> constraintLst "the list of constraints";
      list<Absyn.NamedArg> clsattrs "the list of class attributes. Currently for Optimica extensions";
      Option<ExternalDecl> externalDecl "used by external functions";
      list<Annotation> annotationLst "the list of annotations found in between class elements, equations and algorithms";
      Ident baseClassName "the name of the base class we have to extend";
      Mod modifications "the modifications that need to be applied to the base class";
      ClassDef composition;

    // a derived class
    case (_, DERIVED(typeSpec = Absyn.TPATH(path = p)), _)
      equation
        e = getElementWithPath(inProgram, p);
        e = replaceElementsInElement(inProgram, e, inElements);
      then
        (inClassDef, SOME(e));

    // a parts
    case (_,
          PARTS(
            _,
            normalEquationLst,
            initialEquationLst,
            normalAlgorithmLst,
            initialAlgorithmLst,
            constraintLst,
            clsattrs,
            externalDecl),
          _)
      then
        (PARTS(inElements,
               normalEquationLst,
               initialEquationLst,
               normalAlgorithmLst,
               initialAlgorithmLst,
               constraintLst,
               clsattrs,
               externalDecl), NONE());

    // a class extends, non derived
    case (_, CLASS_EXTENDS(baseClassName, modifications, composition), _)
      equation
        (composition, NONE()) = replaceElementsInClassDef(inProgram, composition, inElements);
      then
        (CLASS_EXTENDS(baseClassName, modifications, composition), NONE());

    // a class extends
    case (_, CLASS_EXTENDS(_, _, composition), _)
      equation
        (composition, SOME(e)) = replaceElementsInClassDef(inProgram, composition, inElements);
      then
        (inClassDef, SOME(e));
  end matchcontinue;
end replaceElementsInClassDef;

protected function getElementWithId
"returns the element from the program having the name as the id.
 if the element does not exist it fails"
  input Program inProgram;
  input String inId;
  output Element outElement;
algorithm
  outElement := matchcontinue(inProgram, inId)
    local
      Program sp, rest;
      Element c, e;
      Absyn.Path p;
      Absyn.Ident i, n;

    case ((e as CLASS(name = n))::_, i)
      equation
        true = stringEq(n, i);
      then
        e;

    case ((e as COMPONENT(name = n))::_, i)
      equation
        true = stringEq(n, i);
      then
        e;

    case ((e as EXTENDS(baseClassPath = p))::_, i)
      equation
        true = stringEq(Absyn.pathString(p), i);
      then
        e;

    case (_::rest, i)
      then getElementWithId(rest, i);

  end matchcontinue;
end getElementWithId;

public function getElementWithPath
"returns the element from the program having the name as the id.
 if the element does not exist it fails"
  input Program inProgram;
  input Absyn.Path inPath;
  output Element outElement;
algorithm
  outElement := match (inProgram, inPath)
    local
      Program sp, rest;
      Element c, e;
      Absyn.Path p;
      Absyn.Ident i, n;

    case (_, Absyn.FULLYQUALIFIED(p))
      then getElementWithPath(inProgram, p);

    case (_, Absyn.IDENT(i))
      equation
        e = getElementWithId(inProgram, i);
      then
        e;

    case (_, Absyn.QUALIFIED(i, p))
      equation
        e = getElementWithId(inProgram, i);
        sp = getElementsFromElement(inProgram, e);
        e = getElementWithPath(sp, p);
      then
        e;
  end match;
end getElementWithPath;

public function getElementName ""
  input Element e;
  output String s;
algorithm
  s := match(e)
    local Absyn.Path p;
    case (COMPONENT(name = s)) then s;
    case (CLASS(name = s)) then s;
    case (EXTENDS(baseClassPath = p)) then Absyn.pathString(p);
  end match;
end getElementName;

public function setBaseClassPath
"@auhtor: adrpo
 set the base class path in extends"
  input Element inE;
  input Absyn.Path inBcPath;
  output Element outE;
protected
  Path bc;
  Visibility v;
  Mod m;
  Option<Annotation> a;
  SourceInfo i;
algorithm
  EXTENDS(bc, v, m, a, i) := inE;
  outE := EXTENDS(inBcPath, v, m, a, i);
end setBaseClassPath;

public function getBaseClassPath
"@auhtor: adrpo
 return the base class path in extends"
  input Element inE;
  output Absyn.Path outBcPath;
protected
  Path bc;
  Visibility v;
  Mod m;
  Option<Annotation> a;
  SourceInfo i;
algorithm
  EXTENDS(baseClassPath = outBcPath) := inE;
end getBaseClassPath;

public function setComponentTypeSpec
"@auhtor: adrpo
 set the typespec path in component"
  input Element inE;
  input Absyn.TypeSpec inTypeSpec;
  output Element outE;
protected
  Ident n;
  Prefixes pr;
  Attributes atr;
  Absyn.TypeSpec ts;
  Comment cmt;
  Option<Absyn.Exp> cnd;
  Path bc;
  Visibility v;
  Mod m;
  Option<Annotation> a;
  SourceInfo i;
algorithm
  COMPONENT(n, pr, atr, ts, m, cmt, cnd, i) := inE;
  outE := COMPONENT(n, pr, atr, inTypeSpec, m, cmt, cnd, i);
end setComponentTypeSpec;

public function getComponentTypeSpec
"@auhtor: adrpo
 get the typespec path in component"
  input Element inE;
  output Absyn.TypeSpec outTypeSpec;
protected
algorithm
  COMPONENT(typeSpec = outTypeSpec) := inE;
end getComponentTypeSpec;

public function setComponentMod
"@auhtor: adrpo
 set the modification in component"
  input Element inE;
  input Mod inMod;
  output Element outE;
protected
  Ident n;
  Prefixes pr;
  Attributes atr;
  Absyn.TypeSpec ts;
  Comment cmt;
  Option<Absyn.Exp> cnd;
  Path bc;
  Visibility v;
  Mod m;
  Option<Annotation> a;
  SourceInfo i;
algorithm
  COMPONENT(n, pr, atr, ts, m, cmt, cnd, i) := inE;
  outE := COMPONENT(n, pr, atr, ts, inMod, cmt, cnd, i);
end setComponentMod;

public function getComponentMod
"@auhtor: adrpo
 get the modification in component"
  input Element inE;
  output Mod outMod;
protected
algorithm
  COMPONENT(modifications = outMod) := inE;
end getComponentMod;

public function isDerivedClass
  input Element inClass;
  output Boolean isDerived;
algorithm
  isDerived := match(inClass)
    case CLASS(classDef = DERIVED()) then true;
    else false;
  end match;
end isDerivedClass;

public function setDerivedTypeSpec
"@auhtor: adrpo
 set the base class path in extends"
  input Element inE;
  input Absyn.TypeSpec inTypeSpec;
  output Element outE;
protected
  Ident n;
  Prefixes pr;
  Attributes atr;
  Encapsulated ep;
  Partial pp;
  Restriction res;
  ClassDef cd;
  SourceInfo i;
  Absyn.TypeSpec ts;
  Option<Annotation> ann;
  Comment cmt;
  Mod m;
algorithm
  CLASS(n, pr, ep, pp, res, cd, cmt, i) := inE;
  DERIVED(ts, m, atr) := cd;
  cd := DERIVED(inTypeSpec, m, atr);
  outE := CLASS(n, pr, ep, pp, res, cd, cmt, i);
end setDerivedTypeSpec;

public function getDerivedTypeSpec
"@auhtor: adrpo
 set the base class path in extends"
  input Element inE;
  output Absyn.TypeSpec outTypeSpec;
protected
algorithm
  CLASS(classDef=DERIVED(typeSpec = outTypeSpec)) := inE;
end getDerivedTypeSpec;

public function getDerivedMod
"@auhtor: adrpo
 set the base class path in extends"
  input Element inE;
  output Mod outMod;
protected
algorithm
  CLASS(classDef=DERIVED(modifications = outMod)) := inE;
end getDerivedMod;

public function setClassPrefixes
  input Prefixes inPrefixes;
  input Element cl;
  output Element outCl;
algorithm
  outCl := match(inPrefixes, cl)
    local
      ClassDef parts;
      Encapsulated e;
      Ident id;
      SourceInfo info;
      Restriction restriction;
      Prefixes prefixes;
      Partial pp;
      Comment cmt;

    // not the same, change
    case(_,CLASS(id,_,e,pp,restriction,parts,cmt,info))
      then CLASS(id,inPrefixes,e,pp,restriction,parts,cmt,info);
  end match;
end setClassPrefixes;

public function makeEquation
  input EEquation inEEq;
  output Equation outEq;
algorithm
  outEq := EQUATION(inEEq);
end makeEquation;

public function getClassDef
  input Element inClass;
  output ClassDef outCdef;
algorithm
  outCdef := match(inClass)
    case CLASS(classDef = outCdef) then outCdef;
  end match;
end getClassDef;

public function equationsContainReinit
"@author:
 returns true if equations contains reinit"
  input list<EEquation> inEqs;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inEqs)
    local Boolean b;
    case _
      equation
        b = List.applyAndFold(inEqs, boolOr, equationContainReinit, false);
      then
        b;
  end match;
end equationsContainReinit;

public function equationContainReinit
"@author:
 returns true if equation contains reinit"
  input EEquation inEq;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inEq)
    local
      Boolean b;
      list<EEquation> eqs;
      list<list<EEquation>> eqs_lst;
      list<tuple<Absyn.Exp, list<EEquation>>> tpl_el;

    case EQ_REINIT() then true;
    case EQ_WHEN(eEquationLst = eqs, elseBranches = tpl_el)
      equation
        b = equationsContainReinit(eqs);
        eqs_lst = List.map(tpl_el, Util.tuple22);
        b = List.applyAndFold(eqs_lst, boolOr, equationsContainReinit, b);
      then
        b;

    case EQ_IF(thenBranch = eqs_lst, elseBranch = eqs)
      equation
        b = equationsContainReinit(eqs);
        b = List.applyAndFold(eqs_lst, boolOr, equationsContainReinit, b);
      then
        b;

    case EQ_FOR(eEquationLst = eqs)
      equation
        b = equationsContainReinit(eqs);
      then
        b;

    else false;

  end match;
end equationContainReinit;

public function algorithmsContainReinit
"@author:
 returns true if statements contains reinit"
  input list<Statement> inAlgs;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inAlgs)
    local Boolean b;
    case _
      equation
        b = List.applyAndFold(inAlgs, boolOr, algorithmContainReinit, false);
      then
        b;
  end match;
end algorithmsContainReinit;

public function algorithmContainReinit
"@author:
 returns true if statement contains reinit"
  input Statement inAlg;
  output Boolean hasReinit;
algorithm
  hasReinit := match(inAlg)
    local
      Boolean b, b1, b2, b3;
      list<Statement> algs, algs1, algs2;
      list<list<Statement>> algs_lst;
      list<tuple<Absyn.Exp, list<Statement>>> tpl_alg;

    case ALG_REINIT() then true;

    case ALG_WHEN_A(branches = tpl_alg)
      equation
        algs_lst = List.map(tpl_alg, Util.tuple22);
        b = List.applyAndFold(algs_lst, boolOr, algorithmsContainReinit, false);
      then
        b;

    case ALG_IF(trueBranch = algs1, elseIfBranch = tpl_alg, elseBranch = algs2)
      equation
        b1 = algorithmsContainReinit(algs1);
        algs_lst = List.map(tpl_alg, Util.tuple22);
        b2 = List.applyAndFold(algs_lst, boolOr, algorithmsContainReinit, b1);
        b3 = algorithmsContainReinit(algs2);
        b = boolOr(b1, boolOr(b2, b3));
      then
        b;

    case ALG_FOR(forBody = algs)
      equation
        b = algorithmsContainReinit(algs);
      then
        b;

    case ALG_WHILE(whileBody = algs)
      equation
        b = algorithmsContainReinit(algs);
      then
        b;

    else false;

  end match;
end algorithmContainReinit;

public function getClassPartialPrefix
  input Element inElement;
  output Partial outPartial;
algorithm
  CLASS(partialPrefix = outPartial) := inElement;
end getClassPartialPrefix;

public function getClassRestriction
  input Element inElement;
  output Restriction outRestriction;
algorithm
  CLASS(restriction = outRestriction) := inElement;
end getClassRestriction;

public function isRedeclareSubMod
  input SubMod inSubMod;
  output Boolean outIsRedeclare;
algorithm
  outIsRedeclare := match(inSubMod)
    case NAMEMOD(mod = REDECL()) then true;
    else false;
  end match;
end isRedeclareSubMod;

public function componentMod
  input Element inElement;
  output Mod outMod;
algorithm
  outMod := match(inElement)
    local
      Mod mod;

    case COMPONENT(modifications = mod) then mod;
    else NOMOD();

  end match;
end componentMod;

public function elementMod
  input Element inElement;
  output Mod outMod;
algorithm
  outMod := match(inElement)
    local
      Mod mod;

    case COMPONENT(modifications = mod) then mod;
    case CLASS(classDef = DERIVED(modifications = mod)) then mod;
    case CLASS(classDef = CLASS_EXTENDS(modifications = mod)) then mod;
    case EXTENDS(modifications = mod) then mod;

  end match;
end elementMod;

public function setElementMod
  "Sets the modifier of an element, or fails if the element is not capable of
   having a modifier."
  input Element inElement;
  input Mod inMod;
  output Element outElement;
algorithm
  outElement := match(inElement, inMod)
    local
      Ident n;
      Prefixes pf;
      Attributes attr;
      Absyn.TypeSpec ty;
      Comment cmt;
      Option<Absyn.Exp> cnd;
      SourceInfo i;
      Encapsulated ep;
      Partial pp;
      Restriction res;
      ClassDef cdef;
      Absyn.Path bc;
      Visibility vis;
      Option<Annotation> ann;

    case (COMPONENT(n, pf, attr, ty, _, cmt, cnd, i), _)
      then COMPONENT(n, pf, attr, ty, inMod, cmt, cnd, i);

    case (CLASS(n, pf, ep, pp, res, cdef, cmt, i), _)
      equation
        cdef = setClassDefMod(cdef, inMod);
      then
        CLASS(n, pf, ep, pp, res, cdef, cmt, i);

    case (EXTENDS(bc, vis, _, ann, i), _)
      then EXTENDS(bc, vis, inMod, ann, i);

  end match;
end setElementMod;

protected function setClassDefMod
  input ClassDef inClassDef;
  input Mod inMod;
  output ClassDef outClassDef;
algorithm
  outClassDef := match(inClassDef, inMod)
    local
      Ident bc;
      ClassDef cdef;
      Absyn.TypeSpec ty;
      Attributes attr;

    case (DERIVED(ty, _, attr), _) then DERIVED(ty, inMod, attr);
    case (CLASS_EXTENDS(bc, _, cdef), _) then CLASS_EXTENDS(bc, inMod, cdef);

  end match;
end setClassDefMod;

public function isBuiltinElement
  input Element inElement;
  output Boolean outIsBuiltin;
algorithm
  outIsBuiltin := match(inElement)
    local
      Annotation ann;

    case CLASS(classDef = PARTS(externalDecl =
      SOME(EXTERNALDECL(lang = SOME("builtin"))))) then true;
    case CLASS(cmt = COMMENT(annotation_ = SOME(ann)))
      then hasBooleanNamedAnnotation(ann, "__OpenModelica_builtin");
    else false;
  end match;
end isBuiltinElement;

public function partitionElements
  input list<Element> inElements;
  output list<Element> outComponents;
  output list<Element> outClasses;
  output list<Element> outExtends;
  output list<Element> outImports;
  output list<Element> outDefineUnits;
algorithm
  (outComponents, outClasses, outExtends, outImports, outDefineUnits) :=
    partitionElements2(inElements, {}, {}, {}, {}, {});
end partitionElements;

protected function partitionElements2
  input list<Element> inElements;
  input list<Element> inComponents;
  input list<Element> inClasses;
  input list<Element> inExtends;
  input list<Element> inImports;
  input list<Element> inDefineUnits;
  output list<Element> outComponents;
  output list<Element> outClasses;
  output list<Element> outExtends;
  output list<Element> outImports;
  output list<Element> outDefineUnits;
algorithm
  (outComponents, outClasses, outExtends, outImports, outDefineUnits) :=
  match(inElements, inComponents, inClasses, inExtends, inImports, inDefineUnits)
    local
      Element el;
      list<Element> rest_el, comp, cls, ext, imp, def;

    case ((el as COMPONENT()) :: rest_el, comp, cls, ext, imp, def)
      equation
        (comp, cls, ext, imp, def) =
          partitionElements2(rest_el, el :: comp, cls, ext, imp, def);
      then
        (comp, cls, ext, imp, def);

    case ((el as CLASS()) :: rest_el, comp, cls, ext, imp, def)
      equation
        (comp, cls, ext, imp, def) =
          partitionElements2(rest_el, comp, el :: cls, ext, imp, def);
      then
        (comp, cls, ext, imp, def);

    case ((el as EXTENDS()) :: rest_el, comp, cls, ext, imp, def)
      equation
        (comp, cls, ext, imp, def) =
          partitionElements2(rest_el, comp, cls, el :: ext, imp, def);
      then
        (comp, cls, ext, imp, def);

    case ((el as IMPORT()) :: rest_el, comp, cls, ext, imp, def)
      equation
        (comp, cls, ext, imp, def) =
          partitionElements2(rest_el, comp, cls, ext, el :: imp, def);
      then
        (comp, cls, ext, imp, def);

    case ((el as DEFINEUNIT()) :: rest_el, comp, cls, ext, imp, def)
      equation
        (comp, cls, ext, imp, def) =
          partitionElements2(rest_el, comp, cls, ext, imp, el :: def);
      then
        (comp, cls, ext, imp, def);

    case ({}, comp, cls, ext, imp, def)
      then (listReverse(comp), listReverse(cls), listReverse(ext),
            listReverse(imp), listReverse(def));

  end match;
end partitionElements2;

public function isExternalFunctionRestriction
  input FunctionRestriction inRestr;
  output Boolean isExternal;
algorithm
  isExternal := match(inRestr)
    case (FR_EXTERNAL_FUNCTION()) then true;
    else false;
  end match;
end isExternalFunctionRestriction;

public function isImpureFunctionRestriction
  input FunctionRestriction inRestr;
  output Boolean isExternal;
algorithm
  isExternal := match(inRestr)
    case (FR_EXTERNAL_FUNCTION(true)) then true;
    case (FR_NORMAL_FUNCTION(true)) then true;
    else false;
  end match;
end isImpureFunctionRestriction;

public function isRestrictionImpure
  input Restriction inRestr;
  input Boolean hasZeroOutputPreMSL3_2;
  output Boolean isExternal;
algorithm
  isExternal := match(inRestr,hasZeroOutputPreMSL3_2)
    case (R_FUNCTION(FR_EXTERNAL_FUNCTION(true)),_) then true;
    case (R_FUNCTION(FR_NORMAL_FUNCTION(true)),_) then true;
    case (R_FUNCTION(FR_EXTERNAL_FUNCTION(false)),false) then true;
    else false;
  end match;
end isRestrictionImpure;

public function setElementVisibility
  input Element inElement;
  input Visibility inVisibility;
  output Element outElement;
algorithm
  outElement := match(inElement, inVisibility)
    local
      Ident name;
      Prefixes prefs;
      Attributes attr;
      Absyn.TypeSpec ty;
      Mod mod;
      Comment cmt;
      Option<Absyn.Exp> cond;
      SourceInfo info;
      Encapsulated ep;
      Partial pp;
      Restriction res;
      ClassDef cdef;
      Absyn.Path bc;
      Option<Annotation> ann;
      Absyn.Import imp;
      Option<String> unit;
      Option<Real> weight;

    case (COMPONENT(name, prefs, attr, ty, mod, cmt, cond, info), _)
      equation
        prefs = prefixesSetVisibility(prefs, inVisibility);
      then
        COMPONENT(name, prefs, attr, ty, mod, cmt, cond, info);

    case (CLASS(name, prefs, ep, pp, res, cdef, cmt, info), _)
      equation
        prefs = prefixesSetVisibility(prefs, inVisibility);
      then
        CLASS(name, prefs, ep, pp, res, cdef, cmt, info);

    case (EXTENDS(bc, _, mod, ann, info), _)
      then EXTENDS(bc, inVisibility, mod, ann, info);

    case (IMPORT(imp, _, info), _)
      then IMPORT(imp, inVisibility, info);

    case (DEFINEUNIT(name, _, unit, weight), _)
      then DEFINEUNIT(name, inVisibility, unit, weight);

  end match;
end setElementVisibility;

public function isClassNamed
  "Returns true if the given element is a class with the given name, otherwise false."
  input Ident inName;
  input Element inClass;
  output Boolean outIsNamed;
algorithm
  outIsNamed := match(inName, inClass)
    local
      Ident name;

    case (_, CLASS(name = name)) then stringEq(inName, name);
    else false;
  end match;
end isClassNamed;

public function getElementComment
  "Returns the comment of an element."
  input Element inElement;
  output Option<Comment> outComment;
algorithm
  outComment := match(inElement)
    local
      Comment cmt;
      ClassDef cdef;

    case COMPONENT(comment = cmt) then SOME(cmt);
    case CLASS(cmt = cmt) then SOME(cmt);
    else NONE();

  end match;
end getElementComment;

public function stripAnnotationFromComment
  "Removes the annotation from a comment."
  input Option<Comment> inComment;
  output Option<Comment> outComment;
algorithm
  outComment := match(inComment)
    local
      Option<String> str;
      Option<Comment> cmt;

    case SOME(COMMENT(_, str)) then SOME(COMMENT(NONE(), str));
    else NONE();

  end match;
end stripAnnotationFromComment;

public function isOverloadedFunction
  input Element inElement;
  output Boolean isOverloaded;
algorithm
  isOverloaded := match(inElement)
    case CLASS(classDef = OVERLOAD()) then true;
    else false;
  end match;
end isOverloadedFunction;

public function mergeWithOriginal
"@author: adrpo
 this function merges the original declaration with the redeclared declaration, see 7.3.2 in Spec.
 - modifiers from the constraining class on derived classes are merged into the new declaration
 - modifiers from the original derived classes are merged into the new declaration
 - if the original declaration has no constraining type the derived declaration is used
 - prefixes and attributes are merged
 same with components
 TODO! how about non-short class definitions with constrained by with modifications?"
  input Element inNew;
  input Element inOld;
  output Element outNew;
algorithm
  outNew := matchcontinue(inNew, inOld)
    local
      Element n, o;
      Ident name1,name2;
      Prefixes prefixes1, prefixes2;
      Encapsulated en1, en2;
      Partial p1,p2;
      Restriction restr1, restr2;
      Attributes attr1,attr2;
      Mod mod1,mod2;
      Absyn.TypeSpec tp1,tp2;
      Absyn.Import im1,im2;
      Absyn.Path path1,path2;
      Option<String> os1,os2;
      Option<Real> or1,or2;
      Option<Absyn.Exp> cond1, cond2;
      ClassDef cd1,cd2;
      Comment cm;
      SourceInfo i;
      Mod mCCNew, mCCOld;

    // for functions return the new one!
    case (_, _)
      equation
        true = isFunction(inNew);
      then
        inNew;

    case (CLASS(name1,prefixes1,en1,p1,restr1,cd1,cm,i),CLASS(_,prefixes2,_,_,_,cd2,_,_))
      equation
        mCCNew = SCodeUtil.getConstrainedByModifiers(prefixes1);
        mCCOld = SCodeUtil.getConstrainedByModifiers(prefixes2);
        cd1 = mergeClassDef(cd1, cd2, mCCNew, mCCOld);
        prefixes1 = propagatePrefixes(prefixes2, prefixes1);
        n = CLASS(name1,prefixes1,en1,p1,restr1,cd1,cm,i);
      then
        n;

    else inNew;

  end matchcontinue;
end mergeWithOriginal;

public function mergeClassDef
"@author: adrpo
 see mergeWithOriginal"
  input ClassDef inNew;
  input ClassDef inOld;
  input Mod inCCModNew;
  input Mod inCCModOld;
  output ClassDef outNew;
algorithm
  outNew := match(inNew, inOld, inCCModNew, inCCModOld)
    local
      ClassDef n, o;
      Absyn.TypeSpec ts1, ts2;
      Mod m1, m2;
      Attributes a1, a2;

    case (DERIVED(ts1,m1,a1),
          DERIVED(_,m2,a2), _, _)
      equation
        m2 = mergeModifiers(m2, inCCModOld);
        m1 = mergeModifiers(m1, inCCModNew);
        m2 = mergeModifiers(m1, m2);
        a2 = propagateAttributes(a2, a1);
        n = DERIVED(ts1,m2,a2);
      then
        n;

  end match;
end mergeClassDef;

public function mergeModifiers
  input Mod inNewMod;
  input Mod inOldMod;
  output Mod outMod;
algorithm
  outMod := matchcontinue(inNewMod, inOldMod)
    local
      Final f1, f2;
      Each e1, e2;
      list<SubMod> sl1, sl2, sl;
      Option<Absyn.Exp> b1, b2, b;
      SourceInfo i1, i2;
      Mod m;

    case (NOMOD(), _) then inOldMod;
    case (_, NOMOD()) then inNewMod;
    case (REDECL(), _) then inNewMod;

    case (MOD(f1, e1, sl1, b1, i1),
          MOD(_, _, sl2, b2, _))
      equation
        b = mergeBindings(b1, b2);
        sl = mergeSubMods(sl1, sl2);
        m = MOD(f1, e1, sl, b, i1);
      then
        m;

    else inNewMod;

  end matchcontinue;
end mergeModifiers;

protected function mergeBindings
  input Option<Absyn.Exp> inNew;
  input Option<Absyn.Exp> inOld;
  output Option<Absyn.Exp> outBnd;
algorithm
  outBnd := match(inNew, inOld)
    case (SOME(_), _) then inNew;
    case (NONE(), _) then inOld;
  end match;
end mergeBindings;

protected function mergeSubMods
  input list<SubMod> inNew;
  input list<SubMod> inOld;
  output list<SubMod> outSubs;
algorithm
  outSubs := matchcontinue(inNew, inOld)
    local
      list<SubMod> sl, rest, old;
      SubMod s;

    case ({}, _) then inOld;

    case (s::rest, _)
      equation
        old = removeSub(s, inOld);
        sl = mergeSubMods(rest, old);
      then
        s::sl;

     else inNew;
  end matchcontinue;
end mergeSubMods;

protected function removeSub
  input SubMod inSub;
  input list<SubMod> inOld;
  output list<SubMod> outSubs;
algorithm
  outSubs := matchcontinue(inSub, inOld)
    local
      list<SubMod>  rest;
      Ident id1, id2;
      list<Subscript> idxs1, idxs2;
      SubMod s;

    case (_, {}) then {};

    case (NAMEMOD(ident = id1), NAMEMOD(ident = id2)::rest)
      equation
        true = stringEqual(id1, id2);
      then
        rest;

    case (_, s::rest)
      equation
        rest = removeSub(inSub, rest);
      then
        s::rest;
  end matchcontinue;
end removeSub;

public function mergeComponentModifiers
  input Element inNewComp;
  input Element inOldComp;
  output Element outComp;
algorithm
  outComp := match(inNewComp, inOldComp)
    local
      Ident n1,n2;
      Prefixes p1,p2;
      Attributes a1,a2;
      Absyn.TypeSpec t1,t2;
      Mod m1,m2,m;
      Comment c1,c2;
      Option<Absyn.Exp> cnd1,cnd2;
      SourceInfo i1,i2;
      Element c;

    case (COMPONENT(n1, p1, a1, t1, m1, c1, cnd1, i1),
          COMPONENT(_, _, _, _, m2, _, _, _))
      equation
        m = mergeModifiers(m1, m2);
        c = COMPONENT(n1, p1, a1, t1, m, c1, cnd1, i1);
      then
        c;

  end match;
end mergeComponentModifiers;

public function propagateAttributes
  input Attributes inOriginalAttributes;
  input Attributes inNewAttributes;
  input Boolean inNewTypeIsArray = false;
  output Attributes outNewAttributes;
protected
  Absyn.ArrayDim dims1, dims2;
  ConnectorType ct1, ct2;
  Parallelism prl1,prl2;
  Variability var1, var2;
  Absyn.Direction dir1, dir2;
algorithm
  ATTR(dims1, ct1, prl1, var1, dir1) := inOriginalAttributes;
  ATTR(dims2, ct2, prl2, var2, dir2) := inNewAttributes;

  // If the new component has an array type, don't propagate the old dimensions.
  // E.g. type Real3 = Real[3];
  //      replaceable Real x[:];
  //      comp(redeclare Real3 x) => Real[3] x
  if not inNewTypeIsArray then
    dims2 := propagateArrayDimensions(dims1, dims2);
  end if;

  ct2 := propagateConnectorType(ct1, ct2);
  prl2 := propagateParallelism(prl1,prl2);
  var2 := propagateVariability(var1, var2);
  dir2 := propagateDirection(dir1, dir2);
  outNewAttributes := ATTR(dims2, ct2, prl2, var2, dir2);
end propagateAttributes;

public function propagateArrayDimensions
  input Absyn.ArrayDim inOriginalDims;
  input Absyn.ArrayDim inNewDims;
  output Absyn.ArrayDim outNewDims;
algorithm
  outNewDims := match(inOriginalDims, inNewDims)
    case (_, {}) then inOriginalDims;
    else inNewDims;
  end match;
end propagateArrayDimensions;

public function propagateConnectorType
  input ConnectorType inOriginalConnectorType;
  input ConnectorType inNewConnectorType;
  output ConnectorType outNewConnectorType;
algorithm
  outNewConnectorType := match(inOriginalConnectorType, inNewConnectorType)
    case (_, POTENTIAL()) then inOriginalConnectorType;
    else inNewConnectorType;
  end match;
end propagateConnectorType;

public function propagateParallelism
  input Parallelism inOriginalParallelism;
  input Parallelism inNewParallelism;
  output Parallelism outNewParallelism;
algorithm
  outNewParallelism := match(inOriginalParallelism, inNewParallelism)
    case (_, NON_PARALLEL()) then inOriginalParallelism;
    else inNewParallelism;
  end match;
end propagateParallelism;

public function propagateVariability
  input Variability inOriginalVariability;
  input Variability inNewVariability;
  output Variability outNewVariability;
algorithm
  outNewVariability := match(inOriginalVariability, inNewVariability)
    case (_, VAR()) then inOriginalVariability;
    else inNewVariability;
  end match;
end propagateVariability;

public function propagateDirection
  input Absyn.Direction inOriginalDirection;
  input Absyn.Direction inNewDirection;
  output Absyn.Direction outNewDirection;
algorithm
  outNewDirection := match(inOriginalDirection, inNewDirection)
    case (_, Absyn.BIDIR()) then inOriginalDirection;
    else inNewDirection;
  end match;
end propagateDirection;

public function propagateAttributesVar
  input Element inOriginalVar;
  input Element inNewVar;
  input Boolean inNewTypeIsArray;
  output Element outNewVar;
protected
  Ident name;
  Prefixes pref1, pref2;
  Attributes attr1, attr2;
  Absyn.TypeSpec ty;
  Mod mod;
  Comment cmt;
  Option<Absyn.Exp> cond;
  SourceInfo info;
algorithm
  COMPONENT(prefixes = pref1, attributes = attr1) := inOriginalVar;
  COMPONENT(name, pref2, attr2, ty, mod, cmt, cond, info) := inNewVar;
  pref2 := propagatePrefixes(pref1, pref2);
  attr2 := propagateAttributes(attr1, attr2, inNewTypeIsArray);
  outNewVar := COMPONENT(name, pref2, attr2, ty, mod, cmt, cond, info);
end propagateAttributesVar;

public function propagateAttributesClass
  input Element inOriginalClass;
  input Element inNewClass;
  output Element outNewClass;
protected
  Ident name;
  Prefixes pref1, pref2;
  Encapsulated ep;
  Partial pp;
  Restriction res;
  ClassDef cdef;
  Comment cmt;
  SourceInfo info;
algorithm
  CLASS(prefixes = pref1) := inOriginalClass;
  CLASS(name, pref2, ep, pp, res, cdef, cmt, info) := inNewClass;
  pref2 := propagatePrefixes(pref1, pref2);
  outNewClass := CLASS(name, pref2, ep, pp, res, cdef, cmt, info);
end propagateAttributesClass;

public function propagatePrefixes
  input Prefixes inOriginalPrefixes;
  input Prefixes inNewPrefixes;
  output Prefixes outNewPrefixes;
protected
  Visibility vis1, vis2;
  Absyn.InnerOuter io1, io2;
  Redeclare rdp;
  Final fp;
  Replaceable rpp;
algorithm
  PREFIXES(visibility = vis1, innerOuter = io1) := inOriginalPrefixes;
  PREFIXES(vis2, rdp, fp, io2, rpp) := inNewPrefixes;
  io2 := propagatePrefixInnerOuter(io1, io2);
  outNewPrefixes := PREFIXES(vis2, rdp, fp, io2, rpp);
end propagatePrefixes;

public function propagatePrefixInnerOuter
  input Absyn.InnerOuter inOriginalIO;
  input Absyn.InnerOuter inIO;
  output Absyn.InnerOuter outIO;
algorithm
  outIO := match(inOriginalIO, inIO)
    case (_, Absyn.NOT_INNER_OUTER()) then inOriginalIO;
    else inIO;
  end match;
end propagatePrefixInnerOuter;

public function isPackage
"Return true if Class is a partial."
  input Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case CLASS(restriction = R_PACKAGE()) then true;
    else false;
  end match;
end isPackage;

public function isPartial
"Return true if Class is a partial."
  input Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inClass)
    case CLASS(partialPrefix = PARTIAL()) then true;
    else false;
  end match;
end isPartial;

public function isValidPackageElement
  "Return true if the given element is allowed in a package, i.e. if it's a
   constant or non-component element. Otherwise returns false."
  input Element inElement;
  output Boolean outIsValid;
algorithm
  outIsValid := match(inElement)
    case COMPONENT(attributes = ATTR(variability = CONST())) then true;
    case COMPONENT() then false;
    else true;
  end match;
end isValidPackageElement;


public function classIsExternalObject
"returns true if a Class fulfills the requirements of an external object"
  input Element cl;
  output Boolean res;
algorithm
  res := match(cl)
    local
      list<Element> els;

    case CLASS(classDef=PARTS(elementLst=els))
      then isExternalObject(els);

    else false;
  end match;
end classIsExternalObject;

public function isExternalObject
"Returns true if the element list fulfills the condition of an External Object.
An external object extends the builtinClass ExternalObject, and has two local
functions, destructor and constructor. "
  input  list<Element> els;
  output Boolean res;
algorithm
  res := matchcontinue(els)
    case _
      equation
        3 = listLength(els);
        true = hasExtendsOfExternalObject(els);
        true = hasExternalObjectDestructor(els);
        true = hasExternalObjectConstructor(els);
      then
        true;

    else false;
  end matchcontinue;
end isExternalObject;

protected function hasExtendsOfExternalObject
"returns true if element list contains 'extends ExternalObject;'"
  input list<Element> inEls;
  output Boolean res;
algorithm
  res:= match (inEls)
    local
      list<Element> els;
      Absyn.Path path;
    case {} then false;
    case EXTENDS(baseClassPath = path)::_
      guard( Absyn.pathEqual(path, Absyn.IDENT("ExternalObject")) ) then true;
    case _::els then hasExtendsOfExternalObject(els);
  end match;
end hasExtendsOfExternalObject;

protected function hasExternalObjectDestructor
"returns true if element list contains 'function destructor .. end destructor'"
  input list<Element> inEls;
  output Boolean res;
algorithm
  res:= match(inEls)
    local list<Element> els;
    case CLASS(name="destructor")::_ then true;
    case _::els then hasExternalObjectDestructor(els);
    else false;
  end match;
end hasExternalObjectDestructor;

protected function hasExternalObjectConstructor
"returns true if element list contains 'function constructor ... end constructor'"
  input list<Element> inEls;
  output Boolean res;
algorithm
  res:= match(inEls)
    local list<Element> els;
    case CLASS(name="constructor")::_ then true;
    case _::els then hasExternalObjectConstructor(els);
    else false;
  end match;
end hasExternalObjectConstructor;

public function getExternalObjectDestructor
"returns the class 'function destructor .. end destructor' from element list"
  input list<Element> inEls;
  output Element cl;
algorithm
  cl:= match(inEls)
    local list<Element> els;
    case ((cl as CLASS(name="destructor"))::_) then cl;
    case (_::els) then getExternalObjectDestructor(els);
  end match;
end getExternalObjectDestructor;

public function getExternalObjectConstructor
"returns the class 'function constructor ... end constructor' from element list"
input list<Element> inEls;
output Element cl;
algorithm
  cl:= match(inEls)
    local list<Element> els;
    case ((cl as CLASS(name="constructor"))::_) then cl;
    case (_::els) then getExternalObjectConstructor(els);
  end match;
end getExternalObjectConstructor;

public function isInstantiableClassRestriction
  input Restriction inRestriction;
  output Boolean outIsInstantiable;
algorithm
  outIsInstantiable := match(inRestriction)
    case R_CLASS() then true;
    case R_MODEL() then true;
    case R_RECORD() then true;
    case R_BLOCK() then true;
    case R_CONNECTOR() then true;
    case R_TYPE() then true;
    case R_ENUMERATION() then true;
    else false;
  end match;
end isInstantiableClassRestriction;

public function isInitial
  input Initial inInitial;
  output Boolean isIn;
algorithm
  isIn := match inInitial
    case INITIAL() then true;
    else false;
  end match;
end isInitial;

public function checkSameRestriction
"check if the restrictions are the same for redeclared classes"
  input Restriction inResNew;
  input Restriction inResOrig;
  input SourceInfo inInfoNew;
  input SourceInfo inInfoOrig;
  output Restriction outRes;
  output SourceInfo outInfo;
algorithm
  (outRes, outInfo) := match(inResNew, inResOrig, inInfoNew, inInfoOrig)
    case (_, _, _, _)
      equation
        // todo: check if the restrictions are the same for redeclared classes
      then
        (inResNew, inInfoNew);
  end match;
end checkSameRestriction;

public function setComponentName
"@auhtor: adrpo
 set the name of the component"
  input Element inE;
  input Ident inName;
  output Element outE;
protected
  Ident n;
  Prefixes pr;
  Attributes atr;
  Absyn.TypeSpec ts;
  Comment cmt;
  Option<Absyn.Exp> cnd;
  Path bc;
  Visibility v;
  Mod m;
  Option<Annotation> a;
  SourceInfo i;
algorithm
  COMPONENT(n, pr, atr, ts, m, cmt, cnd, i) := inE;
  outE := COMPONENT(inName, pr, atr, ts, m, cmt, cnd, i);
end setComponentName;

public function isArrayComponent
  input Element inElement;
  output Boolean outIsArray;
algorithm
  outIsArray := match inElement
    case COMPONENT(attributes = ATTR(arrayDims = _ :: _)) then true;
    else false;
  end match;
end isArrayComponent;

annotation(__OpenModelica_Interface="frontend");
end SCode;
