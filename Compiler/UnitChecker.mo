/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
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

package UnitChecker 
" 
  file:	       UnitChecker.mo
  package:     UnitChecker
  description: Physical unit checking.

This package is used for checking if an equation system is consistent, inconsistent or unknown (not enough information to determine).
"

public import UnitAbsyn;
public import Math;
public import UnitAbsynBuilder;

 

protected import Debug;
protected import Error;
protected import OptManager;

public uniontype UnitCheckResult
  record CONSISTENT end CONSISTENT;  // May be complete or incomplete
  record INCONSISTENT 
     UnitAbsyn.SpecUnit u1;  //Left unit    
     UnitAbsyn.SpecUnit u2;  //Right unit    
  end INCONSISTENT;
end UnitCheckResult;


public function check "Check if a list of unit terms are consistent"
  input UnitAbsyn.UnitTerms tms; 
  input UnitAbsyn.Store st;
  output UnitCheckResult result;
  output UnitAbsyn.Store outSt;
algorithm
   (result,outSt) := matchcontinue(tms,st)
   local
     UnitAbsyn.Store st1,st2,st3;
     UnitAbsyn.UnitTerms rest1;
     UnitAbsyn.UnitTerm tm1;
     UnitCheckResult res1;
     UnitAbsyn.SpecUnit su1,su2;
     String s1,s2,s3;
     case(_,st1) equation
       false = OptManager.getOption("unitChecking");       
     then (CONSISTENT,st1);

     //No more terms?
     case({},st1) 
       then (CONSISTENT,st1);
     //Is consistent?
     case(tm1::rest1,st1) equation
       (CONSISTENT,_,st2) = checkTerm(tm1,st1);
       (res1,st3) = check(rest1,st2);
       then(res1,st3);
     //Is inconsistent?       
     case(tm1::rest1,st1) equation
       (INCONSISTENT(su1,su2),_,st2) = checkTerm(tm1,st1);
       s1 = UnitAbsynBuilder.printTermsStr({tm1});
       s2 = UnitAbsynBuilder.unit2str(UnitAbsyn.SPECIFIED(su1));
       s3 = UnitAbsynBuilder.unit2str(UnitAbsyn.SPECIFIED(su2));
       Error.addMessage(Error.INCONSISTENT_UNITS,{s1,s2,s3});    
       then(INCONSISTENT(su1,su2),st2);
     case(_,_) equation
       Debug.fprint("failtrace", "UnitChecker::check() failed\n");       
      then fail();
   end matchcontinue;
end check; 

public function isComplete "returns true if the store is complete, else false" 
  input UnitAbsyn.Store st;
  output Boolean complete;
  output UnitAbsyn.Store stout;   
algorithm
  complete := matchcontinue(st)
  local Option<UnitAbsyn.Unit>[:] vector; Integer indx;
    list<Option<UnitAbsyn.Unit>> lst;
    Boolean comp;
    UnitAbsyn.Store st2;
    case(UnitAbsyn.STORE(vector,indx)) equation
      lst = arrayList(vector);
      (comp,st2) = completeCheck(lst,1,UnitAbsyn.STORE(vector,indx));
   then(comp,st2);
  end matchcontinue;
end isComplete;

protected function completeCheck "help function to isComplete"
  input list<Option<UnitAbsyn.Unit>> lst;
  input Integer indx;
  input UnitAbsyn.Store st;
  output Boolean isComplete;
  output UnitAbsyn.Store stout;
algorithm 
  _ := matchcontinue(lst,indx,st)
  local 
    UnitAbsyn.Unit u1,u2;
    Boolean comp1;
    UnitAbsyn.Store st2,st3,st4;
    case({},_,st2) then (true,st2);      
    case(SOME(u1)::lst,indx,st2) equation
      (u2,st3) = normalize(indx,st2);
      false = unitHasUnknown(u2);
      (comp1,st4) = completeCheck(lst,indx+1,st3);
    then(comp1,st3);
    case(NONE::_,_,st2) then (true,st2);            
  end matchcontinue;
end completeCheck;

public function checkTerm "check if one term is ok"
  input UnitAbsyn.UnitTerm tm; 
  input UnitAbsyn.Store st;
  output UnitCheckResult result;
  output UnitAbsyn.SpecUnit outUnit;           
  output UnitAbsyn.Store outSt;
algorithm
   (result,outFailingTm,outUnit,outSt) := matchcontinue(tm,st)
   local
     UnitAbsyn.Store st1,st2,st3,st4;
     UnitCheckResult res1,res2,res3,res4;
     UnitAbsyn.Store st1,st2,st3,st4;
     UnitAbsyn.UnitTerm ut1,ut2;
     UnitAbsyn.SpecUnit su1,su2,su3;
     Math.Rational expo1;
     Integer loc;
     case(UnitAbsyn.ADD(ut1,ut2,_),st1) equation
       (res1,su1,st2) = checkTerm(ut1,st1);
       (res2,su2,st3) = checkTerm(ut2,st2);
       (res3,st4) = unify(su1,su2,st3);
       res4 = chooseResult(res1,res2,res3);
       then(res4,su1,st4);
     case(UnitAbsyn.SUB(ut1,ut2,_),st1) equation
       (res1,su1,st2) = checkTerm(ut1,st1);
       (res2,su2,st3) = checkTerm(ut2,st2);
       (res3,st4) = unify(su1,su2,st3);
       res4 = chooseResult(res1,res2,res3);
       then(res4,su1,st4);
     case(UnitAbsyn.MUL(ut1,ut2,_),st1) equation
       (res1,su1,st2) = checkTerm(ut1,st1);
       (res2,su2,st3) = checkTerm(ut2,st2);
       su3 = mulSpecUnit(su1,su2);
       res4 = chooseResult(res1,res2,CONSISTENT);
       then(res4,su3,st3);
     case(UnitAbsyn.DIV(ut1,ut2,_),st1) equation
       (res1,su1,st2) = checkTerm(ut1,st1);
       (res2,su2,st3) = checkTerm(ut2,st2);
       su3 = divSpecUnit(su1,su2);
       res4 = chooseResult(res1,res2,CONSISTENT);
       then(res4,su3,st3);
     case(UnitAbsyn.EQN(ut1,ut2,_),st1) equation
       (res1,su1,st2) = checkTerm(ut1,st1);
       (res2,su2,st3) = checkTerm(ut2,st2);
       (res3,st4) = unify(su1,su2,st3);
       res4 = chooseResult(res1,res2,res3);
       then(res4,su1,st4);
     case(UnitAbsyn.LOC(loc,_),st1) equation
       (UnitAbsyn.UNSPECIFIED) = UnitAbsynBuilder.find(loc,st1);
       then(CONSISTENT,UnitAbsyn.SPECUNIT((Math.RATIONAL(1,1),UnitAbsyn.TYPEPARAMETER("",loc))::{},{}),st1);
     case(UnitAbsyn.LOC(loc,_),st1) equation
       (UnitAbsyn.SPECIFIED(su1)) = UnitAbsynBuilder.find(loc,st1);
       then(CONSISTENT,su1,st1);
     case(UnitAbsyn.POW(ut1,expo1,_),st1) equation
       (res1,su1,st2) = checkTerm(ut1,st1);
       su2 = powSpecUnit(su1,expo1);
       then(res1,su2,st2);
     case(_,_) equation
       Debug.fprint("failtrace", "UnitChecker::checkTerm() failed\n");       
      then fail();
   end matchcontinue;
end checkTerm;
 

protected function chooseResult "Returns the first result that is INCONSISTENT. If not, CONISTENT will be returned"
  input UnitCheckResult res1;
  input UnitCheckResult res2;
  input UnitCheckResult res3;
  output UnitCheckResult resout;
protected
  UnitCheckResult incon;
algorithm  
  resout := matchcontinue(res1,res2,res3)
    case(CONSISTENT,CONSISTENT,CONSISTENT) then CONSISTENT;
    case(CONSISTENT,CONSISTENT,incon) then incon;
    case(CONSISTENT,incon,_) then incon;
    case(incon,_,_) then incon;
    case(_,_,_) equation
      Debug.fprint("failtrace", "UnitChecker::chooseResult() failed\n");       
    then fail();
  end matchcontinue;  
end chooseResult;

protected function unify
  input UnitAbsyn.SpecUnit insu1;           
  input UnitAbsyn.SpecUnit insu2;           
  input UnitAbsyn.Store st;
  output UnitCheckResult outresult;
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
    list<Math.Rational> rest1,rest2;
    case(UnitAbsyn.SPECUNIT(_,{}),UnitAbsyn.SPECUNIT(_,{})) 
      then true;
    case(UnitAbsyn.SPECUNIT(_,{}),UnitAbsyn.SPECUNIT(_,Math.RATIONAL(0,_)::rest1)) equation
      r1 = isSpecUnitEq(UnitAbsyn.SPECUNIT({},{}), UnitAbsyn.SPECUNIT({},rest1));
      then r1;      
    case(UnitAbsyn.SPECUNIT(_,Math.RATIONAL(0,_)::rest1),UnitAbsyn.SPECUNIT(_,{})) equation
      r1 = isSpecUnitEq(UnitAbsyn.SPECUNIT({},rest1),UnitAbsyn.SPECUNIT({},{}));
      then r1;
    case(UnitAbsyn.SPECUNIT(_,Math.RATIONAL(i1a,i1b)::rest1), 
      UnitAbsyn.SPECUNIT(_,Math.RATIONAL(i2a,i2b)::rest2)) equation
        equality(i1a = i2a);
        equality(i1b = i2b);
        r1 = isSpecUnitEq(UnitAbsyn.SPECUNIT({},rest1),UnitAbsyn.SPECUNIT({},rest2));
      then r1;      
    case(_,_) 
      then false;      
  end matchcontinue;
end isSpecUnitEq;


protected function unifyunits
  input UnitAbsyn.SpecUnit insu1;           
  input UnitAbsyn.SpecUnit insu2;           
  input UnitAbsyn.Store st;
  output UnitCheckResult outresult;
  output UnitAbsyn.Store outSt;
algorithm
  (outresult,outSt) := matchcontinue(insu1,insu2,st)
  local
    UnitAbsyn.SpecUnit su1,su2,su3,su4;
    UnitAbsyn.Store st1,st2;
    Integer loc1;
    //No unknown and the same on both sides
    case(su1,su2,st1) equation
      false = hasUnknown(su1);
      false = hasUnknown(su2);
      true = isSpecUnitEq(su1,su2);
      then(CONSISTENT,st1);
    //No unknown, but different on the sides
    case(su1,su2,st1) equation
      false = hasUnknown(su1);
      false = hasUnknown(su2);
      then(INCONSISTENT(su1,su2),st1);
    //Move the unknown to left side and substitute
    case(su1,su2,st1) equation
      su3 = divSpecUnit(su2,su1);
      (loc1,su4) = getUnknown(su3);
      st2 = UnitAbsynBuilder.update(UnitAbsyn.SPECIFIED(su4),loc1,st1);
      then(CONSISTENT,st2);
    //Unknowns are cancelling each other out
    case(_,_,st1) 
      then(CONSISTENT,st1);
  end matchcontinue;        
end unifyunits;

public function newDimlessSpecUnit "creates a new dimensionless unit"
  output UnitAbsyn.SpecUnit su;
algorithm
  UnitAbsyn.SPECIFIED(su) := UnitAbsynBuilder.str2unit("1");  
end newDimlessSpecUnit;  


public function getUnknown "gets the first unknown in a specified unit"
  input UnitAbsyn.SpecUnit suin;
  output Integer loc;
  output UnitAbsyn.SpecUnit suout;
algorithm
  (loc,suout) := matchcontinue(suin)
    local 
     UnitAbsyn.SpecUnit su1,su2;
     Math.Rational expo1,expo2;
     Integer loc1;
     String name;
     list<Math.Rational> unitvec1;
     list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> rest1;        
    case(UnitAbsyn.SPECUNIT((expo1,UnitAbsyn.TYPEPARAMETER(name,loc1))::rest1,unitvec1)) equation
      su1 = divSpecUnit(newDimlessSpecUnit(),UnitAbsyn.SPECUNIT(rest1,unitvec1));
      expo2 = Math.divRational(Math.RATIONAL(1,1), expo1);
      su2 = powSpecUnit(su1,expo2);
      then (loc1,su2);
    case(_) equation
      Debug.fprint("failtrace", "UnitChecker::getUnknown() failed\n");       
    then fail();
  end matchcontinue;
end getUnknown;



public function hasUnknown
  input UnitAbsyn.SpecUnit su;
  output Boolean res;
algorithm
  res := matchcontinue(su)
  local 
    case(UnitAbsyn.SPECUNIT({},_)) then false;
    case(UnitAbsyn.SPECUNIT(_,_)) then true;  
    case(_) equation
      Debug.fprint("failtrace", "UnitChecker::hasUnknown() failed\n");       
    then fail();
  end matchcontinue;
end hasUnknown;

public function unitHasUnknown
  input UnitAbsyn.Unit u;
  output Boolean res;
algorithm
  res := matchcontinue(u)
  local
    UnitAbsyn.SpecUnit su;
    case(UnitAbsyn.SPECIFIED(su)) equation
      false = hasUnknown(su);
      then false;
    case(_) then true;  
  end matchcontinue;
end unitHasUnknown;


public function mulSpecUnit "Multiplying two units corresponds to adding the units and joining the typeParameter list."
  input UnitAbsyn.SpecUnit u1;
  input UnitAbsyn.SpecUnit u2;
  output UnitAbsyn.SpecUnit u;  
algorithm
  u := matchcontinue(u1,u2)
  local list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> tparams1,tparams2,tparams3,tparams4;
    list<Math.Rational> units,units1,units2;
    case(UnitAbsyn.SPECUNIT(tparams1,units1),UnitAbsyn.SPECUNIT(tparams2,units2)) equation
      tparams3 = listAppend(tparams1,tparams2);
      tparams4 = normalizeParamsExponents(tparams3);
      units = mulUnitVec(units1,units2);
    then UnitAbsyn.SPECUNIT(tparams4,units);
    case(_,_) equation
      Debug.fprint("failtrace", "UnitChecker::mulSpecUnit() failed\n");       
    then fail();
  end matchcontinue;
end mulSpecUnit;

public function mulUnitVec "multiplication of two unit vector"
  input list<Math.Rational> inunitvec1;
  input list<Math.Rational> inunitvec2;
  output list<Math.Rational> outunitvec; 
algorithm
  outunitvec := matchcontinue(inunitvec1,inunitvec2)
  local
    Math.Rational expo1,expo2,expo3;
    list<Math.Rational> rest1,rest2,rest3;
    case ({},{}) then {}; 
    case(expo1::rest1,expo2::rest2) equation
      expo3 = Math.addRational(expo1,expo2);
      rest3 = mulUnitVec(rest1,rest2);
    then (expo3::rest3);   
    case(expo1::rest1,{}) equation
      rest3 = mulUnitVec(rest1,{});
    then (expo1::rest3);   
    case({},expo1::rest1) equation
      rest3 = mulUnitVec({},rest1);
    then (expo1::rest3);   
    case(_,_) equation
      Debug.fprint("failtrace", "UnitChecker::powUnitVec() failed\n");       
    then fail();
  end matchcontinue;
end mulUnitVec;



public function divSpecUnit "Divide two specified units"
  input UnitAbsyn.SpecUnit u1;
  input UnitAbsyn.SpecUnit u2;
  output UnitAbsyn.SpecUnit u;  
algorithm
  u := matchcontinue(u1,u2)
  local list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> tparams1,tparams2,tparams3,tparams4,tparams5;
    list<Math.Rational> units,units1,units2;
    case(UnitAbsyn.SPECUNIT(tparams1,units1),UnitAbsyn.SPECUNIT(tparams2,units2)) equation
      tparams3 = negParamList(tparams2,{});
      tparams4 = listAppend(tparams1,tparams3);
      tparams5 = normalizeParamsExponents(tparams4);
      units = divUnitVec(units1,units2);
    then UnitAbsyn.SPECUNIT(tparams5,units);
    case(_,_) equation
      Debug.fprint("failtrace", "UnitChecker::divSpecUnit() failed\n");       
    then fail();
  end matchcontinue;
end divSpecUnit;

public function divUnitVec "division of two unit vectors"
  input list<Math.Rational> inunitvec1;
  input list<Math.Rational> inunitvec2;
  output list<Math.Rational> outunitvec; 
algorithm
  outunitvec := matchcontinue(inunitvec1,inunitvec2)
  local
    Math.Rational expo1,expo2,expo3;
    list<Math.Rational> rest1,rest2,rest3;
    case ({},{}) then {}; 
    case(expo1::rest1,expo2::rest2) equation
      expo3 = Math.subRational(expo1,expo2);
      rest3 = divUnitVec(rest1,rest2);
    then (expo3::rest3);   
    case(expo1::rest1,{}) equation
      rest3 = divUnitVec(rest1,{});
    then (expo1::rest3);   
    case({},expo1::rest1) equation
      expo2 = Math.subRational(Math.RATIONAL(0,1),expo1);
      rest3 = divUnitVec({},rest1);
    then (expo2::rest3);   
    case(_,_) equation
      Debug.fprint("failtrace", "UnitChecker::powUnitVec() failed\n");       
    then fail();
  end matchcontinue;
end divUnitVec;


public function powSpecUnit "Power of a specified unit"
  input UnitAbsyn.SpecUnit suin;
  input Math.Rational expo;
  output UnitAbsyn.SpecUnit uout;  
algorithm
  u := matchcontinue(suin,expo)
  local list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> params1,params2;
    list<Math.Rational> unitvec1,unitvec2;
    case(UnitAbsyn.SPECUNIT(params1,unitvec1),expo) equation
      params2 = powUnitParams(params1,expo); 
      unitvec2 = powUnitVec(unitvec1,expo);
    then UnitAbsyn.SPECUNIT(params2,unitvec2);
    case(_,_) equation
      Debug.fprint("failtrace", "UnitChecker::powSpecUnit() failed\n");       
    then fail();
  end matchcontinue;
end powSpecUnit;


public function powUnitParams "exponent power of the unit type parameters"
  input list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> inparams;
  input Math.Rational expo;  
  output list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> outparams; 
algorithm
  outparams := matchcontinue(inparams,expo)
  local
    Math.Rational expo1,expo2,expo3;
    UnitAbsyn.TypeParameter param;
    list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> rest1,rest2;
    case ({},_) then {}; 
    case((expo1,param)::rest1,expo2) equation
      expo3 = Math.multRational(expo1,expo2);
      rest2 = powUnitParams(rest1,expo2);
    then ((expo3,param)::rest2);   
    case(_,_) equation
      Debug.fprint("failtrace", "UnitChecker::powUnitParams() failed\n");       
    then fail();
  end matchcontinue;
end powUnitParams;

public function powUnitVec "exponent power of the unit vector"
  input list<Math.Rational> inunitvec;
  input Math.Rational expo;  
  output list<Math.Rational> outunitvec; 
algorithm
  outunitvec := matchcontinue(inunitvec,expo)
  local
    Math.Rational expo1,expo2,expo3;
    list<Math.Rational> rest1,rest2;
    case ({},_) then {}; 
    case(expo1::rest1,expo2) equation
      expo3 = Math.multRational(expo1,expo2);
      rest2 = powUnitVec(rest1,expo2);
    then (expo3::rest2);   
    case(_,_) equation
      Debug.fprint("failtrace", "UnitChecker::powUnitVec() failed\n");       
    then fail();
  end matchcontinue;
end powUnitVec;


protected function negParamList 
  input list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> ine;
  input list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> ac;
  output list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> oute;
algorithm
  oute := matchcontinue(ine,ac)
  local 
    Math.Rational qr;
    Integer i1,i2,indx;
    String name;
    UnitAbsyn.TypeParameter p;
    list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> rest,pres,ac2;
    case ({},ac2) then ac2;
    case ((Math.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(name,indx))::rest,ac2) equation
      qr = Math.multRational(Math.RATIONAL(-1,1),Math.RATIONAL(i1,i2));
      pres = negParamList(rest,(qr,UnitAbsyn.TYPEPARAMETER(name,indx))::ac2);      
    then pres;  
    case(_,_) equation
      Debug.fprint("failtrace", "UnitChecker::negParamList() failed\n");       
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
    UnitAbsyn.Unit u1;
    list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> params1,params2,params3;
    list<Math.Rational> unitvec1,unitvec2;
    UnitAbsyn.Store st2;
    UnitAbsyn.SpecUnit su2,su3;
    case (UnitAbsyn.UNSPECIFIED,st) 
      then (UnitAbsyn.UNSPECIFIED,st);
    case (UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(params1,unitvec1)),st) equation
      (UnitAbsyn.SPECUNIT(params2,unitvec2),st2) = normalizeParamsValues(params1,UnitAbsyn.SPECUNIT({},unitvec1),st);
      params3 = normalizeParamsExponents(params2);
      then (UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(params3,unitvec2)),st2);
    case(_,_) equation
      Debug.fprint("failtrace", "UnitChecker::normalizeOnUnit() failed\n");       
    then fail();
  end matchcontinue;
end normalizeOnUnit;

protected function normalizeParamsExponents "normalize the exponents of a parameter list" 
  input list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> inparams;
  output list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> outparams;
algorithm
  outparams := matchcontinue(inparams)
  local
    list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> rest1,rest2,rest3;
    String name;
    Integer loc1;
    Math.Rational expo1,expo2,expo3;
    tuple<Math.Rational,UnitAbsyn.TypeParameter> param;
    //Case: No more elements in list
    case ({}) then {};
    //Case: Found duplicate parameter in list  
    case ((expo1,UnitAbsyn.TYPEPARAMETER(name,loc1))::rest1) equation
      (true,expo2,rest2) = getParam(rest1,loc1);
      expo3 = Math.addRational(expo1,expo2);
      rest3 = normalizeParamsExponents((expo3,UnitAbsyn.TYPEPARAMETER(name,loc1))::rest2);
      then rest3;       
    //Case: No duplicates in list and exponent IS zero
    case ((Math.RATIONAL(0,1),_)::rest1) equation
      rest2 = normalizeParamsExponents(rest1);
      then (rest2);
    //Case: No duplicates in list and exponent is not zero
    case (param::rest1) equation
      rest2 = normalizeParamsExponents(rest1);
      then (param::rest2);
    case(_) equation
      Debug.fprint("failtrace", "UnitChecker::normalizeParamsExponents() failed\n");       
    then fail();
  end matchcontinue;
end normalizeParamsExponents;

protected function getParam "returns the next param in list and removes it from the list. 'found'=true if an location existed" 
  input list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> inparams;
  input Integer loc;
  output Boolean found;
  output Math.Rational outexpo;
  output list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> outparams;  
algorithm
  (expo,outparams) := matchcontinue(inparams,loc)
  local
    list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> rest,rest2;
    String name;
    Integer loc2;
    Math.Rational expo;
    Boolean found2; 
    tuple<Math.Rational,UnitAbsyn.TypeParameter> param;
    case ({},loc) then (false,Math.RATIONAL(1,1),{});
    case ((expo,UnitAbsyn.TYPEPARAMETER(name,loc2))::rest,loc) equation
      equality(loc2 = loc);
      then (true,expo,rest);
    case (param::rest,loc) equation
      (found2,expo,rest2) = getParam(rest,loc);
      then (found2,expo,param::rest2);
    case(_,_) equation
      Debug.fprint("failtrace", "UnitChecker::getParam() failed\n");       
    then fail();
  end matchcontinue;
end getParam;


 
protected function normalizeParamsValues "normalize the values that the the list of unit parameters points at" 
  input list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> inparams;
  input UnitAbsyn.SpecUnit suin;
  input UnitAbsyn.Store st;
  output UnitAbsyn.SpecUnit uout;
  output UnitAbsyn.Store outSt;  
algorithm
  (outparams,uout,outSt) := matchcontinue(inparams,suin,st)
  local
    list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> rest;
    UnitAbsyn.Store st2,st3;
    UnitAbsyn.Unit u2;
    UnitAbsyn.SpecUnit su2,su3;
    String name;
    Integer loc;
    Math.Rational expo;
    case ({},suin,st) then (suin,st);
    case ((expo,UnitAbsyn.TYPEPARAMETER(name,loc))::rest,suin,st) equation
      (u2,st2) = normalize(loc,st);
      su2 = mulSpecUnitWithNorm(suin,u2,name,loc,expo);
      (su3,st3) = normalizeParamsValues(rest,su2,st2);      
      then (su3,st3);
    case(_,_,_) equation
      Debug.fprint("failtrace", "UnitChecker::normalizeParamsValues() failed\n");       
    then fail();
  end matchcontinue;
end normalizeParamsValues;

protected function mulSpecUnitWithNorm   
  input UnitAbsyn.SpecUnit suin;
  input UnitAbsyn.Unit normunit;
  input String name;
  input Integer loc;
  input Math.Rational expo;
  output UnitAbsyn.SpecUnit suout;
algorithm
  suout := matchcontinue(suin,normunit,name,loc,expo)
  local
    input list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> params;
    list<Math.Rational> unitvec;
    UnitAbsyn.SpecUnit su2,sunorm,su3,su4;
    case (UnitAbsyn.SPECUNIT(params,unitvec),UnitAbsyn.UNSPECIFIED,name,loc,expo) 
      then (UnitAbsyn.SPECUNIT((expo,UnitAbsyn.TYPEPARAMETER(name,loc))::params,unitvec));
    case (su2,UnitAbsyn.SPECIFIED(sunorm),name,loc,expo) equation
      su3 = powSpecUnit(sunorm,expo);
      su4 = mulSpecUnit(su2,su3);
      then su4;
    case(_,_,_,_,_) equation
      Debug.fprint("failtrace", "UnitChecker::mulSpecUnitWithNorm() failed\n");       
    then fail();
  end matchcontinue;
end mulSpecUnitWithNorm;




public function printSpecUnit 
protected
  input String text;
  input UnitAbsyn.SpecUnit su;  
algorithm  
  _ := matchcontinue(text,su)
  local
    list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> params;
    list<Math.Rational> unitvec;
    String str;
    case(str,UnitAbsyn.SPECUNIT(params,unitvec)) equation      
	  print(str);
	  print(" \"");
	  print(UnitAbsynBuilder.unit2str(UnitAbsyn.SPECIFIED(su)));
	  print("\" {");
	  printSpecUnitParams(params);  
	  print("}\n");
	  then ();
	end matchcontinue;
end printSpecUnit;

public function printSpecUnitParams 
  input list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> params;
algorithm
  _ := matchcontinue(params)
  local
    String name;
    Integer i1,i2,loc;
    list<tuple<Math.Rational,UnitAbsyn.TypeParameter>> rest;
    case({})
      then ();
    case((Math.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(name,loc))::rest) equation
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
	end matchcontinue;
end printSpecUnitParams;



public function testUnitOp "Test unit operations"
protected
  UnitAbsyn.Unit u1,u2,u3,u4;
  String str1,str2;
algorithm  
  print("test");
end testUnitOp;


public function printResult "Print out the result from the unit check"
  input UnitCheckResult res;
algorithm
  _ := matchcontinue(res)
  local
    UnitAbsyn.SpecUnit u1,u2;      
    String str1,str2;
    case (CONSISTENT) equation
      print("\n---\nThe system of units is consistent.\n---\n");
      then ();
    case (INCONSISTENT(u1,u2)) equation
      print("\n---\nThe system of units is inconsistent. \"");
      str1 = UnitAbsynBuilder.unit2str(UnitAbsyn.SPECIFIED(u1));
      print(str1);
      print("\" != \""); 
      str2 = UnitAbsynBuilder.unit2str(UnitAbsyn.SPECIFIED(u2));
      print(str2);
      print("\"\n---\n"); 
      then ();
  end matchcontinue;  
end printResult;
  

end UnitChecker; 