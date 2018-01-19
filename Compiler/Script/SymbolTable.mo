/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2018, Open Source Modelica Consortium (OSMC),
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

encapsulated uniontype SymbolTable
" file:        SymbolTable.mo
  package:     SymbolTable
  description: Thread-local, mutable symbol table. Set this at the start
               of any interactive call or in Main.
"

import Absyn;
import GlobalScript;
import FCore;
import SCode;

protected
import AvlTreeStringString;
import CevalFunction;
import DAE;
import Error;
import FGraph;
import Global;
import Inst;
import Lookup;
import List;
import SCodeUtil;
import System;

public

record SYMBOLTABLE
  Absyn.Program ast "ast ; The ast" ;
  Option<SCode.Program> explodedAst "the explodedAst is invalidated every time the program is updated";
  list<GlobalScript.Variable> vars "List of variables with values" ;
end SYMBOLTABLE;

function reset
algorithm
  setGlobalRoot(Global.symbolTable, SYMBOLTABLE(
                 ast=Absyn.PROGRAM({},Absyn.TOP()),
                 explodedAst=NONE(),
                 vars={}
                 ));
  updateUriMapping({});
end reset;

function update
  input SymbolTable table;
algorithm
  setGlobalRoot(Global.symbolTable, table);
end update;

function get
  output SymbolTable table;
algorithm
  table := getGlobalRoot(Global.symbolTable);
end get;

function getAbsyn
  output Absyn.Program ast;
protected
  SymbolTable table;
algorithm
  table := get();
  ast := table.ast;
end getAbsyn;

function setAbsyn
  input Absyn.Program ast;
protected
  SymbolTable table;
algorithm
  table := get();
  if referenceEq(table.ast, ast) then
    return;
  end if;
  table.ast := ast;
  updateUriMapping(ast.classes);
  if isSome(table.explodedAst) then
    table.explodedAst := NONE();
  end if;
  update(table);
end setAbsyn;

function getSCode
  output SCode.Program ast;
protected
  SymbolTable table;
algorithm
  table := get();
  if isNone(table.explodedAst) then
    ast := SCodeUtil.translateAbsyn2SCode(table.ast);
    table.explodedAst := SOME(ast);
    update(table);
  else
    SOME(ast) := table.explodedAst;
  end if;
end getSCode;

function setSCode
  input Option<SCode.Program> ast;
protected
  SymbolTable table;
algorithm
  table := get();
  if referenceEq(table.explodedAst, ast) then
    return;
  end if;
  table.explodedAst := ast;
  update(table);
end setSCode;

function clearSCode
protected
  SymbolTable table;
algorithm
  table := get();
  if isSome(table.explodedAst) then
    table.explodedAst := NONE();
    update(table);
  end if;
end clearSCode;

function clearProgram
protected
  SymbolTable table;
algorithm
  table := get();
  reset();
  setVars(table.vars);
end clearProgram;

public function getVars
  "Adds a list of variables to the interactive symboltable."
  output list<GlobalScript.Variable> vars;
protected
  SymbolTable table;
algorithm
  table := get();
  vars := table.vars;
end getVars;

public function setVars
  "Adds a list of variables to the interactive symboltable."
  input list<GlobalScript.Variable> vars;
protected
  SymbolTable table;
algorithm
  table := get();
  table.vars := vars;
  update(table);
end setVars;

function addVars
  "Adds a list of variables to the interactive symboltable."
  input list<DAE.ComponentRef> inCref;
  input list<Values.Value> inValues;
  input FCore.Graph inEnv;
protected
  list<DAE.ComponentRef> crefs;
  list<Values.Value> vals;
  Values.Value v;
  DAE.ComponentRef cr;
algorithm
  crefs := inCref;
  vals := inValues;
  while not listEmpty(crefs) loop
    cr::crefs := crefs;
    v::vals := vals;
    addVar(cr, v, inEnv);
  end while;
end addVars;

public function addVar
  "Adds a variable to the interactive symboltable."
  input DAE.ComponentRef inCref;
  input Values.Value inValue;
  input FCore.Graph inEnv;
protected
  list<GlobalScript.Variable> vars;
  SymbolTable table;
algorithm
  table := get();
  vars := addVarToVarList(inCref, inValue, inEnv, table.vars);
  table.vars := addVarToVarList(inCref, inValue, inEnv, vars);
  update(table);
end addVar;

public function appendVar
"Appends a variable to the interactive symbol table.
 Compared to addVarToSymboltable, this function does
 not search for the identifier, it adds the variable
 to the beginning of the list.
 Used in for example iterators in for statements."
  input Absyn.Ident inIdent;
  input Values.Value inValue;
  input DAE.Type inType;
protected
  SymbolTable table;
algorithm
  table := get();
  table.vars := GlobalScript.IVAR(inIdent, inValue, inType) :: table.vars;
  update(table);
end appendVar;

public function deleteVarFirstEntry
  input Absyn.Ident inIdent;
protected
  SymbolTable table;
algorithm
  table := get();
  table.vars := List.deleteMemberOnTrue(inIdent, table.vars, isVarNamed);
  update(table);
end deleteVarFirstEntry;

protected

function isVarNamed
  input Absyn.Ident id;
  input GlobalScript.Variable v;
  output Boolean b;
algorithm
  b := v.varIdent == id;
end isVarNamed;

function addVarToVarList
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
        (_, val) = CevalFunction.assignVector(inValue, val, subs, FCore.emptyCache(), inEnv);
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

public function buildEnv
"Builds an environment from a symboltable by adding all interactive
 variables and their bindings to the environment."
  output FCore.Graph env;
protected
  SymbolTable table;
algorithm
  table := get();
  (_,env) := Inst.makeEnvFromProgram(getSCode());
  // Reverse the variable list to make sure iterators overwrite other
  // variables (iterators are appended to the front of the list).
  env := addVarsToEnv(listReverse(table.vars), env);
end buildEnv;

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

protected function updateUriMapping
  input list<Absyn.Class> classes;
protected
  AvlTreeStringString.Tree tree;
  String name, fileName, dir;
  Boolean b;
  array<String> namesAndDirs;
  list<SourceInfo> infos;
algorithm
  tree := AvlTreeStringString.EMPTY();
  for cl in classes loop
    _ := match cl
      case Absyn.CLASS(info=SOURCEINFO(fileName="<interactive>")) then ();
      case Absyn.CLASS(name=name,info=SOURCEINFO(fileName=fileName))
        algorithm
          dir := System.dirname(fileName);
          fileName := System.basename(fileName);
          b := stringEq(fileName,"ModelicaBuiltin.mo") or stringEq(fileName,"MetaModelicaBuiltin.mo") or stringEq(dir,".");
          if not b then
            if AvlTreeStringString.hasKey(tree, name) then
              infos := list(cl.info for cl in classes);
              Error.addMultiSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS, {name}, infos);
            end if;
            tree := AvlTreeStringString.add(tree, name, dir);
          end if;
        then ();
      else ();
    end match;
  end for;
  namesAndDirs := listArray(List.thread(AvlTreeStringString.listValues(tree), AvlTreeStringString.listKeys(tree)));
  System.updateUriMapping(namesAndDirs);
end updateUriMapping;

annotation(__OpenModelica_Interface="backend");
end SymbolTable;
