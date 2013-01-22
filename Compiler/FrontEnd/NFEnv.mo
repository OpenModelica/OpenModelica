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

encapsulated package NFEnv
" file:        NFEnv.mo
  package:     NFEnv
  description: Symbol table for lookup

  RCS: $Id$

"
public import Absyn;
public import SCode;

protected import Error;
protected import List;
protected import Util;

public uniontype Entry
  record ENTRY
    String name;
    SCode.Element element;
    Integer scopeLevel;
  end ENTRY;

  record IMPORTED_ENTRY
    Entry entry "The imported entry.";
    Env originEnv "The environment this entry was imported from.";
    Integer scopeLevel "The scope level this entry was imported to.";
  end IMPORTED_ENTRY;
end Entry;

public uniontype ScopeType
  record NORMAL_SCOPE end NORMAL_SCOPE;
  record ENCAPSULATED_SCOPE end ENCAPSULATED_SCOPE;
end ScopeType;

public uniontype Env
  record ENV
    Option<String> name;
    ScopeType scopeType;
    list<Env> scopes;
    Integer scopeCount;
    AvlTree entries;
  end ENV;
end Env;

public constant Env emptyEnv = ENV(NONE(), NORMAL_SCOPE(), {}, 0, emptyAvlTree);

public function openScope
  input Option<String> inScopeName;
  input SCode.Encapsulated inEncapsulated;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inScopeName, inEncapsulated, inEnv)
    local
      list<Env> scopes;
      AvlTree entries;
      ScopeType ty;
      Integer sc;

    case (_, SCode.NOT_ENCAPSULATED(), ENV(_, ty, scopes, sc, entries))
      equation
        sc = sc + 1;
      then
        ENV(inScopeName, ty, inEnv :: scopes, sc, entries);

    case (_, _, ENV(_, _, scopes, sc, _))
      equation
        sc = sc + 1;
      then
        ENV(inScopeName, ENCAPSULATED_SCOPE(), inEnv :: scopes, sc, emptyAvlTree);

  end match;
end openScope;

public function exitScope
  input Env inEnv;
  output Env outEnv;
algorithm
  ENV(scopes = outEnv :: _) := inEnv;
end exitScope;
  
public function topScope
  input Env inEnv;
  output Env outEnv;
protected
  list<Env> scopes;
algorithm
  ENV(scopes = scopes) := inEnv;
  outEnv := List.secondLast(scopes);
end topScope;

public function builtinScope
  input Env inEnv;
  output Env outEnv;
protected
  list<Env> scopes;
algorithm
  ENV(scopes = scopes) := inEnv;
  outEnv := List.last(scopes);
end builtinScope;
  
public function makeEntry
  input SCode.Element inElement;
  input Env inEnv;
  output Entry outEntry;
protected
  Integer scope_lvl;
  String name;
algorithm
  scope_lvl := scopeCount(inEnv);
  name := SCode.elementName(inElement);
  outEntry := ENTRY(name, inElement, scope_lvl);
end makeEntry;

public function insertEntry
  input Entry inEntry;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  ScopeType ty;
  list<Env> scopes;
  Integer sc;
  AvlTree entries;
algorithm
  ENV(name, ty, scopes, sc, entries) := inEnv;
  entries := avlTreeAdd(entries, entryName(inEntry), inEntry);
  outEnv := ENV(name, ty, scopes, sc, entries); 
end insertEntry;
  
public function insertElement
  input SCode.Element inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := insertEntry(makeEntry(inElement, inEnv), inEnv);
end insertElement;

public function lookupEntry
  input String inName;
  input Env inEnv;
  output Entry outEntry;
protected
  AvlTree entries;
algorithm
  ENV(entries = entries) := inEnv;
  outEntry := avlTreeGet(entries, inName);
end lookupEntry;

public function entryEnv
  input Entry inEntry;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inEntry, inEnv)
    local
      Integer scope_lvl, scope_count;
      list<Env> scopes;

    case (ENTRY(scopeLevel = scope_lvl), ENV(scopeCount = scope_count))
      equation
        true = intEq(scope_lvl, scope_count);
      then
        inEnv;

    case (ENTRY(scopeLevel = scope_lvl), ENV(scopes = scopes))
      then listGet(scopes, scope_lvl);

  end matchcontinue;
end entryEnv;

public function resolveImportedEntry
  input Entry inEntry;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := match(inEntry, inEnv)
    local
      Entry entry;
      Env env;

    case (IMPORTED_ENTRY(entry = entry, originEnv = env), _) then (entry, env);
    else (inEntry, inEnv);

  end match;
end resolveImportedEntry;

protected function entryScopeLevel
  input Entry inEntry;
  output Integer outScopeLevel;
algorithm
  outScopeLevel := match(inEntry)
    local
      Integer scope_lvl;

    case ENTRY(scopeLevel = scope_lvl) then scope_lvl;
    case IMPORTED_ENTRY(scopeLevel = scope_lvl) then scope_lvl;

  end match;
end entryScopeLevel;

protected function scopeCount
  input Env inEnv;
  output Integer outScopeCount;
algorithm
  ENV(scopeCount = outScopeCount) := inEnv;
end scopeCount;

public function isScopeEncapsulated
  input Env inEnv;
  output Boolean outIsEncapsulated;
algorithm
  outIsEncapsulated := match(inEnv)
    case ENV(scopeType = ENCAPSULATED_SCOPE()) then true;
    else false;
  end match;
end isScopeEncapsulated;

public function isLocalScopeEntry
  input Entry inEntry;
  input Env inEnv;
  output Boolean outIsLocal;
algorithm
  outIsLocal := intEq(entryScopeLevel(inEntry), scopeCount(inEnv));
end isLocalScopeEntry;
  
public function entryName
  input Entry inEntry;
  output String outName;
algorithm
  ENTRY(name = outName) := inEntry;
end entryName;

public function entryElement
  input Entry inEntry;
  output SCode.Element outElement;
algorithm
  ENTRY(element = outElement) := inEntry;
end entryElement;

public function scopeNameList
  input Env inEnv;
  output list<String> outNames;
algorithm
  outNames := scopeNameList2(inEnv, {});
end scopeNameList;

public function scopeNameList2
  input Env inEnv;
  input list<String> inAccumNames;
  output list<String> outNames;
algorithm
  outNames := match(inEnv, inAccumNames)
    local
      String name;
      Env env;

    case (ENV(name = SOME(name), scopes = env :: _), _)
      then scopeNameList2(env, name :: inAccumNames);

    case (ENV(scopes = env :: _), _)
      then scopeNameList2(env, inAccumNames);

    case (ENV(name = SOME(name), scopes = {}), _)
      then listReverse(name :: inAccumNames);

    case (ENV(scopes = {}), _)
      then listReverse(inAccumNames);

  end match;
end scopeNameList2;

public function printEnvPathStr
  input Env inEnv;
  output String outString;
protected
  list<String> scopes;
algorithm
  scopes := scopeNameList(inEnv);
  outString := stringDelimitList(scopes, ".");
end printEnvPathStr;

public function buildInitialEnv
  input SCode.Program inProgram;
  output Env outEnv;
protected
  Env env;
  SCode.Program prog, builtin;
algorithm
  env := emptyEnv;
  //env := insertEntry(makeEntry(BUILTIN_TIME, env), env);
  (builtin, prog) := List.splitOnTrue(inProgram, SCode.isBuiltinElement);
  env := List.fold(builtin, insertElement, env);
  env := openScope(NONE(), SCode.NOT_ENCAPSULATED(), env);
  outEnv := List.fold(prog, insertElement, env);
end buildInitialEnv;

public function enterEntryScope
  input Entry inEntry;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inEntry, inEnv)
    local
      String name;
      SCode.Encapsulated ep;
      Env env;
      SCode.ClassDef cdef;

    case (ENTRY(element = SCode.CLASS(name = name,
        encapsulatedPrefix = ep, classDef = cdef)), _)
      equation
        env = openScope(SOME(name), ep, inEnv);
        env = populateEnvWithClassDef(cdef, env);
      then
        env;

    case (ENTRY(element = SCode.COMPONENT(name = name)), _)
      equation
        print("NFEnv.enterEntryScope: IMPLEMENT ME!\n");
      then
        fail();

  end match;
end enterEntryScope;
        
protected function populateEnvWithClassDef
  input SCode.ClassDef inClassDef;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inClassDef, inEnv)
    local
      list<SCode.Element> elems;
      Env env;

    case (SCode.PARTS(elementLst = elems), _)
      equation
        env = List.fold(elems, populateEnvWithElement, inEnv);
      then
        env;

    else
      equation
        print("NFEnv.populateEnvWithClassDef: IMPLEMENT ME!\n");
      then
        fail();

  end match;
end populateEnvWithClassDef;

protected function populateEnvWithElement
  input SCode.Element inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inElement, inEnv)
    local
      Entry entry;
      Env env;

    case (SCode.EXTENDS(baseClassPath = _), _)
      equation
        print("NFEnv.populateEnvWithElement: EXTENDS!\n");
      then
        fail();

    case (SCode.IMPORT(imp = _), _)
      equation
        print("NFEnv.populateEnvWithElement: IMPORT!\n");
      then
        fail();

    else insertElement(inElement, inEnv);

  end match;
end populateEnvWithElement;

// AVL Tree implementation
public type AvlKey = String;
public type AvlValue = Entry;

protected constant AvlTree emptyAvlTree = AVLTREENODE(NONE(), 0, NONE(), NONE());

public uniontype AvlTree 
  "The binary tree data structure"
  record AVLTREENODE
    Option<AvlTreeValue> value "Value";
    Integer height "height of tree, used for balancing";
    Option<AvlTree> left "left subtree";
    Option<AvlTree> right "right subtree";
  end AVLTREENODE;
end AvlTree;

public uniontype AvlTreeValue 
  "Each node in the binary tree can have a value associated with it."
  record AVLTREEVALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end AVLTREEVALUE;
end AvlTreeValue;

protected function avlTreeNew 
  "Return an empty tree"
  output AvlTree tree;
algorithm
  tree := emptyAvlTree;
end avlTreeNew;

public function avlTreeAdd
  "Inserts a new value into the tree."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;

    // empty tree
    case (AVLTREENODE(value = NONE(), left = NONE(), right = NONE()), _, _)
      then AVLTREENODE(SOME(AVLTREEVALUE(inKey, inValue)), 1, NONE(), NONE());

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, value)
      then avlBalance(avlTreeAdd2(inAvlTree, stringCompare(key, rkey), key, value));
 
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeAdd failed"});
      then fail();

  end match;
end avlTreeAdd;

protected function avlTreeAdd2
  "Helper function to avlTreeAdd."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;
      Absyn.Info info;

    // Don't allow replacing of nodes.
    //case (_, 0, key, _)
    //  equation
    //    info = getItemInfo(inValue);
    //    Error.addSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS,
    //      {inKey}, info);
    //  then
    //    fail();

    // Insert into right subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        1, key, value)
      equation
        t = avlCreateEmptyIfNone(right);
        t = avlTreeAdd(t, key, value);
      then  
        AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        -1, key, value)
      equation
        t = avlCreateEmptyIfNone(left);
        t = avlTreeAdd(t, key, value);
      then
        AVLTREENODE(oval, h, SOME(t), right);
  end match;
end avlTreeAdd2;

public function avlTreeGet
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
protected
  AvlKey rkey;
algorithm
  AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))) := inAvlTree;
  outValue := avlTreeGet2(inAvlTree, stringCompare(inKey, rkey), inKey);
end avlTreeGet;

protected function avlTreeGet2
  "Helper function to avlTreeGet."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := match(inAvlTree, inKeyComp, inKey)
    local
      AvlKey key;
      AvlValue rval;
      AvlTree left, right;

    // Found match.
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(value = rval))), 0, _)
      then rval;

    // Search to the right.
    case (AVLTREENODE(right = SOME(right)), 1, key)
      then avlTreeGet(right, key);

    // Search to the left.
    case (AVLTREENODE(left = SOME(left)), -1, key)
      then avlTreeGet(left, key);
  end match;
end avlTreeGet2;

public function avlTreeReplace
  "Replaces the value of an already existing node in the tree with a new value."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, value)
      then avlTreeReplace2(inAvlTree, stringCompare(key, rkey), key, value);
 
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeReplace failed"});
      then fail();

  end match;
end avlTreeReplace;

protected function avlTreeReplace2
  "Helper function to avlTreeReplace."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    // Replace this node.
    case (AVLTREENODE(value = SOME(_), height = h, left = left, right = right),
        0, key, value)
      then AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right);

    // Insert into right subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        1, key, value)
      equation
        t = avlCreateEmptyIfNone(right);
        t = avlTreeReplace(t, key, value);
      then  
        AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        -1, key, value)
      equation
        t = avlCreateEmptyIfNone(left);
        t = avlTreeReplace(t, key, value);
      then
        AVLTREENODE(oval, h, SOME(t), right);
  end match;
end avlTreeReplace2;

protected function avlCreateEmptyIfNone 
  "Help function to AvlTreeAdd"
    input Option<AvlTree> t;
    output AvlTree outT;
algorithm
  outT := match(t)
    case (NONE()) then avlTreeNew();
    case (SOME(outT)) then outT;
  end match;
end avlCreateEmptyIfNone;

protected function avlBalance 
  "Balances an AvlTree"
  input AvlTree bt;
  output AvlTree outBt;
protected
  Integer d;
algorithm
  d := avlDifferenceInHeight(bt);
  outBt := avlDoBalance(d, bt);
end avlBalance;

protected function avlDoBalance 
  "Performs balance if difference is > 1 or < -1"
  input Integer difference;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match(difference, bt)
    case(-1, _) then avlComputeHeight(bt);
    case( 0, _) then avlComputeHeight(bt);
    case( 1, _) then avlComputeHeight(bt);
    // d < -1 or d > 1
    else avlDoBalance2(difference < 0, bt);
  end match;
end avlDoBalance;

protected function avlDoBalance2 
"help function to doBalance"
  input Boolean inDiffIsNegative;
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match(inDiffIsNegative,inBt)
    local AvlTree bt;
    case(true,bt) 
      equation
        bt = avlDoBalance3(bt);
        bt = avlRotateLeft(bt);
      then bt;
    case(false,bt) 
      equation
        bt = avlDoBalance4(bt);
        bt = avlRotateRight(bt);
      then bt;
  end match;
end avlDoBalance2;

protected function avlDoBalance3 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rr,bt;
    case(bt)
      equation
        true = avlDifferenceInHeight(Util.getOption(avlRightNode(bt))) > 0;
        rr = avlRotateRight(Util.getOption(avlRightNode(bt)));
        bt = avlSetRight(bt,SOME(rr));
      then bt;
    else inBt;
  end matchcontinue;
end avlDoBalance3;

protected function avlDoBalance4 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rl,bt;
    case (bt)
      equation
        true = avlDifferenceInHeight(Util.getOption(avlLeftNode(bt))) < 0;
        rl = avlRotateLeft(Util.getOption(avlLeftNode(bt)));
        bt = avlSetLeft(bt,SOME(rl));
      then bt;
    else inBt;
  end matchcontinue;
end avlDoBalance4;

protected function avlSetRight 
  "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> l;
  Integer height;
algorithm
  AVLTREENODE(value, height, l, _) := node;
  outNode := AVLTREENODE(value, height, l, right);
end avlSetRight;

protected function avlSetLeft 
  "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> r;
  Integer height;
algorithm
  AVLTREENODE(value, height, _, r) := node;
  outNode := AVLTREENODE(value, height, left, r);
end avlSetLeft;

protected function avlLeftNode 
  "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  AVLTREENODE(left = subNode) := node;
end avlLeftNode;

protected function avlRightNode 
  "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  AVLTREENODE(right = subNode) := node;
end avlRightNode;

protected function avlExchangeLeft 
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := avlSetRight(inParent, avlLeftNode(inNode));
  parent := avlBalance(parent);
  node := avlSetLeft(inNode, SOME(parent));
  outParent := avlBalance(node);
end avlExchangeLeft;

protected function avlExchangeRight 
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := avlSetLeft(inParent, avlRightNode(inNode));
  parent := avlBalance(parent);
  node := avlSetRight(inNode, SOME(parent));
  outParent := avlBalance(node);
end avlExchangeRight;

protected function avlRotateLeft 
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := avlExchangeLeft(Util.getOption(avlRightNode(node)), node);
end avlRotateLeft;

protected function avlRotateRight 
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := avlExchangeRight(Util.getOption(avlLeftNode(node)), node);
end avlRotateRight;

protected function avlDifferenceInHeight 
  "help function to balance, calculates the difference in height between left
  and right child"
  input AvlTree node;
  output Integer diff;
protected
  Option<AvlTree> l, r;
algorithm
  AVLTREENODE(left = l, right = r) := node;
  diff := avlGetHeight(l) - avlGetHeight(r);
end avlDifferenceInHeight;

protected function avlComputeHeight 
  "Compute the height of the AvlTree and store in the node info."
  input AvlTree bt;
  output AvlTree outBt;
protected
  Option<AvlTree> l,r;
  Option<AvlTreeValue> v;
  AvlValue val;
  Integer hl,hr,height;
algorithm
  AVLTREENODE(value = v as SOME(AVLTREEVALUE(value = val)), 
    left = l, right = r) := bt;
  hl := avlGetHeight(l);
  hr := avlGetHeight(r);
  height := intMax(hl, hr) + 1;
  outBt := AVLTREENODE(v, height, l, r);
end avlComputeHeight;

protected function avlGetHeight 
  "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := match(bt)
    case(NONE()) then 0;
    case(SOME(AVLTREENODE(height = height))) then height;
  end match;
end avlGetHeight;

public function avlPrintTreeStrPP
  input AvlTree inTree;
  output String outString;
algorithm
  outString := avlPrintTreeStrPP2(SOME(inTree), "");
end avlPrintTreeStrPP;

protected function avlPrintTreeStrPP2
  input Option<AvlTree> inTree;
  input String inIndent;
  output String outString;
algorithm
  outString := match(inTree, inIndent)
    local
      AvlKey rkey;
      Option<AvlTree> l, r;
      String s1, s2, res, indent;

    case (NONE(), _) then "";

    case (SOME(AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey)), left = l, right = r)), _)
      equation
        indent = inIndent +& "  ";
        s1 = avlPrintTreeStrPP2(l, indent);
        s2 = avlPrintTreeStrPP2(r, indent);
        res = "\n" +& inIndent +& rkey +& s1 +& s2;
      then
        res;

    case (SOME(AVLTREENODE(value = NONE(), left = l, right = r)), _)
      equation
        indent = inIndent +& "  ";
        s1 = avlPrintTreeStrPP2(l, indent);
        s2 = avlPrintTreeStrPP2(r, indent);
        res = "\n" +& s1 +& s2;
      then
        res;
  end match;
end avlPrintTreeStrPP2;

end NFEnv;
