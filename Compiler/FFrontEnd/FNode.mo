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

encapsulated package FNode
" file:        FNode.mo
  package:     FNode
  description: A node structure to hold Modelica constructs


  This module builds nodes out of SCode
"

// public imports
public
import Absyn;
import DAE;
import SCode;
import FCore;

// protected imports
protected
import Error;
import List;
import FGraph;
import FGraphStream;
import Config;
import Flags;

public
type Name = FCore.Name;
type Names = FCore.Names;
type Id = FCore.Id;
type Seq = FCore.Seq;
type Next = FCore.Next;
type Node = FCore.Node;
type Data = FCore.Data;
type Kind = FCore.Kind;
type Ref = FCore.Ref;
type Refs = FCore.Refs;
import FCore.RefTree;
type Children = FCore.Children;
type Parents = FCore.Parents;
type Scope = FCore.Scope;
type ImportTable = FCore.ImportTable;
type Graph = FCore.Graph;
type Extra = FCore.Extra;
type Visited = FCore.Visited;
type Import = FCore.Import;

constant Name extendsPrefix  = "$ext_" "prefix of the extends node";

constant Name topNodeName = "$top";

// these names are used mostly for edges in the graph
// the edges are saved inside the AvlTree ("name", Ref)
constant Name tyNodeName     = "$ty" "type node";
constant Name ftNodeName     = "$ft" "function types node";
constant Name refNodeName    = "$ref" "reference node";
constant Name modNodeName    = "$mod" "modifier node";
constant Name bndNodeName    = "$bnd" "binding node";
constant Name cndNodeName    = "$cnd" "conditional component condition";
constant Name dimsNodeName   = "$dims" "dimensions node";
constant Name tydimsNodeName = "$tydims" "type dimensions node";
constant Name subsNodeName   = "$subs" "cref subscripts";
constant Name ccNodeName     = "$cc" "constrain class node";
constant Name eqNodeName     = "$eq" "equation";
constant Name ieqNodeName    = "$ieq" "initial equation";
constant Name alNodeName     = "$al" "algorithm";
constant Name ialNodeName    = "$ial" "initial algorithm";
constant Name optNodeName    = "$opt" "optimization node";
constant Name edNodeName     = "$ed" "external declaration node";
constant Name forNodeName    = "$for" "scope for for-iterators";
constant Name matchNodeName  = "$match" "scope for match exps";
constant Name cloneNodeName  = "$clone" "clone of the reference node";
constant Name origNodeName   = "$original" "the original of the clone";
constant Name feNodeName     = "$functionEvaluation" "a node for function evaluation";
constant Name duNodeName     = "$definedUnits" "a node for storing defined units";
constant Name veNodeName     = "$ve" "a node for storing references to instance component";
constant Name imNodeName     = "$imp" "an node holding the import table";
constant Name itNodeName     = "$it" "an node holding the instance information DAE.Var";
constant Name assertNodeName = "$assert" "an assersion node";
constant Name statusNodeName = "$status" "an status node";

public function toRef
"@author: adrpo
 turns a node into a ref"
  input Node inNode;
  output Ref outRef;
algorithm
  outRef := arrayCreate(1, inNode);
end toRef;

public function fromRef
"@author: adrpo
 turns a ref into a node"
  input Ref inRef;
  output Node outNode;
algorithm
  outNode := arrayGet(inRef, 1);
end fromRef;

public function updateRef
"@author: adrpo
 sets a node into a ref"
  input Ref inRef;
  input Node inNode;
  output Ref outRef;
algorithm
  outRef := arrayUpdate(inRef, 1, inNode);
end updateRef;

public function id
  input Node inNode;
  output Id id;
algorithm
  FCore.N(id = id) := inNode;
end id;

public function parents
  input Node inNode;
  output Parents p;
algorithm
  FCore.N(parents = p) := inNode;
end parents;

public function hasParents
  input Node inNode;
  output Boolean b;
algorithm
  b := not listEmpty(parents(inNode));
end hasParents;

public function refParents
  input Ref inRef;
  output Parents p;
algorithm
  FCore.N(parents = p) := fromRef(inRef);
end refParents;

public function refPushParents
  input Ref inRef;
  input Parents inParents;
  output Ref outRef;
protected
  Name n;
  Id i;
  Parents p;
  Children c;
  Data d;
algorithm
  FCore.N(n, i, p, c, d) := fromRef(inRef);
  p := listAppend(inParents, p);
  outRef := updateRef(inRef, FCore.N(n, i, p, c, d));
end refPushParents;

public function setParents
  input Node inNode;
  input  Parents inParents;
  output Node outNode;
protected
  Name n;
  Id i;
  Parents p;
  Children c;
  Data d;
algorithm
  FCore.N(n, i, p, c, d) := inNode;
  outNode := FCore.N(n, i, inParents, c, d);
end setParents;

public function target
"returns a target from a REF node"
  input Node inNode;
  output Ref outRef;
algorithm
  outRef::_ := targetScope(inNode);
end target;

public function targetScope
"returns the target scope from a REF node"
  input Node inNode;
  output Scope outScope;
algorithm
  outScope := match(inNode)
    case FCore.N(data = FCore.REF(target = outScope)) then outScope;
  end match;
end targetScope;

public function new
  input Name inName;
  input Id inId;
  input Parents inParents;
  input Data inData;
  output Node node;
algorithm
  node := FCore.N(inName, inId, inParents, RefTree.new(), inData);
end new;

public function addImport
"add import to the import table"
  input SCode.Element inImport;
  input ImportTable inImportTable;
  output ImportTable outImportTable;
algorithm
  outImportTable := match(inImport, inImportTable)
    local
      Import imp;
      list<Import> qual_imps, unqual_imps;
      SourceInfo info;
      Boolean hidden;

    // Unqualified imports
    case (SCode.IMPORT(imp = imp as Absyn.UNQUAL_IMPORT()),
          FCore.IMPORT_TABLE(hidden, qual_imps, unqual_imps))
      equation
        unqual_imps = List.unique(imp :: unqual_imps);
      then
        FCore.IMPORT_TABLE(hidden, qual_imps, unqual_imps);

    // Qualified imports
    case (SCode.IMPORT(imp = imp, info = info),
          FCore.IMPORT_TABLE(hidden, qual_imps, unqual_imps))
      equation
        imp = translateQualifiedImportToNamed(imp);
        checkUniqueQualifiedImport(imp, qual_imps, info);
        qual_imps = List.unique(imp :: qual_imps);
      then
        FCore.IMPORT_TABLE(hidden, qual_imps, unqual_imps);
  end match;
end addImport;

protected function translateQualifiedImportToNamed
  "Translates a qualified import to a named import."
  input Import inImport;
  output Import outImport;
algorithm
  outImport := match(inImport)
    local
      Name name;
      Absyn.Path path;

    // Already named.
    case Absyn.NAMED_IMPORT() then inImport;

    // Get the last identifier from the import and use that as the name.
    case Absyn.QUAL_IMPORT(path = path)
      equation
        name = Absyn.pathLastIdent(path);
      then
        Absyn.NAMED_IMPORT(name, path);
  end match;
end translateQualifiedImportToNamed;

protected function checkUniqueQualifiedImport
  "Checks that a qualified import is unique, because it's not allowed to have
  qualified imports with the same name."
  input Import inImport;
  input list<Import> inImports;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inImport, inImports, inInfo)
    local
      Name name;

    case (_, _, _)
      equation
        false = List.isMemberOnTrue(inImport, inImports,
          compareQualifiedImportNames);
      then
        ();

    case (Absyn.NAMED_IMPORT(name = name), _, _)
      equation
        Error.addSourceMessage(Error.MULTIPLE_QUALIFIED_IMPORTS_WITH_SAME_NAME,
          {name}, inInfo);
      then
        fail();

  end matchcontinue;
end checkUniqueQualifiedImport;

protected function compareQualifiedImportNames
  "Compares two qualified imports, returning true if they have the same import
  name, otherwise false."
  input Import inImport1;
  input Import inImport2;
  output Boolean outEqual;
algorithm
  outEqual := match(inImport1, inImport2)
    local
      Name name1, name2;

    case (Absyn.NAMED_IMPORT(name = name1), Absyn.NAMED_IMPORT(name = name2)) guard stringEqual(name1, name2)
      then
        true;

    else false;
  end match;
end compareQualifiedImportNames;

public function addChildRef
  input Ref inParentRef;
  input Name inName;
  input Ref inChildRef;
protected
  Name n;
  Integer i;
  Parents p;
  Children c;
  Data d;
  Ref parent;
algorithm
  FCore.N(n, i, p, c, d) := fromRef(inParentRef);
  c := RefTree.add(inName, inChildRef, c, RefTree.addConflictReplace);
  parent := updateRef(inParentRef, FCore.N(n, i, p, c, d));
  FGraphStream.edge(inName, fromRef(parent), fromRef(inChildRef));
end addChildRef;

protected function printElementConflictError
  input Ref newRef;
  input Ref oldRef;
  output Ref dummy;
protected
  SourceInfo info1, info2;
  String name;
algorithm
  (name, info1) := SCode.elementNameInfo(FNode.getElementFromRef(newRef));
  info2 := SCode.elementInfo(FNode.getElementFromRef(oldRef));
  Error.addMultiSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS, {name}, {info2, info1});
  fail();
end printElementConflictError;

public function addImportToRef
  input Ref ref;
  input SCode.Element imp;
protected
  Name n;
  Integer id;
  Parents p;
  Children c;
  Data d;
  SCode.Element e;
  Kind t;
  ImportTable it;
  Ref r;
algorithm
  FCore.N(n, id, p, c, FCore.IM(it)) := fromRef(ref);
  it := addImport(imp, it);
  r := updateRef(ref, FCore.N(n, id, p, c, FCore.IM(it)));
end addImportToRef;

public function addTypesToRef
  input Ref ref;
  input list<DAE.Type> inTys;
protected
  Name n;
  Integer id;
  Parents p;
  Children c;
  Data d;
  SCode.Element e;
  Kind t;
  ImportTable it;
  list<DAE.Type> tys;
  Ref r;
algorithm
  FCore.N(n, id, p, c, FCore.FT(tys)) := fromRef(ref);
  tys := List.unique(listAppend(inTys, tys));
  // update the child
  r := updateRef(ref, FCore.N(n, id, p, c, FCore.FT(tys)));
end addTypesToRef;

public function addIteratorsToRef
  input Ref ref;
  input Absyn.ForIterators inIterators;
protected
  Name n;
  Integer id;
  Parents p;
  Children c;
  Data d;
  SCode.Element e;
  Kind t;
  Absyn.ForIterators it;
  Ref r;
algorithm
  FCore.N(n, id, p, c, FCore.FS(it)) := fromRef(ref);
  it := listAppend(it, inIterators);
  // update the child
  r := updateRef(ref, FCore.N(n, id, p, c, FCore.FS(it)));
end addIteratorsToRef;

public function addDefinedUnitToRef
  input Ref ref;
  input SCode.Element du;
protected
  Name n;
  Integer id;
  Parents p;
  Children c;
  Data d;
  SCode.Element e;
  Kind t;
  ImportTable it;
  Ref r;
  list<SCode.Element> dus;
algorithm
  FCore.N(n, id, p, c, FCore.DU(dus)) := fromRef(ref);
  r := updateRef(ref, FCore.N(n, id, p, c, FCore.DU(du::dus)));
end addDefinedUnitToRef;

public function name
  input Node n;
  output String name;
algorithm
  name := match(n)
    local String s;
    case (FCore.N(name = s)) then s;
  end match;
end name;

public function refName
  input Ref r;
  output String n;
algorithm
  n := name(fromRef(r));
end refName;

public function data
  input Node n;
  output Data d;
algorithm
  d := match(n)
    case (FCore.N(data = d)) then d;
  end match;
end data;

public function refData
  input Ref r;
  output Data outData;
algorithm
  outData := data(fromRef(r));
end refData;

public function top
"@author: adrpo
 return the top node ref"
  input Ref inRef;
  output Ref outTop;
algorithm
  outTop := inRef;
  while hasParents(fromRef(outTop)) loop
    outTop := original(parents(fromRef(outTop)));
  end while;
end top;

public function children
  input Node inNode;
  output Children outChildren;
algorithm
  FCore.N(children = outChildren) := inNode;
end children;

public function hasChild
  input Node inNode;
  input Name inName;
  output Boolean b;
algorithm
  b := matchcontinue(inNode, inName)

    case (_, _)
      equation
        _ = childFromNode(inNode, inName);
      then
        true;

    else false;

  end matchcontinue;
end hasChild;

public function refHasChild
  input Ref inRef;
  input Name inName;
  output Boolean b;
algorithm
  b := hasChild(fromRef(inRef), inName);
end refHasChild;

public function setChildren
  input Node inNode;
  input  Children inChildren;
  output Node outNode;
protected
  Name n;
  Id i;
  Parents p;
  Children c;
  Data d;
algorithm
  FCore.N(n, i, p, c, d) := inNode;
  outNode := FCore.N(n, i, p, inChildren, d);
end setChildren;

public function setData
  input Node inNode;
  input  Data inData;
  output Node outNode;
protected
  Name n;
  Id i;
  Parents p;
  Children c;
  Data d;
algorithm
  FCore.N(n, i, p, c, _) := inNode;
  outNode := FCore.N(n, i, p, c, inData);
end setData;

public function child
  input Ref inParentRef;
  input Name inName;
  output Ref outChildRef;
algorithm
  outChildRef := childFromNode(fromRef(inParentRef), inName);
end child;

public function childFromNode
  input Node inNode;
  input Name inName;
  output Ref outChildRef;
protected
  Children c;
algorithm
  c := children(inNode);
  outChildRef := RefTree.get(c, inName);
end childFromNode;

public function element2Data
  input SCode.Element inElement;
  input Kind inKind;
  output Data outData;
  output DAE.Var outVar;
algorithm
  (outData, outVar) := match(inElement, inKind)
    local
      String n;
      SCode.Final finalPrefix;
      SCode.Replaceable repl;
      SCode.Visibility vis;
      SCode.ConnectorType ct;
      SCode.Redeclare redecl;
      Absyn.InnerOuter io;
      SCode.Attributes attr;
      list<Absyn.Subscript> ad;
      SCode.Parallelism prl;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.TypeSpec t;
      SCode.Mod m;
      SCode.Comment comment;
      SourceInfo info;
      Option<Absyn.Exp> condition;
      Data nd;
      DAE.Var i;

    // a component
    case (SCode.COMPONENT(n,SCode.PREFIXES(vis,_,_,io,_),
                                    SCode.ATTR(_,ct,prl,var,dir),
                                    _,_,_,_,_), _)
      equation
        nd = FCore.CO(inElement, DAE.NOMOD(), inKind, FCore.VAR_UNTYPED());
        i  = DAE.TYPES_VAR(
                  n,
                  DAE.ATTR(ct,prl,var,dir,io,vis),
                  DAE.T_UNKNOWN_DEFAULT,
                  DAE.UNBOUND(),NONE());
      then
        (nd, i);

  end match;
end element2Data;

public function dataStr
  input Data inData;
  output String outStr;
algorithm
  outStr := match(inData)
    local
      Name n;
      Absyn.ComponentRef c;
      String m;

    case (FCore.TOP()) then "TOP";
    case (FCore.IT(_)) then "I";
    case (FCore.CL(e = SCode.CLASS(classDef = SCode.CLASS_EXTENDS()))) then "CE";
    case (FCore.CL()) then "C";
    case (FCore.CO()) then "c";
    case (FCore.EX()) then "E";
    case (FCore.DU(_)) then "U";
    case (FCore.FT(_)) then "FT";
    case (FCore.AL(_, _)) then "ALG";
    case (FCore.EQ(_, _)) then "EQ";
    case (FCore.OT(_, _)) then "OPT";
    case (FCore.ED(_)) then "ED";
    case (FCore.FS(_)) then "FS";
    case (FCore.FI(_)) then "FI";
    case (FCore.MS(_)) then "MS";
    case (FCore.MO(_)) then "M";
    case (FCore.EXP(name=n)) then n;
    case (FCore.DIMS(name=n)) then n;
    case (FCore.CR(_)) then "r";
    case (FCore.CC(_)) then "CC";
    case (FCore.ND(_)) then "ND";
    case (FCore.REF(_)) then "REF";
    case (FCore.VR()) then "VR";
    case (FCore.IM(_)) then "IM";
    case (FCore.ASSERT(m)) then "assert(" + m + ")";

    else "UKNOWN NODE DATA";

  end match;
end dataStr;

public function toStr
  input Node inNode;
  output String outStr;
algorithm
  outStr := matchcontinue(inNode)
    local
     Name n;
     Id i;
     Parents p;
     Children c;
     Data d;

    case (FCore.N(_, i, p, _, d))
      equation
        outStr =
           "[i:" + intString(i) + "] " +
           "[p:" + stringDelimitList(List.map(List.map(List.map(p, fromRef), id), intString), ", ") + "] " +
           "[n:" + name(inNode) + "] " +
           "[d:" + dataStr(d) + "]";
      then
        outStr;

    else "Unhandled node!";

  end matchcontinue;
end toStr;

public function toPathStr
"returns the path from top to this node"
  input Node inNode;
  output String outStr;
algorithm
  outStr := matchcontinue(inNode)
    local
     Name n;
     Id id;
     Parents p;
     Children c;
     Data d;
     Ref nr;
     String s;

    // top node
    case (FCore.N(_, _, {}, _, _))
      equation
        outStr = name(inNode);
      then
        outStr;

    case (FCore.N(_, _, p, _, _))
      equation
        nr = contextual(p);
        true = hasParents(fromRef(nr));
        s = toPathStr(fromRef(nr));
        outStr = s + "." + name(inNode);
      then
        outStr;

    case (FCore.N(_, _, p, _, _))
      equation
        nr = contextual(p);
        false = hasParents(fromRef(nr));
        outStr = "." + name(inNode);
      then
        outStr;
  end matchcontinue;
end toPathStr;

public function scopeStr
"note that this function returns the scopes in reverse"
  input Scope sc;
  output String s;
algorithm
  s := stringDelimitList(List.map(listReverse(sc), refName), "/");
end scopeStr;

public function isImplicitScope
"anything that is not top, class or a component is an implicit scope!"
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.TOP()) then false;
    case FCore.N(data = FCore.CL()) then false;
    case FCore.N(data = FCore.CO()) then false;
    case FCore.N(data = FCore.CC()) then false;
    case FCore.N(data = FCore.FS()) then false;
    case FCore.N(data = FCore.MS()) then false;
    case FCore.N(data = FCore.VR()) then false;
    else true;
  end match;
end isImplicitScope;

public function isRefImplicitScope
"anything that is not a class or a component is an implicit scope!"
  input Ref inRef;
  output Boolean b;
algorithm
  b := isImplicitScope(fromRef(inRef));
end isRefImplicitScope;

public function isEncapsulated
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.CL(e = SCode.CLASS(encapsulatedPrefix = SCode.ENCAPSULATED()))) then true;
    case FCore.N(data = FCore.CO()) guard boolEq(Config.acceptMetaModelicaGrammar(), false) and boolNot(Flags.isSet(Flags.GRAPH_INST))
      then true;
    else false;
  end match;
end isEncapsulated;

public function isReference
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.REF()) then true;
    else false;
  end match;
end isReference;

public function isUserDefined
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    local Ref p;
    case FCore.N(data = FCore.CL(kind = FCore.USERDEFINED())) then true;
    case FCore.N(data = FCore.CO(kind = FCore.USERDEFINED())) then true;
    // any parent is userdefined?
    case _ guard hasParents(inNode)
      equation
        p::_ = parents(inNode);
        b = isRefUserDefined(p);
      then
        b;
    else false;
  end match;
end isUserDefined;

public function isTop
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.TOP()) then true;
    else false;
  end match;
end isTop;

public function isExtends
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.EX()) then true;
    else false;
  end match;
end isExtends;

public function isDerived
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    local SCode.Element e;
    case FCore.N(data = FCore.CL(e = e)) then SCode.isDerivedClass(e);
    else false;
  end match;
end isDerived;

public function isClass
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.CL()) then true;
    else false;
  end match;
end isClass;

public function isInstance
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.CL(status = FCore.CLS_INSTANCE(_))) then true;
    else false;
  end match;
end isInstance;

public function isRedeclare
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.CL(e = SCode.CLASS(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())))) then true;
    case FCore.N(data = FCore.CO(e = SCode.COMPONENT(prefixes = SCode.PREFIXES(redeclarePrefix = SCode.REDECLARE())))) then true;
    else false;
  end match;
end isRedeclare;

public function isClassExtends
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.CL(e = SCode.CLASS(classDef = SCode.CLASS_EXTENDS()))) then true;
    else false;
  end match;
end isClassExtends;

public function isComponent
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.CO()) then true;
    else false;
  end match;
end isComponent;

public function isConstrainClass
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.CC()) then true;
    else false;
  end match;
end isConstrainClass;

public function isCref
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.CR()) then true;
    else false;
  end match;
end isCref;

public function isBasicType
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.CL(kind = FCore.BASIC_TYPE())) then true;
    else false;
  end match;
end isBasicType;

public function isBuiltin
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.CL(kind = FCore.BUILTIN())) then true;
    case FCore.N(data = FCore.CO(kind = FCore.BUILTIN())) then true;
    else false;
  end match;
end isBuiltin;

public function isFunction
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    local
      SCode.Element e;
    case FCore.N(data = FCore.CL(e = e)) guard SCode.isFunction(e) or SCode.isOperator(e)
      then true;
    else false;
  end match;
end isFunction;

public function isRecord
  input Node inNode;
  output Boolean b = false;
algorithm
  b := match(inNode)
    local
      SCode.Element e;
    case FCore.N(data = FCore.CL(e = e)) guard SCode.isRecord(e)
      then true;
    else false;
  end match;
end isRecord;

public function isSection
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case (FCore.N(data = FCore.AL())) then true;
    case (FCore.N(data = FCore.EQ())) then true;
    else false;
  end match;
end isSection;

public function isMod
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case (FCore.N(data = FCore.MO())) then true;
    else false;
  end match;
end isMod;

public function isModHolder
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    local Name n;
    case (FCore.N(name = n, data = FCore.MO())) then stringEq(n, modNodeName);
    else false;
  end match;
end isModHolder;

public function isClone
"a node is a clone if its parent is a version node"
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    local Ref r;
    case FCore.N(parents = r::_)
      equation
        b = isRefVersion(r);
      then b;
    else false;
  end match;
end isClone;

public function isVersion
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case FCore.N(data = FCore.VR()) then true;
    else false;
  end match;
end isVersion;

public function isDims
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    case (FCore.N(data = FCore.DIMS())) then true;
    else false;
  end match;
end isDims;

public function isIn
  input Node inNode;
  input FunctionRefIs inFunctionRefIs;
  output Boolean b;
  partial function FunctionRefIs
    input Ref inRef;
    output Boolean is;
  end FunctionRefIs;
algorithm
  b := match(inNode, inFunctionRefIs)
    local
      Scope s;
      Boolean b1, b2;

    case (_, _)
      equation
        s = originalScope(toRef(inNode));
        b1 = List.applyAndFold(s, boolOr, inFunctionRefIs, false);
        s = contextualScope(toRef(inNode));
        b2 = List.applyAndFold(s, boolOr, inFunctionRefIs, false);
        b = boolOr(b1, b2);
      then
        b;

  end match;
end isIn;

public function nonImplicitRefFromScope
"@author: adrpo
 returns the first NON implicit
 reference from the given scope!"
  input Scope inScope;
  output Ref outRef;
algorithm
  outRef := match(inScope)
    local
      Ref r;
      Scope rest;

    case ({}) then fail();

    case (r::_) guard not isRefImplicitScope(r)
      then
        r;

    case (_::rest)
      then
        nonImplicitRefFromScope(rest);
  end match;
end nonImplicitRefFromScope;

public function namesUpToParentName
"@author: adrpo
 returns the names of parents up
 to the given name. if the name
 is not found up to the top the
 empty list is returned.
 note that for A.B.C.D.E.F searching for B from F will give you
 {C, D, E, F}"
  input Ref inRef;
  input Name inName;
  output Names outNames;
algorithm
   outNames := namesUpToParentName_dispatch(inRef, inName, {});
end namesUpToParentName;

protected function namesUpToParentName_dispatch
"@author: adrpo
 returns the names of parents up
 to the given name. if the name
 is not found up to the top the
 empty list is returned.
 note that for A.B.C.D.E.F searching for B from F will give you
 {C, D, E, F}"
  input Ref inRef;
  input Name inName;
  input Names acc;
  output Names outNames;
algorithm
   outNames := match(inRef, inName, acc)
    local
      Ref r;
      Names names;
      Name name;

    // bah, error!
    case (r, _, _) guard isRefTop(r)
      then
        {};

    // we're done, return
    case (r, _, _) guard stringEq(inName, refName(r))
      then
        acc;

    // up the parent
    case (r, name, _)
      then
        namesUpToParentName_dispatch(original(refParents(r)), name, refName(r) :: acc);

  end match;
end namesUpToParentName_dispatch;

public function getModifierTarget
"@author: adrpo
 returns the target of the modifer"
  input Ref inRef;
  output Ref outRef;
algorithm
   outRef := matchcontinue(inRef)
    local
      Ref r;

    // bah, error!
    case (r) guard isRefTop(r)
      then
        fail();

    // we're done, return
    case (r) guard isRefModHolder(r)
      equation
        // get his parent
        r = original(refParents(r));
        r::_ = refRefTargetScope(r);
      then
        r;

    // up the parent
    else getModifierTarget(original(refParents(inRef)));

  end matchcontinue;
end getModifierTarget;

public function originalScope
"@author:
 return the scope from this ref to the top as a list of references.
 NOTE:
   the starting point reference is included and
   the scope is returned reversed, from leafs
   to top"
  input Ref inRef;
  output Scope outScope;
algorithm
  outScope := originalScope_dispatch(inRef, {});
end originalScope;

public function originalScope_dispatch
"@author:
 return the scope from this ref to the top as a list of references.
 NOTE:
   the starting point reference is included and
   the scope is returned reversed, from leafs
   to top"
  input Ref inRef;
  input Scope inAcc;
  output Scope outScope;
algorithm
  outScope := match(inRef, inAcc)
    local
      Scope acc;
      Ref r;

    // top
    case (_, acc) guard isTop(fromRef(inRef))
      then
        listReverse(inRef::acc);

    // not top
    case (_, acc)
      equation
        r = original(parents(fromRef(inRef)));
      then
        originalScope_dispatch(r, inRef::acc);

  end match;
end originalScope_dispatch;

public function original
"@author:
 return the original parent from the parents (the last one)"
  input Parents inParents;
  output Ref outOriginal;
algorithm
  outOriginal := List.last(inParents);
end original;

public function contextualScope
"@author:
 return the scope from this ref to the top as a list of references.
 NOTE:
   the starting point reference is included and
   the scope is returned reversed, from leafs
   to top"
  input Ref inRef;
  output Scope outScope;
algorithm
  outScope := contextualScope_dispatch(inRef, {});
end contextualScope;

public function contextualScope_dispatch
"@author:
 return the scope from this ref to the top as a list of references.
 NOTE:
   the starting point reference is included and
   the scope is returned reversed, from leafs
   to top"
  input Ref inRef;
  input Scope inAcc;
  output Scope outScope;
algorithm
  outScope := match(inRef, inAcc)
    local
      Scope acc;
      Ref r;

    // top
    case (_, acc) guard isTop(fromRef(inRef))
      then
        listReverse(inRef::acc);

    // not top
    case (_, acc)
      equation
        r = contextual(parents(fromRef(inRef)));
      then
        contextualScope_dispatch(r, inRef::acc);

  end match;
end contextualScope_dispatch;

public function contextual
"@author:
 return the contextual parent from the parents (the first one)"
  input Parents inParents;
  output Ref outContextual;
algorithm
  outContextual := listHead(inParents);
end contextual;

public function lookupRef
"@author: adrpo
 lookup a reference based on given scope names
 NOTE:
  inRef/outRef could be in a totally different graph"
  input Ref inRef;
  input Scope inScope;
  output Ref outRef;
algorithm
  outRef := matchcontinue(inRef, inScope)
    local
      Scope s;
      Ref r;

    // for the top, return itself
    case (_, {_}) then inRef;

    case (_, s)
      equation
        // print("Searching for scope: " + toPathStr(fromRef(listHead(s))) + " in " + toPathStr(fromRef(inRef)) + "\n");
        // reverse and remove top
        _::s = listReverse(s);
        r = lookupRef_dispatch(inRef, s);
      then
        r;
  end matchcontinue;
end lookupRef;

public function lookupRef_dispatch
"@author: adrpo
 lookup a reference based on given scope names
 NOTE:
  inRef/outRef could be in a totally different graph"
  input Ref inRef;
  input Scope inScope;
  output Ref outRef;
algorithm
  outRef := match(inRef, inScope)
    local
      Ref r;
      Scope rest;
      Name n;

    case (_, {}) then inRef;

    case (_, r::rest)
      equation
        n = name(fromRef(r));
        // print("Lookup child: " + n + " in " + toPathStr(fromRef(inRef)) + "\n");
        r = child(inRef, n);
        r = lookupRef_dispatch(r, rest);
      then
        r;

  end match;
end lookupRef_dispatch;

public function filter
"@author: adrpo
 filter the children of the given
 reference by the given filter"
  input Ref inRef;
  input Filter inFilter;
  output Refs filtered;
  partial function Filter
    input Ref inRef;
    output Boolean select;
  end Filter;
protected
  Children c;
algorithm
  c := children(fromRef(inRef));
  filtered := RefTree.fold(c, function filter_work(filter = inFilter), {});
  filtered := listReverse(filtered);
end filter;

protected function filter_work
  input Name name;
  input Ref ref;
  input Filter filter;
  input Refs accum;
  output Refs refs = accum;

  partial function Filter
    input Ref inRef;
    output Boolean select;
  end Filter;
algorithm
  if filter(ref) then
    refs := ref :: refs;
  end if;
end filter_work;

public function isRefExtends
  input Ref inRef;
  output Boolean b;
algorithm
  b := isExtends(fromRef(inRef));
end isRefExtends;

public function isRefDerived
  input Ref inRef;
  output Boolean b;
algorithm
  b := isDerived(fromRef(inRef));
end isRefDerived;

public function isRefComponent
  input Ref inRef;
  output Boolean b;
algorithm
  b := isComponent(fromRef(inRef));
end isRefComponent;

public function isRefConstrainClass
  input Ref inRef;
  output Boolean b;
algorithm
  b := isConstrainClass(fromRef(inRef));
end isRefConstrainClass;

public function isRefClass
  input Ref inRef;
  output Boolean b;
algorithm
  b := isClass(fromRef(inRef));
end isRefClass;

public function isRefInstance
  input Ref inRef;
  output Boolean b;
algorithm
  b := isInstance(fromRef(inRef));
end isRefInstance;

public function isRefRedeclare
  input Ref inRef;
  output Boolean b;
algorithm
  b := isRedeclare(fromRef(inRef));
end isRefRedeclare;

public function isRefClassExtends
  input Ref inRef;
  output Boolean b;
algorithm
  b := isClassExtends(fromRef(inRef));
end isRefClassExtends;

public function isRefCref
  input Ref inRef;
  output Boolean b;
algorithm
  b := isCref(fromRef(inRef));
end isRefCref;

public function isRefReference
  input Ref inRef;
  output Boolean b;
algorithm
  b := isReference(fromRef(inRef));
end isRefReference;

public function isRefUserDefined
  input Ref inRef;
  output Boolean b;
algorithm
  b := isUserDefined(fromRef(inRef));
end isRefUserDefined;

public function isRefTop
  input Ref inRef;
  output Boolean b;
algorithm
  b := isTop(fromRef(inRef));
end isRefTop;

public function isRefBasicType
  input Ref inRef;
  output Boolean b;
algorithm
  b := isBasicType(fromRef(inRef));
end isRefBasicType;

public function isRefBuiltin
  input Ref inRef;
  output Boolean b;
algorithm
  b := isBuiltin(fromRef(inRef));
end isRefBuiltin;

public function isRefFunction
  input Ref inRef;
  output Boolean b;
algorithm
  b := isFunction(fromRef(inRef));
end isRefFunction;

public function isRefRecord
  input Ref inRef;
  output Boolean b;
algorithm
  b := isRecord(fromRef(inRef));
end isRefRecord;

public function isRefSection
  input Ref inRef;
  output Boolean b;
algorithm
  b := isSection(fromRef(inRef));
end isRefSection;

public function isRefMod
  input Ref inRef;
  output Boolean b;
algorithm
  b := isMod(fromRef(inRef));
end isRefMod;

public function isRefModHolder
  input Ref inRef;
  output Boolean b;
algorithm
  b := isModHolder(fromRef(inRef));
end isRefModHolder;

public function isRefClone
  input Ref inRef;
  output Boolean b;
algorithm
  b := isClone(fromRef(inRef));
end isRefClone;

public function isRefVersion
  input Ref inRef;
  output Boolean b;
algorithm
  b := isVersion(fromRef(inRef));
end isRefVersion;

public function isRefDims
  input Ref inRef;
  output Boolean b;
algorithm
  b := isDims(fromRef(inRef));
end isRefDims;

public function isRefIn
  input Ref inRef;
  input FunctionRefIs inFunctionRefIs;
  output Boolean b;
  partial function FunctionRefIs
    input Ref inRef;
    output Boolean is;
  end FunctionRefIs;
algorithm
  b := isIn(fromRef(inRef), inFunctionRefIs);
end isRefIn;

public function dfs
"@author: adrpo
 return all refs as given by
 depth first search"
  input Ref inRef;
  output Refs outRefs;
algorithm
  outRefs := match(inRef)
    local
      Refs refs;
      Children c;

    case _
      equation
        c = children(fromRef(inRef));
        refs = RefTree.listValues(c);
        refs = List.flatten(List.map(refs, dfs));
        refs = inRef::refs;
      then
        refs;

  end match;
end dfs;

public function apply1
"@author: adrpo
 apply a function on all the subtree pointed by given ref.
 the order of application is dfs."
  input Ref inRef;
  input Apply inApply;
  input ExtraArg inExtraArg;
  output ExtraArg outExtraArg;
  partial function Apply
    input Name name;
    input Ref inRef;
    input ExtraArg inExtraArg;
    output ExtraArg outExtraArg;
  end Apply;
  replaceable type ExtraArg subtypeof Any;
algorithm
  outExtraArg := RefTree.fold(children(fromRef(inRef)), inApply, inExtraArg);
  outExtraArg := inApply(refName(inRef), inRef, outExtraArg);
end apply1;

public function hasImports
  input Node inNode;
  output Boolean b;
algorithm
  b := match(inNode)
    local list<Import> qi, uqi;

    case (_)
      equation
        FCore.IMPORT_TABLE(_, qi, uqi) = importTable(fromRef(refImport(toRef(inNode))));
        b = boolOr(not listEmpty(qi), not listEmpty(uqi));
      then
        b;

    else false;
  end match;
end hasImports;

public function imports
  input Node inNode;
  output list<Import> outQualifiedImports;
  output list<Import> outUnQualifiedImports;
algorithm
  (outQualifiedImports, outUnQualifiedImports) := match(inNode)
    local list<Import> qi, uqi;
    case (_)
      equation
         FCore.IMPORT_TABLE(_, qi, uqi) = importTable(fromRef(refImport(toRef(inNode))));
      then
        (qi, uqi);
    else ({}, {});
  end match;
end imports;

public function derivedRef
  input Ref inRef;
  output Refs outRefs;
algorithm
  outRefs := match(inRef)
    local Ref r;
    case (_) guard isRefDerived(inRef)
      then
        {child(inRef, refNodeName)};

    else {};

  end match;
end derivedRef;


public function extendsRefs
  input Ref inRef;
  output Refs outRefs;
algorithm
  outRefs := match(inRef)
    local
      Refs refs, rd;

    case (_) guard isRefClass(inRef) // we have a class
      equation
        // get the derived ref
        rd = derivedRef(inRef);
        // get the extends
        refs = filter(inRef, isRefExtends);
        refs = List.flatten(List.map1(refs, filter, isRefReference));
        refs = listAppend(rd,refs);
      then
        refs;

    else {};

  end match;
end extendsRefs;

public function cloneRef
"@author: adrpo
 clone a node ref entire subtree
 the clone will have 2 parents
 {inParentRef, originalParentRef}"
  input Name inName;
  input Ref inRef;
  input Ref inParentRef;
  input Graph inGraph;
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := match(inName, inRef, inParentRef, inGraph)
    local
      Node n;
      Graph g;
      Ref r;

    case (_, _, _, g)
      equation
        (g, r) = clone(fromRef(inRef), inParentRef, g);
        addChildRef(inParentRef, inName, r);
      then
        (g, r);

  end match;
end cloneRef;

public function clone
"@author: adrpo
 clone a node entire subtree
 the clone will have 2 parents
 {inParentRef, originalParentRef}"
  input Node inNode;
  input Ref inParentRef;
  input Graph inGraph;
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := match(inNode, inParentRef, inGraph)
    local
      Node n;
      Graph g;
      Ref r;
      Name name;
      Id id;
      Parents parents;
      Children children;
      Data data;

    case (FCore.N(name, id, parents, children, data), _, g)
      equation
        // add parent
        parents = inParentRef::parents;
        // create node clone
        (g, n as FCore.N(name, id, parents, _, data)) = FGraph.node(g, name, parents, data);
        // make the reference to the new node
        r = toRef(n);
        // clone children
        (g, children) = cloneTree(children, r, g);
        // set the children in the new node
        r = updateRef(r, FCore.N(name, id, parents, children, data));
      then
        (g, r);

  end match;
end clone;

public function cloneTree
"@author: adrpo
 clone a node entire subtree
 the clone will have 2 parents
 {inParentRef, originalParentRef}"
  input Children inChildren;
  input Ref inParentRef;
  input Graph inGraph;
  output Graph outGraph;
  output Children outChildren;
algorithm
  (outChildren, outGraph) :=
    RefTree.mapFold(inChildren, function cloneChild(parentRef = inParentRef), inGraph);
end cloneTree;

protected function cloneChild
  input Name name;
  input Ref parentRef;
  input Ref inRef;
  input Graph inGraph;
  output Ref ref;
  output Graph graph;
algorithm
  (graph, ref) := cloneRef(name, inRef, parentRef, inGraph);
end cloneChild;

public function copyRef
"@author: adrpo
 copy a node ref entire subtree
 this is like clone but the parents are kept as they are"
  input Ref inRef;
  input Graph inGraph;
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := match(inRef, inGraph)
    local
      Node n;
      Graph g;
      Ref r;

    case (_, g)
      equation
        // first copy the entire tree as it is
        // generating new array references
        r = copyRefNoUpdate(inRef);
        // then update all array references
        // in the tree to their new places
        (g, r) = updateRefs(r, g);
      then
        (g, r);

  end match;
end copyRef;

public function updateRefs
"@author: adrpo
 update all parent and node data references in the graph"
  input Ref inRef;
  input Graph inGraph;
  output Graph outGraph;
  output Ref outRef;
algorithm
  (outGraph, outRef) := match(inRef, inGraph)
    local
      Node n;
      Graph g;
      Ref r;

    case (_, g)
      equation
        // for each node in the tree
        // update all refs from the node parents or node data
        ((r, g)) = apply1(inRef, updateRefInGraph, (inRef, g));
      then
        (g, r);

  end match;
end updateRefs;

protected function updateRefInGraph
  input Name name;
  input Ref inRef;
  input tuple<Ref, Graph> inTopRefAndGraph;
  output tuple<Ref, Graph> outTopRefAndGraph;
algorithm
  outTopRefAndGraph := match(inRef, inTopRefAndGraph)
    local
      Ref r, t;
      Graph g;
      Name n;
      Id i;
      Parents p;
      Children c;
      Data d;

    case (_, (t, g))
      equation
        // print("Updating references in node: " + toStr(fromRef(inRef)) + " / [" + toPathStr(fromRef(inRef)) + "]\n");
        FCore.N(n, i, p, c, d) = fromRef(inRef);
        p = List.map1r(p, lookupRefFromRef, t);
        d = updateRefInData(d, t);
        _ = updateRef(inRef, FCore.N(n, i, p, c, d));
      then
        ((t, g));

  end match;
end updateRefInGraph;

public function lookupRefFromRef
"@author: adrpo
 lookup a reference based on old reference in a different graph"
  input Ref inRef;
  input Ref inOldRef;
  output Ref outRef;
algorithm
  outRef := match(inRef, inOldRef)
    local
      Ref r;
      Scope s;
    case (_, _)
      equation
        // get the original scope from the old ref
        s = originalScope(inOldRef);
        r = lookupRef(inRef, s);
      then
        r;
  end match;
end lookupRefFromRef;

protected function updateRefInData
"@author: adrpo
 update references in the node data currently just REF and CLONE hold other references.
 if you add more nodes in FCore that have references in them you need to update this function too!"
  input Data inData;
  input Ref inRef;
  output Data outData;
algorithm
  outData := match(inData, inRef)
    local
      Ref oldRef, r;
      SCode.Element e;
      DAE.Var i;
      DAE.Mod m;
      FCore.Status s;
      Kind k;
      Scope sc;

    case (FCore.REF(sc), _)
      equation
        sc = List.map1r(sc, lookupRefFromRef, inRef);
      then
        FCore.REF(sc);

    else inData;

  end match;
end updateRefInData;

public function copyRefNoUpdate
"@author: adrpo
 copy a node ref entire subtree"
  input Ref inRef;
  output Ref outRef = copy(fromRef(inRef));
end copyRefNoUpdate;

protected function copy
"@author: adrpo
 copy a node entire subtree.
 this is like clone but the parents are kept as they are"
  input Node inNode;
  output Ref outRef;
protected
  Node node = inNode;
algorithm
  outRef := match node
    case FCore.N()
      algorithm
        // copy children
        node.children := RefTree.map(node.children, copyChild);
      then
        toRef(node);
  end match;
end copy;

protected function copyChild
  input Name name;
  input Ref inRef;
  output Ref ref = copyRefNoUpdate(inRef);
end copyChild;

public function getElement
"@author: adrpo
 get element from the node data"
  input Node inNode;
  output SCode.Element outElement;
algorithm
  outElement := match(inNode)
    local
      SCode.Element e;
    case (FCore.N(data = FCore.CL(e = e))) then e;
    case (FCore.N(data = FCore.CO(e = e))) then e;
  end match;
end getElement;

public function getElementFromRef
"@author: adrpo
 get element from the ref"
  input Ref inRef;
  output SCode.Element outElement;
algorithm
  outElement := getElement(fromRef(inRef));
end getElementFromRef;

public function isImplicitRefName
"returns true if the node ref is a for-loop scope or a valueblock scope.
 This is indicated by the name of the frame."
  input Ref r;
  output Boolean b;
algorithm
  b := match r

    case _ guard not isRefTop(r)
      then
        FCore.isImplicitScope(refName(r));

    else false;

  end match;
end isImplicitRefName;

public function refInstVar
"@author: adrpo
 get the DAE.Var from the child node named itNodeName of this reference"
  input Ref inRef;
  output DAE.Var v;
protected
  Ref r;
algorithm
  r := refInstance(inRef);
  FCore.IT(i = v) := refData(r);
end refInstVar;

public function refInstance
  input Ref inRef;
  output Ref r;
algorithm
  r := child(inRef, itNodeName);
end refInstance;

public function isRefRefUnresolved
  input Ref inRef;
  output Boolean b;
algorithm
  b := matchcontinue(inRef)

    case (_)
      equation
        _ = refRef(inRef); // node exists
        b = listEmpty(refRefTargetScope(inRef)); // with non empty scope
      then
        b;

    else true;

  end matchcontinue;
end isRefRefUnresolved;

public function isRefRefResolved
  input Ref inRef;
  output Boolean b;
algorithm
  b := not isRefRefUnresolved(inRef);
end isRefRefResolved;

public function refRef
  input Ref inRef;
  output Ref r;
algorithm
  r := child(inRef, refNodeName);
end refRef;

public function refRefTargetScope
  input Ref inRef;
  output Scope sc;
protected
  Ref r;
algorithm
  r := refRef(inRef);
  sc := targetScope(fromRef(r));
end refRefTargetScope;

public function refImport
  input Ref inRef;
  output Ref r;
algorithm
  r := child(inRef, imNodeName);
end refImport;

public function importTable
"returns the import table from a IM node"
  input Node inNode;
  output ImportTable it;
algorithm
  it := match(inNode)
    case FCore.N(data = FCore.IM(i = it)) then it;
  end match;
end importTable;

public function mkExtendsName
  input Absyn.Path inPath;
  output Name outName;
algorithm
  outName := extendsPrefix + Absyn.pathString(inPath);
end mkExtendsName;

annotation(__OpenModelica_Interface="frontend");
end FNode;
