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

package ComponentReference
"
  file:	       ComponentReference.mo
  package:     ComponentReference
  description: All stuff for ComponentRef datatypes

  RCS: $Id: Exp.mo 6540 2010-10-22 21:07:52Z sjoelund.se $

  This file contains the module `ComponentReference\', which contains functions
  for ComponentRef.
"

public import Absyn;
public import ClassInf;
public import DAE;
public import Graphviz;
public import System;

protected import Exp;
protected import RTOpts;
protected import Util;


/***************************************************/
/* Generate  */
/***************************************************/


public function makeCrefIdent
"@author: adrpo
  This function creates a DAE.CREF_IDENT(ident, identType, subscriptLst)"
  input DAE.Ident ident;
  input DAE.ExpType identType "type of the identifier, without considering the subscripts";
  input list<DAE.Subscript> subscriptLst;
  output DAE.ComponentRef outCrefIdent;
algorithm
  outCrefIdent := DAE.CREF_IDENT(ident, identType, subscriptLst);
end makeCrefIdent;

public function makeCrefQual
"@author: adrpo
  This function creates a DAE.CREF_QUAL(ident, identType, subscriptLst, componentRef)"
  input DAE.Ident ident;
  input DAE.ExpType identType "type of the identifier, without considering the subscripts";
  input list<DAE.Subscript> subscriptLst;
  input DAE.ComponentRef componentRef;
  output DAE.ComponentRef outCrefQual;
algorithm
  outCrefQual := DAE.CREF_QUAL(ident, identType, subscriptLst, componentRef);
end makeCrefQual;


/***************************************************/
/* Transform  */
/***************************************************/

public function crefToPath
"function: crefToPath
  This function converts a ComponentRef to a Path, if possible.
  If the component reference contains subscripts, it will silently
  fail."
  input DAE.ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath:=
  matchcontinue (inComponentRef)
    local
      DAE.Ident i;
      Absyn.Path p;
      DAE.ComponentRef c;
    case DAE.CREF_IDENT(ident = i,subscriptLst = {}) then Absyn.IDENT(i);
    case DAE.CREF_QUAL(ident = i,subscriptLst = {},componentRef = c)
      equation
        p = crefToPath(c);
      then
        Absyn.QUALIFIED(i,p);
  end matchcontinue;
end crefToPath;

public function pathToCref
"function: pathToCref
  This function converts a Absyn.Path to a ComponentRef."
  input Absyn.Path inPath;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inPath)
    local
      DAE.Ident i;
      DAE.ComponentRef c;
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

public function crefToStr
"function: crefStr
  This function converts a ComponentRef to a String.
  It is a tail recursive implementation, because of that it
  neads inPreString. Use inNameSeperator to define the 
  Separator inbetween and between the namespace names and the name"
  input String inPreString;
  input DAE.ComponentRef inComponentRef "The ComponentReference";
  input String inNameSeparator "The Separator between the Names";
  output String outString;
algorithm
  outString:=
  matchcontinue (inPreString,inComponentRef,inNameSeparator)
    local
      DAE.Ident s,ns,s1,ss;
      DAE.ComponentRef n;
    case (inPreString,DAE.CREF_IDENT(ident = s),_)
      equation
        ss = stringAppend(inPreString, s);
      then ss;
    case (inPreString,DAE.CREF_QUAL(ident = s,componentRef = n),inNameSeparator)
      equation
        ns = System.stringAppendList({inPreString, s, inNameSeparator});
        ss = crefToStr(ns,n,inNameSeparator);
      then
        ss;
  end matchcontinue;
end crefToStr;

public function crefStr
"function: crefStr
  This function simply converts a ComponentRef to a String."
  input DAE.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString:= crefToStr("",inComponentRef,".");
end crefStr;

public function crefModelicaStr
"function: crefModelicaStr
  Same as crefStr, but uses _ instead of . "
  input DAE.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString:= crefToStr("",inComponentRef,"_");
end crefModelicaStr;


/***************************************************/
/* Get Items  */
/***************************************************/


public function crefLastPath
  "Returns the last identifier of a cref as an Absyn.IDENT."
  input DAE.ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inComponentRef)
    local
      DAE.Ident i;
      DAE.ComponentRef c;
    case DAE.CREF_IDENT(ident = i, subscriptLst = {}) then Absyn.IDENT(i);
    case DAE.CREF_QUAL(componentRef = c, subscriptLst = {}) then crefLastPath(c);
  end matchcontinue;
end crefLastPath;

public function crefLastIdent
"function: crefLastIdent
  author: PA
  Returns the last identfifier of a ComponentRef."
  input DAE.ComponentRef inComponentRef;
  output DAE.Ident outIdent;
algorithm
  outIdent:=
  matchcontinue (inComponentRef)
    local
      DAE.Ident id,res;
      DAE.ComponentRef cr;
    case (DAE.CREF_IDENT(ident = id)) then id;
    case (DAE.CREF_QUAL(componentRef = cr))
      equation
        res = crefLastIdent(cr);
      then
        res;
  end matchcontinue;
end crefLastIdent;

public function crefLastCref "
  Return the last ComponentRef"
  input DAE.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm 
  outComponentRef:= 
  matchcontinue (inComponentRef)
    local
      DAE.Ident id;
      DAE.ComponentRef res,cr;
    case (inComponentRef as DAE.CREF_IDENT(ident = id)) then inComponentRef;
    case (DAE.CREF_QUAL(componentRef = cr))
      equation
        res = crefLastCref(cr);
      then
        res;
  end matchcontinue;
end crefLastCref;

public function crefSubs "
function: crefSubs
  Return the all subscripts of a ComponentRef"
  input DAE.ComponentRef inComponentRef;
  output list<DAE.Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  matchcontinue (inComponentRef)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs,res;
      DAE.ComponentRef cr;
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
  input DAE.ComponentRef inComponentRef;
  output list<DAE.Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  matchcontinue (inComponentRef)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs,res;
      DAE.ComponentRef cr;
    case (DAE.CREF_IDENT(ident = id,subscriptLst = subs)) then subs;
    case (DAE.CREF_QUAL(componentRef = cr))
      equation
        res = crefLastSubs(cr);
      then
        res;
  end matchcontinue;
end crefLastSubs;

public function crefFirstCref
"Returns the first part of a component reference, i.e the identifier"
  input DAE.ComponentRef inCr;
  output DAE.ComponentRef outCr;
algorithm
  outCr := matchcontinue(inCr)
    local 
      DAE.Ident id;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;
      DAE.ExpType t2;
    
    case( DAE.CREF_QUAL(id,t2,subs,cr)) then DAE.CREF_IDENT(id,t2,{});
    case( DAE.CREF_IDENT(id,t2,subs)) then DAE.CREF_IDENT(id,t2,{});
  end matchcontinue;
end crefFirstCref;

/***************************************************/
/* Compare  */
/***************************************************/

public function crefLastIdentEqual
"function: crefLastIdentEqual
  author: Frenkel TUD
  Returns true if the ComponentRefs has the same name (the last identifier)."
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean equal;
protected
  DAE.Ident id1,id2;
algorithm
  id1 := crefLastIdent(cr1);
  id2 := crefLastIdent(cr2);
  equal := stringEqual(id1, id2);
end crefLastIdentEqual;

public function crefFirstCrefEqual
"function: crefFirstCrefEqual
  author: Frenkel TUD
  Returns true if the ComponentRefs have the same first Cref."
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean equal;
protected
  DAE.ComponentRef pcr1,pcr2;
algorithm
  pcr1 := crefFirstCref(cr1);
  pcr2 := crefFirstCref(cr2);
  equal := crefEqual(pcr1,pcr2);
end crefFirstCrefEqual;

public function crefFirstCrefLastCrefEqual
"function: crefFirstCrefEqual
  author: Frenkel TUD
  Returns true if the ComponentRefs have the same first Cref."
  input DAE.ComponentRef cr1 "First Cref";
  input DAE.ComponentRef cr2 "Last Cref";
  output Boolean equal;
protected
  DAE.ComponentRef pcr1,pcr2;
algorithm
  pcr1 := crefFirstCref(cr1);
  pcr2 := crefLastCref(cr2);
  equal := crefEqual(pcr1,pcr2);
end crefFirstCrefLastCrefEqual;

public function crefSortFunc "A sorting function (greatherThan) for crefs"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean greaterThan;
algorithm
  greaterThan := System.strcmp(Exp.printComponentRefStr(cr1),Exp.printComponentRefStr(cr2)) > 0;
end crefSortFunc;

public function crefContainedIn
"function: crefContainedIn
  author: PA
  Returns true if second arg is a sub component ref of first arg.
  For instance, b.c. is a sub_component of a.b.c."
  input DAE.ComponentRef containerCref "the cref that might contain";
  input DAE.ComponentRef containedCref "cref that might be contained";  
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (containerCref, containedCref)
    local
      DAE.ComponentRef full,partOf,cr2;
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
  input DAE.ComponentRef prefixCref;
  input DAE.ComponentRef fullCref;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (prefixCref,fullCref)
    local
      DAE.ComponentRef cr1,cr2;
      Boolean res;
      DAE.Ident id1,id2;
      list<DAE.Subscript> ss1,ss2;
      DAE.ExpType t2,t22;
    
    // first is qualified, second is an unqualified ident, return false!
    case (DAE.CREF_QUAL(ident = _), DAE.CREF_IDENT(ident = _)) then false;
    
    // both are qualified, dive into
    case (DAE.CREF_QUAL(ident = id1, subscriptLst = ss1,componentRef = cr1),
          DAE.CREF_QUAL(ident = id2, subscriptLst = ss2,componentRef = cr2))
      equation
        true = stringEqual(id1, id2);
        true = Exp.subscriptEqual(ss1, ss2);
        res = crefPrefixOf(cr1, cr2);
      then
        res;
    
    // adrpo: 2010-10-07: first is an ID, second is qualified, see if one is prefix of the other
    //                    even if the first one DOESN'T HAVE SUBSCRIPTS!
    case (DAE.CREF_IDENT(ident = id1,subscriptLst = {}),
          DAE.CREF_QUAL(ident = id2,subscriptLst = ss2))
      equation
        true = stringEqual(id1, id2);
      then
        true;
    
    // first is an ID, second is qualified, see if one is prefix of the other
    case (DAE.CREF_IDENT(ident = id1,subscriptLst = ss1),
          DAE.CREF_QUAL(ident = id2,subscriptLst = ss2))
      equation
        true = stringEqual(id1, id2);
        res = Exp.subscriptEqual(ss1, ss2);
      then
        res;
        
    // adrpo: 2010-10-07: first is an ID, second is an ID, see if one is prefix of the other
    //                    even if the first one DOESN'T HAVE SUBSCRIPTS!
    case (DAE.CREF_IDENT(ident = id1,subscriptLst = {}),
          DAE.CREF_IDENT(ident = id2,subscriptLst = ss2))
      equation
        true = stringEqual(id1, id2);
      then
        true;
    
    case (DAE.CREF_IDENT(ident = id1,subscriptLst = ss1),
          DAE.CREF_IDENT(ident = id2,subscriptLst = ss2))
      equation
        true = stringEqual(id1, id2);
        res = Exp.subscriptEqual(ss1, ss2);
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
        // print("Exp.crefPrefixOf: " +& printComponentRefStr(cr1) +& " NOT PREFIX OF " +& printComponentRefStr(cr2) +& "\n");
      then false;
  end matchcontinue;
end crefPrefixOf;

public function crefEqual
"function: crefEqual
  Returns true if two component references are equal.
  No string comparison of unparsed crefs is performed!"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  output Boolean outBoolean;
algorithm
  outBoolean := crefEqualStringCompare(inComponentRef1,inComponentRef2);
end crefEqual;

public function crefEqualStringCompare
"function: crefEqualStringCompare
  Returns true if two component references are equal, 
  comparing strings in no other solution is found"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef1,inComponentRef2)
    local
      DAE.Ident n1,n2,s1,s2;
      list<DAE.Subscript> idx1,idx2;
      DAE.ComponentRef cr1,cr2;
      
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
        true = Exp.subscriptEqual(idx1, idx2);
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
        s1 = n2 +& "[" +& Exp.printListStr(idx2, Exp.printSubscriptStr, ",") +& "]";
        true = stringEqual(s1,n1);
      then
        true;
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = (idx2 as _::_)),DAE.CREF_IDENT(ident = n2,subscriptLst = {}))
      equation
        0 = System.stringFind(n2, n1); // n1 should be first in n2!
        s1 = n1 +& "[" +& Exp.printListStr(idx2, Exp.printSubscriptStr, ",") +& "]";
        true = stringEqual(s1,n2);
      then
        true;
    // qualified crefs
    case (DAE.CREF_QUAL(ident = n1,subscriptLst = idx1,componentRef = cr1),DAE.CREF_QUAL(ident = n2,subscriptLst = idx2,componentRef = cr2))
      equation
        true = stringEqual(n1, n2);
        true = crefEqualStringCompare(cr1, cr2);
        true = Exp.subscriptEqual(idx1, idx2);
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
        s1 = Exp.printComponentRefStr(cr1);
        s2 = Exp.printComponentRefStr(cr2);
        true = stringEqual(s1, s2);
      then
        true;
	  // left cref is stringified!
    case (cr1 as DAE.CREF_IDENT(ident = n1),cr2 as DAE.CREF_QUAL(ident = n2))
      equation
        0 = System.stringFind(n1, n2); // n2 should be first in n1!
        s1 = Exp.printComponentRefStr(cr1);
        s2 = Exp.printComponentRefStr(cr2);
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
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef1,inComponentRef2)
    local
      DAE.Ident n1,n2,s1,s2;
      list<DAE.Subscript> idx1,idx2;
      DAE.ComponentRef cr1,cr2;

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
        true = Exp.subscriptEqual(idx1, idx2);
      then
        true;
    // qualified crefs
    case (DAE.CREF_QUAL(ident = n1,subscriptLst = idx1,componentRef = cr1),DAE.CREF_QUAL(ident = n2,subscriptLst = idx2,componentRef = cr2))
      equation
        true = stringEqual(n1, n2);
        true = crefEqualNoStringCompare(cr1, cr2);
        true = Exp.subscriptEqual(idx1, idx2);
      then
        true;
    // the crefs are not equal!
    case (_,_) then false;
  end matchcontinue;
end crefEqualNoStringCompare;

public function crefEqualReturn
"function: crefEqualReturn
  author: PA
  Checks if two crefs are equal and if
  so returns the cref, otherwise fail."
  input DAE.ComponentRef cr;
  input DAE.ComponentRef cr2;
  output DAE.ComponentRef cr;
algorithm
  true := crefEqualNoStringCompare(cr, cr2);
end crefEqualReturn;



public function crefIsIdent
"returns true if ComponentRef is an ident,
 i.e a => true , a.b => false"
  input DAE.ComponentRef cr;
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
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(cr)
  local 
    DAE.ComponentRef comp;
    Boolean b;
    case(DAE.CREF_IDENT(identType = DAE.ET_COMPLEX(complexClassType=ClassInf.RECORD(_)))) then true;
    /* this case is false because it is not the last ident.   
    case(DAE.CREF_QUAL(identType = DAE.ET_COMPLEX(complexClassType=ClassInf.RECORD(_)))) then true;*/
    case(DAE.CREF_QUAL(componentRef=comp))
      equation
         b = isRecord(comp);  
      then b;
    case(_) then false;
  end matchcontinue;
end isRecord;

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
  input DAE.ComponentRef cr;
  input String ident;  
  input list<DAE.Subscript> subs;
  input DAE.ExpType tp;
  output DAE.ComponentRef newCr;
algorithm
  newCr := matchcontinue(cr,ident,subs,tp)
  local DAE.ExpType tp1; String id1; list<DAE.Subscript> subs1;
    case(DAE.CREF_IDENT(id1,tp1,subs1),ident,subs,tp) then DAE.CREF_QUAL(id1,tp1,subs1,DAE.CREF_IDENT(ident,tp,subs));
    case(DAE.CREF_QUAL(id1,tp1,subs1,cr),ident,subs,tp)
      equation
        cr = crefPrependIdent(cr,ident,subs,tp);
      then DAE.CREF_QUAL(id1,tp1,subs1,cr);
  end matchcontinue;
end crefPrependIdent;

public function crefAddPrefix "prepends an identifier to a component reference, given the identifier, subscript and the type
author: Frenkel TUD
"
  input String ident;  
  input list<DAE.Subscript> subs;
  input DAE.ExpType tp;
  input DAE.ComponentRef cr;
  output DAE.ComponentRef newCr;
algorithm
  newCr := DAE.CREF_QUAL(ident,tp,subs,cr);
end crefAddPrefix;

public function prependStringCref
"function: prependStringCref
  Prepend a string to a component reference.
  For qualified named, this means prepending a
  string to the first identifier."
  input String inString;
  input DAE.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inString,inComponentRef)
    local
      DAE.Ident i_1,p,i;
      list<DAE.Subscript> s;
      DAE.ComponentRef c;
      DAE.ExpType t2;
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

public function joinCrefs
"function: joinCrefs
  Join two component references by concatenating them."
  input DAE.ComponentRef inComponentRef1 " first part of the new componentref";
  input DAE.ComponentRef inComponentRef2 " last part of the new componentref";
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef1,inComponentRef2)
    local
      DAE.Ident id;
      list<DAE.Subscript> sub;
      DAE.ComponentRef cr2,cr_1,cr;
      DAE.ExpType t2;
    case (DAE.CREF_IDENT(ident = id, identType = t2, subscriptLst = sub),cr2) then DAE.CREF_QUAL(id,t2,sub,cr2);
    case (DAE.CREF_QUAL(ident = id, identType = t2, subscriptLst = sub,componentRef = cr),cr2)
      equation
        cr_1 = joinCrefs(cr, cr2);
      then
        DAE.CREF_QUAL(id,t2,sub,cr_1);
  end matchcontinue;
end joinCrefs;

public function stripCrefIdentSliceSubs "
Author BZ
Strips the SLICE-subscripts fromt the -last- subscript list. All other subscripts are not changed.
For example
x[1].y[{1,2},3,{1,3,7}] => x[1].y[3]
Alternative names: stripLastSliceSubs"
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref)
    local
      DAE.Ident id;
      DAE.ComponentRef cr;
      DAE.ExpType ty;
      list<DAE.Subscript> subs;
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
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref)
    local
      DAE.Ident id;
      DAE.ComponentRef cr;
      DAE.ExpType ty;
    case (DAE.CREF_IDENT(ident = id,identType = ty))
    then DAE.CREF_IDENT(id,ty,{});
    case (DAE.CREF_QUAL(componentRef = cr, identType=ty, ident=id))
      equation
        outCref = crefStripSubs(cr);
      then
        DAE.CREF_QUAL(id,ty,{},outCref);
  end matchcontinue;
end crefStripSubs;

public function crefStripPrefix
"Strips a prefix/cref from a component reference"
  input DAE.ComponentRef cref;
  input DAE.ComponentRef prefix;
  output DAE.ComponentRef outCref;
algorithm
	outCref := matchcontinue(cref,prefix)
	  local
	    list<DAE.Subscript> subs1,subs2;
	    DAE.ComponentRef cr1,cr2;
	    DAE.Ident id1,id2;
	    DAE.ExpType t2;
	  
	  case(DAE.CREF_QUAL(id1,_,subs1,cr1),DAE.CREF_IDENT(id2,_,subs2))
	    equation
	      true = stringEqual(id1, id2);
	      true = Exp.subscriptEqual(subs1,subs2);
	    then cr1;
	  
	  case(DAE.CREF_QUAL(id1,_,subs1,cr1),DAE.CREF_QUAL(id2,_,subs2,cr2))
	    equation
	      true = stringEqual(id1, id2);
	      true = Exp.subscriptEqual(subs1,subs2);
	    then crefStripPrefix(cr1,cr2);
  end matchcontinue;
end crefStripPrefix;

public function crefStripLastIdent
"Strips the last part of a component reference, i.e ident and subs"
  input DAE.ComponentRef inCr;
  output DAE.ComponentRef outCr;
algorithm
  outCr := matchcontinue(inCr)
    local 
      DAE.Ident id;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr1,cr;
      DAE.ExpType t2;
    
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

public function crefStripLastSubs
"function: crefStripLastSubs
  Strips the last subscripts of a ComponentRef"
  input DAE.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs,s;
      DAE.ComponentRef cr_1,cr;
      DAE.ExpType t2;
    
    case (DAE.CREF_IDENT(ident = id,identType = t2,subscriptLst = subs)) then DAE.CREF_IDENT(id,t2,{});
    case (DAE.CREF_QUAL(ident = id,identType = t2,subscriptLst = s,componentRef = cr))
      equation
        cr_1 = crefStripLastSubs(cr);
      then
        DAE.CREF_QUAL(id,t2,s,cr_1);
  end matchcontinue;
end crefStripLastSubs;

public function crefStripFirstIdent
"Strips the first part of a component reference,
i.e the identifier and eventual subscripts"
  input DAE.ComponentRef inCr;
  output DAE.ComponentRef outCr;
algorithm
  outCr := matchcontinue(inCr)
    local DAE.ComponentRef cr;  
    case( DAE.CREF_QUAL(componentRef = cr)) then cr;
  end matchcontinue;
end crefStripFirstIdent;

public function crefSetLastSubs "
function: crefSetLastSubs
  sets the subs of the last componenentref ident"
  input DAE.ComponentRef inComponentRef;
  input list<DAE.Subscript> insubs;
  output DAE.ComponentRef outComponentRef;
algorithm 
  outComponentRef := matchcontinue (inComponentRef,insubs)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs,s;
      DAE.ComponentRef cr_1,cr;
      DAE.ExpType t2;
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
  input DAE.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef)
    local
      list<DAE.Ident> lst,lst_1;
      DAE.Ident id_1,id;
      DAE.ComponentRef cr;
      DAE.ExpType t2;
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

end ComponentReference;

