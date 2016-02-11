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

encapsulated package GlobalScriptUtil
" file:        GlobalScriptUtil.mo
  package:     GlobalScriptUtil
  description: Utility functions for the scripting types.

"

public import Absyn;
public import DAE;
public import FCore;
public import GlobalScript;
public import Values;

protected import CevalFunction;
protected import ComponentReference;
protected import Error;
protected import FGraph;
protected import List;
protected import Lookup;
protected import Inst;
protected import SCode;
protected import SCodeUtil;

public function addVarsToSymboltable
  "Adds a list of variables to the interactive symboltable."
  input list<DAE.ComponentRef> inCref;
  input list<Values.Value> inValues;
  input FCore.Graph inEnv;
  input GlobalScript.SymbolTable inSymbolTable;
  output GlobalScript.SymbolTable outSymbolTable;
algorithm
  outSymbolTable := List.threadFold1(inCref, inValues, addVarToSymboltable,
    inEnv, inSymbolTable);
end addVarsToSymboltable;

public function addVarToSymboltable
  "Adds a variable to the interactive symboltable."
  input DAE.ComponentRef inCref;
  input Values.Value inValue;
  input FCore.Graph inEnv;
  input GlobalScript.SymbolTable inSymbolTable;
  output GlobalScript.SymbolTable outSymbolTable;
protected
  list<GlobalScript.Variable> vars;
algorithm
  GlobalScript.SYMBOLTABLE(lstVarVal = vars) := inSymbolTable;
  vars := addVarToVarList(inCref, inValue, inEnv, vars);
  outSymbolTable := setSymbolTableVars(vars, inSymbolTable);
end addVarToSymboltable;

public function appendVarToSymboltable
"Appends a variable to the interactive symbol table.
 Compared to addVarToSymboltable, this function does
 not search for the identifier, it adds the variable
 to the beginning of the list.
 Used in for example iterators in for statements."
  input Absyn.Ident inIdent;
  input Values.Value inValue;
  input DAE.Type inType;
  input GlobalScript.SymbolTable inSymbolTable;
  output GlobalScript.SymbolTable outSymbolTable;
protected
  list<GlobalScript.Variable> vars;
algorithm
  GlobalScript.SYMBOLTABLE(lstVarVal = vars) := inSymbolTable;
  vars := GlobalScript.IVAR(inIdent, inValue, inType) :: vars;
  outSymbolTable := setSymbolTableVars(vars, inSymbolTable);
end appendVarToSymboltable;

public function deleteVarFromSymboltable
  input Absyn.Ident inIdent;
  input GlobalScript.SymbolTable inSymbolTable;
  output GlobalScript.SymbolTable outSymbolTable;
protected
  list<GlobalScript.Variable> vars;
algorithm
  GlobalScript.SYMBOLTABLE(lstVarVal = vars) := inSymbolTable;
  vars := deleteVarFromVarlist(inIdent, vars);
  outSymbolTable := setSymbolTableVars(vars, inSymbolTable);
end deleteVarFromSymboltable;

protected function setSymbolTableVars
  input list<GlobalScript.Variable> inVars;
  input GlobalScript.SymbolTable inSymbolTable;
  output GlobalScript.SymbolTable outSymbolTable;
protected
  Absyn.Program ast;
  Option<SCode.Program> exp_ast;
  list<GlobalScript.InstantiatedClass> cls;
  list<GlobalScript.CompiledCFunction> comp_funcs;
  list<GlobalScript.LoadedFile> files;
algorithm
  GlobalScript.SYMBOLTABLE(ast, exp_ast, cls, _, comp_funcs, files) := inSymbolTable;
  outSymbolTable := GlobalScript.SYMBOLTABLE(ast, exp_ast, cls, inVars, comp_funcs, files);
end setSymbolTableVars;

public function setSymbolTableAST
  input GlobalScript.SymbolTable inSymTab;
  input Absyn.Program inAST;
  output GlobalScript.SymbolTable outSymTab;
algorithm
  outSymTab := match(inSymTab, inAST)
    local
      list<GlobalScript.InstantiatedClass> i;
      list<GlobalScript.Variable> v;
      list<GlobalScript.CompiledCFunction> c;
      list<GlobalScript.LoadedFile> l;
    case (GlobalScript.SYMBOLTABLE(instClsLst = i,
                      lstVarVal = v, compiledFunctions = c, loadedFiles = l), _)
      then GlobalScript.SYMBOLTABLE(inAST, NONE(), i, v, c, l);
  end match;
end setSymbolTableAST;

public function getSymbolTableAST
  input GlobalScript.SymbolTable inSymTab;
  output Absyn.Program outAST;
algorithm
  outAST := match(inSymTab)
    case (GlobalScript.SYMBOLTABLE(ast = outAST)) then outAST;
  end match;
end getSymbolTableAST;

protected function deleteVarFromVarlist
"deletes the first variable found"
  input Absyn.Ident inIdent;
  input list<GlobalScript.Variable> inVariableLst;
  output list<GlobalScript.Variable> outVariableLst;
algorithm
  outVariableLst := matchcontinue (inIdent,inVariableLst)
    local
      String ident,id2;
      list<GlobalScript.Variable> rest, rest2;
      GlobalScript.Variable var;

    case (_,{})
      then {};

    case (ident,(GlobalScript.IVAR(varIdent = id2) :: rest))
      equation
        true = stringEq(ident, id2);
      then
        rest;

    case (ident,var::rest)
      equation
        rest2 = deleteVarFromVarlist(ident, rest);
      then
        var::rest2;
  end matchcontinue;
end deleteVarFromVarlist;

protected function addVarToVarList
  "Assigns a value to a variable with a specific identifier."
  input DAE.ComponentRef inCref;
  input Values.Value inValue;
  input FCore.Graph inEnv;
  input list<GlobalScript.Variable> inVariables;
  output list<GlobalScript.Variable> outVariables;
protected
  Boolean found;
algorithm
  (outVariables, found) :=
    List.findMap3(inVariables, addVarToVarList2, inCref, inValue, inEnv);
  outVariables := addVarToVarList4(found, inCref, inValue, outVariables);
end addVarToVarList;

protected function addVarToVarList2
  input GlobalScript.Variable inOldVariable;
  input DAE.ComponentRef inCref;
  input Values.Value inValue;
  input FCore.Graph inEnv;
  output GlobalScript.Variable outVariable;
  output Boolean outFound;
protected
  Absyn.Ident id1, id2;
algorithm
  GlobalScript.IVAR(varIdent = id1) := inOldVariable;
  DAE.CREF_IDENT(ident = id2) := inCref;
  outFound := stringEq(id1, id2);
  outVariable := addVarToVarList3(outFound, inOldVariable, inCref, inValue, inEnv);
end addVarToVarList2;

protected function addVarToVarList3
  input Boolean inFound;
  input GlobalScript.Variable inOldVariable;
  input DAE.ComponentRef inCref;
  input Values.Value inValue;
  input FCore.Graph inEnv;
  output GlobalScript.Variable outVariable;
algorithm
  outVariable := match(inFound, inOldVariable, inCref, inValue, inEnv)
    local
      Absyn.Ident id;
      Values.Value val;
      DAE.Type ty;
      list<DAE.Subscript> subs;

    // GlobalScript.Variable is not a match, keep the old one.
    case (false, _, _, _, _) then inOldVariable;

    // Assigning whole variable => return new variable.
    case (true, _, DAE.CREF_IDENT(id, ty, {}), _, _) then GlobalScript.IVAR(id, inValue, ty);

    // Assigning array slice => update the old variable's value.
    case (true, GlobalScript.IVAR(id, val, ty), DAE.CREF_IDENT(subscriptLst = subs), _, _)
      equation
        (_, val, _) = CevalFunction.assignVector(inValue, val, subs,
          FCore.emptyCache(), inEnv, NONE());
      then
        GlobalScript.IVAR(id, val, ty);

  end match;
end addVarToVarList3;

protected function addVarToVarList4
  input Boolean inFound;
  input DAE.ComponentRef inCref;
  input Values.Value inValue;
  input list<GlobalScript.Variable> inVariables;
  output list<GlobalScript.Variable> outVariables;
algorithm
  outVariables := match(inFound, inCref, inValue, inVariables)
    local
      Absyn.Ident id;
      DAE.Type ty;

    // GlobalScript.Variable was already updated in addVarToVar, do nothing.
    case (true, _, _, _) then inVariables;

    // GlobalScript.Variable is new, add it to the list of variables.
    case (false, DAE.CREF_IDENT(id, ty, {}), _, _)
      then GlobalScript.IVAR(id, inValue, ty) :: inVariables;

    // Assigning to an array slice is only allowed for variables that have
    // already been defined, i.e. that have a size. Print an error otherwise.
    case (false, DAE.CREF_IDENT(ident = id, subscriptLst = _ :: _), _, _)
      equation
        Error.addMessage(Error.SLICE_ASSIGN_NON_ARRAY, {id});
      then
        fail();

  end match;
end addVarToVarList4;

public function buildEnvFromSymboltable
" author: PA
   Builds an environment from a symboltable by adding all
   interactive variables and their bindings to the environment."
  input GlobalScript.SymbolTable inSymbolTable;
  output FCore.Graph outEnv;
  output GlobalScript.SymbolTable st;
algorithm
  (outEnv,st) := match (inSymbolTable)
    local
      list<SCode.Element> p_1;
      FCore.Graph env,env_1;
      list<GlobalScript.Variable> vars;

    case (st as GlobalScript.SYMBOLTABLE(lstVarVal = vars))
      equation
        (p_1,st) = symbolTableToSCode(st);
        (_,env) = Inst.makeEnvFromProgram(FCore.emptyCache(), p_1, Absyn.IDENT(""));
        // Reverse the variable list to make sure iterators overwrite other
        // variables (iterators are appended to the front of the list).
        vars = listReverse(vars);
        env_1 = addVarsToEnv(vars, env);
      then
        (env_1,st);

  end match;
end buildEnvFromSymboltable;

public function symbolTableToSCode
"Similar to SCodeUtil.translateAbsyn2SCode
  But this updates the symboltable to cache the translation."
  input GlobalScript.SymbolTable st;
  output SCode.Program program;
  output GlobalScript.SymbolTable outSt;
algorithm
  (program,outSt) := match st
    local
      Absyn.Program ast;
      list<GlobalScript.InstantiatedClass> instClsLst;
      list<GlobalScript.Variable> lstVarVal;
      list<GlobalScript.CompiledCFunction> compiledFunctions;
      list<GlobalScript.LoadedFile> loadedFiles;

    case GlobalScript.SYMBOLTABLE(explodedAst=SOME(program)) then (program,st);
    case GlobalScript.SYMBOLTABLE(ast,_,instClsLst,lstVarVal,compiledFunctions,loadedFiles)
      equation
        program = SCodeUtil.translateAbsyn2SCode(ast);
      then (program,GlobalScript.SYMBOLTABLE(ast,SOME(program),instClsLst,lstVarVal,compiledFunctions,loadedFiles));
  end match;
end symbolTableToSCode;

protected function addVarsToEnv
"Helper function to buildEnvFromSymboltable."
  input list<GlobalScript.Variable> inVariableLst;
  input FCore.Graph inEnv;
  output FCore.Graph outEnv;
algorithm
  outEnv := List.fold(inVariableLst, addVarToEnv, inEnv);
end addVarsToEnv;

protected function addVarToEnv
  input GlobalScript.Variable inVariable;
  input FCore.Graph inEnv;
  output FCore.Graph outEnv;
algorithm
  outEnv := matchcontinue(inVariable, inEnv)
    local
      FCore.Graph env, empty_env;
      String id;
      Values.Value v;
      DAE.Type tp;
      DAE.ComponentRef cref;

    case (GlobalScript.IVAR(varIdent = id, value = v, type_ = tp), env)
      equation
        cref = ComponentReference.makeCrefIdent(id, DAE.T_UNKNOWN_DEFAULT, {});
        empty_env = FGraph.empty();
        (_,_,_,_,_,_,_,_,_) = Lookup.lookupVar(FCore.emptyCache(), env, cref);
        env = FGraph.updateComp(
                  env,
                  DAE.TYPES_VAR(
                    id,
                    DAE.dummyAttrVar,
                    tp,
                    DAE.VALBOUND(v, DAE.BINDING_FROM_DEFAULT_VALUE()),
                    NONE()),
                  FCore.VAR_TYPED(),
                  empty_env);
      then
        env;

    case (GlobalScript.IVAR(varIdent = id, value = v, type_ = tp), env)
      equation
        empty_env = FGraph.empty();
        env = FGraph.mkComponentNode(
                 env,
                 DAE.TYPES_VAR(id,DAE.dummyAttrVar,tp,DAE.VALBOUND(v,DAE.BINDING_FROM_DEFAULT_VALUE()),NONE()),
                  SCode.COMPONENT(
                    id,
                    SCode.defaultPrefixes,
                    SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.BIDIR(), Absyn.NONFIELD()),
                    Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
                    SCode.noComment, NONE(), Absyn.dummyInfo),
                  DAE.NOMOD(),
                 FCore.VAR_UNTYPED(),
                 empty_env);
      then
        env;

  end matchcontinue;
end addVarToEnv;

public function traverseClasses
" This function traverses all classes of a program and applies a function
   to each class. The function takes the Absyn.Class, Absyn.Path option
   and an additional argument and returns an updated class and the
   additional values. The Absyn.Path option contains the path to the class
   that is traversed.
   inputs:  (Absyn.Program,
               Absyn.Path option,
               ((Absyn.Class  Absyn.Path option  \'a) => (Absyn.Class  Absyn.Path option  \'a)),  /* rel-ation to apply */
            \'a, /* extra value passed to re-lation */
            bool) /* true = traverse protected elements */
   outputs: (Absyn.Program   Absyn.Path option  \'a)"
  input Absyn.Program inProgram;
  input Option<Absyn.Path> inPath;
  input FuncType inFunc;
  input Type_a inArg;
  input Boolean inVisitProtected;
  output tuple<Absyn.Program, Option<Absyn.Path>, Type_a> outTpl;

  partial function FuncType
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTpl;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTpl;
  end FuncType;

  replaceable type Type_a subtypeof Any;
algorithm
  outTpl := match (inProgram, inPath, inFunc, inArg, inVisitProtected)
    local
      list<Absyn.Class> classes;
      Option<Absyn.Path> pa_1,pa;
      Type_a args_1,args;
      Absyn.Within within_;
      FuncType visitor;
      Boolean traverse_prot;
      Absyn.Program p;

    case (p as Absyn.PROGRAM(),pa,visitor,args,traverse_prot)
      equation
        ((classes,pa_1,args_1)) = traverseClasses2(p.classes, pa, visitor, args, traverse_prot);
        p.classes = classes;
      then
        (p,pa_1,args_1);
  end match;
end traverseClasses;

protected function traverseClasses2
" Helperfunction to traverseClasses."
  input list<Absyn.Class> inClasses;
  input Option<Absyn.Path> inPath;
  input FuncType inFunc;
  input Type_a inArg "extra argument";
  input Boolean inVisitProtected "visit protected elements";
  output tuple<list<Absyn.Class>, Option<Absyn.Path>, Type_a> outTpl;

  partial function FuncType
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTpl;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTpl;
  end FuncType;
  replaceable type Type_a subtypeof Any;
algorithm
  outTpl := matchcontinue (inClasses, inPath, inFunc, inArg, inVisitProtected)
    local
      Option<Absyn.Path> pa,pa_1,pa_2,pa_3;
      FuncType visitor;
      Type_a args,args_1,args_2,args_3;
      Absyn.Class class_1,class_2,class_;
      list<Absyn.Class> classes_1,classes;
      Boolean traverse_prot;

    case ({},pa,_,args,_) then (({},pa,args));

    case ((class_ :: classes),pa,visitor,args,traverse_prot)
      equation
        ((class_1,_,args_1)) = visitor((class_,pa,args));
        ((class_2,_,args_2)) = traverseInnerClass(class_1, pa, visitor, args_1, traverse_prot);
        ((classes_1,pa_3,args_3)) = traverseClasses2(classes, pa, visitor, args_2, traverse_prot);
      then
        (((class_2 :: classes_1),pa_3,args_3));

    /* Visitor failed, but class contains inner classes after traversal, i.e. those inner classes didn't fail, and thus
    the class must be included also */
    case ((class_ :: classes),pa,visitor,args,traverse_prot)
      equation
        ((class_2,_,args_2)) = traverseInnerClass(class_, pa, visitor, args, traverse_prot);
        true = classHasLocalClasses(class_2);
        ((classes_1,pa_3,args_3)) = traverseClasses2(classes, pa, visitor, args_2, traverse_prot);
      then
        (((class_2 :: classes_1),pa_3,args_3));

    /* Visitor failed, remove class */
    case ((_ :: classes),pa,visitor,args,traverse_prot)
      equation
        ((classes_1,pa_3,args_3)) = traverseClasses2(classes, pa, visitor, args, traverse_prot);
      then
        ((classes_1,pa_3,args_3));

    case ((class_ :: _),_,_,_,_)
      equation
        print("-traverse_classes2 failed on class:");
        print(Absyn.pathString(Absyn.className(class_)));
        print("\n");
      then
        fail();

  end matchcontinue;
end traverseClasses2;

protected function classHasLocalClasses
"Returns true if class contains a local class"
  input Absyn.Class cl;
  output Boolean res;
algorithm
  res := match(cl)
    local
      list<Absyn.ClassPart> parts;

    // A class with parts.
    case (Absyn.CLASS(body= Absyn.PARTS(classParts = parts)))
      equation
        res = partsHasLocalClass(parts);
      then
        res;

    // An extended class with parts: model extends M end M;
    case (Absyn.CLASS(body= Absyn.CLASS_EXTENDS(parts = parts)))
      equation
        res = partsHasLocalClass(parts);
      then
        res;

  end match;
end classHasLocalClasses;

protected function partsHasLocalClass
"Help function to classHasLocalClass"
  input list<Absyn.ClassPart> inParts;
  output Boolean res;
algorithm
  res := matchcontinue(inParts)
    local
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> parts;

    case Absyn.PUBLIC(elts) :: _
      equation
        true = eltsHasLocalClass(elts);
      then
        true;

    case Absyn.PROTECTED(elts) :: _
      equation
        true = eltsHasLocalClass(elts);
      then
        true;

    case _ :: parts then partsHasLocalClass(parts);
    else false;
  end matchcontinue;
end partsHasLocalClass;

protected function eltsHasLocalClass
"help function to partsHasLocalClass"
  input list<Absyn.ElementItem> inElts;
  output Boolean res;
algorithm
  res := matchcontinue(inElts)
    local
      list<Absyn.ElementItem> elts;

    case Absyn.ELEMENTITEM(Absyn.ELEMENT(specification=Absyn.CLASSDEF())) :: _ then true;
    case _ :: elts then eltsHasLocalClass(elts);
    else false;
  end matchcontinue;
end eltsHasLocalClass;

protected function traverseInnerClass
" Helperfunction to traverseClasses2. This function traverses all inner classes of a class."
  input Absyn.Class inClass;
  input Option<Absyn.Path> inPath;
  input FuncType inFunc;
  input Type_a inArg "extra value";
  input Boolean inVisitProtected "if true, traverse protected elts";
  output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTpl;

  partial function FuncType
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTpl;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTpl;
  end FuncType;

  replaceable type Type_a subtypeof Any;
algorithm
  outTpl := matchcontinue(inClass, inPath, inFunc, inArg, inVisitProtected)
    local
      Absyn.Path tmp_pa,pa;
      list<Absyn.ClassPart> parts_1,parts;
      Option<Absyn.Path> pa_1;
      Type_a args_1,args;
      String name,bcname;
      Boolean p,f,e,visit_prot;
      Absyn.Restriction r;
      Option<String> str_opt;
      SourceInfo file_info;
      FuncType visitor;
      Absyn.Class cl;
      list<Absyn.ElementArg> modif;
      list<String> typeVars;
      list<Absyn.NamedArg> classAttrs;
      Absyn.Comment cmt;
      list<Absyn.Annotation> ann;

    /* a class with parts */
    case (Absyn.CLASS(name, p, f, e, r, Absyn.PARTS(typeVars, classAttrs, parts, ann, str_opt), file_info),
          SOME(pa), visitor, args, visit_prot)
      equation
        tmp_pa = Absyn.joinPaths(pa, Absyn.IDENT(name));
        ((parts_1, pa_1, args_1)) = traverseInnerClassParts(parts, SOME(tmp_pa), visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name, p, f, e, r, Absyn.PARTS(typeVars, classAttrs, parts_1, ann, str_opt), file_info), pa_1, args_1));

    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts, ann = ann, comment = str_opt),info = file_info),
          NONE(),visitor,args,visit_prot)
      equation
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, SOME(Absyn.IDENT(name)), visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name,p,f,e,r,Absyn.PARTS(typeVars, classAttrs, parts_1, ann, str_opt),file_info),pa_1,args_1));

    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.PARTS(typeVars = typeVars, classAttrs = classAttrs, classParts = parts, ann = ann, comment = str_opt),info = file_info),
          pa_1,visitor,args,visit_prot)
      equation
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, pa_1, visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name,p,f,e,r,Absyn.PARTS(typeVars,classAttrs,parts_1,ann,str_opt),file_info),pa_1,args_1));

    /* adrpo: handle also an extended class with parts: model extends M end M; */
    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,comment = str_opt, modifications=modif,parts = parts,ann = ann),info = file_info),
          SOME(pa),visitor,args,visit_prot)
      equation
        tmp_pa = Absyn.joinPaths(pa, Absyn.IDENT(name));
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, SOME(tmp_pa), visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,str_opt,parts_1,ann),file_info),pa_1,args_1));

    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,comment = str_opt, modifications=modif,parts = parts,ann = ann),info = file_info),
          NONE(),visitor,args,visit_prot)
      equation
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, SOME(Absyn.IDENT(name)), visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,str_opt,parts_1,ann),file_info),pa_1,args_1));

    case (Absyn.CLASS(name = name,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                      body = Absyn.CLASS_EXTENDS(baseClassName=bcname,comment = str_opt,modifications=modif,parts = parts,ann = ann),info = file_info),
          pa_1,visitor,args,visit_prot)
      equation
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, pa_1, visitor, args, visit_prot);
      then
        ((Absyn.CLASS(name,p,f,e,r,Absyn.CLASS_EXTENDS(bcname,modif,str_opt,parts_1,ann),file_info),pa_1,args_1));

    /* otherwise */
    case (cl,pa_1,_,args,_) then ((cl,pa_1,args));
  end matchcontinue;
end traverseInnerClass;

protected function traverseInnerClassParts
  "Helper function to traverseInnerClass"
  input list<Absyn.ClassPart> inClassParts;
  input Option<Absyn.Path> inPath;
  input FuncType inFunc;
  input Type_a inArg "extra argument";
  input Boolean inVisitProtected "visist protected elts";
  output tuple<list<Absyn.ClassPart>, Option<Absyn.Path>, Type_a> outTpl;

  partial function FuncType
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTpl;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTpl;
  end FuncType;
  replaceable type Type_a subtypeof Any;
algorithm
  outTpl := matchcontinue(inClassParts, inPath, inFunc, inArg, inVisitProtected)
    local
      Option<Absyn.Path> pa,pa_1,pa_2;
      Type_a args,args_1,args_2;
      list<Absyn.ElementItem> elts_1,elts;
      list<Absyn.ClassPart> parts_1,parts;
      FuncType visitor;
      Boolean visit_prot;
      Absyn.ClassPart part;

    case ({},pa,_,args,_) then (({},pa,args));

    case ((Absyn.PUBLIC(contents = elts) :: parts),pa,visitor,args,visit_prot)
      equation
        ((elts_1,_,args_1)) = traverseInnerClassElements(elts, pa, visitor, args, visit_prot);
        ((parts_1,pa_2,args_2)) = traverseInnerClassParts(parts, pa, visitor, args_1, visit_prot);
      then
        (((Absyn.PUBLIC(elts_1) :: parts_1),pa_2,args_2));

    case ((Absyn.PROTECTED(contents = elts) :: parts),pa,visitor,args,true)
      equation
        ((elts_1,_,args_1)) = traverseInnerClassElements(elts, pa, visitor, args, true);
        ((parts_1,pa_2,args_2)) = traverseInnerClassParts(parts, pa, visitor, args_1, true);
      then
        (((Absyn.PROTECTED(elts_1) :: parts_1),pa_2,args_2));

    case ((part :: parts),pa,visitor,args,true)
      equation
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, pa, visitor, args, true);
      then
        (((part :: parts_1),pa_1,args_1));

  end matchcontinue;
end traverseInnerClassParts;

protected function traverseInnerClassElements
  "Helper function to traverseInnerClassParts"
  input list<Absyn.ElementItem> inElements;
  input Option<Absyn.Path> inPath;
  input FuncType inFuncType;
  input Type_a inArg;
  input Boolean inVisitProtected "visit protected elts";
  output tuple<list<Absyn.ElementItem>, Option<Absyn.Path>, Type_a> outTpl;

  partial function FuncType
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTpl;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTpl;
  end FuncType;

  replaceable type Type_a subtypeof Any;
algorithm
  outTpl := matchcontinue(inElements, inPath, inFuncType, inArg, inVisitProtected)
    local
      Option<Absyn.Path> pa,pa_1,pa_2;
      Type_a args,args_1,args_2;
      Absyn.ElementSpec elt_spec_1,elt_spec;
      list<Absyn.ElementItem> elts_1,elts;
      Boolean f,visit_prot;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      SourceInfo info;
      Option<Absyn.ConstrainClass> constr;
      FuncType visitor;
      Absyn.ElementItem elt;
      Boolean repl;
      Absyn.Class cl;

    case ({},pa,_,args,_) then (({},pa,args));
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = io,specification = elt_spec,info = info,constrainClass = constr)) :: elts),pa,visitor,args,visit_prot)
      equation
        ((elt_spec_1,_,args_1)) = traverseInnerClassElementspec(elt_spec, pa, visitor, args, visit_prot);
        ((elts_1,pa_2,args_2)) = traverseInnerClassElements(elts, pa, visitor, args_1, visit_prot);
      then
        ((
          (Absyn.ELEMENTITEM(Absyn.ELEMENT(f,r,io,elt_spec_1,info,constr)) :: elts_1),pa_2,args_2));

   /* Visitor failed in elementspec, but inner classes succeeded, include class */
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = io,specification = Absyn.CLASSDEF(repl,cl),info = info,constrainClass = constr)) :: elts),pa,visitor,args,visit_prot)
      equation
         ((cl,_,args_1)) = traverseInnerClass(cl, pa, visitor, args, visit_prot);
        true  = classHasLocalClasses(cl);
        ((elts_1,pa_2,args_2)) = traverseInnerClassElements(elts, pa, visitor, args_1, visit_prot);
      then
        ((
          (Absyn.ELEMENTITEM(Absyn.ELEMENT(f,r,io,Absyn.CLASSDEF(repl,cl),info,constr))::elts_1),pa_2,args_2));

   /* Visitor failed in elementspec, remove class */
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT()) :: elts),pa,visitor,args,visit_prot)
      equation
        ((elts_1,pa_2,args_2)) = traverseInnerClassElements(elts, pa, visitor, args, visit_prot);
      then
        ((
          elts_1,pa_2,args_2));

    case ((elt :: elts),pa,visitor,args,visit_prot)
      equation
        ((elts_1,pa_1,args_1)) = traverseInnerClassElements(elts, pa, visitor, args, visit_prot);
      then
        (((elt :: elts_1),pa_1,args_1));
  end matchcontinue;
end traverseInnerClassElements;

protected function traverseInnerClassElementspec
" Helperfunction to traverseInnerClassElements"
  input Absyn.ElementSpec inElementSpec;
  input Option<Absyn.Path> inPath;
  input FuncType inFuncType;
  input Type_a inArg;
  input Boolean inVisitProtected "visit protected elts";
  output tuple<Absyn.ElementSpec, Option<Absyn.Path>, Type_a> outTpl;

  partial function FuncType
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTpl;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTpl;
  end FuncType;

  replaceable type Type_a subtypeof Any;
algorithm
  outTpl := match(inElementSpec, inPath, inFuncType, inArg, inVisitProtected)
    local
      Absyn.Class class_1,class_2,class_;
      Option<Absyn.Path> pa_1,pa_2,pa;
      Type_a args_1,args_2,args;
      Boolean repl,visit_prot;
      FuncType visitor;
      Absyn.ElementSpec elt_spec;

    case (Absyn.CLASSDEF(replaceable_ = repl,class_ = class_),pa,visitor,args,visit_prot)
      equation
        ((class_1,_,args_1)) = visitor((class_,pa,args));
        ((class_2,pa_2,args_2)) = traverseInnerClass(class_1, pa, visitor, args_1, visit_prot);
      then
        ((Absyn.CLASSDEF(repl,class_2),pa_2,args_2));

    case (elt_spec as Absyn.EXTENDS(),pa,_,args,_) then ((elt_spec,pa,args));
    case (elt_spec as Absyn.IMPORT(),pa,_,args,_) then ((elt_spec,pa,args));
    case (elt_spec as Absyn.COMPONENTS(),pa,_,args,_) then ((elt_spec,pa,args));
  end match;
end traverseInnerClassElementspec;

annotation(__OpenModelica_Interface="frontend");

end GlobalScriptUtil;
