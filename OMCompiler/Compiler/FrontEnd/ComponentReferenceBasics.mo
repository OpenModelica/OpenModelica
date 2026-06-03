/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package ComponentReferenceBasics
" file:        ComponentReferenceBasics.mo
  package:     ComponentReferenceBasics
  description: Some stuff for ComponentRef datatypes


  This file contains the module ComponentReferenceBasics,
  which contains functions for ComponentRef."

// public imports
public import DAE;

// protected imports
protected import Config;
protected import ExpressionBasics;
protected import List;
protected import System;
protected import TypesDump;

public function crefDims "
function: crefDims
  Return the all dimension (contained in the types) of a ComponentRef"
  input DAE.ComponentRef inComponentRef;
  output list<DAE.Dimension> outDimensionLst;
algorithm
  outDimensionLst := match inComponentRef
    local
      list<DAE.Dimension> dims,res;
      DAE.Type idType;
      DAE.ComponentRef cr;

    case DAE.CREF_IDENT(identType = idType) then TypesDump.getDimensions(idType);

    case DAE.CREF_QUAL(componentRef = cr, identType = idType)
      algorithm
        dims := TypesDump.getDimensions(idType);
        res := crefDims(cr);
        res := listAppend(dims,res);
      then
        res;
  end match;
end crefDims;

public function crefSubs "
function: crefSubs
  Return all subscripts of a ComponentRef"
  input DAE.ComponentRef inComponentRef;
  output list<DAE.Subscript> outSubscriptLst;
algorithm
  outSubscriptLst := match inComponentRef
    local
      list<DAE.Subscript> subs,res;
      DAE.ComponentRef cr;

    case DAE.CREF_IDENT(subscriptLst = subs) then subs;

    case DAE.CREF_QUAL(componentRef = cr,subscriptLst=subs)
      algorithm
        res := crefSubs(cr);
        res := listAppend(subs,res);
      then
        res;
  end match;
end crefSubs;

/***************************************************/
/* Compare  */
/***************************************************/

public function crefLastIdentEqual
"author: Frenkel TUD
  Returns true if the ComponentRefs has the same name (the last identifier)."
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean equal;
protected
  DAE.Ident id1,id2;
algorithm
  id1 := crefLastIdent(cr1);
  id2 := crefLastIdent(cr2);
  equal := stringEq(id1, id2);
end crefLastIdentEqual;

public function crefFirstCrefEqual
"author: Frenkel TUD
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
"author: Frenkel TUD
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

public function crefFirstCref
"Returns the first part of a component reference, i.e the identifier"
  input DAE.ComponentRef inCr;
  output DAE.ComponentRef outCr;
algorithm
  outCr := match inCr
    local
      DAE.Ident id;
      list<DAE.Subscript> subs;
      DAE.Type t2;

    case DAE.CREF_QUAL(id,t2,subs,_) then makeCrefIdent(id,t2,subs);
    case DAE.CREF_IDENT(_,_,_) then inCr;
  end match;
end crefFirstCref;

public function crefLastIdent
"author: PA
  Returns the last identfifier of a ComponentRef."
  input DAE.ComponentRef inComponentRef;
  output DAE.Ident outIdent;
algorithm
  outIdent := match inComponentRef
    local
      DAE.Ident id,res;
      DAE.ComponentRef cr;

    case DAE.CREF_IDENT(ident = id) then id;

    case DAE.CREF_QUAL(componentRef = cr)
      algorithm
        res := crefLastIdent(cr);
      then
        res;
  end match;
end crefLastIdent;

public function crefLastCref "
  Return the last ComponentRef"
  input DAE.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match inComponentRef
    local
      DAE.ComponentRef res,cr;

    case DAE.CREF_IDENT() then inComponentRef;

    case DAE.CREF_QUAL(componentRef = cr)
      algorithm
        res := crefLastCref(cr);
      then
        res;
  end match;
end crefLastCref;

public function crefFirstIdentEqual
  "Returns true if the first identifier in both crefs are the same, otherwise false."
  input DAE.ComponentRef inCref1;
  input DAE.ComponentRef inCref2;
  output Boolean outEqual;
protected
  DAE.Ident id1, id2;
algorithm
  id1 := crefFirstIdent(inCref1);
  id2 := crefFirstIdent(inCref2);
  outEqual := stringEq(id1, id2);
end crefFirstIdentEqual;

public function crefFirstIdent
  "Returns the first identifier of a component reference."
  input DAE.ComponentRef inComponentRef;
  output DAE.Ident outIdent;
algorithm
  outIdent := match inComponentRef
    local
      DAE.Ident id;

    case DAE.CREF_IDENT(ident = id) then id;
    case DAE.CREF_QUAL(ident = id) then id;
  end match;
end crefFirstIdent;

protected

type CompareWithSubsType = enumeration(WithoutSubscripts, WithGenericSubscript, WithGenericSubscriptNotAlphabetic, WithIntSubscript);

package CompareWithGenericSubscript "Package that can be modified to do different kinds of comparisons"
  constant CompareWithSubsType compareSubscript=CompareWithSubsType.WithGenericSubscript;
  function compare
    input DAE.ComponentRef cr1, cr2;
    output Integer res;
  algorithm
    res := match (cr1, cr2)
      case (DAE.CREF_IDENT(),DAE.CREF_IDENT())
        algorithm
          res := stringCompare(cr1.ident, cr2.ident);
          if compareSubscript==CompareWithSubsType.WithoutSubscripts or res <> 0 then
            return;
          end if;
        then compareSubs(cr1.subscriptLst, cr2.subscriptLst);
      case (DAE.CREF_QUAL(),DAE.CREF_QUAL())
        algorithm
          res := stringCompare(cr1.ident, cr2.ident);
          if res <> 0 then
            return;
          end if;
          if compareSubscript<>CompareWithSubsType.WithoutSubscripts then
            res := compareSubs(cr1.subscriptLst, cr2.subscriptLst);
            if res <> 0 then
              return;
            end if;
          end if;
        then compare(cr1.componentRef, cr2.componentRef);
      case (DAE.CREF_QUAL(),DAE.CREF_IDENT())
        algorithm
          res := stringCompare(cr1.ident, cr2.ident);
          if res <> 0 then
            return;
          end if;
          if compareSubscript<>CompareWithSubsType.WithoutSubscripts then
            res := compareSubs(cr1.subscriptLst, cr2.subscriptLst);
          end if;
          if res <> 0 then
            return;
          end if;
        then 1;
      case (DAE.CREF_IDENT(),DAE.CREF_QUAL())
        algorithm
          res := stringCompare(cr1.ident, cr2.ident);
          if res <> 0 then
            return;
          end if;
          if compareSubscript<>CompareWithSubsType.WithoutSubscripts then
            res := compareSubs(cr1.subscriptLst, cr2.subscriptLst);
          end if;
          if res <> 0 then
            return;
          end if;
        then -1;
    end match;
  end compare;
  function compareSubs
    input list<DAE.Subscript> ss1, ss2;
    output Integer res=0;
  protected
    list<DAE.Subscript> ss=ss2;
    DAE.Subscript s2;
    Integer i1, i2;
  algorithm
    for s1 in ss1 loop
      if listEmpty(ss) then
        res := -1;
        return;
      end if;
      s2::ss := ss;
      if compareSubscript == CompareWithSubsType.WithGenericSubscript then
        res := stringCompare(ExpressionBasics.printSubscriptStr(s1), ExpressionBasics.printSubscriptStr(s2));
      elseif compareSubscript == CompareWithSubsType.WithGenericSubscriptNotAlphabetic then
        res := ExpressionBasics.compareSubscripts(s1, s2);
      else
        i1 := ExpressionBasics.subscriptInt(s1);
        i2 := ExpressionBasics.subscriptInt(s2);
        res := if i1 < i2 then -1 elseif i1 > i2 then 1 else 0;
      end if;
      if res <> 0 then
        return;
      end if;
    end for;
    if not listEmpty(ss) then
      res := 1;
    end if;
  end compareSubs;
end CompareWithGenericSubscript;

package CompareWithGenericSubscriptNotAlphabetic
  extends CompareWithGenericSubscript(compareSubscript=CompareWithSubsType.WithGenericSubscriptNotAlphabetic);
end CompareWithGenericSubscriptNotAlphabetic;
package CompareWithoutSubscripts
  extends CompareWithGenericSubscript(compareSubscript=CompareWithSubsType.WithoutSubscripts);
end CompareWithoutSubscripts;
package CompareWithIntSubscript "More efficient than CompareWithGenericSubscript, assuming all subscripts are integers"
  extends CompareWithGenericSubscript(compareSubscript=CompareWithSubsType.WithIntSubscript);
end CompareWithIntSubscript;

public function crefSortFunc "A sorting function (greatherThan) for crefs"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean greaterThan;
algorithm
  greaterThan := CompareWithGenericSubscript.compare(cr1,cr2) > 0;
end crefSortFunc;

public function crefCompareGeneric "A sorting function for crefs"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Integer comp;
algorithm
  comp := CompareWithGenericSubscript.compare(cr1,cr2);
end crefCompareGeneric;

public function crefCompareIntSubscript "A sorting function for crefs"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Integer comp;
algorithm
  comp := CompareWithIntSubscript.compare(cr1,cr2);
end crefCompareIntSubscript;

public function crefCompareGenericNotAlphabetic "A sorting function for crefs"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Integer comp;
algorithm
  comp := CompareWithGenericSubscriptNotAlphabetic.compare(cr1,cr2);
end crefCompareGenericNotAlphabetic;

public function crefLexicalGreaterSubsAtEnd
"mahge:
  Compares two crefs lexically. Subscripts are treated as if they are
  they are at the end of the whole component reference.
  e.g. r[1].i is greater than r[2].a.
  returns true if the first cref is greater than the second"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean isGreater;
algorithm
  isGreater := crefLexicalCompareSubsAtEnd(cr1,cr2) > 0;
end crefLexicalGreaterSubsAtEnd;

public function crefLexicalCompareSubsAtEnd
"mahge:
  Compares two crefs lexically. Subscripts are treated as if they are
  they are at the end of the whole component reference.
  e.g. r[1].i is greater than r[2].a.
  returns value is same as C strcmp. 0 if equal, 1 if first is greater, -1 otherwise"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Integer res;
protected
  list<Integer> subs1;
  list<Integer> subs2;
algorithm
  res := CompareWithoutSubscripts.compare(cr1, cr2);
  if res <> 0 then
    return;
  end if;
  subs1 := ExpressionBasics.subscriptsInt(crefSubs(cr1));
  subs2 := ExpressionBasics.subscriptsInt(crefSubs(cr2));
  res := crefLexicalCompareSubsAtEnd2(subs1, subs2);
end crefLexicalCompareSubsAtEnd;

protected function crefLexicalCompareSubsAtEnd2
"mahge:
  Helper function for crefLexicalCompareubsAtEnd
  compares subs. However only if the crefs with out subs are equal.
  (i.e. identsCompared is 0)
  otherwise just returns"
  input list<Integer> inSubs1;
  input list<Integer> inSubs2;
  output Integer res = 0;
protected
  list<Integer> rest=inSubs2;
algorithm
  for i in inSubs1 loop
    res::rest := rest;
    res := if i>res then 1 elseif i < res then -1 else 0;
    if res <> 0 then
      return;
    end if;
  end for;
end crefLexicalCompareSubsAtEnd2;

public function crefContainedIn
"author: PA
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
    case (DAE.CREF_IDENT(), DAE.CREF_QUAL()) then false;

    // see if they are equal
    case (full, partOf)
      algorithm
        true := crefEqualNoStringCompare(full, partOf);
      then
        true;

    // dive into
    case (full as DAE.CREF_QUAL(componentRef = cr2), partOf)
      algorithm
        false := crefEqualNoStringCompare(full, partOf);
        res := crefContainedIn(cr2,partOf);
      then
        res;

    // anything else is false
    else false;
  end matchcontinue;
end crefContainedIn;

public function crefPrefixOf
"author: PA
  Returns true if prefixCref is a prefix of fullCref
  For example, a.b is a prefix of a.b.c.
  adrpo 2010-10-07,
    added also that a.b.c is a prefix of a.b.c[1].*!"
  input DAE.ComponentRef prefixCref;
  input DAE.ComponentRef fullCref;
  output Boolean outPrefixOf;
algorithm
  outPrefixOf := match (prefixCref,fullCref)
    // both are qualified, dive into
    case (DAE.CREF_QUAL(), DAE.CREF_QUAL())
      then prefixCref.ident == fullCref.ident and
           ExpressionBasics.subscriptEqual(prefixCref.subscriptLst, fullCref.subscriptLst) and
           crefPrefixOf(prefixCref.componentRef, fullCref.componentRef);

    // adrpo: 2010-10-07: first is an ID, second is qualified, see if one is prefix of the other
    //                    even if the first one DOESN'T HAVE SUBSCRIPTS!
    case (DAE.CREF_IDENT(subscriptLst = {}), DAE.CREF_QUAL())
      then prefixCref.ident == fullCref.ident;

    // first is an ID, second is qualified, see if one is prefix of the other
    case (DAE.CREF_IDENT(), DAE.CREF_QUAL())
      then prefixCref.ident == fullCref.ident and
           ExpressionBasics.subscriptEqual(prefixCref.subscriptLst, fullCref.subscriptLst);

    // adrpo: 2010-10-07: first is an ID, second is an ID, see if one is prefix of the other
    //                    even if the first one DOESN'T HAVE SUBSCRIPTS!
    case (DAE.CREF_IDENT(subscriptLst = {}), DAE.CREF_IDENT())
      then stringEq(prefixCref.ident, fullCref.ident);

    case (DAE.CREF_IDENT(), DAE.CREF_IDENT())
      then prefixCref.ident == fullCref.ident and
           ExpressionBasics.subscriptEqual(prefixCref.subscriptLst, fullCref.subscriptLst);

    // they are not a prefix of one-another
    else false;
  end match;
end crefPrefixOf;

public function crefPrefixOfIgnoreSubscripts
"author: PA
  Returns true if prefixCref is a prefix of fullCref
  For example, a.b is a prefix of a.b.c.
  This function ignores the subscripts"
  input DAE.ComponentRef prefixCref;
  input DAE.ComponentRef fullCref;
  output Boolean outPrefixOf;
algorithm
  outPrefixOf := match (prefixCref,fullCref)
    // both are qualified, dive into
    case (DAE.CREF_QUAL(), DAE.CREF_QUAL())
      then prefixCref.ident == fullCref.ident and
           crefPrefixOfIgnoreSubscripts(prefixCref.componentRef, fullCref.componentRef);

    // first is an ID, second is qualified, see if one is prefix of the other
    case (DAE.CREF_IDENT(), DAE.CREF_QUAL())
      then prefixCref.ident == fullCref.ident;

    case (DAE.CREF_IDENT(), DAE.CREF_IDENT())
      then prefixCref.ident == fullCref.ident;

    // they are not a prefix of one-another
    else false;
  end match;
end crefPrefixOfIgnoreSubscripts;

public function crefNotPrefixOf "negation of crefPrefixOf"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean outBoolean;
algorithm
  outBoolean := match(cr1, cr2)
    // first is qualified, second is an unqualified ident, return false!
    case (DAE.CREF_QUAL(), DAE.CREF_IDENT()) then true;
    else not crefPrefixOf(cr1, cr2);
  end match;
end crefNotPrefixOf;

public function crefEqual
"Returns true if two component references are equal.
  No string comparison of unparsed crefs is performed!"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  output Boolean outBoolean;
algorithm
  outBoolean := crefEqualNoStringCompare(inComponentRef1,inComponentRef2);
end crefEqual;

public function crefInLst  "returns true if the cref is in the list of crefs"
  input DAE.ComponentRef cref;
  input list<DAE.ComponentRef> lst;
  output Boolean b;
algorithm
  b := List.isMemberOnTrue(cref,lst,crefEqual);
end crefInLst;

public function crefNotInLst  "returns true if the cref is not in the list of crefs"
  input DAE.ComponentRef cref;
  input list<DAE.ComponentRef> lst;
  output Boolean b;
algorithm
  b := not List.isMemberOnTrue(cref,lst,crefEqual);
end crefNotInLst;

public function crefEqualVerySlowStringCompareDoNotUse
"Returns true if two component references are equal,
  comparing strings if no other solution is found"
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
    case (_,_)
      algorithm
        true := referenceEq(inComponentRef1,inComponentRef2);
      then
        true;

    // simple identifiers
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = {}),DAE.CREF_IDENT(ident = n2,subscriptLst = {}))
      algorithm
        true := stringEq(n1, n2);
      then
        true;
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = (idx1 as _::_)),DAE.CREF_IDENT(ident = n2,subscriptLst = (idx2 as _::_)))
      algorithm
        true := stringEq(n1, n2);
        true := ExpressionBasics.subscriptEqual(idx1, idx2);
      then
        true;
        // BZ 2009-12
        // For some reason in some examples we get crefs on different forms.
        // the compare can be crefEqual(CREF_IDENT("mycref",_,{1,2,3}),CREF_IDENT("mycref[1,2,3]",_,{}))
        // I do belive this has something to do with variable replacement and BackendDAE.
        // TODO: investigate reason, until then keep as is.
        // I do believe that this is the same bug as adrians qual-ident bug below.
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = {}),DAE.CREF_IDENT(ident = n2,subscriptLst = (idx2 as _::_)))
      algorithm
        0 := System.stringFind(n1, n2); // n2 should be first in n1!
        s1 := n2 + "[" + ExpressionBasics.printListStr(idx2, ExpressionBasics.printSubscriptStr, ",") + "]";
        true := stringEq(s1,n1);
      then
        true;
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = (idx2 as _::_)),DAE.CREF_IDENT(ident = n2,subscriptLst = {}))
      algorithm
        0 := System.stringFind(n2, n1); // n1 should be first in n2!
        s1 := n1 + "[" + ExpressionBasics.printListStr(idx2, ExpressionBasics.printSubscriptStr, ",") + "]";
        true := stringEq(s1,n2);
      then
        true;
    // qualified crefs
    case (DAE.CREF_QUAL(ident = n1,subscriptLst = idx1,componentRef = cr1),DAE.CREF_QUAL(ident = n2,subscriptLst = idx2,componentRef = cr2))
      algorithm
        true := stringEq(n1, n2);
        true := crefEqualVerySlowStringCompareDoNotUse(cr1, cr2);
        true := ExpressionBasics.subscriptEqual(idx1, idx2);
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
      algorithm
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
      algorithm
        0 := System.stringFind(n2, n1); // n1 should be first in n2!
        s1 := printComponentRefStr(cr1);
        s2 := printComponentRefStr(cr2);
        true := stringEq(s1, s2);
      then
        true;
    // left cref is stringified!
    case (cr1 as DAE.CREF_IDENT(ident = n1),cr2 as DAE.CREF_QUAL(ident = n2))
      algorithm
        0 := System.stringFind(n1, n2); // n2 should be first in n1!
        s1 := printComponentRefStr(cr1);
        s2 := printComponentRefStr(cr2);
        true := stringEq(s1, s2);
      then
        true;
    // the crefs are not equal!
    else false;
  end matchcontinue;
end crefEqualVerySlowStringCompareDoNotUse;

public function crefEqualNoStringCompare
"Returns true if two component references are equal!
  IMPORTANT! do not use this function if you have
  stringified components, meaning this function will
  return false for: cref1: QUAL(x, IDENT(y)) != cref2: IDENT(x.y)"
  input DAE.ComponentRef inCref1;
  input DAE.ComponentRef inCref2;
  output Boolean outEqual;
algorithm
  if referenceEq(inCref1, inCref2) then
    outEqual := true;
    return;
  end if;

  outEqual := match(inCref1, inCref2)
    case (DAE.CREF_IDENT(), DAE.CREF_IDENT())
      then inCref1.ident == inCref2.ident and
           ExpressionBasics.subscriptEqual(inCref1.subscriptLst, inCref2.subscriptLst);

    case (DAE.CREF_QUAL(), DAE.CREF_QUAL())
      then inCref1.ident == inCref2.ident and
           crefEqualNoStringCompare(inCref1.componentRef, inCref2.componentRef) and
           ExpressionBasics.subscriptEqual(inCref1.subscriptLst, inCref2.subscriptLst);

    else false;
  end match;
end crefEqualNoStringCompare;

public function crefEqualReturn
"author: PA
  Checks if two crefs are equal and if
  so returns the cref, otherwise fail."
  input DAE.ComponentRef cr;
  input DAE.ComponentRef cr2;
  output DAE.ComponentRef ocr;
algorithm
  true := crefEqualNoStringCompare(cr, cr2);
  ocr := cr;
end crefEqualReturn;

public function crefEqualWithoutLastSubs
  "Checks if two crefs are equal, without considering their last subscripts."
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean res;
algorithm
  res := crefEqualNoStringCompare(crefStripLastSubs(cr1),crefStripLastSubs(cr2));
end crefEqualWithoutLastSubs;

public function crefEqualWithoutSubs
  "Checks if two crefs are equal, without considering their subscripts."
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean res;
algorithm
  res := crefEqualWithoutSubs2(referenceEq(cr1, cr2), cr1, cr2);
end crefEqualWithoutSubs;

protected function crefEqualWithoutSubs2
  input Boolean refEq;
  input DAE.ComponentRef icr1;
  input DAE.ComponentRef icr2;
  output Boolean res;
algorithm
  res := match(refEq, icr1, icr2)
    local
      DAE.Ident n1, n2;
      Boolean r;
      DAE.ComponentRef cr1,cr2;

    case (true, _, _) then true;

    case (_, DAE.CREF_IDENT(ident = n1), DAE.CREF_IDENT(ident = n2))
      then stringEq(n1, n2);

    case (_, DAE.CREF_QUAL(ident = n1, componentRef = cr1),
             DAE.CREF_QUAL(ident = n2, componentRef = cr2))
      algorithm
        r := stringEq(n1, n2);
        r := if r then crefEqualWithoutSubs2(referenceEq(cr1, cr2), cr1, cr2) else false;
      then
        r;

    else false;
  end match;
end crefEqualWithoutSubs2;

public function crefStripLastSubs
"Strips the last subscripts of a ComponentRef"
  input DAE.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match inComponentRef
    local
      DAE.Ident id;
      list<DAE.Subscript> s;
      DAE.ComponentRef cr_1,cr;
      DAE.Type t2;

    case DAE.CREF_IDENT(ident = id,identType = t2)
      then
        makeCrefIdent(id,t2,{});

    case DAE.CREF_QUAL(ident = id,identType = t2,subscriptLst = s,componentRef = cr)
      algorithm
        cr_1 := crefStripLastSubs(cr);
      then
        makeCrefQual(id,t2,s,cr_1);
  end match;
end crefStripLastSubs;

public function makeCrefIdent
"@author: adrpo
  This function creates a DAE.CREF_IDENT(ident, identType, subscriptLst)"
  input DAE.Ident ident;
  input DAE.Type identType "type of the identifier, without considering the subscripts";
  input list<DAE.Subscript> subscriptLst;
  output DAE.ComponentRef outCrefIdent;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outCrefIdent := DAE.CREF_IDENT(ident, identType, subscriptLst);
end makeCrefIdent;

public function makeCrefQual
"@author: adrpo
  This function creates a DAE.CREF_QUAL(ident, identType, subscriptLst, componentRef)"
  input DAE.Ident ident;
  input DAE.Type identType "type of the identifier, without considering the subscripts";
  input list<DAE.Subscript> subscriptLst;
  input DAE.ComponentRef componentRef;
  output DAE.ComponentRef outCrefQual;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  // subCref := shareCref(componentRef);
  // outCrefQual := shareCref(DAE.CREF_QUAL(ident, identType, subscriptLst, subCref));
  outCrefQual := DAE.CREF_QUAL(ident, identType, subscriptLst, componentRef);
end makeCrefQual;

public function printComponentRefStr
"Print a ComponentRef.
  LS: print functions that return a string instead of printing
      Had to duplicate the huge printExp2 and modify.
      An alternative would be to implement sprint somehow
  which would need internal state, with reset and
      getString methods.
      Once these are tested and ok, the printExp above can
      be replaced by a call to these _str functions and
      printing the result."
  input DAE.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := match inComponentRef
    local
      DAE.Ident s,str,strrest,strseb;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;
      Boolean b;

    // Optimize -- a function call less
    case DAE.CREF_IDENT(ident = s,subscriptLst = {})
      then s;

    // idents with subscripts
    case DAE.CREF_IDENT(ident = s,subscriptLst = subs)
      algorithm
        str := printComponentRef2Str(s, subs);
      then
        str;

    // Qualified - Modelica output - does not handle names with underscores
    // Qualified - non Modelica output
    case DAE.CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr)
      algorithm
        b := Config.modelicaOutput();
        str := printComponentRef2Str(s, subs);
        strrest := printComponentRefStr(cr);
        strseb := if b then "__" else ".";
        str := stringAppendList({str, strseb, strrest});
      then
        str;

    // Wild
    case DAE.WILD() then "_";
  end match;
end printComponentRefStr;

public function printComponentRef2Str
"Helper function to printComponentRefStr."
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
      algorithm
        b := Config.modelicaOutput();
        str := ExpressionBasics.printListStr(l, ExpressionBasics.printSubscriptStr, ",");
        (strseba,strsebb) := if b then ("_L","_R") else ("[","]");
        str := stringAppendList({s, strseba, str, strsebb});
      then
        str;

  end match;
end printComponentRef2Str;

public function printComponentRefListStr
  input list<DAE.ComponentRef> crs;
  output String res;
algorithm
  res := "{" + stringDelimitList(List.map(crs, printComponentRefStr), ",") + "}";
end printComponentRefListStr;

public function hashComponentRef "new hashing that properly deals with subscripts so [1,2] and [2,1] hash to different values"
  input DAE.ComponentRef cr;
  output Integer hash;
algorithm
hash := match cr
  local
    DAE.Ident id;
    DAE.Type tp;
    list<DAE.Subscript> subs;
    DAE.ComponentRef cr1;
  case DAE.CREF_IDENT(id,tp,subs) algorithm
    //print("IDENT, "+id+" hashed to "+intString(stringHashDjb2(id))+", subs hashed to "+intString(hashSubscripts(tp,subs))+"\n");
  then stringHashDjb2(id) + hashSubscripts(tp,subs);

  case DAE.CREF_QUAL(id,tp,subs,cr1) algorithm
    //print("QUAL, "+id+" hashed to "+intString(stringHashDjb2(id))+", subs hashed to "+intString(hashSubscripts(tp,subs))+"\n");
  then stringHashDjb2(id)+hashSubscripts(tp,subs)+hashComponentRef(cr1);

  else 0;
end match;
end hashComponentRef;

protected function hashSubscripts "help function, hashing subscripts making sure [1,2] and [2,1] doesn't match to the same number"
  input DAE.Type tp;
  input list<DAE.Subscript> subs;
  output Integer hash;
algorithm
  hash := match subs
  case {} then 0;
  // TODO: Currently, the types of component references are wrong, they consider the subscripts but they should not.
  // For example, given Real a[10,10];  the component reference 'a[1,2]' should have type Real[10,10] but it has type Real.
  else hashSubscripts2(List.fill(1,listLength(subs)),/*DAEUtil.expTypeArrayDimensions(tp),*/subs,1);
  end match;
end hashSubscripts;

protected function hashSubscripts2 "help function"
  input list<Integer> dims;
  input list<DAE.Subscript> subs;
  input Integer factor;
  output Integer hash;
algorithm
  hash := match(dims, subs)
  local
    DAE.Subscript s;
    list<Integer> rest_dims;
    list<DAE.Subscript> rest_subs;

    case({}, {}) then 0;
    case(_::rest_dims, s::rest_subs)
    // TODO: change to using dimensions once cref types has been fixed.
    then hashSubscript(s)*factor + hashSubscripts2(rest_dims,rest_subs,factor*1000/* *i1 */);
  end match;
end hashSubscripts2;

protected function hashSubscript "help function"
  input DAE.Subscript sub;
  output Integer hash;
algorithm
 hash := match sub
   local
     DAE.Exp exp;
     Integer i;

   case DAE.WHOLEDIM() then 0;
   case DAE.INDEX(DAE.ICONST(i)) then i;
   case DAE.SLICE(exp) then ExpressionBasics.hashExp(exp);
   case DAE.INDEX(exp) then ExpressionBasics.hashExp(exp);
   case DAE.WHOLE_NONEXP(exp) then ExpressionBasics.hashExp(exp);
 end match;
end hashSubscript;

annotation(__OpenModelica_Interface="frontend_dump");
end ComponentReferenceBasics;
