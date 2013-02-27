package Uncertainties
  
  import DAE;
  import Absyn;
  import Algorithm;
  import BackendDAE;
  import BackendVariable;
  import Debug;
  import List;
  import Env;
  import Interactive;
  import Values;
  import SCode;
  import Flags;
  import Error;
  import System;
  import CevalScript;
  import Dependency;
  import SCodeUtil;
  import Inst;
  import InnerOuter; 
  import DAEUtil;
  import BackendDAECreate;
  import BackendDAEUtil;
  import BackendDAETransform; 
  import BackendEquation;
  import HashTable;
  import ComponentReference;
  import BaseHashTable;
  import Expression;
  import ClassInf;
  import BackendVarTransform;
  import ExpressionSolve;
  import ExpressionSimplify;
  import MathematicaDump;
  import Matching;
  import BackendDAEEXT;
  import Util;
  import Print;

type ExtIncidenceMatrixRow = tuple<Integer,list<Integer>>; 
type ExtIncidenceMatrix = list<ExtIncidenceMatrixRow>;
  
public function modelEquationsUC
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input String outputFileIn;
  input Boolean dumpSteps;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;

algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,outputFileIn,dumpSteps)
    local
      String outputFile,resstr;
      
      DAE.DAElist dae;
      Env.Cache cache;
      list<Env.Frame> env;
      Absyn.Program p;

      BackendDAE.BackendDAE dlow,dlow_1;
      Interactive.SymbolTable st;
      DAE.FunctionTree funcs;
      
      BackendDAE.IncidenceMatrix m,mt,my,mx;
      array<Integer> ass1,ass2;
      
      Integer varCount;
      BackendDAE.Variables vars,kvars;
      list<Integer>  varIndexList, allVarIndexList, refineVarIndexList, elimVarIndexList,approximatedEquations,approximatedEquations_one,equationToExtract,otherEquations,squareBlockEquations,removedVars;
      BackendDAE.EquationArray eqns,ieqns;
      list<BackendDAE.Equation> setC_eq,setS_eq;
      list<BackendDAE.EqSystem> eqsyslist; 
      BackendDAE.Variables allVars,knownVariables,unknownVariables,sharedVars;
      BackendDAE.EquationArray allEqs;
      list<Integer> variables,knowns,unknowns,directlyLinked,indirectlyLinked,outputvars; 
      BackendDAE.Shared shared;
      
      BackendDAE.EqSystem currentSystem,newSystem;
      BackendDAE.EquationArray newSystemEqns;
      BackendDAE.Variables newSystemVars;

      list<Integer> yEqMap,yVarMap,xEqMap,xVarMap;
      Integer nEqs,nVars;
      ExtIncidenceMatrix mExt,knownsSystem;
      list<Integer> setS,setC,unknownsVarsMatch,unknownsEqsMatch,remainingEquations;  

      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;
      
      String outStringA,outStringB,outString;
      list<Option<DAE.Distribution>> distributions;

    case (cache,env,_,(st as Interactive.SYMBOLTABLE(ast = p)),outputFile,_)
      equation
        //print("Initiating\n");   
        Print.clearBuf();

        (dae,cache,env) = flattenModel(className,p,cache);

        //print("- Flatten ok\n");   
        dlow = BackendDAECreate.lower(dae,cache,env);
        //(dlow_1,funcs1) = BackendDAEUtil.getSolvedSystem(dlow, funcs,SOME({"removeSimpleEquations","removeFinalParameters", "removeEqualFunctionCalls", "expandDerOperator"}), NONE(), NONE(),NONE());
        (dlow_1) = BackendDAEUtil.getSolvedSystem(dlow, SOME({"removeAllSimpleEquations","removeUnusedVariables","removeEqualFunctionCalls", "expandDerOperator"}), NONE(), NONE(),SOME({""}));
        //print("* Lowered Ok \n");

        //BackendDump.dump(dlow_1);

        BackendDAE.DAE(currentSystem::eqsyslist,shared) = dlow_1;
        BackendDAE.EQSYSTEM(orderedVars=allVars,orderedEqs=allEqs) = currentSystem;
        BackendDAE.SHARED(knownVars=sharedVars) = shared;         
        
        (m,mt,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.incidenceMatrixScalar(currentSystem,BackendDAE.NORMAL(),NONE());

        //(dlow_1 as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars=allVars,orderedEqs=allEqs,m=SOME(m),mT=SOME(mt))::eqsyslist,_)) = BackendDAEUtil.mapEqSystem(dlow_1,BackendDAEUtil.getIncidenceMatrixScalarfromOptionForMapEqSystem);

        true = intEq(0,listLength(eqsyslist));
        mExt=getExtIncidenceMatrix(m);
        
        //dumpExtIncidenceMatrix(mExt);

        variables = List.intRange(BackendVariable.varsSize(allVars));       
        (knowns,_) = getUncertainRefineVariableIndexes(allVars,variables);
        directlyLinked = getRelatedVariables(mExt,knowns);
        indirectlyLinked = List.setDifference(getRelatedVariables(mExt,directlyLinked),knowns);
        unknowns = listAppend(directlyLinked,indirectlyLinked);
        outputvars = List.setDifference(List.intRange(BackendVariable.varsSize(allVars)),listAppend(unknowns,knowns));

        
        printSep(getMathematicaText("== Initial system =="));
        //printSep(getMathematicaText("Equations (Function calls represent more than one equation"));
        //printSep(equationsToMathematicaGrid(List.intRange(BackendDAEUtil.equationSize(allEqs)),allEqs,allVars,sharedVars,mapIncRowEqn));
        
        //printSep(getMathematicaText("All variables"));
        //printSep(variablesToMathematicaGrid(List.intRange(BackendVariable.varsSize(allVars)),allVars));                 
        //print("Checkpoint 1\n");
        // First try to eliminate all the unknown variables
        dlow_1 = eliminateVariablesDAE(unknowns,dlow_1);
        BackendDAE.DAE(currentSystem::eqsyslist,shared) = dlow_1;
        BackendDAE.EQSYSTEM(orderedVars=allVars,orderedEqs=allEqs) = currentSystem;
        BackendDAE.SHARED(knownVars=sharedVars) = shared;         
        

        (m,mt,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.incidenceMatrixScalar(currentSystem,BackendDAE.NORMAL(),NONE());

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

        (setC)=getEquationsForKnownsSystem(mExt,knowns,unknowns,setS,allEqs,allVars,sharedVars,mapIncRowEqn);
        

        printSep(getMathematicaText("Final Equations"));
        printSep(equationsToMathematicaGrid(setC,allEqs,allVars,sharedVars,mapIncRowEqn));


        setC=List.map1r(setC,listGet,arrayList(mapIncRowEqn));
        setC=List.unique(List.map1(setC,intAdd,-1));       
        setS=List.map1r(setS,listGet,arrayList(mapIncRowEqn));
        setS=List.unique(List.map1(setS,intAdd,-1));   

        setC_eq=List.map1r(setC,BackendDAEUtil.equationNth,allEqs);
        setS_eq=List.map1r(setS,BackendDAEUtil.equationNth,allEqs);
        
       //eqnLst = BackendEquation.equationList(eqns);
        
        knownVariables = BackendVariable.listVar(List.map1r(knowns,BackendVariable.getVarAt,allVars));
        unknownVariables = BackendVariable.listVar(List.map1r(unknowns,BackendVariable.getVarAt,allVars));

        //print("* Uncertainty equations extracted: \n");
        //BackendDump.dumpEqns(setC_eq);

        //print("* Auxiliary set of equations: \n");
        //BackendDump.dumpEqns(setS_eq);

        outStringB = "{{"+&getMathematicaVarStr(knownVariables)+&","+&getMathematicaEqStr(setC_eq,allVars,sharedVars)+&"},{"
                        +&getMathematicaVarStr(unknownVariables)+&","+&getMathematicaEqStr(setS_eq,allVars,sharedVars)+&"},"
                        +&dumpVarsDistributionInfo(distributions)+&"}";
        Print.printBuf("{"+&getMathematicaText("Extraction finished")+&"}");
        outStringA = "Grid[{"+&Print.getString()+&"}]";

        outString=Util.if_(dumpSteps,outStringA,outStringB);
        resstr=writeFileIfNonEmpty(outputFile,outString);
        //resstr="Done...";
      then
        (cache,Values.STRING(resstr),st);
    case (_,_,_,_,outputFile,_)
      equation
        Print.printBuf("{"+&getMathematicaText("Extraction failed")+&"}");
        outStringA = "Grid[{"+&Print.getString()+&"}]"; 
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
  oText:="{"+&text+&"}";
end wrapInList;

protected function verticalGrid
  input list<String> elems;
  output String out;
algorithm
  out:="Grid[{"+&stringDelimitList(List.map(elems,wrapInList),",")+&"}]";
end verticalGrid;

protected function verticalGridBoxed
  input list<String> elems;
  output String out;
algorithm
  out:="Grid[{"+&stringDelimitList(List.map(elems,wrapInList),",")+&"},Frame -> All]";
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
        s="{"+&(intString(index))+&","+&h+&"}";
      then s;  
    case(h::t,_)
        equation
          s="{"+&(intString(index))+&","+&h+&"}";
          ss=s+&","+&(numerateList(t,index+1));
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
        s="{"+&(intString(n))+&","+&h+&"}";
      then s;  
    case(h::t,n::tn)
        equation
          s="{"+&(intString(n))+&","+&h+&"}";
          ss=s+&","+&(numerateListIndex(t,tn));
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
  eqns:=List.unique(List.map1r(equIndices,listGet,arrayList(mapIncRowEqn)));
  eqList:=List.map1r(List.map1(eqns,intAdd,-1),BackendDAEUtil.equationNth,allEqs);
  eqsString:=List.map1(eqList,MathematicaDump.printMmaEqnStr,(variables,knownVariables));
  out:="Grid[{"+&numerateListIndex(eqsString,eqns)+&"},Frame -> All]";
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
    equation print("Warning: the matching in Step 5 was not perfomed successfully");
    then {};
  case(_,{})
    equation print("Warning: the matching in Step 5 was not perfomed successfully");
    then {};    
  case(var::var_t,eqn::eqn_t)
      equation
        s = var+&","+&eqn;
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
      s = "\"-\"" ;
    then s::r;
  case(eqn::eqn_t,_,_,_,_)
    equation
      e = BackendDAEUtil.equationNth(allEqs,eqn-1);
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
  out:="Grid[{"+&numerateListIndex(eqsString,varIndices)+&"},Frame -> All]";
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
        //print("Mathematica Expression =\n"+&content);
      then content;
    case(_,_)
      equation
        directory=System.dirname(filename);
        true=System.directoryExists(directory);
        //print("Writing file "+&filename);
        System.writeFile(filename,content);
      then "Done...";
    case(_,_)
        equation
          //print("Mathematica Expression =\n"+&content); 
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
  s:="{"+&stringDelimitList(List.map(d,dumpVarDistributionInfo),",")+&"}";
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
        case(h::t,i)
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
    case(h::t)
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
  case(SCode.NAMEMOD("__OpenModelica_ApproximatedEquation",SCode.MOD(binding = SOME((Absyn.BOOL(true),_)))))
     then true;
  case(_)
     then false;
   end match;           
end isApproximatedEquation3;


protected function flattenModel
  input Absyn.Path className;
  input Absyn.Program p;
  input Env.Cache icache;
  output DAE.DAElist daeOut;
  output Env.Cache cacheOut;
  output list<Env.Frame> envOut;
algorithm
(daeOut,cacheOut,envOut):=matchcontinue(className,p,icache)
  local
    list<SCode.Element> p_1;
    Absyn.Program ptot;
    DAE.DAElist dae;
    list<Env.Frame> env;
    Real timeFrontend;
    String resstr;
    Env.Cache cache;
  case(_,_,_)
    equation
      System.realtimeTick(CevalScript.RT_CLOCK_UNCERTAINTIES);
      ptot = Dependency.getTotalProgram(className,p);
      p_1 = SCodeUtil.translateAbsyn2SCode(ptot);
      (cache,env,_,dae) = Inst.instantiateClass(icache,InnerOuter.emptyInstHierarchy,p_1,className);
      timeFrontend = System.realtimeTock(CevalScript.RT_CLOCK_UNCERTAINTIES);
      System.realtimeTick(CevalScript.RT_CLOCK_BACKEND);
      dae = DAEUtil.transformationsBeforeBackend(cache,env,dae);
    then (dae,cache,env);
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
  out := "{"+&Util.stringDelimitListNonEmptyElts(listAppend(listAppend(states,algs),listAppend(outputs,inputsStates)),",")+&"}";
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
        ass1=listArray(List.fill(-1,ne)); 
        ass2=listArray(List.fill(-1,nv));
        true = BackendDAEEXT.setAssignment(nv,ne,ass1,ass2);
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
algorithm
(setCOut):=matchcontinue(m,knowns,unknowns,setS,allEqs,variables,knownVariables,mapIncRowEqn)
  local 
    ExtIncidenceMatrix knownsSystem,knownsSystemComp;
    list<Integer> xEqMap,xVarMap;
    BackendDAE.IncidenceMatrix mx,mt;
    array<Integer> ass1,ass2;
    list<list<Integer>> comps,comps_fixed;
    list<Integer> setC;
    String dump,text;
    Integer nxVarMap,nxEqMap;
  case(_,{},_,_,_,_,_,_)
    equation
    then ({});
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

        knownsSystemComp=reduceVariables(knownsSystemComp,knowns);
        //dumpExtIncidenceMatrix(knownsSystemComp);

        (xEqMap,xVarMap,mx)=prepareForMatching(knownsSystemComp);
        nxVarMap = listLength(xVarMap);
        nxEqMap = listLength(xEqMap);
        //print("Final matching of "+&intString(nxEqMap)+&" equations and "+&intString(nxVarMap)+&" variables \n");
        nxVarMap=Util.if_(nxEqMap>nxVarMap,nxEqMap,nxVarMap);
        Matching.matchingExternalsetIncidenceMatrix(nxVarMap,nxEqMap,mx);
        

        ass1=listArray(List.fill(0,nxEqMap)); 
        ass2=listArray(List.fill(0,nxVarMap));

        true = BackendDAEEXT.setAssignment(nxVarMap,nxEqMap,ass2,ass1);
        BackendDAEEXT.matching(nxVarMap,nxEqMap,1,-1,1.0,0);

        BackendDAEEXT.getAssignment(ass1,ass2);

        mt = BackendDAEUtil.transposeMatrix(mx,nxVarMap);

        comps = getComponentsWrapper(mx,mt,ass1,ass2);
        
        comps_fixed =List.map1(comps,restoreIndicesEquivalence,xEqMap);
        knownsSystem=removeEquationInSquaredBlock(knownsSystem,knowns,unknowns,comps_fixed);
        //BackendDump.dumpComponentsOLD(comps_fixed);

        comps_fixed = List.map1(comps_fixed,restoreIndicesEquivalence,arrayList(mapIncRowEqn)); // this is done to print the correct numbers
        printSep(getMathematicaText("Blocks (each row is a block)"));
        printSep("Grid["+&listString(List.map(comps_fixed,intListString))+&",Frame->All]");
        
        
        printSep(equationsToMathematicaGrid(getEquationsNumber(knownsSystem),allEqs,variables,knownVariables,mapIncRowEqn));
        printSep(getMathematicaText("System of knowns after step 8 and 9"));
        
        setC=getEquationsNumber(knownsSystem);
      then (setC);  
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
  out:= "("+&stringDelimitList(List.map(vars,intString),",")+&") ("+&stringDelimitList(List.map(occurrences,intString),",")+&")";
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
        temp = listGet(candidate,1);
        //print("Eliminating "+&intString(temp)+&"\n");
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
out:=matchcontinue(variables,occurrences,acc)
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
end matchcontinue;
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
  case(m,var::tail)
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
      case((eq,vars)::tail,_)
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
numbers:=matchcontinue(m)
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
  end matchcontinue;
end getEquationsNumber;

protected function getMathematicaText
  input String text;
  output String textOut;
algorithm
  textOut:="Text[Style[\""+&text+&"\",Bold,Large]]";
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
       failure(_=BackendDAETransform.tarjanAlgorithm(mt,ass2));
       
       print("TarjanAlgorithm failed\n");
       Error.clearMessages();
       comp = List.intRange(arrayLength(m));
       comps = {comp};
    then
      comps;
  case(_,_,_,_)
    equation
       comps=BackendDAETransform.tarjanAlgorithm(mt,ass2);
    then
      comps;           
end matchcontinue;
end getComponentsWrapper;

protected function getVariables
  input ExtIncidenceMatrix m;
  output list<Integer> varsOut;
algorithm
varsOut:=matchcontinue(m)
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
end matchcontinue;
end getVariables;

protected function listTail
  input ExtIncidenceMatrix l;
  output ExtIncidenceMatrix o;
algorithm
o:=matchcontinue(l)
  local 
    ExtIncidenceMatrix t;
  case({})
    equation
    then {};
  case({_})
    equation
    then {};
  case(_::t)
    equation
    then t;  
end matchcontinue;
end listTail;

protected function removeEquationInSquaredBlock
  input ExtIncidenceMatrix m;
  input list<Integer> knowns;
  input list<Integer> unknowns;
  input list<list<Integer>> components;
  output ExtIncidenceMatrix mOut;
algorithm
mOut:=matchcontinue(m,knowns,unknowns,components)
  local
    list<Integer> h,vars,usedKnowns;
    list<list<Integer>> t;
    ExtIncidenceMatrix compEqns,compsSorted,tailEquations,inner_ret;
  case(_,_,_,{})
    equation
    then {};
  case(_,_,_,h::t)
    equation
       compEqns=getEquations(m,h);
       vars=getVariables(compEqns);
       usedKnowns=List.intersectionOnTrue(vars,knowns,intEq);
       true=intEq(listLength(h),listLength(usedKnowns));
       compsSorted=listReverse(sortEquations(compEqns,unknowns));
       tailEquations=listTail(compsSorted);
       inner_ret=removeEquationInSquaredBlock(m,knowns,unknowns,t);
    then listAppend(tailEquations,inner_ret);
  case(_,_,_,h::t)
    equation
       compEqns=getEquations(m,h);
       vars=getVariables(compEqns);
       usedKnowns=List.intersectionOnTrue(vars,knowns,intEq);
       false=intEq(listLength(h),listLength(usedKnowns));
       inner_ret=removeEquationInSquaredBlock(m,knowns,unknowns,t);
    then listAppend(compEqns,inner_ret);    
end matchcontinue;
end removeEquationInSquaredBlock;

protected function printIntList
  input list<Integer> l;
algorithm
  print("List of size = "+&intString(listLength(l))+&"\n");
  print(stringDelimitList(List.map(l,intString),","));
  print("\n");
end printIntList;

protected function intListString
  input list<Integer> l;
  output String out;
algorithm
  out:="{"+&stringDelimitList(List.map(l,intString),",")+&"}";
end intListString;

protected function listString
  input list<String> l;
  output String out;
algorithm
  out:="{"+&stringDelimitList(l,",")+&"}";
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
  out:=matchcontinue(row,knowns)
    local
      list<Integer> vars;
      Integer n;
    case((_,vars),_)
        equation
          n=listLength(List.intersectionOnTrue(vars,knowns,intEq));
        then n;  
  end matchcontinue;
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
  case((eq,vars)::t,_,_)
      equation
        newVars = List.filter1OnTrue(vars,removeVarsNotInSet_helper,set);
        true = intEq(listLength(newVars),0);
      then removeVarsNotInSet(t,set,acc);
  case((eq,vars)::t,_,_)
      equation
        newVars = List.filter1OnTrue(vars,removeVarsNotInSet_helper,set);
        false = intEq(listLength(newVars),0);
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
  case((e as (eq,_))::t,_)
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
out:=matchcontinue(row,knowns)
  local
    list<Integer> vars;
    Boolean ret;
  case((_,vars),_)
      equation
        ret = containsAny(vars,knowns);
      then ret;  
end matchcontinue;
end removeUnrelatedEquations2;

protected function removeUnrelatedEquations
  input ExtIncidenceMatrix m;
  input list<Integer> knowns;
  output ExtIncidenceMatrix mOut;
algorithm
mOut:=List.filter1OnTrue(m,removeUnrelatedEquations2,knowns);
end removeUnrelatedEquations;

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
  case((h as (_,eqvars))::t,_)
    equation
      true = containsAny(eqvars,vars);
      eqvars = listAppend(eqvars,getRelatedVariables(t,vars));
      eqvars = List.setDifference(setOfList(eqvars),vars);
    then eqvars;
  case((h as (_,eqvars))::t,_)
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
out:=matchcontinue(inList,map)
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
end matchcontinue;
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
      pos = List.position(index,map)+1;
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
(varMapOut,varsOut):=matchcontinue(vars,map,varsFixed)
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
end matchcontinue;
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
(eqMapOut,varMapOut,mOut):=matchcontinue(mExt,eqMap,varMap,m)
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
  end matchcontinue;
end prepareForMatching2;

protected function prepareForMatching
  input ExtIncidenceMatrix mExt;
  output list<Integer> eqMap;
  output list<Integer> varMap;
  output BackendDAE.IncidenceMatrix mOut;
  protected list<list<Integer>> m;
algorithm
(eqMap,varMap,m):=prepareForMatching2(mExt,{},{},{});
//print("Matrix to match: equations = "+&intString(listLength(eqMap))+&" variables = "+&intString(listLength(varMap))+&"\n");
mOut:=listArray(m);
end prepareForMatching;

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
  mOut:=matchcontinue(i,m,acc)
    local
      BackendDAE.IncidenceMatrixElement h;
      list<BackendDAE.IncidenceMatrixElement> t;
    case(_,{},_)
      equation
      then listReverse(acc);
    case(_,h::t,_)
        equation
        then getExtIncidenceMatrix2(i+1,t,(i,h)::acc);  
  end matchcontinue;
end getExtIncidenceMatrix2;

protected function dumpExtIncidenceMatrix
  input ExtIncidenceMatrix m;
algorithm
  _:=matchcontinue(m)
    local
      ExtIncidenceMatrix t;
      Integer eq;
      list<Integer> vars;
    case({})
        then ();  
    case((eq,vars)::t)
        equation
          print(intString(eq)+&":"+&stringDelimitList(List.map(vars,intString),",")+&"\n");
          dumpExtIncidenceMatrix(t);
        then ();  
  end matchcontinue;
end dumpExtIncidenceMatrix;

protected function containsAny
  input list<Integer> m1;
  input list<Integer> m2;
  output Boolean out;
  protected list<Integer> m3;
algorithm
  m3:=List.intersectionOnTrue(m1,m2,intEq);
  out:=listLength(m3)>0;
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
      ieqnLst = BackendEquation.equationList(ieqns);
      eqnLst = BackendEquation.equationList(eqns);
      crefDouble = findArraysPartiallyIndexed(eqnLst);      
      //print("partially indexed crs:"+&Util.stringDelimitList(Util.listMap(crefDouble,Exp.printComponentRefStr),",\n")+&"\n");
      repl = BackendVarTransform.emptyReplacements();

      (m,_,_,_) = BackendDAEUtil.incidenceMatrixScalar(syst, BackendDAE.NORMAL(),NONE()); 
      (eqnLst,seqns,movedvars_1,repl) = eliminateVariablesDAE2(eqnLst,1,vars,kvars,HashTable.emptyHashTable(),repl,crefDouble,m,elimVarIndexList,false);
      //Debug.fcall("dumprepl",BackendVarTransform.dumpReplacements,repl);

      dae = setDaeEqns(dae,BackendEquation.listEquation(eqnLst),false);
      //dae = setDaeSimpleEqns(dae,listEquation(listAppend(equationList(reqns),seqns)));
      dae = replaceDAElow(dae,repl,NONE(),false);  
      (vars_1,kvars_1) = moveVariables(BackendVariable.daeVars(syst),BackendVariable.daeKnVars(shared),movedvars_1); 
      dae = setDaeVars(dae,vars_1);
      dae = setDaeKnownVars(dae,kvars_1);
      
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
        expl = Algorithm.getAllExps(alg);
        ht = findArraysPartiallyIndexed1(eqs,ht);
      then
        ht;
       
    case((eq1 as BackendDAE.ARRAY_EQUATION(left=e1,right=e2)) :: eqs,ht)
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
      
    case(((e1 as DAE.CREF(c1,_))::expl1),dubRef,ht) 
      equation
        c2 = ComponentReference.crefStripLastSubs(c1);
        failure(_ = BaseHashTable.get(c2,dubRef));
        dubRef = BaseHashTable.add((c2,1),dubRef);
        ht = findArraysPartiallyIndexed2(expl1,dubRef,ht);
      then ht;
        
    case(((e1 as DAE.CREF(c1,_))::expl1),dubRef,ht) 
      equation
        c2 = ComponentReference.crefStripLastSubs(c1);
        _ = BaseHashTable.get(c2,dubRef);
        _ = BaseHashTable.get(c2,ht);// if we have one occurrence, most likely it will be more.
        ht = findArraysPartiallyIndexed2(expl1,dubRef,ht);
      then ht;
    
    case(((e1 as DAE.CREF(c1,_))::expl1),dubRef,ht) 
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
    case((e1 as DAE.CREF(c1,_))::expl1,ht) equation
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
 (_,outHt) := BackendEquation.traverseBackendDAEExpsEqnList(inEqs,findArraysPartiallyIndexedRecordsExpVisitor,ht);
 //print("partially indexed crs from reccrs:"+&Util.stringDelimitList(Util.listMap(outRef,Exp.printComponentRefStr),",\n")+&"\n");
end findArraysPartiallyIndexedRecords; 

protected function findArraysPartiallyIndexedRecordsExpVisitor "visitor function for expressions in findArraysPartiallyIndexedRecords"
  input tuple<DAE.Exp,HashTable.HashTable> inTpl;
  output tuple<DAE.Exp,HashTable.HashTable> outTpl;
algorithm
    outTpl := matchcontinue(inTpl)
    local
      DAE.ComponentRef cr;
      HashTable.HashTable ht;
      list<DAE.Var> varLst;
      DAE.Exp e; 
      case((e as DAE.CREF(cr,_),ht)) equation
        DAE.T_COMPLEX(varLst = varLst,complexClassType=ClassInf.RECORD(_)) = ComponentReference.crefLastType(cr); 
        ht = findArraysInRecordLst(ht,cr,varLst);       
      then ((e,ht));
      case((e,ht)) then ((e,ht));
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
      ({e},_) = BackendVarTransform.replaceEquations({e},repl,NONE());
      
      // Attempt to solve the equation wrt to the variables to be eliminated.
      varIndexList = m[eqnIndex];
      (elimVarIndex :: _) = List.intersectionOnTrue(varIndexList, elimVarIndexList, intEq);
      elimVarIndexList_1 = List.removeOnTrue(elimVarIndex,  intEq, elimVarIndexList);
      BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(varOptArr = varOptArr)) = vars;
      SOME(elimVar) = varOptArr[elimVarIndex];
      BackendDAE.VAR(varName = cr1) = elimVar;
      (e2, source) = solveEqn2(e, cr1);
//      print("Eliminated variable #" +& intString(elimVarIndex) +& " in equation #" +& intString(eqnIndex) +& "\n");

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
      (eqns_1,(BackendDAE.SOLVED_EQUATION(cr1,e2,source,false) :: seqns_1),mvars_2,repl_2);
      
    // Next equation.
    case ((e :: eqns),_,_,_,_,_,_,_,_,false)
      equation
        (eqns_1,seqns_1,mvars_1,repl_1) = eliminateVariablesDAE2(eqns, eqnIndex + 1, vars, knvars, mvars,  repl, inDoubles, m, elimVarIndexList, false) "Not a simple variable, check rest" ;
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

public function setDaeVars "
   note: this function destroys matching
"
  input BackendDAE.BackendDAE systIn;
  input BackendDAE.Variables newVarsIn;
  output BackendDAE.BackendDAE sysOut;
protected
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrixT> mT;
  BackendDAE.Matching matching;
  BackendDAE.Shared shared;
  BackendDAE.EquationArray eqns;
  list<BackendDAE.EqSystem> eqlist;
  BackendDAE.StateSets stateSets;
algorithm
  BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedEqs=eqns,m=m,mT=mT,matching=matching,stateSets=stateSets)::eqlist,shared) := systIn;
  sysOut := BackendDAE.DAE(BackendDAE.EQSYSTEM(newVarsIn,eqns,m,mT,matching,stateSets)::eqlist,shared);
end setDaeVars; 

public function setDaeEqns "set the equations of a dae
public function setEquations 
"
  input BackendDAE.BackendDAE dae;
  input BackendDAE.EquationArray eqns;
  input Boolean initEqs "if true, set initialEquations instead of ordered equations";
  output BackendDAE.BackendDAE odae;
algorithm
  odae := match(dae,eqns,initEqs)
  local 
    
    BackendDAE.EqSystem syst;
    list<BackendDAE.EqSystem> systList;
    BackendDAE.Shared shared;
    
    BackendDAE.Variables orderedVars "orderedVars ; ordered Variables, only states and alg. vars" ;
    BackendDAE.EquationArray orderedEqs "orderedEqs ; ordered Equations" ;
    Option<BackendDAE.IncidenceMatrix> m;
    Option<BackendDAE.IncidenceMatrixT> mT;
    BackendDAE.Matching matching;
    
    BackendDAE.Variables knownVars "knownVars ; Known variables, i.e. constants and parameters" ;
    BackendDAE.Variables externalObjects "External object variables";
    BackendDAE.Variables aliasVars "mappings of alias-variables to real-variables"; // added asodja 2010-03-03
    BackendDAE.EquationArray initialEqs "initialEqs ; Initial equations" ;
    BackendDAE.EquationArray removedEqs "these are equations that cannot solve for a variable. for example assertions, external function calls, algorithm sections without effect" ;
    array<DAE.Constraint> constraints "constraints" ;
    array<DAE.ClassAttributes> classAttrs;
    Env.Cache cache;
    Env.Env env;    
    DAE.FunctionTree funcs;
    BackendDAE.EventInfo eventInfo "eventInfo" ;
    BackendDAE.ExternalObjectClasses extObjClasses "classes of external objects, contains constructor & destructor";
    BackendDAE.BackendDAEType backendDAEType "indicate for what the BackendDAE is used"; 
    BackendDAE.SymbolicJacobians symjacs;
    BackendDAE.StateSets stateSets;
    
    case(BackendDAE.DAE(
      (syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars,orderedEqs=orderedEqs,m=m,mT=mT,matching=matching,stateSets=stateSets))::systList,
      (shared as BackendDAE.SHARED(knownVars=knownVars,externalObjects=externalObjects,aliasVars=aliasVars,initialEqs=initialEqs,
                                   removedEqs=removedEqs,functionTree=funcs,
                                   eventInfo=eventInfo,extObjClasses=extObjClasses,backendDAEType=backendDAEType,symjacs=symjacs))),_,false) 
    equation
       syst = BackendDAE.EQSYSTEM(orderedVars,eqns,m,mT,matching,stateSets);                              
    then
       BackendDAE.DAE(syst::systList,shared); 
    
    case(BackendDAE.DAE(systList,
      shared as BackendDAE.SHARED(knownVars=knownVars,externalObjects=externalObjects,aliasVars=aliasVars,initialEqs=initialEqs,
                                   removedEqs=removedEqs,constraints=constraints,classAttrs=classAttrs,cache=cache,env=env,
                                   functionTree=funcs,eventInfo=eventInfo,extObjClasses=extObjClasses,backendDAEType=backendDAEType,symjacs=symjacs)),_,true) 
    equation
       shared = BackendDAE.SHARED(knownVars,externalObjects,aliasVars,eqns,removedEqs,constraints,classAttrs,cache,env,funcs,eventInfo,extObjClasses,backendDAEType,symjacs);                              
    then
       BackendDAE.DAE(systList,shared); 
       
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
  odae := match(idlow,repl,func,replaceVariables)  
  local 
    
    BackendDAE.EqSystem syst;
    list<BackendDAE.EqSystem> systList;
    BackendDAE.Shared shared;
    
    BackendDAE.Variables orderedVars "orderedVars ; ordered Variables, only states and alg. vars" ;
    BackendDAE.EquationArray orderedEqs "orderedEqs ; ordered Equations" ;
    Option<BackendDAE.IncidenceMatrix> m;
    Option<BackendDAE.IncidenceMatrixT> mT;
    BackendDAE.Matching matching;
    
    BackendDAE.Variables knownVars "knownVars ; Known variables, i.e. constants and parameters" ;
    BackendDAE.Variables externalObjects "External object variables";
    BackendDAE.Variables aliasVars "mappings of alias-variables to real-variables"; // added asodja 2010-03-03
    BackendDAE.EquationArray initialEqs "initialEqs ; Initial equations" ;
    BackendDAE.EquationArray removedEqs "these are equations that cannot solve for a variable. for example assertions, external function calls, algorithm sections without effect" ;
    array<DAE.Constraint> constraints "constraints" ;
    array<DAE.ClassAttributes> classAttrs;
    Env.Cache cache;
    Env.Env env;    
    DAE.FunctionTree funcs;
    BackendDAE.EventInfo eventInfo "eventInfo" ;
    BackendDAE.ExternalObjectClasses extObjClasses "classes of external objects, contains constructor & destructor";
    BackendDAE.BackendDAEType backendDAEType "indicate for what the BackendDAE is used"; 
    BackendDAE.SymbolicJacobians symjacs;
    list<BackendDAE.Equation> eqnslst;
    Boolean b;
    BackendDAE.StateSets stateSets;
  
    case(BackendDAE.DAE(
      (syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars,orderedEqs=orderedEqs,m=m,mT=mT,matching=matching,stateSets=stateSets))::systList,
      (shared as BackendDAE.SHARED(knownVars=knownVars,externalObjects=externalObjects,aliasVars=aliasVars,initialEqs=initialEqs,
                                   removedEqs=removedEqs,constraints=constraints,classAttrs=classAttrs,cache=cache,env=env,
                                   functionTree=funcs,eventInfo=eventInfo,extObjClasses=extObjClasses,backendDAEType=backendDAEType,symjacs=symjacs))),_,_,_) 
    equation
       orderedVars = BackendVariable.listVar1(replaceVars(BackendVariable.varList(orderedVars),repl,func,replaceVariables));
       eqnslst = BackendEquation.equationList(orderedEqs);
       (eqnslst,b) = BackendVarTransform.replaceEquations(eqnslst,repl,NONE());
       orderedEqs = Debug.bcallret1(b,BackendEquation.listEquation,eqnslst,orderedEqs);
       syst = BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching,stateSets);
       shared = BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,removedEqs,constraints,classAttrs,cache,env,funcs,eventInfo,extObjClasses,backendDAEType,symjacs);                              
    then
       BackendDAE.DAE(syst::systList,shared); 
       
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

public function varBindingOpt "function: varBindingOpt
author: PA

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
  bindExpOut:=
  match (bindExpIn)
    local
      DAE.Exp e,e1;
    case (NONE()) then NONE();
    case (SOME(e))
      equation
        (e1,_) = ExpressionSimplify.simplify1(e);
      then
        SOME(e1);
  end match;
end applyOptionSimplify;

public function setVarCref "
  author: PA
 
  sets the ComponentRef of a variable.
"
  input BackendDAE.Var inVar;
  input DAE.ComponentRef cr;
  output BackendDAE.Var outVar;
algorithm 
  outVar := match (inVar,cr)
    local
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
      Option<SCode.Comment> cmt;
      DAE.ConnectorType ct;
    case (BackendDAE.VAR(name,kind,dir,prl,tp,bind,bindval,ad,source,attr,cmt,ct),_) then 
      BackendDAE.VAR(cr,kind,dir,prl,tp,bind,bindval,ad,source,attr,cmt,ct); 
  end match;
end setVarCref;

public function setVarBindingOpt "
  author: PA
 
  sets the optional binding of a variable.
"
  input BackendDAE.Var inVar;
  input Option<DAE.Exp> bindExp;
  output BackendDAE.Var outVar;
algorithm 
  outVar := match (inVar,bindExp)
    local
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
      Option<SCode.Comment> cmt;
      DAE.ConnectorType ct;
    case (BackendDAE.VAR(name,kind,dir,prl,tp,bind,bindval,ad,source,attr,cmt,ct),_) then 
      BackendDAE.VAR(name,kind,dir,prl,tp,bindExp,bindval,ad,source,attr,cmt,ct); 
  end match;
end setVarBindingOpt;

public function moveVariables "function: moveVariables
 
  This function takes the two variable lists of a dae (states+alg) and
  known vars and moves a set of variables from the first to the second set.
  This function is needed to manage this in complexity O(n) by only 
  traversing the set once for all variables.
"
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
  input HashTable.HashTable hashTable;
  output BackendDAE.Variables outVariables1;
  output BackendDAE.Variables outVariables2;
algorithm 
  (outVariables1,outVariables2) := match (inVariables1,inVariables2,hashTable)
    local
      list<BackendDAE.Var> lst1,lst2,lst1_1,lst2_1;
      BackendDAE.Variables v1,v2,vars,knvars,vars1,vars2;
      HashTable.HashTable mvars;
    case (vars1,vars2,mvars)
      equation 
        lst1 = BackendVariable.varList(vars1);
        lst2 = BackendVariable.varList(vars2);
        (lst1_1,lst2_1) = moveVariables2(lst1, lst2, mvars);
        v1 = BackendVariable.emptyVars();
        v2 = BackendVariable.emptyVars();
        //vars = addVarsNoUpdCheck(lst1_1, v1);
        vars = BackendVariable.addVars(lst1_1, v1);
        //knvars = addVarsNoUpdCheck(lst2_1, v2);
        knvars = BackendVariable.addVars(lst2_1, v2);
      then
        (vars,knvars);
  end match;
end moveVariables;

protected function moveVariables2 "function: moveVariables2
 
  helper function to move_variables.
"
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
        _ = BaseHashTable.get(cr,mvars) "alg var moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        (vs_1,(v :: knvars_1));
    case (((v as BackendDAE.VAR(varName = cr)) :: vs),knvars,mvars)
      equation 
        failure(_ = BaseHashTable.get(cr,mvars)) "alg var not moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        ((v :: vs_1),knvars_1);
  end matchcontinue;
end moveVariables2;


public function setDaeKnownVars 
  input BackendDAE.BackendDAE dae;
  input BackendDAE.Variables newVarsIn;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := match(dae,newVarsIn)
  local 
    
    list<BackendDAE.EqSystem> systList;
    BackendDAE.Shared shared;
    
    
    BackendDAE.Variables knownVars "knownVars ; Known variables, i.e. constants and parameters" ;
    BackendDAE.Variables externalObjects "External object variables";
    BackendDAE.Variables aliasVars "mappings of alias-variables to real-variables"; // added asodja 2010-03-03
    BackendDAE.EquationArray initialEqs "initialEqs ; Initial equations" ;
    BackendDAE.EquationArray removedEqs "these are equations that cannot solve for a variable. for example assertions, external function calls, algorithm sections without effect" ;
    array<DAE.Constraint> constraints "constraints" ;
    array<DAE.ClassAttributes> classAttrs;
    Env.Cache cache;
    Env.Env env;    
    DAE.FunctionTree funcs;
    BackendDAE.EventInfo eventInfo "eventInfo" ;
    BackendDAE.ExternalObjectClasses extObjClasses "classes of external objects, contains constructor & destructor";
    BackendDAE.BackendDAEType backendDAEType "indicate for what the BackendDAE is used"; 
    BackendDAE.SymbolicJacobians symjacs;
    
    case(BackendDAE.DAE(systList,(shared as BackendDAE.SHARED(externalObjects=externalObjects,aliasVars=aliasVars,initialEqs=initialEqs,
                                   removedEqs=removedEqs,constraints=constraints,classAttrs=classAttrs,eventInfo=eventInfo,cache=cache,env=env,
                                   functionTree=funcs,extObjClasses=extObjClasses,backendDAEType=backendDAEType,symjacs=symjacs))),knownVars) 
    equation
       shared = BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,removedEqs,constraints,classAttrs,cache,env,funcs,eventInfo,extObjClasses,backendDAEType,symjacs);                              
    then
       BackendDAE.DAE(systList,shared); 
       
  end match;
end setDaeKnownVars;

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
  outList := match(inList, inCompFunc,inArgument1)
    local
      ElementType e;
      list<ElementType> left, right;
      Integer middle;

    case ({}, _,_) then {};
    case ({e}, _,_) then {e};
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

    case (l :: _, r :: r_rest, _,_)
      equation
        res = mergeBy1(inLeft, r_rest, inCompFunc,inArgument1);
      then
        r :: res;

    case ({}, _, _,_) then inRight;
    case (_, {}, _,_) then inLeft;

  end matchcontinue;
end mergeBy1;


end Uncertainties;  
  
