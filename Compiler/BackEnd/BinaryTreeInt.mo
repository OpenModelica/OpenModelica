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

encapsulated package BinaryTreeInt
" file:        BinaryTreeInt.mo
  package:     BinaryTreeInt
  description: BinaryTreeInt comprises functions for BinaryTrees.


  BinaryTree."

/**************************
  imports
 **************************/

protected import Error;
protected import Util;


/**************************
  types
 **************************/

public
uniontype BinTree "Generic Binary tree implementation
  - Binary Tree"
  record TREENODE
    Option<TreeValue> value "Value";
    Option<BinTree> leftSubTree "left subtree";
    Option<BinTree> rightSubTree "right subtree";
  end TREENODE;

end BinTree;

public
uniontype TreeValue "Each node in the binary tree can have a value associated with it.
  - Tree Value"
  record TREEVALUE
    Key key "Key";
    Value value "Value";
  end TREEVALUE;

end TreeValue;

public
type Key = Integer "A key is a Integer";

public
type Value = Integer "- Value";

public constant BinTree emptyBinTree=TREENODE(NONE(),NONE(),NONE()) " Empty binary tree ";

/**************************
  implementation
 **************************/

protected function keyCmp
  input Key keya;
  input Key keyb;
  output Integer cmp;
algorithm
  cmp := Util.intSign(keya-keyb);
end keyCmp;

public function treeGet "author: Frenkel TUD 2012-09-18

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string can not be uniquely mapped to an int. Therefore we need to compare two strings
  to get a unique ordering.
"
  input BinTree bt;
  input Key key;
  output Value v;
protected
  String keystr;
  Integer keyhash;
algorithm
  v := treeGet3(bt, key, treeGet2(bt, key));
end treeGet;

protected function treeGet2
  "Helper function to treeGet"
  input BinTree inBinTree;
  input Key ikey;
  output Integer compResult;
algorithm
  compResult := match (inBinTree,ikey)
    local
      Key key;

    // found it
    case (TREENODE(value = SOME(TREEVALUE(key=key))),_)
      then keyCmp(key, ikey);
  end match;
end treeGet2;

protected function treeGet3
  "Helper function to treeGet"
  input BinTree inBinTree;
  input Key ikey;
  input Integer inCompResult;
  output Value outValue;
algorithm
  outValue := match (inBinTree,ikey,inCompResult)
    local
      Value rval;
      BinTree right, left;
      Integer compResult;

    // found it
    case (TREENODE(value = SOME(TREEVALUE(value=rval))),_,0) then rval;
    // search right
    case (TREENODE(rightSubTree = SOME(right)),_,1)
      equation
        compResult = treeGet2(right, ikey);
      then treeGet3(right, ikey, compResult);
    // search left
    case (TREENODE(leftSubTree = SOME(left)),_,-1)
      equation
        compResult = treeGet2(left, ikey);
      then treeGet3(left, ikey, compResult);
  end match;
end treeGet3;

public function treeAddList "author: Frenkel TUD"
  input BinTree inBinTree;
  input list<Key> inKeyLst;
  output BinTree outBinTree;
algorithm
  outBinTree := match (inBinTree,inKeyLst)
    local
      Key key;
      list<Key> res;
      BinTree bt,bt_1,bt_2;

    case (bt,{}) then bt;

    case (bt,key::res)
      equation
        bt_1 = treeAdd(bt,key,0);
        bt_2 = treeAddList(bt_1,res);
      then
        bt_2;
  end match;
end treeAddList;

public function treeAdd "author: PA
  Copied from generic implementation. Changed that no hashfunction is passed
  since a string (ComponentRef) can not be uniquely mapped to an int. Therefore we need to compare two strings
  to get a unique ordering.

  Actually, hashing is still important in order to speed up comparison of strings... So it was re-added in a
  good way, see function keyCompareNinjaSecretHashTricks"
  input BinTree inBinTree;
  input Key inKey;
  input Value inValue;
  output BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inBinTree,inKey,inValue)
    local
      Key rkey;
      Value rval;
      Option<BinTree> left,right;
      BinTree t_1,t,right_1,left_1;
      Option<TreeValue> optVal;

    case (TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()),_,_)
      then
        TREENODE(SOME(TREEVALUE(inKey,inValue)),NONE(),NONE());

    case (TREENODE(value = SOME(TREEVALUE(rkey,_)),leftSubTree = left,rightSubTree = right),_,_)
      equation
        0 = keyCmp(rkey,inKey);
      then
        TREENODE(SOME(TREEVALUE(rkey,inValue)),left,right);

    case (TREENODE(value = optVal as SOME(TREEVALUE(rkey,_)),leftSubTree = left,rightSubTree = (SOME(t))),_,_)
      equation
        1 = keyCmp(rkey,inKey);
        t_1 = treeAdd(t, inKey, inValue);
      then
        TREENODE(optVal,left,SOME(t_1));

    case (TREENODE(value = optVal as SOME(TREEVALUE(rkey,_)),leftSubTree = left,rightSubTree = (NONE())),_,_)
      equation
        1 = keyCmp(rkey,inKey);
        right_1 = treeAdd(TREENODE(NONE(),NONE(),NONE()), inKey, inValue);
      then
        TREENODE(optVal,left,SOME(right_1));

    case (TREENODE(value = optVal as SOME(TREEVALUE(rkey,_)),leftSubTree = (SOME(t)),rightSubTree = right),_,_)
      equation
        -1 = keyCmp(rkey,inKey);
        t_1 = treeAdd(t, inKey, inValue);
      then
        TREENODE(optVal,SOME(t_1),right);

    case (TREENODE(value = optVal as SOME(TREEVALUE(rkey,_)),leftSubTree = (NONE()),rightSubTree = right),_,_)
      equation
        -1 = keyCmp(rkey,inKey);
        left_1 = treeAdd(TREENODE(NONE(),NONE(),NONE()), inKey, inValue);
      then
        TREENODE(optVal,SOME(left_1),right);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"- BinaryTreeInt.treeAdd failed\n"});
      then
        fail();
  end matchcontinue;
end treeAdd;

// protected function treeDelete2 "author: PA
//   This function deletes an entry from the BinTree."
//   input BinTree inBinTree;
//   input Integer inKey;
//   output BinTree outBinTree;
// algorithm
//   outBinTree := matchcontinue (inBinTree,inKey)
//     local
//       BinTree bt,right,left,t;
//       Key key,rkey;
//       TreeValue rightmost;
//       Option<BinTree> optRight,optLeft,optTree;
//       Value rval;
//       Option<TreeValue> optVal;
//       Integer rhash;
//
//     case ((bt as TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE())),_)
//       then bt;
//
//     case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = optLeft,rightSubTree = SOME(right)),_)
//       equation
//         0 = keyCmp(rkey, inKey);
//         (rightmost,right) = treeDeleteRightmostValue(right);
//         optRight = treePruneEmptyNodes(right);
//       then
//         TREENODE(SOME(rightmost),optLeft,optRight);
//
//     case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = SOME(left as TREENODE(value=_)),rightSubTree = NONE()),_)
//       equation
//         0 = keyCmp(rkey, inKey);
//       then
//         left;
//
//     case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = NONE(),rightSubTree = NONE()),_)
//       equation
//         0 = keyCmp(rkey, inKey);
//       then
//         TREENODE(NONE(),NONE(),NONE());
//
//     case (TREENODE(value = optVal as SOME(TREEVALUE(rkey,rval)),leftSubTree = optLeft,rightSubTree = SOME(t)),_)
//       equation
//         1 = keyCmp(rkey, inKey);
//         t = treeDelete2(t, inKey);
//         optTree = treePruneEmptyNodes(t);
//       then
//         TREENODE(optVal,optLeft,optTree);
//
//     case (TREENODE(value = optVal as SOME(TREEVALUE(rkey,rval)),leftSubTree =  SOME(t),rightSubTree = optRight),_)
//       equation
//         -1 = keyCmp(rkey, inKey);
//         t = treeDelete2(t, inKey);
//         optTree = treePruneEmptyNodes(t);
//       then
//         TREENODE(optVal,optTree,optRight);
//
//     else
//       equation
//         Error.addMessage(Error.INTERNAL_ERROR,{"-BinaryTree.treeDelete failed\n"});
//       then
//         fail();
//   end matchcontinue;
// end treeDelete2;

// protected function treeDeleteRightmostValue "author: PA
//   This function takes a BinTree and deletes the rightmost value of the tree.
//   Tt returns this value and the updated BinTree. This function is used in
//   the binary tree deletion function \'tree_delete\'.
//   inputs:  (BinTree)
//   outputs: (TreeValue, /* deleted value */
//               BinTree    /* updated bintree */)
// "
//   input BinTree inBinTree;
//   output TreeValue outTreeValue;
//   output BinTree outBinTree;
// algorithm
//   (outTreeValue,outBinTree) := matchcontinue (inBinTree)
//     local
//       TreeValue treeVal,value;
//       BinTree left,right,bt;
//       Option<BinTree> optRight, optLeft;
//       Option<TreeValue> optTreeVal;
//
//     case (TREENODE(value = SOME(treeVal),leftSubTree = NONE(),rightSubTree = NONE()))
//       then (treeVal,TREENODE(NONE(),NONE(),NONE()));
//
//     case (TREENODE(value = SOME(treeVal),leftSubTree = SOME(left),rightSubTree = NONE()))
//       then (treeVal,left);
//
//     case (TREENODE(value = optTreeVal,leftSubTree = optLeft,rightSubTree = SOME(right)))
//       equation
//         (value,right) = treeDeleteRightmostValue(right);
//         optRight = treePruneEmptyNodes(right);
//       then
//         (value,TREENODE(optTreeVal,optLeft,optRight));
//
//     case (TREENODE(value = SOME(treeVal),leftSubTree = NONE(),rightSubTree = SOME(right)))
//       equation
//         failure((_,_) = treeDeleteRightmostValue(right));
//         print("- BinaryTree.treeDeleteRightmostValue: right value was empty, left NONE\n");
//       then
//         (treeVal,TREENODE(NONE(),NONE(),NONE()));
//
//     else
//       equation
//         Error.addMessage(Error.INTERNAL_ERROR,{"- BinaryTree.treeDeleteRightmostValue failed\n"});
//       then
//         fail();
//   end matchcontinue;
// end treeDeleteRightmostValue;

// protected function treePruneEmptyNodes "author: PA
//   This function is a helper function to tree_delete
//   It is used to delete empty nodes of the BinTree
//   representation, that might be introduced when deleting nodes."
//   input BinTree inBinTree;
//   output Option<BinTree> outBinTreeOption;
// algorithm
//   outBinTreeOption := matchcontinue (inBinTree)
//     local BinTree bt;
//     case TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()) then NONE();
//     case bt then SOME(bt);
//   end matchcontinue;
// end treePruneEmptyNodes;

// protected function bintreeDepth "author: PA
//   This function calculates the depth of the Binary Tree given
//   as input. It can be used for debugging purposes to investigate
//   how balanced binary trees are."
//   input BinTree inBinTree;
//   output Integer outInteger;
// algorithm
//   outInteger := matchcontinue (inBinTree)
//     local
//       Value ld,rd,res;
//       BinTree left,right;
//
//     case (TREENODE(leftSubTree = NONE(),rightSubTree = NONE())) then 1;
//
//     case (TREENODE(leftSubTree = SOME(left),rightSubTree = SOME(right)))
//       equation
//         ld = bintreeDepth(left);
//         rd = bintreeDepth(right);
//         res = intMax(ld, rd);
//       then
//         res + 1;
//
//     case (TREENODE(leftSubTree = SOME(left),rightSubTree = NONE()))
//       equation
//         ld = bintreeDepth(left);
//       then
//         ld;
//
//     case (TREENODE(leftSubTree = NONE(),rightSubTree = SOME(right)))
//       equation
//         rd = bintreeDepth(right);
//       then
//         rd;
//   end matchcontinue;
// end bintreeDepth;


public function bintreeToList "author: PA

  This function takes a BinTree and transform it into a list
  representation, i.e. two lists of keys and values
"
  input BinTree inBinTree;
  output list<Key> outKeyLst;
  output list<Value> outValueLst;
algorithm
  (outKeyLst,outValueLst):=
  matchcontinue (inBinTree)
    local
      list<Key> klst;
      list<Value> vlst;
      BinTree bt;
    case (bt)
      equation
        (klst,vlst) = bintreeToList2(bt, {}, {});
      then
        (klst,vlst);
    case (_)
      equation
        print("- BackendDAEUtil.bintreeToList failed\n");
      then
        fail();
  end matchcontinue;
end bintreeToList;

protected function bintreeToList2 "author: PA
  helper function to bintreeToList"
  input BinTree inBinTree;
  input list<Key> inKeyLst;
  input list<Value> inValueLst;
  output list<Key> outKeyLst;
  output list<Value> outValueLst;
algorithm
  (outKeyLst,outValueLst) := matchcontinue (inBinTree,inKeyLst,inValueLst)
    local
      list<Key> klst;
      list<Value> vlst;
      Key key;
      Value value;
      Option<BinTree> left,right;

    case (TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()),klst,vlst)
      then (klst,vlst);

    case (TREENODE(value = SOME(TREEVALUE(key=key,value=value)),leftSubTree = left,rightSubTree = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
        (klst,vlst) = bintreeToListOpt(right, klst, vlst);
      then
        ((key :: klst),(value :: vlst));

    case (TREENODE(value = NONE(),leftSubTree = left),klst,vlst)
      equation
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToList2;

protected function bintreeToListOpt "author: PA
  helper function to bintreeToList"
  input Option<BinTree> inBinTreeOption;
  input list<Key> inKeyLst;
  input list<Value> inValueLst;
  output list<Key> outKeyLst;
  output list<Value> outValueLst;
algorithm
  (outKeyLst,outValueLst) := match (inBinTreeOption,inKeyLst,inValueLst)
    local
      list<Key> klst;
      list<Value> vlst;
      BinTree bt;

    case (NONE(),klst,vlst) then (klst,vlst);

    case (SOME(bt),klst,vlst)
      equation
        (klst,vlst) = bintreeToList2(bt, klst, vlst);
      then
        (klst,vlst);
  end match;
end bintreeToListOpt;

annotation(__OpenModelica_Interface="backend");
end BinaryTreeInt;
