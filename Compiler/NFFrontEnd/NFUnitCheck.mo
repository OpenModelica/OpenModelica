encapsulated package NFUnitCheck
" file:        NFUnitCheck.mo
  package:     UnitCheck
  description: This package provides everything for advanced unit checking:
                 - for all variables unspecified units get calculated if possible
                 - inconsistent equations get reported in a user friendly way
               authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)"

public
import Absyn;
import DAE;
import NFUnit;
import System;
protected

import BaseHashTable;
import ComponentReference;
import Error;
import Expression;
import ExpressionDump;
import Flags;
import NFHashTableCrToUnit;
import NFHashTableStringToUnit;
import NFHashTableUnitToString;
import List;
import DAEUtil;
import DAEDump;
import SCode;
import FCore;

public uniontype Functionargs
  record FUNCTIONUNITS
    String name;
    list<String> invars;
    list<String> outvars;
    list<String> inunits;
    list<String> outunits;
  end FUNCTIONUNITS;
end Functionargs;


public function unitChecking
  input DAE.DAElist indae;
  input FCore.Cache inCache;
  protected
  DAE.DAElist elts1,elts2,elts3;
  list<DAE.Element> eqlist,varlist,newdaelist;
  NFHashTableCrToUnit.HashTable HtCr2U1, HtCr2U2;
  NFHashTableStringToUnit.HashTable HtS2U;
  NFHashTableUnitToString.HashTable HtU2S;
  DAE.FunctionTree func;
  list<DAE.Function> functionlist;
  list<Functionargs> args;
  list<String> inunits,outunits;
algorithm
  try
   (elts1,elts2):=DAEUtil.splitDAEIntoVarsAndEquations(indae);
   varlist:=GetVarList(elts1);
   eqlist:=GetElementList(elts2);
   func := FCore.getFunctionTree(inCache);
   functionlist := DAEUtil.getFunctionList(func);

   HtCr2U1 := NFHashTableCrToUnit.emptyHashTableSized(2053);
   HtS2U := NFUnit.getKnownUnits();
   HtU2S := NFUnit.getKnownUnitsInverse();

   args:={FUNCTIONUNITS("",{},{},{},{})};

   args:= List.map1Flat(functionlist, parseFunctionList, args);

   // new instantiation
   //((HtCr2U1, HtS2U, HtU2S)) := List.fold(varlist, convertUnitString2unit, (HtCr2U1, HtS2U, HtU2S));

   // old instantiation
   ((HtCr2U1, HtS2U, HtU2S)) := List.fold(varlist, convertUnitString2unit_old, (HtCr2U1, HtS2U, HtU2S));
   HtCr2U2 := BaseHashTable.copy(HtCr2U1);
   ((HtCr2U2, HtS2U, HtU2S)) := algo(varlist,eqlist,args, HtCr2U2, HtS2U, HtU2S);
   if Flags.isSet(Flags.DUMP_UNIT) then
     BaseHashTable.dumpHashTable(HtCr2U2);
     print("######## UnitCheck COMPLETED ########\n");
   end if;
   notification(HtCr2U1, HtCr2U2, HtU2S);
   varlist := List.map2(varlist, returnVar, HtCr2U2, HtU2S);
   newdaelist:=List.append_reverse(varlist,eqlist);
   elts3:=updateDAElist(indae,listReverse(newdaelist));
  else
     Error.addInternalError("./Compiler/NFFrontEnd/NFUnitCheck.mo: unit check module failed",sourceInfo());
  end try;
end unitChecking;



protected function parseFunctionList
  input DAE.Function infunction;
  input list<Functionargs> inTpl;
  output list<Functionargs> outTpl;
algorithm
  outTpl := match(infunction, inTpl)
    local
      String unitString, s;
      list<String> listStr;
      DAE.ComponentRef cr;
      NFUnit.Unit ut;
      Absyn.Path path;
      list<DAE.FunctionDefinition> functions;
      list<DAE.Var> varlst;
      list<DAE.Element> inelt,outelt;
      list<String> inunits,outunits,inargs,outargs;
      DAE.Function fn;
      list<Functionargs> fncheck,fncheck1;
    case (fn,fncheck)
      equation
        s=getFunctionName(fn);
        inelt=DAEUtil.getFunctionInputVars(fn);
        outelt=DAEUtil.getFunctionOutputVars(fn);
        inunits=List.filterMap(inelt,getUnits);
        outunits=List.filterMap(outelt,getUnits);
        inargs=List.filterMap(inelt,getVars);
        outargs=List.filterMap(outelt,getVars);
        fncheck={FUNCTIONUNITS(s,inargs,outargs,inunits,outunits)};
      then
        (fncheck);

  end match;

end parseFunctionList;



public function getFunctionName
  input DAE.Function infunction;
  output String outstring;
algorithm
  outstring:=match(infunction)
    local
      DAE.Function fn;
      Absyn.Path path;
      String s,s1;
    case(DAE.FUNCTION(path=path))
      equation
        s=Absyn.pathStringDefault(path);
        s1=System.trim(s,".");
      then
        s1;
  end match;
end getFunctionName;

function getVars
  input DAE.Element inlist;
  output String outstring;
algorithm
  (outstring):=match(inlist)
    local
      String name;
      DAE.ComponentRef cr;
    case(DAE.VAR(componentRef=cr))
      equation
        name=ComponentReference.crefStr(cr);
      then
        (name);
    case(_)
    then "";
  end match;
end getVars;


function getUnits
  input DAE.Element inlist;
  output String outstring;
algorithm
  (outstring):=match(inlist)
    local
      list <DAE.Element> rest;
      String unitString;
      list<String> inputargs,inputargs1,inputargs2,outputargs,outputargs1,outputargs2;
      DAE.ComponentRef cr;
      DAE.VarDirection direction;
    case(DAE.VAR(componentRef=cr,direction=direction,ty=DAE.T_REAL(),variableAttributesOption=SOME(DAE.VAR_ATTR_REAL(unit=SOME(DAE.SCONST(unitString))))))
      guard(unitString <> "")
      then
        (unitString);
    case(_)
    then ("NONE");
  end match;
end getUnits;




protected function updateDAElist
  input DAE.DAElist indaelist;
  input list<DAE.Element> indaevarlist;
  output DAE.DAElist outdaelist;
algorithm
  outdaelist:= match(indaelist,indaevarlist)
    local
      DAE.Element v,e;
      list<DAE.Element> varlist,varlist2,elts1,elts2;
      DAE.DAElist outdae;
      String ident;
      DAE.ElementSource eltsrc;
      Option<SCode.Comment> comment;

    case(DAE.DAE(elementLst={DAE.COMP(ident=ident,dAElist=varlist,source=eltsrc,comment=comment)}),varlist2)
      equation
        outdae=DAE.DAE({DAE.COMP(ident,varlist2,eltsrc,comment)});
      then
        (outdae);
  end match;
end updateDAElist;


protected function returnVar "returns the new calculated units in DAE"
  input DAE.Element inVar;
  input NFHashTableCrToUnit.HashTable inHtCr2U;
  input NFHashTableUnitToString.HashTable inHtU2S;
  output DAE.Element outVar;
algorithm
  outVar := match(inVar)
    local
      DAE.Element var;
      DAE.ComponentRef cr;
      NFUnit.Unit ut;
      Option<DAE.VariableAttributes> attr;
      String s;

    case (DAE.VAR(variableAttributesOption=SOME(DAE.VAR_ATTR_REAL(unit=SOME(_))))) then inVar;

    case (DAE.VAR(componentRef=cr,variableAttributesOption=attr))
      equation
        ut = BaseHashTable.get(cr, inHtCr2U);
        if NFUnit.isUnit(ut) then
          s = NFUnit.unitString(ut, inHtU2S);
          attr=DAEUtil.setUnitAttr(attr, DAE.SCONST(s));
          inVar.variableAttributesOption=attr;
          var=inVar;
        else
            var = inVar;
        end if;
        then var;
  end match;
end returnVar;



protected function notification "dumps the calculated units"
  input NFHashTableCrToUnit.HashTable inHtCr2U1;
  input NFHashTableCrToUnit.HashTable inHtCr2U2;
  input NFHashTableUnitToString.HashTable inHtU2S;
algorithm
  _ := matchcontinue(inHtCr2U1, inHtCr2U2, inHtU2S)
    local
      String str;
      list<tuple<DAE.ComponentRef, NFUnit.Unit>> lt1;

    case (_,_,_)
      equation
        lt1 = BaseHashTable.hashTableList(inHtCr2U1);
        str = notification2(lt1, inHtCr2U2, inHtU2S);
        false = stringEqual(str, "");
        //Error.addCompilerNotification(str);
        if Flags.isSet(Flags.DUMP_UNIT) then
          Error.addCompilerNotification(str);
        end if;
        then ();

          else ();
  end matchcontinue;
end notification;


protected function notification2 "help-function"
  input list<tuple<DAE.ComponentRef, NFUnit.Unit>> inLt1;
  input NFHashTableCrToUnit.HashTable inHtCr2U2;
  input NFHashTableUnitToString.HashTable inHtU2S;
  output String outS;

algorithm
  outS := matchcontinue(inLt1, inHtCr2U2, inHtU2S)
    local
      String s1, s2;
      list<tuple<DAE.ComponentRef, NFUnit.Unit>> lt1;
      tuple<DAE.ComponentRef, NFUnit.Unit> t1;
      DAE.ComponentRef cr1;
      Real factor1;
      Integer i1, i2, i3, i4, i5, i6, i7;

    case ({}, _, _)
    then "";

    case (t1::lt1, _, _) equation
      (cr1, NFUnit.MASTER())=t1;
      NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)=BaseHashTable.get(cr1, inHtCr2U2);
      s1="\"" + ComponentReference.crefStr(cr1) + "\" has the Unit \"" + NFUnit.unitString(NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inHtU2S) + "\"" + "\n";
      s2=notification2(lt1, inHtCr2U2, inHtU2S);
    then s1 + s2;

    case (_::lt1, _, _) equation
      s1 = notification2(lt1, inHtCr2U2, inHtU2S);
    then s1;
  end matchcontinue;
end notification2;


public function algo "algorithm to check the consistency"
  input list<DAE.Element> invarlist;
  input list<DAE.Element> ineqList;
  input list<Functionargs> inargs;
  input NFHashTableCrToUnit.HashTable inHtCr2U;
  input NFHashTableStringToUnit.HashTable inHtS2U;
  input NFHashTableUnitToString.HashTable inHtU2S;
  output tuple<NFHashTableCrToUnit.HashTable /* outHtCr2U */, NFHashTableStringToUnit.HashTable /* outHtS2U */, NFHashTableUnitToString.HashTable /* outHtU2S */> outTpl;
  protected
  NFHashTableCrToUnit.HashTable HtCr2U;
  NFHashTableStringToUnit.HashTable HtS2U;
  NFHashTableUnitToString.HashTable HtU2S;
  Boolean b1, b2, b3;
algorithm
  ((HtCr2U, b1, HtS2U, HtU2S)) := List.fold(invarlist, foldBindingExp, (inHtCr2U, true, inHtS2U, inHtU2S));
  ((HtCr2U, b2, HtS2U, HtU2S)) := List.fold1(ineqList, foldEquation ,inargs,(HtCr2U, true, HtS2U, HtU2S));
  b3 := BaseHashTable.hasKey(NFUnit.UPDATECREF, HtCr2U);
  //outTpl := algo2(b1, b2, b3, invarlist, ineqList, HtCr2U, HtS2U, HtU2S);
  outTpl :=(HtCr2U, HtS2U, HtU2S);
end algo;


protected function foldBindingExp "folds the Binding expressions"
  input DAE.Element inVar;
  input tuple<NFHashTableCrToUnit.HashTable /* inHtCr2U */, Boolean /* success */, NFHashTableStringToUnit.HashTable /* inHtS2U */, NFHashTableUnitToString.HashTable /* inHtU2S */> inTpl;
  output tuple<NFHashTableCrToUnit.HashTable /* outHtCr2U */, Boolean /* success */, NFHashTableStringToUnit.HashTable /* outHtS2U */, NFHashTableUnitToString.HashTable /* outHtU2S */> outTpl;
algorithm
  outTpl := match(inVar, inTpl)
    local
      DAE.Exp exp, crefExp;
      DAE.ComponentRef cref;
      NFHashTableCrToUnit.HashTable HtCr2U;
      NFHashTableStringToUnit.HashTable HtS2U;
      NFHashTableUnitToString.HashTable HtU2S;
      Boolean b;
      DAE.Element eq;
      DAE.ElementSource source;

    case (DAE.VAR(componentRef=cref, ty=DAE.T_REAL(), binding=SOME(exp),source=source), (HtCr2U, b, HtS2U, HtU2S))
      equation
      crefExp = Expression.crefExp(cref);
      eq = DAE.EQUATION(crefExp, exp, source);
      ((HtCr2U, b, HtS2U, HtU2S))=foldEquation(eq,{},(HtCr2U, b, HtS2U, HtU2S));
    then ((HtCr2U, b, HtS2U, HtU2S));

    case (DAE.VAR(componentRef=cref, ty=DAE.T_REAL(), binding=SOME(_),source=source), (HtCr2U, _, HtS2U, HtU2S))
    then ((HtCr2U, false, HtS2U, HtU2S));

      else inTpl;
  end match;
end foldBindingExp;



protected function foldEquation "folds the equations or return the error message of incosistent equations"
  input DAE.Element inEq;
  input list<Functionargs> inargs;
  input tuple<NFHashTableCrToUnit.HashTable /* inHtCr2U */, Boolean /* success */, NFHashTableStringToUnit.HashTable /* inHtS2U */, NFHashTableUnitToString.HashTable /* inHtU2S */> inTpl;
  output tuple<NFHashTableCrToUnit.HashTable /* outHtCr2U */, Boolean /* success */, NFHashTableStringToUnit.HashTable /* outHtS2U */, NFHashTableUnitToString.HashTable /* outHtU2S */> outTpl;
  protected
  NFHashTableCrToUnit.HashTable HtCr2U;
  NFHashTableStringToUnit.HashTable HtS2U;
  NFHashTableUnitToString.HashTable HtU2S;
  list<list<tuple<DAE.Exp, NFUnit.Unit>>> expListList;
  Boolean b;
algorithm
  (HtCr2U, b, HtS2U, HtU2S):=inTpl;
  (HtCr2U, HtS2U, HtU2S, expListList):=foldEquation2(inEq, HtCr2U, HtS2U, HtU2S,inargs);
  List.map2_0(expListList, Errorfunction, inEq, HtU2S);
  outTpl := (HtCr2U, b, HtS2U, HtU2S);
end foldEquation;


protected function foldEquation2 "help-function"
  input DAE.Element inEq;
  input NFHashTableCrToUnit.HashTable inHtCr2U;
  input NFHashTableStringToUnit.HashTable inHtS2U;
  input NFHashTableUnitToString.HashTable inHtU2S;
  input list<Functionargs> inargs;
  output NFHashTableCrToUnit.HashTable outHtCr2U;
  output NFHashTableStringToUnit.HashTable outHtS2U;
  output NFHashTableUnitToString.HashTable outHtU2S;
  output list<list<tuple<DAE.Exp, NFUnit.Unit>>> outexpListList;

algorithm
  (outHtCr2U, outHtS2U, outHtU2S, outexpListList) := match(inEq, inHtCr2U, inHtS2U, inHtU2S,inargs)
    local
      DAE.Exp temp, rhs, lhs,call;
      DAE.Element eq;
      NFHashTableCrToUnit.HashTable HtCr2U;
      NFHashTableStringToUnit.HashTable HtS2U;
      NFHashTableUnitToString.HashTable HtU2S;
      list<list<tuple<DAE.Exp, NFUnit.Unit>>> expList,expList2,expList3;
      list<Functionargs> args;
      DAE.ComponentRef cr;
      Absyn.Path path,p;
      Boolean b;
      NFUnit.Unit ut,ut1,ut2;
      String s1,formalargs,formalvar,name;
      list<String> invars,outvars,inunitlist,outunitlist;
      list<DAE.Exp> explist,explist1,explist2;

    case (DAE.EQUATION(exp=DAE.Exp.TUPLE(PR=explist1), scalar=call as DAE.CALL(path=Absyn.FULLYQUALIFIED(path),expLst=explist2)), HtCr2U, HtS2U, HtU2S,args)
      equation
        s1=Absyn.pathString(path);
        s1=System.trim(s1,".");
        (invars,outvars,inunitlist,outunitlist)=getNamedUnitlist(s1,args);
        (HtCr2U, HtS2U, HtU2S, expList2) = foldCallArg1(explist1, HtCr2U, HtS2U, HtU2S,NFUnit.MASTER({}),outunitlist,outvars,s1);
        (_, (HtCr2U, HtS2U, HtU2S), expList3) = insertUnitInEquation(call, (HtCr2U, HtS2U, HtU2S),NFUnit.MASTER({}),args);
        expList=List.append_reverse(expList2, expList3);
      then
        (HtCr2U, HtS2U, HtU2S,expList);


    case (DAE.EQUATION(exp=lhs, scalar=call as DAE.CALL(path=Absyn.FULLYQUALIFIED(path),expLst=explist)), HtCr2U, HtS2U, HtU2S,args)
      equation
        s1=Absyn.pathString(path);
        s1=System.trim(s1,".");
        (invars,outvars,_,outunitlist)=getNamedUnitlist(s1,args);
        (ut, (HtCr2U, HtS2U, HtU2S), _) = insertUnitInEquation(lhs, (HtCr2U, HtS2U, HtU2S),NFUnit.MASTER({}),args);
        formalargs =listGet(outunitlist,1);
        formalvar =listGet(outvars,1);
        if (formalargs=="NONE") then
          ut1 =NFUnit.MASTER({});
          else
            ut1 =NFUnit.parseUnitString(formalargs);
        end if;

        (b, _ ,_) = UnitTypesEqual(ut, ut1, HtCr2U);

        if(b==true) then
            expList2 ={};
        else
            temp=makenewcref(lhs,formalvar,s1);
            expList2 = {(lhs, ut),(temp, ut1)}::{};
        end if;
        // rhs
        (_, (HtCr2U, HtS2U, HtU2S), expList3) = insertUnitInEquation(call, (HtCr2U, HtS2U, HtU2S),NFUnit.MASTER({}),args);
        expList=List.append_reverse(expList2, expList3);
        then

          (HtCr2U, HtS2U, HtU2S,expList);


    case (DAE.EQUATION(exp=lhs, scalar=rhs), HtCr2U, HtS2U, HtU2S,args) equation

      temp = DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
        ExpressionDump.dumpExp(temp);
      end if;
        (_, (HtCr2U, HtS2U, HtU2S), expList)=insertUnitInEquation(temp, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      then (HtCr2U, HtS2U, HtU2S,expList);

    case (DAE.ARRAY_EQUATION(exp=lhs, array=rhs), HtCr2U, HtS2U, HtU2S,args) equation
      temp = DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
        ExpressionDump.dumpExp(temp);
      end if;
        (_, (HtCr2U, HtS2U, HtU2S), expList)=insertUnitInEquation(temp, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      then (HtCr2U, HtS2U, HtU2S, expList);
        // solved Equation
    case (DAE.DEFINE(componentRef=cr, exp=rhs), HtCr2U, HtS2U, HtU2S,args) equation
      lhs = DAE.CREF(cr, DAE.T_REAL_DEFAULT);
      temp = DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
        ExpressionDump.dumpExp(temp);
      end if;
        (_, (HtCr2U, HtS2U, HtU2S), expList)=insertUnitInEquation(temp, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      then (HtCr2U, HtS2U, HtU2S, expList);


    case (DAE.COMPLEX_EQUATION(lhs=lhs, rhs=rhs), HtCr2U, HtS2U, HtU2S,args) equation
      temp = DAE.BINARY(rhs, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);
      if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
        ExpressionDump.dumpExp(temp);
      end if;
        (_, (HtCr2U, HtS2U, HtU2S), expList)=insertUnitInEquation(temp, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      then (HtCr2U, HtS2U, HtU2S, expList);


        else equation
          Error.addInternalError("./Compiler/NFFrontEnd/NFUnitCheck.mo: function foldEquation failed", sourceInfo());
        then fail();
  end match;
end foldEquation2;

protected function makenewcref
  input DAE.Exp inexp;
  input String instring;
  input String instring1;
  output DAE.Exp outexp;
algorithm
  outexp:=match(inexp,instring,instring1)
    local
      DAE.ComponentRef cr;
      String name,name1,s1,s2;
    case (DAE.CREF(componentRef=DAE.CREF_IDENT(ident=name )),s1,s2)
      equation
        name=s2+"()"+"."+s1;
        cr=ComponentReference.makeUntypedCrefIdent(name);
        inexp.componentRef=cr;
        outexp=inexp;
      then
        outexp;
  end match;
end makenewcref;

protected function insertUnitInEquation "inserts the units in Equation and check if the equation is consistent or not"
  input DAE.Exp inEq;
  input tuple<NFHashTableCrToUnit.HashTable /* inHtCr2U */, NFHashTableStringToUnit.HashTable /* inHtS2U */, NFHashTableUnitToString.HashTable /* inHtU2S */> inTpl;
  input NFUnit.Unit inUt;
  input list<Functionargs> inargs;
  output NFUnit.Unit outUt;
  output tuple<NFHashTableCrToUnit.HashTable /* outHtCr2U */, NFHashTableStringToUnit.HashTable /* outHtS2U */, NFHashTableUnitToString.HashTable /* outHtU2S */> outTpl;
  output list<list<tuple<DAE.Exp, NFUnit.Unit>>> outexpList;
algorithm
  (outUt, outTpl, outexpList) := matchcontinue(inEq, inTpl, inUt, inargs)
    local
      DAE.ComponentRef cr;
      DAE.Exp exp1, exp2, exp3;
      DAE.Type ty;
      NFHashTableCrToUnit.HashTable HtCr2U;
      NFHashTableStringToUnit.HashTable HtS2U;
      NFHashTableUnitToString.HashTable HtU2S;
      Integer i, i1, i2, i3, i4, i5, i6, i7;
      list<DAE.ComponentRef> lcr, lcr2;
      list<DAE.Exp> ExpList;
      list<list<tuple<DAE.Exp, NFUnit.Unit>>> expListList, expListList2, expListList3;
      Real factor1;
      Real r;
      String s1, s2;
      Absyn.Path path;
      NFUnit.Unit ut, ut2;
      list<String> invars,outvars,inunitlist,outunitlist;
      list<Functionargs> args;
      //SUB equal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut,args);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList=List.append_reverse(expListList, expListList2);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

      //SUB equal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2,args);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList=List.append_reverse(expListList, expListList2);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

      //SUB unequal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut,args);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

      //SUB unequal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2,args);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

      //ADD equal summands
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut,args);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);


      //ADD equal summands
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2,args);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

      //ADD unequal summands
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut,args);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

      //ADD unequal
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2,args);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

      //MUL
    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (ut2 as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      //s1="(" + Unit.unitString(ut, HtU2S) + ").(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = NFUnit.unitMul(ut, ut2);
      s1 = NFUnit.unitString(ut, HtU2S);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER(),args) equation
      (NFUnit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), NFUnit.UNIT(),args) equation
      (NFUnit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (ut2 as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      //s1="(" + Unit.unitString(inUt, HtU2S) + ")/(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = NFUnit.unitDiv(inUt, ut2);
      s1 = NFUnit.unitString(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER(),args) equation
      (NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (NFUnit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), NFUnit.UNIT(),args) equation
      (ut2 as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (NFUnit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      //s1="(" + Unit.unitString(inUt, HtU2S) + ")/(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = NFUnit.unitDiv(inUt, ut2);
      s1 = NFUnit.unitString(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (NFUnit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (NFUnit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

      //DIV
    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (ut2 as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      //s1="(" + Unit.unitString(ut, HtU2S) + ")/(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = NFUnit.unitDiv(ut, ut2);
      s1 = NFUnit.unitString(ut, HtU2S);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER(),args) equation
      (NFUnit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), NFUnit.UNIT(),args) equation
      (NFUnit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (ut2 as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      //s1="(" + Unit.unitString(inUt, HtU2S) + ").(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = NFUnit.unitMul(inUt, ut2);
      s1 = NFUnit.unitString(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER(),args) equation
      (NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (NFUnit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), NFUnit.UNIT(),args) equation
      (ut2 as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (NFUnit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      //s1="(" + Unit.unitString(ut2, HtU2S) + ")/(" + Unit.unitString(inUt, HtU2S) + ")";
      ut = NFUnit.unitDiv(ut2, inUt);
      s1 = NFUnit.unitString(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (NFUnit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (NFUnit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

      //POW
    case (DAE.BINARY(exp1, DAE.POW(), DAE.RCONST(r)), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      i = realInt(r);
      true = realEq(r, intReal(i));
      ut = NFUnit.unitPow(ut, i);
      s1 = NFUnit.unitString(ut, HtU2S);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.POW(), DAE.RCONST(r)), (HtCr2U, HtS2U, HtU2S), ut as NFUnit.UNIT(),args) equation
      (NFUnit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) = NFUnit.unitRoot(ut, r);
      HtCr2U = List.fold1(lcr, updateHtCr2U, NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtCr2U);
      s1 = NFUnit.unitString(NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtU2S);
      HtS2U = addUnit2HtS2U((s1, NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtS2U);
      HtU2S = addUnit2HtU2S((s1, NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.POW(), DAE.RCONST(_)), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

      //DER
    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), NFUnit.UNIT(),args) equation
      (NFUnit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      ut = NFUnit.unitMul(inUt, NFUnit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0));
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      s1 = NFUnit.unitString(ut, HtU2S);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList)=insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      ut=NFUnit.unitDiv(ut, NFUnit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0));
      s1=NFUnit.unitString(ut, HtU2S);
      HtS2U=addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S=addUnit2HtU2S((s1, ut), HtU2S);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER(),args) equation
      (NFUnit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

      //SQRT
    case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut as NFUnit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) = NFUnit.unitRoot(ut, 2.0);
      s1 = NFUnit.unitString(NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtU2S);
      HtS2U = addUnit2HtS2U((s1, NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtS2U);
      HtU2S = addUnit2HtU2S((s1, NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtU2S);
    then
      (NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), NFUnit.UNIT(),args) equation
      (NFUnit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      ut = NFUnit.unitPow(inUt, 2);
      s1 = NFUnit.unitString(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {exp1}), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
    then
      (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

      //IFEXP
    case (DAE.IFEXP(exp1, exp2, exp3), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList3) = insertUnitInEquation(exp3, (HtCr2U, HtS2U, HtU2S), ut,args);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = List.append_reverse(expListList, expListList3);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.IFEXP(exp1, exp2, exp3), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), NFUnit.MASTER({}),args);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList3) = insertUnitInEquation(exp3, (HtCr2U, HtS2U, HtU2S), ut,args);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = List.append_reverse(expListList, expListList3);
      expListList = {(exp2, ut), (exp3, ut2)}::expListList;
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

      //RELATIONS
    case (DAE.RELATION(exp1=exp1), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.RELATION(exp1=exp1, exp2=exp2), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt,args);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

      //all other BINARIES
    case (DAE.BINARY(), (HtCr2U, HtS2U, HtU2S), _,args)
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), {});

      //LBINARY
    case (DAE.LBINARY(), (HtCr2U, HtS2U, HtU2S), _,args)
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), {});

      //LUNARY
    case (DAE.LUNARY(), (HtCr2U, HtS2U, HtU2S), _,args)
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), {});

      //MATRIX
    case (DAE.MATRIX(), (HtCr2U, HtS2U, HtU2S), _,args)
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), {});

      //ARRAY
    case (DAE.ARRAY(), (HtCr2U, HtS2U, HtU2S), _,args)
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), {});

    // builtin function calls
    case (DAE.CALL(path = Absyn.IDENT(name = s1),expLst=ExpList), (HtCr2U, HtS2U, HtU2S), _,_) equation
      (HtCr2U, HtS2U, HtU2S, expListList) = foldCallArg(ExpList, HtCr2U, HtS2U, HtU2S);
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);


      //user defined function CALL
    case (DAE.CALL(path=Absyn.FULLYQUALIFIED(path),expLst=ExpList), (HtCr2U, HtS2U, HtU2S), _,args)
      equation
        s1=Absyn.pathString(path);
        s1=System.trim(s1,".");
        (invars,_,inunitlist,_)=getNamedUnitlist(s1,args);
        (HtCr2U, HtS2U, HtU2S, expListList) = foldCallArg1(ExpList, HtCr2U, HtS2U, HtU2S,inUt,inunitlist,invars,s1);
      then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

        //UMINUS
    case (DAE.UNARY(DAE.UMINUS(), exp1), (HtCr2U, HtS2U, HtU2S), _,args) equation
      (ut, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt,args);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

      //ICONST
    case (DAE.ICONST(), (HtCr2U, HtS2U, HtU2S), _,args)
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S) , {});

      //BCONST
    case (DAE.BCONST(), (HtCr2U, HtS2U, HtU2S), _,args)
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S) , {});

      //SCONST
    case (DAE.SCONST(), (HtCr2U, HtS2U, HtU2S), _,args)
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S) , {});

      //RCONST
    case (DAE.RCONST(), (HtCr2U, HtS2U, HtU2S), _,args)
    then (NFUnit.MASTER({}), (HtCr2U, HtS2U, HtU2S) , {});

      //"time"
    case (DAE.CREF(componentRef=cr), (HtCr2U, HtS2U, HtU2S), _,args) equation
      true = ComponentReference.crefEqual(cr, DAE.crefTime);
      ut = NFUnit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0);
      HtS2U = addUnit2HtS2U(("time", ut), HtS2U);
      HtU2S = addUnit2HtU2S(("time", ut), HtU2S);
    then (ut, (HtCr2U, HtS2U, HtU2S), {});

      //CREF
    case (DAE.CREF(componentRef=cr, ty=DAE.T_REAL()), (HtCr2U, _, _), _,args) equation
      ut = BaseHashTable.get(cr, HtCr2U);
    then (ut, inTpl, {});

      //NO UNIT IN EQUATION
    case (DAE.CREF(), _, _,_)
    then (NFUnit.MASTER({}), inTpl, {});

      // all unhandled expressions, e.g. DAE.CAST, DAE.TUPLE, ...
      else
      equation
        Error.addInternalError("./Compiler/NFFrontEnd/NFUnitCheck.mo: function insertUnitInEquation failed for " + ExpressionDump.printExpStr(inEq), sourceInfo());
        //then fail();
      then (NFUnit.MASTER({}), inTpl, {});
  end matchcontinue;
end insertUnitInEquation;

protected function getNamedUnitlist
  input String instring;
  input list<Functionargs> inargs;
  output list<String> outargs;
  output list<String> outargs2;
  output list<String> outargs3;
  output list<String> outargs4;
algorithm
  (outargs,outargs2,outargs3,outargs4):=match(instring, inargs)
    local
      list<Functionargs> rest;
      String fnname,fnname1;
      list<String> invars,inunitlist, outunitlist,outvars;
    case(fnname,FUNCTIONUNITS(fnname1,invars,outvars,inunitlist,outunitlist)::rest)
      guard stringEq(fnname,fnname1)
      equation
        inunitlist=inunitlist;
        outunitlist=outunitlist;
      then
        (invars,outvars,inunitlist,outunitlist);
    case(fnname,_::rest)
      equation
        (invars,outvars,inunitlist,outunitlist)=getNamedUnitlist(fnname,rest);
      then
        (invars,outvars,inunitlist,outunitlist);
    case(_,_) then ({},{},{},{});
  end match;
end getNamedUnitlist;


protected function UnitTypesEqual "checks equality of two UnitExp's"
  input NFUnit.Unit inut;
  input NFUnit.Unit inut2;
  input NFHashTableCrToUnit.HashTable inHtCr2U;
  output Boolean b;
  output NFUnit.Unit outUt;
  output NFHashTableCrToUnit.HashTable outHtCr2U;
algorithm
  (b, outUt, outHtCr2U) := matchcontinue(inut, inut2, inHtCr2U)
    local
      String s, s2;
      Integer i1, i2, i3, i4, i5, i6, i7;
      Integer j1, j2, j3, j4, j5, j6, j7;
      list<DAE.ComponentRef> lcr, lcr2;
      NFHashTableCrToUnit.HashTable HtCr2U;
      Real factor1, factor2, r;
      NFUnit.Unit ut;

    case (NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), NFUnit.UNIT(factor2, j1, j2, j3, j4, j5, j6, j7), _) equation
      true = realEq(factor1,factor2);
      true = intEq(i1, j1);
      true = intEq(i2, j2);
      true = intEq(i3, j3);
      true = intEq(i4, j4);
      true = intEq(i5, j5);
      true = intEq(i6, j6);
      true = intEq(i7, j7);
    then (true, NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inHtCr2U);

    case (NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), NFUnit.UNIT(factor2, j1, j2, j3, j4, j5, j6, j7), _) equation
      r=realMax(realAbs(factor1), realAbs(factor2));
      true = realLe(realDiv(realAbs(realSub(factor1,factor2)),r),1e-3);
      true = intEq(i1, j1);
      true = intEq(i2, j2);
      true = intEq(i3, j3);
      true = intEq(i4, j4);
      true = intEq(i5, j5);
      true = intEq(i6, j6);
      true = intEq(i7, j7);
    then (true, NFUnit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inHtCr2U);

    case (ut as NFUnit.UNIT(), NFUnit.MASTER(lcr), _) equation
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, inHtCr2U);
    then (true, ut , HtCr2U);

    case (NFUnit.MASTER(lcr), ut as NFUnit.UNIT(), _) equation
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, inHtCr2U);
    then (true, ut, HtCr2U);

    case (NFUnit.MASTER(lcr), NFUnit.MASTER(lcr2), _) equation
      lcr2 = List.append_reverse(lcr, lcr2);
    then (true, NFUnit.MASTER(lcr2), inHtCr2U);

    case (NFUnit.UNKNOWN(s), NFUnit.UNKNOWN(s2), _) equation
      true = stringEqual(s, s2);
    then (true, NFUnit.UNKNOWN(s), inHtCr2U);

    case (NFUnit.UNKNOWN(s), _, _) then (true, NFUnit.UNKNOWN(s), inHtCr2U);
    case (_, NFUnit.UNKNOWN(s), _) then (true, NFUnit.UNKNOWN(s), inHtCr2U);

      else (false, inut, inHtCr2U);
  end matchcontinue;
end UnitTypesEqual;



protected function updateHtCr2U
  input DAE.ComponentRef inCr;
  input NFUnit.Unit inUt;
  input NFHashTableCrToUnit.HashTable inHtCr2U;
  output NFHashTableCrToUnit.HashTable outHtCr2U;
algorithm
  outHtCr2U:=matchcontinue(inCr, inUt, inHtCr2U)
    local
      DAE.ComponentRef cr;
      NFHashTableCrToUnit.HashTable HtCr2U;

    case (_,_,_)
      equation
        true = BaseHashTable.hasKey(NFUnit.UPDATECREF, inHtCr2U);
        BaseHashTable.update((inCr,inUt),inHtCr2U);
      then inHtCr2U;

        else
      equation
        HtCr2U = BaseHashTable.add((NFUnit.UPDATECREF, NFUnit.MASTER({})),inHtCr2U);
        BaseHashTable.update((inCr,inUt),HtCr2U);
      then HtCr2U;

  end matchcontinue;
end updateHtCr2U;



protected function Errorfunction "returns the incostinent Equation with sub-expression"
  input list<tuple<DAE.Exp, NFUnit.Unit>> inexpList;
  input DAE.Element inEq;
  input NFHashTableUnitToString.HashTable inHtU2S;
algorithm
  _ := match(inexpList, inEq, inHtU2S)
    local
      String s, s1, s2, s3, s4;
      list<tuple<DAE.Exp, NFUnit.Unit>> expList;
      DAE.Exp exp1, exp2;
      Integer i;
      SourceInfo info;
    case (expList, _, _)
      equation
        info=getSourceInfo(inEq);
        s = DAEDump.dumpEquationStr(inEq);
        s1 = Errorfunction2(expList, inHtU2S);
        s2="The following equation is INCONSISTENT due to specified unit information:" + s +"\n";
        Error.addSourceMessage(Error.COMPILER_WARNING,{s2},info);
        Error.addCompilerWarning("The units of following sub-expressions need to be equal:\n" + s1);

        /*
        Error.addCompilerWarning("The following NEWFRONTEND UNIT CHECK equation is INCONSISTENT due to specified unit information: " + s + "\n" +
          "The units of following sub-expressions need to be equal:\n" + s1 );*/
      then ();
  end match;
end Errorfunction;

protected function getSourceInfo
input DAE.Element inequation;
output SourceInfo outinfo;
algorithm
  outinfo:=match(inequation)
  local
   SourceInfo info;
  case (DAE.EQUATION(source=DAE.SOURCE(info=info))) then info;
 end match;
end getSourceInfo;

protected function Errorfunction2 "help-function"
  input list<tuple<DAE.Exp, NFUnit.Unit>> inexpList;
  input NFHashTableUnitToString.HashTable inHtU2S;
  output String outS;
algorithm
  outS := match(inexpList, inHtU2S)
    local
      list<tuple<DAE.Exp, NFUnit.Unit>> expList;
      DAE.Exp exp;
      NFUnit.Unit ut;
      String s, s1, s2;

    case ((exp, ut)::{}, _) equation
      s = ExpressionDump.printExpStr(exp);
      s1 = NFUnit.unitString(ut, inHtU2S);
      s = "- sub-expression \"" + s + "\" has unit \"" + s1 + "\"";
    then s;

    case ((exp, ut)::expList, _) equation
      s = ExpressionDump.printExpStr(exp);
      s1 = NFUnit.unitString(ut, inHtU2S);
      s2 = Errorfunction2(expList, inHtU2S);
      s = "- sub-expression \"" + s + "\" has unit \"" + s1 + "\"\n" + s2;
    then s;
  end match;
end Errorfunction2;


public function GetVarList
  input DAE.DAElist indaelist;
  output list<DAE.Element> outstring;
  protected
  list<DAE.Element> varlist;
algorithm
  outstring:=match(indaelist)
    case(DAE.DAE({DAE.COMP(dAElist =varlist)})) then varlist;
    case(_)then {};
  end match;
end GetVarList;

public function GetElementList
  input DAE.DAElist eqlist;
  output list<DAE.Element> outstring;
  protected
  list<DAE.Element> eq1;
  DAE.Element eq2;
algorithm
  outstring:=match(eqlist)
    case(DAE.DAE(eq1)) then eq1;
  end match;
end GetElementList;


protected function foldCallArg "help-function for CALL case in function insertUnitInEquation"
  input list<DAE.Exp> inExpList;
  input NFHashTableCrToUnit.HashTable inHtCr2U;
  input NFHashTableStringToUnit.HashTable inHtS2U;
  input NFHashTableUnitToString.HashTable inHtU2S;
  output NFHashTableCrToUnit.HashTable outHtCr2U = inHtCr2U;
  output NFHashTableStringToUnit.HashTable outHtS2U = inHtS2U;
  output NFHashTableUnitToString.HashTable outHtU2S = inHtU2S;
  output list<list<tuple<DAE.Exp, NFUnit.Unit>>> outExpListList = {};
protected
  list<list<tuple<DAE.Exp, NFUnit.Unit>>> expListList;
algorithm
  for exp in inExpList loop
    (_, (outHtCr2U, outHtS2U, outHtU2S), expListList) :=
      insertUnitInEquation(exp, (outHtCr2U, outHtS2U, outHtU2S), NFUnit.MASTER({}),{});
    outExpListList := List.append_reverse(expListList, outExpListList);
  end for;

  outExpListList := listReverse(outExpListList);
end foldCallArg;


protected function foldCallArg1 "help-function for CALL case in userdefined top level function insertUnitInEquation"
  input list<DAE.Exp> inExpList;
  input NFHashTableCrToUnit.HashTable inHtCr2U;
  input NFHashTableStringToUnit.HashTable inHtS2U;
  input NFHashTableUnitToString.HashTable inHtU2S;
  input NFUnit.Unit inunit;
  input list<String> unitlist;
  input list<String> invars;
  input String fname;
  output NFHashTableCrToUnit.HashTable outHtCr2U = inHtCr2U;
  output NFHashTableStringToUnit.HashTable outHtS2U = inHtS2U;
  output NFHashTableUnitToString.HashTable outHtU2S = inHtU2S;
  output list<list<tuple<DAE.Exp, NFUnit.Unit>>> outExpListList = {};
  protected
  list<list<tuple<DAE.Exp, NFUnit.Unit>>> expListList;
  NFUnit.Unit ut,ut1,ut2;
  String s,formalarg,formalvar;
  list<Functionargs> args;
  DAE.Exp exp,temp;
  Integer count=0;
  Boolean b;
algorithm
  for i in 1:listLength(inExpList) loop
    exp:=listGet(inExpList,i);
    formalarg:=listGet(unitlist,i);
    formalvar:=listGet(invars,i);
    (ut, (outHtCr2U, outHtS2U, outHtU2S), expListList) :=
    insertUnitInEquation(exp, (outHtCr2U, outHtS2U, outHtU2S), inunit,{});
    if (formalarg=="NONE") then
      ut1:=NFUnit.MASTER({});
    else
      ut1:=NFUnit.parseUnitString(formalarg);
    end if;
      s:=NFUnit.unitString(ut,outHtU2S);

    (b, ut,_) := UnitTypesEqual(ut, ut1, outHtCr2U);
    //if(stringEq(s,formalargs)==true) then
      if(b==true) then
        expListList:={};
        else
          temp :=makenewcref(exp,formalvar,fname);
          expListList := {(exp, ut),(temp, ut1)}::{};
      end if;
      outExpListList := List.append_reverse(expListList, outExpListList);
end for;
end foldCallArg1;


protected function addUnit2HtS2U
  input tuple<String, NFUnit.Unit> inTpl;
  input NFHashTableStringToUnit.HashTable inHtS2U;
  output NFHashTableStringToUnit.HashTable outHtS2U;
algorithm
  outHtS2U := BaseHashTable.add(inTpl,inHtS2U);
end addUnit2HtS2U;

protected function addUnit2HtU2S
  input tuple<String, NFUnit.Unit> inTpl;
  input NFHashTableUnitToString.HashTable inHtU2S;
  output NFHashTableUnitToString.HashTable outHtU2S;
algorithm
  outHtU2S := matchcontinue(inTpl, inHtU2S)
    local
      String s;
      NFUnit.Unit ut;
      NFHashTableUnitToString.HashTable HtU2S;

    case ((s, ut), _)
      equation
        false = BaseHashTable.hasKey(ut, inHtU2S);
        HtU2S = BaseHashTable.add((ut,s),inHtU2S);
      then HtU2S;

        else inHtU2S;
  end matchcontinue;
end addUnit2HtU2S;

// get unit information based on old instantiation
protected function convertUnitString2unit_old "converts String to unit"
  input DAE.Element var;
  input tuple<NFHashTableCrToUnit.HashTable /* inHtCr2U */, NFHashTableStringToUnit.HashTable /* HtS2U */, NFHashTableUnitToString.HashTable /* HtU2S */> inTpl;
  output tuple<NFHashTableCrToUnit.HashTable /* outHtCr2U */, NFHashTableStringToUnit.HashTable /* HtS2U */, NFHashTableUnitToString.HashTable /* HtU2S */> outTpl;
algorithm
  outTpl := match(var, inTpl)
    local
      String unitString, s;
      list<String> listStr;
      DAE.ComponentRef cr;
      NFUnit.Unit ut;
      list<DAE.Var> varlst;
      NFHashTableStringToUnit.HashTable HtS2U;
      NFHashTableUnitToString.HashTable HtU2S;
      NFHashTableCrToUnit.HashTable HtCr2U;

    case(DAE.VAR(componentRef=cr,ty=DAE.T_REAL(),variableAttributesOption=SOME(DAE.VAR_ATTR_REAL(unit=SOME(DAE.SCONST(unitString))))),(HtCr2U, HtS2U, HtU2S))
      guard(unitString <> "")
      equation
        (ut, HtS2U, HtU2S) = parse(unitString, cr, HtS2U, HtU2S);
        HtCr2U = BaseHashTable.add((cr,ut),HtCr2U);
      then
        ((HtCr2U, HtS2U, HtU2S));

        // no units
    case(DAE.VAR(componentRef=cr),(HtCr2U, HtS2U, HtU2S))
      equation
        //print ("\n inside Nounits_old ");
        HtCr2U = BaseHashTable.add((cr,NFUnit.MASTER({cr})),HtCr2U);
        HtS2U = addUnit2HtS2U(("-",NFUnit.MASTER({cr})),HtS2U);
        HtU2S = addUnit2HtU2S(("-",NFUnit.MASTER({cr})),HtU2S);
      then
        ((HtCr2U, HtS2U, HtU2S));

    else inTpl; //skip Non-Real Variables

  end match;
end convertUnitString2unit_old;



//based on new Instantiation currently not fully operational
protected function convertUnitString2unit "converts String to unit"
  input DAE.Element var;
  input tuple<NFHashTableCrToUnit.HashTable /* inHtCr2U */, NFHashTableStringToUnit.HashTable /* HtS2U */, NFHashTableUnitToString.HashTable /* HtU2S */> inTpl;
  output tuple<NFHashTableCrToUnit.HashTable /* outHtCr2U */, NFHashTableStringToUnit.HashTable /* HtS2U */, NFHashTableUnitToString.HashTable /* HtU2S */> outTpl;
algorithm
  outTpl := match(var, inTpl)
    local
      String unitString, s;
      list<String> listStr;
      DAE.ComponentRef cr;
      NFUnit.Unit ut;
      list<DAE.Var> varlst;
      NFHashTableStringToUnit.HashTable HtS2U;
      NFHashTableUnitToString.HashTable HtU2S;
      NFHashTableCrToUnit.HashTable HtCr2U;

    case(DAE.VAR(componentRef=cr,ty=DAE.T_REAL(varLst=varlst)),(HtCr2U, HtS2U, HtU2S))
      guard (false==listEmpty(varlst))
      equation
        unitString=parseVarList(varlst);
        (ut, HtS2U, HtU2S) = parse(unitString, cr, HtS2U, HtU2S);
        HtCr2U = BaseHashTable.add((cr,ut),HtCr2U);
      then
        ((HtCr2U, HtS2U, HtU2S));

        // no units
    case(DAE.VAR(componentRef=cr),(HtCr2U, HtS2U, HtU2S))
      equation
        HtCr2U = BaseHashTable.add((cr,NFUnit.MASTER({cr})),HtCr2U);
        HtS2U = addUnit2HtS2U(("-",NFUnit.MASTER({cr})),HtS2U);
        HtU2S = addUnit2HtU2S(("-",NFUnit.MASTER({cr})),HtU2S);
      then
        ((HtCr2U, HtS2U, HtU2S));
  end match;
end convertUnitString2unit;

function parseVarList
  input list<DAE.Var> invarlist;
  output String outstring;
algorithm
  outstring:=match(invarlist)
    local
      list<DAE.Var> varlist;
      DAE.Binding eqbind;
      String s,name;
    case (DAE.Var.TYPES_VAR(name=name,binding=eqbind)::varlist)
      guard stringEq(name,"unit")
      equation
        s=getStringFromExp(eqbind);
      then
        s;
    case(_::varlist)
      equation
        s=parseVarList(varlist);
      then
        s;
    case({}) then "None";
  end match;
end parseVarList;

public function getStringFromExp
  input DAE.Binding binding;
  output String str;
algorithm
  str := match(binding)
    local
      DAE.Exp e;
      Values.Value v;
      String str1;
    case(DAE.UNBOUND()) then "";
    case(DAE.EQBOUND(exp=DAE.SCONST(str1))) then str1;
    case(_)then "None";
  end match;
end getStringFromExp;

protected function parse "author: lochel"
  input String inUnitString;
  input DAE.ComponentRef inCref;
  input NFHashTableStringToUnit.HashTable inHtS2U;
  input NFHashTableUnitToString.HashTable inHtU2S;
  output NFUnit.Unit outUnit;
  output NFHashTableStringToUnit.HashTable outHtS2U = inHtS2U;
  output NFHashTableUnitToString.HashTable outHtU2S = inHtU2S;
algorithm
  try
  outUnit := BaseHashTable.get(inUnitString, inHtS2U);
  else
    outUnit := matchcontinue(inUnitString)
      case ""
      then NFUnit.MASTER({inCref});

      case _
      then NFUnit.parseUnitString(inUnitString, inHtS2U);

    else NFUnit.UNKNOWN(inUnitString);
    end matchcontinue;
    outHtS2U := addUnit2HtS2U((inUnitString, outUnit), outHtS2U);
    outHtU2S := addUnit2HtU2S((inUnitString, outUnit), outHtU2S);
  end try;
end parse;

annotation(__OpenModelica_Interface="frontend");
end NFUnitCheck;

