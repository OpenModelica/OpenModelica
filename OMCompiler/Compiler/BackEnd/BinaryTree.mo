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

encapsulated package BinaryTree
" file:        BinaryTree.mo
  package:     BinaryTree
  description: BinaryTree comprises functions for BinaryTrees.


  BinaryTree."

/**************************
  imports
 **************************/

public import DAE;

protected import BaseHashTable;
protected import ComponentReference;
protected import Error;
protected import List;
protected import System;
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
    String str;
    Integer hash;
    Value value "Value";
  end TREEVALUE;

end TreeValue;

public
type Key = .DAE.ComponentRef "A key is a Component Reference";

public
type Value = Integer "- Value";

public constant BinTree emptyBinTree=TREENODE(NONE(),NONE(),NONE()) " Empty binary tree ";

/**************************
  implementation
 **************************/

protected function keyCompareNinjaSecretHashTricks
  "Super ninja secret that allows you to implement a binary tree based on the hash of strings.
  And only do string comparisons for those rare conflicts (we use 63-bit integers, so conflicts should be
  very, very rare)"
  input String lstr;
  input Integer lhash;
  input String rstr;
  input Integer rhash;
  output Integer cmp;
algorithm
  cmp := Util.intSign(lhash-rhash);
  cmp := if cmp == 0 then stringCompare(lstr, rstr) else cmp;
end keyCompareNinjaSecretHashTricks;

public function treeGet "author: PA

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
  keystr := ComponentReference.printComponentRefStr(key);
  keyhash := stringHashDjb2Mod(keystr,BaseHashTable.hugeBucketSize);
  v := treeGet3(bt, keystr, keyhash, treeGet2(bt, keystr, keyhash));
end treeGet;

protected function treeGet2
  "Helper function to treeGet"
  input BinTree inBinTree;
  input String keystr;
  input Integer keyhash;
  output Integer compResult;
algorithm
  compResult := match (inBinTree,keystr,keyhash)
    local
      String rkeystr;
      Integer rkeyhash;

    // found it
    case (TREENODE(value = SOME(TREEVALUE(str=rkeystr,hash=rkeyhash))),_,_)
      then keyCompareNinjaSecretHashTricks(rkeystr, rkeyhash, keystr, keyhash);
  end match;
end treeGet2;

protected function treeGet3
  "Helper function to treeGet"
  input BinTree inBinTree;
  input String keystr;
  input Integer keyhash;
  input Integer inCompResult;
  output Value outValue;
algorithm
  outValue := match (inBinTree,keystr,keyhash,inCompResult)
    local
      Value rval;
      BinTree right, left;
      Integer compResult;

    // found it
    case (TREENODE(value = SOME(TREEVALUE(value=rval))),_,_,0) then rval;
    // search right
    case (TREENODE(rightSubTree = SOME(right)),_,_,1)
      equation
        compResult = treeGet2(right, keystr, keyhash);
      then treeGet3(right, keystr, keyhash, compResult);
    // search left
    case (TREENODE(leftSubTree = SOME(left)),_,_,-1)
      equation
        compResult = treeGet2(left, keystr, keyhash);
      then treeGet3(left, keystr, keyhash, compResult);
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
protected
  String str;
algorithm
  str := ComponentReference.printComponentRefStr(inKey);
  // We use modulo hashes in order to avoid problems with boxing/unboxing of integers in bootstrapped OMC
  outBinTree := treeAdd2(inBinTree,inKey,stringHashDjb2Mod(str,BaseHashTable.hugeBucketSize),str,inValue);
end treeAdd;

protected function treeAdd2 "author: PA
  Copied from generic implementation. Changed that no hashfunction is passed
  since a string (ComponentRef) can not be uniquely mapped to an int. Therefore we need to compare two strings
  to get a unique ordering."
  input BinTree inBinTree;
  input Key inKey;
  input Integer keyhash;
  input String keystr;
  input Value inValue;
  output BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inBinTree,inKey,keyhash,keystr,inValue)
    local
      DAE.ComponentRef key,rkey;
      Value value,rval;
      String rkeystr;
      Option<BinTree> left,right;
      BinTree t_1,t,right_1,left_1;
      Integer rhash;
      Option<TreeValue> optVal;

    case (TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()),key,_,_,value)
      then
        TREENODE(SOME(TREEVALUE(key,keystr,keyhash,value)),NONE(),NONE());

    case (TREENODE(value = SOME(TREEVALUE(rkey,rkeystr,rhash,_)),leftSubTree = left,rightSubTree = right),_,_,_,value)
      equation
        0 = keyCompareNinjaSecretHashTricks(rkeystr,rhash,keystr,keyhash);
      then
        TREENODE(SOME(TREEVALUE(rkey,rkeystr,rhash,value)),left,right);

    case (TREENODE(value = optVal as SOME(TREEVALUE(_,rkeystr,rhash,_)),leftSubTree = left,rightSubTree = (SOME(t))),key,_,_,value)
      equation
        1 = keyCompareNinjaSecretHashTricks(rkeystr, rhash, keystr, keyhash);
        t_1 = treeAdd2(t, key, keyhash, keystr, value);
      then
        TREENODE(optVal,left,SOME(t_1));

    case (TREENODE(value = optVal as SOME(TREEVALUE(_,rkeystr,rhash,_)),leftSubTree = left,rightSubTree = (NONE())),key,_,_,value)
      equation
        1 = keyCompareNinjaSecretHashTricks(rkeystr, rhash, keystr, keyhash);
        right_1 = treeAdd2(TREENODE(NONE(),NONE(),NONE()), key, keyhash, keystr, value);
      then
        TREENODE(optVal,left,SOME(right_1));

    case (TREENODE(value = optVal as SOME(TREEVALUE(_,rkeystr,rhash,_)),leftSubTree = (SOME(t)),rightSubTree = right),key,_,_,value)
      equation
        -1 = keyCompareNinjaSecretHashTricks(rkeystr, rhash, keystr, keyhash);
        t_1 = treeAdd2(t, key, keyhash, keystr, value);
      then
        TREENODE(optVal,SOME(t_1),right);

    case (TREENODE(value = optVal as SOME(TREEVALUE(_,rkeystr,rhash,_)),leftSubTree = (NONE()),rightSubTree = right),key,_,_,value)
      equation
        -1 = keyCompareNinjaSecretHashTricks(rkeystr, rhash, keystr, keyhash);
        left_1 = treeAdd2(TREENODE(NONE(),NONE(),NONE()), key, keyhash, keystr, value);
      then
        TREENODE(optVal,SOME(left_1),right);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"- BinaryTree.treeAdd2 failed\n"});
      then
        fail();
  end matchcontinue;
end treeAdd2;

// protected function treeDelete2 "author: PA
//   This function deletes an entry from the BinTree."
//   input BinTree inBinTree;
//   input String keystr;
//   input Integer keyhash;
//   output BinTree outBinTree;
// algorithm
//   outBinTree := matchcontinue (inBinTree,keystr,keyhash)
//     local
//       BinTree bt,right,left,t;
//       DAE.ComponentRef key,rkey;
//       String rkeystr;
//       TreeValue rightmost;
//       Option<BinTree> optRight,optLeft,optTree;
//       Value rval;
//       Option<TreeValue> optVal;
//       Integer rhash;
//
//     case ((bt as TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE())),_,_)
//       then bt;
//
//     case (TREENODE(value = SOME(TREEVALUE(rkey,rkeystr,rhash,rval)),leftSubTree = optLeft,rightSubTree = SOME(right)),_,_)
//       equation
//         0 = keyCompareNinjaSecretHashTricks(rkeystr, rhash, keystr, keyhash);
//         (rightmost,right) = treeDeleteRightmostValue(right);
//         optRight = treePruneEmptyNodes(right);
//       then
//         TREENODE(SOME(rightmost),optLeft,optRight);
//
//     case (TREENODE(value = SOME(TREEVALUE(rkey,rkeystr,rhash,rval)),leftSubTree = SOME(left as TREENODE(value=_)),rightSubTree = NONE()),_,_)
//       equation
//         0 = keyCompareNinjaSecretHashTricks(rkeystr, rhash, keystr, keyhash);
//       then
//         left;
//
//     case (TREENODE(value = SOME(TREEVALUE(rkey,rkeystr,rhash,rval)),leftSubTree = NONE(),rightSubTree = NONE()),_,_)
//       equation
//         0 = keyCompareNinjaSecretHashTricks(rkeystr, rhash, keystr, keyhash);
//       then
//         TREENODE(NONE(),NONE(),NONE());
//
//     case (TREENODE(value = optVal as SOME(TREEVALUE(rkey,rkeystr,rhash,rval)),leftSubTree = optLeft,rightSubTree = SOME(t)),_,_)
//       equation
//         1 = keyCompareNinjaSecretHashTricks(rkeystr, rhash, keystr, keyhash);
//         t = treeDelete2(t, keystr, keyhash);
//         optTree = treePruneEmptyNodes(t);
//       then
//         TREENODE(optVal,optLeft,optTree);
//
//     case (TREENODE(value = optVal as SOME(TREEVALUE(rkey,rkeystr,rhash,rval)),leftSubTree =  SOME(t),rightSubTree = optRight),_,_)
//       equation
//         -1 = keyCompareNinjaSecretHashTricks(rkeystr, rhash, keystr, keyhash);
//         t = treeDelete2(t, keystr, keyhash);
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
    case (_)
      equation
        (klst,vlst) = bintreeToList2(inBinTree, {}, {});
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
      DAE.ComponentRef key;
      Value value;
      Option<BinTree> left,right;

    case (TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()),_,_)
      then (inKeyLst,inValueLst);

    case (TREENODE(value = SOME(TREEVALUE(key=key,value=value)),leftSubTree = left,rightSubTree = right),_,_)
      equation
        (klst,vlst) = bintreeToListOpt(left, key::inKeyLst, value::inValueLst);
        (klst,vlst) = bintreeToListOpt(right, klst, vlst);
      then
        (klst,vlst);

    case (TREENODE(value = NONE(),leftSubTree = left),_,_)
      equation
        (klst,vlst) = bintreeToListOpt(left, inKeyLst, inValueLst);
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

    case (NONE(),_,_) then (inKeyLst,inValueLst);

    case (SOME(bt),_,_)
      equation
        (klst,vlst) = bintreeToList2(bt, inKeyLst,inValueLst);
      then
        (klst,vlst);
  end match;
end bintreeToListOpt;

public function binTreeintersection
"Author: Frenkel TUD 2012-09
  at all key member of bt1 and bt2 to iBt"
  input BinTree bt1;
  input BinTree bt2;
  input BinTree iBt;
  output BinTree oBt;
protected
  list<DAE.ComponentRef> keys;
algorithm
  (keys,_) := bintreeToList(bt1);
  oBt := List.fold1(keys, binTreeintersection1, bt2,iBt);
end binTreeintersection;

protected function binTreeintersection1
"Author: Frenkel TUD 2012-09
  Helper for binTreeintersection1"
  input DAE.ComponentRef key;
  input BinTree bt2;
  input BinTree iBt;
  output BinTree oBt;
algorithm
  oBt := matchcontinue(key,bt2,iBt)
    local
     BinTree bt;
    case(_,_,_)
      equation
        _ = treeGet(bt2,key);
        bt = treeAdd(iBt,key,0);
      then
        bt;
    else iBt;
  end matchcontinue;
end binTreeintersection1;

annotation(__OpenModelica_Interface="backend");
end BinaryTree;
