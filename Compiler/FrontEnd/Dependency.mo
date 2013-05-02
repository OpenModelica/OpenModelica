/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköping University,
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

encapsulated package Dependency
" file:        Dependency.mo
  package:     Dependency
  description: This module contains functionality for dependency
               analysis of models used for saveTotalProgram.

  $Id$

  This package builds a dependency list starting from a class."

// public imports
public import Absyn;
public import AbsynDep;
public import SCode;
public import Env;
public import Interactive;

// protected imports
protected import BaseHashTable;
protected import Dump;
protected import HashTable2;
protected import ComponentReference;
protected import Connect;
protected import Flags;
protected import Inst;
protected import List;
protected import DAE;
protected import InnerOuter;
protected import UnitAbsyn;
protected import Prefix;
protected import ClassInf;
protected import Lookup;
protected import ConnectionGraph;
protected import System;
protected import SCodeUtil;

public function getTotalProgramLastClass "Retrieves a total program for the last class in the program"
input Absyn.Program ip;
output Absyn.Program outP;
algorithm
  outP := match(ip)
  local String id; list<Absyn.Class> cls; Absyn.Program p;
    case(p as Absyn.PROGRAM(classes = cls)) equation
      Absyn.CLASS(name=id) = List.last(cls);
      p = getTotalProgram(Absyn.IDENT(id),p);
    then p;
  end match;
end getTotalProgramLastClass;

public function getTotalProgram "
Retrieves a total program for a model by only building dependencies for the affected class"
  input Absyn.Path modelName;
  input Absyn.Program ip;
  output Absyn.Program outP;
algorithm
  outP := matchcontinue(modelName,ip)
  local AbsynDep.Depends dep; AbsynDep.AvlTree uses; Absyn.Program p2,p1,p;
    case(_,p) equation

      true = Flags.isSet(Flags.USEDEP); // do dependency ONLY if this flag is true
      dep = getTotalProgram2(modelName,p);
      uses = AbsynDep.getUsesTransitive(dep,modelName);
      uses = AbsynDep.avlTreeAdd(uses,modelName,{});
      p1 = extractProgram(p,uses);
      p2 = getTotalModelOnTop(p,modelName) "creates a top model if target is qualified";
      p = Interactive.updateProgram(p1,p2);
      // Debug.fprintln(Flags.DEPS, Dump.unparseStr(p, false));
    then p;
    case (_,p) then p;
  end matchcontinue;
end getTotalProgram;

public function getTotalProgramFromPath "
Retrieves a total program for a model by only building dependencies for the affected class.
This function does not check the +d=usedep flag"
  input Absyn.Path modelName;
  input Absyn.Program p;
  output Absyn.Program outP;
algorithm
  outP := matchcontinue(modelName,p)
  local AbsynDep.Depends dep; AbsynDep.AvlTree uses; Absyn.Program p2,p1;
    case(modelName,p) equation
      dep = getTotalProgram2(modelName,p);
      uses = AbsynDep.getUsesTransitive(dep,modelName);
      uses = AbsynDep.avlTreeAdd(uses,modelName,{});
      p1 = extractProgram(p,uses);
      p = p1;
      // Debug.fprintln(Flags.DEPS, Dump.unparseStr(p, false));
    then p;
    case(modelName,p) then p;
  end matchcontinue;
end getTotalProgramFromPath;

protected function getTotalProgram2 "Help function to getTotalProgram"
  input Absyn.Path path;
  input Absyn.Program p;
  output AbsynDep.Depends dep;
algorithm
  dep := match(path,p)
  local SCode.Program p_1; Env.Env env;
    case(_,_) equation
      p_1 = SCodeUtil.translateAbsyn2SCode(p);
      (_,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
      dep = getTotalProgramDep(AbsynDep.emptyDepends(),path,p,env);
    then dep;
  end match;
end getTotalProgram2;

protected function getTotalProgramDep "Help function to getTotalProgram2"
  input AbsynDep.Depends idep;
  input Absyn.Path iclassName;
  input Absyn.Program ip;
  input Env.Env env;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(idep,iclassName,ip,env)
    local
      Absyn.Class cl;
      Option<Absyn.Path> optPath;
      Absyn.ElementSpec comp;
      Absyn.Program p;
      AbsynDep.Depends dep;
      Absyn.Path className;

    case(dep,Absyn.FULLYQUALIFIED(className),p,_) then getTotalProgramDep(dep,className,p,env);
    /* If already added, skip to prevent infinite recursion */
    case(dep,className,p,_) equation
      _ = AbsynDep.getUses(dep,className);
      //print(Absyn.pathString(className));print(" allready added\n");
    then dep;

    /*Classes*/
    case(dep,className,p,_) equation
      cl = Interactive.getPathedClassInProgram(className,p);
      optPath = getClassScope(className);
      ((_,_,(dep,_,_))) = buildClassDependsVisitor((cl,optPath,(dep,p,env)));
     dep = getTotalProgramDep2(dep,className,p,env);
    then dep;

    /* constants */
    case(dep,className,p,_) equation
      comp = Interactive.getPathedComponentElementInProgram(className,p);
      optPath = getClassScope(className);
      optPath = extendScope(optPath,Absyn.pathLastIdent(className)) "a constant gets a 'scope' of its own";
      dep = buildClassDependsInEltSpec(false,comp,optPath,className,(dep,p,env,HashTable2.emptyHashTable()));
      dep = getTotalProgramDep2(dep,className,p,env);
    then dep;

    case(dep,className,p,_)  equation
     // print("GetTotalProgram for ");print(Absyn.pathString(className));print(" skipped \n");
      then dep;
  end matchcontinue;
end getTotalProgramDep;

protected function getTotalProgramDep2 "help function to getTotalProgramDep"
 input AbsynDep.Depends idep;
 input Absyn.Path iclassName;
 input Absyn.Program ip;
 input Env.Env env;
 output AbsynDep.Depends outDep;
 algorithm
   outDep := matchcontinue(idep,iclassName,ip,env)
     local
       AbsynDep.AvlTree classUses; list<Absyn.Path> v;
       Absyn.Program p;
       AbsynDep.Depends dep;
       Absyn.Path className;
     case(dep as AbsynDep.DEPENDS(classUses,_),className as Absyn.IDENT(_),p,_) equation
      v = AbsynDep.avlTreeGet(classUses,className);
      dep = getTotalProgramDepLst(dep,v,p,env);
     then dep;
     case(dep, Absyn.IDENT(_),p,_) then dep;
     case(dep as AbsynDep.DEPENDS(classUses,_),className  as Absyn.QUALIFIED(_,_),p,_) equation
       v = AbsynDep.avlTreeGet(classUses,className);
       dep = getTotalProgramDepLst(dep,v,p,env);
       className = Absyn.stripLast(className);
       dep = getTotalProgramDep(dep,className,p,env);
     then dep;
     case(dep as AbsynDep.DEPENDS(classUses,_),className  as Absyn.QUALIFIED(_,_),p,_) equation
       className = Absyn.stripLast(className);
       dep = getTotalProgramDep(dep,className,p,env);
     then dep;
   end matchcontinue;
end getTotalProgramDep2;

protected function getTotalProgramDepLst "Help function to getTotalProgramDep"
  input AbsynDep.Depends idep;
  input list<Absyn.Path> iclassNameLst;
  input Absyn.Program ip;
  input Env.Env env;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(idep,iclassNameLst,ip,env)
    local
      Absyn.Path className;
      Absyn.Program p;
      AbsynDep.Depends dep;
      list<Absyn.Path> classNameLst;

    case(dep,{},p,_) then dep;

    case(dep,className::classNameLst,p,_) equation
      dep = getTotalProgramDep(dep,className,p,env);
      dep = getTotalProgramDepLst(dep,classNameLst,p,env);
    then dep;
  end match;
end getTotalProgramDepLst;

protected function getClassScope "help function to getTotalProgramDep"
  input Absyn.Path iclassName;
  output Option<Absyn.Path> scope;
algorithm
  scope := matchcontinue(iclassName)
    local String id; Absyn.Path className;
    case(Absyn.FULLYQUALIFIED(className)) then getClassScope(className);

    case(Absyn.IDENT(id)) then NONE();

    case(className) equation
      className = Absyn.stripLast(className);
    then SOME(className);
  end matchcontinue;
end getClassScope;

protected function extendScope "Extends a scope with an identifier"
  input Option<Absyn.Path> optPath;
  input String id;
  output Option<Absyn.Path> outOptPath;
algorithm
  outOptPath := match(optPath,id)
  local Absyn.Path p;
    case(NONE(),_) then SOME(Absyn.IDENT(id));
    case(SOME(p),_) equation
      p = Absyn.joinPaths(p,Absyn.IDENT(id));
    then SOME(p);
  end match;
end extendScope;

protected function addPathScope "Adds the scope to a path"
input Absyn.Path path;
input Option<Absyn.Path> scope;
output Absyn.Path outPath;
algorithm
  outPath := match(path,scope)
  local Absyn.Path scopePath;
    case (_,NONE()) then path;
    case (_,SOME(scopePath)) then Absyn.joinPaths(scopePath,path);
  end match;
end addPathScope;

protected function getTotalModelOnTop "Used for getTotalProgram - retrieves the top level program for a saveTotalModel.
If the model in saveTotal is not on top level, a new model is created that inherits this one with a qualified name that has the
dots replaced by underscores.

I.e
A.B.Examples.test1 results in the model
model A_B_Examples_test1
  extends A.B.Examples.test1;
end A_B_Examples_test1;

Added to the top scope.
"
  input Absyn.Program ip;
  input Absyn.Path modelName;
  output Absyn.Program outP;
algorithm
  outP := match(ip,modelName)
    local
      String id;
      Absyn.TimeStamp timeStamp;
      Absyn.Class cl,cl2;
      Absyn.Program p;

    case(p as Absyn.PROGRAM(globalBuildTimes=timeStamp),Absyn.IDENT(id)) equation
      cl = Interactive.getPathedClassInProgram(modelName,p);
    then Absyn.PROGRAM({cl},Absyn.TOP(),timeStamp);

    case(p as Absyn.PROGRAM(globalBuildTimes=timeStamp),Absyn.QUALIFIED(name=_)) equation
      cl2 = createTopLevelTotalClass(modelName);
      p = Absyn.PROGRAM({cl2},Absyn.TOP(),timeStamp);
    then p;
  end match;
end getTotalModelOnTop;

protected function buildClassDependsInEltSpec "help function to  buildClassDependsinElts"
  input Boolean traverseClasses "is true for redeclarations, which is not traversed separately";
  input Absyn.ElementSpec eltSpec;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
    outDep := matchcontinue(traverseClasses,eltSpec,optPath,cname,dep)
      local
        AbsynDep.Depends d; Absyn.Program p; Env.Env env;
        Absyn.Path path,usesName,cname2;
        list<Absyn.ElementArg> eltarg;
        Absyn.Import import_;
        list<Absyn.ComponentItem> citems;
        Absyn.TypeSpec typeSpec;
        Absyn.ElementAttributes attr; Absyn.Class cl; String id;
        Absyn.ClassDef classDef;
        Env.Env env2;
        HashTable2.HashTable ht;
        /* If extending external object, also add dependency to constructor and destructor functions */
        case(_,Absyn.EXTENDS(path=path as Absyn.IDENT("ExternalObject"), elementArg=eltarg),SOME(cname2),_,(d,p,env,ht)) equation
          d = AbsynDep.addDependency(d,cname2,Absyn.joinPaths(cname2,Absyn.IDENT("constructor")));
          d = AbsynDep.addDependency(d,cname2,Absyn.joinPaths(cname2,Absyn.IDENT("destructor")));
          d = buildClassDependsInElementargs(eltarg,optPath,cname,(d,p,env,ht));
        then d;

        case(_,Absyn.EXTENDS(path=path, elementArg=eltarg),SOME(cname2),_,(d,p,env,ht)) equation
          usesName = absynMakeFullyQualified(path,optPath,cname,env,p);
          d = AbsynDep.addDependency(d,cname2,usesName);
          d = buildClassDependsInElementargs(eltarg,optPath,cname,(d,p,env,ht));
        then d;
        case(_,Absyn.COMPONENTS(typeSpec=typeSpec,components=citems,attributes=attr),_,_,(d,p,env,ht)) equation
          d = buildClassDependsInTypeSpec(typeSpec,optPath,cname,(d,p,env,ht));
          d = buildClassDependsInElementAttr(attr,optPath,cname,(d,p,env,ht));
          d = buildClassDependsInComponentItems(citems,optPath,cname,(d,p,env,ht));
        then d;
        case(_,Absyn.IMPORT(import_=import_),_,_,(d,p,env,ht))
          equation
            d = buildClassDependsInImport(import_,optPath,cname,(d,p,env,ht));
          then d;

        case(false,Absyn.CLASSDEF(class_=cl as Absyn.CLASS(name="equalityConstraint", body = classDef)),_,_,(d,p,env,ht))
          equation
          d = AbsynDep.addDependency(d, cname, Absyn.joinPaths(cname,Absyn.IDENT("equalityConstraint")));
          then d;

        case(false,Absyn.CLASSDEF(class_=cl as Absyn.CLASS(name=id, body = classDef)),_,_,(d,p,env,ht))
          /*
          equation
            env2 = getClassEnvNoElaborationScope(p,_,env);
            d = buildClassDependsInClassDef(classDef,_,Absyn.IDENT(id),(d,p,env2,ht));
          */
          then d;

        /* traverse inner classes only for redeclarations*/
        case(true,Absyn.CLASSDEF(class_=cl as Absyn.CLASS(name=id,body = classDef as Absyn.DERIVED(typeSpec=_))),_,_,(d,p,env,ht))
          equation
          env2 = getClassEnvNoElaborationScope(p,optPath,env);
          d = buildClassDependsInClassDef(classDef,optPath,Absyn.IDENT(id),(d,p,env2,ht));
        then d;
    end matchcontinue;
end  buildClassDependsInEltSpec;

protected function buildClassDependsInComponentItems "build class dependencies from component items,
e.g. redeclaration modifiers, etc."
  input list<Absyn.ComponentItem> icitems;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(icitems,optPath,cname,dep)
    local
      AbsynDep.Depends d; Absyn.Program p; Env.Env env;
      Option<Absyn.Modification> optMod;
      Option<Absyn.Exp> optExp; Absyn.ArrayDim ad;
      HashTable2.HashTable ht;
      list<Absyn.ComponentItem> citems;

    case({},_,_,(d,p,env,ht)) then d;

    case(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification=optMod,arrayDim=ad),condition=optExp)::citems,_,_,(d,p,env,ht)) equation
      d = buildClassDependsInModificationOpt(optMod,optPath,cname,(d,p,env,ht));
      d = buildClassDependsInOptExp(optExp,optPath,cname,(d,p,env,ht));
      d = buildClassDependsinArrayDim(ad,optPath,cname,(d,p,env,ht));
      d = buildClassDependsInComponentItems(citems,optPath,cname,(d,p,env,ht));
    then d;
    case(_,_,_,(d,p,env,ht)) then d;
  end matchcontinue;
end buildClassDependsInComponentItems;

protected function buildClassDependsInModificationOpt "build class dependencies from Option<Modification>"
  input Option<Absyn.Modification> optMod;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(optMod,optPath,cname,dep)
    local
      Absyn.Modification mod;
      AbsynDep.Depends d;
      Absyn.Program p;
      Env.Env env;
      HashTable2.HashTable ht;
    case(NONE(),_,_,(d,p,env,ht)) then d;
    case(SOME(mod),_,_,(d,p,env,ht))
      equation
        d = buildClassDependsInModification(mod,optPath,cname,(d,p,env,ht));
      then d;
  end match;
end buildClassDependsInModificationOpt;

protected function buildClassDependsInModification "build class dependencies from Modification"
  input Absyn.Modification mod;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(mod,optPath,cname,dep)
    local
      Absyn.EqMod eqMod;
      AbsynDep.Depends d;
      Absyn.Program p;
      Env.Env env;
      list<Absyn.ElementArg> eltArgs;
      HashTable2.HashTable ht;
    case(Absyn.CLASSMOD(eltArgs,eqMod),_,_,(d,p,env,ht))
      equation
        d = buildClassDependsInElementargs(eltArgs,optPath,cname,(d,p,env,ht));
        d = buildClassDependsInEqMod(eqMod,optPath,cname,(d,p,env,ht));
      then d;
  end match;
end buildClassDependsInModification;

protected function buildClassDependsInElementargs "build class dependencies from elementargs"
  input list<Absyn.ElementArg> ieltArgs;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(ieltArgs,optPath,cname,dep)
    local
      AbsynDep.Depends d;
      Absyn.Program p;
      Env.Env env;
      Absyn.Modification mod;
      Absyn.ElementSpec eltSpec;
      HashTable2.HashTable ht;
      list<Absyn.ElementArg> eltArgs;

    case({},_,_,(d,p,env,ht)) then d;
    case(Absyn.MODIFICATION(modification=SOME(mod))::eltArgs,_,_,(d,p,env,ht)) equation
      d = buildClassDependsInModification(mod,optPath,cname,(d,p,env,ht));
      d = buildClassDependsInElementargs(eltArgs,optPath,cname,(d,p,env,ht));
    then d;
    case(Absyn.REDECLARATION(elementSpec = eltSpec)::eltArgs,_,_,(d,p,env,ht)) equation
      d = buildClassDependsInEltSpec(true,eltSpec,optPath,cname,(d,p,env,ht));
      d = buildClassDependsInElementargs(eltArgs,optPath,cname,(d,p,env,ht));
    then d;
    case(_::eltArgs,_,_,(d,p,env,ht)) equation
      d = buildClassDependsInElementargs(eltArgs,optPath,cname,(d,p,env,ht));
    then d;
  end matchcontinue;
end buildClassDependsInElementargs;

protected function buildClassDependsInImport "build class dependency from an import statement"
input Absyn.Import imp;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(imp,optPath,cname,dep)
    local
      Absyn.Path usesName,path,cname2;
      AbsynDep.Depends d; Absyn.Program p; Env.Env env;
      HashTable2.HashTable ht;
    case(Absyn.NAMED_IMPORT(path=path),SOME(cname2),_,(d,p,env,ht))
      equation
        usesName = absynCheckFullyQualified(path,optPath,cname,env,p);
        d = AbsynDep.addDependency(d,cname2,usesName);
      then d;

    case(Absyn.QUAL_IMPORT(path),SOME(cname2),_,(d,p,env,ht))
      equation
        usesName = absynCheckFullyQualified(path,optPath,cname,env,p);
        d = AbsynDep.addDependency(d,cname2,usesName);
      then d;

    case(Absyn.UNQUAL_IMPORT(path),SOME(cname2),_,(d,p,env,ht))
      equation
        usesName = absynCheckFullyQualified(path,optPath,cname,env,p);
        d = AbsynDep.addDependency(d,cname2,usesName);
      then d;
  end match;
end buildClassDependsInImport;


protected function buildClassDependsVisitor "class traversal function for calculating class dependencies"
  input tuple<Absyn.Class, Option<Absyn.Path>, tuple<AbsynDep.Depends,Absyn.Program,Env.Env>> inTpl;
  output tuple<Absyn.Class, Option<Absyn.Path>, tuple<AbsynDep.Depends,Absyn.Program,Env.Env>> outTpl;
algorithm
   outTpl := matchcontinue(inTpl)
   local Option<Absyn.Path> optPath;
     AbsynDep.Depends dep;
     Absyn.Program prg;
     Env.Env env,env2;
     Absyn.Class cl;
     Absyn.ClassDef classDef;
     Absyn.Ident id;
     Absyn.Path fq;
     /* Short class definitions */
     case((cl as Absyn.CLASS(name=id,body = classDef as Absyn.DERIVED(typeSpec=_)),optPath,(dep,prg,env))) equation
       env2 = getClassEnvNoElaborationScope(prg,optPath,env);
       (optPath as SOME(fq)) = extendScope(optPath,id);
       dep = AbsynDep.addEmptyDependency(dep,fq);
       dep = buildClassDependsInClassDef(classDef,optPath,Absyn.IDENT(id),(dep,prg,env2,HashTable2.emptyHashTable()));
     then ((cl,optPath,(dep,prg,env)));

       /* Long class definitions */
     case((cl as Absyn.CLASS(name=id,body = classDef),optPath,(dep,prg,env))) equation
       (optPath as SOME(fq)) = extendScope(optPath,id);
       dep = AbsynDep.addEmptyDependency(dep,fq);
       env2 = getClassEnvNoElaborationScope(prg,optPath,env);
       dep = buildClassDependsInClassDef(classDef,optPath,Absyn.IDENT(id),(dep,prg,env2,HashTable2.emptyHashTable()));
     then ((cl,optPath,(dep,prg,env)));
   end matchcontinue;
end buildClassDependsVisitor;

protected function buildClassDependsinParts " help function to buildClassDependsInClassDef"
  input list<Absyn.ClassPart> iparts;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := match(iparts,optPath,cname,dep)
 local
   list<Absyn.ElementItem> elts;
   list<Absyn.EquationItem> eqns;
   list<Absyn.AlgorithmItem> algs;
   AbsynDep.Depends d; Absyn.Program p; Env.Env env;
   HashTable2.HashTable ht;
   list<Absyn.ClassPart> parts;

   case({},_,_,(d,p,env,ht)) then d;

   case (Absyn.PUBLIC(contents = elts)::parts,_,_,(d,p,env,ht)) equation
     d = buildClassDependsinElts(elts,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

   case (Absyn.PROTECTED(contents = elts)::parts,_,_,(d,p,env,ht)) equation
     d = buildClassDependsinElts(elts,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

   case (Absyn.EQUATIONS(contents = eqns)::parts,_,_,(d,p,env,ht)) equation
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

    case (Absyn.INITIALEQUATIONS(contents = eqns)::parts,_,_,(d,p,env,ht)) equation
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

    case (Absyn.ALGORITHMS(contents = algs)::parts,_,_,(d,p,env,ht)) equation
     d = buildClassDependsinAlgs(algs,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

    case (Absyn.INITIALALGORITHMS(contents = algs)::parts,_,_,(d,p,env,ht)) equation
     d = buildClassDependsinAlgs(algs,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

    case(Absyn.EXTERNAL(_,_)::parts,_,_,(d,p,env,ht)) equation
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;
  end match;
end buildClassDependsinParts;

protected function buildClassDependsinAlgs "Build class dependencies from algorithms"
  input list<Absyn.AlgorithmItem> ialgs;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(ialgs,optPath,cname,dep)
   local  AbsynDep.Depends d; Absyn.Program p; Env.Env env;
     Absyn.Algorithm alg;
     HashTable2.HashTable ht;
     list<Absyn.AlgorithmItem> algs;
   case({},_,_,(d,p,env,ht)) then d;
   case(Absyn.ALGORITHMITEM(algorithm_=alg)::algs,_,_,(d,p,env,ht)) equation
     d = buildClassDependsInAlg(alg,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(algs,optPath,cname,(d,p,env,ht));
   then d;
   case(_::algs,_,_,(d,p,env,ht)) equation
     d = buildClassDependsinAlgs(algs,optPath,cname,(d,p,env,ht));
   then d;
 end matchcontinue;
end buildClassDependsinAlgs;

protected function buildClassDependsInAlg "build class dependencies in an algorithm"
  input Absyn.Algorithm alg;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(alg,optPath,cname,dep)
 local Absyn.Exp e1,e2;
   AbsynDep.Depends d; Absyn.Program p; Env.Env env;
   list<Absyn.AlgorithmItem> tb,fb,body;
   list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> elsifb;
   Absyn.ComponentRef cr; Absyn.FunctionArgs funcargs;
   HashTable2.HashTable ht;
   case(Absyn.ALG_ASSIGN(e1,e2),_,_,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e2,optPath,cname,(d,p,env,ht));
   then d;
   case(Absyn.ALG_IF(e1,tb,elsifb,fb),_,_,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(tb,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(fb,optPath,cname,(d,p,env,ht));
     d = buildClassDependsInAlgElseifBranch(elsifb,optPath,cname,(d,p,env,ht));
   then d;

   case(Absyn.ALG_FOR({Absyn.ITERATOR(range=SOME(e1))},body),_,_,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(body,optPath,cname,(d,p,env,ht));
    then d;

   /* adrpo: TODO! add full support for ForIterators*/
   case(Absyn.ALG_FOR({Absyn.ITERATOR(range=NONE())},body),_,_,(d,p,env,ht)) equation
     /* d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht)); */
     d = buildClassDependsinAlgs(body,optPath,cname,(d,p,env,ht));
    then d;

    case(Absyn.ALG_PARFOR({Absyn.ITERATOR(range=SOME(e1))},body),_,_,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(body,optPath,cname,(d,p,env,ht));
    then d;

   /* adrpo: TODO! add full support for ForIterators*/
   case(Absyn.ALG_PARFOR({Absyn.ITERATOR(range=NONE())},body),_,_,(d,p,env,ht)) equation
     /* d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht)); */
     d = buildClassDependsinAlgs(body,optPath,cname,(d,p,env,ht));
    then d;

   case(Absyn.ALG_WHILE(e1,body),_,_,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(body,optPath,cname,(d,p,env,ht));
    then d;

   case(Absyn.ALG_WHEN_A(e1,body,elsifb),_,_,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(body,optPath,cname,(d,p,env,ht));
     d = buildClassDependsInAlgElseifBranch(elsifb,optPath,cname,(d,p,env,ht));
   then d;

   case(Absyn.ALG_NORETCALL(cr,funcargs),_,_,(d,p,env,ht)) equation
    d = buildClassDependsInExp(Absyn.CALL(cr,funcargs),optPath,cname,(d,p,env,ht));
   then d;
   case(_,_,_,(d,p,env,ht)) then d;
  end matchcontinue;
end buildClassDependsInAlg;

protected function buildClassDependsInAlgElseifBranch "help function to buildClassDependsInAlg"
  input list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> ielsifb;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := match(ielsifb,optPath,cname,dep)
 local AbsynDep.Depends d; Absyn.Program p; Env.Env env;
   Absyn.Exp e;
   list<Absyn.AlgorithmItem> eb;
   HashTable2.HashTable ht;
   list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> elsifb;

   case({},_,_,(d,_,_,_)) then d;

   case((e,eb)::elsifb,_,_,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(eb,optPath,cname,(d,p,env,ht));
     d = buildClassDependsInAlgElseifBranch(elsifb,optPath,cname,(d,p,env,ht));
   then d;
 end match;
end buildClassDependsInAlgElseifBranch;

public function extractProgram " extract a sub-program with the classes that are in the avltree passed as argument"
  input Absyn.Program p;
  input AbsynDep.AvlTree tree;
  output Absyn.Program outP;
algorithm
((outP,_,_)) := Interactive.traverseClasses(p, NONE(), extractProgramVisitor, (tree,{},{}), true) "traverse protected" ;
end extractProgram;

protected function buildClassDependsinEqns "Build class dependencies from equations"
  input list<Absyn.EquationItem> ieqns;
  input Option<Absyn.Path> optPath;
  input Absyn.Path icname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(ieqns,optPath,icname,dep)
   local
     AbsynDep.Depends d;
     Absyn.Program p;
     Env.Env env;
     Absyn.Exp e,e1,e2;
     list<Absyn.EquationItem> teqns,feqns,whenEqns;
     list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> elseifeqns,elseWhenEqns;
     Absyn.FunctionArgs fargs;
     Absyn.ComponentRef cr;
     Absyn.Path path,usesName,cname2,cname;
     HashTable2.HashTable ht;
     list<Absyn.EquationItem> eqns;

   case({},_,_,(d,p,env,ht)) then d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_IF(e,teqns,elseifeqns,feqns))::eqns,_,cname,(d,p,env,ht))
     equation
       d = buildClassDependsinElseIfEqns(elseifeqns,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinEqns(teqns,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinEqns(feqns,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
       d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
     then
       d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_EQUALS(e1,e2))::eqns,_,cname,(d,p,env,ht))
     equation
       d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht));
       d = buildClassDependsInExp(e2,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     then
       d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(_,_))::eqns,_,cname,(d,p,env,ht))
     equation
       d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     then
       d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_FOR({Absyn.ITERATOR(range=SOME(e))},feqns))::eqns,_,cname,(d,p,env,ht))
     equation
       d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinEqns(feqns,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     then
       d;

   // adrpo: TODO! FIXME! add the full ForIterators support
   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_FOR({Absyn.ITERATOR(range=NONE())},feqns))::eqns,_,cname,(d,p,env,ht))
     equation
       d = buildClassDependsinEqns(feqns,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     then
       d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_WHEN_E(e,whenEqns,elseWhenEqns))::eqns,_,cname,(d,p,env,ht))
     equation
       d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinEqns(whenEqns,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinElseIfEqns(elseWhenEqns,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     then
       d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_NORETCALL(cr,fargs))::eqns,SOME(cname2),cname,(d,p,env,ht))
     equation
       d = buildClassDependsInFuncargs(fargs,optPath,cname,(d,p,env,ht));
       path = Absyn.crefToPath(cr);
       usesName = absynMakeFullyQualified(path,optPath,cname,env,p);
       cname = addPathScope(cname,optPath);
       d = AbsynDep.addDependency(d,cname2,usesName);
       d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     then
       d;

   case(_::eqns,_,cname,(d,p,env,ht))
     equation
       d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     then
       d;
  end matchcontinue;
end buildClassDependsinEqns;

protected function buildClassDependsinElseIfEqns ""
  input list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> ielseifeqns;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := match(ielseifeqns,optPath,cname,dep)
   local
     AbsynDep.Depends d;
     Absyn.Program p;
     Env.Env env;
     Absyn.Exp e;
     list<Absyn.EquationItem> eqns;
     HashTable2.HashTable ht;
     list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> elseifeqns;

   case({},_,_,(d,p,env,ht)) then d;

   case((e,eqns)::elseifeqns,_,_,(d,p,env,ht))
     equation
       d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
       d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinElseIfEqns(elseifeqns,optPath,cname,(d,p,env,ht));
     then d;
 end match;
end buildClassDependsinElseIfEqns;

protected function buildClassDependsInFuncargs "build class dependencies from function arguments.
For example foo(Modelica.Math.sin(x))
"
  input Absyn.FunctionArgs fargs;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := match(fargs,optPath,cname,dep)
 local list<Absyn.Exp> args;
   list<Absyn.NamedArg> nargs;
   AbsynDep.Depends d; Absyn.Program p; Env.Env env;
   HashTable2.HashTable ht;
   case (Absyn.FUNCTIONARGS(args,nargs),_,_,(d,p,env,ht)) equation
      d = buildClassDependsInExpList(args,optPath,cname,(d,p,env,ht));
      d = buildClassDependsInNamedArgs(nargs,optPath,cname,(d,p,env,ht));
   then d;
  end match;
end buildClassDependsInFuncargs;

protected function buildClassDependsInNamedArgs "build class dependencies from named arguments"
  input list<Absyn.NamedArg> inargs;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := match(inargs,optPath,cname,dep)
   local
     AbsynDep.Depends d;
     Absyn.Program p;
     Env.Env env;
     Absyn.Exp e;
     HashTable2.HashTable ht;
     list<Absyn.NamedArg> nargs;

   case({},_,_,(d,p,env,ht)) then d;

   case(Absyn.NAMEDARG(_,e)::nargs,_,_,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
     d = buildClassDependsInNamedArgs(nargs,optPath,cname,(d,p,env,ht));
   then d;
  end match;
end buildClassDependsInNamedArgs;


protected function buildClassDependsInExpVisitor "visitor function fo building class dependencies from Absyn.Exp"
  input tuple<Absyn.Exp,tuple<Option<Absyn.Path>,Absyn.Path,tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable>>> tpl;
  output tuple<Absyn.Exp,tuple<Option<Absyn.Path>,Absyn.Path,tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable>>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      Option<Absyn.Path> optPath;
      Absyn.Path cname,path,usesName,cname2;
      AbsynDep.Depends d;
      Absyn.Program p;
      Env.Env env;
      Absyn.Exp e;
      Absyn.ComponentRef cr;
      HashTable2.HashTable ht;
      String compString;

    // calls
    case((e as Absyn.CALL(cr,_),(optPath as SOME(cname2),cname,(d,p,env,ht))))
      equation
        path = Absyn.crefToPath(cr);
        usesName = absynMakeFullyQualified(path,optPath,cname,env,p);
        d = AbsynDep.addDependency(d,cname2,usesName);
      then
        ((e,(optPath,cname,(d,p,env,ht))));

    // constants
    case((e as Absyn.CREF(cr),(optPath as SOME(cname2),cname,(d,p,env,ht))))
      equation
        compString = Absyn.printComponentRefStr(cr);
        cr = Absyn.crefStripLastSubs(cr);
        path = Absyn.crefToPath(cr);
        failure(_ = BaseHashTable.get(ComponentReference.makeCrefIdent(compString, DAE.T_UNKNOWN_DEFAULT,{}),ht)) "do not add local variables to depndencies";
        (usesName as Absyn.FULLYQUALIFIED(_)) = absynMakeFullyQualified(path,optPath,cname,env,p);
        d = AbsynDep.addDependency(d,cname2,usesName);
      then
        ((e,(optPath,cname,(d,p,env,ht))));

    // any other case
    case _ then tpl;
  end matchcontinue;
end buildClassDependsInExpVisitor;

protected function buildClassDependsinArrayDimOpt " help function to e.g buildClassDependsInTypeSpec"
  input Option<Absyn.ArrayDim> adOpt;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(adOpt,optPath,cname,dep)
    local
      AbsynDep.Depends d;
      Absyn.Program p;
      Env.Env env;
      Absyn.ArrayDim ad;
      HashTable2.HashTable ht;

    case(NONE(),_,_,(d,p,env,ht)) then d;

    case(SOME(ad),_,_,(d,p,env,ht))
      equation
        d = buildClassDependsinArrayDim(ad,optPath,cname,(d,p,env,ht));
      then d;
  end match;
end buildClassDependsinArrayDimOpt;

protected function buildClassDependsInExpList "build class dependencies from exp list"
  input list<Absyn.Exp> iexpl;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(iexpl,optPath,cname,dep)
    local
      AbsynDep.Depends d; Absyn.Program p; Env.Env env;
      Absyn.Exp e;
      HashTable2.HashTable ht;
      list<Absyn.Exp> expl;

    case({},_,_,(d,p,env,ht)) then d;

    case(e::expl,_,_,(d,p,env,ht))
      equation
        d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
        d = buildClassDependsInExpList(expl,optPath,cname,(d,p,env,ht));
      then d;
  end match;
end buildClassDependsInExpList;

protected function buildClassDependsinElts "help function to buildClassDependsinParts"
  input list<Absyn.ElementItem> ielts;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(ielts,optPath,cname,dep)
   local
     Absyn.ElementSpec eltSpec;
     AbsynDep.Depends d;
     Absyn.Program p;
     Env.Env env;
     HashTable2.HashTable ht;
     list<Absyn.ElementItem> elts;

   case({},_,_,(d,p,env,ht)) then d;

   case(Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=eltSpec))::elts,_,_,(d,p,env,ht))
     equation
       d = buildClassDependsInEltSpec(false,eltSpec,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinElts(elts,optPath,cname,(d,p,env,ht));
     then d;

   case(_::elts,_,_,(d,p,env,ht))
     equation
       d = buildClassDependsinElts(elts,optPath,cname,(d,p,env,ht));
     then d;
 end matchcontinue;
end buildClassDependsinElts;

protected function buildClassDependsInExp "build class dependencies from Absyn.Exp"
  input Absyn.Exp e;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(e,optPath,cname,dep)
    local
      AbsynDep.Depends d;
      Absyn.Program p;
      Env.Env env;
      HashTable2.HashTable ht;

    case(_,_,_,(d,p,env,ht))
      equation
        ((_,(_,_,(outDep,_,_,_)))) = Absyn.traverseExp(e,buildClassDependsInExpVisitor,(optPath,cname,(d,p,env,ht)));
      then outDep;
  end match;
end buildClassDependsInExp;

protected function buildClassDependsInClassDef "help function to buildClassDependsVisitor"
  input Absyn.ClassDef cdef;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(cdef,optPath,cname,dep)
    local
      Absyn.TypeSpec typeSpec;
      Absyn.Program prg;
      AbsynDep.Depends d;
      Env.Env env;
      list<Absyn.ClassPart> parts;
      Absyn.ElementAttributes attr;
      HashTable2.HashTable ht;

    case (Absyn.DERIVED(typeSpec=typeSpec,attributes=attr),_,_,(d,prg,env,ht))
      equation
        d = buildClassDependsInTypeSpec(typeSpec,optPath,cname,(d,prg,env,ht));
        d = buildClassDependsInElementAttr(attr,optPath,cname,(d,prg,env,ht));
      then d;

    case (Absyn.PARTS(classParts=parts),_,_,(d,prg,env,ht))
      equation
        ht = createLocalVariableStruct(parts,ht);
        d = buildClassDependsinParts(parts,optPath,cname,(d,prg,env,ht));
      then d;

    case(Absyn.CLASS_EXTENDS(parts=parts),_,_,(d,prg,env,ht))
      equation
        ht = createLocalVariableStruct(parts,ht);
        d = buildClassDependsinParts(parts,optPath,cname,(d,prg,env,ht));
      then d;

    case(Absyn.ENUMERATION(enumLiterals=_),_,_,(d,_,_,_)) then d;

   // case(_,_,_,_)
   //   equation
   //     print("buildClassDependsInClassDef failed\n");
   //   then
   //     fail();
  end match;
end buildClassDependsInClassDef;

protected function buildClassDependsInTypeSpec "help function to e.g. buildClassDependsInClassDef"
  input Absyn.TypeSpec typeSpec;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(typeSpec,optPath,cname,dep)
    local
      Absyn.Path path,usesName,cname2;
      AbsynDep.Depends d; Absyn.Program p; Env.Env env;
      Option<Absyn.ArrayDim> adOpt;HashTable2.HashTable ht;

    case(Absyn.TPATH(path = path,arrayDim=adOpt),SOME(cname2),_,(d,p,env,ht))
      equation
        d = buildClassDependsinArrayDimOpt(adOpt,optPath,cname,(d,p,env,ht));
        usesName = absynMakeFullyQualified(path,optPath,cname,env,p);
        d = AbsynDep.addDependency(d,cname2,usesName);
      then d;
  end match;
end buildClassDependsInTypeSpec;

protected function buildClassDependsInElementAttr "help function to buildClassDependsVisitor"
  input Absyn.ElementAttributes eltAttr;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(eltAttr,optPath,cname,dep)
    local
      AbsynDep.Depends d; Absyn.Program p; Env.Env env; Absyn.ArrayDim ad;
      HashTable2.HashTable ht;

    case(Absyn.ATTR(arrayDim=ad),_,_,(d,p,env,ht))
      equation
        d = buildClassDependsinArrayDim(ad,optPath,cname,(d,p,env,ht));
      then d;
  end match;
end buildClassDependsInElementAttr;

protected function buildClassDependsInOptExp "build class dependencies from Option<Absyn.Exp>"
  input Option<Absyn.Exp> optExp;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(optExp,optPath,cname,dep)
  local AbsynDep.Depends d; Absyn.Program p; Env.Env env; Absyn.Exp e;HashTable2.HashTable ht;
    case(SOME(e),_,_,(d,p,env,ht)) then buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
    case(NONE(),_,_,(d,p,env,ht)) then d;
  end match;
end buildClassDependsInOptExp;

protected function buildClassDependsInEqMod "build class dependencies from Option<Absyn.Exp>"
  input Absyn.EqMod eqMod;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(eqMod,optPath,cname,dep)
  local AbsynDep.Depends d; Absyn.Program p; Env.Env env; Absyn.Exp e;HashTable2.HashTable ht;
    case(Absyn.EQMOD(exp=e),_,_,(d,p,env,ht)) then buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
    case(Absyn.NOMOD(),_,_,(d,p,env,ht)) then d;
  end match;
end buildClassDependsInEqMod;

protected function buildClassDependsinArrayDim " help function to e.g buildClassDependsInTypeSpec"
  input Absyn.ArrayDim iad;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := match(iad,optPath,cname,dep)
    local
      AbsynDep.Depends d;
      Absyn.Program p;
      Env.Env env;
      Absyn.Exp e;
      HashTable2.HashTable ht;
      Absyn.ArrayDim ad;

    case({},_,_,(d,p,env,ht)) then d;
    case(Absyn.NOSUB()::ad,_,_,(d,p,env,ht)) then buildClassDependsinArrayDim(ad,optPath,cname,(d,p,env,ht));
    case(Absyn.SUBSCRIPT(e)::ad,_,_,(d,p,env,ht)) equation
      d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
      d = buildClassDependsinArrayDim(ad,optPath,cname,(d,p,env,ht));
    then d;
  end match;
end buildClassDependsinArrayDim;

protected function createLocalVariableStruct "
Author BZ 2008-04
Function to extract local defined components and add to a hashtable.
This is used to filter out local variables from constants outside the local scope.
"
input list<Absyn.ClassPart> inparts;
input HashTable2.HashTable inTable;
output HashTable2.HashTable outTable;
algorithm outTable := matchcontinue(inparts,inTable)
  local
    Absyn.ClassPart part;
    list<Absyn.ClassPart> parts;
    list<Absyn.ElementItem> cont;
    HashTable2.HashTable table1,table2;
  case({},_) then inTable;
  case((part as Absyn.PUBLIC(cont))::parts,_)
    equation
      table1 = createLocalVariableStruct(parts,inTable);
      table2 = createLocalVariableStruct2(cont,table1);
    then
      table2;
  case((part as Absyn.PROTECTED(cont))::parts,_)
    equation
      table1 = createLocalVariableStruct(parts,inTable);
      table2 = createLocalVariableStruct2(cont,table1);
    then
      table2;
  case(_::parts,_)
    equation
      (table1) = createLocalVariableStruct(parts,inTable);
    then
      table1;
  end matchcontinue;
end createLocalVariableStruct;

protected function createLocalVariableStruct2 "
Author BZ 2008-04 Helper function for createLocalVariableStruct
"
  input list<Absyn.ElementItem> inElem;
  input HashTable2.HashTable inTable;
  output HashTable2.HashTable outTable;
algorithm
  outTable := matchcontinue(inElem,inTable)
  local
    list<Absyn.ElementItem> elemis;
    HashTable2.HashTable table1,table2;
    Absyn.ElementSpec spec;
    Absyn.ElementItem elit;
  case({},_) then inTable;
  case((Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=spec)))::elemis,_)
    equation
      table1 = createLocalVariableStruct2(elemis,inTable);
      table2 = createLocalVariableStruct3(spec,table1);
    then
      table2;
  case((Absyn.ELEMENTITEM(Absyn.TEXT(info = _)))::elemis,_)
    equation
      table1 = createLocalVariableStruct2(elemis,inTable);
    then table1;
  case((Absyn.LEXER_COMMENT(_))::elemis,_)
    equation
      table1 = createLocalVariableStruct2(elemis,inTable);
    then
      table1;
  case(elit::_,_)
    equation
      print("createLocalVariableStruct2 failed: ");
      print(Dump.unparseElementitemStr(0,elit));
      print("\n");
    then fail();
  end matchcontinue;
end createLocalVariableStruct2;

protected function createLocalVariableStruct3 "
Author BZ 2008-04 Helper function for createLocalVariableStruct
"
  input Absyn.ElementSpec inSpec;
  input HashTable2.HashTable inTable;
  output HashTable2.HashTable outTable;
algorithm
  outTable := matchcontinue(inSpec,inTable)
  local list<Absyn.ComponentItem> comps; HashTable2.HashTable table1;
  case(Absyn.COMPONENTS(components = comps),_)
    equation
      table1 = createLocalVariableStruct4(comps,inTable);
      then
        table1;
  case(Absyn.COMPONENTS(components = comps),_) equation print(" failure in createLocalVariableStruct3\n"); then fail();
  case(_,_) then inTable;
end matchcontinue;
end createLocalVariableStruct3;

protected function createLocalVariableStruct4 "
Author BZ 2008-04 Helper function for createLocalVariableStruct
"
  input list<Absyn.ComponentItem> inComponents;
  input HashTable2.HashTable inTable;
  output HashTable2.HashTable outTable;
algorithm outTable := matchcontinue(inComponents,inTable)
  local list<Absyn.ComponentItem> comps; String id; HashTable2.HashTable table1,table2;
    case({},_) then inTable;
  case((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id)))::comps,_)
    equation
      table1 = BaseHashTable.add((ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}),DAE.ICONST(0)),inTable);
      table2 = createLocalVariableStruct4(comps,table1);
      then
        table1;
  case(_,_) equation print(" failure in createLocalVariableStruct4\n"); then fail();
end matchcontinue;
end createLocalVariableStruct4;

protected function absynCheckFullyQualified "Similar to absynMakeFullyQualified, but only for imports which shoul already
be fully qualified."
  input Absyn.Path path;
  input Option<Absyn.Path> scope;
  input Absyn.Path className;
  input Env.Env env;
  input Absyn.Program p;
  output Absyn.Path fqPath;
algorithm
  fqPath := match(path,scope,className,env,p)
  local
    case(_,_,_,_,_) equation
      (_,fqPath) = Inst.makeFullyQualified(Env.emptyCache(),env, path);
    then fqPath;

   /* case(path,SOME(path2),className,env,p) equation
      print("chekc FQ failed for ");print(Absyn.pathString(path));print("in scope ");
      print(Absyn.pathString(path2));print("\n");
    then fail();

    case(path,NONE(),className,env,p) equation
      print("check FQ failed for ");print(Absyn.pathString(path));print("in top scope\n");
      print("env:");print(Env.printEnvStr(env));
    then fail();
    */
  end match;
end absynCheckFullyQualified;

protected function absynMakeFullyQualified "Takes a path, a scope, a classname , and an Absyn.Program and
makes the path fully qualified by looking up the name in the given scope in the program"
  input Absyn.Path path;
  input Option<Absyn.Path> scope;
  input Absyn.Path className;
  input Env.Env env;
  input Absyn.Program p;
  output Absyn.Path fqPath;
algorithm
  fqPath := match(path,scope,className,env,p)
  local

    case(_,_,_,_,_) equation
      (_,fqPath) = Inst.makeFullyQualified(Env.emptyCache(),env, path);
    then fqPath;

/*    case(path,SOME(path2),className,env,p) equation
      print("FQ failed for ");print(Absyn.pathString(path));print("in scope ");
      print(Absyn.pathString(path2));print("\n");
    then fail();

    case(path,NONE(),className,env,p) equation
      print("FQ failed for ");print(Absyn.pathString(path));print("in top scope\n");
      print("env:");print(Env.printEnvStr(env));
    then fail();
  */
  end match;
end absynMakeFullyQualified;

protected function getClassEnvNoElaborationScope "uses getClassEnvNoElaboration if in a scope, otherwise return top env"
  input Absyn.Program ip;
  input Option<Absyn.Path> optPath;
  input Env.Env ienv;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(ip,optPath,ienv)
  local Absyn.Path path; Absyn.Program p; Env.Env env;

    case(p,NONE(),env) then env;
    case(p,SOME(path),env) then getClassEnvNoElaboration(p,path,env);

    /* As a backup, remove a frame. This can be needed to circumvent encapsulated frames */
    case(p,SOME(path),_::env) then getClassEnvNoElaborationScope(p,SOME(path),env);

  end matchcontinue;
end getClassEnvNoElaborationScope;

public function getClassEnvNoElaboration "function: getClassEnvNoElaboration
   Retrieves the environment of the class, including the frame of the class
   itself by partially instantiating it.

   If partial instantiation fails, a full instantiation is performed.

   This can happen e.g. for
   model A
   model Resistor
    Pin p,n;
    constant Integer n_conn = cardinality(p);
    equation connect(p,n);
   end A;

   where partial instantiation fails since cardinality(p) can not be determined."
  input Absyn.Program p;
  input Absyn.Path p_class;
  input Env.Env env;
  output Env.Env env_2;
protected
  SCode.Element cl;
  String id;
  SCode.Encapsulated encflag;
  SCode.Restriction restr;
  list<Env.Frame> env_1,env2;
  ClassInf.State ci_state;
  Real t1,t2;
  Env.Cache cache;
algorithm
  env_2 := matchcontinue(p,p_class,env)
    // First try partial instantiation
    case(_,_,_)
      equation
        (cache,(cl as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = Lookup.lookupClass(Env.emptyCache(),env, p_class, false);
        env2 = Env.openScope(env_1, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));
        (cache,env_2,_,_) = Inst.partialInstClassIn(cache, env2, InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(), Prefix.NOPRE(), ci_state, cl, SCode.PUBLIC(), {}, 0);
      then
        env_2;

    case(_,_,_)
      equation
        (cache,(cl as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = Lookup.lookupClass(Env.emptyCache(),env, p_class, false);
        env2 = Env.openScope(env_1, encflag, SOME(id), Env.restrictionToScopeType(restr));
        ci_state = ClassInf.start(restr, Env.getEnvName(env2));
        (cache,env_2,_,_,_,_,_,_,_,_,_,_) = Inst.instClassIn(cache,env2, InnerOuter.emptyInstHierarchy,
          UnitAbsyn.noStore,DAE.NOMOD(), Prefix.NOPRE(),
          ci_state, cl, SCode.PUBLIC(), {},false, Inst.INNER_CALL(),
          ConnectionGraph.EMPTY, Connect.emptySet, NONE());
    then
      env_2;
  end matchcontinue;

end getClassEnvNoElaboration;

public function extractProgram2 "
Author BZ 2008-04
extract a subset of classes, with the classes that are in the avltree passed as argument"
  input Absyn.Program p;
  input AbsynDep.AvlTree tree;
  output list<Absyn.Class> outClasses;
  output list<Option<Absyn.Path>> outPaths;
algorithm
((_,_,(_,outClasses,outPaths))) := Interactive.traverseClasses(p,NONE(), extractProgramVisitor, (tree,{},{}), true) "traverse protected" ;
end extractProgram2;

protected function extractProgramVisitor "Visitor function to extractProgram"
  input tuple<Absyn.Class, Option<Absyn.Path>,tuple<AbsynDep.AvlTree,list<Absyn.Class>,list<Option<Absyn.Path>>>> inTpl;
  output tuple<Absyn.Class, Option<Absyn.Path>,tuple<AbsynDep.AvlTree,list<Absyn.Class>,list<Option<Absyn.Path>>>> outTpl;
algorithm
  outTpl := match(inTpl)
    local
      Absyn.Path path; Absyn.Class cl;
      String id; AbsynDep.AvlTree tree;
      list<Absyn.Class> cls;
      list<Option<Absyn.Path>> pts;

    case((cl as Absyn.CLASS(name=id),NONE(),(tree,cls,pts)))
      equation
        _ = AbsynDep.avlTreeGet(tree,Absyn.IDENT(id));
      then
        ((cl,NONE(),(tree,cl::cls,NONE()::pts)));

    case((cl as Absyn.CLASS(name=id),SOME(path),(tree,cls,pts)))
      equation
        _ = AbsynDep.avlTreeGet(tree,Absyn.joinPaths(path,Absyn.IDENT(id)));
      then
        ((cl,SOME(path),(tree,cl::cls,SOME(path)::pts)));
 end match;
end extractProgramVisitor;

protected function createTopLevelTotalClass "Creates a top level total class"
  input Absyn.Path modelName;
  output Absyn.Class cl;
protected
  String classStr,classStr2;
  Absyn.Info info;
  Absyn.ElementSpec elementspec;
algorithm
  classStr:= Absyn.pathString(modelName);
  classStr2 := System.stringReplace(classStr,".","_");
  info := Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0));
  elementspec := Absyn.EXTENDS(modelName,{},NONE());
  cl := Absyn.CLASS(classStr2,false,false,false,Absyn.R_MODEL(),
    Absyn.PARTS({},{},{Absyn.PUBLIC({Absyn.ELEMENTITEM(
      Absyn.ELEMENT(false,NONE(),Absyn.NOT_INNER_OUTER(),elementspec,info,NONE())
    )})},{},NONE()),info);
end createTopLevelTotalClass;

end Dependency;
