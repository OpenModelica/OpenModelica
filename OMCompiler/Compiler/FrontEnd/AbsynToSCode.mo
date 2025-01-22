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

encapsulated package AbsynToSCode
" file:        AbsynToSCode.mo
  package:     AbsynToSCode
  description: AbsynToSCode translates Absyn to SCode intermediate form


  This module contains functions to translate from
  an Absyn data representation to a simplified version
  called SCode.
  The most important function in this module is the *translateAbsyn2SCode*
  function which turns an abstract syntax tree into an SCode
  representation. Also *translateClass*, *translateMod*, etc.

  The SCode representation is then used as input to the Inst module"

public import Absyn;
public import AbsynUtil;
public import SCode;

protected
import Debug;
import Error;
import Flags;
import InstHashTable;
import List;
import MetaUtil;
import SCodeUtil;
import System;
import Util;
import MetaModelica.Dangerous;

// Constant expression for AssertionLevel.error.
protected constant Absyn.Exp ASSERTION_LEVEL_ERROR = Absyn.CREF(Absyn.CREF_FULLYQUALIFIED(
  Absyn.CREF_QUAL("AssertionLevel", {}, Absyn.CREF_IDENT("error", {}))));

public function translateAbsyn2SCode
"This function takes an Absyn.Program
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
      SCode.Program spInitial, sp;
      list<Absyn.Class> inClasses,initialClasses;

    case _
      equation
        InstHashTable.init();
        // adrpo: TODO! FIXME! disable function caching for now as some tests fail.
        // setGlobalRoot(Ceval.cevalHashIndex, Ceval.emptyCevalHashTable());
        Absyn.PROGRAM(classes=inClasses) = MetaUtil.createMetaClassesInProgram(inProgram);

        // set the external flag that signals the presence of inner/outer components in the model
        System.setHasInnerOuterDefinitions(false);
        // set the external flag that signals the presence of expandable connectors in the model
        System.setHasExpandableConnectors(false);
        // set the external flag that signals the presence of overconstrained connectors in the model
        System.setHasOverconstrainedConnectors(false);
        // set the external flag that signals the presence of expandable connectors in the model
        System.setHasStreamConnectors(false);

        // translate given absyn to scode.
        sp = list(translateClass(c) for c in inClasses);

        // adrpo: note that WE DO NOT NEED to add initial functions to the program
        //        as they are already part of the initialEnv done by Builtin.initialGraph
      then
        sp;
  end match;
end translateAbsyn2SCode;

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
      SourceInfo file_info;
      SCode.Element scodeClass;
      SCode.Final sFin;
      SCode.Encapsulated sEnc;
      SCode.Partial sPar;
      SCode.Comment cmt;

    case (c as Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = d,info = file_info), _)
      equation
        // fprint(Flags.TRANSLATE, "Translating class:" + n + "\n");
        r_1 = translateRestriction(c, r); // uniontype will not get translated!
        (d_1,cmt) = translateClassdef(d,file_info,r_1);
        sFin = SCodeUtil.boolFinal(f);
        sEnc = SCodeUtil.boolEncapsulated(e);
        sPar = SCodeUtil.boolPartial(p);
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
             cmt,
             file_info);
      then
        scodeClass;

    case (Absyn.CLASS(name = n,info = file_info), _)
      equation
        // Print out an internal error msg only if no other errors have already
        // been printed.
        true = intEq(Error.getNumMessages(), inNumMessages);
        n = "AbsynToSCode.translateClass2 failed: " + n;
        Error.addSourceMessage(Error.INTERNAL_ERROR,{n},file_info);
      then
        fail();
  end matchcontinue;
end translateClass2;


//mahge: FIX HERE. Check for proper input and output
//declarations in operators according to the specifications.
public function translateOperatorDef
  input Absyn.ClassDef inClassDef;
  input Absyn.Ident operatorName;
  input SourceInfo info;
  output SCode.ClassDef outOperDef;
  output SCode.Comment cmt;
algorithm
  (outOperDef,cmt) := match (inClassDef,operatorName,info)
    local
      Option<String> cmtString;
      list<SCode.Element> els;
      list<SCode.Annotation> anns;
      list<Absyn.ClassPart> parts;
      Option<SCode.Comment> scodeCmt;
      SCode.Ident opName;
      list<Absyn.Annotation> aann;
      Option<SCode.Annotation> ann;

  case (Absyn.PARTS(classParts = parts,ann=aann, comment = cmtString),_,_)
      equation
        els = translateClassdefElements(parts);
        cmt = translateCommentList(aann,cmtString);
      then
        (SCode.PARTS(els,{},{},{},{},{},{},NONE()),cmt);
    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Could not translate operator to SCode because it is not using class parts."}, info);
      then fail();
  end match;
end translateOperatorDef;

public function getOperatorGivenName
  input SCode.Element inOperatorFunction;
  output Absyn.Path outName;
algorithm
  outName := match (inOperatorFunction)
    local
      SCode.Ident name;
    case (SCode.CLASS(name,_,_,_,SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()),_,_,_))
    then Absyn.IDENT(name);

  end match;
end getOperatorGivenName;

public function getOperatorQualName
  input SCode.Element inOperatorFunction;
  input SCode.Ident operName;
  output SCode.Path outName;
algorithm
  outName := match (inOperatorFunction,operName)
    local
      SCode.Ident name,opname;
    case (SCode.CLASS(name,_,_,_,SCode.R_FUNCTION(_),_,_,_),opname)
    then AbsynUtil.joinPaths(Absyn.IDENT(opname), Absyn.IDENT(name));

  end match;
end getOperatorQualName;


public function getListofQualOperatorFuncsfromOperator
  input SCode.Element inOperator;
  output list<SCode.Path> outNames;
algorithm
  outNames := match (inOperator)
    local
      list<SCode.Element> els;
      SCode.Ident opername;
      list<SCode.Path> names;

      //If operator get the list of functions in it.
    case (SCode.CLASS(opername,_,_,_, SCode.R_OPERATOR() ,SCode.PARTS(elementLst = els),_,_))
      equation
        names = List.map1(els,getOperatorQualName,opername);
      then
        names;

      //If operator function return its name
    case (SCode.CLASS(opername,_,_,_, SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()),_,_,_))
      equation
        names = {Absyn.IDENT(opername)};
      then
        names;
  end match;
end getListofQualOperatorFuncsfromOperator;

public function translateRestriction
"Convert a class restriction."
  input Absyn.Class inClass;
  input Absyn.Restriction inRestriction;
  output SCode.Restriction outRestriction;
algorithm
  outRestriction := match (inClass,inRestriction)
    local
      Absyn.Class d;
      Absyn.Path name;
      Integer index;
      Boolean singleton, isImpure, moved;
      Absyn.FunctionPurity purity;
      list<String> typeVars;

    // ?? Only normal functions can have 'external'
    case (d,Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(purity)))
      then if containsExternalFuncDecl(d)
             then SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(purity))
             else SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(purity));

    case (_,Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION())) then SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION());
    case (_,Absyn.R_FUNCTION(Absyn.FR_PARALLEL_FUNCTION())) then SCode.R_FUNCTION(SCode.FR_PARALLEL_FUNCTION());
    case (_,Absyn.R_FUNCTION(Absyn.FR_KERNEL_FUNCTION())) then SCode.R_FUNCTION(SCode.FR_KERNEL_FUNCTION());

    case (_,Absyn.R_CLASS()) then SCode.R_CLASS();
    case (_,Absyn.R_OPTIMIZATION()) then SCode.R_OPTIMIZATION();
    case (_,Absyn.R_MODEL()) then SCode.R_MODEL();
    case (_,Absyn.R_RECORD()) then SCode.R_RECORD(false);
    case (_,Absyn.R_OPERATOR_RECORD()) then SCode.R_RECORD(true);

    case (_,Absyn.R_BLOCK()) then SCode.R_BLOCK();

    case (_,Absyn.R_CONNECTOR()) then SCode.R_CONNECTOR(false);
    case (_,Absyn.R_EXP_CONNECTOR()) equation System.setHasExpandableConnectors(true); then SCode.R_CONNECTOR(true);

    case (_,Absyn.R_OPERATOR()) then SCode.R_OPERATOR();

    case (_,Absyn.R_TYPE()) then SCode.R_TYPE();
    case (_,Absyn.R_PACKAGE()) then SCode.R_PACKAGE();
    case (_,Absyn.R_ENUMERATION()) then SCode.R_ENUMERATION();
    case (_,Absyn.R_PREDEFINED_INTEGER()) then SCode.R_PREDEFINED_INTEGER();
    case (_,Absyn.R_PREDEFINED_REAL()) then SCode.R_PREDEFINED_REAL();
    case (_,Absyn.R_PREDEFINED_STRING()) then SCode.R_PREDEFINED_STRING();
    case (_,Absyn.R_PREDEFINED_BOOLEAN()) then SCode.R_PREDEFINED_BOOLEAN();
    // BTH
    case (_,Absyn.R_PREDEFINED_CLOCK()) then SCode.R_PREDEFINED_CLOCK();
    case (_,Absyn.R_PREDEFINED_ENUMERATION()) then SCode.R_PREDEFINED_ENUMERATION();

    case (_,Absyn.R_METARECORD(name,index,singleton,moved,typeVars)) //MetaModelica extension, added by x07simbj
      then SCode.R_METARECORD(name,index,singleton,moved,typeVars);
    case (Absyn.CLASS(body=Absyn.PARTS(typeVars=typeVars)),Absyn.R_UNIONTYPE()) then SCode.R_UNIONTYPE(typeVars); /*MetaModelica extension added by x07simbj */
    case (_,Absyn.R_UNIONTYPE()) then SCode.R_UNIONTYPE({}); /*MetaModelica extension added by x07simbj */

  end match;
end translateRestriction;

protected function containsExternalFuncDecl
"Returns true if the Absyn.Class contains an external function declaration."
  input Absyn.Class inClass;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inClass)
    local
      list<Absyn.ClassPart> parts;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts))) then List.exist(parts,AbsynUtil.isExternalPart);
    case (Absyn.CLASS(body = Absyn.CLASS_EXTENDS(parts = parts))) then List.exist(parts,AbsynUtil.isExternalPart);
    else false;
  end match;
end containsExternalFuncDecl;

protected function translateAttributes
"@author: adrpo
 translates from Absyn.ElementAttributes to SCode.Attributes"
  input Absyn.ElementAttributes inEA;
  input list<Absyn.Subscript> extraArrayDim;
  output SCode.Attributes outA;
algorithm
  outA := match(inEA,extraArrayDim)
    local
      Boolean f, s;
      Absyn.Variability v;
      Absyn.Parallelism p;
      Absyn.ArrayDim adim,extraADim;
      Absyn.Direction dir;
      Absyn.IsField fi;
      SCode.ConnectorType ct;
      SCode.Parallelism sp;
      SCode.Variability sv;

    case (Absyn.ATTR(f, s, p, v, dir, fi, adim),extraADim)
      equation
        ct = translateConnectorType(f, s);
        sv = translateVariability(v);
        sp = translateParallelism(p);
        adim = listAppend(extraADim, adim);
      then
        SCode.ATTR(adim, ct, sp, sv, dir, fi);
  end match;
end translateAttributes;

protected function translateConnectorType
  input Boolean inFlow;
  input Boolean inStream;
  output SCode.ConnectorType outType;
algorithm
  outType := match(inFlow, inStream)
    case (false, false) then SCode.POTENTIAL();
    case (true, false) then SCode.FLOW();
    case (false, true) then SCode.STREAM();
    // Both flow and stream is not allowed by the grammar, so this shouldn't be
    // possible.
    case (true, true)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"AbsynToSCode.translateConnectorType got both flow and stream prefix."});
      then
        fail();
  end match;
end translateConnectorType;

protected function translateClassdef
"This function converts an Absyn.ClassDef to a SCode.ClassDef.
  For the DERIVED case, the conversion is fairly trivial, but for
  the PARTS case more work is needed.
  The result contains separate lists for:
   elements, equations and algorithms, which are mixed in the input.
  LS: Divided the translateClassdef into separate functions for collecting the different parts"
  input Absyn.ClassDef inClassDef;
  input SourceInfo info;
  input SCode.Restriction re;
  output SCode.ClassDef outClassDef;
  output SCode.Comment outComment;
algorithm
  (outClassDef,outComment) := match (inClassDef,info)
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
      list<SCode.ConstraintSection> cos;
      Option<SCode.ExternalDecl> decl;
      list<Absyn.ClassPart> parts;
      list<String> vars;
      list<SCode.Enum> lst_1;
      list<Absyn.EnumLiteral> lst;
      SCode.Comment scodeCmt;
      Absyn.Path path;
      list<Absyn.Path> pathLst;
      list<String> typeVars;
      SCode.Attributes scodeAttr;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;

    case (Absyn.DERIVED(typeSpec = t,attributes = attr,arguments = a,comment = cmt),_)
      equation
        checkTypeSpec(t, info);
        // fprintln(Flags.TRANSLATE, "translating derived class: " + Dump.unparseTypeSpec(t));
        mod = translateMod(SOME(Absyn.CLASSMOD(a,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), NONE(), info) "TODO: attributes of derived classes";
        scodeAttr = translateAttributes(attr, {});
        scodeCmt = translateComment(cmt);
      then
        (SCode.DERIVED(t,mod,scodeAttr), scodeCmt);

    case (Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts,ann=ann,comment = cmtString),_)
      equation
        // fprintln(Flags.TRANSLATE, "translating class parts");
        typeVars = match re
          case SCode.R_METARECORD() then List.union(typeVars, re.typeVars);
          case SCode.R_UNIONTYPE() then List.union(typeVars, re.typeVars);
          else typeVars;
        end match;
        tvels = List.map1(typeVars, makeTypeVarElement, info);
        els = translateClassdefElements(parts);
        els = listAppend(tvels,els);
        eqs = translateClassdefEquations(parts);
        initeqs = translateClassdefInitialequations(parts);
        als = translateClassdefAlgorithms(parts);
        initals = translateClassdefInitialalgorithms(parts);
        cos = translateClassdefConstraints(parts);
        scodeCmt = translateCommentList(ann, cmtString);
        decl = translateClassdefExternaldecls(parts);
        decl = translateAlternativeExternalAnnotation(decl,scodeCmt);
      then
        (SCode.PARTS(els,eqs,initeqs,als,initals,cos,classAttrs,decl),scodeCmt);

    case (Absyn.ENUMERATION(Absyn.ENUMLITERALS(enumLiterals = lst), cmt),_)
      equation
        // fprintln(Flags.TRANSLATE, "translating enumerations");
        lst_1 = translateEnumlist(lst);
        scodeCmt = translateComment(cmt);
      then
        (SCode.ENUMERATION(lst_1), scodeCmt);

    case (Absyn.ENUMERATION(Absyn.ENUM_COLON(), cmt),_)
      equation
        // fprintln(Flags.TRANSLATE, "translating enumeration of ':'");
        scodeCmt = translateComment(cmt);
      then
        (SCode.ENUMERATION({}),scodeCmt);

    case (Absyn.OVERLOAD(pathLst,cmt),_)
      equation
        // fprintln(Flags.TRANSLATE, "translating overloaded");
        scodeCmt = translateComment(cmt);
      then
        (SCode.OVERLOAD(pathLst),scodeCmt);

    case (Absyn.CLASS_EXTENDS(modifications = cmod,ann=ann,comment = cmtString,parts = parts),_)
      equation
        // fprintln(Flags.TRANSLATE "translating model extends " + name + " ... end " + name + ";");
        els = translateClassdefElements(parts);
        eqs = translateClassdefEquations(parts);
        initeqs = translateClassdefInitialequations(parts);
        als = translateClassdefAlgorithms(parts);
        initals = translateClassdefInitialalgorithms(parts);
        cos = translateClassdefConstraints(parts);
        mod = translateMod(SOME(Absyn.CLASSMOD(cmod,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), NONE(), AbsynUtil.dummyInfo);
        scodeCmt = translateCommentList(ann, cmtString);
        decl = translateClassdefExternaldecls(parts);
        decl = translateAlternativeExternalAnnotation(decl,scodeCmt);
      then
        (SCode.CLASS_EXTENDS(mod,SCode.PARTS(els,eqs,initeqs,als,initals,cos,{},decl)),scodeCmt);

    case (Absyn.PDER(functionName = path,vars = vars, comment=cmt),_)
      equation
        // fprintln(Flags.TRANSLATE, "translating pder( " + AbsynUtil.pathString(path) + ", vars)");
        scodeCmt = translateComment(cmt);
      then
        (SCode.PDER(path,vars),scodeCmt);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"AbsynToSCode.translateClassdef failed"});
      then
        fail();
  end match;
end translateClassdef;

protected function translateAlternativeExternalAnnotation
"first class annotation instead, since it is very common that an element
  annotation is used for this purpose.
  For instance, instead of external \"C\" annotation(Library=\"foo.lib\";
  it says external \"C\" ; annotation(Library=\"foo.lib\";"
input Option<SCode.ExternalDecl> decl;
input SCode.Comment comment;
output Option<SCode.ExternalDecl> outDecl;
algorithm
  outDecl := match (decl,comment)
    local
      Option<SCode.Ident> name ;
      Option<String> l ;
      Option<Absyn.ComponentRef> out ;
      list<Absyn.Exp> a;
      Option<SCode.Annotation> ann1,ann2,ann;
    // none
    case (NONE(),_) then NONE();
    // Else, merge
    case (SOME(SCode.EXTERNALDECL(name,l,out,a,ann1)),SCode.COMMENT(annotation_=ann2))
      equation
        ann = SCodeUtil.mergeSCodeOptAnn(ann1, ann2);
      then SOME(SCode.EXTERNALDECL(name,l,out,a,ann));
  end match;
end translateAlternativeExternalAnnotation;

protected function mergeSCodeAnnotationsFromParts
  input Absyn.ClassPart part;
  input Option<SCode.Annotation> inMod;
  output Option<SCode.Annotation> outMod;
algorithm
  outMod := match (part,inMod)
    local
      Absyn.Annotation aann;
      Option<SCode.Annotation> ann;
      list<Absyn.ElementItem> rest;
    case (Absyn.EXTERNAL(_,SOME(aann)),_)
      equation
        ann = translateAnnotation(aann);
        ann = SCodeUtil.mergeSCodeOptAnn(ann, inMod);
      then ann;
    case (Absyn.PUBLIC(_::rest),_)
      then mergeSCodeAnnotationsFromParts(Absyn.PUBLIC(rest),inMod);
    case (Absyn.PROTECTED(_::rest),_)
      then mergeSCodeAnnotationsFromParts(Absyn.PROTECTED(rest),inMod);

    else inMod;
  end match;
end mergeSCodeAnnotationsFromParts;

protected function translateEnumlist
"Convert an EnumLiteral list to an Ident list.
  Comments are lost."
  input list<Absyn.EnumLiteral> inAbsynEnumLiteralLst;
  output list<SCode.Enum> outEnumLst;
algorithm
  outEnumLst := match (inAbsynEnumLiteralLst)
    local
      list<SCode.Enum> res;
      String id;
      Option<Absyn.Comment> cmtOpt;
      SCode.Comment cmt;
      list<Absyn.EnumLiteral> rest;

    case ({}) then {};
    case ((Absyn.ENUMLITERAL(id, cmtOpt) :: rest))
      equation
        cmt = translateComment(cmtOpt);
        res = translateEnumlist(rest);
      then
        (SCode.ENUM(id, cmt) :: res);
  end match;
end translateEnumlist;

public function translateClassdefElements
"Convert an Absyn.ClassPart list to an Element list."
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
        els = listAppend(es_1, els);
      then
        els;

    case(Absyn.PROTECTED(contents = es) :: rest)
      equation
        es_1 = translateEitemlist(es, SCode.PROTECTED());
        els = translateClassdefElements(rest);
        els = listAppend(es_1, els);
      then
        els;

    case (_ :: rest) /* ignore all other than PUBLIC and PROTECTED, i.e. elements */
      then translateClassdefElements(rest);

  end match;
end translateClassdefElements;

protected function translateClassdefEquations
"Convert an Absyn.ClassPart list to an Equation list."
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
        eql_1 = translateEquations(eql, false);
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
"Convert an Absyn.ClassPart list to an initial Equation list."
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
        eql_1 = translateEquations(eql, true);
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
"Convert an Absyn.ClassPart list to an Algorithm list."
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
        als = translateClassdefAlgorithms(rest);
      then
        als;
    case _
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- AbsynToSCode.translateClassdefAlgorithms failed\n");
      then fail();
  end match;
end translateClassdefAlgorithms;

protected function translateClassdefConstraints
"Convert an Absyn.ClassPart list to an Constraint list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<SCode.ConstraintSection> outConstraintLst;
algorithm
  outConstraintLst := match (inAbsynClassPartLst)
    local
      list<SCode.ConstraintSection> cos,cos_1;
      list<Absyn.Exp> consts;
      list<Absyn.ClassPart> rest;
      Absyn.ClassPart cp;
    case {} then {};
    case ((Absyn.CONSTRAINTS(contents = consts) :: rest))
      equation
        cos = translateClassdefConstraints(rest);
        cos_1 = (SCode.CONSTRAINTS(consts) :: cos);
      then
        cos_1;
    case (cp :: rest) /* ignore everthing other than Constraints */
      equation
        cos = translateClassdefConstraints(rest);
      then
        cos;
    case _
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- AbsynToSCode.translateClassdefConstraints failed\n");
      then fail();
  end match;
end translateClassdefConstraints;

protected function translateClassdefInitialalgorithms
"Convert an Absyn.ClassPart list to an initial Algorithm list."
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
  input list<Absyn.AlgorithmItem> inStatements;
  output list<SCode.Statement> outStatements;
algorithm
  outStatements := list(translateClassdefAlgorithmItem(stmt) for stmt guard AbsynUtil.isAlgorithmItem(stmt) in inStatements);
end translateClassdefAlgorithmitems;

protected function translateClassdefAlgorithmItem
  "Translates an Absyn algorithm (statement) into SCode statement."
  input Absyn.AlgorithmItem inAlgorithm;
  output SCode.Statement outStatement;
protected
  Option<Absyn.Comment> absynComment;
  SCode.Comment comment;
  SourceInfo info;
  Absyn.Algorithm alg;
algorithm
  Absyn.ALGORITHMITEM(algorithm_=alg, comment=absynComment, info=info) := inAlgorithm;
  (comment, info) := translateCommentWithLineInfoChanges(absynComment, info);
  outStatement := match alg
    local
      list<SCode.Statement> body, else_body;
      list<tuple<Absyn.Exp, list<SCode.Statement>>> branches;
      String iter_name;
      Option<Absyn.Exp> iter_range;
      SCode.Statement stmt;
      Absyn.Exp e1, e2, e3;
      Absyn.ComponentRef cr;

    case Absyn.ALG_ASSIGN()
      then SCode.ALG_ASSIGN(alg.assignComponent, alg.value,
          comment, info);

    case Absyn.ALG_IF()
      algorithm
        body := translateClassdefAlgorithmitems(alg.trueBranch);
        else_body := translateClassdefAlgorithmitems(alg.elseBranch);
        branches := translateAlgBranches(alg.elseIfAlgorithmBranch);
      then
        SCode.ALG_IF(alg.ifExp, body, branches, else_body, comment, info);

    case Absyn.ALG_FOR()
      algorithm
        body := translateClassdefAlgorithmitems(alg.forBody);

        // Convert for-loops with multiple iterators into nested for-loops.
        for i in listReverse(alg.iterators) loop
          (iter_name, iter_range) := translateIterator(i, info);
          body := {SCode.ALG_FOR(iter_name, iter_range, body, comment, info)};
        end for;
      then
        listHead(body);

    case Absyn.ALG_PARFOR()
      algorithm
        body := translateClassdefAlgorithmitems(alg.parforBody);

        // Convert for-loops with multiple iterators into nested for-loops.
        for i in listReverse(alg.iterators) loop
          (iter_name, iter_range) := translateIterator(i, info);
          body := {SCode.ALG_PARFOR(iter_name, iter_range, body, comment, info)};
        end for;
      then
        listHead(body);

    case Absyn.ALG_WHILE()
      algorithm
        body := translateClassdefAlgorithmitems(alg.whileBody);
      then
        SCode.ALG_WHILE(alg.boolExpr, body, comment, info);

    case Absyn.ALG_WHEN_A()
      algorithm
        branches := translateAlgBranches((alg.boolExpr, alg.whenBody)
          :: alg.elseWhenAlgorithmBranch);
      then
        SCode.ALG_WHEN_A(branches, comment, info);

    // assert(condition, message)
    case Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
        functionArgs = Absyn.FUNCTIONARGS(args = {e1, e2}, argNames = {}))
      then SCode.ALG_ASSERT(e1, e2, ASSERTION_LEVEL_ERROR, comment, info);

    // assert(condition, message, level)
    case Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
        functionArgs = Absyn.FUNCTIONARGS(args = {e1, e2, e3}, argNames = {}))
      then SCode.ALG_ASSERT(e1, e2, e3, comment, info);

    // assert(condition, message, level = arg)
    case Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
        functionArgs = Absyn.FUNCTIONARGS(args = {e1, e2},
        argNames = {Absyn.NAMEDARG("level", e3)}))
      then SCode.ALG_ASSERT(e1, e2, e3, comment, info);

    case Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "terminate"),
        functionArgs = Absyn.FUNCTIONARGS(args = {e1}, argNames = {}))
      then SCode.ALG_TERMINATE(e1, comment, info);

    case Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "reinit"),
        functionArgs = Absyn.FUNCTIONARGS(args = {e1, e2}, argNames = {}))
      then SCode.ALG_REINIT(e1, e2, comment, info);

    case Absyn.ALG_NORETCALL()
      algorithm
        e1 := Absyn.CALL(alg.functionCall, alg.functionArgs, {});
      then
        SCode.ALG_NORETCALL(e1, comment, info);

    case Absyn.ALG_FAILURE()
      algorithm
        body := translateClassdefAlgorithmitems(alg.equ);
      then
        SCode.ALG_FAILURE(body, comment, info);

    case Absyn.ALG_TRY()
      algorithm
        body := translateClassdefAlgorithmitems(alg.body);
        else_body := translateClassdefAlgorithmitems(alg.elseBody);
      then
        SCode.ALG_TRY(body, else_body, comment, info);

    case Absyn.ALG_RETURN() then SCode.ALG_RETURN(comment, info);
    case Absyn.ALG_BREAK() then SCode.ALG_BREAK(comment, info);
    case Absyn.ALG_CONTINUE() then SCode.ALG_CONTINUE(comment, info);

  end match;
end translateClassdefAlgorithmItem;

protected function translateAlgBranches
  "Translates the elseif or elsewhen branches from Absyn to SCode form."
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inBranches;
  output list<tuple<Absyn.Exp, list<SCode.Statement>>> outBranches;
protected
  Absyn.Exp condition;
  list<Absyn.AlgorithmItem> body;
algorithm
  outBranches := list(
    match branch case (condition, body)
      then (condition, translateClassdefAlgorithmitems(body));
    end match
  for branch in inBranches);
end translateAlgBranches;

protected function translateClassdefExternaldecls
"Converts an Absyn.ClassPart list to an SCode.ExternalDecl option.
  The list should only contain one external declaration, so pick the first one."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Option<SCode.ExternalDecl> outAbsynExternalDeclOption;
algorithm
  outAbsynExternalDeclOption := match (inAbsynClassPartLst)
    local
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
        sann = translateAnnotationOpt(aann);
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
"This function converts a list of Absyn.ElementItem to a list of SCode.Element.
  The boolean argument flags whether the elements are protected.
  Annotations are not translated, i.e. they are removed when converting to SCode."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input SCode.Visibility inVisibility;
  output list<SCode.Element> outElementLst;
protected
  list<SCode.Element> l = {};
  list<Absyn.ElementItem> es = inAbsynElementItemLst;
  Absyn.ElementItem ei;
  SCode.Visibility vis;
  Absyn.Element e;
algorithm
  for ei in es loop
    _ := match (ei)
      local
        list<SCode.Element> e_1;
      case (Absyn.ELEMENTITEM(element = e))
        equation
          // fprintln(Flags.TRANSLATE, "translating element: " + Dump.unparseElementStr(1, e));
          e_1 = translateElement(e, inVisibility);
          l = List.append_reverse(e_1, l);
        then ();
      else ();
    end match;
  end for;
  outElementLst := Dangerous.listReverseInPlace(l);
end translateEitemlist;

// stefan
public function translateAnnotation
"translates an Absyn.Annotation into an SCode.Annotation"
  input Absyn.Annotation inAnnotation;
  output Option<SCode.Annotation> outAnnotation;
algorithm
  outAnnotation := match (inAnnotation)
    local
      list<Absyn.ElementArg> args;
      SCode.Mod m;

    case Absyn.ANNOTATION(elementArgs = {}) then NONE();

    case Absyn.ANNOTATION(elementArgs = args)
      equation
        // Keep empty modifiers since they might have meaning in annotations, e.g. annotation(Dialog()).
        m = translateMod(SOME(Absyn.CLASSMOD(args,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), NONE(), AbsynUtil.dummyInfo, keepEmpty = true);

      then
        if SCodeUtil.isEmptyMod(m) then NONE() else SOME(SCode.ANNOTATION(m));

  end match;
end translateAnnotation;

public function translateAnnotationOpt
  input Option<Absyn.Annotation> absynAnnotation;
  output Option<SCode.Annotation> scodeAnnotation;
algorithm
  scodeAnnotation := match absynAnnotation
    local
      Absyn.Annotation ann;

    case SOME(ann) then translateAnnotation(ann);
    else NONE();
  end match;
end translateAnnotationOpt;

public function translateElement
"This function converts an Absyn.Element to a list of SCode.Element.
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
      SourceInfo info;
      Option<Absyn.ConstrainClass> cc;
      Option<String> expOpt;
      Option<Real> weightOpt;
      list<Absyn.NamedArg> args;
      String name;
      SCode.Visibility vis;

    case (Absyn.ELEMENT(constrainClass = cc,finalPrefix = f,innerOuter = io, redeclareKeywords = repl,specification = s,info = info),vis)
      equation
        es = translateElementspec(cc, f, io, repl,  vis, s, info);
      then
        es;

    case(Absyn.DEFINEUNIT(name, args, info), vis)
      equation
        expOpt = translateDefineunitParam(args,"exp");
        weightOpt = translateDefineunitParam2(args,"weight");
      then {SCode.DEFINEUNIT(name,vis,expOpt,weightOpt,info)};
  end match;
end translateElement;

protected function translateDefineunitParam " help function to translateElement"
  input list<Absyn.NamedArg> inArgs;
  input String inArg;
  output Option<String> expOpt;
algorithm
  (expOpt) := match (inArgs,inArg)
    local
      String str,name, arg;
      list<Absyn.NamedArg> args;

    case(Absyn.NAMEDARG(name,Absyn.STRING(str))::_,arg) guard name == arg
    then SOME(str);
    case({},_) then NONE();
    case(_::args,arg) then translateDefineunitParam(args,arg);
  end match;
end translateDefineunitParam;

protected function translateDefineunitParam2 " help function to translateElement"
  input list<Absyn.NamedArg> inArgs;
  input String inArg;
  output Option<Real> weightOpt;
algorithm
  weightOpt := match (inArgs,inArg)
    local
      String name, arg, s;
      Real r;
      list<Absyn.NamedArg> args;

    case (Absyn.NAMEDARG(name,Absyn.REAL(s))::_,arg) guard name == arg
      equation
        r = System.stringReal(s);
      then SOME(r);
    case({},_) then NONE();
    case(_::args,arg) then translateDefineunitParam2(args,arg);
  end match;
end translateDefineunitParam2;

protected function translateElementspec
"This function turns an Absyn.ElementSpec to a list of SCode.Element.
  The boolean arguments say if the element is final and protected, respectively."
  input Option<Absyn.ConstrainClass> cc;
  input Boolean finalPrefix;
  input Absyn.InnerOuter io;
  input Option<Absyn.RedeclareKeywords> inRedeclareKeywords;
  input SCode.Visibility inVisibility;
  input Absyn.ElementSpec inElementSpec4;
  input SourceInfo inInfo;
  output list<SCode.Element> outElementLst;
algorithm
  outElementLst := match (cc,finalPrefix,io,inRedeclareKeywords,inVisibility,inElementSpec4,inInfo)
    local
      SCode.ClassDef de_1;
      SCode.Restriction re_1;
      Boolean rp,pa,fi,e,repl_1,fl,st,redecl;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.Class cl;
      String n;
      Absyn.Restriction re;
      Absyn.ClassDef de;
      SCode.Mod mod;
      list<Absyn.ElementArg> args;
      list<SCode.Element> xs_1;
      SCode.Parallelism prl1;
      SCode.Variability var1;
      list<SCode.Subscript> tot_dim,ad,d;
      Absyn.ElementAttributes attr;
      Absyn.Direction di;
      Absyn.IsField isf;
      Absyn.TypeSpec t;
      Option<Absyn.Modification> m;
      Option<Absyn.Comment> comment;
      SCode.Comment cmt;
      list<Absyn.ComponentItem> xs;
      Absyn.Import imp;
      Option<Absyn.Exp> cond;
      Absyn.Path path;
      Absyn.Annotation absann;
      Option<SCode.Annotation> ann;
      Absyn.Variability variability;
      Absyn.Parallelism parallelism;
      SourceInfo i,info;
      SCode.Element cls;
      SCode.Redeclare sRed;
      SCode.Final sFin;
      SCode.Replaceable sRep;
      SCode.Encapsulated sEnc;
      SCode.Partial sPar;
      SCode.Visibility vis;
      SCode.ConnectorType ct;
      SCode.Prefixes prefixes;
      Option<SCode.ConstrainClass> scc;


    case (_,_,_,repl,vis, Absyn.CLASSDEF(replaceable_ = rp, class_ = (Absyn.CLASS(name = n,partialPrefix = pa,encapsulatedPrefix = e,restriction = Absyn.R_OPERATOR(),body = de,info = i))),_)
      equation
        (de_1,cmt) = translateOperatorDef(de,n,i);
        (_, redecl) = translateRedeclarekeywords(repl);
        sRed = SCodeUtil.boolRedeclare(redecl);
        sFin = SCodeUtil.boolFinal(finalPrefix);
        scc = translateConstrainClass(cc);
        sRep = if rp then SCode.REPLACEABLE(scc) else SCode.NOT_REPLACEABLE();
        sEnc = SCodeUtil.boolEncapsulated(e);
        sPar = SCodeUtil.boolPartial(pa);
        cls = SCode.CLASS(
          n,
          SCode.PREFIXES(vis,sRed,sFin,io,sRep),
          sEnc, sPar, SCode.R_OPERATOR(), de_1, cmt, i);
      then
        {cls};


    case (_,_,_,repl,vis, Absyn.CLASSDEF(replaceable_ = rp, class_ = (cl as Absyn.CLASS(name = n,partialPrefix = pa,encapsulatedPrefix = e,restriction = re,body = de,info = i))),_)
      equation
        // fprintln(Flags.TRANSLATE, "translating local class: " + n);
        re_1 = translateRestriction(cl, re); // uniontype will not get translated!
        (de_1,cmt) = translateClassdef(de,i,re_1);
        (_, redecl) = translateRedeclarekeywords(repl);
        sRed = SCodeUtil.boolRedeclare(redecl);
        sFin = SCodeUtil.boolFinal(finalPrefix);
        scc = translateConstrainClass(cc);
        sRep = if rp then SCode.REPLACEABLE(scc) else SCode.NOT_REPLACEABLE();
        sEnc = SCodeUtil.boolEncapsulated(e);
        sPar = SCodeUtil.boolPartial(pa);
        cls = SCode.CLASS(
          n,
          SCode.PREFIXES(vis,sRed,sFin,io,sRep),
          sEnc, sPar, re_1, de_1, cmt, i);
      then
        {cls};

    case (_,_,_,_,vis,Absyn.EXTENDS(path = path,elementArg = args,annotationOpt = NONE()),info)
      equation
        // fprintln(Flags.TRANSLATE, "translating extends: " + AbsynUtil.pathString(n));
        mod = translateMod(SOME(Absyn.CLASSMOD(args,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), NONE(), AbsynUtil.dummyInfo);
      then
        {SCode.EXTENDS(path,vis,mod,NONE(),info)};

    case (_,_,_,_,vis,Absyn.EXTENDS(path = path,elementArg = args,annotationOpt = SOME(absann)),info)
      equation
        // fprintln(Flags.TRANSLATE, "translating extends: " + AbsynUtil.pathString(n));
        mod = translateMod(SOME(Absyn.CLASSMOD(args,Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), NONE(), AbsynUtil.dummyInfo);
        ann = translateAnnotation(absann);
      then
        {SCode.EXTENDS(path,vis,mod,ann,info)};

    case (_,_,_,_,_,Absyn.COMPONENTS(components = {}),_) then {};

    case (_,_,_,repl,vis,Absyn.COMPONENTS(attributes =
      (Absyn.ATTR(flowPrefix = fl,streamPrefix=st,parallelism=parallelism,variability = variability,direction = di,isField = isf,arrayDim = ad)), typeSpec = t),info)
      algorithm
        xs_1 := {};
        for comp in inElementSpec4.components loop
          Absyn.COMPONENTITEM(component=Absyn.COMPONENT(name = n,arrayDim = d,modification = m),comment = comment, condition=cond) := comp;
          // TODO: Improve performance by iterating over all elements at once instead of creating a new Absyn.COMPONENTS in each step...
          checkTypeSpec(t,info);
          // fprintln(Flags.TRANSLATE, "translating component: " + n + " final: " + SCodeUtil.finalStr(SCodeUtil.boolFinal(finalPrefix)));
          setHasInnerOuterDefinitionsHandler(io); // signal the external flag that we have inner/outer definitions
          setHasStreamConnectorsHandler(st);      // signal the external flag that we have stream connectors
          mod := translateMod(m, SCode.NOT_FINAL(), SCode.NOT_EACH(), NONE(), info);
          prl1 := translateParallelism(parallelism);
          var1 := translateVariability(variability);
          // PR. This adds the arraydimension that may be specified together with the type of the component.
          tot_dim := listAppend(d, ad);
          (repl_1, redecl) := translateRedeclarekeywords(repl);
          (cmt,info) := translateCommentWithLineInfoChanges(comment,info);
          sFin := SCodeUtil.boolFinal(finalPrefix);
          sRed := SCodeUtil.boolRedeclare(redecl);
          scc := translateConstrainClass(cc);
          sRep := if repl_1 then SCode.REPLACEABLE(scc) else SCode.NOT_REPLACEABLE();
          ct := translateConnectorType(fl, st);
          prefixes := SCode.PREFIXES(vis,sRed,sFin,io,sRep);
          xs_1 := match di
            local
              SCode.Attributes attr1,attr2;
              SCode.Mod mod2;
              String inName;
            case Absyn.INPUT_OUTPUT() guard not Flags.isSet(Flags.SKIP_INPUT_OUTPUT_SYNTACTIC_SUGAR)
              algorithm
                inName := "$in_"+n;
                attr1 := SCode.ATTR(tot_dim,ct,prl1,var1,Absyn.INPUT(),isf);
                attr2 := SCode.ATTR(tot_dim,ct,prl1,var1,Absyn.OUTPUT(),isf);
                mod2 := SCode.MOD(SCode.FINAL(), SCode.NOT_EACH(), {}, SOME(Absyn.CREF(Absyn.CREF_IDENT(inName,{}))), NONE(), info);
              then SCode.COMPONENT(n,prefixes,attr2,t,mod2,cmt,cond,info) :: SCode.COMPONENT(inName,prefixes,attr1,t,mod,cmt,cond,info) :: xs_1;
            else SCode.COMPONENT(n,prefixes,SCode.ATTR(tot_dim,ct,prl1,var1,di,isf),t,mod,cmt,cond,info) :: xs_1;
          end match;
        end for;
        xs_1 := Dangerous.listReverseInPlace(xs_1);
      then xs_1;
    case (_,_,_,_,vis,Absyn.IMPORT(import_ = imp, info = info),_)
      equation
        // fprintln(Flags.TRANSLATE, "translating import: " + Dump.unparseImportStr(imp));
        xs_1 = translateImports(imp,vis,info);
      then
        xs_1;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"AbsynToSCode.translateElementspec failed"});
      then fail();
  end match;
end translateElementspec;

protected function translateImports "Used to handle group imports, i.e. A.B.C.{x=a,b}"
  input Absyn.Import imp;
  input SCode.Visibility visibility;
  input SourceInfo info;
  output list<SCode.Element> elts;
algorithm
  elts := match (imp,visibility,info)
    local
      String name;
      Absyn.Path p;
      list<Absyn.GroupImport> groups;

      /* Maybe these should give warnings? I don't know. See https://trac.modelica.org/Modelica/ticket/955 */
    case (Absyn.NAMED_IMPORT(name,Absyn.FULLYQUALIFIED(p)),_,_)
      then translateImports(Absyn.NAMED_IMPORT(name,p),visibility,info);
    case (Absyn.QUAL_IMPORT(Absyn.FULLYQUALIFIED(p)),_,_)
      then translateImports(Absyn.QUAL_IMPORT(p),visibility,info);
    case (Absyn.UNQUAL_IMPORT(Absyn.FULLYQUALIFIED(p)),_,_)
      then translateImports(Absyn.UNQUAL_IMPORT(p),visibility,info);

    case (Absyn.GROUP_IMPORT(prefix=p,groups=groups),_,_)
      then List.map3(groups, translateGroupImport, p, visibility, info);
    else {SCode.IMPORT(imp, visibility, info)};
  end match;
end translateImports;

protected function translateGroupImport "Used to handle group imports, i.e. A.B.C.{x=a,b}"
  input Absyn.GroupImport gimp;
  input Absyn.Path prefix;
  input SCode.Visibility visibility;
  input SourceInfo info;
  output SCode.Element elt;
algorithm
  elt := match (gimp,prefix,visibility,info)
    local
      String name,rename;
      Absyn.Path path;
      SCode.Visibility vis;

    case (Absyn.GROUP_IMPORT_NAME(name=name),_,vis,_)
      equation
        path = AbsynUtil.joinPaths(prefix,Absyn.IDENT(name));
      then SCode.IMPORT(Absyn.QUAL_IMPORT(path),vis,info);
    case (Absyn.GROUP_IMPORT_RENAME(rename=rename,name=name),_,vis,_)
      equation
        path = AbsynUtil.joinPaths(prefix,Absyn.IDENT(name));
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
"author: PA
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
      SCode.Comment cc_cmt;
      Absyn.Modification mod;
      SCode.Mod cc_mod;

    case SOME(Absyn.CONSTRAINCLASS(elementSpec =
        Absyn.EXTENDS(path = cc_path, elementArg = eltargs), comment = cmt))
      equation
        mod = Absyn.CLASSMOD(eltargs, Absyn.NOMOD());
        cc_mod = translateMod(SOME(mod), SCode.NOT_FINAL(), SCode.NOT_EACH(), NONE(), AbsynUtil.dummyInfo);
        cc_cmt = translateComment(cmt);
      then
        SOME(SCode.CONSTRAINCLASS(cc_path, cc_mod, cc_cmt));

    else NONE();
  end match;
end translateConstrainClass;

protected function translateParallelism
"Converts an Absyn.Parallelism to SCode.Parallelism."
  input Absyn.Parallelism inParallelism;
  output SCode.Parallelism outParallelism;
algorithm
  outParallelism := match (inParallelism)
    case (Absyn.PARGLOBAL())      then SCode.PARGLOBAL();
    case (Absyn.PARLOCAL()) then SCode.PARLOCAL();
    case (Absyn.NON_PARALLEL())    then SCode.NON_PARALLEL();
  end match;
end translateParallelism;

protected function translateVariability
"Converts an Absyn.Variability to SCode.Variability."
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
"This function transforms a list of Absyn.Equation to a list of
  SCode.Equation, by applying the translateEquation function to each
  equation."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input Boolean inIsInitial;
  output list<SCode.Equation> outEquationLst;
algorithm
  outEquationLst := list(
    match eq
      local
        SCode.Comment com;
        SourceInfo info;
      case Absyn.EQUATIONITEM()
        algorithm
          (com,info) := translateCommentWithLineInfoChanges(eq.comment, eq.info);
        then translateEquation(eq.equation_,com,info,inIsInitial);
    end match
    for eq guard match eq case Absyn.EQUATIONITEM() then true; else false; end match in inAbsynEquationItemLst
  );
end translateEquations;

protected function translateCommentWithLineInfoChanges
"turns an Absyn.Comment into an SCode.Comment"
  input Option<Absyn.Comment> inComment;
  input SourceInfo inInfo;
  output SCode.Comment outComment;
  output SourceInfo outInfo;
algorithm
  outComment := translateComment(inComment);
  outInfo := getInfoAnnotationOrDefault(outComment, inInfo);
end translateCommentWithLineInfoChanges;

protected function getInfoAnnotationOrDefault "Replaces the file info if there is an annotation __OpenModelica_FileInfo=(\"fileName\",line). Should be improved."
  input SCode.Comment comment;
  input SourceInfo default;
  output SourceInfo info;
algorithm
  info := match (comment,default)
    local
      list<SCode.SubMod> lst;
    case (SCode.COMMENT(annotation_=SOME(SCode.ANNOTATION(modification=SCode.MOD(subModLst=lst)))),_)
      then getInfoAnnotationOrDefault2(lst,default);
    else default;
  end match;
end getInfoAnnotationOrDefault;

protected function getInfoAnnotationOrDefault2
  input list<SCode.SubMod> lst;
  input SourceInfo default;
  output SourceInfo info;
algorithm
  info := match (lst,default)
    local
      list<SCode.SubMod> rest;
      String fileName;
      Integer line;
    case ({},_) then default;
    case (SCode.NAMEMOD(ident="__OpenModelica_FileInfo",mod=SCode.MOD(binding=SOME(Absyn.TUPLE({Absyn.STRING(fileName),Absyn.INTEGER(line)}))))::_,_)
      then SOURCEINFO(fileName,false,line,0,line,0,0.0);
    case (_::rest,_) then getInfoAnnotationOrDefault2(rest,default);
  end match;
end getInfoAnnotationOrDefault2;

protected function translateComment
"turns an Absyn.Comment into an SCode.Comment"
  input Option<Absyn.Comment> inComment;
  output SCode.Comment outComment;
algorithm
  outComment := match (inComment)
    local
      Option<Absyn.Annotation> absann;
      Option<SCode.Annotation> ann;
      Option<String> ostr;

    case(NONE()) then SCode.noComment;
    case(SOME(Absyn.COMMENT(absann,ostr)))
      equation
        ann = translateAnnotationOpt(absann);
        ostr = Util.applyOption(ostr,System.unescapedString);
      then SCode.COMMENT(ann,ostr);
  end match;
end translateComment;

protected function translateCommentList
  "turns an Absyn.Comment into an SCode.Comment"
  input list<Absyn.Annotation> inAnns;
  input Option<String> inString;
  output SCode.Comment outComment;
algorithm
  outComment := match (inAnns,inString)
    local
      Absyn.Annotation absann;
      list<Absyn.Annotation> anns;
      Option<SCode.Annotation> ann;
      Option<String> ostr;

    case ({},_) then SCode.COMMENT(NONE(),inString);
    case ({absann},_)
      equation
        ann = translateAnnotation(absann);
        ostr = Util.applyOption(inString,System.unescapedString);
      then SCode.COMMENT(ann,ostr);
    case (absann::anns,_)
      equation
        absann = List.fold(anns, AbsynUtil.mergeAnnotations, absann);
        ann = translateAnnotation(absann);
        ostr = Util.applyOption(inString,System.unescapedString);
      then SCode.COMMENT(ann,ostr);
  end match;
end translateCommentList;

protected function translateCommentSeparate
"turns an Absyn.Comment into an SCode.Annotation + string"
  input Option<Absyn.Comment> inComment;
  output Option<SCode.Annotation> outAnn;
  output Option<String> outStr;
algorithm
  (outAnn,outStr) := match (inComment)
    local Absyn.Annotation absann;
      Option<SCode.Annotation> ann;
      String str;

    case(NONE()) then (NONE(),NONE());
    case(SOME(Absyn.COMMENT(NONE(),NONE()))) then (NONE(),NONE());
    case(SOME(Absyn.COMMENT(NONE(),SOME(str)))) then (NONE(),SOME(str));
    case(SOME(Absyn.COMMENT(SOME(absann),NONE())))
      equation
        ann = translateAnnotation(absann);
      then
        (ann,NONE());
    case(SOME(Absyn.COMMENT(SOME(absann),SOME(str))))
      equation
        ann = translateAnnotation(absann);
      then
        (ann,SOME(str));
  end match;
end translateCommentSeparate;

protected function translateEquation
  input Absyn.Equation inEquation;
  input SCode.Comment inComment;
  input SourceInfo inInfo;
  input Boolean inIsInitial;
  output SCode.Equation outEquation;
algorithm
  outEquation := match inEquation
    local
      Absyn.Exp exp, e1, e2, e3;
      list<Absyn.Equation> abody;
      list<SCode.Equation> else_branch, body;
      list<tuple<Absyn.Exp, list<SCode.Equation>>> branches;
      String iter_name;
      Option<Absyn.Exp> iter_range;
      SCode.Equation eq;
      list<Absyn.Exp> conditions;
      list<list<SCode.Equation>> bodies;
      Absyn.ComponentRef cr;

    case Absyn.EQ_IF()
      algorithm
        body := translateEquations(inEquation.equationTrueItems, inIsInitial);
        (conditions, bodies) :=
          List.map1_2(inEquation.elseIfBranches, translateEqBranch, inIsInitial);
        conditions := inEquation.ifExp :: conditions;
        else_branch := translateEquations(inEquation.equationElseItems, inIsInitial);
      then
        SCode.EQ_IF(conditions, body :: bodies, else_branch, inComment, inInfo);

    case Absyn.EQ_WHEN_E()
      algorithm
        body := translateEquations(inEquation.whenEquations, inIsInitial);
        (conditions, bodies) :=
          List.map1_2(inEquation.elseWhenEquations, translateEqBranch, inIsInitial);
        branches := list((c, b) threaded for c in conditions, b in bodies);
      then
        SCode.EQ_WHEN(inEquation.whenExp, body, branches, inComment, inInfo);

    case Absyn.EQ_EQUALS()
      then SCode.EQ_EQUALS(inEquation.leftSide, inEquation.rightSide, inComment, inInfo);

    case Absyn.EQ_PDE()
      then SCode.EQ_PDE(inEquation.leftSide, inEquation.rightSide, inEquation.domain, inComment, inInfo);

    case Absyn.EQ_CONNECT()
      algorithm
        if inIsInitial then
          Error.addSourceMessageAndFail(Error.CONNECT_IN_INITIAL_EQUATION, {}, inInfo);
        end if;
      then
        SCode.EQ_CONNECT(inEquation.connector1, inEquation.connector2, inComment, inInfo);

    case Absyn.EQ_FOR()
      algorithm
        body := translateEquations(inEquation.forEquations, inIsInitial);

        // Convert for-loops with multiple iterators into nested for-loops.
        for i in listReverse(inEquation.iterators) loop
          (iter_name, iter_range) := translateIterator(i, inInfo);
          body := {SCode.EQ_FOR(iter_name, iter_range, body, inComment, inInfo)};
        end for;
      then
        listHead(body);

    // assert(condition, message)
    case Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "assert"),
        functionArgs = Absyn.FUNCTIONARGS(args = {e1, e2}, argNames = {}))
      then SCode.EQ_ASSERT(e1, e2, ASSERTION_LEVEL_ERROR, inComment, inInfo);

    // assert(condition, message, level)
    case Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "assert"),
        functionArgs = Absyn.FUNCTIONARGS(args = {e1, e2, e3}, argNames = {}))
      then SCode.EQ_ASSERT(e1, e2, e3, inComment, inInfo);

    // assert(condition, message, level = arg)
    case Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "assert"),
        functionArgs = Absyn.FUNCTIONARGS(args = {e1, e2},
        argNames = {Absyn.NAMEDARG("level", e3)}))
      then SCode.EQ_ASSERT(e1, e2, e3, inComment, inInfo);

    // terminate(message)
    case Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "terminate"),
        functionArgs = Absyn.FUNCTIONARGS(args = {e1}, argNames = {}))
      then SCode.EQ_TERMINATE(e1, inComment, inInfo);

    // reinit(cref, exp)
    case Absyn.EQ_NORETCALL(functionName = Absyn.CREF_IDENT(name = "reinit"),
        functionArgs = Absyn.FUNCTIONARGS(args = {e1, e2},
        argNames = {}))
      then SCode.EQ_REINIT(e1, e2, inComment, inInfo);

    // Other nonreturning calls. assert, terminate and reinit with the wrong
    // number of arguments is also turned into a noretcall, since it's
    // preferable to handle the error during instantation instead of here.
    case Absyn.EQ_NORETCALL()
      then SCode.EQ_NORETCALL(Absyn.CALL(inEquation.functionName, inEquation.functionArgs, {}),
        inComment, inInfo);

  end match;
end translateEquation;

protected function translateEqBranch
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> inBranch;
  input Boolean inIsInitial;
  output Absyn.Exp outCondition;
  output list<SCode.Equation> outBody;
protected
  list<Absyn.EquationItem> body;
algorithm
  (outCondition, body) := inBranch;
  outBody := translateEquations(body, inIsInitial);
end translateEqBranch;

protected function translateIterator
  input Absyn.ForIterator inIterator;
  input SourceInfo inInfo;
  output String outName;
  output Option<Absyn.Exp> outRange;
protected
  Option<Absyn.Exp> guard_exp;
algorithm
  Absyn.ITERATOR(name = outName, guardExp = guard_exp, range = outRange) := inIterator;

  if isSome(guard_exp) then
    Error.addSourceMessageAndFail(Error.INTERNAL_ERROR,
      {"For loops with guards not yet implemented"}, inInfo);
  end if;
end translateIterator;

protected function translateElementAddinfo
"function: translateElementAddinfo"
  input SCode.Element elem;
  input SourceInfo nfo;
  output SCode.Element oelem;
algorithm
  oelem := match (elem,nfo)
    local
      SCode.Ident a1;
      Absyn.InnerOuter a2;
      Boolean a3,a4,a5,rd;
      SCode.Attributes a6;
      Absyn.TypeSpec a7;
      SCode.Mod a8;
      SCode.Comment a10;
      Option<Absyn.Exp> a11;
      Option<Absyn.ConstrainClass> a13;
      SCode.Prefixes p;

    case(SCode.COMPONENT(a1,p,a6,a7,a8,a10,a11,_), _)
      then SCode.COMPONENT(a1,p,a6,a7,a8,a10,a11,nfo);

    else elem;
  end match;
end translateElementAddinfo;

/* Modification management */
public function translateMod
"Builds an SCode.Mod from an Absyn.Modification."
  input Option<Absyn.Modification> inMod;
  input SCode.Final finalPrefix;
  input SCode.Each eachPrefix;
  input Option<String> comment;
  input SourceInfo info;
  input Boolean keepEmpty = false; // Keep empty modifiers, e.g. (x).
  output SCode.Mod outMod;
protected
  list<Absyn.ElementArg> args;
  Absyn.EqMod eqmod;
  list<SCode.SubMod> subs;
  Option<Absyn.Exp> binding;
algorithm
  (args, eqmod) := match inMod
    case SOME(Absyn.CLASSMOD(elementArgLst = args, eqMod = eqmod)) then (args, eqmod);
    else ({}, Absyn.NOMOD());
  end match;

  subs := if listEmpty(args) then {} else translateArgs(args, keepEmpty);

  binding := match eqmod
    case Absyn.EQMOD() then SOME(eqmod.exp);
    else NONE();
  end match;

  outMod := match (subs, binding, finalPrefix, eachPrefix)
    case ({}, NONE(), SCode.NOT_FINAL(), SCode.NOT_EACH()) then SCode.NOMOD();
    else SCode.MOD(finalPrefix, eachPrefix, subs, binding, comment, info);
  end match;
end translateMod;

protected function translateArgs
  input list<Absyn.ElementArg> args;
  input Boolean keepEmpty;
  output list<SCode.SubMod> subMods = {};
protected
  SCode.Mod smod;
  SCode.Element elem;
  SCode.SubMod sub;
algorithm
  for arg in args loop
    subMods := match arg
      case Absyn.MODIFICATION()
        algorithm
          smod := translateMod(arg.modification, SCodeUtil.boolFinal(arg.finalPrefix),
            translateEach(arg.eachPrefix), arg.comment, arg.info);

          if not SCodeUtil.isEmptyMod(smod) or keepEmpty then
            sub := translateSub(arg.path, smod, arg.info);
            subMods := sub :: subMods;
          end if;
        then
          subMods;

      case Absyn.REDECLARATION()
        algorithm
          elem::{} := translateElementspec(arg.constrainClass, arg.finalPrefix,
            Absyn.NOT_INNER_OUTER(), SOME(arg.redeclareKeywords), SCode.PUBLIC(),
            arg.elementSpec, arg.info);

          sub := SCode.NAMEMOD(AbsynUtil.elementSpecName(arg.elementSpec),
            SCode.REDECL(
              SCodeUtil.boolFinal(arg.finalPrefix),
              translateEach(arg.eachPrefix),
              elem));
        then
          sub :: subMods;
      case Absyn.ELEMENTARGCOMMENT() then subMods;
    end match;
  end for;

  subMods := listReverse(subMods);
end translateArgs;

protected function translateSub
"This function converts a Absyn.ComponentRef plus a list
  of modifications into a number of nested SCode.SUBMOD."
  input Absyn.Path inPath;
  input SCode.Mod inMod;
  input SourceInfo info;
  output SCode.SubMod outSubMod;
algorithm
  outSubMod := match (inPath,inMod,info)
    local
      String i;
      Absyn.Path path;
      SCode.Mod mod;
      SCode.SubMod sub;

    // Then the normal rules
    case (Absyn.IDENT(name = i),mod,_) then SCode.NAMEMOD(i,mod);
    case (Absyn.QUALIFIED(name = i,path = path),mod,_)
      equation
        sub = translateSub(path, mod, info);
        mod = SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{sub},NONE(),NONE(),info);
      then SCode.NAMEMOD(i,mod);
  end match;
end translateSub;

protected function makeTypeVarElement
  input String str;
  input SourceInfo info;
  output SCode.Element elt;
protected
  SCode.ClassDef cd;
  Absyn.TypeSpec ts;
algorithm
  ts := Absyn.TCOMPLEX(Absyn.IDENT("polymorphic"),{Absyn.TPATH(Absyn.IDENT("Any"),NONE())},NONE());
  cd := SCode.DERIVED(ts,SCode.NOMOD(),
                      SCode.ATTR({},SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(),Absyn.BIDIR(),Absyn.NONFIELD()));
  elt := SCode.CLASS(
           str,
           SCode.PREFIXES(
             SCode.PUBLIC(),
             SCode.NOT_REDECLARE(),
             SCode.FINAL(),
             Absyn.NOT_INNER_OUTER(),
             SCode.NOT_REPLACEABLE()),
           SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_TYPE(),cd,SCode.noComment,info);
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

protected function checkTypeSpec
  input Absyn.TypeSpec ts;
  input SourceInfo info;
algorithm
  _ := match (ts,info)
    local
      list<Absyn.TypeSpec> tss;
      Absyn.TypeSpec ts2;
      String str;
    case (Absyn.TPATH(),_) then ();
    case (Absyn.TCOMPLEX(path=Absyn.IDENT("tuple"),typeSpecs={ts2}),_)
      equation
        str = AbsynUtil.typeSpecString(ts);
        Error.addSourceMessage(Error.TCOMPLEX_TUPLE_ONE_NAME,{str},info);
        checkTypeSpec(ts2,info);
      then ();
      // It is okay for tuples to have multiple typespecs
    case (Absyn.TCOMPLEX(path=Absyn.IDENT("tuple"),typeSpecs=tss as (_::_::_)),_)
      equation
        List.map1_0(tss, checkTypeSpec, info);
      then ();
    case (Absyn.TCOMPLEX(typeSpecs={ts2}),_)
      equation
        checkTypeSpec(ts2,info);
      then ();
    case (Absyn.TCOMPLEX(typeSpecs=tss),_)
      equation
        if listMember(ts.path, {Absyn.IDENT("list"),Absyn.IDENT("List"),Absyn.IDENT("array"),Absyn.IDENT("Array"),Absyn.IDENT("polymorphic"),Absyn.IDENT("Option")}) then
          str = AbsynUtil.typeSpecString(ts);
          Error.addSourceMessage(Error.TCOMPLEX_MULTIPLE_NAMES,{str},info);
          List.map1_0(tss, checkTypeSpec, info);
        end if;
      then ();
  end match;
end checkTypeSpec;

annotation(__OpenModelica_Interface="frontend");
end AbsynToSCode;
