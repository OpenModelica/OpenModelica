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

encapsulated package AvlTreeString

/*AvlTree implementation for String as key */

public
uniontype AvlTree "The binary tree data structure
 "
  record NODE
    Option<AvlTreeValue> value "Value" ;
    Integer height "heigth of tree, used for balancing";
    Option<AvlTree> left "left subtree" ;
    Option<AvlTree> right "right subtree" ;
  end NODE;

end AvlTree;

public
uniontype AvlTreeValue "Each node in the binary tree can have a value associated with it."
  record VALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end VALUE;

end AvlTreeValue;
type AvlKey = String;
type AvlValue = Integer;

public function keyStr "prints a key to a string"
  input AvlKey k;
  output String str;
algorithm
  str := k;
end keyStr;

public function valueStr "prints a Value to a string"
  input AvlValue v;
  output String str;
algorithm
  str := intString(v);
end valueStr;

protected function avlKeyCompare
  input AvlKey key1;
  input AvlKey key2;
  output Integer c;
algorithm
  c := stringCompare(key1,key2);
end avlKeyCompare;

public function avlTreeNew "Return an empty tree"
  output AvlTree tree;
algorithm
  tree := NODE(NONE(),0,NONE(),NONE());
  annotation(__OpenModelica_EarlyInline = true);
end avlTreeNew;

public function avlTreeToList "return tree as a flat list of tuples"
  input AvlTree tree;
  output list<tuple<AvlKey,AvlValue>> lst;
algorithm
  lst := avlTreeToList2(SOME(tree));
end avlTreeToList;

public function joinAvlTrees "joins two trees by adding the second one to the first"
  input AvlTree t1;
  input AvlTree t2;
  output AvlTree outTree;
algorithm
  outTree := avlTreeAddLst(avlTreeToList(t2),t1);
end joinAvlTrees;

protected function avlTreeToList2 "help function to avlTreeToList"
  input Option<AvlTree> tree;
  output list<tuple<AvlKey,AvlValue>> lst;
algorithm
  lst := match(tree)
  local Option<AvlTree> r,l; AvlKey k; AvlValue v;
    case NONE() then {};
    case(SOME(NODE(value = NONE(),left = l,right = r) )) equation
      lst = listAppend(avlTreeToList2(l),avlTreeToList2(r));
    then lst;
    case(SOME(NODE(value=SOME(VALUE(k,v)),left = l, right = r))) equation
      lst = listAppend(avlTreeToList2(l),avlTreeToList2(r));
    then (k,v)::lst;
  end match;
end avlTreeToList2;

public function avlTreeAddLst "Adds a list of (key,value) pairs"
  input list<tuple<AvlKey,AvlValue>> inValues;
  input AvlTree inTree;
  output AvlTree outTree;
algorithm
  outTree := match(inValues,inTree)
    local
      AvlKey key;
      list<tuple<AvlKey,AvlValue>> values;
      AvlValue val;
      AvlTree tree;
    case({},tree) then tree;
    case((key,val)::values,tree) equation
      tree = avlTreeAdd(tree,key,val);
      tree = avlTreeAddLst(values,tree);
    then tree;
  end match;
end avlTreeAddLst;

public function avlTreeAddFold
  input AvlKey key;
  input AvlValue value;
  input AvlTree tree;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := avlTreeAdd(tree,key,value);
end avlTreeAddFold;

public function avlTreeAdd "
 Add a tuple (key,value) to the AVL tree."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := matchcontinue (inAvlTree,inKey,inValue)
    local
      AvlKey key,rkey;
      AvlValue value,rval;
      Option<AvlTree> left,right;
      Integer h;
      AvlTree t_1,t,bt;

      /* empty tree*/
    case (NODE(value = NONE(),left = NONE(),right = NONE()),key,value)
      then NODE(SOME(VALUE(key,value)),1,NONE(),NONE());

      /* Replace this node.*/
    case (NODE(value = SOME(VALUE(rkey,_)),height=h,left = left,right = right),key,value)
      equation
        0 = avlKeyCompare(rkey, key);
        bt = balance(NODE(SOME(VALUE(rkey,value)),h,left,right));
      then
        bt;

        /* Insert to right  */
    case (NODE(value = SOME(VALUE(rkey,rval)),height=h,left = left,right = (right)),key,value)
      equation
        true = avlKeyCompare(key,rkey) > 0;
        t = createEmptyAvlIfNone(right);
        t_1 = avlTreeAdd(t, key, value);
        bt = balance(NODE(SOME(VALUE(rkey,rval)),h,left,SOME(t_1)));
      then
        bt;

        /* Insert to left subtree */
    case (NODE(value = SOME(VALUE(rkey,rval)),height=h,left = left ,right = right),key,value)
      equation
        /*true = stringCompare(key,rkey) < 0;*/
         t = createEmptyAvlIfNone(left);
        t_1 = avlTreeAdd(t, key, value);
        bt = balance(NODE(SOME(VALUE(rkey,rval)),h,SOME(t_1),right));
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
  outT := match(t)
    case(SOME(outT)) then outT;
    else NODE(NONE(),0,NONE(),NONE());
  end match;
end createEmptyAvlIfNone;

protected function balance "Balances a AvlTree"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local Integer d; AvlTree bt;
    case(bt) equation
      d = differenceInHeight(bt);
      bt = doBalance(d,bt);
    then bt;
    else equation
      print("balance failed\n");
    then fail();
  end matchcontinue;
end balance;

protected function doBalance "perform balance if difference is > 1 or < -1"
  input Integer difference;
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,inBt)
    local AvlTree bt;
    case(-1,bt) then computeHeight(bt);
    case(0,bt) then computeHeight(bt);
    case(1,bt) then computeHeight(bt);
      /* d < -1 or d > 1 */
    case(_,bt) equation
      bt = doBalance2(difference,bt);
    then bt;
    else inBt;
  end  matchcontinue;
end doBalance;

protected function doBalance2 "help function to doBalance"
  input Integer difference;
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,inBt)
    local AvlTree bt;
    case(_,bt) equation
      true = difference < 0;
      bt = doBalance3(bt);
      bt = rotateLeft(bt);
     then bt;
    case(_,bt) equation
      true = difference > 0;
      bt = doBalance4(bt);
      bt = rotateRight(bt);
     then bt;
  end matchcontinue;
end doBalance2;

protected function doBalance3 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
  local AvlTree rr,bt;
    case(bt) equation
      true = differenceInHeight(getOption(rightNode(bt))) > 0;
      rr = rotateRight(getOption(rightNode(bt)));
      bt = setRight(bt,SOME(rr));
    then bt;
    else inBt;
  end matchcontinue;
end doBalance3;

protected function doBalance4 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match(inBt)
  local AvlTree rl,bt;
  case(bt) equation
      true = differenceInHeight(getOption(leftNode(bt))) < 0;
      rl = rotateLeft(getOption(leftNode(bt)));
      bt = setLeft(bt,SOME(rl));
    then bt;
  end match;
end doBalance4;

protected function setRight "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
algorithm
  outNode := match(node,right)
   local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(NODE(value,height,l,_),_) then NODE(value,height,l,right);
  end match;
end setRight;

protected function setLeft "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
algorithm
  outNode := match(node,left)
  local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(NODE(value,height,_,r),_) then NODE(value,height,left,r);
  end match;
end setLeft;


protected function leftNode "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := match(node)
    case(NODE(left = subNode)) then subNode;
  end match;
end leftNode;

protected function rightNode "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := match(node)
    case(NODE(right = subNode)) then subNode;
  end match;
end rightNode;

protected function exchangeLeft "help function to balance"
  input AvlTree inode;
  input AvlTree iparent;
  output AvlTree outParent "updated parent";
algorithm
  outParent := match(inode,iparent)
    local
      AvlTree bt,node,parent;

    case(node,parent) equation
      parent = setRight(parent,leftNode(node));
      parent = balance(parent);
      node = setLeft(node,SOME(parent));
      bt = balance(node);
    then bt;
  end match;
end exchangeLeft;

protected function exchangeRight "help function to balance"
  input AvlTree inode;
  input AvlTree iparent;
  output AvlTree outParent "updated parent";
algorithm
  outParent := match(inode,iparent)
    local AvlTree bt,node,parent;
    case(node,parent) equation
      parent = setLeft(parent,rightNode(node));
      parent = balance(parent);
      node = setRight(node,SOME(parent));
      bt = balance(node);
    then bt;
  end match;
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
  val := match(opt)
    case(SOME(val)) then val;
  end match;
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
  diff := match(node)
  local Integer lh,rh;
    Option<AvlTree> l,r;
    case(NODE(left=l,right=r)) equation
      lh = getHeight(l);
      rh = getHeight(r);
    then lh - rh;
  end match;
end differenceInHeight;

public function avlTreeGet
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
protected
  AvlKey rkey;
  Integer sc;
  AvlTree tree = inAvlTree;
algorithm
  while true loop
    NODE(value = SOME(VALUE(key = rkey))) := tree;
    sc := avlKeyCompare(inKey, rkey);
    if sc == 0 then
      // Found match.
      NODE(value = SOME(VALUE(value = outValue))) := tree;
      return;
    elseif sc > 0 then
      // Search to the right.
      NODE(right = SOME(tree)) := tree;
    else
      // Search to the left.
      NODE(left = SOME(tree)) := tree;
    end if;
  end while;
end avlTreeGet;

protected function getOptionStr "Retrieve the string from a string option.
  If NONE() return empty string."
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString := match (inTypeAOption,inFuncTypeTypeAToString)
    local
      String str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r)
      equation
        str = r(a);
      then
        str;
    else "";
  end match;
end getOptionStr;

public function printAvlTreeStr "
  Prints the avl tree to a string"
  input AvlTree inAvlTree;
  output String outString;
algorithm
  outString := match (inAvlTree)
    local
      AvlKey rkey;
      String s1,s2,s3,res;
      AvlValue rval;
      Option<AvlTree> l,r;
      Integer h;

    case (NODE(value = SOME(VALUE(rkey,rval)),height = h,left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = "< value=" + valueStr(rval) + ",key=" + keyStr(rkey) + ",height="+ intString(h)+ s2 + s3 + ">\n";
      then
        res;
    case (NODE(value = NONE(),left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = "<NONE," + s2 + ", "+ s3 + ">";

      then
        res;
  end match;
end printAvlTreeStr;

protected function computeHeight "compute the heigth of the AvlTree and store in the node info"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
 outBt := match(bt)
 local Option<AvlTree> l,r;
   Option<AvlTreeValue> v;
   AvlValue val;
   Integer hl,hr,height;
 case(NODE(value=v as SOME(VALUE()),left=l,right=r)) equation
    hl = getHeight(l);
    hr = getHeight(r);
    height = intMax(hl,hr) + 1;
 then NODE(v,height,l,r);
 end match;
end computeHeight;

protected function getHeight "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := match(bt)
    case(SOME(NODE(height = height))) then height;
    else 0;
  end match;
end getHeight;

annotation(__OpenModelica_Interface="util");
end AvlTreeString;
