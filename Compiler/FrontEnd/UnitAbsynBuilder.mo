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

encapsulated package UnitAbsynBuilder

public import UnitAbsyn;
public import DAE;
public import MMath;
public import FCore;
public import HashTable;
public import Absyn;

protected import Array;
protected import BaseHashTable;
protected import ComponentReference;
protected import DAEUtil;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import FNode;
protected import FGraph;
protected import GlobalScriptUtil;
protected import List;
protected import Lookup;
protected import SCode;
protected import SCodeUtil;
protected import Types;
protected import UnitParserExt;
protected import Util;

public function registerUnitWeights "traverses all dae variables and adjusts weights depending on defineunits defined
in the scopes of the classLst for each variable"
  input FCore.Cache cache;
  input FCore.Graph env;
  input DAE.DAElist dae;
 protected
 list<Absyn.Path> paths; list<SCode.Element> du;
algorithm
   _ := matchcontinue(cache,env,dae)
   local
     list<DAE.Element> elts;
   case(_,_,_) equation
       false = Flags.getConfigBool(Flags.UNIT_CHECKING);
   then ();

   case(_,_,DAE.DAE(elementLst=elts)) equation
     /* TODO: This is very unefficient. It increases instantiationtime by factor 2 for
       instantiation of largeTests/TestNandTotal.mo */
       paths = List.unionList(List.map(elts,DAEUtil.getClassList));
       du = List.unionList(List.map1(paths,retrieveUnitsFromEnv,(cache,env)));
       registerUnitWeightDefineunits(du);
   then ();
   end matchcontinue;
end registerUnitWeights;

protected function retrieveUnitsFromEnv "help function to registerUnitWeights"
  input Absyn.Path p;
  input tuple<FCore.Cache,FCore.Graph> tpl;
  output list<SCode.Element> du;

algorithm
   du := matchcontinue(p,tpl)
     local
       FCore.Graph env;
       FCore.Ref r;

     case(_,_) equation
       (_,_,env) = Lookup.lookupClass(Util.tuple21(tpl),Util.tuple22(tpl),p,NONE());
       r = FGraph.lastScopeRef(env);
       // get the defined units node
       r = FNode.child(r, FNode.duNodeName);
       FCore.N(data = FCore.DU(du)) = FNode.fromRef(r);
     then du;
     else {};
  end matchcontinue;
end retrieveUnitsFromEnv;


protected function registerUnitWeightDefineunits "help function to registerUnitWeightForClass"
  input list<SCode.Element> du;
algorithm
   _ := matchcontinue(du)
     /* No defineunits found, for backward compatibility, use default implementation:
     SI system ,with lower cost on Hz and Bq */
     case({}) equation
       registerUnitWeightDefineunits2({
       SCode.DEFINEUNIT("m",SCode.PUBLIC(),NONE(),NONE()),
       SCode.DEFINEUNIT("kg",SCode.PUBLIC(),NONE(),NONE()),
       SCode.DEFINEUNIT("s",SCode.PUBLIC(),NONE(),NONE()),
       SCode.DEFINEUNIT("A",SCode.PUBLIC(),NONE(),NONE()),
       SCode.DEFINEUNIT("k",SCode.PUBLIC(),NONE(),NONE()),
       SCode.DEFINEUNIT("mol",SCode.PUBLIC(),NONE(),NONE()),
       SCode.DEFINEUNIT("cd",SCode.PUBLIC(),NONE(),NONE()),
       SCode.DEFINEUNIT("rad",SCode.PUBLIC(),SOME("m/m"),NONE()),
       SCode.DEFINEUNIT("sr",SCode.PUBLIC(),SOME("m2/m2"),NONE()),
       SCode.DEFINEUNIT("Hz",SCode.PUBLIC(),SOME("s-1"),SOME(0.8)),
       SCode.DEFINEUNIT("N",SCode.PUBLIC(),SOME("m.kg.s-2"),NONE()),
       SCode.DEFINEUNIT("Pa",SCode.PUBLIC(),SOME("N/m2"),NONE()),
       SCode.DEFINEUNIT("W",SCode.PUBLIC(),SOME("J/s"),NONE()),
       SCode.DEFINEUNIT("J",SCode.PUBLIC(),SOME("N.m"),NONE()),
       SCode.DEFINEUNIT("C",SCode.PUBLIC(),SOME("s.A"),NONE()),
       SCode.DEFINEUNIT("V",SCode.PUBLIC(),SOME("W/A"),NONE()),
       SCode.DEFINEUNIT("F",SCode.PUBLIC(),SOME("C/V"),NONE()),
       SCode.DEFINEUNIT("Ohm",SCode.PUBLIC(),SOME("V/A"),NONE()),
       SCode.DEFINEUNIT("S",SCode.PUBLIC(),SOME("A/V"),NONE()),
       SCode.DEFINEUNIT("Wb",SCode.PUBLIC(),SOME("V.s"),NONE()),
       SCode.DEFINEUNIT("T",SCode.PUBLIC(),SOME("Wb/m2"),NONE()),
       SCode.DEFINEUNIT("H",SCode.PUBLIC(),SOME("Wb/A"),NONE()),
       SCode.DEFINEUNIT("lm",SCode.PUBLIC(),SOME("cd.sr"),NONE()),
       SCode.DEFINEUNIT("lx",SCode.PUBLIC(),SOME("lm/m2"),NONE()),
       SCode.DEFINEUNIT("Bq",SCode.PUBLIC(),SOME("s-1"),SOME(0.8)),
       SCode.DEFINEUNIT("Gy",SCode.PUBLIC(),SOME("J/kg"),NONE()),
       SCode.DEFINEUNIT("Sv",SCode.PUBLIC(),SOME("cd.sr"),NONE()),
       SCode.DEFINEUNIT("kat",SCode.PUBLIC(),SOME("s-1.mol"),NONE())
       });   then ();
     else equation registerUnitWeightDefineunits2(du); then ();
  end matchcontinue;
end registerUnitWeightDefineunits;


protected function registerUnitWeightDefineunits2 "help function to registerUnitWeightDefineunits"
  input list<SCode.Element> idu;
algorithm
   _ := matchcontinue(idu)
     local String n; Real w; list<SCode.Element> du;
     case(SCode.DEFINEUNIT(name=n,weight = SOME(w))::du) equation
       UnitParserExt.registerWeight(n,w);
       registerUnitWeightDefineunits2(du);
     then ();
     case(SCode.DEFINEUNIT(weight = NONE())::du) equation
       registerUnitWeightDefineunits2(du);
     then ();
     case(_::du) equation
       registerUnitWeightDefineunits2(du);
     then ();
     case({}) then ();

  end matchcontinue;
end registerUnitWeightDefineunits2;

public function registerUnits "traverses the Absyn.Program and registers all defineunits.
Note: this requires that instantiation is done on a 'total program', so only defineunits that
are referenced in the model are picked up
"
  input Absyn.Program prg;
algorithm
  _ := matchcontinue(prg)
    case _
      equation
        true = Flags.getConfigBool(Flags.UNIT_CHECKING);
        ((_,_,_)) = GlobalScriptUtil.traverseClasses(prg,NONE(),registerUnitInClass,0,false); // defineunits must be in public section.
      then ();

    else
      equation
        false = Flags.getConfigBool(Flags.UNIT_CHECKING);
      then ();
  end matchcontinue;
end registerUnits;

protected function registerUnitInClass " help function to registerUnits"
  input tuple<Absyn.Class,Option<Absyn.Path>,Integer> inTpl;
  output tuple<Absyn.Class,Option<Absyn.Path>,Integer> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local Absyn.Class cl;
    Option<Absyn.Path> pa;
    Integer i;
    list<Absyn.Element> defunits;
    list<Absyn.ElementItem> elts;
    String n;
    case((cl as Absyn.CLASS(),pa,i)) equation
      elts = Absyn.getElementItemsInClass(cl);
      defunits = Absyn.getDefineUnitsInElements(elts);
      registerDefineunits(defunits);
    then ((cl,pa,i));
    case((cl,pa,i)) then ((cl,pa,i));
  end matchcontinue;
end registerUnitInClass;

protected function registerDefineunits "help function to registerUnitInClass"
  input list<Absyn.Element> elts;
algorithm
   _ := matchcontinue(elts)
   local String name; list<Absyn.NamedArg> args; Absyn.Element du;
     String exp; Real weight;
     case({})
     equation registerDefineunits2({
       Absyn.DEFINEUNIT("m",{}),
       Absyn.DEFINEUNIT("kg",{}),
       Absyn.DEFINEUNIT("s",{}),
       Absyn.DEFINEUNIT("A",{}),
       Absyn.DEFINEUNIT("k",{}),
       Absyn.DEFINEUNIT("mol",{}),
       Absyn.DEFINEUNIT("cd",{}),
       Absyn.DEFINEUNIT("rad",{Absyn.NAMEDARG("exp",Absyn.STRING("m/m"))}),
       Absyn.DEFINEUNIT("sr",{Absyn.NAMEDARG("exp",Absyn.STRING("m2/m2"))}),
       Absyn.DEFINEUNIT("Hz",{Absyn.NAMEDARG("exp",Absyn.STRING("s-1")),Absyn.NAMEDARG("weight",Absyn.REAL("0.8"))}),
       Absyn.DEFINEUNIT("N",{Absyn.NAMEDARG("exp",Absyn.STRING("m.kg.s-2"))}),
       Absyn.DEFINEUNIT("Pa",{Absyn.NAMEDARG("exp",Absyn.STRING("N/m2"))}),
       Absyn.DEFINEUNIT("W",{Absyn.NAMEDARG("exp",Absyn.STRING("J/s"))}),
       Absyn.DEFINEUNIT("J",{Absyn.NAMEDARG("exp",Absyn.STRING("N.m"))}),
       Absyn.DEFINEUNIT("C",{Absyn.NAMEDARG("exp",Absyn.STRING("s.A"))}),
       Absyn.DEFINEUNIT("V",{Absyn.NAMEDARG("exp",Absyn.STRING("W/A"))}),
       Absyn.DEFINEUNIT("F",{Absyn.NAMEDARG("exp",Absyn.STRING("C/V"))}),
       Absyn.DEFINEUNIT("Ohm",{Absyn.NAMEDARG("exp",Absyn.STRING("V/A"))}),
       Absyn.DEFINEUNIT("S",{Absyn.NAMEDARG("exp",Absyn.STRING("A/V"))}),
       Absyn.DEFINEUNIT("Wb",{Absyn.NAMEDARG("exp",Absyn.STRING("V.s"))}),
       Absyn.DEFINEUNIT("T",{Absyn.NAMEDARG("exp",Absyn.STRING("Wb/m2"))}),
       Absyn.DEFINEUNIT("H",{Absyn.NAMEDARG("exp",Absyn.STRING("Wb/A"))}),
       Absyn.DEFINEUNIT("lm",{Absyn.NAMEDARG("exp",Absyn.STRING("cd.sr"))}),
       Absyn.DEFINEUNIT("lx",{Absyn.NAMEDARG("exp",Absyn.STRING("lm/m2"))}),
       Absyn.DEFINEUNIT("Bq",{Absyn.NAMEDARG("exp",Absyn.STRING("s-1")),Absyn.NAMEDARG("weight",Absyn.REAL("0.8"))}),
       Absyn.DEFINEUNIT("Gy",{Absyn.NAMEDARG("exp",Absyn.STRING("J/kg"))}),
       Absyn.DEFINEUNIT("Sv",{Absyn.NAMEDARG("exp",Absyn.STRING("cd.sr"))}),
       Absyn.DEFINEUNIT("kat",{Absyn.NAMEDARG("exp",Absyn.STRING("s-1.mol"))})
       });
     then ();

     else
       equation
         registerDefineunits2(elts);
       then ();
  end matchcontinue;
end registerDefineunits;

protected function registerDefineunits2 "help function to registerUnitInClass"
  input list<Absyn.Element> elts;
algorithm
   _ := matchcontinue(elts)
     local
       String exp,name;
       list<Absyn.NamedArg> args;
       Absyn.Element du;
       Real weight;
       list<Absyn.Element> rest;

     case {} then ();
     /* Derived unit with weigth */
     /*case((du as Absyn.DEFINEUNIT(name=_))::elts) equation
       {SCode.DEFINEUNIT(name,SOME(exp),_)} = SCodeUtil.translateElement(du,false);
       UnitParserExt.addDerivedWeight(name,exp,weight);
       registerDefineunits(elts);
     then ();*/

     /* Derived unit without weigth */
     case ((du as Absyn.DEFINEUNIT())::rest)
       equation
         {SCode.DEFINEUNIT(name,_,SOME(exp),_)} = SCodeUtil.translateElement(du,SCode.PUBLIC());
         UnitParserExt.addDerived(name,exp);
         registerDefineunits2(rest);
       then ();

       /* base unit does not not have weight*/
     case((du as Absyn.DEFINEUNIT())::rest)
       equation
         {SCode.DEFINEUNIT(name,_,NONE(),_)} = SCodeUtil.translateElement(du,SCode.PUBLIC());
         UnitParserExt.addBase(name);
         registerDefineunits2(rest);
       then ();

     else
       equation
         print("registerDefineunits failed\n");
       then fail();
  end matchcontinue;
end registerDefineunits2;

public function add "Adds a unit to the UnitAbsyn.Store"
  input UnitAbsyn.Unit unit;
  input UnitAbsyn.Store ist;
  output UnitAbsyn.Store outSt;
  output Integer index;
algorithm
  (outSt,index) := matchcontinue(unit,ist)
    local array<Option<UnitAbsyn.Unit>> vector; Integer newIndx,numElts; UnitAbsyn.Store st;
    case(_,st as UnitAbsyn.STORE(storeVector=vector,numElts = numElts)) equation
      true = numElts == arrayLength(vector);
      st = expandStore(st);
      (st,index) = add(unit,st);
    then (st,index);
    case(_,UnitAbsyn.STORE(storeVector=vector,numElts = numElts)) equation
      newIndx = numElts+1;
      vector = arrayUpdate(vector,newIndx,SOME(unit));
    then (UnitAbsyn.STORE(vector,newIndx),newIndx);
  end matchcontinue;
end add;

public function updateInstStore "  "
  input UnitAbsyn.InstStore store;
  input UnitAbsyn.Store st;
  output UnitAbsyn.InstStore outStore;
algorithm
  outStore := match(store,st)
  local HashTable.HashTable ht; Option<UnitAbsyn.UnitCheckResult> res;
    case(UnitAbsyn.INSTSTORE(_,ht,res),_) then UnitAbsyn.INSTSTORE(st,ht,res);
    case(UnitAbsyn.NOSTORE(),_) then UnitAbsyn.NOSTORE();
  end match;
end updateInstStore;

protected function expandStore "Expands store to make room for more entries.
Expansion factor: 1.4
"
  input UnitAbsyn.Store st;
  output UnitAbsyn.Store outSt;
algorithm
  outSt := match(st)
  local array<Option<UnitAbsyn.Unit>> vector; Integer indx,incr;
    case(UnitAbsyn.STORE(vector,indx)) equation
        incr = intMin(1,realInt(intReal(indx) * 0.4));
        vector = Array.expand(incr,vector,NONE());
     then UnitAbsyn.STORE(vector,indx);
  end match;
end expandStore;


public function update "Updates  unit at index in UnitAbsyn.Store"
  input UnitAbsyn.Unit unit;
  input Integer index;
  input UnitAbsyn.Store st;
  output UnitAbsyn.Store outSt;
algorithm
  outSt := matchcontinue(unit,index,st)
  local array<Option<UnitAbsyn.Unit>> vector; Integer indx;
    case(_,_,UnitAbsyn.STORE(vector,indx)) equation
      vector = arrayUpdate(vector,index,SOME(unit)) "destroys ";
    then UnitAbsyn.STORE(vector,indx);

    else equation
      print("storing unit at index ");print(intString(index));print(" failed\n");
    then fail();
  end matchcontinue;
end update;

public function find "finds a unit in the UnitAbsyn.Store given an index"
  input Integer index;
  input UnitAbsyn.Store st;
  output UnitAbsyn.Unit unit;
algorithm
  unit := matchcontinue(index,st)
    local
      array<Option<UnitAbsyn.Unit>> vector;
      Integer indx;
    case(_,UnitAbsyn.STORE(vector,_)) equation
      SOME(unit) = vector[index];
    then unit;
    else equation
      print(" finding store at index ");print(intString(index));
      print(" failed\n");
    then fail();
  end matchcontinue;
end find;

public function instGetStore "Retrives the Store from an InstStore"
  input UnitAbsyn.InstStore store;
  output UnitAbsyn.Store st;
algorithm
  st := match(store)
    case(UnitAbsyn.INSTSTORE(st,_,_)) then st;
    case(UnitAbsyn.NOSTORE()) then emptyStore();
  end match;
end instGetStore;

public function emptyInstStore "returns an empty InstStore"
  output UnitAbsyn.InstStore st;
algorithm
  st := emptyInstStore2(Flags.getConfigBool(Flags.UNIT_CHECKING));
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
      equation
        s = emptyStore();
        ht = HashTable.emptyHashTable();
      then UnitAbsyn.INSTSTORE(s,ht,NONE());
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

public function printTerms "print the terms to stdout"
input UnitAbsyn.UnitTerms terms;
algorithm
  print(printTermsStr(terms));
end printTerms;

public function printTermsStr "print the terms to a string"
  input UnitAbsyn.UnitTerms terms;
  output String str;
algorithm
  str := "{" + stringDelimitList(List.map(terms,printTermStr),",") + "}";
end printTermsStr;

public function printTermStr "print one term to a string"
  input UnitAbsyn.UnitTerm term;
  output String str;
algorithm
  str := match(term)
  local UnitAbsyn.UnitTerm ut1,ut2; String s1;
    Integer i,i1,i2;
    DAE.Exp e;
    case(UnitAbsyn.ADD(_,_,e)) equation
      s1 = ExpressionDump.printExpStr(e);
    then s1;

    case(UnitAbsyn.SUB(_,_,e)) equation
      s1 = ExpressionDump.printExpStr(e);
    then s1;

    case(UnitAbsyn.MUL(_,_,e)) equation
      s1 = ExpressionDump.printExpStr(e);
    then s1;

    case(UnitAbsyn.DIV(_,_,e)) equation
      s1 = ExpressionDump.printExpStr(e);
    then s1;

    case(UnitAbsyn.EQN(_,_,e)) equation
      s1 = ExpressionDump.printExpStr(e);
    then s1;

    case(UnitAbsyn.LOC(_,e)) equation
    s1 = ExpressionDump.printExpStr(e);
    then s1;

    case(UnitAbsyn.POW(_,MMath.RATIONAL(_,_),e)) equation
      s1 = ExpressionDump.printExpStr(e);
    then s1;

  end match;
end printTermStr;

public function printInstStore "prints the inst store to stdout"
input UnitAbsyn.InstStore st;
algorithm
  _ := match(st)
  local UnitAbsyn.Store s; HashTable.HashTable h;
    case(UnitAbsyn.INSTSTORE(s,h,_)) equation
      print("instStore, s:");
      printStore(s);
      print("\nht:");
      BaseHashTable.dumpHashTable(h);
    then ();
    case(UnitAbsyn.NOSTORE()) then ();
  end match;
end printInstStore;

public function printStore "prints the store to stdout"
input UnitAbsyn.Store st;
algorithm
  _ := match(st)
  local array<Option<UnitAbsyn.Unit>> vector; Integer indx;
    list<Option<UnitAbsyn.Unit>> lst;
    case(UnitAbsyn.STORE(vector,_)) equation
      lst = arrayList(vector);
      printStore2(lst,1);
   then ();
  end match;
end printStore;

protected function printStore2 "help function to printStore"
input list<Option<UnitAbsyn.Unit>> lst;
input Integer indx;
algorithm
  _ := match(lst,indx)
    local
      UnitAbsyn.Unit unit;
      list<Option<UnitAbsyn.Unit>> rest;
    case({},_) then ();

    case(SOME(unit)::rest,_) equation
      print(intString(indx));print("->");
      printUnit(unit);
      print("\n");
      printStore2(rest,indx+1);
    then();
    case(NONE()::_,_) then ();
  end match;
end printStore2;

protected function printUnit "prints a unit to stdout (only for debugging)"
input UnitAbsyn.Unit unit;
algorithm
  _ := matchcontinue(unit)
  local list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeparams;
    list<MMath.Rational> baseunits;
    /*case(unit) equation
      print(unit2str(unit));
    then();*/
    case (UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},baseunits))) equation
      print(printBaseUnitsStr(baseunits));
      print(" [");print(unit2str(unit)); print("]");
    then();
    case(UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(typeparams,baseunits))) equation
      print(stringDelimitList(List.map(typeparams,printTypeParameterStr),","));
      print(printBaseUnitsStr(baseunits));
      print(" [");print(unit2str(unit)); print("]");
    then();
    case(UnitAbsyn.UNSPECIFIED()) equation
      print("Unspecified");
    then ();
  end matchcontinue;
end printUnit;

protected function printBaseUnitsStr "help function to printUnit"
  input list<MMath.Rational> lst;
  output String str;
algorithm
  str := matchcontinue(lst)
  local Integer i1,i2,i3,i4;
    case(MMath.RATIONAL(i1,i2)::MMath.RATIONAL(i3,i4)::_) equation
    str = "m^("+intString(i1)+"/"+intString(i2)+")"
    +  "s^("+intString(i3)+"/"+intString(i4)+")" ;
    then str;
    case({}) then "";
    else "printBaseUnitsStr failed len:" + intString(listLength(lst)) + "\n";
  end matchcontinue;
end printBaseUnitsStr;

protected function printTypeParameterStr "help function to printUnit"
  input tuple<MMath.Rational,UnitAbsyn.TypeParameter> typeParam;
  output String str;
algorithm
  str := match(typeParam)
  local String name; Integer i1,i2,i3,indx;
    case((MMath.RATIONAL(0,0),UnitAbsyn.TYPEPARAMETER(name,indx))) equation
      str = name + "[indx =" + intString(indx) + "]";
      then str;
    case((MMath.RATIONAL(i1,1),UnitAbsyn.TYPEPARAMETER(name,indx))) equation
      str = name + "^" + intString(i1) + "[indx=" + intString(indx) + "]";
    then str;
    case((MMath.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(name,indx))) equation
      str = name+ "^("+ intString(i1) + "/" + intString(i2)+")" + "[indx=" + intString(indx) + "]";
    then str;
  end match;
end printTypeParameterStr;

public function splitRationals "splits a list of Rationals into a list of numerators and denominators"
  input list<MMath.Rational> inRationals;
  output list<Integer> nums;
  output list<Integer> denoms;
algorithm
  (nums,denoms) := match(inRationals)
    local Integer i1,i2; list<MMath.Rational> rationals;
    case({}) then ({},{});
    case(MMath.RATIONAL(i1,i2)::rationals) equation
      (nums,denoms) = splitRationals(rationals);
    then (i1::nums,i2::denoms);
  end match;
end splitRationals;

public function joinRationals "joins a lists of numerators and denominators into list of Rationals"
  input list<Integer> inums;
  input list<Integer> idenoms;
  output list<MMath.Rational> rationals;
algorithm
  (rationals) := match(inums,idenoms)
    local Integer i1,i2; list<Integer> nums,denoms;
    case({},{}) then ({});
    case(i1::nums,i2::denoms) equation
      rationals = joinRationals(nums,denoms);
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
  typeParams := match(inums,idenoms,itpstrs,funcInstIdOpt)
    local Integer i1,i2; String tpParam,s; list<Integer> nums, denoms; list<String> tpstrs;
    case({},{},{},_) then {};
    case(i1::nums,i2::denoms,tpParam::tpstrs,_) equation
      typeParams = joinTypeParams(nums,denoms,tpstrs,funcInstIdOpt);
      s = Util.stringOption(Util.applyOption(funcInstIdOpt,intString));
      tpParam = tpParam + s;
    then (MMath.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(tpParam,0))::typeParams;
  end match;
end joinTypeParams;

public function splitTypeParams "splits type parameter lists into numerators, denominators and typeparameter names"
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> iTypeParams;
  output list<Integer> nums;
  output list<Integer> denoms;
  output list<String> tpstrs;
algorithm
  (nums,denoms,tpstrs) := match(iTypeParams)
    local String tpParam; Integer i1,i2; list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
    case({}) then ({},{},{});
    case((MMath.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(tpParam,_))::typeParams) equation
      (nums,denoms,tpstrs) = splitTypeParams(typeParams);
    then (i1::nums,i2::denoms,tpParam::tpstrs);
  end match;
end splitTypeParams;

public function instBuildUnitTerms "builds unit terms and stores for a DAE. It also returns a hashtable that maps
variable names to store locations."
  input FCore.Graph env;
  input DAE.DAElist dae;
  input DAE.DAElist compDae "to collect variable bindings";
  input UnitAbsyn.InstStore store;
  output UnitAbsyn.InstStore outStore;
  output UnitAbsyn.UnitTerms terms;
algorithm
  (outStore,terms) := matchcontinue(env,dae,compDae,store)
    local
      UnitAbsyn.Store st;
      HashTable.HashTable ht;
      UnitAbsyn.UnitTerms terms2;
      Option<UnitAbsyn.UnitCheckResult> res;
    case (_,_,_,UnitAbsyn.NOSTORE()) then  (UnitAbsyn.NOSTORE(),{});
    case(_,_,_,UnitAbsyn.INSTSTORE(st,ht,res))
      equation
        (terms,st) = buildTerms(env,dae,ht,st);
        (terms2,st) = buildTerms(env,compDae,ht,st) "to get bindings of scalar variables";
        terms = listAppend(terms,terms2);
        //print("built terms, store :"); printStore(st);
        //print("ht =");BaseHashTable.dumpHashTable(ht);
        st = createTypeParameterLocations(st);
        // print("built type param, store :"); printStore(st);
        terms = listReverse(terms);
     then (UnitAbsyn.INSTSTORE(st,ht,res),terms);
    else equation
      print("instBuildUnitTerms failed!!\n");
    then fail();
  end matchcontinue;
end instBuildUnitTerms;


public function buildUnitTerms "builds unit terms and stores for a DAE. It also returns a hashtable that maps
variable names to store locations."
  input FCore.Graph env;
  input DAE.DAElist dae;
  output UnitAbsyn.UnitTerms terms;
  output UnitAbsyn.Store store;
  output HashTable.HashTable ht;
algorithm
  (store,ht) := buildStores(dae);
  (terms,store) := buildTerms(env,dae,ht,store);
  store := createTypeParameterLocations(store);
end buildUnitTerms;

public function instAddStore "Called when instantiating a Real class"
  input UnitAbsyn.InstStore istore;
  input DAE.Type itp;
  input DAE.ComponentRef cr;
  output UnitAbsyn.InstStore outStore;
algorithm
  outStore := matchcontinue(istore,itp,cr)
    local
      UnitAbsyn.Store st;
      HashTable.HashTable ht;
      String unitStr;
      UnitAbsyn.Unit unit; Integer indx;
      DAE.TypeSource ts;
      list<DAE.Var> vs;
      Option<UnitAbsyn.UnitCheckResult> res;
      UnitAbsyn.InstStore store;
      DAE.Type tp;

    case(UnitAbsyn.NOSTORE(),_,_)
      then istore;

    case(UnitAbsyn.INSTSTORE(st,ht,res),DAE.T_REAL(varLst = DAE.TYPES_VAR(name="unit",binding = DAE.EQBOUND(exp=DAE.SCONST(unitStr)))::_),_)
      equation
        unit = str2unit(unitStr,NONE());
        unit = if 0 == stringCompare(unitStr,"") then UnitAbsyn.UNSPECIFIED() else unit;
        (st,indx) = add(unit,st);
        ht = BaseHashTable.add((cr,indx),ht);
      then UnitAbsyn.INSTSTORE(st,ht,res);
    case(store,DAE.T_REAL(_::vs,ts),_)
     then instAddStore(store,DAE.T_REAL(vs,ts),cr);

      /* No unit available. */
    case(UnitAbsyn.INSTSTORE(st,ht,res),DAE.T_REAL(varLst = {}),_)
      equation
        (st,indx) = add(UnitAbsyn.UNSPECIFIED(),st);
        ht = BaseHashTable.add((cr,indx),ht);
      then UnitAbsyn.INSTSTORE(st,ht,res);

    case(store,DAE.T_SUBTYPE_BASIC(complexType=tp),_)
      then instAddStore(store,tp,cr);
    else istore;
  end matchcontinue;
end instAddStore;

public function storeSize "return the number of elements of the store"
input UnitAbsyn.Store store;
output Integer size;
algorithm
  size := match(store)
    case(UnitAbsyn.STORE(_,size)) then size;
  end match;
end storeSize;

protected function createTypeParameterLocations "for each unique type parameter, create an UNSPECIFIED unit
and add to the store."
  input UnitAbsyn.Store store;
  output UnitAbsyn.Store outStore;
protected
  Integer nextElement, storeSz;
algorithm
  storeSz := storeSize(store);
  (outStore,_,nextElement) := createTypeParameterLocations2(store,HashTable.emptyHashTable(),1,storeSz+1);
   outStore := addUnspecifiedStores((nextElement -storeSz) -1,outStore);
end createTypeParameterLocations;

protected function addUnspecifiedStores " adds n unspecified"
  input Integer n;
  input UnitAbsyn.Store istore;
  output UnitAbsyn.Store outStore;
algorithm
  outStore := matchcontinue(n,istore)
    local UnitAbsyn.Store store;
    case(0,store) then store;
    case(_,_) equation
      true = n < 0;
      print("addUnspecifiedStores n < 0!\n");
    then fail();
    case(_,store) equation
      true = n > 0;
      (store,_) = add(UnitAbsyn.UNSPECIFIED(),store);
      store = addUnspecifiedStores(n-1,store);
    then store;
  end matchcontinue;
end addUnspecifiedStores;

protected function createTypeParameterLocations2 "help function"
  input UnitAbsyn.Store istore;
  input HashTable.HashTable iht;
  input Integer i "iterated";
  input Integer inextElt;
  output UnitAbsyn.Store outStore;
  output HashTable.HashTable outHt;
  output Integer outNextElt;
algorithm
  (outStore,outHt,outNextElt) := matchcontinue(istore,iht,i,inextElt)
    local
      Integer numElts;
      array<Option<UnitAbsyn.Unit>> vect;
      UnitAbsyn.Unit unit;
      UnitAbsyn.Store store;
      HashTable.HashTable ht;
      Integer nextElt;

    case(store as UnitAbsyn.STORE(_,numElts),ht,_,nextElt) equation
      true = i > numElts;
     then (store,ht,nextElt);

    case(UnitAbsyn.STORE(vect,numElts),ht,_,nextElt) equation
      SOME(unit) = vect[i];
      (unit,ht,nextElt) = createTypeParameterLocations3(unit,ht,nextElt);
      vect = arrayUpdate(vect,i,SOME(unit));
      (store,ht,nextElt) = createTypeParameterLocations2(UnitAbsyn.STORE(vect,numElts),ht,i+1,nextElt);
    then (store,ht,nextElt);

    case(UnitAbsyn.STORE(vect,numElts),ht,_,nextElt) equation
      (store,ht,nextElt) = createTypeParameterLocations2(UnitAbsyn.STORE(vect,numElts),ht,i+1,nextElt);
    then (store,ht,nextElt);
  end matchcontinue;
end createTypeParameterLocations2;

protected function createTypeParameterLocations3 "help function to createTypeParameterLocations2"
  input UnitAbsyn.Unit unit;
  input HashTable.HashTable iht;
  input Integer inextElt;
  output UnitAbsyn.Unit outUnit;
  output HashTable.HashTable outHt;
  output Integer outNextElt;
algorithm
  (outUnit,outHt,outNextElt) := match(unit,iht,inextElt)
    local
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> params;
      list<MMath.Rational> units;
      HashTable.HashTable ht;
      Integer nextElt;

    // Only succeeds for units with type parameters
    case(UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(params as _::_,units)),ht,nextElt) equation
      (params,ht,nextElt) = createTypeParameterLocations4(params,ht,nextElt);
     then (UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(params,units)),ht,nextElt);
  end match;
end createTypeParameterLocations3;

protected function createTypeParameterLocations4 "help function to createTypeParameterLocations3"
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> iparams;
  input HashTable.HashTable iht;
  input Integer inextElt;
  output list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> outParams;
  output HashTable.HashTable outHt;
  output Integer outNextElt;
algorithm
  (outParams,outHt,outNextElt) := matchcontinue(iparams,iht,inextElt)
    local
      Integer indx; String name; MMath.Rational r;
      tuple<MMath.Rational,UnitAbsyn.TypeParameter> param;
      DAE.ComponentRef cref_;
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> params;
      HashTable.HashTable ht;
      Integer nextElt;

    case({},ht,nextElt) then ({},ht,nextElt);

    case((r,UnitAbsyn.TYPEPARAMETER(name,0))::params,ht,nextElt) equation
      cref_ = ComponentReference.makeCrefIdent(name,DAE.T_UNKNOWN_DEFAULT,{});
      indx = BaseHashTable.get(cref_,ht);
      (params,ht,nextElt) = createTypeParameterLocations4(params,ht,nextElt);
    then ((r,UnitAbsyn.TYPEPARAMETER(name,indx))::params,ht,nextElt);

    case((r,UnitAbsyn.TYPEPARAMETER(name,0))::params,ht,nextElt) equation
        cref_ = ComponentReference.makeCrefIdent(name,DAE.T_UNKNOWN_DEFAULT,{});
        ht = BaseHashTable.add((cref_,nextElt),ht);
       (params,ht,nextElt) = createTypeParameterLocations4(params,ht,nextElt);
    then((r,UnitAbsyn.TYPEPARAMETER(name,nextElt))::params,ht,nextElt+1);

    case(param::params,ht,nextElt) equation
       (params,ht,nextElt) = createTypeParameterLocations4(params,ht,nextElt);
    then(param::params,ht,nextElt);
    else equation
      print("createTypeParameterLocations4 failed\n");
    then fail();
  end matchcontinue;
end createTypeParameterLocations4;

protected function buildStores "builds the stores and creates a hashtable from variable names to store locations"
  input DAE.DAElist dae;
  output UnitAbsyn.Store store;
  output HashTable.HashTable ht;
algorithm
  (store,ht) := buildStores2(dae,emptyStore(),HashTable.emptyHashTable()) "Build stores from variables";
  (store,ht) := buildStores3(dae,store,ht) "build stores from constants and function calls in expressions";
end buildStores;

protected function buildTerms "builds the unit terms from DAE elements (equations)"
  input FCore.Graph env;
  input DAE.DAElist dae;
  input HashTable.HashTable ht;
  input UnitAbsyn.Store istore;
  output UnitAbsyn.UnitTerms terms;
  output UnitAbsyn.Store outStore;
algorithm
  (terms,outStore) := matchcontinue(env,dae,ht,istore)
    local
      DAE.Exp e1,e2,crefExp1,crefExp2;
      UnitAbsyn.UnitTerm ut1,ut2;
      list<UnitAbsyn.UnitTerm> terms1,terms2;
      DAE.ComponentRef cr1,cr2;
      list<DAE.Element> elts;
      UnitAbsyn.Store store;

    case (_,DAE.DAE(elementLst={}),_,store) then ({},store);

    case(_,DAE.DAE(elementLst=DAE.EQUATION(e1,e2,_)::elts),_,store) equation
      (ut1,terms1,store) = buildTermExp(env,e1,false,ht,store);
      (ut2,terms2,store) = buildTermExp(env,e2,false,ht,store);
      (terms,store) = buildTerms(env,DAE.DAE(elts),ht,store);
      terms = listAppend(terms1,listAppend(terms2,terms));
    then  (UnitAbsyn.EQN(ut1,ut2,DAE.BINARY(e1,DAE.SUB(DAE.T_REAL_DEFAULT),e2))::terms,store);

    case(_,DAE.DAE(elementLst=DAE.EQUEQUATION(cr1,cr2,_)::elts),_,store) equation
      crefExp1 = Expression.crefExp(cr1);
      crefExp2 = Expression.crefExp(cr2);
      (ut1,terms1,store) = buildTermExp(env,crefExp1,false,ht,store);
      (ut2,terms2,store) = buildTermExp(env,crefExp2,false,ht,store);
      (terms,store) = buildTerms(env,DAE.DAE(elts),ht,store);
      terms = listAppend(terms1,listAppend(terms2,terms));
    then
      (UnitAbsyn.EQN(ut1,ut2,DAE.BINARY(crefExp1,DAE.SUB(DAE.T_REAL_DEFAULT),crefExp2))::terms,store);

      /* Only consider variables with binding from this instance level, not furhter down */
    case(_,DAE.DAE(elementLst=DAE.VAR(componentRef=cr1 as DAE.CREF_IDENT(_,_,_),binding = SOME(e1))::elts),_,store) equation
      crefExp1 = Expression.crefExp(cr1);
      (ut1,terms1,store) = buildTermExp(env,crefExp1,false,ht,store);
      (ut2,terms2,store) = buildTermExp(env,e1,false,ht,store);
      (terms,store) = buildTerms(env,DAE.DAE(elts),ht,store);
      terms = listAppend(terms1,listAppend(terms2,terms));
    then
      (UnitAbsyn.EQN(ut1,ut2,DAE.BINARY(crefExp1,DAE.SUB(DAE.T_REAL_DEFAULT),e1))::terms,store);

    case(_,DAE.DAE(elementLst=DAE.DEFINE(cr1,e1,_)::elts),_,store) equation
      crefExp1 = Expression.crefExp(cr1);
      (ut1,terms1,store) = buildTermExp(env,crefExp1,false,ht,store);
      (ut2,terms2,store) = buildTermExp(env,e1,false,ht,store);
      (terms,store) = buildTerms(env,DAE.DAE(elts),ht,store);
      terms = listAppend(terms1,listAppend(terms2,terms));
    then
      (UnitAbsyn.EQN(ut1,ut2,DAE.BINARY(crefExp1,DAE.SUB(DAE.T_REAL_DEFAULT),e1))::terms,store);

    case(_,DAE.DAE(elementLst=_::elts),_,store) equation
      (terms,store) = buildTerms(env,DAE.DAE(elts),ht,store);
      then (terms,store);
  end matchcontinue;
end buildTerms;

protected function buildTermExp "help function to buildTerms, handles expressions"
  input FCore.Graph env;
  input DAE.Exp exp;
  input Boolean idivOrMul "is true if surrounding expression is division or multiplication. In that case
   the constant will be treated as dimensionless, otherwise it will be treated as unspecified
  ";
  input HashTable.HashTable iht;
  input UnitAbsyn.Store istore;
  output UnitAbsyn.UnitTerm ut;
  output list<UnitAbsyn.UnitTerm> extraTerms "additional terms from e.g. function calls";
  output UnitAbsyn.Store outStore;
algorithm
  (ut,extraTerms,outStore) := matchcontinue(env,exp,idivOrMul,iht,istore)
    local
      Real r;
      DAE.Operator op;
      Integer indx,i;
      UnitAbsyn.UnitTerm ut1,ut2;
      String s1;
      DAE.ComponentRef cr;
      DAE.Exp e,e1,e2;
      Absyn.Path path;
      list<list<DAE.Exp>> mexpl;
      list<UnitAbsyn.UnitTerm> terms1,terms2,terms,uts;
      list<DAE.Exp> expl;
      UnitAbsyn.Unit u;
      HashTable.HashTable ht;
      UnitAbsyn.Store store;
      Boolean divOrMul;

    /*case(env,e as DAE.RCONST(r),ht,store) equation
      s1 = realString(r);
      indx = BaseHashTable.get(ComponentReference.makeCrefIdent(s1,DAE.T_UNKNOWN_DEFAULT,{}),ht);
    then (UnitAbsyn.LOC(indx,e),{},store);*/

    case(_,e as DAE.ICONST(i),divOrMul,ht,store) equation
      s1 = "$"+intString(tick())+"_"+intString(i);
      u = if divOrMul then str2unit("1",NONE()) else UnitAbsyn.UNSPECIFIED();
      (store,indx) = add(u,store);
       ht = BaseHashTable.add((ComponentReference.makeCrefIdent(s1,DAE.T_UNKNOWN_DEFAULT,{}),indx),ht);
    then (UnitAbsyn.LOC(indx,e),{},store);

    /* for each constant, add new unspecified unit*/
    case(_,e as DAE.RCONST(r),divOrMul,ht,store)equation
      s1 = "$"+intString(tick())+"_"+realString(r);
      u = if divOrMul then str2unit("1",NONE()) else UnitAbsyn.UNSPECIFIED();
      (store,indx) = add(u,store);
       ht = BaseHashTable.add((ComponentReference.makeCrefIdent(s1,DAE.T_UNKNOWN_DEFAULT,{}),indx),ht);
    then (UnitAbsyn.LOC(indx,e),{},store);

    case(_,DAE.CAST(_,e1),divOrMul,ht,store) equation
      (ut,terms,store) = buildTermExp(env,e1,divOrMul,ht,store);
    then (ut,terms,store);

    case(_,e as DAE.CREF(cr,_),_,ht,store) equation
     indx = BaseHashTable.get(cr,ht);
    then (UnitAbsyn.LOC(indx,e),{},store);

    /* special case for pow */
    case(_,e as DAE.BINARY(e1,DAE.POW(_),e2 as DAE.ICONST(i)),divOrMul,ht,store)
      equation
        (ut1,terms1,store) = buildTermExp(env,e1,divOrMul,ht,store);
        (_,terms2,store) = buildTermExp(env,e2,divOrMul,ht,store);
        terms = listAppend(terms1,terms2);
        ut = UnitAbsyn.POW(ut1,MMath.RATIONAL(i,1),e);
    then (ut,terms,store);

    case(_,e as DAE.BINARY(e1,DAE.POW(_),e2 as DAE.RCONST(r)),divOrMul,ht,store)
      equation
        (ut1,terms1,store) = buildTermExp(env,e1,divOrMul,ht,store);
        (_,terms2,store) = buildTermExp(env,e2,divOrMul,ht,store);
        terms = listAppend(terms1,terms2);
        i = realInt(r);
        true = intReal(i) - r == 0.0;
        ut = UnitAbsyn.POW(ut1,MMath.RATIONAL(i,1),e);
    then (ut,terms,store);

    case(_,e as DAE.BINARY(e1,op,e2),divOrMul,ht,store) equation
      divOrMul = Expression.operatorDivOrMul(op);
      (ut1,terms1,store) = buildTermExp(env,e1,divOrMul,ht,store);
      (ut2,terms2,store) = buildTermExp(env,e2,divOrMul,ht,store);
      terms = listAppend(terms1,terms2);
      ut = buildTermOp(ut1,ut2,op,e);
    then (ut,terms,store);

      /* failed to build term for e2, use e1*/
    case(_,DAE.BINARY(e1,op,_),divOrMul,ht,store) equation
      divOrMul = Expression.operatorDivOrMul(op);
      (ut,terms,store) = buildTermExp(env,e1,divOrMul,ht,store);
      failure((_,_,_) = buildTermExp(env,e1,divOrMul,ht,store));
    then (ut,terms,store);

      /* failed to build term for e1, use e2*/
    case(_,DAE.BINARY(e1,op,e2),divOrMul,ht,store) equation
      divOrMul = Expression.operatorDivOrMul(op);
      failure((_,_,_) = buildTermExp(env,e1,divOrMul,ht,store));
      (ut,terms,store) = buildTermExp(env,e2,divOrMul,ht,store);
    then (ut,terms,store);

    case(_,DAE.UNARY(_,e1),divOrMul,ht,store) equation
      (ut,terms,store) = buildTermExp(env,e1,divOrMul,ht,store);
    then (ut,terms,store);

    case(_,e as DAE.IFEXP(_,e1,e2),divOrMul,ht,store) equation
      divOrMul = false;
      (ut1,terms1,store) = buildTermExp(env,e1,divOrMul,ht,store);
      (ut2,terms2,store) = buildTermExp(env,e2,divOrMul,ht,store);
      terms = listAppend(terms1,terms2);
    then (UnitAbsyn.EQN(ut1,ut2,e),terms,store);

    /* function call */
    case(_,e as DAE.CALL(path=path,expLst=expl),divOrMul,ht,store) equation
      divOrMul = false;
      (ut,terms,store) = buildTermCall(env,path,e,expl,divOrMul,ht,store);
    then  (ut,terms,store);

    /* Array, all elements must be of same dimension, since an array with different units in different positions
    can not be declared in Modelica, since modifiers on arrays must affect the whole array */
    case(_,e as DAE.ARRAY(_,_,expl),_,ht,store)
      equation
        print("vector ="+ExpressionDump.printExpStr(e)+"\n");
      (uts,terms,store) = buildTermExpList(env,expl,ht,store);
      ut::uts = buildArrayElementTerms(uts,expl);
      terms = listAppend(terms,uts);
    then (ut,terms,store);

    case(_,e as DAE.MATRIX(matrix=mexpl),_,ht,store)
      equation
        print("Matrix ="+ExpressionDump.printExpStr(e)+"\n");
        expl = List.flatten(mexpl);
        (uts,terms,store) = buildTermExpList(env,expl,ht,store);
        ut::uts = buildArrayElementTerms(uts,expl);
        terms = listAppend(terms,uts);
      then (ut,terms,store);

    case(_,e as DAE.CALL(),_,_,_) equation
      print("buildTermDAE.CALL failed exp: "+ExpressionDump.printExpStr(e)+"\n");
    then fail();
  end matchcontinue;
end buildTermExp;

protected function buildArrayElementTerms "help function to buildTermExpression. For each two terms from an array expression, it create
and EQN to make the constraint that they must have the same unit"
  input list<UnitAbsyn.UnitTerm> iuts;
  input list<DAE.Exp> iexpl;
  output list<UnitAbsyn.UnitTerm> outUts;
algorithm
  outUts := match(iuts,iexpl)
    local
      UnitAbsyn.UnitTerm ut1,ut2;
      DAE.Type ty; DAE.Exp e1,e2;
      list<UnitAbsyn.UnitTerm> uts;
      list<DAE.Exp> expl;

    case({},_) then  {};
    case(uts as {_},_) then uts;
    case(ut1::ut2::uts,e1::e2::expl) equation
      uts = buildArrayElementTerms(uts,expl);
      ty = Expression.typeof(e1);
      uts = listAppend(uts,{UnitAbsyn.EQN(ut1,ut2,DAE.ARRAY(ty,true,{e1,e2}))});
    then uts;
  end match;
end  buildArrayElementTerms;

protected function buildTermCall "builds a term and additional terms from a function call"
  input FCore.Graph env;
  input Absyn.Path path;
  input DAE.Exp funcCallExp;
  input list<DAE.Exp> expl;
  input Boolean divOrMul;
  input HashTable.HashTable ht;
  input UnitAbsyn.Store istore;
  output UnitAbsyn.UnitTerm ut;
  output list<UnitAbsyn.UnitTerm> extraTerms "additional terms from e.g. function calls";
  output UnitAbsyn.Store outStore;
algorithm
  (ut,extraTerms,outStore) := match(env,path,funcCallExp,expl,divOrMul,ht,istore)
    local
      list<Integer> formalParamIndxs;
      Integer funcInstId;
      list<UnitAbsyn.UnitTerm> actTermLst,terms,terms2,extraTerms2;
      DAE.Type functp;
      UnitAbsyn.Store store;

    case(_,_,_,_,_,_,store) equation
       (_,functp,_) = Lookup.lookupType(FCore.noCache(),env,path,NONE());
       funcInstId=tick();
       (store,formalParamIndxs) = buildFuncTypeStores(functp,funcInstId,store);
       (actTermLst,extraTerms,store) = buildTermExpList(env,expl,ht,store);
        terms = buildFormal2ActualParamTerms(formalParamIndxs,actTermLst);
        ({ut},extraTerms2,store) = buildResultTerms(functp,funcInstId,funcCallExp,store);
        extraTerms = listAppend(extraTerms,listAppend(extraTerms2,terms));
    then (ut,extraTerms,store);
  end match;
end buildTermCall;

protected function buildResultTerms "build stores and terms for assigning formal output arguments to
new locations"
  input DAE.Type ifunctp;
  input Integer funcInstId;
  input DAE.Exp funcCallExp;
  input UnitAbsyn.Store istore;
  output list<UnitAbsyn.UnitTerm> terms;
  output list<UnitAbsyn.UnitTerm> extraTerms;
  output UnitAbsyn.Store outStore;
algorithm
  (terms,extraTerms,outStore) := matchcontinue(ifunctp,funcInstId,funcCallExp,istore)
    local
      String unitStr; UnitAbsyn.Unit unit; Integer indx,indx2; Boolean unspec;
      list<DAE.Type> typeLst;
      DAE.Type functp;
      UnitAbsyn.Store store;
    // Real
    case(DAE.T_FUNCTION(_,functp,_,_),_,_,store) equation
      unitStr = getUnitStr(functp);
      //print("Got unit='"+unitStr+"'\n");
      unspec = 0 == stringCompare(unitStr,"");

      unit = str2unit(unitStr,SOME(funcInstId));
      unit = if unspec then UnitAbsyn.UNSPECIFIED() else unit;
     (store,indx) = add(unit,store);
     (store,indx2) = add(UnitAbsyn.UNSPECIFIED(),store);
      then ({UnitAbsyn.LOC(indx2,funcCallExp)},{UnitAbsyn.EQN(UnitAbsyn.LOC(indx2,funcCallExp),UnitAbsyn.LOC(indx,funcCallExp),funcCallExp)},store);

    // Tuple
    case(DAE.T_FUNCTION(funcResultType=DAE.T_TUPLE(types = typeLst)),_,_,store) equation
      (terms,extraTerms,store) = buildTupleResultTerms(typeLst,funcInstId,funcCallExp,store);
     then (terms,extraTerms,store);
    else equation
      print("buildResultTerms failed\n");
    then fail();
  end matchcontinue;
end buildResultTerms;

protected function buildTupleResultTerms "help function to buildResultTerms"
  input list<DAE.Type> ifunctps;
  input Integer funcInstId;
  input DAE.Exp funcCallExp;
  input UnitAbsyn.Store istore;
  output list<UnitAbsyn.UnitTerm> terms;
  output list<UnitAbsyn.UnitTerm> extraTerms;
  output UnitAbsyn.Store outStore;
algorithm
  (terms,extraTerms,outStore) := match(ifunctps,funcInstId,funcCallExp,istore)
    local
      list<UnitAbsyn.UnitTerm> terms1,terms2,extraTerms1,extraTerms2; DAE.Type tp;
      list<DAE.Type> functps;
      UnitAbsyn.Store store;
    case({},_,_,store) then ({},{},store);
    case(tp::functps,_,_,store) equation
      (terms1,extraTerms1,store) = buildResultTerms(tp,funcInstId,funcCallExp,store);
      (terms2,extraTerms2,store) = buildTupleResultTerms(functps,funcInstId,funcCallExp,store);
      terms = listAppend(terms1,terms2);
      extraTerms = listAppend(extraTerms1,extraTerms2);
    then (terms,extraTerms,store);
  end match;
end buildTupleResultTerms;

protected function buildTermExpList "build terms from list of expressions"
  input FCore.Graph env;
  input list<DAE.Exp> iexpl;
  input HashTable.HashTable ht;
  input UnitAbsyn.Store istore;
  output list<UnitAbsyn.UnitTerm> terms;
  output list<UnitAbsyn.UnitTerm> extraTerms;
  output UnitAbsyn.Store outStore;
algorithm
  (terms,extraTerms,outStore) := matchcontinue(env,iexpl,ht,istore)
    local
      DAE.Exp e;
      list<UnitAbsyn.UnitTerm> eterms1,eterms2;
      UnitAbsyn.UnitTerm ut;
      list<DAE.Exp> expl;
      UnitAbsyn.Store store;

    case (_,{},_,store) then ({},{},store);
    case(_,e::expl,_,store) equation
      (ut,eterms1,store) =  buildTermExp(env,e,false,ht,store);
      (terms,eterms2,store) = buildTermExpList(env,expl,ht,store);
      extraTerms = listAppend(eterms1,eterms2);
    then (ut::terms,extraTerms,store);
    case(_,e::_,_,_) equation
      print("buildTermExpList failed for exp"+ExpressionDump.printExpStr(e)+"\n");
    then fail();
  end matchcontinue;
end buildTermExpList;


protected function buildFuncTypeStores "help function to buildTermCall"
  input DAE.Type funcType;
  input Integer funcInstId "unique id for each function call to make unique type parameter names";
  input UnitAbsyn.Store istore;
  output UnitAbsyn.Store outStore;
  output list<Integer> indxs;
algorithm
  (outStore,indxs) := matchcontinue(funcType,funcInstId,istore)
    local list<DAE.FuncArg> args; DAE.Type tp; UnitAbsyn.Store store;
    case(DAE.T_FUNCTION(funcArg = args),_,store) equation
      (store,indxs) = buildFuncTypeStores2(args,funcInstId,store);
    then (store,indxs);
    case(tp,_,_) equation
      print("buildFuncTypeStores failed, tp"+Types.unparseType(tp)+"\n");
    then fail();
  end matchcontinue;
end buildFuncTypeStores;

protected function buildFuncTypeStores2 "help function to buildFuncTypeStores"
  input list<DAE.FuncArg> ifargs;
  input Integer funcInstId;
  input UnitAbsyn.Store istore;
  output UnitAbsyn.Store outStore;
  output list<Integer> indxs;
algorithm
  (outStore,indxs) := match(ifargs,funcInstId,istore)
    local
      String unitStr;
      Integer indx;
      DAE.Type tp;
      UnitAbsyn.Unit unit;
      list<DAE.FuncArg> fargs;
      UnitAbsyn.Store store;

    case({},_,store) then (store,{});
    case(DAE.FUNCARG(ty=tp)::fargs,_,store) equation
      unitStr = getUnitStr(tp);

      unit = str2unit(unitStr,SOME(funcInstId));
      unit = if 0 == stringCompare(unitStr,"") then UnitAbsyn.UNSPECIFIED() else unit;
      (store,indx) = add(unit,store);
      (store,indxs) = buildFuncTypeStores2(fargs,funcInstId,store);
    then (store,indx::indxs);
  end match;
end buildFuncTypeStores2;

protected function getUnitStr "help function to e.g. buildFuncTypeStores2, retrieve a unit string
from a Type (must be T_REAL)"
  input DAE.Type itp;
  output String str;
algorithm
  str := matchcontinue(itp)
    local
      list<DAE.Var> varLst;
      DAE.TypeSource ts;
      DAE.Type tp;

    case(DAE.T_REAL(varLst = DAE.TYPES_VAR(name="unit",binding=DAE.EQBOUND(exp=DAE.SCONST(str)))::_))
      then str;
    case(DAE.T_REAL(_::varLst,ts)) then getUnitStr(DAE.T_REAL(varLst,ts));
    case(DAE.T_REAL({},_)) then "";
    case(DAE.T_INTEGER()) then "";
    case(DAE.T_ARRAY(ty=tp)) then getUnitStr(tp);
    case(tp) equation print("getUnitStr for type "+Types.unparseType(tp)+" failed\n"); then fail();
  end matchcontinue;
end getUnitStr;

protected function buildFormal2ActualParamTerms " help function to buildTermCall"
  input list<Integer> iformalParamIndxs;
  input list<UnitAbsyn.UnitTerm> iactualParamIndxs;
  output UnitAbsyn.UnitTerms terms;
algorithm
  terms := matchcontinue(iformalParamIndxs,iactualParamIndxs)
    local
      Integer loc1; UnitAbsyn.UnitTerm ut; DAE.Exp e;
      list<Integer> formalParamIndxs;
      list<UnitAbsyn.UnitTerm> actualParamIndxs;

    case({},{}) then {};
    case(loc1::formalParamIndxs,ut::actualParamIndxs) equation
      terms = buildFormal2ActualParamTerms(formalParamIndxs,actualParamIndxs);
      e = origExpInTerm(ut);
    then UnitAbsyn.EQN(UnitAbsyn.LOC(loc1,e),ut,e)::terms;
    else equation
      print("buildFormal2ActualParamTerms failed\n");
    then fail();
  end matchcontinue;
end buildFormal2ActualParamTerms;

protected function origExpInTerm "Returns the origExp of a term"
input UnitAbsyn.UnitTerm ut;
output DAE.Exp origExp;
algorithm
  origExp := match(ut) local DAE.Exp e;
    case(UnitAbsyn.ADD(_,_,e)) then e;
    case(UnitAbsyn.SUB(_,_,e)) then e;
    case(UnitAbsyn.MUL(_,_,e)) then e;
    case(UnitAbsyn.DIV(_,_,e)) then e;
    case(UnitAbsyn.EQN(_,_,e)) then e;
    case(UnitAbsyn.LOC(_,e)) then e;
    case(UnitAbsyn.POW(_,_,e)) then e;
  end match;
end origExpInTerm;

protected function buildTermOp "Takes two UnitTerms and and DAE.Operator and creates a new UnitTerm "
  input UnitAbsyn.UnitTerm ut1;
  input UnitAbsyn.UnitTerm ut2;
  input DAE.Operator op;
  input DAE.Exp origExp;
  output UnitAbsyn.UnitTerm ut;
algorithm
  ut := match(ut1,ut2,op,origExp)
    case (_,_,DAE.ADD(),_) then UnitAbsyn.ADD(ut1,ut2,origExp);
    case (_,_,DAE.SUB(),_) then UnitAbsyn.SUB(ut1,ut2,origExp);
    case (_,_,DAE.MUL(),_) then UnitAbsyn.MUL(ut1,ut2,origExp);
    case (_,_,DAE.DIV(),_) then UnitAbsyn.DIV(ut1,ut2,origExp);
  end match;
end buildTermOp;

protected function buildStores2 "help function"
  input DAE.DAElist dae;
  input UnitAbsyn.Store inStore;
  input HashTable.HashTable inHt;
  output UnitAbsyn.Store outStore;
  output HashTable.HashTable outHt;
algorithm
  (outStore,outHt) := matchcontinue(dae,inStore,inHt)
    local
      DAE.ComponentRef cr;
      Option<DAE.VariableAttributes> attropt;
      Integer indx;
      String unitStr;
      list<MMath.Rational> units;
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
      UnitAbsyn.Unit unit;
      DAE.Exp e1,e2;
      DAE.FunctionTree funcs;
      list<DAE.Element> elts;
      UnitAbsyn.Store store;
      HashTable.HashTable ht;
    case(DAE.DAE(elementLst = {}),_,_) then (inStore,inHt);
    case(DAE.DAE(elementLst = DAE.VAR(componentRef=cr,variableAttributesOption=attropt)::elts),_,_)
      equation
        DAE.SCONST(unitStr) = DAEUtil.getUnitAttr(attropt);
        unit = str2unit(unitStr,NONE()); /* Scale and offset not used yet*/
        (store,indx) = add(unit,inStore);
        ht = BaseHashTable.add((cr,indx),inHt);
        (store,ht) = buildStores2(DAE.DAE(elts),store,ht);
      then (store,ht);

    /* Failed to parse will give unspecified unit*/
    case(DAE.DAE(elementLst = DAE.VAR(componentRef=cr)::_),_,_)
      equation
        (store,indx) = add(UnitAbsyn.UNSPECIFIED(),inStore);
        ht = BaseHashTable.add((cr,indx),inHt);
      then (store,ht);

    case(DAE.DAE(elementLst = _::elts),_,_)
      equation
        (store,ht) = buildStores2(DAE.DAE(elts),inStore,inHt);
      then (store,ht);
  end matchcontinue;
end buildStores2;

protected function buildStores3 "help function"
  input DAE.DAElist dae;
  input UnitAbsyn.Store inStore;
  input HashTable.HashTable inHt;
  output UnitAbsyn.Store outStore;
  output HashTable.HashTable outHt;
algorithm
  (outStore,outHt) := matchcontinue(dae,inStore,inHt)
  local DAE.ComponentRef cr; Option<DAE.VariableAttributes> attropt;
    Integer indx; String unitStr;
    list<MMath.Rational> units;
    list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
    UnitAbsyn.Unit unit;
    DAE.Exp e1,e2;
    DAE.FunctionTree funcs;
    list<DAE.Element> elts;
    UnitAbsyn.Store store;
    HashTable.HashTable ht;

    case(DAE.DAE({}),store,ht) then (store,ht);
    case(DAE.DAE(DAE.EQUATION(e1,e2,_)::elts),store,ht) equation
       (store,ht) = buildStoreExp(e1,store,ht,NONE());
       (store,ht) = buildStoreExp(e2,store,ht,NONE());
       (store,ht) = buildStores3(DAE.DAE(elts),store,ht);
    then (store,ht);

    case(DAE.DAE(_::elts),store,ht) equation
      (store,ht) = buildStores3(DAE.DAE(elts),store,ht);
    then (store,ht);
  end matchcontinue;
end buildStores3;

protected function buildStoreExp " build stores from constants in expressions and from function calls"
  input DAE.Exp exp;
  input UnitAbsyn.Store inStore;
  input HashTable.HashTable inHt;
  input Option<DAE.Operator> parentOp;
  output UnitAbsyn.Store outStore;
  output HashTable.HashTable outHt;
algorithm
  (outStore,outHt) := matchcontinue(exp,inStore,inHt,parentOp)
  local Real r; String s1; Integer i,indx; UnitAbsyn.Unit unit; DAE.Exp e1,e2; DAE.Operator op;
    DAE.ComponentRef cref_;
    UnitAbsyn.Store store;
    HashTable.HashTable ht;
    /* Constant on top level, e.g. x = 1 => unspecified type */
    case(DAE.RCONST(r),store,ht,_) equation
      unit = selectConstantUnit(parentOp);
      (store,indx) = add(unit,store);
      s1 = realString(r);
      cref_ = ComponentReference.makeCrefIdent(s1,DAE.T_UNKNOWN_DEFAULT,{});
      ht = BaseHashTable.add((cref_,indx),ht);
    then (store,ht);

   case(DAE.CAST(_,DAE.ICONST(i)),store,ht,_) equation
      unit = selectConstantUnit(parentOp);
      (store,indx) = add(unit,store);
      s1 = intString(i);
      cref_ = ComponentReference.makeCrefIdent(s1,DAE.T_UNKNOWN_DEFAULT,{});
      ht = BaseHashTable.add((cref_,indx),ht);
    then (store,ht);

    case(DAE.BINARY(e1,op,e2),store,ht,_) equation
      (store,ht) = buildStoreExp(e1,store,ht,SOME(op));
      (store,ht) = buildStoreExp(e2,store,ht,SOME(op));
    then (store,ht);

    case(DAE.UNARY(_,e1),store,ht,_) equation
      (store,ht) = buildStoreExp(e1,store,ht,parentOp);
    then (store,ht);

    case(DAE.IFEXP(_,e1,e2),store,ht,_) equation
      (store,ht) = buildStoreExp(e1,store,ht,parentOp);
      (store,ht) = buildStoreExp(e2,store,ht,parentOp);
    then (store,ht);

    case(_,store,ht,_) then (store,ht);
  end matchcontinue;
end buildStoreExp;

public function unitMultiply "Multiplying two units corresponds to adding the units and joining the typeParameter list"
  input UnitAbsyn.Unit u1;
  input UnitAbsyn.Unit u2;
  output UnitAbsyn.Unit u;

algorithm
  u := match(u1,u2)
  local list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> tparams1,tparams2,tparams;
    list<MMath.Rational> units,units1,units2;
    case(UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(tparams1,units1)),UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(tparams2,units2))) equation
      tparams = listAppend(tparams1,tparams2);
      units = List.threadMap(units1,units2,MMath.addRational);
    then UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(tparams,units));
  end match;
end unitMultiply;


protected function selectConstantUnit "returns UNSPECIFIED or dimensionless depending on
parent expression as type of a constant expression"
  input Option<DAE.Operator> op;
  output UnitAbsyn.Unit unit;
algorithm
  unit := match(op)
    case(NONE()) then UnitAbsyn.UNSPECIFIED();
    case(SOME(DAE.ADD(_))) then UnitAbsyn.UNSPECIFIED();
    case(SOME(DAE.SUB(_))) then UnitAbsyn.UNSPECIFIED();
    case(SOME(_)) then str2unit("1",NONE());
  end match;
end selectConstantUnit;

public function unit2str "Translate a unit to a string"
  input UnitAbsyn.Unit unit;
  output String res;
algorithm
  res := match(unit)
    local
      list<Integer> nums,denoms,tpnoms,tpdenoms;
      list<String> tpstrs;
      list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
      list<MMath.Rational> units;

    case(UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(typeParams,units))) equation
      (nums,denoms) = splitRationals(units);
      (tpnoms,tpdenoms,tpstrs) = splitTypeParams(typeParams);
      res = UnitParserExt.unit2str(nums,denoms,tpnoms,tpdenoms,tpstrs,1.0/*scaleFactor*/,0.0/*offset*/);
    then res;
    case(UnitAbsyn.UNSPECIFIED()) then "unspecified";
   end match;
end unit2str;

public function str2unit "Translate a unit string to a unit"
  input String res;
  input Option<Integer> funcInstIdOpt;
  output UnitAbsyn.Unit unit;
protected
   list<Integer> nums,denoms,tpnoms,tpdenoms;
   list<String> tpstrs;
   list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
   list<MMath.Rational> units;
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

/* Tests  */

/* Test1:

model Test1 "CONSISTENT: All units defined. No inference"
  Position x;
  Velocity v;
  Acceleration a;
equation
  der(x) = v;
  der(v) = a;
end Test1;
*/

public function buildTest1

  output UnitAbsyn.UnitTerms ut;
  output UnitAbsyn.Store sigma;
protected
  MMath.Rational r0,r1,nr1,nr2;
  UnitAbsyn.Unit unitderx,unitderv,unitx,unitv,unita;
  algorithm
    r0 := MMath.RATIONAL(0,0);
    r1 := MMath.RATIONAL(1,0);
    nr1 := MMath.RATIONAL(-1,0);
    nr2 := MMath.RATIONAL(-2,0);
    ut := {
    UnitAbsyn.EQN(UnitAbsyn.LOC(1,DAE.SCONST("1")),UnitAbsyn.LOC(4,DAE.SCONST("4")),DAE.SCONST("1==4")),
    UnitAbsyn.EQN(UnitAbsyn.LOC(2,DAE.SCONST("2")),UnitAbsyn.LOC(5,DAE.SCONST("5")),DAE.SCONST("2==5"))
    };

    unitderx := UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,nr1,r0,r0,r0,r0,r0}));/* der("m") -> m/s*/
    unitderv := UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,nr2,r0,r0,r0,r0,r0})); /* der("m/s") -> m/s2 */
    unitx := UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,r0,r0,r0,r0,r0,r0})); /* x -> m */
    unitv := UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,nr1,r0,r0,r0,r0,r0})); /* v -> m/s */
    unita := UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,nr2,r0,r0,r0,r0,r0}));
    sigma := emptyStore();
    (sigma,_) :=  add(unitderx,sigma); /*1*/
    (sigma,_) :=  add(unitderv,sigma); /*2*/
    (sigma,_) :=  add(unitx,sigma); /*3*/
    (sigma,_) :=  add(unitv,sigma); /*4*/
    (sigma,_) :=  add(unita,sigma); /*5*/
    printStore(sigma);
 end buildTest1;

/* Test2:
model Test2 "CONSISTENT: Subtraction operator. All units defined. No inference"
Position x,y,z;
equation
z = x-y;
end Test2;
*/

/*public function buildTest2

  output UnitAbsyn.UnitTerms ut;
  output UnitAbsyn.Locations sigma;
protected
  MMath.Rational r0,r1;
  algorithm
    r0 := MMath.RATIONAL(0,0);
    r1 := MMath.RATIONAL(1,0);
    ut := {
    UnitAbsyn.EQN(UnitAbsyn.LOC("z"),UnitAbsyn.SUB(UnitAbsyn.LOC("x"),UnitAbsyn.LOC("y")))
    };
    sigma := {
    UnitAbsyn.LOCATION("x",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,r0,r0,r0,r0,r0,r0}))), // x -> m
    UnitAbsyn.LOCATION("y",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,r0,r0,r0,r0,r0,r0}))), // y -> m
    UnitAbsyn.LOCATION("z",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,r0,r0,r0,r0,r0,r0}))) // z -> m
    };
 end buildTest2;
 */

 /* Test3
 model Test3 "OVERDETERMINED: All units defined. No inference"
 Position x,y;
 Velocity z;
equation
 z = x-y;
end Test3;
 */

/*public function buildTest3
  output UnitAbsyn.UnitTerms ut;
  output UnitAbsyn.Locations sigma;
protected
  MMath.Rational r0,r1,nr1;
  algorithm
    r0 := MMath.RATIONAL(0,0);
    r1 := MMath.RATIONAL(1,0);
    nr1 := MMath.RATIONAL(-1,0);
    ut := {
    UnitAbsyn.EQN(UnitAbsyn.LOC("z"),UnitAbsyn.SUB(UnitAbsyn.LOC("x"),UnitAbsyn.LOC("y")))
    };
    sigma := {
    UnitAbsyn.LOCATION("x",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,r0,r0,r0,r0,r0,r0}))), // x -> m
    UnitAbsyn.LOCATION("y",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,r0,r0,r0,r0,r0,r0}))), // y -> m
    UnitAbsyn.LOCATION("z",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,nr1,r0,r0,r0,r0,r0}))) // z -> m/s
    };
 end buildTest3;
 */
 /*
 Test5

 model Test5 "CONSTISTENT: Multiplication operator. Not all units defined. inference"
  Position x,y;
  Real z;
 equation
 z = x*y;
end test5;
*/

 /*
 public function buildTest5
  output UnitAbsyn.UnitTerms ut;
  output UnitAbsyn.Locations sigma;
protected
  MMath.Rational r0,r1,nr1;
  algorithm
    r0 := MMath.RATIONAL(0,0);
    r1 := MMath.RATIONAL(1,0);
    nr1 := MMath.RATIONAL(-1,0);
    ut := {
    UnitAbsyn.EQN(UnitAbsyn.LOC("z"),UnitAbsyn.MUL(UnitAbsyn.LOC("x"),UnitAbsyn.LOC("y")))
    };
    sigma := {
    UnitAbsyn.LOCATION("x",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,r0,r0,r0,r0,r0,r0}))), // x -> m
    UnitAbsyn.LOCATION("y",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,r0,r0,r0,r0,r0,r0}))), // y -> m
    UnitAbsyn.LOCATION("z",UnitAbsyn.UNSPECIFIED())                                             // z -> unspecified
    };
 end buildTest5;
 */

 /* Test 8


function Foo8
  input Real x;
  output Real y;
algorithm
  y := x+1; // 1 has unkown unit
end Foo8;

model Test8 "CONSISTENT. type inference in function call "
  Position x,y;
  Velocity v1,v2;

equation
  x = Foo8(y);
  v1 = Foo8(v2);
end Test8;
 */

 /*public function buildTest8
  output UnitAbsyn.UnitTerms ut;
  output UnitAbsyn.Locations sigma;
protected
  MMath.Rational r0,r1,nr1;
  algorithm
    r0 := MMath.RATIONAL(0,0);
    r1 := MMath.RATIONAL(1,0);
    nr1 := MMath.RATIONAL(-1,0);
    ut := {
    UnitAbsyn.EQN(UnitAbsyn.LOC("x"),UnitAbsyn.LOC("Foo8(x)")),
    UnitAbsyn.EQN(UnitAbsyn.LOC("v1"),UnitAbsyn.LOC("Foo8(v2)"))
    };
    sigma := {
    UnitAbsyn.LOCATION("Foo8(y)",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,r0,r0,r0,r0,r0,r0}))), // Foo8(x) -> m
    UnitAbsyn.LOCATION("Foo8(v2)",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,nr1,r0,r0,r0,r0,r0}))), // Foo8(v2) -> m/s
    UnitAbsyn.LOCATION("v1",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,nr1,r0,r0,r0,r0,r0}))), // Foo8(v2) -> m/s
    UnitAbsyn.LOCATION("x",UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},{r1,r0,r0,r0,r0,r0,r0}))) // Foo8(v2) -> m
    };
 end buildTest8;
 */
annotation(__OpenModelica_Interface="frontend");
end UnitAbsynBuilder;

