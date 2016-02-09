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

encapsulated package FCore
" file:        FCore.mo
  package:     FCore
  description: Structures to hold Modelica constructs

  RCS: $Id: FCore.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module holds types used in FNode, FGraph and all the other F* packages
"


public
import Absyn;
import DAE;
import SCode;
import Prefix;
import HashTable;

protected
import BaseHashTable;
import DAEUtil;
import Config;

// ************************ FNode structures ***************************
// ************************ FNode structures ***************************
// ************************ FNode structures ***************************
// ************************ FNode structures ***************************

public
type Name = String "an identifier is just a string";
type Names = list<Name> "list of names";
type Import = Absyn.Import;
type Id = Integer;
type Seq = Integer;
type Next = Seq;

constant ImportTable emptyImportTable = IMPORT_TABLE(false, {}, {});

uniontype ImportTable
  record IMPORT_TABLE
    // Imports should not be inherited, but removing them from the node
    // when doing lookup through extends causes problems for the lookup later
    // on, because for example components may have types that depends on
    // imports.  The hidden flag allows the lookup to 'hide' the imports
    // temporarily, without actually removing them.
    Boolean hidden "If true means that the imports are hidden.";
    list<Import> qualifiedImports;
    list<Import> unqualifiedImports;
  end IMPORT_TABLE;
end ImportTable;

type Ref = Array<Node> "array of 1";

uniontype Node
  record N
    Name     name       "node name, class/component/extends name, etc. see also *NodeName in above";
    Id       id         "Unique node id";
    Parents  parents    "A node can have several parents depending on the context";
    Children children   "List of uniquely named classes and variables";
    Data     data       "More data for this node, Class, Var, etc";
  end N;
end Node;

public uniontype ModScope
  "Used to know where a modifier came from, for error reporting."
  record MS_COMPONENT
    String name;
  end MS_COMPONENT;

  record MS_EXTENDS
    Absyn.Path path;
  end MS_EXTENDS;

  record MS_DERIVED
    Absyn.Path path;
  end MS_DERIVED;

  record MS_CLASS_EXTENDS
    String name;
  end MS_CLASS_EXTENDS;

  record MS_CONSTRAINEDBY
    Absyn.Path path;
  end MS_CONSTRAINEDBY;

end ModScope;

uniontype Data
  record TOP "top"
  end TOP;

  record IT
    DAE.Var i "instantiated component";
  end IT;

  record IM "import"
    ImportTable i "imports";
  end IM;

  record CL "class"
    SCode.Element e;
    Prefix.Prefix pre;
    DAE.Mod mod "modification";
    Kind kind "usedefined, builtin, basic type";
    Status status "if it is untyped, typed or fully instantiated (dae)";
  end CL;

  record CO "component"
    SCode.Element e;
    DAE.Mod mod "modification";
    Kind kind "usedefined, builtin, basic type";
    Status status "if it is untyped, typed or fully instantiated (dae)";
  end CO;

  record EX "extends"
    SCode.Element e;
    DAE.Mod mod "modification";
  end EX;

  record DU "units"
    list<SCode.Element> els;
  end DU;

  record FT "function type nodes"
    list<DAE.Type> tys "list since several types with the same name can exist in the same scope (overloading)";
  end FT;

  record AL "algorithm section"
    Name name "al or ial (initial)";
    list<SCode.AlgorithmSection> a;
  end AL;

  record EQ "equation section"
    Name name "eq or ieq (initial)";
    list<SCode.Equation> e;
  end EQ;

  record OT "optimization"
    list<SCode.ConstraintSection> constrainLst;
    list<Absyn.NamedArg> clsAttrs;
  end OT;

  record ED "external declaration"
    SCode.ExternalDecl ed;
  end ED;

  record FS "for iterators scope"
    Absyn.ForIterators fis;
  end FS;

  record FI "for iterator"
    Absyn.ForIterator fi;
  end FI;

  record MS "match scope"
    Absyn.Exp e;
  end MS;

  record MO "mod"
    SCode.Mod m;
  end MO;

  record EXP "binding, condition, array dim, etc"
    String name "what is the expression for";
    Absyn.Exp e;
  end EXP;

  record CR "component reference"
    Absyn.ComponentRef r;
  end CR;

  record DIMS "dimensions"
    String name "what are the dimensions for, type or component";
    Absyn.ArrayDim dims;
  end DIMS;

  record CC "constrainedby class"
    SCode.ConstrainClass cc;
  end CC;

  record REF "reference node"
    Scope target;
  end REF;

  record ND "no data"
    Option<ScopeType> scopeType;
  end ND;

  record VR "version node, contains the node that decided the generation of the clone"
    Scope source;
    Prefix.Prefix p;
    DAE.Mod m;
    Option<ScopeType> scopeType;
  end VR;

  record ASSERT "an assertion node, to be used in places
    where we want to assert things in the graph.
    for example if we looked up A.B from A.B.C.D
    but could not find C then we add an assertion
    node. we have just a message here but might
    add new info later on."
    String message;
  end ASSERT;

  record STATUS "status node"
    Boolean isInstantiating;
  end STATUS;

end Data;

type Refs = list<Ref>;
type Parents = Refs;
type Scope = Refs;
type Children = CAvlTree;

public type CAvlKey = Name;
public type CAvlValue = Ref;

public constant Scope emptyScope = {} "empty scope";

uniontype CAvlTree "The binary tree data structure for children"
  record CAVLTREENODE
    Option<CAvlTreeValue> value "Value" ;
    Integer height "heigth of tree, used for balancing";
    Option<CAvlTree> left "left subtree" ;
    Option<CAvlTree> right "right subtree" ;
  end CAVLTREENODE;
end CAvlTree;

uniontype CAvlTreeValue "Each node in the binary tree can have a value associated with it."
  record CAVLTREEVALUE
    CAvlKey key "Key" ;
    CAvlValue value "Value" ;
  end CAVLTREEVALUE;
end CAvlTreeValue;

constant CAvlTree emptyCAvlTree = CAVLTREENODE(NONE(),0,NONE(),NONE());

uniontype Kind
  record USERDEFINED end USERDEFINED;
  record BUILTIN end BUILTIN;
  record BASIC_TYPE end BASIC_TYPE;
end Kind;

public uniontype Status
"Used to distinguish between different phases of the instantiation of a component
A component is first added to environment untyped. It can thereafter be instantiated to get its type
and finally instantiated to produce the DAE. These three states are indicated by this datatype."

  record VAR_UNTYPED "Untyped variables, initially added to env"
  end VAR_UNTYPED;

  record VAR_TYPED "Typed variables, when instantiation to get type has been performed"
  end VAR_TYPED;

  record VAR_DAE "Typed variables that also have been instantiated to generate dae. Required to distinguish
                  between typed variables without DAE to know when to skip multiply declared dae elements"
  end VAR_DAE;

  record CLS_UNTYPED "just added to the env"
  end CLS_UNTYPED;

  record CLS_PARTIAL "partially instantiated"
  end CLS_PARTIAL;

  record CLS_FULL "fully instantiated"
  end CLS_FULL;

  record CLS_INSTANCE "a class that was generated for a component"
    String instanceOf;
  end CLS_INSTANCE;

end Status;

// ************************ FVisit structures ***************************
// ************************ FVisit structures ***************************
// ************************ FVisit structures ***************************
// ************************ FVisit structures ***************************

uniontype Visit "Visit Node Info"
  record VN "Visit Node Info"
    Ref ref "which node it is";
    Seq seq "order in which was visited";
  end VN;
end Visit;

uniontype Visited "Visited structure is an AvlTree Id <-> Visit"
  record V
    VAvlTree tree;
    Next next "the next visit node id";
  end V;
end Visited;

public type VAvlKey = Id;
public type VAvlValue = Visit;

uniontype VAvlTree "The binary tree data structure for visited"
  record VAVLTREENODE
    Option<VAvlTreeValue> value "Value" ;
    Integer height "heigth of tree, used for balancing";
    Option<VAvlTree> left "left subtree" ;
    Option<VAvlTree> right "right subtree" ;
  end VAVLTREENODE;
end VAvlTree;

uniontype VAvlTreeValue "Each node in the binary tree can have a value associated with it."
  record VAVLTREEVALUE
    VAvlKey key "Key" ;
    VAvlValue value "Value" ;
  end VAVLTREEVALUE;
end VAvlTreeValue;

constant VAvlTree emptyVAvlTree = VAVLTREENODE(NONE(),0,NONE(),NONE());

// ************************ FGraph structures ***************************
// ************************ FGraph structures ***************************
// ************************ FGraph structures ***************************
// ************************ FGraph structures ***************************


constant Absyn.Path dummyTopModel = Absyn.IDENT("$EMPTY");
constant Extra dummyExtra = EXTRA(dummyTopModel);

constant String recordConstructorSuffix = "$recordconstructor";

constant String forScopeName="$for loop scope$" "a unique scope used in for equations";
constant String forIterScopeName="$foriter loop scope$" "a unique scope used in for iterators";
constant String parForScopeName="$pafor loop scope$" "a unique scope used in parfor loops";
constant String parForIterScopeName="$parforiter loop scope$" "a unique scope used in parfor iterators";
constant String matchScopeName="$match scope$" "a unique scope used by match expressions";
constant String caseScopeName="$case scope$" "a unique scope used by match expressions; to be removed when local decls are deprecated";
constant String patternTypeScope="$pattern type scope$" "a scope for specializing pattern types";
constant list<String> implicitScopeNames={forScopeName,forIterScopeName,parForScopeName,parForIterScopeName,matchScopeName,caseScopeName,patternTypeScope};

uniontype Extra "propagate more info into env if needed"
  record EXTRA "propagate more info into env if needed"
    Absyn.Path topModel;
  end EXTRA;
end Extra;

uniontype Graph "graph"

  record G "graph"
    Name name "name of the graph";
    Ref top "the top node";
    Scope scope "current scope";
    Visited visited "visited structure";
    Extra extra "extra information";
    Next next "next node id for this graph";
  end G;

  record EG "empty graph"
    Name name;
  end EG;

end Graph;

public constant Id firstId = 0;

// ************************ Cache structures ***************************
// ************************ Cache structures ***************************
// ************************ Cache structures ***************************
// ************************ Cache structures ***************************

public type StructuralParameters = tuple<HashTable.HashTable,list<list<DAE.ComponentRef>>>;
public uniontype Cache
  record CACHE
    Option<Graph> initialGraph "and the initial environment";
    array<DAE.FunctionTree> functions "set of Option<DAE.Function>; NONE() means instantiation started; SOME() means it's finished";
    StructuralParameters evaluatedParams "ht of prefixed crefs and a stack of evaluated but not yet prefix crefs";
    Absyn.Path modelName "name of the model being instantiated";
    Absyn.Program program "send the program around if we don't have a symbol table";
  end CACHE;

  record NO_CACHE "no cache" end NO_CACHE;
end Cache;

public uniontype ScopeType
  record FUNCTION_SCOPE end FUNCTION_SCOPE;
  record CLASS_SCOPE end CLASS_SCOPE;
  record PARALLEL_SCOPE end PARALLEL_SCOPE;
end ScopeType;

// ************************ functions ***************************


public function next
  input Next inext;
  output Next onext;
algorithm
  onext := inext + 1;
end next;

public function emptyCache
"returns an empty cache"
  output Cache cache;
protected
  array<DAE.FunctionTree> instFuncs;
  StructuralParameters ht;
algorithm
  instFuncs := arrayCreate(1, DAE.emptyFuncTree);
  ht := (HashTable.emptyHashTableSized(BaseHashTable.lowBucketSize),{});
  cache := CACHE(NONE(),instFuncs,ht,Absyn.IDENT("##UNDEFINED##"),Absyn.dummyProgram);
end emptyCache;


public function noCache "returns an empty cache"
  output Cache cache;
algorithm
  cache := NO_CACHE();
end noCache;

public function addEvaluatedCref
  input Cache cache;
  input SCode.Variability var;
  input DAE.ComponentRef cr;
  output Cache ocache;
algorithm
  ocache := match (cache,var,cr)
    local
      Option<Graph> initialGraph;
      array<DAE.FunctionTree> functions;
      HashTable.HashTable ht;
      list<list<DAE.ComponentRef>> st;
      list<DAE.ComponentRef> crs;
      Absyn.Path p;
      Absyn.Program program;

    case (CACHE(initialGraph,functions,(ht,crs::st),p,program),SCode.PARAM(),_)
      then CACHE(initialGraph,functions,(ht,(cr::crs)::st),p,program);

    else cache;

  end match;
end addEvaluatedCref;

public function getEvaluatedParams
  input Cache cache;
  output HashTable.HashTable ht;
algorithm
  CACHE(evaluatedParams=(ht,_)) := cache;
end getEvaluatedParams;

public function printNumStructuralParameters
  input Cache cache;
protected
  list<DAE.ComponentRef> crs;
algorithm
  CACHE(evaluatedParams=(_,crs::_)) := cache;
  print("printNumStructuralParameters: " + intString(listLength(crs)) + "\n");
end printNumStructuralParameters;

public function setCacheClassName
  input Cache inCache;
  input Absyn.Path p;
  output Cache outCache;
algorithm
  outCache := match(inCache,p)
    local
      array<DAE.FunctionTree> ef;
      StructuralParameters ht;
      Option<Graph> igraph;
      Absyn.Program program;

    case (CACHE(igraph,ef,ht,_,program),_)
      then CACHE(igraph,ef,ht,p,program);
    else inCache;
  end match;
end setCacheClassName;

public function isImplicitScope
  input Name inName;
  output Boolean isImplicit;
algorithm
  isImplicit := matchcontinue(inName)

    local
      Name id;

    case (id) then stringGet(id,1) == 36; // "$"

    else false;

  end matchcontinue;
end isImplicitScope;

public function getCachedInstFunc
"returns the function in the set"
  input Cache inCache;
  input Absyn.Path path;
  output DAE.Function func;
algorithm
  func := match(inCache,path)
    local
      array<DAE.FunctionTree> ef;
    case(CACHE(functions=ef),_)
      equation
        SOME(func) = DAEUtil.avlTreeGet(arrayGet(ef,1),path);
      then func;
  end match;
end getCachedInstFunc;

public function checkCachedInstFuncGuard
"succeeds if the FQ function is in the set of functions"
  input Cache inCache;
  input Absyn.Path path;
algorithm
  _ := match(inCache,path)
    local
      array<DAE.FunctionTree> ef;
    case(CACHE(functions=ef),_) equation
      _ = DAEUtil.avlTreeGet(arrayGet(ef,1),path);
    then ();
  end match;
end checkCachedInstFuncGuard;

public function getFunctionTree
"Selector function"
  input Cache cache;
  output DAE.FunctionTree ft;
algorithm
  ft := match cache
    local
      array<DAE.FunctionTree> ef;
    case CACHE(functions = ef) then arrayGet(ef, 1);
    else DAE.emptyFuncTree;
  end match;
end getFunctionTree;

public function addCachedInstFuncGuard
"adds the FQ path to the set of instantiated functions as NONE().
This guards against recursive functions."
  input Cache cache;
  input Absyn.Path func "fully qualified function name";
  output Cache outCache;
algorithm
  outCache := matchcontinue(cache,func)
    local
      array<DAE.FunctionTree> ef;
      Option<Graph> igraph;
      StructuralParameters ht;
      Absyn.Path p;
      Absyn.Program program;

    // Don't overwrite SOME() with NONE()
    case (_, _)
      equation
        checkCachedInstFuncGuard(cache, func);
        // print("Func quard [there]: " + Absyn.pathString(func) + "\n");
      then cache;

    case (CACHE(igraph,ef,ht,p,program),Absyn.FULLYQUALIFIED(_))
      equation
        ef = arrayUpdate(ef,1,DAEUtil.avlTreeAdd(arrayGet(ef, 1),func,NONE()));
        // print("Func quard [new]: " + Absyn.pathString(func) + "\n");
      then CACHE(igraph,ef,ht,p,program);

    // Non-FQ paths mean aliased functions; do not add these to the cache
    case (_,_)
      equation
        // print("Func quard [unqual]: " + Absyn.pathString(func) + "\n");
      then (cache);

  end matchcontinue;
end addCachedInstFuncGuard;

public function addDaeFunction
"adds the list<DAE.Function> to the set of instantiated functions"
  input Cache inCache;
  input list<DAE.Function> funcs "fully qualified function name";
  output Cache outCache;
algorithm
  outCache := match(inCache,funcs)
    local
      array<DAE.FunctionTree> ef;
      Option<Graph> igraph;
      StructuralParameters ht;
      Absyn.Path p;
      Absyn.Program program;

    case (CACHE(igraph,ef,ht,p,program),_)
      equation
        ef = arrayUpdate(ef,1,DAEUtil.addDaeFunction(funcs, arrayGet(ef, 1)));
      then CACHE(igraph,ef,ht,p,program);
    else inCache;

  end match;
end addDaeFunction;

public function addDaeExtFunction
"adds the external functions in list<DAE.Function> to the set of instantiated functions"
  input Cache inCache;
  input list<DAE.Function> funcs "fully qualified function name";
  output Cache outCache;
algorithm
  outCache := match(inCache,funcs)
    local
      array<DAE.FunctionTree> ef;
      Option<Graph> igraph;
      StructuralParameters ht;
      Absyn.Path p;
      Absyn.Program program;

    case (CACHE(igraph,ef,ht,p,program),_)
      equation
        ef = arrayUpdate(ef,1,DAEUtil.addDaeExtFunction(funcs, arrayGet(ef,1)));
      then CACHE(igraph,ef,ht,p,program);
    else inCache;

  end match;
end addDaeExtFunction;

public function getProgramFromCache
  input Cache inCache;
  output Absyn.Program program;
algorithm
  program := match(inCache)
    case NO_CACHE() then Absyn.dummyProgram;
    case CACHE(program = program) then program;
  end match;
end getProgramFromCache;

public function setProgramInCache
  input Cache inCache;
  input Absyn.Program program;
  output Cache outCache;
algorithm
  outCache := match(inCache,program)
    local
      array<DAE.FunctionTree> ef;
      StructuralParameters ht;
      Absyn.Path p;
      Option<Graph> ograph;

    case (CACHE(ograph,ef,ht,p,_),_) then CACHE(ograph,ef,ht,p,program);
    else inCache;
  end match;
end setProgramInCache;

public function setCachedFunctionTree
  input Cache inCache;
  input DAE.FunctionTree inFunctions;
  output Cache outCache;
protected
  Option<Graph> og;
  array<DAE.FunctionTree> ef;
  StructuralParameters ht;
  Absyn.Path p;
  Absyn.Program program;
algorithm
  outCache := match (inCache,inFunctions)
    case (CACHE(og, _, ht, p, program), _)
      equation
        ef = arrayCreate(1, inFunctions);
      then CACHE(og, ef, ht, p, program);
    else inCache;
  end match;
end setCachedFunctionTree;

public function isTyped
"author BZ 2008-06
  This function checks wheter an InstStatus is typed or not.
  Currently used by Inst.updateComponentsInEnv."
  input Status is;
  output Boolean b;
algorithm
  b := match(is)
    case(VAR_UNTYPED()) then false;
    else true;
  end match;
end isTyped;

public function getCachedInitialGraph "get the initial environment from the cache"
  input Cache cache;
  output Graph g;
algorithm
  g := match(cache)
    case (CACHE(initialGraph = SOME(g))) then g;
  end match;
end getCachedInitialGraph;

public function setCachedInitialGraph "set the initial environment in the cache"
  input Cache inCache;
  input Graph g;
  output Cache outCache;
algorithm
  outCache := match(inCache,g)
    local
      array<DAE.FunctionTree> ef;
      StructuralParameters ht;
      Absyn.Path p;
      Absyn.Program program;

    case (CACHE(_,ef,ht,p,program),_) then CACHE(SOME(g),ef,ht,p,program);
    else inCache;

  end match;
end setCachedInitialGraph;

public function getRecordConstructorName
"@author: adrpo
 adds suffix FCore.recordConstructorSuffix ($recordconstructor)
 to the given name. does not do it for MetaModelica"
  input Name inName;
  output Name outName;
algorithm
  outName := if Config.acceptMetaModelicaGrammar() then inName else inName + recordConstructorSuffix;
end getRecordConstructorName;

public function getRecordConstructorPath
  input Absyn.Path inPath;
  output Absyn.Path outPath;
protected
  Name lastId;
algorithm
  if Config.acceptMetaModelicaGrammar() then
    outPath := inPath;
  else
    lastId := Absyn.pathLastIdent(inPath);
    lastId := getRecordConstructorName(lastId);
    outPath := Absyn.pathSetLastIdent(inPath, Absyn.makeIdentPathFromString(lastId));
  end if;
end getRecordConstructorPath;

annotation(__OpenModelica_Interface="frontend");
end FCore;
