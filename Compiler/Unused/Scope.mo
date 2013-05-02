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

encapsulated package Scope
" file:  Scope.mo
  package:     Scope
  description: Scope is a scope in a pool.
  @author:     adrpo

  RCS: $Id: Scope.mo 8980 2011-05-13 09:12:21Z adrpo $

  The Scope representation is a list of segments of name ids in Name"

public
import Name;
import Pool;

protected
import Util;
import List;

public
type Names = Name.Names;
type Name = Name.Name;

public

uniontype Kind
  record TY "a type/class segment"
  end TY;

  record CO "a component segment"
    Integer tyScopeId  "points us into Scopes";
  end CO;

  record UN "a unit segment"
  end UN;

  record NI "an named import segment"
    Integer nameId   "points us into Names";
    Integer scopeId  "points us into Scopes";
  end NI;

  record UI "an unqualified import"
    Integer scopeId  "points us into Scopes";
  end UI;

  record EX "an extends segment"
    Integer tyScopeId  "points us into Scopes";
  end EX;

  record IS "instantiation segment"
    Integer scopeId  "points us into Scopes, any of the above kind";
  end IS;
end Kind;

uniontype Segment "a scope segment can be any of these"
  record S
    Integer id       "points us into Scopes";
    Integer parentId "points us into Scopes, 0 for top";
    Integer nameId   "points us into Names";
    Kind    kind     "the segment kind";
  end S;
end Segment;

type Scope = list<Segment> "BEWARE! Scope segments are in reverse!";

type Scopes = Pool.Pool<Scope> "an array of unique scopes";

constant Integer defaultPoolSizeScopes = 10;

public function pool
  output Scopes outScopes;
algorithm
  outScopes := Pool.create("Scopes", defaultPoolSizeScopes);
end pool;

public function add
  input Scopes inScopes;
  input Scope inScope;
  output Scopes outScopes;
  output Integer outID;
algorithm
  (outScopes, outID) := Pool.add(inScopes, inScope, NONE());
end add;

public function addAutoUpdateId
  input Scopes inScopes;
  input Scope inScope;
  output Scopes outScopes;
  output Integer outID;
algorithm
  (outScopes, outID) := Pool.add(inScopes, inScope, SOME(updateId));
end addAutoUpdateId;

public function get
  input Scopes inScopes;
  input Integer inID;
  output Scope outScope;
algorithm
  outScope := Pool.get(inScopes, inID);
end get;

public function set
  input Scopes inScopes;
  input Integer inID;
  input Scope inScope;
  output Scopes outScopes;
algorithm
  outScopes := Pool.set(inScopes, inID, inScope);
end set;

public function new
  input Scopes   inScopes;
  input Names    inNames;
  input Name     inName;
  input Integer  parentId;
  input Kind     kind;
  output Scopes  outScopes;
  output Names   outNames;
  output Integer outIndex;
protected
  Scope scope;
  Segment segment;
  Integer nameId;
algorithm
  scope := get(inScopes, parentId);
  (outNames, nameId) := Name.new(inNames, inName);
  segment := S(Pool.autoId, parentId, nameId, kind);
  scope := segment::scope;
  (outScopes, outIndex) := Pool.addUnique(inScopes, scope, SOME(updateId), SOME(scopeEqual));
end new;

public function lastSegmentName
  input Names names;
  input Scope scope;
  output String name;
algorithm
  name := matchcontinue(names, scope)
    local
      Integer nameId;
      String n;

    // fine
    case (names, S(nameId = nameId)::_)
      equation
  n = Name.get(names, nameId);
      then
  n;

    // failure
    case (names, scope)
      equation
  print("Failure in Node.lastSegmentName with " +& scopeStr(names, scope) +& "!\n");
      then
  fail();

  end matchcontinue;
end lastSegmentName;

protected function updateId
"@this function will update the scope id
  is mostly used in conjunction with the pool"
  input Scope inScope;
  input Integer inScopeId;
  output Scope outScope;
protected
  Scope scope;
  Integer scopeId, parentId, nameId;
  Kind kind;
algorithm
  S(scopeId, parentId, nameId, kind)::scope := inScope;
  outScope := S(inScopeId, parentId, nameId, kind)::scope;
end updateId;

public function dumpPool
  input Scopes inScopes;
  input Names inNames;
algorithm
  _ := Util.arrayApplyR(Pool.members(inScopes), Pool.next(inScopes), dump, inNames);
end dumpPool;

function dump
  input Names names;
  input Option<Scope> inScopeOpt;
algorithm
  _ := match(names, inScopeOpt)
    local
      Scope s;
      list<String> lst;

    case (names, SOME(s))
      equation
  lst = List.map1r(listReverse(s), segmentStr, names);
  print(stringDelimitList(lst, ".") +& "\n");
      then ();

    case (_, _)
      equation
  print("\n");
      then
  ();
  end match;
end dump;

function segmentStr
  input Names names;
  input Segment inSegment;
  output String outStr;
algorithm
  outStr := match(names, inSegment)
    local
      Integer scopeId "points us into Scopes";
      Integer parentId "points us into Scopes; 0 for top";
      Integer nameId "points us into Names";
      Kind    kind "what kind of segment it is";
      String n, str;

    case (names, S(scopeId, parentId, nameId, kind))
      equation
  n = Name.get(names, nameId);
  str = kindStr(kind) +&
    "[" +& n +& "," +&
    intString(scopeId) +& "," +&
    intString(parentId) +&
    "]";
      then str;
  end match;
end segmentStr;

public function kindStr
  input Kind inKind;
  output String outStr;
algorithm
  outStr := matchcontinue(inKind)
    case (TY())    then "TY";
    case (CO(_))   then "CO";
    case (UN())    then "UN";
    case (NI(_,_)) then "NI";
    case (UI(_))   then "UI";
    case (EX(_))   then "EX";
    case (IS(_))   then "IS";
  end matchcontinue;
end kindStr;

public function scopeStr
  input Names names;
  input Scope scope;
  output String str;
algorithm
  str := matchcontinue(names, scope)
    local
      Integer nameId;
      String n;
      Scope rest;

    case (names, {}) then "Scope(<empty>)";

    // last element
    case (names, {S(nameId = nameId)})
      equation
  n = Name.get(names, nameId);
      then
  n;

    // rest elements
    case (names, S(nameId = nameId)::rest)
      equation
  n = Name.get(names, nameId);
  n = n +& "." +& scopeStr(names, rest);
      then
  n;
  end matchcontinue;
end scopeStr;

public
function scopeEqual
"disregards the segment id when comparing to be able to use the auto id update in Pool"
  input Option<Scope> inOld;
  input Option<Scope> inNew;
  output Boolean isEqual;
algorithm
  isEqual := matchcontinue(inOld, inNew)
    local
      Integer pID1, nID1, pID2, nID2;
      Scope rest1, rest2;
      Kind k1, k2;

    case (NONE(), NONE()) then true;
    case (NONE(),      _) then false;
    case (_,      NONE()) then false;
    case (SOME(S(_,pID1,nID1,k1)::rest1), SOME(S(_,pID2,nID2,k2)::rest2))
      equation
  true = intEq(pID1, pID2);
  true = intEq(nID1, nID2);
  true = valueEq(k1, k2);
  true = valueEq(rest1, rest2);
      then
  true;
    case (_, _) then false;
  end matchcontinue;
end scopeEqual;

end Scope;

