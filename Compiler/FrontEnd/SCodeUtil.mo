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

encapsulated package SCodeUtil
" file:        SCodeUtil.mo
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

protected import Builtin;
protected import Debug;
protected import Dump;
protected import Error;
protected import Global;
protected import Inst;
protected import InstanceHierarchy;
protected import List;
protected import MetaUtil;
protected import System;
protected import Types;
protected import Util;
protected import SCodeCheck;
protected import SCodeFlatten;
protected import SCodeDump;

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
  outProgram := match(inProgram)
    local
      SCode.Program spInitial, spAbsyn, sp;
      InstanceHierarchy.InstanceHierarchy ih;
      Boolean hasExpandableConnectors;
      list<Absyn.Class> inClasses,initialClasses;

    case (inProgram)
      equation
        setGlobalRoot(Global.instHashIndex, Inst.emptyInstHashTable());
        setGlobalRoot(Global.typesIndex,  Types.createEmptyTypeMemory());
        // adrpo: TODO! FIXME! disable function caching for now as some tests fail.
        // setGlobalRoot(Ceval.cevalHashIndex, Ceval.emptyCevalHashTable());
        Absyn.PROGRAM(classes=inClasses) = MetaUtil.createMetaClassesInProgram(inProgram);

        Absyn.PROGRAM(classes=initialClasses) = Builtin.getInitialFunctions();
        
        // set the external flag that signals the presence of inner/outer components in the model
        System.setHasInnerOuterDefinitions(false);
        // set the external flag that signals the presence of expandable connectors in the model
        System.setHasExpandableConnectors(false);
        // set the external flag that signals the presence of expandable connectors in the model
        System.setHasStreamConnectors(false);
        
        // translate builtin functions
        spInitial = List.fold(initialClasses, translate2, {});
        // call flatten program on the initial classes only
        spInitial = SCodeFlatten.flattenCompleteProgram(spInitial);
        spInitial = listReverse(spInitial);
        
        // translate given absyn to scode.
        spAbsyn = List.fold(inClasses, translate2, {});
        spAbsyn = listReverse(spAbsyn);
        
        // NOTE: we check duplicates separately for builtin
        //       and for absyn to allow duplicates of 
        //       ModelicaBuiltin.mo and MetaModelicaBuiltin.mo
        
        // check duplicates in builtin (initial) functions
        SCodeCheck.checkDuplicateClasses(spInitial);
        // check duplicates in absyn
        SCodeCheck.checkDuplicateClasses(spAbsyn);
         
        sp = listAppend(spInitial, spAbsyn);
      then
        sp;
  end match;
end translateAbsyn2SCode;

public function translate2
"Folds an Absyn.Program into SCode.Program."
  input Absyn.Class inClass;
  input SCode.Program acc;
  output SCode.Program outAcc;
protected
  SCode.Element cl;
algorithm
  cl := translateClass(inClass);
  // print("\n" +& SCodeDump.printElementStr(cl) +& "\n");
  outAcc := cl :: acc;
end translate2;

public function translateClass
  input Absyn.Class inClass;
  output SCode.Element outClass;
algorithm
  outClass := translateClass2(inClass, Error.getNumMessages());
end translateClass;

protected function translateClass2
  "This functions converts an Absyn.Class to a SCode.Class."
  input Absyn.Class inClass;
  input Integer inNumMessages;
  output SCode.Element outClass;
algorithm
  outClass := matchcontinue (inClass, inNumMessages)
    local
      SCode.ClassDef d_1;
      SCode.Restriction r_1;
      Absyn.Class c;
      String n;
      Boolean p,f,e;
      Absyn.Restriction r;
      Absyn.ClassDef d;
      Absyn.Info file_info;
      SCode.Element scodeClass;
      SCode.Final sFin;
      SCode.Encapsulated sEnc;
      SCode.Partial sPar;

    case (c as Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = d,info = file_info), _)
      equation
        // Debug.fprint("translate", "Translating class:" +& n +& "\n");
        r_1 = translateRestriction(c, r); // uniontype will not get translated!
        d_1 = translateClassdef(d,file_info);
        sFin = SCode.boolFinal(f);
        sEnc = SCode.boolEncapsulated(e);
        sPar = SCode.boolPartial(p);
        scodeClass = 
         SCode.CLASS(
           n,
           SCode.PREFIXES( // here we set only final as is a top level class!
             SCode.PUBLIC(),
             SCode.NOT_REDECLARE(),
             sFin,
             Absyn.NOT_INNER_OUTER(),
             SCode.NOT_REPLACEABLE()),
             sEnc,
             sPar,
             r_1,
             d_1,
             file_info);
      then
        scodeClass;

    case (c as Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = d,info = file_info), _)
      equation
        // Print out an internal error msg only if no other errors have already
        // been printed.
        true = intEq(Error.getNumMessages(), inNumMessages);
        n = "SCodeUtil.translateAbsyn2SCodeClass failed: " +& n;
        Error.addSourceMessage(Error.INTERNAL_ERROR,{n},file_info);
      then
        fail();
  end matchcontinue;
end translateClass2;

// Changed to public! krsta
public function translateRestriction
"function: translateRestriction
  Convert a class restriction."
  input Absyn.Class inClass;
  input Absyn.Restriction inRestriction;
  output SCode.Restriction outRestriction;
algorithm
  outRestriction := match (inClass,inRestriction)
    local
      Absyn.Class d;
      Absyn.Path name;
      Integer index;
      Boolean singleton;

    case (d,Absyn.R_FUNCTION()) then Util.if_(containsExternalFuncDecl(d),SCode.R_EXT_FUNCTION(),SCode.R_FUNCTION());
    case (_,Absyn.R_CLASS()) then SCode.R_CLASS();
    case (_,Absyn.R_OPTIMIZATION()) then SCode.R_OPTIMIZATION();
    case (_,Absyn.R_MODEL()) then SCode.R_MODEL();
    case (_,Absyn.R_RECORD()) then SCode.R_RECORD();
    case (_,Absyn.R_BLOCK()) then SCode.R_BLOCK();

    case (_,Absyn.R_CONNECTOR()) then SCode.R_CONNECTOR(false);
    case (_,Absyn.R_EXP_CONNECTOR()) equation System.setHasExpandableConnectors(true); then SCode.R_CONNECTOR(true);

    case (_,Absyn.R_OPERATOR()) then SCode.R_OPERATOR();
    case (_,Absyn.R_OPERATOR_FUNCTION()) then SCode.R_OPERATOR_FUNCTION();
    case (_,Absyn.R_OPERATOR_RECORD()) then SCode.R_OPERATOR_RECORD();

    case (_,Absyn.R_TYPE()) then SCode.R_TYPE();
    case (_,Absyn.R_PACKAGE()) then SCode.R_PACKAGE();
    case (_,Absyn.R_ENUMERATION()) then SCode.R_ENUMERATION();
    case (_,Absyn.R_PREDEFINED_INTEGER()) then SCode.R_PREDEFINED_INTEGER();
    case (_,Absyn.R_PREDEFINED_REAL()) then SCode.R_PREDEFINED_REAL();
    case (_,Absyn.R_PREDEFINED_STRING()) then SCode.R_PREDEFINED_STRING();
    case (_,Absyn.R_PREDEFINED_BOOLEAN()) then SCode.R_PREDEFINED_BOOLEAN();
    case (_,Absyn.R_PREDEFINED_ENUMERATION()) then SCode.R_PREDEFINED_ENUMERATION();

    case (_,Absyn.R_METARECORD(name,index,singleton)) //MetaModelica extension, added by x07simbj
      then SCode.R_METARECORD(name,index,singleton);
    case (_,Absyn.R_UNIONTYPE()) then SCode.R_UNIONTYPE(); /*MetaModelica extension added by x07simbj */

  end match;
end translateRestriction;

protected function containsExternalFuncDecl
"function: containExternalFuncDecl
  Returns true if the Absyn.Class contains an external function declaration."
  input Absyn.Class inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inClass)
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
        res = containsExternalFuncDecl(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},rest,cmt),file_info));
      then
        res;
    /* adrpo: handling also the case model extends X external ... end X; */
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = (Absyn.EXTERNAL(externalDecl = _) :: _)))) then true;
    /* adrpo: handling also the case model extends X external ... end X; */
    case (Absyn.CLASS(name = a,partialPrefix = b,finalPrefix = c,encapsulatedPrefix = d,restriction = e,
                      body = Absyn.CLASS_EXTENDS(parts = (_ :: rest),comment = cmt),
                      info = file_info))
      equation
        res = containsExternalFuncDecl(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({},rest,cmt),file_info));
      then
        res;
    else false;
  end match;
end containsExternalFuncDecl;

protected function translateAttributes
"@author: adrpo
 translates from Absyn.ElementAttributes to SCode.Attributes"
  input Absyn.ElementAttributes inEA;
  input Absyn.ArrayDim extraArrayDim;
  output SCode.Attributes outA;
algorithm
  outA := matchcontinue(inEA,extraArrayDim)
    local
      Boolean f, s;
      Absyn.Variability v;
      Absyn.ArrayDim adim,extraADim;
      Absyn.Direction dir;
      SCode.Flow sf;
      SCode.Stream ss;
      SCode.Variability sv;
      
    case (Absyn.ATTR(f, s, v, dir, adim),extraADim)
      equation
        sf = SCode.boolFlow(f);
        ss = SCode.boolStream(s);
        sv = translateVariability(v);
        adim = listAppend(extraADim, adim);
      then
        SCode.ATTR(adim, sf, ss,  sv, dir);
  end matchcontinue;
end translateAttributes;

protected function translateClassdef
"function: translateClassdef
  This function converts an Absyn.ClassDef to a SCode.ClassDef.
  For the DERIVED case, the conversion is fairly trivial, but for
  the PARTS case more work is needed.
  The result contains separate lists for:
   elements, equations and algorithms, which are mixed in the input.
  LS: Divided the translateClassdef into separate functions for collecting the different parts"
  input Absyn.ClassDef inClassDef;
  input Absyn.Info info;
  output SCode.ClassDef outClassDef;
algorithm
  outClassDef := match (inClassDef,info)
    local
      SCode.Mod mod;
      Absyn.TypeSpec t;
      Absyn.ElementAttributes attr;
      list<Absyn.ElementArg> a,cmod;
      Option<Absyn.Comment> cmt;
      Option<String> cmtString;
      list<SCode.Element> els,tvels;
      list<SCode.Annotation> anns;
      list<SCode.Equation> eqs,initeqs;
      list<SCode.AlgorithmSection> als,initals;
      Option<SCode.ExternalDecl> decl;
      list<Absyn.ClassPart> parts;
      list<String> vars;
      list<SCode.Enum> lst_1;
      list<Absyn.EnumLiteral> lst;
      Option<SCode.Comment> scodeCmt;
      String name;
      Absyn.Path path;
      list<Absyn.Path> pathLst;
      list<String> typeVars;
      SCode.Attributes scodeAttr;

    case (Absyn.DERIVED(typeSpec = t,attributes = attr,arguments = a,comment = cmt),_)
      equation
        // Debug.fprintln("translate", "translating derived class: " +& Dump.unparseTypeSpec(t));
        mod = translateMod(SOME(Absyn.CLASSMOD(a,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH()) "TODO: attributes of derived classes";
        scodeAttr = translateAttributes(attr, {});
        scodeCmt = translateComment(cmt);
      then
        SCode.DERIVED(t,mod,scodeAttr,scodeCmt);

    case (Absyn.PARTS(typeVars = typeVars, classParts = parts,comment = cmtString),_)
      equation
        // Debug.fprintln("translate", "translating class parts");
        tvels = List.map1(typeVars, makeTypeVarElement, info);
        els = translateClassdefElements(parts);
        els = listAppend(tvels,els);
        anns = translateClassdefAnnotations(parts);
        eqs = translateClassdefEquations(parts);
        initeqs = translateClassdefInitialequations(parts);
        als = translateClassdefAlgorithms(parts);
        initals = translateClassdefInitialalgorithms(parts);
        decl = translateClassdefExternaldecls(parts);
        decl = translateAlternativeExternalAnnotation(decl,parts);
        scodeCmt = translateComment(SOME(Absyn.COMMENT(NONE(), cmtString)));
        SCodeCheck.checkDuplicateElements(els);
      then
        SCode.PARTS(els,eqs,initeqs,als,initals,decl,anns,scodeCmt);

    case (Absyn.ENUMERATION(Absyn.ENUMLITERALS(enumLiterals = lst), cmt),_)
      equation
        // Debug.fprintln("translate", "translating enumerations");
        lst_1 = translateEnumlist(lst);
        scodeCmt = translateComment(cmt);
        SCodeCheck.checkDuplicateEnums(lst_1);
      then
        SCode.ENUMERATION(lst_1, scodeCmt);

    case (Absyn.ENUMERATION(Absyn.ENUM_COLON(), cmt),_)
      equation
        // Debug.fprintln("translate", "translating enumeration of ':'");
        scodeCmt = translateComment(cmt);
      then
        SCode.ENUMERATION({},scodeCmt);

    case (Absyn.OVERLOAD(pathLst,cmt),_)
      equation
        // Debug.fprintln("translate", "translating overloaded");
        scodeCmt = translateComment(cmt);
      then
        SCode.OVERLOAD(pathLst,scodeCmt);

    case (Absyn.CLASS_EXTENDS(baseClassName = name,modifications = cmod,comment = cmtString,parts = parts),_)
      equation
        // Debug.fprintln("translate", "translating model extends " +& name +& " ... end " +& name +& ";");
        els = translateClassdefElements(parts);
        anns = translateClassdefAnnotations(parts);
        eqs = translateClassdefEquations(parts);
        initeqs = translateClassdefInitialequations(parts);
        als = translateClassdefAlgorithms(parts);
        initals = translateClassdefInitialalgorithms(parts);
        decl = translateClassdefExternaldecls(parts);
        decl = translateAlternativeExternalAnnotation(decl,parts);
        mod = translateMod(SOME(Absyn.CLASSMOD(cmod,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH());
        scodeCmt = translateComment(SOME(Absyn.COMMENT(NONE(), cmtString)));
        SCodeCheck.checkDuplicateElements(els);
      then
        SCode.CLASS_EXTENDS(name,mod,SCode.PARTS(els,eqs,initeqs,als,initals,decl,anns,scodeCmt));

    case (Absyn.PDER(functionName = path,vars = vars, comment=cmt),_)
      equation
        // Debug.fprintln("translate", "translating pder( " +& Absyn.pathString(path) +& ", vars)");
        scodeCmt = translateComment(cmt);
      then
        SCode.PDER(path,vars,scodeCmt);
  end match;
end translateClassdef;

protected function translateAlternativeExternalAnnotation
"function translateAlternativeExternalAnnotation
  This function fills external declarations without annotation with the
  first class annotation instead, since it is very common that an element
  annotation is used for this purpose.
  For instance, instead of external \"C\" annotation(Library=\"foo.lib\";
  it says external \"C\" ; annotation(Library=\"foo.lib\";"
input Option<SCode.ExternalDecl> decl;
input list<Absyn.ClassPart> parts;
output Option<SCode.ExternalDecl> outDecl;
algorithm
  outDecl := matchcontinue(decl,parts)
    local
      Absyn.Annotation aann;
      SCode.Annotation ann;
      Option<SCode.Ident> name ;
      Option<String> l ;
      Option<Absyn.ComponentRef> out ;
      list<Absyn.Exp> a;
      list<Absyn.ElementItem> els;
      list<Absyn.ClassPart> cls;
    // none
    case (NONE(),_) then NONE();
    // Already filled.
    case (decl as SOME(SCode.EXTERNALDECL(annotation_ = SOME(_))),_) then decl;
    // EXTERNALDECL.
    case (SOME(SCode.EXTERNALDECL(name,l,out,a,NONE())),Absyn.EXTERNAL(_,SOME(aann))::_)
      equation
        ann = translateAnnotation(aann);
      then SOME(SCode.EXTERNALDECL(name,l,out,a,SOME(ann)));
  // Annotation item.
    case (SOME(SCode.EXTERNALDECL(name,l,out,a,NONE())),Absyn.PUBLIC(Absyn.ANNOTATIONITEM(aann)::_)::_)
      equation
        ann = translateAnnotation(aann);
      then SOME(SCode.EXTERNALDECL(name,l,out,a,SOME(ann)));
    // Next element in public list
    case(decl as SOME(SCode.EXTERNALDECL(name,l,out,a,NONE())),Absyn.PUBLIC(_::els)::cls)
    then translateAlternativeExternalAnnotation(decl,Absyn.PUBLIC(els)::cls);
  // Next classpart list
    case (decl as SOME(SCode.EXTERNALDECL(name,l,out,a,NONE())),Absyn.PUBLIC({})::cls)
    then translateAlternativeExternalAnnotation(decl,cls);

  case (SOME(SCode.EXTERNALDECL(name,l,out,a,NONE())),Absyn.PROTECTED(Absyn.ANNOTATIONITEM(aann)::_)::_)
    equation
      ann = translateAnnotation(aann);
    then SOME(SCode.EXTERNALDECL(name,l,out,a,SOME(ann)));
    // Next element in public list
    case(decl as SOME(SCode.EXTERNALDECL(name,l,out,a,NONE())),Absyn.PROTECTED(_::els)::cls)
    then translateAlternativeExternalAnnotation(decl,Absyn.PROTECTED(els)::cls);
  // Next classpart list
    case(decl as SOME(SCode.EXTERNALDECL(name,l,out,a,NONE())),Absyn.PROTECTED({})::cls)
    then translateAlternativeExternalAnnotation(decl,cls);
  // Next in list
  case(decl as SOME(SCode.EXTERNALDECL(name,l,out,a,NONE())),_::cls)
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
  outEnumLst := match (inAbsynEnumLiteralLst)
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
  end match;
end translateEnumlist;

protected function translateClassdefElements
"function: translateClassdefElements
  Convert an Absyn.ClassPart list to an Element list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<SCode.Element> outElementLst;
algorithm
  outElementLst := match (inAbsynClassPartLst)
    local
      list<SCode.Element> els,es_1,els_1;
      list<Absyn.ElementItem> es;
      list<Absyn.ClassPart> rest;

    case {} then {};
    
    case(Absyn.PUBLIC(contents = es) :: rest)
      equation
        es_1 = translateEitemlist(es, SCode.PUBLIC());
        els = translateClassdefElements(rest);
        els_1 = listAppend(es_1, els);
      then
        els_1;
    
    case(Absyn.PROTECTED(contents = es) :: rest)
      equation
        es_1 = translateEitemlist(es, SCode.PROTECTED());
        els = translateClassdefElements(rest);
        els_1 = listAppend(es_1, els);
      then
        els_1;
    
    case (_ :: rest) /* ignore all other than PUBLIC and PROTECTED, i.e. elements */
      then translateClassdefElements(rest);
    
  end match;
end translateClassdefElements;

// stefan
protected function translateClassdefAnnotations
"function: translateClassdefAnnotations
  turns a list of Absyn.ClassPart into a list of Annotations"
  input list<Absyn.ClassPart> inClassPartList;
  output list<SCode.Annotation> outAnnotationList;
algorithm
  outAnnotationList := match (inClassPartList)
    local
      list<SCode.Annotation> anns,anns1,anns2;
      list<Absyn.ElementItem> eilst;
      list<Absyn.ClassPart> cdr;
      list<Absyn.EquationItem> eqilst;
      list<Absyn.AlgorithmItem> algilst;

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
    case(Absyn.ALGORITHMS(algilst) :: cdr)
      equation
        anns = translateAnnotationsAlg(algilst);
        anns1 = translateClassdefAnnotations(cdr);
        anns2 = listAppend(anns,anns1);
      then
        anns2;
    case(Absyn.INITIALALGORITHMS(algilst) :: cdr)
      equation
        anns = translateAnnotationsAlg(algilst);
        anns1 = translateClassdefAnnotations(cdr);
        anns2 = listAppend(anns,anns1);
      then
        anns2;
    case(_ :: cdr)
      equation
        anns = translateClassdefAnnotations(cdr);
      then
        anns;
  end match;
end translateClassdefAnnotations;

protected function translateClassdefEquations
"function: translateClassdefEquations
  Convert an Absyn.ClassPart list to an Equation list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<SCode.Equation> outEquationLst;
algorithm
  outEquationLst := match (inAbsynClassPartLst)
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
  end match;
end translateClassdefEquations;

protected function translateClassdefInitialequations
"function: translateClassdefInitialequations
  Convert an Absyn.ClassPart list to an initial Equation list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<SCode.Equation> outEquationLst;
algorithm
  outEquationLst := match (inAbsynClassPartLst)
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
  end match;
end translateClassdefInitialequations;

protected function translateClassdefAlgorithms
"function: translateClassdefAlgorithms
  Convert an Absyn.ClassPart list to an Algorithm list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<SCode.AlgorithmSection> outAlgorithmLst;
algorithm
  outAlgorithmLst := match (inAbsynClassPartLst)
    local
      list<SCode.AlgorithmSection> als,als_1;
      list<SCode.Statement> al_1;
      list<Absyn.AlgorithmItem> al;
      list<Absyn.ClassPart> rest;
      Absyn.ClassPart cp;
    case {} then {};
    case ((Absyn.ALGORITHMS(contents = al) :: rest))
      equation
        al_1 = translateClassdefAlgorithmitems(al);
        als = translateClassdefAlgorithms(rest);
        als_1 = (SCode.ALGORITHM(al_1) :: als);
      then
        als_1;
    case (cp :: rest) /* ignore everthing other than algorithms */
      equation
        failure(Absyn.ALGORITHMS(contents = _) = cp);
        als = translateClassdefAlgorithms(rest);
      then
        als;
    case _
      equation
        Debug.fprintln("failtrace", "- SCodeUtil.translateClassdefAlgorithms failed");
      then fail();
  end match;
end translateClassdefAlgorithms;

protected function translateClassdefInitialalgorithms
"function: translateClassdefInitialalgorithms
  Convert an Absyn.ClassPart list to an initial Algorithm list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<SCode.AlgorithmSection> outAlgorithmLst;
algorithm
  outAlgorithmLst := match (inAbsynClassPartLst)
    local
      list<SCode.AlgorithmSection> als,als_1;
      list<SCode.Statement> stmts;
      list<Absyn.AlgorithmItem> al;
      list<Absyn.ClassPart> rest;
    case {} then {};
    case ((Absyn.INITIALALGORITHMS(contents = al) :: rest))
      equation
        stmts = translateClassdefAlgorithmitems(al);
        als = translateClassdefInitialalgorithms(rest);
        als_1 = (SCode.ALGORITHM(stmts) :: als);
      then
        als_1;
    case (_ :: rest) /* ignore everthing other than algorithms */
      equation
        als = translateClassdefInitialalgorithms(rest);
      then
        als;
  end match;
end translateClassdefInitialalgorithms;

public function translateClassdefAlgorithmitems
"function: translateClassdefAlgorithmitems
  Filter out comments."
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  output list<SCode.Statement> outAbsynAlgorithmLst;
algorithm
  outAbsynAlgorithmLst := match (inAbsynAlgorithmItemLst)
    local
      list<Absyn.AlgorithmItem> rest;
      list<SCode.Statement> res;
      Absyn.Algorithm alg;
      SCode.Statement stmt;
      Option<Absyn.Comment> comment;
      Option<SCode.Comment> scomment;
      Absyn.Info info;
    case {} then {};
    case (Absyn.ALGORITHMITEM(algorithm_ = alg, comment = comment, info = info) :: rest)
      equation
        scomment = translateComment(comment);
        stmt = translateClassdefAlgorithmItem(alg,scomment,info);
        res = translateClassdefAlgorithmitems(rest);
      then
        (stmt :: res);
    case (Absyn.ALGORITHMITEMANN(annotation_ = _) :: rest)
      equation
        res = translateClassdefAlgorithmitems(rest);
      then
        res;
  end match;
end translateClassdefAlgorithmitems;

protected function translateClassdefAlgorithmItem
"Translates an Absyn algorithm (statement) into SCode statement"
  input Absyn.Algorithm alg;
  input Option<SCode.Comment> comment;
  input Absyn.Info info;
  output SCode.Statement stmt;
algorithm
  stmt := match (alg,comment,info)
    local
      Absyn.ForIterators iterators;
      Absyn.ComponentRef functionCall;
      Absyn.FunctionArgs functionArgs;
      Absyn.Exp assignComponent,value,boolExpr;
      list<SCode.Statement> stmts,stmts1,stmts2;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> branches;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> sbranches;
      list<Absyn.AlgorithmItem> body,elseBody;
      
    case (Absyn.ALG_ASSIGN(assignComponent,value),comment,info)
      then 
        SCode.ALG_ASSIGN(assignComponent,value,comment,info);
    
    case (Absyn.ALG_IF(boolExpr,body,branches,elseBody),comment,info)
      equation
        stmts1 = translateClassdefAlgorithmitems(body);
        stmts2 = translateClassdefAlgorithmitems(elseBody);
        sbranches = translateBranches(branches);
      then SCode.ALG_IF(boolExpr,stmts1,sbranches,stmts2,comment,info);

    case (Absyn.ALG_FOR(iterators,body),comment,info)
      equation
        stmts = translateClassdefAlgorithmitems(body);
      then SCode.ALG_FOR(iterators,stmts,comment,info);
  
    case (Absyn.ALG_WHILE(boolExpr,body),comment,info)
      equation
        stmts = translateClassdefAlgorithmitems(body);
      then SCode.ALG_WHILE(boolExpr,stmts,comment,info);
        
    case (Absyn.ALG_WHEN_A(boolExpr,body,branches),comment,info)
      equation
        branches = (boolExpr,body)::branches;
        sbranches = translateBranches(branches);
      then SCode.ALG_WHEN_A(sbranches,comment,info);

    case (Absyn.ALG_NORETCALL(functionCall,functionArgs),comment,info)
    then SCode.ALG_NORETCALL(functionCall,functionArgs,comment,info);
    
    case (Absyn.ALG_RETURN(),comment,info)
    then SCode.ALG_RETURN(comment,info);
    
    case (Absyn.ALG_BREAK(),comment,info)
    then SCode.ALG_BREAK(comment,info);
    
    case (Absyn.ALG_TRY(body),comment,info)
      equation
        stmts = translateClassdefAlgorithmitems(body);
      then SCode.ALG_TRY(stmts,comment,info);
        
    case (Absyn.ALG_CATCH(body),comment,info)
      equation
        stmts = translateClassdefAlgorithmitems(body);
      then SCode.ALG_CATCH(stmts,comment,info);
    
    case (Absyn.ALG_THROW(),comment,info)
    then SCode.ALG_THROW(comment,info);
    
    case (Absyn.ALG_FAILURE(body),comment,info)
      equation
        stmts = translateClassdefAlgorithmitems(body);
      then SCode.ALG_FAILURE(stmts,comment,info);
    
    /*
    case (_,comment,info)
      equation
        debug_print("- translateClassdefAlgorithmItem: ", alg);
      then fail();
    */
  end match;
end translateClassdefAlgorithmItem;

protected function translateBranches
"Converts the else-if or else-when branches from algorithm statements into SCode form"
  input list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> branches;
  output list<tuple<Absyn.Exp,list<SCode.Statement>>> sbranches;
algorithm
  sbranches := match branches
    local
      Absyn.Exp e;
      list<SCode.Statement> stmts;
      list<Absyn.AlgorithmItem> al;
    case {} then {};
    case ((e,al)::branches)
      equation
        stmts = translateClassdefAlgorithmitems(al);
        sbranches = translateBranches(branches);
      then (e,stmts)::sbranches;
  end match;
end translateBranches;

protected function translateClassdefExternaldecls
"function: translateClassdefExternaldecls
  Converts an Absyn.ClassPart list to an SCode.ExternalDecl option.
  The list should only contain one external declaration, so pick the first one."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Option<SCode.ExternalDecl> outAbsynExternalDeclOption;
algorithm
  outAbsynExternalDeclOption := match (inAbsynClassPartLst)
    local
      Absyn.ExternalDecl decl;
      Option<SCode.ExternalDecl> res;
      list<Absyn.ClassPart> rest;
      Option<SCode.Ident> fn_name;
      Option<String> lang;
      Option<Absyn.ComponentRef> output_;
      list<Absyn.Exp> args;
      Option<Absyn.Annotation> aann;
      Option<SCode.Annotation> sann;

    case (Absyn.EXTERNAL(externalDecl = 
        Absyn.EXTERNALDECL(fn_name, lang, output_, args, aann)) :: _)
      equation
        sann = Util.applyOption(aann, translateAnnotation);
      then SOME(SCode.EXTERNALDECL(fn_name, lang, output_, args, sann));
    case ((_ :: rest))
      equation
        res = translateClassdefExternaldecls(rest);
      then
        res;
    case ({}) then NONE();
  end match;
end translateClassdefExternaldecls;

public function translateEitemlist
"function: translateEitemlist
  This function converts a list of Absyn.ElementItem to a list of SCode.Element.
  The boolean argument flags whether the elements are protected.
  Annotations are not translated, i.e. they are removed when converting to SCode."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input SCode.Visibility inVisibility;
  output list<SCode.Element> outElementLst;
algorithm
  outElementLst := match (inAbsynElementItemLst,inVisibility)
    local
      list<SCode.Element> l,e_1,es_1;
      list<Absyn.ElementItem> es;
      SCode.Visibility vis;
      Absyn.Element e;
      
    case ({},_) then {};
    case ((Absyn.ANNOTATIONITEM(annotation_ = _) :: es),vis)
      equation
        l = translateEitemlist(es, vis);
      then
        l;
    case ((Absyn.ELEMENTITEM(element = e) :: es),vis)
      equation
        // Debug.fprintln("translate", "translating element: " +& Dump.unparseElementStr(1, e));
        e_1 = translateElement(e, vis);
        es_1 = translateEitemlist(es, vis);
        l = listAppend(e_1, es_1);
      then
        l;
  end match;
end translateEitemlist;

// stefan
protected function translateAnnotations
"function: translateAnnotations
  turns a list of Absyn.ElementItem into a list of Annotations"
  input list<Absyn.ElementItem> inElementItemList;
  output list<SCode.Annotation> outAnnotationList;
algorithm
  outAnnotationList := match (inElementItemList)
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
    else
      equation
        Debug.fprintln("failtrace","SCode.translateAnnotations failed");
      then
        fail();
  end match;
end translateAnnotations;

protected function translateAnnotationsEq
"@author: stefan
  function: translateAnnotationsEq
  turns a list of Absyn.EquationItem into a list of Annotations"
  input list<Absyn.EquationItem> inEquationItemList;
  output list<SCode.Annotation> outAnnotationList;
algorithm
  outAnnotationList := match (inEquationItemList)
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
  end match;
end translateAnnotationsEq;


protected function translateAnnotationsAlg
"@author: adrpo
  function: translateAnnotationsAlg
  turns a list of Absyn.AlgorithmItem into a list of Annotations"
  input list<Absyn.AlgorithmItem> inAlgorithmItemList;
  output list<SCode.Annotation> outAnnotationList;
algorithm
  outAnnotationList := match (inAlgorithmItemList)
    local
      list<Absyn.AlgorithmItem> cdr;
      Absyn.Annotation ann;
      SCode.Annotation res;
      list<SCode.Annotation> anns,anns_1;
    case({}) then {};
    case(Absyn.ALGORITHMITEMANN(ann) :: cdr)
      equation
        res = translateAnnotation(ann);
        anns = translateAnnotationsAlg(cdr);
        anns_1 = res :: anns;
      then
        anns_1;
    case(_ :: cdr)
      equation
        anns = translateAnnotationsAlg(cdr);
      then
        anns;
    case(_)
      equation
        Debug.fprintln("failtrace","SCode.translateAnnotationsAlg failed");
      then
        fail();
  end match;
end translateAnnotationsAlg;

// stefan
public function translateAnnotation
"function: translateAnnotation
  translates an Absyn.Annotation into an SCode.Annotation"
  input Absyn.Annotation inAnnotation;
  output SCode.Annotation outAnnotation;
algorithm
  outAnnotation := match (inAnnotation)
    local
      list<Absyn.ElementArg> args;
      SCode.Annotation res;
      SCode.Mod m;
    case(Absyn.ANNOTATION(args))
      equation
        m = translateMod(SOME(Absyn.CLASSMOD(args,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH());
        res = SCode.ANNOTATION(m);
      then
        res;
  end match;
end translateAnnotation;

public function translateElement
"function: translateElement
  This function converts an Absyn.Element to a list of SCode.Element.
  The original element may declare several components at once, and
  those are separated to several declarations in the result."
  input Absyn.Element inElement;
  input SCode.Visibility inVisibility;
  output list<SCode.Element> outElementLst;
algorithm
  outElementLst := match (inElement,inVisibility)
    local
      list<SCode.Element> es;
      Boolean f;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.ElementSpec s;
      Absyn.InnerOuter io;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> cc;
      Option<String> expOpt;
      Option<Real> weightOpt;
      list<Absyn.NamedArg> args;
      String name;
      SCode.Visibility vis;

    case (Absyn.ELEMENT(name = name, constrainClass = cc,finalPrefix = f,innerOuter = io, redeclareKeywords = repl,specification = s,info = info),vis)
      equation
        es = translateElementspec(cc, f, io, repl,  vis, s, info);
      then
        es;

    case(Absyn.DEFINEUNIT(name,args),vis)
      equation
        expOpt = translateDefineunitParam(args,"exp");
        weightOpt = translateDefineunitParam2(args,"weight");
      then {SCode.DEFINEUNIT(name,vis,expOpt,weightOpt)};
  end match;
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
    case({},arg) then NONE();
    case(_::args,arg) then translateDefineunitParam(args,arg);
  end matchcontinue;
end translateDefineunitParam;

protected function translateDefineunitParam2 " help function to translateElement"
  input list<Absyn.NamedArg> args;
  input String arg;
  output Option<Real> weightOpt;
algorithm
  weightOpt := matchcontinue(args,arg)
    local String name; Real r;
    case(Absyn.NAMEDARG(name,Absyn.REAL(r))::_,arg) equation
      true = name ==& arg;
    then SOME(r);
    case({},arg) then NONE();
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
  input SCode.Visibility inVisibility;
  input Absyn.ElementSpec inElementSpec4;
  input Absyn.Info info;
  output list<SCode.Element> outElementLst;
algorithm
  outElementLst := match (cc,finalPrefix,io,inAbsynRedeclareKeywordsOption2,inVisibility,inElementSpec4,info)
    local
      SCode.ClassDef de_1;
      SCode.Restriction re_1;
      Boolean prot,rp,pa,fi,e,repl_1,fl,st,redecl;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.Class cl;
      String n;
      Absyn.Restriction re;
      Absyn.ClassDef de;
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
      Absyn.Path path;
      Absyn.Annotation absann;
      SCode.Annotation ann;
      Absyn.Variability variability;
      Absyn.Info i;
      String str;
      SCode.Element cls;
      SCode.Redeclare sRed;
      SCode.Final sFin;
      SCode.Replaceable sRep;
      SCode.Encapsulated sEnc;
      SCode.Partial sPar;
      SCode.Visibility vis;
      SCode.Flow sFl;
      SCode.Stream sSt;
      Option<SCode.ConstrainClass> scc;

    case (cc,finalPrefix,_,repl,vis, Absyn.CLASSDEF(replaceable_ = rp, class_ = (cl as Absyn.CLASS(name = n,partialPrefix = pa,finalPrefix = fi,encapsulatedPrefix = e,restriction = re,body = de,info = i))),_)
      equation
        // Debug.fprintln("translate", "translating local class: " +& n);
        re_1 = translateRestriction(cl, re); // uniontype will not get translated!
        de_1 = translateClassdef(de,i);
        (_, redecl) = translateRedeclarekeywords(repl);
        sRed = SCode.boolRedeclare(redecl);
        sFin = SCode.boolFinal(finalPrefix);
        scc = translateConstrainClass(cc);
        sRep = Util.if_(rp,SCode.REPLACEABLE(scc),SCode.NOT_REPLACEABLE());
        sEnc = SCode.boolEncapsulated(e);
        sPar = SCode.boolPartial(pa); 
        cls = SCode.CLASS(
          n, 
          SCode.PREFIXES(vis,sRed,sFin,io,sRep), 
          sEnc, sPar, re_1, de_1, i);
      then
        {cls};

    case (cc,finalPrefix,_,repl,vis,Absyn.EXTENDS(path = path,elementArg = args,annotationOpt = NONE()),info)
      equation
        // Debug.fprintln("translate", "translating extends: " +& Absyn.pathString(n));
        mod = translateMod(SOME(Absyn.CLASSMOD(args,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH());
      then
        {SCode.EXTENDS(path,vis,mod,NONE(),info)};

    case (cc,finalPrefix,_,repl,vis,Absyn.EXTENDS(path = path,elementArg = args,annotationOpt = SOME(absann)),info)
      equation
        // Debug.fprintln("translate", "translating extends: " +& Absyn.pathString(n));
        mod = translateMod(SOME(Absyn.CLASSMOD(args,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH());
        ann = translateAnnotation(absann);
      then
        {SCode.EXTENDS(path,vis,mod,SOME(ann),info)};

    case (cc,_,_,_,_,Absyn.COMPONENTS(components = {}),info) then {};

    case (cc,finalPrefix,io,repl,vis,Absyn.COMPONENTS(attributes =
      (attr as Absyn.ATTR(flowPrefix = fl,streamPrefix=st,variability = variability,direction = di,arrayDim = ad)),typeSpec = t,
      components = (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = n,arrayDim = d,modification = m),comment = comment,condition=cond) :: xs)),info)
      equation
        true = SCodeCheck.checkIdentNotEqTypeName(n, t, info);
        // Debug.fprintln("translate", "translating component: " +& n +& " final: " +& SCode.finalStr(SCode.boolFinal(finalPrefix)));
        setHasInnerOuterDefinitionsHandler(io); // signal the external flag that we have inner/outer definitions
        setHasStreamConnectorsHandler(st);      // signal the external flag that we have stream connectors
        xs_1 = translateElementspec(cc, finalPrefix, io, repl, vis,
          Absyn.COMPONENTS(attr,t,xs), info);
        mod = translateMod(m, SCode.NOT_FINAL(), SCode.NOT_EACH());
        pa_1 = translateVariability(variability);
        // PR. This adds the arraydimension that may be specified together with the type of the component. 
        tot_dim = listAppend(d, ad);
        (repl_1, redecl) = translateRedeclarekeywords(repl);
        comment_1 = translateComment(comment);
        sFin = SCode.boolFinal(finalPrefix);
        sRed = SCode.boolRedeclare(redecl);
        scc = translateConstrainClass(cc);
        sRep = Util.if_(repl_1,SCode.REPLACEABLE(scc),SCode.NOT_REPLACEABLE());
        sFl = SCode.boolFlow(fl);
        sSt = SCode.boolStream(st);
      then
        (SCode.COMPONENT(n,
          SCode.PREFIXES(vis,sRed,sFin,io,sRep),
          SCode.ATTR(tot_dim,sFl,sSt,pa_1,di),
          t,mod,comment_1,cond,info) :: xs_1);

    case (cc,finalPrefix,_,repl,vis,Absyn.IMPORT(import_ = imp, info = info),_)
      equation
        // Debug.fprintln("translate", "translating import: " +& Dump.unparseImportStr(imp));
        xs_1 = translateImports(imp,vis,info);
      then
        xs_1;
  end match;
end translateElementspec;

protected function translateImports "Used to handle group imports, i.e. A.B.C.{x=a,b}"
  input Absyn.Import imp;
  input SCode.Visibility visibility;
  input Absyn.Info info;
  output list<SCode.Element> elts;
algorithm
  elts := match (imp,visibility,info)
    local
      Absyn.Path p;
      list<Absyn.GroupImport> groups;
    
    case (Absyn.GROUP_IMPORT(prefix=p,groups=groups),visibility,info)
      then List.map3(groups, translateGroupImport, p, visibility, info);
    else {SCode.IMPORT(imp, visibility, info)};
  end match;
end translateImports;

protected function translateGroupImport "Used to handle group imports, i.e. A.B.C.{x=a,b}"
  input Absyn.GroupImport gimp;
  input Absyn.Path prefix;
  input SCode.Visibility visibility;
  input Absyn.Info info;
  output SCode.Element elt;
algorithm
  elt := match (gimp,prefix,visibility,info)
    local
      String name,rename;
      Absyn.Path path;
      SCode.Visibility vis;
      
    case (Absyn.GROUP_IMPORT_NAME(name=name),prefix,vis,info)
      equation
        path = Absyn.joinPaths(prefix,Absyn.IDENT(name));
      then SCode.IMPORT(Absyn.QUAL_IMPORT(path),vis,info);
    case (Absyn.GROUP_IMPORT_RENAME(rename=rename,name=name),prefix,vis,info)
      equation
        path = Absyn.joinPaths(prefix,Absyn.IDENT(name));
      then SCode.IMPORT(Absyn.NAMED_IMPORT(rename,path),vis,info);
  end match;
end translateGroupImport;

protected function setHasInnerOuterDefinitionsHandler
"@author: adrpo
 This function will set the external flag that signals
 that a model has inner/outer component definitions"
  input Absyn.InnerOuter io;
algorithm
  _ := match (io)
    // no inner outer!
    case (Absyn.NOT_INNER_OUTER()) then ();
    // has inner, outer or innerouter components
    else
      equation
         System.setHasInnerOuterDefinitions(true);
      then ();
  end match;
end setHasInnerOuterDefinitionsHandler;

protected function setHasStreamConnectorsHandler
"@author: adrpo
 This function will set the external flag that signals
 that a model has stream connectors"
  input Boolean streamPrefix;
algorithm
  _ := match (streamPrefix)
    // no stream prefix
    case (false) then ();
    // has stream prefix
    case (true)
      equation
         System.setHasStreamConnectors(true);
      then ();
  end match;
end setHasStreamConnectorsHandler;

protected function translateRedeclarekeywords
"function: translateRedeclarekeywords
  author: PA
  For now, translate to bool, replaceable."
  input Option<Absyn.RedeclareKeywords> inRedeclKeywords;
  output Boolean outIsReplaceable;
  output Boolean outIsRedeclared;
algorithm
  (outIsReplaceable, outIsRedeclared) := match (inRedeclKeywords)
    case (SOME(Absyn.REDECLARE())) then (false, true);
    case (SOME(Absyn.REPLACEABLE())) then (true, false);
    case (SOME(Absyn.REDECLARE_REPLACEABLE())) then (true, true);
    else (false, false);
  end match;
end translateRedeclarekeywords;

protected function translateConstrainClass
  input Option<Absyn.ConstrainClass> inConstrainClass;
  output Option<SCode.ConstrainClass> outConstrainClass;
algorithm
  outConstrainClass := match(inConstrainClass)
    local
      Absyn.Path cc_path;
      list<Absyn.ElementArg> eltargs;
      Option<Absyn.Comment> cmt;
      Option<SCode.Comment> cc_cmt;
      Absyn.Modification mod;
      SCode.Mod cc_mod;

    case SOME(Absyn.CONSTRAINCLASS(elementSpec = 
        Absyn.EXTENDS(path = cc_path, elementArg = eltargs), comment = cmt))
      equation
        mod = Absyn.CLASSMOD(eltargs, Absyn.NOMOD());
        cc_mod = translateMod(SOME(mod), SCode.NOT_FINAL(), SCode.NOT_EACH());
        cc_cmt = translateComment(cmt);
      then
        SOME(SCode.CONSTRAINCLASS(cc_path, cc_mod, cc_cmt));
  
    else NONE();
  end match;
end translateConstrainClass;

protected function translateVariability
"function: translateVariability
  Converts an Absyn.Variability to SCode.Variability."
  input Absyn.Variability inVariability;
  output SCode.Variability outVariability;
algorithm
  outVariability := match (inVariability)
    case (Absyn.VAR())      then SCode.VAR();
    case (Absyn.DISCRETE()) then SCode.DISCRETE();
    case (Absyn.PARAM())    then SCode.PARAM();
    case (Absyn.CONST())    then SCode.CONST();
  end match;
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
      Absyn.Info info;
      String s1, s2;
      Absyn.ComponentRef c1, c2;

    case {} then {};

    // adrpo: check for connect(A, A) as we should give a warning and remove it!
    case (Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(c1, c2),comment = acom,info = info) :: es)
      equation
        true = Absyn.crefEqual(c1, c2);
        s1 = Dump.printComponentRefStr(c1);
        s2 = Dump.printComponentRefStr(c1);
        Error.addSourceMessage(Error.SAME_CONNECT_INSTANCE, {s1, s2}, info);
        es_1 = translateEquations(es);
      then
        (es_1);

    case (Absyn.EQUATIONITEM(equation_ = e,comment = acom,info = info) :: es)
      equation
        // Debug.fprintln("translate", "translating equation: " +& Dump.unparseEquationStr(0, e));
        com = translateComment(acom);
        e_1 = translateEquation(e,com,info);
        es_1 = translateEquations(es);
      then
        (SCode.EQUATION(e_1) :: es_1);

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
  outEEquationLst := match (inAbsynEquationItemLst)
    local
      SCode.EEquation e_1;
      list<SCode.EEquation> es_1;
      Absyn.Equation e;
      list<Absyn.EquationItem> es;
      Option<Absyn.Comment> acom;
      Option<SCode.Comment> com;
      Absyn.Info info;

    case {} then {};

    case (Absyn.EQUATIONITEM(equation_ = e,comment = acom,info = info) :: es)
      equation
        // Debug.fprintln("translate", "translating equation: " +& Dump.unparseEquationStr(0, e));
        com = translateComment(acom);
        e_1 = translateEquation(e,com,info);
        es_1 = translateEEquations(es);
      then
        (e_1 :: es_1);

    case (Absyn.EQUATIONITEMANN(annotation_ = _) :: es)
      equation
        es_1 = translateEEquations(es);
      then
        es_1;
  end match;
end translateEEquations;

// stefan
protected function translateComment
"function: translateComment
  turns an Absyn.Comment into an SCode.Comment"
  input Option<Absyn.Comment> inComment;
  output Option<SCode.Comment> outComment;
algorithm
  outComment := match (inComment)
    local
      Absyn.Annotation absann;
      SCode.Annotation ann;
      String str;

    case(NONE()) then NONE();
    case(SOME(Absyn.COMMENT(NONE(),NONE()))) then SOME(SCode.COMMENT(NONE(),NONE()));
    case(SOME(Absyn.COMMENT(NONE(),SOME(str)))) then SOME(SCode.COMMENT(NONE(),SOME(str)));
    case(SOME(Absyn.COMMENT(SOME(absann),NONE())))
      equation
        ann = translateAnnotation(absann);
      then
        SOME(SCode.COMMENT(SOME(ann),NONE()));
    case(SOME(Absyn.COMMENT(SOME(absann),SOME(str))))
      equation
        ann = translateAnnotation(absann);
      then
        SOME(SCode.COMMENT(SOME(ann),SOME(str)));
  end match;
end translateComment;

protected function translateEquation
"function: translateEquation
  The translation of equations are straightforward, with one exception.
  If clauses are translated so that the SCode only contains simple if-else constructs, and no elseif.
  PR Arrays seem to keep their Absyn.mo structure."
  input Absyn.Equation inEquation;
  input Option<SCode.Comment> inComment;
  input Absyn.Info info;
  output SCode.EEquation outEEquation;
algorithm
  outEEquation := matchcontinue (inEquation,inComment,info)
    local
      list<SCode.EEquation> tb_1,fb_1,eb_1,l_1;
      Absyn.Exp e,ee,econd_1,cond,econd,e1,e2;
      list<Absyn.EquationItem> tb,fb,ei,eb,l;
      SCode.EEquation eq;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> eis,elsewhen_;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> elsewhen_1;
      Absyn.ComponentRef c1,c2,cr;
      String i;
      Absyn.ComponentRef fname;
      Absyn.FunctionArgs fargs;
      list<Absyn.ForIterator> restIterators;
      Option<SCode.Comment> com;
      list<Absyn.Exp> conditions;
      list<list<Absyn.EquationItem>> trueBranches;
      list<list<SCode.EEquation>> trueEEquations;

    case (Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = {},equationElseItems = fb),com,info)
      equation
        tb_1 = translateEEquations(tb);
        fb_1 = translateEEquations(fb);
      then
        SCode.EQ_IF({e},{tb_1},fb_1,com,info);

    /* else-if branches are put as if branches in false branch */
    case (Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = eis,equationElseItems = fb),com,info)
      equation
        (conditions,trueBranches) = Util.splitTuple2List((e,tb)::eis);
        trueEEquations = List.map(trueBranches,translateEEquations);
        fb_1 = translateEEquations(fb);
      then
        SCode.EQ_IF(conditions,trueEEquations,fb_1,com,info);

    case (Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = ((ee,ei) :: eis),equationElseItems = fb),com,info)
      equation
        /* adrpo: we do handle else if clauses in OpenModelica, what do we do with this??!
        eq = translateEquation(Absyn.EQ_IF(e,tb,{},{Absyn.EQUATIONITEM(Absyn.EQ_IF(ee,ei,eis,fb),NONE())}));
        then eq;
        */
        print(" failure in SCode==> translateEquation IF_EQ\n");
      then
        fail();

    case (Absyn.EQ_WHEN_E(whenExp = cond,whenEquations = tb,elseWhenEquations = ((econd,eb) :: elsewhen_)),com,info)
      equation
        tb_1 = translateEEquations(tb);
        SCode.EQ_WHEN(econd_1,eb_1,elsewhen_1,com,info) = translateEquation(Absyn.EQ_WHEN_E(econd,eb,elsewhen_),com,info);
      then
        SCode.EQ_WHEN(cond,tb_1,((econd_1,eb_1) :: elsewhen_1),com,info);

    case (Absyn.EQ_WHEN_E(whenExp = cond,whenEquations = tb,elseWhenEquations = {}),com,info)
      equation
        tb_1 = translateEEquations(tb);
      then
        SCode.EQ_WHEN(cond,tb_1,{},com,info);

    case (Absyn.EQ_EQUALS(leftSide = e1,rightSide = e2),com,info) then SCode.EQ_EQUALS(e1,e2,com,info);
    case (Absyn.EQ_CONNECT(connector1 = c1,connector2 = c2),com,info) then SCode.EQ_CONNECT(c1,c2,com,info);

    case (Absyn.EQ_FOR(iterators = {Absyn.ITERATOR(i,NONE(),SOME(e))},forEquations = l),com,info) /* for loop with a single iterator with explicit range */
      equation
        l_1 = translateEEquations(l);
      then
        SCode.EQ_FOR(i,e,l_1,com,info);

    case (Absyn.EQ_FOR(iterators = {Absyn.ITERATOR(i,NONE(),NONE())},forEquations = l),com,info) /* for loop with a single iterator with implicit range */
      equation
        l_1 = translateEEquations(l);
      then
        SCode.EQ_FOR(i,Absyn.END(),l_1,com,info);

    case (Absyn.EQ_FOR(iterators = Absyn.ITERATOR(i,NONE(),SOME(e))::(restIterators as _::_),forEquations = l),com,info) /* for loop with multiple iterators */
      equation
        eq = translateEquation(Absyn.EQ_FOR(restIterators,l),com,info);
      then
        SCode.EQ_FOR(i,e,{eq},com,info);

    case (Absyn.EQ_FOR(iterators = Absyn.ITERATOR(i,NONE(),NONE())::(restIterators as _::_),forEquations = l),com,info) /* for loop with multiple iterators */
      equation
        eq = translateEquation(Absyn.EQ_FOR(restIterators,l),com,info);
      then
        SCode.EQ_FOR(i,Absyn.END(),{eq},com,info);

    case (Absyn.EQ_FOR(iterators = Absyn.ITERATOR(guardExp=SOME(_))::_,forEquations = l),_,info)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"For loops with guards not yet implemented"}, info);
      then
        fail();

    case (Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT("assert", _),
                            functionArgs = Absyn.FUNCTIONARGS(args = {e1,e2},argNames = {})),com,info)
      then SCode.EQ_ASSERT(e1,e2,com,info);

    case (Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT("terminate", _),
                            functionArgs = Absyn.FUNCTIONARGS(args = {e1},argNames = {})),com,info)
      then SCode.EQ_TERMINATE(e1,com,info);

    case (Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT("reinit", _),
                            functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentRef = cr),e2},argNames = {})),com,info)
      then SCode.EQ_REINIT(cr,e2,com,info);

    case (Absyn.EQ_NORETCALL(fname,fargs),com,info)
      then SCode.EQ_NORETCALL(fname,fargs,com,info);
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
      Boolean a3,a4,a5,rd;
      SCode.Attributes a6;
      Absyn.TypeSpec a7;
      SCode.Mod a8;
      Option<SCode.Comment> a10;
      Option<Absyn.Exp> a11;
      Option<Absyn.ConstrainClass> a13;
      SCode.Prefixes p;

    case(SCode.COMPONENT(a1,p,a6,a7,a8,a10,a11,_), nfo)
      then 
        SCode.COMPONENT(a1,p,a6,a7,a8,a10,a11,nfo);

    else elem;
  end matchcontinue;
end translateElementAddinfo;

/* Modification management */
public function translateMod
"function: translateMod
  Builds an SCode.Mod from an Absyn.Modification.
  The boolean argument flags whether the modification is final."
  input Option<Absyn.Modification> inAbsynModificationOption;
  input SCode.Final inFinalPrefix;
  input SCode.Each inEachPrefix;
  output SCode.Mod outMod;
algorithm
  outMod := match (inAbsynModificationOption,inFinalPrefix,inEachPrefix)
    local
      Absyn.Exp e;
      SCode.Final finalPrefix;
      SCode.Each eachPrefix;
      list<SCode.SubMod> subs;
      list<Absyn.ElementArg> l;

    case (NONE(),_,_) then SCode.NOMOD();  /* final */
    case (SOME(Absyn.CLASSMOD({},(Absyn.EQMOD(exp=e)))),finalPrefix,eachPrefix) 
      then SCode.MOD(finalPrefix,eachPrefix,{},SOME((e,false)));
    case (SOME(Absyn.CLASSMOD({},(Absyn.NOMOD()))),finalPrefix,eachPrefix) 
      then SCode.MOD(finalPrefix,eachPrefix,{},NONE());
    case (SOME(Absyn.CLASSMOD(l,Absyn.EQMOD(exp=e))),finalPrefix,eachPrefix)
      equation
        subs = translateArgs(l);
      then
        SCode.MOD(finalPrefix,eachPrefix,subs,SOME((e,false)));

    case (SOME(Absyn.CLASSMOD(l,Absyn.NOMOD())),finalPrefix,eachPrefix)
      equation
        subs = translateArgs(l);
      then
        SCode.MOD(finalPrefix,eachPrefix,subs,NONE());
  end match;
end translateMod;

protected function translateArgs
"function: translateArgs
  author: LS
  Adding translate for the elementspec in the redeclaration"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<SCode.SubMod> outSubModLst;
algorithm
  outSubModLst := match (inAbsynElementArgLst)
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
      Absyn.Info info;
      SCode.Final scodeFinalPrefix;
      SCode.Each scodeEachPrefix;

    case {} then {};
    
    case ((Absyn.MODIFICATION(finalPrefix = finalPrefix,eachPrefix = each_,componentRef = cref,modification = mod,comment = cmt) :: xs))
      equation
        subs = translateArgs(xs);
        mod_1 = translateMod(mod, SCode.boolFinal(finalPrefix), translateEach(each_));
        sub = translateSub(cref, mod_1);
      then
        (sub :: subs);

    case ((Absyn.REDECLARATION(finalPrefix = finalPrefix,redeclareKeywords = keywords,eachPrefix = each_,elementSpec = spec,constrainClass = constropt, info = info) :: xs))
      equation
        subs = translateArgs(xs);
        n = Absyn.elementSpecName(spec);
        elist = translateElementspec(constropt, finalPrefix, Absyn.NOT_INNER_OUTER(), SOME(keywords), SCode.PUBLIC(), spec, info)
        "LS:: do not know what to use for *protected*, so using false
         LS:: do not know what to use for *replaceable*, so using false";
        scodeFinalPrefix = SCode.boolFinal(finalPrefix);
        scodeEachPrefix = translateEach(each_);
      then
        (SCode.NAMEMOD(n,SCode.REDECL(scodeFinalPrefix,scodeEachPrefix,elist)) :: subs);

  end match;
end translateArgs;

protected function translateSub
"function: translateSub
  This function converts a Absyn.ComponentRef plus a list
  of modifications into a number of nested SCode.SUBMOD."
  input Absyn.ComponentRef inComponentRef;
  input SCode.Mod inMod;
  output SCode.SubMod outSubMod;
algorithm
  outSubMod := match (inComponentRef,inMod)
    local
      String c_str,mod_str,i;
      Absyn.ComponentRef c,path;
      SCode.Mod mod,mod_1;
      list<SCode.Subscript> ss;
      SCode.SubMod sub;

    // First some rules to prevent bad modifications
    case ((c as Absyn.CREF_IDENT(subscripts = (_ :: _))),(mod as SCode.MOD(subModLst = (_ :: _))))
      equation
        c_str = Dump.printComponentRefStr(c);
        mod_str = SCodeDump.printModStr(mod);
        Error.addMessage(Error.ILLEGAL_MODIFICATION, {mod_str,c_str});
      then
        fail();
    case ((c as Absyn.CREF_QUAL(subscripts = (_ :: _))),(mod as SCode.MOD(subModLst = (_ :: _))))
      equation
        c_str = Dump.printComponentRefStr(c);
        mod_str = SCodeDump.printModStr(mod);
        Error.addMessage(Error.ILLEGAL_MODIFICATION, {mod_str,c_str});
      then
        fail();
    // Then the normal rules
    case (Absyn.CREF_IDENT(name = i,subscripts = ss),mod)
      equation
        mod_1 = translateSubSub(ss, mod);
      then
        SCode.NAMEMOD(i,mod_1);
    case (Absyn.CREF_QUAL(name = i,subscripts = ss,componentRef = path),mod)
      equation
        sub = translateSub(path, mod);
        mod = SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{sub},NONE());
        mod_1 = translateSubSub(ss, mod);
      then
        SCode.NAMEMOD(i,mod_1);
  end match;
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
  outMod := match (inSubscriptLst,inMod)
    local
      SCode.Mod m;
      list<SCode.Subscript> l;
    case ({},m) then m;
    case (l,m) then SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{SCode.IDXMOD(l,m)},NONE());
  end match;
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
  namedArgs := match(prefix, mod)
    local
      list<Absyn.NamedArg> nArgs;
      list<SCode.SubMod> subModLst;

    case (prefix, SCode.MOD(subModLst = subModLst))
      equation
        nArgs = translateSubModToNArgs(prefix, subModLst);
      then
        nArgs;
  end match;
end translateSCodeModToNArgs;

public function translateSubModToNArgs
"@author: adrpo
 this function translates a SCode.SubMod into Absyn.NamedArg
 and prefixes all *LOCAL* expressions with the given prefix."
  input String prefix "given prefix, example: world";
  input list<SCode.SubMod> subMods "given sub modifications";
  output list<Absyn.NamedArg> namedArgs "the resulting named arguments";
algorithm
  namedArgs := match(prefix, subMods)
    local
      list<Absyn.NamedArg> nArgs;
      list<SCode.SubMod> subModLst;
      Absyn.Exp exp;
      SCode.Ident ident;
    // deal with the empty list
    case (prefix, {}) then {};
    // deal with named modifiers
    case (prefix, SCode.NAMEMOD(ident, SCode.MOD(binding = SOME((exp,_))))::subModLst)
      equation
        nArgs = translateSubModToNArgs(prefix, subModLst);
        exp = prefixUnqualifiedCrefsFromExp(exp, prefix);
      then
        Absyn.NAMEDARG(ident,exp)::nArgs;
  end match;
end translateSubModToNArgs;

public function prefixTuple
  input tuple<Absyn.Exp, Absyn.Exp> expTuple;
  input String prefix;
  output tuple<Absyn.Exp, Absyn.Exp> prefixedExpTuple;
algorithm
  prefixedExpTuple := match(expTuple, prefix)
    local
      Absyn.Exp e1,e2;

    case((e1, e2), prefix)
      equation
        e1 = prefixUnqualifiedCrefsFromExp(e1, prefix);
        e2 = prefixUnqualifiedCrefsFromExp(e2, prefix);
      then
        ((e1, e2));
  end match;
end prefixTuple;

public function prefixUnqualifiedCrefsFromExpOpt
  input Option<Absyn.Exp> inExpOpt;
  input String prefix;
  output Option<Absyn.Exp> outExpOpt;
algorithm
  outExpOpt := match(inExpOpt, prefix)
    local
      Absyn.Exp exp;

    case (NONE(), prefix) then NONE();
    case (SOME(exp), prefix)
      equation
        exp = prefixUnqualifiedCrefsFromExp(exp, prefix);
      then
        SOME(exp);
  end match;
end prefixUnqualifiedCrefsFromExpOpt;

public function prefixUnqualifiedCrefsFromExpLst
  input list<Absyn.Exp> inExpLst;
  input String prefix;
  output list<Absyn.Exp> outExpLst;
algorithm
  outExpLst := match(inExpLst, prefix)
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
  end match;
end prefixUnqualifiedCrefsFromExpLst;

public function prefixFunctionArgs
  input Absyn.FunctionArgs inFunctionArgs;
  input String prefix;
  output Absyn.FunctionArgs outFunctionArgs;
algorithm
  outFunctionArgs := match(inFunctionArgs, prefix)
    local
      list<Absyn.Exp> args "args" ;
      list<Absyn.NamedArg> argNames "argNames" ;

    case (Absyn.FUNCTIONARGS(args, argNames), prefix)
      equation
        args = prefixUnqualifiedCrefsFromExpLst(args, prefix);
      then
        Absyn.FUNCTIONARGS(args, argNames);
  end match;
end prefixFunctionArgs;

public function prefixUnqualifiedCrefsFromExp
  input Absyn.Exp exp;
  input String prefix;
  output Absyn.Exp prefixedExp;
algorithm
  prefixedExp := matchcontinue(exp, prefix)
    local
      SCode.Ident s;
      Absyn.ComponentRef c,fcn;
      Absyn.Exp e1,e2,e1a,e2a,e,t,f,start,stop,cond;
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
    case (Absyn.IFEXP(ifExp = cond,trueBranch = t,elseBranch = f,elseIfBranch = lst), prefix)
      equation
        cond = prefixUnqualifiedCrefsFromExp(cond, prefix);
        t = prefixUnqualifiedCrefsFromExp(t, prefix);
        f = prefixUnqualifiedCrefsFromExp(f, prefix);
        lst = List.map1(lst, prefixTuple, prefix); // TODO! fixme, prefix these also.
      then
        Absyn.IFEXP(cond, t, f, lst);
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
        es = List.map1(es, prefixUnqualifiedCrefsFromExp, prefix);
      then
        Absyn.ARRAY(es);
    // tuples
    case (Absyn.TUPLE(expressions = es), prefix)
      equation
        es = List.map1(es, prefixUnqualifiedCrefsFromExp, prefix);
      then
        Absyn.TUPLE(es);
    // matrix
    case (Absyn.MATRIX(matrix = esLstLst), prefix)
      equation
        esLstLst = List.map1(esLstLst, prefixUnqualifiedCrefsFromExpLst, prefix);
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
        es = List.map1(es, prefixUnqualifiedCrefsFromExp, prefix);
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

public function getImportFromElement
"Gets the Absyn.Import from an SCode.Element (fails if the element is not SCode.IMPORT)"
  input SCode.Element elt;
  output Absyn.Import imp;
algorithm
  SCode.IMPORT(imp = imp) := elt;
end getImportFromElement;

protected function makeTypeVarElement
  input String str;
  input Absyn.Info info;
  output SCode.Element elt;
protected
  SCode.ClassDef cd;
  Absyn.TypeSpec ts;
algorithm
  ts := Absyn.TCOMPLEX(Absyn.IDENT("polymorphic"),{Absyn.TPATH(Absyn.IDENT("Any"),NONE())},NONE());
  cd := SCode.DERIVED(ts,SCode.NOMOD(),
                      SCode.ATTR({},SCode.NOT_FLOW(),SCode.NOT_STREAM(),SCode.VAR(),Absyn.BIDIR()),
                      NONE());
  elt := SCode.CLASS(
           str,
           SCode.PREFIXES(
             SCode.PUBLIC(),
             SCode.NOT_REDECLARE(),
             SCode.FINAL(),
             Absyn.NOT_INNER_OUTER(),
             SCode.NOT_REPLACEABLE()),
           SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_TYPE(),cd,info);
end makeTypeVarElement;

protected function translateEach
  input  Absyn.Each inAEach;
  output SCode.Each outSEach;
algorithm
  outSEach := match(inAEach)
    case (Absyn.EACH()) then SCode.EACH();
    case (Absyn.NON_EACH()) then SCode.NOT_EACH();
  end match;  
end translateEach;

public function getRedeclareAsElements
"get the redeclare-as-element elements"
  input list<SCode.Element> elements;
  output list<SCode.Element> outElements;
algorithm
  outElements := matchcontinue (elements)
    local
      SCode.Element el;
      list<SCode.Element> els,els1;
    
    // empty
    case ({}) then {};

    // redeclare-as-element component
    case ((el as SCode.COMPONENT(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())))::els)
      equation
        els1 = getRedeclareAsElements(els);
      then 
        el::els1;
    
    // redeclare-as-element class extends, ignore!
    case ((el as SCode.CLASS(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE()), classDef = SCode.CLASS_EXTENDS(baseClassName = _)))::els)
      equation
        els1 = getRedeclareAsElements(els);
      then 
        els1;
        
    // redeclare-as-element class!
    case ((el as SCode.CLASS(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())))::els)
      equation
        els1 = getRedeclareAsElements(els);
      then
        el::els1;
    
    // rest
    case (_::els)
      equation
        els1 = getRedeclareAsElements(els);
      then 
        els1;
  end matchcontinue;
end getRedeclareAsElements;

public function addRedeclareAsElementsToExtends
"add the redeclare-as-element elements to extends"
  input list<SCode.Element> inElements;
  input list<SCode.Element> redeclareElements;
  output list<SCode.Element> outExtendsElements;
algorithm
  outExtendsElements := matchcontinue (inElements, redeclareElements)
    local
      SCode.Element el;
      list<SCode.Element> redecls, rest, out;
      Absyn.Path baseClassPath;
      SCode.Visibility visibility;
      SCode.Mod mod;
      Option<SCode.Annotation> ann "the extends annotation";
      Absyn.Info info;
      SCode.Mod redeclareMod;
    
    // empty, return the same
    case (_, {}) then inElements;

    // empty elements
    case ({}, _) then {};

    // we got some
    case (SCode.EXTENDS(baseClassPath, visibility, mod, ann, info)::rest, redecls)
      equation
        redeclareMod = SCode.REDECL(SCode.NOT_FINAL(), SCode.NOT_EACH(), redecls);
        mod = mergeSCodeMods(redeclareMod, mod);
        out = addRedeclareAsElementsToExtends(rest, redecls);
      then 
        SCode.EXTENDS(baseClassPath, visibility, mod, ann, info)::out;
    
    // failure 
    case ((el as SCode.EXTENDS(baseClassPath = _))::rest, redecls)
      equation
        print("- SCodeUtil.addRedeclareAsElementsToExtends failed on:\nextends:\n\t" +& SCodeDump.shortElementStr(el) +& 
                 "\nredeclares:\n" +& stringDelimitList(List.map(redecls, SCodeDump.unparseElementStr), "\n") +& "\n");
      then
        fail();
        
    // ignore non-extends
    case (el::rest, redecls)
      equation
        out = addRedeclareAsElementsToExtends(rest, redecls);
      then 
        el::out;
    
  end matchcontinue;
end addRedeclareAsElementsToExtends;

protected function mergeSCodeMods
  input SCode.Mod inModOuter;
  input SCode.Mod inModInner;
  output SCode.Mod outMod;
algorithm
  outMod := matchcontinue(inModOuter, inModInner)
    local 
      SCode.Final f1, f2;
      SCode.Each e1, e2;
      list<SCode.Element> els, redecls;
      list<SCode.SubMod> subMods, newSubMods;
      Option<tuple<Absyn.Exp, Boolean>> b;

    // inner is NOMOD
    case (SCode.REDECL(f1, e1, redecls), SCode.NOMOD()) then inModOuter; 
      
    // both are redeclarations
    case (SCode.REDECL(f1, e1, redecls), SCode.REDECL(f2, e2, els))
      equation
        els = listAppend(redecls, els);
      then
        SCode.REDECL(f2, e2, els);
         
    // inner is mod
    case (SCode.REDECL(f1, e1, redecls), SCode.MOD(f2, e2, subMods, b))
      equation
        // we need to make each redcls element into a submod!
        newSubMods = makeElementsIntoSubMods(f1, e1, redecls);
        newSubMods = listAppend(newSubMods, subMods);
      then
        SCode.MOD(f2, e2, newSubMods, b);
         
    // failure
    case (_, _)
      equation
        print("SCodeUtil.mergeSCodeMods failed on:\nouterMod: " +& SCodeDump.printModStr(inModOuter) +& 
               "\ninnerMod: " +& SCodeDump.printModStr(inModInner) +& "\n");  
      then
        fail();

  end matchcontinue;
end mergeSCodeMods;

protected function makeElementsIntoSubMods
"transform elements into submods with named mods"
  input SCode.Final inFinal;
  input SCode.Each inEach;
  input list<SCode.Element> inElements;
  output list<SCode.SubMod> outSubMods;
algorithm
  outSubMods := matchcontinue (inFinal, inEach, inElements)
    local
      SCode.Element el;
      list<SCode.Element> rest;
      SCode.Final f;
      SCode.Each e;
      SCode.Ident n;
      list<SCode.SubMod> newSubMods;
    
    // empty
    case (f, e, {}) then {};

    // class extends, error!
    case (f, e, (el as SCode.CLASS(name = n, classDef = SCode.CLASS_EXTENDS(baseClassName = _)))::rest)
      equation
        // print an error here
        print("- SCodeUtil.makeElementsIntoSubMods ignoring class-extends redeclare-as-element: " +& SCodeDump.unparseElementStr(el) +& "\n");
        // recurse  
        newSubMods = makeElementsIntoSubMods(f, e, rest);
      then 
        newSubMods;

    // component
    case (f, e, (el as SCode.COMPONENT(name = n))::rest)
      equation
        // recurse
        newSubMods = makeElementsIntoSubMods(f, e, rest);
      then 
        SCode.NAMEMOD(n,SCode.REDECL(f,e,{el}))::newSubMods;
        
    // class
    case (f, e, (el as SCode.CLASS(name = n))::rest)
      equation
        // recurse
        newSubMods = makeElementsIntoSubMods(f, e, rest);
      then 
        SCode.NAMEMOD(n,SCode.REDECL(f,e,{el}))::newSubMods;
    
    // rest
    case (f, e, el::rest)
      equation
        // print an error here
        print("- SCodeUtil.makeElementsIntoSubMods ignoring redeclare-as-element redeclaration: " +& SCodeDump.unparseElementStr(el) +& "\n");
        // recurse  
        newSubMods = makeElementsIntoSubMods(f, e, rest);
      then 
        newSubMods;
  end matchcontinue;
end makeElementsIntoSubMods;

end SCodeUtil;
