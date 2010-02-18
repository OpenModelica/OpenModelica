/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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

package SCodeUtil
" file:	       SCodeUtil.mo
  package:     SCodeUtil
  description: SCodeUtil translates Absyn to SCode intermediate form
 
  RCS: $Id$
 
  This module contains functions to translate from
  an Absyn data representation to a simplified version
  called SCode.
  The most important function in this module is the *translateAbsyn2SCode* 
  function which turns an abstract syntax tree into an SCode 
  representation. Also *translateClass*, *translateMod*, etc.
 
  The SCode representation is then used as input to the Inst module"

public import Absyn;
public import SCode;
public import RTOpts;

protected import MetaUtil;
protected import Dump;
protected import Debug;
protected import Util;
protected import Error;
protected import System;
protected import ExpandableConnectors;
protected import Inst;
protected import Ceval;
protected import InstanceHierarchy;

public function translateAbsyn2SCode 
"function: translateAbsyn2SCode
  This function takes an Absyn.Program 
  and constructs a SCode.Program from it.
  This particular version of translate tries to fix any uniontypes
  in the inProgram before translating further. This should probably
  be moved into Parser.parse since you have to modify the tree every
  single time you translate..."
  input Absyn.Program inProgram;
  output SCode.Program outProgram;
algorithm 
  outProgram := matchcontinue(inProgram)
    local
      SCode.Program sp;
      InstanceHierarchy.InstanceHierarchy ih;
      Boolean hasExpandableConnectors;

    case (inProgram)
      equation
        System.addToRoots(0, Inst.emptyInstHashTable());
        // adrpo: TODO! FIXME! disable function caching for now as some tests fail.
        // System.addToRoots(1, Ceval.emptyCevalHashTable());
        inProgram = MetaUtil.createMetaClassesInProgram(inProgram);
        
        // set the external flag that signals the presence of inner/outer components in the model
        System.setHasInnerOuterDefinitions(false);
        // set the external flag that signals the presence of expandable connectors in the model
        System.setHasExpandableConnectors(false);
        sp = translate2(inProgram);
        //print(Util.stringDelimitList(Util.listMap(sp, SCode.printClassStr), "\n"));
        // retrieve the expandable connector presence external flag
        hasExpandableConnectors = System.getHasExpandableConnectors();
        (ih, sp) = ExpandableConnectors.elaborateExpandableConnectors(sp, hasExpandableConnectors);
      then 
        sp;
  end matchcontinue;
end translateAbsyn2SCode;

protected function translate2
"function: translate2
  This function takes an Absyn.Program 
  and constructs a SCode.Program from it."
  input Absyn.Program inProgram;
  output SCode.Program outProgram; 
algorithm 
  outProgram := matchcontinue (inProgram)
    local
      SCode.Class c_1;
      SCode.Program cs_1;
      Absyn.Class c;
      list<Absyn.Class> cs,cs2;
      Absyn.Within w;
      Absyn.Program p;
      Absyn.TimeStamp ts;

    case (Absyn.PROGRAM(classes = {})) then {}; 
    case (Absyn.PROGRAM(classes = (c :: cs),within_ = w,globalBuildTimes=ts))
      equation
        c_1 = translateClass(c);
        /* MetaModelica extension. x07simbj */
        //cs2 = MetaUtil.createMetaClasses(c); /*Find the records in the union type and extend the ast
                                                //with the records as metarecords.
                                            //  */
        //cs = listAppend(cs2,cs);
        /* */
        cs_1 = translate2(Absyn.PROGRAM(cs,w,ts));
      then
        (c_1 :: cs_1);
        
    case (p)
      equation 
        Debug.fprint("failtrace", "-SCodeUtil.translateAbsyn2SCode2 failed\n");
      then
        fail();
  end matchcontinue;
end translate2;

public function translateClass 
"function: translateClass 
  This functions converts an Absyn.Class to a SCode.Class."
  input Absyn.Class inClass;
  output SCode.Class outClass;
algorithm 
  outClass := matchcontinue (inClass)
    local
      SCode.ClassDef d_1;
      SCode.Restriction r_1;
      Absyn.Class c;
      String n;
      Boolean p,f,e;
      Absyn.Restriction r;
      Absyn.ClassDef d;
      Absyn.Info file_info;



    case (c as Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = d,info = file_info))
      equation
        // Debug.fprint("translate", "Translating class:" +& n +& "\n");
        r_1 = translateRestriction(c, r); // uniontype will not get translated!
        d_1 = translateClassdef(d);
      then
        SCode.CLASS(n,p,e,r_1,d_1,file_info);
        
    case (c as Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = d,info = file_info))
      equation
				true = RTOpts.debugFlag("translate");
        Debug.fprintln("translate", "SCodeUtil.translateAbsyn2SCodeClass: Translating class failed:" +& n+&"\n");
      then
        fail();
  end matchcontinue;
end translateClass;

// Changed to public! krsta
public function translateRestriction 
"function: translateRestriction
  Convert a class restriction."
  input Absyn.Class inClass;
  input Absyn.Restriction inRestriction;
  output SCode.Restriction outRestriction;
algorithm 
  outRestriction := matchcontinue (inClass,inRestriction)
    local 
      Absyn.Class d;
      
    case (d,Absyn.R_FUNCTION()) equation true  = containsExternalFuncDecl(d); then SCode.R_EXT_FUNCTION();
    case (d,Absyn.R_FUNCTION()) equation false = containsExternalFuncDecl(d); then SCode.R_FUNCTION();
    case (_,Absyn.R_CLASS()) then SCode.R_CLASS(); 
    case (_,Absyn.R_MODEL()) then SCode.R_MODEL(); 
    case (_,Absyn.R_RECORD()) then SCode.R_RECORD();
    case (_,Absyn.R_BLOCK()) then SCode.R_BLOCK();

    case (_,Absyn.R_CONNECTOR()) then SCode.R_CONNECTOR(false); 
    case (_,Absyn.R_EXP_CONNECTOR()) equation System.setHasExpandableConnectors(true); then SCode.R_CONNECTOR(true);

    case (_,Absyn.R_OPERATOR()) then SCode.R_OPERATOR(false);
    case (_,Absyn.R_OPERATOR_FUNCTION()) then SCode.R_OPERATOR(true);
         
    case (_,Absyn.R_TYPE()) then SCode.R_TYPE();
    case (_,Absyn.R_PACKAGE()) then SCode.R_PACKAGE();
    case (_,Absyn.R_ENUMERATION()) then SCode.R_ENUMERATION();
    case (_,Absyn.R_PREDEFINED_INT()) then SCode.R_PREDEFINED_INT();
    case (_,Absyn.R_PREDEFINED_REAL()) then SCode.R_PREDEFINED_REAL();
    case (_,Absyn.R_PREDEFINED_STRING()) then SCode.R_PREDEFINED_STRING();
    case (_,Absyn.R_PREDEFINED_BOOL()) then SCode.R_PREDEFINED_BOOL();
    case (_,Absyn.R_PREDEFINED_ENUM()) then SCode.R_PREDEFINED_ENUM();
      
    case (_,Absyn.R_METARECORD(name,index)) //MetaModelica extension, added by x07simbj
      local
        Absyn.Path name;
        Integer index; 
      then SCode.R_METARECORD(name,index);
    case (_,Absyn.R_UNIONTYPE()) then SCode.R_UNIONTYPE(); /*MetaModelica extension added by x07simbj */
      
  end matchcontinue;
end translateRestriction;

protected function containsExternalFuncDecl 
"function: containExternalFuncDecl
  Returns true if the Absyn.Class contains an external function declaration."
  input Absyn.Class inClass;
  output Boolean outBoolean;
algorithm 
  outBoolean := matchcontinue (inClass)
    local
      Boolean res,b,c,d;
      String a;
      Absyn.Restriction e;
      list<Absyn.ClassPart> rest;
      Option<String> cmt;
      Absyn.Info file_info;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = (Absyn.EXTERNAL(externalDecl = _) :: _)))) then true; 
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.PARTS(classParts = (_ :: rest),comment = cmt),info = file_info))
      equation 
        res = containsExternalFuncDecl(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(rest,cmt),file_info));
      then
        res;
    /* adrpo: handling also the case model extends X external ... end X; */
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = (Absyn.EXTERNAL(externalDecl = _) :: _)))) then true;
    /* adrpo: handling also the case model extends X external ... end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (_ :: rest),comment = cmt),
                      info = file_info))
      equation
        res = containsExternalFuncDecl(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(rest,cmt),file_info));
      then
        res;
    case (_) then false; 
  end matchcontinue;
end containsExternalFuncDecl;

protected function translateClassdef 
"function: translateClassdef
  This function converts an Absyn.ClassDef to a SCode.ClassDef.  
  For the DERIVED case, the conversion is fairly trivial, but for 
  the PARTS case more work is needed.  
  The result contains separate lists for:
   elements, equations and algorithms, which are mixed in the input.
  LS: Divided the translateClassdef into separate functions for collecting the different parts"
  input Absyn.ClassDef inClassDef;
  output SCode.ClassDef outClassDef;
algorithm 
  outClassDef := matchcontinue (inClassDef)
    local
      SCode.Mod mod;
      Absyn.TypeSpec t;
      Absyn.ElementAttributes attr;
      list<Absyn.ElementArg> a,cmod;
      Option<Absyn.Comment> cmt;
      Option<String> cmtString;
      list<SCode.Element> els;
      list<SCode.Annotation> anns;
      list<SCode.Equation> eqs,initeqs;
      list<SCode.Algorithm> als,initals;
      Option<Absyn.ExternalDecl> decl;
      list<Absyn.ClassPart> parts;
      list<String> vars;
      list<SCode.Enum> lst_1;
      list<Absyn.EnumLiteral> lst;
      Option<SCode.Comment> scodeCmt;
      String name;
      Absyn.Path path;
      list<Absyn.Path> pathLst;

    case Absyn.DERIVED(typeSpec = t,attributes = attr,arguments = a,comment = cmt)
      equation 
        Debug.fprintln("translate", "translating derived class: " +& Dump.unparseTypeSpec(t));
        mod = translateMod(SOME(Absyn.CLASSMOD(a,NONE)), false, Absyn.NON_EACH()) "TODO: attributes of derived classes" ;
        scodeCmt = translateComment(cmt);
      then
        SCode.DERIVED(t,mod,attr,scodeCmt);

    case Absyn.PARTS(classParts = parts,comment = cmtString)
      equation 
        Debug.fprintln("translate", "translating class parts");
        //debug_print("translating-parts:", Dump.unparseClassPartStrLst(1, parts, true));
        els = translateClassdefElements(parts);
        anns = translateClassdefAnnotations(parts);
        eqs = translateClassdefEquations(parts);
        initeqs = translateClassdefInitialequations(parts);
        als = translateClassdefAlgorithms(parts);
        initals = translateClassdefInitialalgorithms(parts);
        decl = translateClassdefExternaldecls(parts);
        decl = translateAlternativeExternalAnnotation(decl,parts);
        scodeCmt = translateComment(SOME(Absyn.COMMENT(NONE, cmtString)));
      then
        SCode.PARTS(els,eqs,initeqs,als,initals,decl,anns,scodeCmt);

    case Absyn.ENUMERATION(Absyn.ENUMLITERALS(enumLiterals = lst), cmt)
      equation 
        Debug.fprintln("translate", "translating enumerations");
        lst_1 = translateEnumlist(lst);
        scodeCmt = translateComment(cmt);
      then
        SCode.ENUMERATION(lst_1, scodeCmt);

    case Absyn.ENUMERATION(Absyn.ENUM_COLON(), cmt) 
      equation
        Debug.fprintln("translate", "translating enumeration of ':'");
        scodeCmt = translateComment(cmt);       
      then 
        SCode.ENUMERATION({},scodeCmt);

    case Absyn.OVERLOAD(pathLst,cmt)
      equation
        Debug.fprintln("translate", "translating overloaded");
        scodeCmt = translateComment(cmt);
      then
        SCode.OVERLOAD(pathLst,scodeCmt);

    case Absyn.CLASS_EXTENDS(baseClassName = name,modifications = cmod,comment = cmtString,parts = parts)      
      equation 
        Debug.fprintln("translate", "translating model extends " +& name +& " ... end " +& name +& ";");
        els = translateClassdefElements(parts);
        anns = translateClassdefAnnotations(parts);
        eqs = translateClassdefEquations(parts);
        initeqs = translateClassdefInitialequations(parts);
        als = translateClassdefAlgorithms(parts);
        initals = translateClassdefInitialalgorithms(parts);
        mod = translateMod(SOME(Absyn.CLASSMOD(cmod,NONE)), false, Absyn.NON_EACH());
        scodeCmt = translateComment(SOME(Absyn.COMMENT(NONE, cmtString)));
      then
        SCode.CLASS_EXTENDS(name,mod,els,eqs,initeqs,als,initals,anns,scodeCmt);

    case Absyn.PDER(functionName = path,vars = vars, comment=cmt) 
      equation
        Debug.fprintln("translate", "translating pder( " +& Absyn.pathString(path) +& ", vars)");
        scodeCmt = translateComment(cmt);       
      then 
        SCode.PDER(path,vars,scodeCmt);
  end matchcontinue;
end translateClassdef;

protected function translateAlternativeExternalAnnotation 
"function translateAlternativeExternalAnnotation
  This function fills external declarations without annotation with the 
  first class annotation instead, since it is very common that an element 
  annotation is used for this purpose.
  For instance, instead of external \"C\" annotation(Library=\"foo.lib\";
  it says external \"C\" ; annotation(Library=\"foo.lib\";"
input Option<Absyn.ExternalDecl> decl;
input list<Absyn.ClassPart> parts;
output Option<Absyn.ExternalDecl> outDecl;
algorithm
  outDecl := matchcontinue(decl,parts)
    local 
      Absyn.Annotation ann;
      Option<SCode.Ident> name ;
      Option<String> l ;
      Option<Absyn.ComponentRef> out ;
      list<Absyn.Exp> a;
      list<Absyn.ElementItem> els;
      list<Absyn.ClassPart> cls;
    // none
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
		then translateAlternativeExternalAnnotation(decl,Absyn.PUBLIC(els)::cls);
	// Next classpart list
    case (decl as SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),Absyn.PUBLIC({})::cls)
		then translateAlternativeExternalAnnotation(decl,cls);
		  
	case (SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),Absyn.PROTECTED(Absyn.ANNOTATIONITEM(ann)::_)::_)
    then SOME(Absyn.EXTERNALDECL(name,l,out,a,SOME(ann)));
    // Next element in public list
    case(decl as SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),Absyn.PROTECTED(_::els)::cls)
		then translateAlternativeExternalAnnotation(decl,Absyn.PROTECTED(els)::cls);
	// Next classpart list
    case(decl as SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),Absyn.PROTECTED({})::cls)
		then translateAlternativeExternalAnnotation(decl,cls);
	// Next in list
	case(decl as SOME(Absyn.EXTERNALDECL(name,l,out,a,NONE)),_::cls)
		then translateAlternativeExternalAnnotation(decl,cls);
	// not found
    case (decl,_) then decl;
  end matchcontinue;
end translateAlternativeExternalAnnotation;

protected function translateEnumlist 
"function: translateEnumlist 
  Convert an EnumLiteral list to an Ident list. 
  Comments are lost."
  input list<Absyn.EnumLiteral> inAbsynEnumLiteralLst;
  output list<SCode.Enum> outEnumLst;
algorithm 
  outIdentLst := matchcontinue (inAbsynEnumLiteralLst)
    local
      list<SCode.Enum> res;
      String id;
      Option<Absyn.Comment> cmtOpt;
      Option<SCode.Comment> scodeCmtOpt;
      list<Absyn.EnumLiteral> rest;
      
    case ({}) then {}; 
    case ((Absyn.ENUMLITERAL(id, cmtOpt) :: rest))
      equation 
        scodeCmtOpt = translateComment(cmtOpt);
        res = translateEnumlist(rest);
      then
        (SCode.ENUM(id, scodeCmtOpt) :: res);
  end matchcontinue;
end translateEnumlist;

protected function translateClassdefElements 
"function: translateClassdefElements 
  Convert an Absyn.ClassPart list to an Element list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<SCode.Element> outElementLst;
algorithm 
  outElementLst := matchcontinue (inAbsynClassPartLst)
    local
      list<SCode.Element> els,es_1,els_1;
      list<Absyn.ElementItem> es;
      list<Absyn.ClassPart> rest;
      Absyn.ClassPart cp;
      
    case {} then {}; 
    case(Absyn.PUBLIC(contents = es) :: rest)
      equation 
        es_1 = translateEitemlist(es, false);      
        els = translateClassdefElements(rest);
        els_1 = listAppend(es_1, els);
      then
        els_1;
    case(Absyn.PROTECTED(contents = es) :: rest)
      equation 
        es_1 = translateEitemlist(es, true);      
        els = translateClassdefElements(rest);
        els_1 = listAppend(es_1, els);
      then
        els_1;
    case (_ :: rest) /* ignore all other than PUBLIC and PROTECTED, i.e. elements */ 
      then translateClassdefElements(rest);
  end matchcontinue;
end translateClassdefElements;

// stefan
protected function translateClassdefAnnotations
"function: translateClassdefAnnotations
  turns a list of Absyn.ClassPart into a list of Annotations"
  input list<Absyn.ClassPart> inClassPartList;
  output list<SCode.Annotation> outAnnotationList;
algorithm
  outAnnotationList := matchcontinue(inClassPartList)
    local
      list<SCode.Annotation> anns,anns1,anns2;
      list<Absyn.ElementItem> eilst;
      list<Absyn.ClassPart> cdr;
      list<Absyn.EquationItem> eqilst;
      
    case({}) then {};
    case(Absyn.PUBLIC(eilst) :: cdr)
      equation
        anns = translateAnnotations(eilst);
        anns1 = translateClassdefAnnotations(cdr);
        anns2 = listAppend(anns,anns1);
      then
        anns2;
    case(Absyn.PROTECTED(eilst) :: cdr)
      equation
        anns = translateAnnotations(eilst);
        anns1 = translateClassdefAnnotations(cdr);
        anns2 = listAppend(anns,anns1);
      then
        anns2;
    case(Absyn.EQUATIONS(eqilst) :: cdr)
      equation
        anns = translateAnnotationsEq(eqilst);
        anns1 = translateClassdefAnnotations(cdr);
        anns2 = listAppend(anns,anns1);
      then
        anns2;
    case(Absyn.INITIALEQUATIONS(eqilst) :: cdr)
      equation
        anns = translateAnnotationsEq(eqilst);
        anns1 = translateClassdefAnnotations(cdr);
        anns2 = listAppend(anns,anns1);
      then
        anns2;
    case(_ :: cdr)
      equation
        anns = translateClassdefAnnotations(cdr);
      then
        anns;
  end matchcontinue;
end translateClassdefAnnotations;

protected function translateClassdefEquations 
"function: translateClassdefEquations 
  Convert an Absyn.ClassPart list to an Equation list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<SCode.Equation> outEquationLst;
algorithm 
  outEquationLst := matchcontinue (inAbsynClassPartLst)
    local
      list<SCode.Equation> eqs,eql_1,eqs_1;
      list<Absyn.EquationItem> eql;
      list<Absyn.ClassPart> rest;
    case {} then {}; 
    case ((Absyn.EQUATIONS(contents = eql) :: rest))
      equation 
        eql_1 = translateEquations(eql);
        eqs = translateClassdefEquations(rest);        
        eqs_1 = listAppend(eqs, eql_1);
      then
        eqs_1;
    case (_ :: rest) /* ignore everthing other than equations */ 
      equation 
        eqs = translateClassdefEquations(rest);
      then
        eqs;
  end matchcontinue;
end translateClassdefEquations;

protected function translateClassdefInitialequations 
"function: translateClassdefInitialequations 
  Convert an Absyn.ClassPart list to an initial Equation list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<SCode.Equation> outEquationLst;
algorithm 
  outEquationLst := matchcontinue (inAbsynClassPartLst)
    local
      list<SCode.Equation> eqs,eql_1,eqs_1;
      list<Absyn.EquationItem> eql;
      list<Absyn.ClassPart> rest;
    case {} then {}; 
    case ((Absyn.INITIALEQUATIONS(contents = eql) :: rest))
      equation 
        eql_1 = translateEquations(eql);      
        eqs = translateClassdefInitialequations(rest);
        eqs_1 = listAppend(eqs, eql_1);
      then
        eqs_1;
    case (_ :: rest) /* ignore everthing other than equations */ 
      equation 
        eqs = translateClassdefInitialequations(rest);
      then
        eqs;
  end matchcontinue;
end translateClassdefInitialequations;

protected function translateClassdefAlgorithms 
"function: translateClassdefAlgorithms 
  Convert an Absyn.ClassPart list to an Algorithm list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<SCode.Algorithm> outAlgorithmLst;
algorithm 
  outAlgorithmLst := matchcontinue (inAbsynClassPartLst)
    local
      list<SCode.Algorithm> als,als_1;
      list<Absyn.Algorithm> al_1;
      list<Absyn.AlgorithmItem> al;
      list<Absyn.ClassPart> rest;
    case {} then {}; 
    case ((Absyn.ALGORITHMS(contents = al) :: rest))
      equation 
        al_1 = translateClassdefAlgorithmitems(al);      
        als = translateClassdefAlgorithms(rest);
        als_1 = (SCode.ALGORITHM(al_1,NONE) :: als);
      then
        als_1;
    case (_ :: rest) /* ignore everthing other than algorithms */ 
      equation 
        als = translateClassdefAlgorithms(rest);
      then
        als;
  end matchcontinue;
end translateClassdefAlgorithms;

protected function translateClassdefInitialalgorithms 
"function: translateClassdefInitialalgorithms 
  Convert an Absyn.ClassPart list to an initial Algorithm list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<SCode.Algorithm> outAlgorithmLst;
algorithm 
  outAlgorithmLst := matchcontinue (inAbsynClassPartLst)
    local
      list<SCode.Algorithm> als,als_1;
      list<Absyn.Algorithm> al_1;
      list<Absyn.AlgorithmItem> al;
      list<Absyn.ClassPart> rest;
    case {} then {}; 
    case ((Absyn.INITIALALGORITHMS(contents = al) :: rest))
      equation 
        al_1 = translateClassdefAlgorithmitems(al);      
        als = translateClassdefInitialalgorithms(rest);
        als_1 = (SCode.ALGORITHM(al_1,NONE) :: als);
      then
        als_1;
    case (_ :: rest) /* ignore everthing other than algorithms */ 
      equation 
        als = translateClassdefInitialalgorithms(rest);
      then
        als;
  end matchcontinue;
end translateClassdefInitialalgorithms;

protected function translateClassdefAlgorithmitems 
"function: translateClassdefAlgorithmitems 
  Convert an Absyn.AlgorithmItem list to an Absyn.Algorithm list.
  Comments are lost."
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  output list<Absyn.Algorithm> outAbsynAlgorithmLst;
algorithm 
  outAbsynAlgorithmLst := matchcontinue (inAbsynAlgorithmItemLst)
    local
      list<Absyn.Algorithm> res;
      Absyn.Algorithm alg;
      list<Absyn.AlgorithmItem> rest;
    case {} then {}; 
    case ((Absyn.ALGORITHMITEM(algorithm_ = alg) :: rest))
      equation 
        res = translateClassdefAlgorithmitems(rest);
      then
        (alg :: res);
    case (_ :: rest)
      equation 
        res = translateClassdefAlgorithmitems(rest);
      then
        res;
  end matchcontinue;
end translateClassdefAlgorithmitems;

protected function translateClassdefExternaldecls 
"function: translateClassdefExternaldecls 
  Converts an Absyn.ClassPart list to an Absyn.ExternalDecl option.
  The list should only contain one external declaration, so pick the first one."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Option<Absyn.ExternalDecl> outAbsynExternalDeclOption;
algorithm 
  outAbsynExternalDeclOption := matchcontinue (inAbsynClassPartLst)
    local
      Absyn.ExternalDecl decl;
      Option<Absyn.ExternalDecl> res;
      list<Absyn.ClassPart> rest;
    case ((Absyn.EXTERNAL(externalDecl = decl) :: _)) then SOME(decl); 
    case ((_ :: rest))
      equation 
        res = translateClassdefExternaldecls(rest);
      then
        res;
    case ({}) then NONE; 
  end matchcontinue;
end translateClassdefExternaldecls;

// Changed from protected to public. KS
public function translateEitemlist 
"function: translateEitemlist 
  This function converts a list of Absyn.ElementItem to a list of SCode.Element.  
  The boolean argument flags whether the elements are protected.
  Annotations are not translated, i.e. they are removed when converting to SCode."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Boolean inBoolean;
  output list<SCode.Element> outElementLst;
algorithm 
  outElementLst := matchcontinue (inAbsynElementItemLst,inBoolean)
    local
      list<SCode.Element> l,e_1,es_1;
      list<Absyn.ElementItem> es;
      Boolean prot;
      Absyn.Element e;
    case ({},_) then {}; 
    case ((Absyn.ANNOTATIONITEM(annotation_ = _) :: es),prot)
      equation 
        l = translateEitemlist(es, prot);
      then
        l;
    case ((Absyn.ELEMENTITEM(element = e) :: es),prot)
      equation 
        // Debug.fprintln("translate", "translating element: " +& Dump.unparseElementStr(1, e));
        e_1 = translateElement(e, prot);
        es_1 = translateEitemlist(es, prot);
        l = listAppend(e_1, es_1);
      then
        l;
  end matchcontinue;
end translateEitemlist;

// stefan
protected function translateAnnotations
"function: translateAnnotations
  turns a list of Absyn.ElementItem into a list of Annotations"
  input list<Absyn.ElementItem> inElementItemList;
  output list<SCode.Annotation> outAnnotationList;
algorithm
  outAnnotationList := matchcontinue(inElementItemList)
    local
      list<Absyn.ElementItem> cdr;
      Absyn.Annotation ann;
      SCode.Annotation res;
      list<SCode.Annotation> anns,anns_1;
    case({}) then {};
    case(Absyn.ANNOTATIONITEM(ann) :: cdr)
      equation
        res = translateAnnotation(ann);
        anns = translateAnnotations(cdr);
        anns_1 = res :: anns;
      then
        anns_1;
    case(_ :: cdr)
      equation
        anns = translateAnnotations(cdr);
      then
        anns;
    case(_)
      equation
        Debug.fprintln("failtrace","SCode.translateAnnotations failed");
      then
        fail();
  end matchcontinue;
end translateAnnotations;

// stefan
protected function translateAnnotationsEq
"function: translateAnnotations
  turns a list of Absyn.EquationItem into a list of Annotations"
  input list<Absyn.EquationItem> inEquationItemList;
  output list<SCode.Annotation> outAnnotationList;
algorithm
  outAnnotationList := matchcontinue(inEquationItemList)
    local
      list<Absyn.EquationItem> cdr;
      Absyn.Annotation ann;
      SCode.Annotation res;
      list<SCode.Annotation> anns,anns_1;
    case({}) then {};
    case(Absyn.EQUATIONITEMANN(ann) :: cdr)
      equation
        res = translateAnnotation(ann);
        anns = translateAnnotationsEq(cdr);
        anns_1 = res :: anns;
      then
        anns_1;
    case(_ :: cdr)
      equation
        anns = translateAnnotationsEq(cdr);
      then
        anns;
    case(_)
      equation
        Debug.fprintln("failtrace","SCode.translateAnnotationsEq failed");
      then
        fail();
  end matchcontinue;
end translateAnnotationsEq;

// stefan
protected function translateAnnotation
"function: translateAnnotation
  translates an Absyn.Annotation into an SCode.Annotation"
  input Absyn.Annotation inAnnotation;
  output SCode.Annotation outAnnotation;
algorithm
  outAnnotation := matchcontinue(inAnnotation)
    local
      list<Absyn.ElementArg> args;
      SCode.Annotation res;
      SCode.Mod m;
    case(Absyn.ANNOTATION(args))
      equation
        m = translateMod(SOME(Absyn.CLASSMOD(args,NONE)), false, Absyn.NON_EACH());
        res = SCode.ANNOTATION(m);
      then
        res;
  end matchcontinue;
end translateAnnotation;

public function translateElement 
"function: translateElement
  This function converts an Absyn.Element to a list of SCode.Element.  
  The original element may declare several components at once, and 
  those are separated to several declarations in the result."
  input Absyn.Element inElement;
  input Boolean inBoolean;
  output list<SCode.Element> outElementLst;
algorithm 
  outElementLst := matchcontinue (inElement,inBoolean)
    local
      list<SCode.Element> es;
      Boolean f,prot;
      Boolean inner_,outer_;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.ElementSpec s;
      Absyn.InnerOuter io;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> cc;
      Absyn.Path p;
      
    case (Absyn.ELEMENT(constrainClass = (cc as SOME(Absyn.CONSTRAINCLASS(elementSpec = Absyn.EXTENDS(path=p)))), finalPrefix = f,innerOuter = io, redeclareKeywords = repl,specification = s,info = info),prot)
      equation 
        es = translateElementspec(cc, f, io, repl,  prot, s,SOME(info));
      then
        es;
        
    case (Absyn.ELEMENT(constrainClass = cc,finalPrefix = f,innerOuter = io, redeclareKeywords = repl,specification = s,info = info),prot)
      equation 
        es = translateElementspec(cc, f, io, repl,  prot, s,SOME(info));
      then
        es;
        
    case(Absyn.DEFINEUNIT(name,args),prot) local Option<String> expOpt; Option<Real> weightOpt;
      list<Absyn.NamedArg> args; String name; 
      equation
        expOpt = translateDefineunitParam(args,"exp");
        weightOpt = translateDefineunitParam2(args,"weight");
    then {SCode.DEFINEUNIT(name,expOpt,weightOpt)};
  end matchcontinue;
end translateElement;

protected function translateDefineunitParam " help function to translateElement"
  input list<Absyn.NamedArg> args;
  input String arg;
  output Option<String> expOpt;
algorithm
  (expOpt) := matchcontinue(args,arg)
    local String str,name;
    case(Absyn.NAMEDARG(name,Absyn.STRING(str))::_,arg) equation
      true = name ==& arg;
    then SOME(str);
    case({},arg) then NONE;
    case(_::args,arg) then translateDefineunitParam(args,arg);  
  end matchcontinue;
end translateDefineunitParam;

protected function translateDefineunitParam2 " help function to translateElement"
  input list<Absyn.NamedArg> args;
  input String arg;
  output Option<Real> weightOpt;
algorithm
  (expOpt) := matchcontinue(args,arg)
    local String name; Real r;
    case(Absyn.NAMEDARG(name,Absyn.REAL(r))::_,arg) equation
      true = name ==& arg;
    then SOME(r);
    case({},arg) then NONE;
    case(_::args,arg) then translateDefineunitParam2(args,arg);  
  end matchcontinue;
end translateDefineunitParam2;

protected function translateElementspec 
"function: translateElementspec 
  This function turns an Absyn.ElementSpec to a list of SCode.Element.
  The boolean arguments say if the element is final and protected, respectively."
  input Option<Absyn.ConstrainClass> cc;
  input Boolean finalPrefix;
  input Absyn.InnerOuter io;
  input Option<Absyn.RedeclareKeywords> inAbsynRedeclareKeywordsOption2;
  input Boolean inBoolean3;
  input Absyn.ElementSpec inElementSpec4;
  input Option<Absyn.Info> info;
  output list<SCode.Element> outElementLst;
algorithm 
  outElementLst := matchcontinue (cc,finalPrefix,io,inAbsynRedeclareKeywordsOption2,inBoolean3,inElementSpec4,info)
    local
      SCode.ClassDef de_1;
      SCode.Restriction re_1;
      Boolean finalPrefix,prot,rp,pa,fi,e,repl_1,fl,st;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.Class cl;
      String n,ns,str;
      Absyn.Restriction re;
      Absyn.ClassDef de;
      Absyn.Info file_info;
      SCode.Mod mod;
      list<Absyn.ElementArg> args;
      list<SCode.Element> xs_1;
      SCode.Variability pa_1;
      list<SCode.Subscript> tot_dim,ad,d;
      Absyn.ElementAttributes attr;
      Absyn.Direction di;
      Absyn.TypeSpec t;
      Option<Absyn.Modification> m;
      Option<Absyn.Comment> comment;
      Option<SCode.Comment> comment_1;
      list<Absyn.ComponentItem> xs;
      Absyn.Import imp;
      Option<Absyn.Exp> cond;

    case (cc,finalPrefix,_,repl,prot,
      Absyn.CLASSDEF(replaceable_ = rp,
                     class_ = (cl as Absyn.CLASS(name = n,partialPrefix = pa,finalPrefix = fi,encapsulatedPrefix = e,restriction = re,
                                                 body = de,info = file_info))),info)
      equation 
        Debug.fprintln("translate", "translating local class: " +& n);
        re_1 = translateRestriction(cl, re); // uniontype will not get translated!
        de_1 = translateClassdef(de);
      then
        {SCode.CLASSDEF(n,finalPrefix,rp,SCode.CLASS(n,pa,e,re_1,de_1,file_info),NONE(),cc)};

    case (cc,finalPrefix,_,repl,prot,Absyn.EXTENDS(path = n,elementArg = args,annotationOpt = NONE),info)
      local Absyn.Path n;
      equation 
        Debug.fprintln("translate", "translating extends: " +& Absyn.pathString(n));
        mod = translateMod(SOME(Absyn.CLASSMOD(args,NONE)), false, Absyn.NON_EACH());
        ns = Absyn.pathString(n);
      then
        {SCode.EXTENDS(n,mod,NONE())};
    
    case (cc,finalPrefix,_,repl,prot,Absyn.EXTENDS(path = n,elementArg = args,annotationOpt = SOME(absann)),info)
      local Absyn.Path n; Absyn.Annotation absann; SCode.Annotation ann;
      equation 
        Debug.fprintln("translate", "translating extends: " +& Absyn.pathString(n));
        mod = translateMod(SOME(Absyn.CLASSMOD(args,NONE)), false, Absyn.NON_EACH());
        ns = Absyn.pathString(n);
        ann = translateAnnotation(absann);
      then
        {SCode.EXTENDS(n,mod,SOME(ann))};

    case (cc,_,_,_,_,Absyn.COMPONENTS(components = {}),info) then {};
 
    case (cc,finalPrefix,io,repl,prot,Absyn.COMPONENTS(attributes = 
      (attr as Absyn.ATTR(flowPrefix = fl,streamPrefix=st,variability = pa,direction = di,arrayDim = ad)),typeSpec = t,
      components = (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = n,arrayDim = d,modification = m),comment = comment,condition=cond) :: xs)),info)
      local Absyn.Variability pa;
      equation 
        Debug.fprintln("translate", "translating component: " +& n);
        setHasInnerOuterDefinitionsHandler(io);        
        xs_1 = translateElementspec(cc, finalPrefix, io, repl, prot, Absyn.COMPONENTS(attr,t,xs), info);
        mod = translateMod(m, false, Absyn.NON_EACH());          
        pa_1 = translateVariability(pa) "PR. This adds the arraydimension that may be specified together with the type of the component." ;
        tot_dim = listAppend(d, ad);
        repl_1 = translateRedeclarekeywords(repl);
        comment_1 = translateComment(comment);
      then
        (SCode.COMPONENT(n,io,finalPrefix,repl_1,prot,SCode.ATTR(tot_dim,fl,st,SCode.RW(),pa_1,di),t,mod,NONE,comment_1,cond,info,cc) :: xs_1);

    case (cc,finalPrefix,_,repl,prot,Absyn.IMPORT(import_ = imp),_) 
      equation
        Debug.fprintln("translate", "translating import: " +& Dump.unparseImportStr(imp));
      then 
        {SCode.IMPORT(imp)}; 
  end matchcontinue;
end translateElementspec;

protected function setHasInnerOuterDefinitionsHandler
"@author: adrpo
 This function will set the external flag that signals
 that a model has inner/outer component definitions"
  input Absyn.InnerOuter io;
algorithm
  _ := matchcontinue (io)
    // no inner outer!
    case (Absyn.UNSPECIFIED()) then ();
    // has inner, outer or innerouter components
    case (_)
      equation
         System.setHasInnerOuterDefinitions(true);
      then ();
  end matchcontinue;
end setHasInnerOuterDefinitionsHandler;

protected function translateRedeclarekeywords 
"function: translateRedeclarekeywords
  author: PA
  For now, translate to bool, replaceable."
  input Option<Absyn.RedeclareKeywords> inAbsynRedeclareKeywordsOption;
  output Boolean outBoolean;
algorithm 
  outBoolean := matchcontinue (inAbsynRedeclareKeywordsOption)
    case (SOME(Absyn.REPLACEABLE())) then true; 
    case (SOME(Absyn.REDECLARE_REPLACEABLE())) then true; 
    case (_) then false; 
  end matchcontinue;
end translateRedeclarekeywords;

protected function translateVariability 
"function: translateVariability 
  Converts an Absyn.Variability to SCode.Variability."
  input Absyn.Variability inVariability;
  output SCode.Variability outVariability;
algorithm 
  outVariability := matchcontinue (inVariability)
    case (Absyn.VAR())      then SCode.VAR(); 
    case (Absyn.DISCRETE()) then SCode.DISCRETE(); 
    case (Absyn.PARAM())    then SCode.PARAM(); 
    case (Absyn.CONST())    then SCode.CONST(); 
  end matchcontinue;
end translateVariability;

protected function translateEquations 
"function: translateEquations 
  This function transforms a list of Absyn.Equation to a list of
  SCode.Equation, by applying the translateEquation function to each
  equation."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<SCode.Equation> outEquationLst;
algorithm 
  outEquationLst := matchcontinue (inAbsynEquationItemLst)
    local
      SCode.EEquation e_1;
      list<SCode.Equation> es_1;
      Absyn.Equation e;
      list<Absyn.EquationItem> es;
      Option<Absyn.Comment> acom;
      Option<SCode.Comment> com;

    case {} then {};

    case (Absyn.EQUATIONITEM(equation_ = e,comment = acom) :: es)
      equation 
        // Debug.fprintln("translate", "translating equation: " +& Dump.unparseEquationStr(0, e));  
        com = translateComment(acom);
        e_1 = translateEquation(e,com);
        es_1 = translateEquations(es);
      then
        (SCode.EQUATION(e_1,NONE) :: es_1);
        
    case (Absyn.EQUATIONITEMANN(annotation_ = _) :: es)
      equation 
        es_1 = translateEquations(es);
      then
        es_1;
  end matchcontinue;
end translateEquations;


protected function translateEEquations 
"function: translateEEquations 
  Helper function to translateEquations"
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<SCode.EEquation> outEEquationLst;
algorithm 
  outEEquationLst := matchcontinue (inAbsynEquationItemLst)
    local
      SCode.EEquation e_1;
      list<SCode.EEquation> es_1;
      Absyn.Equation e;
      list<Absyn.EquationItem> es;
      Option<Absyn.Comment> acom;
      Option<SCode.Comment> com;

    case {} then {};
       
    case (Absyn.EQUATIONITEM(equation_ = e,comment = acom) :: es)
      equation 
        // Debug.fprintln("translate", "translating equation: " +& Dump.unparseEquationStr(0, e));
        com = translateComment(acom);
        e_1 = translateEquation(e,com);
        es_1 = translateEEquations(es);
      then
        (e_1 :: es_1);
        
    case (Absyn.EQUATIONITEMANN(annotation_ = _) :: es)
      equation 
        es_1 = translateEEquations(es);
      then
        es_1;
  end matchcontinue;
end translateEEquations;

// stefan
protected function translateComment
"function: translateComment
	turns an Absyn.Comment into an SCode.Comment"
	input Option<Absyn.Comment> inComment;
	output Option<SCode.Comment> outComment;
algorithm
  outComment := matchcontinue(inComment)
    local
      Absyn.Annotation absann;
      SCode.Annotation ann;
      String str;
      
    case(NONE) then NONE;
    case(SOME(Absyn.COMMENT(NONE,NONE))) then SOME(SCode.COMMENT(NONE,NONE));
    case(SOME(Absyn.COMMENT(NONE,SOME(str)))) then SOME(SCode.COMMENT(NONE,SOME(str)));
    case(SOME(Absyn.COMMENT(SOME(absann),NONE)))
      equation
        ann = translateAnnotation(absann);
      then
        SOME(SCode.COMMENT(SOME(ann),NONE));
    case(SOME(Absyn.COMMENT(SOME(absann),SOME(str))))
      equation
        ann = translateAnnotation(absann);
      then
        SOME(SCode.COMMENT(SOME(ann),SOME(str)));
  end matchcontinue;
end translateComment;

protected function translateEquation 
"function: translateEquation 
  The translation of equations are straightforward, with one exception.  
  If clauses are translated so that the SCode only contains simple if-else constructs, and no elseif.
  PR Arrays seem to keep their Absyn.mo structure."
  input Absyn.Equation inEquation;
  input Option<SCode.Comment> inComment;
  output SCode.EEquation outEEquation;
algorithm 
  outEEquation := matchcontinue (inEquation,inComment)
    local
      list<SCode.EEquation> tb_1,fb_1,eb_1,l_1;
      Absyn.Exp e,ee,econd_1,cond,econd,e1,e2;
      list<Absyn.EquationItem> tb,fb,ei,eb,l;
      SCode.EEquation eq;
      list<SCode.EEquation> eqns;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> eis,elsewhen_;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> elsewhen_1;
      tuple<Absyn.Exp, list<SCode.EEquation>> firstIf;
      Absyn.ComponentRef c1,c2,cr;
      String i;
      Absyn.ComponentRef fname;
      Absyn.FunctionArgs fargs;
      list<Absyn.ForIterator> restIterators;
      Option<SCode.Comment> com;
      
    case (Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = {},equationElseItems = fb),com)
      equation 
        tb_1 = translateEEquations(tb);
        fb_1 = translateEEquations(fb);
      then
        SCode.EQ_IF({e},{tb_1},fb_1,com);
        
    /* else-if branches are put as if branches in false branch */
    case (Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = eis,equationElseItems = fb),com)
      local 
        list<Absyn.Exp> conditions;
        list<list<Absyn.EquationItem>> trueBranches;
        list<list<SCode.EEquation>> trueEEquations; 
      equation
        (conditions,trueBranches) = Util.splitTuple2List((e,tb)::eis);
        trueEEquations = Util.listMap(trueBranches,translateEEquations);
        fb_1 = translateEEquations(fb);
      then
        SCode.EQ_IF(conditions,trueEEquations,fb_1,com);
        
    case (Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = ((ee,ei) :: eis),equationElseItems = fb),com)
      equation 
        /* adrpo: we do handle else if clauses in OpenModelica, what do we do with this??!
        eq = translateEquation(Absyn.EQ_IF(e,tb,{},{Absyn.EQUATIONITEM(Absyn.EQ_IF(ee,ei,eis,fb),NONE)}));
        then eq;
        */
        print(" failure in SCode==> translateEquation IF_EQ\n");
      then
        fail();
        
    case (Absyn.EQ_WHEN_E(whenExp = cond,whenEquations = tb,elseWhenEquations = ((econd,eb) :: elsewhen_)),com)
      equation 
        tb_1 = translateEEquations(tb);
        SCode.EQ_WHEN(econd_1,eb_1,elsewhen_1,com) = translateEquation(Absyn.EQ_WHEN_E(econd,eb,elsewhen_),com);
      then
        SCode.EQ_WHEN(cond,tb_1,((econd_1,eb_1) :: elsewhen_1),com);
        
    case (Absyn.EQ_WHEN_E(whenExp = cond,whenEquations = tb,elseWhenEquations = {}),com)
      equation 
        tb_1 = translateEEquations(tb);
      then
        SCode.EQ_WHEN(cond,tb_1,{},com);
        
    case (Absyn.EQ_EQUALS(leftSide = e1,rightSide = e2),com) then SCode.EQ_EQUALS(e1,e2,com); 
    case (Absyn.EQ_CONNECT(connector1 = c1,connector2 = c2),com) then SCode.EQ_CONNECT(c1,c2,com);
       
    case (Absyn.EQ_FOR(iterators = {(i,SOME(e))},forEquations = l),com) /* for loop with a single iterator with explicit range */
      equation 
        l_1 = translateEEquations(l);
      then
        SCode.EQ_FOR(i,e,l_1,com);
        
    case (Absyn.EQ_FOR(iterators = {(i,NONE())},forEquations = l),com) /* for loop with a single iterator with implicit range */
      equation 
        l_1 = translateEEquations(l);
      then
        SCode.EQ_FOR(i,Absyn.END(),l_1,com);
        
    case (Absyn.EQ_FOR(iterators = (i,SOME(e))::(restIterators as _::_),forEquations = l),com) /* for loop with multiple iterators */
      equation 
        eq = translateEquation(Absyn.EQ_FOR(restIterators,l),com);
      then
        SCode.EQ_FOR(i,e,{eq},com);
        
    case (Absyn.EQ_FOR(iterators = (i,NONE())::(restIterators as _::_),forEquations = l),com) /* for loop with multiple iterators */
      equation 
        eq = translateEquation(Absyn.EQ_FOR(restIterators,l),com);
      then
        SCode.EQ_FOR(i,Absyn.END(),{eq},com);
        
    case (Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT("assert", _),
                            functionArgs = Absyn.FUNCTIONARGS(args = {e1,e2},argNames = {})),com) 
      then SCode.EQ_ASSERT(e1,e2,com);
         
    case (Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT("terminate", _),
                            functionArgs = Absyn.FUNCTIONARGS(args = {e1},argNames = {})),com) 
      then SCode.EQ_TERMINATE(e1,com);
         
    case (Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT("reinit", _),
                            functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentRef = cr),e2},argNames = {})),com) 
      then SCode.EQ_REINIT(cr,e2,com);
         
    case (Absyn.EQ_NORETCALL(fname,fargs),com) 
      then SCode.EQ_NORETCALL(fname,fargs,com);
  end matchcontinue;
end translateEquation;

protected function translateElementAddinfo 
"function: translateElementAddinfo"
  input SCode.Element elem;
  input Absyn.Info nfo;
  output SCode.Element oelem;
algorithm 
  oelem := matchcontinue(elem,nfo)
    local 
      SCode.Ident a1;
      Absyn.InnerOuter a2; 
      Boolean a3,a4,a5;
      SCode.Attributes a6;
      Absyn.TypeSpec a7;
      SCode.Mod a8;
      SCode.OptBaseClass a9;
      Option<SCode.Comment> a10;
      Option<Absyn.Exp> a11;
      Option<Absyn.Info> a12;
      Option<Absyn.ConstrainClass> a13;
      
  case(SCode.COMPONENT(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13), nfo)
    then SCode.COMPONENT(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,SOME(nfo),a13);
      
  case(elem,_) then elem;
    end matchcontinue;
end translateElementAddinfo;

/* Modification management */
public function translateMod 
"function: translateMod
  Builds an SCode.Mod from an Absyn.Modification.  
  The boolean argument flags whether the modification is final."
  input Option<Absyn.Modification> inAbsynModificationOption;
  input Boolean inBoolean;
  input Absyn.Each inEach;
  output SCode.Mod outMod;
algorithm 
  outMod := matchcontinue (inAbsynModificationOption,inBoolean,inEach)
    local
      Absyn.Exp e;
      Boolean finalPrefix;
      Absyn.Each each_;
      list<SCode.SubMod> subs;
      list<Absyn.ElementArg> l;
      
    case (NONE,_,_) then SCode.NOMOD();  /* final */ 
    case (SOME(Absyn.CLASSMOD({},(SOME(e)))),finalPrefix,each_) then SCode.MOD(finalPrefix,each_,{},SOME((e,false))); 
    case (SOME(Absyn.CLASSMOD({},(NONE))),finalPrefix,each_) then SCode.MOD(finalPrefix,each_,{},NONE); 
    case (SOME(Absyn.CLASSMOD(l,SOME(e))),finalPrefix,each_)
      equation 
        subs = translateArgs(l);
      then
        SCode.MOD(finalPrefix,each_,subs,SOME((e,false)));
        
    case (SOME(Absyn.CLASSMOD(l,NONE)),finalPrefix,each_)
      equation 
        subs = translateArgs(l);
      then
        SCode.MOD(finalPrefix,each_,subs,NONE);
  end matchcontinue;
end translateMod;

protected function translateArgs 
"function: translateArgs
  author: LS
  Adding translate for the elementspec in the redeclaration"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<SCode.SubMod> outSubModLst;
algorithm 
  outSubModLst := matchcontinue (inAbsynElementArgLst)
    local
      list<SCode.SubMod> subs;
      SCode.Mod mod_1;
      SCode.SubMod sub;
      Boolean finalPrefix;
      Absyn.Each each_;
      Absyn.ComponentRef cref;
      Option<Absyn.Modification> mod;
      Option<String> cmt;
      list<Absyn.ElementArg> xs;
      String n;
      list<SCode.Element> elist;
      Absyn.RedeclareKeywords keywords;
      Absyn.ElementSpec spec;
      Option<Absyn.ConstrainClass> constropt;
      
    case {} then {}; 
    case ((Absyn.MODIFICATION(finalItem = finalPrefix,each_ = each_,componentRef = cref,modification = mod,comment = cmt) :: xs))
      equation 
        subs = translateArgs(xs);
        mod_1 = translateMod(mod, finalPrefix, each_);
        sub = translateSub(cref, mod_1);
      then
        (sub :: subs);
        
    case ((Absyn.REDECLARATION(finalItem = finalPrefix,redeclareKeywords = keywords,each_ = each_,elementSpec = spec,constrainClass = constropt) :: xs))
      equation 
        subs = translateArgs(xs);
        n = Absyn.elementSpecName(spec);
        elist = translateElementspec(constropt,finalPrefix, Absyn.UNSPECIFIED(), NONE, false, spec, NONE) 
        "LS:: do not know what to use for *protected*, so using false 
         LS:: do not know what to use for *replaceable*, so using false" ;
      then
        (SCode.NAMEMOD(n,SCode.REDECL(finalPrefix,elist)) :: subs);
        
  end matchcontinue;
end translateArgs;

protected function translateSub 
"function: translateSub
  This function converts a Absyn.ComponentRef plus a list 
  of modifications into a number of nested SCode.SUBMOD."
  input Absyn.ComponentRef inComponentRef;
  input SCode.Mod inMod;
  output SCode.SubMod outSubMod;
algorithm 
  outSubMod := matchcontinue (inComponentRef,inMod)
    local
      String c_str,mod_str,i;
      Absyn.ComponentRef c,path;
      SCode.Mod mod,mod_1;
      list<SCode.Subscript> ss;
      SCode.SubMod sub;

    /* First some rules to prevent bad modifications */
    case ((c as Absyn.CREF_IDENT(subscripts = (_ :: _))),(mod as SCode.MOD(subModLst = (_ :: _)))) 
      equation 
        c_str = Dump.printComponentRefStr(c);
        mod_str = SCode.printModStr(mod);
        Error.addMessage(Error.ILLEGAL_MODIFICATION, {mod_str,c_str});
      then
        fail();
    case ((c as Absyn.CREF_QUAL(subScripts = (_ :: _))),(mod as SCode.MOD(subModLst = (_ :: _))))
      equation 
        c_str = Dump.printComponentRefStr(c);
        mod_str = SCode.printModStr(mod);
        Error.addMessage(Error.ILLEGAL_MODIFICATION, {mod_str,c_str});
      then
        fail();
    /* Then the normal rules */
    case (Absyn.CREF_IDENT(name = i,subscripts = ss),mod) 
      equation 
        mod_1 = translateSubSub(ss, mod);
      then
        SCode.NAMEMOD(i,mod_1);
    case (Absyn.CREF_QUAL(name = i,subScripts = ss,componentRef = path),mod)
      equation 
        sub = translateSub(path, mod);
        mod = SCode.MOD(false,Absyn.NON_EACH(),{sub},NONE);
        mod_1 = translateSubSub(ss, mod);
      then
        SCode.NAMEMOD(i,mod_1);
  end matchcontinue;
end translateSub;

protected function translateSubSub 
"function: translateSubSub 
  This function is used to handle the case when a array component is
  indexed in the modification, so that only one or a limitied number
  of array elements should be modified."
  input list<SCode.Subscript> inSubscriptLst;
  input SCode.Mod inMod;
  output SCode.Mod outMod;
algorithm 
  outMod := matchcontinue (inSubscriptLst,inMod)
    local
      SCode.Mod m;
      list<SCode.Subscript> l;
    case ({},m) then m; 
    case (l,m) then SCode.MOD(false,Absyn.NON_EACH(),{SCode.IDXMOD(l,m)},NONE); 
  end matchcontinue;
end translateSubSub;

public function translateSCodeModToNArgs
"@author: adrpo
 this function translates a SCode.Mod into Absyn.NamedArg 
 and prefixes all *LOCAL* expressions with the given prefix.
 Example:
  Input:
   prefix       : world
   modifications: (gravityType  = gravityType, g  = g * Modelica.Math.Vectors.normalize(n), mue  = mue)
  Gives:
   namedArgs:     (gravityType  = world.gravityType, g  = world.g * Modelica.Math.Vectors.normalize(world.n), mue  = world.mue)"
  input String prefix "given prefix, example: world";
  input SCode.Mod mod "given modifications";
  output list<Absyn.NamedArg> namedArgs "the resulting named arguments";
algorithm
  namedArgs := matchcontinue(prefix, mod)
    local 
      list<Absyn.NamedArg> nArgs;
      list<SCode.SubMod> subModLst;
    
    case (prefix, SCode.MOD(subModLst = subModLst))
      equation
        nArgs = translateSubModToNArgs(prefix, subModLst);
      then 
        nArgs;
  end matchcontinue;
end translateSCodeModToNArgs;

public function translateSubModToNArgs
"@author: adrpo
 this function translates a SCode.SubMod into Absyn.NamedArg 
 and prefixes all *LOCAL* expressions with the given prefix."
  input String prefix "given prefix, example: world";
  input list<SCode.SubMod> subMods "given sub modifications";
  output list<Absyn.NamedArg> namedArgs "the resulting named arguments";
algorithm
  namedArgs := matchcontinue(prefix, subMods)
    local 
      list<Absyn.NamedArg> nArgs;
      list<SCode.SubMod> subModLst;
      SCode.Mod mod;
      Absyn.Exp exp;
      SCode.Ident ident;
    // deal with the empty list
    case (prefix, {}) then {};
    // deal with named modifiers
    case (prefix, SCode.NAMEMOD(ident, SCode.MOD(absynExpOption = SOME((exp,_))))::subModLst)
      equation
        nArgs = translateSubModToNArgs(prefix, subModLst);
        exp = prefixUnqualifiedCrefsFromExp(exp, prefix);
      then 
        Absyn.NAMEDARG(ident,exp)::nArgs;
  end matchcontinue;
end translateSubModToNArgs;

public function prefixTuple
  input tuple<Absyn.Exp, Absyn.Exp> expTuple;
  input String prefix;
  output tuple<Absyn.Exp, Absyn.Exp> prefixedExpTuple;
algorithm
  prefixedExp := matchcontinue(expTuple, prefix)
    local 
      Absyn.Exp e1,e2;
      
    case((e1, e2), prefix)
      equation
        e1 = prefixUnqualifiedCrefsFromExp(e1, prefix);
        e2 = prefixUnqualifiedCrefsFromExp(e2, prefix);
      then
        ((e1, e2));
  end matchcontinue;
end prefixTuple;

public function prefixUnqualifiedCrefsFromExpOpt
  input Option<Absyn.Exp> inExpOpt;
  input String prefix;
  output Option<Absyn.Exp> outExpOpt;
algorithm
  outExpOpt := matchcontinue(inExpOpt, prefix)
    local
      Absyn.Exp exp;
      
    case (NONE(), prefix) then NONE();
    case (SOME(exp), prefix)
      equation
        exp = prefixUnqualifiedCrefsFromExp(exp, prefix);
      then
        SOME(exp);
  end matchcontinue;
end prefixUnqualifiedCrefsFromExpOpt;

public function prefixUnqualifiedCrefsFromExpLst
  input list<Absyn.Exp> inExpLst;
  input String prefix;
  output list<Absyn.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue(inExpLst, prefix)
    local
      Absyn.Exp exp;
      list<Absyn.Exp> rest;
      
    case ({}, prefix) then {};
    case (exp::rest, prefix)
      equation
        exp = prefixUnqualifiedCrefsFromExp(exp, prefix);
        rest = prefixUnqualifiedCrefsFromExpLst(rest, prefix);
      then
        exp::rest;
  end matchcontinue;
end prefixUnqualifiedCrefsFromExpLst;

public function prefixFunctionArgs
  input Absyn.FunctionArgs inFunctionArgs;
  input String prefix;
  output Absyn.FunctionArgs outFunctionArgs;
algorithm
  outFunctionArgs := matchcontinue(inFunctionArgs, prefix)
    local
      Absyn.Exp exp;
      list<Absyn.Exp> args "args" ;
      list<Absyn.NamedArg> argNames "argNames" ;      

    case (Absyn.FUNCTIONARGS(args, argNames), prefix)
      equation
        args = prefixUnqualifiedCrefsFromExpLst(args, prefix);
      then
        Absyn.FUNCTIONARGS(args, argNames);
  end matchcontinue;
end prefixFunctionArgs;

public function prefixUnqualifiedCrefsFromExp
  input Absyn.Exp exp;
  input String prefix;
  output Absyn.Exp prefixedExp;
algorithm
  prefixedExp := matchcontinue(exp, prefix)
    local
      SCode.Ident s,sym;
      Integer x;
      Absyn.ComponentRef c,fcn;
      Absyn.Exp e1,e2,e1a,e2a,e,t,f,start,stop,step;
      Absyn.Operator op;
      list<tuple<Absyn.Exp, Absyn.Exp>> lst;
      Absyn.FunctionArgs args;
      list<Absyn.Exp> es;
      Absyn.MatchType matchType;
      Absyn.Exp head, rest;
      Absyn.Exp inputExp;
      list<Absyn.ElementItem> localDecls;
      list<Absyn.Case> cases;
      Option<String> comment;
      list<list<Absyn.Exp>> esLstLst;
      Option<Absyn.Exp> expOpt;
      
    // deal with basic types
    case (Absyn.INTEGER(_), _) then exp;
    case (Absyn.REAL(_), _) then exp;
    case (Absyn.STRING(_), _) then exp;
    case (Absyn.BOOL(_), _) then exp;      
    
    // do NOT prefix if you have qualified component references
    case (Absyn.CREF(componentRef = c as Absyn.CREF_QUAL(name=_)), _) then exp;
     
    // do prefix if you have simple component references
    case (Absyn.CREF(componentRef = c as Absyn.CREF_IDENT(name=_)), prefix)
      equation
        e = Absyn.crefExp(Absyn.CREF_QUAL(prefix, {}, c));
      then
        e;
    // binary 
    case (Absyn.BINARY(exp1 = e1,op = op,exp2 = e2), prefix)
      equation
        e1a = prefixUnqualifiedCrefsFromExp(e1, prefix);
        e2a = prefixUnqualifiedCrefsFromExp(e2, prefix);
      then
        Absyn.BINARY(e1a, op, e2a);
    // unary
    case (Absyn.UNARY(op = op, exp = e), prefix)
      equation
        e = prefixUnqualifiedCrefsFromExp(e, prefix);        
      then
        Absyn.UNARY(op, e);
    // binary logical 
    case (Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2), prefix)
      equation
        e1a = prefixUnqualifiedCrefsFromExp(e1, prefix);
        e2a = prefixUnqualifiedCrefsFromExp(e2, prefix);
      then
        Absyn.LBINARY(e1a, op, e2a);
    // unary logical
    case (Absyn.LUNARY(op = op,exp = e), prefix)
      equation
        e = prefixUnqualifiedCrefsFromExp(e, prefix);      
      then
        Absyn.LUNARY(op, e);
    // relations
    case (Absyn.RELATION(exp1 = e1,op = op,exp2 = e2), prefix)
      equation
        e1a = prefixUnqualifiedCrefsFromExp(e1, prefix);
        e2a = prefixUnqualifiedCrefsFromExp(e2, prefix);
      then
        Absyn.RELATION(e1a, op, e2a);
    // if expressions
    case (Absyn.IFEXP(ifExp = c,trueBranch = t,elseBranch = f,elseIfBranch = lst), prefix)
      local Absyn.Exp c;
      equation
        c = prefixUnqualifiedCrefsFromExp(c, prefix);
        t = prefixUnqualifiedCrefsFromExp(t, prefix);
        f = prefixUnqualifiedCrefsFromExp(f, prefix);
        lst = Util.listMap1(lst, prefixTuple, prefix); // TODO! fixme, prefix these also.
      then
        Absyn.IFEXP(c, t, f, lst);
    // calls
    case (Absyn.CALL(function_ = fcn,functionArgs = args), prefix)      
      equation
        args = prefixFunctionArgs(args, prefix);
      then
        Absyn.CALL(fcn, args);
    // partial evaluated functions
    case (Absyn.PARTEVALFUNCTION(function_ = fcn, functionArgs = args), prefix)
      equation
        args = prefixFunctionArgs(args, prefix);
      then
        Absyn.PARTEVALFUNCTION(fcn, args);
    // arrays
    case (Absyn.ARRAY(arrayExp = es), prefix)
      equation
        es = Util.listMap1(es, prefixUnqualifiedCrefsFromExp, prefix);
      then
        Absyn.ARRAY(es);
    // tuples
    case (Absyn.TUPLE(expressions = es), prefix)
      equation
        es = Util.listMap1(es, prefixUnqualifiedCrefsFromExp, prefix);      
      then
        Absyn.TUPLE(es);
    // matrix
    case (Absyn.MATRIX(matrix = esLstLst), prefix)
      equation
        esLstLst = Util.listMap1(esLstLst, prefixUnqualifiedCrefsFromExpLst, prefix);
      then
        Absyn.MATRIX(esLstLst);
    // range
    case (Absyn.RANGE(start = start,step = expOpt,stop = stop), prefix)
      equation
        start = prefixUnqualifiedCrefsFromExp(start, prefix);
        expOpt = prefixUnqualifiedCrefsFromExpOpt(expOpt, prefix);
        stop = prefixUnqualifiedCrefsFromExp(stop, prefix);
      then
        Absyn.RANGE(start, expOpt, stop);
    // end    
    case (Absyn.END(), prefix) then exp; 
    // MetaModelica expressions!
    case (Absyn.LIST(es), prefix)
      equation
        es = Util.listMap1(es, prefixUnqualifiedCrefsFromExp, prefix);
      then
        Absyn.LIST(es);
    // cons
    case (Absyn.CONS(head, rest), prefix)
      equation
        head = prefixUnqualifiedCrefsFromExp(head, prefix);
        rest = prefixUnqualifiedCrefsFromExp(rest, prefix);
      then
        Absyn.CONS(head, rest);
    // as
    case (Absyn.AS(s, rest), prefix)
      equation
        rest = prefixUnqualifiedCrefsFromExp(rest, prefix);
      then
        Absyn.AS(s, rest);
    // matchexp
    case (Absyn.MATCHEXP(matchType, inputExp, localDecls, cases, comment), prefix)        
      then
        Absyn.MATCHEXP(matchType, inputExp, localDecls, cases, comment);
    // something else, just return the expression
    case (_, prefix) then exp;
  end matchcontinue;
end prefixUnqualifiedCrefsFromExp;

end SCodeUtil;
