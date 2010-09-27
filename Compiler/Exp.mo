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

package Exp
"
  file:	       Exp.mo
  package:     Exp
  description: Expressions

  RCS: $Id$

  This file contains the module `Exp\', which contains data types for
  describing expressions, after they have been examined by the
  static analyzer in the module `StaticExp\'.  There are of course
  great similarities with the expression types in the `Absyn\'
  module, but there are also several important differences.

  No overloading of operators occur, and subscripts have been
  checked to see if they are slices.  All expressions are also type
  consistent, and all implicit type conversions in the AST are made
  explicit here.

  Some expression simplification and solving is also done here. This is used
  for symbolic transformations before simulation, in order to rearrange
  equations into a form needed by simulation tools. simplify, solve,
  exp_contains, exp_equal are part of this code.

  This module also contains functions for printing expressions, to io or to
  strings. Also graphviz output is supported."

public import Absyn;
public import ClassInf;
public import DAE;
public import Graphviz;

public type ComponentRef = DAE.ComponentRef;
public type Exp = DAE.Exp;
public type Ident = String;
public type Operator = DAE.Operator;
public type Type = DAE.ExpType;
public type Subscript = DAE.Subscript;
public type Var = DAE.ExpVar;

protected import RTOpts;
protected import Util;
protected import Print;
protected import ModUtil;
protected import Derive;
protected import Dump;
//protected import Error;
protected import Debug;
protected import Static;
protected import Env;
protected import System;
protected import Builtin;
protected import DAEUtil;
protected import Algorithm;
protected import Values;
protected import ValuesUtil;
protected import Prefix;

protected constant Exp rconstone=DAE.RCONST(1.0);


public uniontype IntOp
  record MULOP end MULOP;
  record DIVOP end DIVOP;
  record ADDOP end ADDOP;
  record SUBOP end SUBOP;
  record POWOP end POWOP;
end IntOp;

public function flattenArrayExpToList "returns all non-array expressions of an array expression as a long list
E.g. {[1,2;3,4],[4,5;6,7]} => {1,2,3,4,4,5,6,7}"
  input Exp e;
  output list<Exp> expLst;
algorithm
  expLst := matchcontinue(e)
  local
    list<Exp> expl;
    list<list<tuple<Exp,Boolean>>> mexpl;
    case(DAE.ARRAY(array=expl)) equation
      expLst = Util.listFlatten(Util.listMap(expl,flattenArrayExpToList));
    then expLst;
    case(DAE.MATRIX(scalar=mexpl)) equation
      expLst = Util.listFlatten(Util.listMap(Util.listFlatten(Util.listListMap(mexpl,Util.tuple21)),flattenArrayExpToList));
    then expLst;
    case(e) then {e};
  end matchcontinue;
end flattenArrayExpToList;



public function realToIntIfPossible
"converts to ICONST if possible. If it does
 not fit, a RCONST is returned instead."
	input Real inVal;
	output Exp outVal;
algorithm
  outVal := matchcontinue(inVal)
  	local
  	  	Integer i;
    case	(inVal)
      equation
       	 i = realInt(inVal);
     	then
				DAE.ICONST(i);
    case	(inVal)
    	then
				DAE.RCONST(inVal);
	end matchcontinue;
end realToIntIfPossible;


public function safeIntOp
	"Safe mul, add, sub or pow operations for integers.
	 The function returns an integer if possible, otherwise a real.
	"
	input Integer val1;
	input Integer val2;
	input IntOp op;
	output Exp outv;
algorithm
  outv :=
  	matchcontinue(val1, val2, op)
  		local
  		  Real rv1,rv2,rv3;
  		  case (val1,val2, MULOP)
  		    equation
  		      rv1 = intReal(val1);
  		      rv2 = intReal(val2);
  		      rv3 = rv1 *. rv2;
  		      outv = realToIntIfPossible(rv3);
  		  then
  		    	outv;
  		  case (val1,val2, DIVOP)
  		    local
  		      Integer ires;
  		    equation
  		      ires = val1 / val2;
  		  then
  		    	DAE.ICONST(ires);

  		  case (val1,val2, SUBOP)
  		    equation
  		      rv1 = intReal(val1);
  		      rv2 = intReal(val2);
  		      rv3 = rv1 -. rv2;
  		      outv = realToIntIfPossible(rv3);
  		  then
  		    	outv;
  		  case (val1,val2, ADDOP)
  		    equation
  		      rv1 = intReal(val1);
  		      rv2 = intReal(val2);
  		      rv3 = rv1 +. rv2;
  		      outv = realToIntIfPossible(rv3);
  		  then
  		    	outv;
  		  case (val1,val2, POWOP)
  		    equation
  		      rv1 = intReal(val1);
  		      rv2 = intReal(val2);
  		      rv3 = realPow(rv1,rv2);
  		      outv = realToIntIfPossible(rv3);
  		  then
  		    	outv;
		end matchcontinue;
end safeIntOp;


public function dumpExpWithTitle
  input String title;
  input Exp exp;
  protected String str;
algorithm
  str := dumpExpStr(exp,0);
  print(title);
  print(str);
  print("\n");
end dumpExpWithTitle;


public function dumpExp
  input Exp exp;
  protected String str;
algorithm
  str := dumpExpStr(exp,0);
  print(str);
  print("--------------------\n");
end dumpExp;

public function crefPrependIdent "prepends (e..g as a suffix) an identifier to a component reference, given the identifier, subscript and the type
author: PA

Example
crefPrependIdent(a.b,c,{},Real) => a.b.c [Real]
crefPrependIdent(a,c,{1},Integer[1]) => a.c[1] [Integer[1]]

alternative names: crefAddSuffix, crefAddIdent
"
  input ComponentRef cr;
  input String ident;  
  input list<DAE.Subscript> subs;
  input DAE.ExpType tp;
  output ComponentRef newCr;
algorithm
  newCr := matchcontinue(cr,ident,subs,tp)
  local DAE.ExpType tp1; String id1; list<DAE.Subscript> subs1;
    case(DAE.CREF_IDENT(id1,tp1,subs1),ident,subs,tp) then DAE.CREF_QUAL(id1,tp1,subs1,DAE.CREF_IDENT(ident,tp,subs));
    case(DAE.CREF_QUAL(id1,tp1,subs1,cr),ident,subs,tp) equation
      cr = crefPrependIdent(cr,ident,subs,tp);
    then DAE.CREF_QUAL(id1,tp1,subs1,cr);
  end matchcontinue;
end crefPrependIdent;

public function crefToPath
"function: crefToPath
  This function converts a ComponentRef to a Path, if possible.
  If the component reference contains subscripts, it will silently
  fail."
  input ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath:=
  matchcontinue (inComponentRef)
    local
      Ident i;
      Absyn.Path p;
      ComponentRef c;
    case DAE.CREF_IDENT(ident = i,subscriptLst = {}) then Absyn.IDENT(i);
    case DAE.CREF_QUAL(ident = i,subscriptLst = {},componentRef = c)
      equation
        p = crefToPath(c);
      then
        Absyn.QUALIFIED(i,p);
  end matchcontinue;
end crefToPath;

public function crefLastPath
  "Returns the last identifier of a cref as an Absyn.IDENT."
  input ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inComponentRef)
    local
      Ident i;
      ComponentRef c;
    case DAE.CREF_IDENT(ident = i, subscriptLst = {}) then Absyn.IDENT(i);
    case DAE.CREF_QUAL(componentRef = c, subscriptLst = {}) then crefLastPath(c);
  end matchcontinue;
end crefLastPath;

public function pathToCref
"function: pathToCref
  This function converts a Absyn.Path to a ComponentRef."
  input Absyn.Path inPath;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inPath)
    local
      Ident i;
      ComponentRef c;
      Absyn.Path p;
    case Absyn.IDENT(name = i) then DAE.CREF_IDENT(i,DAE.ET_OTHER(),{});
    case (Absyn.FULLYQUALIFIED(p)) then pathToCref(p);
    case Absyn.QUALIFIED(name = i,path = p)
      equation
        c = pathToCref(p);        
      then
        DAE.CREF_QUAL(i,DAE.ET_OTHER(),{},c);
  end matchcontinue;
end pathToCref;

public function crefSortFunc "A sorting function (greatherThan) for crefs"
  input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean greaterThan;
algorithm
  greaterThan := System.strcmp(printComponentRefStr(cr1),printComponentRefStr(cr2)) > 0;
end crefSortFunc;

public function crefStr
"function: crefStr
  This function simply converts a ComponentRef to a String."
  input ComponentRef inComponentRef;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef)
    local
      Ident s,ns,s1,ss;
      ComponentRef n;
    case (DAE.CREF_IDENT(ident = s)) then s;
    case (DAE.CREF_QUAL(ident = s,componentRef = n))
      equation
        ns = crefStr(n);
        s1 = stringAppend(s, ".");
        ss = stringAppend(s1, ns);
      then
        ss;
  end matchcontinue;
end crefStr;

public function crefModelicaStr
"function: crefModelicaStr
  Same as crefStr, but uses _ instead of . "
  input ComponentRef inComponentRef;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef)
    local
      Ident s,ns,s1,ss;
      ComponentRef n;
    case (DAE.CREF_IDENT(ident = s)) then s;
    case (DAE.CREF_QUAL(ident = s,componentRef = n))
      equation
        ns = crefModelicaStr(n);
        s1 = stringAppend(s, "_");
        ss = stringAppend(s1, ns);
      then
        ss;
  end matchcontinue;
end crefModelicaStr;

public function crefLastIdent
"function: crefLastIdent
  author: PA
  Returns the last identfifier of a ComponentRef."
  input ComponentRef inComponentRef;
  output Ident outIdent;
algorithm
  outIdent:=
  matchcontinue (inComponentRef)
    local
      Ident id,res;
      ComponentRef cr;
    case (DAE.CREF_IDENT(ident = id)) then id;
    case (DAE.CREF_QUAL(componentRef = cr))
      equation
        res = crefLastIdent(cr);
      then
        res;
  end matchcontinue;
end crefLastIdent;

public function crefIdent "
  Return the last ComponentRef"
  input ComponentRef inComponentRef;
  output ComponentRef outSubscriptLst;
algorithm outSubscriptLst:= matchcontinue (inComponentRef)
    local
      Ident id;
      ComponentRef res,cr;
    case (inComponentRef as DAE.CREF_IDENT(ident = id)) then inComponentRef;
    case (DAE.CREF_QUAL(componentRef = cr))
      equation
        res = crefIdent(cr);
      then
        res;
  end matchcontinue;
end crefIdent;

public function stripCrefIdentSliceSubs "
Author BZ
Strips the SLICE-subscripts fromt the -last- subscript list. All other subscripts are not changed.
For example
x[1].y[{1,2},3,{1,3,7}] => x[1].y[3]
Alternative names: stripLastSliceSubs"
  input ComponentRef inCref;
  output ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref)
    local
      Ident id;
      ComponentRef cr;
      Type ty;
      list<Subscript> subs;
    case (DAE.CREF_IDENT(ident = id,subscriptLst=subs, identType = ty))
      equation
        subs = removeSliceSubs(subs);
    then DAE.CREF_IDENT(id,ty,subs);
    case (DAE.CREF_QUAL(componentRef = cr, identType=ty, subscriptLst=subs, ident=id))
      equation
        outCref = stripCrefIdentSliceSubs(cr);
      then
        DAE.CREF_QUAL(id,ty,subs,outCref);
  end matchcontinue;
end stripCrefIdentSliceSubs;

protected function removeSliceSubs "
helper function for stripCrefIdentSliceSubs
"
input list<Subscript> subs;
output list<Subscript> osubs;
algorithm
  osubs := matchcontinue(subs)
    local Subscript s;
    case({}) then {};
    case(DAE.SLICE(exp=_)::subs) then removeSliceSubs(subs);
    case(s::subs)
      equation
        osubs = removeSliceSubs(subs);
        then
          s::osubs;
  end matchcontinue;
end removeSliceSubs;

public function crefStripSubs "
Removes all subscript of a componentref"
  input ComponentRef inCref;
  output ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref)
    local
      Ident id;
      ComponentRef cr;
      Type ty;
    case (DAE.CREF_IDENT(ident = id,identType = ty))
    then DAE.CREF_IDENT(id,ty,{});
    case (DAE.CREF_QUAL(componentRef = cr, identType=ty, ident=id))
      equation
        outCref = crefStripSubs(cr);
      then
        DAE.CREF_QUAL(id,ty,{},outCref);
  end matchcontinue;
end crefStripSubs;

public function crefSubs "
function: crefSubs
  Return the all subscripts of a ComponentRef"
  input ComponentRef inComponentRef;
  output list<Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  matchcontinue (inComponentRef)
    local
      Ident id;
      list<Subscript> subs,res;
      ComponentRef cr;
    case (DAE.CREF_IDENT(ident = id,subscriptLst = subs))
      then subs;
    case (DAE.CREF_QUAL(componentRef = cr,subscriptLst=subs))
      equation
        res = crefSubs(cr);
        res = listAppend(subs,res);
      then
        res;
  end matchcontinue;
end crefSubs;

public function crefLastSubs "
function: crefLastSubs
  Return the last subscripts of a ComponentRef"
  input ComponentRef inComponentRef;
  output list<Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  matchcontinue (inComponentRef)
    local
      Ident id;
      list<Subscript> subs,res;
      ComponentRef cr;
    case (DAE.CREF_IDENT(ident = id,subscriptLst = subs)) then subs;
    case (DAE.CREF_QUAL(componentRef = cr))
      equation
        res = crefLastSubs(cr);
      then
        res;
  end matchcontinue;
end crefLastSubs;

public function expLastSubs
"function: expLastSubs
  Return the last subscripts of a Exp"
  input Exp inExp;
  output list<Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  matchcontinue (inExp)
    local
      ComponentRef cr;
      list<Subscript> subs;
      Exp e;
    case (DAE.CREF(componentRef=cr))
      equation
        subs = crefLastSubs(cr);
      then subs;
    case (DAE.UNARY(exp=e))
      equation
        subs = expLastSubs(e);
      then subs;
  end matchcontinue;
end expLastSubs;

public function crefStripPrefix
"Strips a prefix/cref from a component reference"
  input ComponentRef cref;
  input ComponentRef prefix;
  output ComponentRef outCref;
algorithm
	outCref := matchcontinue(cref,prefix)
	  local
	    list<Subscript> subs1,subs2;
	    ComponentRef cr1,cr2;
	    Ident id1,id2;
	    Type t2;
	  
	  case(DAE.CREF_QUAL(id1,_,subs1,cr1),DAE.CREF_IDENT(id2,_,subs2))
	    equation
	      true = stringEqual(id1, id2);
	      true = subscriptEqual(subs1,subs2);
	    then cr1;
	  
	  case(DAE.CREF_QUAL(id1,_,subs1,cr1),DAE.CREF_QUAL(id2,_,subs2,cr2))
	    equation
	      true = stringEqual(id1, id2);
	      true = subscriptEqual(subs1,subs2);
	    then crefStripPrefix(cr1,cr2);
  end matchcontinue;
end crefStripPrefix;

public function crefStripLastIdent
"Strips the last part of a component reference, i.e ident and subs"
  input ComponentRef inCr;
  output ComponentRef outCr;
algorithm
  outCr := matchcontinue(inCr)
    local 
      Ident id;
      list<Subscript> subs;
      ComponentRef cr1,cr;
      Type t2;
    
    case( DAE.CREF_QUAL(id,t2,subs,DAE.CREF_IDENT(_,_,_))) 
      then 
        DAE.CREF_IDENT(id,t2,subs);

    case(DAE.CREF_QUAL(id,t2,subs,cr)) 
      equation
        cr1 = crefStripLastIdent(cr);
      then 
        DAE.CREF_QUAL(id,t2,subs,cr1);
  end matchcontinue;
end crefStripLastIdent;

public function expStripLastIdent
"function: expStripLastIdent
  Strips the last subscripts of a Exp"
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
    local
      ComponentRef cr,cr_1;
      Type ty;
      Operator op,op1;
      Exp e,e_1;
      Boolean b;
    case (DAE.CREF(componentRef=cr))
      equation
        cr_1 = crefStripLastIdent(cr);
        ty = crefLastType(cr_1);
      then DAE.CREF(cr_1,ty);
    case (DAE.UNARY(operator=op,exp=e))
      equation
        e_1 = expStripLastIdent(e);
        ty = typeof(e_1);
        b = DAEUtil.expTypeArray(ty);
        op1 = Util.if_(b,DAE.UMINUS_ARR(ty),DAE.UMINUS(ty));
      then DAE.UNARY(op1,e_1);
  end matchcontinue;
end expStripLastIdent;

public function crefStripFirstIdent
"Strips the first part of a component reference,
i.e the identifier and eventual subscripts"
  input ComponentRef inCr;
  output ComponentRef outCr;
algorithm
  outCr := matchcontinue(inCr)
    local ComponentRef cr;  
    case( DAE.CREF_QUAL(componentRef = cr)) then cr;
  end matchcontinue;
end crefStripFirstIdent;

public function crefFirstIdent
"Returns the first part of a component reference, i.e the identifier"
  input ComponentRef inCr;
  output ComponentRef outCr;
algorithm
  outCr := matchcontinue(inCr)
    local 
      Ident id;
      list<Subscript> subs;
      ComponentRef cr;
      Type t2;
    
    case( DAE.CREF_QUAL(id,t2,subs,cr)) then DAE.CREF_IDENT(id,t2,{});
    case( DAE.CREF_IDENT(id,t2,subs)) then DAE.CREF_IDENT(id,t2,{});
  end matchcontinue;
end crefFirstIdent;

public function crefStripLastSubs
"function: crefStripLastSubs
  Strips the last subscripts of a ComponentRef"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef)
    local
      Ident id;
      list<Subscript> subs,s;
      ComponentRef cr_1,cr;
      Type t2;
    
    case (DAE.CREF_IDENT(ident = id,identType = t2,subscriptLst = subs)) then DAE.CREF_IDENT(id,t2,{});
    case (DAE.CREF_QUAL(ident = id,identType = t2,subscriptLst = s,componentRef = cr))
      equation
        cr_1 = crefStripLastSubs(cr);
      then
        DAE.CREF_QUAL(id,t2,s,cr_1);
  end matchcontinue;
end crefStripLastSubs;

public function expStripLastSubs
"function: expStripLastSubs
  Strips the last subscripts of a Exp"
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
    local
      ComponentRef cr,cr_1;
      Type ty;
      Operator op,op1;
      Exp e,e_1;
      Boolean b;
    case (DAE.CREF(componentRef=cr))
      equation
        ty = crefLastType(cr);
        cr_1 = crefStripLastSubs(cr);
      then DAE.CREF(cr_1,ty);
    case (DAE.UNARY(operator=op,exp=e))
      equation
        e_1 = expStripLastSubs(e);
        ty = typeof(e_1);
        b = DAEUtil.expTypeArray(ty);
        op1 = Util.if_(b,DAE.UMINUS_ARR(ty),DAE.UMINUS(ty));
      then DAE.UNARY(op1,e_1);
  end matchcontinue;
end expStripLastSubs;

public function crefSetLastSubs "
"
  input ComponentRef inComponentRef;
  input list<Subscript> insubs;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef := matchcontinue (inComponentRef,insubs)
    local
      Ident id;
      list<Subscript> subs,s;
      ComponentRef cr_1,cr;
      Type t2;
    case (DAE.CREF_IDENT(ident = id,identType = t2,subscriptLst = subs),insubs) then DAE.CREF_IDENT(id,t2,insubs);
    case (DAE.CREF_QUAL(ident = id,identType = t2,subscriptLst = s,componentRef = cr),insubs)
      equation
        cr_1 = crefSetLastSubs(cr,insubs);
      then
        DAE.CREF_QUAL(id,t2,s,cr_1);
  end matchcontinue;
end crefSetLastSubs;

public function crefStripLastSubsStringified
"function crefStripLastSubsStringified
  author: PA
  Same as crefStripLastSubs but works on
  a stringified component ref instead."
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef)
    local
      list<Ident> lst,lst_1;
      Ident id_1,id;
      ComponentRef cr;
      Type t2;
    case (DAE.CREF_IDENT(ident = id,identType = t2,subscriptLst = {}))
      equation
        //print("\n +++++++++++++++++++++++++++++ ");print(id);print("\n");
        lst = Util.stringSplitAtChar(id, "[");
        lst_1 = Util.listStripLast(lst);
        id_1 = Util.stringDelimitList(lst_1, "[");
      then
        DAE.CREF_IDENT(id_1,t2,{});
    case (cr) then cr;
  end matchcontinue;
end crefStripLastSubsStringified;

public function crefContainedIn
"function: crefContainedIn
  author: PA
  Returns true if y is a sub component ref of x.
  For instance, b.c. is a sub_component of a.b.c."
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef1,inComponentRef2)
    local
      ComponentRef x,y,cr2;
      Boolean res;
    case (x,y) /* x y */
      equation
        true = crefEqualNoStringCompare(x, y);
      then
        true;
    case (DAE.CREF_QUAL(componentRef = cr2),y)
      equation
        res = crefContainedIn(cr2,y);
      then
        res;
    case (_,_) then false;
  end matchcontinue;
end crefContainedIn;

public function crefIsIdent
"returns true if ComponentRef is an ident,
 i.e a => true , a.b => false"
  input ComponentRef cr;
  output Boolean res;
algorithm
  res := matchcontinue(cr)
    case(DAE.CREF_IDENT(_,_,_)) then true;
    case(_) then false;
  end matchcontinue;
end crefIsIdent;

/*
public function crefPrefixOf
"function: crefPrefixOf
  author: PA
  Returns true if prefixCref is a prefix of fullCref
  For example, a.b is a prefix of a.b.c"
  input ComponentRef prefixCref;
  input ComponentRef fullCref;
  output Boolean outBoolean;
algorithm
  //System.startTimer();
  outBoolean := crefPrefixOf_dispatch(prefixCref, fullCref);
  //System.stopTimer();
end crefPrefixOf;
*/

public function crefPrefixOf
"function: crefPrefixOf
  author: PA
  Returns true if prefixCref is a prefix of fullCref
  For example, a.b is a prefix of a.b.c"
  input ComponentRef prefixCref;
  input ComponentRef fullCref;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (prefixCref,fullCref)
    local
      ComponentRef cr1,cr2;
      Boolean res;
      Ident id1,id2;
      list<Subscript> ss1,ss2;
      Type t2,t22;
    
    // first is qualified, second is an unqualified ident, return false!
    case (DAE.CREF_QUAL(ident = _), DAE.CREF_IDENT(ident = _)) then false;
    
    // both are qualified, dive into
    case (DAE.CREF_QUAL(ident = id1, subscriptLst = ss1,componentRef = cr1),
          DAE.CREF_QUAL(ident = id2, subscriptLst = ss2,componentRef = cr2))
      equation
        true = stringEqual(id1, id2);
        true = subscriptEqual(ss1, ss2);
        res = crefPrefixOf(cr1, cr2);
      then
        res;
    
    // first is an ID, second is qualified, see if one is prefix of the other
    case (DAE.CREF_IDENT(ident = id1,subscriptLst = ss1),
          DAE.CREF_QUAL(ident = id2,subscriptLst = ss2))
      equation
        true = stringEqual(id1, id2);
        res = subscriptEqual(ss1, ss2);
      then
        res;
    
    // they might be equal, a.b.c is a prefix of a.b.c
    case (cr1,cr2) 
      equation
        true = crefEqualNoStringCompare(cr1, cr2);
      then
        true;        
    
    // they are not a prefix of one-another
    case (cr1,cr2)
      equation
        // print("Exp.crefPrefixOf: " +& printComponentRefStr(cr1) +& " NOT PREFIX OF " +& printComponentRefStr(cr2) +& "\n");
      then false;
  end matchcontinue;
end crefPrefixOf;

public function identEqual
"function: identEqual
  author: PA
  Compares two Ident."
  input Ident inIdent1;
  input Ident inIdent2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inIdent1,inIdent2)
    local Ident id1,id2;
    case (id1,id2)
      equation
        true = stringEqual(id1, id2);
      then
        true;
    case (_,_) then false;
  end matchcontinue;
end identEqual;

public function isRange
"function: isRange
  Returns true if expression is a range expression."
  input Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    case DAE.RANGE(ty = _) then true;
    case _ then false;
  end matchcontinue;
end isRange;

public function isOne
"function: isOne
  Returns true if an expression is constant
  and has the value one, otherwise false"
  input Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    local
      Integer ival;
      Real rzero,rval;
      Boolean res;
      Type t;
      Exp e;
    case (DAE.ICONST(integer = ival))
      equation
        (ival == 1) = true;
      then
        true;
    case (DAE.RCONST(real = rval))
      equation
        rzero = intReal(1) "Due to bug in mmc, go trough a cast from int" ;
        (rzero ==. rval) = true;
      then
        true;
    case (DAE.CAST(ty = t,exp = e))
      equation
        res = isOne(e) "Casting to one is still one" ;
      then
        res;
    case (_) then false;
  end matchcontinue;
end isOne;

public function isZero
"function: isZero
  Returns true if an expression is constant
  and has the value zero, otherwise false"
  input Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    local
      Integer ival;
      Real rzero,rval;
      Boolean res;
      Type t;
      Exp e;
      list<Exp> ae;
      list<Boolean> ab;
      list<list<tuple<Exp, Boolean>>> scalar;      
      list<tuple<Exp, Boolean>> aelstlst;       
    case (DAE.ICONST(integer = ival))
      equation
        (ival == 0) = true;
      then
        true;
    case (DAE.RCONST(real = rval))
      equation
        rzero = intReal(0) "Due to bug in mmc, go trough a cast from int" ;
        (rzero ==. rval) = true;
      then
        true;
    case (DAE.CAST(ty = t,exp = e))
      equation
        res = isZero(e) "Casting to zero is still zero" ;
      then
        res;
    case(DAE.UNARY(DAE.UMINUS(_),e)) then isZero(e);
    case(DAE.ARRAY(array = ae))
      equation
        ab = Util.listMap(ae,isZero);  
        res = Util.boolAndList(ab);
      then   
        res;
    case (DAE.MATRIX(scalar = scalar))  
      equation
        aelstlst = Util.listFlatten(scalar);
        ae = Util.listMap(aelstlst,Util.tuple21);
        ab = Util.listMap(ae,isZero);  
        res = Util.boolAndList(ab);
      then   
        res;         
    case(DAE.UNARY(DAE.UMINUS_ARR(_),e)) then isZero(e);
    case (_) then false;
  end matchcontinue;
end isZero;

public function isConst
"function: isConst
  Returns true if an expression
  is constant otherwise false"
  input Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    local
      Integer ival;
      Real rval;
      Boolean bval,res,b1,b2;
      Ident sval;
      Operator op;
      Exp e,e1,e2;
      Type t;
      list<Exp> ae;
      list<Boolean> ab;
      list<list<tuple<Exp, Boolean>>> scalar;      
      list<tuple<Exp, Boolean>> aelstlst;      
    case (DAE.ICONST(integer = ival)) then true;
    case (DAE.RCONST(real = rval)) then true;
    case (DAE.BCONST(bool = bval)) then true;
    case (DAE.SCONST(string = sval)) then true;
    case (DAE.ENUM_LITERAL(name = _)) then true;

    case (DAE.UNARY(operator = op,exp = e))
      equation
        res = isConst(e);
      then
        res;
    case (DAE.CAST(ty = t,exp = e)) /* Casting to zero is still zero */
      equation
        res = isConst(e);
      then
        res;
    case (DAE.BINARY(e1,op,e2))
      equation
        b1 = isConst(e1);
        b2 = isConst(e2);
        res = boolAnd(b1,b2);
      then
        res;
    case (DAE.CREF(_,DAE.ET_ENUMERATION(index = SOME(_)))) then true;
    case (DAE.ARRAY(array = ae))  
      equation
        ab = Util.listMap(ae,isConst);  
        res = Util.boolAndList(ab);
      then   
        res;   
    case (DAE.MATRIX(scalar = scalar))  
      equation
        aelstlst = Util.listFlatten(scalar);
        ae = Util.listMap(aelstlst,Util.tuple21);
        ab = Util.listMap(ae,isConst);  
        res = Util.boolAndList(ab);
      then   
        res;            
    case (_) then false;
  end matchcontinue;
end isConst;

public function isNotConst
"function isNotConst
  author: PA
  Check if expression is not constant."
  input Exp e;
  output Boolean nb;
  Boolean b;
algorithm
  b := isConst(e);
  nb := boolNot(b);
end isNotConst;

public function isRecord ""
  input ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(cr)
  local 
    DAE.ComponentRef comp;
    Boolean b;
    case(DAE.CREF_IDENT(identType = DAE.ET_COMPLEX(complexClassType=ClassInf.RECORD(_)))) then true;
    case(DAE.CREF_QUAL(identType = DAE.ET_COMPLEX(complexClassType=ClassInf.RECORD(_)))) then true;
    case(DAE.CREF_QUAL(componentRef=comp))
      equation
         b = isRecord(comp);  
      then b;
    case(_) then false;
  end matchcontinue;
end isRecord;

public function isRelation
"function: isRelation
  Returns true if expression is a function expression."
  input Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    local
      Boolean b1,b2,res;
      Exp e1,e2;
    case (DAE.RELATION(exp1 = _)) then true;
    case (DAE.LUNARY(exp = DAE.RELATION(exp1 = _))) then true;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        b1 = isRelation(e1);
        b2 = isRelation(e2);
        res = boolOr(b1, b2);
      then
        res;
    case (_) then false;
  end matchcontinue;
end isRelation;

public function getRealConst "returns the expression as a Real value.
Integer constants are cast to Real"
input Exp e;
output Real v;
algorithm
  v := matchcontinue(e)
  local Integer i;
    case(DAE.RCONST(v)) then v;
    case(DAE.CAST(_,e)) then getRealConst(e);
    case(DAE.ICONST(i)) then intReal(i);
  end matchcontinue;
end getRealConst;

public function getBoolConst "returns the expression as a Boolean value.
"
input Exp e;
output Boolean b;
algorithm
  b := matchcontinue(e)
    case(DAE.BCONST(b)) then b;
  end matchcontinue;
end getBoolConst;

public function getRelations
"function: getRelations
  Retrieve all function sub expressions in an expression."
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExp)
    local
      Exp e,e1,e2,cond,tb,fb;
      list<Exp> rellst1,rellst2,rellst,rellst3,rellst4,xs;
      Type t;
      Boolean sc;
    case ((e as DAE.RELATION(exp1 = _))) then {e};
    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        rellst1 = getRelations(e1);
        rellst2 = getRelations(e2);
        rellst = listAppend(rellst1, rellst2);
      then
        rellst;
    case (DAE.LUNARY(exp = e))
      equation
        rellst = getRelations(e);
      then
        rellst;
    case (DAE.BINARY(exp1 = e1,exp2 = e2))
      equation
        rellst1 = getRelations(e1);
        rellst2 = getRelations(e2);
        rellst = listAppend(rellst1, rellst2);
      then
        rellst;
    case (DAE.IFEXP(expCond = cond,expThen = tb,expElse = fb))
      equation
        rellst1 = getRelations(cond);
        rellst2 = getRelations(tb);
        rellst3 = getRelations(fb);
        rellst4 = listAppend(rellst1, rellst2);
        rellst = listAppend(rellst3, rellst4);
      then
        rellst;
    case (DAE.ARRAY(array = {e}))
      equation
        rellst = getRelations(e);
      then
        rellst;
    case (DAE.ARRAY(ty = t,scalar = sc,array = (e :: xs)))
      equation
        rellst1 = getRelations(DAE.ARRAY(t,sc,xs));
        rellst2 = getRelations(e);
        rellst = listAppend(rellst1, rellst2);
      then
        rellst;
    case (DAE.UNARY(exp = e))
      equation
        rellst = getRelations(e);
      then
        rellst;
    case (_) then {};
  end matchcontinue;
end getRelations;

public function joinCrefs
"function: joinCrefs
  Join two component references by concatenating them."
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef1,inComponentRef2)
    local
      Ident id;
      list<Subscript> sub;
      ComponentRef cr2,cr_1,cr;
      Type t2;
    case (DAE.CREF_IDENT(ident = id, identType = t2, subscriptLst = sub),cr2) then DAE.CREF_QUAL(id,t2,sub,cr2);
    case (DAE.CREF_QUAL(ident = id, identType = t2, subscriptLst = sub,componentRef = cr),cr2)
      equation
        cr_1 = joinCrefs(cr, cr2);
      then
        DAE.CREF_QUAL(id,t2,sub,cr_1);
  end matchcontinue;
end joinCrefs;

public function crefEqual
"function: crefEqual
  Returns true if two component references are equal.
  No string comparison of unparsed crefs is performed!"
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output Boolean outBoolean;
algorithm
  outBoolean := crefEqualStringCompare(inComponentRef1,inComponentRef2);
end crefEqual;

public function crefEqualStringCompare
"function: crefEqualStringCompare
  Returns true if two component references are equal, 
  comparing strings in no other solution is found"
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef1,inComponentRef2)
    local
      Ident n1,n2,s1,s2;
      list<Subscript> idx1,idx2;
      ComponentRef cr1,cr2;
      
    // check for pointer equality first, if they point to the same thing, they are equal
    case (inComponentRef1,inComponentRef2)
      equation
        true = System.refEqual(inComponentRef1,inComponentRef2);
      then
        true;
      
    // simple identifiers
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = {}),DAE.CREF_IDENT(ident = n2,subscriptLst = {}))
      equation
        true = stringEqual(n1, n2);
      then
        true;
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = (idx1 as _::_)),DAE.CREF_IDENT(ident = n2,subscriptLst = (idx2 as _::_)))
      equation
        true = stringEqual(n1, n2);
        true = subscriptEqual(idx1, idx2);
      then
        true;
        // BZ 2009-12
        // For some reason in some examples we get crefs on different forms.
        // the compare can be crefEqual(CREF_IDENT("mycref",_,{1,2,3}),CREF_IDENT("mycref[1,2,3]",_,{}))
        // I do belive this has something to do with variable replacement and DAELow.
        // TODO: investigate reason, until then keep as is.
        // I do believe that this is the same bug as adrians qual-ident bug below.
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = {}),DAE.CREF_IDENT(ident = n2,subscriptLst = (idx2 as _::_)))
      equation
        0 = System.stringFind(n1, n2); // n2 should be first in n1!
        s1 = n2 +& "[" +& printListStr(idx2, printSubscriptStr, ",") +& "]";
        true = stringEqual(s1,n1);
      then
        true;
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = (idx2 as _::_)),DAE.CREF_IDENT(ident = n2,subscriptLst = {}))
      equation
        0 = System.stringFind(n2, n1); // n1 should be first in n2!
        s1 = n1 +& "[" +& printListStr(idx2, printSubscriptStr, ",") +& "]";
        true = stringEqual(s1,n2);
      then
        true;
    // enumerations
    case (cr1 as DAE.CREF_IDENT(ident = n1,subscriptLst = idx1),cr2 as DAE.CREF_IDENT(ident = n2,subscriptLst = idx2))
      local list<Subscript> idx1_1,idx2_1;
      equation
        true = stringEqual(n1, n2);
        (DAE.CREF_IDENT(_,_,idx1_1)) = convertEnumCref(cr1);
        (DAE.CREF_IDENT(_,_,idx2_1)) = convertEnumCref(cr2);
        true = subscriptEqual(idx1_1, idx2_1);
      then
        true;
    // qualified crefs
    case (DAE.CREF_QUAL(ident = n1,subscriptLst = idx1,componentRef = cr1),DAE.CREF_QUAL(ident = n2,subscriptLst = idx2,componentRef = cr2))
      equation
        true = stringEqual(n1, n2);
        true = crefEqualStringCompare(cr1, cr2);
        true = subscriptEqual(idx1, idx2);
      then
        true;
    // this is a VERY expensive case! Do we NEED IT??!!
    // There is a bug here somewhere or in MetaModelica Compiler (MMC).
	  // Therefore as a last resort, print the strings and compare.
	  // adrpo: this is really not needed BUT unfortunately IT IS as
	  //        QUAL(x, IDENT(y)) == IDENT(x.y)
	  //        somewhere in the compiler the lhs is replaced by the rhs
	  //        and makes this case needed! THIS SHOULD BE FIXED!! TODO! FIXME!
	  //        NOTE: THIS IS NOT A BUG IN MMC!
	  /* adrpo: comment this and try to make it work faster with the two cases below!
    case (cr1 as DAE.CREF_QUAL(ident = n1),cr2 as DAE.CREF_IDENT)
      equation
        s1 = printComponentRefStr(cr1);
        s2 = printComponentRefStr(cr2);
        true = stringEqual(s1, s2);
        // debug_print("cr1", cr1);
        // debug_print("cr2", cr2);
        // System.enableTrace();
      then
        true;
	  */
	  // the following two cases replaces the one below
	  // right cref is stringified!
    case (cr1 as DAE.CREF_QUAL(ident = n1),cr2 as DAE.CREF_IDENT(ident = n2))
      equation
        0 = System.stringFind(n2, n1); // n1 should be first in n2!
        s1 = printComponentRefStr(cr1);
        s2 = printComponentRefStr(cr2);
        true = stringEqual(s1, s2);
      then
        true;
	  // left cref is stringified!
    case (cr1 as DAE.CREF_IDENT(ident = n1),cr2 as DAE.CREF_QUAL(ident = n2))
      equation
        0 = System.stringFind(n1, n2); // n2 should be first in n1!
        s1 = printComponentRefStr(cr1);
        s2 = printComponentRefStr(cr2);
        true = stringEqual(s1, s2);
      then
        true;
    // the crefs are not equal!
     case (_,_) then false;
  end matchcontinue;
end crefEqualStringCompare;

public function crefEqualNoStringCompare
"function: crefEqualNoStringCompare
  Returns true if two component references are equal!
  IMPORTANT! do not use this function if you have
  stringified components, meaning this function will
  return false for: cref1: QUAL(x, IDENT(x)) != cref2: IDENT(x.y)"
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef1,inComponentRef2)
    local
      Ident n1,n2,s1,s2;
      list<Subscript> idx1,idx2;
      ComponentRef cr1,cr2;

    // check for pointer equality first, if they point to the same thing, they are equal
    case (inComponentRef1,inComponentRef2)
      equation
        true = System.refEqual(inComponentRef1,inComponentRef2);
      then
        true;

    // simple identifiers
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = idx1),DAE.CREF_IDENT(ident = n2,subscriptLst = idx2))
      equation
        true = stringEqual(n1, n2);
        true = subscriptEqual(idx1, idx2);
      then
        true;
    // enumerations
    case (cr1 as DAE.CREF_IDENT(ident = n1,subscriptLst = idx1),cr2 as DAE.CREF_IDENT(ident = n2,subscriptLst = idx2))
      local list<Subscript> idx1_1,idx2_1;
      equation
        true = stringEqual(n1, n2);
        (DAE.CREF_IDENT(_,_,idx1_1)) = convertEnumCref(cr1);
        (DAE.CREF_IDENT(_,_,idx2_1)) = convertEnumCref(cr2);
        true = subscriptEqual(idx1_1, idx2_1);
      then
        true;
    // qualified crefs
    case (DAE.CREF_QUAL(ident = n1,subscriptLst = idx1,componentRef = cr1),DAE.CREF_QUAL(ident = n2,subscriptLst = idx2,componentRef = cr2))
      equation
        true = stringEqual(n1, n2);
        true = crefEqualNoStringCompare(cr1, cr2);
        true = subscriptEqual(idx1, idx2);
      then
        true;
    // the crefs are not equal!
    case (_,_) then false;
  end matchcontinue;
end crefEqualNoStringCompare;

public function prependSubscriptExp
"Prepends a subscript to a CREF expression
 For instance a.b[1,2] with subscript 'i' becomes a.b[i,1,2]."
input Exp exp;
input Subscript subscr;
output Exp outExp;
algorithm
  outexp := matchcontinue(exp,subscr)
  local Type t; ComponentRef cr,cr1,cr2;
    list<Subscript> subs;
    case(DAE.CREF(cr,t),subscr) equation
      cr1 = crefStripLastSubs(cr);
      subs = crefLastSubs(cr);
      cr2 = subscriptCref(cr1,subscr::subs);
    then DAE.CREF(cr2,t);
  end matchcontinue;
end prependSubscriptExp;

public function crefEqualReturn
"function: crefEqualReturn
  author: PA
  Checks if two crefs are equal and if
  so returns the cref, otherwise fail."
  input ComponentRef cr;
  input ComponentRef cr2;
  output ComponentRef cr;
algorithm
  true := crefEqual(cr, cr2);
end crefEqualReturn;

public function subscriptExp
"function: subscriptExp
  Returns the expression in a subscript index.
  If the subscript is not an index the function fails.x"
  input Subscript inSubscript;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inSubscript)
    local Exp e;
    case (DAE.INDEX(exp = e)) then e;
  end matchcontinue;
end subscriptExp;

public function subscriptEqual
"function: subscriptEqual
  Returns true if two subscript lists are equal."
  input list<Subscript> inSubscriptLst1;
  input list<Subscript> inSubscriptLst2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inSubscriptLst1,inSubscriptLst2)
    local
      Boolean res;
      list<Subscript> xs1,xs2;
      Exp e1,e2;
      
    // both lists are empty 
    case ({},{}) then true;
    
    // wholedims as list heads, compare the rest
    case ((DAE.WHOLEDIM() :: xs1),(DAE.WHOLEDIM() :: xs2))
      equation
        res = subscriptEqual(xs1, xs2);
      then
        res;
    
    // slices as heads, compare the slice exps and then compare the rest
    case ((DAE.SLICE(exp = e1) :: xs1),(DAE.SLICE(exp = e2) :: xs2))
      equation
        res = subscriptEqual(xs1, xs2);
        true = expEqual(e1, e2);
      then
        res;
    
    // indexes as heads, compare the index exps and then compare the rest
    case ((DAE.INDEX(exp = e1) :: xs1),(DAE.INDEX(exp = e2) :: xs2))
      equation
        res = subscriptEqual(xs1, xs2);
        true = expEqual(e1, e2);
      then
        res;
    
    // subscripts are not equal, return false  
    case (_,_) then false;
  end matchcontinue;
end subscriptEqual;

public function prependStringCref
"function: prependStringCref
  Prepend a string to a component reference.
  For qualified named, this means prepending a
  string to the first identifier."
  input String inString;
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inString,inComponentRef)
    local
      Ident i_1,p,i;
      list<Subscript> s;
      ComponentRef c;
      Type t2;
    case (p,DAE.CREF_QUAL(ident = i, identType = t2, subscriptLst = s,componentRef = c))
      equation
        i_1 = stringAppend(p, i);
      then
        DAE.CREF_QUAL(i_1,t2,s,c);
    case (p,DAE.CREF_IDENT(ident = i, identType = t2, subscriptLst = s))
      equation
        i_1 = stringAppend(p, i);
      then
        DAE.CREF_IDENT(i_1,t2,s);
  end matchcontinue;
end prependStringCref;

public function extendCref
"function: extendCref
  The extendCref function extends a ComponentRef by appending
  an identifier and a (possibly empty) list of subscripts.  Adding
  the identifier A to the component reference x.y[10] would
  produce the component reference x.y[10].A, for instance."
  input ComponentRef inComponentRef;
  input Type inType;
  input Ident inIdent;
  input list<Subscript> inSubscriptLst;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef,inType,inIdent,inSubscriptLst)
    local
      Ident i1,i;
      list<Subscript> s1,s;
      ComponentRef c_1,c;
      Type t1,t2;
    case (DAE.CREF_IDENT(ident = i1,identType=t2, subscriptLst = s1),t1,i,s) then DAE.CREF_QUAL(i1,t2,s1,DAE.CREF_IDENT(i,t1,s));
    case (DAE.CREF_QUAL(ident = i1,identType=t2, subscriptLst = s1,componentRef = c),t1,i,s)
      equation
        c_1 = extendCref(c, t1,i, s);
      then
        DAE.CREF_QUAL(i1,t2,s1,c_1);
  end matchcontinue;
end extendCref;

public function applyExpSubscripts "
author: PA
Takes an arbitrary expression and applies subscripts to it. This is done by creating asub
expressions given the original expression and then simplify them.
Note: The subscripts must be INDEX

alternative names: subsriptExp (but already taken), subscriptToAsub
"
  input Exp e;
  input list<DAE.Subscript> subs; 
  output Exp res;
algorithm
  res := matchcontinue(e,subs)
  local list<DAE.Exp> expl;
    DAE.Exp s;
    DAE.Subscript sub;
    
    case(e,{}) then e;
      
    case(e,sub::subs) equation
      // Apply one subscript at a time, so simplify works fine on it.
     s = subscriptExp(sub);
     res = applyExpSubscripts(simplify(DAE.ASUB(e,{s})),subs);
    then res;
      
  end matchcontinue;
end applyExpSubscripts ;
  


public function makeAsub "creates an ASUB given an expression and an index"
  input Exp e;
  input Integer indx;
  output Exp outExp;
algorithm
  outExp := matchcontinue(e,indx)
  local list<DAE.Exp> subs;
    case(DAE.ASUB(e,subs),indx) equation
    subs = listAppend(subs,{DAE.ICONST(indx)});
    then DAE.ASUB(e,subs);

    case(e,indx) then DAE.ASUB(e,{DAE.ICONST(indx)});
  end matchcontinue;
end makeAsub;

public function subscriptCref
"function: subscriptCref
  The subscriptCref function adds a subscript to the ComponentRef
  For instance a.b with subscript 10 becomes a.b[10] and c.d[1,2]
  with subscript 3,4 becomes c.d[1,2,3,4]"
  input ComponentRef inComponentRef;
  input list<Subscript> inSubscriptLst;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef,inSubscriptLst)
    local
      list<Subscript> newsub_1,sub,newsub;
      Ident id;
      ComponentRef cref_1,cref;
      Type t2;
    case (DAE.CREF_IDENT(ident = id,subscriptLst = sub, identType = t2),newsub)
      equation
        newsub_1 = listAppend(sub, newsub);
      then
        DAE.CREF_IDENT(id, t2, newsub_1);
    case (DAE.CREF_QUAL(ident = id,subscriptLst = sub,componentRef = cref, identType = t2),newsub)
      equation
        cref_1 = subscriptCref(cref, newsub);
      then
        DAE.CREF_QUAL(id, t2, sub,cref_1);
  end matchcontinue;
end subscriptCref;

/*
 * - Utility functions
 *   These are utility functions used
 *   in some of the other functions.
 */

public function intSubscripts
"function: intSubscripts
  This function describes the function between a list of integers
  and a list of DAE.Subscript where each integer is converted to
  an integer indexing expression."
  input list<Integer> inIntegerLst;
  output list<Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  matchcontinue (inIntegerLst)
    local
      list<Subscript> xs_1;
      Integer x;
      list<Integer> xs;
    case {} then {};
    case (x :: xs)
      equation
        xs_1 = intSubscripts(xs);
      then
        (DAE.INDEX(DAE.ICONST(x)) :: xs_1);
  end matchcontinue;
end intSubscripts;

public function subscriptsInt "
function: subscriptsInt
  author: PA
  This function creates a list of ints from
  a subscript list, see also intSubscripts."
  input list<Subscript> inSubscriptLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inSubscriptLst)
    local
      list<Integer> xs_1;
      Integer x;
      list<Subscript> xs;
    case {} then {};
    case (DAE.INDEX(exp = DAE.ICONST(integer = x)) :: xs)
      equation
        xs_1 = subscriptsInt(xs);
      then
        (x :: xs_1);
    case (DAE.INDEX(exp = DAE.ENUM_LITERAL(index = x)) :: xs)
      equation
        xs_1 = subscriptsInt(xs);
      then
        (x :: xs_1);
  end matchcontinue;
end subscriptsInt;

public function subscriptString
  "Returns a string representation of a subscript."
  input Subscript subscript;
  output String str;
algorithm
  str := matchcontinue(subscript)
    local
      Integer i;
      String res;
      Absyn.Path enum_lit;
    case (DAE.INDEX(exp = DAE.ICONST(integer = i)))
      equation
        res = intString(i);
      then
        res;
    case (DAE.INDEX(exp = DAE.ENUM_LITERAL(name = enum_lit)))
      equation
        res = Absyn.pathString(enum_lit);
      then
        res;
  end matchcontinue;
end subscriptString;

public function simplify "function simplify
  Simplifies expressions"
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
    local Exp e, eNew;
    case (e)
      equation
        true = RTOpts.getNoSimplify();
        eNew = simplify1(e);
      then eNew;
    case (e)
      equation
        // Debug.fprintln("simplify","SIMPLIFY BEFORE->" +& printExpStr(e));
        eNew = simplify1(e); // Basic local simplifications
        // Debug.fprintln("simplify","SIMPLIFY INTERMEDIATE->" +& printExpStr(eNew));
        eNew = simplify2(eNew); // Advanced (global) simplifications
        // Debug.fprintln("simplify","SIMPLIFY FINAL->" +& printExpStr(eNew));
      then eNew;
  end matchcontinue;
end simplify;

public function simplify1
"function: simplify1
  This function does some very basic simplification
  on expressions, like 0*a = 0, [1][1] => 1, etc."
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      Real v,rv;
      Integer n,i_1,i;
      Exp e,res,exp,c,f,t_1,f_1,e1_1,exp_1,e1,e_1,e2,e2_1,e3_1,e3,cond,sub;
      Type t,tp_1,tp,tp1,tp2,t1;
      Boolean b,remove_if;
      Ident idn;
      list<Exp> exps,exps_1,expl_1;
      list<tuple<Exp, Boolean>> expl;
      list<Boolean> bls;
      list<Subscript> s,s_1;
      ComponentRef c_1;
      Operator op;
      String before, after;
      Real time1,time2;
    
    // noEvent propagated to relations and event triggering functions
    case(DAE.CALL(Absyn.IDENT("noEvent"),{e},tpl,builtin,tp,inline))
      local
        Boolean tpl,builtin;
        DAE.InlineType inline;
        Type tp;
      equation
        e1 = simplify1(stripNoEvent(e));
        e2 = addNoEventToRelations(e1);
        e3 = addNoEventToEventTriggeringFunctions(e2);
      then 
        e3;
    
    // normal call 
    case(DAE.CALL(fn,expl,tpl,builtin,tp,inline))
      local
        Boolean tpl,builtin;
        DAE.InlineType inline;
        Type tp;
        list<Exp> expl;
        Absyn.Path fn;
      equation
        expl = Util.listMap(expl,simplify1);
        true = Util.listFold(Util.listMap(expl,isConst),boolAnd,true);
        e2 = simplifyBuiltinConstantCalls(DAE.CALL(fn,expl,tpl,builtin,tp,inline));
      then 
        e2;
    
    // simplify some builtin calls, like cross, etc
    case(DAE.CALL(fn,expl,tpl,builtin as true,tp,inline))
      local
        Boolean tpl,builtin;
        DAE.InlineType inline;
        Type tp;
        list<Exp> expl;
        Absyn.Path fn;
      equation
        e2 = simplifyBuiltinCalls(DAE.CALL(fn,expl,tpl,builtin,tp,inline));
      then 
        e2;
    
    // cast from real to real
    case (DAE.CAST(ty = DAE.ET_REAL(),exp=e ))
      local Exp e; Real v;
      equation
        DAE.RCONST(v) = simplify1(e);
      then 
        DAE.RCONST(v);
    
    // cast from integer to real
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e))
      local Integer v;
      equation
        DAE.ICONST(v) = simplify1(e);
        rv = intReal(v);
      then
        DAE.RCONST(rv);
    
    // cast of array
    case (DAE.CAST(ty = tp,exp = e))
      equation
        DAE.ARRAY(t,b,exps) = simplify1(e);
        tp_1 = unliftArray(tp);
        exps_1 = Util.listMap1(exps, addCast, tp_1);
    		exps_1 = Util.listMap(exps_1,simplify1);
        res = DAE.ARRAY(tp,b,exps_1);
      then
        res;
    
    // simplify cast in an if expression
    case(DAE.CAST(tp,DAE.IFEXP(cond,e1,e2))) 
      equation
        e1_1 = simplify1(DAE.CAST(tp,e1));
        e2_1 = simplify1(DAE.CAST(tp,e2));
      then 
        DAE.IFEXP(cond,e1_1,e2_1);
    
    // simplify cast of matrix expressions
    case (DAE.CAST(ty = tp,exp = e))
      local list<list<tuple<Exp, Boolean>>> exps,exps_1;
      equation
        DAE.MATRIX(t,n,exps) = simplify1(e);
        tp1 = unliftArray(tp);
        tp2 = unliftArray(tp1);
        exps_1 = matrixExpMap1(exps, addCast, tp2);
        res = simplify1(DAE.MATRIX(tp,n,exps_1));
      then
        res;
    
    // if expression already has a specified cast type.
    case (DAE.CAST(ty = tp,exp = e))
      local ComponentRef cr; Exp e1; Type t1,t2;
      equation
        t1 = arrayEltType(tp);
        e1 = simplify1(e);
        t2 = arrayEltType(typeof(e1));
        equality(t1 = t2);
      then
        e1;
    
    // simplify identity 
    case DAE.CALL( (path as Absyn.IDENT(name = "identity")), {DAE.ICONST(n)}, b,b2, t,b3)
      local
        Boolean b2;DAE.InlineType b3; Absyn.Path path;
        Integer n;
        list<DAE.Exp> matrix; // list of arrays
        DAE.Exp e;
      equation
        matrix = simplifyIdentity(1,n);
        e = DAE.ARRAY(
          DAE.ET_ARRAY(
            DAE.ET_ARRAY(DAE.ET_INT,{DAE.DIM_INTEGER(3)}),
            {DAE.DIM_INTEGER(n),DAE.DIM_INTEGER(n)}
          ),
          false,matrix);
      then
        e;
    
    // simplify argument expression of functions
    case DAE.CALL( path, exps_1, b,b2, t,b3)
      local Boolean b2;DAE.InlineType b3; Absyn.Path path;
      equation
        exps_1 = Util.listMap(exps_1,simplify1);
      then
        DAE.CALL(path,exps_1,b,b2,t,b3);
    
    // simplify arrays
    case DAE.ARRAY( t, b,exps_1)
      equation
        exps_1 = Util.listMap(exps_1,simplify1);
      then
        DAE.ARRAY( t, b,exps_1);
    
    // simplify matrix
    case DAE.MATRIX( t, i, matr)
      local
        list<list<tuple<Exp, Boolean>>> matr,matr2;
      equation
        matr2 = Util.listMap(matr,simplifyMatrixRows);
      then
        DAE.MATRIX( t, i, matr2);
    
    // simplify partially evaluated functions
    case DAE.PARTEVALFUNCTION(path, exps_1, t)
      local Absyn.Path path;
      equation
        exps_1 = Util.listMap(exps_1,simplify1);
      then
        DAE.PARTEVALFUNCTION(path,exps_1,t);

    // array indexing
    case DAE.ASUB(exp = e,sub = sub::{})
      local Exp ae1;
      equation
        i_1 = expInt(sub);
        DAE.ARRAY(t,b,exps) = simplify1(e);
        i_1 = i_1 - 1;
        exp = listNth(exps, i_1);
      then
        exp;
    
    // matrix indexing 
    case DAE.ASUB(exp = e,sub = sub::{})
      local list<list<tuple<Exp, Boolean>>> exps; Exp ae1;
      equation
        i_1 = expInt(sub);
        DAE.MATRIX(t,n,exps) = simplify1(e);
        t1 = unliftArray(t);
        i_1 = i_1 - 1;
        (expl) = listNth(exps, i_1);
        (expl_1,bls) = Util.splitTuple2List(expl);
        b = Util.boolAndList(bls);
      then
        DAE.ARRAY(t1,b,expl_1);
    
    // if expression indexing
    case DAE.ASUB(exp = e,sub = sub::{})
      local Exp t,ae1;
      equation
        _ = expInt(sub);
        DAE.IFEXP(c,t,f) = simplify1(e);
        t_1 = simplify1(DAE.ASUB(t,{sub}));
        f_1 = simplify1(DAE.ASUB(f,{sub}));
      then
        DAE.IFEXP(c,t_1,f_1);
    
    // ident cref indexing
    case DAE.ASUB(exp = e,sub = sub::{})
      local Exp ae1;Type t2;
      equation
        _ = expInt(sub);
        DAE.CREF(DAE.CREF_IDENT(idn,t2,s),t) = simplify1(e);
        t = unliftArray(t);
        s_1 = subscriptsAppend(s, sub);
      then
        DAE.CREF(DAE.CREF_IDENT(idn,t2,s_1),t);
    
    // qualified cref indexing
    case DAE.ASUB(exp = e,sub = sub::{})
      local
        ComponentRef c;
        Exp ae1;
        Type t2;
      equation
        _ = expInt(sub);
        DAE.CREF(DAE.CREF_QUAL(idn,t2,s,c),t) = simplify1(e);
        DAE.CREF(c_1,t) = simplify1(DAE.ASUB(DAE.CREF(c,t),{sub}));
      then
        DAE.CREF(DAE.CREF_QUAL(idn,t2,s,c_1),t);
    
    // indexing
    case DAE.ASUB(exp = e,sub = sub::{})
      local
        Exp ae1;
      equation
        _ = expInt(sub);
        e = simplifyAsub(e, sub) "For arbitrary vector operations, e.g (a+b-c)[1] => a[1]+b[1]-c[1]" ;
      then
        e;
    
    // unary operations
    case ((exp as DAE.UNARY(operator = op,exp = e1))) 
      equation
        e1_1 = simplify1(e1);
        exp_1 = DAE.UNARY(op,e1_1);
        e = simplifyUnary(exp_1, op, e1_1);
      then
        e;
    
    // binary operations on arrays
    case ((exp as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))) 
      equation
        e_1 = simplifyBinaryArray(e1, op, e2);
      then
        e_1;
    
    // binary scalar simplifications
    case ((exp as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2)))
      local String s1,s2; Boolean b;
      equation
        e1_1 = simplify1(e1);
        e2_1 = simplify1(e2);
        exp_1 = DAE.BINARY(e1_1,op,e2_1);
        e_1 = simplifyBinary(exp_1, op, e1_1, e2_1);
      then
        e_1;
    
    // relations 
    case ((exp as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)))
      equation
        e1_1 = simplify1(e1);
        e2_1 = simplify1(e2);
        exp_1 = DAE.RELATION(e1_1,op,e2_1);
        e = simplifyBinary(exp_1, op, e1_1, e2_1);
      then
        e;
    
    // logical unary expressions
    case ((exp as DAE.LUNARY(operator = op,exp = e1)))
      equation
        e1_1 = simplify1(e1);
        exp_1 = DAE.LUNARY(op,e1_1);
        e = simplifyUnary(exp_1, op, e1_1);
      then
        e;
    
    // logical binary expressions
    case ((exp as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)))
      equation
        e1_1 = simplify1(e1);
        e2_1 = simplify1(e2);
        exp_1 = DAE.LBINARY(e1_1,op,e2_1);
        e = simplifyBinary(exp_1, op, e1_1, e2_1);
      then
        e;
    
    // if condition is constant
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        e1_1 = simplify1(e1);
        true = isConst(e1_1);
        b = boolExp(e1_1);
        e2_1 = simplify1(e2);
        e3_1 = simplify1(e3);
        res = Util.if_(b,e2_1,e3_1);
      then
        res;
    
    // if true and false branches are equal
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        e1_1 = simplify1(e1);
        e2_1 = simplify1(e2);
        e3_1 = simplify1(e3);
        remove_if = expEqual(e2_1, e3_1);
        res = Util.if_(remove_if, e2_1, DAE.IFEXP(e1,e2_1,e3_1));
      then
        res;
    
    // component references
    case DAE.CREF(componentRef = c_1 as DAE.CREF_IDENT(idn,_,s),ty=t)
      local
        Integer lInt;
        list<Exp> expl_1;
        Exp exp1;
      equation
        exp1 = simplifyCref(c_1,t);
      then
        exp1;
    
    // anything else
    case e
      then
        e;
  end matchcontinue;
end simplify1;

protected function simplifyBuiltinCalls "simplifies some builtin calls (with no constant expressions"
  input Exp exp "NOTE: assumes call arguments NOT YET SIMPLIFIED (for efficiency reasons)";
  output Exp outExp;
algorithm
  outExp := matchcontinue(exp)
    local
      list<DAE.Exp> expl;
      DAE.Exp e;
      DAE.ExpType tp;
    case (e as DAE.CALL(path = Absyn.IDENT("cross"), builtin = true, expLst = expl))
      local
        list<DAE.Exp> v1, v2;
        Boolean scalar;
      equation
        expl = Util.listMap(expl, simplify1);
        {DAE.ARRAY(array = v1),DAE.ARRAY(array = v2)} = expl;
        expl = Static.elabBuiltinCross2(v1, v2);
        tp = typeof(e);
        // Since there is a bug somewhere in simplify that gives wrong types for arrays we take the type from cross.
        scalar = not isArrayType(unliftArray(tp));
        outExp = simplify(DAE.ARRAY(tp, scalar,expl));    
      then outExp;
    // Simplify built-in function fill. MathCore depends on this being done here, do not remove!
    case (DAE.CALL(path = Absyn.IDENT("fill"), builtin = true, expLst = expl))
      local
        list<Values.Value> valueLst;
      equation
        expl = Util.listMap(expl, simplify1);
        e::expl = expl;
        valueLst = Util.listMap(expl, ValuesUtil.expValue);
        (_,outExp,_) = Static.elabBuiltinFill2(Env.emptyCache(), Env.emptyEnv, e, (DAE.T_NOTYPE, NONE), valueLst, DAE.C_CONST,Prefix.NOPRE());
      then
        outExp;
  end matchcontinue;
end simplifyBuiltinCalls;

protected function simplifyBuiltinConstantCalls "simplifies some builtin calls if constant arguments"
  input Exp exp "assumes already simplified call arguments";
  output Exp outExp;
algorithm
  outExp := matchcontinue(exp)
  local 
    Real r,v1,v2; 
    Integer i, j; 
    Absyn.Path path; Exp e,e1;
    Boolean b;
    
    // der(constant) ==> 0
    case(DAE.CALL(path=Absyn.IDENT("der"),expLst ={e})) 
      equation
        true = isConst(e);
      e1 = simplifyBuiltinConstantDer(e);
    then e1;
    
    // sqrt function
    case(DAE.CALL(path=path,expLst={e})) 
      equation
        Builtin.isSqrt(path);
        r = realSqrt(getRealConst(e));
      then 
        DAE.RCONST(r);
    
    // abs on real
    case(DAE.CALL(path=Absyn.IDENT("abs"),expLst={DAE.RCONST(r)})) 
      equation
        r = realAbs(r);
      then 
        DAE.RCONST(r);
    
    // abs on integer 
    case(DAE.CALL(path=Absyn.IDENT("abs"),expLst={DAE.ICONST(i)})) 
      equation
        i = intAbs(i);
      then 
        DAE.ICONST(i);
    
    // sin function
    case(DAE.CALL(path=path,expLst={e})) 
      equation
        Builtin.isSin(path);
        r = realSin(getRealConst(e));
      then 
        DAE.RCONST(r);
    
    // cos function
    case(DAE.CALL(path=path,expLst={e})) 
      equation
        Builtin.isCos(path);
        r = realCos(getRealConst(e));
      then 
        DAE.RCONST(r);
    
    // tangent function
    case(DAE.CALL(path=path,expLst={e})) 
      equation
        Builtin.isTan(path);
        v1 = realSin(getRealConst(e));
        v2 = realCos(getRealConst(e));
        r = v1 /. v2;
      then 
        DAE.RCONST(r);
    
    // exp function
    case(DAE.CALL(path=path,expLst={e})) 
      equation
        Builtin.isExp(path);
        r = realExp(getRealConst(e));
      then 
        DAE.RCONST(r);
    
    // log function
    case(DAE.CALL(path=path,expLst={e})) 
      equation
        Builtin.isLog(path);
        r = System.log(getRealConst(e));
      then 
        DAE.RCONST(r);
        
    // min function on integers
    case(DAE.CALL(path=path,expLst={DAE.ICONST(i), DAE.ICONST(j)}))
      equation
        Builtin.isMin(path);
        i = intMin(i, j);
      then
        DAE.ICONST(i);

    // min function on reals
    case(DAE.CALL(path=path,expLst={e, e1})) 
      equation
        Builtin.isMin(path);
        v1 = getRealConst(e);
        v2 = getRealConst(e1);
        r = realMin(v1, v2);
      then 
        DAE.RCONST(r);  

    // min function on integers
    case(DAE.CALL(path=path,expLst={DAE.ICONST(i), DAE.ICONST(j)}))
      equation
        Builtin.isMax(path);
        i = intMax(i, j);
      then
        DAE.ICONST(i);

    // max function on reals
    case(DAE.CALL(path=path,expLst={e, e1})) 
      equation
        Builtin.isMax(path);
        v1 = getRealConst(e);
        v2 = getRealConst(e1);
        r = realMax(v1, v2);
      then 
        DAE.RCONST(r);              
  end matchcontinue;
end simplifyBuiltinConstantCalls;

protected function simplifyMatrixRows ""
  input list<tuple<Exp, Boolean>> inRow;
  output list<tuple<Exp, Boolean>> outRow;
algorithm 
  outRow := matchcontinue(inRow)
    local
      Exp e,e_1;
      Boolean b;
  
    case({}) then {};
    case((e,b)::inRow)
      equation
        e_1 = simplify(e);
        outRow = simplifyMatrixRows(inRow);
      then
        (e_1,b)::outRow;
  end matchcontinue;
end simplifyMatrixRows;

protected function simplifyIdentity ""
  input Integer row;
  input Integer n;
  output list<DAE.Exp> outExp;
algorithm
  outExp := matchcontinue(row,n)
    local
      list<DAE.Exp> rowExps;
      DAE.Exp arrExp;
    
    case(row,n) // bottom right
      equation
        true = intEq(row,n);
        rowExps = simplifyIdentityMakeRow(n,1,row);
      then
       {DAE.ARRAY(DAE.ET_ARRAY(DAE.ET_INT,{DAE.DIM_INTEGER(n)}),true,rowExps)};
    
    case(row,n) // bottom right
      equation
        true = row < n;
        rowExps = simplifyIdentityMakeRow(n,1,row);
        outExp = simplifyIdentity(row+1,n);
        arrExp = DAE.ARRAY(DAE.ET_ARRAY(DAE.ET_INT,{DAE.DIM_INTEGER(n)}),true,rowExps);
      then
        arrExp::outExp;
  end matchcontinue;
end simplifyIdentity;

/*
protected function simplifyIdentity ""
  input Integer row;
  input Integer n;
  output list<list<DAE.Exp>> outExp;
algorithm
  outExp := matchcontinue(row,n)
    local
      list<DAE.Exp> rowExps;
    case(row,n) // bottom right
      equation
        true = intEq(row,n);
        rowExps = simplifyIdentityMakeRow(n,1,row);
      then
        {rowExps};
    case(row,n) // bottom right
      equation
        true = intEq(row,n);
        rowExps = simplifyIdentityMakeRow(n,1,row);
        outExp = simplifyIdentity(row+1,n);
      then
        rowExps::outExp;
  end matchcontinue;
end simplifyIdentity;
*/
protected function simplifyIdentityMakeRow ""
  input Integer n;
  input Integer col;
  input Integer row;
  output list<DAE.Exp> expl;
algorithm
  expl := matchcontinue(n,col,row)
    local
      Integer i;
    
    case(n,col,row)
      equation
        true = intEq(n,col);
        i = Util.if_(intEq(col,row),1,0);
      then
        {DAE.ICONST(i)};
    
    case(n,col,row)
      equation
        true = col < n;
        i = Util.if_(intEq(col,row),1,0);
        expl = simplifyIdentityMakeRow(n,col+1,row);
      then
        DAE.ICONST(i)::expl;
  end matchcontinue;
end simplifyIdentityMakeRow;

public function stripNoEvent
"Function that strips all noEvent() calls in an expression"
  input Exp e;
  output Exp outE;
algorithm
  ((outE,_)) := traverseExp(e,stripNoEventExp,0);
end stripNoEvent;

protected function stripNoEventExp "
traversal function for stripNoEvent"
  input tuple<Exp,Integer/*dummy*/> inTpl;
  output tuple<Exp,Integer> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local Exp e; Integer i;
    case((DAE.CALL(path=Absyn.IDENT("noEvent"),expLst={e}),i)) then ((e,i));
    case((e,i)) then ((e,i));
  end matchcontinue;
end stripNoEventExp;

public function addNoEventToRelations
"Function that adds a  noEvent() call to all relations in an expression"
  input Exp e;
  output Exp outE;
algorithm
  ((outE,_)) := traverseExp(e,addNoEventToRelationExp,0);
end addNoEventToRelations;

protected function addNoEventToRelationExp "
traversal function for addNoEventToRelations"
  input tuple<Exp,Integer/*dummy*/> inTpl;
  output tuple<Exp,Integer> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local Exp e; Integer i;
    case((e as DAE.RELATION(exp1=_),i)) then ((DAE.CALL(Absyn.IDENT("noEvent"),{e},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),i));
    case((e,i)) then ((e,i));
  end matchcontinue;
end addNoEventToRelationExp;

public function addNoEventToEventTriggeringFunctions
" Function that adds a  noEvent() call to all event triggering functions in an expression"
  input Exp e;
  output Exp outE;
algorithm
  ((outE,_)) := traverseExp(e,addNoEventToEventTriggeringFunctionsExp,0);
end addNoEventToEventTriggeringFunctions;

protected function addNoEventToEventTriggeringFunctionsExp "
traversal function for addNoEventToEventTriggeringFunctions"
  input tuple<Exp,Integer/*dummy*/> inTpl;
  output tuple<Exp,Integer> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local Exp e; Integer i;
    case (((e as DAE.CALL(path=_)), i))
      equation
        true = isEventTriggeringFunctionExp(e);
      then ((DAE.CALL(Absyn.IDENT("noEvent"),{e},false,true,DAE.ET_BOOL(),DAE.NO_INLINE),i));
    case ((e,i)) then ((e,i));
  end matchcontinue;
end addNoEventToEventTriggeringFunctionsExp;

protected function isEventTriggeringFunctionExp
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB := matchcontinue(inExp)
    case (DAE.CALL(path = Absyn.IDENT("div"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("mod"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("rem"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("ceil"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("floor"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("integer"))) then true;
    case (_) then false;
  end matchcontinue;
end isEventTriggeringFunctionExp;

protected function simplifyCref
" Function for simplifying
  x[{y,z,q}] to {x[y], x[z], x[q]}"
  input ComponentRef inCREF;
  input Type inType;
  output Exp exp;
algorithm
  outExpLst := matchcontinue(inCREF, inType)
    local
      Type t,t2;
      list<Subscript> ssl;
    case(DAE.CREF_IDENT(idn,t2,(ssl as ((DAE.SLICE(DAE.ARRAY(_,_,expl_1))) :: _))),t)
      local
        Ident idn;
        list<Exp> expl_1;
      equation
        exp = simplifyCref2(DAE.CREF(DAE.CREF_IDENT(idn,t2,{}),t),ssl);
      then
        exp;
  end matchcontinue;
end simplifyCref;

protected function simplifyCref2
"Helper function for simplifyCref
 Does the recursion."
  input Exp inExp;
  input list<Subscript> inSsl;
  output Exp outExp;
algorithm
  outExp := matchcontinue(inExp,inSsl)
    local
      Ident idn;
      Type t,tp;
      Exp exp_1, crefExp, exp;
      list<Exp> expl_1,expl;
      Subscript ss;
      list<Subscript> ssl,ssl_2,subs;
      list<ComponentRef> crefs;
      ComponentRef cr;
      Integer dim;
 	  Boolean sc;

    case(exp_1,{}) then exp_1;

    case(DAE.CREF(cr as DAE.CREF_IDENT(idn, _,ssl_2),t), ((ss as (DAE.SLICE(DAE.ARRAY(_,_,(expl_1))))) :: ssl))
      equation
        subs = Util.listMap(expl_1,makeIndexSubscript);
        crefs = Util.listMap1r(Util.listMap(subs,Util.listCreate),subscriptCref,cr);
        expl = Util.listMap1(crefs,makeCrefExp,t);
        dim = listLength(expl);
        exp = simplifyCref2(DAE.ARRAY(DAE.ET_ARRAY(t,{DAE.DIM_INTEGER(dim)}),true,expl),ssl);
      then
        exp;
 	case(crefExp as DAE.ARRAY(tp,sc,expl), ssl )
 	  equation
     expl = Util.listMap1(expl,simplifyCref2,ssl);
   then
     DAE.ARRAY(tp,sc,expl);

  end matchcontinue;
end simplifyCref2;

public function simplify2
"Advanced simplifications covering several
 terms or factors, like a +2a +3a = 5a "
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
  local Exp e,exp,e1,e2,e1_1,e2_1,exp_2,exp_3;
     Operator op;
    case ((exp as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))) /* multiple terms/factor simplifications */
      local String s1,s2; Boolean b;
      equation
        true = isIntegerOrReal(typeof(exp));
        e1 = simplify2(e1);
        e2 = simplify2(e2);
        /* Sorting constants, 1+a+2+b => 3+a+b */
        exp_2 = simplifyBinarySortConstants(DAE.BINARY(e1,op,e2));
        /* Merging coefficients 2a+4b+3a+b => 5a+5b */
        exp_3 = simplifyBinaryCoeff(exp_2);
      then
        exp_3;
    case(DAE.UNARY(op,e1)) equation
      e1 = simplify2(e1);
    then DAE.UNARY(op,e1);

    case (e) then e;
  end matchcontinue;
end simplify2;

protected function simplifyBinaryArray "function: simplifyBinaryArray
  Simplifies binary array expressions,
  e.g. matrix multiplication, etc."
  input Exp inExp1;
  input Operator inOperator2;
  input Exp inExp3;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inOperator2,inExp3)
    local
      Exp e_1,e1,e2,res,s1,a1;
      Type tp;

    case (e1,DAE.MUL_MATRIX_PRODUCT(ty = tp),e2)
      equation
        e1 = simplify1(e1);
        e2 = simplify1(e2);        
        e_1 = simplifyMatrixProduct(e1, e2);
      then
        e_1;

    case (e1,DAE.ADD_ARR(ty = _),e2)
      equation
        tp = typeof(e1);
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        a1 = simplifyVectorBinary(e1, DAE.ADD(tp), e2);
        res = simplify1(a1);
      then
        res;

    case (e1,DAE.ADD_ARR(ty = _),e2)
      equation
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        true = isZero(e1);
      then
        e2;

    case (e1,DAE.ADD_ARR(ty = _),e2)
      equation
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        true = isZero(e2);
      then
        e1;

    case (e1,DAE.SUB_ARR(ty = _),e2)
      equation
        tp = typeof(e1);
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        a1 = simplifyVectorBinary(e1, DAE.SUB(tp), e2);
        res = simplify1(a1);
      then
        res;

    case (e1,DAE.SUB_ARR(ty = tp),e2)
      equation
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        true = isZero(e1);
        res = DAE.UNARY(DAE.UMINUS_ARR(tp),e2);
      then
        res;

    case (e1,DAE.SUB_ARR(ty = _),e2)
      equation
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        true = isZero(e2);
      then
        e1;

    case (e1,DAE.MUL_ARR(ty = _),e2)
      equation
        tp = typeof(e1);
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        a1 = simplifyVectorBinary(e1, DAE.MUL(tp), e2);
        res = simplify1(a1);
      then
        res;

    case (e1,DAE.DIV_ARR(ty = _),e2)
      equation
        tp = typeof(e1);
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        a1 = simplifyVectorBinary(e1, DAE.DIV(tp), e2);
        res = simplify1(a1);
      then
        res;

    case (e1,DAE.POW_ARR(ty = _),e2)
      equation
        tp = typeof(e1);
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        a1 = simplifyMatrixPow(e1, tp, e2);
        res = simplify1(a1);
      then
        res;

    case (e1,DAE.POW_ARR2(ty = _),e2)
      equation
        tp = typeof(e1);
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        a1 = simplifyVectorBinary(e1, DAE.POW(tp), e2);
        res = simplify1(a1);
      then
        res;

    // v1 - -v2 => v1 + v2
    case(e1,DAE.SUB_ARR(ty=tp),e2)
      equation
        (DAE.UNARY(_,e2)) = simplify1(e2);
				e1 = simplify1(e1);
      then DAE.BINARY(e1,DAE.ADD_ARR(tp),e2);

    // v1 + -v2 => v1 - v2
    case(e1,DAE.ADD_ARR(ty=tp),e2)
      equation
        (DAE.UNARY(_,e2)) = simplify1(e2);
        e1 = simplify1(e1);
      then DAE.BINARY(e1,DAE.SUB_ARR(tp),e2);

    // scalar * matrix
    case (s1,DAE.MUL_SCALAR_ARRAY(ty = tp),a1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        (a1 as DAE.MATRIX(scalar=_)) = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(unliftArray(atp));
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.MUL_SCALAR_ARRAY(atp2),DAE.MUL(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // scalar * array
    case (s1,DAE.MUL_SCALAR_ARRAY(ty = tp),a1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        a1 = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(atp);        
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.MUL_SCALAR_ARRAY(atp2),DAE.MUL(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // matrix * scalar
    case (a1,DAE.MUL_ARRAY_SCALAR(ty = tp),s1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        (a1 as DAE.MATRIX(scalar =_)) = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(unliftArray(atp));
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.MUL_ARRAY_SCALAR(atp2),DAE.MUL(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // array * scalar
    case (a1,DAE.MUL_ARRAY_SCALAR(ty = tp),s1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        a1 = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.MUL_ARRAY_SCALAR(atp2),DAE.MUL(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // scalar .+ array
    case (s1,DAE.ADD_SCALAR_ARRAY(ty = tp),a1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        a1 = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.ADD_SCALAR_ARRAY(atp2),DAE.ADD(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // array .+ scalar
    case (a1,DAE.ADD_ARRAY_SCALAR(ty = tp),s1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        a1 = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.ADD_ARRAY_SCALAR(atp2),DAE.ADD(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // scalar .- array
    case (s1,DAE.SUB_SCALAR_ARRAY(ty = tp),a1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        a1 = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.SUB_SCALAR_ARRAY(atp2),DAE.SUB(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // array .- scalar
    case (a1,DAE.SUB_ARRAY_SCALAR(ty = tp),s1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        a1 = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.SUB_ARRAY_SCALAR(atp2),DAE.SUB(tp));
        res = simplifyVectorScalar(a1, op2, s1);
      then
        res;

    // scalar ./ array
    case (s1,DAE.DIV_SCALAR_ARRAY(ty = tp),a1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        a1 = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.DIV_SCALAR_ARRAY(atp2),DAE.DIV(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // matrix / scalar
    case (a1,DAE.DIV_ARRAY_SCALAR(ty = tp),s1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        (a1 as DAE.MATRIX(scalar =_)) = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(unliftArray(atp));
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.DIV_ARRAY_SCALAR(atp2),DAE.DIV(tp));
        res = simplifyVectorScalar(a1, op2, s1);
      then
        res;

    // array / scalar
    case (a1,DAE.DIV_ARRAY_SCALAR(ty = tp),s1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        a1 = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.DIV_ARRAY_SCALAR(atp2),DAE.DIV(tp));
        res = simplifyVectorScalar(a1, op2, s1);
      then
        res;

    // scalar .^ array
    case (s1,DAE.POW_SCALAR_ARRAY(ty = tp),a1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        a1 = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.POW_SCALAR_ARRAY(atp2),DAE.POW(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // array .+ scalar
    case (a1,DAE.POW_ARRAY_SCALAR(ty = tp),s1)
      local Boolean b; Operator op2; Type atp,atp2;
      equation
        a1 = simplify1(a1);
        s1 = simplify(s1);
        tp = typeof(s1);
        atp = typeof(a1);
        atp2 = unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.POW_ARRAY_SCALAR(atp2),DAE.POW(tp));
        res = simplifyVectorScalar(a1, op2, s1);
      then
        res;

    case (e1,DAE.MUL_SCALAR_PRODUCT(ty = tp),e2)
      equation
        e1 = simplify1(e1);
        e2 = simplify1(e2);         
        res = simplifyScalarProduct(e1, e2);
      then
        res;

    case (e1,DAE.MUL_MATRIX_PRODUCT(ty = tp),e2)
      equation
        e1 = simplify1(e1);
        e2 = simplify1(e2);         
        res = simplifyScalarProduct(e1, e2);
      then
        res;

    case (e1,DAE.ADD_ARR(ty = _),e2)
      equation
        tp = typeof(e1);
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        a1 = simplifyMatrixBinary(e1, DAE.ADD(tp), e2);
        res = simplify1(a1);
      then
        res;

    case (e1,DAE.SUB_ARR(ty = _),e2)
      equation
        tp = typeof(e1);
        e1 = simplify1(e1);
        e2 = simplify1(e2);
        a1 = simplifyMatrixBinary(e1, DAE.SUB(tp), e2);
        res = simplify1(a1);
      then
        res;         
  end matchcontinue;
end simplifyBinaryArray;

public function simplifyScalarProduct
"function: simplifyScalarProduct
  author: PA
  Simplifies scalar product:
   v1v2, M  v1 and v1  M
  for vectors v1,v2 and matrix M."
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inExp2)
    local
      list<Exp> expl,expl1,expl2,expl_1;
      Exp exp;
      Type tp1,tp2,tp;
      Boolean sc1,sc2,sc;
      Integer size1,size;
    case (DAE.ARRAY(ty = tp1,scalar = sc1,array = expl1),DAE.ARRAY(ty = tp2,scalar = sc2,array = expl2)) /* v1  v2 */
      equation
        expl = Util.listThreadMap(expl1, expl2, expMul);
        exp = simplify1(Util.listReduce(expl, expAdd));
      then
        exp;
    // M * v1, use first dimension of M as the dimension of the result, in case the array has dimension 1, i.e. is a scalar.
    case (DAE.MATRIX(ty = DAE.ET_ARRAY(ty = tp1, arrayDimensions = d :: _), scalar = expl1),DAE.ARRAY(scalar = sc,array = expl2))
      local 
        list<list<tuple<Exp, Boolean>>> expl1;
        DAE.Dimension d;
      equation
        expl_1 = simplifyScalarProductMatrixVector(expl1, expl2);
      then
        DAE.ARRAY(DAE.ET_ARRAY(tp1, {d}),sc,expl_1);
    case (DAE.ARRAY(ty = tp1,scalar = sc,array = expl1),DAE.MATRIX(ty = tp2,integer = size,scalar = expl2))
      local list<list<tuple<Exp, Boolean>>> expl2;
      equation
        expl_1 = simplifyScalarProductVectorMatrix(expl1, expl2);
      then
        DAE.ARRAY(tp2,sc,expl_1);
    case (DAE.ARRAY(ty = tp as DAE.ET_ARRAY(arrayDimensions= _::_::{}),array = expl1),exp as DAE.ARRAY(ty = tp2,scalar = sc,array = expl2))
      equation 
        expl_1 = simplifyScalarProductMatrixVector1(expl1, expl2);
      then
        DAE.ARRAY(tp2,sc,expl_1);       
  end matchcontinue;
end simplifyScalarProduct;

protected function simplifyScalarProductMatrixVector
"function: simplifyScalarProductMatrixVector
  Simplifies scalar product of matrix  vector."
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  input list<Exp> inExpLst;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inTplExpBooleanLstLst,inExpLst)
    local
      list<Exp> row_1,expl,res,v1;
      Exp exp;
      list<tuple<Exp, Boolean>> row;
      list<list<tuple<Exp, Boolean>>> rows;
    case ({},_) then {};

    case ((row :: rows),v1)
      local Integer x;
      equation
        row_1 = Util.listMap(row, Util.tuple21);
        x = listLength(row_1);
        true = (x<=0);
        res = simplifyScalarProductMatrixVector(rows, v1);
      then
        (DAE.ICONST(0) :: res);
    case ((row :: rows),v1)
      equation
        row_1 = Util.listMap(row, Util.tuple21);
        expl = Util.listThreadMap(row_1, v1, expMul);
        exp = simplify1(Util.listReduce(expl, expAdd));
        res = simplifyScalarProductMatrixVector(rows, v1);
      then
        (exp :: res);
  end matchcontinue;
end simplifyScalarProductMatrixVector;

protected function simplifyScalarProductMatrixVector1
"function: simplifyScalarProductMatrixVector1
  Simplifies scalar product of matrix  vector."
  input list<Exp> inExpLst;
  input list<Exp> inExpLst1;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst,inExpLst1)
    local
      list<Exp> row,rows,res,v1,expl;
      Exp exp;
    case ({},_) then {};
    case ((DAE.ARRAY(array=row) :: rows),v1)
      equation
        expl = Util.listThreadMap(row, v1, expMul);
        exp = simplify1(Util.listReduce(expl, expAdd));
        res = simplifyScalarProductMatrixVector1(rows, v1);
      then
        (exp :: res);
  end matchcontinue;
end simplifyScalarProductMatrixVector1;

protected function simplifyScalarProductVectorMatrix
"function: simplifyScalarProductVectorMatrix
  Simplifies scalar product of vector  matrix"
  input list<Exp> inExpLst;
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst,inTplExpBooleanLstLst) // non working
    local
      list<Exp> row_1,expl,res,v1,expl;
      Exp exp;
      tuple<Exp, Boolean> texp;
      list<tuple<Exp, Boolean>> row;
      list<list<tuple<Exp, Boolean>>> rows;
    case (v1,  ((texp :: {}) :: rows)    )
      local
        list<tuple<Exp, Boolean>> heads;
      equation
        heads = Util.listMap(((texp :: {}) :: rows),Util.listFirst);
        row_1 = Util.listMap(heads, Util.tuple21);
        expl = Util.listThreadMap(v1, row_1, expMul);
        exp = simplify1(Util.listReduce(expl, expAdd));
      then
        (exp :: {});
    case (v1,(rows))
      local
        list<tuple<Exp, Boolean>> heads;
        list<list<tuple<Exp, Boolean>>> tails;
      equation
        heads = Util.listMap((rows),Util.listFirst);
        tails = Util.listMap((rows),Util.listRest);
        row_1 = Util.listMap(heads, Util.tuple21);
        expl = Util.listThreadMap(v1, row_1, expMul);
        exp = simplify1(Util.listReduce(expl, expAdd));
        res = simplifyScalarProductVectorMatrix(v1, tails);
      then
        (exp :: res);
  end matchcontinue;
end simplifyScalarProductVectorMatrix;

protected function simplifyVectorScalar
"function: simplifyVectorScalar
  Simplifies vector scalar operations."
  input Exp inExp1;
  input Operator inOperator2;
  input Exp inExp3;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inOperator2,inExp3)
    local
      Exp s1,e1,e;
      Operator op;
      Type tp;
      Boolean sc;
      list<Exp> es_1,es;
      list<list<tuple<Exp, Boolean>>> mexpl;
      Integer dims;
    /* scalar operator array */
    case (s1,op,DAE.ARRAY(ty = tp,scalar = sc,array = {})) then DAE.ARRAY(tp,sc,{DAE.BINARY(s1,op,DAE.ICONST(0))});
    case (s1,op,DAE.ARRAY(ty = tp,scalar = sc,array = {e1})) then DAE.ARRAY(tp,sc,{DAE.BINARY(s1,op,e1)});
    case (s1,op,DAE.ARRAY(ty = tp,scalar = sc,array = (e1 :: es)))
      equation
        DAE.ARRAY(_,_,es_1) = simplifyVectorScalar(s1, op, DAE.ARRAY(tp,sc,es));
      then
        DAE.ARRAY(tp,sc,(DAE.BINARY(s1,op,e1) :: es_1));

    case (s1,op,DAE.MATRIX(tp,dims,mexpl)) equation
      mexpl = simplifyVectorScalarMatrix(mexpl,op,s1,false /*scalar-array*/);
    then DAE.MATRIX(tp,dims,mexpl);

    /* array operator scalar */
    case (DAE.ARRAY(ty = tp,scalar = sc,array = {}),op,s1) then DAE.ARRAY(tp,sc,{/*DAE.BINARY(DAE.ICONST(0),op,s1)*/});
    case (DAE.ARRAY(ty = tp,scalar = sc,array = {e1}),op,s1) equation
      e = simplify1(DAE.BINARY(e1,op,s1));
    then DAE.ARRAY(tp,sc,{e});

    case (DAE.ARRAY(ty = tp,scalar = sc,array = (e1 :: es)),op,s1)
      equation
        DAE.ARRAY(_,_,es_1) = simplifyVectorScalar(DAE.ARRAY(tp,sc,es),op,s1);
        e = simplify1(DAE.BINARY(e1,op,s1));
      then
        DAE.ARRAY(tp,sc,(e :: es_1));

    case (DAE.MATRIX(tp,dims,mexpl),op,s1) equation
      mexpl = simplifyVectorScalarMatrix(mexpl,op,s1,true/*array-scalar*/);
    then DAE.MATRIX(tp,dims,mexpl);
  end matchcontinue;
end simplifyVectorScalar;

protected function simplifyVectorBinary
"function: simlify_binary_array
  author: PA
  Simplifies vector addition and subtraction"
  input Exp inExp1;
  input Operator inOperator2;
  input Exp inExp3;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inOperator2,inExp3)
    local
      Type tp1,tp2;
      Boolean scalar1,scalar2;
      Exp e1,e2;
      Operator op,op2;
      list<Exp> es_1,es1,es2;
    case (DAE.ARRAY(ty = tp1,scalar = scalar1,array = {e1}),
          op,
         DAE.ARRAY(ty = tp2,scalar = scalar2,array = {e2}))
      equation
        op2 = removeOperatorDimension(op);
      then DAE.ARRAY(tp1,scalar1,{DAE.BINARY(e1,op2,e2)});  /* resulting operator */

    case (DAE.ARRAY(ty = tp1,scalar = scalar1,array = (e1 :: es1)),
          op,
          DAE.ARRAY(ty = tp2,scalar = scalar2,array = (e2 :: es2)))
      equation
        DAE.ARRAY(_,_,es_1) = simplifyVectorBinary(DAE.ARRAY(tp1,scalar1,es1), op, DAE.ARRAY(tp2,scalar2,es2));
        op2 = removeOperatorDimension(op);
      then
        DAE.ARRAY(tp1,scalar1,(DAE.BINARY(e1,op2,e2) :: es_1));
  end matchcontinue;
end simplifyVectorBinary;

protected function simplifyMatrixBinary
"function: simlify_binary_matrix
  author: PA
  Simplifies matrix addition and subtraction"
  input Exp inExp1;
  input Operator inOperator2;
  input Exp inExp3;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inOperator2,inExp3)
    local
      Type tp1,tp2;
      list<list<tuple<Exp, Boolean>>> scalar;
      Integer integer1,integer2,i1,i2;
      list<tuple<Exp, Boolean>> e,e1,e2;
      Operator op,op2;
      list<list<tuple<Exp, Boolean>>> es_1,es1,es2;
      list<Exp> el1,el2;
      Exp exp1;      
    case (DAE.MATRIX(ty = tp1,integer=integer1,scalar = {e1}),
          op,
         DAE.MATRIX(ty = tp2,integer=integer2,scalar = {e2}))
      equation
        op2 = removeOperatorDimension(op);
        e = simplifyMatrixBinary1(e1,op2,e2);
      then DAE.MATRIX(tp1,integer1,{e});  /* resulting operator */

    case (DAE.MATRIX(ty = tp1,integer=integer1,scalar = (e1 :: es1)),
          op,
          DAE.MATRIX(ty = tp2,integer=integer2,scalar = (e2 :: es2)))
      equation
        op2 = removeOperatorDimension(op);
        e = simplifyMatrixBinary1(e1,op2,e2);
        i1 = integer1-1;
        i2 = integer2-1;       
        DAE.MATRIX(_,_,es_1) = simplifyMatrixBinary(DAE.MATRIX(tp1,i1,es1), op, DAE.MATRIX(tp2,i2,es2));
      then
        DAE.MATRIX(tp1,integer1,(e :: es_1));
        
    // because identity is array of array    
    case (DAE.ARRAY(ty=tp1,scalar=false,array={exp1 as DAE.ARRAY(array=el2)}),
          op,
         DAE.MATRIX(ty = tp2,integer=integer2,scalar = {e2}))
      equation
        op2 = removeOperatorDimension(op);
        e1 = Util.listMap1(el2,Util.makeTuple2,false);
        e = simplifyMatrixBinary1(e1,op2,e2);
      then DAE.MATRIX(tp2,integer2,{e});  /* resulting operator */        
        
    case (DAE.ARRAY(ty=tp1,scalar=false,array=((exp1 as DAE.ARRAY(array=el2))::el1)),
          op,     
          DAE.MATRIX(ty = tp2,integer=integer2,scalar = (e2 :: es2)))
      equation
        op2 = removeOperatorDimension(op);
        e1 = Util.listMap1(el2,Util.makeTuple2,false);
        e = simplifyMatrixBinary1(e1,op2,e2);
        i2 = integer2-1;       
        DAE.MATRIX(_,_,es_1) = simplifyMatrixBinary(DAE.ARRAY(tp1,false,el1), op, DAE.MATRIX(tp2,i2,es2));
      then
        DAE.MATRIX(tp2,integer2,(e :: es_1));
     
    case (DAE.MATRIX(ty = tp2,integer=integer2,scalar = {e2}),
          op,
         DAE.ARRAY(ty=tp1,scalar=false,array={exp1 as DAE.ARRAY(array=el2)}))
      equation
        op2 = removeOperatorDimension(op);
        e1 = Util.listMap1(el2,Util.makeTuple2,false);
        e = simplifyMatrixBinary1(e1,op2,e2);
      then DAE.MATRIX(tp2,integer2,{e});  /* resulting operator */        
        
    case (DAE.MATRIX(ty = tp2,integer=integer2,scalar = (e2 :: es2)),
          op,     
          DAE.ARRAY(ty=tp1,scalar=false,array=((exp1 as DAE.ARRAY(array=el2))::el1)))
      equation
        op2 = removeOperatorDimension(op);
        e1 = Util.listMap1(el2,Util.makeTuple2,false);
        e = simplifyMatrixBinary1(e1,op2,e2);
        i2 = integer2-1;       
        DAE.MATRIX(_,_,es_1) = simplifyMatrixBinary(DAE.ARRAY(tp1,false,el1), op, DAE.MATRIX(tp2,i2,es2));
      then
        DAE.MATRIX(tp2,integer2,(e :: es_1));     
                  
  end matchcontinue;
end simplifyMatrixBinary;

protected function simplifyMatrixBinary1
"function: simlify_binary_matrix
  author: PA
  Simplifies matrix addition and subtraction"
  input list<tuple<Exp, Boolean>> inExp1;
  input Operator inOperator2;
  input list<tuple<Exp, Boolean>> inExp3;
  output list<tuple<Exp, Boolean>> outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inOperator2,inExp3)
    local
      Exp e1,e2,e;
      Boolean b1,b2,b;
      Operator op,op2;
      list<tuple<Exp, Boolean>> es_1,es1,es2;
    case ({(e1,b1)},op,{(e2,b2)})
      equation
        op2 = removeOperatorDimension(op);
        b = b1 or b2;
        e = simplify1(DAE.BINARY(e1,op2,e2));
      then {(e,b)};  // resulting operator 
    case ((e1,b1)::es1,op,(e2,b2)::es2)
      equation
        op2 = removeOperatorDimension(op);
        b = b1 or b2;
        e = simplify1(DAE.BINARY(e1,op2,e2));
        es_1 = simplifyMatrixBinary1(es1, op, es2);
      then
        (e,b) :: es_1;
  end matchcontinue;
end simplifyMatrixBinary1;

protected function simplifyMatrixPow
"function: simplifyMatrixPow
  author: Frenkel TUD
  Simplifies matrix powers."
  input Exp inExp1;
  input Type inType;
  input Exp inExp2;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inType,inExp2)
    local
      list<list<tuple<Exp, Boolean>>> expl_1,expl1,expl2;
      list<tuple<Exp, Boolean>> el;
      Type tp1,tp;
      Integer size1,i,i_1;
      list<Integer> range;
      Exp e,m,res;
    /* A^0=I */
    case (m as DAE.MATRIX(ty = tp1,integer = size1,scalar = expl1),tp,
          DAE.ICONST(integer = i))
      equation
        0=i;
        el = Util.listFill((DAE.RCONST(0.0),true),size1);
        expl2 =  Util.listFill(el,size1);
        range = Util.listIntRange2(0,size1-1);
        expl_1 = simplifyMatrixPow1(range,expl2,(DAE.RCONST(1.0),true));
      then
        DAE.MATRIX(tp1,size1,expl_1);      
    /* A^1=A */
    case (m as DAE.MATRIX(ty = tp1,integer = size1,scalar = expl1),tp,
          DAE.ICONST(integer = i))
      equation
        1=i;
      then
        m;
    /* A^i */
    case (m as DAE.MATRIX(ty = tp1,integer = size1,scalar = expl1),tp,
          DAE.ICONST(integer = i))
      equation
        true = 1 < i;
        i_1 = i - 1;
        e = simplifyMatrixPow(m,tp1,DAE.ICONST(i_1));
        res = simplifyMatrixProduct(m,e);
      then
        res;
  end matchcontinue;
end simplifyMatrixPow;

protected function simplifyMatrixPow1
"function: simplifyMatrixPow1
  author: Frenkel TUD
  Simplifies matrix powers."
  input list<Integer> inRange;
  input list<list<tuple<Exp, Boolean>>> inMatrix;
  input tuple<Exp, Boolean> inValue;
  output list<list<tuple<Exp, Boolean>>> outMatrix;
algorithm
  outMatrix:=
  matchcontinue (inRange,inMatrix,inValue)
    local
      list<list<tuple<Exp, Boolean>>> rm,rm1;
      list<tuple<Exp, Boolean>> row,row1;
      tuple<Exp, Boolean> e;
      Integer i;
      list<Integer> rr;
    case ({},{},e)
      then
        {};      
    case (i::{},row::{},e)
      equation
        row1 = Util.listReplaceAt(e,i,row);
      then
        {row1};      
    case (i::rr,row::rm,e)
      equation
        row1 = Util.listReplaceAt(e,i,row);
        rm1 = simplifyMatrixPow1(rr,rm,e);
      then
        row1::rm1;      
  end matchcontinue;
end simplifyMatrixPow1;

protected function simplifyMatrixProduct
"function: simplifyMatrixProduct
  author: PA
  Simplifies matrix products A * B for matrices A and B."
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inExp2)
    local
      list<list<tuple<Exp, Boolean>>> expl_1,expl1,expl2;
      Type tp;
      Integer size1,size2;
      DAE.Dimension n, p, res_dim;
    /* A[n, m] * B[m, p] = C[n, p] */
    case (DAE.MATRIX(ty = DAE.ET_ARRAY(ty = tp, arrayDimensions = {n, _}),integer = size1,scalar = expl1),
          DAE.MATRIX(ty = DAE.ET_ARRAY(arrayDimensions = {_, p}),integer = size2,scalar = expl2))
      equation
        expl_1 = simplifyMatrixProduct2(expl1, expl2);
      then
        DAE.MATRIX(DAE.ET_ARRAY(tp, {n, p}),size1,expl_1);
  end matchcontinue;
end simplifyMatrixProduct;

protected function simplifyMatrixProduct2
"function: simplifyMatrixProduct2
  author: PA
  Helper function to simplifyMatrixProduct."
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst1;
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst2;
  output list<list<tuple<Exp, Boolean>>> outTplExpBooleanLstLst;
algorithm
  outTplExpBooleanLstLst:=
  matchcontinue (inTplExpBooleanLstLst1,inTplExpBooleanLstLst2)
    local
      list<tuple<Exp, Boolean>> res1,e1lst;
      list<list<tuple<Exp, Boolean>>> res2,rest1,m2;
    case ((e1lst :: rest1),m2)
      equation
        res1 = simplifyMatrixProduct3(e1lst, m2);
        res2 = simplifyMatrixProduct2(rest1, m2);
      then
        (res1 :: res2);
    case ({},_) then {};
  end matchcontinue;
end simplifyMatrixProduct2;

protected function simplifyMatrixProduct3
"function: simplifyMatrixProduct3
  author: PA
  Helper function to simplifyMatrixProduct2. Extract each column at
  a time from the second matrix to calculate vector products with the
  first argument."
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst;
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  output list<tuple<Exp, Boolean>> outTplExpBooleanLst;
algorithm
  outTplExpBooleanLst:=
  matchcontinue (inTplExpBooleanLst,inTplExpBooleanLstLst)
    local
      list<tuple<Exp, Boolean>> first_col,es,expl;
      list<list<tuple<Exp, Boolean>>> mat_1,mat;
      Exp e_1;
      Type tp;
      Boolean builtin;
    case ({},_) then {};
    case (expl,mat)
      equation
        first_col = Util.listMap(mat, Util.listFirst);
        mat_1 = Util.listMap(mat, Util.listRest);
        e_1 = simplifyMatrixProduct4(expl, first_col);
        tp = typeof(e_1);
        builtin = typeBuiltin(tp);
        es = simplifyMatrixProduct3(expl, mat_1);
      then
        ((e_1,builtin) :: es);
    case (_,_) then {};
  end matchcontinue;
end simplifyMatrixProduct3;

protected function simplifyMatrixProduct4
"function simplifyMatrixProduct4
  author: PA
  Helper function to simplifyMatrix3,
  performs a scalar mult of vectors"
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst1;
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst2;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inTplExpBooleanLst1,inTplExpBooleanLst2)
    local
      Type tp,tp_1;
      Exp e1,e2,e,res;
      list<tuple<Exp, Boolean>> es1,es2;
    case ({(e1,_)},{(e2,_)})
      equation
        tp = typeof(e1);
        tp_1 = arrayEltType(tp);
      then
        DAE.BINARY(e1,DAE.MUL(tp_1),e2);
    case (((e1,_) :: es1),((e2,_) :: es2))
      equation
        e = simplifyMatrixProduct4(es1, es2);
        tp = typeof(e);
        tp_1 = arrayEltType(tp);
        res = simplify1(DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp_1),e2),DAE.ADD(tp_1),e));
      then
        res;
  end matchcontinue;
end simplifyMatrixProduct4;

protected function addCast
"function: addCast
  Adds a cast of a Type to an expression."
  input Exp inExp;
  input Type inType;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inType)
    local
      Exp e;
      Type tp;
    case (e,tp) then DAE.CAST(tp,e);
  end matchcontinue;
end addCast;

protected function simplifyBinarySortConstants
"function: simplifyBinarySortConstants
  author: PA
  Sorts all constants of a sum or product to the
  beginning of the expression.
  Also combines expressions like 2a+4a and aaa+3a^3."
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
    local
      list<Exp> e_lst,e_lst_1,const_es1,notconst_es1,const_es1_1,e_lst_2;
      Exp res,e,e1,e2;
      Type tp;
       String str;

      /* e1 * e2 */
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2)))
        local Exp res1,res2,zero;
          Boolean b1,b2,b;
      equation
        res = simplifyBinarySortConstantsMul(e);
      then
        res;

    /* e1 / e2 */
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2))) equation
      e1 = simplifyBinarySortConstantsMul(e1);
      e2 = simplifyBinarySortConstantsMul(e2);
    then DAE.BINARY(e1,DAE.DIV(tp),e2);

    /* e1 + e2 */
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2)))
      local Exp res1,res2;
      equation
        e_lst = terms(e);
        e_lst_1 = Util.listMap(e_lst,simplify2);
        (const_es1 ) = Util.listSelect(e_lst_1, isConst);
        notconst_es1 = Util.listSelect(e_lst_1, isNotConst);
        const_es1_1 = simplifyBinaryAddConstants(const_es1);
        res1 = simplify1(makeSum(const_es1_1));
        res2 = makeSum(notconst_es1); // Cannot simplify this, if const_es1_1 empty => infinite recursion.
        res = makeSum({res1,res2});
      then
        res;

    /* return e */
    case(e) then e;
  end matchcontinue;
end simplifyBinarySortConstants;

protected function simplifyBinaryCoeff
"function: simplifyBinaryCoeff
  author: PA
  Combines expressions like 2a+4a and aaa+3a^3, etc"
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
    local
      list<Exp> e_lst,e_lst_1,e1_lst,e2_lst,e2_lst_1;
      Exp res,res1,e,e1,e2;
      Type tp;
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2)))
      equation
        e_lst = factors(e);
        e_lst_1 = simplifyMul(e_lst);
        res = makeProductLst(e_lst_1);
      then
        res;
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2)))
      equation
        e1_lst = factors(e1);
        e2_lst = factors(e2);
        e2_lst_1 = inverseFactors(e2_lst);
        e_lst = listAppend(e1_lst, e2_lst_1);
        e_lst_1 = simplifyMul(e_lst);
        res = makeProductLst(e_lst_1);
      then
        res;
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2)))
      equation
        e_lst = terms(e);
        e_lst_1 = simplifyAdd(e_lst);
        res = makeSum(e_lst_1);
      then
        res;
    case (e) then e;
  end matchcontinue;
end simplifyBinaryCoeff;

protected function simplifyBinaryAddConstants
"function: simplifyBinaryAddConstants
  author: PA
  Adds all expressions in the list, given that they are constant."
  input list<Exp> inExpLst;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst)
    local
      Exp e,e_1,e1;
      list<Exp> es;
      Type tp;
    case ({}) then {};
    case ({e}) then {e};
    case ((e1 :: es))
      equation
        {e} = simplifyBinaryAddConstants(es);
        e_1 = simplifyBinaryConst(DAE.ADD(DAE.ET_REAL()), e1, e);
      then
        {e_1};
    case (_)
      equation
        Debug.fprint("failtrace","-Exp.simplifyBinaryAddConstants failed\n");
      then
        fail();
  end matchcontinue;
end simplifyBinaryAddConstants;

protected function simplifyBinaryMulConstants
"function: simplifyBinaryMulConstants
  author: PA
  Multiplies all expressions in the list, given that they are constant."
  input list<Exp> inExpLst;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst)
    local
      Exp e,e_1,e1;
      list<Exp> es;
      Type tp;
    case ({}) then {};
    case ({e}) then {e};
    case ((e1 :: es))
      equation
        {e} = simplifyBinaryMulConstants(es);
        tp = typeof(e);
        e_1 = simplifyBinaryConst(DAE.MUL(tp), e1, e);
      then
        {e_1};
  end matchcontinue;
end simplifyBinaryMulConstants;

protected function simplifyMul
"function: simplifyMul
  author: PA
  Simplifies expressions like a*a*a*b*a*b*a"
  input list<Exp> expl;
  output list<Exp> expl_1;
//   list<Ident> sl;
//   Ident s;
  list<tuple<Exp, Real>> exp_const,exp_const_1;
  list<Exp> expl_1;
algorithm
//   sl := Util.listMap(expl, printExpStr);
//   s := Util.stringDelimitList(sl, ", ");
  exp_const := simplifyMul2(expl);
  exp_const_1 := simplifyMulJoinFactors(exp_const);
  expl_1 := simplifyMulMakePow(exp_const_1);
end simplifyMul;

protected function simplifyMul2
"function: simplifyMul2
  author: PA
  Helper function to simplifyMul."
  input list<Exp> inExpLst;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm
  outTplExpRealLst:=
  matchcontinue (inExpLst)
    local
      Exp e_1,e;
      Real coeff;
      list<tuple<Exp, Real>> rest;
      list<Exp> es;
    case ({}) then {};
    case ((e :: es))
      equation
        (e_1,coeff) = simplifyBinaryMulCoeff2(e);
        rest = simplifyMul2(es);
      then
        ((e_1,coeff) :: rest);
  end matchcontinue;
end simplifyMul2;

protected function simplifyMulJoinFactors
"function: simplifyMulJoinFactors
 author: PA
  Helper function to simplifyMul.
  Joins expressions that have the same base.
  E.g. {(a,2), (a,4), (b,2)} => {(a,6), (b,2)}"
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm
  outTplExpRealLst:=
  matchcontinue (inTplExpRealLst)
    local
      Real coeff2,coeff_1,coeff;
      list<tuple<Exp, Real>> rest_1,res,rest;
      Exp e;
    case ({}) then {};
    case (((e,coeff) :: rest))
      equation
        (coeff2,rest_1) = simplifyMulJoinFactorsFind(e, rest);
        res = simplifyMulJoinFactors(rest_1);
        coeff_1 = coeff +. coeff2;
      then
        ((e,coeff_1) :: res);
  end matchcontinue;
end simplifyMulJoinFactors;

protected function simplifyMulJoinFactorsFind
"function: simplifyMulJoinFactorsFind
  author: PA
  Helper function to simplifyMulJoinFactors.
  Searches rest of list to find all occurences of a base."
  input Exp inExp;
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output Real outReal;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm
  (outReal,outTplExpRealLst):=
  matchcontinue (inExp,inTplExpRealLst)
    local
      Real coeff2,coeff3,coeff;
      list<tuple<Exp, Real>> res,rest;
      Exp e,e2,e1;
      Type tp;
    case (_,{}) then (0.0,{});
    case (e,((e2,coeff) :: rest)) /* e1 == e2 */
      equation
        true = expEqual(e, e2);
        (coeff2,res) = simplifyMulJoinFactorsFind(e, rest);
        coeff3 = coeff +. coeff2;
      then
        (coeff3,res);
    case (e,((DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = tp),exp2 = e2),coeff) :: rest)) /* e11-e12 and e12-e11, negative -1.0 factor */
      equation
        true = expEqual(e, DAE.BINARY(e2,DAE.SUB(tp),e1));
        (coeff2,res) = simplifyMulJoinFactorsFind(e, rest);
        coeff3 = coeff -. coeff2;
      then
        (coeff3,res);
    case (e,((e2,coeff) :: rest)) /* not expEqual */
      equation
        (coeff2,res) = simplifyMulJoinFactorsFind(e, rest);
      then
        (coeff2,((e2,coeff) :: res));
  end matchcontinue;
end simplifyMulJoinFactorsFind;

protected function simplifyMulMakePow
"function: simplifyMulMakePow
  author: PA
  Helper function to simplifyMul.
  Makes each item in the list into a pow
  expression, except when exponent is 1.0."
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inTplExpRealLst)
    local
      list<Exp> res;
      Exp e;
      Real r;
      list<tuple<Exp, Real>> xs;
      Type tp;
    case ({}) then {};
    case (((e,r) :: xs))
      equation
        (r ==. 1.0) = true;
        res = simplifyMulMakePow(xs);
      then
        (e :: res);
    case (((e,r) :: xs))
      equation
        res = simplifyMulMakePow(xs);
      then
        (DAE.BINARY(e,DAE.POW(DAE.ET_REAL()),DAE.RCONST(r)) :: res);
  end matchcontinue;
end simplifyMulMakePow;

protected function simplifyAdd
"function: simplifyAdd
  author: PA
  Simplifies terms like 2a+4b+2a+a+b"
  input list<Exp> inExpLst;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst)
    local
      list<tuple<Exp, Real>> exp_const,exp_const_1;
      list<Exp> expl_1,expl;
    case (expl)
      equation
        exp_const = simplifyAdd2(expl);
        exp_const_1 = simplifyAddJoinTerms(exp_const);
        expl_1 = simplifyAddMakeMul(exp_const_1);
      then
        expl_1;
    case (_)
      equation
        Debug.fprint("failtrace","-Exp.simplifyAdd failed\n");
      then
        fail();
  end matchcontinue;
end simplifyAdd;

protected function simplifyAdd2
"function: simplifyAdd2
  author: PA
  Helper function to simplifyAdd"
  input list<Exp> inExpLst;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm
  outTplExpRealLst:=
  matchcontinue (inExpLst)
    local
      Exp e_1,e;
      Real coeff;
      list<tuple<Exp, Real>> rest;
      list<Exp> es;
    case ({}) then {};
    case ((e :: es))
      equation
        (e_1,coeff) = simplifyBinaryAddCoeff2(e);
        rest = simplifyAdd2(es);
      then
        ((e_1,coeff) :: rest);
    case (_)
      equation
        Debug.fprint("failtrace","-Exp.simplifyAdd2 failed\n");
      then
        fail();
  end matchcontinue;
end simplifyAdd2;

protected function simplifyAddJoinTerms
"function: simplifyAddJoinTerms
  author: PA
  Helper function to simplifyAdd.
  Join all terms with the same expression.
  i.e. 2a+4a gives an element (a,6) in the list."
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm
  outTplExpRealLst:=
  matchcontinue (inTplExpRealLst)
    local
      Real coeff2,coeff3,coeff;
      list<tuple<Exp, Real>> rest_1,res,rest;
      Exp e;
    case ({}) then {};
    case (((e,coeff) :: rest))
      equation
        (coeff2,rest_1) = simplifyAddJoinTermsFind(e, rest);
        res = simplifyAddJoinTerms(rest_1);
        coeff3 = coeff +. coeff2;
      then
        ((e,coeff3) :: res);
  end matchcontinue;
end simplifyAddJoinTerms;

protected function simplifyAddJoinTermsFind
"function: simplifyAddJoinTermsFind
  author: PA
  Helper function to simplifyAddJoinTerms, finds all occurences of exp."
  input Exp inExp;
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output Real outReal;
  output list<tuple<Exp, Real>> outTplExpRealLst;
algorithm
  (outReal,outTplExpRealLst):=
  matchcontinue (inExp,inTplExpRealLst)
    local
      Real coeff2,coeff3,coeff;
      list<tuple<Exp, Real>> res,rest;
      Exp e,e2;
    case (_,{}) then (0.0,{});
    case (e,((e2,coeff) :: rest))
      equation
        true = expEqual(e, e2);
        (coeff2,res) = simplifyAddJoinTermsFind(e, rest);
        coeff3 = coeff +. coeff2;
      then
        (coeff3,res);
    case (e,((e2,coeff) :: rest)) /* not expEqual */
      equation
        (coeff2,res) = simplifyAddJoinTermsFind(e, rest);
      then
        (coeff2,((e2,coeff) :: res));
  end matchcontinue;
end simplifyAddJoinTermsFind;

protected function simplifyAddMakeMul
"function: simplifyAddMakeMul
  author: PA
  Makes multiplications of each element
  in the list, except for coefficient 1.0"
  input list<tuple<Exp, Real>> inTplExpRealLst;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inTplExpRealLst)
    local
      list<Exp> res;
      Exp e;
      Real r;
      list<tuple<Exp, Real>> xs;
      Type tp;
    case ({}) then {};
    case (((e,r) :: xs))
      equation
        (r ==. 1.0) = true;
        res = simplifyAddMakeMul(xs);
      then
        (e :: res);
    case (((e,r) :: xs))
      local Integer tmpInt;
      equation
        DAE.ET_INT() = typeof(e);
        res = simplifyAddMakeMul(xs);
        tmpInt = realInt(r);
      then
        (DAE.BINARY(DAE.ICONST(tmpInt),DAE.MUL(DAE.ET_INT()),e) :: res);
    case (((e,r) :: xs))
      equation
        res = simplifyAddMakeMul(xs);
      then
        (DAE.BINARY(DAE.RCONST(r),DAE.MUL(DAE.ET_REAL()),e) :: res);
  end matchcontinue;
end simplifyAddMakeMul;

protected function makeFactorDivision
"function: makeFactorDivision
  author: PA
  Takes two expression lists (factors) and makes a division of
  the two. If the second list is empty, no division node is created."
  input list<Exp> inExpLst1;
  input list<Exp> inExpLst2;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExpLst1,inExpLst2)
    local
      list<Exp> const_es1,notconst_es1,es1_1,es1,const_es2,notconst_es2,es2_1,es2;
      Exp res,res_1,e1,q,q_1,p,p_1;
    case ({},{}) then DAE.RCONST(1.0);
    case (es1,{})
      equation
        const_es1 = Util.listSelect(es1, isConst);
        notconst_es1 = Util.listSelect(es1, isNotConst);
        es1_1 = listAppend(const_es1, notconst_es1);
        res = makeProductLst(es1_1);
        res_1 = simplify1(res);
      then
        res_1;
    case (es1,{e1}) /* e1...en / 1.0 => e1...en */
      equation
        true = isConstOne(e1);
        res = makeProductLst(es1);
      then
        res;
    case ({},es2)
      equation
        const_es2 = Util.listSelect(es2, isConst);
        notconst_es2 = Util.listSelect(es2, isNotConst);
        es2_1 = listAppend(const_es2, notconst_es2);
        q = makeProductLst(es2_1);
        q_1 = simplify1(q);
      then
        DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),q_1);
    case (es1,es2)
      equation
        const_es1 = Util.listSelect(es1, isConst);
        notconst_es1 = Util.listSelect(es1, isNotConst);
        es1_1 = listAppend(const_es1, notconst_es1);
        const_es2 = Util.listSelect(es2, isConst);
        notconst_es2 = Util.listSelect(es2, isNotConst);
        es2_1 = listAppend(const_es2, notconst_es2);
        p = makeProductLst(es1_1);
        q = makeProductLst(es2_1);
        p_1 = simplify1(p);
        q_1 = simplify1(q);
      then
        DAE.BINARY(p_1,DAE.DIV(DAE.ET_REAL()),q_1);
  end matchcontinue;
end makeFactorDivision;

protected function removeCommonFactors
"function: removeCommonFactors
  author: PA
  Takes two lists of expressions (factors) and removes the
  factors common to both lists. The special case of the
  ident^exp is treated by subtraction of the exponentials."
  input list<Exp> inExpLst1;
  input list<Exp> inExpLst2;
  output list<Exp> outExpLst1;
  output list<Exp> outExpLst2;
algorithm
  (outExpLst1,outExpLst2):=
  matchcontinue (inExpLst1,inExpLst2)
    local
      Exp e2,pow_e,e1,e;
      list<Exp> es2_1,es1_1,es2_2,es1,es2;
      ComponentRef cr;
      Type tp;
    case ((DAE.BINARY(exp1 = DAE.CREF(componentRef = cr,ty = tp),
           operator = DAE.POW(ty = _),exp2 = e1) :: es1),es2)
      equation
        (DAE.BINARY(_,DAE.POW(_),e2),es2_1) = findPowFactor(cr, es2);
        (es1_1,es2_2) = removeCommonFactors(es1, es2_1);
        pow_e = simplify1(DAE.BINARY(DAE.CREF(cr,tp),DAE.POW(DAE.ET_REAL()),DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2)));
      then
        ((pow_e :: es1_1),es2_2);

    case ((e :: es1),es2)
      equation
        _ = Util.listGetMemberOnTrue(e, es2, expEqual);
        es2_1 = Util.listDeleteMemberOnTrue(es2, e, expEqual);
        (es1_1,es2_2) = removeCommonFactors(es1, es2_1);
      then
        (es1_1,es2_2);

    case ((e :: es1),es2)
      equation
        (es1_1,es2_1) = removeCommonFactors(es1, es2);
      then
        ((e :: es1_1),es2_1);

    case ({},es2) then ({},es2);
  end matchcontinue;
end removeCommonFactors;

protected function findPowFactor
"function findPowFactor
  author: PA
  Helper function to removeCommonFactors.
  Finds a POW expression in a list of factors."
  input ComponentRef inComponentRef;
  input list<Exp> inExpLst;
  output Exp outExp;
  output list<Exp> outExpLst;
algorithm
  (outExp,outExpLst):=
  matchcontinue (inComponentRef,inExpLst)
    local
      ComponentRef cr,cr2;
      Exp e,pow_e;
      list<Exp> es;
    case (cr,((e as DAE.BINARY(exp1 = DAE.CREF(componentRef = cr2),
                           operator = DAE.POW(ty = _))) :: es))
      equation
        true = crefEqual(cr, cr2);
      then
        (e,es);
    case (cr,(e :: es))
      equation
        (pow_e,es) = findPowFactor(cr, es);
      then
        (pow_e,(e :: es));
  end matchcontinue;
end findPowFactor;

protected function simplifyBinaryAddCoeff2
"function: simplifyBinaryAddCoeff2
  This function checks for x+x+x+x and returns (x,4.0)"
  input Exp inExp;
  output Exp outExp;
  output Real outReal;
algorithm
  (outExp,outReal):=
  matchcontinue (inExp)
    local
      Exp exp,e1,e2,e;
      Real coeff,coeff_1;
      Type tp;
    case ((exp as DAE.CREF(componentRef = _))) then (exp,1.0);
    case (DAE.BINARY(exp1 = DAE.RCONST(real = coeff),operator = DAE.MUL(ty = _),exp2 = e1))
      then (e1,coeff);
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = DAE.RCONST(real = coeff)))
      then (e1,coeff);
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = DAE.ICONST(integer = coeff)))
      local Integer coeff;
      equation
        coeff_1 = intReal(coeff);
      then
        (e1,coeff_1);
    case (DAE.BINARY(exp1 = DAE.ICONST(integer = coeff),operator = DAE.MUL(ty = _),exp2 = e1))
      local Integer coeff;
      equation
        coeff_1 = intReal(coeff);
      then
        (e1,coeff_1);
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2))
      equation
        true = expEqual(e1, e2);
      then
        (e1,2.0);
    case (e) then (e,1.0);
  end matchcontinue;
end simplifyBinaryAddCoeff2;

protected function simplifyBinaryMulCoeff2
"function: simplifyBinaryMulCoeff2
  This function takes an expression XXXXX
  and return (X,5.0) to be used for X^5."
  input Exp inExp;
  output Exp outExp;
  output Real outReal;
algorithm
  (outExp,outReal):=
  matchcontinue (inExp)
    local
      Exp e,e1,e2;
      ComponentRef cr;
      Real coeff,coeff_1,coeff_2;
      Type tp;
    case ((e as DAE.CREF(componentRef = cr)))
      then (e,1.0);
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = _),exp2 = DAE.RCONST(real = coeff)))
      then (e1,coeff);
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = _),exp2 = DAE.UNARY(operator = DAE.UMINUS(ty = tp),exp = DAE.RCONST(real = coeff))))
      equation
        coeff_1 = 0.0 -. coeff;
      then
        (e1,coeff_1);
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = _),exp2 = DAE.ICONST(integer = coeff)))
      local Integer coeff;
      equation
        coeff_1 = intReal(coeff);
      then
        (e1,coeff_1);
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = _),exp2 = DAE.UNARY(operator = DAE.UMINUS(ty = tp),exp = DAE.ICONST(integer = coeff))))
      local Integer coeff;
      equation
        coeff_1 = intReal(coeff);
        coeff_2 = 0.0 -. coeff_1;
      then
        (e1,coeff_1);
		case (DAE.BINARY(exp1 = e1, operator = DAE.POW(ty = _), exp2 = DAE.ICONST(integer = coeff)))
			local Integer coeff;
			equation
				coeff_1 = intReal(coeff);
			then
				(e1, coeff_1);
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2))
      equation
        true = expEqual(e1, e2);
      then
        (e1,2.0);
    case (e) then (e,1.0);
  end matchcontinue;
end simplifyBinaryMulCoeff2;

protected function simplifyAsub
"function: simplifyAsub
  This function simplifies array subscripts on vector operations"
  input Exp inExp;
  input Exp inSub;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inSub)
    local
      Exp e_1,e,e1_1,e2_1,e1,e2,exp,cond,sub;
      Type t,t_1,t2;
      Integer indx,i_1,n;
      Operator op,op2;
      Boolean b;
      list<Exp> exps,expl_1;
      list<tuple<Exp, Boolean>> expl;
      list<Boolean> bls;
      ComponentRef cr;
      Real r;
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(ty = t),exp = e),sub)
      equation
        e_1 = simplifyAsub(e, sub);
        t2 = typeof(e_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.UMINUS_ARR(t2),DAE.UMINUS(t2));
        exp = simplify1(DAE.UNARY(op2,e_1));
      then
        exp;
    case (DAE.UNARY(operator = DAE.UPLUS_ARR(ty = t),exp = e),sub)
      equation
        e_1 = simplifyAsub(e, sub);
        t2 = typeof(e_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.UPLUS_ARR(t2),DAE.UPLUS(t2));
        exp=simplify1(DAE.UNARY(op2,e_1));
      then
        exp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = t),exp2 = e2),sub)
      local Boolean b; Type t2; Operator op2;
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.SUB_ARR(t2),DAE.SUB(t2));
        exp = simplify1(DAE.BINARY(e1_1,op2,e2_1));
      then
        exp;
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.MUL_SCALAR_ARRAY(ty = t),exp2 = e2),sub)
      equation
        e2_1 = simplifyAsub(e2, sub);
        e1_1 = simplify1(e1);
        t2 = typeof(e2_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.MUL_SCALAR_ARRAY(t2),DAE.MUL(t2));
        exp = simplify1(DAE.BINARY(e1_1,op,e2_1));
      then
        exp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARRAY_SCALAR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplify1(e2);
        t2 = typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.MUL_ARRAY_SCALAR(t2),DAE.MUL(t2));
        exp = simplify1(DAE.BINARY(e1_1,op,e2_1));
      then
        exp;
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.ADD_SCALAR_ARRAY(ty = t),exp2 = e2),sub)
      equation
        e2_1 = simplifyAsub(e2, sub);
        e1_1 = simplify1(e1);
        t2 = typeof(e2_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.ADD_SCALAR_ARRAY(t2),DAE.ADD(t2));
        exp = simplify1(DAE.BINARY(e1_1,op,e2_1));
      then
        exp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARRAY_SCALAR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplify1(e2);
        t2 = typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.ADD_ARRAY_SCALAR(t2),DAE.ADD(t2));
        exp = simplify1(DAE.BINARY(e1_1,op,e2_1));
      then
        exp;
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.SUB_SCALAR_ARRAY(ty = t),exp2 = e2),sub)
      equation
        e2_1 = simplifyAsub(e2, sub);
        e1_1 = simplify1(e1);
        t2 = typeof(e2_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.SUB_SCALAR_ARRAY(t2),DAE.SUB(t2));
        exp = simplify1(DAE.BINARY(e1_1,op,e2_1));
      then
        exp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARRAY_SCALAR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplify1(e2);
        t2 = typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.SUB_ARRAY_SCALAR(t2),DAE.SUB(t2));
        exp = simplify1(DAE.BINARY(e1_1,op,e2_1));
      then
        exp;

     /* For Matrix product M1 * M2 */
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.MUL_MATRIX_PRODUCT(ty = t),exp2 = e2),sub)
      equation
        e1 = simplify1(e1);
        e2 = simplify1(e2);        
        e = simplifyMatrixProduct(e1,e2);
        e = simplifyAsub(e, sub);
      then
        e;
    /* For scalar product v1 * v2, M * v1 and v1 * M */
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.MUL_MATRIX_PRODUCT(ty = t),exp2 = e2),sub)
      equation
        e1 = simplify1(e1);
        e2 = simplify1(e2);        
        e = simplifyScalarProduct(e1,e2);
        e = simplifyAsub(e, sub);
      then
        e;
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.DIV_SCALAR_ARRAY(ty = t),exp2 = e2),sub)
      equation
        e2_1 = simplifyAsub(e2, sub);
        e1_1 = simplify1(e1);
        t2 = typeof(e2_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.DIV_SCALAR_ARRAY(t2),DAE.DIV(t2));
        exp = simplify1(DAE.BINARY(e1_1,op,e2_1));
      then
        exp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARRAY_SCALAR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplify1(e2);
        t2 = typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.DIV_ARRAY_SCALAR(t2),DAE.DIV(t2));
        exp = simplify1(DAE.BINARY(e1_1,op,e2_1));
      then
        exp;
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.POW_SCALAR_ARRAY(ty = t),exp2 = e2),sub)
      equation
        e2_1 = simplifyAsub(e2, sub);
        e1_1 = simplify1(e1);
        t2 = typeof(e2_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.POW_SCALAR_ARRAY(t2),DAE.POW(t2));
        exp = simplify1(DAE.BINARY(e1_1,op,e2_1));
      then
        exp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW_ARRAY_SCALAR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplify1(e2);
        t2 = typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.POW_ARRAY_SCALAR(t2),DAE.POW(t2));
        exp = simplify1(DAE.BINARY(e1_1,op,e2_1));
      then
        exp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.ADD_ARR(t2),DAE.ADD(t2));
        exp = simplify1(DAE.BINARY(e1_1,op2,e2_1));
      then
        exp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.MUL_ARR(t2),DAE.MUL(t2));
        exp = simplify1(DAE.BINARY(e1_1,op2,e2_1));
      then
        exp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.DIV_ARR(t2),DAE.DIV(t2));
        exp = simplify1(DAE.BINARY(e1_1,op2,e2_1));
      then
        exp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW_ARR2(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.POW_ARR2(t2),DAE.POW(t2));
        exp = simplify1(DAE.BINARY(e1_1,op2,e2_1));
      then
        exp;

    case (DAE.ARRAY(ty = t,scalar = b,array = exps),sub)
      equation
        indx = expInt(sub);
        i_1 = indx - 1;
        exp = listNth(exps, i_1);
      then
        exp;
    case (DAE.MATRIX(ty = t,integer = n,scalar = exps),sub)
      local list<list<tuple<Exp, Boolean>>> exps;
      equation
        indx = expInt(sub);
        i_1 = indx - 1;
        (expl) = listNth(exps, i_1);
        (expl_1,bls) = Util.splitTuple2List(expl);
        t_1 = unliftArray(t);
        b = Util.boolAndList(bls);
      then
        DAE.ARRAY(t_1,b,expl_1);
    case ((e as DAE.CREF(componentRef = cr,ty = t)),sub)
      equation
        e_1 = simplify1(DAE.ASUB(e,{sub}));
      then
        e_1;
    case(e as DAE.IFEXP(cond,e1,e2),sub) equation
       e1_1 = simplifyAsub(e1, sub);
       e2_1 = simplifyAsub(e2, sub);
    then DAE.IFEXP(cond,e1_1,e2_1);
    case(e,sub)
      equation
       e1 = simplify1(e);
    then DAE.ASUB(e1, {sub});
  end matchcontinue;
end simplifyAsub;

protected function simplifyAsubOperator
  input Exp inExp1;
  input Operator inOperator2;
  input Operator inOperator3;
  output Operator outOperator;
algorithm
  outOperator:=
  matchcontinue (inExp1,inOperator2,inOperator3)
    local Operator sop,aop;
    case (DAE.ARRAY(ty = _),sop,aop) then aop;
    case (DAE.MATRIX(ty = _),sop,aop) then aop;
    case (DAE.RANGE(ty = _),sop,aop) then aop;
    case (_,sop,aop) then sop;
  end matchcontinue;
end simplifyAsubOperator;

protected function divide
"function: divide
  author: PA
  divides two expressions."
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inExp2)
    local Exp e1,e2;
    case (e1,e2) then DAE.BINARY(e1,DAE.DIV(DAE.ET_REAL()),e2);
  end matchcontinue;
end divide;

protected function removeFactor
"function: removeFactor
  Remove the factor from the expression (factorize it out)"
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inExp2)
    local
      Exp e1,factor1,expr1,one,factor,expr,exp;
      list<Exp> rest,e2s,e1s,factors_1;
      Type tp;
      Ident fs,es,factorsstr;
      list<Ident> elst;
    case (factor,expr) /* factor expr updated expr factor = expr, return one */
      equation
        (e1 :: rest) = factors(factor);
        e2s = factors(expr);
        factor1 = makeProductLst((e1 :: rest));
        expr1 = makeProductLst(e2s);
        {} = Util.listSetDifferenceOnTrue(e2s, (e1 :: rest), expEqual);
        tp = typeof(e1);
        one = makeConstOne(tp);
      then
        one;
    case (factor,expr)
      equation
        e1s = factors(factor);
        e2s = factors(expr);
        factors_1 = Util.listSetDifferenceOnTrue(e2s, e1s, expEqual);
        exp = makeProductLst(factors_1);
      then
        exp;
    case (factor,expr)
      equation
				true = RTOpts.debugFlag("failtrace");
        fs = printExpStr(factor);
        es = printExpStr(expr);
        Debug.fprint("failtrace","-Exp.removeFactor failed, factor:");
        Debug.fprint("failtrace",fs);
        Debug.fprint("failtrace"," expr:");
        Debug.fprint("failtrace",es);
        Debug.fprint("failtrace","\n");
        e2s = factors(expr);
        elst = Util.listMap(e2s, printExpStr);
        factorsstr = Util.stringDelimitList(elst, ", ");
        Debug.fprint("failtrace"," factors:");
        Debug.fprint("failtrace",factorsstr);
        Debug.fprint("failtrace","\n");
      then
        fail();
  end matchcontinue;
end removeFactor;

protected function gcd
"function: gcd
  Return the greatest common divisor expression from two expressions.
  If no common divisor besides a numerical expression can be found,
  the function fails."
  input Exp e1;
  input Exp e2;
  output Exp product;
  list<Exp> e1s,e2s,factor;
algorithm
  e1s := factors(e1);
  e2s := factors(e2);
  ((factor as (_ :: _))) := Util.listIntersectionOnTrue(e1s, e2s, expEqual);
  product := makeProductLst(factor);
end gcd;

protected function noFactors
"function noFactors
  Helper function to factors.
  If a factor list is empty, the expression has no subfactors.
  But the complete expression is then a factor for larger
  expressions, returned by this function."
  input list<Exp> inExpLst;
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst,inExp)
    local
      Exp e;
      list<Exp> lst;
    case ({},e) then {e};
    case (lst,_) then lst;
  end matchcontinue;
end noFactors;

public function negate
"function: negate
  author: PA
  Negates an expression."
  input Exp e;
  output Exp outExp;
protected
  Type t;
algorithm
  outExp := matchcontinue(e)
  local 
    Type t;
    Operator op;
    Boolean b;
    /* to avoid unnessecary --e */
    case(DAE.UNARY(DAE.UMINUS(t),e)) then e;
    case(DAE.UNARY(DAE.UMINUS_ARR(t),e)) then e;

    /* -0 = 0 */
    case(e) equation
      true = isZero(e);
    then e;

    case(e) equation
      t = typeof(e);
      b = DAEUtil.expTypeArray(t);
      op = Util.if_(b,DAE.UMINUS_ARR(t),DAE.UMINUS(t));
    then DAE.UNARY(op,e);
  end matchcontinue;
end negate;

public function allTerms
"simliar to terms, but also perform expansion of
 multiplications to reveal more terms, like for instance:
 allTerms((a+b)*(b+c)) => {a*b,a*c,b*b,b*c}"
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExp)
    local
      list<Exp> f1,f2,res,f2_1;
      Exp e1,e2,e;
      Type tp;
      ComponentRef cr;

   case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = _),exp2 = e2))
      equation
        f1 = allTerms(e1);
        f2 = allTerms(e2);
        res = listAppend(f1, f2);
      then
        res;
   case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = _),exp2 = e2))
     equation
       f1 = allTerms(e1);
       f2 = allTerms(e2);
       f2_1 = Util.listMap(f2, negate);
       res = listAppend(f1, f2_1);
     then
       res;

   case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = _),exp2 = e2))
      equation
        f1 = allTerms(e1);
        f2 = allTerms(e2);
        res = listAppend(f1, f2);
      then
        res;
   case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = _),exp2 = e2))
     equation
       f1 = allTerms(e1);
       f2 = allTerms(e2);
       f2_1 = Util.listMap(f2, negate);
       res = listAppend(f1, f2_1);
     then
       res;

       /* terms( a*(b+c)) => {a*b, c*b} */
   case (e as DAE.BINARY(e1,DAE.MUL(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e2);
     f1 = Util.listMap1(f1,makeProduct,e1);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.MUL_ARR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e2);
     f1 = Util.listMap1(f1,makeProduct,e1);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.MUL_SCALAR_ARRAY(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e2);
     f1 = Util.listMap1(f1,makeProduct,e1);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;    
   case (e as DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e2);
     f1 = Util.listMap1(f1,makeProduct,e1);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1; 
     /* terms( (b+c)*a) => {b*a, c*a} */
   case (e as DAE.BINARY(e1,DAE.MUL(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeProduct,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.MUL_ARR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeProduct,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.MUL_SCALAR_ARRAY(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeProduct,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeProduct,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;          
   /* terms( (b+c)/a) => {b/a, c/a} */
   case (e as DAE.BINARY(e1,DAE.DIV(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeFraction,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.DIV_ARR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeFraction,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;  
   case (e as DAE.BINARY(e1,DAE.DIV_ARRAY_SCALAR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeFraction,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1; 
   case (e as DAE.BINARY(e1,DAE.DIV_SCALAR_ARRAY(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeFraction,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;              
   case ((e as DAE.BINARY(operator = DAE.MUL(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.MUL_ARR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.MUL_SCALAR_ARRAY(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.MUL_ARRAY_SCALAR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.DIV(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.DIV_ARR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.DIV_ARRAY_SCALAR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.DIV_SCALAR_ARRAY(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.POW(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.POW_ARR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.POW_ARR2(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.POW_ARRAY_SCALAR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.POW_SCALAR_ARRAY(ty = _)))) then {e};
   case ((e as DAE.CREF(componentRef = cr))) then {e};
   case ((e as DAE.ICONST(integer = _))) then {e};
   case ((e as DAE.RCONST(real = _))) then {e};
   case ((e as DAE.SCONST(string = _))) then {e};
   case ((e as DAE.UNARY(operator = _))) then {e};
   case ((e as DAE.IFEXP(expCond = _))) then {e};
   case ((e as DAE.CALL(path = _))) then {e};
   case ((e as DAE.PARTEVALFUNCTION(path = _))) then {e};
   case ((e as DAE.ARRAY(ty = _))) then {e};
   case ((e as DAE.MATRIX(ty = _))) then {e};
   case ((e as DAE.RANGE(ty = _))) then {e};
   case ((e as DAE.CAST(ty = _))) then {e};
   case ((e as DAE.ASUB(exp = _))) then {e};
   case ((e as DAE.SIZE(exp = _))) then {e};
   case ((e as DAE.REDUCTION(path = _))) then {e};
    case (_) then {};
  end matchcontinue;
end allTerms;

public function expand "expands products
For example
a *(b+c) => a*b + a*c
" 
  input Exp e;
  output Exp outE;
algorithm
  outE := matchcontinue(e)
  local DAE.ExpType tp;
    DAE.Operator op;
    Exp e1,e2,e21,e22;
    case(DAE.BINARY(e1,DAE.MUL(tp),e2)) equation
      DAE.BINARY(e21,op,e22) = expand(e2);
      true = isAddOrSub(op);      
    then DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e21),op,DAE.BINARY(e1,DAE.MUL(tp),e22));
    case(e) then e;     
  end matchcontinue;
end expand;

public function isAddOrSub "returns true if operator is ADD or SUB"
  input Operator op;
  output Boolean res;
algorithm
  res := isAdd(op) or isSub(op);    
end isAddOrSub;

public function isAdd "returns true if operator is ADD"
  input Operator op;
  output Boolean res;
algorithm
  res := matchcontinue(op)
    case(DAE.ADD(_)) then true;
    case(_) then false;
  end matchcontinue;
end isAdd;

public function isSub "returns true if operator is SUB"
  input Operator op;
  output Boolean res;
algorithm
  res := matchcontinue(op)
    case(DAE.SUB(_)) then true;
    case(_) then false;
  end matchcontinue;
end isSub;


public function terms "
function: terms
  author: PA
  Returns the terms of the expression if any as a list of expressions"
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExp)
    local
      list<Exp> f1,f2,res,f2_1;
      Exp e1,e2,e;
      Type tp;
      ComponentRef cr;
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = _),exp2 = e2))
      equation
        f1 = terms(e1);
        f2 = terms(e2);
        res = listAppend(f1, f2);
      then
        res;
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = _),exp2 = e2))
      equation
        f1 = terms(e1);
        f2 = terms(e2);
        f2_1 = Util.listMap(f2, negate);
        res = listAppend(f1, f2_1);
      then
        res;
    case ((e as DAE.BINARY(operator = DAE.MUL(ty = _)))) then {e};
    case ((e as DAE.BINARY(operator = DAE.DIV(ty = _)))) then {e};
    case ((e as DAE.BINARY(operator = DAE.POW(ty = _)))) then {e};
    case ((e as DAE.CREF(componentRef = cr))) then {e};
    case ((e as DAE.ICONST(integer = _))) then {e};
    case ((e as DAE.RCONST(real = _))) then {e};
    case ((e as DAE.SCONST(string = _))) then {e};
    case ((e as DAE.UNARY(operator = _))) then {e};
    case ((e as DAE.IFEXP(expCond = _))) then {e};
    case ((e as DAE.CALL(path = _))) then {e};
    case ((e as DAE.PARTEVALFUNCTION(path = _))) then {e};
    case ((e as DAE.ARRAY(ty = _))) then {e};
    case ((e as DAE.MATRIX(ty = _))) then {e};
    case ((e as DAE.RANGE(ty = _))) then {e};
    case ((e as DAE.CAST(ty = _))) then {e};
    case ((e as DAE.ASUB(exp = _))) then {e};
    case ((e as DAE.SIZE(exp = _))) then {e};
    case ((e as DAE.REDUCTION(path = _))) then {e};
    case (_) then {};
  end matchcontinue;
end terms;

public function quotient
"function: quotient
  author: PA
  Returns the quotient of an expression.
  For instance e = p/q returns (p,q) for numerator p and denominator q."
  input Exp inExp;
  output Exp num;
  output Exp denom;
algorithm
  (num,denom):=
  matchcontinue (inExp)
    local
      Exp e1,e2,p,q;
      Type tp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = _),exp2 = e2)) then (e1,e2);  /* (numerator,denominator) */
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = e2))
      equation
        (p,q) = quotient(e1);
        tp = typeof(p);
      then
        (DAE.BINARY(e2,DAE.MUL(tp),p),q);
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = e2))
      equation
        (p,q) = quotient(e2);
        tp = typeof(p);
      then
        (DAE.BINARY(e1,DAE.MUL(tp),p),q);
  end matchcontinue;
end quotient;

public function factors
"function: factors
  Returns the factors of the expression if any as a list of expressions"
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExp)
    local
      list<Exp> f1,f2,f1_1,f2_1,res,f2_2;
      Exp e1,e2,e;
      ComponentRef cr;
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = e2))
      equation
        f1 = factors(e1) "Both subexpression has factors" ;
        f2 = factors(e2);
        f1_1 = noFactors(f1, e1);
        f2_1 = noFactors(f2, e2);
        res = listAppend(f1_1, f2_1);
      then
        res;
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = DAE.ET_REAL()),exp2 = e2))
      equation
        f1 = factors(e1);
        f2 = factors(e2);
        f1_1 = noFactors(f1, e1);
        f2_1 = noFactors(f2, e2);
        f2_2 = inverseFactors(f2_1);
        res = listAppend(f1_1, f2_2);
      then
        res;
    case ((e as DAE.CREF(componentRef = cr))) then {e};
    case ((e as DAE.BINARY(exp1 = _))) then {e};
    case ((e as DAE.ICONST(integer = _))) then {e};
    case ((e as DAE.RCONST(real = _))) then {e};
    case ((e as DAE.SCONST(string = _))) then {e};
    case ((e as DAE.UNARY(operator = _))) then {e};
    case ((e as DAE.IFEXP(expCond = _))) then {e};
    case ((e as DAE.CALL(path = _))) then {e};
    case ((e as DAE.PARTEVALFUNCTION(path = _))) then {e};
    case ((e as DAE.ARRAY(ty = _))) then {e};
    case ((e as DAE.MATRIX(ty = _))) then {e};
    case ((e as DAE.RANGE(ty = _))) then {e};
    case ((e as DAE.CAST(ty = _))) then {e};
    case ((e as DAE.ASUB(exp = _))) then {e};
    case ((e as DAE.SIZE(exp = _))) then {e};
    case ((e as DAE.REDUCTION(path = _))) then {e};
    case (_) then {};
  end matchcontinue;
end factors;

protected function inverseFactors
"function inverseFactors
  Takes a list of expressions and returns
  each expression in the list inversed.
  For example: inverseFactors {a, 3+b} => {1/a, 1/3+b}"
  input list<Exp> inExpLst;
  output list<Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst)
    local
      list<Exp> es_1,es;
      Type tp2,tp;
      Exp e1,e2,e;
    case ({}) then {};
    case ((DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = tp),exp2 = e2) :: es))
      equation
        es_1 = inverseFactors(es);
        tp2 = typeof(e2);
      then
        (DAE.BINARY(e1,DAE.POW(tp),DAE.UNARY(DAE.UMINUS(tp2),e2)) :: es_1);
    case ((e :: es))
      equation
        DAE.ET_REAL() = typeof(e);
        es_1 = inverseFactors(es);
      then
        (DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),e) :: es_1);
    case ((e :: es))
      equation
        DAE.ET_INT() = typeof(e);
        es_1 = inverseFactors(es);
      then
        (DAE.BINARY(DAE.ICONST(1),DAE.DIV(DAE.ET_INT()),e) :: es_1);
  end matchcontinue;
end inverseFactors;

public function makeProduct
"Makes a product of two expressions"
  input Exp e1;
  input Exp e2;
  output Exp product;
algorithm
  product := makeProductLst({e1,e2});
end makeProduct;

public function makeProductLst
"function: makeProductLst
  Takes a list of expressions an makes a product
  expression multiplying all elements in the list."
  input list<Exp> inExpLst;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExpLst)
    local
      Exp e1,res,e,e2,p1;
      list<Exp> es,rest,lst;
      Type tp;
      list<Ident> explst;
      Ident str;
      Boolean b_isZero,b1,b2;
    case ({}) then DAE.RCONST(1.0);
    case ({e1})
      equation
        b_isZero = isZero(e1);
        res = Util.if_(b_isZero,makeConstZero(typeof(e1)),e1);
      then res;
    case ((e :: es)) /* to prevent infinite recursion, disregard constant 1. */
      equation
        true = isConstOne(e);
        res = makeProductLst(es);
        b_isZero = isZero(res);
        res = Util.if_(b_isZero,makeConstZero(typeof(e)),res);
      then
        res;
     case ((e :: es)) /* to prevent infinite recursion, disregard constant 0. */
      equation
        true = isZero(e);
        res = makeConstZero(typeof(e));
      then
        res;
    case ({DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e),e2})
      equation
        true = isConstOne(e1);
      then
        DAE.BINARY(e2,DAE.DIV(tp),e);
    case ({e2,DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e)})
      equation
        true = isConstOne(e1);
      then
        DAE.BINARY(e2,DAE.DIV(tp),e);
    case ((DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e) :: es))
      equation
        true = isConstOne(e1);
        p1 = makeProductLst(es);
        res = DAE.BINARY(p1,DAE.DIV(tp),e);
        b_isZero = isZero(p1);
        res = Util.if_(b_isZero,makeConstZero(typeof(e)),res);
      then
			  res;
    case ({e1,e2})
      equation
        true = isConstOne(e2);
      then
        e1;
    case ({e1,e2})
      equation
        b1 = isZero(e1);
        b2 = isZero(e2);
        b_isZero = boolOr(b1,b2);
        tp = typeof(e1) "Take type info from e1, ok since type checking already performed." ;
        tp = checkIfOther(tp);
        res = DAE.BINARY(e1,DAE.MUL(tp),e2);
        res = Util.if_(b_isZero,makeConstZero(tp),res);
      then
        res;
    case ((e1 :: rest))
      equation
        e2 = makeProductLst(rest);
        tp = typeof(e1);
        tp = checkIfOther(tp);
        res = DAE.BINARY(e1,DAE.MUL(tp),e2);
        b1 = isZero(e1);
        b2 = isZero(e2);
        b_isZero = boolOr(b1,b2);
        res = Util.if_(b_isZero,makeConstZero(typeof(e1)),res);
      then
				res;
    case (lst)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace","-Exp.makeProductLst failed, exp lst:");
        explst = Util.listMap(lst, printExpStr);
        str = Util.stringDelimitList(explst, ", ");
        Debug.fprint("failtrace",str);
        Debug.fprint("failtrace","\n");
      then
        fail();
  end matchcontinue;
end makeProductLst;

public function makeFraction
"function: makeFraction
  author: Frenkel TUD
  Makes a fraction of two expressions"
  input Exp e1;
  input Exp e2;
  output Exp fraction;
algorithm
  fraction := matchcontinue(e1,e2)
    local
      Type etp;
      Boolean scalar;
      Operator op;
    case(e1,e2) equation
      etp = typeof(e1);
      scalar = DAEUtil.expTypeArray(etp);
      op = Util.if_(scalar,DAE.DIV_ARRAY_SCALAR(etp),DAE.DIV(etp));
    then DAE.BINARY(e1,op,e2);
  end matchcontinue;
end makeFraction;

protected function checkIfOther
"Checks if a type is OTHER and in that case returns REAL instead.
 This is used to make proper transformations in case OTHER is
 retrieved from subexpression where it should instead be REAL or INT"
input Type inTp;
output Type outTp;
algorithm
  outTp := matchcontinue(inTp)
    case (DAE.ET_OTHER()) then DAE.ET_REAL();
    case (inTp) then inTp;
  end matchcontinue;
end checkIfOther;

// stefan
public function unboxExpType
"function: unboxExpType
	takes a type, and if it is boxed, unbox it
	otherwise return the given type"
	input Type inType;
	output Type outType;
algorithm
  outType := matchcontinue(inType)
    local
      Type ty;
    case(DAE.ET_BOXED(ty)) then ty;
    case(ty) then ty;
  end matchcontinue;
end unboxExpType;

public function makeDiff
"Takes two expressions and create
 the difference between them"
  input Exp e1;
  input Exp e2;
  output Exp res;
algorithm
  res := matchcontinue(e1,e2)
    local
      Type etp;
      Boolean scalar;
      Operator op;

    case(e1,e2) equation
      true = isZero(e2);
    then e1;

    case(e1,e2) equation
      true = isZero(e1);
    then negate(e2);

    case(e1,e2) equation
      etp = typeof(e1);
      scalar = DAEUtil.expTypeArray(etp);
      op = Util.if_(scalar,DAE.SUB_ARR(etp),DAE.SUB(etp));
    then DAE.BINARY(e1,op,e2);
  end matchcontinue;
end makeDiff;

public function makeSum
"function: makeSum
  Takes a list of expressions an makes a sum
  expression adding all elements in the list."
  input list<Exp> inExpLst;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExpLst)
    local
      Exp e1,e2,res;
      Boolean b1;
      Type tp;
      list<Exp> rest,lst;
      list<Ident> explst;
      Ident str;
      Operator op;
      Boolean b;
    case ({}) then DAE.RCONST(0.0);
    case ({e1}) then e1;
		case ({e1, e2})
			equation
				true = isZero(e1);
			then e2;
		case ({e1, e2})
			equation
				true = isZero(e2);
			then e1;
		case ({e1, e2})
			equation
        tp = typeof(e1) "Take type info from e1, ok since type checking already performed." ;
        b = DAEUtil.expTypeArray(tp);
        op = Util.if_(b,DAE.ADD_ARR(tp),DAE.ADD(tp));
			then DAE.BINARY(e1, op, e2);			  
				//res = DAE.BINARY(e1, DAE.ADD(tp), e2);
			//then res;
    /*case ({e1,e2})
      equation
        b1 = isZero(e1);
        tp = typeof(e1) "Take type info from e1, ok since type checking already performed." ;
        res = DAE.BINARY(e1,DAE.ADD(tp),e2);
				res = Util.if_(b1,e2,res);
      then
        res;*/
    case ((e1 :: rest))
      equation
        b1 = isZero(e1);
        e2 = makeSum(rest);
        tp = typeof(e2);
        b = DAEUtil.expTypeArray(tp);
        op = Util.if_(b,DAE.ADD_ARR(tp),DAE.ADD(tp));        
        res = DAE.BINARY(e1,op,e2);
        res = Util.if_(b1,e2,res);
      then
        res;
    case (lst)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace","-Exp.makeSum failed, exp lst:");
        explst = Util.listMap(lst, printExpStr);
        str = Util.stringDelimitList(explst, ", ");
        Debug.fprint("failtrace",str);
        Debug.fprint("failtrace","\n");
      then
        fail();
  end matchcontinue;
end makeSum;

public function abs
"function: abs
  author: PA
  Makes the expression absolute. i.e. non-negative."
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
    local
      Integer i2,i;
      Real r2,r;
      Exp e_1,e,e1_1,e2_1,e1,e2;
      Type tp;
      Operator op;
    case (DAE.ICONST(integer = i))
      equation
        i2 = intAbs(i);
      then
        DAE.ICONST(i2);
    case (DAE.RCONST(real = r))
      equation
        r2 = realAbs(r);
      then
        DAE.RCONST(r2);
    case (DAE.UNARY(operator = DAE.UMINUS(ty = tp),exp = e))
      equation
        e_1 = abs(e);
      then
        e_1;
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        e1_1 = abs(e1);
        e2_1 = abs(e2);
      then
        DAE.BINARY(e1_1,op,e2_1);
    case (e) then e;
  end matchcontinue;
end abs;

public function arrayFill
  input list<DAE.Dimension> dims;
  input DAE.Exp inExp;
  output DAE.Exp oExp;
algorithm 
  oExp := matchcontinue(dims,inExp)
    local
      list<DAE.Exp> expl;
    case({},inExp) then inExp;
    case(dims,inExp)
      equation
        oExp = arrayFill2(dims,inExp);
      then
        oExp;
  end matchcontinue;
end arrayFill;

protected function arrayFill2
  input list<DAE.Dimension> dims;
  input DAE.Exp inExp;
  output DAE.Exp oExp;
algorithm 
  oExp := matchcontinue(dims,inExp)
  local
    Integer i;
    DAE.Dimension d;
    Type ty;
    list<Exp> expl;
  case({d},inExp)
    equation
      ty = typeof(inExp);
      i = dimensionSize(d);
      expl = listCreateExp(i,inExp);
    then
      DAE.ARRAY(DAE.ET_ARRAY(ty,{DAE.DIM_INTEGER(i)}),true,expl);
  case(_::dims,inExp)
    equation
      print(" arrayFill2 not implemented for matrixes, only single arrays \n");
    then
      fail();
  end matchcontinue;
end arrayFill2;

protected function listCreateExp "
Author BZ
Creates a lsit of exps containing the input exp.
"
input Integer n;
input DAE.Exp e;
output list<DAE.Exp> expl;
algorithm expl := matchcontinue(n,e)
  case(n,e)
    equation
    true = intEq(n,0);
    then
      {};
  case(n,e)
    equation
      true = n>0;
      expl = listCreateExp(n-1,e);
      then
        e::expl;
  end matchcontinue;
end listCreateExp;

public function arrayDimension "
Author BZ
Get dimension of array.
"
	input Type tp;
  output list<DAE.Dimension> dims;
algorithm
  dims := matchcontinue(tp)
    case(DAE.ET_ARRAY(_,dims)) then dims;
    case(_) then {};
  end matchcontinue;
end arrayDimension;

public function arrayTypeDimensions
"Return the array dimensions of a type."
	input Type tp;
  output list<DAE.Dimension> dims;
algorithm
  dims := matchcontinue(tp)
    case(DAE.ET_ARRAY(_,dims)) then dims;
  end matchcontinue;
end arrayTypeDimensions;

public function equalTypes ""
input Type t1,t2;
output Boolean b;
algorithm b := matchcontinue(t1,t2)
  local
    list<DAE.ExpVar> vars1,vars2;
    Type ty1,ty2;
    list<DAE.Dimension> ad1,ad2;
    list<Integer> li1,li2;

  case(DAE.ET_INT(),DAE.ET_INT()) then true;
  case(DAE.ET_REAL(),DAE.ET_REAL()) then true;
  case(DAE.ET_STRING(),DAE.ET_STRING()) then true;
  case(DAE.ET_BOOL(),DAE.ET_BOOL()) then true;

  case(DAE.ET_COMPLEX(_,vars1,_), DAE.ET_COMPLEX(_,vars2,_))
       then equalTypesComplexVars(vars1,vars2);
  case(DAE.ET_ARRAY(ty1,ad1),DAE.ET_ARRAY(ty2,ad2))
    equation
      li1 = Util.listMap(ad1, dimensionSize);
      li2 = Util.listMap(ad2, dimensionSize);
      true = Util.isListEqualWithCompareFunc(li1,li2,intEq);
      true = equalTypes(ty1,ty2);
    then
      true;
  case(t1,t2) then false;
  end matchcontinue;
end equalTypes;

protected function equalTypesComplexVars ""
input list<DAE.ExpVar> vars1,vars2;
output Boolean b;
algorithm
  b := matchcontinue(vars1,vars2)
  local
    DAE.ExpType t1,t2;
    String s1,s2;
    case({},{}) then true;
    case(DAE.COMPLEX_VAR(s1,t1)::vars1,DAE.COMPLEX_VAR(s2,t2)::vars2)
      equation
        //print(" verify subvars: " +& s1 +& " and " +& s2 +& " to go: " +& intString(listLength(vars1)) +& " , " +& intString(listLength(vars2))  +& "\n");
        true = stringEqual(s1,s2);
        //print(" types: " +& typeString(t1) +& " and " +& typeString(t2) +& "\n");
        true = equalTypes(t1,t2);
        //print(s1 +& " and " +& s2 +& " EQUAL \n\n");
        then
          equalTypesComplexVars(vars1,vars2);
    case(_,_) then false;
  end matchcontinue;
end equalTypesComplexVars;

public function typeBuiltin
"function: typeBuiltin
  Returns true if type is one of the builtin types."
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inType)
    case (DAE.ET_INT()) then true;
    case (DAE.ET_REAL()) then true;
    case (DAE.ET_STRING()) then true;
    case (DAE.ET_BOOL()) then true;
    case (_) then false;
  end matchcontinue;
end typeBuiltin;

public function arrayEltType
"function: arrayEltType
   Returns the element type of an array expression."
  input Type inType;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType)
    local Type t;
    case (DAE.ET_ARRAY(ty = t)) then arrayEltType(t);
    case (t) then t;
  end matchcontinue;
end arrayEltType;

public function unliftArray
"function: unliftArray
  Converts an array type into its element type
  See also Types.unliftArray.
  ."
  input Type inType;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType)
    local
      Type tp,t;
      DAE.Dimension d;
      list<DAE.Dimension> ds;
    case (DAE.ET_ARRAY(ty = tp,arrayDimensions = {_}))
      then tp;
    case (DAE.ET_ARRAY(ty = tp,arrayDimensions = (d :: ds)))
      then DAE.ET_ARRAY(tp,ds);
    case (t) then t;
  end matchcontinue;
end unliftArray;

public function unliftExp
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      Type ty;
    case DAE.CREF(componentRef = cr, ty = ty)
      local 
        DAE.ComponentRef cr;
      equation
        ty = unliftArray(ty);
      then
        DAE.CREF(cr, ty);
    case DAE.ARRAY(ty = ty, scalar = s, array = a)
      local
        Boolean s;
        list<Exp> a;
      equation
        ty = unliftArray(ty);
      then
        DAE.ARRAY(ty, s, a);
    case DAE.MATRIX(ty = ty, integer = i, scalar = s)
      local
        Integer i;
        list<list<tuple<Exp, Boolean>>> s;
      equation
        ty = unliftArray(ty);
      then
        DAE.MATRIX(ty, i, s);
    case (_) then inExp;
  end matchcontinue;
end unliftExp;

public function isWholeDim ""
  input DAE.Subscript s;
  output Boolean b;
algorithm
  b := matchcontinue(s)
    case(DAE.WHOLEDIM) then true;
    case(_) then false;
  end matchcontinue;
end isWholeDim;

public function isInt ""
  input Type it;
  output Boolean re;
algorithm
  re := matchcontinue(it)
    local
      Type t1,t2;
    case(DAE.ET_ARRAY(ty=t2))
      then
        isReal(t2);
    case(DAE.ET_INT) then true;
    case(_) then false;
  end matchcontinue;
end isInt;

public function isReal ""
  input Type it;
  output Boolean re;
algorithm
  re := matchcontinue(it)
    local
      Type t1,t2;
    case(DAE.ET_ARRAY(ty=t2))
      then
        isReal(t2);
    case(DAE.ET_REAL) then true;
    case(_) then false;
  end matchcontinue;
end isReal;

public function isExpReal ""
  input Exp e;
  output Boolean re;
algorithm
  re := matchcontinue(e)
    local Type t;
    case(e)
      equation
        t = typeof(e);
        then
          isReal(t);
  end matchcontinue;
end isExpReal;

public function typeof "
function typeof
  Retrieves the Type of the Expression"
  input Exp inExp;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inExp)
    local
      Type tp;
      Operator op;
      Exp e1,e2,e3,e;
      list<Exp> explist;
      list<Type> tylist;
      Integer index;
      Absyn.Path name;
      
    case (DAE.ICONST(integer = _)) then DAE.ET_INT();
    case (DAE.RCONST(real = _)) then DAE.ET_REAL();
    case (DAE.SCONST(string = _)) then DAE.ET_STRING();
    case (DAE.BCONST(bool = _)) then DAE.ET_BOOL();
    case (DAE.ENUM_LITERAL(name, index)) then DAE.ET_ENUMERATION(SOME(index), name, {}, {});
    case (DAE.CREF(ty = tp)) then tp;
    case (DAE.BINARY(operator = op)) then typeofOp(op);
    case (DAE.UNARY(operator = op)) then typeofOp(op);
    case (DAE.LBINARY(operator = op)) then typeofOp(op);
    case (DAE.LUNARY(operator = op)) then typeofOp(op);
    case (DAE.RELATION(operator = op)) then typeofOp(op);
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3)) then typeof(e2);
    case (DAE.CALL(path = _,ty=tp)) then tp;
    case (DAE.PARTEVALFUNCTION(path = _,ty=tp)) then tp;
    case (DAE.ARRAY(ty = tp)) then tp;
    case (DAE.MATRIX(ty = tp)) then tp;
    case (DAE.RANGE(ty = tp)) then tp;
    case (DAE.CAST(ty = tp)) then tp;
    case (DAE.ASUB(exp = e,sub=explist)) equation
      tp = unliftArrayTypeWithSubs(Util.listMap(explist,makeIndexSubscript) ,typeof(e));
    then tp;
    case (DAE.CODE(ty = tp)) then tp;
    case (DAE.REDUCTION(expr = e)) then typeof(e);
    case (DAE.END()) then DAE.ET_OTHER();  /* Can be any type. */
    case (DAE.SIZE(_,NONE)) then DAE.ET_INT();
    case (DAE.SIZE(_,SOME(_))) then DAE.ET_ARRAY(DAE.ET_INT(),{DAE.DIM_UNKNOWN});

    //MetaModelica extension
    case (DAE.LIST(ty = tp)) then DAE.ET_LIST(tp); // was tp, but the type of a LIST is a LIST
    case (DAE.CONS(ty = tp)) then DAE.ET_LIST(tp); // CONS creates lists
    case (DAE.META_TUPLE(explist))
      equation
        tylist = Util.listMap(explist, typeof);
      then DAE.ET_METATUPLE(tylist);
    case (DAE.META_OPTION(SOME(e)))
      equation
        tp = typeof(e);
      then DAE.ET_METAOPTION(tp);
    case (DAE.META_OPTION(NONE)) then DAE.ET_METAOPTION(DAE.ET_OTHER());
    case (DAE.METARECORDCALL(_,_,_,_)) then DAE.ET_UNIONTYPE();
    case e
      equation
        Debug.fprintln("failtrace", "- Exp.typeof failed for " +& printExpStr(e));
      then fail();
  end matchcontinue;
end typeof;

public function liftArrayRight "
This function adds an array dimension to a type on the right side, i.e.
liftArrayRigth(Real[2,3],SOME(4)) => Real[2,3,4].

This function has the same functionality as Types.liftArrayType but for DAE.ExpType.'
"
  input Type inType;
  input DAE.Dimension inDimension;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType,inDimension)
    local
      Type ty_1,ty;
      list<DAE.Dimension> dims;
      DAE.Dimension dim;
      Integer i;
    case (DAE.ET_ARRAY(ty,dims),dim)
      equation
        ty_1 = liftArrayRight(ty, dim);
      then
        DAE.ET_ARRAY(ty_1,dims);
    case (ty,dim)
      then
        DAE.ET_ARRAY(ty,{dim});
  end matchcontinue;
end liftArrayRight;

public function liftArrayLeft "
author: PA
This function adds an array dimension to a type on the left side, i.e.
liftArrayRigth(Real[2,3],SOME(4)) => Real[4,2,3]
"
  input Type inType;
  input DAE.Dimension inDimension;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType,inDimension)
    local
      Type ty_1,ty;
      list<DAE.Dimension> dims;
      DAE.Dimension dim;
      
    case (DAE.ET_ARRAY(ty,dims),dim) then DAE.ET_ARRAY(ty,dim::dims);
      
    case (ty,dim)then DAE.ET_ARRAY(ty,{dim});
      
  end matchcontinue;
end liftArrayLeft;

protected function typeofOp
"function: typeofOp
  Helper function to typeof"
  input Operator inOperator;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inOperator)
    local Type t;
    case (DAE.ADD(ty = t)) then t;
    case (DAE.SUB(ty = t)) then t;
    case (DAE.MUL(ty = t)) then t;
    case (DAE.DIV(ty = t)) then t;
    case (DAE.POW(ty = t)) then t;
    case (DAE.UMINUS(ty = t)) then t;
    case (DAE.UPLUS(ty = t)) then t;
    case (DAE.UMINUS_ARR(ty = t)) then t;
    case (DAE.UPLUS_ARR(ty = t)) then t;
    case (DAE.ADD_ARR(ty = t)) then t;
    case (DAE.SUB_ARR(ty = t)) then t;
    case (DAE.MUL_ARR(ty = t)) then t;
    case (DAE.DIV_ARR(ty = t)) then t;
    case (DAE.MUL_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.MUL_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.ADD_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.ADD_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.SUB_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.SUB_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.MUL_SCALAR_PRODUCT(ty = t)) then t;
    case (DAE.MUL_MATRIX_PRODUCT(ty = t)) then t;
    case (DAE.DIV_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.DIV_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.POW_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.POW_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.POW_ARR(ty = t)) then t;
    case (DAE.POW_ARR2(ty = t)) then t;
    case (DAE.AND()) then DAE.ET_BOOL();
    case (DAE.OR()) then DAE.ET_BOOL();
    case (DAE.NOT()) then DAE.ET_BOOL();
    case (DAE.LESS(ty = t)) then t;
    case (DAE.LESSEQ(ty = t)) then t;
    case (DAE.GREATER(ty = t)) then t;
    case (DAE.GREATEREQ(ty = t)) then t;
    case (DAE.EQUAL(ty = t)) then t;
    case (DAE.NEQUAL(ty = t)) then t;
    case (DAE.USERDEFINED(fqName = t))
      local Absyn.Path t;
      then
        DAE.ET_OTHER();
  end matchcontinue;
end typeofOp;

public function setOpType
  "Sets the type of an operator."
  input Operator inOp;
  input Type inType;
  output Operator outOp;
algorithm
  outOp := matchcontinue(inOp, inType)
    case (DAE.ADD(ty = _), _) then DAE.ADD(inType);
    case (DAE.SUB(ty = _), _) then DAE.SUB(inType);
    case (DAE.MUL(ty = _), _) then DAE.MUL(inType);
    case (DAE.DIV(ty = _), _) then DAE.DIV(inType);
    case (DAE.POW(ty = _), _) then DAE.POW(inType);
    case (DAE.UMINUS(ty = _), _) then DAE.UMINUS(inType);
    case (DAE.UPLUS(ty = _), _) then DAE.UPLUS(inType);
    case (DAE.UMINUS_ARR(ty = _), _) then DAE.UMINUS_ARR(inType);
    case (DAE.UPLUS_ARR(ty = _), _) then DAE.UPLUS_ARR(inType);
    case (DAE.ADD_ARR(ty = _), _) then DAE.ADD_ARR(inType);
    case (DAE.SUB_ARR(ty = _), _) then DAE.SUB_ARR(inType);
    case (DAE.MUL_ARR(ty = _), _) then DAE.MUL_ARR(inType);
    case (DAE.DIV_ARR(ty = _), _) then DAE.DIV_ARR(inType);
    case (DAE.MUL_SCALAR_ARRAY(ty = _), _) then DAE.MUL_SCALAR_ARRAY(inType);
    case (DAE.MUL_ARRAY_SCALAR(ty = _), _) then DAE.MUL_ARRAY_SCALAR(inType);
    case (DAE.ADD_SCALAR_ARRAY(ty = _), _) then DAE.ADD_SCALAR_ARRAY(inType);
    case (DAE.ADD_ARRAY_SCALAR(ty = _), _) then DAE.ADD_ARRAY_SCALAR(inType);
    case (DAE.SUB_SCALAR_ARRAY(ty = _), _) then DAE.SUB_SCALAR_ARRAY(inType);
    case (DAE.SUB_ARRAY_SCALAR(ty = _), _) then DAE.SUB_ARRAY_SCALAR(inType);
    case (DAE.MUL_SCALAR_PRODUCT(ty = _), _) then DAE.MUL_SCALAR_PRODUCT(inType);
    case (DAE.MUL_MATRIX_PRODUCT(ty = _), _) then DAE.MUL_MATRIX_PRODUCT(inType);
    case (DAE.DIV_ARRAY_SCALAR(ty = _), _) then DAE.DIV_ARRAY_SCALAR(inType);
    case (DAE.DIV_SCALAR_ARRAY(ty = _), _) then DAE.DIV_SCALAR_ARRAY(inType);
    case (DAE.POW_ARRAY_SCALAR(ty = _), _) then DAE.POW_ARRAY_SCALAR(inType);
    case (DAE.POW_SCALAR_ARRAY(ty = _), _) then DAE.POW_SCALAR_ARRAY(inType);
    case (DAE.POW_ARR(ty = _), _) then DAE.POW_ARR(inType);
    case (DAE.POW_ARR2(ty = _), _) then DAE.POW_ARR2(inType);
    case (DAE.AND, _) then DAE.AND;
    case (DAE.OR, _) then DAE.OR;
    case (DAE.NOT,_ ) then DAE.NOT;
    case (DAE.LESS(ty = _), _) then inOp;
    case (DAE.LESSEQ(ty = _), _) then inOp;
    case (DAE.GREATER(ty = _), _) then inOp;
    case (DAE.GREATEREQ(ty = _), _) then inOp;
    case (DAE.EQUAL(ty = _), _) then inOp;
    case (DAE.NEQUAL(ty = _), _) then inOp;
    case (DAE.USERDEFINED(fqName = _), _) then inOp;
    case (_, _)
      equation
        Debug.fprintln("failtrace","- Exp.setOpType failed on unknown operator");
      then  
        fail();
  end matchcontinue;
end setOpType;

public function isConstFalse
"Return true if expression is false"
  input Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    case DAE.BCONST(false) then true;
    case (_) then false;
  end matchcontinue;
end isConstFalse;

public function isConstTrue
"Return true if expression is true"
  input Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    case DAE.BCONST(true) then true;
    case (_) then false;
  end matchcontinue;
end isConstTrue;

protected function isConstOne
"function: isConstOne
  Return true if expression is 1"
  input Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    local Real rval; Integer ival;
    
    // constant real 1.0
    case DAE.RCONST(rval)
      equation
        true = realEq(rval, 1.0);
      then
        true;
    
    // constant integer 1 
    case DAE.ICONST(ival)
      equation
        true = intEq(ival, 1);
      then 
        true;
    
    // anything else
    case (_) then false;
  end matchcontinue;
end isConstOne;

protected function isConstMinusOne
"function: isConstMinusOne
  Return true if expression is -1"
  input Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    local Real rval; Integer ival;
    
    // is real -1.0
    case DAE.RCONST(rval)
      equation
        true = realEq(rval, -1.0);
      then
        true;
    
    // is integer 1
    case DAE.ICONST(ival)
      equation
         true = intEq(ival, -1);
      then 
        true;
    
    // anything else
    case (_) then false;
  end matchcontinue;
end isConstMinusOne;

public function makeConstZero
"Generates a zero constant"
	input Type inType;
	output Exp const;
algorithm
  const := matchcontinue(inType)
    case (DAE.ET_REAL()) then DAE.RCONST(0.0);
    case (DAE.ET_INT()) then DAE.ICONST(0);
    case(_) then DAE.RCONST(0.0);
  end matchcontinue;
end makeConstZero;

public function makeIntegerExp
"Creates an integer constant expression given the integer input."
  input Integer i;
  output Exp e;
algorithm
  e := DAE.ICONST(i);
end makeIntegerExp;

public function makeConstOne
"function makeConstOne
  author: PA
  Create the constant value one, given a type that is INT or REAL"
  input Type inType;
  output Exp outExp;
algorithm
  outExp := matchcontinue (inType)
    case (DAE.ET_INT()) then DAE.ICONST(1);
    case (DAE.ET_REAL()) then DAE.RCONST(1.0);
  end matchcontinue;
end makeConstOne;

protected function simplifyBinaryConst
"function: simplifyBinaryConst
  This function evaluates constant binary expressions."
  input Operator inOperator1;
  input Exp inExp2;
  input Exp inExp3;
  output Exp outExp;
algorithm
  outExp := matchcontinue (inOperator1,inExp2,inExp3)
    local
      Integer e3,e1,e2;
      Real e2_1,e1_1,v1,v2;
      Operator op;
      Boolean b,b1,b2;
      Exp exp1,exp2;
    
    case (DAE.ADD(ty = _),DAE.ICONST(integer = e1),DAE.ICONST(integer = e2))
      local Exp val;
      equation
        val = safeIntOp(e1,e2,ADDOP);
      then
        val;
    case (DAE.ADD(ty = _),DAE.RCONST(real = e1),DAE.RCONST(real = e2))
      local Real e3,e1,e2;
      equation
        e3 = e1 +. e2;
      then
        DAE.RCONST(e3);
    case (DAE.ADD(ty = _),DAE.RCONST(real = e1),DAE.ICONST(integer = e2))
      local Real e3,e1;
      equation
        e2_1 = intReal(e2);
        e3 = e1 +. e2_1;
      then
        DAE.RCONST(e3);
    case (DAE.ADD(ty = _),DAE.ICONST(integer = e1),DAE.RCONST(real = e2))
      local Real e3,e2;
      equation
        e1_1 = intReal(e1);
        e3 = e1_1 +. e2;
      then
        DAE.RCONST(e3);
    case (DAE.SUB(ty = _),DAE.ICONST(integer = e1),DAE.ICONST(integer = e2))
     	local 	Exp val;
      equation
	   		val = safeIntOp(e1,e2,SUBOP);
      then
        val;
    case (DAE.SUB(ty = _),DAE.RCONST(real = e1),DAE.RCONST(real = e2))
      local Real e3,e1,e2;
      equation
        e3 = e1 -. e2;
      then
        DAE.RCONST(e3);
    case (DAE.SUB(ty = _),DAE.RCONST(real = e1),DAE.ICONST(integer = e2))
      local Real e3,e1;
      equation
        e2_1 = intReal(e2);
        e3 = e1 -. e2_1;
      then
        DAE.RCONST(e3);
    case (DAE.SUB(ty = _),DAE.ICONST(integer = e1),DAE.RCONST(real = e2))
      local Real e3,e2;
      equation
        e1_1 = intReal(e1);
        e3 = e1_1 -. e2;
      then
        DAE.RCONST(e3);
    case (DAE.MUL(ty = _),DAE.ICONST(integer = e1),DAE.ICONST(integer = e2))
      local Exp val;
      equation
        val = safeIntOp(e1,e2,MULOP);
      then
        val;
    case (DAE.MUL(ty = _),DAE.RCONST(real = e1),DAE.RCONST(real = e2))
      local Real e3,e1,e2;
      equation
        e3 = e1 *. e2;
      then
        DAE.RCONST(e3);
    case (DAE.MUL(ty = _),DAE.RCONST(real = e1),DAE.ICONST(integer = e2))
      local Real e3,e1;
      equation
         e2_1 = intReal(e2);
        e3 = e1 *. e2_1;
      then
        DAE.RCONST(e3);
    case (DAE.MUL(ty = _),DAE.ICONST(integer = e1),DAE.RCONST(real = e2))
      local Real e3,e2;
      equation
        e1_1 = intReal(e1);
        e3 = e1_1 *. e2;
      then
        DAE.RCONST(e3);
    case (DAE.DIV(ty = _),DAE.ICONST(integer = e1),DAE.ICONST(integer = e2))
     	local
     	  Exp val;
      equation
	   		val = safeIntOp(e1,e2,DIVOP);
      then
        val;
    case (DAE.DIV(ty = _),DAE.RCONST(real = e1),DAE.RCONST(real = e2))
      local
        Real e3,e1,e2;
      equation
        e3 = e1 /. e2;
      then
        DAE.RCONST(e3);
    case (DAE.DIV(ty = _),DAE.RCONST(real = e1),DAE.ICONST(integer = e2))
      local Real e3,e1;
      equation
        e2_1 = intReal(e2);
        e3 = e1 /. e2_1;
      then
        DAE.RCONST(e3);
    case (DAE.DIV(ty = _),DAE.ICONST(integer = e1),DAE.RCONST(real = e2))
      local Real e3,e2;
      equation
        e1_1 = intReal(e1);
        e3 = e1_1 /. e2;
      then
        DAE.RCONST(e3);
    case (DAE.POW(ty = _),DAE.ICONST(integer = e1),DAE.ICONST(integer = e2))
      local Exp val;
      equation
				val = safeIntOp(e1,e2,POWOP);
      then
				val;
    case (DAE.POW(ty = _),DAE.RCONST(real = e1),DAE.RCONST(real = e2))
      local Real e3,e1,e2;
      equation
        e3 = e1 ^. e2;
      then
        DAE.RCONST(e3);
    case (DAE.POW(ty = _),DAE.RCONST(real = e1),DAE.ICONST(integer = e2))
      local Real e3,e1;
      equation
        e2_1 = intReal(e2);
        e3 = e1 ^. e2_1;
      then
        DAE.RCONST(e3);
    case (DAE.POW(ty = _),DAE.ICONST(integer = e1),DAE.RCONST(real = e2))
      local Real e3,e2;
      equation
        e1_1 = intReal(e1);
        e3 = e1_1 ^. e2;
      then
        DAE.RCONST(e3);
    /* Relation operations */
    case(DAE.LESS(ty=_),exp1,exp2) 
      equation
        v1 = getRealConst(exp1);
        v2 = getRealConst(exp2);
        b = v1 <. v2;
      then 
        DAE.BCONST(b);
    case(DAE.LESSEQ(ty=_),exp1,exp2) 
      equation
        v1 = getRealConst(exp1);
        v2 = getRealConst(exp2);
        b = v1 <=. v2;
      then 
        DAE.BCONST(b);
    case(DAE.GREATER(ty=_),exp1,exp2) 
      equation
        v1 = getRealConst(exp1);
        v2 = getRealConst(exp2);
        b = v1 >. v2;
      then 
        DAE.BCONST(b);
    case(DAE.GREATEREQ(ty=_),exp1,exp2) 
      equation
        v1 = getRealConst(exp1);
        v2 = getRealConst(exp2);
        b = v1 >=. v2;
      then 
        DAE.BCONST(b);
    case(DAE.EQUAL(ty=_),exp1,exp2) 
      equation
        v1 = getRealConst(exp1);
        v2 = getRealConst(exp2);
        b = v1 ==. v2;
      then 
        DAE.BCONST(b);
    case(DAE.NEQUAL(ty=_),exp1,exp2) 
      equation
        v1 = getRealConst(exp1);
        v2 = getRealConst(exp2);
        b = v1 <>. v2;
      then 
        DAE.BCONST(b);
    case(DAE.AND(),exp1,exp2) 
      equation
        b1 = getBoolConst(exp1);
        b2 = getBoolConst(exp2);
        b = b1 and b2;
      then 
        DAE.BCONST(b);
    case(DAE.OR(),exp1,exp2) 
      equation
        b1 = getBoolConst(exp1);
        b2 = getBoolConst(exp2);
        b = b1 or b2;
      then 
        DAE.BCONST(b);
    // end adrpo added
    case (op,e1,e2)
      local Exp e1,e2;
      then
        fail();
  end matchcontinue;
end simplifyBinaryConst;

protected function simplifyBinary
"function: simplifyBinary
  This function simplifies binary expressions."
  input Exp inExp1;
  input Operator inOperator2;
  input Exp inExp3 "Note: already simplified"; // lhs
  input Exp inExp4 "Note: aldready simplified"; // rhs
  output Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inOperator2,inExp3,inExp4)
    local
      Exp e1_1,e2_1,e3,e,e1,e2,res,e_1,one;
      Operator oper;
      Type ty,ty2,tp,tp2,ty1;
      Ident s1,s2;
      list<Exp> exp_lst,exp_lst_1;
      DAE.ComponentRef cr1,cr2;
      Boolean b;
    
    // constants   
    case (e,oper,e1,e2)
      equation
        true = isConst(e1);
        true = isConst(e2);
        e3 = simplifyBinaryConst(oper, e1, e2);
      then
        e3;
    
    // (a+b)/c1 => a/c1+b/c1, for constant c1
    case (_,DAE.DIV(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = ty2),exp2 = e2),e3)
      equation
        true = isConst(e3);
        res = simplify1(DAE.BINARY(DAE.BINARY(e1,DAE.DIV(ty),e3),DAE.ADD(ty2),DAE.BINARY(e2,DAE.DIV(ty),e3)));
      then
        res;
    
    // (a-b)/c1 => a/c1-b/c1, for constant c1
    case (_,DAE.DIV(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = ty2),exp2 = e2),e3)
      equation
        true = isConst(e3);
        res = simplify1(DAE.BINARY(DAE.BINARY(e1,DAE.DIV(ty),e3),DAE.SUB(ty2),DAE.BINARY(e2,DAE.DIV(ty),e3)));
      then
        res;
    
    // (a+b)c1 => ac1+bc1, for constant c1
    case (_,DAE.MUL(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = ty2),exp2 = e2),e3)
      equation
        true = isConst(e3);
        res = simplify1(DAE.BINARY(DAE.BINARY(e1,DAE.MUL(ty),e3),DAE.ADD(ty2),DAE.BINARY(e2,DAE.MUL(ty),e3)));
      then
        res;
    
    // (a-b)c1 => a/c1-b/c1, for constant c1
    case (_,DAE.MUL(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = ty2),exp2 = e2),e3)
      equation
        true = isConst(e3);
        res = simplify1(DAE.BINARY(DAE.BINARY(e1,DAE.MUL(ty),e3),DAE.SUB(ty2),DAE.BINARY(e2,DAE.MUL(ty),e3)));
      then
        res;
    
    // a+(-b)
    case (_,DAE.ADD(ty = tp),e1,DAE.UNARY(operator = DAE.UMINUS(ty = tp2),exp = e2))
      equation
        e = simplify1(DAE.BINARY(e1,DAE.SUB(tp),e2));
      then
        e;
            
    // (-b)+a
    case (_,DAE.ADD(ty = tp),DAE.UNARY(operator = DAE.UMINUS(ty = tp2),exp = e2), e1)
      equation
        e1 = simplify1(DAE.BINARY(e1,DAE.SUB(tp),e2));
      then
        e1;
    
    // a/b/c => (ac)/b)
    case (_,DAE.DIV(ty = tp),e1,DAE.BINARY(exp1 = e2,operator = DAE.DIV(ty = tp2),exp2 = e3))
      equation
        e = simplify1(DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e3),DAE.DIV(tp2),e2))  ;
      then
        e;
    
    // (a/b)/c => a/(bc))
    case (_,DAE.DIV(ty = tp),DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp2),exp2 = e2),e3)
      equation
        e = simplify1(DAE.BINARY(e1,DAE.DIV(tp2),DAE.BINARY(e2,DAE.MUL(tp),e3)));
      then
        e;
    
    // a / (b*a)  = 1/b
    case (_,DAE.DIV(ty = tp),e1,DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp2),exp2 = e3))
      equation
        true = expEqual(e1,e3);
        e = simplify1(DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(tp2),e2));
      then
        e;
    
    // a / (a*b)  = 1/b
    case (_,DAE.DIV(ty = tp),e1,DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp2),exp2 = e3))
      equation
        true = expEqual(e1,e2);
        e = simplify1(DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(tp2),e3));
      then
        e;
    
    // add with 0
    case (_,DAE.ADD(ty = ty),e1,e2)
      equation
        true = isZero(e1);
      then
        e2;
    
    // add to 0 
    case (_,DAE.ADD(ty = ty),e1,e2)
      equation
        true = isZero(e2);
      then
        e1;
    
    // subtract from zero
    case (_,DAE.SUB(ty = ty),e1,e2)
      equation
        true = isZero(e1);
        e = DAE.UNARY(DAE.UMINUS(ty),e2);
        e_1 = simplify1(e);
      then
        e_1;
    
    // subtract zero
    case (_,DAE.SUB(ty = ty),e1,e2)
      equation
        true = isZero(e2);
      then
        e1;
    
    // a - a  = 0
    case(_,DAE.SUB(ty = ty),e1,e2) 
      equation
        true = expEqual(e1,e2);
        e1 = makeConstZero(ty);
      then 
        e1;

    // a-(-b) = a+b
    case (_,DAE.SUB(ty = ty),e1,DAE.UNARY(operator = DAE.UMINUS(ty = ty2),exp = e2))
      equation
        e = simplify1(DAE.BINARY(e1,DAE.ADD(ty),e2));
      then
        e;
    
    // (e1/e2)e3 => (e1e3)/e2
    case (_,DAE.MUL(ty = tp),DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp2),exp2 = e2),e3)
      equation
        res = simplify1(DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e3),DAE.DIV(tp2),e2));
      then
        res;
    
    // e1(e2/e3) => (e1e2)/e3
    case (_,DAE.MUL(ty = tp),e1,DAE.BINARY(exp1 = e2,operator = DAE.DIV(ty = tp2),exp2 = e3))
      equation
        res = simplify1(DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e2),DAE.DIV(tp2),e3));
      then
        res;
    
    // a * 0 = 0
    case (_,DAE.MUL(ty = ty),e1,e2)
      equation
        true = isZero(e1);
      then
        e1;
    
    // 0 * a = 0
    case (_,DAE.MUL(ty = ty),e1,e2)
      equation
        true = isZero(e2);
      then
        e2;
    
    // a * 1 = a 
    case (_,DAE.MUL(ty = ty),e1,e2)
      equation
        true = isConstOne(e1);
      then
        e2;
    
    // 1 * a = a
    case (_,DAE.MUL(ty = ty),e1,e2)
      equation
        true = isConstOne(e2);
      then
        e1;
    
    // a * -1 = -a 
    case (_,DAE.MUL(ty = ty),e1,e2)
      equation
        true = isConstMinusOne(e1);
        e = simplify1(DAE.UNARY(DAE.UMINUS(ty),e2));
      then
        e;
    
    // -1 * a = -a
    case (_,DAE.MUL(ty = ty),e1,e2)
      equation
        true = isConstMinusOne(e2);
        e = simplify1(DAE.UNARY(DAE.UMINUS(ty),e1));
      then 
        e;
    
    // -a * -b = a * b
    case (_,DAE.MUL(ty = ty),DAE.UNARY(operator = DAE.UMINUS(ty = ty1),exp = e1),DAE.UNARY(operator = DAE.UMINUS(ty = ty2),exp = e2))
      equation
        e = simplify1(DAE.BINARY(e1,DAE.MUL(ty),e2));
      then
        e;
    
    // e1  -e2 => -e1  e2 
    case (_,DAE.MUL(ty = ty),e1,DAE.UNARY(operator = DAE.UMINUS(ty = ty2),exp = e2))
      equation
        e1_1 = simplify1(DAE.UNARY(DAE.UMINUS(ty),e1));
      then
        DAE.BINARY(e1_1,DAE.MUL(ty),e2);
    
    // 0 / x = 0
    case (_,DAE.DIV(ty = ty),e1,e2)
      equation
        true = isZero(e1);
      then
        DAE.RCONST(0.0);

    /* // a / 0 => division error
    case (_,DAE.DIV(ty = ty),e1,e2)
      equation
        true = isZero(e2);
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        Error.addMessage(Error.DIVISION_BY_ZERO, {s1,s2});
      then
        fail();*/
    
    // a / 1 = a
    case (_,DAE.DIV(ty = ty),e1,e2)
      equation
        true = isConstOne(e2);
      then
        e1;
    
    // a / -1 = -a
    case (_,DAE.DIV(ty = ty),e1,e2)
      equation
        true = isConstMinusOne(e2);
        e = simplify1(DAE.UNARY(DAE.UMINUS(ty),e1));
      then
        e;
    
    // a / a  = 1
    case (_,DAE.DIV(ty = ty),e1,e2)
      equation
        true = expEqual(e1,e2);
        res = createConstOne(ty);
      then
        res;
    
    // -a / -b = a / b 
    case (_,DAE.DIV(ty = ty),DAE.UNARY(operator = DAE.UMINUS(ty = ty1),exp = e1),DAE.UNARY(operator = DAE.UMINUS(ty = ty2),exp = e2))      
      then
        DAE.BINARY(e1,DAE.DIV(ty),e2);
    
    // e1 / -e2  => -e1 / e2 
    case (_,DAE.DIV(ty = ty),e1,DAE.UNARY(operator = DAE.UMINUS(ty = ty2),exp = e2))
      equation
        e1_1 = simplify1(DAE.UNARY(DAE.UMINUS(ty),e1));
      then
        DAE.BINARY(e1_1,DAE.DIV(ty),e2);
    
    // e2*e3 / e1 => e3/e1 * e2
    case (_,DAE.DIV(ty = tp2),DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp),exp2 = e3),e1)
      equation
        true = isConst(e3) "(c1x)/c2" ;
        true = isConst(e1);
        e = simplify1(DAE.BINARY(e3,DAE.DIV(tp2),e1));
      then
        DAE.BINARY(e,DAE.MUL(tp),e2);
    
    // e2*e3 / e1 => e2 / e1 * e3
    case (_,DAE.DIV(ty = tp2),DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp),exp2 = e3),e1)
      equation
        true = isConst(e2) ;
        true = isConst(e1);
        e = simplify1(DAE.BINARY(e2,DAE.DIV(tp2),e1));
      then
        DAE.BINARY(e,DAE.MUL(tp),e3);
    
    // e ^ 1 => e
    case (_,DAE.POW(ty = _),e1,e)
      equation
        e_1 = simplify1(e);
        true = isConstOne(e_1);
      then
        e1;
    
    // e ^ - 1 =>  1 / e
    case (_,DAE.POW(ty = tp),e2,e)
      equation
        true = isConstMinusOne(e);
        one = makeConstOne(tp);
      then
        DAE.BINARY(one,DAE.DIV(DAE.ET_REAL()),e2);
    
    // e ^ 0 => 1
    case (_,DAE.POW(ty = _),e1,e)
      equation
        tp = typeof(e1);
        true = isZero(e);
        res = createConstOne(tp);
      then
        res;
    
    // 1 ^ e => 1
    case (_,DAE.POW(ty = _),e1,e)
      equation
        true = isConstOne(e1);
      then
        e1;
    
    // (a1a2...an)^e2 => a1^e2a2^e2..an^e2
    case (_,DAE.POW(ty = _),e1,e2)
      equation
        ((exp_lst as (_ :: _ :: _ :: _))) = factors(e1);
        exp_lst_1 = simplifyBinaryDistributePow(exp_lst, e2);
        res = makeProductLst(exp_lst_1);
      then
        res;
    
    // relation: cr1 == cr2, where cr1 and cr2 are the same 
    case(_,DAE.EQUAL(_),DAE.CREF(cr1,_),DAE.CREF(cr2,_)) 
      equation
        true = crefEqual(cr1,cr2);
      then 
        DAE.BCONST(true);
    
    // relation: cr1 <> cr2 . where cr1 and cr2 are the same 
    case(_,DAE.NEQUAL(_),DAE.CREF(cr1,_),DAE.CREF(cr2,_)) 
      equation
        true = crefEqual(cr1,cr2);
      then 
        DAE.BCONST(false);
    
    // nothing else to simplify
    case (e,_,_,_) then e;
  end matchcontinue;
end simplifyBinary;

protected function simplifyBinaryDistributePow
"function simplifyBinaryDistributePow
  author: PA
  Distributes the pow operator over a list of expressions.
  ({e1,e2,..,en} , pow_e) =>  {e1^pow_e, e2^pow_e,..,en^pow_e}"
  input list<Exp> inExpLst;
  input Exp inExp;
  output list<Exp> outExpLst;
algorithm
  outExpLst := matchcontinue (inExpLst,inExp)
    local
      list<Exp> es_1,es;
      Type tp;
      Exp e,pow_e;
    
    // handle emptyness
    case ({},_) then {};
    
   	// Remove 1^pow_e
    case ((e :: es),pow_e)
      equation
        true = isConstOne(e);
        es_1 = simplifyBinaryDistributePow(es, pow_e);
      then es_1;
    
    // move to next 
    case ((e :: es),pow_e)
      equation
        es_1 = simplifyBinaryDistributePow(es, pow_e);
        tp = typeof(e);
      then
        (DAE.BINARY(e,DAE.POW(tp),pow_e) :: es_1);
  end matchcontinue;
end simplifyBinaryDistributePow;

protected function createConstOne
"function: createConstOne
  Creates a constant value one, given a type INT or REAL"
  input Type inType;
  output Exp outExp;
algorithm
  outExp := matchcontinue (inType)
    local Real realv;
    case (DAE.ET_REAL())
      equation
        realv = intReal(1);
      then
        DAE.RCONST(realv);
    case (DAE.ET_INT()) then DAE.ICONST(1);
  end matchcontinue;
end createConstOne;

protected function simplifyUnary
"function: simplifyUnary
  Simplifies unary expressions."
  input Exp inExp1;
  input Operator inOperator2;
  input Exp inExp3;
  output Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inOperator2,inExp3)
    local
      Type ty,ty1;
      Exp e1,e1_1,e_1,e2,e;
      Integer i_1,i;
      Real r_1,r;
      Boolean b1;
    
    // not true => false, not false => true
    case(_,DAE.NOT(),e1) 
      equation
        b1 = getBoolConst(e1);
        b1 = not b1;
      then 
        DAE.BCONST(b1);
    
    // +e => e
    case (_,DAE.UPLUS(ty = ty),e1) 
      then e1;
    case (_,DAE.UPLUS_ARR(ty = ty),e1) 
      then e1;
    
    // -x => 0 - x
    case (_,DAE.UMINUS(ty = ty),DAE.ICONST(integer = i))
      equation
        i_1 = 0 - i;
      then
        DAE.ICONST(i_1);
    
    // -x => 0.0 - x 
    case (_,DAE.UMINUS(ty = ty),DAE.RCONST(real = r))
      equation
        r_1 = 0.0 -. r;
      then
        DAE.RCONST(r_1);
    
    // -(a * b) => (-a) * b
    case (_,DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = ty1),exp2 = e2))
      equation
         e_1 = simplify1(DAE.BINARY(DAE.UNARY(DAE.UMINUS(ty),e1),DAE.MUL(ty1),e2));
      then
        e_1;
    case (_,DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(ty = ty1),exp2 = e2))
      equation
         e_1 = simplify1(DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.MUL_ARR(ty1),e2)) "-(a*b) => (-a)*b" ;
      then
        e_1;
    // -0 => 0
    case (_,DAE.UMINUS(ty = ty),e1)
      equation
        e1_1 = simplify1(e1);
        true = isZero(e1_1);
      then
        e1_1;
    case (_,DAE.UMINUS_ARR(ty = ty),e1)
      equation
        e1_1 = simplify1(e1);
        true = isZero(e1_1);
      then
        e1_1;
    //  -(a-b) => b - a        
    case (_,DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = ty1),exp2 = e2))
      equation
        e_1 = simplify1(DAE.BINARY(e2,DAE.SUB(ty1),e1)) "-(a-b) => b-a" ;
      then
        e_1;
    case (_,DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = ty1),exp2 = e2))
      equation
        e_1 = simplify1(DAE.BINARY(e2,DAE.SUB_ARR(ty1),e1)) "-(a-b) => b-a" ;
      then
        e_1;
    // -(a + b) => -b - a    
    case (_,DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = ty1),exp2 = e2))
      equation
        e_1 = simplify1(DAE.BINARY(DAE.UNARY(DAE.UMINUS(ty),e1),DAE.ADD(ty1),DAE.UNARY(DAE.UMINUS(ty),e2))) "-(a+b) => -b-a" ;
      then
        e_1;
    case (_,DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = ty1),exp2 = e2))
      equation
        e_1 = simplify1(DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.ADD_ARR(ty1),DAE.UNARY(DAE.UMINUS_ARR(ty),e2))) "-(a+b) => -b-a" ;
      then
        e_1;
    // -( a / b) => -a / b
    case (_,DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = ty1),exp2 = e2))
      equation
        e_1 = simplify1(DAE.BINARY(DAE.UNARY(DAE.UMINUS(ty),e1),DAE.DIV(ty1),e2)) "-(a/b) => -a/b" ;
      then
        e_1;
    case (_,DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARR(ty = ty1),exp2 = e2))
      equation
        e_1 = simplify1(DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.DIV_ARR(ty1),e2)) "-(a/b) => -a/b" ;
      then
        e_1; 
    // -(a * b) => -a * b    
    case (_,DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = ty1),exp2 = e2))
      equation
        e_1 = simplify1(DAE.BINARY(DAE.UNARY(DAE.UMINUS(ty),e1),DAE.MUL(ty1),e2)) "-(ab) => -ab" ;
      then
        e_1;
    case (_,DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(ty = ty1),exp2 = e2))
      equation
        e_1 = simplify1(DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.MUL_ARR(ty1),e2)) "-(ab) => -ab" ;
      then
        e_1;        
     // --a => a   
     case (_,DAE.UMINUS(ty = _),DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = e1)) /* --a => a */
      equation
        e1_1 = simplify1(e1);
      then
        e1_1;
    case (_,DAE.UMINUS_ARR(ty = _),DAE.UNARY(operator = DAE.UMINUS_ARR(ty = _),exp = e1)) /* --a => a */
      equation
        e1_1 = simplify1(e1);
      then
        e1_1;
    // anything else stays the same    
    case (e,_,_) then e;
  end matchcontinue;
end simplifyUnary;

public function containVectorFunctioncall
"Returns true if expression or subexpression is a
 functioncall that returns an array, otherwise false.
  Note: the der operator is represented as a
        function call but still return false."
  input Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    local
      Exp e1,e2,e,e3;
      Boolean res;
      list<Boolean> blst;
      list<Exp> elst;
      list<tuple<Exp, Boolean>> flatexplst;
      list<list<tuple<Exp, Boolean>>> explst;
      Option<Exp> optexp;
    
    // der is not a vector function
    case (DAE.CALL(path = Absyn.IDENT(name = "der"))) then false;
    
    // pre is not a vector function, adrpo: 2009-03-03 -> pre is also needed here!
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"))) then false;
    
    // inStream and actualStream are not a vector function, adrpo: 2010-08-31 -> they are also needed here!
    case (DAE.CALL(path = Absyn.IDENT(name = "inStream"))) then false;
    case (DAE.CALL(path = Absyn.IDENT(name = "actualStream"))) then false;      
    
    // a call that has an return array type returns true 
    case (DAE.CALL(path = _, ty = DAE.ET_ARRAY(_,_))) then true;
    
    // any other call returns false
    case (DAE.CALL(path = _)) then false;
    
    // partial evaluation
    case (DAE.PARTEVALFUNCTION(path = _, expList = elst)) // stefan
      equation
        blst = Util.listMap(elst,containVectorFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    
    // binary operators, e1 has a vector function call
    case (DAE.BINARY(exp1 = e1,exp2 = e2)) 
      equation
        true = containVectorFunctioncall(e1);
      then
        true;    
    // binary operators, e2 has a vector function call
    case (DAE.BINARY(exp1 = e1,exp2 = e2))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // unary operators
    case (DAE.UNARY(exp = e))
      equation
        res = containVectorFunctioncall(e);
      then
        res;
    // logical binary operators, e1 is a vector call
    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        true = containVectorFunctioncall(e1);
      then
        true;
    // logical binary operators, e2 is a vector call
    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // logical unary operators, e is a vector call
    case (DAE.LUNARY(exp = e))
      equation
        res = containVectorFunctioncall(e);
      then
        res;
    // relations e1 op e2, where e1 is a vector call
    case (DAE.RELATION(exp1 = e1,exp2 = e2))
      equation
        true = containVectorFunctioncall(e1);
      then
        true;
    // relations e1 op e2, where e2 is a vector call
    case (DAE.RELATION(exp1 = e1,exp2 = e2))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // if expression where the condition is a vector call
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containVectorFunctioncall(e1);
      then
        true;
    // if expression where the then part is a vector call
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // if expression where the else part is a vector call
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containVectorFunctioncall(e3);
      then
        true;
    // arrays 
    case (DAE.ARRAY(array = elst))
      equation
        blst = Util.listMap(elst, containVectorFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // matrixes
    case (DAE.MATRIX(scalar = explst))
      equation
        flatexplst = Util.listFlatten(explst);
        elst = Util.listMap(flatexplst, Util.tuple21);
        blst = Util.listMap(elst, containVectorFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // ranges [e1:step:e2], where e1 is a vector call
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2))
      equation
        true = containVectorFunctioncall(e1);
      then
        true;
    // ranges [e1:step:e2], where e2 is a vector call
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // ranges [e1:step:e2], where step is a vector call
    case (DAE.RANGE(exp = e1,expOption = SOME(e),range = e2))
      equation
        true = containVectorFunctioncall(e);
      then
        true;
    // tuples return true all the time???!! adrpo: FIXME! TODO! is this really true?
    case (DAE.TUPLE(PR = elst))
      equation 
        blst = Util.listMap(elst, containVectorFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // cast
    case (DAE.CAST(exp = e))
      equation
        res = containVectorFunctioncall(e);
      then
        res;
    // size operator
    case (DAE.SIZE(exp = e1,sz = optexp))      
      equation
        true = containVectorFunctioncall(e1);
      then
        true;
    // size operator
    case (DAE.SIZE(exp = e1,sz = SOME(e2)))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // any other expressions return false
    case (_) then false;
  end matchcontinue;
end containVectorFunctioncall;

public function containFunctioncall
"function: containFunctioncall
  Returns true if expression or subexpression
  is a functioncall, otherwise false.
  Note: the der and pre operators are represented
        as function calls but still returns false."
  input Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    local
      Exp e1,e2,e,e3;
      Boolean res;
      list<Boolean> blst;
      list<Exp> elst;
      list<tuple<Exp, Boolean>> flatexplst;
      list<list<tuple<Exp, Boolean>>> explst;
      Option<Exp> optexp;
    
    // der(x) is not a function call
    case (DAE.CALL(path = Absyn.IDENT(name = "der"))) then false;
    // pre(x) is not a function call
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"))) then false;
    // any other call is a function call
    case (DAE.CALL(path = _)) then true;
    // partial evaluation functions
    case (DAE.PARTEVALFUNCTION(path = _, expList = elst)) // stefan
      equation
        blst = Util.listMap(elst,containFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // binary
    case (DAE.BINARY(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e1);
      then
        true;
    case (DAE.BINARY(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e2);
      then
        true;
    // unary
    case (DAE.UNARY(exp = e))
      equation
        res = containFunctioncall(e);
      then
        res;
    // logical binary
    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e1);
      then
        true; 
    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e2);
      then
        true;
    // logical unary
    case (DAE.LUNARY(exp = e))
      equation
        res = containFunctioncall(e);
      then
        res;
    // relations
    case (DAE.RELATION(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e1);
      then
        true;
    case (DAE.RELATION(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e2);
      then
        true;
    // if expressions
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containFunctioncall(e1);
      then
        true;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containFunctioncall(e2);
      then
        true;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containFunctioncall(e3);
      then
        true;
    // arrays 
    case (DAE.ARRAY(array = elst))
      equation
        blst = Util.listMap(elst, containFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // matrix
    case (DAE.MATRIX(scalar = explst))
      equation
        flatexplst = Util.listFlatten(explst);
        elst = Util.listMap(flatexplst, Util.tuple21);
        blst = Util.listMap(elst, containFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // ranges
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2))
      equation
        true = containFunctioncall(e1);
      then
        true; 
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2))
      equation
        true = containFunctioncall(e2);
      then
        true;
    case (DAE.RANGE(exp = e1,expOption = SOME(e),range = e2))
      equation
        true = containFunctioncall(e);
      then
        true;
    // tuples return true all the time???!! adrpo: FIXME! TODO! is this really true?
    case (DAE.TUPLE(PR = elst))
      equation 
        blst = Util.listMap(elst, containVectorFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // cast
    case (DAE.CAST(exp = e))
      equation
        res = containFunctioncall(e);
      then
        res;
    // size
    case (DAE.SIZE(exp = e1,sz = e2))
      local Option<Exp> e2;
      equation
        true = containFunctioncall(e1);
      then
        true;
    case (DAE.SIZE(exp = e1,sz = SOME(e2)))
      equation
        true = containFunctioncall(e2);
      then
        true;
    // anything else
    case (_) then false;
  end matchcontinue;
end containFunctioncall;

public function unelabExp
"function: unelabExp
  Transform an Exp into Absyn.Exp.
  Note: This function currently only works for
  constants and component references."
  input Exp inExp;
  output Absyn.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      Integer i;
      Real r;
      Ident s;
      Boolean b;
      Absyn.ComponentRef cr_1;
      ComponentRef cr;
      Type t,tp;
      list<Absyn.Exp> expl_1,aexpl;
      list<Exp> expl;
      Exp e1,e2,e3;
      Operator op;
      Absyn.Exp ae1,ae2,ae3;
      Absyn.Operator aop;
      list<list<Exp>> mexpl2;
      list<list<Absyn.Exp>> amexpl;
      list<list<tuple<Exp,Boolean>>> mexpl;
      Absyn.ComponentRef acref;
      Absyn.Path path;
      Absyn.CodeNode code;

    case (DAE.ICONST(integer = i)) then Absyn.INTEGER(i);
    case (DAE.RCONST(real = r)) then Absyn.REAL(r);
    case (DAE.SCONST(string = s)) then Absyn.STRING(s);
    case (DAE.BCONST(bool = b)) then Absyn.BOOL(b);
    case (DAE.CREF(componentRef = cr,ty = t))
      equation
        cr_1 = unelabCref(cr);
      then
        Absyn.CREF(cr_1);

    case(DAE.BINARY(e1,op,e2)) equation
      aop = unelabOperator(op);
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.BINARY(ae1,aop,ae2);

    case(DAE.UNARY(op,e1)) equation
      aop = unelabOperator(op);
      ae1 = unelabExp(e1);
    then Absyn.UNARY(aop,ae1);

    case(DAE.LBINARY(e1,op,e2)) equation
      aop = unelabOperator(op);
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.LBINARY(ae1,aop,ae2);

    case(DAE.LUNARY(op,e1)) equation
      aop = unelabOperator(op);
      ae1 = unelabExp(e1);
    then Absyn.LUNARY(aop,ae1);

    case(DAE.RELATION(e1,op,e2)) equation
      aop = unelabOperator(op);
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.RELATION(ae1,aop,ae2);

    case(DAE.IFEXP(e1,e2,e3)) equation
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
      ae3 = unelabExp(e3);
    then Absyn.IFEXP(ae1,ae2,ae3,{});

    case(DAE.CALL(path,expl,_,_,_,_)) equation
      aexpl = Util.listMap(expl,unelabExp);
      acref = Absyn.pathToCref(path);
    then Absyn.CALL(acref,Absyn.FUNCTIONARGS(aexpl,{}));

    case(DAE.PARTEVALFUNCTION(path,expl,_))
      equation
        aexpl = Util.listMap(expl,unelabExp);
        acref = Absyn.pathToCref(path);
      then
        Absyn.PARTEVALFUNCTION(acref,Absyn.FUNCTIONARGS(aexpl,{}));

    case (DAE.ARRAY(ty = tp,scalar = b,array = expl))
      equation
        expl_1 = Util.listMap(expl, unelabExp);
      then
        Absyn.ARRAY(expl_1);
    
    case(DAE.MATRIX(_,_,mexpl)) equation
      mexpl2 = Util.listListMap(mexpl,Util.tuple21);
      amexpl = Util.listListMap(mexpl2,unelabExp);
    then (Absyn.MATRIX(amexpl));

    case(DAE.RANGE(_,e1,SOME(e2),e3)) equation
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
      ae3 = unelabExp(e3);
    then Absyn.RANGE(ae1,SOME(ae2),ae3);

    case(DAE.RANGE(_,e1,NONE,e3)) equation
      ae1 = unelabExp(e1);
      ae3 = unelabExp(e3);
    then Absyn.RANGE(ae1,NONE,ae3);

    case(DAE.TUPLE(expl))
      equation
        expl_1 = Util.listMap(expl, unelabExp);
      then
        Absyn.TUPLE(expl_1);
    case(DAE.CAST(_,e1)) equation
      ae1 = unelabExp(e1);
    then ae1;

     // ASUB can not be unelabed since it has no representation in Absyn.
    case(DAE.ASUB(_,_)) equation
      print("Internal Error, can not unelab ASUB\n");
    then fail();

    case(DAE.SIZE(e1,SOME(e2))) equation
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({ae1,ae2},{}));

    case(DAE.SIZE(e1,SOME(e2))) equation
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({ae1,ae2},{}));

    case(DAE.CODE(code,_)) then Absyn.CODE(code);

    case DAE.REDUCTION(path,e1,s,e2) equation
      //print("unelab of reduction not impl. yet");
      acref = Absyn.pathToCref(path);
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then 
      Absyn.CALL(acref, Absyn.FOR_ITER_FARG(ae1, {(s,SOME(ae2))}));

    case(DAE.END()) then Absyn.END();
    case(DAE.VALUEBLOCK(_,_,_,_)) equation
      print("unelab of VALUEBLOCK not impl. yet");
    then fail();
  end matchcontinue;
end unelabExp;

public function unelabCref
"function: unelabCref
  Helper function to unelabExp, handles component references."
  input ComponentRef inComponentRef;
  output Absyn.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef)
    local
      list<Absyn.Subscript> subs_1;
      Ident id;
      list<Subscript> subs;
      Absyn.ComponentRef cr_1;
      ComponentRef cr;
    
    // identifiers
    case (DAE.CREF_IDENT(ident = id,subscriptLst = subs))
      equation
        subs_1 = unelabSubscripts(subs);
      then
        Absyn.CREF_IDENT(id,subs_1);
    
    // qualified
    case (DAE.CREF_QUAL(ident = id,subscriptLst = subs,componentRef = cr))
      equation
        cr_1 = unelabCref(cr);
        subs_1 = unelabSubscripts(subs);
      then
        Absyn.CREF_QUAL(id,subs_1,cr_1);
  end matchcontinue;
end unelabCref;

protected function unelabSubscripts
"function: unelabSubscripts
  Helper function to unelabCref, handles subscripts."
  input list<Subscript> inSubscriptLst;
  output list<Absyn.Subscript> outAbsynSubscriptLst;
algorithm
  outAbsynSubscriptLst := matchcontinue (inSubscriptLst)
    local
      list<Absyn.Subscript> xs_1;
      list<Subscript> xs;
      Absyn.Exp e_1;
      Exp e;
    
    // empty list
    case ({}) then {};
    // whole dimension
    case ((DAE.WHOLEDIM() :: xs))
      equation
        xs_1 = unelabSubscripts(xs);
      then
        (Absyn.NOSUB() :: xs_1);
    // slices
    case ((DAE.SLICE(exp = e) :: xs))
      equation
        xs_1 = unelabSubscripts(xs);
        e_1 = unelabExp(e);
      then
        (Absyn.SUBSCRIPT(e_1) :: xs_1);
    // indexes
    case ((DAE.INDEX(exp = e) :: xs))
      equation
        xs_1 = unelabSubscripts(xs);
        e_1 = unelabExp(e);
      then
        (Absyn.SUBSCRIPT(e_1) :: xs_1);
  end matchcontinue;
end unelabSubscripts;

public function toExpCref
"function: toExpCref
  Translate an Absyn.ComponentRef into a ComponentRef.
  Note: Only support for indexed subscripts of integers"
  input Absyn.ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef)
    local
      list<Subscript> subs_1;
      Ident id;
      list<Absyn.Subscript> subs;
      ComponentRef cr_1;
      Absyn.ComponentRef cr;
    
    // ids
    case (Absyn.CREF_IDENT(name = id,subscripts = subs))
      equation
        subs_1 = toExpCrefSubs(subs);
      then
        DAE.CREF_IDENT(id,DAE.ET_OTHER(),subs_1);
    
    // qualified
    case (Absyn.CREF_QUAL(name = id,subScripts = subs,componentRef = cr))
      equation
        cr_1 = toExpCref(cr);
        subs_1 = toExpCrefSubs(subs);
      then
        DAE.CREF_QUAL(id,DAE.ET_OTHER(),subs_1,cr_1);
    
    // qualified
    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cr))
      equation
        cr_1 = toExpCref(cr);
      then
        cr_1; /* There is no DAE.CREF_FULLYQUALIFIED */
  end matchcontinue;
end toExpCref;

protected function toExpCrefSubs
"function: toExpCrefSubs
  Helper function to toExpCref."
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  output list<Subscript> outSubscriptLst;
algorithm
  outSubscriptLst := matchcontinue (inAbsynSubscriptLst)
    local
      list<Subscript> xs_1;
      Integer i;
      list<Absyn.Subscript> xs;
      ComponentRef cr_1;
      Absyn.ComponentRef cr;
      Ident s,str;
      Absyn.Subscript e;
    
    // empty list
    case ({}) then {};
    // integer subscripts become indexes of integers
    case ((Absyn.SUBSCRIPT(subScript = Absyn.INTEGER(value = i)) :: xs))
      equation
        xs_1 = toExpCrefSubs(xs);
      then
        (DAE.INDEX(DAE.ICONST(i)) :: xs_1);
    // cref subscripts become indexes of crefs 
    // => Assumes index is INTEGER. FIXME! TODO!: what about if index is an array?
    case ((Absyn.SUBSCRIPT(subScript = Absyn.CREF(componentRef = cr)) :: xs)) 
      equation
        cr_1 = toExpCref(cr);
        xs_1 = toExpCrefSubs(xs);
      then
        (DAE.INDEX(DAE.CREF(cr_1,DAE.ET_INT())) :: xs_1);
    // when there is an error, move to next TODO! FIXME! report an error!
    case ((e :: xs))
      equation
        s = Dump.printSubscriptsStr({e});
        str = Util.stringAppendList({"#Error converting subscript: ",s," to Exp.\n"});
        //print("#Error converting subscript: " +& s +& " to Exp.\n");
        //Print.printErrorBuf(str);
        xs_1 = toExpCrefSubs(xs);
      then
        xs_1;
  end matchcontinue;
end toExpCrefSubs;

public function addSubscriptsLast "
Function for appending subscripts at end on last ident"
  input ComponentRef cr;
  input Integer i;
  output ComponentRef ocr;
algorithm
  ocr := matchcontinue(cr,i)
    local
      list<Subscript> a3;
      Type a2;
      String a1;
      ComponentRef a4;
    // ids
    case(DAE.CREF_IDENT(a1,a2,a3),i)
      equation
        a3 = listAppend(a3,{DAE.INDEX(DAE.ICONST(i))});
      then
        DAE.CREF_IDENT(a1,a2,a3);
    // qualified
    case(DAE.CREF_QUAL(a1,a2,a3,a4),i)
      equation
        a4 = addSubscriptsLast(a4,i);
      then
        DAE.CREF_QUAL(a1,a2,a3,a4);
  end matchcontinue;
end addSubscriptsLast;

public function subscriptsAppend
"function: subscriptsAppend
  This function takes a subscript list and adds a new subscript.
  But there are a few special cases.  When the last existing
  subscript is a slice, it is replaced by the slice indexed by
  the new subscript."
  input list<Subscript> inSubscriptLst;
  input Exp inSubscript;
  output list<Subscript> outSubscriptLst;
algorithm
  outSubscriptLst := matchcontinue (inSubscriptLst,inSubscript)
    local
      Exp e_1,e;
      Subscript s;
      list<Subscript> ss_1,ss;
    case ({},_) then {DAE.INDEX(inSubscript)};
    case (DAE.WHOLEDIM() :: ss,_) then DAE.INDEX(inSubscript) :: ss;
    case ({DAE.SLICE(exp = e)},_)
      equation
        e_1 = simplify1(DAE.ASUB(e,{inSubscript}));
      then
        {DAE.INDEX(e_1)};
    case ({(s as DAE.INDEX(exp = _))},_) then {s,DAE.INDEX(inSubscript)};
    case ((s :: ss),_)
      equation
        ss_1 = subscriptsAppend(ss, inSubscript);
      then
        (s :: ss_1);
  end matchcontinue;
end subscriptsAppend;

/*
 * - Printing expressions
 *   This module provides some functions to print data to the standard
 *   output.  This is used for error messages, and for debugging the
 *   semantic description.
 */
public function typeString "function typeString
  Converts a type into a String"
  input Type inType;
  output String outString;
algorithm
  outString := matchcontinue (inType)
    local
      list<Ident> ss;
      Ident s1,ts,res;
      Type t;
      list<DAE.Dimension> dims;
      list<tuple<Type,Ident>> varlst;
      list<String> strLst;
      String s1,s2;
    case DAE.ET_INT() then "INT";
    case DAE.ET_REAL() then "REAL";
    case DAE.ET_BOOL() then "BOOL";
    case DAE.ET_STRING() then "STRING";
    case DAE.ET_ENUMERATION(index=SOME(_)) then "ENUM";
    case DAE.ET_ENUMERATION(index=NONE()) then "ENUM TYPE";
    case DAE.ET_OTHER() then "OTHER";
    case (DAE.ET_ARRAY(ty = t,arrayDimensions = dims))
      equation
        ss = Util.listMap(dims, dimensionString);
        s1 = Util.stringDelimitListNonEmptyElts(ss, ", ");
        ts = typeString(t);
        res = Util.stringAppendList({"/tp:",ts,"[",s1,"]/"});
      then
        res;
    case(DAE.ET_COMPLEX(varLst=vars,complexClassType=ci))
      local list<Var> vars; String s;
        ClassInf.State ci;
      equation
        s = "DAE.ET_COMPLEX(" +& typeVarsStr(vars) +& "):" +& ClassInf.printStateStr(ci);
      then s;
    case(_) then "#Exp.typeString failed#";
  end matchcontinue;
end typeString;

public function printComponentRef
"function: printComponentRef
  Print a ComponentRef."
  input ComponentRef inComponentRef;
algorithm
  _ := matchcontinue (inComponentRef)
    local
      Ident s;
      list<Subscript> subs;
      ComponentRef cr;
    // _
    case DAE.WILD()
      equation
        Print.printBuf("_");
      then
        ();
    // ids
    case DAE.CREF_IDENT(ident = s,subscriptLst = subs)
      equation
        printComponentRef2(s, subs);
      then
        ();
    // qualified crefs, does not handle names with underscores
    case DAE.CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr)
      equation
        true = RTOpts.modelicaOutput();
        printComponentRef2(s, subs);
        Print.printBuf("__");
        printComponentRef(cr);
      then
        ();
    case DAE.CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr)
      equation
        false = RTOpts.modelicaOutput();
        printComponentRef2(s, subs);
        Print.printBuf(".");
        printComponentRef(cr);
      then
        ();
  end matchcontinue;
end printComponentRef;

protected function printComponentRef2
"function: printComponentRef2
  Helper function to printComponentRef"
  input String inString;
  input list<Subscript> inSubscriptLst;
algorithm
  _ := matchcontinue (inString,inSubscriptLst)
    local
      Ident s;
      list<Subscript> l;
    case (s,{})
      equation
        Print.printBuf(s);
      then
        ();
    case (s,l)
      equation
        true = RTOpts.modelicaOutput();
        Print.printBuf(s);
        Print.printBuf("_L");
        printList(l, printSubscript, ",");
        Print.printBuf("_R");
      then
        ();
    case (s,l)
      equation
        false = RTOpts.modelicaOutput();
        Print.printBuf(s);
        Print.printBuf("[");
        printList(l, printSubscript, ",");
        Print.printBuf("]");
      then
        ();
  end matchcontinue;
end printComponentRef2;

public function printSubscript
"function: printSubscript
  Print a Subscript."
  input Subscript inSubscript;
algorithm
  _ := matchcontinue (inSubscript)
    local Exp e1;
    case (DAE.WHOLEDIM())
      equation
        Print.printBuf(":");
      then
        ();
    case (DAE.INDEX(exp = e1))
      equation
        printExp(e1);
      then
        ();
    case (DAE.SLICE(exp = e1))
      equation
        printExp(e1);
      then
        ();
  end matchcontinue;
end printSubscript;

public function printExp
"function: printExp
  This function prints a complete expression."
  input Exp e;
algorithm
  printExp2(e, 0);
end printExp;

protected function printExp2
"function: printExp2
  Helper function to printExp."
  input Exp inExp;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inExp,inInteger)
    local
      Ident s,sym,fs,rstr,str;
      Integer x,pri2_1,pri2,pri3,pri1,i;
      Real r;
      ComponentRef c;
      Exp e1,e2,e21,e22,e,t,f,start,stop,step,cr,dim,exp,iterexp;
      Operator op;
      Type ty,ty2;
      Absyn.Path fcn;
      list<Exp> args,es;
    case (DAE.ICONST(integer = x),_)
      equation
        s = intString(x);
        Print.printBuf(s);
      then
        ();
    case (DAE.RCONST(real = x),_)
      local Real x;
      equation
        s = realString(x);
        Print.printBuf(s);
      then
        ();
    case (DAE.SCONST(string = s),_)
      equation
        Print.printBuf("\"");
        Print.printBuf(s);
        Print.printBuf("\"");
      then
        ();
    case (DAE.BCONST(bool = false),_)
      equation
        Print.printBuf("false");
      then
        ();
    case (DAE.BCONST(bool = true),_)
      equation
        Print.printBuf("true");
      then
        ();
    case (DAE.CREF(componentRef = c),_)
      equation
        printComponentRef(c);
      then
        ();

    case (DAE.ENUM_LITERAL(name = enum_lit), _)
      local Absyn.Path enum_lit;
      equation
        s = Absyn.pathString(enum_lit);
        Print.printBuf(s);
      then
        ();

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.SUB(ty = ty)),exp2 = (e2 as DAE.BINARY(exp1 = e21,operator = DAE.SUB(ty = ty2),exp2 = e22))),pri1)
      equation
        sym = binopSymbol(op);
        pri2_1 = binopPriority(op);
        pri2 = pri2_1 + 1;
        pri3 = printLeftpar(pri1, pri2) "binary minus have higher priority than itself" ;
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = binopSymbol(op);
        pri2 = binopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    case (DAE.UNARY(operator = op,exp = e),pri1)
      equation
        sym = unaryopSymbol(op);
        pri2 = unaryopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        Print.printBuf(sym);
        printExp2(e, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = lbinopSymbol(op);
        pri2 = lbinopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    case (DAE.LUNARY(operator = op,exp = e),pri1)
      equation
        sym = lunaryopSymbol(op);
        pri2 = lunaryopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        Print.printBuf(sym);
        printExp2(e, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = relopSymbol(op);
        pri2 = relopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    case (DAE.IFEXP(expCond = c,expThen = t,expElse = f),pri1)
      local Exp c;
      equation
        Print.printBuf("if ");
        printExp2(c, 0);
        Print.printBuf(" then ");
        printExp2(t, 0);
        Print.printBuf(" else ");
        printExp2(f, 0);
      then
        ();
    case (DAE.CALL(path = fcn,expLst = args),_)
      equation
        fs = Absyn.pathString(fcn);
        Print.printBuf(fs);
        Print.printBuf("(");
        printList(args, printExp, ",");
        Print.printBuf(")");
      then
        ();
    case (DAE.PARTEVALFUNCTION(path = fcn, expList = args),_)
      equation
        fs = Absyn.pathString(fcn);
        Print.printBuf("function ");
        Print.printBuf(fs);
        Print.printBuf("(");
        printList(args, printExp, ",");
        Print.printBuf(")");
      then
        ();

    case (DAE.ARRAY(array = es),_)
      equation
        Print.printBuf("{") "Print.printBuf \"This an array: \" &" ;
        printList(es, printExp, ",");
        Print.printBuf("}");
      then
        ();
    case (DAE.TUPLE(PR = es),_) /* PR. */
      equation
        Print.printBuf("(");
        printList(es, printExp, ",");
        Print.printBuf(")");
      then
        ();
    case (DAE.MATRIX(scalar = es),_)
      local list<list<tuple<Exp, Boolean>>> es;
      equation
        Print.printBuf("<matrix>[");
        printList(es, printRow, ";");
        Print.printBuf("]");
      then
        ();
    case (DAE.RANGE(exp = start,expOption = NONE,range = stop),pri1)
      equation
        pri2 = 41;
        pri3 = printLeftpar(pri1, pri2);
        printExp2(start, pri3);
        Print.printBuf(":");
        printExp2(stop, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    case (DAE.RANGE(exp = start,expOption = SOME(step),range = stop),pri1)
      equation
        pri2 = 41;
        pri3 = printLeftpar(pri1, pri2);
        printExp2(start, pri3);
        Print.printBuf(":");
        printExp2(step, pri3);
        Print.printBuf(":");
        printExp2(stop, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = DAE.ICONST(integer = i)),_)
      equation
        false = RTOpts.modelicaOutput();
        r = intReal(i);
        rstr = realString(r);
        Print.printBuf(rstr);
      then
        ();
    case (DAE.CAST(ty = t,exp = e),_)
      local DAE.ExpType t;
      equation
        false = RTOpts.modelicaOutput();
        s = "/*" +& typeString(t) +& "*/";
        Print.printBuf(s +& "(");
        printExp(e);
        Print.printBuf(")");
      then
        ();
    case (DAE.CAST(ty = _,exp = e),_)
      equation
        true = RTOpts.modelicaOutput();
        printExp(e);
      then
        ();
    case (DAE.ASUB(exp = e,sub = ((ae1 as DAE.ICONST(i)))::{}),pri1)
      local
        Exp ae1;
      equation
        pri2 = 51;
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e, pri3);
        printRightpar(pri1, pri2);
        Print.printBuf("[");
        s = intString(i);
        Print.printBuf(s);
        Print.printBuf("]");
      then
        ();

    case (DAE.ASUB(exp = e,sub = ae1),pri1)
      local
        list<Exp> ae1;
      equation
        pri2 = 51;
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e, pri3);
        printRightpar(pri1, pri2);
        Print.printBuf("[");
        s = Util.stringDelimitList(Util.listMap(ae1,printExpStr),", ");
        Print.printBuf(s);
        Print.printBuf("]");
      then
        ();
    case ((e as DAE.SIZE(exp = cr,sz = SOME(dim))),_)
      equation
        str = printExpStr(e);
        Print.printBuf(str);
      then
        ();
    case ((e as DAE.SIZE(exp = cr,sz = NONE)),_)
      equation
        str = printExpStr(e);
        Print.printBuf(str);
      then
        ();
    case ((e as DAE.REDUCTION(path = fcn,expr = exp,ident = i,range = iterexp)),_)
      local Ident i;
      equation
        str = printExpStr(e);
        Print.printBuf(str);
      then
        ();

    // MetaModelica list
    case (DAE.LIST(_,es),_)
      local list<Exp> es;
      equation
        Print.printBuf("<list>{");
        printList(es, printExp, ",");
        Print.printBuf("}");
      then
        ();

    // MetaModelica list cons
    case (DAE.CONS(_,e1,e2),_)
      equation
        Print.printBuf("cons(");
        printExp(e1);
        Print.printBuf(",");
        printExp(e2);
        Print.printBuf(")");
      then
        ();

      // MetaModelica Uniontype Constructor
    case (DAE.METARECORDCALL(path = fcn, args=args),_)
      equation
        fs = Absyn.pathString(fcn);
        Print.printBuf(fs);
        Print.printBuf("(");
        printList(args, printExp, ",");
        Print.printBuf(")");
      then
        ();

    case (DAE.VALUEBLOCK(_,_,_,_),_)
      equation
        Print.printBuf("#VALUEBLOCK#");
      then
        ();

    case (e,_)
      equation
        // debug_print("unknown expression - printExp2: ", e);
        Print.printBuf("#UNKNOWN EXPRESSION# ----eee " +& printExpStr(e));
      then
        ();
  end matchcontinue;
end printExp2;

protected function printLeftpar
"function: printLeftpar
  Print a left paranthesis if priorities require it."
  input Integer inInteger1;
  input Integer inInteger2;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inInteger1,inInteger2)
    local Integer x,y,pri1,pri2;
    case (x,y) /* prio1 prio2 */
      equation
        (x > y) = true;
        Print.printBuf("(");
      then
        0;
    case (pri1,pri2) then pri2;
  end matchcontinue;
end printLeftpar;

protected function printRightpar
"function: printRightpar
  Print a left paranthesis if priorities require it."
  input Integer inInteger1;
  input Integer inInteger2;
algorithm
  _:=
  matchcontinue (inInteger1,inInteger2)
    local Integer x,y;
    case (x,y) /* prio1 prio2 */
      equation
        (x > y) = true;
        Print.printBuf(")");
      then
        ();
    case (_,_) then ();
  end matchcontinue;
end printRightpar;

public function binopPriority
"function: binopPriority
  Returns a priority number for each operator.
  Used to determine when parenthesis in expressions is required.
  Priorities:
    and, or		10
    not		11
    <, >, =, != etc.	21
    bin +		32
    bin -		33
    			35
    /			36
    unary +, unary -	37
    ^			38
    :			41
    {}		51

  LS: Changed precedence for unary +-
   which must be higher than binary operators but lower than power
   according to e.g. matlab

  LS: Changed precedence for binary - , should be higher than + and also
      itself, but this is specially handled in printExp2 and printExp2Str"
  input Operator inOperator;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inOperator)
    case (DAE.ADD(ty = _)) then 32;
    case (DAE.SUB(ty = _)) then 33;
    case (DAE.ADD_ARR(ty = _)) then 32;
    case (DAE.SUB_ARR(ty = _)) then 33;
    case (DAE.MUL_ARR(ty = _)) then 35;
    case (DAE.DIV_ARR(ty = _)) then 36;
    case (DAE.POW_ARR(ty = _)) then 38;
    case (DAE.POW_ARR2(ty = _)) then 38;
    case (DAE.MUL(ty = _)) then 35;
    case (DAE.MUL_SCALAR_ARRAY(ty = _)) then 35;
    case (DAE.MUL_ARRAY_SCALAR(ty = _)) then 35;
    case (DAE.ADD_SCALAR_ARRAY(ty = _)) then 32;
    case (DAE.ADD_ARRAY_SCALAR(ty = _)) then 32;
    case (DAE.SUB_SCALAR_ARRAY(ty = _)) then 33;
    case (DAE.SUB_ARRAY_SCALAR(ty = _)) then 33;
    case (DAE.MUL_SCALAR_PRODUCT(ty = _)) then 35;
    case (DAE.MUL_MATRIX_PRODUCT(ty = _)) then 35;
    case (DAE.DIV(ty = _)) then 36;
    case (DAE.DIV_SCALAR_ARRAY(ty = _)) then 36;
    case (DAE.DIV_ARRAY_SCALAR(ty = _)) then 36;
    case (DAE.POW(ty = _)) then 38;
    case (DAE.POW_SCALAR_ARRAY(ty = _)) then 38;
    case (DAE.POW_ARRAY_SCALAR(ty = _)) then 38;
  end matchcontinue;
end binopPriority;

public function unaryopPriority
"function: unaryopPriority
  Determine unary operator priorities, see binopPriority."
  input Operator inOperator;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inOperator)
    case (DAE.UMINUS(ty = _)) then 37;
    case (DAE.UPLUS(ty = _)) then 37;
    case (DAE.UMINUS_ARR(ty = _)) then 37;
    case (DAE.UPLUS_ARR(ty = _)) then 37;
  end matchcontinue;
end unaryopPriority;

public function lbinopPriority
"function: lbinopPriority
  Determine logical binary operator
  priorities, see binopPriority."
  input Operator inOperator;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inOperator)
    case (DAE.AND()) then 10;
    case (DAE.OR()) then 10;
  end matchcontinue;
end lbinopPriority;

public function lunaryopPriority
"function: lunaryopPriority
  Determine logical unary operator
  priorities, see binopPriority."
  input Operator inOperator;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inOperator)
    case (DAE.NOT()) then 11;
  end matchcontinue;
end lunaryopPriority;

public function relopPriority
"function: relopPriority
  Determine function operator
  priorities, see binopPriority."
  input Operator inOperator;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inOperator)
    case (DAE.LESS(ty = _)) then 21;
    case (DAE.LESSEQ(ty = _)) then 21;
    case (DAE.GREATER(ty = _)) then 21;
    case (DAE.GREATEREQ(ty = _)) then 21;
    case (DAE.EQUAL(ty = _)) then 21;
    case (DAE.NEQUAL(ty = _)) then 21;
  end matchcontinue;
end relopPriority;

public function makeRealAdd
"function: makeRealAdd
  Construct an add node of the two expressions of type REAL."
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inExp2)
    local Exp e1,e2;
    case (e1,e2) then DAE.BINARY(e1,DAE.ADD(DAE.ET_REAL()),e2);
  end matchcontinue;
end makeRealAdd;

public function makeRealArray
"function: makeRealArray
  Construct an array node of an Exp list of type REAL."
  input list<Exp> inExpLst;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExpLst)
    local list<Exp> expl;
    case (expl) then DAE.ARRAY(DAE.ET_REAL(),false,expl);
  end matchcontinue;
end makeRealArray;

public function makeListOfZeros
  input Integer inDimension;
  output list<Exp> outList;
algorithm
  outList := matchcontinue(inDimension)
    local Integer dimension;
      Exp head;
      list<Exp> tail;
      case(0)
        then {};
      case(dimension) equation
        head = DAE.RCONST(0.0);
        tail = makeListOfZeros(dimension-1);
        then head :: tail;
  end matchcontinue;
end makeListOfZeros;

public function makeRealArrayOfZeros
  input Integer inDimension;
  output Exp outExp;
  list<Exp> l;
algorithm
  l := makeListOfZeros(inDimension);
  outExp := makeRealArray(l);
end makeRealArrayOfZeros;

public function binopSymbol "
function: binopSymbol
  Return a string representation of the Operator."
  input Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    local
      Ident s;
      Operator op;
    case op
      equation
        false = RTOpts.typeinfo();
        s = binopSymbol1(op);
      then
        s;
    case op
      equation
        true = RTOpts.typeinfo();
        s = binopSymbol2(op);
      then
        s;
  end matchcontinue;
end binopSymbol;

public function binopSymbol1
"function: binopSymbol1
  Helper function to binopSymbol"
  input Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.ADD(ty = _)) then " + ";
    case (DAE.SUB(ty = _)) then " - ";
    case (DAE.MUL(ty = _)) then " * ";
    case (DAE.DIV(ty = _)) then " / ";
    case (DAE.POW(ty = _)) then " ^ ";
    case (DAE.EQUAL(ty = _)) then " = ";
    case (DAE.ADD_ARR(ty = _)) then " + ";
    case (DAE.SUB_ARR(ty = _)) then " - ";
    case (DAE.MUL_ARR(ty = _)) then " * ";
    case (DAE.DIV_ARR(ty = _)) then " / ";
    case (DAE.POW_ARR(ty = _)) then " ^ ";
    case (DAE.POW_ARR2(ty = _)) then " ^ ";
    case (DAE.MUL_SCALAR_ARRAY(ty = _)) then " * ";
    case (DAE.MUL_ARRAY_SCALAR(ty = _)) then " * ";
    case (DAE.ADD_SCALAR_ARRAY(ty = _)) then " + ";
    case (DAE.ADD_ARRAY_SCALAR(ty = _)) then " + ";
    case (DAE.SUB_SCALAR_ARRAY(ty = _)) then " - ";
    case (DAE.SUB_ARRAY_SCALAR(ty = _)) then " - ";
    case (DAE.POW_SCALAR_ARRAY(ty = _)) then " ^ ";
    case (DAE.POW_ARRAY_SCALAR(ty = _)) then " ^ ";
    case (DAE.MUL_SCALAR_PRODUCT(ty = _)) then " * ";
    case (DAE.MUL_MATRIX_PRODUCT(ty = _)) then " * ";
    case (DAE.DIV_SCALAR_ARRAY(ty = _)) then " / ";
    case (DAE.DIV_ARRAY_SCALAR(ty = _)) then " / ";
  end matchcontinue;
end binopSymbol1;

public function debugBinopSymbol 
"function: binopSymbol1 
  Helper function to binopSymbol"
  input Operator inOperator;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inOperator)
    case (DAE.ADD(ty = _)) then " + "; 
    case (DAE.SUB(ty = _)) then " - ";       
    case (DAE.MUL(ty = _)) then " * "; 
    case (DAE.DIV(ty = _)) then " / "; 
    case (DAE.POW(ty = _)) then " ^ ";
    case (DAE.EQUAL(ty = _)) then " = ";  
    case (DAE.ADD_ARR(ty = _)) then " +ARR "; 
    case (DAE.SUB_ARR(ty = _)) then " -ARR "; 
    case (DAE.MUL_ARR(ty = _)) then " *ARR "; 
    case (DAE.DIV_ARR(ty = _)) then " /ARR "; 
    case (DAE.POW_ARR(ty = _)) then " ^ARR "; 
    case (DAE.POW_ARR2(ty = _)) then " ^ARR2 "; 
    case (DAE.MUL_SCALAR_ARRAY(ty = _)) then " S*ARR "; 
    case (DAE.MUL_ARRAY_SCALAR(ty = _)) then " ARR*S "; 
    case (DAE.ADD_SCALAR_ARRAY(ty = _)) then " S+ARR "; 
    case (DAE.ADD_ARRAY_SCALAR(ty = _)) then " ARR+S "; 
    case (DAE.SUB_SCALAR_ARRAY(ty = _)) then " - "; 
    case (DAE.SUB_ARRAY_SCALAR(ty = _)) then " ARR-S "; 
    case (DAE.POW_SCALAR_ARRAY(ty = _)) then " S^ARR "; 
    case (DAE.POW_ARRAY_SCALAR(ty = _)) then " ARR^S "; 
    case (DAE.MUL_SCALAR_PRODUCT(ty = _)) then " Dot "; 
    case (DAE.MUL_MATRIX_PRODUCT(ty = _)) then " MatrixProd "; 
    case (DAE.DIV_SCALAR_ARRAY(ty = _)) then " S/ARR "; 
    case (DAE.DIV_ARRAY_SCALAR(ty = _)) then " ARR/S "; 
  end matchcontinue;
end debugBinopSymbol;

protected function binopSymbol2
"function: binopSymbol2
  Helper function to binopSymbol."
  input Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    local
      Ident ts,s,s_1;
      Type t;
    case (DAE.ADD(ty = t))
      equation
        ts = typeString(t);
        s = stringAppend(" +<", ts);
        s_1 = stringAppend(s, "> ");
      then
        s_1;
    case (DAE.SUB(ty = t)) equation
       ts = typeString(t);
       s = stringAppend(" -<", ts);
        s_1 = stringAppend(s, "> ");
      then
        s_1;
    case (DAE.MUL(ty = t)) equation
      ts = typeString(t);
       s = stringAppend(" *<", ts);
        s_1 = stringAppend(s, "> ");
      then
        s_1;
    case (DAE.DIV(ty = t))
      equation
        ts = typeString(t);
        s = stringAppend(" /<", ts);
        s_1 = stringAppend(s, "> ");
      then
        s_1;
    case (DAE.POW(ty = t)) then " ^ ";
    case (DAE.ADD_ARR(ty = _)) then " + ";
    case (DAE.SUB_ARR(ty = _)) then " - ";
    case (DAE.MUL_ARR(ty = _)) then " * ";
    case (DAE.DIV_ARR(ty = _)) then " / ";
    case (DAE.POW_ARR(ty = _)) then " ^ ";
    case (DAE.POW_ARR2(ty = _)) then " ^ ";
    case (DAE.MUL_SCALAR_ARRAY(ty = _)) then " * ";
    case (DAE.MUL_ARRAY_SCALAR(ty = _)) then " * ";
    case (DAE.ADD_SCALAR_ARRAY(ty = _)) then " + ";
    case (DAE.ADD_ARRAY_SCALAR(ty = _)) then " + ";
    case (DAE.SUB_SCALAR_ARRAY(ty = _)) then " - ";
    case (DAE.SUB_ARRAY_SCALAR(ty = _)) then " - ";
    case (DAE.POW_SCALAR_ARRAY(ty = _)) then " ^ ";
    case (DAE.POW_ARRAY_SCALAR(ty = _)) then " ^ ";
    case (DAE.MUL_SCALAR_PRODUCT(ty = _)) then " * ";
    case (DAE.MUL_MATRIX_PRODUCT(ty = _)) then " * ";
    case (DAE.DIV_SCALAR_ARRAY(ty = _)) then " / ";
    case (DAE.DIV_ARRAY_SCALAR(ty = _)) then " / ";
  end matchcontinue;
end binopSymbol2;

public function unaryopSymbol
"function: unaryopSymbol
  Return string representation of unary operators."
  input Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.UMINUS(ty = _)) then "-";
    case (DAE.UPLUS(ty = _)) then "+";
    case (DAE.UMINUS_ARR(ty = _)) then "-";
    case (DAE.UPLUS_ARR(ty = _)) then "+";
  end matchcontinue;
end unaryopSymbol;

public function lbinopSymbol
"function: lbinopSymbol
  Return string representation of logical binary operator."
  input Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.AND()) then " AND ";
    case (DAE.OR()) then " OR ";
  end matchcontinue;
end lbinopSymbol;

public function lunaryopSymbol
"function: lunaryopSymbol
  Return string representation of logical unary operator."
  input Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.NOT()) then " NOT ";
  end matchcontinue;
end lunaryopSymbol;

public function relopSymbol
"function: relopSymbol
  Return string representation of function operator."
  input Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.LESS(ty = _)) then " < ";
    case (DAE.LESSEQ(ty = _)) then " <= ";
    case (DAE.GREATER(ty = _)) then " > ";
    case (DAE.GREATEREQ(ty = _)) then " >= ";
    case (DAE.EQUAL(ty = _)) then " == ";
    case (DAE.NEQUAL(ty = _)) then " <> ";
  end matchcontinue;
end relopSymbol;

public function printList
"function: printList
  Print a list of values given a print
  function and a separator string."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input String inString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo,inString)
    local
      Type_a h;
      FuncTypeType_aTo r;
      list<Type_a> t;
      Ident sep;
    case ({},_,_) then ();
    case ({h},r,_)
      equation
        r(h);
      then
        ();
    case ((h :: t),r,sep)
      equation
        r(h);
        Print.printBuf(sep);
        printList(t, r, sep);
      then
        ();
  end matchcontinue;
end printList;

protected function printRow
"function: printRow
  Print a list of expressions to the Print buffer."
  input list<tuple<Exp, Boolean>> es;
  list<Exp> es_1;
algorithm
  es_1 := Util.listMap(es, Util.tuple21);
  printList(es_1, printExp, ",");
end printRow;

public function printComponentRefOptStr
"@autor: adrpo
  Print a cref or none"
  input Option<ComponentRef> inComponentRefOpt;
  output String outString;
algorithm
   outString := matchcontinue(inComponentRefOpt)
     local
       String str;
       ComponentRef cref;
     
     // none
     case NONE() then "NONE()"; 
     
     // some 
     case SOME(cref)
       equation
         str = printComponentRefStr(cref);
         str = "SOME(" +& str +& ")";
       then
         str;
   end matchcontinue;
end printComponentRefOptStr;

public function printComponentRefStr
"function: printComponentRefStr
  Print a ComponentRef.
  LS: print functions that return a string instead of printing
      Had to duplicate the huge printExp2 and modify.
      An alternative would be to implement sprint somehow
  which would need internal state, with reset and
      getString methods.
      Once these are tested and ok, the printExp above can
      be replaced by a call to these _str functions and
      printing the result."
  input ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef)
    local
      Ident s,str,strrest,str_1,str_2;
      list<Subscript> subs;
      ComponentRef cr;
      Type ty;
    case (DAE.CREF_IDENT(ident = s,identType = ty,subscriptLst = {}))
      then s; /* optimize */
    case DAE.CREF_IDENT(ident = s,identType = ty, subscriptLst = subs)
      equation
        str = printComponentRef2Str(s, subs);
      then
        str;
    case DAE.CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr) /* Does not handle names with underscores */
      equation
        true = RTOpts.modelicaOutput();
        str = printComponentRef2Str(s, subs);
        strrest = printComponentRefStr(cr);
        str_1 = stringAppend(str, "__");
        str_2 = stringAppend(str_1, strrest);
      then
        str_2;
    case DAE.CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr)
      equation
        false = RTOpts.modelicaOutput();
        str = printComponentRef2Str(s, subs);
        strrest = printComponentRefStr(cr);
        str_1 = stringAppend(str, ".");
        str_2 = stringAppend(str_1, strrest);
      then
        str_2;
    case DAE.WILD() then "_";
  end matchcontinue;
end printComponentRefStr;

public function printComponentRef2Str
"function: printComponentRef2Str
  Helper function to printComponentRefStr."
  input Ident inIdent;
  input list<Subscript> inSubscriptLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inIdent,inSubscriptLst)
    local
      Ident s,str,str_1,str_2,str_3;
      list<Subscript> l;
    case (s,{}) then s;
    case (s,l)
      equation
        true = RTOpts.modelicaOutput();
        str = printListStr(l, printSubscriptStr, ",");
        str_1 = stringAppend(s, "_L");
        str_2 = stringAppend(str_1, str);
        str_3 = stringAppend(str_2, "_R");
      then
        str_3;
    case (s,l)
      equation
        false = RTOpts.modelicaOutput();
        str = printListStr(l, printSubscriptStr, ",");
        str_1 = stringAppend(s, "[");
        str_2 = stringAppend(str_1, str);
        str_3 = stringAppend(str_2, "]");
      then
        str_3;
  end matchcontinue;
end printComponentRef2Str;

public function printListStr
"function: printListStr
  Same as printList, except it returns
  a string instead of printing."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input String inString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString:=
  matchcontinue (inTypeALst,inFuncTypeTypeAToString,inString)
    local
      Ident s,srest,s_1,s_2,sep;
      Type_a h;
      FuncTypeType_aToString r;
      list<Type_a> t;
    case ({},_,_) then "";
    case ({h},r,_)
      equation
        s = r(h);
      then
        s;
    case ((h :: t),r,sep)
      equation
        s = r(h);
        srest = printListStr(t, r, sep);
        s_1 = stringAppend(s, sep);
        s_2 = stringAppend(s_1, srest);
      then
        s_2;
  end matchcontinue;
end printListStr;

public function debugPrintSubscriptStr "
  Print a Subscript into a String."
  input Subscript inSubscript;
  output String outString;
algorithm
  outString:=
  matchcontinue (inSubscript)
    local
      Ident s;
      Exp e1;
    case (DAE.WHOLEDIM()) then ":";
    case (DAE.INDEX(exp = e1))
      equation
        s = dumpExpStr(e1,0);
      then
        s;
    case (DAE.SLICE(exp = e1))
      equation
        s = dumpExpStr(e1,0);
      then
        s;
  end matchcontinue;
end debugPrintSubscriptStr;


public function printSubscriptStr "
  Print a Subscript into a String."
  input Subscript inSubscript;
  output String outString;
algorithm
  outString:=
  matchcontinue (inSubscript)
    local
      Ident s;
      Exp e1;
    case (DAE.WHOLEDIM()) then ":";
    case (DAE.INDEX(exp = e1))
      equation
        s = printExpStr(e1);
      then
        s;
    case (DAE.SLICE(exp = e1))
      equation
        s = printExpStr(e1);
      then
        s;
  end matchcontinue;
end printSubscriptStr;

public function printExpListStr
"function: printExpListStr
 prints a list of expressions with commas between expressions."
  input list<Exp> expl;
  output String res;
algorithm
  res := Util.stringDelimitList(Util.listMap(expl,printExpStr),", ");
end printExpListStr;

// stefan
public function printExpListStrNoSpace
"function: printExpListStrNoSpace
	same as printExpListStr, but the string will not have any spaces or commas between expressions"
	input list<Exp> expl;
	output String res;
algorithm
  res := Util.stringAppendList(Util.listMap(expl,printExpStr));
end printExpListStrNoSpace;

public function printOptExpStr "
Returns a string if SOME otherwise ''
"
input Option<Exp> oexp;
output String str;
algorithm str := matchcontinue(oexp)
  case(NONE) then "";
  case(SOME(e)) local Exp e; then printExpStr(e);
  end matchcontinue;
end printOptExpStr;

public function printExpStr
"function: printExpStr
  This function prints a complete expression."
  input Exp e;
  output String s;
algorithm
  s := printExp2Str(e, "\"",NONE(),NONE());
end printExpStr;

public function printExp2Str
"function: printExp2Str
  Helper function to printExpStr."
  input Exp inExp;
  input String stringDelimiter;
  input Option<tuple<printComponentRefStrFunc,Type_a>> opcreffunc "tuple of function that prints component references and an extra parameter passed through to the function";
  input Option<printCallFunc> opcallfunc "function that prints function calls";
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function printComponentRefStrFunc
    input ComponentRef inComponentRef;
    input Type_a Param;
    output String outString;
  end printComponentRefStrFunc;  
  partial function printCallFunc
    input Exp inExp;
    input String stringDelimiter;
    input Option<tuple<printComponentRefStrFunc,Type_a>> opcreffunc "tuple of function that prints component references and an extra parameter passed through to the function";
    output String outString;
    partial function printComponentRefStrFunc
      input ComponentRef inComponentRef;
      input Type_a Param;
      output String outString;
    end printComponentRefStrFunc;    
  end printCallFunc;  
algorithm
  outString:=
  matchcontinue (inExp, stringDelimiter, opcreffunc, opcallfunc)
    local
      Ident s,s_1,s_2,sym,s1,s2,s3,s4,s_3,ifstr,thenstr,elsestr,res,fs,argstr,s5,s_4,s_5,res2,str,crstr,dimstr,expstr,iterstr,id;
      Ident s1_1,s2_1,s1_2,s2_2,cs,ts,fs,cs_1,ts_1,fs_1,s3_1;
      Integer x,pri2_1,pri2,pri3,pri1,ival,i,pe1,p1,p2,pc,pt,pf,p,pstop,pstart,pstep;
      Real rval;
      ComponentRef c;
      Type t,ty,ty2,tp;
      Exp e1,e2,e21,e22,e,f,start,stop,step,cr,dim,exp,iterexp,cond,tb,fb;
      Operator op;
      Absyn.Path fcn;
      list<Exp> args,es;
      printComponentRefStrFunc pcreffunc;
      Type_a creffuncparam;
      printCallFunc pcallfunc;
    case (DAE.END(), _, _, _) then "end";
    case (DAE.ICONST(integer = x), _, _, _)
      equation
        s = intString(x);
      then
        s;
    case (DAE.RCONST(real = x), _, _, _)
      local Real x;
      equation
        s = realString(x);
      then
        s;
    case (DAE.SCONST(string = s), _, _, _)
      equation
        s_1 = stringAppend(stringDelimiter, s);
        s_2 = stringAppend(s_1, stringDelimiter);
      then
        s_2;
    case (DAE.BCONST(bool = false), _, _, _) then "false";
    case (DAE.BCONST(bool = true), _, _, _) then "true";
    case (DAE.CREF(componentRef = c,ty = t), _, SOME((pcreffunc,creffuncparam)), _)
      equation
        s = pcreffunc(c,creffuncparam);
      then
        s;      
    case (DAE.CREF(componentRef = c,ty = t), _, _, _)
      equation
        s = printComponentRefStr(c);
      then
        s;

    case (DAE.ENUM_LITERAL(name = lit), _, _, _)
      local Absyn.Path lit;
      equation
        s = Absyn.pathString(lit);
      then
        s;

    case (e as DAE.BINARY(e1,op,e2), _, _, _)
      equation
        sym = binopSymbol(op);
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s2 = printExp2Str(e2, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        p1 = expPriority(e1);
        p2 = expPriority(e2);
        s1_1 = parenthesize(s1, p1, p,false);
        s2_1 = parenthesize(s2, p2, p,true);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;
     case ((e as DAE.UNARY(op,e1)), _, _, _)
      equation
        sym = unaryopSymbol(op);
        s = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        p1 = expPriority(e1);
        s_1 = parenthesize(s, p1, p,true);
        s_2 = stringAppend(sym, s_1);
      then
        s_2;
   case ((e as DAE.LBINARY(e1,op,e2)), _, _, _)
      equation
        sym = lbinopSymbol(op);
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s2 = printExp2Str(e2, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        p1 = expPriority(e1);
        p2 = expPriority(e2);
        s1_1 = parenthesize(s1, p1, p,false);
        s2_1 = parenthesize(s2, p2, p,true);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;
   case ((e as DAE.LUNARY(op,e1)), _, _, _)
      equation
        sym = lunaryopSymbol(op);
        s = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        p1 = expPriority(e1);
        s_1 = parenthesize(s, p1, p,false);
        s_2 = stringAppend(sym, s_1);
      then
        s_2;
    case ((e as DAE.RELATION(e1,op,e2)), _, _, _)
      equation
        sym = relopSymbol(op);
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s2 = printExp2Str(e2, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        p1 = expPriority(e1);
        p2 = expPriority(e2);
        s1_1 = parenthesize(s1, p1, p,false);
        s2_1 = parenthesize(s2, p1, p,true);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;
    case ((e as DAE.IFEXP(cond,tb,fb)), _, _, _)
      equation
        cs = printExp2Str(cond, stringDelimiter, opcreffunc, opcallfunc);
        ts = printExp2Str(tb, stringDelimiter, opcreffunc, opcallfunc);
        fs = printExp2Str(fb, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        pc = expPriority(cond);
        pt = expPriority(tb);
        pf = expPriority(fb);
        cs_1 = parenthesize(cs, pc, p,false);
        ts_1 = parenthesize(ts, pt, p,false);
        fs_1 = parenthesize(fs, pf, p,false);
        str = Util.stringAppendList({"if ",cs_1," then ",ts_1," else ",fs_1});
      then
        str;
    case (e as DAE.CALL(path = fcn,expLst = args), _, _, SOME(pcallfunc))
      equation
        s_2 = pcallfunc(e,stringDelimiter,opcreffunc);
      then
        s_2;        
    case (e as DAE.CALL(path = fcn,expLst = args), _, _, _)
      equation
        fs = Absyn.pathString(fcn);
        argstr = Util.stringDelimitList(
          Util.listMap3(args, printExp2Str, stringDelimiter, opcreffunc, opcallfunc), ",");
        s = stringAppend(fs, "(");
        s_1 = stringAppend(s, argstr);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;

    case (DAE.PARTEVALFUNCTION(path = fcn, expList = args), _, _, _)
      equation
        fs = Absyn.pathString(fcn);
        argstr = Util.stringDelimitList(
          Util.listMap3(args, printExp2Str, stringDelimiter, opcreffunc, opcallfunc), ",");
        s = stringAppend("function ", fs);
        s1 = stringAppend(s, "(");
        s2 = stringAppend(s1, argstr);
        s3 = stringAppend(s2, ")");
      then
        s3;
    case (DAE.ARRAY(array = es,ty=tp), _, _, _)
      local Type tp; String s3;
      equation
        // s3 = typeString(tp); // adrpo: not used!
        s = Util.stringDelimitList(
          Util.listMap3(es, printExp2Str, stringDelimiter, opcreffunc, opcallfunc), ",");
        s_2 = Util.stringAppendList({"{",s,"}"});
      then
        s_2;
    case (DAE.TUPLE(PR = es), _, _, _)
      equation
        s = Util.stringDelimitList(
          Util.listMap3(es, printExp2Str, stringDelimiter, opcreffunc, opcallfunc), ",");
        s_1 = stringAppend("(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;
    case (DAE.MATRIX(scalar = es,ty=tp), _, _, _)
      local list<list<tuple<Exp, Boolean>>> es;
        Type tp; String s3;
      equation
        // s3 = typeString(tp); // adrpo: not used!
        s = Util.stringDelimitList(
          Util.listMap1(es, printRowStr, stringDelimiter), "},{");
        s_2 = Util.stringAppendList({"{{",s,"}}"});
      then
        s_2;
    case (e as DAE.RANGE(_,start,NONE,stop), _, _, _)
      equation
        s1 = printExp2Str(start, stringDelimiter, opcreffunc, opcallfunc);
        s3 = printExp2Str(stop, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        pstart = expPriority(start);
        pstop = expPriority(stop);
        s1_1 = parenthesize(s1, pstart, p,false);
        s3_1 = parenthesize(s3, pstop, p,false);
        s = Util.stringAppendList({s1_1,":",s3_1});
      then
        s;
    case ((e as DAE.RANGE(_,start,SOME(step),stop)), _, _, _)
      equation
        s1 = printExp2Str(start, stringDelimiter, opcreffunc, opcallfunc);
        s2 = printExp2Str(step, stringDelimiter, opcreffunc, opcallfunc);
        s3 = printExp2Str(stop, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        pstart = expPriority(start);
        pstop = expPriority(stop);
        pstep = expPriority(step);
        s1_1 = parenthesize(s1, pstart, p,false);
        s3_1 = parenthesize(s3, pstop, p,false);
        s2_1 = parenthesize(s2, pstep, p,false);
        s = Util.stringAppendList({s1_1,":",s2_1,":",s3_1});
      then
        s;
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = DAE.ICONST(integer = ival)), _, _, _)
      equation
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
      then
        res;
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = DAE.ICONST(integer = ival))), _, _, _)
      equation
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
        res2 = stringAppend("-", res);
      then
        res2;
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e), _, _, _)
      equation
        s = printExp2Str(e, stringDelimiter, opcreffunc, opcallfunc);
        s_2 = Util.stringAppendList({"Real(",s,")"});
      then
        s_2;
    case (DAE.CAST(ty = tp,exp = e), _, _, _)
      equation
        str = typeString(tp);
        s = printExp2Str(e, stringDelimiter, opcreffunc, opcallfunc);
        res = Util.stringAppendList({"DAE.CAST(",str,", ",s,")"});
      then
        res;
    case (e as DAE.ASUB(exp = e1,sub = aexpl), _, _, _)
      local list<Exp> aexpl;
      equation
        p = expPriority(e);
        pe1 = expPriority(e1);
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s1_1 = parenthesize(s1, pe1, p,false);
        s4 = Util.stringDelimitList(
          Util.listMap3(aexpl,printExp2Str, stringDelimiter, opcreffunc, opcallfunc),", ");
        s_4 = s1_1+& "["+& s4 +& "]";
      then
        s_4;
    case (DAE.SIZE(exp = cr,sz = SOME(dim)), _, _, _)
      equation
        crstr = printExp2Str(cr, stringDelimiter, opcreffunc, opcallfunc);
        dimstr = printExp2Str(dim, stringDelimiter, opcreffunc, opcallfunc);
        str = Util.stringAppendList({"size(",crstr,",",dimstr,")"});
      then
        str;
    case (DAE.SIZE(exp = cr,sz = NONE), _, _, _)
      equation
        crstr = printExp2Str(cr, stringDelimiter, opcreffunc, opcallfunc);
        str = Util.stringAppendList({"size(",crstr,")"});
      then
        str;
    case (DAE.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp), _, _, _)
      equation
        fs = Absyn.pathString(fcn);
        expstr = printExp2Str(exp, stringDelimiter, opcreffunc, opcallfunc);
        iterstr = printExp2Str(iterexp, stringDelimiter, opcreffunc, opcallfunc);
        str = Util.stringAppendList({"<reduction>",fs,"(",expstr," for ",id," in ",iterstr,")"});
      then
        str;


      // MetaModelica tuple
    case (DAE.META_TUPLE(es), _, _, _)
      equation
        s = printExp2Str(DAE.TUPLE(es), stringDelimiter, opcreffunc, opcallfunc);
      then
        s;

      // MetaModelica list
    case (DAE.LIST(_,es), _, _, _)
      local list<Exp> es;
      equation
        s = Util.stringDelimitList(
          Util.listMap3(es,printExp2Str, stringDelimiter, opcreffunc, opcallfunc),",");
        s_1 = stringAppend("list(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;

        // MetaModelica list cons
    case (DAE.CONS(_,e1,e2), _, _, _)
      equation
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s2 = printExp2Str(e2, stringDelimiter, opcreffunc, opcallfunc);
        s_2 = Util.stringAppendList({"cons(",s1,",",s2,")"});
      then
        s_2;

        // MetaModelica Option
    case (DAE.META_OPTION(NONE), _, _, _) then "NONE";
    case (DAE.META_OPTION(SOME(e1)), _, _, _)
      equation
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s_1 = Util.stringAppendList({"SOME(",s1,")"});
      then
        s_1;

     // MetaModelica Uniontype Constructor
    case (DAE.METARECORDCALL(path = fcn, args=args), _, _, _)
      equation
        fs = Absyn.pathString(fcn);
        argstr = Util.stringDelimitList(
          Util.listMap3(args,printExp2Str, stringDelimiter, opcreffunc, opcallfunc),",");
        s = stringAppend(fs, "(");
        s_1 = stringAppend(s, argstr);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;

    case (DAE.VALUEBLOCK(_,_,_,_), _, _, _) then "#valueblock#";

    case (e, _, _, _)
      equation
        // debug_print("unknown expression - printExp2Str: ", e);
      then
        "#UNKNOWN EXPRESSION# ----eee ";
  end matchcontinue;
end printExp2Str;

public function parenthesize
"function: parenthesize
  Adds parentheisis to a string if expression
  and parent expression priorities requires it."
  input String inString1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Boolean rightOpParenthesis "true for right hand side operators";
  output String outString;
algorithm
  outString := matchcontinue (inString1,inInteger2,inInteger3,rightOpParenthesis)
    local
      Ident str_1,str;
      Integer pparent,pexpr;
    case (str,pparent,pexpr,rightOpParenthesis) /* expr, prio. parent expr, prio. expr */
      equation
        (pparent > pexpr) = true;
        str_1 = Util.stringAppendList({"(",str,")"});
      then str_1;
    /* If priorites are equal and str is from right hand side, parenthesize to make
          left associative */
    case (str,pparent,pexpr,true)
      equation
        (pparent == pexpr) = true;
        str_1 = Util.stringAppendList({"(",str,")"});
      then
        str_1;
    case (str,_,_,_) then str;
  end matchcontinue;
end parenthesize;


public function expPriority
"function: expPriority
 Returns a priority number for an expression.
 This function is used to output parenthesis
 when needed, e.g., 3(1+2) should output 3(1+2)
 and not 31+2."
  input Exp inExp;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inExp)
    case (DAE.ICONST(_)) then 0;
    case (DAE.RCONST(_)) then 0;
    case (DAE.SCONST(_)) then 0;
    case (DAE.BCONST(_)) then 0;
    case (DAE.ENUM_LITERAL(name = _)) then 0;
    case (DAE.CREF(_,_)) then 0;
    case (DAE.ASUB(_,_)) then 0;
    case (DAE.END()) then 0;
    case (DAE.CAST(_,_)) then 0;
    case (DAE.CALL(path=_)) then 0;
    case (DAE.PARTEVALFUNCTION(path=_)) then 0;
    case (DAE.ARRAY(ty = _)) then 0;
    case (DAE.MATRIX(ty= _)) then 0;
    case (DAE.BINARY(operator = DAE.POW(_))) then 1;
    case (DAE.BINARY(operator = DAE.POW_ARR(_))) then 1;
    case (DAE.BINARY(operator = DAE.POW_ARR2(_))) then 1;
    case (DAE.BINARY(operator = DAE.POW_SCALAR_ARRAY(_))) then 1;
    case (DAE.BINARY(operator = DAE.POW_ARRAY_SCALAR(_))) then 1;
    case (DAE.BINARY(operator = DAE.DIV(_))) then 2;
    case (DAE.BINARY(operator = DAE.DIV_ARR(_))) then 2;
    case (DAE.BINARY(operator = DAE.DIV_SCALAR_ARRAY(_))) then 2;
    case (DAE.BINARY(operator = DAE.DIV_ARRAY_SCALAR(_))) then 2;
    case (DAE.BINARY(operator = DAE.MUL(_))) then 3;
    case (DAE.BINARY(operator = DAE.MUL_ARR(_))) then 3;
    case (DAE.BINARY(operator = DAE.MUL_SCALAR_ARRAY(_))) then 3;
    case (DAE.BINARY(operator = DAE.MUL_ARRAY_SCALAR(_))) then 3;
    case (DAE.BINARY(operator = DAE.ADD_SCALAR_ARRAY(_))) then 5;
    case (DAE.BINARY(operator = DAE.ADD_ARRAY_SCALAR(_))) then 5;
    case (DAE.BINARY(operator = DAE.SUB_SCALAR_ARRAY(_))) then 5;
    case (DAE.BINARY(operator = DAE.SUB_ARRAY_SCALAR(_))) then 5;
    case (DAE.BINARY(operator = DAE.MUL_SCALAR_PRODUCT(_))) then 3;
    case (DAE.BINARY(operator = DAE.MUL_MATRIX_PRODUCT(_))) then 3;
    case (DAE.UNARY(operator = DAE.UPLUS(_))) then 6;
    case (DAE.UNARY(operator = DAE.UMINUS(_))) then 6;
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(_))) then 6;
    case (DAE.UNARY(operator = DAE.UPLUS_ARR(_))) then 6;
    case (DAE.BINARY(operator = DAE.ADD(_))) then 5;
    case (DAE.BINARY(operator = DAE.ADD_ARR(_))) then 5;
    case (DAE.BINARY(operator = DAE.SUB(_))) then 5;
    case (DAE.BINARY(operator = DAE.SUB_ARR(_))) then 5;
    case (DAE.RELATION(operator = DAE.LESS(_))) then 6;
    case (DAE.RELATION(operator = DAE.LESSEQ(_))) then 6;
    case (DAE.RELATION(operator = DAE.GREATER(_))) then 6;
    case (DAE.RELATION(operator = DAE.GREATEREQ(_))) then 6;
    case (DAE.RELATION(operator = DAE.EQUAL(_))) then 6;
    case (DAE.RELATION(operator = DAE.NEQUAL(_))) then 6;
    case (DAE.LUNARY(operator = DAE.NOT())) then 7;
    case (DAE.LBINARY(operator = DAE.AND())) then 8;
    case (DAE.LBINARY(operator = DAE.OR())) then 9;
    case (DAE.RANGE(ty = _)) then 10;
    case (DAE.IFEXP(expCond = _)) then 11;
    case (DAE.TUPLE(_)) then 12;  /* Not valid in inner expressions, only included here for completeness */
    case (_) then 13;
  end matchcontinue;
end expPriority;


public function printRowStr
"function: printRowStr
  Prints a list of expressions to a string."
  input list<tuple<Exp, Boolean>> es;
  input String stringDelimiter;
  output String s;
  list<Exp> es_1;
algorithm
  es_1 := Util.listMap(es, Util.tuple21);
  s := Util.stringDelimitList(
    Util.listMap3(es_1, printExp2Str, stringDelimiter, NONE(), NONE()), ",");
end printRowStr;

public function printLeftparStr
"function: printLeftparStr
  Print a left parenthesis to a string if priorities require it."
  input Integer inInteger1;
  input Integer inInteger2;
  output String outString;
  output Integer outInteger;
algorithm
  (outString,outInteger):=
  matchcontinue (inInteger1,inInteger2)
    local Integer x,y,pri1,pri2;
    case (x,y) /* prio1 prio2 */
      equation
        (x > y) = true;
      then
        ("(",0);
    case (pri1,pri2) then ("",pri2);
  end matchcontinue;
end printLeftparStr;

public function printRightparStr
"function: printRightparStr
  Print a right parenthesis to a
 string if priorities require it."
  input Integer inInteger1;
  input Integer inInteger2;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger1,inInteger2)
    local Integer x,y;
    case (x,y)
      equation
        (x > y) = true;
      then
        ")";
    case (_,_) then "";
  end matchcontinue;
end printRightparStr;

public function expEqual
"function: expEqual
  Returns true if the two expressions are equal."
  input Exp inExp1;
  input Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp1,inExp2)
    local
      Integer c1,c2,i1,i2;
      Ident id1,id2;
      Boolean b1,c1_1,c2_1,b2,res,b3;
      Exp e11,e12,e21,e22,e1,e2,e13,e23,r1,r2;
      Operator op1,op2;
      list<Boolean> bs;
      Absyn.Path path1,path2;
      list<Exp> expl1,expl2;
      Type tp1,tp2;
    
    // check for pointer equality first, if they point to the same thing, they are equal
    case (inExp1,inExp2)
      equation
        true = System.refEqual(inExp1,inExp2);
      then
        true;    
    
    // integers
    case (DAE.ICONST(integer = c1),DAE.ICONST(integer = c2)) then (c1 == c2);
    // reals
    case (DAE.RCONST(real = c1),DAE.RCONST(real = c2))
      local Real c1,c2;
      then
        (c1 ==. c2);
    // strings
    case (DAE.SCONST(string = c1),DAE.SCONST(string = c2))
      local Ident c1,c2;
      equation
        true = stringEqual(c1, c2);
      then
        true;
    // booleans
    case (DAE.BCONST(bool = c1),DAE.BCONST(bool = c2))
      local Boolean c1,c2;
      equation
        res = Util.boolEqual(c1, c2);
      then
        res;
    // enumeration literals
    case (DAE.ENUM_LITERAL(name = enum1), DAE.ENUM_LITERAL(name = enum2))
      local Absyn.Path enum1, enum2;
      equation
        res = Absyn.pathEqual(enum1, enum2);
      then
        res;
    // crefs
    case (DAE.CREF(componentRef = c1),DAE.CREF(componentRef = c2))
      local ComponentRef c1,c2;
      equation
        res = crefEqual(c1, c2);
      then
        res;
    // binary ops
    case (DAE.BINARY(exp1 = e11,operator = op1,exp2 = e12),DAE.BINARY(exp1 = e21,operator = op2,exp2 = e22))
      equation
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // logical binary ops
    case (DAE.LBINARY(exp1 = e11,operator = op1,exp2 = e12),
          DAE.LBINARY(exp1 = e21,operator = op2,exp2 = e22))
      equation
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // unary ops
    case (DAE.UNARY(operator = op1,exp = e1),DAE.UNARY(operator = op2,exp = e2))
      equation
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e1, e2);
        res = boolAnd(b1, b2);
      then
        res;
    // logical binary ops
    case (DAE.LUNARY(operator = op1,exp = e1),DAE.LUNARY(operator = op2,exp = e2))
      equation
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e1, e2);
        res = boolAnd(b1, b2);
      then
        res;
    // relational ops
    case (DAE.RELATION(exp1 = e11,operator = op1,exp2 = e12),DAE.RELATION(exp1 = e21,operator = op2,exp2 = e22))
      equation
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // if expressions
    case (DAE.IFEXP(expCond = e11,expThen = e12,expElse = e13),DAE.IFEXP(expCond = e21,expThen = e22,expElse = e23))
      equation
        b1 = expEqual(e13, e23);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // function calls
    case (DAE.CALL(path = path1,expLst = expl1),DAE.CALL(path = path2,expLst = expl2))
      equation
        b1 = ModUtil.pathEqual(path1, path2);
        bs = Util.listThreadMap(expl1, expl2, expEqual);
        res = Util.boolAndList((b1 :: bs));
      then
        res;
    // partially evaluated functions
    case (DAE.PARTEVALFUNCTION(path = path1,expList = expl1),DAE.PARTEVALFUNCTION(path = path2,expList = expl2))
      equation
        b1 = ModUtil.pathEqual(path1, path2);
        bs = Util.listThreadMap(expl1, expl2, expEqual);
        res = Util.boolAndList((b1 :: bs));
      then
        res;
    // arrays
    case (DAE.ARRAY(ty = tp1,array = expl1),DAE.ARRAY(ty = tp2,array = expl2))
      equation
        equality(tp1 = tp2);
        bs = Util.listThreadMap(expl1, expl2, expEqual);
        res = Util.boolAndList(bs);
      then
        res;
    // matrix
    case (e1 as DAE.MATRIX(ty = _), e2 as DAE.MATRIX(ty = _))
      equation
        equality(e1 = e2); // TODO! FIXME! should use expEqual on elements
      then
        true;
    case (e1 as DAE.MATRIX(ty = _), e2 as DAE.MATRIX(ty = _))
      equation
        failure(equality(e1 = e2)); // TODO! FIXME! should use expEqual on elements
      then
        false;
    // ranges [start:stop]
    case (DAE.RANGE(ty = tp1,exp = e11,expOption = NONE,range = e13),DAE.RANGE(ty = tp2,exp = e21,expOption = NONE,range = e23))
      equation
        b1 = expEqual(e13, e23);
        b2 = expEqual(e11, e21);
        res = Util.boolAndList({b1,b2});
      then
        res;
    // ranges [start:step:stop]
    case (DAE.RANGE(ty = tp1,exp = e11,expOption = SOME(e12),range = e13),DAE.RANGE(ty = tp2,exp = e21,expOption = SOME(e22),range = e23))
      equation
        b1 = expEqual(e13, e23);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // tuples
    case (DAE.TUPLE(PR = expl1),DAE.TUPLE(PR = expl2))
      equation
        bs = Util.listThreadMap(expl1, expl2, expEqual);
        res = Util.boolAndList(bs);
      then
        res;
    // casting
    case (DAE.CAST(ty = tp1,exp = e1),DAE.CAST(ty = tp2,exp = e2))
      equation
        equality(tp1 = tp2);
        res = expEqual(e1, e2);
      then
        res;
    // array subscripts
    case (DAE.ASUB(exp = e1,sub = ae1),DAE.ASUB(exp = e2,sub = ae2))
      local
        list<Exp> ae1,ae2;
      equation
        bs = Util.listThreadMap(ae1, ae2, expEqual);
        res = Util.boolAndList(bs);
        b2 = expEqual(e1, e2);
        res = boolAnd(res, b2);
      then
        res;
    // size(a)
    case (DAE.SIZE(exp = e1,sz = NONE),DAE.SIZE(exp = e2,sz = NONE))
      equation
        res = expEqual(e1, e2);
      then
        res;
    // size(a, dim)
    case (DAE.SIZE(exp = e1,sz = SOME(e11)),DAE.SIZE(exp = e2,sz = SOME(e22)))
      equation
        b1 = expEqual(e1, e2);
        b2 = expEqual(e11, e22);
        res = boolAnd(b1, b2);
      then
        res;
    // metamodeling code
    case (DAE.CODE(code = _),DAE.CODE(code = _))
      equation
        Debug.fprint("failtrace","exp_equal on CODE not impl.\n");
      then
        false;
    case (DAE.REDUCTION(path = path1,expr = e1,ident = id1,range = r1),DAE.REDUCTION(path = path2,expr = e2,ident = id2,range = r2))
      equation
        true = stringEqual(id1, id2);
        b1 = ModUtil.pathEqual(path1, path2);
        b2 = expEqual(e1, e2);
        b3 = expEqual(r1, r2);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // end id
    case (DAE.END(),DAE.END()) then true;
    /*// everything else failed, try structural equality
    case (e1,e2)
      equation
        equality(e1 = e2); 
      then true;
    case (e1,e2)
      equation
        failure(equality(e1 = e2)); 
      then false;
    */
    // not equal        
    case (_,_) then false;
  end matchcontinue;
end expEqual;

public function operatorDivOrMul "returns true if operator is division or multiplication"
  input  Operator op;
  output Boolean res;
algorithm
  res := matchcontinue(op)
    case(DAE.MUL(_)) then true;
    case(DAE.DIV(_)) then true;
    case (_) then false;
  end matchcontinue;
end operatorDivOrMul;

protected function operatorEqual
"function: operatorEqual
  Helper function to expEqual."
  input Operator inOperator1;
  input Operator inOperator2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inOperator1,inOperator2)
    local
      Boolean res;
      Absyn.Path p1,p2;
    case (DAE.ADD(ty = _),DAE.ADD(ty = _)) then true;
    case (DAE.SUB(ty = _),DAE.SUB(ty = _)) then true;
    case (DAE.MUL(ty = _),DAE.MUL(ty = _)) then true;
    case (DAE.DIV(ty = _),DAE.DIV(ty = _)) then true;
    case (DAE.POW(ty = _),DAE.POW(ty = _)) then true;
    case (DAE.UMINUS(ty = _),DAE.UMINUS(ty = _)) then true;
    case (DAE.UMINUS_ARR(ty = _),DAE.UMINUS_ARR(ty = _)) then true;
    case (DAE.UPLUS_ARR(ty = _),DAE.UPLUS_ARR(ty = _)) then true;
    case (DAE.ADD_ARR(ty = _),DAE.ADD_ARR(ty = _)) then true;
    case (DAE.SUB_ARR(ty = _),DAE.SUB_ARR(ty = _)) then true;
    case (DAE.MUL_ARR(ty = _),DAE.MUL_ARR(ty = _)) then true;
    case (DAE.DIV_ARR(ty = _),DAE.DIV_ARR(ty = _)) then true;
    case (DAE.MUL_SCALAR_ARRAY(ty = _),DAE.MUL_SCALAR_ARRAY(ty = _)) then true;
    case (DAE.MUL_ARRAY_SCALAR(ty = _),DAE.MUL_ARRAY_SCALAR(ty = _)) then true;
    case (DAE.ADD_SCALAR_ARRAY(ty = _),DAE.ADD_SCALAR_ARRAY(ty = _)) then true;
    case (DAE.ADD_ARRAY_SCALAR(ty = _),DAE.ADD_ARRAY_SCALAR(ty = _)) then true;
    case (DAE.SUB_SCALAR_ARRAY(ty = _),DAE.SUB_SCALAR_ARRAY(ty = _)) then true;
    case (DAE.SUB_ARRAY_SCALAR(ty = _),DAE.SUB_ARRAY_SCALAR(ty = _)) then true;
    case (DAE.MUL_SCALAR_PRODUCT(ty = _),DAE.MUL_SCALAR_PRODUCT(ty = _)) then true;
    case (DAE.MUL_MATRIX_PRODUCT(ty = _),DAE.MUL_MATRIX_PRODUCT(ty = _)) then true;
    case (DAE.DIV_SCALAR_ARRAY(ty = _),DAE.DIV_SCALAR_ARRAY(ty = _)) then true;
    case (DAE.DIV_ARRAY_SCALAR(ty = _),DAE.DIV_ARRAY_SCALAR(ty = _)) then true;
    case (DAE.POW_SCALAR_ARRAY(ty = _),DAE.POW_SCALAR_ARRAY(ty = _)) then true;
    case (DAE.POW_ARRAY_SCALAR(ty = _),DAE.POW_ARRAY_SCALAR(ty = _)) then true;
    case (DAE.POW_ARR(ty = _),DAE.POW_ARR(ty = _)) then true;
    case (DAE.POW_ARR2(ty = _),DAE.POW_ARR2(ty = _)) then true;
    case (DAE.AND(),DAE.AND()) then true;
    case (DAE.OR(),DAE.OR()) then true;
    case (DAE.NOT(),DAE.NOT()) then true;
    case (DAE.LESS(ty = _),DAE.LESS(ty = _)) then true;
    case (DAE.LESSEQ(ty = _),DAE.LESSEQ(ty = _)) then true;
    case (DAE.GREATER(ty = _),DAE.GREATER(ty = _)) then true;
    case (DAE.GREATEREQ(ty = _),DAE.GREATEREQ(ty = _)) then true;
    case (DAE.EQUAL(ty = _),DAE.EQUAL(ty = _)) then true;
    case (DAE.NEQUAL(ty = _),DAE.NEQUAL(ty = _)) then true;
    case (DAE.USERDEFINED(fqName = p1),DAE.USERDEFINED(fqName = p2))
      equation
        res = ModUtil.pathEqual(p1, p2);
      then
        res;
    case (_,_) then false;
  end matchcontinue;
end operatorEqual;

public function replaceExpListOpt
"similar to replaceExpList. But with Option<Exp> instead of Exp."
  input Option<Exp> inExp1;
  input list<Exp> s;
  input list<Exp> t;
  output Option<Exp> outExp;
  output Integer outInteger;
algorithm
  (outExp,outInteger) := matchcontinue (inExp1,s,t)
    local Exp e;
    case (NONE(),_,_) then (NONE(),0);
    case (SOME(e),s,t) equation
      (e,outInteger) = replaceExpList(e,s,t);
     then (SOME(e),outInteger);
  end matchcontinue;
end replaceExpListOpt;

public function replaceListExp
"function: replaceListExp.
  Replaces an list of expressions with a expression."
  input list<Exp> inExpLst;
  input Exp inExp2;
  input Exp inExp3;
  output list<Exp> outExpLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpLst,outIntegerLst) := matchcontinue (inExpLst,inExp2,inExp3)
    local
      Exp e,e1,e2,e3;
      Integer c;
      list<Exp> rest,explst;
      list<Integer> intlst;
    case ({},_,_) then ({},{});  
    case (e::rest,e2,e3)
      equation
        (e1,c) = replaceExp(e, e2, e3);
        (explst,intlst) = replaceListExp(rest,e2,e3);
      then
        (e1::explst,c::intlst);
  end matchcontinue;
end replaceListExp;

public function replaceExpList
"function: replaceExpList.
  Replaces an expression with a list of several expressions.
  NOTE: Not repreteadly applied, so the source and target
        lists must be disjunct
  Useful for instance when replacing several
  variables at once in an expression."
  input Exp inExp1;
  input list<Exp> inExpLst2;
  input list<Exp> inExpLst3;
  output Exp outExp;
  output Integer outInteger;
algorithm
  (outExp,outInteger) := matchcontinue (inExp1,inExpLst2,inExpLst3)
    local
      Exp e,e_1,e_2,s1,t1;
      Integer c1,c2,c;
      list<Exp> sr,tr;
    case (e,{},{}) then (e,0);  /* expr, source list, target list */
    case (e,(s1 :: sr),(t1 :: tr))
      equation
        (e_1,c1) = replaceExp(e, s1, t1);
        (e_2,c2) = replaceExpList(e_1, sr, tr);
        c = c1 + c2;
      then
        (e_2,c);
  end matchcontinue;
end replaceExpList;

public function replaceExp
"function: replaceExp
  Helper function to replaceExpList."
  input Exp inExp1;
  input Exp inExp2;
  input Exp inExp3;
  output Exp outExp;
  output Integer outInteger;
algorithm
  (outExp,outInteger) := matchcontinue (inExp1,inExp2,inExp3)
    local
      Exp expr,source,target,e1_1,e2_1,e1,e2,e3_1,e3,e_1,r_1,e,r,s;
      Integer c1,c2,c,c3,cnt_1,b,i;
      Operator op;
      list<Exp> expl_1,expl;
      list<Integer> cnt;
      Absyn.Path path,p;
      Boolean t;
      Type tp,ety;
      Absyn.CodeNode a;
      Ident id;
      ComponentRef cr;
      list<Subscript> subs;

    case (expr,source,target) /* expr source expr target expr */
      equation
        true = expEqual(expr, source);
      then
        (target,1);
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (DAE.BINARY(e1_1,op,e2_1),c);
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (DAE.LBINARY(e1_1,op,e2_1),c);
    case (DAE.UNARY(operator = op,exp = e1),source,target)
      equation
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (DAE.UNARY(op,e1_1),c);
    case (DAE.LUNARY(operator = op,exp = e1),source,target)
      equation
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (DAE.LUNARY(op,e1_1),c);
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (DAE.RELATION(e1_1,op,e2_1),c);
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        (e3_1,c3) = replaceExp(e3, source, target);
        c = Util.listReduce({c1,c2,c3}, int_add);
      then
        (DAE.IFEXP(e1_1,e2_1,e3_1),c);
    case (DAE.CALL(path = path,expLst = expl,tuple_ = t,builtin = c,ty=tp,inlineType=i),source,target)
      local Boolean c;DAE.InlineType i; Type tp;
      equation
        (expl_1,cnt) = Util.listMap22(expl, replaceExp, source, target);
        cnt_1 = Util.listReduce(cnt, int_add);
      then
        (DAE.CALL(path,expl_1,t,c,tp,i),cnt_1);
    case(DAE.PARTEVALFUNCTION(path = path, expList = expl, ty = tp),source,target)
      local Type tp;
      equation
        (expl_1,cnt) = Util.listMap22(expl, replaceExp, source, target);
        cnt_1 = Util.listReduce(cnt, int_add);
      then
        (DAE.PARTEVALFUNCTION(path,expl_1,tp),cnt_1);
    case (DAE.ARRAY(ty = tp,scalar = c,array = expl),source,target)
      local Boolean c;
      equation
        (expl_1,cnt) = Util.listMap22(expl, replaceExp, source, target);
        cnt_1 = Util.listReduce(cnt, int_add);
      then
        (DAE.ARRAY(tp,c,expl_1),cnt_1);
    case (DAE.MATRIX(ty = t,integer = b,scalar = expl),source,target)
      local
        list<list<tuple<Exp, Boolean>>> expl_1,expl;
        Integer cnt;
        Type t;
      equation
        (expl_1,cnt) = replaceExpMatrix(expl, source, target);
      then
        (DAE.MATRIX(t,b,expl_1),cnt);
    case (DAE.RANGE(ty = tp,exp = e1,expOption = NONE,range = e2),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (DAE.RANGE(tp,e1_1,NONE,e2_1),c);
    case (DAE.RANGE(ty = tp,exp = e1,expOption = SOME(e3),range = e2),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        (e3_1,c3) = replaceExp(e3, source, target);
        c = Util.listReduce({c1,c2,c3}, int_add);
      then
        (DAE.RANGE(tp,e1_1,SOME(e3_1),e2_1),c);
    case (DAE.TUPLE(PR = expl),source,target)
      equation
        (expl_1,cnt) = Util.listMap22(expl, replaceExp, source, target);
        cnt_1 = Util.listReduce(cnt, int_add);
      then
        (DAE.TUPLE(expl_1),cnt_1);
    case (DAE.CAST(ty = tp,exp = e1),source,target)
      equation
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (DAE.CAST(tp,e1_1),c);

    case (DAE.ASUB(exp = e1,sub = ae1),source,target)
      local list<Exp> ae1;
      equation
        (e1_1,c) = replaceExp(e1, source, target);
        (expl_1,cnt) = Util.listMap22(ae1, replaceExp, source, target);
        cnt_1 = Util.listReduce(cnt, int_add);
        c = c+cnt_1;
      then
        (DAE.ASUB(e1_1,expl_1),c);

    case (DAE.SIZE(exp = e1,sz = NONE),source,target)
      equation
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (DAE.SIZE(e1_1,NONE),c);
    case (DAE.SIZE(exp = e1,sz = SOME(e2)),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (DAE.SIZE(e1_1,SOME(e2_1)),c);
    case (DAE.CODE(code = a,ty = b),source,target)
      local Type b;
      equation
        Debug.fprint("failtrace","-Exp.replaceExp on CODE not implemented.\n");
      then
        (DAE.CODE(a,b),0);
    case (DAE.REDUCTION(path = p,expr = e,ident = id,range = r),source,target)
      equation
        (e_1,c1) = replaceExp(e, source, target);
        (r_1,c2) = replaceExp(r, source, target);
        c = c1 + c2;
      then
        (DAE.REDUCTION(p,e_1,id,r_1),c);
    // qualified componentreferences, replace subscripts
    case(DAE.CREF(DAE.CREF_QUAL(id,tp,subs,cr),ety),source,target) equation
      (subs,c1) = replaceExpSubs(subs,source,target);
      (DAE.CREF(cr,_),c2) = replaceCrefExpSubs(DAE.CREF(cr,ety),source,target);
       // (DAE.CREF(cr,_),c2) = replaceExp(DAE.CREF(cr,ety),source,target);
      c = c1+c2;
    then (DAE.CREF(DAE.CREF_QUAL(id,tp,subs,cr),ety),c1);

    // simple componentreference, replace subscripts
    case(DAE.CREF(DAE.CREF_IDENT(id,tp,subs),ety),source,target) equation
      (subs,c1) = replaceExpSubs(subs,source,target);
    then (DAE.CREF(DAE.CREF_IDENT(id,tp,subs),ety),c1);

    case(DAE.CREF(cr as DAE.CREF_IDENT(id,t2,ssl),ety),_,_)
      local
        Type ety,t2;
        ComponentRef cr,cr_1;
        String name,id;
        list<Subscript> ssl;
      equation
        false = crefHasScalarSubscripts(cr);
        name = printComponentRefStr(cr);
        false = Util.stringContainsChar(name,"$");
        id = Util.stringAppendList({"$",id});
        id = Util.stringReplaceChar(id,".","$p");
      then
        (DAE.CREF(DAE.CREF_IDENT(id,t2,ssl),ety),1);
    // no replacement
    case (e,s,_) then (e,0);
  end matchcontinue;
end replaceExp;

protected function replaceCrefExpSubs
"function: replaceCrefExpSubs
help function to replaceExp. replaces expressions in subscript list
from all Crefs.
"
  input Exp inExp1;
  input Exp inExp2;
  input Exp inExp3;
  output Exp outExp;
  output Integer outInteger;
algorithm
  (outExp,outInteger) := matchcontinue (inExp1,inExp2,inExp3)
    local
      Exp source,target;
      Integer c1,c2,c;
      Operator op;
      Type tp,ety;
      Ident id;
      ComponentRef cr;
      list<Subscript> subs;
    
    case(DAE.CREF(DAE.CREF_QUAL(id,tp,subs,cr),ety),source,target) 
      equation
        (subs,c1) = replaceExpSubs(subs,source,target);
        (DAE.CREF(cr,_),c2) = replaceCrefExpSubs(DAE.CREF(cr,ety),source,target);
        c = c1+c2;
      then 
        (DAE.CREF(DAE.CREF_QUAL(id,tp,subs,cr),ety),c);

    // simple componentreference, replace subscripts
    case(DAE.CREF(DAE.CREF_IDENT(id,tp,subs),ety),source,target) 
      equation
        (subs,c1) = replaceExpSubs(subs,source,target);
      then 
        (DAE.CREF(DAE.CREF_IDENT(id,tp,subs),ety),c1);
  end matchcontinue;
end replaceCrefExpSubs;

protected function replaceExpSubs
"function: replaceExpSubs
help function to replaceExp. replaces expressions in subscript list
"
  input list<Subscript> subs;
  input Exp source;
  input Exp target;
  output list<Subscript> outSubs;
  output Integer cnt;
algorithm
  (outSubs,cnt) := matchcontinue(subs,source,target)
    local Exp e; Integer cnt1,cnt2;
    // empty list
    case({},_,_) then ({},0);
    // WHOLEDIM == ':' 
    case(DAE.WHOLEDIM()::subs,source,target) 
      equation
        (subs,cnt) = replaceExpSubs(subs,source,target);
      then 
        (DAE.WHOLEDIM()::subs,cnt);

    // slices e.g. a[{1,5,7}]
    case(DAE.SLICE(e)::subs,source,target) 
      equation
        (e,cnt1) = replaceExp(e,source,target);
        (subs,cnt2) = replaceExpSubs(subs,source,target);
        cnt = cnt1 + cnt2;
      then 
        (DAE.SLICE(e)::subs,cnt);

    // index, e.g. a[i+1]
    case(DAE.INDEX(e)::subs,source,target) 
      equation
        (e,cnt1) = replaceExp(e,source,target);
        (subs,cnt2) = replaceExpSubs(subs,source,target);
        cnt = cnt1 + cnt2;
      then 
        (DAE.INDEX(e)::subs,cnt);
  end matchcontinue;
end replaceExpSubs;

protected function replaceExpMatrix
"function: replaceExpMatrix
  author: PA
  Helper function to replaceExp,
  traverses Matrix expression list."
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst1;
  input Exp inExp2;
  input Exp inExp3;
  output list<list<tuple<Exp, Boolean>>> outTplExpBooleanLstLst;
  output Integer outInteger;
algorithm
  (outTplExpBooleanLstLst,outInteger) := matchcontinue (inTplExpBooleanLstLst1,inExp2,inExp3)
    local
      Exp str,dst,src;
      list<tuple<Exp, Boolean>> e_1,e;
      Integer c1,c2,c;
      list<list<tuple<Exp, Boolean>>> es_1,es;
    // empty list
    case ({},str,dst) then ({},0);
    // head :: rest
    case ((e :: es),src,dst)
      equation
        (e_1,c1) = replaceExpMatrix2(e, src, dst);
        (es_1,c2) = replaceExpMatrix(es, src, dst);
        c = c1 + c2;
      then
        ((e_1 :: es_1),c);
    // failure
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "- Exp.replaceExpMatrix failed\n");
      then
        fail();
  end matchcontinue;
end replaceExpMatrix;

protected function replaceExpMatrix2
"function: replaceExpMatrix2
  author: PA
  Helper function to replaceExpMatrix"
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst1;
  input Exp inExp2;
  input Exp inExp3;
  output list<tuple<Exp, Boolean>> outTplExpBooleanLst;
  output Integer outInteger;
algorithm
  (outTplExpBooleanLst,outInteger) := matchcontinue (inTplExpBooleanLst1,inExp2,inExp3)
    local
      list<tuple<Exp, Boolean>> es_1,es;
      Integer c1,c2,c;
      Exp e_1,e,src,dst;
      Boolean b;
    case ({},_,_) then ({},0);
    case (((e,b) :: es),src,dst)
      equation
        (es_1,c1) = replaceExpMatrix2(es, src, dst);
        (e_1,c2) = replaceExp(e, src, dst);
        c = c1 + c2;
      then
        (((e_1,b) :: es_1),c);
  end matchcontinue;
end replaceExpMatrix2;

public function crefIsFirstArrayElt
"function: crefIsFirstArrayElt
  This function returns true for component references that
  are arrays and references the first element of the array.
  like for instance a.b{1,1} and a{1} returns true but
  a.b{1,2} or a{2} returns false."
  input ComponentRef inComponentRef;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef)
    local
      list<Subscript> subs;
      list<Exp> exps;
      list<Boolean> bools;
      ComponentRef cr;
    case (cr)
      equation
        ((subs as (_ :: _))) = crefLastSubs(cr);
        exps = Util.listMap(subs, subscriptExp);
        bools = Util.listMap(exps, isOne);
        true = Util.boolAndList(bools);
      then
        true;
    case (_) then false;
  end matchcontinue;
end crefIsFirstArrayElt;

public function stringifyComponentRef
"function: stringifyComponentRef
  Translates a ComponentRef into a DAE.CREF_IDENT by putting
  the string representation of the ComponentRef into it.
  See also stringigyCrefs.

  NOTE: This function should not be used in OMC, since the OMC backend no longer
    uses stringified components. It is still used by MathCore though."
  input ComponentRef cr;
  output ComponentRef outComponentRef;
  list<Subscript> subs;
  ComponentRef cr_1;
  Ident crs;
  Type ty;
algorithm
  subs := crefLastSubs(cr);
  cr_1 := crefStripLastSubs(cr);
  crs := printComponentRefStr(cr_1);
  ty := crefLastType(cr) "The type of the stringified cr is taken from the last identifier";
  outComponentRef := DAE.CREF_IDENT(crs,ty,subs);
end stringifyComponentRef;

public function stringifyCrefs
"function: stringifyCrefs
  This function takes an expression and transforms all component
  reference  names contained in the expression to a simpler form.
  For instance DAE.CREF_QUAL(\"a\",{}, DAE.CREF_IDENT(\"b\",{})) becomes
  DAE.CREF_IDENT(\"a.b\",{})

  NOTE: This function should not be used in OMC, since the OMC backend no longer
    uses stringified components. It is still used by MathCore though."
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
    local
      Exp e,e1_1,e2_1,e1,e2,e_1,e3_1,e3;
      ComponentRef cr_1,cr;
      Type t;
      Operator op;
      list<Exp> expl_1,expl;
      Absyn.Path p;
      Boolean b;
      Integer i;
      Ident id;
    case ((e as DAE.ICONST(integer = _))) then e;
    case ((e as DAE.RCONST(real = _))) then e;
    case ((e as DAE.SCONST(string = _))) then e;
    case ((e as DAE.BCONST(bool = _))) then e;
    case ((e as DAE.CREF(ty = DAE.ET_FUNCTION_REFERENCE_VAR))) then e;
    case ((e as DAE.CREF(ty = DAE.ET_FUNCTION_REFERENCE_FUNC(builtin = _)))) then e;
    case (DAE.CREF(componentRef = cr,ty = t))
      equation
        cr_1 = stringifyComponentRef(cr);
      then
        DAE.CREF(cr_1,t);
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
      then
        DAE.BINARY(e1_1,op,e2_1);
    case (DAE.UNARY(operator = op,exp = e))
      equation
        e_1 = stringifyCrefs(e);
      then
        DAE.UNARY(op,e_1);
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
      then
        DAE.LBINARY(e1_1,op,e2_1);
    case (DAE.LUNARY(operator = op,exp = e))
      equation
        e_1 = stringifyCrefs(e);
      then
        DAE.LUNARY(op,e_1);
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
      then
        DAE.RELATION(e1_1,op,e2_1);
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
        e3_1 = stringifyCrefs(e3);
      then
        DAE.IFEXP(e1_1,e2_1,e3_1);
    case (DAE.CALL(path = p,expLst = expl,tuple_ = t,builtin = b,ty=tp,inlineType=i))
      local Boolean t;DAE.InlineType i; Type tp;
      equation
        expl_1 = Util.listMap(expl, stringifyCrefs);
      then
        DAE.CALL(p,expl_1,t,b,tp,i);
    case (DAE.PARTEVALFUNCTION(path = p, expList = expl, ty = tp))
      local Type tp;
      equation
        expl_1 = Util.listMap(expl, stringifyCrefs);
      then
        DAE.PARTEVALFUNCTION(p,expl_1,tp);
    case (DAE.ARRAY(ty = t,scalar = b,array = expl))
      equation
        expl_1 = Util.listMap(expl, stringifyCrefs);
      then
        DAE.ARRAY(t,b,expl_1);
    case ((e as DAE.MATRIX(ty = t,integer = b,scalar = expl)))
      local
        list<list<tuple<Exp, Boolean>>> expl_1,expl;
        Integer b;
      equation
        expl_1 = stringifyCrefsMatrix(expl);
      then
        DAE.MATRIX(t,b,expl_1);
    case (DAE.RANGE(ty = t,exp = e1,expOption = SOME(e2),range = e3))
      equation
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
        e3_1 = stringifyCrefs(e3);
      then
        DAE.RANGE(t,e1_1,SOME(e2_1),e3_1);
    case (DAE.RANGE(ty = t,exp = e1,expOption = NONE,range = e3))
      equation
        e1_1 = stringifyCrefs(e1);
        e3_1 = stringifyCrefs(e3);
      then
        DAE.RANGE(t,e1_1,NONE,e3_1);
    case (DAE.TUPLE(PR = expl))
      equation
        expl_1 = Util.listMap(expl, stringifyCrefs);
      then
        DAE.TUPLE(expl_1);
    case (DAE.CAST(ty = t,exp = e1))
      equation
        e1_1 = stringifyCrefs(e1);
      then
        DAE.CAST(t,e1_1);
    case (DAE.ASUB(exp = e1,sub = expl_1))
      equation
        e1_1 = stringifyCrefs(e1);
      then
        DAE.ASUB(e1_1,expl_1);
    case (DAE.SIZE(exp = e1,sz = SOME(e2)))
      equation
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
      then
        DAE.SIZE(e1_1,SOME(e2_1));
    case (DAE.SIZE(exp = e1,sz = NONE))
      equation
        e1_1 = stringifyCrefs(e1);
      then
        DAE.SIZE(e1_1,NONE);
    case ((e as DAE.CODE(code = _))) then e;
    case (DAE.REDUCTION(path = p,expr = e1,ident = id,range = e2))
      equation
        e1_1 = stringifyCrefs(e1);
        e2_1 = stringifyCrefs(e2);
      then
        DAE.REDUCTION(p,e1_1,id,e2_1);
    case DAE.END() then DAE.END();
    case (e) then e;
  end matchcontinue;
end stringifyCrefs;

protected function stringifyCrefsMatrix
"function: stringifyCrefsMatrix
  author: PA
  Helper function to stringifyCrefs.
  Handles matrix expresion list."
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  output list<list<tuple<Exp, Boolean>>> outTplExpBooleanLstLst;
algorithm
  outTplExpBooleanLstLst:=
  matchcontinue (inTplExpBooleanLstLst)
    local
      list<tuple<Exp, Boolean>> e_1,e;
      list<list<tuple<Exp, Boolean>>> es_1,es;
    case ({}) then {};
    case ((e :: es))
      equation
        e_1 = stringifyCrefsMatrix2(e);
        es_1 = stringifyCrefsMatrix(es);
      then
        (e_1 :: es_1);
  end matchcontinue;
end stringifyCrefsMatrix;

protected function stringifyCrefsMatrix2
"function: stringifyCrefsMatrix2
  author: PA
  Helper function to stringifyCrefsMatrix"
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst;
  output list<tuple<Exp, Boolean>> outTplExpBooleanLst;
algorithm
  outTplExpBooleanLst:=
  matchcontinue (inTplExpBooleanLst)
    local
      Exp e_1,e;
      list<tuple<Exp, Boolean>> es_1,es;
      Boolean b;
    case ({}) then {};
    case (((e,b) :: es))
      equation
        e_1 = stringifyCrefs(e);
        es_1 = stringifyCrefsMatrix2(es);
      then
        ((e_1,b) :: es_1);
  end matchcontinue;
end stringifyCrefsMatrix2;

public function dumpExpGraphviz
"function: dumpExpGraphviz
  Creates a Graphviz Node from an Expression."
  input Exp inExp;
  output Graphviz.Node outNode;
algorithm
  outNode := matchcontinue (inExp)
    local
      Ident s,s_1,s_2,sym,fs,tystr,istr,id;
      Integer x,i;
      ComponentRef c;
      Graphviz.Node lt,rt,ct,tt,ft,t1,t2,t3,crt,dimt,expt,itert;
      Exp e1,e2,e,t,f,start,stop,step,cr,dim,exp,iterexp;
      Operator op;
      list<Graphviz.Node> argnodes,nodes;
      Absyn.Path fcn;
      list<Exp> args,es;
      Type ty;
    case (DAE.END()) then Graphviz.NODE("END",{},{});
    case (DAE.ICONST(integer = x))
      equation
        s = intString(x);
      then
        Graphviz.LNODE("ICONST",{s},{},{});
    case (DAE.RCONST(real = x))
      local Real x;
      equation
        s = realString(x);
      then
        Graphviz.LNODE("RCONST",{s},{},{});
    case (DAE.SCONST(string = s))
      equation
        s_1 = stringAppend("\"", s);
        s_2 = stringAppend(s_1, "\"");
      then
        Graphviz.LNODE("SCONST",{s_2},{},{});
    case (DAE.BCONST(bool = false)) then Graphviz.LNODE("BCONST",{"false"},{},{});
    case (DAE.BCONST(bool = true)) then Graphviz.LNODE("BCONST",{"true"},{},{});
    case (DAE.CREF(componentRef = c))
      equation
        s = printComponentRefStr(c);
      then
        Graphviz.LNODE("CREF",{s},{},{});
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        sym = binopSymbol(op);
        lt = dumpExpGraphviz(e1);
        rt = dumpExpGraphviz(e2);
      then
        Graphviz.LNODE("BINARY",{sym},{},{lt,rt});
    case (DAE.UNARY(operator = op,exp = e))
      equation
        sym = unaryopSymbol(op);
        ct = dumpExpGraphviz(e);
      then
        Graphviz.LNODE("UNARY",{sym},{},{ct});
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        sym = lbinopSymbol(op);
        lt = dumpExpGraphviz(e1);
        rt = dumpExpGraphviz(e2);
      then
        Graphviz.LNODE("LBINARY",{sym},{},{lt,rt});
    case (DAE.LUNARY(operator = op,exp = e))
      equation
        sym = lunaryopSymbol(op);
        ct = dumpExpGraphviz(e);
      then
        Graphviz.LNODE("LUNARY",{sym},{},{ct});
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation
        sym = relopSymbol(op);
        lt = dumpExpGraphviz(e1);
        rt = dumpExpGraphviz(e2);
      then
        Graphviz.LNODE("RELATION",{sym},{},{lt,rt});
    case (DAE.IFEXP(expCond = c,expThen = t,expElse = f))
      local Exp c;
      equation
        ct = dumpExpGraphviz(c);
        tt = dumpExpGraphviz(t);
        ft = dumpExpGraphviz(f);
      then
        Graphviz.NODE("IFEXP",{},{ct,tt,ft});
    case (DAE.CALL(path = fcn,expLst = args))
      equation
        fs = Absyn.pathString(fcn);
        argnodes = Util.listMap(args, dumpExpGraphviz);
      then
        Graphviz.LNODE("CALL",{fs},{},argnodes);
    case(DAE.PARTEVALFUNCTION(path = fcn,expList = args))
      equation
        fs = Absyn.pathString(fcn);
        argnodes = Util.listMap(args, dumpExpGraphviz);
      then
        Graphviz.NODE("PARTEVALFUNCTION",{},argnodes);
    case (DAE.ARRAY(array = es))
      equation
        nodes = Util.listMap(es, dumpExpGraphviz);
      then
        Graphviz.NODE("ARRAY",{},nodes);
    case (DAE.TUPLE(PR = es))
      equation
        nodes = Util.listMap(es, dumpExpGraphviz);
      then
        Graphviz.NODE("TUPLE",{},nodes);
    case (DAE.MATRIX(scalar = es))
      local list<list<tuple<Exp, Boolean>>> es;
      equation
        s = Util.stringDelimitList(
          Util.listMap1(es, printRowStr, "\""), "},{");
        s_1 = stringAppend("{{", s);
        s_2 = stringAppend(s_1, "}}");
      then
        Graphviz.LNODE("MATRIX",{s_2},{},{});
    case (DAE.RANGE(exp = start,expOption = NONE,range = stop))
      equation
        t1 = dumpExpGraphviz(start);
        t2 = Graphviz.NODE(":",{},{});
        t3 = dumpExpGraphviz(stop);
      then
        Graphviz.NODE("RANGE",{},{t1,t2,t3});
    case (DAE.RANGE(exp = start,expOption = SOME(step),range = stop))
      equation
        t1 = dumpExpGraphviz(start);
        t2 = dumpExpGraphviz(step);
        t3 = dumpExpGraphviz(stop);
      then
        Graphviz.NODE("RANGE",{},{t1,t2,t3});
    case (DAE.CAST(ty = ty,exp = e))
      equation
        tystr = typeString(ty);
        ct = dumpExpGraphviz(e);
      then
        Graphviz.LNODE("CAST",{tystr},{},{ct});
    case (DAE.ASUB(exp = e,sub = ((ae1 as DAE.ICONST(i))::{})))
      local Exp ae1;
      equation
        ct = dumpExpGraphviz(e);
        istr = intString(i);
        s = Util.stringAppendList({"[",istr,"]"});
      then
        Graphviz.LNODE("ASUB",{s},{},{ct});
    case (DAE.SIZE(exp = cr,sz = SOME(dim)))
      equation
        crt = dumpExpGraphviz(cr);
        dimt = dumpExpGraphviz(dim);
      then
        Graphviz.NODE("SIZE",{},{crt,dimt});
    case (DAE.SIZE(exp = cr,sz = NONE))
      equation
        crt = dumpExpGraphviz(cr);
      then
        Graphviz.NODE("SIZE",{},{crt});
    case (DAE.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp))
      equation
        fs = Absyn.pathString(fcn);
        expt = dumpExpGraphviz(exp);
        itert = dumpExpGraphviz(iterexp);
      then
        Graphviz.LNODE("REDUCTION",{fs},{},{expt,itert});
    case (_) then Graphviz.NODE("#UNKNOWN EXPRESSION# ----eeestr ",{},{});
  end matchcontinue;
end dumpExpGraphviz;

protected function genStringNTime
"function:getStringNTime
  Appends the string to itself n times."
  input String inString;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inString,inInteger)
    local
      Ident str,new_str,res_str;
      Integer new_level,level;
    case (str,0) then "";  /* n */
    case (str,level)
      equation
        new_level = level + (-1);
        new_str = genStringNTime(str, new_level);
        res_str = stringAppend(str, new_str);
      then
        res_str;
  end matchcontinue;
end genStringNTime;

public function dumpExpStr
"function: dumpExpStr
  Dumps expression to a string."
  input Exp inExp;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inExp,inInteger)
    local
      Ident gen_str,res_str,s,s_1,s_2,sym,lt,rt,ct,tt,ft,fs,argnodes_1,nodes_1,t1,t2,t3,tystr,istr,crt,dimt,expt,itert,id,tpStr;
      Integer level,x,new_level1,new_level2,new_level3,i;
      ComponentRef c;
      Exp e1,e2,e,t,f,start,stop,step,cr,dim,exp,iterexp;
      Operator op;
      list<Ident> argnodes,nodes;
      Absyn.Path fcn;
      list<Exp> args,es;
      Type ty;
    case (DAE.END(),level)
      equation
        gen_str = genStringNTime("   |", level);
        res_str = Util.stringAppendList({gen_str,"END","\n"});
      then
        res_str;
    case (DAE.ICONST(integer = x),level) /* Graphviz.LNODE(\"ICONST\",{s},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        s = intString(x);
        res_str = Util.stringAppendList({gen_str,"ICONST ",s,"\n"});
      then
        res_str;
    case (DAE.RCONST(real = x),level) /* Graphviz.LNODE(\"RCONST\",{s},{},{}) */
      local Real x;
      equation
        gen_str = genStringNTime("   |", level);
        s = realString(x);
        res_str = Util.stringAppendList({gen_str,"RCONST ",s,"\n"});
      then
        res_str;
    case (DAE.SCONST(string = s),level) /* Graphviz.LNODE(\"SCONST\",{s\'\'},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        s_1 = stringAppend("\"", s);
        s_2 = stringAppend(s_1, "\"");
        res_str = Util.stringAppendList({gen_str,"SCONST ",s_2,"\n"});
      then
        res_str;
    case (DAE.BCONST(bool = false),level) /* Graphviz.LNODE(\"BCONST\",{\"false\"},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        res_str = Util.stringAppendList({gen_str,"BCONST ","false","\n"});
      then
        res_str;
    case (DAE.BCONST(bool = true),level) /* Graphviz.LNODE(\"BCONST\",{\"true\"},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        res_str = Util.stringAppendList({gen_str,"BCONST ","true","\n"});
      then
        res_str;
    case (DAE.CREF(componentRef = c,ty=ty),level) /* Graphviz.LNODE(\"CREF\",{s},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        s = /*printComponentRefStr*/debugPrintComponentRefTypeStr(c);
        tpStr= typeString(ty);
        res_str = Util.stringAppendList({gen_str,"CREF ",s," CREFTYPE:",tpStr,"\n"});
      then
        res_str;
    case (exp as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),level) /* Graphviz.LNODE(\"BINARY\",{sym},{},{lt,rt}) */
      local 
        String str;
        Type tp;
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        sym = debugBinopSymbol(op);
        tp = typeof(exp);
        str = typeString(tp);
        lt = dumpExpStr(e1, new_level1);
        rt = dumpExpStr(e2, new_level2);
        res_str = Util.stringAppendList({gen_str,"BINARY ",sym," ",str,"\n",lt,rt,""});
      then
        res_str;
    case (DAE.UNARY(operator = op,exp = e),level) /* Graphviz.LNODE(\"UNARY\",{sym},{},{ct}) */
      local String str;
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        sym = unaryopSymbol(op);
        ct = dumpExpStr(e, new_level1);
        str = "expType:"+&typeString(typeof(e))+&" optype:"+&typeString(typeofOp(op))+&"\n";
        res_str = Util.stringAppendList({gen_str,"UNARY ",sym," ",str,"\n",ct,""});
      then
        res_str;
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),level) /* Graphviz.LNODE(\"LBINARY\",{sym},{},{lt,rt}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        sym = lbinopSymbol(op);
        lt = dumpExpStr(e1, new_level1);
        rt = dumpExpStr(e2, new_level2);
        res_str = Util.stringAppendList({gen_str,"LBINARY ",sym,"\n",lt,rt,""});
      then
        res_str;
    case (DAE.LUNARY(operator = op,exp = e),level) /* Graphviz.LNODE(\"LUNARY\",{sym},{},{ct}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        sym = lunaryopSymbol(op);
        ct = dumpExpStr(e, new_level1);
        res_str = Util.stringAppendList({gen_str,"LUNARY ",sym,"\n",ct,""});
      then
        res_str;
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),level) /* Graphviz.LNODE(\"RELATION\",{sym},{},{lt,rt}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        sym = relopSymbol(op);
        lt = dumpExpStr(e1, new_level1);
        rt = dumpExpStr(e2, new_level2);
        res_str = Util.stringAppendList({gen_str,"RELATION ",sym,"\n",lt,rt,""});
      then
        res_str;
    case (DAE.IFEXP(expCond = c,expThen = t,expElse = f),level) /* Graphviz.NODE(\"IFEXP\",{},{ct,tt,ft}) */
      local Exp c;
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        new_level3 = level + 1;
        ct = dumpExpStr(c, new_level1);
        tt = dumpExpStr(t, new_level2);
        ft = dumpExpStr(f, new_level3);
        res_str = Util.stringAppendList({gen_str,"IFEXP ","\n",ct,tt,ft,""});
      then
        res_str;
    case (DAE.CALL(path = fcn,expLst = args),level) /* Graphviz.LNODE(\"CALL\",{fs},{},argnodes) Graphviz.NODE(\"ARRAY\",{},nodes) */
      equation
        gen_str = genStringNTime("   |", level);
        fs = Absyn.pathString(fcn);
        new_level1 = level + 1;
        argnodes = Util.listMap1(args, dumpExpStr, new_level1);
        argnodes_1 = Util.stringAppendList(argnodes);
        res_str = Util.stringAppendList({gen_str,"CALL ",fs,"\n",argnodes_1,""});
      then
        res_str;
    case (DAE.PARTEVALFUNCTION(path = fcn,expList = args),level)
      equation
        gen_str = genStringNTime("   |", level);
        fs = Absyn.pathString(fcn);
        new_level1 = level + 1;
        argnodes = Util.listMap1(args, dumpExpStr, new_level1);
        argnodes_1 = Util.stringAppendList(argnodes);
        res_str = Util.stringAppendList({gen_str,"CALL ",fs,"\n",argnodes_1,""});
      then
        res_str;
    case (DAE.ARRAY(array = es,scalar=b,ty=tp),level)
      local Boolean b; String s,tpStr; DAE.ExpType tp;
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        nodes = Util.listMap1(es, dumpExpStr, new_level1);
        nodes_1 = Util.stringAppendList(nodes);
        s = Util.boolString(b);
        tpStr = typeString(tp);
        res_str = Util.stringAppendList({gen_str,"ARRAY scalar:",s," tp: ",tpStr,"\n",nodes_1});
      then
        res_str;
    case (DAE.TUPLE(PR = es),level) /* Graphviz.NODE(\"TUPLE\",{},nodes) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        nodes = Util.listMap1(es, dumpExpStr, new_level1);
        nodes_1 = Util.stringAppendList(nodes);
        res_str = Util.stringAppendList({gen_str,"TUPLE ",nodes_1,"\n"});
      then
        res_str;
    case (DAE.MATRIX(scalar = es),level) /* Graphviz.LNODE(\"MATRIX\",{s\'\'},{},{}) */
      local list<list<tuple<Exp, Boolean>>> es;
      equation
        gen_str = genStringNTime("   |", level);
        s = Util.stringDelimitList(
          Util.listMap1(es, printRowStr, "\""), "},{");
        s_1 = stringAppend("{{", s);
        s_2 = stringAppend(s_1, "}}");
        res_str = Util.stringAppendList({gen_str,"MATRIX ","\n",s_2,"","\n"});
      then
        res_str;
    case (DAE.RANGE(exp = start,expOption = NONE,range = stop),level) /* Graphviz.NODE(\"RANGE\",{},{t1,t2,t3}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        t1 = dumpExpStr(start, new_level1);
        t2 = ":";
        t3 = dumpExpStr(stop, new_level2);
        res_str = Util.stringAppendList({gen_str,"RANGE ","\n",t1,t2,t3,""});
      then
        res_str;
    case (DAE.RANGE(exp = start,expOption = SOME(step),range = stop),level) /* Graphviz.NODE(\"RANGE\",{},{t1,t2,t3}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        new_level3 = level + 1;
        t1 = dumpExpStr(start, new_level1);
        t2 = dumpExpStr(step, new_level2);
        t3 = dumpExpStr(stop, new_level3);
        res_str = Util.stringAppendList({gen_str,"RANGE ","\n",t1,t2,t3,""});
      then
        res_str;
    case (DAE.CAST(ty = ty,exp = e),level) /* Graphviz.LNODE(\"CAST\",{tystr},{},{ct}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        tystr = typeString(ty);
        ct = dumpExpStr(e, new_level1);
        res_str = Util.stringAppendList({gen_str,"CAST ","\n",ct,""});
      then
        res_str;
    case (DAE.ASUB(exp = e,sub = ((ae1 as DAE.ICONST(i))::{})),level) /* Graphviz.LNODE(\"ASUB\",{s},{},{ct}) */
      local Exp ae1;
      equation

        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        ct = dumpExpStr(e, new_level1);
        istr = intString(i);
        s = Util.stringAppendList({"[",istr,"]"});
        res_str = Util.stringAppendList({gen_str,"ASUB ",s,"\n",ct,""});
      then
        res_str;
    case (DAE.SIZE(exp = cr,sz = SOME(dim)),level) /* Graphviz.NODE(\"SIZE\",{},{crt,dimt}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        crt = dumpExpStr(cr, new_level1);
        dimt = dumpExpStr(dim, new_level2);
        res_str = Util.stringAppendList({gen_str,"SIZE ","\n",crt,dimt,""});
      then
        res_str;
    case (DAE.SIZE(exp = cr,sz = NONE),level) /* Graphviz.NODE(\"SIZE\",{},{crt}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        crt = dumpExpStr(cr, new_level1);
        res_str = Util.stringAppendList({gen_str,"SIZE ","\n",crt,""});
      then
        res_str;
    case (DAE.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp),level) /* Graphviz.LNODE(\"REDUCTION\",{fs},{},{expt,itert}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        fs = Absyn.pathString(fcn);
        expt = dumpExpStr(exp, new_level1);
        itert = dumpExpStr(iterexp, new_level2);
        res_str = Util.stringAppendList({gen_str,"REDUCTION ","\n",expt,itert,""});
      then
        res_str;
    case (_,level) /* Graphviz.NODE(\"#UNKNOWN EXPRESSION# ----eeestr \",{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        res_str = Util.stringAppendList({gen_str," UNKNOWN EXPRESSION ","\n"});
      then
        res_str;
  end matchcontinue;
end dumpExpStr;

public function solve
"function: solve
  Solves an equation consisting of a right hand side (rhs) and a
  left hand side (lhs), with respect to the expression given as
  third argument, usually a variable."
  input Exp inExp1;
  input Exp inExp2;
  input Exp inExp3;
  output Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inExp2,inExp3)
    local
      Exp crexp,crexp2,rhs,lhs,res,res_1,cr,e1,e2,e3;
      ComponentRef cr1,cr2;
    /*
    case(debuge1,debuge2,debuge3) // FOR DEBBUGING...
      local Exp debuge1,debuge2,debuge3;
      equation
        print("(Exp.mo debugging)  To solve: rhs: " +&
          printExpStr(debuge1) +& " lhs: " +&
          printExpStr(debuge2) +& " with respect to: " +&
          printExpStr(debuge3) +& "\n");
      then
        fail();*/
    
    // special case when already solved, cr1 = rhs, otherwise division by zero when dividing with derivative
    case (crexp,rhs,crexp2)
      equation
        cr1 = crOrDerCr(crexp);
        cr2 = crOrDerCr(crexp2);
        true = crefEqual(cr1, cr2);
        false = expContains(rhs, crexp);
        res_1 = simplify1(rhs);
      then
        res_1;

    // special case when already solved, lhs = cr1, otherwise division by zero  when dividing with derivative
    case (lhs,crexp ,crexp2)
      equation
        cr1 = crOrDerCr(crexp);
        cr2 = crOrDerCr(crexp2);
        true = crefEqual(cr1, cr2);
        false = expContains(lhs, crexp);
        res_1 = simplify1(lhs);
      then
        res_1;    

    // solving linear equation system using newton iteration ( converges directly )
    case (lhs,rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        res = solve2(lhs, rhs, cr);
        res_1 = simplify1(res);
      then
        res_1;
    
    case (lhs,DAE.IFEXP(e1,e2,e3),(cr as DAE.CREF(componentRef = _)))
      equation
        rhs = solve(lhs,e2,cr);
        res = solve(lhs,e3,cr);
        res_1 = simplify1(DAE.IFEXP(e1,rhs,res));
      then
        res_1;
    
    case (DAE.IFEXP(e1,e2,e3),rhs,(cr as DAE.CREF(componentRef = _)))
      equation
        lhs = solve(rhs,e2,cr);
        res = solve(rhs,e3,cr);
        res_1 = simplify1(DAE.IFEXP(e1,rhs,res));
      then
        res_1;
        
    case (e1,e2,e3)
      equation
        Debug.fprint("failtrace", "-Exp.solve failed\n");
        /*print("solve ");print(printExpStr(e1));print(" = ");print(printExpStr(e2));
        print(" w.r.t ");print(printExpStr(e3));print(" failed\n");*/
      then
        fail();
  end matchcontinue;
end solve;

protected function printExpIfDiff ""
  input Exp e1,e2;
  output String s;
algorithm 
  s := matchcontinue(e1,e2)
    case(e1,e2)
      equation
        true = expEqual(e1,e2);
      then
        "";
    case(e1,e2)
      equation
        false = expEqual(e1,e2);
        s = printExpStr(e1) +& " =!= " +& printExpStr(e2) +& "\n";
      then
        s;
  end matchcontinue;
end printExpIfDiff;

protected function solve2
"function: solve2
  This function solves an equation e1 = e2 with
  respect to the variable given as an expression e3"
  input Exp inExp1;
  input Exp inExp2;
  input Exp inExp3;
  output Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inExp2,inExp3)
    local
      Exp lhs,lhsder,lhsder_1,lhszero,lhszero_1,rhs,rhs_1,e1,e2,crexp;
      ComponentRef cr;
    
    // e1 e2 e3 
    case (e1,e2,(crexp as DAE.CREF(componentRef = cr)))
      equation
        false = hasOnlyFactors(e1,e2);
        lhs = DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2);
        lhsder = Derive.differentiateExpCont(lhs, cr);
        lhsder_1 = simplify(lhsder);
        false = isZero(lhsder_1);
        false = expContains(lhsder_1, crexp);
        (lhszero,_) = replaceExp(lhs, crexp, DAE.RCONST(0.0));
        lhszero_1 = simplify(lhszero);
        rhs = DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),DAE.BINARY(lhszero_1,DAE.DIV(DAE.ET_REAL()),lhsder_1));
        rhs_1 = simplify(rhs);
      then
        rhs_1;

    case(e1,e2,(crexp as DAE.CREF(componentRef = cr)))
      local Exp invCr; list<Exp> factors;
      equation
        ({invCr},factors) = Util.listSplitOnTrue1(listAppend(factors(e1),factors(e2)),isInverseCref,cr);
        rhs_1 = makeProductLst(inverseFactors(factors));
        false = expContains(rhs_1, crexp);
      then
        rhs_1;

    case (e1,e2,(crexp as DAE.CREF(componentRef = cr)))
      equation
        lhs = DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2);
        lhsder = Derive.differentiateExpCont(lhs, cr);
        lhsder_1 = simplify(lhsder);
        true = expContains(lhsder_1, crexp);
        /*print("solve2 failed: Not linear: ");
        print(printExpStr(e1));
        print(" = ");
        print(printExpStr(e2));
        print("\nsolving for: ");
        print(printExpStr(crexp));
        print("\n");
        print("derivative: ");
        print(printExpStr(lhsder));
        print("\n");*/
      then
        fail();
    
    case (e1,e2,(crexp as DAE.CREF(componentRef = cr)))
      equation
        lhs = DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2);
        lhsder = Derive.differentiateExpCont(lhs, cr);
        lhsder_1 = simplify(lhsder);
        /*print("solve2 failed: ");
        print(printExpStr(e1));
        print(" = ");
        print(printExpStr(e2));
        print("\nsolving for: ");
        print(printExpStr(crexp));
        print("\n");
        print("derivative: ");
        print(printExpStr(lhsder_1));
        print("\n");*/
      then
        fail();
  end matchcontinue;
end solve2;

protected function hasOnlyFactors "help function to solve2, returns true if equation e1 == e2, has either e1 == 0 or e2 == 0 and the expression only contains
factors, e.g. a*b*c = 0. In this case we can not solve the equation"
  input Exp e1;
  input Exp e2;
  output Boolean res;
algorithm
  res := matchcontinue(e1,e2)
    case(e1,e2) equation
      true = isZero(e1);
      // More than two factors
      _::_::_ = factors(e2);
      //.. and more than two crefs
      _::_::_ = getCrefFromExp(e2);
    then true;
      
      // Swapped args
    case(e2,e1) equation
      true = isZero(e1);
      _::_::_ = factors(e2);
      _::_::_ = getCrefFromExp(e2);
    then true;
    
    case(_,_) then false;      
  end matchcontinue;
end hasOnlyFactors;

public function getTermsContainingX
"function getTermsContainingX
  Retrieves all terms of an expression containng a variable,
  given as second argument (in the form of an Exp)"
  input Exp inExp1;
  input Exp inExp2;
  output Exp outExp1;
  output Exp outExp2;
algorithm
  (outExp1,outExp2) := matchcontinue (inExp1,inExp2)
    local
      Exp xt1,nonxt1,xt2,nonxt2,xt,nonxt,e1,e2,cr,e;
      Type ty;
      Boolean res;
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = ty),exp2 = e2),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.ADD(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.ADD(ty),nonxt2);
      then
        (xt,nonxt);
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = ty),exp2 = e2),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.SUB(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.SUB(ty),nonxt2);
      then
        (xt,nonxt);
    case (DAE.UNARY(operator = DAE.UPLUS(ty = ty),exp = e),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = DAE.UNARY(DAE.UPLUS(ty),xt1);
        nonxt = DAE.UNARY(DAE.UPLUS(ty),nonxt1);
      then
        (xt,nonxt);
    case (DAE.UNARY(operator = DAE.UMINUS(ty = ty),exp = e),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = DAE.UNARY(DAE.UMINUS(ty),xt1);
        nonxt = DAE.UNARY(DAE.UMINUS(ty),nonxt1);
      then
        (xt,nonxt);
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = ty),exp2 = e2),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.ADD_ARR(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.ADD_ARR(ty),nonxt2);
      then
        (xt,nonxt);      
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = ty),exp2 = e2),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.SUB_ARR(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.SUB_ARR(ty),nonxt2);
      then
        (xt,nonxt);      
    case (DAE.UNARY(operator = DAE.UPLUS_ARR(ty = ty),exp = e),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = DAE.UNARY(DAE.UPLUS_ARR(ty),xt1);
        nonxt = DAE.UNARY(DAE.UPLUS_ARR(ty),nonxt1);
      then
        (xt,nonxt);
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(ty = ty),exp = e),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = DAE.UNARY(DAE.UMINUS_ARR(ty),xt1);
        nonxt = DAE.UNARY(DAE.UMINUS_ARR(ty),nonxt1);
      then
        (xt,nonxt);            
    case (e,(cr as DAE.CREF(componentRef = _)))
      equation
        res = expContains(e, cr);
        xt = Util.if_(res, e, DAE.RCONST(0.0));
        nonxt = Util.if_(res, DAE.RCONST(0.0), e);
      then
        (xt,nonxt);
    case (e,cr)
      equation
        /*Print.printBuf("Exp.getTerms_containingX failed: ");
        printExp(e);
        Print.printBuf("\nsolving for: ");
        printExp(cr);
        Print.printBuf("\n");*/
      then
        fail();
  end matchcontinue;
end getTermsContainingX;

public function expContains
"function: expContains
  Returns true if first expression contains the
  second one as a sub expression. Only component
  references or der(componentReference) can be
  checked so far."
  input Exp inExp1;
  input Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp1,inExp2)
    local
      Integer i;
      Exp cr,c1,c2,e1,e2,e,c,t,f,cref;
      Ident s,str;
      Boolean res,res1,res2,res3;
      list<Boolean> reslist;
      list<Exp> explist,expl_2,args;
      list<tuple<Exp, Boolean>> expl_1;
      list<list<tuple<Exp, Boolean>>> expl;
      ComponentRef cr1,cr2;
      Operator op;
      Absyn.Path fcn;
    
    case (DAE.ICONST(integer = _),cr) then false;
    case (DAE.RCONST(real = _),cr) then false;
    case (DAE.SCONST(string = _),cr) then false;
    case (DAE.BCONST(bool = _),cr) then false;
    case (DAE.ARRAY(array = explist),cr)
      equation
        reslist = Util.listMap1(explist, expContains, cr);
        res = Util.boolOrList(reslist);
      then
        res;
    case (DAE.MATRIX(scalar = expl),cr)
      equation
        expl_1 = Util.listFlatten(expl);
        expl_2 = Util.listMap(expl_1, Util.tuple21);
        reslist = Util.listMap1(expl_2, expContains, cr);
        res = Util.boolOrList(reslist);
      then
        res;
    case ((c1 as DAE.CREF(componentRef = cr1)),(c2 as DAE.CREF(componentRef = cr2)))
      equation
        res = crefEqual(cr1, cr2);
      then
        res;
    case ((c1 as DAE.CREF(componentRef = cr1)),c2 ) then false;
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),cr )
      equation
        res1 = expContains(e1, cr);
        res2 = expContains(e2, cr);
        res = boolOr(res1, res2);
      then
        res;
    case (DAE.UNARY(operator = op,exp = e),cr)
      equation
        res = expContains(e, cr);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),cr)
      equation
        res1 = expContains(e1, cr);
        res2 = expContains(e2, cr);
        res = boolOr(res1, res2);
      then
        res;
    case (DAE.LUNARY(operator = op,exp = e),cr )
      equation
        res = expContains(e, cr);
      then
        res;
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),cr)
      equation
        res1 = expContains(e1, cr);
        res2 = expContains(e2, cr);
        res = boolOr(res1, res2);
      then
        res;
    case (DAE.IFEXP(expCond = c,expThen = t,expElse = f),cr)
      equation
        res1 = expContains(c, cr);
        res2 = expContains(t, cr);
        res3 = expContains(f, cr);
        res = Util.boolOrList({res1,res2,res3});
      then
        res;
    case(DAE.CALL(path=Absyn.IDENT(name="der"),expLst={DAE.CREF(cr1,_)}),
         DAE.CALL(path=Absyn.IDENT(name="der"),expLst={DAE.CREF(cr2,_)})) 
      equation
        res = crefEqual(cr1,cr2);
      then res;
    // pre(v) does not contain variable v
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = {cref}),cr) then false;
    // special rule for no arguments
    case (DAE.CALL(expLst = {}),_) then false;
    // general case for arguments
    case (DAE.CALL(path = fcn,expLst = args),(cr as DAE.CREF(componentRef = _)))
      equation
        reslist = Util.listMap1(args, expContains, cr);
        res = Util.boolOrList(reslist);
      then
        res;
    case (DAE.PARTEVALFUNCTION(path = fcn,expList = args),(cr as DAE.CREF(componentRef = _)))
      equation
        reslist = Util.listMap1(args, expContains, cr);
        res = Util.boolOrList(reslist);
      then
        res;
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = DAE.ICONST(integer = i)),cr ) then false;
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e),cr )
      equation
        res = expContains(e, cr);
      then
        res;
    case (DAE.ASUB(exp = e,sub = _),cr)
      equation
        res = expContains(e, cr);
      then
        res;
		case (DAE.REDUCTION(expr = e), cr)
			equation
				res = expContains(e, cr);
			then
				res;
    case (e,cr)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-Exp.expContains failed\n");
        s = printExpStr(e);
        str = Util.stringAppendList({"exp = ",s,"\n"});
        Debug.fprint("failtrace", str);
      then
        fail();
  end matchcontinue;
end expContains;

public function getCrefFromExp
"function: getCrefFromExp
  Return a list of all component
  references occuring in the expression."
  input Exp inExp;
  output list<ComponentRef> outComponentRefLst;
algorithm
  outComponentRefLst := matchcontinue (inExp)
    local
      ComponentRef cr;
      list<ComponentRef> l1,l2,res,res1,l3,res2;
      Exp e1,e2,e3,e;
      Operator op;
      list<Exp> farg,expl,expl_2;
      list<tuple<Exp, Boolean>> expl_1;
    case (DAE.ICONST(integer = _)) then {};
    case (DAE.RCONST(real = _)) then {};
    case (DAE.SCONST(string = _)) then {};
    case (DAE.BCONST(bool = _)) then {};
    case (DAE.CREF(componentRef = cr)) then {cr};
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res = listAppend(l1, l2);
      then
        res;
    case (DAE.UNARY(operator = op,exp = e1))
      equation
        res = getCrefFromExp(e1);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res = listAppend(l1, l2);
      then
        res;
    case (DAE.LUNARY(operator = op,exp = e1))
      equation
        res = getCrefFromExp(e1);
      then
        res;
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res = listAppend(l1, l2);
      then
        res;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res1 = listAppend(l1, l2);
        l3 = getCrefFromExp(e3);
        res = listAppend(res1, l3);
      then
        res;
    case (DAE.CALL(expLst = farg))
      local list<list<ComponentRef>> res;
      equation
        res = Util.listMap(farg, getCrefFromExp);
        res2 = Util.listFlatten(res);
      then
        res2;
    case(DAE.PARTEVALFUNCTION(expList = farg))
      local list<list<ComponentRef>> res;
      equation
        res = Util.listMap(farg, getCrefFromExp);
        res2 = Util.listFlatten(res);
      then
        res2;
    case (DAE.ARRAY(array = expl))
      local list<list<ComponentRef>> res1;
      equation
        res1 = Util.listMap(expl, getCrefFromExp);
        res = Util.listFlatten(res1);
      then
        res;
    case (DAE.MATRIX(scalar = expl))
      local
        list<list<ComponentRef>> res1;
        list<list<tuple<Exp, Boolean>>> expl;
      equation
        expl_1 = Util.listFlatten(expl);
        expl_2 = Util.listMap(expl_1, Util.tuple21);
        res1 = Util.listMap(expl_2, getCrefFromExp);
        res = Util.listFlatten(res1);
      then
        res;
    case (DAE.RANGE(exp = e1,expOption = SOME(e3),range = e2))
      equation
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res1 = listAppend(l1, l2);
        l3 = getCrefFromExp(e3);
        res = listAppend(res1, l3);
      then
        res;
    case (DAE.RANGE(exp = e1,expOption = NONE,range = e2))
      equation
        l1 = getCrefFromExp(e1);
        l2 = getCrefFromExp(e2);
        res = listAppend(l1, l2);
      then
        res;
    case (DAE.TUPLE(PR = expl))
      local list<list<ComponentRef>> res;
      equation
        res = Util.listMap(expl, getCrefFromExp);
        res2 = Util.listFlatten(res);
      then
        res2;
    case (DAE.CAST(exp = e))
      equation
        res = getCrefFromExp(e);
      then
        res;
    case (DAE.ASUB(exp = e))
      equation
        res = getCrefFromExp(e);
      then
        res;

    /* MetaModelica list */
    case (DAE.CONS(_,e1,e2))
      local list<list<ComponentRef>> res;
      equation
        expl = {e1,e2};
        res = Util.listMap(expl, getCrefFromExp);
        res2 = Util.listFlatten(res);
      then res2;

    case  (DAE.LIST(_,expl))
      local list<list<ComponentRef>> res;
      equation
        res = Util.listMap(expl, getCrefFromExp);
        res2 = Util.listFlatten(res);
      then res2;

/*    case  (METADAE.TUPLE(expl))
      local list<list<ComponentRef>> res;
      equation
        res = Util.listMap(expl, getCrefFromExp);
        res2 = Util.listFlatten(res);
      then res2; */
        /* --------------------- */

    case (_) then {};
  end matchcontinue;
end getCrefFromExp;

public function nthArrayExp
"function: nthArrayExp
  author: PA
  Returns the nth expression of an array expression."
  input Exp inExp;
  input Integer inInteger;
  output Exp outExp;
algorithm
  outExp := matchcontinue (inExp,inInteger)
    local
      Exp e;
      list<Exp> expl;
      Integer indx;
    case (DAE.ARRAY(array = expl),indx)
      equation
        e = listNth(expl, indx);
      then
        e;
  end matchcontinue;
end nthArrayExp;

public function expAdd
"function: expAdd
  author: PA
  Adds two scalar expressions."
  input Exp e1;
  input Exp e2;
  output Exp outExp;
  Type tp;
  Boolean b;
  Operator op;
algorithm
  tp := typeof(e1);
  b := DAEUtil.expTypeArray(tp) "	array_elt_type(tp) => tp\'" ;
  op := Util.if_(b,DAE.ADD_ARR(tp),DAE.ADD(tp));
  outExp := DAE.BINARY(e1,op,e2);
end expAdd;

public function expMul
"function: expMul
  author: PA
  Multiplies two scalar expressions."
  input Exp e1;
  input Exp e2;
  output Exp outExp;
  Type tp;
  Boolean b;
  Operator op;
algorithm
  tp := typeof(e1);
  b := DAEUtil.expTypeArray(tp) "	array_elt_type(tp) => tp\'" ;
  op := Util.if_(b,DAE.MUL_ARR(tp),DAE.MUL(tp));
  outExp := DAE.BINARY(e1,op,e2);
end expMul;

public function makeCrefExpNoType "similar to makeCrefExp but picks type from componentref"
input ComponentRef cref;
output Exp e;
algorithm
  e := makeCrefExp(cref,crefTypeConsiderSubs(cref));
end makeCrefExpNoType;

public function makeCrefExp
"function makeCrefExp
  Makes an expression of a component reference, given also a type"
  input ComponentRef cref;
  input Type tp;
  output Exp e;
algorithm e:= matchcontinue(cref,tp)
  local Type tp2;
  case(cref,tp) then DAE.CREF(cref,tp);
  end matchcontinue;
end makeCrefExp;

public function makeIndexSubscript
"function makeIndexSubscript
  Creates a Subscript INDEX from an Exp."
  input Exp exp;
  output Subscript subscript;
algorithm
  subscript := DAE.INDEX(exp);
end makeIndexSubscript;

public function expCref
"function: expCref
  Returns the componentref if exp is a CREF,"
  input Exp inExp;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inExp)
    local ComponentRef cr;
    case (DAE.CREF(componentRef = cr)) then cr;
  end matchcontinue;
end expCref;

public function expCrefTuple
"function: expCrefTuple
  Returns the componentref if the expression in inTuple is a CREF."
  input tuple<Exp, Boolean> inTuple;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inTuple)
    local ComponentRef cr;
    case ((DAE.CREF(componentRef = cr),_)) then cr;
  end matchcontinue;
end expCrefTuple;


public function traverseExp
"function traverseExp
  Traverses all subexpressions of an expression.
  Takes a function and an extra argument passed through the traversal.
  The function can potentially change the expression. In such cases,
  the changes are made bottom-up, i.e. a subexpression is traversed
  and changed before the complete expression is traversed."
  input Exp inExp;
  input FuncExpType func;
  input Type_a inTypeA;
  output tuple<Exp, Type_a> outTplExpTypeA;
  partial function FuncExpType
    input tuple<Exp, Type_a> inTplExpTypeA;
    output tuple<Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  outTplExpTypeA:=
  matchcontinue (inExp,func,inTypeA)
    local
      Exp e1_1,e,e1,e2_1,e2,e3_1,e_1,e3;
      Type_a ext_arg_1,ext_arg_2,ext_arg,ext_arg_3,ext_arg_4;
      Operator op_1,op;
      FuncExpType rel;
      list<Exp> expl_1,expl;
      Absyn.Path fn_1,fn,path_1,path;
      Boolean t_1,b_1,t,b,scalar_1,scalar;
      Type tp_1,tp;
      Integer i_1,i;
      Ident id_1,id;
    case ((e as DAE.UNARY(operator = op,exp = e1)),rel,ext_arg) /* unary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.UNARY(op,e1_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* binary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.BINARY(e1_1,op,e2_1),ext_arg_2));
      then
        ((e,ext_arg_3));
    case ((e as DAE.LUNARY(operator = op,exp = e1)),rel,ext_arg) /* logic unary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.LUNARY(op,e1_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* logic binary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.LBINARY(e1_1,op,e2_1),ext_arg_2));
      then
        ((e,ext_arg_3));
    case ((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* RELATION */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.RELATION(e1_1,op,e2_1),ext_arg_2));
      then
        ((e,ext_arg_3));
    case ((e as DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3)),rel,ext_arg) /* if expression */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e3_1,ext_arg_3)) = traverseExp(e3, rel, ext_arg_2);
        ((e,ext_arg_4)) = rel((DAE.IFEXP(e1_1,e2_1,e3_1),ext_arg_3));
      then
        ((e,ext_arg_4));
    case ((e as DAE.CALL(path = fn,expLst = expl,tuple_ = t,builtin = b,ty=tp,inlineType = i)),rel,ext_arg)
      local Type tp,tp_1; DAE.InlineType  i;
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.CALL(fn,expl_1,t,b,tp,i),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.PARTEVALFUNCTION(path = fn, expList = expl, ty = tp)),rel,ext_arg)
      local Type tp;
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.PARTEVALFUNCTION(fn,expl_1,tp),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.ARRAY(ty = tp,scalar = scalar,array = expl)),rel,ext_arg)
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.ARRAY(tp,scalar,expl_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.MATRIX(ty = tp,integer = scalar,scalar = expl)),rel,ext_arg)
      local
        list<list<tuple<Exp, Boolean>>> expl_1,expl;
        Integer scalar_1,scalar;
      equation
        (expl_1,ext_arg_1) = traverseExpMatrix(expl, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.MATRIX(tp,scalar,expl_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.RANGE(ty = tp,exp = e1,expOption = NONE,range = e2)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.RANGE(tp,e1_1,NONE,e2_1),ext_arg_2));
      then
        ((e,ext_arg_3));
    case ((e as DAE.RANGE(ty = tp,exp = e1,expOption = SOME(e2),range = e3)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e3_1,ext_arg_3)) = traverseExp(e3, rel, ext_arg_2);
        ((e,ext_arg_4)) = rel((DAE.RANGE(tp,e1_1,SOME(e2_1),e3_1),ext_arg_3));
      then
        ((e,ext_arg_4));
    case ((e as DAE.TUPLE(PR = expl)),rel,ext_arg)
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.TUPLE(expl_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.CAST(ty = tp,exp = e1)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.CAST(tp,e1_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.ASUB(exp = e1,sub = expl_1)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((expl_1,ext_arg_2)) = traverseExpList(expl_1, rel, ext_arg_1);
        ((e,ext_arg_2)) = rel((DAE.ASUB(e1_1,expl_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.SIZE(exp = e1,sz = NONE)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.SIZE(e1_1,NONE),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.SIZE(exp = e1,sz = SOME(e2))),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.SIZE(e1_1,SOME(e2_1)),ext_arg_2));
      then
        ((e,ext_arg_3));
    case ((e as DAE.REDUCTION(path = path,expr = e1,ident = id,range = e2)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.REDUCTION(path,e1_1,id,e2_1),ext_arg_2));
      then
        ((e,ext_arg_3));
            /* MetaModelica list */
    case ((e as DAE.CONS(tp,e1,e2)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((DAE.CONS(_,_,_),ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((DAE.CONS(tp,e1_1,e2_1),ext_arg_3));

    case ((e as DAE.LIST(tp,expl)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = Util.listFoldMap(expl, rel, ext_arg);
        ((e_1,ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((DAE.LIST(tp,expl_1),ext_arg_2));

    case ((e as DAE.META_TUPLE(expl)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = Util.listFoldMap(expl, rel, ext_arg);
        ((e_1,ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((DAE.META_TUPLE(expl_1),ext_arg_2));

    case ((e as DAE.META_OPTION(NONE())),rel,ext_arg)
      equation
      then
        ((DAE.META_OPTION(NONE()),ext_arg));

    case ((e as DAE.META_OPTION(SOME(e1))),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e_1,ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((DAE.META_OPTION(SOME(e1_1)),ext_arg_2));
        /* --------------------- */

    case (e,rel,ext_arg)
      equation
        ((e_1,ext_arg_1)) = rel((e,ext_arg));
      then
        ((e_1,ext_arg_1));
  end matchcontinue;
end traverseExp;

protected function traverseExpMatrix
"function: traverseExpMatrix
  author: PA
   Helper function to traverseExp, traverses matrix expressions."
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<list<tuple<Exp, Boolean>>> outTplExpBooleanLstLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<Exp, Type_a> inTplExpTypeA;
    output tuple<Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outTplExpBooleanLstLst,outTypeA):=
  matchcontinue (inTplExpBooleanLstLst,func,inTypeA)
    local
      FuncExpType rel;
      Type_a e_arg,e_arg_1,e_arg_2;
      list<tuple<Exp, Boolean>> row_1,row;
      list<list<tuple<Exp, Boolean>>> rows_1,rows;
    case ({},rel,e_arg) then ({},e_arg);
    case ((row :: rows),rel,e_arg)
      equation
        (row_1,e_arg_1) = traverseExpMatrix2(row, rel, e_arg);
        (rows_1,e_arg_2) = traverseExpMatrix(rows, rel, e_arg_1);
      then
        ((row_1 :: rows_1),e_arg_2);
  end matchcontinue;
end traverseExpMatrix;

protected function traverseExpMatrix2
"function: traverseExpMatrix2
  author: PA
  Helper function to traverseExpMatrix."
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<tuple<Exp, Boolean>> outTplExpBooleanLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<Exp, Type_a> inTplExpTypeA;
    output tuple<Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outTplExpBooleanLst,outTypeA):=
  matchcontinue (inTplExpBooleanLst,func,inTypeA)
    local
      Type_a e_arg,e_arg_1,e_arg_2;
      Exp e_1,e;
      list<tuple<Exp, Boolean>> rest_1,rest;
      Boolean b;
      FuncExpType rel;
    case ({},_,e_arg) then ({},e_arg);
    case (((e,b) :: rest),rel,e_arg)
      equation
        ((e_1,e_arg_1)) = traverseExp(e, rel, e_arg);
        (rest_1,e_arg_2) = traverseExpMatrix2(rest, rel, e_arg_1);
      then
        (((e_1,b) :: rest_1),e_arg_2);
  end matchcontinue;
end traverseExpMatrix2;

protected function matrixExpMap1
"function: matrixExpMap1
  author: PA
  Maps a function, taking one extra
  argument over a MATRIX expression list."
  input list<list<tuple<Exp, Boolean>>> inTplExpBooleanLstLst;
  input FuncTypeExpType_bToExp inFuncTypeExpTypeBToExp;
  input Type_b inTypeB;
  output list<list<tuple<Exp, Boolean>>> outTplExpBooleanLstLst;
  partial function FuncTypeExpType_bToExp
    input Exp inExp;
    input Type_b inTypeB;
    output Exp outExp;
    replaceable type Type_b subtypeof Any;
  end FuncTypeExpType_bToExp;
  replaceable type Type_b subtypeof Any;
algorithm
  outTplExpBooleanLstLst:=
  matchcontinue (inTplExpBooleanLstLst,inFuncTypeExpTypeBToExp,inTypeB)
    local
      list<tuple<Exp, Boolean>> e_1,e;
      list<list<tuple<Exp, Boolean>>> es_1,es;
      FuncTypeExpType_bToExp rel;
      Type_b arg;
    case ({},_,_) then {};
    case ((e :: es),rel,arg)
      equation
        e_1 = matrixExpMap1Help(e, rel, arg);
        es_1 = matrixExpMap1(es, rel, arg);
      then
        (e_1 :: es_1);
  end matchcontinue;
end matrixExpMap1;

protected function matrixExpMap1Help
"function: matrixExpMap1Help
  Helper function to matrixExpMap1."
  input list<tuple<Exp, Boolean>> inTplExpBooleanLst;
  input FuncTypeExpType_bToExp inFuncTypeExpTypeBToExp;
  input Type_b inTypeB;
  output list<tuple<Exp, Boolean>> outTplExpBooleanLst;
  partial function FuncTypeExpType_bToExp
    input Exp inExp;
    input Type_b inTypeB;
    output Exp outExp;
    replaceable type Type_b subtypeof Any;
  end FuncTypeExpType_bToExp;
  replaceable type Type_b subtypeof Any;
algorithm
  outTplExpBooleanLst:=
  matchcontinue (inTplExpBooleanLst,inFuncTypeExpTypeBToExp,inTypeB)
    local
      Exp e_1,e;
      list<tuple<Exp, Boolean>> es_1,es;
      Boolean b;
      FuncTypeExpType_bToExp rel;
      Type_b arg;
    case ({},_,_) then {};
    case (((e,b) :: es),rel,arg)
      equation
        e_1 = rel(e, arg);
        es_1 = matrixExpMap1Help(es, rel, arg);
      then
        ((e_1,b) :: es_1);
  end matchcontinue;
end matrixExpMap1Help;

public function CodeVarToCref
  input Exp inExp;
  output Exp outExp;
algorithm
  outExp:=matchcontinue(inExp)
  local ComponentRef e_cref; Absyn.ComponentRef cref;
    case(DAE.CODE(Absyn.C_VARIABLENAME(cref),_)) equation
      (_,e_cref) = Static.elabUntypedCref(Env.emptyCache(),Env.emptyEnv,cref,false,Prefix.NOPRE);
      then DAE.CREF(e_cref,DAE.ET_OTHER());
  end matchcontinue;
end CodeVarToCref;

public function expIntOrder "Function: expIntOrder
This function takes a list of Exp, assumes they are all ICONST
and checks wheter the ICONST are in order."
  input Integer expectedValue;
  input list<Exp> integers;
  output Boolean ob;
algorithm 
  ob := matchcontinue(expectedValue,integers)
    local
      list<Exp> expl;
      Integer x1,x2;
      Boolean b;
    case(_,{}) then true;
    case(x1, DAE.ICONST(x2)::expl)
      equation
        true = intEq(x1, x2);
        b = expIntOrder(x1+1,expl);
      then 
        b;
    case(_,_) then false;
  end matchcontinue;
end expIntOrder;

public function makeVar "Creates a Var given a name and Type"
  input String name;
  input Type tp;
  output Var v;
algorithm
  v:= DAE.COMPLEX_VAR(name,tp);
end makeVar;

public function varName "Returns the name of a Var"
  input Var v;
  output String name;
algorithm
  name := matchcontinue(v)
    case(DAE.COMPLEX_VAR(name,_)) then name;
  end matchcontinue;
end varName;

public function varType "Returns the type of a Var"
  input Var v;
  output Type tp;
algorithm
  tp := matchcontinue(v)
    case(DAE.COMPLEX_VAR(_,tp)) then tp;
  end matchcontinue;
end varType;

public function countBinary "counts the number of binary operations in an expression"
  input Exp e;
  output Integer count;
algorithm
  count := matchcontinue(e)
    local Exp e1,e2,e3; list<Exp> expl; list<list<tuple<Exp,Boolean>>> mexpl;
    case(DAE.BINARY(e1,_,e2)) 
      equation
        count = 1 + countBinary(e1) + countBinary(e2);
      then count;
    case(DAE.IFEXP(e1,e2,e3)) 
      equation
        count =  countBinary(e2) + countBinary(e3);
      then count;
    case(DAE.CALL(expLst = expl)) 
      equation
        count = Util.listReduce(Util.listMap(expl,countBinary),intAdd);
      then count;
    case(DAE.PARTEVALFUNCTION(expList = expl))
      equation
        count = Util.listReduce(Util.listMap(expl,countBinary),intAdd);
      then count;
    case(DAE.ARRAY(array = expl)) 
      equation
        count = Util.listReduce(Util.listMap(expl,countBinary),intAdd);
      then count;
    case(DAE.MATRIX(scalar=mexpl)) 
      equation
        expl = Util.listFlatten(Util.listListMap(mexpl,Util.tuple21));
        count = Util.listReduce(Util.listMap(expl,countBinary),intAdd);
      then count;
    case(DAE.RANGE(_,e1,SOME(e2),e3)) 
      equation
        count = countBinary(e1) + countBinary(e2) + countBinary(e3);
      then count;
    case(DAE.RANGE(_,e1,NONE,e3)) 
      equation
        count = countBinary(e1) + countBinary(e3);
      then count;
    case(DAE.TUPLE(expl)) 
      equation
        count = Util.listReduce(Util.listMap(expl,countBinary),intAdd);
      then count;
    case(DAE.CAST(_,e)) then countBinary(e);
    case(DAE.ASUB(e,_)) then countBinary(e);
    case(_) then 0;
  end matchcontinue;
end countBinary;

public function countMulDiv "counts the number of multiplications and divisions in an expression"
  input Exp e;
  output Integer count;
algorithm
  count := matchcontinue(e)
    local Exp e1,e2,e3; list<Exp> expl; list<list<tuple<Exp,Boolean>>> mexpl;
    case(DAE.BINARY(e1,DAE.MUL(_),e2)) equation
      count = 1 + countMulDiv(e1) + countMulDiv(e2);
    then count;
    case(DAE.BINARY(e1,DAE.DIV(_),e2)) equation
      count = 1 + countMulDiv(e1) + countMulDiv(e2);
    then count;
    case(DAE.IFEXP(e1,e2,e3)) equation
      count =  countMulDiv(e2) + countMulDiv(e3);
    then count;
    case(DAE.CALL(expLst = expl)) equation
      count = Util.listReduce(Util.listMap(expl,countMulDiv),intAdd);
    then count;
    case(DAE.PARTEVALFUNCTION(expList = expl)) equation
      count = Util.listReduce(Util.listMap(expl,countMulDiv),intAdd);
    then count;
    case(DAE.ARRAY(array = expl)) equation
      count = Util.listReduce(Util.listMap(expl,countMulDiv),intAdd);
    then count;
    case(DAE.MATRIX(scalar=mexpl)) equation
      expl = Util.listFlatten(Util.listListMap(mexpl,Util.tuple21));
      count = Util.listReduce(Util.listMap(expl,countMulDiv),intAdd);
    then count;
    case(DAE.RANGE(_,e1,SOME(e2),e3)) equation
      count = countMulDiv(e1) + countMulDiv(e2) + countMulDiv(e3);
    then count;
    case(DAE.RANGE(_,e1,NONE,e3)) equation
      count = countMulDiv(e1) + countMulDiv(e3);
    then count;
    case(DAE.TUPLE(expl)) equation
      count = Util.listReduce(Util.listMap(expl,countMulDiv),intAdd);
    then count;
    case(DAE.CAST(_,e)) then countMulDiv(e);
    case(DAE.ASUB(e,_)) then countMulDiv(e);
    case(_) then 0;
  end matchcontinue;
end countMulDiv;

public function crefExp "
Author: BZ, 2008-08
generate an DAE.CREF(ComponentRef, Type) from a ComponenRef, make array type correct from subs"
  input ComponentRef cr;
  output Exp cref;
algorithm cref := matchcontinue(cr)
  local
    Type ty1,ty2;
    list<Subscript> subs;
  case(cr)
    equation
      (ty1 as DAE.ET_ARRAY(_,_)) = crefLastType(cr);
      subs = crefLastSubs(cr);
      ty2 = unliftArrayTypeWithSubs(subs,ty1);
    then
      DAE.CREF(cr,ty2);
  case(cr)
    equation
      ty1 = crefLastType(cr);
    then
      DAE.CREF(cr,ty1);
end matchcontinue;
end crefExp;

public function unliftArrayTypeWithSubs "
helper function for renameVarsToUnderlineVar2 unlifts array type as much as we have subscripts"
  input list<Subscript> subs;
  input Type ty;
  output Type oty;
algorithm  oty := matchcontinue(subs,ty)
  local
    list<Subscript> rest;
  case({},ty) then ty;
  case(_::rest, ty)
    equation
      ty = unliftArray(ty);
      ty = unliftArrayTypeWithSubs(rest,ty);
    then
      ty;
end matchcontinue;
end unliftArrayTypeWithSubs;

public function crefHaveSubs "Function: crefHaveSubs
	Checks whether Componentref has any subscripts, recursive "
  input ComponentRef icr;
  output Boolean ob;
algorithm ob := matchcontinue(icr)
  local ComponentRef cr; Boolean b; Ident str; Integer idx;
  case(DAE.CREF_QUAL(_,_,_ :: _, _)) then true;
  case(DAE.CREF_IDENT(_,_,_ :: _)) then true;
  case(DAE.CREF_IDENT(str,_,{})) // for stringified crefs!
    equation
      idx = System.stringFind(str, "["); // (-1 on failure)
      idx > 0 = true; // index should be more than 0!
    then true;
  case(DAE.CREF_QUAL(_,_,{}, cr))
    equation
      b = crefHaveSubs(cr);
    then b;
  case(_) then false;
end matchcontinue;
end crefHaveSubs;

public function subscriptContain "function: subscriptContain
	This function checks whether sub2 contains sub1 or not(DAE.WHOLEDIM)
"
  input list<Subscript> issl1;
  input list<Subscript> issl2;
  output Boolean contained;
algorithm
  contained := matchcontinue(issl1,issl2)
    local
      Boolean b;
      Subscript ss1,ss2;
      list<Subscript> ssl1,ssl2;
    case({},_) then true;
    case(ss1 ::ssl1, (ss2 as DAE.WHOLEDIM())::ssl2)
      equation
        b = subscriptContain(ssl1,ssl2);
      then b;
/*    case(ss1::ssl1, (ss2 as DAE.SLICE(exp)) ::ssl2)
      local Exp exp;
        equation
         b = subscriptContain(ssl1,ssl2);
        then
          b;
          */
    case((ss1 as DAE.INDEX(e1 as DAE.ICONST(i)))::ssl1, (ss2 as DAE.SLICE(e2 as DAE.ARRAY(_,_,expl))) ::ssl2)
      local Exp e1,e2; Integer i; list<Exp> expl;
        equation
        true = subscriptContain2(i,expl);
        b = subscriptContain(ssl1,ssl2);
      then
        b;
    case(ss1::ssl1,ss2::ssl2)
      equation
        true = subscriptEqual({ss1},{ss2});
        b = subscriptContain(ssl1,ssl2);
        then
          b;
    case(_,_) then false;
  end matchcontinue;
end subscriptContain;

protected function subscriptContain2 "
"
  input Integer inInt;
  input list<Exp> inExp2;
  output Boolean contained;
algorithm
  contained := matchcontinue(inInt,inExp2)
    local
      Boolean b,b2;
      Exp e1,e2;
      list<Exp> expl,expl2;
      Integer i,j;
      case(i,( (e1 as DAE.ICONST(j)) :: expl))
        equation
            true = (i == j);
          then
            true;
      case(i,(( e1 as DAE.ICONST(j)) :: expl))
        equation
            true = subscriptContain2(i,expl);
          then
            true;
      case(i,( (e1 as DAE.ARRAY(_,_,expl2)) :: expl))
        equation
          b = subscriptContain2(i,expl2);
          b2 = subscriptContain2(i,expl);
          b = Util.boolOrList({b,b2});
        then
          b;
      case(_,_) then false;
  end matchcontinue;
end subscriptContain2;

public function subscriptDimensions "Function: subscriptDimensions
Returns the dimensionality of the subscript expression
"
  input list<Subscript> insubs;
  output list<DAE.Dimension> oint;
algorithm oint := matchcontinue(insubs)
  local
    Subscript ss;
    list<Subscript> subs;
    list<Exp> expl;
    Integer x;
    list<DAE.Dimension> recursive;
    DAE.Exp e;

  case ({}) then {};
    
  case ((ss as DAE.INDEX(DAE.ICONST(x)))::subs) 
    equation
      recursive = subscriptDimensions(subs);
    then 
      DAE.DIM_INTEGER(x):: recursive;      
    
  case ((ss as DAE.WHOLEDIM) :: subs)
    equation
      recursive = subscriptDimensions(subs);
    then
      DAE.DIM_UNKNOWN :: recursive;

  case ((ss as DAE.INDEX(exp = e)) :: subs)
    equation
      recursive = subscriptDimensions(subs);
    then
      DAE.DIM_EXP(e) :: recursive;
       
  case (ss :: subs)
    local String sub_str;
    equation
      true = RTOpts.debugFlag("failtrace");
      sub_str = subscriptString(ss);
      Debug.fprintln("failtrace", "- Exp.subscriptDimensions failed on " +& sub_str);
    then
      fail();
end matchcontinue;
end subscriptDimensions;

public function crefNotPrefixOf "negation of crefPrefixOf"
 input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean outBoolean;
algorithm  
  outBoolean := matchcontinue(cr1, cr2)
    // first is qualified, second is an unqualified ident, return false!
    case (DAE.CREF_QUAL(ident = _), DAE.CREF_IDENT(ident = _)) then true;
    case (cr1, cr2) then (not crefPrefixOf(cr1,cr2));
  end matchcontinue;
end crefNotPrefixOf;

public function isArray " function: isArray
returns true if expression is an array.
"
  input Exp inExp;
  output Boolean outB;
algorithm
  outB := matchcontinue(inExp)
    case(DAE.ARRAY(array = _ )) then true;
    case(_) then false;
  end matchcontinue;
end isArray;

public function isMatrix " function: isArray
returns true if expression is an array.
"
  input Exp inExp;
  output Boolean outB;
algorithm
  outB := matchcontinue(inExp)
    case(DAE.MATRIX(scalar = _ )) then true;
    case(_) then false;
  end matchcontinue;
end isMatrix;


public function isUnary " function: isArray
returns true if expression is an array.
"
  input Exp inExp;
  output Boolean outB;
algorithm
  outB:=
  matchcontinue(inExp)
    local
      Exp exp1;
    case(exp1 as DAE.UNARY(operator =_))
      then
        true;
    case(_)
    then
      false;
  end matchcontinue;
end isUnary;

public function isCref "
Author: BZ 2008-06, checks wheter an exp is cref or not."
  input Exp inExp;
  output Boolean outB;
algorithm outB:= matchcontinue(inExp)
    case(DAE.CREF(_,_)) then true;
    case(_) then false;
  end matchcontinue;
end isCref;

public function crefAppend "
Author BZ
function for appending two cref
append (a.b, r.q.t) ==> a.b.r.q.t"
  input ComponentRef cr1,cr2;
  output ComponentRef cr3;
algorithm
  cr3 := matchcontinue(cr1,cr2)
    local
      String name;
      Type ty;
      list<Subscript> subs;
      ComponentRef child,merge;

    case(DAE.CREF_IDENT(name,ty,subs), cr2) then DAE.CREF_QUAL(name,ty,subs,cr2);
    case(DAE.CREF_QUAL(name,ty,subs,child), cr2)
      equation
        merge = crefAppend(child,cr2);
      then
        DAE.CREF_QUAL(name,ty,subs,merge);
  end matchcontinue;
end crefAppend;

public function isCrefArray "Function isCrefArray
Checks wheter a cref is an array or not.
"
  input Exp inExp;
  output Boolean outB;
algorithm
  outB:=
  matchcontinue(inExp)
    local
      Exp exp1;
    case(exp1 as DAE.CREF(_,DAE.ET_ARRAY(_,_)))
    then
      true;
    case(_)
    then
      false;
  end matchcontinue;
end isCrefArray;

public function isCrefScalar
  "Checks whether an expression is a scalar cref or not."
  input Exp inExp;
  output Boolean isScalar;
algorithm
  isScalar := matchcontinue(inExp)
    case DAE.CREF(ty = DAE.ET_ARRAY(ty = _))
      local ComponentRef cr; Boolean b;
      equation
        cr = expCref(inExp);
        b = crefHasScalarSubscripts(cr);
      then
        b;
    case DAE.CREF(ty = _) then true;
    case _ then false;
  end matchcontinue;
end isCrefScalar;

public function expCanBeZero "Returns true if it is possible that the expression can be zero.

For instance,
expCanBeZero(1) => false
expCanBeZero(a+b) => true  (for a = -b)
expCanBeZero(1+a^2) => false (all terms positive)
"
  input Exp e;
  output Boolean canBeZero;
algorithm
  canBeZero := matchcontinue(e)
    local list<Exp> terms;

    case(e) equation
      true = isConst(e) and not isZero(e);
    then false;

      /* For several terms, all must be positive or zero and at least one must be > 0 */
    case(e) equation
      (terms as _::_) = terms(e);
      true = Util.boolAndList(Util.listMap(terms,expIsPositiveOrZero));
      _::_ = Util.listSelect(terms,expIsPositive);
    then false;

    case(e) then true;
  end matchcontinue;
end expCanBeZero;

public function expIsPositive "Returns true if an expression is positive,
Returns true in the following cases:
constant >= 0

See also expIsPositiveOrZero.
"
  input Exp e;
  output Boolean res;
algorithm
  res := matchcontinue(e)
    local Exp e1,e2;

     /* constant >= 0 */
    case(e) equation
      true = isConst(e);
      false = expReal(e) <. intReal(0);
    then true;

    case(_) then false;
  end matchcontinue;
end expIsPositive;


public function expIsPositiveOrZero "Returns true if an expression is positive or equal to zero,
Returns true in the following cases:
constant >= 0
a^n, for even n.
abs(expr)
"
  input Exp e;
  output Boolean res;
algorithm
  res := matchcontinue(e)
    local Exp e1,e2;

     /* constant >= 0 */
    case(e) equation
      true = isConst(e);
      false = expReal(e) <. intReal(0);
    then true;

      /* e1 ^ n for even n */
    case(DAE.BINARY(e1,DAE.POW(_),e2)) equation
      true = isEven(e2);
    then true;

    /* expr * expr */
    case(DAE.BINARY(e1,DAE.MUL(_),e2)) equation
      true = expEqual(e1,e2);
    then true;
    case(_) then false;
  end matchcontinue;
end expIsPositiveOrZero;

public function isEven "returns true if expression is even"
  input Exp e;
  output Boolean even;
algorithm
  even := matchcontinue(e)
  local Integer i;
    case(DAE.ICONST(i)) equation
     0 = intMod(i,2);
    then true;
    case(_) then false;
  end matchcontinue;
end isEven;

public function realIfRealInArray "function: realIfRealInArray
this function takes a list of numbers. If one of them is a real, type real is returned.
Otherwise Inteteger. Fails on other types."
  input list<Exp> inExps;
  output Type otype;
algorithm otype := matchcontinue(inExps)
  local
    Exp e1,e2;
    list<Exp> expl;
    Type ty,rty;
    case({}) then DAE.ET_INT();
  case( e1 :: expl)
    equation
      (ty as DAE.ET_INT()) = typeof(e1);
      rty = realIfRealInArray(expl);
      then
        rty;
  case(e1 :: expl)
    equation
    (ty as DAE.ET_REAL()) = typeof(e1);
      rty = realIfRealInArray(expl);
    then
      ty;
  case(_)
    equation
    Debug.fprint("failtrace"," realIfRealInArray got non array/real Expressions \n");
    then
      fail();
  end matchcontinue;
end realIfRealInArray;

protected function crOrDerCr "returns the component reference of CREF or der(CREF)"
  input Exp exp;
  output ComponentRef cr;
algorithm
  cr := matchcontinue(exp)
    case(DAE.CREF(cr,_)) then cr;
    case(DAE.CALL(path=Absyn.IDENT("der"),expLst = {DAE.CREF(cr,_)})) then cr;
  end matchcontinue;
end crOrDerCr;

protected function crOrDerCrExp
  input Exp exp;
  output Exp cr_exp;
algorithm
  cr_exp := matchcontinue(exp)
    local DAE.Exp e;  
    case (DAE.CREF(componentRef = _)) then exp;
    case (DAE.CALL(path = Absyn.IDENT("der"))) then exp;
    //case (DAE.CALL(path = Absyn.IDENT("der"), expLst = {e as DAE.CREF(componentRef = _)})) then e;
  end matchcontinue;
end crOrDerCrExp;

public function replaceCrefSliceSub "
Go trough ComponentRef searching for a slice eighter in
qual's or finaly ident. if none find, add dimension to DAE.CREF_IDENT(,ss:INPUTARG,)"
  input ComponentRef inCr;
  input list<Subscript> newSub;
  output ComponentRef outCr;
algorithm outCr := matchcontinue(inCr,newSub)
  local
    Type t2,identType;
    ComponentRef child;
    list<Subscript> subs;
    String name, str1, str2, str;

  // debugging case, uncomment for enabling
  // case(child,newSub)
  //  equation
  //    str1 = printComponentRefStr(child);
  //    str2 = Util.stringDelimitList(Util.listMap(newSub, printSubscriptStr), ", ");
  //    str  = "Exp.replaceCrefSliceSub(" +& str1 +& " subs: [" +& str2 +& "]\n";
  //    print(str);
  //  then
  //    fail();

  // Case where we try to find a Exp.DAE.SLICE()
  case(DAE.CREF_IDENT(name,identType,subs),newSub)
    equation
      subs = replaceSliceSub(subs, newSub);
    then
      DAE.CREF_IDENT(name,identType,subs);

  // case where there is not existant Exp.DAE.SLICE() as subscript
  case( child as DAE.CREF_IDENT(identType  = t2, subscriptLst = subs),newSub)
    equation
      true = (listLength(arrayTypeDimensions(t2)) >= (listLength(subs)+1));
      child = subscriptCref(child,newSub);
    then
      child;

  case( child as DAE.CREF_IDENT(identType  = t2, subscriptLst = subs),newSub)
    equation
      false = (listLength(arrayTypeDimensions(t2)) >= (listLength(subs)+listLength(newSub)));
      child = subscriptCref(child,newSub);
      Debug.fprintln("failtrace", "WARNING - Exp.replaceCref_SliceSub setting subscript last, not containing dimension");
    then
      child;

  // Try DAE.CREF_QUAL with DAE.SLICE subscript
  case(DAE.CREF_QUAL(name,identType,subs,child),newSub)
    equation
      subs = replaceSliceSub(subs, newSub);
    then
      DAE.CREF_QUAL(name,identType,subs,child);

  // case where there is not existant Exp.DAE.SLICE() as subscript in CREF_QUAL
  case(DAE.CREF_QUAL(name,identType,subs,child),newSub)
    equation
      true = (listLength(arrayTypeDimensions(identType)) >= (listLength(subs)+1));
      subs = listAppend(subs,newSub);
    then
      DAE.CREF_QUAL(name,identType,subs,child);

  // DAE.CREF_QUAL without DAE.SLICE, search child
  case(DAE.CREF_QUAL(name,identType,subs,child),newSub)
    equation
      child = replaceCrefSliceSub(child,newSub);
    then
      DAE.CREF_QUAL(name,identType,subs,child);

  case(_,_)
    equation
      Debug.fprint("failtrace", "- Exp.replaceCref_SliceSub failed\n ");
    then
      fail();
end matchcontinue;
end replaceCrefSliceSub;

protected function replaceSliceSub "
A function for replacing any occurance of DAE.SLICE or DAE.WHOLEDIM with new sub."
  input list<Subscript> inSubs;
  input list<Subscript> inSub;
  output list<Subscript> osubs;
algorithm
  osubs := matchcontinue(inSubs,inSub)
    local
      list<Subscript> subs;
      Subscript sub;
    case((sub as DAE.SLICE(_))::subs,inSub)
      equation
        subs = listAppend(inSub,subs);
      then
        subs;
    // adrpo, 2010-02-23:
    //   WHOLEDIM is *also* a special case of SLICE
    //   that contains the all subscripts, so we need
    //   to handle that too here!
    case((sub as DAE.WHOLEDIM())::subs,inSub)
      equation
        subs = listAppend(inSub,subs);
      then
        subs;
    case((sub)::subs,inSub)
      equation
        subs = replaceSliceSub(subs,inSub);
      then
        (sub::subs);
  end matchcontinue;
end replaceSliceSub;

protected function dumpSimplifiedExp
"a function to dump simplified expressions"
  input Exp inExp;
  input Exp outExp;
algorithm
  _ := matchcontinue(inExp,outExp)
    case(inExp,outExp) equation
      true = expEqual(inExp,outExp);
      then ();
    case(inExp,outExp) equation
      false= expEqual(inExp,outExp);
      print(printExpStr(inExp));print( " simplified to "); print(printExpStr(outExp));print("\n");
      then ();
  end matchcontinue;
end dumpSimplifiedExp;

public function simplify1time "simplify1 with timing"
  input Exp e;
  output Exp outE;
protected
  Real t1,t2;
algorithm
  t1 := clock();
  outE := simplify1(e);
  t2 := clock();
  print(Util.if_(t2 -. t1 >. 0.01,"simplify1 took "+&realString(t2 -. t1)+&" seconds for exp: "+&printExpStr(e)+& " \nsimplified to :"+&printExpStr(outE)+&"\n",""));
end simplify1time;

public function boolExp "returns the boolean constant expression of a BOOL"
input Exp e;
output Boolean b;
algorithm
  b := matchcontinue(e)
    case(DAE.BCONST(b)) then b;
  end matchcontinue;
end boolExp;

protected function simplifyVectorScalarMatrix "Help function to simplifyVectorScalar,
handles MATRIX expressions"
  input list<list<tuple<Exp, Boolean>>> mexpl;
  input Operator op;
  input Exp s1;
  input Boolean arrayScalar "if true, array op scalar, otherwise scalar op array";
  output list<list<tuple<Exp, Boolean>>> outExp;
algorithm
  outExp := matchcontinue(mexpl,op,s1,arrayScalar)
  local list<tuple<Exp, Boolean>> row;
    case({},op,s1,arrayScalar) then {};
    case(row::mexpl,op,s1,arrayScalar) equation
      row = simplifyVectorScalarMatrixRow(row,op,s1,arrayScalar);
      mexpl = simplifyVectorScalarMatrix(mexpl,op,s1,arrayScalar);
    then row::mexpl;
  end matchcontinue;
end simplifyVectorScalarMatrix;

protected function simplifyVectorScalarMatrixRow "Help function to simplifyVectorScalarMatrix,
handles MATRIX row"
  input list<tuple<Exp, Boolean>> row;
  input Operator op;
  input Exp s1;
  input Boolean arrayScalar "if true, array op scalar, otherwise scalar op array";
  output list<tuple<Exp, Boolean>> outExp;
algorithm
  outExp := matchcontinue(row,op,s1,arrayScalar)
  local Exp e; Boolean scalar;
    case({},op,s1,arrayScalar) then {};
      /* array op scalar */
    case((e,scalar)::row,op,s1,true) equation
      row = simplifyVectorScalarMatrixRow(row,op,s1,true);
    then ((DAE.BINARY(e,op,s1),scalar)::row);

    /* scalar op array */
    case((e,scalar)::row,op,s1,false) equation
      row = simplifyVectorScalarMatrixRow(row,op,s1,false);
    then ((DAE.BINARY(s1,op,e),scalar)::row);
  end matchcontinue;
end simplifyVectorScalarMatrixRow;

protected function removeOperatorDimension "Function: removeOperatorDimension
Helper function for simplifyVectorBinary, removes an dimension from the operator.
"
  input Operator inop;
  output Operator outop;
algorithm outop := matchcontinue(inop)
  local Type ty1,ty2;
    String str;
  case( DAE.ADD(ty=ty1)) equation ty2 = unliftArray(ty1); then DAE.ADD(ty2);
  case( DAE.SUB(ty=ty1)) equation ty2 = unliftArray(ty1); then DAE.SUB(ty2);
end matchcontinue;
end removeOperatorDimension;

protected function simplifyBinarySortConstantsMul
"Helper relation to simplifyBinarySortConstants"
  input Exp inExp;
  output Exp outExp;
 protected list<Exp> e_lst, e_lst_1,const_es1,const_es1_1,notconst_es1;
  Exp res1,res2;
algorithm
  e_lst  := factors(inExp);
  e_lst_1 := Util.listMap(e_lst,simplify2); // simplify2 for recursive
  const_es1 := Util.listSelect(e_lst_1, isConst);
  notconst_es1 := Util.listSelect(e_lst_1, isNotConst);
  const_es1_1 := simplifyBinaryMulConstants(const_es1);
  res1 := simplify1(makeProductLst(const_es1_1)); // simplify1 for basic constant evaluation.
  res2 := makeProductLst(notconst_es1); // Cannot simplify this, if const_es1_1 empty => infinite recursion.
  outExp := makeProductLst({res1,res2});
end simplifyBinarySortConstantsMul;

public function makeNoEvent " adds a noEvent call around an expression"
input Exp e1;
output Exp res;
algorithm
  res := DAE.CALL(Absyn.IDENT("noEvent"),{e1},false,true,DAE.ET_BOOL(),DAE.NO_INLINE);
end makeNoEvent;

public function makeNestedIf "creates a nested if expression given a list of conditions and
guared expressions and a default value (the else branch)"
  input list<Exp> conds "conditions";
  input list<Exp> tbExps " guarded expressions, for each condition";
  input Exp fExp "default value, else branch";
  output Exp ifExp;
algorithm
  ifExp := matchcontinue(conds,tbExps,fExp)
  local Exp c,tbExp;
    case({c},{tbExp},fExp)
    then DAE.IFEXP(c,tbExp,fExp);
    case(c::conds,tbExp::tbExps,fExp) equation
      ifExp = makeNestedIf(conds,tbExps,fExp);
    then DAE.IFEXP(c,tbExp,ifExp);
  end matchcontinue;
end makeNestedIf;

public function makeDiv "Takes two expressions and create a division"
  input Exp e1;
  input Exp e2;
  output Exp res;
algorithm
  res := matchcontinue(e1,e2)
    local
      Type etp;
      Boolean scalar;
      Operator op;
    case(e1,e2) equation
      true = isZero(e1);
    then e1;
    case(e1,e2) equation
      true = isOne(e2);
    then e1;
    case(e1,e2) equation
      etp = typeof(e1);
      scalar = DAEUtil.expTypeArray(etp);
      op = Util.if_(scalar,DAE.DIV_ARRAY_SCALAR(etp),DAE.DIV(etp));
    then DAE.BINARY(e1,op,e2);
  end matchcontinue;
end makeDiv;

public function printArraySizes "Function: printArraySizes
"
input list<Option <Integer>> inLst;
output String out;
algorithm
  out := matchcontinue(inLst)
  local
    Integer x;
    list<Option<Integer>> lst;
    String s,s2;
    case({}) then "";
    case(SOME(x) :: lst)
      equation
      s = printArraySizes(lst);
      s2 = intString(x);
      s = Util.stringAppendList({s2, s});
      then s;
    case(_ :: lst)
      equation
      s = printArraySizes(lst);
      then s;
end matchcontinue;
end printArraySizes;

public function tmpPrint "
"
input list<Option <Integer>> inLst;

algorithm
  _ := matchcontinue(inLst)
  local
    Integer x;
    list<Option<Integer>> lst;
    case({}) then ();
    case(SOME(x) :: lst)
      equation
      print(intString(x));print(" ,");
      tmpPrint(lst);
      then ();
    case(_ :: lst)
      equation
      tmpPrint(lst);
      then ();
end matchcontinue;
end tmpPrint;

public function unliftArrayX "Function: unliftArrayX
Unlifts a type with X dimensions...
"
  input Type inType;
  input Integer x;
  output Type outType;
algorithm outType := matchcontinue(inType,x)
  local Type ty;
  case(inType,0) then inType;
  case(inType,x)
    equation
      ty = unliftArray(inType);
      then
        unliftArrayX(ty,x-1);
end matchcontinue;
end unliftArrayX;

public function liftArrayR "
function liftArrayR
Converts a type into an array type with dimension n as first dim"
  input Type tp;
  input DAE.Dimension n;
  output Type outTp;
algorithm
  outTp := matchcontinue(tp,n)
    local
      Type elt_tp,tp;
      list<DAE.Dimension> dims;

    case(DAE.ET_ARRAY(elt_tp,dims),n)
      equation
      dims = listAppend({n},dims);
      then DAE.ET_ARRAY(elt_tp,dims);

    case(tp,n)
    then DAE.ET_ARRAY(tp,{n});

  end matchcontinue;
end liftArrayR;

public function typeOfString
"function typeOfString
  Retrieves the Type of the Expression as a String"
  input Exp inExp;
  output String str;
  Type ty;
  String str;
algorithm
    ty := typeof(inExp);
    str := typeString(ty);
end typeOfString;

public function isIntegerOrReal "Returns true if Type is Integer or Real"
input Type tp;
output Boolean res;
algorithm
  res := matchcontinue(tp)
    case(DAE.ET_REAL()) then  true;
    case(DAE.ET_INT()) then true;
    case(_) then false;
  end matchcontinue;
end isIntegerOrReal;

protected function isInverseCref " Returns true if expression is 1/cr for a ComponentRef cr"
input Exp e;
input ComponentRef cr;
output Boolean res;
algorithm
  res := matchcontinue(e,cr)
  local ComponentRef cr2; Exp e1;
    case(DAE.BINARY(e1,DAE.DIV(_),DAE.CREF(componentRef = cr2)),cr)equation
        true = crefEqual(cr,cr2);
        true = isConstOne(e1);
    then true;
    case(_,_) then false;
  end matchcontinue;
end isInverseCref;

public function traverseExpList
"function traverseExpList
 author PA:
 Calls traverseExp for each element of list. (Earier used Util.foldListMap for this, which was a bug)"
 input list<Exp> expl;
  input funcType rel;
  input Type_a ext_arg;
  output tuple<list<Exp>, Type_a> outTpl;
  partial function funcType
    input tuple<Exp, Type_a> tpl1;
    output tuple<Exp, Type_a> tpl2;
    replaceable type Type_a subtypeof Any;
  end funcType;
  replaceable type Type_a subtypeof Any;
algorithm
  outTpl := matchcontinue(expl,rel,ext_arg)
  local Exp e,e1; list<Exp> expl1;
    case({},rel,ext_arg) then (({},ext_arg));
    case(e::expl,rel,ext_arg) equation
      ((e1,ext_arg)) = traverseExp(e, rel, ext_arg);
      ((expl1,ext_arg)) = traverseExpList(expl,rel,ext_arg);
    then ((e1::expl1,ext_arg));
  end matchcontinue;
end traverseExpList;

public function traverseExpOpt "Calls traverseExp for SOME(exp) and does nothing for NONE"
  input Option<Exp> inExp;
  input FuncExpType func;
  input Type_a inTypeA;
  output tuple<Option<Exp>, Type_a> outTpl;
  partial function FuncExpType
    input tuple<Exp, Type_a> inTpl;
    output tuple<Exp, Type_a> outTpl;
    replaceable type Type_a subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  outTpl:= matchcontinue (inExp,func,inTypeA)
  local Exp e;
    case(NONE,_,inTypeA) then ((NONE,inTypeA));
    case(SOME(e),func,inTypeA) equation
      ((e,inTypeA)) = traverseExp(e,func,inTypeA);
     then ((SOME(e),inTypeA));
  end matchcontinue;
end traverseExpOpt;

public function expReal "returns the real value if expression is constant Real"
  input Exp exp;
  output Real r;
algorithm
  r := matchcontinue(exp) local Integer i;
    case(DAE.RCONST(r)) then r;
    case(DAE.ICONST(i)) then intReal(i);
    case(DAE.CAST(_,DAE.ICONST(i))) then intReal(i);
  end matchcontinue;
end expReal;

public function expInt "returns the int value if expression is constant Integer"
	input Exp exp;
	output Integer i;
algorithm
	i := matchcontinue(exp) local Integer i2;
    case (DAE.ICONST(integer = i2)) then i2;
    case (DAE.ENUM_LITERAL(index = i2)) then i2;
	end matchcontinue;
end expInt;

public function isExpCrefOrIfExp
"Returns true if expression is a componentRef or an if expression"
  input Exp e;
  output Boolean res;
algorithm
  res := matchcontinue(e)
    case(DAE.CREF(_,_)) then true;
    case(DAE.IFEXP(_,_,_)) then true;
    case(_) then false;
  end matchcontinue;
end isExpCrefOrIfExp;


public function isExpCref
"Returns true if expression is a componentRef"
  input Exp e;
  output Boolean res;
algorithm
  res := matchcontinue(e)
    case(DAE.CREF(_,_)) then true;
    case(_) then false;
  end matchcontinue;
end isExpCref;

public function expCrefInclIfExpFactors
"function: expCrefInclIfExpFactors
  Returns the componentref if exp is a CREF, or the factors of CREF if expression is an if expression.
  This is used in e.g. the tearing algorithm to detect potential division by zero in
  expressions like 1/(if b then 1.0 else x) which could lead to division by zero if b is false and x is 0; "
  input Exp inExp;
  output list<ComponentRef> outComponentRefs;
algorithm
  outComponentRefs:=
  matchcontinue (inExp)
    local ComponentRef cr; Exp c,tb,fb;
      list<Exp> f;
      list<ComponentRef> crefs;
    case (DAE.CREF(componentRef = cr)) then {cr};
    case(DAE.IFEXP(c,tb,fb)) equation
      f = Util.listSelect(listAppend(factors(tb),factors(fb)),isExpCref);
      crefs = Util.listMap(f,expCref);
    then crefs;
  end matchcontinue;
end expCrefInclIfExpFactors;

public function arrayContainZeroDimension " function containZeroDimension
Check wheter an arrayDim contains a zero dimension or not.
"
input list<DAE.Dimension> inDim;
output Boolean zero;

algorithm
  zero :=
  matchcontinue(inDim)
    local
      DAE.Dimension d;
      list<DAE.Dimension> iLst;
      Integer x;
      Boolean retVal;
    case({}) then true;

    case (DAE.DIM_UNKNOWN :: iLst)
      equation
        retVal = arrayContainZeroDimension(iLst);
      then
        retVal;

    case (d :: iLst)
      equation
        false = (dimensionSize(d) >= 1);
        retVal = arrayContainZeroDimension(iLst);
      then
        retVal;

    case(_) then false;
end matchcontinue;
end arrayContainZeroDimension;

public function arrayContainWholeDimension
  "Checks if a list of dimensions contain a wholedim, i.e. NONE."
  input list<DAE.Dimension> inDim;
  output Boolean wholedim;
algorithm
  wholedim := matchcontinue(inDim)
    local
      input list<DAE.Dimension> rest_dims;
    case ({}) then false;
    case (DAE.DIM_UNKNOWN :: rest_dims) then true;
    case (_ :: rest_dims) then arrayContainZeroDimension(rest_dims);
  end matchcontinue;
end arrayContainWholeDimension;

public function crefHasScalarSubscripts "returns true if the subscripts of the cref results in a scalar variable.
For example given Real x[3,3]
  x[1,2] has scalar subscripts
  x[1] has not scalar subscripts
  x[:,1] has not scalar subscripts
  x[{1,2},1] has not scalar subscripts
"
  input ComponentRef cr;
  output Boolean hasScalarSubs;
algorithm
  hasScalarSubs := matchcontinue(cr)
  local 
    list<Subscript> subs;
    DAE.ExpType tp;
    list<DAE.Dimension> dims;
    
    /* No subscripts */
    case(cr) equation {} = crefLastSubs(cr); then true;
      
      /* constant Subscripts that match type => true */ 
    case(cr) equation
      (subs as (_::_))= crefLastSubs(cr);
      true = subscriptConstants(subs);
      tp = crefLastType(cr);
      dims = arrayDimension(tp);
      // Since all subscripts are constants, sufficient to compare length of dimensions
      // Dimensions may be removed when a component is instantiated if it has
      // constant subscripts though, so it may have more subscripts than
      // dimensions.
      true = listLength(dims) <= listLength(subs);
    then true;
      
      /* All other cases are false */
    case(cr) then false;
  end matchcontinue;
end crefHasScalarSubscripts;

protected function subscriptConstants "returns true if all subscripts are constant values (no slice or wholedim "
  input list<Subscript> subs;
  output Boolean areConstant;
algorithm
  areConstant := matchcontinue(subs)
    case({}) then true;
    case(DAE.INDEX(exp = DAE.ICONST(integer = _)):: subs) 
      equation
        areConstant = subscriptConstants(subs);
      then 
        areConstant;
    case(DAE.INDEX(exp = DAE.ENUM_LITERAL(index = _)) :: subs)
      equation
        areConstant = subscriptConstants(subs);
      then
        areConstant;
    case(_) then false;
  end matchcontinue;
end subscriptConstants;

public function containWholeDim " A function to check if a cref contains a [:] wholedim element in the subscriptlist.
"
  input ComponentRef inRef;
  output Boolean wholedim;

algorithm
  wholedim :=
  matchcontinue(inRef)
    local
      ComponentRef cr;
      list<Subscript> ssl;
      Ident name;
      Type ty;
    case(DAE.CREF_IDENT(name,ty,ssl))
      equation
        wholedim = containWholeDim2(ssl,ty);
      then
        wholedim;
    case(DAE.CREF_QUAL(name,ty,ssl,cr))
      equation
        wholedim = containWholeDim(cr);
      then
        wholedim;
    case(_) then false;
  end matchcontinue;
end containWholeDim;

public function containWholeDim2 " A function to check if a cref contains a [:] wholedim element in the subscriptlist.
"
  input list<Subscript> inRef;
  input Type inType;
  output Boolean wholedim;

algorithm
  wholedim :=
  matchcontinue(inRef,inType)
    local
      Subscript ss;
      list<Subscript> ssl;
      Ident name;
      Boolean b;
      Type tty;
      list<DAE.Dimension> ad;
    case({},_) then false;
    case((ss as DAE.WHOLEDIM())::ssl,DAE.ET_ARRAY(tty,ad))
    then
      true;
    case((ss as DAE.SLICE(es1))::ssl, DAE.ET_ARRAY(tty,ad))
      local Exp es1;
      equation
        true = containWholeDim3(es1,ad);
      then
        true;
    case(_::ssl,DAE.ET_ARRAY(tty,ad))
      equation
        ad = Util.listStripFirst(ad);
        b = containWholeDim2(ssl,DAE.ET_ARRAY(tty,ad));
      then b;
    case(_::ssl,inType)
      equation
        wholedim = containWholeDim2(ssl,inType);
      then
        wholedim;
  end matchcontinue;
end containWholeDim2;

protected function containWholeDim3 "Function: containWholeDim3
Verify that a slice adresses all dimensions"
input Exp inExp;
input list<DAE.Dimension> ad;
output Boolean ob;
algorithm ob := matchcontinue(inExp,ad)
  local
    list<Exp> expl;
    Integer x1,x2;
    DAE.Dimension d;
  case(DAE.ARRAY(array=expl), d :: _)
    equation
      x1 = listLength(expl);
      x2 = dimensionSize(d);
      true = intEq(x1, x2);
    then
      true;
  case(_,_)
    then false;
  end matchcontinue;
end containWholeDim3;

protected function elaborateCrefQualType "Function: elaborateCrefQualType
helper function for stringifyComponentRef. When having a complex type, we
are only interested in the dimensions of the comlpex var but the new type
we want is located in the IDENT.

Currently, we do not extract type information from quals,
Codegen has no support for that yet.
DAE.CREF_QUAL(a,DAE.ARRAY(REAL,5),{},DAE.CREF_IDENT(B,DAE.ARRAY(REAL,5),{})).b[:]) would translate do
DAE.CREF_IDENT($a$pb,DAE.ARRAY(REAL,5,5),{}) which is not the same thing.

This function also gives a failtrace-> warning when we have an Exp.DAE.ET_OTHER() type in a qual."
  input ComponentRef inRef;
  output Type otype;
algorithm otype := matchcontinue(inRef)
  local Type ty; ComponentRef cr;
  case(DAE.CREF_IDENT(_, ty,_)) then ty;
  case(DAE.CREF_QUAL(_,DAE.ET_COMPLEX(varLst=_),_,cr)) then elaborateCrefQualType(cr);
  case(DAE.CREF_QUAL(_,DAE.ET_ENUMERATION(index=NONE()),_,cr)) then elaborateCrefQualType(cr);
  case(DAE.CREF_QUAL(id,DAE.ET_OTHER(),_,cr))
    local String id,s;
    equation
      Debug.fprint("failtrace", "- **WARNING** Exp.elaborateCrefQualType caught an Exp.DAE.ET_OTHER() type: ");
      s = printComponentRefStr(DAE.CREF_QUAL(id,DAE.ET_OTHER(),{},cr));
      Debug.fprint("failtrace", s);
      Debug.fprint("failtrace", "\n");
    then elaborateCrefQualType(cr);
  case(DAE.CREF_QUAL(_,ty,_,cr)) then ty;
end matchcontinue;
end elaborateCrefQualType;

public function crefLastType "returns the 'last' type of a cref.

For instance, for the cref 'a.b' it returns the type in identifier 'b'
"
  input ComponentRef inRef;
  output Type res;
algorithm
  res :=
  matchcontinue (inRef)
    local
      Type t2; ComponentRef cr;
      case(inRef as DAE.CREF_IDENT(_,t2,_))
        then
          t2;
      case(inRef as DAE.CREF_QUAL(_,_,_,cr))
        then
          crefLastType(cr);
  end matchcontinue;
end crefLastType;

public function crefSetLastType "
sets the 'last' type of a cref.
"
  input ComponentRef inRef;
  input Type newType;
  output ComponentRef outRef;
algorithm outRef := matchcontinue (inRef,newType)
    local
      Type ty;
      ComponentRef child;
      list<Subscript> subs;
      String id;
      case(DAE.CREF_IDENT(id,_,subs),newType)
        then
          DAE.CREF_IDENT(id,newType,subs);
      case(DAE.CREF_QUAL(id,ty,subs,child),newType)
        equation
          child = crefSetLastType(child,newType);
        then
          DAE.CREF_QUAL(id,ty,subs,child);
  end matchcontinue;
end crefSetLastType;

public function crefTypeConsiderSubs "Function: crefTypeConsiderSubs 
Author: PA
Function for extracting the type out of a componentReference and consider the influence of the last subscript list. 
For exampel. If the last cref type is Real[3,3] and the last subscript list is {Exp.INDEX(1)}, the type becomes Real[3], i.e
one dimension is lifted.
See also, crefType.
"
  input ComponentRef cr;
  output Type res;
algorithm 
 res := unliftArrayTypeWithSubs(crefLastSubs(cr),crefLastType(cr));
end crefTypeConsiderSubs;

public function crefType "Function: crefType 
Function for extracting the type out of a componentReference. 
"
  input ComponentRef inRef;
  output Type res;
algorithm
  res :=
  matchcontinue (inRef)
    local
      Type t2;
      case(inRef as DAE.CREF_IDENT(_,t2,_)) then t2;
      case(inRef as DAE.CREF_QUAL(_,t2,_,_)) then t2;
      case(cr)
        local ComponentRef cr;String s;
        equation
					true = RTOpts.debugFlag("failtrace");
          Debug.fprint("failtrace", "-Exp.crefType failed on Cref:");
          s = printComponentRefStr(cr);
          Debug.fprint("failtrace", s);
          Debug.fprint("failtrace", "\n");
        then
          fail();
  end matchcontinue;
end crefType;

public function crefNameType "Function: crefType
Function for extracting the name and type out of a componentReference.
"
  input ComponentRef inRef;
  output String id;
  output Type res;
algorithm
  (id,res) :=
  matchcontinue (inRef)
    local
      Type t2;
      String name;
      case(inRef as DAE.CREF_IDENT(name,t2,_))
        then
          (name,t2);
      case(inRef as DAE.CREF_QUAL(name,t2,_,_))
        then
          (name,t2);
      case(cr)
        local ComponentRef cr;String s;
        equation
					true = RTOpts.debugFlag("failtrace");
          Debug.fprint("failtrace", "-Exp.crefType failed on Cref:");
          s = printComponentRefStr(cr);
          Debug.fprint("failtrace", s);
          Debug.fprint("failtrace", "\n");
        then
          fail();
  end matchcontinue;
end crefNameType;

public function expSub
"function: expMul
  author: PA
  Subtracts two scalar expressions."
  input Exp e1;
  input Exp e2;
  output Exp outExp;
  Type tp;
  Boolean b;
  Operator op;
algorithm
  tp := typeof(e1);
  b := DAEUtil.expTypeArray(tp);
  op := Util.if_(b,DAE.SUB_ARR(tp),DAE.SUB(tp));
  outExp := DAE.BINARY(e1,op,e2);
end expSub;

public function expDiv "
function expDiv
  author: PA
  Divides two scalar expressions."
  input Exp e1;
  input Exp e2;
  output Exp outExp;
  Type tp;
  Boolean b;
  Operator op;  
algorithm
  tp := typeof(e1);
  b := DAEUtil.expTypeArray(tp);
  op := Util.if_(b,DAE.DIV_ARR(tp),DAE.DIV(tp));
  outExp := DAE.BINARY(e1,op,e2);
end expDiv;

public function expLn
"function expLn
  author: PA
  Takes the natural logarithm of an expression."
  input Exp e1;
  output Exp outExp;
  Type tp;
algorithm
  tp := typeof(e1);
  outExp := DAE.CALL(Absyn.IDENT("log"),{e1},false,true,tp,DAE.NO_INLINE);
end expLn;

public function extractCrefsFromExp "
Author: BZ 2008-06, Extracts all ComponentRef from an exp.
"
input Exp inExp;
output list<ComponentRef> ocrefs;
algorithm ocrefs := matchcontinue(inExp)
  case(inExp)
    local list<ComponentRef> crefs;
    equation
      ((_,crefs)) = traverseExp(inExp, traversingComponentRefFinder, {});
      then
        crefs;
  end matchcontinue;
end extractCrefsFromExp;

protected function traversingComponentRefFinder "
Author: BZ 2008-06
Exp traverser that Union the current ComponentRef with list if it is already there.
Returns a list containing, unique, all componentRef in an exp.
"
  input tuple<Exp, list<ComponentRef> > inExp;
  output tuple<Exp, list<ComponentRef> > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    list<ComponentRef> crefs;
    ComponentRef cr;
    Type ty;
  case( (DAE.CREF(cr,ty), crefs) )
    local list<Boolean> blist;
    equation
      crefs = Util.listUnionEltOnTrue(cr,crefs,crefEqual);
    then
      ((DAE.CREF(cr,ty), crefs ));
  case(inExp) then inExp;
end matchcontinue;
end traversingComponentRefFinder;

public function extractDivExpFromExp "
Author: Frenkel TUD 2010-02, Extracts all Division Exp from an exp.
"
input Exp inExp;
output list<Exp> outExps;
algorithm outExps := matchcontinue(inExp)
  case(inExp)
    local list<Exp> exps;
    equation
      ((_,exps)) = traverseExp(inExp, traversingDivExpFinder, {});
      then
        exps;
  end matchcontinue;
end extractDivExpFromExp;

protected function traversingDivExpFinder "
Author: Frenkel TUD 2010-02
Returns a list containing, all division exp in an exp.
"
  input tuple<Exp, list<Exp> > inExp;
  output tuple<Exp, list<Exp> > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    list<Exp> exps;
    Exp e,e2;
    Type ty;
  case( (e as DAE.BINARY(operator = DAE.DIV(ty),exp2 = e2), exps) )
    then ((e, e2::exps ));
  case( ( e as DAE.BINARY(operator = DAE.DIV_ARR(ty),exp2 = e2), exps) )
    then ((e, e2::exps ));
  case( ( e as DAE.BINARY(operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), exps) )
    then ((e, e2::exps ));
  case( ( e as DAE.BINARY(operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), exps) )
    then ((e, e2::exps ));
  case(inExp) then inExp;
end matchcontinue;
end traversingDivExpFinder;

public function containsExp
"function containsExp
  Author BZ 2008-06 same as expContains, but reversed."
  input Exp inExp1;
  input Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean:= expContains(inExp2,inExp1);
end containsExp;

protected function typeVarsStr "help function to typeString"
input list<Var> vars;
output String s;
algorithm
  s := Util.stringDelimitList(Util.listMap(vars,typeVarString),",");
end typeVarsStr;

protected function typeVarString "help function to typeVarsStr"
  input Var v;
  output String s;
algorithm
  s := matchcontinue(v)
  local String name; Type tp;
    case(DAE.COMPLEX_VAR(name,tp)) equation
      s = name +& ":" +& typeString(tp);
    then s;
  end matchcontinue;
end typeVarString;

protected function unelabOperator "help function to unelabExp."
input Operator op;
output Absyn.Operator aop;
algorithm
  aop := matchcontinue(op)
    case(DAE.ADD(_)) then Absyn.ADD();
    case(DAE.SUB(_)) then Absyn.SUB();
    case(DAE.MUL(_)) then Absyn.MUL();
    case(DAE.DIV(_)) then Absyn.DIV();
    case(DAE.POW(_)) then Absyn.POW();
    case(DAE.UMINUS(_)) then Absyn.UMINUS();
    case(DAE.UPLUS(_)) then Absyn.UPLUS();
    case(DAE.UMINUS_ARR(_)) then Absyn.UMINUS();
    case(DAE.UPLUS_ARR(_)) then Absyn.UPLUS();
    case(DAE.ADD_ARR(_)) then Absyn.ADD();
    case(DAE.SUB_ARR(_)) then Absyn.SUB();
    case(DAE.MUL_ARR(_)) then Absyn.MUL();
    case(DAE.DIV_ARR(_)) then Absyn.DIV();
    case(DAE.MUL_SCALAR_ARRAY(_)) then Absyn.MUL();
    case(DAE.MUL_ARRAY_SCALAR(_)) then Absyn.MUL();
    case(DAE.ADD_SCALAR_ARRAY(_)) then Absyn.ADD();
    case(DAE.ADD_ARRAY_SCALAR(_)) then Absyn.ADD();
    case(DAE.SUB_SCALAR_ARRAY(_)) then Absyn.SUB();
    case(DAE.SUB_ARRAY_SCALAR(_)) then Absyn.SUB();
    case(DAE.MUL_SCALAR_PRODUCT(_)) then Absyn.MUL();
    case(DAE.MUL_MATRIX_PRODUCT(_)) then Absyn.MUL();
    case(DAE.DIV_SCALAR_ARRAY(_)) then Absyn.DIV();
    case(DAE.DIV_ARRAY_SCALAR(_)) then Absyn.DIV();
    case(DAE.POW_SCALAR_ARRAY(_)) then Absyn.POW();
    case(DAE.POW_ARRAY_SCALAR(_)) then Absyn.POW();
    case(DAE.POW_ARR(_)) then Absyn.POW();
    case(DAE.POW_ARR2(_)) then Absyn.POW();
    case(DAE.AND()) then Absyn.AND();
    case(DAE.OR()) then Absyn.OR();
    case(DAE.NOT()) then Absyn.NOT();
    case(DAE.LESS(_)) then Absyn.LESS();
    case(DAE.LESSEQ(_)) then Absyn.LESSEQ();
    case(DAE.GREATER(_)) then Absyn.GREATER();
    case(DAE.GREATEREQ(_)) then Absyn.GREATEREQ();
    case(DAE.EQUAL(_)) then Absyn.EQUAL();
    case(DAE.NEQUAL(_)) then Absyn.NEQUAL();
  end matchcontinue;
end unelabOperator;

protected function replaceExpCrefRecursive
"function: replaceExpCrefRecursive
 function for adding $p in front of every cref child"
  input ComponentRef inCref;
  output String ostr;
algorithm ostr := matchcontinue(inCref)
  local String name,s1,s2,s3; ComponentRef cr,cr2;
  case(cr as DAE.CREF_IDENT(ident = name))
    equation
      s1 = printComponentRefStr(cr);
    then
      s1;
  case(DAE.CREF_QUAL(name,_,subs,cr))
    local list<Subscript> subs;
    equation
      s1 = replaceExpCrefRecursive(cr);
      cr2 = DAE.CREF_IDENT(name,DAE.ET_REAL(),subs);
      s2 = printComponentRefStr(cr2);
      s3 = Util.stringAppendList({s2,"$p",s1});
    then
      s3;
end matchcontinue;
end replaceExpCrefRecursive;

public function debugPrintComponentRefExp "
This function takes an exp and tries to print ComponentReferences.
Uses debugPrint.ComponentRefTypeStr, which gives type information to stdout.
NOTE Only used for debugging.
"
  input Exp inExp;
  output String str;
algorithm str := matchcontinue(inExp)
  local
    ComponentRef cr;
    String s1,s2,s3;
    list<Exp> expl;
    list<String> s1s;
  case(DAE.CREF(cr,_)) then debugPrintComponentRefTypeStr(cr);
  case(DAE.ARRAY(_,_,expl))
    equation
      s1 = "{" +& Util.stringAppendList(Util.listMap(expl,debugPrintComponentRefExp)) +& "}";
    then
      s1;
  case(inExp) then printExpStr(inExp); // when not cref, print expression anyways since it is used for some debugging.
end matchcontinue;
end debugPrintComponentRefExp;

public function debugPrintComponentRefTypeStr "Function: print_component_ref
This function is equal to debugPrintComponentRefTypeStr with the extra feature that it
prints the base type of each ComponentRef.
NOTE Only used for debugging.
"
  input ComponentRef inComponentRef;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef)
    local
      Ident s,str,str2,strrest,str_1,str_2;
      list<Subscript> subs;
      ComponentRef cr;
      Type ty;
    case DAE.CREF_IDENT(ident = s,identType=ty,subscriptLst = subs)
      equation
        str_1 = printListStr(subs, debugPrintSubscriptStr, ",");
        str = s +& Util.if_(stringLength(str_1) > 0, "["+& str_1 +& "}" , "");
        // this printing way will be useful when adressin the  'crefEqual' bug.
        //str = printComponentRef2Str(s, subs);
        str2 = typeString(ty);
        str = Util.stringAppendList({str," [",str2,"]"});
      then
        str;
    case DAE.CREF_QUAL(ident = s,identType=ty,subscriptLst = subs,componentRef = cr) /* Does not handle names with underscores */
      equation
        true = RTOpts.modelicaOutput();
        str = printComponentRef2Str(s, subs);
        str2 = typeString(ty);
        str = Util.stringAppendList({str," [",str2,"] "});
        strrest = debugPrintComponentRefTypeStr(cr);
        str_1 = stringAppend(str, "__");
        str_2 = stringAppend(str_1, strrest);
      then
        str_2;
    case DAE.CREF_QUAL(ident = s,identType=ty,subscriptLst = subs,componentRef = cr)
      equation
        false = RTOpts.modelicaOutput();
        str = printComponentRef2Str(s, subs);
        str2 = typeString(ty);
        str = Util.stringAppendList({str," [",str2,"] "});
        strrest = debugPrintComponentRefTypeStr(cr);
        str_1 = stringAppend(str, ".");
        str_2 = stringAppend(str_1, strrest);
      then
        str_2;
    case DAE.WILD() then "_";
  end matchcontinue;
end debugPrintComponentRefTypeStr;

public function getEnumIndexfromCref "function: getEnumIndexfromCref
  Evaluates ComponentRef, i.e. variables, by
  looking up variables in the environment."
  input ComponentRef inComponentRef;
  output Integer outEnumIndex;
algorithm
  outEnumIndex :=
  matchcontinue (inComponentRef)
    local
      ComponentRef c;
      Integer idx;
    case (DAE.CREF_IDENT(_,DAE.ET_ENUMERATION(SOME(idx),_,_,_),_))
      local Integer index;
      then
        idx;
    case (DAE.CREF_QUAL(_,_,_,c))
      equation
         idx = getEnumIndexfromCref(c);
      then
        idx;
    case (_) then fail();
    end matchcontinue;
end getEnumIndexfromCref;

public function printEnumLiteralArray "function: printEnumLiteralArray
  Evaluates ComponentRef, i.e. variables, by
  looking up variables in the environment."
  input Type inType;
  output String outString;
  output Boolean outIsEnum;
algorithm
  (outString,outIsEnum) :=
  matchcontinue (inType)
    local
      list<Ident> names;
      String namestr,nn;
    case DAE.ET_ENUMERATION(_,_,names,_)
      local String index;
      equation
         nn = Util.stringDelimitList(names,"\",\"");
         namestr = Util.stringAppendList({"{\"",nn,"\"}"});
      then
        (namestr,true);
    case (_) then ("",false);
    end matchcontinue;
end printEnumLiteralArray;


public function getEnumTypefromCref "function: getEnumIndexfromCref
  Evaluates ComponentRef, i.e. variables, by
  looking up variables in the environment."
  input ComponentRef inComponentRef;
  output Type outEnumType;
algorithm
  outEnumType :=
  matchcontinue (inComponentRef)
    local
      ComponentRef c;
      Type t;
    case (DAE.CREF_IDENT(_,t,_)) then t;
    case (DAE.CREF_QUAL(_,_,_,c))
      equation
         t = getEnumTypefromCref(c);
      then
        t;
    case (_) then fail();
    end matchcontinue;
end getEnumTypefromCref;

public function convertEnumCref "function: convertEnumCref

  Converts an Enumeration Cref into a Normal Cref
  Example x[Color.green] -> x[1].
"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef)
      local
        Integer idx;
        Ident ident;
        Type identType;
        ComponentRef c;
    /* enumeration */
    case (DAE.CREF_IDENT(ident = ident, identType = identType, 
        subscriptLst = {DAE.INDEX(exp = DAE.CREF(c,_))}))
      equation
        idx = getEnumIndexfromCref(c);
      then
        DAE.CREF_IDENT(ident, identType , {DAE.INDEX(DAE.ICONST(idx))});
    case (DAE.CREF_IDENT(ident = ident, identType = identType, 
        subscriptLst = {DAE.INDEX(exp = DAE.ENUM_LITERAL(index = idx))}))
      then
        DAE.CREF_IDENT(ident, identType, {DAE.INDEX(DAE.ICONST(idx))});
    case (c) then c;
  end matchcontinue;
end convertEnumCref;

public function isArrayType
"Returns true if inType is an ET_ARRAY"
  input DAE.ExpType inType;
  output Boolean b;
algorithm
  b := matchcontinue inType
    case DAE.ET_ARRAY(_,_) then true;
    case _ then false;
  end matchcontinue;
end isArrayType;

public function sizeOf
"Returns the size of an ET_ARRAY or ET_COMPLEX"
  input DAE.ExpType inType;
  output Integer i;
algorithm
  i := matchcontinue inType
    local
      list<DAE.Dimension> ad;
      Integer nr;
      list<Integer> lstInt;
      list<Var> varLst;
    // count the variables in array
    case DAE.ET_ARRAY(arrayDimensions = ad)
      equation
        nr = dimensionSize(Util.listReduce(ad, dimensionsMult));
      then
        nr;
    // count the variables in record
    case DAE.ET_COMPLEX(varLst = varLst)
      equation
        lstInt = Util.listMap(Util.listMap(varLst, varType), sizeOf);
        nr = Util.listReduce(lstInt, intAdd);
      then
        nr;
    // for all other consider it just 1 variable
    case _ then 1;
  end matchcontinue;
end sizeOf;

protected function simplifyBuiltinConstantDer 
"returns 0.0 or an array filled with 0.0 if the input is Real, Integer or an array of Real/Integer"
  input Exp inExp "assumes already simplified constant expression";
  output Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      Exp e;
      list<DAE.Dimension> dims;
    case DAE.RCONST(_) then DAE.RCONST(0.0);   
    case DAE.ICONST(_) then DAE.RCONST(0.0);   
    case DAE.ARRAY(ty=DAE.ET_ARRAY(ty=DAE.ET_REAL, arrayDimensions=dims))
      equation
        (e,_) = makeZeroExpression(dims);
      then
        e;  
    case DAE.ARRAY(ty=DAE.ET_ARRAY(ty=DAE.ET_INT, arrayDimensions=dims))
      equation
        (e,_) = makeZeroExpression(dims);
      then
        e;  
  end matchcontinue;
end simplifyBuiltinConstantDer;

public function makeZeroExpression
" creates a Real or array<Real> zero expression with given dimensions, also returns its type"
  input list<DAE.Dimension> inDims;
  output Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp,outType) := matchcontinue(inDims)
    local
      Integer i;
      DAE.Dimension d;
      list<DAE.Dimension> dims;
      Exp e;
      list<Exp> eLst;
      DAE.Type ty;
    case {} then (DAE.RCONST(0.0), DAE.T_REAL_DEFAULT);
    case d::dims
      equation
        i = dimensionSize(d);
        (e, ty) = makeZeroExpression(dims);
        eLst = Util.listFill(e,i);
      then
        (DAE.ARRAY(DAE.ET_ARRAY(DAE.ET_REAL(),d::dims),false,eLst), 
         (DAE.T_ARRAY(d,ty),NONE));      
  end matchcontinue;
end makeZeroExpression;  

public function getMatchingExpsList
  input list<DAE.Exp> inExps;
  input MatchFn inFn;
  output list<DAE.Exp> outExpLst;
  partial function MatchFn
    input DAE.Exp inExpr;
    output list<DAE.Exp> outExprLst;
  end MatchFn;
  list<list<DAE.Exp>> explists;
algorithm
  explists := Util.listMap1(inExps, getMatchingExps, inFn);
  outExpLst := Util.listFlatten(explists);
end getMatchingExpsList;

public function getMatchingExps
"function: getMatchingExps
  Return all exps that match the given function.
  Inner exps may be returned separately but not
  extracted from the exp they are in, e.g.
    CALL(foo, {CALL(bar)}) will return
    {CALL(foo, {CALL(bar)}), CALL(bar,{})}"
  input DAE.Exp inExp;
  input MatchFn inFn;
  output list<DAE.Exp> outExpLst;
  partial function MatchFn
    input DAE.Exp inExpr;
    output list<DAE.Exp> outExprLst;
  end MatchFn;
algorithm
  outExpLst:=
  matchcontinue (inExp,inFn)
    local
      list<DAE.Exp> exps,exps2,args,a,b,res,elts,elst,elist;
      DAE.Exp e,e1,e2,e3;
      Absyn.Path path;
      Boolean tuple_,builtin;
      list<tuple<DAE.Exp, Boolean>> flatexplst;
      list<list<tuple<DAE.Exp, Boolean>>> explst;
      Option<DAE.Exp> optexp;
      MatchFn fn;

    // First we check if the function matches
    case (e, fn)
      equation
        res = fn(e);
      then res;

    // Else: Traverse all Exps
    case ((e as DAE.CALL(path = path,expLst = args,tuple_ = tuple_,builtin = builtin)),fn)
      equation
        exps = getMatchingExpsList(args,fn);
      then
        exps;
    case (DAE.PARTEVALFUNCTION(expList = args),fn)
      equation
        res = getMatchingExpsList(args,fn);
      then
        res;
    case (DAE.BINARY(exp1 = e1,exp2 = e2),fn) /* Binary */
      equation
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.UNARY(exp = e),fn) /* Unary */
      equation
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),fn) /* LBinary */
      equation
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.LUNARY(exp = e),fn) /* LUnary */
      equation
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),fn) /* Relation */
      equation
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),fn)
      equation
        res = getMatchingExpsList({e1,e2,e3},fn);
      then
        res;
    case (DAE.ARRAY(array = elts),fn) /* Array */
      equation
        res = getMatchingExpsList(elts,fn);
      then
        res;
    case (DAE.MATRIX(scalar = explst),fn) /* Matrix */
      equation
        flatexplst = Util.listFlatten(explst);
        elst = Util.listMap(flatexplst, Util.tuple21);
        res = getMatchingExpsList(elst,fn);
      then
        res;
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2),fn) /* Range */
      local list<DAE.Exp> e3;
      equation
        e3 = Util.optionToList(optexp);
        elist = listAppend({e1,e2}, e3);
        res = getMatchingExpsList(elist,fn);
      then
        res;
    case (DAE.TUPLE(PR = exps),fn) /* Tuple */
      equation
        res = getMatchingExpsList(exps,fn);
      then
        res;
    case (DAE.CAST(exp = e),fn)
      equation
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.SIZE(exp = e1,sz = e2),fn) /* Size */
      local Option<DAE.Exp> e2;
      equation
        a = Util.optionToList(e2);
        elist = e1 :: a;
        res = getMatchingExpsList(elist,fn);
      then
        res;

        /* MetaModelica list */
    case (DAE.CONS(_,e1,e2),fn)
      equation
        elist = {e1,e2};
        res = getMatchingExpsList(elist,fn);
      then res;

    case  (DAE.LIST(_,elist),fn)
      equation
        res = getMatchingExpsList(elist,fn);
      then res;

    case (e as DAE.METARECORDCALL(args = elist),fn)
      equation
        res = getMatchingExpsList(elist,fn);
      then res;

    case (DAE.META_TUPLE(elist), fn)
      equation
        res = getMatchingExpsList(elist, fn);
      then res;

   case (DAE.META_OPTION(SOME(e1)), fn)
      equation
        res = getMatchingExps(e1, fn);
      then res;

    case(DAE.ASUB(exp = e1),fn)
      equation
        res = getMatchingExps(e1,fn);
        then
          res;

    case(DAE.CREF(_,_),_) then {};

		case (DAE.REDUCTION(expr = e1), fn)
			equation
				res = getMatchingExps(e1, fn);
			then
				res;

    case (DAE.VALUEBLOCK(localDecls = ld,body = body,result = e),fn)
      local
    		list<DAE.Element> ld;
    		list<DAE.Statement> body;
      equation
        exps = DAEUtil.getAllExps(ld);
        exps2 = Algorithm.getAllExpsStmts(body);
        exps = listAppend(exps,exps2);
        res = getMatchingExpsList(e::exps,fn);
      then res;

    case (DAE.ICONST(_),_) then {};
    case (DAE.RCONST(_),_) then {};
    case (DAE.BCONST(_),_) then {};
    case (DAE.SCONST(_),_) then {};
    case (DAE.CODE(_,_),_) then {};
    case (DAE.END(),_) then {};
    case (DAE.META_OPTION(NONE),_) then {};

    case (e,_)
      equation
        Debug.fprintln("failtrace", "- Exp.getMatchingExps failed: " +& printExpStr(e));
      then fail();

  end matchcontinue;
end getMatchingExps;

public function dimensionSize
  "Extracts an integer from an array dimension"
  input DAE.Dimension dim;
  output Integer value;
algorithm
  value := matchcontinue(dim)
    local
      Integer i;
    case DAE.DIM_INTEGER(integer = i) then i;
    case DAE.DIM_ENUM(size = i) then i; 
  end matchcontinue;
end dimensionSize;

public function dimensionSizeExp
  "Converts a dimension to an integer expression."
  input DAE.Dimension dim;
  output DAE.Exp exp;
algorithm
  exp := matchcontinue(dim)
    local
      Integer i;
    case DAE.DIM_INTEGER(integer = i) then DAE.ICONST(i);
    case DAE.DIM_ENUM(size = i) then DAE.ICONST(i);
  end matchcontinue;
end dimensionSizeExp;

public function intDimension
  "Converts an integer to an array dimension."
  input Integer value;
  output DAE.Dimension dim;
algorithm
  dim := DAE.DIM_INTEGER(value);
end intDimension;

public function dimensionString
  "Returns a string representation of an array dimension."
  input DAE.Dimension dim;
  output String str;
algorithm
  str := matchcontinue(dim)
    local
      String s;
      Integer x;
    case DAE.DIM_UNKNOWN then ":";
    case DAE.DIM_ENUM(enumTypeName = p) 
      local Absyn.Path p;
      equation
        s = Absyn.pathString(p);
      then 
        s;
    case DAE.DIM_INTEGER(integer = x)
      equation
        s = intString(x);
      then
        s;
    case DAE.DIM_EXP(exp = e)
      local Exp e;
      equation
        s = printExpStr(e);
      then
        s;
  end matchcontinue;
end dimensionString;

public function dimensionSubscript
  "Converts an array dimension to a subscript."
  input DAE.Dimension dim;
  output DAE.Subscript sub;
algorithm
  sub := matchcontinue(dim)
    local
      Integer i;
    case DAE.DIM_INTEGER(integer = i) then DAE.INDEX(DAE.ICONST(i));
    case DAE.DIM_ENUM(size = i) then DAE.INDEX(DAE.ICONST(i));
    case DAE.DIM_UNKNOWN then DAE.WHOLEDIM();
  end matchcontinue;
end dimensionSubscript;

public function dimensionsEqual
  "Returns whether two dimensions are equal or not."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output Boolean res;
algorithm
  res := matchcontinue(dim1, dim2)
    case (DAE.DIM_UNKNOWN, _) then true;
    case (_, DAE.DIM_UNKNOWN) then true;
    case (DAE.DIM_EXP(exp = _), _) then true;
    case (_, DAE.DIM_EXP(exp = _)) then true;
    case (_, _)
      local Boolean b;
      equation
        b = intEq(dimensionSize(dim1), dimensionSize(dim2));
      then
        b;
  end matchcontinue;
end dimensionsEqual;

public function dimensionsKnownAndEqual
  "Checks that two dimensions are specified and equal."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output Boolean res;
algorithm
  res := intEq(dimensionSize(dim1), dimensionSize(dim2));
end dimensionsKnownAndEqual;

public function dimensionsMult
  "Multiplies two dimensions."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output DAE.Dimension res;
algorithm
  res := intDimension(dimensionSize(dim1) * dimensionSize(dim2));
end dimensionsMult;

public function dimensionsAdd
  "Adds two dimensions."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output DAE.Dimension res;
algorithm
  res := matchcontinue(dim1, dim2)
    case (DAE.DIM_UNKNOWN, _) then DAE.DIM_UNKNOWN;
    case (_, DAE.DIM_UNKNOWN) then DAE.DIM_UNKNOWN;
    case (_, _)
      equation
        res = intDimension(dimensionSize(dim1) + dimensionSize(dim2));
      then
        res;
  end matchcontinue;
end dimensionsAdd;

public function dimensionKnown
  "Checks whether a dimensions is known or not."
  input DAE.Dimension dim;
  output Boolean known;
algorithm
  known := matchcontinue(dim)
    case DAE.DIM_UNKNOWN then false;
    case DAE.DIM_EXP(exp = DAE.ICONST(integer = _)) then true;
    case DAE.DIM_EXP(exp = _) then false;
    case _ then true;
  end matchcontinue;
end dimensionKnown;

public function arrayAppend
  "Appends a new element to a DAE.ARRAY."
  input DAE.Exp head;
  input DAE.Exp rest;
  output DAE.Exp array;
algorithm
  array := matchcontinue(head, rest)
    local
      DAE.ExpType ty;
      Boolean scalar;
      list<DAE.Exp> expl;
      Integer dim;
      list<DAE.Dimension> dims;
    case (_, DAE.ARRAY(
        DAE.ET_ARRAY(ty = ty, arrayDimensions = DAE.DIM_INTEGER(dim) :: dims),
        scalar = scalar, 
        array = expl))
      equation
        dim = dim + 1;
        dims = DAE.DIM_INTEGER(dim) :: dims;
      then
        DAE.ARRAY(DAE.ET_ARRAY(ty, dims), scalar, head :: expl);
    case (_, _)
      equation
        Debug.fprintln("failtrace", "- Exp.arrayAppend failed.");
      then
        fail();
  end matchcontinue;
end arrayAppend;

public function concatArrayType
  "Concatenates two array types, so that the resulting type is correct."
  input DAE.ExpType arrayType1;
  input DAE.ExpType arrayType2;
  output DAE.ExpType concatType;
algorithm
  concatType := matchcontinue(arrayType1, arrayType2)
    local
      DAE.ExpType et;
      DAE.Dimension dim1, dim2;
      list<DAE.Dimension> dims1, dims2;
    case (DAE.ET_ARRAY(ty = et, arrayDimensions = dim1 :: dims1),
          DAE.ET_ARRAY(arrayDimensions = dim2 :: dims2))
      equation
        dim1 = dimensionsAdd(dim1, dim2);
      then
        DAE.ET_ARRAY(et, dim1 :: dims1);
  end matchcontinue;
end concatArrayType;

public function arrayDimensionSetFirst
  "Updates the first dimension of an array type."
  input DAE.ExpType inArrayType;
  input DAE.Dimension dimension;
  output DAE.ExpType outArrayType;
algorithm
  outArrayType := matchcontinue(inArrayType, dimension)
    local
      DAE.ExpType ty;
      list<DAE.Dimension> rest_dims;
    case (DAE.ET_ARRAY(ty = ty, arrayDimensions = _ :: rest_dims), _)
      then DAE.ET_ARRAY(ty, dimension :: rest_dims);
  end matchcontinue;
end arrayDimensionSetFirst;

public function isValidSubscript
  "Checks if an expression is a valid subscript, i.e. an integer or enumeration
  literal."
  input DAE.Exp inSub;
  output Boolean isValid;
algorithm
  isValid := matchcontinue(inSub)
    case DAE.ICONST(integer = _) then true;
    case DAE.ENUM_LITERAL(index = _) then true;
    case _ then false;
  end matchcontinue;
end isValidSubscript;

end Exp;

