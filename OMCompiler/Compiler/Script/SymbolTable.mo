/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
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
import FCore;
import InteractiveTypes;
import SCode;
import Values;
import Vector;

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
import AbsynToSCode;
import MetaUtil;
import System;
import SCodeUtil;
protected import ComponentReferenceBasics;

public

record SYMBOLTABLE
  Absyn.Program ast "ast ; The ast" ;
  Option<SCode.Program> explodedAst "the explodedAst is invalidated every time the program is updated";
  list<InteractiveTypes.Variable> vars "List of variables with values" ;
  Vector<Absyn.Program> cachedAsts;
  Integer cacheIndex;
  tuple<Boolean,Boolean,Boolean,Boolean> connectorFlags
    "has inner/outer, expandable, overconstrained and stream connectors; a side
     effect of translating explodedAst that the old frontend reads later. Stored
     here so getSCode can re-assert it on a cache hit, since an intervening
     translation or NFInst.resetGlobalFlags may have cleared the global flags.";
end SYMBOLTABLE;

constant Integer AST_CACHE_MAX_SIZE = 1000;

function reset
  type Program = Absyn.Program;
algorithm
  setGlobalRoot(Global.symbolTable, SYMBOLTABLE(
                 ast=Absyn.PROGRAM({},Absyn.TOP()),
                 explodedAst=NONE(),
                 vars={},
                 cachedAsts=Vector.new<Program>(),
                 cacheIndex=0,
                 connectorFlags=(false,false,false,false)
                 ));
  updateUriMapping({});
end reset;

function currentConnectorFlags
  "Reads the global connector flags set as a side effect of translating SCode."
  output tuple<Boolean,Boolean,Boolean,Boolean> flags;
algorithm
  flags := (System.getHasInnerOuterDefinitions(), System.getHasExpandableConnectors(),
            System.getHasOverconstrainedConnectors(), System.getHasStreamConnectors());
end currentConnectorFlags;

function applyConnectorFlags
  "Restores the global connector flags to match the cached SCode."
  input tuple<Boolean,Boolean,Boolean,Boolean> flags;
protected
  Boolean io, ec, oc, sc;
algorithm
  (io, ec, oc, sc) := flags;
  System.setHasInnerOuterDefinitions(io);
  System.setHasExpandableConnectors(ec);
  System.setHasOverconstrainedConnectors(oc);
  System.setHasStreamConnectors(sc);
end applyConnectorFlags;

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

function setAbsynElement
  "Sets the Absyn program in the symbol table like setAbsyn, but also updates
   the SCode if it's cached. This can be used to avoid invalidating the whole
   SCode program when only updating a single element in the Absyn."
  input Absyn.Program ast;
  input Absyn.Element element;
  input Absyn.Path path;
protected
  SymbolTable table;
  SCode.Element scode_elem;
  list<SCode.Element> scode_elems, scode_prog;

  function update_element
    input SCode.Element oldElement;
    input output SCode.Element newElement;
  algorithm
    if SCodeUtil.isElementProtected(oldElement) then
      newElement := SCodeUtil.makeElementProtected(newElement);
    end if;
  end update_element;
algorithm
  table := get();

  if referenceEq(table.ast, ast) then
    return;
  end if;

  table.ast := ast;
  updateUriMapping(ast.classes);

  if isSome(table.explodedAst) then
    // Restore the flags for the rest of the program so translateElement only
    // adds to them, then record the updated set.
    applyConnectorFlags(table.connectorFlags);
    // Assume the element is public here since we don't know the actual
    // visibility, and then update it later in update_element if it's not.
    scode_elems := AbsynToSCode.translateElement(element, SCode.Visibility.PUBLIC());

    if listLength(scode_elems) > 1 then
      // translateElement can return multiple elements when multiple components
      // are declared in the same declaration, pick the one matching the path.
      SOME(scode_elem) := List.findOption(scode_elems,
        function SCodeUtil.isElementNamed(name = AbsynUtil.pathLastIdent(path)));
    else
      scode_elem := listHead(scode_elems);
    end if;

    SOME(scode_prog) := table.explodedAst;
    (scode_prog, true) := SCodeUtil.transformPathedElementInProgram(path,
      function update_element(newElement = scode_elem), scode_prog);
    table.explodedAst := SOME(scode_prog);
    table.connectorFlags := currentConnectorFlags();
  end if;

  update(table);
end setAbsynElement;

function setAbsynClass
  "Sets the Absyn program in the symbol table like setAbsyn, but also updates
   the SCode if it's cached. This can be used to avoid invalidating the whole
   SCode program when only updating a single class in the Absyn."
  input Absyn.Program ast;
  input Absyn.Class cls;
  input Absyn.Path path;
protected
  SymbolTable table;
  SCode.Element scode_elem;
  list<SCode.Element> scode_prog;

  function update_element
    input SCode.Element oldElement;
    input output SCode.Element newElement;
  algorithm
    // An SCode.Element created from an Absyn.Class will only have default prefixes set,
    // so copy those from the old element to make sure they're not lost.
    newElement := SCodeUtil.setElementPrefixes(SCodeUtil.elementPrefixes(oldElement), newElement);
  end update_element;
algorithm
  table := get();

  if referenceEq(table.ast, ast) then
    return;
  end if;

  table.ast := ast;
  updateUriMapping(ast.classes);

  if isSome(table.explodedAst) then
    applyConnectorFlags(table.connectorFlags);
    scode_elem := AbsynToSCode.translateClass(cls);

    SOME(scode_prog) := table.explodedAst;
    (scode_prog, true) := SCodeUtil.transformPathedElementInProgram(path,
      function update_element(newElement = scode_elem), scode_prog);
    table.explodedAst := SOME(scode_prog);
    table.connectorFlags := currentConnectorFlags();
  end if;

  update(table);
end setAbsynClass;

function setAbsynLoaded
  "Sets the Absyn program like setAbsyn, but for loadString: when the SCode is
   cached and the loaded classes are top-level, it refreshes only those classes
   in the SCode instead of dropping the whole cache. This keeps a loadString of
   one class from re-exploding the entire loaded library. Falls back to full
   invalidation if the merge changed the program in any other way (e.g. a
   `uses` clause pulled in extra libraries)."
  input Absyn.Program ast      "the full program after merging";
  input Absyn.Program loaded   "the just-parsed classes, with their within";
protected
  SymbolTable table;
  list<SCode.Element> sp, newElems = {};
  SCode.Element se;
  Boolean found, topLevel;
  Absyn.Program metaLoaded;

  function update_element
    input SCode.Element oldElement;
    input output SCode.Element newElement;
  algorithm
    newElement := SCodeUtil.setElementPrefixes(SCodeUtil.elementPrefixes(oldElement), newElement);
  end update_element;
algorithm
  table := get();
  if referenceEq(table.ast, ast) then
    return;
  end if;
  table.ast := ast;
  updateUriMapping(ast.classes);

  topLevel := match loaded.within_ case Absyn.TOP() then true; else false; end match;

  if topLevel and isSome(table.explodedAst) then
    SOME(sp) := table.explodedAst;
    applyConnectorFlags(table.connectorFlags);
    // translateClass does not run MetaUtil.createMetaClassesInProgram, which lifts
    // uniontype records into top-level metarecords (a no-op outside MetaModelica).
    // Apply it to the loaded classes so the incremental SCode matches what a full
    // translateAbsyn2SCode would produce.
    metaLoaded := MetaUtil.createMetaClassesInProgram(loaded);
    for cls in metaLoaded.classes loop
      se := AbsynToSCode.translateClass(cls);
      (sp, found) := SCodeUtil.transformPathedElementInProgram(Absyn.IDENT(cls.name),
        function update_element(newElement = se), sp);
      if not found then
        newElems := se :: newElems;
      end if;
    end for;
    newElems := listReverse(newElems);
    table.connectorFlags := currentConnectorFlags();
    // Only trust the incremental SCode if it accounts for exactly the program's
    // top-level classes after meta expansion; otherwise the merge did more than
    // we tracked (e.g. a `uses` clause pulled in extra libraries).
    metaLoaded := MetaUtil.createMetaClassesInProgram(table.ast);
    table.explodedAst := if listLength(sp) + listLength(newElems) == listLength(metaLoaded.classes)
                         then SOME(listAppend(sp, newElems)) else NONE();
  elseif isSome(table.explodedAst) then
    table.explodedAst := NONE();
  end if;

  update(table);
end setAbsynLoaded;

function setAbsynDeleted
  "Sets the Absyn program like setAbsyn after a class was deleted, but when the
   SCode is cached and a top-level class was removed, drops just that class from
   the SCode instead of invalidating the whole cache."
  input Absyn.Program ast;
  input Absyn.Path path;
protected
  SymbolTable table;
  list<SCode.Element> sp;
  String name;
  Boolean topLevel;
algorithm
  table := get();
  table.ast := ast;
  updateUriMapping(ast.classes);

  (topLevel, name) := match path case Absyn.IDENT(name) then (true, name); else (false, ""); end match;

  if isSome(table.explodedAst) then
    if topLevel then
      SOME(sp) := table.explodedAst;
      table.explodedAst := SOME(list(e for e guard not SCodeUtil.isElementNamed(name, e) in sp));
    else
      table.explodedAst := NONE();
    end if;
  end if;

  update(table);
end setAbsynDeleted;

function getSCode
  output SCode.Program ast;
protected
  SymbolTable table;
algorithm
  table := get();
  if isNone(table.explodedAst) then
    ast := AbsynToSCode.translateAbsyn2SCode(table.ast);
    table.explodedAst := SOME(ast);
    table.connectorFlags := currentConnectorFlags();
    update(table);
  else
    SOME(ast) := table.explodedAst;
    applyConnectorFlags(table.connectorFlags);
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
  output list<InteractiveTypes.Variable> vars;
protected
  SymbolTable table;
algorithm
  table := get();
  vars := table.vars;
end getVars;

public function setVars
  "Adds a list of variables to the interactive symboltable."
  input list<InteractiveTypes.Variable> vars;
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
  list<InteractiveTypes.Variable> vars;
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
  table.vars := InteractiveTypes.IVAR(inIdent, inValue, inType) :: table.vars;
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

function storeAST
  output Integer id;
protected
  SymbolTable table;
algorithm
  table := get();
  id := table.cacheIndex + 1;

  // Handle integer wraparound.
  if id < 0 then
    id := 1;
  end if;

  // Update the index in the symbol table.
  table.cacheIndex := id;
  update(table);

  if Vector.size(table.cachedAsts) >= AST_CACHE_MAX_SIZE then
    // Wrap around if the cache is full.
    Vector.update(table.cachedAsts, intMod(id-1, AST_CACHE_MAX_SIZE)+1, getAbsyn());
  else
    // Otherwise just push a new value onto the vector.
    Vector.push(table.cachedAsts, getAbsyn());
  end if;
end storeAST;

function restoreAST
  input Integer id;
  output Boolean success;
protected
  SymbolTable table;
algorithm
  table := get();
  // Make sure the id is in the current index range.
  success := id <= table.cacheIndex and id > table.cacheIndex - AST_CACHE_MAX_SIZE and id > 0;

  if success then
    setAbsyn(Vector.get(table.cachedAsts, intMod(id-1, AST_CACHE_MAX_SIZE)+1));
  end if;
end restoreAST;

protected

function isVarNamed
  input Absyn.Ident id;
  input InteractiveTypes.Variable v;
  output Boolean b;
algorithm
  b := v.varIdent == id;
end isVarNamed;

function addVarToVarList
  "Assigns a value to a variable with a specific identifier."
  input DAE.ComponentRef inCref;
  input Values.Value inValue;
  input FCore.Graph inEnv;
  input list<InteractiveTypes.Variable> inVariables;
  output list<InteractiveTypes.Variable> outVariables;
protected
  Boolean found;
algorithm
  (outVariables, found) :=
    List.findMap(inVariables, function addVarToVarList2(inCref = inCref, inValue = inValue, inEnv = inEnv));
  outVariables := addVarToVarList4(found, inCref, inValue, outVariables);
end addVarToVarList;

protected function addVarToVarList2
  input InteractiveTypes.Variable inOldVariable;
  input DAE.ComponentRef inCref;
  input Values.Value inValue;
  input FCore.Graph inEnv;
  output InteractiveTypes.Variable outVariable;
  output Boolean outFound;
protected
  Absyn.Ident id1, id2;
algorithm
  InteractiveTypes.IVAR(varIdent = id1) := inOldVariable;
  DAE.CREF_IDENT(ident = id2) := inCref;
  outFound := stringEq(id1, id2);
  outVariable := addVarToVarList3(outFound, inOldVariable, inCref, inValue, inEnv);
end addVarToVarList2;

protected function addVarToVarList3
  input Boolean inFound;
  input InteractiveTypes.Variable inOldVariable;
  input DAE.ComponentRef inCref;
  input Values.Value inValue;
  input FCore.Graph inEnv;
  output InteractiveTypes.Variable outVariable;
algorithm
  outVariable := match(inFound, inOldVariable, inCref)
    local
      Absyn.Ident id;
      Values.Value val;
      DAE.Type ty;
      list<DAE.Subscript> subs;

    // InteractiveTypes.Variable is not a match, keep the old one.
    case (false, _, _) then inOldVariable;

    // Assigning whole variable => return new variable.
    case (true, _, DAE.CREF_IDENT(id, ty, {})) then InteractiveTypes.IVAR(id, inValue, ty);

    // Assigning array slice => update the old variable's value.
    case (true, InteractiveTypes.IVAR(id, val, ty), DAE.CREF_IDENT(subscriptLst = subs))
      algorithm
        (_, val) := CevalFunction.assignVector(inValue, val, subs, FCore.emptyCache(), inEnv);
      then
        InteractiveTypes.IVAR(id, val, ty);

  end match;
end addVarToVarList3;

protected function addVarToVarList4
  input Boolean inFound;
  input DAE.ComponentRef inCref;
  input Values.Value inValue;
  input list<InteractiveTypes.Variable> inVariables;
  output list<InteractiveTypes.Variable> outVariables;
algorithm
  outVariables := match(inFound, inCref)
    local
      Absyn.Ident id;
      DAE.Type ty;

    // InteractiveTypes.Variable was already updated in addVarToVar, do nothing.
    case (true, _) then inVariables;

    // InteractiveTypes.Variable is new, add it to the list of variables.
    case (false, DAE.CREF_IDENT(id, ty, {}))
      then InteractiveTypes.IVAR(id, inValue, ty) :: inVariables;

    // Assigning to an array slice is only allowed for variables that have
    // already been defined, i.e. that have a size. Print an error otherwise.
    case (false, DAE.CREF_IDENT(ident = id, subscriptLst = _ :: _))
      algorithm
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
  input list<InteractiveTypes.Variable> inVariableLst;
  input FCore.Graph inEnv;
  output FCore.Graph outEnv;
algorithm
  outEnv := List.fold(inVariableLst, addVarToEnv, inEnv);
end addVarsToEnv;

protected function addVarToEnv
  input InteractiveTypes.Variable inVariable;
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

    case (InteractiveTypes.IVAR(varIdent = id, value = v, type_ = tp), env)
      algorithm
        cref := ComponentReferenceBasics.makeCrefIdent(id, DAE.T_UNKNOWN_DEFAULT, {});
        empty_env := FGraph.empty();
        Lookup.lookupVar(FCore.emptyCache(), env, cref);
        env := FGraph.updateComp(
                  env,
                  DAE.TYPES_VAR(
                    id,
                    DAE.dummyAttrVar,
                    tp,
                    DAE.VALBOUND(v, DAE.BINDING_FROM_DEFAULT_VALUE()),
                    false,
                    NONE()),
                  FCore.VAR_TYPED(),
                  empty_env);
      then
        env;

    case (InteractiveTypes.IVAR(varIdent = id, value = v, type_ = tp), env)
      algorithm
        empty_env := FGraph.empty();
        env := FGraph.mkComponentNode(
                 env,
                 DAE.TYPES_VAR(id,DAE.dummyAttrVar,tp,DAE.VALBOUND(v,DAE.BINDING_FROM_DEFAULT_VALUE()),false,NONE()),
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
    () := match cl
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
