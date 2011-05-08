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

encapsulated package BackendVarTransform
" file:         BackendVarTransform.mo
  package:     BackendVarTransform
  description: BackendVarTransform contains a Binary Tree representation of variable replacements.

  RCS: $Id$

  This module contain a Binary tree representation of variable replacements
  along with some functions for performing replacements of variables in equations"

public import BackendDAE;
public import DAE;
public import HashTable2;
public import HashTable3;
public import Values;

protected import Absyn;
protected import BaseHashTable;
protected import BackendDAEUtil;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Util;

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
    HashTable2.HashTable extendhashTable "src -> noting, used for extend arrays and records.";
  end REPLACEMENTS;

end VariableReplacements;

public function emptyReplacements "function: emptyReplacements

  Returns an empty set of replacement rules
"
  output VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements:=
  match ()
      local HashTable2.HashTable ht,eht;
        HashTable3.HashTable invHt;
    case ()
      equation
        ht = HashTable2.emptyHashTable();
        eht = HashTable2.emptyHashTable();
        invHt = HashTable3.emptyHashTable();
      then
        REPLACEMENTS(ht,invHt,eht);
  end match;
end emptyReplacements;

public function emptyReplacementsSized "function: emptyReplacements
  Returns an empty set of replacement rules, giving a size of hashtables to allocate"
  input Integer size;
  output VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements := match (size)
      local HashTable2.HashTable ht,eht;
        HashTable3.HashTable invHt;
    case (size)
      equation
        ht = HashTable2.emptyHashTableSized(size);
        invHt = HashTable3.emptyHashTableSized(size);
        eht = HashTable2.emptyHashTableSized(size);
      then
        REPLACEMENTS(ht,invHt,eht);
  end match;
end emptyReplacementsSized;

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
      DAE.ComponentRef src,src_1;
      DAE.Exp dst,dst_1;
      HashTable2.HashTable ht,ht_1,eht,eht_1;
      HashTable3.HashTable invHt,invHt_1;
    // PA: Commented out this, since it will only slow things down without adding any functionality.
    // Once match is available as a complement to matchcontinue, this case could be useful again.
    //case ((repl as REPLACEMENTS(ht,invHt)),src,dst) /* source dest */
     // equation
     //   olddst = BaseHashTable.get(src, ht) "if rule a->b exists, fail" ;
     // then
     //   fail();
     
    case ((repl as REPLACEMENTS(ht,invHt,eht)),src,dst)
      equation        
        (REPLACEMENTS(ht,invHt,eht),src_1,dst_1) = makeTransitive(repl, src, dst);
        /*s1 = ComponentReference.printComponentRefStr(src);
        s2 = ExpressionDump.printExpStr(dst);
        s3 = ComponentReference.printComponentRefStr(src_1);
        s4 = ExpressionDump.printExpStr(dst_1);
        s = stringAppendList(
          {"add_replacement(",s1,", ",s2,") -> add_replacement(",s3,
          ", ",s4,")\n"});
          print(s);
        Debug.fprint("addrepl", s);*/
        ht_1 = BaseHashTable.add((src_1, dst_1),ht);
        invHt_1 = addReplacementInv(invHt, src_1, dst_1);
        eht_1 = addExtendReplacement(eht,src_1,NONE());
      then
        REPLACEMENTS(ht_1,invHt_1,eht_1);
    case (_,_,_)
      equation
        print("-add_replacement failed\n");
      then
        fail();
  end matchcontinue;
end addReplacement;

protected function addReplacementNoTransitive "Similar to addReplacement but
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
      DAE.ComponentRef src;
      DAE.Exp dst,olddst;
      HashTable2.HashTable ht,ht_1,eht,eht_1;
      HashTable3.HashTable invHt,invHt_1;
    case ((repl as REPLACEMENTS(ht,invHt,eht)),src,dst) /* source dest */
      equation
        olddst = BaseHashTable.get(src,ht) "if rule a->b exists, fail" ;
      then
        fail();
    case ((repl as REPLACEMENTS(ht,invHt,eht)),src,dst)
      equation
        ht_1 = BaseHashTable.add((src, dst),ht);
        invHt_1 = addReplacementInv(invHt, src, dst);
        eht_1 = addExtendReplacement(eht,src,NONE());
      then
        REPLACEMENTS(ht_1,invHt_1,eht_1);
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
    case (invHt,src,dst) equation
      dests = Expression.extractCrefsFromExp(dst);
      invHt_1 = Util.listFold_2(dests,addReplacementInv2,invHt,src);
      then
        invHt_1;
  end match;
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
      HashTable3.HashTable invHt_1;
      list<DAE.ComponentRef> srcs;
    case (invHt,src,dst)
      equation
        failure(_ = BaseHashTable.get(dst,invHt)) "No previous elt for dst -> src" ;
        invHt_1 = BaseHashTable.add((dst, {src}),invHt);
      then
        invHt_1;
    case (invHt,src,dst)
      equation
        srcs = BaseHashTable.get(dst,invHt) "previous elt for dst -> src, append.." ;
        srcs = Util.listUnion({},src::srcs);
        invHt_1 = BaseHashTable.add((dst, srcs),invHt);
      then
        invHt_1;
  end matchcontinue;
end addReplacementInv2;

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
  match (repl,src,dst)
    local
      VariableReplacements repl_1,repl_2;
      DAE.ComponentRef src_1,src_2;
      DAE.Exp dst_1,dst_2,dst_3;
      
    case (repl,src,dst)
      equation
        (repl_1,src_1,dst_1) = makeTransitive1(repl, src, dst);
        (repl_2,src_2,dst_2) = makeTransitive2(repl_1, src_1, dst_1);
        (dst_3,_) = ExpressionSimplify.simplify1(dst_2) "to remove e.g. --a";
      then
        (repl_2,src_2,dst_3);
  end match;
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
      VariableReplacements repl_1,singleRepl;
      HashTable2.HashTable ht,eht;
      HashTable3.HashTable invHt;
      // old rule a->expr(b1,..,bn) must be updated to a->expr(c_exp,...,bn) when new rule b1->c_exp
      // is introduced
    case ((repl as REPLACEMENTS(ht,invHt,eht)),src,dst)
      equation
        lst = BaseHashTable.get(src, invHt);
        singleRepl = addReplacementNoTransitive(emptyReplacementsSized(53),src,dst);
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
  outRepl := match(lst,repl,singleRepl)
    local
      DAE.Exp crDst;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crs;
      VariableReplacements repl1,repl2;
      HashTable2.HashTable ht;
    case({},repl,_) then repl;
    case(cr::crs,repl as REPLACEMENTS(hashTable=ht),singleRepl)
      equation
        crDst = BaseHashTable.get(cr,ht);
        (crDst,_) = replaceExp(crDst,singleRepl,NONE());
        repl1 = addReplacementNoTransitive(repl,cr,crDst) "add updated old rule";
        repl2 = makeTransitive12(crs,repl1,singleRepl);
      then repl2;
  end match;
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
      DAE.Exp dst_1;
      // for rule a->b1+..+bn, replace all b1 to bn's in the expression;
    case (repl ,src,dst)
      equation
        (dst_1,_) = replaceExp(dst,repl,NONE());
      then
        (repl,src,dst_1);
        // replace Exp failed, keep old rule.
    case (repl,src,dst) then (repl,src,dst);  /* dst has no own replacement, return */
  end matchcontinue;
end makeTransitive2;

protected function addExtendReplacement
"function: addExtendReplacement
  author: Frenkel TUD 2011-04
  checks if the parents of cref from type array or record
  and add a rule to extend them."
  input HashTable2.HashTable extendrepl;
  input DAE.ComponentRef cr;
  input Option<DAE.ComponentRef> preCr;
  output HashTable2.HashTable outExtendrepl;
algorithm
  outExtendrepl:=
  matchcontinue (extendrepl,cr,preCr)
    local
      HashTable2.HashTable erepl,erepl1;
      DAE.ComponentRef cr,subcr,precr,precr1,pcr,precrn,precrn1;
      DAE.Ident ident;
      DAE.ExpType ty;
      list<DAE.Subscript> subscriptLst;
    case (extendrepl,cr as DAE.CREF_IDENT(ident=ident,identType=ty as DAE.ET_ARRAY(ty=_),subscriptLst=subscriptLst),NONE())
      equation
        precr = ComponentReference.makeCrefIdent(ident,ty,{});
        failure(_ = BaseHashTable.get(precr,extendrepl));
        // update Replacements
        erepl = BaseHashTable.add((precr, DAE.RCONST(0.0)),extendrepl);
      then erepl;
    case (extendrepl,cr as DAE.CREF_IDENT(ident=ident,identType=ty as DAE.ET_ARRAY(ty=_),subscriptLst=subscriptLst),SOME(pcr))
      equation
        precr = ComponentReference.makeCrefIdent(ident,ty,{});
        precr1 = ComponentReference.joinCrefs(pcr,precr);
        failure(_ = BaseHashTable.get(precr1,extendrepl));
        // update Replacements
        erepl = BaseHashTable.add((precr1, DAE.RCONST(0.0)),extendrepl);
      then erepl;
    case (extendrepl,cr as DAE.CREF_IDENT(ident=ident,identType=ty as DAE.ET_COMPLEX(complexClassType=ClassInf.RECORD(_)),subscriptLst=subscriptLst),NONE())
      equation
        failure(_ = BaseHashTable.get(cr,extendrepl));
        // update Replacements
        erepl = BaseHashTable.add((cr, DAE.RCONST(0.0)),extendrepl);
      then erepl;
    case (extendrepl,cr as DAE.CREF_IDENT(ident=ident,identType=ty as DAE.ET_COMPLEX(complexClassType=ClassInf.RECORD(_)),subscriptLst=subscriptLst),SOME(pcr))
      equation
        precr1 = ComponentReference.joinCrefs(pcr,cr);
        failure(_ = BaseHashTable.get(precr1,extendrepl));
        // update Replacements
        erepl = BaseHashTable.add((precr1, DAE.RCONST(0.0)),extendrepl);
      then erepl;        
    case (extendrepl,DAE.CREF_IDENT(ident=_),_) then extendrepl;
    case (extendrepl,cr as DAE.CREF_QUAL(ident=ident,identType=ty as DAE.ET_ARRAY(ty=_),subscriptLst=subscriptLst,componentRef=subcr),NONE())
      equation
        precr = ComponentReference.makeCrefIdent(ident,ty,{});
        failure(_ = BaseHashTable.get(precr,extendrepl));
        // update Replacements
        erepl = BaseHashTable.add((precr, DAE.RCONST(0.0)),extendrepl);
        precrn = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        erepl1 = addExtendReplacement(erepl,subcr,SOME(precrn));
      then erepl1;
    case (extendrepl,cr as DAE.CREF_QUAL(ident=ident,identType=ty as DAE.ET_COMPLEX(complexClassType=ClassInf.RECORD(_)),subscriptLst=subscriptLst,componentRef=subcr),NONE())
      equation
        precr = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        failure(_ = BaseHashTable.get(precr,extendrepl));
        // update Replacements
        erepl = BaseHashTable.add((precr, DAE.RCONST(0.0)),extendrepl);
        erepl1 = addExtendReplacement(erepl,subcr,SOME(precr));
      then erepl1;
    case (extendrepl,cr as DAE.CREF_QUAL(ident=ident,identType=ty as DAE.ET_ARRAY(ty=_),subscriptLst=subscriptLst,componentRef=subcr),SOME(pcr))
      equation
        precr = ComponentReference.makeCrefIdent(ident,ty,{});
        precr1 = ComponentReference.joinCrefs(pcr,precr);
        failure(_ = BaseHashTable.get(precr1,extendrepl));
        // update Replacements
        erepl = BaseHashTable.add((precr1, DAE.RCONST(0.0)),extendrepl);
        precrn = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        precrn1 = ComponentReference.joinCrefs(pcr,precrn);
        erepl1 = addExtendReplacement(erepl,subcr,SOME(precrn1));
      then erepl1;
    case (extendrepl,cr as DAE.CREF_QUAL(ident=ident,identType=ty as DAE.ET_COMPLEX(complexClassType=ClassInf.RECORD(_)),subscriptLst=subscriptLst,componentRef=subcr),SOME(pcr))
      equation
        precr = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        precr1 = ComponentReference.joinCrefs(pcr,precr);
        failure(_ = BaseHashTable.get(precr1,extendrepl));
        // update Replacements
        erepl = BaseHashTable.add((precr1, DAE.RCONST(0.0)),extendrepl);
        erepl1 = addExtendReplacement(erepl,subcr,SOME(precr1));
      then erepl1;
    // all other
    case (extendrepl,cr as DAE.CREF_QUAL(ident=ident,identType=ty,subscriptLst=subscriptLst,componentRef=subcr),NONE())
      equation
        precrn = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        erepl = addExtendReplacement(extendrepl,subcr,SOME(precrn));
      then erepl;
    case (extendrepl,cr as DAE.CREF_QUAL(ident=ident,identType=ty,subscriptLst=subscriptLst,componentRef=subcr),SOME(pcr))
      equation
        precrn = ComponentReference.makeCrefIdent(ident,ty,subscriptLst);
        precrn1 = ComponentReference.joinCrefs(pcr,precrn);
        erepl = addExtendReplacement(extendrepl,subcr,SOME(precrn1));
      then erepl;
    case (extendrepl,cr,_)
      equation
        Debug.fprintln("failtrace", "- BackendVarTransform.addExtendReplacement failed");
      then extendrepl;
  end matchcontinue;
end addExtendReplacement;


public function getReplacement "function: getReplacement

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

public function getExtendReplacement "function: getExtendReplacement

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
    case (REPLACEMENTS(extendhashTable=ht),src)
      equation
        dst = BaseHashTable.get(src,ht);
      then
        dst;
  end match;
end getExtendReplacement;

protected function avoidDoubleHashLookup "
Author BZ 200X-XX modified 2008-06
When adding replacement rules, we might not have the correct type availible at the moment.
Then DAE.ET_OTHER() is used, so when replacing exp and finding DAE.ET_OTHER(), we use the
type of the expression to be replaced instead.
TODO: find out why array residual functions containing arrays as xloc[] does not work,
      doing that will allow us to use this function for all crefs."
  input DAE.Exp inExp;
  input DAE.ExpType inType;
  output DAE.Exp outExp;
algorithm  outExp := matchcontinue(inExp,inType)
  local DAE.ComponentRef cr;
  case(DAE.CREF(cr,DAE.ET_OTHER()),inType) then Expression.makeCrefExp(cr,inType);
  case(inExp,_) then inExp;
  end matchcontinue;
end avoidDoubleHashLookup;

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
      DAE.Exp e,e1_1,e2_1,e1,e2,e3_1,e3,r_1,r;
      DAE.ExpType t,tp,ety;
      VariableReplacements repl;
      Option<FuncTypeExp_ExpToBoolean> cond;
      DAE.Operator op;
      list<DAE.Exp> expl_1,expl;
      Absyn.Path path,p;
      Boolean c,isTuple,c1,c2,c3;
      Integer b;
      Absyn.CodeNode a;
      String id;
      list<list<tuple<DAE.Exp, Boolean>>> bexpl_1,bexpl;
      DAE.InlineType inlineType;
      Integer index_;
      Option<tuple<DAE.Exp,Integer,Integer>> isExpisASUB;
      Option<Values.Value> v;
      Option<DAE.Exp> foldExp;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators iters;
      
      // Note: Most of these functions check if a subexpression did a replacement.
      // If it did not, we do not create a new copy of the expression (to save some memory). 
    case ((e as DAE.CREF(componentRef = cr,ty = t)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (cr,_) = replaceCrefSubs(cr,repl,cond);
        e1 = getExtendReplacement(repl, cr);
        ((e2,(_,true))) = BackendDAEUtil.extendArrExp((e,(NONE(),false)));
        (e3,_) = replaceExp(e2,repl,cond);
      then
        (e3,true);
    case ((e as DAE.CREF(componentRef = cr,ty = t)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (cr,_) = replaceCrefSubs(cr,repl,cond);
        e1 = getReplacement(repl, cr);
        e2 = avoidDoubleHashLookup(e1,t);
      then
        (e2,true);
    case ((e as DAE.CREF(componentRef = cr,ty = t)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (cr,true) = replaceCrefSubs(cr,repl,cond);
      then (DAE.CREF(cr,t),true);
    case ((e as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        true = c1 or c2;
      then
        (DAE.BINARY(e1_1,op,e2_1),true);
    case ((e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        true = c1 or c2;
      then
        (DAE.LBINARY(e1_1,op,e2_1),true);
    case ((e as DAE.UNARY(operator = op,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1_1,true) = replaceExp(e1, repl, cond);
      then
        (DAE.UNARY(op,e1_1),true);
    case ((e as DAE.LUNARY(operator = op,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
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
    case ((e as DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        (e3_1,c3) = replaceExp(e3, repl, cond);
        true = c1 or c2 or c3;
      then
        (DAE.IFEXP(e1_1,e2_1,e3_1),true);
      /* Special case when a variable in pre() is an alias for unary minus of another */
    case (DAE.CALL(path = path as Absyn.IDENT("pre"),expLst = {e as DAE.CREF(componentRef = _)},tuple_ = isTuple,builtin = c,ty=tp,inlineType=inlineType),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (DAE.UNARY(DAE.UMINUS(ety),e),true) = replaceExp(e, repl, cond);
      then
        (DAE.UNARY(DAE.UMINUS(ety),DAE.CALL(path,{e},isTuple,c,tp,inlineType)),true);
    case ((e as DAE.CALL(path = path,expLst = expl,tuple_ = isTuple,builtin = c,ty=tp,inlineType=inlineType)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (expl_1,true) = replaceExpList(expl, repl, cond, {}, false);
      then
        (DAE.CALL(path,expl_1,isTuple,c,tp,inlineType),true);
    case ((e as DAE.ARRAY(ty = tp,scalar = c,array = expl)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (expl_1,true) = replaceExpList(expl, repl, cond, {}, false);
      then
        (DAE.ARRAY(tp,c,expl_1),true);
    case ((e as DAE.MATRIX(ty = t,integer = b,scalar = bexpl)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (bexpl_1,true) = replaceExpMatrix(bexpl, repl, cond, {}, false);
      then
        (DAE.MATRIX(t,b,bexpl_1),true);
    case ((e as DAE.RANGE(ty = tp,exp = e1,expOption = NONE(),range = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        true = c1 or c2;
      then
        (DAE.RANGE(tp,e1_1,NONE(),e2_1),true);
    case ((e as DAE.RANGE(ty = tp,exp = e1,expOption = SOME(e3),range = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        (e3_1,c3) = replaceExp(e3, repl, cond);
        true = c1 or c2 or c3;
      then
        (DAE.RANGE(tp,e1_1,SOME(e3_1),e2_1),true);
    case ((e as DAE.TUPLE(PR = expl)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (expl_1,true) = replaceExpList(expl, repl, cond, {}, false);
      then
        (DAE.TUPLE(expl_1),true);
    case ((e as DAE.CAST(ty = tp,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1_1,true) = replaceExp(e1, repl, cond);
      then
        (DAE.CAST(tp,e1_1),true);
    case ((e as DAE.ASUB(exp = e1,sub = expl)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (expl,true) = replaceExpList(expl, repl, cond, {}, c1);
      then
        (Expression.makeASUB(e1_1,expl),true);
    case ((e as DAE.SIZE(exp = e1,sz = NONE())),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1_1,true) = replaceExp(e1, repl, cond);
      then
        (DAE.SIZE(e1_1,NONE()),true);
    case ((e as DAE.SIZE(exp = e1,sz = SOME(e2))),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (e2_1,c2) = replaceExp(e2, repl, cond);
        true = c1 or c2;
      then
        (DAE.SIZE(e1_1,SOME(e2_1)),true);
    case (DAE.CODE(code = a,ty = tp),repl,cond)
      equation
        print("replace_exp on CODE not impl.\n");
      then
        (DAE.CODE(a,tp),false);
    case ((e as DAE.REDUCTION(reductionInfo = reductionInfo,expr = e1,iterators = iters)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        (e1_1,c1) = replaceExp(e1, repl, cond);
        (iters,true) = replaceExpIters(iters, repl, cond, {}, false);
      then (DAE.REDUCTION(reductionInfo,e1_1,iters),true);
    case (e,repl,cond)
      then (e,false);
  end matchcontinue;
end replaceExp;

protected function replaceCrefSubs
  input DAE.ComponentRef inCref;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> cond;
  output DAE.ComponentRef outCr;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  (outCr,replacementPerformed) := match (inCref,repl,cond)
    local
      String name;
      DAE.ComponentRef cr,cr_1;
      DAE.ExpType ty;
      list<DAE.Subscript> subs,subs_1;
      Boolean c1,c2;

    case (inCref as DAE.CREF_QUAL(ident = name, identType = ty, subscriptLst = subs, componentRef = cr), repl, cond)
      equation
        (subs_1, c1) = replaceCrefSubs2(subs, repl, cond);
        (cr_1, c2) = replaceCrefSubs(cr, repl, cond);
        subs = Util.if_(c1,subs_1,subs);
        cr = Util.if_(c2,cr_1,cr);
        cr = Util.if_(c1 or c2,DAE.CREF_QUAL(name, ty, subs, cr),inCref);
      then
        (cr, c1 or c2);

    case (inCref as DAE.CREF_IDENT(ident = name, identType = ty, subscriptLst = subs), repl, cond)
      equation
        (subs, c1) = replaceCrefSubs2(subs, repl, cond);
        cr = Util.if_(c1,DAE.CREF_IDENT(name, ty, subs),inCref);
      then
        (cr, c1);

    else (inCref,false);
  end match;
end replaceCrefSubs;

protected function replaceCrefSubs2
  input list<DAE.Subscript> subs;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> cond;
  output list<DAE.Subscript> outSubs;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  (outSubs,replacementPerformed) := match (subs,repl,cond)
    local
      DAE.Exp exp;
      Boolean c1,c2;
    case ({}, repl, cond) then ({},false);
    case (DAE.WHOLEDIM()::subs, repl, cond)
      equation
        (subs,c1) = replaceCrefSubs2(subs,repl,cond);
      then (DAE.WHOLEDIM()::subs, c1);

    case (DAE.SLICE(exp = exp)::subs, repl, cond)
      equation
        (exp,c2) = replaceExp(exp, repl, cond);
        (subs,c1) = replaceCrefSubs2(subs,repl,cond);
      then
        (DAE.SLICE(exp)::subs, c1 or c2);

    case (DAE.INDEX(exp = exp)::subs, repl, cond)
      equation
        (exp,c2) = replaceExp(exp, repl, cond);
        (subs,c1) = replaceCrefSubs2(subs,repl,cond);
      then
        (DAE.INDEX(exp)::subs, c1 or c2);

    case (DAE.WHOLE_NONEXP(exp = exp)::subs, repl, cond)
      equation
        (exp,c2) = replaceExp(exp, repl, cond);
        (subs,c1) = replaceCrefSubs2(subs,repl,cond);
      then
        (DAE.WHOLE_NONEXP(exp)::subs, c1 or c2);
    
  end match;
end replaceCrefSubs2;

public function replaceExpList
  input list<DAE.Exp> expl;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> cond;
  input list<DAE.Exp> acc1;
  input Boolean acc2;
  output list<DAE.Exp> outExpl;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  (outExpl,replacementPerformed) := match (expl,repl,cond,acc1,acc2)
    local
      DAE.Exp exp;
      Boolean c;
    case ({},_,_,acc1,acc2) then (listReverse(acc1),acc2);
    case (exp::expl,repl,cond,acc1,acc2)
      equation
        (exp,c) = replaceExp(exp,repl,cond);
        (acc1,acc2) = replaceExpList(expl,repl,cond,exp::acc1,c or acc2);
      then (acc1,acc2);
  end match;
end replaceExpList;

protected function replaceExpIters
  input list<DAE.ReductionIterator> iters;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> cond;
  input list<DAE.ReductionIterator> acc1;
  input Boolean acc2;
  output list<DAE.ReductionIterator> outIter;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  (outIter,replacementPerformed) := matchcontinue (iters,repl,cond,acc1,acc2)
    local
      String id;
      DAE.Exp exp,gexp;
      DAE.Type ty;
      Boolean b1,b2;
      DAE.ReductionIterator iter;
    case ({},_,_,acc1,acc2) then (listReverse(acc1),acc2);
    case (DAE.REDUCTIONITER(id,exp,NONE(),ty)::iters,repl,cond,acc1,_)
      equation
        (exp,true) = replaceExp(exp, repl, cond);
        (iters,_) = replaceExpIters(iters,repl,cond,DAE.REDUCTIONITER(id,exp,NONE(),ty)::acc1,true);
      then (iters,true);
    case (DAE.REDUCTIONITER(id,exp,SOME(gexp),ty)::iters,repl,cond,acc1,acc2)
      equation
        (exp,b1) = replaceExp(exp, repl, cond);
        (gexp,b2) = replaceExp(gexp, repl, cond);
        true = b1 or b2;
        (iters,_) = replaceExpIters(iters,repl,cond,DAE.REDUCTIONITER(id,exp,SOME(gexp),ty)::acc1,true);
      then (iters,true);
    case (iter::iters,repl,cond,acc1,acc2)
      equation
        (iters,acc2) = replaceExpIters(iters,repl,cond,iter::acc1,acc2);
      then (iters,acc2);
  end matchcontinue;
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
    case (NONE(),_) then true;
  end match;
end replaceExpCond;

protected function replaceExpMatrix "function: replaceExpMatrix
  author: PA

  Helper function to replace_exp, traverses Matrix expression list.
"
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
  input list<list<tuple<DAE.Exp, Boolean>>> acc1;
  input Boolean acc2;
  output list<list<tuple<DAE.Exp, Boolean>>> outTplExpExpBooleanLstLst;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  (outTplExpExpBooleanLstLst,replacementPerformed) :=
  match (inTplExpExpBooleanLstLst,inVariableReplacements,inFuncTypeExpExpToBooleanOption,acc1,acc2)
    local
      VariableReplacements repl;
      Option<FuncTypeExp_ExpToBoolean> cond;
      list<tuple<DAE.Exp, Boolean>> e_1,e;
      list<list<tuple<DAE.Exp, Boolean>>> es_1,es;
      Boolean c;
    case ({},repl,cond,acc1,acc2) then (listReverse(acc1),acc2);
    case ((e :: es),repl,cond,acc1,acc2)
      equation
        (e_1,acc2) = replaceExpMatrix2(e, repl, cond, {}, acc2);
        (acc1,acc2) = replaceExpMatrix(es, repl, cond, e_1::acc1, acc2);
      then
        (acc1,acc2);
  end match;
end replaceExpMatrix;

protected function replaceExpMatrix2 "function: replaceExpMatrix2
  author: PA

  Helper function to replace_exp_matrix
"
  input list<tuple<DAE.Exp, Boolean>> inTplExpExpBooleanLst;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
  input list<tuple<DAE.Exp, Boolean>> acc1;
  input Boolean acc2;
  output list<tuple<DAE.Exp, Boolean>> outTplExpExpBooleanLst;
  output Boolean replacementPerformed;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  (outTplExpExpBooleanLst,replacementPerformed) :=
  match (inTplExpExpBooleanLst,inVariableReplacements,inFuncTypeExpExpToBooleanOption,acc1,acc2)
    local
      list<tuple<DAE.Exp, Boolean>> es_1,es;
      DAE.Exp e_1,e;
      Boolean b,c;
      VariableReplacements repl;
      Option<FuncTypeExp_ExpToBoolean> cond;
    case ({},_,_,acc1,acc2) then (listReverse(acc1),acc2);
    case (((e,b) :: es),repl,cond,acc1,acc2)
      equation
        (e_1,c) = replaceExp(e, repl, cond);
        (acc1,acc2) = replaceExpMatrix2(es, repl, cond, (e_1,b)::acc1, c or acc2);
      then
        (acc1,acc2);
  end match;
end replaceExpMatrix2;

public function replaceEquations
"function: replaceEquations
  This function takes a list of equations ana a set of variable
  replacements and applies the replacements on all equations.
  The function returns the updated list of equations"
  input list<BackendDAE.Equation> inDAE;
  input VariableReplacements repl;
  output list<BackendDAE.Equation> outDAE;
protected
  HashTable2.HashTable ht;
algorithm
  REPLACEMENTS(hashTable = ht) := repl;
  // Do not do empty replacements; it just takes time ;)
  outDAE := Debug.bcallret2(BaseHashTable.hashTableCurrentSize(ht)>0,replaceEquations2,inDAE,repl,inDAE);
end replaceEquations;

protected function replaceEquations2
  input list<BackendDAE.Equation> inBackendDAEEquationLst;
  input VariableReplacements inVariableReplacements;
  output list<BackendDAE.Equation> outBackendDAEEquationLst;
algorithm
  outBackendDAEEquationLst:=
  matchcontinue (inBackendDAEEquationLst,inVariableReplacements)
    local
      DAE.Exp e1_1,e2_1,e1_2,e2_2,e1,e2,e_1,e_2,e;
      list<BackendDAE.Equation> es_1,es;
      VariableReplacements repl;
      BackendDAE.Equation a;
      DAE.ComponentRef cr;
      Integer indx;
      list<DAE.Exp> expl,expl1,expl2;
      BackendDAE.WhenEquation whenEqn,whenEqn1;
      DAE.ElementSource source "the origin of the element";
      Boolean b1,b2;

    case ({},_) then {};
    case ((BackendDAE.ARRAY_EQUATION(indx,expl,source)::es),repl)
      equation
        (expl1,true) = replaceExpList(expl,repl,NONE(),{},false);
        /* TODO: Add symbolic operation to source */
        expl2 = ExpressionSimplify.simplifyList(expl1,{});
        es_1 = replaceEquations(es,repl);
      then
         (BackendDAE.ARRAY_EQUATION(indx,expl2,source)::es_1);

    case ((BackendDAE.EQUATION(exp = e1,scalar = e2,source = source) :: es),repl)
      equation
        (e1_1,b1) = replaceExp(e1, repl,NONE());
        (e2_1,b2) = replaceExp(e2, repl,NONE());
        true = b1 or b2;
        source = DAEUtil.addSymbolicTransformationSubstitution(b1,source,e1,e1_1);
        source = DAEUtil.addSymbolicTransformationSubstitution(b2,source,e2,e2_1);
        (e1_2,b1) = ExpressionSimplify.simplify(e1_1);
        (e2_2,b2) = ExpressionSimplify.simplify(e2_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e1_1,e1_2);
        source = DAEUtil.addSymbolicTransformationSimplify(b2,source,e2_1,e2_2);
        es_1 = replaceEquations(es, repl);
      then
        (BackendDAE.EQUATION(e1_2,e2_2,source) :: es_1);

    case (((BackendDAE.ALGORITHM(index=indx,in_=expl,out=expl1,source = source)) :: es),repl)
      equation
        (expl,b1) = replaceExpList(expl,repl,NONE(),{},false);
        (expl1,true) = replaceExpList(expl1,repl,NONE(),{},b1);
        /* TODO: Add symbolic operation to source */
        expl = ExpressionSimplify.simplifyList(expl,{});
        expl1 = ExpressionSimplify.simplifyList(expl1,{}) "who decided to do this crap twice?";
        // original algorithm is done by replaceAlgorithms
        // inputs and ouputs are updated from DAELow.updateAlgorithmInputsOutputs       
        es_1 = replaceEquations(es, repl);
      then
        (BackendDAE.ALGORITHM(indx,expl,expl1,source) :: es_1);

    case ((BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e,source = source) :: es),repl)
      equation
        (e_1,true) = replaceExp(e, repl,NONE());
        (e_2,_) = ExpressionSimplify.simplify(e_1);
        source = DAEUtil.addSymbolicTransformationSubstitution(true,source,e,e_2);
        es_1 = replaceEquations(es, repl);
      then
        (BackendDAE.SOLVED_EQUATION(cr,e_2,source) :: es_1);

    case ((BackendDAE.RESIDUAL_EQUATION(exp = e,source = source) :: es),repl)
      equation
        (e_1,true) = replaceExp(e, repl,NONE());
        (e_2,_) = ExpressionSimplify.simplify(e_1);
        source = DAEUtil.addSymbolicTransformationSubstitution(true,source,e,e_2);
        es_1 = replaceEquations(es, repl);
      then
        (BackendDAE.RESIDUAL_EQUATION(e_2,source) :: es_1);

    case ((BackendDAE.WHEN_EQUATION(whenEqn,source) :: es),repl)
      equation
        whenEqn1 = replaceWhenEquation(whenEqn,repl);
        es_1 = replaceEquations(es, repl);
      then
        (BackendDAE.WHEN_EQUATION(whenEqn1,source) :: es_1);

    case ((a :: es),repl)
      equation
        es_1 = replaceEquations(es, repl);
      then
        (a :: es_1);
  end matchcontinue;
end replaceEquations2;

protected function replaceWhenEquation "Replaces variables in a when equation"
  input BackendDAE.WhenEquation whenEqn;
  input VariableReplacements repl;
  output BackendDAE.WhenEquation outWhenEqn;
algorithm
  outWhenEqn := matchcontinue(whenEqn,repl)
  local Integer i;
    DAE.ComponentRef cr,cr1;
    DAE.Exp e,e1,e2;
    DAE.ExpType tp;
    BackendDAE.WhenEquation elsePart,elsePart2;
    Boolean b1;

    case (BackendDAE.WHEN_EQ(i,cr,e,NONE()),repl)
      equation
        (e1,b1) = replaceExp(e, repl,NONE());
        /* TODO: Add symbolic operation to source */
        (e2,_) = ExpressionSimplify.simplify(e1);
        (DAE.CREF(cr1,_),_) = replaceExp(Expression.crefExp(cr),repl,NONE());
      then 
        BackendDAE.WHEN_EQ(i,cr1,e2,NONE());

    // Replacements makes cr negative, a = -b
    case (BackendDAE.WHEN_EQ(i,cr,e,NONE()),repl)
      equation
        (DAE.UNARY(DAE.UMINUS(tp),DAE.CREF(cr1,_)),_) = replaceExp(Expression.crefExp(cr),repl,NONE());
        /* TODO: Add symbolic operation to source */
        (e1,b1) = replaceExp(e, repl,NONE());
        e1 = DAE.UNARY(DAE.UMINUS(tp),e1);
        (e2,_) = ExpressionSimplify.simplify(e1);
      then 
        BackendDAE.WHEN_EQ(i,cr1,e2,NONE());

    case (BackendDAE.WHEN_EQ(i,cr,e,SOME(elsePart)),repl)
      equation
        elsePart2 = replaceWhenEquation(elsePart,repl);
        /* TODO: Add symbolic operation to source */
        (e1,b1) = replaceExp(e, repl,NONE());
        (e2,_) = ExpressionSimplify.simplify(e1);
        (DAE.CREF(cr1,_),_) = replaceExp(Expression.crefExp(cr),repl,NONE());
      then BackendDAE.WHEN_EQ(i,cr1,e2,SOME(elsePart2));

    // Replacements makes cr negative, a = -b
    case (BackendDAE.WHEN_EQ(i,cr,e,SOME(elsePart)),repl)
      equation
        elsePart2 = replaceWhenEquation(elsePart,repl);
        /* TODO: Add symbolic operation to source */
        (DAE.UNARY(DAE.UMINUS(tp),DAE.CREF(cr1,_)),_) = replaceExp(Expression.crefExp(cr),repl,NONE());
        (e1,b1) = replaceExp(e, repl,NONE());
        e1 = DAE.UNARY(DAE.UMINUS(tp),e1);
        (e2,_) = ExpressionSimplify.simplify(e1);
      then BackendDAE.WHEN_EQ(i,cr1,e2,SOME(elsePart2));

  end matchcontinue;
end replaceWhenEquation;

public function replaceMultiDimEquations "function: replaceMultiDimEquations

  This function takes a list of equations ana a set of variable replacements
  and applies the replacements on all array equations.
  The function returns the updated list of array equations
"
  input list<BackendDAE.MultiDimEquation> inBackendDAEEquationLst;
  input VariableReplacements inVariableReplacements;
  output list<BackendDAE.MultiDimEquation> outBackendDAEEquationLst;
algorithm
  outBackendDAEEquationLst:=
  match (inBackendDAEEquationLst,inVariableReplacements)
    local
      DAE.Exp e1_1,e2_1,e1,e2,e1_2,e2_2;
      list<BackendDAE.MultiDimEquation> es_1,es;
      VariableReplacements repl;
      list<Integer> dims;
      DAE.ElementSource source "the origin of the element";
      Boolean b1,b2;

    case ({},_) then {};
    case ((BackendDAE.MULTIDIM_EQUATION(left = e1,right = e2,dimSize = dims,source=source) :: es),repl)
      equation
        (e1_1,b1) = replaceExp(e1, repl,NONE());
        (e2_1,b2) = replaceExp(e2, repl,NONE());
        (e1_2,_) = ExpressionSimplify.simplify(e1_1);
        (e2_2,_) = ExpressionSimplify.simplify(e2_1);
        source = DAEUtil.addSymbolicTransformationSubstitution(b1,source,e1,e1_2);
        source = DAEUtil.addSymbolicTransformationSubstitution(b2,source,e2,e2_2);
        es_1 = replaceMultiDimEquations(es, repl);
      then
        (BackendDAE.MULTIDIM_EQUATION(dims,e1_2,e2_2,source) :: es_1);
  end match;
end replaceMultiDimEquations;

public function replaceAlgorithms "function: replaceAlgorithms

  This function takes a list of algorithms ana a set of variable replacements
  and applies the replacements on all array equations.
  The function returns the updated list of array equations
"
  input list<DAE.Algorithm> inAlgorithmLst;
  input VariableReplacements inVariableReplacements;
  output list<DAE.Algorithm> outAlgorithmLst;
  output Boolean replacementPerformed;
algorithm
  (outAlgorithmLst,replacementPerformed) :=
  match (inAlgorithmLst,inVariableReplacements)
    local
      VariableReplacements repl;
      list<DAE.Statement> statementLst,statementLst_1;
      list<DAE.Algorithm> es,es_1;
      Boolean b1,b2;
    case ({},_) then ({},false);
    case ((DAE.ALGORITHM_STMTS(statementLst=statementLst) :: es),repl)
      equation
        (statementLst_1,b1) = replaceStatementLst(statementLst,repl);
        (es_1,b2) = replaceAlgorithms(es,repl);
      then
        (DAE.ALGORITHM_STMTS(statementLst_1)  :: es_1, b1 or b2);
  end match;
end replaceAlgorithms;

public function replaceStatementLst "function: replaceStatementLst

  Helper for replaceMultiDimEquations.
"
  input list<DAE.Statement> inStatementLst;
  input VariableReplacements inVariableReplacements;
  output list<DAE.Statement> outStatementLst;
  output Boolean replacementPerformed;
algorithm
  (outStatementLst,replacementPerformed) :=
  matchcontinue (inStatementLst,inVariableReplacements)
    local
      VariableReplacements repl;
      list<DAE.Statement> es,es_1,statementLst,statementLst_1;
      DAE.Statement statement,statement_1;
      DAE.ExpType type_;
      DAE.Exp e1_1,e2_1,e1,e2,e1_2,e2_2;
      list<DAE.Exp> expExpLst,expExpLst_1;
      DAE.Else else_,else_1;
      DAE.ElementSource source;
      DAE.ComponentRef cr;
      Boolean iterIsArray;
      DAE.Ident ident;
      list<Integer> helpVarIndices;
      Boolean b1,b2,b3;
          
    case ({},_) then ({},false);
    
    case ((DAE.STMT_ASSIGN(type_=type_,exp1=e1,exp=e2,source=source)::es),repl)
      equation
        (e1_1,b1) = replaceExp(e1, repl,NONE());
        (e2_1,b2) = replaceExp(e2, repl,NONE());
        true = b1 or b2;
        (e1_2,_) = ExpressionSimplify.simplify(e1_1);
        (e2_2,_) = ExpressionSimplify.simplify(e2_1);
        source = DAEUtil.addSymbolicTransformationSubstitution(b1,source,e1,e1_2);
        source = DAEUtil.addSymbolicTransformationSubstitution(b2,source,e2,e2_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_ASSIGN(type_,e1_2,e2_2,source):: es_1,true);
    
    case ((DAE.STMT_TUPLE_ASSIGN(type_=type_,expExpLst=expExpLst,exp=e2,source=source)::es),repl)
      equation
        (expExpLst_1,b1) = replaceExpList(expExpLst,repl,NONE(),{},false);
        (e2_1,b2) = replaceExp(e2, repl,NONE());
        true = b1 or b2;
        source = DAEUtil.addSymbolicTransformationSubstitution(b2,source,e2,e2_1);
        (e2_2,b1) = ExpressionSimplify.simplify(e2_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e2_1,e2_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_TUPLE_ASSIGN(type_,expExpLst_1,e2_2,source):: es,true);
    
    case ((DAE.STMT_ASSIGN_ARR(type_=type_,componentRef=cr,exp=e1,source=source)::es),repl)
      equation
        (e1_1,true) = replaceExp(e1, repl,NONE());
        source = DAEUtil.addSymbolicTransformationSubstitution(true,source,e1,e1_1);
        (e1_2,b1) = ExpressionSimplify.simplify(e1_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e1_1,e1_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_ASSIGN_ARR(type_,cr,e1_2,source):: es_1,true);
    
    case ((DAE.STMT_IF(exp=e1,statementLst=statementLst,else_=else_,source=source)::es),repl)
      equation
        (statementLst_1,b1) = replaceStatementLst(statementLst, repl);
        (e1_1,b2) = replaceExp(e1, repl,NONE());
        (else_1,b3) = replaceElse(else_,repl);
        true = b1 or b2 or b3;
        source = DAEUtil.addSymbolicTransformationSubstitution(b2,source,e1,e1_1);
        (e1_2,b1) = ExpressionSimplify.simplify(e1_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e1_1,e1_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_IF(e1_2,statementLst_1,else_1,source):: es_1,true);
    
    case ((DAE.STMT_FOR(type_=type_,iterIsArray=iterIsArray,iter=ident,range=e1,statementLst=statementLst,source=source)::es),repl)
      equation
        (statementLst_1,b1) = replaceStatementLst(statementLst, repl);
        (e1_1,b2) = replaceExp(e1, repl,NONE());
        true = b1 or b2;
        source = DAEUtil.addSymbolicTransformationSubstitution(b2,source,e1,e1_1);
        (e1_2,b1) = ExpressionSimplify.simplify(e1_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e1_1,e1_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_FOR(type_,iterIsArray,ident,e1_2,statementLst_1,source):: es_1,true);
    
    case ((DAE.STMT_WHILE(exp=e1,statementLst=statementLst,source=source)::es),repl)
      equation
        (statementLst_1,b1) = replaceStatementLst(statementLst, repl);
        (e1_1,b2) = replaceExp(e1, repl,NONE());
        true = b1 or b2;
        source = DAEUtil.addSymbolicTransformationSubstitution(b2,source,e1,e1_1);
        (e1_2,b1) = ExpressionSimplify.simplify(e1_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e1_1,e1_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_WHILE(e1_2,statementLst_1,source):: es_1,true);
    
    case ((DAE.STMT_WHEN(exp=e1,statementLst=statementLst,elseWhen=NONE(),helpVarIndices=helpVarIndices,source=source)::es),repl)
      equation
        (statementLst_1,b1) = replaceStatementLst(statementLst, repl);
        (e1_1,b2) = replaceExp(e1, repl,NONE());
        true = b1 or b2;
        source = DAEUtil.addSymbolicTransformationSubstitution(b2,source,e1,e1_1);
        (e1_2,b1) = ExpressionSimplify.simplify(e1_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e1_1,e1_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_WHEN(e1_2,statementLst_1,NONE(),helpVarIndices,source):: es_1,true);
    
    case ((DAE.STMT_WHEN(exp=e1,statementLst=statementLst,elseWhen=SOME(statement),helpVarIndices=helpVarIndices,source=source)::es),repl)
      equation
        (statementLst_1,b1) = replaceStatementLst(statementLst, repl);
        (statement_1::{},b2) = replaceStatementLst({statement}, repl);
        (e1_1,b3) = replaceExp(e1, repl,NONE());
        true = b1 or b2 or b3;
        source = DAEUtil.addSymbolicTransformationSubstitution(b3,source,e1,e1_1);
        (e1_2,b1) = ExpressionSimplify.simplify(e1_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e1_1,e1_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_WHEN(e1_2,statementLst_1,SOME(statement_1),helpVarIndices,source):: es_1,true);
    
    case ((DAE.STMT_ASSERT(cond=e1,msg=e2,source=source)::es),repl)
      equation
        (e1_1,b1) = replaceExp(e1, repl,NONE());
        (e2_1,b2) = replaceExp(e2, repl,NONE());
        true = b1 or b2;
        (e1_2,_) = ExpressionSimplify.simplify(e1_1);
        (e2_2,_) = ExpressionSimplify.simplify(e2_1);
        source = DAEUtil.addSymbolicTransformationSubstitution(b1,source,e1,e1_2);
        source = DAEUtil.addSymbolicTransformationSubstitution(b2,source,e2,e2_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_ASSERT(e1_2,e2_2,source):: es_1,true);
    
    case ((DAE.STMT_TERMINATE(msg=e1,source=source)::es),repl)
      equation
        (e1_1,true) = replaceExp(e1, repl,NONE());
        source = DAEUtil.addSymbolicTransformationSubstitution(true,source,e1,e1_1);
        (e1_2,b1) = ExpressionSimplify.simplify(e1_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e1_1,e1_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_TERMINATE(e1_2,source):: es_1,true);
    
    case ((DAE.STMT_REINIT(var=e1,value=e2,source=source)::es),repl)
      equation
        (e1_1,b1) = replaceExp(e1, repl,NONE());
        (e2_1,b2) = replaceExp(e2, repl,NONE());
        true = b1 or b2;
        (e1_2,_) = ExpressionSimplify.simplify(e1_1);
        (e2_2,_) = ExpressionSimplify.simplify(e2_1);
        source = DAEUtil.addSymbolicTransformationSubstitution(b1,source,e1,e1_2);
        source = DAEUtil.addSymbolicTransformationSubstitution(b2,source,e2,e2_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_REINIT(e1_2,e2_2,source):: es_1,true);
    
    case ((DAE.STMT_NORETCALL(exp=e1,source=source)::es),repl)
      equation
        (e1_1,true) = replaceExp(e1, repl,NONE());
        source = DAEUtil.addSymbolicTransformationSubstitution(true,source,e1,e1_1);
        (e1_2,b1) = ExpressionSimplify.simplify(e1_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e1_1,e1_2);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_NORETCALL(e1_2,source):: es_1,true);
    
    // MetaModelica extension. KS
    case ((DAE.STMT_FAILURE(body=statementLst,source=source)::es),repl)
      equation
        (statementLst_1,true) = replaceStatementLst(statementLst, repl);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_FAILURE(statementLst_1,source):: es_1,true);
    
    case ((DAE.STMT_TRY(tryBody=statementLst,source=source)::es),repl)
      equation
        (statementLst_1,true) = replaceStatementLst(statementLst, repl);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_TRY(statementLst_1,source):: es_1,true);
    
    case ((DAE.STMT_CATCH(catchBody=statementLst,source=source)::es),repl)
      equation
        (statementLst_1,true) = replaceStatementLst(statementLst, repl);
        (es_1,_) = replaceStatementLst(es, repl);
      then
        (DAE.STMT_CATCH(statementLst_1,source):: es_1,true);
    
    case ((statement::es),repl) 
      equation
        (es_1,b1) = replaceStatementLst(es, repl);
      then
        (statement:: es_1,b1);
  end matchcontinue;
end replaceStatementLst;

protected function replaceElse "function: replaceElse

  Helper for replaceStatementLst.
"
  input DAE.Else inElse;
  input VariableReplacements inVariableReplacements;
  output DAE.Else outElse;
  output Boolean replacementPerformed;
algorithm
  (outElse,replacementPerformed) := matchcontinue (inElse,inVariableReplacements)
    local
      VariableReplacements repl;
      list<DAE.Statement> statementLst,statementLst_1;
      DAE.Exp e1,e1_1,e1_2;
      DAE.Else else_,else_1;
      Boolean b1,b2,b3;
    case (DAE.ELSEIF(exp=e1,statementLst=statementLst,else_=else_),repl)
      equation
        (statementLst_1,b1) = replaceStatementLst(statementLst, repl);
        (e1_1,b2) = replaceExp(e1, repl,NONE());
        (else_1,b3) = replaceElse(else_,repl);
        true = b1 or b2 or b3;
        (e1_2,_) = ExpressionSimplify.simplify(e1_1);
      then
        (DAE.ELSEIF(e1_2,statementLst_1,else_1),true);
    case (DAE.ELSE(statementLst=statementLst),repl) 
      equation
        (statementLst_1,true) = replaceStatementLst(statementLst, repl);
      then
        (DAE.ELSE(statementLst_1),true);
    else (inElse,false);
  end matchcontinue;
end replaceElse;

public function dumpReplacements
"function: dumpReplacements
  Prints the variable replacements on form var1 -> var2"
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
  end match;
end dumpReplacements;

protected function printReplacementTupleStr "help function to dumpReplacements"
  input tuple<DAE.ComponentRef,DAE.Exp> tpl;
  output String str;
algorithm
  // optional exteded type debugging
  str := ComponentReference.debugPrintComponentRefTypeStr(Util.tuple21(tpl)) +& " -> " +& ExpressionDump.debugPrintComponentRefExp(Util.tuple22(tpl));
  // Normal debugging, without type&dimension information on crefs.
  //str := ComponentReference.printComponentRefStr(Util.tuple21(tpl)) +& " -> " +& ExpressionDump.printExpStr(Util.tuple22(tpl));
end printReplacementTupleStr;

end BackendVarTransform;
