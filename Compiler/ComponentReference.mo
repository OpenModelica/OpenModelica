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


end ComponentReference;

