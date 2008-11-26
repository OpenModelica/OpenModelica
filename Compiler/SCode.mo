/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
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

  This module contains data structures to describe a Modelica model
  in a more convenient way than the `Absyn\' module does.  The most
  important function in this module is the `elaborate\' function
  which turns an abstract syntax tree into an SCode representation.

  The SCode representation is used as input to the Inst module"

public import Absyn;

public
type Ident = Absyn.Ident "Some definitions are borrowed from `Absyn\'" ;

public
type Path = Absyn.Path;

public
type Subscript = Absyn.Subscript;

public
uniontype Restriction
  record R_CLASS end R_CLASS;

  record R_MODEL end R_MODEL;

  record R_RECORD end R_RECORD;

  record R_BLOCK end R_BLOCK;

  record R_CONNECTOR end R_CONNECTOR;

  record R_TYPE end R_TYPE;

  record R_PACKAGE end R_PACKAGE;

  record R_FUNCTION end R_FUNCTION;

  record R_EXT_FUNCTION "Added c.t. Absyn" end R_EXT_FUNCTION;

  record R_ENUMERATION end R_ENUMERATION;

  record R_PREDEFINED_INT end R_PREDEFINED_INT;

  record R_PREDEFINED_REAL end R_PREDEFINED_REAL;

  record R_PREDEFINED_STRING end R_PREDEFINED_STRING;

  record R_PREDEFINED_BOOL end R_PREDEFINED_BOOL;

  record R_PREDEFINED_ENUM end R_PREDEFINED_ENUM;

end Restriction;

public
uniontype Mod "- Modifications"
  record MOD
    Boolean final_ "final" ;
    Absyn.Each each_;
    list<SubMod> subModLst;
    Option<tuple<Absyn.Exp,Boolean>> absynExpOption "The binding expression of a modification
    has an expression and a Boolean delayElaboration which is true if elaboration(type checking)
    should be delayed. This can for instance be used when having A a(x = a.y) where a.y can not be
    type checked -before- a is instantiated, which is the current design in instantiation process.";
  end MOD;

  record REDECL
    Boolean final_ "final" ;
    list<Element> elementLst;
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
  record CLASS
    Ident name "Name" ;
    Boolean partial_ "Partial" ;
    Boolean encapsulated_ "Encapsulated" ;
    Restriction restriction "Restricion" ;
    ClassDef parts "Parts" ;
  end CLASS;

end Class;

public
uniontype ClassDef "
  The major difference between these types and their `Absyn\'
  counterparts is that the `PARTS\' constructor contains separate
  lists for elements, equations and algorithms.

  SCode.PARTS contains elements of a class definition. For instance,
    model A
      extends B;
      C c;
    end A;
  Here PARTS contains two elements ('extends B' and 'C c')
  SCode.DERIVED is used for short class definitions, i.e:
  class A = B(modifiers);
  "
  record PARTS
    list<Element> elementLst;
    list<Equation> equationLst;
    list<Equation> initialEquation "InitialEquation" ;
    list<Algorithm> algorithmLst;
    list<Algorithm> initialAlgorithm "InitialAlgorithm" ;
    Option<Absyn.ExternalDecl> used "Used by external functions" ;
  end PARTS;

  record DERIVED
    Absyn.TypeSpec typeSpec "typeSpec: type specification" ;
    Mod mod;
  end DERIVED;

  record ENUMERATION
    list<Ident> identLst;
  end ENUMERATION;

  record OVERLOAD
    list<Absyn.Path> absynPathLst;
  end OVERLOAD;

  record CLASS_EXTENDS
    Ident ident1;
    Mod mod2;
    list<Element> elementLst3;
    list<Equation> equationLst4;
    list<Equation> equationLst5;
    list<Algorithm> algorithmLst6;
    list<Algorithm> algorithmLst7;
  end CLASS_EXTENDS;

  record PDER
    Absyn.Path function_ "function name" ;
    list<Ident> derived "derived variables" ;
  end PDER;

end ClassDef;

public
uniontype Equation "- Equations"
  record EQUATION
    EEquation eEquation;
    Option<Absyn.Path> baseclassname "baseclassname if in bclass" ;
  end EQUATION;

end Equation;

public
uniontype EEquation "These are almost identical to the `Absyn\' versions.  In `EQ_IF\',
  the `elseif\' branches are represented as normal `else\' branches
  with a single `if\' statement in them."
  record EQ_IF
    Absyn.Exp conditional "conditional" ;
    list<EEquation> true_ "true branch" ;
    list<EEquation> false_ "false branch" ;
  end EQ_IF;

  record EQ_EQUALS
    Absyn.Exp exp1;
    Absyn.Exp exp2;
  end EQ_EQUALS;

  record EQ_CONNECT
    Absyn.ComponentRef componentRef1;
    Absyn.ComponentRef componentRef2;
  end EQ_CONNECT;

  record EQ_FOR
    Ident id;
    Absyn.Exp range;
    list<EEquation> eEquationLst;
  end EQ_FOR;

  record EQ_WHEN
    Absyn.Exp exp;
    list<EEquation> eEquationLst;
    list<tuple<Absyn.Exp, list<EEquation>>> tplAbsynExpEEquationLstLst;
  end EQ_WHEN;

  record EQ_ASSERT
    Absyn.Exp condition;
    Absyn.Exp message;
  end EQ_ASSERT;

  record EQ_TERMINATE
    Absyn.Exp message;
  end EQ_TERMINATE;

  record EQ_REINIT
    Absyn.ComponentRef componentRef;
    Absyn.Exp state "state variable the new value" ;
  end EQ_REINIT;

end EEquation;

public
uniontype Algorithm "- Algorithms
  The `Absyn\' module uses the terminology from the grammar, where
  `algorithm\' means an algorithmic statement.  But here,
  `Algorithm\' means a whole algorithm section."
  record ALGORITHM
    list<Absyn.Algorithm> absynAlgorithmLst;
    Option<Absyn.Path> baseclass "baseclass name if in baseclass" ;
  end ALGORITHM;

end Algorithm;

public
uniontype Element "- Elements
  There are four types of elements in a declaration, represented
  by the constructors `EXTENDS\' (for `extends\' clauses),
  `CLASSDEF\' (for local class definitions)  `COMPONENT\' (for
  local variables). and `IMPORT\' (for `import\' clauses)
  The baseclass name is initially NONE in the translation, and
    if an element is inherited from a base class it is filled in during the
    instantiation process."
  record EXTENDS
    Path path;
    Mod mod;
  end EXTENDS;

  record CLASSDEF
    Ident name "name" ;
    Boolean final_ "final" ;
    Boolean replaceable_ "replaceable" ;
    Class class_;
    Option<Path> baseclass "baseclass name if in baseclass" ;
  end CLASSDEF;

  record IMPORT
    Absyn.Import import_;
  end IMPORT;

  record COMPONENT
    Ident component "component name" ;
    Absyn.InnerOuter innerOuter;
    Boolean final_ "final" ;
    Boolean replaceable_ "replaceable" ;
    Boolean protected_ "protected" ;
    Attributes attributes;
    Absyn.TypeSpec typeSpec "typeSpec : type specification" ;
    Mod mod;
    Option<Path> baseclass "baseclass name if in baseclass" ;
    Option<Absyn.Comment> this "this if for extraction comments and annotations from Absyn" ;
  end COMPONENT;

end Element;

public
uniontype Attributes "- Attributes"
  record ATTR
    Absyn.ArrayDim arrayDim;
    Boolean flow_ "flow" ;
    Boolean stream_ "stream" ;
    Accessibility RW "RW, RO, WO" ;
    Variability parameter_ "parameter" ;
    Absyn.Direction input_ "input, output or bidirectional" ;
  end ATTR;

end Attributes;

public
uniontype Variability
  record VAR end VAR;

  record DISCRETE end DISCRETE;

  record PARAM end PARAM;

  record CONST end CONST;

end Variability;

public
uniontype Accessibility "These are attributes that apply to a declared component."
  record RW "read/write" end RW;

  record RO "read-only" end RO;

  record WO "write-only (not used)" end WO;

end Accessibility;

protected import Dump;
protected import Debug;
protected import Print;
protected import Util;
protected import Error;
protected import ModUtil;

public function elaborate "function: elaborate

  This function takes an `Absyn.Program\' and constructs a `Program\'
  from it.
"
  input Absyn.Program inProgram;
  output Program outProgram;
algorithm
  outProgram:=
  matchcontinue (inProgram)
    local
      Class c_1;
      Program cs_1;
      Absyn.Class c;
      list<Absyn.Class> cs;
      Absyn.Within w;
      Absyn.Program p;
    case (Absyn.PROGRAM(classes = {})) then {};
    case (Absyn.PROGRAM(classes = (c :: cs),within_ = w))
      equation
        c_1 = elabClass(c);
        cs_1 = elaborate(Absyn.PROGRAM(cs,w));
      then
        (c_1 :: cs_1);
    case (p)
      equation
        Debug.fprint("failtrace", "-elaborate failed\n");
      then
        fail();
  end matchcontinue;
end elaborate;

public function elabClass "function: elabClass

  This functions converts an `Absyn.Class\' to a `Class\'.
"
  input Absyn.Class inClass;
  output Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass)
    local
      ClassDef d_1;
      Restriction r_1;
      Absyn.Class c;
      String n;
      Boolean p,f,e;
      Absyn.Restriction r;
      Absyn.ClassDef d;
      Absyn.Info file_info;
    case ((c as Absyn.CLASS(name = n,partial_ = p,final_ = f,encapsulated_ = e,restriction = r,body = d,info = file_info)))
      equation
        //debug_print("elaborating-class:", n);
        r_1 = elabRestriction(c, r); // uniontype will not get elaborated!
        d_1 = elabClassdef(d);
      then
        CLASS(n,p,e,r_1,d_1);
  end matchcontinue;
end elabClass;

protected function elabRestriction "function: elabRestriction

  Convert a class restriction.
"
  input Absyn.Class inClass;
  input Absyn.Restriction inRestriction;
  output Restriction outRestriction;
algorithm
  outRestriction:=
  matchcontinue (inClass,inRestriction)
    local Absyn.Class d;
    case (d,Absyn.R_FUNCTION())
      equation
        true = containExternalFuncDecl(d);
      then
        R_EXT_FUNCTION();
    case (d,Absyn.R_FUNCTION())
      equation
        false = containExternalFuncDecl(d);
      then
        R_FUNCTION();
    case (_,Absyn.R_CLASS()) then R_CLASS();
    case (_,Absyn.R_MODEL()) then R_MODEL();
    case (_,Absyn.R_RECORD()) then R_RECORD();
    case (_,Absyn.R_BLOCK()) then R_BLOCK();
    case (_,Absyn.R_CONNECTOR()) then R_CONNECTOR();
    case (_,Absyn.R_EXP_CONNECTOR()) then R_CONNECTOR();  /* fixme */
    case (_,Absyn.R_TYPE()) then R_TYPE();  /* fixme */
    case (_,Absyn.R_PACKAGE()) then R_PACKAGE();
    case (_,Absyn.R_ENUMERATION()) then R_ENUMERATION();
    case (_,Absyn.R_PREDEFINED_INT()) then R_PREDEFINED_INT();
    case (_,Absyn.R_PREDEFINED_REAL()) then R_PREDEFINED_REAL();
    case (_,Absyn.R_PREDEFINED_STRING()) then R_PREDEFINED_STRING();
    case (_,Absyn.R_PREDEFINED_BOOL()) then R_PREDEFINED_BOOL();
    case (_,Absyn.R_PREDEFINED_ENUM()) then R_PREDEFINED_ENUM();
  end matchcontinue;
end elabRestriction;

protected function containExternalFuncDecl "function: containExternalFuncDecl

  Returns true if Class contains an external function declaration.
"
  input Absyn.Class inClass;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inClass)
    local
      Boolean res,b,c,d;
      String a;
      Absyn.Restriction e;
      list<Absyn.ClassPart> rest;
      Option<String> cmt;
      Absyn.Info file_info;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = (Absyn.EXTERNAL(externalDecl = _) :: _)))) then true;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restriction = e,body = Absyn.PARTS(classParts = (_ :: rest),comment = cmt),info = file_info))
      equation
        res = containExternalFuncDecl(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(rest,cmt),file_info));
      then
        res;
    case (_) then false;
  end matchcontinue;
end containExternalFuncDecl;

protected function elabClassdef "function: elabClassdef

  This function converts an `Absyn.ClassDef\' to a `ClassDef\'.  For
  the `DERIVED\' case, the conversion is fairly trivial, but for the
  `PARTS\' case more work is needed.  The result contains separate
  lists for elements, equations and algorithms, which are mixed in
  the input.

  LS: Divided the elabClassdef into separate functions for
  collecting the different parts
"
  input Absyn.ClassDef inClassDef;
  output ClassDef outClassDef;
algorithm
  outClassDef:=
  matchcontinue (inClassDef)
    local
      Mod mod;
      Absyn.TypeSpec t;
      Absyn.ElementAttributes attr;
      list<Absyn.ElementArg> a,cmod;
      Option<Absyn.Comment> cmt;
      list<Element> els;
      list<Equation> eqs,initeqs;
      list<Algorithm> als,initals;
      Option<Absyn.ExternalDecl> decl;
      list<Absyn.ClassPart> parts;
      list<String> lst_1,vars;
      list<Absyn.EnumLiteral> lst;
      String name;
      Absyn.Path path;
    case (Absyn.DERIVED(typeSpec = t,attributes = attr,arguments = a,comment = cmt))
      equation
        //debug_print("elaborating-derived:", t);
        mod = buildMod(SOME(Absyn.CLASSMOD(a,NONE)), false, Absyn.NON_EACH()) "TODO: attributes of derived classes" ;
      then
        DERIVED(t,mod);
    case (Absyn.PARTS(classParts = parts,comment = cmt))
      local Option<String> cmt;
      equation
        //debug_print("elaborating-parts:", Dump.unparseClassPartStrLst(1, parts, true));
        els = elabClassdefElements(parts);
        eqs = elabClassdefEquations(parts);
        initeqs = elabClassdefInitialequations(parts);
        als = elabClassdefAlgorithms(parts);
        initals = elabClassdefInitialalgorithms(parts);
        decl = elabClassdefExternaldecls(parts);
        decl = elabAlternativeExternalAnnotation(decl,parts);
      then
        PARTS(els,eqs,initeqs,als,initals,decl);
    case (Absyn.ENUMERATION(enumLiterals = Absyn.ENUMLITERALS(enumLiterals = lst)))
      equation
        lst_1 = elabEnumlist(lst);
      then
        ENUMERATION(lst_1);
    case (Absyn.ENUMERATION(enumLiterals = Absyn.ENUM_COLON())) then ENUMERATION({});
    case (Absyn.OVERLOAD(functionNames = lst))
      local list<Absyn.Path> lst;
      then
        OVERLOAD(lst);
    case (Absyn.CLASS_EXTENDS(name = name,arguments = cmod,comment = cmt,parts = parts))
      local Option<String> cmt;
      equation
        //debug_print("elaborating-extends:", name);
        els = elabClassdefElements(parts);
        eqs = elabClassdefEquations(parts);
        initeqs = elabClassdefInitialequations(parts);
        als = elabClassdefAlgorithms(parts);
        initals = elabClassdefInitialalgorithms(parts);
        mod = buildMod(SOME(Absyn.CLASSMOD(cmod,NONE)), false, Absyn.NON_EACH());
      then
        CLASS_EXTENDS(name,mod,els,eqs,initeqs,als,initals);
    case (Absyn.PDER(functionName = path,vars = vars)) then PDER(path,vars);
  end matchcontinue;
end elabClassdef;

protected function elabAlternativeExternalAnnotation "This function fills external declarations
without annotation with the first class annotation instead, since it is very common that an
element annotation is used for this purpose.

For instance, instead of
external \"C\" annotation(Library=\"foo.lib\";
it says
external \"C\" ;
annotation(Library=\"foo.lib\";
"
input Option<Absyn.ExternalDecl> decl;
input list<Absyn.ClassPart> parts;
output Option<Absyn.ExternalDecl> outDecl;
algorithm
  outDecl := matchcontinue(decl,parts)
    local
      Absyn.Annotation ann;
      Option<Ident> name ;
      Option<String> l ;
      Option<Absyn.ComponentRef> out ;
      list<Absyn.Exp> a;
      list<Absyn.ElementItem> els;
      list<Absyn.ClassPart> cls;
    case (NONE,_) then NONE;

      // Already filled.
    case (decl as SOME(Absyn.EXTERNALDECL(annotation_ = SOME(_))),_) then decl;

     // EXTERNALDECL.
    case (SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),Absyn.EXTERNAL(_,SOME(ann))::_)
    then SOME(Absyn.EXTERNALDECL(name,l,out,a,SOME(ann)));

			// Annotation item.
    case (SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),Absyn.PUBLIC(Absyn.ANNOTATIONITEM(ann)::_)::_)
    then SOME(Absyn.EXTERNALDECL(name,l,out,a,SOME(ann)));

    // Next element in public list
    case(decl as SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),Absyn.PUBLIC(_::els)::cls)
		then elabAlternativeExternalAnnotation(decl,Absyn.PUBLIC(els)::cls);

		// Next classpart list
    case (decl as SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),Absyn.PUBLIC({})::cls)
		then elabAlternativeExternalAnnotation(decl,cls);

		   case (SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),Absyn.PROTECTED(Absyn.ANNOTATIONITEM(ann)::_)::_)
    then SOME(Absyn.EXTERNALDECL(name,l,out,a,SOME(ann)));

    // Next element in public list
    case(decl as SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),Absyn.PROTECTED(_::els)::cls)
		then elabAlternativeExternalAnnotation(decl,Absyn.PROTECTED(els)::cls);

		// Next classpart list
    case(decl as SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),Absyn.PROTECTED({})::cls)
		then elabAlternativeExternalAnnotation(decl,cls);

	  // Next in list
		   case(decl as SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),_::cls)
		then elabAlternativeExternalAnnotation(decl,cls);

		// not found
    case (decl,_) then decl;
  end matchcontinue;
end elabAlternativeExternalAnnotation;

protected function elabEnumlist "function: elabEnumlist

  Convert an EnumLiteral list to an Ident list. Comments are lost.
"
  input list<Absyn.EnumLiteral> inAbsynEnumLiteralLst;
  output list<Ident> outIdentLst;
algorithm
  outIdentLst:=
  matchcontinue (inAbsynEnumLiteralLst)
    local
      list<String> res;
      String id;
      list<Absyn.EnumLiteral> rest;
    case ({}) then {};
    case ((Absyn.ENUMLITERAL(literal = id) :: rest))
      equation
        res = elabEnumlist(rest);
      then
        (id :: res);
  end matchcontinue;
end elabEnumlist;

protected function elabClassdefElements "function: elabClassdefElements

  Convert an Absyn.ClassPart list to an Element list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Element> outElementLst;
algorithm
  outElementLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Element> els,es_1,els_1;
      list<Absyn.ElementItem> es;
      list<Absyn.ClassPart> rest;
    case {} then {};
    case ((Absyn.PUBLIC(contents = es) :: rest))
      equation
        es_1 = elabEitemlist(es, false);
        els = elabClassdefElements(rest);
        els_1 = listAppend(es_1, els);
      then
        els_1;
    case ((Absyn.PROTECTED(contents = es) :: rest))
      equation
        es_1 = elabEitemlist(es, true);
        els = elabClassdefElements(rest);
        els_1 = listAppend(es_1, els);
      then
        els_1;
    case (_ :: rest) /* ignore all other than PUBLIC and PROTECTED, i.e. elements */
      equation
        els = elabClassdefElements(rest);
      then
        els;
  end matchcontinue;
end elabClassdefElements;

protected function elabClassdefEquations "function: elabClassdefEquations

  Convert an Absyn.ClassPart list to an Equation list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Equation> eqs,eql_1,eqs_1;
      list<Absyn.EquationItem> eql;
      list<Absyn.ClassPart> rest;
    case {} then {};
    case ((Absyn.EQUATIONS(contents = eql) :: rest))
      equation
        eql_1 = elabEquations(eql);
        eqs = elabClassdefEquations(rest);
        eqs_1 = listAppend(eqs, eql_1);
      then
        eqs_1;
    case (_ :: rest) /* ignore everthing other than equations */
      equation
        eqs = elabClassdefEquations(rest);
      then
        eqs;
  end matchcontinue;
end elabClassdefEquations;

protected function elabClassdefInitialequations "function: elabClassdefInitialequations

  Convert an Absyn.ClassPart list to an initial Equation list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Equation> eqs,eql_1,eqs_1;
      list<Absyn.EquationItem> eql;
      list<Absyn.ClassPart> rest;
    case {} then {};
    case ((Absyn.INITIALEQUATIONS(contents = eql) :: rest))
      equation
        eql_1 = elabEquations(eql);
        eqs = elabClassdefInitialequations(rest);
        eqs_1 = listAppend(eqs, eql_1);
      then
        eqs_1;
    case (_ :: rest) /* ignore everthing other than equations */
      equation
        eqs = elabClassdefInitialequations(rest);
      then
        eqs;
  end matchcontinue;
end elabClassdefInitialequations;

protected function elabClassdefAlgorithms "function: elabClassdefAlgorithms

  Convert an Absyn.ClassPart list to an Algorithm list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Algorithm> outAlgorithmLst;
algorithm
  outAlgorithmLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Algorithm> als,als_1;
      list<Absyn.Algorithm> al_1;
      list<Absyn.AlgorithmItem> al;
      list<Absyn.ClassPart> rest;
    case {} then {};
    case ((Absyn.ALGORITHMS(contents = al) :: rest))
      equation
        al_1 = elabClassdefAlgorithmitems(al);
        als = elabClassdefAlgorithms(rest);
        als_1 = (ALGORITHM(al_1,NONE) :: als);
      then
        als_1;
    case (_ :: rest) /* ignore everthing other than algorithms */
      equation
        als = elabClassdefAlgorithms(rest);
      then
        als;
  end matchcontinue;
end elabClassdefAlgorithms;

protected function elabClassdefInitialalgorithms "function: elabClassdefInitialalgorithms

  Convert an Absyn.ClassPart list to an initial Algorithm list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Algorithm> outAlgorithmLst;
algorithm
  outAlgorithmLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Algorithm> als,als_1;
      list<Absyn.Algorithm> al_1;
      list<Absyn.AlgorithmItem> al;
      list<Absyn.ClassPart> rest;
    case {} then {};
    case ((Absyn.INITIALALGORITHMS(contents = al) :: rest))
      equation
        al_1 = elabClassdefAlgorithmitems(al);
        als = elabClassdefInitialalgorithms(rest);
        als_1 = (ALGORITHM(al_1,NONE) :: als);
      then
        als_1;
    case (_ :: rest) /* ignore everthing other than algorithms */
      equation
        als = elabClassdefInitialalgorithms(rest);
      then
        als;
  end matchcontinue;
end elabClassdefInitialalgorithms;

protected function elabClassdefAlgorithmitems "function: elabClassdefAlgorithmitems

  Convert an Absyn.AlgorithmItem list to an Absyn.Algorithm list.
  Comments are lost.
"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  output list<Absyn.Algorithm> outAbsynAlgorithmLst;
algorithm
  outAbsynAlgorithmLst:=
  matchcontinue (inAbsynAlgorithmItemLst)
    local
      list<Absyn.Algorithm> res;
      Absyn.Algorithm alg;
      list<Absyn.AlgorithmItem> rest;
    case {} then {};
    case ((Absyn.ALGORITHMITEM(algorithm_ = alg) :: rest))
      equation
        res = elabClassdefAlgorithmitems(rest);
      then
        (alg :: res);
    case ((_ :: rest))
      equation
        res = elabClassdefAlgorithmitems(rest);
      then
        res;
  end matchcontinue;
end elabClassdefAlgorithmitems;

protected function elabClassdefExternaldecls "function: elabClassdefExternaldecls

  Converts an Absyn.ClassPart list to an Absyn.ExternalDecl option
  The list should only contain one external declaration, so pick the first
  one.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Option<Absyn.ExternalDecl> outAbsynExternalDeclOption;
algorithm
  outAbsynExternalDeclOption:=
  matchcontinue (inAbsynClassPartLst)
    local
      Absyn.ExternalDecl decl;
      Option<Absyn.ExternalDecl> res;
      list<Absyn.ClassPart> rest;
    case ((Absyn.EXTERNAL(externalDecl = decl) :: _)) then SOME(decl);
    case ((_ :: rest))
      equation
        res = elabClassdefExternaldecls(rest);
      then
        res;
    case ({}) then NONE;
  end matchcontinue;
end elabClassdefExternaldecls;

// Changed from protected to public. KS
public function elabEitemlist "function: elabEitemlist

  This function converts a list of `Absyn.ElementItem\' to a list of
  `Element\'.  The boolean argument flags whether the elements are
  pretected. Annotations are not elaborated, i.e. they are removed when
  converting to SCode.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Boolean inBoolean;
  output list<Element> outElementLst;
algorithm
  outElementLst:=
  matchcontinue (inAbsynElementItemLst,inBoolean)
    local
      list<Element> l,e_1,es_1;
      list<Absyn.ElementItem> es;
      Boolean prot;
      Absyn.Element e;
    case ({},_) then {};
    case ((Absyn.ANNOTATIONITEM(annotation_ = _) :: es),prot)
      equation
        l = elabEitemlist(es, prot);
      then
        l;
    case ((Absyn.ELEMENTITEM(element = e) :: es),prot)
      equation
        //debug_print("elaborating-element:", Dump.unparseElementStr(1, e));
        e_1 = elabElement(e, prot);
        es_1 = elabEitemlist(es, prot);
        l = listAppend(e_1, es_1);
      then
        l;
  end matchcontinue;
end elabEitemlist;

protected function elabElement "function: elabElement

  This function converts an `Absyn.Element\' to a list of
  `Element\'s.  The original element may declare several components
  at once, and those are separated to several declarations in the
  result.
"
  input Absyn.Element inElement;
  input Boolean inBoolean;
  output list<Element> outElementLst;
algorithm
  outElementLst:=
  matchcontinue (inElement,inBoolean)
    local
      list<Element> es;
      Boolean f,prot;
      Boolean inner_,outer_;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.ElementSpec s;
      Absyn.InnerOuter io;
      Absyn.Info info;
    case (Absyn.ELEMENT(final_ = f,innerOuter = io, redeclareKeywords = repl,specification = s,info = info),prot)
      equation
        es = elabElementspec(f, io, repl,  prot, s);
      then
        es;
  end matchcontinue;
end elabElement;

protected function elabElementspec "function: elabElementspec

  This function turns an `Absyn.ElementSpec\' to a list of
  `Element\'s.  The boolean arguments say if the element is final and
  protected, respectively.
"
  input Boolean final_;
  input Absyn.InnerOuter io;
  input Option<Absyn.RedeclareKeywords> inAbsynRedeclareKeywordsOption2;
  input Boolean inBoolean3;
  input Absyn.ElementSpec inElementSpec4;
  output list<Element> outElementLst;
algorithm
  outElementLst:=
  matchcontinue (final_,io,inAbsynRedeclareKeywordsOption2,inBoolean3,inElementSpec4)
    local
      ClassDef de_1;
      Restriction re_1;
      Boolean final_,prot,rp,pa,fi,e,repl_1,fl,st;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.Class cl;
      String n,ns;
      Absyn.Restriction re;
      Absyn.ClassDef de;
      Absyn.Info file_info;
      Mod mod;
      list<Absyn.ElementArg> args;
      list<Element> xs_1;
      Variability pa_1;
      list<Subscript> tot_dim,ad,d;
      Absyn.ElementAttributes attr;
      Absyn.Direction di;
      Absyn.TypeSpec t;
      Option<Absyn.Modification> m;
      Option<Absyn.Comment> comment;
      list<Absyn.ComponentItem> xs;
      Absyn.Import imp;
    case (final_,_,repl,prot,Absyn.CLASSDEF(replaceable_ = rp,class_ = (cl as Absyn.CLASS(name = n,partial_ = pa,final_ = fi,encapsulated_ = e,restriction = re,body = de,info = file_info))))
      equation
        //debug_print("elaborating-class:", n);
        re_1 = elabRestriction(cl, re); // uniontype will not get elaborated!
        de_1 = elabClassdef(de);
      then
        {CLASSDEF(n,final_,rp,CLASS(n,pa,e,re_1,de_1),NONE)};
    case (final_,_,repl,prot,Absyn.EXTENDS(path = n,elementArg = args))
      local Absyn.Path n;
      equation
        mod = buildMod(SOME(Absyn.CLASSMOD(args,NONE)), false, Absyn.NON_EACH());
        ns = Absyn.pathString(n);
      then
        {EXTENDS(n,mod)};
    case (_,_,_,_,Absyn.COMPONENTS(components = {})) then {};
    case (final_,io,repl,prot,Absyn.COMPONENTS(attributes = 
      (attr as Absyn.ATTR(flow_ = fl,stream_=st,variability = pa,direction = di,arrayDim = ad)),typeSpec = t,
      components = (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = n,arrayDim = d,modification = m),comment = comment) :: xs)))
      local Absyn.Variability pa;
      equation
        xs_1 = elabElementspec(final_, io, repl, prot, Absyn.COMPONENTS(attr,t,xs));
        mod = buildMod(m, false, Absyn.NON_EACH());
        pa_1 = elabVariability(pa) "PR. This adds the arraydimension that may be specified together with
	 the type of the component." ;
        tot_dim = listAppend(d, ad);
        repl_1 = elabRedeclarekeywords(repl);
      then
        (COMPONENT(n,io,final_,repl_1,prot,ATTR(tot_dim,fl,st,RW(),pa_1,di),t,mod,
          NONE,comment) :: xs_1);
    case (final_,_,repl,prot,Absyn.IMPORT(import_ = imp)) then {IMPORT(imp)};
  end matchcontinue;
end elabElementspec;

protected function elabRedeclarekeywords "function: elabRedeclarekeywords
  author: PA

  For now, translate to bool, replaceable.
"
  input Option<Absyn.RedeclareKeywords> inAbsynRedeclareKeywordsOption;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inAbsynRedeclareKeywordsOption)
    case (SOME(Absyn.REPLACEABLE())) then true;
    case (SOME(Absyn.REDECLARE_REPLACEABLE())) then true;
    case (_) then false;
  end matchcontinue;
end elabRedeclarekeywords;

protected function elabVariability "function: elabVariability

  Converts an Absyn.Variability to Variability.
"
  input Absyn.Variability inVariability;
  output Variability outVariability;
algorithm
  outVariability:=
  matchcontinue (inVariability)
    case (Absyn.VAR()) then VAR();
    case (Absyn.DISCRETE()) then DISCRETE();
    case (Absyn.PARAM()) then PARAM();
    case (Absyn.CONST()) then CONST();
  end matchcontinue;
end elabVariability;

protected function elabEquations "function: elabEquations

  This function transforms a list of `Absyn.Equation\'s to a list of
  `Equations\'s, by applying the `elab_equation\' function to each
  equation.
"
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inAbsynEquationItemLst)
    local
      EEquation e_1;
      list<Equation> es_1;
      Absyn.Equation e;
      list<Absyn.EquationItem> es;
    case {} then {};
    case (Absyn.EQUATIONITEM(equation_ = e) :: es)
      equation
        e_1 = elabEquation(e);
        es_1 = elabEquations(es);
      then
        (EQUATION(e_1,NONE) :: es_1);
    case (Absyn.EQUATIONITEMANN(annotation_ = _) :: es)
      equation
        es_1 = elabEquations(es);
      then
        es_1;
  end matchcontinue;
end elabEquations;

protected function elabEEquations "function: elabEEquations

  Helper function to elab_equations
"
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<EEquation> outEEquationLst;
algorithm
  outEEquationLst:=
  matchcontinue (inAbsynEquationItemLst)
    local
      EEquation e_1;
      list<EEquation> es_1;
      Absyn.Equation e;
      list<Absyn.EquationItem> es;
    case {} then {};
    case (Absyn.EQUATIONITEM(equation_ = e) :: es)
      equation
        e_1 = elabEquation(e);
        es_1 = elabEEquations(es);
      then
        (e_1 :: es_1);
    case (Absyn.EQUATIONITEMANN(annotation_ = _) :: es)
      equation
        es_1 = elabEEquations(es);
      then
        es_1;
  end matchcontinue;
end elabEEquations;

public function equationStr "function: equationStr
  author: PA

  Return the equation as a string.
"
  input EEquation inEEquation;
  output String outString;
algorithm
  outString:=
  matchcontinue (inEEquation)
    local
      String s1,s2,s3,res,id;
      list<String> tb_strs,fb_strs,str_lst;
      Absyn.Exp exp,e1,e2;
      list<EEquation> tb,fb,eqn_lst;
      Absyn.ComponentRef cr1,cr2,cr;
    case (EQ_IF(conditional = exp,true_ = tb,false_ = fb))
      equation
        s1 = Dump.printExpStr(exp);
        tb_strs = Util.listMap(tb, equationStr);
        fb_strs = Util.listMap(fb, equationStr);
        s2 = Util.stringDelimitList(tb_strs, "\n");
        s3 = Util.stringDelimitList(fb_strs, "\n");
        res = Util.stringAppendList({"if ",s1," then ",s2,"else ",s3,"end if;"});
      then
        res;
    case (EQ_EQUALS(exp1 = e1,exp2 = e2))
      equation
        s1 = Dump.printExpStr(e1);
        s2 = Dump.printExpStr(e2);
        res = Util.stringAppendList({s1," = ",s2,";"});
      then
        res;
    case (EQ_CONNECT(componentRef1 = cr1,componentRef2 = cr2))
      equation
        s1 = Dump.printComponentRefStr(cr1);
        s2 = Dump.printComponentRefStr(cr2);
        res = Util.stringAppendList({"connect(",s1,", ",s2,");"});
      then
        res;
    case (EQ_FOR(id = id,range = exp,eEquationLst = eqn_lst))
      equation
        s1 = Dump.printExpStr(exp);
        str_lst = Util.listMap(eqn_lst, equationStr);
        s2 = Util.stringDelimitList(str_lst, "\n");
        res = Util.stringAppendList({"for ",id," in ",s1," loop\n",s2,"\nend for;"});
      then
        res;
    case (EQ_WHEN(exp = _)) then "EQ_WHEN(... not impl ...)";
    case (EQ_ASSERT(condition = e1,message = e2))
      equation
        s1 = Dump.printExpStr(e1);
        s2 = Dump.printExpStr(e2);
        res = Util.stringAppendList({"assert(",s1,", ",s2,");"});
      then
        res;
    case (EQ_REINIT(componentRef = cr,state = e1))
      equation
        s1 = Dump.printComponentRefStr(cr);
        s2 = Dump.printExpStr(e1);
        res = Util.stringAppendList({"reinit(",s1,", ",s2,");"});
      then
        res;
  end matchcontinue;
end equationStr;

protected function elabEquation "function: elabEquation

  The translation of equations are straightforward, with one
  exception.  `If\' clauses are translated so that the SCode only
  contains simple `if\'-`else\' constructs, and no `elseif\'.

  PR Arrays seem to keep their Absyn.mo structure."
  input Absyn.Equation inEquation;
  output EEquation outEEquation;
algorithm
  outEEquation:=
  matchcontinue (inEquation)
    local
      list<EEquation> tb_1,fb_1,eb_1,l_1;
      Absyn.Exp e,ee,econd_1,cond,econd,e1,e2;
      list<Absyn.EquationItem> tb,fb,ei,eb,l;
      EEquation eq;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> eis,elsewhen_;
      list<tuple<Absyn.Exp, list<EEquation>>> elsewhen_1;
      Absyn.ComponentRef c1,c2,cr;
      String i;
    case Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = {},equationElseItems = fb)
      equation
        tb_1 = elabEEquations(tb);
        fb_1 = elabEEquations(fb);
      then
        EQ_IF(e,tb_1,fb_1);
    case Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = ((ee,ei) :: eis),equationElseItems = fb)
      equation
        eq = elabEquation(
          Absyn.EQ_IF(e,tb,{},
          {Absyn.EQUATIONITEM(Absyn.EQ_IF(ee,ei,eis,fb),NONE)}));
      then
        eq;
    case Absyn.EQ_WHEN_E(whenExp = cond,whenEquations = tb,elseWhenEquations = ((econd,eb) :: elsewhen_))
      equation
        tb_1 = elabEEquations(tb);
        EQ_WHEN(econd_1,eb_1,elsewhen_1) = elabEquation(Absyn.EQ_WHEN_E(econd,eb,elsewhen_));
      then
        EQ_WHEN(cond,tb_1,((econd_1,eb_1) :: elsewhen_1));
    case Absyn.EQ_WHEN_E(whenExp = cond,whenEquations = tb,elseWhenEquations = {})
      equation
        tb_1 = elabEEquations(tb);
      then
        EQ_WHEN(cond,tb_1,{});
    case Absyn.EQ_EQUALS(leftSide = e1,rightSide = e2) then EQ_EQUALS(e1,e2);
    case Absyn.EQ_CONNECT(connector1 = c1,connector2 = c2) then EQ_CONNECT(c1,c2);
    case Absyn.EQ_FOR(iterators = {(i,SOME(e))},forEquations = l)
      equation
        l_1 = elabEEquations(l);
      then
        EQ_FOR(i,e,l_1);
    case Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT("assert", _),functionArgs = Absyn.FUNCTIONARGS(args = {e1,e2},argNames = {})) then EQ_ASSERT(e1,e2);
    case Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT("terminate", _),functionArgs = Absyn.FUNCTIONARGS(args = {e1},argNames = {})) then EQ_TERMINATE(e1);
    case Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT("reinit", _),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),e2},argNames = {})) then EQ_REINIT(cr,e2);
  end matchcontinue;
end elabEquation;

public function buildMod "- Modification management
  function: buildMod

  Builds an `SCode.Mod\' from an `Absyn.Modification\'.  The boolean
  argument flags whether the modification is `final\'.
"
  input Option<Absyn.Modification> inAbsynModificationOption;
  input Boolean inBoolean;
  input Absyn.Each inEach;
  output Mod outMod;
algorithm
  outMod:=
  matchcontinue (inAbsynModificationOption,inBoolean,inEach)
    local
      Absyn.Exp e;
      Boolean final_;
      Absyn.Each each_;
      list<SubMod> subs;
      list<Absyn.ElementArg> l;
    case (NONE,_,_) then NOMOD();  /* final */
    case (SOME(Absyn.CLASSMOD({},(SOME(e)))),final_,each_) then MOD(final_,each_,{},SOME((e,false)));
    case (SOME(Absyn.CLASSMOD({},(NONE))),final_,each_) then MOD(final_,each_,{},NONE);
    case (SOME(Absyn.CLASSMOD(l,SOME(e))),final_,each_)
      equation
        subs = buildArgs(l);
      then
        MOD(final_,each_,subs,SOME((e,false)));
    case (SOME(Absyn.CLASSMOD(l,NONE)),final_,each_)
      equation
        subs = buildArgs(l);
      then
        MOD(final_,each_,subs,NONE);
  end matchcontinue;
end buildMod;

public function stripSubmod "function: stripSubmod
  author: PA

  Removes all submodifiers from the Mod.
"
  input Mod inMod;
  output Mod outMod;
algorithm
  outMod:=
  matchcontinue (inMod)
    local
      Boolean f;
      Absyn.Each each_;
      list<SubMod> subs;
      Option<tuple<Absyn.Exp,Boolean>> e;
      Mod m;
    case (MOD(final_ = f,each_ = each_,subModLst = subs,absynExpOption = e)) then MOD(f,each_,{},e);
    case (m) then m;
  end matchcontinue;
end stripSubmod;

protected function buildArgs "function: buildArgs
  author: LS

  Adding elaborate for the elementspec in the redeclaration
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<SubMod> outSubModLst;
algorithm
  outSubModLst:=
  matchcontinue (inAbsynElementArgLst)
    local
      list<SubMod> subs;
      Mod mod_1;
      SubMod sub;
      Boolean final_;
      Absyn.Each each_;
      Absyn.ComponentRef cref;
      Option<Absyn.Modification> mod;
      Option<String> cmt;
      list<Absyn.ElementArg> xs;
      String n;
      list<Element> elist;
      Absyn.RedeclareKeywords keywords;
      Absyn.ElementSpec spec;
      Option<Absyn.ConstrainClass> constropt;
    case {} then {};
    case ((Absyn.MODIFICATION(finalItem = final_,each_ = each_,componentReg = cref,modification = mod,comment = cmt) :: xs))
      equation
        subs = buildArgs(xs);
        mod_1 = buildMod(mod, final_, each_);
        sub = buildSub(cref, mod_1);
      then
        (sub :: subs);
    case ((Absyn.REDECLARATION(finalItem = final_,redeclareKeywords = keywords,each_ = each_,elementSpec = spec,constrainClass = constropt) :: xs))
      equation
        subs = buildArgs(xs);
        n = Absyn.elementSpecName(spec);
        elist = elabElementspec(final_, Absyn.UNSPECIFIED(), NONE, false, spec) "LS:: don\'t know what to use for \"protected\", so using false LS:: don\'t know what to use for \"replaceable\", so using false" ;
      then
        (NAMEMOD(n,REDECL(final_,elist)) :: subs);
  end matchcontinue;
end buildArgs;

protected function buildSub "function: buildSub

  This function converts a `ComponentRef\' into a number of nested
  `SUBMOD\'s.
"
  input Absyn.ComponentRef inComponentRef;
  input Mod inMod;
  output SubMod outSubMod;
algorithm
  outSubMod:=
  matchcontinue (inComponentRef,inMod)
    local
      String c_str,mod_str,i;
      Absyn.ComponentRef c,path;
      Mod mod,mod_1;
      list<Subscript> ss;
      SubMod sub;
    case ((c as Absyn.CREF_IDENT(subscripts = (_ :: _))),(mod as MOD(subModLst = (_ :: _)))) /* First some rules to prevent bad modifications */
      equation
        c_str = Dump.printComponentRefStr(c);
        mod_str = printModStr(mod);
        Error.addMessage(Error.ILLEGAL_MODIFICATION, {mod_str,c_str});
      then
        fail();
    case ((c as Absyn.CREF_QUAL(subScripts = (_ :: _))),(mod as MOD(subModLst = (_ :: _))))
      equation
        c_str = Dump.printComponentRefStr(c);
        mod_str = printModStr(mod);
        Error.addMessage(Error.ILLEGAL_MODIFICATION, {mod_str,c_str});
      then
        fail();
    case (Absyn.CREF_IDENT(name = i,subscripts = ss),mod) /* Then the normal rules */
      equation
        mod_1 = buildSubSub(ss, mod);
      then
        NAMEMOD(i,mod_1);
    case (Absyn.CREF_QUAL(name = i,subScripts = ss,componentRef = path),mod)
      equation
        sub = buildSub(path, mod);
        mod = MOD(false,Absyn.NON_EACH(),{sub},NONE);
        mod_1 = buildSubSub(ss, mod);
      then
        NAMEMOD(i,mod_1);
  end matchcontinue;
end buildSub;

protected function buildSubSub "function: buildSubSub

  This function is used to handle the case when a array component is
  indexed in the modification, so that only one or a limitied number
  of array elements should be modified.
"
  input list<Subscript> inSubscriptLst;
  input Mod inMod;
  output Mod outMod;
algorithm
  outMod:=
  matchcontinue (inSubscriptLst,inMod)
    local
      Mod m;
      list<Subscript> l;
    case ({},m) then m;
    case (l,m) then MOD(false,Absyn.NON_EACH(),{IDXMOD(l,m)},NONE);
  end matchcontinue;
end buildSubSub;

public function getElementNamed "function: getElementNamed

  Return the Element with the name given as first argument from
  the Class.
"
  input Ident inIdent;
  input Class inClass;
  output Element outElement;
algorithm
  outElement:=
  matchcontinue (inIdent,inClass)
    local
      Element elt;
      String id;
      list<Element> elts;
    case (id,CLASS(parts = PARTS(elementLst = elts)))
      equation
        elt = getElementNamedFromElts(id, elts);
      then
        elt;
  end matchcontinue;
end getElementNamed;

protected function getElementNamedFromElts "function: getElementNamedFromElts

  Helper function to get_element_named.
"
  input Ident inIdent;
  input list<Element> inElementLst;
  output Element outElement;
algorithm
  outElement:=
  matchcontinue (inIdent,inElementLst)
    local
      Element elt,comp,cdef;
      String id2,id1;
      list<Element> xs;
    case (id2,((comp as COMPONENT(component = id1)) :: _))
      equation
        equality(id1 = id2);
      then
        comp;
    case (id2,(COMPONENT(component = id1) :: xs))
      equation
        failure(equality(id1 = id2));
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;
    case (id2,(CLASSDEF(name = id1) :: xs))
      equation
        failure(equality(id1 = id2));
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;
    case (id2,(EXTENDS(path = _) :: xs))
      equation
        elt = getElementNamedFromElts(id2, xs);
      then
        elt;
    case (id2,((cdef as CLASSDEF(name = id1)) :: _))
      equation
        equality(id1 = id2);
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

public function printMod "function: printMod

  This function prints a modification.  The code is excluded from
  the report for brevity.
"
  input Mod m;
  String s;
algorithm
  s := printModStr(m);
  Print.printBuf(s);
end printMod;

public function printModStr "function: printModStr

  Prints Mod to a string.
"
  input Mod inMod;
  output String outString;
algorithm
  outString:=
  matchcontinue (inMod)
    local
      String final_str,str,res,each_str,subs_str,ass_str;
      list<String> strs;
      Boolean b,final_;
      list<Element> elist;
      Absyn.Each each_;
      list<SubMod> subs;
      Option<tuple<Absyn.Exp,Boolean>> ass;
    case (NOMOD()) then "";
    case REDECL(final_ = b,elementLst = elist)
      equation
        Print.printBuf("redeclare(");
        final_str = Util.if_(b, "final", "");
        strs = Util.listMap(elist, printElementStr);
        str = Util.stringDelimitList(strs, ",");
        res = Util.stringAppendList({"redeclare(",final_str,str,")"});
      then
        res;
    case MOD(final_ = final_,each_ = each_,subModLst = subs,absynExpOption = ass)
      equation
        final_str = Util.if_(final_, "final", "");
        each_str = Dump.unparseEachStr(each_);
        subs_str = printSubs1Str(subs);
        ass_str = printEqmodStr(ass);
        res = Util.stringAppendList({final_str,each_str,subs_str,ass_str});
      then
        res;
    case _
      equation
        Print.printBuf("#-- print_mod_str failed\n");
      then
        fail();
  end matchcontinue;
end printModStr;

public function restrString "function: restrString

  Prints Restriction to a string.
"
  input Restriction inRestriction;
  output String outString;
algorithm
  outString:=
  matchcontinue (inRestriction)
    case R_CLASS() then "CLASS";
    case R_MODEL() then "MODEL";
    case R_RECORD() then "RECORD";
    case R_BLOCK() then "BLOCK";
    case R_CONNECTOR() then "CONNECTOR";
    case R_TYPE() then "TYPE";
    case R_PACKAGE() then "PACKAGE";
    case R_FUNCTION() then "FUNCTION";
    case R_EXT_FUNCTION() then "EXTFUNCTION";
    case R_PREDEFINED_INT() then "PREDEFINED_INT";
    case R_PREDEFINED_REAL() then "PREDEFINED_REAL";
    case R_PREDEFINED_STRING() then "PREDEFINED_STRING";
    case R_PREDEFINED_BOOL() then "PREDEFINED_BOOL";
  end matchcontinue;
end restrString;

public function printRestr "function: printRestr

  Prints Restriction to the Print buffer.
"
  input Restriction restr;
  String str;
algorithm
  str := restrString(restr);
  Print.printBuf(str);
end printRestr;

protected function printFinal "function: printFinal

  Prints \"final\" to the Print buffer.
"
  input Boolean inBoolean;
algorithm
  _:=
  matchcontinue (inBoolean)
    case false then ();
    case true
      equation
        Print.printBuf(" final ");
      then
        ();
  end matchcontinue;
end printFinal;

protected function printSubsStr "function: printSubsStr

  Prints a SubMod list to a string.
"
  input list<SubMod> inSubModLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inSubModLst)
    local
      String s,res,n,mod_str,str,sub_str;
      Mod mod;
      list<SubMod> subs;
      list<Subscript> ss;
    case {} then "";
    case {NAMEMOD(ident = n,A = mod)}
      equation
        Print.printBuf(n);
        s = printModStr(mod);
        res = stringAppend(n, s);
      then
        res;
    case (NAMEMOD(ident = n,A = mod) :: subs)
      equation
        mod_str = printModStr(mod);
        str = printSubsStr(subs);
        res = Util.stringAppendList({n, mod_str, ", ", str});
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
        res = Util.stringAppendList({str,mod_str,", ",sub_str});
      then
        res;
  end matchcontinue;
end printSubsStr;

protected function printSubs1Str "function: printSubs1Str

  Helper function to print_subs_str.
"
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
        Print.printBuf("(");
        s = printSubsStr(l);
        Print.printBuf(")");
        res = Util.stringAppendList({"(",s,")"});
      then
        res;
  end matchcontinue;
end printSubs1Str;

protected function printEqmodStr "function: printEqmodStr

  Helper function to print_mod_str.
"
  input Option<tuple<Absyn.Exp,Boolean>> inAbsynExpOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynExpOption)
    local
      String str,res;
      Absyn.Exp e;
      Boolean b;
    case NONE then "";
    case SOME((e,b))
      equation
        str = Dump.printExpStr(e);
        res = stringAppend(" = ", str);
      then
        res;
  end matchcontinue;
end printEqmodStr;

public function printElementList "function: printElementList

  Print Element list to Print buffer.
"
  input list<Element> inElementLst;
algorithm
  _:=
  matchcontinue (inElementLst)
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
  outString:=
  matchcontinue (inElement)
    local
      String str,str2,res,n,mod_str,s,vs;
      Absyn.Path path,typath;
      Mod mod;
      Boolean final_,repl,prot;
      Absyn.InnerOuter io;
      Class cl;
      Variability var;
      Absyn.TypeSpec tySpec;
      Option<Absyn.Comment> comment;
      Attributes attr;
      String modStr;
    case EXTENDS(path = path,mod = mod)
      equation
        str = Absyn.pathString(path);
        modStr = printModStr(mod);
        res = Util.stringAppendList({"EXTENDS(",str,", modification=",modStr,")"});
      then
        res;
    case CLASSDEF(name = n,final_ = final_,replaceable_ = repl,class_ = cl,baseclass = SOME(path))
      equation
        str = Absyn.pathString(path);
        res = Util.stringAppendList({"CLASSDEF(",n,", from basclass: ",str,")"});
      then
        res;
    case COMPONENT(component = n,innerOuter=io,final_ = final_,replaceable_ = repl,protected_ = prot,
      attributes = ATTR(parameter_ = var),typeSpec = tySpec,mod = mod,baseclass = SOME(path),this = comment)
      equation
        mod_str = printModStr(mod);
        s = Dump.unparseTypeSpec(tySpec);
        vs = variabilityString(var);
        str = Absyn.pathString(path);
        str2 = innerouterString(io);
        res = Util.stringAppendList(
          {"COMPONENT(",n, " ", mod_str, " ", s, " ",str2," var :",vs,", from baseclass: ",
          str,")"});
      then
        res;
    case CLASSDEF(name = n,final_ = final_,replaceable_ = repl,class_ = cl,baseclass = NONE)
      equation
        str = printClassStr(cl);
        res = Util.stringAppendList({"CLASSDEF(",n,",...,",str,")"});
      then
        res;
    case COMPONENT(component = n,innerOuter=io,final_ = final_,replaceable_ = repl,protected_ = prot,attributes = attr,typeSpec = tySpec,mod = mod,baseclass = NONE,this = comment)
      equation
        mod_str = printModStr(mod);
        s = Dump.unparseTypeSpec(tySpec);
        str2 = innerouterString(io);
        res = Util.stringAppendList({"COMPONENT(",n," ",str2," mod: ",mod_str,", tp: ",s,")"});
      then
        res;
    case (IMPORT(import_ = _)) then "IMPORT(_)";
  end matchcontinue;
end printElementStr;

public function unparseElementStr "function: printElementStr

  Print Element to a string.
"
  input Element inElement;
  output String outString;
algorithm
  outString:=
  matchcontinue (inElement)
    local
      String str,res,n,mod_str,s,vs;
      Absyn.Path path;
      Absyn.TypeSpec typath;
      Mod mod;
      Boolean final_,repl,prot;
      Class cl;
      Variability var;
      Option<Absyn.Comment> comment;
      Attributes attr;
    case EXTENDS(path = path,mod = mod)
      equation
        str = Absyn.pathString(path);
        res = Util.stringAppendList({"extends ",str,";"});
      then
        res;
    case COMPONENT(component = n,final_ = final_,replaceable_ = repl,protected_ = prot,attributes = ATTR(parameter_ = var),typeSpec = typath,mod = mod,baseclass = SOME(path),this = comment)
      equation
        mod_str = printModStr(mod);
        s = Dump.unparseTypeSpec(typath);
        vs = unparseVariability(var);
        str = Absyn.pathString(path);
        res = Util.stringAppendList(
          {vs," ",s," ",n,mod_str,"; // from baseclass: ",
          str,"\n"});
      then
        res;
    case CLASSDEF(name = n,final_ = final_,replaceable_ = repl,class_ = cl,baseclass = _)
      equation
        str = printClassStr(cl);
        res = Util.stringAppendList({"class ",n,"\n",str,"end ",n,";\n"});
      then
        res;
    case COMPONENT(component = n,final_ = final_,replaceable_ = repl,protected_ = prot,attributes = ATTR(parameter_ = var),typeSpec = typath,mod = mod,baseclass = NONE,this = comment)
      equation
        mod_str = printModStr(mod);
        s = Dump.unparseTypeSpec(typath);
        vs = unparseVariability(var);
        res = Util.stringAppendList(
          {vs," ",s," ",n,mod_str,";\n"});
      then
        res;
    case (IMPORT(import_ = _)) then "import ... ";
  end matchcontinue;
end unparseElementStr;

public function printClassStr
  input Class inClass;
  output String outString;
algorithm
  outString:=
  matchcontinue (inClass)
    local
      String s,res,id;
      Boolean p,en;
      Restriction rest;
      ClassDef def;
    case (CLASS(name = id,partial_ = p,encapsulated_ = en,restriction = rest,parts = def))
      equation
        s = printClassdefStr(def);
        res = Util.stringAppendList({"CLASS(",id,",_,_,_,",s,")"});
      then
        res;
  end matchcontinue;
end printClassStr;

protected function printClassdefStr
  input ClassDef inClassDef;
  output String outString;
algorithm
  outString:=
  matchcontinue (inClassDef)
    local
      list<String> elts_str;
      String s1,res,s2,s3;
      list<Element> elts;
      list<Equation> eqns,ieqns;
      list<Algorithm> alg,ial;
      Option<Absyn.ExternalDecl> ext;
      Absyn.TypeSpec typeSpec;
      Mod mod;
    case (PARTS(elementLst = elts,equationLst = eqns,initialEquation = ieqns,algorithmLst = alg,initialAlgorithm = ial,used = ext))
      equation
        elts_str = Util.listMap(elts, printElementStr);
        s1 = Util.stringDelimitList(elts_str, ",\n");
        res = Util.stringAppendList({"PARTS(",s1,",_,_,_,_,_)"});
      then
        res;
    case (DERIVED(typeSpec = typeSpec,mod = mod))
      equation
        s2 = Dump.unparseTypeSpec(typeSpec);
        s3 = printModStr(mod);
        res = Util.stringAppendList({"DERIVED(",s2,",",s3,")"});
      then
        res;
  end matchcontinue;
end printClassdefStr;

public function attrVariability "Return the variability attribute from Attributes"
  input Attributes attr;
  output Variability var;
algorithm
  var := matchcontinue (attr) local Variability v;
	    case	ATTR(parameter_=v) then v;
    end matchcontinue;
end attrVariability;


public function variabilityString "function: variabilityString

  Print Variability to a string.
"
  input Variability inVariability;
  output String outString;
algorithm
  outString:=
  matchcontinue (inVariability)
    case (VAR()) then "VAR";
    case (DISCRETE()) then "DISCRETE";
    case (PARAM()) then "PARAM";
    case (CONST()) then "CONST";
  end matchcontinue;
end variabilityString;

public function innerouterString "function: inner/outer String

  Print a inner outer info to a string.
"
  input Absyn.InnerOuter innerOuter;
  output String outString;
algorithm
  outString:=
  matchcontinue (innerOuter)
    case (Absyn.INNEROUTER()) then "INNER/OUTER";
    case (Absyn.INNER()) then "INNER";
    case (Absyn.OUTER()) then "OUTER";
    case (Absyn.UNSPECIFIED()) then "";
  end matchcontinue;
end innerouterString;

public function unparseVariability "function: variabilityString

  Print Variability to a string.
"
  input Variability inVariability;
  output String outString;
algorithm
  outString:=
  matchcontinue (inVariability)
    case (VAR()) then "";
    case (DISCRETE()) then "discrete";
    case (PARAM()) then "parameter";
    case (CONST()) then "constant";
  end matchcontinue;
end unparseVariability;


public function isParameterOrConst "function: isParameterOrConst

  Returns true if Variability indicates a parameter or constant.
"
  input Variability inVariability;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVariability)
    case (VAR()) then false;
    case (DISCRETE()) then false;
    case (PARAM()) then true;
    case (CONST()) then true;
  end matchcontinue;
end isParameterOrConst;

public function isConstant "function: isConstant
Returns true if Variability is constant, otherwise false
"
  input Variability inVariability;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVariability)
    case (VAR()) then false;
    case (DISCRETE()) then false;
    case (PARAM()) then false;
   case (CONST()) then true;
  end matchcontinue;
end isConstant;

public function countParts "function: countParts

  Counts the number of ClassParts of a Class.
"
  input Class inClass;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inClass)
    local
      Integer res;
      list<Element> elts;
    case CLASS(parts = PARTS(elementLst = elts))
      equation
        res = listLength(elts);
      then
        res;
    case _ then 0;
  end matchcontinue;
end countParts;

public function componentNames "function: componentNames

  Return a string list of all component names of a class.
"
  input Class inClass;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inClass)
    local
      list<String> res;
      list<Element> elts;
    case (CLASS(parts = PARTS(elementLst = elts)))
      equation
        res = componentNamesFromElts(elts);
      then
        res;
    case (_) then {};
  end matchcontinue;
end componentNames;

protected function componentNamesFromElts "function: componentNamesFromElts

  Helper function to component_names.
"
  input list<Element> inElementLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inElementLst)
    local
      list<String> res;
      String id;
      list<Element> rest;
    case ({}) then {};
    case ((COMPONENT(component = id) :: rest))
      equation
        res = componentNamesFromElts(rest);
      then
        (id :: res);
  end matchcontinue;
end componentNamesFromElts;

public function isFunction "function: isFunction

  Return true if Class is a function.
"
  input Class inClass;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inClass)
    local
      String n;
      ClassDef def;
    case CLASS(name = n,restriction = R_FUNCTION(),parts = def) then true;
    case CLASS(name = n,restriction = R_EXT_FUNCTION(),parts = def) then true;
    case _ then false;
  end matchcontinue;
end isFunction;

public function className "function: className

  Returns the class name of a Class.
"
  input Class inClass;
  output String outString;
algorithm
  outString:=
  matchcontinue (inClass)
    local String n;
    case CLASS(name = n) then n;
    case _ then "Not a class";
  end matchcontinue;
end className;

public function classSetPartial "function: classSetPartial
  author: PA

  Sets the partial attribute of a Class
"
  input Class inClass;
  input Boolean inBoolean;
  output Class outClass;
algorithm
  outClass:=
  matchcontinue (inClass,inBoolean)
    local
      String id;
      Boolean enc,partial_;
      Restriction restr;
      ClassDef def;
    case (CLASS(name = id,encapsulated_ = enc,restriction = restr,parts = def),partial_) then CLASS(id,partial_,enc,restr,def);
  end matchcontinue;
end classSetPartial;

function isFunctionOrExtFunction "
This function returns true if the class restriction is function or external function.
Otherwise false is returned.
"
  input Restriction r;
  output Boolean res;
algorithm
  res := matchcontinue(r)
    case(R_FUNCTION()) then true;
    case (R_EXT_FUNCTION()) then true;
    case(_) then false;
  end matchcontinue;
 end isFunctionOrExtFunction;

 public function elementEqual "returns true if two elements are equal,
 i.e. for a component have the same type, name, and attributes, etc."
   input Element element1;
   input Element element2;
   output Boolean equal;
 algorithm
   equal := matchcontinue(element1,element2)
     case (CLASSDEF(name1,f1,r1,cl1,_),CLASSDEF(name2,f2,r2,cl2,_))
         local
           Ident name1,name2;
           Boolean f1,f2,r1,r2,b1,b2,b3;
           Class cl1,cl2;
       equation
         b1 = stringEqual(name1,name2);
         b2 = Util.boolEqual(f1,f2);
         b3 = Util.boolEqual(r1,r2);
         b3 = classEqual(cl1,cl2);
         equal = Util.boolAndList({b1,b2,b3});
       then equal;

     case (COMPONENT(name1,io,f1,r1,p1,attr1,tp1,mod1,_,_), COMPONENT(name2,io2,f2,r2,p2,attr2,tp2,mod2,_,_))
       local
         Boolean b1,b1a,b1b,b2,b3,b4,b5,b6,f1,f2,r1,r2,p1,p2; Ident name1,name2;
         Absyn.InnerOuter io,io2;
         Attributes attr1,attr2; Mod mod1,mod2; Absyn.TypeSpec tp1,tp2;
       equation
         b1 = stringEqual(name1,name2);
         b1a = ModUtil.innerOuterEqual(io,io2);
         b2 = Util.boolEqual(f1,f2);
         b3 = Util.boolEqual(r1,r2);
         b4 = Util.boolEqual(p1,p2);
         b5 = attributesEqual(attr1,attr2);
         b6 = modEqual(mod1,mod2);
         equal = Util.boolAndList({b1,b1a,b2,b3,b4,b5,b6});
         then equal;
     case(_,_) then false;
   end matchcontinue;
 end elementEqual;

protected function classEqual "returns true if two classes are equal"
  input Class class1;
  input Class class2;
  output Boolean equal;

algorithm
  equal := matchcontinue(class1,class2)
    case (CLASS(name1,p1,e1,restr1,parts1), CLASS(name2,p2,e2,restr2,parts2))
      local
        Ident name1,name2;
        Boolean p1,e1,p2,e2,b1,b2,b3,b4,b5;
        Restriction restr1,restr2;
        ClassDef parts1,parts2;
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

 protected function restrictionEqual "Returns true if two Restriction's are equal."
 input Restriction restr1;
 input Restriction restr2;
 output Boolean equal;
 algorithm
   equal := matchcontinue(restr1,restr2)
     case (R_CLASS(),R_CLASS()) then true;
     case (R_MODEL(),R_MODEL()) then true;
     case (R_RECORD(),R_RECORD()) then true;
     case (R_BLOCK(),R_BLOCK()) then true;
     case (R_CONNECTOR(),R_CONNECTOR()) then true;
     case (R_TYPE(),R_TYPE()) then true;
     case (R_PACKAGE(),R_PACKAGE()) then true;
     case (R_FUNCTION(),R_FUNCTION()) then true;
     case (R_EXT_FUNCTION(),R_EXT_FUNCTION()) then true;
     case (R_ENUMERATION(),R_ENUMERATION()) then true;
     case (R_PREDEFINED_INT(),R_PREDEFINED_INT()) then true;
     case (R_PREDEFINED_REAL(),R_PREDEFINED_REAL()) then true;
     case (R_PREDEFINED_STRING(),R_PREDEFINED_STRING()) then true;
     case (R_PREDEFINED_BOOL(),R_PREDEFINED_BOOL()) then true;
     case (R_PREDEFINED_ENUM(),R_PREDEFINED_ENUM()) then true;
     case (_,_) then false;
   end matchcontinue;
 end restrictionEqual;

 protected function classDefEqual "Returns true if Two ClassDef's are equal"
 input ClassDef cdef1;
 input ClassDef cdef2;
 output Boolean equal;
 algorithm
   equal := matchcontinue(cdef1,cdef2)
     case(PARTS(elts1,eqns1,ieqns1,algs1,ialgs1,_),PARTS(elts2,eqns2,ieqns2,algs2,ialgs2,_))
       local
         list<Element> elts1,elts2;
         list<Equation> eqns1,eqns2;
         list<Equation> ieqns1,ieqns2;
         list<Algorithm> algs1,algs2;
         list<Algorithm> ialgs1,ialgs2;
         list<Boolean> blst1,blst2,blst3,blst4,blst5,blst;
       equation
         blst1 = Util.listThreadMap(elts1,elts2,elementEqual);
         blst2 = Util.listThreadMap(eqns1,eqns2,equationEqual);
         blst3 = Util.listThreadMap(ieqns1,ieqns2,equationEqual);
         blst4 = Util.listThreadMap(algs1,algs2,algorithmEqual);
         blst5 = Util.listThreadMap(ialgs1,ialgs2,algorithmEqual);
         blst = Util.listFlatten({blst1,blst2,blst3,blst4,blst5});
         equal = Util.boolAndList(blst);
       then equal;
     case (DERIVED(tySpec1,mod1),DERIVED(tySpec2,mod2))
       local
         Absyn.TypeSpec tySpec1, tySpec2;
         Mod mod1,mod2;
         Boolean b1,b2;
       equation
         b1 = ModUtil.typeSpecEqual(tySpec1, tySpec2);
         b2 = modEqual(mod1,mod2);
         equal = Util.boolAndList({b1,b2});
       then equal;
     case (ENUMERATION(ilst1),ENUMERATION(ilst2))
       local list<Ident> ilst1,ilst2;
         list<Boolean> blst;
       equation
         blst = Util.listThreadMap(ilst1,ilst2,stringEqual);
         equal = Util.boolAndList(blst);
       then equal;
     case (CLASS_EXTENDS(_,_,_,_,_,_,_),CLASS_EXTENDS(_,_,_,_,_,_,_))
       equation
         print("classDefEqual on CLASS_EXTENDS not implemented yet\n");
       then false;
     case (PDER(_,_),PDER(_,_)) equation
       print("classDefEqual on PDER not impl. yet\n");
     then false;
     case(_,_) then false;
   end matchcontinue;
end classDefEqual;

 protected function arraydimOptEqual " Returns true if two Option<ArrayDim> are equal"
   input Option<Absyn.ArrayDim> adopt1;
   input Option<Absyn.ArrayDim> adopt2;
   output Boolean equal;
 algorithm
   equal := matchcontinue(adopt1,adopt2)
     case(NONE(),NONE()) then true;
     case(SOME(lst1),SOME(lst2))
       local
         list<Absyn.Subscript> lst1,lst2;
         list<Boolean> blst;
       equation
           blst = Util.listThreadMap(lst1,lst2,subscriptEqual);
           equal = Util.boolAndList(blst);
       then equal;
   end matchcontinue;
end arraydimOptEqual;

protected function subscriptEqual "Returns true if two Absyn.Subscript's are equal"
input Absyn.Subscript sub1;
input Absyn.Subscript sub2;
output Boolean equal;
algorithm
  equal := matchcontinue(sub1,sub2)
    case(Absyn.NOSUB,Absyn.NOSUB) then true;
    case(Absyn.SUBSCRIPT(e1),Absyn.SUBSCRIPT(e2))
      local
        Absyn.Exp e1,e2;
        equation
          equal=Absyn.expEqual(e1,e2);
          then equal;
    case (_,_) then false;
  end matchcontinue;
end subscriptEqual;


protected function algorithmEqual "Returns true if two Algorithm's are equal."
  input Algorithm alg1;
  input Algorithm alg2;
  output Boolean equal;
algorithm
  equal := matchcontinue(alg1,alg2)
    case(ALGORITHM(a1,_),ALGORITHM(a2,_))
      local
        list<Absyn.Algorithm> a1,a2;
        list<Boolean> blst;
      equation
        blst = Util.listThreadMap(a1,a2,algorithmEqual2);
        equal = Util.boolAndList(blst);
      then equal;
  end matchcontinue;
end algorithmEqual;

protected function algorithmEqual2 "Returns true if two Absyn.Algorithm's are equal."
 input Absyn.Algorithm a1;
 input Absyn.Algorithm a2;
 output Boolean equal;
 algorithm
   equal := matchcontinue(a1,a2)
     case(Absyn.ALG_ASSIGN(Absyn.CREF(cr1),e1),Absyn.ALG_ASSIGN(Absyn.CREF(cr2),e2))
       local
         Absyn.ComponentRef cr1,cr2;
         Absyn.Exp e1,e2;
         Boolean b1,b2;
       equation
           b1 = Absyn.crefEqual(cr1,cr2);
           b2 = Absyn.expEqual(e1,e2);
           equal = boolAnd(b1,b2);
       then equal;
     case(Absyn.ALG_ASSIGN(e11 as Absyn.TUPLE(_),e12),Absyn.ALG_ASSIGN(e21 as Absyn.TUPLE(_),e22))
       local
         Absyn.Exp e11,e12,e21,e22;
         Boolean b1,b2;
       equation
           b1 = Absyn.expEqual(e11,e21);
           b2 = Absyn.expEqual(e12,e22);
           equal = boolAnd(b1,b2);
       then equal;
     case(Absyn.ALG_IF(_,_,_,_),Absyn.ALG_IF(_,_,_,_)) // TODO: ALG_IF
			then false;
     case (Absyn.ALG_FOR(_,_),Absyn.ALG_FOR(_,_)) then false; // TODO: ALG_FOR
     case (Absyn.ALG_WHILE(_,_),Absyn.ALG_WHILE(_,_)) then false; // TODO: ALG_WHILE
     case(Absyn.ALG_WHEN_A(_,_,_),Absyn.ALG_WHEN_A(_,_,_)) then false; //TODO: ALG_WHILE
     case (Absyn.ALG_NORETCALL(_,_),Absyn.ALG_NORETCALL(_,_)) then false; //TODO: ALG_NORETCALL
     case(_,_) then false;
   end matchcontinue;
 end algorithmEqual2;

 protected function equationEqual "Returns true if two equations are equal."
 input Equation eqn1;
 input Equation eqn2;
 output Boolean equal;
 algorithm
   equal := matchcontinue(eqn1,eqn2)
     case (EQUATION(eq1,_),EQUATION(eq2,_)) local
       EEquation eq1,eq2;
       equation
         equal = equationEqual2(eq1,eq2);
         then equal;
   end matchcontinue;
 end equationEqual;

 protected function equationEqual2 "Helper function to equationEqual"
 input EEquation eq1;
 input EEquation eq2;
 output Boolean equal;
 algorithm
   equal := matchcontinue(eq1,eq2)
     case (EQ_IF(cond1,tb1,fb1),EQ_IF(cond2,tb2,fb2))
       local
         list<EEquation> tb1,fb1,tb2,fb2;
         Absyn.Exp cond1,cond2;
         list<Boolean> blst1,blst2,blst;
         Boolean b1;
       equation
         blst1 = Util.listThreadMap(tb1,tb2,equationEqual2);
         blst2 = Util.listThreadMap(fb1,fb2,equationEqual2);
         b1 = Absyn.expEqual(cond1,cond2);
         blst = Util.listFlatten({{b1},blst1,blst2});
         equal = Util.boolAndList(blst);
         then equal;
     case(EQ_EQUALS(e11,e12),EQ_EQUALS(e21,e22))
       local
         Absyn.Exp e11,e12,e21,e22;
         Boolean b1,b2;
       equation
         b1 = Absyn.expEqual(e11,e21);
         b2 = Absyn.expEqual(e21,e22);
         equal = boolAnd(b1,b2);
         then equal;
     case(EQ_CONNECT(cr11,cr12),EQ_CONNECT(cr21,cr22))
       local
         Absyn.ComponentRef cr11,cr12,cr21,cr22;
         Boolean b1,b2;
       equation
         b1 = Absyn.crefEqual(cr11,cr21);
         b2 = Absyn.crefEqual(cr12,cr22);
         equal = boolAnd(b1,b2);
         then equal;
     case (EQ_FOR(id1,exp1,eq1),EQ_FOR(id2,exp2,eq2))
       local
         Absyn.Ident id1,id2;
         Absyn.Exp exp1,exp2;
         list<EEquation> eq1,eq2;
         list<Boolean> blst1;
         Boolean b1,b2;
       equation
         blst1 = Util.listThreadMap(eq1,eq2,equationEqual2);
         b1 = Absyn.expEqual(exp1,exp2);
         b2 = stringEqual(id1,id2);
         equal = Util.boolAndList(b1::b2::blst1);
       then equal;
     case (EQ_WHEN(cond1,elst1,_),EQ_WHEN(cond2,elst2,_)) // TODO: elsewhen not checked yet.
       local
         Absyn.Exp cond1,cond2;
         list<EEquation> elst1,elst2;
         list<Boolean> blst1;
         Boolean b1;
       equation
         blst1 = Util.listThreadMap(elst1,elst2,equationEqual2);
         b1 = Absyn.expEqual(cond1,cond2);
         equal = Util.boolAndList(b1::blst1);
       then equal;

     case (EQ_ASSERT(c1,m1),EQ_ASSERT(c2,m2))
       local
         Absyn.Exp c1,c2,m1,m2;
         Boolean b1,b2;
       equation
         b1 = Absyn.expEqual(c1,c2);
         b2 = Absyn.expEqual(m1,m2);
         equal = boolAnd(b1,b2);
       then equal;
     case (EQ_REINIT(cr1,e1),EQ_REINIT(cr2,e2))
       local
         Absyn.ComponentRef cr1,cr2;
         Absyn.Exp e1,e2;
         Boolean b1,b2;
       equation
         b1 = Absyn.expEqual(e1,e2);
         b2 = Absyn.crefEqual(cr1,cr2);
         equal = boolAnd(b1,b2);
       then equal;
     case(_,_) then false;
   end matchcontinue;
 end equationEqual2;

 protected function modEqual "Return true if two Mod:s are equal"
   input Mod mod1;
   input Mod mod2;
   output Boolean equal;
 algorithm
   equal := matchcontinue(mod1,mod2)
   local
     case (MOD(f1,each1,submodlst1,SOME((e1,_))),MOD(f2,each2,submodlst2,SOME((e2,_))))
       local Boolean f1,f2,b1,b2,b3,b4; Absyn.Each each1,each2;
         list<SubMod> submodlst1,submodlst2;
         Absyn.Exp e1,e2;
       equation
         b1 = Util.boolEqual(f1,f2);
         b2 = Absyn.eachEqual(each1,each2);
         b3 = subModsEqual(submodlst1,submodlst2);
         b4 = Absyn.expEqual(e1,e2);
         equal = Util.boolAndList({b1,b2,b3,b4});
       then equal;
     case (MOD(f1,each1,submodlst1,_),MOD(f2,each2,submodlst2,_))
       local Boolean b1,b2,b3,f1,f2; Absyn.Each each1,each2;
         list<SubMod> submodlst1,submodlst2;
       equation
         b1 = Util.boolEqual(f1,f2);
         b2 = Absyn.eachEqual(each1,each2);
         b3 = subModsEqual(submodlst1,submodlst2);
         equal = Util.boolAndList({b1,b2,b3});
       then equal;
     case (NOMOD(),NOMOD()) then true;
     case (REDECL(f1,elts1),REDECL(f2,elts2))
       local list<Element> elts1,elts2;
         list<Boolean> blst; Boolean b1,f1,f2;
       equation
         b1 = Util.boolEqual(f1,f2);
         blst = Util.listThreadMap(elts1,elts2,elementEqual);
         equal = Util.boolAndList(b1::blst);
       then equal;
     case(_,_) then false;
   end matchcontinue;
end modEqual;

protected function subModsEqual "return true if two subModifier lists are equal"
  input list<SubMod>  subModLst1;
  input list<SubMod>  subModLst2;
  output Boolean equal;
algorithm
  equal := matchcontinue(subModLst1,subModLst2)
    case ({},{}) then true;

    case (NAMEMOD(id1,mod1)::subModLst1,NAMEMOD(id2,mod2)::subModLst2)
      local Ident id1,id2; Mod mod1,mod2; Boolean b1,b2,b3;
        equation
          b1 = stringEqual(id1,id2);
          b2 = modEqual(mod1,mod2);
          b3 = subModsEqual(subModLst1,subModLst2);
          equal = Util.boolAndList({b1,b2,b3});
        then equal;
    case (IDXMOD(ss1,mod1)::subModLst1,IDXMOD(ss2,mod2)::subModLst2)
      local list<Subscript> ss1,ss2; Mod mod1,mod2; Boolean b1,b2,b3;
        equation
          b1 = subscriptsEqual(ss1,ss2);
          b2 = modEqual(mod1,mod2);
          b3 = subModsEqual(subModLst1,subModLst2);
          equal = Util.boolAndList({b1,b2,b3});
        then equal;
    case (_,_) then false;
  end matchcontinue;
end subModsEqual;

protected function subscriptsEqual "Returns true if two subscript lists are equal"
  input list<Subscript> ss1;
  input list<Subscript> ss2;
  output Boolean equal;
algorithm
  equal := matchcontinue(ss1,ss2)
    case({},{}) then true;
    case(Absyn.NOSUB()::ss1,Absyn.NOSUB()::ss2)
      then subscriptsEqual(ss1,ss2);
    case(Absyn.SUBSCRIPT(e1)::ss1,Absyn.SUBSCRIPT(e2)::ss2)
      local Boolean b1,b2; Absyn.Exp e1,e2;
      equation
        b1 = Absyn.expEqual(e1,e2);
        b2 = subscriptsEqual(ss1,ss2);
        equal = Util.boolAndList({b1,b2});
        then equal;
    case(_,_) then false;
  end matchcontinue;
end subscriptsEqual;

 protected function attributesEqual "Returns true if two Atributes are equal"
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
        	b6 = Util.boolEqual(st1,st2); // added Modelica 3.1 stream connectors 
        	equal = Util.boolAndList({b1,b2,b3,b4,b5,b6});
        then equal;
  end matchcontinue;
end attributesEqual;

protected function accessibilityEqual "Returns true if two  Accessibliy:s are equal"
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

protected function variabilityEqual "Returns true if two Variablity:s are equal"
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

protected function directionEqual "Returns true if two Direction:s are equal"
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

protected function arrayDimEqual "Return true if two arraydims are equal"
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

end SCode;

