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

public function crefPrependIdent "prepends (e..g as a suffix) an identifier to a component reference, given the identifier, subscript and the type
author: PA

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
  equal := Exp.crefEqual(pcr1,pcr2);
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
  equal := Exp.crefEqual(pcr1,pcr2);
end crefFirstCrefLastCrefEqual;

  
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
  
  
public function crefSortFunc "A sorting function (greatherThan) for crefs"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean greaterThan;
algorithm
  greaterThan := System.strcmp(Exp.printComponentRefStr(cr1),Exp.printComponentRefStr(cr2)) > 0;
end crefSortFunc;

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


end ComponentReference;

