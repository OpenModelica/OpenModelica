package UnitAbsynBuilder " Copyright MathCore Engineering AB 2008

Author: Peter Aronsson (peter.aronsson@mathcore.com)

This module contains functions fro building UnitAbsyn terms that are used for building constraint equations
for unit checker module

"

public import UnitAbsyn;
public import DAE;
public import MMath;
public import Env;
public import HashTable;
public import Absyn;

protected import DAEUtil;
protected import Exp;
protected import Interactive;
protected import Lookup;
protected import OptManager;
protected import SCode;
protected import SCodeUtil;
protected import System;
protected import Types;
protected import UnitParserExt;
protected import Util;

public function registerUnitWeights "traverses all dae variables and adjusts weights depending on defineunits defined
in the scopes of the classLst for each variable"
  input Env.Cache cache;
  input Env.Env env;  
  input list<DAE.Element> dae;
 protected 
 list<Absyn.Path> paths; list<SCode.Element> du;
algorithm
   _ := matchcontinue(cache,env,dae)
     case(cache,env,dae) equation       
       false = OptManager.getOption("unitChecking");    
   then ();
   case(cache,env,dae) equation
     /* TODO: This is very unefficient. It increases instantiationtime by factor 2 for 
    	 instantiation of largeTests/TestNandTotal.mo */
       paths = Util.listListUnion(Util.listMap(dae,DAEUtil.getClassList));
       du = Util.listListUnion(Util.listMap1(paths,retrieveUnitsFromEnv,(cache,env)));
       registerUnitWeightDefineunits(du);
   then ();
   end matchcontinue;
end registerUnitWeights;

protected function retrieveUnitsFromEnv "help function to registerUnitWeights"
  input Absyn.Path p;
  input tuple<Env.Cache,Env.Env> tpl;
  output list<SCode.Element> du;

algorithm
   du := matchcontinue(p,tpl) local 
   Env.Env env; list<SCode.Element> du;
     case(p,tpl) equation
       (_,_,env as Env.FRAME(defineUnits = du)::_) = Lookup.lookupClass(Util.tuple21(tpl),Util.tuple22(tpl),p,false);
     then du;
     case(p,tpl) then {};
  end matchcontinue;   
end retrieveUnitsFromEnv;


protected function registerUnitWeightDefineunits "help function to registerUnitWeightForClass"
  input list<SCode.Element> du;
algorithm 
   _ := matchcontinue(du)
   local String n; Real w;
     /* No defineunits found, for backward compatibility, use default implementation: 
     SI system ,with lower cost on Hz and Bq */
     case({}) equation 
       registerUnitWeightDefineunits2({
       SCode.DEFINEUNIT("m",NONE,NONE),
       SCode.DEFINEUNIT("kg",NONE,NONE),
       SCode.DEFINEUNIT("s",NONE,NONE),
       SCode.DEFINEUNIT("A",NONE,NONE),
       SCode.DEFINEUNIT("k",NONE,NONE),
       SCode.DEFINEUNIT("mol",NONE,NONE),
       SCode.DEFINEUNIT("cd",NONE,NONE),
       SCode.DEFINEUNIT("rad",SOME("m/m"),NONE),
       SCode.DEFINEUNIT("sr",SOME("m2/m2"),NONE),            
       SCode.DEFINEUNIT("Hz",SOME("s-1"),SOME(0.8)),
       SCode.DEFINEUNIT("N",SOME("m.kg.s-2"),NONE),
       SCode.DEFINEUNIT("Pa",SOME("N/m2"),NONE),
       SCode.DEFINEUNIT("W",SOME("J/s"),NONE),
       SCode.DEFINEUNIT("J",SOME("N.m"),NONE),
       SCode.DEFINEUNIT("C",SOME("s.A"),NONE),
       SCode.DEFINEUNIT("V",SOME("W/A"),NONE),
       SCode.DEFINEUNIT("F",SOME("C/V"),NONE),
       SCode.DEFINEUNIT("Ohm",SOME("V/A"),NONE),
       SCode.DEFINEUNIT("S",SOME("A/V"),NONE),
       SCode.DEFINEUNIT("Wb",SOME("V.s"),NONE),
       SCode.DEFINEUNIT("T",SOME("Wb/m2"),NONE),
       SCode.DEFINEUNIT("H",SOME("Wb/A"),NONE),
       SCode.DEFINEUNIT("lm",SOME("cd.sr"),NONE),
       SCode.DEFINEUNIT("lx",SOME("lm/m2"),NONE),
       SCode.DEFINEUNIT("Bq",SOME("s-1"),SOME(0.8)),
       SCode.DEFINEUNIT("Gy",SOME("J/kg"),NONE),
       SCode.DEFINEUNIT("Sv",SOME("cd.sr"),NONE),
       SCode.DEFINEUNIT("kat",SOME("s-1.mol"),NONE)
       });   then ();     
     case(du) equation registerUnitWeightDefineunits2(du); then ();    
  end matchcontinue;
end registerUnitWeightDefineunits;


protected function registerUnitWeightDefineunits2 "help function to registerUnitWeightDefineunits"
  input list<SCode.Element> du;
algorithm 
   _ := matchcontinue(du)
   local String n; Real w; 
     case(SCode.DEFINEUNIT(name=n,weight = SOME(w))::du) equation
       UnitParserExt.registerWeight(n,w);
       registerUnitWeightDefineunits2(du);
     then ();
     case(SCode.DEFINEUNIT(name=n,weight = NONE)::du) equation
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
  ((_,_,_)) := Interactive.traverseClasses(prg,NONE,registerUnitInClass,0,false); // defineunits must be in public section.
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
    case((cl as Absyn.CLASS(name=n),pa,i)) equation
      elts = Interactive.getElementitemsInClass(cl);
      defunits = Interactive.getDefineunitsInElements(elts);
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
       Absyn.DEFINEUNIT("Hz",{Absyn.NAMEDARG("exp",Absyn.STRING("s-1")),Absyn.NAMEDARG("weight",Absyn.REAL(0.8))}),
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
       Absyn.DEFINEUNIT("Bq",{Absyn.NAMEDARG("exp",Absyn.STRING("s-1")),Absyn.NAMEDARG("weight",Absyn.REAL(0.8))}),
       Absyn.DEFINEUNIT("Gy",{Absyn.NAMEDARG("exp",Absyn.STRING("J/kg"))}),
       Absyn.DEFINEUNIT("Sv",{Absyn.NAMEDARG("exp",Absyn.STRING("cd.sr"))}),
       Absyn.DEFINEUNIT("kat",{Absyn.NAMEDARG("exp",Absyn.STRING("s-1.mol"))})
       });  
     then ();
    
     case(elts) equation
       registerDefineunits2(elts);
     then ();
              
  end matchcontinue;
end registerDefineunits;       

protected function registerDefineunits2 "help function to registerUnitInClass"
  input list<Absyn.Element> elts;
algorithm
   _ := matchcontinue(elts) 
   local String name; list<Absyn.NamedArg> args; Absyn.Element du;
     String exp; Real weight;
     case({}) then ();
     /* Derived unit with weigth */
     /*case((du as Absyn.DEFINEUNIT(name=_))::elts) equation
       {SCode.DEFINEUNIT(name,SOME(exp),_)} = SCodeUtil.translateElement(du,false);       
       UnitParserExt.addDerivedWeight(name,exp,weight);
       registerDefineunits(elts);
     then ();*/
     
     /* Derived unit without weigth */
     case((du as Absyn.DEFINEUNIT(name=_))::elts) equation
       {SCode.DEFINEUNIT(name,SOME(exp),_)} = SCodeUtil.translateElement(du,false);
       UnitParserExt.addDerived(name,exp);
       registerDefineunits2(elts);
     then ();
            
       /* base unit does not not have weight*/
     case((du as Absyn.DEFINEUNIT(name=_))::elts) equation
       {SCode.DEFINEUNIT(name,NONE,_)} = SCodeUtil.translateElement(du,false);
       UnitParserExt.addBase(name);
       registerDefineunits2(elts);
     then ();
     
     case(_) equation
       print("registerDefineunits failed\n");
     then fail();
  end matchcontinue;
end registerDefineunits2; 

public function add "Adds a unit to the UnitAbsyn.Store"
  input UnitAbsyn.Unit unit; 
  input UnitAbsyn.Store st;
  output UnitAbsyn.Store outSt;
  output Integer index;
algorithm
  (outSt,index) := matchcontinue(unit,st)
    local Option<UnitAbsyn.Unit>[:] vector; Integer newIndx,numElts;
    case(unit,st as UnitAbsyn.STORE(storeVector=vector,numElts = numElts)) equation
      true = numElts == arrayLength(vector);
      st = expandStore(st);
      (st,index) = add(unit,st);
    then (st,index);
    case(unit,UnitAbsyn.STORE(storeVector=vector,numElts = numElts)) equation
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
  outStore := matchcontinue(store,st)
  local HashTable.HashTable ht; Option<UnitAbsyn.UnitCheckResult> res;
    case(UnitAbsyn.INSTSTORE(_,ht,res),st) then UnitAbsyn.INSTSTORE(st,ht,res);
    case(UnitAbsyn.NOSTORE(),st) then UnitAbsyn.NOSTORE();
  end matchcontinue;
end updateInstStore; 

protected function expandStore "Expands store to make room for more entries.
Expansion factor: 1.4
"
  input UnitAbsyn.Store st;
  output UnitAbsyn.Store outSt;
algorithm
  outSt := matchcontinue(st)
  local Option<UnitAbsyn.Unit>[:] vector; Integer indx,incr;
    case(UnitAbsyn.STORE(vector,indx)) equation
        incr = intMin(1,realInt(intReal(indx) *. 0.4));
        vector = arrayExpand(incr,vector,NONE());
     then UnitAbsyn.STORE(vector,indx);
  end matchcontinue;
end expandStore;
  

public function update "Updates  unit at index in UnitAbsyn.Store" 
  input UnitAbsyn.Unit unit;
  input Integer index;
  input UnitAbsyn.Store st;
  output UnitAbsyn.Store outSt;
algorithm
  outSt := matchcontinue(unit,index,st)
  local Option<UnitAbsyn.Unit>[:] vector; Integer indx;  
    case(unit,index,UnitAbsyn.STORE(vector,indx)) equation
      vector = arrayUpdate(vector,index,SOME(unit)) "destroys ";
    then UnitAbsyn.STORE(vector,indx);
       
    case(_,index,_) equation
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
  local Option<UnitAbsyn.Unit>[:] vector; Integer indx;
    UnitAbsyn.Unit unit;
    case(index,UnitAbsyn.STORE(vector,indx)) equation
      SOME(unit) = vector[index]; 
    then unit;
    case(index,_) equation
      print(" finding store at index ");print(intString(index));
      print(" failed\n");
    then fail();
  end matchcontinue;
end find;

public function instGetStore "Retrives the Store from an InstStore"
  input UnitAbsyn.InstStore store;
  output UnitAbsyn.Store st;
algorithm
  st := matchcontinue(store)
    case(UnitAbsyn.INSTSTORE(st,_,_)) then st;
    case(UnitAbsyn.NOSTORE()) then emptyStore();
  end matchcontinue;
end instGetStore;

public function emptyInstStore "returns an empty InstStore"
output UnitAbsyn.InstStore st;
protected
  UnitAbsyn.Store s;
  HashTable.HashTable ht;
algorithm
  s := emptyStore();
  ht := HashTable.emptyHashTable();
  st := UnitAbsyn.INSTSTORE(s,ht,NONE);
end emptyInstStore;

public function emptyStore "Returns an empty store with 10 empty array elements"
output UnitAbsyn.Store st;
protected
Option<UnitAbsyn.Unit>[:] vector;
algorithm
   vector := arrayCreate(10,NONE);
   st := UnitAbsyn.STORE(vector,0);
end emptyStore;

public function arrayExpand "
copied from Util.mo in OpenModelica

  Increases the number of elements of a vector with n.
  Each of the new elements have the value v."
  input Integer n;
  input Type_a[:] arr;
  input Type_a v;
  output Type_a[:] newarr_1;
  replaceable type Type_a subtypeof Any;
  Integer len,newlen;
  Type_a[:] newarr,newarr_1;
algorithm 
  len := arrayLength(arr);
  newlen := n + len;
  newarr := fill(v, newlen);
  newarr_1 := arrayCopy(arr, newarr);
end arrayExpand;

public function arrayCopy "function: arrayCopy
  copies all values in src array into dest array.
  The function fails if all elements can not be fit into dest array."
  input Type_a[:] inTypeAArray1;
  input Type_a[:] inTypeAArray2;
  output Type_a[:] outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeAArray:=
  matchcontinue (inTypeAArray1,inTypeAArray2)
    local
      Integer srclen,dstlen;
      Type_a[:] src,dst,dst_1;
    case (src,dst) /* src dst */ 
      equation 
        srclen = arrayLength(src);
        dstlen = arrayLength(dst);
        (srclen > dstlen) = true;
        print(
          "- Util.arrayCopy failed. Can not fit elements into dest array\n");
      then
        fail();
    case (src,dst)
      equation 
        srclen = arrayLength(src);
        srclen = srclen - 1;
        dst_1 = arrayCopy2(src, dst, srclen);
      then
        dst_1;
  end matchcontinue;
end arrayCopy;

protected function arrayCopy2 
  input Type_a[:] inTypeAArray1;
  input Type_a[:] inTypeAArray2;
  input Integer inInteger3;
  output Type_a[:] outTypeAArray;
  replaceable type Type_a subtypeof Any;
algorithm 
  outTypeAArray:=
  matchcontinue (inTypeAArray1,inTypeAArray2,inInteger3)
    local
      Type_a[:] src,dst,dst_1,dst_2;
      Type_a elt;
      Integer pos;
    case (src,dst,-1) then dst;  /* src dst current pos */ 
    case (src,dst,pos)
      equation 
        elt = src[pos + 1];
        dst_1 = arrayUpdate(dst, pos + 1, elt);
        pos = pos - 1;
        dst_2 = arrayCopy2(src, dst_1, pos);
      then
        dst_2;
  end matchcontinue;
end arrayCopy2;

public function printTerms "print the terms to stdout"
input UnitAbsyn.UnitTerms terms;
algorithm
  print(printTermsStr(terms));
end printTerms;

public function printTermsStr "print the terms to a string"
  input UnitAbsyn.UnitTerms terms;
  output String str;
algorithm
  str := "{" +& Util.stringDelimitList(Util.listMap(terms,printTermStr),",") +& "}";
end printTermsStr;

public function printTermStr "print one term to a string"
  input UnitAbsyn.UnitTerm term;
  output String str;
algorithm
  str := matchcontinue(term)
  local UnitAbsyn.UnitTerm ut1,ut2; String s1,s2,s3; 
    Integer i,i1,i2;
    DAE.Exp e;
    case(UnitAbsyn.ADD(ut1,ut2,e)) equation
      s1 = Exp.printExpStr(e);
    then s1;
    
    case(UnitAbsyn.SUB(ut1,ut2,e)) equation
      s1 = Exp.printExpStr(e);
    then s1;
      
    case(UnitAbsyn.MUL(ut1,ut2,e)) equation
      s1 = Exp.printExpStr(e);
    then s1;
      
    case(UnitAbsyn.DIV(ut1,ut2,e)) equation
      s1 = Exp.printExpStr(e);
    then s1;
      
    case(UnitAbsyn.EQN(ut1,ut2,e)) equation
      s1 = Exp.printExpStr(e);
    then s1;
      
    case(UnitAbsyn.LOC(i,e)) equation
    s1 = Exp.printExpStr(e);
    then s1;
       
    case(UnitAbsyn.POW(ut1,MMath.RATIONAL(i1,i2),e)) equation
      s1 = Exp.printExpStr(e);
    then s1;
              
  end matchcontinue;
end printTermStr;

public function printInstStore "prints the inst store to stdout"
input UnitAbsyn.InstStore st;
algorithm
  _ := matchcontinue(st) 
  local UnitAbsyn.Store s; HashTable.HashTable h;
    case(UnitAbsyn.INSTSTORE(s,h,_)) equation
      print("instStore, s:");
      printStore(s);
      print("\nht:");
      HashTable.dumpHashTable(h);
    then ();
    case(UnitAbsyn.NOSTORE()) then ();      
  end matchcontinue;
end printInstStore;

public function printStore "prints the store to stdout"
input UnitAbsyn.Store st;
algorithm
  _ := matchcontinue(st)
  local Option<UnitAbsyn.Unit>[:] vector; Integer indx;
    list<Option<UnitAbsyn.Unit>> lst;
    case(UnitAbsyn.STORE(vector,indx)) equation
      lst = arrayList(vector);
      printStore2(lst,1);
   then ();
  end matchcontinue;
end printStore;

protected function printStore2 "help function to printStore"
input list<Option<UnitAbsyn.Unit>> lst;
input Integer indx;
algorithm
  _ := matchcontinue(lst,indx)
  local UnitAbsyn.Unit unit;
    case({},_) then ();
      
    case(SOME(unit)::lst,indx) equation
      print(intString(indx));print("->");
      printUnit(unit);
      print("\n");
      printStore2(lst,indx+1);
    then();
    case(NONE::_,_) then ();            
  end matchcontinue;
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
    case(unit as UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT({},baseunits))) equation
      print(printBaseUnitsStr(baseunits));
      print(" [");print(unit2str(unit)); print("]");
    then();
    case(unit as UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(typeparams,baseunits))) equation
      print(Util.stringDelimitList(Util.listMap(typeparams,printTypeParameterStr),","));
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
    str = "m^("+&intString(i1)+&"/"+&intString(i2)+&")"
    +&  "s^("+&intString(i3)+&"/"+&intString(i4)+&")" ;
    then str;
    case({}) then ""; 
    case(lst) then "printBaseUnitsStr failed len:" +& intString(listLength(lst)) +& "\n";    
  end matchcontinue;
end printBaseUnitsStr;
  
protected function printTypeParameterStr "help function to printUnit"
  input tuple<MMath.Rational,UnitAbsyn.TypeParameter> typeParam;
  output String str;
algorithm
  str := matchcontinue(typeParam)
  local String name; Integer i1,i2,i3,indx;
    case((MMath.RATIONAL(0,0),UnitAbsyn.TYPEPARAMETER(name,indx))) equation
      str = name +& "[indx =" +& intString(indx) +& "]";
      then str;
    case((MMath.RATIONAL(i1,1),UnitAbsyn.TYPEPARAMETER(name,indx))) equation
      str = name +& "^" +& intString(i1) +& "[indx=" +& intString(indx) +& "]";     
    then str;
    case((MMath.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(name,indx))) equation
      str = name+& "^("+& intString(i1) +& "/" +& intString(i2)+&")" +& "[indx=" +& intString(indx) +& "]";     
    then str;
  end matchcontinue; 
end printTypeParameterStr;

public function splitRationals "splits a list of Rationals into a list of numerators and denominators"
  input list<MMath.Rational> rationals;
  output list<Integer> nums;
  output list<Integer> denoms;
algorithm
  (nums,denoms) := matchcontinue(rationals)
  local Integer i1,i2;
    case({}) then ({},{});
    case(MMath.RATIONAL(i1,i2)::rationals) equation
      (nums,denoms) = splitRationals(rationals);
    then (i1::nums,i2::denoms);
  end matchcontinue;
end splitRationals;

public function joinRationals "joins a lists of numerators and denominators into list of Rationals"
  input list<Integer> nums;
  input list<Integer> denoms;
  output list<MMath.Rational> rationals;
algorithm
  (rationals) := matchcontinue(nums,denoms)
  local Integer i1,i2;
    case({},{}) then ({});
    case(i1::nums,i2::denoms) equation
      rationals = joinRationals(nums,denoms);
    then (MMath.RATIONAL(i1,i2)::rationals);
  end matchcontinue;
end joinRationals;

public function joinTypeParams "creates type parameter lists from list of numerators , denominators and typeparameter names"
  input list<Integer> nums;
  input list<Integer> denoms;
  input list<String> tpstrs;
  input Option<Integer> funcInstIdOpt;
  output list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
algorithm
  typeParams := matchcontinue(nums,denoms,tpstrs,funcInstIdOpt)
    local Integer i1,i2;
      String tpParam,s;
    case({},{},{},_) then {};
    case(i1::nums,i2::denoms,tpParam::tpstrs,funcInstIdOpt) equation
      typeParams = joinTypeParams(nums,denoms,tpstrs,funcInstIdOpt);
        s=Util.stringOption(Util.applyOption(funcInstIdOpt,intString));
        tpParam = tpParam +& s;
    then (MMath.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(tpParam,0))::typeParams;
  end matchcontinue;  
end joinTypeParams;
  
public function splitTypeParams "splits type parameter lists into numerators, denominators and typeparameter names"
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
  output list<Integer> nums;
  output list<Integer> denoms;
  output list<String> tpstrs; 
algorithm
  (nums,denoms,tpstrs) := matchcontinue(typeParams)
  local String tpParam; Integer i1,i2;
    case({}) then ({},{},{});
    case((MMath.RATIONAL(i1,i2),UnitAbsyn.TYPEPARAMETER(tpParam,_))::typeParams) equation
      (nums,denoms,tpstrs) = splitTypeParams(typeParams);
    then (i1::nums,i2::denoms,tpParam::tpstrs);
  end matchcontinue;  
end splitTypeParams;

public function instBuildUnitTerms "builds unit terms and stores for a DAE. It also returns a hashtable that maps
variable names to store locations."
  input Env.Env env;
  input list<DAE.Element> dae;
  input list<DAE.Element> compDae "to collect variable bindings";
  input UnitAbsyn.InstStore store;
  output UnitAbsyn.InstStore outStore;
  output UnitAbsyn.UnitTerms terms;  
algorithm
  (outStore,terms) := matchcontinue(env,dae,compDae,store)
  local UnitAbsyn.Store st; HashTable.HashTable ht; UnitAbsyn.UnitTerms terms2;
    Option<UnitAbsyn.UnitCheckResult> res;
    case(env,dae,compDae,store) equation
      false = OptManager.getOption("unitChecking");
    then(UnitAbsyn.noStore,{});
    case(env,dae,compDae,UnitAbsyn.NOSTORE()) then  (UnitAbsyn.NOSTORE(),{});     
    case(env,dae,compDae,UnitAbsyn.INSTSTORE(st,ht,res)) equation  
     (terms,st) = buildTerms(env,dae,ht,st);
     (terms2,st) = buildTerms(env,compDae,ht,st) "to get bindings of scalar variables";
     terms = listAppend(terms,terms2);
     //print("built terms, store :"); printStore(st);
     //print("ht =");HashTable.dumpHashTable(ht);
      st = createTypeParameterLocations(st);
     // print("built type param, store :"); printStore(st);
     terms = listReverse(terms);
     then (UnitAbsyn.INSTSTORE(st,ht,res),terms);
    case(_,_,_,_) equation
      print("instBuildUnitTerms failed!!\n");
    then fail();       
  end matchcontinue;
end instBuildUnitTerms;  

  
public function buildUnitTerms "builds unit terms and stores for a DAE. It also returns a hashtable that maps
variable names to store locations."
  input Env.Env env;
  input list<DAE.Element> dae;
  output UnitAbsyn.UnitTerms terms;
  output UnitAbsyn.Store store;
  output HashTable.HashTable ht;
algorithm
  (store,ht) := buildStores(dae);
  (terms,store) := buildTerms(env,dae,ht,store);
  store := createTypeParameterLocations(store); 
end buildUnitTerms;  

public function instAddStore "Called when instantiating a Real class"
  input UnitAbsyn.InstStore store;
  input DAE.Type tp;
  input DAE.ComponentRef cr;
  output UnitAbsyn.InstStore outStore;
algorithm
  outStore := matchcontinue(store,tp,cr)
  local UnitAbsyn.Store st; HashTable.HashTable ht; DAE.Exp e; String unitStr;
    UnitAbsyn.Unit unit; Integer indx;
    Option<Absyn.Path> optPath;
    list<DAE.Var> vs;
    Option<UnitAbsyn.UnitCheckResult> res;
    
    case(store,_,_) equation
      false = OptManager.getOption("unitChecking");
    then UnitAbsyn.noStore;
      
    case(UnitAbsyn.INSTSTORE(st,ht,res),(DAE.T_REAL(DAE.TYPES_VAR(name="unit",binding = DAE.EQBOUND(exp=DAE.SCONST(unitStr)))::_),_),cr) equation
      unit = str2unit(unitStr,NONE);
      unit = Util.if_(0 == System.strcmp(unitStr,""),UnitAbsyn.UNSPECIFIED(),unit);
      (st,indx) = add(unit,st);
       ht = HashTable.add((cr,indx),ht);       
    then UnitAbsyn.INSTSTORE(st,ht,res);     
    case(store,(DAE.T_REAL(_::vs),optPath),cr) equation
     then instAddStore(store,(DAE.T_REAL(vs),optPath),cr);

      /* No unit available. */
    case(UnitAbsyn.INSTSTORE(st,ht,res),(DAE.T_REAL({}),_),cr) equation

      (st,indx) = add(UnitAbsyn.UNSPECIFIED(),st);
       ht = HashTable.add((cr,indx),ht);       
    then UnitAbsyn.INSTSTORE(st,ht,res);

    case(store,(DAE.T_COMPLEX(complexTypeOption=SOME(tp)),_),cr) equation
       store = instAddStore(store,tp,cr); 
    then store; 
    case(store,_,cr) then store;                 
  end matchcontinue;  
end instAddStore;


public function storeSize "return the number of elements of the store"
input UnitAbsyn.Store store;
output Integer size;
algorithm
  size := matchcontinue(store)
    case(UnitAbsyn.STORE(_,size)) then size;
  end matchcontinue;
end storeSize;

protected function createTypeParameterLocations "for each unique type parameter, create an UNSPECIFIED unit 
and add to the store."
  input UnitAbsyn.Store store;
  output UnitAbsyn.Store outStore;
protected
  Integer nextElement, storeSize;
algorithm
  storeSize := storeSize(store);
  (outStore,_,nextElement) := createTypeParameterLocations2(store,HashTable.emptyHashTable(),1,storeSize+1);
   outStore := addUnspecifiedStores((nextElement -storeSize) -1,outStore);  
end createTypeParameterLocations;

protected function addUnspecifiedStores " adds n unspecified"
  input Integer n;
  input UnitAbsyn.Store store;
  output UnitAbsyn.Store outStore;
algorithm
  outStore := matchcontinue(n,store)
    case(0,store) then store;
    case(n,store) equation 
      true = n < 0;
      print("addUnspecifiedStores n < 0!\n");
    then fail(); 
    case(n,store) equation
      true = n > 0;
      (store,_) = add(UnitAbsyn.UNSPECIFIED(),store);
      store = addUnspecifiedStores(n-1,store);
    then store;      
  end matchcontinue;  
end addUnspecifiedStores;

protected function createTypeParameterLocations2 "help function"
  input UnitAbsyn.Store store;
  input HashTable.HashTable ht;
  input Integer i "iterated";
  input Integer nextElt;
  output UnitAbsyn.Store outStore;
  output HashTable.HashTable outHt;
  output Integer outNextElt;
algorithm
  (outStore,outHt,outNextElt) := matchcontinue(store,ht,i,nextElt)
  local Integer numElts; Option<UnitAbsyn.Unit>[:] vect;
    UnitAbsyn.Unit unit;
     
    case(store as UnitAbsyn.STORE(vect,numElts),ht,i,nextElt) equation
      true = i > numElts;
     then (store,ht,nextElt); 
    
    case(store as UnitAbsyn.STORE(vect,numElts),ht,i,nextElt) equation 
      SOME(unit) = vect[i];
      (unit,ht,nextElt) = createTypeParameterLocations3(unit,ht,nextElt);
      vect = arrayUpdate(vect,i,SOME(unit));
      (store,ht,nextElt) = createTypeParameterLocations2(UnitAbsyn.STORE(vect,numElts),ht,i+1,nextElt);
    then (store,ht,nextElt);
   
    case(store as UnitAbsyn.STORE(vect,numElts),ht,i,nextElt) equation
      (store,ht,nextElt) = createTypeParameterLocations2(UnitAbsyn.STORE(vect,numElts),ht,i+1,nextElt);
    then (store,ht,nextElt);        
  end matchcontinue;
end createTypeParameterLocations2;

protected function createTypeParameterLocations3 "help function to createTypeParameterLocations2"
  input UnitAbsyn.Unit unit;
  input HashTable.HashTable ht;
  input Integer nextElt;
  output UnitAbsyn.Unit outUnit;
  output HashTable.HashTable outHt;
  output Integer outNextElt;
algorithm
  (outUnit,outHt,outNextElt) := matchcontinue(unit,ht,nextElt)
  local list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> params;
    list<MMath.Rational> units;
     /* Only succeeds for units with type parameters */
    case(UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(params as _::_,units)),ht,nextElt) equation
      (params,ht,nextElt) = createTypeParameterLocations4(params,ht,nextElt);
     then (UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(params,units)),ht,nextElt);        
  end matchcontinue;
end createTypeParameterLocations3;

protected function createTypeParameterLocations4 "help function to createTypeParameterLocations3"
  input list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> params;
  input HashTable.HashTable ht;  
  input Integer nextElt;
  output list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> outParams;
  output HashTable.HashTable outHt;
  output Integer outNextElt;
algorithm
  (outParams,outHt,outNextElt) := matchcontinue(params,ht,nextElt)
  local Integer indx; String name; MMath.Rational r;
    tuple<MMath.Rational,UnitAbsyn.TypeParameter> param;
    case({},ht,nextElt) then ({},ht,nextElt);
   
    case((r,UnitAbsyn.TYPEPARAMETER(name,0))::params,ht,nextElt) equation
      indx = HashTable.get(DAE.CREF_IDENT(name,DAE.ET_OTHER(),{}),ht);
      (params,ht,nextElt) = createTypeParameterLocations4(params,ht,nextElt);
    then ((r,UnitAbsyn.TYPEPARAMETER(name,indx))::params,ht,nextElt);
      
    case((r,UnitAbsyn.TYPEPARAMETER(name,0))::params,ht,nextElt) equation
        ht = HashTable.add((DAE.CREF_IDENT(name,DAE.ET_OTHER(),{}),nextElt),ht);
       (params,ht,nextElt) = createTypeParameterLocations4(params,ht,nextElt);
    then((r,UnitAbsyn.TYPEPARAMETER(name,nextElt))::params,ht,nextElt+1);
      
    case(param::params,ht,nextElt) equation
       (params,ht,nextElt) = createTypeParameterLocations4(params,ht,nextElt);
    then(param::params,ht,nextElt);      
    case(_,_,_) equation
      print("createTypeParameterLocations4 failed\n");
    then fail();
  end matchcontinue;
end createTypeParameterLocations4;
  
protected function buildStores "builds the stores and creates a hashtable from variable names to store locations"
  input list<DAE.Element> dae;
  output UnitAbsyn.Store store;
  output HashTable.HashTable ht;
algorithm
  (store,ht) := buildStores2(dae,emptyStore(),HashTable.emptyHashTable()) "Build stores from variables";
  (store,ht) := buildStores3(dae,store,ht) "build stores from constants and function calls in expressions";
end buildStores;

protected function buildTerms "builds the unit terms from DAE elements (equations)"
  input Env.Env env;
  input list<DAE.Element> dae;
  input HashTable.HashTable ht;
  input UnitAbsyn.Store store;
  output UnitAbsyn.UnitTerms terms;
  output UnitAbsyn.Store outStore;
algorithm
  (terms,outStore) := matchcontinue(env,dae,ht,store)
    local DAE.Exp e1,e2; UnitAbsyn.UnitTerm ut1,ut2;
      list<UnitAbsyn.UnitTerm> terms1,terms2,terms;
      DAE.ComponentRef cr1,cr2;
      list<DAE.Element> dae1;
    case(env,{},ht,store) then ({},store);
    case(env,DAE.EQUATION(e1,e2)::dae,ht,store) equation
      (ut1,terms1,store) = buildTermExp(env,e1,false,ht,store);      
      (ut2,terms2,store) = buildTermExp(env,e2,false,ht,store);
      (terms,store) = buildTerms(env,dae,ht,store);
      terms = listAppend(terms1,listAppend(terms2,terms));
    then  (UnitAbsyn.EQN(ut1,ut2,DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2))::terms,store);
      
    case(env,DAE.EQUEQUATION(cr1,cr2)::dae,ht,store) equation
      (ut1,terms1,store) = buildTermExp(env,DAE.CREF(cr1,DAE.ET_OTHER()),false,ht,store);
      (ut2,terms2,store) = buildTermExp(env,DAE.CREF(cr2,DAE.ET_OTHER()),false,ht,store);
      (terms,store) = buildTerms(env,dae,ht,store);
      terms = listAppend(terms1,listAppend(terms2,terms));
    then  (UnitAbsyn.EQN(ut1,ut2,DAE.BINARY(DAE.CREF(cr1,DAE.ET_OTHER()),DAE.SUB(DAE.ET_REAL()),DAE.CREF(cr2,DAE.ET_OTHER())))::terms,store);
           
      /* Only consider variables with binding from this instance level, not furhter down */
    case(env,DAE.VAR(componentRef=cr1 as DAE.CREF_IDENT(_,_,_),binding = SOME(e1))::dae,ht,store) equation      
      (ut1,terms1,store) = buildTermExp(env,DAE.CREF(cr1,DAE.ET_OTHER()),false,ht,store);
      (ut2,terms2,store) = buildTermExp(env,e1,false,ht,store);
      (terms,store) = buildTerms(env,dae,ht,store);
      terms = listAppend(terms1,listAppend(terms2,terms));    
    then  (UnitAbsyn.EQN(ut1,ut2,DAE.BINARY(DAE.CREF(cr1,DAE.ET_OTHER()),DAE.SUB(DAE.ET_REAL()),e1))::terms,store);
            
    case(env,DAE.DEFINE(cr1,e1)::dae,ht,store) equation
      (ut1,terms1,store) = buildTermExp(env,DAE.CREF(cr1,DAE.ET_OTHER()),false,ht,store);
      (ut2,terms2,store) = buildTermExp(env,e1,false,ht,store);
      (terms,store) = buildTerms(env,dae,ht,store);
      terms = listAppend(terms1,listAppend(terms2,terms));
    then  (UnitAbsyn.EQN(ut1,ut2,DAE.BINARY(DAE.CREF(cr1,DAE.ET_OTHER()),DAE.SUB(DAE.ET_REAL()),e1))::terms,store);
        
    case(env,_::dae,ht,store) equation
      (terms,store) = buildTerms(env,dae,ht,store);
      then (terms,store);    
  end matchcontinue;
end buildTerms; 

protected function buildTermExp "help function to buildTerms, handles expressions"
  input Env.Env env;
  input DAE.Exp exp;
  input Boolean divOrMul "is true if surrounding expression is division or multiplication. In that case 
   the constant will be treated as dimensionless, otherwise it will be treated as unspecified 
  ";
  input HashTable.HashTable ht;
  input UnitAbsyn.Store store;
  output UnitAbsyn.UnitTerm ut;
  output list<UnitAbsyn.UnitTerm> extraTerms "additional terms from e.g. function calls";
  output UnitAbsyn.Store outStore;    
algorithm
  (ut,extraTerms,outStore) := matchcontinue(env,exp,divOrMul,ht,store)
  local Real r; DAE.Operator op; Integer indx; UnitAbsyn.UnitTerm ut,ut1,ut2; String s1,crStr;
    DAE.ComponentRef cr;
    DAE.Exp e,e1,e2;
    Absyn.Path path;
    list<UnitAbsyn.UnitTerm> terms1,terms2,terms;
    list<DAE.Exp> expl;
    UnitAbsyn.Unit u;
    
    /*case(env,e as DAE.RCONST(r),ht,store) equation
      s1 = realString(r);
      indx = HashTable.get(DAE.CREF_IDENT(s1,DAE.ET_OTHER(),{}),ht);
    then (UnitAbsyn.LOC(indx,e),{},store);*/
    
    case(env,e as DAE.ICONST(i),divOrMul,ht,store) local Integer i; equation      
      s1 = "$"+&intString(tick())+&"_"+&intString(i);
      u = Util.if_(divOrMul,str2unit("1",NONE),UnitAbsyn.UNSPECIFIED());            
      (store,indx) = add(u,store);
       ht = HashTable.add((DAE.CREF_IDENT(s1,DAE.ET_OTHER(),{}),indx),ht);
    then (UnitAbsyn.LOC(indx,e),{},store);
    
    /* for each constant, add new unspecified unit*/
    case(env,e as DAE.RCONST(r),divOrMul,ht,store)equation
      s1 = "$"+&intString(tick())+&"_"+&realString(r);
      u = Util.if_(divOrMul,str2unit("1",NONE),UnitAbsyn.UNSPECIFIED());
      (store,indx) = add(u,store);
       ht = HashTable.add((DAE.CREF_IDENT(s1,DAE.ET_OTHER(),{}),indx),ht);
    then (UnitAbsyn.LOC(indx,e),{},store);
    
    case(env,DAE.CAST(_,e1),divOrMul,ht,store) equation
      (ut,terms,store) = buildTermExp(env,e1,divOrMul,ht,store);
    then (ut,terms,store);
      
    case(env,e as DAE.CREF(cr,_),divOrMul,ht,store) equation
     indx = HashTable.get(cr,ht);
    then (UnitAbsyn.LOC(indx,e),{},store);
    
    /* special case for pow */
    case(env,e as DAE.BINARY(e1,DAE.POW(_),e2 as DAE.ICONST(i)),divOrMul,ht,store) local Integer i;
      equation
        (ut1,terms1,store) = buildTermExp(env,e1,divOrMul,ht,store);
        (ut2,terms2,store) = buildTermExp(env,e2,divOrMul,ht,store);
        terms = listAppend(terms1,terms2);
        ut = UnitAbsyn.POW(ut1,MMath.RATIONAL(i,1),e);
    then (ut,terms,store);
    
    case(env,e as DAE.BINARY(e1,DAE.POW(_),e2 as DAE.RCONST(r)),divOrMul,ht,store) local Integer i; Real r;
      equation
        (ut1,terms1,store) = buildTermExp(env,e1,divOrMul,ht,store);
        (ut2,terms2,store) = buildTermExp(env,e2,divOrMul,ht,store);
        terms = listAppend(terms1,terms2);
        i = realInt(r);
        true = intReal(i) -. r ==. 0.0;
        ut = UnitAbsyn.POW(ut1,MMath.RATIONAL(i,1),e);
    then (ut,terms,store);  
      
    case(env,e as DAE.BINARY(e1,op,e2),divOrMul,ht,store) equation
      divOrMul = Exp.operatorDivOrMul(op);
      (ut1,terms1,store) = buildTermExp(env,e1,divOrMul,ht,store);
      (ut2,terms2,store) = buildTermExp(env,e2,divOrMul,ht,store);
      terms = listAppend(terms1,terms2);
      ut = buildTermOp(ut1,ut2,op,e);
    then (ut,terms,store);
      
      /* failed to build term for e2, use e1*/
    case(env,DAE.BINARY(e1,op,e2),divOrMul,ht,store) equation
      divOrMul = Exp.operatorDivOrMul(op);
      (ut,terms,store) = buildTermExp(env,e1,divOrMul,ht,store);
      failure((_,_,_) = buildTermExp(env,e1,divOrMul,ht,store));  
    then (ut,terms,store);

      /* failed to build term for e1, use e2*/
    case(env,DAE.BINARY(e1,op,e2),divOrMul,ht,store) equation
      divOrMul = Exp.operatorDivOrMul(op);
      failure((_,_,_) = buildTermExp(env,e1,divOrMul,ht,store));
      (ut,terms,store) = buildTermExp(env,e2,divOrMul,ht,store);  
    then (ut,terms,store);
      
    case(env,DAE.UNARY(op,e1),divOrMul,ht,store) equation
      (ut,terms,store) = buildTermExp(env,e1,divOrMul,ht,store);
    then (ut,terms,store);
      
    case(env,e as DAE.IFEXP(_,e1,e2),divOrMul,ht,store) equation
      divOrMul = false;
      (ut1,terms1,store) = buildTermExp(env,e1,divOrMul,ht,store);
      (ut2,terms2,store) = buildTermExp(env,e2,divOrMul,ht,store);
      terms = listAppend(terms1,terms2);     
    then (UnitAbsyn.EQN(ut1,ut2,e),terms,store);
    
    /* function call */
    case(env,e as DAE.CALL(path=path,expLst=expl),divOrMul,ht,store) equation
      divOrMul = false;
      (ut,terms,store) = buildTermCall(env,path,e,expl,divOrMul,ht,store);       
    then  (ut,terms,store);

    /* Array, all elements must be of same dimension, since an array with different units in different positions
    can not be declared in Modelica, since modifiers on arrays must affect the whole array */      
    case(env,e as DAE.ARRAY(_,_,expl),divOrMul,ht,store) 
      local list<UnitAbsyn.UnitTerm> uts; list<DAE.Exp> expl; UnitAbsyn.UnitTerm ut;
      equation
        print("vector ="+&Exp.printExpStr(e)+&"\n");
      (uts,terms,store) = buildTermExpList(env,expl,ht,store);
      ut::uts = buildArrayElementTerms(uts,expl);
      terms = listAppend(terms,uts);
    then (ut,terms,store);    
  
    case(env,e as DAE.MATRIX(_,_,mexpl),divOrMul,ht,store) 
      local  list<list<tuple<DAE.Exp, Boolean>>> mexpl; list<UnitAbsyn.UnitTerm> uts;
      equation 
        print("Matrix ="+&Exp.printExpStr(e)+&"\n");
        expl = Util.listFlatten(Util.listListMap(mexpl,Util.tuple21));
        (uts,terms,store) = buildTermExpList(env,expl,ht,store);
        ut::uts = buildArrayElementTerms(uts,expl);
        terms = listAppend(terms,uts);
      then (ut,terms,store);    
  
    case(env,e as DAE.CALL(path=_),divOrMul,ht,store) equation
      print("buildTermDAE.CALL failed exp: "+&Exp.printExpStr(e)+&"\n");
    then fail();            
  end matchcontinue;
end buildTermExp;

protected function buildArrayElementTerms "help function to buildTermExp. For each two terms from an array expression, it create
and EQN to make the constraint that they must have the same unit"
  input list<UnitAbsyn.UnitTerm> uts;
  input list<DAE.Exp> expl;
  output list<UnitAbsyn.UnitTerm> outUts;
algorithm
  outUts := matchcontinue(uts,expl)
  local UnitAbsyn.UnitTerm ut1,ut2;  DAE.ExpType ty; DAE.Exp e1,e2;
    case({},_) then  {};
    case(uts as {_},_) then uts;    
    case(ut1::ut2::uts,e1::e2::expl) equation
      uts = buildArrayElementTerms(uts,expl);
      ty = Exp.typeof(e1);
      uts = listAppend(uts,{UnitAbsyn.EQN(ut1,ut2,DAE.ARRAY(ty,true,{e1,e2}))});
    then uts;                     
  end matchcontinue;
end  buildArrayElementTerms;

protected function buildTermCall "builds a term and additional terms from a function call"
  input Env.Env env;
  input Absyn.Path path;
  input DAE.Exp funcCallExp;
  input list<DAE.Exp> expl;
  input Boolean divOrMul;
  input HashTable.HashTable ht;
  input UnitAbsyn.Store store;
  output UnitAbsyn.UnitTerm ut;
  output list<UnitAbsyn.UnitTerm> extraTerms "additional terms from e.g. function calls";
  output UnitAbsyn.Store outStore;
algorithm
  (ut,extraTerms,outStore) := matchcontinue(env,path,funcCallExp,expl,divOrMul,ht,store)
    local list<Integer> formalParamIndxs; Integer resIndx;
      list<UnitAbsyn.UnitTerm> actTermLst,terms,terms2,extraTerms2; DAE.Type functp;
       Integer funcInstId;
    case(env,path,funcCallExp,expl,divOrMul,ht,store) equation
       (_,functp,_) = Lookup.lookupType(Env.emptyCache(),env,path,false);
       funcInstId=tick();
       (store,formalParamIndxs) = buildFuncTypeStores(functp,funcInstId,store);
       (actTermLst,extraTerms,store) = buildTermExpList(env,expl,ht,store);
        terms = buildFormal2ActualParamTerms(formalParamIndxs,actTermLst);
        (terms2 as {ut},extraTerms2,store) = buildResultTerms(functp,funcInstId,funcCallExp,store);
        extraTerms = listAppend(extraTerms,listAppend(extraTerms2,terms));
    then (ut,extraTerms,store);
  end matchcontinue;
end buildTermCall;    

protected function buildResultTerms "build stores and terms for assigning formal output arguments to
new locations"
  input DAE.Type functp;
  input Integer funcInstId;
  input DAE.Exp funcCallExp;
  input UnitAbsyn.Store store;
  output list<UnitAbsyn.UnitTerm> terms;
  output list<UnitAbsyn.UnitTerm> extraTerms;
  output UnitAbsyn.Store outStore;
algorithm
  (terms,outStore) := matchcontinue(functp,funcInstId,funcCallExp,store)
  local String unitStr; UnitAbsyn.Unit unit; Integer indx,indx2; Boolean unspec;
    list<DAE.Type> typeLst;
    /* Real */
    case((DAE.T_FUNCTION(_,functp),_),funcInstId,funcCallExp,store) equation
      unitStr = getUnitStr(functp);
      //print("Got unit='"+&unitStr+&"'\n");
      unspec = 0 == System.strcmp(unitStr,"");
      
      unit = str2unit(unitStr,SOME(funcInstId));
      unit = Util.if_(unspec,UnitAbsyn.UNSPECIFIED(),unit);
     (store,indx) = add(unit,store);
     (store,indx2) = add(UnitAbsyn.UNSPECIFIED(),store);
      then ({UnitAbsyn.LOC(indx2,funcCallExp)},{UnitAbsyn.EQN(UnitAbsyn.LOC(indx2,funcCallExp),UnitAbsyn.LOC(indx,funcCallExp),funcCallExp)},store);
      
    /* Tuple */
    case((DAE.T_FUNCTION(_,(DAE.T_TUPLE(typeLst),_)),_),funcInstId,funcCallExp,store) equation
      (terms,extraTerms,store) = buildTupleResultTerms(typeLst,funcInstId,funcCallExp,store);
     then (terms,extraTerms,store);
    case(_,_,_,_) equation
      print("buildResultTerms failed\n");
    then fail();
  end matchcontinue;
end buildResultTerms;

protected function buildTupleResultTerms "help function to buildResultTerms"
  input list<DAE.Type> functps;
  input Integer funcInstId;
  input DAE.Exp funcCallExp;
  input UnitAbsyn.Store store;
  output list<UnitAbsyn.UnitTerm> terms;
  output list<UnitAbsyn.UnitTerm> extraTerms;
  output UnitAbsyn.Store outStore;
algorithm
  (terms,extraTerms,outStore) := matchcontinue(functps,funcInstId,funcCallExp,store)
  local list<UnitAbsyn.UnitTerm> terms1,terms2,extraTerms1,extraTerms2; DAE.Type tp;
    case({},funcInstId,funcCallExp,store) then ({},{},store);
    case(tp::functps,funcInstId,funcCallExp,store) equation
      (terms1,extraTerms1,store) = buildResultTerms(tp,funcInstId,funcCallExp,store);
      (terms2,extraTerms2,store) = buildTupleResultTerms(functps,funcInstId,funcCallExp,store);
      terms = listAppend(terms1,terms2);
      extraTerms = listAppend(extraTerms1,extraTerms2);
    then (terms,extraTerms,store);
  end matchcontinue;
end buildTupleResultTerms;

protected function buildTermExpList "build terms from list of expressions"
  input Env.Env env;
  input list<DAE.Exp> expl;
  input HashTable.HashTable ht;
  input UnitAbsyn.Store store;
  output list<UnitAbsyn.UnitTerm> terms;
  output list<UnitAbsyn.UnitTerm> extraTerms;
  output UnitAbsyn.Store outStore;
algorithm
  (terms,extraTerms,outStore) := matchcontinue(env,expl,ht,store)
  local DAE.Exp e;
    list<UnitAbsyn.UnitTerm> eterms1,eterms2; UnitAbsyn.UnitTerm ut;
    case(env,{},ht,store) then ({},{},store);
    case(env,e::expl,ht,store) equation
      (ut,eterms1,store) =  buildTermExp(env,e,false,ht,store);
      (terms,eterms2,store) = buildTermExpList(env,expl,ht,store);
      extraTerms = listAppend(eterms1,eterms2);
    then (ut::terms,extraTerms,store);  
    case(_,e::_,_,_) equation
      print("buildTermExpList failed for exp"+&Exp.printExpStr(e)+&"\n");
    then fail();   
  end matchcontinue;
end buildTermExpList;
  

protected function buildFuncTypeStores "help function to buildTermCall"
  input DAE.Type funcType;
  input Integer funcInstId "unique id for each function call to make unique type parameter names";
  input UnitAbsyn.Store store;
  output UnitAbsyn.Store outStore;
  output list<Integer> indxs;
algorithm
  (outStore,indxs) := matchcontinue(funcType,funcInstId,store)
  local list<DAE.FuncArg>  args; DAE.Type tp;
    case((DAE.T_FUNCTION(args,_),_),funcInstId,store) equation
      (store,indxs) = buildFuncTypeStores2(args,funcInstId,store);
    then (store,indxs);
    case(tp,_,_) equation
      print("buildFuncTypeStores failed, tp"+&Types.unparseType(tp)+&"\n");
    then fail();
  end matchcontinue;
end buildFuncTypeStores; 

protected function buildFuncTypeStores2 "help function to buildFuncTypeStores"
  input list<DAE.FuncArg> fargs;
  input Integer funcInstId;
  input UnitAbsyn.Store store;
  output UnitAbsyn.Store outStore;
  output list<Integer> indxs;
algorithm
  (outStore,indxs) := matchcontinue(fargs,funcInstId,store)
  local String unitStr; Integer indx; DAE.Type tp; UnitAbsyn.Unit unit;
    case({},funcInstId,store) then (store,{});
    case((_,tp)::fargs,funcInstId,store) equation
      unitStr = getUnitStr(tp);
      
      unit = str2unit(unitStr,SOME(funcInstId));
      unit = Util.if_(0 == System.strcmp(unitStr,""),UnitAbsyn.UNSPECIFIED(),unit);
      (store,indx) = add(unit,store);
      (store,indxs) = buildFuncTypeStores2(fargs,funcInstId,store);
    then (store,indx::indxs);
  end matchcontinue;
end buildFuncTypeStores2;

protected function getUnitStr "help function to e.g. buildFuncTypeStores2, retrieve a unit string
from a Type (must be T_REAL)"
  input DAE.Type tp;
  output String str;
algorithm
  str := matchcontinue(tp)
  local list<DAE.Var> varLst;
    Option<Absyn.Path> optPath;
    case((DAE.T_REAL(DAE.TYPES_VAR(name="unit",binding=DAE.EQBOUND(exp=DAE.SCONST(str)))::_),_))
      then str;
    case((DAE.T_REAL(_::varLst),optPath)) then getUnitStr((DAE.T_REAL(varLst),optPath));
    case((DAE.T_REAL({}),_)) then "";
    case((DAE.T_INTEGER(_),_)) then "";
    case((DAE.T_ARRAY(arrayType=tp),_)) then getUnitStr(tp);
    case(tp) equation print("getUnitStr for type "+&Types.unparseType(tp)+&" failed\n"); then fail();
  end matchcontinue;  
end getUnitStr;

protected function buildFormal2ActualParamTerms " help function to buildTermCall"
  input list<Integer> formalParamIndxs;
  input list<UnitAbsyn.UnitTerm> actualParamIndxs;
  output UnitAbsyn.UnitTerms terms;
algorithm
  terms := matchcontinue(formalParamIndxs,actualParamIndxs)
  local Integer loc1; UnitAbsyn.UnitTerm ut; DAE.Exp e;
    case({},{}) then {};
    case(loc1::formalParamIndxs,ut::actualParamIndxs) equation
      terms = buildFormal2ActualParamTerms(formalParamIndxs,actualParamIndxs);
      e = origExpInTerm(ut);
    then UnitAbsyn.EQN(UnitAbsyn.LOC(loc1,e),ut,e)::terms;
    case(_,_) equation
      print("buildFormal2ActualParamTerms failed\n");
    then fail();
  end matchcontinue;
end buildFormal2ActualParamTerms;

protected function origExpInTerm "Returns the origExp of a term"
input UnitAbsyn.UnitTerm ut;
output DAE.Exp origExp;
algorithm
  origExp := matchcontinue(ut) local DAE.Exp e;
    case(UnitAbsyn.ADD(_,_,e)) then e;
    case(UnitAbsyn.SUB(_,_,e)) then e;
    case(UnitAbsyn.MUL(_,_,e)) then e;
    case(UnitAbsyn.DIV(_,_,e)) then e;
    case(UnitAbsyn.EQN(_,_,e)) then e;
    case(UnitAbsyn.LOC(_,e)) then e;
    case(UnitAbsyn.POW(_,_,e)) then e;          
  end matchcontinue;
end origExpInTerm;

protected function buildTermOp "Takes two UnitTerms and and DAE.Operator and creates a new UnitTerm "
  input UnitAbsyn.UnitTerm ut1;
  input UnitAbsyn.UnitTerm ut2;
  input DAE.Operator op;
  input DAE.Exp origExp;
  output UnitAbsyn.UnitTerm ut;
algorithm
  ut := matchcontinue(ut1,ut2,op,origExp)
    case(ut1,ut2,DAE.ADD(_),origExp) then UnitAbsyn.ADD(ut1,ut2,origExp);
    case(ut1,ut2,DAE.SUB(_),origExp) then UnitAbsyn.SUB(ut1,ut2,origExp);
    case(ut1,ut2,DAE.MUL(_),origExp) then UnitAbsyn.MUL(ut1,ut2,origExp);
    case(ut1,ut2,DAE.DIV(_),origExp) then UnitAbsyn.DIV(ut1,ut2,origExp);
  end matchcontinue;
end buildTermOp;

protected function buildStores2 "help function"
  input list<DAE.Element> dae;
  input UnitAbsyn.Store store;
  input HashTable.HashTable ht;
  output UnitAbsyn.Store outStore;
  output HashTable.HashTable outHt;
algorithm
  (outStore,outHt) := matchcontinue(dae,store,ht)
  local DAE.ComponentRef cr; Option<DAE.VariableAttributes> attropt;
    Integer indx; String unitStr;
    list<MMath.Rational> units;
    list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
    UnitAbsyn.Unit unit;
    DAE.Exp e1,e2;
    case({},store,ht) then (store,ht);
    case(DAE.VAR(componentRef=cr,variableAttributesOption=attropt)::dae,store,ht) equation
      DAE.SCONST(unitStr) = DAEUtil.getUnitAttr(attropt);
      unit = str2unit(unitStr,NONE); /* Scale and offset not used yet*/
      (store,indx) = add(unit,store);
      ht = HashTable.add((cr,indx),ht);
      (store,ht) = buildStores2(dae,store,ht);
    then (store,ht);
    
    /* Failed to parse will give unspecified unit*/
    case(DAE.VAR(componentRef=cr,variableAttributesOption=attropt)::dae,store,ht) equation
      (store,indx) = add(UnitAbsyn.UNSPECIFIED(),store);
      ht = HashTable.add((cr,indx),ht);
    then (store,ht);
          
    case(_::dae,store,ht) equation
      (store,ht) = buildStores2(dae,store,ht);
    then (store,ht);     
  end matchcontinue;  
end buildStores2;

protected function buildStores3 "help function"
  input list<DAE.Element> dae;
  input UnitAbsyn.Store store;
  input HashTable.HashTable ht;
  output UnitAbsyn.Store outStore;
  output HashTable.HashTable outHt;
algorithm
  (outStore,outHt) := matchcontinue(dae,store,ht)
  local DAE.ComponentRef cr; Option<DAE.VariableAttributes> attropt;
    Integer indx; String unitStr;
    list<MMath.Rational> units;
    list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
    UnitAbsyn.Unit unit;
    DAE.Exp e1,e2;
    case({},store,ht) then (store,ht);    
    case(DAE.EQUATION(e1,e2)::dae,store,ht) equation
       (store,ht) = buildStoreExp(e1,store,ht,NONE);
       (store,ht) = buildStoreExp(e2,store,ht,NONE);
       (store,ht) = buildStores3(dae,store,ht);
    then (store,ht); 
      
    case(_::dae,store,ht) equation
      (store,ht) = buildStores3(dae,store,ht);
    then (store,ht);     
  end matchcontinue;  
end buildStores3;

protected function buildStoreExp " build stores from constants in expressions and from function calls"
  input DAE.Exp exp;
  input UnitAbsyn.Store store;
  input HashTable.HashTable ht;
  input Option<DAE.Operator> parentOp;
  output UnitAbsyn.Store outStore;
  output HashTable.HashTable outHt;
algorithm
  (outStore,outHt) := matchcontinue(exp,store,ht,parentOp)
  local Real r; String s1; Integer i,indx; UnitAbsyn.Unit unit; DAE.Exp e1,e2; DAE.Operator op;
    /* Constant on top level, e.g. x = 1 => unspecified type */
    case(DAE.RCONST(r),store,ht,parentOp) equation
      unit = selectConstantUnit(parentOp);
      (store,indx) = add(unit,store);
      s1 = realString(r);
      ht = HashTable.add((DAE.CREF_IDENT(s1,DAE.ET_OTHER(),{}),indx),ht);
    then (store,ht);
      
   case(DAE.CAST(_,DAE.ICONST(i)),store,ht,parentOp) equation
      unit = selectConstantUnit(parentOp);
      (store,indx) = add(unit,store);
      s1 = intString(i);
      ht = HashTable.add((DAE.CREF_IDENT(s1,DAE.ET_OTHER(),{}),indx),ht);
    then (store,ht);
      
    case(DAE.BINARY(e1,op,e2),store,ht,parentOp) equation
      (store,ht) = buildStoreExp(e1,store,ht,SOME(op));
      (store,ht) = buildStoreExp(e2,store,ht,SOME(op));
    then (store,ht);
      
    case(DAE.UNARY(_,e1),store,ht,parentOp) equation
      (store,ht) = buildStoreExp(e1,store,ht,parentOp);
    then (store,ht);
      
    case(DAE.IFEXP(_,e1,e2),store,ht,parentOp) equation
      (store,ht) = buildStoreExp(e1,store,ht,parentOp);
      (store,ht) = buildStoreExp(e2,store,ht,parentOp);
    then (store,ht); 
      
/*    case(DAE.CALL(path=Absyn.IDENT("der"),expLst = {DAE.CREF(_,cr)}),store,ht,parentOp) equation
      indx = HashTable.get(cr,ht);
      unit = find(index,st);
      derUnit = unitMultiply(unit,str2unit("1/s"));
    then (store,ht);*/
    case(_,store,ht,parentOp) then (store,ht);   
  end matchcontinue;  
end buildStoreExp;

public function unitMultiply "Multiplying two units corresponds to adding the units and joining the typeParameter list"
  input UnitAbsyn.Unit u1;
  input UnitAbsyn.Unit u2;
  output UnitAbsyn.Unit u;
  
algorithm
  u := matchcontinue(u1,u2)
  local list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> tparams1,tparams2,tparams;
    list<MMath.Rational> units,units1,units2;
    case(UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(tparams1,units1)),UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(tparams2,units2))) equation
      tparams = listAppend(tparams1,tparams2);
      units = Util.listThreadMap(units1,units2,MMath.addRational);
    then UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(tparams,units));
  end matchcontinue;
end unitMultiply;


protected function selectConstantUnit "returns UNSPECIFIED or dimensionless depending on 
parent expression as type of a constant expression"
  input Option<DAE.Operator> op;
  output UnitAbsyn.Unit unit;
algorithm
  unit := matchcontinue(op)
    case(NONE) then UnitAbsyn.UNSPECIFIED();
    case(SOME(DAE.ADD(_))) then UnitAbsyn.UNSPECIFIED();
    case(SOME(DAE.SUB(_))) then UnitAbsyn.UNSPECIFIED();
    case(SOME(_)) then str2unit("1",NONE);                
  end matchcontinue;
end selectConstantUnit;

public function unit2str "Translate a unit to a string"
  input UnitAbsyn.Unit unit;
  output String res;
algorithm
  res := matchcontinue(unit)
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
   end matchcontinue;
end unit2str;

public function str2unit "Translate a unit string to a unit"
  input String res;
  input Option<Integer> funcInstIdOpt;
  output UnitAbsyn.Unit unit;
protected
   list<Integer> nums,denoms,tpnoms,tpdenoms;
   list<String> tpstrs;  
   Real scaleFactor,offset;
   list<tuple<MMath.Rational,UnitAbsyn.TypeParameter>> typeParams;
   list<MMath.Rational> units;
algorithm
  (nums,denoms,tpnoms,tpdenoms,tpstrs,scaleFactor,offset) := UnitParserExt.str2unit(res);
  units := joinRationals(nums,denoms);
  typeParams := joinTypeParams(tpnoms,tpdenoms,tpstrs,funcInstIdOpt);  
  unit := UnitAbsyn.SPECIFIED(UnitAbsyn.SPECUNIT(typeParams,units));
end str2unit;

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
end UnitAbsynBuilder; 
  
