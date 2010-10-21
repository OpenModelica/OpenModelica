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

package SCode
" file:	       SCode.mo
  package:     SCode
  description: SCode intermediate form

  RCS: $Id$

  This module contains data structures to describe a Modelica
  model in a more convenient (canonical) way than the Absyn module does.
  Also local functions for printing and query of SCode are defined.

  See also SCodeUtil.mo for translation functions
  from Absyn representation to SCode representation.

  The SCode representation is used as input to the Inst module"

public import Absyn;

public type Ident = Absyn.Ident "Some definitions are borrowed from `Absyn\'";

public type Path = Absyn.Path;

public type Subscript = Absyn.Subscript;

public
uniontype Restriction
  record R_CLASS end R_CLASS;
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
    Boolean finalPrefix "final" ;
    Absyn.Each eachPrefix;
    list<SubMod> subModLst;
    Option<tuple<Absyn.Exp,Boolean>> absynExpOption "The binding expression of a modification
    has an expression and a Boolean delayElaboration which is true if elaboration(type checking)
    should be delayed. This can for instance be used when having A a(x = a.y) where a.y can not be
    type checked -before- a is instantiated, which is the current design in instantiation process.";
  end MOD;

  record REDECL
    Boolean finalPrefix       "final" ;
    list<Element> elementLst  "elements" ;
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
type Program = list<Class> "- Programs
As in the AST, a program is simply a list of class definitions." ;

public
uniontype Class "- Classes"
  record CLASS "the simplified SCode class"
    Ident name "the name of the class" ;
    Boolean partialPrefix "the partial prefix" ;
    Boolean encapsulatedPrefix "the encapsulated prefix" ;
    Restriction restriction "the restriction of the class" ;
    ClassDef classDef "the class specification" ;
    Absyn.Info info "the class information";
  end CLASS;
end Class;

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
  class A = B(modifiers);
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
    Option<Absyn.ExternalDecl> externalDecl        "used by external functions" ;
    list<Annotation>           annotationLst       "the list of annotations found in between class elements, equations and algorithms";
    Option<Comment>            comment             "the class comment";
  end PARTS;

  record CLASS_EXTENDS "an extended class definition plus the additional parts"
    Ident            baseClassName       "the name of the base class we have to extend";
    Mod              modifications       "the modifications that need to be applied to the base class";
    list<Element>    elementLst          "the list of elements";
    list<Equation>   normalEquationLst   "the list of equations";
    list<Equation>   initialEquationLst  "the list of initial equations";
    list<AlgorithmSection>  normalAlgorithmLst  "the list of algorithms";
    list<AlgorithmSection>  initialAlgorithmLst "the list of initial algorithms";
    list<Annotation> annotationLst       "the list of annotations found in between class elements, equations and algorithms";
    Option<Comment>  comment             "the class comment";
  end CLASS_EXTENDS;

  record DERIVED "a derived class"
    Absyn.TypeSpec typeSpec "typeSpec: type specification" ;
    Mod modifications;
    Absyn.ElementAttributes attributes;
    Option<Comment> comment "the translated comment from the Absyn";
  end DERIVED;

  record ENUMERATION "an enumeration"
    list<Enum> enumLst "if the list is empty it means :, the supertype of all enumerations";
    Option<Comment> comment "the translated comment from the Absyn";
  end ENUMERATION;

  record OVERLOAD "an overloaded function"
    list<Absyn.Path> pathLst;
    Option<Comment> comment "the translated comment from the Absyn";
  end OVERLOAD;

  record PDER "the partial derivative"
    Absyn.Path  functionPath "function name" ;
    list<Ident> derivedVariables "derived variables" ;
    Option<Comment> comment "the Absyn comment";
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
    list<tuple<Absyn.Exp, list<EEquation>>> tplAbsynExpEEquationLstLst "the elsewhen expression and equation list";
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

  record ALG_MATCHCASES
    Absyn.MatchType matchType;
    list<Absyn.Exp> inputExps;
    list<Absyn.Exp> switchCases;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_MATCHCASES;

  record ALG_GOTO
    String labelName;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_GOTO;

  record ALG_LABEL
    String labelName;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_LABEL;

  record ALG_FAILURE
    Statement equ;
    Option<Comment> comment;
    Absyn.Info info;
  end ALG_FAILURE;
  //-------------------------------

end Statement;

public
uniontype Element "- Elements
  There are four types of elements in a declaration, represented by the constructors:
  EXTENDS   (for extends clauses),
  CLASSDEF  (for local class definitions)
  COMPONENT (for local variables). and
  IMPORT    (for import clauses)
  The baseclass name is initially NONE() in the translation,
  and if an element is inherited from a base class it is
  filled in during the instantiation process."
  record EXTENDS "the extends element"
    Path baseClassPath "the extends path";
    Mod modifications  "the modifications applied to the base class";
    Option<Annotation> annotation_;
  end EXTENDS;

  record CLASSDEF "a local class definition"
    Ident   name               "the name of the local class" ;
    Boolean finalPrefix        "final prefix" ;
    Boolean replaceablePrefix  "replaceable prefix" ;
    Class   classDef           "the class definition" ;
    Option<Absyn.ConstrainClass> cc;
  end CLASSDEF;

  record IMPORT "an import element"
    Absyn.Import imp "the import definition";
  end IMPORT;

  record COMPONENT "a component"
    Ident component               "the component name" ;
    Absyn.InnerOuter innerOuter   "the inner/outer/innerouter prefix";
    Boolean finalPrefix           "the final prefix" ;
    Boolean replaceablePrefix     "the replaceable prefix" ;
    Boolean protectedPrefix       "the protected prefix" ;
    Attributes attributes         "the component attributes";
    Absyn.TypeSpec typeSpec       "the type specification" ;
    Mod modifications             "the modifications to be applied to the component";
    Option<Comment> comment       "this if for extraction of comments and annotations from Absyn";
    Option<Absyn.Exp> condition   "the conditional declaration of a component";
    Option<Absyn.Info> info       "this is for line and column numbers, also file name.";
    Option<Absyn.ConstrainClass> cc "The constraining class for the component";
  end COMPONENT;

  record DEFINEUNIT "a unit defintion has a name and the two optional parameters exp, and weight"
    Ident name;
    Option<String> exp;
    Option<Real> weight;
  end DEFINEUNIT;
end Element;

public
uniontype Attributes "- Attributes"
  record ATTR "the attributes of the component"
    Absyn.ArrayDim arrayDims "the array dimensions of the component";
    Boolean flowPrefix "the flow prefix" ;
    Boolean streamPrefix "the stream prefix" ;
    Accessibility accesibility "the accesibility of the component: RW (read/write), RO (read only), WO (write only)" ;
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

public
uniontype Accessibility "These are attributes that apply to a declared component."
  record RW "read/write" end RW;
  record RO "read-only" end RO;
  record WO "write-only (not used)" end WO;
end Accessibility;


public /* adrpo: previously present in Inst.mo */
uniontype Initial "the initial attribute of an algorithm or equation
 Intial is used as argument to instantiation-function for
 specifying if equations or algorithms are initial or not."
  record INITIAL "an initial equation or algorithm" end INITIAL;
  record NON_INITIAL "a normal equation or algorithm" end NON_INITIAL;
end Initial;


// .......... functionality .........
protected import Util;
protected import Dump;
protected import ModUtil;
protected import Print;
protected import Error;
protected import System;

protected function elseWhenEquationStr
"@author: adrpo
  Return the elsewhen parts as a string."
  input  list<tuple<Absyn.Exp, list<EEquation>>> tplAbsynExpEEquationLstLst;
  output String str;
algorithm
  str := matchcontinue(tplAbsynExpEEquationLstLst)
    local
      Absyn.Exp exp;
      list<EEquation> eqn_lst;
      list<tuple<Absyn.Exp, list<EEquation>>> rest;
      String s1, s2, s3, res;
      list<String> str_lst; 
    
    case ({}) then "";
    
    case ((exp,eqn_lst)::rest)
      equation
        s1 = Dump.printExpStr(exp);
        str_lst = Util.listMap(eqn_lst, equationStr);
        s2 = Util.stringDelimitList(str_lst, "\n");
        s3 = elseWhenEquationStr(tplAbsynExpEEquationLstLst);
        res = System.stringAppendList({"\nelsewhen ",s1," then\n",s2,"\n", s3});        
      then 
        res;
  end matchcontinue;
end elseWhenEquationStr;

public function equationStr
"function: equationStr
  author: PA
  Return the equation as a string."
  input EEquation inEEquation;
  output String outString;
algorithm
  outString := matchcontinue (inEEquation)
    local
      String s1,s2,s3,s4,res,id;
      list<String> tb_strs,fb_strs,str_lst;
      Absyn.Exp e1,e2,exp;
      list<Absyn.Exp> ifexp;
      list<EEquation> ttb,fb,eqn_lst;
      list<list<EEquation>> tb;
      Absyn.ComponentRef cr1,cr2,cr;
      Absyn.FunctionArgs fargs;
      list<tuple<Absyn.Exp, list<EEquation>>> tplAbsynExpEEquationLstLst;
      
    case (EQ_IF(condition = e1::ifexp,thenBranch = ttb::tb,elseBranch = fb))
      equation
        s1 = Dump.printExpStr(e1);
        tb_strs = Util.listMap(ttb, equationStr);
        fb_strs = Util.listMap(fb, equationStr);
        s2 = Util.stringDelimitList(tb_strs, "\n");
        s3 = Util.stringDelimitList(fb_strs, "\n");
        s4 = elseIfEquationStr(ifexp,tb);
        res = System.stringAppendList({"if ",s1," then ",s2,s4,"else ",s3,"end if;"});
      then
        res;
    case (EQ_EQUALS(expLeft = e1,expRight = e2))
      equation
        s1 = Dump.printExpStr(e1);
        s2 = Dump.printExpStr(e2);
        res = System.stringAppendList({s1," = ",s2,";"});
      then
        res;
    case (EQ_CONNECT(crefLeft = cr1,crefRight = cr2))
      equation
        s1 = Dump.printComponentRefStr(cr1);
        s2 = Dump.printComponentRefStr(cr2);
        res = System.stringAppendList({"connect(",s1,", ",s2,");"});
      then
        res;
    case (EQ_FOR(index = id,range = exp,eEquationLst = eqn_lst))
      equation
        s1 = Dump.printExpStr(exp);
        str_lst = Util.listMap(eqn_lst, equationStr);
        s2 = Util.stringDelimitList(str_lst, "\n");
        res = System.stringAppendList({"for ",id," in ",s1," loop\n",s2,"\nend for;"});
      then
        res;
    case (EQ_WHEN(condition=exp, eEquationLst=eqn_lst, tplAbsynExpEEquationLstLst=tplAbsynExpEEquationLstLst))
      equation
        s1 = Dump.printExpStr(exp);
        str_lst = Util.listMap(eqn_lst, equationStr);
        s2 = Util.stringDelimitList(str_lst, "\n");
        s3 = elseWhenEquationStr(tplAbsynExpEEquationLstLst);
        res = System.stringAppendList({"when ",s1," then\n",s2,s3,"\nend when;"});
      then 
        res;
    case (EQ_ASSERT(condition = e1,message = e2))
      equation
        s1 = Dump.printExpStr(e1);
        s2 = Dump.printExpStr(e2);
        res = System.stringAppendList({"assert(",s1,", ",s2,");"});
      then
        res;
    case (EQ_REINIT(cref = cr,expReinit = e1))
      equation
        s1 = Dump.printComponentRefStr(cr);
        s2 = Dump.printExpStr(e1);
        res = System.stringAppendList({"reinit(",s1,", ",s2,");"});
      then
        res;
    case(EQ_NORETCALL(functionName = cr, functionArgs = fargs))
      equation
        s1 = Dump.printComponentRefStr(cr);
        s2 = Dump.printFunctionArgsStr(fargs);
        res = s1 +& "(" +& s2 +& ");";
      then res;
  end matchcontinue;
end equationStr;

protected function prettyPrintOptModifier "
Author BZ, 2008-07
Pretty print SCode.Mod
"
input Option<Absyn.Modification> oam;
input String comp;
output String str;
algorithm str := matchcontinue(oam,comp)
  local
    Absyn.Modification m;
  case(NONE(),_) then "";
  case(SOME(m),comp)
    equation
      str = prettyPrintModifier(m,comp);
      then
        str;
  end matchcontinue;
end prettyPrintOptModifier;

protected function prettyPrintModifier "
Author BZ, 2008-07
Helper function for prettyPrintOptModifier
"
input Absyn.Modification oam;
input String comp;
output String str;
algorithm str := matchcontinue(oam,comp)
  local
    Absyn.Modification m;
    Absyn.Exp exp;
    list<Absyn.ElementArg> laea;
    Absyn.ElementArg aea;
  case(Absyn.CLASSMOD(_,SOME(exp)),comp)
    equation
      str = comp +& " = " +&Dump.printExpStr(exp);
      then
        str;
  case(Absyn.CLASSMOD((laea as aea::{}),NONE()),comp)
    equation
    str = comp +& "(" +&prettyPrintElementModifier(aea) +&")";
    then
      str;
  case(Absyn.CLASSMOD((laea as _::{}),NONE()),comp)
    equation
      str = comp +& "({" +& Util.stringDelimitList(Util.listMap(laea,prettyPrintElementModifier),", ") +& "})";
    then
      str;
  end matchcontinue;
end prettyPrintModifier;

protected function prettyPrintElementModifier "
Author BZ, 2008-07
Helper function for prettyPrintOptModifier

TODO: implement type of new redeclare component
"
  input Absyn.ElementArg aea;
  output String str;
algorithm str := matchcontinue(aea)
  local
    Option<Absyn.Modification> oam;
    String compName;
    Absyn.ElementSpec spec;
    Absyn.ComponentRef cr;
  case(Absyn.MODIFICATION(modification = oam,componentRef=cr))
    equation
      compName = Absyn.printComponentRefStr(cr);
    then prettyPrintOptModifier(oam,compName);
  case(Absyn.REDECLARATION(elementSpec=spec))
    equation
      compName = Absyn.elementSpecName(spec);
    then
      "Redeclaration of (" +& compName +& ")";
end matchcontinue;
end prettyPrintElementModifier;

public function stripSubmod
"function: stripSubmod
  author: PA
  Removes all submodifiers from the Mod."
  input Mod inMod;
  output Mod outMod;
algorithm
  outMod := matchcontinue (inMod)
    local
      Boolean f;
      Absyn.Each each_;
      list<SubMod> subs;
      Option<tuple<Absyn.Exp,Boolean>> e;
      Mod m;
    case (MOD(finalPrefix = f,eachPrefix = each_,subModLst = subs,absynExpOption = e)) then MOD(f,each_,{},e);
    case (m) then m;
  end matchcontinue;
end stripSubmod;

public function getElementNamed
"function: getElementNamed
  Return the Element with the name given as first argument from the Class."
  input Ident inIdent;
  input Class inClass;
  output Element outElement;
algorithm
  outElement := matchcontinue (inIdent,inClass)
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
    case (id,CLASS(classDef = CLASS_EXTENDS(elementLst = elts)))
      equation
        elt = getElementNamedFromElts(id, elts);
      then
        elt;
  end matchcontinue;
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
    
    case (id2,((comp as COMPONENT(component = id1)) :: _))
      equation
        true = stringEqual(id1, id2);
      then
        comp;
    
    case (id2,(COMPONENT(component = id1) :: xs))
      equation
        false = stringEqual(id1, id2);
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;
    
    case (id2,(CLASSDEF(name = id1) :: xs))
      equation
        false = stringEqual(id1, id2);
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;
    
    case (id2,(EXTENDS(baseClassPath = _) :: xs))
      equation
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;
    
    case (id2,((cdef as CLASSDEF(name = id1)) :: _))
      equation
        true = stringEqual(id1, id2);
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

public function printMod
"function: printMod
  This function prints a modification.
  The code is excluded from the report for brevity."
  input Mod m;
  String s;
algorithm
  s := printModStr(m);
  Print.printBuf(s);
end printMod;

public function printModStr
"function: printModStr
  Prints Mod to a string."
  input Mod inMod;
  output String outString;
algorithm
  outString:=
  matchcontinue (inMod)
    local
      String finalPrefixstr,str,res,each_str,subs_str,ass_str;
      list<String> strs;
      Boolean b,finalPrefix;
      list<Element> elist;
      Absyn.Each each_;
      list<SubMod> subs;
      Option<tuple<Absyn.Exp,Boolean>> ass;
    case (NOMOD()) then "";
    case REDECL(finalPrefix = b,elementLst = elist)
      equation
        Print.printBuf("redeclare(");
        finalPrefixstr = Util.if_(b, "final", "");
        strs = Util.listMap(elist, printElementStr);
        str = Util.stringDelimitList(strs, ",");
        res = System.stringAppendList({"redeclare(",finalPrefixstr,str,")"});
      then
        res;
    case MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,absynExpOption = ass)
      equation
        finalPrefixstr = Util.if_(finalPrefix, "final", "");
        each_str = Dump.unparseEachStr(each_);
        subs_str = printSubs1Str(subs);
        ass_str = printEqmodStr(ass);
        res = System.stringAppendList({finalPrefixstr,each_str,subs_str,ass_str});
      then
        res;
    case _
      equation
        Print.printBuf("#-- Inst.printModStr failed\n");
      then
        fail();
  end matchcontinue;
end printModStr;

public function restrString
"function: restrString
  Prints Restriction to a string."
  input Restriction inRestriction;
  output String outString;
algorithm
  outString:=
  matchcontinue (inRestriction)
    case R_CLASS() then "CLASS";
    case R_MODEL() then "MODEL";
    case R_RECORD() then "RECORD";
    case R_BLOCK() then "BLOCK";
    case R_CONNECTOR(false) then "CONNECTOR";
    case R_CONNECTOR(true) then "EXPANDABLE_CONNECTOR";
    case R_OPERATOR(false) then "OPERATOR";
    case R_OPERATOR(true) then "OPERATOR_FUNCTION";
    case R_TYPE() then "TYPE";
    case R_PACKAGE() then "PACKAGE";
    case R_FUNCTION() then "FUNCTION";
    case R_EXT_FUNCTION() then "EXTFUNCTION";
    case R_ENUMERATION() then "ENUMERATION";
    case R_METARECORD(_,_) then "METARECORD";
    case R_UNIONTYPE() then "UNIONTYPE";
    // predefined types
    case R_PREDEFINED_INTEGER() then "PREDEFINED_INT";
    case R_PREDEFINED_REAL() then "PREDEFINED_REAL";
    case R_PREDEFINED_STRING() then "PREDEFINED_STRING";
    case R_PREDEFINED_BOOLEAN() then "PREDEFINED_BOOL";
    case R_PREDEFINED_ENUMERATION() then "PREDEFINED_ENUM";
  end matchcontinue;
end restrString;

public function printRestr
"function: printRestr
  Prints Restriction to the Print buffer."
  input Restriction restr;
  String str;
algorithm
  str := restrString(restr);
  Print.printBuf(str);
end printRestr;

protected function printFinal
"function: printFinal
  Prints \"final\" to the Print buffer."
  input Boolean inBoolean;
algorithm
  _ := matchcontinue (inBoolean)
    case false then ();
    case true
      equation
        Print.printBuf(" final ");
      then
        ();
  end matchcontinue;
end printFinal;

protected function printSubsStr
"function: printSubsStr
  Prints a SubMod list to a string."
  input list<SubMod> inSubModLst;
  output String outString;
algorithm
  outString := matchcontinue (inSubModLst)
    local
      String s,res,n,mod_str,str,sub_str;
      Mod mod;
      list<SubMod> subs;
      list<Subscript> ss;
    case {} then "";
    case {NAMEMOD(ident = n,A = mod)}
      equation
        s = printModStr(mod);
        res = n +& " " +& s;
      then
        res;
    case (NAMEMOD(ident = n,A = mod) :: subs)
      equation
        mod_str = printModStr(mod);
        str = printSubsStr(subs);
        res = System.stringAppendList({n, " ", mod_str, ", ", str});
      then
        res;
    case {IDXMOD(subscriptLst = ss,an = mod)}
      equation
        str = Dump.printSubscriptsStr(ss);
        mod_str = printModStr(mod);
        res = stringAppend(str, mod_str);
      then
        res;
    case (IDXMOD(subscriptLst = ss,an = mod) :: subs)
      equation
        str = Dump.printSubscriptsStr(ss);
        mod_str = printModStr(mod);
        sub_str = printSubsStr(subs);
        res = System.stringAppendList({str,mod_str,", ",sub_str});
      then
        res;
  end matchcontinue;
end printSubsStr;

public function printSubs1Str
"function: printSubs1Str
  Helper function to printSubsStr."
  input list<SubMod> inSubModLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inSubModLst)
    local
      String s,res;
      list<SubMod> l;
    case {} then "";
    case l
      equation
        s = printSubsStr(l);
        res = System.stringAppendList({"(",s,")"});
      then
        res;
  end matchcontinue;
end printSubs1Str;

protected function printEqmodStr
"function: printEqmodStr
  Helper function to printModStr."
  input Option<tuple<Absyn.Exp,Boolean>> inAbsynExpOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynExpOption)
    local
      String str,res;
      Absyn.Exp e;
      Boolean b;
    case NONE() then "";
    case SOME((e,b))
      equation
        str = Dump.printExpStr(e);
        res = stringAppend(" = ", str);
      then
        res;
  end matchcontinue;
end printEqmodStr;

public function printElementList
"function: printElementList
  Print Element list to Print buffer."
  input list<Element> inElementLst;
algorithm
  _ := matchcontinue (inElementLst)
    local
      Element x;
      list<Element> xs;
    case ({}) then ();
    case ((x :: xs))
      equation
        printElement(x);
        printElementList(xs);
      then
        ();
  end matchcontinue;
end printElementList;

public function printElement
"function: printElement
  Print Element to Print buffer."
  input Element elt;
  String str;
algorithm
  str := printElementStr(elt);
  Print.printBuf(str);
end printElement;

public function printElementStr
"function: printElementStr
  Print Element to a string."
  input Element inElement;
  output String outString;
algorithm
  outString :=  matchcontinue (inElement)
    local
      String str,str2,res,n,mod_str,s,vs;
      Absyn.Path path,typath;
      Mod mod;
      Boolean finalPrefix,repl,prot;
      Absyn.InnerOuter io;
      Class cl;
      Variability var;
      Absyn.TypeSpec tySpec;
      Option<Comment> comment;
      Attributes attr;
      String modStr;
      Absyn.Path path;
      Absyn.Import imp;

    case EXTENDS(baseClassPath = path,modifications = mod)
      equation
        str = Absyn.pathString(path);
        modStr = printModStr(mod);
        res = System.stringAppendList({"EXTENDS(",str,", modification=",modStr,")"});
      then
        res;
    case CLASSDEF(name = n,finalPrefix = finalPrefix,replaceablePrefix = repl,classDef = cl)
      equation
        str = printClassStr(cl);
        res = System.stringAppendList({"CLASSDEF(",n,",",str,")"});
      then
        res;
    case COMPONENT(component = n,innerOuter=io,finalPrefix = finalPrefix,replaceablePrefix = repl,
                   protectedPrefix = prot, attributes = ATTR(variability = var),typeSpec = tySpec,
                   modifications = mod,comment = comment)
      equation
        mod_str = printModStr(mod);
        s = Dump.unparseTypeSpec(tySpec);
        vs = variabilityString(var);
        str2 = innerouterString(io);
        res = System.stringAppendList({"COMPONENT(",n, " in/out: ", str2, " mod: ",mod_str, " tp: ", s," var :",vs,")"});
      then
        res;
    case CLASSDEF(name = n,finalPrefix = finalPrefix,replaceablePrefix = repl,classDef = cl)
      equation
        str = printClassStr(cl);
        res = System.stringAppendList({"CLASSDEF(",n,",...,",str,")"});
      then
        res;
    case (IMPORT(imp = imp))
      equation
         str = "IMPORT("+& Absyn.printImportString(imp) +& ");";
      then str;
  end matchcontinue;
end printElementStr;

public function unparseElementStr
"function: unparseElementStr
  Print Element to a string."
  input Element inElement;
  output String outString;
algorithm
  outString := matchcontinue (inElement)
    local
      String str,res,n,mod_str,s,vs,ioStr;
      Absyn.TypeSpec typath;
      Mod mod;
      Class cl;
      Variability var;
      Option<Comment> comment;
      Attributes attr;
      Absyn.Path path;
      Absyn.Import imp;
      Absyn.InnerOuter io;

    case EXTENDS(baseClassPath = path,modifications = mod)
      equation
        str = Absyn.pathString(path);
        res = System.stringAppendList({"extends ",str,";"});
      then
        res;

    case COMPONENT(component = n,innerOuter = io,attributes = ATTR(variability = var),
                   typeSpec = typath,modifications = mod,comment = comment)
      equation
        ioStr = Dump.unparseInnerouterStr(io);
        mod_str = printModStr(mod);
        s = Dump.unparseTypeSpec(typath);
        vs = unparseVariability(var);
        vs = Util.if_(stringEqual(vs, ""), "", vs +& " ");
        res = System.stringAppendList({ioStr,vs,s," ",n," ",mod_str,";\n"});
      then
        res;

    case CLASSDEF(name = n,classDef = cl)
      equation
        str = printClassStr(cl);
        res = System.stringAppendList({"class ",n,"\n",str,"end ",n,";\n"});
      then
        res;

    case (IMPORT(imp = imp))
      equation
         str = "import "+& Absyn.printImportString(imp) +& ";";
      then str;
  end matchcontinue;
end unparseElementStr;

public function printClassStr "
  prints a class to a string"
  input Class inClass;
  output String outString;
algorithm
  outString := matchcontinue (inClass)
    local
      String s,res,id,re;
      Boolean p,en;
      Restriction rest;
      ClassDef def;
    case (CLASS(name = id,partialPrefix = p,encapsulatedPrefix = en,restriction = rest,classDef = def))
      equation
        s = printClassdefStr(def);
        re = restrString(rest);
        res = System.stringAppendList({"CLASS(",id,",_,_,",re,",",s,")\n"});
      then
        res;
  end matchcontinue;
end printClassStr;

public function printClassdefStr
"function printClassdefStr
  prints the class definition to a string"
  input ClassDef inClassDef;
  output String outString;
algorithm
  outString := matchcontinue (inClassDef)
    local
      list<String> elts_str;
      String s1,res,s2,s3,baseClassName;
      list<Element> elts;
      list<Equation> eqns,ieqns;
      list<AlgorithmSection> alg,ial;
      Option<Absyn.ExternalDecl> ext;
      Absyn.TypeSpec typeSpec;
      Mod mod;
      list<Enum> enumLst;
      list<Absyn.Path> plst;
      Absyn.Path path;
      list<String> slst;
      
    case (PARTS(elementLst = elts,
                normalEquationLst = eqns,
                initialEquationLst = ieqns,
                normalAlgorithmLst = alg,
                initialAlgorithmLst = ial,
                externalDecl = ext))
      equation
        elts_str = Util.listMap(elts, printElementStr);
        s1 = Util.stringDelimitList(elts_str, ",\n");
        res = System.stringAppendList({"PARTS(\n",s1,",_,_,_,_,_)"});
      then
        res;
    /* adrpo: handle also the case: model extends X end X; */
    case (CLASS_EXTENDS(
              baseClassName = baseClassName,
              modifications = mod,
              elementLst = elts,
              normalEquationLst = eqns,
              initialEquationLst = ieqns,
              normalAlgorithmLst = alg,
              initialAlgorithmLst = ial))
      equation
        elts_str = Util.listMap(elts, printElementStr);
        s1 = Util.stringDelimitList(elts_str, ",\n");
        res = System.stringAppendList({"CLASS_EXTENDS(", baseClassName, " PARTS(\n",s1,",_,_,_,_,_)"});
      then
        res;
    case (DERIVED(typeSpec = typeSpec,modifications = mod))
      equation
        s2 = Dump.unparseTypeSpec(typeSpec);
        s3 = printModStr(mod);
        res = System.stringAppendList({"DERIVED(",s2,",",s3,")"});
      then
        res;
    case (ENUMERATION(enumLst, _))
      equation
        s1 = Util.stringDelimitList(Util.listMap(enumLst, printEnumStr), ", ");
        res = System.stringAppendList({"ENUMERATION(", s1, ")"});
      then
        res;
    case (OVERLOAD(plst, _))
      equation
        s1 = Util.stringDelimitList(Util.listMap(plst, Absyn.pathString), ", ");
        res = System.stringAppendList({"OVERLOAD(", s1, ")"});
      then
        res;
    case (PDER(path, slst, _))
      equation
        s1 = Absyn.pathString(path);
        s2 = Util.stringDelimitList(slst, ", ");
        res = System.stringAppendList({"PDER(", s1, ", ", s2, ")"});
      then
        res;
    case (_)
      equation
        res = "SCode.printClassdefStr -> UNKNOWN_CLASS(CheckME)";
      then
        res;        
  end matchcontinue;
end printClassdefStr;

public function printEnumStr
  input Enum en;
  output String str;
algorithm
  str := matchcontinue(en)
    local
      String s;
    case ENUM(s, _) then s;
  end matchcontinue;
end printEnumStr;

public function attrVariability
"function attrVariability
  Return the variability attribute from Attributes"
  input Attributes attr;
  output Variability var;
algorithm
  var := matchcontinue (attr)
    local Variability v;
    case	ATTR(variability = v) then v;
  end matchcontinue;
end attrVariability;

public function variabilityString
"function: variabilityString
  Print Variability to a string."
  input Variability inVariability;
  output String outString;
algorithm
  outString := matchcontinue (inVariability)
    case (VAR()) then "VAR";
    case (DISCRETE()) then "DISCRETE";
    case (PARAM()) then "PARAM";
    case (CONST()) then "CONST";
  end matchcontinue;
end variabilityString;

public function innerouterString
"function: innerouterString
  Print a inner outer info to a string."
  input Absyn.InnerOuter innerOuter;
  output String outString;
algorithm
  outString := matchcontinue (innerOuter)
    case (Absyn.INNEROUTER()) then "INNER/OUTER";
    case (Absyn.INNER()) then "INNER";
    case (Absyn.OUTER()) then "OUTER";
    case (Absyn.UNSPECIFIED()) then "";
  end matchcontinue;
end innerouterString;

public function unparseVariability
"function: variabilityString
  Print Variability to a string."
  input Variability inVariability;
  output String outString;
algorithm
  outString := matchcontinue (inVariability)
    case (VAR()) then "";
    case (DISCRETE()) then "discrete";
    case (PARAM()) then "parameter";
    case (CONST()) then "constant";
  end matchcontinue;
end unparseVariability;

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
    case(CLASSDEF(classDef = CLASS(classDef = CLASS_EXTENDS(baseClassName = _)))) then false;
    case(_) then true;
  end matchcontinue;
end isNotElementClassExtends;

public function isParameterOrConst
"function: isParameterOrConst
  Returns true if Variability indicates a parameter or constant."
  input Variability inVariability;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVariability)
    case (VAR()) then false;
    case (DISCRETE()) then false;
    case (PARAM()) then true;
    case (CONST()) then true;
  end matchcontinue;
end isParameterOrConst;

public function isConstant
"function: isConstant
  Returns true if Variability is constant, otherwise false"
  input Variability inVariability;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVariability)
    case (VAR()) then false;
    case (DISCRETE()) then false;
    case (PARAM()) then false;
   case (CONST()) then true;
  end matchcontinue;
end isConstant;

public function countParts
"function: countParts
  Counts the number of ClassParts of a Class."
  input Class inClass;
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
    case CLASS(classDef = CLASS_EXTENDS(elementLst = elts))
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
  input Class inClass;
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
    case (CLASS(classDef = CLASS_EXTENDS(elementLst = elts)))
      equation
        res = componentNamesFromElts(elts);
      then
        res;
    case (_) then {};
  end matchcontinue;
end componentNames;

public function elementName ""
input Element e;
output String s;
algorithm
  s := matchcontinue(e)
    case(COMPONENT(component = s)) then s;
    case(CLASSDEF(name = s)) then s;
  end matchcontinue;
end elementName;

public function enumName ""
input Enum e;
output String s;
algorithm
  s := matchcontinue(e)
    case(ENUM(literal = s)) then s;
  end matchcontinue;
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
    case ((COMPONENT(component = id) :: rest))
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
  input Class inClass;
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
  input Class inClass;
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
  input Class inClass;
  input Boolean inBoolean;
  output Class outClass;
algorithm
  outClass := matchcontinue (inClass,inBoolean)
    local
      String id;
      Boolean enc,partialPrefix;
      Restriction restr;
      ClassDef def;
      Absyn.Info info;

    case (CLASS(name = id,encapsulatedPrefix = enc,restriction = restr,classDef = def, info = info),partialPrefix)
      then CLASS(id,partialPrefix,enc,restr,def,info);
  end matchcontinue;
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
      Class cl1,cl2;
      Boolean b1,b1a,b1b,b2,b3,b4,b5,b6,b7,f1,f2,r1,r2,p1,p2;
      Absyn.InnerOuter io,io2;
      Attributes attr1,attr2; Mod mod1,mod2;
      Absyn.TypeSpec tp1,tp2;
      Absyn.Import im1,im2;
      Absyn.Path path1, path2;
      Option<String> os1,os2;
      Option<Real> or1,or2;
      Option<Absyn.Exp> cond1, cond2;
      Option<Absyn.ConstrainClass> cc1, cc2;
      
     case (CLASSDEF(name1,f1,r1,cl1,_),CLASSDEF(name2,f2,r2,cl2,_))
       equation
         b1 = stringEqual(name1,name2);
         b2 = Util.boolEqual(f1,f2);
         b3 = Util.boolEqual(r1,r2);
         b3 = classEqual(cl1,cl2);
         equal = Util.boolAndList({b1,b2,b3});
       then equal;
     case (COMPONENT(name1,io,f1,r1,p1,attr1,tp1,mod1,_,cond1,_,cc1), COMPONENT(name2,io2,f2,r2,p2,attr2,tp2,mod2,_,cond2,_,cc2))
       equation
         equality(cond1 = cond2);
         equality(cc1 = cc2); // TODO! FIXME! this might fail for different comments!
         b1 = stringEqual(name1,name2);
         b1a = ModUtil.innerOuterEqual(io,io2);
         b2 = Util.boolEqual(f1,f2);
         b3 = Util.boolEqual(r1,r2);
         b4 = Util.boolEqual(p1,p2);
         b5 = attributesEqual(attr1,attr2);
         b6 = modEqual(mod1,mod2);
         b7 = Absyn.typeSpecEqual(tp1,tp2);
         equal = Util.boolAndList({b1,b1a,b2,b3,b4,b5,b6,b7});
         then equal;
     case (EXTENDS(path1,mod1,_), EXTENDS(path2,mod2,_))      
       equation
         b1 = ModUtil.pathEqual(path1,path2);
         b2 = modEqual(mod1,mod2);
         equal = Util.boolAndList({b1,b2});
       then equal;
     case (IMPORT(im1), IMPORT(im2))      
       equation
         equal = Absyn.importEqual(im1,im2);
       then equal;
     case (DEFINEUNIT(name1,os1,or1), DEFINEUNIT(name2,os2,or2))      
       equation
         b1 = stringEqual(name1,name2);
         equality(os1 = os2);
         equality(or1 = or2);
       then b1;
     case(_,_) then false;
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

public function classEqual
"function classEqual
  returns true if two classes are equal"
  input Class class1;
  input Class class2;
  output Boolean equal;
algorithm
  equal := matchcontinue(class1,class2)
    local
      Ident name1,name2;
      Boolean p1,e1,p2,e2,b1,b2,b3,b4,b5;
      Restriction restr1,restr2;
      ClassDef parts1,parts2;
      Absyn.Info info1,info2;
    case (CLASS(name1,p1,e1,restr1,parts1,info1), CLASS(name2,p2,e2,restr2,parts2,info2))
        equation
          b1 = stringEqual(name1,name2);
          b2 = Util.boolEqual(p1,p2);
          b3 = Util.boolEqual(e1,e2);
          b4 = restrictionEqual(restr1,restr2);
          b5 = classDefEqual(parts1,parts2);
          equal = Util.boolAndList({b1,b2,b3,b4,b5});
        then equal;
  end matchcontinue;
end classEqual;

public function restrictionEqual "Returns true if two Restriction's are equal."
  input Restriction restr1;
  input Restriction restr2;
  output Boolean equal;
algorithm
   equal := matchcontinue(restr1,restr2)
     case (R_CLASS(),R_CLASS()) then true;
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
  isEqual := matchcontinue(e1, e2)
    local
      String s1, s2;
      Boolean b1, b2;

    case (ENUM(s1,_), ENUM(s2,_))
      equation
        b1 = stringEqual(s1, s2);
        // ignore comments here.
      then b1;
  end matchcontinue;
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
         list<Boolean> blst1,blst2,blst3,blst4,blst5,blst6,blst;
         Absyn.ElementAttributes attr1,attr2;
         Absyn.TypeSpec tySpec1, tySpec2;
         Absyn.Path p1, p2;
         Mod mod1,mod2;
         Boolean b1,b2,b3;
         list<Enum> elst1,elst2;
         list<Ident> ilst1,ilst2;
         list<Boolean> blst;
         String bcName1, bcName2;

     case(PARTS(elts1,eqns1,ieqns1,algs1,ialgs1,_,anns1,_),
          PARTS(elts2,eqns2,ieqns2,algs2,ialgs2,_,anns2,_))
       equation
         blst1 = Util.listThreadMap(elts1,elts2,elementEqual);
         blst2 = Util.listThreadMap(eqns1,eqns2,equationEqual);
         blst3 = Util.listThreadMap(ieqns1,ieqns2,equationEqual);
         blst4 = Util.listThreadMap(algs1,algs2,algorithmEqual);
         blst5 = Util.listThreadMap(ialgs1,ialgs2,algorithmEqual);
         // adrpo: ignore annotations!
         // blst6 = Util.listThreadMap(anns1,anns2,annotationEqual);
         blst = Util.listFlatten({blst1,blst2,blst3,blst4,blst5/*,blst6*/});
         equal = Util.boolAndList(blst);
       then equal;

     case (DERIVED(tySpec1,mod1,attr1,_),
           DERIVED(tySpec2,mod2,attr2,_))
       equation
         b1 = ModUtil.typeSpecEqual(tySpec1, tySpec2);
         b2 = modEqual(mod1,mod2);
         b3 = Util.isEqual(attr1,attr2);
         equal = Util.boolAndList({b1,b2,b3});
       then equal;

     case (ENUMERATION(elst1,_),ENUMERATION(elst2,_))
       equation
         blst = Util.listThreadMap(elst1,elst2,enumEqual);
         equal = Util.boolAndList(blst);
       then equal;

    case (cdef1 as CLASS_EXTENDS(bcName1,mod1,elts1,eqns1,ieqns1,algs1,ialgs1,anns1,_),
          cdef2 as CLASS_EXTENDS(bcName2,mod2,elts2,eqns2,ieqns2,algs2,ialgs2,anns2,_))
      equation
         blst1 = Util.listThreadMap(elts1,elts2,elementEqual);
         blst2 = Util.listThreadMap(eqns1,eqns2,equationEqual);
         blst3 = Util.listThreadMap(ieqns1,ieqns2,equationEqual);
         blst4 = Util.listThreadMap(algs1,algs2,algorithmEqual);
         blst5 = Util.listThreadMap(ialgs1,ialgs2,algorithmEqual);
         b1 = stringEqual(bcName1,bcName2);
         b2 = modEqual(mod1,mod2);
         // adrpo: ignore annotations!
         // blst6 = Util.listThreadMap(anns1,anns2,annotationEqual);
         blst = Util.listFlatten({{b1,b2},blst1,blst2,blst3,blst4,blst5/*,blst6*/});
         equal = Util.boolAndList(blst);
      then
        equal;

    case (cdef1 as PDER(p1,ilst1,_),cdef2 as PDER(p2,ilst2,_))
      equation
         blst = Util.listThreadMap(ilst1,ilst2,stringEqual);
         equal = Util.boolAndList(blst);
       then equal;
    // adrpo: TODO! FIXME! are these below really needed??!!
    // as far as I can tell we handle all the cases.
    case(cdef1, cdef2)
      equation
        equality(cdef1=cdef2);
      then true;

    case(cdef1, cdef2)
      equation
        failure(equality(cdef1=cdef2));
      then false;
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
        blst = Util.listThreadMap(lst1,lst2,subscriptEqual);
        equal = Util.boolAndList(blst);
      then equal;
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
    case(Absyn.NOSUB,Absyn.NOSUB) then true;
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
      list<Boolean> blst;
    case(ALGORITHM(a1),ALGORITHM(a2))
      equation
        blst = Util.listThreadMap(a1,a2,algorithmEqual2);
        equal = Util.boolAndList(blst);
      then equal;
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
  equal := matchcontinue(eqn1,eqn2)
    local EEquation eq1,eq2;
    case (EQUATION(eq1),EQUATION(eq2))
      equation
        equal = equationEqual2(eq1,eq2);
        then equal;
  end matchcontinue;
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
      list<Boolean> blst1,blst2,blst3,blst;
      Absyn.Exp e11,e12,e21,e22,exp1,exp2,c1,c2,m1,m2,e1,e2;
      Boolean b1,b2;
      Absyn.ComponentRef cr11,cr12,cr21,cr22,cr1,cr2;
      Absyn.Ident id1,id2;
      list<EEquation> fb1,fb2,eql1,eql2,elst1,elst2;

    case (EQ_IF(condition = ifcond1, thenBranch = tb1, elseBranch = fb1),EQ_IF(condition = ifcond2, thenBranch = tb2, elseBranch = fb2))
      equation
        blst1 = equationEqual22(tb1,tb2);//Util.listThreadMap(tb1,tb2,equationEqual2);
        blst2 = Util.listThreadMap(fb1,fb2,equationEqual2);
        blst3 = Util.listThreadMap(ifcond1,ifcond2,Absyn.expEqual);
        blst = Util.listFlatten({blst1,blst2,blst3});
        equal = Util.boolAndList(blst);
      then equal;
    case(EQ_EQUALS(expLeft = e11, expRight = e12),EQ_EQUALS(expLeft = e21, expRight = e22))
      equation
        b1 = Absyn.expEqual(e11,e21);
        b2 = Absyn.expEqual(e12,e22);
        equal = boolAnd(b1,b2);
      then equal;
    case(EQ_CONNECT(crefLeft = cr11, crefRight = cr12),EQ_CONNECT(crefLeft = cr21, crefRight = cr22))
      equation
        b1 = Absyn.crefEqual(cr11,cr21);
        b2 = Absyn.crefEqual(cr12,cr22);
        equal = boolAnd(b1,b2);
      then equal;
    case (EQ_FOR(index = id1, range = exp1, eEquationLst = eql1),EQ_FOR(index = id2, range = exp2, eEquationLst = eql2))
      equation
        blst1 = Util.listThreadMap(eql1,eql2,equationEqual2);
        b1 = Absyn.expEqual(exp1,exp2);
        b2 = stringEqual(id1,id2);
        equal = Util.boolAndList(b1::b2::blst1);
      then equal;
    case (EQ_WHEN(condition = cond1, eEquationLst = elst1),EQ_WHEN(condition = cond2, eEquationLst = elst2)) // TODO: elsewhen not checked yet.
      equation
        blst1 = Util.listThreadMap(elst1,elst2,equationEqual2);
        b1 = Absyn.expEqual(cond1,cond2);
        equal = Util.boolAndList(b1::blst1);
      then equal;
    case (EQ_ASSERT(condition = c1, message = m1),EQ_ASSERT(condition = c2, message = m2))
      equation
        b1 = Absyn.expEqual(c1,c2);
        b2 = Absyn.expEqual(m1,m2);
        equal = boolAnd(b1,b2);
      then equal;
    case (EQ_REINIT(cref = cr1, expReinit = e1),EQ_REINIT(cref = cr2, expReinit = e2))
      equation
        b1 = Absyn.expEqual(e1,e2);
        b2 = Absyn.crefEqual(cr1,cr2);
        equal = boolAnd(b1,b2);
      then equal;
    case(_,_) then false;
  end matchcontinue;
end equationEqual2;

protected function equationEqual22
"Author BZ
 Helper function for equationEqual2, does compare list<list<equation>> (else ifs in ifequations.)"
  input list<list<EEquation>> tb1;
  input list<list<EEquation>> tb2;
  output list<Boolean> blist;
algorithm
  blist := matchcontinue(tb1,tb2)
    local list<Boolean> blist1,blist2;
    case({},{}) then {};
    case(_,{}) then {false};
    case({},_) then {false};
    case(tb_1::tb1,tb_2::tb2)
      local
        list<EEquation> tb_1,tb_2;
      equation
        blist1 = Util.listThreadMap(tb_1,tb_2,equationEqual2);
        blist2 = equationEqual22(tb1,tb2);
        blist1 = listAppend(blist1,blist2);
      then
        blist1;
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
      Boolean f1,f2,b1,b2,b3,b4;
      Absyn.Each each1,each2;
      list<SubMod> submodlst1,submodlst2;
      Absyn.Exp e1,e2;
      list<Element> elts1,elts2;
      list<Boolean> blst;

    case (MOD(f1,each1,submodlst1,SOME((e1,_))),MOD(f2,each2,submodlst2,SOME((e2,_))))
      equation
        b1 = Util.boolEqual(f1,f2);
        b2 = Absyn.eachEqual(each1,each2);
        b3 = subModsEqual(submodlst1,submodlst2);
        b4 = Absyn.expEqual(e1,e2);
        equal = Util.boolAndList({b1,b2,b3,b4});
      then equal;
    case (MOD(f1,each1,submodlst1,_),MOD(f2,each2,submodlst2,_))
      equation
        b1 = Util.boolEqual(f1,f2);
        b2 = Absyn.eachEqual(each1,each2);
        b3 = subModsEqual(submodlst1,submodlst2);
        equal = Util.boolAndList({b1,b2,b3});
      then equal;
    case (NOMOD(),NOMOD()) then true;
    case (REDECL(f1,elts1),REDECL(f2,elts2))
      equation
        b1 = Util.boolEqual(f1,f2);
        blst = Util.listThreadMap(elts1,elts2,elementEqual);
        equal = Util.boolAndList(b1::blst);
      then equal;
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
      Boolean b1,b2,b3;
      list<Subscript> ss1,ss2;

    case ({},{}) then true;
    case (NAMEMOD(id1,mod1)::subModLst1,NAMEMOD(id2,mod2)::subModLst2)
        equation
          b1 = stringEqual(id1,id2);
          b2 = modEqual(mod1,mod2);
          b3 = subModsEqual(subModLst1,subModLst2);
          equal = Util.boolAndList({b1,b2,b3});
        then equal;
    case (IDXMOD(ss1,mod1)::subModLst1,IDXMOD(ss2,mod2)::subModLst2)
        equation
          b1 = subscriptsEqual(ss1,ss2);
          b2 = modEqual(mod1,mod2);
          b3 = subModsEqual(subModLst1,subModLst2);
          equal = Util.boolAndList({b1,b2,b3});
        then equal;
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
      Boolean b1,b2;
      Absyn.Exp e1,e2;

    case({},{}) then true;
    case(Absyn.NOSUB()::ss1,Absyn.NOSUB()::ss2)
      then subscriptsEqual(ss1,ss2);
    case(Absyn.SUBSCRIPT(e1)::ss1,Absyn.SUBSCRIPT(e2)::ss2)
      equation
        b1 = Absyn.expEqual(e1,e2);
        b2 = subscriptsEqual(ss1,ss2);
        equal = Util.boolAndList({b1,b2});
        then equal;
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
    case(ATTR(ad1,fl1,st1,acc1,var1,dir1),ATTR(ad2,fl2,st2,acc2,var2,dir2))
      local Accessibility acc1,acc2;
        Variability var1,var2;
        Boolean fl1,fl2,st1,st2,b1,b2,b3,b4,b5,b6;
        Absyn.ArrayDim ad1,ad2;
        Absyn.Direction dir1,dir2;
      equation
        	b1 = arrayDimEqual(ad1,ad2);
        	b2 = Util.boolEqual(fl1,fl2);
        	b3 = accessibilityEqual(acc1,acc2);
        	b4 = variabilityEqual(var1,var2);
        	b5 = directionEqual(dir1,dir2);
          b6 = Util.boolEqual(st1,st2);  // added Modelica 3.1 stream connectors
        	equal = Util.boolAndList({b1,b2,b3,b4,b5,b6});
        then equal;
  end matchcontinue;
end attributesEqual;

protected function accessibilityEqual
"function accessibilityEqual
  Returns true if two  Accessibliy properties are equal"
  input Accessibility acc1;
  input Accessibility acc2;
  output Boolean equal;
algorithm
  equal := matchcontinue(acc1,acc2)
    case(RW(), RW()) then true;
    case(RO(), RO()) then true;
    case(WO(), WO()) then true;
    case(_, _) then false;
  end matchcontinue;
end accessibilityEqual;

protected function variabilityEqual
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
      local Boolean b1; Absyn.Exp e1,e2;
     case({},{}) then true;
     case (Absyn.NOSUB()::ad1, Absyn.NOSUB()::ad2) equation
       equal = arrayDimEqual(ad1,ad2);
       then equal;
     case (Absyn.SUBSCRIPT(e1)::ad1,Absyn.SUBSCRIPT(e2)::ad2)
       local Absyn.Exp e1,e2; Boolean b1,b2;
       equation
         b1 = Absyn.expEqual(e1,e2);
         b2 =  arrayDimEqual(ad1,ad2);
         equal = Util.boolAndList({b1,b2});
         then equal;
     case(_,_) then false;
   end matchcontinue;
end arrayDimEqual;

public function equationStr2
"Takes a SCode.Equation rather then EEquation as equationStr does."
  input Equation eqns;
  output String s;
algorithm
  s := matchcontinue(eqns)
    local EEquation e;
    case(EQUATION(eEquation=e)) then equationStr(e);
  end matchcontinue;
end equationStr2;

protected function elseIfEquationStr
"Author BZ, 2008-09
 Function for printing elseif statements to string."
  input list<Absyn.Exp> conditions;
  input list<list<EEquation>> elseIfBodies;
  output String elseIfString;
algorithm
  elseIfString := matchcontinue(conditions,elseIfBodies)
    local
      Absyn.Exp cond;
      list<EEquation> eib;
      String conString, bodyString,recString,resString;
      list<String> bodyStrings;
    case({},{}) then "";
    case(cond::conditions,eib::elseIfBodies)
      equation
        conString = Dump.printExpStr(cond);
        bodyStrings = Util.listMap(eib, equationStr);
        bodyString = Util.stringDelimitList(bodyStrings, "\n");
        recString = elseIfEquationStr(conditions,elseIfBodies);
        recString = Util.if_(Util.isEmptyString(recString), "", "\n" +& recString);
        resString = " elseif " +& conString +& " then\n" +& bodyString +& recString;
      then
        resString;
  end matchcontinue;
end elseIfEquationStr;

public function setClassRestriction "Sets the restriction of a SCode Class"
  input Restriction r;
  input Class cl;
  output Class outCl;
algorithm
  outCl := matchcontinue(r,cl)
  local ClassDef parts; Boolean p,e; Ident id; Absyn.Info info;
    case(r,CLASS(id,p,e,_,parts,info)) then CLASS(id,p,e,r,parts,info);
  end matchcontinue;
end setClassRestriction;

public function setClassPartialPrefix "Sets the partial prefix of a SCode Class"
  input Boolean partialPrefix;
  input Class cl;
  output Class outCl;
algorithm
  outCl := matchcontinue(partialPrefix,cl)
    local 
      ClassDef parts; 
      Boolean e; 
      Ident id; 
      Absyn.Info info; 
      Restriction restriction;    
    case(partialPrefix,CLASS(id,_,e,restriction,parts,info)) then CLASS(id,partialPrefix,e,restriction,parts,info);
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
      list<tuple<Absyn.ComponentRef, Integer>> lst,lst_1,lst_2,lst_3,lst_4;
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
          false = stringEqual(id, id_1);
          lst_1=Absyn.findIteratorInExp(id,e_1);
          lst_2=findIteratorInEEquationLst(id,eeqLst);
          lst=listAppend(lst_1,lst_2);
        then lst;
      case (id,EQ_FOR(index = id_1, range = e_1, eEquationLst = eeqLst))
        equation
          true = stringEqual(id, id_1);
          lst=Absyn.findIteratorInExp(id,e_1);
        then lst;
      case (id,EQ_WHEN(condition = e_1, eEquationLst = eeqLst, tplAbsynExpEEquationLstLst = ew))
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
    outLst:=matchcontinue(inString,inEEqLst)
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
  end matchcontinue;
end findIteratorInEEquationLst;

protected function findIteratorInEEquationLstLst
//This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<list<EEquation>> inEEqLstLst;
  output list<tuple<Absyn.ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inEEqLstLst)
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
  end matchcontinue;
end findIteratorInEEquationLstLst;

protected function findIteratorInElsewhen
//This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<tuple<Absyn.Exp, list<EEquation>>> inElsewhen;
  output list<tuple<Absyn.ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inElsewhen)
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
  end matchcontinue;
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
    case (( comp as COMPONENT(component=name)) :: rest)
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
  input Class cl;
  output list<Element> compElts;
  output list<String> compNames;
algorithm
  (compElts,compNames) := matchcontinue (cl)
    local
      list<Element> elts, comps;
      list<String> names;

    case (CLASS(classDef = PARTS(elementLst = elts)))
      equation
        (comps, names) = filterComponents(elts);
      then (comps,names);
    case (CLASS(classDef = CLASS_EXTENDS(elementLst = elts)))
      equation
        (comps, names) = filterComponents(elts);
      then (comps,names);
  end matchcontinue;
end getClassComponents;

public function printInitialStr
"prints SCode.Initial to a string"
  input Initial initial_;
  output String str;
algorithm
  str := matchcontinue(initial_)
    case (INITIAL()) then "initial";
    case (NON_INITIAL()) then "non initial";
  end matchcontinue;
end printInitialStr;

public function makeEnumType
  "Creates an EnumType element from an enumeration literal and an optional
  comment."
  input Enum enum;
  input Absyn.Info info;
  output Element enum_type;
algorithm
  enum_type := matchcontinue(enum, info)
    local
      String literal;
      Option<Comment> comment;
    case (ENUM(literal = literal, comment = comment), _)
      equation
        isValidEnumLiteral(literal);
      then 
        COMPONENT(
          literal, Absyn.UNSPECIFIED(), true, false, false,
          ATTR({}, false, false, RO(), CONST(), Absyn.BIDIR()),
          Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()), 
          NOMOD(), comment,NONE(), NONE(),NONE());
    case (ENUM(literal = literal), _)
      local
        String info_str;
      equation
        info_str = Error.infoStr(info);
        Error.addMessage(Error.INVALID_ENUM_LITERAL, {info_str, literal});
      then fail();
  end matchcontinue;
end makeEnumType;

public function isValidEnumLiteral
  "Checks if a string is a valid enumeration literal."
  input String literal;
algorithm
  true := Util.listNotContains(literal, {"quantity", "min", "max", "start", "fixed"});
end isValidEnumLiteral;

public function variabilityOr 
"returns the more constant of two Variabilities (considers VAR < DISCRETE < PARAM < CONST ), similarly to Types.constOr"
  input Variability inConst1;
  input Variability inConst2;
  output Variability outConst;
algorithm
outConst := matchcontinue(inConst1, inConst2)
  case (CONST,_) then CONST;   
  case (_,CONST) then CONST;   
  case (PARAM,_) then PARAM;   
  case (_,PARAM) then PARAM;   
  case (DISCRETE,_) then DISCRETE;   
  case (_,DISCRETE) then DISCRETE;
  case (_,_) then VAR;
  end matchcontinue;
end variabilityOr;

public function statementToAlgorithmItem
"Transforms SCode.Statement back to Absyn.AlgorithmItem. Discards the comment.
Only to be used to unparse statements again."
  input Statement stmt;
  output Absyn.AlgorithmItem algi; 
algorithm
  algi := matchcontinue stmt
    local
      Absyn.ComponentRef functionCall;
      Absyn.Exp assignComponent;
      Absyn.Exp boolExpr;
      Absyn.Exp value;
      Absyn.ForIterators iterators;
      Absyn.FunctionArgs functionArgs;
      Absyn.Info info;
      list<Absyn.Exp> inputExps,switchCases,conditions;
      list<list<Statement>> stmtsList;
      list<Statement> body,trueBranch,elseBranch;
      list<tuple<Absyn.Exp, list<Statement>>> branches;
      Option<Comment> comment;
      Statement equ;
      String labelName;
      Absyn.AlgorithmItem alg;
      list<Absyn.AlgorithmItem> algs1,algs2;
      list<list<Absyn.AlgorithmItem>> algsLst;
      list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> abranches;
      Absyn.MatchType matchType;
      
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
    
    case ALG_MATCHCASES(matchType,inputExps,switchCases,comment,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_MATCHCASES(matchType,inputExps,switchCases),NONE(),info);
      
    case ALG_GOTO(labelName,comment,info)
    then Absyn.ALGORITHMITEM(Absyn.ALG_GOTO(labelName),NONE(),info);
    
    case ALG_FAILURE(equ,comment,info)
      equation
        alg = statementToAlgorithmItem(equ);
      then Absyn.ALGORITHMITEM(Absyn.ALG_FAILURE(alg),NONE(),info);
  end matchcontinue;
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
      Statement algItem;
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
    outLst := matchcontinue(inString,inAlgItemLst)
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
  end matchcontinue;
end findIteratorInStatements;

protected function findIteratorInElseIfBranch //This function is not tail-recursive, and I don't know how to fix it -- alleb
  input String inString;
  input list<tuple<Absyn.Exp, list<Statement>>> inElseIfBranch;
  output list<tuple<Absyn.ComponentRef, Integer>> outLst;
algorithm
    outLst:=matchcontinue(inString,inElseIfBranch)
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
  end matchcontinue;
end findIteratorInElseIfBranch;

public function equationFileInfo
  input EEquation eq;
  output Absyn.Info info;
algorithm
  info := matchcontinue eq
    case EQ_IF(info=info) then info;
    case EQ_EQUALS(info=info) then info;
    case EQ_CONNECT(info=info) then info;
    case EQ_FOR(info=info) then info;
    case EQ_WHEN(info=info) then info;
    case EQ_ASSERT(info=info) then info;
    case EQ_TERMINATE(info=info) then info;
    case EQ_REINIT(info=info) then info;
    case EQ_NORETCALL(info=info) then info;
  end matchcontinue;
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

end SCode;

