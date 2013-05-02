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

encapsulated package Global
" file:  Global.mo
  package:     Global
  description: Global contains structures that are available globally.

  RCS: $Id: Global.mo 8980 2011-05-13 09:12:21Z adrpo $

  The Global package contains structures that are available globally."



constant Integer instHashIndex = 0;
constant Integer typesIndex = 1;
constant Integer crefIndex = 2;
constant Integer builtinIndex = 3;
constant Integer profilerTime1Index = 5;
constant Integer profilerTime2Index = 6;
constant Integer flagsIndex = 7;

import Name;
import Scope;
import InstInfo;
import Interactive;
import Pool;

type Names       = Name.Names;
type Scopes      = Scope.Scopes;
type InstInfo    = InstInfo.Info;
type SymbolTable = Interactive.SymbolTable;
type Id    = Integer;

constant Name.Name    rootName  = "$/";
constant Id     rootScopeId     = 1;
constant Scope.Scope  rootScope       = {Scope.S(rootScopeId, virtualId, 1, Scope.TY())};
constant Id     rootParentId    = 1;
constant Id     rootInstanceId  = 2;

constant Id     virtualId = 0 "an id for the parent of the root, etc, when we do not have any info";
constant Id     autoId = Pool.autoId "an dummy id that will be auto-updated on insert in a pool";

uniontype Global
  record G
    Names       na "names";
    Scopes      sc "scopes";
    InstInfo    ii "inst info";
    SymbolTable st "symbol table";
  end G;
end Global;

constant Integer globalMemoryIndex = 4;

public function new
"makes a new global"
protected
  Names       na "names";
  Scopes      sc "scopes";
  InstInfo    ii "inst info";
  SymbolTable st "symbol table";
algorithm
  na := Name.pool();
  sc := Scope.pool();
  ii := InstInfo.I();
  st := Interactive.emptySymboltable;
  _ := set(G(na, sc, ii, st));
end new;

public function get
"returns the Global structure from the global variable"
  output Global global;
algorithm
  global := getGlobalRoot(globalMemoryIndex);
end get;

public function set
"sets the Global structure in the global variable and returns it also
 so that is easier to write it in expressions such as then setGlobal(global)
 so you can both set it an return it"
  input Global inGlobal;
  output Global outGlobal;
algorithm
  setGlobalRoot(globalMemoryIndex, inGlobal);
  outGlobal := inGlobal;
end set;

public function getNames
  output Names names;
algorithm
  G(na = names) := get();
end getNames;

public function setNames
  input Names inNames;
  output Names outNames;
protected
  Names       na "names";
  Scopes      sc "scopes";
  InstInfo    ii "inst info";
  SymbolTable st "symbol table";
algorithm
  G(na, sc, ii, st) := get();
  G(na = outNames) := set(G(inNames, sc, ii, st));
end setNames;

public function getScopes
  output Scopes scopes;
algorithm
  G(sc = scopes) := get();
end getScopes;

public function setScopes
  input Scopes inScopes;
  output Scopes outScopes;
protected
  Names       na "scopes";
  Scopes      sc "scopes";
  InstInfo    ii "inst info";
  SymbolTable st "symbol table";
algorithm
  G(na, sc, ii, st) := get();
  G(sc = outScopes) := set(G(na, inScopes, ii, st));
end setScopes;

public function getInstInfo
  output InstInfo instInfo;
algorithm
  G(ii = instInfo) := get();
end getInstInfo;

public function setInstInfo
  input InstInfo inInstInfo;
  output InstInfo outInstInfo;
protected
  Names       na "instInfo";
  Scopes      sc "instInfo";
  InstInfo    ii "inst info";
  SymbolTable st "symbol table";
algorithm
  G(na, sc, ii, st) := get();
  G(ii = outInstInfo) := set(G(na, sc, inInstInfo, st));
end setInstInfo;

public function getSymbolTable
  output SymbolTable symbolTable;
algorithm
  G(st = symbolTable) := get();
end getSymbolTable;

public function setSymbolTable
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
protected
  Names       na "symbolTable";
  Scopes      sc "symbolTable";
  InstInfo    ii "inst info";
  SymbolTable st "symbol table";
algorithm
  G(na, sc, ii, st) := get();
  G(st = outSymbolTable) := set(G(na, sc, ii, inSymbolTable));
end setSymbolTable;

public function newName
  input Name.Name name;
  output Id id;
protected
  Names na;
algorithm
  na := getNames();
  (na, id) := Name.new(na, name);
  na := setNames(na);
end newName;

public function getName
  input Id id;
  output Name.Name name;
protected
  Names na;
algorithm
  na := getNames();
  name := Name.get(na, id);
end getName;

public function newScope
  input Name.Name name;
  input Id parentId;
  input Scope.Kind kind;
  output Id id;
protected
  Names  na;
  Scopes sc;
algorithm
  na := getNames();
  sc := getScopes();
  (sc, na, id) := Scope.new(sc, na, name, parentId, kind);
  na := setNames(na);
end newScope;

public function getScope
  input Id id;
  output Scope.Scope scope;
protected
  Scopes sc;
algorithm
  sc := getScopes();
  scope := Scope.get(sc, id);
end getScope;

end Global;
