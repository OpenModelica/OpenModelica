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

encapsulated package VarTransform
" file:        VarTransform.mo
  package:     VarTransform
  description: VarTransform contains a Binary Tree representation of variable replacements.


  This module contain a Binary tree representation of variable replacements
  along with some functions for performing replacements of variables in equations"

public import DAE;
public import HashTable2;
public import HashTable3;
public import SCode;
protected import MetaModelica.Dangerous.listReverseInPlace;

public
uniontype VariableReplacements
"VariableReplacements consists of a mapping between variables and expressions, the first binary tree of this type.
 To eliminate a variable from an equation system a replacement rule varname->expression is added to this
 datatype.
 To be able to update these replacement rules incrementally a backward lookup mechanism is also required.
 For instance, having a rule a->b and adding a rule b->c requires to find the first rule a->b and update it to
 a->c. This is what the second binary tree is used for."
  record REPLACEMENTS
    HashTable2.HashTable hashTable "src -> dst, used for replacing. src is variable, dst is expression.";
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
protected import BaseHashTable;
protected import ComponentReference;
//protected import Debug;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import List;
protected import Util;

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
  outDae := match(dae,repl,condExpFunc)
  local list<DAE.Element> elts;
    DAE.FunctionTree funcs;
    list<tuple<DAE.AvlKey,DAE.AvlValue>> funcLst;
    case(DAE.DAE(elementLst=elts),_,_)
      equation
        elts = applyReplacementsDAEElts(elts,repl,condExpFunc);
      then (DAE.DAE(elts));
  end match;
end applyReplacementsDAE;

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
      DAE.Exp bindExp,bindExp2,e,e2,e22,e1,e11,e3,e32;
      DAE.InstDims dims;
      DAE.StartValue start;
      DAE.ConnectorType ct;
      DAE.ElementSource source "the origin of the element";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> cmt;
      Absyn.InnerOuter io;
      DAE.Dimensions idims;
      DAE.ExternalDecl extDecl;
      DAE.Ident id;
      Absyn.Path path;
      list<DAE.Statement> stmts,stmts2;
      DAE.VarParallelism prl;
      DAE.VarVisibility prot;
      Boolean partialPrefix;
      DAE.ExternalDecl extdecl;
      DAE.Function f1,f2;
      String str;
      list<list<DAE.Element>> tbs,tbs_1;
      list<DAE.Exp> conds,conds_1;

      // if no replacements, return dae, no need to traverse.
    case (dae,REPLACEMENTS((_,_,_,0,_),_),_) then dae;

    case ({},_,_) then {};

    case (DAE.VAR(cr,kind,dir,prl,prot,tp,SOME(bindExp),dims,ct,source,attr,cmt,io)::dae,_,_)
      equation
        (bindExp2,_) = replaceExp(bindExp, repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae, repl, condExpFunc);
        attr = applyReplacementsVarAttr(attr, repl, condExpFunc);
        /* TODO: Add operation to source */
      then DAE.VAR(cr,kind,dir,prl,prot,tp,SOME(bindExp2),dims,ct,source,attr,cmt,io)::dae2;

    case (DAE.VAR(cr,kind,dir,prl,prot,tp,NONE(),dims,ct,source,attr,cmt,io)::dae,_,_)
      equation
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
        attr = applyReplacementsVarAttr(attr,repl,condExpFunc);
      then DAE.VAR(cr,kind,dir,prl,prot,tp,NONE(),dims,ct,source,attr,cmt,io)::dae2;

    case (DAE.DEFINE(cr,e,source)::dae,_,_)
      equation
        (e2,_) = replaceExp(e, repl, condExpFunc);
        (DAE.CREF(cr2,_),_) = replaceExp(Expression.crefExp(cr), repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
        /* TODO: Add operation to source */
      then DAE.DEFINE(cr2,e2,source)::dae2;

    case (DAE.INITIALDEFINE(cr,e,source)::dae,_,_)
      equation
        (e2,_) = replaceExp(e, repl, condExpFunc);
        (DAE.CREF(cr2,_),_) = replaceExp(Expression.crefExp(cr), repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
        /* TODO: Add operation to source */
      then DAE.INITIALDEFINE(cr2,e2,source)::dae2;

    case (DAE.EQUEQUATION(cr,cr1,source)::dae,_,_)
      equation
        (DAE.CREF(cr2,_),_) = replaceExp(Expression.crefExp(cr), repl, condExpFunc);
        (DAE.CREF(cr1_2,_),_) = replaceExp(Expression.crefExp(cr1), repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
        /* TODO: Add operation to source */
      then DAE.EQUEQUATION(cr2,cr1_2,source)::dae2;

    case (DAE.EQUATION(e1,e2,source)::dae,_,_)
      equation
        (e11,_) = replaceExp(e1, repl, condExpFunc);
        (e22,_) = replaceExp(e2, repl, condExpFunc);
        /* TODO: Add operation to source */
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.EQUATION(e11,e22,source)::dae2;

    case (DAE.ARRAY_EQUATION(idims,e1,e2,source)::dae,_,_)
      equation
        (e11,_) = replaceExp(e1, repl, condExpFunc);
        (e22,_) = replaceExp(e2, repl, condExpFunc);
        /* TODO: Add operation to source */
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.ARRAY_EQUATION(idims,e11,e22,source)::dae2;

    case (DAE.INITIAL_ARRAY_EQUATION(idims,e1,e2,source)::dae,_,_)
      equation
        (e11,_) = replaceExp(e1, repl, condExpFunc);
        (e22,_) = replaceExp(e2, repl, condExpFunc);
        /* TODO: Add operation to source */
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.INITIAL_ARRAY_EQUATION(idims,e11,e22,source)::dae2;

    case (DAE.WHEN_EQUATION(e1,elist,SOME(elt),source)::dae,_,_)
      equation
        (e11,_) = replaceExp(e1, repl, condExpFunc);
        /* TODO: Add operation to source */
        {elt2} = applyReplacementsDAEElts({elt},repl,condExpFunc);
        elist2 = applyReplacementsDAEElts(elist,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.WHEN_EQUATION(e11,elist2,SOME(elt2),source)::dae2;

    case (DAE.WHEN_EQUATION(e1,elist,NONE(),source)::dae,_,_)
      equation
        (e11,_) = replaceExp(e1, repl, condExpFunc);
        /* TODO: Add operation to source */
        elist2 = applyReplacementsDAEElts(elist,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.WHEN_EQUATION(e11,elist2,NONE(),source)::dae2;

    case (DAE.IF_EQUATION(conds,tbs,elist2,source)::dae,_,_)
      equation
        (conds_1,_) = replaceExpList(conds, repl, condExpFunc);
        /* TODO: Add operation to source */
        tbs_1 = List.map2(tbs,applyReplacementsDAEElts,repl,condExpFunc);
        elist22 = applyReplacementsDAEElts(elist2,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.IF_EQUATION(conds_1,tbs_1,elist22,source)::dae2;

    case (DAE.INITIAL_IF_EQUATION(conds,tbs,elist2,source)::dae,_,_)
      equation
        (conds_1,_) = replaceExpList(conds, repl, condExpFunc);
        /* TODO: Add operation to source */
        tbs_1 = List.map2(tbs,applyReplacementsDAEElts,repl,condExpFunc);
        elist22 = applyReplacementsDAEElts(elist2,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.INITIAL_IF_EQUATION(conds_1,tbs_1,elist22,source)::dae2;

    case (DAE.INITIALEQUATION(e1,e2,source)::dae,_,_)
      equation
        (e11,_) = replaceExp(e1, repl, condExpFunc);
        (e22,_) = replaceExp(e2, repl, condExpFunc);
        /* TODO: Add operation to source */
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.INITIALEQUATION(e11,e22,source)::dae2;

    case (DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),source)::dae,_,_)
      equation
        (stmts2,_) = replaceEquationsStmts(stmts,repl,condExpFunc);
        /* TODO: Add operation to source */
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts2),source)::dae2;

    case (DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts),source)::dae,_,_)
      equation
        (stmts2,_) = replaceEquationsStmts(stmts,repl,condExpFunc);
        /* TODO: Add operation to source */
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts2),source)::dae2;

    case (DAE.COMP(id,elist,source,cmt)::dae,_,_)
      equation
        _ = applyReplacementsDAEElts(elist,repl,condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.COMP(id,elist,source,cmt)::dae2;

    case ((elt as DAE.EXTOBJECTCLASS(_,_))::dae,_,_)
      equation
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then elt::dae2;

    case (DAE.ASSERT(e1,e2,e3,source)::dae,_,_)
      equation
        (e11,_) = replaceExp(e1, repl, condExpFunc);
        (e22,_) = replaceExp(e2, repl, condExpFunc);
        (e32,_) = replaceExp(e3, repl, condExpFunc);
        /* TODO: Add operation to source */
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.ASSERT(e11,e22,e32,source)::dae2;

    case (DAE.TERMINATE(e1,source)::dae,_,_)
      equation
        (e11,_) = replaceExp(e1, repl, condExpFunc);
        /* TODO: Add operation to source */
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.TERMINATE(e11,source)::dae2;

    case (DAE.REINIT(cr,e1,source)::dae,_,_)
      equation
        (e11,_) = replaceExp(e1, repl, condExpFunc);
        /* TODO: Add operation to source */
        (DAE.CREF(cr2,_),_) = replaceExp(Expression.crefExp(cr), repl, condExpFunc);
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.REINIT(cr2,e11,source)::dae2;

    case (DAE.COMPLEX_EQUATION(e1,e2,source)::dae,_,_)
      equation
        (e11,_) = replaceExp(e1, repl, condExpFunc);
        (e22,_) = replaceExp(e2, repl, condExpFunc);
        /* TODO: Add operation to source */
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.COMPLEX_EQUATION(e11,e22,source)::dae2;

    case (DAE.INITIAL_COMPLEX_EQUATION(e1,e2,source)::dae,_,_)
      equation
        (e11,_) = replaceExp(e1, repl, condExpFunc);
        (e22,_) = replaceExp(e2, repl, condExpFunc);
        /* TODO: Add operation to source */
        dae2 = applyReplacementsDAEElts(dae,repl,condExpFunc);
      then DAE.INITIAL_COMPLEX_EQUATION(e11,e22,source)::dae2;

    // failtrace. adrpo: TODO! FIXME! this SHOULD NOT FAIL!
    case (elt::dae,_,_)
      equation
        // Debug.fprintln(Flags.FAILTRACE, "- VarTransform.applyReplacementsDAEElts could not apply replacements to: " + DAEDump.dumpElementsStr({elt}));
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
  outAttr := match(attr,repl,condExpFunc)
    local
      Option<DAE.Exp> quantity,unit,displayUnit,min,max,initial_,fixed,nominal,startOrigin;
      Option<DAE.StateSelect> stateSelect;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> dist;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case(SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,max,initial_,fixed,nominal,stateSelect,unc,dist,eb,ip,fn,startOrigin)),_,_)
      equation
        (quantity) = replaceExpOpt(quantity,repl,condExpFunc);
        (unit) = replaceExpOpt(unit,repl,condExpFunc);
        (displayUnit) = replaceExpOpt(displayUnit,repl,condExpFunc);
        (min) = replaceExpOpt(min,repl,condExpFunc);
        (max) = replaceExpOpt(max,repl,condExpFunc);
        (initial_) = replaceExpOpt(initial_,repl,condExpFunc);
        (fixed) = replaceExpOpt(fixed,repl,condExpFunc);
        (nominal) = replaceExpOpt(nominal,repl,condExpFunc);
        //TODO: replace expressions also in uncertainty attributes (unc and dist)
      then SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,max,initial_,fixed,nominal,stateSelect,unc,dist,eb,ip,fn,startOrigin));

    case(SOME(DAE.VAR_ATTR_INT(quantity,min,max,initial_,fixed,unc,dist,eb,ip,fn,startOrigin)),_,_)
      equation
        (quantity) = replaceExpOpt(quantity,repl,condExpFunc);
        (min) = replaceExpOpt(min,repl,condExpFunc);
        (max) = replaceExpOpt(max,repl,condExpFunc);
        (initial_) = replaceExpOpt(initial_,repl,condExpFunc);
        (fixed) = replaceExpOpt(fixed,repl,condExpFunc);
      then SOME(DAE.VAR_ATTR_INT(quantity,min,max,initial_,fixed,unc,dist,eb,ip,fn,startOrigin));

      case(SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn,startOrigin)),_,_)
        equation
          (quantity) = replaceExpOpt(quantity,repl,condExpFunc);
          (initial_) = replaceExpOpt(initial_,repl,condExpFunc);
          (fixed) = replaceExpOpt(fixed,repl,condExpFunc);
        then SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn,startOrigin));

      case(SOME(DAE.VAR_ATTR_STRING(quantity,initial_,eb,ip,fn,startOrigin)),_,_)
        equation
          (quantity) = replaceExpOpt(quantity,repl,condExpFunc);
          (initial_) = replaceExpOpt(initial_,repl,condExpFunc);
        then SOME(DAE.VAR_ATTR_STRING(quantity,initial_,eb,ip,fn,startOrigin));

      case (NONE(),_,_) then NONE();
  end match;
end  applyReplacementsVarAttr;

public function applyReplacements "This function takes a VariableReplacements and two component references.
  It applies the replacements to each component reference.
"
  input VariableReplacements inVariableReplacements1;
  input DAE.ComponentRef inComponentRef2;
  input DAE.ComponentRef inComponentRef3;
  output DAE.ComponentRef outComponentRef1;
  output DAE.ComponentRef outComponentRef2;
algorithm
  (outComponentRef1,outComponentRef2):=
  match (inVariableReplacements1,inComponentRef2,inComponentRef3)
    local
      DAE.ComponentRef cr1_1,cr2_1,cr1,cr2;
      VariableReplacements repl;
    case (repl,cr1,cr2)
      equation
        (DAE.CREF(cr1_1,_),_) = replaceExp(Expression.crefExp(cr1), repl,NONE());
        (DAE.CREF(cr2_1,_),_) = replaceExp(Expression.crefExp(cr2), repl,NONE());
      then
        (cr1_1,cr2_1);
  end match;
end applyReplacements;

public function applyReplacementList " Author: BZ, 2008-11

  This function takes a VariableReplacements and a list of component references.
  It applies the replacements to each component reference.
"
  input VariableReplacements repl;
  input list<DAE.ComponentRef> increfs;
  output list<DAE.ComponentRef> ocrefs;
algorithm  (ocrefs):= match (repl,increfs)
    local
      DAE.ComponentRef cr1_1,cr1;
    case(_,{}) then {};
    case (_,cr1::ocrefs)
      equation
        (DAE.CREF(cr1_1,_),_) = replaceExp(Expression.crefExp(cr1), repl,NONE());
        ocrefs = applyReplacementList(repl,ocrefs);
      then
        cr1_1::ocrefs;
  end match;
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
  match (repl,inExp1,inExp2)
    local
      DAE.Exp e1,e2;
      Boolean b1,b2;
    case (_,e1,e2)
      equation
        (e1,_) = replaceExp(e1, repl, NONE());
        (e2,_) = replaceExp(e2, repl, NONE());
        (e1,_) = ExpressionSimplify.simplify1(e1);
        (e2,_) = ExpressionSimplify.simplify1(e2);
      then
        (e1,e2);
  end match;
end applyReplacementsExp;

public function emptyReplacementsArray "create an array of n empty replacements"
  input Integer n;
  output array<VariableReplacements> repl;
algorithm
  repl := listArray(emptyReplacementsArray2(n));
end emptyReplacementsArray;

protected function emptyReplacementsArray2 "help function"
  input Integer n;
  output list<VariableReplacements> replLst;
algorithm
  replLst := matchcontinue(n)
  local VariableReplacements r;
    case 0 then {};
    case _
      equation
        true = n < 0;
        print("Internal error, emptyReplacementsArray2 called with negative n!");
      then fail();
    else
      equation
        true = n > 0;
        r = emptyReplacements();
        replLst = emptyReplacementsArray2(n-1);
      then r::replLst;
  end matchcontinue;
end emptyReplacementsArray2;

public function emptyReplacements "
  Returns an empty set of replacement rules
"
  output VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements:=
  match ()
      local HashTable2.HashTable ht;
        HashTable3.HashTable invHt;
    case ()
      equation
        ht = HashTable2.emptyHashTable();
        invHt = HashTable3.emptyHashTable();
      then
        REPLACEMENTS(ht,invHt);
  end match;
end emptyReplacements;

public function emptyReplacementsSized "
  Returns an empty set of replacement rules, giving a size of hashtables to allocate
"
  input Integer size;
  output VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements:=
  match (size)
      local HashTable2.HashTable ht;
        HashTable3.HashTable invHt;
    case _
      equation
        ht = HashTable2.emptyHashTableSized(size);
        invHt = HashTable3.emptyHashTableSized(size);
      then
        REPLACEMENTS(ht,invHt);
  end match;
end emptyReplacementsSized;

public function replaceEquationsStmts "
  Helper function to replace_equations,
  Handles the replacement of DAE.Statement.
"
  input list<DAE.Statement> inAlgorithmStatementLst;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> condExpFunc;
  output list<DAE.Statement> outAlgorithmStatementLst;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  (outAlgorithmStatementLst,replacementPerformed) :=
  matchcontinue (inAlgorithmStatementLst,repl,condExpFunc)
    local
      DAE.Exp e_1,e_2,e,e1,e2,e3,e_3;
      list<DAE.Exp> expl1,expl2;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Statement> xs_1,xs,stmts,stmts2;
      DAE.Type tp,tt;
      DAE.Statement x;
      Boolean b1,b2,b3;
      String id1;
      DAE.ElementSource source;
      Absyn.Path fnName;
      Option<DAE.Statement> ew,ew_1;
      list<DAE.ComponentRef> conditions;
      Boolean initialCall,iterIsArray;
      DAE.Else el,el_1;
      Integer ix;

    case ({},_,_) then ({},false);
    case ((DAE.STMT_ASSIGN(type_ = tp,exp1 = e2,exp = e,source = source) :: xs),_,_)
      equation
        (e_1,b1) = replaceExp(e, repl, condExpFunc);
        (e_2,b2) = replaceExp(e2, repl, condExpFunc);
        true = b1 or b2;
        /* TODO: Add operation to source; do simplify? */
        (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_ASSIGN(tp,e_2,e_1,source) :: xs_1,true);
    case ((DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl1, exp = e,source = source) :: xs),_,_)
      equation
        (e_1,b1) = replaceExp(e, repl, condExpFunc);
        (expl2,b2) = replaceExpList(expl1, repl, condExpFunc);
        true = b1 or b2;
        /* TODO: Add operation to source; do simplify? */
        (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_TUPLE_ASSIGN(tp,expl2,e_1,source) :: xs_1,true);
    case ((DAE.STMT_ASSIGN_ARR(type_ = tp, lhs = e1, exp = e2, source = source) :: xs),_,_)
      equation
        (e_1,b1) = replaceExp(e1, repl, condExpFunc);
        (e_2,b2) = replaceExp(e2, repl, condExpFunc);
        true = b1 or b2;
        /* TODO: Add operation to source; do simplify? */
        (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_ASSIGN_ARR(tp,e_1,e_2,source) :: xs_1,true);
    // case ((DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e,source = source) :: xs),_,_)
      // equation
        // (e_1,true) = replaceExp(e, repl, condExpFunc);
        // /* TODO: Add operation to source; do simplify? */
        // (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      // then
        // (DAE.STMT_ASSIGN_ARR(tp,cr,e_1,source) :: xs_1,true);
    case (((DAE.STMT_IF(exp=e,statementLst=stmts,else_ = el,source = source)) :: xs),_,_)
      equation
        (el_1,b1) = replaceEquationsElse(el,repl,condExpFunc);
        (stmts2,b2) = replaceEquationsStmts(stmts,repl,condExpFunc);
        (e_1,b3) = replaceExp(e, repl, condExpFunc);
        true = b1 or b2 or b3;
        /* TODO: Add operation to source; do simplify? */
        (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_IF(e_1,stmts2,el_1,source) :: xs_1,true);
    case (((DAE.STMT_FOR(type_=tp,iterIsArray=iterIsArray,iter=id1,index=ix,range=e,statementLst=stmts,source = source)) :: xs),_,_)
      equation
        (stmts2,b1) = replaceEquationsStmts(stmts,repl,condExpFunc);
        (e_1,b2) = replaceExp(e, repl, condExpFunc);
        true = b1 or b2;
        /* TODO: Add operation to source; do simplify? */
        (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_FOR(tp,iterIsArray,id1,ix,e_1,stmts2,source) :: xs_1,true);
    case (((DAE.STMT_WHILE(exp = e,statementLst=stmts,source = source)) :: xs),_,_)
      equation
        (stmts2,b1) = replaceEquationsStmts(stmts,repl,condExpFunc);
        (e_1,b2) = replaceExp(e, repl, condExpFunc);
        true = b1 or b2;
        /* TODO: Add operation to source; do simplify? */
        (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_WHILE(e_1,stmts2,source) :: xs_1,true);
    case (((DAE.STMT_WHEN(exp=e,conditions=conditions,initialCall=initialCall,statementLst=stmts,elseWhen=ew,source=source))::xs),_,_)
      equation
        (ew_1,b1) = replaceOptEquationsStmts(ew,repl,condExpFunc);
        (stmts2,b2) = replaceEquationsStmts(stmts,repl,condExpFunc);
        (e_1,b3) = replaceExp(e, repl, condExpFunc);
        true = b1 or b2 or b3;
        /* TODO: Add operation to source; do simplify? */
        (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_WHEN(e_1,conditions,initialCall,stmts2,ew_1,source)::xs_1, true);
    case (((DAE.STMT_ASSERT(cond=e,msg=e2,level=e3,source=source)) :: xs),_,_)
      equation
        (e_1,b1) = replaceExp(e, repl, condExpFunc);
        (e_2,b2) = replaceExp(e2, repl, condExpFunc);
        (e_3,b3) = replaceExp(e3, repl, condExpFunc);
        true = b1 or b2 or b3;
        /* TODO: Add operation to source; do simplify? */
        (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_ASSERT(e_1,e_2,e_3,source) :: xs_1, true);
    case (((DAE.STMT_TERMINATE(msg = e,source = source)) :: xs),_,_)
      equation
        (e_1,true) = replaceExp(e, repl, condExpFunc);
        /* TODO: Add operation to source; do simplify? */
        (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_TERMINATE(e_1,source) :: xs_1, true);

    case (((DAE.STMT_REINIT(var = e,value=e2,source = source)) :: xs),_,_)
      equation
        (e_1,b1) = replaceExp(e, repl, condExpFunc);
        (e_2,b2) = replaceExp(e2, repl, condExpFunc);
        true = b1 or b2;
        /* TODO: Add operation to source; do simplify? */
        (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_REINIT(e_1,e_2,source) :: xs_1, true);

    case ((DAE.STMT_NORETCALL(exp = e,source = source)) :: xs,_,_)
      equation
        (e_1,true) = replaceExp(e, repl, condExpFunc);
        /* TODO: Add operation to source; do simplify? */
        (xs_1,_) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (DAE.STMT_NORETCALL(e_1,source) :: xs_1, true);

    case ((x :: xs),_,_)
      equation
        (xs_1, b1) = replaceEquationsStmts(xs, repl,condExpFunc);
      then
        (x :: xs_1, b1);
  end matchcontinue;

end replaceEquationsStmts;

protected function replaceEquationsElse "
Helper function for replaceEquationsStmts, replaces DAE.Else"
  input DAE.Else inElse;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> condExpFunc;
  output DAE.Else outElse;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  (outElse,replacementPerformed) := matchcontinue(inElse,repl,condExpFunc)
    local
      DAE.Exp e,e_1;
      list<DAE.Statement> st,st_1;
      DAE.Else el,el_1;
      Boolean b1,b2,b3;
    case(DAE.ELSEIF(e,st,el),_,_)
      equation
        (el_1,b1) = replaceEquationsElse(el,repl,condExpFunc);
        (st_1,b2) = replaceEquationsStmts(st,repl,condExpFunc);
        (e_1,b3) = replaceExp(e, repl, condExpFunc);
        true = b1 or b2 or b3;
      then (DAE.ELSEIF(e_1,st_1,el_1),true);
    case(DAE.ELSE(st),_,_)
      equation
        (st_1,true) = replaceEquationsStmts(st,repl,condExpFunc);
      then (DAE.ELSE(st_1),true);
    else (inElse,false);
  end matchcontinue;
end replaceEquationsElse;

protected function replaceOptEquationsStmts "
Helper function for replaceEquationsStmts, replaces optional statement"
  input Option<DAE.Statement> optStmt;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> condExpFunc;
  output Option<DAE.Statement> outAlgorithmStatementLst;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  (outAlgorithmStatementLst,replacementPerformed) := matchcontinue(optStmt,inVariableReplacements,condExpFunc)
    local
      DAE.Statement stmt,stmt2;
    case(SOME(stmt),_,_)
      equation
        ({stmt2},true) = replaceEquationsStmts({stmt},inVariableReplacements,condExpFunc);
      then (SOME(stmt2),true);
    else (optStmt,false);
  end matchcontinue;
end replaceOptEquationsStmts;

public function dumpReplacements
"Prints the variable replacements on form var1 -> var2"
  input VariableReplacements inVariableReplacements;
algorithm
  _:=
  match (inVariableReplacements)
    local
      String str,len_str;
      Integer len;
      HashTable2.HashTable ht;
      list<tuple<DAE.ComponentRef,DAE.Exp>> tplLst;
    case (REPLACEMENTS(hashTable= ht))
      equation
        (tplLst) = BaseHashTable.hashTableList(ht);
        str = stringDelimitList(List.map(tplLst,printReplacementTupleStr),"\n");
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
  end match;
end dumpReplacements;

public function dumpReplacementsStr "
Author BZ 2009-04
Function for dumping replacements to string.
"
  input VariableReplacements inVariableReplacements;
  output String ostr;
algorithm ostr := match (inVariableReplacements)
    local
      list<DAE.Exp> srcs,dsts;
      list<String> srcstrs,dststrs,dststrs_1,strs;
      String str,len_str,s1;
      Integer len;
      HashTable2.HashTable ht;
      list<tuple<DAE.ComponentRef,DAE.Exp>> tplLst;
    case (REPLACEMENTS(hashTable = ht))
      equation
        (tplLst) = BaseHashTable.hashTableList(ht);
        str = stringDelimitList(List.map(tplLst,printReplacementTupleStr),"\n");
        s1 = "Replacements: (" + intString(listLength(tplLst)) + ")\n=============\n" + str + "\n";
      then
        s1;
  end match;
end dumpReplacementsStr;

public function getAllReplacements "
Author BZ 2009-04
Extract all crefs -> exp to two separate lists.
"
input VariableReplacements inVariableReplacements;
output list<DAE.ComponentRef> crefs;
output list<DAE.Exp> dsts;
algorithm (crefs,dsts) := match (inVariableReplacements)
    local
      HashTable2.HashTable ht;
      list<tuple<DAE.ComponentRef,DAE.Exp>> tplLst;
    case (REPLACEMENTS(hashTable = ht))
      equation
        tplLst = BaseHashTable.hashTableList(ht);
        crefs = List.map(tplLst,Util.tuple21);
        dsts = List.map(tplLst,Util.tuple22);
      then
        (crefs,dsts);
  end match;
end getAllReplacements;

protected function printReplacementTupleStr "help function to dumpReplacements"
  input tuple<DAE.ComponentRef,DAE.Exp> tpl;
  output String str;
algorithm
  // optional exteded type debugging
  //str := ComponentReference.debugPrintComponentRefTypeStr(Util.tuple21(tpl)) + " -> " + ExpressionDump.debugPrintComponentRefExp(Util.tuple22(tpl));
  // Normal debugging, without type&dimension information on crefs.
  str := ComponentReference.printComponentRefStr(Util.tuple21(tpl)) + " -> " + ExpressionDump.printExpStr(Util.tuple22(tpl));
end printReplacementTupleStr;

public function replacementSources "Returns all sources of the replacement rules"
  input VariableReplacements repl;
  output list<DAE.ComponentRef> sources;
algorithm
  sources := match(repl)
  local list<DAE.Exp> srcs;
    HashTable2.HashTable ht;
    case (REPLACEMENTS(ht,_))
      equation
          sources = BaseHashTable.hashTableKeyList(ht);
      then sources;
  end match;
end replacementSources;

public function replacementTargets "Returns all targets of the replacement rules"
  input VariableReplacements repl;
  output list<DAE.ComponentRef> sources;
algorithm
  sources := match(repl)
    local
      list<DAE.Exp> targets;
      list<DAE.ComponentRef> targets2;
      HashTable2.HashTable ht;

    case (REPLACEMENTS(ht,_))
      equation
        targets = BaseHashTable.hashTableValueList(ht);
        targets2 = List.flatten(List.map(targets,Expression.extractCrefsFromExp));
      then
        targets2;
  end match;
end replacementTargets;

public function addReplacementLst " adds several replacements given by list of crefs and list of expressions by repeatedly calling addReplacement"
  input VariableReplacements inRepl;
  input list<DAE.ComponentRef> crs;
  input list<DAE.Exp> dsts;
  output VariableReplacements repl;
algorithm
  repl := match (inRepl,crs,dsts)
    local
      DAE.ComponentRef cr;
      DAE.Exp dst;
      list<DAE.ComponentRef> crrest;
      list<DAE.Exp> dstrest;

    case (repl,{},{}) then repl;
    case (repl,cr::crrest,dst::dstrest) equation
      repl = addReplacement(repl,cr,dst);
      repl = addReplacementLst(repl,crrest,dstrest);
    then repl;
  end match;
end addReplacementLst;

public function addReplacement "
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
      DAE.ComponentRef src,src_1;
      DAE.Exp dst,dst_1;
      HashTable2.HashTable ht,ht_1;
      HashTable3.HashTable invHt,invHt_1;
    // PA: Commented out this, since it will only slow things down without adding any functionality.
    // Once match is available as a complement to matchcontinue, this case could be useful again.
    //case ((repl as REPLACEMENTS(ht,invHt)),src,dst) /* source dest */
     // equation
     //   olddst = BaseHashTable.get(src, ht) "if rule a->b exists, fail" ;
     // then
     //   fail();

    case ((REPLACEMENTS(_,_)),src,dst)
      equation
        (REPLACEMENTS(ht,invHt),src_1,dst_1) = makeTransitive(repl, src, dst);
        /*s1 = ComponentReference.printComponentRefStr(src);
        s2 = ExpressionDump.printExpStr(dst);
        s3 = ComponentReference.printComponentRefStr(src_1);
        s4 = ExpressionDump.printExpStr(dst_1);
        s = stringAppendList(
          {"add_replacement(",s1,", ",s2,") -> add_replacement(",s3,
          ", ",s4,")\n"});
          print(s);
        Debug.fprint(Flags.ADD_REPL, s);*/
        ht_1 = BaseHashTable.add((src_1, dst_1),ht);
        invHt_1 = addReplacementInv(invHt, src_1, dst_1);
      then
        REPLACEMENTS(ht_1,invHt_1);
    else
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
  input DAE.ComponentRef src;
  input DAE.Exp dst;
  output VariableReplacements outRepl = repl;
protected
  HashTable2.HashTable ht;
  HashTable3.HashTable invHt;
algorithm
  REPLACEMENTS(ht,invHt) := outRepl;
  if BaseHashTable.hasKey(src, ht) then // TODO: Is this correct? Previously, we skipped this code which was a dead case
    return;
  end if;
  ht := BaseHashTable.add((src, dst), ht);
  invHt := addReplacementInv(invHt, src, dst);
  outRepl := REPLACEMENTS(ht,invHt);
end addReplacementNoTransitive;

protected function addReplacementInv "
  Helper function to addReplacement
  Adds the inverse rule of a replacement to the second binary tree
  of VariableReplacements.
"
  input HashTable3.HashTable invHt;
  input DAE.ComponentRef src;
  input DAE.Exp dst;
  output HashTable3.HashTable outInvHt;
algorithm
  outInvHt:=
  match (invHt,src,dst)
    local
      HashTable3.HashTable invHt_1;
      list<DAE.ComponentRef> dests;
    case (_,_,_) equation
      dests = Expression.extractCrefsFromExp(dst);
      invHt_1 = List.fold1r(dests,addReplacementInv2,src,invHt);
      then
        invHt_1;
  end match;
end addReplacementInv;

protected function addReplacementInv2 "
  Helper function to addReplacementInv
  Adds the inverse rule for one of the variables of a replacement to the second binary tree
  of VariableReplacements.
  Since a replacement is on the form var -> expression of vars(v1,v2,...,vn) the inverse binary tree
  contains rules for v1 -> var, v2 -> var, ...., vn -> var so that any of the variables of the expression
  will update the rule.
"
  input HashTable3.HashTable invHt;
  input DAE.ComponentRef dst;
  input DAE.ComponentRef src;
  output HashTable3.HashTable outInvHt;
algorithm
  outInvHt:=
  matchcontinue (invHt,dst,src)
    local
      HashTable3.HashTable invHt_1;
      list<DAE.ComponentRef> srcs;
    case (_,_,_)
      equation
        failure(_ = BaseHashTable.get(dst,invHt)) "No previous elt for dst -> src" ;
        invHt_1 = BaseHashTable.add((dst, {src}),invHt);
      then
        invHt_1;
    case (_,_,_)
      equation
        srcs = BaseHashTable.get(dst,invHt) "previous elt for dst -> src, append.." ;
        srcs = amortizeUnion(src::srcs);//List.union({},src::srcs);
        invHt_1 = BaseHashTable.add((dst, srcs),invHt);
      then
        invHt_1;
  end matchcontinue;
end addReplacementInv2;

protected function amortizeUnion "performs listUnion but in an 'amortized' way, by only doing it occasionally"
  input list<DAE.ComponentRef> inCrefs;
  output list<DAE.ComponentRef> crefs;
algorithm
  crefs := match(inCrefs)
    case(_) guard intMod(listLength(inCrefs),7)==0 // Experiments performed on different values: {{5, 102}, {6, 99}, {7, 98.8}, {8, 101}, {10, 101}, 20, 104}}
      then List.union({},inCrefs);
    else inCrefs;
  end match;
end amortizeUnion;

public function addReplacementIfNot "Calls addReplacement() if condition (first argument) is false,
  otherwise does nothing.

  Author: asodja, 2010-03-03
"
  input Boolean condition;
  input VariableReplacements repl;
  input DAE.ComponentRef inSrc;
  input DAE.Exp inDst;
  output VariableReplacements outRepl;
algorithm
  outRepl:=  match (condition,repl,inSrc,inDst)
    local
      DAE.ComponentRef src;
      DAE.Exp dst;
      VariableReplacements repl_1;
    case (false,_,src,dst) /* source dest */
      equation
        repl_1 = addReplacement(repl,src,dst);
      then repl_1;
    case (true,_,_,_)
      then repl;
  end match;
end addReplacementIfNot;

protected function makeTransitive "
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
  match (repl,src,dst)
    local
      VariableReplacements repl_1,repl_2;
      DAE.ComponentRef src_1,src_2;
      DAE.Exp dst_1,dst_2,dst_3;

    case (_,_,_)
      equation
        (repl_1,src_1,dst_1) = makeTransitive1(repl, src, dst);
        (repl_2,src_2,dst_2) = makeTransitive2(repl_1, src_1, dst_1);
        (dst_3,_) = ExpressionSimplify.simplify1(dst_2) "to remove e.g. --a";
      then
        (repl_2,src_2,dst_3);
  end match;
end makeTransitive;

protected function makeTransitive1 "
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
      VariableReplacements repl_1,singleRepl;
      HashTable2.HashTable ht;
      HashTable3.HashTable invHt;
      // old rule a->expr(b1,..,bn) must be updated to a->expr(c_exp,...,bn) when new rule b1->c_exp
      // is introduced
    case ((REPLACEMENTS(_,invHt)),_,_)
      equation
        lst = BaseHashTable.get(src, invHt);
        singleRepl = addReplacementNoTransitive(emptyReplacementsSized(53),src,dst);
        repl_1 = makeTransitive12(lst,repl,singleRepl);
      then
        (repl_1,src,dst);
    else (repl,src,dst);
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
  outRepl := match(lst,repl,singleRepl)
    local
      DAE.Exp crDst;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crs;
      VariableReplacements repl1,repl2;
      HashTable2.HashTable ht;
    case({},_,_) then repl;
    case(cr::crs,REPLACEMENTS(hashTable=ht),_)
      equation
        crDst = BaseHashTable.get(cr,ht);
        (crDst,_) = replaceExp(crDst,singleRepl,NONE());
        repl1 = addReplacementNoTransitive(repl,cr,crDst) "add updated old rule";
        repl2 = makeTransitive12(crs,repl1,singleRepl);
      then repl2;
  end match;
end makeTransitive12;

protected function makeTransitive2 "
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
      DAE.Exp dst_1;
      // for rule a->b1+..+bn, replace all b1 to bn's in the expression;
    case (_,_,_)
      equation
        (dst_1,_) = replaceExp(dst,repl,NONE());
      then
        (repl,src,dst_1);
        // replace Exp failed, keep old rule.
    else (repl,src,dst);  /* dst has no own replacement, return */
  end matchcontinue;
end makeTransitive2;

public function getReplacement "
  Retrives a replacement variable given a set of replacement rules and a
  source variable.
"
  input VariableReplacements inVariableReplacements;
  input DAE.ComponentRef inComponentRef;
  output DAE.Exp outComponentRef;
algorithm
  outComponentRef:=
  match (inVariableReplacements,inComponentRef)
    local
      DAE.ComponentRef src;
      DAE.Exp dst;
      HashTable2.HashTable ht;
    case (REPLACEMENTS(hashTable=ht),src)
      equation
        dst = BaseHashTable.get(src,ht);
      then
        dst;
  end match;
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
  outExp := match (inExp,repl,funcOpt)
  local DAE.Exp e;
    case(SOME(e),_,_)
      equation
        /* TODO: Propagate this boolean? */
        (e,_) = replaceExp(e,repl,funcOpt);
      then SOME(e);
    else NONE();
  end match;
end replaceExpOpt;

public function avoidDoubleHashLookup "
Author BZ 200X-XX modified 2008-06
When adding replacement rules, we might not have the correct type availible at the moment.
Then DAE.T_UNKNOWN_DEFAULT is used, so when replacing exp and finding DAE.T_UNKNOWN(_), we use the
type of the expression to be replaced instead.
TODO: find out why array residual functions containing arrays as xloc[] does not work,
      doing that will allow us to use this function for all crefs."
  input DAE.Exp inExp;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm  outExp := matchcontinue(inExp,inType)
  local DAE.ComponentRef cr;
  case(DAE.CREF(cr,DAE.T_UNKNOWN()),_) then Expression.makeCrefExp(cr,inType);
  else inExp;
  end matchcontinue;
end avoidDoubleHashLookup;

public function replaceExpRepeated "similar to replaceExp but repeats the replacements until expression no longer changes.
Note: This is only required/useful if replacements are built with addReplacementNoTransitive."
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

public function replaceExpRepeated2 "help function to replaceExpRepeated"
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
    local
      DAE.Exp e1,res;
      Boolean b;
    case (_,_,_,_,_,_)
      equation
        true = i > maxIter;
      then e;
    case (_,_,_,_,_,true) then e;
    else
      equation
        (e1,b) = replaceExp(e,repl,func);
        res = replaceExpRepeated2(e1,repl,func,maxIter,i+1,not b /*Expression.expEqual(e,e1)*/);
      then res;
  end matchcontinue;
end replaceExpRepeated2;

public function replaceExp "
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
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  (outExp,replacementPerformed) :=
  matchcontinue (inExp,inVariableReplacements,inFuncTypeExpExpToBooleanOption)
    local
      DAE.ComponentRef cr;
      DAE.Exp e,e_1,e1_1,e2_1,e1,e2,e3_1,e3;
      DAE.Type t,tp,ety;
      VariableReplacements repl;
      Option<FuncTypeExp_ExpToBoolean> cond;
      DAE.Operator op;
      list<DAE.Exp> expl_1,expl;
      Absyn.Path path;
      Boolean c,c1,c2,c3;
      Integer b;
      Absyn.CodeNode a;
      list<list<DAE.Exp>> bexpl_1,bexpl;
      Integer index_;
      Option<tuple<DAE.Exp,Integer,Integer>> isExpisASUB;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators iters;
      DAE.CallAttributes attr;

      // Note: Most of these functions check if a subexpression did a replacement.
      // If it did not, we do not create a new copy of the expression (to save some memory).

    case ((DAE.CREF(componentRef = cr,ty = t)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        e1 = getReplacement(repl, cr);
        e2 = avoidDoubleHashLookup(e1,t);
      then
        (e2,true);
    case ((DAE.BINARY(exp1 = e1,operator = op,exp2 = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        true = c1 or c2;
      then
        (DAE.BINARY(e1_1,op,e2_1),true);
    case ((DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        true = c1 or c2;
      then
        (DAE.LBINARY(e1_1,op,e2_1),true);
    case ((DAE.UNARY(operator = op,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,true) = replaceExp(e1, repl, cond);
      then
        (DAE.UNARY(op,e1_1),true);
    case ((DAE.LUNARY(operator = op,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,true) = replaceExp(e1, repl, cond);
      then
        (DAE.LUNARY(op,e1_1),true);
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2, index=index_, optionExpisASUB= isExpisASUB),repl,cond)
      equation
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        true = c1 or c2;
      then
        (DAE.RELATION(e1_1,op,e2_1,index_,isExpisASUB),true);
    case ((DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        (e3_1,c3) = replaceExp(e3, repl, cond);
        true = c1 or c2 or c3;
      then
        (DAE.IFEXP(e1_1,e2_1,e3_1),true);
      /* Special case when a variable in pre() is an alias for unary minus of another */
    case (DAE.CALL(path = path as Absyn.IDENT("pre"),expLst = {e as DAE.CREF()},attr=attr),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (DAE.UNARY(DAE.UMINUS(ety),e_1),true) = replaceExp(e, repl, cond);
      then
        (DAE.UNARY(DAE.UMINUS(ety),DAE.CALL(path,{e_1},attr)),true);
    case ((e as DAE.CALL(path = path,expLst = expl,attr=attr)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (expl_1,true) = replaceExpList(expl, repl, cond);
      then
        (DAE.CALL(path,expl_1,attr),true);
    case ((DAE.ARRAY(ty = tp,scalar = c,array = expl)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (expl_1,true) = replaceExpList(expl, repl, cond);
      then
        (DAE.ARRAY(tp,c,expl_1),true);
    case ((DAE.MATRIX(ty = t,integer = b,matrix = bexpl)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (bexpl_1,true) = replaceExpMatrix(bexpl, repl, cond);
      then
        (DAE.MATRIX(t,b,bexpl_1),true);
    case ((DAE.RANGE(ty = tp,start = e1,step = NONE(),stop = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        true = c1 or c2;
      then
        (DAE.RANGE(tp,e1_1,NONE(),e2_1),true);
    case ((DAE.RANGE(ty = tp,start = e1,step = SOME(e3),stop = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        (e3_1,c3) = replaceExp(e3, repl, cond);
        true = c1 or c2 or c3;
      then
        (DAE.RANGE(tp,e1_1,SOME(e3_1),e2_1),true);
    case ((DAE.TUPLE(PR = expl)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (expl_1,true) = replaceExpList(expl, repl, cond);
      then
        (DAE.TUPLE(expl_1),true);
    case ((DAE.CAST(ty = tp,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,true) = replaceExp(e1, repl, cond);
      then
        (DAE.CAST(tp,e1_1),true);
    case ((DAE.ASUB(exp = e1,sub = expl)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (expl_1,c2) = replaceExpList(expl, repl, cond);
        true = c1 or c2;
      then
        (Expression.makeASUB(e1_1,expl_1),true);
    case ((DAE.SIZE(exp = e1,sz = NONE())),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,true) = replaceExp(e1, repl, cond);
      then
        (DAE.SIZE(e1_1,NONE()),true);
    case ((DAE.SIZE(exp = e1,sz = SOME(e2))),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        true = c1 or c2;
      then
        (DAE.SIZE(e1_1,SOME(e2_1)),true);
    case (DAE.CODE(code = a,ty = tp),_,_)
      equation
        print("replace_exp on CODE not impl.\n");
      then
        (DAE.CODE(a,tp),false);
    case ((DAE.REDUCTION(reductionInfo = reductionInfo,expr = e1,iterators = iters)),repl,cond)
      equation
        true = replaceExpCond(cond, inExp);
        (e1_1,_) = replaceExp(e1, repl, cond);
        (iters,true) = replaceExpIters(iters, repl, cond);
      then (DAE.REDUCTION(reductionInfo,e1_1,iters),true);
    case (e,_,_)
      then (e,false);
  end matchcontinue;
end replaceExp;

public function replaceExpList
  input list<DAE.Exp> iexpl;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> cond;
  output list<DAE.Exp> outExpl;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
protected
  list<DAE.Exp> acc1 = {};
  Boolean acc2 = false;
  Boolean c;
algorithm
  for exp in iexpl loop
    (exp,c) := replaceExp(exp,repl,cond);
    acc2 := acc2 or c;
    acc1 := exp::acc1;
  end for;
  outExpl := listReverseInPlace(acc1);
  replacementPerformed := acc2;
end replaceExpList;

protected function replaceExpIters
  input list<DAE.ReductionIterator> inIters;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> cond;
  output list<DAE.ReductionIterator> outIter;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
protected
  list<DAE.ReductionIterator> acc1 = {};
  Boolean acc2 = false;
algorithm
  for iter in inIters loop
    _ := match (iter)
      local
        String id;
        DAE.Exp exp,gexp;
        DAE.Type ty;
        Boolean b1,b2;
      case (DAE.REDUCTIONITER(id,exp,NONE(),ty))
        equation
          (exp,b1) = replaceExp(exp, repl, cond);
          if b1 then
            acc1 = DAE.REDUCTIONITER(id,exp,NONE(),ty)::acc1;
            acc2 = true;
          else
            acc1 = iter::acc1;
          end if;
        then ();
      case (DAE.REDUCTIONITER(id,exp,SOME(gexp),ty))
        equation
          (exp,b1) = replaceExp(exp, repl, cond);
          (gexp,b2) = replaceExp(gexp, repl, cond);
          if b1 or b2 then
            acc1 = DAE.REDUCTIONITER(id,exp,SOME(gexp),ty)::acc1;
            acc2 = true;
          else
            acc1 = iter::acc1;
          end if;
        then ();
      else
        equation
          acc1 = iter::acc1;
        then ();
    end match;
  end for;
  outIter := listReverseInPlace(acc1);
  replacementPerformed := acc2;
end replaceExpIters;

protected function replaceExpCond "function replaceExpCond(cond,e) => true &

  Helper function to replace_Expression. Evaluates a condition function if
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
  match (inFuncTypeExpExpToBooleanOption,inExp)
    local
      Boolean res;
      FuncTypeExp_ExpToBoolean cond;
      DAE.Exp e;
    case (SOME(cond),e) /* cond e */
      equation
        res = cond(e);
      then
        res;
    else true;
  end match;
end replaceExpCond;

protected function replaceExpMatrix "author: PA
  Helper function to replaceExp, traverses Matrix expression list."
  input list<list<DAE.Exp>> inTplExpExpBooleanLstLst;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
  output list<list<DAE.Exp>> outTplExpExpBooleanLstLst;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
protected
  list<list<DAE.Exp>> acc1 = {};
  Boolean acc2 = false;
  Boolean c;
algorithm
  for exp in inTplExpExpBooleanLstLst loop
    (exp,c) := replaceExpList(exp, inVariableReplacements, inFuncTypeExpExpToBooleanOption);
    acc2 := acc2 or c;
    acc1 := exp::acc1;
  end for;
  outTplExpExpBooleanLstLst := listReverseInPlace(acc1);
  replacementPerformed := acc2;
end replaceExpMatrix;

protected function bintreeToExplist2 "helper function to bintree_to_list"
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
      DAE.Exp value,crefExp;
      Option<BinTree> left,right;

    case (TREENODE(value = NONE(),left = NONE(),right = NONE()),klst,vlst) then (klst,vlst);
    case (TREENODE(value = SOME(TREEVALUE(key,value)),left = left,right = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToExplistOpt(left, klst, vlst);
        (klst,vlst) = bintreeToExplistOpt(right, klst, vlst);
        crefExp = Expression.crefExp(key);
      then
        ((crefExp :: klst),(value :: vlst));

    case (TREENODE(value = NONE(),left = left),klst,vlst)
      equation
        (klst,vlst) = bintreeToExplistOpt(left, klst, vlst);
        (klst,vlst) = bintreeToExplistOpt(left, klst, vlst);
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToExplist2;

protected function bintreeToExplistOpt "helper function to bintree_to_list"
  input Option<BinTree> inBinTreeOption1;
  input list<DAE.Exp> inExpExpLst2;
  input list<DAE.Exp> inExpExpLst3;
  output list<DAE.Exp> outExpExpLst1;
  output list<DAE.Exp> outExpExpLst2;
algorithm
  (outExpExpLst1,outExpExpLst2):=
  match (inBinTreeOption1,inExpExpLst2,inExpExpLst3)
    local
      list<DAE.Exp> klst,vlst;
      BinTree bt;
    case (SOME(bt),klst,vlst)
      equation
        (klst,vlst) = bintreeToExplist2(bt, klst, vlst);
      then
        (klst,vlst);
    else then (inExpExpLst2,inExpExpLst3);
  end match;
end bintreeToExplistOpt;

annotation(__OpenModelica_Interface="frontend");
end VarTransform;
