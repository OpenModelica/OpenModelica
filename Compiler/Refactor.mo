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

package Refactor
" file:        Refactor.mo
  package:     Refactor
  description: Refactoring package

  RCS: $Id$

  This module contains functions for refactoring of Modelica/MetaModelica code.
  Right now there is support for old-style annotation refactoring to new-style
  annotations."


public import Absyn;
protected import Interactive;
protected import Util;
protected import Inst;
protected import Env;

public function refactorGraphicalAnnotation "function: refactorGraphicalAnnnotation
	This function refactors the graphical annotations of a class to the modelica standard.
"
  input Absyn.Program wholeAST; //AST
  input Absyn.Class classToRefactor;
  output Absyn.Class changedClass; //Manipulerad AST
algorithm
  changedClass := matchcontinue (wholeAST, classToRefactor)
    local
      list<Absyn.Class> classList, other;
      Absyn.Class c;
      Absyn.Within w;
      Absyn.Program p;
    case(wholeAST, classToRefactor)
      equation
        c = refactorGraphAnnInClass(classToRefactor,wholeAST,Absyn.IDENT(""));
      then
        c;

  end matchcontinue;
end refactorGraphicalAnnotation;

protected function refactorGraphAnnInClass "function: refactorGraphAnnInClass
	Helper function to refactorGraphicalAnnotation. Part of the AST traverse.
"
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  output Absyn.Class outClass;

algorithm
  outClass:= matchcontinue (inClass,inProgram,classPath)
    local
      Absyn.Program p;
      Absyn.ClassDef resultClassDef;
      Absyn.Class c;
      String n;
      Boolean part,f,e;
      Absyn.Restriction r;
      Absyn.ClassDef d,inClassDef;
      Absyn.Info file_info;
      Absyn.Path cPath;
      Env.Env env;

    case (Absyn.CLASS(
      name = n,
      partial_ = part,
      final_ = f,
      encapsulated_ = e,
      restriction = r,
      body = d,
      info = file_info),p,Absyn.IDENT(name = ""))
      equation
        //debug_print("Refactoring Class1:", n);
        cPath = Absyn.IDENT(n);
        env = Interactive.getClassEnv(p,cPath);
        resultClassDef = refactorGraphAnnInClassDef(d,p,cPath,env);
      then
        Absyn.CLASS(n,part,f,e,r,resultClassDef,file_info);

    case (Absyn.CLASS(
      name = n,
      partial_ = part,
      final_ = f,
      encapsulated_ = e,
      restriction = r,
      body = d,
      info = file_info),p,cPath)
      equation
       //  debug_print("Refactoring Class:", n);
        cPath = Absyn.joinPaths(cPath,Absyn.IDENT(n));
        env = Interactive.getClassEnv(p,cPath);
        resultClassDef = refactorGraphAnnInClassDef(d,p,cPath,env);
      then
        Absyn.CLASS(n,part,f,e,r,resultClassDef,file_info);

  end matchcontinue;

end refactorGraphAnnInClass;

protected function refactorGraphAnnInClassDef "function: refactorGraphAnnInClassDef
	Helper function to refactorGraphAnnInClass. Part of AST traverse.
"
  input Absyn.ClassDef inDef;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input Env.Env inClassEnv;
  output Absyn.ClassDef outDef;
algorithm
  outDef := matchcontinue (inDef,inProgram,classPath,inClassEnv)
    local
      Absyn.Program p;
      Absyn.ClassDef cd;
      list<Absyn.ClassPart> cp,resultPart;
      Option<String> cmt;
      Option<Absyn.Comment> com;
      Absyn.ElementAttributes attrs;
     Absyn.Ident n;
      list<Absyn.ElementArg> args,annList,resAnnList;
      Absyn.TypeSpec ts;
      Absyn.Path cPath;
      Env.Env env;

    case(Absyn.PARTS(classParts = cp, comment = cmt),p,cPath,env)
      equation
        resultPart = refactorGraphAnnInClassParts(cp,p,cPath,env);
      then
        Absyn.PARTS(resultPart,cmt);

    case(Absyn.DERIVED(typeSpec = ts, attributes = attrs,arguments = args, comment = SOME(Absyn.COMMENT(annotation_=SOME(Absyn.ANNOTATION(elementArgs = annList)),comment = cmt))),p,cPath,env)
      equation
        resAnnList = transformClassAnnList(annList,{"Class"},{},p);
      then
        Absyn.DERIVED(ts,attrs,args,SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(resAnnList)),cmt)));
 /*   case(Absyn.CLASS_EXTENDS(name = n,arguments = annList, comment = cmt,parts = cp),p,cPath,env)
      equation
        resultPart = refactorGraphAnnInClassParts(cp,p,cPath,env);
        resAnnList = transformClassAnnList(annList,{"Class"},{},p);
      then
        Absyn.CLASS_EXTENDS(n,resAnnList,cmt,resultPart);                */

    case(cd,p,_,_) then cd;

  end matchcontinue;

end refactorGraphAnnInClassDef;

protected function refactorGraphAnnInClassParts "function: refactorGraphAnnInClassParts
	Helper function to refactorGraphAnnInClassDef. Part of the AST traverse.
"
  input list<Absyn.ClassPart> inParts;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input Env.Env env;
  output list<Absyn.ClassPart> outParts;
algorithm
  outParts := matchcontinue (inParts,inProgram,classPath,env)
    local
      Absyn.Program p;
      list<Absyn.ClassPart> restParts,resParts,resultParts;
      Absyn.ClassPart firstPart,resultPart;
      Absyn.Path cPath;
      Env.Env env;
    case({},_,_,_) then {};
    case(firstPart :: restParts ,p,cPath, env)
      equation
        resultPart = refactorGraphAnnInClassPart(firstPart,p,cPath,env);
        resParts = refactorGraphAnnInClassParts(restParts,p,cPath,env);
      then
        resultPart :: resParts;
  end matchcontinue;
end refactorGraphAnnInClassParts;

protected function refactorGraphAnnInClassPart"function: refactorGraphAnnInClassPart
	Helper function to refactorGraphAnnInClassParts. Part of the AST traverse.
"
  input Absyn.ClassPart inPart;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input Env.Env inClassEnv;
  output Absyn.ClassPart outPart;

algorithm

  outPart := matchcontinue (inPart,inProgram,classPath,inClassEnv)

    local

      Absyn.Program p;
      list<Absyn.ElementItem> elContent,resultElContent;
      list<Absyn.EquationItem> eqContent,resultEqContent;
      list<Absyn.AlgorithmItem> algContent,resultAlgContent;
      Absyn.ClassPart cp;
      Absyn.Path cPath;
      Env.Env env;

    case(Absyn.PUBLIC(contents = elContent),p,cPath,env)
      equation
        resultElContent = refactorGraphAnnInContentList(elContent,refactorGraphAnnInElItem,p,cPath,env);
      then
        Absyn.PUBLIC(resultElContent);

    case(Absyn.PROTECTED(contents = elContent),p,cPath,env)
      equation
        resultElContent = refactorGraphAnnInContentList(elContent,refactorGraphAnnInElItem,p,cPath,env);
      then
        Absyn.PROTECTED(resultElContent);

    case(Absyn.EQUATIONS(contents = eqContent),p,cPath,env)
      equation
        resultEqContent = refactorGraphAnnInContentList(eqContent,refactorGraphAnnInEqItem,p,cPath,env);
      then
        Absyn.EQUATIONS(resultEqContent);

    case(Absyn.ALGORITHMS(contents = algContent),p,cPath,env)
      equation
        resultAlgContent = refactorGraphAnnInContentList(algContent,refactorGraphAnnInAlgItem,p,cPath,env);
      then
        Absyn.ALGORITHMS(resultAlgContent);

    case(Absyn.INITIALEQUATIONS(contents = eqContent),p,cPath,env)
      equation
        resultEqContent = refactorGraphAnnInContentList(eqContent,refactorGraphAnnInEqItem,p,cPath,env);
      then
        Absyn.INITIALEQUATIONS(resultEqContent);

    case(Absyn.INITIALALGORITHMS(contents = algContent),p,cPath,env)
      equation
        resultAlgContent = refactorGraphAnnInContentList(algContent,refactorGraphAnnInAlgItem,p,cPath,env);
      then
        Absyn.INITIALALGORITHMS(resultAlgContent);

    case(cp,p,_,_) then cp;
  end matchcontinue;
end refactorGraphAnnInClassPart;


protected function refactorGraphAnnInContentList"function: refactorGraphAnnInContentList
	Helper function to refactorGraphAnnInClassPart. Part of the AST traverse.
"
  input list<contentType> inList;
  input refactorGraphAnnInContent refactorGraphAnnInItem;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input Env.Env inClassEnv;
  output list<contentType> outList;
  public
  replaceable type contentType subtypeof Any;
  partial function refactorGraphAnnInContent
    input contentType inItem;
    input Absyn.Program inProgram;
    input Absyn.Path classPath;
    input Env.Env inClassEnv;
    output contentType outItem;
  end refactorGraphAnnInContent;
algorithm
  outList := matchcontinue (inList,refactorGraphAnnInItem,inProgram,classPath,inClassEnv)
    local
      Absyn.Program p;
      list<contentType> restList,resultList,resList;
      contentType firstItem,resultItem;
      Absyn.Path cPath;
      Env.Env env;
    case({},_,_,_,_) then {};
    case(firstItem :: restList,refactorGraphAnnInItem,p,cPath,env)
      equation
        resultItem = refactorGraphAnnInItem(firstItem,p,cPath,env);
        resList = refactorGraphAnnInContentList(restList,refactorGraphAnnInItem,p,cPath,env);
      then
        resultItem :: resList;
  end matchcontinue;
end refactorGraphAnnInContentList;

protected function refactorGraphAnnInElItem"function: refactorGraphAnnInElItem
	Helper function to refactorGraphAnnInClassPart. Part of the AST traverse.
"
  input Absyn.ElementItem inItem;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input Env.Env inClassEnv;
  output Absyn.ElementItem outItem;
algorithm
  outItem := matchcontinue (inItem,inProgram,classPath,inClassEnv)
    local
      Absyn.Program p;
      Context context;
      Absyn.Element el,resultElement;
      list<Absyn.ElementArg> annList;
      Absyn.Path cPath;
      Env.Env env;

    case(Absyn.ANNOTATIONITEM(annotation_ = Absyn.ANNOTATION(elementArgs = annList)),p,_,env)
      equation
        annList = transformClassAnnList(annList,{"Class"},{},p);
      then
        Absyn.ANNOTATIONITEM(Absyn.ANNOTATION(annList));

    case(Absyn.ELEMENTITEM(element = el) ,p,cPath,env)
      equation
        resultElement = refactorGraphAnnInElement(el,p,cPath,env);
      then
        Absyn.ELEMENTITEM(resultElement);
  end matchcontinue;
end refactorGraphAnnInElItem;

protected function refactorGraphAnnInEqItem"function: refactorGraphAnnInEqItem
	Helper function to refactorGraphAnnInClassPart. Part of the AST traverse.
"
  input Absyn.EquationItem inItem;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input Env.Env inClassEnv;
  output Absyn.EquationItem outItem;

algorithm

  outItem := matchcontinue (inItem,inProgram,classPath,inClassEnv)

    local
      Absyn.Program p;
      Absyn.Equation e;
      Absyn.EquationItem ei;
      Option<String> com;
      Absyn.Annotation a;
      list<Absyn.ElementArg> annList;
      Absyn.Path cPath;

    case(Absyn.EQUATIONITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = annList)),p,_,_)
      equation
        annList = transformClassAnnList(annList,{"Class"},{},p); //ClasS!??!
      then Absyn.EQUATIONITEMANN(Absyn.ANNOTATION(annList));

    case(Absyn.EQUATIONITEM(equation_ = e, comment =
      SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(elementArgs = annList)),comment = com))),p,_,_)
      equation
        annList = transformConnectAnnList(annList,{"Connect"},{},p); //Connectannotation
      then
        Absyn.EQUATIONITEM(e,SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annList)),com)));
    case(ei,p,_,_) then ei;
  end matchcontinue;
end refactorGraphAnnInEqItem;

protected function refactorGraphAnnInAlgItem"function: refactorGraphAnnInAlgItem
	Helper function to refactorGraphAnnInClassPart. Part of the AST traverse.
"
  input Absyn.AlgorithmItem inItem;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input Env.Env inClassEnv;
  output Absyn.AlgorithmItem outItem;
algorithm
  outItem := matchcontinue (inItem,inProgram,classPath,inClassEnv)
    local
      Absyn.Program p;
      Absyn.AlgorithmItem algI;
      Absyn.Algorithm alg;
      Option<String> com;
      list<Absyn.ElementArg> annList;
      Absyn.Path cPath;
    case(Absyn.ALGORITHMITEMANN(annotation_ =  Absyn.ANNOTATION(elementArgs = annList) ),p,_,_)
      equation
        annList = transformClassAnnList(annList,{"Class"},{},p);
      then
        Absyn.ALGORITHMITEMANN(Absyn.ANNOTATION(annList));

    case(Absyn.ALGORITHMITEM(algorithm_ = alg, comment =
      SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annList)),com))),p,_,_)
      equation
        //        a = transformGraphAnn(a,p); whut?

      then
        Absyn.ALGORITHMITEM(alg,SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annList)),com)));

    case(algI,p,_,_) then algI;

  end matchcontinue;

end refactorGraphAnnInAlgItem;

protected function refactorGraphAnnInElement"function: refactorGraphAnnInElement

	Helper function to refactorGraphAnnInElItem. Part of the AST traverse.

"
  input Absyn.Element inElement;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input Env.Env inClassEnv;
  output Absyn.Element outElement;

algorithm

  outElement := matchcontinue (inElement,inProgram,classPath,inClassEnv)

    local

      Absyn.Program p;
      Boolean f;
      Option<Absyn.RedeclareKeywords> rdk;
      Absyn.InnerOuter io;
      Absyn.Ident n;
      Absyn.ElementSpec es,resultSpec;
      Absyn.Info i;
      Option<Absyn.ConstrainClass> cc;
      Absyn.Path cPath;
      Env.Env env;

    case(Absyn.ELEMENT(final_ = f, redeclareKeywords = rdk,
      innerOuter = io, name = n, specification = es, info = i, constrainClass = cc),p,cPath,env)

      equation

        cc = refactorConstrainClass(cc,p,cPath,env);
        resultSpec = refactorGraphAnnInElSpec(es,p,cPath,env);

      then
        Absyn.ELEMENT(f,rdk,io,n,resultSpec,i,cc);

  end matchcontinue;

end refactorGraphAnnInElement;

protected function refactorConstrainClass "function: refactorGraphAnnInElement

	Helper function to refactorGraphAnnInElItem. Part of the AST traverse.

"
  input Option<Absyn.ConstrainClass> inCC;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input Env.Env inClassEnv;
  output Option<Absyn.ConstrainClass> outCC;

algorithm

  outCC := matchcontinue (inCC,inProgram,classPath,inClassEnv)

	local
      Absyn.Program p;
      Absyn.ElementSpec es,resultSpec;
      Option<Absyn.Comment> com;
      Absyn.Path cPath;
      Env.Env env;
    case(SOME(Absyn.CONSTRAINCLASS(elementSpec = es, comment = com)),p,cPath,env)

      equation
       resultSpec = refactorGraphAnnInElSpec(es,p,cPath,env);

      then
        SOME(Absyn.CONSTRAINCLASS(resultSpec,com));
    case(NONE,_,_,_)
    then NONE;
	end matchcontinue;
end refactorConstrainClass;

protected function refactorGraphAnnInElSpec"function: refactorGraphAnnInElSpec

	Helper function to refactorGraphAnnInElement Part of the AST traverse.

"
  input Absyn.ElementSpec inSpec;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input Env.Env inClassEnv;
  output Absyn.ElementSpec outSpec;

algorithm

  outSpec := matchcontinue (inSpec,inProgram,classPath,inClassEnv)

    local

      Absyn.Program p;
      Absyn.ElementSpec e;
      Absyn.ElementAttributes at;
      Absyn.Path path,cPath;
      Absyn.ComponentItem firstComp,resultComp;
      list<Absyn.ComponentItem> restCompList,resCompList,resultCompList;
      Absyn.Class cl,cl1;
      Boolean r;
      Env.Env env;

    case(Absyn.CLASSDEF(replaceable_ = r, class_ = cl),p,cPath,env)

      equation

        cl1 = refactorGraphAnnInClass(cl,p,cPath);

      then
        Absyn.CLASSDEF(r,cl1);

    case(Absyn.COMPONENTS(at,Absyn.TPATH(path,z),firstComp :: restCompList),p,cPath,env)
      local Option<Absyn.ArrayDim> z;
      equation
        resultComp = refactorGraphAnnInComponentItem(firstComp,cPath,path,p,env);
        Absyn.COMPONENTS(at,Absyn.TPATH(path,z),resCompList) =
          refactorGraphAnnInElSpec(Absyn.COMPONENTS(at,Absyn.TPATH(path,z),restCompList),p,cPath,env);
        //resultCompList = resultComp :: resCompList;

      then
        Absyn.COMPONENTS(at,Absyn.TPATH(path,z), resultComp :: resCompList); //resultCompList);



    case(e,p,_,_)

    then e;

  end matchcontinue;

end refactorGraphAnnInElSpec;



protected function refactorGraphAnnInComponentItem"function: refactorGraphAnnInComponentItem

	Helper function to refactorGraphAnnInElSpec Part of the AST traverse.

"
  input Absyn.ComponentItem inCom;
  input Absyn.Path classPath;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Env.Env inClassEnv;
  output Absyn.ComponentItem outCom;

algorithm

  outCom := matchcontinue (inCom,classPath,inPath,inProgram,inClassEnv)

    local

      Absyn.Program p;
      Absyn.Path path,cPath;
      Option<Absyn.ComponentCondition> con;
      Absyn.Component comp;
      list<Absyn.ElementArg> annList;
      Option<String> str;
      Option<Absyn.Comment> com;
      Env.Env env;

    case(Absyn.COMPONENTITEM(component = comp, condition = con,
      comment = SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(elementArgs = annList)), comment = str))),
      cPath,path,p,env)
      equation
        annList = transformComponentAnnList(annList,{"Component"},{},cPath,path,p,env);

      then
        Absyn.COMPONENTITEM(comp,con,SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annList)),str))/*NONE*/);

    case(Absyn.COMPONENTITEM(comp, con, com),_,_,_,_)
    then Absyn.COMPONENTITEM(comp,con,com);

  end matchcontinue;

end refactorGraphAnnInComponentItem;


protected function transformComponentAnnList "function: transformComponentAnnList

	This function transforms old component annotations to new ones
"

  input list<Absyn.ElementArg> inArgs;
  input Context inCon;
  input list<Absyn.ElementArg> resultList;
  input Absyn.Path classPath;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Env.Env inClassEnv;
  output list<Absyn.ElementArg> outArgs;

algorithm

  outArgs := matchcontinue (inArgs,inCon,resultList,classPath,inPath,inProgram,inClassEnv)

    local
      Absyn.Program p;
      Absyn.Path path,cPath;
      Absyn.Exp x1,x2,y1,y2,rx1,rx2,ry1,ry2;
      Integer ix1,ix2,iy1,iy2;
      list<Absyn.ElementArg> args,rest,res,trans;
      Absyn.ElementArg arg,iconTrans,diagramTrans;
      Context context, c;
      Boolean fi;
      Absyn.Each e;
      Option<String> com;
      list<Absyn.Subscript> s;
      Option<Real> rot;
      Env.Env env;


    case({},_,res,_,_,_,_) then res ;

    case(Absyn.MODIFICATION(
      finalItem = fi,
      each_ = e,
      componentReg =
      	Absyn.CREF_IDENT(name = "extent",subscripts = s),
      modification =
      	SOME(Absyn.CLASSMOD(elementArgLst = args, expOption = SOME(Absyn.MATRIX(matrix = {{x1,y1},{x2,y2}} )))),
      comment = com) :: rest,context as ("Component" :: c),res,cPath,path,p,env)

      equation

        Absyn.R_CONNECTOR() = getRestrictionFromPath(cPath,path,p,env)"Fails the case if we shouldn't have a iconTransformation";
        rot = getRotationDegree(listAppend(res,rest));
        iconTrans = getIconTransformation(x1,y1,x2,y2,rot,cPath,path,p,env);
        diagramTrans = getDiagramTransformation(x1,y1,x2,y2,rot,cPath,path,p,env);
        trans = listAppend({diagramTrans},{iconTrans});
        res = transformComponentAnnList(rest,context,res,cPath,path,p,env);
        res = {Absyn.MODIFICATION(fi, e, Absyn.CREF_IDENT("Placement",s), SOME(Absyn.CLASSMOD(trans, NONE)),/*NONE,*/com)};//:: res; //SOME(Absyn.ARRAY({Absyn.ARRAY({x1,y1}	),Absyn.ARRAY({x2,y2})}))

      then res;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e,
      componentReg = Absyn.CREF_IDENT(name = "extent",subscripts = s),
      modification = SOME(Absyn.CLASSMOD(elementArgLst = args,
      expOption = SOME(Absyn.MATRIX(matrix = {{x1,y1},{x2,y2}} )))), comment = com) :: rest,
      context as ("Component" :: c),res,cPath,path,p,env)

      equation

        rot = getRotationDegree(listAppend(res,rest));
        diagramTrans = getDiagramTransformation(x1,y1,x2,y2,rot,cPath,path,p,env);
        res = transformComponentAnnList(rest,context,res,cPath,path,p,env);
        res = {Absyn.MODIFICATION(fi, e, Absyn.CREF_IDENT("Placement",s), SOME(Absyn.CLASSMOD({diagramTrans}, NONE))/*NONE*/,com)};//:: res; /*SOME(Absyn.ARRAY({Absyn.ARRAY({x1,y1}	),Absyn.ARRAY({x2,y2})}))*/

      then res;

    case(arg :: rest,context,res,cPath,path,p,env)
      equation
        res = arg :: res;
        res = transformComponentAnnList(rest,context,res,cPath,path,p,env);

      then res;
  end matchcontinue;

end transformComponentAnnList;

protected function getRestrictionFromPath"function: getRestrictionFromPath

	Helper function to transformComponentAnnList. This function takes a path and a program
	as arguments and then returns the class restriction to that path.
"
  input Absyn.Path classPath;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Env.Env inClassEnv;
  output Absyn.Restriction outRestriction;

algorithm

  outResttriction := matchcontinue(classPath,inPath,inProgram, inClassEnv)

    local

      Absyn.Class cdef;
      Absyn.Program p;
      Absyn.Path fullPath,path,cPath;
      Absyn.Restriction restriction;
      Env.Env env;

    case(cPath,path,p, env) // try directly first
      equation
        fullPath = fixPaths(cPath, path);
       // debug_print("getRestrictionFromPath: TryingLookingUp:", Absyn.pathString(fullPath));
        cdef = Interactive.getPathedClassInProgram(fullPath,p);
        restriction = getRestrictionInClass(cdef);
      then
        restriction;

    case(cPath,path,p, env) // if it fails try the hard way
      equation
        (_,fullPath) = Inst.makeFullyQualified(Env.emptyCache,env,path);
    //    debug_print("getRestrictionFromPath: LookingUp:", Absyn.pathString(fullPath));
        cdef = Interactive.getPathedClassInProgram(fullPath,p);
        restriction = getRestrictionInClass(cdef);
      then
        restriction;

    case(cPath,path,p, env)
      equation
//        debug_print("\ngetPathedClassInProgram:", "failed!");
      then fail();


  end matchcontinue;

end getRestrictionFromPath;

protected function getRestrictionInClass"function: getRestrictionFromClass

	Helper function to getRestrictionInPath. This function takes a class as
	argument and then returns the restriction to that class.
"

  input Absyn.Class inClass;
  output Absyn.Restriction outRestriction;

algorithm

  outRestriction := matchcontinue(inClass)

    local

      Absyn.Restriction restriction;

    case(Absyn.CLASS(restriction = restriction))

    then
      restriction;

  end matchcontinue;

end getRestrictionInClass;

protected function getRotationDegree"function: getRotationDegree

	Helper function to transformComponentAnnList. This function checks if there's a rotation
	annotation in the ElementArg list and then returns the degree of rotation.
"

  input list<Absyn.ElementArg> inList;
  output Option<Real> degrees;

algorithm

  degrees := matchcontinue(inList)

    local

      Real rot;
      Absyn.Exp ex;
      list<Absyn.ElementArg> rest;
      Option<Real> res;

    case({}) then NONE;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "rotation"), modification = SOME(Absyn.CLASSMOD(expOption = SOME(ex)))) :: rest)

      equation


        rot = (getValueFromExp(ex));

      then
        SOME(rot);

    case(_ :: rest)

      equation

        res = getRotationDegree(rest);

      then
        res;

  end matchcontinue;

end getRotationDegree;

protected function getIconTransformation"function: getIconTransformation

	Helper function to transformComponentAnnList. This function calculates and returns the iconTransformation
	annotation.
"

  input Absyn.Exp ax1;
  input Absyn.Exp ay1;
  input Absyn.Exp ax2;
  input Absyn.Exp ay2;
  input Option<Real> inRotation;
  input Absyn.Path classPath;
  input Absyn.Path inPath;
  input Absyn.Program inProg;
  input Env.Env inClassEnv;
  output Absyn.ElementArg iconTrans;

algorithm

  iconTrans := matchcontinue(ax1,ay1,ax2,ay2,inRotation,classPath,inPath,inProg,inClassEnv)

    local

      Integer s;
      Real rcx1,rcy1,rcx2,rcy2,rax1,ray1,rax2,ray2,rot;
      Absyn.ElementArg scale,aspectRatio,x,y,flipHorizontal,flipVertical,rotation;
      Absyn.Path path,cPath;
      Absyn.Program p;
      Absyn.Exp x1,x2,y1,y2;
      Env.Env env;

    case(x1,y1,x2,y2,NONE,cPath,path,p,env)

      equation

        rax1 = getValueFromExp(x1);
        ray1 = getValueFromExp(y1);
        rax2 = getValueFromExp(x2);
        ray2 = getValueFromExp(y2);

        (x1,y1,x2,y2) = getCoordsInPath(cPath,path,p,{"Icon"}, env);
        rcx1 = getValueFromExp(x1);
        rcy1 = getValueFromExp(y1);
        rcx2 = getValueFromExp(x2);
        rcy2 = getValueFromExp(y2);

        aspectRatio = getAspectRatioAnn(rax1,rax2,ray1,ray2,rcx1,rcy1,rcx2,rcy2);
        x = getXYAnn(rax1,rax2,"x");
        y = getXYAnn(ray1,ray2,"y");
        scale = getScaleAnn(rax1,rax2,rcx1,rcx2);
        flipHorizontal = getFlipAnn(rax1,rax2,"flipHorizontal");
        flipVertical = getFlipAnn(ray1,ray2,"flipVertical");

      then Absyn.MODIFICATION(false,Absyn.NON_EACH,Absyn.CREF_IDENT("iconTransformation",{}),SOME(Absyn.CLASSMOD({x,y,scale,aspectRatio,flipHorizontal,flipVertical},NONE)),NONE);

    case(x1,y1,x2,y2,SOME(rot),cPath,path,p, env)

      equation

        rax1 = getValueFromExp(x1);
        ray1 = getValueFromExp(y1);
        rax2 = getValueFromExp(x2);
        ray2 = getValueFromExp(y2);
        (x1,y1,x2,y2) = getCoordsInPath(cPath,path,p,{"Icon"}, env);
        rcx1 = getValueFromExp(x1);
        rcy1 = getValueFromExp(y1);
        rcx2 = getValueFromExp(x2);
        rcy2 = getValueFromExp(y2);
        aspectRatio = getAspectRatioAnn(rax1,rax2,ray1,ray2,rcx1,rcy1,rcx2,rcy2);
        x = getXYAnn(rax1,rax2,"x");
        y = getXYAnn(ray1,ray2,"y");
        scale = getScaleAnn(rax1,rax2,rcx1,rcx2);
        flipHorizontal = getFlipAnn(rax1,rax2,"flipHorizontal");
        flipVertical = getFlipAnn(ray1,ray2,"flipVertical");
        rotation = getRotationAnn(rot);

      then Absyn.MODIFICATION(false,Absyn.NON_EACH,Absyn.CREF_IDENT("iconTransformation",{}),SOME(Absyn.CLASSMOD({x,y,scale,aspectRatio,flipHorizontal,flipVertical,rotation},NONE)),NONE);

  end matchcontinue;

end getIconTransformation;

protected function getDiagramTransformation"function: getDiagramTransformation

	Helper function to transformComponentAnnList. This function calculates and returns the transformation
	annotation.
"

  input Absyn.Exp ax1;
  input Absyn.Exp ay1;
  input Absyn.Exp ax2;
  input Absyn.Exp ay2;
  input Option<Real> inRotation;
  input Absyn.Path classPath;
  input Absyn.Path inPath;
  input Absyn.Program inProg;
  input Env.Env inClassEnv;
  output Absyn.ElementArg trans;

algorithm

  trans := matchcontinue(ax1,ay1,ax2,ay2,inRotation,classPath,inPath,inProg, inClassEnv)

    local

      Integer s;
      Real rcx1,rcy1,rcx2,rcy2,rax1,ray1,rax2,ray2,rot;
      Absyn.ElementArg scale,aspectRatio,x,y,flipHorizontal,flipVertical,rotation;
      Absyn.Path path,cPath;
      Absyn.Program p;
      Absyn.Exp x1,x2,y1,y2;
      Env.Env env;

    case(x1,y1,x2,y2,NONE,cPath,path,p, env)

      equation

	      rax1 = getValueFromExp(x1);
        ray1 = getValueFromExp(y1);
        rax2 = getValueFromExp(x2);
        ray2 = getValueFromExp(y2);
        (x1,y1,x2,y2) = getCoordsInPath(cPath,path,p,{"Diagram"}, env);
        rcx1 = getValueFromExp(x1);
        rcy1 = getValueFromExp(y1);
        rcx2 = getValueFromExp(x2);
        rcy2 = getValueFromExp(y2);

   //     (x1,y1,x2,y2) = getCoordsInPath(cPath,path,p,{"Diagram"}, env);
        aspectRatio = getAspectRatioAnn(rax1,rax2,ray1,ray2,rcx1,rcy1,rcx2,rcy2);
        x = getXYAnn(rax1,rax2,"x");
        y = getXYAnn(ray1,ray2,"y");
        scale = getScaleAnn(rax1,rax2,rcx1,rcx2);
        flipHorizontal = getFlipAnn(rax1,rax2,"flipHorizontal");
        flipVertical = getFlipAnn(ray1,ray2,"flipVertical");

      then Absyn.MODIFICATION(false,Absyn.NON_EACH,Absyn.CREF_IDENT("transformation",{}),SOME(Absyn.CLASSMOD({x,y,scale,aspectRatio,flipHorizontal,flipVertical},NONE)),NONE);

    case(x1,y1,x2,y2,SOME(rot),cPath,path,p, env)

      equation

	      rax1 = getValueFromExp(x1);
        ray1 = getValueFromExp(y1);
        rax2 = getValueFromExp(x2);
        ray2 = getValueFromExp(y2);

        (x1,y1,x2,y2) = getCoordsInPath(cPath,path,p,{"Diagram"}, env);
        rcx1 = getValueFromExp(x1);
        rcy1 = getValueFromExp(y1);
        rcx2 = getValueFromExp(x2);
        rcy2 = getValueFromExp(y2);
        aspectRatio = getAspectRatioAnn(rax1,rax2,ray1,ray2,rcx1,rcy1,rcx2,rcy2);
        x = getXYAnn(rax1,rax2,"x");
        y = getXYAnn(ray1,ray2,"y");
        scale = getScaleAnn(rax1,rax2,rcx1,rcx2);
        flipHorizontal = getFlipAnn(rax1,rax2,"flipHorizontal");
        flipVertical = getFlipAnn(ray1,ray2,"flipVertical");
        rotation = getRotationAnn(rot);

      then
        Absyn.MODIFICATION(false,Absyn.NON_EACH,Absyn.CREF_IDENT("transformation",{}),SOME(Absyn.CLASSMOD({x,y,scale,aspectRatio,flipHorizontal,flipVertical,rotation},NONE)),NONE);

  end matchcontinue;

end getDiagramTransformation;

protected function getAspectRatioAnn"function: getAspectRatioAnn

	Helper function to getIconTransformation and getDiagramTransformation. This function calculates and returns the aspect ratio
	annotation.
"
  input Real x1;
  input Real x2;
  input Real y1;
  input Real y2;
  input Real cx1;
  input Real cy1;
  input Real cx2;
  input Real cy2;
  output Absyn.ElementArg aspectRatio;


algorithm

  aspectRatio := matchcontinue (x1,x2,y1,y2,cx1,cy1,cx2,cy2)

    local

      Real aspect;
      Real 	crx1,cry1,crx2,cry2,rx1,rx2,ry1,ry2;


    case(rx1,rx2,ry1,ry2,crx1,cry1,crx2,cry2)


      equation

        aspect = (realAbs(ry2-.ry1)*.(realAbs(cry2-.cry1)))/.(realAbs(rx2-.rx1)*.(realAbs(crx2-.crx1)));

      then
        Absyn.MODIFICATION(false,Absyn.NON_EACH,Absyn.CREF_IDENT("aspectRatio",{}),SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(aspect)))),NONE);

  end matchcontinue;

end getAspectRatioAnn;

protected function getXYAnn"function: getXYAnn

	Helper function to getIconTransformation and getDiagramTransformation. This function calculates and returns the X or Y
	annotation.
"
	input Real val1;
	input Real val2;
  input Absyn.Ident name;
  output Absyn.ElementArg res;

algorithm

  res := matchcontinue(val1,val2,name)

    local

      Real x1,x2;
      Real value;
      Absyn.Ident n;

    case(x1,x2,n)

      equation

                value = (x1+.x2)/.2.0;
      then
        Absyn.MODIFICATION(false,Absyn.NON_EACH,Absyn.CREF_IDENT(n,{}),SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(value)))),NONE);

  end matchcontinue;

end getXYAnn;

protected function getScaleAnn"function: getScaleAnn

	Helper function to getIconTransformation and getDiagramTransformation. This function calculates and returns the scale
	annotation.
"
  input Real ax1;
  input Real ax2;
  input Real cx1;
  input Real cx2;
  output Absyn.ElementArg scale;

algorithm

  scale := matchcontinue(ax1,ax2,cx1,cx2)

    local

      Real arx1,arx2,crx1,crx2,scaleFac,tmp1,tmp2;

    case(arx1,arx2,crx1,crx2)

      equation
        scaleFac = (realAbs(arx1-.arx2))/.(realAbs(crx1-.crx2));
      then
        Absyn.MODIFICATION(false,Absyn.NON_EACH,Absyn.CREF_IDENT("scale",{}),SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(scaleFac)))),NONE);

  end matchcontinue;

end getScaleAnn;

protected function getFlipAnn"function: getFlipAnn

	Helper function to getIconTransformation and getDiagramTransformation. This function calculates and returns the flip
	annotations.
"

  input Real val1;
  input Real val2;
  input Absyn.Ident name;
  output Absyn.ElementArg flip;
  Boolean value;

algorithm

  value := val1>.val2;
  flip := Absyn.MODIFICATION(false,Absyn.NON_EACH,Absyn.CREF_IDENT(name,{}),SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(value)))),NONE);

end getFlipAnn;

protected function getRotationAnn"function: getRotationAnn

	Helper function to getIconTransformation and getDiagramTransformation. This function calculates and returns the rotation
	annotation.
"

  input Real rot;
  output Absyn.ElementArg rotation;

algorithm
  rot := rot *. (-1.0);
  rotation := Absyn.MODIFICATION(false,Absyn.NON_EACH,Absyn.CREF_IDENT("rotation",{}),SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(rot)))),NONE);

end getRotationAnn;


protected function getCoordsInPath"function: getCoordsInPath
	Helper function to transformComponentAnnList. This function takes a path and a program
	as arguments and then returns the diagram or icon coordinates in that path.
"
  input Absyn.Path classPath;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Context contextToGetCoordsFrom;
  input Env.Env inClassEnv;
  output Absyn.Exp posX1;
  output Absyn.Exp posY1;
  output Absyn.Exp posX2;
  output Absyn.Exp posY2;

algorithm

  (posX1,posY1,posX2,posY2) := matchcontinue (classPath,inPath,inProgram,contextToGetCoordsFrom, inClassEnv)

    local
      Absyn.Class cdef;
      Absyn.Exp x1,y1,x2,y2;
      Absyn.Path path,fullPath,cPath;
      Absyn.Program p;
      Absyn.ComponentRef cref;
      Context context;


      Env.Env cenv,env;
      String str;
      Env.Cache cache;
      String id;

    case(cPath,path,p,context, env) // try directly first
      equation
        fullPath = fixPaths(cPath, path);
//        debug_print("getCoordsInPath: TryingLookingUp:", Absyn.pathString(fullPath));
        cdef = Interactive.getPathedClassInProgram(fullPath,p);
        (x1,y1,x2,y2) = getCoordsInClass(cdef,context);
      then
       (x1,y1,x2,y2);

    case(cPath,path,p,context, env) // if it doesn't work, try the hard way
      equation
        //	p_1 = SCode.elaborate(p);
        //	(_,env) = Inst.makeSimpleEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT(""));
        (_,fullPath) = Inst.makeFullyQualified(Env.emptyCache,env,path);
        //	print("env:\n");print(Env.printEnvStr(env));
        //str = Absyn.pathString(cPath);
        //print("\npath = ");
        //print(str);
    //    debug_print("getCoordsInPath: LookingUp:", Absyn.pathString(fullPath));
        cdef = Interactive.getPathedClassInProgram(fullPath,p);
        (x1,y1,x2,y2) = getCoordsInClass(cdef,context);
      then
	      (x1,y1,x2,y2);//(Absyn.REAL(-100.0),Absyn.REAL(-100.0),Absyn.REAL(100.0),Absyn.REAL(100.0));

    case(cPath,path,p,context, env) // if it doesn't work, try the hard way
      equation
  //     debug_print("\ngetPathedClassInProgram:", "failed!");
      then fail();

  end matchcontinue;

end getCoordsInPath;

protected function getCoordsInClass"function: getCoordsInClass

	Helper function to getCoordsInPath. This function takes a class and a program
	as arguments and then returns the diagram or icon coordinates in that class.
"

  input Absyn.Class inClass;
  input Context contextToGetCoordsFrom;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;

algorithm

  (x1,y1,x2,y2) := matchcontinue (inClass,contextToGetCoordsFrom)

    local
      Absyn.Exp x1,y2,x2,y2;
      Absyn.Class cdef;
      list<Absyn.ClassPart> parts1;
      list<Absyn.ElementArg> annlist;
      Context context;

    case(Absyn.CLASS(body = Absyn.PARTS(classParts = parts1)),context)

      equation

        (x1,y1,x2,y2) = getCoordsFromParts(parts1,context);

      then
        (x1,y1,x2,y2);
    case(Absyn.CLASS(body = Absyn.DERIVED(comment =  SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(elementArgs = annlist)))))),context)

      	equation

      	  (x1,y1,x2,y2) = getCoordsInAnnList(annlist,context);

			then
			  (x1,y1,x2,y2);
/*	    case(Absyn.CLASS(body = Absyn.CLASS_EXTENDS(arguments = annlist,parts = parts1)),context)

      	equation

      	  //(x1,y1,x2,y2) = getCoordsInAnnList(annlist,context);
      	  (x1,y1,x2,y2) = getCoordsFromParts(parts1,context);
			then
			  (x1,y1,x2,y2);   */
  end matchcontinue;

end getCoordsInClass;

protected function getCoordsFromParts"function: getCoordsFromParts

	Helper function to getCoordsInClass.
"

  input list<Absyn.ClassPart> inParts;
  input Context contextToGetCoordsFrom;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;

algorithm

  (x1,y1,x2,y2) := matchcontinue(inParts,contextToGetCoordsFrom)

    local

      Absyn.Exp x1,y2,x2,y2;
      list<Absyn.ClassPart> rest;
      list<Absyn.ElementItem> elts;
      list<Absyn.EquationItem> eqns;
      list<Absyn.AlgorithmItem> algs;
      Context context;

    case(Absyn.PUBLIC(contents = elts) :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsFromElts(elts,context);

      then
        (x1,y1,x2,y2);

    case(Absyn.PROTECTED(contents = elts) :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsFromElts(elts,context);

      then
        (x1,y1,x2,y2);

    case(Absyn.EQUATIONS(contents = eqns) :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsFromEqns(eqns,context);

      then
        (x1,y1,x2,y2);

    case(Absyn.INITIALEQUATIONS(contents = eqns) :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsFromEqns(eqns,context);

      then
        (x1,y1,x2,y2);

    case(Absyn.ALGORITHMS(contents = algs) :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsFromAlgs(algs,context);

      then
        (x1,y1,x2,y2);

    case(Absyn.INITIALALGORITHMS(contents = algs) :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsFromAlgs(algs,context);

      then
        (x1,y1,x2,y2);

    case(_ :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsFromParts(rest,context);

      then
        (x1,y1,x2,y2);

  end matchcontinue;

end getCoordsFromParts;

protected function getCoordsFromElts"function: getCoordsFromElts

	Helper function to getCoordsFromParts.
"

  input list<Absyn.ElementItem> inElts;
  input Context contextToGetCoordsFrom;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;

algorithm

  (x1,y1,x2,y2) := matchcontinue(inElts,contextToGetCoordsFrom)

    local

      Absyn.Exp x1,y2,x2,y2;
      list<Absyn.ElementItem> rest;
      list<Absyn.ElementArg> annList;
      Context context;

    case(Absyn.ANNOTATIONITEM(annotation_ = Absyn.ANNOTATION(elementArgs = annList)) :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsInAnnList(annList,context);

      then
        (x1,y1,x2,y2);

    case(_ :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsFromElts(rest,context);

      then
        (x1,y1,x2,y2);

  end matchcontinue;

end getCoordsFromElts;

protected function getCoordsFromEqns"function: getCoordsFromEqns

	Helper function to getCoordsFromParts.
"

  input list<Absyn.EquationItem> inEqns;
  input Context contextToGetCoordsFrom;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;

algorithm

  (x1,y1,x2,y2) := matchcontinue(inEqns,contextToGetCoordsFrom)

    local

      Absyn.Exp x1,y2,x2,y2;
      list<Absyn.EquationItem> rest;
      list<Absyn.ElementArg> annList;
      Context context;

    case(Absyn.EQUATIONITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = annList)) :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsInAnnList(annList,context);

      then
        (x1,y1,x2,y2);

    case(_ :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsFromEqns(rest,context);

      then
        (x1,y1,x2,y2);

  end matchcontinue;

end getCoordsFromEqns;

protected function getCoordsFromAlgs"function: getCoordsFromAlgs

	Helper function to getCoordsFromParts.
"

  input list<Absyn.AlgorithmItem> inAlgs;
  input Context contextToGetCoordsFrom;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;

algorithm

  (x1,y1,x2,y2) := matchcontinue(inAlgs,contextToGetCoordsFrom)

    local

      Absyn.Exp x1,y2,x2,y2;
      list<Absyn.AlgorithmItem> rest;
      list<Absyn.ElementArg> annList;
      Context context;

    case(Absyn.ALGORITHMITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = annList)) :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsInAnnList(annList,context);

      then
        (x1,y1,x2,y2);

    case(_ :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsFromAlgs(rest,context);

      then
        (x1,y1,x2,y2);

  end matchcontinue;

end getCoordsFromAlgs;

protected function getCoordsInAnnList"function: getCoordsInAnnList

	Helper function to getCoordsFromEqns,elts,algs.
"

  input list<Absyn.ElementArg> inAnns;
  input Context contextToGetCoordsFrom;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;

algorithm

  (x1,y1,x2,y2) := matchcontinue(inAnns,contextToGetCoordsFrom)

    local

      Absyn.Exp x1,y1,x2,y2;
      list<Absyn.ElementArg> rest,args;
      Context context;

    case({},_) then (Absyn.REAL(-100.0),Absyn.REAL(-100.0),Absyn.REAL(100.0),Absyn.REAL(100.0))/*If coordsys is not explicit defined, old implicit standard is [-100,-100;100,100]*/;
    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Coordsys"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args)))::rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsFromCoordSysArgs(args);
      then
        (x1,y1,x2,y2);

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Icon"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args)))::rest,"Icon" :: context)

      equation

        (x1,y1,x2,y2) = getCoordsFromLayerArgs(args);

      then
        (x1,y1,x2,y2);

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Diagram"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args)))::rest,"Diagram" :: context)

      equation

        (x1,y1,x2,y2) = getCoordsFromLayerArgs(args);

      then
        (x1,y1,x2,y2);

    case(_ :: rest,context)

      equation

        (x1,y1,x2,y2) = getCoordsInAnnList(rest,context);

      then
        (x1,y1,x2,y2);

  end matchcontinue;

end getCoordsInAnnList;

protected function getCoordsFromCoordSysArgs"function: getCoordsFromCoordSysArgs

	Helper function to getCoordsInAnnList.
"
  input list<Absyn.ElementArg> inAnns;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;

algorithm

  (x1,y1,x2,y2) := matchcontinue(inAnns)

    local

      Absyn.Exp x1,y1,x2,y2;
      list<Absyn.ElementArg> rest;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "extent"), modification = SOME(Absyn.CLASSMOD(expOption = SOME(Absyn.MATRIX(matrix = {{x1,y1},{x2,y2}} ))))) :: rest)

    then
      (x1,y1,x2,y2);

    case(_ :: rest)

      equation

        (x1,y1,x2,y2) = getCoordsFromCoordSysArgs(rest);

      then
        (x1,y1,x2,y2);

  end matchcontinue;

end getCoordsFromCoordSysArgs;

protected function getExtentModification
  input list<Absyn.ElementArg> elementArgLst;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;  
algorithm
  (x1,y1,x2,y2) := matchcontinue (elementArgLst)
    local list<Absyn.ElementArg> rest;
    case (Absyn.MODIFICATION(
      componentReg = Absyn.CREF_IDENT(name = "extent"), 
      modification = SOME(Absyn.CLASSMOD(expOption = SOME(Absyn.ARRAY({Absyn.ARRAY({x1,y1}	),Absyn.ARRAY({x2,y2})}))) )):: rest)
      equation
      then (x1,y1,x2,y2);
        
    case (_:: rest)
      equation
        (x1,y1,x2,y2) = getExtentModification(rest);
      then (x1,y1,x2,y2);
  end matchcontinue;         
end getExtentModification ;

protected function getCoordsFromLayerArgs
"function: getCoordsFromLayerArgs
	Helper function to getCoordsInAnnList."
  input list<Absyn.ElementArg> inAnns;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;
algorithm

  (x1,y1,x2,y2) := matchcontinue(inAnns)

    local

      Absyn.Exp x1,y1,x2,y2;
      list<Absyn.ElementArg> rest,args;

    case (Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "coordinateSystem"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args)))::rest)
      equation
        (x1,y1,x2,y2) = getExtentModification(args);
      then
        (x1,y1,x2,y2);

    case(_ :: rest)

      equation

        (x1,y1,x2,y2) = getCoordsFromLayerArgs(rest);

      then
        (x1,y1,x2,y2);


  end matchcontinue;

end getCoordsFromLayerArgs;

protected function transformConnectAnnList "function: transformConnectAnnList

	This function transforms old connect annotations to new ones
"

  input list<Absyn.ElementArg> inArgs;
  input Context inCon;
  input list<Absyn.ElementArg> resultList;
  input Absyn.Program inProgram;

  output list<Absyn.ElementArg> outArgs;

algorithm

  outArgs := matchcontinue (inArgs,inCon,resultList,inProgram)

    local
      Absyn.Program p;
      list<list<Absyn.Exp>> expMatrix;
      list<Absyn.Exp> expLst;
      Absyn.Exp x1,x2,y1,y2;
      Integer x,color1,color2,color3;
      String val,val1,val2;
      list<String> arrows;
      Real thick;
      list<Absyn.ElementArg> args,rest,res,argRes,restRes;
      Absyn.ElementArg arg;
      Context context, c;
      Boolean fi;
      Absyn.Each e;
      Option<String> com;
      list<Absyn.Subscript> s;
      Option<Absyn.Exp> ex;

    case({},_,res,p) then res ;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "points",subscripts = s), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,expOption =  SOME(Absyn.MATRIX(matrix = expMatrix ))  )), comment = com) :: rest,context as ("Connect" :: c),res,p)

      equation

        context = addContext(context,"Line");
        expLst = Util.listMap(expMatrix,matrixToArray);
        res = transformConnectAnnList(rest,context,res,p);

      then {Absyn.MODIFICATION(fi,e,Absyn.CREF_IDENT("Line",s), SOME(Absyn.CLASSMOD(Absyn.MODIFICATION(false,Absyn.NON_EACH,Absyn.CREF_IDENT("points",{}),SOME(Absyn.CLASSMOD({},SOME(Absyn.ARRAY(expLst))  )),NONE) :: res,NONE)),com)};//res;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "points",subscripts = s), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,expOption =  SOME(Absyn.MATRIX(matrix = expMatrix ))  )), comment = com) :: rest,context as ("Line" :: c),res,p)

      equation

        expLst = Util.listMap(expMatrix,matrixToArray);
        res = transformConnectAnnList(rest,context,res,p);

      then Absyn.MODIFICATION(fi,e,Absyn.CREF_IDENT("points",{}),SOME(Absyn.CLASSMOD({},SOME(Absyn.ARRAY(expLst))  )),com) :: res; //res;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "style",subscripts = s), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,expOption =  ex )), comment = com) :: rest,context as ("Connect" :: c),res,p)

      equation

        context = addContext(context,"Line");
        args = cleanStyleAttrs(args,{},context);
        rest = listAppend(args,rest);
        res = transformConnectAnnList(rest,context,res,p);

      then {Absyn.MODIFICATION(fi,e,Absyn.CREF_IDENT("Line",s),SOME(Absyn.CLASSMOD(res,ex)),com)};

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "style",subscripts = s), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,expOption =  ex )), comment = com) :: rest,context as ("Line" :: c),res,p)

      equation

        args = cleanStyleAttrs(args,{},context);
				rest = listAppend(args,rest);
				res = transformConnectAnnList(rest,context,res,p);

      then res;


    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "color",subscripts = s), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,expOption = SOME(Absyn.INTEGER(value = x)))), comment = com) :: rest,context as ("Line" :: c),res,p)

      equation

        (color1,color2,color3) = getMappedColor(x);
        res = transformConnectAnnList(rest,context,res,p);

      then Absyn.MODIFICATION(fi,e,Absyn.CREF_IDENT("color",s), SOME(Absyn.CLASSMOD(args,SOME(Absyn.ARRAY({Absyn.INTEGER(color1),Absyn.INTEGER(color2),Absyn.INTEGER(color3)})))),com):: res;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "pattern",subscripts = s), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,expOption = SOME(Absyn.INTEGER(value = x)))), comment = com) :: rest,context as ("Line" :: c),res,p)

      equation

        val = arrayGet(listArray(patternMapList),x+1);
        res = transformConnectAnnList(rest,context,res,p);

      then Absyn.MODIFICATION(fi,e,Absyn.CREF_IDENT("pattern",s), SOME(Absyn.CLASSMOD(args,SOME(Absyn.CREF(Absyn.CREF_QUAL("LinePattern", {},Absyn.CREF_IDENT(val, {})))))),com):: res;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "thickness",subscripts = s), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,expOption = SOME(Absyn.INTEGER(value = x)))), comment = com) :: rest,context as ("Line" :: c),res,p)

      equation

        thick = arrayGet(listArray(thicknessMapList),x);
        res = transformConnectAnnList(rest,context,res,p);

      then Absyn.MODIFICATION(fi,e,Absyn.CREF_IDENT("thickness",s), SOME(Absyn.CLASSMOD(args,SOME(Absyn.REAL(thick)))),com):: res;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "smooth",subscripts = s), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,expOption = ex)), comment = com) :: rest,context as ("Line" :: c),res,p)

      equation

        res = transformConnectAnnList(rest,context,res,p);

      then Absyn.MODIFICATION(fi,e,Absyn.CREF_IDENT("smooth",s), SOME(Absyn.CLASSMOD(args,ex)),com):: res;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "arrow",subscripts = s), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,expOption = SOME(Absyn.INTEGER(value = x)))), comment = com) :: rest,context as ("Line" :: c),res,p)

      equation

        arrows = arrayGet(listArray(arrowMapList),x+1);
        val1 = arrayGet(listArray(arrows),1);
        val2 = arrayGet(listArray(arrows),2);
        res = transformConnectAnnList(rest,context,res,p);

      then Absyn.MODIFICATION(fi,e,Absyn.CREF_IDENT("arrow",s), SOME(Absyn.CLASSMOD(args,SOME(Absyn.ARRAY({Absyn.CREF(Absyn.CREF_QUAL("Arrow", {},Absyn.CREF_IDENT(val1, {}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT(val2,{})))})))),com):: res;


    case(arg :: rest,context,res,p)

      equation

        res = transformConnectAnnList(rest,context,res,p);

      then arg :: res;

  end matchcontinue;

end transformConnectAnnList;

protected function transformClassAnnList " function transformClassAnnList

	This function transforms old graphical class annotations (i.e Icon/Diagram layers)
	to new ones.
"

  input list<Absyn.ElementArg> inArgs;
  input Context inCon;
  input list<Absyn.ElementArg> resultList;
  input Absyn.Program inProgram;

  output list<Absyn.ElementArg> outArgs;

algorithm

  outArgs := matchcontinue (inArgs,inCon,resultList,inProgram)

    local

      Absyn.Program p;
      Absyn.Exp x1,x2,y1,y2;
      list<Absyn.ElementArg> args,rest,res;
      list<Absyn.Exp> argRes;
      Absyn.ElementArg coord,arg;
      Context context, c;
      Boolean fi;
      Absyn.Each e;
      Option<String> com;
      list<Absyn.Subscript> s;
      Option<Absyn.Exp> ex;


    case({},_,res,p) then res ;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "Icon", subscripts = s), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, expOption =  ex   )), comment = com) :: rest,context as ("Class" :: c),res,p)

      equation

        c = addContext(context,"Layer");
        argRes = transAnnLstToCalls(args,c);
        coord = getCoordSysAnn(listAppend(res,rest),p);
        res = transformClassAnnList(rest,context,res,p);

      then Absyn.MODIFICATION(fi, e, Absyn.CREF_IDENT("Icon",s), SOME(Absyn.CLASSMOD({coord,Absyn.MODIFICATION(false, Absyn.NON_EACH, Absyn.CREF_IDENT("graphics",{}),SOME(Absyn.CLASSMOD({}, SOME(Absyn.ARRAY(argRes))   )),NONE)}, ex)),com) :: res		;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "Diagram", subscripts = s), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, expOption =  ex   )), comment = com) :: rest,context as ("Class" :: c),res,p)

      equation

        c = addContext(context,"Layer");
        argRes = transAnnLstToCalls(args,c);
        coord = getCoordSysAnn(listAppend(res,rest),p);
        res = transformClassAnnList(rest,context,res,p);

      then Absyn.MODIFICATION(fi, e, Absyn.CREF_IDENT("Diagram",s), SOME(Absyn.CLASSMOD({coord,Absyn.MODIFICATION(false, Absyn.NON_EACH, Absyn.CREF_IDENT("graphics",{}),SOME(Absyn.CLASSMOD({}, SOME(Absyn.ARRAY(argRes))   )),NONE)}, ex)),com) :: res;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "Coordsys", subscripts = s), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, expOption =  ex   )), comment = com) :: rest,context,res,p)

      equation

        true = isLayerAnnInList(listAppend(res,rest))/*Fails the case if we have a coordsys without a layer definition*/;
        res = Absyn.MODIFICATION(fi, e, Absyn.CREF_IDENT("Coordsys",s), SOME(Absyn.CLASSMOD(args, ex)),com) :: res;
        res = transformClassAnnList(rest,context,res,p);

      then Util.listDeleteMember(res,Absyn.MODIFICATION(fi, e, Absyn.CREF_IDENT("Coordsys",s), SOME(Absyn.CLASSMOD(args, ex)),com));

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "Coordsys", subscripts = s), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, expOption =  ex   )), comment = com) :: rest,context,res,p)

      equation


        res = Absyn.MODIFICATION(fi, e, Absyn.CREF_IDENT("Coordsys",s), SOME(Absyn.CLASSMOD(args, ex)),com) :: res;
        coord = getCoordSysAnn(listAppend(res,rest),p);
        res = listAppend({Absyn.MODIFICATION(false, Absyn.NON_EACH, Absyn.CREF_IDENT("Diagram",{}), SOME(Absyn.CLASSMOD({coord},NONE)),NONE),Absyn.MODIFICATION(false, Absyn.NON_EACH, Absyn.CREF_IDENT("Icon",{}), SOME(Absyn.CLASSMOD({coord},NONE)),NONE)},res);
        res = transformClassAnnList(rest,context,res,p);

      then Util.listDeleteMember(res,Absyn.MODIFICATION(fi, e, Absyn.CREF_IDENT("Coordsys",s), SOME(Absyn.CLASSMOD(args, ex)),com));

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "extent",subscripts = s), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, expOption = SOME(Absyn.MATRIX(matrix = {{x1,y1},{x2,y2}} )))), comment = com) :: rest,context as ("Coordsys" :: c),res,p)

      equation

        res = Absyn.MODIFICATION(fi, e, Absyn.CREF_IDENT("extent",s), SOME(Absyn.CLASSMOD(args, SOME(Absyn.ARRAY({Absyn.ARRAY({x1,y1}	),Absyn.ARRAY({x2,y2})})))),com) :: res;
        res = transformClassAnnList(rest,context,res,p);

      then res;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "grid")) :: rest,context ,res,p)

      equation

        res = transformClassAnnList(rest,context,res,p);

      then res;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "component")) :: rest,context ,res,p)

      equation

        res = transformClassAnnList(rest,context,res,p);

      then res;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Window")) :: rest,context ,res,p)

      equation

        res = transformClassAnnList(rest,context,res,p);

      then res;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Terminal")) :: rest,context ,res,p)

      equation

        res = transformClassAnnList(rest,context,res,p);

      then res;

    case(arg :: rest,context,res,p)

      equation

        res = transformClassAnnList(rest,context,res,p);

      then arg :: res;

  end matchcontinue;

end transformClassAnnList;

protected function isLayerAnnInList"function: isLayerAnnInList

	Helper function to transformClassAnnList. Returns true if a icon or diagram annotation
	is in the list, false otherwise.
"
  input list<Absyn.ElementArg> inList;
  output Boolean result;

algorithm

  result := matchcontinue(inList)

    local

      list<Absyn.ElementArg> rest;
      Boolean res;

    case({}) then false;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Diagram")) :: rest)

    then
      true;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Icon")) :: rest)

    then
      true;

    case(_ :: rest)

      equation

        res = isLayerAnnInList(rest);

      then
        res;

  end matchcontinue;

end isLayerAnnInList;

protected function  getCoordSysAnn "function: getCoordSysAnn

	Helper function to transformClassAnnList. Fetches an old coordinate system
	annotations and returns it. If none it returns the default system for the old
	standard ([{-100,-100}{100,100}]).
"

  input list<Absyn.ElementArg> inArgs;
  input Absyn.Program inProgram;
  output Absyn.ElementArg coordSys;

algorithm
  coordSys := matchcontinue (inArgs,inProgram)

    local
      Absyn.Program p;
      list<Absyn.ElementArg> args,rest;
      Absyn.ElementArg res;
      Boolean fi;
      Absyn.Each e;
      Option<String> com;
      list<Absyn.Subscript> s;
      Option<Absyn.Exp> ex;

    case ({},_)

    then
      Absyn.MODIFICATION(false, Absyn.NON_EACH, Absyn.CREF_IDENT("coordinateSystem", {}), SOME(Absyn.CLASSMOD({Absyn.MODIFICATION(false, Absyn.NON_EACH, Absyn.CREF_IDENT("extent",{}), SOME(Absyn.CLASSMOD({}, SOME(Absyn.ARRAY({Absyn.ARRAY({Absyn.INTEGER(-100),Absyn.INTEGER(-100)}	),Absyn.ARRAY({Absyn.INTEGER(100),Absyn.INTEGER(100)})})))),NONE)}, NONE)), NONE)/*Create default*/;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "Coordsys", subscripts = s), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, expOption =  ex   )), comment = com) :: rest,p)

      equation

        args = transformClassAnnList(args,"Coordsys"::{},{},p);

      then
        Absyn.MODIFICATION(fi, e, Absyn.CREF_IDENT("coordinateSystem", s), SOME(Absyn.CLASSMOD(args, ex)), com);

    case(_ :: rest,p)

      equation

        res = getCoordSysAnn(rest,p);

      then res;

  end matchcontinue;

end getCoordSysAnn;


protected function transAnnLstToCalls " function: transAnnLstToCalls

	Helper function to transformClassAnnList. Some graphical annotations
	have abstract syntax as CALLS in the new standard
"

  input list<Absyn.ElementArg> inArgs;
  input Context inCon;
  output list<Absyn.Exp> outArgs;

algorithm

  outArgs := matchcontinue (inArgs,inCon)

    local

      list<Absyn.ElementArg> args,rest;
      list<Absyn.Exp> res,restRes;
      list<Absyn.NamedArg> argRes;
      Absyn.Ident n;
      Context context, c;

    case({},_) then {} ;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = n), modification = SOME(Absyn.CLASSMOD(elementArgLst = args))) :: rest,context as ("Layer" :: c))

      equation
        c = addContext(context,n);
        argRes = transAnnLstToNamedArgs(args,c);
				restRes = transAnnLstToCalls(rest,context);

      then
        Absyn.CALL(Absyn.CREF_IDENT(n,{}), Absyn.FUNCTIONARGS({},argRes)) :: restRes;

    case(_ :: rest,context)

      equation

        res = transAnnLstToCalls(rest,context);

      then res;

  end matchcontinue;

end transAnnLstToCalls;

protected function transAnnLstToNamedArgs " function: transAnnLstToNamedArgs

	Helper function to transformClassAnnList. Some graphical annotations
	have abstract syntax as Absyn.NamedArg in the new standard
"

  input list<Absyn.ElementArg> inArgs;
  input Context inCon;
  output list<Absyn.NamedArg> outArgs;

algorithm

  outArgs := matchcontinue (inArgs,inCon)

    local

      list<list<Absyn.Exp>> expMatrix;
      list<Absyn.Exp> expLst;
      Absyn.Exp exp;

      list<Absyn.ElementArg> args, rest;
      list<Absyn.NamedArg> res,restRes,argRes;
      Context context, c;
      list<String> arrows;
      Absyn.Exp x1,x2,y1,y2;
      Integer color1,color2,color3,x;
      String  val,val1,val2;
      Real thick;

    case({},_) then {} ;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "extent"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, expOption = SOME(Absyn.MATRIX(matrix = {{x1,y1},{x2,y2}} ))))) :: rest,context)

      equation

        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("extent",Absyn.ARRAY({Absyn.ARRAY({x1,y1}	),Absyn.ARRAY({x2,y2})})) :: restRes;//res;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "style"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args))) :: rest,context)

      equation

        restRes = transAnnLstToNamedArgs(rest,context);
        args = cleanStyleAttrs(args,{},context); //Styleregler

        argRes = transAnnLstToNamedArgs(args,context);
        res = listAppend(argRes,restRes);
      then res;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "color"), modification = SOME(Absyn.CLASSMOD(expOption = SOME(Absyn.INTEGER(value = x))))) :: rest, context as ("Text" :: c))

      equation

        (color1,color2,color3) = getMappedColor(x);
        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("fillColor", Absyn.ARRAY({Absyn.INTEGER(color1),Absyn.INTEGER(color2),Absyn.INTEGER(color3)})) :: restRes;//res;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "color"), modification = SOME(Absyn.CLASSMOD(expOption = SOME(Absyn.INTEGER(value = x))))) :: rest, context as ("Line" :: c))

      equation

        (color1,color2,color3) = getMappedColor(x);
        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("color", Absyn.ARRAY({Absyn.INTEGER(color1),Absyn.INTEGER(color2),Absyn.INTEGER(color3)})) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "color"), modification = SOME(Absyn.CLASSMOD(expOption = SOME(Absyn.INTEGER(value = x))))) :: rest, context )

      equation

        (color1,color2,color3) = getMappedColor(x);
        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("lineColor",Absyn.ARRAY({Absyn.INTEGER(color1),Absyn.INTEGER(color2),Absyn.INTEGER(color3)})) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "fillColor"), modification = SOME(Absyn.CLASSMOD(expOption =  SOME(Absyn.INTEGER(value = x))   ))) :: rest,context )

      equation

        (color1,color2,color3) = getMappedColor(x);
        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("fillColor", Absyn.ARRAY({Absyn.INTEGER(color1),Absyn.INTEGER(color2),Absyn.INTEGER(color3)})) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "pattern"), modification = SOME(Absyn.CLASSMOD(expOption =  SOME(Absyn.INTEGER(value = x))   ))) :: rest,context )

      equation

        val = arrayGet(listArray(patternMapList),x+1);
        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("pattern",Absyn.CREF(Absyn.CREF_QUAL("LinePattern", {},Absyn.CREF_IDENT(val, {})))) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "fillPattern"), modification = SOME(Absyn.CLASSMOD( expOption =  SOME(Absyn.INTEGER(value = x))   ))) :: rest,context )

      equation

        val = arrayGet(listArray(fillPatternMapList),x+1);
        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("fillPattern",Absyn.CREF(Absyn.CREF_QUAL("FillPattern", {},Absyn.CREF_IDENT(val, {})))) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "thickness"), modification = SOME(Absyn.CLASSMOD(expOption =  SOME(Absyn.INTEGER(value = x))   ))) :: rest,context as ("Line" :: c))

      equation

        thick = arrayGet(listArray(thicknessMapList),x);
        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("thickness",Absyn.REAL(thick)) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "thickness"), modification = SOME(Absyn.CLASSMOD(expOption =  SOME(Absyn.INTEGER(value = x))   ))) :: rest,context )

      equation

        thick = arrayGet(listArray(thicknessMapList),x);
        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("lineThickness",Absyn.REAL(thick)) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "gradient"), modification = SOME(Absyn.CLASSMOD(expOption = SOME(Absyn.INTEGER(value = x)) ))) :: rest,context)

      equation

        val = arrayGet(listArray(gradientMapList),x+1);
        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("fillPattern",Absyn.CREF(Absyn.CREF_QUAL("FillPattern", {},Absyn.CREF_IDENT(val, {}))))	:: restRes	;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "smooth"), modification = SOME(Absyn.CLASSMOD(expOption =  SOME(exp)   ))) :: rest,context)

      equation

        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("smooth",exp) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "arrow"), modification = SOME(Absyn.CLASSMOD(expOption =  SOME(Absyn.INTEGER(value = x))   ))) :: rest,context)

      equation

        arrows = arrayGet(listArray(arrowMapList),x+1);
        val1 = arrayGet(listArray(arrows),1);
        val2 = arrayGet(listArray(arrows),2);
        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("arrow",Absyn.ARRAY({Absyn.CREF(Absyn.CREF_QUAL("Arrow", {},Absyn.CREF_IDENT(val1, {}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT(val2,{})))})):: restRes		;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "textStyle"), modification = SOME(Absyn.CLASSMOD( expOption =  SOME(exp)   ))) :: rest,context as ("Text" :: c))

      equation

        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("textStyle",exp) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "font"), modification = SOME(Absyn.CLASSMOD(expOption =  SOME(exp)   ))) :: rest,context as ("Text" :: c))

      equation

        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("font",exp) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "string"), modification = SOME(Absyn.CLASSMOD(expOption =  SOME(exp)   ))) :: rest,context as ("Text" :: c))

      equation

        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("textString",exp) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "name"), modification = SOME(Absyn.CLASSMOD(expOption =  SOME(exp)   ))) :: rest,context as ("Bitmap" :: c))

      equation

        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("fileName",exp) :: restRes;

    case(Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "points"), modification = SOME(Absyn.CLASSMOD( expOption =  SOME(Absyn.MATRIX(matrix = expMatrix ))  ))) :: rest,context)

      equation

        expLst = Util.listMap(expMatrix,matrixToArray);
        restRes = transAnnLstToNamedArgs(rest,context);

      then Absyn.NAMEDARG("points",Absyn.ARRAY(expLst)) :: restRes;

    case(_ :: rest,context)

      equation

        res = transAnnLstToNamedArgs(rest,context);

      then res;

  end matchcontinue;

end transAnnLstToNamedArgs;


protected function cleanStyleAttrs "function: cleanStyleAttrs

	Helperfunction to the transform functions. The old style attribute and it's
	contents needs to be adjusted according to priorities before beeing transformed.
"

  input list<Absyn.ElementArg> inArgs;
  input list<Absyn.ElementArg > resultList;
  input Context inCon;
  output list<Absyn.ElementArg> outArgs;

algorithm

  outArgs := matchcontinue (inArgs,resultList,context)

    local

      list<Absyn.ElementArg> args,outList,rest,resultList;
      Absyn.ElementArg arg;
      Context context,c;
      Boolean fi;
      Absyn.Each e;
      Option<Absyn.Modification> m;
      Option<String> com;
      list<Absyn.Subscript> s;

    case({},resultList,_) then resultList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "color", subscripts = s), modification = m, comment = com)) :: rest, resultList,context	)

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "fillColor", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Rectangle"::c))

      equation
        //If fillColor is specified but not fillPattern or Gradient we need to insert a FillPattern
        false = isGradientInList(listAppend(rest,resultList));
        false = isFillPatternInList(listAppend(rest,resultList));
        resultList = insertFillPatternInList(resultList);
        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "fillColor", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Ellipse"::c))

      equation
        //If fillColor is specified but not fillPattern or Gradient we need to insert a FillPattern
        false = isGradientInList(listAppend(rest,resultList));
        false = isFillPatternInList(listAppend(rest,resultList));
        resultList = insertFillPatternInList(resultList);
        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "fillColor", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Polygon"::c))

      equation
        //If fillColor is specified but not fillPattern or Gradient we need to insert a FillPattern
        false = isGradientInList(listAppend(rest,resultList));
        false = isFillPatternInList(listAppend(rest,resultList));
        resultList = insertFillPatternInList(resultList);
        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "fillColor", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Rectangle"::c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "fillColor", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Ellipse"::c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "fillColor", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Polygon"::c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "pattern", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Rectangle" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "pattern", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Ellipse" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "pattern", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Polygon" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "pattern", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Line" :: c))

      equation


        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "fillPattern", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as("Rectangle" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "fillPattern", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as("Ellipse" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "fillPattern", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as("Polygon" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "thickness", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as("Bitmap" :: c))

      equation

        //Filter away, bitmaps can have no thickness.
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "thickness", subscripts = s), modification = m, comment = com)) :: rest, resultList,context)

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "gradient", subscripts = s), modification = SOME(Absyn.CLASSMOD(elementArgLst = args,expOption = SOME(Absyn.INTEGER(value = 0)))), comment = com)) :: rest, resultList,context)
      //Filter away
      equation
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "gradient", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Rectangle" :: c))

      equation

        rest = removeFillPatternInList(rest) /*If we have a old gradient any old fillPattern should be removed.*/;
        resultList = removeFillPatternInList(resultList) /*If we have a old gradient any old fillPattern should be removed.*/;
        rest = setDefaultLineInList(rest) /*If Gradient is set the line around the figure should be default*/;
        resultList = setDefaultLineInList(resultList) /*If Gradient is set the line around the figure should be default*/;
        (rest,resultList) = setDefaultFillColor(rest,resultList) /*If gradient is specificed but no fillColor, fillColor needs to be set to it's default dymola value.*/;
        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "gradient", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as ("Ellipse" :: c))

      equation

        rest = removeFillPatternInList(rest) /*If we have a old gradient any old fillPattern should be removed.*/;
        resultList = removeFillPatternInList(resultList) /*If we have a old gradient any old fillPattern should be removed.*/;
        rest = setDefaultLineInList(rest) /*If Gradient is set the line around the figure should be default*/;
        resultList = setDefaultLineInList(resultList) /*If Gradient is set the line around the figure should be default*/;
        (rest,resultList) = setDefaultFillColor(rest,resultList) /*If gradient is specificed but no fillColor, fillColor needs to be set to it's default dymola value.*/;


        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "smooth", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as("Polygon" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "smooth", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as("Line" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "arrow", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as("Line" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "textStyle", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as("Text" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

    case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "font", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as("Text" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

 /*   case((arg as Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "string", subscripts = s), modification = m, comment = com)) :: rest, resultList,context as("Text" :: c))

      equation

        resultList = Util.listAppendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

  */
    case(_ :: rest, resultList,context)

      equation
        //Filter away unwanted trash
        outList = cleanStyleAttrs(rest,resultList,context);

      then outList;

  end matchcontinue;

end cleanStyleAttrs;

protected function insertFillPatternInList "function insertFillPatternInList

	Helperfunction to cleanStyleAttrs. Inserts a fillPattern attribute in a list
	of annotations.
"

  input list<Absyn.ElementArg> inArgs;
  output list<Absyn.ElementArg> outArgs;

algorithm

  outArgs := matchcontinue inArgs

    local

      list<Absyn.ElementArg> lst;

    case(lst)

      equation

        lst = Absyn.MODIFICATION(false, Absyn.NON_EACH, Absyn.CREF_IDENT("fillPattern", {}), SOME(Absyn.CLASSMOD({},SOME(Absyn.INTEGER(1)))), NONE) :: lst;

      then lst;

  end matchcontinue;

end insertFillPatternInList;

protected function isGradientInList " function: isGradientInList

	Helperfunction to cleanStyle attrs. Returns true if a Gradient is found in a list
	of Absyn.ElementArg.
"

  input list<Absyn.ElementArg> inArgs;
  output Boolean result;

algorithm

  result := matchcontinue inArgs

    local

      list<Absyn.ElementArg> rest;
      Absyn.ElementArg arg;
      Boolean fi,res;
      Absyn.Each e;
      Option<Absyn.Modification> m;
      Option<String> com;
      list<Absyn.Subscript> s;

    case({}) then false;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "gradient", subscripts = s), modification = m, comment = com):: rest)

    then true;

    case(arg :: rest)

      equation

        res = isGradientInList(rest);

      then res;

  end matchcontinue	 ;

end isGradientInList;

protected function isFillPatternInList "function: isFillPatternInList

	Helperfunction to cleanStyleAttrs. Returns true if a fillPattern attribute is
	found in a list of Absyn.ElementArg.
"

  input list<Absyn.ElementArg> inArgs;
  output Boolean result;

algorithm

  result := matchcontinue inArgs

    local

      list<Absyn.ElementArg> rest;
      Absyn.ElementArg arg;
      Boolean fi,res;
      Absyn.Each e;
      Option<Absyn.Modification> m;
      Option<String> com;
      list<Absyn.Subscript> s;

    case({}) then false;

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "fillPattern", subscripts = s), modification = m, comment = com):: rest)

    then true;

    case(arg :: rest)

      equation

        res = isFillPatternInList(rest);

      then res;

  end matchcontinue;

end isFillPatternInList;

protected function removeFillPatternInList "function: removeFillPatternInList

	Helperfunction to cleanStyleAttrs. Removes a fillPattern attribute if present in a list
	of Absyn.ElementArg.
"
  input list<Absyn.ElementArg> inList;
  output list<Absyn.ElementArg> outList;

algorithm

  outList := matchcontinue inList

    local

      list<Absyn.ElementArg> rest,lst;
      Absyn.ElementArg arg;
      Boolean fi;
      Absyn.Each e;
      Absyn.ComponentRef cref;
      Option<Absyn.Modification> m;
      Option<String> com;
      list<Absyn.Subscript> s;

    case({}) then {};

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "fillPattern", subscripts = s), modification = m, comment = com) :: rest)

    then rest;

    case(arg::rest)

      equation

        lst = removeFillPatternInList(rest);

      then (arg::lst);

  end matchcontinue;

end removeFillPatternInList;

protected function setDefaultFillColor "function: setDefaultFillColor

	Helperfunction to cleanStyleAttrs. Sets a fillColor default value according to dymola
	standard. Used in case of gradient beeing specified but no fillColor.
"

  input list<Absyn.ElementArg> oldList;
  input list<Absyn.ElementArg> transformedList;

  output list<Absyn.ElementArg> oList;
  output list<Absyn.ElementArg> tList;

algorithm

  (oList,tList)	:= matchcontinue (oldList,transformedList)

    local

      list<Absyn.ElementArg> oLst,tLst;

    case(oLst,tLst)

      equation

        false = isFillColorInList(listAppend(oLst,tLst));
        tLst = Absyn.MODIFICATION(false,Absyn.NON_EACH,Absyn.CREF_IDENT("fillColor",{}), SOME(Absyn.CLASSMOD({},SOME(Absyn.INTEGER(3)))), NONE)::tLst;

      then (oLst,tLst);

    case(oLst,tLst)

    then (oLst,tLst);

  end matchcontinue;

end setDefaultFillColor;

protected function isFillColorInList "function: isFillColorInList

	Helperfunction to setDefaultFillColor. Returns true if a fillColor attribute is found
	in a list of Absyn.ElementArg.
"

  input list<Absyn.ElementArg> inList;
  output Boolean outBoolean;

algorithm

  outList := matchcontinue inList

    local

      list<Absyn.ElementArg> rest,lst,args;
      Absyn.ElementArg arg;

    case({})
    then false;

    case( Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "fillColor")):: rest)

    then true;

    case(arg::rest)

    then isFillColorInList(rest);

  end matchcontinue;

end isFillColorInList;


protected function setDefaultLineInList "function: setDefaultLineinList

	Helperfunction to cleanStyleAttrs. Sets the line annotation to defualt values.
"

  input list<Absyn.ElementArg> inList;
  output list<Absyn.ElementArg> outList;

algorithm

  outList := matchcontinue inList

    local

      list<Absyn.ElementArg> rest,lst,args;
      Absyn.ElementArg arg;
      Option<Absyn.Exp> ex;
      Boolean fi;
      Absyn.Each e;
      Absyn.ComponentRef cref;
      Option<Absyn.Modification> m;
      Option<String> com;
      list<Absyn.Subscript> s;

    case({}) then {};

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "thickness", subscripts = s), modification = SOME(Absyn.CLASSMOD(elementArgLst= args,expOption = ex)), comment = com) :: rest)

      equation

        lst = setDefaultLineInList(rest);

      then lst; //filtered

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "pattern", subscripts = s), modification = SOME(Absyn.CLASSMOD(elementArgLst= args,expOption = ex)), comment = com) :: rest)

      equation

        lst = setDefaultLineInList(rest);

      then lst; //filtered

    case(Absyn.MODIFICATION(finalItem = fi, each_ = e, componentReg = Absyn.CREF_IDENT(name = "color", subscripts = s), modification = SOME(Absyn.CLASSMOD(elementArgLst= args,expOption = ex)), comment = com) :: rest)

      equation

        lst = setDefaultLineInList(rest);

      then Absyn.MODIFICATION(fi, e, Absyn.CREF_IDENT("color", s), SOME(Absyn.CLASSMOD(args,SOME(Absyn.INTEGER(0)))), com) :: lst;

    case(arg::rest)

      equation

        lst = setDefaultLineInList(rest);

      then (arg::lst);

  end matchcontinue;

end setDefaultLineInList;

protected function getMappedColor "function: getMappedColor

	Helperfunction during the transformation. Takes a old color representation as input
	and returns the three RGB representations for that color.
"

  input Integer inColor "color to be mapped";
  output Integer color1;
  output Integer color2;
  output Integer color3;

algorithm

  (color1,color2,color3) := matchcontinue (inColor)

    local

      rgbColor rcol;
      Integer	color,color1,color2,color3;

    case(color)

      equation

        rcol = arrayGet(listArray(colorMapList),color+1);
        color1 = arrayGet(listArray(rcol),1);
        color2 = arrayGet(listArray(rcol),2);
        color3 = arrayGet(listArray(rcol),3);
      then
        (color1,color2,color3);

  end matchcontinue;

end getMappedColor;

protected function matrixToArray "function: matrixToArray
"

  input list<Absyn.Exp> inLst;
  output Absyn.Exp  outExp;

algorithm
  outExp := Absyn.ARRAY(inLst);

end matrixToArray;
/*
protected function getValueFromIntExp

  input Absyn.Exp intExpr;
  output Integer value;

algorithm

  value := matchcontinue(intExpr)

    local

      Integer val;

    case(Absyn.INTEGER(value = val))

    then val;

    case(Absyn.UNARY(exp = Absyn.INTEGER(value = val)))

    then (-val);

  end matchcontinue;

end getValueFromIntExp;

protected function getValueFromRealExp

  input Absyn.Exp realExpr;
  output Real value;

algorithm

  value := matchcontinue(realExpr)

    local

      Real val,val2;

    case(Absyn.REAL(value = val))

    then val;

    case(Absyn.UNARY(exp = Absyn.REAL(value = val)))

    then -.val;

  end matchcontinue;

end getValueFromRealExp;	*/
protected function getValueFromExp

  input Absyn.Exp expr;
  output Real value;

algorithm

  value := matchcontinue(expr)

    local

      Real realVal;
      Integer intVal;

    case(Absyn.REAL(value = realVal))

    then realVal;

    case(Absyn.UNARY(exp = Absyn.REAL(value = realVal)))

    then -.realVal;

    case(Absyn.INTEGER(value = intVal))

    then intReal(intVal);

    case(Absyn.UNARY(exp = Absyn.INTEGER(value = intVal)))

    then -.intReal(intVal);
  end matchcontinue;

end getValueFromExp;
protected function addContext "function: addContext
"

  input list<String> inList;
  input String newCon;

  output list<String> outList;

algorithm

  outList := matchcontinue(inList,newCon)

    local

      String str;
      list<String> strLst;

    case(strLst,str)
    then str :: strLst;

  end matchcontinue;

end addContext;

type Context = list<String>;

type rgbColor = list<Integer>;

type rgbColorMapList = list<rgbColor>;

constant rgbColorMapList colorMapList = {
  {0,0,0},{255,0,0},{0,255,0},{0,0,255},{0,255,255},{255,0,255},{255,255,0},{255,255,255},{192,192,192},{160,160,160},
  {128,128,128},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},
  {0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{235,235,235},{240,255,255},{0,0,0},
  {0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{255,0,0},{191,0,0},{255,127,127},
  {223,159,159},{255,127,0},{191,95,0},{255,191,127},{223,191,159},{255,255,0},{191,191,0},{255,255,127},
  {223,223,159},{127,255,0},{95,191,0},{191,255,127},{191,223,159},{0,255,0},{0,191,0},{127,255,127},
  {159,223,159},{0,255,127},{0,191,95},{127,255,191},{159,223,191},{0,255,255},{0,191,191},{127,255,255},
  {159,223,223},{0,127,255},{0,95,191},{127,191,255},{159,191,223},{0,0,255},{0,0,191},{127,127,255},
  {159,159,223},{127,0,255},{95,0,191},{191,127,255},{191,159,223},{255,0,255},{191,0,191},{255,127,255},
  {223,159,223},{255,0,127},{191,0,95},{255,127,191},{223,159,191}
    };

constant list<String> fillPatternMapList = {
  None,Solid,None,None,None,Horizontal,
  Vertical,Forward,Backward,Cross,CrossDiag
  };

constant list<String> gradientMapList = {
  None,VerticalCylinder,HorizontalCylinder,Sphere
  };
constant list<String> patternMapList = {
  None,Solid,Dash,Dot,DashDot,DashDotDot
  };
constant list<Real> thicknessMapList = {
  0.25,0.5,0.0,1.0
  };
constant list<list<String>> arrowMapList = {
  {None,None}, {None,Filled}, {Filled,None}, {Filled,Filled}, {None,Half}
    };

constant String None = "None";
constant String Solid = "Solid";
constant String Horizontal = "Horizontal";
constant String Vertical = "Vertical";
constant String Cross = "Cross";
constant String Forward = "Forward";
constant String Backward = "Backward";
constant String CrossDiag = "CrossDiag";

constant String HorizontalCylinder = "HorizontalCylinder";
constant String VerticalCylinder = "VerticalCylinder";
constant String Sphere = "Sphere";

constant String Dash = "Dash";
constant String Dot = "Dot";
constant String DashDot = "DashDot";
constant String DashDotDot = "DashDotDot";
constant String Filled = "Filled";
constant String  Half = "Half";

protected function fixPaths
"@author adrpo
 this function takes a path1: X.Y.Z.K.L and a path2: Z.U.M
 and returns a path X.Y.Z.U.M
"
  input Absyn.Path  inPath1;
  input Absyn.Path  inPath2;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue (inPath1, inPath2)
    local
      Absyn.Path ip1, ip2, p1, p2;
      String str1, str2;
      Absyn.Path out;
    case (ip1, ip2)
      equation
        str1 = Absyn.pathLastIdent(ip1);
        str2 = Absyn.pathFirstIdent(ip2);
        false = stringEqual(str1, str2);
        p1 = Absyn.stripLast(ip1);
        out = fixPaths(p1, ip2);
      then
        out;

    case (ip1, ip2)
      equation
        str1 = Absyn.pathLastIdent(ip1);
        str2 = Absyn.pathFirstIdent(ip2);
        true = stringEqual(str1, str2);
        p1 = Absyn.stripLast(ip1);
        out = Absyn.joinPaths(p1, ip2);
      then
        out;

    case (ip1, ip2) // if everything else fails, return ip2
      then
        ip2;

  end matchcontinue;
end fixPaths;
end Refactor;
