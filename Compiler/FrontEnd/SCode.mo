/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
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
  record R_RECORD end R_RECORD;
  record R_BLOCK end R_BLOCK;
  record R_CONNECTOR "a connector"
    Boolean isExpandable "is expandable?";
  end R_CONNECTOR;
  record R_OPERATOR "an operator definition"
    Boolean isFunction "is this operator a function?";
  end R_OPERATOR;
  record R_TYPE end R_TYPE;
  record R_PACKAGE end R_PACKAGE;
  record R_FUNCTION end R_FUNCTION;
  record R_EXT_FUNCTION "Added c.t. Absyn" end R_EXT_FUNCTION;
  record R_ENUMERATION end R_ENUMERATION;

  // predefined internal types
  record R_PREDEFINED_INTEGER     "predefined IntegerType" end R_PREDEFINED_INTEGER;
  record R_PREDEFINED_REAL        "predefined RealType"    end R_PREDEFINED_REAL;
  record R_PREDEFINED_STRING      "predefined StringType"  end R_PREDEFINED_STRING;
  record R_PREDEFINED_BOOLEAN     "predefined BooleanType" end R_PREDEFINED_BOOLEAN;
  record R_PREDEFINED_ENUMERATION "predefined EnumType"    end R_PREDEFINED_ENUMERATION;

  // MetaModelica extensions
  record R_METARECORD "Metamodelica extension"
    Absyn.Path name; //Name of the uniontype
    Integer index; //Index in the uniontype
  end R_METARECORD; /* added by x07simbj */

  record R_UNIONTYPE "Metamodelica extension"
  end R_UNIONTYPE; /* added by simbj */
end Restriction;

public
uniontype Mod "- Modifications"

  record MOD
    Final finalPrefix "final prefix";    
    Each  eachPrefix "each prefix";
    list<SubMod> subModLst;
    Option<tuple<Absyn.Exp,Boolean>> binding "The binding expression of a modification
    has an expression and a Boolean delayElaboration which is true if elaboration(type checking)
    should be delayed. This can for instance be used when having A a(x = a.y) where a.y can not be
    type checked -before- a is instantiated, which is the current design in instantiation process.";
  end MOD;

  record REDECL
    Final         finalPrefix "final prefix";    
    Each          eachPrefix "each prefix";    
    list<Element> elementLst  "elements";
  end REDECL;

  record NOMOD end NOMOD;

end Mod;

public
uniontype SubMod "Modifications are represented in an more structured way than in
    the `Absyn\' module.  Modifications using qualified names
    (such as in `x.y =  z\') are normalized (to `x(y = z)\').  And a
    special case when arrays are subscripted in a modification.
"
  record NAMEMOD
    Ident ident;
    Mod A "A named component" ;
  end NAMEMOD;

  record IDXMOD
    list<Subscript> subscriptLst;
    Mod an "An array element" ;
  end IDXMOD;

end SubMod;

public
type Program = list<Element> "- Programs
As in the AST, a program is simply a list of class definitions.";

public
uniontype Enum "Enum, which is a name in an enumeration and an optional Comment."
  record ENUM
    Ident           literal;
    Option<Comment> comment;
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
    Option<ExternalDecl>       externalDecl        "used by external functions";
    list<Annotation>           annotationLst       "the list of annotations found in between class elements, equations and algorithms";
    Option<Comment>            comment             "the class comment";
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
    Option<Comment> comment "the translated comment from the Absyn";
  end DERIVED;

  record ENUMERATION "an enumeration"
    list<Enum> enumLst      "if the list is empty it means :, the supertype of all enumerations";
    Option<Comment> comment "the translated comment from the Absyn";
  end ENUMERATION;

  record OVERLOAD "an overloaded function"
    list<Absyn.Path> pathLst "the path lists";
    Option<Comment> comment  "the translated comment from the Absyn";
  end OVERLOAD;

  record PDER "the partial derivative"
    Absyn.Path  functionPath     "function name" ;
    list<Ident> derivedVariables "derived variables" ;
    Option<Comment> comment      "the Absyn comment";
  end PDER;

end ClassDef;

// stefan
public
uniontype Comment

  record COMMENT
    Option<Annotation> annotation_;
    Option<String> comment;
  end COMMENT;

  record CLASS_COMMENT
    list<Annotation> annotations;
    Option<Comment> comment;
  end CLASS_COMMENT;
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
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_IF;

  record EQ_EQUALS "the equality equation"
    Absyn.Exp expLeft  "the expression on the left side of the operator";
    Absyn.Exp expRight "the expression on the right side of the operator";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_EQUALS;

  record EQ_CONNECT "the connect equation"
    Absyn.ComponentRef crefLeft  "the connector/component reference on the left side";
    Absyn.ComponentRef crefRight "the connector/component reference on the right side";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_CONNECT;

  record EQ_FOR "the for equation"
    Ident           index        "the index name";
    Absyn.Exp       range        "the range of the index";
    list<EEquation> eEquationLst "the equation list";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_FOR;

  record EQ_WHEN "the when equation"
    Absyn.Exp        condition "the when condition";
    list<EEquation>  eEquationLst "the equation list";
    list<tuple<Absyn.Exp, list<EEquation>>> elseBranches "the elsewhen expression and equation list";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_WHEN;

  record EQ_ASSERT "the assert equation"
    Absyn.Exp condition "the assert condition";
    Absyn.Exp message   "the assert message";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_ASSERT;

  record EQ_TERMINATE "the terminate equation"
    Absyn.Exp message "the terminate message";
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_TERMINATE;

  record EQ_REINIT "a reinit equation"
    Absyn.ComponentRef cref      "the variable to initialize";
    Absyn.Exp          expReinit "the new value" ;
    Option<Comment> comment;
    Absyn.Info info;
  end EQ_REINIT;

  record EQ_NORETCALL "function calls without return value"
    Absyn.ComponentRef functionName "the function nanme";
    Absyn.FunctionArgs functionArgs "the function arguments";
    Option<Comment> comment;
    Absyn.Info info;
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

public uniontype Statement "The Statement type describes one algorithm statement in an algorithm section."
  record ALG_ASSIGN
    Absyn.Exp assignComponent "assignComponent" ;
    Absyn.Exp value "value" ;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_ASSIGN;

  record ALG_IF
    Absyn.Exp boolExpr;
    list<Statement> trueBranch;
    list<tuple<Absyn.Exp, list<Statement>>> elseIfBranch;
    list<Statement> elseBranch;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_IF;

  record ALG_FOR
    Absyn.ForIterators iterators;
    list<Statement> forBody "forBody" ;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_FOR;

  record ALG_WHILE
    Absyn.Exp boolExpr "boolExpr" ;
    list<Statement> whileBody "whileBody" ;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_WHILE;

  record ALG_WHEN_A
    list<tuple<Absyn.Exp, list<Statement>>> branches;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_WHEN_A;

  record ALG_NORETCALL
    Absyn.ComponentRef functionCall "functionCall" ;
    Absyn.FunctionArgs functionArgs "functionArgs; general fcalls without return value" ;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_NORETCALL;

  record ALG_RETURN
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_RETURN;

  record ALG_BREAK
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_BREAK;

  // Part of MetaModelica extension. KS
  record ALG_TRY
    list<Statement> tryBody;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_TRY;

  record ALG_CATCH
    list<Statement> catchBody;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_CATCH;

  record ALG_THROW
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_THROW;

  record ALG_FAILURE
    list<Statement> stmts;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_FAILURE;
  //-------------------------------

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
    Option<Comment> comment;
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
uniontype Stream "the stream prefix"
  record STREAM     "a stream prefix"     end STREAM;
  record NOT_STREAM "a non stream prefix" end NOT_STREAM;
end Stream;

public
uniontype Flow "the flow prefix"
  record FLOW     "a flow prefix"     end FLOW;
  record NOT_FLOW "a non flow prefix" end NOT_FLOW;
end Flow;

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
    Absyn.Info   info                "the import information";
  end IMPORT;  
  
  record EXTENDS "the extends element"
    Path baseClassPath               "the extends path";
    Visibility visibility            "the protected/public prefix";
    Mod modifications                "the modifications applied to the base class";
    Option<Annotation> ann           "the extends annotation";
    Absyn.Info info                  "the extends info";
  end EXTENDS;

  record CLASS "a class definition"
    Ident   name                     "the name of the class";
    Prefixes prefixes                "the common class or component prefixes";
    Encapsulated encapsulatedPrefix  "the encapsulated prefix";
    Partial partialPrefix            "the partial prefix";    
    Restriction restriction          "the restriction of the class";
    ClassDef classDef                "the class specification";
    Absyn.Info info                  "the class information";
  end CLASS;
  
  record COMPONENT "a component"
    Ident name                      "the component name";
    Prefixes prefixes               "the common class or component prefixes";    
    Attributes attributes           "the component attributes";
    Absyn.TypeSpec typeSpec         "the type specification";
    Mod modifications               "the modifications to be applied to the component";
    Option<Comment> comment         "this if for extraction of comments and annotations from Absyn";
    Option<Absyn.Exp> condition     "the conditional declaration of a component";
    Absyn.Info info                 "this is for line and column numbers, also file name.";
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
    Flow   flowPrefix   "the flow prefix";
    Stream streamPrefix "the stream prefix";
    Variability variability " the variability: parameter, discrete, variable, constant" ;
    Absyn.Direction direction "the direction: input, output or bidirectional" ;
  end ATTR;
end Attributes;

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

public constant Attributes defaultConstAttr =
  ATTR({}, NOT_FLOW(), NOT_STREAM(), CONST(), Absyn.BIDIR());

// .......... functionality .........
protected import Util;
protected import Dump;
protected import ModUtil;
protected import Print;
protected import Error;
protected import SCodeCheck;
protected import SCodeDump;


public function stripSubmod
"function: stripSubmod
  author: PA
  Removes all submodifiers from the Mod."
  input Mod inMod;
  output Mod outMod;
algorithm
  outMod := matchcontinue (inMod)
    local
      Final f;
      Each each_;
      list<SubMod> subs;
      Option<tuple<Absyn.Exp,Boolean>> e;
      Mod m;
    case (MOD(finalPrefix = f,eachPrefix = each_,subModLst = subs,binding = e)) then MOD(f,each_,{},e);
    case (m) then m;
  end matchcontinue;
end stripSubmod;

public function getElementNamed
"function: getElementNamed
  Return the Element with the name given as first argument from the Class."
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

protected function getElementNamedFromElts
"function: getElementNamedFromElts
  Helper function to getElementNamed."
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
    
    case (id2,(EXTENDS(baseClassPath = _) :: xs))
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
algorithm isExtend := matchcontinue(ele)
  case(EXTENDS(baseClassPath = _)) then true;
  case(_) then false;
end matchcontinue;
end isElementExtends;

public function isNotElementClassExtends "
check if an element is not of type CLASS_EXTENDS."
  input Element ele;
  output Boolean isExtend;
algorithm
  isExtend := matchcontinue(ele)
    case(CLASS(classDef = CLASS_EXTENDS(baseClassName = _))) then false;
    case(_) then true;
  end matchcontinue;
end isNotElementClassExtends;

public function isParameterOrConst
"function: isParameterOrConst
  Returns true if Variability indicates a parameter or constant."
  input Variability inVariability;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVariability)
    case (VAR()) then false;
    case (DISCRETE()) then false;
    case (PARAM()) then true;
    case (CONST()) then true;
  end match;
end isParameterOrConst;

public function isConstant
"function: isConstant
  Returns true if Variability is constant, otherwise false"
  input Variability inVariability;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVariability)
    case (VAR()) then false;
    case (DISCRETE()) then false;
    case (PARAM()) then false;
   case (CONST()) then true;
  end match;
end isConstant;

public function countParts
"function: countParts
  Counts the number of ClassParts of a Class."
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
    
    case _ then 0;
    
  end matchcontinue;
end countParts;

public function componentNames
"function: componentNames
  Return a string list of all component names of a class."
  input Element inClass;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inClass)
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
    
    case (_) then {};
    
  end matchcontinue;
end componentNames;

public function elementInfo "retrieves the element info"
  input Element e;
  output Absyn.Info info;
algorithm
  info := match(e)
    local
      Absyn.Info i;
    
    case(IMPORT(info = i)) then i;
    case(EXTENDS(info = i)) then i;
    case(CLASS(info = i)) then i;
    case(COMPONENT(info = i)) then i;
    case(DEFINEUNIT(name = _)) then fail();    
    
  end match;
end elementInfo;

public function elementName ""
  input Element e;
  output String s;
algorithm
  s := match(e)
    case(COMPONENT(name = s)) then s;
    case(CLASS(name = s)) then s;
  end match;
end elementName;

public function enumName ""
input Enum e;
output String s;
algorithm
  s := match(e)
    case(ENUM(literal = s)) then s;
  end match;
end enumName;

public function componentNamesFromElts
"function: componentNamesFromElts
  Helper function to componentNames."
  input list<Element> inElementLst;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inElementLst)
    local list<String> res; String id; list<Element> rest;
    case ({}) then {};
    case ((COMPONENT(name = id) :: rest))
      equation
        res = componentNamesFromElts(rest);
      then
        (id :: res);
    case _ :: rest
      then componentNamesFromElts(rest);
  end matchcontinue;
end componentNamesFromElts;

public function isFunction
"function: isFunction
  Return true if Class is a function."
  input Element inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inClass)
    local String n; ClassDef def;
    case CLASS(name = n,restriction = R_FUNCTION(),classDef = def) then true;
    case CLASS(name = n,restriction = R_EXT_FUNCTION(),classDef = def) then true;
    case _ then false;
  end matchcontinue;
end isFunction;

public function className
"function: className
  Returns the class name of a Class."
  input Element inClass;
  output String outString;
algorithm
  outString := matchcontinue (inClass)
    local String n;
    case CLASS(name = n) then n;
    case _ then "Not a class";
  end matchcontinue;
end className;

public function classSetPartial
"function: classSetPartial
  author: PA
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
      Absyn.Info info;
      Prefixes prefixes;

    case (CLASS(name = id,
                prefixes = prefixes,
                encapsulatedPrefix = enc,
                restriction = restr,
                classDef = def, 
                info = info),partialPrefix)
      then CLASS(id,prefixes,enc,partialPrefix,restr,def,info);
  end match;
end classSetPartial;

public function isFunctionOrExtFunction
"function isFunctionOrExtFunction
  This function returns true if the class
  restriction is function or external function.
  Otherwise false is returned."
  input Restriction r;
  output Boolean res;
algorithm
  res := matchcontinue(r)
    case(R_FUNCTION()) then true;
    case (R_EXT_FUNCTION()) then true;
    case(_) then false;
  end matchcontinue;
 end isFunctionOrExtFunction;

public function elementEqual
"function elementEqual
  returns true if two elements are equal,
  i.e. for a component have the same type,
  name, and attributes, etc."
   input Element element1;
   input Element element2;
   output Boolean equal;
 algorithm
   equal := matchcontinue(element1,element2)
     local
      Ident name1,name2;
      Element cl1,cl2;
      Prefixes prefixes1, prefixes2;
      Encapsulated en1, en2;
      Partial p1,p2;
      Absyn.InnerOuter io1,io2;
      Restriction restr1, restr2;
      Attributes attr1,attr2; 
      Mod mod1,mod2;
      Absyn.TypeSpec tp1,tp2;
      Absyn.Import im1,im2;
      Absyn.Path path1,path2;
      Option<String> os1,os2;
      Option<Real> or1,or2;
      Option<Absyn.Exp> cond1, cond2;
      Option<Absyn.ConstrainClass> cc1, cc2;
      ClassDef cd1,cd2;
      
    case (CLASS(name1,prefixes1,en1,p1,restr1,cd1,_),CLASS(name2,prefixes2,en2,p2,restr2,cd2,_))
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
         true = ModUtil.pathEqual(path1,path2);
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
"function: annotationEqual
  returns true if 2 annotations are equal"
  input Annotation annotation1;
  input Annotation annotation2;
  output Boolean equal;
algorithm
  equal := matchcontinue(annotation1,annotation2)
    local
      Mod mod1,mod2;
      Boolean res;
    case(ANNOTATION(mod1),ANNOTATION(mod2))
      equation
        res = modEqual(mod1,mod2);
      then
        res;
    case(_,_) then false;
  end matchcontinue;
end annotationEqual;

public function restrictionEqual "Returns true if two Restriction's are equal."
  input Restriction restr1;
  input Restriction restr2;
  output Boolean equal;
algorithm
   equal := matchcontinue(restr1,restr2)
     case (R_CLASS(),R_CLASS()) then true;
     case (R_OPTIMIZATION(),R_OPTIMIZATION()) then true;
     case (R_MODEL(),R_MODEL()) then true;
     case (R_RECORD(),R_RECORD()) then true;
     case (R_BLOCK(),R_BLOCK()) then true;
     case (R_CONNECTOR(true),R_CONNECTOR(true)) then true; // expandable connectors
     case (R_CONNECTOR(false),R_CONNECTOR(false)) then true; // non expandable connectors
     case (R_OPERATOR(true),R_OPERATOR(true)) then true; // operator
     case (R_OPERATOR(false),R_OPERATOR(false)) then true; // operator function
     case (R_TYPE(),R_TYPE()) then true;
     case (R_PACKAGE(),R_PACKAGE()) then true;
     case (R_FUNCTION(),R_FUNCTION()) then true;
     case (R_EXT_FUNCTION(),R_EXT_FUNCTION()) then true;
     case (R_ENUMERATION(),R_ENUMERATION()) then true;
     case (R_PREDEFINED_INTEGER(),R_PREDEFINED_INTEGER()) then true;
     case (R_PREDEFINED_REAL(),R_PREDEFINED_REAL()) then true;
     case (R_PREDEFINED_STRING(),R_PREDEFINED_STRING()) then true;
     case (R_PREDEFINED_BOOLEAN(),R_PREDEFINED_BOOLEAN()) then true;
     case (R_PREDEFINED_ENUMERATION(),R_PREDEFINED_ENUMERATION()) then true;
     case (_,_) then false;
   end matchcontinue;
end restrictionEqual;

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
"function classDefEqual
  Returns true if Two ClassDef's are equal"
 input ClassDef cdef1;
 input ClassDef cdef2;
 output Boolean equal;
 algorithm
   equal := matchcontinue(cdef1,cdef2)
     local
       list<Element> elts1,elts2;
       list<Annotation> anns1,anns2;
       list<Equation> eqns1,eqns2;
       list<Equation> ieqns1,ieqns2;
       list<AlgorithmSection> algs1,algs2;
       list<AlgorithmSection> ialgs1,ialgs2;
       Attributes attr1,attr2;
       Absyn.TypeSpec tySpec1, tySpec2;
       Absyn.Path p1, p2;
       Mod mod1,mod2;
       list<Enum> elst1,elst2;
       list<Ident> ilst1,ilst2;
       String bcName1, bcName2;
       
     case(PARTS(elts1,eqns1,ieqns1,algs1,ialgs1,_,anns1,_),
          PARTS(elts2,eqns2,ieqns2,algs2,ialgs2,_,anns2,_))
       equation
         Util.listThreadMapAllValue(elts1,elts2,elementEqual,true);
         Util.listThreadMapAllValue(eqns1,eqns2,equationEqual,true);
         Util.listThreadMapAllValue(ieqns1,ieqns2,equationEqual,true);
         Util.listThreadMapAllValue(algs1,algs2,algorithmEqual,true);
         Util.listThreadMapAllValue(ialgs1,ialgs2,algorithmEqual,true);
         // adrpo: ignore annotations!
         // blst6 = Util.listThreadMap(anns1,anns2,annotationEqual);
       then 
         true;
         
     case (DERIVED(tySpec1,mod1,attr1,_),
           DERIVED(tySpec2,mod2,attr2,_))
       equation
         true = ModUtil.typeSpecEqual(tySpec1, tySpec2);
         true = modEqual(mod1,mod2);
         true = attributesEqual(attr1, attr2);
       then 
         true;
         
     case (ENUMERATION(elst1,_),ENUMERATION(elst2,_))
       equation
         Util.listThreadMapAllValue(elst1,elst2,enumEqual,true);
       then 
         true;
         
     case (cdef1 as CLASS_EXTENDS(bcName1,mod1,PARTS(elts1,eqns1,ieqns1,algs1,ialgs1,_,anns1,_)),
           cdef2 as CLASS_EXTENDS(bcName2,mod2,PARTS(elts2,eqns2,ieqns2,algs2,ialgs2,_,anns2,_)))
       equation
         Util.listThreadMapAllValue(elts1,elts2,elementEqual,true);
         Util.listThreadMapAllValue(eqns1,eqns2,equationEqual,true);
         Util.listThreadMapAllValue(ieqns1,ieqns2,equationEqual,true);
         Util.listThreadMapAllValue(algs1,algs2,algorithmEqual,true);
         Util.listThreadMapAllValue(ialgs1,ialgs2,algorithmEqual,true);
         true = stringEq(bcName1,bcName2);
         true = modEqual(mod1,mod2);
         // adrpo: ignore annotations!
         // blst6 = Util.listThreadMap(anns1,anns2,annotationEqual);
       then
         true;
         
     case (cdef1 as PDER(p1,ilst1,_),cdef2 as PDER(p2,ilst2,_))
       equation
         Util.listThreadMapAllValue(ilst1,ilst2,stringEq,true);
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
    
    case(cdef1, cdef2) then fail();   
  end matchcontinue;
end classDefEqual;

protected function arraydimOptEqual
"function arraydimOptEqual
  Returns true if two Option<ArrayDim> are equal"
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
        Util.listThreadMapAllValue(lst1,lst2,subscriptEqual,true);
      then 
        true;
    // oth. false
    case(SOME(lst1),SOME(lst2)) then false;
  end matchcontinue;
end arraydimOptEqual;

protected function subscriptEqual
"function subscriptEqual
  Returns true if two Absyn.Subscript are equal"
input Absyn.Subscript sub1;
input Absyn.Subscript sub2;
output Boolean equal;
algorithm
  equal := matchcontinue(sub1,sub2)
    local
      Absyn.Exp e1,e2;
    case(Absyn.NOSUB(),Absyn.NOSUB()) then true;
    case(Absyn.SUBSCRIPT(e1),Absyn.SUBSCRIPT(e2))
      equation
        equal=Absyn.expEqual(e1,e2);
      then equal;
    case (_,_) then false;
  end matchcontinue;
end subscriptEqual;

protected function algorithmEqual
"function algorithmEqual
  Returns true if two Algorithm's are equal."
  input AlgorithmSection alg1;
  input AlgorithmSection alg2;
  output Boolean equal;
algorithm
  equal := matchcontinue(alg1,alg2)
    local
      list<Statement> a1,a2;
    
    case(ALGORITHM(a1),ALGORITHM(a2))
      equation
        Util.listThreadMapAllValue(a1,a2,algorithmEqual2,true);
      then 
        true;
    
    // false otherwise!
    case (_, _) then false;
  end matchcontinue;
end algorithmEqual;

protected function algorithmEqual2
"function algorithmEqual2
  Returns true if two Absyn.Algorithm are equal."
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
    case(_,_) then false;
   end matchcontinue;
 end algorithmEqual2;

public function equationEqual
"function equationEqual
  Returns true if two equations are equal."
  input Equation eqn1;
  input Equation eqn2;
  output Boolean equal;
algorithm
  equal := match(eqn1,eqn2)
    local EEquation eq1,eq2;
    case (EQUATION(eq1),EQUATION(eq2))
      equation
        equal = equationEqual2(eq1,eq2);
        then equal;
  end match;
end equationEqual;

protected function equationEqual2
"function equationEqual2
  Helper function to equationEqual"
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
        Util.listThreadMapAllValue(fb1,fb2,equationEqual2,true);
        Util.listThreadMapAllValue(ifcond1,ifcond2,Absyn.expEqual,true);
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
    
    case (EQ_FOR(index = id1, range = exp1, eEquationLst = eql1),EQ_FOR(index = id2, range = exp2, eEquationLst = eql2))
      equation
        Util.listThreadMapAllValue(eql1,eql2,equationEqual2,true);
        true = Absyn.expEqual(exp1,exp2);
        true = stringEq(id1,id2);
      then 
        true;
    
    case (EQ_WHEN(condition = cond1, eEquationLst = elst1),EQ_WHEN(condition = cond2, eEquationLst = elst2)) // TODO: elsewhen not checked yet.
      equation
        Util.listThreadMapAllValue(elst1,elst2,equationEqual2,true);
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
    
    // otherwise false
    case(_,_) then false;
  end matchcontinue;
end equationEqual2;

protected function equationEqual22
"Author BZ
 Helper function for equationEqual2, does compare list<list<equation>> (else ifs in ifequations.)"
  input list<list<EEquation>> tb1;
  input list<list<EEquation>> tb2;
  output Boolean bOut;
algorithm
  bOut := matchcontinue(tb1,tb2)
    local
      list<EEquation> tb_1,tb_2;
    
    case({},{}) then true;
    case(_,{}) then false;
    case({},_) then false;
    case(tb_1::tb1,tb_2::tb2)
      equation
        Util.listThreadMapAllValue(tb_1,tb_2,equationEqual2,true);
        true = equationEqual22(tb1,tb2);
      then
        true;
    case(tb_1::tb1,tb_2::tb2) then false;
    
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
      list<Element> elts1,elts2;

    case (MOD(f1,each1,submodlst1,SOME((e1,_))),MOD(f2,each2,submodlst2,SOME((e2,_))))
      equation
        true = valueEq(f1,f2);
        true = eachEqual(each1,each2);
        true = subModsEqual(submodlst1,submodlst2);
        true = Absyn.expEqual(e1,e2);
      then 
        true;
    
    case (MOD(f1,each1,submodlst1,NONE()),MOD(f2,each2,submodlst2,NONE()))
      equation
        true = valueEq(f1,f2);
        true = eachEqual(each1,each2);
        true = subModsEqual(submodlst1,submodlst2);
      then 
        true;
    
    case (NOMOD(),NOMOD()) then true;
    
    case (REDECL(f1,each1,elts1),REDECL(f2,each2,elts2))
      equation
        true = valueEq(f1,f2);
        true = eachEqual(each1,each2);
        Util.listThreadMapAllValue(elts1,elts2,elementEqual,true);
      then 
        true;
    
    case(_,_) then false;
    
  end matchcontinue;
end modEqual;

protected function subModsEqual
"function subModsEqual
  Return true if two subModifier lists are equal"
  input list<SubMod>  subModLst1;
  input list<SubMod>  subModLst2;
  output Boolean equal;
algorithm
  equal := matchcontinue(subModLst1,subModLst2)
    local
      Ident id1,id2;
      Mod mod1,mod2;
      list<Subscript> ss1,ss2;

    case ({},{}) then true;
    
    case (NAMEMOD(id1,mod1)::subModLst1,NAMEMOD(id2,mod2)::subModLst2)
        equation
          true = stringEq(id1,id2);
          true = modEqual(mod1,mod2);
          true = subModsEqual(subModLst1,subModLst2);
        then 
          true;
    
    case (IDXMOD(ss1,mod1)::subModLst1,IDXMOD(ss2,mod2)::subModLst2)
        equation
          true = subscriptsEqual(ss1,ss2);
          true = modEqual(mod1,mod2);
          true = subModsEqual(subModLst1,subModLst2);
        then 
          true;
    
    case (_,_) then false;
  end matchcontinue;
end subModsEqual;

protected function subscriptsEqual
"function subscriptsEqual
  Returns true if two subscript lists are equal"
  input list<Subscript> ss1;
  input list<Subscript> ss2;
  output Boolean equal;
algorithm
  equal := matchcontinue(ss1,ss2)
    local
      Absyn.Exp e1,e2;

    case({},{}) then true;
    
    case(Absyn.NOSUB()::ss1,Absyn.NOSUB()::ss2)
      then subscriptsEqual(ss1,ss2);
    
    case(Absyn.SUBSCRIPT(e1)::ss1,Absyn.SUBSCRIPT(e2)::ss2)
      equation
        true = Absyn.expEqual(e1,e2);
        true = subscriptsEqual(ss1,ss2);
      then 
        true;
    
    case(_,_) then false;
  end matchcontinue;
end subscriptsEqual;

public function attributesEqual
"function attributesEqual
  Returns true if two Atributes are equal"
   input Attributes attr1;
   input Attributes attr2;
   output Boolean equal;
algorithm
  equal:= matchcontinue(attr1,attr2)
    local
      Variability var1,var2;
      Flow fl1,fl2;
      Stream st1,st2;
      Absyn.ArrayDim ad1,ad2;
      Absyn.Direction dir1,dir2;
      
    case(ATTR(ad1,fl1,st1,var1,dir1),ATTR(ad2,fl2,st2,var2,dir2))
      equation
        true = arrayDimEqual(ad1,ad2);
        true = valueEq(fl1,fl2);
        true = variabilityEqual(var1,var2);
        true = directionEqual(dir1,dir2);
        true = valueEq(st1,st2);  // added Modelica 3.1 stream connectors
      then 
        true;
    
    case(_, _) then false;
    
  end matchcontinue;
end attributesEqual;

public function variabilityEqual
"function variabilityEqual
  Returns true if two Variablity prefixes are equal"
  input Variability var1;
  input Variability var2;
  output Boolean equal;
algorithm
  equal := matchcontinue(var1,var2)
    case(VAR(),VAR()) then true;
    case(DISCRETE(),DISCRETE()) then true;
    case(PARAM(),PARAM()) then true;
    case(CONST(),CONST()) then true;
    case(_,_) then false;
  end matchcontinue;
end variabilityEqual;

protected function directionEqual
"function directionEqual
  Returns true if two Direction prefixes are equal"
  input Absyn.Direction dir1;
  input Absyn.Direction dir2;
  output Boolean equal;
algorithm
  equal := matchcontinue(dir1,dir2)
    case(Absyn.INPUT(),Absyn.INPUT()) then true;
    case(Absyn.OUTPUT(),Absyn.OUTPUT()) then true;
    case(Absyn.BIDIR(),Absyn.BIDIR()) then true;
    case(_,_) then false;
  end matchcontinue;
end directionEqual;

protected function arrayDimEqual
"function arrayDimEqual
  Return true if two arraydims are equal"
 input Absyn.ArrayDim ad1;
 input Absyn.ArrayDim ad2;
 output Boolean equal;
 algorithm
   equal := matchcontinue(ad1,ad2)
     local
       Absyn.Exp e1,e2;
     
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
     
     case(_,_) then false;
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
      Absyn.Info info;
      Prefixes prefixes;
      Restriction oldR;
    
    // check if restrictions are equal, so you can return the same thing!
    case(r, CLASS(restriction = oldR))
      equation
        true = restrictionEqual(r, oldR);
      then 
        cl;
    
    // not equal, change
    case(r, CLASS(id,prefixes,e,p,_,parts,info)) 
      then CLASS(id,prefixes,e,p,r,parts,info);
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
      Absyn.Info info;
      Prefixes prefixes;
      Restriction r;
      Ident id;
      
    // check if restrictions are equal, so you can return the same thing!
    case(name, CLASS(name = id))
      equation
        true = stringEqual(name, id);
      then 
        cl;      
    
    // not equal, change
    case(name, CLASS(_,prefixes,e,p,r,parts,info)) 
      then CLASS(name,prefixes,e,p,r,parts,info);
  end matchcontinue;
end setClassName;

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
      Absyn.Info info;
      Restriction restriction;
      Prefixes prefixes;
      Partial oldPartialPrefix;
    
    // check if partial prefix are equal, so you can return the same thing!
    case(partialPrefix,CLASS(partialPrefix = oldPartialPrefix))
      equation
        true = valueEq(partialPrefix, oldPartialPrefix); 
      then 
        cl;
    
    // not the same, change
    case(partialPrefix,CLASS(id,prefixes,e,_,restriction,parts,info)) 
      then CLASS(id,prefixes,e,partialPrefix,restriction,parts,info);
  end matchcontinue;
end setClassPartialPrefix;

protected function findIteratorInEEquation
  input String inString;
  input EEquation inEEq;
  output list<tuple<Absyn.ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inEEq)
    local
      String id, id_1;
      list<tuple<Absyn.ComponentRef, Integer>> lst,lst_1,lst_2,lst_3;
      Absyn.Exp e_1,e_2;
      list<Absyn.Exp> eLst;
      Absyn.ComponentRef cr_1, cr_2;
      list<EEquation> eeqLst;
      list<list<EEquation>> eeqLstLst;
      Absyn.FunctionArgs fArgs;
      list<tuple<Absyn.Exp, list<EEquation>>> ew;

      case (id,EQ_IF(condition = eLst, thenBranch = eeqLstLst, elseBranch = eeqLst))
        equation
          lst_1=Absyn.findIteratorInExpLst(id,eLst);
          lst_2=findIteratorInEEquationLstLst(id,eeqLstLst);
          lst_3=findIteratorInEEquationLst(id,eeqLst);
          lst=Util.listFlatten({lst_1,lst_2,lst_3});
        then lst;
      case (id,EQ_EQUALS(expLeft = e_1, expRight = e_2))
        equation
          lst_1=Absyn.findIteratorInExp(id,e_1);
          lst_2=Absyn.findIteratorInExp(id,e_2);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id,EQ_CONNECT(crefLeft = cr_1, crefRight = cr_2))
        equation
          lst_1=Absyn.findIteratorInCRef(id,cr_1);
          lst_2=Absyn.findIteratorInCRef(id,cr_2);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id,EQ_FOR(index = id_1, range = e_1, eEquationLst = eeqLst))
        equation
          false = stringEq(id, id_1);
          lst_1=Absyn.findIteratorInExp(id,e_1);
          lst_2=findIteratorInEEquationLst(id,eeqLst);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id,EQ_FOR(index = id_1, range = e_1, eEquationLst = eeqLst))
        equation
          true = stringEq(id, id_1);
          lst=Absyn.findIteratorInExp(id,e_1);
        then lst;
      case (id,EQ_WHEN(condition = e_1, eEquationLst = eeqLst, elseBranches = ew))
        equation
          lst_1=Absyn.findIteratorInExp(id,e_1);
          lst_2=findIteratorInEEquationLst(id,eeqLst);
          lst_3=findIteratorInElsewhen(id,ew);
          lst=Util.listFlatten({lst_1,lst_2,lst_3});
        then lst;
      case (id,EQ_ASSERT(condition = e_1, message = e_2))
        equation
          lst_1=Absyn.findIteratorInExp(id,e_1);
          lst_2=Absyn.findIteratorInExp(id,e_2);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id,EQ_TERMINATE(message = e_1))
        equation
          lst=Absyn.findIteratorInExp(id,e_1);
        then lst;
      case (id,EQ_REINIT(cref = cr_1, expReinit = e_2))
        equation
          lst_1=Absyn.findIteratorInCRef(id,cr_1);
          lst_2=Absyn.findIteratorInExp(id,e_2);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id,EQ_NORETCALL(functionArgs = fArgs))
        equation
          lst=Absyn.findIteratorInFunctionArgs(id,fArgs);
        then lst;

  end matchcontinue;
end findIteratorInEEquation;

public function findIteratorInEEquationLst "Used by Inst.instEquationCommon for EQ_FOR with implicit range"
//This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<EEquation> inEEqLst;
  output list<tuple<Absyn.ComponentRef, Integer>> outLst;
algorithm
    outLst := match(inString,inEEqLst)
    local
      list<tuple<Absyn.ComponentRef, Integer>> lst,lst_1,lst_2;
      String id;
      list<EEquation> rest;
      EEquation eeq;
      case (id,{}) then {};
      case (id,eeq::rest)
        equation
          lst_1=findIteratorInEEquation(id,eeq);
          lst_2=findIteratorInEEquationLst(id,rest);
          lst=listAppend(lst_1,lst_2);
        then lst;
  end match;
end findIteratorInEEquationLst;

protected function findIteratorInEEquationLstLst
//This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<list<EEquation>> inEEqLstLst;
  output list<tuple<Absyn.ComponentRef, Integer>> outLst;
algorithm
    outLst := match(inString,inEEqLstLst)
    local
      list<tuple<Absyn.ComponentRef, Integer>> lst,lst_1,lst_2;
      String id;
      list<list<EEquation>> rest;
      list<EEquation> eeq;
      case (id,{}) then {};
      case (id,eeq::rest)
        equation
          lst_1=findIteratorInEEquationLst(id,eeq);
          lst_2=findIteratorInEEquationLstLst(id,rest);
          lst=listAppend(lst_1,lst_2);
        then lst;
  end match;
end findIteratorInEEquationLstLst;

protected function findIteratorInElsewhen
//This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<tuple<Absyn.Exp, list<EEquation>>> inElsewhen;
  output list<tuple<Absyn.ComponentRef, Integer>> outLst;
algorithm
    outLst := match(inString,inElsewhen)
    local
      list<tuple<Absyn.ComponentRef, Integer>> lst,lst_1,lst_2,lst_3;
      String id;
      list<tuple<Absyn.Exp, list<EEquation>>> rest;
      Absyn.Exp e;
      list<EEquation> eeq;
      case (id,{}) then {};
      case (id,(e,eeq)::rest)
        equation
          lst_1 = Absyn.findIteratorInExp(id,e);
          lst_2 = findIteratorInEEquationLst(id,eeq);
          lst_3 = findIteratorInElsewhen(id,rest);
          lst = Util.listFlatten({lst_1,lst_2,lst_3});
        then lst;
  end match;
end findIteratorInElsewhen;


protected function filterComponents
"This function returns the components from a class"
  input list<Element> elts;
  output list<Element> compElts;
  output list<String> compNames;
algorithm
  (compElts,compNames) := matchcontinue (elts)
    local
      list<Element> rest, comps;
      Element comp; String name;
      list<String> names;
    // handle the empty things
    case ({}) then ({},{});
    // collect components
    case (( comp as COMPONENT(name=name)) :: rest)
      equation
        (comps, names) = filterComponents(rest);
      then (comp::comps,name::names);
    // ignore others
    case (_ :: rest)
      equation
        (comps, names) = filterComponents(rest);
      then (comps, names);
  end matchcontinue;
end filterComponents;

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

public function makeEnumType
  "Creates an EnumType element from an enumeration literal and an optional
  comment."
  input Enum inEnum;
  input Absyn.Info inInfo;
  output Element outEnumType;
protected
  String literal;
  Option<Comment> comment;
algorithm
  ENUM(literal = literal, comment = comment) := inEnum;
  SCodeCheck.checkValidEnumLiteral(literal, inInfo);
  outEnumType := COMPONENT(literal, defaultPrefixes, defaultConstAttr,
    Absyn.TPATH(Absyn.IDENT("EnumType"), NONE()), 
    NOMOD(), comment, NONE(), inInfo);
end makeEnumType;

public function variabilityOr 
"returns the more constant of two Variabilities (considers VAR() < DISCRETE() < PARAM() < CONST() ), similarly to Types.constOr"
  input Variability inConst1;
  input Variability inConst2;
  output Variability outConst;
algorithm
outConst := matchcontinue(inConst1, inConst2)
  case (CONST(),_) then CONST();
  case (_,CONST()) then CONST();
  case (PARAM(),_) then PARAM();
  case (_,PARAM()) then PARAM();
  case (DISCRETE(),_) then DISCRETE();
  case (_,DISCRETE()) then DISCRETE();
  case (_,_) then VAR();
  end matchcontinue;
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
      Absyn.ForIterators iterators;
      Absyn.FunctionArgs functionArgs;
      Absyn.Info info;
      list<Absyn.Exp> conditions;
      list<list<Statement>> stmtsList;
      list<Statement> body,trueBranch,elseBranch;
      list<tuple<Absyn.Exp, list<Statement>>> branches;
      Option<Comment> comment;
      list<Absyn.AlgorithmItem> algs1,algs2;
      list<list<Absyn.AlgorithmItem>> algsLst;
      list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> abranches;
      
    case ALG_ASSIGN(assignComponent,value,comment,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(assignComponent,value),NONE(),info);
    
    case ALG_IF(boolExpr,trueBranch,branches,elseBranch,comment,info)
      equation
        algs1 = Util.listMap(trueBranch,statementToAlgorithmItem);

        conditions = Util.listMap(branches, Util.tuple21);
        stmtsList = Util.listMap(branches, Util.tuple22);
        algsLst = Util.listListMap(stmtsList, statementToAlgorithmItem);
        abranches = Util.listThreadTuple(conditions,algsLst);

        algs2 = Util.listMap(elseBranch,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_IF(boolExpr,algs1,abranches,algs2),NONE(),info);
    
    case ALG_FOR(iterators,body,comment,info)
      equation
        algs1 = Util.listMap(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_FOR(iterators,algs1),NONE(),info);
  
    case ALG_WHILE(boolExpr,body,comment,info)
      equation
        algs1 = Util.listMap(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_WHILE(boolExpr,algs1),NONE(),info);
        
    case ALG_WHEN_A(branches,comment,info)
      equation
        (boolExpr::conditions) = Util.listMap(branches, Util.tuple21);
        stmtsList = Util.listMap(branches, Util.tuple22);
        (algs1::algsLst) = Util.listListMap(stmtsList, statementToAlgorithmItem);
        abranches = Util.listThreadTuple(conditions,algsLst);
      then Absyn.ALGORITHMITEM(Absyn.ALG_WHEN_A(boolExpr,algs1,abranches),NONE(),info);

    case ALG_NORETCALL(functionCall,functionArgs,comment,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(functionCall,functionArgs),NONE(),info);
    
    case ALG_RETURN(comment,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_RETURN(),NONE(),info);
    
    case ALG_BREAK(comment,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_BREAK(),NONE(),info);
    
    case ALG_TRY(body,comment,info)
      equation
        algs1 = Util.listMap(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_TRY(algs1),NONE(),info);
        
    case ALG_CATCH(body,comment,info)
      equation
        algs1 = Util.listMap(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_CATCH(algs1),NONE(),info);
    
    case ALG_THROW(comment,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),NONE(),info);
    
    case ALG_FAILURE(body,comment,info)
      equation
        algs1 = Util.listMap(body,statementToAlgorithmItem);
      then Absyn.ALGORITHMITEM(Absyn.ALG_FAILURE(algs1),NONE(),info);
  end match;
end statementToAlgorithmItem;

protected function findIteratorInStatement
  input String inString;
  input Statement inAlg;
  output list<tuple<Absyn.ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inAlg)
    local
      String id;
      list<tuple<Absyn.ComponentRef, Integer>> lst,lst_1,lst_2,lst_3,lst_4;
      list<list<tuple<Absyn.ComponentRef, Integer>>> lst_lst;
      Absyn.Exp e_1,e_2;
      list<Statement> algLst_1,algLst_2;
      list<tuple<Absyn.Exp, list<Statement>>> branches, elseIfBranch;
      list<Absyn.ForIterator> forIterators;
      Absyn.FunctionArgs funcArgs;
      Boolean bool;

      case (id,ALG_ASSIGN(assignComponent = e_1, value = e_2))
        equation
          lst_1=Absyn.findIteratorInExp(id,e_1);
          lst_2=Absyn.findIteratorInExp(id,e_2);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id,ALG_IF(boolExpr = e_1, trueBranch = algLst_1, elseIfBranch = elseIfBranch, elseBranch = algLst_2))
        equation
          lst_1=Absyn.findIteratorInExp(id,e_1);
          lst_2=findIteratorInStatements(id,algLst_1);
          lst_3=findIteratorInElseIfBranch(id,elseIfBranch);
          lst_4=findIteratorInStatements(id,algLst_2);
          lst=Util.listFlatten({lst_1,lst_2,lst_3,lst_4});
        then lst;
/*      case (id, ALG_FOR(forIterators,algLst_1))
        equation
          true=iteratorPresentAmongIterators(id,forIterators);
          lst=findIteratorInForIteratorsBounds(id,forIterators);
        then lst;
      case (id, ALG_FOR(forIterators,algLst_1))
        equation
          false=iteratorPresentAmongIterators(id,forIterators);
          lst_1=findIteratorInStatements(id,algLst_1);
          lst_2=findIteratorInForIteratorsBounds(id,forIterators);
          lst=listAppend(lst_1,lst_2);
        then lst; */
      case (id, ALG_FOR(iterators = forIterators, forBody = algLst_1))
        equation
          lst_1=findIteratorInStatements(id,algLst_1);
          (bool,lst_2)=Absyn.findIteratorInForIteratorsBounds2(id,forIterators);
          lst_1=Util.if_(bool, {}, lst_1);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id, ALG_WHILE(boolExpr = e_1, whileBody = algLst_1))
        equation
          lst_1=Absyn.findIteratorInExp(id,e_1);
          lst_2=findIteratorInStatements(id,algLst_1);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id,ALG_WHEN_A(branches = {})) then {};
      case (id,ALG_WHEN_A(branches = (e_1,algLst_1)::branches))
        equation
          lst_1=Absyn.findIteratorInExpLst(id,Util.listMap(branches,Util.tuple21));
          lst_lst = Util.listMap1r(Util.listMap(branches,Util.tuple22),findIteratorInStatements,id);
          lst=Util.listFlatten(lst_1::lst_lst);
        then lst;
      case (id,ALG_NORETCALL(functionArgs = funcArgs))
        equation
          lst=Absyn.findIteratorInFunctionArgs(id,funcArgs);
        then lst;
      case (id,ALG_TRY(tryBody = algLst_1))
        equation
          lst=findIteratorInStatements(id,algLst_1);
        then lst;
      case (id,ALG_CATCH(catchBody = algLst_1))
        equation
          lst=findIteratorInStatements(id,algLst_1);
        then lst;
      case (_,_) then {};
  end matchcontinue;
end findIteratorInStatement;

public function findIteratorInStatements "
Used by Inst.instForStatement
"
//This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<Statement> inAlgItemLst;
  output list<tuple<Absyn.ComponentRef, Integer>> outLst;
algorithm
    outLst := match(inString,inAlgItemLst)
    local
      list<tuple<Absyn.ComponentRef, Integer>> lst,lst_1,lst_2;
      String id;
      list<Statement> rest;
      Statement algItem;
      case (id,{}) then {};
      case (id,algItem::rest)
        equation
          lst_1=findIteratorInStatement(id,algItem);
          lst_2=findIteratorInStatements(id,rest);
          lst=listAppend(lst_1,lst_2);
        then lst;
  end match;
end findIteratorInStatements;

protected function findIteratorInElseIfBranch //This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<tuple<Absyn.Exp, list<Statement>>> inElseIfBranch;
  output list<tuple<Absyn.ComponentRef, Integer>> outLst;
algorithm
    outLst := match (inString,inElseIfBranch)
    local
      list<tuple<Absyn.ComponentRef, Integer>> lst,lst_1,lst_2,lst_3;
      String id;
      list<tuple<Absyn.Exp, list<Statement>>> rest;
      Absyn.Exp exp;
      list<Statement> algItemLst;
      case (id,{}) then {};
      case (id,(exp,algItemLst)::rest)
        equation
          lst_1=Absyn.findIteratorInExp(id,exp);
          lst_2=findIteratorInStatements(id,algItemLst);
          lst_3=findIteratorInElseIfBranch(id,rest);
          lst=Util.listFlatten({lst_1,lst_2,lst_3});
        then lst;
  end match;
end findIteratorInElseIfBranch;

public function equationFileInfo
  input EEquation eq;
  output Absyn.Info info;
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
  b := matchcontinue mod
    case NOMOD() then true;
    case MOD(subModLst={}) then true;
    case _ then false;
  end matchcontinue;
end emptyModOrEquality;

public function isComponentWithDirection
  input Element elt;
  input Absyn.Direction dir1;
  output Boolean b;
algorithm
  b := matchcontinue (elt,dir1)
    local
      Absyn.Direction dir2;
    case (COMPONENT(attributes = ATTR(direction = dir2)),dir1) then directionEqual(dir1,dir2);
    case (_,_) then false;
  end matchcontinue;
end isComponentWithDirection;

public function isComponent
  input Element elt;
  output Boolean b;
algorithm
  b := matchcontinue (elt)
    case (COMPONENT(attributes = _)) then true;
    else false;
  end matchcontinue;
end isComponent;

public function isNotComponent
  input Element elt;
  output Boolean b;
algorithm
  b := matchcontinue (elt)
    case (COMPONENT(attributes = _)) then false;
    else true;
  end matchcontinue;
end isNotComponent;

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
    Util.listMapAndFold(inEEquations, traverseEEquations, inTuple);
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
      TraverseFunc traverser;
      Argument arg;
      tuple<TraverseFunc, Argument> tup;
      Absyn.Exp e1, e2;
      list<Absyn.Exp> expl1;
      list<list<EEquation>> then_branch;
      list<EEquation> else_branch, eql;
      list<tuple<Absyn.Exp, list<EEquation>>> else_when;
      list<Absyn.NamedArg> args;
      Absyn.ForIterators iters;
      Option<Comment> comment;
      Absyn.Info info;
      Absyn.ComponentRef cr1, cr2;
      Ident index;

    case (EQ_IF(expl1, then_branch, else_branch, comment, info), tup)
      equation
        (then_branch, tup) = Util.listMapAndFold(then_branch,
          traverseEEquationsList, tup);
        (else_branch, tup) = traverseEEquationsList(else_branch, tup);
      then
        (EQ_IF(expl1, then_branch, else_branch, comment, info), tup);

    case (EQ_FOR(index, e1, eql, comment, info), tup)
      equation
        (eql, tup) = traverseEEquationsList(eql, tup);
      then
        (EQ_FOR(index, e1, eql, comment, info), tup);

    case (EQ_WHEN(e1, eql, else_when, comment, info), tup)
      equation
        (eql, tup) = traverseEEquationsList(eql, tup);
        (else_when, tup) = Util.listMapAndFold(else_when,
          traverseElseWhenEEquations, tup);
      then
        (EQ_WHEN(e1, eql, else_when, comment, info), tup);

    else then (inEEquation, inTuple);
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
  input tuple<TraverseFunc, Argument> inTuple;
  output list<EEquation> outEEquations;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Absyn.Exp, Argument> inTuple;
    output tuple<Absyn.Exp, Argument> outTuple;
  end TraverseFunc;
algorithm
  (outEEquations, outTuple) := 
    Util.listMapAndFold(inEEquations, traverseEEquationExps, inTuple);
end traverseEEquationListExps;

public function traverseEEquationExps
  "Traverses an EEquation, calling the given function on each Absyn.Exp it
  encounters. This funcion is intended to be used together with
  traverseEEquations, and does NOT descend into sub-EEquations."
  input EEquation inEEquation;
  input tuple<TraverseFunc, Argument> inTuple;
  output EEquation outEEquation;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Absyn.Exp, Argument> inTuple;
    output tuple<Absyn.Exp, Argument> outTuple;
  end TraverseFunc;
algorithm
  (outEEquation, outTuple) := match(inEEquation, inTuple)
    local
      TraverseFunc traverser;
      Argument arg;
      tuple<TraverseFunc, Argument> tup;
      Absyn.Exp e1, e2;
      list<Absyn.Exp> expl1;
      list<list<EEquation>> then_branch;
      list<EEquation> else_branch, eql;
      list<tuple<Absyn.Exp, list<EEquation>>> else_when;
      list<Absyn.NamedArg> args;
      Absyn.ForIterators iters;
      Option<Comment> comment;
      Absyn.Info info;
      Absyn.ComponentRef cr1, cr2;
      Ident index;

    case (EQ_IF(expl1, then_branch, else_branch, comment, info), (traverser, arg))
      equation
        ((expl1, arg)) = Absyn.traverseExpList(expl1, traverser, arg);
      then
        (EQ_IF(expl1, then_branch, else_branch, comment, info), (traverser, arg));

    case (EQ_EQUALS(e1, e2, comment, info), (traverser, arg))
      equation
        ((e1, arg)) = traverser((e1, arg));
        ((e2, arg)) = traverser((e2, arg));
      then
        (EQ_EQUALS(e1, e2, comment, info), (traverser, arg));

    case (EQ_CONNECT(cr1, cr2, comment, info), _)
      equation
        (cr1, tup) = traverseComponentRefExps(cr1, inTuple);
        (cr2, tup) = traverseComponentRefExps(cr2, tup);
      then
        (EQ_CONNECT(cr1, cr2, comment, info), tup);

    case (EQ_FOR(index, e1, eql, comment, info), (traverser, arg))
      equation
        ((e1, arg)) = traverser((e1, arg));
      then
        (EQ_FOR(index, e1, eql, comment, info), (traverser, arg));

    case (EQ_WHEN(e1, eql, else_when, comment, info), (traverser, arg))
      equation
        ((e1, arg)) = traverser((e1, arg));
        (else_when, tup) = Util.listMapAndFold(else_when, traverseElseWhenExps, 
          (traverser, arg));
      then
        (EQ_WHEN(e1, eql, else_when, comment, info), tup);

    case (EQ_ASSERT(e1, e2, comment, info), (traverser, arg))
      equation
        ((e1, arg)) = traverser((e1, arg));
        ((e2, arg)) = traverser((e2, arg));
      then
        (EQ_ASSERT(e1, e2, comment, info), (traverser, arg));

    case (EQ_TERMINATE(e1, comment, info), (traverser, arg))
      equation
        ((e1, arg)) = traverser((e1, arg));
      then
        (EQ_TERMINATE(e1, comment, info), (traverser, arg));

    case (EQ_REINIT(cr1, e1, comment, info), _)
      equation
        (cr1, (traverser, arg)) = traverseComponentRefExps(cr1, inTuple);
        ((e1, arg)) = traverser((e1, arg));
      then
        (EQ_REINIT(cr1, e1, comment, info), (traverser, arg));

    case (EQ_NORETCALL(cr1, Absyn.FUNCTIONARGS(expl1, args), comment, info), tup)
      equation
        (cr1, (traverser, arg)) = traverseComponentRefExps(cr1, tup);
        ((expl1, arg)) = Absyn.traverseExpList(expl1, traverser, arg);
        (args, tup) = Util.listMapAndFold(args, traverseNamedArgExps, (traverser, arg));
      then
        (EQ_NORETCALL(cr1, Absyn.FUNCTIONARGS(expl1, args), comment, info), tup);

    case (EQ_NORETCALL(cr1, Absyn.FOR_ITER_FARG(e1, iters), comment, info), tup)
      equation
        (cr1, (traverser, arg)) = traverseComponentRefExps(cr1, tup);
        ((e1, arg)) = traverser((e1,  arg));
        (iters, tup) = Util.listMapAndFold(iters, traverseForIteratorExps,
          (traverser, arg));
      then
        (EQ_NORETCALL(cr1, Absyn.FOR_ITER_FARG(e1, iters), comment, info), tup);

    else then (inEEquation, inTuple);
  end match;
end traverseEEquationExps;

protected function traverseComponentRefExps
  "Traverses the subscripts of a component reference and calls the given
  function on the subscript expressions."
  input Absyn.ComponentRef inCref;
  input tuple<TraverseFunc, Argument> inTuple;
  output Absyn.ComponentRef outCref;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Absyn.Exp, Argument> inTuple;
    output tuple<Absyn.Exp, Argument> outTuple;
  end TraverseFunc;
algorithm
  (outCref, outTuple) := match(inCref, inTuple)
    local
      Absyn.Ident name;
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef cr;
      tuple<TraverseFunc, Argument> tup;

    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cr), _)
      equation
        (cr, tup) = traverseComponentRefExps(cr, inTuple);
      then
        (Absyn.CREF_FULLYQUALIFIED(cr), tup);

    case (Absyn.CREF_QUAL(name = name, subScripts = subs, componentRef = cr), _)
      equation
        (cr, tup) = traverseComponentRefExps(cr, inTuple);
        (subs, tup) = Util.listMapAndFold(subs, traverseSubscriptExps, tup);
      then
        (Absyn.CREF_QUAL(name, subs, cr), tup);

    case (Absyn.CREF_IDENT(name = name, subscripts = subs), _)
      equation
        (subs, tup) = Util.listMapAndFold(subs, traverseSubscriptExps, inTuple);
      then
        (Absyn.CREF_IDENT(name, subs), tup);

    case (Absyn.WILD(), _) then (inCref, inTuple);
  end match;
end traverseComponentRefExps;

protected function traverseSubscriptExps
  "Calls the given function on the subscript expression."
  input Absyn.Subscript inSubscript;
  input tuple<TraverseFunc, Argument> inTuple;
  output Absyn.Subscript outSubscript;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Absyn.Exp, Argument> inTuple;
    output tuple<Absyn.Exp, Argument> outTuple;
  end TraverseFunc;
algorithm
  (outSubscript, outTuple) := match(inSubscript, inTuple)
    local
      Absyn.Exp sub_exp;
      TraverseFunc traverser;
      Argument arg;
    
    case (Absyn.SUBSCRIPT(subScript = sub_exp), (traverser, arg))
      equation
        ((sub_exp, arg)) = traverser((sub_exp, arg));
      then
        (Absyn.SUBSCRIPT(sub_exp), (traverser, arg));

    case (Absyn.NOSUB(), _) then (inSubscript, inTuple);
  end match;
end traverseSubscriptExps;

protected function traverseElseWhenExps
  "Traverses the expressions in an else when branch, and calls the given
  function on the expressions."
  input tuple<Absyn.Exp, list<EEquation>> inElseWhen;
  input tuple<TraverseFunc, Argument> inTuple;
  output tuple<Absyn.Exp, list<EEquation>> outElseWhen;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Absyn.Exp, Argument> inTuple;
    output tuple<Absyn.Exp, Argument> outTuple;
  end TraverseFunc;

  TraverseFunc traverser;
  Argument arg;
  Absyn.Exp exp;
  list<EEquation> eql;
algorithm
  (traverser, arg) := inTuple;
  (exp, eql) := inElseWhen;
  ((exp, arg)) := traverser((exp, arg));
  outElseWhen := (exp, eql);
  outTuple := (traverser, arg);
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
    input tuple<Absyn.Exp, Argument> inTuple;
    output tuple<Absyn.Exp, Argument> outTuple;
  end TraverseFunc;

  TraverseFunc traverser;
  Argument arg;
  Absyn.Ident name;
  Absyn.Exp value;
algorithm
  (traverser, arg) := inTuple;
  Absyn.NAMEDARG(argName = name, argValue = value) := inArg;
  ((value, arg)) := traverser((value, arg));
  outArg := Absyn.NAMEDARG(name, value);
  outTuple := (traverser, arg);
end traverseNamedArgExps;

protected function traverseForIteratorExps
  "Calls the given function on the expression associated with a for iterator."
  input Absyn.ForIterator inIterator;
  input tuple<TraverseFunc, Argument> inTuple;
  output Absyn.ForIterator outIterator;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Absyn.Exp, Argument> inTuple;
    output tuple<Absyn.Exp, Argument> outTuple;
  end TraverseFunc;
algorithm
  (outIterator, outTuple) := match(inIterator, inTuple)
    local
      TraverseFunc traverser;
      Argument arg;
      Absyn.Ident ident;
      Absyn.Exp guardExp,range;

    case (Absyn.ITERATOR(ident, NONE(), NONE()), (traverser, arg))
      then
        (Absyn.ITERATOR(ident, NONE(), NONE()), (traverser, arg));

    case (Absyn.ITERATOR(ident, NONE(), SOME(range)), (traverser, arg))
      equation
        ((range, arg)) = traverser((range, arg));
      then
        (Absyn.ITERATOR(ident, NONE(), SOME(range)), (traverser, arg));

    case (Absyn.ITERATOR(ident, SOME(guardExp), SOME(range)), (traverser, arg))
      equation
        ((guardExp, arg)) = traverser((guardExp, arg));
        ((range, arg)) = traverser((range, arg));
      then
        (Absyn.ITERATOR(ident, SOME(guardExp), SOME(range)), (traverser, arg));

    case (Absyn.ITERATOR(ident, SOME(guardExp), NONE()), (traverser, arg))
      equation
        ((guardExp, arg)) = traverser((guardExp, arg));
      then
        (Absyn.ITERATOR(ident, SOME(guardExp), NONE()), (traverser, arg));

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
    Util.listMapAndFold(inStatements, traverseStatements, inTuple);
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
      Absyn.ForIterators iters;
      Option<Comment> comment;
      Absyn.Info info;
      Statement stmt;

    case (ALG_IF(e, stmts1, branches, stmts2, comment, info), (traverser, arg))
      equation
        (stmts1, tup) = traverseStatementsList(stmts1, (traverser, arg));
        (branches, tup) = Util.listMapAndFold(branches, 
          traverseBranchStatements, tup);
        (stmts2, tup) = traverseStatementsList(stmts2, (traverser, arg));
      then
        (ALG_IF(e, stmts1, branches, stmts2, comment, info), tup);

    case (ALG_FOR(iters, stmts1, comment, info), tup)
      equation
        (stmts1, tup) = traverseStatementsList(stmts1, tup);
      then
        (ALG_FOR(iters, stmts1, comment, info), tup);

    case (ALG_WHILE(e, stmts1, comment, info), (traverser, arg))
      equation
        (stmts1, tup) = traverseStatementsList(stmts1, (traverser, arg));
      then
        (ALG_WHILE(e, stmts1, comment, info), tup);

    case (ALG_WHEN_A(branches, comment, info), tup)
      equation
        (branches, tup) = Util.listMapAndFold(branches, 
          traverseBranchStatements, tup);
      then
        (ALG_WHEN_A(branches, comment, info), tup);

    case (ALG_TRY(stmts1, comment, info), tup)
      equation
        (stmts1, tup) = traverseStatementsList(stmts1, tup);
      then
        (ALG_TRY(stmts1, comment, info), tup);

    case (ALG_CATCH(stmts1, comment, info), tup)
      equation
        (stmts1, tup) = traverseStatementsList(stmts1, tup);
      then
        (ALG_CATCH(stmts1, comment, info), tup);

    case (ALG_FAILURE(stmts1, comment, info), tup)
      equation
        (stmts1, tup) = traverseStatementsList(stmts1, tup);
      then
        (ALG_FAILURE(stmts1, comment, info), tup);

    else then (inStatement, inTuple);
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
  input tuple<TraverseFunc, Argument> inTuple;
  output list<Statement> outStatements;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Absyn.Exp, Argument> inTuple;
    output tuple<Absyn.Exp, Argument> outTuple;
  end TraverseFunc;
algorithm
  (outStatements, outTuple) :=
    Util.listMapAndFold(inStatements, traverseStatementExps, inTuple);
end traverseStatementListExps;

public function traverseStatementExps
  "Applies the given function to each expression in the given statement. This
  function is intended to be used together with traverseStatements, and does NOT
  descend into sub-statements."
  input Statement inStatement;
  input tuple<TraverseFunc, Argument> inTuple;
  output Statement outStatement;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Absyn.Exp, Argument> inTuple;
    output tuple<Absyn.Exp, Argument> outTuple;
  end TraverseFunc;
algorithm
  (outStatement, outTuple) := match(inStatement, inTuple)
    local
      TraverseFunc traverser;
      Argument arg;
      tuple<TraverseFunc, Argument> tup;
      Absyn.ComponentRef cr1;
      Absyn.Exp e1, e2;
      list<Absyn.Exp> expl1;
      list<Statement> stmts1, stmts2;
      list<tuple<Absyn.Exp, list<Statement>>> branches;
      Absyn.ForIterators iters;
      list<Absyn.NamedArg> args;
      Option<Comment> comment;
      Absyn.Info info;

    case (ALG_ASSIGN(e1, e2, comment, info), (traverser, arg))
      equation
        ((e1, arg)) = traverser((e1, arg));
        ((e2, arg)) = traverser((e2, arg));
      then
        (ALG_ASSIGN(e1, e2, comment, info), (traverser, arg));

    case (ALG_IF(e1, stmts1, branches, stmts2, comment, info), (traverser, arg))
      equation
        ((e1, arg)) = traverser((e1, arg));
        (branches, tup) = Util.listMapAndFold(branches, traverseBranchExps,
          (traverser, arg));
      then
        (ALG_IF(e1, stmts1, branches, stmts2, comment, info), tup);

    case (ALG_FOR(iters, stmts1, comment, info), tup)
      equation
        (iters, tup) = Util.listMapAndFold(iters, traverseForIteratorExps, tup);
      then
        (ALG_FOR(iters, stmts1, comment, info), tup);

    case (ALG_WHILE(e1, stmts1, comment, info), (traverser, arg))
      equation
        ((e1, arg)) = traverser((e1, arg));
      then
        (ALG_WHILE(e1, stmts1, comment, info), (traverser, arg));

    case (ALG_WHEN_A(branches, comment, info), tup)
      equation
        (branches, tup) = Util.listMapAndFold(branches, traverseBranchExps, tup);
      then
        (ALG_WHEN_A(branches, comment, info), tup);

    case (ALG_NORETCALL(cr1, Absyn.FUNCTIONARGS(expl1, args), comment, info), tup)
      equation
        (cr1, (traverser, arg)) = traverseComponentRefExps(cr1, tup);
        ((expl1, arg)) = Absyn.traverseExpList(expl1, traverser, arg);
        (args, tup) = Util.listMapAndFold(args, traverseNamedArgExps, (traverser, arg));
      then
        (ALG_NORETCALL(cr1, Absyn.FUNCTIONARGS(expl1, args), comment, info), tup);

    case (ALG_NORETCALL(cr1, Absyn.FOR_ITER_FARG(e1, iters), comment, info), tup)
      equation
        (cr1, (traverser, arg)) = traverseComponentRefExps(cr1, tup);
        ((e1, arg)) = traverser((e1,  arg));
        (iters, tup) = Util.listMapAndFold(iters, traverseForIteratorExps,
          (traverser, arg));
      then
        (ALG_NORETCALL(cr1, Absyn.FOR_ITER_FARG(e1, iters), comment, info), tup);

    else then (inStatement, inTuple);
  end match;
end traverseStatementExps;

protected function traverseBranchExps
  "Calls the given function on each expression found in an if or when branch."
  input tuple<Absyn.Exp, list<Statement>> inBranch;
  input tuple<TraverseFunc, Argument> inTuple;
  output tuple<Absyn.Exp, list<Statement>> outBranch;
  output tuple<TraverseFunc, Argument> outTuple;

  replaceable type Argument subtypeof Any;

  partial function TraverseFunc
    input tuple<Absyn.Exp, Argument> inTuple;
    output tuple<Absyn.Exp, Argument> outTuple;
  end TraverseFunc;

  TraverseFunc traverser;
  Argument arg;
  Absyn.Exp exp;
  list<Statement> stmts;
algorithm
  (traverser, arg) := inTuple;
  (exp, stmts) := inBranch;
  ((exp, arg)) := traverser((exp, arg));
  outBranch := (exp, stmts);
  outTuple := (traverser, arg);
end traverseBranchExps;

public function elementIsClass
  input Element el;
  output Boolean b;
algorithm
  b := match el
    case CLASS(classDef=_) then true;
    else false;
  end match;
end elementIsClass;

public function getElementClass
  input Element el;
  output Element cl;
algorithm
  cl := matchcontinue(el)
    case CLASS(name=_) then el;
    case _ then fail();
  end matchcontinue;
end getElementClass;

protected constant list<String> knownExternalCFunctions = {"acos"};

public function isBuiltinFunction
  input Element cl;
  input list<String> inVars;
  input list<String> outVars;
  output String name;
algorithm
  name := match (cl,inVars,outVars)
    local
      Absyn.Info info;
      String inc,outVar1,outVar2,name1,name2;
      list<String> argsStr;
      list<Absyn.Exp> args;
    case (CLASS(name=name,restriction=R_EXT_FUNCTION(),classDef=PARTS(externalDecl=SOME(EXTERNALDECL(funcName=NONE(),lang=SOME("builtin"))))),_,_)
      then name;
    case (CLASS(restriction=R_EXT_FUNCTION(),classDef=PARTS(externalDecl=SOME(EXTERNALDECL(funcName=SOME(name),lang=SOME("builtin"))))),_,_)
      then name;
    case (CLASS(restriction=R_EXT_FUNCTION(), classDef=PARTS(externalDecl=SOME(EXTERNALDECL(funcName=SOME(name),lang=SOME("C"),output_=SOME(Absyn.CREF_IDENT(outVar2,{})),args=args)))),inVars,{outVar1})
      equation
        true = listMember(name,{"sin","cos","tan","asin","acos","atan","atan2","sinh","cosh","tanh","exp","log","log10","sqrt"});
        true = outVar2 ==& outVar1;
        argsStr = Util.listMapMap(args, Absyn.expCref, Absyn.crefIdent);
        equality(argsStr = inVars);
      then name;
    case (CLASS(name=name,
      restriction=R_EXT_FUNCTION(),
      classDef=PARTS(externalDecl=SOME(EXTERNALDECL(funcName=NONE(),lang=SOME("C"))))),_,_)
      equation
        true = listMember(name,{"sin","cos","tan","asin","acos","atan","atan","sinh","cosh","tanh","exp","log","log10","sqrt"});
      then name;
  end match;
end isBuiltinFunction;

public function getEEquationInfo
  "Extracts the Absyn.Info from an EEquation."
  input EEquation inEEquation;
  output Absyn.Info outInfo;
algorithm
  outInfo := match(inEEquation)
    local
      Absyn.Info info;

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
  "Extracts the Absyn.Info from a Statement."
  input Statement inStatement;
  output Absyn.Info outInfo;
algorithm
  outInfo := match(inStatement)
    local
      Absyn.Info info;

    case ALG_ASSIGN(info = info) then info;
    case ALG_IF(info = info) then info;
    case ALG_FOR(info = info) then info;
    case ALG_WHILE(info = info) then info;
    case ALG_WHEN_A(info = info) then info;
    case ALG_NORETCALL(info = info) then info;
    case ALG_RETURN(info = info) then info;
    case ALG_BREAK(info = info) then info;
    case ALG_TRY(info = info) then info;
    case ALG_CATCH(info = info) then info;
    case ALG_THROW(info = info) then info;
    case ALG_FAILURE(info = info) then info;
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
  Option<ExternalDecl> ed;
  list<Annotation> annl;
  Option<Comment> c;
algorithm
  PARTS(el, nel, iel, nal, ial, ed, annl, c) := inClassDef;
  outClassDef := PARTS(inElement :: el, nel, iel, nal, ial, ed, annl, c);
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
  Absyn.Info i;
algorithm
  CLASS(n, pf, ep, pp, r, _, i) := inElement;
  outElement := CLASS(n, pf, ep, pp, r, inClassDef, i);
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
    case (REPLACEABLE(_)) then true;
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
  outReplaceable := matchcontinue(inBoolReplaceable, inOptConstrainClass)
    case (true, inOptConstrainClass) then REPLACEABLE(inOptConstrainClass);
    case (false, SOME(_))
      equation
        print("Ignoring constraint class because replaceable prefix is not present!\n");  
      then NOT_REPLACEABLE();
    case (false, _) then NOT_REPLACEABLE();
  end matchcontinue;
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

public function boolFinal
  input Boolean inBoolFinal;
  output Final outFinal;
algorithm
  outFinal := match(inBoolFinal)
    case (true) then FINAL();
    case (false) then NOT_FINAL();
  end match;
end boolFinal;

public function flowBool
  input Flow inFlow;
  output Boolean bFlow;
algorithm
  bFlow := match(inFlow)
    case (FLOW()) then true;
    case (NOT_FLOW()) then false;
  end match;
end flowBool;

public function boolFlow
  input Boolean inBoolFlow;
  output Flow outFlow;
algorithm
  outFlow := match(inBoolFlow)
    case (true) then FLOW();
    case (false) then NOT_FLOW();
  end match;
end boolFlow;

public function streamBool
  input Stream inStream;
  output Boolean bStream;
algorithm
  bStream := match(inStream)
    case (STREAM()) then true;
    case (NOT_STREAM()) then false;
  end match;
end streamBool;

public function boolStream
  input Boolean inBoolStream;
  output Stream outStream;
algorithm
  outStream := match(inBoolStream)
    case (true) then STREAM();
    case (false) then NOT_STREAM();
  end match;
end boolStream;

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
      Variability v1,v2,v;
      Absyn.Direction d1,d2,d;
      Absyn.ArrayDim ad1,ad2,ad;
      Flow f1,f2,f;
      Stream s1,s2,s;
    
    case(ele,NONE()) then SOME(ele);
    case(ATTR(ad1,f1,s1,v1,d1), SOME(ATTR(ad2,f2,s2,v2,d2)))
      equation
        f = boolFlow(boolOr(flowBool(f1),flowBool(f2)));
        s = boolStream(boolOr(streamBool(s1),streamBool(s2)));
        v = propagateVariability(v1,v2);
        d = propagateDirection(d1,d2);
        ad = ad1; // TODO! CHECK if ad1 == ad2!
      then
        SOME(ATTR(ad,f,s,v,d));
  end match;
end mergeAttributes;

protected function propagateVariability 
"Helper function for mergeAttributes"
  input Variability v1;
  input Variability v2;
  output Variability v;
algorithm 
  v := matchcontinue(v1,v2)
    case(v1,VAR()) then v1;
    case(v1,_) then v1;
  end matchcontinue;
end propagateVariability;

protected function propagateDirection 
"Helper function for mergeAttributes"
  input Absyn.Direction d1;
  input Absyn.Direction d2;
  output Absyn.Direction d;
algorithm 
  d := matchcontinue(d1,d2)
    case(Absyn.BIDIR(),d2) then d2;
    case(d1,Absyn.BIDIR()) then d1;
    case(d1,d2)
      equation
        equality(d1 = d2);
      then d1;
    case(_,_)
      equation
        print(" failure in propagateAbsynDirection, inner outer mismatch");
      then
        fail();
  end matchcontinue;
end propagateDirection;

public function prefixesVisibility
  input Prefixes inPrefixes;
  output Visibility outVisibility;
algorithm
  PREFIXES(visibility = outVisibility) := inPrefixes;
end prefixesVisibility;

public function eachEqual "Returns true if two each attributes are equal"
  input Each each1;
  input Each each2;
  output Boolean equal;
algorithm
  equal := matchcontinue(each1,each2)
    case(NOT_EACH(),NOT_EACH()) then true;
    case(EACH(),EACH()) then true;
    case(_,_) then false;
  end matchcontinue;
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
    
    case(_,_) then false;
    
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
        true = ModUtil.innerOuterEqual(io1, io2);
        true = replaceableEqual(rpl1, rpl2); 
      then 
        true;
    
    case(_,_) then false;
    
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
  Flow f;
  Stream s;
  Variability v;
  Absyn.Direction d;
algorithm
  ATTR(_, f, s, v, d) := inAttributes;
  outAttributes := ATTR({}, f, s, v, d);
end removeAttributeDimensions;

public function setAttributesDirection
  input Attributes inAttributes;
  input Absyn.Direction inDirection;
  output Attributes outAttributes;
protected
  Absyn.ArrayDim ad;
  Flow f;
  Stream s;
  Variability v;
algorithm
  ATTR(ad, f, s, v, _) := inAttributes;
  outAttributes := ATTR(ad, f, s, v, inDirection);
end setAttributesDirection;

public function attrVariability
"function attrVariability
  Return the variability attribute from Attributes"
  input Attributes attr;
  output Variability var;
algorithm
  var := match (attr)
    local Variability v;
    case  ATTR(variability = v) then v;
  end match;
end attrVariability;

end SCode;

