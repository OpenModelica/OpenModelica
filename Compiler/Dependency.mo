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

package Dependency
" file:        Dependency.mo
  package:     Dependency
  description: This module contains functionality for dependency
               analysis of models used for saveTotalProgram.

  $Id: Dependency.mo 5160 2010-03-17 14:33:27Z petar $

  This package builds a dependency list starting from a class."

public import Absyn;
public import AbsynDep;
public import SCode;
public import Env;
public import Interactive;

protected import HashTable2;
protected import Inst;
protected import Util;
protected import DAE;
protected import InnerOuter;
protected import UnitAbsyn;
protected import Prefix;
protected import ClassInf;
protected import Lookup;
protected import Connect;
protected import ConnectionGraph;
protected import System;
protected import SCodeUtil;
protected import RTOpts;

public function getTotalProgramLastClass "Retrieves a total program for the last class in the program"
input Absyn.Program p;
output Absyn.Program outP;
algorithm
  outP := matchcontinue(p)
  local String id; list<Absyn.Class> cls;
    case(p as Absyn.PROGRAM(classes = cls)) equation
      Absyn.CLASS(name=id) = Util.listLast(cls);
      p = getTotalProgram(Absyn.IDENT(id),p);
    then p;
  end matchcontinue;
end getTotalProgramLastClass;

public function getTotalProgram "
Retrieves a total program for a model by only building dependencies for the affected class"
  input Absyn.Path modelName;
  input Absyn.Program p;
  output Absyn.Program outP;
algorithm
  outP := matchcontinue(modelName,p)
  local AbsynDep.Depends dep; AbsynDep.AvlTree uses; Absyn.Program p2,p1;
    case(modelName,p) equation
      true = RTOpts.debugFlag("usedep"); // do dependency ONLY if this flag is true
      dep = getTotalProgram2(modelName,p);
      uses = AbsynDep.getUsesTransitive(dep,modelName);
      uses = AbsynDep.avlTreeAdd(uses,modelName,{});
      p1 = extractProgram(p,uses);
      p2 = getTotalModelOnTop(p,modelName) "creates a top model if target is qualified";
      p = Interactive.updateProgram(p1,p2);
      // Debug.fprintln("deps", Dump.unparseStr(p, false));
    then p;
    case(modelName,p) then p;
  end matchcontinue;
end getTotalProgram;

protected function getTotalProgram2 "Help function to getTotalProgram"
  input Absyn.Path path;
  input Absyn.Program p;
  output AbsynDep.Depends dep;
algorithm
  dep := matchcontinue(path,p)
  local SCode.Program p_1; Env.Env env;
    case(path,p) equation
      p_1 = SCodeUtil.translateAbsyn2SCode(p);
      (_,env) = Inst.makeEnvFromProgram(Env.emptyCache(),p_1, Absyn.IDENT(""));
      dep = getTotalProgramDep(AbsynDep.emptyDepends(),path,p,env);
    then dep;
  end matchcontinue;
end getTotalProgram2;

protected function getTotalProgramDep "Help function to getTotalProgram2"
  input AbsynDep.Depends dep;
  input Absyn.Path className;
  input Absyn.Program p;
  input Env.Env env;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(dep,className,p,env)
  local Absyn.Class cl; AbsynDep.AvlTree classUses; list<Absyn.Path> v;
    Option<Absyn.Path> optPath;
    Absyn.ElementSpec comp;

    case(dep,Absyn.FULLYQUALIFIED(className),p,env) then getTotalProgramDep(dep,className,p,env);
    /* If already added, skip to prevent infinite recursion */
    case(dep,className,p,env) equation
      _ = AbsynDep.getUses(dep,className);
      //print(Absyn.pathString(className));print(" allready added\n");
    then dep;

    /*Classes*/
    case(dep,className,p,env) equation
      cl = Interactive.getPathedClassInProgram(className,p);
      optPath = getClassScope(className);
      ((_,_,(dep,_,_))) = buildClassDependsVisitor((cl,optPath,(dep,p,env)));
     dep = getTotalProgramDep2(dep,className,p,env);
    then dep;

    /* constants */
    case(dep,className,p,env) equation
      comp = Interactive.getPathedComponentElementInProgram(className,p);
      optPath = getClassScope(className);
      optPath = extendScope(optPath,Absyn.pathLastIdent(className)) "a constant gets a 'scope' of its own";
      dep = buildClassDependsInEltSpec(false,comp,optPath,className,(dep,p,env,HashTable2.emptyHashTable()));
      dep = getTotalProgramDep2(dep,className,p,env);
    then dep;

    case(dep,className,p,env)  equation
     // print("GetTotalProgram for ");print(Absyn.pathString(className));print(" skipped \n");
      then dep;
  end matchcontinue;
end getTotalProgramDep;

protected function getTotalProgramDep2 "help function to getTotalProgramDep"
 input AbsynDep.Depends dep;
 input Absyn.Path className;
 input Absyn.Program p;
 input Env.Env env;
 output AbsynDep.Depends outDep;
 algorithm
   outDep := matchcontinue(dep,className,p,env)
   local AbsynDep.AvlTree classUses; list<Absyn.Path> v;
     case(dep as AbsynDep.DEPENDS(classUses,_),className as Absyn.IDENT(_),p,env) equation
      v = AbsynDep.avlTreeGet(classUses,className);
      dep = getTotalProgramDepLst(dep,v,p,env);
     then dep;
     case(dep, Absyn.IDENT(_),p,env) then dep;
     case(dep as AbsynDep.DEPENDS(classUses,_),className  as Absyn.QUALIFIED(_,_),p,env) equation
       v = AbsynDep.avlTreeGet(classUses,className);
       dep = getTotalProgramDepLst(dep,v,p,env);
       className = Absyn.stripLast(className);
       dep = getTotalProgramDep(dep,className,p,env);
     then dep;
     case(dep as AbsynDep.DEPENDS(classUses,_),className  as Absyn.QUALIFIED(_,_),p,env) equation
       className = Absyn.stripLast(className);
       dep = getTotalProgramDep(dep,className,p,env);
     then dep;
   end matchcontinue;
end getTotalProgramDep2;

protected function getTotalProgramDepLst "Help function to getTotalProgramDep"
  input AbsynDep.Depends dep;
  input list<Absyn.Path> classNameLst;
  input Absyn.Program p;
  input Env.Env env;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(dep,classNameLst,p,env)
  local Absyn.Path className;

    case(dep,{},p,env) then dep;

    case(dep,className::classNameLst,p,env) equation
      dep = getTotalProgramDep(dep,className,p,env);
      dep = getTotalProgramDepLst(dep,classNameLst,p,env);
    then dep;
  end matchcontinue;
end getTotalProgramDepLst;

protected function getClassScope "help function to getTotalProgramDep"
input Absyn.Path className;
output Option<Absyn.Path> scope;
algorithm
  scope := matchcontinue(className)
    local String id;
    case(Absyn.FULLYQUALIFIED(className)) then getClassScope(className);

    case(Absyn.IDENT(id)) then NONE;

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
  outOptPath := matchcontinue(optPath,id)
  local Absyn.Path p;
    case(NONE,id) then SOME(Absyn.IDENT(id));
    case(SOME(p),id) equation
      p = Absyn.joinPaths(p,Absyn.IDENT(id));
    then SOME(p);
  end matchcontinue;
end extendScope;

protected function addPathScope "Adds the scope to a path"
input Absyn.Path path;
input Option<Absyn.Path> scope;
output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(path,scope)
  local Absyn.Path scopePath;
    case(path,NONE) then path;
    case(path,SOME(scopePath)) then Absyn.joinPaths(scopePath,path);
  end matchcontinue;
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
  input Absyn.Program p;
  input Absyn.Path modelName;
  output Absyn.Program outP;
algorithm
  outP := matchcontinue(p,modelName)
  local String id; Absyn.TimeStamp timeStamp; Absyn.Path scope; Absyn.Class cl,cl2; Absyn.Program p2;

    case(p as Absyn.PROGRAM(globalBuildTimes=timeStamp),modelName as Absyn.IDENT(id)) equation
      cl = Interactive.getPathedClassInProgram(modelName,p);
    then Absyn.PROGRAM({cl},Absyn.TOP(),timeStamp);

    case(p as Absyn.PROGRAM(globalBuildTimes=timeStamp),modelName as Absyn.QUALIFIED(name=_)) equation
      cl2 = createTopLevelTotalClass(modelName);
      p = Absyn.PROGRAM({cl2},Absyn.TOP(),timeStamp);
    then p;
  end matchcontinue;
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
        case(_,Absyn.EXTENDS(path=path as Absyn.IDENT("ExternalObject"), elementArg=eltarg),optPath as SOME(cname2),cname,(d,p,env,ht)) equation
          d = AbsynDep.addDependency(d,cname2,Absyn.joinPaths(cname2,Absyn.IDENT("constructor")));
          d = AbsynDep.addDependency(d,cname2,Absyn.joinPaths(cname2,Absyn.IDENT("destructor")));
          d = buildClassDependsInElementargs(eltarg,optPath,cname,(d,p,env,ht));
        then d;

        case(_,Absyn.EXTENDS(path=path, elementArg=eltarg),optPath as SOME(cname2),cname,(d,p,env,ht)) equation
          usesName = absynMakeFullyQualified(path,optPath,cname,env,p);
          d = AbsynDep.addDependency(d,cname2,usesName);
          d = buildClassDependsInElementargs(eltarg,optPath,cname,(d,p,env,ht));
        then d;
        case(_,Absyn.COMPONENTS(typeSpec=typeSpec,components=citems,attributes=attr),optPath,cname,(d,p,env,ht)) equation
          d = buildClassDependsInTypeSpec(typeSpec,optPath,cname,(d,p,env,ht));
          d = buildClassDependsInElementAttr(attr,optPath,cname,(d,p,env,ht));
          d = buildClassDependsInComponentItems(citems,optPath,cname,(d,p,env,ht));
        then d;
        case(_,Absyn.IMPORT(import_,_),optPath,cname,(d,p,env,ht)) equation
          d = buildClassDependsInImport(import_,optPath,cname,(d,p,env,ht));
        then d;

        case(false,Absyn.CLASSDEF(class_=cl as Absyn.CLASS(name="equalityConstraint", body = classDef)),optPath,cname,(d,p,env,ht))
          equation
          d = AbsynDep.addDependency(d, cname, Absyn.joinPaths(cname,Absyn.IDENT("equalityConstraint")));
          then d;

        case(false,Absyn.CLASSDEF(class_=cl as Absyn.CLASS(name=id, body = classDef)),optPath,cname,(d,p,env,ht))
          /*
          equation
            env2 = getClassEnvNoElaborationScope(p,optPath,env);
            d = buildClassDependsInClassDef(classDef,optPath,Absyn.IDENT(id),(d,p,env2,ht));
          */
          then d;

        /* traverse inner classes only for redeclarations*/
        case(true,Absyn.CLASSDEF(class_=cl as Absyn.CLASS(name=id,body = classDef as Absyn.DERIVED(typeSpec=_))),optPath,cname,(d,p,env,ht))
          equation
          env2 = getClassEnvNoElaborationScope(p,optPath,env);
          d = buildClassDependsInClassDef(classDef,optPath,Absyn.IDENT(id),(d,p,env2,ht));
        then d;
    end matchcontinue;
end  buildClassDependsInEltSpec;

protected function buildClassDependsInComponentItems "build class dependencies from component items,
e.g. redeclaration modifiers, etc."
  input list<Absyn.ComponentItem> citems;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(citems,optPath,cname,dep)
    local
      AbsynDep.Depends d; Absyn.Program p; Env.Env env;
      Option<Absyn.Modification> optMod;
      Option<Absyn.Exp> optExp; Absyn.ArrayDim ad;
      HashTable2.HashTable ht;
    case({},optPath,cname,(d,p,env,ht)) then d;

    case(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification=optMod,arrayDim=ad),condition=optExp)::citems,optPath,cname,(d,p,env,ht)) equation
      d = buildClassDependsInModificationOpt(optMod,optPath,cname,(d,p,env,ht));
      d = buildClassDependsInOptExp(optExp,optPath,cname,(d,p,env,ht));
      d = buildClassDependsinArrayDim(ad,optPath,cname,(d,p,env,ht));
      d = buildClassDependsInComponentItems(citems,optPath,cname,(d,p,env,ht));
    then d;
    case(_,optPath,cname,(d,p,env,ht)) then d;
  end matchcontinue;
end buildClassDependsInComponentItems;

protected function buildClassDependsInModificationOpt "build class dependencies from Option<Modification>"
  input Option<Absyn.Modification> optMod;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(optMod,optPath,cname,dep)
  local Option<Absyn.Exp> optExp; Absyn.Modification mod;
    AbsynDep.Depends d; Absyn.Program p; Env.Env env;
    list<Absyn.ElementArg> eltArgs;HashTable2.HashTable ht;
    case(NONE, optPath,cname,(d,p,env,ht)) then d;
    case(SOME(mod),optPath,cname,(d,p,env,ht)) equation
      d = buildClassDependsInModification(mod,optPath,cname,(d,p,env,ht));
    then d;
  end matchcontinue;
end buildClassDependsInModificationOpt;

protected function buildClassDependsInModification "build class dependencies from Modification"
  input Absyn.Modification mod;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(mod,optPath,cname,dep)
  local Option<Absyn.Exp> optExp;
    AbsynDep.Depends d; Absyn.Program p; Env.Env env;
    list<Absyn.ElementArg> eltArgs;
    HashTable2.HashTable ht;
    case(Absyn.CLASSMOD(eltArgs,optExp),optPath,cname,(d,p,env,ht)) equation
      d = buildClassDependsInElementargs(eltArgs,optPath,cname,(d,p,env,ht));
      d = buildClassDependsInOptExp(optExp,optPath,cname,(d,p,env,ht));
    then d;
  end matchcontinue;
end buildClassDependsInModification;

protected function buildClassDependsInElementargs "build class dependencies from elementargs"
  input list<Absyn.ElementArg> eltArgs;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(eltArgs,optPath,cname,dep)
  local Option<Absyn.Exp> expOpt;
    AbsynDep.Depends d; Absyn.Program p; Env.Env env;
    Absyn.Modification mod;
    Absyn.ElementSpec eltSpec;
    HashTable2.HashTable ht;
    case({},optPath,cname,(d,p,env,ht)) then d;
    case(Absyn.MODIFICATION(modification=SOME(mod))::eltArgs,optPath,cname,(d,p,env,ht)) equation
      d = buildClassDependsInModification(mod,optPath,cname,(d,p,env,ht));
      d = buildClassDependsInElementargs(eltArgs,optPath,cname,(d,p,env,ht));
    then d;
    case(Absyn.REDECLARATION(elementSpec = eltSpec)::eltArgs,optPath,cname,(d,p,env,ht)) equation
      d = buildClassDependsInEltSpec(true,eltSpec,optPath,cname,(d,p,env,ht));
      d = buildClassDependsInElementargs(eltArgs,optPath,cname,(d,p,env,ht));
    then d;
    case(_::eltArgs,optPath,cname,(d,p,env,ht)) equation
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
  outDep := matchcontinue(imp,optPath,cname,dep)
    local
      Absyn.Path usesName,path,cname2;
      AbsynDep.Depends d; Absyn.Program p; Env.Env env;
      HashTable2.HashTable ht;
    case(Absyn.NAMED_IMPORT(path=path),optPath as SOME(cname2),cname,(d,p,env,ht))
      equation
        usesName = absynCheckFullyQualified(path,optPath,cname,env,p);
        d = AbsynDep.addDependency(d,cname2,usesName);
      then d;

    case(Absyn.QUAL_IMPORT(path),optPath as SOME(cname2),cname,(d,p,env,ht))
      equation
        usesName = absynCheckFullyQualified(path,optPath,cname,env,p);
        d = AbsynDep.addDependency(d,cname2,usesName);
      then d;

    case(Absyn.UNQUAL_IMPORT(path),optPath as SOME(cname2),cname,(d,p,env,ht))
      equation
        usesName = absynCheckFullyQualified(path,optPath,cname,env,p);
        d = AbsynDep.addDependency(d,cname2,usesName);
      then d;
  end matchcontinue;
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
     Absyn.Path fq,usesName,cname2;
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
  input list<Absyn.ClassPart> parts;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(parts,optPath,cname,dep)
 local
   list<Absyn.ElementItem> elts;
   list<Absyn.EquationItem> eqns;
   list<Absyn.AlgorithmItem> algs;
   AbsynDep.Depends d; Absyn.Program p; Env.Env env;
   HashTable2.HashTable ht;
   case({},optPath,cname,(d,p,env,ht)) then d;

   case (Absyn.PUBLIC(contents = elts)::parts,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinElts(elts,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

   case (Absyn.PROTECTED(contents = elts)::parts,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinElts(elts,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

   case (Absyn.EQUATIONS(contents = eqns)::parts,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

    case (Absyn.INITIALEQUATIONS(contents = eqns)::parts,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

    case (Absyn.ALGORITHMS(contents = algs)::parts,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinAlgs(algs,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

    case (Absyn.INITIALALGORITHMS(contents = algs)::parts,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinAlgs(algs,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;

    case(Absyn.EXTERNAL(_,_)::parts,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinParts(parts,optPath,cname,(d,p,env,ht));
   then d;
  end matchcontinue;
end buildClassDependsinParts;

protected function buildClassDependsinAlgs "Build class dependencies from algorithms"
  input  list<Absyn.AlgorithmItem> algs;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(algs,optPath,cname,dep)
   local  AbsynDep.Depends d; Absyn.Program p; Env.Env env;
     Absyn.Algorithm alg;
     HashTable2.HashTable ht;
   case({},optPath,cname,(d,p,env,ht)) then d;
   case(Absyn.ALGORITHMITEM(algorithm_=alg)::algs,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInAlg(alg,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(algs,optPath,cname,(d,p,env,ht));
   then d;
   case(_::algs,optPath,cname,(d,p,env,ht)) equation
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
   case(Absyn.ALG_ASSIGN(e1,e2),optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e2,optPath,cname,(d,p,env,ht));
   then d;
   case(Absyn.ALG_IF(e1,tb,elsifb,fb),optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(tb,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(fb,optPath,cname,(d,p,env,ht));
     d = buildClassDependsInAlgElseifBranch(elsifb,optPath,cname,(d,p,env,ht));
   then d;

   case(Absyn.ALG_FOR({(_,SOME(e1))},body),optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(body,optPath,cname,(d,p,env,ht));
    then d;

   /* adrpo: TODO! add full support for ForIterators*/
   case(Absyn.ALG_FOR({(_,NONE)},body),optPath,cname,(d,p,env,ht)) equation
     /* d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht)); */
     d = buildClassDependsinAlgs(body,optPath,cname,(d,p,env,ht));
    then d;

   case(Absyn.ALG_WHILE(e1,body),optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(body,optPath,cname,(d,p,env,ht));
    then d;

   case(Absyn.ALG_WHEN_A(e1,body,elsifb),optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(body,optPath,cname,(d,p,env,ht));
     d = buildClassDependsInAlgElseifBranch(elsifb,optPath,cname,(d,p,env,ht));
   then d;

   case(Absyn.ALG_NORETCALL(cr,funcargs),optPath,cname,(d,p,env,ht)) equation
    d = buildClassDependsInExp(Absyn.CALL(cr,funcargs),optPath,cname,(d,p,env,ht));
   then d;
   case(_,optPath,cname,(d,p,env,ht)) then d;
  end matchcontinue;
end buildClassDependsInAlg;

protected function buildClassDependsInAlgElseifBranch "help function to buildClassDependsInAlg"
  input list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> elsifb;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(elsifb,optPath,cname,dep)
 local AbsynDep.Depends d; Absyn.Program p; Env.Env env;
   Absyn.Exp e;
   list<Absyn.AlgorithmItem> eb;
   HashTable2.HashTable ht;
   case({},_,_,(d,_,_,_)) then d;

   case((e,eb)::elsifb,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinAlgs(eb,optPath,cname,(d,p,env,ht));
     d = buildClassDependsInAlgElseifBranch(elsifb,optPath,cname,(d,p,env,ht));
   then d;
 end matchcontinue;
end buildClassDependsInAlgElseifBranch;

public function extractProgram " extract a sub-program with the classes that are in the avltree passed as argument"
  input Absyn.Program p;
  input AbsynDep.AvlTree tree;
  output Absyn.Program outP;
algorithm
((outP,_,_)) := Interactive.traverseClasses(p, NONE(), extractProgramVisitor, (tree,{},{}), true) "traverse protected" ;
end extractProgram;

protected function buildClassDependsinEqns "Build class dependencies from equations"
  input  list<Absyn.EquationItem> eqns;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(eqns,optPath,cname,dep)
   local  AbsynDep.Depends d; Absyn.Program p; Env.Env env;HashTable2.HashTable ht;
     Absyn.Exp e,e1,e2;
     list<Absyn.EquationItem> teqns,feqns,whenEqns;
     list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> elseifeqns,elseWhenEqns;
     Absyn.FunctionArgs fargs; Absyn.ComponentRef cr;
     Absyn.Path path,usesName,cname2;
     HashTable2.HashTable ht;
     Absyn.ForIterators forIter;
   case({},optPath,cname,(d,p,env,ht)) then d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_IF(e,teqns,elseifeqns,feqns))::eqns,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinElseIfEqns(elseifeqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinEqns(teqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinEqns(feqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
   then d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_EQUALS(e1,e2))::eqns,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e1,optPath,cname,(d,p,env,ht));
     d = buildClassDependsInExp(e2,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
   then d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(_,_))::eqns,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
   then d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_FOR({(_,SOME(e))},feqns))::eqns,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinEqns(feqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
   then d;

   /* adrpo: TODO! add the full ForIterators support */
   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_FOR({(_,NONE)},feqns))::eqns,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinEqns(feqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
   then d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_WHEN_E(e,whenEqns,elseWhenEqns))::eqns,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinEqns(whenEqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinElseIfEqns(elseWhenEqns,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
   then d;

   case(Absyn.EQUATIONITEM(equation_ = Absyn.EQ_NORETCALL(cr,fargs))::eqns,optPath as SOME(cname2),cname,(d,p,env,ht)) equation
     d = buildClassDependsInFuncargs(fargs,optPath,cname,(d,p,env,ht));
     path = Absyn.crefToPath(cr);
     usesName = absynMakeFullyQualified(path,optPath,cname,env,p);
     cname = addPathScope(cname,optPath);
     d = AbsynDep.addDependency(d,cname2,usesName);
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
   then d;
   case(_::eqns,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
   then d;
 end matchcontinue;
end buildClassDependsinEqns;

protected function buildClassDependsinElseIfEqns ""
  input list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> elseifeqns;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(elseifeqns,optPath,cname,dep)
   local
     AbsynDep.Depends d;
     Absyn.Program p;
     Env.Env env;
     Absyn.Exp e;
     list<Absyn.EquationItem> eqns;
     HashTable2.HashTable ht;
   case({},optPath,cname,(d,p,env,ht)) then d;

   case((e,eqns)::elseifeqns,optPath,cname,(d,p,env,ht))
     equation
       d = buildClassDependsinEqns(eqns,optPath,cname,(d,p,env,ht));
       d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
       d = buildClassDependsinElseIfEqns(elseifeqns,optPath,cname,(d,p,env,ht));
     then d;
 end matchcontinue;
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
 outDep := matchcontinue(fargs,optPath,cname,dep)
 local list<Absyn.Exp> args;
   list<Absyn.NamedArg> nargs;
   AbsynDep.Depends d; Absyn.Program p; Env.Env env;
   HashTable2.HashTable ht;
   case (Absyn.FUNCTIONARGS(args,nargs),optPath,cname,(d,p,env,ht)) equation
      d = buildClassDependsInExpList(args,optPath,cname,(d,p,env,ht));
      d = buildClassDependsInNamedArgs(nargs,optPath,cname,(d,p,env,ht));
   then d;
  end matchcontinue;
end buildClassDependsInFuncargs;

protected function buildClassDependsInNamedArgs "build class dependencies from named arguments"
  input list<Absyn.NamedArg> nargs;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(nargs,optPath,cname,dep)
 local list<Absyn.Exp> args;
   AbsynDep.Depends d; Absyn.Program p; Env.Env env;
   Absyn.Exp e;
   HashTable2.HashTable ht;
   case({},optPath,cname,(d,p,env,ht)) then d;

   case(Absyn.NAMEDARG(_,e)::nargs,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
     d = buildClassDependsInNamedArgs(nargs,optPath,cname,(d,p,env,ht));
   then d;
  end matchcontinue;
end buildClassDependsInNamedArgs;


protected function buildClassDependsInExpVisitor "visitor function fo building class dependencies from Absyn.Exp"
  input tuple<Absyn.Exp,tuple<Option<Absyn.Path>,Absyn.Path,tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable>>> tpl;
  output tuple<Absyn.Exp,tuple<Option<Absyn.Path>,Absyn.Path,tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable>>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
  local Option<Absyn.Path> optPath;
    Absyn.Path cname,path,usesName,cname2;
    AbsynDep.Depends d;
    Absyn.Program p;
    Env.Env env;
    Absyn.Exp e;
    Absyn.ComponentRef cr;
    HashTable2.HashTable ht;
    case((e as Absyn.CALL(cr,_),(optPath as SOME(cname2),cname,(d,p,env,ht)))) equation
      path = Absyn.crefToPath(cr);
      usesName = absynMakeFullyQualified(path,optPath,cname,env,p);
      d = AbsynDep.addDependency(d,cname2,usesName);
    then ((e,(optPath,cname,(d,p,env,ht))));

    /* constants */
    case((e as Absyn.CREF(cr),(optPath as SOME(cname2),cname,(d,p,env,ht))))
      local String compString;
        list<DAE.Exp> dbgList;
      equation
      compString = Absyn.printComponentRefStr(cr);
      cr = Absyn.crefStripLastSubs(cr);
      path = Absyn.crefToPath(cr);
      failure(_ = HashTable2.get(DAE.CREF_IDENT(compString, DAE.ET_OTHER(),{}),ht)) "do not add local variables to depndencies";
      (usesName as Absyn.FULLYQUALIFIED(_)) = absynMakeFullyQualified(path,optPath,cname,env,p);
      d = AbsynDep.addDependency(d,cname2,usesName);
    then ((e,(optPath,cname,(d,p,env,ht))));

    case(tpl) then tpl;
  end matchcontinue;
end buildClassDependsInExpVisitor;

protected function buildClassDependsinArrayDimOpt " help function to e.g buildClassDependsInTypeSpec"
  input Option<Absyn.ArrayDim> adOpt;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(adOpt,optPath,cname,dep)
   local AbsynDep.Depends d; Absyn.Program p; Env.Env env; Absyn.ArrayDim ad;HashTable2.HashTable ht;
   case(NONE,optPath,cname,(d,p,env,ht)) then d;
   case(SOME(ad),optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsinArrayDim(ad,optPath,cname,(d,p,env,ht));
   then d;
 end matchcontinue;
end buildClassDependsinArrayDimOpt;

protected function buildClassDependsInExpList "build class dependencies from exp list"
  input list<Absyn.Exp> expl;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(expl,optPath,cname,dep)
    local
      AbsynDep.Depends d; Absyn.Program p; Env.Env env;
      Absyn.Exp e;
      HashTable2.HashTable ht;
      case({},optPath,cname,(d,p,env,ht)) then d;

      case(e::expl,optPath,cname,(d,p,env,ht)) equation
        d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
        d = buildClassDependsInExpList(expl,optPath,cname,(d,p,env,ht));
      then d;
  end matchcontinue;
end buildClassDependsInExpList;


protected function buildClassDependsinElts "help function to buildClassDependsinParts"
  input list<Absyn.ElementItem> elts;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
 outDep := matchcontinue(elts,optPath,cname,dep)
 local Absyn.ElementSpec eltSpec;
   AbsynDep.Depends d; Absyn.Program p; Env.Env env;HashTable2.HashTable ht;
   case({},optPath,cname,(d,p,env,ht)) then d;

   case(Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=eltSpec))::elts,optPath,cname,(d,p,env,ht)) equation
     d = buildClassDependsInEltSpec(false,eltSpec,optPath,cname,(d,p,env,ht));
     d = buildClassDependsinElts(elts,optPath,cname,(d,p,env,ht));
   then d;
   case(_::elts,optPath,cname,(d,p,env,ht)) equation
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
  outDep := matchcontinue(e,optPath,cname,dep)
  local AbsynDep.Depends d; Absyn.Program p; Env.Env env; HashTable2.HashTable ht;
    case(e,optPath,cname,(d,p,env,ht)) equation
      ((_,(_,_,(outDep,_,_,_)))) = Absyn.traverseExp(e,buildClassDependsInExpVisitor,(optPath,cname,(d,p,env,ht)));
     then outDep;
  end matchcontinue;
end buildClassDependsInExp;

protected function buildClassDependsInClassDef "help function to buildClassDependsVisitor"
  input Absyn.ClassDef cdef;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(cdef,optPath,cname,dep)
  local Absyn.TypeSpec typeSpec;
    Absyn.Program prg; AbsynDep.Depends d; Env.Env env;
    list<Absyn.ClassPart> parts; Absyn.ElementAttributes attr;
    HashTable2.HashTable ht;
    case (Absyn.DERIVED(typeSpec=typeSpec,attributes=attr),optPath,cname,(d,prg,env,ht)) equation
      d = buildClassDependsInTypeSpec(typeSpec,optPath,cname,(d,prg,env,ht));
      d = buildClassDependsInElementAttr(attr,optPath,cname,(d,prg,env,ht));
    then d;

    case (Absyn.PARTS(classParts=parts),optPath,cname,(d,prg,env,ht)) equation
      ht = createLocalVariableStruct(parts,ht);
      d = buildClassDependsinParts(parts,optPath,cname,(d,prg,env,ht));
    then d;

    case(Absyn.CLASS_EXTENDS(parts=parts),optPath,cname,(d,prg,env,ht)) equation
      ht = createLocalVariableStruct(parts,ht);
      d = buildClassDependsinParts(parts,optPath,cname,(d,prg,env,ht));
    then d;

    case(Absyn.ENUMERATION(enumLiterals=_),_,_,(d,_,_,_)) then d;

   /* case(_,_,_,_) equation
      print("buildClassDependsInClassDef failed\n");
    then fail();*/

  end matchcontinue;
end buildClassDependsInClassDef;


protected function buildClassDependsInTypeSpec "help function to e.g. buildClassDependsInClassDef"
  input Absyn.TypeSpec typeSpec;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(typeSpec,optPath,cname,dep)
  local Absyn.Path path,usesName,cname2;
    AbsynDep.Depends d; Absyn.Program p; Env.Env env; Option<Absyn.ArrayDim> adOpt;HashTable2.HashTable ht;
    case(Absyn.TPATH(path = path,arrayDim=adOpt),optPath as SOME(cname2),cname,(d,p,env,ht)) equation
      d = buildClassDependsinArrayDimOpt(adOpt,optPath,cname,(d,p,env,ht));
      usesName = absynMakeFullyQualified(path,optPath,cname,env,p);
      d = AbsynDep.addDependency(d,cname2,usesName);
    then d;
  end matchcontinue;
end buildClassDependsInTypeSpec;

protected function buildClassDependsInElementAttr "help function to buildClassDependsVisitor"
  input Absyn.ElementAttributes eltAttr;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(eltAttr,optPath,cname,dep)
  local Absyn.Path path,usesName,cname2;
    AbsynDep.Depends d; Absyn.Program p; Env.Env env; Absyn.ArrayDim ad;
    HashTable2.HashTable ht;
    case(Absyn.ATTR(arrayDim=ad),optPath,cname,(d,p,env,ht)) equation
      d = buildClassDependsinArrayDim(ad,optPath,cname,(d,p,env,ht));
    then d;
  end matchcontinue;
end buildClassDependsInElementAttr;

protected function buildClassDependsInOptExp "build class dependencies from Option<Absyn.Exp>"
  input Option<Absyn.Exp> optExp;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env, HashTable2.HashTable > dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(optExp,optPath,cname,dep)
  local AbsynDep.Depends d; Absyn.Program p; Env.Env env; Absyn.Exp e;HashTable2.HashTable ht;
    case(SOME(e),optPath,cname,(d,p,env,ht)) then buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
    case(NONE,optPath,cname,(d,p,env,ht)) then d;
  end matchcontinue;
end buildClassDependsInOptExp;

protected function buildClassDependsinArrayDim " help function to e.g buildClassDependsInTypeSpec"
  input Absyn.ArrayDim ad;
  input Option<Absyn.Path> optPath;
  input Absyn.Path cname;
  input tuple<AbsynDep.Depends,Absyn.Program,Env.Env,HashTable2.HashTable> dep;
  output AbsynDep.Depends outDep;
algorithm
  outDep := matchcontinue(ad,optPath,cname,dep)
    local
      AbsynDep.Depends d;
      Absyn.Program p;
      Env.Env env;
      Absyn.Exp e;
      HashTable2.HashTable ht;
    case({},optPath,cname,(d,p,env,ht)) then d;
    case(Absyn.NOSUB()::ad,optPath,cname,(d,p,env,ht)) then buildClassDependsinArrayDim(ad,optPath,cname,(d,p,env,ht));
    case(Absyn.SUBSCRIPT(e)::ad,optPath,cname,(d,p,env,ht)) equation
      d = buildClassDependsInExp(e,optPath,cname,(d,p,env,ht));
      d = buildClassDependsinArrayDim(ad,optPath,cname,(d,p,env,ht));
    then d;
  end matchcontinue;
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
  case({},inTable) then inTable;
  case((part as Absyn.PUBLIC(cont))::parts,inTable)
    equation
      table1 = createLocalVariableStruct(parts,inTable);
      table2 = createLocalVariableStruct2(cont,table1);
    then
      table2;
  case((part as Absyn.PROTECTED(cont))::parts,inTable)
    equation
      table1 = createLocalVariableStruct(parts,inTable);
      table2 = createLocalVariableStruct2(cont,table1);
    then
      table2;
  case(_::parts,inTable)
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
algorithm _ := matchcontinue(inElem,inTable)
  local
    list<Absyn.ElementItem> elemis;
    HashTable2.HashTable table1,table2;
    String id;
    Absyn.ElementSpec spec;
  case({},inTable) then inTable;
  case((Absyn.ELEMENTITEM(Absyn.ELEMENT(name = id,specification=spec)))::elemis,inTable)
    equation
      table1 = createLocalVariableStruct2(elemis,inTable);
      table2 = createLocalVariableStruct3(spec,table1);
    then
      table2;
  case((Absyn.ELEMENTITEM(Absyn.TEXT(info = _)))::elemis,inTable)
    equation
      table1 = createLocalVariableStruct2(elemis,inTable);
    then table1;
  case((Absyn.ANNOTATIONITEM(_))::elemis,inTable)
    equation
      table1 = createLocalVariableStruct2(elemis,inTable);
    then
      table1;
  case(_,_) equation print("createLocalVariableStruct2 failed\n"); then fail();
  end matchcontinue;
end createLocalVariableStruct2;

protected function createLocalVariableStruct3 "
Author BZ 2008-04 Helper function for createLocalVariableStruct
"
  input Absyn.ElementSpec inSpec;
  input HashTable2.HashTable inTable;
  output HashTable2.HashTable outTable;
algorithm _ := matchcontinue(inSpec,inTable)
  local list<Absyn.ComponentItem> comps; HashTable2.HashTable table1;
  case(Absyn.COMPONENTS(components = comps),inTable)
    equation
      table1 = createLocalVariableStruct4(comps,inTable);
      then
        table1;
  case(Absyn.COMPONENTS(components = comps),inTable) equation print(" failure in createLocalVariableStruct3\n"); then fail();
  case(_,inTable) then inTable;
end matchcontinue;
end createLocalVariableStruct3;

protected function createLocalVariableStruct4 "
Author BZ 2008-04 Helper function for createLocalVariableStruct
"
  input list<Absyn.ComponentItem> inComponents;
  input HashTable2.HashTable inTable;
  output HashTable2.HashTable outTable;
algorithm _ := matchcontinue(inComponents,inTable)
  local list<Absyn.ComponentItem> comps; String id; HashTable2.HashTable table1,table2;
    case({}, inTable) then inTable;
  case((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id)))::comps,inTable)
    equation
      table1 = HashTable2.add((DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}),DAE.ICONST(0)),inTable);
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
  fqPath := matchcontinue(path,scope,className,env,p)
  local
    Env.Env cenv;
    SCode.Program p_1;
    Absyn.Path scope2,path2;
    case(path,_,_,env,p) equation
      (_,fqPath) = Inst.makeFullyQualified(Env.emptyCache(),env, path);
    then fqPath;

   /* case(path,SOME(path2),className,env,p) equation
      print("chekc FQ failed for ");print(Absyn.pathString(path));print("in scope ");
      print(Absyn.pathString(path2));print("\n");
    then fail();

    case(path,NONE,className,env,p) equation
      print("check FQ failed for ");print(Absyn.pathString(path));print("in top scope\n");
      print("env:");print(Env.printEnvStr(env));
    then fail();
    */
  end matchcontinue;
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
  fqPath := matchcontinue(path,scope,className,env,p)
  local
    Env.Env cenv;
    SCode.Program p_1;
    Absyn.Path scope2,path2;

    case(path,scope,className,env,p) equation
      (_,fqPath) = Inst.makeFullyQualified(Env.emptyCache(),env, path);
    then fqPath;

/*    case(path,SOME(path2),className,env,p) equation
      print("FQ failed for ");print(Absyn.pathString(path));print("in scope ");
      print(Absyn.pathString(path2));print("\n");
    then fail();

    case(path,NONE,className,env,p) equation
      print("FQ failed for ");print(Absyn.pathString(path));print("in top scope\n");
      print("env:");print(Env.printEnvStr(env));
    then fail();
  */
  end matchcontinue;
end absynMakeFullyQualified;

protected function getClassEnvNoElaborationScope "uses getClassEnvNoElaboration if in a scope, otherwise return top env"
input Absyn.Program p;
input Option<Absyn.Path> optPath;
input Env.Env env;
output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(p,optPath,env)
  local Absyn.Path path;
    case(p,NONE,env) then env;
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

   where partial instantiation fails since cardinality(p) can not be determined.
"
  input Absyn.Program p;
  input Absyn.Path p_class;
  input Env.Env env;
  output Env.Env env_2;
  SCode.Class cl;
  String id;
  Boolean encflag;
  SCode.Restriction restr;
  list<Env.Frame> env_1,env2;
  ClassInf.State ci_state;
  Real t1,t2;
  Env.Cache cache;
algorithm
  env_2 := matchcontinue(p,p_class,env)
/* First try partial instantiation */
    case(p,p_class,env) equation
      (cache,(cl as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = Lookup.lookupClass(Env.emptyCache(),env, p_class, false);
      env2 = Env.openScope(env_1, encflag, SOME(id), Env.restrictionToScopeType(restr));
      ci_state = ClassInf.start(restr, Env.getEnvName(env2));
      (cache,env_2,_,_) = Inst.partialInstClassIn(cache, env2, InnerOuter.emptyInstHierarchy,
                                                  DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
                                                  ci_state, cl, false, {});
    then env_2;
    case(p,p_class,env) equation
      (cache,(cl as SCode.CLASS(name=id,encapsulatedPrefix=encflag,restriction=restr)),env_1) = Lookup.lookupClass(Env.emptyCache(),env, p_class, false);
      env2 = Env.openScope(env_1, encflag, SOME(id), Env.restrictionToScopeType(restr));
      ci_state = ClassInf.start(restr, Env.getEnvName(env2));
      (cache,env_2,_,_,_,_,_,_,_,_,_,_) = Inst.instClassIn(cache,env2, InnerOuter.emptyInstHierarchy,
        UnitAbsyn.noStore,DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet,
        ci_state, cl, false, {},false, Inst.INNER_CALL, ConnectionGraph.EMPTY,NONE);
    then env_2;
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
((_,_,(_,outClasses,outPaths))) := Interactive.traverseClasses(p, NONE, extractProgramVisitor, (tree,{},{}), true) "traverse protected" ;
end extractProgram2;

protected function extractProgramVisitor "Visitor function to extractProgram"
  input tuple<Absyn.Class, Option<Absyn.Path>,tuple<AbsynDep.AvlTree,list<Absyn.Class>,list<Option<Absyn.Path>>>> inTpl;
  output tuple<Absyn.Class, Option<Absyn.Path>,tuple<AbsynDep.AvlTree,list<Absyn.Class>,list<Option<Absyn.Path>>>> outTpl;
algorithm
 outTpl := matchcontinue(inTpl)
 local Absyn.Path path; Absyn.Class cl; String id; AbsynDep.AvlTree tree; list<Absyn.Class> cls; list<Option<Absyn.Path>> pts;
   case((cl as Absyn.CLASS(name=id),NONE,(tree,cls,pts))) equation
     _ = AbsynDep.avlTreeGet(tree,Absyn.IDENT(id));
    then ((cl,NONE,(tree,cl::cls,NONE::pts)));
   case((cl as Absyn.CLASS(name=id),SOME(path),(tree,cls,pts))) equation
     _ = AbsynDep.avlTreeGet(tree,Absyn.joinPaths(path,Absyn.IDENT(id)));
   then ((cl,SOME(path),(tree,cl::cls,SOME(path)::pts)));
 end matchcontinue;
end extractProgramVisitor;

protected function createTopLevelTotalClass "Creates a top level total class"
  input Absyn.Path modelName;
  output Absyn.Class cl;
protected
String classStr,classStr2; Absyn.Info info; Absyn.ElementSpec elementspec;
algorithm
  classStr:= Absyn.pathString(modelName);
  classStr2 := System.stringReplace(classStr,".","_");
  info := Absyn.INFO("",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0));
  elementspec := Absyn.EXTENDS(modelName,{},NONE());
  cl := Absyn.CLASS(classStr2,false,false,false,Absyn.R_MODEL(),
    Absyn.PARTS({Absyn.PUBLIC({Absyn.ELEMENTITEM(
      Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"",elementspec,info,NONE)
    )})},NONE),info);
end createTopLevelTotalClass;

end Dependency;
