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

encapsulated package ComponentReference
" file:        ComponentReference.mo
  package:     ComponentReference
  description: All stuff for ComponentRef datatypes

  RCS: $Id$

  This file contains the module ComponentReference, 
  which contains functions for ComponentRef."

// public imports
public import Absyn;
public import DAE;

// protected imports
protected import ClassInf;
protected import Config;
protected import Debug;
protected import Dump;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import Global;
protected import List;
protected import Print;
protected import System;
protected import Types;
protected import Util;

// do not make this public. instead use the function below.
protected constant DAE.ComponentRef dummyCref = DAE.CREF_IDENT("dummy", DAE.T_UNKNOWN_DEFAULT, {});

public type ComponentRef = DAE.ComponentRef;

public function hashComponentRefMod "
  author: PA
 
  Calculates a hash value for DAE.ComponentRef, by hashing each individual part separately and summing the values, and then apply
  intMod to it, to return a value in range [0,mod-1].
  Also hashes subscripts in a clever way avoiding [1,2] and [2,1] to hash to the same value. This is done by investigating array type
  to find dimension of array. 
"
  input DAE.ComponentRef cr;
  input Integer mod;
  output Integer res;
protected
  Integer h;
algorithm 
   // hash might overflow => force positive
   h := intAbs(hashComponentRef(cr));
   res := intMod(h,mod);
end hashComponentRefMod;

public function hashComponentRef "new hashing that properly deals with subscripts so [1,2] and [2,1] hash to different values"
  input DAE.ComponentRef cr;
  output Integer hash;
algorithm
hash := matchcontinue(cr)
  local
    DAE.Ident id;
    DAE.Type tp;
    list<DAE.Subscript> subs;
    DAE.ComponentRef cr1;
  case(DAE.CREF_IDENT(id,tp,subs)) equation
    //print("IDENT, "+&id+&" hashed to "+&intString(stringHashDjb2(id))+&", subs hashed to "+&intString(hashSubscripts(tp,subs))+&"\n");
  then stringHashDjb2(id) + hashSubscripts(tp,subs);

  case(DAE.CREF_QUAL(id,tp,subs,cr1)) equation
    //print("QUAL, "+&id+&" hashed to "+&intString(stringHashDjb2(id))+&", subs hashed to "+&intString(hashSubscripts(tp,subs))+&"\n");
  then stringHashDjb2(id)+hashSubscripts(tp,subs)+hashComponentRef(cr1);

  case(DAE.CREF_ITER(id,_,tp,subs)) 
  then stringHashDjb2(id)+ hashSubscripts(tp,subs);
  case(_) then 0;
end matchcontinue;
end hashComponentRef;

protected protected function hashSubscripts "help function, hashing subscripts making sure [1,2] and [2,1] doesn't match to the same number"
  input DAE.Type tp;
  input list<DAE.Subscript> subs;
  output Integer hash;
algorithm
  hash := matchcontinue(tp,subs)
  case(_,{}) then 0;
  // TODO: Currently, the types of component references are wrong, they consider the subscripts but they should not.
  // For example, given Real a[10,10];  the component reference 'a[1,2]' should have type Real[10,10] but it has type Real.
  case(_,_)  then hashSubscripts2(List.fill(1,listLength(subs)),/*DAEUtil.expTypeArrayDimensions(tp),*/subs,1);
  end matchcontinue;
end hashSubscripts;

protected protected function hashSubscripts2 "help function"
  input list<Integer> dims;
  input list<DAE.Subscript> subs;
  input Integer factor;
  output Integer hash;
algorithm
  hash := match(dims,subs,factor)
  local 
    Integer i1;
    DAE.Subscript s;
    list<Integer> rest_dims;
    list<DAE.Subscript> rest_subs;
   
    case({},{},_) then 0;
    case(i1::rest_dims,s::rest_subs,_)
    // TODO: change to using dimensions once cref types has been fixed.
    then hashSubscript(s)*factor + hashSubscripts2(rest_dims,rest_subs,factor*1000/* *i1 */);  
  end match;
end hashSubscripts2;

protected function hashSubscript "help function"
  input DAE.Subscript sub;
  output Integer hash;
algorithm
 hash := matchcontinue(sub)
   local 
     DAE.Exp exp;
     Integer i;

   case(DAE.WHOLEDIM()) then 0;
   case(DAE.INDEX(DAE.ICONST(i))) then i; 
   case(DAE.SLICE(exp)) then Expression.hashExp(exp);
   case(DAE.INDEX(exp)) then Expression.hashExp(exp);
   case(DAE.WHOLE_NONEXP(exp)) then Expression.hashExp(exp);
 end matchcontinue;
end hashSubscript;

public function createEmptyCrefMemory
"@author: adrpo
  creates an array, with one element for each record in ComponentRef!"
  output array<list<ComponentRef>> crefMemory;
algorithm
  crefMemory := arrayCreate(3, {});
end createEmptyCrefMemory;

protected function searchInMememoryLst
"@author: adrpo
  This function searches in memory for already existing ComponentRef"
  input ComponentRef inCref;
  input list<ComponentRef> inMem;
  output ComponentRef outCref;
algorithm
  outCref := matchcontinue (inCref, inMem)
    local
      list<ComponentRef> rest;
      ComponentRef cref;
    
    // fail if we couldn't find it
    case (inCref, {}) then fail();
    
    // see if we have it in memory, return the already existing!
    case (inCref, cref::rest)
      equation
        equality(inCref = cref);
      then
        cref;
    
    // try the next    
    case (inCref, cref::rest)
      equation
        failure(equality(inCref = cref));
        cref = searchInMememoryLst(inCref, rest);
      then
        cref;
  end matchcontinue;
end searchInMememoryLst;

protected function shareCref 
"@author: adrpo
  searches in the global cache for the given cref and if 
  there is one, returns that pointer, otherwise adds it"
  input ComponentRef inCref;
  output ComponentRef outCref;
algorithm
  outCref := matchcontinue (inCref)
    local
      array<list<ComponentRef>> crefMem;
      list<ComponentRef> crefLst;
      ComponentRef cref;
      Integer indexBasedOnValueConstructor;

    // see if we have it in memory
    case (inCref) then inCref;

    // see if we have it in memory
    case (inCref)
      equation        
        // oh the horror. if you don't understand this, contact adrpo
        // get from global roots
        crefMem = getGlobalRoot(Global.crefIndex);
        // select a list based on the constructor of ComponentRef value
        indexBasedOnValueConstructor = valueConstructor(inCref);
        crefLst = arrayGet(crefMem, indexBasedOnValueConstructor + 1);
        // search in the list for already existing one
        cref = searchInMememoryLst(inCref, crefLst);
        
        // print("Lst: " +& intString(listLength(crefLst)) +& 
        //       " Shared: " +& printComponentRefStr(cref) +& "\n");
      then
        cref;
    
    // we didn't find it, add it
    case (inCref)
      equation
        // oh the horror. if you don't understand this, contact adrpo
        // get from global roots        
        crefMem = getGlobalRoot(Global.crefIndex);
        // select a list based on the constructor of ComponentRef value
        indexBasedOnValueConstructor = valueConstructor(inCref);
        crefLst = arrayGet(crefMem, indexBasedOnValueConstructor + 1);
        // add the translation to the list and set the array
        crefMem = arrayUpdate(crefMem, indexBasedOnValueConstructor + 1, inCref::crefLst);
        // set the global cache with the new value
        setGlobalRoot(Global.crefIndex, crefMem);
      then 
        inCref;
  end matchcontinue;
end shareCref;

/***************************************************/
/* generate a ComponentRef */
/***************************************************/

public function makeDummyCref
"@author: adrpo
  This function creates a dummy component reference"
  output ComponentRef outCrefIdent;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outCrefIdent := dummyCref; // shareCref(dummyCref);
end makeDummyCref;

public function makeCrefIdent
"@author: adrpo
  This function creates a DAE.CREF_IDENT(ident, identType, subscriptLst)"
  input DAE.Ident ident;
  input DAE.Type identType "type of the identifier, without considering the subscripts";
  input list<DAE.Subscript> subscriptLst;
  output ComponentRef outCrefIdent;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outCrefIdent := DAE.CREF_IDENT(ident, identType, subscriptLst); // shareCref(DAE.CREF_IDENT(ident, identType, subscriptLst));
end makeCrefIdent;

public function makeUntypedCrefIdent
  input DAE.Ident ident;
  output ComponentRef outCrefIdent;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outCrefIdent := DAE.CREF_IDENT(ident, DAE.T_UNKNOWN_DEFAULT, {});
end makeUntypedCrefIdent;

public function makeCrefQual
"@author: adrpo
  This function creates a DAE.CREF_QUAL(ident, identType, subscriptLst, componentRef)"
  input DAE.Ident ident;
  input DAE.Type identType "type of the identifier, without considering the subscripts";
  input list<DAE.Subscript> subscriptLst;
  input ComponentRef componentRef;
  output ComponentRef outCrefQual;
  annotation(__OpenModelica_EarlyInline = true);
protected
  ComponentRef subCref;
algorithm
  // subCref := shareCref(componentRef);
  // outCrefQual := shareCref(DAE.CREF_QUAL(ident, identType, subscriptLst, subCref));
  outCrefQual := DAE.CREF_QUAL(ident, identType, subscriptLst, componentRef);
end makeCrefQual;


/***************************************************/
/* transform to other types */
/***************************************************/

public function crefToPath
"function: crefToPath
  This function converts a ComponentRef to a Path, if possible.
  If the component reference contains subscripts, it will silently
  fail."
  input ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath := match (inComponentRef)
    local
      DAE.Ident i;
      Absyn.Path p;
      ComponentRef c;
    
    case DAE.CREF_IDENT(ident = i,subscriptLst = {}) then Absyn.IDENT(i);
    
    case DAE.CREF_QUAL(ident = i,subscriptLst = {},componentRef = c)
      equation
        p = crefToPath(c);
      then
        Absyn.QUALIFIED(i,p);
  end match;
end crefToPath;

public function crefToPathIgnoreSubs
  input ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath := match(inComponentRef)
    local
      DAE.Ident i;
      Absyn.Path p;
      ComponentRef c;

    case DAE.CREF_IDENT(ident = i) then Absyn.IDENT(i);
    case DAE.CREF_QUAL(ident = i, componentRef = c)
      equation
        p = crefToPathIgnoreSubs(c);
      then
        Absyn.QUALIFIED(i, p);
  end match;
end crefToPathIgnoreSubs;

public function pathToCref
"function: pathToCref
  This function converts a Absyn.Path to a ComponentRef."
  input Absyn.Path inPath;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inPath)
    local
      DAE.Ident i;
      ComponentRef c;
      Absyn.Path p;
    
    case Absyn.IDENT(name = i) then makeCrefIdent(i,DAE.T_UNKNOWN_DEFAULT,{});
    
    case (Absyn.FULLYQUALIFIED(p)) then pathToCref(p);
    
    case Absyn.QUALIFIED(name = i,path = p)
      equation
        c = pathToCref(p);
      then
        makeCrefQual(i,DAE.T_UNKNOWN_DEFAULT,{},c);
  end match;
end pathToCref;

public function creffromVar
" function creffromVar
  author: Frenkel TUD
  generates a cref from DAE.Var"
  input DAE.Var inVar;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inVar)
    local
      String name;
      DAE.Type ty;
      
    case DAE.TYPES_VAR(name=name,ty=ty)
      then
        makeCrefIdent(name,ty,{});
  end match;
end creffromVar;

public function unelabCref
"function: unelabCref
  Transform an ComponentRef into Absyn.ComponentRef."
  input ComponentRef inComponentRef;
  output Absyn.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef)
    local
      list<Absyn.Subscript> subs_1;
      DAE.Ident id;
      list<DAE.Subscript> subs;
      Absyn.ComponentRef cr_1;
      ComponentRef cr;
    
    // iterators
    case (DAE.CREF_ITER(ident = id, subscriptLst = subs))
      equation
        subs_1 = unelabSubscripts(subs);
      then
        Absyn.CREF_IDENT(id ,subs_1);    
    
    // identifiers
    case (DAE.CREF_IDENT(ident = id, subscriptLst = subs))
      equation
        subs_1 = unelabSubscripts(subs);
      then
        Absyn.CREF_IDENT(id, subs_1);
    
    // qualified
    case (DAE.CREF_QUAL(ident = id, subscriptLst = subs, componentRef = cr))
      equation
        cr_1 = unelabCref(cr);
        subs_1 = unelabSubscripts(subs);
      then
        Absyn.CREF_QUAL(id, subs_1, cr_1);
        
    case _
      equation
        true = Flags.isSet(Flags.FAILTRACE);        
        print("ComponentReference.unelabCref failed on: " +& printComponentRefStr(inComponentRef) +& "\n");
      then
        fail();
        
  end matchcontinue;
end unelabCref;

protected function unelabSubscripts
"function: unelabSubscripts
  Helper function to unelabCref, handles subscripts."
  input list<DAE.Subscript> inSubscriptLst;
  output list<Absyn.Subscript> outAbsynSubscriptLst;
algorithm
  outAbsynSubscriptLst := match (inSubscriptLst)
    local
      list<Absyn.Subscript> xs_1;
      list<DAE.Subscript> xs;
      Absyn.Exp e_1;
      DAE.Exp e;
    
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
        e_1 = Expression.unelabExp(e);
      then
        (Absyn.SUBSCRIPT(e_1) :: xs_1);
    // indexes
    case ((DAE.INDEX(exp = e) :: xs))
      equation
        xs_1 = unelabSubscripts(xs);
        e_1 = Expression.unelabExp(e);
      then
        (Absyn.SUBSCRIPT(e_1) :: xs_1);
  end match;
end unelabSubscripts;

public function toExpCref
"function: toExpCref
  Translate an Absyn.ComponentRef into a ComponentRef.
  Note: Only support for indexed subscripts of integers"
  input Absyn.ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef)
    local
      list<DAE.Subscript> subs_1;
      DAE.Ident id;
      list<Absyn.Subscript> subs;
      ComponentRef cr_1;
      Absyn.ComponentRef cr;
    
    // ids
    case (Absyn.CREF_IDENT(name = id,subscripts = subs))
      equation
        subs_1 = toExpCrefSubs(subs);
      then
        makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,subs_1);
    
    // qualified
    case (Absyn.CREF_QUAL(name = id,subscripts = subs,componentRef = cr))
      equation
        cr_1 = toExpCref(cr);
        subs_1 = toExpCrefSubs(subs);
      then
        makeCrefQual(id,DAE.T_UNKNOWN_DEFAULT,subs_1,cr_1);
    
    // fully qualified
    case (Absyn.CREF_FULLYQUALIFIED(componentRef = cr))
      equation
        cr_1 = toExpCref(cr);
      then
        cr_1; // There is no fullyqualified cref, translate to qualified cref
  end match;
end toExpCref;

protected function toExpCrefSubs
"function: toExpCrefSubs
  Helper function to toExpCref."
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  output list<DAE.Subscript> outSubscriptLst;
algorithm
  outSubscriptLst := matchcontinue (inAbsynSubscriptLst)
    local
      list<DAE.Subscript> xs_1;
      Integer i;
      list<Absyn.Subscript> xs;
      ComponentRef cr_1;
      Absyn.ComponentRef cr;
      DAE.Ident s,str;
      Absyn.Subscript e;
      DAE.Exp exp;
    
    // empty list
    case ({}) then {};
    
    // integer subscripts become indexes of integers
    case ((Absyn.SUBSCRIPT(subscript = Absyn.INTEGER(value = i)) :: xs))
      equation
        xs_1 = toExpCrefSubs(xs);
      then
        (DAE.INDEX(DAE.ICONST(i)) :: xs_1);
    
    // cref subscripts become indexes of crefs 
    // => Assumes index is INTEGER. FIXME! TODO!: what about if index is an array?
    case ((Absyn.SUBSCRIPT(subscript = Absyn.CREF(componentRef = cr)) :: xs)) 
      equation
        cr_1 = toExpCref(cr);
        xs_1 = toExpCrefSubs(xs);
        exp = Expression.makeCrefExp(cr_1,DAE.T_INTEGER_DEFAULT);
      then
        (DAE.INDEX(exp) :: xs_1);
    
    // when there is an error, move to next TODO! FIXME! report an error!
    case ((e :: xs))
      equation
        s = Dump.printSubscriptsStr({e});
        str = stringAppendList({"#Error converting subscript: ",s," to Expression.\n"});
        //print("#Error converting subscript: " +& s +& " to Expression.\n");
        //Print.printErrorBuf(str);
        xs_1 = toExpCrefSubs(xs);
      then
        xs_1;
  end matchcontinue;
end toExpCrefSubs;


public function crefToStr
"function: crefStr
  This function converts a ComponentRef to a String.
  It is a tail recursive implementation, because of that it
  neads inPreString. Use inNameSeperator to define the 
  Separator inbetween and between the namespace names and the name"
  input String inPreString;
  input ComponentRef inComponentRef "The ComponentReference";
  input String inNameSeparator "The Separator between the Names";
  output String outString;
algorithm
  outString:=
  match (inPreString,inComponentRef,inNameSeparator)
    local
      DAE.Ident s,ns,ss;
      ComponentRef n;
    case (_,DAE.CREF_IDENT(ident = s),_)
      equation
        ss = stringAppend(inPreString, s);
      then ss;
    case (_,DAE.CREF_QUAL(ident = s,componentRef = n),_)
      equation
        ns = stringAppendList({inPreString, s, inNameSeparator});
        ss = crefToStr(ns,n,inNameSeparator);
      then
        ss;
  end match;
end crefToStr;

public function crefStr
"function: crefStr
  This function simply converts a ComponentRef to a String."
  input ComponentRef inComponentRef;
  output String outString;
algorithm
  outString:= crefToStr("",inComponentRef,".");
end crefStr;

public function crefModelicaStr
"function: crefModelicaStr
  Same as crefStr, but uses _ instead of . "
  input ComponentRef inComponentRef;
  output String outString;
algorithm
  outString:= crefToStr("",inComponentRef,"_");
end crefModelicaStr;

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
  outString := match (inComponentRef)
    local
      DAE.Ident s,str,strrest,strseb;
      list<DAE.Subscript> subs;
      ComponentRef cr;
      Boolean b;
      Integer ix;
    
    // Optimize -- a function call less
    case (DAE.CREF_IDENT(ident = s,subscriptLst = {}))
      then s;
    
    // idents with subscripts 
    case DAE.CREF_IDENT(ident = s,subscriptLst = subs)
      equation
        str = printComponentRef2Str(s, subs);
      then
        str;

    // Optimize -- a function call less
    case (DAE.CREF_ITER(ident = s,index=ix,subscriptLst = {}))
      then s +& "/* iter index " +& intString(ix) +& " */";
    
    // idents with subscripts 
    case DAE.CREF_ITER(ident = s,index=ix,subscriptLst = subs)
      equation
        str = printComponentRef2Str(s, subs);
      then
        str +& "/* iter index " +& intString(ix) +& " */";
    
    // Qualified - Modelica output - does not handle names with underscores
    // Qualified - non Modelica output
    case DAE.CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr)
      equation
        b = Config.modelicaOutput();
        str = printComponentRef2Str(s, subs);
        strrest = printComponentRefStr(cr);
        strseb = Util.if_(b,"__",".");
        str = stringAppendList({str, strseb, strrest});
      then
        str;
    
    // Wild 
    case DAE.WILD() then "_";
  end match;
end printComponentRefStr;

public function printComponentRef2Str
"function: printComponentRef2Str
  Helper function to printComponentRefStr."
  input DAE.Ident inIdent;
  input list<DAE.Subscript> inSubscriptLst;
  output String outString;
algorithm
  outString := match (inIdent,inSubscriptLst)
    local
      DAE.Ident s,str,strseba,strsebb;
      list<DAE.Subscript> l;
      Boolean b;
    
    // no subscripts
    case (s,{}) then s;
    
    // some subscripts, Modelica output
    // some subscripts, non Modelica output
    case (s,l)
      equation
        b = Config.modelicaOutput();
        str = ExpressionDump.printListStr(l, ExpressionDump.printSubscriptStr, ",");
        ((strseba,strsebb)) = Util.if_(b,("_L","_R"),("[","]")); 
        str = stringAppendList({s, strseba, str, strsebb});
      then
        str;
    
  end match;
end printComponentRef2Str;

public function debugPrintComponentRefTypeStr "Function: debugPrintComponentRefTypeStr
This function is equal to debugPrintComponentRefTypeStr with the extra feature that it
prints the base type of each ComponentRef.
NOTE Only used for debugging."
  input ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef)
    local
      DAE.Ident s,str,str2,strrest,str_1;
      list<DAE.Subscript> subs;
      ComponentRef cr;
      DAE.Type ty;
    
    case DAE.CREF_IDENT(ident = s,identType=ty,subscriptLst = subs)
      equation
        str_1 = ExpressionDump.printListStr(subs, ExpressionDump.debugPrintSubscriptStr, ", ");
        str = s +& Util.if_(stringLength(str_1) > 0, "["+& str_1 +& "]", "");
        str2 = Types.unparseType(ty);
        str = stringAppendList({str," [",str2,"]"});
      then
        str;
    
    case DAE.CREF_QUAL(ident = s,identType=ty,subscriptLst = subs,componentRef = cr)
      equation
        false = Config.modelicaOutput();
        str_1 = ExpressionDump.printListStr(subs, ExpressionDump.debugPrintSubscriptStr, ", ");
        str = s +& Util.if_(stringLength(str_1) > 0, "["+& str_1 +& "]", "");
        str2 = Types.unparseType(ty);
        strrest = debugPrintComponentRefTypeStr(cr);
        str = stringAppendList({str," [",str2,"] ", ".", strrest});
      then
        str;
    
    case DAE.WILD() then "_";
      
    // Does not handle names with underscores
    case DAE.CREF_QUAL(ident = s,identType=ty,subscriptLst = subs,componentRef = cr)
      equation
        true = Config.modelicaOutput();
        str = printComponentRef2Str(s, subs);
        str2 = Types.unparseType(ty);
        strrest = debugPrintComponentRefTypeStr(cr);
        str = stringAppendList({str," [",str2,"] ", "__", strrest});
      then
        str;
      
  end matchcontinue;
end debugPrintComponentRefTypeStr;


/***************************************************/
/* Compare  */
/***************************************************/

public function crefLastIdentEqual
"function: crefLastIdentEqual
  author: Frenkel TUD
  Returns true if the ComponentRefs has the same name (the last identifier)."
  input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean equal;
protected
  DAE.Ident id1,id2;
algorithm
  id1 := crefLastIdent(cr1);
  id2 := crefLastIdent(cr2);
  equal := stringEq(id1, id2);
end crefLastIdentEqual;

public function crefFirstCrefEqual
"function: crefFirstCrefEqual
  author: Frenkel TUD
  Returns true if the ComponentRefs have the same first Cref."
  input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean equal;
protected
  ComponentRef pcr1,pcr2;
algorithm
  pcr1 := crefFirstCref(cr1);
  pcr2 := crefFirstCref(cr2);
  equal := crefEqual(pcr1,pcr2);
end crefFirstCrefEqual;

public function crefFirstCrefLastCrefEqual
"function: crefFirstCrefEqual
  author: Frenkel TUD
  Returns true if the ComponentRefs have the same first Cref."
  input ComponentRef cr1 "First Cref";
  input ComponentRef cr2 "Last Cref";
  output Boolean equal;
protected
  ComponentRef pcr1,pcr2;
algorithm
  pcr1 := crefFirstCref(cr1);
  pcr2 := crefLastCref(cr2);
  equal := crefEqual(pcr1,pcr2);
end crefFirstCrefLastCrefEqual;

public function crefFirstIdentEqual
  "Returns true if the first identifier in both crefs are the same, otherwise false."
  input ComponentRef inCref1;
  input ComponentRef inCref2;
  output Boolean outEqual;
protected
  DAE.Ident id1, id2;
algorithm
  id1 := crefFirstIdent(inCref1);
  id2 := crefFirstIdent(inCref2);
  outEqual := stringEq(id1, id2);
end crefFirstIdentEqual;
 
public function crefSortFunc "A sorting function (greatherThan) for crefs"
  input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean greaterThan;
algorithm
  greaterThan := stringCompare(printComponentRefStr(cr1),printComponentRefStr(cr2)) > 0;
end crefSortFunc;

public function crefContainedIn
"function: crefContainedIn
  author: PA
  Returns true if second arg is a sub component ref of first arg.
  For instance, b.c. is a sub_component of a.b.c."
  input ComponentRef containerCref "the cref that might contain";
  input ComponentRef containedCref "cref that might be contained";
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (containerCref, containedCref)
    local
      ComponentRef full,partOf,cr2;
      Boolean res;

    // a qualified cref cannot be contained in an ident cref.
    case (DAE.CREF_IDENT(ident = _), DAE.CREF_QUAL(componentRef = _)) then false;
      
    // see if they are equal
    case (full, partOf)
      equation
        true = crefEqualNoStringCompare(full, partOf);
      then
        true;

    // dive into 
    case (full as DAE.CREF_QUAL(componentRef = cr2), partOf)
      equation
        false = crefEqualNoStringCompare(full, partOf);
        res = crefContainedIn(cr2,partOf);
      then
        res;
    
    // anything else is false
    case (_,_) then false;
  end matchcontinue;
end crefContainedIn;

public function crefPrefixOf
"function: crefPrefixOf
  author: PA
  Returns true if prefixCref is a prefix of fullCref
  For example, a.b is a prefix of a.b.c.
  adrpo 2010-10-07, 
    added also that a.b.c is a prefix of a.b.c[1].*!"
  input ComponentRef prefixCref;
  input ComponentRef fullCref;
  output Boolean outBoolean;
algorithm
  outBoolean := match (prefixCref,fullCref)
    local
      ComponentRef cr1,cr2;
      Boolean res;
      DAE.Ident id1,id2;
      list<DAE.Subscript> ss1,ss2;
    
    // first is qualified, second is an unqualified ident, return false!
    case (DAE.CREF_QUAL(ident = _), DAE.CREF_IDENT(ident = _)) then false;
    
    // both are qualified, dive into
    case (DAE.CREF_QUAL(ident = id1, subscriptLst = ss1,componentRef = cr1),
          DAE.CREF_QUAL(ident = id2, subscriptLst = ss2,componentRef = cr2))
      equation
        res = stringEq(id1, id2);
        res = Debug.bcallret2(res, Expression.subscriptEqual, ss1, ss2, false);
        res = Debug.bcallret2(res, crefPrefixOf, cr1, cr2, false);
      then
        res;
    
    // adrpo: 2010-10-07: first is an ID, second is qualified, see if one is prefix of the other
    //                    even if the first one DOESN'T HAVE SUBSCRIPTS!
    case (DAE.CREF_IDENT(ident = id1,subscriptLst = {}),
          DAE.CREF_QUAL(ident = id2,subscriptLst = ss2))
      then stringEq(id1, id2);
    
    // first is an ID, second is qualified, see if one is prefix of the other
    case (DAE.CREF_IDENT(ident = id1,subscriptLst = ss1),
          DAE.CREF_QUAL(ident = id2,subscriptLst = ss2))
      equation
        res = Debug.bcallret2(stringEq(id1, id2), Expression.subscriptEqual, ss1, ss2, false);
      then
        res;
        
    // adrpo: 2010-10-07: first is an ID, second is an ID, see if one is prefix of the other
    //                    even if the first one DOESN'T HAVE SUBSCRIPTS!
    case (DAE.CREF_IDENT(ident = id1,subscriptLst = {}),
          DAE.CREF_IDENT(ident = id2,subscriptLst = ss2))
      then stringEq(id1, id2);
    
    case (DAE.CREF_IDENT(ident = id1,subscriptLst = ss1),
          DAE.CREF_IDENT(ident = id2,subscriptLst = ss2))
      equation
        res = Debug.bcallret2(stringEq(id1, id2), Expression.subscriptEqual, ss1, ss2, false);
      then
        res;
    
    /* adrpo: 2010-10-07. already handled by the cases above!
                          they might be equal, a.b.c is a prefix of a.b.c
    case (cr1,cr2) 
      equation
        true = crefEqualNoStringCompare(cr1, cr2);
      then
        true;*/
    
    // they are not a prefix of one-another
    case (cr1,cr2)
      equation
        // print("Expression.crefPrefixOf: " +& printComponentRefStr(cr1) +& " NOT PREFIX OF " +& printComponentRefStr(cr2) +& "\n");
      then false;
  end match;
end crefPrefixOf;

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
      DAE.Ident n1,n2,s1,s2;
      list<DAE.Subscript> idx1,idx2;
      ComponentRef cr1,cr2;
      
    // check for pointer equality first, if they point to the same thing, they are equal
    case (_,_)
      equation
        true = referenceEq(inComponentRef1,inComponentRef2);
      then
        true;
      
    // simple identifiers
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = {}),DAE.CREF_IDENT(ident = n2,subscriptLst = {}))
      equation
        true = stringEq(n1, n2);
      then
        true;
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = (idx1 as _::_)),DAE.CREF_IDENT(ident = n2,subscriptLst = (idx2 as _::_)))
      equation
        true = stringEq(n1, n2);
        true = Expression.subscriptEqual(idx1, idx2);
      then
        true;
        // BZ 2009-12
        // For some reason in some examples we get crefs on different forms.
        // the compare can be crefEqual(CREF_IDENT("mycref",_,{1,2,3}),CREF_IDENT("mycref[1,2,3]",_,{}))
        // I do belive this has something to do with variable replacement and BackendDAE.
        // TODO: investigate reason, until then keep as is.
        // I do believe that this is the same bug as adrians qual-ident bug below.
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = {}),DAE.CREF_IDENT(ident = n2,subscriptLst = (idx2 as _::_)))
      equation
        0 = System.stringFind(n1, n2); // n2 should be first in n1!
        s1 = n2 +& "[" +& ExpressionDump.printListStr(idx2, ExpressionDump.printSubscriptStr, ",") +& "]";
        true = stringEq(s1,n1);
      then
        true;
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = (idx2 as _::_)),DAE.CREF_IDENT(ident = n2,subscriptLst = {}))
      equation
        0 = System.stringFind(n2, n1); // n1 should be first in n2!
        s1 = n1 +& "[" +& ExpressionDump.printListStr(idx2, ExpressionDump.printSubscriptStr, ",") +& "]";
        true = stringEq(s1,n2);
      then
        true;
    // qualified crefs
    case (DAE.CREF_QUAL(ident = n1,subscriptLst = idx1,componentRef = cr1),DAE.CREF_QUAL(ident = n2,subscriptLst = idx2,componentRef = cr2))
      equation
        true = stringEq(n1, n2);
        true = crefEqualStringCompare(cr1, cr2);
        true = Expression.subscriptEqual(idx1, idx2);
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
        true = stringEq(s1, s2);
        // debug_print("cr1", cr1);
        // debug_print("cr2", cr2);
        // enableTrace();
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
        true = stringEq(s1, s2);
      then
        true;
    // left cref is stringified!
    case (cr1 as DAE.CREF_IDENT(ident = n1),cr2 as DAE.CREF_QUAL(ident = n2))
      equation
        0 = System.stringFind(n1, n2); // n2 should be first in n1!
        s1 = printComponentRefStr(cr1);
        s2 = printComponentRefStr(cr2);
        true = stringEq(s1, s2);
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
  input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean res;
algorithm
  res := crefEqualNoStringCompare2(referenceEq(cr1,cr2),cr1,cr2);
end crefEqualNoStringCompare;

protected function crefEqualNoStringCompare2
"function: crefEqualNoStringCompare
  Returns true if two component references are equal!
  IMPORTANT! do not use this function if you have
  stringified components, meaning this function will
  return false for: cref1: QUAL(x, IDENT(x)) != cref2: IDENT(x.y)"
  input Boolean refEq;
  input ComponentRef inComponentRef1;
  input ComponentRef inComponentRef2;
  output Boolean res;
algorithm
  res := match (refEq,inComponentRef1,inComponentRef2)
    local
      DAE.Ident n1,n2;
      list<DAE.Subscript> idx1,idx2;
      ComponentRef cr1,cr2;

    // check for pointer equality first, if they point to the same thing, they are equal
    case (true,_,_) then true;

    // simple identifiers
    case (_,DAE.CREF_IDENT(ident = n1,subscriptLst = idx1),DAE.CREF_IDENT(ident = n2,subscriptLst = idx2))
      equation
        res = stringEq(n1, n2);
        res = Debug.bcallret2(res, Expression.subscriptEqual, idx1, idx2, false);
      then res;
    // qualified crefs
    case (_,DAE.CREF_QUAL(ident = n1,subscriptLst = idx1,componentRef = cr1),DAE.CREF_QUAL(ident = n2,subscriptLst = idx2,componentRef = cr2))
      equation
        res = stringEq(n1, n2);
        res = Debug.bcallret3(res, crefEqualNoStringCompare2, referenceEq(cr1,cr2), cr1, cr2, false);
        res = Debug.bcallret2(res, Expression.subscriptEqual, idx1, idx2, false);
      then res;
    // the crefs are not equal!
    else false;
  end match;
end crefEqualNoStringCompare2;

public function crefEqualReturn
"function: crefEqualReturn
  author: PA
  Checks if two crefs are equal and if
  so returns the cref, otherwise fail."
  input ComponentRef cr;
  input ComponentRef cr2;
  output ComponentRef ocr;
algorithm
  true := crefEqualNoStringCompare(cr, cr2);
  ocr := cr;
end crefEqualReturn;

public function crefEqualWithoutLastSubs
  "Checks if two crefs are equal, without considering their last subscripts."
  input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean res;
algorithm
  res := crefEqualNoStringCompare(crefStripLastSubs(cr1),crefStripLastSubs(cr2));
end crefEqualWithoutLastSubs;

public function crefEqualWithoutSubs
  "Checks if two crefs are equal, without considering their subscripts."
  input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean res;
algorithm
  res := crefEqualWithoutSubs2(referenceEq(cr1, cr2), cr1, cr2);
end crefEqualWithoutSubs;

protected function crefEqualWithoutSubs2
  input Boolean refEq;
  input ComponentRef icr1;
  input ComponentRef icr2;
  output Boolean res;
algorithm
  res := match(refEq, icr1, icr2)
    local
      DAE.Ident n1, n2;
      Boolean r;
      ComponentRef cr1,cr2;

    case (true, _, _) then true;

    case (_, DAE.CREF_IDENT(ident = n1), DAE.CREF_IDENT(ident = n2))
      then stringEq(n1, n2);

    case (_, DAE.CREF_QUAL(ident = n1, componentRef = cr1), 
             DAE.CREF_QUAL(ident = n2, componentRef = cr2))
      equation
        r = stringEq(n1, n2);
        r = Debug.bcallret3(r, crefEqualWithoutSubs2, referenceEq(cr1, cr2),
          cr1, cr2, false);
      then
        r;

    else false;
  end match;
end crefEqualWithoutSubs2;
        
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

public function isRecord "
function isRecord
  returns true if the type of the last ident is a record"
  input ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(cr)
  local 
    ComponentRef comp;
    case(DAE.CREF_IDENT(identType = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)))) then true;
    /* this case is false because it is not the last ident.   
    case(DAE.CREF_QUAL(identType = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)))) then true;*/
    case(DAE.CREF_QUAL(componentRef=comp)) then isRecord(comp);
    case(_) then false;
  end matchcontinue;
end isRecord;

public function isArrayElement "
function isArrayElement
  returns true if cref is elemnt of an array"
  input ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(cr)
  local 
    ComponentRef comp;
    case(DAE.CREF_IDENT(identType = DAE.T_ARRAY(ty=_))) then true;
    case(DAE.CREF_QUAL(identType = DAE.T_ARRAY(ty=_))) then true;
    case(DAE.CREF_QUAL(componentRef=comp)) then isArrayElement(comp);
    case(_) then false;
  end matchcontinue;
end isArrayElement;

public function isPreCref
  input ComponentRef cr;
  output Boolean b;
algorithm
  b := match(cr)
    case(DAE.CREF_QUAL(ident = "$PRE")) then true;
    else then false;
  end match;
end isPreCref;

public function popPreCref
  input ComponentRef inCR;
  output ComponentRef outCR;
algorithm
  outCR := match(inCR)
    local ComponentRef cr;
    case(DAE.CREF_QUAL(ident = "$PRE", componentRef=cr)) then cr;
    else then inCR;
  end match;
end popPreCref;

public function popCref
  input ComponentRef inCR;
  output ComponentRef outCR;
algorithm
  outCR := match(inCR)
    local ComponentRef cr;
    case(DAE.CREF_QUAL(componentRef=cr)) then cr;
    else then inCR;
  end match;
end popCref;

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
      list<DAE.Subscript> subs;
      list<DAE.Exp> exps;
      ComponentRef cr;
    case (cr)
      equation
        ((subs as (_ :: _))) = crefLastSubs(cr);
        exps = List.map(subs, Expression.subscriptIndexExp);
        // fails if any mapped functions returns false
      then List.mapAllValueBool(exps, Expression.isOne, true);
    else false;
  end matchcontinue;
end crefIsFirstArrayElt;

public function crefHaveSubs "Function: crefHaveSubs
  Checks whether Componentref has any subscripts, recursive "
  input ComponentRef icr;
  output Boolean ob;
algorithm ob := matchcontinue(icr)
  local ComponentRef cr; Boolean b; DAE.Ident str; Integer idx;
  case(DAE.CREF_QUAL(subscriptLst = _ :: _)) then true;
  case(DAE.CREF_IDENT(subscriptLst = _ :: _)) then true;
  case(DAE.CREF_IDENT(ident = str,subscriptLst ={})) // for stringified crefs!
    equation
      idx = System.stringFind(str, "["); // (-1 on failure)
      idx > 0 = true; // index should be more than 0!
    then true;
  case(DAE.CREF_QUAL(subscriptLst = {},componentRef = cr))
    equation
      b = crefHaveSubs(cr);
    then b;
  case(_) then false;
end matchcontinue;
end crefHaveSubs;

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
    list<DAE.Subscript> subs;
    DAE.Type tp;
    DAE.Dimensions dims;
    
    /* No subscripts */
    case _ equation {} = crefLastSubs(cr); then true;
      
      /* constant Subscripts that match type => true */ 
    case _ equation
      (subs as (_::_))= crefLastSubs(cr);
      true = Expression.subscriptConstants(subs);
      tp = crefLastType(cr);
      dims = Expression.arrayDimension(tp);
      // Since all subscripts are constants, sufficient to compare length of dimensions
      // Dimensions may be removed when a component is instantiated if it has
      // constant subscripts though, so it may have more subscripts than
      // dimensions.
      true = listLength(dims) <= listLength(subs);
    then true;
      
      /* All other cases are false */
    case _ then false;
  end matchcontinue;
end crefHasScalarSubscripts;

public function containWholeDim " A function to check if a cref contains a [:] wholedim element in the subscriptlist.
"
  input ComponentRef inRef;
  output Boolean wholedim;

algorithm
  wholedim :=
  matchcontinue(inRef)
    local
      ComponentRef cr;
      list<DAE.Subscript> ssl;
      DAE.Ident name;
      DAE.Type ty;
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

protected function containWholeDim2 "
  A function to check if a cref contains a [:] wholedim element in the subscriptlist."
  input list<DAE.Subscript> inRef;
  input DAE.Type inType;
  output Boolean wholedim;
algorithm
  wholedim := matchcontinue(inRef,inType)
    local
      DAE.Subscript ss;
      list<DAE.Subscript> ssl;
      DAE.Ident name;
      Boolean b;
      DAE.Type tty;
      DAE.Dimensions ad;
      DAE.Exp es1;
      DAE.TypeSource ts;
    
    case({},_) then false;
    
    case((ss as DAE.WHOLEDIM())::ssl,DAE.T_ARRAY(tty,ad,ts)) then true;
    
    case((ss as DAE.SLICE(es1))::ssl, DAE.T_ARRAY(tty,ad,ts))
      equation
        true = containWholeDim3(es1,ad);
      then
        true;
    
    case(_::ssl,DAE.T_ARRAY(tty,ad,ts))
      equation
        ad = List.stripFirst(ad);
        b = containWholeDim2(ssl,DAE.T_ARRAY(tty,ad,ts));
      then 
        b;
    
    case(_::ssl,inType)
      equation
        wholedim = containWholeDim2(ssl,inType);
      then
        wholedim;
  end matchcontinue;
end containWholeDim2;

protected function containWholeDim3 "function: containWholeDim3
Verify that a slice adresses all dimensions"
  input DAE.Exp inExp;
  input DAE.Dimensions ad;
  output Boolean ob;
algorithm 
  ob := matchcontinue(inExp,ad)
    local
      list<DAE.Exp> expl;
      Integer x1,x2;
      DAE.Dimension d;
  
    case(DAE.ARRAY(array=expl), d :: _)
      equation
        x1 = listLength(expl);
        x2 = Expression.dimensionSize(d);
        true = intEq(x1, x2);
      then
        true;
    
    case(_,_) then false;
  end matchcontinue;
end containWholeDim3;

/***************************************************/
/* Getter  */
/***************************************************/
public function crefLastPath
  "Returns the last identifier of a cref as an Absyn.IDENT."
  input ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath := match(inComponentRef)
    local
      DAE.Ident i;
      ComponentRef c;
    case DAE.CREF_IDENT(ident = i, subscriptLst = {}) then Absyn.IDENT(i);
    case DAE.CREF_QUAL(componentRef = c, subscriptLst = {}) then crefLastPath(c);
  end match;
end crefLastPath;

public function crefFirstIdent
  "Returns the first identifier of a component reference."
  input ComponentRef inComponentRef;
  output DAE.Ident outIdent;
algorithm
  outIdent := match(inComponentRef)
    local
      DAE.Ident id;

    case DAE.CREF_IDENT(ident = id) then id;
    case DAE.CREF_QUAL(ident = id) then id;
  end match;
end crefFirstIdent;

public function crefLastIdent
"function: crefLastIdent
  author: PA
  Returns the last identfifier of a ComponentRef."
  input ComponentRef inComponentRef;
  output DAE.Ident outIdent;
algorithm
  outIdent := match (inComponentRef)
    local
      DAE.Ident id,res;
      ComponentRef cr;
    
    case (DAE.CREF_IDENT(ident = id)) then id;
    
    case (DAE.CREF_QUAL(componentRef = cr))
      equation
        res = crefLastIdent(cr);
      then
        res;
  end match;
end crefLastIdent;

public function crefLastCref "
  Return the last ComponentRef"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef := match (inComponentRef)
    local
      DAE.Ident id;
      ComponentRef res,cr;
    
    case (DAE.CREF_IDENT(ident = id)) then inComponentRef;
    
    case (DAE.CREF_QUAL(componentRef = cr))
      equation
        res = crefLastCref(cr);
      then
        res;
  end match;
end crefLastCref;

public function crefType
  "Function for extracting the type of the first identifier of a cref."
  input ComponentRef inCref;
  output DAE.Type outType;
algorithm
  outType := match(inCref)
    local
      DAE.Type ty;
    
    case DAE.CREF_IDENT(identType = ty) then ty;
    case DAE.CREF_QUAL(identType = ty) then ty;
    
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("ComponentReference.crefType failed on cref: ");
        Debug.traceln(printComponentRefStr(inCref));
      then
        fail();

  end match;
end crefType;

public function crefLastType "returns the 'last' type of a cref.
For instance, for the cref 'a.b' it returns the type in identifier 'b'
adrpo:
  NOTE THAT THIS WILL BE AN ARRAY TYPE IF THE LAST CREF IS AN ARRAY TYPE
  If you want to get the component reference type considering subscripts use:
  crefTypeConsiderSubs"
  input ComponentRef inRef;
  output DAE.Type res;
algorithm
  res := match (inRef)
    local
      DAE.Type t2;
      ComponentRef cr;
    
    case(DAE.CREF_IDENT(_,t2,_)) then t2;
    case(DAE.CREF_QUAL(_,_,_,cr)) then crefLastType(cr);
  end match;
end crefLastType;

public function crefSubs "
function: crefSubs
  Return the all subscripts of a ComponentRef"
  input ComponentRef inComponentRef;
  output list<DAE.Subscript> outSubscriptLst;
algorithm
  outSubscriptLst := match (inComponentRef)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs,res;
      ComponentRef cr;
    
    case (DAE.CREF_IDENT(ident = id,subscriptLst = subs)) then subs;
    
    case (DAE.CREF_QUAL(componentRef = cr,subscriptLst=subs))
      equation
        res = crefSubs(cr);
        res = listAppend(subs,res);
      then
        res;
  end match;
end crefSubs;

public function crefLastSubs "
function: crefLastSubs
  Return the last subscripts of a ComponentRef"
  input ComponentRef inComponentRef;
  output list<DAE.Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  match (inComponentRef)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs,res;
      ComponentRef cr;
    case (DAE.CREF_IDENT(ident = id,subscriptLst = subs)) then subs;
    case (DAE.CREF_QUAL(componentRef = cr))
      equation
        res = crefLastSubs(cr);
      then
        res;
  end match;
end crefLastSubs;

public function crefFirstCref
"Returns the first part of a component reference, i.e the identifier"
  input ComponentRef inCr;
  output ComponentRef outCr;
algorithm
  outCr := match(inCr)
    local 
      DAE.Ident id;
      list<DAE.Subscript> subs;
      ComponentRef cr;
      DAE.Type t2;
    
    case( DAE.CREF_QUAL(id,t2,subs,cr)) then makeCrefIdent(id,t2,subs);
    case( DAE.CREF_IDENT(id,t2,subs)) then inCr;
  end match;
end crefFirstCref;

public function crefTypeConsiderSubs "Function: crefTypeConsiderSubs 
Author: PA
Function for extracting the type out of a componentReference and consider the influence of the last subscript list. 
For exampel. If the last cref type is Real[3,3] and the last subscript list is {Expression.INDEX(1)}, the type becomes Real[3], i.e
one dimension is lifted.
See also, crefType.
"
  input ComponentRef cr;
  output DAE.Type res;
algorithm 
 res := Expression.unliftArrayTypeWithSubs(crefLastSubs(cr),crefLastType(cr));
end crefTypeConsiderSubs;

public function crefNameType "Function: crefType
Function for extracting the name and type out of the first cref of a componentReference.
"
  input ComponentRef inRef;
  output DAE.Ident id;
  output DAE.Type res;
algorithm
  (id,res) :=
  matchcontinue (inRef)
    local
      DAE.Type t2;
      DAE.Ident name;
      String s;
    
    case(inRef as DAE.CREF_IDENT(name,t2,_)) then (name,t2);
    
    case(inRef as DAE.CREF_QUAL(name,t2,_,_)) then (name,t2);
    
    case(inRef)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprint(Flags.FAILTRACE, "-ComponentReference.crefType failed on Cref:");
        s = printComponentRefStr(inRef);
        Debug.fprint(Flags.FAILTRACE, s);
        Debug.fprint(Flags.FAILTRACE, "\n");
      then
        fail();
  end matchcontinue;
end crefNameType;

/***************************************************/
/* Change  */
/***************************************************/

public function crefPrependIdent "prepends (e..g as a suffix) an identifier to a component reference, given the identifier, subscript and the type
author: PA

  The crefPrependIdent function extends a ComponentRef by appending
  an identifier and a (possibly empty) list of subscripts.  Adding
  the identifier A to the component reference x.y[10] would
  produce the component reference x.y[10].A, for instance.

Example
crefPrependIdent(a.b,c,{},Real) => a.b.c [Real]
crefPrependIdent(a,c,{1},Integer[1]) => a.c[1] [Integer[1]]

alternative names: crefAddSuffix, crefAddIdent
"
  input ComponentRef icr;
  input String ident;
  input list<DAE.Subscript> subs;
  input DAE.Type tp;
  output ComponentRef newCr;
algorithm
  newCr := match(icr,ident,subs,tp)
    local 
      DAE.Type tp1; String id1; list<DAE.Subscript> subs1;
      ComponentRef cr;
    
    case(DAE.CREF_IDENT(id1,tp1,subs1),_,_,_) 
      then 
        makeCrefQual(id1,tp1,subs1,makeCrefIdent(ident,tp,subs));
    
    case(DAE.CREF_QUAL(id1,tp1,subs1,cr),_,_,_)
      equation
        cr = crefPrependIdent(cr,ident,subs,tp);
      then 
        makeCrefQual(id1,tp1,subs1,cr);
  end match;
end crefPrependIdent;

public function crefPrefixDer "public function crefPrefixDer
  Appends $DER to a cref, so a => $DER.a"
  input ComponentRef inCref;
  output ComponentRef outCref;
algorithm
  outCref := makeCrefQual(DAE.derivativeNamePrefix, DAE.T_REAL_DEFAULT, {}, inCref);
end crefPrefixDer;

public function crefPrefixPre "public function crefPrefixPre
  Appends $PRE to a cref, so a => $PRE.a"
  input ComponentRef inCref;
  output ComponentRef outCref;
algorithm
  outCref := makeCrefQual(DAE.preNamePrefix, DAE.T_UNKNOWN_DEFAULT, {}, inCref);
end crefPrefixPre;

public function crefPrefixString
  "Prefixes a cref with a string identifier, e.g.:
    crefPrefixString(a, b.c) => a.b.c"
  input String inString;
  input ComponentRef inCref;
  output ComponentRef outCref;
algorithm
  outCref := makeCrefQual(inString, DAE.T_UNKNOWN_DEFAULT, {}, inCref);
end crefPrefixString;

public function crefPrefixStringList
  "Prefixes a cref with a list of strings, e.g.:
    crefPrefixStringList({a, b, c}, d.e.f) => a.b.c.d.e.f"
  input list<String> inStrings;
  input ComponentRef inCref;
  output ComponentRef outCref;
algorithm
  outCref := match(inStrings, inCref)
    local
      String str;
      list<String> rest_str;
      ComponentRef cref;

    case (str :: rest_str, cref)
      equation
        cref = crefPrefixStringList(rest_str, cref);
        cref = crefPrefixString(str, cref);
      then
        cref;

    else inCref;

  end match;
end crefPrefixStringList;

public function prefixWithPath
  input ComponentRef inCref;
  input Absyn.Path inPath;
  output ComponentRef outCref;
algorithm
  outCref := match(inCref, inPath)
    local
      Absyn.Ident name;
      Absyn.Path rest_path;
      ComponentRef cref;

    case (_, Absyn.IDENT(name = name))
      then DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, {}, inCref);

    case (_, Absyn.QUALIFIED(name = name, path = rest_path))
      equation
        cref = prefixWithPath(inCref, rest_path);
      then
        DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, {}, cref);

    case (_, Absyn.FULLYQUALIFIED(path = rest_path))
      then prefixWithPath(inCref, rest_path);

  end match;
end prefixWithPath;

public function prependStringCref
"function: prependStringCref
  Prepend a string to a component reference.
  For qualified named, this means prepending a
  string to the first identifier."
  input String inString;
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inString,inComponentRef)
    local
      DAE.Ident i_1,p,i;
      list<DAE.Subscript> s;
      ComponentRef c;
      DAE.Type t2;
    
    case (p,DAE.CREF_QUAL(ident = i, identType = t2, subscriptLst = s,componentRef = c))
      equation
        i_1 = stringAppend(p, i);
      then
        makeCrefQual(i_1,t2,s,c);
    
    case (p,DAE.CREF_IDENT(ident = i, identType = t2, subscriptLst = s))
      equation
        i_1 = stringAppend(p, i);
      then
        makeCrefIdent(i_1,t2,s);
  end match;
end prependStringCref;

public function appendStringCref
  input String str;
  input ComponentRef cr;
  output ComponentRef ocr;
algorithm
  ocr := joinCrefs(cr,DAE.CREF_IDENT(str,DAE.T_UNKNOWN_DEFAULT,{}));
end appendStringCref;

public function joinCrefs
"function: joinCrefs
  Join two component references by concatenating them.
  
  alternative names: crefAppend

  "
  input ComponentRef inComponentRef1 " first part of the new componentref";
  input ComponentRef inComponentRef2 " last part of the new componentref";
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef1,inComponentRef2)
    local
      DAE.Ident id;
      list<DAE.Subscript> sub;
      ComponentRef cr2,cr_1,cr;
      DAE.Type t2;
    
    case (DAE.CREF_IDENT(ident = id, identType = t2, subscriptLst = sub),cr2) 
      then 
        makeCrefQual(id,t2,sub,cr2);
    
    case (DAE.CREF_QUAL(ident = id, identType = t2, subscriptLst = sub,componentRef = cr),cr2)
      equation
        cr_1 = joinCrefs(cr, cr2);
      then
        makeCrefQual(id,t2,sub,cr_1);
  end match;
end joinCrefs;

public function subscriptCref
"function: subscriptCref
  The subscriptCref function adds a subscript to the ComponentRef
  For instance a.b with subscript 10 becomes a.b[10] and c.d[1,2]
  with subscript 3,4 becomes c.d[1,2,3,4]"
  input ComponentRef inComponentRef;
  input list<DAE.Subscript> inSubscriptLst;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef,inSubscriptLst)
    local
      list<DAE.Subscript> newsub_1,sub,newsub;
      DAE.Ident id;
      ComponentRef cref_1,cref;
      DAE.Type t2;
    
    case (DAE.CREF_IDENT(ident = id,subscriptLst = sub, identType = t2),newsub)
      equation
        newsub_1 = listAppend(sub, newsub);
      then
        makeCrefIdent(id, t2, newsub_1);
    
    case (DAE.CREF_QUAL(ident = id,subscriptLst = sub,componentRef = cref, identType = t2),newsub)
      equation
        cref_1 = subscriptCref(cref, newsub);
      then
        makeCrefQual(id, t2, sub,cref_1);
  end match;
end subscriptCref;

public function subscriptCrefWithInt
  "Subscripts a component reference with a constant integer. It also unlifts the
  type of the components reference so that the type of the reference is correct
  with regards to the subscript. If the reference is not of array type this
  function will fail."
  input ComponentRef inComponentRef;
  input Integer inSubscript;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := match(inComponentRef, inSubscript)
    local
      list<DAE.Subscript> subs;
      DAE.Subscript new_sub;
      DAE.Ident id;
      ComponentRef rest_cref;
      DAE.Type ty;

    case (DAE.CREF_IDENT(ident = id, subscriptLst = subs, identType = ty), _)
      equation
        new_sub = DAE.INDEX(DAE.ICONST(inSubscript));
        subs = listAppend(subs, {new_sub});
        ty = Expression.unliftArray(ty);
      then
        makeCrefIdent(id, ty, subs);

    case (DAE.CREF_QUAL(ident = id, subscriptLst = subs, 
          componentRef = rest_cref, identType = ty), _)
      equation
        rest_cref = subscriptCrefWithInt(rest_cref, inSubscript);
      then
        makeCrefQual(id, ty, subs, rest_cref);

  end match;
end subscriptCrefWithInt;

public function crefSetLastSubs "
function: crefSetLastSubs
  sets the subs of the last componenentref ident"
  input ComponentRef inComponentRef;
  input list<DAE.Subscript> insubs;
  output ComponentRef outComponentRef;
algorithm 
  outComponentRef := match (inComponentRef,insubs)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs,s;
      ComponentRef cr_1,cr;
      DAE.Type t2;
    
    case (DAE.CREF_IDENT(ident = id,identType = t2,subscriptLst = subs),_) 
      then makeCrefIdent(id,t2,insubs);
    
    case (DAE.CREF_QUAL(ident = id,identType = t2,subscriptLst = s,componentRef = cr),_)
      equation
        cr_1 = crefSetLastSubs(cr,insubs);
      then
        makeCrefQual(id,t2,s,cr_1);
  end match;
end crefSetLastSubs;

public function crefSetLastType "
sets the 'last' type of a cref."
  input ComponentRef inRef;
  input DAE.Type newType;
  output ComponentRef outRef;
algorithm 
  outRef := matchcontinue (inRef,newType)
    local
      DAE.Type ty;
      ComponentRef child;
      list<DAE.Subscript> subs;
      DAE.Ident id;
    
    case(DAE.CREF_IDENT(id,_,subs),_)
      then
        makeCrefIdent(id,newType,subs);
    
    case(DAE.CREF_QUAL(id,ty,subs,child),_)
      equation
        child = crefSetLastType(child,newType);
      then
        makeCrefQual(id,ty,subs,child);
  end matchcontinue;
end crefSetLastType;

public function replaceCrefSliceSub "
Go trough ComponentRef searching for a slice eighter in
qual's or finaly ident. if none find, add dimension to DAE.CREF_IDENT(,ss:INPUTARG,)"
  input ComponentRef inCr;
  input list<DAE.Subscript> newSub;
  output ComponentRef outCr;
algorithm 
  outCr := matchcontinue(inCr,newSub)
    local
      DAE.Type t2,identType;
      ComponentRef child;
      list<DAE.Subscript> subs;
      String name;
      
    // debugging case, uncomment for enabling
    // case(child,newSub)
    //  equation
    //    str1 = printComponentRefStr(child);
    //    str2 = stringDelimitList(List.map(newSub, printSubscriptStr), ", ");
    //    str  = "replaceCrefSliceSub(" +& str1 +& " subs: [" +& str2 +& "]\n";
    //    print(str);
    //  then
    //    fail();
      
    // Case where we try to find a Expression.DAE.SLICE()
    case(DAE.CREF_IDENT(name,identType,subs),newSub)
      equation
        subs = replaceSliceSub(subs, newSub);
      then
        makeCrefIdent(name,identType,subs);
        
    // case where there is not existant Expression.DAE.SLICE() as subscript
    case( child as DAE.CREF_IDENT(identType  = t2, subscriptLst = subs),newSub)
      equation
        true = (listLength(Expression.arrayTypeDimensions(t2)) >= (listLength(subs)+1));
        child = subscriptCref(child,newSub);
      then
        child;
        
    case( child as DAE.CREF_IDENT(identType  = t2, subscriptLst = subs),newSub)
      equation
        false = (listLength(Expression.arrayTypeDimensions(t2)) >= (listLength(subs)+listLength(newSub)));
        child = subscriptCref(child,newSub);
        Debug.fprintln(Flags.FAILTRACE, "WARNING - Expression.replaceCref_SliceSub setting subscript last, not containing dimension");
      then
        child;
        
    // Try DAE.CREF_QUAL with DAE.SLICE subscript
    case(DAE.CREF_QUAL(name,identType,subs,child),newSub)
      equation
        subs = replaceSliceSub(subs, newSub);
      then
        makeCrefQual(name,identType,subs,child);
        
    // case where there is not existant Expression.DAE.SLICE() as subscript in CREF_QUAL
    case(DAE.CREF_QUAL(name,identType,subs,child),newSub)
      equation
        true = (listLength(Expression.arrayTypeDimensions(identType)) >= (listLength(subs)+1));
        subs = listAppend(subs,newSub);
      then
        makeCrefQual(name,identType,subs,child);
        
    // DAE.CREF_QUAL without DAE.SLICE, search child
    case(DAE.CREF_QUAL(name,identType,subs,child),newSub)
      equation
        child = replaceCrefSliceSub(child,newSub);
      then
        makeCrefQual(name,identType,subs,child);
        
    case(_,_)
      equation
        Debug.fprint(Flags.FAILTRACE, "- Expression.replaceCref_SliceSub failed\n ");
      then
        fail();
  end matchcontinue;
end replaceCrefSliceSub;

protected function replaceSliceSub "
A function for replacing any occurance of DAE.SLICE or DAE.WHOLEDIM with new sub."
  input list<DAE.Subscript> inSubs;
  input list<DAE.Subscript> inSub;
  output list<DAE.Subscript> osubs;
algorithm
  osubs := matchcontinue(inSubs,inSub)
    local
      list<DAE.Subscript> subs;
      DAE.Subscript sub;
    
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
      DAE.Ident id;
      ComponentRef cr;
      DAE.Type ty;
      list<DAE.Subscript> subs;
    
    case (DAE.CREF_IDENT(ident = id,subscriptLst=subs, identType = ty))
      equation
        subs = removeSliceSubs(subs);
      then 
        makeCrefIdent(id,ty,subs);
    
    case (DAE.CREF_QUAL(componentRef = cr, identType=ty, subscriptLst=subs, ident=id))
      equation
        outCref = stripCrefIdentSliceSubs(cr);
      then
        makeCrefQual(id,ty,subs,outCref);
  end matchcontinue;
end stripCrefIdentSliceSubs;

protected function removeSliceSubs "
helper function for stripCrefIdentSliceSubs"
  input list<DAE.Subscript> subs;
  output list<DAE.Subscript> osubs;
algorithm
  osubs := matchcontinue(subs)
    local DAE.Subscript s;
    
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
  outCref := match(inCref)
    local
      DAE.Ident id;
      ComponentRef cr;
      DAE.Type ty;
    
    case (DAE.CREF_IDENT(ident = id,identType = ty))
      then makeCrefIdent(id,ty,{});
    
    case (DAE.CREF_QUAL(componentRef = cr, identType=ty, ident=id))
      equation
        outCref = crefStripSubs(cr);
      then
        makeCrefQual(id,ty,{},outCref);
  end match;
end crefStripSubs;

public function crefStripPrefix
"Strips a prefix/cref from a component reference"
  input ComponentRef cref;
  input ComponentRef prefix;
  output ComponentRef outCref;
algorithm
  outCref := match(cref,prefix)
    local
      list<DAE.Subscript> subs1,subs2;
      ComponentRef cr1,cr2;
      DAE.Ident id1,id2;
    
    case(DAE.CREF_QUAL(id1,_,subs1,cr1),DAE.CREF_IDENT(id2,_,subs2))
      equation
        true = stringEq(id1, id2);
        true = Expression.subscriptEqual(subs1,subs2);
      then cr1;
    
    case(DAE.CREF_QUAL(id1,_,subs1,cr1),DAE.CREF_QUAL(id2,_,subs2,cr2))
      equation
        true = stringEq(id1, id2);
        true = Expression.subscriptEqual(subs1,subs2);
      then crefStripPrefix(cr1,cr2);
  end match;
end crefStripPrefix;

public function crefStripLastIdent
"Strips the last part of a component reference, i.e ident and subs"
  input ComponentRef inCr;
  output ComponentRef outCr;
algorithm
  outCr := matchcontinue(inCr)
    local 
      DAE.Ident id;
      list<DAE.Subscript> subs;
      ComponentRef cr1,cr;
      DAE.Type t2;
    
    case( DAE.CREF_QUAL(id,t2,subs,DAE.CREF_IDENT(_,_,_))) 
      then 
        makeCrefIdent(id,t2,subs);

    case(DAE.CREF_QUAL(id,t2,subs,cr)) 
      equation
        cr1 = crefStripLastIdent(cr);
      then 
        makeCrefQual(id,t2,subs,cr1);
  end matchcontinue;
end crefStripLastIdent;

public function crefStripLastSubs
"function: crefStripLastSubs
  Strips the last subscripts of a ComponentRef"
  input ComponentRef inComponentRef;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs,s;
      ComponentRef cr_1,cr;
      DAE.Type t2;
    
    case (DAE.CREF_IDENT(ident = id,identType = t2,subscriptLst = subs)) 
      then 
        makeCrefIdent(id,t2,{});
    
    case (DAE.CREF_QUAL(ident = id,identType = t2,subscriptLst = s,componentRef = cr))
      equation
        cr_1 = crefStripLastSubs(cr);
      then
        makeCrefQual(id,t2,s,cr_1);
  end match;
end crefStripLastSubs;

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
      list<DAE.Ident> lst,lst_1;
      DAE.Ident id_1,id;
      ComponentRef cr;
      DAE.Type t2;
    
    case (DAE.CREF_IDENT(ident = id,identType = t2,subscriptLst = {}))
      equation
        //print("\n +++++++++++++++++++++++++++++ ");print(id);print("\n");
        lst = Util.stringSplitAtChar(id, "[");
        lst_1 = List.stripLast(lst);
        id_1 = stringDelimitList(lst_1, "[");
      then
        makeCrefIdent(id_1,t2,{});
    
    case (cr) then cr;

  end matchcontinue;
end crefStripLastSubsStringified;

public function stringifyComponentRef
"function: stringifyComponentRef
  Translates a ComponentRef into a DAE.CREF_IDENT by putting
  the string representation of the ComponentRef into it.
  See also stringigyCrefs.

  NOTE: This function should not be used in OMC, since the OMC backend no longer
    uses stringified components. It is still used by MathCore though."
  input ComponentRef cr;
  output ComponentRef outComponentRef;
protected
  list<DAE.Subscript> subs;
  ComponentRef cr_1;
  DAE.Ident crs;
  DAE.Type ty;
algorithm
  subs := crefLastSubs(cr);
  cr_1 := crefStripLastSubs(cr);
  crs := printComponentRefStr(cr_1);
  ty := crefLastType(cr) "The type of the stringified cr is taken from the last identifier";
  outComponentRef := makeCrefIdent(crs,ty,subs);
end stringifyComponentRef;

/***************************************************/
/* Print and Dump */
/***************************************************/

public function printComponentRef
"function: printComponentRef
  Print a ComponentRef."
  input ComponentRef inComponentRef;
algorithm
  _ := matchcontinue (inComponentRef)
    local
      DAE.Ident s;
      list<DAE.Subscript> subs;
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
        true = Config.modelicaOutput();
        printComponentRef2(s, subs);
        Print.printBuf("__");
        printComponentRef(cr);
      then
        ();
    case DAE.CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr)
      equation
        false = Config.modelicaOutput();
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
  input DAE.Ident inString;
  input list<DAE.Subscript> inSubscriptLst;
algorithm
  _ := matchcontinue (inString,inSubscriptLst)
    local
      DAE.Ident s;
      list<DAE.Subscript> l;
    case (s,{})
      equation
        Print.printBuf(s);
      then
        ();
    case (s,l)
      equation
        true = Config.modelicaOutput();
        Print.printBuf(s);
        Print.printBuf("_L");
        ExpressionDump.printList(l, ExpressionDump.printSubscript, ",");
        Print.printBuf("_R");
      then
        ();
    case (s,l)
      equation
        false = Config.modelicaOutput();
        Print.printBuf(s);
        Print.printBuf("[");
        ExpressionDump.printList(l, ExpressionDump.printSubscript, ",");
        Print.printBuf("]");
      then
        ();
  end matchcontinue;
end printComponentRef2;

public function printComponentRefListStr
  input list<ComponentRef> crs;
  output String res;
algorithm
  res := "{" +& stringDelimitList(List.map(crs, printComponentRefStr), ",") +& "}";
end printComponentRefListStr;

public function printComponentRefList
  input list<ComponentRef> crs;
protected
  String buffer;
algorithm
  buffer := "{" +& stringDelimitList(List.map(crs, printComponentRefStr), ", ") +& "}\n";
  print(buffer);
end printComponentRefList;

public function replaceWholeDimSubscript
  input ComponentRef icr;
  input Integer index;
  output ComponentRef ocr;
algorithm
  ocr := matchcontinue (icr,index)
    local
      String id;
      DAE.Type et;
      list<DAE.Subscript> ss;
      ComponentRef cr;
      
    case (DAE.CREF_QUAL(id,et,ss,cr),_)
      equation
        ss = replaceWholeDimSubscript2(ss,index);
      then DAE.CREF_QUAL(id,et,ss,cr);
    case (DAE.CREF_QUAL(id,et,ss,cr),_)
      equation
        cr = replaceWholeDimSubscript(cr,index);
      then DAE.CREF_QUAL(id,et,ss,cr);
    case (DAE.CREF_IDENT(id,et,ss),_)
      equation
        ss = replaceWholeDimSubscript2(ss,index);
      then DAE.CREF_IDENT(id,et,ss);
  end matchcontinue;
end replaceWholeDimSubscript;

public function replaceWholeDimSubscript2
  input list<DAE.Subscript> isubs;
  input Integer index;
  output list<DAE.Subscript> osubs;
algorithm
  osubs := match (isubs,index)
    local
      DAE.Subscript sub;
      list<DAE.Subscript> subs;
      
    case (DAE.WHOLEDIM()::subs,_)
      equation
        sub = DAE.INDEX(DAE.ICONST(index));
      then sub::subs;
    // TODO: SLICE, NONEXP
    case (sub::subs,_)
      equation
        subs = replaceWholeDimSubscript2(subs,index);
      then sub::subs;
  end match;
end replaceWholeDimSubscript2;

public function splitCrefLast
  "Splits a cref at the end, e.g. a.b.c.d => {a.b.c, d}."
  input ComponentRef inCref;
  output ComponentRef outPrefixCref;
  output ComponentRef outLastCref;
algorithm
  (outPrefixCref, outLastCref) := match(inCref)
    local
      DAE.Ident id;
      DAE.Type ty;
      list<DAE.Subscript> subs;
      ComponentRef prefix, last;
      
    case DAE.CREF_QUAL(id, ty, subs, last as DAE.CREF_IDENT(ident = _))
      then (DAE.CREF_IDENT(id, ty, subs), last);

    case DAE.CREF_QUAL(id, ty, subs, last)
      equation
        (prefix, last) = splitCrefLast(last);
      then
        (DAE.CREF_QUAL(id, ty, subs, prefix), last);

  end match;
end splitCrefLast;

public function splitCrefFirst
  input ComponentRef inCref;
  output ComponentRef outCrefFirst;
  output ComponentRef outCrefRest;
protected
  DAE.Ident id;
  DAE.Type ty;
  list<DAE.Subscript> subs;
algorithm
  DAE.CREF_QUAL(id, ty, subs, outCrefRest) := inCref;
  outCrefFirst := DAE.CREF_IDENT(id, ty, subs);
end splitCrefFirst;

public function toStringList
  "Converts a component reference to a list of strings."
  input ComponentRef inCref;
  output list<String> outStringList;
algorithm
  outStringList := toStringList_tail(inCref, {});
end toStringList;

protected function toStringList_tail
  "Tail-recursive implementation of toStringList."
  input ComponentRef inCref;
  input list<String> inAccumStrings;
  output list<String> outStringList;
algorithm
  outStringList := match(inCref, inAccumStrings)
    local
      String id;
      ComponentRef cref;

    case (DAE.CREF_QUAL(ident = id, componentRef = cref), _)
      then toStringList_tail(cref, id :: inAccumStrings);

    case (DAE.CREF_IDENT(ident = id), _)
      then listReverse(id :: inAccumStrings);

    else {};

  end match;
end toStringList_tail;

public function crefDepth
  input ComponentRef inCref;
  output Integer depth;
algorithm
  depth :=
  match (inCref)
    local
      ComponentRef n;
    
    case (DAE.WILD()) then 0;
    case (DAE.CREF_IDENT(ident = _)) then 1;
    case (DAE.CREF_QUAL(componentRef = n))
      then
        crefDepth1(n,1);
  end match;  
end crefDepth;

protected function crefDepth1
  input DAE.ComponentRef inCref;
  input Integer iDepth;
  output Integer depth;
algorithm
  depth :=
  match (inCref,iDepth)
    local
      DAE.ComponentRef n;
    
    case (DAE.WILD(),_) then iDepth;
    case (DAE.CREF_IDENT(ident = _),_) then 1+iDepth;
    case (DAE.CREF_QUAL(componentRef = n),_)
      then
        crefDepth1(n,1+iDepth);
  end match;  
end crefDepth1;

public function expandCref
  "Expands an array cref into a list of elements, e.g.:

     expandCref(x) => {x[1], x[2], x[3]} 

   This function expects the subscripts of the cref to be constant evaluated,
   otherwise it will fail."
  input ComponentRef inCref;
  input Boolean expandRecord;
  output list<ComponentRef> outCref;
algorithm
  outCref := matchcontinue(inCref,expandRecord)
    case (_,_) then expandCref_impl(inCref,expandRecord);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- ComponentReference.expandCref failed on " +&
          printComponentRefStr(inCref));
      then
        fail();

  end matchcontinue;
end expandCref;

public function expandCref_impl
  input ComponentRef inCref;
  input Boolean expandRecord;
  output list<ComponentRef> outCref;
algorithm
  outCref := match(inCref,expandRecord)
    local
      DAE.Ident id;
      DAE.Type ty;
      list<DAE.Dimension> dims;
      list<DAE.Subscript> subs;
      ComponentRef cref;
      list<ComponentRef> crefs, crefs2;
      list<DAE.Var> varLst;

    // A simple cref without subscripts but record type.
    case (DAE.CREF_IDENT(id, DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_)), {}),true)
      equation
        // Create a list of crefs from names
        crefs =  List.map(varLst,creffromVar);
        crefs = List.map1r(crefs,joinCrefs,inCref);
      then
        List.map1Flat(crefs,expandCref_impl,true);        

    // A simple cref without subscripts but array type.
    case (DAE.CREF_IDENT(id, DAE.T_ARRAY(ty = ty as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_)), dims = dims), {}),true)
      equation
        // Create a list of : subscripts to generate all elements.
        subs = List.fill(DAE.WHOLEDIM(), listLength(dims));
        crefs = expandCref2(id, ty, subs, dims);
      then
        expandCrefLst(crefs,varLst,{});

    // A simple cref without subscripts but array type.
    case (DAE.CREF_IDENT(id, DAE.T_ARRAY(ty = ty, dims = dims), {}),_)
      equation
        // Create a list of : subscripts to generate all elements.
        subs = List.fill(DAE.WHOLEDIM(), listLength(dims));
      then
        expandCref2(id, ty, subs, dims);

    // A simple cref with subscripts and array type.
    case (DAE.CREF_IDENT(id, DAE.T_ARRAY(ty = ty as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_)), dims = dims), subs),true)
      equation
        // Use the subscripts to generate only the wanted elements.
        crefs = expandCref2(id, ty, subs, dims);
      then
        expandCrefLst(crefs,varLst,{});

    // A simple cref with subscripts and array type.
    case (DAE.CREF_IDENT(id, DAE.T_ARRAY(ty = ty, dims = dims), subs),_)
        // Use the subscripts to generate only the wanted elements.
      then
        expandCref2(id, ty, subs, dims);


    // A qualified cref with array type.
    case (DAE.CREF_QUAL(id, ty as DAE.T_ARRAY(ty = _), subs, cref),_)
      equation
        // Expand the rest of the cref.
        crefs = expandCref_impl(cref,expandRecord);
        // Create a simple identifier for the head of the cref and expand it.
        cref = DAE.CREF_IDENT(id, ty, subs);
        crefs2 = expandCref_impl(cref,expandRecord);
        crefs2 = listReverse(crefs2);
        // Create all combinations of the two lists.
        crefs = expandCrefQual(crefs2, crefs, {});
      then
        crefs;

    // A qualified cref with scalar type.
    case (DAE.CREF_QUAL(id, ty, subs, cref),_)
      equation
        // Expand the rest of the cref.
        crefs = expandCref_impl(cref,expandRecord);
        // Append the head of this cref to all of the generated crefs.
        crefs = List.map3r(crefs, makeCrefQual, id, ty, subs);
      then
        crefs;

    // All other cases, no expansion.
    else {inCref};

  end match;
end expandCref_impl;

protected function expandCrefLst
  input list<ComponentRef> inCrefs;
  input list<DAE.Var> varLst;
  input list<list<ComponentRef>> inCrefsAcc;
  output list<ComponentRef> outCref;
algorithm
  outCref := match(inCrefs,varLst,inCrefsAcc)
    local
      ComponentRef cr;
      list<ComponentRef> crefs,rest;
    case ({},_,_) then List.flatten(inCrefsAcc);
    case (cr::rest,_,_) 
      equation
        // Create a list of crefs from names
        crefs = List.map(varLst,creffromVar);
        crefs = List.map1r(crefs,joinCrefs,cr);
        crefs = List.map1Flat(crefs,expandCref_impl,true);        
      then
        expandCrefLst(rest,varLst,crefs::inCrefsAcc);
  end match;
end expandCrefLst;


protected function expandCrefQual
  "Helper function to expandCref_impl. Constructs all combinations of the head
   and rest cref lists. E.g.:
    expandCrefQual({x, y}, {a, b}) => {x.a, x.b, y.a, y.b} "
  input list<ComponentRef> inHeadCrefs;
  input list<ComponentRef> inRestCrefs;
  input list<ComponentRef> inAccumCrefs;
  output list<ComponentRef> outCrefs;
algorithm
  outCrefs := match(inHeadCrefs, inRestCrefs, inAccumCrefs)
    local
      list<ComponentRef> crefs, rest_crefs;
      ComponentRef cref;

    case (cref :: rest_crefs, _, _)
      equation
        crefs = List.map1r(inRestCrefs, joinCrefs, cref);
        crefs = listAppend(crefs, inAccumCrefs);
      then
        expandCrefQual(rest_crefs, inRestCrefs, crefs);

    else inAccumCrefs;

  end match;
end expandCrefQual;

protected function expandCref2
  input DAE.Ident inId;
  input DAE.Type inType;
  input list<DAE.Subscript> inSubscripts;
  input list<DAE.Dimension> inDimensions;
  output list<ComponentRef> outCrefs;
protected
  list<list<DAE.Subscript>> subs;
algorithm
  // Expand each subscript into a list of subscripts.
  subs := List.threadMap(inSubscripts, inDimensions, expandSubscript);
  subs := listReverse(subs);
  // Use expandCref3 to construct a cref for each combination of subscripts.
  outCrefs := expandCref3(inId, inType, subs, {}, {});
end expandCref2;

protected function expandCref3
  input DAE.Ident inId;
  input DAE.Type inType;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Subscript> inAccumSubs;
  input list<ComponentRef> inAccumCrefs;
  output list<ComponentRef> outCrefs;
algorithm
  outCrefs := match(inId, inType, inSubscripts, inAccumSubs, inAccumCrefs)
    local
      DAE.Subscript sub;
      list<DAE.Subscript> subs, acc_subs;
      list<list<DAE.Subscript>> rest_subs;
      list<ComponentRef> crefs;
      ComponentRef cref;

    case (_, _, (sub :: subs) :: rest_subs, acc_subs, crefs)
      equation
        crefs = expandCref3(inId, inType, subs :: rest_subs, acc_subs, crefs);
        crefs = expandCref3(inId, inType, rest_subs, sub :: acc_subs, crefs);
      then
        crefs;

    case (_, _, _ :: _, _, crefs)
      then inAccumCrefs;

    else
      equation
        cref = DAE.CREF_IDENT(inId, inType, inAccumSubs);
      then
        cref :: inAccumCrefs;

  end match;
end expandCref3;

protected function expandSubscript
  "Expands a subscript into a list of subscripts. Also takes a dimension to be
   able to evaluate : subscripts."
  input DAE.Subscript inSubscript;
  input DAE.Dimension inDimension;
  output list<DAE.Subscript> outSubscripts;
algorithm
  outSubscripts := match(inSubscript, inDimension)
    local
      DAE.Exp exp;

    // An index subscript from range.
    case (DAE.INDEX(exp = exp as DAE.RANGE(ty=_)), _)
      then getRangeContents(exp);

    // An index subscript, return it as an array.
    case (DAE.INDEX(exp = _), _) then {inSubscript};

    // A : subscript, use the dimension to generate all subscripts.
    case (DAE.WHOLEDIM(), _)
      then expandDimension(inDimension);

    // A slice subscript.
    case (DAE.SLICE(exp = exp), _)
      then expandSlice(exp);

  end match;
end expandSubscript;

protected function getRangeContents 
  input DAE.Exp e;
  output list<DAE.Subscript> outSubscripts;
algorithm
  outSubscripts := match e
    local
      Integer istart,istep,istop;
      list<Integer> ilst;
      list<DAE.Exp> explst;
    case DAE.RANGE(DAE.T_INTEGER(varLst = _),DAE.ICONST(istart),NONE(),DAE.ICONST(istop))
      equation
        ilst = List.intRange3(istart, 1, istop);
        explst = List.map(ilst, Expression.makeIntegerExp);
      then List.map(explst, Expression.makeIndexSubscript);
        
    case DAE.RANGE(DAE.T_INTEGER(varLst = _),DAE.ICONST(istart),SOME(DAE.ICONST(istep)),DAE.ICONST(istop))
      equation
        ilst = List.intRange3(istart, istep, istop);
        explst = List.map(ilst, Expression.makeIntegerExp);
      then List.map(explst, Expression.makeIndexSubscript);
  end match;
end getRangeContents;

protected function expandDimension
  "Generates a list of subscripts given an array dimension."
  input DAE.Dimension inDimension;
  output list<DAE.Subscript> outSubscript;
algorithm
  outSubscript := match(inDimension)
    local
      Integer dim_int;
      Absyn.Path enum_ty;
      list<String> enum_lits;
      list<DAE.Exp> enum_expl;

    // An integer dimension, generate a list of integer subscripts.
    case DAE.DIM_INTEGER(integer = dim_int)
      then List.generateReverse(dim_int, makeIntegerSubscript);

    // An enumeration dimension, construct all enumeration literals and make
    // subscript out of them.
    case DAE.DIM_ENUM(enumTypeName = enum_ty, literals = enum_lits)
      equation
        enum_expl = Expression.makeEnumLiterals(enum_ty, enum_lits);
      then
        List.map(enum_expl, Expression.makeIndexSubscript);

  end match;
end expandDimension;

protected function makeIntegerSubscript
  "Generates an integer subscript. For use with List.generate."
  input Integer inIndex;
  output Integer outNextIndex;
  output DAE.Subscript outSubscript;
  output Boolean outContinue;
algorithm
  (outNextIndex, outSubscript, outContinue) := match(inIndex)
    case 0 then (0, DAE.WHOLEDIM(), false);
    else (inIndex - 1, DAE.INDEX(DAE.ICONST(inIndex)), true);
  end match;
end makeIntegerSubscript;
      
protected function expandSlice
  "Expands a slice subscript expression."
  input DAE.Exp inSliceExp;
  output list<DAE.Subscript> outSubscripts;
algorithm
  outSubscripts := match(inSliceExp)
    local
      list<DAE.Exp> expl;
      String exp_str, err_str;

    case DAE.ARRAY(array = expl)
      then List.map(expl, Expression.makeIndexSubscript);

    else
      equation
        exp_str = ExpressionDump.printExpStr(inSliceExp);
        err_str = "ComponentReference.expandSlice: Unknown slice " +& exp_str;
        Error.addMessage(Error.INTERNAL_ERROR, {err_str});
      then
        fail();

  end match;
end expandSlice;

public function replaceSubsWithString
  input ComponentRef inCref;
  output ComponentRef outCref;
algorithm
  outCref := match(inCref)
    local
      DAE.Ident ident,ident1;
      DAE.Type identType;
      list<DAE.Subscript> subscriptLst;
      ComponentRef cr,cr1;
      String str;
    case DAE.CREF_QUAL(ident=ident,identType=identType,subscriptLst={},componentRef=cr)
      equation
        cr1 = replaceSubsWithString(cr);
      then  
        DAE.CREF_QUAL(ident,identType,{},cr1);
    case DAE.CREF_QUAL(ident=ident,identType=identType,subscriptLst=subscriptLst,componentRef=cr)
      equation
        identType = Expression.unliftArrayTypeWithSubs(subscriptLst,identType);
        cr1 = replaceSubsWithString(cr);
        str = ExpressionDump.printListStr(subscriptLst, ExpressionDump.printSubscriptStr, "_");
        ident1 = stringAppendList({ident, "_", str, "_"});
      then  
        DAE.CREF_QUAL(ident1,identType,{},cr1);
    case DAE.CREF_IDENT(subscriptLst={})
      then  
        inCref;
    case DAE.CREF_IDENT(ident=ident,identType=identType,subscriptLst=subscriptLst)
      equation
        identType = Expression.unliftArrayTypeWithSubs(subscriptLst,identType);
        str = ExpressionDump.printListStr(subscriptLst, ExpressionDump.printSubscriptStr, "_");
        ident1 = stringAppendList({ident, "_", str, "_"});
      then  
        DAE.CREF_IDENT(ident1,identType,{});
    case DAE.CREF_ITER(ident=_)
      then  
        inCref;
    case DAE.WILD()
      then  
        inCref;
  end match;
end replaceSubsWithString;

public function replaceLast
  "Replaces the last part of a cref with a new cref."
  input ComponentRef inCref;
  input ComponentRef inNewLast;
  output ComponentRef outCref;
algorithm
  outCref := match(inCref, inNewLast)
    local
      DAE.Ident ident;
      DAE.Type ty;
      list<DAE.Subscript> subs;
      ComponentRef cref;

    case (DAE.CREF_QUAL(ident, ty, subs, cref), _)
      equation
        cref = replaceLast(cref, inNewLast);
      then
        DAE.CREF_QUAL(ident, ty, subs, cref);

    case (DAE.CREF_IDENT(ident = _), _) then inNewLast;

  end match;
end replaceLast;

public function expandArrayCref
  input DAE.ComponentRef inCr;
  input DAE.Dimensions dims;
  output list<DAE.ComponentRef> outCrefs;
protected
  list<DAE.Subscript> subs;
  list<list<DAE.Subscript>> subslst;
algorithm
  subs := List.fill(DAE.WHOLEDIM(), listLength(dims));
  // Expand each subscript into a list of subscripts.
  subslst := List.threadMap(subs, dims, expandSubscript);
  subslst := listReverse(subslst);
  // Use expandCref3 to construct a cref for each combination of subscripts.
  outCrefs := expandArrayCref1(inCr, subslst, {}, {});
end expandArrayCref;

protected function expandArrayCref1
  input DAE.ComponentRef inCr;
  input list<list<DAE.Subscript>> inSubscripts;
  input list<DAE.Subscript> inAccumSubs;
  input list<DAE.ComponentRef> inAccumCrefs;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  outCrefs := match(inCr, inSubscripts, inAccumSubs, inAccumCrefs)
    local
      DAE.Subscript sub;
      list<DAE.Subscript> subs;
      list<list<DAE.Subscript>> rest_subs;
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef cref;

    case (_, (sub :: subs) :: rest_subs, _, _)
      equation
        crefs = expandArrayCref1(inCr, subs :: rest_subs, inAccumSubs, inAccumCrefs);
        crefs = expandArrayCref1(inCr, rest_subs, sub :: inAccumSubs, crefs);
      then
        crefs;

    case (_, _ :: _, _, _)
      then inAccumCrefs;

    else
      equation
        cref = crefSetLastSubs(inCr,inAccumSubs);
      then
        cref :: inAccumCrefs;

  end match;
end expandArrayCref1;

public function explode
  "Explodes a cref into a list of CREF_IDENTs."
  input DAE.ComponentRef inCref;
  output list<DAE.ComponentRef> outParts;
algorithm
  outParts := listReverse(explode_tail(inCref, {}));
end explode;

protected function explode_tail
  input DAE.ComponentRef inCref;
  input list<DAE.ComponentRef> inParts;
  output list<DAE.ComponentRef> outParts;
algorithm
  outParts := match(inCref, inParts)
    local
      DAE.ComponentRef first_cr, rest_cr;

    case (DAE.CREF_QUAL(componentRef = rest_cr), _)
      equation
        first_cr = crefFirstCref(inCref);
      then
        explode_tail(rest_cr, first_cr :: inParts);

    else inCref :: inParts;

  end match;
end explode_tail;

public function implode
  "Constructs a cref from a list of CREF_IDENTs."
  input list<DAE.ComponentRef> inParts;
  output DAE.ComponentRef outCref;
protected
  DAE.ComponentRef first;
  list<DAE.ComponentRef> rest;
algorithm
  first :: rest := listReverse(inParts);
  outCref := implode_tail(rest, first);
end implode;

protected function implode_tail
  input list<DAE.ComponentRef> inParts;
  input DAE.ComponentRef inAccumCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inParts, inAccumCref)
    local
      DAE.Ident id;
      DAE.Type ty;
      list<DAE.Subscript> subs;
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef cr;

    case (DAE.CREF_IDENT(id, ty, subs) :: rest, _)
      equation
        cr = DAE.CREF_QUAL(id, ty, subs, inAccumCref);
      then
        implode_tail(rest, cr);

    case ({}, _) then inAccumCref;

  end match;
end implode_tail;

end ComponentReference;

