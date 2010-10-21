package AbsynDep "Copyright MathCore Engineering AB 2007
  author Peter Aronsson

  This package contains a data structure and functions for maintaining dependency information between
  Absyn classes.

  Interface:
  Depends - main data structure that contains two associative arrays (impl. as AVL trees) for uses and
  usedBy information. uses retrieves definitions required/used by the class and usedBy retrieves the classes
  that uses the definition of the class.

  addDependency(depends, class, usesClass) -> depends

  getUses(depends,class) -> avltree of used classes

  getUsesTransitive(depends,class) -> avltree of used classes under transitive closure

  getUsedBy(depends,class) => avltree of classes that uses the class (e.g as component)

  "

  public uniontype Depends " dependency information (uses/usedBy) for classes"
    record DEPENDS
      AvlTree uses "the uses information, maps a class to the classes that are used in this class";
      AvlTree usedBy "the usedby information, maps a class to the classes that uses this class(e.g. as a component)";
      /*NOTE: the AvlTree is a "generic" datatype, defined at the bottom of the file */

    end DEPENDS;
 end Depends;


 public import Absyn;

 protected import Util;
 protected import System;
 protected import ModUtil;

public function dumpDepends "prints dependency information to stdout"
  input Depends depends;
algorithm
  _ := matchcontinue(depends)
  local AvlTree used, usedBy;
    list<tuple<AvlKey,AvlValue>> usedLst,usedByLst;
    case(DEPENDS(used,usedBy)) equation
      usedLst = avlTreeToList(used);
      usedByLst = avlTreeToList(usedBy);
      print("Used\n=====\n");
      print(Util.stringDelimitList(Util.listMap(usedLst, printKeyValueTupleStr),"\n"));
      print("\n\nUsedBy=====\n");
      print(Util.stringDelimitList(Util.listMap(usedByLst, printKeyValueTupleStr),"\n"));
    then ();
   end matchcontinue;
end dumpDepends;

protected function printKeyValueTupleStr "print key/value tuple as key -> value to string"
  input tuple<AvlKey,AvlValue> tpl;
  output String str;
algorithm
  str := matchcontinue(tpl)
  local AvlKey key; AvlValue val;
    case((key,val)) equation
      str = keyStr(key) +& " -> " +& valueStr(val);
    then str;
  end matchcontinue;
end printKeyValueTupleStr;

public function addEmptyDependency "Adds a dependency that a class has no dependencies by inserting empty lists.
This is needed so that empty classes are still taken into consideration in e.g. Dependency.getTotalProgram"
  input Depends depends;
  input Absyn.Path cl;
  output Depends outDepends;
algorithm
   outDepends := matchcontinue(depends,cl)
   local
     AvlTree uses, usedBy;
     case(DEPENDS(uses,usedBy),cl) equation
         uses = avlTreeAdd(uses,cl,{});
     then DEPENDS(uses,usedBy);
   end matchcontinue;
end addEmptyDependency;

public function addDependency "add a dependency tha a class 'cl' uses another class 'usesClass' e.g. as a component"
   input Depends depends;
   input Absyn.Path cl;
   input Absyn.Path usesClass;
   output Depends outDepends;
 algorithm
   outDepends := matchcontinue(depends,cl,usesClass)
   local
     AvlTree uses, usedBy;
     case(DEPENDS(uses,usedBy),cl,usesClass) equation
         uses = avlTreeAdd(uses,cl,{usesClass});
         usedBy = avlTreeAdd(usedBy,usesClass,{cl});
     then DEPENDS(uses,usedBy);
   end matchcontinue;
 end addDependency;

public function emptyDepends "Return an empty Depends"
  output Depends dep;
protected
  AvlTree used,usedBy;
algorithm
  used := avlTreeNew();
  usedBy := avlTreeNew();
  dep := DEPENDS(used,usedBy);
end emptyDepends;

public function getUses "Retrive an avltree of classes (with empty class lists)
 for the class 'cl', containing all classes used by the class"
  input Depends depends;
  input Absyn.Path cl;
  output AvlTree uses;
algorithm
  uses := matchcontinue(depends,cl)
    local AvlValue v;
    case(DEPENDS(uses,_),cl) equation
      v = avlTreeGet(uses,cl);
      uses = avlAddUses(avlTreeNew(),v);
    then uses;
  end matchcontinue;
end getUses;

protected function avlAddUses "Help function to getUses, adds all uses to an avltree with empty list as values"
   input AvlTree tree;
   input AvlValue vals;
   output AvlTree outTree;
 algorithm
   outTree := matchcontinue(tree,vals)
   local Absyn.Path p;
     case(tree,{}) then tree;
     case(tree,p::vals) equation
      tree = avlTreeAdd(tree,p,{});
      tree = avlAddUses(tree,vals);
     then tree;
   end matchcontinue;
end avlAddUses;

public function getUsesTransitive "returns the transitive closure of getUses"
   input Depends depends;
   input Absyn.Path cl;
   output AvlTree uses;
algorithm
  uses := matchcontinue(depends,cl)
  local AvlTree outUses,treeUses; list<Absyn.Path> v;

    case(depends,Absyn.FULLYQUALIFIED(cl)) then getUsesTransitive(depends,cl);
    case(depends as DEPENDS(treeUses,_),cl) equation
      v = avlTreeGet(treeUses,cl);
      outUses = getUsesTransitive2Lst(depends,v,avlTreeNew());
    then outUses;
    case(depends,cl) then avlTreeNew();
  end matchcontinue;
end getUsesTransitive;

protected function getUsesTransitive2 "Help function to getUsesTransitive"
   input Depends depends;
   input Absyn.Path cl;
   input AvlTree uses;
   output AvlTree outUses;
algorithm
  outUses := matchcontinue(depends,cl,uses)
  local AvlTree treeUses;
    AvlValue v;

    case(depends,Absyn.FULLYQUALIFIED(cl),uses) then getUsesTransitive2(depends,cl,uses);

    case(depends,cl as Absyn.IDENT(_),uses) equation
      _ = avlTreeGet(uses,cl);
    then uses;

     /* If already added, return, recurse */
    case(depends,cl,uses) equation
      _ = avlTreeGet(uses,cl);
      uses = getUsesTransitive2(depends,Absyn.stripLast(cl),uses);
    then uses;

    case(DEPENDS(treeUses,_),cl as Absyn.IDENT(_),uses) equation
      v = avlTreeGet(treeUses,cl);
      outUses = avlAddUses(uses,{cl});
      outUses = getUsesTransitive2Lst(depends,v,outUses);
    then outUses;

    case(depends as DEPENDS(treeUses,_),cl as Absyn.QUALIFIED(_,_),uses) equation
      v = avlTreeGet(treeUses,cl);
      outUses = avlAddUses(uses,{cl});
      outUses = getUsesTransitive2Lst(depends,v,outUses);
      cl = Absyn.stripLast(cl);
      outUses = getUsesTransitive2(depends,cl,outUses);
    then outUses;

    case(_,cl,uses) then uses;
  end matchcontinue;
end getUsesTransitive2;

protected function getUsesTransitive2Lst "Help function to getUsesTransitive2"
  input Depends depends;
  input list<Absyn.Path> pathList;
  input AvlTree uses;
  output AvlTree outUses;
algorithm
  outUses := matchcontinue(depends,pathList,uses)
  local Absyn.Path path;
    case(depends,{},uses) then uses;
    case(depends,path::pathList,uses) equation
      uses = getUsesTransitive2(depends,path,uses);
      uses = getUsesTransitive2Lst(depends,pathList,uses);
    then uses;
  end matchcontinue;
end getUsesTransitive2Lst;

public function getUsedBy "returns the classes that uses the class 'cl' e.g. as a component"
  input Depends depends;
  input Absyn.Path cl;
  output AvlTree usedBy;
 algorithm
   usedBy := matchcontinue(depends,cl)
   local AvlValue v;
     case(DEPENDS(_,usedBy),cl) equation
       v = avlTreeGet(usedBy,cl);
       usedBy= avlAddUses(avlTreeNew(),v);
     then usedBy;
   end matchcontinue;
end getUsedBy;

public function getUsedBySub "
Author BZ, 2009-10
If inpu cl is 'A.B' it returns classes using A.B, but also classes that uses A.B.C.D and A.B.R, it returns all classes that equals or are a subpath of provided path.
"
  input Depends depends;
  input Absyn.Path cl;
  output AvlTree usedBy;
algorithm
  usedBy := matchcontinue(depends,cl)
    local AvlValue v;
    case(DEPENDS(_,usedBy),cl) equation
      v = avlTreeGetSubs(usedBy,cl);
      //print("included: " +& Util.stringDelimitList(Util.listMap(v,Absyn.pathString),", ") +& "\n");
      usedBy= avlAddUses(avlTreeNew(),v);
    then usedBy;
  end matchcontinue;
end getUsedBySub;

 /*
 *
 *  Generic AVL tree implementation below (copied from Env)
 *
 */

  public
type AvlKey = Absyn.Path ;
public
type AvlValue = list<Absyn.Path>;

public function keyStr "prints a key to a string"
input AvlKey k;
output String str;
algorithm
  str := Absyn.pathString(k);
end keyStr;

public function valueStr "prints a Value to a string"
input AvlValue v;
output String str;
algorithm
  str := "{" +& Util.stringDelimitList(Util.listMap(v,Absyn.pathString),",") +& "}";
end valueStr;

/* Generic Code below */
public
uniontype AvlTree "The binary tree data structure
 "
  record AVLTREENODE
    Option<AvlTreeValue> value "Value" ;
    Integer height "heigth of tree, used for balancing";
    Option<AvlTree> left "left subtree" ;
    Option<AvlTree> right "right subtree" ;
  end AVLTREENODE;

end AvlTree;

public
uniontype AvlTreeValue "Each node in the binary tree can have a value associated with it."
  record AVLTREEVALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end AVLTREEVALUE;

end AvlTreeValue;

public function avlTreeNew "Return an empty tree"
  output AvlTree tree;
algorithm
  tree := AVLTREENODE(NONE(),0,NONE(),NONE());
end avlTreeNew;

protected function avlTreeToList "return tree as a flat list of tuples"
  input AvlTree tree;
  output list<tuple<AvlKey,AvlValue>> lst;
algorithm
  lst := avlTreeToList2(SOME(tree));
end avlTreeToList;

protected function avlTreeToList2 "help function to avlTreeToList"
  input Option<AvlTree> tree;
  output list<tuple<AvlKey,AvlValue>> lst;
algorithm
  lst := matchcontinue(tree)
  local Option<AvlTree> r,l; AvlKey k; AvlValue v;
    case NONE() then {};
    case(SOME(AVLTREENODE(value = NONE(),left = l,right = r) )) equation
      lst = listAppend(avlTreeToList2(l),avlTreeToList2(r));
    then lst;
    case(SOME(AVLTREENODE(value=SOME(AVLTREEVALUE(k,v)),left = l, right = r))) equation
      lst = listAppend(avlTreeToList2(l),avlTreeToList2(r));
    then (k,v)::lst;
  end matchcontinue;
end avlTreeToList2;

public function avlTreeAdd "
 Help function to avlTreeAdd.
 "
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree:=
  matchcontinue (inAvlTree,inKey,inValue)
    local
      AvlKey key,rkey;
      AvlValue value,rval;
      Option<AvlTree> left,right;
      Integer rhval,h;
      AvlTree t_1,t,right_1,left_1,bt;

      /* empty tree*/
    case (AVLTREENODE(value = NONE(),height=h,left = NONE(),right = NONE()),key,value)
    	then AVLTREENODE(SOME(AVLTREEVALUE(key,value)),1,NONE(),NONE());

		/* Replace this node. NOTE: different from generic impl. Joins the list. */
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),height=h,left = left,right = right),key,value)
      equation
        true = ModUtil.pathEqual(rkey,key);
        value = Util.listUnionOnTrue(value,rval,ModUtil.pathEqual);
        bt = balance(AVLTREENODE(SOME(AVLTREEVALUE(rkey,value)),h,left,right));
      then
        bt;

        /* Insert to right  */
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),height=h,left = left,right = (right)),key,value)
      equation
        true = System.strcmp(Absyn.pathString(key),Absyn.pathString(rkey)) > 0;
        t = createEmptyAvlIfNone(right);
        t_1 = avlTreeAdd(t, key, value);
        bt = balance(AVLTREENODE(SOME(AVLTREEVALUE(rkey,rval)),h,left,SOME(t_1)));
      then
        bt;

        /* Insert to left subtree */
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),height=h,left = left ,right = right),key,value)
      equation
        /*true = System.strcmp(key,rkey) < 0;*/
         t = createEmptyAvlIfNone(left);
        t_1 = avlTreeAdd(t, key, value);
        bt = balance(AVLTREENODE(SOME(AVLTREEVALUE(rkey,rval)),h,SOME(t_1),right));
      then
        bt;
    case (_,_,_)
      equation
        print("avlTreeAdd failed\n");
      then
        fail();
  end matchcontinue;
end avlTreeAdd;

protected function createEmptyAvlIfNone "Help function to AvlTreeAdd2"
input Option<AvlTree> t;
output AvlTree outT;
algorithm
  outT := matchcontinue(t)
    case(NONE()) then AVLTREENODE(NONE(),0,NONE(),NONE());
    case(SOME(outT)) then outT;
  end matchcontinue;
end createEmptyAvlIfNone;

protected function nodeValue "return the node value"
input AvlTree bt;
output AvlValue v;
algorithm
  v := matchcontinue(bt)
    case(AVLTREENODE(value=SOME(AVLTREEVALUE(_,v)))) then v;
  end matchcontinue;
end nodeValue;

protected function balance "Balances a AvlTree"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(bt)
  local Integer d;
    case(bt) equation
      d = differenceInHeight(bt);
      bt = doBalance(d,bt);
    then bt;
    case(_) equation
      print("balance failed\n");
    then fail();
  end matchcontinue;
end balance;

protected function doBalance "perform balance if difference is > 1 or < -1"
input Integer difference;
input AvlTree bt;
output AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,bt)
    case(-1,bt) then computeHeight(bt);
    case(0,bt) then computeHeight(bt);
    case(1,bt) then computeHeight(bt);
      /* d < -1 or d > 1 */
    case(difference,bt) equation
      bt = doBalance2(difference,bt);
    then bt;
    case(difference,bt) then bt;
  end  matchcontinue;
end doBalance;

protected function doBalance2 "help function to doBalance"
  input Integer difference;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,bt)
    case(difference,bt) equation
      true = difference < 0;
      bt = doBalance3(bt);
      bt = rotateLeft(bt);
     then bt;
    case(difference,bt) equation
      true = difference > 0;
      bt = doBalance4(bt);
      bt = rotateRight(bt);
     then bt;
  end matchcontinue;
end doBalance2;

protected function doBalance3 "help function to doBalance2"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(bt)
  local AvlTree rr;
    case(bt) equation
      true = differenceInHeight(getOption(rightNode(bt))) > 0;
      rr = rotateRight(getOption(rightNode(bt)));
      bt = setRight(bt,SOME(rr));
    then bt;
    case(bt) then bt;
  end matchcontinue;
end doBalance3;

protected function doBalance4 "help function to doBalance2"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(bt)
  local AvlTree rl;
 case(bt) equation
      true = differenceInHeight(getOption(leftNode(bt))) < 0;
      rl = rotateLeft(getOption(leftNode(bt)));
      bt = setLeft(bt,SOME(rl));
    then bt;
  end matchcontinue;
end doBalance4;

protected function setRight "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
algorithm
  outNode := matchcontinue(node,right)
   local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(AVLTREENODE(value,height,l,r),right) then AVLTREENODE(value,height,l,right);
  end matchcontinue;
end setRight;

protected function setLeft "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
algorithm
  outNode := matchcontinue(node,left)
  local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(AVLTREENODE(value,height,l,r),left) then AVLTREENODE(value,height,left,r);
  end matchcontinue;
end setLeft;


protected function leftNode "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := matchcontinue(node)
    case(AVLTREENODE(left = subNode)) then subNode;
  end matchcontinue;
end leftNode;

protected function rightNode "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := matchcontinue(node)
    case(AVLTREENODE(right = subNode)) then subNode;
  end matchcontinue;
end rightNode;

protected function exchangeLeft "help function to balance"
input AvlTree node;
input AvlTree parent;
output AvlTree outParent "updated parent";
algorithm
  outParent := matchcontinue(node,parent)
    local Option<AvlTreeValue> value;
      Integer height ;
      AvlTree left,right,bt,leftNode,rightNode;

    case(node,parent) equation
      parent = setRight(parent,leftNode(node));
      parent = balance(parent);
      node = setLeft(node,SOME(parent));
      bt = balance(node);
    then bt;
  end matchcontinue;
end exchangeLeft;

protected function exchangeRight "help function to balance"
input AvlTree node;
input AvlTree parent;
output AvlTree outParent "updated parent";
algorithm
  outParent := matchcontinue(node,parent)
  local AvlTree bt;
    case(node,parent) equation
      parent = setLeft(parent,rightNode(node));
      parent = balance(parent);
      node = setRight(node,SOME(parent));
      bt = balance(node);
    then bt;
  end matchcontinue;
end exchangeRight;

protected function rotateLeft "help function to balance"
input AvlTree node;
output AvlTree outNode "updated node";
algorithm
  outNode := exchangeLeft(getOption(rightNode(node)),node);
end rotateLeft;

protected function getOption "Retrieve the value of an option"
  replaceable type T subtypeof Any;
  input Option<T> opt;
  output T val;
algorithm
  val := matchcontinue(opt)
    case(SOME(val)) then val;
  end matchcontinue;
end getOption;

protected function rotateRight "help function to balance"
input AvlTree node;
output AvlTree outNode "updated node";
algorithm
  outNode := exchangeRight(getOption(leftNode(node)),node);
end rotateRight;

protected function differenceInHeight "help function to balance, calculates the difference in height
between left and right child"
input AvlTree node;
output Integer diff;
algorithm
  diff := matchcontinue(node)
  local Integer lh,rh;
    Option<AvlTree> l,r;
    case(AVLTREENODE(left=l,right=r)) equation
      lh = getHeight(l);
      rh = getHeight(r);
    then lh - rh;
  end matchcontinue;
end differenceInHeight;

public function avlTreeGet "  Get a value from the binary tree given a key.
"
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue:=
  matchcontinue (inAvlTree,inKey)
    local
      AvlKey rkey,key;
      AvlValue rval,res;
      Option<AvlTree> left,right;
      Integer rhval;
      /* hash func Search to the right */
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),left = left,right = right),key)
      equation
        true = ModUtil.pathEqual(rkey,key);
      then
        rval;

        /* Search to the right */
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),left = left,right = SOME(right)),key)
      local AvlTree right;
      equation
        true = System.strcmp(Absyn.pathString(key),Absyn.pathString(rkey)) > 0;
        res = avlTreeGet(right, key);
      then
        res;

        /* Search to the left */
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),left = SOME(left),right = right),key)
      local AvlTree left;
      equation
        /*true = System.strcmp(key,rkey) < 0;*/
        res = avlTreeGet(left, key);
      then
        res;
  end matchcontinue;
end avlTreeGet;

protected function avlTreeGetSubsopt
  input Option<AvlTree> inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
  AvlTree item;
  algorithm outValue := matchcontinue(inAvlTree,inKey)
  case(NONE(),_) then {};
  case(SOME(item),inKey) then avlTreeGetSubs (item,inKey);
end matchcontinue;
end avlTreeGetSubsopt;

public function avlTreeGetSubs "  Get values from the binary tree given a key.
"
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
algorithm outValue:= matchcontinue (inAvlTree,inKey)
    local
      AvlKey rkey,key;
      AvlValue rval,res,res2;
      Option<AvlTree> left,right;
      Integer rhval;
      Boolean b1,b2;
      String s1;
      // end of tree case
  case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),left = NONE(),right = NONE()),key)
    equation
      b2 = Absyn.pathPrefixOf(key,rkey);
      rval = Util.if_(b2,rval,{});
    then
      rval;
      // Normal case, compare current node and search left+right
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),left = left,right = right),key)
      equation
        b1 = Absyn.pathPrefixOf(key,rkey);
        rval = Util.if_(b1,rval,{});
        res = avlTreeGetSubsopt(left, key);
        res2 = avlTreeGetSubsopt(right, key);
        rval = listAppend(rval,listAppend(res,res2));
      then
        rval;
  end matchcontinue;
end avlTreeGetSubs;

protected function getOptionStr "function getOptionStr

  Retrieve the string from a string option.
  If NONE() return empty string.
"
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString:=
  matchcontinue (inTypeAOption,inFuncTypeTypeAToString)
    local
      String str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r)
      equation
        str = r(a);
      then
        str;
    case (NONE(),_) then "";
  end matchcontinue;
end getOptionStr;

protected function printAvlTreeStr "
  Prints the avl tree to a string
"
  input AvlTree inAvlTree;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAvlTree)
    local
      AvlKey rkey;
      String s1,s2,s3,res;
      AvlValue rval;
      Option<AvlTree> l,r;
      Integer h;

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(rkey,rval)),height = h,left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = "< value=" +& valueStr(rval) +& ",key=" +& keyStr(rkey) +& ",height="+& intString(h)+& s2 +& s3 +& ">\n";
      then
        res;
    case (AVLTREENODE(value = NONE(),left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = "<NONE," +& s2 +& ", "+& s3 +& ">";

      then
        res;
  end matchcontinue;
end printAvlTreeStr;

protected function computeHeight "compute the heigth of the AvlTree and store in the node info"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
 outBt := matchcontinue(bt)
 local Option<AvlTree> l,r;
   Option<AvlTreeValue> v;
   AvlValue val;
   Integer hl,hr,height;
 case(AVLTREENODE(value=v as SOME(AVLTREEVALUE(_,val)),left=l,right=r)) equation
    hl = getHeight(l);
    hr = getHeight(r);
    height = intMax(hl,hr) + 1;
 then AVLTREENODE(v,height,l,r);
 end matchcontinue;
end computeHeight;

protected function getHeight "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := matchcontinue(bt)
    case(NONE()) then 0;
    case(SOME(AVLTREENODE(height = height))) then height;
  end matchcontinue;
end getHeight;

end AbsynDep;
