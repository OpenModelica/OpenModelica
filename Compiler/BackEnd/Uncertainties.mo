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

encapsulated package Uncertainties

public import Absyn;
public import BackendDAE;
public import BackendVarTransform;
public import DAE;
public import FCore;
public import GlobalScript;
public import HashTable;
public import Values;

protected import Algorithm;
protected import BackendDAECreate;
protected import BackendDAEEXT;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVariable;
protected import BaseHashSet;
protected import BaseHashTable;
protected import ClassInf;
protected import ClockIndexes;
protected import ComponentReference;
protected import DAEUtil;
protected import Error;
protected import Expression;
protected import ExpressionSimplify;
protected import ExpressionSolve;
protected import Flags;
protected import HashSet;
protected import HashTable2;
protected import InnerOuter;
protected import Inst;
protected import List;
protected import Matching;
protected import MathematicaDump;
protected import Print;
protected import SCode;
protected import SCodeUtil;
protected import Sorting;
protected import System;
protected import Util;

protected type ExtIncidenceMatrixRow = tuple<Integer,list<Integer>>;
protected type ExtIncidenceMatrix = list<ExtIncidenceMatrixRow>;

protected uniontype AliasSet
  record ALIASSET
    HashSet.HashSet symbols;
    HashTable2.HashTable expl;
    HashTable.HashTable signs;
    Option<DAE.ElementSource> source;
  end ALIASSET;
end AliasSet;


public function modelEquationsUC
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input String outputFileIn;
  input Boolean dumpSteps;
  output FCore.Cache outCache;
  output Values.Value outValue;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;

algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,outputFileIn,dumpSteps)
    local
      String outputFile,resstr;

      DAE.DAElist dae;
      FCore.Cache cache;
      FCore.Graph graph;
      Absyn.Program p;

      BackendDAE.BackendDAE dlow,dlow_1;
      GlobalScript.SymbolTable st;

      BackendDAE.IncidenceMatrix m,mt;

      list<Integer>     approximatedEquations,approximatedEquations_one;
      list<BackendDAE.Equation> setC_eq,setS_eq;
      list<BackendDAE.EqSystem> eqsyslist;
      BackendDAE.Variables allVars,knownVariables,unknownVariables,sharedVars;
      BackendDAE.EquationArray allEqs;
      list<Integer> variables,knowns,unknowns,directlyLinked,indirectlyLinked,outputvars;
      BackendDAE.Shared shared;

      BackendDAE.EqSystem currentSystem;

      ExtIncidenceMatrix mExt;
      list<Integer> setS,setC,unknownsVarsMatch,remainingEquations,removed_equations_squared;

      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;

      String outStringA,outStringB,outString,description;
      list<Option<DAE.Distribution>> distributions;

    case (cache,graph,_,(st as GlobalScript.SYMBOLTABLE(ast = p)),outputFile,_)
      equation
        //print("Initiating\n");
        Print.clearBuf();

        (dae,cache,graph) = flattenModel(className,p,cache);
        description = DAEUtil.daeDescription(dae);
        //print("- Flatten ok\n");
        dlow = BackendDAECreate.lower(dae,cache,graph,BackendDAE.EXTRA_INFO(description,outputFile));
        //(dlow_1,funcs1) = BackendDAEUtil.getSolvedSystem(dlow, funcs,SOME({"removeSimpleEquations","removeFinalParameters", "removeEqualFunctionCalls", "expandDerOperator"}), NONE(), NONE(),NONE());
        (dlow_1) = BackendDAEUtil.getSolvedSystem(dlow,"", SOME({"removeSimpleEquations","removeUnusedVariables","removeEqualFunctionCalls","expandDerOperator"}), NONE(), NONE(), SOME({}));
        //print("* Lowered Ok \n");

        dlow_1 = removeSimpleEquationsUC(dlow_1);

        BackendDAE.DAE(currentSystem::eqsyslist,shared) = dlow_1;
        BackendDAE.EQSYSTEM(orderedVars=allVars,orderedEqs=allEqs) = currentSystem;
        BackendDAE.SHARED(knownVars=sharedVars) = shared;

        (m,_,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.incidenceMatrixScalar(currentSystem,BackendDAE.NORMAL(),NONE());

        //(dlow_1 as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars=allVars,orderedEqs=allEqs,m=SOME(m),mT=SOME(mt))::eqsyslist,_)) = BackendDAEUtil.mapEqSystem(dlow_1,BackendDAEUtil.getIncidenceMatrixScalarfromOptionForMapEqSystem);

        true = listEmpty(eqsyslist);
        mExt=getExtIncidenceMatrix(m);

        //dumpExtIncidenceMatrix(mExt);

        variables = List.intRange(BackendVariable.varsSize(allVars));
        (knowns,_) = getUncertainRefineVariableIndexes(allVars,variables);
        directlyLinked = getRelatedVariables(mExt,knowns);
        indirectlyLinked = List.setDifference(getRelatedVariables(mExt,directlyLinked),knowns);
        unknowns = listAppend(directlyLinked,indirectlyLinked);
        outputvars = List.setDifference(List.intRange(BackendVariable.varsSize(allVars)),listAppend(unknowns,knowns));

         // First try to eliminate all the unknown variables
        dlow_1 = eliminateVariablesDAE(unknowns,dlow_1);

              printSep(getMathematicaText("== Initial system =="));
        //      printSep(getMathematicaText("Equations (Function calls represent more than one equation"));
        //      printSep(equationsToMathematicaGrid(List.intRange(BackendDAEUtil.equationSize(allEqs)),allEqs,allVars,sharedVars,mapIncRowEqn));

        //      printSep(getMathematicaText("All variables"));
        //      printSep(variablesToMathematicaGrid(List.intRange(BackendVariable.varsSize(allVars)),allVars));
        //print("Checkpoint 1\n");
        BackendDAE.DAE(currentSystem::_,shared) = dlow_1;
        BackendDAE.EQSYSTEM(orderedVars=allVars,orderedEqs=allEqs) = currentSystem;
        BackendDAE.SHARED(knownVars=sharedVars) = shared;


        (m,_,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.incidenceMatrixScalar(currentSystem,BackendDAE.NORMAL(),NONE());

              printSep(getMathematicaText("After Symbolic Elimination"));
              printSep(getMathematicaText("Equations (Function calls represent more than one equation)"));
              printSep(equationsToMathematicaGrid(List.intRange(BackendDAEUtil.equationSize(allEqs)),allEqs,allVars,sharedVars,mapIncRowEqn));
              printSep(getMathematicaText("Variables"));
              printSep(variablesToMathematicaGrid(List.intRange(BackendVariable.varsSize(allVars)),allVars));

        mExt=getExtIncidenceMatrix(m);

        approximatedEquations_one = getEquationsWithApproximatedAnnotation(dlow_1);
        approximatedEquations = List.flatten(List.map1r(approximatedEquations_one,listGet,arrayList(mapEqnIncRow)));

        mExt=removeEquations(mExt,approximatedEquations);

              printSep(getMathematicaText("Approximated equations to be removed"));
              printSep(equationsToMathematicaGrid(approximatedEquations,allEqs,allVars,sharedVars,mapIncRowEqn));

              printSep(getMathematicaText("After eliminating approximated equations"));
              printSep(equationsToMathematicaGrid(getEquationsNumber(mExt),allEqs,allVars,sharedVars,mapIncRowEqn));

        // get the variable indices after the elimination
        variables = List.intRange(BackendVariable.varsSize(allVars));
        (knowns,distributions) = getUncertainRefineVariableIndexes(allVars,variables);
        directlyLinked = getRelatedVariables(mExt,knowns);
        indirectlyLinked = List.setDifference(getRelatedVariables(mExt,directlyLinked),knowns);
        unknowns = listAppend(directlyLinked,indirectlyLinked);
        outputvars = List.setDifference(List.intRange(BackendVariable.varsSize(allVars)),listAppend(unknowns,knowns));


              printSep(getMathematicaText("Known variables"));
              printSep(variablesToMathematicaGrid(knowns,allVars));

              printSep(getMathematicaText("Directly linked variables"));
              printSep(variablesToMathematicaGrid(directlyLinked,allVars));

              printSep(getMathematicaText("Indirectly linked variables"));
              printSep(variablesToMathematicaGrid(indirectlyLinked,allVars));

              printSep(getMathematicaText("Output variables"));
              printSep(variablesToMathematicaGrid(outputvars,allVars));

        mExt=eliminateOutputVariables(mExt,outputvars);

              printSep(getMathematicaText("After eliminating output variables"));
              printSep(equationsToMathematicaGrid(getEquationsNumber(mExt),allEqs,allVars,sharedVars,mapIncRowEqn));

        (setS,unknownsVarsMatch)=getEquationsForUnknownsSystem(mExt,knowns,unknowns);

              printSep(getMathematicaText("Matching performed after step 5 (Set S)"));
              printSep(unknowsMatchingToMathematicaGrid(unknownsVarsMatch,setS,allEqs,allVars,sharedVars,mapIncRowEqn));

        remainingEquations=List.setDifference(getEquationsNumber(mExt),setS);

              printSep(getMathematicaText("Remaining equations"));
              printSep(equationsToMathematicaGrid(remainingEquations,allEqs,allVars,sharedVars,mapIncRowEqn));

        (setC,removed_equations_squared)=getEquationsForKnownsSystem(mExt,knowns,unknowns,setS,allEqs,allVars,sharedVars,mapIncRowEqn);

        if not listEmpty(removed_equations_squared) then
          print("Warning: the system is ill-posed. One or more equations have been removed from squared system of knowns.\n");
        end if;
              printSep(getMathematicaText("Equations removed from squared blocks (with more than one equation)"));
              printSep(equationsToMathematicaGrid(removed_equations_squared,allEqs,allVars,sharedVars,mapIncRowEqn));

              printSep(getMathematicaText("Final Equations"));
              printSep(equationsToMathematicaGrid(setC,allEqs,allVars,sharedVars,mapIncRowEqn));


        setC = List.map1r(setC, listGet, arrayList(mapIncRowEqn));
        setC = List.unique(setC);
        setS = List.map1r(setS, listGet, arrayList(mapIncRowEqn));
        setS = List.unique(setS);

        setC_eq = List.map1r(setC, BackendEquation.equationNth1, allEqs);
        setS_eq = List.map1r(setS, BackendEquation.equationNth1, allEqs);

       //eqnLst = BackendEquation.equationList(eqns);

        knownVariables = BackendVariable.listVar(List.map1r(knowns,BackendVariable.getVarAt,allVars));
        unknownVariables = BackendVariable.listVar(List.map1r(unknowns,BackendVariable.getVarAt,allVars));

        //print("* Uncertainty equations extracted: \n");
        //BackendDump.dumpEquationList(setC_eq);

        //print("* Auxiliary set of equations: \n");
        //BackendDump.dumpEquationList(setS_eq);

        outStringB = "{{"+getMathematicaVarStr(knownVariables)+","+getMathematicaEqStr(setC_eq,allVars,sharedVars)+"},{"
                        +getMathematicaVarStr(unknownVariables)+","+getMathematicaEqStr(setS_eq,allVars,sharedVars)+"},"
                        +dumpVarsDistributionInfo(distributions)+"}";
        Print.printBuf("{"+getMathematicaText("Extraction finished")+"}");
        outStringA = "Grid[{"+Print.getString()+"}]";

        outString=if dumpSteps then outStringA else outStringB;
        resstr=writeFileIfNonEmpty(outputFile,outString);
        //resstr="Done...";
      then
        (cache,Values.STRING(resstr),st);
    case (_,_,_,_,outputFile,_)
      equation
        Print.printBuf("{"+getMathematicaText("Extraction failed")+"}");
        outStringA = "Grid[{"+Print.getString()+"}]";
        _=writeFileIfNonEmpty(outputFile,outStringA);
        true = Flags.isSet(Flags.FAILTRACE);
        resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"modelEquationsUC: The model equations in model",resstr," could not be extracted"});
        Error.addMessage(Error.INTERNAL_ERROR, {resstr});
      then
        fail();
  end matchcontinue;
end modelEquationsUC;

protected function printSep
  input String s;
algorithm
  Print.printBuf("{ ");
  Print.printBuf(s);
  Print.printBuf("} , ");
end printSep;

protected function wrapInList
  input String text;
  output String oText;
algorithm
  oText:="{"+text+"}";
end wrapInList;

protected function verticalGrid
  input list<String> elems;
  output String out;
algorithm
  out:="Grid[{"+stringDelimitList(List.map(elems,wrapInList),",")+"}]";
end verticalGrid;

protected function verticalGridBoxed
  input list<String> elems;
  output String out;
algorithm
  out:="Grid[{"+stringDelimitList(List.map(elems,wrapInList),",")+"},Frame -> All]";
end verticalGridBoxed;

protected function numerateList
  input list<String> elems;
  input Integer index;
  output String out;
algorithm
  out:=matchcontinue(elems,index)
    local String h,s,ss; list<String> t;
    case({},_)
      then "";
    case({h},_)
      equation
        s="{"+(intString(index))+","+h+"}";
      then s;
    case(h::t,_)
        equation
          s="{"+(intString(index))+","+h+"}";
          ss=s+","+(numerateList(t,index+1));
        then ss;
  end matchcontinue;
end numerateList;

protected function numerateListIndex
  input list<String> elems;
  input list<Integer> indices;
  output String out;
algorithm
  out:=matchcontinue(elems,indices)
    local String h,s,ss; list<String> t;Integer n; list<Integer> tn;
    case({},_)
      then "";
    case({h},{n})
      equation
        s="{"+(intString(n))+","+h+"}";
      then s;
    case(h::t,n::tn)
        equation
          s="{"+(intString(n))+","+h+"}";
          ss=s+","+(numerateListIndex(t,tn));
        then ss;
  end matchcontinue;

end numerateListIndex;

protected function equationsToMathematicaGrid
  input list<Integer> equIndices;
  input BackendDAE.EquationArray allEqs;
  input BackendDAE.Variables variables;
  input BackendDAE.Variables knownVariables;
  input array<Integer> mapIncRowEqn;
  output String out;
  protected list<BackendDAE.Equation> eqList;
  list<String> eqsString;
  list<Integer> eqns;
algorithm
  eqns:=List.unique(List.map1r(equIndices, listGet, arrayList(mapIncRowEqn)));
  eqList:=List.map1r(eqns, BackendEquation.equationNth1, allEqs);
  eqsString:=List.map1(eqList, MathematicaDump.printMmaEqnStr, (variables, knownVariables));
  out:="Grid[{"+numerateListIndex(eqsString, eqns)+"}, Frame -> All]";
end equationsToMathematicaGrid;


protected function unknowsMatchingToMathematicaGrid2
  input list<String> vars;
  input list<String> eqns;
  output list<String> out;
algorithm
out:=matchcontinue(vars,eqns)
  local
    String var,eqn,s;
    list<String> var_t,eqn_t,r;
  case({},{})
    equation
    then {};
  case({},_)
    equation print("Warning: The system is ill-posed. When computing the unknowns, there are more equations than variables.\n");
    then {};
  case(_,{})
    equation print("Warning: The system is ill-posed. When computing the unknowns, there are more variables than equations.\n");
    then {};
  case(var::var_t,eqn::eqn_t)
      equation
        s = var+","+eqn;
        r = unknowsMatchingToMathematicaGrid2(var_t,eqn_t);
      then s::r;
  end matchcontinue;
end unknowsMatchingToMathematicaGrid2;

protected function getEquationStringOrNothing
  input list<Integer> equations;
  input BackendDAE.EquationArray allEqs;
  input BackendDAE.Variables variables;
  input BackendDAE.Variables knownVariables;
  input array<Integer> mapIncRowEqn;
  output list<String> out;
algorithm
out:=matchcontinue(equations,allEqs,variables,knownVariables,mapIncRowEqn)
  local
    Integer eqn;
    list<Integer> eqn_t;
    String s;
    list<String> r;
    BackendDAE.Equation e;

  case({},_,_,_,_) then {};

  case(eqn::eqn_t,_,_,_,_)
   equation
      true = intEq(eqn,0);
      r = getEquationStringOrNothing(eqn_t,allEqs,variables,knownVariables,mapIncRowEqn);
      s = "\"-\"";
    then s::r;
  case(eqn::eqn_t,_,_,_,_)
    equation
      e = BackendEquation.equationNth1(allEqs,eqn);
      r = getEquationStringOrNothing(eqn_t,allEqs,variables,knownVariables,mapIncRowEqn);
      s = MathematicaDump.printMmaEqnStr(e,(variables,knownVariables));
    then s::r;
end matchcontinue;
end getEquationStringOrNothing;

protected function unknowsMatchingToMathematicaGrid
  input list<Integer> vars;
  input list<Integer> equations;
  input BackendDAE.EquationArray allEqs;
  input BackendDAE.Variables variables;
  input BackendDAE.Variables knownVariables;
  input array<Integer> mapIncRowEqn;
  output String out;
  protected
  list<BackendDAE.Equation> eqList;
  list<BackendDAE.Var> varList;
  list<String> eqsString,varString;
  list<Integer> eqns;
algorithm
  eqns:=List.map1r(equations,listGet,arrayList(mapIncRowEqn));
  eqsString:=getEquationStringOrNothing(eqns,allEqs,variables,knownVariables,mapIncRowEqn);
  varList:=List.map1r(vars,BackendVariable.getVarAt,variables);
  varString:=List.map2(varList,MathematicaDump.printMmaVarStr,false,variables);
  out:=verticalGridBoxed(unknowsMatchingToMathematicaGrid2(varString,eqsString));
end unknowsMatchingToMathematicaGrid;


protected function variablesToMathematicaGrid
  input list<Integer> varIndices;
  input BackendDAE.Variables variables;
  output String out;
  protected list<BackendDAE.Var> varList;
  list<String> eqsString;
algorithm
  varList:=List.map1r(varIndices,BackendVariable.getVarAt,variables);
  eqsString:=List.map2(varList,MathematicaDump.printMmaVarStr,false,variables);
  out:="Grid[{"+numerateListIndex(eqsString,varIndices)+"},Frame -> All]";
end variablesToMathematicaGrid;


protected function writeFileIfNonEmpty
  input String filename;
  input String content;
  output String out;
algorithm
out:=matchcontinue(filename,content)
    local String directory;
    case("",_)
      equation
        //print("Mathematica Expression =\n"+content);
      then content;
    case(_,_)
      equation
        directory=System.dirname(filename);
        true=System.directoryExists(directory);
        //print("Writing file "+filename);
        System.writeFile(filename,content);
      then "Done...";
    case(_,_)
        equation
          //print("Mathematica Expression =\n"+content);
        then content;
  end matchcontinue;
end writeFileIfNonEmpty;

protected function dumpVarDistributionInfo
  input Option<DAE.Distribution> d;
  output String out;
algorithm
out:=match(d)
local
  DAE.Exp name,params,paramNames;
  String e1,e2,e3,s,s1;
case(SOME(DAE.DISTRIBUTION(name,params,paramNames)))
  equation
    e1=MathematicaDump.printExpMmaStr(name,BackendVariable.emptyVars(),BackendVariable.emptyVars());
    e2=MathematicaDump.printExpMmaStr(params,BackendVariable.emptyVars(),BackendVariable.emptyVars());
    e3=MathematicaDump.printExpMmaStr(paramNames,BackendVariable.emptyVars(),BackendVariable.emptyVars());
    s1=stringDelimitList({e1,e2,e3},",");
    s=stringAppendList({"{",s1,"}"});
  then s;
  case(NONE())
    then "\"None\"";
end match;
end dumpVarDistributionInfo;

protected function dumpVarsDistributionInfo
  input list<Option<DAE.Distribution>> d;
  output String s;
algorithm
  s:="{"+stringDelimitList(List.map(d,dumpVarDistributionInfo),",")+"}";
end dumpVarsDistributionInfo;

protected function getEquationsWithApproximatedAnnotation
   input BackendDAE.BackendDAE dae;
   output list<Integer> outEqs;
algorithm
  outEqs:=match(dae)
     local
       BackendDAE.EquationArray orderedEqs;
       list<Integer> ret;
    case(BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedEqs=orderedEqs)::_,_))
      equation
        ret=getEquationsWithApproximatedAnnotation2(BackendEquation.equationList(orderedEqs),1);
      then
        ret;
    case(_)
      then {};
  end match;
end getEquationsWithApproximatedAnnotation;

protected function getEquationsWithApproximatedAnnotation2
   input list<BackendDAE.Equation> eqs;
   input Integer index;
   output list<Integer> listOut;
algorithm
   listOut:=
      matchcontinue(eqs,index)
        local
          BackendDAE.Equation h;
          list<BackendDAE.Equation> t;
          list<Integer> inner_ret;
          Integer i;
        case ({},_)
          then
            {};
        case(h::t,i)
          equation
            true=isApproximatedEquation(h);
            inner_ret = getEquationsWithApproximatedAnnotation2(t,i+1);
          then
            i::inner_ret;
        case(_::t,i)
          equation
            inner_ret = getEquationsWithApproximatedAnnotation2(t,i+1);
          then
            inner_ret;
      end matchcontinue;
end getEquationsWithApproximatedAnnotation2;

protected function isApproximatedEquation
  input BackendDAE.Equation eqn;
  output Boolean out;
algorithm
  out:= match(eqn)
    local
      list<SCode.Comment> comment;
      Boolean ret;
    case(BackendDAE.EQUATION(source=DAE.SOURCE(comment=comment)))
      equation
        ret = isApproximatedEquation2(comment);
      then
        ret;
    case(_)
      then
        false;
  end match;
end isApproximatedEquation;

protected function isApproximatedEquation2
  input list<SCode.Comment> commentIn;
  output Boolean out;
 algorithm
  out:= matchcontinue(commentIn)
    local
      SCode.Comment h;
      list<SCode.Comment> t;
      Boolean ret;
      list<SCode.SubMod> subModLst;
    case({})
      equation
        then false;
    case(SCode.COMMENT(annotation_=SOME(SCode.ANNOTATION(SCode.MOD(subModLst=subModLst))))::t)
      equation
        ret = (List.exist(subModLst,isApproximatedEquation3)) or isApproximatedEquation2(t);
      then
        ret;
    case(_::t)
      equation
        ret = isApproximatedEquation2(t);
      then
        ret;
  end matchcontinue;
end isApproximatedEquation2;

protected function isApproximatedEquation3
  input SCode.SubMod m;
  output Boolean out;
algorithm
out:= match(m)
  case(SCode.NAMEMOD("__OpenModelica_ApproximatedEquation",SCode.MOD(binding = SOME(Absyn.BOOL(true)))))
     then true;
  case(_)
     then false;
   end match;
end isApproximatedEquation3;


protected function flattenModel
  input Absyn.Path className;
  input Absyn.Program p;
  input FCore.Cache icache;
  output DAE.DAElist daeOut;
  output FCore.Cache cacheOut;
  output FCore.Graph graphOut;
algorithm
(daeOut,cacheOut,graphOut):=matchcontinue(className,p,icache)
  local
    list<SCode.Element> p_1;
    Absyn.Program ptot;
    DAE.DAElist dae;
    FCore.Graph graph;
    Real timeFrontend;
    String resstr;
    FCore.Cache cache;
  case(_,_,_)
    equation
      System.realtimeTick(ClockIndexes.RT_CLOCK_UNCERTAINTIES);
      p_1 = SCodeUtil.translateAbsyn2SCode(p);
      (cache,graph,_,dae) = Inst.instantiateClass(icache,InnerOuter.emptyInstHierarchy,p_1,className);
      _ = System.realtimeTock(ClockIndexes.RT_CLOCK_UNCERTAINTIES);
      System.realtimeTick(ClockIndexes.RT_CLOCK_BACKEND);
      dae = DAEUtil.transformationsBeforeBackend(cache,graph,dae);
    then (dae,cache,graph);
  else
      equation
        resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"modelEquationsUC: The model ",resstr," could not be flattened"});
        Error.addMessage(Error.INTERNAL_ERROR, {resstr});
      then fail();
end matchcontinue;
end flattenModel;

protected function getMathematicaVarStr
  input BackendDAE.Variables vars;
  output String out;
  protected list<String> states,algs,outputs,inputsStates;
  protected String s1;
algorithm
  (states,algs,outputs,inputsStates) := MathematicaDump.printMmaVarsStr(vars);
  out := "{"+Util.stringDelimitListNonEmptyElts(listAppend(listAppend(states,algs),listAppend(outputs,inputsStates)),",")+"}";
end getMathematicaVarStr;

protected function getMathematicaEqStr
  input list<BackendDAE.Equation> eqns;
  input BackendDAE.Variables systemVars;
  input BackendDAE.Variables sharedVars;
  output String out;
algorithm
  out:= MathematicaDump.printMmaEqnsStr(eqns,(systemVars,sharedVars));
end getMathematicaEqStr;

protected function getEquationsForUnknownsSystem
  input ExtIncidenceMatrix m;
  input list<Integer> knowns;
  input list<Integer> unknowns;
  output list<Integer> eqnsOut;
  output list<Integer> varsOut;
algorithm
(eqnsOut,varsOut):=matchcontinue(m,knowns,unknowns)
  local
    ExtIncidenceMatrix unknownsSystem;
    list<Integer> yEqMap,yVarMap,setS;
    Integer nv,ne;
    BackendDAE.IncidenceMatrix my;
    array<Integer> ass1,ass2;
    list<Integer> vars;
  case(_,_,{})
    equation
    then ({},{});
  case(_,_,_)
    equation
        unknownsSystem=getSystemForUnknowns(m,knowns,unknowns);

        (yEqMap,yVarMap,my)=prepareForMatching(unknownsSystem);
        //Debug.fcall(Flags.UNCERTAINTIES,BackendDump.dumpIncidenceMatrix,my);

        ne=listLength(yEqMap);
        nv=listLength(yVarMap);
        ass1=arrayCreate(ne,-1);
        ass2=arrayCreate(nv,-1);
        true = BackendDAEEXT.setAssignment(ne,nv,ass1,ass2);
        Matching.matchingExternalsetIncidenceMatrix(nv,ne,my);
        BackendDAEEXT.matching(nv,ne,1,-1,0.0,0);
        BackendDAEEXT.getAssignment(ass1,ass2);
        //printIntList(arrayList(ass1));
        //printIntList(arrayList(ass2));
        vars = yVarMap;
        setS = restoreIndicesEquivalence(List.filter1OnTrue(arrayList(ass2),intGt,-1),yEqMap);
    then (setS,vars);
end matchcontinue;
end getEquationsForUnknownsSystem;

protected function getEquationsForKnownsSystem
  input ExtIncidenceMatrix m;
  input list<Integer> knowns;
  input list<Integer> unknowns;
  input list<Integer> setS;
  input BackendDAE.EquationArray allEqs;
  input BackendDAE.Variables variables;
  input BackendDAE.Variables knownVariables;
  input array<Integer> mapIncRowEqn;
  output list<Integer> setCOut;
  output list<Integer> removed_equations_squaredOut;
algorithm
(setCOut,removed_equations_squaredOut):=matchcontinue(m,knowns,unknowns,setS,allEqs,variables,knownVariables,mapIncRowEqn)
  local
    ExtIncidenceMatrix knownsSystem,knownsSystemComp;
    list<Integer> xEqMap,xVarMap;
    BackendDAE.IncidenceMatrix mx,mt;
    array<Integer> ass1,ass2;
    list<list<Integer>> comps,comps_fixed;
    list<Integer> setC,removed_equations_squared;
    Integer nxVarMap,nxEqMap,size;
  case(_,{},_,_,_,_,_,_)
    equation
    then ({},{});
  case(_,_,_,_,_,_,_,_)
      equation
        //print("Knowns = ");printIntList(knowns);print(";\n");
        //print("Cleaning up system of knowns..");
        knownsSystem = removeEquations(m,setS);
        knownsSystem = removeUnrelatedEquations(knownsSystem,knowns);
        true = listEmpty(knownsSystem);
        print("Warning: The system is ill-posed. There are no remaining equations containing the knowns.\n");
    then
      ({},{});
  case(_,_,_,_,_,_,_,_)
      equation
        //print("Knowns = ");printIntList(knowns);print(";\n");
        //print("Cleaning up system of knowns..");
        knownsSystem = removeEquations(m,setS);
        knownsSystem = removeUnrelatedEquations(knownsSystem,knowns);


        printSep(getMathematicaText("System of knowns after step 7"));
        printSep(equationsToMathematicaGrid(getEquationsNumber(knownsSystem),allEqs,variables,knownVariables,mapIncRowEqn));


        knownsSystemComp=sortEquations(knownsSystem,knowns);
        knownsSystemComp=removeVarsNotInSet(knownsSystemComp,knowns,{});

        //knownsSystemComp=reduceVariables(knownsSystemComp,knowns);
        //dumpExtIncidenceMatrix(knownsSystemComp);

        (xEqMap,xVarMap,mx)=prepareForMatching(knownsSystemComp);
        nxVarMap = listLength(xVarMap);
        nxEqMap = listLength(xEqMap);
        size=if nxEqMap>nxVarMap then nxEqMap else nxVarMap;
        //print("Final matching of "+intString(nxEqMap)+" equations and "+intString(nxVarMap)+" variables \n");
        Matching.matchingExternalsetIncidenceMatrix(size,size,mx);

        //BackendDump.dumpIncidenceMatrix(mx);
        ass1=listArray(List.fill(0,size));
        ass2=listArray(List.fill(0,size));

        true = BackendDAEEXT.setAssignment(size,size,ass2,ass1);
        BackendDAEEXT.matching(size,size,1,-1,1.0,0);

        BackendDAEEXT.getAssignment(ass1,ass2);

        //printIntList(arrayList(ass1));
        //printIntList(arrayList(ass2));

        mt = BackendDAEUtil.transposeMatrix(mx,nxVarMap);

        comps = getComponentsWrapper(mx,mt,ass1,ass2);
        //print("Removing equations larget than "+intString(listLength(xEqMap))+"\n");
        comps = removeDummyEquations(comps,listLength(xEqMap));
        //BackendDump.dumpComponentsOLD(comps);

        comps_fixed =List.map1(comps,restoreIndicesEquivalence,xEqMap);
        (knownsSystem,removed_equations_squared)=removeEquationInSquaredBlock(knownsSystem,knowns,unknowns,comps_fixed);
        //BackendDump.dumpComponentsOLD(comps_fixed);

        comps_fixed = List.map1(comps_fixed,restoreIndicesEquivalence,arrayList(mapIncRowEqn)); // this is done to print the correct numbers
        printSep(getMathematicaText("Blocks (each row is a block)"));
        printSep("Grid["+listString(List.map(comps_fixed,intListString))+",Frame->All]");


        printSep(getMathematicaText("System of knowns after step 8 and 9"));
        printSep(equationsToMathematicaGrid(getEquationsNumber(knownsSystem),allEqs,variables,knownVariables,mapIncRowEqn));

        checkSystemContainsVars(knownsSystem,knowns,variables);
        setC=getEquationsNumber(knownsSystem);
      then (setC,removed_equations_squared);
end matchcontinue;
end getEquationsForKnownsSystem;


protected function printVarReduction
  input list<tuple<list<Integer>,list<Integer>>> elems;
algorithm
  print("Reduced variables:\n");
  print(stringDelimitList(List.map(elems,printVarReduction2),"\n"));
end printVarReduction;

protected function printVarReduction2
  input tuple<list<Integer>,list<Integer>> elem;
  output String out;
  protected
  list<Integer> occurrences,vars;
algorithm
  (occurrences,vars) := elem;
  out:= "("+stringDelimitList(List.map(vars,intString),",")+") ("+stringDelimitList(List.map(occurrences,intString),",")+")";
end printVarReduction2;

protected function pickReductionCandidates
  input list<tuple<list<Integer>,list<Integer>>> elems;
  output list<list<Integer>> elemsOut;
algorithm
elemsOut:=matchcontinue(elems)
  local
    list<Integer> occurrence,vars;
    list<tuple<list<Integer>,list<Integer>>> tail;
    list<list<Integer>> newElems;
  case({}) then {};
  case((occurrence,vars)::tail)
    equation
      true = listLength(vars)>1 and listLength(occurrence)>1;
      newElems = pickReductionCandidates(tail);
    then
      vars::newElems;
  case(_::tail)
     then pickReductionCandidates(tail);
end matchcontinue;
end pickReductionCandidates;

protected function reduceVariables
  input ExtIncidenceMatrix m;
  input list<Integer> knowns;
  output ExtIncidenceMatrix mOut;
protected
  Integer neq,nvar;
  list<Integer> variables;
  list<list<Integer>> occurrences,candidates;
  list<tuple<list<Integer>,list<Integer>>> reducedVars;
  ExtIncidenceMatrix newM;
algorithm
  mOut:=matchcontinue(m,knowns)
    case(_,_)
    equation
      neq = listLength(getEquationsNumber(m));
      variables = getVariables(m);
      nvar = listLength(variables);
      true =  neq>=nvar; // The system is squared or overdetermined do nothing
    then
      m;
    case(_,_)
    equation
      neq = listLength(getEquationsNumber(m));
      variables = getVariables(m);
      nvar = listLength(variables);
      true =  neq<nvar;
      occurrences = List.map1r(knowns,occurrencesOfVariable,m);
      reducedVars = findReductionCantidates(variables,occurrences,{});
      candidates = pickReductionCandidates(reducedVars);
      //printVarReduction(reducedVars);
      newM=reduceVariablesInMatrix(m,candidates,nvar-neq);
    then
      newM;
  end matchcontinue;
end reduceVariables;

protected function reduceVariablesInMatrix
  input ExtIncidenceMatrix m;
  input list<list<Integer>> candidates;
  input Integer count;
  output ExtIncidenceMatrix mOut;
algorithm
  mOut:=matchcontinue(m,candidates,count)
    local
      list<Integer> candidate,variables;
      Integer temp;
      list<list<Integer>> candidatesTail;
      ExtIncidenceMatrix newM;
    case(_,{},_)
      equation
        true=count>0;
        print("Warning: The system of equations is under-determined. The results may be incorrect.\n");
        then
          m;
    case(_,{},_)
        then
          m;
    case(_,_,_)
      equation
        true=intEq(count,0);
      then m;
    case(_,candidate::candidatesTail,_)
      equation
        true=count>0;
        temp = listHead(candidate);
        //print("Eliminating "+intString(temp)+"\n");
        variables=List.setDifference(getVariables(m),{temp});
        newM = removeVarsNotInSet(m,variables,{});
        newM = reduceVariablesInMatrix(newM,candidatesTail,count-1);
      then newM;
  end matchcontinue;
end reduceVariablesInMatrix;

protected function findReductionCantidates
  input list<Integer> variables;
  input list<list<Integer>> occurrences;
  input list<tuple<list<Integer>,list<Integer>>> acc;
  output list<tuple<list<Integer>,list<Integer>>> out;
algorithm
out:=match(variables,occurrences,acc)
  local
    Integer var;
    list<Integer> occurrence,varTail;
    list<list<Integer>> occurrenceTail;
    list<tuple<list<Integer>,list<Integer>>> newAcc;
  case({},{},_) then acc;
  case(var::varTail,occurrence::occurrenceTail,_)
    equation
      newAcc=findReductionCantidates2(var,occurrence,acc);
    then
      findReductionCantidates(varTail,occurrenceTail,newAcc);
end match;
end findReductionCantidates;

protected function findReductionCantidates2
  input Integer var;
  input list<Integer> occurrence;
  input list<tuple<list<Integer>,list<Integer>>> acc;
  output list<tuple<list<Integer>,list<Integer>>> accOut;
algorithm
accOut:=matchcontinue(var,occurrence,acc)
  local
    list<tuple<list<Integer>,list<Integer>>> newAcc,tail;
    list<Integer> elemOccurrences,vars;
    tuple<list<Integer>,list<Integer>> elem;
  case(_,_,{})
    equation
      newAcc = {(occurrence,{var})};
    then
     newAcc;
  case(_,_,(elemOccurrences,vars)::tail)
    equation
      true = intEq(listLength(occurrence),listLength(elemOccurrences));
      true = containsAll(occurrence,elemOccurrences);
      elem = (elemOccurrences,listAppend(vars,{var}));
      newAcc = elem::tail;
    then
      newAcc;
  case(_,_,(elemOccurrences,vars)::tail)
    equation
      newAcc = findReductionCantidates2(var,occurrence,tail);
    then
      (elemOccurrences,vars)::newAcc;
end matchcontinue;
end findReductionCantidates2;

protected function eliminateOutputVariables
  input ExtIncidenceMatrix mIn;
  input list<Integer> outputs;
  output ExtIncidenceMatrix mOut;
algorithm
mOut:=matchcontinue(mIn,outputs)
  local Integer var; list<Integer> tail;
  list<Integer> o;
  ExtIncidenceMatrix newM,m;
  case(m,{})
    then m;
  case(m,var::tail)
    equation
      o=occurrencesOfVariable(m,var);
      true=intEq(listLength(o),1);
      newM=removeEquations(m,o);
      newM=eliminateOutputVariables(newM,tail);
    then newM;
  case(m,_::tail)
    equation
      newM=eliminateOutputVariables(m,tail);
    then newM;
end matchcontinue;
end eliminateOutputVariables;

protected function occurrencesOfVariable
  input ExtIncidenceMatrix m;
  input Integer var;
  output list<Integer> out;
algorithm
  out:=matchcontinue(m,var)
    local
      ExtIncidenceMatrix tail;
      list<Integer> ret,vars;
      Integer eq;
      case({},_) then {};
      case((eq,vars)::tail,_)
        equation
          true = containsAny(vars,{var});
          ret = occurrencesOfVariable(tail,var);
        then
          eq::ret;
      case((_,_)::tail,_)
        equation
          ret = occurrencesOfVariable(tail,var);
        then
          ret;
  end matchcontinue;
end occurrencesOfVariable;

protected function getEquationsNumber
  input ExtIncidenceMatrix m;
  output list<Integer> numbers;
algorithm
numbers:= match(m)
    local
      ExtIncidenceMatrix t;
      Integer eq;
      list<Integer> inner_ret;
    case({})
        equation
        then {};
    case((eq,_)::t)
      equation
        inner_ret = getEquationsNumber(t);
      then eq::inner_ret;
  end match;
end getEquationsNumber;

protected function getMathematicaText
  input String text;
  output String textOut;
algorithm
  textOut:="Text[Style[\""+text+"\",Bold,Large]]";
end getMathematicaText;

protected function getComponentsWrapper
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mt;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output list<list<Integer>> compsOut;
algorithm
compsOut:=matchcontinue(m,mt,ass1,ass2)
  local
    list<list<Integer>> comps;
    list<Integer> comp;
  case(_,_,_,_)
    equation
      true = intEq(0,arrayLength(m));
    then {{}};
  case(_,_,_,_)
    equation
      true = intEq(1,arrayLength(m));
    then {{1}};
  case(_,_,_,_)
    equation
       failure(_=Sorting.TarjanTransposed(mt,ass2));

       print("TarjanAlgorithm failed\n");
       Error.clearMessages();
       comp = List.intRange(arrayLength(m));
       comps = {comp};
    then
      comps;
  case(_,_,_,_)
    equation
       comps=Sorting.TarjanTransposed(mt,ass2);
    then
      comps;
end matchcontinue;
end getComponentsWrapper;

protected function getVariables
  input ExtIncidenceMatrix m;
  output list<Integer> varsOut;
algorithm
varsOut:= match(m)
   local
      list<Integer> vars,newVars;
      ExtIncidenceMatrix t;
   case({})
        equation
        then {};
   case((_,vars)::t)
        equation
           newVars=listAppend(vars,getVariables(t));
           newVars=List.unique(newVars);
        then newVars;
end match;
end getVariables;

protected function removeEquationInSquaredBlock
  input ExtIncidenceMatrix m;
  input list<Integer> knowns;
  input list<Integer> unknowns;
  input list<list<Integer>> components;
  output ExtIncidenceMatrix mOut;
  output list<Integer> removedEquations;
algorithm
(mOut,removedEquations):=matchcontinue(m,knowns,unknowns,components)
  local
    list<Integer> h,vars,usedKnowns;
    list<list<Integer>> t;
    ExtIncidenceMatrix compEqns,compsSorted,tailEquations,inner_ret;
    Integer removeEquation;
    list<Integer> removed_inner;
  case(_,_,_,{})
    equation
    then ({},{});
  case(_,_,_,h::t)
    equation
       compEqns=getEquations(m,h);
       vars=getVariables(compEqns);
       usedKnowns=List.intersectionOnTrue(vars,knowns,intEq);
       true=intEq(listLength(h),listLength(usedKnowns));
       compsSorted=listReverse(sortEquations(compEqns,unknowns));
       (removeEquation,_)::tailEquations=compsSorted;
       (inner_ret,removed_inner)=removeEquationInSquaredBlock(m,knowns,unknowns,t);
       removed_inner = if listLength(compsSorted)>1 then removeEquation::removed_inner else removed_inner;
    then (listAppend(tailEquations,inner_ret),removed_inner);
  case(_,_,_,h::t)
    equation
       compEqns=getEquations(m,h);
       vars=getVariables(compEqns);
       usedKnowns=List.intersectionOnTrue(vars,knowns,intEq);
       false=intEq(listLength(h),listLength(usedKnowns));
       (inner_ret,removed_inner)=removeEquationInSquaredBlock(m,knowns,unknowns,t);
    then (listAppend(compEqns,inner_ret),removed_inner);
end matchcontinue;
end removeEquationInSquaredBlock;

protected function printIntList
  input list<Integer> l;
algorithm
  print("List of size = "+intString(listLength(l))+"\n");
  print(stringDelimitList(List.map(l,intString),","));
  print("\n");
end printIntList;

protected function intListString
  input list<Integer> l;
  output String out;
algorithm
  out:="{"+stringDelimitList(List.map(l,intString),",")+"}";
end intListString;

protected function listString
  input list<String> l;
  output String out;
algorithm
  out:="{"+stringDelimitList(l,",")+"}";
end listString;

protected function setOfList
  input list<Integer> inList;
  output list<Integer> outList;
algorithm
  outList:=List.unique(inList);
end setOfList;

protected function countKnowns
  input ExtIncidenceMatrixRow row;
  input list<Integer> knowns;
  output Integer out;
algorithm
  out:= match(row,knowns)
    local
      list<Integer> vars;
      Integer n;
    case((_,vars),_)
        equation
          n=listLength(List.intersectionOnTrue(vars,knowns,intEq));
        then n;
  end match;
end countKnowns;

protected function sortEquations
  input ExtIncidenceMatrix m;
  input list<Integer> knowns;
  output ExtIncidenceMatrix mOut;
algorithm
  mOut:=sortBy1(m,countKnowns,knowns);
end sortEquations;

protected function removeVarsNotInSet_helper
  input Integer var;
  input list<Integer> elems;
  output Boolean out;
algorithm
  out:=containsAny({var},elems);
end removeVarsNotInSet_helper;

protected function removeVarsNotInSet
  input ExtIncidenceMatrix m;
  input list<Integer> set;
  input ExtIncidenceMatrix acc;
  output ExtIncidenceMatrix mOut;
algorithm
mOut:=matchcontinue(m,set,acc)
  local
     list<Integer> vars,newVars;
     ExtIncidenceMatrix t;
     Integer eq;
  case({},_,_)
    equation
    then listReverse(acc);
  case((_,vars)::t,_,_)
      equation
        newVars = List.filter1OnTrue(vars,removeVarsNotInSet_helper,set);
        true = listEmpty(newVars);
      then removeVarsNotInSet(t,set,acc);
  case((eq,vars)::t,_,_)
      equation
        newVars = List.filter1OnTrue(vars,removeVarsNotInSet_helper,set);
        false = listEmpty(newVars);
      then removeVarsNotInSet(t,set,(eq,newVars)::acc);
end matchcontinue;
end removeVarsNotInSet;

protected function removeEquations
  input ExtIncidenceMatrix m;
  input list<Integer> eqns;
  output ExtIncidenceMatrix mOut;
algorithm
mOut:=matchcontinue(m,eqns)
  local
    ExtIncidenceMatrixRow e;
    ExtIncidenceMatrix t,inner_ret;
    Integer eq;
  case({},_)
    equation
    then {};
  case((e as (eq,_))::t,_)
    equation
      false = containsAny({eq},eqns);
      inner_ret=removeEquations(t,eqns);
    then e::inner_ret;
  case(((eq,_))::t,_)
    equation
      true = containsAny({eq},eqns);
      inner_ret=removeEquations(t,eqns);
    then inner_ret;
end matchcontinue;
end removeEquations;


protected function getEquationsHelper
  input ExtIncidenceMatrixRow m;
  input list<Integer> eqns;
  output Boolean out;
algorithm
out:=matchcontinue(m,eqns)
  local
    Integer e;
  case((e,_),_)
      equation
      true = List.isMemberOnTrue(e,eqns,intEq);
  then true;
  case((e,_),_)
      equation
      false = List.isMemberOnTrue(e,eqns,intEq);
  then false;
end matchcontinue;
end getEquationsHelper;

protected function getEquations
  input ExtIncidenceMatrix m;
  input list<Integer> eqns;
  output ExtIncidenceMatrix mOut;
algorithm
mOut:=List.filter1OnTrue(m,getEquationsHelper,eqns);
end getEquations;

protected function removeUnrelatedEquations2
  input ExtIncidenceMatrixRow row;
  input list<Integer> knowns;
  output Boolean out;
algorithm
out:= match(row,knowns)
  local
    list<Integer> vars;
    Boolean ret;
  case((_,vars),_)
      equation
        ret = containsAny(vars,knowns);
      then ret;
end match;
end removeUnrelatedEquations2;

protected function removeUnrelatedEquations
  input ExtIncidenceMatrix m;
  input list<Integer> knowns;
  output ExtIncidenceMatrix mOut;
algorithm
mOut:=List.filter1OnTrue(m,removeUnrelatedEquations2,knowns);
end removeUnrelatedEquations;

protected function checkSystemContainsVars "Check that each variable is contained in the system"
    input ExtIncidenceMatrix m;
    input list<Integer> knows;
    input BackendDAE.Variables variables;
algorithm
    _:=matchcontinue(m,knows,variables)
        local
            Integer h;
            list<Integer> t,ret;
            BackendDAE.Var not_found_var;
            String str;
        case(_,{},_)
        then ();
        case(_,h::t,_)
            equation
                true=listEmpty(removeUnrelatedEquations(m,{h}));
                not_found_var=BackendVariable.getVarAt(variables,h);
                str = ComponentReference.crefStr(BackendVariable.varCref(not_found_var));
                print("Warning: The variable '"+str+"' was not found in the system of knowns\n");
                checkSystemContainsVars(m,t,variables);
            then ();
        case(_,h::t,_)
            equation
               false=listEmpty(removeUnrelatedEquations(m,{h}));
                checkSystemContainsVars(m,t,variables);
            then ();
    end matchcontinue;
end checkSystemContainsVars;

protected function getSystemForUnknowns
  input ExtIncidenceMatrix m;
  input list<Integer> knowns;
  input list<Integer> unknowns;
  output ExtIncidenceMatrix mOut;
  protected ExtIncidenceMatrix mTemp;
algorithm
  mTemp:=sortEquations(m,knowns);
  mOut:=removeVarsNotInSet(mTemp,unknowns,{});
end getSystemForUnknowns;

protected function getRelatedVariables
  input ExtIncidenceMatrix m;
  input list<Integer> vars;
  output list<Integer> varsOut;
algorithm
varsOut:=matchcontinue(m,vars)
  local
     ExtIncidenceMatrix t;
     ExtIncidenceMatrixRow h;
     list<Integer> eqvars;
  case({},_)
      equation
      then {};
  case(((_,eqvars))::t,_)
    equation
      true = containsAny(eqvars,vars);
      eqvars = listAppend(eqvars,getRelatedVariables(t,vars));
      eqvars = List.setDifference(setOfList(eqvars),vars);
    then eqvars;
  case(((_,eqvars))::t,_)
    equation
      false = containsAny(eqvars,vars);
      eqvars = getRelatedVariables(t,vars);
      eqvars = List.setDifference(setOfList(eqvars),vars);
    then eqvars;
end matchcontinue;
end getRelatedVariables;

protected function restoreIndicesEquivalence
  input list<Integer> inList;
  input list<Integer> map;
  output list<Integer> out;
algorithm
out:= match(inList,map)
  local
    list<Integer> t,inner_ret;
    Integer h,v;
  case({},_)
    equation
    then {};
  case(h::t,_)
      equation
        v = listGet(map,h);
        inner_ret = restoreIndicesEquivalence(t,map);
      then v::inner_ret;
end match;
end restoreIndicesEquivalence;

protected function addIndexEquivalence
  input Integer index;
  input list<Integer> map;
  output Integer indexOut;
  output list<Integer> mapOut;
algorithm
(indexOut,mapOut):=matchcontinue(index,map)
  local
    Integer pos;
    list<Integer> newMap;
  case(_,_)
    equation
      true = List.isMemberOnTrue(index,map,intEq);
      pos = List.position(index,map);
    then
      (pos,map);
  case(_,_)
    equation
      false = List.isMemberOnTrue(index,map,intEq);
      pos = listLength(map)+1;
      newMap = listAppend(map,{index});
    then
      (pos,newMap);
end matchcontinue;
end addIndexEquivalence;

protected function addVarEquivalences
  input list<Integer> vars;
  input list<Integer> map;
  input list <Integer> varsFixed;
  output list<Integer> varMapOut;
  output list<Integer> varsOut;
algorithm
(varMapOut,varsOut):= match(vars,map,varsFixed)
  local
    Integer h,v;
    list<Integer> remaining,newMap,innerVars,innerMap;
  case({},_,_)
    equation
    then (map,varsFixed);
  case(h::remaining,_,_)
      equation
       (v,newMap)=addIndexEquivalence(h,map);
       (innerMap,innerVars)=addVarEquivalences(remaining,newMap,v::varsFixed);
      then (innerMap,innerVars);
end match;
end addVarEquivalences;

protected function prepareForMatching2
  input ExtIncidenceMatrix mExt;
  input list<Integer> eqMap;
  input list<Integer> varMap;
  input list<list<Integer>> m;
  output list<Integer> eqMapOut;
  output list<Integer> varMapOut;
  output list<list<Integer>> mOut;
algorithm
(eqMapOut,varMapOut,mOut):= match(mExt,eqMap,varMap,m)
    local
      Integer eq;
      list<Integer> vars,newVarMap,newEqMap,newVars;
      ExtIncidenceMatrix t;
      list<list<Integer>> newM;
    case({},_,_,_)
      equation
        newM = listReverse(m);
      then (eqMap,varMap,newM);
    case((eq,vars)::t,_,_,_)
        equation
          (_,newEqMap) = addIndexEquivalence(eq,eqMap);
          (newVarMap,newVars) = addVarEquivalences(vars,varMap,{});
          (newEqMap,newVarMap,newM) = prepareForMatching2(t,newEqMap,newVarMap,newVars::m);
        then (newEqMap,newVarMap,newM);
  end match;
end prepareForMatching2;

protected function prepareForMatching
  input ExtIncidenceMatrix mExt;
  output list<Integer> eqMap;
  output list<Integer> varMap;
  output BackendDAE.IncidenceMatrix mOut;
  protected list<list<Integer>> m;
algorithm
(eqMap,varMap,m):=prepareForMatching2(mExt,{},{},{});
//print("Matrix to match: equations = "+intString(listLength(eqMap))+" variables = "+intString(listLength(varMap))+"\n");
mOut:=listArray(fixUnderdeterminedSystem(m,listLength(varMap),listLength(eqMap)));
end prepareForMatching;

protected function removeDummyEquations
   input list<list<Integer>> comps;
   input Integer max_neqs;
   output list<list<Integer>> out;
algorithm
out:= match(comps,max_neqs)
   local
      list<list<Integer>> t,ret;
      list<Integer> h,row;
   case({},_)
      then {};
   case(h::t,_)
      equation
        row=List.removeOnTrue(max_neqs,intLt,h);
        ret=removeDummyEquations(t,max_neqs);
      then row::ret;
end match;
end removeDummyEquations;

protected function fixUnderdeterminedSystem
   input list<list<Integer>> m;
   input Integer nvars;
   input Integer neqs;
   output list<list<Integer>> mOut;
algorithm
  mOut:=matchcontinue(m,nvars,neqs)
     local
        list<Integer> dummyEq;
        list<list<Integer>> new_m;
     case(_,_,_)
        equation
          true=intGt(nvars,neqs);
          dummyEq=List.intRange(nvars);
          new_m=fixUnderdeterminedSystem(listAppend(m,{dummyEq}),nvars,neqs+1);
        then new_m;
     case(_,_,_)
           then m;
  end matchcontinue;
end fixUnderdeterminedSystem;

protected function getExtIncidenceMatrix
  input BackendDAE.IncidenceMatrix m;
  output ExtIncidenceMatrix mOut;
algorithm
  mOut:=getExtIncidenceMatrix2(1,arrayList(m),{});
end getExtIncidenceMatrix;

protected function getExtIncidenceMatrix2
  input Integer i;
  input list<BackendDAE.IncidenceMatrixElement> m;
  input ExtIncidenceMatrix acc;
  output ExtIncidenceMatrix mOut;
algorithm
  mOut:= match(i,m,acc)
    local
      BackendDAE.IncidenceMatrixElement h;
      list<BackendDAE.IncidenceMatrixElement> t;
    case(_,{},_)
      equation
      then listReverse(acc);
    case(_,h::t,_)
        equation
        then getExtIncidenceMatrix2(i+1,t,(i,h)::acc);
  end match;
end getExtIncidenceMatrix2;

protected function dumpExtIncidenceMatrix
  input ExtIncidenceMatrix m;
algorithm
  _:=match(m)
    local
      ExtIncidenceMatrix t;
      Integer eq;
      list<Integer> vars;
    case({})
        then ();
    case((eq,vars)::t)
        equation
          print(intString(eq)+":"+stringDelimitList(List.map(vars,intString),",")+"\n");
          dumpExtIncidenceMatrix(t);
        then ();
  end match;
end dumpExtIncidenceMatrix;

protected function containsAny
  input list<Integer> m1;
  input list<Integer> m2;
  output Boolean out;
  protected list<Integer> m3;
algorithm
  m3:=List.intersectionOnTrue(m1,m2,intEq);
  out:= not listEmpty(m3);
end containsAny;

protected function containsAll
  input list<Integer> m1;
  input list<Integer> m2;
  output Boolean out;
  protected list<Integer> m3;
algorithm
  m3:=List.intersectionOnTrue(m1,m2,intEq);
  out:=intEq(listLength(m3),listLength(m2));
end containsAll;


public function getUncertainRefineVariableIndexes
"
  author: Daniel Hedberg, 2011-01
  modified by: Leonardo Laguna, 2012-01

  Returns a list with the indexes of all variables in variableIndexList which
  have the uncertain attribute set to Uncertainty.Refine.
"
  input BackendDAE.Variables allVariables;
  input list<Integer> variableIndexList;
  output list<Integer> indices;
  output list<Option<DAE.Distribution>> distributions;
algorithm
  (indices,distributions) := matchcontinue (allVariables, variableIndexList)
    local
      list<Integer> variableIndexListRest, refineVariableIndexList;
      Integer index;
      BackendDAE.Var var;
      Option<DAE.Distribution> dist;
      list<Option<DAE.Distribution>> distInner;
    case (_, {}) then
      ({},{});
    // Variable has its uncertain attribute set to Uncertainty.Refine?
    case (_, index :: variableIndexListRest) equation
      var = BackendVariable.getVarAt(allVariables, index);
      true = BackendVariable.varHasUncertainValueRefine(var);
      dist = BackendVariable.varTryGetDistribution(var);
      (refineVariableIndexList,distInner) = getUncertainRefineVariableIndexes(allVariables, variableIndexListRest);
    then
      (index :: refineVariableIndexList,dist::distInner);
    // Variable is missing the uncertain attribute or it is not set to Uncertainty.Refine?
    case (_, index :: variableIndexListRest) equation
      var = BackendVariable.getVarAt(allVariables, index);
      false = BackendVariable.varHasUncertainValueRefine(var);
      (refineVariableIndexList,distInner) = getUncertainRefineVariableIndexes(allVariables, variableIndexListRest);
    then
      (refineVariableIndexList,distInner);
    case (_,_) equation print("getUncertainRefineVariableIndexes failed!\n"); then fail();
  end matchcontinue;
end getUncertainRefineVariableIndexes;


public function eliminateVariablesDAE
"
  author: Daniel Hedberg, 2011-01

  Eliminates the specified variables between the given set of equations.
"
  input list<Integer> elimVarIndexList;
  input BackendDAE.BackendDAE indae;
  output BackendDAE.BackendDAE outDae;
algorithm
  outDae := match(elimVarIndexList, indae)
    local
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables vars,vars_1,kvars,kvars_1;
      BackendDAE.EquationArray eqns,ieqns;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      HashTable.HashTable crefDouble;
      BackendDAE.IncidenceMatrix m;
      HashTable.HashTable movedvars_1;
      list<BackendDAE.Equation> seqns,eqnLst,ieqnLst;
      BackendVarTransform.VariableReplacements repl;

    case(_,dae as BackendDAE.DAE((syst as BackendDAE.EQSYSTEM(orderedEqs=eqns,orderedVars=vars))::_,(shared as BackendDAE.SHARED(knownVars=kvars,initialEqs=ieqns)))) equation
      _ = BackendEquation.equationList(ieqns);
      eqnLst = BackendEquation.equationList(eqns);
      crefDouble = findArraysPartiallyIndexed(eqnLst);
      //print("partially indexed crs:"+Util.stringDelimitList(Util.listMap(crefDouble,Exp.printComponentRefStr),",\n")+"\n");
      repl = BackendVarTransform.emptyReplacements();

      (m,_,_,_) = BackendDAEUtil.incidenceMatrixScalar(syst, BackendDAE.NORMAL(),NONE());
      (eqnLst,_,movedvars_1,repl) = eliminateVariablesDAE2(eqnLst,1,vars,kvars,HashTable.emptyHashTable(),repl,crefDouble,m,elimVarIndexList,false);
      //Debug.fcall("dumprepl",BackendVarTransform.dumpReplacements,repl);

      dae = setDaeEqns(dae,BackendEquation.listEquation(eqnLst),false);
      //dae = setDaeSimpleEqns(dae,listEquation(listAppend(equationList(reqns),seqns)));
      dae = replaceDAElow(dae,repl,NONE(),false);
      (vars_1,kvars_1) = moveVariables(BackendVariable.daeVars(syst),BackendVariable.daeKnVars(shared),movedvars_1);
      dae = setDaeVars(dae,vars_1);
      dae = BackendDAEUtil.setKnownVars(dae, kvars_1);

      dae = BackendDAEUtil.transformBackendDAE(dae,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.ALLOW_UNDERCONSTRAINED())),NONE(),NONE());
      dae = BackendDAEUtil.mapEqSystem1(dae,BackendDAEUtil.getIncidenceMatrixfromOptionForMapEqSystem,BackendDAE.NORMAL());
    then dae;
  end match;
end eliminateVariablesDAE;

protected function findArraysPartiallyIndexed "Function findArraysPartiallyIndexed
This function identifies which of our variables that are indexed with a full array or a DAE.WHOLEDIM
For instance, the following component references (v is a vector) results in an entry of the variable in the result list of this funtion:

a.b.v[{1,2}]
a.v
a.v[:]

a.R -> a.R.v for Record variable R containing array variable v (dealt with in findArraysPartiallyIndexedRecords)
"
  input list<BackendDAE.Equation> inEqs;
  output HashTable.HashTable ht;
algorithm
  ht:= findArraysPartiallyIndexed1(inEqs,HashTable.emptyHashTable());
  ht :=findArraysPartiallyIndexedRecords(inEqs,ht);
end findArraysPartiallyIndexed;

protected function findArraysPartiallyIndexed1 "help function to findArraysPartiallyIndexed
This function identifies which of our variables that are indexed with a full array or a DAE.WHOLEDIM
For instance, the following component references (v is a vector) results in an entry of the variable in the result list of this funtion:

a.b.v[{1,2}]
a.v
a.v[:]
"
  input list<BackendDAE.Equation> inEqs;
  input HashTable.HashTable inht;
  output HashTable.HashTable outHt;
algorithm
  (outHt) :=
  matchcontinue(inEqs,inht)
      local
        list<BackendDAE.Equation> eqs;
        BackendDAE.Equation eq1;
        DAE.Exp e1,e2;
        list<DAE.Exp> expl;
        HashTable.HashTable ht;
        DAE.Algorithm alg;
    case({},ht) then  ht;
    case( BackendDAE.ALGORITHM(alg=alg) :: eqs,ht)
      equation
        _ = Algorithm.getAllExps(alg);
        ht = findArraysPartiallyIndexed1(eqs,ht);
      then
        ht;

    case((BackendDAE.ARRAY_EQUATION(left=e1,right=e2)) :: eqs,ht)
      equation
        ht = findArraysPartiallyIndexed2({e1,e2},ht,HashTable.emptyHashTable());
        ht = findArrayVariables({e1,e2},ht) "finds all array variables, including earlier special case for v = foo(..)";
        ht = findArraysPartiallyIndexed1(eqs,ht);
      then
        ht;
    case(_ ::eqs,ht)
      equation
        ht = findArraysPartiallyIndexed1(eqs,ht);
    then
      ht;
  end matchcontinue;
end findArraysPartiallyIndexed1;

protected function findArraysPartiallyIndexed2 "
"
  input list<DAE.Exp> inRef "The list of expressions to traverse/search for crefs";
  input HashTable.HashTable indubRef "ComponentReferences that are duplicate(y[1,1],y[1,2] is a double)";
  input HashTable.HashTable inht "Added componentReferences";
  output HashTable.HashTable outHt;

algorithm
  outHt := matchcontinue(inRef,indubRef,inht)
    local
      DAE.ComponentRef c1,c2;
      DAE.Exp e1;
      list<DAE.Exp> expl1;
      HashTable.HashTable dubRef,ht;

    case({}, _, ht) then ht;

    case(((DAE.CREF(c1,_))::expl1),dubRef,ht)
      equation
        c2 = ComponentReference.crefStripLastSubs(c1);
        failure(_ = BaseHashTable.get(c2,dubRef));
        dubRef = BaseHashTable.add((c2,1),dubRef);
        ht = findArraysPartiallyIndexed2(expl1,dubRef,ht);
      then ht;

    case(((DAE.CREF(c1,_))::expl1),dubRef,ht)
      equation
        c2 = ComponentReference.crefStripLastSubs(c1);
        _ = BaseHashTable.get(c2,dubRef);
        _ = BaseHashTable.get(c2,ht);// if we have one occurrence, most likely it will be more.
        ht = findArraysPartiallyIndexed2(expl1,dubRef,ht);
      then ht;

    case(((DAE.CREF(c1,_))::expl1),dubRef,ht)
      equation
        c2 = ComponentReference.crefStripLastSubs(c1);
        _ = BaseHashTable.get(c2,dubRef);
        failure(_ = BaseHashTable.get(c2,ht));
        ht = BaseHashTable.add((c2,1),ht);
        ht = findArraysPartiallyIndexed2(expl1,dubRef,ht);
      then ht;
    case(_::expl1,dubRef,ht)
      equation
        ht = findArraysPartiallyIndexed2(expl1,dubRef,ht);
        then
          ht;
  end matchcontinue;
end findArraysPartiallyIndexed2;


protected function findArrayVariables "collects all variables that are arrays and adds them to the list"
  input list<DAE.Exp> inRef "The list of expressions to traverse/search for crefs";
  input HashTable.HashTable inht;
  output HashTable.HashTable outHt;
algorithm
  outHt := matchcontinue(inRef,inht)
    local DAE.Exp e1;
      list<DAE.Exp> expl1;
      DAE.ComponentRef c1;
      HashTable.HashTable ht;
    case({},ht) then ht;
    case((DAE.CREF(c1,_))::expl1,ht) equation
      true = Expression.isArrayType(ComponentReference.crefTypeConsiderSubs(c1));

      ht = BaseHashTable.add((c1,1),ht);
      ht = findArrayVariables(expl1,ht);
    then ht;
    case(_::expl1,ht) equation
      ht = findArrayVariables(expl1,ht);
    then ht;
  end matchcontinue;
end findArrayVariables;

protected function findArraysPartiallyIndexedRecords "finds vector variables inside record instances in all equations"
  input list<BackendDAE.Equation> inEqs;
  input HashTable.HashTable ht;
  output HashTable.HashTable outHt;
algorithm
 (_,outHt) := BackendEquation.traverseExpsOfEquationList(inEqs,findArraysPartiallyIndexedRecordsExpVisitor,ht);
 //print("partially indexed crs from reccrs:"+Util.stringDelimitList(Util.listMap(outRef,Exp.printComponentRefStr),",\n")+"\n");
end findArraysPartiallyIndexedRecords;

protected function findArraysPartiallyIndexedRecordsExpVisitor "visitor function for expressions in findArraysPartiallyIndexedRecords"
  input DAE.Exp inExp;
  input HashTable.HashTable inHt;
  output DAE.Exp e;
  output HashTable.HashTable ht;
algorithm
  (e,ht) := matchcontinue (inExp,inHt)
      local
        DAE.ComponentRef cr;
        list<DAE.Var> varLst;
      case (e as DAE.CREF(cr,_),ht)
        equation
          DAE.T_COMPLEX(varLst = varLst,complexClassType=ClassInf.RECORD(_)) = ComponentReference.crefLastType(cr);
          ht = findArraysInRecordLst(ht,cr,varLst);
        then (e,ht);
      else (inExp,inHt);
  end matchcontinue;
end findArraysPartiallyIndexedRecordsExpVisitor;

protected function  findArraysInRecordLst "help function to findArraysPartiallyIndexedRecordsExpVisitor, searches the record elements for arrays"
 input HashTable.HashTable inht "accumulated crefs so far";
 input DAE.ComponentRef recordCr  "the record cref";
 input list<DAE.Var> invarLst;
 output HashTable.HashTable outHt "resulting accumulated crefs";
algorithm
  outHt := matchcontinue(inht,recordCr,invarLst)
    local
      HashTable.HashTable ht;
      String name;
      DAE.Type tp;
      DAE.ComponentRef thisCr;
      list<DAE.Var> varLst;
    case (ht,_,{}) then ht;
    // found array
    case(ht,_,DAE.TYPES_VAR(name=name,ty=tp)::varLst) equation
      true = Expression.isArrayType(tp);
      thisCr = ComponentReference.joinCrefs(recordCr,DAE.CREF_IDENT(name,tp,{}));
      ht = BaseHashTable.add((thisCr,0),ht);
      ht = findArraysInRecordLst(ht,recordCr,varLst);
    then ht;
    // found record inside record, recurse
    //case(ht,recordCr,DAE.TYPES_VAR(name,tp as DAE.ET_COMPLEX(varLst=varLst2,complexClassType=ClassInf.RECORD(_)))::varLst) equation
    //  thisCr = ComponentReference.joinCrefs(recordCr,DAE.CREF_IDENT(name,tp,{}));
    //  ht = findArraysInRecordLst(ht,thisCr,varLst2);
    //  ht = findArraysInRecordLst(ht,recordCr,varLst);
    //then ht;
    // other element (scalar)
    case(ht,_,_::varLst) equation
      ht = findArraysInRecordLst(ht,recordCr,varLst);
    then ht;

  end matchcontinue;
end findArraysInRecordLst;

protected function eliminateVariablesDAE2
"
  author: Daniel Hedberg, 2011-01

  Finds the variables in elimVarIndexList that can be eliminated in between
  the given set of equations. Returns a set of variable replacements that can
  be used to replace the variables in the equations that are left
"
  input list<BackendDAE.Equation> ieqns;
  input Integer eqnIndex;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input HashTable.HashTable mvars;
  input BackendVarTransform.VariableReplacements repl;
  input HashTable.HashTable inDoubles "variables that are partially indexed (part of array)";
  input BackendDAE.IncidenceMatrix m;
  input list<Integer> elimVarIndexList;
  input Boolean failCheck "if becomes true, fail. (Poor mans exception handling )";
  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outSimpleEqns;
  output HashTable.HashTable outMvars;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  (outEqns,outSimpleEqns,outMvars,outRepl):=
  matchcontinue (ieqns,eqnIndex,vars,knvars,mvars,repl,inDoubles,m,elimVarIndexList,failCheck)
    local
      HashTable.HashTable mvars_1,mvars_2;
      BackendVarTransform.VariableReplacements repl_1,repl_2;
      DAE.ComponentRef cr1;
      list<BackendDAE.Equation> eqns_1,seqns_1;
      list<Integer> varIndexList, elimVarIndexList_1;
      Integer elimVarIndex;
      BackendDAE.Equation e;
      list<BackendDAE.Equation> eqns;
      DAE.Exp e2;
      DAE.ElementSource source;
      array<Option<BackendDAE.Var>> varOptArr;
      BackendDAE.Var elimVar;

    case ({},_,_,_,_,_,_,_,_,false) then
      ({},{},mvars,repl);

    case (e::eqns,_,_,_,_,_,_,_,_,false) equation
      //true = RTOpts.eliminationLevel() > 0;
      //false = equationHasZeroCrossing(e);
      ({e},_) = BackendVarTransform.replaceEquations({e},repl,NONE()) "this can be dangerous in case of if-equations, because the can be simplified to a list of equations";

      // Attempt to solve the equation wrt to the variables to be eliminated.
      varIndexList = m[eqnIndex];
      (elimVarIndex :: _) = List.intersectionOnTrue(varIndexList, elimVarIndexList, intEq);
      elimVarIndexList_1 = List.removeOnTrue(elimVarIndex,  intEq, elimVarIndexList);
      elimVar = BackendVariable.getVarAt(vars, elimVarIndex);
      BackendDAE.VAR(varName = cr1) = elimVar;
      (e2, source) = solveEqn2(e, cr1);
//      print("Eliminated variable #" + intString(elimVarIndex) + " in equation #" + intString(eqnIndex) + "\n");

      //false = BackendVariable.isStateVar(elimVar);
      //BackendVariable.isVariable(cr1,vars,knvars) "cr1 not constant";
      //false = varHasStartValue(cr1Var) "never remove variables with start value";
      //false = BackendVariable.isTopLevelInputOrOutput(cr1,vars,knvars);
      //false = arrayPartiallyIndexed(cr1,inDoubles);
      repl_1 = BackendVarTransform.addReplacement(repl, cr1, e2,NONE());
      //failCheck = checkCircularEquation(cr1,e2,e);
      mvars_1 = BaseHashTable.add((cr1,0),mvars);
      (eqns_1,seqns_1,mvars_2,repl_2) = eliminateVariablesDAE2(eqns, eqnIndex + 1, vars, knvars, mvars_1, repl_1, inDoubles, m, elimVarIndexList_1, failCheck);
    then
      (eqns_1,(BackendDAE.SOLVED_EQUATION(cr1,e2,source,BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN) :: seqns_1),mvars_2,repl_2);

    // Next equation.
    case ((e :: eqns),_,_,_,_,_,_,_,_,false)
      equation
        (eqns_1,seqns_1,mvars_1,repl_1) = eliminateVariablesDAE2(eqns, eqnIndex + 1, vars, knvars, mvars,  repl, inDoubles, m, elimVarIndexList, false) "Not a simple variable, check rest";
      then
        ((e :: eqns_1),seqns_1,mvars_1,repl_1);
  end matchcontinue;
end eliminateVariablesDAE2;

protected function solveEqn2 "solves an equation w.r.t. a variable"
  input BackendDAE.Equation eqn;
  input DAE.ComponentRef cr;
  output DAE.Exp exp;
  output DAE.ElementSource source;
algorithm
  (exp,source) := match(eqn,cr)
    local
      DAE.Exp e1,e2;
    case(BackendDAE.EQUATION(exp=e1,scalar=e2,source=source),_)
      equation
        (exp,_) = ExpressionSolve.solve(e1,e2,DAE.CREF(cr,DAE.T_REAL_DEFAULT));
      then (exp,source);
    case(_,_)
      equation
        then fail();
  end match;
end solveEqn2;

protected function setDaeVars "
   note: this function destroys matching
"
  input BackendDAE.BackendDAE systIn;
  input BackendDAE.Variables newVarsIn;
  output BackendDAE.BackendDAE sysOut;
algorithm
  sysOut := BackendDAEUtil.setVars(systIn, newVarsIn);
end setDaeVars;

protected function setDaeEqns "set the equations of a dae
public function setEquations
"
  input BackendDAE.BackendDAE dae;
  input BackendDAE.EquationArray eqns;
  input Boolean initEqs "if true, set initialEquations instead of ordered equations";
  output BackendDAE.BackendDAE odae;
algorithm
  odae := match (dae, initEqs)
  local
    BackendDAE.EqSystem syst;
    list<BackendDAE.EqSystem> systList;
    BackendDAE.Shared shared;
  case (BackendDAE.DAE(syst::systList, shared), false)
    equation
      syst = BackendDAEUtil.setEqSystEqs(syst, eqns);
    then
      BackendDAE.DAE(syst::systList, shared);
  case (BackendDAE.DAE(systList, shared), false)
    equation
      shared = BackendDAEUtil.setSharedInitialEqns(shared, eqns);
    then
      BackendDAE.DAE(systList, shared);
  end match;
end setDaeEqns;

public function replaceDAElow
  input BackendDAE.BackendDAE idlow;
  input BackendVarTransform.VariableReplacements repl;
  input Option<PredicateFunction> func;
  partial function PredicateFunction
    input DAE.Exp e;
    output Boolean b;
  end PredicateFunction;
  input Boolean replaceVariables "if true, run replacementrules on variablelist also: Note: requires destinations in repl to be crefs!";
  output BackendDAE.BackendDAE odae;
algorithm
  odae := match idlow
  local
    BackendDAE.EqSystem syst;
    list<BackendDAE.EqSystem> systList;
    BackendDAE.Shared shared;
    BackendDAE.Variables orderedVars;
    BackendDAE.EquationArray orderedEqs;
  case BackendDAE.DAE(
      (syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs))::systList, shared)
    equation
      orderedVars = BackendVariable.listVar1(replaceVars(BackendVariable.varList(orderedVars), repl, func, replaceVariables));
      (orderedEqs, _) = BackendVarTransform.replaceEquationsArr(orderedEqs, repl, NONE());
      syst = BackendDAEUtil.setEqSystVars(syst, orderedVars);
      syst = BackendDAEUtil.setEqSystEqs(syst, orderedEqs);
    then
      BackendDAE.DAE(syst::systList, shared);
  end match;
end replaceDAElow;

protected function replaceVars "help function to replaceDAElow, replaces variables.
If replaceName is true it replaced the variable name, fails if destination is not cref.
if replaceName is false it only replaces in binding expression.
"
  input list<BackendDAE.Var> invarLst;
  input BackendVarTransform.VariableReplacements repl;
  input Option<PredicateFunction> func;
  input Boolean replaceName;
  partial function PredicateFunction
    input DAE.Exp e;
    output Boolean b;
  end PredicateFunction;

  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := match(invarLst,repl,func,replaceName)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      Option<DAE.Exp> bindExp;
      list<BackendDAE.Var> varLst;

    case({},_,_,_) then {};
    case(v::varLst,_,_,true) equation
      cr = BackendVariable.varCref(v);
      bindExp = varBindingOpt(v);
      bindExp = replaceExpOpt(bindExp,repl,func);
      bindExp = applyOptionSimplify(bindExp);
      (DAE.CREF(cr,_),_) = BackendVarTransform.replaceExp(DAE.CREF(cr, DAE.T_REAL_DEFAULT),repl,func);
      v = setVarCref(v,cr);
      v = setVarBindingOpt(v,bindExp);
      varLst = replaceVars(varLst,repl,func,replaceName);
    then v::varLst;

    case(v::varLst,_,_,false) equation
      bindExp = varBindingOpt(v);
      bindExp = replaceExpOpt(bindExp,repl,func);
      bindExp = applyOptionSimplify(bindExp);
      v = setVarBindingOpt(v,bindExp);
      varLst = replaceVars(varLst,repl,func,replaceName);
    then v::varLst;
  end match;
end replaceVars;

public function varBindingOpt "author: PA

returns the binding expression option of a variable"
input BackendDAE.Var v;
output Option<DAE.Exp> exp;
algorithm
  exp := match(v)
    case(BackendDAE.VAR(bindExp = exp)) then exp;
  end match;
end varBindingOpt;


public function replaceExpOpt "Similar to replaceExp but takes Option<Exp> instead of Exp"
 input Option<DAE.Exp> inExp;
  input BackendVarTransform.VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> funcOpt;
  output Option<DAE.Exp> outExp;
  partial function FuncTypeExp_ExpToBoolean
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outExp := match (inExp,repl,funcOpt)
  local DAE.Exp e;
    case(NONE(),_,_) then NONE();
    case(SOME(e),_,_)
      equation
        /* TODO: Propagate this boolean? */
        (e,_) = BackendVarTransform.replaceExp(e,repl,funcOpt);
      then SOME(e);
  end match;
end replaceExpOpt;

public function applyOptionSimplify
  input Option<DAE.Exp> bindExpIn;
  output Option<DAE.Exp> bindExpOut;
algorithm
  bindExpOut := match(bindExpIn)
    local
      DAE.Exp e, e1;

    case NONE()
    then NONE();

    case SOME(e) equation
      (e1,_) = ExpressionSimplify.simplify1(e);
    then SOME(e1);
  end match;
end applyOptionSimplify;

public function setVarCref "author: PA
  Sets the ComponentRef of a variable."
  input BackendDAE.Var inVar;
  input DAE.ComponentRef cr;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef name;
  BackendDAE.VarKind kind;
  DAE.VarDirection dir;
  DAE.VarParallelism prl;
  DAE.Type tp;
  Option<DAE.Exp> bind ;
  Option<Values.Value> bindval;
  DAE.InstDims ad;
  DAE.ElementSource source;
  Option<DAE.VariableAttributes> attr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> cmt;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter io;
algorithm
  BackendDAE.VAR(name,kind,dir,prl,tp,bind,bindval,ad,source,attr,ts,cmt,ct,io,_) := inVar;
  outVar := BackendDAE.VAR(cr,kind,dir,prl,tp,bind,bindval,ad,source,attr,ts,cmt,ct,io,false);
end setVarCref;

public function setVarBindingOpt "author: PA
  Sets the optional binding of a variable."
  input BackendDAE.Var inVar;
  input Option<DAE.Exp> bindExp;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef name;
  BackendDAE.VarKind kind;
  DAE.VarDirection dir;
  DAE.VarParallelism prl;
  BackendDAE.Type tp;
  Option<DAE.Exp> bind ;
  Option<Values.Value> bindval;
  DAE.InstDims ad;
  DAE.ElementSource source;
  Option<DAE.VariableAttributes> attr;
  Option<BackendDAE.TearingSelect> ts;
  Option<SCode.Comment> cmt;
  DAE.ConnectorType ct;
  DAE.VarInnerOuter innerOuter;
algorithm
  BackendDAE.VAR(name,kind,dir,prl,tp,bind,bindval,ad,source,attr,ts,cmt,ct,innerOuter,_) := inVar;
  outVar := BackendDAE.VAR(name,kind,dir,prl,tp,bindExp,bindval,ad,source,attr,ts,cmt,ct,innerOuter,false);
end setVarBindingOpt;

public function moveVariables "
  This function takes the two variable lists of a dae (states+alg) and
  known vars and moves a set of variables from the first to the second set.
  This function is needed to manage this in complexity O(n) by only
  traversing the set once for all variables."
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
  input HashTable.HashTable hashTable;
  output BackendDAE.Variables outVariables1;
  output BackendDAE.Variables outVariables2;
protected
  list<BackendDAE.Var> lst1, lst2, lst1_1, lst2_1;
  BackendDAE.Variables v1, v2, vars, knvars;
algorithm
  lst1 := BackendVariable.varList(inVariables1);
  lst2 := BackendVariable.varList(inVariables2);
  (lst1_1, lst2_1) := moveVariables2(lst1, lst2, hashTable);
  v1 := BackendVariable.emptyVars();
  v2 := BackendVariable.emptyVars();
  //vars := addVarsNoUpdCheck(lst1_1, v1);
  outVariables1 := BackendVariable.addVars(lst1_1, v1);
  //knvars := addVarsNoUpdCheck(lst2_1, v2);
  outVariables2 := BackendVariable.addVars(lst2_1, v2);
end moveVariables;

protected function moveVariables2 "
  Helper function to moveVariables."
  input list<BackendDAE.Var> inVarLst1;
  input list<BackendDAE.Var> inVarLst2;
  input HashTable.HashTable hashTable;
  output list<BackendDAE.Var> outVarLst1;
  output list<BackendDAE.Var> outVarLst2;
algorithm
  (outVarLst1,outVarLst2):=
  matchcontinue (inVarLst1,inVarLst2,hashTable)
    local
      list<BackendDAE.Var> knvars,vs_1,knvars_1,vs;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      HashTable.HashTable mvars;
    case ({},knvars,_) then ({},knvars);
    case (((v as BackendDAE.VAR(varName = cr)) :: vs),knvars,mvars)
      equation
        _ = BaseHashTable.get(cr,mvars) "alg var moved to known vars";
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        (vs_1,(v :: knvars_1));
    case (((v as BackendDAE.VAR(varName = cr)) :: vs),knvars,mvars)
      equation
        failure(_ = BaseHashTable.get(cr,mvars)) "alg var not moved to known vars";
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        ((v :: vs_1),knvars_1);
  end matchcontinue;
end moveVariables2;

replaceable type ElementType subtypeof Any;
replaceable type ArgType1 subtypeof Any;

public function sortBy1
  "Sorts a list given a function that returns a rate of the elements.
   The function takes an extra argument.
    Example:
      Note:  foo(x,y) = x+y
      sort({100, 1000, 1,100000}, foo,0) => {1, 100, 1000,100000}"
  input list<ElementType> inList;
  input CompareFunc inCompFunc;
  input ArgType1 inArgument1;
  output list<ElementType> outList;

  partial function CompareFunc
    input ElementType inElement1;
    input ArgType1 inArgument1;
    output Integer outRes;
  end CompareFunc;
algorithm
  outList := match inList
    local
      ElementType e;
      list<ElementType> left, right;
      Integer middle;

    case {} then {};
    case {e} then {e};
    else
      equation
        middle = intDiv(listLength(inList), 2);
        (left, right) = List.split(inList, middle);
        left = sortBy1(left, inCompFunc,inArgument1);
        right = sortBy1(right, inCompFunc,inArgument1);
      then
        mergeBy1(left, right, inCompFunc,inArgument1);

  end match;
end sortBy1;

protected function mergeBy1
  "Helper function to sortBy1, merges two sorted lists given a rate function and an extra argument."
  input list<ElementType> inLeft;
  input list<ElementType> inRight;
  input CompareFunc inCompFunc;
  input ArgType1 inArgument1;
  output list<ElementType> outList;

  partial function CompareFunc
    input ElementType inElement1;
    input ArgType1 inArgument1;
    output Integer outRes;
  end CompareFunc;
algorithm
  outList := matchcontinue(inLeft, inRight, inCompFunc,inArgument1)
    local
      ElementType l, r;
      list<ElementType> l_rest, r_rest, res;
      Integer ri,li;

    case ({}, {}, _,_) then {};

    case (l :: l_rest, r :: _, _,_)
      equation
        ri = inCompFunc(r,inArgument1);
        li = inCompFunc(l,inArgument1);
        true = intGt(ri,li);
        res = mergeBy1(l_rest, inRight, inCompFunc,inArgument1);
      then
        l :: res;

    case (_ :: _, r :: r_rest, _,_)
      equation
        res = mergeBy1(inLeft, r_rest, inCompFunc,inArgument1);
      then
        r :: res;

    case ({}, _, _,_) then inRight;
    case (_, {}, _,_) then inLeft;

  end matchcontinue;
end mergeBy1;


protected function removeSimpleEquationsUC
" This function is a variation of the algorithm used in removeSimpleEquations.mo module.
  The main difference in this algorithm is that it is more generic since it works on ComponentRef
  without considering the variability of the symbol. Extracting uncertainties requires
  the following case:
  x = p;
  p + y;
  where 'x' is an uncertain variable, 'p' is a parameter and 'y' is a variable. This algorithm should
  remove the parameter 'p' returning the following equation:
  x + y;
"
  input BackendDAE.BackendDAE daeIn;
  output BackendDAE.BackendDAE daeOut;
algorithm
  daeOut:= match(daeIn)
    local
      BackendDAE.BackendDAE dae;
      list<AliasSet> sets;
      list<BackendDAE.Equation> other_eqns,simple_eqns;
      BackendDAE.EquationArray eqns;
      BackendDAE.Variables vars,knvars;
      list<DAE.ComponentRef> set_solutions,removed_vars;
      BackendVarTransform.VariableReplacements repl;
      HashTable.HashTable removed_vars_table;
    case(dae as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedEqs=eqns,orderedVars=vars)::_, BackendDAE.SHARED(knownVars=knvars)))
      equation
        repl=BackendVarTransform.emptyReplacements();
        removed_vars_table=HashTable.emptyHashTable();
        (sets,other_eqns)=separateAliasSetsAndEquations(BackendEquation.equationList(eqns), {}, {});
        //print("Alias Sets:\n");
        //dumpAliasSets(sets);
        set_solutions=List.map2(sets,solveAliasSet,vars,knvars);
        //print("Solutions for sets:\n");
        //print(stringDelimitList(List.map(set_solutions,ComponentReference.printComponentRefStr),"\n"));
        //print("\n");
        (repl,simple_eqns,removed_vars)=createReplacementsAndEquations(set_solutions,sets,vars,knvars,repl,{},{});
        //BackendVarTransform.dumpReplacements(repl);
        //BackendDump.dumpEquationList(simple_eqns,"Equations:\n");
        //print("Removed variables:\n");
        //ComponentReference.printComponentRefList(removed_vars);
        (other_eqns,_)=BackendVarTransform.replaceEquations(other_eqns, repl, NONE());
        removed_vars_table=addCrefsToHashTable(removed_vars, removed_vars_table);
        (vars,knvars)=moveVariables(vars, knvars, removed_vars_table);
        dae = setDaeVars(dae, vars);
        dae = BackendDAEUtil.setKnownVars(dae, knvars);
        dae = setDaeEqns(dae, BackendEquation.listEquation(listAppend(simple_eqns, other_eqns)),false);

        dae = BackendDAEUtil.transformBackendDAE(dae, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.ALLOW_UNDERCONSTRAINED())), NONE(), NONE());
        dae = BackendDAEUtil.mapEqSystem1(dae, BackendDAEUtil.getIncidenceMatrixfromOptionForMapEqSystem, BackendDAE.NORMAL());
      then dae;
  end match;
end removeSimpleEquationsUC;

protected function addCrefsToHashTable
   input list<DAE.ComponentRef> crefs;
   input HashTable.HashTable table;
   output HashTable.HashTable out;
algorithm
out:=match(crefs,table)
   local
      DAE.ComponentRef h;
      list<DAE.ComponentRef> t;
      HashTable.HashTable new_table;
   case({},_)
      then table;
   case(h::t,_)
    equation
      new_table=BaseHashTable.add((h,0),table);
      new_table=addCrefsToHashTable(t,new_table);
    then new_table;
end match;
end addCrefsToHashTable;

protected function getAllVariablesForCref
" Returns the variable asicoated to a cref taken variables or known variables"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=matchcontinue(cr,vars,knvars)
    local
      list<BackendDAE.Var> out;
    case(_,_,_)
      equation
        (out,_)=BackendVariable.getVar(cr,vars);
      then out;
    case(_,_,_)
      equation
        (out,_)=BackendVariable.getVar(cr,knvars);
      then out;
  end matchcontinue;
end getAllVariablesForCref;

protected function rateVariable
" Returns the ratign of a variable."
  input BackendDAE.Var var;
  output Real out;
  protected
    Real acc,i;
    DAE.ComponentRef cr;
algorithm
  acc:=0.0;
  BackendDAE.VAR(varName=cr) := var;
  i := 1.0 / (1.0 + intReal(ComponentReference.crefDepth(cr))); // larger names = lower rating
  acc:=acc + i;
  i:=if BackendVariable.isParam(var) then 3.0 else 0.0; // parametes has higher rating than variables
  acc:=acc + i;
  i:=if BackendVariable.isStateVar(var) then 5.0 else 0.0; // states have higher rating than variables and parameters
  acc:=acc + i;
  i:=if BackendVariable.varHasUncertainValueRefine(var) then 7.0 else 0.0; // uncertain variables have the highest rating for this elimination
  acc:=acc + i;
  out:=acc;
end rateVariable;

protected function rateVariableList
" This is an auxiliary function of rateSetElement. It takes
  all the variables associated to a cref and calculates the rating.
"
  input list<BackendDAE.Var> vars;
  output Real out;
algorithm
out:= match(vars)
  local
    Real r1,r2,r;
    BackendDAE.Var h;
    list<BackendDAE.Var> t;
    case({})
      equation
      then 0.0;
    case(h::t)
      equation
        r1 = rateVariable(h);
        r2 = rateVariableList(t);
        r = if realGt(r1,r2) then r1 else r2;
      then r;
end match;
end rateVariableList;

protected function rateSetElement
" Returns a tuple with the input cref and it's rating.
  The rating is a real number that, the bigger it is,
  the more feasible is the symbol.
"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output tuple<DAE.ComponentRef,Real> out;
  protected
  list<BackendDAE.Var> var;
algorithm
  var:=getAllVariablesForCref(cr,vars,knvars);
  out:=(cr,rateVariableList(var));
end rateSetElement;

protected function setPairSortFunction
" This function is used to sort a list of tuple<cref,real>
  based on the real number.
"
  input tuple<DAE.ComponentRef,Real> a;
  input tuple<DAE.ComponentRef,Real> b;
  output Boolean out;
  protected
  Real av,bv;
algorithm
  (_,av):=a;
  (_,bv):=b;
  out:=realLt(av,bv);
end setPairSortFunction;

protected function solveAliasSet
" Takes a set and returns the most feasible symbol to be kept (base on rateSetElement).
"
  input AliasSet set;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output DAE.ComponentRef out;
protected
  list<DAE.ComponentRef> names;
  list<tuple<DAE.ComponentRef,Real>> name_rate_list;
algorithm
  names:=getAliasSetSymbolList(set);
  name_rate_list:=List.map2(names,rateSetElement,vars,knvars);
  name_rate_list:=List.sort(name_rate_list,setPairSortFunction);
  (out,_)::_ :=name_rate_list;
end solveAliasSet;

protected function isRemovableVar
  input BackendDAE.Var var;
  output Boolean out;
  protected
    DAE.ComponentRef cr;
algorithm
  // I'm keeping only uncertain variables and states
  out:=(not BackendVariable.isStateVar(var)) and (not BackendVariable.varHasUncertainValueRefine(var));
end isRemovableVar;

protected function isRemovableVarList
  input list<BackendDAE.Var> vars;
  output Boolean out;
algorithm
out:= match(vars)
  local
    Boolean r1,r2,r;
    BackendDAE.Var h;
    list<BackendDAE.Var> t;
    case({})
      equation
      then true;
    case(h::t)
      equation
        r1 = isRemovableVar(h);
        r2 = isRemovableVarList(t);
        r = r1 and r2;
      then r;
end match;
end isRemovableVarList;

protected function isRemovableSymbol
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output Boolean out;
  protected
  list<BackendDAE.Var> var;
algorithm
  var:=getAllVariablesForCref(cr,vars,knvars);
  out:=isRemovableVarList(var);
end isRemovableSymbol;

protected function fixSingOfExp
  input Integer sign;
  input DAE.Exp eIn;
  output DAE.Exp out;
algorithm
  out:=match(sign,eIn)
    local
      DAE.Exp e;
      DAE.Type tp;
    case(-1,_)
      equation
        tp = Expression.typeof(eIn);
      then DAE.UNARY(DAE.UMINUS(tp),eIn);
    case(_,_)
      then eIn;
  end match;
end fixSingOfExp;


protected function generateEquation
  input DAE.ComponentRef cr;
  input DAE.Exp e;
  input DAE.ElementSource source;
  output BackendDAE.Equation out;
algorithm
  out := BackendDAE.SOLVED_EQUATION(cr, e, source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
end generateEquation;

protected function createReplacementsAndEquationsForSet
  input DAE.ComponentRef solution;
  input list<DAE.ComponentRef> symbols;
  input AliasSet set;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input BackendVarTransform.VariableReplacements repl_acc;
  input list<BackendDAE.Equation> eqns_acc;
  input list<DAE.ComponentRef> removed_vars_acc;
  output BackendVarTransform.VariableReplacements replOut;
  output list<BackendDAE.Equation> eqnsOut;
  output list<DAE.ComponentRef> removed_varsOut;
algorithm
  (replOut,eqnsOut,removed_varsOut):=matchcontinue(solution,symbols,set,vars,knvars,repl_acc,eqns_acc,removed_vars_acc)
    local
      list<DAE.ComponentRef> t,new_removed_vars;
      DAE.ComponentRef h;
      DAE.Exp e;
      Integer sign1,sign2,sign;
      BackendVarTransform.VariableReplacements new_repl;
      list<BackendDAE.Equation> new_eqns;
      BackendDAE.Equation eqn;
      DAE.ElementSource source;
    case(_,{},_,_,_,_,_,_)
      then (repl_acc,eqns_acc,removed_vars_acc);
    case(_,h::t,_,_,_,_,_,_)
      equation // ignore if the current cref is the solution
        true=ComponentReference.crefEqual(solution,h);
        (new_repl,new_eqns,new_removed_vars)=createReplacementsAndEquationsForSet(solution,t,set,vars,knvars,repl_acc,eqns_acc,removed_vars_acc);
      then (new_repl,new_eqns,new_removed_vars);
    case(_,h::t,_,_,_,_,_,_)
      equation // if it's removable, create a replacement
        true=isRemovableSymbol(h,vars,knvars);
        (sign1,e)=getAliasSetExpressionAndSign(solution,set);
        (sign2,_)=getAliasSetExpressionAndSign(h,set);
        sign=if sign2<0 then -sign1 else sign1;
        e=fixSingOfExp(sign,e);
        new_repl=BackendVarTransform.addReplacement(repl_acc,h,e,NONE());
        new_removed_vars=h::removed_vars_acc;
        (new_repl,new_eqns,new_removed_vars)=createReplacementsAndEquationsForSet(solution,t,set,vars,knvars,new_repl,eqns_acc,new_removed_vars);
      then (new_repl,new_eqns,new_removed_vars);
    case(_,h::t,_,_,_,_,_,_)
      equation // otherwise create an equation
        false=isRemovableSymbol(h,vars,knvars);
        (sign1,e)=getAliasSetExpressionAndSign(solution,set);
        (sign2,_)=getAliasSetExpressionAndSign(h,set);
        sign=if sign2<0 then -sign1 else sign1;
        e=fixSingOfExp(sign,e);
        source=getAliasSetSource(set);
        eqn=generateEquation(h,e,source);
        new_eqns=eqn::eqns_acc;
        (new_repl,new_eqns,new_removed_vars)=createReplacementsAndEquationsForSet(solution,t,set,vars,knvars,repl_acc,new_eqns,removed_vars_acc);
      then (new_repl,new_eqns,new_removed_vars);
  end matchcontinue;
end createReplacementsAndEquationsForSet;

protected function createReplacementsAndEquations
  input list<DAE.ComponentRef> solutions;
  input list<AliasSet> sets;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input BackendVarTransform.VariableReplacements repl_acc;
  input list<BackendDAE.Equation> eqns_acc;
  input list<DAE.ComponentRef> removed_vars_acc;
  output BackendVarTransform.VariableReplacements replOut;
  output list<BackendDAE.Equation> eqnsOut;
  output list<DAE.ComponentRef> removed_vars;
algorithm
(replOut,eqnsOut,removed_vars):=match(solutions,sets,vars,knvars,repl_acc,eqns_acc,removed_vars_acc)
  local
    list<DAE.ComponentRef> symbols,solt,new_removed_vars;
    list<AliasSet> sett;
    AliasSet set;
    DAE.ComponentRef solution;
    BackendVarTransform.VariableReplacements new_repl;
    list<BackendDAE.Equation> new_eqns;
  case({},{},_,_,_,_,_)
    then (repl_acc,eqns_acc,removed_vars_acc);
  case(solution::solt,set::sett,_,_,_,_,_)
    equation
      symbols=getAliasSetSymbolList(set);
      (new_repl,new_eqns,new_removed_vars)=createReplacementsAndEquationsForSet(solution,symbols,set,vars,knvars,repl_acc,eqns_acc,removed_vars_acc);
      (new_repl,new_eqns,new_removed_vars)=createReplacementsAndEquations(solt,sett,vars,knvars,new_repl,new_eqns,new_removed_vars);
    then (new_repl,new_eqns,new_removed_vars);
end match;
end createReplacementsAndEquations;

protected function separateAliasSetsAndEquations
" This functions takes the list of equations and creates the sets of alias equations.
  The function returns the alisas sets and the remaining equations that are not alias equations
  Note: sets and eqn_accIn are acumulators, therefore should be empty lists on firsts call.
"
  input list<BackendDAE.Equation> eqnIn;
  input list<AliasSet> sets;
  input list<BackendDAE.Equation> eqn_accIn;
  output list<AliasSet> setsOut;
  output list<BackendDAE.Equation> eqn_accOut;
algorithm
  (setsOut,eqn_accOut):=
  match (eqnIn,sets,eqn_accIn)
    local
      DAE.ComponentRef cr;
      DAE.Exp e1,e2;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> t,eqn_acc;
      list<AliasSet> new_sets;
    case({},_,_)
      equation
        eqn_acc=listReverse(eqn_accIn);
      then (sets,eqn_acc);
    case ((eqn as BackendDAE.EQUATION(exp=e1,scalar=e2))::t,_,_)
      equation
        (new_sets,eqn_acc) = addPairToSet(sets,eqn_accIn,eqn,e1,e2);
        (new_sets,eqn_acc) = separateAliasSetsAndEquations(t,new_sets,eqn_acc);
      then (new_sets,eqn_acc);
    case ((eqn as BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e2))::t,_,_)
      equation
        e1 = Expression.crefExp(cr);
        (new_sets,eqn_acc) = addPairToSet(sets,eqn_accIn,eqn,e1,e2);
        (new_sets,eqn_acc) = separateAliasSetsAndEquations(t,new_sets,eqn_acc);
      then (new_sets,eqn_acc);
    case (eqn::t,_,_)
      equation
        (new_sets,eqn_acc) = separateAliasSetsAndEquations(t,sets,eqn::eqn_accIn);
      then (new_sets,eqn_acc);
   end match;
end separateAliasSetsAndEquations;



protected function addPairToSet
" This function takes an equation and its rhs and lhs. If the equation is an alias equation, the alias is
  added to the sets. Otherwise the equation is added to the accumulator of equations."
  input list<AliasSet> sets;
  input list<BackendDAE.Equation> eqn_acc;
  input BackendDAE.Equation eqn;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  output list<AliasSet> out;
  output list<BackendDAE.Equation> eqn_acc_out;
algorithm
  (out,eqn_acc_out) := match (sets,eqn_acc,eqn,lhs,rhs)
    local
      DAE.ComponentRef cr1,cr2;
      list<AliasSet> new_sets;
      DAE.Type tp;
      DAE.Exp e1,e2;
      Option<DAE.ElementSource> source;
    // a = b;
    case (_,_,_,e1 as DAE.CREF(componentRef = cr1),e2 as DAE.CREF(componentRef = cr2))
      equation
        source=getSourceIfApproximated(eqn);
        new_sets=pushToSetList(sets,cr1,e1,1,cr2,e2,1,source);
      then (new_sets,eqn_acc);
    // a = -b;
    case (_,_,_,e1 as DAE.CREF(componentRef = cr1),DAE.UNARY(DAE.UMINUS(_),e2 as DAE.CREF(componentRef = cr2)))
      equation
        source=getSourceIfApproximated(eqn);
        new_sets=pushToSetList(sets,cr1,e1,1,cr2,e2,-1,source);
      then (new_sets,eqn_acc);
    // -a = b;
    case (_,_,_,e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),e2 as DAE.CREF(componentRef = cr2))
      equation
        source=getSourceIfApproximated(eqn);
        new_sets=pushToSetList(sets,cr1,e1,-1,cr2,e2,1,source);
      then (new_sets,eqn_acc);
    // -a = -b;
    case (_,_,_,e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr2)))
      equation
        source=getSourceIfApproximated(eqn);
        new_sets=pushToSetList(sets,cr1,e1,-1,cr2,e2,-1,source);
      then (new_sets,eqn_acc);
    else
      equation
      then (sets,eqn::eqn_acc);
    end match;
end addPairToSet;

protected function getSourceIfApproximated "Returns SOME(source) if the equation is approximated"
    input BackendDAE.Equation eqn;
    output Option<DAE.ElementSource> source;
    protected DAE.ElementSource temp;
algorithm
    temp:=BackendEquation.equationSource(eqn);
    source:=if isApproximatedEquation(eqn) then SOME(temp) else NONE();
end getSourceIfApproximated;

/*     Set handling functions    */

protected function createSet
" Creates an initial alias set. It receives the alias symbols and its signs.
"
  input DAE.ComponentRef cr1;
  input DAE.Exp e1;
  input Integer sign1In;
  input DAE.ComponentRef cr2;
  input DAE.Exp e2;
  input Integer sign2In;
  input Option<DAE.ElementSource> source;
  output AliasSet setOut;
algorithm
  setOut:=match(cr1,e1,sign1In,cr2,e2,sign2In,source)
    local
      Integer sign1,sign2;
      HashSet.HashSet new_symbols;
      HashTable.HashTable new_signs;
      HashTable2.HashTable new_expl;
    case(_,_,sign1,_,_,sign2,_)
      equation
        new_signs=HashTable.emptyHashTable();
        new_symbols=HashSet.emptyHashSet();
        new_expl=HashTable2.emptyHashTable();
        new_signs=BaseHashTable.add((cr1,sign1),new_signs);
        new_signs=BaseHashTable.add((cr2,sign2),new_signs);
        new_symbols=BaseHashSet.add(cr1,new_symbols);
        new_symbols=BaseHashSet.add(cr2,new_symbols);
        new_expl=BaseHashTable.add((cr1,e1),new_expl);
        new_expl=BaseHashTable.add((cr2,e2),new_expl);
      then ALIASSET(new_symbols,new_expl,new_signs,source);
  end match;
end createSet;


protected function addToSet
" Adds a new alias to an specific set. This function should be called only if we known
  that the current alias belongs to the set (cr1 is already in the set)."
  input AliasSet set;
  input DAE.ComponentRef cr1; // cr1 needs to be the one already belonging to the set
  input DAE.Exp e1;
  input Integer sign1In;
  input DAE.ComponentRef cr2;
  input DAE.Exp e2;
  input Integer sign2In;
  input Option<DAE.ElementSource> sourceIn;
  output AliasSet setOut;
algorithm
  setOut:=match(set,cr1,e1,sign1In,cr2,e2,sign2In,sourceIn)
    local
      Integer current_sign,sign1_temp,sign1,sign2;
      HashSet.HashSet symbols,new_symbols;
      HashTable.HashTable signs,new_signs;
      HashTable2.HashTable expl,new_expl;
      Option<DAE.ElementSource> source_current,source_new;
    case(ALIASSET(symbols,expl,signs,source_current),_,_,sign1,_,_,sign2,_)
      equation
        // fix the signs of the new alias
        current_sign=BaseHashTable.get(cr1,signs); // get existing sign of cr1
        sign1_temp=sign1;
        sign1=if intEq(sign1_temp,current_sign) then sign1 else -sign1; //If the sign of the existing set is different, change both signs
        sign2=if intEq(sign1_temp,current_sign) then sign2 else -sign2;
        new_signs=BaseHashTable.add((cr2,sign2),signs);
        new_symbols=BaseHashSet.add(cr2,symbols);
        new_expl=BaseHashTable.add((cr2,e2),expl);
        source_new=updateSource(source_current,sourceIn);
      then ALIASSET(new_symbols,new_expl,new_signs,source_new);
  end match;
end addToSet;

protected function updateSource "Takes the source of the current set and the new alias.
If the existing source is NONE and the new SOME, if is replaced, otherwise the source is kept.
Note: the source is only added when the equation is approximated."
  input Option<DAE.ElementSource> source1;
  input Option<DAE.ElementSource> source2;
  output Option<DAE.ElementSource> sourceOut;
algorithm
  sourceOut:=match(source1,source2)
        local
        DAE.ElementSource s;
        case(NONE(),NONE())
            then NONE();
        case(SOME(s),NONE())
            then SOME(s);
        case(NONE(),SOME(s))
            then SOME(s);
        case(SOME(s),SOME(_))
            then SOME(s);
  end match;
end updateSource;

protected function existsInSet
" Returns true if the cr belongs to an alias set."
  input AliasSet set;
  input DAE.ComponentRef cr;
  output Boolean out;
algorithm
  out:=match(set,cr)
    local
      HashSet.HashSet symbols;
      Boolean ret;
    case(ALIASSET(symbols,_,_,_),_)
      equation
        ret = BaseHashSet.has(cr,symbols);
      then ret;
  end match;
end existsInSet;

protected function pushToSetList
" This function takes an alias and insert it to its corresponding set. If the alias
  does cannot be inserted in any set, it creates a new set."
  input list<AliasSet> sets;
  input DAE.ComponentRef cr1;
  input DAE.Exp e1;
  input Integer sign1;
  input DAE.ComponentRef cr2;
  input DAE.Exp e2;
  input Integer sign2;
  input Option<DAE.ElementSource> source;
  output list<AliasSet> setsOut;
algorithm
  setsOut:=matchcontinue(sets,cr1,e1,sign1,cr2,e2,sign2,source)
    local
      AliasSet new_set,h;
      list<AliasSet> t,inner_sets;
    case({},_,_,_,_,_,_,_)
      equation  // None of the crs exist in a set. Create a new one
        new_set = createSet(cr1,e1,sign1,cr2,e2,sign2,source);
      then {new_set};
    case(h::t,_,_,_,_,_,_,_)
      equation
        true=existsInSet(h,cr1); // cr1 exists in a set
        new_set=addToSet(h,cr1,e1,sign1,cr2,e2,sign2,source);
      then new_set::t;
    case(h::t,_,_,_,_,_,_,_)
      equation
        true=existsInSet(h,cr2); // cr2 exists in a set
        new_set=addToSet(h,cr2,e2,sign2,cr1,e1,sign1,source);
      then new_set::t;
    case(h::t,_,_,_,_,_,_,_)
      equation
        inner_sets=pushToSetList(t,cr1,e1,sign1,cr2,e2,sign2,source);
      then h::inner_sets;
  end matchcontinue;
end pushToSetList;


protected function getAliasSetSymbolList
  input AliasSet set;
  output list<DAE.ComponentRef> out;
algorithm
out:=match(set)
  local
    list<DAE.ComponentRef> crl;
    HashSet.HashSet symbols;
  case(ALIASSET(symbols,_,_,_))
    equation
      crl=BaseHashSet.hashSetList(symbols);
    then crl;
end match;
end getAliasSetSymbolList;

protected function getAliasSetSource
  input AliasSet set;
  output DAE.ElementSource out;
algorithm
out:=match(set)
  local
    DAE.ElementSource source;
  case(ALIASSET(_,_,_,SOME(source)))
    then source;
  case(ALIASSET(_,_,_,NONE()))
    then DAE.emptyElementSource;
end match;
end getAliasSetSource;

protected function getAliasSetExpressionAndSign
  input DAE.ComponentRef cr;
  input AliasSet set;
  output Integer signOut;
  output DAE.Exp eOut;
algorithm
(signOut,eOut):=match(cr,set)
  local
    HashTable2.HashTable expl;
    HashTable.HashTable signs;
    Integer sign;
    DAE.Exp e;
  case(_,ALIASSET(_,expl,signs,_))
    equation
      sign=BaseHashTable.get(cr,signs);
      e=BaseHashTable.get(cr,expl);
    then (sign,e);
end match;
end getAliasSetExpressionAndSign;


protected function dumpAliasSets
" Prints all the sets"
  input list<AliasSet> sets;
algorithm
  _:=match(sets)
    local
      list<AliasSet> t;
      list<DAE.ComponentRef> crefs;
      list<Integer> sign_values;
      HashSet.HashSet symbols;
      HashTable.HashTable signs;
      Option<DAE.ElementSource> source;
    case({})
      then ();
    case(ALIASSET(symbols,_,signs,source)::t)
      equation
        crefs=BaseHashSet.hashSetList(symbols);
        sign_values=List.map1(crefs,BaseHashTable.get,signs);
        dumpAliasSets2(crefs,sign_values);
        dumpAliasSets3(source);
        print("\n");
        dumpAliasSets(t);
      then ();
  end match;
end dumpAliasSets;

protected function dumpAliasSets2
  input list<DAE.ComponentRef> crefs;
  input list<Integer> sign_values;
algorithm
  _:=match(crefs,sign_values)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> cr_t;
      Integer i;
      list<Integer> i_t;
      String s;
    case({},{})
      then ();
    case(cr::cr_t,i::i_t)
      equation
        s = if i>0 then "+" else "-";
        print(s+ComponentReference.printComponentRefStr(cr)+", ");
        dumpAliasSets2(cr_t,i_t);
      then ();
  end match;
end dumpAliasSets2;

protected function dumpAliasSets3 "
Auxiliary function of dumpAliasSets. Prints true if the alias came from an approximated equation."
  input Option<DAE.ElementSource> sourceIn;
algorithm
  _ :=match(sourceIn)
  local
    list<SCode.Comment> comment;
    String str;
  case(NONE())
  equation
    print(" *Approximated = false");
  then ();
  case(SOME(DAE.SOURCE(comment=comment)))
  equation
    str = boolString(isApproximatedEquation2(comment));
    print(" *Approximated = "+str);
  then ();
  end match;
end dumpAliasSets3;

annotation(__OpenModelica_Interface="backend");
end Uncertainties;
