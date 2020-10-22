encapsulated package FUnitCheck
" file:        UnitCheck.mo
  package:     UnitCheck
  description: This package provides everything for advanced unit checking:
                 - for all variables unspecified units get calculated if possible
                 - inconsistent equations get reported in a user friendly way
               authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)"

public
import Absyn;
import AbsynUtil;
import DAE;
import Unit = FUnit;
import System;

protected
import BaseHashTable;
import ComponentReference;
import Error;
import Expression;
import ExpressionDump;
import Flags;
import HashTableCrToUnit = FHashTableCrToUnit;
import HashTableStringToUnit = FHashTableStringToUnit;
import HashTableUnitToString = FHashTableUnitToString;
import List;
import DAEUtil;
import DAEDump;
import SCode;
import ExecStat.execStat;

public uniontype Functionargs
  record FUNCTIONUNITS
    String name;
    list<String> invars;
    list<String> outvars;
    list<String> inunits;
    list<String> outunits;
  end FUNCTIONUNITS;
end Functionargs;


public function checkUnits
  input DAE.DAElist inDAE;
  input DAE.FunctionTree func;
  output DAE.DAElist outDAE = inDAE;
protected
  DAE.DAElist elts1, elts2;
  list<DAE.Element> eqlist, varlist, newdaelist;
  list<DAE.Function> functionlist;
  list<Functionargs> args;
  HashTableCrToUnit.HashTable HtCr2U1, HtCr2U2;
  HashTableStringToUnit.HashTable HtS2U;
  HashTableUnitToString.HashTable HtU2S;
algorithm
  if not (Flags.getConfigBool(Flags.UNIT_CHECKING) or (Flags.getConfigBool(Flags.CHECK_MODEL) and Flags.isSet(Flags.SCODE_INST))) then
    return;
  end if;
  try
    (elts1, elts2) := DAEUtil.splitDAEIntoVarsAndEquations(inDAE);
    varlist := GetVarList(elts1);
    eqlist := GetElementList(elts2);
    functionlist := DAEUtil.getFunctionList(func);

    HtCr2U1 := HashTableCrToUnit.emptyHashTableSized(Util.nextPrime(integer(10+1.4*listLength(varlist))));
    HtS2U := Unit.getKnownUnits();
    HtU2S := Unit.getKnownUnitsInverse();

    args := {FUNCTIONUNITS("", {}, {}, {}, {})};

    args := List.mapFlat(functionlist, parseFunctionList);

    // new instantiation
    //((HtCr2U1, HtS2U, HtU2S)) := List.fold(varlist, convertUnitString2unit, (HtCr2U1, HtS2U, HtU2S));
    // old instantiation
    ((HtCr2U1, HtS2U, HtU2S)) := List.fold(varlist, convertUnitString2unit_old, (HtCr2U1, HtS2U, HtU2S));
    HtCr2U2 := BaseHashTable.copy(HtCr2U1);
    ((HtCr2U2, HtS2U, HtU2S)) := algo(varlist, eqlist, args, HtCr2U2, HtS2U, HtU2S);
    varlist := List.map2(varlist, returnVar, HtCr2U2, HtU2S);
    newdaelist := listAppend(varlist, eqlist);
    if Flags.isSet(Flags.DUMP_UNIT) then
      BaseHashTable.dumpHashTable(HtCr2U2);
      print("######## UnitCheck COMPLETED ########\n");
    end if;
    notification(HtCr2U1, HtCr2U2, HtU2S);
    outDAE := updateDAElist(inDAE, newdaelist);
  else
    Error.addInternalError(getInstanceName() + ": unit check module failed", sourceInfo());
  end try;

  execStat(getInstanceName());
end checkUnits;



protected function parseFunctionList
  input DAE.Function infunction;
  output list<Functionargs> outTpl;
protected
  list<DAE.Element> inelt, outelt;
  list<String> inunits, outunits, inargs, outargs;
  String unitString, s;
algorithm
  s := getFunctionName(infunction);
  inelt := DAEUtil.getFunctionInputVars(infunction);
  outelt := DAEUtil.getFunctionOutputVars(infunction);
  inunits := List.filterMap(inelt,getUnits);
  outunits := List.filterMap(outelt,getUnits);
  inargs := List.filterMap(inelt,getVars);
  outargs := List.filterMap(outelt,getVars);
  outTpl := {FUNCTIONUNITS(s,inargs,outargs,inunits,outunits)};
end parseFunctionList;



public function getFunctionName
  input DAE.Function inFunction;
  output String outString = AbsynUtil.pathString(AbsynUtil.makeNotFullyQualified(DAEUtil.functionName(inFunction)));
end getFunctionName;

function getVars
  input DAE.Element inElement;
  output String outString;
algorithm
  outString := match inElement
    local
      DAE.ComponentRef cr;

    case DAE.VAR(componentRef=cr)
    then ComponentReference.crefStr(cr);

    else "";
  end match;
end getVars;


function getUnits
  input DAE.Element inElement;
  output String outString;
algorithm
  outString := match inElement
    local
      String unitString;

    case(DAE.VAR(ty=DAE.T_REAL(), variableAttributesOption=SOME(DAE.VAR_ATTR_REAL(unit=SOME(DAE.SCONST(unitString))))))
      guard(unitString <> "")
    then unitString;

    else "NONE";
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

    case(DAE.DAE(elementLst={DAE.COMP(ident=ident,source=eltsrc,comment=comment)}),varlist2)
      equation
        outdae=DAE.DAE({DAE.COMP(ident,varlist2,eltsrc,comment)});
      then
        (outdae);
  end match;
end updateDAElist;


protected function returnVar "returns the new calculated units in DAE"
  input DAE.Element inVar;
  input HashTableCrToUnit.HashTable inHtCr2U;
  input HashTableUnitToString.HashTable inHtU2S;
  output DAE.Element outVar;
algorithm
  outVar := match(inVar)
    local
      DAE.Element var;
      DAE.ComponentRef cr;
      Unit.Unit ut;
      Option<DAE.VariableAttributes> attr;
      String s;

    case (DAE.VAR(variableAttributesOption=SOME(DAE.VAR_ATTR_REAL(unit=SOME(_))))) then inVar;

    case (DAE.VAR(componentRef=cr,variableAttributesOption=attr)) equation
      if BaseHashTable.hasKey(cr, inHtCr2U) then
        ut = BaseHashTable.get(cr, inHtCr2U);
        if Unit.isUnit(ut) then
          s = Unit.unitString(ut, inHtU2S);
          attr = DAEUtil.setUnitAttr(attr, DAE.SCONST(s));
          inVar.variableAttributesOption = attr;
          var = inVar;
        else
          var = inVar;
        end if;
      else
        var = inVar;
      end if;
    then var;
  end match;
end returnVar;



protected function notification "dumps the calculated units"
  input HashTableCrToUnit.HashTable inHtCr2U1;
  input HashTableCrToUnit.HashTable inHtCr2U2;
  input HashTableUnitToString.HashTable inHtU2S;
protected
  String str;
  list<tuple<DAE.ComponentRef, Unit.Unit>> lt1;
algorithm
  lt1 := BaseHashTable.hashTableList(inHtCr2U1);
  str := notification2(lt1, inHtCr2U2, inHtU2S);
  if Flags.isSet(Flags.DUMP_UNIT) and str<>"" then
    Error.addCompilerNotification(str);
  end if;
end notification;


protected function notification2 "help-function"
  input list<tuple<DAE.ComponentRef, Unit.Unit>> inLt1;
  input HashTableCrToUnit.HashTable inHtCr2U2;
  input HashTableUnitToString.HashTable inHtU2S;
  output String outS;
protected
  DAE.ComponentRef cr1=DAE.emptyCref;
  Real factor1=0;
  Integer i1=0, i2=0, i3=0, i4=0, i5=0, i6=0, i7=0;
algorithm
  outS := stringAppendList(list(
  // We already assigned the variables before
  "\"" + ComponentReference.crefStr(cr1) + "\" has the Unit \"" + Unit.unitString(Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inHtU2S) + "\"\n"
  // Do the filtering and unboxing stuff at the same time; then we only need one hashtable call
  // And we only use a try-block for MASTER nodes
  for t1 guard match t1 local Boolean b; case (cr1,Unit.MASTER()) algorithm
    b := false;
    try
      Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) := BaseHashTable.get(cr1, inHtCr2U2);
      b := true;
    else
    end try;
  then b; else false; end match in inLt1
  ));
end notification2;


public function algo "algorithm to check the consistency"
  input list<DAE.Element> invarlist;
  input list<DAE.Element> ineqList;
  input list<Functionargs> inargs;
  input HashTableCrToUnit.HashTable inHtCr2U;
  input HashTableStringToUnit.HashTable inHtS2U;
  input HashTableUnitToString.HashTable inHtU2S;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, HashTableStringToUnit.HashTable /* outHtS2U */, HashTableUnitToString.HashTable /* outHtU2S */> outTpl;
  protected
  HashTableCrToUnit.HashTable HtCr2U;
  HashTableStringToUnit.HashTable HtS2U;
  HashTableUnitToString.HashTable HtU2S;
  Boolean b1, b2, b3;
algorithm
  ((HtCr2U, b1, HtS2U, HtU2S)) := List.fold(invarlist, foldBindingExp, (inHtCr2U, true, inHtS2U, inHtU2S));
  ((HtCr2U, b2, HtS2U, HtU2S)) := List.fold1(ineqList, foldEquation ,inargs,(HtCr2U, true, HtS2U, HtU2S));
  b3 := BaseHashTable.hasKey(FUnit.UPDATECREF, HtCr2U);
  //outTpl := algo2(b1, b2, b3, invarlist, ineqList, HtCr2U, HtS2U, HtU2S);
  outTpl :=(HtCr2U, HtS2U, HtU2S);
end algo;


protected function foldBindingExp "folds the Binding expressions"
  input DAE.Element inVar;
  input tuple<HashTableCrToUnit.HashTable /* inHtCr2U */, Boolean /* success */, HashTableStringToUnit.HashTable /* inHtS2U */, HashTableUnitToString.HashTable /* inHtU2S */> inTpl;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, Boolean /* success */, HashTableStringToUnit.HashTable /* outHtS2U */, HashTableUnitToString.HashTable /* outHtU2S */> outTpl;
algorithm
  outTpl := match(inVar, inTpl)
    local
      DAE.Exp exp, crefExp;
      DAE.ComponentRef cref;
      HashTableCrToUnit.HashTable HtCr2U;
      HashTableStringToUnit.HashTable HtS2U;
      HashTableUnitToString.HashTable HtU2S;
      Boolean b;
      DAE.Element eq;
      DAE.ElementSource source;

    case (DAE.VAR(componentRef=cref, ty=DAE.T_REAL(), binding=SOME(exp),source=source), (HtCr2U, b, HtS2U, HtU2S))
      equation
      crefExp = Expression.crefExp(cref);
      eq = DAE.EQUATION(crefExp, exp, source);
      ((HtCr2U, b, HtS2U, HtU2S))=foldEquation(eq,{},(HtCr2U, b, HtS2U, HtU2S));
    then ((HtCr2U, b, HtS2U, HtU2S));

    case (DAE.VAR(ty=DAE.T_REAL(), binding=SOME(_)), (HtCr2U, _, HtS2U, HtU2S))
    then ((HtCr2U, false, HtS2U, HtU2S));

      else inTpl;
  end match;
end foldBindingExp;



protected function foldEquation "folds the equations or return the error message of incosistent equations"
  input DAE.Element inEq;
  input list<Functionargs> inargs;
  input tuple<HashTableCrToUnit.HashTable /* inHtCr2U */, Boolean /* success */, HashTableStringToUnit.HashTable /* inHtS2U */, HashTableUnitToString.HashTable /* inHtU2S */> inTpl;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, Boolean /* success */, HashTableStringToUnit.HashTable /* outHtS2U */, HashTableUnitToString.HashTable /* outHtU2S */> outTpl;
  protected
  HashTableCrToUnit.HashTable HtCr2U;
  HashTableStringToUnit.HashTable HtS2U;
  HashTableUnitToString.HashTable HtU2S;
  list<list<tuple<DAE.Exp, Unit.Unit>>> expListList;
  Boolean b;
algorithm
  (HtCr2U, b, HtS2U, HtU2S):=inTpl;
  (HtCr2U, HtS2U, HtU2S, expListList):=foldEquation2(inEq, HtCr2U, HtS2U, HtU2S,inargs);
  List.map2_0(expListList, Errorfunction, inEq, HtU2S);
  outTpl := (HtCr2U, b, HtS2U, HtU2S);
end foldEquation;


protected function foldEquation2 "help-function"
  input DAE.Element eq;
  input output HashTableCrToUnit.HashTable htCr2U;
  input output HashTableStringToUnit.HashTable htS2U;
  input output HashTableUnitToString.HashTable htU2S;
  input list<Functionargs> args;
        output list<list<tuple<DAE.Exp, Unit.Unit>>> inconsistentUnits;
algorithm
  inconsistentUnits := match eq
    local
      DAE.Exp temp, lhs;
      list<list<tuple<DAE.Exp, Unit.Unit>>> expList, expList2, expList3;
      Absyn.Path path;
      Boolean b;
      Unit.Unit ut1, ut2;
      String s1, formalargs, formalvar;
      list<String> outvars, outunitlist;
      list<DAE.Exp> expl;

       // solved Equation
    case DAE.DEFINE()
      algorithm
        lhs := DAE.CREF(eq.componentRef, DAE.T_REAL_DEFAULT);
        temp := DAE.BINARY(eq.exp, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);

        if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
          ExpressionDump.dumpExp(temp);
        end if;

        (_, (htCr2U, htS2U, htU2S), inconsistentUnits) :=
          insertUnitInEquation(temp, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        inconsistentUnits;

    case DAE.INITIALDEFINE()
      algorithm
        lhs := DAE.CREF(eq.componentRef, DAE.T_REAL_DEFAULT);
        temp := DAE.BINARY(eq.exp, DAE.SUB(DAE.T_REAL_DEFAULT), lhs);

        if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
          ExpressionDump.dumpExp(temp);
        end if;

        (_, (htCr2U, htS2U, htU2S), inconsistentUnits) :=
          insertUnitInEquation(temp, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        inconsistentUnits;

    case DAE.EQUATION(exp = DAE.Exp.TUPLE(PR = expl),
                      scalar = DAE.CALL(path = Absyn.FULLYQUALIFIED(path)))
      algorithm
        s1 := AbsynUtil.pathString(path);
        s1 := System.trim(s1,".");
        (_, outvars, _, outunitlist) := getNamedUnitlist(s1, args);
        (htCr2U, htS2U, htU2S, expList2) :=
          foldCallArg1(expl, htCr2U, htS2U, htU2S, Unit.MASTER({}), outunitlist, outvars, s1);
        (_, (htCr2U, htS2U, htU2S), expList3) :=
          insertUnitInEquation(eq.scalar, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        List.append_reverse(expList2, expList3);

    case DAE.EQUATION(exp = lhs,
                      scalar = DAE.CALL(path = Absyn.FULLYQUALIFIED(path)))
      algorithm
        s1 := AbsynUtil.pathString(path);
        s1 := System.trim(s1,".");
        (_, outvars, _, outunitlist) := getNamedUnitlist(s1,args);
        (ut1, (htCr2U, htS2U, htU2S), _) :=
          insertUnitInEquation(lhs, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
        formalargs := listHead(outunitlist);
        formalvar := listHead(outvars);

        ut2 := if formalargs == "NONE" then Unit.MASTER({}) else Unit.parseUnitString(formalargs);

        b := UnitTypesEqual(ut1, ut2, htCr2U);
        if b then
          expList2 := {};
        else
          temp := makenewcref(lhs, formalvar, s1);
          expList2 := {(lhs, ut1), (temp, ut2)} :: {};
        end if;
        // rhs
        (_, (htCr2U, htS2U, htU2S), expList3) :=
          insertUnitInEquation(eq.scalar, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        List.append_reverse(expList2, expList3);

    case DAE.EQUATION()
      algorithm
        temp := DAE.BINARY(eq.scalar, DAE.SUB(DAE.T_REAL_DEFAULT), eq.exp);

        if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
          ExpressionDump.dumpExp(temp);
        end if;

        (_, (htCr2U, htS2U, htU2S), inconsistentUnits) :=
          insertUnitInEquation(temp, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        inconsistentUnits;

    case DAE.EQUEQUATION() then {};

    case DAE.INITIALEQUATION()
      algorithm
        temp := DAE.BINARY(eq.exp2, DAE.SUB(DAE.T_REAL_DEFAULT), eq.exp1);

        if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
          ExpressionDump.dumpExp(temp);
        end if;

        (_, (htCr2U, htS2U, htU2S), inconsistentUnits) :=
          insertUnitInEquation(temp, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        inconsistentUnits;

    case DAE.ARRAY_EQUATION()
      algorithm
        temp := DAE.BINARY(eq.array, DAE.SUB(DAE.T_REAL_DEFAULT), eq.exp);

        if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
          ExpressionDump.dumpExp(temp);
        end if;

        (_, (htCr2U, htS2U, htU2S), inconsistentUnits) :=
          insertUnitInEquation(temp, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        inconsistentUnits;

    case DAE.INITIAL_ARRAY_EQUATION()
      algorithm
        temp := DAE.BINARY(eq.array, DAE.SUB(DAE.T_REAL_DEFAULT), eq.exp);

        if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
          ExpressionDump.dumpExp(temp);
        end if;

        (_, (htCr2U, htS2U, htU2S), inconsistentUnits) :=
          insertUnitInEquation(temp, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        inconsistentUnits;

    case DAE.COMPLEX_EQUATION()
      algorithm
        temp := DAE.BINARY(eq.rhs, DAE.SUB(DAE.T_REAL_DEFAULT), eq.lhs);

        if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
          ExpressionDump.dumpExp(temp);
        end if;

        (_, (htCr2U, htS2U, htU2S), inconsistentUnits) :=
          insertUnitInEquation(temp, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        inconsistentUnits;

    case DAE.INITIAL_COMPLEX_EQUATION()
      algorithm
        temp := DAE.BINARY(eq.rhs, DAE.SUB(DAE.T_REAL_DEFAULT), eq.lhs);

        if Flags.isSet(Flags.DUMP_EQ_UNIT_STRUCT) then
          ExpressionDump.dumpExp(temp);
        end if;

        (_, (htCr2U, htS2U, htU2S), inconsistentUnits) :=
          insertUnitInEquation(temp, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        inconsistentUnits;

    case DAE.WHEN_EQUATION()
      algorithm
        for e in eq.equations loop
          (htCr2U, htS2U, htU2S, inconsistentUnits) := foldEquation2(e, htCr2U, htS2U, htU2S, args);
        end for;
      then
        inconsistentUnits;

    case DAE.IF_EQUATION() then {};
    case DAE.INITIAL_IF_EQUATION() then {};

    case DAE.NORETCALL()
      algorithm
        (_, (htCr2U, htS2U, htU2S), inconsistentUnits) :=
          insertUnitInEquation(eq.exp, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        inconsistentUnits;

    case DAE.INITIAL_NORETCALL()
      algorithm
        (_, (htCr2U, htS2U, htU2S), inconsistentUnits) :=
          insertUnitInEquation(eq.exp, (htCr2U, htS2U, htU2S), Unit.MASTER({}), args);
      then
        inconsistentUnits;

    case DAE.INITIAL_ASSERT() then {};
    case DAE.ASSERT() then {};
    case DAE.TERMINATE() then {};
    case DAE.INITIAL_TERMINATE() then {};
    case DAE.REINIT() then {};
    case DAE.ALGORITHM() then {};
    case DAE.INITIALALGORITHM() then {};

    else
      algorithm
        Error.addInternalError(getInstanceName() + " failed on: " +
          DAEDump.dumpEquationStr(eq), sourceInfo());
      then
        fail();
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
  input tuple<HashTableCrToUnit.HashTable /* inHtCr2U */, HashTableStringToUnit.HashTable /* inHtS2U */, HashTableUnitToString.HashTable /* inHtU2S */> inTpl;
  input Unit.Unit inUt;
  input list<Functionargs> inargs;
  output Unit.Unit outUt;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, HashTableStringToUnit.HashTable /* outHtS2U */, HashTableUnitToString.HashTable /* outHtU2S */> outTpl;
  output list<list<tuple<DAE.Exp, Unit.Unit>>> outexpList;
algorithm
  (outUt, outTpl, outexpList) := matchcontinue(inEq, inTpl, inUt)
    local
      DAE.ComponentRef cr;
      DAE.Exp exp1, exp2, exp3;
      DAE.Type ty;
      HashTableCrToUnit.HashTable HtCr2U;
      HashTableStringToUnit.HashTable HtS2U;
      HashTableUnitToString.HashTable HtU2S;
      Integer i, i1, i2, i3, i4, i5, i6, i7;
      list<DAE.ComponentRef> lcr, lcr2;
      list<DAE.Exp> ExpList;
      list<list<tuple<DAE.Exp, Unit.Unit>>> expListList, expListList2, expListList3;
      Real factor1;
      Real r;
      String s1, s2;
      Absyn.Path path;
      Unit.Unit ut, ut2;
      list<String> invars,outvars,inunitlist,outunitlist;

    //SUB equal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut, inargs);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList=List.append_reverse(expListList, expListList2);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    //SUB equal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2, inargs);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList=List.append_reverse(expListList, expListList2);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    //SUB unequal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut, inargs);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then
      (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //SUB unequal summands
    case (DAE.BINARY(exp1, DAE.SUB(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2, inargs);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then
      (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //ADD equal summands
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut, inargs);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);


      //ADD equal summands
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2, inargs);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

      //ADD unequal summands
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), ut, inargs);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then
      (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //ADD unequal
    case (DAE.BINARY(exp1, DAE.ADD(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), ut2, inargs);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then
      (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //MUL
    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      //s1="(" + Unit.unitString(ut, HtU2S) + ").(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = Unit.unitMul(ut, ut2);
      s1 = Unit.unitString(ut, HtU2S);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.MASTER()) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (Unit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      //s1="(" + Unit.unitString(inUt, HtU2S) + ")/(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = Unit.unitDiv(inUt, ut2);
      s1 = Unit.unitString(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.MASTER()) equation
      (Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (Unit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      //s1="(" + Unit.unitString(inUt, HtU2S) + ")/(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = Unit.unitDiv(inUt, ut2);
      s1 = Unit.unitString(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.MUL(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //DIV
    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      //s1="(" + Unit.unitString(ut, HtU2S) + ")/(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = Unit.unitDiv(ut, ut2);
      s1 = Unit.unitString(ut, HtU2S);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.MASTER()) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (Unit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      //s1="(" + Unit.unitString(inUt, HtU2S) + ").(" + Unit.unitString(ut2, HtU2S) + ")";
      ut = Unit.unitMul(inUt, ut2);
      s1 = Unit.unitString(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.MASTER()) equation
      (Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (ut2 as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (Unit.MASTER(varList=lcr), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      //s1="(" + Unit.unitString(ut2, HtU2S) + ")/(" + Unit.unitString(inUt, HtU2S) + ")";
      ut = Unit.unitDiv(ut2, inUt);
      s1 = Unit.unitString(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.DIV(), exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      expListList = List.append_reverse(expListList, expListList2);
    then
      (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //POW
    case (DAE.BINARY(exp1, DAE.POW(), DAE.RCONST(r)), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      i = realInt(r);
      true = realEq(r, intReal(i));
      ut = Unit.unitPow(ut, i);
      s1 = Unit.unitString(ut, HtU2S);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.POW(), DAE.RCONST(r)), (HtCr2U, HtS2U, HtU2S), ut as Unit.UNIT()) equation
      (Unit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) = Unit.unitRoot(ut, r);
      HtCr2U = List.fold1(lcr, updateHtCr2U, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtCr2U);
      s1 = Unit.unitString(Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtU2S);
      HtS2U = addUnit2HtS2U((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtS2U);
      HtU2S = addUnit2HtU2S((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.BINARY(exp1, DAE.POW(), DAE.RCONST(_)), (HtCr2U, HtS2U, HtU2S), _) equation
      (_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
    then
      (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //PRE
    case (DAE.CALL(path=Absyn.IDENT(name="pre"), expLst={exp1}), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    //DER
    case (DAE.CALL(path=Absyn.IDENT(name="der"), expLst={exp1}), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (Unit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      ut = Unit.unitMul(inUt, Unit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0));
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      s1 = Unit.unitString(ut, HtU2S);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then
      (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name="der"), expLst={exp1}), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList)=insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      ut=Unit.unitDiv(ut, Unit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0));
      s1=Unit.unitString(ut, HtU2S);
      HtS2U=addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S=addUnit2HtU2S((s1, ut), HtU2S);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path = Absyn.IDENT(name="der"), expLst={exp1}), (HtCr2U, HtS2U, HtU2S), Unit.MASTER()) equation
      (Unit.MASTER(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //SQRT
    case (DAE.CALL(path=Absyn.IDENT(name="sqrt"), expLst={exp1}), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut as Unit.UNIT(), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7) = Unit.unitRoot(ut, 2.0);
      s1 = Unit.unitString(Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), HtU2S);
      HtS2U = addUnit2HtS2U((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtS2U);
      HtU2S = addUnit2HtU2S((s1, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7)), HtU2S);
    then (Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path=Absyn.IDENT(name="sqrt"), expLst={exp1}), (HtCr2U, HtS2U, HtU2S), Unit.UNIT()) equation
      (Unit.MASTER(lcr), (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      ut = Unit.unitPow(inUt, 2);
      s1 = Unit.unitString(ut, HtU2S);
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, HtCr2U);
      HtS2U = addUnit2HtS2U((s1, ut), HtS2U);
      HtU2S = addUnit2HtU2S((s1, ut), HtU2S);
    then (inUt, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.CALL(path=Absyn.IDENT(name="sqrt"), expLst={exp1}), (HtCr2U, HtS2U, HtU2S), _) equation
      (_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //IFEXP
    case (DAE.IFEXP(_, exp2, exp3), (HtCr2U, HtS2U, HtU2S), _) equation
      //(_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList3) = insertUnitInEquation(exp3, (HtCr2U, HtS2U, HtU2S), ut, inargs);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      //expListList = List.append_reverse(expListList, expListList2);
      //expListList = List.append_reverse(expListList, expListList3);
      expListList = List.append_reverse(expListList2, expListList3);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.IFEXP(_, exp2, exp3), (HtCr2U, HtS2U, HtU2S), _) equation
      //(_, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), Unit.MASTER({}), inargs);
      (ut, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp2, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList3) = insertUnitInEquation(exp3, (HtCr2U, HtS2U, HtU2S), ut, inargs);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      //expListList = List.append_reverse(expListList, expListList2);
      //expListList = List.append_reverse(expListList, expListList3);
      expListList = List.append_reverse(expListList2, expListList3);
      expListList = {(exp2, ut), (exp3, ut2)}::expListList;
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //RELATIONS
    case (DAE.RELATION(exp1=exp1), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (true, ut, HtCr2U) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

    case (DAE.RELATION(exp1=exp1, exp2=exp2), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (ut2, (HtCr2U, HtS2U, HtU2S), expListList2) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
      (false, _, _) = UnitTypesEqual(ut, ut2, HtCr2U);
      expListList = List.append_reverse(expListList, expListList2);
      expListList = {(exp1, ut), (exp2, ut2)}::expListList;
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    // builtin function calls
    case (DAE.CALL(path=Absyn.IDENT(), expLst=ExpList), (HtCr2U, HtS2U, HtU2S), _) equation
      (HtCr2U, HtS2U, HtU2S, expListList) = foldCallArg(ExpList, HtCr2U, HtS2U, HtU2S);
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);


    //user defined function CALL
    case (DAE.CALL(path=Absyn.FULLYQUALIFIED(path), expLst=ExpList), (HtCr2U, HtS2U, HtU2S), _) equation
      s1 = AbsynUtil.pathString(path);
      s1 = System.trim(s1,".");
      (invars, _, inunitlist, _) = getNamedUnitlist(s1, inargs);
      (HtCr2U, HtS2U, HtU2S, expListList) = foldCallArg1(ExpList, HtCr2U, HtS2U, HtU2S, inUt, inunitlist, invars, s1);
    then (Unit.MASTER({}), (HtCr2U, HtS2U, HtU2S), expListList);

    //UMINUS
    case (DAE.UNARY(DAE.UMINUS(), exp1), (HtCr2U, HtS2U, HtU2S), _) equation
      (ut, (HtCr2U, HtS2U, HtU2S), expListList) = insertUnitInEquation(exp1, (HtCr2U, HtS2U, HtU2S), inUt, inargs);
    then (ut, (HtCr2U, HtS2U, HtU2S), expListList);

     //"time"
    case (DAE.CREF(componentRef=cr), (HtCr2U, HtS2U, HtU2S), _) equation
      true = ComponentReference.crefEqual(cr, DAE.crefTime);
      ut = Unit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0);
      HtS2U = addUnit2HtS2U(("time", ut), HtS2U);
      HtU2S = addUnit2HtU2S(("time", ut), HtU2S);
    then (ut, (HtCr2U, HtS2U, HtU2S), {});

    //CREF
    case (DAE.CREF(componentRef=cr, ty=DAE.T_REAL()), (HtCr2U, _, _), _) equation
      ut = BaseHashTable.get(cr, HtCr2U);
    then (ut, inTpl, {});

    //NO UNIT IN EQUATION
    // all unhandled expressions, e.g. DAE.CAST, DAE.TUPLE, ...
    else
      //Error.addInternalError("./Compiler/FrontEnd/FUnitCheck.mo: function insertUnitInEquation failed for " + ExpressionDump.printExpStr(inEq), sourceInfo());
    then (Unit.MASTER({}), inTpl, {});
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
    case(fnname,FUNCTIONUNITS(fnname1,invars,outvars,inunitlist,outunitlist)::_)
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
  input Unit.Unit inut;
  input Unit.Unit inut2;
  input HashTableCrToUnit.HashTable inHtCr2U;
  output Boolean b;
  output Unit.Unit outUt;
  output HashTableCrToUnit.HashTable outHtCr2U;
algorithm
  (b, outUt, outHtCr2U) := matchcontinue(inut, inut2, inHtCr2U)
    local
      String s, s2;
      Integer i1, i2, i3, i4, i5, i6, i7;
      Integer j1, j2, j3, j4, j5, j6, j7;
      list<DAE.ComponentRef> lcr, lcr2;
      HashTableCrToUnit.HashTable HtCr2U;
      Real factor1, factor2, r;
      Unit.Unit ut;

    case (Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), Unit.UNIT(factor2, j1, j2, j3, j4, j5, j6, j7), _) equation
      true = realEq(factor1,factor2);
      true = intEq(i1, j1);
      true = intEq(i2, j2);
      true = intEq(i3, j3);
      true = intEq(i4, j4);
      true = intEq(i5, j5);
      true = intEq(i6, j6);
      true = intEq(i7, j7);
    then (true, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inHtCr2U);

    case (Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), Unit.UNIT(factor2, j1, j2, j3, j4, j5, j6, j7), _) equation
      r=realMax(realAbs(factor1), realAbs(factor2));
      true = realLe(realDiv(realAbs(realSub(factor1,factor2)),r),1e-3);
      true = intEq(i1, j1);
      true = intEq(i2, j2);
      true = intEq(i3, j3);
      true = intEq(i4, j4);
      true = intEq(i5, j5);
      true = intEq(i6, j6);
      true = intEq(i7, j7);
    then (true, Unit.UNIT(factor1, i1, i2, i3, i4, i5, i6, i7), inHtCr2U);

    case (ut as Unit.UNIT(), Unit.MASTER(lcr), _) equation
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, inHtCr2U);
    then (true, ut , HtCr2U);

    case (Unit.MASTER(lcr), ut as Unit.UNIT(), _) equation
      HtCr2U = List.fold1(lcr, updateHtCr2U, ut, inHtCr2U);
    then (true, ut, HtCr2U);

    case (Unit.MASTER(lcr), Unit.MASTER(lcr2), _) equation
      lcr2 = List.append_reverse(lcr, lcr2);
    then (true, Unit.MASTER(lcr2), inHtCr2U);

    case (Unit.UNKNOWN(s), Unit.UNKNOWN(s2), _) equation
      true = stringEqual(s, s2);
    then (true, Unit.UNKNOWN(s), inHtCr2U);

    case (Unit.UNKNOWN(s), _, _) then (true, Unit.UNKNOWN(s), inHtCr2U);
    case (_, Unit.UNKNOWN(s), _) then (true, Unit.UNKNOWN(s), inHtCr2U);

      else (false, inut, inHtCr2U);
  end matchcontinue;
end UnitTypesEqual;



protected function updateHtCr2U
  input DAE.ComponentRef inCr;
  input Unit.Unit inUt;
  input HashTableCrToUnit.HashTable inHtCr2U;
  output HashTableCrToUnit.HashTable outHtCr2U;
algorithm
  outHtCr2U:=matchcontinue(inCr, inUt, inHtCr2U)
    local
      DAE.ComponentRef cr;
      HashTableCrToUnit.HashTable HtCr2U;

    case (_,_,_)
      equation
        true = BaseHashTable.hasKey(FUnit.UPDATECREF, inHtCr2U);
        BaseHashTable.update((inCr,inUt),inHtCr2U);
      then inHtCr2U;

        else
      equation
        HtCr2U = BaseHashTable.add((FUnit.UPDATECREF, Unit.MASTER({})),inHtCr2U);
        BaseHashTable.update((inCr,inUt),HtCr2U);
      then HtCr2U;

  end matchcontinue;
end updateHtCr2U;



protected function Errorfunction "returns the incostinent Equation with sub-expression"
  input list<tuple<DAE.Exp, Unit.Unit>> inexpList;
  input DAE.Element inEq;
  input HashTableUnitToString.HashTable inHtU2S;
algorithm
  _ := match(inexpList, inEq, inHtU2S)
    local
      String s, s1, s2, s3, s4;
      list<tuple<DAE.Exp, Unit.Unit>> expList;
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
  input list<tuple<DAE.Exp, Unit.Unit>> inexpList;
  input HashTableUnitToString.HashTable inHtU2S;
  output String outS;
algorithm
  outS := match(inexpList, inHtU2S)
    local
      list<tuple<DAE.Exp, Unit.Unit>> expList;
      DAE.Exp exp;
      Unit.Unit ut;
      String s, s1, s2;

    case ((exp, ut)::{}, _) equation
      s = ExpressionDump.printExpStr(exp);
      s1 = Unit.unitString(ut, inHtU2S);
      s = "- sub-expression \"" + s + "\" has unit \"" + s1 + "\"";
    then s;

    case ((exp, ut)::expList, _) equation
      s = ExpressionDump.printExpStr(exp);
      s1 = Unit.unitString(ut, inHtU2S);
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
  input HashTableCrToUnit.HashTable inHtCr2U;
  input HashTableStringToUnit.HashTable inHtS2U;
  input HashTableUnitToString.HashTable inHtU2S;
  output HashTableCrToUnit.HashTable outHtCr2U = inHtCr2U;
  output HashTableStringToUnit.HashTable outHtS2U = inHtS2U;
  output HashTableUnitToString.HashTable outHtU2S = inHtU2S;
  output list<list<tuple<DAE.Exp, Unit.Unit>>> outExpListList = {};
protected
  list<list<tuple<DAE.Exp, Unit.Unit>>> expListList;
algorithm
  for exp in inExpList loop
    (_, (outHtCr2U, outHtS2U, outHtU2S), expListList) :=
      insertUnitInEquation(exp, (outHtCr2U, outHtS2U, outHtU2S), Unit.MASTER({}),{});
    outExpListList := List.append_reverse(expListList, outExpListList);
  end for;

  outExpListList := listReverse(outExpListList);
end foldCallArg;


protected function foldCallArg1 "help-function for CALL case in userdefined top level function insertUnitInEquation"
  input list<DAE.Exp> inExpList;
  input HashTableCrToUnit.HashTable inHtCr2U;
  input HashTableStringToUnit.HashTable inHtS2U;
  input HashTableUnitToString.HashTable inHtU2S;
  input Unit.Unit inunit;
  input list<String> unitlist;
  input list<String> invars;
  input String fname;
  output HashTableCrToUnit.HashTable outHtCr2U = inHtCr2U;
  output HashTableStringToUnit.HashTable outHtS2U = inHtS2U;
  output HashTableUnitToString.HashTable outHtU2S = inHtU2S;
  output list<list<tuple<DAE.Exp, Unit.Unit>>> outExpListList = {};
  protected
  list<list<tuple<DAE.Exp, Unit.Unit>>> expListList;
  Unit.Unit ut,ut1,ut2;
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
      ut1:=Unit.MASTER({});
    else
      ut1:=Unit.parseUnitString(formalarg);
    end if;
      s:=Unit.unitString(ut,outHtU2S);

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
  input tuple<String, Unit.Unit> inTpl;
  input HashTableStringToUnit.HashTable inHtS2U;
  output HashTableStringToUnit.HashTable outHtS2U;
algorithm
  outHtS2U := BaseHashTable.add(inTpl,inHtS2U);
end addUnit2HtS2U;

protected function addUnit2HtU2S
  input tuple<String, Unit.Unit> inTpl;
  input HashTableUnitToString.HashTable inHtU2S;
  output HashTableUnitToString.HashTable outHtU2S;
algorithm
  outHtU2S := matchcontinue(inTpl, inHtU2S)
    local
      String s;
      Unit.Unit ut;
      HashTableUnitToString.HashTable HtU2S;

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
  input tuple<HashTableCrToUnit.HashTable /* inHtCr2U */, HashTableStringToUnit.HashTable /* HtS2U */, HashTableUnitToString.HashTable /* HtU2S */> inTpl;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, HashTableStringToUnit.HashTable /* HtS2U */, HashTableUnitToString.HashTable /* HtU2S */> outTpl;
algorithm
  outTpl := match(var, inTpl)
    local
      String unitString, s;
      list<String> listStr;
      DAE.ComponentRef cr;
      Unit.Unit ut;
      list<DAE.Var> varlst;
      HashTableStringToUnit.HashTable HtS2U;
      HashTableUnitToString.HashTable HtU2S;
      HashTableCrToUnit.HashTable HtCr2U;

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
        HtCr2U = BaseHashTable.add((cr,Unit.MASTER({cr})),HtCr2U);
        HtS2U = addUnit2HtS2U(("-",Unit.MASTER({cr})),HtS2U);
        HtU2S = addUnit2HtU2S(("-",Unit.MASTER({cr})),HtU2S);
      then
        ((HtCr2U, HtS2U, HtU2S));

    else inTpl; //skip Non-Real Variables

  end match;
end convertUnitString2unit_old;



//based on new Instantiation currently not fully operational
protected function convertUnitString2unit "converts String to unit"
  input DAE.Element var;
  input tuple<HashTableCrToUnit.HashTable /* inHtCr2U */, HashTableStringToUnit.HashTable /* HtS2U */, HashTableUnitToString.HashTable /* HtU2S */> inTpl;
  output tuple<HashTableCrToUnit.HashTable /* outHtCr2U */, HashTableStringToUnit.HashTable /* HtS2U */, HashTableUnitToString.HashTable /* HtU2S */> outTpl;
algorithm
  outTpl := match(var, inTpl)
    local
      String unitString, s;
      list<String> listStr;
      DAE.ComponentRef cr;
      Unit.Unit ut;
      list<DAE.Var> varlst;
      HashTableStringToUnit.HashTable HtS2U;
      HashTableUnitToString.HashTable HtU2S;
      HashTableCrToUnit.HashTable HtCr2U;

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
        HtCr2U = BaseHashTable.add((cr,Unit.MASTER({cr})),HtCr2U);
        HtS2U = addUnit2HtS2U(("-",Unit.MASTER({cr})),HtS2U);
        HtU2S = addUnit2HtU2S(("-",Unit.MASTER({cr})),HtU2S);
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
    case (DAE.Var.TYPES_VAR(name=name,binding=eqbind)::_)
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
  input HashTableStringToUnit.HashTable inHtS2U;
  input HashTableUnitToString.HashTable inHtU2S;
  output Unit.Unit outUnit;
  output HashTableStringToUnit.HashTable outHtS2U = inHtS2U;
  output HashTableUnitToString.HashTable outHtU2S = inHtU2S;
algorithm
  if inUnitString == "" then
    outUnit := Unit.MASTER({inCref});
    return;
  end if;
  try
    outUnit := BaseHashTable.get(inUnitString, inHtS2U);
  else
    try
      outUnit := Unit.parseUnitString(inUnitString, inHtS2U);
    else
      outUnit := Unit.UNKNOWN(inUnitString);
    end try;
    outHtS2U := addUnit2HtS2U((inUnitString, outUnit), outHtS2U);
    outHtU2S := addUnit2HtU2S((inUnitString, outUnit), outHtU2S);
  end try;
end parse;

annotation(__OpenModelica_Interface="frontend");
end FUnitCheck;
