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

encapsulated package ComponentReference
" file:        ComponentReference.mo
  package:     ComponentReference
  description: All stuff for ComponentRef datatypes


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
protected import List;
protected import Print;
protected import System;
protected import Types;
protected import Util;

// do not make this public. instead use the function below.
protected constant DAE.ComponentRef dummyCref = DAE.CREF_IDENT("dummy", DAE.T_UNKNOWN_DEFAULT, {});

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
    //print("IDENT, "+id+" hashed to "+intString(stringHashDjb2(id))+", subs hashed to "+intString(hashSubscripts(tp,subs))+"\n");
  then stringHashDjb2(id) + hashSubscripts(tp,subs);

  case(DAE.CREF_QUAL(id,tp,subs,cr1)) equation
    //print("QUAL, "+id+" hashed to "+intString(stringHashDjb2(id))+", subs hashed to "+intString(hashSubscripts(tp,subs))+"\n");
  then stringHashDjb2(id)+hashSubscripts(tp,subs)+hashComponentRef(cr1);

  case(DAE.CREF_ITER(id,_,tp,subs))
  then stringHashDjb2(id)+ hashSubscripts(tp,subs);
  else 0;
end matchcontinue;
end hashComponentRef;

protected protected function hashSubscripts "help function, hashing subscripts making sure [1,2] and [2,1] doesn't match to the same number"
  input DAE.Type tp;
  input list<DAE.Subscript> subs;
  output Integer hash;
algorithm
  hash := match(tp,subs)
  case(_,{}) then 0;
  // TODO: Currently, the types of component references are wrong, they consider the subscripts but they should not.
  // For example, given Real a[10,10];  the component reference 'a[1,2]' should have type Real[10,10] but it has type Real.
  else hashSubscripts2(List.fill(1,listLength(subs)),/*DAEUtil.expTypeArrayDimensions(tp),*/subs,1);
  end match;
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
    case(_::rest_dims,s::rest_subs,_)
    // TODO: change to using dimensions once cref types has been fixed.
    then hashSubscript(s)*factor + hashSubscripts2(rest_dims,rest_subs,factor*1000/* *i1 */);
  end match;
end hashSubscripts2;

protected function hashSubscript "help function"
  input DAE.Subscript sub;
  output Integer hash;
algorithm
 hash := match(sub)
   local
     DAE.Exp exp;
     Integer i;

   case(DAE.WHOLEDIM()) then 0;
   case(DAE.INDEX(DAE.ICONST(i))) then i;
   case(DAE.SLICE(exp)) then Expression.hashExp(exp);
   case(DAE.INDEX(exp)) then Expression.hashExp(exp);
   case(DAE.WHOLE_NONEXP(exp)) then Expression.hashExp(exp);
 end match;
end hashSubscript;

public function createEmptyCrefMemory
"@author: adrpo
  creates an array, with one element for each record in ComponentRef!"
  output array<list<DAE.ComponentRef>> crefMemory;
algorithm
  crefMemory := arrayCreate(3, {});
end createEmptyCrefMemory;

/***************************************************/
/* generate a ComponentRef */
/***************************************************/

public function makeDummyCref
"@author: adrpo
  This function creates a dummy component reference"
  output DAE.ComponentRef outCrefIdent;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outCrefIdent := dummyCref;
end makeDummyCref;

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

public function makeUntypedCrefIdent
  input DAE.Ident ident;
  output DAE.ComponentRef outCrefIdent;
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
  input DAE.ComponentRef componentRef;
  output DAE.ComponentRef outCrefQual;
  annotation(__OpenModelica_EarlyInline = true);
protected
  DAE.ComponentRef subCref;
algorithm
  // subCref := shareCref(componentRef);
  // outCrefQual := shareCref(DAE.CREF_QUAL(ident, identType, subscriptLst, subCref));
  outCrefQual := DAE.CREF_QUAL(ident, identType, subscriptLst, componentRef);
end makeCrefQual;


/***************************************************/
/* transform to other types */
/***************************************************/

public function crefToPath
"This function converts a ComponentRef to a Path, if possible.
  If the component reference contains subscripts, it will silently
  fail."
  input DAE.ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath := match (inComponentRef)
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
  end match;
end crefToPath;

public function crefToPathIgnoreSubs
  input DAE.ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath := match(inComponentRef)
    local
      DAE.Ident i;
      Absyn.Path p;
      DAE.ComponentRef c;

    case DAE.CREF_IDENT(ident = i) then Absyn.IDENT(i);
    case DAE.CREF_QUAL(ident = i, componentRef = c)
      equation
        p = crefToPathIgnoreSubs(c);
      then
        Absyn.QUALIFIED(i, p);
  end match;
end crefToPathIgnoreSubs;

public function pathToCref
"This function converts a Absyn.Path to a ComponentRef."
  input Absyn.Path inPath;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inPath)
    local
      DAE.Ident i;
      DAE.ComponentRef c;
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
"  author: Frenkel TUD
  generates a cref from DAE.Var"
  input DAE.Var inVar;
  output DAE.ComponentRef outComponentRef;
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
"Transform an ComponentRef into Absyn.ComponentRef."
  input DAE.ComponentRef inComponentRef;
  output Absyn.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef)
    local
      list<Absyn.Subscript> subs_1;
      DAE.Ident id;
      list<DAE.Subscript> subs;
      Absyn.ComponentRef cr_1;
      DAE.ComponentRef cr;

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
        print("ComponentReference.unelabCref failed on: " + printComponentRefStr(inComponentRef) + "\n");
      then
        fail();

  end matchcontinue;
end unelabCref;

protected function unelabSubscripts
"Helper function to unelabCref, handles subscripts."
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
    case (DAE.WHOLE_NONEXP(exp = e) :: xs)
      equation
        xs_1 = unelabSubscripts(xs);
        e_1 = Expression.unelabExp(e);
      then
        (Absyn.SUBSCRIPT(e_1) :: xs_1);
  end match;
end unelabSubscripts;

public function toExpCref
"Translate an Absyn.ComponentRef into a ComponentRef.
  Note: Only support for indexed subscripts of integers"
  input Absyn.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef)
    local
      list<DAE.Subscript> subs_1;
      DAE.Ident id;
      list<Absyn.Subscript> subs;
      DAE.ComponentRef cr_1;
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
"Helper function to toExpCref."
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  output list<DAE.Subscript> outSubscriptLst;
algorithm
  outSubscriptLst := matchcontinue (inAbsynSubscriptLst)
    local
      list<DAE.Subscript> xs_1;
      Integer i;
      list<Absyn.Subscript> xs;
      DAE.ComponentRef cr_1;
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
        _ = stringAppendList({"#Error converting subscript: ",s," to Expression.\n"});
        //print("#Error converting subscript: " + s + " to Expression.\n");
        //Print.printErrorBuf(str);
        xs_1 = toExpCrefSubs(xs);
      then
        xs_1;
  end matchcontinue;
end toExpCrefSubs;


public function crefToStr
"This function converts a ComponentRef to a String.
  It is a tail recursive implementation, because of that it
  neads inPreString. Use inNameSeperator to define the
  Separator inbetween and between the namespace names and the name"
  input String inPreString;
  input DAE.ComponentRef inComponentRef "The ComponentReference";
  input String inNameSeparator "The Separator between the Names";
  output String outString;
algorithm
  outString:=
  match (inPreString,inComponentRef,inNameSeparator)
    local
      DAE.Ident s,ns,ss;
      DAE.ComponentRef n;
    case (_,DAE.CREF_IDENT(ident = s),_)
      equation
        ss = stringAppend(inPreString, s);
      then ss;
    case (_,DAE.CREF_QUAL(ident = s,componentRef = n),_)
      equation
        ns = stringAppendList({inPreString, s, inNameSeparator});
        ss = crefToStr(ns,n,inNameSeparator);
      then ss;
  end match;
end crefToStr;

public function crefStr
"This function simply converts a ComponentRef to a String."
  input DAE.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := if Flags.getConfigBool(Flags.MODELICA_OUTPUT)
                    then crefToStr("",inComponentRef,"__")
                    else crefToStr("",inComponentRef,".");
end crefStr;

public function crefModelicaStr
"Same as crefStr, but uses _ instead of . "
  input DAE.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString:= crefToStr("",inComponentRef,"_");
end crefModelicaStr;

public function printComponentRefOptStr
"@autor: adrpo
  Print a cref or none"
  input Option<DAE.ComponentRef> inComponentRefOpt;
  output String outString;
algorithm
   outString := match(inComponentRefOpt)
     local
       String str;
       DAE.ComponentRef cref;

     // none
     case NONE() then "NONE()";

     // some
     case SOME(cref)
       equation
         str = printComponentRefStr(cref);
         str = "SOME(" + str + ")";
       then
         str;
   end match;
end printComponentRefOptStr;

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
  outString := match (inComponentRef)
    local
      DAE.Ident s,str,strrest,strseb;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;
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
      then s + "/* iter index " + intString(ix) + " */";

    // idents with subscripts
    case DAE.CREF_ITER(ident = s,index=ix,subscriptLst = subs)
      equation
        str = printComponentRef2Str(s, subs);
      then
        str + "/* iter index " + intString(ix) + " */";

    // Qualified - Modelica output - does not handle names with underscores
    // Qualified - non Modelica output
    case DAE.CREF_QUAL(ident = s,subscriptLst = subs,componentRef = cr)
      equation
        b = Config.modelicaOutput();
        str = printComponentRef2Str(s, subs);
        strrest = printComponentRefStr(cr);
        strseb = if b then "__" else ".";
        str = stringAppendList({str, strseb, strrest});
      then
        str;

    // Wild
    case DAE.WILD() then "_";
  end match;
end printComponentRefStr;

public function printComponentRefStrFixDollarDer
  "Like printComponentRefStr but also fixes the special dollar-sign variables"
  input DAE.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := match (inComponentRef)
    local
      DAE.ComponentRef cr;
    case (DAE.CREF_QUAL(ident = "$DER",subscriptLst = {},componentRef=cr))
      then "der(" + printComponentRefStr(cr) + ")";
    else printComponentRefStr(inComponentRef);
  end match;
end printComponentRefStrFixDollarDer;

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
      equation
        b = Config.modelicaOutput();
        str = ExpressionDump.printListStr(l, ExpressionDump.printSubscriptStr, ",");
        ((strseba,strsebb)) = if b then ("_L","_R") else ("[","]");
        str = stringAppendList({s, strseba, str, strsebb});
      then
        str;

  end match;
end printComponentRef2Str;

public function debugPrintComponentRefTypeStr "Function: debugPrintComponentRefTypeStr
This function is equal to debugPrintComponentRefTypeStr with the extra feature that it
prints the base type of each ComponentRef.
NOTE Only used for debugging."
  input DAE.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := match (inComponentRef)
    local
      DAE.Ident s,str,str2,strrest,str_1;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;
      DAE.Type ty;

    case DAE.WILD() then "_";

    case DAE.CREF_IDENT(ident = s,identType=ty,subscriptLst = subs)
      equation
        str_1 = ExpressionDump.printListStr(subs, ExpressionDump.debugPrintSubscriptStr, ", ");
        str = s + (if stringLength(str_1) > 0 then "["+ str_1 + "]" else "");
        str2 = Types.unparseType(ty);
        str = stringAppendList({str," [",str2,"]"});
      then
        str;

    // Does not handle names with underscores
    case DAE.CREF_QUAL(ident = s,identType=ty,subscriptLst = subs,componentRef = cr)
      equation
        if (Config.modelicaOutput())
        then
          str = printComponentRef2Str(s, subs);
          str2 = Types.unparseType(ty);
          strrest = debugPrintComponentRefTypeStr(cr);
          str = stringAppendList({str," [",str2,"] ", "__", strrest});
        else
          str_1 = ExpressionDump.printListStr(subs, ExpressionDump.debugPrintSubscriptStr, ", ");
          str = s + (if stringLength(str_1) > 0 then "["+ str_1 + "]" else "");
          str2 = Types.unparseType(ty);
          strrest = debugPrintComponentRefTypeStr(cr);
          str = stringAppendList({str," [",str2,"] ", ".", strrest});
        end if;
      then
        str;

  end match;
end debugPrintComponentRefTypeStr;


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

public function crefSortFunc "A sorting function (greatherThan) for crefs"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean greaterThan;
algorithm
  greaterThan := stringCompare(printComponentRefStr(cr1),printComponentRefStr(cr2)) > 0;
end crefSortFunc;

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
  isGreater := crefLexicalCompareubsAtEnd(cr1,cr2) > 0;
end crefLexicalGreaterSubsAtEnd;

public function crefLexicalCompareubsAtEnd
"mahge:
  Compares two crefs lexically. Subscripts are treated as if they are
  they are at the end of the whole component reference.
  e.g. r[1].i is greater than r[2].a.
  returns value is same as C strcmp. 0 if equal, 1 if first is greater, -1 otherwise"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Integer comapred;
protected
  String cr1_nosub_str;
  String cr2_nosub_str;
  list<Integer> subs1;
  list<Integer> subs2;
  Integer idents_comapred;
algorithm
  cr1_nosub_str := crefStr(cr1);
  cr2_nosub_str := crefStr(cr2);
  subs1 := Expression.subscriptsInt(crefSubs(cr1));
  subs2 := Expression.subscriptsInt(crefSubs(cr2));
  idents_comapred := stringCompare(cr1_nosub_str, cr2_nosub_str);
  comapred := crefLexicalCompareubsAtEnd2(idents_comapred, subs1, subs2);
end crefLexicalCompareubsAtEnd;

protected function crefLexicalCompareubsAtEnd2
"mahge:
  Helper function for crefLexicalCompareubsAtEnd
  compares subs. However only if the crefs with out subs are equal.
  (i.e. identsCompared is 0)
  otheriwse just returns"
  input Integer identsCompared;
  input list<Integer> inSubs1;
  input list<Integer> inSubs2;
  output Integer outCompared;
algorithm
  outCompared := match(identsCompared, inSubs1, inSubs2)
    local
      Integer sub1, sub2;
      list<Integer> rest1, rest2;

    case (1, _, _)
      then 1;

    case (-1, _, _)
      then -1;

    // No subs
    case (_, {}, {})
      then identsCompared;

    // One of them has subs while the nosub crefs are the same
    case (0, {}, _)
      then -1;

    case (0, _, {})
      then 1;

    case (0, sub1::rest1, sub2::rest2)
      guard
        intEq(sub1,sub2)
       then
         crefLexicalCompareubsAtEnd2(0, rest1,rest2);

    case (0, sub1::_, sub2::_)
      guard
        intGe(sub1,sub2)
       then 1;

    case (0, _::_, _::_)
       then -1;

    case (_, _, _)
      equation
        print("ComponentReference.crefLexicalCompareubsAtEnd2 failed \n");
       then
         fail();

  end match;
end crefLexicalCompareubsAtEnd2;

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
           Expression.subscriptEqual(prefixCref.subscriptLst, fullCref.subscriptLst) and
           crefPrefixOf(prefixCref.componentRef, fullCref.componentRef);

    // adrpo: 2010-10-07: first is an ID, second is qualified, see if one is prefix of the other
    //                    even if the first one DOESN'T HAVE SUBSCRIPTS!
    case (DAE.CREF_IDENT(subscriptLst = {}), DAE.CREF_QUAL())
      then prefixCref.ident == fullCref.ident;

    // first is an ID, second is qualified, see if one is prefix of the other
    case (DAE.CREF_IDENT(), DAE.CREF_QUAL())
      then prefixCref.ident == fullCref.ident and
           Expression.subscriptEqual(prefixCref.subscriptLst, fullCref.subscriptLst);

    // adrpo: 2010-10-07: first is an ID, second is an ID, see if one is prefix of the other
    //                    even if the first one DOESN'T HAVE SUBSCRIPTS!
    case (DAE.CREF_IDENT(subscriptLst = {}), DAE.CREF_IDENT())
      then stringEq(prefixCref.ident, fullCref.ident);

    case (DAE.CREF_IDENT(), DAE.CREF_IDENT())
      then prefixCref.ident == fullCref.ident and
           Expression.subscriptEqual(prefixCref.subscriptLst, fullCref.subscriptLst);

    // they are not a prefix of one-another
    else false;
  end match;
end crefPrefixOf;

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
        s1 = n2 + "[" + ExpressionDump.printListStr(idx2, ExpressionDump.printSubscriptStr, ",") + "]";
        true = stringEq(s1,n1);
      then
        true;
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = (idx2 as _::_)),DAE.CREF_IDENT(ident = n2,subscriptLst = {}))
      equation
        0 = System.stringFind(n2, n1); // n1 should be first in n2!
        s1 = n1 + "[" + ExpressionDump.printListStr(idx2, ExpressionDump.printSubscriptStr, ",") + "]";
        true = stringEq(s1,n2);
      then
        true;
    // qualified crefs
    case (DAE.CREF_QUAL(ident = n1,subscriptLst = idx1,componentRef = cr1),DAE.CREF_QUAL(ident = n2,subscriptLst = idx2,componentRef = cr2))
      equation
        true = stringEq(n1, n2);
        true = crefEqualVerySlowStringCompareDoNotUse(cr1, cr2);
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
    else false;
  end matchcontinue;
end crefEqualVerySlowStringCompareDoNotUse;

public function crefEqualNoStringCompare
"Returns true if two component references are equal!
  IMPORTANT! do not use this function if you have
  stringified components, meaning this function will
  return false for: cref1: QUAL(x, IDENT(x)) != cref2: IDENT(x.y)"
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
           Expression.subscriptEqual(inCref1.subscriptLst, inCref2.subscriptLst);

    case (DAE.CREF_QUAL(), DAE.CREF_QUAL())
      then inCref1.ident == inCref2.ident and
           crefEqualNoStringCompare(inCref1.componentRef, inCref2.componentRef) and
           Expression.subscriptEqual(inCref1.subscriptLst, inCref2.subscriptLst);

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
      equation
        r = stringEq(n1, n2);
        r = if r then crefEqualWithoutSubs2(referenceEq(cr1, cr2), cr1, cr2) else false;
      then
        r;

    else false;
  end match;
end crefEqualWithoutSubs2;

public function crefIsIdent
"returns true if ComponentRef is an ident,
 i.e a => true , a.b => false"
  input DAE.ComponentRef cr;
  output Boolean res;
algorithm
  res := match(cr)
    case DAE.CREF_IDENT() then true;
    else false;
  end match;
end crefIsIdent;

public function crefIsNotIdent
"returns true if ComponentRef is not an ident,
 i.e a => false , a.b => true"
  input DAE.ComponentRef cr;
  output Boolean res;
algorithm
  res := match(cr)
    case DAE.CREF_IDENT() then false;
    else true;
  end match;
end crefIsNotIdent;

public function isRecord "
function isRecord
  returns true if the type of the last ident is a record"
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := match(cr)
  local
    DAE.ComponentRef comp;
    case(DAE.CREF_IDENT(identType = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)))) then true;
    /* this case is false because it is not the last ident.
    case(DAE.CREF_QUAL(identType = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)))) then true;*/
    case(DAE.CREF_QUAL(componentRef=comp)) then isRecord(comp);
    else false;
  end match;
end isRecord;

public function isArrayElement "returns true if cref is elemnt of an array"
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := match(cr)
  local
    DAE.ComponentRef comp;
    case(DAE.CREF_IDENT(identType = DAE.T_ARRAY())) then true;
    case(DAE.CREF_QUAL(identType = DAE.T_ARRAY())) then true;
    case(DAE.CREF_QUAL(componentRef=comp)) then isArrayElement(comp);
    else false;
  end match;
end isArrayElement;

public function isPreCref
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := match(cr)
    case(DAE.CREF_QUAL(ident = "$PRE")) then true;
    else false;
  end match;
end isPreCref;

public function popPreCref
  input DAE.ComponentRef inCR;
  output DAE.ComponentRef outCR;
algorithm
  outCR := match(inCR)
    local DAE.ComponentRef cr;
    case(DAE.CREF_QUAL(ident = "$PRE", componentRef=cr)) then cr;
    else inCR;
  end match;
end popPreCref;

public function popCref
  input DAE.ComponentRef inCR;
  output DAE.ComponentRef outCR;
algorithm
  outCR := match(inCR)
    local DAE.ComponentRef cr;
    case(DAE.CREF_QUAL(componentRef=cr)) then cr;
    else inCR;
  end match;
end popCref;

public function crefIsFirstArrayElt
"This function returns true for component references that
  are arrays and references the first element of the array.
  like for instance a.b{1,1} and a{1} returns true but
  a.b{1,2} or a{2} returns false."
  input DAE.ComponentRef inComponentRef;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef)
    local
      list<DAE.Subscript> subs;
      list<DAE.Exp> exps;
      DAE.ComponentRef cr;
    case (cr)
      equation
        if stringEqual(Config.simCodeTarget(), "Cpp") then
          ((subs as (_ :: _))) = crefLastSubs(cr);
        else
          ((subs as (_ :: _))) = crefSubs(cr);
        end if;
        // fails if any mapped functions returns false
      then List.mapAllValueBool(subs, Expression.subscriptIsFirst, true);
    else false;
  end matchcontinue;
end crefIsFirstArrayElt;

public function crefHaveSubs "Function: crefHaveSubs
  Checks whether Componentref has any subscripts, recursive "
  input DAE.ComponentRef icr;
  output Boolean ob;
algorithm ob := matchcontinue(icr)
  local
    DAE.ComponentRef cr;
    Boolean b;
    DAE.Ident str;
    Integer idx;
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
  else false;
end matchcontinue;
end crefHaveSubs;

public function crefHasScalarSubscripts "returns true if the subscripts of the cref results in a scalar variable.
For example given Real x[3,3]
  x[1,2] has scalar subscripts
  x[1] has not scalar subscripts
  x[:,1] has not scalar subscripts
  x[{1,2},1] has not scalar subscripts
"
  input DAE.ComponentRef cr;
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
    else false;
  end matchcontinue;
end crefHasScalarSubscripts;

public function crefIsScalarWithAllConstSubs
  ""
  input DAE.ComponentRef inCref;
  output Boolean isScalar;
algorithm
  isScalar := matchcontinue(inCref)
    local
      Boolean res;
      list<DAE.Subscript> subs;
      list<DAE.Dimension> dims;
      list<DAE.ComponentRef> tempcrefs;
      Integer ndim, nsub;

    case _ equation {} = crefSubs(inCref); then true;

    case _
      equation
        (subs as (_::_))= crefSubs(inCref);
        dims = crefDims(inCref);
        // Dimensions may be removed when a component is instantiated if it has
        // constant subscripts though, so it may have more subscripts than
        // dimensions.
        // mahge: TODO: Does this still happen?
        true = listLength(dims) <= listLength(subs);
        true = Expression.subscriptConstants(subs);
      then
        true;

    else false;

  end matchcontinue;
end crefIsScalarWithAllConstSubs;

public function crefIsScalarWithVariableSubs
  ""
  input DAE.ComponentRef inCref;
  output Boolean isScalar;
algorithm
  isScalar := matchcontinue(inCref)
    local
      Boolean res;
      list<DAE.Subscript> subs;
      list<DAE.Dimension> dims;
      list<DAE.ComponentRef> tempcrefs;
      Integer ndim, nsub;

    case _
      equation
        (subs as (_::_))= crefSubs(inCref);
        dims = crefDims(inCref);
        // Dimensions may be removed when a component is instantiated if it has
        // constant subscripts though, so it may have more subscripts than
        // dimensions.
        // mahge: TODO: Does this still happen?
        true = listLength(dims) <= listLength(subs);
        false = Expression.subscriptConstants(subs);
      then
        true;

    else false;

  end matchcontinue;
end crefIsScalarWithVariableSubs;

public function containWholeDim " A function to check if a cref contains a [:] wholedim element in the subscriptlist.
"
  input DAE.ComponentRef inRef;
  output Boolean wholedim;

algorithm
  wholedim := match(inRef)
    local
      DAE.ComponentRef cr;
      list<DAE.Subscript> ssl;
      DAE.Ident name;
      DAE.Type ty;
    case(DAE.CREF_IDENT(_,ty,ssl))
      equation
        wholedim = containWholeDim2(ssl,ty);
      then
        wholedim;
    case(DAE.CREF_QUAL(_,_,_,cr))
      equation
        wholedim = containWholeDim(cr);
      then
        wholedim;
    else false;
  end match;
end containWholeDim;

public function traverseCref
  replaceable type Type_a subtypeof Any;
  input DAE.ComponentRef cref;
  input FuncType func;
  input Type_a argIn;
  output Type_a argOut;
    partial function FuncType
      input DAE.ComponentRef crefIn;
      input Type_a inType;
      output Type_a outType;
    end FuncType;
algorithm
  argOut := matchcontinue(cref,func,argIn)
  local
    DAE.ComponentRef cr;
    Type_a arg;
   case(DAE.CREF_IDENT(_,_,_),_,_)
    equation
      arg = func(cref,argIn);
    then arg;
  case(DAE.CREF_QUAL(_,_,_,cr),_,_)
    equation
      arg = func(cref,argIn);
    then traverseCref(cr,func,arg);
  else
    equation
      print("traverseCref failed!");
      then fail();
  end matchcontinue;
end traverseCref;

public function crefIsRec"traverse function to check if one of the crefs is a record"
  input DAE.ComponentRef cref;
  input Boolean isRecIn;
  output Boolean isRec;
algorithm
  // is this case the last ident needs a consideration
  isRec := isRecIn or Types.isRecord(crefLastType(cref));
end crefIsRec;

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

    case((DAE.WHOLEDIM())::_,DAE.T_ARRAY(_,_,_)) then true;

    case((DAE.SLICE(es1))::_, DAE.T_ARRAY(_,ad,_))
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

    case(_::ssl,_)
      equation
        wholedim = containWholeDim2(ssl,inType);
      then
        wholedim;
  end matchcontinue;
end containWholeDim2;

protected function containWholeDim3 "Verify that a slice adresses all dimensions"
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

    else false;
  end matchcontinue;
end containWholeDim3;

/***************************************************/
/* Getter  */
/***************************************************/

public function crefArrayGetFirstCref
"mahge: This function is used to get the first element in
an array cref if the cref was to be expanded. e.g.
     (a->nonarray, b->array) given a.b[1]   return a.b[1].
     (a->nonarray, b->array) given a.b      return a.b[1].
     (a->array, b->array) given a[1].b   return a[1].b[1]
     (a->array, b->array) given a[2].b   return a[2].b[1]
  i.e essentially filling the missing subs with 1.
"
  input DAE.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match(inComponentRef)
    local
      DAE.ComponentRef cr;
      list<DAE.Dimension> dims;
      list<DAE.Subscript> subs, newsubs;
      Integer diff;
      DAE.Type ty;
      DAE.Ident i;

    case DAE.CREF_IDENT(i, ty, subs)
      algorithm
        dims := Types.getDimensions(ty);
        diff := listLength(dims) - listLength(subs);
        newsubs := List.fill(DAE.INDEX(DAE.ICONST(1)), diff);
        subs := List.appendNoCopy(subs,newsubs);
      then
        DAE.CREF_IDENT(i, ty, subs);

    case DAE.CREF_QUAL(i, ty, subs, cr)
      algorithm
        dims := Types.getDimensions(ty);
        diff := listLength(dims) - listLength(subs);
        newsubs := List.fill(DAE.INDEX(DAE.ICONST(1)), diff);
        subs := List.appendNoCopy(subs,newsubs);
        cr := crefArrayGetFirstCref(cr);
      then
        DAE.CREF_QUAL(i, ty, subs, cr);
  end match;
end crefArrayGetFirstCref;


public function crefLastPath
  "Returns the last identifier of a cref as an Absyn.IDENT."
  input DAE.ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath := match(inComponentRef)
    local
      DAE.Ident i;
      DAE.ComponentRef c;
    case DAE.CREF_IDENT(ident = i, subscriptLst = {}) then Absyn.IDENT(i);
    case DAE.CREF_QUAL(componentRef = c, subscriptLst = {}) then crefLastPath(c);
  end match;
end crefLastPath;

public function crefFirstIdent
  "Returns the first identifier of a component reference."
  input DAE.ComponentRef inComponentRef;
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
"author: PA
  Returns the last identfifier of a ComponentRef."
  input DAE.ComponentRef inComponentRef;
  output DAE.Ident outIdent;
algorithm
  outIdent := match (inComponentRef)
    local
      DAE.Ident id,res;
      DAE.ComponentRef cr;

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
  input DAE.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef)
    local
      DAE.Ident id;
      DAE.ComponentRef res,cr;

    case (DAE.CREF_IDENT()) then inComponentRef;

    case (DAE.CREF_QUAL(componentRef = cr))
      equation
        res = crefLastCref(cr);
      then
        res;
  end match;
end crefLastCref;

public function crefRest
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  DAE.CREF_QUAL(componentRef = outCref) := inCref;
end crefRest;

public function crefTypeFull2
  "Helper function to crefTypeFull."
  input DAE.ComponentRef inCref;
  output DAE.Type outType;
  output list<DAE.Dimension> outDims;
algorithm
  (outType, outDims) := match(inCref)
    local
      DAE.ComponentRef cr;
      DAE.Type ty, basety;
      list<DAE.Dimension> dims, restdims;
      list<DAE.Subscript> subs;

    case DAE.CREF_IDENT(identType = ty, subscriptLst = subs)
      equation
        (ty,dims) = Types.flattenArrayType(ty);
        dims = List.stripN(dims,listLength(subs));
      then (ty,dims);

    case DAE.CREF_QUAL(identType = ty, subscriptLst = subs, componentRef = cr)
      equation
        (ty,dims) = Types.flattenArrayType(ty);
        dims = List.stripN(dims,listLength(subs));

        (basety, restdims) = crefTypeFull2(cr);
        dims = listAppend(dims, restdims);
      then (basety, dims);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("ComponentReference.crefTypeFull2 failed on cref: ");
        Debug.traceln(printComponentRefStr(inCref));
      then
        fail();
  end match;
end crefTypeFull2;

public function crefTypeFull
  "mahge:
   This function gives the type of a cref.
   This is done by considering how many dimensions and subscripts
   the cref has. It also takes in to consideration where the subscripts
   are loacated in a qualifed cref. e.g. consider :
    record R
      Real [4]
    end R;

    R a[3][2];

    if we have a cref a[1][1].b[1] --> Real
                      a[1].b --> Real[2][4]
                      a.b[1] --> Real[3][2]
                      a[1][1].b --> Real[4]
                      a[1].b[1] --> Real[2]

   "
  input DAE.ComponentRef inCref;
  output DAE.Type outType;
protected
  DAE.Type ty;
  list<DAE.Dimension> dims;
algorithm
  (ty,dims) := crefTypeFull2(inCref);
  if listEmpty(dims) then
    outType := ty;
  else
    outType := DAE.T_ARRAY(ty, dims, Types.getTypeSource(ty));
  end if;
end crefTypeFull;

public function crefType
  " ***deprecated. Use crefTypeFull unless you really specifically want the type of the first cref.
  Function for extracting the type of the first identifier of a cref.
  "
  input DAE.ComponentRef inCref;
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

public function crefLastType
" ***deprecated.
  mahge: Use crefTypeFull unless you really specifically want the type of the last cref.
  Remember the type of a cref is not the same as the type of the last cref!!.

returns the 'last' type of a cref.
For instance, for the cref 'a.b' it returns the type in identifier 'b'
adrpo:
  NOTE THAT THIS WILL BE AN ARRAY TYPE IF THE LAST CREF IS AN ARRAY TYPE
  If you want to get the component reference type considering subscripts use:
  crefTypeConsiderSubs"
  input DAE.ComponentRef inRef;
  output DAE.Type res;
algorithm
  res := match (inRef)
    local
      DAE.Type t2;
      DAE.ComponentRef cr;

    case(DAE.CREF_IDENT(_,t2,_)) then t2;
    case(DAE.CREF_QUAL(_,_,_,cr)) then crefLastType(cr);
  end match;
end crefLastType;

public function crefDims "
function: crefDims
  Return the all dimension (contained in the types) of a ComponentRef"
  input DAE.ComponentRef inComponentRef;
  output list<DAE.Dimension> outDimensionLst;
algorithm
  outDimensionLst := match (inComponentRef)
    local
      list<DAE.Dimension> dims,res;
      DAE.Type idType;
      DAE.ComponentRef cr;

    case (DAE.CREF_IDENT(identType = idType)) then Types.getDimensions(idType);

    case (DAE.CREF_QUAL(componentRef = cr, identType = idType))
      equation
        dims = Types.getDimensions(idType);
        res = crefDims(cr);
        res = listAppend(dims,res);
      then
        res;
  end match;
end crefDims;

public function crefSubs "
function: crefSubs
  Return the all subscripts of a ComponentRef"
  input DAE.ComponentRef inComponentRef;
  output list<DAE.Subscript> outSubscriptLst;
algorithm
  outSubscriptLst := match (inComponentRef)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs,res;
      DAE.ComponentRef cr;

    case (DAE.CREF_IDENT(subscriptLst = subs)) then subs;

    case (DAE.CREF_QUAL(componentRef = cr,subscriptLst=subs))
      equation
        res = crefSubs(cr);
        res = listAppend(subs,res);
      then
        res;
  end match;
end crefSubs;

public function crefFirstSubs
  input DAE.ComponentRef inCref;
  output list<DAE.Subscript> outSubscripts;
algorithm
  outSubscripts := match inCref
    case DAE.CREF_IDENT() then inCref.subscriptLst;
    case DAE.CREF_QUAL() then inCref.subscriptLst;
    else {};
  end match;
end crefFirstSubs;

public function crefLastSubs "Return the last subscripts of a ComponentRef"
  input DAE.ComponentRef inComponentRef;
  output list<DAE.Subscript> outSubscriptLst;
algorithm
  outSubscriptLst := match (inComponentRef)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;

    case (DAE.CREF_IDENT(subscriptLst=subs))
    then subs;

    case (DAE.CREF_QUAL(componentRef=cr)) equation
    then crefLastSubs(cr);
  end match;
end crefLastSubs;

public function crefFirstCref
"Returns the first part of a component reference, i.e the identifier"
  input DAE.ComponentRef inCr;
  output DAE.ComponentRef outCr;
algorithm
  outCr := match(inCr)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;
      DAE.Type t2;

    case( DAE.CREF_QUAL(id,t2,subs,_)) then makeCrefIdent(id,t2,subs);
    case( DAE.CREF_IDENT(_,_,_)) then inCr;
  end match;
end crefFirstCref;

public function crefTypeConsiderSubs
" ***deprecated.
  mahge: use crefTypeFull(). This is not what you want. We need to consider not just the last subs but all subs.
  We can have slices.

Function: crefTypeConsiderSubs
Author: PA
Function for extracting the type out of a componentReference and consider the influence of the last subscript list.
For exampel. If the last cref type is Real[3,3] and the last subscript list is {Expression.INDEX(1)}, the type becomes Real[3], i.e
one dimension is lifted.
See also, crefType.
"
  input DAE.ComponentRef cr;
  output DAE.Type res;
algorithm
 res := Expression.unliftArrayTypeWithSubs(crefLastSubs(cr),crefLastType(cr));
end crefTypeConsiderSubs;

public function crefNameType "Function: crefType
Function for extracting the name and type out of the first cref of a componentReference.
"
  input DAE.ComponentRef inRef;
  output DAE.Ident id;
  output DAE.Type res;
algorithm
  (id,res) :=
  matchcontinue (inRef)
    local
      DAE.Type t2;
      DAE.Ident name;
      String s;

    case(DAE.CREF_IDENT(name,t2,_)) then (name,t2);

    case(DAE.CREF_QUAL(name,t2,_,_)) then (name,t2);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("-ComponentReference.crefType failed on Cref:");
        s = printComponentRefStr(inRef);
        Debug.traceln(s);
      then
        fail();
  end matchcontinue;
end crefNameType;

public function getArrayCref
  input DAE.ComponentRef name;
  output Option<DAE.ComponentRef> arrayCref;
algorithm
  arrayCref := matchcontinue(name)
    local
      DAE.ComponentRef arrayCrefInner;

    case (_) equation
      true = crefIsFirstArrayElt(name);
      if stringEqual(Config.simCodeTarget(), "Cpp") then
        arrayCrefInner = crefStripLastSubs(name);
      else
        arrayCrefInner = crefStripSubs(name);
      end if;
    then SOME(arrayCrefInner);

    else
    then NONE();
  end matchcontinue;
end getArrayCref;

public function getArraySubs
  input DAE.ComponentRef name;
  output list<DAE.Subscript> arraySubs;
algorithm
  arraySubs := matchcontinue(name)
    local
      list<DAE.Subscript> arrayCrefSubs;

    case (_) equation
      arrayCrefSubs = crefSubs(name);
    then arrayCrefSubs;

    else
    then {};
  end matchcontinue;
end getArraySubs;

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
  input DAE.ComponentRef icr;
  input String ident;
  input list<DAE.Subscript> subs;
  input DAE.Type tp;
  output DAE.ComponentRef newCr;
algorithm
  newCr := match(icr,ident,subs,tp)
    local
      DAE.Type tp1;
      String id1;
      list<DAE.Subscript> subs1;
      DAE.ComponentRef cr;

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
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := makeCrefQual(DAE.derivativeNamePrefix, DAE.T_REAL_DEFAULT, {}, inCref);
end crefPrefixDer;

public function crefPrefixPre "public function crefPrefixPre
  Appends $PRE to a cref, so a => $PRE.a"
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := makeCrefQual(DAE.preNamePrefix, DAE.T_UNKNOWN_DEFAULT, {}, inCref);
end crefPrefixPre;

public function crefPrefixPrevious "public function crefPrefixPrevious
  Appends $CLKPRE to a cref, so a => $CLKPRE.a"
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := makeCrefQual(DAE.previousNamePrefix, DAE.T_UNKNOWN_DEFAULT, {}, inCref);
end crefPrefixPrevious;

public function crefPrefixStart "public function crefPrefixStart
  Appends $START to a cref, so a => $START.a"
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := makeCrefQual(DAE.startNamePrefix, DAE.T_UNKNOWN_DEFAULT, {}, inCref);
end crefPrefixStart;

public function crefPrefixString
  "Prefixes a cref with a string identifier, e.g.:
    crefPrefixString(a, b.c) => a.b.c"
  input String inString;
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := makeCrefQual(inString, DAE.T_UNKNOWN_DEFAULT, {}, inCref);
end crefPrefixString;

public function crefPrefixStringList
  "Prefixes a cref with a list of strings, e.g.:
    crefPrefixStringList({a, b, c}, d.e.f) => a.b.c.d.e.f"
  input list<String> inStrings;
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inStrings, inCref)
    local
      String str;
      list<String> rest_str;
      DAE.ComponentRef cref;

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
  input DAE.ComponentRef inCref;
  input Absyn.Path inPath;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inPath)
    local
      Absyn.Ident name;
      Absyn.Path rest_path;
      DAE.ComponentRef cref;

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
"Prepend a string to a component reference.
  For qualified named, this means prepending a
  string to the first identifier."
  input String inString;
  input DAE.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inString,inComponentRef)
    local
      DAE.Ident i_1,p,i;
      list<DAE.Subscript> s;
      DAE.ComponentRef c;
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
  input DAE.ComponentRef cr;
  output DAE.ComponentRef ocr;
algorithm
  ocr := joinCrefs(cr,DAE.CREF_IDENT(str,DAE.T_UNKNOWN_DEFAULT,{}));
end appendStringCref;

public function appendStringFirstIdent
  "Appends a string to the first identifier of a cref."
  input String inString;
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inString, inCref)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;
      DAE.Type ty;
      Integer idx;

    case (_, DAE.CREF_QUAL(id, ty, subs, cr))
      equation
        id = stringAppend(id, inString);
      then DAE.CREF_QUAL(id, ty, subs, cr);

    case (_, DAE.CREF_IDENT(id, ty, subs))
      equation
        id = stringAppend(id, inString);
      then
        DAE.CREF_IDENT(id, ty, subs);

    case (_, DAE.CREF_ITER(id, idx, ty, subs))
      equation
        id = stringAppend(id, inString);
      then
        DAE.CREF_ITER(id, idx, ty, subs);

  end match;
end appendStringFirstIdent;

public function appendStringLastIdent
  "Appends a string to the last identifier of a cref."
  input String inString;
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inString, inCref)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;
      DAE.Type ty;
      Integer idx;

    case (_, DAE.CREF_QUAL(id, ty, subs, cr))
      equation
        cr = appendStringLastIdent(inString,cr);
      then DAE.CREF_QUAL(id, ty, subs, cr);

    case (_, DAE.CREF_IDENT(id, ty, subs))
      equation
        id = stringAppend(id, inString);
      then
        DAE.CREF_IDENT(id, ty, subs);

    case (_, DAE.CREF_ITER(id, idx, ty, subs))
      equation
        id = stringAppend(id, inString);
      then
        DAE.CREF_ITER(id, idx, ty, subs);

  end match;
end appendStringLastIdent;

public function joinCrefs
"Join two component references by concatenating them.

  alternative names: crefAppend

  "
  input DAE.ComponentRef inComponentRef1 " first part of the new componentref";
  input DAE.ComponentRef inComponentRef2 " last part of the new componentref";
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef1,inComponentRef2)
    local
      DAE.Ident id;
      list<DAE.Subscript> sub;
      DAE.ComponentRef cr2,cr_1,cr;
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

public function joinCrefsR
"like joinCrefs but with last part as first argument."
  input DAE.ComponentRef inComponentRef2 " last part of the new componentref";
  input DAE.ComponentRef inComponentRef1 " first part of the new componentref";
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef2,inComponentRef1)
    local
      DAE.Ident id;
      list<DAE.Subscript> sub;
      DAE.ComponentRef cr2,cr_1,cr;
      DAE.Type t2;

    case (cr2,DAE.CREF_IDENT(ident = id, identType = t2, subscriptLst = sub))
      then
        makeCrefQual(id,t2,sub,cr2);

    case (cr2,DAE.CREF_QUAL(ident = id, identType = t2, subscriptLst = sub,componentRef = cr))
      equation
        cr_1 = joinCrefs(cr, cr2);
      then
        makeCrefQual(id,t2,sub,cr_1);
  end match;
end joinCrefsR;

public function subscriptCref
"The subscriptCref function adds a subscript to the ComponentRef
  For instance a.b with subscript 10 becomes a.b[10] and c.d[1,2]
  with subscript 3,4 becomes c.d[1,2,3,4]"
  input DAE.ComponentRef inComponentRef;
  input list<DAE.Subscript> inSubscriptLst;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef,inSubscriptLst)
    local
      list<DAE.Subscript> newsub_1,sub,newsub;
      DAE.Ident id;
      DAE.ComponentRef cref_1,cref;
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
  input DAE.ComponentRef inComponentRef;
  input Integer inSubscript;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match(inComponentRef, inSubscript)
    local
      list<DAE.Subscript> subs;
      DAE.Subscript new_sub;
      DAE.Ident id;
      DAE.ComponentRef rest_cref;
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

public function crefSetLastSubs "sets the subs of the last componenentref ident"
  input DAE.ComponentRef inComponentRef;
  input list<DAE.Subscript> inSubs;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef, inSubs)
    local
      DAE.Ident id;
      DAE.Type tp;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;

    case (DAE.CREF_IDENT(ident=id, identType=tp), _)
    then makeCrefIdent(id, tp, inSubs);

    case (DAE.CREF_QUAL(ident=id, identType=tp, subscriptLst=subs, componentRef=cr) ,_) equation
      cr = crefSetLastSubs(cr, inSubs);
    then makeCrefQual(id, tp, subs, cr);
  end match;
end crefSetLastSubs;

public function crefSetType "
sets the type of a cref."
  input DAE.ComponentRef inRef;
  input DAE.Type newType;
  output DAE.ComponentRef outRef;
algorithm
  outRef := match (inRef,newType)
    local
      DAE.Type ty;
      DAE.ComponentRef child;
      list<DAE.Subscript> subs;
      DAE.Ident id;

    case(DAE.CREF_IDENT(id,_,subs),_)
      then
        makeCrefIdent(id,newType,subs);

    case(DAE.CREF_QUAL(id,_,subs,child),_)
      then
        makeCrefQual(id,newType,subs,child);
  end match;
end crefSetType;

public function crefSetLastType "
sets the 'last' type of a cref."
  input DAE.ComponentRef inRef;
  input DAE.Type newType;
  output DAE.ComponentRef outRef;
algorithm
  outRef := match (inRef)
    local
      DAE.Type ty;
      DAE.ComponentRef child;
      list<DAE.Subscript> subs;
      DAE.Ident id;
      Integer idx;

    case DAE.CREF_IDENT(id,_,subs)
      then makeCrefIdent(id,newType,subs);

    case DAE.CREF_QUAL(id,ty,subs,child)
      equation
        child = crefSetLastType(child,newType);
      then
        makeCrefQual(id,ty,subs,child);

    case DAE.CREF_ITER(id, idx, _, subs)
      then DAE.CREF_ITER(id, idx, newType, subs);

  end match;
end crefSetLastType;

public function replaceCrefSliceSub "
Go trough ComponentRef searching for a slice eighter in
qual's or finaly ident. if none find, add dimension to DAE.CREF_IDENT(,ss:INPUTARG,)"
  input DAE.ComponentRef inCr;
  input list<DAE.Subscript> newSub;
  output DAE.ComponentRef outCr;
algorithm
  outCr := matchcontinue(inCr,newSub)
    local
      DAE.Type t2,identType;
      DAE.ComponentRef child;
      list<DAE.Subscript> subs;
      String name;

    // debugging case, uncomment for enabling
    // case(child,newSub)
    //  equation
    //    str1 = printComponentRefStr(child);
    //    str2 = stringDelimitList(List.map(newSub, printSubscriptStr), ", ");
    //    str  = "replaceCrefSliceSub(" + str1 + " subs: [" + str2 + "]\n";
    //    print(str);
    //  then
    //    fail();

    // Case where we try to find a Expression.DAE.SLICE()
    case(DAE.CREF_IDENT(name,identType,subs),_)
      equation
        subs = replaceSliceSub(subs, newSub);
      then
        makeCrefIdent(name,identType,subs);

    // case where there is not existant Expression.DAE.SLICE() as subscript
    case (DAE.CREF_IDENT(identType  = t2, subscriptLst = subs),_)
      equation
        true = (listLength(Expression.arrayTypeDimensions(t2)) >= (listLength(subs)+1));
        child = subscriptCref(inCr,newSub);
      then
        child;

    case (DAE.CREF_IDENT(identType  = t2, subscriptLst = subs),_)
      equation
        false = (listLength(Expression.arrayTypeDimensions(t2)) >= (listLength(subs)+listLength(newSub)));
        child = subscriptCref(inCr,newSub);
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("WARNING - Expression.replaceCref_SliceSub setting subscript last, not containing dimension\n");
        end if;
      then
        child;

    // Try DAE.CREF_QUAL with DAE.SLICE subscript
    case(DAE.CREF_QUAL(name,identType,subs,child),_)
      equation
        subs = replaceSliceSub(subs, newSub);
      then
        makeCrefQual(name,identType,subs,child);

    // case where there is not existant Expression.DAE.SLICE() as subscript in CREF_QUAL
    case(DAE.CREF_QUAL(name,identType,subs,child),_)
      equation
        true = (listLength(Expression.arrayTypeDimensions(identType)) >= (listLength(subs)+1));
        subs = listAppend(subs,newSub);
      then
        makeCrefQual(name,identType,subs,child);

    // DAE.CREF_QUAL without DAE.SLICE, search child
    case(DAE.CREF_QUAL(name,identType,subs,child),_)
      equation
        child = replaceCrefSliceSub(child,newSub);
      then
        makeCrefQual(name,identType,subs,child);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Expression.replaceCref_SliceSub failed\n");
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

    case((DAE.SLICE(_))::subs,_)
      equation
        subs = listAppend(inSub,subs);
      then
        subs;

    // adrpo, 2010-02-23:
    //   WHOLEDIM is *also* a special case of SLICE
    //   that contains the all subscripts, so we need
    //   to handle that too here!
    case((DAE.WHOLEDIM())::subs,_)
      equation
        subs = listAppend(inSub,subs);
      then
        subs;

    case((sub)::subs,_)
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
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref)
    local
      DAE.Ident id;
      DAE.ComponentRef cr;
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
  end match;
end stripCrefIdentSliceSubs;

public function stripArrayCref"strips the cref at the array-cref. remove subscripts, outputs appended crefs"
  input DAE.ComponentRef crefIn;
  output DAE.ComponentRef crefHead;
  output Integer idxOut;
  output Option<DAE.ComponentRef> crefTail;
algorithm
  (crefHead, idxOut, crefTail) := match(crefIn)
    local
      Integer idx;
      DAE.Ident id;
      DAE.ComponentRef cr, outCref;
      DAE.Type ty;
      list<DAE.Subscript> subs;
    case (DAE.CREF_IDENT(ident = id,subscriptLst={DAE.INDEX(DAE.ICONST(idx))}, identType = ty))
      equation
        // the complete cref is an array
      then
        (makeCrefIdent(id,ty,{}),idx,NONE());

    case (DAE.CREF_QUAL(componentRef = cr, identType=ty, subscriptLst={DAE.INDEX(DAE.ICONST(idx))}, ident=id))
      equation
        // strip the cref here
      then
        (makeCrefIdent(id,ty,{}),idx,SOME(cr));

    case (DAE.CREF_QUAL(componentRef = cr, identType=ty, subscriptLst=subs, ident=id))
      equation
        // continue
        outCref = stripCrefIdentSliceSubs(cr);
      then
        (makeCrefQual(id,ty,{},outCref),-1,NONE());
  end match;
end stripArrayCref;

protected function removeSliceSubs "
helper function for stripCrefIdentSliceSubs"
  input list<DAE.Subscript> subs;
  output list<DAE.Subscript> osubs = {};
algorithm
  for s in subs loop
    osubs := match s
      case DAE.SLICE() then osubs;
      else s::osubs;
    end match;
  end for;
  osubs := MetaModelica.Dangerous.listReverseInPlace(osubs);
end removeSliceSubs;

public function crefStripSubs "
Removes all subscript of a componentref"
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref)
    local
      DAE.Ident id;
      DAE.ComponentRef cr;
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
  input DAE.ComponentRef cref;
  input DAE.ComponentRef prefix;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(cref,prefix)
    local
      list<DAE.Subscript> subs1,subs2;
      DAE.ComponentRef cr1,cr2;
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
  input DAE.ComponentRef inCr;
  output DAE.ComponentRef outCr;
algorithm
  outCr := matchcontinue(inCr)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr1,cr;
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
"Strips the last subscripts of a ComponentRef"
  input DAE.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef)
    local
      DAE.Ident id;
      list<DAE.Subscript> subs,s;
      DAE.ComponentRef cr_1,cr;
      DAE.Type t2;

    case (DAE.CREF_IDENT(ident = id,identType = t2))
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
  input DAE.ComponentRef inCr;
  output DAE.ComponentRef outCr;
algorithm
  outCr := match(inCr)
    local
      DAE.ComponentRef cr;
    case( DAE.CREF_QUAL(componentRef = cr)) then cr;
  end match;
end crefStripFirstIdent;

public function crefStripLastSubsStringified
"author: PA
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
"Translates a ComponentRef into a DAE.CREF_IDENT by putting
  the string representation of the ComponentRef into it.
  See also stringigyCrefs.

  NOTE: This function should not be used in OMC, since the OMC backend no longer
    uses stringified components. It is still used by MathCore though."
  input DAE.ComponentRef cr;
  output DAE.ComponentRef outComponentRef;
protected
  list<DAE.Subscript> subs;
  DAE.ComponentRef cr_1;
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
"Print a ComponentRef."
  input DAE.ComponentRef inComponentRef;
algorithm
  _ := match (inComponentRef)
    local
      DAE.Ident s;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;
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
        if (Config.modelicaOutput())
        then
          printComponentRef2(s, subs);
          Print.printBuf("__");
          printComponentRef(cr);
        else
          printComponentRef2(s, subs);
          Print.printBuf(".");
          printComponentRef(cr);
        end if;
      then
        ();
  end match;
end printComponentRef;

protected function printComponentRef2
"Helper function to printComponentRef"
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
        if (Config.modelicaOutput())
        then
          Print.printBuf(s);
          Print.printBuf("_L");
          ExpressionDump.printList(l, ExpressionDump.printSubscript, ",");
          Print.printBuf("_R");
        else
          Print.printBuf(s);
          Print.printBuf("[");
          ExpressionDump.printList(l, ExpressionDump.printSubscript, ",");
          Print.printBuf("]");
        end if;
      then
        ();

  end matchcontinue;
end printComponentRef2;

public function printComponentRefListStr
  input list<DAE.ComponentRef> crs;
  output String res;
algorithm
  res := "{" + stringDelimitList(List.map(crs, printComponentRefStr), ",") + "}";
end printComponentRefListStr;

public function printComponentRefList
  input list<DAE.ComponentRef> crs;
protected
  String buffer;
algorithm
  buffer := "{" + stringDelimitList(List.map(crs, printComponentRefStr), ", ") + "}\n";
  print(buffer);
end printComponentRefList;

public function replaceWholeDimSubscript
  input DAE.ComponentRef icr;
  input Integer index;
  output DAE.ComponentRef ocr;
algorithm
  ocr := matchcontinue (icr,index)
    local
      String id;
      DAE.Type et;
      list<DAE.Subscript> ss;
      DAE.ComponentRef cr;

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
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outPrefixCref;
  output DAE.ComponentRef outLastCref;
algorithm
  (outPrefixCref, outLastCref) := match(inCref)
    local
      DAE.Ident id;
      DAE.Type ty;
      list<DAE.Subscript> subs;
      DAE.ComponentRef prefix, last;

    case DAE.CREF_QUAL(id, ty, subs, last as DAE.CREF_IDENT())
      then (DAE.CREF_IDENT(id, ty, subs), last);

    case DAE.CREF_QUAL(id, ty, subs, last)
      equation
        (prefix, last) = splitCrefLast(last);
      then
        (DAE.CREF_QUAL(id, ty, subs, prefix), last);

  end match;
end splitCrefLast;

public function firstNCrefs
  "Gets the first a cref at the n-th cref, e.g. (a.b.c.d,2) => a.b."
  input DAE.ComponentRef inCref;
  input Integer nIn;
  output DAE.ComponentRef outFirstCrefs;

algorithm
  (outFirstCrefs) := matchcontinue(inCref,nIn)
    local
      DAE.Ident id;
      DAE.Type ty;
      list<DAE.Subscript> subs;
      DAE.ComponentRef prefix, last;
    case(_,0)
      then (inCref);

    case(DAE.CREF_QUAL(id, ty, subs, last),1)
      then DAE.CREF_IDENT(id, ty, subs);

    case(DAE.CREF_IDENT(id, ty, subs),_)
      then inCref;

    case (DAE.CREF_QUAL(id, ty, subs, last),)
      equation
        prefix = firstNCrefs(last,nIn-1);
      then
        DAE.CREF_QUAL(id, ty, subs, prefix);

      else
        then (inCref);

  end matchcontinue;
end firstNCrefs;

public function splitCrefFirst
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCrefFirst;
  output DAE.ComponentRef outCrefRest;
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
  input DAE.ComponentRef inCref;
  output list<String> outStringList;
algorithm
  outStringList := toStringList_tail(inCref, {});
end toStringList;

protected function toStringList_tail
  "Tail-recursive implementation of toStringList."
  input DAE.ComponentRef inCref;
  input list<String> inAccumStrings;
  output list<String> outStringList;
algorithm
  outStringList := match(inCref, inAccumStrings)
    local
      String id;
      DAE.ComponentRef cref;

    case (DAE.CREF_QUAL(ident = id, componentRef = cref), _)
      then toStringList_tail(cref, id :: inAccumStrings);

    case (DAE.CREF_IDENT(ident = id), _)
      then listReverse(id :: inAccumStrings);

    else {};

  end match;
end toStringList_tail;

public function crefDepth
  input DAE.ComponentRef inCref;
  output Integer depth;
algorithm
  depth :=
  match (inCref)
    local
      DAE.ComponentRef n;

    case (DAE.WILD()) then 0;
    case (DAE.CREF_IDENT()) then 1;
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
    case (DAE.CREF_IDENT(),_) then 1+iDepth;
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
  input DAE.ComponentRef inCref;
  input Boolean expandRecord;
  output list<DAE.ComponentRef> outCref;
algorithm
  outCref := matchcontinue(inCref,expandRecord)
    case (_,_) then expandCref_impl(inCref,expandRecord);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- ComponentReference.expandCref failed on " +
          printComponentRefStr(inCref));
      then
        fail();

  end matchcontinue;
end expandCref;

public function expandCref_impl
  input DAE.ComponentRef inCref;
  input Boolean expandRecord;
  output list<DAE.ComponentRef> outCref;
algorithm
  outCref := matchcontinue(inCref,expandRecord)
    local
      DAE.Ident id;
      DAE.Type ty, basety,correctTy;
      DAE.TypeSource source;
      list<DAE.Dimension> dims;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> crefs, crefs2;
      list<DAE.Var> varLst;

    // A scalar record ident cref. Expand record true
    case (DAE.CREF_IDENT(_, DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_)), {}),true)
      equation
        // Create a list of crefs from names
        crefs =  List.map(varLst,creffromVar);
        crefs = List.map1r(crefs,joinCrefs,inCref);
      then
        List.map1Flat(crefs,expandCref_impl,true);

    // A array record ident cref without subscripts. Expand record true
    case (DAE.CREF_IDENT(id, ty as DAE.T_ARRAY(source=source), {}),true)
      equation
        // Flatten T_ARRAY(T_ARRAY(T_COMPLEX(), dim2,src), dim1,src) types to one level T_ARRAY(simpletype, alldims, src)
        (basety as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_)), dims) = Types.flattenArrayType(ty);
        correctTy = DAE.T_ARRAY(basety,dims,source);
        // Create a list of : subscripts to generate all elements.
        subs = List.fill(DAE.WHOLEDIM(), listLength(dims));
        crefs = expandCref2(id, correctTy, subs, dims);
      then
        expandCrefLst(crefs,varLst,{});

    // A array type cref (possibly record but no expansion of records) without subscripts.
    case (DAE.CREF_IDENT(id, ty as DAE.T_ARRAY(source=source), {}),_)
      equation
        // Flatten T_ARRAY(T_ARRAY(T_..., dim2,src), dim1,src) types to one level T_ARRAY(simpletype, alldims, src)
        (basety, dims) = Types.flattenArrayType(ty);
        correctTy = DAE.T_ARRAY(basety,dims,source);
        // Create a list of : subscripts to generate all elements.
        subs = List.fill(DAE.WHOLEDIM(), listLength(dims));
      then
        expandCref2(id, correctTy, subs, dims);

    // A array complex cref with subscripts. Expand record true
    case (DAE.CREF_IDENT(id, ty as DAE.T_ARRAY(source=source), subs),true)
      equation
        // Flatten T_ARRAY(T_ARRAY(T_COMPLEX(), dim2,src), dim1,src) types to one level T_ARRAY(simpletype, alldims, src)
        (basety as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_)), dims) = Types.flattenArrayType(ty);
        correctTy = DAE.T_ARRAY(basety,dims,source);
        // Use the subscripts to generate only the wanted elements.
         crefs = expandCref2(id, correctTy, subs, dims);
      then
        expandCrefLst(crefs,varLst,{});

    // A array type cref (possibly record but no expansion of records) with subscripts.
    case (DAE.CREF_IDENT(id, ty as DAE.T_ARRAY(source=source), subs),_)
      equation
        // Flatten T_ARRAY(T_ARRAY(T_..., dim2,src), dim1,src) types to one level T_ARRAY(simpletype, alldims, src)
        (basety, dims) = Types.flattenArrayType(ty);
        correctTy = DAE.T_ARRAY(basety,dims,source);
        // Use the subscripts to generate only the wanted elements.
      then
        expandCref2(id, correctTy, subs, dims);


    // A qualified cref with array type.
    case (DAE.CREF_QUAL(id, ty as DAE.T_ARRAY(source=source), subs, cref),_)
      equation
        // Expand the rest of the cref.
        crefs = expandCref_impl(cref,expandRecord);
        // Flatten T_ARRAY(T_ARRAY(T_..., dim2,src), dim1,src) types to one level T_ARRAY(simpletype, alldims, src)
        (basety, dims) = Types.flattenArrayType(ty);
        correctTy = DAE.T_ARRAY(basety,dims,source);
        // Create a simple identifier for the head of the cref and expand it.
        cref = DAE.CREF_IDENT(id, correctTy, subs);
        crefs2 = expandCref_impl(cref,false);
        crefs2 = listReverse(crefs2);
        // crefs2 = List.map1(crefs2,crefSetType,correctTy);
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

  end matchcontinue;
end expandCref_impl;

protected function expandCrefLst
  input list<DAE.ComponentRef> inCrefs;
  input list<DAE.Var> varLst;
  input list<list<DAE.ComponentRef>> inCrefsAcc;
  output list<DAE.ComponentRef> outCref;
algorithm
  outCref := match(inCrefs,varLst,inCrefsAcc)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs,rest;
    case ({},_,_) then List.flatten(inCrefsAcc);
    case (cr::rest,_,_)
      equation
        // Create a list of crefs from names
        crefs = List.map(varLst,creffromVar);
        crefs = List.map1r(crefs,joinCrefs,cr);
      then
        expandCrefLst(rest,varLst,crefs::inCrefsAcc);
  end match;
end expandCrefLst;


protected function expandCrefQual
  "Helper function to expandCref_impl. Constructs all combinations of the head
   and rest cref lists. E.g.:
    expandCrefQual({x, y}, {a, b}) => {x.a, x.b, y.a, y.b} "
  input list<DAE.ComponentRef> inHeadCrefs;
  input list<DAE.ComponentRef> inRestCrefs;
  input list<DAE.ComponentRef> inAccumCrefs;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  outCrefs := match(inHeadCrefs, inRestCrefs, inAccumCrefs)
    local
      list<DAE.ComponentRef> crefs, rest_crefs;
      DAE.ComponentRef cref;

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
  output list<DAE.ComponentRef> outCrefs = {};
protected
  list<list<DAE.Subscript>> subslst;
algorithm
  // Expand each subscript into a list of subscripts.
  subslst := List.threadMap(inSubscripts, inDimensions, Expression.expandSubscript);

  subslst := List.combination(subslst);
  for subs in subslst loop
    outCrefs := makeCrefIdent(inId,inType,subs)::outCrefs;
  end for;
  outCrefs := listReverse(outCrefs);
end expandCref2;

public function replaceSubsWithString
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref)
    local
      DAE.Ident ident,ident1;
      DAE.Type identType;
      list<DAE.Subscript> subscriptLst;
      DAE.ComponentRef cr,cr1;
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
    case DAE.CREF_ITER()
      then
        inCref;
    case DAE.WILD()
      then
        inCref;
  end match;
end replaceSubsWithString;

public function replaceLast
  "Replaces the last part of a cref with a new cref."
  input DAE.ComponentRef inCref;
  input DAE.ComponentRef inNewLast;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inNewLast)
    local
      DAE.Ident ident;
      DAE.Type ty;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cref;

    case (DAE.CREF_QUAL(ident, ty, subs, cref), _)
      equation
        cref = replaceLast(cref, inNewLast);
      then
        DAE.CREF_QUAL(ident, ty, subs, cref);

    case (DAE.CREF_IDENT(), _) then inNewLast;

  end match;
end replaceLast;

public function expandArrayCref
"deprecated. use expandArray"
  input DAE.ComponentRef inCr;
  input list<DAE.Dimension> inDims;
  output list<DAE.ComponentRef> outCrefs;
protected
  DAE.Type lasttype;
  DAE.ComponentRef tmpcref;
algorithm
  lasttype := crefLastType(inCr);
  lasttype := Types.liftTypeWithDims(lasttype, inDims);
  tmpcref := crefSetLastType(inCr, lasttype);
  outCrefs := expandCref(tmpcref, false);
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
  outCref := implode_reverse(listReverse(inParts));
end implode;

public function implode_reverse
  "Constructs a cref from a reversed list of CREF_IDENTs."
  input list<DAE.ComponentRef> inParts;
  output DAE.ComponentRef outCref;
protected
  DAE.ComponentRef first;
  list<DAE.ComponentRef> rest;
algorithm
  first :: rest := inParts;
  outCref := implode_tail(rest, first);
end implode_reverse;

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

public function identifierCount
  input DAE.ComponentRef inCref;
  output Integer outIdCount;
algorithm
  outIdCount := identifierCount_tail(inCref, 0);
end identifierCount;

protected function identifierCount_tail
  input DAE.ComponentRef inCref;
  input Integer inAccumCount;
  output Integer outIdCount;
algorithm
  outIdCount := match(inCref, inAccumCount)
    local
      DAE.ComponentRef cr;

    case (DAE.CREF_QUAL(componentRef = cr), _)
      then identifierCount_tail(cr, inAccumCount + 1);

    else inAccumCount + 1;
  end match;
end identifierCount_tail;

public function checkCrefSubscriptsBounds
  "Checks that the subscripts in a cref are valid given the dimensions of the
   cref's type. Prints an error if they are not."
  input DAE.ComponentRef inCref;
  input SourceInfo inInfo;
algorithm
  checkCrefSubscriptsBounds2(inCref, inCref, inInfo);
end checkCrefSubscriptsBounds;

protected function checkCrefSubscriptsBounds2
  input DAE.ComponentRef inCref;
  input DAE.ComponentRef inWholeCref;
  input SourceInfo inInfo;
algorithm
  _ := match(inCref, inWholeCref, inInfo)
    local
      DAE.Type ty;
      list<DAE.Subscript> subs;
      list<DAE.Dimension> dims;
      DAE.ComponentRef rest_cr;

    case (DAE.CREF_QUAL(identType = ty, subscriptLst = subs, componentRef = rest_cr), _, _)
      equation
        checkCrefSubscriptsBounds3(ty, subs, inWholeCref, inInfo);
        checkCrefSubscriptsBounds2(rest_cr, inWholeCref, inInfo);
      then
        ();

    case (DAE.CREF_IDENT(identType = ty, subscriptLst = subs), _, _)
      equation
        checkCrefSubscriptsBounds3(ty, subs, inWholeCref, inInfo);
      then
        ();

    case (DAE.CREF_ITER(identType = ty, subscriptLst = subs), _, _)
      equation
        checkCrefSubscriptsBounds3(ty, subs, inWholeCref, inInfo);
      then
        ();

  end match;
end checkCrefSubscriptsBounds2;

protected function checkCrefSubscriptsBounds3
  input DAE.Type inCrefType;
  input list<DAE.Subscript> inSubscripts;
  input DAE.ComponentRef inWholeCref;
  input SourceInfo inInfo;
protected
  list<DAE.Dimension> dims;
  list<DAE.Subscript> subs;
algorithm
  dims := Types.getDimensions(inCrefType);
  // The type might contain dimensions from the cref part's prefix here, so
  // reverse the lists and check them from the back to pair up each subscript
  // with the correct dimension.
  dims := listReverse(dims);
  subs := listReverse(inSubscripts);
  checkCrefSubscriptsBounds4(subs, dims, 1, inWholeCref, inInfo);
end checkCrefSubscriptsBounds3;

protected function checkCrefSubscriptsBounds4
  input list<DAE.Subscript> inSubscripts;
  input list<DAE.Dimension> inDimensions;
  input Integer inIndex;
  input DAE.ComponentRef inWholeCref;
  input SourceInfo inInfo;
algorithm
  _ := match(inSubscripts, inDimensions, inIndex, inWholeCref, inInfo)
    local
      DAE.Subscript sub;
      list<DAE.Subscript> rest_subs;
      DAE.Dimension dim;
      list<DAE.Dimension> rest_dims;

    case (sub :: rest_subs, dim :: rest_dims, _, _, _)
      equation
        true = checkCrefSubscriptBounds(sub, dim, inIndex, inWholeCref, inInfo);
        checkCrefSubscriptsBounds4(rest_subs, rest_dims, inIndex + 1, inWholeCref, inInfo);
      then
        ();

    case ({}, _, _, _, _) then ();

    // Cref types are sometimes messed up, and we might get a cref with
    // subscripts but no dimensions here. That's usually fine, since the
    // subscripts in those cases are generated by the compiler.
    case (_, {}, _, _, _) then ();
  end match;
end checkCrefSubscriptsBounds4;

protected function checkCrefSubscriptBounds
  input DAE.Subscript inSubscript;
  input DAE.Dimension inDimension;
  input Integer inIndex;
  input DAE.ComponentRef inWholeCref;
  input SourceInfo inInfo;
  output Boolean outIsValid;
algorithm
  outIsValid := matchcontinue(inSubscript, inDimension, inIndex, inWholeCref, inInfo)
    local
      Integer idx, idx2, dim;
      list<DAE.Exp> expl;
      DAE.Exp exp;

    /*/ allow index 0 with dimension 0
    case (DAE.INDEX(exp = exp as DAE.ICONST(integer = idx)),
          DAE.DIM_INTEGER(integer = dim), _, _, _)
      equation
        true = idx == 0 and dim == 0;
      then
        true;*/

    case (DAE.INDEX(exp = exp as DAE.ICONST(integer = idx)),
          DAE.DIM_INTEGER(integer = dim), _, _, _)
      equation
        false = idx > 0 and idx <= dim;
        printSubscriptBoundsError(exp, inDimension, inIndex, inWholeCref, inInfo);
      then
        false;

    case (DAE.SLICE(exp = DAE.ARRAY(array = expl)),
          DAE.DIM_INTEGER(integer = dim), _, _, _)
      equation
        exp = List.getMemberOnTrue(dim, expl, subscriptExpOutOfBounds);
        printSubscriptBoundsError(exp, inDimension, inIndex, inWholeCref, inInfo);
      then
        false;

    else true;
  end matchcontinue;
end checkCrefSubscriptBounds;

protected function subscriptExpOutOfBounds
  input Integer inDimSize;
  input DAE.Exp inSubscriptExp;
  output Boolean outOutOfBounds;
algorithm
  outOutOfBounds := match(inDimSize, inSubscriptExp)
    local
      Integer i;

    case (_, DAE.ICONST(integer = i)) then i < 1 or i > inDimSize;
    else false;
  end match;
end subscriptExpOutOfBounds;

protected function printSubscriptBoundsError
  input DAE.Exp inSubscriptExp;
  input DAE.Dimension inDimension;
  input Integer inIndex;
  input DAE.ComponentRef inCref;
  input SourceInfo inInfo;
protected
  String sub_str, dim_str, idx_str, cref_str;
algorithm
  sub_str := ExpressionDump.printExpStr(inSubscriptExp);
  dim_str := ExpressionDump.dimensionString(inDimension);
  idx_str := intString(inIndex);
  cref_str := printComponentRefStr(inCref);
  Error.addSourceMessage(Error.ARRAY_INDEX_OUT_OF_BOUNDS,
    {sub_str, idx_str, dim_str, cref_str}, inInfo);
end printSubscriptBoundsError;

public function crefAppendedSubs
  input DAE.ComponentRef cref;
  output String s;
protected
  String s1,s2;
algorithm
  s1 := crefToStr("",cref,"_P");
  s2 := stringDelimitList(List.map(List.map(crefSubs(cref),Expression.getSubscriptExp),ExpressionDump.printExpStr),",");
  s := s1+"["+s2+"]";
end  crefAppendedSubs;

annotation(__OpenModelica_Interface="frontend");
end ComponentReference;

