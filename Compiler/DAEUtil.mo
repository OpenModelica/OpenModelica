/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
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
 * from Linköpings University, either from the above address,
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

package DAEUtil
" file:	 DAEUtil.mo
  package:     DAE
  description: DAE management and output
 
  RCS: $Id$
  
  This module exports some helper functions to the DAE AST.
"

public import Absyn;
public import ClassInf;
public import DAE;
public import Env;
public import SCode;
public import Values;

public function derivativeOrder "
Function to sort derivatives.
Used for Util.sort
"
input tuple<Integer,DAE.derivativeCond> e1,e2; //greaterThanFunc
output Boolean b;
Integer i1,i2;
algorithm 
  b := matchcontinue(e1,e2)
    case((i1,_),(i2,_))
      then Util.isIntGreater(i1,i2);
  end matchcontinue;
end derivativeOrder;

public function addEquationBoundString "" 
  input DAE.Exp bindExp;
  input Option<DAE.VariableAttributes> attr;
  output Option<DAE.VariableAttributes> oattr;
algorithm oattr :=
matchcontinue (bindExp,attr)
    local
     	Option<DAE.Exp> e1,e2,e3,e4,e5,e6;
    	tuple<Option<DAE.Exp>, Option<DAE.Exp>> min;
      Option<DAE.StateSelect> sSelectOption,sSelectOption2;
      Option<Boolean> ip,fn;
      String s;
  case (bindExp,SOME(DAE.VAR_ATTR_REAL(e1,e2,e3,min,e4,e5,e6,sSelectOption,_,ip,fn)))
    then (SOME(DAE.VAR_ATTR_REAL(e1,e2,e3,min,e4,e5,e6,sSelectOption,SOME(bindExp),ip,fn))); 
  case (bindExp,SOME(DAE.VAR_ATTR_INT(e1,min,e2,e3,_,ip,fn)))
    then SOME(DAE.VAR_ATTR_INT(e1,min,e2,e3,SOME(bindExp),ip,fn));
  case (bindExp,SOME(DAE.VAR_ATTR_BOOL(e1,e2,e3,_,ip,fn)))	    
    then SOME(DAE.VAR_ATTR_BOOL(e1,e2,e3,SOME(bindExp),ip,fn));
  case (bindExp,SOME(DAE.VAR_ATTR_STRING(e1,e2,_,ip,fn)))
    then SOME(DAE.VAR_ATTR_STRING(e1,e2,SOME(bindExp),ip,fn));
  case(_,_) equation print("-failur DAE.add_Equation_Bound_String\n"); then fail();
   end matchcontinue;
end addEquationBoundString;

public function getClassList "get list of classes from Var"
  input DAE.Element v;
  output list<Absyn.Path> lst;
algorithm
  lst := matchcontinue(v)
    case(DAE.VAR(pathLst = lst)) then lst;
    case(_) then {};
  end matchcontinue;
end getClassList;

public function getBoundStartEquation ""
input DAE.VariableAttributes attr;
output DAE.Exp oe;
algorithm oe := matchcontinue(attr)
  local DAE.Exp beq;
  case (DAE.VAR_ATTR_REAL(equationBound = SOME(beq))) then beq; 
  case (DAE.VAR_ATTR_INT(equationBound = SOME(beq))) then beq; 
  case (DAE.VAR_ATTR_BOOL(equationBound = SOME(beq))) then beq; 
  case (DAE.VAR_ATTR_ENUMERATION(equationBound = SOME(beq))) then beq; 
end matchcontinue;
end getBoundStartEquation;

protected import Algorithm;
protected import Ceval;
protected import Debug;
protected import Dump;
protected import Error;
protected import Exp;
protected import Graphviz;
protected import ModUtil;
protected import Print;
protected import RTOpts;
protected import System;
protected import Types;
protected import Util;

public function removeEquations "Removes all equations and algorithms, from the dae"
	input list<DAE.Element> inDae;
	output list<DAE.Element> outDaeNonEq;
	output list<DAE.Element> outDaeEq;
algorithm
	inDae := matchcontinue(inDae)
	  local
	    DAE.Element v,e;
	    list<DAE.Element> elts,elts2,elts22,elts1,elts11,elts3,elts33;
	    String  id;
	  case({}) then  ({},{});
	    
	  case((v as DAE.VAR(componentRef=_))::elts)
	    equation
	      (elts2,elts3)=removeEquations(elts);
	    then (v::elts2,elts3);
	  case(DAE.COMP(id,DAE.DAE(elts1))::elts2)
	    equation
	      (elts11,elts3) = removeEquations(elts1);
	      (elts22,elts33) = removeEquations(elts2);
	      elts3 = listAppend(elts3,elts33);
	    then (DAE.COMP(id,DAE.DAE(elts11))::elts22,elts3);
	  case((e as DAE.EQUATION(_,_))::elts2)
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as DAE.EQUEQUATION(_,_))::elts2) 
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as DAE.INITIALEQUATION(_,_))::elts2) 
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as DAE.ARRAY_EQUATION(_,_,_))::elts2) 
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as DAE.COMPLEX_EQUATION(_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as DAE.INITIAL_COMPLEX_EQUATION(_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as DAE.INITIALDEFINE(_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    
	  case((e as DAE.DEFINE(_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    	    
	  case((e as DAE.WHEN_EQUATION(_,_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    	    
	  case((e as DAE.IF_EQUATION(_,_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    	    	    
	  case((e as DAE.INITIAL_IF_EQUATION(_,_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    	    	    	    
	  case((e as DAE.ALGORITHM(_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as DAE.INITIALALGORITHM(_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as DAE.FUNCTION(path=_))::elts2) equation
	    (elts22,elts3) = removeEquations(elts2);
    then (e::elts22,elts3);
	  case((e as DAE.RECORD_CONSTRUCTOR(path=_))::elts2) equation
	    (elts22,elts3) = removeEquations(elts2);
    then (e::elts22,elts3);
	  case((e as DAE.EXTOBJECTCLASS(path=_))::elts2) equation
	    (elts22,elts3) = removeEquations(elts2);
    then (e::elts22,elts3);	            
	  case((e as DAE.ASSERT(_,_))::elts2) 
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as DAE.REINIT(_,_))::elts2) 
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    
	end matchcontinue;  
  
end removeEquations;

public function removeVariables "Remove the variables in the list from the DAE"
  input list<DAE.Element> dae;
  input list<DAE.ComponentRef> vars;
  output list<DAE.Element> outDae;
algorithm
  outDae := Util.listFold(vars,removeVariable,dae);
end removeVariables;

public function removeVariable "Remove the variable from the DAE"
  input DAE.ComponentRef var;
  input list<DAE.Element> dae;
  output list<DAE.Element> outDae;
algorithm
   outDae := matchcontinue(var,dae)
     local DAE.ComponentRef cr;
       list<DAE.Element> elist,elist2;
       DAE.Element e,v;
       String id;
     case(var,{}) then {};
     case(var,(v as DAE.VAR(componentRef = cr))::dae) equation
       true = Exp.crefEqual(var,cr);
     then dae;
     case(var,DAE.COMP(id,DAE.DAE(elist))::dae) equation
       elist2=removeVariable(var,elist);
       dae = removeVariable(var,dae);
     then DAE.COMP(id,DAE.DAE(elist2))::dae;
     case(var,e::dae) equation
         dae = removeVariable(var,dae);
      then e::dae;        
   end matchcontinue;
end removeVariable;

public function removeInnerAttrs "Remove the inner attribute of all vars in list"
  input list<DAE.Element> dae;
  input list<DAE.ComponentRef> vars;
  output list<DAE.Element> outDae;
algorithm
  outDae := Util.listFold(vars,removeInnerAttr,dae);
end removeInnerAttrs;

public function removeInnerAttr "Remove the inner attribute from variable in the DAE"
  input DAE.ComponentRef var;
  input list<DAE.Element> dae;
  output list<DAE.Element> outDae;
algorithm
   outDae := matchcontinue(var,dae)
   			local DAE.ComponentRef cr,oldVar,newVar;
   			  list<DAE.Element> elist,elist2,elist3;
   			  DAE.Element e,v,u,o;
   			  String id;
   			  DAE.ComponentRef cr;
   			  DAE.VarKind kind;
   			  DAE.VarDirection dir;
    			DAE.Type tp;
   			  Option<DAE.Exp> bind;
   			  DAE.InstDims dim;
    			DAE.Flow flow_;
   			  list<Absyn.Path> cls;
    			Option<DAE.VariableAttributes> attr;
   			  Option<SCode.Comment> cmt;
    			Absyn.InnerOuter io,io2;
   			  DAE.VarProtection prot;
   			  DAE.Stream st;
     case(var,{}) then {};
     /* When having an inner outer, we declare two variables on the same line. 
        Since we can not handle this with current instantiation procedure, we create temporary variables in the dae.
        These are named uniqly and renamed later in "instClass" 
     */ 
     case(var,DAE.VAR(oldVar,kind,dir,prot,tp,bind,dim,flow_,st,cls,attr,cmt,(io as Absyn.INNEROUTER()))::dae) equation
       true = compareUniquedVarWithNonUnique(var,oldVar);
       newVar = nameInnerouterUniqueCref(oldVar);
       o = DAE.VAR(oldVar,kind,dir,prot,tp,NONE,dim,flow_,st,cls,attr,cmt,Absyn.OUTER()) "intact";
       u = DAE.VAR(newVar,kind,dir,prot,tp,bind,dim,flow_,st,cls,attr,cmt,Absyn.UNSPECIFIED()) " unique'ified";
       elist3 = u::{o};
       dae = listAppend(elist3,dae);
     then 
       dae;
         
     case(var,DAE.VAR(cr,kind,dir,prot,tp,bind,dim,flow_,st,cls,attr,cmt,io)::dae) equation
       true = Exp.crefEqual(var,cr);
       io2 = removeInnerAttribute(io);
     then 
       DAE.VAR(cr,kind,dir,prot,tp,bind,dim,flow_,st,cls,attr,cmt,io2)::dae;
       
     case(var,DAE.COMP(id,DAE.DAE(elist))::dae) equation
       elist2=removeInnerAttr(var,elist);
       dae = removeInnerAttr(var,dae);
     then DAE.COMP(id,DAE.DAE(elist2))::dae;
     case(var,e::dae) equation
         dae = removeInnerAttr(var,dae);
      then e::dae;        
   end matchcontinue;
end removeInnerAttr;

protected function compareUniquedVarWithNonUnique "
Author: BZ, workaround to get innerouter elements to work.
This function strips the 'unique identifer' from the cref and compares.
"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean equal;
  String s1,s2,s3;
algorithm
  s1 := Exp.printComponentRefStr(cr1);
  s2 := Exp.printComponentRefStr(cr2);
  s1 := System.stringReplace(s1, DAE.UNIQUEIO, "");
  s2 := System.stringReplace(s2, DAE.UNIQUEIO, "");
  equal := stringEqual(s1,s2);
end compareUniquedVarWithNonUnique;

public function nameInnerouterUniqueCref "
Author: BZ, 2008-11
Renames a var to unique name
"
  input DAE.ComponentRef inCr;
  output DAE.ComponentRef outCr;
algorithm outCr := matchcontinue(inCr)
  local
    DAE.ComponentRef newChild,child;
    String id;
    DAE.ExpType idt;
    list<DAE.Subscript> subs;
  case(DAE.CREF_IDENT(id,idt,subs))
    equation
      id = DAE.UNIQUEIO +& id;
    then
      DAE.CREF_IDENT(id,idt,subs);
  case(DAE.CREF_QUAL(id,idt,subs,child))
    equation
      newChild = nameInnerouterUniqueCref(child);      
    then
      DAE.CREF_QUAL(id,idt,subs,newChild);
      
end matchcontinue;
end nameInnerouterUniqueCref;

public function unNameInnerouterUniqueCref ""
input DAE.ComponentRef cr;
input String removalString;
output DAE.ComponentRef ocr;
algorithm ocr := matchcontinue(cr,removalString)
  local
    String str,str2;
    DAE.ExpType ty;
    DAE.ComponentRef child,child_2;
    list<DAE.Subscript> subs;
  case(DAE.CREF_IDENT(str,ty,subs),removalString)
    equation
      str2 = System.stringReplace(str, removalString, "");
      then
        DAE.CREF_IDENT(str2,ty,subs);
  case(DAE.CREF_QUAL(str,ty,subs,child),removalString)
    equation
      child_2 = unNameInnerouterUniqueCref(child,removalString);
      str2 = System.stringReplace(str, removalString, "");
    then
      DAE.CREF_QUAL(str2,ty,subs,child_2);
  case(DAE.WILD(),_) then DAE.WILD(); 
  case(child,_) 
    equation 
      print(" failure unNameInnerouterUniqueCref: ");
      print(Exp.printComponentRefStr(child) +& "\n"); 
      then fail(); 
  end matchcontinue;
end unNameInnerouterUniqueCref;
protected function getOuterBinding "
Author: BZ, 2008-11
Aquire the binding on the outer/innerouter variable, to transfer to inner variable.
"
input DAE.ComponentRef currVar;
input list<tuple<DAE.ComponentRef, DAE.Exp>> inlst;
output Option<DAE.Exp> binding;
algorithm binding := matchcontinue(currVar,inlst)
  local DAE.ComponentRef cr1,cr2; DAE.Exp e;
  case(_,{}) then NONE; 
  case(cr1,(cr2,e)::inlst)
    equation
      true = Exp.crefEqual(cr1,cr2);
      then
        SOME(e);
  case(cr1,(_,_)::inlst) then getOuterBinding(cr1,inlst);
  end matchcontinue;
end getOuterBinding;

protected function removeInnerAttribute "Help function to removeInnerAttr"
	 input Absyn.InnerOuter io;
	 output Absyn.InnerOuter ioOut;
algorithm
  ioOut := matchcontinue(io)
    case(Absyn.INNER()) then Absyn.UNSPECIFIED();
    case(Absyn.INNEROUTER()) then Absyn.OUTER();
    case(io) then io;
  end matchcontinue;
end removeInnerAttribute;

public function varCref " returns the component reference of a variable"
input DAE.Element elt;
output DAE.ComponentRef cr;
algorithm
  cr := matchcontinue(elt)
    case(DAE.VAR(componentRef = cr)) then cr;
  end matchcontinue;
end varCref;

public function printDAE "function: printDAE
 
  This function prints out a list of elements (i.e. a DAE)
  to the stdout. Useful for example when called from Inst.instClass"
  input DAE.DAElist inDAElist;
algorithm  
  _:=
  matchcontinue (inDAElist)
    local
    	DAE.DAElist dae;
    	String str;
    case dae 
      equation
        Print.clearBuf();
        dump2(dae);
        str = Print.getString();
        print(str);
      then 
        ();
  end matchcontinue;
end printDAE;        


public function dump "function: dump
 
  This function prints the DAE in the standard output format.
"
  input DAE.DAElist inDAElist;
algorithm 
  _:=
  matchcontinue (inDAElist)
    local 
      list<DAE.Element> daelist;
    case DAE.DAE(elementLst = daelist)
      equation 
        Util.listMap0(daelist, dumpFunction);
        Util.listMap0(daelist, dumpExtObjectClass);
        Util.listMap0(daelist, dumpCompElement);
      then
        ();
  end matchcontinue;
end dump;

public function dump2str ""
input DAE.DAElist inDAElist;
output String str;
algorithm 
  dump2(inDAElist);
  str := Print.getString();
  Print.clearBuf();
end dump2str;

public function dump2 "function: dump2
 
  Helper function to dump. Prints the DAE using module Print.
"
  input DAE.DAElist inDAElist;
algorithm 
  _:=
  matchcontinue (inDAElist)
    local
      String comment_str,ident,str,extdeclstr,s1;
      DAE.ComponentRef cr;
      DAE.Exp e,e1,e2;
      DAE.InstDims dims;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<DAE.Element> xs;
      DAE.DAElist lst,dae;
      Absyn.Path path;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      DAE.ExternalDecl extdecl;
    case DAE.DAE(elementLst = (DAE.VAR(componentRef = cr,
                               binding = SOME(e),
                               dims = dims,
                               variableAttributesOption = dae_var_attr,
                               absynCommentOption = comment) :: xs))
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        
        /* //include type of var 
        
        s1 = Exp.debugPrintComponentRefTypeStr(cr); 
        s1 = Util.stringReplaceChar(s1,"\n","");
        Print.printBuf("((" +& s1);        
        Print.printBuf("))");
        */
        Print.printBuf("=");
        Exp.printExp(e);
        Print.printBuf(",dims=");
        Dump.printList(dims, Exp.printSubscript, ", ");
        comment_str = dumpCommentOptionStr(comment) "	dump_start_value start &" ;
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        Print.printBuf(", ");
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE(elementLst = (DAE.VAR(componentRef = cr,binding = NONE,variableAttributesOption = dae_var_attr,absynCommentOption = comment) :: xs))
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        /* // include type in dump
        s1 = Exp.debugPrintComponentRefTypeStr(cr); 
        s1 = Util.stringReplaceChar(s1,"\n","");
        Print.printBuf("((" +& s1);
        Print.printBuf("))");
        */
        comment_str = dumpCommentOptionStr(comment) "	dump_start_value start &" ;
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        Print.printBuf(", ");
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE(elementLst = (DAE.DEFINE(componentRef = cr) :: xs))
      equation 
        Print.printBuf("DEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE(elementLst = (DAE.INITIALDEFINE(componentRef = cr) :: xs))
      equation 
        Print.printBuf("INITIALDEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE(elementLst = (DAE.EQUATION(exp = e1,scalar = e2) :: xs))
      equation 
        Print.printBuf("EQUATION(");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case DAE.DAE(elementLst = (DAE.INITIALEQUATION(exp1 = e1,exp2 = e2) :: xs))
      equation 
        Print.printBuf("INITIALEQUATION(");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE(elementLst = (DAE.ALGORITHM(algorithm_ = _) :: xs)))
      equation 
        Print.printBuf("ALGORITHM(...)");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE(elementLst = (DAE.INITIALALGORITHM(algorithm_ = _) :: xs)))
      equation 
        Print.printBuf("INITIALALGORITHM(...)");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE(elementLst = (DAE.COMP(ident = ident,dAElist = lst) :: xs)))
      equation 
        Print.printBuf("COMP(");
        Print.printBuf(ident);
        dump2(lst);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE(elementLst = (DAE.FUNCTION(path = _) :: xs)))
      equation 
        Print.printBuf("FUNCTION(...)\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE(elementLst = DAE.FUNCTION(path = path,functions = (DAE.FUNCTION_EXT(body = dae,externalDecl=extdecl))::_ ,type_ = tp) :: xs))
        equation 
        Print.printBuf("EXTFUNCTION(\n");
        str = Absyn.pathString(path);
        Print.printBuf(str);
        Print.printBuf(", ");
        dump2(dae);
        Print.printBuf(", ");
        Print.printBuf(Types.printTypeStr(tp));
        Print.printBuf(", ");
        extdeclstr = dumpExtDeclStr(extdecl);
        Print.printBuf(extdeclstr);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE(elementLst = (DAE.RECORD_CONSTRUCTOR(path = _) :: xs)))
      equation 
        Print.printBuf("RECORD_CONSTRUCTOR(...)\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE(elementLst = (DAE.ASSERT(condition=e1,message=e2) :: xs)))
      equation 
        Print.printBuf("ASSERT(\n");
        Exp.printExp(e1);
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE.DAE(xs));
      then
        ();
    case (DAE.DAE(elementLst = {})) then (); 
    case (_)
      equation
        Print.printBuf("dump2 failed\n");
      then
        ();
  end matchcontinue;
end dump2;

protected function dumpStartValue "function: dumpStartValue
 
  Dumps the StartValue for a variable.
"
  input DAE.StartValue inStartValue;
algorithm 
  _:=
  matchcontinue (inStartValue)
    local
      DAE.Exp e;
    case (SOME(e))
      equation 
        Print.printBuf("(start=");
        Exp.printExp(e);
        Print.printBuf(")");
      then
        ();
    case (_) then (); 
  end matchcontinue;
end dumpStartValue;

public function dumpStartValueStr "function: dumpStartValueStr
 
  Dumps the start value for a variable to a string.
"
  input DAE.StartValue inStartValue;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStartValue)
    local
      String s,res;
      DAE.Exp e;
    case (SOME(e))
      equation 
        s = Exp.printExpStr(e);
        res = Util.stringAppendList({"(peterstart=",s,")"});
      then
        res;
    case (_) then ""; 
  end matchcontinue;
end dumpStartValueStr;

public function dumpExtDeclStr "function: dumpExtDeclStr
 
  Dumps the external declaration to a string.
"
  input DAE.ExternalDecl inExternalDecl;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExternalDecl)
    local
      String extargsstr,rettystr,str,id,lang;
      list<DAE.ExtArg> extargs;
      DAE.ExtArg retty;
      Option<Absyn.Annotation> ann;
    case DAE.EXTERNALDECL(ident = id,external_ = extargs,parameters = retty,returnType = lang,language = ann)
      equation 
        extargsstr = Dump.getStringList(extargs, dumpExtArgStr, ",");
        rettystr = dumpExtArgStr(retty);
        str = Util.stringAppendList(
          {"EXTERNALDECL(",id,", (",extargsstr,"), ",rettystr,", \"",
          lang,"\")"});
      then
        str;
  end matchcontinue;
end dumpExtDeclStr;

public function dumpExtArgStr "function: dumpExtArgStr
 
  Helper function to dump_ext_decl_str
"
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExtArg)
    local
      String crstr,dirstr,tystr,str,dimstr;
      DAE.ComponentRef cr;
      Boolean fl,st;      
      SCode.Accessibility acc;
      SCode.Variability var;
      Absyn.Direction dir;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Exp exp,dim;
      DAE.Attributes attr;
    case DAE.NOEXTARG() then "void"; 
    case DAE.EXTARG(componentRef = cr,attributes = DAE.ATTR(flowPrefix = fl,streamPrefix=st,accessibility = acc,parameter_ = var,direction = dir),type_ = ty)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        dirstr = Dump.directionSymbol(dir);
        tystr = Types.getTypeName(ty);
        str = Util.stringAppendList({dirstr," ",tystr," ",crstr});
      then
        str;
    case DAE.EXTARGEXP(exp = exp,type_ = ty)
      equation 
        crstr = Exp.printExpStr(exp);
        tystr = Types.getTypeName(ty);
        str = Util.stringAppendList({"(",tystr,") ",crstr});
      then
        str;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size(",crstr,",",dimstr,")"});
      then
        str;
  end matchcontinue;
end dumpExtArgStr;

public function dumpStr "function: dumpStr
  
  This function prints the DAE to a string.
"
  input DAE.DAElist inDAElist;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inDAElist)
    local
      list<String> flist,clist,slist,extlist;
      String str;
      list<DAE.Element> daelist;
    case DAE.DAE(elementLst = daelist)
      equation 
        flist = Util.listMap(daelist, dumpFunctionStr);
        extlist = Util.listMap(daelist, dumpExtObjClassStr);
        clist = Util.listMap(daelist, dumpCompElementStr);
        slist = Util.listFlatten({flist,extlist, clist});
        str = Util.stringAppendList(slist);
      then
        str;
  end matchcontinue;
end dumpStr;

protected function dumpCompElement "function: dumpCompElement
 
  Dumps Component elements.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      String n;
      list<DAE.Element> l;
    case DAE.COMP(ident = n,dAElist = DAE.DAE(elementLst = l))
      equation 
        false = RTOpts.modelicaOutput();
        Print.printBuf("fclass ");
        Print.printBuf(n);
        Print.printBuf("\n");
        dumpElements(l);
        Print.printBuf("end ");
        Print.printBuf(n);
        Print.printBuf(";\n");
      then
        ();
    case DAE.COMP(ident = n,dAElist = DAE.DAE(elementLst = l))
      equation 
        true = RTOpts.modelicaOutput();
        Print.printBuf("class ");
        Print.printBuf(n);
        Print.printBuf("\n");
        dumpElements(l);
        Print.printBuf("end ");
        Print.printBuf(n);
        Print.printBuf(";\n");
      then
        ();
    case _ then ();  /* LS: for non-COMPS, which are only FUNCTIONS at the moment */ 
  end matchcontinue;
end dumpCompElement;

protected function dumpCompElementStr "function: dumpCompElementStr
 
  Dumps components to a string.
"
  input DAE.Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      String s1,s2,s3,s4,s5,s6,str,n;
      list<DAE.Element> l;
    case DAE.COMP(ident = n,dAElist = DAE.DAE(elementLst = l))
      equation 
        false = RTOpts.modelicaOutput();
        s1 = stringAppend("fclass ", n);
        s2 = stringAppend(s1, "\n");
        s3 = dumpElementsStr(l);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, "end ");
        s6 = stringAppend(s5, n);
        str = stringAppend(s6, ";\n");
      then
        str;
    case DAE.COMP(ident = n,dAElist = DAE.DAE(elementLst = l))
      equation 
        true = RTOpts.modelicaOutput();
        s1 = stringAppend("class ", n);
        s2 = stringAppend(s1, "\n");
        s3 = dumpElementsStr(l);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, "end ");
        s6 = stringAppend(s5, n);
        str = stringAppend(s6, ";\n");
      then
        str;
    case _ then "";  /* LS: for non-COMPS, which are only FUNCTIONS at the moment */ 
  end matchcontinue;
end dumpCompElementStr;

public function dumpElements "function: dumpElements
 
  Dump elements. 
"
  input list<DAE.Element> l;
algorithm 
  dumpVars(l);
  Util.listMap0(l, dumpExtObjectClass);
  Print.printBuf("initial equation\n");
  Util.listMap0(l, dumpInitialequation);
  Print.printBuf("equation\n");
  Util.listMap0(l, dumpEquation);
  Util.listMap0(l, dumpInitialalgorithm);
  Util.listMap0(l, dumpAlgorithm);
  Util.listMap0(l, dumpCompElement);
  
end dumpElements;

public function dumpElementsStr "function: dumpElementsStr
 
  Dump elements to a string
"
  input list<DAE.Element> l;
  output String str;
  String s0,s1,s2,s3,s4,s5,initeqstr,initalgstr,eqstr,algstr;
  Boolean noiniteq,noinitalg,noeq,noalg;
algorithm 
  s1 := dumpVarsStr(l);
  s2 := dumpInitialequationsStr(l);
  s3 := dumpEquationsStr(l);
  s4 := dumpInitialalgorithmsStr(l);
  s5 := dumpAlgorithmsStr(l);
  noiniteq := stringEqual(s2, "");
  noinitalg := stringEqual(s4, "");
  noeq := stringEqual(s3, "");
  noalg := stringEqual(s5, "");
  initeqstr := Dump.selectString(noiniteq, "", "initial equation\n");
  initalgstr := Dump.selectString(noinitalg, "", "initial algorithm\n");
  eqstr := Dump.selectString(noeq, "", "equation\n");
  algstr := Dump.selectString(noalg, "", "algorithm\n");
  s0 := Util.stringDelimitListNonEmptyElts(Util.listMap(l,dumpExtObjClassStr),"\n");
  str := Util.stringAppendList({s0,s1,initeqstr,s2,initalgstr,s4,eqstr,s3,algstr,s5});
end dumpElementsStr;

public function dumpAlgorithmsStr "function: dumpAlgorithmsStr
 
  Dump algorithms to a string.
"
  input list<DAE.Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      String s1,s2,s3,str;
      list<DAE.Statement> stmts;
      list<DAE.Element> xs;
    case ((DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)) :: xs))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        s2 = stringAppend("algorithm\n", s1);
        s3 = dumpAlgorithmsStr(xs);
        str = stringAppend(s1, s3);
      then
        str;
    case ((_ :: xs))
      equation 
        str = dumpAlgorithmsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpAlgorithmsStr;

protected function dumpInitialalgorithmsStr "function: dumpInitialalgorithmsStr
 
  Dump initialalgorithms to a string.
"
  input list<DAE.Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      String s1,s2,s3,str;
      list<DAE.Statement> stmts;
      list<DAE.Element> xs;
    case ((DAE.INITIALALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)) :: xs))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        s2 = stringAppend("algorithm\n", s1);
        s3 = dumpInitialalgorithmsStr(xs);
        str = stringAppend(s1, s3);
      then
        str;
    case ((_ :: xs))
      equation 
        str = dumpInitialalgorithmsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpInitialalgorithmsStr;

protected function dumpEquationsStr "function: dumpEquationsStr
 
  Dump equations to a string.
"
  input list<DAE.Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      String s1,s2,s3,s4,s4_1,s5,s6,str,s;
      DAE.Exp e1,e2,e;
      list<DAE.Element> xs,xs1,xs2;
      list<list<DAE.Element>> tb;
      DAE.ComponentRef c,cr,cr1,cr2;
    case ((DAE.EQUATION(exp = e1,scalar = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpEquationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
        
      case ((DAE.EQUEQUATION(cr1,cr2) :: xs))
      equation 
        s1 = Exp.printComponentRefStr(cr1)+&" = "+&Exp.printComponentRefStr(cr2)+&";\n";
        s2 = dumpEquationsStr(xs);
        str = s1+&s2;
      then
        str;
    case ((DAE.ARRAY_EQUATION(exp = e1,array = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpEquationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((DAE.COMPLEX_EQUATION(lhs = e1,rhs= e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpEquationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;        
    case ((DAE.DEFINE(componentRef = c,exp = e) :: xs))
      equation 
        s1 = Exp.printComponentRefStr(c);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpEquationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((DAE.ASSERT(condition=e1,message = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s3 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"assert(",s1,",",s2,");\n",s3});
      then
        str;
    case ((DAE.IF_EQUATION(condition1 = {},equations2 = {},equations3 = {}) :: xs)) then "";
      
    case ((DAE.IF_EQUATION(condition1 = (c::conds),equations2 = (xs1::tb),equations3 = {}) :: xs))
      local 
        DAE.Exp c;
        list<DAE.Exp> conds;   
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpEquationsStr(xs1);
        s2 = dumpIfEquationsStr(conds,tb);
        s3 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  if ",s," then\n",s1,s2,"  end if;\n",s3});
      then
        str;        
        
    case ((DAE.IF_EQUATION(condition1 = (c::conds),equations2 = (xs1::tb),equations3 = xs2) :: xs))
      local 
        DAE.Exp c;
        list<DAE.Exp> conds;   
        String ss11; 
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpEquationsStr(xs1);
        s2 = dumpEquationsStr(xs2);
        ss11 = dumpIfEquationsStr(conds,tb);
        s3 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  if ",s," then\n",s1,ss11,"  else\n",s2,"  end if;\n",s3});
      then
        str;
    case ((DAE.WHEN_EQUATION(condition = c,equations = xs1,elsewhen_ = SOME(xs2)) :: xs))
      local
        DAE.Exp c;
        DAE.Element xs2;
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpEquationsStr(xs1);
        s2 = dumpEquationsStr((xs2 :: xs));
        str = Util.stringAppendList({"when ",s," then\n",s1,"  else",s2});
      then
        str;
    case ((DAE.WHEN_EQUATION(condition = c,equations = xs1,elsewhen_ = NONE) :: xs))
      local
        DAE.Exp c;
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpEquationsStr(xs1);
        s3 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  when ",s," then\n",s1,"  end when;\n",s3});
      then
        str;
    case ((DAE.REINIT(componentRef = cr,exp = e) :: xs))
      equation 
        s = Exp.printComponentRefStr(cr);
        s1 = Exp.printExpStr(e);
        s2 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  reinit(",s,",",s1,");\n",s2});
      then
        str;
    case ((DAE.NORETCALL(functionName=path,functionArgs=expl) :: xs))
      local
        list<DAE.Exp> expl;
        Absyn.Path path;
      equation 
        s = Absyn.pathString(path);
        s1 = Util.stringDelimitList(Util.listMap(expl,Exp.printExpStr),",");
        s2 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  ",s,"(",s1,");\n",s2});
      then
        str;        
    case ((_ :: xs))
      equation 
        str = dumpEquationsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpEquationsStr;

protected function dumpIfEquationsStr "" 
  input list<DAE.Exp> conds;
  input list<list<DAE.Element>> tbs;
  output String outString; 
algorithm outString := matchcontinue(conds,tbs)
  local
    DAE.Exp c;
    list<DAE.Element> tb;
    String s1,s2,sRec,sRes;
  case({},{}) then "";
  case(c::conds, tb::tbs)
    equation
      s1 = Exp.printExpStr(c);
      s2 = dumpEquationsStr(tb);
      sRec = dumpIfEquationsStr(conds,tbs);
      sRes = "  elseif " +& s1 +& " then\n" +& s2 +& sRec; //+& Util.if_(Util.isEmptyString(sRec),"","\n");
      then
        sRes;
end matchcontinue;
end dumpIfEquationsStr;

protected function dumpInitialequationsStr "function: dumpInitialequationsStr
 
  Dump initial equations to a string.
"
  input list<DAE.Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      String s1,s2,s3,s4,s4_1,s5,s6,str,s;
      DAE.Exp e1,e2,e;
      list<DAE.Element> xs,xs1,xs2;
      list<list<DAE.Element>> trueBranches;
      DAE.ComponentRef c;
    case ((DAE.INITIALEQUATION(exp1 = e1,exp2 = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpInitialequationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpInitialequationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;    
    case ((DAE.INITIALDEFINE(componentRef = c,exp = e) :: xs))
      equation 
        s1 = Exp.printComponentRefStr(c);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " := ");
        s4 = Exp.printExpStr(e);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpInitialequationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((DAE.INITIAL_IF_EQUATION(condition1 = (c::conds),equations2 = (xs1::trueBranches),equations3 = xs2) :: xs))
      local        
        DAE.Exp c;
        list<DAE.Exp> conds;   
        String ss11; 
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpInitialequationsStr(xs1);
        s2 = dumpInitialequationsStr(xs2);
        ss11 = dumpIfEquationsStr(conds,trueBranches);
        s3 = dumpInitialequationsStr(xs);
        str = Util.stringAppendList({"  if ",s," then\n",s1,ss11,"  else\n",s2,"  end if;\n",s3});
      then
        str;
    case ((_ :: xs))
      equation 
        str = dumpInitialequationsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpInitialequationsStr;

protected function dumpVars "function: dumpVars
 
  Dump variables to Print buffer.
"
  input list<DAE.Element> lst;
  String str;
algorithm 
  str := dumpVarsStr(lst);
  Print.printBuf(str);
end dumpVars;

public function dumpVarsStr "function: dumpVarsStr
 
  Dump variables to a string.
"
  input list<DAE.Element> inElementLst;
  output String outString;
algorithm 
  outString:= matchcontinue (inElementLst)
    local
      String s1,s2,str;
      DAE.Element first;
      list<DAE.Element> rest;
    case {} then ""; 
    case (first :: rest)
      equation 
        s1 = dumpVarStr(first);
        s2 = dumpVarsStr(rest);
        str = stringAppend(s1, s2);
      then
        str;
  end matchcontinue;
end dumpVarsStr;

protected function dumpKind "function: dumpKind
 
  Dump VarKind.
"
  input DAE.VarKind inVarKind;
algorithm 
  _:=
  matchcontinue (inVarKind)
    case DAE.CONST()
      equation 
        Print.printBuf(" constant  ");
      then
        ();
    case DAE.PARAM()
      equation 
        Print.printBuf(" parameter ");
      then
        ();
    case DAE.DISCRETE()
      equation 
        Print.printBuf(" discrete  ");
      then
        ();
    case DAE.VARIABLE()
      equation 
        Print.printBuf("           ");
      then
        ();
  end matchcontinue;
end dumpKind;

protected function dumpKindStr "function: dumpKindStr 
 
  Dump VarKind to a string.
"
  input DAE.VarKind inVarKind;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVarKind)
    case DAE.CONST() then "constant "; 
    case DAE.PARAM() then "parameter "; 
    case DAE.DISCRETE() then "discrete "; 
    case DAE.VARIABLE() then ""; 
  end matchcontinue;
end dumpKindStr;

protected function dumpDirection "function: dumpDirection
 
  Dump VarDirection.
"
  input DAE.VarDirection inVarDirection;
algorithm 
  _:=
  matchcontinue (inVarDirection)
    case DAE.INPUT()
      equation 
        Print.printBuf(" input  ");
      then
        ();
    case DAE.OUTPUT()
      equation 
        Print.printBuf(" output ");
      then
        ();
    case DAE.BIDIR()
      equation 
        Print.printBuf("        ");
      then
        ();
  end matchcontinue;
end dumpDirection;

public function dumpDirectionStr "function: dumpDirectionStr
 
  Dump VarDirection to a string
"
  input DAE.VarDirection inVarDirection;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVarDirection)
    case DAE.INPUT() then "input "; 
    case DAE.OUTPUT() then "output "; 
    case DAE.BIDIR() then ""; 
  end matchcontinue;
end dumpDirectionStr;

protected function dumpStateSelectStr "function dumpStateSelectStr
 
  Dump StateSelect to a string.
"
  input DAE.StateSelect inStateSelect;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStateSelect)
    case DAE.NEVER() then "StateSelect.never"; 
    case DAE.AVOID() then "StateSelect.avoid"; 
    case DAE.PREFER() then "StateSelect.prefer"; 
    case DAE.ALWAYS() then "StateSelect.always"; 
    case DAE.DEFAULT() then "StateSelect.default"; 
  end matchcontinue;
end dumpStateSelectStr;

public function dumpVariableAttributes "function: dumpVariableAttributes 
 
  Dump VariableAttributes option.
"
  input Option<DAE.VariableAttributes> attr;
  String res;
algorithm 
  res := dumpVariableAttributesStr(attr);
  Print.printBuf(res);
end dumpVariableAttributes;

public function getUnitAttr "
  Return the unit attribute
"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp start;
algorithm 
  start:=
  matchcontinue (inVariableAttributesOption)
    local
      DAE.Exp u;
    case (SOME(DAE.VAR_ATTR_REAL(_,SOME(u),_,_,_,_,_,_,_,_,_))) then u;
    case (_) then DAE.SCONST(""); 
  end matchcontinue;
end getUnitAttr;

public function getStartAttrEmpty " 
  Return the start attribute.
"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  input DAE.Exp optExp;
  output DAE.Exp start;
algorithm 
  start := matchcontinue (inVariableAttributesOption,optExp)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r))),_) then r;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r))),_) then r;
    case (SOME(DAE.VAR_ATTR_BOOL(initial_ = SOME(r))),_) then r;
    case (SOME(DAE.VAR_ATTR_STRING(initial_ = SOME(r))),_) then r;
    case(_,optExp) then optExp;
  end matchcontinue;
end getStartAttrEmpty;

public function getMinMax " 
Author: BZ, returns a list of optional exp, {opt<Min> opt<Max} 
"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output list<Option<DAE.Exp>> oExps;
algorithm oExps := matchcontinue(inVariableAttributesOption)
  local 
    Option<DAE.Exp> e1,e2;
  case(SOME(DAE.VAR_ATTR_ENUMERATION(min = (e1,e2))))
    equation
    then
      e1::{e2};
  case(SOME(DAE.VAR_ATTR_INT(min = (e1,e2))))
    equation
    then
      e1::{e2};
  case(SOME(DAE.VAR_ATTR_REAL(min = (e1,e2))))
    equation
    then
      e1::{e2};  
  case(_) then {};
  end matchcontinue;
end getMinMax;

public function getStartAttr " 
  Return the start attribute.
"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp start;
algorithm 
  start:=
  matchcontinue (inVariableAttributesOption)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_BOOL(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_STRING(initial_ = SOME(r)))) then r;
    case (_) then DAE.RCONST(0.0); 
  end matchcontinue;
end getStartAttr;

public function getStartAttrFail " 
  Return the start attribute. or fails"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp start;
algorithm start:= matchcontinue (inVariableAttributesOption)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_BOOL(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_STRING(initial_ = SOME(r)))) then r;
  end matchcontinue;
end getStartAttrFail;

public function setVariableAttributes "sets the attributes of a DAE.Element that is VAR"
  input DAE.Element var;
  input Option<DAE.VariableAttributes> varOpt;
  output DAE.Element outVar;
algorithm
  outVar := matchcontinue(var,varOpt)
    local
      DAE.ComponentRef cr;
      DAE.VarKind k;
      DAE.VarDirection d ;
      DAE.VarProtection p;
      DAE.Type ty ;
      Option<DAE.Exp> b; 
      DAE.InstDims  dims ;
      DAE.Flow fl;
      DAE.Stream st;
      list<Absyn.Path> cls;
      Option<SCode.Comment> cmt;
      Absyn.InnerOuter io; 
    
    case(DAE.VAR(cr,k,d,p,ty,b,dims,fl,st,cls,_,cmt,io),varOpt) then DAE.VAR(cr,k,d,p,ty,b,dims,fl,st,cls,varOpt,cmt,io);
  end matchcontinue;
end setVariableAttributes;

public function setStartAttr " 
  sets the start attribute. If NONE, assumes Real attributes.
"
  input Option<DAE.VariableAttributes> attr;
  input DAE.Exp start;
  output Option<DAE.VariableAttributes> outAttr;  
algorithm 
  outAttr:=
  matchcontinue (attr,start)
    local
      Option<DAE.Exp> q,u,du,i,f,n;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      DAE.Exp r;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;
    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,_,f,n,ss,eb,ip,fn)),start) 
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,SOME(start),f,n,ss,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,_,f,eb,ip,fn)),start) 
    then SOME(DAE.VAR_ATTR_INT(q,minMax,SOME(start),f,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_BOOL(q,_,f,eb,ip,fn)),start) 
    then SOME(DAE.VAR_ATTR_BOOL(q,SOME(start),f,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_STRING(q,_,eb,ip,fn)),start) 
    then SOME(DAE.VAR_ATTR_STRING(q,SOME(start),eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,fn)),start) 
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,SOME(start),du,eb,ip,fn));
    case (NONE,start) 
      then SOME(DAE.VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),SOME(start),NONE,NONE,NONE,NONE,NONE,NONE)); 
  end matchcontinue;
end setStartAttr;

public function setUnitAttr " 
  sets the unit attribute. .
"
  input Option<DAE.VariableAttributes> attr;
  input DAE.Exp unit;
  output Option<DAE.VariableAttributes> outAttr;  
algorithm 
  outAttr:=
  matchcontinue (attr,unit)
    local
      Option<DAE.Exp> q,u,du,i,f,n,s;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      DAE.Exp r;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;
    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,s,f,n,ss,eb,ip,fn)),unit) 
    then SOME(DAE.VAR_ATTR_REAL(q,SOME(unit),du,minMax,s,f,n,ss,eb,ip,fn));
    case (NONE,unit) 
      then SOME(DAE.VAR_ATTR_REAL(NONE,SOME(unit),NONE,(NONE,NONE),NONE,NONE,NONE,NONE,NONE,NONE,NONE)); 
  end matchcontinue;
end setUnitAttr;

public function setProtectedAttr " 
  sets the start attribute. If NONE, assumes Real attributes.
"
  input Option<DAE.VariableAttributes> attr;
  input Boolean isProtected;
  output Option<DAE.VariableAttributes> outAttr;  
algorithm 
  outAttr:=
  matchcontinue (attr,isProtected)
    local
      Option<DAE.Exp> q,u,du,i,f,n;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      DAE.Exp r;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn; 
    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,_,fn)),isProtected) 
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,SOME(isProtected),fn));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,eb,_,fn)),isProtected)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,eb,SOME(isProtected),fn));
    case (SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,_,fn)),isProtected) 
    then SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,SOME(isProtected),fn));
    case (SOME(DAE.VAR_ATTR_STRING(q,i,eb,_,fn)),isProtected)
    then SOME(DAE.VAR_ATTR_STRING(q,i,eb,SOME(isProtected),fn));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,fn)),isProtected) 
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,SOME(isProtected),fn));
    case (NONE,isProtected) 
      then SOME(DAE.VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),NONE,NONE,NONE,NONE,NONE,SOME(isProtected),NONE));
  end matchcontinue;
end setProtectedAttr;

public function getProtectedAttr " 
  retrieves the protected attribute form VariableAttributes.
"
  input Option<DAE.VariableAttributes> attr;
  output Boolean isProtected;
algorithm 
  isProtected:=
  matchcontinue (attr)      
    case (SOME(DAE.VAR_ATTR_REAL(isProtected=SOME(isProtected)))) then isProtected; 
    case (SOME(DAE.VAR_ATTR_INT(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_BOOL(isProtected=SOME(isProtected)))) then isProtected;     
    case (SOME(DAE.VAR_ATTR_STRING(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(isProtected=SOME(isProtected)))) then isProtected; 
    case(_) then false;
  end matchcontinue;
end getProtectedAttr;

public function setFixedAttr "Function: setFixedAttr
Sets the start attribute:fixed to inputarg
" 
  input Option<DAE.VariableAttributes> attr;
  input Option<DAE.Exp> start;
  output Option<DAE.VariableAttributes> outAttr;  
algorithm 
  outAttr:=
  matchcontinue (attr,start)
    local
      Option<DAE.Exp> q,u,du,i,f,n,ini;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      DAE.Exp r;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;
    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,ini,_,n,ss,eb,ip,fn)),start) 
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,ini,start,n,ss,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,ini,_,eb,ip,fn)),start) 
    then SOME(DAE.VAR_ATTR_INT(q,minMax,ini,start,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_BOOL(q,ini,_,eb,ip,fn)),start) 
    then SOME(DAE.VAR_ATTR_BOOL(q,ini,start,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_STRING(q,ini,eb,ip,fn)),start) 
    then SOME(DAE.VAR_ATTR_STRING(q,ini,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,_,eb,ip,fn)),start) 
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,start,eb,ip,fn));
  end matchcontinue;
end setFixedAttr;

public function setFinalAttr " 
  sets the start attribute. If NONE, assumes Real attributes.
"
  input Option<DAE.VariableAttributes> attr;
  input Boolean finalPrefix;
  output Option<DAE.VariableAttributes> outAttr;  
algorithm 
  outAttr:=
  matchcontinue (attr,finalPrefix)
    local
      Option<DAE.Exp> q,u,du,i,f,n;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn; 
    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,ip,_)),finalPrefix) 
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,ip,SOME(finalPrefix)));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,eb,ip,_)),finalPrefix)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,eb,ip,SOME(finalPrefix)));
    case (SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,ip,_)),finalPrefix) 
    then SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,ip,SOME(finalPrefix)));
    case (SOME(DAE.VAR_ATTR_STRING(q,i,eb,ip,_)),finalPrefix)
    then SOME(DAE.VAR_ATTR_STRING(q,i,eb,ip,SOME(finalPrefix)));
      
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,_)),finalPrefix) 
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,SOME(finalPrefix)));
      
    case (NONE,finalPrefix)
      then SOME(DAE.VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),NONE,NONE,NONE,NONE,NONE,NONE,SOME(finalPrefix)));
  end matchcontinue;
end setFinalAttr;

public function boolVarProtection "Function: boolVarProtection
Takes a DAE.varprotection and returns true/false (is_protected / not) 
"
  input DAE.VarProtection vp;
  output Boolean prot;
algorithm
  prot := matchcontinue(vp) 
    case(DAE.PUBLIC()) then false;
    case(DAE.PROTECTED()) then true; 
    case(_) equation print("- DAEUtil.boolVa_Protection failed\n"); then fail();
  end matchcontinue;
end boolVarProtection;

public function varHasName "returns true if variable equals name passed as argument"
  input DAE.Element var;
  input DAE.ComponentRef cr;
  output Boolean res;
algorithm
  res := matchcontinue(var,cr) 
  local DAE.ComponentRef cr2;
    case(DAE.VAR(componentRef=cr2),cr) equation
      res = Exp.crefEqual(cr2,cr);      
    then res;
  end matchcontinue;
end varHasName;

public function hasStartAttr " 
  Returns true if variable attributes defines a start value.
"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output Boolean hasStart;
algorithm 
  hasStart:=
  matchcontinue (inVariableAttributesOption)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r)))) then true;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r)))) then true;
    case (SOME(DAE.VAR_ATTR_BOOL(initial_ = SOME(r)))) then true;
    case (SOME(DAE.VAR_ATTR_STRING(initial_ = SOME(r)))) then true;
    case (_) then false; 
  end matchcontinue;
end hasStartAttr;

public function getStartAttrString "function: getStartAttrString
 
  Return the start attribute as a string.
"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVariableAttributesOption)
    local
      String s;
      DAE.Exp r;
    case (NONE) then ""; 
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r))))
      equation 
        s = Exp.printExpStr(r);
      then
        s;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r))))
      equation 
        s = Exp.printExpStr(r);        
      then
        s;
    case (_) then ""; 
  end matchcontinue;
end getStartAttrString;

protected function stringToString "function: stringToString
 
  Convert a string to a Modelica string, enclosed in citation marks.
"
  input String str;
  output String str_1;
  String str_1;
algorithm 
  str_1 := Util.stringAppendList({"\"",str,"\""});
end stringToString;

public function dumpVariableAttributesStr "function: dumpVariableAttributesStr
 
  Dump VariableAttributes option to a string.
"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVariableAttributesOption)
    local
      String quantity,unit_str,displayUnit_str,stateSel_str,min_str,max_str,nominal_str,Initial_str,fixed_str,res_1,res1,res;
      Boolean is_empty;
      Option<DAE.Exp> quant,unit,displayUnit;
      Option<DAE.Exp> min,max,Initial,nominal;
      Option<DAE.Exp> fixed;
      Option<DAE.StateSelect> stateSel;
    case (SOME(DAE.VAR_ATTR_REAL(quant,unit,displayUnit,(min,max),Initial,fixed,nominal,stateSel,_,_,_)))
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, Exp.printExpStr, "quantity = ");
        unit_str = Dump.getOptionWithConcatStr(unit, Exp.printExpStr, "unit = ");
        displayUnit_str = Dump.getOptionWithConcatStr(displayUnit, Exp.printExpStr, "displayUnit = ");
        stateSel_str = Dump.getOptionWithConcatStr(stateSel, dumpStateSelectStr , "StateSelect = ");
        min_str = Dump.getOptionWithConcatStr(min, Exp.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, Exp.printExpStr, "max = ");
        nominal_str = Dump.getOptionWithConcatStr(nominal, Exp.printExpStr, "nominal = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Exp.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Exp.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts(
          {quantity,unit_str,displayUnit_str,min_str,max_str,
          Initial_str,fixed_str,nominal_str,stateSel_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(DAE.VAR_ATTR_INT(quant,(min,max),Initial,fixed,_,_,_)))
      local Option<DAE.Exp> min,max,Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, Exp.printExpStr, "quantity = ");
        min_str = Dump.getOptionWithConcatStr(min, Exp.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, Exp.printExpStr, "max = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Exp.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Exp.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,min_str,max_str,Initial_str,fixed_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(DAE.VAR_ATTR_BOOL(quant,Initial,fixed,_,_,_)))
      local Option<DAE.Exp> Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, Exp.printExpStr, "quantity = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Exp.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Exp.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,Initial_str,fixed_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(DAE.VAR_ATTR_STRING(quant,Initial,_,_,_)))
      local Option<DAE.Exp> Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, Exp.printExpStr, "quantity = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Exp.printExpStr, "start = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,Initial_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(quant,(min,max),Initial,fixed,_,_,_)))
      local Option<DAE.Exp> min,max,Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, Exp.printExpStr, "quantity = ");
        min_str = Dump.getOptionWithConcatStr(min, Exp.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, Exp.printExpStr, "max = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Exp.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Exp.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,min_str,max_str,Initial_str,fixed_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (NONE) then ""; 
    case (_) then "unknown VariableAttributes"; 
  end matchcontinue;
end dumpVariableAttributesStr;

protected function dumpVar "
  Dump Var.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      DAE.ComponentRef id;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type typ;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> classlst,class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Exp e;
    case DAE.VAR(componentRef = id,
             kind = kind,
             direction = dir,
             ty = typ,
             binding = NONE,
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             pathLst = classlst,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        dumpKind(kind);
        dumpDirection(dir);
        Print.printBuf(Types.unparseType(typ));
        Print.printBuf(" ");
        Exp.printComponentRef(id);
        dumpCommentOption(comment) "	dump_start_value start &" ;
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(";\n");
      then
        ();
    case DAE.VAR(componentRef = id,
             kind = kind,
             direction = dir,
             ty = typ,
             binding = SOME(e),
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             pathLst = class_,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        dumpKind(kind);
        dumpDirection(dir);
        Print.printBuf(Types.unparseType(typ));
        Print.printBuf(" ");
        Exp.printComponentRef(id);
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(" = ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (_) then (); 
  end matchcontinue;
end dumpVar;

protected function dumpVarStr "function: dumpVarStr
 
  Dump var to a string.
"
  input DAE.Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      String s1,s2,s3,s4,comment_str,s5,str,s6,s7;
      DAE.ComponentRef id;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type typ;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> classlst;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Exp e;
      DAE.VarProtection prot;
    case DAE.VAR(componentRef = id,
             kind = kind,
             direction = dir,
             protection=prot,
             ty = typ,
             binding = NONE,
             flowPrefix = flowPrefix,
             streamPrefix =  streamPrefix,
             pathLst = classlst,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        s1 = dumpKindStr(kind);
        s2 = dumpDirectionStr(dir);
        s3 = Types.unparseType(typ);
        s4 = Exp.printComponentRefStr(id);
        s7 = dumpVarProtectionStr(prot);
        comment_str = dumpCommentOptionStr(comment);
        s5 = dumpVariableAttributesStr(dae_var_attr);
        str = Util.stringAppendList({s7,s1,s2,s3," ",s4,s5,comment_str,";\n"});
      then
        str;
    case DAE.VAR(componentRef = id,
             kind = kind,
             direction = dir,
             protection=prot,
             ty = typ,
             binding = SOME(e),
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             pathLst = classlst,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        s1 = dumpKindStr(kind);
        s2 = dumpDirectionStr(dir);
        s3 = Types.unparseType(typ);
        s4 = Exp.printComponentRefStr(id);
        s5 = Exp.printExpStr(e);
        comment_str = dumpCommentOptionStr(comment);
        s6 = dumpVariableAttributesStr(dae_var_attr);
        s7 = dumpVarProtectionStr(prot);
        str = Util.stringAppendList({s7,s1,s2,s3," ",s4,s6," = ",s5,comment_str,";\n"})  ;
      then
        str;
    case (_) then ""; 
  end matchcontinue;
end dumpVarStr;

protected function dumpVarProtectionStr "Prints 'protected' to a string for protected variables"
  input DAE.VarProtection prot;
  output String str;
algorithm
  str := matchcontinue(prot)
    case DAE.PUBLIC() then "";
    case DAE.PROTECTED() then "protected ";  
  end matchcontinue;
end dumpVarProtectionStr;

public function dumpCommentOptionStr "function: dumpCommentOptionStr
 
  Dump Comment option to a string.
"
  input Option<SCode.Comment> inAbsynCommentOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynCommentOption)
    local
      String str,cmt;
      Option<SCode.Annotation> annopt;
    case (NONE) then ""; 
    case (SOME(SCode.COMMENT(annopt,SOME(cmt))))
      equation 
        str = Util.stringAppendList({" \"",cmt,"\""});
      then
        str;
    case (SOME(SCode.COMMENT(annopt,NONE))) then ""; 
  end matchcontinue;
end dumpCommentOptionStr;

protected function dumpCommentOption "function: dumpCommentOption_str
 
  Dump Comment option.
"
  input Option<SCode.Comment> comment;
  String str;
algorithm 
  str := dumpCommentOptionStr(comment);
  Print.printBuf(str);
end dumpCommentOption;

protected function dumpEquation "function: dumpEquation
 
  Dump equation.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      DAE.Exp e1,e2,e;
      DAE.ComponentRef c,cr1,cr2;
    case (DAE.EQUATION(exp = e1,scalar = e2))
      equation 
        Print.printBuf("  ");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
        
      case (DAE.EQUEQUATION(cr1,cr2))
      equation 
        Print.printBuf("  ");
        Exp.printComponentRef(cr1);
        Print.printBuf(" = ");
        Exp.printComponentRef(cr2);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.ARRAY_EQUATION(exp = e1,array= e2))
      equation 
        Print.printBuf("  ");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
        
    case (DAE.COMPLEX_EQUATION(lhs = e1,rhs= e2))
      equation 
        Print.printBuf("  ");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(";\n");
      then
        ();        
        
    case (DAE.DEFINE(componentRef = c,exp = e))
      equation 
        Print.printBuf("  ");
        Exp.printComponentRef(c);
        Print.printBuf(" ::= ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (DAE.ASSERT(condition=e1,message=e2))
      equation 
        Print.printBuf("assert(");
        Exp.printExp(e1);
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(");\n");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpEquation;

protected function dumpInitialequation "function: dumpInitialequation
 
  Dump initial equation.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      DAE.Exp e1,e2,e;
      DAE.ComponentRef c;
      list<DAE.Element> xs,xs1,xs2;
      list<list<DAE.Element>> trueBranches;
    case (DAE.INITIALEQUATION(exp1 = e1,exp2 = e2))
      equation 
        Print.printBuf("  ");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
    case (DAE.INITIALDEFINE(componentRef = c,exp = e))
      equation 
        Print.printBuf("  ");
        Exp.printComponentRef(c);
        Print.printBuf(" ::= ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2))
      equation
        Print.printBuf("  ");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
    case (DAE.INITIAL_IF_EQUATION(condition1 = (c::conds),equations2 = (xs1::trueBranches),equations3 = xs2))
      local
        DAE.Exp c;
        list<DAE.Exp> conds;
        String ss11;
      equation
        Print.printBuf("  if ");
        Exp.printExp(c);
        Print.printBuf(" then\n");
        Util.listMap0(xs1,dumpInitialequation);
        Print.printBuf(dumpIfEquationsStr(conds,trueBranches));
        Print.printBuf("  else\n");
        Util.listMap0(xs2,dumpInitialequation);
        Print.printBuf("end if;\n");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpInitialequation;

protected function dumpEquationStr "function: dumpEquationStr
 
  Dump equation to a string.
"
  input DAE.Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      String s1,s2,s3,s4,s5,str,s;
      DAE.Exp e1,e2,e;
      DAE.ComponentRef c,cr1,cr2;
    case (DAE.EQUATION(exp = e1,scalar = e2))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, ";\n");
      then
        str;
     case (DAE.EQUEQUATION(cr1,cr2))
      equation 
        s1 = Exp.printComponentRefStr(cr1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printComponentRefStr(cr2);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, ";\n");
      then
        str;
    case(DAE.ARRAY_EQUATION(_,e1,e2)) equation
      s1 = Exp.printExpStr(e1);
      s2 = Exp.printExpStr(e2);
      str = s1 +& " = " +& s2;
    then str;
    
    case(DAE.COMPLEX_EQUATION(e1,e2)) equation
      s1 = Exp.printExpStr(e1);
      s2 = Exp.printExpStr(e2);
      str = s1 +& " = " +& s2;
    then str;
      
    case (DAE.DEFINE(componentRef = c,exp = e))
      equation 
        s1 = Exp.printComponentRefStr(c);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(" ::= ", s2);
        s4 = Exp.printExpStr(e);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, ";\n");
      then
        str;
    case (DAE.ASSERT(condition=e1,message = e2))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        str = Util.stringAppendList({"assert(",s1, ",",s2,");\n"});
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpEquationStr;

public function dumpAlgorithm "function: dumpAlgorithm
 
  Dump algorithm.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local list<DAE.Statement> stmts;
    case DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts))
      equation 
        Print.printBuf("algorithm\n");
        Dump.printList(stmts, ppStatement, "");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpAlgorithm;

protected function dumpInitialalgorithm "function: dump_algorithm
 
  Dump initial algorithm.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local list<DAE.Statement> stmts;
    case DAE.INITIALALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts))
      equation 
        Print.printBuf("initial algorithm\n");
        Dump.printList(stmts, ppStatement, "");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpInitialalgorithm;

public function dumpAlgorithmStr 
"function: dumpAlgorithmStr 
  Dump algorithm to a string"
  input DAE.Element inElement;
  output String outString;
algorithm 
  outString := matchcontinue (inElement)
    local
      String s1,str;
      list<DAE.Statement> stmts;
    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        str = stringAppend("algorithm\n", s1);
      then
        str;
    case (_) then ""; 
  end matchcontinue;
end dumpAlgorithmStr;

protected function dumpInitialalgorithmStr 
"function: dumpInitialalgorithmStr 
  Dump initial algorithm to a string"
  input DAE.Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      String s1,str;
      list<DAE.Statement> stmts;
    case DAE.INITIALALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        str = stringAppend("initial algorithm\n", s1);
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpInitialalgorithmStr;

protected function dumpExtObjectClass 
"function: dumpExtObjectClass 
  Dump External Object class"
  input DAE.Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    local
      String fstr;
      Absyn.Path fpath;
      DAE.Element constr,destr;
      list<DAE.Element> dae;
      tuple<DAE.TType, Option<Absyn.Path>> t;
    case DAE.EXTOBJECTCLASS(path = fpath,constructor=constr,destructor=destr)
      equation 
        Print.printBuf("class ");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf("\n extends ExternalObject;\n");
        dumpFunction(constr);
        dumpFunction(destr);
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpExtObjectClass;

public function printInlineTypeStr ""
input DAE.InlineType it;
output String str;
algorithm 
  str := matchcontinue(it)
    case(DAE.NO_INLINE) then "No inline";
      case(DAE.AFTER_INDEX_RED_INLINE) then "Inline after index reduction";
        case(DAE.NORM_INLINE) then "Inline before index reduction";
  end matchcontinue;
end printInlineTypeStr;

public function derivativeCondStr "
Author BZ 
Function for prinding conditions
"
input DAE.derivativeCond dc;
output String str;
algorithm str := matchcontinue(dc)
  case(DAE.NO_DERIVATIVE(e))
    local DAE.Exp e;
      equation
        str  = "noDerivative(" +& Exp.printExpStr(e) +& ")";
      then
        str;
  case(DAE.ZERO_DERIVATIVE) then "zeroDerivative";
  end matchcontinue;
end derivativeCondStr;

public function dumpDerivativeCond "debug function "
input list<tuple<Integer,DAE.derivativeCond>> conditionRefs;
output list<String> oStrings;
algorithm oStrings := matchcontinue( conditionRefs)
  local
    DAE.derivativeCond derCond;
    String s1;
    Integer name;
  case({}) then {};    
  case((name,derCond)::conditionRefs) 
    equation
    oStrings = dumpDerivativeCond(conditionRefs);
    s1 = derivativeCondStr(derCond);
    s1 = intString(name) +& " = " +& s1;
    then
      s1::oStrings;
  end matchcontinue;
end dumpDerivativeCond;

protected function dumpFunction 
"function: dumpFunction 
  Dump function"
  input DAE.Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    local
      String fstr;
      Absyn.Path fpath;
      list<DAE.Element> dae;
      DAE.Type t;
    case DAE.FUNCTION(path = fpath,functions = (DAE.FUNCTION_DEF(DAE.DAE(elementLst = dae))::_),type_ = t)
      equation 
        Print.printBuf("function ");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf("\n");
        dumpElements(dae);
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n\n");
      then
        ();
      case DAE.FUNCTION(path = fpath,functions = (DAE.FUNCTION_EXT(body = DAE.DAE(elementLst = dae))::_),type_ = t)
       local String fstr,daestr,str;
      equation 
        fstr = Absyn.pathString(fpath);
        daestr = dumpElementsStr(dae);
        str = Util.stringAppendList({"function ",fstr,"\n",daestr,"\nexternal \"C\";\nend ",fstr,";\n\n"});
        Print.printBuf(str);
      then
        ();
    case DAE.RECORD_CONSTRUCTOR(path = fpath)
      equation 
        Print.printBuf("record ");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf("\n");
        Print.printBuf("...\n");
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n\n");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpFunction;

public function dumpFunctionStr "function: dumpFunctionStr
 
  Dump function to a string.
"
  input DAE.Element inElement;
  output String outString;
algorithm 
  outString := matchcontinue (inElement)
    local
      String fstr,daestr,str;
      Absyn.Path fpath;
      list<DAE.Element> dae;
      DAE.Type t;
      String s1,s2;
      case(inElement)
        equation
          s1 = Print.getString();
          Print.clearBuf();
          dumpFunction(inElement);
          s2 = Print.getString();
          Print.printBuf(s1);
          then
            s2;
    case _ then ""; 
  end matchcontinue;
end dumpFunctionStr;

protected function dumpExtObjClassStr 
"function: dumpExtObjStr 
  Dump external object class to a string."
  input DAE.Element inElement;
  output String outString;
algorithm 
  outString := matchcontinue (inElement)
    local
      String fstr,daestr,str,c_str,d_str;
      Absyn.Path fpath;
      list<DAE.Element> dae;
      DAE.Element constr,destr;
      DAE.Type t;
    case DAE.EXTOBJECTCLASS(path = fpath,constructor = constr, destructor = destr)
      equation 
        fstr = Absyn.pathString(fpath);
        c_str = dumpFunctionStr(constr);
        d_str = dumpFunctionStr(destr);
        str = Util.stringAppendList({"class  ",fstr,"\n  extends ExternalObject;\n",c_str,
          d_str,"end ",fstr,";\n"});
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpExtObjClassStr;

protected function ppStatement 
"function: ppStatement 
  Prettyprint an algorithm statement"
  input DAE.Statement alg;
algorithm 
  ppStmt(alg, 2);
end ppStatement;

public function ppStatementStr 
"function: ppStatementStr 
  Prettyprint an algorithm statement to a string."
  input DAE.Statement alg;
  output String str;
algorithm 
  str := ppStmtStr(alg, 2);
end ppStatementStr;

protected function ppStmt 
"function: ppStmt 
  Helper function to ppStatement."
  input DAE.Statement inStatement;
  input Integer inInteger;
algorithm 
  _ := matchcontinue (inStatement,inInteger)
    local
      DAE.ComponentRef c;
      DAE.Exp e,cond,msg,e2;
      Integer i,i_1;
      String s1,s2,s3,str,id;
      list<String> es;
      list<DAE.Exp> expl;
      list<DAE.Statement> then_,stmts;
      DAE.Statement stmt;
      Algorithm.Else else_;
    case (DAE.STMT_ASSIGN(exp1 = e2 as DAE.ASUB(_,_),exp = e),i) local DAE.Exp ae1,ae2;
      equation 
        indent(i);
        Exp.printExp(e2);
        Print.printBuf(" := ");
        Exp.printExp(e); 
        Print.printBuf(";\n");
      then
        ();
    case (DAE.STMT_ASSIGN(exp1 = e2 as DAE.CREF(c,_),exp = e),i) 
      equation 
        indent(i);
        Exp.printComponentRef(c);
        Print.printBuf(" := ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        (); 
    case (DAE.STMT_ASSIGN_ARR(componentRef = c,exp = e),i)
      equation 
        indent(i);
        Exp.printComponentRef(c);
        Print.printBuf(" := ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = expl,exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printExpStr(e);
        es = Util.listMap(expl, Exp.printExpStr);
        s3 = Util.stringDelimitList(es, ", ");
        str = Util.stringAppendList({s1,"(",s3,") := ",s2,";\n"});
        Print.printBuf(str);
      then
        ();
    case (DAE.STMT_IF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        indent(i);
        Print.printBuf("if ");
        Exp.printExp(e);
        Print.printBuf(" then\n");
        i_1 = i + 2;
        ppStmtList(then_, i_1);
        ppElse(else_, i);
        indent(i);
        Print.printBuf("end if;\n");
      then
        ();
    case (DAE.STMT_FOR(ident = id,exp = e,statementLst = stmts),i)
      equation 
        indent(i);
        Print.printBuf("for ");
        Print.printBuf(id);
        Print.printBuf(" in ");
        Exp.printExp(e);
        Print.printBuf(" loop\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
        indent(i);
        Print.printBuf("end for;\n");
      then
        ();
    case (DAE.STMT_WHILE(exp = e,statementLst = stmts),i)
      equation 
        indent(i);
        Print.printBuf("while ");
        Exp.printExp(e);
        Print.printBuf(" loop\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
        indent(i);
        Print.printBuf("end while;\n");
      then
        ();
    case (stmt as DAE.STMT_WHEN(exp = _),i)
      equation 
        indent(i);
        Print.printBuf(ppWhenStmtStr(stmt,1));
      then
        ();
    case (DAE.STMT_ASSERT(cond = cond,msg = msg),i)
      equation 
        indent(i);
        Print.printBuf("assert( ");
        Exp.printExp(cond);
        Print.printBuf(", ");
        Exp.printExp(msg);
        Print.printBuf(");\n");
      then
        ();
    case (DAE.STMT_BREAK(),i)
      equation 
        indent(i);
        Print.printBuf("break;\n");
      then
        ();
    case (DAE.STMT_REINIT(e1,e2),i)
           local DAE.Exp e1,e2;
      equation 
        indent(i);
        Print.printBuf("reinit(");
        Exp.printExp(e1); 
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(");\n");         
      then
        ();
    case (_,i)
      equation 
        indent(i);
        Print.printBuf("**ALGORITHM**;\n");
      then
        ();
  end matchcontinue;
end ppStmt;


protected function ppWhenStmtStr
  input DAE.Statement inStatement;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStatement,inInteger)
    local
      String s1,s2,s3,s4,s5,s6,str,s7,s8,s9,s10,s11,id,cond_str,msg_str;
      DAE.ComponentRef c;
      DAE.Exp e,cond,msg;
      Integer i,i_1;
      list<String> es;
      list<DAE.Exp> expl;
      list<DAE.Statement> then_,stmts;
      DAE.Statement stmt;
      Algorithm.Else else_;
    case (DAE.STMT_WHEN(exp = e,statementLst = stmts, elseWhen=NONE),i)
      equation 
        s3 = stringAppend("when ",Exp.printExpStr(e));
        s5 = stringAppend(s3, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = indentStr(i);
        s9 = stringAppend(s7, s8);
        str = stringAppend(s9, "end when;\n");
      then
        str;
    case (DAE.STMT_WHEN(exp = e,statementLst = stmts, elseWhen=SOME(stmt)),i)
      equation 
        s3 = Exp.printExpStr(e);
        s4 = stringAppend("when ", s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppWhenStmtStr(stmt,i);
        s9 = stringAppend(indentStr(i),"else");
        s10= stringAppend(s7,s9);
        str = stringAppend(s10, s8);
      then
        str;
   end matchcontinue;
end ppWhenStmtStr;

protected function ppStmtStr "function: ppStmtStr
 
  Helper function to pp_statement_str
"
  input DAE.Statement inStatement;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStatement,inInteger)
    local
      String s1,s2,s3,s4,s5,s6,str,s7,s8,s9,s10,s11,id,cond_str,msg_str;
      DAE.ComponentRef c;
      DAE.Exp e,cond,msg,e2;
      Integer i,i_1;
      list<String> es;
      list<DAE.Exp> expl;
      list<DAE.Statement> then_,stmts;
      DAE.Statement stmt;
      Algorithm.Else else_;
    case (DAE.STMT_ASSIGN(exp1 = e2 as DAE.CREF(c,_),exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printComponentRefStr(c);
        s3 = stringAppend(s1, s2);
        s4 = stringAppend(s3, " := ");
        s5 = Exp.printExpStr(e);
        s6 = stringAppend(s4, s5);
        str = stringAppend(s6, ";\n");
      then
        str;
    case (DAE.STMT_ASSIGN(exp1 = e2 as DAE.ASUB(_,_),exp = e),i) local DAE.Exp ae1,ae2;
      equation 
        s1 = indentStr(i);
        s2 = Exp.printExpStr(e2);
        s3 = stringAppend(s1, s2);
        s4 = stringAppend(s3, " := ");
        s5 = Exp.printExpStr(e); 
        s6 = stringAppend(s4, s5);
        str = stringAppend(s6, ";\n");
      then
        str;
    
    case (DAE.STMT_ASSIGN_ARR(componentRef = c,exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printComponentRefStr(c);
        s3 = stringAppend(s1, s2);
        s4 = stringAppend(s3, " := ");
        s5 = Exp.printExpStr(e);
        s6 = stringAppend(s4, s5);
        str = stringAppend(s6, ";\n");
      then
        str;
    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = expl,exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printExpStr(e);
        es = Util.listMap(expl, Exp.printExpStr);
        s3 = Util.stringDelimitList(es, ", ");
        str = Util.stringAppendList({s1,"(",s3,") := ",s2,";\n"});
      then
        str;
    case (DAE.STMT_IF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "if ");
        s3 = Exp.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(then_, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppElseStr(else_, i);
        s9 = stringAppend(s7, s8);
        s10 = indentStr(i);
        s11 = stringAppend(s9, s10);
        str = stringAppend(s11, "end if;\n");
      then
        str;
    case (DAE.STMT_FOR(ident = id,exp = e,statementLst = stmts),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "for ");
        s3 = stringAppend(s2, id);
        s4 = stringAppend(s3, " in ");
        s5 = Exp.printExpStr(e);
        s6 = stringAppend(s4, s5);
        s7 = stringAppend(s6, " loop\n");
        i_1 = i + 2;
        s8 = ppStmtListStr(stmts, i_1);
        s9 = stringAppend(s7, s8);
        s10 = indentStr(i);
        s11 = stringAppend(s9, s10);
        str = stringAppend(s11, "end for;\n");
      then
        str;
    case (DAE.STMT_WHILE(exp = e,statementLst = stmts),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "while ");
        s3 = Exp.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " loop\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = indentStr(i);
        s9 = stringAppend(s7, s8);
        str = stringAppend(s9, "end while;\n");
      then
        str;
    case (stmt as DAE.STMT_WHEN(exp = _),i)
      equation 
        s1 = indentStr(i);
        s2 = ppWhenStmtStr(stmt,i);
        str = stringAppend(s1,s2);
      then
        str;
    case (DAE.STMT_ASSERT(cond = cond,msg = msg),i)
      equation 
        s1 = indentStr(i);
        cond_str = Exp.printExpStr(cond);
        msg_str = Exp.printExpStr(msg);
        str = Util.stringAppendList({s1,"assert(",cond_str,", ",msg_str,");\n"});
      then
        str;

    case (DAE.STMT_NORETCALL(e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printExpStr(e);
        str = Util.stringAppendList({s1,s2,"\n"});
      then
        str;

    case (DAE.STMT_BREAK(),i)
      equation 
        s1 = indentStr(i);
        str = stringAppend(s1, "break;\n");
      then
        str;
    case (DAE.STMT_REINIT(e1,e2),i)
      local DAE.Exp e1,e2; String e1_str,e2_str;
        equation
          s1 = indentStr(i);
          e1_str = Exp.printExpStr(e1);
          e2_str = Exp.printExpStr(e2);
          str = Util.stringAppendList({s1,"reinit(",e1_str,", ",e2_str,");\n"});
        then str;
    case (_,i)
      equation 
        s1 = indentStr(i);
        str = stringAppend(s1, "**ALGORITHM COULD NOT BE GENERATED(DAE.mo)**;\n");
      then
        str;
  end matchcontinue;
end ppStmtStr;

protected function ppStmtList "function: ppStmtList
 
  Helper function to pp_stmt
"
  input list<DAE.Statement> inAlgorithmStatementLst;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inAlgorithmStatementLst,inInteger)
    local
      DAE.Statement stmt;
      list<DAE.Statement> stmts;
      Integer i;
    case ({},_) then (); 
    case ((stmt :: stmts),i)
      equation 
        ppStmt(stmt, i);
        ppStmtList(stmts, i);
      then
        ();
  end matchcontinue;
end ppStmtList;

protected function ppStmtListStr "function: ppStmtListStr
 
  Helper function to pp_stmt_str
"
  input list<DAE.Statement> inAlgorithmStatementLst;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAlgorithmStatementLst,inInteger)
    local
      String s1,s2,str;
      DAE.Statement stmt;
      list<DAE.Statement> stmts;
      Integer i;
    case ({},_) then ""; 
    case ((stmt :: stmts),i)
      equation 
        s1 = ppStmtStr(stmt, i);
        s2 = ppStmtListStr(stmts, i);
        str = stringAppend(s1, s2);
      then
        str;
  end matchcontinue;
end ppStmtListStr;

protected function ppElse "function: ppElse
 
  Helper function to pp_stmt
"
  input Algorithm.Else inElse;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inElse,inInteger)
    local
      Integer i_1,i;
      DAE.Exp e;
      list<DAE.Statement> then_,stmts;
      Algorithm.Else else_;
    case (DAE.NOELSE(),_) then (); 
    case (DAE.ELSEIF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        indent(i);
        Print.printBuf("elseif ");
        Exp.printExp(e);
        Print.printBuf(" then\n");
        i_1 = i + 2;
        ppStmtList(then_, i_1);
        ppElse(else_, i);
      then
        ();
    case (DAE.ELSE(statementLst = stmts),i)
      equation 
        indent(i);
        Print.printBuf("else\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
      then
        ();
  end matchcontinue;
end ppElse;

protected function ppElseStr "function: pp_else
 
  Helper function to ppElseStr
"
  input Algorithm.Else inElse;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElse,inInteger)
    local
      String s1,s2,s3,s4,s5,s6,s7,s8,str;
      Integer i_1,i;
      DAE.Exp e;
      list<DAE.Statement> then_,stmts;
      Algorithm.Else else_;
    case (DAE.NOELSE(),_) then ""; 
    case (DAE.ELSEIF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "elseif ");
        s3 = Exp.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(then_, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppElseStr(else_, i);
        str = stringAppend(s7, s8);
      then
        str;
    case (DAE.ELSE(statementLst = stmts),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "else\n");
        i_1 = i + 2;
        s3 = ppStmtListStr(stmts, i_1);
        str = stringAppend(s2, s3);
      then
        str;
  end matchcontinue;
end ppElseStr;

protected function indent "function: indent
 
  Print an indentation, given an indent level.
"
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inInteger)
    local Integer i_1,i;
    case 0 then (); 
    case i
      equation 
        Print.printBuf(" ");
        i_1 = i - 1;
        indent(i_1);
      then
        ();
  end matchcontinue;
end indent;

protected function indentStr "function: indentStr
 
  Print an indentation to a string, given an indent level.
"
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger)
    local
      Integer i_1,i;
      String s1,str;
    case 0 then ""; 
    case i
      equation 
        i_1 = i - 1;
        s1 = indentStr(i_1);
        str = stringAppend(" ", s1);
      then
        str;
  end matchcontinue;
end indentStr;

public function getMatchingElements "function getMatchingElements
  author:  LS 
 
  Retrive the elements for which the function given as second argument
  succeeds.
"
  input list<DAE.Element> elist;
  input FuncTypeElementTo cond;
  output list<DAE.Element> elist;
  partial function FuncTypeElementTo
    input DAE.Element inElement;
  end FuncTypeElementTo;
algorithm 
  elist := Util.listFilter(elist, cond);
end getMatchingElements;

public function getAllMatchingElements "function getAllMatchingElements
  author:  PA 
 
  Similar to getMatchingElements but traverses down in COMP elements also.
"
  input list<DAE.Element> elist;
  input FuncTypeElementTo cond;
  output list<DAE.Element> elist;
  partial function FuncTypeElementTo
    input DAE.Element inElement;
  end FuncTypeElementTo;
algorithm 
  elist := matchcontinue(elist,cond)
    local
      list<DAE.Element> elist2;
      DAE.Element e;
    case({},_) then {};
    case(DAE.COMP(_,DAE.DAE(elist))::elist2,cond) equation
      elist= getAllMatchingElements(elist,cond);
      elist2 = getAllMatchingElements(elist2,cond);
      elist2 = listAppend(elist,elist2);
      then elist2;
    case(e::elist,cond) equation
      cond(e);
      elist = getAllMatchingElements(elist,cond);
    then e::elist;

    case(e::elist,cond) equation
      elist = getAllMatchingElements(elist,cond);
    then elist;
  end matchcontinue;
end getAllMatchingElements;

public function isNormalInlineFunc "
Author BZ
"
input DAE.Element inElem;
output Boolean b;
algorithm 
  b := matchcontinue(inElem)
    case(DAE.FUNCTION(inlineType=DAE.NORM_INLINE)) then true;
    case(_) then false;
  end matchcontinue;
end isNormalInlineFunc;
public function findAllMatchingElements "function findAllMatchingElements
  author:  adrpo 
 
  Similar to getMatchingElements but gets two conditions and returns two lists.
"
  input list<DAE.Element> elist;
  input FuncTypeElementTo cond1;
  input FuncTypeElementTo cond2;  
  output list<DAE.Element> firstList;
  output list<DAE.Element> secondList;
  partial function FuncTypeElementTo
    input DAE.Element inElement;
  end FuncTypeElementTo;
algorithm 
  (firstList,secondList) := matchcontinue(elist,cond1,cond2)
    local
      list<DAE.Element> rest, lst, elist1, elist2, elist1a, elist2a;
      DAE.Element e;
    
    // handle the empty case
    case({},_,_) then ({},{});
    // handle the dive-in case
    case(DAE.COMP(_,DAE.DAE(lst))::rest,cond1,cond2) 
      equation
        (elist1,elist2) = findAllMatchingElements(lst,cond1,cond2);
        (elist1a,elist2a) = findAllMatchingElements(rest,cond1,cond2);
        elist1 = listAppend(elist1,elist1a);
        elist2 = listAppend(elist2,elist2a);
      then (elist1,elist2);
    // handle both first and second condition true!
    case(e::rest,cond1,cond2) 
      equation
        cond1(e);
        cond2(e);
        (elist1,elist2) = findAllMatchingElements(rest,cond1,cond2);
      then (e::elist1,e::elist2);
    // handle first condition true
    case(e::rest,cond1,cond2) 
      equation
        cond1(e);
        (elist1,elist2) = findAllMatchingElements(rest,cond1,cond2);
      then (e::elist1,elist2);
    // handle the second condition
    case(e::rest,cond1,cond2) 
      equation
        cond2(e);
        (elist1,elist2) = findAllMatchingElements(rest,cond1,cond2);
      then (elist1,e::elist2);
    // move to next element.
    case(e::rest,cond1,cond2) 
      equation
        (elist1,elist2) = findAllMatchingElements(rest,cond1,cond2);
      then (elist1,elist2);
  end matchcontinue;
end findAllMatchingElements;

public function isAfterIndexInlineFunc "
Author BZ
"
input DAE.Element inElem;
output Boolean b;
algorithm 
  b := matchcontinue(inElem)
    case(DAE.FUNCTION(inlineType=DAE.AFTER_INDEX_RED_INLINE)) then true;
    case(_) then false;
  end matchcontinue;
end isAfterIndexInlineFunc;

public function isEqualInlineType "
Author BZ
"
input DAE.InlineType a1,a2;
output Boolean b;
algorithm 
  b := matchcontinue(a1,a2)
    case(DAE.NO_INLINE,DAE.NO_INLINE) then true;
    case(DAE.NORM_INLINE,DAE.NORM_INLINE) then true;
    case(DAE.AFTER_INDEX_RED_INLINE,DAE.AFTER_INDEX_RED_INLINE) then true;
    case(_,_) then false;
  end matchcontinue;
end isEqualInlineType;

public function isParameter "function isParameter
  author: LS 
  Succeeds if element is parameter.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case DAE.VAR(kind = DAE.PARAM()) then ();
  end matchcontinue;
end isParameter;

public function isParameterOrConstant "
  author: BZ 2008-06
  Succeeds if element is constant/parameter.
"
  input DAE.Element inElement;
  output Boolean b;
algorithm 
  b:=
  matchcontinue (inElement)
    case DAE.VAR(kind = DAE.CONST()) then true; 
    case DAE.VAR(kind = DAE.PARAM()) then true;
    case(_) then false;
  end matchcontinue;
end isParameterOrConstant;

public function isInnerVar "function isInnerVar
  author: PA 
 
  Succeeds if element is a variable with prefix inner.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case DAE.VAR(innerOuter = Absyn.INNER()) then ();
    case DAE.VAR(innerOuter = Absyn.INNEROUTER())then ();
  end matchcontinue;
end isInnerVar;

public function isOuterVar "function isOuterVar
  author: PA 
  Succeeds if element is a variable with prefix outer.
"
  input DAE.Element inElement;
algorithm _:= matchcontinue (inElement)
    case DAE.VAR(innerOuter = Absyn.OUTER()) then ();
    /* FIXME? adrpo: do we need this? case VAR(innerOuter = Absyn.INNEROUTER()) then (); */
  end matchcontinue;
end isOuterVar;

public function isComp "function isComp
  author: LS 
 
  Succeeds if element is component, COMP.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case DAE.COMP(ident = _) then (); 
  end matchcontinue;
end isComp;

public function getOutputVars "function getOutputVars
  author: LS 
 
  Retrieve all output variables from an Element list.
"
  input list<DAE.Element> vl;
  output list<DAE.Element> vl_1;
  list<DAE.Element> vl_1;
algorithm 
  vl_1 := getMatchingElements(vl, isOutputVar);
end getOutputVars;

public function getProtectedVars "
  author: PA
 
  Retrieve all protected variables from an Element list.
"
  input list<DAE.Element> vl;
  output list<DAE.Element> vl_1;
  list<DAE.Element> vl_1;
algorithm 
  vl_1 := getMatchingElements(vl, isProtectedVar);
end getProtectedVars;

public function getBidirVars "function get_output_vars
  author: LS 
 
  Retrieve all bidirectional variables from an Element list.
"
  input list<DAE.Element> vl;
  output list<DAE.Element> vl_1;
  list<DAE.Element> vl_1;
algorithm 
  vl_1 := getMatchingElements(vl, isBidirVar);
end getBidirVars;

public function getInputVars "
  Retrieve all input variables from an Element list.
"
  input list<DAE.Element> vl;
  output list<DAE.Element> vl_1;
  list<DAE.Element> vl_1;
algorithm 
  vl_1 := getMatchingElements(vl, isInput);
end getInputVars;

public function setComponentTypeOpt "
  
  See setComponentType
"
  input list<DAE.Element> inElementLst;
  input Option<Absyn.Path> inPath;
  output list<DAE.Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElementLst,inPath)
      local Absyn.Path p;
    case (inElementLst,SOME(p)) equation
      outElementLst = setComponentType(inElementLst,p);
    then outElementLst ;
    case(inElementLst,NONE) then inElementLst;
  end matchcontinue;
end setComponentTypeOpt;

public function setComponentType "
  This function takes a dae element list and a type name and 
  inserts the type name into each Var (variable) of the dae.
  This type name is the origin of the variable.
"
  input list<DAE.Element> inElementLst;
  input Absyn.Path inPath;
  output list<DAE.Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElementLst,inPath)
    local
      list<DAE.Element> xs_1,xs;
      DAE.ComponentRef cr;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      DAE.InstDims dim;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.Element x;
			DAE.VarProtection prot;
			Option<DAE.Exp> bind;
      list<Absyn.Path> lst;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Absyn.Path newtype;
      Absyn.InnerOuter io;
    case ({},_) then {}; 
    case ((DAE.VAR(componentRef = cr,
               kind = kind,
               direction = dir, 
               protection = prot,
               ty = tp,
               binding = bind,
               dims = dim,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix,
               pathLst = lst,
               variableAttributesOption = dae_var_attr,
               absynCommentOption = comment,
               innerOuter=io) :: xs),newtype)
      equation 
        xs_1 = setComponentType(xs, newtype);
      then
        (DAE.VAR(cr,kind,dir,prot,tp,bind,dim,flowPrefix,streamPrefix,(newtype :: lst),dae_var_attr,comment,io) :: xs_1);
        
    case ((x :: xs),newtype)
      equation 
        xs_1 = setComponentType(xs, newtype);
      then
        (x :: xs_1);
  end matchcontinue;
end setComponentType;

public function isOutputVar 
"Succeeds if Element is an output variable."
  input DAE.Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.OUTPUT()) then ();
  end matchcontinue;
end isOutputVar;

public function isProtectedVar 
"Succeeds if Element is a protected variable."
  input DAE.Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    case DAE.VAR(protection=DAE.PROTECTED()) then (); 
  end matchcontinue;
end isProtectedVar;

public function isPublicVar "
  Succeeds if Element is a public variable.
"
  input DAE.Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    case DAE.VAR(protection=DAE.PUBLIC()) then (); 
  end matchcontinue;
end isPublicVar;

public function isBidirVar "
  Succeeds if Element is a bidirectional variable.
"
  input DAE.Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.BIDIR()) then ();
  end matchcontinue;
end isBidirVar;

public function isInputVar "
  Succeeds if Element is an input variable.
"
  input DAE.Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.INPUT()) then ();
  end matchcontinue;
end isInputVar;

public function isInput "
  Succeeds if Element is an input .
"
  input DAE.Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    case DAE.VAR(direction = DAE.INPUT()) then ();
  end matchcontinue;
end isInput;

protected function isNotVar "
  Succeeds if Element is not a variable.
"
  input DAE.Element e;
algorithm 
  failure(isVar(e));
end isNotVar;

public function isVar "
  Succeeds if Element is a variable.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case DAE.VAR(componentRef = _) then (); 
  end matchcontinue;
end isVar;

public function isFunctionRefVar "
  return true if the element is a function reference variable
"
  input DAE.Element inElem;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inElem)
    case DAE.VAR(ty = (DAE.T_FUNCTION(_,_,_),_)) then true;
    case _ then false;
  end matchcontinue;
end isFunctionRefVar;

public function isAlgorithm "function: isAlgorithm
  author: LS
 
  Succeeds if Element is an algorithm.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case DAE.ALGORITHM(algorithm_ = _) then (); 
  end matchcontinue;
end isAlgorithm;

public function isFunction "function: isFunction
  author: LS
 
  Succeeds if Element is not a function.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case DAE.FUNCTION(path = _) then (); 
    case DAE.RECORD_CONSTRUCTOR(path = _) then (); 
  end matchcontinue;
end isFunction;

public function dumpDebug "

 Dump the data structures in a 
 paranthesised way

"
  input DAE.DAElist inDAElist;
algorithm 
  _:=
  matchcontinue (inDAElist)
    local list<DAE.Element> elist;
    case DAE.DAE(elementLst = elist)
      equation 
        Print.printBuf("DAE(");
        dumpDebugElist(elist);
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end dumpDebug;

protected function dumpDebugElist "function: dumpDebugElist
 
  Helper function to dump_debug.
"
  input list<DAE.Element> inElementLst;
algorithm 
  _:=
  matchcontinue (inElementLst)
    local
      DAE.Element first;
      list<DAE.Element> rest;
    case {} then (); 
    case (first :: rest)
      equation 
        dumpDebugElement(first);
        Print.printBuf("\n");
        dumpDebugElist(rest);
      then
        ();
  end matchcontinue;
end dumpDebugElist;

public function dumpDebugDAE ""
  input DAE.DAElist dae;
  output String str;
algorithm str := matchcontinue(dae)
  local
    list<DAE.Element> elems;
  case(DAE.DAE(elems)) 
    equation
      Print.clearBuf();
      dumpDebugElist(elems);
      str = Print.getString();
    then
      str;
end matchcontinue;
end dumpDebugDAE;

public function dumpDebugElement "function: dumpDebugElement
 
  Dump element using parenthesis.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      String comment_str,tmp_str,n,fstr;
      DAE.ComponentRef cr,cr1,cr2;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type t;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Exp e,exp,e1,e2;
      DAE.DAElist l;
      Absyn.Path fpath;
    case DAE.VAR(componentRef = cr,
             kind = vk,
             direction = vd,
             binding = NONE,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        dumpKind(vk); 
        comment_str = dumpCommentOptionStr(comment);
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        tmp_str = dumpVariableAttributesStr(dae_var_attr);
        Print.printBuf(tmp_str);
        Print.printBuf(")");
      then
        ();
    case DAE.VAR(componentRef = cr,
             kind = vk,
             direction = vd,
             binding = SOME(e),
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        dumpKind(vk);
        Print.printBuf(", binding: ");
        Exp.printExp(e);
        comment_str = dumpCommentOptionStr(comment);
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        tmp_str = dumpVariableAttributesStr(dae_var_attr);        
        Print.printBuf(tmp_str);
        Print.printBuf(")");
      then
        ();
    case DAE.DEFINE(componentRef = cr,exp = exp)
      equation 
        Print.printBuf("DEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        Exp.printExp(exp);
        Print.printBuf(")");
      then
        ();
    case DAE.INITIALDEFINE(componentRef = cr,exp = exp)
      equation 
        Print.printBuf("INITIALDEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        Exp.printExp(exp);
        Print.printBuf(")");
      then
        ();
    case DAE.EQUATION(exp = e1,scalar = e2)
      equation 
        Print.printBuf("EQUATION(");
        Exp.printExp(e1);
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(")");
      then
        ();
              
     case DAE.EQUEQUATION(cr1,cr2)
      equation 
        Print.printBuf("EQUATION(");
        Exp.printComponentRef(cr1);
        Print.printBuf(",");
        Exp.printComponentRef(cr2);
        Print.printBuf(")");
      then
        ();
    case DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)
      equation 
        Print.printBuf("INITIALEQUATION(");
        Exp.printExp(e1);
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.ALGORITHM(algorithm_ = _)
      equation 
        Print.printBuf("ALGORITHM()");
      then
        ();
    case DAE.INITIALALGORITHM(algorithm_ = _)
      equation 
        Print.printBuf("INITIALALGORITHM()");
      then
        ();
    case DAE.COMP(ident = n,dAElist = l)
      equation 
        Print.printBuf("COMP(");
        Print.printBuf(n);
        Print.printBuf(",");
        dumpDebug(l);
        Print.printBuf(")");
      then
        ();
     case DAE.FUNCTION(path = fpath,functions = (DAE.FUNCTION_DEF(body = l)::_),type_ = t)
      equation 
        Print.printBuf("FUNCTION(");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf(",");
        Print.printBuf(Types.printTypeStr(t));
        Print.printBuf(",");
        dumpDebug(l);
        Print.printBuf(")");
      then
        ();
    case DAE.RECORD_CONSTRUCTOR(path = fpath,type_ = t)
      equation 
        Print.printBuf("RECORD_CONSTRUCTOR(");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf(",");
        Print.printBuf(Types.printTypeStr(t));
        Print.printBuf(")");
      then
        ();
    case _
      equation 
        Print.printBuf("UNKNOWN ");
      then
        ();
  end matchcontinue;
end dumpDebugElement;

public function findElement "function: findElement
 
  Search for an element for which the function passed as second 
  argument succeds. If no element is found return NONE.
"
  input list<DAE.Element> inElementLst;
  input FuncTypeElementTo inFuncTypeElementTo;
  output Option<DAE.Element> outElementOption;
  partial function FuncTypeElementTo
    input DAE.Element inElement;
  end FuncTypeElementTo;
algorithm 
  outElementOption:=
  matchcontinue (inElementLst,inFuncTypeElementTo)
    local
      DAE.Element e;
      list<DAE.Element> rest;
      FuncTypeElementTo f;
      Option<DAE.Element> e_1;
    case ({},_) then NONE; 
    case ((e :: rest),f)
      equation 
        f(e);
      then
        SOME(e);
    case ((e :: rest),f)
      equation 
        failure(f(e));
        e_1 = findElement(rest, f);
      then
        e_1;
  end matchcontinue;
end findElement;

public function dumpGraphviz "
 Graphviz functions to visualize 
 the dae
"
  input DAE.DAElist dae;
  Graphviz.Node r;
algorithm 
  r := buildGraphviz(dae);
  Graphviz.dump(r);
end dumpGraphviz;

protected function buildGraphviz "function: buildGraphviz
 
  Builds the graphviz node from a dae list.
"
  input DAE.DAElist inDAElist;
  output Graphviz.Node outNode;
algorithm 
  outNode:=
  matchcontinue (inDAElist)
    local
      list<DAE.Element> vars,nonvars,els;
      list<Graphviz.Node> nonvarnodes,varnodes,nodelist;
    case DAE.DAE(elementLst = els)
      equation 
        vars = getMatchingElements(els, isVar);
        nonvars = getMatchingElements(els, isNotVar);
        nonvarnodes = buildGrList(nonvars);
        varnodes = buildGrVars(vars);
        nodelist = listAppend(nonvarnodes, varnodes);
      then
        Graphviz.NODE("DAE",{},nodelist);
  end matchcontinue;
end buildGraphviz;

protected function buildGrList "function buildGrList
 
  Helper function to build_graphviz.
"
  input list<DAE.Element> inElementLst;
  output list<Graphviz.Node> outGraphvizNodeLst;
algorithm 
  outGraphvizNodeLst:=
  matchcontinue (inElementLst)
    local
      Graphviz.Node node;
      list<Graphviz.Node> nodelist;
      DAE.Element el;
      list<DAE.Element> rest;
    case {} then {}; 
    case (el :: rest)
      equation 
        node = buildGrElement(el);
        nodelist = buildGrList(rest);
      then
        (node :: nodelist);
  end matchcontinue;
end buildGrList;

protected function buildGrVars "function buildGrVars
 
  Helper function to build_graphviz.
"
  input list<DAE.Element> inElementLst;
  output list<Graphviz.Node> outGraphvizNodeLst;
algorithm 
  outGraphvizNodeLst := matchcontinue (inElementLst)
    local
      list<String> strlist;
      list<DAE.Element> vars;
    case {} then {}; 
    case vars
      equation 
        (strlist,_) = buildGrStrlist(vars, buildGrVarStr, 10);
      then
        {Graphviz.LNODE("VARS",strlist,{Graphviz.box},{})};
  end matchcontinue;
end buildGrVars;

public function buildGrStrlist "function buildGrStrlist
 
  Helper function to build_graphviz.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input Integer inInteger;
  output list<String> outStringLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm 
  (outStringLst,outTypeALst):=
  matchcontinue (inTypeALst,inFuncTypeTypeAToString,inInteger)
    local
      list<Type_a> ignored,rest;
      FuncTypeType_aToString printer;
      Integer count,count_1;
      list<String> strlist;
      String str;
      Type_a var;
    case ({},_,_) then ({},{}); 
    case (ignored,printer,count)
      equation 
        (count <= 0) = true;
      then
        ({"..."},ignored);
    case ((var :: rest),printer,count)
      equation 
        (count > 0) = true;
        count_1 = count - 1;
        (strlist,ignored) = buildGrStrlist(rest, printer, count_1);
        str = printer(var);
      then
        ((str :: strlist),ignored);
  end matchcontinue;
end buildGrStrlist;

protected function buildGrVarStr "function buildGrVarStr
 
  Helper function to build_graphviz.
"
  input DAE.Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      String str,expstr,str_1,str_2;
      DAE.ComponentRef cr;
      DAE.Exp exp;
    case DAE.VAR(componentRef = cr,binding = NONE)
      equation 
        str = Exp.printComponentRefStr(cr);
      then
        str;
    case DAE.VAR(componentRef = cr,binding = SOME(exp))
      equation 
        str = Exp.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        str_1 = stringAppend(str, " = ");
        str_2 = stringAppend(str_1, expstr);
      then
        str_2;
  end matchcontinue;
end buildGrVarStr;

protected function printExpStrSpecial "function: printExpStrSpecial
 
  Prints an expression to a string suitable for graphviz.
"
  input DAE.Exp inExp;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExp)
    local
      String s_1,s_2,s,str;
      DAE.Exp exp;
    case DAE.SCONST(string = s)
      equation 
        s_1 = stringAppend("\\\"", s);
        s_2 = stringAppend(s_1, "\\\"");
      then
        s_2;
    case exp
      equation 
        str = Exp.printExpStr(exp);
      then
        str;
  end matchcontinue;
end printExpStrSpecial;

protected function buildGrElement "function: buildGrElement
 
  Builds a Graphviz.Node from an element.
"
  input DAE.Element inElement;
  output Graphviz.Node outNode;
algorithm 
  outNode := matchcontinue (inElement)
    local
      String crstr,vkstr,expstr,expstr_1,e1str,e2str,n,fstr;
      DAE.ComponentRef cr,cr1,cr2;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Exp exp,e1,e2;
      Graphviz.Node node;
      DAE.Type ty;
      DAE.DAElist dae;
      Absyn.Path fpath;
    case DAE.VAR(componentRef = cr,kind = vk,direction = vd,binding = NONE)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        vkstr = dumpKindStr(vk);
      then
        Graphviz.LNODE("VAR",{crstr,vkstr},{},{});
    case DAE.VAR(componentRef = cr,kind = vk,direction = vd,binding = SOME(exp))
      equation 
        crstr = Exp.printComponentRefStr(cr);
        vkstr = dumpKindStr(vk);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("VAR",{crstr,vkstr,expstr_1},{},{});
    case DAE.DEFINE(componentRef = cr,exp = exp)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("DEFINE",{crstr,expstr_1},{},{});
    case DAE.EQUATION(exp = e1,scalar = e2)
      equation 
        e1str = printExpStrSpecial(e1);
        e2str = printExpStrSpecial(e2);
      then
        Graphviz.LNODE("EQUATION",{e1str,"=",e2str},{},{});
    case DAE.EQUEQUATION(cr1,cr2)
      equation 
        e1str = printExpStrSpecial(DAE.CREF(cr1,DAE.ET_OTHER()));
        e2str = printExpStrSpecial(DAE.CREF(cr2,DAE.ET_OTHER()));
      then
        Graphviz.LNODE("EQUEQUATION",{e1str,"=",e2str},{},{});
    case DAE.ALGORITHM(algorithm_ = _) then Graphviz.NODE("ALGORITHM",{},{}); 
    case DAE.INITIALDEFINE(componentRef = cr,exp = exp)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("INITIALDEFINE",{crstr,expstr_1},{},{});
    case DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)
      equation 
        e1str = printExpStrSpecial(e1);
        e2str = printExpStrSpecial(e2);
      then
        Graphviz.LNODE("INITIALEQUATION",{e1str,"=",e2str},{},{});
    case DAE.INITIALALGORITHM(algorithm_ = _) then Graphviz.NODE("INITIALALGORITHM",{},{}); 
    case DAE.COMP(ident = n,dAElist = dae)
      equation 
        node = buildGraphviz(dae);
      then
        Graphviz.LNODE("COMP",{n},{},{node});
    case DAE.FUNCTION(path = fpath,functions = (DAE.FUNCTION_DEF(body = dae)::_),type_ = ty)
      equation 
        node = buildGraphviz(dae);
        fstr = Absyn.pathString(fpath);
      then
        Graphviz.LNODE("FUNCTION",{fstr},{},{node});
    case DAE.RECORD_CONSTRUCTOR(path = fpath)
      equation 
        fstr = Absyn.pathString(fpath);
      then
        Graphviz.LNODE("RECORD_CONSTRUCTOR",{fstr},{},{});
  end matchcontinue;
end buildGrElement;

public function getVariableBindingsStr "function: getVariableBindingsStr
 
  This function takes a `DAE.Element\' list and returns a comma separated 
  string of variable bindings.
  E.g. model A Real x=1; Real y=2; end A; => \"1,2\"
"
  input list<DAE.Element> elts;
  output String str;
  list<DAE.Element> varlst;
algorithm 
  varlst := getVariableList(elts);
  str := getBindingsStr(varlst);
end getVariableBindingsStr;

protected function getVariableList "function: getVariableList
 
  Return all variables from an Element list.
"
  input list<DAE.Element> inElementLst;
  output list<DAE.Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElementLst)
    local
      list<DAE.Element> res,lst;
      DAE.Element x;    
            
    /* adrpo: filter out records! */
    case ((x as DAE.VAR(ty = (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_))) :: lst)
      equation
        res = getVariableList(lst);
      then
        (res);   
              
    case ((x as DAE.VAR(_,_,_,_,_,_,_,_,_,_,_,_,_)) :: lst)
      equation 
        res = getVariableList(lst);
      then
        (x :: res);
    case (_ :: lst)
      equation 
        res = getVariableList(lst);
      then
        res;
    case {} then {}; 
  end matchcontinue;
end getVariableList;

protected function getBindingsStr "function: getBindingsStr
 
  Retrive the bindings from a list of Elements and output to a string.
"
  input list<DAE.Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      String expstr,s3,s4,str,s1,s2;
      DAE.Element v;
      DAE.ComponentRef cr;
      DAE.Exp e;
      list<DAE.Element> lst;
    case (((v as DAE.VAR(componentRef = cr,binding = SOME(e))) :: (lst as (_ :: _))))
      equation 
        expstr = Exp.printExpStr(e);
        s3 = stringAppend(expstr, ",");
        s4 = getBindingsStr(lst);
        str = stringAppend(s3, s4);
      then
        str;
    case (((v as DAE.VAR(componentRef = cr,binding = NONE)) :: (lst as (_ :: _))))
      equation 
        s1 = "-,";
        s2 = getBindingsStr(lst);
        str = stringAppend(s1, s2);
      then
        str;
    case ({(v as DAE.VAR(componentRef = cr,binding = SOME(e)))})
      equation 
        str = Exp.printExpStr(e);
      then
        str;
    case ({(v as DAE.VAR(componentRef = cr,binding = NONE))}) then ""; 
  end matchcontinue;
end getBindingsStr;

public function getBindings "function: getBindingsStr
Author: BZ, 2008-11
Get variable-bindings from element list.
"
  input list<DAE.Element> inElementLst;
  output list<DAE.ComponentRef> outc;
  output list<DAE.Exp> oute;
algorithm (outc,oute) := matchcontinue (inElementLst)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      case({}) then ({},{});
    case (DAE.VAR(componentRef = cr,binding = SOME(e)) :: inElementLst)
      equation 
        (outc,oute) = getBindings(inElementLst);
      then
        (cr::outc,e::oute);
    case (DAE.VAR(componentRef = cr,binding  = NONE) :: inElementLst) 
      equation
        (outc,oute) = getBindings(inElementLst);
      then (outc,oute);
    case (_) equation print(" error in getBindings \n"); then fail();  
  end matchcontinue;
end getBindings;

public function toFlow "function: toFlow
 
  Create a Flow, given a ClassInf.State and a boolean flow value.
"
  input Boolean inBoolean;
  input ClassInf.State inState;
  output DAE.Flow outFlow;
algorithm 
  outFlow:=
  matchcontinue (inBoolean,inState)
    case (true,_) then DAE.FLOW(); 
    case (_,ClassInf.CONNECTOR(string = _)) then DAE.NON_FLOW(); 
    case (_,_) then DAE.NON_CONNECTOR(); 
  end matchcontinue;
end toFlow;

public function toStream "function: toStram
  Create a Stream, given a ClassInf.State and a boolean stream value."
  input Boolean inBoolean;
  input ClassInf.State inState;
  output DAE.Stream outStream;
algorithm
  outFlow:=
  matchcontinue (inBoolean,inState)
    case (true,_) then DAE.STREAM();
    case (_,ClassInf.CONNECTOR(string = _)) then DAE.NON_STREAM();
    case (_,_) then DAE.NON_STREAM_CONNECTOR();
  end matchcontinue;
end toStream;

public function getFlowVariables "function: getFlowVariables
 
  Retrive the flow variables of an Element list.
"
  input list<DAE.Element> inElementLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inElementLst)
    local
      list<DAE.ComponentRef> res,res1,res1_1,res2;
      DAE.ComponentRef cr;
      list<DAE.Element> xs,lst;
      String id;
    case ({}) then {}; 
    case ((DAE.VAR(componentRef = cr,flowPrefix = DAE.FLOW()) :: xs))
      equation 
        res = getFlowVariables(xs);
      then
        (cr :: res);
    case ((DAE.COMP(ident = id,dAElist = DAE.DAE(elementLst = lst)) :: xs))
      equation 
        res1 = getFlowVariables(lst);
        res1_1 = getFlowVariables2(res1, id);
        res2 = getFlowVariables(xs);
        res = listAppend(res1_1, res2);
      then
        res;
    case ((_ :: xs))
      equation 
        res = getFlowVariables(xs);
      then
        res;
  end matchcontinue;
end getFlowVariables;

protected function getFlowVariables2 "function: getFlowVariables2
 
  Helper function to get_flow_variables.
"
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input String inIdent;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inExpComponentRefLst,inIdent)
    local
      String id;
      list<DAE.ComponentRef> res,xs;
      DAE.ComponentRef cr_1,cr;
    case ({},id) then {}; 
    case ((cr :: xs),id)
      equation 
        res = getFlowVariables2(xs, id);
        cr_1 = Exp.joinCrefs(DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}), cr);
      then
        (cr_1 :: res);
  end matchcontinue;
end getFlowVariables2;

public function getStreamVariables "function: getStreamVariables
  Retrive the stream variables of an Element list."
  input list<DAE.Element> inElementLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inElementLst)
    local
      list<DAE.ComponentRef> res,res1,res1_1,res2;
      DAE.ComponentRef cr;
      list<DAE.Element> xs,lst;
      String id;
    case ({}) then {};
    case ((DAE.VAR(componentRef = cr,streamPrefix = DAE.STREAM()) :: xs))
      equation
        res = getStreamVariables(xs);
      then
        (cr :: res);
    case ((DAE.COMP(ident = id,dAElist = DAE.DAE(elementLst = lst)) :: xs))
      equation
        res1 = getStreamVariables(lst);
        res1_1 = getStreamVariables2(res1, id);
        res2 = getStreamVariables(xs);
        res = listAppend(res1_1, res2);
      then
        res;
    case ((_ :: xs))
      equation
        res = getStreamVariables(xs);
      then
        res;
  end matchcontinue;
end getStreamVariables;

protected function getStreamVariables2 "function: getStreamVariables2

  Helper function to get_flow_variables.
"
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input String inIdent;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inExpComponentRefLst,inIdent)
    local
      String id;
      list<DAE.ComponentRef> res,xs;
      DAE.ComponentRef cr_1,cr;
    case ({},id) then {};
    case ((cr :: xs),id)
      equation
        res = getStreamVariables2(xs, id);
        cr_1 = Exp.joinCrefs(DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}), cr);
      then
        (cr_1 :: res);
  end matchcontinue;
end getStreamVariables2;

public function daeToRecordValue "function: daeToRecordValue
  Transforms a list of elements into a record value.
  TODO: This does not work for records inside records. 
  For a general approach we need to build an environment from the DAE and then
  instead investigate the variables and lookup their values from the created environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input list<DAE.Element> inElementLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm 
  (outCache, outValue) := matchcontinue (inCache,inEnv,inPath,inElementLst,inBoolean)
    local
      Absyn.Path cname;
      Values.Value value,res;
      list<Values.Value> vals;
      list<String> names;
      String cr_str;
      DAE.ComponentRef cr;
      DAE.Exp rhs;
      list<DAE.Element> rest;
      Boolean impl;
      Integer ix;
      DAE.Element el;
      Env.Cache cache;
      Env.Env env;
      
    case (cache,env,cname,{},_) then (cache,Values.RECORD(cname,{},{},-1));  /* impl */
    case (cache,env,cname,DAE.VAR(componentRef = cr, binding = SOME(rhs)) :: rest, impl)
      equation
        // Debug.fprintln("failtrace", "- DAEUtil.daeToRecordValue typeOfRHS: " +& Exp.typeOfString(rhs));        
        (cache, value,_) = Ceval.ceval(cache, env, rhs, impl, NONE, NONE, Ceval.MSG());
        (cache, Values.RECORD(cname,vals,names,ix)) = daeToRecordValue(cache, env, cname, rest, impl);
        cr_str = Exp.printComponentRefStr(cr);        
      then
        (cache,Values.RECORD(cname,(value :: vals),(cr_str :: names),ix));
    /*    
    case (cache,env,cname,(DAE.EQUATION(exp = DAE.CREF(componentRef = cr),scalar = rhs) :: rest),impl)
      equation 
        (cache, value,_) = Ceval.ceval(Env.emptyCache(),{}, rhs, impl, NONE, NONE, Ceval.MSG());
        (cache, Values.RECORD(cname,vals,names,ix)) = daeToRecordValue(cache, env, cname, rest, impl);
        cr_str = Exp.printComponentRefStr(cr);
      then
        (cache,Values.RECORD(cname,(value :: vals),(cr_str :: names),ix));
    */
    case (cache,env,_,el::_,_)
      local String str;
      equation
				true = RTOpts.debugFlag("failtrace");
        str = dumpDebugDAE(DAE.DAE({el}));
        Debug.fprintln("failtrace", "- DAEUtil.daeToRecordValue failed on: " +& str);
      then
        fail();
  end matchcontinue;
end daeToRecordValue;

public function toModelicaForm "function toModelicaForm.
 
  Transforms all variables from a.b.c to a_b_c, etc
"
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
algorithm 
  outDAElist:=
  matchcontinue (inDAElist)
    local list<DAE.Element> elts_1,elts;
    case (DAE.DAE(elementLst = elts))
      equation 
        elts_1 = toModelicaFormElts(elts);
      then
        DAE.DAE(elts_1);
  end matchcontinue;
end toModelicaForm;

protected function toModelicaFormElts "function: toModelicaFormElts
 
  Helper function to to_modelica_form.
"
  input list<DAE.Element> inElementLst;
  output list<DAE.Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElementLst)
    local
      String str,str_1,id;
      list<DAE.Element> elts_1,elts,welts_1,welts,telts_1,eelts_1,telts,eelts;
      Option<DAE.Exp> d_1,d,f;
      DAE.ComponentRef cr,cr_1;
      DAE.VarKind a;
      DAE.VarDirection b;
      DAE.Type t;
      DAE.InstDims e;
      DAE.Flow g;
      DAE.Stream streamPrefix;
      DAE.Stream s;
      DAE.Element elt_1,elt;
      DAE.DAElist dae_1,dae;
      DAE.VarProtection prot;
      list<Absyn.Path> h;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Exp e_1,e1_1,e2_1,e1,e2;
      Absyn.Path p;
      Absyn.InnerOuter io;
      list<DAE.Exp> conds, conds_1;
      list<list<DAE.Element>> trueBranches, trueBranches_1;
      list<DAE.Element> eelts;
      Boolean partialPrefix;
      list<DAE.FunctionDefinition> derFuncs;
      DAE.InlineType inlineType;
    case ({}) then {}; 
    case ((DAE.VAR(componentRef = cr,
               kind = a,
               direction = b,
               protection = prot,
               ty = t,
               binding = d,
               dims = e,
               flowPrefix = g,
               streamPrefix = streamPrefix,
               pathLst = h,
               variableAttributesOption = dae_var_attr,
               absynCommentOption = comment,
               innerOuter=io) :: elts))
      local
        DAE.ExpType ty;
      equation 
        str = Exp.printComponentRefStr(cr);
        str_1 = Util.stringReplaceChar(str, ".", "_");
        elts_1 = toModelicaFormElts(elts);
        d_1 = toModelicaFormExpOpt(d);
        ty = Exp.crefType(cr); 
      then
        (DAE.VAR(DAE.CREF_IDENT(str_1,ty,{}),a,b,prot,t,d_1,e,g,streamPrefix,h,dae_var_attr,
          comment,io) :: elts_1);
    case ((DAE.DEFINE(componentRef = cr,exp = e) :: elts))
      local
        DAE.Exp e;
      equation 
        e_1 = toModelicaFormExp(e);
        cr_1 = toModelicaFormCref(cr);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.DEFINE(cr_1,e_1) :: elts_1);
    case ((DAE.INITIALDEFINE(componentRef = cr,exp = e) :: elts))
      local
        DAE.Exp e;
      equation 
        e_1 = toModelicaFormExp(e);
        cr_1 = toModelicaFormCref(cr);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIALDEFINE(cr_1,e_1) :: elts_1);
    case ((DAE.EQUATION(exp = e1,scalar = e2) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.EQUATION(e1_1,e2_1) :: elts_1);
    case ((DAE.EQUEQUATION(cr1,cr2) :: elts))
      local
        DAE.ComponentRef cr1,cr2;
      equation 
         DAE.CREF(cr1,_) = toModelicaFormExp(DAE.CREF(cr1,DAE.ET_OTHER()));
         DAE.CREF(cr2,_) = toModelicaFormExp(DAE.CREF(cr2,DAE.ET_OTHER()));
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.EQUEQUATION(cr1,cr2) :: elts_1);
    case ((DAE.WHEN_EQUATION(condition = e1,equations = welts,elsewhen_ = SOME(elt)) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        welts_1 = toModelicaFormElts(welts);
        {elt_1} = toModelicaFormElts({elt});
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.WHEN_EQUATION(e1_1,welts_1,SOME(elt_1)) :: elts_1);
    case ((DAE.WHEN_EQUATION(condition = e1,equations = welts,elsewhen_ = NONE) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        welts_1 = toModelicaFormElts(welts);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.WHEN_EQUATION(e1_1,welts_1,NONE) :: elts_1);
    case ((DAE.IF_EQUATION(condition1 = conds,equations2 = trueBranches,equations3 = eelts) :: elts))
      equation 
        conds_1 = Util.listMap(conds,toModelicaFormExp);
        trueBranches_1 = Util.listMap(trueBranches,toModelicaFormElts);
        eelts_1 = toModelicaFormElts(eelts);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.IF_EQUATION(conds_1,trueBranches_1,eelts_1) :: elts_1);
    case ((DAE.INITIAL_IF_EQUATION(condition1 = conds,equations2 = trueBranches,equations3 = eelts) :: elts))
      equation 
        conds_1 = Util.listMap(conds,toModelicaFormExp);
        trueBranches_1 = Util.listMap(trueBranches,toModelicaFormElts);
        eelts_1 = toModelicaFormElts(eelts);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIAL_IF_EQUATION(conds_1,trueBranches_1,eelts_1) :: elts_1);
    case ((DAE.INITIALEQUATION(exp1 = e1,exp2 = e2) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIALEQUATION(e1_1,e2_1) :: elts_1);
    case ((DAE.ALGORITHM(algorithm_ = a) :: elts))
      local
        Algorithm.Algorithm a;
      equation 
        print("to_modelica_form_elts(ALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.ALGORITHM(a) :: elts_1);
    case ((DAE.INITIALALGORITHM(algorithm_ = a) :: elts))
      local
        Algorithm.Algorithm a;
      equation 
        print("to_modelica_form_elts(INITIALALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIALALGORITHM(a) :: elts_1);
    case ((DAE.COMP(ident = id,dAElist = dae) :: elts))
      equation 
        dae_1 = toModelicaForm(dae);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.COMP(id,dae_1) :: elts_1);
    case ((DAE.FUNCTION(path = p,functions = (DAE.FUNCTION_DEF(dae)::derFuncs),type_ = t,partialPrefix=partialPrefix,inlineType = inlineType) :: elts))
      equation 
        dae_1 = toModelicaForm(dae);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.FUNCTION(p,(DAE.FUNCTION_DEF(dae_1)::derFuncs),t,partialPrefix,inlineType) :: elts_1);
    case ((DAE.FUNCTION(path = p,functions = (DAE.FUNCTION_EXT(dae, d)::derFuncs),type_ = t,partialPrefix=partialPrefix,inlineType = inlineType) :: elts))
      local DAE.ExternalDecl d;
      equation 
        elts_1 = toModelicaFormElts(elts);
        dae_1 = toModelicaForm(dae);
      then
        (DAE.FUNCTION(p,(DAE.FUNCTION_EXT(dae, d)::derFuncs),t,partialPrefix,inlineType) :: elts_1);
 
    case ((DAE.RECORD_CONSTRUCTOR(path = p,type_ = t) :: elts))
      equation 
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.RECORD_CONSTRUCTOR(p,t) :: elts_1);
    case ((DAE.ASSERT(condition = e1,message=e2) :: elts))
      local
        DAE.Exp e1,e2,e_1,e_2;
      equation 
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e1);
        e_2 = toModelicaFormExp(e2);
      then
        (DAE.ASSERT(e_1,e_2) :: elts_1);
  end matchcontinue;
end toModelicaFormElts;

public function replaceCrefInVar "
Author BZ 
 Function for updating the Component Ref of the Var
"
  input DAE.ComponentRef newCr;
  input DAE.Element inelem;
  output DAE.Element outelem;
algorithm
  outelem := matchcontinue(newCr, inelem)
    local
      DAE.ComponentRef a1;
      DAE.VarKind a2;
      DAE.VarDirection a3;
      DAE.VarProtection a4;
      DAE.Type a5;
      DAE.InstDims a7;
      DAE.Flow a8;
      DAE.Stream a9;
      Option<DAE.Exp> a6; 
      list<Absyn.Path> a10;
      Option<DAE.VariableAttributes> a11;
      Option<SCode.Comment> a12;
      Absyn.InnerOuter a13;
    case(newCr, DAE.VAR(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13))
      then DAE.VAR(newCr,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13);
  end matchcontinue;
end replaceCrefInVar;

protected function toModelicaFormExpOpt "function: toModelicaFormExpOpt
 
  Helper function to to_mdelica_form_elts.
"
  input Option<DAE.Exp> inExpExpOption;
  output Option<DAE.Exp> outExpExpOption;
algorithm 
  outExpExpOption:=
  matchcontinue (inExpExpOption)
    local DAE.Exp e_1,e;
    case (SOME(e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        SOME(e_1);
    case (NONE) then NONE; 
  end matchcontinue;
end toModelicaFormExpOpt;

protected function toModelicaFormCref "function: toModelicaFormCref
 
  Helper function to to_modelica_form_elts.
"
  input DAE.ComponentRef cr;
  output DAE.ComponentRef outComponentRef;
  String str,str_1;
  DAE.ExpType ty;
algorithm 
  str := Exp.printComponentRefStr(cr);
  ty := Exp.crefType(cr); 
  str_1 := Util.stringReplaceChar(str, ".", "_");
  outComponentRef := DAE.CREF_IDENT(str_1,ty,{});
end toModelicaFormCref;

protected function toModelicaFormExp "function: toModelicaFormExp
 
  Helper function to to_modelica_form_elts.
"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      DAE.ComponentRef cr_1,cr;
      DAE.ExpType t,tp;
      DAE.Exp e1_1,e2_1,e1,e2,e_1,e,e3_1,e3;
      DAE.Operator op;
      list<DAE.Exp> expl_1,expl;
      Absyn.Path f;
      Boolean b,bt;
      Integer i;
      Option<DAE.Exp> eopt_1,eopt;
      DAE.InlineType il; 
    case (DAE.CREF(componentRef = cr,ty = t))
      equation 
        cr_1 = toModelicaFormCref(cr);
      then
        DAE.CREF(cr_1,t);
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        DAE.BINARY(e1_1,op,e2_1);
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        DAE.LBINARY(e1_1,op,e2_1);
    case (DAE.UNARY(operator = op,exp = e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        DAE.UNARY(op,e_1);
    case (DAE.LUNARY(operator = op,exp = e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        DAE.LUNARY(op,e_1);
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        DAE.RELATION(e1_1,op,e2_1);
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        e3_1 = toModelicaFormExp(e3);
      then
        DAE.IFEXP(e1_1,e2_1,e3_1);
    case (DAE.CALL(path = f,expLst = expl,tuple_ = bt,builtin = b,ty=tp,inlineType=il))
      equation 
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        DAE.CALL(f,expl_1,bt,b,tp,il);
    case (DAE.ARRAY(ty = t,scalar = b,array = expl))
      equation 
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        DAE.ARRAY(t,b,expl_1);
    case (DAE.TUPLE(PR = expl))
      equation 
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        DAE.TUPLE(expl_1);
    case (DAE.CAST(ty = t,exp = e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        DAE.CAST(t,e_1);
    case (DAE.ASUB(exp = e,sub = expl))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        DAE.ASUB(e_1,expl);
    case (DAE.SIZE(exp = e,sz = eopt))
      equation 
        e_1 = toModelicaFormExp(e);
        eopt_1 = toModelicaFormExpOpt(eopt);
      then
        DAE.SIZE(e_1,eopt_1);
    case (e) then e; 
  end matchcontinue;
end toModelicaFormExp;

public function getNamedFunction "function: getNamedFunction
 
  return the FUNCTION with the given name. Returns empty list if not found
  TODO: Only top level functions are checked. Add recursing into the DAE
  and path name checking.
  TODO: External functions?
"
  input Absyn.Path inPath;
  input list<DAE.Element> inElementLst;
  output list<DAE.Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inPath,inElementLst)
    local
      Absyn.Path path,elpath;
      DAE.Element el;
      list<DAE.Element> rest,res;
    case (_,{}) then {}; 
    case (path,((el as DAE.FUNCTION(path = elpath)) :: rest))
      equation 
        true = ModUtil.pathEqual(path, elpath);
      then
        {el};
    case (path,((el as DAE.RECORD_CONSTRUCTOR(path = elpath)) :: rest))
      equation 
        true = ModUtil.pathEqual(path, elpath); 
      then 
        {el}; 
    case (path,(el :: rest))
      equation 
        res = getNamedFunction(path, rest);
      then
        res;
    case (_,_)
      equation 
        Debug.fprintln("failtrace", "- DAEUtil.getNamedFunction failed");
      then
        fail();
  end matchcontinue;
end getNamedFunction;

public function getAllExps "function: getAllExps
  
  This function goes through the DAE structure and finds all the
  expressions and returns them in a list
"
  input list<DAE.Element> elements;
  output list<DAE.Exp> exps;
  list<list<DAE.Exp>> expslist;
algorithm 
  expslist := Util.listMap(elements, getAllExpsElement);
  exps := Util.listFlatten(expslist);
end getAllExps;

protected function crefToExp "function: crefToExp
 
  Makes an expression from a ComponentRef.
"
  input DAE.ComponentRef inComponentRef;
  output DAE.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inComponentRef)
    local DAE.ComponentRef cref;
    case cref then DAE.CREF(cref,DAE.ET_OTHER()); 
  end matchcontinue;
end crefToExp;

public function verifyWhenEquation "
Author BZ, 2008-09
This function verifies when-equations. 
Returns the crefs written to, and also checks for illegal statements in when-body eqn's.
"
  input list<DAE.Element> inElems;
  output list<DAE.ComponentRef> leftSideCrefs;
algorithm  leftSideCrefs := matchcontinue(inElems)
  local
    list<DAE.Element> elems1,oelems,moreWhen;
    list<DAE.ComponentRef> crefs1,crefs2;
  case({}) then {};
    // no need to check elseWhen, they are beein handled in a reverse order, from inst.mo.
  case(DAE.WHEN_EQUATION(_,elems1,_)::moreWhen) then verifyWhenEquationStatements(elems1);
    
  case(inElems) then verifyWhenEquationStatements(inElems);
  case(inElems) 
    equation 
      print("-verify_When_Equation FAILED\n"); 
      //print(dumpElementsStr(elems1) +& "\n\n");
      then fail();
end matchcontinue;
end verifyWhenEquation;

protected function verifyWhenEquationStatements2 ""
  input list<DAE.Exp> inExps;
  output list<DAE.ComponentRef> leftSideCrefs;
algorithm
  leftSideCrefs := matchcontinue(inExps)
    local
      DAE.Exp e;
      list<DAE.ComponentRef> crefs1,crefs2;
    case({}) then {};
    case(e::inExps)
      equation
        crefs1 = verifyWhenEquationStatements({DAE.EQUATION(e,e)});
        crefs2 = verifyWhenEquationStatements2(inExps);
        leftSideCrefs = listAppend(crefs1,crefs2);
      then
        leftSideCrefs;
  end matchcontinue;
end verifyWhenEquationStatements2;

protected function verifyWhenEquationStatements "
Author BZ, 2008-09
Helper function for verifyWhenEquation
TODO: add some error reporting for this. 
"
input list<DAE.Element> inElems;
output list<DAE.ComponentRef> leftSideCrefs;
algorithm 
  leftSideCrefs:=
  matchcontinue (inElems)
    local
      String s1,s2;
      Integer i;
      list<DAE.Exp> e1,e2,e3,exps,explist1,explist2,exps1,exps2,exps3;
      DAE.Exp crefexp,exp,cond,ee1,ee2;
      DAE.ComponentRef cref;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.InstDims instdims;
      DAE.Flow flowPrefix;
      DAE.Element el;
      DAE.ExtArg retarg;
      Option<DAE.Exp> bndexp,startvalexp;
      list<Absyn.Path> pathlist;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<DAE.Element> ellist,elements,eqs,eqsfalseb,rest;
      list<list<DAE.Element>> eqstrueb;
      list<DAE.ComponentRef> lhsCrefs,crefs1,crefs2,crefs3;
      Option<DAE.Element> elsewhenopt;
      Algorithm.Algorithm alg;
      String id,fname,lang;
      Absyn.Path path;
      list<list<DAE.Exp>> argexps,expslist;
      list<DAE.ExtArg> args;
      Option<Absyn.Annotation> ann;
    case({}) then {};
    case(DAE.VAR(componentRef = _)::rest) 
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        lhsCrefs;
    case(DAE.DEFINE(componentRef = cref,exp = exp)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        cref::lhsCrefs;

    case(DAE.EQUATION(exp = DAE.CREF(cref,_))::rest)
      equation
      lhsCrefs = verifyWhenEquationStatements(rest);
      then
        cref::lhsCrefs;
    case(DAE.EQUATION(exp = DAE.TUPLE(exps1))::rest)
      equation
        crefs1 = verifyWhenEquationStatements2(exps1);
        lhsCrefs = verifyWhenEquationStatements(rest);
        lhsCrefs = listAppend(crefs1,lhsCrefs);
      then 
        lhsCrefs;
    case(DAE.EQUEQUATION(cref,_)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        cref::lhsCrefs;
        
    case(DAE.IF_EQUATION(condition1 = exps,equations2 = eqstrueb,equations3 = eqsfalseb)::rest)
      local list<list<DAE.ComponentRef>> crefslist;
      equation 
        crefslist = Util.listMap(eqstrueb,verifyWhenEquationStatements);
        crefs2 = verifyWhenEquationStatements(eqsfalseb);
        crefslist = listAppend(crefslist,{crefs2});
        (crefs1,true) = compareCrefList(crefslist);
        lhsCrefs = verifyWhenEquationStatements(rest);
        lhsCrefs = listAppend(crefs1,lhsCrefs);
      then
        lhsCrefs;
    case(DAE.IF_EQUATION(condition1 = exps,equations2 = eqstrueb,equations3 = eqsfalseb)::rest)
      local list<list<DAE.ComponentRef>> crefslist;
      equation 
        crefslist = Util.listMap(eqstrueb,verifyWhenEquationStatements);
        crefs2 = verifyWhenEquationStatements(eqsfalseb);
        (crefs1,false) = compareCrefList(crefslist);
        s2 = dumpEquationStr(DAE.IF_EQUATION(exps,eqstrueb,eqsfalseb));
        s1 = "Error in IF-equation: \n" +& s2 +& "\n " +& "\nAll branches must write to same variables \n";
        print(s1);
      then
        fail();

    case(DAE.ALGORITHM(algorithm_ = alg)::rest)
      equation 
        print("ALGORITHM not implemented for use inside when equation\n"); 
      then
        fail();
    case(DAE.INITIALALGORITHM(algorithm_ = alg)::rest)
      equation 
        print("INITIALALGORITHM not allowed inside when equation\n"); 
      then
        fail();
    case(DAE.COMP(ident = _)::rest)
      equation 
      print("COMP not implemented for use inside when equation\n"); 
      then
        fail();

    case(DAE.ASSERT(condition=ee1,message=ee2)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        lhsCrefs;
    case(DAE.TERMINATE(message = _)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        lhsCrefs;
    case(DAE.REINIT(componentRef=cref)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        /*cref::*/lhsCrefs;
       
    case(DAE.FUNCTION(path = path)::rest)
      equation
        print("FUNCTION not allowed inside when equation\n");
      then 
        fail();  
    case(DAE.RECORD_CONSTRUCTOR(path = path)::rest)
      equation
        print("RECORD_CONSTRUCTOR not allowed inside when equation\n");
      then 
        fail();  
    case(DAE.INITIAL_IF_EQUATION(condition1 = _)::rest)
      equation print("INITIAL_IF_EQUATION not allowed inside when equation\n");
      then 
        fail();  
    case(DAE.INITIALEQUATION(exp1 = _)::rest)
      equation print("INITIALEQUATION not allowed inside when equation\n");
      then 
        fail();  
    case(DAE.NORETCALL(_,_)::rest)
      equation print("NORETCALL not allowed inside when equation\n"); 
      then 
        fail();  
    case(DAE.WHEN_EQUATION(condition = _)::rest)
      equation 
        print(" When-equation inside when equation..?\n");
      then
        fail(); 
    case(DAE.INITIALDEFINE(componentRef = cref,exp = exp)::_)
      equation 
        print("INITIALDEFINE inside when equation, error");
      then
        fail();
    case(_)
      equation 
        Debug.fprintln("failtrace", "- DAEUtil.verifyWhenEquationStatements failed");
      then
        fail();
  end matchcontinue;
end verifyWhenEquationStatements;

protected function compareCrefList ""
input list<list<DAE.ComponentRef>> inrefs;
output list<DAE.ComponentRef> outrefs;
output Boolean matching;
algorithm (outrefs,matching) := matchcontinue(inrefs)
  local
    list<DAE.ComponentRef> crefs,recRefs;
    Integer i;
    Boolean b1,b2,b3;
  case({}) then ({},true);
  case(crefs::{}) then (crefs,true);
  case(crefs::inrefs) // this case will allways have revRefs >=1 unless we are supposed to have 0
    equation
      (recRefs,b3) = compareCrefList(inrefs);
      i = listLength(recRefs);
      b1 = (0 == intMod(listLength(crefs),listLength(recRefs)));        
      crefs = Util.listListUnionOnTrue({recRefs,crefs},Exp.crefEqual);
      b2 = intEq(listLength(crefs),i);
      b1 = boolAnd(b1,boolAnd(b2,b3));
    then
      (crefs,b1);      
  end matchcontinue;
end compareCrefList; 

protected function getAllExpsElement "function: getAllExpsElement
  
  Helper to get_all_exps. Implements get_all_exps for different kinds of
  elements 
"
  input DAE.Element inElement;
  output list<DAE.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inElement)
    local
      
      list<DAE.Exp> e1,e2,e3,exps,explist1,explist2,exps1,exps2,exps3,ifcond;
      DAE.Exp crefexp,exp,cond;
      DAE.ComponentRef cref;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type ty;
      Option<DAE.Exp> bndexp,startvalexp;
      DAE.InstDims instdims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> pathlist;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<DAE.Element> ellist,elements,eqs,eqsfalseb;
      list<list<DAE.Element>> eqstrueb;
      Option<DAE.Element> elsewhenopt;
      Algorithm.Algorithm alg;
      String id,fname,lang;
      Absyn.Path path;
      list<list<DAE.Exp>> argexps,expslist;
      list<DAE.ExtArg> args;
      DAE.ExtArg retarg;
      Option<Absyn.Annotation> ann;
    case DAE.VAR(componentRef = cref,
             kind = vk,
             direction= vd,
             ty = ty,
             binding = bndexp,
             dims = instdims,
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             pathLst = pathlist,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment) /* VAR */ 
      equation 
        e1 = Util.optionToList(bndexp);
        e3 = Util.listMap(instdims, getAllExpsSubscript);
        e3 = Util.listFlatten(e3);
        crefexp = crefToExp(cref);
        exps = Util.listFlatten({e1,e3,{crefexp}});
      then
        exps;
    case DAE.DEFINE(componentRef = cref,exp = exp)
      equation 
        crefexp = crefToExp(cref);
      then
        {crefexp,exp};
    case DAE.INITIALDEFINE(componentRef = cref,exp = exp)
      equation 
        crefexp = crefToExp(cref);
      then
        {crefexp,exp};
    case DAE.EQUATION(exp = e1,scalar = e2)
      local DAE.Exp e1,e2;
      then
        {e1,e2};
    case DAE.EQUEQUATION(cr1,cr2)
      local DAE.ComponentRef cr1,cr2; DAE.Exp e1,e2;
        equation
          e1 = crefToExp(cr1);
          e2 = crefToExp(cr2);
      then
        {e1,e2};
    case DAE.WHEN_EQUATION(condition = cond,equations = eqs,elsewhen_ = elsewhenopt)
      equation 
        ellist = Util.optionToList(elsewhenopt);
        elements = listAppend(eqs, ellist);
        exps = getAllExps(elements);
      then
        (cond :: exps);
    case DAE.IF_EQUATION(condition1 = ifcond,equations2 = eqstrueb,equations3 = eqsfalseb)
      equation 
        explist1 = Util.listFlatten(Util.listMap(eqstrueb,getAllExps));
        explist2 = getAllExps(eqsfalseb);
        exps = Util.listFlatten({ifcond,explist1,explist2});
      then
        exps;
    case DAE.INITIAL_IF_EQUATION(condition1 = ifcond,equations2 = eqstrueb,equations3 = eqsfalseb)
      equation 
        explist1 = Util.listFlatten(Util.listMap(eqstrueb,getAllExps));
        explist2 = getAllExps(eqsfalseb);
        exps = Util.listFlatten({ifcond,explist1,explist2});
      then
        exps;
    case DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)
      local DAE.Exp e1,e2;
      then
        {e1,e2};
    case DAE.ALGORITHM(algorithm_ = alg)
      equation 
        exps = Algorithm.getAllExps(alg);
      then
        exps;
    case DAE.INITIALALGORITHM(algorithm_ = alg)
      equation 
        exps = Algorithm.getAllExps(alg);
      then
        exps;
    case DAE.COMP(ident = id,dAElist = DAE.DAE(elementLst = elements))
      equation 
        exps = getAllExps(elements);
      then
        exps;
    case DAE.FUNCTION(path = path,functions = (DAE.FUNCTION_DEF(body = DAE.DAE(elementLst = elements))::_),type_ = ty)
     local tuple<DAE.TType, Option<Absyn.Path>> ty;
      equation 
        exps1 = getAllExps(elements);
        exps2 = Types.getAllExps(ty);
        exps = listAppend(exps1, exps2);
      then
        exps;
    case DAE.FUNCTION(path = path,functions = (DAE.FUNCTION_EXT(DAE.DAE(elementLst = elements),externalDecl = DAE.EXTERNALDECL(ident = fname,external_ = args,parameters = retarg,returnType = lang,language = ann))::_),type_ = ty)
      local tuple<DAE.TType, Option<Absyn.Path>> ty;
      equation 
        exps1 = getAllExps(elements);
        exps2 = Types.getAllExps(ty);
        exps3 = getAllExpsExtarg(retarg);
        argexps = Util.listMap(args, getAllExpsExtarg);
        expslist = listAppend({exps1,exps2,exps3}, argexps);
        exps = Util.listFlatten(expslist);
      then
        exps;
    case DAE.RECORD_CONSTRUCTOR(path = path) then {};
    case DAE.ASSERT(condition=e1,message=e2) local DAE.Exp e1,e2; then {e1,e2}; 
    case DAE.NORETCALL(fname,fargs)
      local
        Absyn.Path fname;
        list<DAE.Exp> fargs;
      then {DAE.CALL(fname,fargs,false,false,DAE.ET_OTHER(),DAE.NO_INLINE)};      
      
    case _
      equation 
        Debug.fprintln("failtrace", "- DAEUtil.getAllExpsElement failed");
      then
        fail();
  end matchcontinue;
end getAllExpsElement;

protected function getAllExpsSubscript "function: getAllExpsSubscript
  
  Get all exps from a Subscript 
"
  input DAE.Subscript inSubscript;
  output list<DAE.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inSubscript)
    local DAE.Exp e;
    case DAE.WHOLEDIM() then {}; 
    case DAE.SLICE(exp = e) then {e}; 
    case DAE.INDEX(exp = e) then {e}; 
    case _
      equation 
        Debug.fprintln("failtrace", "- DAEUtil.getAllExpsSubscript failed");
      then
        fail();
  end matchcontinue;
end getAllExpsSubscript;

protected function getAllExpsExtarg 
"function: getAllExpsExtarg  
  Get all exps from an ExtArg"
  input DAE.ExtArg inExtArg;
  output list<DAE.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExtArg)
    local
      DAE.Exp exp1,crefexp,exp;
      list<DAE.Exp> explist,exps,tyexps;
      DAE.ComponentRef cref;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
    case DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty)
      equation 
        exp1 = crefToExp(cref);
        explist = Types.getAllExps(ty);
        exps = listAppend({exp1}, explist);
      then
        exps;
    case DAE.EXTARGEXP(exp = exp1,type_ = ty)
      equation 
        explist = Types.getAllExps(ty);
        exps = listAppend({exp1}, explist);
      then
        exps;
    case DAE.EXTARGSIZE(componentRef = cref,attributes = attr,type_ = ty,exp = exp)
      equation 
        crefexp = crefToExp(cref);
        tyexps = Types.getAllExps(ty);
        exps = Util.listFlatten({{crefexp},tyexps,{exp}});
      then
        exps;
    case DAE.NOEXTARG() then {}; 
    case _
      equation 
        Debug.fprintln("failtrace", "- DAEUtil.getAllExpsExtarg failed");
      then
        fail();
  end matchcontinue;
end getAllExpsExtarg;

public function transformIfEqToExpr 
"function: transformIfEqToExpr
  transform all if equations to ordinary equations involving if-expressions"
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
algorithm 
  outDAElist := matchcontinue (inDAElist)
    local
      DAE.DAElist sublist_result,result,sublist;
      list<DAE.Element> rest_result,rest,res2,res1,res;
      DAE.Element subresult,el;
      String name;
    case (DAE.DAE(elementLst = {})) then DAE.DAE({}); 
    case (DAE.DAE(elementLst = (DAE.COMP(ident = name,dAElist = sublist) :: rest)))
      equation 
        sublist_result = transformIfEqToExpr(sublist);
        DAE.DAE(rest_result) = transformIfEqToExpr(DAE.DAE(rest));
        subresult = DAE.COMP(name,sublist_result);
        result = DAE.DAE((subresult :: rest_result));
      then
        result;
    case (DAE.DAE(elementLst = (el :: rest)))
      equation
        res1 = ifEqToExpr(el);
        DAE.DAE(res2) = transformIfEqToExpr(DAE.DAE(rest));
        res = listAppend(res1, res2);
      then
        DAE.DAE(res);
    case (DAE.DAE(elementLst = (el :: rest)))
      equation
        DAE.DAE(res) = transformIfEqToExpr(DAE.DAE(rest));
      then
        DAE.DAE((el :: res));
  end matchcontinue;
end transformIfEqToExpr;

protected function ifEqToExpr 
"function: ifEqToExpr
  Transform one if-equation into equations involving if-expressions"
  input DAE.Element inElement;
  output list<DAE.Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElement)
    local
      Integer true_eq,false_eq;
      String elt_str;
      DAE.Element elt;
      list<DAE.Exp> cond;
      list<DAE.Element> false_branch,equations;
      list<list<DAE.Element>> true_branch;

    case ((elt as DAE.IF_EQUATION(condition1 = cond,equations2 = true_branch,equations3 = false_branch)))
      equation 
        true_eq = ifEqToExpr2(true_branch);
        false_eq = listLength(false_branch);
        (true_eq == false_eq) = false;
        elt_str = dumpEquationsStr({elt});
        Error.addMessage(Error.DIFFERENT_NO_EQUATION_IF_BRANCHES, {elt_str});
      then
        {};
    case (DAE.IF_EQUATION(condition1 = cond,equations2 = true_branch,equations3 = false_branch))
      equation 
        true_eq = ifEqToExpr2(true_branch);
        false_eq = listLength(false_branch);
        (true_eq == false_eq) = true;
        equations = makeEquationsFromIf(cond, true_branch, false_branch);
      then
        equations;
    case (elt as DAE.IF_EQUATION(_, _, _)) // only display failure on if equation  
      equation
        elt_str = dumpElementsStr({elt});
        Debug.fprintln("failtrace", "- DAE.ifEqToExpr failed " +& elt_str);
      then fail();
  end matchcontinue;
end ifEqToExpr;

protected function ifEqToExpr2
  input list<list<DAE.Element>> tbs;
  output Integer len;
algorithm len := matchcontinue(tbs)
  local
    list<DAE.Element> tb;
    Integer recLen;
  case(tb::{}) then listLength(tb);
  case(tb::tbs)
    equation
      recLen = ifEqToExpr2(tbs);
      recLen = Util.if_(intEq(recLen,listLength(tb)),recLen,-1);
    then 
      recLen;
end matchcontinue;
end ifEqToExpr2;

protected function makeEquationsFromIf
  input list<DAE.Exp> inExp1;
  input list<list<DAE.Element>> inElementLst2;
  input list<DAE.Element> inElementLst3;
  output list<DAE.Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inExp1,inElementLst2,inElementLst3)
    local 
      list<list<DAE.Element>> tbs,rest1,tbsRest,tbsFirstL;
      list<DAE.Element> tbsFirst,fbs,rest_res;
      DAE.Element fb,eq;
      list<DAE.Exp> conds,tbsexp; 
      DAE.Exp fbexp,ifexp;
    case (_,tbs,{})
      equation
        Util.listMap0(tbs, Util.assertListEmpty);
      then {}; 

    case (conds,tbs,fb::fbs)
      equation 
        tbsRest = Util.listMap(tbs,Util.listRest);
        rest_res = makeEquationsFromIf(conds, tbsRest, fbs);
        
        tbsFirst = Util.listMap(tbs,Util.listFirst);        
        tbsexp = Util.listMap(tbsFirst,makeEquationToResidualExp);        
        fbexp = makeEquationToResidualExp(fb);
        
        ifexp = Exp.makeNestedIf(conds,tbsexp,fbexp);
        eq = DAE.EQUATION(DAE.RCONST(0.0),ifexp);
      then
        (eq :: rest_res);
  end matchcontinue;
end makeEquationsFromIf;

protected function makeEquationToResidualExp ""
  input DAE.Element eq;
  output DAE.Exp oExp;
algorithm
  oExp := matchcontinue(eq)
    local
      DAE.Exp e1,e2;
    case(DAE.EQUATION(e1,e2))
      equation
        oExp = DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2);
      then 
        oExp;
  end matchcontinue;
end makeEquationToResidualExp;

public function dumpFlow "
Author BZ 2008-07, dump flow properties to string.
"
  input DAE.Flow var;
  output String flowStrig;
algorithm flowString := matchcontinue(var)
  case DAE.FLOW() then "flow";
  case DAE.NON_FLOW() then "effort";
  case DAE.NON_CONNECTOR() then "non_connector";
end matchcontinue;
end dumpFlow;

public function renameTimeToDollarTime "
Author: BZ, 2009-1
rename the keyword time to globalData->timeValue, this is a special case for functions since they do not get translated in to c_crefs.
"
  input list<DAE.Element> dae;
  output list<DAE.Element> odae;  
algorithm
  (odae,_) := traverseDAE(dae, renameTimeToDollarTimeVisitor,0);
end renameTimeToDollarTime;

protected function renameTimeToDollarTimeVisitor "
Author: BZ, 2009-01
The visitor function for traverseDAE.calls Exp.traverseExp on the expression.
"
  input DAE.Exp exp; 
  input Integer arg; 
  output DAE.Exp oexp; 
  output Integer oarg; 
algorithm
  (oexp,oarg) := matchcontinue(exp,arg)
    local
      DAE.ExpType ty;
      DAE.ComponentRef cr,cr2;
    case(exp,oarg) 
      equation
        ((oexp,oarg)) = Exp.traverseExp(exp,renameTimeToDollarTimeFromCref,oarg);
      then 
        (oexp,oarg);
  end matchcontinue;
end renameTimeToDollarTimeVisitor;

protected function renameTimeToDollarTimeFromCref "
Author: BZ, 2008-12
Function for Exp.traverseExp, removes the constant 'UNIQUEIO' from any cref it might visit.
"
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm
  outTplExpExpString := matchcontinue (inTplExpExpString)
    local
      DAE.ComponentRef cr,cr2;
      DAE.ExpType cty,ty;
      Integer oarg;
      list<DAE.Subscript> subs;
    case((DAE.CREF(DAE.CREF_IDENT("time",cty,subs),ty),oarg))
      then ((DAE.CREF(DAE.CREF_IDENT("globalData->timeValue",cty,subs),ty),oarg));
    case(inTplExpExpString) then inTplExpExpString;
end matchcontinue;   
end renameTimeToDollarTimeFromCref;


public function renameUniqueOuterVars "
Author: BZ, 2008-12
Rename innerouter(the inner part of innerouter) variables that have been renamed to a.b.$unique$var
Just remove the $unique$ from the var name.
This function traverses the entire dae.
"
  input list<DAE.Element> dae;
  output list<DAE.Element> odae;  
algorithm (odae,_) := traverseDAE(dae, renameUniqueVisitor,0);
end renameUniqueOuterVars;

protected function renameUniqueVisitor "
Author: BZ, 2008-12
The visitor function for traverseDAE. 
calls Exp.traverseExp on the expression.
"
input DAE.Exp exp; 
input Integer arg; 
output DAE.Exp oexp; 
output Integer oarg; 
algorithm (oexp,oarg) := matchcontinue(exp,arg)
  local
    DAE.ExpType ty;
    DAE.ComponentRef cr,cr2;
  case(exp,oarg) 
    equation
      ((oexp,oarg)) = Exp.traverseExp(exp,removeUniqieIdentifierFromCref,oarg);
    then 
      (oexp,oarg);
  end matchcontinue;
end renameUniqueVisitor;

protected function removeUniqieIdentifierFromCref "
Author: BZ, 2008-12
Function for Exp.traverseExp, removes the constant 'UNIQUEIO' from any cref it might visit.
"
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm outTplExpExpString := matchcontinue (inTplExpExpString)
  local DAE.ComponentRef cr,cr2; DAE.ExpType ty; Integer oarg;
  case((DAE.CREF(cr,ty),oarg))    
    equation
      cr2 = unNameInnerouterUniqueCref(cr,DAE.UNIQUEIO);
    then ((DAE.CREF(cr2,ty),oarg));
    case(inTplExpExpString) then inTplExpExpString;
  end matchcontinue;   
end removeUniqieIdentifierFromCref;

public function nameUniqueOuterVars "
Author: BZ, 2008-12
Rename all variables to the form a.b.$unique$var, call
This function traverses the entire dae.
"
  input list<DAE.Element> dae;
  output list<DAE.Element> odae;  
algorithm (odae,_) := traverseDAE(dae, nameUniqueVisitor,0);
end nameUniqueOuterVars;

protected function nameUniqueVisitor "
Author: BZ, 2008-12
The visitor function for traverseDAE. 
calls Exp.traverseExp on the expression.
"
input DAE.Exp exp; 
input Integer arg; 
output DAE.Exp oexp; 
output Integer oarg; 
algorithm (oexp,oarg) := matchcontinue(exp,arg)
  local
    DAE.ExpType ty;
    DAE.ComponentRef cr,cr2;
  case(exp,oarg) 
    equation
      ((oexp,oarg)) = Exp.traverseExp(exp,addUniqieIdentifierToCref,oarg);
    then 
      (oexp,oarg);
  end matchcontinue;
end nameUniqueVisitor;

protected function addUniqieIdentifierToCref "
Author: BZ, 2008-12
Function for Exp.traverseExp, adds the constant 'UNIQUEIO' to the CREF_IDENT() part of the cref.
"
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm outTplExpExpString := matchcontinue (inTplExpExpString)
  local DAE.ComponentRef cr,cr2; DAE.ExpType ty; Integer oarg;
  case((DAE.CREF(cr,ty),oarg))    
    equation
      cr2 = nameInnerouterUniqueCref(cr);
    then ((DAE.CREF(cr2,ty),oarg));
    case(inTplExpExpString) then inTplExpExpString;
  end matchcontinue;   
end addUniqieIdentifierToCref;

// helper functions for traverseDAE
protected function traverseDAEOptExp "
Author: BZ, 2008-12
Traverse an optional expression, helper function for traverseDAE
"
  input Option<DAE.Exp> oexp;
  input FuncExpType func;
  input Type_a extraArg;
  output Option<DAE.Exp> ooexp;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm(ooexp,oextraArg) := matchcontinue(oexp,func,extraArg)
  case(NONE,func,extraArg) then (NONE,extraArg);
  case(SOME(e),func,extraArg)
    local DAE.Exp e;
    equation
      (e,extraArg) = func(e,extraArg);
    then
      (SOME(e),extraArg);
end matchcontinue;
end traverseDAEOptExp;

protected function traverseDAEExpList "
Author: BZ, 2008-12
Traverse an list of expressions, helper function for traverseDAE
"
  input list<DAE.Exp> exps;
  input FuncExpType func;
  input Type_a extraArg;
  output list<DAE.Exp> oexps;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm(oexps,oextraArg) := matchcontinue(exps,func,extraArg)
  local DAE.Exp e; 
  case({},func,extraArg) then ({},extraArg);
  case(e::exps,func,extraArg)
    equation
      (e,extraArg) = func(e,extraArg);
      (oexps,extraArg) = traverseDAEExpList(exps,func,extraArg);
    then
      (e::oexps,extraArg);
end matchcontinue;
end traverseDAEExpList;

protected function traverseDAEList "
Author: BZ, 2008-12
Helper function for traverseDAE, traverses a list of dae element list. 
"
  input list<list<DAE.Element>> daeList;
  input FuncExpType func;
  input Type_a extraArg;
  output list<list<DAE.Element>> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm (traversedDaeList,Type_a) := matchcontinue(daeList,func,extraArg)
  local
    list<DAE.Element> branch,branch2;
    list<list<DAE.Element>> recRes; 
  case({},func,extraArg) then ({},extraArg);
  case(branch::daeList,func,extraArg)
    equation
      (branch2,extraArg) = traverseDAE(branch,func,extraArg);
      (recRes,extraArg) = traverseDAEList(daeList,func,extraArg);
    then
      (branch2::recRes,extraArg);
end matchcontinue;
end traverseDAEList;

public function traverseDAE "
Author: BZ, 2008-12
This function traverses all dae exps.
NOTE, it also traverses DAE.VAR(componenname) as an expression.
"
  input list<DAE.Element> daeList;
  input FuncExpType func;
  input Type_a extraArg;
  output list<DAE.Element> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm (traversedDaeList,Type_a) := matchcontinue(daeList,func,extraArg)
  local
    DAE.ComponentRef cr,cr2,cr1,cr1_2;
    list<DAE.Element> dae,dae2,elist,elist2,elist22,elist1,elist11;
    DAE.Element elt,elt2,elt22,elt1,elt11;
    DAE.VarKind kind;
    DAE.VarDirection dir;
    DAE.Type tp,ftp;
    DAE.InstDims dims;
    DAE.StartValue start;
    DAE.Flow fl;
    DAE.Stream st;
    DAE.ExternalDecl extDecl;
    DAE.VarProtection prot;
    DAE.Exp bindExp,bindExp2,e,e2,e22,e1,e11;
    list<Absyn.Path> clsLst;
    Option<DAE.VariableAttributes> attr;
    Option<SCode.Comment> cmt;
    Option<DAE.Exp> optExp;
    Absyn.InnerOuter io;
    list<Integer> idims;
    String id;
    Absyn.Path path;
    list<DAE.Statement> stmts,stmts2;
    list<list<DAE.Element>> tbs,tbs_1;
    list<DAE.Exp> conds,conds_1, args; 
    Boolean partialPrefix;
    Absyn.Path path; 
    list<DAE.Exp> expl;
    list<DAE.FunctionDefinition> derFuncs;
    DAE.InlineType inlineType;
  case({},_,extraArg) then ({},extraArg);
  case(DAE.VAR(cr,kind,dir,prot,tp,optExp,dims,fl,st,clsLst,attr,cmt,io)::dae,func,extraArg) 
    equation
      (DAE.CREF(cr2,_),extraArg) = func(DAE.CREF(cr,DAE.ET_REAL()), extraArg);
      (optExp,extraArg) = traverseDAEOptExp(optExp,func,extraArg);      
      (attr,extraArg) = traverseDAEVarAttr(attr,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.VAR(cr2,kind,dir,prot,tp,optExp,dims,fl,st,clsLst,attr,cmt,io)::dae2,extraArg);
      
  case(DAE.DEFINE(cr,e)::dae,func,extraArg)
    equation
      (e2,extraArg) = func(e, extraArg);
      (DAE.CREF(cr2,_),extraArg) = func(DAE.CREF(cr,DAE.ET_REAL()), extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.DEFINE(cr2,e2)::dae2,extraArg);
      
  case(DAE.INITIALDEFINE(cr,e)::dae,func,extraArg) 
    equation
      (e2,extraArg) = func(e, extraArg);
      (DAE.CREF(cr2,_),extraArg) = func(DAE.CREF(cr,DAE.ET_REAL()), extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.INITIALDEFINE(cr2,e2)::dae2,extraArg);
      
  case(DAE.EQUEQUATION(cr,cr1)::dae,func,extraArg) 
    equation
      (DAE.CREF(cr2,_),extraArg) = func(DAE.CREF(cr,DAE.ET_REAL()), extraArg);
      (DAE.CREF(cr1_2,_),extraArg) = func(DAE.CREF(cr1,DAE.ET_REAL()), extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.EQUEQUATION(cr2,cr1_2)::dae2,extraArg);
      
  case(DAE.EQUATION(e1,e2)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1, extraArg);
      (e22,extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.EQUATION(e11,e22)::dae2,extraArg);
      
  case(DAE.COMPLEX_EQUATION(e1,e2)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1, extraArg);
      (e22,extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.COMPLEX_EQUATION(e11,e22)::dae2,extraArg);
      
  case(DAE.ARRAY_EQUATION(idims,e1,e2)::dae,func,extraArg) 
    equation
      (e11, extraArg) = func(e1, extraArg);
      (e22, extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.ARRAY_EQUATION(idims,e11,e22)::dae2,extraArg);
      
  case(DAE.WHEN_EQUATION(e1,elist,SOME(elt))::dae,func,extraArg) 
    equation
      (e11, extraArg) = func(e1, extraArg);
      ({elt2}, extraArg)= traverseDAE({elt},func,extraArg);
      (elist2, extraArg) = traverseDAE(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.WHEN_EQUATION(e11,elist2,SOME(elt2))::dae2,extraArg);
      
  case(DAE.WHEN_EQUATION(e1,elist,NONE)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1, extraArg);
      (elist2,extraArg) = traverseDAE(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.WHEN_EQUATION(e11,elist2,NONE)::dae2,extraArg);
      
  case(DAE.INITIALEQUATION(e1,e2)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1, extraArg);
      (e22,extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.INITIALEQUATION(e11,e22)::dae2,extraArg);
      
  case(DAE.INITIAL_COMPLEX_EQUATION(e1,e2)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1, extraArg);
      (e22,extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.INITIAL_COMPLEX_EQUATION(e11,e22)::dae2,extraArg);
      
  case(DAE.COMP(id,DAE.DAE(elist))::dae,func,extraArg) 
    equation
      (elist2,extraArg) = traverseDAE(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.COMP(id,DAE.DAE(elist))::dae2,extraArg);
      
  case(DAE.FUNCTION(path,(DAE.FUNCTION_DEF(DAE.DAE(elementLst = elist))::derFuncs),ftp,partialPrefix,inlineType)::dae,func,extraArg) 
    equation
      (elist2,extraArg) = traverseDAE(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.FUNCTION(path,DAE.FUNCTION_DEF(DAE.DAE(elist2))::derFuncs,ftp,partialPrefix,inlineType)::dae2,extraArg);
    
    case(DAE.FUNCTION(path,(DAE.FUNCTION_EXT(body = DAE.DAE(elementLst = elist),externalDecl=extDecl)::derFuncs),ftp,partialPrefix,inlineType)::dae,func,extraArg) 
    equation
      (elist2,extraArg) = traverseDAE(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
     then (DAE.FUNCTION(path,DAE.FUNCTION_EXT(DAE.DAE(elist2),extDecl)::derFuncs,ftp,partialPrefix,DAE.NO_INLINE)::dae2,extraArg);
      
  case(DAE.RECORD_CONSTRUCTOR(path,tp)::dae,func,extraArg) 
    equation
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.RECORD_CONSTRUCTOR(path,tp)::dae2,extraArg);
      
  case(DAE.EXTOBJECTCLASS(path,elt1,elt2)::dae,func,extraArg) 
    equation
      ({elt11,elt22},extraArg) =  traverseDAE({elt1,elt2},func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.EXTOBJECTCLASS(path,elt1,elt2)::dae2,extraArg);
      
  case(DAE.ASSERT(e1,e2)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1,extraArg);
      (e22,extraArg) = func(e2,extraArg);          
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.ASSERT(e11,e22)::dae2,extraArg);
      
  case(DAE.TERMINATE(e1)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.TERMINATE(e11)::dae2,extraArg);    
  
  case(DAE.NORETCALL(path,expl)::dae,func,extraArg) 
    equation
      (expl,extraArg) = traverseDAEExpList(expl,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.NORETCALL(path,expl)::dae2,extraArg);
                
  case(DAE.NORETCALL(path,expl)::dae,func,extraArg) 
    equation
      (expl,extraArg) = traverseDAEExpList(expl,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.NORETCALL(path,expl)::dae2,extraArg);
                
  case(DAE.REINIT(cr,e1)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1,extraArg);
      (DAE.CREF(cr2,_),extraArg) = func(DAE.CREF(cr,DAE.ET_REAL()),extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.REINIT(cr2,e11)::dae2,extraArg);
      
  case(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts))::dae,func,extraArg) 
    equation
      (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts2))::dae2,extraArg);
      
  case(DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts))::dae,func,extraArg) 
    equation
      (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts2))::dae2,extraArg);
      
  case(DAE.IF_EQUATION(conds,tbs,elist2)::dae,func,extraArg)
    equation
      (conds_1,extraArg) = traverseDAEExpList(conds, func, extraArg);
      (tbs_1,extraArg) = traverseDAEList(tbs,func,extraArg);
      (elist22,extraArg) = traverseDAE(elist2,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.IF_EQUATION(conds_1,tbs_1,elist22)::dae2,extraArg);

  case(DAE.INITIAL_IF_EQUATION(conds,tbs,elist2)::dae,func,extraArg)
    equation
      (conds_1,extraArg) = traverseDAEExpList(conds, func, extraArg);
      (tbs_1,extraArg) = traverseDAEList(tbs,func,extraArg);
      (elist22,extraArg) = traverseDAE(elist2,func,extraArg); 
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DAE.INITIAL_IF_EQUATION(conds_1,tbs_1,elist22)::dae2,extraArg);
  // Empty function call - stefan
  case(DAE.NORETCALL(_, _)::dae,func,extraArg)
    equation
      Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"Empty function call in equations", "Move the function calls to appropriate algorithm section"});
    then fail();

  case(elt::_,_,_)
    local
      String str;
    equation
      print(" failure in DAE.traverseDAE\n");
      str = dumpElementsStr({elt});
      print(str);
    then fail();
end matchcontinue;
end traverseDAE;

public function traverseDAEEquationsStmts "function: traverseDAEEquationsStmts
  Author: BZ, 2008-12
  Helper function to traverseDAE,
  Handles the traversing of DAE.Statement.
"
  input list<DAE.Statement> inStmts;
  input FuncExpType func;
  input Type_a extraArg;
  output list<DAE.Statement> outStmts;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm(outStmts,oextraArg) := matchcontinue(inStmts,func,extraArg)
    local
      DAE.Exp e_1,e_2,e,e2;
      list<DAE.Exp> expl1,expl2;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Statement> xs_1,xs,stmts,stmts2;
      DAE.ExpType tp,tt;
      DAE.Statement x,ew,ew_1;
      Boolean b1;
      String id1;
      list<Integer> li;
  case ({},_,extraArg) then ({},extraArg);
      
  case ((DAE.STMT_ASSIGN(type_ = tp,exp1 = e2,exp = e) :: xs),func,extraArg)
    equation 
      (e_1,extraArg) = func(e, extraArg);
      (e_2,extraArg) = func(e2, extraArg);
      (xs_1,extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_ASSIGN(tp,e_2,e_1) :: xs_1,extraArg);
      
  case ((DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl1, exp = e) :: xs),func,extraArg)
    equation 
      (e_1, extraArg) = func(e, extraArg);
      (expl2, extraArg) = traverseDAEExpList(expl1,func,extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then ((DAE.STMT_TUPLE_ASSIGN(tp,expl2,e_1) :: xs_1),extraArg);
      
  case ((DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e) :: xs),func,extraArg)
    equation 
      (e_1, extraArg) = func(e, extraArg); 
      (e_2 as DAE.CREF(cr_1,_), extraArg) = func(DAE.CREF(cr,DAE.ET_OTHER()), extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_ASSIGN_ARR(tp,cr_1,e_1) :: xs_1,extraArg);
      
  case (((x as DAE.STMT_FOR(type_=tp,boolean=b1,ident=id1,exp=e,statementLst=stmts)) :: xs),func,extraArg)
    equation 
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_FOR(tp,b1,id1,e_1,stmts2) :: xs_1,extraArg);
      
  case (((x as DAE.STMT_WHILE(exp = e,statementLst=stmts)) :: xs),func,extraArg)
    equation 
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_WHILE(e_1,stmts2) :: xs_1,extraArg);
      
  case (((x as DAE.STMT_WHEN(exp = e,statementLst=stmts,elseWhen=NONE,helpVarIndices=li)) :: xs),func,extraArg)
    equation 
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_WHEN(e_1,stmts2,NONE,li) :: xs_1,extraArg);
      
  case (((x as DAE.STMT_WHEN(exp = e,statementLst=stmts,elseWhen=SOME(ew),helpVarIndices=li)) :: xs),func,extraArg)
    equation 
      ({ew_1}, extraArg) = traverseDAEEquationsStmts({ew},func,extraArg);
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_WHEN(e_1,stmts2,SOME(ew),li) :: xs_1,extraArg);
      
  case (((x as DAE.STMT_ASSERT(cond = e, msg=e2)) :: xs),func,extraArg)
    equation 
      (e_1, extraArg) = func(e, extraArg); 
      (e_2, extraArg) = func(e2, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_ASSERT(e_1,e_2) :: xs_1,extraArg);
      
  case (((x as DAE.STMT_TERMINATE(msg = e)) :: xs),func,extraArg)
    equation 
      (e_1, extraArg) = func(e, extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_TERMINATE(e_1) :: xs_1,extraArg);
      
  case (((x as DAE.STMT_REINIT(var = e,value=e2)) :: xs),func,extraArg)
    equation 
      (e_1, extraArg) = func(e, extraArg); 
      (e_2, extraArg) = func(e2, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_REINIT(e_1,e_2) :: xs_1,extraArg);
      
  case (((x as DAE.STMT_NORETCALL(e)) :: xs),func,extraArg)
    local Absyn.Path fnName;
    equation
      (e_1, extraArg) = func(e, extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_NORETCALL(e_1) :: xs_1,extraArg);
      
  case (((x as DAE.STMT_RETURN()) :: xs),func,extraArg)
    equation 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (x :: xs_1,extraArg);   
      
  case (((x as DAE.STMT_BREAK()) :: xs),func,extraArg)
    equation 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (x :: xs_1,extraArg);
      
  case (((x as DAE.STMT_IF(exp=e,statementLst=stmts,else_ = el)) :: xs),func,extraArg)
    local Algorithm.Else el,el_1;
    equation 
      (el_1,extraArg) = traverseDAEEquationsStmtsElse(el,func,extraArg);
      (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1,extraArg) = func(e, extraArg); 
      (xs_1,extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_IF(e_1,stmts2,el_1) :: xs_1,extraArg);
      
  case ((x :: xs),func,extraArg)
    equation 
      print("Warning, not implemented in replace_equations_stmts\n");
      (xs_1,extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (x :: xs_1,extraArg);
end matchcontinue;
end traverseDAEEquationsStmts;

protected function traverseDAEEquationsStmtsElse "
Author: BZ, 2008-12
Helper function for traverseDAEEquationsStmts
"
  input Algorithm.Else inElse;
  input FuncExpType func;
  input Type_a extraArg;
  output Algorithm.Else outElse;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm (outElse,extraArg) := matchcontinue(inElse,func,extraArg)
  local 
    DAE.Exp e,e_1;
    list<DAE.Statement> st,st_1;
    Algorithm.Else el,el_1;
  case(DAE.NOELSE(),_,extraArg) then (DAE.NOELSE,extraArg);
  case(DAE.ELSEIF(e,st,el),func,extraArg)
    equation
      (el_1,extraArg) = traverseDAEEquationsStmtsElse(el,func,extraArg);
      (st_1,extraArg) = traverseDAEEquationsStmts(st,func,extraArg);
      (e_1,extraArg) = func(e, extraArg); 
    then (DAE.ELSEIF(e_1,st_1,el_1),extraArg);
  case(DAE.ELSE(st),func,extraArg)
    equation
      (st_1,extraArg) = traverseDAEEquationsStmts(st,func,extraArg);
    then (DAE.ELSE(st_1),extraArg);      
end matchcontinue;
end traverseDAEEquationsStmtsElse;

protected function traverseDAEVarAttr "
Author: BZ, 2008-12
Help function to traverseDAE
"
  input Option<DAE.VariableAttributes> attr;
  input FuncExpType func;
  input Type_a extraArg;
  output Option<DAE.VariableAttributes> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outAttr,extraArg) := matchcontinue(attr,func,extraArg)
    local
      Option<DAE.Exp> quantity,unit,displayUnit,min,max,initial_,fixed,nominal,eb;
      Option<DAE.StateSelect> stateSelect;
      Option<Boolean> ip,fn;
    case(SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect,eb,ip,fn)),func,extraArg)
      equation
        (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
        (unit,extraArg) = traverseDAEOptExp(unit,func,extraArg);
        (displayUnit,extraArg) = traverseDAEOptExp(displayUnit,func,extraArg);      
        (min,extraArg) = traverseDAEOptExp(min,func,extraArg);
        (max,extraArg) = traverseDAEOptExp(max,func,extraArg);
        (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
        (nominal,extraArg) = traverseDAEOptExp(nominal,func,extraArg);                                          
      then (SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect,eb,ip,fn)),extraArg);
   
    case(SOME(DAE.VAR_ATTR_INT(quantity,(min,max),initial_,fixed,eb,ip,fn)),func,extraArg)
      equation
        (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
        (min,extraArg) = traverseDAEOptExp(min,func,extraArg);
        (max,extraArg) = traverseDAEOptExp(max,func,extraArg);
        (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
      then (SOME(DAE.VAR_ATTR_INT(quantity,(min,max),initial_,fixed,eb,ip,fn)),extraArg);
    
      case(SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn)),func,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
          (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
        then (SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn)),extraArg);

      case(SOME(DAE.VAR_ATTR_STRING(quantity,initial_,eb,ip,fn)),func,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        then (SOME(DAE.VAR_ATTR_STRING(quantity,initial_,eb,ip,fn)),extraArg);
        
      case(SOME(DAE.VAR_ATTR_ENUMERATION(quantity,(min,max),initial_,fixed,eb,ip,fn)),func,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        then (SOME(DAE.VAR_ATTR_ENUMERATION(quantity,(min,max),initial_,fixed,eb,ip,fn)),extraArg);

      case (NONE(),_,extraArg) then (NONE(),extraArg);        
  end matchcontinue; 
end traverseDAEVarAttr; 

end DAEUtil;
