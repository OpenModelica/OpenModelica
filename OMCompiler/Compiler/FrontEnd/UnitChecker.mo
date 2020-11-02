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

encapsulated package UnitChecker
"
  file:         UnitChecker.mo
  package:     UnitChecker
  description: Physical unit checking.

  This package is used for checking if an equation system is consistent, inconsistent or unknown (not enough information to determine).
"

public import UnitAbsyn;
public import MMath;
public import UnitAbsynBuilder;

protected import Debug;
protected import Error;
protected import Flags;
protected import HashTable;

public function check "Check if a list of unit terms are consistent"
  input UnitAbsyn.UnitTerms tms;
  input UnitAbsyn.InstStore ist;
  output UnitAbsyn.InstStore outSt;
algorithm
  (outSt) := matchcontinue(tms,ist)
    local
      UnitAbsyn.Store st1,st2;
      UnitAbsyn.UnitTerms rest1;
      UnitAbsyn.UnitTerm tm1;
      Option<UnitAbsyn.UnitCheckResult> res;
      UnitAbsyn.SpecUnit su1,su2;
      String s1,s2,s3;
      HashTable.HashTable ht;
      UnitAbsyn.InstStore st;

    case (_,st)
      equation
        // phi: very old unit checking
        /*
        false = Flags.getConfigBool(Flags.UNIT_CHECKING);
        */
      then (st);

    // No more terms?
    case ({},UnitAbsyn.INSTSTORE(st1,ht,_))
      then UnitAbsyn.INSTSTORE(st1,ht,SOME(UnitAbsyn.CONSISTENT()));

    // Is consistent?
    case (tm1::rest1,UnitAbsyn.INSTSTORE(st1,ht,_))
      equation
        (UnitAbsyn.CONSISTENT(),_,st2) = checkTerm(tm1,st1);
        (st) = check(rest1,UnitAbsyn.INSTSTORE(st2,ht,SOME(UnitAbsyn.CONSISTENT())));
      then(st);

     // Is inconsistent?
     case (tm1::_,UnitAbsyn.INSTSTORE(st1,ht,_))
       equation
         (UnitAbsyn.INCONSISTENT(su1,su2),_,_) = checkTerm(tm1,st1);
         s1 = UnitAbsynBuilder.printTermsStr({tm1});
         s2 = UnitAbsynBuilder.unit2str(UnitAbsyn.SPECIFIED(su1));
         s3 = UnitAbsynBuilder.unit2str(UnitAbsyn.SPECIFIED(su2));
         Error.addMessage(Error.INCONSISTENT_UNITS,{s1,s2,s3});
       then
         UnitAbsyn.INSTSTORE(st1,ht,SOME(UnitAbsyn.INCONSISTENT(su1,su2)));

     // failtrace
     else
       equation
         true = Flags.isSet(Flags.FAILTRACE);
         Debug.trace("UnitChecker::check() failed\n");
         print("check failed\n");
       then
         fail();
   end matchcontinue;
end check;

public function isComplete "returns true if the store is complete, else false"
  input UnitAbsyn.Store st;
  output Boolean complete;
  output UnitAbsyn.Store stout;
algorithm
  (complete,stout) := match(st)
    local
      array<Option<UnitAbsyn.Unit>> vector; Integer indx;
      list<Option<UnitAbsyn.Unit>> lst;
      Boolean comp;
      UnitAbsyn.Store st2;

    case (UnitAbsyn.STORE(vector,indx))
      equation
        lst = arrayList(vector);
        (comp,st2) = completeCheck(lst,1,UnitAbsyn.STORE(vector,indx));
      then
        (comp,st2);
  end match;
end isComplete;

protected function completeCheck "help function to isComplete"
  input list<Option<UnitAbsyn.Unit>> ilst;
  input Integer indx;
  input UnitAbsyn.Store st;
  output Boolean isComplete;
  output UnitAbsyn.Store stout;
algorithm
  (isComplete,stout) := matchcontinue(ilst,indx,st)
    local
      UnitAbsyn.Unit u1,u2;
      Boolean comp1;
      UnitAbsyn.Store st2,st3,st4;
      list<Option<UnitAbsyn.Unit>> lst;

    case ({},_,st2) then (true,st2);

    case (SOME(_)::lst,_,st2)
      equation
        (u2,st3) = normalize(indx,st2);
        false = unitHasUnknown(u2);
        (comp1,_) = completeCheck(lst,indx+1,st3);
      then
        (comp1,st3);

    case (SOME(_)::_,_,st2)
      equation
        (u2,_) = normalize(indx,st2);
        true = unitHasUnknown(u2);
      then
        (false,st2);

    case(NONE()::_,_,st2) then (true,st2);
  end matchcontinue;
end completeCheck;

public function checkTerm "check if one term is ok"
  input UnitAbsyn.UnitTerm tm;
  input UnitAbsyn.Store st;
  output UnitAbsyn.UnitCheckResult result;
  output UnitAbsyn.SpecUnit outUnit;
  output UnitAbsyn.Store outSt;
algorithm
   (result,outUnit,outSt) := matchcontinue(tm,st)
     local
       UnitAbsyn.Store st1,st2,st3,st4;
       UnitAbsyn.UnitCheckResult res1,res2,res3,res4;
       UnitAbsyn.UnitTerm ut1,ut2;
       UnitAbsyn.SpecUnit su1,su2,su3;
       MMath.Rational expo1;
       Integer loc;

     case (UnitAbsyn.ADD(ut1,ut2,_),st1)
       equation
         (res1,su1,st2) = checkTerm(ut1,st1);
         (res2,su2,st3) = checkTerm(ut2,st2);
         (res3,st4) = unify(su1,su2,st3);
         res4 = chooseResult(res1,res2,res3);
       then (res4,su1,st4);

     case (UnitAbsyn.SUB(ut1,ut2,_),st1)
       equation
         (res1,su1,st2) = checkTerm(ut1,st1);
         (res2,su2,st3) = checkTerm(ut2,st2);
         (res3,st4) = unify(su1,su2,st3);
         res4 = chooseResult(res1,res2,res3);
       then (res4,su1,st4);

     case (UnitAbsyn.MUL(ut1,ut2,_),st1)
       equation
         (res1,su1,st2) = checkTerm(ut1,st1);
         (res2,su2,st3) = checkTerm(ut2,st2);
         su3 = mulSpecUnit(su1,su2);
         res4 = chooseResult(res1,res2,UnitAbsyn.CONSISTENT());
       then(res4,su3,st3);

     case (UnitAbsyn.DIV(ut1,ut2,_),st1)
       equation
         (res1,su1,st2) = checkTerm(ut1,st1);
         (res2,su2,st3) = checkTerm(ut2,st2);
         su3 = divSpecUnit(su1,su2);
         res4 = chooseResult(res1,res2,UnitAbsyn.CONSISTENT());
       then(res4,su3,st3);

     case (UnitAbsyn.EQN(ut1,ut2,_),st1)
       equation
         (res1,su1,st2) = checkTerm(ut1,st1);
         (res2,su2,st3) = checkTerm(ut2,st2);
         (res3,st4) = unify(su1,su2,st3);
         res4 = chooseResult(res1,res2,res3);
       then(res4,su1,st4);

     case (UnitAbsyn.LOC(loc,_),st1)
       equation
         (UnitAbsyn.UNSPECIFIED()) = UnitAbsynBuilder.find(loc,st1);
       then(UnitAbsyn.CONSISTENT(),UnitAbsyn.SPECUNIT((MMath.RATIONAL(1,1),UnitAbsyn.TYPEPARAMETER("",loc))::{},{}),st1);

     case (UnitAbsyn.LOC(loc,_),st1)
       equation
         (UnitAbsyn.SPECIFIED(su1)) = UnitAbsynBuilder.find(loc,st1);
       then(UnitAbsyn.CONSISTENT(),su1,st1);

     case (UnitAbsyn.POW(ut1,expo1,_),st1)
       equation
         (res1,su1,st2) = checkTerm(ut1,st1);
         su2 = powSpecUnit(su1,expo1);
       then(res1,su2,st2);

     else
       equation
         true = Flags.isSet(Flags.FAILTRACE);
         Debug.trace("UnitChecker::checkTerm() failed\n");
       then fail();
   end matchcontinue;
end checkTerm;

protected function chooseResult "Returns the first result that is UnitAbsyn.INCONSISTENT. If not, CONISTENT will be returned"
  input UnitAbsyn.UnitCheckResult res1;
  input UnitAbsyn.UnitCheckResult res2;
  input UnitAbsyn.UnitCheckResult res3;
  output UnitAbsyn.UnitCheckResult resout;
protected
  UnitAbsyn.UnitCheckResult incon;
algorithm
  resout := match(res1,res2,res3)
    case(UnitAbsyn.CONSISTENT(),UnitAbsyn.CONSISTENT(),UnitAbsyn.CONSISTENT()) then UnitAbsyn.CONSISTENT();
    case(UnitAbsyn.CONSISTENT(),UnitAbsyn.CONSISTENT(),incon) then incon;
    case(UnitAbsyn.CONSISTENT(),incon,_) then incon;
    case(incon,_,_) then incon;
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::chooseResult() failed\n");
      then fail();
  end match;
end chooseResult;

protected function unify
  input UnitAbsyn.SpecUnit insu1;
  input UnitAbsyn.SpecUnit insu2;
  input UnitAbsyn.Store st;
  output UnitAbsyn.UnitCheckResult outresult;
  output UnitAbsyn.Store outSt;
protected
  UnitAbsyn.SpecUnit su1,su2;
  UnitAbsyn.Store st1,st2;
algorithm
  (UnitAbsyn.SPECIFIED(su1),st1) := normalizeOnUnit(UnitAbsyn.SPECIFIED(insu1),st);
  (UnitAbsyn.SPECIFIED(su2),st2) := normalizeOnUnit(UnitAbsyn.SPECIFIED(insu2),st1);
  (outresult,outSt) := unifyunits(su1,su2,st2);
end unify;

protected function isSpecUnitEq "checks if twp spec units are equal (presupposed that they have no unknowns"
  input UnitAbsyn.SpecUnit insu1;
  input UnitAbsyn.SpecUnit insu2;
  output Boolean res;
algorithm
  res := matchcontinue(insu1,insu2)
    local
      Boolean r1;
      Integer i1a,i1b,i2a,i2b;
      list<MMath.Rational> rest1,rest2;

    case(UnitAbsyn.SPECUNIT(_,{}),UnitAbsyn.SPECUNIT(_,{}))
      then true;

    case(UnitAbsyn.SPECUNIT(_,{}),UnitAbsyn.SPECUNIT(_,MMath.RATIONAL(0,_)::rest1))
      equation
        r1 = isSpecUnitEq(UnitAbsyn.SPECUNIT({},{}), UnitAbsyn.SPECUNIT({},rest1));
      then r1;

    case(UnitAbsyn.SPECUNIT(_,MMath.RATIONAL(0,_)::rest1),UnitAbsyn.SPECUNIT(_,{}))
      equation
        r1 = isSpecUnitEq(UnitAbsyn.SPECUNIT({},rest1),UnitAbsyn.SPECUNIT({},{}));
      then r1;

    case(UnitAbsyn.SPECUNIT(_,MMath.RATIONAL(i1a,i1b)::rest1), UnitAbsyn.SPECUNIT(_,MMath.RATIONAL(i2a,i2b)::rest2))
      equation
        true = intEq(i1a, i2a);
        true = intEq(i1b, i2b);
        r1 = isSpecUnitEq(UnitAbsyn.SPECUNIT({},rest1),UnitAbsyn.SPECUNIT({},rest2));
      then r1;

    else
      then false;
  end matchcontinue;
end isSpecUnitEq;

protected function unifyunits
  input UnitAbsyn.SpecUnit insu1;
  input UnitAbsyn.SpecUnit insu2;
  input UnitAbsyn.Store st;
  output UnitAbsyn.UnitCheckResult outresult;
  output UnitAbsyn.Store outSt;
algorithm
  (outresult,outSt) := matchcontinue(insu1,insu2,st)
    local
      UnitAbsyn.SpecUnit su1,su2,su3,su4;
      UnitAbsyn.Store st1,st2;
      Integer loc1;

    // No unknown and the same on both sides
    case(su1,su2,st1)
      equation
        false = hasUnknown(su1);
        false = hasUnknown(su2);
        true = isSpecUnitEq(su1,su2);
      then
        (UnitAbsyn.CONSISTENT(),st1);

    // No unknown, but different on the sides
    case(su1,su2,st1)
      equation
        false = hasUnknown(su1);
        false = hasUnknown(su2);
      then
        (UnitAbsyn.INCONSISTENT(su1,su2),st1);

    // Move the unknown to left side and substitute
    case(su1,su2,st1)
      equation
        su3 = divSpecUnit(su2,su1);
        (loc1,su4) = getUnknown(su3);
        st2 = UnitAbsynBuilder.update(UnitAbsyn.SPECIFIED(su4),loc1,st1);
      then
        (UnitAbsyn.CONSISTENT(),st2);

    // Unknowns are cancelling each other out
    case(_,_,st1)
      then(UnitAbsyn.CONSISTENT(),st1);
  end matchcontinue;
end unifyunits;

public function newDimlessSpecUnit "creates a new dimensionless unit"
  output UnitAbsyn.SpecUnit su;
algorithm
  UnitAbsyn.SPECIFIED(su) := UnitAbsynBuilder.str2unit("1",NONE());
end newDimlessSpecUnit;

public function getUnknown "gets the first unknown in a specified unit"
  input UnitAbsyn.SpecUnit suin;
  output Integer loc;
  output UnitAbsyn.SpecUnit suout;
algorithm
  (loc,suout) := matchcontinue(suin)
    local
      UnitAbsyn.SpecUnit su1,su2;
      MMath.Rational expo1,expo2;
      Integer loc1;
      String name;
      list<MMath.Rational> unitvec1;
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> rest1;

    case(UnitAbsyn.SPECUNIT((expo1,UnitAbsyn.TYPEPARAMETER(_,loc1))::rest1,unitvec1))
      equation
        su1 = divSpecUnit(newDimlessSpecUnit(),UnitAbsyn.SPECUNIT(rest1,unitvec1));
        expo2 = MMath.divRational(MMath.RATIONAL(1,1), expo1);
        su2 = powSpecUnit(su1,expo2);
      then (loc1,su2);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::getUnknown() failed\n");
      then
        fail();
  end matchcontinue;
end getUnknown;

public function hasUnknown
  input UnitAbsyn.SpecUnit su;
  output Boolean res;
algorithm
  res := matchcontinue(su)
    case(UnitAbsyn.SPECUNIT({},_)) then false;
    case(UnitAbsyn.SPECUNIT(_,_)) then true;
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::hasUnknown() failed\n");
      then fail();
  end matchcontinue;
end hasUnknown;

public function unitHasUnknown
  input UnitAbsyn.Unit u;
  output Boolean res;
algorithm
  res := match(u)
    local
      UnitAbsyn.SpecUnit su;
      Boolean unk;
    case(UnitAbsyn.SPECIFIED(su))
      equation
        unk = hasUnknown(su);
      then unk;
    else true;
  end match;
end unitHasUnknown;

public function mulSpecUnit "Multiplying two units corresponds to adding the units and joining the typeParameter list."
  input UnitAbsyn.SpecUnit u1;
  input UnitAbsyn.SpecUnit u2;
  output UnitAbsyn.SpecUnit u;
algorithm
  u := matchcontinue(u1,u2)
    local
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> tparams1,tparams2,tparams3,tparams4;
      list<MMath.Rational> units,units1,units2;

    case (UnitAbsyn.SPECUNIT(tparams1,units1),UnitAbsyn.SPECUNIT(tparams2,units2))
      equation
        tparams3 = listAppend(tparams1,tparams2);
        tparams4 = normalizeParamsExponents(tparams3);
        units = mulUnitVec(units1,units2);
      then
        UnitAbsyn.SPECUNIT(tparams4,units);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::mulSpecUnit() failed\n");
      then
        fail();
  end matchcontinue;
end mulSpecUnit;

public function mulUnitVec "multiplication of two unit vector"
  input list<MMath.Rational> inunitvec1;
  input list<MMath.Rational> inunitvec2;
  output list<MMath.Rational> outunitvec;
algorithm
  outunitvec := matchcontinue(inunitvec1,inunitvec2)
    local
      MMath.Rational expo1,expo2,expo3;
      list<MMath.Rational> rest1,rest2,rest3;

    // empty list
    case ({},{}) then {};

    case(expo1::rest1,expo2::rest2)
      equation
        expo3 = MMath.addRational(expo1,expo2);
        rest3 = mulUnitVec(rest1,rest2);
      then
        (expo3::rest3);

    case(expo1::rest1,{})
      equation
        rest3 = mulUnitVec(rest1,{});
      then
        (expo1::rest3);

    case({},expo1::rest1)
      equation
        rest3 = mulUnitVec({},rest1);
      then (expo1::rest3);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::powUnitVec() failed\n");
      then fail();
  end matchcontinue;
end mulUnitVec;

public function divSpecUnit "Divide two specified units"
  input UnitAbsyn.SpecUnit u1;
  input UnitAbsyn.SpecUnit u2;
  output UnitAbsyn.SpecUnit u;
algorithm
  u := matchcontinue(u1,u2)
    local
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> tparams1,tparams2,tparams3,tparams4,tparams5;
      list<MMath.Rational> units,units1,units2;

    case(UnitAbsyn.SPECUNIT(tparams1,units1),UnitAbsyn.SPECUNIT(tparams2,units2))
      equation
        tparams3 = negParamList(tparams2,{});
        tparams4 = listAppend(tparams1,tparams3);
        tparams5 = normalizeParamsExponents(tparams4);
        units = divUnitVec(units1,units2);
      then
        UnitAbsyn.SPECUNIT(tparams5,units);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::divSpecUnit() failed\n");
      then fail();
  end matchcontinue;
end divSpecUnit;

public function divUnitVec "division of two unit vectors"
  input list<MMath.Rational> inunitvec1;
  input list<MMath.Rational> inunitvec2;
  output list<MMath.Rational> outunitvec;
algorithm
  outunitvec := matchcontinue(inunitvec1,inunitvec2)
    local
      MMath.Rational expo1,expo2,expo3;
      list<MMath.Rational> rest1,rest2,rest3;

    case ({},{}) then {};

    case(expo1::rest1,expo2::rest2)
      equation
        expo3 = MMath.subRational(expo1,expo2);
        rest3 = divUnitVec(rest1,rest2);
      then
        (expo3::rest3);

    case(expo1::rest1,{})
      equation
        rest3 = divUnitVec(rest1,{});
      then
        (expo1::rest3);

    case({},expo1::rest1)
      equation
        expo2 = MMath.subRational(MMath.RATIONAL(0,1),expo1);
        rest3 = divUnitVec({},rest1);
      then
        (expo2::rest3);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::powUnitVec() failed\n");
      then fail();
  end matchcontinue;
end divUnitVec;

public function powSpecUnit "Power of a specified unit"
  input UnitAbsyn.SpecUnit suin;
  input MMath.Rational expo;
  output UnitAbsyn.SpecUnit uout;
algorithm
  uout := matchcontinue(suin,expo)
    local
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> params1,params2;
      list<MMath.Rational> unitvec1,unitvec2;

    case(UnitAbsyn.SPECUNIT(params1,unitvec1),_)
      equation
        params2 = powUnitParams(params1,expo);
        unitvec2 = powUnitVec(unitvec1,expo);
      then
        UnitAbsyn.SPECUNIT(params2,unitvec2);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::powSpecUnit() failed\n");
      then
        fail();
  end matchcontinue;
end powSpecUnit;

public function powUnitParams "exponent power of the unit type parameters"
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> inparams;
  input MMath.Rational expo;
  output list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> outparams;
algorithm
  outparams := matchcontinue(inparams,expo)
    local
      MMath.Rational expo1,expo2,expo3;
      UnitAbsyn.TypeParameter param;
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> rest1,rest2;

    case ({},_) then {};

    case((expo1,param)::rest1,expo2)
      equation
        expo3 = MMath.multRational(expo1,expo2);
        rest2 = powUnitParams(rest1,expo2);
      then
        ((expo3,param)::rest2);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::powUnitParams() failed\n");
      then fail();
  end matchcontinue;
end powUnitParams;

public function powUnitVec "exponent power of the unit vector"
  input list<MMath.Rational> inunitvec;
  input MMath.Rational expo;
  output list<MMath.Rational> outunitvec;
algorithm
  outunitvec := matchcontinue(inunitvec,expo)
    local
      MMath.Rational expo1,expo2,expo3;
      list<MMath.Rational> rest1,rest2;

    case ({},_) then {};

    case(expo1::rest1,expo2)
      equation
        expo3 = MMath.multRational(expo1,expo2);
        rest2 = powUnitVec(rest1,expo2);
      then
        (expo3::rest2);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::powUnitVec() failed\n");
      then fail();
  end matchcontinue;
end powUnitVec;

protected function negParamList
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> ine;
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> ac;
  output list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> oute;
algorithm
  oute := matchcontinue(ine,ac)
    local
      MMath.Rational qr;
      Integer i1,i2,indx;
      String name;
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> rest,pres,ac2;

    case ({},ac2) then ac2;

    case ((MMath.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(name,indx))::rest,ac2)
      equation
        qr = MMath.multRational(MMath.RATIONAL(-1,1),MMath.RATIONAL(i1,i2));
        pres = negParamList(rest,(qr,UnitAbsyn.TYPEPARAMETER(name,indx))::ac2);
      then pres;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::negParamList() failed\n");
      then fail();
  end matchcontinue;
end negParamList;

public function normalize "normalizes the unit pointed by 'loc'. Returns the normalized unit."
  input Integer loc;
  input UnitAbsyn.Store st;
  output UnitAbsyn.Unit unit;
  output UnitAbsyn.Store outSt;
protected
  UnitAbsyn.Unit u1,u2;
  UnitAbsyn.Store st2;
algorithm
   u1 := UnitAbsynBuilder.find(loc,st);
   (u2,st2) := normalizeOnUnit(u1,st);
   outSt := UnitAbsynBuilder.update(u2,loc,st2);
   unit := u2;
end normalize;

public function normalizeOnUnit "switch on each kind of unit"
  input UnitAbsyn.Unit u;
  input UnitAbsyn.Store st;
  output UnitAbsyn.Unit unit;
  output UnitAbsyn.Store outSt;
algorithm
  (unit,outSt) := matchcontinue(u,st)
    local
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> params1,params2,params3;
      list<MMath.Rational> unitvec1,unitvec2;
      UnitAbsyn.Store st2;

    case (UnitAbsyn.UNSPECIFIED(),_)
      then (UnitAbsyn.UNSPECIFIED(),st);

    case (UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(params1,unitvec1)),_)
      equation
        (UnitAbsyn.SPECUNIT(params2,unitvec2),st2) = normalizeParamsValues(params1,UnitAbsyn.SPECUNIT({},unitvec1),st);
        params3 = normalizeParamsExponents(params2);
      then
        (UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(params3,unitvec2)),st2);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::normalizeOnUnit() failed\n");
      then fail();
  end matchcontinue;
end normalizeOnUnit;

protected function normalizeParamsExponents "normalize the exponents of a parameter list"
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> inparams;
  output list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> outparams;
algorithm
  outparams := matchcontinue(inparams)
    local
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> rest1,rest2,rest3;
      String name;
      Integer loc1;
      MMath.Rational expo1,expo2,expo3;
      tuple<MMath.Rational,UnitAbsyn.TypeParameter> param;

    // Case: No more elements in list
    case ({}) then {};

    // Case: Found duplicate parameter in list
    case ((expo1,UnitAbsyn.TYPEPARAMETER(name,loc1))::rest1)
      equation
        (true,expo2,rest2) = getParam(rest1,loc1);
        expo3 = MMath.addRational(expo1,expo2);
        rest3 = normalizeParamsExponents((expo3,UnitAbsyn.TYPEPARAMETER(name,loc1))::rest2);
      then
        rest3;

    // Case: No duplicates in list and exponent IS zero
    case ((MMath.RATIONAL(0,1),_)::rest1)
      equation
        rest2 = normalizeParamsExponents(rest1);
      then
        rest2;

    // Case: No duplicates in list and exponent is not zero
    case (param::rest1)
      equation
        rest2 = normalizeParamsExponents(rest1);
      then
        (param::rest2);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::normalizeParamsExponents() failed\n");
      then
        fail();
  end matchcontinue;
end normalizeParamsExponents;

protected function getParam "returns the next param in list and removes it from the list. 'found'=true if an location existed"
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> inparams;
  input Integer loc;
  output Boolean found;
  output MMath.Rational outexpo;
  output list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> outparams;
algorithm
  (found,outexpo,outparams) := matchcontinue(inparams,loc)
    local
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> rest,rest2;
      String name;
      Integer loc2;
      MMath.Rational expo;
      Boolean found2;
      tuple<MMath.Rational,UnitAbsyn.TypeParameter> param;

    case ({},_) then (false,MMath.RATIONAL(1,1),{});

    case ((expo,UnitAbsyn.TYPEPARAMETER(_,loc2))::rest,_)
      equation
        true = intEq(loc2, loc);
      then
        (true,expo,rest);

    case (param::rest,_)
      equation
        (found2,expo,rest2) = getParam(rest,loc);
      then
        (found2,expo,param::rest2);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::getParam() failed\n");
      then fail();
  end matchcontinue;
end getParam;

protected function normalizeParamsValues "normalize the values that the the list of unit parameters points at"
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> inparams;
  input UnitAbsyn.SpecUnit suin;
  input UnitAbsyn.Store st;
  output UnitAbsyn.SpecUnit uout;
  output UnitAbsyn.Store outSt;
algorithm
  (uout,outSt) := matchcontinue(inparams,suin,st)
    local
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> rest;
      UnitAbsyn.Store st2,st3;
      UnitAbsyn.Unit u2;
      UnitAbsyn.SpecUnit su2,su3;
      String name;
      Integer loc;
      MMath.Rational expo;

    case ({},_,_) then (suin,st);

    case ((expo,UnitAbsyn.TYPEPARAMETER(name,loc))::rest,_,_)
      equation
        (u2,st2) = normalize(loc,st);
        su2 = mulSpecUnitWithNorm(suin,u2,name,loc,expo);
        (su3,st3) = normalizeParamsValues(rest,su2,st2);
      then
        (su3,st3);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::normalizeParamsValues() failed\n");
      then fail();
  end matchcontinue;
end normalizeParamsValues;

protected function mulSpecUnitWithNorm
  input UnitAbsyn.SpecUnit suin;
  input UnitAbsyn.Unit normunit;
  input String name;
  input Integer loc;
  input MMath.Rational expo;
  output UnitAbsyn.SpecUnit suout;
algorithm
  suout := matchcontinue(suin,normunit,name,loc,expo)
    local
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> params;
      list<MMath.Rational> unitvec;
      UnitAbsyn.SpecUnit su2,sunorm,su3,su4;

    case (UnitAbsyn.SPECUNIT(params,unitvec),UnitAbsyn.UNSPECIFIED(),_,_,_)
      then (UnitAbsyn.SPECUNIT((expo,UnitAbsyn.TYPEPARAMETER(name,loc))::params,unitvec));

    case (su2,UnitAbsyn.SPECIFIED(sunorm),_,_,_)
      equation
        su3 = powSpecUnit(sunorm,expo);
        su4 = mulSpecUnit(su2,su3);
      then
        su4;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("UnitChecker::mulSpecUnitWithNorm() failed\n");
      then fail();
  end matchcontinue;
end mulSpecUnitWithNorm;

public function printSpecUnit
  input String text;
  input UnitAbsyn.SpecUnit su;
algorithm
  _ := match(text,su)
    local
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> params;
      list<MMath.Rational> unitvec;
      String str;

    case(str,UnitAbsyn.SPECUNIT(params,_))
      equation
        print(str);
        print(" \"");
        print(UnitAbsynBuilder.unit2str(UnitAbsyn.SPECIFIED(su)));
        print("\" {");
        printSpecUnitParams(params);
        print("}\n");
      then ();
  end match;
end printSpecUnit;

public function printSpecUnitParams
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> params;
algorithm
  _ := match(params)
    local
      String name;
      Integer i1,i2,loc;
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> rest;

    case({}) then ();

    case((MMath.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(name,loc))::rest)
      equation
        print("(\"");
        print(name);
        print("\",");
        print(intString(loc));
        print(")^(");
        print(intString(i1));
        print("/");
        print(intString(i2));
        print("),");
        printSpecUnitParams(rest);
      then ();
  end match;
end printSpecUnitParams;

public function testUnitOp "Test unit operations"
protected
  UnitAbsyn.Unit u1,u2,u3,u4;
  String str1,str2;
algorithm
  print("test");
end testUnitOp;

public function printResult "Print out the result from the unit check"
  input UnitAbsyn.UnitCheckResult res;
algorithm
  _ := match(res)
    local
      UnitAbsyn.SpecUnit u1,u2;
      String str1,str2;

    case (UnitAbsyn.CONSISTENT())
      equation
        print("\n---\nThe system of units is consistent.\n---\n");
      then ();

    case (UnitAbsyn.INCONSISTENT(u1,u2))
      equation
        print("\n---\nThe system of units is inconsistent. \"");
        str1 = UnitAbsynBuilder.unit2str(UnitAbsyn.SPECIFIED(u1));
        print(str1);
        print("\" != \"");
        str2 = UnitAbsynBuilder.unit2str(UnitAbsyn.SPECIFIED(u2));
        print(str2);
        print("\"\n---\n");
      then ();
  end match;
end printResult;

annotation(__OpenModelica_Interface="frontend");
end UnitChecker;
