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

encapsulated package UnitAbsynBuilder

public import UnitAbsyn;
public import DAE;
public import MMath;
public import HashTable;

protected import Array;
protected import BaseHashTable;
protected import Flags;
protected import UnitParserExt;
protected import Util;

public function add "Adds a unit to the UnitAbsyn.Store"
  input UnitAbsyn.Unit unit;
  input UnitAbsyn.Store ist;
  output UnitAbsyn.Store outSt;
  output Integer index;
algorithm
  (outSt,index) := matchcontinue ist
    local array<Option<UnitAbsyn.Unit>> vector; Integer newIndx,numElts; UnitAbsyn.Store st;
    case st as UnitAbsyn.STORE(storeVector=vector,numElts = numElts) algorithm
      true := numElts == arrayLength(vector);
      st := expandStore(st);
      (st,index) := add(unit,st);
    then (st,index);
    case UnitAbsyn.STORE(storeVector=vector,numElts = numElts) algorithm
      newIndx := numElts+1;
      vector := arrayUpdate(vector,newIndx,SOME(unit));
    then (UnitAbsyn.STORE(vector,newIndx),newIndx);
  end matchcontinue;
end add;

protected function expandStore "Expands store to make room for more entries.
Expansion factor: 1.4
"
  input UnitAbsyn.Store st;
  output UnitAbsyn.Store outSt;
algorithm
  outSt := match st
  local array<Option<UnitAbsyn.Unit>> vector; Integer indx,incr;
    case UnitAbsyn.STORE(vector,indx) algorithm
        incr := intMin(1,realInt(intReal(indx) * 0.4));
        vector := Array.expand(incr,vector,NONE());
     then UnitAbsyn.STORE(vector,indx);
  end match;
end expandStore;

public function emptyInstStore "returns an empty InstStore"
  output UnitAbsyn.InstStore st;
algorithm
  // phi: very old unit checking
  st := emptyInstStore2(/*Flags.getConfigBool(Flags.UNIT_CHECKING)*/false);
end emptyInstStore;

protected function emptyInstStore2 "returns an empty InstStore"
  input Boolean wantInstStore;
  output UnitAbsyn.InstStore st;
algorithm
  st := match wantInstStore
    local
      UnitAbsyn.Store s;
      HashTable.HashTable ht;
    case true
      algorithm
        s := emptyStore();
        ht := HashTable.emptyHashTable();
      then UnitAbsyn.INSTSTORE(s,ht);
    else UnitAbsyn.noStore;
  end match;
end emptyInstStore2;

public function emptyStore "Returns an empty store with 10 empty array elements"
output UnitAbsyn.Store st;
protected
  array<Option<UnitAbsyn.Unit>> vector;
algorithm
   vector := arrayCreate(10,NONE());
   st := UnitAbsyn.STORE(vector,0);
end emptyStore;

public function splitRationals "splits a list of Rationals into a list of numerators and denominators"
  input list<MMath.Rational> inRationals;
  output list<Integer> nums;
  output list<Integer> denoms;
algorithm
  (nums,denoms) := match inRationals
    local Integer i1,i2; list<MMath.Rational> rationals;
    case {} then ({},{});
    case MMath.RATIONAL(i1,i2)::rationals algorithm
      (nums,denoms) := splitRationals(rationals);
    then (i1::nums,i2::denoms);
  end match;
end splitRationals;

public function joinRationals "joins a lists of numerators and denominators into list of Rationals"
  input list<Integer> inums;
  input list<Integer> idenoms;
  output list<MMath.Rational> rationals;
algorithm
  rationals := match(inums,idenoms)
    local Integer i1,i2; list<Integer> nums,denoms;
    case({},{}) then ({});
    case(i1::nums,i2::denoms) algorithm
      rationals := joinRationals(nums,denoms);
    then (MMath.RATIONAL(i1,i2)::rationals);
  end match;
end joinRationals;

public function joinTypeParams "creates type parameter lists from list of numerators , denominators and typeparameter names"
  input list<Integer> inums;
  input list<Integer> idenoms;
  input list<String> itpstrs;
  input Option<Integer> funcInstIdOpt;
  output list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
algorithm
  typeParams := match(inums, idenoms, itpstrs)
    local Integer i1,i2; String tpParam,s; list<Integer> nums, denoms; list<String> tpstrs;
    case({}, {}, {}) then {};
    case(i1::nums, i2::denoms, tpParam::tpstrs) algorithm
      typeParams := joinTypeParams(nums,denoms,tpstrs,funcInstIdOpt);
      s := Util.applyOptionOrDefault(funcInstIdOpt, intString, "");
      tpParam := tpParam + s;
    then (MMath.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(tpParam,0))::typeParams;
  end match;
end joinTypeParams;

public function splitTypeParams "splits type parameter lists into numerators, denominators and typeparameter names"
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> iTypeParams;
  output list<Integer> nums;
  output list<Integer> denoms;
  output list<String> tpstrs;
algorithm
  (nums,denoms,tpstrs) := match iTypeParams
    local String tpParam; Integer i1,i2; list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
    case {} then ({},{},{});
    case (MMath.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(tpParam,_))::typeParams algorithm
      (nums,denoms,tpstrs) := splitTypeParams(typeParams);
    then (i1::nums,i2::denoms,tpParam::tpstrs);
  end match;
end splitTypeParams;

public function instAddStore "Called when instantiating a Real class"
  input UnitAbsyn.InstStore istore;
  input DAE.Type itp;
  input DAE.ComponentRef cr;
  output UnitAbsyn.InstStore outStore;
algorithm
  outStore := matchcontinue(istore, itp)
    local
      UnitAbsyn.Store st;
      HashTable.HashTable ht;
      String unitStr;
      UnitAbsyn.Unit unit; Integer indx;
      list<DAE.Var> varLst;
      UnitAbsyn.InstStore store;
      DAE.Type tp;

    case(UnitAbsyn.NOSTORE(), _)
      then istore;

    case(UnitAbsyn.INSTSTORE(st,ht), DAE.T_REAL(varLst = varLst))
      algorithm
        for v in varLst loop
          () := match v
            case DAE.TYPES_VAR(name="unit",binding = DAE.EQBOUND(exp=DAE.SCONST(unitStr)))
              algorithm
                unit := str2unit(unitStr,NONE());
                unit := if 0 == stringCompare(unitStr,"") then UnitAbsyn.UNSPECIFIED() else unit;
                (st,indx) := add(unit,st);
                ht := BaseHashTable.add((cr,indx),ht);
                outStore := UnitAbsyn.INSTSTORE(st,ht);
                return;
              then ();
            else ();
          end match;
        end for;
        (st,indx) := add(UnitAbsyn.UNSPECIFIED(),st);
        ht := BaseHashTable.add((cr,indx),ht);
      then UnitAbsyn.INSTSTORE(st,ht);

    case(store, DAE.T_SUBTYPE_BASIC(complexType=tp))
      then instAddStore(store,tp,cr);
    else istore;
  end matchcontinue;
end instAddStore;

public function unit2str "Translate a unit to a string"
  input UnitAbsyn.Unit unit;
  output String res;
algorithm
  res := match unit
    local
      list<Integer> nums,denoms,tpnoms,tpdenoms;
      list<String> tpstrs;
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
      list<MMath.Rational> units;

    case UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(typeParams,units)) algorithm
      (nums,denoms) := splitRationals(units);
      (tpnoms,tpdenoms,tpstrs) := splitTypeParams(typeParams);
      res := UnitParserExt.unit2str(nums,denoms,tpnoms,tpdenoms,tpstrs,1.0/*scaleFactor*/,0.0/*offset*/);
    then res;
    case UnitAbsyn.UNSPECIFIED() then "unspecified";
   end match;
end unit2str;

public function str2unit "Translate a unit string to a unit"
  input String res;
  input Option<Integer> funcInstIdOpt;
  output UnitAbsyn.Unit unit;
algorithm
  (unit,_,_) := str2unitWithScaleFactor(res,funcInstIdOpt);
end str2unit;

public function str2unitWithScaleFactor "Translate a unit string to a unit"
  input String res;
  input Option<Integer> funcInstIdOpt;
  output UnitAbsyn.Unit unit;
  output Real scaleFactor;
  output Real offset;
protected
   list<Integer> nums,denoms,tpnoms,tpdenoms;
   list<String> tpstrs;
   list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
   list<MMath.Rational> units;
algorithm
  (nums,denoms,tpnoms,tpdenoms,tpstrs,scaleFactor,offset) := UnitParserExt.str2unit(res);
  units := joinRationals(nums,denoms);
  typeParams := joinTypeParams(tpnoms,tpdenoms,tpstrs,funcInstIdOpt);
  unit := UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(typeParams,units));
end str2unitWithScaleFactor;

public function convertUnits
  "value_unit1 = factor*value_unit2 + offset. Units that differ in rad only
   convert where Hz makes up for it, as revolutions per second (FMI 3.0,
   section 2.4.3: 1 Hz = 2*pi rad/s)."
  input String unit1;
  input String unit2;
  output Boolean converts;
  output Real factor;
  output Real offset;
protected
  UnitAbsyn.Unit u1, u2;
  Real factor1, factor2, offset1, offset2;
  Integer rad1, hz1, rad2, hz2;
algorithm
  (u1, factor1, offset1) := str2unitWithScaleFactor(unit1, NONE());
  (u2, factor2, offset2) := str2unitWithScaleFactor(unit2, NONE());
  (rad1, hz1) := UnitParserExt.angleExponents(unit1);
  (rad2, hz2) := UnitParserExt.angleExponents(unit2);
  converts := valueEq(u1, u2);
  factor := factor2/factor1;
  offset := (offset2 - offset1)/factor1;
  if rad1 <> rad2 then
    converts := converts and rad1 + hz1 == rad2 + hz2;
    if converts then
      factor := factor*(2*3.14159265358979323846)^intReal(hz2 - hz1);
    end if;
  end if;
end convertUnits;

public function getDerivedUnits
  "The unit symbols that convertUnits converts to and from baseUnit."
  input String baseUnit;
  output list<String> derivedUnits = {};
protected
  Boolean converts;
algorithm
  str2unit(baseUnit, NONE());
  for unit in UnitParserExt.allUnitSymbols() loop
    if not stringEq(baseUnit, unit) then
      (converts, _, _) := convertUnits(baseUnit, unit);
      if converts then
        derivedUnits := unit :: derivedUnits;
      end if;
    end if;
  end for;
end getDerivedUnits;

annotation(__OpenModelica_Interface="frontend");
end UnitAbsynBuilder;
