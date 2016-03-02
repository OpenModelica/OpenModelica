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

encapsulated package Refactor
" file:        Refactor.mo
  package:     Refactor
  description: Refactoring package


  This module contains functions for refactoring of Modelica/MetaModelica code.
  Right now there is support for old-style annotation refactoring to new-style
  annotations."


public import Absyn;
protected import List;
protected import Interactive;
protected import Inst;
protected import FCore;
protected import System; // stringReal

public function refactorGraphicalAnnotation "This function refactors the graphical annotations of a class to the modelica standard.
"
  input Absyn.Program wholeAST; //AST
  input Absyn.Class classToRefactor;
  output Absyn.Class changedClass; //Manipulerad AST
algorithm
  changedClass := match (wholeAST, classToRefactor)
    local
      Absyn.Class c;
    case(_, _)
      equation
        c = refactorGraphAnnInClass(classToRefactor,wholeAST,Absyn.IDENT(""));
      then
        c;

  end match;
end refactorGraphicalAnnotation;

protected function refactorGraphAnnInClass "Helper function to refactorGraphicalAnnotation. Part of the AST traverse.
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
      String n;
      Boolean part,f,e;
      Absyn.Restriction r;
      Absyn.ClassDef d;
      SourceInfo file_info;
      Absyn.Path cPath;
      FCore.Graph env;

    case (Absyn.CLASS(
      name = n,
      partialPrefix = part,
      finalPrefix = f,
      encapsulatedPrefix = e,
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
      partialPrefix = part,
      finalPrefix = f,
      encapsulatedPrefix = e,
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

protected function refactorGraphAnnInClassDef "Helper function to refactorGraphAnnInClass. Part of AST traverse.
"
  input Absyn.ClassDef inDef;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input FCore.Graph inClassEnv;
  output Absyn.ClassDef outDef;
algorithm
  outDef := matchcontinue (inDef,inProgram,classPath,inClassEnv)
    local
      Absyn.Program p;
      Absyn.ClassDef cd;
      list<Absyn.ClassPart> cp,resultPart;
      list<Absyn.Annotation> ann;
      Option<String> cmt;
      Absyn.ElementAttributes attrs;
      list<Absyn.ElementArg> args,annList,resAnnList;
      Absyn.TypeSpec ts;
      Absyn.Path cPath;
      FCore.Graph env;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;

    case(Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = cp, ann = ann, comment = cmt),p,cPath,env)
      equation
        resultPart = refactorGraphAnnInClassParts(cp,p,cPath,env);
      then
        Absyn.PARTS(typeVars,classAttrs,resultPart,ann,cmt);

    case(Absyn.DERIVED(typeSpec = ts, attributes = attrs,arguments = args, comment = SOME(Absyn.COMMENT(annotation_=SOME(Absyn.ANNOTATION(elementArgs = annList)),comment = cmt))),p,_,_)
      equation
        resAnnList = transformClassAnnList(annList,{"Class"},{},p);
      then
        Absyn.DERIVED(ts,attrs,args,SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(resAnnList)),cmt)));

    else inDef;

  end matchcontinue;

end refactorGraphAnnInClassDef;

protected function refactorGraphAnnInClassParts "Helper function to refactorGraphAnnInClassDef. Part of the AST traverse.
"
  input list<Absyn.ClassPart> inParts;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input FCore.Graph env;
  output list<Absyn.ClassPart> outParts;
algorithm
  outParts := match (inParts,inProgram,classPath,env)
    local
      Absyn.Program p;
      list<Absyn.ClassPart> restParts,resParts;
      Absyn.ClassPart firstPart,resultPart;
      Absyn.Path cPath;
    case({},_,_,_) then {};
    case(firstPart :: restParts ,p,cPath, _)
      equation
        resultPart = refactorGraphAnnInClassPart(firstPart,p,cPath,env);
        resParts = refactorGraphAnnInClassParts(restParts,p,cPath,env);
      then
        resultPart :: resParts;
  end match;
end refactorGraphAnnInClassParts;

protected function refactorGraphAnnInClassPart"Helper function to refactorGraphAnnInClassParts. Part of the AST traverse.
"
  input Absyn.ClassPart inPart;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input FCore.Graph inClassEnv;
  output Absyn.ClassPart outPart;

algorithm

  outPart := matchcontinue (inPart,inProgram,classPath,inClassEnv)

    local

      Absyn.Program p;
      list<Absyn.ElementItem> elContent,resultElContent;
      list<Absyn.EquationItem> eqContent,resultEqContent;
      list<Absyn.AlgorithmItem> algContent,resultAlgContent;
      Absyn.Path cPath;
      FCore.Graph env;

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

    else inPart;
  end matchcontinue;
end refactorGraphAnnInClassPart;


protected function refactorGraphAnnInContentList"Helper function to refactorGraphAnnInClassPart. Part of the AST traverse.
"
  input list<contentType> inList;
  input refactorGraphAnnInContent refactorGraphAnnInItem;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input FCore.Graph inClassEnv;
  output list<contentType> outList;
  public
  replaceable type contentType subtypeof Any;
  partial function refactorGraphAnnInContent
    input contentType inItem;
    input Absyn.Program inProgram;
    input Absyn.Path classPath;
    input FCore.Graph inClassEnv;
    output contentType outItem;
  end refactorGraphAnnInContent;
algorithm
  outList := match (inList,refactorGraphAnnInItem,inProgram,classPath,inClassEnv)
    local
      Absyn.Program p;
      list<contentType> restList,resList;
      contentType firstItem,resultItem;
      Absyn.Path cPath;
      FCore.Graph env;
    case({},_,_,_,_) then {};
    case(firstItem :: restList,_,p,cPath,env)
      equation
        resultItem = refactorGraphAnnInItem(firstItem,p,cPath,env);
        resList = refactorGraphAnnInContentList(restList,refactorGraphAnnInItem,p,cPath,env);
      then
        resultItem :: resList;
  end match;
end refactorGraphAnnInContentList;

protected function refactorGraphAnnInElItem"Helper function to refactorGraphAnnInClassPart. Part of the AST traverse.
"
  input Absyn.ElementItem inItem;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input FCore.Graph inClassEnv;
  output Absyn.ElementItem outItem;
algorithm
  outItem := match (inItem,inProgram,classPath,inClassEnv)
    local
      Absyn.Program p;
      Absyn.Element el,resultElement;
      list<Absyn.ElementArg> annList;
      Absyn.Path cPath;
      FCore.Graph env;

    case(Absyn.ELEMENTITEM(element = el) ,p,cPath,env)
      equation
        resultElement = refactorGraphAnnInElement(el,p,cPath,env);
      then
        Absyn.ELEMENTITEM(resultElement);
  end match;
end refactorGraphAnnInElItem;

protected function refactorGraphAnnInEqItem"Helper function to refactorGraphAnnInClassPart. Part of the AST traverse.
"
  input Absyn.EquationItem inItem;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input FCore.Graph inClassEnv;
  output Absyn.EquationItem outItem;

algorithm

  outItem := matchcontinue (inItem,inProgram,classPath,inClassEnv)

    local
      Absyn.Program p;
      Absyn.Equation e;
      Option<String> com;
      list<Absyn.ElementArg> annList;
      SourceInfo info;

    case(Absyn.EQUATIONITEM(equation_ = e, info = info, comment =
      SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(elementArgs = annList)),comment = com))),p,_,_)
      equation
        annList = transformConnectAnnList(annList,{"Connect"},{},p); //Connectannotation
      then
        Absyn.EQUATIONITEM(e,SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annList)),com)),info);
    else inItem;
  end matchcontinue;
end refactorGraphAnnInEqItem;

protected function refactorGraphAnnInAlgItem"Helper function to refactorGraphAnnInClassPart. Part of the AST traverse.
"
  input Absyn.AlgorithmItem inItem;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input FCore.Graph inClassEnv;
  output Absyn.AlgorithmItem outItem;
algorithm
  outItem := matchcontinue (inItem,inProgram,classPath,inClassEnv)
    local
      Absyn.Program p;
      Absyn.Algorithm alg;
      Option<String> com;
      list<Absyn.ElementArg> annList;
      SourceInfo info;
    case(Absyn.ALGORITHMITEM(algorithm_ = alg, info = info, comment =
      SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annList)),com))),_,_,_)
      equation
        //        a = transformGraphAnn(a,p); whut?

      then
        Absyn.ALGORITHMITEM(alg,SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annList)),com)),info);

    else inItem;

  end matchcontinue;

end refactorGraphAnnInAlgItem;

protected function refactorGraphAnnInElement"
  Helper function to refactorGraphAnnInElItem. Part of the AST traverse.

"
  input Absyn.Element inElement;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input FCore.Graph inClassEnv;
  output Absyn.Element outElement;

algorithm

  outElement := match (inElement,inProgram,classPath,inClassEnv)

    local

      Absyn.Program p;
      Boolean f;
      Option<Absyn.RedeclareKeywords> rdk;
      Absyn.InnerOuter io;
      Absyn.ElementSpec es,resultSpec;
      SourceInfo i;
      Option<Absyn.ConstrainClass> cc;
      Absyn.Path cPath;
      FCore.Graph env;

    case(Absyn.ELEMENT(finalPrefix = f, redeclareKeywords = rdk,
      innerOuter = io, specification = es, info = i, constrainClass = cc),p,cPath,env)

      equation

        cc = refactorConstrainClass(cc,p,cPath,env);
        resultSpec = refactorGraphAnnInElSpec(es,p,cPath,env);

      then
        Absyn.ELEMENT(f,rdk,io,resultSpec,i,cc);

  end match;

end refactorGraphAnnInElement;

protected function refactorConstrainClass "
  Helper function to refactorGraphAnnInElItem. Part of the AST traverse.

"
  input Option<Absyn.ConstrainClass> inCC;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input FCore.Graph inClassEnv;
  output Option<Absyn.ConstrainClass> outCC;

algorithm

  outCC := match (inCC,inProgram,classPath,inClassEnv)

  local
      Absyn.Program p;
      Absyn.ElementSpec es,resultSpec;
      Option<Absyn.Comment> com;
      Absyn.Path cPath;
      FCore.Graph env;
    case(SOME(Absyn.CONSTRAINCLASS(elementSpec = es, comment = com)),p,cPath,env)

      equation
       resultSpec = refactorGraphAnnInElSpec(es,p,cPath,env);

      then
        SOME(Absyn.CONSTRAINCLASS(resultSpec,com));
    case(NONE(),_,_,_)
    then NONE();
  end match;
end refactorConstrainClass;

protected function refactorGraphAnnInElSpec"
  Helper function to refactorGraphAnnInElement Part of the AST traverse.

"
  input Absyn.ElementSpec inSpec;
  input Absyn.Program inProgram;
  input Absyn.Path classPath;
  input FCore.Graph inClassEnv;
  output Absyn.ElementSpec outSpec;

algorithm

  outSpec := matchcontinue (inSpec,inProgram,classPath,inClassEnv)

    local

      Absyn.Program p;
      Absyn.ElementSpec e;
      Absyn.ElementAttributes at;
      Absyn.Path path,cPath;
      Absyn.ComponentItem firstComp,resultComp;
      list<Absyn.ComponentItem> restCompList,resCompList;
      Absyn.Class cl,cl1;
      Boolean r;
      FCore.Graph env;
      Option<Absyn.ArrayDim> z;

    case(Absyn.CLASSDEF(replaceable_ = r, class_ = cl),p,cPath,_)

      equation

        cl1 = refactorGraphAnnInClass(cl,p,cPath);

      then
        Absyn.CLASSDEF(r,cl1);

    case(Absyn.COMPONENTS(at,Absyn.TPATH(path,z),firstComp :: restCompList),p,cPath,env)
      equation
        resultComp = refactorGraphAnnInComponentItem(firstComp,cPath,path,p,env);
        Absyn.COMPONENTS(at,Absyn.TPATH(path,z),resCompList) =
          refactorGraphAnnInElSpec(Absyn.COMPONENTS(at,Absyn.TPATH(path,z),restCompList),p,cPath,env);
        //resultCompList = resultComp :: resCompList;

      then
        Absyn.COMPONENTS(at,Absyn.TPATH(path,z), resultComp :: resCompList); //resultCompList);

    else inSpec;

  end matchcontinue;

end refactorGraphAnnInElSpec;



protected function refactorGraphAnnInComponentItem"
  Helper function to refactorGraphAnnInElSpec Part of the AST traverse.

"
  input Absyn.ComponentItem inCom;
  input Absyn.Path classPath;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input FCore.Graph inClassEnv;
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
      FCore.Graph env;

    case(Absyn.COMPONENTITEM(component = comp, condition = con,
      comment = SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(elementArgs = annList)), comment = str))),
      cPath,path,p,env)
      equation
        annList = transformComponentAnnList(annList,{"Component"},{},cPath,path,p,env);

      then
        Absyn.COMPONENTITEM(comp,con,SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annList)),str))/*NONE*/);

    else inCom;

  end matchcontinue;

end refactorGraphAnnInComponentItem;


protected function transformComponentAnnList "
  This function transforms old component annotations to new ones
"

  input list<Absyn.ElementArg> inArgs;
  input Context inCon;
  input list<Absyn.ElementArg> resultList;
  input Absyn.Path classPath;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input FCore.Graph inClassEnv;
  output list<Absyn.ElementArg> outArgs;

algorithm

  outArgs := matchcontinue (inArgs,inCon,resultList,classPath,inPath,inProgram,inClassEnv)

    local
      Absyn.Program p;
      Absyn.Path path,cPath;
      Absyn.Exp x1,x2,y1,y2;
      list<Absyn.ElementArg> args,rest,res,trans;
      Absyn.ElementArg arg,iconTrans,diagramTrans;
      Context context, c;
      Boolean fi;
      Absyn.Each e;
      Option<String> com;
      Option<Real> rot;
      FCore.Graph env;
      SourceInfo info;


    case({},_,res,_,_,_,_) then res ;

    case(Absyn.MODIFICATION(
      finalPrefix = fi,
      eachPrefix = e,
      path =
        Absyn.IDENT(name = "extent"),
      modification =
        SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.MATRIX(matrix = {{x1,y1},{x2,y2}} )))),
      comment = com, info = info) :: rest,context as ("Component" :: _),res,cPath,path,p,env)
      equation
        Absyn.R_CONNECTOR() = getRestrictionFromPath(cPath,path,p,env)"Fails the case if we shouldn't have a iconTransformation";
        rot = getRotationDegree(listAppend(res,rest));
        iconTrans = getIconTransformation(x1,y1,x2,y2,rot,cPath,path,p,env);
        diagramTrans = getDiagramTransformation(x1,y1,x2,y2,rot,cPath,path,p,env);
        trans = {diagramTrans,iconTrans};
        res = transformComponentAnnList(rest,context,res,cPath,path,p,env);
        res = {Absyn.MODIFICATION(fi, e, Absyn.IDENT("Placement"), SOME(Absyn.CLASSMOD(trans,Absyn.NOMOD())),/*NONE,*/com, info)};//:: res; //SOME(Absyn.ARRAY({Absyn.ARRAY({x1,y1}  ),Absyn.ARRAY({x2,y2})}))
      then res;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "extent"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.MATRIX(matrix = {{x1,y1},{x2,y2}} )))), comment = com, info = info) :: rest,
      context as ("Component" :: _),res,cPath,path,p,env)
      equation
        rot = getRotationDegree(listAppend(res,rest));
        diagramTrans = getDiagramTransformation(x1,y1,x2,y2,rot,cPath,path,p,env);
        res = transformComponentAnnList(rest,context,res,cPath,path,p,env);
        res = {Absyn.MODIFICATION(fi, e, Absyn.IDENT("Placement"), SOME(Absyn.CLASSMOD({diagramTrans},Absyn.NOMOD()))/*NONE*/,com, info)};//:: res; /*SOME(Absyn.ARRAY({Absyn.ARRAY({x1,y1}  ),Absyn.ARRAY({x2,y2})}))*/
      then res;

    case(arg :: rest,context,res,cPath,path,p,env)
      equation
        res = arg :: res;
        res = transformComponentAnnList(rest,context,res,cPath,path,p,env);
      then res;
  end matchcontinue;

end transformComponentAnnList;

protected function getRestrictionFromPath"
  Helper function to transformComponentAnnList. This function takes a path and a program
  as arguments and then returns the class restriction to that path.
"
  input Absyn.Path classPath;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input FCore.Graph inClassEnv;
  output Absyn.Restriction outRestriction;
algorithm
  outRestriction := matchcontinue(classPath,inPath,inProgram, inClassEnv)
    local
      Absyn.Class cdef;
      Absyn.Program p;
      Absyn.Path fullPath,path,cPath;
      Absyn.Restriction restriction;
      FCore.Graph env;

    case(cPath,path,p, _) // try directly first
      equation
        fullPath = fixPaths(cPath, path);
       // debug_print("getRestrictionFromPath: TryingLookingUp:", Absyn.pathString(fullPath));
        cdef = Interactive.getPathedClassInProgram(fullPath,p);
        restriction = getRestrictionInClass(cdef);
      then
        restriction;

    case(_,path,p, env) // if it fails try the hard way
      equation
        (_,fullPath) = Inst.makeFullyQualified(FCore.emptyCache(),env,path);
    //    debug_print("getRestrictionFromPath: LookingUp:", Absyn.pathString(fullPath));
        cdef = Interactive.getPathedClassInProgram(fullPath,p);
        restriction = getRestrictionInClass(cdef);
      then
        restriction;

    else
      equation
//        debug_print("\ngetPathedClassInProgram:", "failed!");
      then fail();
  end matchcontinue;
end getRestrictionFromPath;

protected function getRestrictionInClass"
  Helper function to getRestrictionInPath. This function takes a class as
  argument and then returns the restriction to that class.
"

  input Absyn.Class inClass;
  output Absyn.Restriction outRestriction;
algorithm
  outRestriction := match(inClass)
    local
      Absyn.Restriction restriction;
    case(Absyn.CLASS(restriction = restriction)) then restriction;
  end match;
end getRestrictionInClass;

protected function getRotationDegree"
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

    case({}) then NONE();

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "rotation"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=ex)))) :: _)
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

protected function getIconTransformation"
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
  input FCore.Graph inClassEnv;
  output Absyn.ElementArg iconTrans;

algorithm

  iconTrans := match(ax1,ay1,ax2,ay2,inRotation,classPath,inPath,inProg,inClassEnv)

    local

      Real rcx1,rcy1,rcx2,rcy2,rax1,ray1,rax2,ray2,rot;
      Absyn.ElementArg scale,aspectRatio,x,y,flipHorizontal,flipVertical,rotation;
      Absyn.Path path,cPath;
      Absyn.Program p;
      Absyn.Exp x1,x2,y1,y2;
      FCore.Graph env;

    case(x1,y1,x2,y2,NONE(),cPath,path,p,env)
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
      then Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("iconTransformation"),SOME(Absyn.CLASSMOD({x,y,scale,aspectRatio,flipHorizontal,flipVertical},Absyn.NOMOD())),NONE(),Absyn.dummyInfo);

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
      then Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("iconTransformation"),SOME(Absyn.CLASSMOD({x,y,scale,aspectRatio,flipHorizontal,flipVertical,rotation},Absyn.NOMOD())),NONE(),Absyn.dummyInfo);

  end match;
end getIconTransformation;

protected function getDiagramTransformation"
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
  input FCore.Graph inClassEnv;
  output Absyn.ElementArg trans;

algorithm

  trans := match(ax1,ay1,ax2,ay2,inRotation,classPath,inPath,inProg, inClassEnv)

    local

      Real rcx1,rcy1,rcx2,rcy2,rax1,ray1,rax2,ray2,rot;
      Absyn.ElementArg scale,aspectRatio,x,y,flipHorizontal,flipVertical,rotation;
      Absyn.Path path,cPath;
      Absyn.Program p;
      Absyn.Exp x1,x2,y1,y2;
      FCore.Graph env;

    case(x1,y1,x2,y2,NONE(),cPath,path,p, env)

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

      then Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("transformation"),SOME(Absyn.CLASSMOD({x,y,scale,aspectRatio,flipHorizontal,flipVertical},Absyn.NOMOD())),NONE(),Absyn.dummyInfo);

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
        Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("transformation"),SOME(Absyn.CLASSMOD({x,y,scale,aspectRatio,flipHorizontal,flipVertical,rotation},Absyn.NOMOD())),NONE(),Absyn.dummyInfo);

  end match;
end getDiagramTransformation;

protected function getAspectRatioAnn"
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
  aspectRatio := match (x1,x2,y1,y2,cx1,cy1,cx2,cy2)
    local
      Real aspect,crx1,cry1,crx2,cry2,rx1,rx2,ry1,ry2;
      String s;

    case(rx1,rx2,ry1,ry2,crx1,cry1,crx2,cry2)
      equation
        aspect = (realAbs(ry2 - ry1) * (realAbs(cry2 - cry1))) / (realAbs(rx2 - rx1) * (realAbs(crx2 - crx1)));
        s = realString(aspect);
      then
      Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("aspectRatio"),SOME(Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.REAL(s),Absyn.dummyInfo))),NONE(),Absyn.dummyInfo);

  end match;
end getAspectRatioAnn;

protected function getXYAnn "
  Helper function to getIconTransformation and getDiagramTransformation. This function calculates and returns the X or Y
  annotation.
"
  input Real val1;
  input Real val2;
  input Absyn.Ident name;
  output Absyn.ElementArg res;
algorithm
  res := match(val1,val2,name)
    local
      Real x1,x2;
      Real value;
      Absyn.Ident n;
      String s;
    case(x1,x2,n)
      equation
        value = (x1 + x2) / 2.0;
        s = realString(value);
      then
        Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT(n),SOME(Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.REAL(s),Absyn.dummyInfo))),NONE(),Absyn.dummyInfo);
  end match;
end getXYAnn;

protected function getScaleAnn "
  Helper function to getIconTransformation and getDiagramTransformation. This function calculates and returns the scale
  annotation.
"
  input Real ax1;
  input Real ax2;
  input Real cx1;
  input Real cx2;
  output Absyn.ElementArg scale;
algorithm
  scale := match(ax1,ax2,cx1,cx2)
    local
      Real arx1,arx2,crx1,crx2,scaleFac;
      String s;
    case(arx1,arx2,crx1,crx2)
      equation
        scaleFac = (realAbs(arx1 - arx2)) / (realAbs(crx1 - crx2));
        s = realString(scaleFac);
      then
        Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("scale"),SOME(Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.REAL(s),Absyn.dummyInfo))),NONE(),Absyn.dummyInfo);

  end match;
end getScaleAnn;

protected function getFlipAnn"
  Helper function to getIconTransformation and getDiagramTransformation. This function calculates and returns the flip
  annotations.
"

  input Real val1;
  input Real val2;
  input Absyn.Ident name;
  output Absyn.ElementArg flip;
protected
  Boolean value;

algorithm

  value := val1 > val2;
  flip := Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT(name),SOME(Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.BOOL(value),Absyn.dummyInfo))),NONE(),Absyn.dummyInfo);

end getFlipAnn;

protected function getRotationAnn"Helper function to getIconTransformation and getDiagramTransformation.
  This function calculates and returns the rotation annotation."
  input Real rot;
  output Absyn.ElementArg rotation;
protected
  Real r;
  String s;
algorithm
  r := rot * (-1.0);
  s := realString(r);
  rotation := Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("rotation"),SOME(Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.REAL(s),Absyn.dummyInfo))),NONE(),Absyn.dummyInfo);
end getRotationAnn;


protected function getCoordsInPath"Helper function to transformComponentAnnList. This function takes a path and a program
  as arguments and then returns the diagram or icon coordinates in that path.
"
  input Absyn.Path classPath;
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Context contextToGetCoordsFrom;
  input FCore.Graph inClassEnv;
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
      Context context;


      FCore.Graph env;

    case(cPath,path,p,context, _) // try directly first
      equation
        fullPath = fixPaths(cPath, path);
//        debug_print("getCoordsInPath: TryingLookingUp:", Absyn.pathString(fullPath));
        cdef = Interactive.getPathedClassInProgram(fullPath,p);
        (x1,y1,x2,y2) = getCoordsInClass(cdef,context);
      then
       (x1,y1,x2,y2);

    case(_,path,p,context, env) // if it doesn't work, try the hard way
      equation
        //  p_1 = SCodeUtil.translateAbsyn2SCode(p);
        //  (_,env) = Inst.makeEnvFromProgram(FCore.emptyCache,p_1, Absyn.IDENT(""));
        (_,fullPath) = Inst.makeFullyQualified(FCore.emptyCache(),env,path);
        //  print("env:\n");print(FGraph.printGraphStr(env));
        //str = Absyn.pathString(cPath);
        //print("\npath = ");
        //print(str);
    //    debug_print("getCoordsInPath: LookingUp:", Absyn.pathString(fullPath));
        cdef = Interactive.getPathedClassInProgram(fullPath,p);
        (x1,y1,x2,y2) = getCoordsInClass(cdef,context);
      then
        (x1,y1,x2,y2);//(Absyn.REAL(-100.0),Absyn.REAL(-100.0),Absyn.REAL(100.0),Absyn.REAL(100.0));

    else // if it doesn't work, try the hard way
      equation
  //     debug_print("\ngetPathedClassInProgram:", "failed!");
      then fail();

  end matchcontinue;

end getCoordsInPath;

protected function getCoordsInClass "
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
  (x1,y1,x2,y2) := match (inClass,contextToGetCoordsFrom)
    local
      list<Absyn.Annotation> ann;
      list<Absyn.ElementArg> annlst;
      Context context;

    case(Absyn.CLASS(body = Absyn.PARTS(ann = ann)),context)
      equation
        annlst = List.flatten(List.map(ann,Absyn.annotationToElementArgs));
        (x1,y1,x2,y2) = getCoordsInAnnList(annlst,context);
      then
        (x1,y1,x2,y2);

    case(Absyn.CLASS(body = Absyn.DERIVED(comment =  SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(elementArgs = annlst)))))),context)
        equation
          (x1,y1,x2,y2) = getCoordsInAnnList(annlst,context);
      then
        (x1,y1,x2,y2);

  end match;
end getCoordsInClass;

protected function getCoordsInAnnList"
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
      list<Absyn.ElementArg> rest,args;
      Context context;

    case({},_) then (Absyn.REAL("-100.0"),Absyn.REAL("-100.0"),Absyn.REAL("100.0"),Absyn.REAL("100.0"))/*If coordsys is not explicit defined, old implicit standard is [-100,-100;100,100]*/;
    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "Coordsys"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args)))::_,_)
      equation
        (x1,y1,x2,y2) = getCoordsFromCoordSysArgs(args);
      then
        (x1,y1,x2,y2);

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "Icon"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args)))::_,"Icon" :: _)
      equation
        (x1,y1,x2,y2) = getCoordsFromLayerArgs(args);
      then
        (x1,y1,x2,y2);

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "Diagram"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args)))::_,"Diagram" :: _)
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

protected function getCoordsFromCoordSysArgs"
  Helper function to getCoordsInAnnList.
"
  input list<Absyn.ElementArg> inAnns;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;
algorithm
  (x1,y1,x2,y2) := match(inAnns)
    local
      list<Absyn.ElementArg> rest;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "extent"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.MATRIX(matrix = {{x1,y1},{x2,y2}} ))))) :: _)
    then
      (x1,y1,x2,y2);

    case(_ :: rest)
      equation
        (x1,y1,x2,y2) = getCoordsFromCoordSysArgs(rest);
      then
        (x1,y1,x2,y2);

  end match;
end getCoordsFromCoordSysArgs;

protected function getExtentModification
  input list<Absyn.ElementArg> elementArgLst;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;
algorithm
  (x1,y1,x2,y2) := match (elementArgLst)
    local list<Absyn.ElementArg> rest;
    case (Absyn.MODIFICATION(
      path = Absyn.IDENT(name = "extent"),
      modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.ARRAY({Absyn.ARRAY({x1,y1}  ),Absyn.ARRAY({x2,y2})}))) )):: _)
      equation
      then (x1,y1,x2,y2);

    case (_:: rest)
      equation
        (x1,y1,x2,y2) = getExtentModification(rest);
      then (x1,y1,x2,y2);
  end match;
end getExtentModification;

protected function getCoordsFromLayerArgs
"Helper function to getCoordsInAnnList."
  input list<Absyn.ElementArg> inAnns;
  output Absyn.Exp x1;
  output Absyn.Exp y1;
  output Absyn.Exp x2;
  output Absyn.Exp y2;
algorithm
  (x1,y1,x2,y2) := matchcontinue(inAnns)
    local
      list<Absyn.ElementArg> rest,args;

    case (Absyn.MODIFICATION(path = Absyn.IDENT(name = "coordinateSystem"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args)))::_)
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

protected function transformConnectAnnList "
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
      Integer x,color1,color2,color3;
      String val,val1,val2,s;
      list<String> arrows;
      Real thick;
      list<Absyn.ElementArg> args,rest,res;
      Absyn.ElementArg arg;
      Context context, c;
      Boolean fi;
      Absyn.Each e;
      Option<String> com;
      Absyn.EqMod eqMod;
      SourceInfo info, mod_info;

    case({},_,res,_) then res ;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "points"), modification = SOME(Absyn.CLASSMOD( eqMod = Absyn.EQMOD(Absyn.MATRIX(matrix = expMatrix),info)  )), comment = com, info = mod_info) :: rest,context as ("Connect" :: _),res,p)
      equation
        context = addContext(context,"Line");
        expLst = List.map(expMatrix,matrixToArray);
        res = transformConnectAnnList(rest,context,res,p);
      then {Absyn.MODIFICATION(fi,e,Absyn.IDENT("Line"), SOME(Absyn.CLASSMOD(Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("points"),SOME(Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.ARRAY(expLst),info))),NONE(),mod_info) :: res,Absyn.NOMOD())),com,mod_info)};//res;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "points"), modification = SOME(Absyn.CLASSMOD( eqMod = Absyn.EQMOD(Absyn.MATRIX(matrix = expMatrix),info)  )), comment = com, info = mod_info) :: rest,context as ("Line" :: _),res,p)
      equation
        expLst = List.map(expMatrix,matrixToArray);
        res = transformConnectAnnList(rest,context,res,p);
      then Absyn.MODIFICATION(fi,e,Absyn.IDENT("points"),SOME(Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.ARRAY(expLst),info))),com,mod_info) :: res; //res;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "style"), modification = SOME(Absyn.CLASSMOD( elementArgLst = args , eqMod = eqMod)), comment = com, info = mod_info) :: rest,context as ("Connect" :: _),res,p)
      equation
        context = addContext(context,"Line");
        args = cleanStyleAttrs(args,{},context);
        rest = listAppend(args,rest);
        res = transformConnectAnnList(rest,context,res,p);
      then {Absyn.MODIFICATION(fi,e,Absyn.IDENT("Line"),SOME(Absyn.CLASSMOD(res,eqMod)),com,mod_info)};

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "style"), modification = SOME(Absyn.CLASSMOD( elementArgLst = args))) :: rest,context as ("Line" :: _),res,p)
      equation
        args = cleanStyleAttrs(args,{},context);
        rest = listAppend(args,rest);
        res = transformConnectAnnList(rest,context,res,p);
      then res;


    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "color"), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,eqMod = Absyn.EQMOD(Absyn.INTEGER(value = x),info))), comment = com, info = mod_info) :: rest,context as ("Line" :: _),res,p)
      equation
        (color1,color2,color3) = getMappedColor(x);
        res = transformConnectAnnList(rest,context,res,p);
      then Absyn.MODIFICATION(fi,e,Absyn.IDENT("color"), SOME(Absyn.CLASSMOD(args,Absyn.EQMOD(Absyn.ARRAY({Absyn.INTEGER(color1),Absyn.INTEGER(color2),Absyn.INTEGER(color3)}),info))),com,mod_info):: res;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "pattern"), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x)))), comment = com, info = mod_info) :: rest,context as ("Line" :: _),res,p)
      equation
        val = arrayGet(listArray(patternMapList),x+1);
        res = transformConnectAnnList(rest,context,res,p);
      then Absyn.MODIFICATION(fi,e,Absyn.IDENT("pattern"), SOME(Absyn.CLASSMOD(args,Absyn.EQMOD(Absyn.CREF(Absyn.CREF_QUAL("LinePattern", {},Absyn.CREF_IDENT(val, {}))),Absyn.dummyInfo))),com, mod_info):: res;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "thickness"), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x)))), comment = com, info = mod_info) :: rest,context as ("Line" :: _),res,p)
      equation
        thick = arrayGet(listArray(thicknessMapList),x);
        res = transformConnectAnnList(rest,context,res,p);
        s = realString(thick);
      then Absyn.MODIFICATION(fi,e,Absyn.IDENT("thickness"), SOME(Absyn.CLASSMOD(args,Absyn.EQMOD(Absyn.REAL(s),Absyn.dummyInfo))),com,mod_info):: res;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "smooth"), modification = SOME(Absyn.CLASSMOD( elementArgLst = args , eqMod = eqMod)), comment = com, info = mod_info) :: rest,context as ("Line" :: _),res,p)
      equation
        res = transformConnectAnnList(rest,context,res,p); then Absyn.MODIFICATION(fi,e,Absyn.IDENT("smooth"), SOME(Absyn.CLASSMOD(args,eqMod)),com, mod_info):: res;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "arrow"), modification = SOME(Absyn.CLASSMOD( elementArgLst = args ,eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x)))), comment = com, info = mod_info) :: rest,context as ("Line" :: _),res,p)
      equation
        arrows = arrayGet(listArray(arrowMapList),x+1);
        val1 = arrayGet(listArray(arrows),1);
        val2 = arrayGet(listArray(arrows),2);
        res = transformConnectAnnList(rest,context,res,p);
      then Absyn.MODIFICATION(fi,e,Absyn.IDENT("arrow"), SOME(Absyn.CLASSMOD(args,Absyn.EQMOD(Absyn.ARRAY({Absyn.CREF(Absyn.CREF_QUAL("Arrow", {},Absyn.CREF_IDENT(val1, {}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT(val2,{})))}),Absyn.dummyInfo))),com, mod_info):: res;

    case(arg :: rest,context,res,p)
      equation
        res = transformConnectAnnList(rest,context,res,p);
      then arg :: res;

  end matchcontinue;
end transformConnectAnnList;

protected function transformClassAnnList "
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
      Absyn.EqMod eqMod;
      SourceInfo info, mod_info;

    case({},_,res,_) then res ;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "Icon"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, eqMod = eqMod)), comment = com, info = mod_info) :: rest,context as ("Class" :: c),res,p)
      equation
        c = addContext(context,"Layer");
        argRes = transAnnLstToCalls(args,c);
        coord = getCoordSysAnn(listAppend(res,rest),p);
        res = transformClassAnnList(rest,context,res,p);
      then Absyn.MODIFICATION(fi, e, Absyn.IDENT("Icon"), SOME(Absyn.CLASSMOD({coord,Absyn.MODIFICATION(false, Absyn.NON_EACH(), Absyn.IDENT("graphics"),SOME(Absyn.CLASSMOD({}, Absyn.EQMOD(Absyn.ARRAY(argRes),Absyn.dummyInfo)   )),NONE(),mod_info)}, eqMod)),com,mod_info) :: res    ;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "Diagram"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, eqMod = eqMod)), comment = com, info = mod_info) :: rest,context as ("Class" :: c),res,p)
      equation
        c = addContext(context,"Layer");
        argRes = transAnnLstToCalls(args,c);
        coord = getCoordSysAnn(listAppend(res,rest),p);
        res = transformClassAnnList(rest,context,res,p);
      then Absyn.MODIFICATION(fi, e, Absyn.IDENT("Diagram"), SOME(Absyn.CLASSMOD({coord,Absyn.MODIFICATION(false, Absyn.NON_EACH(), Absyn.IDENT("graphics"),SOME(Absyn.CLASSMOD({}, Absyn.EQMOD(Absyn.ARRAY(argRes),Absyn.dummyInfo)   )),NONE(),mod_info)}, eqMod)),com,mod_info) :: res;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "Coordsys"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, eqMod = eqMod)), comment = com, info = mod_info) :: rest,context,res,p)
      equation
        true = isLayerAnnInList(listAppend(res,rest))/*Fails the case if we have a coordsys without a layer definition*/;
        res = Absyn.MODIFICATION(fi, e, Absyn.IDENT("Coordsys"), SOME(Absyn.CLASSMOD(args, eqMod)),com,mod_info) :: res;
        res = transformClassAnnList(rest,context,res,p);
      then List.deleteMember(res,Absyn.MODIFICATION(fi, e, Absyn.IDENT("Coordsys"), SOME(Absyn.CLASSMOD(args, eqMod)),com,mod_info));

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "Coordsys"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, eqMod = eqMod)), comment = com, info = mod_info) :: rest,context,res,p)
      equation
        res = Absyn.MODIFICATION(fi, e, Absyn.IDENT("Coordsys"), SOME(Absyn.CLASSMOD(args, eqMod)),com,mod_info) :: res;
        coord = getCoordSysAnn(listAppend(res,rest),p);
        res = listAppend({Absyn.MODIFICATION(false, Absyn.NON_EACH(),
        Absyn.IDENT("Diagram"),
        SOME(Absyn.CLASSMOD({coord},Absyn.NOMOD())),NONE(),mod_info),Absyn.MODIFICATION(false, Absyn.NON_EACH(), Absyn.IDENT("Icon"), SOME(Absyn.CLASSMOD({coord},Absyn.NOMOD())),NONE(),mod_info)},res);
        res = transformClassAnnList(rest,context,res,p);
      then List.deleteMember(res,Absyn.MODIFICATION(fi, e, Absyn.IDENT("Coordsys"), SOME(Absyn.CLASSMOD(args, eqMod)),com,mod_info));

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "extent"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, eqMod = Absyn.EQMOD(Absyn.MATRIX(matrix = {{x1,y1},{x2,y2}} ),info))), comment = com, info = mod_info) :: rest,context as ("Coordsys" :: _),res,p)
      equation
        res = Absyn.MODIFICATION(fi, e, Absyn.IDENT("extent"), SOME(Absyn.CLASSMOD(args, Absyn.EQMOD(Absyn.ARRAY({Absyn.ARRAY({x1,y1}),Absyn.ARRAY({x2,y2})}),info))),com,mod_info) :: res;
        res = transformClassAnnList(rest,context,res,p);
      then res;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "grid")) :: rest,context ,res,p)
      equation
        res = transformClassAnnList(rest,context,res,p);
      then res;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "component")) :: rest,context ,res,p)
      equation
        res = transformClassAnnList(rest,context,res,p);
      then res;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "Window")) :: rest,context ,res,p)
      equation
        res = transformClassAnnList(rest,context,res,p);
      then res;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "Terminal")) :: rest,context ,res,p)
      equation
        res = transformClassAnnList(rest,context,res,p);
      then res;

    case(arg :: rest,context,res,p)
      equation
        res = transformClassAnnList(rest,context,res,p);
      then arg :: res;
  end matchcontinue;
end transformClassAnnList;

protected function isLayerAnnInList"
  Helper function to transformClassAnnList. Returns true if a icon or diagram annotation
  is in the list, false otherwise.
"
  input list<Absyn.ElementArg> inList;
  output Boolean result;
algorithm
  result := match(inList)
    local
      list<Absyn.ElementArg> rest;
      Boolean res;

    case({}) then false;
    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "Diagram")) :: _)
    then
      true;
    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "Icon")) :: _)
    then
      true;
    case(_ :: rest)
      equation
        res = isLayerAnnInList(rest);
      then
        res;
  end match;
end isLayerAnnInList;

protected function  getCoordSysAnn "
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
      Absyn.EqMod eqMod;
      SourceInfo info;

    case ({},_)
    then
      Absyn.MODIFICATION(false, Absyn.NON_EACH(), Absyn.IDENT("coordinateSystem"), SOME(Absyn.CLASSMOD({Absyn.MODIFICATION(false, Absyn.NON_EACH(), Absyn.IDENT("extent"), SOME(Absyn.CLASSMOD({},
      Absyn.EQMOD(Absyn.ARRAY({Absyn.ARRAY({Absyn.INTEGER(-100),Absyn.INTEGER(-100)}),Absyn.ARRAY({Absyn.INTEGER(100),Absyn.INTEGER(100)})}),Absyn.dummyInfo))),
      NONE(),Absyn.dummyInfo)},Absyn.NOMOD())),NONE(),Absyn.dummyInfo)/*Create default*/;

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "Coordsys"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args, eqMod = eqMod)), comment = com, info = info) :: _,p)
      equation
        args = transformClassAnnList(args,"Coordsys"::{},{},p);
      then
        Absyn.MODIFICATION(fi, e, Absyn.IDENT("coordinateSystem"), SOME(Absyn.CLASSMOD(args, eqMod)), com, info);

    case(_ :: rest,p)
      equation
        res = getCoordSysAnn(rest,p);
      then res;
  end matchcontinue;
end getCoordSysAnn;


protected function transAnnLstToCalls "
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

      /* Special case for Line, need to add default color={0,0,255} if no color given */
    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "Line"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args))) :: rest,context as ("Layer" :: c))

      equation
        c = addContext(context,"Line");
        argRes = transAnnLstToNamedArgs(args,c);
        {} = List.select1(argRes,nameArgWithName, "color");
        restRes = transAnnLstToCalls(rest,context);
      then
        Absyn.CALL(Absyn.CREF_IDENT("Line",{}), Absyn.FUNCTIONARGS({},
        Absyn.NAMEDARG("color",Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(255)}))::argRes)) :: restRes;

      /* Special case for Rectangle Ellipse, Polygon, Text, need to add default lineColor={0,0,255} if no color given */
    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = n), modification = SOME(Absyn.CLASSMOD(elementArgLst = args))) :: rest,context as ("Layer" :: c))

      equation
        c = addContext(context,n);
        true = isLinebasedGraphic(c);
        argRes = transAnnLstToNamedArgs(args,c);
        {} = List.select1(argRes,nameArgWithName, "lineColor");
        restRes = transAnnLstToCalls(rest,context);
      then
        Absyn.CALL(Absyn.CREF_IDENT(n,{}), Absyn.FUNCTIONARGS({},
        Absyn.NAMEDARG("lineColor",Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(255)}))::argRes)) :: restRes;


    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = n), modification = SOME(Absyn.CLASSMOD(elementArgLst = args))) :: rest,context as ("Layer" :: c))

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

protected function nameArgWithName
  input Absyn.NamedArg narg;
  input String argName;
  output Boolean res;
algorithm
  res := match(narg,argName)
  local String name;
    case(Absyn.NAMEDARG(name,_),_) equation
      res = (name == argName);
    then res;
  end match;
end nameArgWithName;

protected function transAnnLstToNamedArgs "
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
      String  val,val1,val2,s;
      Real thick;

    case({},_) then {} ;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "extent"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.MATRIX(matrix = {{x1,y1},{x2,y2}} ))))) :: rest,context)
      equation
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("extent",Absyn.ARRAY({Absyn.ARRAY({x1,y1}  ),Absyn.ARRAY({x2,y2})})) :: restRes;//res;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "style"), modification = SOME(Absyn.CLASSMOD(elementArgLst = args))) :: rest,context)
      equation
        restRes = transAnnLstToNamedArgs(rest,context);
        args = cleanStyleAttrs(args,{},context); //Styleregler
        argRes = transAnnLstToNamedArgs(args,context);
        res = listAppend(argRes,restRes);
      then res;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "color"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x))))) :: rest, context as ("Text" :: _))
      equation
        (color1,color2,color3) = getMappedColor(x);
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("fillColor", Absyn.ARRAY({Absyn.INTEGER(color1),Absyn.INTEGER(color2),Absyn.INTEGER(color3)})) :: restRes;//res;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "color"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x))))) :: rest, context as ("Line" :: _))
      equation
        (color1,color2,color3) = getMappedColor(x);
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("color", Absyn.ARRAY({Absyn.INTEGER(color1),Absyn.INTEGER(color2),Absyn.INTEGER(color3)})) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "color"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x))))) :: rest, context )
      equation
        (color1,color2,color3) = getMappedColor(x);
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("lineColor",Absyn.ARRAY({Absyn.INTEGER(color1),Absyn.INTEGER(color2),Absyn.INTEGER(color3)})) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillColor"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x))   ))) :: rest,context )
      equation
        (color1,color2,color3) = getMappedColor(x);
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("fillColor", Absyn.ARRAY({Absyn.INTEGER(color1),Absyn.INTEGER(color2),Absyn.INTEGER(color3)})) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "pattern"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x))   ))) :: rest,context )
      equation
        val = arrayGet(listArray(patternMapList),x+1);
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("pattern",Absyn.CREF(Absyn.CREF_QUAL("LinePattern", {},Absyn.CREF_IDENT(val, {})))) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillPattern"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x))   ))) :: rest,context )
      equation
        val = arrayGet(listArray(fillPatternMapList),x+1);
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("fillPattern",Absyn.CREF(Absyn.CREF_QUAL("FillPattern", {},Absyn.CREF_IDENT(val, {})))) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "thickness"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x))   ))) :: rest,context as ("Line" :: _))
      equation
        thick = arrayGet(listArray(thicknessMapList),x);
        restRes = transAnnLstToNamedArgs(rest,context);
        s = realString(thick);
      then Absyn.NAMEDARG("thickness",Absyn.REAL(s)) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "thickness"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x))   ))) :: rest,context )
      equation
        thick = arrayGet(listArray(thicknessMapList),x);
        restRes = transAnnLstToNamedArgs(rest,context);
        s = realString(thick);
      then Absyn.NAMEDARG("lineThickness",Absyn.REAL(s)) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "gradient"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x)) ))) :: rest,context)
      equation
        val = arrayGet(listArray(gradientMapList),x+1);
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("fillPattern",Absyn.CREF(Absyn.CREF_QUAL("FillPattern", {},Absyn.CREF_IDENT(val, {}))))  :: restRes  ;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "smooth"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=exp)))) :: rest,context)
      equation
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("smooth",exp) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "arrow"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = x))   ))) :: rest,context)
      equation
        arrows = arrayGet(listArray(arrowMapList),x+1);
        val1 = arrayGet(listArray(arrows),1);
        val2 = arrayGet(listArray(arrows),2);
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("arrow",Absyn.ARRAY({Absyn.CREF(Absyn.CREF_QUAL("Arrow", {},Absyn.CREF_IDENT(val1, {}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT(val2,{})))})):: restRes    ;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "textStyle"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=exp)   ))) :: rest,context as ("Text" :: _))
      equation
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("textStyle",exp) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "font"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=exp)))) :: rest,context as ("Text" :: _))
      equation
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("font",exp) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "string"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=exp)))) :: rest,context as ("Text" :: _))
      equation
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("textString",exp) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "name"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=exp)))) :: rest,context as ("Bitmap" :: _))
      equation
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("fileName",exp) :: restRes;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "points"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.MATRIX(matrix = expMatrix ))  ))) :: rest,context)
      equation
        expLst = List.map(expMatrix,matrixToArray);
        restRes = transAnnLstToNamedArgs(rest,context);
      then Absyn.NAMEDARG("points",Absyn.ARRAY(expLst)) :: restRes;

    case(_ :: rest,context)
      equation
        res = transAnnLstToNamedArgs(rest,context);
      then res;
  end matchcontinue;
end transAnnLstToNamedArgs;

protected function cleanStyleAttrs "
  Helperfunction to the transform functions. The old style attribute and it's
  contents needs to be adjusted according to priorities before beeing transformed.
  See also cleanStyleAttrs2.
"

  input list<Absyn.ElementArg> inArgs;
  input list<Absyn.ElementArg > resultList;
  input Context inCon;
  output list<Absyn.ElementArg> outArgs;

algorithm
  outArgs := matchcontinue(inArgs,resultList,inCon)
    local Context context;

      /* If is Rectangle, Ellipse, Polygon or Text and no color attribute, set default to lineColor={0,0,255} */
    case(_,_, context)
      equation
        true = isLinebasedGraphic(context);
        {} = List.select(inArgs,isLineColorModifier);
        outArgs = cleanStyleAttrs2(Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("lineColor"),
        SOME(Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(255)}),Absyn.dummyInfo))),NONE(),Absyn.dummyInfo)::inArgs,resultList,context);
      then outArgs;

      /* If is Line and no color attribute, set default to color={0,0,255} */
    case(_,_, context)
      equation
        true = isLineGraphic(context);
        {} = List.select(inArgs,isLineColorModifier);
        outArgs = cleanStyleAttrs2(Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("color"),
        SOME(Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(255)}),Absyn.dummyInfo))),NONE(),Absyn.dummyInfo)::inArgs,resultList,context);
      then outArgs;

    else
      equation
        outArgs = cleanStyleAttrs2(inArgs,resultList,inCon);
      then outArgs;
  end matchcontinue;
end cleanStyleAttrs;

protected function isLineColorModifier
  input Absyn.ElementArg arg;
  output Boolean res;
algorithm
  res := match(arg)
    case(Absyn.MODIFICATION(path = Absyn.IDENT("color"),
        modification = SOME(Absyn.CLASSMOD(_,_))))
      then true;
    else false;
  end match;
end isLineColorModifier;

protected function isStyleModifier
  input Absyn.ElementArg arg;
  output Boolean res;
algorithm
  res := match(arg)
    case(Absyn.MODIFICATION(path = Absyn.IDENT("style"))) then true;
    else false;
  end match;
end isStyleModifier;

protected function isLinebasedGraphic "Returns true if context string is a line based graphic"
  input Context context;
  output Boolean res;
algorithm
  res := match(context)
    case("Rectangle"::_) then true;
    case("Ellipse"::_) then true;
    case("Polygon"::_) then true;
    case("Text"::_) then true;
    else false;
  end match;
end isLinebasedGraphic;

protected function isLineGraphic "Returns true if context string is a Line"
  input Context context;
  output Boolean res;
algorithm
  res := match(context)
    case("Line"::_) then true;
    else false;
  end match;
end isLineGraphic;


protected function cleanStyleAttrs2 "
  Helperfunction to the transform functions. The old style attribute and it's
  contents needs to be adjusted according to priorities before beeing transformed."
  input list<Absyn.ElementArg> inArgs;
  input list<Absyn.ElementArg> inResultList;
  input Context inCon;
  output list<Absyn.ElementArg> outArgs;
algorithm
  outArgs := match (inArgs,inResultList,inCon)
    local
      list<Absyn.ElementArg> args,outList,rest;
      Absyn.ElementArg arg;
      Context context,c;
      Boolean fi;
      Absyn.Each e;
      Option<Absyn.Modification> m;
      Option<String> com;
      list<Absyn.ElementArg> resultList;

    case({},resultList,_) then resultList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "color"))) :: rest, resultList,context  )
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillColor"))) :: rest, resultList,context as ("Rectangle"::_))
      guard
        //If fillColor is specified but not fillPattern or Gradient we need to insert a FillPattern
        not isGradientInList(listAppend(rest,resultList)) and
        not isFillPatternInList(listAppend(rest,resultList))
      equation
        resultList = insertFillPatternInList(resultList);
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillColor"))) :: rest, resultList,context as ("Ellipse"::_))
      guard
        //If fillColor is specified but not fillPattern or Gradient we need to insert a FillPattern
        not isGradientInList(listAppend(rest,resultList)) and
        not isFillPatternInList(listAppend(rest,resultList))
      equation
        resultList = insertFillPatternInList(resultList);
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillColor"))) :: rest, resultList,context as ("Polygon"::_))

      guard
        //If fillColor is specified but not fillPattern or Gradient we need to insert a FillPattern
        not isGradientInList(listAppend(rest,resultList)) and
        not isFillPatternInList(listAppend(rest,resultList))
      equation
        resultList = insertFillPatternInList(resultList);
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillColor"))) :: rest, resultList,context as ("Rectangle"::_))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillColor"))) :: rest, resultList,context as ("Ellipse"::_))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillColor"))) :: rest, resultList,context as ("Polygon"::_))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "pattern"))) :: rest, resultList,context as ("Rectangle" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "pattern"))) :: rest, resultList,context as ("Ellipse" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "pattern"))) :: rest, resultList,context as ("Polygon" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "pattern"))) :: rest, resultList,context as ("Line" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillPattern"))) :: rest, resultList,context as("Rectangle" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillPattern"))) :: rest, resultList,context as("Ellipse" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillPattern"))) :: rest, resultList,context as("Polygon" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((Absyn.MODIFICATION(path = Absyn.IDENT(name = "thickness"))) :: rest, resultList,context as("Bitmap" :: _))
      equation
        //Filter away, bitmaps can have no thickness.
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "thickness"))) :: rest, resultList,context)
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((Absyn.MODIFICATION(path = Absyn.IDENT(name = "gradient"), modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=Absyn.INTEGER(value = 0)))))) :: rest, resultList,context)
      //Filter away
      equation
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "gradient"))) :: rest, resultList,context as ("Rectangle" :: _))
      equation
        rest = removeFillPatternInList(rest) /*If we have a old gradient any old fillPattern should be removed.*/;
        resultList = removeFillPatternInList(resultList) /*If we have a old gradient any old fillPattern should be removed.*/;
        rest = setDefaultLineInList(rest) /*If Gradient is set the line around the figure should be default*/;
        resultList = setDefaultLineInList(resultList) /*If Gradient is set the line around the figure should be default*/;
        (rest,resultList) = setDefaultFillColor(rest,resultList) /*If gradient is specificed but no fillColor, fillColor needs to be set to it's default dymola value.*/;
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "gradient"))) :: rest, resultList,context as ("Ellipse" :: _))
      equation
        rest = removeFillPatternInList(rest) /*If we have a old gradient any old fillPattern should be removed.*/;
        resultList = removeFillPatternInList(resultList) /*If we have a old gradient any old fillPattern should be removed.*/;
        rest = setDefaultLineInList(rest) /*If Gradient is set the line around the figure should be default*/;
        resultList = setDefaultLineInList(resultList) /*If Gradient is set the line around the figure should be default*/;
        (rest,resultList) = setDefaultFillColor(rest,resultList) /*If gradient is specificed but no fillColor, fillColor needs to be set to it's default dymola value.*/;
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "smooth"))) :: rest, resultList,context as("Polygon" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "smooth"))) :: rest, resultList,context as("Line" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "arrow"))) :: rest, resultList,context as("Line" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "textStyle"))) :: rest, resultList,context as("Text" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

    case((arg as Absyn.MODIFICATION(path = Absyn.IDENT(name = "font"))) :: rest, resultList,context as("Text" :: _))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;

 /*   case((arg as Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "string"), modification = m, comment = com)) :: rest, resultList,context as("Text" :: c))
      equation
        resultList = List.appendElt(arg,resultList);
        outList = cleanStyleAttrs(rest,resultList,context);
      then outList;

  */
    case(_ :: rest, resultList,context)
      equation
        //Filter away unwanted trash
        outList = cleanStyleAttrs2(rest,resultList,context);
      then outList;
  end match;
end cleanStyleAttrs2;

protected function insertFillPatternInList "Helperfunction to cleanStyleAttrs. Inserts a fillPattern attribute in a list
  of annotations.
"

  input list<Absyn.ElementArg> inArgs;
  output list<Absyn.ElementArg> outArgs;
algorithm
  outArgs := match inArgs
    local
      list<Absyn.ElementArg> lst;

    case(lst)
      equation
        lst = Absyn.MODIFICATION(false, Absyn.NON_EACH(),
        Absyn.IDENT("fillPattern"), SOME(Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.INTEGER(1),Absyn.dummyInfo))),NONE(),Absyn.dummyInfo) :: lst;
      then lst;
  end match;
end insertFillPatternInList;

protected function isGradientInList "
  Helperfunction to cleanStyle attrs. Returns true if a Gradient is found in a list
  of Absyn.ElementArg.
"
  input list<Absyn.ElementArg> inArgs;
  output Boolean result;
algorithm
  result := match inArgs
    local
      list<Absyn.ElementArg> rest;
      Absyn.ElementArg arg;
      Boolean fi,res;
      Absyn.Each e;
      Option<Absyn.Modification> m;
      Option<String> com;

    case({}) then false;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "gradient")):: _)
    then true;

    case(_ :: rest)
      equation
        res = isGradientInList(rest);
      then res;
  end match;
end isGradientInList;

protected function isFillPatternInList "
  Helperfunction to cleanStyleAttrs. Returns true if a fillPattern attribute is
  found in a list of Absyn.ElementArg.
"

  input list<Absyn.ElementArg> inArgs;
  output Boolean result;

algorithm
  result := match inArgs
    local
      list<Absyn.ElementArg> rest;
      Absyn.ElementArg arg;
      Boolean fi,res;
      Absyn.Each e;
      Option<Absyn.Modification> m;
      Option<String> com;

    case({}) then false;

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillPattern")):: _)
    then true;

    case(_ :: rest)
      equation
        res = isFillPatternInList(rest);
      then res;
  end match;
end isFillPatternInList;

protected function removeFillPatternInList "
  Helperfunction to cleanStyleAttrs. Removes a fillPattern attribute if present in a list
  of Absyn.ElementArg.
"
  input list<Absyn.ElementArg> inList;
  output list<Absyn.ElementArg> outList;
algorithm
  outList := match inList
    local
      list<Absyn.ElementArg> rest,lst;
      Absyn.ElementArg arg;

    case({}) then {};

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillPattern")) :: rest)

    then rest;

    case(arg::rest)
      equation
        lst = removeFillPatternInList(rest);
      then (arg::lst);
  end match;
end removeFillPatternInList;

protected function setDefaultFillColor "
  Helperfunction to cleanStyleAttrs. Sets a fillColor default value according to dymola
  standard. Used in case of gradient beeing specified but no fillColor.
"

  input list<Absyn.ElementArg> oldList;
  input list<Absyn.ElementArg> transformedList;

  output list<Absyn.ElementArg> oList;
  output list<Absyn.ElementArg> tList;
algorithm
  (oList,tList)  := matchcontinue (oldList,transformedList)
    local
      list<Absyn.ElementArg> oLst,tLst;

    case(oLst,tLst)
      equation
        false = isFillColorInList(listAppend(oLst,tLst));
        tLst = Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.IDENT("fillColor"), SOME(Absyn.CLASSMOD({},Absyn.EQMOD(Absyn.INTEGER(3),Absyn.dummyInfo))),NONE(),Absyn.dummyInfo)::tLst;
      then (oLst,tLst);

    else (oldList,transformedList);
  end matchcontinue;
end setDefaultFillColor;

protected function isFillColorInList "
  Helperfunction to setDefaultFillColor. Returns true if a fillColor attribute is found
  in a list of Absyn.ElementArg.
"
  input list<Absyn.ElementArg> inList;
  output Boolean outBoolean;
algorithm
  outBoolean := match inList
    local
      list<Absyn.ElementArg> rest;
      Absyn.ElementArg arg;
    case({})
      then false;
    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "fillColor")):: _)
      then true;
    case(_::rest)
      then isFillColorInList(rest);
  end match;
end isFillColorInList;


protected function setDefaultLineInList "Helperfunction to cleanStyleAttrs. Sets the line annotation to defualt values."
  input list<Absyn.ElementArg> inList;
  output list<Absyn.ElementArg> outList;
algorithm
  outList := match inList
    local
      list<Absyn.ElementArg> rest,lst,args;
      Absyn.ElementArg arg;
      Boolean fi;
      Absyn.Each e;
      Option<String> com;
      SourceInfo info;

    case({}) then {};
    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "thickness"), modification = SOME(Absyn.CLASSMOD())) :: rest)
      equation
        lst = setDefaultLineInList(rest);
      then lst; //filtered

    case(Absyn.MODIFICATION(path = Absyn.IDENT(name = "pattern"), modification = SOME(Absyn.CLASSMOD())) :: rest)
      equation
        lst = setDefaultLineInList(rest);
      then lst; //filtered

    case(Absyn.MODIFICATION(finalPrefix = fi, eachPrefix = e, path = Absyn.IDENT(name = "color"), modification = SOME(Absyn.CLASSMOD(elementArgLst= args)), comment = com, info = info) :: rest)
      equation
        lst = setDefaultLineInList(rest);
      then Absyn.MODIFICATION(fi, e, Absyn.IDENT("color"), SOME(Absyn.CLASSMOD(args,Absyn.EQMOD(Absyn.INTEGER(0),Absyn.dummyInfo))), com, info) :: lst;

    case(arg::rest)
      equation
        lst = setDefaultLineInList(rest);
      then (arg::lst);
  end match;
end setDefaultLineInList;

protected function getMappedColor "
  Helperfunction during the transformation. Takes a old color representation as input
  and returns the three RGB representations for that color.
"
  input Integer inColor "color to be mapped";
  output Integer color1;
  output Integer color2;
  output Integer color3;
algorithm
  (color1,color2,color3) := match (inColor)
    local
      rgbColor rcol;
      Integer  color;
    case(color)
      equation
        rcol = arrayGet(listArray(colorMapList),color+1);
        color1 = arrayGet(listArray(rcol),1);
        color2 = arrayGet(listArray(rcol),2);
        color3 = arrayGet(listArray(rcol),3);
      then
        (color1,color2,color3);
  end match;
end getMappedColor;

protected function matrixToArray ""
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
  value := match(intExpr)
    local
      Integer val;
    case(Absyn.INTEGER(value = val))
      then val;

    case(Absyn.UNARY(exp = Absyn.INTEGER(value = val)))
      then (-val);
  end match;
end getValueFromIntExp;

protected function getValueFromRealExp
  input Absyn.Exp realExpr;
  output Real value;
algorithm
  value := match(realExpr)
    local
      Real val;
    case(Absyn.REAL(value = val))
      then val;
    case(Absyn.UNARY(exp = Absyn.REAL(value = val)))
      then -val;
  end match;
end getValueFromRealExp;  */

protected function getValueFromExp
  input Absyn.Exp expr;
  output Real value;
algorithm
  value := match(expr)
    local
      String realVal;
      Integer intVal;
    case(Absyn.REAL(value = realVal))
    then System.stringReal(realVal);

    case(Absyn.UNARY(exp = Absyn.REAL(value = realVal)))
    then - System.stringReal(realVal);

    case(Absyn.INTEGER(value = intVal))
    then intReal(intVal);

    case(Absyn.UNARY(exp = Absyn.INTEGER(value = intVal)))
    then - intReal(intVal);
  end match;
end getValueFromExp;

protected function addContext ""
  input list<String> inList;
  input String newCon;
  output list<String> outList;
algorithm
  outList := match(inList,newCon)
    local
      String str;
      list<String> strLst;
    case(strLst,str)
    then str :: strLst;
  end match;
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
      Absyn.Path ip1, ip2, p1;
      String str1, str2;
      Absyn.Path out;
    case (ip1, ip2)
      equation
        str1 = Absyn.pathLastIdent(ip1);
        str2 = Absyn.pathFirstIdent(ip2);
        false = stringEq(str1, str2);
        p1 = Absyn.stripLast(ip1);
        out = fixPaths(p1, ip2);
      then
        out;

    case (ip1, ip2)
      equation
        str1 = Absyn.pathLastIdent(ip1);
        str2 = Absyn.pathFirstIdent(ip2);
        true = stringEq(str1, str2);
        p1 = Absyn.stripLast(ip1);
        out = Absyn.joinPaths(p1, ip2);
      then
        out;

    else inPath2; // if everything else fails, return inPath2

  end matchcontinue;
end fixPaths;

annotation(__OpenModelica_Interface="backend");
end Refactor;
