/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�pings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package VarTransform
" file:	       VarTransform.mo
  package:     VarTransform
  description: VarTransform contains a Binary Tree representation of variable replacements.

  RCS: $Id$

  This module contain a Binary tree representation of variable replacements
  along with some functions for performing replacements of variables in equations"

public import DAE;
public import HashTable2;
public import HashTable3;
public import SCode;

public
uniontype VariableReplacements "
VariableReplacements consists of a mapping between variables and expressions, the first binary tree of this type.
To eliminate a variable from an equation system a replacement rule varname->expression is added to this
datatype.
To be able to update these replacement rules incrementally a backward lookup mechanism is also required.
For instance, having a rule a->b and adding a rule b->c requires to find the first rule a->b and update it to
a->c. This is what the second binary tree is used for.
   "
  record REPLACEMENTS
    HashTable2.HashTable hashTable "src -> dst, used for replacing. src is variable, dst is expression" ;
    HashTable3.HashTable invHashTable "dst -> list of sources. dst is a variable, sources are variables.";
  end REPLACEMENTS;

end VariableReplacements;

public
uniontype BinTree
  record TREENODE
    Option<TreeValue> value "Value" ;
    Option<BinTree> left "left subtree" ;
    Option<BinTree> right "right subtree" ;
  end TREENODE;

end BinTree;

public
uniontype BinTree2
  record TREENODE2
    Option<TreeValue2> value "Value" ;
    Option<BinTree2> left "left subtree" ;
    Option<BinTree2> right "right subtree" ;
  end TREENODE2;

end BinTree2;

public
uniontype TreeValue "Each node in the binary tree can have a value associated with it."
  record TREEVALUE
    Key key "Key" ;
    Value value "Value" ;
  end TREEVALUE;

end TreeValue;

public
uniontype TreeValue2
  record TREEVALUE2
    Key key "Key" ;
    Value2 value "Value" ;
  end TREEVALUE2;

end TreeValue2;

public
type Key = DAE.ComponentRef "Key" ;

public
type Value = DAE.Exp;

public
type Value2 = list<DAE.ComponentRef>;

protected import Absyn;
protected import Algorithm;
protected import Exp;
protected import System;
protected import Util;
//protected import RTOpts;
//protected import Debug;
protected import DAEUtil;

public function applyReplacementsDAE "Apply a set of replacement rules on a DAE "
  input DAE.DAElist dae;
  input VariableReplacements repl;
	input Option<FuncTypeExp_ExpToBoolean> condExpFunc;
	output DAE.DAElist outDae;
	partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outDae := matchcontinue(dae,repl,condExpFunc)
  local list<DAE.Element> elts;
    DAE.FunctionTree funcs;
    list<tuple<DAE.AvlKey,DAE.AvlValue>> funcLst;
    case(DAE.DAE(elts,funcs),repl,condExpFunc) equation
      elts = applyReplacementsDAEElts(elts,repl,condExpFunc);
      funcLst = DAEUtil.avlTreeToList(funcs);
      funcLst = applyReplacementsDAEFuncLst(funcLst,repl,condExpFunc);
      funcs = DAEUtil.avlTreeAddLst(funcLst,DAEUtil.avlTreeNew());
    then (DAE.DAE(elts,funcs));
  end matchcontinue;
end applyReplacementsDAE;

protected function applyReplacementsDAEFuncLst "help function to applyReplacementsDAE, goes though the function tree"
  input list<tuple<DAE.AvlKey,DAE.AvlValue>> funcLst;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> condExpFunc;
	output list<tuple<DAE.AvlKey,DAE.AvlValue>> outFuncLst;
	partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outFuncLst := matchcontinue(funcLst,repl,condExpFunc)
   local
     Absyn.Path p;
     DAE.Element elt;
    case({},repl,condExpFunc) then {};
    case((p,elt)::funcLst,repl,condExpFunc) equation
      {elt} = applyReplacementsDAEElts({elt},repl,condExpFunc);
      funcLst = applyReplacementsDAEFuncLst(funcLst,repl,condExpFunc);
    then ((p,elt)::funcLst);
  end matchcontinue;
end applyReplacementsDAEFuncLst;

public function applyReplacementsDAEElts "Help function to applyReplacementsDAE, goes though the element list"
	input list<DAE.Element> inDae;
	input VariableReplacements repl;
	input Option<FuncTypeExp_ExpToBoolean> condExpFunc;
	output list<DAE.Element> outDae;
	partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outDae := matchcontinue(inDae,repl,condExpFunc)
    local
      DAE.ComponentRef cr,cr2,cr1,cr1_2;
      list<DAE.Element> dae,dae2,elist,elist2,elist22,elist1,elist11;
      DAE.Element elt,elt2,elt22,elt1,elt11;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp,ftp;
      DAE.Exp bindExp,bindExp2,e,e2,e22,e1,e11;
      DAE.InstDims dims;
      DAE.StartValue start;
      DAE.Flow fl;
      DAE.ElementSource source "the origin of the element";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> cmt;
      Absyn.InnerOuter io;
      list<Integer> idims;
      DAE.ExternalDecl extDecl;
      DAE.Ident id;
      Absyn.Path path;
      list<DAE.Statement> stmts,stmts2;
      DAE.VarProtection prot;
      DAE.Stream st;
      Boolean partialPrefix;
      DAE.ExternalDecl extdecl;

      // if no replacements, return dae, no need to traverse.
    case(dae,REPLACEMENTS(HashTable2.HASHTABLE(numberOfEntries=0),_),condExpFunc) then dae;

    case({},repl,condExpFunc) then {};

    case(DAE.VAR(cr,kind,dir,prot,tp,SOME(bindExp),dims,fl,st,source,attr,cmt,io)::dae,repl,condExpFunc)
      equation
        (bindExp2) = replaceExp(bindExp, repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae, repl, condExpFunc);
        attr = applyReplacementsVarAttr(attr, repl, condExpFunc);
      then DAE.VAR(cr,kind,dir,prot,tp,SOME(bindExp2),dims,fl,st,source,attr,cmt,io)::dae2;

    case(DAE.VAR(cr,kind,dir,prot,tp,NONE,dims,fl,st,source,attr,cmt,io)::dae,repl,condExpFunc)
      equation
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
        attr = applyReplacementsVarAttr(attr,repl,condExpFunc);
      then DAE.VAR(cr,kind,dir,prot,tp,NONE,dims,fl,st,source,attr,cmt,io)::dae2;

    case(DAE.DEFINE(cr,e,source)::dae,repl,condExpFunc)
      equation
        (e2) = replaceExp(e, repl, condExpFunc);
        (DAE.CREF(cr2,_)) = replaceExp(DAE.CREF(cr, DAE.ET_OTHER()), repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.DEFINE(cr2,e2,source)::dae2;

    case(DAE.INITIALDEFINE(cr,e,source)::dae,repl,condExpFunc)
      equation
        (e2) = replaceExp(e, repl, condExpFunc);
        (DAE.CREF(cr2,_)) = replaceExp(DAE.CREF(cr, DAE.ET_OTHER()), repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.INITIALDEFINE(cr2,e2,source)::dae2;

    case(DAE.EQUEQUATION(cr,cr1,source)::dae,repl,condExpFunc)
      equation
        (DAE.CREF(cr2,_)) = replaceExp(DAE.CREF(cr, DAE.ET_OTHER()), repl, condExpFunc);
        (DAE.CREF(cr1_2,_)) = replaceExp(DAE.CREF(cr1, DAE.ET_OTHER()), repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.EQUEQUATION(cr2,cr1_2,source)::dae2;

    case(DAE.EQUATION(e1,e2,source)::dae,repl,condExpFunc)
      equation
        (e11) = replaceExp(e1, repl, condExpFunc);
        (e22) = replaceExp(e2, repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.EQUATION(e11,e22,source)::dae2;

    case(DAE.ARRAY_EQUATION(idims,e1,e2,source)::dae,repl,condExpFunc)
      equation
        (e11) = replaceExp(e1, repl, condExpFunc);
        (e22) = replaceExp(e2, repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.ARRAY_EQUATION(idims,e11,e22,source)::dae2;

    case(DAE.WHEN_EQUATION(e1,elist,SOME(elt),source)::dae,repl,condExpFunc)
      equation
        (e11) = replaceExp(e1, repl, condExpFunc);
        {elt2}= applyReplacementsDAEElts({elt},repl,condExpFunc);
        elist2 = applyReplacementsDAEElts(elist,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.WHEN_EQUATION(e11,elist2,SOME(elt2),source)::dae2;

    case(DAE.WHEN_EQUATION(e1,elist,NONE,source)::dae,repl,condExpFunc)
      equation
        (e11) = replaceExp(e1, repl, condExpFunc);
        elist2 = applyReplacementsDAEElts(elist,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.WHEN_EQUATION(e11,elist2,NONE,source)::dae2;

    case(DAE.IF_EQUATION(conds,tbs,elist2,source)::dae,repl,condExpFunc)
      local
        list<list<DAE.Element>> tbs,tbs_1;
        list<DAE.Exp> conds,conds_1;
      equation
        conds_1 = Util.listMap2(conds,replaceExp, repl, condExpFunc);
        tbs_1 = Util.listMap2(tbs,applyReplacementsDAEElts,repl,condExpFunc);
        elist22 = applyReplacementsDAEElts(elist2,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.IF_EQUATION(conds_1,tbs_1,elist22,source)::dae2;

    case(DAE.INITIAL_IF_EQUATION(conds,tbs,elist2,source)::dae,repl,condExpFunc)
      local
        list<list<DAE.Element>> tbs,tbs_1;
        list<DAE.Exp> conds,conds_1;
      equation
        conds_1 = Util.listMap2(conds,replaceExp, repl, condExpFunc);
        tbs_1 = Util.listMap2(tbs,applyReplacementsDAEElts,repl,condExpFunc);
        elist22 = applyReplacementsDAEElts(elist2,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.INITIAL_IF_EQUATION(conds_1,tbs_1,elist22,source)::dae2;

    case(DAE.INITIALEQUATION(e1,e2,source)::dae,repl,condExpFunc)
      equation
        (e11) = replaceExp(e1, repl, condExpFunc);
        (e22) = replaceExp(e2, repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.INITIALEQUATION(e11,e22,source)::dae2;

    case(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),source)::dae,repl,condExpFunc)
      equation
        stmts2 = replaceEquationsStmts(stmts,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts2),source)::dae2;

    case(DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts),source)::dae,repl,condExpFunc)
      equation
        stmts2 = replaceEquationsStmts(stmts,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts2),source)::dae2;

    case(DAE.COMP(id,elist,source)::dae,repl,condExpFunc)
      equation
        elist2 = applyReplacementsDAEElts(elist,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.COMP(id,elist,source)::dae2;

     case(DAE.FUNCTION(path,DAE.FUNCTION_DEF(elist)::derFuncs,ftp,partialPrefix,inlineType,source)::dae,repl,condExpFunc)
       local list<DAE.FunctionDefinition> derFuncs;
         DAE.InlineType inlineType;
      equation
        elist2 = applyReplacementsDAEElts(elist,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
        then
          DAE.FUNCTION(path,DAE.FUNCTION_DEF(elist2)::derFuncs,ftp,partialPrefix,inlineType,source)::dae2;
     // adrpo 2010-02-16: apply also replacements to the external function DAE.
     case(DAE.FUNCTION(path,DAE.FUNCTION_EXT(elist,extdecl)::derFuncs,ftp,partialPrefix,inlineType,source)::dae,repl,condExpFunc)
       local list<DAE.FunctionDefinition> derFuncs;
         DAE.InlineType inlineType;
      equation
        elist2 = applyReplacementsDAEElts(elist,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
        then
          DAE.FUNCTION(path,DAE.FUNCTION_EXT(elist2,extdecl)::derFuncs,ftp,partialPrefix,inlineType,source)::dae2;

    case(DAE.EXTOBJECTCLASS(path,elt1,elt2,source)::dae,repl,condExpFunc)
      equation
        {elt11,elt22} =  applyReplacementsDAEElts({elt1,elt2},repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.EXTOBJECTCLASS(path,elt1,elt2,source)::dae2;

    case(DAE.ASSERT(e1,e2,source)::dae,repl,condExpFunc)
      equation
        (e11) = replaceExp(e1, repl, condExpFunc);
        (e22) = replaceExp(e2, repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.ASSERT(e11,e22,source)::dae2;

    case(DAE.TERMINATE(e1,source)::dae,repl,condExpFunc)
      equation
        (e11) = replaceExp(e1, repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.TERMINATE(e11,source)::dae2;

    case(DAE.REINIT(cr,e1,source)::dae,repl,condExpFunc)
      equation
        (e11) = replaceExp(e1, repl, condExpFunc);
        (DAE.CREF(cr2,_)) = replaceExp(DAE.CREF(cr,DAE.ET_REAL()), repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.REINIT(cr2,e11,source)::dae2;

    case(DAE.COMPLEX_EQUATION(e1,e2,source)::dae,repl,condExpFunc)
      equation
        (e11) = replaceExp(e1, repl, condExpFunc);
        (e22) = replaceExp(e2, repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.COMPLEX_EQUATION(e11,e22,source)::dae2;

    case(DAE.INITIAL_COMPLEX_EQUATION(e1,e2,source)::dae,repl,condExpFunc)
      equation
        (e11) = replaceExp(e1, repl, condExpFunc);
        (e22) = replaceExp(e2, repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.INITIAL_COMPLEX_EQUATION(e11,e22,source)::dae2;

    // failtrace. adrpo: TODO! FIXME! this SHOULD NOT FAIL!
    case(elt::dae,repl,condExpFunc)
      local String str;
      equation
        // Debug.fprintln("failtrace", "- VarTransform.applyReplacementsDAEElts could not apply replacements to: " +& DAEUtil.dumpElementsStr({elt}));
        dae = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then elt::dae;
  end matchcontinue;
end applyReplacementsDAEElts;

protected function applyReplacementsVarAttr "Help function to applyReplacementsDAEElts"
  input Option<DAE.VariableAttributes> attr;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> condExpFunc;
  output Option<DAE.VariableAttributes> outAttr;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outAttr := matchcontinue(attr,repl,condExpFunc)
    local Option<DAE.Exp> quantity,unit,displayUnit,min,max,initial_,fixed,nominal;
      Option<DAE.StateSelect> stateSelect;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case(SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect,eb,ip,fn)),repl,condExpFunc) equation
      (quantity) = replaceExpOpt(quantity,repl,condExpFunc);
      (unit) = replaceExpOpt(unit,repl,condExpFunc);
      (displayUnit) = replaceExpOpt(displayUnit,repl,condExpFunc);
      (min) = replaceExpOpt(min,repl,condExpFunc);
      (max) = replaceExpOpt(max,repl,condExpFunc);
      (initial_) = replaceExpOpt(initial_,repl,condExpFunc);
      (fixed) = replaceExpOpt(fixed,repl,condExpFunc);
      (nominal) = replaceExpOpt(nominal,repl,condExpFunc);
      then SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect,eb,ip,fn));

    case(SOME(DAE.VAR_ATTR_INT(quantity,(min,max),initial_,fixed,eb,ip,fn)),repl,condExpFunc) equation
      (quantity) = replaceExpOpt(quantity,repl,condExpFunc);
      (min) = replaceExpOpt(min,repl,condExpFunc);
      (max) = replaceExpOpt(max,repl,condExpFunc);
      (initial_) = replaceExpOpt(initial_,repl,condExpFunc);
      (fixed) = replaceExpOpt(fixed,repl,condExpFunc);
      then SOME(DAE.VAR_ATTR_INT(quantity,(min,max),initial_,fixed,eb,ip,fn));

      case(SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn)),repl,condExpFunc) equation
      (quantity) = replaceExpOpt(quantity,repl,condExpFunc);
      (initial_) = replaceExpOpt(initial_,repl,condExpFunc);
      (fixed) = replaceExpOpt(fixed,repl,condExpFunc);
      then SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn));

      case(SOME(DAE.VAR_ATTR_STRING(quantity,initial_,eb,ip,fn)),repl,condExpFunc) equation
      (quantity) = replaceExpOpt(quantity,repl,condExpFunc);
      (initial_) = replaceExpOpt(initial_,repl,condExpFunc);
      then SOME(DAE.VAR_ATTR_STRING(quantity,initial_,eb,ip,fn));

      case (NONE(),repl,_) then NONE();
  end matchcontinue;
end  applyReplacementsVarAttr;

public function applyReplacements "function: applyReplacements

  This function takes a VariableReplacements and two component references.
  It applies the replacements to each component reference.
"
  input VariableReplacements inVariableReplacements1;
  input DAE.ComponentRef inComponentRef2;
  input DAE.ComponentRef inComponentRef3;
  output DAE.ComponentRef outComponentRef1;
  output DAE.ComponentRef outComponentRef2;
algorithm
  (outComponentRef1,outComponentRef2):=
  matchcontinue (inVariableReplacements1,inComponentRef2,inComponentRef3)
    local
      DAE.ComponentRef cr1_1,cr2_1,cr1,cr2;
      VariableReplacements repl;
    case (repl,cr1,cr2)
      equation
        (DAE.CREF(cr1_1,_)) = replaceExp(DAE.CREF(cr1,DAE.ET_REAL()), repl, NONE);
        (DAE.CREF(cr2_1,_)) = replaceExp(DAE.CREF(cr2,DAE.ET_REAL()), repl, NONE);
      then
        (cr1_1,cr2_1);
  end matchcontinue;
end applyReplacements;

public function applyReplacementList "function: applyReplacements
 Author: BZ, 2008-11

  This function takes a VariableReplacements and a list of component references.
  It applies the replacements to each component reference.
"
  input VariableReplacements repl;
  input list<DAE.ComponentRef> increfs;
  output list<DAE.ComponentRef> ocrefs;
algorithm  (ocrefs):= matchcontinue (repl,increfs)
    local
      DAE.ComponentRef cr1_1,cr1;
      VariableReplacements repl;
      case(_,{}) then {};
    case (repl,cr1::increfs)
      equation
        (DAE.CREF(cr1_1,_)) = replaceExp(DAE.CREF(cr1,DAE.ET_REAL()), repl, NONE);
        ocrefs = applyReplacementList(repl,increfs);
      then
        cr1_1::ocrefs;
  end matchcontinue;
end applyReplacementList;

public function applyReplacementsExp "

Similar to applyReplacements but for expressions instead of component references.
"
  input VariableReplacements repl;
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp1;
  output DAE.Exp outExp2;
algorithm
  (outExp1,outExp2):=
  matchcontinue (repl,inExp1,inExp2)
    local
      DAE.Exp e1,e2;
      VariableReplacements repl;
    case (repl,e1,e2)
      equation
        (e1) = replaceExp(e1, repl, NONE);
        (e2) = replaceExp(e2, repl, NONE);
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
      then
        (e1,e2);
  end matchcontinue;
end applyReplacementsExp;

public function emptyReplacementsArray "create an array of n empty replacements"
  input Integer n;
  output VariableReplacements[:] repl;
algorithm
  repl := listArray(emptyReplacementsArray2(n));
end emptyReplacementsArray;

protected function emptyReplacementsArray2 "help function"
  input Integer n;
  output list<VariableReplacements> replLst;
algorithm
  replLst := matchcontinue(n)
  local VariableReplacements r;
    case(0) then {};
    case(n) equation
      true = n < 0;
      print("Internal error, emptyReplacementsArray2 called with negative n!");
    then fail();
    case(n) equation
      true = n > 0;
      r = emptyReplacements();
      replLst = emptyReplacementsArray2(n-1);
    then r::replLst;
  end matchcontinue;
end emptyReplacementsArray2;

public function emptyReplacements "function: emptyReplacements

  Returns an empty set of replacement rules
"
  output VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements:=
  matchcontinue ()
      local HashTable2.HashTable ht;
        HashTable3.HashTable invHt;
    case ()
      equation
        ht = HashTable2.emptyHashTable();
        invHt = HashTable3.emptyHashTable();
      then
        REPLACEMENTS(ht,invHt);
  end matchcontinue;
end emptyReplacements;

public function replaceEquationsStmts "function: replaceEquationsStmts

  Helper function to replace_equations,
  Handles the replacement of DAE.Statement.
"
  input list<DAE.Statement> inAlgorithmStatementLst;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> condExpFunc;
  output list<DAE.Statement> outAlgorithmStatementLst;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outAlgorithmStatementLst:=
  matchcontinue (inAlgorithmStatementLst,inVariableReplacements,condExpFunc)
    local
      DAE.Exp e_1,e_2,e,e2;
      list<DAE.Exp> expl1,expl2;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Statement> xs_1,xs,stmts,stmts2;
      DAE.ExpType tp,tt;
      VariableReplacements repl;
      DAE.Statement x;
      Boolean b1;
      Algorithm.Ident id1;
    case ({},_,_) then {};
    case ((DAE.STMT_ASSIGN(type_ = tp,exp1 = e2,exp = e) :: xs),repl,condExpFunc)
      equation
        e_1 = replaceExp(e, repl, condExpFunc);
        e_2 = replaceExp(e2, repl, condExpFunc);
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_ASSIGN(tp,e_2,e_1) :: xs_1);
    case ((DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl1, exp = e) :: xs),repl,condExpFunc)
      equation
        e_1 = replaceExp(e, repl, condExpFunc);
        expl2 = Util.listMap2(expl1, replaceExp, repl, condExpFunc);
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_TUPLE_ASSIGN(tp,expl2,e_1) :: xs_1);
    case ((DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e) :: xs),repl,condExpFunc)
      equation
        e_1 = replaceExp(e, repl, condExpFunc);
        (e_2 as DAE.CREF(cr_1,_)) = replaceExp(DAE.CREF(cr,DAE.ET_OTHER()), repl, condExpFunc);
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_ASSIGN_ARR(tp,cr_1,e_1) :: xs_1);
    case (((x as DAE.STMT_IF(exp=e,statementLst=stmts,else_ = el)) :: xs),repl,condExpFunc)
      local Algorithm.Else el,el_1;
      equation
        el_1 = replaceEquationsElse(el,repl,condExpFunc);
        stmts2 = replaceEquationsStmts(stmts,repl,condExpFunc);
        e_1 = replaceExp(e, repl, condExpFunc);
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_IF(e_1,stmts2,el_1) :: xs_1);
    case (((x as DAE.STMT_FOR(type_=tp,boolean=b1,ident=id1,exp=e,statementLst=stmts)) :: xs),repl,condExpFunc)
      equation
        stmts2 = replaceEquationsStmts(stmts,repl,condExpFunc);
        e_1 = replaceExp(e, repl, condExpFunc);
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_FOR(tp,b1,id1,e_1,stmts2) :: xs_1);
    case (((x as DAE.STMT_WHILE(exp = e,statementLst=stmts)) :: xs),repl,condExpFunc)
      equation
        stmts2 = replaceEquationsStmts(stmts,repl,condExpFunc);
        e_1 = replaceExp(e, repl, condExpFunc);
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_WHILE(e_1,stmts2) :: xs_1);
    case (((x as DAE.STMT_WHEN(exp = e,statementLst=stmts,elseWhen=ew,helpVarIndices=li)) :: xs),repl,condExpFunc)
      local Option<DAE.Statement> ew,ew_1; list<Integer> li;
      equation
        ew_1 = replaceOptEquationsStmts(ew,repl,condExpFunc);
        stmts2 = replaceEquationsStmts(stmts,repl,condExpFunc);
        e_1 = replaceExp(e, repl, condExpFunc);
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_WHEN(e_1,stmts2,ew_1,li) :: xs_1);
    case (((x as DAE.STMT_ASSERT(cond = e, msg=e2)) :: xs),repl,condExpFunc)
      equation
        e_1 = replaceExp(e, repl, condExpFunc);
        e_2 = replaceExp(e2, repl, condExpFunc);
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_ASSERT(e_1,e_2) :: xs_1);
    case (((x as DAE.STMT_TERMINATE(msg = e)) :: xs),repl,condExpFunc)
      equation
        e_1 = replaceExp(e, repl, condExpFunc);
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_TERMINATE(e_1) :: xs_1);
    case (((x as DAE.STMT_REINIT(var = e,value=e2)) :: xs),repl,condExpFunc)
      equation
        e_1 = replaceExp(e, repl, condExpFunc);
        e_2 = replaceExp(e2, repl, condExpFunc);
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_REINIT(e_1,e_2) :: xs_1);
    case ((x as DAE.STMT_NORETCALL(e)) :: xs,repl,condExpFunc)
      local Absyn.Path fnName;
      equation
        e_1 = replaceExp(e, repl, condExpFunc);
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_NORETCALL(e_1) :: xs_1);
    case (((x as DAE.STMT_RETURN()) :: xs),repl,condExpFunc)
      equation
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (x :: xs_1);

    case (((x as DAE.STMT_BREAK()) :: xs),repl,condExpFunc)
      equation
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (x :: xs_1);
    case ((x :: xs),repl,condExpFunc)
      equation
        print("Warning, not implemented in replace_equations_stmts\n");
        xs_1 = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (x :: xs_1);
  end matchcontinue;

end replaceEquationsStmts;

protected function replaceEquationsElse "
Helper function for replaceEquationsStmts, replaces Algorithm.Else"
  input Algorithm.Else inElse;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> condExpFunc;
  output Algorithm.Else outElse;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm outElse := matchcontinue(inElse,repl,condExpFunc)
  local
    DAE.Exp e,e_1;
    list<DAE.Statement> st,st_1;
    Algorithm.Else el,el_1;
  case(DAE.NOELSE(),_,_) then DAE.NOELSE;
  case(DAE.ELSEIF(e,st,el),repl,condExpFunc)
    equation
      el_1 = replaceEquationsElse(el,repl,condExpFunc);
      st_1 = replaceEquationsStmts(st,repl,condExpFunc);
      e_1 = replaceExp(e, repl, condExpFunc);
    then DAE.ELSEIF(e_1,st_1,el_1);
  case(DAE.ELSE(st),repl,condExpFunc)
    equation
      st_1 = replaceEquationsStmts(st,repl,condExpFunc);
    then DAE.ELSE(st_1);
end matchcontinue;
end replaceEquationsElse;

protected function replaceOptEquationsStmts "
Helper function for replaceEquationsStmts, replaces optional statement"
  input Option<DAE.Statement> optStmt;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> condExpFunc;
  output Option<DAE.Statement> outAlgorithmStatementLst;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm outAlgorithmStatementLst := matchcontinue(optStmt,inVariableReplacements,condExpFunc)
  local DAE.Statement stmt,stmt2;
  case(SOME(stmt),inVariableReplacements,condExpFunc)
    equation
    ({stmt2}) = replaceEquationsStmts({stmt},inVariableReplacements,condExpFunc);
    then SOME(stmt2);
  case(NONE,_,_) then NONE;
    end matchcontinue;
end replaceOptEquationsStmts;

public function dumpReplacements
"function: dumpReplacements
  Prints the variable replacements on form var1 -> var2"
  input VariableReplacements inVariableReplacements;
algorithm
  _:=
  matchcontinue (inVariableReplacements)
    local
      list<DAE.Exp> srcs,dsts;
      list<String> srcstrs,dststrs,dststrs_1,strs;
      String str,len_str;
      Integer len;
      HashTable2.HashTable ht;
      list<tuple<DAE.ComponentRef,DAE.Exp>> tplLst;
    case (REPLACEMENTS(hashTable= ht))
      equation
        (tplLst) = HashTable2.hashTableList(ht);
        str = Util.stringDelimitList(Util.listMap(tplLst,printReplacementTupleStr),"\n");
        print("Replacements: (");
        len = listLength(tplLst);
        len_str = intString(len);
        print(len_str);
        print(")\n");
        print("=============\n");
        print(str);
        print("\n");
      then
        ();
  end matchcontinue;
end dumpReplacements;

public function dumpReplacementsStr "
Author BZ 2009-04
Function for dumping replacements to string.
"
  input VariableReplacements inVariableReplacements;
  output String ostr;
algorithm ostr := matchcontinue (inVariableReplacements)
    local
      list<DAE.Exp> srcs,dsts;
      list<String> srcstrs,dststrs,dststrs_1,strs;
      String str,len_str,s1;
      Integer len;
      HashTable2.HashTable ht;
      list<tuple<DAE.ComponentRef,DAE.Exp>> tplLst;
    case (REPLACEMENTS(hashTable = ht))
      equation
        (tplLst) = HashTable2.hashTableList(ht);
        str = Util.stringDelimitList(Util.listMap(tplLst,printReplacementTupleStr),"\n");
        s1 = "Replacements: (" +& intString(listLength(tplLst)) +& ")\n=============\n" +& str +& "\n";
      then
        s1;
  end matchcontinue;
end dumpReplacementsStr;

public function getAllReplacements "
Author BZ 2009-04
Extract all crefs -> exp to two separate lists.
"
input VariableReplacements inVariableReplacements;
output list<DAE.ComponentRef> crefs;
output list<DAE.Exp> dsts;
algorithm (dsts,crefs) := matchcontinue (inVariableReplacements)
    local
      HashTable2.HashTable ht;
      list<tuple<DAE.ComponentRef,DAE.Exp>> tplLst;
    case (REPLACEMENTS(hashTable = ht))
      equation
        tplLst = HashTable2.hashTableList(ht);
        crefs = Util.listMap(tplLst,Util.tuple21);
        dsts = Util.listMap(tplLst,Util.tuple22);
      then
        (crefs,dsts);
  end matchcontinue;
end getAllReplacements;

protected function printReplacementTupleStr "help function to dumpReplacements"
  input tuple<DAE.ComponentRef,DAE.Exp> tpl;
  output String str;
algorithm
  // optional exteded type debugging
  str := Exp.debugPrintComponentRefTypeStr(Util.tuple21(tpl)) +& " -> " +& Exp.debugPrintComponentRefExp(Util.tuple22(tpl));
  // Normal debugging, without type&dimension information on crefs.
  //str := Exp.printComponentRefStr(Util.tuple21(tpl)) +& " -> " +& Exp.printExpStr(Util.tuple22(tpl));
end printReplacementTupleStr;

public function replacementSources "Returns all sources of the replacement rules"
  input VariableReplacements repl;
  output list<DAE.ComponentRef> sources;
algorithm
  sources := matchcontinue(repl)
  local list<DAE.Exp> srcs;
    HashTable2.HashTable ht;
    case (REPLACEMENTS(ht,_))
      equation
          sources = HashTable2.hashTableKeyList(ht);
      then sources;
  end matchcontinue;
end replacementSources;

public function replacementTargets "Returns all targets of the replacement rules"
  input VariableReplacements repl;
  output list<DAE.ComponentRef> sources;
algorithm
  sources := matchcontinue(repl)
  local
    list<DAE.Exp> targets;
    list<DAE.ComponentRef> targets2;
    HashTable2.HashTable ht;
    case (REPLACEMENTS(ht,_))
      equation
          targets = HashTable2.hashTableValueList(ht);
          targets2 = Util.listFlatten(Util.listMap(targets,Exp.getCrefFromExp));
      then  targets2;
  end matchcontinue;
end replacementTargets;

public function addReplacement "function: addReplacement

  Adds a replacement rule to the set of replacement rules given as argument.
  If a replacement rule a->b already exists and we add a new rule b->c then
  the rule a->b is updated to a->c. This is done using the make_transitive
  function.
"
  input VariableReplacements repl;
  input DAE.ComponentRef inSrc;
  input DAE.Exp inDst;
  output VariableReplacements outRepl;
algorithm
  outRepl:=
  matchcontinue (repl,inSrc,inDst)
    local
      DAE.ComponentRef src,src_1,dst_1;
      DAE.Exp dst,dst_1,olddst;
      VariableReplacements repl;
      HashTable2.HashTable ht,ht_1;
      HashTable3.HashTable invHt,invHt_1;
      String s1,s2,s3,s4,s;
    case ((repl as REPLACEMENTS(ht,invHt)),src,dst) /* source dest */
      equation
        olddst = HashTable2.get(src, ht) "if rule a->b exists, fail" ;
      then
        fail();
    case ((repl as REPLACEMENTS(ht,invHt)),src,dst)
      equation
        (REPLACEMENTS(ht,invHt),src_1,dst_1) = makeTransitive(repl, src, dst);
        /*s1 = Exp.printComponentRefStr(src);
        s2 = Exp.printExpStr(dst);
        s3 = Exp.printComponentRefStr(src_1);
        s4 = Exp.printExpStr(dst_1);
        s = Util.stringAppendList(
          {"add_replacement(",s1,", ",s2,") -> add_replacement(",s3,
          ", ",s4,")\n"});
          print(s);
        Debug.fprint("addrepl", s);*/
        ht_1 = HashTable2.add((src_1, dst_1),ht);
        invHt_1 = addReplacementInv(invHt, src_1, dst_1);
      then
        REPLACEMENTS(ht_1,invHt_1);
    case (_,_,_)
      equation
        print("-add_replacement failed\n");
      then
        fail();
  end matchcontinue;
end addReplacement;

public function addReplacementNoTransitive "Similar to addReplacement but
does not make transitive replacement rules.
"
  input VariableReplacements repl;
  input DAE.ComponentRef inSrc;
  input DAE.Exp inDst;
  output VariableReplacements outRepl;
algorithm
  outRepl:=
  matchcontinue (repl,inSrc,inDst)
    local
      DAE.ComponentRef src,src_1,dst_1;
      DAE.Exp dst,dst_1,olddst;
      VariableReplacements repl;
      HashTable2.HashTable ht,ht_1;
      HashTable3.HashTable invHt,invHt_1;
      String s1,s2,s3,s4,s;
    case ((repl as REPLACEMENTS(ht,invHt)),src,dst) /* source dest */
      equation
        olddst = HashTable2.get(src,ht) "if rule a->b exists, fail" ;
      then
        fail();
    case ((repl as REPLACEMENTS(ht,invHt)),src,dst)
      equation
        ht_1 = HashTable2.add((src, dst),ht);
        invHt_1 = addReplacementInv(invHt, src, dst);
      then
        REPLACEMENTS(ht_1,invHt_1);
    case (_,_,_)
      equation
        print("-add_replacement failed\n");
      then
        fail();
  end matchcontinue;
end addReplacementNoTransitive;

protected function addReplacementInv "function: addReplacementInv

  Helper function to addReplacement
  Adds the inverse rule of a replacement to the second binary tree
  of VariableReplacements.
"
  input HashTable3.HashTable invGt;
  input DAE.ComponentRef src;
  input DAE.Exp dst;
  output HashTable3.HashTable outInvHt;
algorithm
  outInvHt:=
  matchcontinue (invHt,src,dst)
    local
      HashTable3.HashTable invHt_1,invHt;
      DAE.ComponentRef src;
      DAE.Exp dst;
      list<DAE.ComponentRef> dests;
    case (invHt,src,dst) equation
      dests = Exp.getCrefFromExp(dst);
      invHt_1 = Util.listFold_2(dests,addReplacementInv2,invHt,src);
      then
        invHt_1;
  end matchcontinue;
end addReplacementInv;

protected function addReplacementInv2 "function: addReplacementInv2

  Helper function to addReplacementInv
  Adds the inverse rule for one of the variables of a replacement to the second binary tree
  of VariableReplacements.
  Since a replacement is on the form var -> expression of vars(v1,v2,...,vn) the inverse binary tree
  contains rules for v1 -> var, v2 -> var, ...., vn -> var so that any of the variables of the expression
  will update the rule.
"
  input HashTable3.HashTable invHt;
  input DAE.ComponentRef src;
  input DAE.ComponentRef dst;
  output HashTable3.HashTable outInvHt;
algorithm
  outInvHt:=
  matchcontinue (invHt,src,dst)
    local
      HashTable3.HashTable invHt_1,invHt;
      DAE.ComponentRef src;
      DAE.ComponentRef dst;
      list<DAE.ComponentRef> srcs;
    case (invHt,src,dst)
      equation
        failure(_ = HashTable3.get(dst,invHt)) "No previous elt for dst -> src" ;
        invHt_1 = HashTable3.add((dst, {src}),invHt);
      then
        invHt_1;
    case (invHt,src,dst)
      equation
        srcs = HashTable3.get(dst,invHt) "previous elt for dst -> src, append.." ;
        invHt_1 = HashTable3.add((dst, (src :: srcs)),invHt);
      then
        invHt_1;
  end matchcontinue;
end addReplacementInv2;

public function addReplacementIfNot "function: addReplacementIf
  Calls addReplacement() if condition (first argument) is true, 
  otherwise does nothing.
  
  Author: asodja, 2010-03-03  
"
  input Boolean condition;
  input VariableReplacements repl;
  input DAE.ComponentRef inSrc;
  input DAE.Exp inDst;  
  output VariableReplacements outRepl;
algorithm 
  outRepl:=  matchcontinue (condition,repl,inSrc,inDst)    
    local
      DAE.ComponentRef src;
      DAE.Exp dst;
      VariableReplacements repl, repl_1;
    case (false,repl,src,dst) /* source dest */
      equation
        repl_1 = addReplacement(repl,src,dst);
      then repl_1;
    case (true,repl,src,dst)
      then repl;
  end matchcontinue;
end addReplacementIfNot;

protected function makeTransitive "function: makeTransitive

  This function takes a set of replacement rules and a new replacement rule
  in the form of two ComponentRef:s and makes sure the new replacement rule
  is replaced with the transitive value.
  For example, if we have the rule a->b and a new rule c->a it is changed to c->b.
  Also, if we have a rule a->b and a new rule b->c then the -old- rule a->b is changed
  to a->c.
  For arbitrary expressions: if we have a rule ax-> expr(b1,..,bn) and a new rule c->expr(a1,ax,..,an)
  it is changed to c-> expr(a1,expr(b1,...,bn),..,an).
  And similary for a rule ax -> expr(b1,bx,..,bn) and a new rule bx->expr(c1,..,cn) then old rule is changed to
  ax -> expr(b1,expr(c1,..,cn),..,bn).
"
  input VariableReplacements repl;
  input DAE.ComponentRef src;
  input DAE.Exp dst;
  output VariableReplacements outRepl;
  output DAE.ComponentRef outSrc;
  output DAE.Exp outDst;
algorithm
  (outRepl,outSrc,outDst):=
  matchcontinue (repl,src,dst)
    local
      VariableReplacements repl_1,repl_2,repl;
      DAE.ComponentRef src_1,src_2;
      DAE.Exp dst_1,dst_2,dst_3;
    case (repl,src,dst)
      equation
        (repl_1,src_1,dst_1) = makeTransitive1(repl, src, dst);
        (repl_2,src_2,dst_2) = makeTransitive2(repl_1, src_1, dst_1);
        dst_3 = Exp.simplify(dst_2) "to remove e.g. --a";
      then
        (repl_2,src_2,dst_3);
  end matchcontinue;
end makeTransitive;

protected function makeTransitive1 "function: makeTransitive1

  helper function to makeTransitive
"
  input VariableReplacements repl;
  input DAE.ComponentRef src;
  input DAE.Exp dst;
  output VariableReplacements outRepl;
  output DAE.ComponentRef outSrc;
  output DAE.Exp outDst;
algorithm
  (outRepl,outSrc,outDst):=
  matchcontinue (repl,src,dst)
    local
      list<DAE.ComponentRef> lst;
      VariableReplacements repl_1,repl,singleRepl;
      HashTable2.HashTable ht;
      HashTable3.HashTable invHt;
      DAE.Exp dst_1;
      // old rule a->expr(b1,..,bn) must be updated to a->expr(c_exp,...,bn) when new rule b1->c_exp
      // is introduced
    case ((repl as REPLACEMENTS(ht,invHt)),src,dst)
      equation
        lst = HashTable3.get(src, invHt);
        singleRepl = addReplacementNoTransitive(emptyReplacements(),src,dst);
        repl_1 = makeTransitive12(lst,repl,singleRepl);
      then
        (repl_1,src,dst);
    case (repl,src,dst) then (repl,src,dst);
  end matchcontinue;
end makeTransitive1;

protected function makeTransitive12 "Helper function to makeTransitive1
For each old rule a->expr(b1,..,bn) update dest by applying the new rule passed as argument
in singleRepl."
  input list<DAE.ComponentRef> lst;
  input VariableReplacements repl;
  input VariableReplacements singleRepl "contain one replacement rule: the rule to be added";
  output VariableReplacements outRepl;
algorithm
  outRepl := matchcontinue(lst,repl,singleRepl)
    local
      DAE.Exp crDst;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crs;
      VariableReplacements repl1,repl2;
      HashTable2.HashTable ht;
    case({},repl,_) then repl;
    case(cr::crs,repl as REPLACEMENTS(hashTable=ht),singleRepl) equation
      crDst = HashTable2.get(cr,ht);
      crDst = replaceExp(crDst,singleRepl,NONE);
      repl1=addReplacementNoTransitive(repl,cr,crDst) "add updated old rule";
      repl2 = makeTransitive12(crs,repl1,singleRepl);
    then repl2;
  end matchcontinue;
end makeTransitive12;

protected function makeTransitive2 "function: makeTransitive2

  Helper function to makeTransitive
"
  input VariableReplacements repl;
  input DAE.ComponentRef src;
  input DAE.Exp dst;
  output VariableReplacements outRepl;
  output DAE.ComponentRef outSrc;
  output DAE.Exp outDst;
algorithm
  (outRepl,outSrc,outDst):=
  matchcontinue (repl,src,dst)
    local
      DAE.ComponentRef src,src_1;
      DAE.Exp newdst,dst_1,dst;
      VariableReplacements repl_1,repl;
      HashTable2.HashTable ht;
      HashTable3.HashTable invHt;
      // for rule a->b1+..+bn, replace all b1 to bn's in the expression;
    case (repl ,src,dst)
      equation
        (dst_1) = replaceExp(dst,repl,NONE);
      then
        (repl,src,dst_1);
        // replace Exp failed, keep old rule.
    case (repl,src,dst) then (repl,src,dst);  /* dst has no own replacement, return */
  end matchcontinue;
end makeTransitive2;

protected function addReplacements "function: addReplacements

  Adding of several replacements at once with common destination.
  Uses add_replacement
"
  input VariableReplacements repl;
  input list<DAE.ComponentRef> srcs;
  input DAE.Exp dst;
  output VariableReplacements outRepl;
algorithm
  outRepl:=
  matchcontinue (repl,srcs,dst)
    local
      VariableReplacements repl,repl_1,repl_2;
      DAE.ComponentRef src;
      list<DAE.ComponentRef> srcs;
    case (repl,{},_) then repl;
    case (repl,(src :: srcs),dst)
      equation
        repl_1 = addReplacement(repl, src, dst);
        repl_2 = addReplacements(repl_1, srcs, dst);
      then
        repl_2;
    case (_,_,_)
      equation
        print("add_replacements failed\n");
      then
        fail();
  end matchcontinue;
end addReplacements;

public function getReplacement "function: getReplacement

  Retrives a replacement variable given a set of replacement rules and a
  source variable.
"
  input VariableReplacements inVariableReplacements;
  input DAE.ComponentRef inComponentRef;
  output DAE.Exp outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inVariableReplacements,inComponentRef)
    local
      DAE.ComponentRef src,src1;
      DAE.Exp dst;
      HashTable2.HashTable ht;
    case (REPLACEMENTS(hashTable=ht),src)
      equation
        src1 = Exp.convertEnumCref(src);
        dst = HashTable2.get(src1,ht);
      then
        dst;
  end matchcontinue;
end getReplacement;

public function replaceExpOpt "Similar to replaceExp but takes Option<Exp> instead of Exp"
 input Option<DAE.Exp> inExp;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> funcOpt;
  output Option<DAE.Exp> outExp;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outExp := matchcontinue (inExp,repl,funcOpt)
  local DAE.Exp e;
    case(NONE(),_,_) then NONE();
    case(SOME(e),repl,funcOpt) equation
      e = replaceExp(e,repl,funcOpt);
    then SOME(e);
  end matchcontinue;
end replaceExpOpt;

protected function avoidDoubleHashLookup "
Author BZ 200X-XX modified 2008-06
When adding replacement rules, we might not have the correct type availible at the moment.
Then DAE.ET_OTHER() is used, so when replacing exp and finding DAE.ET_OTHER(), we use the
type of the expression to be replaced instead.
TODO: find out why array residual functions containing arrays as xloc[] does not work,
	doing that will allow us to use this function for all crefs.
"
input DAE.Exp inExp;
input DAE.ExpType inType;
output DAE.Exp outExp;
algorithm  outExp := matchcontinue(inExp,inType)
  local DAE.ComponentRef cr;
  case(DAE.CREF(cr,DAE.ET_OTHER()),inType)
    then DAE.CREF(cr,inType);
  case(inExp,_) then inExp;
  end matchcontinue;
end avoidDoubleHashLookup;

public function replaceExpRepeated "similar to replaceExp but repeats the replacements until expression no longer changes.
Note: This is only required/useful if replacements are built with addReplacementNoTransitive.
"
  input DAE.Exp e;
  input VariableReplacements repl;
  input Option<VisitFunc> func;
  input Integer maxIter "max iterations";
  output DAE.Exp outExp;

  partial function VisitFunc
    input DAE.Exp exp;
    output Boolean res;
  end VisitFunc;

algorithm
  outExp := replaceExpRepeated2(e,repl,func,maxIter,1,false);
end replaceExpRepeated;

public function replaceExpRepeated2 "help function to replaceExpRepeated
"
  input DAE.Exp e;
  input VariableReplacements repl;
  input Option<VisitFunc> func;
  input Integer maxIter;
  input Integer i;
  input Boolean equal;
  output DAE.Exp outExp;

  partial function VisitFunc
    input DAE.Exp exp;
    output Boolean res;
  end VisitFunc;

algorithm
  outExp := matchcontinue(e,repl,func,maxIter,i,equal)
  local DAE.Exp e1,res;
    case(e,repl,func,maxIter,i,equal) equation
      true = i > maxIter;
    then e;
    case(e,repl,func,maxIter,i,true) then e;
    case(e,repl,func,maxIter,i,false) equation
      e1 = replaceExp(e,repl,func);
      res = replaceExpRepeated2(e1,repl,func,maxIter,i+1,Exp.expEqual(e,e1));
    then res;
  end matchcontinue;
end replaceExpRepeated2;

public function replaceExp "function: replaceExp

  Takes a set of replacement rules and an expression and a function
  giving a boolean value for an expression.
  The function replaces all variables in the expression using
  the replacement rules, if the boolean value is true children of the
  expression is visited (including the expression itself). If it is false,
  no replacemet is performed."
  input DAE.Exp inExp;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
  output DAE.Exp outExp;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outExp:=
  matchcontinue (inExp,inVariableReplacements,inFuncTypeExpExpToBooleanOption)
    local
      DAE.ComponentRef cr_1,cr;
      DAE.Exp e,e1_1,e2_1,e1,e2,e3_1,e3,r_1,r;
      DAE.ExpType t,tp;
      VariableReplacements repl;
      Option<FuncTypeExp_ExpToBoolean> cond;
      DAE.Operator op;
      list<DAE.Exp> expl_1,expl;
      Absyn.Path path,p;
      Boolean c;
      Integer b,i;
      Absyn.CodeNode a;
      String id;
    case ((e as DAE.CREF(componentRef = cr,ty = t)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1) = getReplacement(repl, cr);
        e2 = avoidDoubleHashLookup(e1,t);
      then
        e2;
    case ((e as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
      then
        DAE.BINARY(e1_1,op,e2_1);
    case ((e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
      then
        DAE.LBINARY(e1_1,op,e2_1);
    case ((e as DAE.UNARY(operator = op,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
      then
        DAE.UNARY(op,e1_1);
    case ((e as DAE.LUNARY(operator = op,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
      then
        DAE.LUNARY(op,e1_1);
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),repl,cond)
      equation
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
      then
        DAE.RELATION(e1_1,op,e2_1);
    case ((e as DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
        e3_1 = replaceExp(e3, repl, cond);
      then
        DAE.IFEXP(e1_1,e2_1,e3_1);
    case ((e as DAE.CALL(path = path,expLst = expl,tuple_ = t,builtin = c,ty=tp,inlineType=inl)),repl,cond)
      local Boolean t;
      DAE.InlineType inl; DAE.ExpType tp;
      equation
        true = replaceExpCond(cond, e);
        expl_1 = Util.listMap2(expl, replaceExp, repl, cond);
      then
        DAE.CALL(path,expl_1,t,c,tp,inl);
    case ((e as DAE.ARRAY(ty = tp,scalar = c,array = expl)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        expl_1 = Util.listMap2(expl, replaceExp, repl, cond);
      then
        DAE.ARRAY(tp,c,expl_1);
    case ((e as DAE.MATRIX(ty = t,integer = b,scalar = expl)),repl,cond)
      local list<list<tuple<DAE.Exp, Boolean>>> expl_1,expl;
      equation
        true = replaceExpCond(cond, e);
        expl_1 = replaceExpMatrix(expl, repl, cond);
      then
        DAE.MATRIX(t,b,expl_1);
    case ((e as DAE.RANGE(ty = tp,exp = e1,expOption = NONE,range = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
      then
        DAE.RANGE(tp,e1_1,NONE,e2_1);
    case ((e as DAE.RANGE(ty = tp,exp = e1,expOption = SOME(e3),range = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
        e3_1 = replaceExp(e3, repl, cond);
      then
        DAE.RANGE(tp,e1_1,SOME(e3_1),e2_1);
    case ((e as DAE.TUPLE(PR = expl)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        expl_1 = Util.listMap2(expl, replaceExp, repl, cond);
      then
        DAE.TUPLE(expl_1);
    case ((e as DAE.CAST(ty = tp,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
      then
        DAE.CAST(tp,e1_1);
    case ((e as DAE.ASUB(exp = e1,sub = expl)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
      then
        DAE.ASUB(e1_1,expl);
    case ((e as DAE.SIZE(exp = e1,sz = NONE)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
      then
        DAE.SIZE(e1_1,NONE);
    case ((e as DAE.SIZE(exp = e1,sz = SOME(e2))),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
      then
        DAE.SIZE(e1_1,SOME(e2_1));
    case (DAE.CODE(code = a,ty = b),repl,cond)
      local DAE.ExpType b;
      equation
        print("replace_exp on CODE not impl.\n");
      then
        DAE.CODE(a,b);
    case ((e as DAE.REDUCTION(path = p,expr = e1,ident = id,range = r)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        r_1 = replaceExp(r, repl, cond);
      then
        DAE.REDUCTION(p,e1_1,id,r_1);
    case (e,repl,cond)
      equation
        //Debug.fprintln("failtrace", "- VarTransform.replaceExp faied on: " +& Exp.printExpStr(e));
      then e;
  end matchcontinue;
end replaceExp;

protected function replaceExpCond "function replaceExpCond(cond,e) => true &

  Helper function to replace_exp. Evaluates a condition function if
  SOME otherwise returns true.
"
  input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
  input DAE.Exp inExp;
  output Boolean outBoolean;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outBoolean:=
  matchcontinue (inFuncTypeExpExpToBooleanOption,inExp)
    local
      Boolean res;
      FuncTypeExp_ExpToBoolean cond;
      DAE.Exp e;
    case (SOME(cond),e) /* cond e */
      equation
        res = cond(e);
      then
        res;
    case (NONE,_) then true;
  end matchcontinue;
end replaceExpCond;

protected function replaceExpMatrix "function: replaceExpMatrix
  author: PA

  Helper function to replace_exp, traverses Matrix expression list.
"
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
  output list<list<tuple<DAE.Exp, Boolean>>> outTplExpExpBooleanLstLst;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outTplExpExpBooleanLstLst:=
  matchcontinue (inTplExpExpBooleanLstLst,inVariableReplacements,inFuncTypeExpExpToBooleanOption)
    local
      VariableReplacements repl;
      Option<FuncTypeExp_ExpToBoolean> cond;
      list<tuple<DAE.Exp, Boolean>> e_1,e;
      list<list<tuple<DAE.Exp, Boolean>>> es_1,es;
    case ({},repl,cond) then {};
    case ((e :: es),repl,cond)
      equation
        (e_1) = replaceExpMatrix2(e, repl, cond);
        (es_1) = replaceExpMatrix(es, repl, cond);
      then
        (e_1 :: es_1);
  end matchcontinue;
end replaceExpMatrix;

protected function replaceExpMatrix2 "function: replaceExpMatrix2
  author: PA

  Helper function to replace_exp_matrix
"
  input list<tuple<DAE.Exp, Boolean>> inTplExpExpBooleanLst;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
  output list<tuple<DAE.Exp, Boolean>> outTplExpExpBooleanLst;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outTplExpExpBooleanLst:=
  matchcontinue (inTplExpExpBooleanLst,inVariableReplacements,inFuncTypeExpExpToBooleanOption)
    local
      list<tuple<DAE.Exp, Boolean>> es_1,es;
      DAE.Exp e_1,e;
      Boolean b;
      VariableReplacements repl;
      Option<FuncTypeExp_ExpToBoolean> cond;
    case ({},_,_) then {};
    case (((e,b) :: es),repl,cond)
      equation
        (es_1) = replaceExpMatrix2(es, repl, cond);
        (e_1) = replaceExp(e, repl, cond);
      then
        ((e_1,b) :: es_1);
  end matchcontinue;
end replaceExpMatrix2;

protected function bintreeToExplist "function: bintree_to_list

  This function takes a BinTree and transform it into a list
  representation, i.e. two lists of keys and values
"
  input BinTree inBinTree;
  output list<DAE.Exp> outExpExpLst1;
  output list<DAE.Exp> outExpExpLst2;
algorithm
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inBinTree)
    local
      list<DAE.Exp> klst,vlst;
      BinTree bt;
    case (bt)
      equation
        (klst,vlst) = bintreeToExplist2(bt, {}, {});
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToExplist;

protected function bintreeToExplist2 "function: bintree_to_list2

  helper function to bintree_to_list
"
  input BinTree inBinTree1;
  input list<DAE.Exp> inExpExpLst2;
  input list<DAE.Exp> inExpExpLst3;
  output list<DAE.Exp> outExpExpLst1;
  output list<DAE.Exp> outExpExpLst2;
algorithm
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inBinTree1,inExpExpLst2,inExpExpLst3)
    local
      list<DAE.Exp> klst,vlst;
      DAE.ComponentRef key;
      DAE.Exp value;
      Option<BinTree> left,right;
    case (TREENODE(value = NONE,left = NONE,right = NONE),klst,vlst) then (klst,vlst);
    case (TREENODE(value = SOME(TREEVALUE(key,value)),left = left,right = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToExplistOpt(left, klst, vlst);
        (klst,vlst) = bintreeToExplistOpt(right, klst, vlst);
      then
        ((DAE.CREF(key,DAE.ET_REAL()) :: klst),(value :: vlst));
    case (TREENODE(value = NONE,left = left,right = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToExplistOpt(left, klst, vlst);
        (klst,vlst) = bintreeToExplistOpt(left, klst, vlst);
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToExplist2;

protected function bintreeToExplistOpt "function: bintree_to_list_opt

  helper function to bintree_to_list
"
  input Option<BinTree> inBinTreeOption1;
  input list<DAE.Exp> inExpExpLst2;
  input list<DAE.Exp> inExpExpLst3;
  output list<DAE.Exp> outExpExpLst1;
  output list<DAE.Exp> outExpExpLst2;
algorithm
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inBinTreeOption1,inExpExpLst2,inExpExpLst3)
    local
      list<DAE.Exp> klst,vlst;
      BinTree bt;
    case (NONE,klst,vlst) then (klst,vlst);
    case (SOME(bt),klst,vlst)
      equation
        (klst,vlst) = bintreeToExplist2(bt, klst, vlst);
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToExplistOpt;

protected function treeGet "function: treeGet

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string can not be uniquely mapped to an int. Therefore we need to
  compare two strings to get a unique ordering.
"
  input BinTree inBinTree;
  input Key inKey;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inBinTree,inKey)
    local
      String rkeystr,keystr;
      DAE.ComponentRef rkey,key;
      DAE.Exp rval,res;
      Option<BinTree> left,right;
      Integer cmpval;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = right),key)
      equation
        rkeystr = Exp.printComponentRefStr(rkey);
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        rval;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = SOME(right)),key)
      local BinTree right;
      equation
        keystr = Exp.printComponentRefStr(key) "Search to the right" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        res = treeGet(right, key);
      then
        res;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = SOME(left),right = right),key)
      local BinTree left;
      equation
        keystr = Exp.printComponentRefStr(key) "Search to the left" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        res = treeGet(left, key);
      then
        res;
  end matchcontinue;
end treeGet;

protected function treeAdd "function: treeAdd

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string (ComponentRef) can not be uniquely mapped to an int.
  Therefore we need to compare two strings to get a unique ordering.
"
  input BinTree inBinTree;
  input Key inKey;
  input Value inValue;
  output BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inBinTree,inKey,inValue)
    local
      DAE.ComponentRef key,rkey;
      DAE.Exp value,rval;
      String rkeystr,keystr;
      Option<BinTree> left,right;
      Integer cmpval;
      BinTree t_1,t,right_1,left_1;
    case (TREENODE(value = NONE,left = NONE,right = NONE),key,value) then TREENODE(SOME(TREEVALUE(key,value)),NONE,NONE);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = right),key,value)
      equation
        rkeystr = Exp.printComponentRefStr(rkey) "Replace this node" ;
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        TREENODE(SOME(TREEVALUE(rkey,value)),left,right);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = (right as SOME(t))),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to right subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeAdd(t, key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),left,SOME(t_1));
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = (right as NONE)),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to right node" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        right_1 = treeAdd(TREENODE(NONE,NONE,NONE), key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),left,SOME(right_1));
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = (left as SOME(t)),right = right),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to left subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeAdd(t, key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),SOME(t_1),right);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = (left as NONE),right = right),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to left node" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        left_1 = treeAdd(TREENODE(NONE,NONE,NONE), key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),SOME(left_1),right);
    case (_,_,_)
      equation
        print("tree_add failed\n");
      then
        fail();
  end matchcontinue;
end treeAdd;

protected function treeGet2 "function: treeGet2

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string can not be uniquely mapped to an int. Therefore we need
  to compare two strings to get a unique ordering.
"
  input BinTree2 inBinTree2;
  input Key inKey;
  output Value2 outValue2;
algorithm
  outValue2:=
  matchcontinue (inBinTree2,inKey)
    local
      String rkeystr,keystr;
      DAE.ComponentRef rkey,key;
      list<DAE.ComponentRef> rval,res;
      Option<BinTree2> left,right;
      Integer cmpval;
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = left,right = right),key)
      equation
        rkeystr = Exp.printComponentRefStr(rkey);
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        rval;
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = left,right = SOME(right)),key)
      local BinTree2 right;
      equation
        keystr = Exp.printComponentRefStr(key) "Search to the right" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        res = treeGet2(right, key);
      then
        res;
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = SOME(left),right = right),key)
      local BinTree2 left;
      equation
        keystr = Exp.printComponentRefStr(key) "Search to the left" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        res = treeGet2(left, key);
      then
        res;
  end matchcontinue;
end treeGet2;

protected function treeAdd2
"function: treeAdd2
  Copied from generic implementation. Changed that no hashfunction is passed
  since a string (ComponentRef) can not be uniquely mapped to an int.
  Therefore we need to compare two strings to get a unique ordering."
  input BinTree2 inBinTree2;
  input Key inKey;
  input Value2 inValue2;
  output BinTree2 outBinTree2;
algorithm
  outBinTree2:=
  matchcontinue (inBinTree2,inKey,inValue2)
    local
      DAE.ComponentRef key,rkey;
      list<DAE.ComponentRef> value,rval;
      String rkeystr,keystr;
      Option<BinTree2> left,right;
      Integer cmpval;
      BinTree2 t_1,t,right_1,left_1;
    case (TREENODE2(value = NONE,left = NONE,right = NONE),key,value) then TREENODE2(SOME(TREEVALUE2(key,value)),NONE,NONE);
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = left,right = right),key,value)
      equation
        rkeystr = Exp.printComponentRefStr(rkey) "Replace this node" ;
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        TREENODE2(SOME(TREEVALUE2(rkey,value)),left,right);
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = left,right = (right as SOME(t))),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to right subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeAdd2(t, key, value);
      then
        TREENODE2(SOME(TREEVALUE2(rkey,rval)),left,SOME(t_1));
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = left,right = (right as NONE)),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to right node" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        right_1 = treeAdd2(TREENODE2(NONE,NONE,NONE), key, value);
      then
        TREENODE2(SOME(TREEVALUE2(rkey,rval)),left,SOME(right_1));
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = (left as SOME(t)),right = right),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to left subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeAdd2(t, key, value);
      then
        TREENODE2(SOME(TREEVALUE2(rkey,rval)),SOME(t_1),right);
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = (left as NONE),right = right),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to left node" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        left_1 = treeAdd2(TREENODE2(NONE,NONE,NONE), key, value);
      then
        TREENODE2(SOME(TREEVALUE2(rkey,rval)),SOME(left_1),right);
    case (_,_,_)
      equation
        print("tree_add2 failed\n");
      then
        fail();
  end matchcontinue;
end treeAdd2;

end VarTransform;

